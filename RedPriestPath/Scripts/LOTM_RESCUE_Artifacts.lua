-- Resource 268: synchronized Rescue-only artifact effects.
-- UI may request an action, but every mutation and reward is revalidated here.
LOTM_RESCUE_Artifacts=LOTM_RESCUE_Artifacts or {};

local VERSION=4;
local SLOT_PREFIX="LOTM_PP_ARTIFACT_SLOT_";
local INSTANCE_PREFIX="LOTM_PP_ARTIFACT_INSTANCE_";
local WEATHER_ABILITY="ABILITY_LOTM_RESCUE_WEATHER_MONSTER_DEBUFF";
local ATTACHED_PROPERTY="LOTM_RESCUE_ARTIFACT_MODIFIERS_268";
local UPGRADE_ATTACHED_PROPERTY="LOTM_RESCUE_ARTIFACT_MODIFIERS_270";
local UPGRADE271_ATTACHED_PROPERTY="LOTM_RESCUE_ARTIFACT_MODIFIERS_271";
local ALLY_ATTACHED_PROPERTY="LOTM_RESCUE_ARTIFACT_ALLY_MODIFIERS_268";
local ALLY_UPGRADE_ATTACHED_PROPERTY="LOTM_RESCUE_ARTIFACT_ALLY_MODIFIERS_270";
local ALLY_UPGRADE271_ATTACHED_PROPERTY="LOTM_RESCUE_ARTIFACT_ALLY_MODIFIERS_271";
local MIGRATION_PROPERTY="LOTM_RESCUE_ARTIFACT_MIGRATION_268";
local WEATHER_RECONCILE_VERSION=2;
local WEATHER_RECONCILE_PROPERTY="LOTM_RESCUE_ARTIFACT_WEATHER_RECONCILE_VERSION";
local ARTIFACTS={
 "GREATWORK_LOTM_PP_GOLDEN_APPRAISAL_MIRROR","GREATWORK_LOTM_PP_PERPETUAL_GEARBOX","GREATWORK_LOTM_PP_ERROR_ASTROLABE",
 "GREATWORK_LOTM_PP_HERMES_FURNACE","GREATWORK_LOTM_PP_MYSTERY_BLUEPRINT","GREATWORK_LOTM_PP_KNOWLEDGE_CASKET",
 "GREATWORK_LOTM_PP_CIVILIZATION_STELE","GREATWORK_LOTM_RP_DISASTER_EMBER","GREATWORK_LOTM_RP_CONSPIRATOR_LETTER",
 "GREATWORK_LOTM_RP_BLOOD_HARVEST_SICKLE","GREATWORK_LOTM_RP_IRONBLOOD_BANNER","GREATWORK_LOTM_RP_WAR_SCRIPTURE",
 "GREATWORK_LOTM_RP_DISASTER_WEATHER","GREATWORK_LOTM_RP_CONQUEROR_CROWN","GREATWORK_LOTM_BE_GOLDEN_BRIBE",
 "GREATWORK_LOTM_BE_CORRUPTION_TAXBOOK","GREATWORK_LOTM_BE_CHAOS_CODEX","GREATWORK_LOTM_BE_DEPRAVED_FEAST",
 "GREATWORK_LOTM_BE_FRENZY_SCEPTER","GREATWORK_LOTM_BE_ENTROPY_CROWN","GREATWORK_LOTM_BE_ORDER_CONVERTER"
};

local function Log(message) print("[LOTM_RESCUE][Artifacts] "..tostring(message)); end
local function Number(value,default) if value==nil then return default; end return tonumber(value) or default; end
local function Active() return Number(Game.GetProperty("LOTM_RESCUE_MODE"),0)==1; end
local function Human(playerID)
 local p=Players[playerID];
 return p~=nil and p:IsAlive() and p:IsMajor() and p:IsHuman() and p or nil;
end
local function ResourceType(index,positive)
 return string.format("RESOURCE_LOTM_RESCUE_ARTIFACT_LEASE_%02d_%s",index,positive and "POS" or "NEG");
end
local function OrdinaryResourceType(index,positive)
 return string.format("RESOURCE_LOTM_ARTIFACT_LEASE76_%02d_%s",index,positive and "POS" or "NEG");
