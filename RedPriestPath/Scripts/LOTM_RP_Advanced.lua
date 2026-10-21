-- Sequence 6–0 authoritative Gameplay layer.
-- Sequence 2 Weather Manipulation is implemented by synchronized database
-- modifiers; Lua remains responsible for the earlier event-driven effects.

local LOTM_RP_HERO_TYPE :string = "UNIT_LOTM_RP_PATH_HOLDER";
local LOTM_RP_COMMAND_PLAN_TARGET :string = "LOTM_RP_Command_SelectPlanTarget";
local LOTM_RP_PLAN_TARGET_ID :string = "LOTM_RP_PLAN_TARGET_ID";
local LOTM_RP_PLAN_TARGET_READY_AT :string = "LOTM_RP_PLAN_TARGET_READY_AT";
local LOTM_RP_PLAN_WAS_AT_WAR :string = "LOTM_RP_PLAN_WAS_AT_WAR";
local LOTM_RP_PLAN_GOLD_ACTIVE :string = "LOTM_RP_PLAN_GOLD_ACTIVE";
local LOTM_RP_PLAN_GOLD_MODIFIER_ACTIVE :string =
	"LOTM_RP_PLAN_GOLD_MODIFIER_ACTIVE";
local LOTM_RP_PLAN_GOLD_START_MODIFIER :string =
	"LOTM_RP_MOD_PLAN_GOLD_PER_TURN_START";
local LOTM_RP_PLAN_GOLD_STOP_MODIFIER :string =
	"LOTM_RP_MOD_PLAN_GOLD_PER_TURN_STOP";
local LOTM_RP_REAPER_HEAL_TURN :string = "LOTM_RP_REAPER_HEAL_TURN";
local LOTM_RP_FORMATION_BASELINED :string = "LOTM_RP_S4_FORMATION_BASELINED";
local LOTM_RP_FORMATION_OBSERVED :string = "LOTM_RP_S4_FORMATION_OBSERVED";
local LOTM_RP_PROVOKER_GARRISON_ABILITY :string =
	"ABILITY_LOTM_RP_PROVOKER_GARRISONED";
local LOTM_RP_PLAN_TARGET_COOLDOWN :number = 10;
local LOTM_RP_PLAN_FIRST_WAR_GOLD :number = 2000;
local pendingNetworkProjects :table = {};
local pendingNetworkProjectKeys :table = {};

local LOTM_RP_PROJECTS :table = {
	["PROJECT_LOTM_RP_CONSPIRATOR_POTION"] = { from = 7, to = 6 },
	["PROJECT_LOTM_RP_REAPER_POTION"] = { from = 6, to = 5 },
	["PROJECT_LOTM_RP_IRONBLOOD_KNIGHT_POTION"] = { from = 5, to = 4 },
	["PROJECT_LOTM_RP_WAR_BISHOP_POTION"] = { from = 4, to = 3 },
	["PROJECT_LOTM_RP_WEATHER_WARLOCK_POTION"] = { from = 3, to = 2 },
	["PROJECT_LOTM_RP_CONQUEROR_POTION"] = { from = 2, to = 1 },
	["PROJECT_LOTM_RP_WAR_FESTIVAL"] = {
		from = 1, to = 0, requiresChurch = true
	},
	["PROJECT_LOTM_RP_WAR_FESTIVAL_UNCONSECRATED"] = {
		from = 1, to = 0, allowWithoutChurch = true
	},
};

local function Log(message :string)
	print("[LOTM_RP][Advanced] " .. message);
end

local function GetPlayer(playerID :number)
	return playerID ~= nil and Players[playerID] or nil;
end

local function GetHeroTypeIndex()
	local definition = GameInfo.Units[LOTM_RP_HERO_TYPE];
	return definition ~= nil and definition.Index or -1;
end

local function IsLivingHero(unit, playerID :number)
	return unit ~= nil
		and unit:GetOwner() == playerID
		and not unit:IsDead()
		and not unit:IsDelayedDeath()
		and unit:GetType() == GetHeroTypeIndex();
end

