-- Sequence-9/8 progression and project advancement.
-- Sequence 9 intentionally observes synchronized unit experience instead of
-- reconstructing discovery/combat events with UI-only visibility APIs.

local LOTM_RP_HERO_TYPE :string = "UNIT_LOTM_RP_PATH_HOLDER";
local LOTM_RP_SEQUENCE_PROPERTY :string = "LOTM_RP_SEQUENCE";
local LOTM_RP_HUNTER_XP_BASELINE :string = "LOTM_RP_HUNTER_XP_BASELINE";
local LOTM_RP_PROJECT_PROVOKER :string = "PROJECT_LOTM_RP_PROVOKER_POTION";
local LOTM_RP_PROJECT_PYROMANIAC :string = "PROJECT_LOTM_RP_PYROMANIAC_POTION";
local LOTM_RP_BELIEF_CHURCH :string = "BELIEF_LOTM_RP_ESTABLISH_CHURCH";
local LOTM_RP_BELIEF_TRUE_GOD :string = "BELIEF_LOTM_RP_TRUE_GOD_CHURCH";
local LOTM_RP_CHURCH_START_TURN :string = "LOTM_RP_CHURCH_START_TURN";
local LOTM_RP_TRUE_GOD_CHURCH :string = "LOTM_RP_TRUE_GOD_CHURCH";
local LOTM_RP_CAN_ADVANCE_SEQUENCE_0 :string = "LOTM_RP_CAN_ADVANCE_SEQUENCE_0";
local pendingNetworkProjects :table = {};
local pendingNetworkProjectKeys :table = {};

local function Log(message :string)
	print("[LOTM_RP][Progression] " .. message);
end

local function GetPlayer(playerID :number)
	return playerID ~= nil and Players[playerID] or nil;
end

local function GetHeroTypeIndex()
	local definition = GameInfo.Units[LOTM_RP_HERO_TYPE];
	return definition ~= nil and definition.Index or -1;
end

local function IsHero(unit, playerID :number)
	return unit ~= nil
		and unit:GetOwner() == playerID
		and unit:GetType() == GetHeroTypeIndex();
end

local function GetSequence(playerID :number)
	return LOTM_RP_State.GetSequence(playerID);
end

local function IsRescueMode()
	return (tonumber(Game.GetProperty("LOTM_RESCUE_MODE") or 0) or 0) == 1;
end

local function GetHeroExperience(hero)
	if hero == nil then
		return nil;
	end
	local experience = hero:GetExperience();
	if experience == nil then
		return nil;
	end
	return experience:GetExperiencePoints() or 0;
end

local function ObserveHunterExperience(playerID :number, hero)
	if not LOTM_RP_State.IsEnabledPlayer(playerID)
		or GetSequence(playerID) ~= 9
		or not IsHero(hero, playerID) then
		return false;
	end
	local player = GetPlayer(playerID);
	local currentXP = GetHeroExperience(hero);
	if player == nil or currentXP == nil then
		return false;
	end

	local baseline = player:GetProperty(LOTM_RP_HUNTER_XP_BASELINE);
	if baseline == nil or baseline < 0 or currentXP < baseline then
		-- First observation, migration, or a defensive reset never grants
		-- historical progress. Respawned units restore the same XP and baseline.
		player:SetProperty(LOTM_RP_HUNTER_XP_BASELINE, currentXP);
		return false;
	end
	if currentXP > baseline then
		player:SetProperty(LOTM_RP_HUNTER_XP_BASELINE, currentXP);
		local objectKey = (IsRescueMode() and "RESCUE_P9:HUNTER_XP:" or "HUNTER_XP:")
			.. tostring(hero:GetID()) .. ":" .. tostring(currentXP);
		local added = LOTM_RP_State.TryAddDigestion(playerID, "A", objectKey);
		if added then
			Log("hunter experience progress player=" .. tostring(playerID)
				.. " xp=" .. tostring(currentXP));
		end
		return added;
	end
	return false;
end

local function GetBeliefIndex(beliefType :string)
	local definition = GameInfo.Beliefs[beliefType];
	return definition ~= nil and definition.Index or -1;
end

