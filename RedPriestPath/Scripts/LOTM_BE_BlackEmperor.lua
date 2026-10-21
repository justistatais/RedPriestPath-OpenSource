-- Black Emperor Path (Sequences 9-2).
-- All persistent mutations in this module run in synchronized Gameplay.

local LOTM_BE_PATH :string = "PATH_BLACK_EMPEROR";
local LOTM_BE_CODE_OF_LAWS :string = "CIVIC_CODE_OF_LAWS";
local LOTM_BE_CHAOS_I :string = "POLICY_LOTM_BE_CHAOS_I";
local LOTM_BE_CHAOS_II :string = "POLICY_LOTM_BE_CHAOS_II";
local LOTM_BE_CHAOS_III :string = "POLICY_LOTM_BE_CHAOS_III";
local LOTM_BE_CORRUPTION_I :string = "POLICY_LOTM_BE_CORRUPTION_I";
local LOTM_BE_CORRUPTION_II :string = "POLICY_LOTM_BE_CORRUPTION_II";
local LOTM_BE_CORRUPTION_III :string = "POLICY_LOTM_BE_CORRUPTION_III";
local LOTM_BE_FRENZY_I :string = "POLICY_LOTM_BE_FRENZY_I";
local LOTM_BE_FRENZY_II :string = "POLICY_LOTM_BE_FRENZY_II";
local LOTM_BE_TRANSFORMATION_PROJECT :string = "PROJECT_LOTM_BE_TRANSFORMATION";
local LOTM_BE_CITY_OWNER_PROPERTY :string = "LOTM_BE_OBSERVED_CITY_OWNER";
local LOTM_BE_CITY_TRANSFER_AWARD_PROPERTY :string = "LOTM_BE_SEQ2_TRANSFER_AWARD_KEY";
local LOTM_BE_CITY_INDEX_VERSION_PROPERTY :string = "LOTM_BE_CITY_INDEX_VERSION";
local LOTM_BE_CITY_INDEX_VERSION :number = 1;
local ScanCityOwnership;
local InitializeTradeRouteBaseline;
local ProcessNetworkEvents;
local pendingNetworkEvents :table = {};
local pendingNetworkEventKeys :table = {};
local networkTradeObservedCounts :table = {};
local networkCityObservedOwners :table = {};

