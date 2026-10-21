-- Rescue Mode Phase 10: fixed descent, true gods, Divine Legion, purification
-- tiers, Outer God phases/minions, and rescue victory.
include("LOTM_Effects");
include("LOTM_RESCUE_SyncActions");
LOTM_RESCUE_Phase10=LOTM_RESCUE_Phase10 or {};

local VERSION=40;
local ALLIED_ACTION_VERSION=4;
local VISIBILITY_VERSION=2;
local BOSS_POSITION_VERSION=5;
local GOD_PROPERTY="LOTM_RESCUE_PHASE10_IS_GOD";
local CONFIRMED_DAMAGE_PROPERTY="LOTM_RESCUE_PHASE10_LAST_CONFIRMED_DAMAGE";
local LEGACY_PLUS_ABILITY="ABILITY_LOTM_RESCUE_P10_STRENGTH_PLUS";
local MINUS_ABILITY="ABILITY_LOTM_RESCUE_P10_STRENGTH_MINUS";
local DIVINE_LEGION_ABILITY="ABILITY_LOTM_RESCUE_DIVINE_LEGION";
local PLAYER_GOD_MOBILITY_ABILITY="ABILITY_LOTM_RESCUE_PLAYER_GOD_MOBILITY_30";
local PLAYER_GOD_BASE_STRENGTH=550;
local PLAYER_GOD_MOBILITY_THRESHOLD=1000;
local PLAYER_GOD_MOBILITY_BONUS=30;
local STRENGTH_BITS={1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192};
local ATTACK_BITS={1,2,4};
local BOSS_TYPE="UNIT_LOTM_RESCUE_OUTER_GOD_AVATAR";
local MINION_TYPE="UNIT_LOTM_RESCUE_OUTER_GOD_MINION";
local PATH_GODS={
 PATH_RED_PRIEST="UNIT_LOTM_RESCUE_GOD_RED_PRIEST",
 PATH_PERFECT="UNIT_LOTM_RESCUE_GOD_PERFECT",
 PATH_BLACK_EMPEROR="UNIT_LOTM_RESCUE_GOD_BLACK_EMPEROR",
 PATH_THIEF="UNIT_LOTM_RESCUE_GOD_THIEF"
};
local PERFECT_MODEL_PATHS={PATH_RED_PRIEST=true,PATH_BLACK_EMPEROR=true};
local PERFECT_MODEL_TYPE="UNIT_LOTM_RESCUE_GOD_PERFECT";
local CHURCH_GODS={
 {Role="FOOL",Type="UNIT_LOTM_RESCUE_GOD_FOOL"},
 {Role="NIGHT",Type="UNIT_LOTM_RESCUE_GOD_NIGHT"},
 {Role="STORM",Type="UNIT_LOTM_RESCUE_GOD_STORM"}
};
local m_spawnReserved={};
local m_roleUnits={};
local m_phase10Creating=false;
local m_bossIntentionalDefeat={};
local m_nativeDamageEvents={};
local m_bossCombatEvents={};
local m_nativeDamageCorrections={};
local m_pendingNetworkRemovals={};
local m_pendingNetworkRemovalKeys={};
local ResolveBossDefeat;

function LOTM_RESCUE_Phase10.IsCreating()
 return m_phase10Creating;
end

