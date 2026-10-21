-- UI publications request a synchronized operation; only this Gameplay side
-- validates current engine state and changes units or rewards.
include("LOTM_Effects");
LOTM_RESCUE_RuntimeEvents=LOTM_RESCUE_RuntimeEvents or {};
local SEAL="ABILITY_LOTM_RESCUE_EARLY_SEAL";
local function Active() return tonumber(Game.GetProperty("LOTM_RESCUE_MODE") or 0)==1; end
local function Log(s) print("[LOTM_RESCUE][RuntimeEvents] "..s); end
local function Requester(id)
 for _,p in ipairs(PlayerManager.GetAliveMajors() or {}) do
  if p:GetID()==tonumber(id) and p:IsHuman() then return p; end
 end
 return nil;
end
local function Number(value) local n=tonumber(value); if n~=nil and n>=0 and n<=2147483647 and n==math.floor(n) then return n; end return nil; end
local function WorldTurn()
 if LOTM_RESCUE_Phase5~=nil and LOTM_RESCUE_Phase5.WorldTurn~=nil then return LOTM_RESCUE_Phase5.WorldTurn(); end
 local start=GameConfiguration~=nil and GameConfiguration.GetStartTurn~=nil and GameConfiguration.GetStartTurn() or 0;
 return math.max(1,Game.GetCurrentGameTurn()-(tonumber(start) or 0)+1);
end
local function SealTarget(unit)
 if unit==nil or unit:GetProperty("LOTM_RESCUE_PHASE10_ROLE")~=nil then return false; end
 for _,name in ipairs({"UNIT_LOTM_RESCUE_OUTER_GOD_AVATAR","UNIT_LOTM_RESCUE_OUTER_GOD_MINION"}) do
  local info=GameInfo.Units[name]; if info~=nil and unit:GetType()==info.Index then return false; end
 end
 if (tonumber(unit:GetProperty("LOTM_WORLD_MONSTER_SERIAL") or 0) or 0)>0
  or tonumber(unit:GetProperty("LOTM_RESCUE_CENTER_MONSTER") or 0)==1 then return true; end
 for _,name in ipairs({"UNIT_LOTM_RESCUE_LOST_CONTROL_LOW","UNIT_LOTM_RESCUE_LOST_CONTROL_MID","UNIT_LOTM_RESCUE_LOST_CONTROL_HIGH"}) do
  local info=GameInfo.Units[name]; if info~=nil and unit:GetType()==info.Index then return true; end
 end
 return false;
end
function LOTM_RESCUE_RuntimeEvents.ApplyEarlySeal(unit)
 if not Active() or not SealTarget(unit) or GameInfo.UnitAbilities[SEAL]==nil then return false; end
 local ability=unit:GetAbility(); if ability==nil then return false; end
 local wanted=WorldTurn()<=20 and 1 or 0;
 LOTM_Effects.SetAbilityCount(ability,SEAL,wanted);
 return (ability:GetAbilityCount(SEAL) or 0)==wanted;