local function HasChurchPantheon(playerID :number)
	local player = GetPlayer(playerID);
	local religion = player ~= nil and player:GetReligion() or nil;
	local churchBeliefIndex = GetBeliefIndex(LOTM_RP_BELIEF_CHURCH);
	return religion ~= nil
		and churchBeliefIndex >= 0
		and religion:GetPantheon() == churchBeliefIndex;
end

local function HasFoundedBelief(playerID :number, beliefType :string)
	local beliefIndex = GetBeliefIndex(beliefType);
	if beliefIndex < 0 then
		return false;
	end
	local gameReligion = Game.GetReligion();
	local religions = gameReligion ~= nil and gameReligion:GetReligions() or {};
	for _, religion in ipairs(religions) do
		if religion.Founder == playerID then
			for _, religionBelief in ipairs(religion.Beliefs or {}) do
				if religionBelief == beliefIndex then
					return true;
				end
			end
		end
	end
	return false;
end

local function ProcessChurchEffects(playerID :number, allowGrant :boolean)
	local player = GetPlayer(playerID);
	if player == nil or not LOTM_RP_State.IsAnyPathPlayer(playerID) then
		return;
	end

	local currentTurn = Game.GetCurrentGameTurn();
	if HasChurchPantheon(playerID) then
		local startTurn = player:GetProperty(LOTM_RP_CHURCH_START_TURN);
		if startTurn == nil or startTurn < 0 then
			player:SetProperty(LOTM_RP_CHURCH_START_TURN, currentTurn);
			startTurn = currentTurn;
		end
		if allowGrant
			and currentTurn > startTurn
			and (currentTurn - startTurn) % 3 == 0 then
			LOTM_RP_State.TryAddDigestion(
				playerID,
				"A",
				(IsRescueMode() and "RESCUE_P9:AUX:CHURCH_TURN:" or "CHURCH_TURN:") .. tostring(currentTurn)
			);
		end
	end

	if HasFoundedBelief(playerID, LOTM_RP_BELIEF_TRUE_GOD) then
		player:SetProperty(LOTM_RP_TRUE_GOD_CHURCH, 1);
		player:SetProperty(LOTM_RP_CAN_ADVANCE_SEQUENCE_0, 1);
		if allowGrant then
			LOTM_RP_State.TryAddDigestion(
				playerID,
				"A",
				(IsRescueMode() and "RESCUE_P9:AUX:TRUE_GOD_CHURCH_TURN:" or "TRUE_GOD_CHURCH_TURN:") .. tostring(currentTurn)
			);
		end
	end
end

local function OnCommandChurchFounded(playerID :number, parameters :table)
	local player = GetPlayer(playerID);
	local churchBeliefIndex = GetBeliefIndex(LOTM_RP_BELIEF_CHURCH);
	local beliefID = parameters ~= nil and parameters.BeliefID or -1;
	if player == nil
		or not LOTM_RP_State.IsAnyPathPlayer(playerID)
		or churchBeliefIndex < 0
		or beliefID ~= churchBeliefIndex
		or not HasChurchPantheon(playerID) then
		Log("ERROR rejected church-founded command player=" .. tostring(playerID));
		return;
	end
	if (player:GetProperty(LOTM_RP_CHURCH_START_TURN) or -1) < 0 then
		player:SetProperty(
			LOTM_RP_CHURCH_START_TURN,
			Game.GetCurrentGameTurn()
		);
	end
end

local function OnCommandDenounce(playerID :number, parameters :table)
	local targetPlayerID = parameters ~= nil and parameters.TargetPlayerID or -1;
	local denounceTurn = parameters ~= nil
		and tonumber(parameters.DenounceTurn) or -1;
	local targetPlayer = GetPlayer(targetPlayerID);
	local sequence = GetSequence(playerID);
	local currentTurn = Game.GetCurrentGameTurn();
	if not LOTM_RP_State.IsEnabledPlayer(playerID)
		or sequence ~= 8
		or targetPlayerID == playerID
		or targetPlayer == nil
		or not targetPlayer:IsAlive()
		or not targetPlayer:IsMajor()
		or denounceTurn < 0
		or denounceTurn ~= math.floor(denounceTurn)
		or denounceTurn > currentTurn then
		Log("ERROR rejected denounce command player=" .. tostring(playerID)
			.. " target=" .. tostring(targetPlayerID)
			.. " denounceTurn=" .. tostring(denounceTurn)
			.. " currentTurn=" .. tostring(currentTurn));
		return;
	end
	LOTM_RP_State.TryAddDigestion(
		playerID,
		"A",
		"DENOUNCE_TARGET:" .. tostring(targetPlayerID)
			.. ":" .. tostring(denounceTurn)
	);
	Log("player=" .. tostring(playerID)
		.. " denounced target=" .. tostring(targetPlayerID)
		.. " turn=" .. tostring(denounceTurn)
		.. " sequence8 digestion submitted");
