-- Phase 05 release-candidate deterministic sequence-7 arson command and
-- ordinary-pillage digestion.
-- Every mutation in this file runs in Gameplay after an EXECUTE_SCRIPT command
-- or an authoritative Gameplay event.

local LOTM_RP_COMMAND_NAME :string = "LOTM_RP_Command_Arson";
local LOTM_RP_HERO_TYPE :string = "UNIT_LOTM_RP_PATH_HOLDER";
local LOTM_RP_SEQUENCE_PROPERTY :string = "LOTM_RP_SEQUENCE";
local LOTM_RP_UNIT_ID_PROPERTY :string = "LOTM_RP_UNIT_ID";
local LOTM_RP_ARSON_READY_AT_PROPERTY :string = "LOTM_RP_ARSON_READY_AT";
local LOTM_RP_ARSON_RANGE :number = 6;
local LOTM_RP_ARSON_COOLDOWN :number = 5;
local LOTM_RP_BURN_DURATION :number = 9;

local LOTM_RP_BURN_STARTED_AT :string = "LOTM_RP_BURN_STARTED_AT";
local LOTM_RP_BURN_UNTIL :string = "LOTM_RP_BURN_UNTIL";
local LOTM_RP_BURN_OWNER :string = "LOTM_RP_BURN_OWNER";
local LOTM_RP_BURN_REVISION :string = "LOTM_RP_BURN_REVISION";
local LOTM_RESCUE_ARSON_DAMAGE :string = "LOTM_RESCUE_PHASE9_ARSON_DAMAGE";

local function Log(message :string)
	print("[LOTM_RP][Arson] " .. message);
end

local function Reject(ownerID :number, unitID :number, reason :string)
	Log("ERROR rejected command owner=" .. tostring(ownerID)
		.. " unit=" .. tostring(unitID)
		.. " reason=" .. reason);
	return false;
end

local function IsRescueMode()
	return (tonumber(Game.GetProperty("LOTM_RESCUE_MODE") or 0) or 0) == 1;
end

local function GetHeroTypeIndex()
	local definition = GameInfo.Units[LOTM_RP_HERO_TYPE];
	return definition ~= nil and definition.Index or -1;
end

local function GetIntegerParameter(parameters :table, key)
	if parameters == nil then
		return nil;
	end
	local value = tonumber(parameters[key]);
	if value == nil or value ~= math.floor(value) then
		return nil;
	end
	return value;
end

local function IsEnemyUnit(ownerID :number, targetUnit)
	if targetUnit == nil
		or targetUnit:IsDead()
		or targetUnit:IsDelayedDeath()
		or targetUnit:GetOwner() == ownerID then
		return false;
	end
	local player = Players[ownerID];
	local diplomacy = player ~= nil and player:GetDiplomacy() or nil;
	return diplomacy ~= nil and diplomacy:IsAtWarWith(targetUnit:GetOwner());
end

local function IsGodUnit(targetUnit)
	return targetUnit ~= nil
		and (tonumber(targetUnit:GetProperty("LOTM_RESCUE_PHASE10_IS_GOD") or 0) or 0) == 1;
end

local function HasEnemyUnit(ownerID :number, plot)
	for _, targetUnit in ipairs(Units.GetUnitsInPlot(plot)) do
		if IsEnemyUnit(ownerID, targetUnit)
			and (not IsRescueMode() or not IsGodUnit(targetUnit)) then
			return true;
		end
	end
	return false;
end

local function IsLegalTarget(ownerID :number, unit, plot)
	if plot == nil then
		return false, "missing target plot";
	end
	if plot:IsWater() then
		return false, "target is water";
	end
	if plot:IsCity() then
		return false, "target is a city center";
	end
	if Map.GetPlotDistance(unit:GetX(), unit:GetY(), plot:GetX(), plot:GetY())
		> LOTM_RP_ARSON_RANGE then
		return false, "target is outside range";
	end
	local visibility = PlayersVisibility[ownerID];
	if visibility == nil or not visibility:IsVisible(plot:GetIndex()) then
		return false, "target is not currently visible";
	end
	if not HasEnemyUnit(ownerID, plot) then
		return false, "target has no enemy unit";
	end
	return true, nil;
end

local function MarkBurning(plot, ownerID :number, currentTurn :number)
	plot:SetProperty(LOTM_RP_BURN_STARTED_AT, currentTurn);
	plot:SetProperty(LOTM_RP_BURN_UNTIL, currentTurn + LOTM_RP_BURN_DURATION);
	plot:SetProperty(LOTM_RP_BURN_OWNER, ownerID);
	Game:SetProperty(
		LOTM_RP_BURN_REVISION,
		(Game:GetProperty(LOTM_RP_BURN_REVISION) or 0) + 1
	);
end

