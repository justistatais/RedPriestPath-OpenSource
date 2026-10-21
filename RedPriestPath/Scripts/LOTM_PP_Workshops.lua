-- 全局失控工坊。保持原版 BARBARIAN_CAMP 改良与部落 AI，只在同步端
-- 记录分类、守卫、额外刷兵、0级来源强化和人类清营奖励。
include("LOTM_Effects");

local CAMP :number = GameInfo.Improvements.IMPROVEMENT_BARBARIAN_CAMP.Index;
local NORMAL_SEQUENCE_UNIT :number = GameInfo.Units.UNIT_LOTM_PP_PATH_HOLDER.Index;
local RESCUE_LEGACY_TYPES={
 [2]="UNIT_LOTM_RESCUE_LOST_CONTROL_LOW",
 [1]="UNIT_LOTM_RESCUE_LOST_CONTROL_MID",
 [0]="UNIT_LOTM_RESCUE_LOST_CONTROL_HIGH"
};
local RESCUE_FINAL_BATTLE_TYPES={};
for _,unitType in ipairs({"UNIT_LOTM_RESCUE_OUTER_GOD_AVATAR","UNIT_LOTM_RESCUE_OUTER_GOD_MINION"}) do
 local info=GameInfo.Units[unitType]; if info~=nil then RESCUE_FINAL_BATTLE_TYPES[info.Index]=true; end
end
local CLASSIFIED="LOTM_PP_WORKSHOP_CLASSIFIED"; local IS_WORKSHOP="LOTM_PP_WORKSHOP_IS_WORKSHOP";
local LEVEL="LOTM_PP_WORKSHOP_LEVEL"; local SETTLED="LOTM_PP_WORKSHOP_REWARD_SETTLED";
local SPAWNS="LOTM_PP_WORKSHOP_NORMAL_SPAWN_COUNT"; local CLEARER="LOTM_PP_WORKSHOP_LAST_HUMAN";
local SEQUENCE_CREATED="LOTM_PP_WORKSHOP_SEQUENCE_CREATED";
local m_internalCreate=false;
local m_barbarianID=nil;
-- Version 3 is a one-time resource-287 migration.  It deterministically
-- rediscovers resource-286 camps that may have been saved after their local
-- ImprovementAddedToMap callback but before the next synchronized anchor.
local WORKSHOP_REGISTRY_VERSION=3;
local WORKSHOP_REGISTRY_VERSION_KEY="LOTM_PP_WORKSHOP_REGISTRY_VERSION";
local WORKSHOP_REGISTRY_PLOTS_KEY="LOTM_PP_WORKSHOP_REGISTRY_PLOTS";
local CLASSIFICATION_VERSION=1;
local CLASSIFICATION_VERSION_PROPERTY="LOTM_PP_WORKSHOP_DETERMINISTIC_VERSION";
local BIRTH_RECONCILE_VERSION=1;
local BIRTH_RECONCILE_VERSION_PROPERTY="LOTM_PP_WORKSHOP_BIRTH_RECONCILE_VERSION";
local STABLE_MODULUS=2147483647;
local m_classificationSeed=nil;
local m_workshopPlots={};
local m_workshopSet={};
local m_workshopCoverage={};
local m_registryReady=false;
-- ImprovementAddedToMap is a local publication callback.  In network games
-- its delivery may be interleaved with synchronized player operations in a
-- different order on each peer, so it may only populate this Lua-local queue.
-- All Gameplay mutation is delayed to a later stable world-turn edge.
local m_networkImprovementAdditions={};
local m_networkImprovementPlots={};
local m_networkImprovementBoundaryTurn=nil;
local m_networkUnitAdditionsLocal={};
local m_networkUnitAdditionKeys={};
local m_networkUnitRemovalBatches={};
local m_networkUnitRemovalBatchKeys={};
local m_networkImprovementRemovals={};
local m_networkImprovementRemovalKeys={};
local m_networkImprovementRemovedPlots={};
local m_networkImprovementRemovalProcessedPlots={};
local m_networkImprovementRemovalProcessedPlotKeys={};
local m_networkUnitRemovals={};
local m_networkUnitRemovalKeys={};
local QueueNetworkWorkshopSettlement;
LOTM_PP_Workshops=LOTM_PP_Workshops or {};
local PATH="LOTM_PP_WORKSHOP_PATH";
local PATHS={"PP","RP","BE"};
local SEQUENCE_STRENGTH_ABILITY="ABILITY_LOTM_PP_WORKSHOP_SEQUENCE_STRENGTH";
local DYNAMIC_STRENGTH_ABILITY="ABILITY_LOTM_WORLD_DYNAMIC_STRENGTH";
local RESCUE_MONSTER_STRENGTH_ABILITY="ABILITY_LOTM_WORLD_MONSTER_FRENZY_STRENGTH_V2";
local RESCUE_TIER_STRENGTH_ABILITIES={{1,"ABILITY_LOTM_WORLD_MONSTER_TIER_MID_STRENGTH"},{0,"ABILITY_LOTM_WORLD_MONSTER_TIER_HIGH_STRENGTH"}};
local RESCUE_MONSTER_UNIT_TYPE="LOTM_RESCUE_CENTER_MONSTER_UNIT_TYPE";
local SEQUENCE_STRENGTH_ABILITIES={
 {10,SEQUENCE_STRENGTH_ABILITY},
 {20,"ABILITY_LOTM_PP_WORKSHOP_SEQUENCE_20"},
 {30,"ABILITY_LOTM_PP_WORKSHOP_SEQUENCE_30"},
 {25,"ABILITY_LOTM_PP_WORKSHOP_SEQUENCE_25"},
 {35,"ABILITY_LOTM_PP_WORKSHOP_SEQUENCE_35"},
 {45,"ABILITY_LOTM_PP_WORKSHOP_SEQUENCE_45"},
 {55,"ABILITY_LOTM_PP_WORKSHOP_SEQUENCE_55"},
 {65,"ABILITY_LOTM_PP_WORKSHOP_SEQUENCE_65"},
 {75,"ABILITY_LOTM_PP_WORKSHOP_SEQUENCE_75"},
 {85,"ABILITY_LOTM_PP_WORKSHOP_SEQUENCE_85"},
 {95,"ABILITY_LOTM_PP_WORKSHOP_SEQUENCE_95"}
};
local SEQUENCE_STRENGTH_COUNT="LOTM_PP_WORKSHOP_STRENGTH_COUNT";
local PERIOD_STRENGTH_PROPERTY="LOTM_RESCUE_PHASE5_BIRTH_BONUS";
local RESCUE_SEQUENCE_SERIAL="LOTM_RESCUE_PHASE4_SEQUENCE_SERIAL";
local CLEARER_UNIT="LOTM_PP_WORKSHOP_CLEARER_UNIT";
local CLASSIFIED_TURN="LOTM_RESCUE_WORKSHOP_CLASSIFIED_TURN";
local CAMP_EPOCH="LOTM_PP_WORKSHOP_CAMP_EPOCH";
local CAMP_TRIBE_INDEX="LOTM_PP_WORKSHOP_CAMP_TRIBE_INDEX";
local CAMP_REBUILD_PENDING="LOTM_PP_WORKSHOP_CAMP_REBUILD_PENDING";
local CAMP_EPOCH_COUNTER_PREFIX="LOTM_PP_WORKSHOP_CAMP_EPOCH_COUNTER:";
local MP_PENDING_SETTLEMENTS="LOTM_PP_WORKSHOP_MP_PENDING_SETTLEMENTS";
local MP_PENDING="LOTM_PP_WORKSHOP_MP_PENDING";
local MP_PENDING_OWNER="LOTM_PP_WORKSHOP_MP_PENDING_OWNER";
local MP_PENDING_CLEARER="LOTM_PP_WORKSHOP_MP_PENDING_CLEARER";
local MP_PENDING_CLEARER_UNIT="LOTM_PP_WORKSHOP_MP_PENDING_CLEARER_UNIT";
local MP_PENDING_LEVEL="LOTM_PP_WORKSHOP_MP_PENDING_LEVEL";
local MP_PENDING_PATH="LOTM_PP_WORKSHOP_MP_PENDING_PATH";
local MP_PENDING_CLASSIFIED_TURN="LOTM_PP_WORKSHOP_MP_PENDING_CLASSIFIED_TURN";
local MP_PENDING_CAMP_EPOCH="LOTM_PP_WORKSHOP_MP_PENDING_CAMP_EPOCH";
-- Multiplayer queues are committed at a synchronized turn boundary only.
-- Keep the enqueue turn separate from the legacy classification turn so a
-- callback arriving after the anchor event cannot be settled in the same
-- turn.  The two boundary markers also make reconnect/repeated callbacks
-- harmless: each queue is considered at most once per world turn.
local MP_PENDING_QUEUED_TURN="LOTM_PP_WORKSHOP_MP_PENDING_QUEUED_TURN";
local MP_UNIT_QUEUE_LAST_BOUNDARY="LOTM_PP_WORKSHOP_MP_UNIT_QUEUE_LAST_BOUNDARY";
local MP_SETTLEMENT_QUEUE_LAST_BOUNDARY="LOTM_PP_WORKSHOP_MP_SETTLEMENT_QUEUE_LAST_BOUNDARY";
local MP_UNIT_COMMITTED_TOKEN="LOTM_PP_WORKSHOP_MP_UNIT_COMMITTED_TOKEN";
local MP_UNIT_GENERATION_PROPERTY="LOTM_PP_WORKSHOP_MP_UNIT_GENERATION";
local MP_UNIT_EPOCH_PREFIX="LOTM_PP_WORKSHOP_MP_UNIT_EPOCH:";
local MP_UNIT_STAGE_PREFIX="LOTM_PP_WORKSHOP_MP_UNIT_STAGE:";
local MP_CHURCH_SETTLED="LOTM_PP_WORKSHOP_MP_CHURCH_SETTLED";
local MP_PHASE4_SETTLED="LOTM_PP_WORKSHOP_MP_PHASE4_SETTLED";
local MP_REWARD_SETTLED="LOTM_PP_WORKSHOP_MP_REWARD_SETTLED";
local MP_PENDING_UNIT_ADDITIONS="LOTM_PP_WORKSHOP_MP_PENDING_UNIT_ADDITIONS";
local PERIOD_STRENGTH_ABILITIES={
 {10,"ABILITY_LOTM_RESCUE_PERIOD_STRENGTH_10"},
 {20,"ABILITY_LOTM_RESCUE_PERIOD_STRENGTH_20"},
 {30,"ABILITY_LOTM_RESCUE_PERIOD_STRENGTH_30"},
 {40,"ABILITY_LOTM_RESCUE_PERIOD_STRENGTH_40"}
};
local SEQUENCE_NAMES={
 PP={[2]="LOC_LOTM_PP_ASTRONOMER_NAME",[1]="LOC_LOTM_PP_MYSTICIST_NAME",[0]="LOC_LOTM_PP_ENLIGHTENER_NAME"},
 RP={[2]="LOC_LOTM_RP_WORKSHOP_HARVESTER_NAME",[1]="LOC_LOTM_RP_WORKSHOP_WAR_BISHOP_NAME",[0]="LOC_LOTM_RP_WORKSHOP_CONQUEROR_NAME"},
 BE={[2]="LOC_LOTM_BE_WORKSHOP_CHAOS_MENTOR_NAME",[1]="LOC_LOTM_BE_WORKSHOP_FRENZY_MAGE_NAME",[0]="LOC_LOTM_BE_WORKSHOP_PRINCE_NAME"}
};
local RESCUE_NAMES={
 [2]="LOC_LOTM_WORLD_MONSTER_LOW_NAME",
 [1]="LOC_LOTM_WORLD_MONSTER_MID_NAME",
 [0]="LOC_LOTM_WORLD_MONSTER_HIGH_NAME"
};
local RESCUE_BONUS={[2]=15,[1]=25,[0]=35};
local PHASE4_VERSION=5;
LOTM_RESCUE_Phase4=LOTM_RESCUE_Phase4 or {};

