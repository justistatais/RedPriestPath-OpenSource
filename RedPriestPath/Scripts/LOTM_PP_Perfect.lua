-- Perfect Path Sequence 9 through Sequence 0.
-- Gameplay owns every mutation; UI only reads the synchronized properties.

local LOTM_PP_PATH :string = "PATH_PERFECT";
local LOTM_PP_RELIC_INTERVAL :number = 5;
local LOTM_PP_RELIC_LIMIT :number = 5;
local SCIENTIST_LEDGER_VERSION :number = 1;
local SCIENTIST_LEDGER_VERSION_KEY :string = "LOTM_PP_SCIENTIST_RECRUIT_LEDGER_VERSION";
local SCIENTIST_LEDGER_PREFIX :string = "LOTM_PP_SCIENTIST_RECRUITED_UNIT_";
local pendingNetworkScientistUnits :table = {};
local pendingNetworkScientistKeys :table = {};
local pendingNetworkGameplayEvents :table = {};
local pendingNetworkGameplayEventKeys :table = {};

local NETWORK_GAMEPLAY_EVENT_ORDER :table = {
	TECH_BOOST = 10,
	CIVIC_BOOST = 20,
	GOODY_HUT = 30,
	UNIT_MOVE = 40,
	UNIT_CHARGES = 50,
	IMPROVEMENT = 60,
	DISTRICT = 70,
	RESEARCH = 80,
	CIVIC = 90,
	GREAT_WORK = 100,
	-- A project may advance the sequence and attach its next set of modifiers.
	-- Keep it after every digestion fact captured in the same world turn.
	CITY_PROJECT = 1000,
};

local LOTM_PP_PROJECT_ADVANCES :table = {
	PROJECT_LOTM_PP_ARCHAEOLOGIST_POTION = { 9, 8 },
	PROJECT_LOTM_PP_APPRAISER_POTION = { 8, 7 },
	PROJECT_LOTM_PP_MECHANICAL_EXPERT_POTION = { 7, 6 },
	PROJECT_LOTM_PP_ASTRONOMER_POTION = { 6, 5 },
	PROJECT_LOTM_PP_ALCHEMIST_POTION = { 5, 4 },
	PROJECT_LOTM_PP_MYSTERY_SCHOLAR_POTION = { 4, 3 },
	PROJECT_LOTM_PP_KNOWLEDGE_MENTOR_POTION = { 3, 2 },
	PROJECT_LOTM_PP_ENLIGHTENER_POTION = { 2, 1 },
	PROJECT_LOTM_PP_CIVILIZATION_ASCENSION = { 1, 0 },
	PROJECT_LOTM_PP_CIVILIZATION_ASCENSION_UNCONSECRATED = {
		1, 0, allowWithoutChurch = true
	},
};

local LOTM_PP_BASE_YIELDS :table = {
	YIELD_FOOD = true,
	YIELD_PRODUCTION = true,
	YIELD_GOLD = true,
	YIELD_SCIENCE = true,
	YIELD_CULTURE = true,
	YIELD_FAITH = true,
};

local LOTM_PP_SEQUENCE_MODIFIERS :table = {
	[9] = {
		{ "LOTM_PP_MOD_GENERALIST_TECH_BOOST", "LOTM_PP_GENERALIST_TECH_ATTACHED" },
		{ "LOTM_PP_MOD_GENERALIST_CIVIC_BOOST", "LOTM_PP_GENERALIST_CIVIC_ATTACHED" },
	},
	[8] = {
		{ "LOTM_PP_MOD_PALACE_RELIC_SLOTS", "LOTM_PP_RELIC_SLOTS_ATTACHED" },
	},
	[6] = {
		{ "LOTM_PP_MOD_MECHANICAL_IMPROVED_PLOT_PRODUCTION",
			"LOTM_PP_MECHANICAL_PLOTS_ATTACHED" },
	},
	[5] = {
		{ "LOTM_PP_MOD_ASTRONOMER_CAMPUS_YIELD",
			"LOTM_PP_ASTRONOMER_CAMPUS_ATTACHED" },
		{ "LOTM_PP_MOD_ASTRONOMER_CAMPUS_BUILDINGS",
			"LOTM_PP_ASTRONOMER_BUILDINGS_ATTACHED" },
		{ "LOTM_PP_MOD_ASTRONOMER_SPACE_PROJECTS",
			"LOTM_PP_ASTRONOMER_SPACE_ATTACHED" },
	},
	[4] = {
		{ "LOTM_PP_MOD_ALCHEMIST_BUILDER_CHARGES_V2",
			"LOTM_PP_ALCHEMIST_CHARGES_V2_ATTACHED" },
		{ "LOTM_PP_MOD_ALCHEMIST_CITY_PRODUCTION",
			"LOTM_PP_ALCHEMIST_PRODUCTION_ATTACHED" },
	},
	[1] = {
		{ "LOTM_PP_MOD_ENLIGHTENER_SCIENCE",
			"LOTM_PP_ENLIGHTENER_SCIENCE_ATTACHED" },
		{ "LOTM_PP_MOD_ENLIGHTENER_CULTURE",
			"LOTM_PP_ENLIGHTENER_CULTURE_ATTACHED" },
	},
	[0] = {
		{ "LOTM_PP_MOD_PERFECT_FOOD", "LOTM_PP_PERFECT_FOOD_ATTACHED" },
		{ "LOTM_PP_MOD_PERFECT_PRODUCTION", "LOTM_PP_PERFECT_PRODUCTION_ATTACHED" },
		{ "LOTM_PP_MOD_PERFECT_GOLD", "LOTM_PP_PERFECT_GOLD_ATTACHED" },
		{ "LOTM_PP_MOD_PERFECT_SCIENCE", "LOTM_PP_PERFECT_SCIENCE_ATTACHED" },
		{ "LOTM_PP_MOD_PERFECT_CULTURE", "LOTM_PP_PERFECT_CULTURE_ATTACHED" },
		{ "LOTM_PP_MOD_PERFECT_FAITH", "LOTM_PP_PERFECT_FAITH_ATTACHED" },
	},
};