end
local function ReconcileSeal()
 if not Active() then return; end
 local active=WorldTurn()<=20 and 1 or 0;
 local migrated=tonumber(Game.GetProperty("LOTM_RESCUE_EARLY_SEAL_VERSION") or 0)==1;
 if migrated and tonumber(Game.GetProperty("LOTM_RESCUE_EARLY_SEAL_ACTIVE"))==active then return; end
 local units={}; local seen={}; local legacy={};
 local function Add(unit)
  if unit==nil or not SealTarget(unit) then return; end
  local key=unit:GetOwner()..":"..unit:GetID(); if seen[key] then return; end
  seen[key]=true; units[#units+1]=unit;
  if (tonumber(unit:GetProperty("LOTM_WORLD_MONSTER_SERIAL") or 0) or 0)<=0 then legacy[#legacy+1]=key; end
 end
 if not migrated then
  -- New-feature old-save migration only. Subsequent threshold changes read
  -- the existing active-monster index and these few legacy identities.
  local natives={};
  for _,player in ipairs(PlayerManager.GetAliveBarbarians() or {}) do
   for _,unit in player:GetUnits():Members() do
    Add(unit); natives[#natives+1]={Owner=unit:GetOwner(),Unit=unit:GetID()};
   end
  end
  -- The same one-time migration covers pre-bridge native survivors whose
  -- birth was published before this context existed. No second unit scan.
  if LOTM_WORLD_Barbarians==nil or LOTM_WORLD_Barbarians.ProcessRescueUnitCandidates==nil
   or not LOTM_WORLD_Barbarians.ProcessRescueUnitCandidates(natives) then return; end
 else
  for token in string.gmatch(tostring(Game.GetProperty("LOTM_WORLD_MONSTER_ACTIVE_SERIALS") or ""),"[^,]+") do
   local serial=tonumber(token);
   if serial~=nil and serial>0 then
    local prefix="LOTM_WORLD_MONSTER:"..serial..":";
    local owner=Number(Game.GetProperty(prefix.."OWNER")); local id=Number(Game.GetProperty(prefix.."UNIT_ID"));
    if tonumber(Game.GetProperty(prefix.."LIVE"))==1 and owner~=nil and id~=nil then
     local unit=UnitManager.GetUnit(owner,id);
     if unit~=nil and tonumber(unit:GetProperty("LOTM_WORLD_MONSTER_SERIAL"))==serial then Add(unit); end
    end
   end
  end
  for owner,id in string.gmatch(tostring(Game.GetProperty("LOTM_RESCUE_EARLY_SEAL_LEGACY_UNITS") or ""),"(%d+):(%d+)") do Add(UnitManager.GetUnit(tonumber(owner),tonumber(id))); end
 end
 table.sort(units,function(a,b) if a:GetOwner()~=b:GetOwner() then return a:GetOwner()<b:GetOwner(); end return a:GetID()<b:GetID(); end);
 for _,unit in ipairs(units) do if not LOTM_RESCUE_RuntimeEvents.ApplyEarlySeal(unit) then return; end end
 table.sort(legacy);
 Game.SetProperty("LOTM_RESCUE_EARLY_SEAL_LEGACY_UNITS",table.concat(legacy,","));
 Game.SetProperty("LOTM_RESCUE_EARLY_SEAL_VERSION",1);
 Game.SetProperty("LOTM_RESCUE_EARLY_SEAL_ACTIVE",active);
 Log("early seal worldTurn="..WorldTurn().." active="..active.." combat="..(active==1 and -10 or 0).." reconciled="..#units);
end
local function CommandCleanup(playerID,parameters)
 if not Active() or Requester(playerID)==nil or type(parameters)~="table" then return; end
 local csv=parameters.Units; if type(csv)~="string" or #csv>2048 then return; end
 local candidates={};
 for owner,id in string.gmatch(csv,"(%d+):(%d+)") do
  if #candidates>=64 then return; end
  owner=Number(owner); id=Number(id);
  if owner==nil or id==nil then return; end
  candidates[#candidates+1]={Owner=owner,Unit=id};
 end
 if #candidates==0 then return; end
 if LOTM_WORLD_Barbarians~=nil and LOTM_WORLD_Barbarians.ProcessRescueUnitCandidates~=nil then
  local ok,removed=LOTM_WORLD_Barbarians.ProcessRescueUnitCandidates(candidates);
  Log("native spawn command candidates="..#candidates.." removed="..tostring(removed or 0).." accepted="..tostring(ok));
 end
end
local function CommandCamp(playerID,parameters)
 if not Active() or Requester(playerID)==nil or type(parameters)~="table" then return; end
 local plot=Number(parameters.PlotIndex); local epoch=Number(parameters.CampEpoch);
 if plot==nil or epoch==nil or LOTM_PP_Workshops==nil or LOTM_PP_Workshops.ResolveRemovedCamp==nil then return; end
 local done=LOTM_PP_Workshops.ResolveRemovedCamp(plot,epoch);
 Log("camp command plot="..plot.." epoch="..epoch.." settled="..tostring(done).." turn="..Game.GetCurrentGameTurn());
end
local function OnTurn(playerID)
 if not Active() or not LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID) then return; end
 ReconcileSeal();
end
local function CommandPotion(playerID,parameters)
 if not Active() or Requester(playerID)==nil or type(parameters)~="table" then return; end
 local target=Number(parameters.TargetPlayerID);
 if target==nil or Requester(target)==nil or LOTM_RESCUE_Thief==nil
  or LOTM_RESCUE_Thief.ReconcileCompletedPotion==nil then return; end
 local done=LOTM_RESCUE_Thief.ReconcileCompletedPotion(target);
 Log("potion command target="..target.." advanced="..tostring(done).." turn="..Game.GetCurrentGameTurn());
end
GameEvents.LOTM_RESCUE_Command_NativeCleanup.Add(CommandCleanup);
GameEvents.LOTM_RESCUE_Command_CampRemoved.Add(CommandCamp);
GameEvents.LOTM_RESCUE_Command_PotionCompleted.Add(CommandPotion);
LOTM_MP_TurnSync.AddSynchronized(OnTurn,"RescueRuntimeEvents");
LOTM_MP_TurnSync.RunStartup(function()
 if Active() then ReconcileSeal(); Game.SetProperty("LOTM_RESCUE_RUNTIME_EVENTS_READY",1); end
end,"RescueRuntimeEvents");
Log("loaded version=1 nativeSpawn=executeScript campReward=executeScript earlySeal=turns1to20");