local function SortedMajorIDs()
	local ids :table = {};
	for _, playerID in ipairs(PlayerManager.GetAliveMajorIDs() or {}) do
		ids[#ids + 1] = tonumber(playerID);
	end
	table.sort(ids);
	return ids;
end

local P :table = {
	FirstCityGranted = "LOTM_BE_FIRST_CITY_REWARD_GRANTED",
	WildcardAttached = "LOTM_BE_WILDCARD_SLOT_ATTACHED",
	MightStrengthAttached = "LOTM_BE_MIGHT_STRENGTH_ATTACHED",
	MightStrengthV2Attached = "LOTM_BE_MIGHT_STRENGTH_V2_ATTACHED",
	LegacyBaseStrengthCorrected = "LOTM_BE_LEGACY_BASE_STRENGTH_CORRECTED",
	CivilianBuildersV2Cleaned = "LOTM_BE_CIVILIAN_BUILDERS_V2_CLEANED",
	MightMovementAttached = "LOTM_BE_MIGHT_MOVEMENT_ATTACHED",
	TradeGoldAttached = "LOTM_BE_TRADE_GOLD_ATTACHED",
	WealthAttached = "LOTM_BE_WEALTH_ATTACHED",
	EnvoyBaseline = "LOTM_BE_ENVOY_BASELINE",
	TradeRouteActiveCount274 = "LOTM_BE_TRADE_ROUTE_ACTIVE_COUNT_274",
	AutomaticCivicTurn = "LOTM_BE_AUTOMATIC_CIVIC_TURN",
	CivicScoringMigrated = "LOTM_BE_CIVIC_SCORING_V2_MIGRATED",
	ChaosIUnlocked = "LOTM_BE_CHAOS_I_UNLOCKED",
	ChaosIIUnlocked = "LOTM_BE_CHAOS_II_UNLOCKED",
	ChaosIIIUnlocked = "LOTM_BE_CHAOS_III_UNLOCKED",
	CorruptionIUnlocked = "LOTM_BE_CORRUPTION_I_UNLOCKED",
	CorruptionIIUnlocked = "LOTM_BE_CORRUPTION_II_UNLOCKED",
	CorruptionIIIUnlocked = "LOTM_BE_CORRUPTION_III_UNLOCKED",
	FrenzyIUnlocked = "LOTM_BE_FRENZY_I_UNLOCKED",
	FrenzyIIUnlocked = "LOTM_BE_FRENZY_II_UNLOCKED",
	TransformationProjectAttached = "LOTM_BE_TRANSFORMATION_PROJECT_ATTACHED",
	CorruptProsperityFoodAttached = "LOTM_BE_CORRUPT_PROSPERITY_FOOD_ATTACHED",
	EntropyPressureAttached = "LOTM_BE_ENTROPY_PRESSURE_ATTACHED",
	EntropyPressureV2Attached = "LOTM_BE_ENTROPY_PRESSURE_V2_ATTACHED",
	EntropyLoyaltyAttached = "LOTM_BE_ENTROPY_LOYALTY_ATTACHED",
};

local LOTM_BE_TOMB_SLOT_MODIFIERS :table = {
	{ "LOTM_BE_MOD_TOMB_MILITARY_SLOT_1", "LOTM_BE_TOMB_MILITARY_SLOT_1_ATTACHED" },
	{ "LOTM_BE_MOD_TOMB_MILITARY_SLOT_2", "LOTM_BE_TOMB_MILITARY_SLOT_2_ATTACHED" },
	{ "LOTM_BE_MOD_TOMB_MILITARY_SLOT_3", "LOTM_BE_TOMB_MILITARY_SLOT_3_ATTACHED" },
	{ "LOTM_BE_MOD_TOMB_ECONOMIC_SLOT_1", "LOTM_BE_TOMB_ECONOMIC_SLOT_1_ATTACHED" },
	{ "LOTM_BE_MOD_TOMB_ECONOMIC_SLOT_2", "LOTM_BE_TOMB_ECONOMIC_SLOT_2_ATTACHED" },
	{ "LOTM_BE_MOD_TOMB_ECONOMIC_SLOT_3", "LOTM_BE_TOMB_ECONOMIC_SLOT_3_ATTACHED" },
	{ "LOTM_BE_MOD_TOMB_WILDCARD_SLOT_1", "LOTM_BE_TOMB_WILDCARD_SLOT_1_ATTACHED" },
	{ "LOTM_BE_MOD_TOMB_WILDCARD_SLOT_2", "LOTM_BE_TOMB_WILDCARD_SLOT_2_ATTACHED" },
	{ "LOTM_BE_MOD_TOMB_WILDCARD_SLOT_3", "LOTM_BE_TOMB_WILDCARD_SLOT_3_ATTACHED" },
};

local function Log(message :string)
	print("[LOTM_BE] " .. message);
end

local function GetPlayer(playerID :number)
	return playerID ~= nil and Players[playerID] or nil;
end

local function IsBlackEmperor(playerID :number)
	return LOTM_RP_State ~= nil
		and LOTM_RP_State.IsBlackEmperorPlayer ~= nil
		and LOTM_RP_State.IsBlackEmperorPlayer(playerID);
end

local function GetSequence(playerID :number)
	return LOTM_RP_State.GetSequence(playerID);
end

local function AddDigestion(playerID :number, category :string, key :string, amount :number)
	local added = 0;
	for index = 1, math.max(0, amount or 1) do
		if LOTM_RP_State.TryAddDigestion(
			playerID,
			category,
			key .. ":POINT:" .. tostring(index)
		) then
			added = added + 1;
		end
	end
	return added;
end

local function HasAnyCity(player)
	if player == nil then
		return false;
	end
	for _, city in player:GetCities():Members() do
		return city ~= nil;
	end
	return false;
end

local function GrantFirstCityReward(playerID :number)
	local player = GetPlayer(playerID);
	if player == nil or not IsBlackEmperor(playerID) or not HasAnyCity(player)
		or (player:GetProperty(P.FirstCityGranted) or 0) == 1 then
		return false;
	end

	LOTM_RP_State.AttachModifierOnce(
		playerID,
		"LOTM_BE_MOD_RULES_WILDCARD_SLOT",
		P.WildcardAttached
	);
	local civic = GameInfo.Civics[LOTM_BE_CODE_OF_LAWS];
	local culture = player:GetCulture();
	if civic ~= nil and culture ~= nil and not culture:HasCivic(civic.Index) then
		-- CivicCompleted may be raised by the normal progress-completion path.
		-- Mark this grant first so
		-- the event handler cannot award the same automatic civic a second time.
		player:SetProperty(P.AutomaticCivicTurn, Game.GetCurrentGameTurn());
		-- Firaxis' Player tuner completes civics by filling their cultural
		-- progress. This also refreshes the current-research state immediately;
		-- SetCivic alone can leave the UI cache stale until the tree is opened.
		culture:SetCulturalProgress(civic.Index, culture:GetCultureCost(civic.Index));
		if not culture:HasCivic(civic.Index) then
			culture:SetCivic(civic.Index, true);
		end
		AddDigestion(
			playerID,
			"A",
			"CIVIC_COMPLETED:" .. tostring(civic.Index),
			3
		);
	end
	player:SetProperty(P.FirstCityGranted, 1);
	Log("player=" .. tostring(playerID) .. " received Code of Laws and wildcard slot");
	return true;
end

local function GetTotalEnvoys(playerID :number)
	local player = GetPlayer(playerID);
	local influence = player ~= nil and player:GetInfluence() or nil;
	if influence == nil then
		return 0;
	end
	local total = influence:GetTokensToGive() or 0;
	for _, minorID in ipairs(PlayerManager.GetAliveMinorIDs()) do
		local minor = GetPlayer(minorID);
		local minorInfluence = minor ~= nil and minor:GetInfluence() or nil;
		if minorInfluence ~= nil then
			total = total + (minorInfluence:GetTokensReceived(playerID) or 0);
		end
	end
	if LOTM_WORLD_Churches ~= nil and LOTM_WORLD_Churches.GetEnvoys ~= nil then
		for _, churchType in ipairs({"FOOL", "NIGHT", "STORM"}) do
			total = total + LOTM_WORLD_Churches.GetEnvoys(playerID, churchType);
		end
	end
	return total;
end

local function MigrateSequence9CivicScoring(playerID :number)
	if not IsBlackEmperor(playerID) or GetSequence(playerID) ~= 9 then
		return;
	end
	local player = GetPlayer(playerID);
	if player == nil or (player:GetProperty(P.CivicScoringMigrated) or 0) == 1
		or (player:GetProperty(P.FirstCityGranted) or 0) ~= 1 then
		return;
	end
	local culture = player:GetCulture();
	if culture == nil then
		return;
	end

	-- rc.41 awarded two points for civics and could retain policy-card points.
	-- Rebuild once from authoritative completed civics under the rc.42 rule.
	local completed :table = {};
	for civic in GameInfo.Civics() do
		if culture:HasCivic(civic.Index) then
			table.insert(completed, civic.Index);
		end
	end
	table.sort(completed);
	player:SetProperty("LOTM_RP_DIGEST_A", 0);
	player:SetProperty("LOTM_RP_DIGEST_B", 0);
	player:SetProperty("LOTM_RP_DIGEST_TURN", -1);
	player:SetProperty("LOTM_RP_DIGEST_TURN_GAIN", 0);
	for _, civicIndex in ipairs(completed) do
		AddDigestion(
			playerID,
			"A",
			"CIVIC_COMPLETED:" .. tostring(civicIndex),
			3
		);
	end
	player:SetProperty(P.CivicScoringMigrated, 1);
	Log("player=" .. tostring(playerID)
		.. " migrated Sequence 9 civic scoring completed="
		.. tostring(#completed));
end

local function RefreshEnvoyBaseline(playerID :number, allowGain :boolean)
	if not IsBlackEmperor(playerID) or GetSequence(playerID) ~= 7 then
		return;
	end
	local player = GetPlayer(playerID);
	local total = GetTotalEnvoys(playerID);
	local baseline = player:GetProperty(P.EnvoyBaseline);
	if baseline == nil or baseline < 0 then
		player:SetProperty(P.EnvoyBaseline, total);
		return;
	end
	if allowGain and total > baseline then
		for serial = baseline + 1, total do
			LOTM_RP_State.TryAddDigestion(
				playerID,
				"B",
				"ENVOY_GAIN:" .. tostring(Game.GetCurrentGameTurn())
					.. ":" .. tostring(serial)
			);
		end
	end
	player:SetProperty(P.EnvoyBaseline, total);
end

function LOTM_BE_RefreshEnvoyBaseline(playerID :number, allowGain :boolean)
	RefreshEnvoyBaseline(playerID, allowGain == true);
end

local function UnlockPolicyOnce(playerID :number, policyType :string, flagKey :string)
	local player = GetPlayer(playerID);
	if player == nil or (player:GetProperty(flagKey) or 0) == 1 then
		return false;
	end
	local policy = GameInfo.Policies[policyType];
	local culture = player:GetCulture();
	if policy == nil or culture == nil then
		return false;
	end
	culture:UnlockPolicy(policy.Index);
	player:SetProperty(flagKey, 1);
	Log("player=" .. tostring(playerID) .. " unlocked policy=" .. policyType);
	return true;
end

local function IsPolicyActive(playerID :number, policyType :string)
	local player = GetPlayer(playerID);
	local policy = GameInfo.Policies[policyType];
	local culture = player ~= nil and player:GetCulture() or nil;
	return policy ~= nil and culture ~= nil and culture:IsPolicyActive(policy.Index);
end

local function IsTransformationActive(playerID :number)
	local player = GetPlayer(playerID);
	return player ~= nil
		and tonumber(player:GetProperty("LOTM_BE_TRANSFORMATION_ACTIVE_SYNC")) == 1;
end

local function UnlockSequencePolicies(playerID :number, sequence :number)
	if sequence <= 5 then
		UnlockPolicyOnce(playerID, LOTM_BE_CHAOS_I, P.ChaosIUnlocked);
	end
	if sequence <= 4 then
		UnlockPolicyOnce(playerID, LOTM_BE_CHAOS_II, P.ChaosIIUnlocked);
		UnlockPolicyOnce(playerID, LOTM_BE_CORRUPTION_I, P.CorruptionIUnlocked);
	end
	if sequence <= 3 then
		UnlockPolicyOnce(playerID, LOTM_BE_FRENZY_I, P.FrenzyIUnlocked);
		UnlockPolicyOnce(playerID, LOTM_BE_CORRUPTION_II, P.CorruptionIIUnlocked);
	end
	if sequence <= 1 then
		UnlockPolicyOnce(playerID, LOTM_BE_CHAOS_III, P.ChaosIIIUnlocked);
		UnlockPolicyOnce(playerID, LOTM_BE_CORRUPTION_III, P.CorruptionIIIUnlocked);
		UnlockPolicyOnce(playerID, LOTM_BE_FRENZY_II, P.FrenzyIIUnlocked);
	end
end

local function CleanupStrandedCivilianBuilders(playerID :number)
	local player = GetPlayer(playerID);
	if player == nil
		or (player:GetProperty(P.CivilianBuildersV2Cleaned) or 0) == 1 then
		return false;
	end
	local stranded :table = {};
	for _, unit in player:GetUnits():Members() do
		local unitInfo = unit ~= nil and GameInfo.Units[unit:GetType()] or nil;
		if unitInfo ~= nil
			and unitInfo.FormationClass == "FORMATION_CLASS_CIVILIAN"
			and (unitInfo.BuildCharges or 0) > 0
			and unit:GetBuildCharges() <= 0 then
			table.insert(stranded, unit);
		end
	end
	table.sort(stranded, function(left, right)
		return left:GetID() < right:GetID();
	end);
	for _, unit in ipairs(stranded) do
		Log("removing stranded zero-charge civilian builder player="
			.. tostring(playerID) .. " unit=" .. tostring(unit:GetID()));
		UnitManager.Kill(unit, false);
	end
	player:SetProperty(P.CivilianBuildersV2Cleaned, 1);
	return #stranded > 0;
end

local function CorrectLegacyBuilderBaseStrength(playerID :number)
	local player = GetPlayer(playerID);
	if player == nil or not IsBlackEmperor(playerID)
		or GetSequence(playerID) > 8
		or (player:GetProperty(P.MightStrengthAttached) or 0) ~= 1
		or (player:GetProperty(P.LegacyBaseStrengthCorrected) or 0) == 1 then
		return false;
	end

	-- rc.41-46 permanently attached a player-wide +10 base-strength modifier.
	-- Permanent instances are serialized in the save and retain their original
	-- argument even though the current database row is now zero.  Detect the
	-- actual saved instance from a civilian builder instead of guessing from a
	-- version/property flag, so clean new games never receive this correction.
	for _, unit in player:GetUnits():Members() do
		local unitInfo = unit ~= nil and GameInfo.Units[unit:GetType()] or nil;
		local databaseCombat = unitInfo ~= nil
			and (tonumber(unitInfo.Combat) or 0) or 0;
		local runtimeCombat = unit ~= nil and (unit:GetCombat() or 0) or 0;
		if unitInfo ~= nil
			and unitInfo.FormationClass == "FORMATION_CLASS_CIVILIAN"
			and (unitInfo.BuildCharges or 0) > 0
			and databaseCombat == 0
			and runtimeCombat >= 10 then
			local attached = LOTM_RP_State.AttachModifierOnce(
				playerID,
				"LOTM_BE_MOD_LEGACY_BASE_STRENGTH_CORRECTION",
				P.LegacyBaseStrengthCorrected
			);
			Log("legacy base-strength migration player=" .. tostring(playerID)
				.. " unit=" .. tostring(unit:GetID())
				.. " unitType=" .. tostring(unitInfo.UnitType)
				.. " databaseCombat=" .. tostring(databaseCombat)
				.. " runtimeBefore=" .. tostring(runtimeCombat)
				.. " runtimeAfter=" .. tostring(unit:GetCombat())
				.. " attached=" .. tostring(attached));
			return attached;
		end
	end
	return false;
end

function LOTM_BE_RefreshSequenceState(playerID :number)
	if not IsBlackEmperor(playerID) then
		return false;
	end
	local sequence = GetSequence(playerID);
	GrantFirstCityReward(playerID);
	MigrateSequence9CivicScoring(playerID);
	if sequence <= 8 then
		CorrectLegacyBuilderBaseStrength(playerID);
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			"LOTM_BE_MOD_MIGHT_BASE_STRENGTH_AURA_V2",
			P.MightStrengthV2Attached
		);
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			"LOTM_BE_MOD_MIGHT_MOVEMENT",
			P.MightMovementAttached
		);
		CleanupStrandedCivilianBuilders(playerID);
	end
	if sequence <= 7 then
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			"LOTM_BE_MOD_BRIBERY_TRADE_GOLD",
			P.TradeGoldAttached
		);
	end
	if sequence <= 6 then
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			"LOTM_BE_MOD_CORRUPT_WEALTH_GOLD",
			P.WealthAttached
		);
	end
	if sequence <= 5 then
		UnlockSequencePolicies(playerID, sequence);
	end
	if sequence <= 4 then
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			"LOTM_BE_MOD_CORRUPT_PROSPERITY_FOOD",
			P.CorruptProsperityFoodAttached
		);
	end
	if sequence <= 2 then
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			"LOTM_BE_MOD_ENTROPY_PRESSURE",
			P.EntropyPressureAttached
		);
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			"LOTM_BE_MOD_ENTROPY_PRESSURE_V2_BONUS",
			P.EntropyPressureV2Attached
		);
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			"LOTM_BE_MOD_ENTROPY_LOYALTY",
			P.EntropyLoyaltyAttached
		);
	end
	if sequence <= 1 then
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			"LOTM_BE_MOD_ALLOW_TRANSFORMATION_PROJECT",
			P.TransformationProjectAttached
		);
	end
	if sequence <= 0 then
		for _, entry in ipairs(LOTM_BE_TOMB_SLOT_MODIFIERS) do
			LOTM_RP_State.AttachModifierOnce(playerID, entry[1], entry[2]);
		end
	end
	if sequence == 7 then
		RefreshEnvoyBaseline(playerID, false);
	end
	return true;