local function Log(message :string)
	print("[LOTM_PP][Perfect] " .. message);
end

local function GetPlayer(playerID :number)
	return playerID ~= nil and Players[playerID] or nil;
end

local function IsPerfect(playerID :number)
	return LOTM_RP_State ~= nil
		and LOTM_RP_State.IsPerfectPlayer(playerID)
		and LOTM_RP_State.GetPath(playerID) == LOTM_PP_PATH;
end

local function GetSequence(playerID :number)
	return LOTM_RP_State.GetSequence(playerID);
end

local function RepairLegacyAlchemistCharges(playerID :number)
	local player = GetPlayer(playerID);
	if player == nil
		or (player:GetProperty("LOTM_PP_ALCHEMIST_CHARGES_ATTACHED") or 0) ~= 1
		or (player:GetProperty("LOTM_PP_ALCHEMIST_CHARGES_LEGACY_COMPENSATED") or 0) == 1 then
		return;
	end
	player:AttachModifierByID(
		"LOTM_PP_MOD_ALCHEMIST_BUILDER_CHARGES_LEGACY_COMPENSATION"
	);
	player:SetProperty("LOTM_PP_ALCHEMIST_CHARGES_LEGACY_COMPENSATED", 1);
	Log("player=" .. tostring(playerID)
		.. " compensated legacy unrestricted Alchemist builder charges");
end

local function AttachSequenceModifiers(playerID :number, sequence :number)
	for unlockSequence = 9, 0, -1 do
		if sequence <= unlockSequence then
			for _, entry in ipairs(LOTM_PP_SEQUENCE_MODIFIERS[unlockSequence] or {}) do
				LOTM_RP_State.AttachModifierOnce(playerID, entry[1], entry[2]);
			end
		end
	end
end

local function IsSpecialtyDistrict(district)
	return district ~= nil
		and (district.RequiresPopulation == true or district.RequiresPopulation == 1);
end

local function AttachMysterySystem(playerID :number)
	local player = GetPlayer(playerID);
	if player == nil
		or (player:GetProperty("LOTM_PP_MYSTERY_SYSTEM_ATTACHED") or 0) == 1 then
		return;
	end
	local attached = 0;
	for district in GameInfo.Districts() do
		if IsSpecialtyDistrict(district) then
			for yieldInfo in GameInfo.Yields() do
				if LOTM_PP_BASE_YIELDS[yieldInfo.YieldType] then
					player:AttachModifierByID(
						"LOTM_PP_MOD_MYSTERY_DISTRICT_"
							.. district.DistrictType .. "_" .. yieldInfo.YieldType
					);
					player:AttachModifierByID(
						"LOTM_PP_MOD_MYSTERY_BUILDING_"
							.. district.DistrictType .. "_" .. yieldInfo.YieldType
					);
					attached = attached + 2;
				end
			end
		end
	end
	player:SetProperty("LOTM_PP_MYSTERY_SYSTEM_ATTACHED", 1);
	Log("player=" .. tostring(playerID)
		.. " attached mystery-system modifiers=" .. tostring(attached));
end

local function ApplyKnowledgeTeaching(playerID :number)
	local player = GetPlayer(playerID);
	if player == nil then
		return;
	end
	local technologies = player:GetTechs();
	for technology in GameInfo.Technologies() do
		if not technologies:HasTech(technology.Index)
			and not technologies:HasBoostBeenTriggered(technology.Index) then
			technologies:TriggerBoost(technology.Index, 1);
		end
	end
	local culture = player:GetCulture();
	for civic in GameInfo.Civics() do
		if not culture:HasCivic(civic.Index)
			and not culture:HasBoostBeenTriggered(civic.Index) then
			culture:TriggerBoost(civic.Index, 1);
		end
	end
end

local function GrantEnlightenerScientistPoints(playerID :number)
	local player = GetPlayer(playerID);
	if player == nil
		or (player:GetProperty("LOTM_PP_ENLIGHTENER_POINTS_GRANTED") or 0) == 1 then
		return;
	end
	local scientistClass = GameInfo.GreatPersonClasses[
		"GREAT_PERSON_CLASS_SCIENTIST"
	];
	local points = player:GetGreatPeoplePoints();
	if scientistClass == nil or points == nil then
		Log("ERROR unable to grant Enlightener Great Scientist points player="
			.. tostring(playerID));
		return;
	end
	points:ChangePointsTotal(scientistClass.Index, 99999);
	player:SetProperty("LOTM_PP_ENLIGHTENER_POINTS_GRANTED", 1);
	Log("player=" .. tostring(playerID)
		.. " granted Enlightener Great Scientist points=99999");
end

local function AttachAppraiserModifiers(playerID :number)
	local player = GetPlayer(playerID);
	if player == nil or (player:GetProperty("LOTM_PP_APPRAISER_ATTACHED") or 0) == 1 then
		return;
	end
	local attached = 0;
	local seen :table = {};
	for yieldChange in GameInfo.GreatWork_YieldChanges() do
		local greatWork = GameInfo.GreatWorks[yieldChange.GreatWorkType];
		if greatWork ~= nil then
			local modifierID = "LOTM_PP_MOD_GREATWORK_"
				.. greatWork.GreatWorkObjectType .. "_" .. yieldChange.YieldType;
			if not seen[modifierID] then
				player:AttachModifierByID(modifierID);
				seen[modifierID] = true;
				attached = attached + 1;
			end
		end
	end
	player:SetProperty("LOTM_PP_APPRAISER_ATTACHED", 1);
	Log("player=" .. tostring(playerID)
		.. " attached appraiser great-work modifiers=" .. tostring(attached));
end

