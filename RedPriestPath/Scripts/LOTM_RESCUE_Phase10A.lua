-- Rescue Mode Phase 10A: synchronized endgame measurement and descent gate.
-- This deliberately does not generate gods/Boss units or invent balance values.
LOTM_RESCUE_Phase10A=LOTM_RESCUE_Phase10A or {};

local VERSION=6;
-- Legacy measurement markers retained for compatibility: local VERSION=4; local total=skillReady and math.floor(rawTotal/10) or 0; SetChanged(player,"LOTM_RESCUE_PHASE10A_DIVINE_LEGION_RAW_TOTAL",rawTotal); SetChanged(player,"LOTM_RESCUE_PHASE10A_DIVINE_LEGION_BREAKDOWN",breakdown)
local PATH_NONE="NONE";
local GOD_UNIT_PROPERTY="LOTM_RESCUE_PHASE10_IS_GOD";
local MAX_BREAKDOWN_LENGTH=3500;
local RELIC_PROJECT="PROJECT_LOTM_RESCUE_WAR_GOD_RELIC";
local RELIC_UNLOCK_MODIFIER="LOTM_RESCUE_P10_ALLOW_WAR_GOD_RELIC";
local m_pendingNetworkProjectCompletions={};
local m_pendingNetworkProjectCompletionKeys={};
local SACRIFICE_COMMAND="LOTM_RESCUE_Command_Sacrifice";

local function Log(message) print("[LOTM_RESCUE][Phase10A] "..tostring(message)); end
local function Number(value,default) if value==nil then return default; end return tonumber(value) or default; end
local function Active() return Number(Game.GetProperty("LOTM_RESCUE_MODE"),0)==1; end
local function SetChanged(owner,key,value)
 if owner:GetProperty(key)~=value then owner:SetProperty(key,value); end
end

local function ChurchEnvoys(player,church)
 return math.max(0,Number(player:GetProperty("LOTM_CHURCH_"..church.."_ENVOYS"),0));
end

local function ReconcileWarGodRelic(player)
 if player==nil or not player:IsAlive() or not player:IsMajor() or not player:IsHuman() then return false; end
 local fool=ChurchEnvoys(player,"FOOL"); local night=ChurchEnvoys(player,"NIGHT"); local storm=ChurchEnvoys(player,"STORM");
 local qualified=fool>=6 and night>=6 and storm>=6;
 if qualified and Number(player:GetProperty("LOTM_RESCUE_WAR_GOD_RELIC_UNLOCK_ATTACHED"),0)~=1 then
  player:AttachModifierByID(RELIC_UNLOCK_MODIFIER);
  player:SetProperty("LOTM_RESCUE_WAR_GOD_RELIC_UNLOCK_ATTACHED",1);
  player:SetProperty("LOTM_RESCUE_WAR_GOD_RELIC_STATE","PROJECT_AVAILABLE");
  Log("warGodRelic unlocked player="..player:GetID().." envoys="..fool.."/"..night.."/"..storm);
 end
 SetChanged(player,"LOTM_RESCUE_WAR_GOD_RELIC_REQUIREMENT_MET",qualified and 1 or 0);
 return qualified;
end

function LOTM_RESCUE_Phase10A.OnChurchEnvoysChanged(playerID)
 if not Active() then return false; end
 return ReconcileWarGodRelic(Players[playerID]);
end

local function IsMilitaryCombatUnit(unit)
 if unit==nil or unit:IsDead() or unit:IsDelayedDeath() then return false; end
 if Number(unit:GetProperty(GOD_UNIT_PROPERTY),0)==1 then return false; end
 local info=GameInfo.Units[unit:GetType()]; if info==nil then return false; end
 -- Modded heroes and other special military actors do not always use one of
 -- Firaxis' three standard combat FormationClass values. Runtime combat is
 -- the authoritative eligibility test; divine units remain explicitly
 -- excluded above so the bonus can never count or sacrifice itself.
 return math.max(Number(unit:GetCombat(),0),Number(unit:GetRangedCombat(),0),Number(unit:GetBombardCombat(),0))>0;
end

local function EffectiveStrength(unit)
 -- Runtime getters include the unit's current formation, promotions and
 -- persistent Ability/Modifier changes, while excluding combat-preview-only
 -- terrain, target, attack/defence and other contextual modifiers.
 return math.max(Number(unit:GetCombat(),0),Number(unit:GetRangedCombat(),0),Number(unit:GetBombardCombat(),0));
end

