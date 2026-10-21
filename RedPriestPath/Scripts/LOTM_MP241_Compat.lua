-- Multiplayer-only compatibility surface for features added after rc.241.
--
-- The rc.241 Gameplay modules keep their original event registrations and do
-- not call this adapter.  Only post-rc.241 modules use these helpers.  In
-- particular, this file does not install a shared turn dispatcher. Each new
-- handler registers directly on GameEvents.PlayerTurnStarted; client-local
-- activation notifications must not write authoritative state in multiplayer.

LOTM_MP_TurnSync = LOTM_MP_TurnSync or {};
LOTM_MP_TurnSync.VERSION = 241;
LOTM_MP_TurnSync._wrappers = LOTM_MP_TurnSync._wrappers or {};
LOTM_MP_TurnSync._startupWrappers = LOTM_MP_TurnSync._startupWrappers or {};
LOTM_MP_TurnSync._registered = LOTM_MP_TurnSync._registered or {};
LOTM_MP_TurnSync._startups = LOTM_MP_TurnSync._startups or {};

local STABLE_MODULUS = 2147483647;

local function NormalizeStableValue(value)
	local numeric = tonumber(value);
	if numeric == nil then
		local result = 0;
		local source = tostring(value or "");
		for index = 1, #source do
			result = (result * 131 + string.byte(source,index)) % STABLE_MODULUS;
		end
		return result;
	end
	numeric = math.floor(numeric) % STABLE_MODULUS;
	if numeric < 0 then numeric = numeric + STABLE_MODULUS; end
	return numeric;
end

local function MixStableValue(value,component)
	return (NormalizeStableValue(value) * 48271
		+ NormalizeStableValue(component) + 1) % STABLE_MODULUS;
end

local function StableSeed()
	local gameSeed = GameConfiguration ~= nil
		and GameConfiguration.GetValue ~= nil
		and GameConfiguration.GetValue("GAME_SYNC_RANDOM_SEED") or 0;
	local mapSeed = MapConfiguration ~= nil
		and MapConfiguration.GetValue ~= nil
		and MapConfiguration.GetValue("RANDOM_SEED") or nil;
	if mapSeed == nil and GameConfiguration ~= nil
		and GameConfiguration.GetValue ~= nil then
		mapSeed = GameConfiguration.GetValue("MAP_RANDOM_SEED");
	end
	return MixStableValue(MixStableValue(104729,gameSeed),mapSeed or 0);
end

function LOTM_MP_TurnSync.IsNetworkGame()
	return GameConfiguration ~= nil
		and GameConfiguration.IsAnyMultiplayer ~= nil
		and GameConfiguration.IsAnyMultiplayer() == true;
end

function LOTM_MP_TurnSync.IsRescueModeConfigured()
	if GameInfo ~= nil and GameInfo.Resources ~= nil
		and GameInfo.Resources["RESOURCE_LOTM_RESCUE_ALLY_BANNER"] ~= nil then
		return true;
	end
	local configured = GameConfiguration ~= nil
		and GameConfiguration.GetValue ~= nil
		and GameConfiguration.GetValue("GAMEMODE_LOTM_RESCUE") or nil;
	return configured == true or tonumber(configured or 0) == 1;
end

function LOTM_MP_TurnSync.Random(maxExclusive,label,legacyLabel)
	local limit = math.floor(tonumber(maxExclusive) or 0);
	if limit <= 0 then return 0; end
	if limit == 1 then return 0; end
	local turn = Game ~= nil and Game.GetCurrentGameTurn ~= nil
		and Game.GetCurrentGameTurn() or 0;
	local value = MixStableValue(StableSeed(),turn);
	value = MixStableValue(value,label or legacyLabel or "LOTM_MP241");
	value = MixStableValue(value,limit);
	return value % limit;
end

function LOTM_MP_TurnSync.GetStableAnchorPlayerID()
	local best = nil;
	for _,player in ipairs(PlayerManager.GetAliveMajors() or {}) do
		local playerID = player:GetID();
		if best == nil or playerID < best then best = playerID; end
	end
	return best or -1;
end

function LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID)
	return tonumber(playerID) == LOTM_MP_TurnSync.GetStableAnchorPlayerID();
end

local function Guarded(handler,label,playerID,isFirstTimeThisTurn)
	local ok,details = pcall(handler,playerID,isFirstTimeThisTurn);
	if not ok then
		print("[LOTM][MP241Compat] handler failed label="..tostring(label)
			.." details="..tostring(details));
	end
	return ok;
end

