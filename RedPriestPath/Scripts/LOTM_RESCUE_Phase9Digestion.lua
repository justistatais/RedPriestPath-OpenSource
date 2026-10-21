-- Rescue Mode Phase 9: confirmed Red Priest digestion override.
-- UI-only purchase/production observations arrive through validated
-- EXECUTE_SCRIPT commands; all actual state mutation remains in Gameplay.
LOTM_RESCUE_Phase9Digestion=LOTM_RESCUE_Phase9Digestion or {};

local VERSION=2;
local PATH="PATH_RED_PRIEST";
local GOLD_PURCHASE_COMMAND="LOTM_RESCUE_P9_Command_GoldMilitaryPurchase";
local TRAINED_COMMAND="LOTM_RESCUE_P9_Command_MilitaryTrained";
local META_PREFIX="LOTM_RESCUE_P9_UNIT_META:";
local DAMAGE_PREFIX="LOTM_RESCUE_P9_DAMAGE:";
local pendingNetworkObservations={};
local pendingNetworkObservationKeys={};

local function Log(message) print("[LOTM_RESCUE][Phase9Digestion] "..tostring(message)); end
local function Number(value,default) if value==nil then return default; end return tonumber(value) or default; end
local function Active() return Number(Game.GetProperty("LOTM_RESCUE_MODE"),0)==1; end
local function Player(playerID) return playerID~=nil and Players[playerID] or nil; end
local function Eligible(playerID,sequence)
 local player=Player(playerID);
 return Active() and player~=nil and player:IsAlive() and player:IsMajor() and player:IsHuman()
  and player:GetProperty("LOTM_RP_PATH")==PATH and Number(player:GetProperty("LOTM_RP_SEQUENCE"),9)==sequence;
end
local function Key(playerID,unitID,suffix) return suffix..tostring(playerID)..":"..tostring(unitID); end
local function ResolveUnitInfo(value)
 local info=GameInfo.Units[value]; if info~=nil then return info; end
 local numeric=tonumber(value); if numeric==nil then return nil; end
 for row in GameInfo.Units() do if row.Hash==numeric or row.Index==numeric then return row; end end
 return nil;
end
local function IsMilitaryInfo(info)
	return info~=nil and info.FormationClass~=nil and info.FormationClass~="FORMATION_CLASS_CIVILIAN";
end
local function IsLostControl(unit)
 if unit==nil then return false; end
 if Number(unit:GetProperty("LOTM_RESCUE_CENTER_MONSTER"),0)==1 or Number(unit:GetProperty("LOTM_PP_WORKSHOP_SEQUENCE"),0)==1 then return true; end
 return LOTM_WORLD_Monsters~=nil and LOTM_WORLD_Monsters.IsMonster~=nil and LOTM_WORLD_Monsters.IsMonster(unit);
end
local function WriteObservation(playerID,unitID,base,lost,damage)
 local baseKey=Key(playerID,unitID,META_PREFIX)..":BASE"; local lostKey=Key(playerID,unitID,META_PREFIX)..":LOST";
 if Number(Game.GetProperty(baseKey),nil)~=base then Game.SetProperty(baseKey,base); end
 if Number(Game.GetProperty(lostKey),nil)~=lost then Game.SetProperty(lostKey,lost); end
 local damageKey=Key(playerID,unitID,DAMAGE_PREFIX)..":SYNC_CURRENT";
 if damage~=nil and Number(Game.GetProperty(damageKey),nil)~=damage then Game.SetProperty(damageKey,damage); end
end
local function ObserveUnit(playerID,unitID)
 local unit=UnitManager.GetUnit(playerID,unitID); if unit==nil then return false; end
 WriteObservation(playerID,unitID,unit:GetCombat() or 0,IsLostControl(unit) and 1 or 0,unit:GetDamage() or 0);
 return true;