local function GrantNextRelic(playerID :number)
	local player = GetPlayer(playerID);
	if player == nil then
		return false;
	end
	local count = player:GetProperty("LOTM_PP_RELIC_COUNT") or 0;
	if count >= LOTM_PP_RELIC_LIMIT then
		return false;
	end
	local nextCount = count + 1;
	LOTM_RP_State.AttachModifierOnce(
		playerID,
		"LOTM_PP_MOD_GRANT_RELIC_V3_" .. tostring(nextCount),
		"LOTM_PP_RELIC_GRANT_V3_" .. tostring(nextCount)
	);
	player:SetProperty("LOTM_PP_RELIC_COUNT", nextCount);
	player:SetProperty(
		"LOTM_PP_NEXT_RELIC_TURN",
		nextCount < LOTM_PP_RELIC_LIMIT
			and Game.GetCurrentGameTurn() + LOTM_PP_RELIC_INTERVAL
			or -1
	);
	-- The relic ability is inherited, but its digestion task belongs only to
	-- the Archaeologist.  Later sequences keep their own event-based tasks.
	if GetSequence(playerID) == 8 then
		LOTM_RP_State.TryAddDigestion(
			playerID,
			"A",
			"PERFECT_RELIC:" .. tostring(nextCount)
		);
	end
	Log("player=" .. tostring(playerID)
		.. " granted path relic " .. tostring(nextCount)
		.. "/" .. tostring(LOTM_PP_RELIC_LIMIT));
	return true;
end

local function RepairRecordedRelicGrants(playerID :number, player)
	local count = math.min(
		LOTM_PP_RELIC_LIMIT,
		math.max(0, player:GetProperty("LOTM_PP_RELIC_COUNT") or 0)
	);
	for grantIndex = 1, count do
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			"LOTM_PP_MOD_GRANT_RELIC_V3_" .. tostring(grantIndex),
			"LOTM_PP_RELIC_GRANT_V3_" .. tostring(grantIndex)
		);
	end
end

local function ProcessRelics(playerID :number, allowTurnGrant :boolean)
	if GetSequence(playerID) > 8 then
		return;
	end
	local player = GetPlayer(playerID);
	if player == nil then
		return;
	end
	-- rc.26/27 recorded relic counters although their effects respectively
	-- lacked RunOnce or Amount. Attach corrected V3 grants for every recorded
	-- item; per-index properties make this save-safe.
	RepairRecordedRelicGrants(playerID, player);
	if (player:GetProperty("LOTM_PP_RELIC_STARTED") or 0) ~= 1 then
		player:SetProperty("LOTM_PP_RELIC_STARTED", 1);
		player:SetProperty("LOTM_PP_RELIC_COUNT", 0);
		player:SetProperty("LOTM_PP_NEXT_RELIC_TURN", Game.GetCurrentGameTurn());
		-- Continents already occupied when Sequence 8 begins are historical
		-- knowledge, not a new-continent discovery.
		for _, city in player:GetCities():Members() do
			local cityPlot = Map.GetPlot(city:GetX(), city:GetY());
			local continent = cityPlot ~= nil and cityPlot:GetContinentType() or -1;
			if continent >= 0 then
				player:SetProperty(
					"LOTM_PP_CONTINENT_SEEN_" .. tostring(continent),
					1
				);
			end
		end
		GrantNextRelic(playerID);
		return;
	end
	local nextTurn = player:GetProperty("LOTM_PP_NEXT_RELIC_TURN") or -1;
	if allowTurnGrant and nextTurn >= 0 and Game.GetCurrentGameTurn() >= nextTurn then
		GrantNextRelic(playerID);
	end
end

function LOTM_PP_RefreshSequenceState(playerID :number)
	if not IsPerfect(playerID) then
		return false;
	end
	local sequence = GetSequence(playerID);
	RepairLegacyAlchemistCharges(playerID);
	AttachSequenceModifiers(playerID, sequence);
	if sequence <= 3 then
		AttachMysterySystem(playerID);
	end
	if sequence <= 2 then
		ApplyKnowledgeTeaching(playerID);
	end
	if sequence <= 1 then
		GrantEnlightenerScientistPoints(playerID);
	end
	if sequence <= 7 then
		AttachAppraiserModifiers(playerID);
	end
	return true;
end

local function StableNetworkValue(value)
	if value == nil then return "nil"; end
	local valueType = type(value);
	if valueType == "boolean" then
		return value and "boolean:1" or "boolean:0";
	end
	return valueType .. ":" .. tostring(value);
end