local function KillEnemyUnits(ownerID :number, plot)
	local targets = {};
	for _, targetUnit in ipairs(Units.GetUnitsInPlot(plot)) do
		if IsEnemyUnit(ownerID, targetUnit) then
			table.insert(targets, targetUnit);
		end
	end
	-- Units.GetUnitsInPlot does not promise a network-stable iteration order.
	-- Killing in owner/unit-ID order preserves the exact same targets and
	-- effects while making any downstream death events deterministic.
	table.sort(targets, function(left, right)
		if left:GetOwner() ~= right:GetOwner() then
			return left:GetOwner() < right:GetOwner();
		end
		return left:GetID() < right:GetID();
	end);
	for _, targetUnit in ipairs(targets) do
		UnitManager.Kill(targetUnit);
	end
	return #targets;
end

local function DamageEnemyUnits(ownerID :number, plot, amount :number)
	local targets = {};
	for _, targetUnit in ipairs(Units.GetUnitsInPlot(plot)) do
		if IsEnemyUnit(ownerID, targetUnit) and not IsGodUnit(targetUnit) then table.insert(targets, targetUnit); end
	end
	table.sort(targets, function(left, right)
		if left:GetOwner() ~= right:GetOwner() then return left:GetOwner() < right:GetOwner(); end
		return left:GetID() < right:GetID();
	end);
	local killed = 0;
	for _, targetUnit in ipairs(targets) do
		targetUnit:ChangeDamage(amount);
		if targetUnit:IsDead() or targetUnit:IsDelayedDeath() then killed = killed + 1; end
	end
	return #targets, killed;
end

local function AddSuccessWorldText(plot)
	-- Firaxis Gameplay scripts use the four-argument signature.  Keeping this
	-- on the authoritative command path means every client receives the same
	-- activation before rendering its local flyover text.
	if LOTM_MP_TurnSync.IsNetworkGame() then
		local ok,details=pcall(function()
			Game.AddWorldViewText(
				0,
				Locale.Lookup("LOC_LOTM_RP_ARSON_SUCCESS"),
				plot:GetX(),
				plot:GetY()
			);
		end);
		if not ok then
			Log("network arson world text skipped after Gameplay commit error="..tostring(details));
		end
		return;
	end
	Game.AddWorldViewText(
		0,
		Locale.Lookup("LOC_LOTM_RP_ARSON_SUCCESS"),
		plot:GetX(),
		plot:GetY()
	);
end

local function OnCommandArson(
	ownerID :number,
	unitID :number,
	parameters :table
)
	if not LOTM_RP_State.IsEnabledPlayer(ownerID) then
		return Reject(ownerID, unitID, "player is not an enabled path player");
	end

	local player = Players[ownerID];
	if player == nil then
		return Reject(ownerID, unitID, "missing player");
	end
	if not player:IsTurnActive() then
		return Reject(ownerID, unitID, "player turn is not active");
	end
	local unit = player:GetUnits():FindID(unitID);
	if unit == nil
		or unit:IsDead()
		or unit:IsDelayedDeath()
		or unit:GetType() ~= GetHeroTypeIndex() then
		return Reject(ownerID, unitID, "unit is not a living path hero");
	end
	if (player:GetProperty(LOTM_RP_UNIT_ID_PROPERTY) or -1) ~= unitID then
		return Reject(ownerID, unitID, "unit is not the registered hero");
	end
	if (player:GetProperty(LOTM_RP_SEQUENCE_PROPERTY) or 9) > 7 then
		return Reject(ownerID, unitID, "player has not reached sequence 7");
	end

	local currentTurn = Game.GetCurrentGameTurn();
	local readyAt = player:GetProperty(LOTM_RP_ARSON_READY_AT_PROPERTY) or -1;
	if readyAt >= 0 and currentTurn < readyAt then
		return Reject(ownerID, unitID, "cooldown ready at turn " .. tostring(readyAt));
	end
	local rescueDamage = tonumber(Game.GetProperty(LOTM_RESCUE_ARSON_DAMAGE) or 0) or 0;
	if IsRescueMode() and rescueDamage <= 0 then
		return Reject(ownerID, unitID, "rescue direct-damage value is pending");
	end

	local targetX = GetIntegerParameter(parameters, UnitCommandTypes.PARAM_X);
	local targetY = GetIntegerParameter(parameters, UnitCommandTypes.PARAM_Y);
	if targetX == nil or targetY == nil then
		return Reject(ownerID, unitID, "missing or non-integer target coordinates");
	end
	local plot = Map.GetPlot(targetX, targetY);
	local isLegal, reason = IsLegalTarget(ownerID, unit, plot);
	if not isLegal then
		return Reject(ownerID, unitID, reason);
	end

	if IsRescueMode() then
		local damagedCount, killedCount = DamageEnemyUnits(ownerID, plot, rescueDamage);
		player:SetProperty(LOTM_RP_ARSON_READY_AT_PROPERTY,currentTurn + LOTM_RP_ARSON_COOLDOWN);
		LOTM_RP_State.TryAddDigestion(ownerID,"A","RESCUE_P9:ARSON_DAMAGE:"..tostring(currentTurn)..":"..tostring(unitID)..":"..tostring(plot:GetIndex()));
		if killedCount > 0 then
			LOTM_RP_State.TryAddDigestion(ownerID,"B","RESCUE_P9:ARSON_KILL:"..tostring(currentTurn)..":"..tostring(unitID)..":"..tostring(plot:GetIndex()));
		end
		AddSuccessWorldText(plot);
		Log("executed rescue direct damage owner="..tostring(ownerID).." unit="..tostring(unitID).." plot="..tostring(plot:GetIndex()).." damagedEnemyUnits="..tostring(damagedCount).." killedEnemyUnits="..tostring(killedCount).." amount="..tostring(rescueDamage).." readyAt="..tostring(currentTurn + LOTM_RP_ARSON_COOLDOWN));
		return true;
	end

	local killedCount = KillEnemyUnits(ownerID, plot);
	UnitManager.FinishMoves(unit);
	player:SetProperty(
		LOTM_RP_ARSON_READY_AT_PROPERTY,
		currentTurn + LOTM_RP_ARSON_COOLDOWN
	);
	MarkBurning(plot, ownerID, currentTurn);
	LOTM_RP_State.TryAddDigestion(
		ownerID,
		"A",
		"ARSON:" .. tostring(currentTurn)
			.. ":" .. tostring(unitID)
			.. ":" .. tostring(plot:GetIndex())
	);
	AddSuccessWorldText(plot);

	Log("executed owner=" .. tostring(ownerID)
		.. " unit=" .. tostring(unitID)
		.. " plot=" .. tostring(plot:GetIndex())
		.. " killedEnemyUnits=" .. tostring(killedCount)
		.. " readyAt=" .. tostring(currentTurn + LOTM_RP_ARSON_COOLDOWN));
	return true;
