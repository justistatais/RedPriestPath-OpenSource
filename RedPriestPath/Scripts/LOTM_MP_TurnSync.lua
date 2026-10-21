-- Multiplayer-only authoritative turn registration.
--
-- Gameplay mutations must not use Events.PlayerTurnActivated in a network
-- game: that event follows each local client's turn/UI activation lifecycle.
-- GameEvents.PlayerTurnStarted is emitted by synchronized Gameplay and is the
-- pattern used by Haikesi Addon, More Historical Leaders and HD gameplay
-- scripts for Property, yield, production and Modifier changes.
--
-- Single-player deliberately keeps the legacy event and callback unchanged.

LOTM_MP_TurnSync = LOTM_MP_TurnSync or {};
LOTM_MP_TurnSync.VERSION = 7;
LOTM_MP_TurnSync._wrappers = LOTM_MP_TurnSync._wrappers or {};
LOTM_MP_TurnSync._startupWrappers = LOTM_MP_TurnSync._startupWrappers or {};
LOTM_MP_TurnSync._turnHandlers = LOTM_MP_TurnSync._turnHandlers or {};
LOTM_MP_TurnSync._startupHandlers = LOTM_MP_TurnSync._startupHandlers or {};
LOTM_MP_TurnSync._dispatcherInstalled = LOTM_MP_TurnSync._dispatcherInstalled or false;
LOTM_MP_TurnSync._stableSeed = LOTM_MP_TurnSync._stableSeed or nil;
LOTM_MP_TurnSync._dispatcherFault = LOTM_MP_TurnSync._dispatcherFault or false;

local RegisterNetworkTurnHandler;
local RegisterNetworkStartupHandler;

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
	if LOTM_MP_TurnSync._stableSeed == nil then
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
		LOTM_MP_TurnSync._stableSeed = MixStableValue(
			MixStableValue(104729,gameSeed),mapSeed or 0);
	end
	return LOTM_MP_TurnSync._stableSeed;
end

function LOTM_MP_TurnSync.IsNetworkGame()
	return GameConfiguration ~= nil
		and GameConfiguration.IsAnyMultiplayer ~= nil
		and GameConfiguration.IsAnyMultiplayer() == true;
end

-- The rescue-only resource database is selected by Action Criteria before
-- Gameplay contexts load. Prefer that deterministic marker over the custom
-- GameConfiguration value, which may still be nil during network startup.
function LOTM_MP_TurnSync.IsRescueModeConfigured()
	if GameInfo ~= nil and GameInfo.Resources ~= nil
		and GameInfo.Resources["RESOURCE_LOTM_RESCUE_ALLY_BANNER"] ~= nil then
		return true;
	end
	local configured = GameConfiguration ~= nil
		and GameConfiguration.GetValue ~= nil
		and GameConfiguration.GetValue("GAMEMODE_LOTM_RESCUE") or nil;
	return configured == true or tonumber(configured) == 1;
end

-- Multiplayer rolls are pure functions of synchronized configuration, the
-- current game turn and a caller-supplied stable event identity. They never
-- advance the engine-wide RNG stream, so two callbacks arriving in a
-- different local order cannot perturb later Gameplay. Single-player keeps
-- the exact legacy Game.GetRandNum path.
function LOTM_MP_TurnSync.Random(maxExclusive,label,legacyLabel)
	local limit = math.floor(tonumber(maxExclusive) or 0);
	if limit <= 0 then return 0; end
	if not LOTM_MP_TurnSync.IsNetworkGame() then
		return Game.GetRandNum(limit,tostring(legacyLabel or label or "LOTM"));
	end
	if limit == 1 then return 0; end
	local turn = Game ~= nil and Game.GetCurrentGameTurn ~= nil
		and Game.GetCurrentGameTurn() or 0;
	local value = MixStableValue(StableSeed(),turn);
	value = MixStableValue(value,label or "");
	value = MixStableValue(value,limit);
	return value % limit;
end

local function InvokeTurnHandler(handler,label,playerID,isFirstTimeThisTurn)
	if LOTM_UnitAddedPerf ~= nil and type(LOTM_UnitAddedPerf.MeasureTurn) == "function" then
		LOTM_UnitAddedPerf.MeasureTurn(label,handler,playerID,isFirstTimeThisTurn);
	else
		handler(playerID,isFirstTimeThisTurn);
	end
