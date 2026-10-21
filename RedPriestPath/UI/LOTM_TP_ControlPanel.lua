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
LOTM_StartupTrace.Mark("LOTM_TP_ControlPanel","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"LOTM_TP_ControlPanel","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"LOTM_TP_ControlPanel","GameEvents");
local LuaEvents = LOTM_StartupTrace.Events(LuaEvents,"LOTM_TP_ControlPanel","LuaEvents");
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
do
-- END RC342 STARTUP TRACE
-- Local Thief controls. Every mutation is submitted through EXECUTE_SCRIPT.

local PATH = "PATH_THIEF";
local PRODUCTION_COMMAND = "LOTM_TP_Command_SettleProduction";
local m_waiting = false;
local m_productionSubmittedTurn = -1;

local function LocalPlayer()
	local id = Game.GetLocalPlayer();
	return id ~= nil and id >= 0 and id or -1, id ~= nil and id >= 0 and Players[id] or nil;
end

local function Request(command, values)
	if m_waiting then return; end
	local id, player = LocalPlayer(); if player == nil then return; end
	local parameters = values or {}; parameters.OnStart = command;
	m_waiting = true;
	UI.RequestPlayerOperation(id, PlayerOperations.EXECUTE_SCRIPT, parameters);
end

local function PlayerName(id)
	local config = id ~= nil and id >= 0 and PlayerConfigurations[id] or nil;
	return config ~= nil and Locale.Lookup(config:GetCivilizationDescription()) or Locale.Lookup("LOC_LOTM_TP_TARGET_NONE");
end

local function Candidates(playerID, metOnly)
	local player = Players[playerID]; local result = {};
	for _, target in ipairs(PlayerManager.GetWasEverAliveMajors()) do
		local i = target:GetID();
		if i ~= playerID and target:GetTeam() ~= player:GetTeam()
			and (not metOnly or player:GetDiplomacy():HasMet(i)) then table.insert(result, i); end
	end
	table.sort(result); return result;
end