local function BuildBreakdown(player)
 local rows={}; local total=0; local count=0;
 for _,unit in player:GetUnits():Members() do
  if IsMilitaryCombatUnit(unit) then
   local strength=EffectiveStrength(unit); local info=GameInfo.Units[unit:GetType()];
   count=count+1; total=total+strength;
   table.insert(rows,{id=unit:GetID(),text=tostring(info.UnitType).."#"..tostring(unit:GetID()).."="..tostring(strength)});
  end
 end
 table.sort(rows,function(left,right) return left.id<right.id; end);
 local parts={}; for _,row in ipairs(rows) do table.insert(parts,row.text); end
 local breakdown=table.concat(parts,";");
 if string.len(breakdown)>MAX_BREAKDOWN_LENGTH then breakdown=string.sub(breakdown,1,MAX_BREAKDOWN_LENGTH)..";TRUNCATED"; end
 return total,count,breakdown,rows;
end

local function PublishSchedule()
 local worldTurn=LOTM_RESCUE_Phase5.WorldTurn(); local finalTurn=LOTM_RESCUE_Phase5.FinalTurn();
 SetChanged(Game,"LOTM_RESCUE_PHASE10A_VERSION",VERSION);
 SetChanged(Game,"LOTM_RESCUE_PHASE10A_WORLD_TURN",worldTurn);
 SetChanged(Game,"LOTM_RESCUE_PHASE10A_FINAL_TURN",finalTurn);
 SetChanged(Game,"LOTM_RESCUE_PHASE10A_TURNS_REMAINING",math.max(0,finalTurn-worldTurn));
 SetChanged(Game,"LOTM_RESCUE_PHASE10A_PURIFICATION_PREVIEW",Number(Game.GetProperty("GLOBAL_PURIFICATION"),0));
 if worldTurn>=finalTurn then
  SetChanged(Game,"LOTM_RESCUE_PHASE10A_DESCENT_DUE",1);
  SetChanged(Game,"LOTM_RESCUE_PHASE10A_STATE","BALANCE_DATA_REQUIRED");
  SetChanged(Game,"LOTM_RESCUE_PHASE10A_BOSS_GENERATED",0);
 else
  SetChanged(Game,"LOTM_RESCUE_PHASE10A_DESCENT_DUE",0);
  SetChanged(Game,"LOTM_RESCUE_PHASE10A_STATE","MEASUREMENT_READY");
 end
 return worldTurn,finalTurn;
end

local function RefreshPlayer(playerID)
 if not Active() then return false; end
 local player=Players[playerID];
 if player==nil or not player:IsAlive() or not player:IsMajor() or not player:IsHuman() then return false; end
 ReconcileWarGodRelic(player);
 local skillReady=Number(player:GetProperty("LOTM_RESCUE_WAR_GOD_RELIC_COMPLETED"),0)==1;
 local sacrificed=math.max(0,Number(player:GetProperty("LOTM_RESCUE_PHASE10A_DIVINE_LEGION_SACRIFICED_TOTAL"),0));
 local count=math.max(0,Number(player:GetProperty("LOTM_RESCUE_PHASE10A_DIVINE_LEGION_SACRIFICE_COUNT"),0));
 local total=skillReady and sacrificed or 0;
 local previous=Number(player:GetProperty("LOTM_RESCUE_PHASE10A_DIVINE_LEGION_TOTAL"),-1);
 local path=tostring(player:GetProperty("LOTM_RP_PATH") or PATH_NONE);
 local sequence=Number(player:GetProperty("LOTM_RP_SEQUENCE"),9);
 local qualified=path~=PATH_NONE and sequence<=0;
 SetChanged(player,"LOTM_RESCUE_PHASE10A_DIVINE_LEGION_TOTAL",total);
 SetChanged(player,"LOTM_RESCUE_PHASE10A_DIVINE_LEGION_RAW_TOTAL",sacrificed*10);
 SetChanged(player,"LOTM_RESCUE_PHASE10A_DIVINE_LEGION_INHERIT_DIVISOR",10);
 SetChanged(player,"LOTM_RESCUE_PHASE10A_DIVINE_LEGION_COUNT",count);
 SetChanged(player,"LOTM_RESCUE_PHASE10A_DIVINE_LEGION_BREAKDOWN",tostring(player:GetProperty("LOTM_RESCUE_PHASE10A_DIVINE_LEGION_SACRIFICE_LOG") or ""));
 SetChanged(player,"LOTM_RESCUE_PHASE10A_DIVINE_LEGION_QUALIFIED",qualified and skillReady and 1 or 0);
 SetChanged(player,"LOTM_RESCUE_PHASE10A_PLAYER_GOD_STATE",not qualified and "NOT_SEQUENCE_ZERO" or skillReady and "DIVINE_LEGION_READY" or "WAR_GOD_RELIC_REQUIRED");
 if previous~=total then
  Log("divineLegion player="..tostring(playerID).." path="..path.." sequence="..tostring(sequence).." sacrificedRaw="..tostring(sacrificed*10).." inherited="..tostring(total).." divisor=10 skillReady="..tostring(skillReady).." sacrifices="..tostring(count));
 end
 return true;
