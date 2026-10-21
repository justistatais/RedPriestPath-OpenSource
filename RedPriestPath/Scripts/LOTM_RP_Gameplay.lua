-- Single authoritative Gameplay context.
-- The included modules intentionally share LOTM_RP_State in this environment.

-- Explicit per-context sentinel. Lua globals are not shared between Civ VI
-- Gameplay add-ins, so the standalone Rescue Phase 1/2/3 contexts see nil and
-- can remain passive in multiplayer while this entrypoint owns registration.
LOTM_RP_MASTER_GAMEPLAY_CONTEXT = true;

-- Bootstrap the multiplayer turn adapter inside the authoritative entrypoint.
-- Do not depend on ImportFiles/include ordering for this critical dependency:
-- Civ VI applies AddGameplayScripts and ImportFiles as separate actions, and
-- an unresolved include returns without creating the expected global.
local function InstallTurnSyncEntrypoint()
	if type(LOTM_MP_TurnSync) == "table"
		and tonumber(LOTM_MP_TurnSync.VERSION or 0) >= 7
		and type(LOTM_MP_TurnSync.Add) == "function"
		and type(LOTM_MP_TurnSync.AddSynchronized) == "function"
		and type(LOTM_MP_TurnSync.RunStartup) == "function"
		and type(LOTM_MP_TurnSync.RunPendingStartups) == "function"
		and type(LOTM_MP_TurnSync.IsRescueModeConfigured) == "function"
		and type(LOTM_MP_TurnSync.Random) == "function" then
		return;
	end

	LOTM_MP_TurnSync = {
		VERSION = 7,
		_wrappers = {},
		_startupWrappers = {},
		_turnHandlers = {},
		_startupHandlers = {},
		_dispatcherInstalled = false,
		_stableSeed = nil,
		_dispatcherFault = false
	};
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

	-- Action Criteria has already selected the rescue-only gameplay database
	-- before this context is created.  That database marker is authoritative
	-- here: a custom GameConfiguration value can still be nil while network
	-- Gameplay contexts are loading, which previously skipped Phase 1/2/3 even
	-- though the lobby and Modding layer had enabled Redemption Mode.
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
end

InstallTurnSyncEntrypoint();
if type(LOTM_MP_TurnSync) ~= "table"
	or tonumber(LOTM_MP_TurnSync.VERSION or 0) < 6
	or type(LOTM_MP_TurnSync.Add) ~= "function"
	or type(LOTM_MP_TurnSync.AddSynchronized) ~= "function"
	or type(LOTM_MP_TurnSync.RunStartup) ~= "function"
	or type(LOTM_MP_TurnSync.RunPendingStartups) ~= "function"
	or type(LOTM_MP_TurnSync.IsRescueModeConfigured) ~= "function"
	or type(LOTM_MP_TurnSync.Random) ~= "function" then
	error("[LOTM][MPTurnSync] FATAL entrypoint bootstrap failed");
end
print("[LOTM][MPTurnSync] initialized version="
	.. tostring(LOTM_MP_TurnSync.VERSION)
	.. " network=" .. tostring(LOTM_MP_TurnSync.IsNetworkGame())
	.. " rescueMode=" .. tostring(LOTM_MP_TurnSync.IsRescueModeConfigured())
	.. " source=ENTRYPOINT");