local function IsAtWar(playerID :number, targetID :number)
	local player = GetPlayer(playerID);
	local diplomacy = player ~= nil and player:GetDiplomacy() or nil;
	return diplomacy ~= nil and diplomacy:IsAtWarWith(targetID);
end

local function IsMajorLivingOpponent(playerID :number, targetID :number)
	local target = GetPlayer(targetID);
	return targetID ~= playerID
		and target ~= nil
		and target:IsAlive()
		and target:IsMajor();
end

local function SetPlanningIncomeModifier(player, shouldBeActive :boolean)
	if player == nil then
		return;
	end
	local isActive =
		(player:GetProperty(LOTM_RP_PLAN_GOLD_MODIFIER_ACTIVE) or 0) == 1;
	if shouldBeActive == isActive then
		return;
	end
	-- Firaxis uses MODIFIER_PLAYER_ADJUST_YIELD_CHANGE + YIELD_GOLD for
	-- genuine Gold-per-turn income.  Attach a balancing -100 modifier when
	-- peace begins because Player exposes AttachModifierByID but no matching
	-- detach operation.
	player:AttachModifierByID(
		shouldBeActive
			and LOTM_RP_PLAN_GOLD_START_MODIFIER
			or LOTM_RP_PLAN_GOLD_STOP_MODIFIER
	);
	player:SetProperty(
		LOTM_RP_PLAN_GOLD_MODIFIER_ACTIVE,
		shouldBeActive and 1 or 0
	);
	Log("player=" .. tostring(player:GetID())
		.. " native planned income active=" .. tostring(shouldBeActive));
end

local function GetIntegerParameter(parameters :table, key)
	local value = parameters ~= nil and tonumber(parameters[key]) or nil;
	return value ~= nil and value == math.floor(value) and value or nil;
end

local function HasIndustrialization(playerID :number)
	local player = GetPlayer(playerID);
	local technology = GameInfo.Technologies["TECH_INDUSTRIALIZATION"];
	return player ~= nil and technology ~= nil
		and player:GetTechs():HasTech(technology.Index);
end

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

local function IsCorpsOrArmy(unit)
	if unit == nil then
		return false;
	end
	local formation = unit:GetMilitaryFormation();
	return formation == MilitaryFormationTypes.CORPS_FORMATION
		or formation == MilitaryFormationTypes.ARMY_FORMATION;
end

local function ProcessProvokerGarrison(playerID :number)
	if not LOTM_RP_State.IsEnabledPlayer(playerID) then
		return;
	end
	local hero = LOTM_RP_State.FindHero(playerID);
	if not IsLivingHero(hero, playerID) then
		return;
	end
	local ability = hero:GetAbility();
	if ability == nil then
		return;
	end
	local shouldBeActive = LOTM_RP_State.GetSequence(playerID) <= 8
		and (hero:GetFortifyTurns() or 0) > 0;
	local currentCount = ability:GetAbilityCount(LOTM_RP_PROVOKER_GARRISON_ABILITY) or 0;
	if shouldBeActive and currentCount < 1 then
		ability:ChangeAbilityCount(LOTM_RP_PROVOKER_GARRISON_ABILITY, 1);
	elseif not shouldBeActive and currentCount > 0 then
		ability:ChangeAbilityCount(
			LOTM_RP_PROVOKER_GARRISON_ABILITY,
			-currentCount
		);
	end
	if shouldBeActive then
		local damage = hero:GetDamage() or 0;
		if damage > 0 then
			hero:ChangeDamage(-damage);
		end
	end
end

