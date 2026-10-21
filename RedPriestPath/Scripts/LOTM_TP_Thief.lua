-- Thief pathway authoritative Gameplay module (normal mode only).
-- UI may only request the synchronized commands registered at the bottom.
include("LOTM_Effects");

local PATH = "PATH_THIEF";
local HERO = "UNIT_LOTM_TP_PATH_HOLDER";
local FAKE_GOLD = "RESOURCE_LOTM_TP_FAKE_GOLD";
local FAKE_GOLD_TRADE = "RESOURCE_LOTM_TP_FAKE_GOLD_TRADE";
local TOURISM_LUXURY = "RESOURCE_LOTM_TP_TOURISM_LUXURY";
local TARGET_COOLDOWN = 5;
local PROBE_VERSION = 4;
local LEGACY_TRADE_CARRIER_CLEANUP_VERSION = 1;
local PRODUCTION_DEBUFF_MINUS = "LOTM_TP_TARGET_PRODUCTION_MINUS_10";
local PRODUCTION_DEBUFF_PLUS = "LOTM_TP_TARGET_PRODUCTION_PLUS_10";
local pendingNetworkEvents = {};
local pendingNetworkEventKeys = {};

local P = {
	Target = "LOTM_TP_TARGET_PLAYER",
	TargetChangedTurn = "LOTM_TP_TARGET_CHANGED_TURN",
	BoostTurn = "LOTM_TP_LAST_BOOST_TURN",
	ProductionBuffer = "LOTM_TP_PRODUCTION_BUFFER",
	ScienceBuffer = "LOTM_TP_SCIENCE_BUFFER",
	CultureBuffer = "LOTM_TP_CULTURE_BUFFER",
	BorrowedCiv = "LOTM_TP_BORROWED_CIV",
	FinalBranch = "LOTM_TP_FINAL_BRANCH",
	TechNatural = "LOTM_TP_TECH_NATURAL_COUNT",
	CivicNatural = "LOTM_TP_CIVIC_NATURAL_COUNT",
	TechBurst = "LOTM_TP_TECH_BURST_ACTIVE",
	CivicBurst = "LOTM_TP_CIVIC_BURST_ACTIVE",
	PendingTech = "LOTM_TP_PENDING_TECH_GIFT",
	PendingCivic = "LOTM_TP_PENDING_CIVIC_GIFT",
	GiftGuardTech = "LOTM_TP_GIFT_GUARD_TECH",
	GiftGuardCivic = "LOTM_TP_GIFT_GUARD_CIVIC",
	GiftGuardTechIndex = "LOTM_TP_GIFT_GUARD_TECH_INDEX",
	GiftGuardCivicIndex = "LOTM_TP_GIFT_GUARD_CIVIC_INDEX",
	ProbeVersion = "LOTM_TP_PROBE_VERSION",
	CityTransferSupported = "LOTM_TP_CITY_TRANSFER_SUPPORTED",
	ProductionTransferSupported = "LOTM_TP_PRODUCTION_TRANSFER_SUPPORTED",
	AbilityDetachSupported = "LOTM_TP_ABILITY_DETACH_SUPPORTED",
	ReligionPressureSupported = "LOTM_TP_RELIGION_PRESSURE_SUPPORTED",
	TradeBridgeSupported = "LOTM_TP_TRADE_BRIDGE_SUPPORTED",
	LastProcessedTurn = "LOTM_TP_LAST_PROCESSED_TURN",
	LastProductionSettlementTurn = "LOTM_TP_LAST_PRODUCTION_SETTLEMENT_TURN",
	LastKnowledgeSource = "LOTM_TP_LAST_KNOWLEDGE_STEAL_SOURCE",
	LastKnowledgeTurn = "LOTM_TP_LAST_KNOWLEDGE_STEAL_TURN",
	LastKnowledgeScience = "LOTM_TP_LAST_KNOWLEDGE_STEAL_SCIENCE",
	LastKnowledgeCulture = "LOTM_TP_LAST_KNOWLEDGE_STEAL_CULTURE",
	LastKnowledgeFaith = "LOTM_TP_LAST_KNOWLEDGE_STEAL_FAITH",
	KnowledgeBonusScience = "LOTM_TP_KNOWLEDGE_BONUS_SCIENCE",
	KnowledgeBonusCulture = "LOTM_TP_KNOWLEDGE_BONUS_CULTURE",
	KnowledgeBonusFaith = "LOTM_TP_KNOWLEDGE_BONUS_FAITH",
	LastFakeGoldSettlement = "LOTM_TP_LAST_FAKE_GOLD_SETTLEMENT_SERIAL",
	LegacyTradeCarrierCleanup = "LOTM_TP_LEGACY_TRADE_CARRIER_CLEANUP_VERSION",
	ProductionDebuffTarget = "LOTM_TP_PRODUCTION_DEBUFF_TARGET",
	ParasiteOwner = "LOTM_TP_PARASITE_TARGET_OWNER",
	ParasiteCity = "LOTM_TP_PARASITE_TARGET_CITY",
	ParasiteX = "LOTM_TP_PARASITE_TARGET_X",
	ParasiteY = "LOTM_TP_PARASITE_TARGET_Y",
	ParasiteStartTurn = "LOTM_TP_PARASITE_START_TURN",
	ParasiteDueTurn = "LOTM_TP_PARASITE_DUE_TURN",
	LastParasiteCity = "LOTM_TP_LAST_PARASITE_CITY",
	LastParasiteTurn = "LOTM_TP_LAST_PARASITE_TURN",
	TourismBurstCleanupTurn = "LOTM_TP_TOURISM_BURST_CLEANUP_TURN",
	TourismBurstStock = "LOTM_TP_TOURISM_BURST_STOCK",
};

local POTIONS = {
	PROJECT_LOTM_TP_SWINDLER_POTION = {9, 8},
	PROJECT_LOTM_TP_CRYPTOLOGIST_POTION = {8, 7},
	PROJECT_LOTM_TP_PROMETHEUS_POTION = {7, 6},
	PROJECT_LOTM_TP_DREAM_STEALER_POTION = {6, 5},
	PROJECT_LOTM_TP_PARASITE_POTION = {5, 4},
	PROJECT_LOTM_TP_MENTOR_OF_DECEIT_POTION = {4, 3},
	PROJECT_LOTM_TP_FATE_TROJAN_POTION = {3, 2},
	PROJECT_LOTM_TP_WORM_OF_TIME_POTION = {2, 1},
	PROJECT_LOTM_TP_ERROR_APOTHEOSIS = {1, 0},
};

local function Log(message)
	print("[LOTM_TP][Thief] " .. tostring(message));
end

local function IsRescueMode()
	local state = tonumber(Game.GetProperty("LOTM_RESCUE_MODE") or 0) or 0;
	if state == 1 then return true; end
	if LOTM_MP_TurnSync ~= nil
		and type(LOTM_MP_TurnSync.IsRescueModeConfigured) == "function" then
		return LOTM_MP_TurnSync.IsRescueModeConfigured();
	end
	local configured = GameConfiguration.GetValue("GAMEMODE_LOTM_RESCUE");
	return configured == true or tonumber(configured or 0) == 1;
end

local function IsNetworkGame()
	return LOTM_MP_TurnSync ~= nil
		and type(LOTM_MP_TurnSync.IsNetworkGame) == "function"
		and LOTM_MP_TurnSync.IsNetworkGame() == true;
end

local function IsThief(playerID)
	return not IsRescueMode() and LOTM_RP_State ~= nil
		and LOTM_RP_State.IsThiefPlayer ~= nil
		and LOTM_RP_State.IsThiefPlayer(playerID);
end

local function GetSequence(playerID)
	return LOTM_RP_State.GetSequence(playerID);
end

local function StableRand(limit, label)
	if limit <= 0 then return 0; end
	local modulus, value = 2147483647, 104729;
	local gameSeed = GameConfiguration ~= nil and GameConfiguration.GetValue ~= nil
		and GameConfiguration.GetValue("GAME_SYNC_RANDOM_SEED") or 0;
	local mapSeed = MapConfiguration ~= nil and MapConfiguration.GetValue ~= nil
		and MapConfiguration.GetValue("RANDOM_SEED") or 0;
	local text = tostring(gameSeed) .. ":" .. tostring(mapSeed) .. ":LOTM_TP:" .. tostring(label);
	for index = 1, #text do value = (value * 131 + string.byte(text, index)) % modulus; end
	return value % limit;
end

local function GetResourceIndex()
	local row = GameInfo.Resources[FAKE_GOLD];
	return row ~= nil and row.Index or -1;
end

local function GetTradeBackingIndex()
	local row = GameInfo.Resources[FAKE_GOLD_TRADE];
	return row ~= nil and row.Index or -1;
end

local function GetTourismLuxuryIndex()
	local row = GameInfo.Resources[TOURISM_LUXURY];
	return row ~= nil and row.Index or -1;
end

local function GetResourceAmount(player, resourceIndex)
	local resources = player ~= nil and player:GetResources() or nil;
	if resourceIndex < 0 or resources == nil then return 0; end
	return math.max(0, math.floor(tonumber(resources:GetResourceAmount(resourceIndex)) or 0));
end

local function ChangeResourceAmount(player, resourceIndex, amount)
	local resources = player ~= nil and player:GetResources() or nil;
	if resourceIndex < 0 or resources == nil or resources.ChangeResourceAmount == nil then return false; end
	local current = GetResourceAmount(player, resourceIndex);
	local delta = math.floor(tonumber(amount) or 0);
	if delta < 0 then delta = -math.min(current, -delta); end
	if delta == 0 then return true; end
	resources:ChangeResourceAmount(resourceIndex, delta);
	return GetResourceAmount(player, resourceIndex) == current + delta;
end

local function GetFakeGold(player)
	return GetResourceAmount(player, GetResourceIndex());
end

local function ChangeFakeGold(player, amount)
	return ChangeResourceAmount(player, GetResourceIndex(), amount);
end

-- Tourism is granted by a native player tourism modifier.  The previous
-- implementation tried to fake an excess luxury inventory, but GameCore does
-- not count arbitrary ChangeResourceAmount stock as excess luxuries.
local function ReadInternationalTourists(player)
	local ok, value = pcall(function() return player:GetCulture():GetTouristsTo(); end);
	return ok and tonumber(value) or nil;
end