-- Rescue Phase 1/2/3 are owned by this one bundled Gameplay context in both
-- single-player and multiplayer.  Keeping the three phases here removes the
-- cross-action VFS dependency that is unsafe when Civ VI has retained an older
-- component table in Mods.sqlite; the network-only order check below still
-- protects the synchronized dispatcher contract.
local rescueConfigured = LOTM_MP_TurnSync.IsRescueModeConfigured();
if rescueConfigured then
	include("LOTM_RESCUE_Phase1");
	include("LOTM_RESCUE_Phase2Test");
	include("LOTM_RESCUE_Phase3");
	-- Direct rescue monster creation is loaded only for the rescue branch;
	-- ordinary games never instantiate this module.
	include("LOTM_RESCUE_DirectMonsters");
	if LOTM_MP_TurnSync.IsNetworkGame() then
	local function LabelIndex(entries,label)
		for index,entry in ipairs(entries or {}) do
			if tostring(entry.Label) == tostring(label) then return index; end
		end
		return nil;
	end
	local phase1Startup=LabelIndex(LOTM_MP_TurnSync._startupHandlers,"RescuePhase1");
	local phase2Startup=LabelIndex(LOTM_MP_TurnSync._startupHandlers,"RescuePhase2A");
	local phase2Turn=LabelIndex(LOTM_MP_TurnSync._turnHandlers,"RescuePhase2");
	local phase3Turn=LabelIndex(LOTM_MP_TurnSync._turnHandlers,"RescuePhase3");
	if phase1Startup==nil or phase2Startup==nil or phase1Startup>=phase2Startup
		or phase2Turn==nil or phase3Turn==nil or phase2Turn>=phase3Turn then
		error("[LOTM_RESCUE] FATAL ordered network bootstrap registration incomplete");
	end
	print("[LOTM_RESCUE] ordered network bootstrap registration verified phase1Startup="
		..tostring(phase1Startup).." phase2Startup="..tostring(phase2Startup)
		.." phase2Turn="..tostring(phase2Turn).." phase3Turn="..tostring(phase3Turn));
	end
end

include("LOTM_UnitAddedPerf");
include("LOTM_RP_Lifecycle");
include("LOTM_RP_Progression");
include("LOTM_PP_Perfect");
include("LOTM_BE_BlackEmperor");
if not rescueConfigured then
	include("LOTM_TP_Thief");
end
include("LOTM_WORLD_State");
include("LOTM_WORLD_Barbarians");
if LOTM_RESCUE_SyncActions==nil then include("LOTM_RESCUE_SyncActions"); end
include("LOTM_RESCUE_Difficulty");
	include("LOTM_RESCUE_Phase5");
	include("LOTM_RESCUE_Phase6");
	include("LOTM_RESCUE_Thief");
if not rescueConfigured then include("LOTM_AI_Cult_Difficulty"); end
include("LOTM_AI_Cults");
include("LOTM_AI_Cult_Hanged");
if not rescueConfigured then LOTM_AI_Cult_Difficulty.Register(); end
include("LOTM_RESCUE_Phase7");
include("LOTM_RESCUE_Phase8");
include("LOTM_RESCUE_Phase9");
include("LOTM_RESCUE_Phase9Digestion");
include("LOTM_RESCUE_Phase10A");
include("LOTM_RESCUE_Phase10");
include("LOTM_WORLD_Monsters");
include("LOTM_RESCUE_RuntimeEvents");
include("LOTM_WORLD_Events");
include("LOTM_PP_Artifacts");
include("LOTM_RESCUE_Artifacts");
include("LOTM_WORLD_GoodyHuts");
include("LOTM_PP_Workshops");
include("LOTM_GodBlessings");
include("LOTM_WORLD_Churches");
include("LOTM_JUSTICE_Governor");
include("LOTM_MS_Governors");
if rescueConfigured then include("LOTM_RESCUE_StarGovernor"); end
include("LOTM_RP_Arson");
include("LOTM_RP_Advanced");
include("LOTM_RP_CommandProbe");
include("LOTM_DEV_QuickTest");

-- Registered last so each event batch report includes every module above.
Events.UnitAddedToMap.Add(function() LOTM_UnitAddedPerf.EventCompleted(); end);
LOTM_MP_TurnSync.Add(function(playerID,isFirstTimeThisTurn)
	if not LOTM_UnitAddedPerf.FirstTurnReported and isFirstTimeThisTurn~=false then
		LOTM_UnitAddedPerf.FirstTurnReported=true;
		LOTM_UnitAddedPerf.Report("firstPlayerTurn");
		LOTM_UnitAddedPerf.Enabled=false;
	end
end,"UnitAddedPerf");