local function OnCommandSelectPlanTarget(playerID :number, parameters :table)
	local player = GetPlayer(playerID);
	local targetID = GetIntegerParameter(parameters, "TargetPlayerID");
	if player == nil
		or not LOTM_RP_State.IsEnabledPlayer(playerID)
		or IsRescueMode()
		or LOTM_RP_State.GetSequence(playerID) > 6
		or targetID == nil
		or not IsMajorLivingOpponent(playerID, targetID) then
		Log("ERROR rejected plan target player=" .. tostring(playerID));
		return;
	end

	local currentTurn = Game.GetCurrentGameTurn();
	local currentTarget = player:GetProperty(LOTM_RP_PLAN_TARGET_ID) or -1;
	local readyAt = player:GetProperty(LOTM_RP_PLAN_TARGET_READY_AT) or -1;
	if targetID ~= currentTarget and readyAt >= 0 and currentTurn < readyAt then
		Log("ERROR rejected plan target cooldown player=" .. tostring(playerID));
		return;
	end
	if targetID ~= currentTarget then
		local isAtWar = IsAtWar(playerID, targetID);
		player:SetProperty(LOTM_RP_PLAN_TARGET_ID, targetID);
		player:SetProperty(
			LOTM_RP_PLAN_TARGET_READY_AT,
			currentTurn + LOTM_RP_PLAN_TARGET_COOLDOWN
		);
		-- Selecting an already-warring civilization does not fabricate a new
		-- "first entered war" event, but its continuing-war income is active.
		player:SetProperty(LOTM_RP_PLAN_WAS_AT_WAR, isAtWar and 1 or 0);
		player:SetProperty(LOTM_RP_PLAN_GOLD_ACTIVE, isAtWar and 1 or 0);
		SetPlanningIncomeModifier(player, isAtWar);
	end
	Log("player=" .. tostring(playerID) .. " planned target=" .. tostring(targetID));
end

local function ProcessPlannedWarEconomy(playerID :number)
	if not LOTM_RP_State.IsEnabledPlayer(playerID)
		or LOTM_RP_State.GetSequence(playerID) > 6 then
		return;
	end
	local player = GetPlayer(playerID);
	if IsRescueMode() then
		if player ~= nil then
			SetPlanningIncomeModifier(player, false);
			player:SetProperty(LOTM_RP_PLAN_GOLD_ACTIVE, 0);
		end
		return;
	end
	local targetID = player ~= nil
		and (player:GetProperty(LOTM_RP_PLAN_TARGET_ID) or -1) or -1;
	if player == nil or not IsMajorLivingOpponent(playerID, targetID) then
		if player ~= nil then
			player:SetProperty(LOTM_RP_PLAN_GOLD_ACTIVE, 0);
			SetPlanningIncomeModifier(player, false);
		end
		return;
	end

	local isAtWar = IsAtWar(playerID, targetID);
	local wasAtWar = player:GetProperty(LOTM_RP_PLAN_WAS_AT_WAR);
	if wasAtWar == nil or wasAtWar < 0 then
		-- Save/load baseline: do not retroactively pay 2000 Gold for a war
		-- which began before this version observed the relationship.
		player:SetProperty(LOTM_RP_PLAN_WAS_AT_WAR, isAtWar and 1 or 0);
		player:SetProperty(LOTM_RP_PLAN_GOLD_ACTIVE, isAtWar and 1 or 0);
		SetPlanningIncomeModifier(player, isAtWar);
		return;
	end
	if isAtWar and wasAtWar == 0 then
		local firstWarProperty =
			"LOTM_RP_PLAN_FIRST_WAR_REWARDED:" .. tostring(targetID);
		if (player:GetProperty(firstWarProperty) or 0) ~= 1 then
			player:SetProperty(firstWarProperty, 1);
			player:GetTreasury():ChangeGoldBalance(LOTM_RP_PLAN_FIRST_WAR_GOLD);
			if LOTM_RP_State.GetSequence(playerID) == 6 then
				LOTM_RP_State.TryAddDigestion(
					playerID,
					"A",
					"PLANNED_WAR:" .. tostring(targetID)
				);
			end
			Log("player=" .. tostring(playerID)
				.. " first planned war target=" .. tostring(targetID)
				.. " gold=" .. tostring(LOTM_RP_PLAN_FIRST_WAR_GOLD));
		end
	end
	player:SetProperty(LOTM_RP_PLAN_WAS_AT_WAR, isAtWar and 1 or 0);
	player:SetProperty(LOTM_RP_PLAN_GOLD_ACTIVE, isAtWar and 1 or 0);
	SetPlanningIncomeModifier(player, isAtWar);
end

local function OnDiplomacyWarStateChanged(firstPlayerID :number, secondPlayerID :number)
	-- Diplomacy notifications are local publications in network games.  The
	-- same relationships are reconciled from synchronized state every turn.
	if LOTM_MP_TurnSync.IsNetworkGame() then return; end
	ProcessPlannedWarEconomy(firstPlayerID);
	ProcessPlannedWarEconomy(secondPlayerID);
