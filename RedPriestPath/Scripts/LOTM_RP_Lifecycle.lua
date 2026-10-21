-- Phase 05 release-candidate authoritative Gameplay state, path selection,
-- hero lifecycle, digestion, and sequence grants.
include("LOTM_Effects");

local LOTM_RP_STATE_VERSION :number = 36;
local LOTM_PATH_HOLDER_PROMOTION_CLASS :string = "PROMOTION_CLASS_LOTM_RP_PATH_HOLDER";
local LOTM_RP_HERO_TYPE :string = "UNIT_LOTM_RP_PATH_HOLDER";
local LOTM_PP_HERO_TYPE :string = "UNIT_LOTM_PP_PATH_HOLDER";
local LOTM_BE_HERO_TYPE :string = "UNIT_LOTM_BE_PATH_HOLDER";
local LOTM_TP_HERO_TYPE :string = "UNIT_LOTM_TP_PATH_HOLDER";
local LOTM_RP_SELECTED_PATH :string = "PATH_RED_PRIEST";
local LOTM_PP_SELECTED_PATH :string = "PATH_PERFECT";
local LOTM_BE_SELECTED_PATH :string = "PATH_BLACK_EMPEROR";
local LOTM_TP_SELECTED_PATH :string = "PATH_THIEF";
local LOTM_RP_RESPAWN_DELAY :number = 5;
local LOTM_RP_DIGESTION_TARGET :number = 6;
local LOTM_RP_DIGESTION_TURN_CAP :number = 2;
local LOTM_RP_HUNTER_MODIFIER :string = "LOTM_RP_MOD_GRANT_HUNTER_INSTINCT";
local LOTM_RP_PROVOKER_MODIFIER :string = "LOTM_RP_MOD_GRANT_PROVOKER";
local LOTM_RP_PROVOKER_PROJECT_MODIFIER :string = "LOTM_RP_MOD_ALLOW_PROVOKER_PROJECT";
local LOTM_RP_PYROMANIAC_PROJECT_MODIFIER :string = "LOTM_RP_MOD_ALLOW_PYROMANIAC_PROJECT";
local LOTM_RP_CONSPIRATOR_PROJECT_MODIFIER :string = "LOTM_RP_MOD_ALLOW_CONSPIRATOR_PROJECT";
local LOTM_RP_REAPER_PROJECT_MODIFIER :string = "LOTM_RP_MOD_ALLOW_REAPER_PROJECT";
local LOTM_RP_IRONBLOOD_PROJECT_MODIFIER :string = "LOTM_RP_MOD_ALLOW_IRONBLOOD_PROJECT";
local LOTM_RP_WAR_BISHOP_PROJECT_MODIFIER :string = "LOTM_RP_MOD_ALLOW_WAR_BISHOP_PROJECT";
local LOTM_RP_WEATHER_WARLOCK_PROJECT_MODIFIER :string = "LOTM_RP_MOD_ALLOW_WEATHER_WARLOCK_PROJECT";
local LOTM_RP_CONQUEROR_PROJECT_MODIFIER :string = "LOTM_RP_MOD_ALLOW_CONQUEROR_PROJECT";
local LOTM_RP_WAR_FESTIVAL_PROJECT_MODIFIER :string = "LOTM_RP_MOD_ALLOW_WAR_FESTIVAL_PROJECT";
local LOTM_RP_UNCONSECRATED_WAR_FESTIVAL_PROJECT_MODIFIER :string =
	"LOTM_RP_MOD_ALLOW_UNCONSECRATED_WAR_FESTIVAL_PROJECT";
local LOTM_RP_IRONBLOOD_MODIFIER :string = "LOTM_RP_MOD_IRONBLOOD_FRIENDLY_STRENGTH_AURA_V2";
local LOTM_RP_IRONBLOOD_MOVEMENT_MODIFIER :string = "LOTM_RP_MOD_IRONBLOOD_FRIENDLY_MOVEMENT_AURA_V2";
local LOTM_RP_WAR_BISHOP_PRODUCTION_MODIFIER :string = "LOTM_RP_MOD_WAR_BISHOP_PRODUCTION";
local LOTM_RP_WAR_BISHOP_WEARINESS_MODIFIER :string = "LOTM_RP_MOD_WAR_BISHOP_WEARINESS";
local LOTM_RP_WEATHER_ENEMY_STRENGTH_MODIFIER :string = "LOTM_RP_MOD_WEATHER_ENEMY_STRENGTH_AURA_V2";
local LOTM_RP_WEATHER_ENEMY_MOVEMENT_MODIFIER :string = "LOTM_RP_MOD_WEATHER_ENEMY_MOVEMENT_AURA_V2";
local LOTM_RP_WEATHER_ENEMY_WEARINESS_MODIFIER :string = "LOTM_RP_MOD_WEATHER_ENEMY_WEARINESS_AURA_V2";
local LOTM_RP_WEATHER_FRIENDLY_MOVEMENT_MODIFIER :string = "LOTM_RP_MOD_WEATHER_FRIENDLY_MOVEMENT_AURA_V2";
local LOTM_RP_CONQUEST_BYPASS_WALLS_MODIFIER :string = "LOTM_RP_MOD_GRANT_CONQUEST_BYPASS_WALLS";
local LOTM_RP_RED_PRIEST_WAR_PRODUCTION_MODIFIER :string = "LOTM_RP_MOD_RED_PRIEST_WAR_PRODUCTION";
-- Resource 378 revalidates old unlocks against actual digestion and the
-- canonical database rule before repairing a missing project modifier.
local LOTM_RP_PROJECT_UNLOCK_REPAIR_VERSION :number = 5;
-- TEST ONLY: set false (or comment this block) to remove the combat toggle.
local LOTM_TEST_COMBAT_TOGGLE_ENABLED :boolean = false;
local LOTM_TEST_COMBAT_COMMAND :string = "LOTM_RP_Command_TestCombatToggle";
local LOTM_TEST_COMBAT_PLUS_MODIFIER :string = "LOTM_TP_TEST_COMBAT_PLUS_200";
local LOTM_TEST_COMBAT_MINUS_MODIFIER :string = "LOTM_TP_TEST_COMBAT_MINUS_200";
local LOTM_TEST_CAPITAL_PRODUCTION_PLUS_MODIFIER :string = "LOTM_TP_TEST_CAPITAL_PRODUCTION_PLUS_999";
local LOTM_TEST_CAPITAL_PRODUCTION_MINUS_MODIFIER :string = "LOTM_TP_TEST_CAPITAL_PRODUCTION_MINUS_999";
-- A saved property can outlive a runtime modifier instance.  Reconcile the
-- active test state once per player after the save has restored Player data.
local LOTM_TEST_COMBAT_RECONCILED :table = {};

local function IsRescueMode()
	local state = tonumber(Game.GetProperty("LOTM_RESCUE_MODE") or 0) or 0;
	if state == 1 then
		return true;
	end
	if LOTM_MP_TurnSync ~= nil
		and type(LOTM_MP_TurnSync.IsRescueModeConfigured) == "function" then
		return LOTM_MP_TurnSync.IsRescueModeConfigured();
	end
	local configured = GameConfiguration.GetValue("GAMEMODE_LOTM_RESCUE");
	return configured == true or tonumber(configured or 0) == 1;
end

local LOTM_RP_PROPERTIES :table = {
	StateVersion = "LOTM_RP_STATE_VERSION",
	Path = "LOTM_RP_PATH",
	PathDecided = "LOTM_RP_PATH_DECIDED",
	Sequence = "LOTM_RP_SEQUENCE",
	DigestA = "LOTM_RP_DIGEST_A",
	DigestB = "LOTM_RP_DIGEST_B",
	DigestTurn = "LOTM_RP_DIGEST_TURN",
	DigestTurnGain = "LOTM_RP_DIGEST_TURN_GAIN",
	UnitID = "LOTM_RP_UNIT_ID",
	RespawnAt = "LOTM_RP_RESPAWN_AT",
	ArsonReadyAt = "LOTM_RP_ARSON_READY_AT",
	PlanTargetID = "LOTM_RP_PLAN_TARGET_ID",
	PlanTargetReadyAt = "LOTM_RP_PLAN_TARGET_READY_AT",
	PlanWasAtWar = "LOTM_RP_PLAN_WAS_AT_WAR",
	PlanGoldActive = "LOTM_RP_PLAN_GOLD_ACTIVE",
	PlanGoldModifierActive = "LOTM_RP_PLAN_GOLD_MODIFIER_ACTIVE",
	SavedXP = "LOTM_RP_SAVED_XP",
	HunterXPBaseline = "LOTM_RP_HUNTER_XP_BASELINE",
	ChurchStartTurn = "LOTM_RP_CHURCH_START_TURN",
	TrueGodChurch = "LOTM_RP_TRUE_GOD_CHURCH",
	CanAdvanceSequenceZero = "LOTM_RP_CAN_ADVANCE_SEQUENCE_0",
	SequenceZeroCeremonySerial = "LOTM_RP_SEQUENCE0_CEREMONY_SERIAL",
	SequenceZeroCeremonyReadyTurn = "LOTM_RP_SEQUENCE0_CEREMONY_READY_TURN",
	SequenceZeroCeremonyAckSerial = "LOTM_RP_SEQUENCE0_CEREMONY_ACK_SERIAL",
	OpeningComicShown = "LOTM_RP_OPENING_COMIC_SHOWN",
	SavedPromotions = "LOTM_RP_SAVED_PROMOTIONS",
	PromotionTreeMigrated = "LOTM_RP_PROMOTION_TREE_MIGRATED",
	SavedName = "LOTM_RP_SAVED_NAME",
	RiflingAttached = "LOTM_RP_MOD_RIFLING_ATTACHED",
	PlasticsAttached = "LOTM_RP_MOD_PLASTICS_ATTACHED",
	TechIronWorkingAttached = "LOTM_RP_TECH_IRON_WORKING_ATTACHED",
	TechApprenticeshipAttached = "LOTM_RP_TECH_APPRENTICESHIP_ATTACHED",
	TechGunpowderAttached = "LOTM_RP_TECH_GUNPOWDER_ATTACHED",
	TechMilitaryScienceAttached = "LOTM_RP_TECH_MILITARY_SCIENCE_ATTACHED",
	TechReplaceablePartsAttached = "LOTM_RP_TECH_REPLACEABLE_PARTS_ATTACHED",
	TechSatellitesAttached = "LOTM_RP_TECH_SATELLITES_ATTACHED",
	HunterAttached = "LOTM_RP_MOD_HUNTER_ATTACHED",
	ProvokerAttached = "LOTM_RP_MOD_PROVOKER_ATTACHED",
	IronbloodAttached = "LOTM_RP_MOD_IRONBLOOD_ATTACHED",
	IronbloodMovementAttached = "LOTM_RP_MOD_IRONBLOOD_MOVEMENT_ATTACHED",
	IronbloodFriendlyStrengthV2Attached = "LOTM_RP_MOD_IRONBLOOD_FRIENDLY_STRENGTH_V2_ATTACHED",
	IronbloodFriendlyMovementV2Attached = "LOTM_RP_MOD_IRONBLOOD_FRIENDLY_MOVEMENT_V2_ATTACHED",
	WarBishopProductionAttached = "LOTM_RP_MOD_WAR_BISHOP_PRODUCTION_ATTACHED",
	WarBishopWearinessAttached = "LOTM_RP_MOD_WAR_BISHOP_WEARINESS_ATTACHED",
	WeatherEnemyStrengthAttached = "LOTM_RP_MOD_WEATHER_ENEMY_STRENGTH_ATTACHED",
	WeatherEnemyMovementAttached = "LOTM_RP_MOD_WEATHER_ENEMY_MOVEMENT_ATTACHED",
	WeatherEnemyWearinessAttached = "LOTM_RP_MOD_WEATHER_ENEMY_WEARINESS_ATTACHED",
	WeatherEnemyStrengthV2Attached = "LOTM_RP_MOD_WEATHER_ENEMY_STRENGTH_V2_ATTACHED",
	WeatherEnemyMovementV2Attached = "LOTM_RP_MOD_WEATHER_ENEMY_MOVEMENT_V2_ATTACHED",
	WeatherEnemyWearinessV2Attached = "LOTM_RP_MOD_WEATHER_ENEMY_WEARINESS_V2_ATTACHED",
	WeatherFriendlyMovementAttached = "LOTM_RP_MOD_WEATHER_FRIENDLY_MOVEMENT_ATTACHED",
	WeatherFriendlyMovementV2Attached = "LOTM_RP_MOD_WEATHER_FRIENDLY_MOVEMENT_V2_ATTACHED",
	ConquestBypassWallsAttached = "LOTM_RP_MOD_CONQUEST_BYPASS_WALLS_ATTACHED",
	RedPriestWarProductionAttached = "LOTM_RP_MOD_RED_PRIEST_WAR_PRODUCTION_ATTACHED",
	TestCombatBoostActive = "LOTM_TEST_COMBAT_BOOST_ACTIVE",
	ProvokerProjectUnlocked = "LOTM_RP_PROJECT_PROVOKER_UNLOCKED",
	PyromaniacProjectUnlocked = "LOTM_RP_PROJECT_PYROMANIAC_UNLOCKED",
	ConspiratorProjectUnlocked = "LOTM_RP_PROJECT_CONSPIRATOR_UNLOCKED",
	ReaperProjectUnlocked = "LOTM_RP_PROJECT_REAPER_UNLOCKED",
	IronbloodProjectUnlocked = "LOTM_RP_PROJECT_IRONBLOOD_UNLOCKED",
	WarBishopProjectUnlocked = "LOTM_RP_PROJECT_WAR_BISHOP_UNLOCKED",
	WeatherWarlockProjectUnlocked = "LOTM_RP_PROJECT_WEATHER_WARLOCK_UNLOCKED",
	ConquerorProjectUnlocked = "LOTM_RP_PROJECT_CONQUEROR_UNLOCKED",
	WarFestivalProjectUnlocked = "LOTM_RP_PROJECT_WAR_FESTIVAL_UNLOCKED",
	UnconsecratedWarFestivalProjectUnlocked =
		"LOTM_RP_PROJECT_UNCONSECRATED_WAR_FESTIVAL_UNLOCKED",
	ProjectUnlockRepairVersion = "LOTM_RP_PROJECT_UNLOCK_REPAIR_VERSION",
};

