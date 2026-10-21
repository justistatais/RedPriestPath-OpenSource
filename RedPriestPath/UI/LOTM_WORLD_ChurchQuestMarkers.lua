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
LOTM_StartupTrace.Mark("LOTM_WORLD_ChurchQuestMarkers","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"LOTM_WORLD_ChurchQuestMarkers","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"LOTM_WORLD_ChurchQuestMarkers","GameEvents");
local LuaEvents = LOTM_StartupTrace.Events(LuaEvents,"LOTM_WORLD_ChurchQuestMarkers","LuaEvents");
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
do
-- END RC342 STARTUP TRACE
include("InstanceManager");

local m_Markers=InstanceManager:new("ChurchQuestMarkerInstance","Anchor",Controls.QuestMarkerContainer);
local CHURCHES={
 {Type="FOOL",Name="LOC_LOTM_CHURCH_FOOL_NAME",Icon="ICON_LOTM_CHURCH_FOOL",Color="COLOR_LOTM_CHURCH_FOOL"},
 {Type="NIGHT",Name="LOC_LOTM_CHURCH_NIGHT_NAME",Icon="ICON_LOTM_CHURCH_NIGHT",Color="COLOR_LOTM_CHURCH_NIGHT"},
 {Type="STORM",Name="LOC_LOTM_CHURCH_STORM_NAME",Icon="ICON_LOTM_CHURCH_STORM",Color="COLOR_LOTM_CHURCH_STORM"}
};

local function Property(player,church,suffix,default)
 local value=player~=nil and player:GetProperty("LOTM_CHURCH_"..church.."_"..suffix) or nil; return value==nil and default or value;
end

local function TargetPlotIndex(player,church)
 local kind=tostring(Property(player,church,"TARGET_KIND","NONE")); local stored=tonumber(Property(player,church,"TARGET_PLOT",-1)) or -1;
 if kind=="MONSTER" then
  local serial=tonumber(Property(player,church,"TARGET_ID",-1)) or -1;
  local ownerValue=Game.GetProperty("LOTM_WORLD_MONSTER:"..serial..":OWNER"); local unitValue=Game.GetProperty("LOTM_WORLD_MONSTER:"..serial..":UNIT_ID");
  local owner=ownerValue~=nil and tonumber(ownerValue) or nil; local unitID=unitValue~=nil and tonumber(unitValue) or nil;
  local unit=owner~=nil and unitID~=nil and UnitManager.GetUnit(owner,unitID) or nil;
  if unit~=nil then local plot=Map.GetPlot(unit:GetX(),unit:GetY()); if plot~=nil then return plot:GetIndex(); end end
 end
 return stored;
end

local function SetIcon(control,iconName)
 local x,y,sheet=IconManager:FindIconAtlas(iconName,32); if sheet~=nil and sheet~="" then control:SetTexture(x,y,sheet); return true; end return false;
end

local function Refresh()
 m_Markers:ResetInstances(); local playerID=Game.GetLocalPlayer(); local player=playerID~=nil and playerID>=0 and Players[playerID] or nil; if player==nil then return; end
 for _,church in ipairs(CHURCHES) do
  local tier=tonumber(Property(player,church.Type,"ACTIVE_TIER",0)) or 0; local kind=tostring(Property(player,church.Type,"TARGET_KIND","NONE")); local plotIndex=TargetPlotIndex(player,church.Type);
  local plot=tier>0 and kind~="BARB_CAMP_COUNT" and plotIndex>=0 and Map.GetPlotByIndex(plotIndex) or nil;
  if plot~=nil then
   local instance=m_Markers:GetInstance(); local worldX,worldY=UI.GridToWorld(plotIndex); instance.Anchor:SetWorldPositionVal(worldX,worldY,12);
   SetIcon(instance.Icon,church.Icon); instance.Icon:SetColor(UI.GetColorValue(church.Color));
   local location=Locale.Lookup("LOC_LOTM_CHURCH_COORDINATES",plot:GetX(),plot:GetY()); instance.Button:SetToolTipString(Locale.Lookup("LOC_LOTM_CHURCH_MAP_MARKER_TOOLTIP",Locale.Lookup(church.Name),tier,location));
   instance.Button:RegisterCallback(Mouse.eLClick,function() UI.LookAtPlot(plot:GetX(),plot:GetY()); end);
  end
 end
end

Events.LoadGameViewStateDone.Add(Refresh); Events.GameCoreEventPublishComplete.Add(Refresh); Events.PlayerTurnActivated.Add(function(id) if id==Game.GetLocalPlayer() then Refresh(); end end); Events.LocalPlayerChanged.Add(Refresh); Refresh();
-- BEGIN RC342 STARTUP TRACE

end
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("LOTM_WORLD_ChurchQuestMarkers","CONTEXT END");
-- END RC342 STARTUP TRACE