end

local function ProcessFormationDigestion(playerID :number)
	if not LOTM_RP_State.IsEnabledPlayer(playerID)
		or LOTM_RP_State.GetSequence(playerID) ~= 4 then
		return;
	end
	local player = GetPlayer(playerID);
	if player == nil then
		return;
	end
	local baseline = player:GetProperty(LOTM_RP_FORMATION_BASELINED) or 0;
	for _, unit in player:GetUnits():Members() do
		if IsCorpsOrArmy(unit) then
			local key = LOTM_RP_FORMATION_OBSERVED .. ":" .. tostring(unit:GetID());
			if baseline ~= 1 then
				unit:SetProperty(key, 1);
			elseif (unit:GetProperty(key) or 0) ~= 1 then
				unit:SetProperty(key, 1);
				LOTM_RP_State.TryAddDigestion(
					playerID,
					"A",
					"FORMATION:" .. tostring(unit:GetID())
				);
			end
		end
	end
	if baseline ~= 1 then
		player:SetProperty(LOTM_RP_FORMATION_BASELINED, 1);
	end
end

local function ProcessWeatherDigestion(playerID :number)
	if not LOTM_RP_State.IsEnabledPlayer(playerID)
		or LOTM_RP_State.GetSequence(playerID) ~= 2 then
		return;
	end
	for _, targetID in ipairs(PlayerManager.GetAliveMajorIDs()) do
		if IsMajorLivingOpponent(playerID, targetID) and IsAtWar(playerID, targetID) then
			LOTM_RP_State.TryAddDigestion(
				playerID,
				"A",
				"WEATHER_WAR_TURN:" .. tostring(Game.GetCurrentGameTurn())
			);
			return;
		end
	end
end

local function IsWithinHeroRange(playerID :number, unit)
	local hero = LOTM_RP_State.FindHero(playerID);
	return hero ~= nil and unit ~= nil
		and Map.GetPlotDistance(hero:GetX(), hero:GetY(), unit:GetX(), unit:GetY())
			<= 6;
end

local function IsDefeatedUnit(defenderUnitID :number, defenderUnit)
	return defenderUnitID ~= nil and defenderUnitID >= 0
		and (defenderUnit == nil or defenderUnit:IsDead() or defenderUnit:IsDelayedDeath());
end

local function HealAfterKill(playerID :number, attackerUnit)
	local currentTurn = Game.GetCurrentGameTurn();
	if attackerUnit == nil
		or (attackerUnit:GetProperty(LOTM_RP_REAPER_HEAL_TURN) or -1) == currentTurn then
		return;
	end
	local amount = IsLivingHero(attackerUnit, playerID) and 60 or 30;
	local damage = attackerUnit:GetDamage() or 0;
	if damage > 0 then
		attackerUnit:ChangeDamage(-math.min(amount, damage));
	end
	attackerUnit:SetProperty(LOTM_RP_REAPER_HEAL_TURN, currentTurn);
end