end
local function SetResource(player,resourceType,wanted)
 local row=GameInfo.Resources[resourceType]; if player==nil or row==nil then return false; end
 local resources=player:GetResources(); local current=resources:GetResourceAmount(row.Index) or 0;
 local target=wanted and 1 or 0;
 if current~=target and resources.ChangeResourceAmount~=nil then resources:ChangeResourceAmount(row.Index,target-current); return true; end
 return false;
end
local function IsEquipped(player,artifactType)
 for slot=1,9 do if player:GetProperty(SLOT_PREFIX..slot)==artifactType then return true; end end
 return false;
end
local function Polarity(player,artifactType)
 if not IsEquipped(player,artifactType) then return false,false; end
 local instance=Number(player:GetProperty(INSTANCE_PREFIX..artifactType),-1);
 local playerTurn=Number(player:GetProperty("LOTM_WORLD_PLAYER_TURN"),0);
 local satisfiedUntil=instance>=0 and Number(player:GetProperty("LOTM_ARTIFACT_SATISFIED_UNTIL_"..instance),-1) or -1;
 local uncontrolledUntil=instance>=0 and Number(player:GetProperty("LOTM_ARTIFACT_UNCONTROLLED_UNTIL_"..instance),-1) or -1;
 if uncontrolledUntil>playerTurn then return false,true; end
 if satisfiedUntil>playerTurn then return true,false; end
 return true,true;
end
local function PositiveActive(player,artifactType)
 local positive=Polarity(player,artifactType); return positive;
end