end

function LOTM_BE_OnPathSelected(playerID :number)
	LOTM_BE_RefreshSequenceState(playerID);
end

local function OnPlayerTurnActivated(playerID :number, isFirstTimeThisTurn :boolean)
	if isFirstTimeThisTurn and ProcessNetworkEvents ~= nil then
		ProcessNetworkEvents(playerID);
	end
	InitializeTradeRouteBaseline(playerID, "PLAYER_TURN");
	if not IsBlackEmperor(playerID) then
		return;
	end
	LOTM_BE_RefreshSequenceState(playerID);
	if isFirstTimeThisTurn then
		RefreshEnvoyBaseline(playerID, true);
		local sequence = GetSequence(playerID);
		if sequence == 5 and IsPolicyActive(playerID, LOTM_BE_CHAOS_I) then
			LOTM_RP_State.TryAddDigestion(
				playerID,
				"A",
				"CHAOS_I_ACTIVE:" .. tostring(Game.GetCurrentGameTurn())
			);
		elseif sequence == 4 and (
			IsPolicyActive(playerID, LOTM_BE_CORRUPTION_I)
			or IsPolicyActive(playerID, LOTM_BE_CHAOS_II)
		) then
			LOTM_RP_State.TryAddDigestion(
				playerID, "B", "SEQUENCE4_POLICY_ACTIVE:"
					.. tostring(Game.GetCurrentGameTurn())
			);
		elseif sequence == 3 then
			if IsPolicyActive(playerID, LOTM_BE_FRENZY_I) then
				LOTM_RP_State.TryAddDigestion(
					playerID, "A", "FRENZY_I_ACTIVE:"
						.. tostring(Game.GetCurrentGameTurn())
				);
			end
			if IsPolicyActive(playerID, LOTM_BE_CORRUPTION_II) then
				LOTM_RP_State.TryAddDigestion(
					playerID, "B", "CORRUPTION_II_ACTIVE:"
						.. tostring(Game.GetCurrentGameTurn())
				);
			end
		elseif sequence == 1 then
			if IsTransformationActive(playerID) then
				LOTM_RP_State.TryAddDigestion(
					playerID, "A", "TRANSFORMATION_ACTIVE:"
						.. tostring(Game.GetCurrentGameTurn())
				);
			end
			if IsPolicyActive(playerID, LOTM_BE_CHAOS_III)
				or IsPolicyActive(playerID, LOTM_BE_CORRUPTION_III)
				or IsPolicyActive(playerID, LOTM_BE_FRENZY_II) then
				LOTM_RP_State.TryAddDigestion(
					playerID, "B", "SEQUENCE1_POLICY_ACTIVE:"
						.. tostring(Game.GetCurrentGameTurn())
				);
			end
		end
	end
end

local function OnCityBuilt(playerID :number, cityID :number)
	local player = GetPlayer(playerID);
	local city = player ~= nil and player:GetCities():FindID(cityID) or nil;
	local plot = city ~= nil and Map.GetPlot(city:GetX(), city:GetY()) or nil;
	if plot ~= nil then
		plot:SetProperty(LOTM_BE_CITY_OWNER_PROPERTY, playerID);
	end
	if IsBlackEmperor(playerID) then
		GrantFirstCityReward(playerID);
	end
