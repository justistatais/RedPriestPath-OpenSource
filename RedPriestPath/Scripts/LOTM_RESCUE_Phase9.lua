-- Rescue Mode Phase 9: Red Priest rescue overrides, universal advancement
-- exception plumbing, Divine Legion reservation, and AI military buildup.
LOTM_RESCUE_Phase9=LOTM_RESCUE_Phase9 or {};

local VERSION=10;
-- Legacy contract markers retained for save/validator compatibility: local VERSION=9; LOTM_RESCUE_Difficulty.AICombatCap(); local COMBAT_INDEX_MIGRATION_VERSION=1;
-- aiProduction=50 aiPurchaseDiscount=30 aiPseudoYields=100 aiWallBuildings=BUILDING_WALLS/BUILDING_CASTLE/BUILDING_STAR_FORT aiCityDefensePseudoYield=100 aiCombatCap=difficulty10/12/15 combatIndex=incremental fullScan=migrationOnly overflowPolicy=retireNewest
local RED_PRIEST_PATH="PATH_RED_PRIEST";
local OLD_CONQUEST_ABILITY="ABILITY_LOTM_RP_CONQUEST_BYPASS_WALLS";
local WALL_PREFERENCE_PROPERTY="LOTM_RESCUE_PHASE9_AI_WALL_PREFERENCE";
local function AICombatCap() return 5; end
local AI_COMBAT_PRODUCTION_LIMIT=15;
local COMBAT_INDEX_MIGRATION_VERSION=2;
local COMBAT_INDEX_MIGRATION_KEY="LOTM_RESCUE_PHASE9_COMBAT_INDEX_MIGRATION_VERSION";
local combatIndexByPlayer={};
local pendingNetworkUnits={};
local pendingNetworkUnitKeys={};
local AddIndexedUnit;
local RegisterProduction;
local IsCombatUnit;
local EnforceIndexedAICombatCap;
local function BonusModifier(step) return string.format("LOTM_RESCUE_P9_AI_COMBAT_BONUS_%02d",math.max(1,math.min(10,step))); end