-- First public balance candidate. All values are centralized for the complete
-- post-Phase-10 test and can be tuned without changing the state machine.
local TIERS={
  {Min=0,   Max=499, Strength=999,Phases=2,Heal=20,Summon=3,Cap=10,Skills=5},
  {Min=500, Max=999, Strength=888,Phases=2,Heal=15,Summon=4,Cap=8, Skills=4},
  {Min=1000,Max=1499,Strength=777,Phases=2,Heal=12,Summon=5,Cap=6, Skills=3},
  {Min=1500,Max=1999,Strength=666,Phases=2,Heal=8, Summon=6,Cap=4, Skills=2},
 {Min=2000,Max=2999,Strength=555,Phases=2,Heal=5,Summon=8,Cap=2,Skills=1},
 {Min=3000,Max=2147483647,Strength=444,Phases=2,Heal=5,Summon=8,Cap=2,Skills=1}
};
local BEST_TIER_THRESHOLD=TIERS[#TIERS].Min;
local PURIFICATION_DISPLAY_MAX=3000;
local BATTLEFIELD_REVEAL_RADIUS=6;
local BOSS_SIGHT_RADIUS=6;
local BOSS_SIGHT_VERSION=2;
local CHURCH_GOD_RESPAWN_DELAY=5;
local CHURCH_GOD_RESPAWN_VERSION=2;
local PLAYER_GOD_RESPAWN_DELAY=5;
local BOSS_LIVES=2;
local EXHAUSTED_BOSS_RECOVERY_VERSION=1;
local BOSS_DEATH_RECOVERY_VERSION=1;
local VICTORY_PRESENTATION_VERSION=1;

local function Log(message) print("[LOTM_RESCUE][Phase10] "..tostring(message)); end
local function Number(value,default) if value==nil then return default; end return tonumber(value) or default; end
local function Active() return Number(Game.GetProperty("LOTM_RESCUE_MODE"),0)==1; end
local function IsNetworkMultiplayer()
 return GameConfiguration~=nil and GameConfiguration.IsAnyMultiplayer~=nil and GameConfiguration.IsAnyMultiplayer() or false;
end
local function PublishNetworkConfirmedDamage(unit)
 if not IsNetworkMultiplayer() or unit==nil or unit:IsDead() or unit:IsDelayedDeath() then return -1; end
 local current=Number(unit:GetDamage(),0);
 if Number(unit:GetProperty(CONFIRMED_DAMAGE_PROPERTY),-1)~=current then unit:SetProperty(CONFIRMED_DAMAGE_PROPERTY,current); end
 return current;
end
local function WorldTurn() return LOTM_RESCUE_Phase5.WorldTurn(); end
-- Persisted birth turn covers initial descent and the single allowed respawn.
-- Read-only predicate; damage/kill callers retain their synchronized ownership.
function LOTM_RESCUE_Phase10.IsDescentProtected(unit)
 if not Active() or unit==nil or Number(unit:GetProperty(GOD_PROPERTY),0)~=1 then return false; end
 local role=tostring(unit:GetProperty("LOTM_RESCUE_PHASE10_ROLE") or "");
 local friendly=role=="FOOL" or role=="NIGHT" or role=="STORM" or string.match(role,"^PLAYER_GOD_%d+$")~=nil;
 return friendly and Number(unit:GetProperty("LOTM_RESCUE_PHASE10_SPAWN_TURN"),-1)==WorldTurn();
end
local function ProtectDescent(unit,source)
 if not LOTM_RESCUE_Phase10.IsDescentProtected(unit) then return false; end
 Log("descent protection role="..tostring(unit:GetProperty("LOTM_RESCUE_PHASE10_ROLE")).." unit="..unit:GetOwner()..":"..unit:GetID().." turn="..WorldTurn().." source="..source);
 return true;
end

local function FinalTurn() return LOTM_RESCUE_Phase5.FinalTurn(); end
local function RoleKey(role,suffix) return "LOTM_RESCUE_PHASE10_"..role.."_"..suffix; end
local function EngineKey(playerID,unitID) return "LOTM_RESCUE_PHASE10_ENGINE:"..tostring(playerID)..":"..tostring(unitID); end
local function BossEpoch()
 return Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_EPOCH"),0);
end
local function IndependentOwnerID()
 local owner=Number(Game.GetProperty("LOTM_RESCUE_TEST_PLAYER_ID"),-1);
 return owner>=0 and Players[owner]~=nil and Players[owner]:IsAlive() and owner or -1;
end

local function HumanPlayers()
 local result={};
 for _,player in ipairs(PlayerManager.GetAliveMajors()) do if player:IsHuman() then table.insert(result,player); end end
 table.sort(result,function(a,b) return a:GetID()<b:GetID(); end); return result;
end

local function CenterPlot()
 local index=Number(Game.GetProperty("LOTM_RESCUE_CENTER_CITY_PLOT"),Number(Game.GetProperty("LOTM_RESCUE_CENTER_PLOT"),-1));
 return index>=0 and Map.GetPlotByIndex(index) or nil;
end

local function CandidatePlots(maxRange,minRange)
 local center=CenterPlot(); if center==nil then return {}; end
 local rows={}; minRange=math.max(1,Number(minRange,1));
 for dx=-maxRange,maxRange do for dy=-maxRange,maxRange do
  local plot=Map.GetPlotXYWithRangeCheck(center:GetX(),center:GetY(),dx,dy,maxRange);
  local distance=plot~=nil and Map.GetPlotDistance(center:GetX(),center:GetY(),plot:GetX(),plot:GetY()) or -1;
  if plot~=nil and plot:GetIndex()~=center:GetIndex() and not plot:IsWater() and not plot:IsImpassable()
   and distance>=minRange and not plot:IsCity() and plot:GetDistrictType()<0 and plot:GetUnitCount()==0 and not m_spawnReserved[plot:GetIndex()] then
   table.insert(rows,{Plot=plot,Distance=distance});
  end
 end end
 table.sort(rows,function(a,b) if a.Distance~=b.Distance then return a.Distance<b.Distance; end return a.Plot:GetIndex()<b.Plot:GetIndex(); end);
 return rows;
end

local function SetAbilityCount(unit,abilityType,desired)
 local abilities=unit~=nil and unit:GetAbility() or nil; if abilities==nil or GameInfo.UnitAbilities[abilityType]==nil then return false; end
 LOTM_Effects.SetAbilityCount(abilities,abilityType,desired);
 return (abilities:GetAbilityCount(abilityType) or 0)==desired;
end

local function BitAbility(prefix,value) return prefix..tostring(value); end

local function ApplyBits(unit,prefix,bits,value)
 value=math.max(0,math.floor(Number(value,0))); local applied=0;
 for _,bit in ipairs(bits) do
  local enabled=math.floor(value/bit)%2==1 and 1 or 0;
  if SetAbilityCount(unit,BitAbility(prefix,bit),enabled) then applied=applied+enabled*bit; end
 end
 return applied;
end

local function ExactStrength(unit,target)
 if unit==nil then return false; end
 local abilities=unit:GetAbility(); if abilities==nil then return false; end
 -- Ability modifiers apply once regardless of Ability count. Resource 191's
 -- +1 ability stacked N times therefore remained +1. Fixed binary abilities
 -- make every target exact while changing only fourteen 0/1 counters.
 SetAbilityCount(unit,LEGACY_PLUS_ABILITY,0); SetAbilityCount(unit,MINUS_ABILITY,0);
 local info=GameInfo.Units[unit:GetType()]; local baseline=info~=nil and Number(info.Combat,0) or Number(unit:GetCombat(),0);
 local targetValue=math.max(1,math.floor(Number(target,baseline))); local delta=math.max(0,targetValue-baseline);
 local applied=ApplyBits(unit,"ABILITY_LOTM_RESCUE_P10_STRENGTH_",STRENGTH_BITS,delta);
 unit:SetProperty("LOTM_RESCUE_PHASE10_TARGET_STRENGTH",target);
 unit:SetProperty("LOTM_RESCUE_PHASE10_BASELINE_STRENGTH",baseline);
 unit:SetProperty("LOTM_RESCUE_PHASE10_APPLIED_STRENGTH",baseline+applied);
 return baseline+applied==targetValue;
end

local function PlacedUnit(unit,expectedOwner,expectedUnitID)
 if unit==nil then return nil,nil,"NIL_UNIT"; end
 local ok,dead,delayed,owner,unitID,x,y=pcall(function()
  return unit:IsDead(),unit:IsDelayedDeath(),unit:GetOwner(),unit:GetID(),unit:GetX(),unit:GetY();
 end);
 if not ok then return nil,nil,"UNIT_API"; end
 if dead or delayed then return nil,nil,"DEAD_OR_DELAYED"; end
 if owner~=expectedOwner or unitID~=expectedUnitID then return nil,nil,"IDENTITY_MISMATCH"; end
 local direct=UnitManager.GetUnit(expectedOwner,expectedUnitID);
 if direct==nil then return nil,nil,"NOT_IN_OWNER_INDEX"; end
 local plot=Map.GetPlot(x,y);
 if plot==nil then return nil,nil,"NOT_ON_MAP"; end
 local present=false;
 for _,candidate in ipairs(Units.GetUnitsInPlot(plot) or {}) do
  if candidate:GetOwner()==expectedOwner and candidate:GetID()==expectedUnitID then present=true; break; end
 end
 if not present then return nil,nil,"NOT_IN_PLOT_INDEX"; end
 return direct,plot,"OK";
end

local function PlacementAllowed(plot,minRange,maxRange,attemptDistance)
 local center=CenterPlot(); if plot==nil or center==nil then return false,-1,"PLOT_OR_CENTER_MISSING"; end
 local distance=Map.GetPlotDistance(center:GetX(),center:GetY(),plot:GetX(),plot:GetY());
 if plot:GetIndex()==center:GetIndex() then return false,distance,"CENTER_PLOT"; end
 if plot:IsWater() or plot:IsImpassable() or plot:IsCity() or plot:GetDistrictType()>=0 then return false,distance,"ILLEGAL_TERRAIN"; end
 if distance<minRange or distance>maxRange then return false,distance,"OUT_OF_RANGE"; end
 if distance>attemptDistance then return false,distance,"OUTSIDE_ATTEMPT_RING"; end
 if m_spawnReserved[plot:GetIndex()] then return false,distance,"RESERVED"; end
 return true,distance,"OK";
end

local function Spawn(playerID,unitType,role,maxRange,minRange)
 local info=GameInfo.Units[unitType]; if info==nil then Log("spawn failed role="..role.." reason=TYPE_MISSING"); return nil; end
 maxRange=math.max(1,Number(maxRange,4)); minRange=math.max(1,Number(minRange,1));
 local candidates=CandidatePlots(maxRange,minRange); if #candidates==0 then Log("spawn delayed role="..role.." reason=NO_PLOT"); return nil; end
 local initFailures=0; local rejected=0;
 for attempt,entry in ipairs(candidates) do
  local requested=entry.Plot;
  m_phase10Creating=true;
  local ok,unit=pcall(UnitManager.InitUnit,playerID,info.Index,requested:GetX(),requested:GetY());
  m_phase10Creating=false;
  if not ok or unit==nil then
   initFailures=initFailures+1;
   Log("spawn attempt failed role="..role.." attempt="..attempt.."/"..#candidates.." reason=INIT_FAILED requestedPlot="..requested:GetIndex().." requestedDistance="..entry.Distance);
  else
   local unitID=-1; local idOK,idValue=pcall(function() return unit:GetID(); end); if idOK then unitID=Number(idValue,-1); end
   local placed,actualPlot,reason=PlacedUnit(unit,playerID,unitID);
   if (placed==nil or actualPlot:GetIndex()~=requested:GetIndex()) and UnitManager.PlaceUnit~=nil then
    pcall(UnitManager.PlaceUnit,unit,requested:GetX(),requested:GetY());
    placed,actualPlot,reason=PlacedUnit(unit,playerID,unitID);
   end
   local accepted=false; local actualDistance=-1; local placementReason=reason;
   if placed~=nil then accepted,actualDistance,placementReason=PlacementAllowed(actualPlot,minRange,maxRange,entry.Distance); end
   if accepted then
    unit=placed;
    m_spawnReserved[actualPlot:GetIndex()]=true;
    unit:SetProperty(GOD_PROPERTY,role~="MINION" and 1 or 0);
    unit:SetProperty("LOTM_RESCUE_PHASE10_ROLE",role);
    unit:SetProperty("LOTM_RESCUE_PHASE10_SPAWN_TURN",WorldTurn());
    if role~="MINION" then PublishNetworkConfirmedDamage(unit); end
    Game.SetProperty(EngineKey(playerID,unit:GetID()),role);
    Game.SetProperty(RoleKey(role,"OWNER"),playerID); Game.SetProperty(RoleKey(role,"UNIT"),unit:GetID());
    m_roleUnits[role]=unit;
    local experience=unit:GetExperience(); if experience~=nil then experience:SetExperienceLocked(true); end
    Log("spawn committed role="..role.." type="..unitType.." owner="..playerID.." unit="..unit:GetID().." attempt="..attempt.."/"..#candidates.." requestedPlot="..requested:GetIndex().." plot="..actualPlot:GetIndex().." centerDistance="..actualDistance);
    return unit;
   end
   rejected=rejected+1;
   local actual=actualPlot~=nil and actualPlot:GetIndex() or -1;
   Log("spawn rejected role="..role.." attempt="..attempt.."/"..#candidates.." reason="..tostring(placementReason).." owner="..playerID.." unit="..unitID.." requestedPlot="..requested:GetIndex().." requestedDistance="..entry.Distance.." actualPlot="..actual.." actualDistance="..actualDistance);
   if unitID>=0 then Game.SetProperty(EngineKey(playerID,unitID),nil); end
   pcall(UnitManager.Kill,unit);
  end
 end
 Log("spawn delayed role="..role.." reason=ALL_CANDIDATES_REJECTED candidates="..#candidates.." initFailures="..initFailures.." rejected="..rejected.." range="..minRange.."-"..maxRange);
 return nil;
end

local function FindRole(role)
 local cached=m_roleUnits[role];
 if cached~=nil then
  local owner=Number(Game.GetProperty(RoleKey(role,"OWNER")),-1); local unitID=Number(Game.GetProperty(RoleKey(role,"UNIT")),-1);
  local placed=PlacedUnit(cached,owner,unitID);
  if placed~=nil then return placed; end
  m_roleUnits[role]=nil;
 end
 local owner=Number(Game.GetProperty(RoleKey(role,"OWNER")),-1); local unitID=Number(Game.GetProperty(RoleKey(role,"UNIT")),-1);
 if owner<0 or unitID<0 then return nil; end
 if UnitManager~=nil and UnitManager.GetUnit~=nil then
  local ok,direct=pcall(UnitManager.GetUnit,owner,unitID); if ok and direct~=nil then
   local placed=PlacedUnit(direct,owner,unitID); if placed~=nil then m_roleUnits[role]=placed; return placed; end
  end
 end
 local player=Players[owner]; local found=player~=nil and player:GetUnits():FindID(unitID) or nil;
 if found~=nil then local placed=PlacedUnit(found,owner,unitID); if placed~=nil then m_roleUnits[role]=placed; return placed; end end
  Game.SetProperty(EngineKey(owner,unitID),nil);
  Log("role lookup unavailable role="..role.." owner="..owner.." unit="..unitID.." reason=NOT_PLACED_METADATA_PRESERVED");
 return nil;
end

local function TierFor(purification)
 for index,tier in ipairs(TIERS) do if purification>=tier.Min and purification<=tier.Max then return index,tier; end end
 return #TIERS,TIERS[#TIERS];
end

local function PublishTier(purification)
 purification=Number(purification,Number(Game.GetProperty("GLOBAL_PURIFICATION"),0)); local index,tier=TierFor(purification);
 Game.SetProperty("LOTM_RESCUE_PHASE10_PURIFICATION_LOCKED",purification);
 Game.SetProperty("LOTM_RESCUE_PHASE10_PURIFICATION_TIER",index);
 Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_STRENGTH",tier.Strength);
 Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_MAX_HEALTH",tier.Phases*100);
 Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_HEAL",tier.Heal);
 Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_SUMMON_INTERVAL",tier.Summon);
 Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_SKILLS",tier.Skills);
 return index,tier,purification;
end

local function ChurchGodMeta(role)
 for _,meta in ipairs(CHURCH_GODS) do if meta.Role==role then return meta; end end
 return nil;
end

local function BossSpawnCount()
 local stored=Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_SPAWN_COUNT");
 if stored~=nil then return math.max(0,Number(stored,0)); end
 local generated=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_GENERATED"),0)==1;
 local remaining=math.max(0,Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_PHASES_REMAINING"),BOSS_LIVES));
 local count=generated and math.min(BOSS_LIVES,math.max(1,BOSS_LIVES-math.min(BOSS_LIVES,remaining)+1)) or 0;
 Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_SPAWN_COUNT",count);
 Log("boss lives migrated spawned="..count.." remaining="..remaining.." max="..BOSS_LIVES);
 return count;
end

local function ScheduleChurchGodRespawn(role)
 if ChurchGodMeta(role)==nil then return false; end
 local used=Number(Game.GetProperty(RoleKey(role,"RESPAWN_USED")),0);
 if used>=1 then
  Game.SetProperty(RoleKey(role,"STATE"),"DEAD"); Game.SetProperty(RoleKey(role,"RESPAWN_TURN"),nil);
  Log("church god permanently destroyed role="..role.." turn="..WorldTurn()); return false;
 end
 local due=WorldTurn()+CHURCH_GOD_RESPAWN_DELAY;
 Game.SetProperty(RoleKey(role,"STATE"),"RESPAWN_PENDING"); Game.SetProperty(RoleKey(role,"RESPAWN_TURN"),due);
 Log("church god respawn scheduled role="..role.." deathTurn="..WorldTurn().." respawnTurn="..due.." remaining=1"); return true;
end

local function MigrateChurchGodRespawns()
 local previous=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_CHURCH_RESPAWN_VERSION"),0);
 if previous>=CHURCH_GOD_RESPAWN_VERSION then return; end
 if previous==1 and Number(Game.GetProperty("LOTM_RESCUE_PHASE10_DESCENT_TRIGGERED"),0)==1 then
  Game.SetProperty(RoleKey("FOOL","RESPAWN_USED"),1);
  Log("church god respawn migration role=FOOL remaining=0 reason=LEGACY_REPEATED_RESPAWN_EVIDENCE");
 end
 for _,meta in ipairs(CHURCH_GODS) do
  if FindRole(meta.Role)==nil and Game.GetProperty(RoleKey(meta.Role,"STATE"))=="DEAD" and Number(Game.GetProperty(RoleKey(meta.Role,"RESPAWN_USED")),0)==0 then ScheduleChurchGodRespawn(meta.Role); end
 end
 Game.SetProperty("LOTM_RESCUE_PHASE10_CHURCH_RESPAWN_VERSION",CHURCH_GOD_RESPAWN_VERSION);
end

local function SpawnBoss()
 if Number(Game.GetProperty("LOTM_RESCUE_PHASE10_VICTORY"),0)==1 then return nil; end
 local spawnCount=BossSpawnCount();
 if spawnCount>=BOSS_LIVES then Log("boss spawn blocked reason=LIVES_EXHAUSTED count="..spawnCount.." max="..BOSS_LIVES); return nil; end
 local barbID=-1; for _,player in ipairs(PlayerManager.GetAliveBarbarians()) do barbID=player:GetID(); break; end
 if barbID<0 then Log("boss delayed reason=BARBARIAN_OWNER_MISSING"); return nil; end
 local purification=Game.GetProperty("LOTM_RESCUE_PHASE10_PURIFICATION_LOCKED");
 if purification==nil then Log("boss delayed reason=PURIFICATION_NOT_LOCKED"); return nil; end
 local index,tier=TierFor(Number(purification,0));
 local independentOwner=IndependentOwnerID();
 local ownerMode=tostring(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_OWNER_MODE") or "BARBARIAN_FIRST");
 local owner=ownerMode=="INDEPENDENT_FREE_CITIES" and independentOwner or barbID;
 if owner<0 then owner=barbID; ownerMode="BARBARIAN_FIRST"; end
 local unit=Spawn(owner,BOSS_TYPE,"BOSS",2,1);
 if unit==nil and owner==barbID and independentOwner>=0 then
  Log("boss owner fallback from=BARBARIAN to=INDEPENDENT_FREE_CITIES reason=NEAR_CENTER_PLACEMENT_REJECTED owner="..independentOwner);
  owner=independentOwner; ownerMode="INDEPENDENT_FREE_CITIES";
  unit=Spawn(owner,BOSS_TYPE,"BOSS",2,1);
 end
 if unit==nil then return nil; end
 Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_OWNER_MODE",ownerMode);
 local strengthOK=ExactStrength(unit,tier.Strength); local attacks=ApplyBits(unit,"ABILITY_LOTM_RESCUE_P10_EXTRA_ATTACK_",ATTACK_BITS,math.max(0,tier.Skills-1));
 unit:SetProperty("LOTM_RESCUE_PHASE10_BOSS_TIER",index); unit:SetProperty("LOTM_RESCUE_PHASE10_BOSS_PHASE",Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_PHASES_REMAINING"),tier.Phases));
  spawnCount=spawnCount+1; Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_SPAWN_COUNT",spawnCount); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_GENERATED",1); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_RESPAWN_PENDING",0);
  local epoch=BossEpoch()+1; Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_EPOCH",epoch);
  unit:SetProperty("LOTM_RESCUE_PHASE10_BOSS_EPOCH",epoch);
 local plot=Map.GetPlot(unit:GetX(),unit:GetY()); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_OWNER",unit:GetOwner()); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_UNIT",unit:GetID()); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_PLOT",plot~=nil and plot:GetIndex() or -1); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_X",unit:GetX()); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_Y",unit:GetY());
 Log("boss ready tier="..index.." ownerMode="..ownerMode.." owner="..unit:GetOwner().." strength="..tier.Strength.." applied="..Number(unit:GetProperty("LOTM_RESCUE_PHASE10_APPLIED_STRENGTH"),-1).." strengthOK="..tostring(strengthOK).." extraAttacks="..attacks.." phasesRemaining="..Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_PHASES_REMAINING"),tier.Phases).." heal="..tier.Heal.." summon="..tier.Summon.." skills="..tier.Skills);
 return unit;
end

local function MigrateBossPosition()
 if Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_POSITION_VERSION"),0)>=BOSS_POSITION_VERSION then return true; end
 local boss=FindRole("BOSS"); local center=CenterPlot();
 if boss==nil then Log("boss position migration delayed reason=BOSS_NOT_INDEXED"); return false; end
 if center==nil then Log("boss position migration delayed reason=CENTER_MISSING"); return false; end
 local bossPlot=Map.GetPlot(boss:GetX(),boss:GetY());
 if bossPlot==nil then Log("boss position migration delayed reason=BOSS_PLOT_MISSING unit="..boss:GetID()); return false; end
 local before=Map.GetPlotDistance(center:GetX(),center:GetY(),bossPlot:GetX(),bossPlot:GetY());
 if before>=1 and before<=2 then
  Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_POSITION_VERSION",BOSS_POSITION_VERSION);
  Log("boss position migration retained unit="..boss:GetID().." distance="..before.." plot="..bossPlot:GetIndex());
  return true;
 end
 local candidates=CandidatePlots(2,1);
 if #candidates==0 or UnitManager==nil or UnitManager.PlaceUnit==nil then
  Log("boss position migration delayed reason=NO_NEAR_CENTER_PLOT distance="..before); return false;
 end
 for attempt,entry in ipairs(candidates) do
  local destination=entry.Plot;
  local ok,result=pcall(UnitManager.PlaceUnit,boss,destination:GetX(),destination:GetY());
  local moved=ok and result~=false and boss:GetX()==destination:GetX() and boss:GetY()==destination:GetY();
  if moved then
   Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_POSITION_VERSION",BOSS_POSITION_VERSION);
   Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_PLOT",destination:GetIndex());
   Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_X",boss:GetX()); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_Y",boss:GetY());
   Log("boss position migrated unit="..boss:GetID().." fromDistance="..before.." attempt="..attempt.."/"..#candidates.." toPlot="..destination:GetIndex().." toDistance="..entry.Distance);
   return true;
  end
 end
 Log("boss position migration delayed reason=ALL_NEAR_CENTER_PLACES_FAILED distance="..before.." candidates="..#candidates); return false;
end

local function EnsureChurchGods()
 local owner=Number(Game.GetProperty("LOTM_RESCUE_TEST_PLAYER_ID"),-1);
 if owner<0 or Players[owner]==nil or not Players[owner]:IsAlive() then Log("church gods delayed reason=INDEPENDENT_OWNER_MISSING"); return false; end
 for _,meta in ipairs(CHURCH_GODS) do
  local unit=FindRole(meta.Role); local state=tostring(Game.GetProperty(RoleKey(meta.Role,"STATE")) or "");
  local canSpawn=state=="";
  local respawning=state=="RESPAWN_PENDING" and WorldTurn()>=Number(Game.GetProperty(RoleKey(meta.Role,"RESPAWN_TURN")),2147483647);
  if unit==nil and state=="ACTIVE" then
   if Number(Game.GetProperty(RoleKey(meta.Role,"RESPAWN_USED")),0)>=1 then
    Game.SetProperty(RoleKey(meta.Role,"STATE"),"DEAD"); state="DEAD";
   else
    ScheduleChurchGodRespawn(meta.Role); state="RESPAWN_PENDING";
   end
  end
  if unit==nil and (canSpawn or respawning) then
   unit=Spawn(owner,meta.Type,meta.Role,4);
   if unit~=nil then
    ExactStrength(unit,550); Game.SetProperty(RoleKey(meta.Role,"STATE"),"ACTIVE");
    if respawning then Game.SetProperty(RoleKey(meta.Role,"RESPAWN_USED"),1); Game.SetProperty(RoleKey(meta.Role,"RESPAWN_TURN"),nil); Log("church god respawned role="..meta.Role.." turn="..WorldTurn().." remaining=0"); end
   end
  end
  -- Existing saves can enter this version with the god already serialized.
  -- Reapply the exact synchronized target so the 255-clamp correction never
  -- depends on creating a replacement unit.
  if unit~=nil then ExactStrength(unit,PLAYER_GOD_BASE_STRENGTH); PublishNetworkConfirmedDamage(unit); end
 end
 return true;
end

local function RevealBattlefield()
 if Number(Game.GetProperty("LOTM_RESCUE_PHASE10_VISIBILITY_VERSION"),0)>=VISIBILITY_VERSION then return; end
 local center=CenterPlot(); if center==nil then return; end
 local revealed=0;
 for _,player in ipairs(HumanPlayers()) do
  local visibility=PlayersVisibility[player:GetID()];
  if visibility~=nil then
   for dx=-BATTLEFIELD_REVEAL_RADIUS,BATTLEFIELD_REVEAL_RADIUS do for dy=-BATTLEFIELD_REVEAL_RADIUS,BATTLEFIELD_REVEAL_RADIUS do
    local plot=Map.GetPlotXYWithRangeCheck(center:GetX(),center:GetY(),dx,dy,BATTLEFIELD_REVEAL_RADIUS);
    if plot~=nil then visibility:ChangeVisibilityCount(plot:GetIndex(),1); revealed=revealed+1; end
   end end
  end
 end
 Game.SetProperty("LOTM_RESCUE_PHASE10_VISIBILITY_VERSION",VISIBILITY_VERSION);
 Log("battlefield revealed center="..center:GetIndex().." radius="..BATTLEFIELD_REVEAL_RADIUS.." visibilityEntries="..revealed);
end

local function PlotSetCSV(indices)
 local text={}; for _,index in ipairs(indices) do text[#text+1]=tostring(index); end
 return table.concat(text,",");
end

local function PlotSetFromCSV(value)
 local result={}; local seen={}; for token in string.gmatch(tostring(value or ""),"[^,]+") do
  local index=tonumber(token); if index~=nil and not seen[index] and Map.GetPlotByIndex(index)~=nil then result[#result+1]=index; seen[index]=true; end
 end
 table.sort(result);
 return result;
end

local function BossSightPlots(boss)
 local result={}; local seen={}; if boss==nil then return result; end
 for dx=-BOSS_SIGHT_RADIUS,BOSS_SIGHT_RADIUS do for dy=-BOSS_SIGHT_RADIUS,BOSS_SIGHT_RADIUS do
  local plot=Map.GetPlotXYWithRangeCheck(boss:GetX(),boss:GetY(),dx,dy,BOSS_SIGHT_RADIUS);
  local index=plot~=nil and plot:GetIndex() or -1;
  if index>=0 and not seen[index] then result[#result+1]=index; seen[index]=true; end
 end end
 table.sort(result);
 return result;
end

local function MaintainBossVisibility()
 if Number(Game.GetProperty("LOTM_RESCUE_PHASE10_DESCENT_TRIGGERED"),0)~=1 then return; end
 local boss=FindRole("BOSS"); local bossPlot=boss~=nil and Map.GetPlot(boss:GetX(),boss:GetY()) or nil;
 local bossPlotIndex=bossPlot~=nil and bossPlot:GetIndex() or -1;
 local current=BossSightPlots(boss); local currentSet={}; for _,index in ipairs(current) do currentSet[index]=true; end
 local currentCSV=PlotSetCSV(current);
 local changed=0; local restored=0;
 for _,player in ipairs(HumanPlayers()) do
  local visibility=PlayersVisibility[player:GetID()];
  if visibility~=nil then
    local key="LOTM_RESCUE_PHASE10_BOSS_SIGHT_PLOTS_V"..BOSS_SIGHT_VERSION;
    local previous=PlotSetFromCSV(player:GetProperty(key));
   local previousSet={}; for _,index in ipairs(previous) do previousSet[index]=true; end
   for _,index in ipairs(previous) do
    if not currentSet[index] and visibility:GetVisibilityCount(index)>0 then visibility:ChangeVisibilityCount(index,-1); changed=changed+1; end
   end
   for _,index in ipairs(current) do
    if not previousSet[index] then visibility:ChangeVisibilityCount(index,1); changed=changed+1;
    elseif not visibility:IsVisible(index) then visibility:ChangeVisibilityCount(index,1); restored=restored+1; end
   end
   player:SetProperty(key,currentCSV);
   player:SetProperty("LOTM_RESCUE_PHASE10_BOSS_SIGHT_UNIT",boss~=nil and boss:GetID() or -1);
   player:SetProperty("LOTM_RESCUE_PHASE10_BOSS_SIGHT_PLOT",bossPlotIndex);
  end
 end
  Log("boss sight maintained unit="..tostring(boss~=nil and boss:GetID() or -1).." plot="..tostring(bossPlotIndex).." radius="..BOSS_SIGHT_RADIUS.." changed="..changed.." restored="..restored.." humans="..#HumanPlayers());
end

 local function CombatStrengthDamage(attack,defense)
  return math.max(1,math.min(100,math.floor(24*math.exp((attack-defense)/25))));
end

local function EffectiveCombatStrength(unit,fallback)
 if unit==nil then return fallback; end
 -- Final-battle strengths intentionally exceed GameCore's native display
 -- range.  GetCombat() is observed to clamp those units at 255, so using it
 -- made a 550/999-strength god retaliate for only one damage.  The exact
 -- synchronized target published by ExactStrength is authoritative for gods;
 -- ordinary units continue to use their live runtime value.
 if Number(unit:GetProperty(GOD_PROPERTY),0)==1 then
  local applied=Number(unit:GetProperty("LOTM_RESCUE_PHASE10_APPLIED_STRENGTH"),0);
  if applied>0 then return applied; end
 end
 local runtime=Number(unit:GetCombat(),0);
 if runtime>0 then return runtime; end
 return Number(unit:GetProperty("LOTM_RESCUE_PHASE10_APPLIED_STRENGTH"),fallback);
end

local function EffectiveAttackStrength(unit,fallback)
 if unit==nil then return fallback; end
 if Number(unit:GetProperty(GOD_PROPERTY),0)==1 then return EffectiveCombatStrength(unit,fallback); end
 return math.max(Number(unit:GetCombat(),0),Number(unit:GetRangedCombat(),0),Number(unit:GetBombardCombat(),0),fallback or 0);
end

local function IsGod(unit)
 return unit~=nil and Number(unit:GetProperty(GOD_PROPERTY),0)==1;
end

local function UnitKey(playerID,unitID)
 return tostring(playerID)..":"..tostring(unitID);
end

local function QueueNetworkRemoval(playerID,unitID,role)
 local normalizedPlayerID=tonumber(playerID); local normalizedUnitID=tonumber(unitID);
 if normalizedPlayerID==nil or normalizedUnitID==nil or role==nil or role=="" then return; end
 local key=UnitKey(normalizedPlayerID,normalizedUnitID);
 local epoch=tostring(role)=="BOSS" and BossEpoch() or 0;
 local queueKey=tostring(role)=="BOSS" and (key..":E"..tostring(epoch)) or key;
 local existing=m_pendingNetworkRemovalKeys[queueKey];
 if existing~=nil then
  existing.Intentional=existing.Intentional==true or m_bossIntentionalDefeat[key]==true;
  return;
 end
 local entry={PlayerID=normalizedPlayerID,UnitID=normalizedUnitID,Role=tostring(role),
  QueuedTurn=Game.GetCurrentGameTurn(),Key=queueKey,IdentityKey=key,Epoch=epoch,
  Intentional=m_bossIntentionalDefeat[key]==true};
 m_pendingNetworkRemovals[#m_pendingNetworkRemovals+1]=entry; m_pendingNetworkRemovalKeys[queueKey]=entry;
end

-- Civ VI can clamp scripted damage at maxDamage-1, leaving the Boss visibly
-- alive with one hit point and never emitting a reliable combat-death event.
-- Treat that terminal damage state as lethal and route it through the normal
-- UnitRemoved/ResolveBossDefeat path.  Model migration clears EngineKey first,
-- so migration kills cannot enter this path.
local function KillBossAtTerminalDamage(boss,reason)
 if boss==nil or boss:IsDead() or boss:IsDelayedDeath() then return false; end
 local maximum=Number(boss:GetMaxDamage(),100); local current=Number(boss:GetDamage(),0);
 if current<math.max(0,maximum-1) then return false; end
 local key=boss:GetOwner()..":"..boss:GetID(); m_bossIntentionalDefeat[key]=true;
 local ok,result=pcall(UnitManager.Kill,boss);
 Log("boss terminal damage kill owner="..boss:GetOwner().." unit="..boss:GetID().." damage="..current.." max="..maximum.." reason="..tostring(reason).." ok="..tostring(ok).." result="..tostring(result));
 return ok and result~=false;
end

local function AlliedAttack(attacker,boss)
 if attacker==nil or boss==nil or boss:IsDead() or boss:IsDelayedDeath() then return false,"TARGET_GONE",0; end
 local attack=EffectiveCombatStrength(attacker,550);
 local defense=EffectiveCombatStrength(boss,540);
 local damage=math.min(35,CombatStrengthDamage(attack,defense));
 local maximum=Number(boss:GetMaxDamage(),100); local current=Number(boss:GetDamage(),0);
 if current+damage>=math.max(0,maximum-1) then
  local owner=boss:GetOwner(); local unitID=boss:GetID(); local epoch=BossEpoch();
  local ok=KillBossAtTerminalDamage(boss,"ALLIED_ATTACK");
  if ok and IsNetworkMultiplayer() and ResolveBossDefeat~=nil then
   ResolveBossDefeat(owner,unitID,"ALLIED_SIEGE",epoch);
  end
  return ok,ok and "PHASE_DEFEATED" or "KILL_FAILED",damage;
 end
 boss:ChangeDamage(damage); PublishNetworkConfirmedDamage(boss); return true,"DAMAGE",damage;
end

-- BEGIN USER AUTHORIZED RESCUE STORM DAMAGE (resource434)
-- Called only by synchronized storm-plan execution. Keep this bounded API
-- separate from native combat and retain the existing Boss phase/death path.
function LOTM_RESCUE_Phase10.ApplyStormDamage(boss,baseline,goal,epoch,caster,serial)
 if not Active() or boss==nil or boss:IsDead() or boss:IsDelayedDeath() then return false; end
 local row=GameInfo.Units[boss:GetType()];
 local isBoss=(row~=nil and row.UnitType==BOSS_TYPE)
  or (tostring(boss:GetProperty("LOTM_RESCUE_PHASE10_ROLE") or "")=="BOSS" and IsGod(boss));
 if not isBoss or Number(boss:GetProperty("LOTM_RESCUE_PHASE10_BOSS_EPOCH"),0)~=epoch
  or baseline==nil or baseline<0 or caster==nil or serial==nil or serial<1 then return false; end
 local maximum=Number(boss:GetMaxDamage(),100);
 if goal~=math.min(maximum,baseline+20) then return false; end
 local owner,id=boss:GetOwner(),boss:GetID(); local key=UnitKey(owner,id);
 local receipt="LOTM_RESCUE_PHASE10_STORM_DAMAGE:"..caster..":"..serial;
 local spent=math.max(0,math.min(20,Number(boss:GetProperty(receipt),0)));
 local current=Number(boss:GetDamage(),0);
 local delta=math.min(20-spent,math.max(0,math.min(goal,maximum-1)-current));
 if delta>0 then
  -- A scripted hit must not pair with an earlier unpaired native combat.
  m_nativeDamageEvents[key]=nil; m_bossCombatEvents[key]=nil;
  m_nativeDamageCorrections[key]={Old=current,New=current+delta};
  local ok,err=pcall(function() boss:ChangeDamage(delta); end);
  local after=UnitManager.GetUnit(owner,id);
  if after==nil or after:IsDead() or after:IsDelayedDeath() then
   if IsNetworkMultiplayer() and ResolveBossDefeat~=nil then ResolveBossDefeat(owner,id,"STORM_SKILL",epoch); end
   Log("storm damage owner="..owner.." unit="..id.." cast="..caster..":"..serial.." before="..current.." amount="..delta.." phaseDefeated=true");
   return true;
  end
  local observed=math.max(0,math.min(delta,Number(after:GetDamage(),current)-current));
  spent=spent+observed; after:SetProperty(receipt,spent); PublishNetworkConfirmedDamage(after);
  if not ok and observed<delta then Log("storm damage incomplete unit="..key.." error="..tostring(err)); return false; end
  if observed<delta then return false; end
  Log("storm damage owner="..owner.." unit="..id.." cast="..caster..":"..serial.." before="..current.." after="..Number(after:GetDamage(),0).." amount="..observed.." spent="..spent);
  boss=after;
 end
 -- Existing terminal-damage semantics are retained: <=20 remaining HP can
 -- defeat one phase; this API never manufactures a full-health nuclear kill.
 if goal>=maximum-1 and Number(boss:GetDamage(),0)>=maximum-1 then
  local killed=KillBossAtTerminalDamage(boss,"STORM_SKILL");
  if killed and IsNetworkMultiplayer() and ResolveBossDefeat~=nil then ResolveBossDefeat(owner,id,"STORM_SKILL",epoch); end
  return killed;
 end
 PublishNetworkConfirmedDamage(boss);
 return spent>=20 or Number(boss:GetDamage(),0)>=goal;
end
-- END USER AUTHORIZED RESCUE STORM DAMAGE (resource434)

local function OuterGodUnitAttack(boss,target)
 if boss==nil or target==nil or target:IsDead() or target:IsDelayedDeath() then return false,"TARGET_GONE",0; end
 if ProtectDescent(target,"OUTER_GOD_ATTACK") then return false,"DESCENT_PROTECTED",0; end
 local attack=EffectiveCombatStrength(boss,555);
 local defense=EffectiveCombatStrength(target,550);
 local damage=CombatStrengthDamage(attack,defense);
 local maximum=Number(target:GetMaxDamage(),100); local current=Number(target:GetDamage(),0);
 if current+damage>=maximum then
  local ok=pcall(UnitManager.Kill,target); return ok,ok and "GOD_DESTROYED" or "KILL_FAILED",damage;
 end
 target:ChangeDamage(damage); PublishNetworkConfirmedDamage(target); return true,"DAMAGE",damage;
end

local function AdjacentCityBlocker(target)
 if target==nil or target.City==nil then return nil; end
 local player=Players[target.Owner]; if player==nil or not player:IsAlive() then return nil; end
 local candidates={};
 for _,unit in player:GetUnits():Members() do
  if not unit:IsDead() and not unit:IsDelayedDeath() and Map.GetPlotDistance(unit:GetX(),unit:GetY(),target.City:GetX(),target.City:GetY())==1 then
   candidates[#candidates+1]=unit;
  end
 end
 table.sort(candidates,function(a,b) return a:GetID()<b:GetID(); end);
 return candidates[1];
end

local function OpenFirstRingCount(targetPlot)
 if targetPlot==nil then return 0; end local count=0; local seen={};
 for dx=-1,1 do for dy=-1,1 do
  local plot=Map.GetPlotXYWithRangeCheck(targetPlot:GetX(),targetPlot:GetY(),dx,dy,1);
  if plot~=nil and not seen[plot:GetIndex()] and Map.GetPlotDistance(plot:GetX(),plot:GetY(),targetPlot:GetX(),targetPlot:GetY())==1 then
   seen[plot:GetIndex()]=true;
   if not plot:IsWater() and not plot:IsImpassable() and not plot:IsCity() and plot:GetDistrictType()<0 and plot:GetUnitCount()==0 then count=count+1; end
  end
 end end
 return count;
end

local function PlacementRejected(moveDiagnostic)
 if type(moveDiagnostic)~="table" then return false; end
 return moveDiagnostic.Status=="PLACE_FAILED_ALL" or moveDiagnostic.Status=="PLACE_FAILED_UNEXPECTED_COORD_CHANGE";
end

local function AttackAdjacentCityBlocker(attacker,target)
 local blocker=AdjacentCityBlocker(target); if blocker==nil then return false,"NO_CITY_BLOCKER",0,-1,-1; end
 local owner=blocker:GetOwner(); local unitID=blocker:GetID();
 local attacked,reason,damage=OuterGodUnitAttack(attacker,blocker);
 if attacked and reason=="GOD_DESTROYED" then reason="CITY_BLOCKER_DESTROYED"; end
 return attacked,reason,damage,owner,unitID;
end

local function FirstRingEntries(targetPlot)
 local entries={}; local seen={};
 for dx=-1,1 do for dy=-1,1 do
  local plot=Map.GetPlotXYWithRangeCheck(targetPlot:GetX(),targetPlot:GetY(),dx,dy,1);
  if plot~=nil and Map.GetPlotDistance(plot:GetX(),plot:GetY(),targetPlot:GetX(),targetPlot:GetY())==1 and not seen[plot:GetIndex()] then
   seen[plot:GetIndex()]=true;
   local water=plot:IsWater(); local impassable=plot:IsImpassable(); local city=plot:IsCity();
   local district=plot:GetDistrictType(); local units=plot:GetUnitCount();
   local open=not water and not impassable and not city and district<0 and units==0;
   entries[#entries+1]={Index=plot:GetIndex(),Text=table.concat({
    "plot="..plot:GetIndex(),"xy="..plot:GetX()..":"..plot:GetY(),"owner="..plot:GetOwner(),
    "terrain="..plot:GetTerrainType(),"feature="..plot:GetFeatureType(),"continent="..plot:GetContinentType(),
    "water="..tostring(water),"impassable="..tostring(impassable),"city="..tostring(city),
    "district="..district,"units="..units,"open="..tostring(open)
   },",")};
  end
 end end
 table.sort(entries,function(a,b) return a.Index<b.Index; end);
 local result={}; for _,entry in ipairs(entries) do result[#result+1]="{"..entry.Text.."}"; end
 return table.concat(result,";");
end

local function LogCityAssaultDiagnostic(actor,target,stage,moveDiagnostic)
 if not IsNetworkMultiplayer() or actor==nil or target==nil or target.City==nil then return; end
 local targetPlot=Map.GetPlot(target.City:GetX(),target.City:GetY()); if targetPlot==nil then return; end
 local details="";
 if type(moveDiagnostic)=="table" then
  details=" status="..tostring(moveDiagnostic.Status).." source="..tostring(moveDiagnostic.Source).." target="..tostring(moveDiagnostic.Target)..
   " candidates="..tostring(moveDiagnostic.CandidateCount).." crossContinent="..tostring(moveDiagnostic.CrossContinent)..
   " selection="..tostring(moveDiagnostic.Selection).." destination="..tostring(moveDiagnostic.Destination)..
   " destinationDistance="..tostring(moveDiagnostic.DestinationDistance).." callOK="..tostring(moveDiagnostic.CallOK)..
   " retryCandidates="..tostring(moveDiagnostic.RetryCandidateCount).." attemptCount="..tostring(moveDiagnostic.AttemptCount)..
   " rawResultType="..tostring(moveDiagnostic.RawResultType).." rawResult="..tostring(moveDiagnostic.RawResult)..
   " failureReason="..tostring(moveDiagnostic.FailureReason).." finalXY="..tostring(moveDiagnostic.FinalX)..":"..tostring(moveDiagnostic.FinalY)..
   " moved="..tostring(moveDiagnostic.Moved).." attempts="..tostring(type(moveDiagnostic.Attempts)=="table" and table.concat(moveDiagnostic.Attempts,"|") or "");
 end
 Log("city assault diagnostic stage="..stage.." actorOwner="..actor:GetOwner().." actorUnit="..actor:GetID()..
  " cityOwner="..target.Owner.." city="..target.ID..details.." firstRing="..FirstRingEntries(targetPlot));
end

local function NearestChurchGod(boss)
 local candidates={};
 for _,meta in ipairs(CHURCH_GODS) do
  local unit=FindRole(meta.Role);
  if unit~=nil then candidates[#candidates+1]={Role=meta.Role,Unit=unit,Distance=Map.GetPlotDistance(boss:GetX(),boss:GetY(),unit:GetX(),unit:GetY())}; end
 end
 table.sort(candidates,function(a,b) if a.Distance~=b.Distance then return a.Distance<b.Distance; end return a.Role<b.Role; end);
 return candidates[1];
end

local function NearestCity(unit)
 local candidates={}; local protected={};
 for _,zone in ipairs({"CENTER","FOOL","NIGHT","STORM"}) do
  local plotIndex=Number(Game.GetProperty("LOTM_RESCUE_"..zone.."_CITY_PLOT"),-1); if plotIndex>=0 then protected[plotIndex]=true; end
 end
 for _,playerID in ipairs(PlayerManager.GetAliveIDs()) do
  local player=Players[playerID];
  if player~=nil and player:IsAlive() then
   for _,city in player:GetCities():Members() do
    local plot=Map.GetPlot(city:GetX(),city:GetY());
    if plot~=nil and protected[plot:GetIndex()]~=true then
      local distance=Map.GetPlotDistance(unit:GetX(),unit:GetY(),city:GetX(),city:GetY());
     candidates[#candidates+1]={City=city,Owner=playerID,ID=city:GetID(),Distance=distance};
    end
   end
  end
 end
 table.sort(candidates,function(a,b)
  if a.Distance~=b.Distance then return a.Distance<b.Distance; end
  if a.Owner~=b.Owner then return a.Owner<b.Owner; end
  return a.ID<b.ID;
 end);
 return candidates[1];
end

local function LockedCityTarget(unit)
 local owner=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_CITY_LOCK_OWNER"),-1);
 local cityID=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_CITY_LOCK_ID"),-1);
 if owner<0 or cityID<0 then return nil; end
 local city=CityManager.GetCity(owner,cityID); if city==nil then return nil; end
 local plot=Map.GetPlot(city:GetX(),city:GetY()); if plot==nil then return nil; end
 for _,zone in ipairs({"CENTER","FOOL","NIGHT","STORM"}) do
  if plot:GetIndex()==Number(Game.GetProperty("LOTM_RESCUE_"..zone.."_CITY_PLOT"),-1) then return nil; end
 end
 return {City=city,Owner=owner,ID=cityID,Distance=Map.GetPlotDistance(unit:GetX(),unit:GetY(),city:GetX(),city:GetY())};
end

local function UpdateBossCityLock(target,turn)
 local owner=target~=nil and target.Owner or -1; local cityID=target~=nil and target.ID or -1;
 local previousOwner=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_CITY_LOCK_OWNER"),-1);
 local previousCity=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_CITY_LOCK_ID"),-1);
 local start=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_CITY_LOCK_START"),turn);
 if owner~=previousOwner or cityID~=previousCity then
  start=turn; Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_CITY_LOCK_OWNER",owner); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_CITY_LOCK_ID",cityID); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_CITY_LOCK_START",start);
 end
 return start,math.max(1,turn-start+1);
end

local function ClearBossCityLock(reason)
 local owner=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_CITY_LOCK_OWNER"),-1); local cityID=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_CITY_LOCK_ID"),-1);
 if owner>=0 or cityID>=0 then Log("outer god city lock cleared owner="..owner.." city="..cityID.." reason="..tostring(reason)); end
 Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_CITY_LOCK_OWNER",nil); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_CITY_LOCK_ID",nil); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_CITY_LOCK_START",nil);
end

local DestroyCityDirect;
local function GuideMinions(playerID,force)
 local humans=HumanPlayers(); local anchor=#humans>0 and humans[1]:GetID() or -1;
 if not force and playerID~=anchor then return; end
 local turn=WorldTurn(); if Number(Game.GetProperty("LOTM_RESCUE_PHASE10_MINION_ACTION_TURN"),-1)==turn then return; end
 if LOTM_RESCUE_SyncActions==nil then return; end
 local minions={};
 for _,barbarian in ipairs(PlayerManager.GetAliveBarbarians()) do
  for _,unit in barbarian:GetUnits():Members() do
   if Number(unit:GetProperty("LOTM_RESCUE_PHASE10_IS_MINION"),0)==1 and not unit:IsDead() and not unit:IsDelayedDeath() then minions[#minions+1]=unit; end
  end
 end
 table.sort(minions,function(a,b) if a:GetOwner()~=b:GetOwner() then return a:GetOwner()<b:GetOwner(); end return a:GetID()<b:GetID(); end);
 for _,minion in ipairs(minions) do
  local target=NearestCity(minion); local targetPlot=target~=nil and Map.GetPlot(target.City:GetX(),target.City:GetY()) or nil;
  if target~=nil and targetPlot~=nil then
   local before=Map.GetPlotDistance(minion:GetX(),minion:GetY(),targetPlot:GetX(),targetPlot:GetY()); local moved=false; local moveReason="ADJACENT"; local destination=-1; local moveDiagnostic=IsNetworkMultiplayer() and {} or nil;
   if before>1 then LogCityAssaultDiagnostic(minion,target,"BEFORE_MOVE",nil); moved,moveReason,destination=LOTM_RESCUE_SyncActions.MoveToward(minion,targetPlot,5,false,true,nil,nil,moveDiagnostic); LogCityAssaultDiagnostic(minion,target,"AFTER_MOVE",moveDiagnostic); end
   local after=Map.GetPlotDistance(minion:GetX(),minion:GetY(),targetPlot:GetX(),targetPlot:GetY()); local destroyed=false; local destroyReason="OUT_OF_RANGE";
   local blockerAttacked=false; local blockerReason="NOT_NEEDED"; local blockerDamage=0; local blockerOwner=-1; local blockerUnit=-1;
   if after<=1 then destroyed,destroyReason=DestroyCityDirect(target.City);
   elseif after==2 then
    blockerAttacked,blockerReason,blockerDamage,blockerOwner,blockerUnit=AttackAdjacentCityBlocker(minion,target);
    if not blockerAttacked and IsNetworkMultiplayer() and PlacementRejected(moveDiagnostic) and OpenFirstRingCount(targetPlot)>0 then
     destroyed,destroyReason=DestroyCityDirect(target.City); if destroyed then destroyReason="FORCED_SIEGE_"..destroyReason; end
    end
   end
   if before>1 then LogCityAssaultDiagnostic(minion,target,"AFTER_ACTION",nil); end
   UnitManager.FinishMoves(minion);
   Log("outer god minion action turn="..turn.." owner="..minion:GetOwner().." unit="..minion:GetID().." cityOwner="..target.Owner.." city="..target.ID.." before="..before.." after="..after.." moved="..tostring(moved).." moveReason="..moveReason.." destination="..destination.." destroyed="..tostring(destroyed).." destroyReason="..destroyReason.." blockerAttacked="..tostring(blockerAttacked).." blockerReason="..blockerReason.." blockerDamage="..blockerDamage.." blockerOwner="..blockerOwner.." blockerUnit="..blockerUnit);
  else
   UnitManager.FinishMoves(minion); Log("outer god minion action delayed turn="..turn.." owner="..minion:GetOwner().." unit="..minion:GetID().." reason=NO_UNPROTECTED_CITY");
  end
 end
 Game.SetProperty("LOTM_RESCUE_PHASE10_MINION_ACTION_TURN",turn);
end

DestroyCityDirect=function(city)
 if city==nil then return false,"CITY_MISSING"; end
 local owner=city:GetOwner(); local cityID=city:GetID(); local live=CityManager.GetCity(owner,cityID);
 if live==nil then return false,"CITY_MISSING"; end
 if CityManager.DestroyCity~=nil then
  local ok,result=pcall(CityManager.DestroyCity,live);
  if ok and result~=false and CityManager.GetCity(owner,cityID)==nil then return true,"CITY_DESTROYED"; end
 end
 if CityManager.RequestCommand==nil or CityCommandTypes==nil or CityCommandTypes.DESTROY==nil or CityDestroyDirectives==nil or CityDestroyDirectives.RAZE==nil or UnitOperationTypes==nil or UnitOperationTypes.PARAM_FLAGS==nil then return false,"CITY_DESTROY_API_UNAVAILABLE"; end
 local parameters={}; parameters[UnitOperationTypes.PARAM_FLAGS]=CityDestroyDirectives.RAZE;
 local ok,result=pcall(CityManager.RequestCommand,live,CityCommandTypes.DESTROY,parameters);
 if not ok or result==false then return false,"CITY_DESTROY_REQUEST_FAILED"; end
 return true,"CITY_DESTROY_REQUESTED";
end

local function GuideOuterGod(playerID,force)
 local humans=HumanPlayers(); local anchor=#humans>0 and humans[1]:GetID() or -1;
 if not force and playerID~=anchor then return; end
 local turn=WorldTurn(); if Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_ACTION_TURN"),-1)==turn then return; end
 local boss=FindRole("BOSS"); if boss==nil or LOTM_RESCUE_SyncActions==nil then return; end
 local _,lockedTier=TierFor(Number(Game.GetProperty("LOTM_RESCUE_PHASE10_PURIFICATION_LOCKED"),0));
 ExactStrength(boss,lockedTier.Strength);
 local target=NearestChurchGod(boss); local targetPlot=nil; local kind="CHURCH_GOD"; local owner=-1; local id=-1; local role="";
 if target~=nil then targetPlot=Map.GetPlot(target.Unit:GetX(),target.Unit:GetY()); owner=target.Unit:GetOwner(); id=target.Unit:GetID(); role=target.Role;
 else
  target=LockedCityTarget(boss) or NearestCity(boss); kind="CITY";
  if target~=nil then targetPlot=Map.GetPlot(target.City:GetX(),target.City:GetY()); owner=target.Owner; id=target.ID; end
 end
 if target==nil or targetPlot==nil then Log("outer god action delayed reason=NO_TARGET turn="..turn); return; end
 local lockStart=-1; local lockAge=0;
 if kind=="CITY" then lockStart,lockAge=UpdateBossCityLock(target,turn); else ClearBossCityLock("NON_CITY_TARGET"); end
 local before=Map.GetPlotDistance(boss:GetX(),boss:GetY(),targetPlot:GetX(),targetPlot:GetY()); local moved=false; local reason="ADJACENT"; local destination=-1; local moveDiagnostic=IsNetworkMultiplayer() and kind=="CITY" and {} or nil;
 if before>1 then if kind=="CITY" then LogCityAssaultDiagnostic(boss,target,"BEFORE_MOVE",nil); end moved,reason,destination=LOTM_RESCUE_SyncActions.MoveToward(boss,targetPlot,6,false,true,nil,nil,moveDiagnostic); if kind=="CITY" then LogCityAssaultDiagnostic(boss,target,"AFTER_MOVE",moveDiagnostic); end end
 local after=Map.GetPlotDistance(boss:GetX(),boss:GetY(),targetPlot:GetX(),targetPlot:GetY()); local attacked=false; local attackReason="OUT_OF_RANGE"; local damage=0; local blockerOwner=-1; local blockerUnit=-1;
 if after<=1 then
  if kind=="CHURCH_GOD" then attacked,attackReason,damage=OuterGodUnitAttack(boss,target.Unit);
  else attacked,attackReason=DestroyCityDirect(target.City); end
 elseif kind=="CITY" and after==2 then
  attacked,attackReason,damage,blockerOwner,blockerUnit=AttackAdjacentCityBlocker(boss,target);
  if not attacked and IsNetworkMultiplayer() and PlacementRejected(moveDiagnostic) and OpenFirstRingCount(targetPlot)>0 then
   attacked,attackReason=DestroyCityDirect(target.City); if attacked then attackReason="FORCED_SIEGE_"..attackReason; end
  end
 end
 local cityResolved=kind=="CITY" and attacked and (string.find(attackReason,"CITY_DESTROY",1,true)~=nil);
 if kind=="CITY" and not cityResolved and lockAge>=3 then
  local forced,forcedReason=DestroyCityDirect(target.City);
  if forced then attacked=true; attackReason="LOCK_TIMEOUT_3_"..forcedReason; cityResolved=true; end
 end
 if cityResolved then ClearBossCityLock(attackReason); end
 if kind=="CITY" and before>1 then LogCityAssaultDiagnostic(boss,target,"AFTER_ACTION",nil); end
 UnitManager.FinishMoves(boss); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_ACTION_TURN",turn);
 Log("outer god action turn="..turn.." kind="..kind.." role="..role.." owner="..owner.." id="..id.." before="..before.." after="..after.." moved="..tostring(moved).." moveReason="..reason.." destination="..destination.." attacked="..tostring(attacked).." attackReason="..attackReason.." damage="..damage.." blockerOwner="..blockerOwner.." blockerUnit="..blockerUnit.." lockStart="..lockStart.." lockAge="..lockAge.." cityResolved="..tostring(cityResolved));
end

local function GuideChurchGods(playerID,force)
 local humans=HumanPlayers(); local anchor=#humans>0 and humans[1]:GetID() or -1;
 if not force and playerID~=anchor then return; end
 local turn=WorldTurn(); local appliedVersion=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_ALLIED_ACTION_VERSION"),0);
 if appliedVersion>=ALLIED_ACTION_VERSION and Number(Game.GetProperty("LOTM_RESCUE_PHASE10_ALLIED_ACTION_TURN"),-1)==turn then return; end
 local boss=FindRole("BOSS");
 if boss==nil then Log("allied siege delayed reason=BOSS_NOT_INDEXED turn="..turn); return; end
 if LOTM_RESCUE_SyncActions==nil then Log("allied siege delayed reason=SYNC_ACTIONS_MISSING turn="..turn); return; end
 local target=Map.GetPlot(boss:GetX(),boss:GetY()); if target==nil then Log("allied siege delayed reason=BOSS_PLOT_MISSING turn="..turn); return; end
 local indexed={};
 for _,meta in ipairs(CHURCH_GODS) do local unit=FindRole(meta.Role); if unit~=nil then indexed[#indexed+1]={Meta=meta,Unit=unit}; end end
 local found=#indexed;
 if found==0 then Log("allied siege delayed reason=NO_CHURCH_GODS_INDEXED turn="..turn); return; end
 if found<#CHURCH_GODS then Log("allied siege delayed reason=PARTIAL_CHURCH_GODS_INDEXED found="..found.." expected="..#CHURCH_GODS.." turn="..turn); return; end
 for _,entry in ipairs(indexed) do
  local meta=entry.Meta; local unit=entry.Unit;
   local before=Map.GetPlotDistance(unit:GetX(),unit:GetY(),target:GetX(),target:GetY()); local moved=false; local reason="ADJACENT"; local source=Map.GetPlot(unit:GetX(),unit:GetY()); local destination=source~=nil and source:GetIndex() or -1;
   if before>1 then
    local info=GameInfo.Units[unit:GetType()];
    moved,reason,destination=LOTM_RESCUE_SyncActions.MoveToward(unit,target,info~=nil and Number(info.BaseMoves,1) or 1,false,true);
   end
   local after=Map.GetPlotDistance(unit:GetX(),unit:GetY(),target:GetX(),target:GetY()); local attacked=false; local attackReason="OUT_OF_RANGE"; local damage=0;
   if after<=1 then attacked,attackReason,damage=AlliedAttack(unit,boss); end
   UnitManager.FinishMoves(unit);
   Log("allied siege role="..meta.Role.." boss="..boss:GetID().." before="..before.." after="..after.." moved="..tostring(moved).." moveReason="..reason.." destination="..destination.." attacked="..tostring(attacked).." attackReason="..attackReason.." damage="..damage);
   if FindRole("BOSS")==nil then break; end
 end
 Game.SetProperty("LOTM_RESCUE_PHASE10_ALLIED_ACTION_VERSION",ALLIED_ACTION_VERSION);
 Game.SetProperty("LOTM_RESCUE_PHASE10_ALLIED_ACTION_TURN",turn);
 Log("allied siege completed turn="..turn.." godsProcessed="..found);
end

local function FreezeIndependentGodAI(playerID)
 local owner=IndependentOwnerID(); if playerID~=owner then return; end
 for _,meta in ipairs(CHURCH_GODS) do local unit=FindRole(meta.Role); if unit~=nil then UnitManager.FinishMoves(unit); end end
 local boss=FindRole("BOSS"); if boss~=nil and boss:GetOwner()==owner then UnitManager.FinishMoves(boss); end
end

local function MigrateChurchGodOwnership()
 if Number(Game.GetProperty("LOTM_RESCUE_PHASE10_OWNERSHIP_VERSION"),0)>=1 then return; end
 local owner=Number(Game.GetProperty("LOTM_RESCUE_TEST_PLAYER_ID"),-1); local retired=0;
 if owner<0 or Players[owner]==nil or not Players[owner]:IsAlive() then Log("ownership migration delayed reason=INDEPENDENT_OWNER_MISSING"); return; end
 for _,meta in ipairs(CHURCH_GODS) do
  local storedOwner=Number(Game.GetProperty(RoleKey(meta.Role,"OWNER")),-1); local unit=FindRole(meta.Role);
  if unit~=nil and storedOwner~=owner then
   local unitID=unit:GetID(); Game.SetProperty(EngineKey(storedOwner,unitID),nil);
   Game.SetProperty(RoleKey(meta.Role,"OWNER"),nil); Game.SetProperty(RoleKey(meta.Role,"UNIT"),nil); Game.SetProperty(RoleKey(meta.Role,"STATE"),nil);
   local ok=pcall(UnitManager.Kill,unit); if ok then retired=retired+1; end
  end
 end
 Game.SetProperty("LOTM_RESCUE_PHASE10_OWNERSHIP_VERSION",1);
 Log("ownership migration independentOwner="..owner.." retiredHumanChurchGods="..retired);
end

local function PlayerGodRole(playerID) return "PLAYER_GOD_"..tostring(playerID); end
local function PlayerGodIDFromRole(role) return tonumber(string.match(tostring(role or ""),"^PLAYER_GOD_(%d+)$")); end
local function DesiredPlayerGodType(path)
 if PERFECT_MODEL_PATHS[path] then return PERFECT_MODEL_TYPE; end
 return PATH_GODS[path];
end
local function EnsurePlayerGod(player)
 if player==nil or not player:IsHuman() then return nil; end
 local path=tostring(player:GetProperty("LOTM_RP_PATH") or "NONE"); local sequence=Number(player:GetProperty("LOTM_RP_SEQUENCE"),9);
 if sequence>0 or PATH_GODS[path]==nil then return nil; end
 local role=PlayerGodRole(player:GetID()); local unit=FindRole(role); local desiredType=DesiredPlayerGodType(path); local desiredInfo=GameInfo.Units[desiredType];
 if unit~=nil and desiredInfo~=nil and unit:GetType()~=desiredInfo.Index then
  local oldOwner=unit:GetOwner(); local oldID=unit:GetID(); Game.SetProperty(EngineKey(oldOwner,oldID),nil); m_roleUnits[role]=nil;
  Game.SetProperty(RoleKey(role,"OWNER"),nil); Game.SetProperty(RoleKey(role,"UNIT"),nil);
  local ok=pcall(UnitManager.Kill,unit); unit=nil;
  Log("player god model migrated player="..player:GetID().." path="..path.." old="..oldOwner..":"..oldID.." desiredType="..desiredType.." killed="..tostring(ok));
 end
 local state=tostring(Game.GetProperty(RoleKey(role,"STATE")) or "");
 if unit==nil and state=="ACTIVE" then
  if Number(Game.GetProperty(RoleKey(role,"RESPAWN_USED")),0)>=1 then
   Game.SetProperty(RoleKey(role,"STATE"),"DEAD"); state="DEAD";
  else
   local due=WorldTurn()+PLAYER_GOD_RESPAWN_DELAY;
   Game.SetProperty(RoleKey(role,"STATE"),"RESPAWN_PENDING"); Game.SetProperty(RoleKey(role,"RESPAWN_TURN"),due); state="RESPAWN_PENDING";
   Log("player god respawn scheduled role="..role.." deathTurn="..WorldTurn().." respawnTurn="..due.." remaining=1");
  end
 elseif unit==nil and state=="DEAD" and Number(Game.GetProperty(RoleKey(role,"RESPAWN_USED")),0)==0 then
  -- Repair rc.331 saves whose player god was marked DEAD permanently.
  local due=WorldTurn()+PLAYER_GOD_RESPAWN_DELAY;
  Game.SetProperty(RoleKey(role,"STATE"),"RESPAWN_PENDING"); Game.SetProperty(RoleKey(role,"RESPAWN_TURN"),due); state="RESPAWN_PENDING";
  Log("player god respawn migrated role="..role.." deathTurn="..WorldTurn().." respawnTurn="..due.." remaining=1");
 end
 local respawning=state=="RESPAWN_PENDING" and WorldTurn()>=Number(Game.GetProperty(RoleKey(role,"RESPAWN_TURN")),2147483647);
 if unit==nil and (state=="" or respawning) then
  unit=Spawn(player:GetID(),desiredType,role,5);
  if unit~=nil then
   Game.SetProperty(RoleKey(role,"STATE"),"ACTIVE"); player:SetProperty("LOTM_RESCUE_PHASE10_PLAYER_GOD_STATE","ACTIVE"); unit:SetProperty("LOTM_RESCUE_PHASE10_PLAYER_GOD_PATH",path); unit:SetProperty("LOTM_RESCUE_PHASE10_MODEL_SOURCE",desiredType);
   if respawning then Game.SetProperty(RoleKey(role,"RESPAWN_USED"),1); Game.SetProperty(RoleKey(role,"RESPAWN_TURN"),nil); Log("player god respawned role="..role.." turn="..WorldTurn().." remaining=0"); end
  end
 end
 if unit~=nil then
  LOTM_RESCUE_Phase10A.RefreshAll();
  local inherited=Number(player:GetProperty("LOTM_RESCUE_PHASE10A_DIVINE_LEGION_TOTAL"),0);
  local skillReady=Number(player:GetProperty("LOTM_RESCUE_WAR_GOD_RELIC_COMPLETED"),0)==1;
  SetAbilityCount(unit,DIVINE_LEGION_ABILITY,skillReady and 1 or 0);
  local target=PLAYER_GOD_BASE_STRENGTH+(skillReady and math.max(0,inherited) or 0);
  local strengthOK=ExactStrength(unit,target); unit:SetProperty("LOTM_RESCUE_PHASE10_DIVINE_LEGION_TOTAL",inherited); unit:SetProperty("LOTM_RESCUE_PHASE10_DIVINE_LEGION_SKILL",skillReady and 1 or 0);
  local runtimeCombat=Number(unit:GetCombat(),0); local mobilityActive=runtimeCombat>PLAYER_GOD_MOBILITY_THRESHOLD;
  local mobilityOK=SetAbilityCount(unit,PLAYER_GOD_MOBILITY_ABILITY,mobilityActive and 1 or 0);
   unit:SetProperty("LOTM_RESCUE_PHASE10_PLAYER_GOD_RUNTIME_COMBAT",runtimeCombat);
   unit:SetProperty("LOTM_RESCUE_PHASE10_PLAYER_GOD_MOBILITY_BONUS",mobilityActive and PLAYER_GOD_MOBILITY_BONUS or 0);
   PublishNetworkConfirmedDamage(unit);
   Log("divineLegion applied player="..player:GetID().." godUnit="..unit:GetID().." skillReady="..tostring(skillReady).." base="..PLAYER_GOD_BASE_STRENGTH.." inherited="..inherited.." target="..target.." applied="..Number(unit:GetProperty("LOTM_RESCUE_PHASE10_APPLIED_STRENGTH"),-1).." strengthOK="..tostring(strengthOK).." runtimeCombat="..runtimeCombat.." mobilityThreshold="..PLAYER_GOD_MOBILITY_THRESHOLD.." mobilityBonus="..(mobilityActive and PLAYER_GOD_MOBILITY_BONUS or 0).." mobilityOK="..tostring(mobilityOK));
 end
 return unit;
end

-- Called only after Gameplay commits a successful Sequence 0 advancement.
function LOTM_RESCUE_Phase10.OnSequenceZeroAdvanced(playerID)
 if not Active() or Number(Game.GetProperty("LOTM_RESCUE_PHASE10_VICTORY"),0)==1 then return false; end
 if Number(Game.GetProperty("LOTM_RESCUE_PHASE10_DESCENT_TRIGGERED"),0)~=1 then
  Log("sequence zero god player="..tostring(playerID).." reason=WAIT_WORLD_DESCENT"); return false;
 end
 local unit=EnsurePlayerGod(Players[playerID]);
 Log("sequence zero god player="..tostring(playerID).." spawned="..tostring(unit~=nil).." turn="..WorldTurn());
 return unit~=nil;
end

local function CountMinions()
 local barbID=-1; for _,candidate in ipairs(PlayerManager.GetAliveBarbarians()) do barbID=candidate:GetID(); break; end
 local player=barbID>=0 and Players[barbID] or nil; if player==nil then return 0; end
 local count=0; for _,unit in player:GetUnits():Members() do if Number(unit:GetProperty("LOTM_RESCUE_PHASE10_IS_MINION"),0)==1 then count=count+1; end end return count;
end

local function MaintainBoss(playerID)
 local boss=FindRole("BOSS"); if boss==nil then
  Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_PLOT",-1); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_UNIT",-1);
   if Number(Game.GetProperty("LOTM_RESCUE_PHASE10_DESCENT_TRIGGERED"),0)==1
    and Number(Game.GetProperty("LOTM_RESCUE_PHASE10_VICTORY"),0)~=1
    and BossSpawnCount()<BOSS_LIVES then SpawnBoss(); end
  return;
 end
 local bossPlot=Map.GetPlot(boss:GetX(),boss:GetY()); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_OWNER",boss:GetOwner()); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_UNIT",boss:GetID()); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_PLOT",bossPlot~=nil and bossPlot:GetIndex() or -1); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_X",boss:GetX()); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_Y",boss:GetY());
 local barbID=-1; for _,candidate in ipairs(PlayerManager.GetAliveBarbarians()) do barbID=candidate:GetID(); break; end
 if playerID~=boss:GetOwner() then return; end
 local _,tier=TierFor(Number(Game.GetProperty("LOTM_RESCUE_PHASE10_PURIFICATION_LOCKED"),0));
 local damage=Number(boss:GetDamage(),0); if damage>0 then boss:ChangeDamage(-math.min(tier.Heal,damage)); end
 PublishNetworkConfirmedDamage(boss);
 local turn=WorldTurn(); local last=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_LAST_SUMMON_TURN"),-1000000);
 if turn-last>=tier.Summon and CountMinions()<tier.Cap then
  local minion=Spawn(barbID,MINION_TYPE,"MINION",6);
  if minion~=nil then minion:SetProperty(GOD_PROPERTY,0); minion:SetProperty("LOTM_RESCUE_PHASE10_IS_MINION",1); Game.SetProperty("LOTM_RESCUE_PHASE10_LAST_SUMMON_TURN",turn); end
 end
end

local function PublishVictoryPresentation(reason)
 local humans=HumanPlayers();
 if #humans==0 then Log("victory presentation delayed reason=NO_HUMAN_PLAYER source="..tostring(reason)); return false; end
 local winningTeam=humans[1]:GetTeam();
 Game.SetProperty("LOTM_RESCUE_PHASE10_WINNING_TEAM",winningTeam);
 for _,player in ipairs(humans) do
  player:SetProperty("LOTM_RESCUE_PHASE10_VICTORY",1);
 end
 Game.SetProperty("LOTM_RESCUE_PHASE10_VICTORY_PRESENTATION_VERSION",VICTORY_PRESENTATION_VERSION);
 Log("victory presentation published reason="..tostring(reason).." winningTeam="..winningTeam.." humans="..#humans.." gameCoreConquest=false");
 return true;
end

local function GrantVictory()
 local first=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_VICTORY"),0)~=1;
 Game.SetProperty("LOTM_RESCUE_PHASE10_VICTORY",1); Game.SetProperty("LOTM_RESCUE_PHASE10_STATE","VICTORY");
 if first then Game.SetProperty("LOTM_RESCUE_PHASE10_VICTORY_TURN",WorldTurn()); end
 PublishVictoryPresentation(first and "GRANT" or "RECONCILE");
 Log("VICTORY bossDefeated=true worldTurn="..WorldTurn().." purification="..Number(Game.GetProperty("LOTM_RESCUE_PHASE10_PURIFICATION_LOCKED"),0));
end

local function ReconcileVictoryPresentation()
 if Number(Game.GetProperty("LOTM_RESCUE_PHASE10_VICTORY"),0)~=1 then return false; end
 return PublishVictoryPresentation("PRESENTATION_RECONCILE");
end

-- Resources before Phase 10 v30 could consume both Boss spawns while a late or
-- missing removal callback left the save outside the victory state.  A third
-- life would violate the two-life contract, so reconcile this exact old-save
-- terminal state once and award the already-earned victory.
local function MigrateExhaustedBossVictory()
 if Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_DEATH_RECOVERY_VERSION"),0)>=BOSS_DEATH_RECOVERY_VERSION then return false; end
 if Number(Game.GetProperty("LOTM_RESCUE_PHASE10_DESCENT_TRIGGERED"),0)~=1 then return false; end
 if Number(Game.GetProperty("LOTM_RESCUE_PHASE10_VICTORY"),0)==1 then
  Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_DEATH_RECOVERY_VERSION",BOSS_DEATH_RECOVERY_VERSION); return false;
 end
 local boss=FindRole("BOSS"); local spawnCount=BossSpawnCount();
 local defeatCount=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_DEFEAT_COUNT"),0);
 -- New saves carry the authoritative death counter.  For older saves, the
 -- already-proven exhausted-spawn state is the only recoverable evidence.
 local exhausted=(defeatCount>=BOSS_LIVES) or (defeatCount==0 and spawnCount>=BOSS_LIVES);
 if boss~=nil or not exhausted then
  Game.SetProperty("LOTM_RESCUE_PHASE10_EXHAUSTED_BOSS_RECOVERY_VERSION",EXHAUSTED_BOSS_RECOVERY_VERSION); return false;
 end
 Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_PHASES_REMAINING",0);
 Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_RESPAWN_PENDING",0);
 Game.SetProperty(RoleKey("BOSS","STATE"),"DEFEATED_MIGRATED");
  Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_DEATH_RECOVERY_VERSION",BOSS_DEATH_RECOVERY_VERSION);
  Game.SetProperty("LOTM_RESCUE_PHASE10_EXHAUSTED_BOSS_RECOVERY_VERSION",EXHAUSTED_BOSS_RECOVERY_VERSION);
 Log("legacy exhausted boss reconciled spawnCount="..spawnCount.." defeatCount="..defeatCount.." lives="..BOSS_LIVES.." action=GRANT_VICTORY");
 GrantVictory(); return true;
end

local function BeginDescent()
 if Number(Game.GetProperty("LOTM_RESCUE_PHASE10_DESCENT_TRIGGERED"),0)==1 then return true; end
 local center=CenterPlot(); if center==nil then Log("descent delayed reason=CENTER_MISSING"); return false; end
 local purification=Number(Game.GetProperty("GLOBAL_PURIFICATION"),0);
 local index,tier=PublishTier(purification);
 Game.SetProperty("LOTM_RESCUE_PHASE10_DESCENT_TRIGGERED",1); Game.SetProperty("LOTM_RESCUE_PHASE10_DESCENT_TURN",WorldTurn());
 Game.SetProperty("LOTM_RESCUE_PHASE10_SEAL_STATE","RELEASED"); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_PHASES_REMAINING",tier.Phases);
 Game.SetProperty("LOTM_RESCUE_PHASE10_STATE","FINAL_BATTLE"); Game.SetProperty("LOTM_RESCUE_PHASE",10);
 MigrateChurchGodOwnership(); MigrateChurchGodRespawns(); SpawnBoss(); MigrateBossPosition(); EnsureChurchGods(); for _,player in ipairs(HumanPlayers()) do EnsurePlayerGod(player); end RevealBattlefield(); GuideOuterGod(-1,true); GuideChurchGods(-1,true); MaintainBossVisibility();
 Log("DESCENT worldTurn="..WorldTurn().." finalTurn="..FinalTurn().." purification="..purification.." tier="..index.." center="..center:GetIndex());
 return true;
end

local function Refresh(playerID,isFirstTimeThisTurn)
 if not Active() or isFirstTimeThisTurn==false then return; end
 -- Single-player damage callbacks can precede or follow OnCombatOccurred.
 -- Network games never consume this local evidence.
 m_nativeDamageEvents={}; m_bossCombatEvents={};
 Game.SetProperty("LOTM_RESCUE_PHASE10_VERSION",VERSION); Game.SetProperty("LOTM_RESCUE_PHASE10_FINAL_TURN",FinalTurn()); Game.SetProperty("LOTM_RESCUE_PHASE10_BEST_TIER_THRESHOLD",BEST_TIER_THRESHOLD);
 Game.SetProperty("LOTM_RESCUE_PURIFICATION_DISPLAY_MAX",PURIFICATION_DISPLAY_MAX);
 for index=2,#TIERS do Game.SetProperty("LOTM_RESCUE_PHASE10_TIER_THRESHOLD_"..index,TIERS[index].Min); end
 if WorldTurn()>=FinalTurn() then BeginDescent(); end
 local existingBoss=FindRole("BOSS");
 if Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_EPOCH"),0)<=0 and existingBoss~=nil then
  local migratedEpoch=math.max(1,BossSpawnCount());
  Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_EPOCH",migratedEpoch);
  existingBoss:SetProperty("LOTM_RESCUE_PHASE10_BOSS_EPOCH",migratedEpoch);
  Log("boss epoch migrated epoch="..migratedEpoch.." reason=LEGACY_SAVE");
 elseif existingBoss~=nil and Number(existingBoss:GetProperty("LOTM_RESCUE_PHASE10_BOSS_EPOCH"),0)<=0 then
  existingBoss:SetProperty("LOTM_RESCUE_PHASE10_BOSS_EPOCH",BossEpoch());
 end
 PublishNetworkConfirmedDamage(existingBoss);
 MigrateExhaustedBossVictory();
 ReconcileVictoryPresentation();
 if Number(Game.GetProperty("LOTM_RESCUE_PHASE10_DESCENT_TRIGGERED"),0)==1 and Number(Game.GetProperty("LOTM_RESCUE_PHASE10_VICTORY"),0)~=1 then
  MigrateChurchGodOwnership(); MigrateChurchGodRespawns(); MigrateBossPosition(); EnsureChurchGods(); RevealBattlefield();
  local player=Players[playerID]; if player~=nil and player:IsHuman() then EnsurePlayerGod(player); end
  GuideOuterGod(playerID,false);
  GuideMinions(playerID,false);
  GuideChurchGods(playerID,false);
  FreezeIndependentGodAI(playerID);
  MaintainBoss(playerID);
  MaintainBossVisibility();
 end
end

ResolveBossDefeat=function(playerID,unitID,source,epoch)
 local key=playerID..":"..unitID;
 local resolvedEpoch=Number(epoch,BossEpoch());
 local lastEpoch=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_LAST_DEFEATED_EPOCH"),-1);
 if Number(Game.GetProperty("LOTM_RESCUE_PHASE10_VICTORY"),0)==1
  or (Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_LAST_DEFEATED_OWNER"),-1)==playerID
   and Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_LAST_DEFEATED_UNIT"),-1)==unitID
   and (lastEpoch==resolvedEpoch or lastEpoch<0)) then return; end
 Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_LAST_DEFEATED_OWNER",playerID); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_LAST_DEFEATED_UNIT",unitID);
 Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_LAST_DEFEATED_EPOCH",resolvedEpoch);
 local defeats=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_DEFEAT_COUNT"),0)+1;
 Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_DEFEAT_COUNT",defeats);
 local remaining=math.max(0,Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_PHASES_REMAINING"),1)-1);
 Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_PHASES_REMAINING",remaining);
 if remaining>0 then Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_RESPAWN_PENDING",1); Game.SetProperty(RoleKey("BOSS","STATE"),"PHASE_DEFEATED"); Log("boss phase defeated remaining="..remaining.." source="..source);
 else
  -- Use the established single-player victory finalizer after the second
  -- actual Boss death.  Multiplayer delivery is an optional outer layer;
  -- it must never decide whether the Boss was defeated.
  Log("boss defeat count="..defeats.." lives="..BOSS_LIVES.." action=GRANT_VICTORY");
  GrantVictory();
 end
 m_bossIntentionalDefeat[key]=nil;
end

local function CorrectNativeGodCombatDamage(key)
 local event=m_nativeDamageEvents[key]; local combat=m_bossCombatEvents[key]; if event==nil or combat==nil then return; end
 m_nativeDamageEvents[key]=nil; m_bossCombatEvents[key]=nil;
 local unit=UnitManager.GetUnit(combat.Player,combat.Unit);
 if unit==nil or unit:IsDead() or unit:IsDelayedDeath() then return; end
 if ProtectDescent(unit,"COMBAT_CORRECTION") then return; end
 -- Reject a stale heal/scripted-damage event.  The event paired with this
 -- combat must still describe the unit's current damage and must be damage.
 if event.New~=Number(unit:GetDamage(),0) or event.New<=event.Old then
  Log("god combat correction skipped role="..combat.Role.." unit="..key.." reason=STALE_OR_NON_DAMAGE_EVENT old="..event.Old.." new="..event.New.." current="..Number(unit:GetDamage(),0));
  return;
 end
 local observed=math.max(0,event.New-event.Old); local extra=math.max(0,combat.Desired-observed);
 if extra>0 then
  local maximum=Number(unit:GetMaxDamage(),100); local current=Number(unit:GetDamage(),0);
  if current+extra>=maximum then
   if combat.IsBoss then
    local applied=math.max(0,maximum-1-current);
    if applied>0 then m_nativeDamageCorrections[key]={Old=current,New=current+applied}; unit:ChangeDamage(applied); end
    KillBossAtTerminalDamage(unit,"NATIVE_GOD_COMBAT_CORRECTION");
   else
    pcall(UnitManager.Kill,unit);
   end
  else
   m_nativeDamageCorrections[key]={Old=current,New=current+extra}; unit:ChangeDamage(extra);
  end
 end
 Log("god combat damage correction role="..combat.Role.." unit="..key.." attack="..combat.Attack.." defense="..combat.Defense.." observed="..observed.." desired="..combat.Desired.." extra="..extra);
end

local function CorrectNetworkGodCombatDamage(unit,role,attack,defense,isBoss)
 if unit==nil or unit:IsDead() or unit:IsDelayedDeath() then return; end
 if ProtectDescent(unit,"COMBAT_CORRECTION") then return; end
 local playerID=unit:GetOwner(); local unitID=unit:GetID(); local key=UnitKey(playerID,unitID);
 local maximum=Number(unit:GetMaxDamage(),100); local current=Number(unit:GetDamage(),0);
 local desired=CombatStrengthDamage(attack,defense);
 -- A saturated custom result is lethal without needing any pre-combat damage
 -- baseline.  This restores a final god's intended kill against ordinary
 -- targets while keeping Boss deaths on the terminal-damage/epoch path below.
 if not isBoss and desired>=maximum then
  local ok,result=pcall(UnitManager.Kill,unit);
  Log("god combat synchronized saturated kill role="..role.." unit="..key.." attack="..attack.." defense="..defense.." desired="..desired.." max="..maximum.." ok="..tostring(ok).." result="..tostring(result));
  return;
 end
 -- Only the current Boss has a provably closed damage ledger here: every
 -- Phase-10 heal and scripted hit publishes a checkpoint.  Ordinary units and
 -- player/church gods can heal or take damage in other systems between fights,
 -- so their last checkpoint cannot be used as a pre-combat value without a
 -- stale-baseline overcorrection.
 if not isBoss then return; end
 local stored=unit:GetProperty(CONFIRMED_DAMAGE_PROPERTY);
 if stored==nil then
  PublishNetworkConfirmedDamage(unit);
  Log("god combat synchronized correction skipped role="..role.." unit="..key.." reason=CONFIRMED_DAMAGE_MISSING current="..current);
  return;
 end
 local confirmed=Number(stored,current);
 confirmed=math.max(0,math.min(maximum,confirmed));
 -- OnCombatOccurred is the synchronized owner of this path, but its ordering
 -- relative to the native damage publication is not assumed.  A non-positive
 -- delta is not evidence that native damage has landed, so fail closed instead
 -- of adding the full desired damage before the engine result.
 if current<=confirmed then
  PublishNetworkConfirmedDamage(unit);
  Log("god combat synchronized correction skipped role="..role.." unit="..key.." reason=NATIVE_DAMAGE_NOT_OBSERVED confirmed="..confirmed.." current="..current);
  return;
 end
 local observed=math.max(0,current-confirmed);
 local extra=math.max(0,desired-observed);
 if extra>0 then
  if current+extra>=maximum then
   if isBoss then
    local applied=math.max(0,maximum-1-current);
    if applied>0 then unit:ChangeDamage(applied); end
   else
    pcall(UnitManager.Kill,unit);
   end
  else
   unit:ChangeDamage(extra);
  end
 end
 PublishNetworkConfirmedDamage(UnitManager.GetUnit(playerID,unitID));
 Log("god combat synchronized correction role="..role.." unit="..key.." attack="..attack.." defense="..defense.." confirmed="..confirmed.." current="..current.." observed="..observed.." desired="..desired.." extra="..extra);
end

local function OnUnitDamageChanged(playerID,unitID,newDamage,oldDamage)
 if not Active() or Number(Game.GetProperty("LOTM_RESCUE_PHASE10_DESCENT_TRIGGERED"),0)~=1 then return; end
 if IsNetworkMultiplayer() then
  -- This event is locally published and is never evidence for network state.
  -- Synchronized OnCombatOccurred owns correction, checkpoints and Boss death.
  return;
 end
 local key=UnitKey(playerID,unitID); local newValue=Number(newDamage,0); local oldValue=Number(oldDamage,0);
 local correction=m_nativeDamageCorrections[key];
 if correction~=nil and correction.Old==oldValue and correction.New==newValue then
  m_nativeDamageCorrections[key]=nil;
  local bossOwner=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_OWNER"),-1); local bossUnit=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_UNIT"),-1);
  if playerID==bossOwner and unitID==bossUnit then KillBossAtTerminalDamage(UnitManager.GetUnit(playerID,unitID),"DAMAGE_EVENT"); end
  return;
 end
 if correction~=nil then m_nativeDamageCorrections[key]=nil; end
 m_nativeDamageEvents[key]={New=newValue,Old=oldValue}; CorrectNativeGodCombatDamage(key);
 local bossOwner=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_OWNER"),-1); local bossUnit=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_UNIT"),-1);
 if playerID==bossOwner and unitID==bossUnit then KillBossAtTerminalDamage(UnitManager.GetUnit(playerID,unitID),"DAMAGE_EVENT_TERMINAL"); end
end

local function OnCombat(attackerPlayerID,attackerUnitID,defenderPlayerID,defenderUnitID)
 if not Active() then return; end
 local networkGame=IsNetworkMultiplayer();
 local bossOwner=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_OWNER"),-1); local bossUnit=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_UNIT"),-1);
 local attacker=UnitManager.GetUnit(attackerPlayerID,attackerUnitID); local defender=UnitManager.GetUnit(defenderPlayerID,defenderUnitID);
 if attacker~=nil and defender~=nil and (IsGod(attacker) or IsGod(defender)) then
  local attack=EffectiveAttackStrength(attacker,0); local defense=EffectiveCombatStrength(defender,0);
  local ranged=math.max(Number(attacker:GetRangedCombat(),0),Number(attacker:GetBombardCombat(),0))>0;
  if networkGame then
   local retaliation=EffectiveCombatStrength(defender,0); local attackerDefense=EffectiveCombatStrength(attacker,0);
   local defenderIsBoss=defenderPlayerID==bossOwner and defenderUnitID==bossUnit;
   local attackerIsBoss=attackerPlayerID==bossOwner and attackerUnitID==bossUnit;
   if defenderIsBoss or IsGod(attacker) then CorrectNetworkGodCombatDamage(defender,"DEFENDER",attack,defense,defenderIsBoss); end
   if not ranged and (attackerIsBoss or IsGod(defender)) then CorrectNetworkGodCombatDamage(attacker,"ATTACKER_RETALIATION",retaliation,attackerDefense,attackerIsBoss); end
  else
   local defenderKey=UnitKey(defenderPlayerID,defenderUnitID);
   m_bossCombatEvents[defenderKey]={Player=defenderPlayerID,Unit=defenderUnitID,Role="DEFENDER",Attack=attack,Defense=defense,Desired=CombatStrengthDamage(attack,defense),IsBoss=defenderPlayerID==bossOwner and defenderUnitID==bossUnit};
   CorrectNativeGodCombatDamage(defenderKey);
   if not ranged then
    local retaliation=EffectiveCombatStrength(defender,0); local attackerDefense=EffectiveCombatStrength(attacker,0); local attackerKey=UnitKey(attackerPlayerID,attackerUnitID);
    m_bossCombatEvents[attackerKey]={Player=attackerPlayerID,Unit=attackerUnitID,Role="ATTACKER_RETALIATION",Attack=retaliation,Defense=attackerDefense,Desired=CombatStrengthDamage(retaliation,attackerDefense),IsBoss=attackerPlayerID==bossOwner and attackerUnitID==bossUnit};
    CorrectNativeGodCombatDamage(attackerKey);
   end
  end
 end
 if (attackerPlayerID==bossOwner and attackerUnitID==bossUnit) or (defenderPlayerID==bossOwner and defenderUnitID==bossUnit) then
  local epoch=BossEpoch(); local boss=UnitManager.GetUnit(bossOwner,bossUnit); local resolved=false;
  if networkGame and boss~=nil and not boss:IsDead() and not boss:IsDelayedDeath() then
   local killed=KillBossAtTerminalDamage(boss,"SYNCHRONIZED_COMBAT");
   if killed and ResolveBossDefeat~=nil then ResolveBossDefeat(bossOwner,bossUnit,"SYNCHRONIZED_COMBAT",epoch); end
   resolved=killed;
   boss=UnitManager.GetUnit(bossOwner,bossUnit);
  end
  if not resolved and (boss==nil or boss:IsDead() or boss:IsDelayedDeath()) then ResolveBossDefeat(bossOwner,bossUnit,networkGame and "SYNCHRONIZED_COMBAT" or "COMBAT",epoch); end
 end
end

local function ApplyRemoved(playerID,unitID,role,intentionalDefeat,epoch)
 local cached=m_roleUnits[role];
 if cached~=nil and cached:GetOwner()==playerID and cached:GetID()==unitID then m_roleUnits[role]=nil; end
 if role=="MINION" then Game.SetProperty(EngineKey(playerID,unitID),nil); return; end
 local currentRoleMatches=not IsNetworkMultiplayer()
  or (Number(Game.GetProperty(RoleKey(role,"OWNER")),-1)==playerID
   and Number(Game.GetProperty(RoleKey(role,"UNIT")),-1)==unitID
   and (role~="BOSS" or Number(epoch,BossEpoch())==BossEpoch()));
 if currentRoleMatches then Game.SetProperty(EngineKey(playerID,unitID),nil); end
 if currentRoleMatches then
  if ChurchGodMeta(role)~=nil then
   if Game.GetProperty(RoleKey(role,"STATE"))~="RESPAWN_PENDING" then ScheduleChurchGodRespawn(role); end
  elseif PlayerGodIDFromRole(role)~=nil then
   local used=Number(Game.GetProperty(RoleKey(role,"RESPAWN_USED")),0);
   if used>=1 then
    Game.SetProperty(RoleKey(role,"STATE"),"DEAD"); Game.SetProperty(RoleKey(role,"RESPAWN_TURN"),nil);
    Log("player god permanently destroyed role="..role.." turn="..WorldTurn());
   else
    local due=WorldTurn()+PLAYER_GOD_RESPAWN_DELAY;
    Game.SetProperty(RoleKey(role,"STATE"),"RESPAWN_PENDING"); Game.SetProperty(RoleKey(role,"RESPAWN_TURN"),due);
    Log("player god respawn scheduled role="..role.." deathTurn="..WorldTurn().." respawnTurn="..due.." remaining=1");
   end
  else Game.SetProperty(RoleKey(role,"STATE"),"DEAD"); end
 end
  if role=="BOSS" and Number(Game.GetProperty("LOTM_RESCUE_PHASE10_VICTORY"),0)~=1 then
  local key=playerID..":"..unitID;
  local resolvedEpoch=Number(epoch,BossEpoch());
  local alreadyResolved=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_LAST_DEFEATED_OWNER"),-1)==playerID
   and Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_LAST_DEFEATED_UNIT"),-1)==unitID
   and Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_LAST_DEFEATED_EPOCH"),-1)==resolvedEpoch;
  -- A Boss removed from the map is a valid phase defeat.  Older logic treated
  -- a missed/late combat callback as abnormal removal, leaving phases stuck
  -- forever after the player visibly killed the Boss twice.
  ResolveBossDefeat(playerID,unitID,(intentionalDefeat==true or m_bossIntentionalDefeat[key]) and "ALLIED_SIEGE" or (alreadyResolved and "COMBAT_ALREADY_RESOLVED" or "COMBAT_REMOVAL"),epoch);
  elseif ChurchGodMeta(role)==nil then Log("god removed role="..role.." owner="..playerID.." unit="..unitID); end
   if role=="BOSS" and currentRoleMatches then MaintainBossVisibility(); end
end

local function OnRemoved(playerID,unitID)
 if not Active() then return; end
 local role=tostring(Game.GetProperty(EngineKey(playerID,unitID)) or ""); if role=="" then return; end
 if IsNetworkMultiplayer() then QueueNetworkRemoval(playerID,unitID,role); return; end
 ApplyRemoved(playerID,unitID,role,false,nil);
end

local function ProcessNetworkRemovals(playerID)
 if not IsNetworkMultiplayer() or not LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID) then return; end
 local currentTurn=Game.GetCurrentGameTurn(); local ready={}; local waiting={};
 for _,entry in ipairs(m_pendingNetworkRemovals) do
  if entry.QueuedTurn<currentTurn then ready[#ready+1]=entry; else waiting[#waiting+1]=entry; end
 end
 m_pendingNetworkRemovals=waiting;
 table.sort(ready,function(a,b)
  if a.QueuedTurn~=b.QueuedTurn then return a.QueuedTurn<b.QueuedTurn; end
  if a.PlayerID~=b.PlayerID then return a.PlayerID<b.PlayerID; end
  if a.UnitID~=b.UnitID then return a.UnitID<b.UnitID; end
  return a.Role<b.Role;
 end);
 for _,entry in ipairs(ready) do
  m_pendingNetworkRemovalKeys[entry.Key]=nil;
  local unit=UnitManager.GetUnit(entry.PlayerID,entry.UnitID); local liveRole=tostring(Game.GetProperty(EngineKey(entry.PlayerID,entry.UnitID)) or "");
  local staleBossEpoch=entry.Role=="BOSS" and entry.Epoch<BossEpoch();
  if (unit==nil or unit:IsDead() or unit:IsDelayedDeath() or staleBossEpoch) and (liveRole=="" or liveRole==entry.Role) then
   ApplyRemoved(entry.PlayerID,entry.UnitID,entry.Role,entry.Intentional,entry.Epoch);
  else
   Log("deferred removal discarded player="..entry.PlayerID.." unit="..entry.UnitID.." role="..entry.Role.." liveRole="..liveRole);
  end
 end
end

local function OnUnitMoveComplete(playerID,unitID,x,y)
 if IsNetworkMultiplayer() then return; end
 if not Active() or Number(Game.GetProperty("LOTM_RESCUE_PHASE10_DESCENT_TRIGGERED"),0)~=1 then return; end
 if playerID==Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_OWNER"),-1)
  and unitID==Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_UNIT"),-1) then MaintainBossVisibility(); end
end

local function OnSynchronizedRefresh(playerID,isFirstTimeThisTurn)
 if IsNetworkMultiplayer() and isFirstTimeThisTurn~=false and LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID) then
  ProcessNetworkRemovals(playerID);
 end
 Refresh(playerID,isFirstTimeThisTurn);
end

LOTM_MP_TurnSync.Add(OnSynchronizedRefresh,"RescuePhase10");
Events.UnitRemovedFromMap.Add(OnRemoved);
Events.UnitMoveComplete.Add(OnUnitMoveComplete);
Events.UnitDamageChanged.Add(OnUnitDamageChanged);
GameEvents.OnCombatOccurred.Add(OnCombat);
LOTM_MP_TurnSync.RunStartup(function()
 if Active() then
  Game.SetProperty("LOTM_RESCUE_PHASE10_VERSION",VERSION); Game.SetProperty("LOTM_RESCUE_PHASE10_FINAL_TURN",FinalTurn()); Game.SetProperty("LOTM_RESCUE_PHASE10_BEST_TIER_THRESHOLD",BEST_TIER_THRESHOLD);
  Game.SetProperty("LOTM_RESCUE_PURIFICATION_DISPLAY_MAX",PURIFICATION_DISPLAY_MAX);
  for index=2,#TIERS do Game.SetProperty("LOTM_RESCUE_PHASE10_TIER_THRESHOLD_"..index,TIERS[index].Min); end
  if WorldTurn()>=FinalTurn() then
   BeginDescent();
   MigrateExhaustedBossVictory();
   ReconcileVictoryPresentation();
   if Number(Game.GetProperty("LOTM_RESCUE_PHASE10_DESCENT_TRIGGERED"),0)==1 and Number(Game.GetProperty("LOTM_RESCUE_PHASE10_VICTORY"),0)~=1 then
    MigrateChurchGodOwnership(); MigrateChurchGodRespawns(); local startupBoss=FindRole("BOSS"); if startupBoss==nil then startupBoss=SpawnBoss(); end PublishNetworkConfirmedDamage(startupBoss); MigrateBossPosition(); EnsureChurchGods(); for _,player in ipairs(HumanPlayers()) do EnsurePlayerGod(player); end RevealBattlefield(); GuideOuterGod(-1,true); GuideMinions(-1,true); GuideChurchGods(-1,true); MaintainBossVisibility();
   end
  end
 end
end,"RescuePhase10");
Log("loaded version="..VERSION.." finalTurns=costMultiplierScaled standard=150 tiers=0/500/1000/1500/2000/3000 strengths=999/888/777/666/555/444 playerGodBase=550 divineLegion=basePlusWarGodRelicOneTenth playerGodMobility=runtimeCombatAbove1000:+30 displayMax=3000 churchGodOwner=freeCities churchGodRespawn=5turnsOnce:v1 playerGodRespawn=5turnsOnce:v1 bossOwner=barbarianThenFreeCitiesFallback bossTargets=churchGodsCombatDamageThenNearestUnprotectedCity alliedSiege=humanTurn:v4 battlefieldReveal=6:v2 bossSight=radius6:persistent:v2 bossPosition=firstOrSecondRing:v5 spawnCommit=verifiedCandidateIteration exhaustedBossRecovery=v1 strength=binaryExact victory=rescuePropertyToFiraxisEndGameUI nativeConquestDisabled");
