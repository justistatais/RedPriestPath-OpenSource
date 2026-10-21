-- Synchronized AI cult assignment, independent tiers, target scaling and
-- reversible continuous effects. UI reads these Properties but never writes.
LOTM_AI_Cults = LOTM_AI_Cults or {};

local CULTS={"DEMONESS","HANGED_MAN","CHAINED"};
local TIER_KEYS={
 DEMONESS="LOTM_CULT_DEMONESS_TIER",
 HANGED_MAN="LOTM_CULT_HANGED_MAN_TIER",
 CHAINED="LOTM_CULT_CHAINED_TIER"
};
local MAX_KEYS={
 DEMONESS="LOTM_CULT_DEMONESS_MAX_POSTINDUSTRIAL_TECH",
 HANGED_MAN="LOTM_CULT_HANGED_MAX_POSTINDUSTRIAL_TECH",
 CHAINED="LOTM_CULT_CHAINED_MAX_POSTINDUSTRIAL_TECH"
};
local STATE_VERSION=4;
local prefixCache={};
local HANGED_WAR_ABILITIES={
 [1]="ABILITY_LOTM_CULT_HANGED_WAR_C1",[5]="ABILITY_LOTM_CULT_HANGED_WAR_C5",
 [20]="ABILITY_LOTM_CULT_HANGED_WAR_C20",[40]="ABILITY_LOTM_CULT_HANGED_WAR_C40",
 [60]="ABILITY_LOTM_CULT_HANGED_WAR_C60"
};
local CHAINED_WAR_ABILITIES={
 [2]="ABILITY_LOTM_CULT_CHAINED_WAR_C2",[10]="ABILITY_LOTM_CULT_CHAINED_WAR_C10",
 [20]="ABILITY_LOTM_CULT_CHAINED_WAR_C20"
};
local WAR_COMBAT_ABILITIES={
 "ABILITY_LOTM_CULT_HANGED_WAR_C1","ABILITY_LOTM_CULT_HANGED_WAR_C5",
 "ABILITY_LOTM_CULT_HANGED_WAR_C20","ABILITY_LOTM_CULT_HANGED_WAR_C40",
 "ABILITY_LOTM_CULT_HANGED_WAR_C60","ABILITY_LOTM_CULT_CHAINED_WAR_C2",
 "ABILITY_LOTM_CULT_CHAINED_WAR_C10","ABILITY_LOTM_CULT_CHAINED_WAR_C20"
};

local function Log(message) print("[LOTM_CULT] "..tostring(message)); end
local function Number(value,default) if value==nil then return default; end return tonumber(value) or default; end
local function AliveMajors()
 local result={};
 for _,player in ipairs(PlayerManager.GetAliveMajors()) do table.insert(result,player); end
 table.sort(result,function(a,b) return a:GetID()<b:GetID(); end);
 return result;
end
local function AliveAIMajors()
 local result={}; for _,player in ipairs(AliveMajors()) do if not player:IsHuman() then table.insert(result,player); end end return result;