local function OnCombatOccurred(
	attackerPlayerID :number,
	attackerUnitID :number,
	defenderPlayerID :number,
	defenderUnitID :number
)
	local attackerPlayer = GetPlayer(attackerPlayerID);
	local defenderPlayer = GetPlayer(defenderPlayerID);
	local attacker = attackerPlayer ~= nil
		and attackerPlayer:GetUnits():FindID(attackerUnitID) or nil;
	local defender = defenderPlayer ~= nil
		and defenderPlayer:GetUnits():FindID(defenderUnitID) or nil;
	if attacker == nil or not IsDefeatedUnit(defenderUnitID, defender) then
		return;
	end

	local sequence = LOTM_RP_State.IsEnabledPlayer(attackerPlayerID)
		and LOTM_RP_State.GetSequence(attackerPlayerID) or 10;
	if sequence <= 5 then
		HealAfterKill(attackerPlayerID, attacker);
	end
	if sequence == 5 then
		LOTM_RP_State.TryAddDigestion(
			attackerPlayerID,
			"B",
			"REAPER_KILL:" .. tostring(Game.GetCurrentGameTurn())
				.. ":" .. tostring(attackerUnitID) .. ":" .. tostring(defenderPlayerID)
				.. ":" .. tostring(defenderUnitID)
		);
		if defender ~= nil and (defender:GetDamage() or 0) > 0 then
			LOTM_RP_State.TryAddDigestion(
				attackerPlayerID,
				"A",
				"REAPER_WOUNDED_KILL:" .. tostring(Game.GetCurrentGameTurn())
					.. ":" .. tostring(attackerUnitID) .. ":" .. tostring(defenderPlayerID)
					.. ":" .. tostring(defenderUnitID)
			);
		end
	elseif sequence == 4 and IsWithinHeroRange(attackerPlayerID, attacker) then
		LOTM_RP_State.TryAddDigestion(
			attackerPlayerID,
			"B",
			"IRONBLOOD_AURA_KILL:" .. tostring(Game.GetCurrentGameTurn())
				.. ":" .. tostring(attackerUnitID) .. ":" .. tostring(defenderPlayerID)
				.. ":" .. tostring(defenderUnitID)
		);
	end
end

local function OnCityConquered(
	capturerID :number,
	ownerID :number,
	cityID :number,
	cityX :number,
	cityY :number
)
	if not LOTM_RP_State.IsEnabledPlayer(capturerID) then
		return;
	end
	local sequence = LOTM_RP_State.GetSequence(capturerID);
	if sequence ~= 3 and sequence ~= 1 then
		return;
	end
	local player = GetPlayer(capturerID);
	local city = player ~= nil and player:GetCities():FindID(cityID) or nil;
	if sequence == 3 and city ~= nil and not IsRescueMode() then
		city:ChangeLoyalty(15);
	end
	LOTM_RP_State.TryAddDigestion(
		capturerID,
		"B",
		(sequence == 1 and "CONQUEROR_CITY:" or "CITY_CONQUERED:")
			.. tostring(cityX) .. ":" .. tostring(cityY)
			.. ":" .. tostring(Game.GetCurrentGameTurn())
	);
	if sequence == 1 and city ~= nil and type(city.IsOriginalCapital) == "function" then
		local ok, isOriginalCapital = pcall(city.IsOriginalCapital, city);
		if ok and isOriginalCapital then
			LOTM_RP_State.TryAddDigestion(
				capturerID,
				"A",
				"CONQUEROR_ORIGINAL_CAPITAL:" .. tostring(cityX) .. ":" .. tostring(cityY)
					.. ":" .. tostring(Game.GetCurrentGameTurn())
			);
		end
	end
end

local function ApplyCityProjectCompleted(playerID :number, cityID :number, projectID :number)
	-- The shared advancement helper validates sequence and digestion, while
	-- this project handler owns the Red Priest path restriction.
	if not LOTM_RP_State.IsEnabledPlayer(playerID) then
		return;
	end
	-- Resolve the engine's synchronized project index directly.  Avoiding a
	-- hash-table scan removes table-order dependence without changing which
	-- project is recognized or any advancement condition.
	local definition = GameInfo.Projects[projectID];
	local projectType = definition ~= nil and definition.ProjectType or nil;
	if projectType == nil then
		return;
	end
	local project = LOTM_RP_PROJECTS[projectType];
	if project == nil then
		return;
	end
	if project.from == 5 and not IsRescueMode() and not HasIndustrialization(playerID) then
		Log("ERROR rejected ironblood advancement without industrialization player=" .. tostring(playerID));
		return;
	end
	if project.requiresChurch then
		local player = GetPlayer(playerID);
		if player == nil or (player:GetProperty("LOTM_RP_CAN_ADVANCE_SEQUENCE_0") or 0) ~= 1 then
			Log("ERROR rejected Red Priest advancement without True God Church player=" .. tostring(playerID));
			return;
		end
	end
	if not LOTM_RP_State.AdvanceSequence(
		playerID,
		project.from,
		project.to,
		project.allowWithoutChurch == true
	) then
		Log("ERROR rejected advanced project player=" .. tostring(playerID)
			.. " project=" .. projectType);
	elseif project.to == 6 then
		ProcessPlannedWarEconomy(playerID);
	end