end

local function ProcessProgressionPlayer(playerID :number, allowTurnGrant :boolean)
	if not LOTM_RP_State.IsAnyPathPlayer(playerID) then
		return;
	end
	LOTM_RP_State.RefreshSequenceState(playerID);
	local sequence = GetSequence(playerID);
	if LOTM_RP_State.IsEnabledPlayer(playerID) and sequence == 9 then
		ObserveHunterExperience(playerID, LOTM_RP_State.FindHero(playerID));
	end
	ProcessChurchEffects(playerID, allowTurnGrant);
end

local function OnPlayerTurnActivated(playerID :number, isFirstTimeThisTurn :boolean)
	if isFirstTimeThisTurn ~= false and LOTM_MP_TurnSync.IsNetworkGame()
		and LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID) then
		local currentTurn = Game.GetCurrentGameTurn();
		local ready :table = {}; local waiting :table = {};
		for _, entry in ipairs(pendingNetworkProjects) do
			if entry.QueuedTurn < currentTurn then ready[#ready + 1] = entry;
			else waiting[#waiting + 1] = entry; end
		end
		pendingNetworkProjects = waiting;
		table.sort(ready, function(a,b)
			if a.QueuedTurn ~= b.QueuedTurn then return a.QueuedTurn < b.QueuedTurn; end
			if a.PlayerID ~= b.PlayerID then return a.PlayerID < b.PlayerID; end
			if a.ProjectID ~= b.ProjectID then return a.ProjectID < b.ProjectID; end
			return a.CityID < b.CityID;
		end);
		for _, entry in ipairs(ready) do
			if pendingNetworkProjectKeys[entry.Key] == entry then pendingNetworkProjectKeys[entry.Key] = nil; end
			entry.Apply(entry.PlayerID, entry.CityID, entry.ProjectID);
		end
	end
	ProcessProgressionPlayer(playerID, isFirstTimeThisTurn);
end

local function OnUnitMoveComplete(playerID :number, unitID :number, x :number, y :number)
	if LOTM_MP_TurnSync.IsNetworkGame() then return; end
	local player = GetPlayer(playerID);
	local unit = player ~= nil and player:GetUnits():FindID(unitID) or nil;
	ObserveHunterExperience(playerID, unit);
end

local function OnGoodyHutReward(
	playerID :number,
	unitID :number,
	rewardType :number,
	rewardSubType :number
)
	if LOTM_MP_TurnSync.IsNetworkGame() then return; end
	local player = GetPlayer(playerID);
	local unit = player ~= nil and player:GetUnits():FindID(unitID) or nil;
	ObserveHunterExperience(playerID, unit);
end

local function CountStrongerTargetAttack(
	attackerPlayerID :number,
	attackerUnit,
	defenderPlayerID :number,
	defenderUnit
)
	if not IsHero(attackerUnit, attackerPlayerID)
		or defenderUnit == nil
		or GetSequence(attackerPlayerID) ~= 8 then
		return;
	end
	local attackerBase = attackerUnit:GetCombat() or 0;
	local defenderBase = defenderUnit:GetCombat() or 0;
	if defenderBase > attackerBase then
		LOTM_RP_State.TryAddDigestion(
			attackerPlayerID,
			"B",
			"TARGET_UNIT:" .. tostring(defenderPlayerID)
				.. ":" .. tostring(defenderUnit:GetID())
		);
	end
end

local function OnCombatOccurred(
	attackerPlayerID :number,
	attackerUnitID :number,
	defenderPlayerID :number,
	defenderUnitID :number
)
	local attackerPlayer = GetPlayer(attackerPlayerID);
	local defenderPlayer = GetPlayer(defenderPlayerID);
	local attackerUnit = attackerPlayer ~= nil
		and attackerPlayer:GetUnits():FindID(attackerUnitID) or nil;
	local defenderUnit = defenderPlayer ~= nil
		and defenderPlayer:GetUnits():FindID(defenderUnitID) or nil;

	ObserveHunterExperience(attackerPlayerID, attackerUnit);
	ObserveHunterExperience(defenderPlayerID, defenderUnit);
	CountStrongerTargetAttack(
		attackerPlayerID,
		attackerUnit,
		defenderPlayerID,
		defenderUnit
	);
end

local function OnPostUnitPromotionEarned(
	playerID :number,
	unitID :number,
	promotionType :number
)
	local player = GetPlayer(playerID);
	local unit = player ~= nil and player:GetUnits():FindID(unitID) or nil;
	ObserveHunterExperience(playerID, unit);
end

local function ApplyCityProjectCompleted(
	playerID :number,
	cityID :number,
	projectID :number
)
	-- AdvanceSequence is shared by every path.  A stale or externally granted
	-- Red Priest project must not advance a different path at the same sequence.
	if not LOTM_RP_State.IsEnabledPlayer(playerID) then
		return;
	end
	local provoker = GameInfo.Projects[LOTM_RP_PROJECT_PROVOKER];
	local pyromaniac = GameInfo.Projects[LOTM_RP_PROJECT_PYROMANIAC];
	local advanced = false;
	if provoker ~= nil and projectID == provoker.Index then
		advanced = LOTM_RP_State.AdvanceSequence(playerID, 9, 8);
	elseif pyromaniac ~= nil and projectID == pyromaniac.Index then
		advanced = LOTM_RP_State.AdvanceSequence(playerID, 8, 7);
	else
		return;
	end

	if not advanced then
		Log("ERROR rejected project completion player=" .. tostring(playerID)
			.. " project=" .. tostring(projectID)
			.. " sequence=" .. tostring(GetSequence(playerID)));
	end
end

local function OnCityProjectCompleted(playerID :number, cityID :number, projectID :number)
	if not LOTM_RP_State.IsEnabledPlayer(playerID) then return; end
	if not LOTM_MP_TurnSync.IsNetworkGame() then
		ApplyCityProjectCompleted(playerID, cityID, projectID);
		return;
	end
	local provoker = GameInfo.Projects[LOTM_RP_PROJECT_PROVOKER];
	local pyromaniac = GameInfo.Projects[LOTM_RP_PROJECT_PYROMANIAC];
	if (provoker == nil or projectID ~= provoker.Index)
		and (pyromaniac == nil or projectID ~= pyromaniac.Index) then return; end
	local turn = Game.GetCurrentGameTurn();
	local key = table.concat({turn, playerID, cityID, projectID}, ":");
	if pendingNetworkProjectKeys[key] ~= nil then return; end
	local entry = {QueuedTurn=turn,PlayerID=tonumber(playerID),CityID=tonumber(cityID),
		ProjectID=tonumber(projectID),Key=key,Apply=ApplyCityProjectCompleted};
	if entry.PlayerID == nil or entry.CityID == nil or entry.ProjectID == nil then return; end
	pendingNetworkProjects[#pendingNetworkProjects + 1] = entry;
	pendingNetworkProjectKeys[key] = entry;
end

local function Initialize()
	LOTM_MP_TurnSync.Add(OnPlayerTurnActivated,"Progression");
	Events.UnitMoveComplete.Add(OnUnitMoveComplete);
	Events.GoodyHutReward.Add(OnGoodyHutReward);
	Events.CityProjectCompleted.Add(OnCityProjectCompleted);
	GameEvents.OnCombatOccurred.Add(OnCombatOccurred);
	GameEvents.PostUnitPromotionEarned.Add(OnPostUnitPromotionEarned);
	GameEvents.LOTM_RP_Command_Denounce.Add(OnCommandDenounce);
	GameEvents.LOTM_RP_Command_ChurchFounded.Add(OnCommandChurchFounded);

	LOTM_MP_TurnSync.RunStartup(function()
		local playerIDs :table = {};
		for _, playerID in ipairs(PlayerManager.GetAliveMajorIDs() or {}) do
			playerIDs[#playerIDs + 1] = playerID;
		end
		table.sort(playerIDs);
		for _, playerID in ipairs(playerIDs) do
			ProcessProgressionPlayer(playerID, false);
		end
	end,"Progression");
	Log("initialized experience-driven sequence-9/8 progression");
end

Initialize();
