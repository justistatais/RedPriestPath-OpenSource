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
LOTM_StartupTrace.Mark("LOTM_RESCUE_CampAction","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"LOTM_RESCUE_CampAction","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"LOTM_RESCUE_CampAction","GameEvents");
local LuaEvents = LOTM_StartupTrace.Events(LuaEvents,"LOTM_RESCUE_CampAction","LuaEvents");
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
do
-- END RC342 STARTUP TRACE
-- Read-only ability action. Gameplay validates local placement and owns
-- native city creation, rewards, resurrection and cooldown.
local initialized=false;
local visible=false;
local actionsStack=nil;
local function SetVisible(wanted)
 if wanted==visible then return; end
 visible=wanted; Controls.ActionButton:SetHide(not wanted);
 if actionsStack~=nil then actionsStack:CalculateSize(); actionsStack:ReprocessAnchoring(); end
end
local function GetTarget()
 local id=Game.GetLocalPlayer(); if id==nil or id<0 then return nil; end
 local player=Players[id]; local unit=UI.GetHeadSelectedUnit();
 if player==nil or tonumber(Game.GetProperty("LOTM_RESCUE_MODE") or 0)~=1
  or player:GetProperty("LOTM_RP_PATH")~="PATH_THIEF"
  or (tonumber(player:GetProperty("LOTM_RP_SEQUENCE") or 9) or 9)>4
  or unit==nil or unit:GetOwner()~=id or unit:IsDead() or unit:IsDelayedDeath() then return nil; end
 local info=GameInfo.Units[unit:GetType()];
 local isHero=info~=nil and info.UnitType=="UNIT_LOTM_TP_PATH_HOLDER";
 local isWorm=info~=nil and info.UnitType=="UNIT_LOTM_RESCUE_TIME_WORM";
 if not isHero and not isWorm then return nil; end
 local plot=Map.GetPlot(unit:GetX(),unit:GetY());
 if plot==nil or plot:IsCity() or (plot.IsWater~=nil and plot:IsWater()) then return nil; end
 if isHero then
  if (tonumber(player:GetProperty("LOTM_RESCUE_CAMP_CONVERT_PENDING") or 0) or 0)~=0
   or (tonumber(player:GetProperty("LOTM_RESCUE_CAMP_CONVERT_TURN") or -1) or -1)==Game.GetCurrentGameTurn() then return nil; end
  return id,{OnStart="LOTM_RESCUE_Command_ConvertBarbarianCamp",PlotIndex=plot:GetIndex(),Mode="SELF"},"LOC_LOTM_RESCUE_PARASITE_FOUND_TOOLTIP";
 end
 if (tonumber(player:GetProperty("LOTM_RP_SEQUENCE") or 9) or 9)>1
  or (tonumber(player:GetProperty("LOTM_RESCUE_TIME_WORM_FOUND_PENDING") or 0) or 0)~=0
  or (tonumber(player:GetProperty("LOTM_RESCUE_TIME_WORM_COOLDOWN") or -1) or -1)>Game.GetCurrentGameTurn() then return nil; end
 return id,{OnStart="LOTM_RESCUE_Command_FoundTimeWormCity",UnitID=unit:GetID(),Mode="SELF"},"LOC_LOTM_RESCUE_WORM_FOUND_TOOLTIP";
end
local function Refresh()
 if not initialized then return; end
 local id,params,tooltip=GetTarget();
 SetVisible(id~=nil);
 if id~=nil then Controls.ActionButton:SetToolTipString(Locale.Lookup(tooltip)); end
end
local function RequestRefresh()
 if initialized then ContextPtr:RequestRefresh(); end
end
local function Submit()
 local id,params=GetTarget(); if id==nil then SetVisible(false); return; end
 print("[LOTM_RESCUE][CampActionUI] submit command="..params.OnStart.." player="..id.." plot="..tostring(params.PlotIndex).." unit="..tostring(params.UnitID));
 local accepted=UI.RequestPlayerOperation(id,PlayerOperations.EXECUTE_SCRIPT,params);
 if accepted==false then print("[LOTM_RESCUE][CampActionUI] submission rejected"); end
 SetVisible(false);
end
local function Setup()
 if initialized then return; end
 actionsStack=ContextPtr:LookUpControl("/InGame/UnitPanel/StandardActionsStack");
 if actionsStack==nil then return; end
 initialized=true; ContextPtr:SetHide(false);
 Controls.ActionButton:ChangeParent(actionsStack);
 Controls.ActionButton:RegisterCallback(Mouse.eLClick,Submit);
 ContextPtr:SetRefreshHandler(Refresh);
 Events.UnitSelectionChanged.Add(RequestRefresh);
 Events.UnitMovementPointsChanged.Add(RequestRefresh);
 Events.GameCoreEventPublishComplete.Add(RequestRefresh);
 RequestRefresh();
 print("[LOTM_RESCUE][CampActionUI] loaded sequence<=4 legalPlot=true advancedCity=true respawnTurns=5 wormCooldown=3");
end
Events.LoadGameViewStateDone.Add(Setup);
-- BEGIN RC342 STARTUP TRACE

end
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("LOTM_RESCUE_CampAction","CONTEXT END");
-- END RC342 STARTUP TRACE
