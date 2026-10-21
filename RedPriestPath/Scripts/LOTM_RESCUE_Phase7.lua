-- Rescue Mode Phase 7: cumulative positive support for AI cult civilizations.
-- Existing ordinary-mode cult penalties are retired by LOTM_AI_Cults while
-- rescue mode is active. Phase 8 targeting AI and Phase 10 Boss rules are out.
LOTM_RESCUE_Phase7=LOTM_RESCUE_Phase7 or {};

local VERSION=5;
local INCREMENTAL_MIGRATION_VERSION=2;
local INCREMENTAL_MIGRATION_KEY="LOTM_RESCUE_PHASE7_INCREMENTAL_MIGRATION_VERSION";
local ABILITY_SCHEMA_VERSION=1;
local UNIT_SIGNATURE_KEY="LOTM_RESCUE_PHASE7_ABILITY_SIGNATURE";
local CULTS={DEMONESS=true,HANGED_MAN=true,CHAINED=true};
local ABILITIES={
 HANGED_MAN={
  [1]="ABILITY_LOTM_RESCUE_P7_HANGED_T1_C10",
  [2]="ABILITY_LOTM_RESCUE_P7_HANGED_T2_C20",
  [3]="ABILITY_LOTM_RESCUE_P7_HANGED_T3_C40"
 },
 CHAINED={
  [1]="ABILITY_LOTM_RESCUE_P7_CHAINED_T1_M2",
  [2]="ABILITY_LOTM_RESCUE_P7_CHAINED_T2_M2_C20"
 }
};
local ABILITY_CULT_ORDER={"HANGED_MAN","CHAINED"};
local prefixCache={};
local unitIndexByPlayer={};
local pendingNetworkUnits={};
local pendingNetworkUnitKeys={};

local function Log(message) print("[LOTM_RESCUE][Phase7] "..tostring(message)); end
local function Number(value,default) if value==nil then return default; end return tonumber(value) or default; end
local function Active() return Number(Game.GetProperty("LOTM_RESCUE_MODE"),0)==1; end
local function Cult(player) local value=player~=nil and player:GetProperty("LOTM_CULT_PATH") or nil; return CULTS[value] and value or nil; end