end
local function QueueNetworkObservation(playerID,unitID)
 local normalizedPlayerID=tonumber(playerID); local normalizedUnitID=tonumber(unitID);
 if normalizedPlayerID==nil or normalizedUnitID==nil then return; end
 local key=tostring(normalizedPlayerID)..":"..tostring(normalizedUnitID);
 if pendingNetworkObservationKeys[key]~=nil then return; end
 local unit=UnitManager.GetUnit(normalizedPlayerID,normalizedUnitID);
 local entry={PlayerID=normalizedPlayerID,UnitID=normalizedUnitID,
   QueuedTurn=Game.GetCurrentGameTurn(),Key=key,
   Base=unit~=nil and (unit:GetCombat() or 0) or nil,
   Lost=unit~=nil and (IsLostControl(unit) and 1 or 0) or nil,
   Damage=unit~=nil and (unit:GetDamage() or 0) or nil};
 pendingNetworkObservations[#pendingNetworkObservations+1]=entry;
 pendingNetworkObservationKeys[key]=entry;
end
local function ProcessNetworkObservations(playerID)
 if not LOTM_MP_TurnSync.IsNetworkGame()
  or not LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID) then return; end
 local currentTurn=Game.GetCurrentGameTurn(); local ready={}; local waiting={};
 for _,entry in ipairs(pendingNetworkObservations) do
  if entry.Cancelled==true then
   if pendingNetworkObservationKeys[entry.Key]==entry then pendingNetworkObservationKeys[entry.Key]=nil; end
  elseif entry.QueuedTurn<currentTurn then ready[#ready+1]=entry;
  else waiting[#waiting+1]=entry; end
 end
 pendingNetworkObservations=waiting;
 table.sort(ready,function(a,b)
  if a.PlayerID~=b.PlayerID then return a.PlayerID<b.PlayerID; end
  return a.UnitID<b.UnitID;
 end);
 for _,entry in ipairs(ready) do
  if pendingNetworkObservationKeys[entry.Key]==entry then pendingNetworkObservationKeys[entry.Key]=nil; end
  if not ObserveUnit(entry.PlayerID,entry.UnitID) and entry.Base~=nil then
   WriteObservation(entry.PlayerID,entry.UnitID,entry.Base,entry.Lost or 0,entry.Damage);
  end
 end
end

-- Synchronized death owners call this hook before clearing their durable
-- owner/unit identity.  It gives the later Phase 9 combat handler a stable
-- lost-control fact even when the defeated unit has already left UnitManager.
function LOTM_RESCUE_Phase9Digestion.RecordLostControlIdentity(playerID,unitID,base)
 if not Active() then return; end
 local baseKey=Key(playerID,unitID,META_PREFIX)..":BASE";
 local damageKey=Key(playerID,unitID,DAMAGE_PREFIX)..":SYNC_CURRENT";
 WriteObservation(playerID,unitID,
  Number(base,Number(Game.GetProperty(baseKey),0)),1,
  Number(Game.GetProperty(damageKey),0));
end
local function Defeated(playerID,unitID)
 local unit=UnitManager.GetUnit(playerID,unitID);
 return unitID~=nil and unitID>=0 and (unit==nil or unit:IsDead() or unit:IsDelayedDeath());
end
local function HeroWithin(playerID,x,y)
 local hero=LOTM_RP_State.FindHero(playerID);
 return hero~=nil and not hero:IsDead() and not hero:IsDelayedDeath()
  and Map.GetPlotDistance(hero:GetX(),hero:GetY(),x,y)<=6;
end
local function Add(playerID,category,eventKey)
 return LOTM_RP_State.TryAddDigestion(playerID,category,"RESCUE_P9:"..eventKey);
end

local function OnUnitDamageChanged(playerID,unitID,newDamage,oldDamage)
 if not Active() then return; end
 if LOTM_MP_TurnSync.IsNetworkGame() then
  -- Local publication order is not authoritative in multiplayer.  Synchronized
  -- combat below records post-combat damage and compares the next fight with
  -- that durable value; this callback therefore performs no state write and
  -- contributes no branch input.
  return;
 end
 ObserveUnit(playerID,unitID);
 local prefix=Key(playerID,unitID,DAMAGE_PREFIX);
 Game.SetProperty(prefix..":TURN",Game.GetCurrentGameTurn());
 Game.SetProperty(prefix..":OLD",Number(oldDamage,0));
 Game.SetProperty(prefix..":NEW",Number(newDamage,0));
end

local function OnCombat(attackerPlayerID,attackerUnitID,defenderPlayerID,defenderUnitID)
 if not Active() then return; end
 local network=LOTM_MP_TurnSync.IsNetworkGame();
 local defenderDamageKey=Key(defenderPlayerID,defenderUnitID,DAMAGE_PREFIX);
 local defenderDamageBefore=network and Number(Game.GetProperty(defenderDamageKey..":SYNC_CURRENT"),0) or 0;
 ObserveUnit(attackerPlayerID,attackerUnitID);
 ObserveUnit(defenderPlayerID,defenderUnitID);
 local serial=Number(Game.GetProperty("LOTM_RESCUE_P9_COMBAT_SERIAL"),0)+1;
 Game.SetProperty("LOTM_RESCUE_P9_COMBAT_SERIAL",serial);
 local attacker=UnitManager.GetUnit(attackerPlayerID,attackerUnitID);
 local defender=UnitManager.GetUnit(defenderPlayerID,defenderUnitID);
 local defeated=Defeated(defenderPlayerID,defenderUnitID);
 local sequence=LOTM_RP_State.IsEnabledPlayer(attackerPlayerID) and LOTM_RP_State.GetSequence(attackerPlayerID) or -1;

 if sequence==8 and attacker~=nil and attacker:GetID()==Number(Player(attackerPlayerID):GetProperty("LOTM_RP_UNIT_ID"),-1) then
  local lost=defender~=nil and IsLostControl(defender)
   or Number(Game.GetProperty(Key(defenderPlayerID,defenderUnitID,META_PREFIX)..":LOST"),0)==1;
  if lost then Add(attackerPlayerID,"A","S8_LOST_CONTROL_ATTACK:"..serial); end
  local attackerBase=attacker:GetCombat() or 0;
  local defenderBase=defender~=nil and (defender:GetCombat() or 0) or Number(Game.GetProperty(Key(defenderPlayerID,defenderUnitID,META_PREFIX)..":BASE"),0);
  if defenderBase>attackerBase then Add(attackerPlayerID,"B","S8_STRONGER_ATTACK:"..serial); end
 end

 if not defeated then
  return;
 end
 local killKey=tostring(Game.GetCurrentGameTurn())..":"..tostring(attackerUnitID)..":"..tostring(defenderPlayerID)..":"..tostring(defenderUnitID);
 if sequence==5 then
  Add(attackerPlayerID,"A","S5_KILL:"..killKey);
  local damagePrefix=Key(defenderPlayerID,defenderUnitID,DAMAGE_PREFIX);
  local woundedBefore=false;
  if network then woundedBefore=defenderDamageBefore>0;
  else
   local damageTurn=Number(Game.GetProperty(damagePrefix..":TURN"),-1);
   woundedBefore=damageTurn==Game.GetCurrentGameTurn() and Number(Game.GetProperty(damagePrefix..":OLD"),0)>0;
  end
  if woundedBefore then Add(attackerPlayerID,"B","S5_WOUNDED_KILL:"..killKey); end
 elseif sequence==4 and attacker~=nil and HeroWithin(attackerPlayerID,attacker:GetX(),attacker:GetY()) then
  Add(attackerPlayerID,"A","S4_KILL_WITHIN_6:"..killKey);
 elseif sequence==1 and attacker~=nil then
  -- The second-attack bookkeeping below awards the kill bonus after its base point.
 end

 if sequence==1 and attacker~=nil then
  local turn=Game.GetCurrentGameTurn();
  local attackTurn=Number(attacker:GetProperty("LOTM_RESCUE_P9_ATTACK_TURN"),-1);
  local count=attackTurn==turn and Number(attacker:GetProperty("LOTM_RESCUE_P9_ATTACK_COUNT"),0) or 0;
  count=count+1; attacker:SetProperty("LOTM_RESCUE_P9_ATTACK_TURN",turn); attacker:SetProperty("LOTM_RESCUE_P9_ATTACK_COUNT",count);
  if count==2 then
   Add(attackerPlayerID,"A","S1_SECOND_ATTACK:"..turn..":"..attackerUnitID);
   Add(attackerPlayerID,"B","S1_SECOND_ATTACK_KILL:"..killKey);
  end
 end
end

local function OnCombatCountAttack(attackerPlayerID,attackerUnitID,defenderPlayerID,defenderUnitID)
 if not Eligible(attackerPlayerID,1) then return; end
 local attacker=UnitManager.GetUnit(attackerPlayerID,attackerUnitID); if attacker==nil then return; end
 local turn=Game.GetCurrentGameTurn();
 local attackTurn=Number(attacker:GetProperty("LOTM_RESCUE_P9_ATTACK_TURN"),-1);
 local count=attackTurn==turn and Number(attacker:GetProperty("LOTM_RESCUE_P9_ATTACK_COUNT"),0) or 0;
 -- Kill events are counted in OnCombat so the base and kill point stay ordered.
 if Defeated(defenderPlayerID,defenderUnitID) then return; end
 count=count+1; attacker:SetProperty("LOTM_RESCUE_P9_ATTACK_TURN",turn); attacker:SetProperty("LOTM_RESCUE_P9_ATTACK_COUNT",count);
 if count==2 then Add(attackerPlayerID,"A","S1_SECOND_ATTACK:"..turn..":"..attackerUnitID); end
end

local function OnGoldMilitaryPurchase(playerID,parameters)
 if not Eligible(playerID,6) then return; end
 local info=ResolveUnitInfo(parameters~=nil and parameters.UnitType or nil);
 local spent=Number(parameters~=nil and parameters.GoldSpent or nil,0);
 local serial=tostring(parameters~=nil and parameters.Serial or "");
 if not IsMilitaryInfo(info) or spent<=0 or serial=="" then Log("rejected gold military purchase player="..tostring(playerID)); return; end
 Add(playerID,"A","S6_GOLD_MILITARY:"..serial..":"..info.UnitType);
end

local function OnMilitaryTrained(playerID,parameters)
 local sequence=LOTM_RP_State.IsEnabledPlayer(playerID) and LOTM_RP_State.GetSequence(playerID) or -1;
 if sequence~=6 and sequence~=3 then return; end
 local info=ResolveUnitInfo(parameters~=nil and parameters.UnitType or nil);
 local serial=tostring(parameters~=nil and parameters.Serial or "");
 if not IsMilitaryInfo(info) or serial=="" then Log("rejected military training player="..tostring(playerID)); return; end
	local eventName=sequence==6 and "S6_MILITARY_TRAINED:" or "S3_MILITARY_TRAINED:";
	Add(playerID,sequence==6 and "B" or "A",eventName..serial..":"..info.UnitType);
end

local baseLostControlKilled=LOTM_RESCUE_Phase6.OnLostControlKilled;
local function OnLostControlKilled(tier,killerPlayerID,killerUnitID,sourceKind,sourceSerial)
 local first,second=baseLostControlKilled(tier,killerPlayerID,killerUnitID,sourceKind,sourceSerial);
 if Eligible(killerPlayerID,2) then
  local numericTier=Number(tier,2); local token=tostring(sourceKind)..":"..tostring(sourceSerial);
  if numericTier==1 then Add(killerPlayerID,"A","S2_MID_KILL:"..token);
  elseif numericTier==0 then Add(killerPlayerID,"A","S2_HIGH_KILL_A:"..token); Add(killerPlayerID,"B","S2_HIGH_KILL_B:"..token); end
 end
 return first,second;
end
LOTM_RESCUE_Phase6.OnLostControlKilled=OnLostControlKilled;
LOTM_RESCUE_Phase4.OnLostControlKilled=OnLostControlKilled;

local baseWorkshopCleared=LOTM_RESCUE_Phase4.OnWorkshopCleared;
LOTM_RESCUE_Phase4.OnWorkshopCleared=function(level,clearerPlayerID,clearerUnitID,plotIndex,classificationTurn)
 local first,second=baseWorkshopCleared(level,clearerPlayerID,clearerUnitID,plotIndex,classificationTurn);
 if Eligible(clearerPlayerID,4) then
  local plot=Map.GetPlotByIndex(Number(plotIndex,-1));
  if plot~=nil and HeroWithin(clearerPlayerID,plot:GetX(),plot:GetY()) then
   Add(clearerPlayerID,"B","S4_WORKSHOP_WITHIN_6:"..tostring(plotIndex)..":"..tostring(classificationTurn));
  end
 end
 return first,second;
end

local function OnTurn(playerID,isFirstTimeThisTurn)
 if isFirstTimeThisTurn==false then return; end
 ProcessNetworkObservations(playerID);
end

local function OnUnitAdded(playerID,unitID)
 if not Active() then return; end
 if LOTM_MP_TurnSync.IsNetworkGame() then QueueNetworkObservation(playerID,unitID); return; end
 ObserveUnit(playerID,unitID);
end

local function OnUnitRemoved(playerID,unitID)
 local normalizedPlayerID=tonumber(playerID); local normalizedUnitID=tonumber(unitID);
 if normalizedPlayerID==nil or normalizedUnitID==nil then return; end
 local key=tostring(normalizedPlayerID)..":"..tostring(normalizedUnitID);
 local entry=pendingNetworkObservationKeys[key];
 if entry~=nil then
  entry.Cancelled=true;
  if pendingNetworkObservationKeys[key]==entry then pendingNetworkObservationKeys[key]=nil; end
 end
end

GameEvents.LOTM_RESCUE_P9_Command_GoldMilitaryPurchase.Add(OnGoldMilitaryPurchase);
GameEvents.LOTM_RESCUE_P9_Command_MilitaryTrained.Add(OnMilitaryTrained);
Events.UnitAddedToMap.Add(LOTM_UnitAddedPerf.Wrap("Phase9Digestion",OnUnitAdded));
Events.UnitRemovedFromMap.Add(OnUnitRemoved);
Events.UnitDamageChanged.Add(OnUnitDamageChanged);
GameEvents.OnCombatOccurred.Add(OnCombatCountAttack);
GameEvents.OnCombatOccurred.Add(OnCombat);
LOTM_MP_TurnSync.Add(OnTurn,"RescuePhase9DigestionRuntime");
LOTM_MP_TurnSync.RunStartup(function()
 if Active() then
  Game.SetProperty("LOTM_RESCUE_PHASE9_DIGESTION_VERSION",VERSION);
  Game.SetProperty("LOTM_RESCUE_PHASE9_DIGESTION_STATE","READY");
 end
end,"RescuePhase9Digestion");
Log("loaded version="..VERSION.." active="..tostring(Active()).." rangeRule=hex_distance_lte_6 metaWrites=changedOnly ordinaryMode=false");