end

local function SacrificeUnit(ownerID,unitID)
 if not Active() then return false; end
 local player=Players[ownerID]; local unit=player~=nil and player:GetUnits():FindID(unitID) or nil;
 local path=player~=nil and tostring(player:GetProperty("LOTM_RP_PATH") or PATH_NONE) or PATH_NONE;
 local sequence=player~=nil and Number(player:GetProperty("LOTM_RP_SEQUENCE"),9) or 9;
 if player==nil or not player:IsHuman() or path==PATH_NONE or sequence>0 or Number(player:GetProperty("LOTM_RESCUE_WAR_GOD_RELIC_COMPLETED"),0)~=1 then return false; end
 if not IsMilitaryCombatUnit(unit) then Log("sacrifice rejected player="..ownerID.." unit="..unitID.." reason=NOT_MILITARY"); return false; end
 local strength=EffectiveStrength(unit); if strength<=0 then return false; end
 local gain=math.floor(strength/10); local before=Number(player:GetProperty("LOTM_RESCUE_PHASE10A_DIVINE_LEGION_SACRIFICED_TOTAL"),0);
 local count=Number(player:GetProperty("LOTM_RESCUE_PHASE10A_DIVINE_LEGION_SACRIFICE_COUNT"),0)+1;
 local serial="LOTM_RESCUE_SACRIFICE:"..ownerID..":"..unitID..":"..Game.GetCurrentGameTurn();
 if Number(player:GetProperty(serial),0)==1 then return false; end
 local ok=pcall(UnitManager.Kill,unit); if not ok then return false; end
 player:SetProperty(serial,1); player:SetProperty("LOTM_RESCUE_PHASE10A_DIVINE_LEGION_SACRIFICED_TOTAL",before+gain); player:SetProperty("LOTM_RESCUE_PHASE10A_DIVINE_LEGION_SACRIFICE_COUNT",count);
 local oldLog=tostring(player:GetProperty("LOTM_RESCUE_PHASE10A_DIVINE_LEGION_SACRIFICE_LOG") or ""); local row=tostring(unitID).."="..tostring(strength).."/10="..tostring(gain);
 player:SetProperty("LOTM_RESCUE_PHASE10A_DIVINE_LEGION_SACRIFICE_LOG",string.sub(oldLog..(oldLog=="" and "" or ";")..row,1,MAX_BREAKDOWN_LENGTH));
 Log("sacrifice committed player="..ownerID.." unit="..unitID.." strength="..strength.." gain="..gain.." total="..(before+gain)); RefreshPlayer(ownerID); return true;
end

GameEvents.LOTM_RESCUE_Command_Sacrifice.Add(function(ownerID,unitID,parameters) return SacrificeUnit(ownerID,unitID); end);

local function ApplyCityProjectCompleted(playerID,cityID,projectID)
 if not Active() then return; end
 local project=GameInfo.Projects[projectID]; if project==nil or project.ProjectType~=RELIC_PROJECT then return; end
 local player=Players[playerID]; if player==nil or not ReconcileWarGodRelic(player) then
  Log("warGodRelic completion rejected player="..tostring(playerID).." reason=ENVOYS_BELOW_6"); return;
 end
 if Number(player:GetProperty("LOTM_RESCUE_WAR_GOD_RELIC_COMPLETED"),0)~=1 then
  player:SetProperty("LOTM_RESCUE_WAR_GOD_RELIC_COMPLETED",1);
  player:SetProperty("LOTM_RESCUE_WAR_GOD_RELIC_STATE","DIVINE_LEGION_GRANTED");
  player:SetProperty("LOTM_RESCUE_WAR_GOD_RELIC_COMPLETED_TURN",LOTM_RESCUE_Phase5.WorldTurn());
  Log("warGodRelic completed player="..playerID.." city="..cityID.." divineLegion=true");
 end
 RefreshPlayer(playerID);
end