end

local function OnPillage(
	playerID :number,
	unitID :number,
	improvementType :number,
	buildingType :number,
	districtType :number,
	plotIndex :number
)
	if not LOTM_RP_State.IsEnabledPlayer(playerID)
		or LOTM_RP_State.GetSequence(playerID) > 7 then
		return;
	end
	local player = Players[playerID];
	local unit = player ~= nil and player:GetUnits():FindID(unitID) or nil;
	if unit == nil
		or unit:IsDead()
		or unit:IsDelayedDeath()
		or unit:GetType() ~= GetHeroTypeIndex()
		or (player:GetProperty(LOTM_RP_UNIT_ID_PROPERTY) or -1) ~= unitID then
		return;
	end

	local currentTurn = Game.GetCurrentGameTurn();

	LOTM_RP_State.TryAddDigestion(
		playerID,
		"B",
		"PILLAGE:" .. tostring(currentTurn)
			.. ":" .. tostring(unitID)
			.. ":" .. tostring(plotIndex)
			.. ":" .. tostring(improvementType)
			.. ":" .. tostring(buildingType)
			.. ":" .. tostring(districtType)
	);
end

local function CleanupExpiredBurning()
	local currentTurn = Game.GetCurrentGameTurn();
	local changed = false;
	for plotIndex = 0, Map.GetPlotCount() - 1 do
		local plot = Map.GetPlotByIndex(plotIndex);
		local burnUntil = plot ~= nil and plot:GetProperty(LOTM_RP_BURN_UNTIL) or nil;
		if burnUntil ~= nil and currentTurn >= burnUntil then
			plot:SetProperty(LOTM_RP_BURN_STARTED_AT, nil);
			plot:SetProperty(LOTM_RP_BURN_UNTIL, nil);
			plot:SetProperty(LOTM_RP_BURN_OWNER, nil);
			changed = true;
		end

	end
	if changed then
		Game:SetProperty(
			LOTM_RP_BURN_REVISION,
			(Game:GetProperty(LOTM_RP_BURN_REVISION) or 0) + 1
		);
	end
end

local function OnPlayerTurnActivated(playerID :number, isFirstTimeThisTurn :boolean)
	if isFirstTimeThisTurn then
		CleanupExpiredBurning();
	end
end

local function Initialize()
	GameEvents.LOTM_RP_Command_Arson.Add(OnCommandArson);
	GameEvents.OnPillage.Add(OnPillage);
	LOTM_MP_TurnSync.Add(OnPlayerTurnActivated,"Arson");
	LOTM_MP_TurnSync.RunStartup(function()
		if Game:GetProperty(LOTM_RP_BURN_REVISION) == nil then
			Game:SetProperty(LOTM_RP_BURN_REVISION, 0);
		end
		CleanupExpiredBurning();
	end,"Arson");
	Log("initialized command=" .. LOTM_RP_COMMAND_NAME);
end

Initialize();
