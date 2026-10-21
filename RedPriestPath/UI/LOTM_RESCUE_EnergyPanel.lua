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
LOTM_StartupTrace.Mark("LOTM_RESCUE_EnergyPanel","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"LOTM_RESCUE_EnergyPanel","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"LOTM_RESCUE_EnergyPanel","GameEvents");
local LuaEvents = LOTM_StartupTrace.Events(LuaEvents,"LOTM_RESCUE_EnergyPanel","LuaEvents");
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
do
-- END RC342 STARTUP TRACE
-- Read-only presentation plus EXECUTE_SCRIPT requests for purification energy.
local ABILITIES={"MADNESS","ECHO","ARMY","WALL"};
local COSTS={MADNESS={40,60,80,100,120,140,160,180,200,220},ECHO={40,60,80,100,120,140,160,180,200,220},ARMY={40,60,80,100,120,140,160,180,200,220},WALL={40,60,80,100,120,140,160,180,200,220}};
-- XML control IDs use title case (MadnessAdd, EchoAdd, ...), while the
-- gameplay ability keys are upper-case.  Do not build Controls keys by
-- concatenating the upper-case gameplay key: Civ VI then returns nil and the
-- panel fails during game-view initialization.
local CONTROL_IDS={
 MADNESS={Description="MadnessDescription",Info="MadnessInfo",Add="MadnessAdd",Minus="MadnessMinus"},
 ECHO={Description="EchoDescription",Info="EchoInfo",Add="EchoAdd",Minus="EchoMinus"},
 ARMY={Description="ArmyDescription",Info="ArmyInfo",Add="ArmyAdd",Minus="ArmyMinus"},
 WALL={Description="WallDescription",Info="WallInfo",Add="WallAdd",Minus="WallMinus"},
};
local DESCRIPTION_TAGS={
 MADNESS="LOC_LOTM_RESCUE_ABILITY_MADNESS_DESCRIPTION",
 ECHO="LOC_LOTM_RESCUE_ABILITY_ECHO_DESCRIPTION",
 ARMY="LOC_LOTM_RESCUE_ABILITY_ARMY_DESCRIPTION",
 WALL="LOC_LOTM_RESCUE_ABILITY_WALL_DESCRIPTION",
};
local open=false; local waiting=false;
local function P() local id=Game.GetLocalPlayer(); return id, id~=nil and id>=0 and Players[id] or nil; end
local function N(v,d) return tonumber(v) or d; end
local function ControlFor(ability,kind)
 local ids=CONTROL_IDS[ability]; local id=ids~=nil and ids[kind] or nil;
 return id~=nil and Controls[id] or nil;
end
local function Submit(command,parameters)
 if waiting then return; end; local id,player=P(); if player==nil or not player:IsTurnActive() then return; end; waiting=true; UI.RequestPlayerOperation(id,PlayerOperations.EXECUTE_SCRIPT,parameters or {OnStart=command});
end
local function Refresh()
 local id,player=P(); local active=Game.GetProperty("LOTM_RESCUE_MODE")==1 and player~=nil and player:IsAlive() and player:IsMajor() and player:IsHuman() and player:GetProperty("LOTM_RP_PATH")~=nil and player:GetProperty("LOTM_RP_PATH")~="NONE";
 if Controls.EnergyPopup==nil then print("[LOTM_RESCUE][EnergyUI] missing EnergyPopup root"); return; end
 if not active then open=false; end; Controls.EnergyPopup:SetHide(not (active and open)); if not active then return; end
 local balance=N(player:GetProperty("LOTM_RESCUE_ENERGY_BALANCE"),0); local spent=N(player:GetProperty("LOTM_RESCUE_ENERGY_SPENT"),0); local total=0;
 for _,a in ipairs(ABILITIES) do total=total+N(Game.GetProperty("LOTM_RESCUE_ABILITY_LEVEL_"..a),0); end
 Controls.Balance:SetText(Locale.Lookup("LOC_LOTM_RESCUE_ENERGY_BALANCE",balance)); Controls.Spent:SetText(Locale.Lookup("LOC_LOTM_RESCUE_ENERGY_SPENT",spent)); Controls.Global:SetText(Locale.Lookup("LOC_LOTM_RESCUE_ENERGY_GLOBAL",total));
  for _,a in ipairs(ABILITIES) do local level=N(Game.GetProperty("LOTM_RESCUE_ABILITY_LEVEL_"..a),0); local own=N(player:GetProperty("LOTM_RESCUE_ABILITY_ALLOCATED_"..a),0); local cost=level<10 and COSTS[a][level+1] or 0; local desc=ControlFor(a,"Description"); local info=ControlFor(a,"Info"); local add=ControlFor(a,"Add"); local minus=ControlFor(a,"Minus"); if desc~=nil then desc:SetText(Locale.Lookup(DESCRIPTION_TAGS[a])); end; if info~=nil then info:SetText(Locale.Lookup("LOC_LOTM_RESCUE_ABILITY_INFO",level,own,cost)); end; if add~=nil then add:SetDisabled(waiting or level>=10 or balance<cost); end; if minus~=nil then minus:SetDisabled(waiting or own<=0); end; end
end
local function Add(a) Submit("LOTM_RESCUE_Command_AllocatePurificationAbility",{OnStart="LOTM_RESCUE_Command_AllocatePurificationAbility",Ability=a}); end
local function Minus(a) Submit("LOTM_RESCUE_Command_DeallocatePurificationAbility",{OnStart="LOTM_RESCUE_Command_DeallocatePurificationAbility",Ability=a}); end
local function Initialize()
 ContextPtr:SetHide(false); if Controls.Close~=nil then Controls.Close:RegisterCallback(Mouse.eLClick,function() open=false; Refresh(); end); end; if Controls.ResetAll~=nil then Controls.ResetAll:RegisterCallback(Mouse.eLClick,function() Submit("LOTM_RESCUE_Command_ResetAllPurificationAbilities",{OnStart="LOTM_RESCUE_Command_ResetAllPurificationAbilities"}); end); end
 for _,a in ipairs(ABILITIES) do local ability=a; local add=ControlFor(ability,"Add"); local minus=ControlFor(ability,"Minus"); if add~=nil then add:RegisterCallback(Mouse.eLClick,function() Add(ability); end); else print("[LOTM_RESCUE][EnergyUI] missing add control ability="..tostring(ability)); end; if minus~=nil then minus:RegisterCallback(Mouse.eLClick,function() Minus(ability); end); else print("[LOTM_RESCUE][EnergyUI] missing minus control ability="..tostring(ability)); end; end
 LuaEvents.LOTM_RESCUE_EnergyPanel_Open.Add(function() open=true; waiting=false; Refresh(); end); Events.GameCoreEventPublishComplete.Add(function() waiting=false; Refresh(); end); Events.LocalPlayerTurnBegin.Add(function() waiting=false; Refresh(); end); Events.LoadGameViewStateDone.Add(Refresh); Refresh();
end
Initialize();
-- BEGIN RC342 STARTUP TRACE

end
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("LOTM_RESCUE_EnergyPanel","CONTEXT END");
-- END RC342 STARTUP TRACE
