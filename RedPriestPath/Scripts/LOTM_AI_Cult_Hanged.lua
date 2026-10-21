-- Hanged Man flesh-puppet equivalent replacements. No unit is killed or
-- rebuilt: a newly created current-baseline melee unit keeps its model,
-- experience, promotions, formation and AI mission, while receiving a fixed
-- +10/+20 ability, synchronized properties, name and UI emblem.
LOTM_AI_Cult_Hanged = LOTM_AI_Cult_Hanged or {};

local ABILITY_10="ABILITY_LOTM_CULT_FLESH_PUPPET_10";
local ABILITY_20="ABILITY_LOTM_CULT_FLESH_PUPPET_20";
local SOURCE_PROPERTY="LOTM_CULT_SOURCE_CULT";
local TIER_PROPERTY="LOTM_CULT_TIER_AT_CREATE";
local BASELINE_PROPERTY="LOTM_CULT_BASELINE_MELEE_STRENGTH";
local pendingNetworkUnits={};
local pendingNetworkUnitKeys={};
local pendingRemovedUnits={};
local INDEX_KEY="LOTM_CULT_HANGED_PUPPET_IDS";
local INDEX_VERSION_KEY="LOTM_CULT_HANGED_PUPPET_INDEX_VERSION";

local function Log(message) print("[LOTM_CULT][Hanged] "..tostring(message)); end
local function Number(value,default) if value==nil then return default; end return tonumber(value) or default; end
local function RescueActive()
 return LOTM_MP_TurnSync.IsRescueModeConfigured()
  or Number(Game.GetProperty("LOTM_RESCUE_MODE"),0)==1;
end
local function IsFormalHuman(player)
 return player~=nil and LOTM_RP_State~=nil and LOTM_RP_State.IsAnyPathPlayer~=nil
  and LOTM_RP_State.IsAnyPathPlayer(player:GetID());