local LOTM_RP_DEFAULTS :table = {
	{ key = LOTM_RP_PROPERTIES.Path, value = "NONE" },
	{ key = LOTM_RP_PROPERTIES.PathDecided, value = 0 },
	{ key = LOTM_RP_PROPERTIES.Sequence, value = 9 },
	{ key = LOTM_RP_PROPERTIES.DigestA, value = 0 },
	{ key = LOTM_RP_PROPERTIES.DigestB, value = 0 },
	{ key = LOTM_RP_PROPERTIES.DigestTurn, value = -1 },
	{ key = LOTM_RP_PROPERTIES.DigestTurnGain, value = 0 },
	{ key = LOTM_RP_PROPERTIES.UnitID, value = -1 },
	{ key = LOTM_RP_PROPERTIES.RespawnAt, value = -1 },
	{ key = LOTM_RP_PROPERTIES.ArsonReadyAt, value = -1 },
	{ key = LOTM_RP_PROPERTIES.PlanTargetID, value = -1 },
	{ key = LOTM_RP_PROPERTIES.PlanTargetReadyAt, value = -1 },
	{ key = LOTM_RP_PROPERTIES.PlanWasAtWar, value = -1 },
	{ key = LOTM_RP_PROPERTIES.PlanGoldActive, value = 0 },
	{ key = LOTM_RP_PROPERTIES.PlanGoldModifierActive, value = 0 },
	{ key = LOTM_RP_PROPERTIES.SavedXP, value = 0 },
	{ key = LOTM_RP_PROPERTIES.HunterXPBaseline, value = -1 },
	{ key = LOTM_RP_PROPERTIES.ChurchStartTurn, value = -1 },
	{ key = LOTM_RP_PROPERTIES.TrueGodChurch, value = 0 },
	{ key = LOTM_RP_PROPERTIES.CanAdvanceSequenceZero, value = 0 },
	{ key = LOTM_RP_PROPERTIES.SequenceZeroCeremonySerial, value = 0 },
	{ key = LOTM_RP_PROPERTIES.SequenceZeroCeremonyReadyTurn, value = -1 },
	{ key = LOTM_RP_PROPERTIES.SequenceZeroCeremonyAckSerial, value = 0 },
	{ key = LOTM_RP_PROPERTIES.OpeningComicShown, value = 0 },
	{ key = LOTM_RP_PROPERTIES.SavedPromotions, value = "" },
	{ key = LOTM_RP_PROPERTIES.PromotionTreeMigrated, value = 1 },
	{ key = LOTM_RP_PROPERTIES.SavedName, value = "" },
	{ key = LOTM_RP_PROPERTIES.RiflingAttached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.PlasticsAttached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.TechIronWorkingAttached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.TechApprenticeshipAttached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.TechGunpowderAttached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.TechMilitaryScienceAttached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.TechReplaceablePartsAttached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.TechSatellitesAttached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.HunterAttached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.ProvokerAttached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.IronbloodAttached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.IronbloodMovementAttached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.IronbloodFriendlyStrengthV2Attached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.IronbloodFriendlyMovementV2Attached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.WarBishopProductionAttached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.WarBishopWearinessAttached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.WeatherEnemyStrengthAttached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.WeatherEnemyMovementAttached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.WeatherEnemyWearinessAttached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.WeatherEnemyStrengthV2Attached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.WeatherEnemyMovementV2Attached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.WeatherEnemyWearinessV2Attached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.WeatherFriendlyMovementAttached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.WeatherFriendlyMovementV2Attached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.ConquestBypassWallsAttached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.RedPriestWarProductionAttached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.TestCombatBoostActive, value = 0 },
	{ key = LOTM_RP_PROPERTIES.ProvokerProjectUnlocked, value = 0 },
	{ key = LOTM_RP_PROPERTIES.PyromaniacProjectUnlocked, value = 0 },
	{ key = LOTM_RP_PROPERTIES.ConspiratorProjectUnlocked, value = 0 },
	{ key = LOTM_RP_PROPERTIES.ReaperProjectUnlocked, value = 0 },
	{ key = LOTM_RP_PROPERTIES.IronbloodProjectUnlocked, value = 0 },
	{ key = LOTM_RP_PROPERTIES.WarBishopProjectUnlocked, value = 0 },
	{ key = LOTM_RP_PROPERTIES.WeatherWarlockProjectUnlocked, value = 0 },
	{ key = LOTM_RP_PROPERTIES.ConquerorProjectUnlocked, value = 0 },
	{ key = LOTM_RP_PROPERTIES.WarFestivalProjectUnlocked, value = 0 },
	{ key = LOTM_RP_PROPERTIES.UnconsecratedWarFestivalProjectUnlocked, value = 0 },
	{ key = LOTM_RP_PROPERTIES.ProjectUnlockRepairVersion, value = 0 },
};

local m_creatingHero :table = {};

local function Log(message :string)
	print("[LOTM_RP][Lifecycle] " .. message);
end

local function GetPlayer(playerID :number)
	if playerID == nil then
		return nil;
	end
	return Players[playerID];
end

local function GetHeroTypeIndex(typeName :string)
	local definition = GameInfo.Units[typeName];
	return definition ~= nil and definition.Index or -1;
end

local function IsHeroUnit(unit)
	local unitType = unit ~= nil and unit:GetType() or -1;
	return unit ~= nil
		and not unit:IsDead()
		and not unit:IsDelayedDeath()
		and (unitType == GetHeroTypeIndex(LOTM_RP_HERO_TYPE)
			or unitType == GetHeroTypeIndex(LOTM_PP_HERO_TYPE)
			or unitType == GetHeroTypeIndex(LOTM_BE_HERO_TYPE)
			or unitType == GetHeroTypeIndex(LOTM_TP_HERO_TYPE));
end

local function GetExpectedHeroType(playerID :number)
	local player = GetPlayer(playerID);
	local path = player ~= nil and player:GetProperty(LOTM_RP_PROPERTIES.Path) or "NONE";
	if path == LOTM_PP_SELECTED_PATH then
		return LOTM_PP_HERO_TYPE;
	elseif path == LOTM_BE_SELECTED_PATH then
		return LOTM_BE_HERO_TYPE;
	elseif path == LOTM_TP_SELECTED_PATH then
		return LOTM_TP_HERO_TYPE;
	end
	return LOTM_RP_HERO_TYPE;
end

LOTM_RP_State = LOTM_RP_State or {};

function LOTM_RP_State.EnsurePlayerState(playerID :number)
	local player = GetPlayer(playerID);
	if player == nil then
		return nil;
	end

	local storedVersion = player:GetProperty(LOTM_RP_PROPERTIES.StateVersion);
	if storedVersion ~= nil and storedVersion > LOTM_RP_STATE_VERSION then
		Log("ERROR player=" .. tostring(playerID)
			.. " state version=" .. tostring(storedVersion)
			.. " is newer than supported=" .. tostring(LOTM_RP_STATE_VERSION));
		return player;
	end

	for _, defaultEntry in ipairs(LOTM_RP_DEFAULTS) do
		if player:GetProperty(defaultEntry.key) == nil then
			player:SetProperty(defaultEntry.key, defaultEntry.value);
		end
	end
	-- rc.40 replaces the Recon promotion class. Recreating an existing holder is
	-- required because Gameplay exposes SetPromotion but no removal counterpart;
	-- the one-shot flag prevents inherited Recon modifiers from surviving in saves.
	if storedVersion ~= nil and storedVersion <= 24 then
		player:SetProperty(LOTM_RP_PROPERTIES.PromotionTreeMigrated, 0);
	end

	-- Migrate an already-enabled version-3 save without asking a second time.
	local storedPath = player:GetProperty(LOTM_RP_PROPERTIES.Path);
	if storedVersion ~= nil
		and storedVersion <= 3
		and storedPath == LOTM_RP_SELECTED_PATH then
		player:SetProperty(LOTM_RP_PROPERTIES.Path, LOTM_RP_SELECTED_PATH);
		player:SetProperty(LOTM_RP_PROPERTIES.PathDecided, 1);
	end
	-- rc.20 acknowledged the Sequence 0 ceremony when its UI context entered
	-- the popup queue.  A Firaxis era/age popup could then suppress it even
	-- though Gameplay had already recorded it as shown.  Re-open exactly that
	-- rc.20 serial once on migration; pre-rc.20 Sequence 0 saves have serial 0
	-- and deliberately remain ineligible for backfill.
	if storedVersion == 12
		and (player:GetProperty(LOTM_RP_PROPERTIES.Sequence) or 9) == 0 then
		local ceremonySerial =
			player:GetProperty(LOTM_RP_PROPERTIES.SequenceZeroCeremonySerial) or 0;
		local acknowledgedSerial =
			player:GetProperty(LOTM_RP_PROPERTIES.SequenceZeroCeremonyAckSerial) or 0;
		if ceremonySerial > 0 and acknowledgedSerial >= ceremonySerial then
			player:SetProperty(
				LOTM_RP_PROPERTIES.SequenceZeroCeremonyAckSerial,
				ceremonySerial - 1
			);
			player:SetProperty(
				LOTM_RP_PROPERTIES.SequenceZeroCeremonyReadyTurn,
				Game.GetCurrentGameTurn()
			);
			Log("player=" .. tostring(playerID)
				.. " migrated rc.20 ceremony serial="
				.. tostring(ceremonySerial) .. " for one deferred replay");
		end
	end
	-- rc.29/30 could already advance the Perfect Path to Sequence 0 but did
	-- not schedule its own ceremony. Backfill exactly one pending ceremony
	-- for those saves; the synchronized serial/acknowledgement flow remains
	-- identical to the Red Priest ceremony.
	if storedVersion ~= nil
		and storedVersion <= 17
		and storedPath == LOTM_PP_SELECTED_PATH
		and (player:GetProperty(LOTM_RP_PROPERTIES.Sequence) or 9) == 0
		and (player:GetProperty(LOTM_RP_PROPERTIES.SequenceZeroCeremonySerial) or 0) == 0 then
		player:SetProperty(LOTM_RP_PROPERTIES.SequenceZeroCeremonySerial, 1);
		player:SetProperty(
			LOTM_RP_PROPERTIES.SequenceZeroCeremonyReadyTurn,
			Game.GetCurrentGameTurn()
		);
		Log("player=" .. tostring(playerID)
			.. " backfilled Perfect Path sequence-0 ceremony serial=1");
	end
	player:SetProperty(LOTM_RP_PROPERTIES.StateVersion, LOTM_RP_STATE_VERSION);
	return player;