end

local function TimedTurnWrapper(handler,label)
	return function(playerID,isFirstTimeThisTurn)
		InvokeTurnHandler(handler,label,playerID,isFirstTimeThisTurn);
	end;
end

function LOTM_MP_TurnSync.Add(handler, label)
	if type(handler) ~= "function" then
		error("[LOTM][MPTurnSync] invalid handler " .. tostring(label));
	end
	if not LOTM_MP_TurnSync.IsNetworkGame() then
		local wrapper=TimedTurnWrapper(handler,label);
		LOTM_MP_TurnSync._wrappers[#LOTM_MP_TurnSync._wrappers + 1]=wrapper;
		Events.PlayerTurnActivated.Add(wrapper);
		return "SINGLE_PLAYER_LEGACY";
	end
	if GameEvents == nil or GameEvents.PlayerTurnStarted == nil then
		error("[LOTM][MPTurnSync] synchronized PlayerTurnStarted unavailable for "
			.. tostring(label));
	end
	RegisterNetworkTurnHandler(handler,label);
	print("[LOTM][MPTurnSync] synchronized handler=" .. tostring(label));
	return "NETWORK_SYNCHRONIZED";
end

-- Some legacy systems already used the synchronized Gameplay event in single
-- player. Route only their network branch through the ordered dispatcher.
function LOTM_MP_TurnSync.AddSynchronized(handler,label)
	if type(handler) ~= "function" then
		error("[LOTM][MPTurnSync] invalid synchronized handler " .. tostring(label));
	end
	if not LOTM_MP_TurnSync.IsNetworkGame() then
		local wrapper=TimedTurnWrapper(handler,label);
		LOTM_MP_TurnSync._wrappers[#LOTM_MP_TurnSync._wrappers + 1]=wrapper;
		GameEvents.PlayerTurnStarted.Add(wrapper);
		return "SINGLE_PLAYER_SYNCHRONIZED_LEGACY";
	end
	if GameEvents == nil or GameEvents.PlayerTurnStarted == nil then
		error("[LOTM][MPTurnSync] synchronized PlayerTurnStarted unavailable for "
			.. tostring(label));
	end
	RegisterNetworkTurnHandler(handler,label);
	print("[LOTM][MPTurnSync] ordered synchronized handler=" .. tostring(label));
	return "NETWORK_SYNCHRONIZED_ORDERED";
end

-- Startup reconciliation is a global operation (it may scan every player,
-- attach modifiers, or consume a deterministic random stream).  In a network
-- game every peer must enter it from the same world-turn edge.  Do not use the
-- first PlayerTurnStarted callback observed by a peer: a client can still be
-- loading and observe a different player first.  The lowest alive major is a
-- stable, engine-owned anchor and is also the convention used by the rescue
-- phase schedulers.
local function LowestAliveMajorID()
	local lowest = nil;
	if PlayerManager ~= nil and PlayerManager.GetAliveMajorIDs ~= nil then
		for _, value in ipairs(PlayerManager.GetAliveMajorIDs() or {}) do
			local playerID = tonumber(value);
			if playerID ~= nil and (lowest == nil or playerID < lowest) then
				lowest = playerID;
			end
		end
	end
	return lowest;
end

function LOTM_MP_TurnSync.GetStableAnchorPlayerID()
	return LowestAliveMajorID();
end

function LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID)
	local anchor = LowestAliveMajorID();
	return anchor ~= nil and tonumber(playerID) == anchor;
end

local function ReadNumericGameProperty(key)
	if Game == nil or Game.GetProperty == nil then return nil; end
	-- Civ VI may return zero Lua values for an absent Property. Assigning
	-- first forces one nil value, so tonumber is never invoked with no args.
	local rawValue = Game.GetProperty(key);
	return rawValue ~= nil and tonumber(rawValue) or nil;
end

local function RescueStartupReady(label)
	if not LOTM_MP_TurnSync.IsNetworkGame() then return true; end
	if not LOTM_MP_TurnSync.IsRescueModeConfigured() then return true; end
	if tostring(label) == "RescuePhase1" then return true; end
	if tostring(label) == "RescuePhase2A" then
		return Game ~= nil and Game.GetProperty ~= nil
			and Game.GetProperty("LOTM_RESCUE_PHASE1_STATE") == "READY";
	end
	local readyTurn = ReadNumericGameProperty("LOTM_RESCUE_PHASE2A_READY_GAME_TURN");
	local currentTurn = Game ~= nil and Game.GetCurrentGameTurn ~= nil
		and Game.GetCurrentGameTurn() or 0;
	return Game ~= nil and Game.GetProperty ~= nil
		and Game.GetProperty("LOTM_RESCUE_PHASE1_STATE") == "READY"
		and Game.GetProperty("LOTM_RESCUE_PHASE2A_STATE") == "READY"
		and readyTurn ~= nil and currentTurn > readyTurn;
end

local function RescueRuntimeReady()
	if not LOTM_MP_TurnSync.IsNetworkGame() then return true; end
	if not LOTM_MP_TurnSync.IsRescueModeConfigured() then return true; end
	local readyTurn = ReadNumericGameProperty("LOTM_RESCUE_PHASE2A_READY_GAME_TURN");
	local currentTurn = Game ~= nil and Game.GetCurrentGameTurn ~= nil
		and Game.GetCurrentGameTurn() or 0;
	return Game ~= nil and Game.GetProperty ~= nil
		and Game.GetProperty("LOTM_RESCUE_PHASE1_STATE") == "READY"
		and Game.GetProperty("LOTM_RESCUE_PHASE2A_STATE") == "READY"
		and readyTurn ~= nil and currentTurn > readyTurn;
end

-- Intentionally local: a Lua exception can be client-specific. Writing a
-- fault code/property only on the failing peer would itself create persistent
-- synchronized-state divergence instead of broadcasting the failure.
local function LatchDispatcherFault(kind,label,details)
	if LOTM_MP_TurnSync._dispatcherFault then return; end
	LOTM_MP_TurnSync._dispatcherFault = {
		Kind=tostring(kind),
		Label=tostring(label),
		Error=tostring(details)
	};
	print("[LOTM][MPTurnSync] FATAL dispatcher fault kind=" .. tostring(kind)
		.. " label=" .. tostring(label) .. " error=" .. tostring(details)
		.. "; all later network dispatch disabled");
end

local function ClaimNetworkTurn(playerID)
	local turn = Game.GetCurrentGameTurn();
	local key = "LOTM_MP_TURNSYNC_LAST_CLAIMED_TURN:" .. tostring(tonumber(playerID) or -1);
	local claimedTurn = ReadNumericGameProperty(key);
	if claimedTurn == tonumber(turn) then return false; end
	Game.SetProperty(key,turn);
	return true;
end

function LOTM_MP_TurnSync.RunPendingStartups(triggerPlayerID,source)
	if LOTM_MP_TurnSync._dispatcherFault then return false; end
	local anchor = LowestAliveMajorID();
	if anchor == nil then
		print("[LOTM][MPTurnSync] startup deferred reason=NO_ALIVE_MAJOR source="
			.. tostring(source or "UNKNOWN"));
		return false;
	end
	local stagedRescue = LOTM_MP_TurnSync.IsNetworkGame()
		and LOTM_MP_TurnSync.IsRescueModeConfigured();
	local currentTurn = Game ~= nil and Game.GetCurrentGameTurn ~= nil
		and Game.GetCurrentGameTurn() or 0;
	local lastRescueStartupTurn = ReadNumericGameProperty(
		"LOTM_MP_TURNSYNC_LAST_RESCUE_STARTUP_TURN");
	if stagedRescue and lastRescueStartupTurn == tonumber(currentTurn) then
		return false;
	end
	for _,entry in ipairs(LOTM_MP_TurnSync._startupHandlers) do
		if not entry.Completed and RescueStartupReady(entry.Label) then
			local ok,details = pcall(entry.Handler,anchor);
			if not ok then
				LatchDispatcherFault("STARTUP",entry.Label,details);
				return false;
			end
			entry.Completed = true;
			print("[LOTM][MPTurnSync] synchronized startup=" .. tostring(entry.Label)
				.. " anchor=" .. tostring(anchor)
				.. " trigger=" .. tostring(triggerPlayerID)
				.. " source=" .. tostring(source or "UNKNOWN"));
			-- Phase 1 reserves 76 plots and Phase 2 creates four cities plus their
			-- territory and walls. Keep those native mutations in separate network
			-- turns; the single-player RunStartup path remains immediate below.
			local stagedHeavy = stagedRescue and (tostring(entry.Label)=="RescuePhase1"
				or tostring(entry.Label)=="RescuePhase2A");
			if stagedHeavy then
				Game.SetProperty("LOTM_MP_TURNSYNC_LAST_RESCUE_STARTUP_TURN",currentTurn);
				print("[LOTM][MPTurnSync] rescue startup staged turn="
					.. tostring(currentTurn) .. " completed=" .. tostring(entry.Label)
					.. " nextStage=NEXT_WORLD_TURN");
				return false;
			end
		end
	end
	for _,entry in ipairs(LOTM_MP_TurnSync._startupHandlers) do
		if not entry.Completed then return false; end
	end
	return true;
end

local function DispatchNetworkTurn(playerID)
	if LOTM_MP_TurnSync._dispatcherFault then return; end
	local anchor = LowestAliveMajorID();
	if anchor ~= nil and tonumber(playerID) == anchor then
		LOTM_MP_TurnSync.RunPendingStartups(playerID,"PLAYER_TURN_STARTED");
		if LOTM_MP_TurnSync._dispatcherFault then return; end
	end
	-- Startup completion is local to this Lua context and must be rebuilt after
	-- a save load/reconnect.  The turn claim is synchronized and persistent, so
	-- checking it first would skip reconciliation when re-entering a turn that
	-- the previous context already claimed. Runtime settlement remains behind
	-- the claim and therefore stays exactly-once per player/game turn.
	if not ClaimNetworkTurn(playerID) then return; end
	if not RescueRuntimeReady() then return; end
	for _,entry in ipairs(LOTM_MP_TurnSync._startupHandlers) do
		if not entry.Completed then return; end
	end
	for _,entry in ipairs(LOTM_MP_TurnSync._turnHandlers) do
		local ok,details = pcall(InvokeTurnHandler,entry.Handler,entry.Label,playerID,true);
		if not ok then
			LatchDispatcherFault("TURN",entry.Label,details);
			return;
		end
	end
end

local function EnsureNetworkDispatcher()
	if LOTM_MP_TurnSync._dispatcherInstalled then return; end
	LOTM_MP_TurnSync._dispatcherInstalled = true;
	LOTM_MP_TurnSync._wrappers[#LOTM_MP_TurnSync._wrappers + 1] = DispatchNetworkTurn;
	GameEvents.PlayerTurnStarted.Add(DispatchNetworkTurn);
	print("[LOTM][MPTurnSync] ordered network dispatcher installed");
end

RegisterNetworkTurnHandler = function(handler,label)
	LOTM_MP_TurnSync._turnHandlers[#LOTM_MP_TurnSync._turnHandlers + 1] = {
		Handler=handler,Label=label
	};
	EnsureNetworkDispatcher();
end

RegisterNetworkStartupHandler = function(handler,label)
	LOTM_MP_TurnSync._startupHandlers[#LOTM_MP_TurnSync._startupHandlers + 1] = {
		Handler=handler,Label=label,Completed=false
	};
	EnsureNetworkDispatcher();
end

-- Gameplay script contexts are created independently on every peer. Mutating
-- synchronized state directly while those contexts are still loading can race
-- the initial sync snapshot. Keep the original immediate startup in single
-- player, but defer network startup reconciliation to the first synchronized
-- player-turn event received by every peer.
function LOTM_MP_TurnSync.RunStartup(handler, label)
	if type(handler) ~= "function" then
		error("[LOTM][MPTurnSync] invalid startup handler " .. tostring(label));
	end
	if not LOTM_MP_TurnSync.IsNetworkGame() then
		handler();
		return "SINGLE_PLAYER_IMMEDIATE";
	end
	if GameEvents == nil or GameEvents.PlayerTurnStarted == nil then
		error("[LOTM][MPTurnSync] synchronized startup event unavailable for "
			.. tostring(label));
	end
	RegisterNetworkStartupHandler(handler,label);
	print("[LOTM][MPTurnSync] deferred startup=" .. tostring(label));
	return "NETWORK_DEFERRED";
end

print("[LOTM][MPTurnSync] initialized version="
	.. tostring(LOTM_MP_TurnSync.VERSION)
	.. " network=" .. tostring(LOTM_MP_TurnSync.IsNetworkGame())
	.. " rescueMode=" .. tostring(LOTM_MP_TurnSync.IsRescueModeConfigured())
	.. " source=INCLUDE");