end

local function OnUnitAddedToMap(playerID :number, unitID :number)
	if LOTM_MP_TurnSync.IsNetworkGame() then
		return;
	end
	if IsBlackEmperor(playerID) and GetSequence(playerID) <= 8 then
		CorrectLegacyBuilderBaseStrength(playerID);
	end
end

local function QueueNetworkEvent(kind :string, stableIdentity :string, details :table)
	local queuedTurn = Game.GetCurrentGameTurn();
	local key = tostring(queuedTurn) .. ":" .. tostring(kind) .. ":" .. tostring(stableIdentity);
	local existing = pendingNetworkEventKeys[key];
	if existing ~= nil then
		existing.Count = (existing.Count or 1) + 1;
		return existing;
	end
	local entry = details or {};
	entry.Kind = kind;
	entry.QueuedTurn = queuedTurn;
	entry.StableIdentity = tostring(stableIdentity);
	entry.Key = key;
	entry.Count = 1;
	pendingNetworkEvents[#pendingNetworkEvents + 1] = entry;
	pendingNetworkEventKeys[key] = entry;
	return entry;
end

local function ApplyCivicCompleted(
	playerID :number,
	civicIndex :number,
	isCanceled :boolean,
	wasAutomaticGrant :boolean
)
	if IsBlackEmperor(playerID) and GetSequence(playerID) == 9 and not isCanceled then
		local player = GetPlayer(playerID);
		local civic = GameInfo.Civics[LOTM_BE_CODE_OF_LAWS];
		if player ~= nil and civic ~= nil and civic.Index == civicIndex
			and (wasAutomaticGrant == true
				or player:GetProperty(P.AutomaticCivicTurn) == Game.GetCurrentGameTurn()) then
			return;
		end
		AddDigestion(
			playerID,
			"A",
			"CIVIC_COMPLETED:" .. tostring(civicIndex),
			3
		);
	end
end

local function OnCivicCompleted(playerID :number, civicIndex :number, isCanceled :boolean)
	if not LOTM_MP_TurnSync.IsNetworkGame() then
		ApplyCivicCompleted(playerID, civicIndex, isCanceled, false);
		return;
	end
	local normalizedPlayerID = tonumber(playerID);
	local normalizedCivicIndex = tonumber(civicIndex);
	if isCanceled or normalizedPlayerID == nil or normalizedCivicIndex == nil
		or not IsBlackEmperor(normalizedPlayerID) then
		return;
	end
	local player = GetPlayer(normalizedPlayerID);
	local wasAutomaticGrant = player ~= nil
		and player:GetProperty(P.AutomaticCivicTurn) == Game.GetCurrentGameTurn();
	QueueNetworkEvent(
		"CIVIC",
		tostring(normalizedPlayerID) .. ":" .. tostring(normalizedCivicIndex),
		{
			PlayerID = normalizedPlayerID,
			ObjectID = normalizedCivicIndex,
			WasAutomaticGrant = wasAutomaticGrant == true,
		}
	);
end

local function ApplyResearchCompleted(playerID :number, techIndex :number, isCanceled :boolean)
	if IsBlackEmperor(playerID) and GetSequence(playerID) == 5 and not isCanceled then
		LOTM_RP_State.TryAddDigestion(
			playerID,
			"B",
			"TECH_COMPLETED:" .. tostring(techIndex)
		);
	end
end

local function OnResearchCompleted(playerID :number, techIndex :number, isCanceled :boolean)
	if not LOTM_MP_TurnSync.IsNetworkGame() then
		ApplyResearchCompleted(playerID, techIndex, isCanceled);
		return;
	end
	local normalizedPlayerID = tonumber(playerID);
	local normalizedTechIndex = tonumber(techIndex);
	if isCanceled or normalizedPlayerID == nil or normalizedTechIndex == nil
		or not IsBlackEmperor(normalizedPlayerID) then
		return;
	end
	QueueNetworkEvent(
		"RESEARCH",
		tostring(normalizedPlayerID) .. ":" .. tostring(normalizedTechIndex),
		{ PlayerID = normalizedPlayerID, ObjectID = normalizedTechIndex }
	);
end

local function OnCityPopulationChanged(playerID :number, cityID :number, changeAmount :number)
	if IsBlackEmperor(playerID) and GetSequence(playerID) == 4
		and (changeAmount or 0) > 0 then
		LOTM_RP_State.TryAddDigestion(
			playerID,
			"A",
			"POPULATION_GROWTH:" .. tostring(Game.GetCurrentGameTurn())
				.. ":" .. tostring(cityID) .. ":" .. tostring(changeAmount)
		);
	end
end

local function IsLoyaltyTransfer(city)
	if city == nil or CityTransferTypes == nil then
		return false;
	end
	local transferType = city:GetLastTransferType();
	return transferType ~= nil and (
		(CityTransferTypes.BY_CULTURAL_IDENTITY ~= nil
			and transferType == CityTransferTypes.BY_CULTURAL_IDENTITY)
		or (CityTransferTypes.BY_LOYALTY ~= nil
			and transferType == CityTransferTypes.BY_LOYALTY)
	);
end

local function ObserveTransferredCity(playerID :number, city, previousOwner, source :string)
	if city == nil then
		return false;
	end
	local plot = Map.GetPlot(city:GetX(), city:GetY());
	if plot == nil then
		return false;
	end
	local currentOwner = city:GetOwner();
	local awardKey = tostring(previousOwner) .. ":" .. tostring(currentOwner)
		.. ":" .. tostring(Game.GetCurrentGameTurn());
	local shouldAward = previousOwner ~= nil and previousOwner ~= currentOwner
		and currentOwner == playerID
		and IsBlackEmperor(playerID) and GetSequence(playerID) == 2
		and IsLoyaltyTransfer(city)
		and plot:GetProperty(LOTM_BE_CITY_TRANSFER_AWARD_PROPERTY) ~= awardKey;
	plot:SetProperty(LOTM_BE_CITY_OWNER_PROPERTY, currentOwner);
	if not shouldAward then
		return false;
	end
	plot:SetProperty(LOTM_BE_CITY_TRANSFER_AWARD_PROPERTY, awardKey);
	local added = AddDigestion(
		playerID,
		"A",
		"LOYALTY_CITY_TRANSFER:" .. tostring(plot:GetIndex())
			.. ":" .. awardKey,
		3
	);
	Log("loyalty city transfer player=" .. tostring(playerID)
		.. " city=" .. tostring(city:GetID())
		.. " plot=" .. tostring(plot:GetIndex())
		.. " oldOwner=" .. tostring(previousOwner)
		.. " source=" .. tostring(source)
		.. " added=" .. tostring(added));
	return added > 0;
end

ScanCityOwnership = function(allowAwards :boolean)
	local indexedVersionValue = Game:GetProperty(LOTM_BE_CITY_INDEX_VERSION_PROPERTY);
	local indexedVersion = indexedVersionValue ~= nil and tonumber(indexedVersionValue) or nil;
	if indexedVersion ~= nil and indexedVersion >= LOTM_BE_CITY_INDEX_VERSION then
		return;
	end
	local ownerIDs :table = {};
	for _, ownerID in ipairs(PlayerManager.GetAliveIDs()) do
		ownerIDs[#ownerIDs + 1] = ownerID;
	end
	table.sort(ownerIDs);
	for _, ownerID in ipairs(ownerIDs) do
		local owner = GetPlayer(ownerID);
		if owner ~= nil then
			local cities :table = {};
			for _, city in owner:GetCities():Members() do
				cities[#cities + 1] = city;
			end
			table.sort(cities, function(a, b)
				local aPlot = Map.GetPlot(a:GetX(), a:GetY());
				local bPlot = Map.GetPlot(b:GetX(), b:GetY());
				return (aPlot ~= nil and aPlot:GetIndex() or -1)
					< (bPlot ~= nil and bPlot:GetIndex() or -1);
			end);
			for _, city in ipairs(cities) do
				local plot = Map.GetPlot(city:GetX(), city:GetY());
				if plot ~= nil then
					plot:SetProperty(LOTM_BE_CITY_OWNER_PROPERTY, ownerID);
				end
			end
		end
	end
	Game:SetProperty(LOTM_BE_CITY_INDEX_VERSION_PROPERTY, LOTM_BE_CITY_INDEX_VERSION);
	Log("city owner index migration version=" .. tostring(LOTM_BE_CITY_INDEX_VERSION));
end

local function OnCityTransfered(playerID :number, cityID :number)
	local player = GetPlayer(playerID);
	local city = player ~= nil and player:GetCities():FindID(cityID) or nil;
	if city == nil then
		return;
	end
	local plot = Map.GetPlot(city:GetX(), city:GetY());
	local previousOwner = plot ~= nil
		and plot:GetProperty(LOTM_BE_CITY_OWNER_PROPERTY) or nil;
	if LOTM_MP_TurnSync.IsNetworkGame() then
		if plot == nil then return; end
		local normalizedPlayerID = tonumber(playerID);
		local normalizedCityID = tonumber(cityID);
		local plotIndex = plot:GetIndex();
		local normalizedPreviousOwner = tonumber(networkCityObservedOwners[plotIndex]);
		if normalizedPreviousOwner == nil then
			normalizedPreviousOwner = tonumber(previousOwner);
		end
		if normalizedPlayerID == nil or normalizedCityID == nil then return; end
		networkCityObservedOwners[plotIndex] = normalizedPlayerID;
		local wasLoyaltyTransfer = IsLoyaltyTransfer(city);
		QueueNetworkEvent(
			"CITY_TRANSFER",
			table.concat({
				plotIndex, normalizedPreviousOwner or -1,
				normalizedPlayerID, normalizedCityID,
				wasLoyaltyTransfer and 1 or 0,
			}, ":"),
			{
				PlayerID = normalizedPlayerID,
				CityID = normalizedCityID,
				PlotIndex = plotIndex,
				PreviousOwner = normalizedPreviousOwner or -1,
				WasLoyaltyTransfer = wasLoyaltyTransfer,
			}
		);
		return;
	end
	ObserveTransferredCity(playerID, city, previousOwner, "event");
end

local function IsDefeatedUnit(unitID :number, unit)
	return unitID ~= nil and unitID >= 0
		and (unit == nil or unit:IsDead() or unit:IsDelayedDeath());
end

local function OnCombatOccurred(
	attackerPlayerID :number,
	attackerUnitID :number,
	defenderPlayerID :number,
	defenderUnitID :number
)
	local attackerPlayer = GetPlayer(attackerPlayerID);
	local attacker = attackerPlayer ~= nil
		and attackerPlayer:GetUnits():FindID(attackerUnitID) or nil;
	local defenderPlayer = GetPlayer(defenderPlayerID);
	local defender = defenderPlayer ~= nil
		and defenderPlayer:GetUnits():FindID(defenderUnitID) or nil;
	if IsBlackEmperor(attackerPlayerID) and GetSequence(attackerPlayerID) == 8
		and IsDefeatedUnit(defenderUnitID, defender) then
		AddDigestion(
			attackerPlayerID,
			"A",
			"KILL:" .. tostring(Game.GetCurrentGameTurn()) .. ":"
				.. tostring(attackerUnitID) .. ":" .. tostring(defenderPlayerID)
				.. ":" .. tostring(defenderUnitID),
			2
		);
	elseif IsBlackEmperor(defenderPlayerID) and GetSequence(defenderPlayerID) == 8
		and IsDefeatedUnit(attackerUnitID, attacker) then
		AddDigestion(
			defenderPlayerID,
			"A",
			"KILL:" .. tostring(Game.GetCurrentGameTurn()) .. ":"
				.. tostring(defenderUnitID) .. ":" .. tostring(attackerPlayerID)
				.. ":" .. tostring(attackerUnitID),
			2
		);
	end
end

local function OnPillage(
	playerID :number,
	unitID :number,
	improvementType :number,
	buildingType :number,
	districtType :number,
	plotIndex :number
)
	if IsBlackEmperor(playerID) and GetSequence(playerID) == 8 then
		LOTM_RP_State.TryAddDigestion(
			playerID,
			"B",
			"PILLAGE:" .. tostring(Game.GetCurrentGameTurn()) .. ":"
				.. tostring(unitID) .. ":" .. tostring(plotIndex)
		);
	end
end

local function IsCommercialOrHarborDistrict(districtType :string)
	return districtType == "DISTRICT_COMMERCIAL_HUB"
		or districtType == "DISTRICT_HARBOR";
end

local function OnDistrictConstructed(
	playerID :number,
	districtType :number,
	x :number,
	y :number
)
	if not IsBlackEmperor(playerID) or GetSequence(playerID) ~= 6 then
		return;
	end
	local info = GameInfo.Districts[districtType];
	if info ~= nil and IsCommercialOrHarborDistrict(info.DistrictType) then
		LOTM_RP_State.TryAddDigestion(
			playerID,
			"A",
			"DISTRICT:" .. tostring(Game.GetCurrentGameTurn()) .. ":"
				.. tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(districtType)
		);
	end
end

local function OnBuildingConstructed(
	playerID :number,
	cityID :number,
	buildingIndex :number,
	plotIndex :number,
	isOriginalConstruction :boolean
)
	if not IsBlackEmperor(playerID) or GetSequence(playerID) ~= 6
		or not isOriginalConstruction then
		return;
	end
	local building = GameInfo.Buildings[buildingIndex];
	if building ~= nil and IsCommercialOrHarborDistrict(building.PrereqDistrict) then
		LOTM_RP_State.TryAddDigestion(
			playerID,
			"A",
			"BUILDING:" .. tostring(cityID) .. ":" .. tostring(buildingIndex)
		);
	end
end

local GOLDEN_BRIBE_ARTIFACT :string = "GREATWORK_LOTM_BE_GOLDEN_BRIBE";

local function GetOutgoingTradeRouteCount(player)
	if player == nil or player.GetTrade == nil then return nil; end
	local trade = player:GetTrade();
	if trade == nil or trade.CountOutgoingRoutes == nil then return nil; end
	return trade:CountOutgoingRoutes();
end

local function GoldenBribePositiveActive(playerID :number)
	return LOTM_PP_ArtifactPositiveActive ~= nil
		and LOTM_PP_ArtifactPositiveActive(playerID, GOLDEN_BRIBE_ARTIFACT) == true;
end

local function IsAliveInfluenceRecipient(playerID :number)
	if playerID == nil or playerID < 0 then return false, nil; end
	local isAliveMinor = false;
	for _, minorID in ipairs(PlayerManager.GetAliveMinorIDs()) do
		if minorID == playerID then isAliveMinor = true; break; end
	end
	local player = isAliveMinor and GetPlayer(playerID) or nil;
	local influence = player ~= nil and player:GetInfluence() or nil;
	return influence ~= nil and influence:CanReceiveInfluence(), player;
end

InitializeTradeRouteBaseline = function(playerID :number, reason :string)
	local player = GetPlayer(playerID);
	if player == nil or player:GetProperty(P.TradeRouteActiveCount274) ~= nil then return; end
	local current = GetOutgoingTradeRouteCount(player);
	if current == nil then
		Log("trade-route baseline deferred player=" .. tostring(playerID)
			.. " reason=COUNT_API_UNAVAILABLE trigger=" .. tostring(reason));
		return;
	end
	player:SetProperty(P.TradeRouteActiveCount274, current);
	Log("trade-route baseline player=" .. tostring(playerID)
		.. " active=" .. tostring(current) .. " reason=" .. tostring(reason));
end

local function ApplyTradeRouteActivityChanged(
	eventPlayerID :number,
	originPlayerID :number,
	originCityID :number,
	destinationPlayerID :number,
	destinationCityID :number
)
	local player = GetPlayer(originPlayerID);
	if player == nil or not player:IsAlive() or not player:IsMajor() then return; end
	local current = GetOutgoingTradeRouteCount(player);
	if current == nil then
		Log("trade-route ignored player=" .. tostring(originPlayerID)
			.. " reason=COUNT_API_UNAVAILABLE");
		return;
	end
	local previous = tonumber(player:GetProperty(P.TradeRouteActiveCount274));
	if previous == nil then
		player:SetProperty(P.TradeRouteActiveCount274, current);
		Log("trade-route event baselined player=" .. tostring(originPlayerID)
			.. " active=" .. tostring(current));
		return;
	end
	-- Commit the synchronized transition before granting anything. Duplicate
	-- callbacks, save/load and multiplayer reconnects then observe no increase.
	player:SetProperty(P.TradeRouteActiveCount274, current);
	local delta = current - previous;
	if delta <= 0 then
		Log("trade-route ignored player=" .. tostring(originPlayerID)
			.. " previous=" .. tostring(previous) .. " current=" .. tostring(current)
			.. " delta=" .. tostring(delta) .. " reason=NOT_STARTED");
		return;
	end

	local isBriber = IsBlackEmperor(originPlayerID) and GetSequence(originPlayerID) == 7;
	local hasContract = GoldenBribePositiveActive(originPlayerID);
	if not isBriber and not hasContract then
		Log("trade-route ignored player=" .. tostring(originPlayerID)
			.. " previous=" .. tostring(previous) .. " current=" .. tostring(current)
			.. " delta=" .. tostring(delta) .. " reason=NO_POSITIVE_EFFECT");
		return;
	end
	local routeKey = tostring(Game.GetCurrentGameTurn()) .. ":"
		.. tostring(eventPlayerID) .. ":" .. tostring(originCityID) .. ":"
		.. tostring(destinationPlayerID) .. ":" .. tostring(destinationCityID)
		.. ":" .. tostring(previous) .. ">" .. tostring(current);
	if isBriber then
		LOTM_RP_State.TryAddDigestion(originPlayerID, "A", "TRADE_ROUTE:" .. routeKey);
	end

	local canReceive = IsAliveInfluenceRecipient(destinationPlayerID);
	if not canReceive then
		Log("trade-route resolved player=" .. tostring(originPlayerID)
			.. " destination=" .. tostring(destinationPlayerID)
			.. " delta=" .. tostring(delta) .. " envoy=false reason=NOT_REAL_CITY_STATE");
		return;
	end
	local originInfluence = player:GetInfluence();
	if originInfluence == nil then
		Log("trade-route resolved player=" .. tostring(originPlayerID)
			.. " destination=" .. tostring(destinationPlayerID)
			.. " delta=" .. tostring(delta) .. " envoy=false reason=ORIGIN_INFLUENCE_MISSING");
		return;
	end
	originInfluence:GiveFreeTokenToPlayer(destinationPlayerID);
	if isBriber then
		LOTM_RP_State.TryAddDigestion(originPlayerID, "B", "TRADE_ENVOY:" .. routeKey);
	end
	RefreshEnvoyBaseline(originPlayerID, false);
	Log("trade-route resolved player=" .. tostring(originPlayerID)
		.. " destination=" .. tostring(destinationPlayerID)
		.. " previous=" .. tostring(previous) .. " current=" .. tostring(current)
		.. " delta=" .. tostring(delta) .. " briber=" .. tostring(isBriber)
		.. " contractPositive=" .. tostring(hasContract) .. " envoy=true");
end

local function OnTradeRouteActivityChanged(
	eventPlayerID :number,
	originPlayerID :number,
	originCityID :number,
	destinationPlayerID :number,
	destinationCityID :number
)
	if not LOTM_MP_TurnSync.IsNetworkGame() then
		ApplyTradeRouteActivityChanged(
			eventPlayerID,
			originPlayerID,
			originCityID,
			destinationPlayerID,
			destinationCityID
		);
		return;
	end
	local normalizedOriginPlayerID = tonumber(originPlayerID);
	local normalizedEventPlayerID = tonumber(eventPlayerID) or -1;
	local normalizedOriginCityID = tonumber(originCityID) or -1;
	local normalizedDestinationPlayerID = tonumber(destinationPlayerID) or -1;
	local normalizedDestinationCityID = tonumber(destinationCityID) or -1;
	local player = GetPlayer(normalizedOriginPlayerID);
	if player == nil or not player:IsAlive() or not player:IsMajor() then return; end
	local current = GetOutgoingTradeRouteCount(player);
	if current == nil then
		Log("trade-route fact ignored player=" .. tostring(normalizedOriginPlayerID)
			.. " reason=COUNT_API_UNAVAILABLE");
		return;
	end
	local previousObserved = tonumber(networkTradeObservedCounts[normalizedOriginPlayerID]);
	if previousObserved == nil then
		previousObserved = tonumber(player:GetProperty(P.TradeRouteActiveCount274));
	end
	if previousObserved == nil then previousObserved = current; end
	networkTradeObservedCounts[normalizedOriginPlayerID] = current;
	local started = current > previousObserved;
	local stableIdentity = table.concat({
		normalizedOriginPlayerID,
		normalizedEventPlayerID,
		normalizedOriginCityID,
		normalizedDestinationPlayerID,
		normalizedDestinationCityID,
		current,
		started and 1 or 0,
	}, ":");
	QueueNetworkEvent("TRADE_ROUTE", stableIdentity, {
		PlayerID = normalizedOriginPlayerID,
		EventPlayerID = normalizedEventPlayerID,
		OriginCityID = normalizedOriginCityID,
		DestinationPlayerID = normalizedDestinationPlayerID,
		DestinationCityID = normalizedDestinationCityID,
		ObservedActiveCount = current,
		Started = started,
		WasBriber = IsBlackEmperor(normalizedOriginPlayerID)
			and GetSequence(normalizedOriginPlayerID) == 7,
		HadContract = GoldenBribePositiveActive(normalizedOriginPlayerID),
	});
end

local function OnCommandGoldPurchase(playerID :number, parameters :table)
	if not IsBlackEmperor(playerID) or GetSequence(playerID) ~= 6 then
		return;
	end
	local kind = parameters ~= nil and tostring(parameters.Kind or "") or "";
	if kind ~= "UNIT" and kind ~= "BUILDING" and kind ~= "GREAT_PERSON" then
		return;
	end
	local serial = parameters ~= nil and tostring(parameters.Serial or "") or "";
	if serial == "" then
		return;
	end
	if kind == "GREAT_PERSON" then
		local individualID = tonumber(parameters.IndividualID);
		local goldCost = tonumber(parameters.GoldCost);
		local goldSpent = tonumber(parameters.GoldSpent);
		local greatPeople = Game.GetGreatPeople();
		local confirmed = false;
		if individualID ~= nil and goldCost ~= nil and goldCost > 0
			and goldSpent == goldCost and greatPeople ~= nil then
			for _, entry in ipairs(greatPeople:GetPastTimeline()) do
				if entry.Individual == individualID and entry.Claimant == playerID then
					confirmed = true;
					break;
				end
			end
		end
		if not confirmed then
			Log("rejected unconfirmed Great Person purchase player=" .. tostring(playerID));
			return;
		end
	end
	LOTM_RP_State.TryAddDigestion(
		playerID,
		"B",
		"GOLD_PURCHASE:" .. kind .. ":" .. serial
	);
end

local function OnInfluenceChanged(playerID :number)
	if LOTM_MP_TurnSync.IsNetworkGame() then
		return;
	end
	if playerID ~= nil and playerID >= 0 then
		RefreshEnvoyBaseline(playerID, true);
		return;
	end
	for _, majorID in ipairs(SortedMajorIDs()) do
		RefreshEnvoyBaseline(majorID, true);
	end
end

local function ApplyCityProjectCompleted(playerID :number, cityID :number, projectID :number)
	if not IsBlackEmperor(playerID) then
		return;
	end
	local projectType :string = nil;
	local expectedSequence :number = nil;
	local nextSequence :number = nil;
	local barbarian = GameInfo.Projects["PROJECT_LOTM_BE_BARBARIAN_POTION"];
	local briber = GameInfo.Projects["PROJECT_LOTM_BE_BRIBER_POTION"];
	local baron = GameInfo.Projects["PROJECT_LOTM_BE_BARON_OF_CORRUPTION_POTION"];
	local chaosMentor = GameInfo.Projects["PROJECT_LOTM_BE_CHAOS_MENTOR_POTION"];
	local countOfCorruption = GameInfo.Projects["PROJECT_LOTM_BE_COUNT_OF_CORRUPTION_POTION"];
	local frenzyMage = GameInfo.Projects["PROJECT_LOTM_BE_FRENZY_MAGE_POTION"];
	local dukeOfEntropy = GameInfo.Projects["PROJECT_LOTM_BE_DUKE_OF_ENTROPY_POTION"];
	local princeOfAbolition = GameInfo.Projects["PROJECT_LOTM_BE_PRINCE_OF_ABOLITION_POTION"];
	local enthronement = GameInfo.Projects["PROJECT_LOTM_BE_ENTHRONEMENT"];
	local unconsecratedEnthronement =
		GameInfo.Projects["PROJECT_LOTM_BE_ENTHRONEMENT_UNCONSECRATED"];
	local allowWithoutChurch :boolean = false;
	if barbarian ~= nil and barbarian.Index == projectID then
		projectType, expectedSequence, nextSequence =
			"PROJECT_LOTM_BE_BARBARIAN_POTION", 9, 8;
	elseif briber ~= nil and briber.Index == projectID then
		projectType, expectedSequence, nextSequence =
			"PROJECT_LOTM_BE_BRIBER_POTION", 8, 7;
	elseif baron ~= nil and baron.Index == projectID then
		projectType, expectedSequence, nextSequence =
			"PROJECT_LOTM_BE_BARON_OF_CORRUPTION_POTION", 7, 6;
	elseif chaosMentor ~= nil and chaosMentor.Index == projectID then
		projectType, expectedSequence, nextSequence =
			"PROJECT_LOTM_BE_CHAOS_MENTOR_POTION", 6, 5;
	elseif countOfCorruption ~= nil and countOfCorruption.Index == projectID then
		projectType, expectedSequence, nextSequence =
			"PROJECT_LOTM_BE_COUNT_OF_CORRUPTION_POTION", 5, 4;
	elseif frenzyMage ~= nil and frenzyMage.Index == projectID then
		projectType, expectedSequence, nextSequence =
			"PROJECT_LOTM_BE_FRENZY_MAGE_POTION", 4, 3;
	elseif dukeOfEntropy ~= nil and dukeOfEntropy.Index == projectID then
		projectType, expectedSequence, nextSequence =
			"PROJECT_LOTM_BE_DUKE_OF_ENTROPY_POTION", 3, 2;
	elseif princeOfAbolition ~= nil and princeOfAbolition.Index == projectID then
		projectType, expectedSequence, nextSequence =
			"PROJECT_LOTM_BE_PRINCE_OF_ABOLITION_POTION", 2, 1;
	elseif enthronement ~= nil and enthronement.Index == projectID then
		projectType, expectedSequence, nextSequence =
			"PROJECT_LOTM_BE_ENTHRONEMENT", 1, 0;
	elseif unconsecratedEnthronement ~= nil
		and unconsecratedEnthronement.Index == projectID then
		projectType, expectedSequence, nextSequence =
			"PROJECT_LOTM_BE_ENTHRONEMENT_UNCONSECRATED", 1, 0;
		allowWithoutChurch = true;
	else
		return;
	end
	if not LOTM_RP_State.AdvanceSequence(
		playerID,
		expectedSequence,
		nextSequence,
		allowWithoutChurch
	) then
		Log("rejected project transition player=" .. tostring(playerID)
			.. " project=" .. projectType);
	end
end

local function OnCityProjectCompleted(playerID :number, cityID :number, projectID :number)
	if not LOTM_MP_TurnSync.IsNetworkGame() then
		ApplyCityProjectCompleted(playerID, cityID, projectID);
		return;
	end
	local normalizedPlayerID = tonumber(playerID);
	local normalizedCityID = tonumber(cityID);
	local normalizedProjectID = tonumber(projectID);
	if normalizedPlayerID == nil or normalizedProjectID == nil
		or not IsBlackEmperor(normalizedPlayerID) then
		return;
	end
	QueueNetworkEvent(
		"PROJECT",
		table.concat({
			normalizedPlayerID,
			normalizedProjectID,
			normalizedCityID or -1,
		}, ":"),
		{
			PlayerID = normalizedPlayerID,
			CityID = normalizedCityID or -1,
			ObjectID = normalizedProjectID,
		}
	);
end

local function ApplyNetworkCityTransfer(entry :table)
	local previousOwner = tonumber(entry.PreviousOwner) or -1;
	local currentOwner = tonumber(entry.PlayerID) or -1;
	local plotIndex = tonumber(entry.PlotIndex);
	local plot = plotIndex ~= nil and Map.GetPlotByIndex(plotIndex) or nil;
	if plot == nil or previousOwner < 0 or previousOwner == currentOwner
		or entry.WasLoyaltyTransfer ~= true
		or not IsBlackEmperor(currentOwner) or GetSequence(currentOwner) ~= 2 then
		return false;
	end
	local awardKey = tostring(previousOwner) .. ":" .. tostring(currentOwner)
		.. ":" .. tostring(entry.QueuedTurn);
	if plot:GetProperty(LOTM_BE_CITY_TRANSFER_AWARD_PROPERTY) == awardKey then
		return false;
	end
	plot:SetProperty(LOTM_BE_CITY_TRANSFER_AWARD_PROPERTY, awardKey);
	local added = AddDigestion(
		currentOwner,
		"A",
		"LOYALTY_CITY_TRANSFER:" .. tostring(plotIndex) .. ":" .. awardKey,
		3
	);
	Log("network loyalty city transfer player=" .. tostring(currentOwner)
		.. " city=" .. tostring(entry.CityID)
		.. " plot=" .. tostring(plotIndex)
		.. " oldOwner=" .. tostring(previousOwner)
		.. " added=" .. tostring(added));
	return added > 0;
end

local function ApplyNetworkTradeRoute(entry :table, stableSerial :number)
	if entry.Started ~= true then return false; end
	local originPlayerID = tonumber(entry.PlayerID);
	local player = GetPlayer(originPlayerID);
	if player == nil or not player:IsAlive() or not player:IsMajor() then return false; end
	local currentActive = GetOutgoingTradeRouteCount(player);
	if currentActive == nil then
		Log("network trade-route deferred player=" .. tostring(originPlayerID)
			.. " reason=COUNT_API_UNAVAILABLE");
		return false;
	end
	local previousActive = tonumber(player:GetProperty(P.TradeRouteActiveCount274));
	if previousActive == nil then previousActive = 0; end
	if currentActive <= previousActive then
		if currentActive < previousActive then
			player:SetProperty(P.TradeRouteActiveCount274, currentActive);
		end
		return false;
	end
	local wasBriber = entry.WasBriber == true;
	local hadContract = entry.HadContract == true;
	if not wasBriber and not hadContract then return false; end
	local routeKey = table.concat({
		entry.QueuedTurn,
		entry.EventPlayerID or -1,
		entry.OriginCityID or -1,
		entry.DestinationPlayerID or -1,
		entry.DestinationCityID or -1,
		stableSerial,
	}, ":");
	if wasBriber then
		LOTM_RP_State.TryAddDigestion(originPlayerID, "A", "TRADE_ROUTE:" .. routeKey);
	end
	local destinationPlayerID = tonumber(entry.DestinationPlayerID);
	local canReceive = IsAliveInfluenceRecipient(destinationPlayerID);
	if not canReceive then
		Log("network trade-route resolved player=" .. tostring(originPlayerID)
			.. " destination=" .. tostring(destinationPlayerID)
			.. " envoy=false reason=NOT_REAL_CITY_STATE");
		return false;
	end
	local originInfluence = player:GetInfluence();
	if originInfluence == nil then
		Log("network trade-route resolved player=" .. tostring(originPlayerID)
			.. " destination=" .. tostring(destinationPlayerID)
			.. " envoy=false reason=ORIGIN_INFLUENCE_MISSING");
		return false;
	end
	originInfluence:GiveFreeTokenToPlayer(destinationPlayerID);
	-- Commit the synchronized route baseline before processing the next captured
	-- start in this batch.  This makes multiple starts and duplicate callbacks
	-- consume exactly one transition each while remaining independent of the
	-- clients' local publication order.
	local nextActive = math.min(currentActive, previousActive + 1);
	player:SetProperty(P.TradeRouteActiveCount274, nextActive);
	if wasBriber then
		LOTM_RP_State.TryAddDigestion(originPlayerID, "B", "TRADE_ENVOY:" .. routeKey);
	end
	Log("network trade-route resolved player=" .. tostring(originPlayerID)
		.. " destination=" .. tostring(destinationPlayerID)
		.. " briber=" .. tostring(wasBriber)
		.. " contractPositive=" .. tostring(hadContract)
		.. " envoy=true");
	return true;
end

ProcessNetworkEvents = function(playerID :number)
	if not LOTM_MP_TurnSync.IsNetworkGame()
		or not LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID) then
		return;
	end
	local currentTurn = Game.GetCurrentGameTurn();
	local ready :table = {};
	local waiting :table = {};
	for _, entry in ipairs(pendingNetworkEvents) do
		if entry.QueuedTurn < currentTurn then
			ready[#ready + 1] = entry;
		else
			waiting[#waiting + 1] = entry;
		end
	end
	pendingNetworkEvents = waiting;
	local priority :table = {
		CIVIC = 1,
		RESEARCH = 2,
		TRADE_ROUTE = 3,
		CITY_TRANSFER = 4,
		PROJECT = 5,
	};
	table.sort(ready, function(a, b)
		if a.QueuedTurn ~= b.QueuedTurn then return a.QueuedTurn < b.QueuedTurn; end
		local aPriority = priority[a.Kind] or 99;
		local bPriority = priority[b.Kind] or 99;
		if aPriority ~= bPriority then return aPriority < bPriority; end
		local aPlayerID = tonumber(a.PlayerID) or -1;
		local bPlayerID = tonumber(b.PlayerID) or -1;
		if aPlayerID ~= bPlayerID then return aPlayerID < bPlayerID; end
		return tostring(a.StableIdentity) < tostring(b.StableIdentity);
	end);
	local touchedTradePlayers :table = {};
	local touchedTradePlayerSet :table = {};
	local touchedCityPlots :table = {};
	local touchedCityPlotSet :table = {};
	for stableSerial, entry in ipairs(ready) do
		if pendingNetworkEventKeys[entry.Key] == entry then
			pendingNetworkEventKeys[entry.Key] = nil;
		end
		local count = math.max(1, tonumber(entry.Count) or 1);
		if entry.Kind == "TRADE_ROUTE" then
			if touchedTradePlayerSet[entry.PlayerID] ~= true then
				touchedTradePlayerSet[entry.PlayerID] = true;
				touchedTradePlayers[#touchedTradePlayers + 1] = tonumber(entry.PlayerID);
			end
			for occurrence = 1, count do
				ApplyNetworkTradeRoute(entry, stableSerial * 1000 + occurrence);
			end
		elseif entry.Kind == "CITY_TRANSFER" then
			if touchedCityPlotSet[entry.PlotIndex] ~= true then
				touchedCityPlotSet[entry.PlotIndex] = true;
				touchedCityPlots[#touchedCityPlots + 1] = tonumber(entry.PlotIndex);
			end
			for occurrence = 1, count do
				ApplyNetworkCityTransfer(entry);
			end
		elseif entry.Kind == "PROJECT" then
			for occurrence = 1, count do
				ApplyCityProjectCompleted(entry.PlayerID, entry.CityID, entry.ObjectID);
			end
		elseif entry.Kind == "CIVIC" then
			for occurrence = 1, count do
				ApplyCivicCompleted(entry.PlayerID, entry.ObjectID, false, entry.WasAutomaticGrant);
			end
		elseif entry.Kind == "RESEARCH" then
			for occurrence = 1, count do
				ApplyResearchCompleted(entry.PlayerID, entry.ObjectID, false);
			end
		end
	end
	table.sort(touchedTradePlayers);
	for _, tradePlayerID in ipairs(touchedTradePlayers) do
		local player = GetPlayer(tradePlayerID);
		local current = GetOutgoingTradeRouteCount(player);
		if player ~= nil and current ~= nil then
			player:SetProperty(P.TradeRouteActiveCount274, current);
			networkTradeObservedCounts[tradePlayerID] = current;
			RefreshEnvoyBaseline(tradePlayerID, false);
		end
	end
	table.sort(touchedCityPlots);
	for _, plotIndex in ipairs(touchedCityPlots) do
		local plot = Map.GetPlotByIndex(plotIndex);
		if plot ~= nil then
			local ownerID = plot:GetOwner();
			plot:SetProperty(LOTM_BE_CITY_OWNER_PROPERTY, ownerID);
			networkCityObservedOwners[plotIndex] = ownerID;
		end
	end
end

local function Initialize()
	LOTM_MP_TurnSync.Add(OnPlayerTurnActivated,"BlackEmperor");
	Events.UnitAddedToMap.Add(LOTM_UnitAddedPerf.Wrap("BlackEmperor",OnUnitAddedToMap));
	GameEvents.CityBuilt.Add(OnCityBuilt);
	Events.CivicCompleted.Add(OnCivicCompleted);
	Events.ResearchCompleted.Add(OnResearchCompleted);
	GameEvents.OnCityPopulationChanged.Add(OnCityPopulationChanged);
	if Events.CityTransfered ~= nil then
		Events.CityTransfered.Add(OnCityTransfered);
	else
		Log("warning: CityTransfered event unavailable; using turn-scan loyalty fallback only");
	end
	Events.InfluenceChanged.Add(OnInfluenceChanged);
	Events.TradeRouteActivityChanged.Add(OnTradeRouteActivityChanged);
	GameEvents.OnDistrictConstructed.Add(OnDistrictConstructed);
	Events.CityProjectCompleted.Add(OnCityProjectCompleted);
	GameEvents.OnCombatOccurred.Add(OnCombatOccurred);
	GameEvents.OnPillage.Add(OnPillage);
	GameEvents.BuildingConstructed.Add(OnBuildingConstructed);
	GameEvents.LOTM_BE_Command_GoldPurchase.Add(OnCommandGoldPurchase);
	LOTM_MP_TurnSync.RunStartup(function()
		ScanCityOwnership(false);
		local playerIDs :table = {};
		for _, playerID in ipairs(SortedMajorIDs()) do playerIDs[#playerIDs + 1] = playerID; end
		table.sort(playerIDs);
		for _, playerID in ipairs(playerIDs) do
			InitializeTradeRouteBaseline(playerID, "INITIALIZE");
			if IsBlackEmperor(playerID) then
				LOTM_BE_RefreshSequenceState(playerID);
			end
		end
	end,"BlackEmperor");
	Log("initialized sequences 9-0");
end

Initialize();
