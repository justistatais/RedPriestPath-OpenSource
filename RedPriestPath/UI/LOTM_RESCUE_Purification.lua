-- BEGIN RC342 STARTUP TRACE
-- Optional startup diagnostics, resource 435. Embedded by generate_startup_trace.py so a
-- missing VFS import cannot hide the first startup checkpoint.
-- Keep disabled in releases: high-frequency UI tracing caused severe stutter.
-- To diagnose a new failure, enable and rerun both startup/bundle generators.
if LOTM_StartupTrace == nil then
	LOTM_StartupTrace = { Enabled=false, Resource=435 };
	local trace = LOTM_StartupTrace;
	local sequence = 0;
	local unpackValues = table.unpack or unpack;
	local function Pack(...) return { n=select("#",...), ... }; end
	local function Scalar(value)
		local kind = type(value);
		if kind == "nil" then return "nil"; end
		if kind == "boolean" or kind == "number" then return tostring(value); end
		if kind == "string" then return string.sub(value:gsub("[\r\n\t]"," "),1,240); end
		-- Never tostring engine userdata or tables: __tostring can call native code.
		return "<" .. kind .. ">";
	end
	function trace.Mark(context,point,...)
		if not trace.Enabled then return; end
		sequence = sequence + 1;
		local fields = {};
		for index=1,select("#",...) do fields[index] = Scalar(select(index,...)); end
		print("[LOTM_DIAG] r=435 seq=" .. sequence .. " ctx=" .. context
			.. " point=" .. point .. (#fields>0 and " args=" .. table.concat(fields,"|") or ""));
	end
	-- A lexical proxy belongs to this module only. The actual Events tables,
	-- other mods' listeners, registration order and synchronization are untouched.
	function trace.Events(source,context,bus)
		if source == nil or not trace.Enabled then return source; end
		local events = {};
		return setmetatable({}, { __index=function(_,name)
			local real = source[name];
			if real == nil then return nil; end
			if events[name] ~= nil then return events[name]; end
			local wrappers = {};
			local nextID = 0;
			local proxy = setmetatable({}, {
				__index=function(_,member) return real[member]; end,
				__call=function(_,...) return real(...); end
			});
			proxy.Add = function(callback)
				local wrapped = wrappers[callback];
				if wrapped == nil then
					nextID = nextID + 1;
					local point = bus .. "." .. name .. "#" .. nextID;
					wrapped = function(...)
						trace.Mark(context,"EVENT BEGIN " .. point,...);
						-- No pcall: preserve the original error and engine error handling.
						local result = Pack(callback(...));
						trace.Mark(context,"EVENT END " .. point);
						return unpackValues(result,1,result.n);
					end;
					wrappers[callback] = wrapped;
				end
				trace.Mark(context,"REGISTER BEFORE " .. bus .. "." .. name);
				local result = Pack(real.Add(wrapped));
				trace.Mark(context,"REGISTER AFTER " .. bus .. "." .. name);
				return unpackValues(result,1,result.n);
			end;
			proxy.Remove = function(callback)
				-- Keep the identity for remove/re-add and duplicate registration.
				return real.Remove(wrappers[callback] or callback);
			end;
			events[name] = proxy;
			return proxy;
		end });
	end
end
LOTM_StartupTrace.Mark("LOTM_RESCUE_Purification","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"LOTM_RESCUE_Purification","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"LOTM_RESCUE_Purification","GameEvents");
local LuaEvents = LOTM_StartupTrace.Events(LuaEvents,"LOTM_RESCUE_Purification","LuaEvents");
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
do
-- END RC342 STARTUP TRACE
-- Rescue Phase 6 HUD: read-only view of synchronized Gameplay properties.
local FALLBACK_DISPLAY_MAX=3000;
local FALLBACK_BEST_TIER_THRESHOLD=3000;
local FALLBACK_TIER_THRESHOLDS={500,1000,1500,2000};
local WIDE_WIDTH=500;
local COMPACT_WIDTH=400;
local COMPACT_BREAKPOINT=1600;
local HORIZONTAL_PADDING=14;
local TOP_OFFSET=31;
local g_PositionDirty=true;
local g_PositionScreenX=nil;
local g_PositionScreenY=nil;
local g_LastLaunchWidth=nil;
local g_LayoutRefreshPending=false;
local g_ProgressWidth=WIDE_WIDTH-(HORIZONTAL_PADDING*2);
local MARKERS={
	{Line=Controls.Mark500,Label=Controls.Mark500Label},
	{Line=Controls.Mark1000,Label=Controls.Mark1000Label},
	{Line=Controls.Mark1500,Label=Controls.Mark1500Label},
	{Line=Controls.Mark2000,Label=Controls.Mark2000Label}
};

local function Clamp(value,minimum,maximum)
	return math.max(minimum,math.min(maximum,value));
end

local function ContributorName(key)
	if key=="CHURCH_FOOL" then return Locale.Lookup("LOC_LOTM_RESCUE_PURIFICATION_CHURCH_FOOL"); end
	if key=="CHURCH_NIGHT" then return Locale.Lookup("LOC_LOTM_RESCUE_PURIFICATION_CHURCH_NIGHT"); end
	if key=="CHURCH_STORM" then return Locale.Lookup("LOC_LOTM_RESCUE_PURIFICATION_CHURCH_STORM"); end
	if key=="LEGACY_UNATTRIBUTED" then return Locale.Lookup("LOC_LOTM_RESCUE_PURIFICATION_LEGACY"); end
	local playerID=tonumber(string.match(key,"^PLAYER_(-?%d+)$"));
	local config=playerID~=nil and PlayerConfigurations[playerID] or nil;
	if config~=nil then return Locale.Lookup(config:GetPlayerName()); end
	return Locale.Lookup("LOC_LOTM_RESCUE_PURIFICATION_UNKNOWN",tostring(playerID or key));
end

local function ContributionRanking()
	local entries={}; local list=tostring(Game.GetProperty("LOTM_RESCUE_PHASE6_CONTRIBUTOR_LIST") or "");
	for key in string.gmatch(list,"[^,]+") do
		local prefix="LOTM_RESCUE_PHASE6_CONTRIBUTION:"..key..":";
		local value=tonumber(Game.GetProperty(prefix.."TOTAL") or 0) or 0;
		local events=tonumber(Game.GetProperty(prefix.."EVENTS") or 0) or 0;
		if value>0 then entries[#entries+1]={Key=key,Name=ContributorName(key),Value=value,Events=events}; end
	end
	table.sort(entries,function(a,b) if a.Value~=b.Value then return a.Value>b.Value; end return a.Key<b.Key; end);
	if #entries==0 then
		local empty=Locale.Lookup("LOC_LOTM_RESCUE_PURIFICATION_RANKING_EMPTY"); return empty,empty;
	end
	local compact={}; local full={Locale.Lookup("LOC_LOTM_RESCUE_PURIFICATION_RANKING_TITLE")};
	for rank,entry in ipairs(entries) do
		local line=Locale.Lookup("LOC_LOTM_RESCUE_PURIFICATION_RANKING_ENTRY",rank,entry.Name,entry.Value,entry.Events);
		full[#full+1]=line; if rank<=3 then compact[#compact+1]=tostring(rank).."."..entry.Name.." "..entry.Value; end
	end
	return Locale.Lookup("LOC_LOTM_RESCUE_PURIFICATION_RANKING_COMPACT",table.concat(compact,"  |  ")),table.concat(full,"[NEWLINE]");
end

local function IsRescueMode()
	if GameInfo~=nil and GameInfo.Resources~=nil
		and GameInfo.Resources["RESOURCE_LOTM_RESCUE_ALLY_BANNER"]~=nil then return true; end
	local configured=GameConfiguration~=nil and GameConfiguration.GetValue~=nil
		and GameConfiguration.GetValue("GAMEMODE_LOTM_RESCUE") or nil;
	return configured==true or tonumber(configured)==1;
end

local function RealizePosition(screenX,screenY,rootWidth)
 if not g_PositionDirty and g_PositionScreenX==screenX and g_PositionScreenY==screenY then return; end
 -- Additional UI contexts can have an unresolved parent width when loaded.
 -- Position against the viewport explicitly instead of centering in that
 -- parent. LaunchBar/panels must never move this HUD down from the top edge.
 Controls.Root:SetOffsetX(math.floor((screenX-rootWidth)/2));
 Controls.Root:SetOffsetY(TOP_OFFSET);
 Controls.Root:ReprocessAnchoring();
 g_PositionDirty=false;
 g_PositionScreenX=screenX;
 g_PositionScreenY=screenY;
end

local function RealizeSize()
	local screenX,screenY=UIManager:GetScreenSizeVal();
	local rootWidth=screenX<COMPACT_BREAKPOINT and COMPACT_WIDTH or WIDE_WIDTH;
	local trackBorderWidth=rootWidth-24;
	g_ProgressWidth=rootWidth-(HORIZONTAL_PADDING*2);
	local displayMax=tonumber(Game.GetProperty("LOTM_RESCUE_PURIFICATION_DISPLAY_MAX") or FALLBACK_DISPLAY_MAX) or FALLBACK_DISPLAY_MAX;
	displayMax=math.max(1,displayMax);
	Controls.Root:SetSizeX(rootWidth);
	-- Fixed viewport top-center, independent of panel and LaunchBar geometry.
	RealizePosition(screenX,screenY,rootWidth);
	Controls.Background:SetSizeX(rootWidth);
	Controls.BorderTop:SetSizeX(rootWidth);
	Controls.BorderBottom:SetSizeX(rootWidth);
	Controls.Title:SetSizeX(rootWidth-24);
	Controls.Leaderboard:SetSizeX(rootWidth-24);
	Controls.TrackBorder:SetSizeX(trackBorderWidth);
	Controls.Track:SetSizeX(g_ProgressWidth);
	local progressLeft=HORIZONTAL_PADDING;
	local labelWidth=44;
	for index,marker in ipairs(MARKERS) do
		local threshold=tonumber(Game.GetProperty("LOTM_RESCUE_PHASE10_TIER_THRESHOLD_"..(index+1)) or FALLBACK_TIER_THRESHOLDS[index]) or FALLBACK_TIER_THRESHOLDS[index];
		local markerX=progressLeft+math.floor(g_ProgressWidth*Clamp(threshold/displayMax,0,1))-1;
		marker.Line:SetOffsetX(markerX);
		marker.Label:SetSizeX(labelWidth);
		marker.Label:SetOffsetX(Clamp(markerX-math.floor(labelWidth/2),2,rootWidth-labelWidth-2));
		marker.Label:SetText(tostring(threshold));
	end
end

local function Refresh()
	-- This context is already gated by the rescue-mode Criteria in modinfo.
	-- Once descent starts, purification is locked and the setup HUD is no
	-- longer useful.  This UI remains read-only: Gameplay owns the property.
	if not IsRescueMode() or Game.GetProperty("LOTM_RESCUE_PHASE10_DESCENT_TRIGGERED") then
		Controls.Root:SetHide(true);
		ContextPtr:SetHide(true);
		return;
	end
	-- AdditionalUserInterfaces contexts are initially hidden by the InGame host;
	-- both the context and its root must be shown for an always-on HUD.
	ContextPtr:SetHide(false);
	Controls.Root:SetHide(false);
	local total=tonumber(Game.GetProperty("GLOBAL_PURIFICATION") or 0) or 0;
	local displayMax=tonumber(Game.GetProperty("LOTM_RESCUE_PURIFICATION_DISPLAY_MAX") or FALLBACK_DISPLAY_MAX) or FALLBACK_DISPLAY_MAX;
	local threshold=tonumber(Game.GetProperty("LOTM_RESCUE_PHASE10_BEST_TIER_THRESHOLD") or FALLBACK_BEST_TIER_THRESHOLD) or FALLBACK_BEST_TIER_THRESHOLD;
	displayMax=math.max(1,displayMax);
	threshold=math.max(1,threshold);
	local delta=tonumber(Game.GetProperty("LOTM_RESCUE_PHASE6_LAST_DELTA") or 0) or 0;
	local turn=tonumber(Game.GetProperty("LOTM_RESCUE_PHASE6_LAST_TURN") or -1) or -1;
	RealizeSize();
	local fillWidth=math.floor(g_ProgressWidth*Clamp(total/displayMax,0,1)+0.5);
	Controls.ProgressFill:SetSizeX(fillWidth);
	Controls.ProgressFill:SetHide(fillWidth<=0);
	local valueText=nil;
	if total>=displayMax then
		valueText=Locale.Lookup("LOC_LOTM_RESCUE_PURIFICATION_VALUE_OVER",total,displayMax);
	else
		valueText=Locale.Lookup("LOC_LOTM_RESCUE_PURIFICATION_VALUE",total,displayMax);
	end
	Controls.Title:SetText(Locale.Lookup("LOC_LOTM_RESCUE_PURIFICATION_TITLE").."  |  "..valueText);
	local compactRanking,fullRanking=ContributionRanking();
	Controls.Leaderboard:SetText(compactRanking);
	Controls.Root:SetToolTipString(Locale.Lookup("LOC_LOTM_RESCUE_PURIFICATION_TOOLTIP",total,delta,turn,displayMax,threshold).."[NEWLINE][NEWLINE]"..fullRanking);
end

local function OnDeferredLayoutRefresh()
	ContextPtr:ClearRequestRefresh();
	g_LayoutRefreshPending=false;
	g_PositionDirty=true;
	Refresh();
end

local function InvalidateLayout()
	g_PositionDirty=true;
	if not g_LayoutRefreshPending and not ContextPtr:IsHidden() then
		g_LayoutRefreshPending=true;
		-- LaunchBar may handle the same event after this context. Measure once
		-- on the next UI refresh, after every native open/close callback finishes.
		ContextPtr:RequestRefresh();
	end
end

ContextPtr:SetRefreshHandler(OnDeferredLayoutRefresh);
Events.GameCoreEventPublishComplete.Add(Refresh);
Events.PlayerTurnActivated.Add(function(playerID) if playerID==Game.GetLocalPlayer() then Refresh(); end end);
Events.LocalPlayerChanged.Add(Refresh);
Events.LoadGameViewStateDone.Add(function() g_PositionDirty=true; Refresh(); end);
LuaEvents.LaunchBar_Resize.Add(function(width)
	if width==g_LastLaunchWidth then return; end
	g_LastLaunchWidth=width;
	g_PositionDirty=true;
	if not ContextPtr:IsHidden() then RealizeSize(); end
end);
Events.SystemUpdateUI.Add(function(updateType)
	if updateType==SystemUpdateUI.ScreenResize then InvalidateLayout(); end
end);
-- Firaxis LaunchBar OnOpen/OnClose moves LaunchContainer at <=850px without
-- broadcasting LaunchBar_Resize. These are its finite panel subscriptions,
-- including Expansion1/2; no frame polling or control-tree traversal is needed.
for _,eventName in ipairs({
	"CivicsTree_OpenCivicsTree","CivicsTree_CloseCivicsTree",
	"Government_OpenGovernment","Government_CloseGovernment",
	"GovernorPanel_Opened","GovernorPanel_Closed",
	"GreatPeople_OpenGreatPeople","GreatPeople_CloseGreatPeople",
	"GreatWorks_OpenGreatWorks","GreatWorks_CloseGreatWorks",
	"HistoricMoments_Opened","HistoricMoments_Closed",
	"Religion_OpenReligion","Religion_CloseReligion",
	"PantheonChooser_OpenReligion","PantheonChooser_CloseReligion",
	"TechTree_OpenTechTree","TechTree_CloseTechTree",
	"ClimateScreen_Opened","ClimateScreen_Closed"
}) do
	LuaEvents[eventName].Add(InvalidateLayout);
end
Events.InterfaceModeChanged.Add(function(oldMode,newMode)
	if oldMode==InterfaceModeTypes.VIEW_MODAL_LENS or newMode==InterfaceModeTypes.VIEW_MODAL_LENS then
		InvalidateLayout();
	end
end);
Refresh();
local loadedScreenX,loadedScreenY=UIManager:GetScreenSizeVal();
print("[LOTM_RESCUE][Phase6UI] loaded readOnly=true centeredTop=true position=viewportFixed screen="..tostring(loadedScreenX).."x"..tostring(loadedScreenY).." displayMax="..tostring(Game.GetProperty("LOTM_RESCUE_PURIFICATION_DISPLAY_MAX") or FALLBACK_DISPLAY_MAX)
	.." bestTierThreshold="..tostring(Game.GetProperty("LOTM_RESCUE_PHASE10_BEST_TIER_THRESHOLD") or FALLBACK_BEST_TIER_THRESHOLD)
	.." contextHidden="..tostring(ContextPtr:IsHidden()).." rootHidden="..tostring(Controls.Root:IsHidden()));
-- BEGIN RC342 STARTUP TRACE

end
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("LOTM_RESCUE_Purification","CONTEXT END");
-- END RC342 STARTUP TRACE