local function NextCandidate(list, current)
	if #list == 0 then return -1; end
	for index, value in ipairs(list) do if value == current then return list[index % #list + 1]; end end
	return list[1];
end

local function OnTarget()
	local id, player = LocalPlayer(); if player == nil then return; end
	Request("LOTM_TP_Command_SetTarget", {TargetPlayerID=NextCandidate(Candidates(id, true), tonumber(player:GetProperty("LOTM_TP_TARGET_PLAYER") or -1))});
end

local function OnAbility()
	local id, player = LocalPlayer(); if player == nil then return; end
	local currentCiv = tostring(player:GetProperty("LOTM_TP_BORROWED_CIV") or "");
	local list = Candidates(id, false); local current = -1;
	for _, sourceID in ipairs(list) do
		local config = PlayerConfigurations[sourceID];
		if config ~= nil and config:GetCivilizationTypeName() == currentCiv then current = sourceID; break; end
	end
	Request("LOTM_TP_Command_SetBorrowedAbility", {SourcePlayerID=NextCandidate(list, current)});
end

local function ChooseBranch(branch) Request("LOTM_TP_Command_ChooseFinalBranch", {Branch=branch}); end

local function RedeemFakeGold()
	local id, player = LocalPlayer();
	if player == nil then return; end
	local resource = GameInfo.Resources["RESOURCE_LOTM_TP_FAKE_GOLD"];
	local amount = resource ~= nil and player:GetResources():GetResourceAmount(resource.Index) or 0;
	if amount > 0 then Request("LOTM_TP_Command_RedeemFakeGold", {Amount=math.floor(amount)}); end
end

local function Refresh()
	local id, player = LocalPlayer();
	local thief = player ~= nil and player:GetProperty("LOTM_RP_PATH") == PATH;
	Controls.OpenButton:SetHide(not thief);
	if not thief then Controls.Panel:SetHide(true); Controls.FinalPopup:SetHide(true); return; end
	local sequence = tonumber(player:GetProperty("LOTM_RP_SEQUENCE") or 9) or 9;
	Controls.SequenceLabel:SetText(Locale.Lookup("LOC_LOTM_TP_HUD_SEQUENCE", sequence, Locale.Lookup("LOC_LOTM_TP_HUD_SEQUENCE_NAME_S" .. sequence)));
	local resource = GameInfo.Resources["RESOURCE_LOTM_TP_FAKE_GOLD"];
	local fake = resource ~= nil and player:GetResources():GetResourceAmount(resource.Index) or 0;
	Controls.FakeGoldLabel:SetText(Locale.Lookup("LOC_LOTM_TP_FAKE_GOLD_BALANCE", math.floor(fake)));
	local target = tonumber(player:GetProperty("LOTM_TP_TARGET_PLAYER") or -1) or -1;
	Controls.TargetLabel:SetText(Locale.Lookup("LOC_LOTM_TP_TARGET_CURRENT", PlayerName(target)));
	local cooldown = math.max(0, 5 - (Game.GetCurrentGameTurn() - (tonumber(player:GetProperty("LOTM_TP_TARGET_CHANGED_TURN") or -999) or -999)));
	Controls.TargetButton:SetDisabled(cooldown > 0 or #Candidates(id, true) == 0);
	Controls.TargetButton:SetToolTipString(cooldown > 0 and Locale.Lookup("LOC_LOTM_TP_TARGET_COOLDOWN", cooldown) or "");
	Controls.AbilityButton:SetHide(sequence > 2);
	Controls.AbilityButton:SetDisabled((player:GetProperty("LOTM_TP_ABILITY_DETACH_SUPPORTED") or 0) ~= 1);
	Controls.RedeemButton:SetHide(sequence > 8);
	Controls.RedeemButton:SetDisabled(fake <= 0);
	local probes = Locale.Lookup("LOC_LOTM_TP_PROBE_STATUS",
		player:GetProperty("LOTM_TP_TRADE_BRIDGE_SUPPORTED") or 0,
		player:GetProperty("LOTM_TP_CITY_TRANSFER_SUPPORTED") or 0,
		player:GetProperty("LOTM_TP_PRODUCTION_TRANSFER_SUPPORTED") or 0,
		player:GetProperty("LOTM_TP_ABILITY_DETACH_SUPPORTED") or 0);
	Controls.ProbeLabel:SetText(probes);
	Controls.FinalPopup:SetHide(not (sequence == 0 and tostring(player:GetProperty("LOTM_TP_FINAL_BRANCH") or "NONE") == "NONE"));
end

local function SubmitProductionSettlement()
	local id, player = LocalPlayer();
	if player == nil or not player:IsTurnActive()
		or player:GetProperty("LOTM_RP_PATH") ~= PATH
		or (tonumber(player:GetProperty("LOTM_RP_SEQUENCE") or 9) or 9) > 6 then return; end
	local turn = Game.GetCurrentGameTurn();
	if m_productionSubmittedTurn == turn
		or tonumber(player:GetProperty("LOTM_TP_LAST_PRODUCTION_SETTLEMENT_TURN") or -1) == turn
		or (tonumber(player:GetProperty("LOTM_TP_PRODUCTION_BUFFER") or 0) or 0) <= 0 then return; end
	m_productionSubmittedTurn = turn;
	UI.RequestPlayerOperation(id, PlayerOperations.EXECUTE_SCRIPT, {
		OnStart = PRODUCTION_COMMAND,
		Turn = turn
	});
	print("[LOTM_TP][ControlPanel] production settlement submitted player="
		.. id .. " turn=" .. turn);
end

local function OnPlayerTurnActivated(playerID, isFirstTimeThisTurn)
	if isFirstTimeThisTurn ~= false and playerID == Game.GetLocalPlayer() then
		SubmitProductionSettlement();
	end
end

local function Initialize()
	-- Thief uses the shared left LaunchBar and LOTM_RP_HUD.  Keep this
	-- compatibility context loaded but permanently hidden so the old right-
	-- side panel cannot diverge from the other three pathways.
	ContextPtr:SetHide(true);
	Events.PlayerTurnActivated.Add(OnPlayerTurnActivated);
	Events.GameCoreEventPublishComplete.Add(SubmitProductionSettlement);
	Events.LoadGameViewStateDone.Add(SubmitProductionSettlement);
end

Initialize();
-- BEGIN RC342 STARTUP TRACE

end
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("LOTM_TP_ControlPanel","CONTEXT END");
-- END RC342 STARTUP TRACE