-- Civ VI exposes GetTouristsTo/GetTouristsFrom as read-only accessors in the
-- public Lua surface.  Keep the direct grant isolated here: if a game build
-- exposes a setter/change method, use it and verify the observed delta; if it
-- does not, leave the existing tourism modifier intact and record the exact
-- limitation instead of pretending a percentage is a fixed tourist grant.
local function GrantDirectInternationalTourists(player, amount)
	local before = ReadInternationalTourists(player);
	local directAmount = math.max(0, math.floor(tonumber(amount) or 0));
	if before == nil or directAmount <= 0 then return false, "NO_BASELINE"; end
	local culture = player ~= nil and player:GetCulture() or nil;
	local attempts = {
		{culture, "ChangeTouristsTo", function(target) return before + directAmount; end},
		{culture, "ChangeTourism", function() return directAmount; end},
		{culture, "SetTouristsTo", function() return before + directAmount; end},
		{player, "ChangeTourism", function() return directAmount; end},
		{player, "ChangeTourists", function() return directAmount; end},
		{player, "SetTouristsTo", function() return before + directAmount; end},
	};
	for _, attempt in ipairs(attempts) do
		local target, method, argument = attempt[1], attempt[2], attempt[3];
		local ok, available = pcall(function() return target ~= nil and type(target[method]) == "function"; end);
		if ok and available then
			local callOK = pcall(function() target[method](target, argument(target)); end);
			local after = ReadInternationalTourists(player);
			if callOK and after ~= nil and after >= before + directAmount then
				return true, method;
			end
		end
	end
	return false, "NO_PUBLIC_SETTER";
end

-- Select a fresh pre-registered instance for every serial so repeated projects
-- add another tourism-only modifier instead of being deduplicated.
local function ResolveTourismBurstModifier(baseID, serial)
	local branch = baseID == "LOTM_TP_TOURISM_BURST_II" and "II" or "I";
	local slot = math.floor(tonumber(serial) or 0);
	if slot >= 1 and slot <= 64 then
		return "LOTM_TP_TOURISM_BURST_" .. branch .. "_" .. tostring(slot);
	end
	return baseID;
end

local function ApplyTourismBurst(playerID, modifierID, amount)
	local player = Players[playerID];
	if player == nil then
		Log("culture transfer tourism failed player=" .. tostring(playerID)
			.. " modifier=" .. tostring(modifierID) .. " reason=NO_PLAYER");
		return false;
	end
	local touristsBefore = ReadInternationalTourists(player);
	local serial = (tonumber(player:GetProperty("LOTM_TP_TOURISM_SERIAL") or 0) or 0) + 1;
	local appliedModifierID = ResolveTourismBurstModifier(modifierID, serial);
	local ok, err = pcall(function() return player:AttachModifierByID(appliedModifierID); end);
	if not ok or err == false then
		Log("culture transfer tourism failed player=" .. tostring(playerID)
			.. " modifier=" .. tostring(appliedModifierID) .. " reason=ATTACH error=" .. tostring(err));
		return false;
	end
	local directAmount = modifierID == "LOTM_TP_TOURISM_BURST_II" and 15 or 5;
	local directOK, directReason = GrantDirectInternationalTourists(player, directAmount);
	player:SetProperty("LOTM_TP_TOURISM_SERIAL", serial);
	player:SetProperty("LOTM_TP_TOURISM_BEFORE", touristsBefore);
	player:SetProperty("LOTM_TP_TOURISM_AMOUNT", amount);
	player:SetProperty("LOTM_TP_TOURISM_DIRECT_AMOUNT", directAmount);
	Log("culture transfer tourism requested player=" .. tostring(playerID) .. " serial=" .. serial
		.. " modifier=" .. tostring(appliedModifierID) .. " amount=" .. tostring(amount)
		.. " effect=PLAYER_ADJUST_TOURISM"
		.. " directTourists=" .. tostring(directAmount)
		.. " directApplied=" .. tostring(directOK)
		.. " directMethod=" .. tostring(directReason)
		.. " touristsBefore=" .. tostring(touristsBefore) .. " touristsAfter=" .. tostring(ReadInternationalTourists(player)));
	return true;
end

local function CleanupTourismBurst(playerID, player, turn)
	local version = tonumber(player:GetProperty("LOTM_TP_TOURISM_CLEANUP_VERSION") or 0) or 0;
	if version >= 2 then return; end
	-- Clear only legacy rc.311–rc.315 carrier stock.  New transfers never
	-- create this resource and therefore cannot affect trade or luxury counts.
	local index = GetTourismLuxuryIndex();
	local stock = index >= 0 and GetResourceAmount(player, index) or 0;
	if stock > 0 and not ChangeResourceAmount(player, index, -stock) then
		Log("legacy tourism carrier cleanup failed player=" .. tostring(playerID)
			.. " amount=" .. tostring(stock));
		return;
	end
	player:SetProperty(P.TourismBurstCleanupTurn, nil);
	player:SetProperty(P.TourismBurstStock, nil);
	player:SetProperty("LOTM_TP_TOURISM_CLEANUP_VERSION", 2);
	if stock > 0 then
		Log("legacy tourism carrier cleared player=" .. tostring(playerID) .. " amount=" .. tostring(stock));
	end
end

local function ClearLegacyTradeCarrier(playerID)
	if IsNetworkGame() then return false; end
	local player = Players[playerID];
	if player == nil then return false; end
	local migrated = tonumber(player:GetProperty(P.LegacyTradeCarrierCleanup) or 0) or 0;
	if migrated >= LEGACY_TRADE_CARRIER_CLEANUP_VERSION then return true; end
	local backingIndex = GetTradeBackingIndex();
	if backingIndex < 0 then
		player:SetProperty(P.LegacyTradeCarrierCleanup, LEGACY_TRADE_CARRIER_CLEANUP_VERSION);
		return true;
	end
	local current = GetResourceAmount(player, backingIndex);
	if current > 0 and not ChangeResourceAmount(player, backingIndex, -current) then
		Log("legacy trade carrier cleanup failed player=" .. tostring(playerID)
			.. " amount=" .. tostring(current));
		return false;
	end
	player:SetProperty(P.LegacyTradeCarrierCleanup, LEGACY_TRADE_CARRIER_CLEANUP_VERSION);
	if current > 0 then
		Log("legacy trade carrier cleared player=" .. tostring(playerID)
			.. " amount=" .. tostring(current));
	end
	return true;
end

local function IsSameTeam(a, b)
	return a ~= nil and b ~= nil and a:GetTeam() == b:GetTeam();
end

local function HasMet(player, targetID)
	local diplomacy = player ~= nil and player:GetDiplomacy() or nil;
	return diplomacy ~= nil and diplomacy:HasMet(targetID);
end

local function IsLegalTarget(playerID, targetID)
	local player = Players[playerID];
	local target = Players[targetID];
	return targetID ~= nil and targetID >= 0 and targetID ~= playerID
		and player ~= nil and target ~= nil and target:IsAlive() and target:IsMajor()
		and not IsSameTeam(player, target) and HasMet(player, targetID);
end

local function ResolveTarget(playerID)
	local player = Players[playerID];
	local targetID = player ~= nil and tonumber(player:GetProperty(P.Target) or -1) or -1;
	if not IsLegalTarget(playerID, targetID) then
		if player ~= nil and targetID >= 0 then
			player:SetProperty(P.Target, -1);
			Log("target cleared player=" .. playerID .. " target=" .. targetID);
		end
		return -1, nil;
	end
	return targetID, Players[targetID];
end

local function AddDigestion(playerID, category, key, amount)
	if LOTM_RP_State ~= nil and LOTM_RP_State.TryAddDigestion ~= nil then
		return LOTM_RP_State.TryAddDigestion(playerID, category, key, amount);
	end
	return false;
end

local function TransferGold(playerID, targetID, target)
	local player = Players[playerID];
	local treasury = player ~= nil and player:GetTreasury() or nil;
	local targetTreasury = target ~= nil and target:GetTreasury() or nil;
	if treasury == nil or targetTreasury == nil then return 0; end
	local yield = math.max(0, tonumber(targetTreasury:GetGoldYield()) or 0);
	local amount = LOTM_Effects.CappedPercentFloor(yield, 50,
		targetTreasury:GetGoldBalance());
	if amount <= 0 then return 0; end
	local networkGame = LOTM_MP_TurnSync ~= nil and LOTM_MP_TurnSync.IsNetworkGame ~= nil
		and LOTM_MP_TurnSync.IsNetworkGame() == true;
	if not networkGame then
		-- A single-player transfer is committed only when both observable balance
		-- deltas match.  This also makes future logs prove that the 50% calculation
		-- reached the player's treasury instead of merely reaching this function.
		local playerBefore = tonumber(treasury:GetGoldBalance()) or 0;
		local targetBefore = tonumber(targetTreasury:GetGoldBalance()) or 0;
		local debitOK = pcall(function() targetTreasury:ChangeGoldBalance(-amount); end);
		local targetAfterDebit = tonumber(targetTreasury:GetGoldBalance()) or targetBefore;
		local actualDebit = targetBefore - targetAfterDebit;
		local creditOK = false;
		if debitOK and math.abs(actualDebit - amount) < 0.001 then
			creditOK = pcall(function() treasury:ChangeGoldBalance(amount); end);
		end
		local playerAfter = tonumber(treasury:GetGoldBalance()) or playerBefore;
		local actualCredit = playerAfter - playerBefore;
		if not debitOK or not creditOK or math.abs(actualDebit - amount) >= 0.001
			or math.abs(actualCredit - amount) >= 0.001 then
			-- Reverse only the deltas actually observed; a partial API failure must
			-- not create gold or silently delete it.
			if math.abs(actualDebit) >= 0.001 then
				pcall(function() targetTreasury:ChangeGoldBalance(actualDebit); end);
			end
			if math.abs(actualCredit) >= 0.001 then
				pcall(function() treasury:ChangeGoldBalance(-actualCredit); end);
			end
			Log("gold transfer rolled back player=" .. playerID .. " target=" .. targetID
				.. " requested=" .. amount .. " debited=" .. actualDebit .. " credited=" .. actualCredit);
			return 0;
		end
		Log("gold stolen player=" .. playerID .. " target=" .. targetID
			.. " yield=" .. yield .. " rate=50pct amount=" .. amount
			.. " targetBefore=" .. targetBefore .. " targetAfter=" .. targetAfterDebit
			.. " playerBefore=" .. playerBefore .. " playerAfter=" .. playerAfter);
		local capital = player:GetCities() ~= nil and player:GetCities():GetCapitalCity() or nil;
		if capital ~= nil and Game.AddWorldViewText ~= nil then
			-- Match the mod's existing yield-float presentation.  This is deliberately
			-- best-effort and runs only after the authoritative balance transaction.
			pcall(function()
				Game.AddWorldViewText(playerID,
					"[COLOR_FLOAT_GOLD]+" .. tostring(amount) .. " [ICON_Gold][ENDCOLOR]",
					capital:GetX(), capital:GetY());
			end);
		end
		return amount;
	end
	targetTreasury:ChangeGoldBalance(-amount);
	treasury:ChangeGoldBalance(amount);
	Log("gold stolen player=" .. playerID .. " target=" .. targetID .. " amount=" .. amount);
	return amount;