local function QueueNetworkGameplayEvent(
	kind,
	playerID,
	payload,
	...
)
	local order = NETWORK_GAMEPLAY_EVENT_ORDER[kind];
	local normalizedPlayerID = tonumber(playerID);
	if order == nil or normalizedPlayerID == nil then return; end
	local queuedTurn = Game.GetCurrentGameTurn();
	local keyParts :table = {
		tostring(queuedTurn),
		kind,
		tostring(normalizedPlayerID),
	};
	local valueCount = select("#", ...);
	for index = 1, valueCount do
		keyParts[#keyParts + 1] = StableNetworkValue(select(index, ...));
	end
	local sortKey = table.concat(keyParts, "|");
	local existing = pendingNetworkGameplayEventKeys[sortKey];
	if existing ~= nil then
		existing.Count = existing.Count + 1;
		return;
	end
	local entry = {
		Kind = kind,
		Order = order,
		PlayerID = normalizedPlayerID,
		Payload = payload,
		QueuedTurn = queuedTurn,
		SortKey = sortKey,
		Count = 1,
	};
	pendingNetworkGameplayEvents[#pendingNetworkGameplayEvents + 1] = entry;
	pendingNetworkGameplayEventKeys[sortKey] = entry;
end

local function NetworkGameplayEventLess(left, right)
	if left.QueuedTurn ~= right.QueuedTurn then
		return left.QueuedTurn < right.QueuedTurn;
	end
	if left.Order ~= right.Order then return left.Order < right.Order; end
	if left.PlayerID ~= right.PlayerID then return left.PlayerID < right.PlayerID; end
	return left.SortKey < right.SortKey;
end

local function ApplyGreatWorkCreated(
	playerID :number,
	unitID :number,
	cityX :number,
	cityY :number,
	buildingID :number,
	greatWorkID :number
)
	if not IsPerfect(playerID) or GetSequence(playerID) ~= 7 then
		return;
	end
	local workKey = tostring(greatWorkID)
		.. ":" .. tostring(cityX) .. ":" .. tostring(cityY)
		.. ":" .. tostring(buildingID);
	LOTM_RP_State.TryAddDigestion(
		playerID, "A", "GREAT_WORK_ACQUIRED:" .. workKey
	);
	LOTM_RP_State.TryAddDigestion(
		playerID, "B", "GREAT_WORK_PLACED:" .. workKey
	);
end

local function OnGreatWorkCreated(
	playerID :number,
	unitID :number,
	cityX :number,
	cityY :number,
	buildingID :number,
	greatWorkID :number
)
	if LOTM_MP_TurnSync.IsNetworkGame() then
		if IsPerfect(playerID) and GetSequence(playerID) == 7 then
			QueueNetworkGameplayEvent(
				"GREAT_WORK",
				playerID,
				{
					UnitID = unitID,
					CityX = cityX,
					CityY = cityY,
					BuildingID = buildingID,
					GreatWorkID = greatWorkID,
				},
				unitID, cityX, cityY, buildingID, greatWorkID
			);
		end
		return;
	end
	ApplyGreatWorkCreated(playerID, unitID, cityX, cityY, buildingID, greatWorkID);
end

local function NextEventSerial(player, property :string)
	local serial = (player:GetProperty(property) or 0) + 1;
	player:SetProperty(property, serial);
	return serial;
end

local function IsGreatScientist(unit)
	local unitInfo = unit ~= nil and GameInfo.Units[unit:GetType()] or nil;
	return unitInfo ~= nil and unitInfo.UnitType == "UNIT_GREAT_SCIENTIST";
end

local function ScientistLedgerKey(unitID)
	return SCIENTIST_LEDGER_PREFIX .. tostring(unitID);
end

local function MarkExistingScientists(playerID)
	local player = GetPlayer(playerID);
	if player == nil then return; end
	local units :table = {};
	for _, unit in player:GetUnits():Members() do units[#units + 1] = unit; end
	table.sort(units, function(a,b) return a:GetID() < b:GetID(); end);
	for _, unit in ipairs(units) do
		if IsGreatScientist(unit) then
			local key = ScientistLedgerKey(unit:GetID());
			if player:GetProperty(key) ~= 1 then player:SetProperty(key, 1); end
		end
	end
end

local function CommitScientistRecruitment(playerID, unitID)
	local player = GetPlayer(playerID);
	if player == nil then return; end
	local ledgerKey = ScientistLedgerKey(unitID);
	if player:GetProperty(ledgerKey) == 1 then return; end
	-- Commit the per-unit ledger before creating the digestion event.  A save/load
	-- replay can therefore never award this recruit twice, even if the old
	-- serial-based event key differs after a reconnect.
	player:SetProperty(ledgerKey, 1);
	LOTM_RP_State.TryAddDigestion(
		playerID,
		"A",
		"GREAT_SCIENTIST_RECRUITED:"
			.. tostring(NextEventSerial(player, "LOTM_PP_SCIENTIST_RECRUIT_SERIAL"))
	);
end

local function ProcessScientistRecruitment(playerID, unitID)
	if not IsPerfect(playerID) or GetSequence(playerID) ~= 1 then return; end
	local player = GetPlayer(playerID);
	local unit = player ~= nil and player:GetUnits():FindID(unitID) or nil;
	if player == nil or not IsGreatScientist(unit) then return; end
	CommitScientistRecruitment(playerID, unitID);
end

local function QueueNetworkScientistUnit(playerID, unitID)
	local normalizedPlayerID = tonumber(playerID);
	local normalizedUnitID = tonumber(unitID);
	if normalizedPlayerID == nil or normalizedUnitID == nil then return; end
	local player = GetPlayer(normalizedPlayerID);
	local unit = player ~= nil and player:GetUnits():FindID(normalizedUnitID) or nil;
	-- Capture event-time eligibility while the Great Person still exists.  The
	-- callback remains read-only; the scientist may be activated and removed
	-- before the next stable world-turn boundary.
	if not IsPerfect(normalizedPlayerID) or GetSequence(normalizedPlayerID) ~= 1
		or not IsGreatScientist(unit) then return; end
	local key = tostring(normalizedPlayerID) .. ":" .. tostring(normalizedUnitID);
	if pendingNetworkScientistKeys[key] ~= nil then return; end
	local entry = {
		PlayerID = normalizedPlayerID,
		UnitID = normalizedUnitID,
		QueuedTurn = Game.GetCurrentGameTurn(),
		Key = key,
	};
	pendingNetworkScientistUnits[#pendingNetworkScientistUnits + 1] = entry;
	pendingNetworkScientistKeys[key] = entry;
end

local function ProcessNetworkScientistUnits(playerID)
	if not LOTM_MP_TurnSync.IsNetworkGame()
		or not LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID) then return; end
	local currentTurn = Game.GetCurrentGameTurn();
	local ready :table = {};
	local waiting :table = {};
	for _, entry in ipairs(pendingNetworkScientistUnits) do
		if entry.Cancelled == true then
			if pendingNetworkScientistKeys[entry.Key] == entry then pendingNetworkScientistKeys[entry.Key] = nil; end
		elseif entry.QueuedTurn < currentTurn then
			ready[#ready + 1] = entry;
		else
			waiting[#waiting + 1] = entry;
		end
	end
	pendingNetworkScientistUnits = waiting;
	table.sort(ready, function(a,b)
		if a.PlayerID ~= b.PlayerID then return a.PlayerID < b.PlayerID; end
		return a.UnitID < b.UnitID;
	end);
	for _, entry in ipairs(ready) do
		if pendingNetworkScientistKeys[entry.Key] == entry then pendingNetworkScientistKeys[entry.Key] = nil; end
		CommitScientistRecruitment(entry.PlayerID, entry.UnitID);
	end
end

local function ApplyTechBoostTriggered(playerID :number)
	if not IsPerfect(playerID) or GetSequence(playerID) ~= 9 then
		return;
	end
	local player = GetPlayer(playerID);
	LOTM_RP_State.TryAddDigestion(
		playerID,
		"A",
		"TECH_BOOST:" .. tostring(NextEventSerial(player, "LOTM_PP_TECH_BOOST_SERIAL"))
	);
end

local function OnTechBoostTriggered(playerID :number, techIndex :number)
	if LOTM_MP_TurnSync.IsNetworkGame() then
		if IsPerfect(playerID) and GetSequence(playerID) == 9 then
			QueueNetworkGameplayEvent(
				"TECH_BOOST", playerID, { TechIndex = techIndex }, techIndex
			);
		end
		return;
	end
	ApplyTechBoostTriggered(playerID);
end

local function ApplyCivicBoostTriggered(playerID :number)
	if not IsPerfect(playerID) or GetSequence(playerID) ~= 9 then
		return;
	end
	local player = GetPlayer(playerID);
	LOTM_RP_State.TryAddDigestion(
		playerID,
		"B",
		"CIVIC_BOOST:" .. tostring(NextEventSerial(player, "LOTM_PP_CIVIC_BOOST_SERIAL"))
	);
end

local function OnCivicBoostTriggered(playerID :number, civicIndex :number)
	if LOTM_MP_TurnSync.IsNetworkGame() then
		if IsPerfect(playerID) and GetSequence(playerID) == 9 then
			QueueNetworkGameplayEvent(
				"CIVIC_BOOST", playerID, { CivicIndex = civicIndex }, civicIndex
			);
		end
		return;
	end
	ApplyCivicBoostTriggered(playerID);
end

local function ApplyGoodyHutReward(
	playerID :number,
	unitID :number,
	rewardType :number,
	rewardSubType :number
)
	if IsPerfect(playerID) and GetSequence(playerID) == 8 then
		local player = GetPlayer(playerID);
		LOTM_RP_State.TryAddDigestion(
			playerID,
			"B",
			"GOODY_HUT:"
				.. tostring(NextEventSerial(player, "LOTM_PP_GOODY_HUT_SERIAL"))
		);
	end
end

local function OnGoodyHutReward(
	playerID :number,
	unitID :number,
	rewardType :number,
	rewardSubType :number
)
	if LOTM_MP_TurnSync.IsNetworkGame() then
		if IsPerfect(playerID) and GetSequence(playerID) == 8 then
			QueueNetworkGameplayEvent(
				"GOODY_HUT",
				playerID,
				{
					UnitID = unitID,
					RewardType = rewardType,
					RewardSubType = rewardSubType,
				},
				unitID, rewardType, rewardSubType
			);
		end
		return;
	end
	ApplyGoodyHutReward(playerID, unitID, rewardType, rewardSubType);
end

local function ApplyUnitMoveComplete(
	playerID :number,
	unitID :number,
	x :number,
	y :number
)
	if not IsPerfect(playerID) or GetSequence(playerID) ~= 8 then
		return;
	end
	local player = GetPlayer(playerID);
	local plot = Map.GetPlot(x, y);
	if player == nil or plot == nil then
		return;
	end
	local continent = plot:GetContinentType();
	if continent ~= nil and continent >= 0
		and (player:GetProperty("LOTM_PP_CONTINENT_SEEN_" .. tostring(continent)) or 0) ~= 1 then
		player:SetProperty("LOTM_PP_CONTINENT_SEEN_" .. tostring(continent), 1);
		LOTM_RP_State.TryAddDigestion(
			playerID, "B", "CONTINENT:" .. tostring(continent)
		);
	end
	local feature = GameInfo.Features[plot:GetFeatureType()];
	if feature ~= nil and feature.NaturalWonder
		and (player:GetProperty("LOTM_PP_WONDER_SEEN_" .. feature.FeatureType) or 0) ~= 1 then
		player:SetProperty("LOTM_PP_WONDER_SEEN_" .. feature.FeatureType, 1);
		LOTM_RP_State.TryAddDigestion(
			playerID, "B", "NATURAL_WONDER:" .. feature.FeatureType
		);
	end
end

local function OnUnitMoveComplete(
	playerID :number,
	unitID :number,
	x :number,
	y :number
)
	if LOTM_MP_TurnSync.IsNetworkGame() then
		if IsPerfect(playerID) and GetSequence(playerID) == 8 then
			QueueNetworkGameplayEvent(
				"UNIT_MOVE",
				playerID,
				{ UnitID = unitID, X = x, Y = y },
				unitID, x, y
			);
		end
		return;
	end
	ApplyUnitMoveComplete(playerID, unitID, x, y);
end

local function ApplyUnitChargesChanged(
	playerID :number,
	unitID :number,
	newCharges :number,
	oldCharges :number,
	capturedUnitType :number
)
	if not IsPerfect(playerID)
		or (GetSequence(playerID) ~= 6 and GetSequence(playerID) ~= 4)
		or newCharges == nil or oldCharges == nil
		or newCharges >= oldCharges then
		return;
	end
	local player = GetPlayer(playerID);
	local builder = GameInfo.Units["UNIT_BUILDER"];
	local unit = capturedUnitType == nil and player ~= nil
		and player:GetUnits():FindID(unitID) or nil;
	local unitType = capturedUnitType ~= nil and capturedUnitType
		or (unit ~= nil and unit:GetType() or nil);
	if player == nil or builder == nil or unitType ~= builder.Index then
		return;
	end
	local serial = NextEventSerial(player, "LOTM_PP_BUILDER_CHARGE_SERIAL");
	LOTM_RP_State.TryAddDigestion(
		playerID, "A", "BUILDER_CHARGE:" .. tostring(serial)
	);
end

local function OnUnitChargesChanged(
	playerID :number,
	unitID :number,
	newCharges :number,
	oldCharges :number
)
	if LOTM_MP_TurnSync.IsNetworkGame() then
		if IsPerfect(playerID)
			and (GetSequence(playerID) == 6 or GetSequence(playerID) == 4)
			and newCharges ~= nil and oldCharges ~= nil
			and newCharges < oldCharges then
			local player = GetPlayer(playerID);
			local unit = player ~= nil and player:GetUnits():FindID(unitID) or nil;
			local unitType = unit ~= nil and unit:GetType() or nil;
			local builder = GameInfo.Units["UNIT_BUILDER"];
			if builder ~= nil and unitType == builder.Index then
				QueueNetworkGameplayEvent(
					"UNIT_CHARGES",
					playerID,
					{
						UnitID = unitID,
						NewCharges = newCharges,
						OldCharges = oldCharges,
						UnitType = unitType,
					},
					unitID, newCharges, oldCharges, unitType
				);
			end
		end
		return;
	end
	ApplyUnitChargesChanged(playerID, unitID, newCharges, oldCharges, nil);
end

local function ApplyImprovementAddedToMap(
	x :number,
	y :number,
	improvementType :number,
	ownerID :number,
	eventTurn :number
)
	if IsPerfect(ownerID) and GetSequence(ownerID) == 6 then
		LOTM_RP_State.TryAddDigestion(
			ownerID,
			"B",
			"IMPROVEMENT:" .. tostring(x) .. ":" .. tostring(y)
				.. ":" .. tostring(eventTurn ~= nil
					and eventTurn or Game.GetCurrentGameTurn())
		);
	end
end

local function OnImprovementAddedToMap(
	x :number,
	y :number,
	improvementType :number,
	ownerID :number
)
	if LOTM_MP_TurnSync.IsNetworkGame() then
		if IsPerfect(ownerID) and GetSequence(ownerID) == 6 then
			QueueNetworkGameplayEvent(
				"IMPROVEMENT",
				ownerID,
				{ X = x, Y = y, ImprovementType = improvementType },
				x, y, improvementType
			);
		end
		return;
	end
	ApplyImprovementAddedToMap(x, y, improvementType, ownerID, nil);
end

local function IsCampusBuilding(buildingIndex :number)
	local building = GameInfo.Buildings[buildingIndex];
	return building ~= nil and building.PrereqDistrict == "DISTRICT_CAMPUS";
end

local function IsSpecialtyBuilding(buildingIndex :number)
	local building = GameInfo.Buildings[buildingIndex];
	local district = building ~= nil
		and GameInfo.Districts[building.PrereqDistrict] or nil;
	return IsSpecialtyDistrict(district);
end

-- GameEvents.BuildingConstructed is a synchronized Gameplay event, unlike the
-- client-local Events publications routed through the fact queue below.
local function OnBuildingConstructed(
	playerID :number,
	cityID :number,
	buildingIndex :number,
	plotIndex :number,
	isOriginalConstruction :boolean
)
	if not IsPerfect(playerID) or not isOriginalConstruction then
		return;
	end
	local sequence = GetSequence(playerID);
	if sequence == 5 and IsCampusBuilding(buildingIndex) then
		LOTM_RP_State.TryAddDigestion(
			playerID, "B", "CAMPUS_BUILDING:" .. tostring(cityID)
				.. ":" .. tostring(buildingIndex)
		);
	elseif sequence == 4 then
		LOTM_RP_State.TryAddDigestion(
			playerID, "B", "BUILDING:" .. tostring(cityID)
				.. ":" .. tostring(buildingIndex)
		);
	elseif sequence == 3 and IsSpecialtyBuilding(buildingIndex) then
		LOTM_RP_State.TryAddDigestion(
			playerID, "B", "SPECIALTY_BUILDING:" .. tostring(cityID)
				.. ":" .. tostring(buildingIndex)
		);
	end
end

local function ApplyDistrictAddedToMap(
	playerID :number,
	districtID :number,
	cityID :number,
	x :number,
	y :number,
	districtType :number,
	percentComplete :number
)
	if not IsPerfect(playerID) or percentComplete == nil or percentComplete < 100 then
		return;
	end
	local sequence = GetSequence(playerID);
	local district = GameInfo.Districts[districtType];
	if sequence == 5
		and district ~= nil
		and district.DistrictType == "DISTRICT_CAMPUS" then
		LOTM_RP_State.TryAddDigestion(
			playerID, "B", "CAMPUS_DISTRICT:" .. tostring(cityID)
				.. ":" .. tostring(districtID)
		);
	elseif sequence == 4 then
		LOTM_RP_State.TryAddDigestion(
			playerID, "B", "DISTRICT:" .. tostring(cityID)
				.. ":" .. tostring(districtID)
		);
	elseif sequence == 3 and IsSpecialtyDistrict(district) then
		LOTM_RP_State.TryAddDigestion(
			playerID, "A", "SPECIALTY_DISTRICT:" .. tostring(cityID)
				.. ":" .. tostring(districtID)
		);
	end
end

local function OnDistrictAddedToMap(
	playerID :number,
	districtID :number,
	cityID :number,
	x :number,
	y :number,
	districtType :number,
	percentComplete :number
)
	if LOTM_MP_TurnSync.IsNetworkGame() then
		if IsPerfect(playerID) and percentComplete ~= nil and percentComplete >= 100 then
			QueueNetworkGameplayEvent(
				"DISTRICT",
				playerID,
				{
					DistrictID = districtID,
					CityID = cityID,
					X = x,
					Y = y,
					DistrictType = districtType,
					PercentComplete = percentComplete,
				},
				cityID, districtID, x, y, districtType, percentComplete
			);
		end
		return;
	end
	ApplyDistrictAddedToMap(
		playerID, districtID, cityID, x, y, districtType, percentComplete
	);
end

local function ApplyResearchCompleted(
	playerID :number,
	techIndex :number,
	isCanceled :boolean
)
	if not IsPerfect(playerID) or isCanceled then
		return;
	end
	local sequence = GetSequence(playerID);
	if sequence == 5 then
		LOTM_RP_State.TryAddDigestion(
			playerID, "A", "TECH_COMPLETED:" .. tostring(techIndex)
		);
	elseif sequence == 2 then
		LOTM_RP_State.TryAddDigestion(
			playerID, "A", "MENTOR_TECH:" .. tostring(techIndex)
		);
	elseif sequence == 1 then
		LOTM_RP_State.TryAddDigestion(
			playerID, "B", "ENLIGHTENER_KNOWLEDGE_TECH:" .. tostring(techIndex)
		);
	end
end

local function OnResearchCompleted(
	playerID :number,
	techIndex :number,
	isCanceled :boolean
)
	if LOTM_MP_TurnSync.IsNetworkGame() then
		if IsPerfect(playerID) and not isCanceled then
			QueueNetworkGameplayEvent(
				"RESEARCH",
				playerID,
				{ TechIndex = techIndex, IsCanceled = isCanceled },
				techIndex, isCanceled
			);
		end
		return;
	end
	ApplyResearchCompleted(playerID, techIndex, isCanceled);
end

local function ApplyCivicCompleted(
	playerID :number,
	civicIndex :number,
	isCanceled :boolean
)
	if not IsPerfect(playerID) or isCanceled then
		return;
	end
	local sequence = GetSequence(playerID);
	if sequence == 2 then
		LOTM_RP_State.TryAddDigestion(
			playerID, "B", "MENTOR_CIVIC:" .. tostring(civicIndex)
		);
	elseif sequence == 1 then
		LOTM_RP_State.TryAddDigestion(
			playerID, "B", "ENLIGHTENER_KNOWLEDGE_CIVIC:" .. tostring(civicIndex)
		);
	end
end

local function OnCivicCompleted(
	playerID :number,
	civicIndex :number,
	isCanceled :boolean
)
	if LOTM_MP_TurnSync.IsNetworkGame() then
		if IsPerfect(playerID) and not isCanceled then
			QueueNetworkGameplayEvent(
				"CIVIC",
				playerID,
				{ CivicIndex = civicIndex, IsCanceled = isCanceled },
				civicIndex, isCanceled
			);
		end
		return;
	end
	ApplyCivicCompleted(playerID, civicIndex, isCanceled);
end

local function OnUnitAddedToMap(playerID :number, unitID :number)
	if LOTM_MP_TurnSync.IsNetworkGame() then
		QueueNetworkScientistUnit(playerID, unitID);
		return;
	end
	ProcessScientistRecruitment(playerID, unitID);
end

local function OnUnitRemovedFromMap(playerID :number, unitID :number)
	local normalizedPlayerID = tonumber(playerID);
	local normalizedUnitID = tonumber(unitID);
	if normalizedPlayerID == nil or normalizedUnitID == nil then return; end
	local key = tostring(normalizedPlayerID) .. ":" .. tostring(normalizedUnitID);
	local entry = pendingNetworkScientistKeys[key];
	-- Great People commonly disappear in the same turn they are recruited.
	-- Keep the captured event in the Lua-local queue so the synchronized turn
	-- can still award it exactly once through the persistent per-unit ledger.
	if entry ~= nil then entry.RemovedBeforeSettlement = true; end
end

local function ApplyCityProjectCompleted(
	playerID :number,
	cityID :number,
	projectIndex :number,
	eventTurn :number
)
	if not IsPerfect(playerID) then
		return;
	end
	local project = GameInfo.Projects[projectIndex];
	if project == nil then
		return;
	end
	local advance = LOTM_PP_PROJECT_ADVANCES[project.ProjectType];
	if advance ~= nil then
		if not LOTM_RP_State.AdvanceSequence(
			playerID,
			advance[1],
			advance[2],
			advance.allowWithoutChurch == true
		) then
			Log("ERROR rejected project advancement player=" .. tostring(playerID)
				.. " project=" .. project.ProjectType);
		elseif advance[2] == 8 then
			ProcessRelics(playerID, true);
		end
		return;
	end
	local sequence = GetSequence(playerID);
	if sequence == 5 and project.SpaceRace then
		LOTM_RP_State.TryAddDigestion(
			playerID, "B", "SPACE_PROJECT:" .. tostring(project.ProjectType)
				.. ":" .. tostring(eventTurn ~= nil
					and eventTurn or Game.GetCurrentGameTurn())
		);
	elseif sequence == 4 then
		LOTM_RP_State.TryAddDigestion(
			playerID, "B", "CITY_PROJECT:" .. tostring(project.ProjectType)
				.. ":" .. tostring(cityID)
				.. ":" .. tostring(eventTurn ~= nil
					and eventTurn or Game.GetCurrentGameTurn())
		);
	end
end

local function OnCityProjectCompleted(
	playerID :number,
	cityID :number,
	projectIndex :number
)
	if LOTM_MP_TurnSync.IsNetworkGame() then
		if IsPerfect(playerID) and GameInfo.Projects[projectIndex] ~= nil then
			QueueNetworkGameplayEvent(
				"CITY_PROJECT",
				playerID,
				{ CityID = cityID, ProjectIndex = projectIndex },
				cityID, projectIndex
			);
		end
		return;
	end
	ApplyCityProjectCompleted(playerID, cityID, projectIndex, nil);
end

local function ApplyNetworkGameplayEvent(entry)
	local payload = entry.Payload;
	if entry.Kind == "TECH_BOOST" then
		ApplyTechBoostTriggered(entry.PlayerID);
	elseif entry.Kind == "CIVIC_BOOST" then
		ApplyCivicBoostTriggered(entry.PlayerID);
	elseif entry.Kind == "GOODY_HUT" then
		ApplyGoodyHutReward(
			entry.PlayerID,
			payload.UnitID,
			payload.RewardType,
			payload.RewardSubType
		);
	elseif entry.Kind == "UNIT_MOVE" then
		ApplyUnitMoveComplete(entry.PlayerID, payload.UnitID, payload.X, payload.Y);
	elseif entry.Kind == "UNIT_CHARGES" then
		ApplyUnitChargesChanged(
			entry.PlayerID,
			payload.UnitID,
			payload.NewCharges,
			payload.OldCharges,
			payload.UnitType
		);
	elseif entry.Kind == "IMPROVEMENT" then
		ApplyImprovementAddedToMap(
			payload.X, payload.Y, payload.ImprovementType, entry.PlayerID,
			entry.QueuedTurn
		);
	elseif entry.Kind == "DISTRICT" then
		ApplyDistrictAddedToMap(
			entry.PlayerID,
			payload.DistrictID,
			payload.CityID,
			payload.X,
			payload.Y,
			payload.DistrictType,
			payload.PercentComplete
		);
	elseif entry.Kind == "RESEARCH" then
		ApplyResearchCompleted(
			entry.PlayerID, payload.TechIndex, payload.IsCanceled
		);
	elseif entry.Kind == "CIVIC" then
		ApplyCivicCompleted(
			entry.PlayerID, payload.CivicIndex, payload.IsCanceled
		);
	elseif entry.Kind == "GREAT_WORK" then
		ApplyGreatWorkCreated(
			entry.PlayerID,
			payload.UnitID,
			payload.CityX,
			payload.CityY,
			payload.BuildingID,
			payload.GreatWorkID
		);
	elseif entry.Kind == "CITY_PROJECT" then
		ApplyCityProjectCompleted(
			entry.PlayerID, payload.CityID, payload.ProjectIndex,
			entry.QueuedTurn
		);
	end
end

local function ProcessNetworkGameplayEvents(playerID)
	if not LOTM_MP_TurnSync.IsNetworkGame()
		or not LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID) then return; end
	local currentTurn = Game.GetCurrentGameTurn();
	local ready :table = {};
	local waiting :table = {};
	for _, entry in ipairs(pendingNetworkGameplayEvents) do
		if entry.QueuedTurn < currentTurn then
			ready[#ready + 1] = entry;
		else
			waiting[#waiting + 1] = entry;
		end
	end
	pendingNetworkGameplayEvents = waiting;
	table.sort(ready, NetworkGameplayEventLess);
	-- Remove ready keys before applying.  If one application faults, the
	-- failed entry and every later entry are restored below in their sorted
	-- order, so no captured fact is silently lost.
	for _, entry in ipairs(ready) do
		if pendingNetworkGameplayEventKeys[entry.SortKey] == entry then
			pendingNetworkGameplayEventKeys[entry.SortKey] = nil;
		end
	end
	for index, entry in ipairs(ready) do
		local appliedCount = tonumber(entry.AppliedCount) or 0;
		local failureDetails = nil;
		for occurrence = 1, entry.Count do
			if occurrence > appliedCount then
				local ok, details = pcall(function()
					ApplyNetworkGameplayEvent(entry);
				end);
				if not ok then
					Log("ERROR deferred network fact kind=" .. tostring(entry.Kind)
						.. " turn=" .. tostring(entry.QueuedTurn)
						.. " player=" .. tostring(entry.PlayerID)
						.. " occurrence=" .. tostring(occurrence)
						.. " error=" .. tostring(details));
					entry.AppliedCount = occurrence - 1;
					failureDetails = details;
					break;
				end
				entry.AppliedCount = occurrence;
			end
		end
		if failureDetails ~= nil then
			for restoreIndex = index, #ready do
				local restore = ready[restoreIndex];
				pendingNetworkGameplayEvents[#pendingNetworkGameplayEvents + 1] = restore;
				pendingNetworkGameplayEventKeys[restore.SortKey] = restore;
			end
			-- The shared dispatcher catches this error and latches its global local
			-- fault before any later network handler can write synchronized state.
			error("Perfect deferred network fact failed: " .. tostring(failureDetails));
		end
	end
end

local function ProcessPlayer(playerID :number, allowTurnGrant :boolean)
	if not IsPerfect(playerID) then
		return;
	end
	LOTM_PP_RefreshSequenceState(playerID);
	ProcessRelics(playerID, allowTurnGrant);
end

function LOTM_PP_OnPathSelected(playerID :number)
	ProcessPlayer(playerID, true);
end

local function OnPlayerTurnActivated(playerID :number, isFirstTimeThisTurn :boolean)
	if isFirstTimeThisTurn ~= false then
		-- Scientist recruitment is also a digestion fact, so drain it before the
		-- generic queue whose CITY_PROJECT order is deliberately last.
		ProcessNetworkScientistUnits(playerID);
		ProcessNetworkGameplayEvents(playerID);
	end
	ProcessPlayer(playerID, isFirstTimeThisTurn);
end

local function Initialize()
	LOTM_MP_TurnSync.Add(OnPlayerTurnActivated,"Perfect");
	Events.TechBoostTriggered.Add(OnTechBoostTriggered);
	Events.CivicBoostTriggered.Add(OnCivicBoostTriggered);
	Events.GoodyHutReward.Add(OnGoodyHutReward);
	Events.UnitMoveComplete.Add(OnUnitMoveComplete);
	Events.UnitChargesChanged.Add(OnUnitChargesChanged);
	Events.ImprovementAddedToMap.Add(OnImprovementAddedToMap);
	Events.DistrictAddedToMap.Add(OnDistrictAddedToMap);
	Events.ResearchCompleted.Add(OnResearchCompleted);
	Events.CivicCompleted.Add(OnCivicCompleted);
	Events.UnitAddedToMap.Add(LOTM_UnitAddedPerf.Wrap("Perfect",OnUnitAddedToMap));
	Events.UnitRemovedFromMap.Add(OnUnitRemovedFromMap);
	Events.CityProjectCompleted.Add(OnCityProjectCompleted);
	Events.GreatWorkCreated.Add(OnGreatWorkCreated);
	GameEvents.BuildingConstructed.Add(OnBuildingConstructed);
	LOTM_MP_TurnSync.RunStartup(function()
		local playerIDs :table = {};
		for _, playerID in ipairs(PlayerManager.GetAliveMajorIDs()) do playerIDs[#playerIDs + 1] = playerID; end
		table.sort(playerIDs);
		for _, playerID in ipairs(playerIDs) do
			if (Game.GetProperty(SCIENTIST_LEDGER_VERSION_KEY) or 0) < SCIENTIST_LEDGER_VERSION then
				MarkExistingScientists(playerID);
			end
			ProcessPlayer(playerID, false);
		end
		if (Game.GetProperty(SCIENTIST_LEDGER_VERSION_KEY) or 0) < SCIENTIST_LEDGER_VERSION then
			Game.SetProperty(SCIENTIST_LEDGER_VERSION_KEY, SCIENTIST_LEDGER_VERSION);
		end
	end,"Perfect");
	Log("initialized Perfect Path Sequence 9 through Sequence 0");
end

Initialize();