local function RunStartupEntry(entry)
	if entry == nil then return true; end
	if entry.State ~= "WAITING" then return entry.State ~= "FAILED"; end
	-- Reserve first; a partially applied startup must never run twice.
	entry.State = "RUNNING";
	local ok,details = pcall(entry.Handler);
	-- A false result is a completed reconciliation with no applicable content
	-- (e.g. Thief's thiefFound=false), not permission for an unbounded rescan.
	-- The former immediate adapter also ran these handlers only once per load.
	entry.State = ok and "DONE" or "FAILED";
	if not ok then
		print("[LOTM][MP241Compat] startup failed label="..tostring(entry.Label)
			.." details="..tostring(details));
	end
	return ok;
end

local function RegisterSynchronized(handler,label)
	if type(handler) ~= "function" or GameEvents == nil
		or GameEvents.PlayerTurnStarted == nil then return false; end
	-- All production callers supply stable, unique labels. The function key
	-- still provides context-local de-duplication for unlabeled callers.
	local key = label or handler;
	if LOTM_MP_TurnSync._registered[key] ~= nil then return false; end
	local lastTurns = {};
	local wrapper = function(playerID)
		local id = tonumber(playerID);
		if id == nil or id < 0 or id ~= math.floor(id) then return; end
		local turn = Game.GetCurrentGameTurn();
		if lastTurns[id] == turn then return; end
		local propertyKey = label ~= nil and ("LOTM_MP241_TURN_"..tostring(label).."_"..id) or nil;
		if propertyKey ~= nil and tonumber(Game.GetProperty(propertyKey) or -1) == turn then return; end
		-- Reserve before the callback and persist it before any native mutation.
		-- Re-entry and same-turn reload must not replay a partially applied turn.
		lastTurns[id] = turn;
		if propertyKey ~= nil then Game.SetProperty(propertyKey,turn); end
		if not RunStartupEntry(LOTM_MP_TurnSync._startups[key]) then return; end
		Guarded(handler,label,playerID,true);
	end;
	LOTM_MP_TurnSync._registered[key] = wrapper;
	LOTM_MP_TurnSync._wrappers[#LOTM_MP_TurnSync._wrappers + 1] = wrapper;
	GameEvents.PlayerTurnStarted.Add(wrapper);
	return true;
end

function LOTM_MP_TurnSync.Add(handler,label)
	return RegisterSynchronized(handler,label);
end

function LOTM_MP_TurnSync.AddSynchronized(handler,label)
	return RegisterSynchronized(handler,label);
end

function LOTM_MP_TurnSync.RunStartup(handler,label)
	if type(handler) ~= "function" or GameEvents == nil
		or GameEvents.PlayerTurnStarted == nil then return false; end
	local key = label or handler;
	if LOTM_MP_TurnSync._startups[key] ~= nil then return false; end
	local entry = { Handler=handler, Label=label, State="WAITING" };
	LOTM_MP_TurnSync._startups[key] = entry;
	LOTM_MP_TurnSync._startupWrappers[#LOTM_MP_TurnSync._startupWrappers + 1] = entry;
	-- A separate direct listener also restores startup-only modules on load.
	-- Matching turn callbacks invoke their startup first, regardless of order.
	GameEvents.PlayerTurnStarted.Add(function() RunStartupEntry(entry); end);
	return true;
end

-- Called only by the separate synchronized main-load command after include.
-- This startup-only pass has no recurring full-world dispatcher or scan.
function LOTM_MP_TurnSync.RunPendingStartups()
	local ok = true;
	for _,entry in ipairs(LOTM_MP_TurnSync._startupWrappers) do
		if not RunStartupEntry(entry) then ok = false; end
	end
	return ok;
end

-- The bridge records these IDs from synchronized PlayerTurnStarted events
-- before this bundle is loaded. Restore only this turn's missed callbacks;
-- persisted per-handler turn guards make a saved/repeated request idempotent.
function LOTM_MP_TurnSync.RunCurrentTurnCatchUp(playerIDs)
	local ordered = {}; local seen = {};
	for _,value in ipairs(playerIDs or {}) do
		local id = tonumber(value);
		if id ~= nil and id >= 0 and id == math.floor(id) and not seen[id] then
			seen[id] = true; ordered[#ordered + 1] = id;
		end
	end
	table.sort(ordered);
	for _,id in ipairs(ordered) do
		for _,wrapper in ipairs(LOTM_MP_TurnSync._wrappers) do wrapper(id); end
	end
end

print("[LOTM][MP241Compat] initialized version=241 directEvents=true synchronized=true unifiedDispatcher=false");