end

local function ApplyProgressBuffer(player, kind)
	local key = kind == "TECH" and P.ScienceBuffer or P.CultureBuffer;
	local amount = math.floor(tonumber(player:GetProperty(key) or 0) or 0);
	if amount <= 0 then return 0; end
	local object = kind == "TECH" and player:GetTechs() or player:GetCulture();
	if object == nil then return 0; end
	local current = kind == "TECH" and object:GetResearchingTech() or object:GetProgressingCivic();
	if current == nil or current < 0 then return 0; end
	local ok = pcall(function()
		if kind == "TECH" then object:ChangeCurrentResearchProgress(amount);
		else object:ChangeCurrentCulturalProgress(amount); end
	end);
	if ok then player:SetProperty(key, 0); return amount; end
	return 0;
end

local KNOWLEDGE_BONUS = {
	SCIENCE = {
		Property = P.KnowledgeBonusScience,
		Plus = "LOTM_TP_KNOWLEDGE_SCIENCE_PLUS_1",
		Minus = "LOTM_TP_KNOWLEDGE_SCIENCE_MINUS_1",
	},
	CULTURE = {
		Property = P.KnowledgeBonusCulture,
		Plus = "LOTM_TP_KNOWLEDGE_CULTURE_PLUS_1",
		Minus = "LOTM_TP_KNOWLEDGE_CULTURE_MINUS_1",
	},
	FAITH = {
		Property = P.KnowledgeBonusFaith,
		Plus = "LOTM_TP_KNOWLEDGE_FAITH_PLUS_1",
		Minus = "LOTM_TP_KNOWLEDGE_FAITH_MINUS_1",
	},
};

-- MODIFIER_PLAYER_ADJUST_YIELD_CHANGE is the same native flat-yield effect
-- already used by this mod's artifact and Hanged Man systems.  Keeping the
-- current net amount in a synchronized Property lets Gameplay attach only the
-- delta; the yield engine then updates both the top-panel total and settlement.
local function SetKnowledgeYieldBonus(playerID, player, category, desired)
	local definition = KNOWLEDGE_BONUS[category];
	if player == nil or definition == nil or player.AttachModifierByID == nil then
		return false, 0;
	end
	desired = math.max(0, math.floor(tonumber(desired or 0) or 0));
	local old = math.max(0, math.floor(tonumber(player:GetProperty(definition.Property) or 0) or 0));
	local delta = desired - old;
	if delta == 0 then return true, old; end
	local modifierID = delta > 0 and definition.Plus or definition.Minus;
	local rollbackID = delta > 0 and definition.Minus or definition.Plus;
	local count = math.abs(delta);
	local applied = 0;
	for _ = 1, count do
		local ok = pcall(function() player:AttachModifierByID(modifierID); end);
		if not ok then
			for _ = 1, applied do
				pcall(function() player:AttachModifierByID(rollbackID); end);
			end
			Log("knowledge yield bonus failed player=" .. playerID
				.. " category=" .. category .. " old=" .. old
				.. " desired=" .. desired .. " applied=" .. applied);
			return false, old;
		end
		applied = applied + 1;
	end
	player:SetProperty(definition.Property, desired);
	Log("knowledge yield bonus player=" .. playerID .. " category=" .. category
		.. " old=" .. old .. " desired=" .. desired .. " delta=" .. delta);
	return true, old;
end

local function RestoreKnowledgeYieldBonus(playerID, player, category, old)
	local restored = SetKnowledgeYieldBonus(playerID, player, category, old);
	if not restored then
		Log("knowledge yield bonus rollback failed player=" .. playerID
			.. " category=" .. category .. " desired=" .. tostring(old));
	end
end

local function ClearKnowledgeYieldBonuses(playerID, player)
	SetKnowledgeYieldBonus(playerID, player, "SCIENCE", 0);
	SetKnowledgeYieldBonus(playerID, player, "CULTURE", 0);
	SetKnowledgeYieldBonus(playerID, player, "FAITH", 0);
end

local function TransferKnowledgeAndFaith(playerID, targetID, target)
	local player = Players[playerID];
	if player == nil or target == nil then return 0; end
	-- Settle any legacy buffer once, then use native per-turn modifiers only.
	ApplyProgressBuffer(player, "TECH");
	ApplyProgressBuffer(player, "CIVIC");
	local movedScience, movedCulture, movedFaith = 0, 0, 0;
	local sourceTech = target:GetTechs();
	local sourceTechID = sourceTech ~= nil and sourceTech:GetResearchingTech() or -1;
	local science = sourceTech ~= nil and LOTM_Effects.PercentFloor(sourceTech:GetScienceYield(), 20) or 0;
	if science > 0 and sourceTechID ~= nil and sourceTechID >= 0 then
		science = math.min(science, math.floor(math.max(0, sourceTech:GetResearchProgress(sourceTechID))));
	else
		science = 0;
	end
	local scienceBonusOK, oldScience = SetKnowledgeYieldBonus(playerID, player, "SCIENCE", science);
	if scienceBonusOK and science > 0 then
		local ok, failure = pcall(function() sourceTech:ChangeCurrentResearchProgress(-science); end);
		if ok then movedScience = science;
		else
			RestoreKnowledgeYieldBonus(playerID, player, "SCIENCE", oldScience);
			Log("knowledge transfer failed player=" .. playerID .. " category=SCIENCE reason=" .. tostring(failure));
		end
	end
	local sourceCulture = target:GetCulture();
	local sourceCivicID = sourceCulture ~= nil and sourceCulture:GetProgressingCivic() or -1;
	local culture = sourceCulture ~= nil and LOTM_Effects.PercentFloor(sourceCulture:GetCultureYield(), 20) or 0;
	if culture > 0 and sourceCivicID ~= nil and sourceCivicID >= 0
		and sourceCulture.ChangeCurrentCulturalProgress == nil then
		Log("knowledge transfer failed player=" .. playerID .. " category=CULTURE reason=NO_PROGRESS_API");
	end
	if culture <= 0 or sourceCivicID == nil or sourceCivicID < 0
		or sourceCulture.ChangeCurrentCulturalProgress == nil then
		culture = 0;
	end
	local cultureBonusOK, oldCulture = SetKnowledgeYieldBonus(playerID, player, "CULTURE", culture);
	if cultureBonusOK and culture > 0 then
		-- GetCulturalProgress is exposed to Firaxis UI contexts but is nil in
		-- authoritative Gameplay.  Sequence 5 steals current positive Culture
		-- yield, so debit the calculated share without a UI-only progress read.
		local ok, failure = pcall(function() sourceCulture:ChangeCurrentCulturalProgress(-culture); end);
		if ok then movedCulture = culture;
		else
			RestoreKnowledgeYieldBonus(playerID, player, "CULTURE", oldCulture);
			Log("knowledge transfer failed player=" .. playerID .. " category=CULTURE reason=" .. tostring(failure));
		end
	end
	local sourceReligion = target:GetReligion();
	local faithYield = sourceReligion ~= nil and LOTM_Effects.PercentFloor(sourceReligion:GetFaithYield(), 20) or 0;
	local faith = sourceReligion ~= nil and math.min(faithYield, math.floor(math.max(0, sourceReligion:GetFaithBalance()))) or 0;
	local faithBonusOK, oldFaith = SetKnowledgeYieldBonus(playerID, player, "FAITH", faith);
	if faithBonusOK and faith > 0 then
		local ok, failure = pcall(function() sourceReligion:ChangeFaithBalance(-faith); end);
		if ok then movedFaith = faith;
		else
			RestoreKnowledgeYieldBonus(playerID, player, "FAITH", oldFaith);
			Log("knowledge transfer failed player=" .. playerID .. " category=FAITH reason=" .. tostring(failure));
		end
	end
	local moved = movedScience + movedCulture + movedFaith;
	if moved > 0 then
		local turn = Game.GetCurrentGameTurn();
		player:SetProperty(P.LastKnowledgeSource, targetID);
		player:SetProperty(P.LastKnowledgeTurn, turn);
		player:SetProperty(P.LastKnowledgeScience, movedScience);
		player:SetProperty(P.LastKnowledgeCulture, movedCulture);
		player:SetProperty(P.LastKnowledgeFaith, movedFaith);
		Log("knowledge stolen player=" .. playerID .. " target=" .. targetID
			.. " science=" .. movedScience .. " culture=" .. movedCulture
			.. " faith=" .. movedFaith .. " total=" .. moved
			.. " destination=NATIVE_PER_TURN_YIELD");
	end
	return moved;
end