end
local function IsPuppet(unit) return unit~=nil and unit:GetProperty(SOURCE_PROPERTY)=="HANGED_MAN"; end
local function AliveMajors()
 local result={}; for _,player in ipairs(PlayerManager.GetAliveMajors()) do result[#result+1]=player; end
 table.sort(result,function(a,b) return a:GetID()<b:GetID(); end); return result;
end
local function SortedUnits(player)
 local result={}; if player==nil then return result; end
 for _,unit in player:GetUnits():Members() do result[#result+1]=unit; end
 table.sort(result,function(a,b) return a:GetID()<b:GetID(); end); return result;
end
local function PuppetIDs(player)
 local ids={}; local seen={};
 for token in string.gmatch(tostring(player:GetProperty(INDEX_KEY) or ""),"%d+") do
  local id=tonumber(token); if not seen[id] then ids[#ids+1]=id; seen[id]=true; end
 end
 table.sort(ids); return ids;
end
local function SavePuppetIDs(player,ids)
 table.sort(ids); local values={}; for _,id in ipairs(ids) do values[#values+1]=tostring(id); end
 local value=table.concat(values,",");
 if player:GetProperty(INDEX_KEY)~=value then player:SetProperty(INDEX_KEY,value); end
end
local function TrackPuppet(player,unit)
 local ids=PuppetIDs(player);
 for _,id in ipairs(ids) do if id==unit:GetID() then return; end end
 ids[#ids+1]=unit:GetID(); SavePuppetIDs(player,ids);
end
local function IsBaselineType(unitType,baselineIndex)
 if unitType==baselineIndex then return true; end
 -- A civilization's unique replacement is the same melee tier, rather than
 -- a different ranged/cavalry candidate. Keep its actual model and identity.
 local info=GameInfo.Units[unitType];
 if info==nil or info.PromotionClass~="PROMOTION_CLASS_MELEE" or GameInfo.UnitReplaces==nil then return false; end
 local baseline=GameInfo.Units[baselineIndex];
 for row in GameInfo.UnitReplaces() do
  if row.CivUniqueUnitType==info.UnitType and baseline~=nil and row.ReplacesUnitType==baseline.UnitType then return true; end
 end
 return false;
end

local function SetAbility(unit,abilityType,desired)
 local abilities=unit~=nil and unit:GetAbility() or nil; if abilities==nil then return; end
 local current=abilities:GetAbilityCount(abilityType) or 0; if current~=desired then abilities:ChangeAbilityCount(abilityType,desired-current); end
end
local function ApplyTier(unit,tier)
 if unit==nil or not IsPuppet(unit) then return; end
 SetAbility(unit,ABILITY_10,tier==2 and 1 or 0); SetAbility(unit,ABILITY_20,tier==3 and 1 or 0);
 unit:SetProperty("LOTM_CULT_FLESH_PUPPET_ACTIVE_TIER",tier);
 local experience=unit:GetExperience(); if experience~=nil then
  local veteranName=LOTM_MP_TurnSync.IsNetworkGame() and ("LOTM_CULT_FLESH_PUPPET_"..tostring(tier))
   or Locale.Lookup("LOC_UNIT_LOTM_CULT_FLESH_PUPPET_NAME");
  experience:SetVeteranName(veteranName);
 end
end

local function CaptureNewUnit(playerID,unitID)
 if RescueActive() then return; end
 local player=Players[playerID]; if player==nil or player:IsHuman() or not player:IsAlive() or not player:IsMajor() then return; end
 if LOTM_AI_Cults.GetPlayerCult(playerID)~="HANGED_MAN" then return; end
 local tier=LOTM_AI_Cults.GetTier("HANGED_MAN"); if tier~=2 and tier~=3 then return; end
 local unit=UnitManager.GetUnit(playerID,unitID); if unit==nil then return; end
 local baseline=LOTM_WORLD_Barbarians.ResolveMeleeBaseline(playerID);
 if baseline==nil then return; end
 if not IsPuppet(unit) and unit:GetType()~=baseline.Index and not IsBaselineType(unit:GetType(),baseline.Index) then return; end
 return {PlayerID=playerID,UnitID=unitID,UnitType=unit:GetType(),TierAtCreate=tier,
  BaselineIndex=baseline.Index,BaselineCombat=baseline.Combat,BaselineUnitType=baseline.UnitType};
end
local function ApplyCapturedNewUnit(entry)
 if entry==nil or RescueActive() then return; end
 local player=Players[entry.PlayerID];
 local unit=player~=nil and UnitManager.GetUnit(entry.PlayerID,entry.UnitID) or nil;
 if player==nil or unit==nil or player:IsHuman() or not player:IsAlive() or not player:IsMajor()
  or LOTM_AI_Cults.GetPlayerCult(entry.PlayerID)~="HANGED_MAN" or unit:GetType()~=entry.UnitType
  or (not IsPuppet(unit) and not IsBaselineType(entry.UnitType,entry.BaselineIndex)) then return; end
 if IsPuppet(unit) then TrackPuppet(player,unit); ApplyTier(unit,LOTM_AI_Cults.GetTier("HANGED_MAN")); return; end
 unit:SetProperty(SOURCE_PROPERTY,"HANGED_MAN"); unit:SetProperty(TIER_PROPERTY,entry.TierAtCreate);
 unit:SetProperty(BASELINE_PROPERTY,entry.BaselineCombat);
 unit:SetProperty("LOTM_CULT_BASELINE_MELEE_UNIT_TYPE",entry.BaselineUnitType);
 TrackPuppet(player,unit);
 local activeTier=LOTM_AI_Cults.GetTier("HANGED_MAN");
 if activeTier==2 or activeTier==3 then ApplyTier(unit,activeTier); end
 Log("marked player="..entry.PlayerID.." unit="..entry.UnitID.." baseline="
  ..tostring(entry.BaselineUnitType)..":"..tostring(entry.BaselineCombat)
  .." tierAtCreate="..tostring(entry.TierAtCreate).." activeTier="..tostring(activeTier));
end
local function ApplyNewUnit(playerID,unitID)
 ApplyCapturedNewUnit(CaptureNewUnit(playerID,unitID));
end
local function QueueNetworkUnitInitialized(playerID,unitID)
 local normalizedPlayerID=tonumber(playerID); local normalizedUnitID=tonumber(unitID);
 if normalizedPlayerID==nil or normalizedUnitID==nil then return; end
 local captured=CaptureNewUnit(normalizedPlayerID,normalizedUnitID); if captured==nil then return; end
 local key=tostring(normalizedPlayerID)..":"..tostring(normalizedUnitID);
 if pendingNetworkUnitKeys[key]~=nil then return; end
 local entry=captured; entry.QueuedTurn=Game.GetCurrentGameTurn(); entry.Key=key;
 pendingNetworkUnits[#pendingNetworkUnits+1]=entry; pendingNetworkUnitKeys[key]=entry;
end
local function ProcessNetworkUnitInitializations(playerID)
 local network=LOTM_MP_TurnSync.IsNetworkGame();
 if network and not LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID) then return; end
 local currentTurn=Game.GetCurrentGameTurn(); local ready={}; local waiting={};
 for _,entry in ipairs(pendingNetworkUnits) do
  if entry.Cancelled==true then
   if pendingNetworkUnitKeys[entry.Key]==entry then pendingNetworkUnitKeys[entry.Key]=nil; end
  elseif (network and entry.QueuedTurn<currentTurn)
   or (not network and entry.PlayerID==playerID) then ready[#ready+1]=entry; else waiting[#waiting+1]=entry; end
 end
 pendingNetworkUnits=waiting;
 table.sort(ready,function(a,b)
  if a.PlayerID~=b.PlayerID then return a.PlayerID<b.PlayerID; end
  return a.UnitID<b.UnitID;
 end);
 for _,entry in ipairs(ready) do
  if pendingNetworkUnitKeys[entry.Key]==entry then pendingNetworkUnitKeys[entry.Key]=nil; end
  ApplyCapturedNewUnit(entry);
 end
end
local function TryMarkNewUnit(playerID,unitID)
 if RescueActive() then return; end
 if LOTM_MP_TurnSync.IsNetworkGame() then QueueNetworkUnitInitialized(playerID,unitID); return; end
 ApplyNewUnit(playerID,unitID);
end

function LOTM_AI_Cult_Hanged.ReconcileAll()
 if RescueActive() then return; end
 local tier=LOTM_AI_Cults.GetTier("HANGED_MAN");
 for _,player in ipairs(AliveMajors()) do
  if not player:IsHuman() and LOTM_AI_Cults.GetPlayerCult(player:GetID())=="HANGED_MAN" then
   if Number(player:GetProperty(INDEX_VERSION_KEY),0)<1 then
    -- One bounded repair for old saves: recover omitted current-baseline
    -- units and index existing puppets. Ordinary callbacks never rescan armies.
    for _,unit in ipairs(SortedUnits(player)) do
     if IsPuppet(unit) then TrackPuppet(player,unit);
     elseif tier==2 or tier==3 then ApplyNewUnit(player:GetID(),unit:GetID()); end
    end
    player:SetProperty(INDEX_VERSION_KEY,1);
    Log("index repaired player="..player:GetID().." tier="..tier.." ids="..tostring(player:GetProperty(INDEX_KEY) or ""));
   end
   if (tier==2 or tier==3) and Number(player:GetProperty("LOTM_CULT_HANGED_PUPPET_TIER_SYNC"),0)~=tier then
    local living={};
    for _,id in ipairs(PuppetIDs(player)) do
     local unit=UnitManager.GetUnit(player:GetID(),id);
     if IsPuppet(unit) then living[#living+1]=id; ApplyTier(unit,tier); end
    end
    SavePuppetIDs(player,living); player:SetProperty("LOTM_CULT_HANGED_PUPPET_TIER_SYNC",tier);
   end
  end
 end
end

function LOTM_AI_Cult_Hanged.RetireForRescue()
 if not RescueActive() then return; end
 for _,player in ipairs(AliveMajors()) do
  if not player:IsHuman() then for _,unit in ipairs(SortedUnits(player)) do if IsPuppet(unit) then
   SetAbility(unit,ABILITY_10,0); SetAbility(unit,ABILITY_20,0);
   unit:SetProperty(SOURCE_PROPERTY,nil); unit:SetProperty("LOTM_CULT_FLESH_PUPPET_ACTIVE_TIER",0);
  end end end
 end
end

local function OnTurn(playerID,isFirstTimeThisTurn)
 if isFirstTimeThisTurn==false or RescueActive() then return; end
 ProcessNetworkUnitInitializations(playerID);
 if LOTM_MP_TurnSync.IsNetworkGame() and not LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID) then return; end
 table.sort(pendingRemovedUnits,function(a,b)
  if a.PlayerID~=b.PlayerID then return a.PlayerID<b.PlayerID; end
  return a.UnitID<b.UnitID;
 end);
 for _,entry in ipairs(pendingRemovedUnits) do
  local player=Players[entry.PlayerID];
  if player~=nil and UnitManager.GetUnit(entry.PlayerID,entry.UnitID)==nil then
   local living={}; for _,id in ipairs(PuppetIDs(player)) do if id~=entry.UnitID then living[#living+1]=id; end end
   if player:GetProperty(INDEX_KEY)~=nil then SavePuppetIDs(player,living); end
  end
 end
 pendingRemovedUnits={};
end

local function OnUnitRemoved(playerID,unitID)
 local key=tonumber(playerID)~=nil and tonumber(unitID)~=nil
  and tostring(tonumber(playerID))..":"..tostring(tonumber(unitID)) or nil;
 local entry=key~=nil and pendingNetworkUnitKeys[key] or nil;
 if entry~=nil then
  entry.Cancelled=true;
  if pendingNetworkUnitKeys[key]==entry then pendingNetworkUnitKeys[key]=nil; end
 end
 if key~=nil and not RescueActive() then pendingRemovedUnits[#pendingRemovedUnits+1]={PlayerID=tonumber(playerID),UnitID=tonumber(unitID)}; end
end

local function SettleAttackFaith(attackerPlayerID,defenderPlayerID,defenderUnitID)
 if RescueActive() then return; end
 local defender=UnitManager.GetUnit(defenderPlayerID,defenderUnitID); if not IsPuppet(defender) then return; end
 local attacker=Players[attackerPlayerID]; if not IsFormalHuman(attacker) then return; end
 local tier=LOTM_AI_Cults.GetTier("HANGED_MAN"); if tier~=2 and tier~=3 then return; end
 local base=tier==2 and 10 or 20; local targetTier=LOTM_AI_Cults.GetTargetTier(attacker); local amount=math.floor(base*LOTM_AI_Cults.GetMultiplier(tier,targetTier)+0.000001); if amount<=0 then return; end
 local religion=attacker:GetReligion(); if religion==nil then return; end local balance=Number(religion:GetFaithBalance(),0); religion:ChangeFaithBalance(-math.min(balance,amount));
 attacker:SetProperty("LOTM_CULT_FLESH_PUPPET_LAST_ATTACK_TURN",Game.GetCurrentGameTurn()); attacker:SetProperty("LOTM_CULT_FLESH_PUPPET_LAST_ATTACK_TARGET",tostring(defenderPlayerID)..":"..tostring(defenderUnitID));
 Log("attack faith attacker="..attackerPlayerID.." defender="..defenderPlayerID..":"..defenderUnitID.." amount="..amount.." tier="..tier);
end

local function OnCombat(attackerPlayerID,attackerUnitID,defenderPlayerID,defenderUnitID)
 -- The combat event fires only for the active attacker. This includes unit and
 -- city ranged attacks; a puppet attacking the player has the arguments
 -- reversed and therefore never charges faith.
 SettleAttackFaith(attackerPlayerID,defenderPlayerID,defenderUnitID);
end

GameEvents.UnitInitialized.Add(TryMarkNewUnit);
-- UnitInitialized can arrive before the native object is queryable. The map
-- publication captures facts only; a synchronized turn owns the fallback.
Events.UnitAddedToMap.Add(QueueNetworkUnitInitialized);
Events.UnitRemovedFromMap.Add(OnUnitRemoved);
GameEvents.OnCombatOccurred.Add(OnCombat);
LOTM_MP_TurnSync.Add(OnTurn,"AICultHanged");
LOTM_MP_TurnSync.RunStartup(LOTM_AI_Cult_Hanged.ReconcileAll,"AICultHanged");
Log("initialized equivalent replacement bonus=10/20");