end

function LOTM_RP_State.IsEnabledPlayer(playerID :number)
	local player = GetPlayer(playerID);
	if player == nil
		or not player:IsAlive()
		or not player:IsMajor()
		or not player:IsHuman() then
		return false;
	end

	player = LOTM_RP_State.EnsurePlayerState(playerID);
	if (player:GetProperty(LOTM_RP_PROPERTIES.PathDecided) or 0) ~= 1 then
		return false;
	end
	return player:GetProperty(LOTM_RP_PROPERTIES.Path) == LOTM_RP_SELECTED_PATH;
end

function LOTM_RP_State.GetPath(playerID :number)
	local player = LOTM_RP_State.EnsurePlayerState(playerID);
	if player == nil
		or (player:GetProperty(LOTM_RP_PROPERTIES.PathDecided) or 0) ~= 1 then
		return "NONE";
	end
	return player:GetProperty(LOTM_RP_PROPERTIES.Path) or "NONE";
end

function LOTM_RP_State.IsPerfectPlayer(playerID :number)
	local player = GetPlayer(playerID);
	return player ~= nil
		and player:IsAlive()
		and player:IsMajor()
		and player:IsHuman()
		and LOTM_RP_State.GetPath(playerID) == LOTM_PP_SELECTED_PATH;
end

function LOTM_RP_State.IsBlackEmperorPlayer(playerID :number)
	local player = GetPlayer(playerID);
	return player ~= nil
		and player:IsAlive()
		and player:IsMajor()
		and player:IsHuman()
		and LOTM_RP_State.GetPath(playerID) == LOTM_BE_SELECTED_PATH;
end

function LOTM_RP_State.IsThiefPlayer(playerID :number)
	local player = GetPlayer(playerID);
	return player ~= nil
		and player:IsAlive()
		and player:IsMajor()
		and player:IsHuman()
		and not IsRescueMode()
		and LOTM_RP_State.GetPath(playerID) == LOTM_TP_SELECTED_PATH;
end

function LOTM_RP_State.IsRescueThiefPlayer(playerID :number)
	local player = GetPlayer(playerID);
	return player ~= nil and player:IsAlive() and player:IsMajor() and player:IsHuman()
		and IsRescueMode() and LOTM_RP_State.GetPath(playerID) == LOTM_TP_SELECTED_PATH;
end

function LOTM_RP_State.IsAnyPathPlayer(playerID :number)
	return LOTM_RP_State.IsEnabledPlayer(playerID)
		or LOTM_RP_State.IsPerfectPlayer(playerID)
		or LOTM_RP_State.IsBlackEmperorPlayer(playerID)
		or LOTM_RP_State.IsThiefPlayer(playerID)
		or LOTM_RP_State.IsRescueThiefPlayer(playerID);
end

function LOTM_RP_State.GetSequence(playerID :number)
	local player = LOTM_RP_State.EnsurePlayerState(playerID);
	return player ~= nil and player:GetProperty(LOTM_RP_PROPERTIES.Sequence) or 9;
end

function LOTM_RP_State.SetSequence(playerID :number, sequence :number)
	local player = LOTM_RP_State.EnsurePlayerState(playerID);
	if player == nil or type(sequence) ~= "number"
		or sequence < 0 or sequence > 9 then
		return false;
	end
	player:SetProperty(LOTM_RP_PROPERTIES.Sequence, sequence);
	return true;
end

local function EncodeStableObjectKey(objectKey)
	local text = tostring(objectKey or "");
	local encoded :table = {};
	for index = 1, #text do
		encoded[index] = string.format("%02X", string.byte(text, index));
	end
	return table.concat(encoded);
end

local function GetDigestionTotal(player)
	return (player:GetProperty(LOTM_RP_PROPERTIES.DigestA) or 0)
		+ (player:GetProperty(LOTM_RP_PROPERTIES.DigestB) or 0);
end

local function GetProjectUnlock(player, sequence :number)
	local path = player:GetProperty(LOTM_RP_PROPERTIES.Path);
	if path == LOTM_TP_SELECTED_PATH then
		local modifiers = {
			[9] = "LOTM_TP_MOD_ALLOW_SWINDLER_PROJECT",
			[8] = "LOTM_TP_MOD_ALLOW_CRYPTOLOGIST_PROJECT",
			[7] = "LOTM_TP_MOD_ALLOW_PROMETHEUS_PROJECT",
			[6] = "LOTM_TP_MOD_ALLOW_DREAM_STEALER_PROJECT",
			[5] = "LOTM_TP_MOD_ALLOW_PARASITE_PROJECT",
			[4] = "LOTM_TP_MOD_ALLOW_MENTOR_OF_DECEIT_PROJECT",
			[3] = "LOTM_TP_MOD_ALLOW_FATE_TROJAN_PROJECT",
			[2] = "LOTM_TP_MOD_ALLOW_WORM_OF_TIME_PROJECT",
			[1] = "LOTM_TP_MOD_ALLOW_ERROR_PROJECT",
		};
		local modifierID = modifiers[sequence];
		if modifierID ~= nil then
			return modifierID, "LOTM_TP_PROJECT_S" .. tostring(sequence) .. "_UNLOCKED";
		end
		return nil, nil;
	elseif path == LOTM_BE_SELECTED_PATH then
		if sequence == 9 then
			return "LOTM_BE_MOD_ALLOW_BARBARIAN_PROJECT",
				"LOTM_BE_PROJECT_BARBARIAN_UNLOCKED";
		elseif sequence == 8 then
			return "LOTM_BE_MOD_ALLOW_BRIBER_PROJECT",
				"LOTM_BE_PROJECT_BRIBER_UNLOCKED";
		elseif sequence == 7 then
			return "LOTM_BE_MOD_ALLOW_BARON_OF_CORRUPTION_PROJECT",
				"LOTM_BE_PROJECT_BARON_OF_CORRUPTION_UNLOCKED";
		elseif sequence == 6 then
			return "LOTM_BE_MOD_ALLOW_CHAOS_MENTOR_PROJECT",
				"LOTM_BE_PROJECT_CHAOS_MENTOR_UNLOCKED";
		elseif sequence == 5 then
			return "LOTM_BE_MOD_ALLOW_COUNT_OF_CORRUPTION_PROJECT",
				"LOTM_BE_PROJECT_COUNT_OF_CORRUPTION_UNLOCKED";
		elseif sequence == 4 then
			return "LOTM_BE_MOD_ALLOW_FRENZY_MAGE_PROJECT",
				"LOTM_BE_PROJECT_FRENZY_MAGE_UNLOCKED";
		elseif sequence == 3 then
			return "LOTM_BE_MOD_ALLOW_DUKE_OF_ENTROPY_PROJECT",
				"LOTM_BE_PROJECT_DUKE_OF_ENTROPY_UNLOCKED";
		elseif sequence == 2 then
			return "LOTM_BE_MOD_ALLOW_PRINCE_OF_ABOLITION_PROJECT",
				"LOTM_BE_PROJECT_PRINCE_OF_ABOLITION_UNLOCKED";
		elseif sequence == 1 then
			if (player:GetProperty(LOTM_RP_PROPERTIES.TrueGodChurch) or 0) == 1 then
				return "LOTM_BE_MOD_ALLOW_ENTHRONEMENT_PROJECT",
					"LOTM_BE_PROJECT_ENTHRONEMENT_UNLOCKED";
			end
			return "LOTM_BE_MOD_ALLOW_UNCONSECRATED_ENTHRONEMENT_PROJECT",
				"LOTM_BE_PROJECT_UNCONSECRATED_ENTHRONEMENT_UNLOCKED";
		end
		return nil, nil;
	elseif path == LOTM_PP_SELECTED_PATH then
		if sequence == 9 then
			return "LOTM_PP_MOD_ALLOW_ARCHAEOLOGIST_PROJECT",
				"LOTM_PP_PROJECT_ARCHAEOLOGIST_UNLOCKED";
		elseif sequence == 8 then
			return "LOTM_PP_MOD_ALLOW_APPRAISER_PROJECT",
				"LOTM_PP_PROJECT_APPRAISER_UNLOCKED";
		elseif sequence == 7 then
			return "LOTM_PP_MOD_ALLOW_MECHANICAL_EXPERT_PROJECT",
				"LOTM_PP_PROJECT_MECHANICAL_EXPERT_UNLOCKED";
		elseif sequence == 6 then
			return "LOTM_PP_MOD_ALLOW_ASTRONOMER_PROJECT",
				"LOTM_PP_PROJECT_ASTRONOMER_UNLOCKED";
		elseif sequence == 5 then
			return "LOTM_PP_MOD_ALLOW_ALCHEMIST_PROJECT",
				"LOTM_PP_PROJECT_ALCHEMIST_UNLOCKED";
		elseif sequence == 4 then
			return "LOTM_PP_MOD_ALLOW_MYSTERY_SCHOLAR_PROJECT",
				"LOTM_PP_PROJECT_MYSTERY_SCHOLAR_UNLOCKED";
		elseif sequence == 3 then
			return "LOTM_PP_MOD_ALLOW_KNOWLEDGE_MENTOR_PROJECT",
				"LOTM_PP_PROJECT_KNOWLEDGE_MENTOR_UNLOCKED";
		elseif sequence == 2 then
			return "LOTM_PP_MOD_ALLOW_ENLIGHTENER_PROJECT",
				"LOTM_PP_PROJECT_ENLIGHTENER_UNLOCKED";
		elseif sequence == 1 then
			if (player:GetProperty(LOTM_RP_PROPERTIES.TrueGodChurch) or 0) == 1 then
				return "LOTM_PP_MOD_ALLOW_CIVILIZATION_ASCENSION",
					"LOTM_PP_PROJECT_CIVILIZATION_ASCENSION_UNLOCKED";
			end
			return "LOTM_PP_MOD_ALLOW_UNCONSECRATED_CIVILIZATION_ASCENSION",
				"LOTM_PP_PROJECT_UNCONSECRATED_CIVILIZATION_ASCENSION_UNLOCKED";
		end
		return nil, nil;
	elseif path ~= LOTM_RP_SELECTED_PATH then
		return nil, nil;
	end
	if sequence == 9 then
		return LOTM_RP_PROVOKER_PROJECT_MODIFIER,
			LOTM_RP_PROPERTIES.ProvokerProjectUnlocked;
	elseif sequence == 8 then
		return LOTM_RP_PYROMANIAC_PROJECT_MODIFIER,
			LOTM_RP_PROPERTIES.PyromaniacProjectUnlocked;
	elseif sequence == 7 then
		return LOTM_RP_CONSPIRATOR_PROJECT_MODIFIER,
			LOTM_RP_PROPERTIES.ConspiratorProjectUnlocked;
	elseif sequence == 6 then
		return LOTM_RP_REAPER_PROJECT_MODIFIER,
			LOTM_RP_PROPERTIES.ReaperProjectUnlocked;
	elseif sequence == 5 then
		return LOTM_RP_IRONBLOOD_PROJECT_MODIFIER,
			LOTM_RP_PROPERTIES.IronbloodProjectUnlocked;
	elseif sequence == 4 then
		return LOTM_RP_WAR_BISHOP_PROJECT_MODIFIER,
			LOTM_RP_PROPERTIES.WarBishopProjectUnlocked;
	elseif sequence == 3 then
		return LOTM_RP_WEATHER_WARLOCK_PROJECT_MODIFIER,
			LOTM_RP_PROPERTIES.WeatherWarlockProjectUnlocked;
	elseif sequence == 2 then
		return LOTM_RP_CONQUEROR_PROJECT_MODIFIER,
			LOTM_RP_PROPERTIES.ConquerorProjectUnlocked;
	elseif sequence == 1 then
		if (player:GetProperty(LOTM_RP_PROPERTIES.TrueGodChurch) or 0) == 1 then
			return LOTM_RP_WAR_FESTIVAL_PROJECT_MODIFIER,
				LOTM_RP_PROPERTIES.WarFestivalProjectUnlocked;
		end
		return LOTM_RP_UNCONSECRATED_WAR_FESTIVAL_PROJECT_MODIFIER,
			LOTM_RP_PROPERTIES.UnconsecratedWarFestivalProjectUnlocked;
	end
	return nil, nil;