local function QueueNetworkCityProjectCompleted(playerID,cityID,projectID)
 local normalizedPlayerID=tonumber(playerID); local normalizedCityID=tonumber(cityID); local normalizedProjectID=tonumber(projectID);
 if normalizedPlayerID==nil or normalizedCityID==nil or normalizedProjectID==nil or not Active() then return; end
 local project=GameInfo.Projects[normalizedProjectID]; if project==nil or project.ProjectType~=RELIC_PROJECT then return; end
 local queuedTurn=Game.GetCurrentGameTurn();
 local key=tostring(queuedTurn)..":"..tostring(normalizedPlayerID)..":"..tostring(normalizedCityID)..":"..tostring(normalizedProjectID);
 if m_pendingNetworkProjectCompletionKeys[key]~=nil then return; end
 local entry={QueuedTurn=queuedTurn,PlayerID=normalizedPlayerID,CityID=normalizedCityID,ProjectID=normalizedProjectID,Key=key};
 m_pendingNetworkProjectCompletions[#m_pendingNetworkProjectCompletions+1]=entry;
 m_pendingNetworkProjectCompletionKeys[key]=entry;
end

local function ProcessNetworkCityProjectCompletions(playerID)
 if not LOTM_MP_TurnSync.IsNetworkGame() or not LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID) then return; end
 local currentTurn=Game.GetCurrentGameTurn(); local ready={}; local waiting={};
 for _,entry in ipairs(m_pendingNetworkProjectCompletions) do
  if entry.QueuedTurn<currentTurn then ready[#ready+1]=entry; else waiting[#waiting+1]=entry; end
 end
 m_pendingNetworkProjectCompletions=waiting;
 table.sort(ready,function(a,b)
  if a.QueuedTurn~=b.QueuedTurn then return a.QueuedTurn<b.QueuedTurn; end
  if a.PlayerID~=b.PlayerID then return a.PlayerID<b.PlayerID; end
  if a.CityID~=b.CityID then return a.CityID<b.CityID; end
  return a.ProjectID<b.ProjectID;
 end);
 for _,entry in ipairs(ready) do
  if m_pendingNetworkProjectCompletionKeys[entry.Key]==entry then m_pendingNetworkProjectCompletionKeys[entry.Key]=nil; end
  local project=GameInfo.Projects[entry.ProjectID]; local player=Players[entry.PlayerID];
  if project~=nil and project.ProjectType==RELIC_PROJECT and player~=nil and player:IsAlive() and player:IsMajor()
   and player:IsHuman() then
   -- The completion is a synchronized fact from the earlier turn.  The city
   -- may have been conquered or destroyed while it waited at the stable
   -- boundary; inspect ownership for diagnostics, but never discard the fact
   -- merely because the original city no longer belongs to this player.
   local city=player:GetCities():FindID(entry.CityID);
   local cityStillOwned=city~=nil and city:GetOwner()==entry.PlayerID;
   if not cityStillOwned then
    Log("deferred project city changed; preserving completion player="..entry.PlayerID.." city="..entry.CityID.." project="..entry.ProjectID);
   end
   ApplyCityProjectCompleted(entry.PlayerID,entry.CityID,entry.ProjectID);
  else
   Log("deferred project completion discarded player="..entry.PlayerID.." city="..entry.CityID.." project="..entry.ProjectID);
  end
 end
end

local function OnCityProjectCompleted(playerID,cityID,projectID)
 if LOTM_MP_TurnSync.IsNetworkGame() then QueueNetworkCityProjectCompleted(playerID,cityID,projectID); return; end
 ApplyCityProjectCompleted(playerID,cityID,projectID);
end

function LOTM_RESCUE_Phase10A.RefreshAll()
 if not Active() then return false; end
 local worldTurn,finalTurn=PublishSchedule();
 local majors={}; for _,player in ipairs(PlayerManager.GetAliveMajors()) do majors[#majors+1]=player; end
 table.sort(majors,function(a,b) return a:GetID()<b:GetID(); end);
 for _,player in ipairs(majors) do if player:IsHuman() then RefreshPlayer(player:GetID()); end end
 if worldTurn>=finalTurn and Number(Game.GetProperty("LOTM_RESCUE_PHASE10A_GATE_LOGGED"),0)~=1 then
  Game.SetProperty("LOTM_RESCUE_PHASE10A_GATE_LOGGED",1);
  Log("descentGate worldTurn="..tostring(worldTurn).." finalTurn="..tostring(finalTurn)
   .." purification="..tostring(Number(Game.GetProperty("GLOBAL_PURIFICATION"),0))
   .." godsGenerated=false bossGenerated=false reason=balance_data_required");
 end
 return true;
end

LOTM_MP_TurnSync.Add(function(playerID,isFirstTimeThisTurn)
 if isFirstTimeThisTurn==false then return; end
 if LOTM_MP_TurnSync.IsNetworkGame() then ProcessNetworkCityProjectCompletions(playerID); end
 if not Active() then return; end
 PublishSchedule(); RefreshPlayer(playerID);
end,"RescuePhase10A");
Events.CityProjectCompleted.Add(OnCityProjectCompleted);
LOTM_MP_TurnSync.RunStartup(LOTM_RESCUE_Phase10A.RefreshAll,"RescuePhase10A");
Log("loaded version="..VERSION.." measurement=true divineLegion=sacrificedUnitOneTenth command="..SACRIFICE_COMMAND);