end

local function OnCityProjectCompleted(playerID :number, cityID :number, projectID :number)
	if not LOTM_RP_State.IsEnabledPlayer(playerID) then return; end
	if not LOTM_MP_TurnSync.IsNetworkGame() then
		ApplyCityProjectCompleted(playerID,cityID,projectID); return;
	end
	local normalizedPlayerID=tonumber(playerID); local normalizedCityID=tonumber(cityID);
	local normalizedProjectID=tonumber(projectID); local definition=GameInfo.Projects[normalizedProjectID];
	if normalizedPlayerID==nil or normalizedCityID==nil or normalizedProjectID==nil
		or definition==nil or LOTM_RP_PROJECTS[definition.ProjectType]==nil then return; end
	local turn=Game.GetCurrentGameTurn();
	local key=table.concat({turn,normalizedPlayerID,normalizedProjectID,normalizedCityID},":");
	if pendingNetworkProjectKeys[key]~=nil then return; end
	local entry={QueuedTurn=turn,PlayerID=normalizedPlayerID,CityID=normalizedCityID,
		ProjectID=normalizedProjectID,Key=key};
	pendingNetworkProjects[#pendingNetworkProjects+1]=entry; pendingNetworkProjectKeys[key]=entry;
end

local function ProcessNetworkProjects(playerID)
	if not LOTM_MP_TurnSync.IsNetworkGame() or not LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID) then return; end
	local currentTurn=Game.GetCurrentGameTurn(); local ready={}; local waiting={};
	for _,entry in ipairs(pendingNetworkProjects) do
		if entry.QueuedTurn<currentTurn then ready[#ready+1]=entry; else waiting[#waiting+1]=entry; end
	end
	pendingNetworkProjects=waiting;
	table.sort(ready,function(a,b)
		if a.QueuedTurn~=b.QueuedTurn then return a.QueuedTurn<b.QueuedTurn; end
		if a.PlayerID~=b.PlayerID then return a.PlayerID<b.PlayerID; end
		if a.ProjectID~=b.ProjectID then return a.ProjectID<b.ProjectID; end
		return a.CityID<b.CityID;
	end);
	for _,entry in ipairs(ready) do
		if pendingNetworkProjectKeys[entry.Key]==entry then pendingNetworkProjectKeys[entry.Key]=nil; end
		ApplyCityProjectCompleted(entry.PlayerID,entry.CityID,entry.ProjectID);
	end
end

local function OnPlayerTurnActivated(playerID :number, isFirstTimeThisTurn :boolean)
	if not isFirstTimeThisTurn then
		return;
	end
	ProcessNetworkProjects(playerID);
	ProcessProvokerGarrison(playerID);
	ProcessPlannedWarEconomy(playerID);
	ProcessFormationDigestion(playerID);
	ProcessWeatherDigestion(playerID);
end

local function Initialize()
	GameEvents.LOTM_RP_Command_SelectPlanTarget.Add(OnCommandSelectPlanTarget);
	GameEvents.OnCombatOccurred.Add(OnCombatOccurred);
	GameEvents.CityConquered.Add(OnCityConquered);
	Events.CityProjectCompleted.Add(OnCityProjectCompleted);
	Events.DiplomacyDeclareWar.Add(OnDiplomacyWarStateChanged);
	Events.DiplomacyMakePeace.Add(OnDiplomacyWarStateChanged);
	LOTM_MP_TurnSync.Add(OnPlayerTurnActivated,"Advanced");
	LOTM_MP_TurnSync.RunStartup(function()
		local playerIDs :table = {};
		for _, playerID in ipairs(PlayerManager.GetAliveMajorIDs() or {}) do
			playerIDs[#playerIDs + 1] = playerID;
		end
		table.sort(playerIDs);
		for _, playerID in ipairs(playerIDs) do
			ProcessProvokerGarrison(playerID);
			ProcessPlannedWarEconomy(playerID);
			ProcessFormationDigestion(playerID);
			ProcessWeatherDigestion(playerID);
		end
	end,"Advanced");
	Log("initialized sequence 6-0 core");
end

Initialize();