end

-- The immutable database manifest is read once per context. Qualification
-- resources are authoritative, save-persistent native project prerequisites;
-- they also close old saves whose permanent AllowProject was attached early.
local PROJECT_GATE_VERSION = 1;
local PROJECT_GATE_VERSION_KEY = "LOTM_PATH_PROJECT_GATE_VERSION";
local PROJECT_GATE_ACTIVE_KEY = "LOTM_PATH_PROJECT_GATE_ACTIVE";
local projectRules = nil;
local projectRulesByType = nil;
local projectRulesByStage = nil;

local function LoadProjectRules()
	if projectRules ~= nil then return true; end
	if GameInfo.LOTM_PathProjectRules == nil then return false; end
	local rows = {};
	for row in GameInfo.LOTM_PathProjectRules() do rows[#rows + 1] = row; end
	if #rows == 0 then return false; end
	table.sort(rows, function(a,b) return a.ProjectType < b.ProjectType; end);
	projectRules = rows;
	projectRulesByType = {};
	projectRulesByStage = {};
	for _,row in ipairs(rows) do
		projectRulesByType[row.ProjectType] = row;
		local key = row.PathType .. ":" .. tostring(row.FromSequence);
		projectRulesByStage[key] = projectRulesByStage[key] or {};
		projectRulesByStage[key][#projectRulesByStage[key] + 1] = row;
	end
	return true;
end

local function CurrentProjectRule(player)
	if not LoadProjectRules() then return nil; end
	local path = player:GetProperty(LOTM_RP_PROPERTIES.Path) or "NONE";
	local sequence = player:GetProperty(LOTM_RP_PROPERTIES.Sequence) or 9;
	local church = tonumber(player:GetProperty(LOTM_RP_PROPERTIES.TrueGodChurch) or 0) == 1 and 1 or 0;
	for _,row in ipairs(projectRulesByStage[path .. ":" .. tostring(sequence)] or {}) do
		if row.ChurchRequired == -1 or row.ChurchRequired == church then return row; end
	end
	return nil;
end

local function HasProjectPrerequisites(player, rule)
	local project = rule ~= nil and GameInfo.Projects[rule.ProjectType] or nil;
	if project == nil then return false; end
	-- Read the effective database. Rescue mode deliberately clears the normal
	-- industrialization prerequisite; no duplicated hardcoded tech rule.
	if project.PrereqTech ~= nil and project.PrereqTech ~= "" then
		local tech = GameInfo.Technologies[project.PrereqTech];
		local techs = player:GetTechs();
		if tech == nil or techs == nil or not techs:HasTech(tech.Index) then return false; end
	end
	return true;
end

local function SetProjectGate(player, rule, enabled)
	local resource = GameInfo.Resources[rule.GateResourceType];
	local resources = player:GetResources();
	if resource == nil or resources == nil or resources.ChangeResourceAmount == nil then return false; end
	local amount = resources:GetResourceAmount(resource.Index);
	local current = tonumber(amount or 0) or 0;
	local wanted = enabled and 1 or 0;
	if current ~= wanted then resources:ChangeResourceAmount(resource.Index, wanted-current); end
	local after = resources:GetResourceAmount(resource.Index);
	return (tonumber(after or 0) or 0) == wanted;
end

local function SyncProjectQualification(player, eligibleRule)
	if not LoadProjectRules() then return false; end
	local active = player:GetProperty(PROJECT_GATE_ACTIVE_KEY) or "";
	local wanted = eligibleRule ~= nil and eligibleRule.ProjectType or "";
	if (tonumber(player:GetProperty(PROJECT_GATE_VERSION_KEY) or 0) or 0) < PROJECT_GATE_VERSION then
		-- One new-feature/old-save migration; later events touch only the old
		-- and current project token. Never scan cities, players or modifiers.
		for _,row in ipairs(projectRules) do
			if not SetProjectGate(player,row,row.ProjectType == wanted) then return false; end
		end
		player:SetProperty(PROJECT_GATE_VERSION_KEY,PROJECT_GATE_VERSION);
	else
		if active ~= wanted and projectRulesByType[active] ~= nil then
			if not SetProjectGate(player,projectRulesByType[active],false) then return false; end
		end
		if eligibleRule ~= nil and not SetProjectGate(player,eligibleRule,true) then return false; end
	end
	if active ~= wanted then player:SetProperty(PROJECT_GATE_ACTIVE_KEY,wanted); end
	return true;
end

local function RefreshProjectUnlock(playerID :number)
	local player = LOTM_RP_State.EnsurePlayerState(playerID);
	if player == nil or not LOTM_RP_State.IsAnyPathPlayer(playerID) then return false; end
	-- A purchased potion is held until real digestion reaches six. Consume it
	-- before publishing any production qualification for the old sequence.
	if LOTM_RP_State.TryConsumePurchasedPotion ~= nil
		and LOTM_RP_State.TryConsumePurchasedPotion(playerID) then return true; end
	local modifierID, flagKey = GetProjectUnlock(player,player:GetProperty(LOTM_RP_PROPERTIES.Sequence) or 9);
	local rule = CurrentProjectRule(player);
	local digestionTotal = GetDigestionTotal(player);
	local eligible = rule ~= nil and rule.ModifierId == modifierID and rule.UnlockFlag == flagKey
		and digestionTotal >= LOTM_RP_DIGESTION_TARGET and HasProjectPrerequisites(player,rule);
	if not SyncProjectQualification(player,eligible and rule or nil) then return false; end
	local repairVersion = tonumber(player:GetProperty(LOTM_RP_PROPERTIES.ProjectUnlockRepairVersion) or 0) or 0;
	if not eligible then
		if flagKey ~= nil and (tonumber(player:GetProperty(flagKey) or 0) or 0) ~= 0 then
			player:SetProperty(flagKey,0);
		end
		if repairVersion < LOTM_RP_PROJECT_UNLOCK_REPAIR_VERSION then
			player:SetProperty(LOTM_RP_PROPERTIES.ProjectUnlockRepairVersion,LOTM_RP_PROJECT_UNLOCK_REPAIR_VERSION);
		end
		return false;
	end
	if repairVersion < LOTM_RP_PROJECT_UNLOCK_REPAIR_VERSION then
		if player.AttachModifierByID == nil or GameInfo.Modifiers[modifierID] == nil then return false; end
		local ok,details = pcall(function() player:AttachModifierByID(modifierID); end);
		if not ok then Log("project repair pending player="..tostring(playerID).." reason="..tostring(details)); return false; end
		player:SetProperty(flagKey,1);
		player:SetProperty(LOTM_RP_PROPERTIES.ProjectUnlockRepairVersion,LOTM_RP_PROJECT_UNLOCK_REPAIR_VERSION);
		Log("qualified project repair player="..tostring(playerID).." project="..rule.ProjectType);
		return true;
	end
	return LOTM_RP_State.AttachModifierOnce(playerID,modifierID,flagKey);
end

function LOTM_RP_State.TryAddDigestion(playerID :number, category :string, objectKey :string, amount :number)
	if not LOTM_RP_State.IsAnyPathPlayer(playerID)
		or (category ~= "A" and category ~= "B")
		or objectKey == nil or tostring(objectKey) == "" then
		return false;
	end

	local player = LOTM_RP_State.EnsurePlayerState(playerID);
	local requestedAmount = math.max(1, math.floor(tonumber(amount or 1) or 1));
	if IsRescueMode() and LOTM_RP_State.IsEnabledPlayer(playerID)
		and string.sub(tostring(objectKey), 1, 10) ~= "RESCUE_P9:" then
		-- Rescue Red Priest digestion is an explicit Phase 9 allow-list. This
		-- central guard prevents older denounce/war/city/church hooks from
		-- leaking points while leaving ordinary mode and the other paths intact.
		return false;
	end
	local sequence = player:GetProperty(LOTM_RP_PROPERTIES.Sequence) or 9;
	if sequence < 1 or sequence > 9 then
		return false;
	end
	local currentTotal = GetDigestionTotal(player);
	if currentTotal >= LOTM_RP_DIGESTION_TARGET then
		RefreshProjectUnlock(playerID);
		return false;
	end

	local currentTurn = Game.GetCurrentGameTurn();
	local digestTurn = player:GetProperty(LOTM_RP_PROPERTIES.DigestTurn) or -1;
	local turnGain = player:GetProperty(LOTM_RP_PROPERTIES.DigestTurnGain) or 0;
	if digestTurn ~= currentTurn then
		digestTurn = currentTurn;
		turnGain = 0;
	end
	local ignoresTurnCap = LOTM_RP_State.IsBlackEmperorPlayer(playerID)
		and sequence == 9;
	-- Explicit multi-point bursts (currently Sequence 4 Parasite's +3 capture)
	-- are one idempotent event and intentionally bypass the normal +2/turn cap.
	if requestedAmount == 1 and not ignoresTurnCap and turnGain >= LOTM_RP_DIGESTION_TURN_CAP then
		return false;
	end

	local dedupKey = "LOTM_RP_DIGEST_SEEN_S" .. tostring(sequence)
		.. "_" .. category .. "_" .. EncodeStableObjectKey(objectKey);
	if player:GetProperty(dedupKey) == 1 then
		return false;
	end

	local counterKey = category == "A"
		and LOTM_RP_PROPERTIES.DigestA
		or LOTM_RP_PROPERTIES.DigestB;
	player:SetProperty(dedupKey, 1);
	local appliedAmount = math.min(requestedAmount, LOTM_RP_DIGESTION_TARGET - currentTotal);
	player:SetProperty(counterKey, (player:GetProperty(counterKey) or 0) + appliedAmount);
	player:SetProperty(LOTM_RP_PROPERTIES.DigestTurn, digestTurn);
	player:SetProperty(LOTM_RP_PROPERTIES.DigestTurnGain, turnGain + appliedAmount);

	Log("player=" .. tostring(playerID)
		.. " sequence=" .. tostring(sequence)
		.. " digestion category=" .. category
		.. " object=" .. tostring(objectKey)
		.. " amount=" .. tostring(appliedAmount)
		.. " total=" .. tostring(GetDigestionTotal(player)));
	RefreshProjectUnlock(playerID);
	return true;
end

function LOTM_RP_State.GetPublicState(playerID :number)
	local player = LOTM_RP_State.EnsurePlayerState(playerID);
	if player == nil then
		return nil;
	end
	return {
		version = player:GetProperty(LOTM_RP_PROPERTIES.StateVersion),
		path = player:GetProperty(LOTM_RP_PROPERTIES.Path),
		sequence = player:GetProperty(LOTM_RP_PROPERTIES.Sequence),
		digestA = player:GetProperty(LOTM_RP_PROPERTIES.DigestA),
		digestB = player:GetProperty(LOTM_RP_PROPERTIES.DigestB),
		digestTurn = player:GetProperty(LOTM_RP_PROPERTIES.DigestTurn),
		digestTurnGain = player:GetProperty(LOTM_RP_PROPERTIES.DigestTurnGain),
		unitID = player:GetProperty(LOTM_RP_PROPERTIES.UnitID),
		respawnAt = player:GetProperty(LOTM_RP_PROPERTIES.RespawnAt),
		arsonReadyAt = player:GetProperty(LOTM_RP_PROPERTIES.ArsonReadyAt),
		planTargetID = player:GetProperty(LOTM_RP_PROPERTIES.PlanTargetID),
		planTargetReadyAt = player:GetProperty(LOTM_RP_PROPERTIES.PlanTargetReadyAt),
	};
end

local function CollectHeroUnits(playerID :number)
	local heroes :table = {};
	local player = GetPlayer(playerID);
	if player == nil then
		return heroes;
	end
	for _, unit in player:GetUnits():Members() do
		if IsHeroUnit(unit) then
			table.insert(heroes, unit);
		end
	end
	table.sort(heroes, function(left, right)
		return left:GetID() < right:GetID();
	end);
	return heroes;
end

function LOTM_RP_State.FindHero(playerID :number)
	local player = GetPlayer(playerID);
	if player == nil then
		return nil;
	end

	local registeredID = player:GetProperty(LOTM_RP_PROPERTIES.UnitID);
	if registeredID ~= nil and registeredID >= 0 then
		local registeredUnit = player:GetUnits():FindID(registeredID);
		if IsHeroUnit(registeredUnit) then
			return registeredUnit;
		end
	end

	local heroes = CollectHeroUnits(playerID);
	return heroes[1];
end

local function SerializePromotions(unit)
	local promotions :table = {};
	local experience = unit:GetExperience();
	if experience == nil then
		return "";
	end
	for promotion in GameInfo.UnitPromotions() do
		if promotion.PromotionClass == LOTM_PATH_HOLDER_PROMOTION_CLASS
			and experience:HasPromotion(promotion.Index) then
			table.insert(promotions, promotion.UnitPromotionType);
		end
	end
	table.sort(promotions);
	return table.concat(promotions, ",");
end

function LOTM_RP_State.SnapshotHero(playerID :number, unit)
	local player = LOTM_RP_State.EnsurePlayerState(playerID);
	if player == nil or unit == nil or unit:GetOwner() ~= playerID
		or not IsHeroUnit(unit) then
		return false;
	end

	local experience = unit:GetExperience();
	if experience ~= nil then
		player:SetProperty(
			LOTM_RP_PROPERTIES.SavedXP,
			experience:GetExperiencePoints() or 0
		);
		player:SetProperty(LOTM_RP_PROPERTIES.SavedPromotions, SerializePromotions(unit));
		player:SetProperty(LOTM_RP_PROPERTIES.SavedName, experience:GetVeteranName() or "");
	end
	return true;
end

function LOTM_RP_State.ScheduleRespawn(playerID :number)
	local player = LOTM_RP_State.EnsurePlayerState(playerID);
	if player == nil then
		return false;
	end
	if (player:GetProperty(LOTM_RP_PROPERTIES.RespawnAt) or -1) < 0 then
		local respawnTurn = Game.GetCurrentGameTurn() + LOTM_RP_RESPAWN_DELAY;
		player:SetProperty(LOTM_RP_PROPERTIES.RespawnAt, respawnTurn);
		Log("player=" .. tostring(playerID) .. " respawn scheduled for turn=" .. tostring(respawnTurn));
	end
	player:SetProperty(LOTM_RP_PROPERTIES.UnitID, -1);
	return true;
end

function LOTM_RP_State.AttachModifierOnce(playerID :number, modifierID :string, flagKey :string)
	local player = LOTM_RP_State.EnsurePlayerState(playerID);
	if player == nil or modifierID == nil or flagKey == nil then
		return false;
	end
	if (player:GetProperty(flagKey) or 0) == 1 then
		return false;
	end
	player:AttachModifierByID(modifierID);
	player:SetProperty(flagKey, 1);
	Log("player=" .. tostring(playerID) .. " attached modifier=" .. modifierID);
	return true;
end

function LOTM_RP_State.RefreshSequenceState(playerID :number)
	local player = LOTM_RP_State.EnsurePlayerState(playerID);
	if player == nil then
		return false;
	end
	if LOTM_RP_State.IsPerfectPlayer(playerID) then
		if LOTM_PP_RefreshSequenceState ~= nil then
			LOTM_PP_RefreshSequenceState(playerID);
		end
		RefreshProjectUnlock(playerID);
		return true;
	elseif LOTM_RP_State.IsBlackEmperorPlayer(playerID) then
		if LOTM_BE_RefreshSequenceState ~= nil then
			LOTM_BE_RefreshSequenceState(playerID);
		end
		RefreshProjectUnlock(playerID);
		return true;
	elseif LOTM_RP_State.IsThiefPlayer(playerID) then
		if LOTM_TP_RefreshSequenceState ~= nil then
			LOTM_TP_RefreshSequenceState(playerID);
		end
		RefreshProjectUnlock(playerID);
		return true;
	elseif LOTM_RP_State.IsRescueThiefPlayer(playerID) then
		if LOTM_RESCUE_Thief ~= nil and LOTM_RESCUE_Thief.RefreshSequenceState ~= nil then
			LOTM_RESCUE_Thief.RefreshSequenceState(playerID);
		end
		RefreshProjectUnlock(playerID);
		return true;
	elseif not LOTM_RP_State.IsEnabledPlayer(playerID) then
		return false;
	end
	local sequence = player:GetProperty(LOTM_RP_PROPERTIES.Sequence) or 9;
	if sequence <= 9 then
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			LOTM_RP_HUNTER_MODIFIER,
			LOTM_RP_PROPERTIES.HunterAttached
		);
	end
	if sequence <= 8 then
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			LOTM_RP_PROVOKER_MODIFIER,
			LOTM_RP_PROPERTIES.ProvokerAttached
		);
	end
	if sequence <= 4 then
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			LOTM_RP_IRONBLOOD_MODIFIER,
			LOTM_RP_PROPERTIES.IronbloodFriendlyStrengthV2Attached
		);
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			LOTM_RP_IRONBLOOD_MOVEMENT_MODIFIER,
			LOTM_RP_PROPERTIES.IronbloodFriendlyMovementV2Attached
		);
	end
	if sequence <= 3 and not IsRescueMode() then
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			LOTM_RP_WAR_BISHOP_PRODUCTION_MODIFIER,
			LOTM_RP_PROPERTIES.WarBishopProductionAttached
		);
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			LOTM_RP_WAR_BISHOP_WEARINESS_MODIFIER,
			LOTM_RP_PROPERTIES.WarBishopWearinessAttached
		);
	end
	if sequence <= 2 and not IsRescueMode() then
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			LOTM_RP_WEATHER_ENEMY_STRENGTH_MODIFIER,
			LOTM_RP_PROPERTIES.WeatherEnemyStrengthV2Attached
		);
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			LOTM_RP_WEATHER_ENEMY_MOVEMENT_MODIFIER,
			LOTM_RP_PROPERTIES.WeatherEnemyMovementV2Attached
		);
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			LOTM_RP_WEATHER_ENEMY_WEARINESS_MODIFIER,
			LOTM_RP_PROPERTIES.WeatherEnemyWearinessV2Attached
		);
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			LOTM_RP_WEATHER_FRIENDLY_MOVEMENT_MODIFIER,
			LOTM_RP_PROPERTIES.WeatherFriendlyMovementV2Attached
		);
	end
	if sequence <= 1 and not IsRescueMode() then
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			LOTM_RP_CONQUEST_BYPASS_WALLS_MODIFIER,
			LOTM_RP_PROPERTIES.ConquestBypassWallsAttached
		);
	end
	if sequence <= 0 then
		if not IsRescueMode() then
			LOTM_RP_State.AttachModifierOnce(
				playerID,
				LOTM_RP_RED_PRIEST_WAR_PRODUCTION_MODIFIER,
				LOTM_RP_PROPERTIES.RedPriestWarProductionAttached
			);
		end
	end
	RefreshProjectUnlock(playerID);
	return true;
