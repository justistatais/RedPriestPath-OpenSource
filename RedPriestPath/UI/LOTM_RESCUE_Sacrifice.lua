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
LOTM_StartupTrace.Mark("LOTM_RESCUE_Sacrifice","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"LOTM_RESCUE_Sacrifice","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"LOTM_RESCUE_Sacrifice","GameEvents");
local LuaEvents = LOTM_StartupTrace.Events(LuaEvents,"LOTM_RESCUE_Sacrifice","LuaEvents");
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
do
-- END RC342 STARTUP TRACE
-- Rescue War God's Relic: sacrifice the currently selected friendly unit.
-- The request is only a synchronized EXECUTE_SCRIPT command; Gameplay owns validation.
local COMMAND="LOTM_RESCUE_Command_Sacrifice";
local function Refresh()
 local id=Game.GetLocalPlayer(); local player=id~=nil and Players[id] or nil; local unit=UI.GetHeadSelectedUnit();
 local path=player~=nil and tostring(player:GetProperty("LOTM_RP_PATH") or "NONE") or "NONE";
 local show=player~=nil and player:IsTurnActive() and path~="NONE"
  and tonumber(player:GetProperty("LOTM_RP_SEQUENCE") or 9)<=0
  and tonumber(player:GetProperty("LOTM_RESCUE_WAR_GOD_RELIC_COMPLETED") or 0)==1
  and unit~=nil and unit:GetOwner()==id;
 Controls.SacrificeButton:SetHide(not show);
end
local function Submit()
 local id=Game.GetLocalPlayer(); local unit=UI.GetHeadSelectedUnit();
 if id==nil or unit==nil or unit:GetOwner()~=id then Refresh(); return; end
 local parameters={}; parameters[UnitCommandTypes.PARAM_NAME]=COMMAND;
 UnitManager.RequestCommand(unit,UnitCommandTypes.EXECUTE_SCRIPT,parameters);
end
-- User requested the button be disabled while all existing bonuses remain.
-- ContextPtr:SetHide(false); Controls.SacrificeButton:SetText("献祭选中单位"); Controls.SacrificeButton:RegisterCallback(Mouse.eLClick,Submit);
-- Events.UnitSelectionChanged.Add(Refresh); Events.LocalPlayerTurnBegin.Add(Refresh);
-- if Events.GameCoreEventPublishComplete~=nil then Events.GameCoreEventPublishComplete.Add(Refresh); end
-- Refresh();
ContextPtr:SetHide(true);
Controls.SacrificeButton:SetHide(true);
-- BEGIN RC342 STARTUP TRACE

end
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("LOTM_RESCUE_Sacrifice","CONTEXT END");
-- END RC342 STARTUP TRACE
