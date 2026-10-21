-- rc.82 synchronized uncontrolled monsters. UI is deliberately not authoritative.
include("LOTM_Effects");
LOTM_WORLD_Monsters = LOTM_WORLD_Monsters or {};

local TIER_CHANCE={[2]=30,[1]=30,[0]=30};
local TIER_BONUS={[2]=15,[1]=25,[0]=35};
local TIER_MOVES={[2]=3,[1]=4,[0]=4};
local TIER_HEAL={[2]=10,[1]=10,[0]=10};
local REWARD_GOLD_PER_ERA :number=500;
local TIER_NAME={[2]="LOC_LOTM_WORLD_MONSTER_LOW_NAME",[1]="LOC_LOTM_WORLD_MONSTER_MID_NAME",[0]="LOC_LOTM_WORLD_MONSTER_HIGH_NAME"};
local MAP_CAP={MAPSIZE_DUEL=1,MAPSIZE_TINY=2,MAPSIZE_SMALL=2,MAPSIZE_STANDARD=3,MAPSIZE_LARGE=4,MAPSIZE_HUGE=5};
local STRENGTH_ABILITY="ABILITY_LOTM_WORLD_MONSTER_FRENZY_STRENGTH_V2";
local TIER_STRENGTH_ABILITIES={{1,"ABILITY_LOTM_WORLD_MONSTER_TIER_MID_STRENGTH"},{0,"ABILITY_LOTM_WORLD_MONSTER_TIER_HIGH_STRENGTH"}};
local LEGACY_STRENGTH_ABILITY="ABILITY_LOTM_WORLD_DYNAMIC_STRENGTH";
local LEGACY_FRENZY_ABILITY="ABILITY_LOTM_WORLD_MONSTER_FRENZY_STRENGTH";
local MOVEMENT_ABILITIES={{1,"ABILITY_LOTM_WORLD_DYNAMIC_MOVEMENT"},{2,"ABILITY_LOTM_WORLD_DYNAMIC_MOVEMENT_2"}};
local RESCUE_WEATHER_ABILITY="ABILITY_LOTM_RESCUE_WEATHER_MONSTER_DEBUFF";
local EFFECT_VERSION_PROPERTY="LOTM_WORLD_MONSTER_EFFECT_VERSION";
local CURRENT_EFFECT_VERSION=7;
local MONSTER_TIER="LOTM_WORLD_MONSTER_TIER";
local MONSTER_SERIAL="LOTM_WORLD_MONSTER_SERIAL";
local MONSTER_SOURCE="LOTM_WORLD_MONSTER_SOURCE_WORKSHOP";
local MONSTER_SOURCE_CAMP_EPOCH="LOTM_WORLD_MONSTER_SOURCE_CAMP_EPOCH";
local PERIOD_BONUS_PROPERTY="LOTM_RESCUE_PHASE5_BIRTH_BONUS";
local TARGET_KIND_PROPERTY="LOTM_WORLD_MONSTER_LOCKED_TARGET_KIND";
local TARGET_OWNER_PROPERTY="LOTM_WORLD_MONSTER_LOCKED_TARGET_OWNER";
local TARGET_ID_PROPERTY="LOTM_WORLD_MONSTER_LOCKED_TARGET_ID";
local REDEPLOYED_TURN_PROPERTY="LOTM_WORLD_MONSTER_REDEPLOYED_TURN";
local REDEPLOY_DISTANCE=12;
local REDEPLOY_TARGET_MIN_DISTANCE=5;
local REDEPLOY_TARGET_MAX_DISTANCE=12;
local PERIOD_STRENGTH_ABILITIES={
	{10,"ABILITY_LOTM_RESCUE_PERIOD_STRENGTH_10"},
	{20,"ABILITY_LOTM_RESCUE_PERIOD_STRENGTH_20"},
	{30,"ABILITY_LOTM_RESCUE_PERIOD_STRENGTH_30"},
	{40,"ABILITY_LOTM_RESCUE_PERIOD_STRENGTH_40"}
};
local questResolver=nil;
local creatingMonster=false;
local playerHuntCacheTurn=-1;
local playerHuntCache=false;
local CAMP=GameInfo.Improvements.IMPROVEMENT_BARBARIAN_CAMP.Index;
-- UnitRemovedFromMap is only a local publication callback in a network game.
-- It may collect evidence, but Release/SettleReward must wait for the one
-- synchronized, lowest-major turn boundary shared by every peer.
local networkRemovalQueue={};
local networkRemovalBySerial={};
local ACTIVE_MONSTER_SERIALS="LOTM_WORLD_MONSTER_ACTIVE_SERIALS";
local ACTIVE_MONSTER_INDEX_VERSION="LOTM_WORLD_MONSTER_ACTIVE_INDEX_VERSION";
local CURRENT_ACTIVE_MONSTER_INDEX_VERSION=1;

local function Log(message)
	print("[LOTM_WORLD][Monsters] "..tostring(message));
end
local function Verbose()
	return tonumber(Game.GetProperty("LOTM_RESCUE_VERBOSE_LOGS") or 0)==1;
end
local function Trace(message)
	if Verbose() then Log(message); end
end

local function BarbarianID()
	for _,player in ipairs(PlayerManager.GetAliveBarbarians()) do return player:GetID(); end
	return -1;
end

local function NumberProperty(object,key,default)
	return LOTM_WORLD_State.NumberProperty(object,key,default);
end
local function RescueActive()
	return LOTM_RESCUE_Phase5~=nil and LOTM_RESCUE_Phase5.IsActive~=nil and LOTM_RESCUE_Phase5.IsActive();
end
local function MonsterChance(tier)
	return RescueActive() and LOTM_RESCUE_Phase5.MonsterChance() or TIER_CHANCE[tier];
end
local function MonsterCooldown()
	return RescueActive() and LOTM_RESCUE_Phase5.MonsterCooldown() or 10;
end
local function MonsterPerWorkshopCap()
	return RescueActive() and LOTM_RESCUE_Phase5.MonsterPerWorkshopCap() or 1;
end
local function MonsterBurst()
	return RescueActive() and LOTM_RESCUE_Phase5.MonsterBurst~=nil and LOTM_RESCUE_Phase5.MonsterBurst() or 1;
end
local function BirthPeriodBonus()
	return RescueActive() and LOTM_RESCUE_Phase5.BirthStrengthBonus() or 0;
end

local function IncrementProperty(object,key)
	local value=NumberProperty(object,key,0)+1;
	object:SetProperty(key,value);
	return value;
end

local function IncrementGame(key)
	local value=LOTM_WORLD_State.NumberGameProperty(key,0)+1;
	Game.SetProperty(key,value);
	return value;
end

local function EngineKey(ownerID,unitID)
	return "LOTM_WORLD_MONSTER_ENGINE:"..tostring(ownerID)..":"..tostring(unitID);
end

local function MetaKey(serial,suffix)
	return "LOTM_WORLD_MONSTER:"..tostring(serial)..":"..suffix;
end