end

local function CompleteSequenceAdvance(playerID :number, player, expectedSequence :number, nextSequence :number, source :string)
	player:SetProperty(LOTM_RP_PROPERTIES.Sequence, nextSequence);
	player:SetProperty(LOTM_RP_PROPERTIES.DigestA, 0);
	player:SetProperty(LOTM_RP_PROPERTIES.DigestB, 0);
	player:SetProperty(LOTM_RP_PROPERTIES.DigestTurn, -1);
	player:SetProperty(LOTM_RP_PROPERTIES.DigestTurnGain, 0);
	if nextSequence == 0 and LOTM_RP_State.IsAnyPathPlayer(playerID) then
		local ceremonySerial =
			(player:GetProperty(LOTM_RP_PROPERTIES.SequenceZeroCeremonySerial) or 0) + 1;
		player:SetProperty(
			LOTM_RP_PROPERTIES.SequenceZeroCeremonySerial,
			ceremonySerial
		);
		player:SetProperty(
			LOTM_RP_PROPERTIES.SequenceZeroCeremonyReadyTurn,
				Game.GetCurrentGameTurn()
		);
		Log("player=" .. tostring(playerID)
			.. " scheduled sequence-0 ceremony serial=" .. tostring(ceremonySerial)
			.. " readyTurn="
			.. tostring(player:GetProperty(LOTM_RP_PROPERTIES.SequenceZeroCeremonyReadyTurn)));
	end
	LOTM_RP_State.RefreshSequenceState(playerID);
	Log("player=" .. tostring(playerID)
		.. " advanced sequence " .. tostring(expectedSequence)
		.. "->" .. tostring(nextSequence)
		.. " source=" .. tostring(source));
	if nextSequence == 0 and LOTM_RESCUE_Phase10 ~= nil
		and LOTM_RESCUE_Phase10.OnSequenceZeroAdvanced ~= nil then
		LOTM_RESCUE_Phase10.OnSequenceZeroAdvanced(playerID);
	end
	return true;