end
local function SortedUnits(player)
 local result={}; if player==nil then return result; end
 for _,unit in player:GetUnits():Members() do result[#result+1]=unit; end
 table.sort(result,function(a,b) return a:GetID()<b:GetID(); end);
 return result;
end
local function IsCult(path) return path=="DEMONESS" or path=="HANGED_MAN" or path=="CHAINED"; end
local function PlayerCult(player) local value=player~=nil and player:GetProperty("LOTM_CULT_PATH") or nil; return IsCult(value) and value or "NONE"; end
local function RescueActive() return Number(Game.GetProperty("LOTM_RESCUE_MODE"),0)==1; end

local function SetPlayerCult(player,path)
 if player==nil or player:IsHuman() or not IsCult(path) then return; end
 if PlayerCult(player)=="NONE" then
  player:SetProperty("LOTM_CULT_PATH",path);
  Game.SetProperty("LOTM_CULT_PATH_"..tostring(player:GetID()),path);
  Log("assigned player="..player:GetID().." path="..path);
 end
end

local function InitializeAssignments()
 local ai=AliveAIMajors(); if #ai==0 then return; end
 local missing={}; local present={}; local unassigned={};
 for _,player in ipairs(ai) do
  local path=PlayerCult(player); if IsCult(path) then present[path]=true else table.insert(unassigned,player); end
 end
 for _,path in ipairs(CULTS) do if not present[path] then table.insert(missing,path); end end
 -- With at least three AI, consume every missing path first. A synchronized
 -- rotation keeps which AI receives which guaranteed path unpredictable.
 if #ai>=3 and #unassigned>0 then
  local offset=LOTM_WORLD_State.Random(#missing>0 and #missing or 1,"CULT_GUARANTEE_ROTATION");
  local rotated={}; for index=1,#missing do table.insert(rotated,missing[((index+offset-1)%#missing)+1]); end
  missing=rotated;
 end
 for index,player in ipairs(unassigned) do
  local path=nil;
  if #ai>=3 and index<=#missing then path=missing[index];
  else path=CULTS[LOTM_WORLD_State.Random(#CULTS,"CULT_ASSIGN_PLAYER_"..player:GetID())+1]; end
  SetPlayerCult(player,path);
 end
 Game.SetProperty("LOTM_CULT_ASSIGNMENTS_INITIALIZED",1);
end

local function IndustrialEraChronology()
 local row=GameInfo.Eras.ERA_INDUSTRIAL; return row~=nil and Number(row.ChronologyIndex,row.Index) or 3;
end
local function PostIndustrialTechCount(player)
 if player==nil then return 0; end local techs=player:GetTechs(); if techs==nil then return 0; end
 local threshold=IndustrialEraChronology(); local count=0;
 for tech in GameInfo.Technologies() do
  local era=tech.EraType~=nil and GameInfo.Eras[tech.EraType] or nil;
  if era~=nil and Number(era.ChronologyIndex,era.Index)>=threshold and techs:HasTech(tech.Index) then count=count+1; end
 end
 return count;
end

local function DesiredTier(maxTech) if maxTech>=14 then return 3 elseif maxTech>=5 then return 2 else return 1 end end
local function ReconcileTiers()
 for _,cult in ipairs(CULTS) do
  local highest=0;
  for _,player in ipairs(AliveAIMajors()) do if PlayerCult(player)==cult then highest=math.max(highest,PostIndustrialTechCount(player)); end end
  local historical=Number(Game.GetProperty(MAX_KEYS[cult]),0); if highest>historical then historical=highest; Game.SetProperty(MAX_KEYS[cult],historical); end
  local oldTier=Number(Game.GetProperty(TIER_KEYS[cult]),1); local newTier=math.max(oldTier,DesiredTier(historical));
  if Game.GetProperty(TIER_KEYS[cult])==nil or newTier~=oldTier then Game.SetProperty(TIER_KEYS[cult],newTier); Log("tier cult="..cult.." old="..oldTier.." new="..newTier.." maxTech="..historical); end
 end
end

function LOTM_AI_Cults.GetTier(cult) return Number(Game.GetProperty(TIER_KEYS[cult]),1); end
function LOTM_AI_Cults.GetPlayerCult(playerID) return PlayerCult(Players[playerID]); end
function LOTM_AI_Cults.PostIndustrialTechCount(player) return PostIndustrialTechCount(player); end

local function HasFormalPath(player)
 if player==nil or LOTM_RP_State==nil or LOTM_RP_State.IsAnyPathPlayer==nil then return false; end
 -- Reuse the authoritative pathway-state API.  The synchronized property
 -- stores PATH_RED_PRIEST / PATH_PERFECT / PATH_BLACK_EMPEROR, not the old
 -- RP / PP / BE shorthand.  Keeping a second literal check here previously
 -- blocked both war modifiers and per-turn Faith settlement.
 return LOTM_RP_State.IsAnyPathPlayer(player:GetID());
end
function LOTM_AI_Cults.GetTargetTier(player)
 if HasFormalPath(player) then
  local sequence=Number(player:GetProperty("LOTM_RP_SEQUENCE"),9);
  if sequence>=5 then return 1 elseif sequence>=3 then return 2 else return 3 end -- Sequence 2..0 is tier 3.
 end
 return DesiredTier(PostIndustrialTechCount(player));
end
function LOTM_AI_Cults.GetMultiplier(cultTier,targetTier)
 local difference=targetTier-cultTier;
 if difference==0 then return 1 elseif difference==1 then return 0.2 elseif difference>=2 then return 0 elseif difference==-1 then return 2 else return 3 end
end
local function ScaledInt(base,cultTier,targetTier) return math.floor(base*LOTM_AI_Cults.GetMultiplier(cultTier,targetTier)+0.000001); end
local function ScaledPercent(base,cultTier,targetTier) return math.min(100,ScaledInt(base,cultTier,targetTier)); end

function LOTM_AI_Cults.GetHighestScoreMajorCivilization()
 local selected=nil; local best=nil;
 for _,player in ipairs(AliveMajors()) do
  local score=Number(player:GetScore(),0);
  if best==nil or score>best or (score==best and player:GetID()<selected:GetID()) then selected=player; best=score; end
 end
 return selected;
end

local function HasLivingCult(cult) for _,player in ipairs(AliveAIMajors()) do if PlayerCult(player)==cult then return true; end end return false; end
local function AtWarWithCult(player,cult)
 if player==nil then return false; end local diplomacy=player:GetDiplomacy(); if diplomacy==nil then return false; end
 for _,enemy in ipairs(AliveAIMajors()) do if PlayerCult(enemy)==cult and diplomacy:IsAtWarWith(enemy:GetID()) then return true; end end
 return false;
end

local function PrefixIds(prefix)
 if prefixCache[prefix]~=nil then return prefixCache[prefix]; end local found={};
 for row in GameInfo.Modifiers() do if string.sub(row.ModifierId,1,#prefix)==prefix then table.insert(found,row.ModifierId); end end
 table.sort(found); prefixCache[prefix]=found; return found;
end
local function AttachPrefix(player,prefix)
 local ids=PrefixIds(prefix); for _,modifierID in ipairs(ids) do player:AttachModifierByID(modifierID); end
 if #ids==0 then Log("modifier prefix missing="..prefix); end
end
local function NotifyEffect(player,slot,active)
 if player==nil or not player:IsHuman() then return; end
 local cult=nil; local notificationType=NotificationTypes.USER_DEFINED_9;
 if slot=="DEMONESS" then cult="DEMONESS"; notificationType=NotificationTypes.USER_DEFINED_4;
 elseif slot=="HANGED_WAR" then cult="HANGED_MAN"; notificationType=NotificationTypes.USER_DEFINED_5;
 elseif slot=="CHAINED_WAR" or slot=="CHAINED_BORDER" then cult="CHAINED"; end
 if cult==nil then return; end local tier=LOTM_AI_Cults.GetTier(cult);
 if LOTM_MP_TurnSync.IsNetworkGame() then
  -- Locale and NotificationManager are presentation-only services.  The
  -- modifier switch and its authoritative property have already committed;
  -- keep every localized operation inside the best-effort boundary so a
  -- client-specific notification failure cannot stop later Gameplay handlers.
  local ok,err=pcall(function()
   local name=Locale.Lookup("LOC_LOTM_CULT_"..cult.."_NAME"); local skill=Locale.Lookup("LOC_LOTM_CULT_"..cult.."_T"..tier.."_NAME");
   local data={}; data[ParameterTypes.MESSAGE]=Locale.Lookup(active and "LOC_LOTM_CULT_NOTIFICATION_APPLIED" or "LOC_LOTM_CULT_NOTIFICATION_ENDED",name,skill); data[ParameterTypes.SUMMARY]=active and Locale.Lookup("LOC_LOTM_CULT_"..cult.."_T"..tier.."_DESCRIPTION") or Locale.Lookup("LOC_LOTM_CULT_NOTIFICATION_ENDED_SUMMARY"); data.AlwaysUnique=true; data.ShowIcon=false;
   NotificationManager.SendNotification(player:GetID(),notificationType,data);
  end);
  if not ok then Log("network notification skipped after Gameplay commit slot="..slot.." error="..tostring(err)); end
  return;
 end
 local name=Locale.Lookup("LOC_LOTM_CULT_"..cult.."_NAME"); local skill=Locale.Lookup("LOC_LOTM_CULT_"..cult.."_T"..tier.."_NAME");
 local data={}; data[ParameterTypes.MESSAGE]=Locale.Lookup(active and "LOC_LOTM_CULT_NOTIFICATION_APPLIED" or "LOC_LOTM_CULT_NOTIFICATION_ENDED",name,skill); data[ParameterTypes.SUMMARY]=active and Locale.Lookup("LOC_LOTM_CULT_"..cult.."_T"..tier.."_DESCRIPTION") or Locale.Lookup("LOC_LOTM_CULT_NOTIFICATION_ENDED_SUMMARY"); data.AlwaysUnique=true; data.ShowIcon=false;
 local ok,err=pcall(function() NotificationManager.SendNotification(player:GetID(),notificationType,data); end); if not ok then Log("notification failed slot="..slot.." error="..tostring(err)); end
end
local function ApplySwitch(player,slot,desired)
 local property="LOTM_CULT_APPLIED_"..slot; local old=tostring(player:GetProperty(property) or "NONE"); desired=desired or "NONE";
 if old==desired then return; end
 if old~="NONE" then AttachPrefix(player,"LOTM_CULT_"..old.."_OFF__"); end
 if desired~="NONE" then AttachPrefix(player,"LOTM_CULT_"..desired.."_ON__"); end
 player:SetProperty(property,desired); NotifyEffect(player,slot,desired~="NONE"); Log("switch player="..player:GetID().." slot="..slot.." old="..old.." new="..desired);
end
local function RetireLegacySwitch(player,slot)
 local property="LOTM_CULT_APPLIED_"..slot; local old=tostring(player:GetProperty(property) or "NONE");
 if old=="NONE" then return; end
 AttachPrefix(player,"LOTM_CULT_"..old.."_OFF__");
 player:SetProperty(property,"NONE");
 Log("retired legacy switch player="..player:GetID().." slot="..slot.." old="..old);
end
local function RefreshWarNotification(player,slot,desired)
 local property="LOTM_CULT_ACTIVE_"..slot; local old=tostring(player:GetProperty(property) or "NONE"); desired=desired or "NONE";
 if old==desired then return; end
 player:SetProperty(property,desired); NotifyEffect(player,slot,desired~="NONE");
 Log("war notification state player="..player:GetID().." slot="..slot.." old="..old.." new="..desired);
end

local function RefreshEffectAudit(player,hangedWar,hangedTier,hangedCombatAmount,chainedWar,chainedTier,chainedMove,chainedCombatAmount,chainedYield)
 local targetTier=LOTM_AI_Cults.GetTargetTier(player);
 local state=table.concat({
  "TARGET_T"..tostring(targetTier),
  "HANGED="..(hangedWar and ("T"..tostring(hangedTier)..":C"..tostring(hangedCombatAmount)) or "OFF"),
  "CHAINED="..(chainedWar and ("T"..tostring(chainedTier)..":MOVE_"..tostring(chainedMove or "NONE")..":C"..tostring(chainedCombatAmount)..":YIELD_"..tostring(chainedYield or "NONE")) or "OFF")
 },"|");
 local property="LOTM_CULT_EFFECT_AUDIT";
 if tostring(player:GetProperty(property) or "")~=state then
  player:SetProperty(property,state);
  Log("effect audit player="..player:GetID().." "..state);
 end
end

local function DemonessToken(player,tier)
 local target=LOTM_AI_Cults.GetTargetTier(player);
 if tier==1 then local amount=ScaledInt(1,tier,target); return amount>0 and "DEMONESS_V2_T1_M"..amount or nil; end
 if tier==2 then local percent=ScaledPercent(20,tier,target); return percent>0 and "DEMONESS_T2_P"..percent or nil; end
 local amenity=ScaledInt(5,tier,target); local percent=ScaledPercent(50,tier,target);
 return percent>0 and ("DEMONESS_T3_A"..amenity.."_P"..percent) or nil;
end
local function HangedToken(player,tier)
 local amount=0; if tier==1 then amount=ScaledInt(5,tier,LOTM_AI_Cults.GetTargetTier(player)); elseif tier==3 then amount=ScaledInt(20,tier,LOTM_AI_Cults.GetTargetTier(player)); end
 return amount>0 and ("HANGED_T"..tier.."_C"..amount) or nil,amount;
end
local function HangedFaithToken(player,tier)
 local _,amount=HangedToken(player,tier);
 return amount>0 and ("HANGED_FAITH_T"..tier.."_F"..amount) or nil,amount;
end
local function ChainedMoveToken(player,tier)
 local target=LOTM_AI_Cults.GetTargetTier(player);
 if tier==1 then local move=ScaledInt(1,tier,target); return move>0 and "CHAINED_MOVE_T1_M1" or nil; end
 if tier==2 then local move=ScaledInt(1,tier,target); return move>0 and ("CHAINED_MOVE_T2_M"..move) or nil; end
 return nil;
end
local function ChainedYieldToken(player,tier)
 if tier~=3 then return nil; end
 local percent=ScaledPercent(50,tier,LOTM_AI_Cults.GetTargetTier(player));
 return percent>0 and "CHAINED_YIELD_T3_P"..percent or nil;
end
local function ChainedCombatAmount(player,tier)
 return tier==2 and ScaledInt(10,tier,LOTM_AI_Cults.GetTargetTier(player)) or 0;
end
local function ChainedBorderToken(player,tier)
 if tier~=2 then return nil; end local percent=ScaledPercent(50,tier,LOTM_AI_Cults.GetTargetTier(player)); return percent>0 and "CHAINED_BORDER_P"..percent or nil;
end

local function SetUnitAbility(unit,abilityType,desired)
 local abilities=unit~=nil and unit:GetAbility() or nil; if abilities==nil then return; end
 local current=abilities:GetAbilityCount(abilityType) or 0;
 if current~=desired then abilities:ChangeAbilityCount(abilityType,desired-current); end
end
local function RefreshWarCombatAbilities(player,hangedAmount,chainedAmount)
 if player==nil then return; end
 local hangedAbility=HANGED_WAR_ABILITIES[hangedAmount]; local chainedAbility=CHAINED_WAR_ABILITIES[chainedAmount];
 for _,unit in ipairs(SortedUnits(player)) do
  for _,abilityType in ipairs(WAR_COMBAT_ABILITIES) do
   local desired=(abilityType==hangedAbility or abilityType==chainedAbility) and 1 or 0;
   SetUnitAbility(unit,abilityType,desired);
  end
 end
end

local function RetireNegativeEffectsForRescue()
 for _,player in ipairs(AliveMajors()) do
  ApplySwitch(player,"DEMONESS",nil);
  ApplySwitch(player,"CHAINED_BORDER",nil);
  RetireLegacySwitch(player,"HANGED_WAR");
  ApplySwitch(player,"HANGED_FAITH",nil);
  player:SetProperty("LOTM_CULT_HANGED_FAITH_PER_TURN",0);
  RetireLegacySwitch(player,"CHAINED_WAR");
  ApplySwitch(player,"CHAINED_MOVE",nil);
  ApplySwitch(player,"CHAINED_YIELD",nil);
  RefreshWarCombatAbilities(player,0,0);
  RefreshWarNotification(player,"HANGED_WAR",nil);
  RefreshWarNotification(player,"CHAINED_WAR",nil);
  player:SetProperty("LOTM_CULT_AT_WAR_WITH_HANGED",0);
  player:SetProperty("LOTM_CULT_AT_WAR_WITH_CHAINED",0);
  player:SetProperty("LOTM_CULT_EFFECT_AUDIT","RESCUE_POSITIVE_ONLY");
 end
end

local function ReconcileEffects()
 if RescueActive() then RetireNegativeEffectsForRescue(); return; end
 local top=LOTM_AI_Cults.GetHighestScoreMajorCivilization(); local topID=top~=nil and top:GetID() or -1; Game.SetProperty("LOTM_CULT_TOP_SCORE_PLAYER",topID);
 local demonTier=LOTM_AI_Cults.GetTier("DEMONESS"); local hangedTier=LOTM_AI_Cults.GetTier("HANGED_MAN"); local chainedTier=LOTM_AI_Cults.GetTier("CHAINED");
 local demonAlive=HasLivingCult("DEMONESS"); local hangedAlive=HasLivingCult("HANGED_MAN"); local chainedAlive=HasLivingCult("CHAINED");
 for _,player in ipairs(AliveMajors()) do
  local isTop=player:GetID()==topID;
  local demonDesired=nil; if demonAlive and isTop and PlayerCult(player)~="DEMONESS" then demonDesired=DemonessToken(player,demonTier); end
  ApplySwitch(player,"DEMONESS",demonDesired);
  local borderDesired=nil; if chainedAlive and isTop and PlayerCult(player)~="CHAINED" then borderDesired=ChainedBorderToken(player,chainedTier); end
  ApplySwitch(player,"CHAINED_BORDER",borderDesired);
  local formalHuman=HasFormalPath(player);
  local hangedWar=formalHuman and hangedAlive and AtWarWithCult(player,"HANGED_MAN");
  local chainedWar=formalHuman and chainedAlive and AtWarWithCult(player,"CHAINED");
  player:SetProperty("LOTM_CULT_AT_WAR_WITH_HANGED",hangedWar and 1 or 0); player:SetProperty("LOTM_CULT_AT_WAR_WITH_CHAINED",chainedWar and 1 or 0);
  local hangedDesired=nil; local hangedCombatAmount=0;
  if hangedWar and (hangedTier==1 or hangedTier==3) then hangedDesired,hangedCombatAmount=HangedToken(player,hangedTier); end
  -- Retire resource 111-114 permanent combat switches. Their OFF pair keeps
  -- old saves numerically neutral; removable Unit Abilities own live combat.
  RetireLegacySwitch(player,"HANGED_WAR");
  local hangedFaithDesired=nil; local hangedFaithAmount=0;
  if hangedWar and (hangedTier==1 or hangedTier==3) then hangedFaithDesired,hangedFaithAmount=HangedFaithToken(player,hangedTier); end
  ApplySwitch(player,"HANGED_FAITH",hangedFaithDesired);
  player:SetProperty("LOTM_CULT_HANGED_FAITH_PER_TURN",hangedFaithDesired~=nil and -hangedFaithAmount or 0);
  RetireLegacySwitch(player,"CHAINED_WAR");
  local chainedMove=nil; local chainedYield=nil; local chainedCombatAmount=0;
  if chainedWar then
   chainedMove=ChainedMoveToken(player,chainedTier);
   chainedYield=ChainedYieldToken(player,chainedTier);
   chainedCombatAmount=ChainedCombatAmount(player,chainedTier);
  end
  ApplySwitch(player,"CHAINED_MOVE",chainedMove);
  ApplySwitch(player,"CHAINED_YIELD",chainedYield);
  RefreshWarCombatAbilities(player,hangedCombatAmount,chainedCombatAmount);
  RefreshWarNotification(player,"HANGED_WAR",hangedDesired);
  -- A war relation alone is not an active effect. Tier scaling can truncate
  -- every integer effect to zero, or grant complete immunity.
  local chainedWarDesired=nil;
  if chainedWar and (chainedMove~=nil or chainedCombatAmount>0 or chainedYield~=nil) then chainedWarDesired="CHAINED_T"..tostring(chainedTier); end
  RefreshWarNotification(player,"CHAINED_WAR",chainedWarDesired);
  RefreshEffectAudit(player,hangedWar,hangedTier,hangedCombatAmount,chainedWar,chainedTier,chainedMove,chainedCombatAmount,chainedYield);
 end
end

function LOTM_AI_Cults.Reconcile()
 InitializeAssignments(); ReconcileTiers(); ReconcileEffects();
 Game.SetProperty("LOTM_CULT_STATE_VERSION",STATE_VERSION);
 if RescueActive() then
  if LOTM_AI_Cult_Hanged~=nil and LOTM_AI_Cult_Hanged.RetireForRescue~=nil then LOTM_AI_Cult_Hanged.RetireForRescue(); end
 elseif LOTM_AI_Cult_Hanged~=nil and LOTM_AI_Cult_Hanged.ReconcileAll~=nil then LOTM_AI_Cult_Hanged.ReconcileAll(); end
 -- Phase 7 owns a lowest-major synchronized network handler. Calling it from
 -- ResearchCompleted, diplomacy or UnitAdded callbacks can interleave its
 -- DynamicModifier allocation with native engine allocation on different
 -- peers. Single-player keeps the original immediate reconciliation path.
 if not LOTM_MP_TurnSync.IsNetworkGame() and LOTM_RESCUE_Phase7~=nil and LOTM_RESCUE_Phase7.ReconcileAll~=nil then LOTM_RESCUE_Phase7.ReconcileAll(); end
end

local function OnTurn(playerID,isFirstTimeThisTurn)
 if isFirstTimeThisTurn==false then return; end LOTM_AI_Cults.Reconcile();
end
local function OnResearchCompleted(playerID,techIndex,isCanceled)
 if LOTM_MP_TurnSync.IsNetworkGame() then return; end
 if isCanceled~=true then LOTM_AI_Cults.Reconcile(); end
end
-- Match the proven planned-war economy: diplomacy events refresh immediately,
-- while PlayerTurnActivated remains the authoritative fallback and settlement.
local function OnDiplomacyChanged()
 if LOTM_MP_TurnSync.IsNetworkGame() then return; end
 LOTM_AI_Cults.Reconcile();
end
local function OnUnitAddedToMap(playerID)
 if LOTM_MP_TurnSync.IsNetworkGame() then return; end
 if RescueActive() then return; end
 local player=Players[playerID]; if player~=nil and player:IsHuman() then LOTM_AI_Cults.Reconcile(); end
end

LOTM_MP_TurnSync.Add(OnTurn,"AICults");
Events.ResearchCompleted.Add(OnResearchCompleted);
Events.DiplomacyDeclareWar.Add(OnDiplomacyChanged);
Events.DiplomacyMakePeace.Add(OnDiplomacyChanged);
Events.UnitAddedToMap.Add(LOTM_UnitAddedPerf.Wrap("AICults",OnUnitAddedToMap));
LOTM_MP_TurnSync.RunStartup(LOTM_AI_Cults.Reconcile,"AICults");
Log("initialized stateVersion="..STATE_VERSION.." tiers=1..3 thresholds=5/14");
