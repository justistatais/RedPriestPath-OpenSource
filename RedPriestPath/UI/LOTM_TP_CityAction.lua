-- BEGIN RC342 STARTUP TRACE
-- Optional startup diagnostics, resource 393. Embedded by generate_startup_trace.py so a
-- missing VFS import cannot hide the first startup checkpoint.
-- Keep disabled in releases: high-frequency UI tracing caused severe stutter.
-- To diagnose a new failure, enable and rerun both startup/bundle generators.
if LOTM_StartupTrace == nil then
	LOTM_StartupTrace = { Enabled=false, Resource=393 };
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
		print("[LOTM_DIAG] r=393 seq=" .. sequence .. " ctx=" .. context
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
LOTM_StartupTrace.Mark("LOTM_TP_CityAction","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"LOTM_TP_CityAction","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"LOTM_TP_CityAction","GameEvents");
local LuaEvents = LOTM_StartupTrace.Events(LuaEvents,"LOTM_TP_CityAction","LuaEvents");
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
do
-- END RC342 STARTUP TRACE
-- Unit-panel Parasite action. UI only submits the synchronized Gameplay
-- command; ownership and the five-turn timer remain authoritative there.

local function Hide() Controls.ActionButton:SetHide(true); end

local function Refresh()
	Hide();
	local localID = Game.GetLocalPlayer();
	if localID == nil or localID < 0 then return; end
	local player = Players[localID];
	local unit = UI.GetHeadSelectedUnit();
	if player == nil or unit == nil
		or unit:GetOwner() ~= localID
		or player:GetProperty("LOTM_RP_PATH") ~= "PATH_THIEF"
		or (tonumber(player:GetProperty("LOTM_RP_SEQUENCE") or 9) or 9) > 4 then return; end
	local due = tonumber(player:GetProperty("LOTM_TP_PARASITE_DUE_TURN") or -1) or -1;
	if due >= (Game.GetCurrentGameTurn() or 0) then return; end
	local unitInfo = GameInfo.Units[unit:GetType()];
	if unitInfo == nil or unitInfo.UnitType ~= "UNIT_LOTM_TP_PATH_HOLDER" then return; end
	local plot = Map.GetPlot(unit:GetX(), unit:GetY());
	local plotOwner = plot ~= nil and plot:GetOwner() or -1;
	local city = plot ~= nil and plotOwner >= 0 and plotOwner ~= localID
		and Cities.GetPlotPurchaseCity(plot) or nil;
	if city == nil or city:GetOwner() ~= plotOwner then return; end
	Controls.ActionButton:SetHide(false);
end

local function Submit()
	local playerID = Game.GetLocalPlayer();
	local unit = UI.GetHeadSelectedUnit();
	if unit == nil then Hide(); return; end
	UI.RequestPlayerOperation(playerID, PlayerOperations.EXECUTE_SCRIPT, {
		OnStart="LOTM_TP_Command_DesignateCity", UnitID=unit:GetID(),
		X=unit:GetX(), Y=unit:GetY()
	});
	Hide();
end

local function Setup()
	ContextPtr:SetHide(false);
	local stack = ContextPtr:LookUpControl("/InGame/UnitPanel/StandardActionsStack");
	if stack ~= nil then Controls.ActionButton:ChangeParent(stack); end
	Controls.ActionButton:RegisterCallback(Mouse.eLClick, Submit);
	Events.UnitSelectionChanged.Add(Refresh);
	Events.UnitMovementPointsChanged.Add(Refresh);
	Events.GameCoreEventPublishComplete.Add(Refresh);
	Hide();
end

Events.LoadGameViewStateDone.Add(Setup);
-- BEGIN RC342 STARTUP TRACE

end
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("LOTM_TP_CityAction","CONTEXT END");
-- END RC342 STARTUP TRACE