local function PrefixIds(prefix)
 if prefixCache[prefix]~=nil then return prefixCache[prefix]; end
 local result={}; for row in GameInfo.Modifiers() do if string.sub(row.ModifierId,1,#prefix)==prefix then table.insert(result,row.ModifierId); end end
 table.sort(result); prefixCache[prefix]=result; return result;
end
local function AttachStage(player,cult,stage)
 local property="LOTM_RESCUE_PHASE7_APPLIED:"..cult..":"..stage;
 if Number(player:GetProperty(property),0)==1 then return; end
 local prefix="LOTM_RESCUE_P7_"..cult.."_T"..stage.."__";
 local ids=PrefixIds(prefix); for _,modifierID in ipairs(ids) do player:AttachModifierByID(modifierID); end
 player:SetProperty(property,1);
 Log("attached player="..player:GetID().." cult="..cult.." stage="..stage.." modifiers="..#ids);
end
local function SetAbility(unit,abilityType,desired)
 local abilities=unit~=nil and unit:GetAbility() or nil; if abilities==nil or GameInfo.UnitAbilities[abilityType]==nil then return; end
 local current=abilities:GetAbilityCount(abilityType) or 0; if current~=desired then abilities:ChangeAbilityCount(abilityType,desired-current); end
end
local function UnitIndex(playerID)
 local index=unitIndexByPlayer[playerID];
 if index==nil then index={ids={},order={}}; unitIndexByPlayer[playerID]=index; end
 return index;
end
local function TrackUnit(playerID,unitID)
 local index=UnitIndex(playerID); if index.ids[unitID] then return false; end
 index.ids[unitID]=true; index.order[#index.order+1]=unitID; return true;
end
local function UntrackUnit(playerID,unitID)
 local index=unitIndexByPlayer[playerID]; if index~=nil then index.ids[unitID]=nil; end
end
local function UnitSignature(cult,tier)
 return "v"..ABILITY_SCHEMA_VERSION..":"..tostring(cult)..":"..tostring(tier);
end
local function StampUnitTier(unit,cult,tier)
 unit:SetProperty(UNIT_SIGNATURE_KEY,UnitSignature(cult,tier));
end
local function ApplyUnitTier(unit,cult,tier)
 if unit==nil then return; end
 for _,abilityCult in ipairs(ABILITY_CULT_ORDER) do
  local cultAbilities=ABILITIES[abilityCult];
  for stage=1,#cultAbilities do
   SetAbility(unit,cultAbilities[stage],abilityCult==cult and stage<=tier and 1 or 0);
  end
 end
 StampUnitTier(unit,cult,tier);
end
local function ApplyIndexedTier(player,cult,tier)
 local index=UnitIndex(player:GetID()); local compact={}; local ordered={};
 for _,unitID in ipairs(index.order) do if index.ids[unitID] then ordered[#ordered+1]=unitID; end end
 table.sort(ordered);
 for _,unitID in ipairs(ordered) do
  if index.ids[unitID] then
  local unit=player:GetUnits():FindID(unitID);
   if unit~=nil then ApplyUnitTier(unit,cult,tier); compact[#compact+1]=unitID; else index.ids[unitID]=nil; end
  end
 end
 index.order=compact;
end
local function MigratePlayerUnits(player,cult,tier,stampOnly)
 unitIndexByPlayer[player:GetID()]={ids={},order={}};
 local units={};
 for _,unit in player:GetUnits():Members() do units[#units+1]=unit; end
 table.sort(units,function(a,b) return a:GetID()<b:GetID(); end);
 local count=0;
 for _,unit in ipairs(units) do
  TrackUnit(player:GetID(),unit:GetID());
  if stampOnly then StampUnitTier(unit,cult,tier); else ApplyUnitTier(unit,cult,tier); end
  count=count+1;
 end
 return count;
end
local function ReconcilePlayer(player,allowFullMigration,stampOnly)
 if player==nil or not player:IsAlive() or player:IsHuman() then return; end
 local cult=Cult(player); if cult==nil then return; end
 local tier=math.max(1,math.min(3,LOTM_AI_Cults.GetTier(cult)));
 for stage=1,tier do AttachStage(player,cult,stage); end
 local oldTier=Number(player:GetProperty("LOTM_RESCUE_PHASE7_TIER"),0);
 local oldCult=tostring(player:GetProperty("LOTM_RESCUE_PHASE7_CULT") or "NONE");
 if allowFullMigration then
  local count=MigratePlayerUnits(player,cult,tier,stampOnly);
  Log("signature migration player="..player:GetID().." cult="..cult.." tier="..tier.." units="..count.." mode="..(stampOnly and "STAMP_ONLY" or "APPLY"));
 elseif oldTier~=tier or oldCult~=cult then
  ApplyIndexedTier(player,cult,tier);
 end
 player:SetProperty("LOTM_RESCUE_PHASE7_TIER",tier);
 player:SetProperty("LOTM_RESCUE_PHASE7_CULT",cult);
end
function LOTM_RESCUE_Phase7.ReconcileAll()
 if not Active() then return false; end
 Game.SetProperty("LOTM_RESCUE_PHASE7_VERSION",VERSION);
 Game.SetProperty("LOTM_RESCUE_PHASE7_STATE","READY");
 local phase=Number(Game.GetProperty("LOTM_RESCUE_PHASE"),0); if phase<7 then Game.SetProperty("LOTM_RESCUE_PHASE",7); end
 local previousMigration=Number(Game.GetProperty(INCREMENTAL_MIGRATION_KEY),0);
 local migrate=previousMigration<INCREMENTAL_MIGRATION_VERSION;
 local stampOnly=previousMigration>=1;
 local players={};
 for _,player in ipairs(PlayerManager.GetAliveMajors()) do players[#players+1]=player; end
 table.sort(players,function(a,b) return a:GetID()<b:GetID(); end);
 for _,player in ipairs(players) do ReconcilePlayer(player,migrate,stampOnly); end
 if migrate then Game.SetProperty(INCREMENTAL_MIGRATION_KEY,INCREMENTAL_MIGRATION_VERSION); end
 if LOTM_AI_Cult_Hanged~=nil and LOTM_AI_Cult_Hanged.RetireForRescue~=nil then LOTM_AI_Cult_Hanged.RetireForRescue(); end
 return true;
end

local function QueueNetworkUnitAdded(playerID,unitID)
 local normalizedPlayerID=tonumber(playerID); local normalizedUnitID=tonumber(unitID);
 if normalizedPlayerID==nil or normalizedUnitID==nil then return; end
 local key=tostring(normalizedPlayerID)..":"..tostring(normalizedUnitID);
 if pendingNetworkUnitKeys[key]~=nil then return; end
 local entry={PlayerID=normalizedPlayerID,UnitID=normalizedUnitID,QueuedTurn=Game.GetCurrentGameTurn(),Key=key};
 pendingNetworkUnits[#pendingNetworkUnits+1]=entry; pendingNetworkUnitKeys[key]=entry;
end
local function ProcessNetworkUnitAdditions(playerID)
 if not LOTM_MP_TurnSync.IsNetworkGame() or not LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID) then return; end
 local currentTurn=Game.GetCurrentGameTurn(); local ready={}; local waiting={};
 for _,entry in ipairs(pendingNetworkUnits) do
  if entry.Cancelled~=true then
   if entry.QueuedTurn<currentTurn then ready[#ready+1]=entry; else waiting[#waiting+1]=entry; end
  end
 end
 pendingNetworkUnits=waiting;
 table.sort(ready,function(a,b) if a.PlayerID~=b.PlayerID then return a.PlayerID<b.PlayerID; end return a.UnitID<b.UnitID; end);
 local applied=0;
 for _,entry in ipairs(ready) do
   if pendingNetworkUnitKeys[entry.Key]==entry then pendingNetworkUnitKeys[entry.Key]=nil; end
   local player=Players[entry.PlayerID];
   if player~=nil and player:IsAlive() and not player:IsHuman() then
    local cult=Cult(player);
    if cult~=nil then
     local unit=UnitManager.GetUnit(entry.PlayerID,entry.UnitID);
     if unit~=nil then
      TrackUnit(entry.PlayerID,entry.UnitID);
      local tier=math.max(1,math.min(3,LOTM_AI_Cults.GetTier(cult)));
      if tostring(unit:GetProperty(UNIT_SIGNATURE_KEY) or "")~=UnitSignature(cult,tier) then ApplyUnitTier(unit,cult,tier); applied=applied+1; end
     end
    end
   end
 end
 if applied>0 then Log("applied deferred unit abilities turn="..currentTurn.." units="..applied); end
end
local function OnUnitAdded(playerID,unitID)
 if not Active() then return; end
 local player=Players[playerID]; if player==nil or player:IsHuman() or Cult(player)==nil then return; end
 if LOTM_MP_TurnSync.IsNetworkGame() then
  TrackUnit(playerID,unitID); QueueNetworkUnitAdded(playerID,unitID); return;
 end
 local unit=UnitManager.GetUnit(playerID,unitID); if unit==nil then return; end
 local cult=Cult(player); local tier=math.max(1,math.min(3,LOTM_AI_Cults.GetTier(cult)));
 if not TrackUnit(playerID,unitID) then return; end
 if tostring(unit:GetProperty(UNIT_SIGNATURE_KEY) or "")~=UnitSignature(cult,tier) then ApplyUnitTier(unit,cult,tier); end
end
local function OnUnitRemoved(playerID,unitID)
 local normalizedPlayerID=tonumber(playerID); local normalizedUnitID=tonumber(unitID);
 local key=normalizedPlayerID~=nil and normalizedUnitID~=nil and tostring(normalizedPlayerID)..":"..tostring(normalizedUnitID) or nil;
 local entry=key~=nil and pendingNetworkUnitKeys[key] or nil;
 if entry~=nil then
  entry.Cancelled=true;
  if pendingNetworkUnitKeys[key]==entry then pendingNetworkUnitKeys[key]=nil; end
 end
 UntrackUnit(playerID,unitID);
end
Events.UnitAddedToMap.Add(LOTM_UnitAddedPerf.Wrap("Phase7",OnUnitAdded));
Events.UnitRemovedFromMap.Add(OnUnitRemoved);
local function LowestAliveMajorID()
 local ids=PlayerManager.GetAliveMajorIDs(); table.sort(ids);
 return ids[1];
end
local function OnSynchronizedPlayerTurnStarted(playerID)
 if playerID==LowestAliveMajorID() then LOTM_RESCUE_Phase7.ReconcileAll(); ProcessNetworkUnitAdditions(playerID); end
end
LOTM_MP_TurnSync.AddSynchronized(OnSynchronizedPlayerTurnStarted,"RescuePhase7Runtime");
Log("loaded version="..VERSION.." active="..tostring(Active()).." startupAttach=deferredToSynchronizedTurn unitUpdates=singlePlayerImmediate/networkNextFullTurnSorted fullScan=migrationOnly persistentSignature=v"..ABILITY_SCHEMA_VERSION.." doubled=true inherited=true phase8AI=false bossFormula=false");