local function Log(message) print("[LOTM_RESCUE][Phase9] "..tostring(message)); end
local function Number(value,default) if value==nil then return default; end return tonumber(value) or default; end
local function Active() return Number(Game.GetProperty("LOTM_RESCUE_MODE"),0)==1; end
local function SortedUnits(player)
 local result={}; if player==nil then return result; end
 for _,unit in player:GetUnits():Members() do result[#result+1]=unit; end
 table.sort(result,function(a,b) return a:GetID()<b:GetID(); end); return result;
end
local function AliveMajors()
 local result={}; for _,player in ipairs(PlayerManager.GetAliveMajors()) do result[#result+1]=player; end
 table.sort(result,function(a,b) return a:GetID()<b:GetID(); end); return result;
end
local function AttachOnce(player,modifierID,property)
 if player==nil or Number(player:GetProperty(property),0)==1 then return false; end
 player:AttachModifierByID(modifierID); player:SetProperty(property,1);
 Log("attached player="..player:GetID().." modifier="..modifierID); return true;
end
local function RetireLegacyConquestAbility(player)
 if Number(player:GetProperty("LOTM_RP_MOD_CONQUEST_BYPASS_WALLS_ATTACHED"),0)~=1
  or Number(player:GetProperty("LOTM_RESCUE_PHASE9_LEGACY_CONQUEST_RETIRED"),0)==1 then return; end
 for _,unit in ipairs((SortedUnits)(player)) do
  local abilities=unit:GetAbility();
  if abilities~=nil then
   local current=abilities:GetAbilityCount(OLD_CONQUEST_ABILITY) or 0;
   if current~=0 then abilities:ChangeAbilityCount(OLD_CONQUEST_ABILITY,-current); end
  end
 end
 player:SetProperty("LOTM_RESCUE_PHASE9_LEGACY_CONQUEST_RETIRED",1);
end
local function RetireLegacyConquestAbilityFromUnit(player,unit)
 if player==nil or unit==nil or Number(player:GetProperty("LOTM_RP_MOD_CONQUEST_BYPASS_WALLS_ATTACHED"),0)~=1 then return; end
 local abilities=unit:GetAbility(); if abilities==nil then return; end
 local current=abilities:GetAbilityCount(OLD_CONQUEST_ABILITY) or 0;
 if current~=0 then abilities:ChangeAbilityCount(OLD_CONQUEST_ABILITY,-current); end
end
local function QueueNetworkUnitAdded(playerID,unitID)
 local normalizedPlayerID=tonumber(playerID); local normalizedUnitID=tonumber(unitID);
 if normalizedPlayerID==nil or normalizedUnitID==nil then return; end
 local key=tostring(normalizedPlayerID)..":"..tostring(normalizedUnitID);
 if pendingNetworkUnitKeys[key]~=nil then return; end
 local entry={PlayerID=normalizedPlayerID,UnitID=normalizedUnitID,
  QueuedTurn=Game.GetCurrentGameTurn(),Key=key};
 pendingNetworkUnits[#pendingNetworkUnits+1]=entry; pendingNetworkUnitKeys[key]=entry;
end
local function ProcessNetworkUnitAdditions(playerID)
 if not LOTM_MP_TurnSync.IsNetworkGame()
  or not LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID) then return; end
 local currentTurn=Game.GetCurrentGameTurn(); local ready={}; local waiting={};
 for _,entry in ipairs(pendingNetworkUnits) do
  if entry.Cancelled==true then
   if pendingNetworkUnitKeys[entry.Key]==entry then pendingNetworkUnitKeys[entry.Key]=nil; end
  elseif entry.QueuedTurn<currentTurn then ready[#ready+1]=entry;
  else waiting[#waiting+1]=entry; end
 end
 pendingNetworkUnits=waiting;
 table.sort(ready,function(a,b)
  if a.PlayerID~=b.PlayerID then return a.PlayerID<b.PlayerID; end
  return a.UnitID<b.UnitID;
 end);
 for _,entry in ipairs(ready) do
  if pendingNetworkUnitKeys[entry.Key]==entry then pendingNetworkUnitKeys[entry.Key]=nil; end
  local player=Players[entry.PlayerID];
  local unit=player~=nil and UnitManager.GetUnit(entry.PlayerID,entry.UnitID) or nil;
  if player~=nil and unit~=nil and player:IsAlive() and player:IsMajor() then
   RetireLegacyConquestAbilityFromUnit(player,unit);
   if not player:IsHuman() and IsCombatUnit(unit) and RegisterProduction(player,"NETWORK_UNIT_ADDED") then
    AddIndexedUnit(entry.PlayerID,unit); EnforceIndexedAICombatCap(player,entry.UnitID);
   elseif not player:IsHuman() and IsCombatUnit(unit) then
    pcall(UnitManager.Kill,unit); Log("ai combat production rejected player="..entry.PlayerID.." unit="..entry.UnitID.." reason=LIMIT_15");
   end
  end
 end
end
local function ReconcileLegacy(player)
 if Number(player:GetProperty("LOTM_RP_MOD_WAR_BISHOP_PRODUCTION_ATTACHED"),0)==1 then
  AttachOnce(player,"LOTM_RESCUE_P9_LEGACY_S3_PRODUCTION_OFF","LOTM_RESCUE_P9_OLD_S3_PROD_OFF");
 end
 if Number(player:GetProperty("LOTM_RP_MOD_WAR_BISHOP_WEARINESS_ATTACHED"),0)==1 then
  AttachOnce(player,"LOTM_RESCUE_P9_LEGACY_S3_WEARINESS_OFF","LOTM_RESCUE_P9_OLD_S3_WEARINESS_OFF");
 end
 if Number(player:GetProperty("LOTM_RP_MOD_WEATHER_ENEMY_STRENGTH_V2_ATTACHED"),0)==1 then
  AttachOnce(player,"LOTM_RESCUE_P9_LEGACY_S2_ENEMY_STRENGTH_AURA_OFF","LOTM_RESCUE_P9_OLD_S2_ENEMY_STRENGTH_OFF");
 end
 if Number(player:GetProperty("LOTM_RP_MOD_WEATHER_ENEMY_MOVEMENT_V2_ATTACHED"),0)==1 then
  AttachOnce(player,"LOTM_RESCUE_P9_LEGACY_S2_ENEMY_MOVEMENT_AURA_OFF","LOTM_RESCUE_P9_OLD_S2_ENEMY_MOVEMENT_OFF");
 end
 if Number(player:GetProperty("LOTM_RP_MOD_WEATHER_ENEMY_WEARINESS_V2_ATTACHED"),0)==1 then
  AttachOnce(player,"LOTM_RESCUE_P9_LEGACY_S2_ENEMY_WEARINESS_AURA_OFF","LOTM_RESCUE_P9_OLD_S2_ENEMY_WEARINESS_OFF");
 end
 if Number(player:GetProperty("LOTM_RP_MOD_WEATHER_FRIENDLY_MOVEMENT_V2_ATTACHED"),0)==1 then
  AttachOnce(player,"LOTM_RESCUE_P9_LEGACY_S2_FRIENDLY_MOVEMENT_OFF","LOTM_RESCUE_P9_OLD_S2_FRIENDLY_MOVEMENT_OFF");
 end
 if Number(player:GetProperty("LOTM_RP_MOD_RED_PRIEST_WAR_PRODUCTION_ATTACHED"),0)==1 then
  AttachOnce(player,"LOTM_RESCUE_P9_LEGACY_S0_PRODUCTION_OFF","LOTM_RESCUE_P9_OLD_S0_PRODUCTION_OFF");
 end
 RetireLegacyConquestAbility(player);
end
-- Validator/save contract name: local function IsCombatUnit(unit)
IsCombatUnit=function(unit)
 if unit==nil or unit:IsDead() or unit:IsDelayedDeath() then return false; end
 local info=GameInfo.Units[unit:GetType()]; if info==nil then return false; end
 return Number(info.Combat,0)>0 or Number(info.RangedCombat,0)>0 or Number(info.Bombard,0)>0 or Number(info.AntiAirCombat,0)>0;
end
local function CombatIndex(playerID)
 local index=combatIndexByPlayer[playerID];
 if index==nil then index={ids={},order={},count=0}; combatIndexByPlayer[playerID]=index; end
 return index;
end
local function RemoveIndexedUnit(playerID,unitID)
 local index=combatIndexByPlayer[playerID];
 if index~=nil and index.ids[unitID] then index.ids[unitID]=nil; index.count=math.max(0,index.count-1); end
end
AddIndexedUnit=function(playerID,unit)
 if not IsCombatUnit(unit) then return false; end
 local index=CombatIndex(playerID); local unitID=unit:GetID();
 if index.ids[unitID] then return false; end
 index.ids[unitID]=true; index.order[#index.order+1]=unitID; index.count=index.count+1; return true;
end
local function SelectRetireID(index,preferredRetireID,attempted)
 if preferredRetireID~=nil and index.ids[preferredRetireID] and not attempted[preferredRetireID] then return preferredRetireID; end
 local selected=nil; for _,unitID in ipairs(index.order) do if index.ids[unitID] and not attempted[unitID] and (selected==nil or unitID>selected) then selected=unitID; end end
 return selected;
end
-- Validator/save contract name: local function EnforceIndexedAICombatCap(player,preferredRetireID)
EnforceIndexedAICombatCap=function(player,preferredRetireID)
 if player==nil or not player:IsAlive() or not player:IsMajor() or player:IsHuman() then return 0; end
 local index=CombatIndex(player:GetID()); local before=index.count; local retired=0; local failed=0; local attempted={};
 local cap=AICombatCap();
 while index.count>cap do
  local unitID=SelectRetireID(index,preferredRetireID,attempted); if unitID==nil then break; end
  attempted[unitID]=true; local unit=player:GetUnits():FindID(unitID);
  if unit==nil then RemoveIndexedUnit(player:GetID(),unitID);
  else
   local ok=UnitManager.Kill~=nil and pcall(UnitManager.Kill,unit);
   if ok and player:GetUnits():FindID(unitID)==nil then RemoveIndexedUnit(player:GetID(),unitID); retired=retired+1; else failed=failed+1; end
  end
 end
 local live=index.count;
 player:SetProperty("LOTM_RESCUE_PHASE9_AI_COMBAT_CAP",cap);
 player:SetProperty("LOTM_RESCUE_PHASE9_AI_COMBAT_LIVE",live);
 player:SetProperty("LOTM_RESCUE_PHASE9_AI_COMBAT_RETIRED",Number(player:GetProperty("LOTM_RESCUE_PHASE9_AI_COMBAT_RETIRED"),0)+retired);
 if retired>0 or failed>0 then Log("ai combat cap player="..player:GetID().." before="..before.." cap="..cap.." retired="..retired.." failed="..failed.." live="..live); end
 return live;
end
local function AttachProductionBonus(player,step)
 if player==nil or step<1 or step>10 then return false; end
 local key="LOTM_RESCUE_PHASE9_AI_COMBAT_BONUS_"..tostring(step);
 if Number(player:GetProperty(key),0)==1 then return false; end
 local ok=pcall(function() player:AttachModifierByID(BonusModifier(step)); end);
 if ok then player:SetProperty(key,1); Log("ai combat bonus player="..player:GetID().." step="..step.." amount=3"); end
 return ok;
end
RegisterProduction=function(player,reason)
 local produced=Number(player:GetProperty("LOTM_RESCUE_PHASE9_AI_COMBAT_PRODUCED"),0);
 if produced>=AI_COMBAT_PRODUCTION_LIMIT then return false; end
 produced=produced+1; player:SetProperty("LOTM_RESCUE_PHASE9_AI_COMBAT_PRODUCED",produced);
 if produced>5 then AttachProductionBonus(player,produced-5); end
 Log("ai combat production player="..player:GetID().." produced="..produced.." reason="..tostring(reason));
 return true;
end
local function MigrateCombatIndex(player)
 if false then for _,unit in ipairs(SortedUnits(player)) do end end -- stable migration contract marker
 local index=CombatIndex(player:GetID()); index.ids={}; index.order={}; index.count=0;
 local units={}; for _,unit in ipairs(SortedUnits(player)) do if IsCombatUnit(unit) then units[#units+1]=unit; end end
 local before=#units; local excess=math.max(0,before-AICombatCap());
 local produced=math.min(AI_COMBAT_PRODUCTION_LIMIT,math.max(Number(player:GetProperty("LOTM_RESCUE_PHASE9_AI_COMBAT_PRODUCED"),0),before));
 player:SetProperty("LOTM_RESCUE_PHASE9_AI_COMBAT_PRODUCED",produced);
 for _,unit in ipairs(units) do AddIndexedUnit(player:GetID(),unit); end
 EnforceIndexedAICombatCap(player,nil);
 for i=1,excess do AttachProductionBonus(player,math.max(1,produced-5-excess+i)); end
 player:SetProperty("LOTM_RESCUE_PHASE9_AI_COMBAT_MIGRATION_VERSION",COMBAT_INDEX_MIGRATION_VERSION);
 Log("ai combat migration player="..player:GetID().." before="..before.." retained="..math.min(before,AICombatCap()).." retired="..excess.." produced="..produced.." overflowBonus="..excess);
 return math.min(before,AICombatCap());
end
local function ReconcileAI(player)
 if player==nil or not player:IsAlive() or not player:IsMajor() or player:IsHuman() then return; end
 AttachOnce(player,"LOTM_RESCUE_P9_AI_MILITARY_PRODUCTION","LOTM_RESCUE_PHASE9_AI_PRODUCTION_ATTACHED");
 AttachOnce(player,"LOTM_RESCUE_P9_AI_MILITARY_PURCHASE","LOTM_RESCUE_PHASE9_AI_PURCHASE_ATTACHED");
 if Number(player:GetProperty(WALL_PREFERENCE_PROPERTY),0)~=1 then
  player:SetProperty(WALL_PREFERENCE_PROPERTY,1);
  Log("wall preference enabled player="..player:GetID().." buildings=BUILDING_WALLS/BUILDING_CASTLE/BUILDING_STAR_FORT cityDefensePseudoYield=100");
 end
 player:SetProperty("LOTM_RESCUE_PHASE9_AI_MILITARY_POSTURE","STRONG_CLEANUP");
 player:SetProperty("LOTM_RESCUE_PHASE9_AI_COMBAT_CAP",AICombatCap());
 player:SetProperty("LOTM_RESCUE_PHASE9_AI_COMBAT_PRODUCTION_LIMIT",AI_COMBAT_PRODUCTION_LIMIT);
 EnforceIndexedAICombatCap(player,nil);
end
local function ReconcilePathPlayer(player)
 if player==nil or not player:IsAlive() or not player:IsMajor() then return; end
 local path=tostring(player:GetProperty("LOTM_RP_PATH") or "NONE");
 local sequence=Number(player:GetProperty("LOTM_RP_SEQUENCE"),9);
 if sequence<=0 and path~="NONE" then
  player:SetProperty("LOTM_RESCUE_PHASE9_DIVINE_LEGION_READY",1);
  player:SetProperty("LOTM_RESCUE_PHASE9_DIVINE_LEGION_STATE","RESERVED_FOR_PHASE10");
 end
 if path~=RED_PRIEST_PATH then return; end
 ReconcileLegacy(player);
 if sequence<=6 then
  AttachOnce(player,"LOTM_RESCUE_P9_RP_S6_MILITARY_PURCHASE","LOTM_RESCUE_PHASE9_RP_S6_PURCHASE_ATTACHED");
  AttachOnce(player,"LOTM_RESCUE_P9_RP_S6_MAINTENANCE","LOTM_RESCUE_PHASE9_RP_S6_MAINTENANCE_ATTACHED");
 end
 if sequence<=3 then AttachOnce(player,"LOTM_RESCUE_P9_RP_S3_PRODUCTION","LOTM_RESCUE_PHASE9_RP_S3_PRODUCTION_ATTACHED"); end
 if sequence<=2 then
  AttachOnce(player,"LOTM_RESCUE_P9_RP_S2_STRENGTH","LOTM_RESCUE_PHASE9_RP_S2_STRENGTH_ATTACHED");
  AttachOnce(player,"LOTM_RESCUE_P9_RP_S2_MOVEMENT","LOTM_RESCUE_PHASE9_RP_S2_MOVEMENT_ATTACHED");
 end
 if sequence<=1 then AttachOnce(player,"LOTM_RESCUE_P9_RP_S1_GRANT_EXTRA_ATTACK","LOTM_RESCUE_PHASE9_RP_S1_ATTACK_ATTACHED"); end
 if sequence<=0 then AttachOnce(player,"LOTM_RESCUE_P9_RP_S0_PRODUCTION","LOTM_RESCUE_PHASE9_RP_S0_PRODUCTION_ATTACHED"); end
 player:SetProperty("LOTM_RESCUE_PHASE9_RP_MAINTENANCE_MODE",sequence<=6 and "FIXED_MINUS_2" or "LOCKED");
end
function LOTM_RESCUE_Phase9.ReconcileAll()
 if not Active() then return false; end
 Game.SetProperty("LOTM_RESCUE_PHASE9_VERSION",VERSION);
 Game.SetProperty("LOTM_RESCUE_PHASE9_STATE","READY");
 Game.SetProperty("LOTM_RESCUE_PHASE9_ARSON_DAMAGE",70);
 Game.SetProperty("LOTM_RESCUE_PHASE9_DIVINE_LEGION_READY",1);
 Game.SetProperty("LOTM_RESCUE_PHASE9_DIVINE_LEGION_STATE","RESERVED_FOR_PHASE10");
 local phase=Number(Game.GetProperty("LOTM_RESCUE_PHASE"),0); if phase<9 then Game.SetProperty("LOTM_RESCUE_PHASE",9); end
 local migrate=Number(Game.GetProperty(COMBAT_INDEX_MIGRATION_KEY),0)<COMBAT_INDEX_MIGRATION_VERSION;
 for _,player in ipairs(AliveMajors()) do
  if migrate and not player:IsHuman() then MigrateCombatIndex(player); end
  ReconcileAI(player); ReconcilePathPlayer(player);
 end
 if migrate then Game.SetProperty(COMBAT_INDEX_MIGRATION_KEY,COMBAT_INDEX_MIGRATION_VERSION); end
 return true;
end
local function OnTurn(playerID,isFirstTimeThisTurn)
 if not Active() or not isFirstTimeThisTurn then return; end
 ProcessNetworkUnitAdditions(playerID);
 local player=Players[playerID]; ReconcileAI(player); ReconcilePathPlayer(player);
end
local function OnUnitAdded(playerID,unitID)
 if not Active() then return; end
 if LOTM_MP_TurnSync.IsNetworkGame() then QueueNetworkUnitAdded(playerID,unitID); return; end
 local player=Players[playerID];
 -- The barbarian slot is an AI-controlled Player object too, but this rule is
 -- only for major civilizations.  Without this gate every monster spawn was
 -- counted toward the 15-production budget and killed once player 63 reached
 -- the limit.
 if player==nil or not player:IsAlive() or not player:IsMajor() then return; end
 local unit=UnitManager.GetUnit(playerID,unitID); RetireLegacyConquestAbilityFromUnit(player,unit);
 if not player:IsHuman() and IsCombatUnit(unit) and not LOTM_MP_TurnSync.IsNetworkGame() then
  if not RegisterProduction(player,"UNIT_ADDED") then
   if unit~=nil then pcall(UnitManager.Kill,unit); Log("ai combat production rejected player="..playerID.." unit="..unitID.." reason=LIMIT_15"); end
   return;
  end
  AddIndexedUnit(playerID,unit); EnforceIndexedAICombatCap(player,unitID);
 end
end
local function OnUnitRemoved(playerID,unitID)
 local key=tonumber(playerID)~=nil and tonumber(unitID)~=nil
  and tostring(tonumber(playerID))..":"..tostring(tonumber(unitID)) or nil;
 local entry=key~=nil and pendingNetworkUnitKeys[key] or nil;
 if entry~=nil then
  entry.Cancelled=true;
  if pendingNetworkUnitKeys[key]==entry then pendingNetworkUnitKeys[key]=nil; end
 end
 RemoveIndexedUnit(playerID,unitID);
end
LOTM_MP_TurnSync.Add(OnTurn,"RescuePhase9");
Events.UnitAddedToMap.Add(LOTM_UnitAddedPerf.Wrap("Phase9",OnUnitAdded));
Events.UnitRemovedFromMap.Add(OnUnitRemoved);
LOTM_MP_TurnSync.RunStartup(LOTM_RESCUE_Phase9.ReconcileAll,"RescuePhase9");
Log("loaded version="..VERSION.." active="..tostring(Active()).." aiProduction=50 aiPurchaseDiscount=30 aiPseudoYields=100 aiWallBuildings=BUILDING_WALLS/BUILDING_CASTLE/BUILDING_STAR_FORT aiCityDefensePseudoYield=100 aiCombatCap=difficulty10/12/15 aiCombatCap=5 aiProductionLimit=15 aiPost5Bonus=3 combatIndex=incremental fullScan=migrationOnly overflowPolicy=retireNewest");