local function TriggerRandomBoost(playerID)
	local player = Players[playerID];
	if player == nil then return false; end
	local candidates = {};
	local techs = player:GetTechs();
	for row in GameInfo.Technologies() do
		if not techs:HasTech(row.Index) and not techs:HasBoostBeenTriggered(row.Index) then
			table.insert(candidates, {kind="TECH", index=row.Index});
		end
	end
	local culture = player:GetCulture();
	for row in GameInfo.Civics() do
		if not culture:HasCivic(row.Index) and not culture:HasBoostBeenTriggered(row.Index) then
			table.insert(candidates, {kind="CIVIC", index=row.Index});
		end
	end
	table.sort(candidates, function(a,b) if a.kind == b.kind then return a.index < b.index; end return a.kind < b.kind; end);
	if #candidates == 0 then return false; end
	local pick = candidates[StableRand(#candidates, playerID .. ":BOOST:" .. Game.GetCurrentGameTurn()) + 1];
	local ok = pcall(function()
		if pick.kind == "TECH" then techs:TriggerBoost(pick.index, 1);
		else culture:TriggerBoost(pick.index, 1); end
	end);
	if ok then Log("boost player=" .. playerID .. " kind=" .. pick.kind .. " index=" .. pick.index); end
	return ok;
end

local function ProbePlayer(playerID)
	local player = Players[playerID];
	if player == nil then return; end
	local oldVersion = tonumber(player:GetProperty(P.ProbeVersion) or 0) or 0;
	local oldProduction = tonumber(player:GetProperty(P.ProductionTransferSupported) or -1) or -1;
	local oldDetach = tonumber(player:GetProperty(P.AbilityDetachSupported) or -1) or -1;
	local oldReligion = tonumber(player:GetProperty(P.ReligionPressureSupported) or -1) or -1;
	local oldTrade = tonumber(player:GetProperty(P.TradeBridgeSupported) or -1) or -1;
	player:SetProperty(P.ProbeVersion, PROBE_VERSION);
	-- CityManager.TransferCity is the native, lossless ownership API used by
	-- the subscribed Amon mod.  Expose the capability only when the runtime
	-- actually provides it; the UI remains hidden on builds without it.
	local cityTransferSupported = CityManager ~= nil and CityManager.TransferCity ~= nil;
	player:SetProperty(P.CityTransferSupported, cityTransferSupported and 1 or 0);
	local tradeSupported = not IsNetworkGame();
	player:SetProperty(P.TradeBridgeSupported, tradeSupported and 1 or 0);
	local capital = player:GetCities() ~= nil and player:GetCities():GetCapitalCity() or nil;
	local queue = capital ~= nil and capital:GetBuildQueue() or nil;
	-- The shipped Gameplay build queue exposes AddProgress (the same API used
	-- by the subscribed Amon mod), not ChangeCurrentProductionProgress.
	local productionSupported = queue ~= nil and queue.AddProgress ~= nil;
	player:SetProperty(P.ProductionTransferSupported, productionSupported and 1 or 0);
	player:SetProperty(P.AbilityDetachSupported, player.DetachModifierByID ~= nil and 1 or 0);
	local cityReligion = capital ~= nil and capital:GetReligion() or nil;
	player:SetProperty(P.ReligionPressureSupported,
		cityReligion ~= nil and cityReligion.AddReligiousPressure ~= nil and 1 or 0);
	local productionValue = productionSupported and 1 or 0;
	local detachValue = player.DetachModifierByID ~= nil and 1 or 0;
	local religionValue = cityReligion ~= nil and cityReligion.AddReligiousPressure ~= nil and 1 or 0;
	if oldVersion < PROBE_VERSION or oldProduction ~= productionValue
		or oldTrade ~= (tradeSupported and 1 or 0)
		or oldDetach ~= detachValue or oldReligion ~= religionValue then
			Log("probe player=" .. playerID
			.. " cityTransfer=" .. tostring(cityTransferSupported)
			.. " production=" .. tostring(productionSupported)
			.. " detach=" .. tostring(player.DetachModifierByID ~= nil)
			.. " religion=" .. tostring(cityReligion ~= nil and cityReligion.AddReligiousPressure ~= nil));
	end
end

local function AttachProductionDebuff(target, modifierID)
	if target == nil or target.AttachModifierByID == nil then return false; end
	return pcall(function() target:AttachModifierByID(modifierID); end);
end

local function DetachProductionDebuff(target, modifierID)
	if target == nil or target.DetachModifierByID == nil then return false; end
	return pcall(function() target:DetachModifierByID(modifierID); end);
end

local function ChangeProductionDebuffOwner(target, delta)
	if target == nil then return; end
	local count = math.max(0, tonumber(target:GetProperty("LOTM_TP_PRODUCTION_DEBUFF_COUNT") or 0) or 0);
	local nextCount = math.max(0, count + delta);
	if count == 0 and nextCount > 0 then
		AttachProductionDebuff(target, PRODUCTION_DEBUFF_MINUS);
	elseif count > 0 and nextCount == 0 then
		if not DetachProductionDebuff(target, PRODUCTION_DEBUFF_MINUS) then
			AttachProductionDebuff(target, PRODUCTION_DEBUFF_PLUS);
		end
	end
	target:SetProperty("LOTM_TP_PRODUCTION_DEBUFF_COUNT", nextCount);
	target:SetProperty("LOTM_TP_PRODUCTION_DEBUFF_ACTIVE", nextCount > 0 and 1 or 0);
end

local function SyncProductionDebuff(playerID, targetID, target)
	local player = Players[playerID];
	if player == nil then return; end
	local oldID = tonumber(player:GetProperty(P.ProductionDebuffTarget) or -1) or -1;
	if oldID == targetID then return; end
	if oldID >= 0 and Players[oldID] ~= nil then ChangeProductionDebuffOwner(Players[oldID], -1); end
	if targetID ~= nil and targetID >= 0 and target ~= nil then ChangeProductionDebuffOwner(target, 1); end
	player:SetProperty(P.ProductionDebuffTarget, targetID ~= nil and targetID or -1);
	Log("production debuff target player=" .. playerID .. " target=" .. tostring(targetID or -1));
end

local function AccrueProduction(playerID, targetID, target)
	local player = Players[playerID];
	if player == nil or target == nil or (player:GetProperty(P.ProductionTransferSupported) or 0) ~= 1 then return 0; end
	-- The target cities carry the authoritative -10% modifier. Read their
	-- post-debuff production and transfer the corresponding lost share.
	local cities = {};
	for _, city in target:GetCities():Members() do cities[#cities + 1] = city; end
	table.sort(cities, function(a, b) return a:GetID() < b:GetID(); end);
	local total = 0;
	local postProductionTotal = 0;
	for _, city in ipairs(cities) do
		local after = math.max(0, tonumber(city:GetYield(YieldTypes.PRODUCTION)) or 0);
		postProductionTotal = postProductionTotal + after;
		local amount = math.floor((after / 0.9) * 0.1 + 0.0001);
		if amount > 0 then total = total + amount; end
	end
	if total <= 0 then return 0; end

	local buffered = math.floor(tonumber(player:GetProperty(P.ProductionBuffer) or 0) or 0);
	local nextBuffer = buffered + total;
	player:SetProperty(P.ProductionBuffer, nextBuffer);
	Log("production accrued player=" .. playerID .. " target=" .. targetID
		.. " postDebuffProduction=" .. postProductionTotal .. " amount=" .. total
		.. " buffer=" .. nextBuffer .. " awaiting=EXECUTE_SCRIPT");
	return total;
end

local function GetProductionQueue(city)
	local queue = city ~= nil and city:GetBuildQueue() or nil;
	if queue == nil or queue.AddProgress == nil then return nil, 0; end
	local currentHash = -1;
	if queue.GetCurrentProductionTypeHash ~= nil then
		local ok = pcall(function() currentHash = queue:GetCurrentProductionTypeHash(); end);
		if ok and tonumber(currentHash or 0) == 0 then return nil, 0; end
	end
	return queue, tonumber(currentHash or -1) or -1;
end

local function ProductionDestinations(playerID, player)
	local result, fallback = {}, {};
	local capital = player:GetCities():GetCapitalCity();
	local capitalQueue, capitalHash = GetProductionQueue(capital);
	if capitalQueue ~= nil then
		result[#result + 1] = {City=capital, Queue=capitalQueue, Hash=capitalHash};
	end
	for _, city in player:GetCities():Members() do
		if capital == nil or city:GetID() ~= capital:GetID() then
			local queue, currentHash = GetProductionQueue(city);
			if queue ~= nil then fallback[#fallback + 1] = {City=city, Queue=queue, Hash=currentHash}; end
		end
	end
	table.sort(fallback, function(a, b) return a.City:GetID() < b.City:GetID(); end);
	if #fallback > 0 then
		local start = StableRand(#fallback, playerID .. ":S6:DEST:" .. Game.GetCurrentGameTurn()) + 1;
		for offset = 0, #fallback - 1 do
			result[#result + 1] = fallback[((start + offset - 1) % #fallback) + 1];
		end
	end
	return result;
end

local function OnSettleProduction(playerID, parameters)
	if not IsThief(playerID) or GetSequence(playerID) > 6 then return; end
	local player = Players[playerID];
	local turn = Game.GetCurrentGameTurn();
	if tonumber(player:GetProperty(P.LastProductionSettlementTurn) or -1) == turn then return; end
	local amount = math.floor(tonumber(player:GetProperty(P.ProductionBuffer) or 0) or 0);
	if amount <= 0 or (player:GetProperty(P.ProductionTransferSupported) or 0) ~= 1 then return; end
	local lastError = "NO_RECEIVING_QUEUE";
	for _, destination in ipairs(ProductionDestinations(playerID, player)) do
		local accepted, failure = pcall(function() destination.Queue:AddProgress(amount); end);
		if accepted then
			player:SetProperty(P.ProductionBuffer, 0);
			player:SetProperty(P.LastProductionSettlementTurn, turn);
			player:SetProperty("LOTM_TP_LAST_PRODUCTION_STEAL_AMOUNT", amount);
			player:SetProperty("LOTM_TP_LAST_PRODUCTION_STEAL_CITY", destination.City:GetID());
			player:SetProperty("LOTM_TP_LAST_PRODUCTION_STEAL_TURN", turn);
			Log("production stolen player=" .. playerID .. " amount=" .. amount
				.. " destinationCity=" .. destination.City:GetID()
				.. " productionHash=" .. destination.Hash
				.. " mode=YIELD_DEBUFF api=EXECUTE_SCRIPT:AddProgress");
			local sequence = GetSequence(playerID);
			if sequence == 6 then AddDigestion(playerID, "A", "TP:S6:PROD:" .. turn); end
			if sequence == 1 then AddDigestion(playerID, "A", "TP:S1:THEFT:" .. turn); end
			return;
		end
		lastError = tostring(failure or "ADD_PROGRESS_REJECTED");
	end
	Log("production settlement deferred player=" .. playerID .. " amount=" .. amount
		.. " reason=" .. lastError);
end

local function GetCivType(playerID)
	local config = PlayerConfigurations[playerID];
	return config ~= nil and config:GetCivilizationTypeName() or "";
end

local function TraitIsUniqueObject(traitType)
	for row in GameInfo.Units() do if row.TraitType == traitType then return true; end end
	for row in GameInfo.Buildings() do if row.TraitType == traitType then return true; end end
	for row in GameInfo.Districts() do if row.TraitType == traitType then return true; end end
	for row in GameInfo.Improvements() do if row.TraitType == traitType then return true; end end
	return false;
end

local function GetCivAbilityModifiers(civType)
	local result = {};
	for link in GameInfo.CivilizationTraits() do
		if link.CivilizationType == civType and not TraitIsUniqueObject(link.TraitType) then
			local trait = GameInfo.Traits[link.TraitType];
			if trait ~= nil and trait.Description ~= nil and trait.Description ~= "" then
				for tm in GameInfo.TraitModifiers() do
					if tm.TraitType == link.TraitType and GameInfo.Modifiers[tm.ModifierId] ~= nil then
						table.insert(result, tm.ModifierId);
					end
				end
			end
		end
	end
	table.sort(result);
	return result;
end

local function ApplyBorrowedAbility(playerID, civType)
	local player = Players[playerID];
	if civType == "" or civType == GetCivType(playerID) then
		Log("ability switch blocked player=" .. playerID .. " reason=NATIVE_OR_EMPTY_CIV");
		return false;
	end
	if player == nil or tostring(player:GetProperty(P.BorrowedCiv) or "") ~= "" then
		Log("ability choice rejected player=" .. playerID .. " reason=ALREADY_CHOSEN");
		return false;
	end
	local modifiers = GetCivAbilityModifiers(civType);
	if #modifiers == 0 then return false; end
	-- Persist the in-flight choice as well: a partial attach failure may retry
	-- this civilization only, and never stacks already attached modifiers.
	local pending = tostring(player:GetProperty("LOTM_TP_BORROW_PENDING_CIV") or "");
	if pending ~= "" and pending ~= civType then return false; end
	player:SetProperty("LOTM_TP_BORROW_PENDING_CIV", civType);
	local seen = {};
	for _, modifierID in ipairs(modifiers) do
		local key = "LOTM_TP_BORROW_APPLIED_" .. modifierID;
		if not seen[modifierID] and (player:GetProperty(key) or 0) ~= 1 then
			local ok, result = pcall(function() return player:AttachModifierByID(modifierID); end);
			if not ok or result == false then
				Log("ability choice failed player=" .. playerID .. " modifier=" .. modifierID);
				return false;
			end
			player:SetProperty(key, 1);
		end
		seen[modifierID] = true;
	end
	player:SetProperty(P.BorrowedCiv, civType);
	Log("ability switched player=" .. playerID .. " civ=" .. civType);
	return true;
end

local function ApplyAllAbilities(playerID)
	local player = Players[playerID];
	if player == nil then return; end
	if (player:GetProperty("LOTM_TP_ALL_ABILITIES_AUDIT_VERSION") or 0) >= 1 then
		local pending = tostring(player:GetProperty("LOTM_TP_ALL_ABILITIES_RETRY") or "");
		if pending == "" then return; end
		local remaining = {};
		local count = tonumber(player:GetProperty("LOTM_TP_ALL_ABILITIES_LOADED")) or 0;
		for modifierID in string.gmatch(pending, "[^,]+") do
			local ok, result = pcall(function() return player:AttachModifierByID(modifierID); end);
			if ok and result ~= false then
				player:SetProperty("LOTM_TP_ALL_APPLIED_" .. modifierID, 1);
				player:SetProperty("LOTM_TP_ALL_STATUS_" .. modifierID, "ATTACHED"); count = count + 1;
			else table.insert(remaining, modifierID); end
		end
		player:SetProperty("LOTM_TP_ALL_ABILITIES_RETRY", table.concat(remaining, ","));
		player:SetProperty("LOTM_TP_ALL_ABILITIES_LOADED", count);
		player:SetProperty("LOTM_TP_ALL_ABILITIES_ATTACHED", count == player:GetProperty("LOTM_TP_ALL_ABILITIES_TOTAL") and 1 or 0);
		return;
	end
	-- One migration for the old aggregate flag. Inspect actual instances before
	-- filling gaps, including the ability already borrowed at Sequence 2.
	local legacy = (player:GetProperty("LOTM_TP_ALL_ABILITIES_ATTACHED") or 0) == 1;
	local attached, inspected = {}, false;
	if GameEffects ~= nil and GameEffects.GetModifiers ~= nil
		and GameEffects.GetModifierDefinition ~= nil and GameEffects.GetModifierOwner ~= nil
		and GameEffects.GetObjectsPlayerId ~= nil then
		inspected = pcall(function()
			for _, id in ipairs(GameEffects.GetModifiers() or {}) do
				local def = GameEffects.GetModifierDefinition(id);
				local owner = GameEffects.GetModifierOwner(id);
				if def ~= nil and owner ~= nil and GameEffects.GetObjectsPlayerId(owner) == playerID then
					attached[def.Id] = true;
				end
			end
		end);
	end
	local seen = {};
	local complete = true;
	local retry = {};
	local total, loaded = 0, 0;
	local sources = PlayerManager.GetWasEverAliveMajors();
	if LOTM_MP_TurnSync.IsNetworkGame() then
		local ordered = {}; for _, source in ipairs(sources or {}) do table.insert(ordered, source); end
		table.sort(ordered, function(a,b) return a:GetID() < b:GetID(); end); sources = ordered;
	end
	for _, source in ipairs(sources or {}) do
		local sourceID = source:GetID();
		if sourceID ~= playerID and GetCivType(sourceID) ~= GetCivType(playerID) then
			for _, modifierID in ipairs(GetCivAbilityModifiers(GetCivType(sourceID))) do
				if not seen[modifierID] then
					seen[modifierID] = true; total = total + 1;
					local key = "LOTM_TP_ALL_APPLIED_" .. modifierID;
					local present = attached[modifierID] == true or (player:GetProperty(key) or 0) == 1
						or (not inspected and (player:GetProperty("LOTM_TP_BORROW_APPLIED_" .. modifierID) or 0) == 1);
					local status = present and "CONFIRMED" or "MISSING";
					if not present and legacy and not inspected then
						status = "LEGACY_UNVERIFIED";
					elseif not present then
						local ok, result = pcall(function() return player:AttachModifierByID(modifierID); end);
						present = ok and result ~= false;
						status = present and "ATTACHED" or "FAILED";
					end
					if present then loaded = loaded + 1; player:SetProperty(key, 1); else complete = false; end
					player:SetProperty("LOTM_TP_ALL_STATUS_" .. modifierID, status);
					if status == "FAILED" then table.insert(retry, modifierID); end
					Log("ability audit player=" .. playerID .. " civ=" .. GetCivType(sourceID)
						.. " modifier=" .. modifierID .. " status=" .. status);
				end
			end
		end
	end
	player:SetProperty("LOTM_TP_ALL_ABILITIES_ATTACHED", complete and 1 or 0);
	player:SetProperty("LOTM_TP_ALL_ABILITIES_AUDIT_VERSION", 1);
	player:SetProperty("LOTM_TP_ALL_ABILITIES_TOTAL", total);
	player:SetProperty("LOTM_TP_ALL_ABILITIES_RETRY", table.concat(retry, ","));
	player:SetProperty("LOTM_TP_ALL_ABILITIES_LOADED", loaded);
	Log("all abilities audited player=" .. playerID .. " loaded=" .. loaded .. " total=" .. total
		.. " inspected=" .. tostring(inspected));
end

local function ApplyReligionPressure(player, city, amount)
	local religion = player:GetReligion();
	local religionID = religion ~= nil and religion:GetReligionTypeCreated() or -1;
	local cityReligion = city ~= nil and city:GetReligion() or nil;
	if religionID == nil or religionID < 0 or cityReligion == nil
		or cityReligion.AddReligiousPressure == nil then return false; end
	return pcall(function() cityReligion:AddReligiousPressure(religionID, amount); end);
end

local function GetMissionarySpreadPressure()
	local missionary = GameInfo.Units["UNIT_MISSIONARY"];
	local strength = missionary ~= nil and tonumber(missionary.ReligiousStrength) or 100;
	return math.max(1, math.floor(strength or 100));
end

local function CompleteFaithTransfer(playerID, allMajors)
	local player = Players[playerID];
	if player == nil then return false; end
	local capital = player:GetCities():GetCapitalCity();
	if capital == nil then return false; end
	local religionID = player:GetReligion():GetReligionTypeCreated();
	if religionID == nil or religionID < 0 then return false; end
	local candidates = {};
	local owners = PlayerManager.GetAliveMajorIDs();
	for _, ownerID in ipairs(owners) do
		local owner = Players[ownerID];
		if owner ~= nil and owner:IsAlive() and owner:IsMajor() then
			for _, city in owner:GetCities():Members() do
				local cityReligion = city:GetReligion();
				if cityReligion ~= nil and cityReligion:GetMajorityReligion() ~= religionID then
					table.insert(candidates, city);
				end
			end
		end
	end
	local spreadPressure = GetMissionarySpreadPressure();
	local spreadsPerCity = 10;
	local function CityDistance(city)
		return Map.GetPlotDistance(capital:GetX(), capital:GetY(), city:GetX(), city:GetY());
	end
	table.sort(candidates, function(a,b)
		local da, db = CityDistance(a), CityDistance(b);
		if da == db then
			if a:GetOwner() == b:GetOwner() then return a:GetID() < b:GetID(); end
			return a:GetOwner() < b:GetOwner();
		end
		return da < db;
	end);
	local limit = allMajors and 5 or 1;
	local changed = 0;
	for index = 1, math.min(limit, #candidates) do
		local city = candidates[index];
		local pressure = spreadPressure;
		local appliedCount = 0;
		for _ = 1, spreadsPerCity do
			if ApplyReligionPressure(player, city, pressure) then appliedCount = appliedCount + 1; end
		end
		local applied = appliedCount == spreadsPerCity;
		if applied then
			changed = changed + 1;
			Log("faith transfer applied player=" .. tostring(playerID)
				.. " mode=" .. (allMajors and "II" or "I")
				.. " owner=" .. tostring(city:GetOwner()) .. " city=" .. tostring(city:GetID())
				.. " spreads=" .. tostring(spreadsPerCity)
				.. " pressurePerSpread=" .. tostring(pressure)
				.. " applied=" .. tostring(appliedCount));
		end
	end
	return changed > 0;
end

local function GiftCurrent(playerID, kind)
	local player = Players[playerID];
	if player == nil then return false; end
	if kind == "TECH" then
		local techs = player:GetTechs(); local current = techs:GetResearchingTech();
		if current == nil or current < 0 then player:SetProperty(P.PendingTech, 1); return false; end
		player:SetProperty(P.GiftGuardTech, 1);
		player:SetProperty(P.GiftGuardTechIndex, current);
		techs:SetResearchProgress(current, techs:GetResearchCost(current));
		player:SetProperty(P.PendingTech, 0); return true;
	else
		local culture = player:GetCulture(); local current = culture:GetProgressingCivic();
		if current == nil or current < 0 then player:SetProperty(P.PendingCivic, 1); return false; end
		player:SetProperty(P.GiftGuardCivic, 1);
		player:SetProperty(P.GiftGuardCivicIndex, current);
		culture:SetCulturalProgress(current, culture:GetCultureCost(current));
		player:SetProperty(P.PendingCivic, 0); return true;
	end
end

local function ProcessTurn(playerID)
	if not IsThief(playerID) then return; end
	local player = Players[playerID];
	local turn = Game.GetCurrentGameTurn();
	local networkGame = LOTM_MP_TurnSync ~= nil and LOTM_MP_TurnSync.IsNetworkGame ~= nil
		and LOTM_MP_TurnSync.IsNetworkGame() == true;
	if not networkGame then
		local lastTurn = tonumber(player:GetProperty(P.LastProcessedTurn) or -1) or -1;
		if lastTurn == turn then return; end
	player:SetProperty(P.LastProcessedTurn, turn);
	end
	CleanupTourismBurst(playerID, player, turn);
	ProbePlayer(playerID);
	-- Resolve a previously designated city before accruing this turn's other
	-- effects.  The transfer itself is authoritative and idempotently verified.
	local function ProcessParasite()
		local due = tonumber(player:GetProperty(P.ParasiteDueTurn) or -1) or -1;
		if due < 0 or due > turn then return; end
		local ownerID = tonumber(player:GetProperty(P.ParasiteOwner) or -1) or -1;
		local cityID = tonumber(player:GetProperty(P.ParasiteCity) or -1) or -1;
		local city = ownerID >= 0 and cityID >= 0 and CityManager.GetCity(ownerID, cityID) or nil;
		local valid = city ~= nil and city:GetOwner() == ownerID and ownerID ~= playerID;
		if valid then
			local owner = Players[ownerID];
			valid = owner ~= nil and owner:IsAlive();
		end
		if not valid then
			Log("parasite cancelled player=" .. playerID .. " owner=" .. ownerID
				.. " city=" .. cityID .. " reason=TARGET_INVALID");
			for _, key in ipairs({P.ParasiteOwner,P.ParasiteCity,P.ParasiteX,P.ParasiteY,P.ParasiteStartTurn,P.ParasiteDueTurn}) do player:SetProperty(key, nil); end
			return;
		end
		local ok, result = pcall(function() return CityManager.TransferCity(city, playerID); end);
		local transferred = ok and result ~= false;
		local owned = CityManager.GetCity(playerID, cityID);
		if transferred and owned ~= nil and owned:GetOwner() == playerID then
			player:SetProperty(P.LastParasiteCity, cityID);
			player:SetProperty(P.LastParasiteTurn, turn);
			if GetSequence(playerID) == 4 then AddDigestion(playerID, "A", "TP:S4:PARASITE:" .. cityID .. ":" .. turn, 3); end
			Log("parasite completed player=" .. playerID .. " owner=" .. ownerID
				.. " city=" .. cityID .. " due=" .. due .. " api=CityManager.TransferCity");
		else
			Log("parasite transfer failed player=" .. playerID .. " owner=" .. ownerID
				.. " city=" .. cityID .. " api=CityManager.TransferCity ok=" .. tostring(ok)
				.. " result=" .. tostring(result));
		end
		for _, key in ipairs({P.ParasiteOwner,P.ParasiteCity,P.ParasiteX,P.ParasiteY,P.ParasiteStartTurn,P.ParasiteDueTurn}) do player:SetProperty(key, nil); end
	end
	ProcessParasite();
	local sequence = GetSequence(playerID);
	local targetID, target = ResolveTarget(playerID);
	if sequence > 5 or target == nil then
		ClearKnowledgeYieldBonuses(playerID, player);
	end
	if sequence <= 6 then
		SyncProductionDebuff(playerID, target ~= nil and targetID or -1, target);
	else
		SyncProductionDebuff(playerID, -1, nil);
	end
	local theftOccurred = false;
	if target ~= nil then
		local gold = TransferGold(playerID, targetID, target); theftOccurred = gold > 0 or theftOccurred;
		if sequence == 9 and gold > 0 then AddDigestion(playerID, "A", "TP:S9:GOLD:" .. turn); end
		if sequence <= 6 then
			AccrueProduction(playerID, targetID, target);
		end
		if sequence <= 5 then
			local knowledge = TransferKnowledgeAndFaith(playerID, targetID, target); theftOccurred = knowledge > 0 or theftOccurred;
			if sequence == 5 and knowledge > 0 then AddDigestion(playerID, "A", "TP:S5:YIELDS:" .. turn); end
		end
	end
	if sequence <= 8 then
		ChangeFakeGold(player, sequence <= 4 and 40 or 20);
	end
	if sequence <= 7 then
		local last = tonumber(player:GetProperty(P.BoostTurn) or -999) or -999;
		if turn - last >= 2 and TriggerRandomBoost(playerID) then
			player:SetProperty(P.BoostTurn, turn);
			if sequence == 7 then AddDigestion(playerID, "A", "TP:S7:BOOST:" .. turn); end
		end
	end
	if sequence == 2 and tostring(player:GetProperty(P.BorrowedCiv) or "") ~= "" then
		AddDigestion(playerID, "A", "TP:S2:BORROW:" .. turn);
	elseif sequence <= 1 then
		ApplyAllAbilities(playerID);
		if sequence == 1 and theftOccurred then AddDigestion(playerID, "A", "TP:S1:THEFT:" .. turn); end
	end
	if sequence == 0 and player:GetProperty(P.FinalBranch) == "TECH_CIVIC" then
		if (player:GetProperty(P.PendingTech) or 0) == 1 then GiftCurrent(playerID, "TECH"); end
		if (player:GetProperty(P.PendingCivic) or 0) == 1 then GiftCurrent(playerID, "CIVIC"); end
	end
end

function LOTM_TP_RefreshSequenceState(playerID)
	if not IsThief(playerID) then return false; end
	local player = Players[playerID];
	local sequence = GetSequence(playerID);
	ProbePlayer(playerID);
	if sequence <= 3 then
		-- Sequence 3's special ability projects are sequence-gated, not
		-- digestion-gated.  Reconcile them once for old saves whose legacy
		-- marker says attached although the actual modifiers were lost.
		local repair = tonumber(player:GetProperty("LOTM_TP_SPECIAL_PROJECT_REPAIR_VERSION") or 0) or 0;
		if repair < 3 then
			local okFaith = pcall(function() player:AttachModifierByID("LOTM_TP_MOD_ALLOW_FAITH_TRANSFER"); end);
			local okCulture = pcall(function() player:AttachModifierByID("LOTM_TP_MOD_ALLOW_CULTURE_TRANSFER"); end);
			player:SetProperty("LOTM_TP_SPECIAL_I_ATTACHED", 1);
			player:SetProperty("LOTM_TP_SPECIAL_PROJECT_REPAIR_VERSION", 3);
			Log("sequence3 special projects reconciled player=" .. tostring(playerID)
				.. " faith=" .. tostring(okFaith) .. " culture=" .. tostring(okCulture));
		end
	end
	if sequence <= 1 then ApplyAllAbilities(playerID); end
	return true;
end

function LOTM_TP_OnPathSelected(playerID)
	if IsThief(playerID) then
		local player = Players[playerID];
		player:SetProperty(P.Target, -1);
		player:SetProperty(P.TargetChangedTurn, -999);
		player:SetProperty(P.FinalBranch, "NONE");
		ProbePlayer(playerID);
		LOTM_TP_RefreshSequenceState(playerID);
	end
end

local function OnSetTarget(playerID, parameters)
	if not IsThief(playerID) then return; end
	local targetID = tonumber(parameters ~= nil and parameters.TargetPlayerID or -1) or -1;
	local player = Players[playerID];
	local turn = Game.GetCurrentGameTurn();
	local changed = tonumber(player:GetProperty(P.TargetChangedTurn) or -999) or -999;
	if not IsLegalTarget(playerID, targetID) or turn - changed < TARGET_COOLDOWN then
		Log("target command rejected player=" .. playerID .. " target=" .. targetID);
		return;
	end
	player:SetProperty(P.Target, targetID);
	player:SetProperty(P.TargetChangedTurn, turn);
	Log("target selected player=" .. playerID .. " target=" .. targetID);
end

local function OnSetBorrowedAbility(playerID, parameters)
	if not IsThief(playerID) or GetSequence(playerID) ~= 2 then return; end
	if tostring(Players[playerID]:GetProperty(P.BorrowedCiv) or "") ~= "" then
		Log("ability choice rejected player=" .. playerID .. " reason=ALREADY_CHOSEN"); return;
	end
	local sourceID = tonumber(parameters ~= nil and parameters.SourcePlayerID or -1) or -1;
	if sourceID < 0 or sourceID == playerID then return; end
	local found = false;
	for _, source in ipairs(PlayerManager.GetWasEverAliveMajors()) do
		if source:GetID() == sourceID then found = true; break; end
	end
	if not found then return; end
	ApplyBorrowedAbility(playerID, GetCivType(sourceID));
end

local function OnChooseFinalBranch(playerID, parameters)
	if not IsThief(playerID) or GetSequence(playerID) ~= 0 then return; end
	local player = Players[playerID];
	if tostring(player:GetProperty(P.FinalBranch) or "NONE") ~= "NONE" then return; end
	local branch = tostring(parameters ~= nil and parameters.Branch or "");
	if branch ~= "TECH_CIVIC" and branch ~= "FAITH" and branch ~= "CULTURE" then return; end
	player:SetProperty(P.FinalBranch, branch);
	if branch == "FAITH" then player:AttachModifierByID("LOTM_TP_MOD_ALLOW_FAITH_TRANSFER_II"); end
	if branch == "CULTURE" then player:AttachModifierByID("LOTM_TP_MOD_ALLOW_CULTURE_TRANSFER_II"); end
	Log("final branch player=" .. playerID .. " branch=" .. branch);
end

-- The native deal remains an ordinary lump-sum Gold payment, so its displayed
-- value and AI valuation stay unchanged. After DiplomacyDealEnacted, this
-- synchronized command substitutes Counterfeit Gold first: refund the payer's
-- matching ordinary Gold and remove the same amount from the recipient. The AI
-- therefore receives no Counterfeit Gold and cannot store or convert it.
local function OnSettleFakeGoldDeal(playerID, parameters)
	if IsNetworkGame() or not IsThief(playerID) or GetSequence(playerID) > 8 then return; end
	local fromID = math.floor(tonumber(parameters ~= nil and parameters.FromPlayerID or -1) or -1);
	local toID = math.floor(tonumber(parameters ~= nil and parameters.ToPlayerID or -1) or -1);
	local amount = math.max(0, math.floor(tonumber(parameters ~= nil and parameters.Amount or 0) or 0));
	local incoming = math.max(0, math.floor(tonumber(parameters ~= nil and parameters.IncomingAmount or 0) or 0));
	local payerGoldBefore = tonumber(parameters ~= nil and parameters.PayerGoldBefore or nil);
	local recipientGoldBefore = tonumber(parameters ~= nil and parameters.RecipientGoldBefore or nil);
	local serial = tostring(parameters ~= nil and parameters.Serial or "");
	if fromID ~= playerID or toID < 0 or toID == fromID or amount <= 0
		or payerGoldBefore == nil or recipientGoldBefore == nil
		or #serial < 1 or #serial > 120 or string.match(serial, "^[%w_:%-]+$") == nil then
		Log("fake gold deal rejected player=" .. tostring(playerID) .. " reason=BAD_REQUEST");
		return;
	end
	local payer, recipient = Players[fromID], Players[toID];
	local payerTreasury = payer ~= nil and payer:GetTreasury() or nil;
	local recipientTreasury = recipient ~= nil and recipient:GetTreasury() or nil;
	if payer == nil or recipient == nil or payerTreasury == nil or recipientTreasury == nil then return; end
	local settledValue = payer:GetProperty(P.LastFakeGoldSettlement);
	if tostring(settledValue or "") == serial then return; end
	local payerGoldAfterDeal = tonumber(payerTreasury:GetGoldBalance()) or payerGoldBefore;
	local recipientGoldAfterDeal = tonumber(recipientTreasury:GetGoldBalance()) or recipientGoldBefore;
	local expectedPayer = payerGoldBefore - amount + incoming;
	local expectedRecipient = recipientGoldBefore + amount - incoming;
	if math.abs(payerGoldAfterDeal - expectedPayer) >= 0.001
		or math.abs(recipientGoldAfterDeal - expectedRecipient) >= 0.001 then
		Log("fake gold deal pending player=" .. tostring(playerID) .. " serial=" .. serial
			.. " reason=NATIVE_GOLD_DELTA_MISMATCH payer=" .. tostring(payerGoldAfterDeal)
			.. "/" .. tostring(expectedPayer) .. " recipient=" .. tostring(recipientGoldAfterDeal)
			.. "/" .. tostring(expectedRecipient));
		return;
	end
	local fakeBefore = GetFakeGold(payer);
	local substitute = math.min(fakeBefore, amount);
	if substitute <= 0 then
		payer:SetProperty(P.LastFakeGoldSettlement, serial);
		return;
	end
	local ok, failure = pcall(function()
		if not ChangeFakeGold(payer, -substitute) then error("FAKE_GOLD_DEBIT_REJECTED"); end
		payerTreasury:ChangeGoldBalance(substitute);
		recipientTreasury:ChangeGoldBalance(-substitute);
		if GetFakeGold(payer) ~= fakeBefore - substitute
			or math.abs((tonumber(payerTreasury:GetGoldBalance()) or 0)
				- (payerGoldAfterDeal + substitute)) >= 0.001
			or math.abs((tonumber(recipientTreasury:GetGoldBalance()) or 0)
				- (recipientGoldAfterDeal - substitute)) >= 0.001 then
			error("SETTLEMENT_DELTA_MISMATCH");
		end
	end);
	if not ok then
		local rollbackOK = true;
		local fakeNow = GetFakeGold(payer);
		if not ChangeFakeGold(payer, fakeBefore - fakeNow) or GetFakeGold(payer) ~= fakeBefore then
			rollbackOK = false;
		end
		local payerNow = tonumber(payerTreasury:GetGoldBalance()) or payerGoldAfterDeal;
		local payerRestoreOK = pcall(function()
			payerTreasury:ChangeGoldBalance(payerGoldAfterDeal - payerNow);
		end);
		if not payerRestoreOK or math.abs((tonumber(payerTreasury:GetGoldBalance()) or payerGoldAfterDeal)
			- payerGoldAfterDeal) >= 0.001 then rollbackOK = false; end
		local recipientNow = tonumber(recipientTreasury:GetGoldBalance()) or recipientGoldAfterDeal;
		local recipientRestoreOK = pcall(function()
			recipientTreasury:ChangeGoldBalance(recipientGoldAfterDeal - recipientNow);
		end);
		if not recipientRestoreOK or math.abs((tonumber(recipientTreasury:GetGoldBalance()) or recipientGoldAfterDeal)
			- recipientGoldAfterDeal) >= 0.001 then rollbackOK = false; end
		if not rollbackOK then
			-- Do not retry a partially restored transaction: repeating it could amplify
			-- an engine-level treasury failure. Preserve the serial and emit a fatal log.
			payer:SetProperty(P.LastFakeGoldSettlement, serial);
		end
		Log("fake gold deal rolled back player=" .. tostring(playerID) .. " serial=" .. serial
			.. " rollbackOK=" .. tostring(rollbackOK) .. " failure=" .. tostring(failure));
		return;
	end
	payer:SetProperty(P.LastFakeGoldSettlement, serial);
	if GetSequence(playerID) == 8 then
		AddDigestion(playerID, "A", "TP:S8:DEAL:" .. serial);
	end
	Log("fake gold deal settled payer=" .. tostring(fromID) .. " recipient=" .. tostring(toID)
		.. " negotiatedGold=" .. tostring(amount) .. " fakeSpent=" .. tostring(substitute)
		.. " trueGoldSpent=" .. tostring(amount - substitute)
		.. " aiGoldReceived=" .. tostring(amount - substitute) .. " serial=" .. serial);
end

local function OnDesignateCity(playerID, parameters)
	if not IsThief(playerID) or GetSequence(playerID) > 4 then return; end
	local player = Players[playerID];
	if player == nil or (player:GetProperty(P.CityTransferSupported) or 0) ~= 1 then
		Log("city designation rejected player=" .. tostring(playerID) .. " reason=LOSSLESS_TRANSFER_GATE_CLOSED");
		return;
	end
	local turn = Game.GetCurrentGameTurn();
	local pendingDue = tonumber(player:GetProperty(P.ParasiteDueTurn) or -1) or -1;
	if pendingDue >= turn then
		Log("city designation rejected player=" .. playerID .. " reason=PARASITE_ALREADY_PENDING");
		return;
	end
	local unitID = math.floor(tonumber(parameters ~= nil and parameters.UnitID or -1) or -1);
	local x = math.floor(tonumber(parameters ~= nil and parameters.X or -1) or -1);
	local y = math.floor(tonumber(parameters ~= nil and parameters.Y or -1) or -1);
	local unit = unitID >= 0 and UnitManager.GetUnit(playerID, unitID) or nil;
	local unitInfo = unit ~= nil and GameInfo.Units[unit:GetType()] or nil;
	if unit == nil or unitInfo == nil or unitInfo.UnitType ~= HERO then
		Log("city designation rejected player=" .. playerID .. " reason=INVALID_HOLDER"); return;
	end
	if unit:GetX() ~= x or unit:GetY() ~= y then x, y = unit:GetX(), unit:GetY(); end
	local plot = Map.GetPlot(x, y);
	local cityOwner = plot ~= nil and tonumber(plot:GetOwner() or -1) or -1;
	local city = plot ~= nil and cityOwner >= 0 and cityOwner ~= playerID
		and Cities.GetPlotPurchaseCity(plot) or nil;
	if city == nil or city:GetOwner() ~= cityOwner then
		Log("city designation rejected player=" .. playerID .. " owner=" .. cityOwner
			.. " reason=NO_OTHER_TERRITORY_CITY"); return;
	end
	player:SetProperty(P.ParasiteOwner, cityOwner);
	player:SetProperty(P.ParasiteCity, city:GetID());
	player:SetProperty(P.ParasiteX, x);
	player:SetProperty(P.ParasiteY, y);
	player:SetProperty(P.ParasiteStartTurn, turn);
	player:SetProperty(P.ParasiteDueTurn, turn + 5);
	Log("parasite designated player=" .. playerID .. " owner=" .. cityOwner
		.. " city=" .. city:GetID() .. " start=" .. turn .. " due=" .. (turn + 5));
end

local function ApplyResearchCompleted(playerID, techIndex, isCanceled, capturedGift)
	if isCanceled or not IsThief(playerID) then return; end
	local player = Players[playerID];
	if capturedGift == true
		or (capturedGift == nil and (player:GetProperty(P.GiftGuardTech) or 0) == 1) then
		player:SetProperty(P.GiftGuardTech, 0);
		player:SetProperty(P.GiftGuardTechIndex, nil);
		return;
	end
	if GetSequence(playerID) ~= 0 or player:GetProperty(P.FinalBranch) ~= "TECH_CIVIC" then return; end
	local count = (player:GetProperty(P.TechNatural) or 0) + 1; player:SetProperty(P.TechNatural, count);
	if (player:GetProperty(P.TechBurst) or 0) == 1 then GiftCurrent(playerID, "TECH");
	elseif count >= 3 then player:SetProperty(P.TechBurst, 1); GiftCurrent(playerID, "TECH"); end
end

local function ApplyCivicCompleted(playerID, civicIndex, isCanceled, capturedGift)
	if isCanceled or not IsThief(playerID) then return; end
	local player = Players[playerID];
	if capturedGift == true
		or (capturedGift == nil and (player:GetProperty(P.GiftGuardCivic) or 0) == 1) then
		player:SetProperty(P.GiftGuardCivic, 0);
		player:SetProperty(P.GiftGuardCivicIndex, nil);
		return;
	end
	if GetSequence(playerID) ~= 0 or player:GetProperty(P.FinalBranch) ~= "TECH_CIVIC" then return; end
	local count = (player:GetProperty(P.CivicNatural) or 0) + 1; player:SetProperty(P.CivicNatural, count);
	if (player:GetProperty(P.CivicBurst) or 0) == 1 then GiftCurrent(playerID, "CIVIC");
	elseif count >= 3 then player:SetProperty(P.CivicBurst, 1); GiftCurrent(playerID, "CIVIC"); end
end

local function ApplyCityProjectCompleted(playerID, cityID, projectID, eventTurn)
	if not IsThief(playerID) then return; end
	local row = GameInfo.Projects[projectID];
	if row == nil then return; end
	local advance = POTIONS[row.ProjectType];
	if advance ~= nil then
		LOTM_RP_State.AdvanceSequence(playerID, advance[1], advance[2], true);
		return;
	end
	-- Project visibility and old queued production do not confer a current
	-- ability. Revalidate both inherited Sequence 3 projects and the mutually
	-- exclusive Sequence 0 branch before applying any completion reward.
	local sequence = GetSequence(playerID);
	local branch = tostring(Players[playerID]:GetProperty(P.FinalBranch) or "NONE");
	if row.ProjectType == "PROJECT_LOTM_TP_FAITH_TRANSFER_II" then
		if sequence ~= 0 or branch ~= "FAITH" then return; end
	elseif row.ProjectType == "PROJECT_LOTM_TP_CULTURE_TRANSFER_II" then
		if sequence ~= 0 or branch ~= "CULTURE" then return; end
	elseif sequence > 3 then
		return;
	end
	if row.ProjectType == "PROJECT_LOTM_TP_FAITH_TRANSFER" then
		if CompleteFaithTransfer(playerID, false) and GetSequence(playerID) == 3 then
			local identityTurn = eventTurn ~= nil and eventTurn or Game.GetCurrentGameTurn();
			AddDigestion(playerID, "A", "TP:S3:FAITH:" .. identityTurn);
			AddDigestion(playerID, "B", "TP:S3:FAITH2:" .. identityTurn);
		end
	elseif row.ProjectType == "PROJECT_LOTM_TP_FAITH_TRANSFER_II" then
		CompleteFaithTransfer(playerID, true);
	elseif row.ProjectType == "PROJECT_LOTM_TP_CULTURE_TRANSFER" then
		local success = ApplyTourismBurst(playerID, "LOTM_TP_TOURISM_BURST_I", 2500);
		if success and GetSequence(playerID) == 3 then
			local identityTurn = eventTurn ~= nil and eventTurn or Game.GetCurrentGameTurn();
			AddDigestion(playerID, "A", "TP:S3:CULTURE:" .. identityTurn);
			AddDigestion(playerID, "B", "TP:S3:CULTURE2:" .. identityTurn);
		end
	elseif row.ProjectType == "PROJECT_LOTM_TP_CULTURE_TRANSFER_II" then
		ApplyTourismBurst(playerID, "LOTM_TP_TOURISM_BURST_II", 9500);
	end
end

local function QueueNetworkEvent(kind, playerID, objectID, cityID, capturedGift)
	local normalizedPlayerID=tonumber(playerID); local normalizedObjectID=tonumber(objectID);
	if normalizedPlayerID==nil or normalizedObjectID==nil then return; end
	local turn=Game.GetCurrentGameTurn(); local normalizedCityID=tonumber(cityID) or -1;
	local key=table.concat({turn,kind,normalizedPlayerID,normalizedObjectID,normalizedCityID,capturedGift==true and 1 or 0},":");
	if pendingNetworkEventKeys[key]~=nil then return; end
	local entry={QueuedTurn=turn,Kind=kind,PlayerID=normalizedPlayerID,ObjectID=normalizedObjectID,
		CityID=normalizedCityID,CapturedGift=capturedGift==true,Key=key};
	pendingNetworkEvents[#pendingNetworkEvents+1]=entry; pendingNetworkEventKeys[key]=entry;
end

local function OnResearchCompleted(playerID,techIndex,isCanceled)
	if not LOTM_MP_TurnSync.IsNetworkGame() then ApplyResearchCompleted(playerID,techIndex,isCanceled,nil); return; end
	if isCanceled or not IsThief(playerID) then return; end
	local player=Players[playerID];
	local guardIndex=player~=nil and tonumber(player:GetProperty(P.GiftGuardTechIndex)) or nil;
	local capturedGift=player~=nil and (player:GetProperty(P.GiftGuardTech) or 0)==1
		and (guardIndex==nil or guardIndex==tonumber(techIndex));
	QueueNetworkEvent("RESEARCH",playerID,techIndex,-1,capturedGift);
end

local function OnCivicCompleted(playerID,civicIndex,isCanceled)
	if not LOTM_MP_TurnSync.IsNetworkGame() then ApplyCivicCompleted(playerID,civicIndex,isCanceled,nil); return; end
	if isCanceled or not IsThief(playerID) then return; end
	local player=Players[playerID];
	local guardIndex=player~=nil and tonumber(player:GetProperty(P.GiftGuardCivicIndex)) or nil;
	local capturedGift=player~=nil and (player:GetProperty(P.GiftGuardCivic) or 0)==1
		and (guardIndex==nil or guardIndex==tonumber(civicIndex));
	QueueNetworkEvent("CIVIC",playerID,civicIndex,-1,capturedGift);
end

local function OnCityProjectCompleted(playerID,cityID,projectID)
	if not LOTM_MP_TurnSync.IsNetworkGame() then ApplyCityProjectCompleted(playerID,cityID,projectID,nil); return; end
	local row=GameInfo.Projects[projectID];
	if not IsThief(playerID) or row==nil or (POTIONS[row.ProjectType]==nil
		and row.ProjectType~="PROJECT_LOTM_TP_FAITH_TRANSFER"
		and row.ProjectType~="PROJECT_LOTM_TP_FAITH_TRANSFER_II"
		and row.ProjectType~="PROJECT_LOTM_TP_CULTURE_TRANSFER"
		and row.ProjectType~="PROJECT_LOTM_TP_CULTURE_TRANSFER_II") then return; end
	QueueNetworkEvent("PROJECT",playerID,projectID,cityID,false);
end

local function ProcessNetworkEvents(playerID)
	if not LOTM_MP_TurnSync.IsNetworkGame() or not LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID) then return; end
	local currentTurn=Game.GetCurrentGameTurn(); local ready={}; local waiting={};
	for _,entry in ipairs(pendingNetworkEvents) do
		if entry.QueuedTurn<currentTurn then ready[#ready+1]=entry; else waiting[#waiting+1]=entry; end
	end
	pendingNetworkEvents=waiting;
	local priority={RESEARCH=1,CIVIC=2,PROJECT=3};
	table.sort(ready,function(a,b)
		if a.QueuedTurn~=b.QueuedTurn then return a.QueuedTurn<b.QueuedTurn; end
		if a.PlayerID~=b.PlayerID then return a.PlayerID<b.PlayerID; end
		if priority[a.Kind]~=priority[b.Kind] then return priority[a.Kind]<priority[b.Kind]; end
		if a.ObjectID~=b.ObjectID then return a.ObjectID<b.ObjectID; end
		return a.CityID<b.CityID;
	end);
	for _,entry in ipairs(ready) do
		if pendingNetworkEventKeys[entry.Key]==entry then pendingNetworkEventKeys[entry.Key]=nil; end
		if entry.Kind=="RESEARCH" then ApplyResearchCompleted(entry.PlayerID,entry.ObjectID,false,entry.CapturedGift);
		elseif entry.Kind=="CIVIC" then ApplyCivicCompleted(entry.PlayerID,entry.ObjectID,false,entry.CapturedGift);
		else ApplyCityProjectCompleted(entry.PlayerID,entry.CityID,entry.ObjectID,entry.QueuedTurn); end
	end
end

local function OnSynchronizedTurn(playerID,first)
	if first==false then return; end
	ProcessNetworkEvents(playerID); ProcessTurn(playerID);
end

local function Initialize()
	if IsRescueMode() then Log("disabled rescue mode"); return; end
	LOTM_MP_TurnSync.Add(OnSynchronizedTurn,"Thief");
	Events.ResearchCompleted.Add(OnResearchCompleted);
	Events.CivicCompleted.Add(OnCivicCompleted);
	Events.CityProjectCompleted.Add(OnCityProjectCompleted);
	GameEvents.LOTM_TP_Command_SetTarget.Add(OnSetTarget);
	GameEvents.LOTM_TP_Command_SetBorrowedAbility.Add(OnSetBorrowedAbility);
	GameEvents.LOTM_TP_Command_ChooseFinalBranch.Add(OnChooseFinalBranch);
	GameEvents.LOTM_TP_Command_SettleProduction.Add(OnSettleProduction);
	GameEvents.LOTM_TP_Command_SettleFakeGoldDeal.Add(OnSettleFakeGoldDeal);
	GameEvents.LOTM_TP_Command_DesignateCity.Add(OnDesignateCity);
	local function RefreshThiefStartup()
		local playerIDs={};
		local thiefFound = false;
		for _, playerID in ipairs(PlayerManager.GetAliveMajorIDs() or {}) do playerIDs[#playerIDs+1]=playerID; end
		table.sort(playerIDs);
		for _, playerID in ipairs(playerIDs) do
			ClearLegacyTradeCarrier(playerID);
			if IsThief(playerID) then
				thiefFound = true;
				ProbePlayer(playerID);
				-- Use the shared lifecycle refresh on load so old saves restore
				-- both pathway abilities and any unlocked city project modifier.
				LOTM_RP_State.RefreshSequenceState(playerID);
			end
		end
		Log("startup refresh complete players=" .. tostring(#playerIDs)
			.. " thiefFound=" .. tostring(thiefFound));
		return thiefFound;
	end
	-- Restored Properties must be read at a Gameplay turn boundary. A new game
	-- without a selected Thief is a successful startup, not a retry condition.
	-- Never migrate/refresh from the high-frequency local core-publish event.
	if LOTM_MP_TurnSync.IsNetworkGame() then
		LOTM_MP_TurnSync.RunStartup(RefreshThiefStartup,"Thief");
	else
		local startupDone = false;
		LOTM_MP_TurnSync.AddSynchronized(function(playerID, first)
			if startupDone or first == false or Players[playerID] == nil then return; end
			local ids = PlayerManager.GetAliveMajorIDs() or {};
			if #ids == 0 then return; end
			for _, id in ipairs(ids) do if Players[id] == nil then return; end end
			-- Close the gate before mutating state, including callbacks from native APIs.
			startupDone = true;
			RefreshThiefStartup();
			Log("startup refresh committed source=SYNCHRONIZED_PLAYER_TURN_STARTED");
		end,"ThiefLoad");
	end
	Log("initialized probeVersion=" .. PROBE_VERSION);
end

Initialize();