end

function LOTM_RP_State.TryConsumePurchasedPotion(playerID :number)
	if not LOTM_RP_State.IsAnyPathPlayer(playerID) then return false; end
	local player=LOTM_RP_State.EnsurePlayerState(playerID);
	-- Civ VI may expose an absent Property as zero Lua return values. Passing
	-- GetProperty() directly as tonumber's sole argument then calls tonumber
	-- with no arguments and aborts the entire refresh before project unlock.
	local purchasedSequenceValue=player:GetProperty("LOTM_WORLD_PURCHASED_POTION_SEQUENCE");
	local purchasedSequence=purchasedSequenceValue~=nil
		and tonumber(purchasedSequenceValue) or nil;
	if purchasedSequence==nil then return false; end
	local sequence=player:GetProperty(LOTM_RP_PROPERTIES.Sequence) or 9;
	if sequence~=purchasedSequence or sequence<2 or sequence>9 then return false; end
	local digestionTotal=GetDigestionTotal(player);
	if digestionTotal<LOTM_RP_DIGESTION_TARGET then
		Log("purchased potion pending digestion player="..tostring(playerID)
			.." sequence="..tostring(sequence).." digestion="..tostring(digestionTotal));
		return false;
	end
	local projectType=player:GetProperty("LOTM_WORLD_PURCHASED_POTION_PROJECT");
	local rule=CurrentProjectRule(player);
	if rule==nil or rule.ProjectType~=projectType or not HasProjectPrerequisites(player,rule) then return false; end
	local purchaseSerialValue=player:GetProperty("LOTM_WORLD_PURCHASED_POTION_SERIAL");
	local purchaseSerial=purchaseSerialValue~=nil and tonumber(purchaseSerialValue) or 0;
	-- Clear the entitlement first so RefreshSequenceState cannot consume it
	-- again while CompleteSequenceAdvance refreshes inherited abilities.
	player:SetProperty("LOTM_WORLD_PURCHASED_POTION_SEQUENCE",nil);
	player:SetProperty("LOTM_WORLD_PURCHASED_POTION_PROJECT",nil);
	player:SetProperty("LOTM_WORLD_PURCHASED_POTION_SERIAL",nil);
	player:SetProperty("LOTM_WORLD_GOODY_POTION_CLEAR_PROJECT",projectType);
	player:SetProperty("LOTM_WORLD_GOODY_POTION_CLEAR_SERIAL",purchaseSerial);
	Log("player="..tostring(playerID).." consumed purchased potion after digestion sequence="
		..tostring(sequence).."->"..tostring(sequence-1).." project="..tostring(projectType)
		.." digestion="..tostring(digestionTotal));
	return CompleteSequenceAdvance(playerID,player,sequence,sequence-1,"GATHERING_PURCHASE_AFTER_DIGESTION");
end

function LOTM_RP_State.AdvanceSequence(
	playerID :number,
	expectedSequence :number,
	nextSequence :number,
	allowWithoutChurch :boolean
)
	if not LOTM_RP_State.IsAnyPathPlayer(playerID) then return false; end
	local player = LOTM_RP_State.EnsurePlayerState(playerID);
	local sequence = player:GetProperty(LOTM_RP_PROPERTIES.Sequence) or 9;
	if sequence ~= expectedSequence
		or nextSequence ~= expectedSequence - 1
		or GetDigestionTotal(player) < LOTM_RP_DIGESTION_TARGET then return false; end
	local rule = CurrentProjectRule(player);
	if rule == nil or rule.FromSequence ~= expectedSequence or rule.ToSequence ~= nextSequence
		or not HasProjectPrerequisites(player,rule) then return false; end
	if expectedSequence == 1 and nextSequence == 0
		and (player:GetProperty(LOTM_RP_PROPERTIES.TrueGodChurch) or 0) ~= 1
		and allowWithoutChurch ~= true then
		Log("ERROR rejected sequence 1->0 without True God Church player="..tostring(playerID));
		return false;
	end
	return CompleteSequenceAdvance(playerID,player,expectedSequence,nextSequence,"PROJECT");
end

function LOTM_RP_State.RegisterPurchasedPotion(playerID :number, expectedSequence :number, projectType :string, serial :number)
	if not LOTM_RP_State.IsAnyPathPlayer(playerID) then return false; end
	local player=LOTM_RP_State.EnsurePlayerState(playerID);
	local sequence=player:GetProperty(LOTM_RP_PROPERTIES.Sequence) or 9;
	-- Purchase may precede completed digestion, but only one exact current-
	-- sequence entitlement can exist. Sequence 1->0 is never purchasable.
	if sequence~=expectedSequence or expectedSequence<2 or expectedSequence>9
		or projectType==nil or tostring(projectType)==""
		or tonumber(serial)==nil
		or player:GetProperty("LOTM_WORLD_PURCHASED_POTION_SEQUENCE")~=nil then return false; end
	local rule=CurrentProjectRule(player);
	if rule==nil or rule.ProjectType~=projectType or rule.FromSequence~=expectedSequence then return false; end
	player:SetProperty("LOTM_WORLD_PURCHASED_POTION_SEQUENCE",expectedSequence);
	player:SetProperty("LOTM_WORLD_PURCHASED_POTION_PROJECT",projectType);
	player:SetProperty("LOTM_WORLD_PURCHASED_POTION_SERIAL",serial);
	Log("player="..tostring(playerID).." registered purchased potion sequence="
		..tostring(expectedSequence).." project="..tostring(projectType).." serial="..tostring(serial));
	LOTM_RP_State.TryConsumePurchasedPotion(playerID);
	return true;
end

local function RestoreHeroSnapshot(playerID :number, unit)
	local player = GetPlayer(playerID);
	local experience = unit ~= nil and unit:GetExperience() or nil;
	if player == nil or experience == nil then
		return;
	end

	local savedPromotions = player:GetProperty(LOTM_RP_PROPERTIES.SavedPromotions) or "";
	local promotionSet :table = {};
	for promotionType in string.gmatch(savedPromotions, "[^,]+") do
		promotionSet[promotionType] = true;
	end
	for promotion in GameInfo.UnitPromotions() do
		if promotion.PromotionClass == LOTM_PATH_HOLDER_PROMOTION_CLASS
			and promotionSet[promotion.UnitPromotionType]
			and not experience:HasPromotion(promotion.Index) then
			experience:SetPromotion(promotion.Index);
		end
	end

	local currentXP = experience:GetExperiencePoints() or 0;
	local savedXP = player:GetProperty(LOTM_RP_PROPERTIES.SavedXP) or 0;
	if savedXP ~= currentXP then
		experience:ChangeExperience(savedXP - currentXP);
	end

	local savedName = player:GetProperty(LOTM_RP_PROPERTIES.SavedName) or "";
	if savedName ~= "" then
		experience:SetVeteranName(savedName);
	end
end

local function ResolveDuplicateHeroes(playerID :number)
	local player = GetPlayer(playerID);
	if player == nil then
		return nil;
	end
	local heroes = CollectHeroUnits(playerID);
	if #heroes == 0 then
		return nil;
	end

	local registeredID = player:GetProperty(LOTM_RP_PROPERTIES.UnitID) or -1;
	local keeper = nil;
	for _, hero in ipairs(heroes) do
		if hero:GetID() == registeredID then
			keeper = hero;
			break;
		end
	end
	if keeper == nil then
		keeper = heroes[1];
		player:SetProperty(LOTM_RP_PROPERTIES.UnitID, keeper:GetID());
	end

	if #heroes > 1 then
		Log("ERROR player=" .. tostring(playerID)
			.. " has duplicate path holders"
			.. "; keeping registered unit=" .. tostring(keeper:GetID()));
		for _, hero in ipairs(heroes) do
			if hero:GetID() ~= keeper:GetID() then
				UnitManager.Kill(hero, false);
			end
		end
	end
	return keeper;
end

local function GetSpawnCity(playerID :number)
	local player = GetPlayer(playerID);
	if player == nil then
		return nil;
	end
	local cities = player:GetCities();
	local capital = cities:GetCapitalCity();
	if capital ~= nil then
		return capital;
	end
	local fallbackCity = nil;
	for _, city in cities:Members() do
		if fallbackCity == nil or city:GetID() < fallbackCity:GetID() then
			fallbackCity = city;
		end
	end
	return fallbackCity;
end

local function CreateHeroAtCity(playerID :number, city)
	local existingIDs :table = {};
	for _, hero in ipairs(CollectHeroUnits(playerID)) do
		existingIDs[hero:GetID()] = true;
	end

	m_creatingHero[playerID] = true;
	local heroType = GetExpectedHeroType(playerID);
	local created = UnitManager.InitUnit(playerID, heroType, city:GetX(), city:GetY());
	if created == nil then
		UnitManager.InitUnitValidAdjacentHex(
			playerID,
			heroType,
			city:GetX(),
			city:GetY(),
			1
		);
	end
	m_creatingHero[playerID] = nil;

	if created ~= nil and IsHeroUnit(created) then
		return created;
	end
	for _, hero in ipairs(CollectHeroUnits(playerID)) do
		if not existingIDs[hero:GetID()] then
			return hero;
		end
	end
	return nil;
end

local m_retypingHero :table = {};
local m_retypedHeroUnitIDs :table = {};

local function RetypeHeroForPath(playerID :number, hero, forceRecreate :boolean)
	if hero == nil then
		return nil;
	end
	local expectedType = GetExpectedHeroType(playerID);
	local expectedIndex = GetHeroTypeIndex(expectedType);
	if hero:GetType() == expectedIndex and forceRecreate ~= true then
		return hero;
	end

	local player = GetPlayer(playerID);
	if player == nil or expectedIndex < 0 then
		return hero;
	end
	LOTM_RP_State.SnapshotHero(playerID, hero);
	local x, y = hero:GetX(), hero:GetY();
	local oldUnitID = hero:GetID();
	local damage = hero:GetDamage() or 0;
	local moves = hero:GetMovesRemaining() or 0;
	m_retypingHero[playerID] = true;
	m_retypedHeroUnitIDs[playerID] = oldUnitID;
	UnitManager.Kill(hero, false);
	local replacement = UnitManager.InitUnit(playerID, expectedType, x, y);
	if replacement == nil then
		UnitManager.InitUnitValidAdjacentHex(playerID, expectedType, x, y, 1);
		for _, candidate in ipairs(CollectHeroUnits(playerID)) do
			if candidate:GetType() == expectedIndex then
				replacement = candidate;
				break;
			end
		end
	end
	m_retypingHero[playerID] = nil;
	if replacement == nil then
		LOTM_RP_State.ScheduleRespawn(playerID);
		Log("ERROR player=" .. tostring(playerID)
			.. " failed path-holder icon migration to " .. expectedType);
		return nil;
	end
	RestoreHeroSnapshot(playerID, replacement);
	if damage > 0 then
		replacement:ChangeDamage(damage);
	end
	local replacementMoves = replacement:GetMovesRemaining() or 0;
	if replacementMoves ~= moves then
		replacement:ChangeMovesRemaining(moves - replacementMoves);
	end
	player:SetProperty(LOTM_RP_PROPERTIES.UnitID, replacement:GetID());
	Log("player=" .. tostring(playerID)
		.. (forceRecreate == true and " migrated promotion tree; unit type="
			or " migrated path-holder unit type=") .. expectedType
		.. " unit=" .. tostring(replacement:GetID()));
	return replacement;
