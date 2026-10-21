-- Rescue Mode Phase 8: configurable permanent major coalition and lightweight
-- lost-control targeting. The default permanent coalition blocks declarations at
-- engine level; the advanced-setup opt-out retains the reactive peace fallback.
LOTM_RESCUE_Phase8=LOTM_RESCUE_Phase8 or {};

local VERSION=7;
local GUIDE_INTERVAL=2;
local MAX_GUIDED_UNITS=2;
local ALLIANCE_CONFIG="LOTM_RESCUE_MAJOR_ALLIANCE";
local WORKSHOP_PROPERTY="LOTM_PP_WORKSHOP_IS_WORKSHOP";
local CENTER_PROPERTY="LOTM_RESCUE_CENTER_MONSTER";
local HUMAN_WAR_PREFIX="LOTM_RESCUE_PHASE8_HUMAN_WAR:";
local ALLIANCE_PAIR_PREFIX="LOTM_RESCUE_PHASE8_PERMANENT_ALLIANCE:";
local PEACE_PREFIX="LOTM_RESCUE_P8_PEACE__";
local peaceModifierIds=nil;
local LAST_RECONCILE_TURN="LOTM_RESCUE_PHASE8_LAST_RECONCILE_TURN";
local OPENING_COALITION_READY="LOTM_RESCUE_PHASE8_OPENING_COALITION_READY";

local function Log(message) print("[LOTM_RESCUE][Phase8] "..tostring(message)); end
local function Number(value,default) if value==nil then return default; end return tonumber(value) or default; end
local function Active() return Number(Game.GetProperty("LOTM_RESCUE_MODE"),0)==1; end
local function PermanentAllianceEnabled()
 local value=GameConfiguration.GetValue(ALLIANCE_CONFIG);
 if value==nil then return true; end
 return value==true or Number(value,0)==1 or string.lower(tostring(value))=="true";
end
local function PairKey(firstID,secondID)
 local low=math.min(firstID,secondID); local high=math.max(firstID,secondID);
 return HUMAN_WAR_PREFIX..low..":"..high;
end
local function AlliancePairKey(firstID,secondID)
 local low=math.min(firstID,secondID); local high=math.max(firstID,secondID);
 return ALLIANCE_PAIR_PREFIX..low..":"..high;
end
local function AliveMajor(player)
 return player~=nil and player:IsAlive() and player:IsMajor();
