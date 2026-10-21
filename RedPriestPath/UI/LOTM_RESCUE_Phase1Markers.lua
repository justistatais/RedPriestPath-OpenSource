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
LOTM_StartupTrace.Mark("LOTM_RESCUE_Phase1Markers","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"LOTM_RESCUE_Phase1Markers","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"LOTM_RESCUE_Phase1Markers","GameEvents");
local LuaEvents = LOTM_StartupTrace.Events(LuaEvents,"LOTM_RESCUE_Phase1Markers","LuaEvents");
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
do
-- END RC342 STARTUP TRACE
include("InstanceManager");

local m_Markers=InstanceManager:new("RescuePhase1MarkerInstance","Anchor",Controls.MarkerContainer);
local m_viewReady=false;
local ZONES={
	{Key="CENTER",Label="LOC_LOTM_RESCUE_MARKER_CENTER",Color={0x10/255,0x10/255,0x18/255,0.90}},
	{Key="FOOL",Label="LOC_LOTM_RESCUE_MARKER_FOOL",Color={0xF2/255,0xF2/255,0xF2/255,0.90}},
	{Key="NIGHT",Label="LOC_LOTM_RESCUE_MARKER_NIGHT",Color={0x6B/255,0x2F/255,0xB8/255,0.90}},
	{Key="STORM",Label="LOC_LOTM_RESCUE_MARKER_STORM",Color={0x20/255,0xC8/255,0xD8/255,0.90}}
};

local function IsRevealed(playerID,plot)
	local visibility=PlayersVisibility[playerID];
	return visibility~=nil and visibility:IsRevealed(plot:GetX(),plot:GetY());
end

local function Refresh()
	if not m_viewReady then return; end
	m_Markers:ResetInstances();
	if Game.GetProperty("LOTM_RESCUE_PHASE1_STATE")~="READY" then return; end
	-- Formal Phase 2 presentation uses the real city banners and borders; the
	-- old coordinate badges are development markers only.
	if Game.GetProperty("LOTM_RESCUE_PHASE2A_STATE")=="READY" then return; end
	local playerID=Game.GetLocalPlayer(); if playerID==nil or playerID<0 then return; end
	local radius=tostring(Game.GetProperty("LOTM_RESCUE_SEAL_RADIUS") or "?");
	local directions=tostring(Game.GetProperty("LOTM_RESCUE_DIRECTION_GROUP") or "?");
	for _,zone in ipairs(ZONES) do
		local index=tonumber(Game.GetProperty("LOTM_RESCUE_"..zone.Key.."_PLOT") or -1); local plot=index>=0 and Map.GetPlotByIndex(index) or nil;
		if plot~=nil and IsRevealed(playerID,plot) then
			local instance=m_Markers:GetInstance(); local worldX,worldY=UI.GridToWorld(index); instance.Anchor:SetWorldPositionVal(worldX,worldY,10);
			instance.Badge:SetColor(UI.GetColorValue(zone.Color[1],zone.Color[2],zone.Color[3],zone.Color[4])); instance.Label:SetText(Locale.Lookup(zone.Label));
			instance.Button:SetToolTipString(Locale.Lookup("LOC_LOTM_RESCUE_MARKER_TOOLTIP",Locale.Lookup(zone.Label),plot:GetX(),plot:GetY(),radius,directions));
			instance.Button:RegisterCallback(Mouse.eLClick,function() UI.LookAtPlot(plot:GetX(),plot:GetY()); end);
		end
	end
end

Events.LoadGameViewStateDone.Add(function()
	m_viewReady=true;
	print("[LOTM_RESCUE][MarkersUI] game view ready; enabling markers");
	Refresh();
end);
Events.GameCoreEventPublishComplete.Add(Refresh);
Events.PlayerTurnActivated.Add(function(id) if id==Game.GetLocalPlayer() then Refresh(); end end);
Events.LocalPlayerChanged.Add(Refresh);
if Events.FogOfWarVisibilityChanged~=nil then Events.FogOfWarVisibilityChanged.Add(Refresh); end
print("[LOTM_RESCUE][MarkersUI] initialized dormant until game view ready");
-- BEGIN RC342 STARTUP TRACE

end
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("LOTM_RESCUE_Phase1Markers","CONTEXT END");
-- END RC342 STARTUP TRACE