end

local function AttachTechnologyModifiers(playerID :number)
	local player = GetPlayer(playerID);
	if player == nil then
		return;
	end
	local technologies = player:GetTechs();
	local steps :table = {
		{
			technology = "TECH_IRON_WORKING",
			modifier = "LOTM_RP_MOD_TECH_IRON_WORKING_COMBAT",
			flag = LOTM_RP_PROPERTIES.TechIronWorkingAttached,
		},
		{
			technology = "TECH_APPRENTICESHIP",
			modifier = "LOTM_RP_MOD_TECH_APPRENTICESHIP_COMBAT",
			flag = LOTM_RP_PROPERTIES.TechApprenticeshipAttached,
		},
		{
			technology = "TECH_GUNPOWDER",
			modifier = "LOTM_RP_MOD_TECH_GUNPOWDER_COMBAT",
			flag = LOTM_RP_PROPERTIES.TechGunpowderAttached,
		},
		{
			technology = "TECH_MILITARY_SCIENCE",
			modifier = "LOTM_RP_MOD_TECH_MILITARY_SCIENCE_COMBAT",
			flag = LOTM_RP_PROPERTIES.TechMilitaryScienceAttached,
		},
		{
			technology = "TECH_REPLACEABLE_PARTS",
			modifier = "LOTM_RP_MOD_TECH_REPLACEABLE_PARTS_COMBAT",
			flag = LOTM_RP_PROPERTIES.TechReplaceablePartsAttached,
		},
		{
			technology = "TECH_SATELLITES",
			modifier = "LOTM_RP_MOD_TECH_SATELLITES_COMBAT",
			flag = LOTM_RP_PROPERTIES.TechSatellitesAttached,
		},
	};
	for _, step in ipairs(steps) do
		local technology = GameInfo.Technologies[step.technology];
		if technology ~= nil and technologies:HasTech(technology.Index) then
			LOTM_RP_State.AttachModifierOnce(
				playerID,
				step.modifier,
				step.flag
			);
		end
	end
end

local function OnAcknowledgeSequenceZeroCeremony(playerID :number, parameters :table)
	if not LOTM_RP_State.IsAnyPathPlayer(playerID) then
		return;
	end
	local player = LOTM_RP_State.EnsurePlayerState(playerID);
	local requestedSerial = parameters ~= nil and tonumber(parameters.Serial) or nil;
	local currentSerial =
		player:GetProperty(LOTM_RP_PROPERTIES.SequenceZeroCeremonySerial) or 0;
	local readyTurn =
		player:GetProperty(LOTM_RP_PROPERTIES.SequenceZeroCeremonyReadyTurn) or -1;
	local acknowledgedSerial =
		player:GetProperty(LOTM_RP_PROPERTIES.SequenceZeroCeremonyAckSerial) or 0;
	if requestedSerial == nil
		or requestedSerial ~= math.floor(requestedSerial)
		or requestedSerial ~= currentSerial
		or requestedSerial <= acknowledgedSerial
		or (player:GetProperty(LOTM_RP_PROPERTIES.Sequence) or 9) ~= 0
		or readyTurn < 0
		or Game.GetCurrentGameTurn() < readyTurn then
		Log("ERROR rejected sequence-0 ceremony acknowledgement player="
			.. tostring(playerID) .. " serial=" .. tostring(requestedSerial));
		return;
	end
	player:SetProperty(
		LOTM_RP_PROPERTIES.SequenceZeroCeremonyAckSerial,
		requestedSerial
	);
	Log("player=" .. tostring(playerID)
		.. " acknowledged sequence-0 ceremony serial=" .. tostring(requestedSerial));
end

local function OnMarkOpeningComicShown(playerID :number, parameters :table)
	if not LOTM_RP_State.IsAnyPathPlayer(playerID) then
		Log("ERROR rejected opening-comic acknowledgement player=" .. tostring(playerID));
		return;
	end
	local player = LOTM_RP_State.EnsurePlayerState(playerID);
	if tonumber(player:GetProperty(LOTM_RP_PROPERTIES.OpeningComicShown) or 0) == 1 then
		return;
	end
	player:SetProperty(LOTM_RP_PROPERTIES.OpeningComicShown, 1);
	Log("player=" .. tostring(playerID) .. " acknowledged opening comic");
end

local function RefreshWarAuraSource(playerID :number, hero)
	if not IsHeroUnit(hero) then
		return;
	end
	local promotion = GameInfo.UnitPromotions["PROMOTION_LOTM_RP_COMBAT_3"];
	local experience = hero:GetExperience();
	local abilities = hero:GetAbility();
	if promotion == nil or experience == nil or abilities == nil then
		Log("ERROR war aura source interface missing player=" .. tostring(playerID));
		return;
	end
	local hasPromotion = experience:HasPromotion(promotion.Index);
	local desired = hasPromotion and 1 or 0;
	local abilityType = "ABILITY_LOTM_RP_WAR_AURA_SOURCE_V2";
	LOTM_Effects.SetAbilityCount(abilities, abilityType, desired);
	local actual = abilities:GetAbilityCount(abilityType) or 0;
	local signature = tostring(desired) .. ":" .. tostring(actual);
	if hero:GetProperty("LOTM_RP_WAR_AURA_SOURCE_V2_STATE") ~= signature then
		hero:SetProperty("LOTM_RP_WAR_AURA_SOURCE_V2_STATE", signature);
		Log("war aura source player=" .. tostring(playerID)
			.. " unit=" .. tostring(hero:GetID())
			.. " promotion=" .. tostring(hasPromotion)
			.. " desired=" .. tostring(desired)
			.. " actual=" .. tostring(actual));
	end
end

function LOTM_RP_State.EnsureHero(playerID :number)
	if not LOTM_RP_State.IsAnyPathPlayer(playerID) then
		return nil;
	end

	local player = LOTM_RP_State.EnsurePlayerState(playerID);
	AttachTechnologyModifiers(playerID);
	LOTM_RP_State.RefreshSequenceState(playerID);
	local hero = ResolveDuplicateHeroes(playerID);
	if hero ~= nil then
		local migratePromotionTree =
			(player:GetProperty(LOTM_RP_PROPERTIES.PromotionTreeMigrated) or 0) ~= 1;
		hero = RetypeHeroForPath(playerID, hero, migratePromotionTree);
		if hero == nil then
			return nil;
		end
		if migratePromotionTree then
			player:SetProperty(LOTM_RP_PROPERTIES.PromotionTreeMigrated, 1);
		end
		player:SetProperty(LOTM_RP_PROPERTIES.UnitID, hero:GetID());
		player:SetProperty(LOTM_RP_PROPERTIES.RespawnAt, -1);
		RefreshWarAuraSource(playerID, hero);
		LOTM_RP_State.SnapshotHero(playerID, hero);
		return hero;
	end
	if (player:GetProperty(LOTM_RP_PROPERTIES.PromotionTreeMigrated) or 0) ~= 1 then
		-- A dead/pending holder has no live stale promotion modifiers to remove.
		player:SetProperty(LOTM_RP_PROPERTIES.SavedPromotions, "");
		player:SetProperty(LOTM_RP_PROPERTIES.PromotionTreeMigrated, 1);
		Log("player=" .. tostring(playerID)
			.. " cleared legacy Recon promotions before holder respawn");
	end

	local respawnAt = player:GetProperty(LOTM_RP_PROPERTIES.RespawnAt) or -1;
	local registeredID = player:GetProperty(LOTM_RP_PROPERTIES.UnitID) or -1;
	if registeredID >= 0 and respawnAt < 0 then
		LOTM_RP_State.ScheduleRespawn(playerID);
		respawnAt = player:GetProperty(LOTM_RP_PROPERTIES.RespawnAt) or -1;
	end
	if respawnAt >= 0 and Game.GetCurrentGameTurn() < respawnAt then
		return nil;
	end

	local city = GetSpawnCity(playerID);
	if city == nil then
		return nil;
	end
	local isRespawn = respawnAt >= 0;
	hero = CreateHeroAtCity(playerID, city);
	if hero == nil then
		Log("player=" .. tostring(playerID) .. " has no legal capital or adjacent spawn plot");
		return nil;
	end

	player:SetProperty(LOTM_RP_PROPERTIES.UnitID, hero:GetID());
	player:SetProperty(LOTM_RP_PROPERTIES.RespawnAt, -1);
	if isRespawn then
		RestoreHeroSnapshot(playerID, hero);
	end
	RefreshWarAuraSource(playerID, hero);
	LOTM_RP_State.SnapshotHero(playerID, hero);
	Log("player=" .. tostring(playerID)
		.. (isRespawn and " respawned" or " created")
		.. " hero unit=" .. tostring(hero:GetID()));
	return hero;
end

local function ReconcileTestCombatToggle(playerID :number)
	if LOTM_TEST_COMBAT_RECONCILED[playerID] == true
		or not LOTM_TEST_COMBAT_TOGGLE_ENABLED
		or IsRescueMode()
		or (LOTM_MP_TurnSync ~= nil and LOTM_MP_TurnSync.IsNetworkGame ~= nil
			and LOTM_MP_TurnSync.IsNetworkGame())
		or not LOTM_RP_State.IsAnyPathPlayer(playerID) then
		return;
	end
	local player = GetPlayer(playerID);
	if player == nil then return; end
	local active = (tonumber(player:GetProperty(LOTM_RP_PROPERTIES.TestCombatBoostActive) or 0) or 0) == 1;
	if not active then
		LOTM_TEST_COMBAT_RECONCILED[playerID] = true;
		return;
	end
	if GameInfo.Modifiers[LOTM_TEST_COMBAT_PLUS_MODIFIER] == nil
		or GameInfo.Modifiers[LOTM_TEST_CAPITAL_PRODUCTION_PLUS_MODIFIER] == nil then
		Log("ERROR test combat reconcile modifier missing player=" .. tostring(playerID));
		return;
	end
	local ok, details = pcall(function()
		player:AttachModifierByID(LOTM_TEST_COMBAT_PLUS_MODIFIER);
		player:AttachModifierByID(LOTM_TEST_CAPITAL_PRODUCTION_PLUS_MODIFIER);
	end);
	if ok then
		LOTM_TEST_COMBAT_RECONCILED[playerID] = true;
	end
	local capital = player:GetCities() ~= nil and player:GetCities():GetCapitalCity() or nil;
	local observedProduction = -1;
	if capital ~= nil and YieldTypes ~= nil and YieldTypes.PRODUCTION ~= nil
		and capital.GetYield ~= nil then
		observedProduction = tonumber(capital:GetYield(YieldTypes.PRODUCTION) or -1) or -1;
	end
	Log("test combat reconcile player=" .. tostring(playerID)
		.. " active=true reattached=" .. tostring(ok)
		.. " details=" .. tostring(details or "")
		.. " capital=" .. tostring(capital ~= nil and capital:GetID() or -1)
		.. " observedProduction=" .. tostring(observedProduction));