local function Log(s) print("[LOTM_PP][Workshops] "..tostring(s)); end
local function NumberValue(value) if value==nil then return nil; end return tonumber(value); end
local function Verbose() return NumberValue(Game.GetProperty("LOTM_RESCUE_VERBOSE_LOGS"))==1; end
local function Trace(s) if Verbose() then Log(s); end end
local function RemoveNetworkPendingSettlementIndex(plotIndex)
 local indices={}; local seen={};
 for token in string.gmatch(tostring(Game.GetProperty(MP_PENDING_SETTLEMENTS) or ""),"[^,]+") do
  local current=tonumber(token);
  if current~=nil and current>=0 and current~=plotIndex and not seen[current] then
   seen[current]=true; indices[#indices+1]=current;
  end
 end
 table.sort(indices);
 local serialized=table.concat(indices,",");
 if tostring(Game.GetProperty(MP_PENDING_SETTLEMENTS) or "")~=serialized then
  Game.SetProperty(MP_PENDING_SETTLEMENTS,serialized);
 end
end
local function LocalNetworkUnitBatchKey(owner,unitID,queuedTurn)
 return table.concat({tonumber(queuedTurn) or -1,tonumber(owner) or -1,tonumber(unitID) or -1},":");
end
local function MarkNetworkUnitAdditionFiltered(unit)
 if unit==nil or LOTM_MP_TurnSync==nil or not LOTM_MP_TurnSync.IsNetworkGame() then return; end
 local owner=tonumber(unit:GetOwner()); local unitID=tonumber(unit:GetID());
 if owner==nil or unitID==nil then return; end
 local entry=m_networkUnitAdditionKeys[LocalNetworkUnitBatchKey(owner,unitID,Game.GetCurrentGameTurn())];
 if entry~=nil then entry.Filtered=true; end
end
function LOTM_PP_Workshops.MarkNetworkUnitFiltered(unit)
 MarkNetworkUnitAdditionFiltered(unit);
end
local function IsRescueMode()
 if LOTM_MP_TurnSync~=nil
  and type(LOTM_MP_TurnSync.IsRescueModeConfigured)=="function"
  and LOTM_MP_TurnSync.IsRescueModeConfigured() then return true; end
 return NumberValue(Game.GetProperty("LOTM_RESCUE_MODE"))==1;
end
-- Direct rescue monsters write their durable owner:unit -> serial index just
-- after InitUnit.  UnitAddedToMap can be delivered one turn later (especially
-- in single-player save/load), before the transient unit properties are
-- visible to this callback.  Treat a live durable index as monster identity so
-- the rescue normal-barbarian cleanup cannot kill freshly spawned Madness units.
-- The ordinary confirmed-spawn path remains guarded by LOTM_WORLD_Monsters.IsMonster(u).
local function IsDurableRescueMonster(playerID,unitID,unit)
 if unit~=nil and LOTM_WORLD_Monsters~=nil and LOTM_WORLD_Monsters.IsMonster~=nil
  and LOTM_WORLD_Monsters.IsMonster(unit) then return true; end
 local owner=tonumber(playerID); local id=tonumber(unitID); if owner==nil or id==nil then return false; end
 local serial=tonumber(Game.GetProperty("LOTM_WORLD_MONSTER_ENGINE:"..owner..":"..id) or 0) or 0;
 if serial<=0 then return false; end
 return (tonumber(Game.GetProperty("LOTM_WORLD_MONSTER:"..serial..":LIVE") or 0) or 0)==1;
end
local function NormalizeStableValue(value)
 local numeric=math.floor(tonumber(value) or 0)%STABLE_MODULUS;
 if numeric<0 then numeric=numeric+STABLE_MODULUS; end
 return numeric;
end
local function MixStableValue(value,component)
 return (NormalizeStableValue(value)*48271+NormalizeStableValue(component)+1)%STABLE_MODULUS;
end
local function StableTextValue(value)
 local result=0; local text=tostring(value or "");
 for index=1,#text do result=(result*131+string.byte(text,index))%STABLE_MODULUS; end
 return result;
end
local function ClassificationSeed()
 if m_classificationSeed==nil then
  local gameSeed=GameConfiguration~=nil and GameConfiguration.GetValue~=nil and GameConfiguration.GetValue("GAME_SYNC_RANDOM_SEED") or 0;
  local mapSeed=MapConfiguration~=nil and MapConfiguration.GetValue~=nil and MapConfiguration.GetValue("RANDOM_SEED") or nil;
  if mapSeed==nil and GameConfiguration~=nil and GameConfiguration.GetValue~=nil then mapSeed=GameConfiguration.GetValue("MAP_RANDOM_SEED"); end
  m_classificationSeed=MixStableValue(MixStableValue(104729,gameSeed),mapSeed or 0);
 end
 return m_classificationSeed;
end
local function StableClassificationRoll(plotIndex,channel,maxExclusive)
 local limit=math.floor(tonumber(maxExclusive) or 0); if limit<=1 then return 0; end
 local value=MixStableValue(ClassificationSeed(),plotIndex);
 value=MixStableValue(value,StableTextValue(channel));
 return value%limit;
end
local function BarbarianID()
 if m_barbarianID==nil or m_barbarianID<0 then
  m_barbarianID=-1;
  for _,p in ipairs(PlayerManager.GetAliveBarbarians()) do m_barbarianID=p:GetID(); break; end
 end
 return m_barbarianID;
end
local function IsWorkshopPlot(plot)
 return plot~=nil and plot:GetImprovementType()==CAMP and (plot:GetProperty(IS_WORKSHOP) or 0)==1;
end
local function InsertWorkshopIndex(plotIndex)
 if plotIndex==nil or plotIndex<0 or m_workshopSet[plotIndex] then return false; end
 local inserted=false;
 for position,current in ipairs(m_workshopPlots) do
  if plotIndex<current then table.insert(m_workshopPlots,position,plotIndex); inserted=true; break; end
 end
 if not inserted then m_workshopPlots[#m_workshopPlots+1]=plotIndex; end
 m_workshopSet[plotIndex]=true;
 return true;
end
local function SaveWorkshopRegistry()
 local serialized=table.concat(m_workshopPlots,",");
 if tostring(Game.GetProperty(WORKSHOP_REGISTRY_PLOTS_KEY) or "")~=serialized then Game.SetProperty(WORKSHOP_REGISTRY_PLOTS_KEY,serialized); end
 if NumberValue(Game.GetProperty(WORKSHOP_REGISTRY_VERSION_KEY))~=WORKSHOP_REGISTRY_VERSION then Game.SetProperty(WORKSHOP_REGISTRY_VERSION_KEY,WORKSHOP_REGISTRY_VERSION); end
end
local function AddWorkshopCoverage(plot)
 if not IsWorkshopPlot(plot) then return; end
 local plotIndex=plot:GetIndex();
 for dx=-3,3 do for dy=-3,3 do
  local covered=Map.GetPlotXYWithRangeCheck(plot:GetX(),plot:GetY(),dx,dy,3);
  if covered~=nil then
   local coveredIndex=covered:GetIndex(); local candidates=m_workshopCoverage[coveredIndex];
   if candidates==nil then candidates={}; m_workshopCoverage[coveredIndex]=candidates; end
   local exists=false; for _,candidate in ipairs(candidates) do if candidate==plotIndex then exists=true; break; end end
   if not exists then candidates[#candidates+1]=plotIndex; end
  end
 end end
end
local function BuildWorkshopCoverage()
 m_workshopCoverage={};
 for _,plotIndex in ipairs(m_workshopPlots) do AddWorkshopCoverage(Map.GetPlotByIndex(plotIndex)); end
end
local function RegisterWorkshopPlot(plot)
 if not IsWorkshopPlot(plot) then return false; end
 if not InsertWorkshopIndex(plot:GetIndex()) then return false; end
 if m_registryReady then AddWorkshopCoverage(plot); SaveWorkshopRegistry(); end
 return true;
end
local function UnregisterWorkshopPlot(plotIndex)
 if not m_workshopSet[plotIndex] then return false; end
 for position,current in ipairs(m_workshopPlots) do if current==plotIndex then table.remove(m_workshopPlots,position); break; end end
 m_workshopSet[plotIndex]=nil;
 if m_registryReady then BuildWorkshopCoverage(); SaveWorkshopRegistry(); end
 return true;
end
local function ResetWorkshopRegistry()
 m_workshopPlots={}; m_workshopSet={}; m_workshopCoverage={}; m_registryReady=false;
end
local function LoadWorkshopRegistry()
 ResetWorkshopRegistry();
 local serialized=tostring(Game.GetProperty(WORKSHOP_REGISTRY_PLOTS_KEY) or ""); local rejected=0;
 for token in string.gmatch(serialized,"[^,]+") do
  local plotIndex=tonumber(token); local plot=plotIndex~=nil and Map.GetPlotByIndex(plotIndex) or nil;
  if plotIndex~=nil and plotIndex>=0 and IsWorkshopPlot(plot) then
   InsertWorkshopIndex(plotIndex);
  else
   rejected=rejected+1;
   -- If a network save was taken after the camp vanished but before its
   -- local removal publication crossed the next stable turn, the serialized
   -- registry is the durable evidence. Recover only that stale indexed plot;
   -- never rescan the map during ordinary reloads.
   if LOTM_MP_TurnSync.IsNetworkGame() and plot~=nil
    and (plot:GetProperty(CLASSIFIED) or 0)==1
    and (plot:GetProperty(IS_WORKSHOP) or 0)==1
    and (plot:GetProperty(SETTLED) or 0)~=1
    and QueueNetworkWorkshopSettlement~=nil then
    QueueNetworkWorkshopSettlement(plot,plot:GetOwner());
   end
  end
 end
 BuildWorkshopCoverage(); m_registryReady=true; SaveWorkshopRegistry();
 return rejected;
end
local function SequenceEngineKey(playerID,unitID) return "LOTM_RESCUE_PHASE4_ENGINE_"..tostring(playerID).."_"..tostring(unitID); end
local function SequenceSerialEngineKey(playerID,unitID) return "LOTM_RESCUE_PHASE4_SERIAL_ENGINE_"..tostring(playerID).."_"..tostring(unitID); end
local function EnsurePhase4State()
 if not IsRescueMode() then return; end
 if NumberValue(Game.GetProperty("LOTM_RESCUE_PHASE4_VERSION"))~=PHASE4_VERSION then
  Game.SetProperty("LOTM_RESCUE_PHASE4_VERSION",PHASE4_VERSION);
  Game.SetProperty("LOTM_RESCUE_PHASE4_STATE","READY");
  Log("phase4 READY version="..PHASE4_VERSION.." centerMonster=true tierBonus=15/25/35 purification=false");
 end
 local phase=NumberValue(Game.GetProperty("LOTM_RESCUE_PHASE")) or 0;
 if phase<4 then Game.SetProperty("LOTM_RESCUE_PHASE",4); end
end
local function RescueUnitIndex(unit)
 local frozenType=unit~=nil and unit:GetProperty(RESCUE_MONSTER_UNIT_TYPE) or nil;
 local frozenInfo=frozenType~=nil and GameInfo.Units[frozenType] or nil;
 if frozenInfo~=nil then return frozenInfo.Index; end
 local barbarianID=BarbarianID();
 local resolved=barbarianID>=0 and LOTM_WORLD_Barbarians.ResolveMeleeBaseline(barbarianID) or nil;
 return resolved~=nil and resolved.Index or NORMAL_SEQUENCE_UNIT;
end
local function SequenceUnitIndex(level,unit)
 return IsRescueMode() and RescueUnitIndex(unit) or NORMAL_SEQUENCE_UNIT;
end
local function CurrentPeriodBonus()
 if not IsRescueMode() or LOTM_RESCUE_Phase5==nil or LOTM_RESCUE_Phase5.BirthStrengthBonus==nil then return 0; end
 return LOTM_RESCUE_Phase5.BirthStrengthBonus();
end
if LOTM_RESCUE_Phase4.OnWorkshopCleared==nil then
 function LOTM_RESCUE_Phase4.OnWorkshopCleared(workshopLevel,clearerPlayerID) end
end
if LOTM_RESCUE_Phase4.OnLostControlKilled==nil then
 function LOTM_RESCUE_Phase4.OnLostControlKilled(lostControlTier,killerPlayerID) end
end
local function IsHumanMajor(id)
 local p=Players[id]; return p~=nil and p:IsAlive() and p:IsMajor() and p:IsHuman();
end
local function IsLegalResolver(id)
 local p=Players[id]; if p==nil or not p:IsAlive() then return false; end
 if p:IsMajor() then return true; end
 local config=PlayerConfigurations[id];
 return config~=nil and config:GetCivilizationLevelTypeName()=="CIVILIZATION_LEVEL_CITY_STATE";
end
local function RollLevel(plotIndex)
 local r=StableClassificationRoll(plotIndex,"LEVEL",100);
 if IsRescueMode() and LOTM_RESCUE_Phase5~=nil and LOTM_RESCUE_Phase5.WorkshopLevelChances~=nil then
  local low,mid,high=LOTM_RESCUE_Phase5.WorkshopLevelChances();
  if r<low then return 2 elseif r<low+mid then return 1 else return 0; end
 end
 local era=Game.GetEras():GetCurrentEra();
 if era<=2 then return 2 elseif era==3 then return r<60 and 2 or 1
 elseif era==4 then return r<30 and 2 or (r<75 and 1 or 0)
 elseif era==5 then return r<20 and 2 or (r<55 and 1 or 0)
 elseif era==6 then return r<15 and 2 or (r<40 and 1 or 0)
 elseif era==7 then return r<10 and 2 or (r<30 and 1 or 0)
 else return r<10 and 2 or (r<25 and 1 or 0) end
end
local function EnsureSequenceStrength(unit,desiredCount)
 local ability=unit:GetAbility(); if ability==nil then Log("sequence ability interface missing unit="..tostring(unit:GetID())); return; end
 local baseline=NumberValue(desiredCount) or NumberValue(unit:GetProperty("LOTM_PP_WORKSHOP_BASELINE_V2"));
 if baseline==nil then local resolved=LOTM_WORLD_Barbarians.ResolveMeleeBaseline(unit:GetOwner()); baseline=resolved~=nil and resolved.Combat or 20; end
 local info=GameInfo.Units[unit:GetType()]; local unitBase=info~=nil and (NumberValue(info.Combat) or 20) or 20;
 local level=NumberValue(unit:GetProperty(LEVEL)) or 2;
 local rescue=IsRescueMode(); local bonus=rescue and (RESCUE_BONUS[level] or 15) or 10;
 local desired=rescue and 0 or math.max(0,baseline+bonus-unitBase); unit:SetProperty("LOTM_PP_WORKSHOP_BASELINE_V2",baseline); unit:SetProperty(SEQUENCE_STRENGTH_COUNT,rescue and bonus or desired);
 LOTM_Effects.SetAbilityCount(ability,DYNAMIC_STRENGTH_ABILITY,0);
 local selected=LOTM_Effects.SyncAbilityTiers(ability,SEQUENCE_STRENGTH_ABILITIES,not rescue and desired or nil);
 if GameInfo.UnitAbilities[RESCUE_MONSTER_STRENGTH_ABILITY]~=nil then LOTM_Effects.SetAbilityCount(ability,RESCUE_MONSTER_STRENGTH_ABILITY,rescue and 1 or 0); end
 LOTM_Effects.SyncAbilityTiers(ability,RESCUE_TIER_STRENGTH_ABILITIES,rescue and level or nil,GameInfo.UnitAbilities);
 local periodBonus=IsRescueMode() and (NumberValue(unit:GetProperty(PERIOD_STRENGTH_PROPERTY)) or 0) or 0;
 LOTM_Effects.SyncAbilityTiers(ability,PERIOD_STRENGTH_ABILITIES,periodBonus,GameInfo.UnitAbilities);
 if rescue and LOTM_RESCUE_Artifacts~=nil and LOTM_RESCUE_Artifacts.ApplyMonsterWeather~=nil then LOTM_RESCUE_Artifacts.ApplyMonsterWeather(unit); end
 Trace("sequence strength unit="..tostring(unit:GetID()).." B="..tostring(baseline).." level="..level.." bonus="..bonus.." periodBonus="..periodBonus.." target="..tostring(baseline+bonus+periodBonus).." ability="..tostring(rescue and RESCUE_MONSTER_STRENGTH_ABILITY or selected));
end
local function ApplySequenceName(unit,path,level)
 local numericLevel=NumberValue(level) or 2;
 local names=SEQUENCE_NAMES[path] or SEQUENCE_NAMES.PP;
 local tag=IsRescueMode() and (RESCUE_NAMES[numericLevel] or RESCUE_NAMES[2]) or (names[numericLevel] or names[2]);
 local veteranName=Locale.Lookup(tag);
 if LOTM_MP_TurnSync.IsNetworkGame() then
  veteranName=IsRescueMode() and ("LOTM_RESCUE_MONSTER_"..numericLevel)
   or ("LOTM_WORKSHOP_SEQUENCE_"..tostring(path or "PP").."_"..numericLevel);
 end
 local experience=unit:GetExperience(); experience:SetExperienceLocked(true); experience:SetVeteranName(veteranName);
end
local function EnsureSequenceSerial(unit)
 if not IsRescueMode() then return 0; end
 local serial=NumberValue(unit:GetProperty(RESCUE_SEQUENCE_SERIAL));
 if serial==nil or serial<=0 then serial=(NumberValue(Game.GetProperty("LOTM_RESCUE_PHASE4_NEXT_SEQUENCE_SERIAL")) or 0)+1; Game.SetProperty("LOTM_RESCUE_PHASE4_NEXT_SEQUENCE_SERIAL",serial); unit:SetProperty(RESCUE_SEQUENCE_SERIAL,serial); end
 Game.SetProperty(SequenceSerialEngineKey(unit:GetOwner(),unit:GetID()),serial);
 return serial;
end
local function MarkSequence(unit,level,plotIndex,path,baseline,periodBonus,baselineType)
 unit:SetProperty("LOTM_PP_WORKSHOP_SEQUENCE",1); unit:SetProperty("LOTM_PP_WORKSHOP_LEVEL",level); unit:SetProperty("LOTM_PP_WORKSHOP_PATH",path); unit:SetProperty("LOTM_PP_WORKSHOP_PLOT",plotIndex); unit:SetProperty("LOTM_PP_WORKSHOP_BASELINE",baseline or 20);
 if IsRescueMode() then local info=GameInfo.Units[unit:GetType()]; unit:SetProperty("LOTM_RESCUE_CENTER_MONSTER",1); unit:SetProperty(RESCUE_MONSTER_UNIT_TYPE,baselineType or (info~=nil and info.UnitType or nil)); end
 unit:SetProperty(PERIOD_STRENGTH_PROPERTY,IsRescueMode() and (NumberValue(periodBonus) or 0) or 0);
 MarkNetworkUnitAdditionFiltered(unit);
 EnsureSequenceStrength(unit,baseline or 20);
 if IsRescueMode() then Game.SetProperty(SequenceEngineKey(unit:GetOwner(),unit:GetID()),NumberValue(level) or 2); EnsureSequenceSerial(unit); end
 ApplySequenceName(unit,path,level); UnitManager.FinishMoves(unit);
end
local function EnsureSequence(plot)
 EnsurePhase4State();
 if IsRescueMode() then return; end
 if (plot:GetProperty(IS_WORKSHOP) or 0)~=1 then return; end
 local barb=BarbarianID(); if barb<0 then return; end
 local existingUnits=Units.GetUnitsInPlot(plot) or {};
 if LOTM_MP_TurnSync.IsNetworkGame() then table.sort(existingUnits,function(a,b) if a:GetOwner()~=b:GetOwner() then return a:GetOwner()<b:GetOwner(); end return a:GetID()<b:GetID(); end); end
 for _,u in ipairs(existingUnits) do if u:GetOwner()==barb and (u:GetProperty("LOTM_PP_WORKSHOP_SEQUENCE") or 0)==1 then
  local level=NumberValue(u:GetProperty(LEVEL) or plot:GetProperty(LEVEL)) or 2; local expectedType=SequenceUnitIndex(level,u);
  if u:GetType()~=expectedType then
   local baseline=NumberValue(u:GetProperty("LOTM_PP_WORKSHOP_BASELINE_V2")) or NumberValue(u:GetProperty("LOTM_PP_WORKSHOP_BASELINE")) or 20;
   local path=u:GetProperty(PATH) or plot:GetProperty(PATH) or "PP"; local periodBonus=NumberValue(u:GetProperty(PERIOD_STRENGTH_PROPERTY)) or 0;
   Game.SetProperty(SequenceEngineKey(u:GetOwner(),u:GetID()),nil); Game.SetProperty(SequenceSerialEngineKey(u:GetOwner(),u:GetID()),nil); UnitManager.Kill(u);
   m_internalCreate=true; local migrated=UnitManager.InitUnit(barb,expectedType,plot:GetX(),plot:GetY()); m_internalCreate=false;
   local expectedInfo=GameInfo.Units[expectedType];
   if migrated~=nil then MarkSequence(migrated,level,plot:GetIndex(),path,baseline,periodBonus,expectedInfo~=nil and expectedInfo.UnitType or nil); Log("sequence migrated plot="..plot:GetIndex().." level="..level.." unitType="..tostring(expectedInfo~=nil and expectedInfo.UnitType or expectedType).." centerMonster="..tostring(IsRescueMode())); end
   return;
  end
  if IsRescueMode() and u:GetProperty(RESCUE_MONSTER_UNIT_TYPE)==nil then local info=GameInfo.Units[u:GetType()]; if info~=nil then u:SetProperty(RESCUE_MONSTER_UNIT_TYPE,info.UnitType); u:SetProperty("LOTM_RESCUE_CENTER_MONSTER",1); end end
  ApplySequenceName(u,u:GetProperty(PATH) or plot:GetProperty(PATH) or "PP",level); if IsRescueMode() then Game.SetProperty(SequenceEngineKey(u:GetOwner(),u:GetID()),level); EnsureSequenceSerial(u); end EnsureSequenceStrength(u,nil); UnitManager.FinishMoves(u); return;
 end end
 if (plot:GetProperty(SEQUENCE_CREATED) or 0)==1 then return; end
 -- Replace only the original center guard; scouts and units outside the center remain original.
 local centerUnits=Units.GetUnitsInPlot(plot) or {};
 if LOTM_MP_TurnSync.IsNetworkGame() then
  table.sort(centerUnits,function(a,b)
   if a:GetOwner()~=b:GetOwner() then return a:GetOwner()<b:GetOwner(); end
   return a:GetID()<b:GetID();
  end);
 end
 for _,u in ipairs(centerUnits) do if u:GetOwner()==barb then UnitManager.Kill(u); break; end end
 local resolved=LOTM_WORLD_Barbarians.ResolveMeleeBaseline(barb); local baseline=resolved~=nil and resolved.Combat or 20;
 local level=plot:GetProperty(LEVEL) or 2; local periodBonus=CurrentPeriodBonus();
 local sequenceType=SequenceUnitIndex(level,nil); m_internalCreate=true; local u=UnitManager.InitUnit(barb,sequenceType,plot:GetX(),plot:GetY()); m_internalCreate=false;
 if u~=nil then local sequenceInfo=GameInfo.Units[sequenceType]; MarkSequence(u,level,plot:GetIndex(),plot:GetProperty(PATH) or "PP",baseline,periodBonus,resolved~=nil and resolved.UnitType or (sequenceInfo~=nil and sequenceInfo.UnitType or nil)); plot:SetProperty(SEQUENCE_CREATED,1); Log("sequence spawned plot="..plot:GetIndex().." path="..tostring(plot:GetProperty(PATH)).." B="..baseline.." periodBonus="..periodBonus.." unitType="..tostring(sequenceInfo~=nil and sequenceInfo.UnitType or sequenceType).." centerMonster="..tostring(IsRescueMode())); end
end
local function RollPath(level,plotIndex)
 local available={}; for _,path in ipairs(PATHS) do if LOTM_PP_HasAvailableArtifact==nil or LOTM_PP_HasAvailableArtifact(path,level) then table.insert(available,path); end end
 if #available==0 then return nil; end return available[StableClassificationRoll(plotIndex,"PATH:"..tostring(level),#available)+1];
end
local function ResolveCampTribeIndex(plot)
 if plot==nil or Game.GetBarbarianManager==nil then return nil; end
 local manager=Game.GetBarbarianManager();
 if manager==nil or manager.GetTribeIndexAtLocation==nil then return nil; end
 local ok,value=pcall(manager.GetTribeIndexAtLocation,manager,plot:GetX(),plot:GetY());
 value=ok and tonumber(value) or nil;
 return value~=nil and value>=0 and value or nil;
end
local function CampNeedsNewGeneration(plot,forced)
 if forced==true then return true; end
 local stored=NumberValue(plot~=nil and plot:GetProperty(CAMP_TRIBE_INDEX) or nil);
 local current=ResolveCampTribeIndex(plot);
 return stored~=nil and current~=nil and stored~=current;
end
local function ResetCampGeneration(plot)
 local plotIndex=plot:GetIndex();
 for _,unit in ipairs(Units.GetUnitsInPlot(plot) or {}) do
  if unit:GetOwner()==BarbarianID() and (unit:GetProperty("LOTM_PP_WORKSHOP_SEQUENCE") or 0)==1 then
   pcall(UnitManager.Kill,unit);
  end
 end
 UnregisterWorkshopPlot(plotIndex);
 for _,key in ipairs({CLASSIFIED,IS_WORKSHOP,LEVEL,PATH,SETTLED,SPAWNS,SEQUENCE_CREATED,CLEARER,CLEARER_UNIT,
   CLASSIFICATION_VERSION_PROPERTY,CLASSIFIED_TURN,"LOTM_RESCUE_PHASE5_LEVEL_PERIOD",
   "LOTM_RESCUE_PHASE5_LEVEL_CHANCES","LOTM_RESCUE_PHASE5_CLASSIFICATION_CHANCE",
   "LOTM_PP_WORKSHOP_EXTRA_SPAWN_COUNT","LOTM_WORLD_WORKSHOP_MONSTER_SERIAL",
   "LOTM_WORLD_WORKSHOP_MONSTER_COOLDOWN_UNTIL",MP_PENDING,MP_PENDING_OWNER,
   MP_PENDING_CLEARER,MP_PENDING_CLEARER_UNIT,MP_PENDING_LEVEL,MP_PENDING_PATH,
   MP_PENDING_CLASSIFIED_TURN,MP_PENDING_CAMP_EPOCH,MP_PENDING_QUEUED_TURN,MP_CHURCH_SETTLED,
   MP_PHASE4_SETTLED,MP_REWARD_SETTLED,CAMP_REBUILD_PENDING,BIRTH_RECONCILE_VERSION_PROPERTY}) do plot:SetProperty(key,nil); end
 RemoveNetworkPendingSettlementIndex(plotIndex);
 local counterKey=CAMP_EPOCH_COUNTER_PREFIX..tostring(plotIndex);
 local epoch=math.max(NumberValue(Game.GetProperty(counterKey)) or 0,
  NumberValue(plot:GetProperty(CAMP_EPOCH)) or 0)+1;
 Game.SetProperty(counterKey,epoch); plot:SetProperty(CAMP_EPOCH,epoch);
 plot:SetProperty(CAMP_TRIBE_INDEX,nil);
 local tribe=ResolveCampTribeIndex(plot); if tribe~=nil then plot:SetProperty(CAMP_TRIBE_INDEX,tribe); end
 Log("camp generation reset plot="..plotIndex.." epoch="..epoch.." tribe="..tostring(tribe));
end
local function EnsureCampGeneration(plot,forced)
 if CampNeedsNewGeneration(plot,forced) then
  if (plot:GetProperty(MP_PENDING) or 0)==1 then
   if (plot:GetProperty(CAMP_REBUILD_PENDING) or 0)~=1 then plot:SetProperty(CAMP_REBUILD_PENDING,1); end
   Trace("camp generation deferred for old settlement plot="..plot:GetIndex());
   return false;
  end
  ResetCampGeneration(plot); return true;
 end
 if NumberValue(plot:GetProperty(CAMP_EPOCH))==nil then
  local counterKey=CAMP_EPOCH_COUNTER_PREFIX..tostring(plot:GetIndex());
  local epoch=(NumberValue(Game.GetProperty(counterKey)) or 0)+1;
  Game.SetProperty(counterKey,epoch); plot:SetProperty(CAMP_EPOCH,epoch);
 end
 local tribe=ResolveCampTribeIndex(plot);
 if tribe~=nil and NumberValue(plot:GetProperty(CAMP_TRIBE_INDEX))~=tribe then plot:SetProperty(CAMP_TRIBE_INDEX,tribe); end
 return true;
end
local function Classify(plot)
 if plot==nil or plot:GetImprovementType()~=CAMP then return false; end
 if not EnsureCampGeneration(plot,(plot:GetProperty(CAMP_REBUILD_PENDING) or 0)==1) then return false; end
 if (plot:GetProperty(CLASSIFIED) or 0)~=1 then
  local chance=IsRescueMode() and LOTM_RESCUE_Phase5~=nil and LOTM_RESCUE_Phase5.WorkshopChance~=nil and LOTM_RESCUE_Phase5.WorkshopChance() or 50;
  local plotIndex=plot:GetIndex(); local classificationRoll=StableClassificationRoll(plotIndex,"CLASSIFICATION",100);
  local workshop=classificationRoll<chance;
  plot:SetProperty(CLASSIFIED,1); plot:SetProperty(IS_WORKSHOP,workshop and 1 or 0);
  plot:SetProperty(CLASSIFICATION_VERSION_PROPERTY,CLASSIFICATION_VERSION);
  if IsRescueMode() then plot:SetProperty(CLASSIFIED_TURN,Game.GetCurrentGameTurn()); end
  if workshop then local level=RollLevel(plotIndex); local path=RollPath(level,plotIndex); if path==nil then workshop=false; plot:SetProperty(IS_WORKSHOP,0); else plot:SetProperty(LEVEL,level); plot:SetProperty(PATH,path); end plot:SetProperty(SETTLED,0); plot:SetProperty(SPAWNS,0);
   if IsRescueMode() and LOTM_RESCUE_Phase5~=nil and LOTM_RESCUE_Phase5.WorkshopLevelChances~=nil then local low,mid,high=LOTM_RESCUE_Phase5.WorkshopLevelChances(); plot:SetProperty("LOTM_RESCUE_PHASE5_LEVEL_PERIOD",LOTM_RESCUE_Phase5.CurrentPeriod()); plot:SetProperty("LOTM_RESCUE_PHASE5_LEVEL_CHANCES",low..","..mid..","..high); end
  end
  plot:SetProperty("LOTM_RESCUE_PHASE5_CLASSIFICATION_CHANCE",chance);
	  -- Civ VI's C binding may return zero Lua values for a missing Property.
	  -- Store it first so tostring always receives exactly one argument.
	  local loggedLevel=plot:GetProperty(LEVEL); local loggedChances=plot:GetProperty("LOTM_RESCUE_PHASE5_LEVEL_CHANCES");
	  Log("classified plot="..plot:GetIndex().." workshop="..tostring(workshop).." chance="..chance.." roll="..classificationRoll.." deterministicVersion="..CLASSIFICATION_VERSION.." level="..tostring(loggedLevel or "NONE").." levelChances="..tostring(loggedChances or "NONE"));
 end
 if (plot:GetProperty(IS_WORKSHOP) or 0)==1 and plot:GetProperty(PATH)==nil then plot:SetProperty(PATH,RollPath(plot:GetProperty(LEVEL) or 2,plot:GetIndex()) or "PP"); end
 if (plot:GetProperty(IS_WORKSHOP) or 0)==1 then RegisterWorkshopPlot(plot); end
 EnsureSequence(plot);
 if (plot:GetProperty(IS_WORKSHOP) or 0)==1 and not IsRescueMode()
  and not LOTM_MP_TurnSync.IsNetworkGame()
  and LOTM_PP_Workshops.ReconcileSinglePlayerWorkshopBirthUnits~=nil
  and (NumberValue(plot:GetProperty(BIRTH_RECONCILE_VERSION_PROPERTY)) or 0)<BIRTH_RECONCILE_VERSION then
  local reconcileOK,reconcileError=pcall(LOTM_PP_Workshops.ReconcileSinglePlayerWorkshopBirthUnits,plot);
  if reconcileOK then
   plot:SetProperty(BIRTH_RECONCILE_VERSION_PROPERTY,BIRTH_RECONCILE_VERSION);
  else
   Log("single-player birth reconciliation failed plot="..plot:GetIndex()
    .." error="..tostring(reconcileError));
  end
 end
 return true;
end
local function QueueNetworkImprovementAdded(x,y,improvementType,ownerID)
 if improvementType~=CAMP then return; end
 local plot=Map.GetPlot(x,y); if plot==nil then return; end
 local plotIndex=plot:GetIndex(); local queuedTurn=Game.GetCurrentGameTurn();
 local existing=m_networkImprovementAdditions[plotIndex];
 if existing==nil then
  m_networkImprovementPlots[#m_networkImprovementPlots+1]=plotIndex;
  m_networkImprovementAdditions[plotIndex]={QueuedTurn=queuedTurn,PlotIndex=plotIndex,
    Rebuilt=m_networkImprovementRemovedPlots[plotIndex]==true};
 elseif queuedTurn<existing.QueuedTurn then
  existing.QueuedTurn=queuedTurn;
  existing.Rebuilt=existing.Rebuilt==true or m_networkImprovementRemovedPlots[plotIndex]==true;
 end
end
local function ClassifySinglePlayerImprovementAdded(x,y,improvementType,ownerID)
 if improvementType==CAMP then Classify(Map.GetPlot(x,y)); end
end
local function ProcessNetworkImprovementAdditions(playerID)
 if not LOTM_MP_TurnSync.IsNetworkGame() then return; end
 if not LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID) then return; end
 local currentTurn=Game.GetCurrentGameTurn();
 if m_networkImprovementBoundaryTurn==currentTurn then return; end
 m_networkImprovementBoundaryTurn=currentTurn;
 table.sort(m_networkImprovementPlots);
 local remaining={}; local classified=0;
 for _,plotIndex in ipairs(m_networkImprovementPlots) do
  local entry=m_networkImprovementAdditions[plotIndex];
  -- A callback batch must cross at least one complete world-turn boundary.
  if entry~=nil and entry.QueuedTurn<currentTurn then
   local plot=Map.GetPlotByIndex(plotIndex);
    local rebuildRequested=entry.Rebuilt==true or m_networkImprovementRemovedPlots[plotIndex]==true
     or (plot~=nil and (plot:GetProperty(CAMP_REBUILD_PENDING) or 0)==1);
    local rebuilt=plot~=nil and plot:GetImprovementType()==CAMP and CampNeedsNewGeneration(plot,rebuildRequested);
    if rebuilt and (plot:GetProperty(MP_PENDING) or 0)==1 then
    -- Preserve the old generation's plot-backed settlement until its next-turn
    -- checkpoint completes; only then may the new camp reuse these fields.
     if (plot:GetProperty(CAMP_REBUILD_PENDING) or 0)~=1 then plot:SetProperty(CAMP_REBUILD_PENDING,1); end
     remaining[#remaining+1]=plotIndex;
    else
     if plot~=nil and plot:GetImprovementType()==CAMP then
      if rebuildRequested then plot:SetProperty(CAMP_REBUILD_PENDING,1); end
      Classify(plot);
    end
    m_networkImprovementAdditions[plotIndex]=nil;
    classified=classified+1;
   end
  elseif entry~=nil then
   remaining[#remaining+1]=plotIndex;
  end
 end
 m_networkImprovementPlots=remaining;
 if classified>0 then
  Trace("network improvement batch turn="..currentTurn.." classified="..classified);
 end
end
local function NearestWorkshop(x,y)
 for radius=0,3 do for dx=-radius,radius do for dy=-radius,radius do local p=Map.GetPlotXYWithRangeCheck(x,y,dx,dy,radius); if p~=nil and p:GetImprovementType()==CAMP and (p:GetProperty(IS_WORKSHOP) or 0)==1 then return p; end end end end
 return nil;
end
local function IndexedNearestWorkshop(x,y)
 local source=Map.GetPlot(x,y); if source==nil then return nil,"NO_SOURCE",0; end
 local candidates=m_workshopCoverage[source:GetIndex()]; if candidates==nil or #candidates==0 then return nil,"NO_CANDIDATE",0; end
 if #candidates==1 then
  local camp=Map.GetPlotByIndex(candidates[1]);
  if IsWorkshopPlot(camp) then return camp,"UNIQUE",1; end
 end
 -- Overlapping coverage retains the exact legacy radius/dx/dy selection order.
 local legacyStarted=LOTM_UnitAddedPerf.BeginSection();
 local camp=NearestWorkshop(x,y);
 LOTM_UnitAddedPerf.EndSection("Workshops.Lookup.Legacy",legacyStarted,#candidates);
 return camp,#candidates==1 and "STALE_LEGACY" or "OVERLAP_LEGACY",#candidates;
end
local function InitializeWorkshopRegistry()
 local version=NumberValue(Game.GetProperty(WORKSHOP_REGISTRY_VERSION_KEY)); local campCount=0;
 if version~=WORKSHOP_REGISTRY_VERSION then
  ResetWorkshopRegistry();
  for i=0,Map.GetPlotCount()-1 do
   local plot=Map.GetPlotByIndex(i);
   if plot:GetImprovementType()==CAMP then campCount=campCount+1; Classify(plot); end
  end
  BuildWorkshopCoverage(); m_registryReady=true; SaveWorkshopRegistry();
  Log("registry initialized version="..WORKSHOP_REGISTRY_VERSION.." mode=MIGRATION_FULL_SCAN camps="..campCount.." workshops="..#m_workshopPlots);
  return campCount;
 end
 local rejected=LoadWorkshopRegistry();
 for _,plotIndex in ipairs(m_workshopPlots) do local plot=Map.GetPlotByIndex(plotIndex); if plot~=nil then Classify(plot); campCount=campCount+1; end end
 Log("registry initialized version="..WORKSHOP_REGISTRY_VERSION.." mode=PERSISTED_INCREMENTAL workshops="..campCount.." rejected="..rejected);
 return campCount;
end
local function CreateExtra(source,camp)
 local barb=BarbarianID(); if barb<0 then return; end
 for dir=0,5 do local p=Map.GetAdjacentPlot(camp:GetX(),camp:GetY(),dir); if p~=nil and not p:IsWater() and p:GetUnitCount()==0 then
  m_internalCreate=true; local u=UnitManager.InitUnit(barb,source:GetType(),p:GetX(),p:GetY()); m_internalCreate=false;
  if u~=nil then u:SetProperty("LOTM_PP_WORKSHOP_EXTRA",1); u:SetProperty("LOTM_PP_WORKSHOP_SOURCE",camp:GetIndex());
   MarkNetworkUnitAdditionFiltered(u);
   if (camp:GetProperty(LEVEL) or 2)==0 then local a=u:GetAbility(); if a~=nil then a:ChangeAbilityCount("ABILITY_LOTM_PP_WORKSHOP_LEVEL0_STRENGTH",1); end end
   camp:SetProperty("LOTM_PP_WORKSHOP_EXTRA_SPAWN_COUNT",(camp:GetProperty("LOTM_PP_WORKSHOP_EXTRA_SPAWN_COUNT") or 0)+1);
   Game.SetProperty("LOTM_PP_WORKSHOP_EXTRA_SPAWN_TOTAL",LOTM_WORLD_State.NumberGameProperty("LOTM_PP_WORKSHOP_EXTRA_SPAWN_TOTAL",0)+1);
   Trace("extra unit plot="..camp:GetIndex().." type="..source:GetType().." extraCount="..tostring(camp:GetProperty("LOTM_PP_WORKSHOP_EXTRA_SPAWN_COUNT"))); return;
  end
 end end
end
local function NetworkPendingUnitAdditions()
 local result={}; local seen={};
 for token in string.gmatch(tostring(Game.GetProperty(MP_PENDING_UNIT_ADDITIONS) or ""),"[^;]+") do
  local fields={}; for value in string.gmatch(token,"[^:]+") do fields[#fields+1]=value; end
  local turn=tonumber(fields[1]); local camp=tonumber(fields[2]); local owner=tonumber(fields[3]);
  local unitID=tonumber(fields[4]); local unitType=tonumber(fields[5]);
  if turn~=nil and camp~=nil and owner~=nil and unitID~=nil and unitType~=nil then
   -- Five fields are the resource-291 legacy format. They remain consumable,
   -- but without a generation token they can never mutate a possibly reused
   -- live unit. New entries append Removed and Generation fields.
   local removed=#fields>=6 and tonumber(fields[6])==1 or false;
    local generation=#fields>=7 and tostring(fields[7]) or "LEGACY";
    local campEpoch=#fields>=8 and tonumber(fields[8]) or nil;
    local normalizedCampEpoch=campEpoch~=nil and campEpoch or "LEGACY";
    local key=table.concat({turn,camp,owner,unitID,unitType,removed and 1 or 0,generation,normalizedCampEpoch},":");
   if not seen[key] then
    seen[key]=true;
    -- `Turn` was the name used by the first network queue format.  Expose
    -- the same value as QueuedTurn internally so processing can explicitly
    -- enforce a full-turn delay while still reading old saves.
    result[#result+1]={QueuedTurn=turn,Turn=turn,Camp=camp,Owner=owner,Unit=unitID,
     Type=unitType,Removed=removed,Generation=generation,CampEpoch=normalizedCampEpoch};
   end
  end
 end
 table.sort(result,function(a,b)
  if a.QueuedTurn~=b.QueuedTurn then return a.QueuedTurn<b.QueuedTurn; end
  if a.Camp~=b.Camp then return a.Camp<b.Camp; end
  if a.Owner~=b.Owner then return a.Owner<b.Owner; end
  if a.Unit~=b.Unit then return a.Unit<b.Unit; end
  if a.Type~=b.Type then return a.Type<b.Type; end
  if a.Removed~=b.Removed then return a.Removed==true; end
   if tostring(a.Generation or "")~=tostring(b.Generation or "") then return tostring(a.Generation or "")<tostring(b.Generation or ""); end
   return tostring(a.CampEpoch or "LEGACY")<tostring(b.CampEpoch or "LEGACY");
 end);
 return result;
end
local function SaveNetworkPendingUnitAdditions(entries)
 local values={};
 for _,entry in ipairs(entries) do
  values[#values+1]=table.concat({entry.QueuedTurn or entry.Turn,entry.Camp,entry.Owner,
    entry.Unit,entry.Type,entry.Removed==true and 1 or 0,entry.Generation or "LEGACY",
    entry.CampEpoch or "LEGACY"},":");
 end
 local serialized=table.concat(values,";");
 if tostring(Game.GetProperty(MP_PENDING_UNIT_ADDITIONS) or "")~=serialized then
  Game.SetProperty(MP_PENDING_UNIT_ADDITIONS,serialized);
 end
end
local function NetworkUnitEntryToken(entry)
  return table.concat({entry.QueuedTurn or entry.Turn,entry.Camp,entry.Owner,entry.Unit,
   entry.Type,entry.Removed==true and 1 or 0,entry.Generation or "LEGACY",
   entry.CampEpoch or "LEGACY"},":");
end
local function GenerationNetworkUnitEntryToken(entry)
 return table.concat({entry.QueuedTurn or entry.Turn,entry.Camp,entry.Owner,entry.Unit,
  entry.Type,entry.Removed==true and 1 or 0,entry.Generation or "LEGACY"},":");
end
local function LegacyNetworkUnitEntryToken(entry)
 return table.concat({entry.QueuedTurn or entry.Turn,entry.Camp,entry.Owner,entry.Unit,entry.Type},":");
end
local function NetworkUnitStageKey(entry,suffix)
 return MP_UNIT_STAGE_PREFIX..NetworkUnitEntryToken(entry)..":"..tostring(suffix);
end
local function ClearNetworkUnitStages(entry)
 for _,suffix in ipairs({"STAGE","COUNT_TARGET","GLOBAL_TARGET","EXTRA_COUNT_TARGET","EXTRA_GLOBAL_TARGET"}) do
  Game.SetProperty(NetworkUnitStageKey(entry,suffix),nil);
 end
end
local function NextSynchronizedUnitGeneration(owner,unitID)
 local key=MP_UNIT_EPOCH_PREFIX..tostring(owner)..":"..tostring(unitID);
 local epoch=(NumberValue(Game.GetProperty(key)) or 0)+1;
 Game.SetProperty(key,epoch);
 return table.concat({"S",owner,unitID,epoch},".");
end
local function RecoverCommittedNetworkUnitEntry(entries)
 local committed=tostring(Game.GetProperty(MP_UNIT_COMMITTED_TOKEN) or "");
 if committed=="" then return entries; end
 for index,entry in ipairs(entries) do
  if NetworkUnitEntryToken(entry)==committed or GenerationNetworkUnitEntryToken(entry)==committed
   or LegacyNetworkUnitEntryToken(entry)==committed then
   table.remove(entries,index);
   SaveNetworkPendingUnitAdditions(entries);
   Trace("network unit recovered committed token="..committed);
   break;
  end
 end
 -- If the queue write succeeded but clearing this marker did not, the token is
 -- absent and can also be discarded safely.  Only one item is ever in flight.
 Game.SetProperty(MP_UNIT_COMMITTED_TOKEN,nil);
 return entries;
end
local function QueueNetworkWorkshopUnitAddition(unit,camp,queuedTurnOverride,ownerOverride,unitIDOverride,unitTypeOverride,generationOverride,removedOverride,campEpochOverride)
 local entries=NetworkPendingUnitAdditions();
 local queuedTurn=tonumber(queuedTurnOverride) or Game.GetCurrentGameTurn();
 local owner=unit~=nil and unit:GetOwner() or tonumber(ownerOverride);
 local unitID=unit~=nil and unit:GetID() or tonumber(unitIDOverride);
 local unitType=unit~=nil and unit:GetType() or tonumber(unitTypeOverride);
 if owner==nil or unitID==nil or unitType==nil then return nil,false; end
 local campEpoch=tonumber(campEpochOverride); if campEpoch==nil then campEpoch=NumberValue(camp:GetProperty(CAMP_EPOCH)) or 0; end
 -- A local callback batch is normalized before reaching this function, but a
 -- reconnect can still replay the same captured fact while its durable queue
 -- entry already exists. Detect that identity before allocating a generation:
 -- generation epochs are authoritative state and may advance only for a fact
 -- that will actually be appended to the persistent queue.
 for _,entry in ipairs(entries) do
  if entry.QueuedTurn==queuedTurn and entry.Camp==camp:GetIndex() and entry.Owner==owner
   and entry.Unit==unitID and entry.Type==unitType and entry.Removed==(removedOverride==true)
   and tostring(entry.CampEpoch or "LEGACY")==tostring(campEpoch) then
   return tostring(entry.Generation or ""),false;
  end
 end
 local generation=tostring(generationOverride or "");
 if generation=="" then generation=NextSynchronizedUnitGeneration(owner,unitID); end
 local candidate={QueuedTurn=queuedTurn,Turn=queuedTurn,Camp=camp:GetIndex(),Owner=owner,
  Unit=unitID,Type=unitType,Generation=generation,Removed=removedOverride==true,CampEpoch=campEpoch};
 entries[#entries+1]=candidate;
 table.sort(entries,function(a,b)
  if a.QueuedTurn~=b.QueuedTurn then return a.QueuedTurn<b.QueuedTurn; end
  if a.Camp~=b.Camp then return a.Camp<b.Camp; end
  if a.Owner~=b.Owner then return a.Owner<b.Owner; end
  if a.Unit~=b.Unit then return a.Unit<b.Unit; end
  if a.Type~=b.Type then return a.Type<b.Type; end
  if a.Removed~=b.Removed then return a.Removed==true; end
  if tostring(a.Generation)~=tostring(b.Generation) then return tostring(a.Generation)<tostring(b.Generation); end
  return tostring(a.CampEpoch or "LEGACY")<tostring(b.CampEpoch or "LEGACY");
 end);
 SaveNetworkPendingUnitAdditions(entries);
 Trace("network unit queued turn="..candidate.QueuedTurn.." camp="..candidate.Camp
   .." owner="..candidate.Owner.." unit="..candidate.Unit.." type="..candidate.Type
   .." generation="..candidate.Generation.." campEpoch="..tostring(candidate.CampEpoch)
   .." removed="..tostring(candidate.Removed));
 return generation,true;
end

local function CreateNetworkExtra(sourceType,camp,entry)
 local barb=BarbarianID(); if barb<0 then return; end
 local eventToken=NetworkUnitEntryToken(entry); local existing=nil; local spawnPlot=nil;
 for dir=0,5 do
  local plot=Map.GetAdjacentPlot(camp:GetX(),camp:GetY(),dir);
  if plot~=nil then
   for _,candidate in ipairs(Units.GetUnitsInPlot(plot) or {}) do
    if candidate:GetProperty("LOTM_PP_WORKSHOP_EXTRA_EVENT_TOKEN")==eventToken then existing=candidate; break; end
   end
   if existing~=nil then break; end
   if spawnPlot==nil and not plot:IsWater() and plot:GetUnitCount()==0 then spawnPlot=plot; end
  end
 end
 local extraTarget=NumberValue(Game.GetProperty(NetworkUnitStageKey(entry,"EXTRA_COUNT_TARGET")));
 local globalTarget=NumberValue(Game.GetProperty(NetworkUnitStageKey(entry,"EXTRA_GLOBAL_TARGET")));
 if existing==nil and spawnPlot~=nil then
  if extraTarget==nil then
   extraTarget=(NumberValue(camp:GetProperty("LOTM_PP_WORKSHOP_EXTRA_SPAWN_COUNT")) or 0)+1;
   Game.SetProperty(NetworkUnitStageKey(entry,"EXTRA_COUNT_TARGET"),extraTarget);
  end
  if globalTarget==nil then
   globalTarget=LOTM_WORLD_State.NumberGameProperty("LOTM_PP_WORKSHOP_EXTRA_SPAWN_TOTAL",0)+1;
   Game.SetProperty(NetworkUnitStageKey(entry,"EXTRA_GLOBAL_TARGET"),globalTarget);
  end
  m_internalCreate=true;
  local initOK,unit=pcall(UnitManager.InitUnit,barb,sourceType,spawnPlot:GetX(),spawnPlot:GetY());
  m_internalCreate=false;
  if not initOK then error(unit); end
  if unit~=nil then
   unit:SetProperty("LOTM_PP_WORKSHOP_EXTRA_EVENT_TOKEN",eventToken);
   unit:SetProperty("LOTM_PP_WORKSHOP_EXTRA",1); unit:SetProperty("LOTM_PP_WORKSHOP_SOURCE",camp:GetIndex());
   MarkNetworkUnitAdditionFiltered(unit); existing=unit;
  end
 end
 if existing~=nil then
  if (camp:GetProperty(LEVEL) or 2)==0 then
   LOTM_Effects.SetAbilityCount(existing:GetAbility(),"ABILITY_LOTM_PP_WORKSHOP_LEVEL0_STRENGTH",1);
  end
  if extraTarget~=nil and (NumberValue(camp:GetProperty("LOTM_PP_WORKSHOP_EXTRA_SPAWN_COUNT")) or 0)<extraTarget then camp:SetProperty("LOTM_PP_WORKSHOP_EXTRA_SPAWN_COUNT",extraTarget); end
  if globalTarget~=nil and LOTM_WORLD_State.NumberGameProperty("LOTM_PP_WORKSHOP_EXTRA_SPAWN_TOTAL",0)<globalTarget then Game.SetProperty("LOTM_PP_WORKSHOP_EXTRA_SPAWN_TOTAL",globalTarget); end
  Trace("network extra unit plot="..camp:GetIndex().." type="..sourceType.." extraCount="..tostring(camp:GetProperty("LOTM_PP_WORKSHOP_EXTRA_SPAWN_COUNT")));
 end
end
local function NetworkQueueBoundary(playerID,lastBoundaryProperty)
 if not LOTM_MP_TurnSync.IsNetworkGame() then return false,nil; end
 if not LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID) then return false,nil; end
 local currentTurn=Game.GetCurrentGameTurn();
 if NumberValue(Game.GetProperty(lastBoundaryProperty))==currentTurn then return false,currentTurn; end
 -- Claim the stable anchor before touching either queue.  A repeated
 -- PlayerTurnStarted/reconnect callback in this world turn must not replay a
 -- partially completed batch; an unsuccessful item remains for the next
 -- boundary.
 Game.SetProperty(lastBoundaryProperty,currentTurn);
 return true,currentTurn;
end

local function ProcessNetworkWorkshopUnitAddition(entry,camp)
 if camp==nil then return true,"WORKSHOP_GONE"; end
 if not IsWorkshopPlot(camp) then return true,"WORKSHOP_GONE"; end
 local currentCampEpoch=NumberValue(camp:GetProperty(CAMP_EPOCH));
 local capturedCampEpoch=tonumber(entry.CampEpoch);
 if (camp:GetProperty(CAMP_REBUILD_PENDING) or 0)==1
  or (capturedCampEpoch~=nil and currentCampEpoch~=capturedCampEpoch) then
  Trace("network unit camp generation detached plot="..entry.Camp
   .." captured="..tostring(entry.CampEpoch).." live="..tostring(currentCampEpoch));
  return true,"STALE_CAMP_GENERATION";
 end
 local stage=NumberValue(Game.GetProperty(NetworkUnitStageKey(entry,"STAGE"))) or 0;
 local unit=UnitManager.GetUnit(entry.Owner,entry.Unit);
 local unitGeneration=unit~=nil and unit:GetProperty(MP_UNIT_GENERATION_PROPERTY) or nil;
 local generationMatches=entry.Removed~=true and unit~=nil and unit:GetType()==entry.Type
  and entry.Generation~="LEGACY" and tostring(unitGeneration or "")==tostring(entry.Generation or "");
 if stage<1 and generationMatches then
  unit:SetProperty("LOTM_PP_WORKSHOP_SOURCE",entry.Camp);
  if (camp:GetProperty(LEVEL) or 2)==0 then
   local ability=unit:GetAbility();
   LOTM_Effects.SetAbilityCount(ability,"ABILITY_LOTM_PP_WORKSHOP_LEVEL0_STRENGTH",1);
  end
 elseif stage<1 then
  Trace("network unit generation detached owner="..entry.Owner.." unit="..entry.Unit
   .." captured="..tostring(entry.Generation).." live="..tostring(unitGeneration)
   .." removed="..tostring(entry.Removed));
 end
 if stage<1 then Game.SetProperty(NetworkUnitStageKey(entry,"STAGE"),1); stage=1; end
 local count=NumberValue(Game.GetProperty(NetworkUnitStageKey(entry,"COUNT_TARGET")));
 local globalCount=NumberValue(Game.GetProperty(NetworkUnitStageKey(entry,"GLOBAL_TARGET")));
 if count==nil then
  count=(NumberValue(camp:GetProperty(SPAWNS)) or 0)+1;
  Game.SetProperty(NetworkUnitStageKey(entry,"COUNT_TARGET"),count);
 end
 if globalCount==nil then
  globalCount=LOTM_WORLD_State.NumberGameProperty("LOTM_PP_WORKSHOP_NORMAL_SPAWN_TOTAL",0)+1;
  Game.SetProperty(NetworkUnitStageKey(entry,"GLOBAL_TARGET"),globalCount);
 end
 if stage<2 then
  if (NumberValue(camp:GetProperty(SPAWNS)) or 0)<count then camp:SetProperty(SPAWNS,count); end
  if LOTM_WORLD_State.NumberGameProperty("LOTM_PP_WORKSHOP_NORMAL_SPAWN_TOTAL",0)<globalCount then Game.SetProperty("LOTM_PP_WORKSHOP_NORMAL_SPAWN_TOTAL",globalCount); end
  Game.SetProperty(NetworkUnitStageKey(entry,"STAGE"),2); stage=2;
 end
 Trace("network normal spawn turn="..tostring(entry.QueuedTurn or entry.Turn).." plot="..entry.Camp.." type="..entry.Type
  .." normalCount="..count.." globalNormal="..tostring(Game.GetProperty("LOTM_PP_WORKSHOP_NORMAL_SPAWN_TOTAL")));
 if stage<3 then
  if (camp:GetProperty(LEVEL) or 2)<=1 and count%2==0 then CreateNetworkExtra(entry.Type,camp,entry); end
  Game.SetProperty(NetworkUnitStageKey(entry,"STAGE"),3); stage=3;
 end
 if stage<4 then
  local eventToken=NetworkUnitEntryToken(entry);
  if LOTM_WORLD_Monsters~=nil and LOTM_WORLD_Monsters.TrySpawnFromWorkshopNetwork~=nil then
   LOTM_WORLD_Monsters.TrySpawnFromWorkshopNetwork(camp,entry.Owner,eventToken);
  elseif generationMatches and LOTM_WORLD_Monsters~=nil and LOTM_WORLD_Monsters.TrySpawnFromWorkshop~=nil then
   LOTM_WORLD_Monsters.TrySpawnFromWorkshop(camp,unit);
  end
  Game.SetProperty(NetworkUnitStageKey(entry,"STAGE"),4);
 end
 return true,"SETTLED";
end

local function ProcessNetworkWorkshopUnitAdditions(playerID)
 local claimed,currentTurn=NetworkQueueBoundary(playerID,MP_UNIT_QUEUE_LAST_BOUNDARY);
 if not claimed then return; end
 local entries=RecoverCommittedNetworkUnitEntry(NetworkPendingUnitAdditions());
 local index=1;
 while index<=#entries do
  local entry=entries[index];
  -- Entries created after this anchor are deliberately left for the next
  -- turn, ensuring all peers observe one complete callback batch.
  if (entry.QueuedTurn or entry.Turn or currentTurn)>=currentTurn then
   index=index+1;
  else
   local ok,result=pcall(ProcessNetworkWorkshopUnitAddition,entry,Map.GetPlotByIndex(entry.Camp));
   if not ok then Log("network unit settlement error turn="..tostring(entry.QueuedTurn or entry.Turn)
    .." camp="..entry.Camp.." owner="..entry.Owner.." unit="..entry.Unit.." error="..tostring(result)); end
   if not ok then
    -- Keep this and every later sorted entry for a future synchronized
    -- boundary.  Earlier entries were already removed and checkpointed.  Let
    -- the ordered dispatcher latch the unexpected exception fail-closed.
    error(result);
   end
   -- Inner effects have replay-safe stages and monotonic targets. This final
   -- commit marker only bridges completed settlement and queue removal.
   Game.SetProperty(MP_UNIT_COMMITTED_TOKEN,NetworkUnitEntryToken(entry));
   table.remove(entries,index);
   SaveNetworkPendingUnitAdditions(entries);
   ClearNetworkUnitStages(entry);
   Game.SetProperty(MP_UNIT_COMMITTED_TOKEN,nil);
   Trace("network unit checkpoint turn="..tostring(entry.QueuedTurn or entry.Turn)
    .." camp="..entry.Camp.." owner="..entry.Owner.." unit="..entry.Unit.." result="..tostring(result));
  end
 end
end
local function QueueLocalNetworkUnitAdded(playerID,unitID,x,y)
 local normalizedPlayerID=tonumber(playerID); local normalizedUnitID=tonumber(unitID);
 if normalizedPlayerID==nil or normalizedUnitID==nil then return; end
 local queuedTurn=Game.GetCurrentGameTurn();
 local key=LocalNetworkUnitBatchKey(normalizedPlayerID,normalizedUnitID,queuedTurn);
 local rescueCleanup=IsRescueMode();
 -- UnitRemovedFromMap and UnitAddedToMap are local publications and their
 -- relative order is not an authority signal. Once this owner:unitID batch
 -- has any removal fact, every same-turn addition loses, including an Add
 -- delivered after the Remove for a newly reused engine ID.
 if not rescueCleanup and m_networkUnitRemovalBatches[key]~=nil then return; end
 local unit=UnitManager.GetUnit(normalizedPlayerID,normalizedUnitID);
 -- A load-time UnitAdded replay for an already captured/settled generation is
 -- not a new spawn fact. Both markers are written only at synchronized stages.
 if not rescueCleanup and unit~=nil and (unit:GetProperty(MP_UNIT_GENERATION_PROPERTY)~=nil
  or unit:GetProperty("LOTM_PP_WORKSHOP_SOURCE")~=nil) then return; end
 local filtered=unit~=nil and ((unit:GetProperty("LOTM_PP_WORKSHOP_SEQUENCE") or 0)==1
  or (unit:GetProperty("LOTM_PP_WORKSHOP_EXTRA") or 0)==1
  or (LOTM_WORLD_Monsters~=nil and LOTM_WORLD_Monsters.IsMonster~=nil and LOTM_WORLD_Monsters.IsMonster(unit))) or false;
 local unitType=unit~=nil and unit:GetType() or nil;
 -- The engine's unit ID is a generation boundary.  Do not add a client-local
 -- arrival ordinal: duplicate callback delivery must serialize to the same
 -- captured token on every peer.
 local captureToken=table.concat({"C",queuedTurn,normalizedPlayerID,normalizedUnitID,
  unitType or -1,tonumber(x) or -1,tonumber(y) or -1},".");
 local existing=m_networkUnitAdditionKeys[key];
 if existing~=nil then
  if rescueCleanup then existing.RescueCleanup=true; existing.Cancelled=false; return; end
  -- Exact duplicate delivery is one fact. Conflicting same-batch observations
  -- cannot identify a stable engine generation, so remember the ambiguity and
  -- fail closed independent of which observation arrived first.
  if tostring(existing.CaptureToken or "")~=captureToken then
   existing.Ambiguous=true; existing.Cancelled=true;
  end
  if filtered then existing.Filtered=true; end
  return;
 end
 local entry={PlayerID=normalizedPlayerID,UnitID=normalizedUnitID,
  X=tonumber(x),Y=tonumber(y),QueuedTurn=queuedTurn,Key=key,
  UnitType=unitType,Filtered=filtered,CaptureToken=captureToken,RemovedBeforeSettlement=false,
  RescueCleanup=rescueCleanup};
 m_networkUnitAdditionsLocal[#m_networkUnitAdditionsLocal+1]=entry;
 m_networkUnitAdditionKeys[key]=entry;
end
local function ProcessUnitAdded(playerID,unitID,x,y,fromNetworkQueue,queuedTurnOverride,capturedUnitType,capturedFiltered,capturedGeneration,capturedRemoved)
 if playerID~=BarbarianID() then LOTM_UnitAddedPerf.MarkSection("Workshops.Entry.NonBarbarian",1); return; end
 -- UnitAddedToMap is only a local publication callback.  In a network game
 -- do not let creator-local timing flags decide whether a unit enters the
 -- queue: those flags can be true on one peer while the same publication is
 -- delivered after the creator returned on another.  The later synchronized
 -- consumer filters from captured facts and durable unit properties instead.
 if LOTM_MP_TurnSync.IsNetworkGame() and not fromNetworkQueue then
  QueueLocalNetworkUnitAdded(playerID,unitID,x,y); LOTM_UnitAddedPerf.MarkSection("Workshops.Entry.NetworkQueued",1); return;
 end
 if LOTM_RESCUE_Phase10~=nil and LOTM_RESCUE_Phase10.IsCreating~=nil and LOTM_RESCUE_Phase10.IsCreating() then
  LOTM_UnitAddedPerf.MarkSection("Workshops.Entry.Phase10Create",1); return;
 end
 if m_internalCreate then LOTM_UnitAddedPerf.MarkSection("Workshops.Entry.InternalCreate",1); return; end
 if LOTM_WORLD_Monsters~=nil and LOTM_WORLD_Monsters.IsCreating~=nil and LOTM_WORLD_Monsters.IsCreating() then LOTM_UnitAddedPerf.MarkSection("Workshops.Entry.MonsterCreate",1); return; end
 local u=UnitManager.GetUnit(playerID,unitID);
 local generationDetached=fromNetworkQueue and (capturedRemoved==true or u==nil
  or (capturedUnitType~=nil and u:GetType()~=capturedUnitType));
 if generationDetached then u=nil; end
 if u==nil and not fromNetworkQueue then LOTM_UnitAddedPerf.MarkSection("Workshops.Entry.MissingUnit",1); return; end
 if IsRescueMode() and LOTM_WORLD_Barbarians~=nil and LOTM_WORLD_Barbarians.IsProtectedRescueUnit~=nil then
  if u==nil then LOTM_UnitAddedPerf.MarkSection("Workshops.Entry.MissingUnit",1); return; end
  local protected,identity=LOTM_WORLD_Barbarians.IsProtectedRescueUnit(u);
  if protected and identity~="DURABLE" then LOTM_UnitAddedPerf.MarkSection("Workshops.Entry.RescueMonster",1); return; end
  -- The network branch returned to its local-only queue above. Single-player
  -- keeps immediate handling, while recording any failed removal for the
  -- existing synchronized Phase5 turn boundary to retry.
  if LOTM_WORLD_Barbarians.ProcessRescueUnitCandidates~=nil then
   local _,removed=LOTM_WORLD_Barbarians.ProcessRescueUnitCandidates({{Owner=playerID,Unit=unitID}});
   LOTM_UnitAddedPerf.MarkSection("Workshops.Entry.RescueNormalKilled",removed or 0);
  end
  return;
 end
 local filtered=u~=nil and ((u:GetProperty("LOTM_PP_WORKSHOP_SEQUENCE") or 0)==1
  or (u:GetProperty("LOTM_PP_WORKSHOP_EXTRA") or 0)==1
  or IsDurableRescueMonster(playerID,unitID,u))
  or capturedFiltered==true;
 if filtered then LOTM_UnitAddedPerf.MarkSection("Workshops.Entry.FilteredUnit",1); return; end
 if IsRescueMode() then
  if u==nil then LOTM_UnitAddedPerf.MarkSection("Workshops.Entry.MissingUnit",1); return; end
  if IsDurableRescueMonster(playerID,unitID,u) then LOTM_UnitAddedPerf.MarkSection("Workshops.Entry.RescueMonster",1); return; end
  if RESCUE_FINAL_BATTLE_TYPES[u:GetType()]~=true then
   pcall(UnitManager.Kill,u); LOTM_UnitAddedPerf.MarkSection("Workshops.Entry.RescueNormalKilled",1);
  else LOTM_UnitAddedPerf.MarkSection("Workshops.Entry.RescueFinalBattle",1); end
  return;
 end
 local eventX=fromNetworkQueue and tonumber(x) or u:GetX();
 local eventY=fromNetworkQueue and tonumber(y) or u:GetY();
 if (eventX==nil or eventY==nil) and u~=nil then eventX=u:GetX(); eventY=u:GetY(); end
 if eventX==nil or eventY==nil then LOTM_UnitAddedPerf.MarkSection("Workshops.Entry.MissingCoordinates",1); return; end
 local lookupStarted=LOTM_UnitAddedPerf.BeginSection();
 local camp,lookupMode,candidateCount=IndexedNearestWorkshop(eventX,eventY);
 LOTM_UnitAddedPerf.EndSection("Workshops.Lookup.Total",lookupStarted,candidateCount);
 LOTM_UnitAddedPerf.MarkSection("Workshops.Lookup."..lookupMode,1);
 if camp==nil then return; end
 if LOTM_MP_TurnSync.IsNetworkGame() and ((camp:GetProperty(CAMP_REBUILD_PENDING) or 0)==1
  or m_networkImprovementRemovedPlots[camp:GetIndex()]==true) then
  LOTM_UnitAddedPerf.MarkSection("Workshops.Hit.CampGenerationDetached",1); return;
 end
 local hitStarted=LOTM_UnitAddedPerf.BeginSection();
 if eventX==camp:GetX() and eventY==camp:GetY() and (camp:GetProperty(SEQUENCE_CREATED) or 0)==1 then
  local killStarted=LOTM_UnitAddedPerf.BeginSection(); if u~=nil then UnitManager.Kill(u); end LOTM_UnitAddedPerf.EndSection("Workshops.Hit.SequenceKill",killStarted,1);
  LOTM_UnitAddedPerf.EndSection("Workshops.Hit.Total",hitStarted,1); return;
 end
 if LOTM_MP_TurnSync.IsNetworkGame() then
  local generation=QueueNetworkWorkshopUnitAddition(u,camp,queuedTurnOverride,playerID,unitID,capturedUnitType,
   capturedGeneration,generationDetached,NumberValue(camp:GetProperty(CAMP_EPOCH)) or 0);
  -- Persist the captured fact before binding its generation to a live unit.
  -- A failure or reload between the two safely degrades to detached settlement
  -- (counts/derivatives preserved, no possibly reused unit mutated).
  if u~=nil and generation~=nil and generation~="" then u:SetProperty(MP_UNIT_GENERATION_PROPERTY,generation); end
  LOTM_UnitAddedPerf.EndSection("Workshops.Hit.Total",hitStarted,1); return;
 end
 local propertyStarted=LOTM_UnitAddedPerf.BeginSection();
 u:SetProperty("LOTM_PP_WORKSHOP_SOURCE",camp:GetIndex());
 if (camp:GetProperty(LEVEL) or 2)==0 then local a=u:GetAbility(); if a~=nil then a:ChangeAbilityCount("ABILITY_LOTM_PP_WORKSHOP_LEVEL0_STRENGTH",1); end end
 local count=(camp:GetProperty(SPAWNS) or 0)+1; camp:SetProperty(SPAWNS,count);
 Game.SetProperty("LOTM_PP_WORKSHOP_NORMAL_SPAWN_TOTAL",LOTM_WORLD_State.NumberGameProperty("LOTM_PP_WORKSHOP_NORMAL_SPAWN_TOTAL",0)+1);
 LOTM_UnitAddedPerf.EndSection("Workshops.Hit.Properties",propertyStarted,1);
 Trace("normal spawn plot="..camp:GetIndex().." type="..u:GetType().." normalCount="..count.." globalNormal="..tostring(Game.GetProperty("LOTM_PP_WORKSHOP_NORMAL_SPAWN_TOTAL")));
 if (camp:GetProperty(LEVEL) or 2)<=1 and count%2==0 then
  local extraStarted=LOTM_UnitAddedPerf.BeginSection(); CreateExtra(u,camp); LOTM_UnitAddedPerf.EndSection("Workshops.Hit.CreateExtra",extraStarted,1);
 end
 if LOTM_WORLD_Monsters~=nil and LOTM_WORLD_Monsters.TrySpawnFromWorkshop~=nil then
  local monsterStarted=LOTM_UnitAddedPerf.BeginSection();
  local monsterSpawned,monsterReason=LOTM_WORLD_Monsters.TrySpawnFromWorkshop(camp,u);
  LOTM_UnitAddedPerf.EndSection("Workshops.Hit.MonsterAttempt",monsterStarted,1);
  if not LOTM_MP_TurnSync.IsNetworkGame() then
   Log("monster attempt source=UNIT_ADDED plot="..camp:GetIndex().." unit="..u:GetID()
    .." spawned="..tostring(monsterSpawned).." result="..tostring(monsterReason));
  end
 end
 LOTM_UnitAddedPerf.EndSection("Workshops.Hit.Total",hitStarted,1);
end

local function ProcessNetworkLocalUnitAdditions(playerID)
 if not LOTM_MP_TurnSync.IsNetworkGame() or not LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID) then return; end
 local currentTurn=Game.GetCurrentGameTurn(); local ready={}; local waiting={};
 for _,entry in ipairs(m_networkUnitAdditionsLocal) do
  if entry.Cancelled==true and entry.RescueCleanup~=true then
   if m_networkUnitAdditionKeys[entry.Key]==entry then m_networkUnitAdditionKeys[entry.Key]=nil; end
  elseif entry.QueuedTurn<currentTurn then ready[#ready+1]=entry;
  else waiting[#waiting+1]=entry; end
 end
 m_networkUnitAdditionsLocal=waiting;
 table.sort(ready,function(a,b)
  if a.QueuedTurn~=b.QueuedTurn then return a.QueuedTurn<b.QueuedTurn; end
  if a.PlayerID~=b.PlayerID then return a.PlayerID<b.PlayerID; end
  if a.UnitID~=b.UnitID then return a.UnitID<b.UnitID; end
  if (a.X or -1)~=(b.X or -1) then return (a.X or -1)<(b.X or -1); end
  if (a.Y or -1)~=(b.Y or -1) then return (a.Y or -1)<(b.Y or -1); end
  if (a.UnitType or -1)~=(b.UnitType or -1) then return (a.UnitType or -1)<(b.UnitType or -1); end
  if a.RemovedBeforeSettlement~=b.RemovedBeforeSettlement then return a.RemovedBeforeSettlement==true; end
  return tostring(a.CaptureToken or "")<tostring(b.CaptureToken or "");
 end);
 local rescueCandidates={}; local rescueEntries={};
 for _,entry in ipairs(ready) do
  if entry.RescueCleanup==true and IsRescueMode() then
   rescueCandidates[#rescueCandidates+1]={Owner=entry.PlayerID,Unit=entry.UnitID}; rescueEntries[#rescueEntries+1]=entry;
  else
   if m_networkUnitAdditionKeys[entry.Key]==entry then m_networkUnitAdditionKeys[entry.Key]=nil; end
   ProcessUnitAdded(entry.PlayerID,entry.UnitID,entry.X,entry.Y,true,entry.QueuedTurn,
    entry.UnitType,entry.Filtered,nil,entry.RemovedBeforeSettlement);
  end
 end
 if IsRescueMode() then
  local committed=LOTM_WORLD_Barbarians~=nil and LOTM_WORLD_Barbarians.ProcessRescueUnitCandidates~=nil
   and LOTM_WORLD_Barbarians.ProcessRescueUnitCandidates(rescueCandidates);
  for _,entry in ipairs(rescueEntries) do
   if committed then
    if m_networkUnitAdditionKeys[entry.Key]==entry then m_networkUnitAdditionKeys[entry.Key]=nil; end
   else
    m_networkUnitAdditionsLocal[#m_networkUnitAdditionsLocal+1]=entry;
   end
  end
 end
 table.sort(m_networkUnitRemovalBatchKeys);
 local retainedRemovalBatchKeys={};
 for _,key in ipairs(m_networkUnitRemovalBatchKeys) do
  local removedTurn=tonumber(m_networkUnitRemovalBatches[key]);
  if removedTurn~=nil and removedTurn<currentTurn then
   m_networkUnitRemovalBatches[key]=nil;
  elseif removedTurn~=nil then
   retainedRemovalBatchKeys[#retainedRemovalBatchKeys+1]=key;
  end
 end
 m_networkUnitRemovalBatchKeys=retainedRemovalBatchKeys;
end
local function ClearProcessedNetworkImprovementRemovalFacts()
 local stillPending={};
 for _,entry in ipairs(m_networkImprovementRemovals) do stillPending[entry.PlotIndex]=true; end
 table.sort(m_networkImprovementRemovalProcessedPlotKeys);
 for _,plotIndex in ipairs(m_networkImprovementRemovalProcessedPlotKeys) do
  if not stillPending[plotIndex] then m_networkImprovementRemovedPlots[plotIndex]=nil; end
  m_networkImprovementRemovalProcessedPlots[plotIndex]=nil;
 end
 m_networkImprovementRemovalProcessedPlotKeys={};
end
local function OnUnitAdded(playerID,unitID,x,y)
 ProcessUnitAdded(playerID,unitID,x,y,false,nil);
end
local function OnUnitMoved(playerID,unitID)
 if IsRescueMode() and playerID==BarbarianID() then
  -- OnUnitMoved runs inside the native unit operation. Deleting its actor
  -- here can strand barbarian AI turn processing. Birth publications are
  -- handled by the separate synchronized command and the turn queue.
  return;
 end
 if not IsLegalResolver(playerID) then return; end local u=UnitManager.GetUnit(playerID,unitID); if u==nil then return; end local p=Map.GetPlot(u:GetX(),u:GetY());
 if p~=nil and (p:GetImprovementType()==CAMP
  or (IsRescueMode() and (p:GetProperty(CLASSIFIED) or 0)==1 and (p:GetProperty(IS_WORKSHOP) or 0)==1
   and (p:GetProperty(SETTLED) or 0)~=1 and (p:GetProperty(MP_PENDING) or 0)~=1)) then
  p:SetProperty(CLEARER,playerID); p:SetProperty(CLEARER_UNIT,unitID);
 end
end
local function NetworkPendingIndices()
 local result={}; local seen={};
 for token in string.gmatch(tostring(Game.GetProperty(MP_PENDING_SETTLEMENTS) or ""),"[^,]+") do
  local plotIndex=tonumber(token);
  if plotIndex~=nil and plotIndex>=0 and not seen[plotIndex] then seen[plotIndex]=true; result[#result+1]=plotIndex; end
 end
 table.sort(result); return result;
end
local function SaveNetworkPendingIndices(indices)
 local values={}; for _,plotIndex in ipairs(indices) do values[#values+1]=tostring(plotIndex); end
 local serialized=table.concat(values,",");
 if tostring(Game.GetProperty(MP_PENDING_SETTLEMENTS) or "")~=serialized then
  Game.SetProperty(MP_PENDING_SETTLEMENTS,serialized);
 end
end
local function StableNetworkClearer(plot)
 local clearerValue=plot:GetProperty(CLEARER);
 if clearerValue~=nil and IsLegalResolver(tonumber(clearerValue)) then
  return tonumber(clearerValue),NumberValue(plot:GetProperty(CLEARER_UNIT));
 end
 -- Preserve the existing fallback at the shared synchronized boundary.
 -- Never snapshot these occupants in the local removal-publication callback:
 -- different publication timing must not become different reward owners.
 local candidates={};
 for _,unit in ipairs(Units.GetUnitsInPlot(plot) or {}) do
  if IsLegalResolver(unit:GetOwner()) then candidates[#candidates+1]={Owner=unit:GetOwner(),Unit=unit:GetID()}; end
 end
 table.sort(candidates,function(a,b) if a.Owner~=b.Owner then return a.Owner<b.Owner; end return a.Unit<b.Unit; end);
 if #candidates==0 then return nil,nil; end
 return candidates[1].Owner,candidates[1].Unit;
end
QueueNetworkWorkshopSettlement=function(plot,ownerID)
 if (plot:GetProperty(MP_PENDING) or 0)==1 then return; end
 local clearer,clearerUnit=StableNetworkClearer(plot);
 local queuedTurn=Game.GetCurrentGameTurn();
 plot:SetProperty(MP_PENDING,1);
 plot:SetProperty(MP_PENDING_OWNER,ownerID);
 plot:SetProperty(MP_PENDING_CLEARER,clearer);
 plot:SetProperty(MP_PENDING_CLEARER_UNIT,clearerUnit);
 plot:SetProperty(MP_PENDING_LEVEL,NumberValue(plot:GetProperty(LEVEL)) or 2);
 plot:SetProperty(MP_PENDING_PATH,plot:GetProperty(PATH) or "PP");
 plot:SetProperty(MP_PENDING_CLASSIFIED_TURN,NumberValue(plot:GetProperty(CLASSIFIED_TURN)) or Game.GetCurrentGameTurn());
 plot:SetProperty(MP_PENDING_CAMP_EPOCH,NumberValue(plot:GetProperty(CAMP_EPOCH)) or 0);
 plot:SetProperty(MP_PENDING_QUEUED_TURN,queuedTurn);
 local indices=NetworkPendingIndices(); local found=false;
 for _,plotIndex in ipairs(indices) do if plotIndex==plot:GetIndex() then found=true; break; end end
 if not found then indices[#indices+1]=plot:GetIndex(); table.sort(indices); end
 SaveNetworkPendingIndices(indices);
 Log("network settlement queued plot="..plot:GetIndex().." clearer="..tostring(clearer)
  .." queuedTurn="..queuedTurn.." earliestSettlementTurn="..(queuedTurn+1));
end

local function PendingSettlementQueuedTurn(plot,currentTurn)
 local queuedTurn=NumberValue(plot:GetProperty(MP_PENDING_QUEUED_TURN));
 if queuedTurn==nil then
  -- No released build had a pending network settlement before this field was
  -- introduced.  Treat a legacy/incomplete record as newly queued and defer
  -- it one full synchronized turn instead of racing a load-time callback.
  queuedTurn=currentTurn;
  plot:SetProperty(MP_PENDING_QUEUED_TURN,queuedTurn);
 end
 return queuedTurn;
end
local function SettleNetworkWorkshop(plot)
 local plotIndex=plot:GetIndex();
 local pendingCampEpoch=NumberValue(plot:GetProperty(MP_PENDING_CAMP_EPOCH));
 if pendingCampEpoch~=nil and pendingCampEpoch~=(NumberValue(plot:GetProperty(CAMP_EPOCH)) or 0) then
  Log("network settlement discarded stale camp generation plot="..plotIndex
   .." captured="..pendingCampEpoch.." current="..tostring(plot:GetProperty(CAMP_EPOCH)));
  plot:SetProperty(MP_PENDING,nil);
  return true;
 end
 local clearer=NumberValue(plot:GetProperty(MP_PENDING_CLEARER));
 local clearerUnit=NumberValue(plot:GetProperty(MP_PENDING_CLEARER_UNIT));
 local level=NumberValue(plot:GetProperty(MP_PENDING_LEVEL)) or 2;
 local path=plot:GetProperty(MP_PENDING_PATH) or "PP";
 local classificationTurn=NumberValue(plot:GetProperty(MP_PENDING_CLASSIFIED_TURN)) or Game.GetCurrentGameTurn();
 if (plot:GetProperty(MP_CHURCH_SETTLED) or 0)~=1 then
  local ok,details=pcall(function()
   if LOTM_WORLD_Churches~=nil and LOTM_WORLD_Churches.OnWorkshopResolved~=nil then
    LOTM_WORLD_Churches.OnWorkshopResolved(plotIndex,clearer or -1);
   end
  end);
  if not ok then Log("network church settlement error plot="..plotIndex.." error="..tostring(details)); return false; end
  plot:SetProperty(MP_CHURCH_SETTLED,1);
 end
 if IsRescueMode() and (plot:GetProperty(MP_PHASE4_SETTLED) or 0)~=1 then
  local ok,details=pcall(LOTM_RESCUE_Phase4.OnWorkshopCleared,level,clearer or -1,
   clearerUnit or -1,plotIndex,classificationTurn);
  if not ok then Log("network Phase4 settlement error plot="..plotIndex.." error="..tostring(details)); return false; end
  plot:SetProperty(MP_PHASE4_SETTLED,1);
 end
 if (plot:GetProperty(MP_REWARD_SETTLED) or 0)~=1 then
  if clearer~=nil and IsHumanMajor(clearer) and LOTM_PP_GrantWorkshopReward~=nil then
   local eventKey=tostring(plotIndex)..":"..tostring(classificationTurn);
   local ok,granted,result=pcall(LOTM_PP_GrantWorkshopReward,clearer,level,path,eventKey);
   if not ok then Log("network reward error player="..clearer.." plot="..plotIndex.." error="..tostring(granted)); return false; end
   -- Grant mutates the authoritative artifact ledger.  Commit the durable
   -- settlement flags immediately after a successful/complete result, before
   -- any localized notification work that may be unavailable in a peer's
   -- context.  This closes the reload window that could grant a second item.
   if granted==true or result=="COMPLETE" then
    plot:SetProperty(SETTLED,1);
    plot:SetProperty(MP_REWARD_SETTLED,1);
    local notifyOK,notifyError=pcall(function()
     local message=result=="COMPLETE" and Locale.Lookup("LOC_LOTM_PP_WORKSHOP_ALL_COLLECTED")
      or Locale.Lookup("LOC_LOTM_PP_WORKSHOP_REWARD",GameInfo.GreatWorks[result]
       and Locale.Lookup(GameInfo.GreatWorks[result].Name) or tostring(result));
     Game.AddWorldViewText(clearer,message,plot:GetX(),plot:GetY());
    end);
    if not notifyOK then Log("network reward notification deferred player="..clearer.." plot="..plotIndex.." error="..tostring(notifyError)); end
    Log("network cleared player="..clearer.." plot="..plotIndex.." path="..tostring(path)
     .." granted="..tostring(granted).." result="..tostring(result)
     .." settledTurn="..Game.GetCurrentGameTurn());
   else
    Log("network reward not committed player="..clearer.." plot="..plotIndex.." result="..tostring(result));
    return false;
   end
  else Log("network cleared without human reward plot="..plotIndex
    .." clearer="..tostring(clearer).." improvementOwner="..tostring(plot:GetProperty(MP_PENDING_OWNER))); end
  if clearer==nil or not IsHumanMajor(clearer) or LOTM_PP_GrantWorkshopReward==nil then
   plot:SetProperty(SETTLED,1);
   plot:SetProperty(MP_REWARD_SETTLED,1);
  end
 end
 plot:SetProperty(MP_PENDING,nil);
 return true;
end
local function ProcessNetworkWorkshopSettlements(playerID)
 local claimed,currentTurn=NetworkQueueBoundary(playerID,MP_SETTLEMENT_QUEUE_LAST_BOUNDARY);
 if not claimed then return; end
 local pending=NetworkPendingIndices();
 local index=1;
 while index<=#pending do
  local plotIndex=pending[index];
  local plot=Map.GetPlotByIndex(plotIndex);
  if plot==nil or (plot:GetProperty(MP_PENDING) or 0)~=1 then
   -- Stale index is a successful no-op; remove it immediately so a reload
   -- cannot keep retrying a destroyed/cleared camp forever.
   table.remove(pending,index); SaveNetworkPendingIndices(pending);
  elseif PendingSettlementQueuedTurn(plot,currentTurn)>=currentTurn then
   index=index+1;
  else
   local ok,result=pcall(SettleNetworkWorkshop,plot);
   if not ok then
    Log("network settlement error plot="..plotIndex.." error="..tostring(result));
    -- Preserve the failed suffix and let the dispatcher stop later writers.
    error(result);
   end
   if result~=true then
    -- Preserve this entry and every later PlotIndex until the next boundary;
    -- all entries removed before it have durable checkpoints.
    break;
   end
   table.remove(pending,index); SaveNetworkPendingIndices(pending);
   Trace("network settlement checkpoint plot="..plotIndex.." result="..tostring(result));
  end
 end
end
local function QueueNetworkImprovementRemoved(x,y,ownerID)
 local plot=Map.GetPlot(x,y); if plot==nil then return; end
 if (plot:GetProperty(CLASSIFIED) or 0)~=1 and not m_workshopSet[plot:GetIndex()] then return; end
 local queuedTurn=Game.GetCurrentGameTurn();
 local campEpoch=NumberValue(plot:GetProperty(CAMP_EPOCH)) or 0;
 local key=tostring(plot:GetIndex())..":"..tostring(campEpoch)..":"..tostring(queuedTurn);
 if m_networkImprovementRemovalKeys[key]~=nil then return; end
 local entry={X=tonumber(x),Y=tonumber(y),OwnerID=tonumber(ownerID),
  PlotIndex=plot:GetIndex(),CampEpoch=campEpoch,QueuedTurn=queuedTurn,Key=key};
 m_networkImprovementRemovals[#m_networkImprovementRemovals+1]=entry;
 m_networkImprovementRemovalKeys[key]=entry;
 m_networkImprovementRemovedPlots[plot:GetIndex()]=true;
 Log("network removal observed plot="..plot:GetIndex()
  .." observedTurn="..queuedTurn.." earliestSettlementTurn="..(queuedTurn+2));
end
local function OnRemoved(x,y,ownerID,fromNetworkQueue,capturedCampEpoch)
 if LOTM_MP_TurnSync.IsNetworkGame() and not fromNetworkQueue then
  QueueNetworkImprovementRemoved(x,y,ownerID); return;
 end
 local p=Map.GetPlot(x,y); if p==nil then return; end
 if fromNetworkQueue and tonumber(capturedCampEpoch)~=(NumberValue(p:GetProperty(CAMP_EPOCH)) or 0) then
  Trace("stale camp removal ignored plot="..p:GetIndex().." capturedEpoch="..tostring(capturedCampEpoch)
   .." currentEpoch="..tostring(p:GetProperty(CAMP_EPOCH))); return;
 end
 UnregisterWorkshopPlot(p:GetIndex());
 if (p:GetProperty(CLASSIFIED) or 0)~=1 then return; end
 p:SetProperty(CAMP_REBUILD_PENDING,1);
 if LOTM_MP_TurnSync.IsNetworkGame() and (p:GetProperty(IS_WORKSHOP) or 0)==1 then
  if (p:GetProperty(SETTLED) or 0)~=1 then QueueNetworkWorkshopSettlement(p,ownerID); end
  return;
 end
 local clearerValue=p:GetProperty(CLEARER); local clearer=clearerValue~=nil and tonumber(clearerValue) or nil; local clearerUnit=NumberValue(p:GetProperty(CLEARER_UNIT));
 if clearer==nil then for _,unit in ipairs(Units.GetUnitsInPlot(p) or {}) do if IsLegalResolver(unit:GetOwner()) then clearer=unit:GetOwner(); clearerUnit=unit:GetID(); break; end end end
 if (p:GetProperty(IS_WORKSHOP) or 0)~=1 then
  if LOTM_WORLD_Churches~=nil and LOTM_WORLD_Churches.OnBarbarianCampResolved~=nil then LOTM_WORLD_Churches.OnBarbarianCampResolved(p:GetIndex(),clearer or -1); end
  return;
 end
 if (p:GetProperty(SETTLED) or 0)==1 then return; end
 if LOTM_WORLD_Churches~=nil and LOTM_WORLD_Churches.OnWorkshopResolved~=nil then LOTM_WORLD_Churches.OnWorkshopResolved(p:GetIndex(),clearer or -1); end
 if IsRescueMode() then
  local ok,details=pcall(LOTM_RESCUE_Phase4.OnWorkshopCleared,NumberValue(p:GetProperty(LEVEL)) or 2,clearer or -1,clearerUnit or -1,p:GetIndex(),NumberValue(p:GetProperty(CLASSIFIED_TURN)) or Game.GetCurrentGameTurn());
  if not ok then Log("OnWorkshopCleared interface error="..tostring(details)); end
 end
 if clearer~=nil and IsHumanMajor(clearer) and LOTM_PP_GrantWorkshopReward~=nil then local ok,granted,result=pcall(LOTM_PP_GrantWorkshopReward,clearer,p:GetProperty(LEVEL) or 2,p:GetProperty(PATH) or "PP"); if ok then p:SetProperty(SETTLED,1); local message=result=="COMPLETE" and Locale.Lookup("LOC_LOTM_PP_WORKSHOP_ALL_COLLECTED") or Locale.Lookup("LOC_LOTM_PP_WORKSHOP_REWARD",GameInfo.GreatWorks[result] and Locale.Lookup(GameInfo.GreatWorks[result].Name) or tostring(result)); Game.AddWorldViewText(clearer,message,x,y); Log("cleared player="..clearer.." path="..tostring(p:GetProperty(PATH)).." granted="..tostring(granted).." result="..tostring(result)); else Log("reward error player="..clearer.." error="..tostring(granted)); end
 else Log("cleared without human reward owner="..tostring(ownerID)); end
end
-- Called only from an authenticated EXECUTE_SCRIPT Gameplay command. The UI
-- supplies an identity to inspect, never the claimed clearer or reward.
function LOTM_PP_Workshops.ResolveRemovedCamp(plotIndex,campEpoch)
 if not IsRescueMode() then return false; end
 local plot=Map.GetPlotByIndex(plotIndex);
 if plot==nil or plot:GetImprovementType()==CAMP
  or NumberValue(plot:GetProperty(CAMP_EPOCH))~=campEpoch
  or (plot:GetProperty(CLASSIFIED) or 0)~=1 or (plot:GetProperty(IS_WORKSHOP) or 0)~=1 then return false; end
 if (plot:GetProperty(SETTLED) or 0)==1 then return true; end
 if not LOTM_MP_TurnSync.IsNetworkGame() then OnRemoved(plot:GetX(),plot:GetY(),plot:GetOwner()); return (plot:GetProperty(SETTLED) or 0)==1; end
 OnRemoved(plot:GetX(),plot:GetY(),plot:GetOwner(),true,campEpoch);
 if (plot:GetProperty(MP_PENDING) or 0)~=1 then return false; end
 local ok,done=pcall(SettleNetworkWorkshop,plot);
 if ok and done then RemoveNetworkPendingSettlementIndex(plotIndex);
 else Log("synchronized camp command retry plot="..plotIndex.." detail="..tostring(done)); end
 return ok and done==true;
end

local function ProcessNetworkImprovementRemovals(playerID)
 if not LOTM_MP_TurnSync.IsNetworkGame()
  or not LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID) then return; end
 local currentTurn=Game.GetCurrentGameTurn(); local ready={}; local waiting={};
 for _,entry in ipairs(m_networkImprovementRemovals) do
  if entry.QueuedTurn<currentTurn then ready[#ready+1]=entry;
  else waiting[#waiting+1]=entry; end
 end
 m_networkImprovementRemovals=waiting;
 table.sort(ready,function(a,b)
  if a.QueuedTurn~=b.QueuedTurn then return a.QueuedTurn<b.QueuedTurn; end
  if a.PlotIndex~=b.PlotIndex then return a.PlotIndex<b.PlotIndex; end
  if (a.CampEpoch or 0)~=(b.CampEpoch or 0) then return (a.CampEpoch or 0)<(b.CampEpoch or 0); end
  if (a.OwnerID or -1)~=(b.OwnerID or -1) then return (a.OwnerID or -1)<(b.OwnerID or -1); end
  if (a.X or -1)~=(b.X or -1) then return (a.X or -1)<(b.X or -1); end
  return (a.Y or -1)<(b.Y or -1);
 end);
 for _,entry in ipairs(ready) do
  m_networkImprovementRemovalKeys[entry.Key]=nil;
  OnRemoved(entry.X,entry.Y,entry.OwnerID,true,entry.CampEpoch);
  if m_networkImprovementRemovalProcessedPlots[entry.PlotIndex]~=true then
   m_networkImprovementRemovalProcessedPlotKeys[#m_networkImprovementRemovalProcessedPlotKeys+1]=entry.PlotIndex;
  end
  m_networkImprovementRemovalProcessedPlots[entry.PlotIndex]=true;
 end
end
local function Dead(unit) return unit==nil or unit:IsDead() or unit:IsDelayedDeath(); end
local function SettleLostControlKill(playerID,unitID,killerPlayerID,killerUnitID,capturedLevel,capturedSerial,confirmedRemoved)
 if not IsRescueMode() then return; end
 local key=SequenceEngineKey(playerID,unitID); local serialKey=SequenceSerialEngineKey(playerID,unitID);
 local level=NumberValue(capturedLevel); local serial=NumberValue(capturedSerial);
 if level==nil then level=NumberValue(Game.GetProperty(key)); end
 if serial==nil then serial=NumberValue(Game.GetProperty(serialKey)); end
 if level==nil or (confirmedRemoved~=true and not Dead(UnitManager.GetUnit(playerID,unitID))) then return; end
 local currentUnit=UnitManager.GetUnit(playerID,unitID);
 local currentUnitSerial=currentUnit~=nil and NumberValue(currentUnit:GetProperty(RESCUE_SEQUENCE_SERIAL)) or nil;
 local identityReused=currentUnit~=nil and (serial==nil or currentUnitSerial~=serial);
 if not identityReused and LOTM_RESCUE_Phase9Digestion~=nil
  and type(LOTM_RESCUE_Phase9Digestion.RecordLostControlIdentity)=="function" then
  LOTM_RESCUE_Phase9Digestion.RecordLostControlIdentity(playerID,unitID,
   currentUnit~=nil and (currentUnit:GetCombat() or 0) or 0);
 end
 -- A later unit may already own the same engine ID. Clear the engine mapping
 -- only while it still names the sequence generation being settled.
 if not identityReused and serial~=nil and NumberValue(Game.GetProperty(serialKey))==serial then
  Game.SetProperty(key,nil); Game.SetProperty(serialKey,nil);
 end
 local ok,details=pcall(LOTM_RESCUE_Phase4.OnLostControlKilled,level,killerPlayerID or -1,killerUnitID or -1,"CENTER",serial or (tostring(playerID)..":"..tostring(unitID)));
 if not ok then Log("OnLostControlKilled interface error="..tostring(details)); end
end
local function ProcessUnitRemoved(playerID,unitID,killerPlayerID,killerUnitID,capturedLevel,capturedSerial)
 local prefix="LOTM_RESCUE_SCRIPTED_KILLER:"..playerID..":"..unitID..":";
 local expectedSerial=NumberValue(capturedSerial);
 if expectedSerial==nil then expectedSerial=NumberValue(Game.GetProperty(SequenceSerialEngineKey(playerID,unitID))); end
 local scriptedIdentityMatches=expectedSerial~=nil and expectedSerial>0
  and tostring(Game.GetProperty(prefix.."TARGET_KIND") or "")=="SEQUENCE"
  and NumberValue(Game.GetProperty(prefix.."TARGET_SERIAL"))==expectedSerial;
 local resolvedKillerPlayerID=NumberValue(killerPlayerID);
 local resolvedKillerUnitID=NumberValue(killerUnitID);
 if resolvedKillerPlayerID==nil and scriptedIdentityMatches then resolvedKillerPlayerID=NumberValue(Game.GetProperty(prefix.."PLAYER")); end
 if resolvedKillerUnitID==nil and scriptedIdentityMatches then resolvedKillerUnitID=NumberValue(Game.GetProperty(prefix.."UNIT")); end
 if resolvedKillerPlayerID==nil then return; end
 if scriptedIdentityMatches then
  local storedKiller=NumberValue(Game.GetProperty(prefix.."PLAYER"));
  local storedKillerUnit=NumberValue(Game.GetProperty(prefix.."UNIT"));
  if storedKiller==resolvedKillerPlayerID and (storedKillerUnit or -1)==(resolvedKillerUnitID or -1) then
   Game.SetProperty(prefix.."PLAYER",nil); Game.SetProperty(prefix.."UNIT",nil);
   Game.SetProperty(prefix.."TARGET_KIND",nil); Game.SetProperty(prefix.."TARGET_SERIAL",nil);
  end
 end
 SettleLostControlKill(playerID,unitID,resolvedKillerPlayerID,resolvedKillerUnitID or -1,
  capturedLevel,expectedSerial,true);
end
local function QueueNetworkUnitRemoved(playerID,unitID)
 local normalizedPlayerID=tonumber(playerID); local normalizedUnitID=tonumber(unitID);
 if normalizedPlayerID==nil or normalizedUnitID==nil then return; end
 local prefix="LOTM_RESCUE_SCRIPTED_KILLER:"..normalizedPlayerID..":"..normalizedUnitID..":";
 local sequenceSerial=NumberValue(Game.GetProperty(SequenceSerialEngineKey(normalizedPlayerID,normalizedUnitID)));
 if sequenceSerial==nil or sequenceSerial<=0
  or tostring(Game.GetProperty(prefix.."TARGET_KIND") or "")~="SEQUENCE"
  or NumberValue(Game.GetProperty(prefix.."TARGET_SERIAL"))~=sequenceSerial then return; end
 local killerPlayerID=NumberValue(Game.GetProperty(prefix.."PLAYER"));
 if killerPlayerID==nil then return; end
 local queuedTurn=Game.GetCurrentGameTurn();
 local key=tostring(normalizedPlayerID)..":"..tostring(normalizedUnitID)..":"..tostring(queuedTurn);
 if m_networkUnitRemovalKeys[key]~=nil then return; end
 local entry={PlayerID=normalizedPlayerID,UnitID=normalizedUnitID,
  KillerPlayerID=killerPlayerID,KillerUnitID=NumberValue(Game.GetProperty(prefix.."UNIT")),
  Level=NumberValue(Game.GetProperty(SequenceEngineKey(normalizedPlayerID,normalizedUnitID))),
  Serial=sequenceSerial,
  QueuedTurn=queuedTurn,Key=key};
 m_networkUnitRemovals[#m_networkUnitRemovals+1]=entry;
 m_networkUnitRemovalKeys[key]=entry;
end
local function OnUnitRemoved(playerID,unitID)
 if LOTM_MP_TurnSync.IsNetworkGame() then
  local normalizedPlayerID=tonumber(playerID); local normalizedUnitID=tonumber(unitID);
  if normalizedPlayerID~=nil and normalizedUnitID~=nil then
    local removedTurn=Game.GetCurrentGameTurn();
    local batchKey=LocalNetworkUnitBatchKey(normalizedPlayerID,normalizedUnitID,removedTurn);
    if m_networkUnitRemovalBatches[batchKey]==nil then
     m_networkUnitRemovalBatchKeys[#m_networkUnitRemovalBatchKeys+1]=batchKey;
    end
    m_networkUnitRemovalBatches[batchKey]=removedTurn;
   for _,pending in ipairs(m_networkUnitAdditionsLocal) do
    if pending.PlayerID==normalizedPlayerID and pending.UnitID==normalizedUnitID then
     if pending.QueuedTurn==removedTurn then
      pending.Cancelled=true;
     else
      pending.RemovedBeforeSettlement=true;
     end
    end
   end
  end
  QueueNetworkUnitRemoved(playerID,unitID); return;
 end
 ProcessUnitRemoved(playerID,unitID,nil,nil,nil,nil);
end
local function ProcessNetworkUnitRemovals(playerID)
 if not LOTM_MP_TurnSync.IsNetworkGame()
  or not LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID) then return; end
 local currentTurn=Game.GetCurrentGameTurn(); local ready={}; local waiting={};
 for _,entry in ipairs(m_networkUnitRemovals) do
  if entry.QueuedTurn<currentTurn then ready[#ready+1]=entry;
  else waiting[#waiting+1]=entry; end
 end
 m_networkUnitRemovals=waiting;
 table.sort(ready,function(a,b)
  if a.QueuedTurn~=b.QueuedTurn then return a.QueuedTurn<b.QueuedTurn; end
  if a.PlayerID~=b.PlayerID then return a.PlayerID<b.PlayerID; end
  if a.UnitID~=b.UnitID then return a.UnitID<b.UnitID; end
  if (a.KillerPlayerID or -1)~=(b.KillerPlayerID or -1) then return (a.KillerPlayerID or -1)<(b.KillerPlayerID or -1); end
  return (a.KillerUnitID or -1)<(b.KillerUnitID or -1);
 end);
 for _,entry in ipairs(ready) do
  m_networkUnitRemovalKeys[entry.Key]=nil;
  ProcessUnitRemoved(entry.PlayerID,entry.UnitID,entry.KillerPlayerID,entry.KillerUnitID,entry.Level,entry.Serial);
 end
end
local function OnCombat(attackerPlayerID,attackerUnitID,defenderPlayerID,defenderUnitID)
 SettleLostControlKill(attackerPlayerID,attackerUnitID,defenderPlayerID,defenderUnitID);
 SettleLostControlKill(defenderPlayerID,defenderUnitID,attackerPlayerID,attackerUnitID);
end

-- Barbarian tribe creation publishes its initial UnitAddedToMap callbacks
-- before ImprovementAddedToMap on some single-player runs.  The new camp is
-- therefore not classified yet and those units cannot find their workshop.
-- Reconcile only the bounded radius used by the existing lookup, only for the
-- freshly classified camp, and only for units that still have no source.
function LOTM_PP_Workshops.ReconcileSinglePlayerWorkshopBirthUnits(camp)
 if camp==nil or IsRescueMode() or LOTM_MP_TurnSync.IsNetworkGame() then return; end
 local barb=BarbarianID(); if barb<0 then return; end
 local candidates={}; local seenPlots={}; local seenUnits={};
 for radius=0,3 do
  for dx=-radius,radius do for dy=-radius,radius do
   local plot=Map.GetPlotXYWithRangeCheck(camp:GetX(),camp:GetY(),dx,dy,radius);
   local plotIndex=plot~=nil and plot:GetIndex() or -1;
   if plot~=nil and not seenPlots[plotIndex] then
    seenPlots[plotIndex]=true;
    for _,unit in ipairs(Units.GetUnitsInPlot(plot) or {}) do
     local source=unit:GetProperty("LOTM_PP_WORKSHOP_SOURCE");
     local key=tostring(unit:GetOwner())..":"..tostring(unit:GetID());
     if unit:GetOwner()==barb and source==nil and not seenUnits[key]
      and (unit:GetProperty("LOTM_PP_WORKSHOP_SEQUENCE") or 0)~=1
      and (unit:GetProperty("LOTM_PP_WORKSHOP_EXTRA") or 0)~=1
      and not (LOTM_WORLD_Monsters~=nil and LOTM_WORLD_Monsters.IsMonster~=nil
       and LOTM_WORLD_Monsters.IsMonster(unit)) then
      seenUnits[key]=true; candidates[#candidates+1]=unit;
     end
    end
   end
  end end
 end
 table.sort(candidates,function(a,b) return a:GetID()<b:GetID(); end);
 local repaired=0;
 for _,unit in ipairs(candidates) do
  local ownerID=unit:GetOwner(); local unitID=unit:GetID();
  ProcessUnitAdded(ownerID,unitID,unit:GetX(),unit:GetY(),false,nil);
  local live=UnitManager.GetUnit(ownerID,unitID);
  local source=live~=nil and live:GetProperty("LOTM_PP_WORKSHOP_SOURCE") or nil;
  if tonumber(source)==camp:GetIndex() then repaired=repaired+1; end
 end
 Log("single-player birth units reconciled plot="..camp:GetIndex()
  .." candidates="..#candidates.." repaired="..repaired);
end

local function OnTurn(playerID,isFirstTimeThisTurn)
 if isFirstTimeThisTurn==false then return; end
 if LOTM_MP_TurnSync.IsNetworkGame() then
  -- Queue consumption is anchored to exactly one synchronized major-player
  -- boundary.  Single-player continues directly to its legacy barbarian
  -- turn path below; no queue state is consulted there.
  ProcessNetworkImprovementRemovals(playerID);
  ProcessNetworkUnitRemovals(playerID);
   ProcessNetworkImprovementAdditions(playerID);
   ProcessNetworkLocalUnitAdditions(playerID);
   ClearProcessedNetworkImprovementRemovalFacts();
  ProcessNetworkWorkshopUnitAdditions(playerID);
  ProcessNetworkWorkshopSettlements(playerID);
 end
 if playerID==BarbarianID() then
  local turnStarted=LOTM_UnitAddedPerf.BeginSection();
  EnsurePhase4State();
  local plotStarted=LOTM_UnitAddedPerf.BeginSection(); local campCount=0; local stale={};
  for _,plotIndex in ipairs(m_workshopPlots) do
   local p=Map.GetPlotByIndex(plotIndex);
   if IsWorkshopPlot(p) then campCount=campCount+1; Classify(p); else stale[#stale+1]=plotIndex; end
  end
  for _,plotIndex in ipairs(stale) do UnregisterWorkshopPlot(plotIndex); end
  LOTM_UnitAddedPerf.EndSection("Workshops.TurnPlots",plotStarted,campCount);
  local unitsStarted=LOTM_UnitAddedPerf.BeginSection(); local unitCount=0;
  local barb=Players[playerID]; if barb~=nil then
   local units={}; for _,u in barb:GetUnits():Members() do units[#units+1]=u; end
   if LOTM_MP_TurnSync.IsNetworkGame() then table.sort(units,function(a,b) return a:GetID()<b:GetID(); end); end
   for _,u in ipairs(units) do
    unitCount=unitCount+1;
    if (u:GetProperty("LOTM_PP_WORKSHOP_SEQUENCE") or 0)==1 then
     EnsureSequenceStrength(u,nil);
     local source=Map.GetPlotByIndex(u:GetProperty("LOTM_PP_WORKSHOP_PLOT") or -1);
     if source~=nil and (u:GetX()~=source:GetX() or u:GetY()~=source:GetY()) then
      if UnitManager.PlaceUnit~=nil then UnitManager.PlaceUnit(u,source:GetX(),source:GetY()); Trace("sequence movement corrected plot="..source:GetIndex()); end
     end
     UnitManager.FinishMoves(u)
   elseif u:GetProperty("LOTM_PP_WORKSHOP_SOURCE")~=nil then local camp=Map.GetPlotByIndex(u:GetProperty("LOTM_PP_WORKSHOP_SOURCE")); if camp~=nil and (camp:GetProperty(LEVEL) or 2)==0 and u:GetDamage()>0 then u:ChangeDamage(-math.min(10,u:GetDamage())); end end
   end
  end
  LOTM_UnitAddedPerf.EndSection("Workshops.TurnUnits",unitsStarted,unitCount);
  LOTM_UnitAddedPerf.EndSection("Workshops.TurnTotal",turnStarted,campCount+unitCount);
  if LOTM_UnitAddedPerf.SectionEnabled then LOTM_UnitAddedPerf.ReportSections("firstBarbarianTurn"); LOTM_UnitAddedPerf.SectionEnabled=false; end
 end
end
local function Initialize()
 local initializeStarted=LOTM_UnitAddedPerf.BeginSection();
 if LOTM_MP_TurnSync.IsNetworkGame() then
  Events.ImprovementAddedToMap.Add(QueueNetworkImprovementAdded);
 else
  -- Preserve the original immediate single-player path exactly.
  Events.ImprovementAddedToMap.Add(ClassifySinglePlayerImprovementAdded);
 end
 Events.ImprovementRemovedFromMap.Add(OnRemoved); Events.UnitAddedToMap.Add(LOTM_UnitAddedPerf.Wrap("Workshops",OnUnitAdded)); Events.UnitRemovedFromMap.Add(OnUnitRemoved); GameEvents.OnUnitMoved.Add(OnUnitMoved); GameEvents.OnCombatOccurred.Add(OnCombat); LOTM_MP_TurnSync.Add(OnTurn,"Workshops");
 LOTM_MP_TurnSync.RunStartup(function()
  local scanStarted=LOTM_UnitAddedPerf.BeginSection(); local campCount=InitializeWorkshopRegistry();
  LOTM_UnitAddedPerf.EndSection("Workshops.InitializePlots",scanStarted,campCount);
  LOTM_UnitAddedPerf.EndSection("Workshops.InitializeTotal",initializeStarted,campCount);
  Log("initialized registryVersion="..WORKSHOP_REGISTRY_VERSION.." workshops="..#m_workshopPlots.." fullScan=migrationOnly unitLookup=coverageIndex classification=stable-v"..CLASSIFICATION_VERSION);
 end,"Workshops");
end
Initialize();