local rescueModifierIds=nil;
local function RescueModifierIds()
 if rescueModifierIds~=nil then return rescueModifierIds; end
 rescueModifierIds={};
 if GameInfo.LOTM_RescueArtifactModifiers268~=nil then
  for row in GameInfo.LOTM_RescueArtifactModifiers268() do rescueModifierIds[#rescueModifierIds+1]=row.ModifierId; end
 end
 table.sort(rescueModifierIds); return rescueModifierIds;
end
local function EnsureHumanInfrastructure(player)
 if Number(player:GetProperty(ATTACHED_PROPERTY),0)~=1 then
  local ids=RescueModifierIds();
  for _,modifierID in ipairs(ids) do pcall(function() player:AttachModifierByID(modifierID); end); end
  player:SetProperty(ATTACHED_PROPERTY,1); player:SetProperty(UPGRADE_ATTACHED_PROPERTY,1); player:SetProperty(UPGRADE271_ATTACHED_PROPERTY,1);
  Log("holder modifiers attached player="..player:GetID().." count="..#ids);
 else
  if Number(player:GetProperty(UPGRADE_ATTACHED_PROPERTY),0)~=1 then
   local ids={
   "LOTM_RESCUE_LETTER_GOLD","LOTM_RESCUE_LETTER_PRODUCTION",
   "LOTM_RESCUE_SCRIPTURE_PRODUCTION","LOTM_RESCUE_SCRIPTURE_FOOD",
   "LOTM_RESCUE_SCRIPTURE_OLD_WAR_PRODUCTION_NEUTRALIZE268",
   "LOTM_RESCUE_SCRIPTURE_OLD_PEACE_PRODUCTION_NEUTRALIZE268",
   "LOTM_RESCUE_SCRIPTURE_OLD_WEARINESS_NEUTRALIZE268"
   };
   for _,modifierID in ipairs(ids) do pcall(function() player:AttachModifierByID(modifierID); end); end
   player:SetProperty(UPGRADE_ATTACHED_PROPERTY,1);
   Log("holder resource270 modifiers attached player="..player:GetID().." count="..#ids);
  elseif Number(player:GetProperty(UPGRADE271_ATTACHED_PROPERTY),0)~=1 then
   local ids={"LOTM_RESCUE_CROWN_SELF_COMBAT_NEUTRALIZE270","LOTM_RESCUE_CROWN_SELF_INNER_RESTORE270","LOTM_RESCUE_CROWN_SELF_OUTER_RESTORE270"};
   for _,modifierID in ipairs(ids) do pcall(function() player:AttachModifierByID(modifierID); end); end
   Log("holder resource271 crown repair attached player="..player:GetID().." count="..#ids);
  end
  player:SetProperty(UPGRADE271_ATTACHED_PROPERTY,1);
 end
end
local function EnsureAllyInfrastructure(player)
 if player==nil or not player:IsAlive() or not player:IsMajor() or player:IsHuman() then return; end
 local baseAttached=Number(player:GetProperty(ALLY_ATTACHED_PROPERTY),0)==1;
 local upgradeAttached=Number(player:GetProperty(ALLY_UPGRADE_ATTACHED_PROPERTY),0)==1;
 local upgrade271Attached=Number(player:GetProperty(ALLY_UPGRADE271_ATTACHED_PROPERTY),0)==1;
 if baseAttached and upgradeAttached and upgrade271Attached then return; end
 local base={
  "LOTM_RESCUE_ALLY_BANNER_COMBAT",
  "LOTM_RESCUE_ALLY_CROWN_INNER","LOTM_RESCUE_ALLY_CROWN_OUTER"
 };
 if not baseAttached then for _,modifierID in ipairs(base) do pcall(function() player:AttachModifierByID(modifierID); end); end end
 if baseAttached and upgradeAttached and not upgrade271Attached then
  local repair={"LOTM_RESCUE_ALLY_CROWN_COMBAT_NEUTRALIZE270","LOTM_RESCUE_ALLY_CROWN_INNER_RESTORE270","LOTM_RESCUE_ALLY_CROWN_OUTER_RESTORE270"};
  for _,modifierID in ipairs(repair) do pcall(function() player:AttachModifierByID(modifierID); end); end
 end
 player:SetProperty(ALLY_ATTACHED_PROPERTY,1); player:SetProperty(ALLY_UPGRADE_ATTACHED_PROPERTY,1);
 player:SetProperty(ALLY_UPGRADE271_ATTACHED_PROPERTY,1);
end
local function ReconcileHolder(player)
 EnsureHumanInfrastructure(player);
 local changed=false;
 for index,artifactType in ipairs(ARTIFACTS) do
  local positive,negative=Polarity(player,artifactType);
  -- Rescue owns the active namespace. Retire every ordinary polarity lease,
  -- including those serialized by an older save.
  changed=SetResource(player,OrdinaryResourceType(index,true),false) or changed;
  changed=SetResource(player,OrdinaryResourceType(index,false),false) or changed;
  changed=SetResource(player,ResourceType(index,true),positive) or changed;
  changed=SetResource(player,ResourceType(index,false),negative) or changed;
 end
 if Number(player:GetProperty(MIGRATION_PROPERTY),0)~=1 then
  player:SetProperty(MIGRATION_PROPERTY,1);
  Log("old-save lease migration player="..player:GetID());
 end
 return changed;
end
local function PairKey(firstID,secondID)
 local low=math.min(firstID,secondID); local high=math.max(firstID,secondID);
 return "LOTM_RESCUE_PHASE8_PERMANENT_ALLIANCE:"..low..":"..high;
end
local function Allied(first,secondID)
 local diplomacy=first~=nil and first:GetDiplomacy() or nil;
 local official=false;
 if diplomacy~=nil and diplomacy.HasAllied~=nil then
  local ok,result=pcall(function() return diplomacy:HasAllied(secondID); end); official=ok and result==true;
 end
 return official or Number(Game.GetProperty(PairKey(first:GetID(),secondID)),0)==1;
end
local function HumanHolders()
 local result={};
 for _,player in ipairs(PlayerManager.GetAliveMajors()) do if player:IsHuman() then result[#result+1]=player; end end
 table.sort(result,function(a,b) return a:GetID()<b:GetID(); end); return result;
end
local function SortedAliveIDs()
 local result={};
 for _,playerID in ipairs(PlayerManager.GetAliveIDs()) do result[#result+1]=playerID; end
 table.sort(result); return result;
end
local function SortedAliveMajors()
 local result={};
 for _,player in ipairs(PlayerManager.GetAliveMajors()) do result[#result+1]=player; end
 table.sort(result,function(a,b) return a:GetID()<b:GetID(); end); return result;
end
local function SortedUnits(player)
 local result={}; if player==nil then return result; end
 for _,unit in player:GetUnits():Members() do result[#result+1]=unit; end
 table.sort(result,function(a,b) return a:GetID()<b:GetID(); end); return result;
end
local function IsWeatherTarget(unit)
 if unit==nil then return false; end
 local roaming=LOTM_WORLD_Monsters~=nil and LOTM_WORLD_Monsters.IsMonster~=nil and LOTM_WORLD_Monsters.IsMonster(unit);
 return roaming or Number(unit:GetProperty("LOTM_RESCUE_CENTER_MONSTER"),0)==1;
end
local function ApplyWeatherAbility(unit,desired)
 if not IsWeatherTarget(unit) then return false; end
 local ability=unit:GetAbility(); if ability==nil or GameInfo.UnitAbilities[WEATHER_ABILITY]==nil then return false; end
 local current=ability:GetAbilityCount(WEATHER_ABILITY) or 0; local wanted=desired and 1 or 0;
 if current~=wanted then ability:ChangeAbilityCount(WEATHER_ABILITY,wanted-current); return true; end
 return false;
end
local function ReconcileMonsters(weatherActive)
 local changed=0; local targets=0;
 for _,playerID in ipairs(SortedAliveIDs()) do
  local player=Players[playerID];
  if player~=nil then for _,unit in ipairs(SortedUnits(player)) do
   if IsWeatherTarget(unit) then targets=targets+1; if ApplyWeatherAbility(unit,weatherActive) then changed=changed+1; end end
  end end
 end
 return changed,targets;
end
local function ReconcileGlobal(reason)
 if not Active() then return; end
 local holders=HumanHolders(); local weather=false; local frenzy=false; local crown=false; local bannerAllies=0; local crownAllies=0;
 for _,holder in ipairs(holders) do
  ReconcileHolder(holder);
  weather=weather or PositiveActive(holder,"GREATWORK_LOTM_RP_DISASTER_WEATHER");
  frenzy=frenzy or PositiveActive(holder,"GREATWORK_LOTM_BE_FRENZY_SCEPTER");
  crown=crown or PositiveActive(holder,"GREATWORK_LOTM_RP_CONQUEROR_CROWN");
 end
 local oldWeather=Number(Game.GetProperty("LOTM_RESCUE_ARTIFACT_WEATHER_ACTIVE"),0)==1;
 Game.SetProperty("LOTM_RESCUE_ARTIFACT_WEATHER_ACTIVE",weather and 1 or 0);
 Game.SetProperty("LOTM_RESCUE_ARTIFACT_FRENZY_ACTIVE",frenzy and 1 or 0);
 local reconcileVersion=Number(Game.GetProperty(WEATHER_RECONCILE_PROPERTY),0);
 local mustReconcile=oldWeather~=weather or reconcileVersion<WEATHER_RECONCILE_VERSION;
 local monsterChanges=0; local monsterTargets=-1;
 if mustReconcile then monsterChanges,monsterTargets=ReconcileMonsters(weather); end
 if mustReconcile then Game.SetProperty(WEATHER_RECONCILE_PROPERTY,WEATHER_RECONCILE_VERSION); end
 for _,ai in ipairs(SortedAliveMajors()) do
  if not ai:IsHuman() then
   EnsureAllyInfrastructure(ai);
   local banner=false; local crown=false;
   for _,holder in ipairs(holders) do if Allied(holder,ai:GetID()) then
    banner=banner or PositiveActive(holder,"GREATWORK_LOTM_RP_IRONBLOOD_BANNER");
    crown=crown or PositiveActive(holder,"GREATWORK_LOTM_RP_CONQUEROR_CROWN");
   end end
   SetResource(ai,"RESOURCE_LOTM_RESCUE_ALLY_BANNER",banner);
   SetResource(ai,"RESOURCE_LOTM_RESCUE_ALLY_CROWN",crown);
   if banner then bannerAllies=bannerAllies+1; end
   if crown then crownAllies=crownAllies+1; end
  end
 end
 if LOTM_RESCUE_Phase5~=nil and LOTM_RESCUE_Phase5.RefreshState~=nil then LOTM_RESCUE_Phase5.RefreshState(); end
 Log("reconciled reason="..tostring(reason).." holders="..#holders.." weather="..tostring(weather).." crown="..tostring(crown).." frenzy="..tostring(frenzy).." bannerAllies="..bannerAllies.." crownAllies="..crownAllies.." monsterTargets="..monsterTargets.." monsterChanges="..monsterChanges);
end

-- Public hook used by the monster creation/reconciliation chain.
function LOTM_RESCUE_Artifacts.WeatherActive()
 return Active() and Number(Game.GetProperty("LOTM_RESCUE_ARTIFACT_WEATHER_ACTIVE"),0)==1;
end
function LOTM_RESCUE_Artifacts.ApplyMonsterWeather(unit)
 return ApplyWeatherAbility(unit,LOTM_RESCUE_Artifacts.WeatherActive());
end

local function PlunderReward(player,unit,plunderType,baseAmount)
 -- PlunderAmount is already the native operation reward for the current
 -- ruleset. Applying game-speed CostMultiplier here halved Online rewards a
 -- second time (latest runtime evidence: base 25 became 26 instead of 50).
 local doubled=math.max(0,math.floor(Number(baseAmount,0)+0.5))*2; local amount=doubled;
 if amount<=0 then return 0,doubled; end
 if plunderType=="PLUNDER_GOLD" then player:GetTreasury():ChangeGoldBalance(amount);
 elseif plunderType=="PLUNDER_FAITH" then local religion=player:GetReligion(); if religion~=nil then religion:ChangeFaithBalance(amount); end
 elseif plunderType=="PLUNDER_SCIENCE" then local techs=player:GetTechs(); if techs~=nil and techs.ChangeCurrentResearchProgress~=nil then techs:ChangeCurrentResearchProgress(amount); end
 elseif plunderType=="PLUNDER_CULTURE" then local culture=player:GetCulture(); if culture~=nil and culture.ChangeCurrentCulturalProgress~=nil then culture:ChangeCurrentCulturalProgress(amount); end
 elseif plunderType=="PLUNDER_HEAL" then local damage=unit:GetDamage() or 0; amount=math.min(damage,amount); unit:ChangeDamage(-amount);
 else return 0,doubled; end
 return amount,doubled;
end
local function ShowPlunderWorldText(playerID,plunderType,amount,x,y)
 if amount<=0 or Game.AddWorldViewText==nil then return; end
 local styles={
  PLUNDER_GOLD={"COLOR_FLOAT_GOLD","ICON_Gold"},
  PLUNDER_FAITH={"COLOR_FLOAT_FAITH","ICON_Faith"},
  PLUNDER_SCIENCE={"COLOR_FLOAT_SCIENCE","ICON_Science"},
  PLUNDER_CULTURE={"COLOR_FLOAT_CULTURE","ICON_Culture"},
  PLUNDER_HEAL={"COLOR_FLOAT_FOOD","ICON_Health"}
 };
 local style=styles[plunderType]; if style==nil then return; end
 if LOTM_MP_TurnSync.IsNetworkGame() then
  local ok,details=pcall(function()
   Game.AddWorldViewText(playerID,"["..style[1].."]+"..tostring(amount).." ["..style[2].."][ENDCOLOR]",x,y);
  end);
  if not ok then Log("network own-pillage world text skipped after Gameplay commit error="..tostring(details)); end
  return;
 end
 Game.AddWorldViewText(playerID,"["..style[1].."]+"..tostring(amount).." ["..style[2].."][ENDCOLOR]",x,y);
end
local function MoveCost(unit)
 local cost=Number(GlobalParameters.PILLAGE_MOVEMENT_COST,3)*60;
 local moves=unit:GetMovesRemaining() or 0; unit:ChangeMovesRemaining(-math.min(moves,cost));
end
local function CommandOwnPillage(ownerID,unitID,parameters)
 if not Active() then return false; end
 local player=Human(ownerID); local unit=player~=nil and player:GetUnits():FindID(unitID) or nil;
 if player==nil or unit==nil or unit:IsDead() or unit:IsDelayedDeath() or not player:IsTurnActive() then return false; end
 if not PositiveActive(player,"GREATWORK_LOTM_RP_DISASTER_EMBER") then Log("own pillage rejected reason=EMBER_INACTIVE player="..ownerID); return false; end
 if (unit:GetCombat() or 0)<=0 and (unit:GetRangedCombat() or 0)<=0 and (unit:GetBombardCombat() or 0)<=0 then return false; end
 if (unit:GetMovesRemaining() or 0)<=0 then return false; end
 local x=Number(parameters[UnitCommandTypes.PARAM_X],-1); local y=Number(parameters[UnitCommandTypes.PARAM_Y],-1);
 local plot=Map.GetPlot(x,y); if plot==nil or unit:GetX()~=x or unit:GetY()~=y or plot:GetOwner()~=ownerID then return false; end
 local key="LOTM_RESCUE_OWN_PILLAGE:"..ownerID..":"..unitID..":"..plot:GetIndex();
 if Number(Game.GetProperty(key),-1)==Game.GetCurrentGameTurn() then return false; end
 local plunderType=nil; local baseAmount=0; local layer="NONE"; local changed=false;
 local improvement=GameInfo.Improvements[plot:GetImprovementType()];
 if improvement~=nil and not plot:IsImprovementPillaged() and improvement.PlunderType~="NO_PLUNDER" and improvement.PlunderType~="PLUNDER_NONE" then
  plunderType=improvement.PlunderType; baseAmount=improvement.PlunderAmount; layer="IMPROVEMENT";
  local ok=pcall(function() ImprovementBuilder.SetImprovementPillaged(plot,true); end); changed=ok and plot:IsImprovementPillaged();
 else
  local district=CityManager.GetDistrictAt(x,y); local districtInfo=district~=nil and GameInfo.Districts[district:GetType()] or nil;
  if district~=nil and districtInfo~=nil and districtInfo.PlunderType~="NO_PLUNDER" and districtInfo.PlunderType~="PLUNDER_NONE" then
   plunderType=districtInfo.PlunderType; baseAmount=districtInfo.PlunderAmount;
   local city=Cities.GetPlotPurchaseCity(plot); local buildings=city~=nil and city:GetBuildings() or nil;
   if buildings~=nil then
    local candidates={}; for building in GameInfo.Buildings() do
     if building.PrereqDistrict==districtInfo.DistrictType and buildings:HasBuilding(building.Index) and not buildings:IsPillaged(building.Index) and Number(building.Pillage,1)~=0 then candidates[#candidates+1]=building; end
    end
    table.sort(candidates,function(a,b) return a.Index<b.Index; end);
    if #candidates>0 then
     local target=candidates[1]; local ok=pcall(function() buildings:SetPillaged(target.Index,true); end);
     changed=ok and buildings:IsPillaged(target.Index); layer="BUILDING:"..target.BuildingType;
    elseif not district:IsPillaged() then local ok=pcall(function() district:SetPillaged(true); end); changed=ok and district:IsPillaged(); layer="DISTRICT"; end
   end
  end
 end
 if not changed then Log("own pillage rejected reason=NO_VALID_LAYER player="..ownerID.." plot="..plot:GetIndex()); return false; end
 Game.SetProperty(key,Game.GetCurrentGameTurn()); MoveCost(unit);
 local reward,doubled=PlunderReward(player,unit,plunderType,baseAmount);
 ShowPlunderWorldText(ownerID,plunderType,reward,x,y);
 Log("own pillage committed player="..ownerID.." unit="..unitID.." plot="..plot:GetIndex().." layer="..layer.." plunder="..tostring(plunderType).." base="..tostring(baseAmount).." double="..doubled.." reward="..reward);
 return true;
end

local function OnPlayerTurn(playerID,isFirstTime)
 if isFirstTime==false or Human(playerID)==nil then return; end ReconcileGlobal("PLAYER_TURN:"..playerID);
end
local function OnArtifactCommand() ReconcileGlobal("ARTIFACT_COMMAND"); end
local function OnDiplomacy(firstID,secondID)
 if LOTM_MP_TurnSync.IsNetworkGame() then return; end
 ReconcileGlobal("DIPLOMACY:"..tostring(firstID)..":"..tostring(secondID));
end

GameEvents.LOTM_RESCUE_Command_OwnPillage.Add(CommandOwnPillage);
GameEvents.LOTM_PP_Command_Artifact.Add(OnArtifactCommand);
LOTM_MP_TurnSync.Add(OnPlayerTurn,"RescueArtifacts");
Events.DiplomacyDeclareWar.Add(OnDiplomacy); Events.DiplomacyMakePeace.Add(OnDiplomacy);
if Events.AllianceChanged~=nil then Events.AllianceChanged.Add(OnDiplomacy); end
LOTM_MP_TurnSync.RunStartup(function() ReconcileGlobal("INITIALIZE"); end,"RescueArtifacts");
Log("initialized version="..VERSION.." separatedLeases=21 ownPillage=synchronized ally=HasAlliedOrPermanentPair");