end

local function ProcessPlayer(playerID :number)
	if LOTM_RP_State.IsAnyPathPlayer(playerID) then
		LOTM_RP_State.EnsureHero(playerID);
		ReconcileTestCombatToggle(playerID);
	end
end

local function ProcessAllPlayers()
	local playerIDs :table = {};
	for _, playerID in ipairs(PlayerManager.GetAliveMajorIDs() or {}) do
		playerIDs[#playerIDs + 1] = playerID;
	end
	table.sort(playerIDs);
	for _, playerID in ipairs(playerIDs) do
		ProcessPlayer(playerID);
	end
end

local function OnSelectPath(playerID :number, parameters :table)
	local player = GetPlayer(playerID);
	local choice = parameters ~= nil and parameters.Choice or nil;
	if player == nil
		or not player:IsAlive()
		or not player:IsMajor()
		or not player:IsHuman()
		or (choice ~= LOTM_RP_SELECTED_PATH
			and choice ~= LOTM_PP_SELECTED_PATH
			and choice ~= LOTM_BE_SELECTED_PATH
			and choice ~= LOTM_TP_SELECTED_PATH
			and choice ~= "NONE") then
		Log("ERROR rejected path-selection command player=" .. tostring(playerID));
		return;
	end

	player = LOTM_RP_State.EnsurePlayerState(playerID);
	if (player:GetProperty(LOTM_RP_PROPERTIES.PathDecided) or 0) == 1 then
		Log("ERROR rejected duplicate path-selection command player=" .. tostring(playerID));
		return;
	end

	player:SetProperty(LOTM_RP_PROPERTIES.Path, choice);
	player:SetProperty(LOTM_RP_PROPERTIES.PathDecided, 1);
	Log("player=" .. tostring(playerID) .. " selected path=" .. tostring(choice));
	-- Rescue Thief must seed its purification-energy baseline before EnsureHero
	-- runs the per-turn rescue effects.  Otherwise the hero refresh grants the
	-- first +1 energy and leaves the historical GLOBAL_PURIFICATION delta to a
	-- later turn, making a newly selected Thief appear to have no loaded energy.
	local rescueThiefSelected = choice == LOTM_TP_SELECTED_PATH
		and IsRescueMode()
		and LOTM_RESCUE_Thief ~= nil
		and LOTM_RESCUE_Thief.OnPathSelected ~= nil;
	if rescueThiefSelected then
		LOTM_RESCUE_Thief.OnPathSelected(playerID);
	end
	if choice == LOTM_RP_SELECTED_PATH
		or choice == LOTM_PP_SELECTED_PATH
		or choice == LOTM_BE_SELECTED_PATH
		or choice == LOTM_TP_SELECTED_PATH then
		local hero = LOTM_RP_State.EnsureHero(playerID);
		if hero == nil then
			Log("player=" .. tostring(playerID)
				.. " hero creation pending capital/city initialization");
		end
		if choice == LOTM_PP_SELECTED_PATH and LOTM_PP_OnPathSelected ~= nil then
			LOTM_PP_OnPathSelected(playerID);
		elseif choice == LOTM_BE_SELECTED_PATH and LOTM_BE_OnPathSelected ~= nil then
			LOTM_BE_OnPathSelected(playerID);
		elseif choice == LOTM_TP_SELECTED_PATH and rescueThiefSelected then
			-- Seeded above, before EnsureHero; do not run the initializer twice.
		elseif choice == LOTM_TP_SELECTED_PATH and LOTM_TP_OnPathSelected ~= nil then
			LOTM_TP_OnPathSelected(playerID);
		end
	end
end

local function OnPlayerTurnActivated(playerID :number, isFirstTimeThisTurn :boolean)
	ProcessPlayer(playerID);
end

local function OnCityBuilt(playerID :number, cityID :number)
	ProcessPlayer(playerID);
end

local function OnResearchCompleted(playerID :number, techIndex :number, isCanceled :boolean)
	-- ResearchCompleted is locally published.  Network turns already call
	-- EnsureHero -> AttachTechnologyModifiers from the synchronized dispatcher,
	-- so the callback must not allocate modifiers in client-specific order.
	if LOTM_MP_TurnSync.IsNetworkGame() then return; end
	if not isCanceled and LOTM_RP_State.IsAnyPathPlayer(playerID) then
		AttachTechnologyModifiers(playerID);
	end
end

local function SnapshotEventUnit(playerID :number, unitID :number)
	local player = GetPlayer(playerID);
	if player == nil then
		return;
	end
	local unit = player:GetUnits():FindID(unitID);
	if IsHeroUnit(unit) then
		RefreshWarAuraSource(playerID, unit);
		LOTM_RP_State.SnapshotHero(playerID, unit);
		if unit:IsDead() or unit:IsDelayedDeath() then
			LOTM_RP_State.ScheduleRespawn(playerID);
		end
	end
end

local function OnCombatOccurred(
	attackerPlayerID :number,
	attackerUnitID :number,
	defenderPlayerID :number,
	defenderUnitID :number
)
	SnapshotEventUnit(attackerPlayerID, attackerUnitID);
	SnapshotEventUnit(defenderPlayerID, defenderUnitID);
end

local function OnPostUnitPromotionEarned(
	playerID :number,
	unitID :number,
	promotionType :number
)
	SnapshotEventUnit(playerID, unitID);
end

local function OnUnitRemovedFromMap(playerID :number, unitID :number)
	if LOTM_MP_TurnSync.IsNetworkGame() then
		-- These flags are Lua-local retype bookkeeping only.  Missing registered
		-- heroes are detected and scheduled by synchronized EnsureHero next turn.
		if m_retypedHeroUnitIDs[playerID] == unitID then m_retypedHeroUnitIDs[playerID] = nil; end
		return;
	end
	if m_retypedHeroUnitIDs[playerID] == unitID then
		m_retypedHeroUnitIDs[playerID] = nil;
		return;
	end
	if m_retypingHero[playerID] then
		return;
	end
	local player = GetPlayer(playerID);
	if player == nil then
		return;
	end
	local registeredID = player:GetProperty(LOTM_RP_PROPERTIES.UnitID) or -1;
	if registeredID == unitID then
		LOTM_RP_State.ScheduleRespawn(playerID);
	end
end

local function OnUnitInitialized(playerID :number, unitID :number)
	if m_creatingHero[playerID] or not LOTM_RP_State.IsAnyPathPlayer(playerID) then
		return;
	end
	local player = GetPlayer(playerID);
	local unit = player ~= nil and player:GetUnits():FindID(unitID) or nil;
	if IsHeroUnit(unit) and not LOTM_MP_TurnSync.IsNetworkGame() then
		ResolveDuplicateHeroes(playerID);
	end
end

-- TEST ONLY: authoritative reversible +200 combat toggle.  UI submits the
-- command; this handler alone mutates synchronized state and modifier stacks.
local function OnTestCombatToggle(playerID :number, parameters :table)
	if not LOTM_TEST_COMBAT_TOGGLE_ENABLED or IsRescueMode()
		or (LOTM_MP_TurnSync ~= nil and LOTM_MP_TurnSync.IsNetworkGame ~= nil
			and LOTM_MP_TurnSync.IsNetworkGame()) then
		Log("test combat toggle rejected mode or disabled player=" .. tostring(playerID));
		return;
	end
	if not LOTM_RP_State.IsAnyPathPlayer(playerID) then
		Log("test combat toggle rejected non-path player=" .. tostring(playerID));
		return;
	end
	local player = GetPlayer(playerID);
	if player == nil or not player:IsTurnActive() then
		Log("test combat toggle rejected inactive player=" .. tostring(playerID));
		return;
	end
	local registeredID = player:GetProperty(LOTM_RP_PROPERTIES.UnitID) or -1;
	local requestedID = parameters ~= nil and tonumber(parameters.UnitID) or registeredID;
	if requestedID ~= registeredID then
		Log("test combat toggle rejected unit mismatch player=" .. tostring(playerID));
		return;
	end
	local hero = LOTM_RP_State.FindHero(playerID);
	if hero == nil or hero:IsDead() or hero:IsDelayedDeath() then
		Log("test combat toggle rejected missing hero player=" .. tostring(playerID));
		return;
	end
	local active = (tonumber(player:GetProperty(LOTM_RP_PROPERTIES.TestCombatBoostActive) or 0) or 0) == 1;
	local modifierID = active and LOTM_TEST_COMBAT_MINUS_MODIFIER or LOTM_TEST_COMBAT_PLUS_MODIFIER;
	local productionModifierID = active
		and LOTM_TEST_CAPITAL_PRODUCTION_MINUS_MODIFIER
		or LOTM_TEST_CAPITAL_PRODUCTION_PLUS_MODIFIER;
	if GameInfo.Modifiers[modifierID] == nil or GameInfo.Modifiers[productionModifierID] == nil then
		Log("ERROR test combat modifier missing combat=" .. modifierID
			.. " production=" .. productionModifierID);
		return;
	end
	player:AttachModifierByID(modifierID);
	player:AttachModifierByID(productionModifierID);
	player:SetProperty(LOTM_RP_PROPERTIES.TestCombatBoostActive, active and 0 or 1);
	local capital = player:GetCities() ~= nil and player:GetCities():GetCapitalCity() or nil;
	local observedProduction = -1;
	if capital ~= nil and YieldTypes ~= nil and YieldTypes.PRODUCTION ~= nil
		and capital.GetYield ~= nil then
		observedProduction = tonumber(capital:GetYield(YieldTypes.PRODUCTION) or -1) or -1;
	end
	Log("test combat toggle player=" .. tostring(playerID)
		.. " unit=" .. tostring(requestedID)
		.. " active=" .. tostring(not active)
		.. " modifier=" .. modifierID
		.. " capitalProductionModifier=" .. productionModifierID
		.. " capital=" .. tostring(capital ~= nil and capital:GetID() or -1)
		.. " observedProduction=" .. tostring(observedProduction));
end

local function Initialize()
	LOTM_MP_TurnSync.Add(OnPlayerTurnActivated,"Lifecycle");
	GameEvents.CityBuilt.Add(OnCityBuilt);
	Events.ResearchCompleted.Add(OnResearchCompleted);
	Events.UnitRemovedFromMap.Add(OnUnitRemovedFromMap);
	GameEvents.OnCombatOccurred.Add(OnCombatOccurred);
	GameEvents.PostUnitPromotionEarned.Add(OnPostUnitPromotionEarned);
	GameEvents.UnitInitialized.Add(OnUnitInitialized);
	GameEvents.LOTM_RP_Command_SelectPath.Add(OnSelectPath);
	GameEvents.LOTM_RP_Command_AcknowledgeSequence0Ceremony.Add(
		OnAcknowledgeSequenceZeroCeremony
	);
	GameEvents.LOTM_RP_Command_MarkOpeningComicShown.Add(OnMarkOpeningComicShown);
	-- TEST ONLY: keep this single registration adjacent to the switch above.
	GameEvents.LOTM_RP_Command_TestCombatToggle.Add(OnTestCombatToggle);
	LOTM_MP_TurnSync.RunStartup(ProcessAllPlayers,"Lifecycle");
	Log("initialized state version=" .. tostring(LOTM_RP_STATE_VERSION));
end

Initialize();