local function ActiveMonsterSerials()
	local result={}; local seen={};
	for token in string.gmatch(tostring(Game.GetProperty(ACTIVE_MONSTER_SERIALS) or ""),"[^,]+") do
		local serial=tonumber(token);
		if serial~=nil and serial>0 and not seen[serial] then
			seen[serial]=true; result[#result+1]=serial;
		end
	end
	table.sort(result);
	return result;
end

local function SaveActiveMonsterSerials(serials)
	local values={};
	for _,serial in ipairs(serials) do values[#values+1]=tostring(serial); end
	local serialized=table.concat(values,",");
	if tostring(Game.GetProperty(ACTIVE_MONSTER_SERIALS) or "")~=serialized then
		Game.SetProperty(ACTIVE_MONSTER_SERIALS,serialized);
	end
end

local function SetPropertyIfChanged(object,key,value)
	if object~=nil and object:GetProperty(key)~=value then object:SetProperty(key,value); end
end

local function RegisterActiveMonsterSerial(serial)
	local normalized=tonumber(serial); if normalized==nil or normalized<=0 then return; end
	local serials=ActiveMonsterSerials(); local found=false;
	for _,value in ipairs(serials) do if value==normalized then found=true; break; end end
	if not found then serials[#serials+1]=normalized; table.sort(serials); SaveActiveMonsterSerials(serials); end
end

local function RemoveActiveMonsterSerial(serial)
	local normalized=tonumber(serial); if normalized==nil or normalized<=0 then return; end
	local remaining={};
	for _,value in ipairs(ActiveMonsterSerials()) do
		if value~=normalized then remaining[#remaining+1]=value; end
	end
	SaveActiveMonsterSerials(remaining);
end

local function MigrateActiveMonsterIndex()
	if LOTM_WORLD_State.NumberGameProperty(ACTIVE_MONSTER_INDEX_VERSION,0)>=CURRENT_ACTIVE_MONSTER_INDEX_VERSION then return; end
	local serials=ActiveMonsterSerials(); local seen={};
	for _,serial in ipairs(serials) do seen[serial]=true; end
	local lastSerial=math.max(0,LOTM_WORLD_State.NumberGameProperty("LOTM_WORLD_MONSTER_NEXT_SERIAL",0));
	for serial=1,lastSerial do
		if LOTM_WORLD_State.NumberGameProperty(MetaKey(serial,"LIVE"),0)==1 and not seen[serial] then
			seen[serial]=true; serials[#serials+1]=serial;
		end
	end
	table.sort(serials); SaveActiveMonsterSerials(serials);
	Game.SetProperty(ACTIVE_MONSTER_INDEX_VERSION,CURRENT_ACTIVE_MONSTER_INDEX_VERSION);
	Log("active index migrated version="..CURRENT_ACTIVE_MONSTER_INDEX_VERSION.." scannedSerials="..lastSerial.." active="..#serials);
end

local function CurrentEraIndex()
	if Game.GetEras==nil then return 0; end
	local eras=Game.GetEras();
	if eras==nil or eras.GetCurrentEra==nil then return 0; end
	local currentEra=eras:GetCurrentEra();
	return tonumber(currentEra) or 0;
end

local function IsLegalWilderness(plot,requireEmpty)
	if plot==nil or plot:IsWater() or plot:GetOwner()>=0 or plot:IsCity() then return false; end
	if plot:GetDistrictType()>=0 then return false; end
	if requireEmpty and plot:GetUnitCount()>0 then return false; end
	return true;
end

local function MapCap()
	local mapInfo=GameInfo.Maps[Map.GetMapSize()];
	local mapSizeType=mapInfo~=nil and mapInfo.MapSizeType or "MAPSIZE_STANDARD";
	if RescueActive() and LOTM_RESCUE_Phase5.MonsterGlobalCap~=nil then return LOTM_RESCUE_Phase5.MonsterGlobalCap(),mapSizeType; end
	local base=MAP_CAP[mapSizeType] or 3;
	local multiplier=RescueActive() and LOTM_RESCUE_Phase5.GlobalCapMultiplier() or 1;
	return math.max(1,math.floor(base*multiplier)),mapSizeType;
end

function LOTM_WORLD_Monsters.IsMonster(unit)
	return unit~=nil and NumberProperty(unit,MONSTER_TIER,-1)>=0 and NumberProperty(unit,MONSTER_SERIAL,0)>0;
end

function LOTM_WORLD_Monsters.IsCreating()
	return creatingMonster;
end

function LOTM_WORLD_Monsters.RegisterQuestResolver(callback)
	questResolver=type(callback)=="function" and callback or nil;
end

local function ApplyAbilityCount(unit,abilityType,desired)
	if GameInfo.UnitAbilities[abilityType]==nil then return desired==0; end
	local ability=unit~=nil and unit:GetAbility() or nil;
	if ability==nil then return false; end
	LOTM_Effects.SetAbilityCount(ability,abilityType,desired);
	return (ability:GetAbilityCount(abilityType) or 0)==desired;
end

local function ApplyMonsterAbilities(unit,tier,moveDelta,periodBonus)
	if NumberProperty(unit,EFFECT_VERSION_PROPERTY,0)<CURRENT_EFFECT_VERSION then
		local ability=unit~=nil and unit:GetAbility() or nil;
		if ability~=nil then
			local rebuild={LEGACY_STRENGTH_ABILITY,LEGACY_FRENZY_ABILITY,STRENGTH_ABILITY,TIER_STRENGTH_ABILITIES[1][2],TIER_STRENGTH_ABILITIES[2][2],MOVEMENT_ABILITIES[1][2],MOVEMENT_ABILITIES[2][2],PERIOD_STRENGTH_ABILITIES[1][2],PERIOD_STRENGTH_ABILITIES[2][2],PERIOD_STRENGTH_ABILITIES[3][2],PERIOD_STRENGTH_ABILITIES[4][2],RESCUE_WEATHER_ABILITY};
			for _,abilityType in ipairs(rebuild) do
				if GameInfo.UnitAbilities[abilityType]~=nil then LOTM_Effects.SetAbilityCount(ability,abilityType,0); end
			end
		end
		unit:SetProperty(TARGET_KIND_PROPERTY,nil); unit:SetProperty(TARGET_OWNER_PROPERTY,nil); unit:SetProperty(TARGET_ID_PROPERTY,nil);
		unit:SetProperty(EFFECT_VERSION_PROPERTY,CURRENT_EFFECT_VERSION);
		Log("rebuilt effects serial="..NumberProperty(unit,MONSTER_SERIAL,0).." version="..CURRENT_EFFECT_VERSION);
	end
	ApplyAbilityCount(unit,STRENGTH_ABILITY,1);
	for _,entry in ipairs(TIER_STRENGTH_ABILITIES) do
		ApplyAbilityCount(unit,entry[2],entry[1]==tier and 1 or 0);
	end
	for _,entry in ipairs(MOVEMENT_ABILITIES) do
		ApplyAbilityCount(unit,entry[2],entry[1]==moveDelta and 1 or 0);
	end
	for _,entry in ipairs(PERIOD_STRENGTH_ABILITIES) do
		ApplyAbilityCount(unit,entry[2],entry[1]==periodBonus and 1 or 0);
	end
	ApplyAbilityCount(unit,RESCUE_WEATHER_ABILITY,RescueActive() and NumberProperty(Game,"LOTM_RESCUE_ARTIFACT_WEATHER_ACTIVE",0)==1 and 1 or 0);
	if LOTM_RESCUE_RuntimeEvents~=nil then LOTM_RESCUE_RuntimeEvents.ApplyEarlySeal(unit); end
end

local function LiveMonsters()
	local result={};
	local activeSerials=ActiveMonsterSerials(); local activeSeen={};
	for _,serial in ipairs(activeSerials) do activeSeen[serial]=true; end
	local barbarianID=BarbarianID();
	local player=barbarianID>=0 and Players[barbarianID] or nil;
	if player==nil then return result; end
	for _,unit in player:GetUnits():Members() do
		if LOTM_WORLD_Monsters.IsMonster(unit) then
			table.insert(result,unit);
			local serial=NumberProperty(unit,MONSTER_SERIAL,0);
			local tier=NumberProperty(unit,MONSTER_TIER,2);
			local source=NumberProperty(unit,MONSTER_SOURCE,-1);
			local baseline=NumberProperty(unit,"LOTM_WORLD_MONSTER_BASELINE",0);
			SetPropertyIfChanged(Game,MetaKey(serial,"LIVE"),1);
			SetPropertyIfChanged(Game,MetaKey(serial,"OWNER"),unit:GetOwner());
			SetPropertyIfChanged(Game,MetaKey(serial,"UNIT_ID"),unit:GetID());
			SetPropertyIfChanged(Game,MetaKey(serial,"TIER"),tier);
			SetPropertyIfChanged(Game,MetaKey(serial,"SOURCE"),source);
			SetPropertyIfChanged(Game,MetaKey(serial,"BASELINE"),baseline);
			local sourceEpoch=unit:GetProperty(MONSTER_SOURCE_CAMP_EPOCH);
			if sourceEpoch~=nil then SetPropertyIfChanged(Game,MetaKey(serial,"SOURCE_CAMP_EPOCH"),sourceEpoch); end
			SetPropertyIfChanged(Game,EngineKey(unit:GetOwner(),unit:GetID()),serial);
			if not activeSeen[serial] then activeSeen[serial]=true; activeSerials[#activeSerials+1]=serial; end
		end
	end
	table.sort(result,function(a,b) return NumberProperty(a,MONSTER_SERIAL,0)<NumberProperty(b,MONSTER_SERIAL,0); end);
	table.sort(activeSerials); SaveActiveMonsterSerials(activeSerials);
	SetPropertyIfChanged(Game,"LOTM_WORLD_MONSTER_LIVE_COUNT",#result);
	return result;
end

local function FindSpawnPlot(camp)
	local maximumRadius=RescueActive() and 3 or 2;
	for radius=1,maximumRadius do
		local candidates={};
		for dx=-radius,radius do for dy=-radius,radius do
			local plot=Map.GetPlotXYWithRangeCheck(camp:GetX(),camp:GetY(),dx,dy,radius);
			if IsLegalWilderness(plot,true) and plot:GetImprovementType()<0 then table.insert(candidates,plot); end
		end end
		table.sort(candidates,function(a,b) return a:GetIndex()<b:GetIndex(); end);
		if #candidates>0 then return candidates[1]; end
	end
	return nil;
end

local function Suppress(camp,tier,reason)
	IncrementProperty(camp,"LOTM_WORLD_MONSTER_SUPPRESSED_"..reason);
	IncrementGame("LOTM_WORLD_MONSTER_TIER_"..tier.."_SUPPRESSED_"..reason);
	if reason=="NO_PLOT" or reason=="NO_BASELINE" or reason=="INIT_FAILED" then
		Log("check suppressed reason="..reason.." tier="..tier.." camp="..camp:GetIndex());
	else
		Trace("check suppressed reason="..reason.." tier="..tier.." camp="..camp:GetIndex());
	end
	return false,reason;
end
local function LiveFromWorkshop(live,campIndex)
	local count=0;
	for _,unit in ipairs(live) do if NumberProperty(unit,MONSTER_SOURCE,-1)==campIndex then count=count+1; end end
	return count;
end

local function TrySpawnOne(camp,sourceUnit,periodic,networkSourceOwner,batch)
	if camp==nil or camp:GetImprovementType()~=CAMP or NumberProperty(camp,"LOTM_PP_WORKSHOP_IS_WORKSHOP",0)~=1 then return false,"INVALID"; end
	if not periodic then
		if sourceUnit==nil and networkSourceOwner==nil then return false,"INVALID"; end
		if sourceUnit~=nil then
			if LOTM_WORLD_Monsters.IsMonster(sourceUnit) or NumberProperty(sourceUnit,"LOTM_PP_WORKSHOP_EXTRA",0)==1 or NumberProperty(sourceUnit,"LOTM_PP_WORKSHOP_SEQUENCE",0)==1 then return false,"NOT_NORMAL"; end
			if NumberProperty(sourceUnit,"LOTM_PP_WORKSHOP_SOURCE",-1)~=camp:GetIndex() then return false,"SOURCE_MISMATCH"; end
		end
	end
	local tier=NumberProperty(camp,"LOTM_PP_WORKSHOP_LEVEL",2);
	if TIER_CHANCE[tier]==nil then tier=2; end
	local turn=Game.GetCurrentGameTurn();
	if turn<NumberProperty(camp,"LOTM_WORLD_WORKSHOP_MONSTER_COOLDOWN_UNTIL",-1) then return Suppress(camp,tier,"COOLDOWN"); end
	local live=batch~=nil and batch.Live or LiveMonsters(); local cap=batch~=nil and batch.Cap or MapCap();
	if #live>=cap then return Suppress(camp,tier,"CAP"); end
	local sourceLive=LiveFromWorkshop(live,camp:GetIndex()); local sourceCap=MonsterPerWorkshopCap();
	if sourceLive>=sourceCap then return Suppress(camp,tier,"LIVE"); end
	local spawnPlot=FindSpawnPlot(camp);
	if spawnPlot==nil then return Suppress(camp,tier,"NO_PLOT"); end
	local ownerID=periodic and BarbarianID() or (sourceUnit~=nil and sourceUnit:GetOwner() or networkSourceOwner);
	local baseline=batch~=nil and batch.Baseline or LOTM_WORLD_Barbarians.ResolveMeleeBaseline(ownerID);
	if baseline==nil then return Suppress(camp,tier,"NO_BASELINE"); end
	local rollOrdinal=IncrementProperty(camp,"LOTM_WORLD_MONSTER_ELIGIBLE_CHECKS");
	IncrementGame("LOTM_WORLD_MONSTER_TIER_"..tier.."_ELIGIBLE_CHECKS");
	local roll=LOTM_WORLD_State.Random(100,"monster tier="..tier
		.." camp="..camp:GetIndex().." ordinal="..tostring(rollOrdinal)
		.." periodic="..tostring(periodic==true));
	camp:SetProperty("LOTM_WORLD_MONSTER_LAST_ROLL",roll);
	IncrementProperty(camp,"LOTM_WORLD_MONSTER_ROLLS");
	IncrementGame("LOTM_WORLD_MONSTER_TIER_"..tier.."_ROLLS");
	local chance=MonsterChance(tier);
	Trace("roll tier="..tier.." camp="..camp:GetIndex().." value="..roll.." chance="..chance.." sourceLive="..sourceLive.." sourceCap="..sourceCap.." globalCap="..cap);
	if roll>=chance then return false,"ROLL_MISS"; end
	IncrementProperty(camp,"LOTM_WORLD_MONSTER_ROLL_HITS");
	IncrementGame("LOTM_WORLD_MONSTER_TIER_"..tier.."_ROLL_HITS");
	creatingMonster=true;
	local initOK,unit=pcall(UnitManager.InitUnit,ownerID,baseline.Index,spawnPlot:GetX(),spawnPlot:GetY());
	creatingMonster=false;
	if not initOK then unit=nil; end
	if unit==nil then return Suppress(camp,tier,"INIT_FAILED"); end
	local serial=IncrementGame("LOTM_WORLD_MONSTER_NEXT_SERIAL");
	local periodBonus=BirthPeriodBonus();
	local targetStrength=baseline.Combat+TIER_BONUS[tier]+periodBonus;
	local strengthDelta=math.max(0,targetStrength-(tonumber(GameInfo.Units[unit:GetType()].Combat) or baseline.Combat));
	local moveDelta=math.max(0,TIER_MOVES[tier]-(tonumber(GameInfo.Units[unit:GetType()].BaseMoves) or baseline.BaseMoves));
	local sourceCampEpoch=camp:GetProperty("LOTM_PP_WORKSHOP_CAMP_EPOCH");
	unit:SetProperty(MONSTER_TIER,tier); unit:SetProperty(MONSTER_SERIAL,serial); unit:SetProperty(MONSTER_SOURCE,camp:GetIndex()); unit:SetProperty(PERIOD_BONUS_PROPERTY,periodBonus);
	if sourceCampEpoch~=nil then unit:SetProperty(MONSTER_SOURCE_CAMP_EPOCH,sourceCampEpoch); end
	unit:SetProperty("LOTM_WORLD_MONSTER_BASELINE",baseline.Combat); unit:SetProperty("LOTM_WORLD_MONSTER_UNIT_TYPE",baseline.UnitType);
	unit:SetProperty("LOTM_WORLD_MONSTER_TARGET_STRENGTH",targetStrength); unit:SetProperty("LOTM_WORLD_MONSTER_TARGET_MOVES",TIER_MOVES[tier]);
	-- Commit the recoverable identity before optional cross-module, ability, or
	-- presentation work. LiveMonsters can reconstruct every core field from the
	-- unit if an interruption occurs after this point.
	camp:SetProperty("LOTM_WORLD_WORKSHOP_MONSTER_SERIAL",serial);
	Game.SetProperty(MetaKey(serial,"LIVE"),1); Game.SetProperty(MetaKey(serial,"OWNER"),unit:GetOwner()); Game.SetProperty(MetaKey(serial,"UNIT_ID"),unit:GetID());
	Game.SetProperty(MetaKey(serial,"TIER"),tier); Game.SetProperty(MetaKey(serial,"SOURCE"),camp:GetIndex()); Game.SetProperty(MetaKey(serial,"BASELINE"),baseline.Combat);
	if sourceCampEpoch~=nil then Game.SetProperty(MetaKey(serial,"SOURCE_CAMP_EPOCH"),sourceCampEpoch); end
	Game.SetProperty(EngineKey(unit:GetOwner(),unit:GetID()),serial);
	if batch~=nil then
		batch.Live[#batch.Live+1]=unit;
		if not batch.ActiveSeen[serial] then batch.ActiveSeen[serial]=true; batch.ActiveSerials[#batch.ActiveSerials+1]=serial; end
	else
		RegisterActiveMonsterSerial(serial);
	end
	-- InitUnit publishes UnitAddedToMap before it returns.  Backfill the
	-- already-enqueued Workshops evidence as soon as this durable monster
	-- identity exists, without relying on the client-local IsCreating flag.
	if LOTM_PP_Workshops~=nil and type(LOTM_PP_Workshops.MarkNetworkUnitFiltered)=="function" then
		LOTM_PP_Workshops.MarkNetworkUnitFiltered(unit);
	end
	ApplyMonsterAbilities(unit,tier,moveDelta,periodBonus);
	local experience=unit:GetExperience(); if experience~=nil then
		experience:SetExperienceLocked(true);
		local veteranName=LOTM_MP_TurnSync.IsNetworkGame() and ("LOTM_WORLD_MONSTER_"..tostring(tier)) or Locale.Lookup(TIER_NAME[tier]);
		experience:SetVeteranName(veteranName);
	end
	IncrementProperty(camp,"LOTM_WORLD_MONSTER_SPAWNED"); IncrementGame("LOTM_WORLD_MONSTER_TIER_"..tier.."_SPAWNED");
	if batch==nil then SetPropertyIfChanged(Game,"LOTM_WORLD_MONSTER_LIVE_COUNT",#live+1); end
	UnitManager.FinishMoves(unit);
	Log("spawned serial="..serial.." tier="..tier.." camp="..camp:GetIndex().." unit="..baseline.UnitType.." B="..baseline.Combat.." periodBonus="..periodBonus.." target="..targetStrength);
	return true,"SPAWNED";
end

function LOTM_WORLD_Monsters.TrySpawnFromWorkshop(camp,sourceUnit)
	local rawBurst=math.max(1,MonsterBurst());
	local burst=RescueActive() and LOTM_RESCUE_Phase5~=nil and LOTM_RESCUE_Phase5.ScaleMonsterSpawnCount~=nil
		and LOTM_RESCUE_Phase5.ScaleMonsterSpawnCount(rawBurst,"WORKSHOP_EVENT",LOTM_RESCUE_Phase5.WorldTurn()) or rawBurst;
	local spawned=0; local lastReason=burst>0 and "NONE" or "RATE_REDUCED";
	for attempt=1,burst do
		local success,reason=TrySpawnOne(camp,sourceUnit,false); lastReason=reason;
		if success then spawned=spawned+1; end
		if reason=="INVALID" or reason=="NOT_NORMAL" or reason=="SOURCE_MISMATCH" or reason=="COOLDOWN" or reason=="CAP" or reason=="LIVE" or reason=="NO_PLOT" or reason=="NO_BASELINE" or reason=="INIT_FAILED" then break; end
	end
	Trace("burst camp="..tostring(camp~=nil and camp:GetIndex() or -1).." raw="..rawBurst.." requested="..burst.." spawned="..spawned.." lastReason="..lastReason);
	return spawned>0,spawned>0 and "SPAWNED_"..spawned or lastReason;
end

-- Network workshop unit callbacks are batched and sorted before they compete
-- for the global monster cap/serial. The source may have died before the next
-- synchronized turn boundary, so the already-validated owner is sufficient.
-- The single-player path above still validates and uses the live source unit.
function LOTM_WORLD_Monsters.TrySpawnFromWorkshopNetwork(camp,sourceOwnerID,eventToken)
	if not LOTM_MP_TurnSync.IsNetworkGame() then return false,"NETWORK_ONLY"; end
	local ownerID=tonumber(sourceOwnerID);
	if ownerID==nil then return false,"INVALID"; end
	local token=tostring(eventToken or "");
	local eventKey=token~="" and ("LOTM_WORLD_MONSTER_WORKSHOP_EVENT:"..token) or nil;
	if eventKey~=nil and Game.GetProperty(eventKey)~=nil then return false,"DUPLICATE_EVENT"; end
	-- Claim before any roll/counter/unit mutation. If an unexpected exception
	-- interrupts the attempt, reload fails closed instead of replaying a partly
	-- applied monster event. Normal completion upgrades the marker to DONE.
	if eventKey~=nil then Game.SetProperty(eventKey,"PREPARED"); end
	local rawBurst=math.max(1,MonsterBurst());
	local burst=RescueActive() and LOTM_RESCUE_Phase5~=nil and LOTM_RESCUE_Phase5.ScaleMonsterSpawnCount~=nil
		and LOTM_RESCUE_Phase5.ScaleMonsterSpawnCount(rawBurst,"WORKSHOP_EVENT",LOTM_RESCUE_Phase5.WorldTurn()) or rawBurst;
	local spawned=0; local lastReason=burst>0 and "NONE" or "RATE_REDUCED";
	for attempt=1,burst do
		local success,reason=TrySpawnOne(camp,nil,false,ownerID); lastReason=reason;
		if success then spawned=spawned+1; end
		if reason=="INVALID" or reason=="COOLDOWN" or reason=="CAP" or reason=="LIVE" or reason=="NO_PLOT" or reason=="NO_BASELINE" or reason=="INIT_FAILED" then break; end
	end
	if eventKey~=nil then Game.SetProperty(eventKey,"DONE"); end
	Trace("network burst camp="..tostring(camp~=nil and camp:GetIndex() or -1).." raw="..rawBurst.." requested="..burst.." spawned="..spawned.." lastReason="..lastReason);
	return spawned>0,spawned>0 and "SPAWNED_"..spawned or lastReason;
end

function LOTM_WORLD_Monsters.RescueTurnSpawn(worldTurn,requested)
	if not RescueActive() then return 0,"INACTIVE"; end
	local turn=tonumber(worldTurn) or 0; local key="LOTM_WORLD_MONSTER_PERIODIC_LAST_TURN";
	if LOTM_WORLD_State.NumberGameProperty(key,-1)==turn then return 0,"DUPLICATE"; end
	Game.SetProperty(key,turn);
	local workshops={};
	for index=0,Map.GetPlotCount()-1 do
		local plot=Map.GetPlotByIndex(index);
		if plot~=nil and plot:GetImprovementType()==CAMP and NumberProperty(plot,"LOTM_PP_WORKSHOP_IS_WORKSHOP",0)==1 then workshops[#workshops+1]=plot; end
	end
	table.sort(workshops,function(a,b) return a:GetIndex()<b:GetIndex(); end);
	local ownerID=BarbarianID(); local live=LiveMonsters(); local activeSerials=ActiveMonsterSerials(); local activeSeen={};
	for _,serial in ipairs(activeSerials) do activeSeen[serial]=true; end
	local batch={Live=live,Cap=MapCap(),Baseline=LOTM_WORLD_Barbarians.ResolveMeleeBaseline(ownerID),ActiveSerials=activeSerials,ActiveSeen=activeSeen};
	local attempts=math.max(0,tonumber(requested) or 0); local executed=0; local spawned=0; local reasons={}; local plots={};
	for slot=1,attempts do
		if #workshops==0 then break; end
		local choice=LOTM_WORLD_State.Random(#workshops,"periodic monster turn="..turn.." slot="..slot)+1;
		local camp=table.remove(workshops,choice); executed=executed+1; plots[#plots+1]=tostring(camp:GetIndex());
		local success,reason=TrySpawnOne(camp,nil,true,nil,batch); if success then spawned=spawned+1; end
		reasons[#reasons+1]=reason;
		if reason=="CAP" then break; end
	end
	Game.SetProperty("LOTM_WORLD_MONSTER_PERIODIC_LAST_ATTEMPTS",executed);
	Game.SetProperty("LOTM_WORLD_MONSTER_PERIODIC_LAST_SPAWNED",spawned);
	Game.SetProperty("LOTM_WORLD_MONSTER_PERIODIC_LAST_PLOTS",table.concat(plots,","));
	Game.SetProperty("LOTM_WORLD_MONSTER_PERIODIC_LAST_REASONS",table.concat(reasons,","));
	table.sort(batch.ActiveSerials); SaveActiveMonsterSerials(batch.ActiveSerials);
	SetPropertyIfChanged(Game,"LOTM_WORLD_MONSTER_LIVE_COUNT",#batch.Live);
	Log("periodic worldTurn="..turn.." requested="..attempts.." attempts="..executed.." spawned="..spawned.." plots="..table.concat(plots,",").." reasons="..table.concat(reasons,","));
	return spawned,"DONE";
end

local function LegalPath(unit,destination)
	return unit~=nil and destination~=nil and IsLegalWilderness(destination,false);
end

local function ConservativeKillable(attacker,defender)
	local remaining=math.max(1,(defender:GetMaxDamage() or 100)-(defender:GetDamage() or 0));
	if defender:GetCombat()<=0 then return true; end
	local minimumDamage=math.max(1,math.floor(24*math.exp((attacker:GetCombat()-defender:GetCombat())/25)));
	return remaining<=minimumDamage;
end

local function SimulatedKillable(attacker,defender)
	if CombatManager==nil or CombatManager.SimulateAttackVersus==nil or CombatResultParameters==nil then return ConservativeKillable(attacker,defender); end
	local combatType=CombatTypes~=nil and CombatTypes.MELEE or nil;
	local ok,result=pcall(CombatManager.SimulateAttackVersus,attacker:GetComponentID(),defender:GetComponentID(),combatType);
	if not ok or type(result)~="table" then return ConservativeKillable(attacker,defender); end
	local data=result[CombatResultParameters.DEFENDER];
	if type(data)~="table" then return ConservativeKillable(attacker,defender); end
	local final=data[CombatResultParameters.FINAL_DAMAGE_TO]; local maximum=data[CombatResultParameters.MAX_HIT_POINTS];
	if final==nil or maximum==nil then return ConservativeKillable(attacker,defender); end
	return final>=maximum;
end

local function TargetClass(unit)
	local info=GameInfo.Units[unit:GetType()];
	if unit:GetCombat()>0 or unit:GetRangedCombat()>0 or (info~=nil and (tonumber(info.Bombard) or 0)>0) then return 0; end
	if info~=nil and info.FormationClass=="FORMATION_CLASS_CIVILIAN" then return 1; end
	return 2;
end

local function ProtectedSealPlots()
	local result={};
	for _,zone in ipairs({"CENTER","FOOL","NIGHT","STORM"}) do
		local plotIndex=LOTM_WORLD_State.NumberGameProperty("LOTM_RESCUE_"..zone.."_CITY_PLOT",-1);
		if plotIndex>=0 then result[plotIndex]=true; end
	end
	return result;
end

local function PlayerHuntUnlocked()
	if not RescueActive() then return false; end
	local turn=Game.GetCurrentGameTurn() or 0;
	if playerHuntCacheTurn==turn then return playerHuntCache; end
	playerHuntCacheTurn=turn; playerHuntCache=true;
	for _,player in ipairs(PlayerManager.GetAliveMajors()) do
		if not player:IsHuman() then playerHuntCache=false; break; end
	end
	if playerHuntCache then
		for _ in ipairs(PlayerManager.GetAliveMinors()) do playerHuntCache=false; break; end
	end
	if playerHuntCache then
		local freeID=PlayerManager.GetFreeCitiesPlayerID(); local free=freeID~=nil and freeID>=0 and Players[freeID] or nil;
		if free~=nil and free:IsAlive() then
			local protected=ProtectedSealPlots();
			for _,city in free:GetCities():Members() do
				local plot=Map.GetPlot(city:GetX(),city:GetY());
				if plot==nil or not protected[plot:GetIndex()] then playerHuntCache=false; break; end
			end
		end
	end
	local state=playerHuntCache and 1 or 0;
	local previous=LOTM_WORLD_State.NumberGameProperty("LOTM_WORLD_MONSTER_PLAYER_HUNT_UNLOCKED",-1);
	Game.SetProperty("LOTM_WORLD_MONSTER_PLAYER_HUNT_UNLOCKED",state);
	if previous~=state then Log("player hunt state="..(playerHuntCache and "UNLOCKED_ONLY_HUMANS_AND_SEAL_CHURCHES_REMAIN" or "LOCKED_EXTERNAL_FACTIONS_REMAIN").." worldTurn="..turn); end
	return playerHuntCache;
end

local function IsAllowedUnitTarget(unit)
	if unit==nil then return false; end
	local player=Players[unit:GetOwner()];
	return player~=nil and (not player:IsHuman() or PlayerHuntUnlocked());
end

local function LegalTargets(monster)
	local result={}; local maxDistance=NumberProperty(monster,"LOTM_WORLD_MONSTER_TARGET_MOVES",3);
	for dx=-maxDistance,maxDistance do for dy=-maxDistance,maxDistance do
		local plot=Map.GetPlotXYWithRangeCheck(monster:GetX(),monster:GetY(),dx,dy,maxDistance);
		if IsLegalWilderness(plot,false) and LegalPath(monster,plot) then
			for _,other in ipairs(Units.GetUnitsInPlot(plot) or {}) do
				if other:GetOwner()~=monster:GetOwner() and IsAllowedUnitTarget(other) then
					table.insert(result,{Unit=other,Plot=plot,Killable=SimulatedKillable(monster,other),Class=TargetClass(other),Distance=Map.GetPlotDistance(monster:GetX(),monster:GetY(),plot:GetX(),plot:GetY()),Remaining=(other:GetMaxDamage() or 100)-(other:GetDamage() or 0)});
				end
			end
		end
	end end
	table.sort(result,function(a,b)
		if a.Killable~=b.Killable then return a.Killable; end
		if a.Class~=b.Class then return a.Class<b.Class; end
		if a.Distance~=b.Distance then return a.Distance<b.Distance; end
		if a.Remaining~=b.Remaining then return a.Remaining<b.Remaining; end
		if a.Unit:GetOwner()~=b.Unit:GetOwner() then return a.Unit:GetOwner()<b.Unit:GetOwner(); end
		return a.Unit:GetID()<b.Unit:GetID();
	end);
	return result;
end

local function IsCityStatePlayer(player)
	if player==nil then return false; end
	local config=PlayerConfigurations[player:GetID()];
	return config~=nil and config:GetCivilizationLevelTypeName()=="CIVILIZATION_LEVEL_CITY_STATE";
end

local function IsAttackableCityOwner(player)
	return player~=nil and player:IsAlive() and ((player:IsMajor() and (not player:IsHuman() or PlayerHuntUnlocked())) or IsCityStatePlayer(player));
end

local function AICityTargets(monster)
	local result={}; local source=Map.GetPlot(monster:GetX(),monster:GetY());
	if source==nil then return result; end
	local owners={};
	for _,player in ipairs(PlayerManager.GetAliveMajors()) do owners[#owners+1]=player; end
	for _,player in ipairs(PlayerManager.GetAliveMinors()) do owners[#owners+1]=player; end
	for _,player in ipairs(owners) do
		if IsAttackableCityOwner(player) then
			for _,city in player:GetCities():Members() do
				local plot=Map.GetPlot(city:GetX(),city:GetY());
				if plot~=nil and (RescueActive() or plot:GetContinentType()==source:GetContinentType()) then
					result[#result+1]={City=city,Plot=plot,Owner=player:GetID(),CityID=city:GetID(),Distance=Map.GetPlotDistance(monster:GetX(),monster:GetY(),city:GetX(),city:GetY())};
				end
			end
		end
	end
	table.sort(result,function(a,b)
		if a.Distance~=b.Distance then return a.Distance<b.Distance; end
		if a.Owner~=b.Owner then return a.Owner<b.Owner; end
		return a.CityID<b.CityID;
	end);
	return result;
end

local function AssaultCityTarget(monster)
	if not RescueActive() then return nil; end
	local candidates=AICityTargets(monster); if #candidates==0 then return nil; end
	local focus=candidates[1];
	return {Kind="AI_CITY",City=focus.City,Plot=focus.Plot,Owner=focus.Owner,ID=focus.CityID};
end

local function AITerritoryOwners()
	local result={};
	for _,player in ipairs(PlayerManager.GetAliveMajors()) do if IsAttackableCityOwner(player) then result[player:GetID()]=true; end end
	for _,player in ipairs(PlayerManager.GetAliveMinors()) do if IsAttackableCityOwner(player) then result[player:GetID()]=true; end end
	return result;
end

local function ClearLockedTarget(monster)
	monster:SetProperty(TARGET_KIND_PROPERTY,nil); monster:SetProperty(TARGET_OWNER_PROPERTY,nil); monster:SetProperty(TARGET_ID_PROPERTY,nil);
end

local function LockedTarget(monster)
	local kind=tostring(monster:GetProperty(TARGET_KIND_PROPERTY) or "");
	local owner=NumberProperty(monster,TARGET_OWNER_PROPERTY,-1); local id=NumberProperty(monster,TARGET_ID_PROPERTY,-1);
	if kind=="UNIT" then
		local unit=owner>=0 and id>=0 and UnitManager.GetUnit(owner,id) or nil;
		if unit~=nil and not unit:IsDead() and not unit:IsDelayedDeath() and IsAllowedUnitTarget(unit) then
			local plot=Map.GetPlot(unit:GetX(),unit:GetY()); if plot~=nil then return {Kind="UNIT",Unit=unit,Plot=plot,Owner=owner,ID=id}; end
		end
	elseif kind=="AI_CITY" then
		local city=owner>=0 and id>=0 and CityManager.GetCity(owner,id) or nil;
		if city~=nil and IsAttackableCityOwner(Players[city:GetOwner()]) then
			local plot=Map.GetPlot(city:GetX(),city:GetY()); if plot~=nil then return {Kind="AI_CITY",City=city,Plot=plot,Owner=owner,ID=id}; end
		end
	end
	if kind~="" then ClearLockedTarget(monster); Log("target released serial="..NumberProperty(monster,MONSTER_SERIAL,0).." kind="..kind.." owner="..owner.." id="..id); end
	return nil;
end

local function ChooseLockedTarget(monster)
	local focus=AssaultCityTarget(monster);
	if focus~=nil then
		monster:SetProperty(TARGET_KIND_PROPERTY,"AI_CITY"); monster:SetProperty(TARGET_OWNER_PROPERTY,focus.Owner); monster:SetProperty(TARGET_ID_PROPERTY,focus.ID);
		Log("nearest city locked serial="..NumberProperty(monster,MONSTER_SERIAL,0).." owner="..focus.Owner.." city="..focus.ID.." plot="..focus.Plot:GetIndex());
		return focus;
	end
	local candidates={};
	for _,entry in ipairs(LegalTargets(monster)) do candidates[#candidates+1]={Kind="UNIT",Unit=entry.Unit,Plot=entry.Plot,Owner=entry.Unit:GetOwner(),ID=entry.Unit:GetID()}; end
	for _,entry in ipairs(AICityTargets(monster)) do candidates[#candidates+1]={Kind="AI_CITY",City=entry.City,Plot=entry.Plot,Owner=entry.Owner,ID=entry.CityID}; end
	if #candidates==0 then return nil; end
	local serial=NumberProperty(monster,MONSTER_SERIAL,0);
	local choice=LOTM_WORLD_State.Random(#candidates,"monster locked target serial="..serial)+1; local target=candidates[choice];
	monster:SetProperty(TARGET_KIND_PROPERTY,target.Kind); monster:SetProperty(TARGET_OWNER_PROPERTY,target.Owner); monster:SetProperty(TARGET_ID_PROPERTY,target.ID);
	Log("target locked serial="..serial.." kind="..target.Kind.." owner="..target.Owner.." id="..target.ID.." candidates="..#candidates);
	return target;
end

local function RoamPlot(monster)
	local candidates={}; local maxDistance=NumberProperty(monster,"LOTM_WORLD_MONSTER_TARGET_MOVES",3);
	for dx=-maxDistance,maxDistance do for dy=-maxDistance,maxDistance do
		local plot=Map.GetPlotXYWithRangeCheck(monster:GetX(),monster:GetY(),dx,dy,maxDistance);
		if plot~=nil and plot:GetIndex()~=(Map.GetPlot(monster:GetX(),monster:GetY())):GetIndex() and IsLegalWilderness(plot,true) and LegalPath(monster,plot) then table.insert(candidates,plot); end
	end end
	table.sort(candidates,function(a,b) return a:GetIndex()<b:GetIndex(); end);
	if #candidates==0 then return nil; end
	return candidates[LOTM_WORLD_State.Random(#candidates,"monster roam serial="..NumberProperty(monster,MONSTER_SERIAL,0))+1];
end

local function EngineComponentID(object,componentType)
	if object==nil then return nil; end
	if object.GetComponentID~=nil then
		local ok,value=pcall(object.GetComponentID,object); if ok and type(value)=="table" then return value; end
	end
	if componentType==nil or object.GetOwner==nil or object.GetID==nil then return nil; end
	return {player=object:GetOwner(),id=object:GetID(),type=componentType};
end

local function SimulateEngineMelee(attacker,defender,defenderComponentType)
	if attacker==nil or defender==nil or CombatManager==nil or CombatManager.SimulateAttackVersus==nil or CombatResultParameters==nil or ComponentType==nil then
		return nil,"ENGINE_COMBAT_API_UNAVAILABLE";
	end
	local attackerComponentID=EngineComponentID(attacker,ComponentType.UNIT); local defenderComponentID=EngineComponentID(defender,defenderComponentType);
	if attackerComponentID==nil or defenderComponentID==nil then return nil,"ENGINE_COMPONENT_ID_UNAVAILABLE"; end
	local combatType=CombatTypes~=nil and CombatTypes.MELEE or nil;
	local ok,result=pcall(CombatManager.SimulateAttackVersus,attackerComponentID,defenderComponentID,combatType);
	if not ok or type(result)~="table" then return nil,"ENGINE_COMBAT_SIMULATION_FAILED"; end
	local attackerData=result[CombatResultParameters.ATTACKER]; local defenderData=result[CombatResultParameters.DEFENDER];
	if type(attackerData)~="table" or type(defenderData)~="table" then return nil,"ENGINE_COMBAT_RESULT_UNAVAILABLE"; end
	local attackerDamage=tonumber(attackerData[CombatResultParameters.DAMAGE_TO]);
	local defenderDamage=tonumber(defenderData[CombatResultParameters.DAMAGE_TO]);
	local defenseDamage=CombatResultParameters.DEFENSE_DAMAGE_TO~=nil and tonumber(defenderData[CombatResultParameters.DEFENSE_DAMAGE_TO]) or 0;
	if attackerDamage==nil or defenderDamage==nil then return nil,"ENGINE_COMBAT_DAMAGE_UNAVAILABLE"; end
	return {AttackerDamage=math.max(0,attackerDamage),DefenderDamage=math.max(0,defenderDamage),DefenseDamage=math.max(0,defenseDamage or 0)},"ENGINE_COMBAT_READY";
end

local function ApplyEngineUnitDamage(unit,damage)
	if unit==nil or damage<=0 or unit:IsDead() or unit:IsDelayedDeath() then return true,false; end
	local maximum=unit:GetMaxDamage() or 100; local current=unit:GetDamage() or 0;
	if current+damage>=maximum then
		local ok,result=pcall(UnitManager.Kill,unit);
		return ok and result~=false,true;
	end
	unit:ChangeDamage(damage); return true,false;
end

local function ScriptedAttack(attacker,defender)
	if attacker==nil or defender==nil or defender:IsDead() or defender:IsDelayedDeath() then return false,"TARGET_GONE"; end
	local result,reason=SimulateEngineMelee(attacker,defender,ComponentType~=nil and ComponentType.UNIT or nil); if result==nil then return false,reason; end
	local attackSerial=NumberProperty(attacker,"LOTM_WORLD_MONSTER_ATTACK_SERIAL",0)+1;
	attacker:SetProperty("LOTM_WORLD_MONSTER_ATTACK_SERIAL",attackSerial);
	local reflected=LOTM_RESCUE_Thief~=nil and LOTM_RESCUE_Thief.ShouldReflectAttack~=nil
		and LOTM_RESCUE_Thief.ShouldReflectAttack(attacker,defender,attackSerial);
	if reflected then
		if LOTM_RESCUE_SyncActions~=nil and LOTM_RESCUE_SyncActions.MarkScriptedKiller~=nil then
			LOTM_RESCUE_SyncActions.MarkScriptedKiller(attacker,defender);
		end
		local attackerOK,attackerKilled=ApplyEngineUnitDamage(attacker,result.DefenderDamage);
		if not attackerOK then return false,"ENGINE_REFLECT_DAMAGE_APPLY_FAILED"; end
		return true,"REFLECTED_33PCT_DAMAGE_"..result.DefenderDamage.."_KILLS_"..tostring(attackerKilled);
	end
	local defenderOK,defenderKilled=ApplyEngineUnitDamage(defender,result.DefenderDamage);
	local attackerOK,attackerKilled=ApplyEngineUnitDamage(attacker,result.AttackerDamage);
	if not defenderOK or not attackerOK then return false,"ENGINE_UNIT_DAMAGE_APPLY_FAILED"; end
	return true,"ENGINE_UNIT_DAMAGE_"..result.DefenderDamage.."_RETALIATION_"..result.AttackerDamage.."_KILLS_"..tostring(defenderKilled).."/"..tostring(attackerKilled);
end

local function ScriptedCityAttack(attacker,target)
	if attacker==nil or target==nil or not IsAttackableCityOwner(Players[target:GetOwner()]) then return false,"CITY_TARGET_INVALID"; end
	local district=CityManager.GetDistrictAt(target:GetX(),target:GetY());
	if district==nil or DefenseTypes==nil or DefenseTypes.DISTRICT_GARRISON==nil or DefenseTypes.DISTRICT_OUTER==nil then return false,"CITY_DISTRICT_UNAVAILABLE"; end
	local result,reason=SimulateEngineMelee(attacker,district,ComponentType~=nil and ComponentType.DISTRICT or nil); if result==nil then return false,reason; end
	local attackSerial=NumberProperty(attacker,"LOTM_WORLD_MONSTER_ATTACK_SERIAL",0)+1;
	attacker:SetProperty("LOTM_WORLD_MONSTER_ATTACK_SERIAL",attackSerial);
	local reflected=LOTM_RESCUE_Thief~=nil and LOTM_RESCUE_Thief.ShouldReflectAttack~=nil
		and LOTM_RESCUE_Thief.ShouldReflectAttack(attacker,target,attackSerial);
	if reflected then
		local killer=nil;
		for _,candidate in ipairs(PlayerManager.GetAliveMajors() or {}) do
			if candidate:IsHuman() and candidate:GetProperty("LOTM_RP_PATH")=="PATH_THIEF"
				and tonumber(candidate:GetProperty("LOTM_RP_SEQUENCE") or 9)<=3 then
				killer=candidate:GetUnits():FindID(tonumber(candidate:GetProperty("LOTM_RP_UNIT_ID") or -1));
				if killer~=nil then break; end
			end
		end
		if killer~=nil and LOTM_RESCUE_SyncActions~=nil and LOTM_RESCUE_SyncActions.MarkScriptedKiller~=nil then
			LOTM_RESCUE_SyncActions.MarkScriptedKiller(attacker,killer);
		end
		local attackerOK,attackerKilled=ApplyEngineUnitDamage(attacker,result.DefenderDamage);
		if not attackerOK then return false,"ENGINE_REFLECT_DAMAGE_APPLY_FAILED"; end
		return true,"REFLECTED_33PCT_CITY_DAMAGE_"..result.DefenderDamage.."_KILLS_"..tostring(attackerKilled);
	end
	local garrisonOK,garrison=pcall(function() return district:GetDamage(DefenseTypes.DISTRICT_GARRISON); end);
	local garrisonMaxOK,garrisonMax=pcall(function() return district:GetMaxDamage(DefenseTypes.DISTRICT_GARRISON); end);
	local outerOK,outer=pcall(function() return district:GetDamage(DefenseTypes.DISTRICT_OUTER); end);
	local outerMaxOK,outerMax=pcall(function() return district:GetMaxDamage(DefenseTypes.DISTRICT_OUTER); end);
	if not garrisonOK or not garrisonMaxOK or not outerOK or not outerMaxOK then return false,"CITY_DAMAGE_READ_FAILED"; end
	garrison=tonumber(garrison) or 0; garrisonMax=tonumber(garrisonMax) or 100; outer=tonumber(outer) or 0; outerMax=tonumber(outerMax) or 0;
	if garrisonMax<=0 then garrisonMax=100; end
	local nextGarrison=math.min(garrisonMax,garrison+result.DefenderDamage); local nextOuter=outerMax>0 and math.min(outerMax,outer+result.DefenseDamage) or outer;
	local writeOK=pcall(function()
		district:SetDamage(DefenseTypes.DISTRICT_GARRISON,nextGarrison);
		if outerMax>0 then district:SetDamage(DefenseTypes.DISTRICT_OUTER,nextOuter); end
	end);
	if not writeOK then return false,"CITY_DAMAGE_WRITE_FAILED"; end
	local attackerOK=ApplyEngineUnitDamage(attacker,result.AttackerDamage); if not attackerOK then return false,"ENGINE_RETALIATION_APPLY_FAILED"; end
	if nextGarrison>=garrisonMax then
		local live=CityManager.GetCity(target:GetOwner(),target:GetID());
		if live==nil or not IsAttackableCityOwner(Players[live:GetOwner()]) then return false,"CITY_LETHAL_REVALIDATION_FAILED"; end
		local ownerID=live:GetOwner(); local cityID=live:GetID();
		if CityManager.DestroyCity~=nil then
			local destroyOK,destroyed=pcall(CityManager.DestroyCity,live);
			if destroyOK and destroyed~=false and CityManager.GetCity(ownerID,cityID)==nil then return true,"AI_CITY_DESTROYED"; end
		end
		if CityManager.RequestCommand==nil or CityCommandTypes==nil or CityCommandTypes.DESTROY==nil or CityDestroyDirectives==nil or CityDestroyDirectives.RAZE==nil or UnitOperationTypes==nil or UnitOperationTypes.PARAM_FLAGS==nil then
			return false,"CITY_DESTROY_API_UNAVAILABLE";
		end
		local parameters={}; parameters[UnitOperationTypes.PARAM_FLAGS]=CityDestroyDirectives.RAZE;
		local requestOK,requested=pcall(CityManager.RequestCommand,live,CityCommandTypes.DESTROY,parameters);
		if not requestOK or requested==false then return false,"AI_CITY_DESTROY_REQUEST_FAILED"; end
		return true,"AI_CITY_DESTROY_REQUESTED";
	end
	return true,"ENGINE_CITY_GARRISON_"..result.DefenderDamage.."_WALL_"..result.DefenseDamage.."_RETALIATION_"..result.AttackerDamage;
end

local function ReconcileMonsterAbilities(monster)
	local tier=NumberProperty(monster,MONSTER_TIER,2);
	local info=GameInfo.Units[monster:GetType()];
	local baseMoves=info~=nil and (tonumber(info.BaseMoves) or 2) or 2;
	ApplyMonsterAbilities(monster,tier,math.max(0,NumberProperty(monster,"LOTM_WORLD_MONSTER_TARGET_MOVES",TIER_MOVES[tier])-baseMoves),NumberProperty(monster,PERIOD_BONUS_PROPERTY,0));
	return tier;
end

local function Act(monster)
	local tier=ReconcileMonsterAbilities(monster); local damage=monster:GetDamage() or 0;
	if damage>0 then monster:ChangeDamage(-math.min(TIER_HEAL[tier],damage)); end
	if LOTM_RESCUE_SyncActions==nil then UnitManager.FinishMoves(monster); Log("action serial="..NumberProperty(monster,MONSTER_SERIAL,0).." gameplayNative=false reason=HELPER_UNAVAILABLE attack=false destination=-1"); return; end
	local currentTurn=Game.GetCurrentGameTurn();
	if NumberProperty(monster,REDEPLOYED_TURN_PROPERTY,-1)==currentTurn then
		UnitManager.FinishMoves(monster);
		Log("action serial="..NumberProperty(monster,MONSTER_SERIAL,0).." gameplayNative=false reason=REDEPLOY_COOLDOWN attack=false destination=-1 attackEligibleTurn="..tostring(currentTurn+1));
		return;
	end
	local target=LockedTarget(monster) or ChooseLockedTarget(monster); local destination=nil; local attack=false; local acted=false; local reason="NO_DESTINATION"; local targetKind="NONE"; local targetOwner=-1; local targetCity=-1;
	if target~=nil and target.Kind=="UNIT" then
		destination=target.Plot; attack=true; targetKind="UNIT"; targetOwner=target.Owner;
		local distance=Map.GetPlotDistance(monster:GetX(),monster:GetY(),destination:GetX(),destination:GetY());
		if distance>1 then acted,reason=LOTM_RESCUE_SyncActions.MoveToward(monster,destination,NumberProperty(monster,"LOTM_WORLD_MONSTER_TARGET_MOVES",3),true,false); end
		if Map.GetPlotDistance(monster:GetX(),monster:GetY(),destination:GetX(),destination:GetY())<=1 then acted,reason=ScriptedAttack(monster,target.Unit); end
	elseif target~=nil and target.Kind=="AI_CITY" then
		destination=target.Plot; attack=true; targetKind="AI_CITY"; targetOwner=target.Owner; targetCity=target.ID;
		local distance=Map.GetPlotDistance(monster:GetX(),monster:GetY(),destination:GetX(),destination:GetY());
		local source=Map.GetPlot(monster:GetX(),monster:GetY());
		local crossContinent=source~=nil and source:GetContinentType()~=destination:GetContinentType();
		if distance>REDEPLOY_DISTANCE or crossContinent then
			local from=source~=nil and source:GetIndex() or -1; local redeployPlot=-1; local redeployDistance=-1;
			acted,reason,redeployPlot,redeployDistance=LOTM_RESCUE_SyncActions.RedeployNearTarget(monster,destination,REDEPLOY_TARGET_MIN_DISTANCE,REDEPLOY_TARGET_MAX_DISTANCE,false,AITerritoryOwners());
			if acted then
				local placed=Map.GetPlot(monster:GetX(),monster:GetY());
				monster:SetProperty(REDEPLOYED_TURN_PROPERTY,currentTurn);
				UnitManager.FinishMoves(monster);
				Log("redeployed serial="..NumberProperty(monster,MONSTER_SERIAL,0).." from="..from.." to="..tostring(placed~=nil and placed:GetIndex() or redeployPlot)
					.." targetKind=AI_CITY targetOwner="..targetOwner.." targetID="..targetCity.." distanceBefore="..distance
					.." distanceAfter="..redeployDistance.." attackEligibleTurn="..tostring(currentTurn+1).." reason="..reason);
				Log("action serial="..NumberProperty(monster,MONSTER_SERIAL,0).." gameplayNative=true reason=REDEPLOY_COOLDOWN attack=false targetKind=AI_CITY targetOwner="..targetOwner.." targetCity="..targetCity.." destination="..destination:GetIndex());
				return;
			end
		end
		if distance>1 then acted,reason=LOTM_RESCUE_SyncActions.MoveToward(monster,destination,NumberProperty(monster,"LOTM_WORLD_MONSTER_TARGET_MOVES",3),false,false,AITerritoryOwners()); end
		-- The first long-distance redeploy can leave a monster inside the target's
		-- five-tile ring but behind a newly occupied or unusable route. Distance
		-- alone would then suppress every later redeploy. Retry another legal ring
		-- tile on NO_PLOT and preserve the same no-attack-until-next-turn rule.
		if reason=="NO_PLOT" then
			local blockedSource=Map.GetPlot(monster:GetX(),monster:GetY());
			local blockedFrom=blockedSource~=nil and blockedSource:GetIndex() or -1;
			local distanceBeforeRetry=Map.GetPlotDistance(monster:GetX(),monster:GetY(),destination:GetX(),destination:GetY());
			local retryPlot=-1; local retryDistance=-1; local retryReason="NO_REDEPLOY_PLOT";
			acted,retryReason,retryPlot,retryDistance=LOTM_RESCUE_SyncActions.RedeployNearTarget(monster,destination,REDEPLOY_TARGET_MIN_DISTANCE,REDEPLOY_TARGET_MAX_DISTANCE,false,AITerritoryOwners());
			if acted then
				local placed=Map.GetPlot(monster:GetX(),monster:GetY());
				monster:SetProperty(REDEPLOYED_TURN_PROPERTY,currentTurn);
				UnitManager.FinishMoves(monster);
				Log("redeployed serial="..NumberProperty(monster,MONSTER_SERIAL,0).." from="..blockedFrom.." to="..tostring(placed~=nil and placed:GetIndex() or retryPlot)
					.." targetKind=AI_CITY targetOwner="..targetOwner.." targetID="..targetCity.." distanceBefore="..distanceBeforeRetry
					.." distanceAfter="..retryDistance.." attackEligibleTurn="..tostring(currentTurn+1).." reason=BLOCKED_"..retryReason);
				Log("action serial="..NumberProperty(monster,MONSTER_SERIAL,0).." gameplayNative=true reason=REDEPLOY_COOLDOWN attack=false targetKind=AI_CITY targetOwner="..targetOwner.." targetCity="..targetCity.." destination="..destination:GetIndex());
				return;
			end
			reason=retryReason;
		end
		if Map.GetPlotDistance(monster:GetX(),monster:GetY(),destination:GetX(),destination:GetY())<=1 then
			acted,reason=ScriptedCityAttack(monster,target.City);
		else
			for _,entry in ipairs(LegalTargets(monster)) do
				if entry.Distance<=1 then
					local fallbackReason="NONE"; acted,fallbackReason=ScriptedAttack(monster,entry.Unit);
					reason="CITY_BLOCKED_UNIT_"..fallbackReason; targetKind="UNIT"; targetOwner=entry.Unit:GetOwner(); targetCity=-1; destination=entry.Plot;
					break;
				end
			end
		end
	else
		destination=RoamPlot(monster);
		if destination~=nil then acted,reason=LOTM_RESCUE_SyncActions.MoveToward(monster,destination,NumberProperty(monster,"LOTM_WORLD_MONSTER_TARGET_MOVES",3),true,false); end
	end
	-- Single-player only: an AI city can remain a valid CityManager object while
	-- no legal approach plot exists (for example after ownership/terrain changes).
	-- Do not keep the permanent lock in that case, otherwise every later turn
	-- repeats NO_PLOT and this civilization is effectively never attacked.
	if (reason=="NO_PLOT" or reason=="NO_REDEPLOY_PLOT" or reason=="PLACE_FAILED") and targetKind=="AI_CITY"
		and (LOTM_MP_TurnSync==nil or not LOTM_MP_TurnSync.IsNetworkGame()) then
		ClearLockedTarget(monster);
		Log("target released serial="..NumberProperty(monster,MONSTER_SERIAL,0)
			.." kind=AI_CITY owner="..tostring(targetOwner).." id="..tostring(targetCity)
			.." reason="..tostring(reason).."_SP_RESELECT");
	end
	UnitManager.FinishMoves(monster);
	local actionMessage="action serial="..NumberProperty(monster,MONSTER_SERIAL,0).." gameplayNative="..tostring(acted).." reason="..reason.." attack="..tostring(attack).." targetKind="..targetKind.." targetOwner="..targetOwner.." targetCity="..targetCity.." destination="..tostring(destination~=nil and destination:GetIndex() or -1);
	if string.find(reason,"AI_CITY_",1,true)==1 or string.find(reason,"ENGINE_",1,true)==1 or reason=="NO_PLOT" or reason=="PLACE_FAILED" or reason=="HELPER_UNAVAILABLE" or string.find(reason,"FAILED",1,true)~=nil or string.find(reason,"UNAVAILABLE",1,true)~=nil then Log(actionMessage); else Trace(actionMessage); end
end

local function Release(serial,removedTurn,liveCountAlreadyReconciled)
	if serial==nil or serial<=0 then return; end
	if LOTM_WORLD_State.NumberGameProperty(MetaKey(serial,"LIVE"),0)~=1 then return; end
	local source=LOTM_WORLD_State.NumberGameProperty(MetaKey(serial,"SOURCE"),-1);
	local camp=Map.GetPlotByIndex(source);
	local sourceEpochValue=Game.GetProperty(MetaKey(serial,"SOURCE_CAMP_EPOCH"));
	local sourceEpoch=sourceEpochValue~=nil and tonumber(sourceEpochValue) or nil;
	local currentEpochValue=camp~=nil and camp:GetProperty("LOTM_PP_WORKSHOP_CAMP_EPOCH") or nil;
	local currentEpoch=currentEpochValue~=nil and tonumber(currentEpochValue) or nil;
	local currentSlot=camp~=nil and NumberProperty(camp,"LOTM_WORLD_WORKSHOP_MONSTER_SERIAL",0) or 0;
	-- Resource-290 monsters have no frozen camp epoch.  For those legacy units,
	-- the still-matching source slot is the only proof that this is the original
	-- camp generation.  Missing epoch data must not authorize cooldown writes to
	-- a rebuilt camp on the same plot.
	local sameCampGeneration=false;
	if sourceEpoch~=nil and currentEpoch~=nil then
		sameCampGeneration=sourceEpoch==currentEpoch;
	elseif currentSlot==serial then
		sameCampGeneration=true;
	end
	local releaseTurn=NumberProperty(Game,MetaKey(serial,"RELEASE_TURN"),-1);
	if releaseTurn<0 then
		releaseTurn=tonumber(removedTurn) or Game.GetCurrentGameTurn();
		Game.SetProperty(MetaKey(serial,"RELEASE_TURN"),releaseTurn);
	end
	local cooldownUntil=NumberProperty(Game,MetaKey(serial,"RELEASE_COOLDOWN_UNTIL"),-1);
	if cooldownUntil<0 then
		cooldownUntil=releaseTurn+MonsterCooldown();
		Game.SetProperty(MetaKey(serial,"RELEASE_COOLDOWN_UNTIL"),cooldownUntil);
	end
	if camp~=nil and sameCampGeneration then
		if currentSlot==serial then
			camp:SetProperty("LOTM_WORLD_WORKSHOP_MONSTER_SERIAL",0);
		end
		camp:SetProperty("LOTM_WORLD_WORKSHOP_MONSTER_COOLDOWN_UNTIL",cooldownUntil);
	end
	if liveCountAlreadyReconciled~=true then
		local count=0;
		for _,activeSerial in ipairs(ActiveMonsterSerials()) do
			if activeSerial~=serial and LOTM_WORLD_State.NumberGameProperty(MetaKey(activeSerial,"LIVE"),0)==1 then count=count+1; end
		end
		Game.SetProperty("LOTM_WORLD_MONSTER_LIVE_COUNT",count);
	end
	Log("released serial="..serial.." cooldownUntil="..cooldownUntil.." sameCampGeneration="..tostring(sameCampGeneration));
end

local function SettleReward(serial,killerID,killerUnitID,capturedEraIndex)
	if serial==nil or serial<=0 or LOTM_WORLD_State.NumberGameProperty(MetaKey(serial,"REWARDED"),0)==1 then return; end
	if RescueActive() and LOTM_RESCUE_Phase6~=nil and LOTM_RESCUE_Phase6.OnLostControlKilled~=nil then
		local tier=LOTM_WORLD_State.NumberGameProperty(MetaKey(serial,"TIER"),2);
		local ok,result=pcall(LOTM_RESCUE_Phase6.OnLostControlKilled,tier,killerID,killerUnitID,"MONSTER",serial);
		if not ok then Log("Phase6 purification error serial="..serial.." error="..tostring(result)); end
	end
	local killer=Players[killerID]; if killer==nil or not killer:IsAlive() or not killer:IsMajor() then return; end
	Game.SetProperty(MetaKey(serial,"REWARDED"),1);
	local handled=false;
	if questResolver~=nil then local ok,result=pcall(questResolver,killerID,serial); handled=ok and result==true; end
	local tier=LOTM_WORLD_State.NumberGameProperty(MetaKey(serial,"TIER"),2);
	local eraIndex=tonumber(capturedEraIndex); if eraIndex==nil then eraIndex=Game.GetEras():GetCurrentEra() or 0; end
	local eraNumber=math.max(1,eraIndex+1);
	local goldReward=REWARD_GOLD_PER_ERA*eraNumber;
	if not handled then
		local treasury=killer:GetTreasury(); if treasury~=nil then treasury:ChangeGoldBalance(goldReward); end
	end
	Log("reward serial="..serial.." killer="..killerID.." tier="..tier.." era="..eraNumber.." gold="..goldReward.." questHandled="..tostring(handled));
end

local function Dead(unit)
	return unit==nil or unit:IsDead() or unit:IsDelayedDeath();
end

local function ScriptedKillerPrefix(ownerID,unitID)
	return "LOTM_RESCUE_SCRIPTED_KILLER:"..tostring(ownerID)..":"..tostring(unitID)..":";
end

local function MonsterIdentityMatches(serial,ownerID,unitID)
	return LOTM_WORLD_State.NumberGameProperty(MetaKey(serial,"OWNER"),-1)==tonumber(ownerID)
		and LOTM_WORLD_State.NumberGameProperty(MetaKey(serial,"UNIT_ID"),-1)==tonumber(unitID);
end

local function CancelNetworkRemoval(serial,reason)
	local entry=networkRemovalBySerial[tonumber(serial)];
	if entry~=nil then
		entry.Cancelled=true;
		networkRemovalBySerial[entry.Serial]=nil;
		Trace("network removal cancelled serial="..entry.Serial.." reason="..tostring(reason));
	end
end

local function ClearCapturedIdentity(ownerID,unitID,serial,killerID,killerUnitID)
	local engineKey=EngineKey(ownerID,unitID);
	if LOTM_WORLD_State.NumberGameProperty(engineKey,0)~=serial then return; end
	Game.SetProperty(engineKey,nil);
	local prefix=ScriptedKillerPrefix(ownerID,unitID);
	if killerID~=nil and killerID>=0
		and tostring(Game.GetProperty(prefix.."TARGET_KIND") or "")=="MONSTER"
		and LOTM_WORLD_State.NumberGameProperty(prefix.."TARGET_SERIAL",-1)==serial
		and LOTM_WORLD_State.NumberGameProperty(prefix.."PLAYER",-1)==killerID
		and LOTM_WORLD_State.NumberGameProperty(prefix.."UNIT",-1)==(killerUnitID or -1) then
		Game.SetProperty(prefix.."PLAYER",nil); Game.SetProperty(prefix.."UNIT",nil);
		Game.SetProperty(prefix.."TARGET_KIND",nil); Game.SetProperty(prefix.."TARGET_SERIAL",nil);
	end
end

local function FinalizeRemoval(serial,ownerID,unitID,killerID,killerUnitID,removedTurn,rewardEraIndex,liveCountAlreadyReconciled,source,cancelQueued)
	local normalizedSerial=tonumber(serial); local normalizedOwner=tonumber(ownerID); local normalizedUnit=tonumber(unitID);
	if normalizedSerial==nil or normalizedSerial<=0 or normalizedOwner==nil or normalizedUnit==nil then return false,"INVALID_IDENTITY"; end
	if not MonsterIdentityMatches(normalizedSerial,normalizedOwner,normalizedUnit) then
		Log("removal rejected source="..tostring(source).." serial="..normalizedSerial.." owner="..normalizedOwner.." unit="..normalizedUnit.." reason=IDENTITY_MISMATCH");
		return false,"IDENTITY_MISMATCH";
	end
	local current=UnitManager.GetUnit(normalizedOwner,normalizedUnit);
	local identityReused=current~=nil and NumberProperty(current,MONSTER_SERIAL,0)~=normalizedSerial;
	if not identityReused and LOTM_RESCUE_Phase9Digestion~=nil
		and type(LOTM_RESCUE_Phase9Digestion.RecordLostControlIdentity)=="function" then
		LOTM_RESCUE_Phase9Digestion.RecordLostControlIdentity(normalizedOwner,normalizedUnit,
			LOTM_WORLD_State.NumberGameProperty(MetaKey(normalizedSerial,"BASELINE"),0));
	end
	Release(normalizedSerial,removedTurn,liveCountAlreadyReconciled);
	local normalizedKiller=tonumber(killerID) or -1; local normalizedKillerUnit=tonumber(killerUnitID) or -1;
	if normalizedKiller>=0 then SettleReward(normalizedSerial,normalizedKiller,normalizedKillerUnit,rewardEraIndex); end
	-- Clear owner:unitID state only while it still names this serial.  A later
	-- unit generation may already have reused the same engine ID.
	ClearCapturedIdentity(normalizedOwner,normalizedUnit,normalizedSerial,normalizedKiller,normalizedKillerUnit);
	Game.SetProperty(MetaKey(normalizedSerial,"MISSING_SINCE"),nil);
	Game.SetProperty(MetaKey(normalizedSerial,"LIVE"),0);
	RemoveActiveMonsterSerial(normalizedSerial);
	if cancelQueued then CancelNetworkRemoval(normalizedSerial,source); end
	return true,"SETTLED";
end

local function QueueNetworkRemoval(playerID,unitID)
	local owner=tonumber(playerID); local removedUnit=tonumber(unitID);
	if owner==nil or removedUnit==nil then return; end
	local serial=LOTM_WORLD_State.NumberGameProperty(EngineKey(owner,removedUnit),0);
	if serial<=0 or LOTM_WORLD_State.NumberGameProperty(MetaKey(serial,"LIVE"),0)~=1 then return; end
	if not MonsterIdentityMatches(serial,owner,removedUnit) then
		Log("network removal enqueue rejected serial="..serial.." owner="..owner.." unit="..removedUnit.." reason=IDENTITY_MISMATCH");
		return;
	end
	local existing=networkRemovalBySerial[serial];
	if existing~=nil then
		Trace("network removal duplicate serial="..serial.." queuedTurn="..existing.QueuedTurn);
		return;
	end
	local entry={
		Serial=serial,OwnerID=owner,UnitID=removedUnit,
		QueuedTurn=Game.GetCurrentGameTurn(),
		Cancelled=false
	};
	networkRemovalQueue[#networkRemovalQueue+1]=entry;
	networkRemovalBySerial[serial]=entry;
	Trace("network removal queued serial="..serial.." owner="..owner.." unit="..removedUnit.." queuedTurn="..entry.QueuedTurn);
end

local function ReconcileActiveMonsterRemovals(source)
	local missing={}; local liveCount=0;
	local currentTurn=Game.GetCurrentGameTurn();
	for _,serial in ipairs(ActiveMonsterSerials()) do
		if LOTM_WORLD_State.NumberGameProperty(MetaKey(serial,"LIVE"),0)~=1 then
			Game.SetProperty(MetaKey(serial,"MISSING_SINCE"),nil);
			RemoveActiveMonsterSerial(serial);
		else
			local owner=LOTM_WORLD_State.NumberGameProperty(MetaKey(serial,"OWNER"),-1);
			local unitID=LOTM_WORLD_State.NumberGameProperty(MetaKey(serial,"UNIT_ID"),-1);
			local unit=owner>=0 and unitID>=0 and UnitManager.GetUnit(owner,unitID) or nil;
			local unitSerial=unit~=nil and NumberProperty(unit,MONSTER_SERIAL,0) or 0;
			if not Dead(unit) and unitSerial==serial then
				liveCount=liveCount+1;
				if Game.GetProperty(MetaKey(serial,"MISSING_SINCE"))~=nil then Game.SetProperty(MetaKey(serial,"MISSING_SINCE"),nil); end
			else
				local identityReused=unit~=nil and unitSerial~=serial;
				local missingSinceValue=Game.GetProperty(MetaKey(serial,"MISSING_SINCE"));
				local missingSince=missingSinceValue~=nil and tonumber(missingSinceValue) or nil;
				if identityReused or (missingSince~=nil and missingSince<currentTurn) then
					missing[#missing+1]={Serial=serial,OwnerID=owner,UnitID=unitID,IdentityReused=identityReused};
				elseif missingSince==nil then
					Game.SetProperty(MetaKey(serial,"MISSING_SINCE"),currentTurn);
					Trace("active removal awaiting confirmation serial="..serial.." turn="..currentTurn);
				end
			end
		end
	end
	-- The active index is bounded by the monster cap. Recounting it avoids a
	-- full unit/map scan at every stable anchor and makes fallback release safe.
	Game.SetProperty("LOTM_WORLD_MONSTER_LIVE_COUNT",liveCount);
	for _,entry in ipairs(missing) do
		local prefix=ScriptedKillerPrefix(entry.OwnerID,entry.UnitID);
		local engineOwnsIdentity=LOTM_WORLD_State.NumberGameProperty(EngineKey(entry.OwnerID,entry.UnitID),0)==entry.Serial;
		local scriptedIdentityMatches=tostring(Game.GetProperty(prefix.."TARGET_KIND") or "")=="MONSTER"
			and LOTM_WORLD_State.NumberGameProperty(prefix.."TARGET_SERIAL",-1)==entry.Serial;
		local killerID=engineOwnsIdentity and not entry.IdentityReused and scriptedIdentityMatches
			and LOTM_WORLD_State.NumberGameProperty(prefix.."PLAYER",-1) or -1;
		local killerUnitID=killerID>=0 and LOTM_WORLD_State.NumberGameProperty(prefix.."UNIT",-1) or -1;
		local settled,reason=FinalizeRemoval(entry.Serial,entry.OwnerID,entry.UnitID,
			killerID,killerUnitID,Game.GetCurrentGameTurn(),CurrentEraIndex(),true,
			source or "ACTIVE_INDEX",true);
		Trace("active removal reconcile serial="..entry.Serial.." settled="..tostring(settled).." reason="..tostring(reason));
	end
end

local function CombatMonsterSerial(ownerID,unitID)
	local serial=LOTM_WORLD_State.NumberGameProperty(EngineKey(ownerID,unitID),0);
	if serial<=0 then return 0; end
	local unit=UnitManager.GetUnit(ownerID,unitID);
	if unit~=nil and NumberProperty(unit,MONSTER_SERIAL,0)~=serial then return 0; end
	return serial;
end

local function ProcessNetworkRemovals(playerID)
	if not LOTM_MP_TurnSync.IsNetworkGame()
		or not LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID) then return; end
	local currentTurn=Game.GetCurrentGameTurn();
	-- The durable active index is the sole ordering authority.  Reconcile it
	-- first so peers with a delivered, delayed, or save-lost local callback all
	-- finalize the same missing serials in the same order from anchor-time facts.
	ReconcileActiveMonsterRemovals("ACTIVE_INDEX_RUNTIME");
	table.sort(networkRemovalQueue,function(a,b)
		if a.QueuedTurn~=b.QueuedTurn then return a.QueuedTurn<b.QueuedTurn; end
		if a.Serial~=b.Serial then return a.Serial<b.Serial; end
		if a.OwnerID~=b.OwnerID then return a.OwnerID<b.OwnerID; end
		if a.UnitID~=b.UnitID then return a.UnitID<b.UnitID; end
		return a.UnitID<b.UnitID;
	end);
	local index=1;
	while index<=#networkRemovalQueue do
		local entry=networkRemovalQueue[index];
		if entry.Cancelled then
			if networkRemovalBySerial[entry.Serial]==entry then networkRemovalBySerial[entry.Serial]=nil; end
			table.remove(networkRemovalQueue,index);
		elseif entry.QueuedTurn>=currentTurn then
			-- Cross one complete world-turn edge before any Gameplay mutation.
			break;
		else
			-- The synchronized active-index pass above is the only Gameplay
			-- authority.  An aged local publication that did not match a missing
			-- active identity is stale evidence and may only be forgotten.
			if networkRemovalBySerial[entry.Serial]==entry then networkRemovalBySerial[entry.Serial]=nil; end
			table.remove(networkRemovalQueue,index);
			Trace("network removal discarded serial="..entry.Serial.." reason=STALE_LOCAL_PUBLICATION");
		end
	end
end

local function OnCombat(attackerPlayerID,attackerUnitID,defenderPlayerID,defenderUnitID,attackerDistrictID,defenderDistrictID)
	local attackerSerial=CombatMonsterSerial(attackerPlayerID,attackerUnitID);
	local defenderSerial=CombatMonsterSerial(defenderPlayerID,defenderUnitID);
	if attackerSerial>0 then
		Log("engine combat attackerSerial="..attackerSerial.." defenderPlayer="..tostring(defenderPlayerID)
			.." defenderUnit="..tostring(defenderUnitID).." defenderDistrict="..tostring(defenderDistrictID));
	end
	if attackerSerial>0 and Dead(UnitManager.GetUnit(attackerPlayerID,attackerUnitID)) then
		FinalizeRemoval(attackerSerial,attackerPlayerID,attackerUnitID,defenderPlayerID,defenderUnitID,
			Game.GetCurrentGameTurn(),nil,false,"SYNCHRONIZED_COMBAT",true);
	end
	if defenderSerial>0 and Dead(UnitManager.GetUnit(defenderPlayerID,defenderUnitID)) then
		FinalizeRemoval(defenderSerial,defenderPlayerID,defenderUnitID,attackerPlayerID,attackerUnitID,
			Game.GetCurrentGameTurn(),nil,false,"SYNCHRONIZED_COMBAT",true);
	end
end

local function OnRemoved(playerID,unitID)
	if LOTM_MP_TurnSync.IsNetworkGame() then QueueNetworkRemoval(playerID,unitID); return; end
	local serial=LOTM_WORLD_State.NumberGameProperty(EngineKey(playerID,unitID),0);
	if serial>0 then
		local prefix=ScriptedKillerPrefix(playerID,unitID);
		local scriptedIdentityMatches=tostring(Game.GetProperty(prefix.."TARGET_KIND") or "")=="MONSTER"
			and LOTM_WORLD_State.NumberGameProperty(prefix.."TARGET_SERIAL",-1)==serial;
		local killerID=scriptedIdentityMatches and LOTM_WORLD_State.NumberGameProperty(prefix.."PLAYER",-1) or -1;
		local killerUnitID=LOTM_WORLD_State.NumberGameProperty(prefix.."UNIT",-1);
		-- Single-player is immediate, but it must use the same durable completion
		-- gate as combat/network reconciliation.  In particular, LIVE=0 is only
		-- committed after release, optional reward, and captured-identity cleanup.
		FinalizeRemoval(serial,playerID,unitID,killerID,killerUnitID,
			Game.GetCurrentGameTurn(),nil,false,"SINGLE_PLAYER_CALLBACK",true);
	end
end

local function OnTurn(playerID,isFirstTimeThisTurn)
	if isFirstTimeThisTurn==false then return; end
	if LOTM_MP_TurnSync.IsNetworkGame() then ProcessNetworkRemovals(playerID); end
	if playerID~=BarbarianID() then return; end
	for _,monster in ipairs(LiveMonsters()) do Act(monster); end
end

LOTM_MP_TurnSync.Add(OnTurn,"WorldMonsters");
Events.UnitRemovedFromMap.Add(OnRemoved);
GameEvents.OnCombatOccurred.Add(OnCombat);
LOTM_MP_TurnSync.RunStartup(function()
	MigrateActiveMonsterIndex();
	for _,monster in ipairs(LiveMonsters()) do ReconcileMonsterAbilities(monster); end
	if LOTM_MP_TurnSync.IsNetworkGame() then ReconcileActiveMonsterRemovals("ACTIVE_INDEX_STARTUP"); end
end,"WorldMonsters");
Log("initialized ordinary chances=30/30/30 bonus=30 heal=10 reward=500*era caps=1/2/2/3/4/5 cooldown=10 rescuePhase5=dynamic combat=engineSimulationAppliedByResource221Flow turn=multiplayerSynchronized");