end
local function SortedMajors()
 local result={};
 for _,player in ipairs(PlayerManager.GetAliveMajors()) do result[#result+1]=player; end
 table.sort(result,function(a,b) return a:GetID()<b:GetID(); end);
 return result;
end
local function AnchorMajorID()
 local majors=SortedMajors(); return #majors>0 and majors[1]:GetID() or -1;
end
local function PeaceModifierIds()
 if peaceModifierIds~=nil then return peaceModifierIds; end
 peaceModifierIds={};
 for row in GameInfo.Modifiers() do if string.sub(row.ModifierId,1,#PEACE_PREFIX)==PEACE_PREFIX then peaceModifierIds[#peaceModifierIds+1]=row.ModifierId; end end
 table.sort(peaceModifierIds); return peaceModifierIds;
end
local function AttachPeacePreference(player)
 if player==nil or player:IsHuman() or Number(player:GetProperty("LOTM_RESCUE_PHASE8_PEACE_PREFERENCE"),0)==1 then return; end
 local ids=PeaceModifierIds(); for _,modifierID in ipairs(ids) do player:AttachModifierByID(modifierID); end
 if #ids>0 then player:SetProperty("LOTM_RESCUE_PHASE8_PEACE_PREFERENCE",1); end
 Log("peace preference player="..player:GetID().." modifiers="..#ids);
end
local function AtWar(first,secondID)
 local diplomacy=first~=nil and first:GetDiplomacy() or nil;
 return diplomacy~=nil and diplomacy:IsAtWarWith(secondID);
end
local function ForcePeace(actingID,reactingID,reason)
 local acting=Players[actingID]; local reacting=Players[reactingID];
 if not AliveMajor(acting) or not AliveMajor(reacting) or not AtWar(acting,reactingID) then return true; end
 local diplomacy=acting:GetDiplomacy();
 if diplomacy==nil or diplomacy.MakePeaceWith==nil then
  Log("peace unavailable acting="..actingID.." reacting="..reactingID.." reason="..reason);
  return false;
 end
 local ok,result=pcall(function() return diplomacy:MakePeaceWith(reactingID); end);
 Log("peace request acting="..actingID.." reacting="..reactingID.." reason="..reason.." ok="..tostring(ok).." result="..tostring(result));
 return ok;
end
local function HumanWarAllowed(firstID,secondID)
 return Number(Game.GetProperty(PairKey(firstID,secondID)),0)==1;
end
local function EstablishPermanentCoalition()
 if not PermanentAllianceEnabled() then
  Game.SetProperty("LOTM_RESCUE_PHASE8_ALLIANCE_MODE","FREE");
  return 0,0;
 end
 Game.SetProperty("LOTM_RESCUE_PHASE8_ALLIANCE_MODE","PERMANENT");
 local majors=SortedMajors(); local formed=0; local failed=0;
 for firstIndex=1,#majors do for secondIndex=firstIndex+1,#majors do
  local first=majors[firstIndex]; local second=majors[secondIndex];
  local key=AlliancePairKey(first:GetID(),second:GetID());
  if Number(Game.GetProperty(key),0)~=1 then
   if AtWar(first,second:GetID()) then ForcePeace(first:GetID(),second:GetID(),"PERMANENT_COALITION"); end
   local diplomacy=first:GetDiplomacy();
   local reverseDiplomacy=second:GetDiplomacy();
   local ok=false; local result=nil;
   if diplomacy~=nil and diplomacy.SetPermanentAlliance~=nil then
    if diplomacy.SetHasMet~=nil then pcall(function() diplomacy:SetHasMet(second:GetID()); end); end
    if reverseDiplomacy~=nil and reverseDiplomacy.SetHasMet~=nil then pcall(function() reverseDiplomacy:SetHasMet(first:GetID()); end); end
    ok,result=pcall(function() return diplomacy:SetPermanentAlliance(second:GetID()); end);
   end
   if ok and result~=false then
    Game.SetProperty(key,1); formed=formed+1;
    Log("permanent alliance formed first="..first:GetID().." second="..second:GetID());
   else
    Game.SetProperty(key,-1); failed=failed+1;
    Log("permanent alliance failed first="..first:GetID().." second="..second:GetID().." ok="..tostring(ok).." result="..tostring(result));
   end
  end
 end end
 return formed,failed;
end
function LOTM_RESCUE_Phase8.EstablishOpeningCoalition()
 if not LOTM_MP_TurnSync.IsNetworkGame()
  or LOTM_RP_MASTER_GAMEPLAY_CONTEXT~=true
  or type(LOTM_MP_TurnSync.IsRescueModeConfigured)~="function"
  or not LOTM_MP_TurnSync.IsRescueModeConfigured() then
  return false,"INACTIVE_CONTEXT";
 end
 if not Active()
  or Game.GetProperty("LOTM_RESCUE_PHASE1_STATE")~="READY"
  or Game.GetProperty("LOTM_RESCUE_PHASE2A_STATE")~="READY" then
  return false,"RESCUE_BOOTSTRAP_NOT_READY";
 end
 if Number(Game.GetProperty(OPENING_COALITION_READY),0)==1 then
  return true,"ALREADY_READY";
 end
 local formed,failed=EstablishPermanentCoalition();
 Game.SetProperty("LOTM_RESCUE_PHASE8_OPENING_ALLIANCES_FORMED",formed);
 Game.SetProperty("LOTM_RESCUE_PHASE8_OPENING_ALLIANCES_FAILED",failed);
 if failed==0 then Game.SetProperty(OPENING_COALITION_READY,1); end
 Log("opening coalition reconciled formed="..formed.." failed="..failed
	 .." retryPending="..tostring(failed>0).." deferredModifiers=true");
 return failed==0,failed==0 and "READY" or "RETRY_PENDING";
end
local function ReconcilePeace()
 local majors=SortedMajors();
 for firstIndex=1,#majors do for secondIndex=firstIndex+1,#majors do
  local first=majors[firstIndex]; local second=majors[secondIndex];
  if AtWar(first,second:GetID()) then
   local anyHuman=first:IsHuman() or second:IsHuman();
   if PermanentAllianceEnabled() or (not anyHuman) or (not HumanWarAllowed(first:GetID(),second:GetID())) then
    ForcePeace(first:GetID(),second:GetID(),anyHuman and "AI_AGGRESSION" or "AI_VS_AI");
   end
  end
 end end
end
local function IsLostControl(unit)
 if unit==nil then return false; end
 if Number(unit:GetProperty(CENTER_PROPERTY),0)==1 then return true; end
 return LOTM_WORLD_Monsters~=nil and LOTM_WORLD_Monsters.IsMonster~=nil and LOTM_WORLD_Monsters.IsMonster(unit);
end
local function TargetEntries()
 local byPlot={};
 for _,barbarian in ipairs(PlayerManager.GetAliveBarbarians()) do
  for _,unit in barbarian:GetUnits():Members() do if IsLostControl(unit) then
   local plot=Map.GetPlot(unit:GetX(),unit:GetY());
   if plot~=nil then
    local candidate={Plot=plot,Unit=unit,Kind="LOST_CONTROL",HasUnit=true}; local existing=byPlot[plot:GetIndex()];
    if not LOTM_MP_TurnSync.IsNetworkGame() or existing==nil or unit:GetOwner()<existing.Unit:GetOwner()
     or (unit:GetOwner()==existing.Unit:GetOwner() and unit:GetID()<existing.Unit:GetID()) then byPlot[plot:GetIndex()]=candidate; end
   end
  end end
 end
 local camp=GameInfo.Improvements.IMPROVEMENT_BARBARIAN_CAMP;
 if camp~=nil then for plotIndex=0,Map.GetPlotCount()-1 do
  local plot=Map.GetPlotByIndex(plotIndex);
  if plot:GetImprovementType()==camp.Index and Number(plot:GetProperty(WORKSHOP_PROPERTY),0)==1 and byPlot[plotIndex]==nil then
   byPlot[plotIndex]={Plot=plot,Kind="WORKSHOP",HasUnit=#(Units.GetUnitsInPlot(plot) or {})>0};
  end
 end end
 local result={}; for plotIndex=0,Map.GetPlotCount()-1 do if byPlot[plotIndex]~=nil then result[#result+1]=byPlot[plotIndex]; end end
 return result;
end
local function TargetRank(player,target)
 local minimum=nil; local sameContinent=false;
 for _,city in player:GetCities():Members() do
  local cityPlot=Map.GetPlot(city:GetX(),city:GetY());
  local distance=Map.GetPlotDistance(city:GetX(),city:GetY(),target.Plot:GetX(),target.Plot:GetY());
  if minimum==nil or distance<minimum then minimum=distance; end
  if cityPlot~=nil and cityPlot:GetContinentType()==target.Plot:GetContinentType() then sameContinent=true; end
 end
 if minimum==nil then return nil; end
 if minimum<=6 then return 0,minimum; end
 if minimum<=10 then return 1,minimum; end
 if sameContinent then return 2,minimum; end
 return nil;
end
local function BestTarget(player,targets)
 local ranked={};
 for _,target in ipairs(targets) do
  local priority,distance=TargetRank(player,target);
  if priority~=nil then ranked[#ranked+1]={Target=target,Priority=priority,CityDistance=distance}; end
 end
 table.sort(ranked,function(a,b)
  if a.Priority~=b.Priority then return a.Priority<b.Priority; end
  if a.CityDistance~=b.CityDistance then return a.CityDistance<b.CityDistance; end
  if a.Target.Kind~=b.Target.Kind then return a.Target.Kind<b.Target.Kind; end
  return a.Target.Plot:GetIndex()<b.Target.Plot:GetIndex();
 end);
 return #ranked>0 and ranked[1] or nil;
end
local function AtWarWithHuman(player)
 local diplomacy=player~=nil and player:GetDiplomacy() or nil; if diplomacy==nil then return false; end
 for _,other in ipairs(SortedMajors()) do if other:IsHuman() and diplomacy:IsAtWarWith(other:GetID()) then return true; end end
 return false;
end
local function EligibleUnits(player,targetPlot)
 local result={};
 for _,unit in player:GetUnits():Members() do
  local info=GameInfo.Units[unit:GetType()];
  if unit:GetCombat()>0 and info~=nil and info.FormationClass~="FORMATION_CLASS_CIVILIAN"
   and not IsLostControl(unit) and Number(unit:GetProperty("LOTM_RESCUE_GUARDIAN_SERIAL"),0)==0 then
   result[#result+1]={Unit=unit,Distance=Map.GetPlotDistance(unit:GetX(),unit:GetY(),targetPlot:GetX(),targetPlot:GetY()),Damage=unit:GetDamage() or 0};
  end
 end
 table.sort(result,function(a,b)
  if a.Distance~=b.Distance then return a.Distance<b.Distance; end
  if a.Damage~=b.Damage then return a.Damage<b.Damage; end
  return a.Unit:GetID()<b.Unit:GetID();
 end);
 return result;
end
local function ClearTarget(unit,target)
 if LOTM_RESCUE_SyncActions==nil then return false,"HELPER_UNAVAILABLE"; end
 if target.HasUnit and target.Unit~=nil and not target.Unit:IsDead() and not target.Unit:IsDelayedDeath() then
  return LOTM_RESCUE_SyncActions.ScriptedKill(target.Unit,unit),"UNIT_CLEARED";
 end
 local camp=GameInfo.Improvements.IMPROVEMENT_BARBARIAN_CAMP;
 if camp~=nil and target.Plot:GetImprovementType()==camp.Index and ImprovementBuilder~=nil and ImprovementBuilder.SetImprovementType~=nil then
  target.Plot:SetProperty("LOTM_PP_WORKSHOP_LAST_HUMAN",unit:GetOwner()); target.Plot:SetProperty("LOTM_PP_WORKSHOP_CLEARER_UNIT",unit:GetID());
  return pcall(ImprovementBuilder.SetImprovementType,target.Plot,-1,-1),"WORKSHOP_CLEARED";
 end
 return false,"TARGET_GONE";
end
local function ExecuteGuide(unit,target)
 if LOTM_RESCUE_SyncActions==nil then return false,"HELPER_UNAVAILABLE"; end
 local distance=Map.GetPlotDistance(unit:GetX(),unit:GetY(),target.Plot:GetX(),target.Plot:GetY());
 if distance<=1 then local cleared,reason=ClearTarget(unit,target); UnitManager.FinishMoves(unit); return cleared,reason; end
 local info=GameInfo.Units[unit:GetType()]; local moves=info~=nil and Number(info.BaseMoves,1) or 1;
 local moved,reason=LOTM_RESCUE_SyncActions.MoveToward(unit,target.Plot,moves,false,false);
 if moved and Map.GetPlotDistance(unit:GetX(),unit:GetY(),target.Plot:GetX(),target.Plot:GetY())<=1 then local cleared,clearReason=ClearTarget(unit,target); reason=reason.."+"..clearReason; moved=cleared; end
 if moved then UnitManager.FinishMoves(unit); end
 return moved,reason;
end
local function GuidePlayer(player,targets)
 if player==nil or player:IsHuman() or AtWarWithHuman(player) then return; end
 if Number(player:GetProperty("LOTM_RESCUE_PHASE8_LAST_GUIDE_TURN"),-1)==Game.GetCurrentGameTurn() then return; end
 local ranked=BestTarget(player,targets);
 if ranked==nil then player:SetProperty("LOTM_RESCUE_PHASE8_TARGET_PLOT",-1); return; end
 local target=ranked.Target;
 player:SetProperty("LOTM_RESCUE_PHASE8_TARGET_PLOT",target.Plot:GetIndex());
 player:SetProperty("LOTM_RESCUE_PHASE8_TARGET_PRIORITY",ranked.Priority);
 player:SetProperty("LOTM_RESCUE_PHASE8_TARGET_KIND",target.Kind);
 local requested=false; local reason="NO_UNIT"; local selected={}; local guided=0;
 for _,entry in ipairs(EligibleUnits(player,target.Plot)) do
  requested,reason=ExecuteGuide(entry.Unit,target); selected[#selected+1]=entry.Unit:GetID();
  if requested then guided=guided+1; end
  if guided>=MAX_GUIDED_UNITS then break; end
 end
 player:SetProperty("LOTM_RESCUE_PHASE8_LAST_GUIDE_TURN",Game.GetCurrentGameTurn());
 Log("guide player="..player:GetID().." units="..table.concat(selected,",").." guided="..guided.." target="..target.Plot:GetIndex().." kind="..target.Kind.." priority="..ranked.Priority.." cityDistance="..ranked.CityDistance.." lastRequested="..tostring(requested).." reason="..reason);
end
function LOTM_RESCUE_Phase8.ReconcileAll(forceGuide)
 if not Active() then return false; end
 local worldTurn=Game.GetCurrentGameTurn();
 if not forceGuide and Number(Game.GetProperty(LAST_RECONCILE_TURN),-1)==worldTurn then return true; end
 Game.SetProperty(LAST_RECONCILE_TURN,worldTurn);
 Game.SetProperty("LOTM_RESCUE_PHASE8_VERSION",VERSION);
 Game.SetProperty("LOTM_RESCUE_PHASE8_STATE","READY");
 local phase=Number(Game.GetProperty("LOTM_RESCUE_PHASE"),0); if phase<8 then Game.SetProperty("LOTM_RESCUE_PHASE",8); end
 for _,player in ipairs(SortedMajors()) do AttachPeacePreference(player); end
 ReconcilePeace();
 local formed,failed=EstablishPermanentCoalition();
 Game.SetProperty("LOTM_RESCUE_PHASE8_ALLIANCES_FORMED",formed);
 Game.SetProperty("LOTM_RESCUE_PHASE8_ALLIANCES_FAILED",failed);
 if forceGuide or worldTurn%GUIDE_INTERVAL==0 then
  local targets=TargetEntries();
  for _,player in ipairs(SortedMajors()) do GuidePlayer(player,targets); end
 end
 return true;
end
local function OnWar(actingID,reactingID)
 if LOTM_MP_TurnSync.IsNetworkGame() then return; end
 if not Active() then return; end
 local acting=Players[actingID]; local reacting=Players[reactingID]; if not AliveMajor(acting) or not AliveMajor(reacting) then return; end
 if PermanentAllianceEnabled() then
  ForcePeace(actingID,reactingID,"PERMANENT_COALITION_BREACH");
 elseif acting:IsHuman() then
  Game.SetProperty(PairKey(actingID,reactingID),1);
  Log("human war preserved acting="..actingID.." reacting="..reactingID);
 else
  ForcePeace(actingID,reactingID,reacting:IsHuman() and "AI_ON_HUMAN" or "AI_ON_AI");
 end
end
local function OnPeace(firstID,secondID)
 if LOTM_MP_TurnSync.IsNetworkGame() then return; end
 if Active() then Game.SetProperty(PairKey(firstID,secondID),nil); end
end
local function OnTurn(playerID,isFirstTimeThisTurn)
 if isFirstTimeThisTurn==false or not Active() or playerID~=AnchorMajorID() then return; end
 LOTM_RESCUE_Phase8.ReconcileAll(false);
end
local function OnBootstrap() LOTM_RESCUE_Phase8.ReconcileAll(true); end

Events.DiplomacyDeclareWar.Add(OnWar);
Events.DiplomacyMakePeace.Add(OnPeace);
LOTM_MP_TurnSync.Add(OnTurn,"RescuePhase8");
if not LOTM_MP_TurnSync.IsNetworkGame() then
 GameEvents.LOTM_RESCUE_Command_BootstrapCity.Add(OnBootstrap);
end
LOTM_MP_TurnSync.RunStartup(function() LOTM_RESCUE_Phase8.ReconcileAll(false); end,"RescuePhase8");
Log("loaded version="..VERSION.." active="..tostring(Active()).." anchor=lowestAliveMajor reconcileOncePerWorldTurn=true permanentAlliance="..tostring(PermanentAllianceEnabled()).." guideInterval="..GUIDE_INTERVAL.." maxGuidedUnitsPerAI="..MAX_GUIDED_UNITS.." freeModeHumanWarPreserved=true specialUnits=false bossFormula=false");
