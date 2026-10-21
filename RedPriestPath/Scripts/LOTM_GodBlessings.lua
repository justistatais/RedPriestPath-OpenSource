-- Shared direct lightning impact. UI only submits EXECUTE_SCRIPT.
-- No unit, launch facility, WMD stock, missile command or nuclear VFX is created.
-- Native bindings apply our bounded nuclear-destruction profile directly.
LOTM_GodBlessings = LOTM_GodBlessings or { VERSION=6 };
local WEAPON="WMD_LOTM_LIGHTNING_STORM";
local CARRIER="UNIT_LOTM_STORM_MANIFESTATION";
local CHARGES="LOTM_STORM_CHARGES";
local DELIVERY_VERSION=3;
-- V4 frame99 is the first reviewed mass-strike frame (zero-based98, 4.083s).
local IMPACT_FRAME=98;
local STORM_DEBUG_UNLIMITED=false;
-- Production casts spend earned charges. Keep the saved CAST_DEBUG identity
-- only to reject or finish already accepted legacy test operations safely.
local function Log(s) print("[LOTM][GodBlessings] "..tostring(s)); end
local function N(o,k,d)
 local v=o~=nil and o:GetProperty(k) or nil;
 return v~=nil and tonumber(v) or d;
end
local function Loaded()
 return GameInfo.WMDs~=nil and GameInfo.WMDs[WEAPON]~=nil
  and GameInfo.Units~=nil and GameInfo.Units[CARRIER]~=nil;
end
local function Rescue() return LOTM_MP_TurnSync.IsRescueModeConfigured(); end
local function StormEnabled()
 return Loaded() and Rescue()==(tonumber(Game.GetProperty("LOTM_RESCUE_MODE") or 0)==1);
end
local function Normal() return StormEnabled() and not Rescue(); end
function LOTM_GodBlessings.IsEnabled() return Normal(); end
function LOTM_GodBlessings.IsStormEnabled() return StormEnabled(); end
local function DebugUnlimited() return StormEnabled() and STORM_DEBUG_UNLIMITED==true; end
local function Player(id)
 local p=id~=nil and Players[id] or nil;
 return p~=nil and p:IsAlive() and p:IsMajor() and p or nil;
end
local function Quest(church,tier,suffix)
 return "LOTM_CHURCH_"..church.."_QUEST_"..tier.."_"..suffix;
end
local function PublishFX(p,kind,plotIndex,castSerial)
 local plot=Map.GetPlotByIndex(plotIndex); if plot==nil then return false; end
 local serial=N(p,"LOTM_GOD_FX_SERIAL",0)+1;
 local key="LOTM_GOD_FX_"..serial.."_";
 p:SetProperty(key.."KIND",kind); p:SetProperty(key.."PLOT",plotIndex);
 if kind=="STORM" and castSerial~=nil then
  p:SetProperty(key.."CAST_SERIAL",castSerial); p:SetProperty(key.."IMPACT_FRAME",IMPACT_FRAME);
 end
 p:SetProperty("LOTM_GOD_FX_SERIAL",serial);
 Log("fx player="..p:GetID().." serial="..serial.." kind="..kind.." plot="..plotIndex);
 return true;
end
function LOTM_GodBlessings.RecordCapitalFX(p,church,tier)
 if not Normal() or (church~="FOOL" and church~="NIGHT") then return; end
 local receipt=Quest(church,tier,"GOD_FX_RECORDED");
 if N(p,receipt,0)==1 then return; end
 local capital=p:GetCities():GetCapitalCity(); if capital==nil then return; end
 local plot=Map.GetPlot(capital:GetX(),capital:GetY());
 if plot~=nil and PublishFX(p,church,plot:GetIndex()) then p:SetProperty(receipt,1); end
end
function LOTM_GodBlessings.GrantStorm(p,tier,strength)
 if not StormEnabled() or (tier~=6 and tier~=10 and tier~=15) then return false; end
 if Rescue() and tier==6 then return false; end
 local receipt=Quest("STORM",tier,"STORM_GRANTED");
 if N(p,receipt,0)==1 then return true; end
 p:SetProperty(CHARGES,N(p,CHARGES,0)+1);
 p:SetProperty(receipt,1);
 Log("grant player="..p:GetID().." tier="..tier.." strength="..tostring(strength)
  .." charges="..N(p,CHARGES,0));
 return true;
end
function LOTM_GodBlessings.BaselineCapitalFX(p)
 if not Normal() then return; end
 -- A version-gated migration suppresses animations for already awarded
 -- historical blessings. New rewards receive their own persistent receipt.
 for _,church in ipairs({"FOOL","NIGHT"}) do for _,tier in ipairs({6,10,15}) do
  if N(p,Quest(church,tier,"REWARD_APPLIED"),0)==1 then
   p:SetProperty(Quest(church,tier,"GOD_FX_RECORDED"),1);
  end
 end end
end
local function Carrier(p)
 local id=N(p,"LOTM_STORM_CARRIER_ID",-1);
 local unit=id>=0 and UnitManager.GetUnit(p:GetID(),id) or nil;
 local row=GameInfo.Units[CARRIER];
 if unit==nil or row==nil or unit:GetType()~=row.Index
  or N(unit,"LOTM_STORM_CAST_SERIAL",-1)~=N(p,"LOTM_STORM_CAST_SERIAL",0) then return nil; end
 return unit;
end
local function RemoveCarrier(p)
 -- Resource428 and earlier saves may still contain a prepared carrier.
 -- It is retained in the database solely for exact-identity cleanup.
 local unit=Carrier(p); if unit~=nil then UnitManager.Kill(unit); end
 p:SetProperty("LOTM_STORM_CARRIER_ID",-1);
end
local function OriginKey(plotIndex) return "LOTM_STORM_ORIGIN_"..plotIndex.."_"; end
local function RemoveOrigin(p)
 local index=N(p,"LOTM_STORM_SOURCE_PLOT",-1);
 if N(p,"LOTM_STORM_SOURCE_TEMPORARY",0)==1 and index>=0 then
  local key=OriginKey(index);
  if tonumber(Game.GetProperty(key.."OWNER"))==p:GetID()
   and tonumber(Game.GetProperty(key.."SERIAL"))==N(p,"LOTM_STORM_CAST_SERIAL",0) then
   local plot=Map.GetPlotByIndex(index); local row=GameInfo.Improvements.IMPROVEMENT_MISSILE_SILO;
   -- Do not remove an existing silo or a replacement made by another action.
   if plot~=nil and row~=nil and plot:GetImprovementType()==row.Index then
    ImprovementBuilder.SetImprovementType(plot,-1,-1);
   end
   Game.SetProperty(key.."OWNER",nil); Game.SetProperty(key.."SERIAL",nil);
  end
 end
 p:SetProperty("LOTM_STORM_SOURCE_TEMPORARY",0);
 p:SetProperty("LOTM_STORM_SOURCE_PLOT",-1);
 p:SetProperty("LOTM_STORM_SOURCE_CITY_ID",-1);
end

local function Result(p,value)
 p:SetProperty("LOTM_STORM_RESULT",value);
 p:SetProperty("LOTM_STORM_RESULT_SERIAL",N(p,"LOTM_STORM_RESULT_SERIAL",0)+1);
 Log("result player="..p:GetID().." value="..value.." charges="..N(p,CHARGES,0));
end
local function LegacyCleanup(p)
 if N(p,"LOTM_STORM_DELIVERY_MIGRATED",0)>=DELIVERY_VERSION then return; end
 -- Exact saved identities only; an ordinary silo is never created or removed.
 RemoveCarrier(p); RemoveOrigin(p);
 local row=GameInfo.WMDs[WEAPON]; local stock=p:GetWMDs();
 if stock~=nil and stock.GetWeaponCount~=nil and stock.ChangeWeaponCount~=nil then
  local count=stock:GetWeaponCount(row.Index); if count>0 then stock:ChangeWeaponCount(row.Index,-count); end
 end
 p:SetProperty("LOTM_STORM_PENDING",0); p:SetProperty("LOTM_STORM_ARMED",0);
 p:SetProperty("LOTM_STORM_CAST_DEBUG",0);
 p:SetProperty("LOTM_STORM_WINDUP",0); p:SetProperty("LOTM_STORM_START_FX_SERIAL",0);
 p:SetProperty("LOTM_STORM_DELIVERY_MIGRATED",DELIVERY_VERSION);
end
local function Session(playerID,parameters)
 if not StormEnabled() or type(parameters)~="table" then return nil; end
 local p=Player(playerID);
 return p~=nil and p:IsHuman() and tonumber(parameters.CastSerial)==N(p,"LOTM_STORM_CAST_SERIAL",0)
  and N(p,"LOTM_STORM_PENDING",0)==1 and N(p,"LOTM_STORM_DELIVERY_VERSION",0)==DELIVERY_VERSION and p or nil;
end
local function Cancel(p)
 if N(p,"LOTM_STORM_PENDING",0)~=1 or N(p,"LOTM_STORM_APPLYING",0)==1 or N(p,"LOTM_STORM_WINDUP",0)==1 then return; end
 p:SetProperty("LOTM_STORM_PENDING",0); p:SetProperty("LOTM_STORM_ARMED",0);
 p:SetProperty("LOTM_STORM_CAST_DEBUG",0); Result(p,"CANCELLED");
end
local function OnPrepare(playerID,parameters)
 if not StormEnabled() or type(parameters)~="table" then return; end
 local p=Player(playerID); if p==nil or not p:IsHuman() then return; end
 if not p:IsTurnActive() then Result(p,"NOT_YOUR_TURN"); return; end
 if tonumber(parameters.ExpectedSerial)~=N(p,"LOTM_STORM_CAST_SERIAL",0) then return; end
 LegacyCleanup(p);
 if N(p,"LOTM_STORM_PENDING",0)==1 then return; end
 if not DebugUnlimited() and N(p,CHARGES,0)<=0 then Result(p,"NO_CHARGE"); return; end
 p:SetProperty("LOTM_STORM_CAST_SERIAL",N(p,"LOTM_STORM_CAST_SERIAL",0)+1);
 p:SetProperty("LOTM_STORM_DELIVERY_VERSION",DELIVERY_VERSION);
 p:SetProperty("LOTM_STORM_PREPARED_TURN",Game.GetCurrentGameTurn());
 p:SetProperty("LOTM_STORM_TARGET_PLOT",-1);
 p:SetProperty("LOTM_STORM_CAST_DEBUG",DebugUnlimited() and 1 or 0);
 p:SetProperty("LOTM_STORM_APPLYING",0); p:SetProperty("LOTM_STORM_PLAN_COUNT",0);
 p:SetProperty("LOTM_STORM_WINDUP",0); p:SetProperty("LOTM_STORM_START_FX_SERIAL",0);
 p:SetProperty("LOTM_STORM_ARMED",1); p:SetProperty("LOTM_STORM_PENDING",1); Result(p,"READY");
end
-- At most the target plus six adjacent hexes. No per-event map/player scan.
local function BlastPlots(target)
 local plots={}; local seen={};
 for dy=-1,1 do for dx=-1,1 do
  local plot=Map.GetPlotXYWithRangeCheck(target:GetX(),target:GetY(),dx,dy,1);
  if plot~=nil and not seen[plot:GetIndex()] then seen[plot:GetIndex()]=true; plots[#plots+1]=plot; end
 end end
 table.sort(plots,function(a,b) return a:GetIndex()<b:GetIndex(); end); return plots;
end
-- Standard and modded ability-based WMD blast resistance, using actual DB
-- amounts (the stock GDR is Blast=50). Cache metadata, never live unit state.
local resistanceAbilities=nil;
local districtReplacements=nil;
local function DistrictTypes(row)
 if districtReplacements==nil then
  districtReplacements={};
  for replacement in GameInfo.DistrictReplaces() do
   districtReplacements[replacement.CivUniqueDistrictType]=replacement.ReplacesDistrictType;
  end
 end
 local types={}; local current=row.DistrictType;
 while current~=nil and not types[current] do types[current]=true; current=districtReplacements[current]; end
 return types;
end
local function BlastResistance(unit)
 if resistanceAbilities==nil then
  resistanceAbilities={};
  for link in GameInfo.UnitAbilityModifiers() do
   local modifier=GameInfo.Modifiers[link.ModifierId];
   local dynamic=modifier~=nil and GameInfo.DynamicModifiers[modifier.ModifierType] or nil;
   if dynamic~=nil and dynamic.EffectType=="EFFECT_ADJUST_UNIT_WMD_PROTECTION" then
    for argument in GameInfo.ModifierArguments() do
     if argument.ModifierId==link.ModifierId and argument.Name=="Blast" then
      resistanceAbilities[#resistanceAbilities+1]={Ability=link.UnitAbilityType,Amount=tonumber(argument.Value) or 0};
     end
    end
   end
  end
  table.sort(resistanceAbilities,function(a,b) return a.Ability<b.Ability or (a.Ability==b.Ability and a.Amount<b.Amount); end);
 end
 local ability=unit:GetAbility(); if ability==nil or ability.GetAbilityCount==nil then error("UnitAbility.GetAbilityCount unavailable"); end
 local total=0;
 for _,entry in ipairs(resistanceAbilities) do
  if ability:GetAbilityCount(entry.Ability)>0 then total=total+entry.Amount; end
 end
 return math.max(0,math.min(100,total));
end
local function IsOuterGod(unit)
 if not Rescue() or not StormEnabled() or unit==nil then return false; end
 local row=GameInfo.Units[unit:GetType()];
 return (row~=nil and row.UnitType=="UNIT_LOTM_RESCUE_OUTER_GOD_AVATAR")
  or (tostring(unit:GetProperty("LOTM_RESCUE_PHASE10_ROLE") or "")=="BOSS"
   and N(unit,"LOTM_RESCUE_PHASE10_IS_GOD",0)==1);
end
local function OuterStep(unit)
 local before=unit:GetDamage(); local maximum=unit:GetMaxDamage();
 return {Kind="OUTER_GOD",Owner=unit:GetOwner(),ID=unit:GetID(),Value=math.min(maximum,before+20),
  Extra=maximum,BaseDamage=before,OuterEpoch=N(unit,"LOTM_RESCUE_PHASE10_BOSS_EPOCH",0),OuterType=unit:GetType()};
end
local function CollectPlan(p,target)
 local plan={}; local cities={}; local orderedCities={}; local owners={}; local ownerIDs={}; local seenUnits={};
 local function Owner(id)
  if id~=nil and id>=0 and id~=p:GetID() and Players[id]~=nil and not owners[id] then
   owners[id]=true; ownerIDs[#ownerIDs+1]=id;
  end
 end
 local function Add(kind,owner,id,value,extra)
  plan[#plan+1]={Kind=kind,Owner=owner,ID=id,Value=value,Extra=extra or 0};
 end
 local function Unit(unit)
  if unit==nil or unit:IsDead() or unit:IsDelayedDeath() then return; end
  local owner=unit:GetOwner(); local id=unit:GetID(); local key=owner..":"..id;
  if seenUnits[key] then return; end; seenUnits[key]=true; Owner(owner);
  -- Decide before calculating a nuclear endpoint or queuing UnitManager.Kill.
  -- Outer-God minions do not match the avatar/BOSS predicate.
  if IsOuterGod(unit) then
   if LOTM_RESCUE_Phase10==nil or LOTM_RESCUE_Phase10.ApplyStormDamage==nil then error("Outer God storm damage binding unavailable"); end
   plan[#plan+1]=OuterStep(unit); return;
  end
  local damage=math.floor(unit:GetMaxDamage()*(100-BlastResistance(unit))/100);
  if damage>0 then
   if unit.ChangeDamage==nil or UnitManager.Kill==nil then error("Unit damage binding unavailable"); end
   Add("UNIT",owner,id,math.min(unit:GetMaxDamage(),unit:GetDamage()+damage),unit:GetMaxDamage());
  end
 end
 for _,plot in ipairs(BlastPlots(target)) do
  Owner(plot:GetOwner());
  local workers=plot:GetWorkerCount(); local working=Cities.GetPlotWorkingCity(plot:GetIndex());
  if workers>0 and working~=nil then
   local key=working:GetOwner()..":"..working:GetID();
   if cities[key]==nil then cities[key]={City=working,Workers=0}; orderedCities[#orderedCities+1]=cities[key]; end
   cities[key].Workers=cities[key].Workers+workers;
  end
  local units=Units.GetUnitsInPlot(plot) or {};
  table.sort(units,function(a,b) return a:GetOwner()<b:GetOwner() or (a:GetOwner()==b:GetOwner() and a:GetID()<b:GetID()); end);
  for _,unit in ipairs(units) do Unit(unit); end
  -- Stationed aircraft use a separate plot collection in the native UI.
  for _,air in ipairs(plot:GetAirUnits() or {}) do
   local unit=air.GetOwner~=nil and air or UnitManager.GetUnit(air.player,air.id); Unit(unit);
  end
  if plot:GetImprovementType()>=0 and not plot:IsImprovementPillaged() then
   if ImprovementBuilder.SetImprovementPillaged==nil then error("Improvement pillage binding unavailable"); end
   Add("IMPROVEMENT",-1,plot:GetIndex(),1);
  end
  if plot:GetRouteType()>=0 and not plot:IsRoutePillaged() then
   if RouteBuilder.SetRoutePillaged==nil then error("Route pillage binding unavailable"); end
   Add("ROUTE",-1,plot:GetIndex(),1);
  end
  local city=Cities.GetPlotPurchaseCity(plot);
  local district=city~=nil and city:GetDistricts():GetDistrictAtLocation(plot:GetIndex()) or nil;
  local districtRow=district~=nil and GameInfo.Districts[district:GetType()] or nil;
  if district~=nil and districtRow~=nil and districtRow.DistrictType~="DISTRICT_WONDER" then
   for _,defense in ipairs({DefenseTypes.DISTRICT_GARRISON,DefenseTypes.DISTRICT_OUTER}) do
    local maximum=district:GetMaxDamage(defense);
    if maximum>district:GetDamage(defense) then
     if district.ChangeDamage==nil then error("District.ChangeDamage unavailable"); end
     Add("DEFENSE",district:GetOwner(),district:GetID(),maximum,defense);
    end
   end
   local row=districtRow; local buildings=city:GetBuildings();
   if row~=nil then
    local allowedDistricts=DistrictTypes(row);
    local candidates={};
    for building in GameInfo.Buildings() do
     if allowedDistricts[building.PrereqDistrict] and not building.IsWonder
      and buildings:HasBuilding(building.Index) and not buildings:IsPillaged(building.Index) then
      if buildings.SetPillaged==nil then error("CityBuildings.SetPillaged unavailable"); end
      candidates[#candidates+1]=building.Index;
     end
    end
    table.sort(candidates); for _,index in ipairs(candidates) do Add("BUILDING",city:GetOwner(),city:GetID(),1,index); end
    if row.DistrictType~="DISTRICT_CITY_CENTER" and not district:IsPillaged() then
     if district.SetPillaged==nil then error("District.SetPillaged unavailable"); end
     Add("DISTRICT",district:GetOwner(),district:GetID(),1);
    end
   end
  end
 end
 table.sort(orderedCities,function(a,b) return a.City:GetOwner()<b.City:GetOwner() or (a.City:GetOwner()==b.City:GetOwner() and a.City:GetID()<b.City:GetID()); end);
 -- Snapshot all workers before any population change causes reassignment.
 for _,entry in ipairs(orderedCities) do
  local city=entry.City; if city.ChangePopulation==nil then error("City.ChangePopulation unavailable"); end
  Add("POPULATION",city:GetOwner(),city:GetID(),math.max(1,city:GetPopulation()-entry.Workers));
 end
 local wars={}; local diplomacy=p:GetDiplomacy();
 table.sort(ownerIDs); for _,id in ipairs(ownerIDs) do if not diplomacy:IsAtWarWith(id) then wars[#wars+1]=id; end end;
 return plan,wars;
end
local function ApplyStep(step,caster,serial)
 local p=step.Owner>=0 and Players[step.Owner] or nil;
 if step.Kind=="OUTER_GOD" then
  local unit=UnitManager.GetUnit(step.Owner,step.ID); if unit==nil or unit:IsDead() or unit:IsDelayedDeath() then return; end
  if not IsOuterGod(unit) or unit:GetType()~=step.OuterType
   or N(unit,"LOTM_RESCUE_PHASE10_BOSS_EPOCH",0)~=step.OuterEpoch then
   Log("outer god step skipped identity changed owner="..step.Owner.." unit="..step.ID); return;
  end
  if LOTM_RESCUE_Phase10==nil or LOTM_RESCUE_Phase10.ApplyStormDamage==nil
   or not LOTM_RESCUE_Phase10.ApplyStormDamage(unit,step.BaseDamage,step.Value,step.OuterEpoch,caster,serial) then
   error("Outer God 20-point damage verification failed");
  end
 elseif step.Kind=="UNIT" then
  local unit=UnitManager.GetUnit(step.Owner,step.ID); if unit==nil then return; end
  if IsOuterGod(unit) then error("Outer God cannot use a nuclear kill step"); end
  if step.Value>=step.Extra then UnitManager.Kill(unit);
  elseif unit:GetDamage()<step.Value then unit:ChangeDamage(step.Value-unit:GetDamage()); end
  local after=UnitManager.GetUnit(step.Owner,step.ID);
  if after~=nil and not after:IsDead() and not after:IsDelayedDeath() and after:GetDamage()<step.Value then error("UNIT verification failed"); end
 elseif step.Kind=="IMPROVEMENT" or step.Kind=="ROUTE" then
  local plot=Map.GetPlotByIndex(step.ID); if plot==nil then return; end
  if step.Kind=="IMPROVEMENT" then
   ImprovementBuilder.SetImprovementPillaged(plot,true); if not plot:IsImprovementPillaged() then error("IMPROVEMENT verification failed"); end
  else RouteBuilder.SetRoutePillaged(plot,true); if not plot:IsRoutePillaged() then error("ROUTE verification failed"); end end
 elseif step.Kind=="DEFENSE" or step.Kind=="DISTRICT" then
  local district=p~=nil and p:GetDistricts():FindID(step.ID) or nil; if district==nil then return; end
  if step.Kind=="DEFENSE" then
   local goal=math.min(step.Value,district:GetMaxDamage(step.Extra));
   if district:GetDamage(step.Extra)<goal then district:ChangeDamage(step.Extra,goal-district:GetDamage(step.Extra)); end
   if district:GetDamage(step.Extra)<goal then error("DEFENSE verification failed"); end
  else district:SetPillaged(true); if not district:IsPillaged() then error("DISTRICT verification failed"); end end
 elseif step.Kind=="BUILDING" or step.Kind=="POPULATION" then
  local city=p~=nil and p:GetCities():FindID(step.ID) or nil; if city==nil then return; end
  if step.Kind=="BUILDING" then
   local buildings=city:GetBuildings(); buildings:SetPillaged(step.Extra,true);
   if not buildings:IsPillaged(step.Extra) then error("BUILDING verification failed"); end
  elseif city:GetPopulation()>step.Value then
   city:ChangePopulation(step.Value-city:GetPopulation());
   if city:GetPopulation()>step.Value then error("POPULATION verification failed"); end
  end
 end
end
local function ResumeImpact(p)
 if N(p,"LOTM_STORM_APPLYING",0)~=1 then return; end
 local count=N(p,"LOTM_STORM_PLAN_COUNT",0);
 for index=N(p,"LOTM_STORM_PLAN_DONE",0)+1,count do
  local prefix="LOTM_STORM_PLAN_"..index.."_";
  local step={Kind=p:GetProperty(prefix.."Kind"),Owner=N(p,prefix.."Owner",-1),ID=N(p,prefix.."ID",-1),Value=N(p,prefix.."Value",0),Extra=N(p,prefix.."Extra",0),
   BaseDamage=N(p,prefix.."BaseDamage",0),OuterEpoch=N(p,prefix.."OuterEpoch",0),OuterType=N(p,prefix.."OuterType",-1)};
  -- Recheck serialized legacy UNIT plans before their lethal branch. Persist
  -- the converted fixed endpoint before any damage so retries remain bounded.
  if step.Kind=="UNIT" then
   local unit=UnitManager.GetUnit(step.Owner,step.ID);
   if IsOuterGod(unit) then
    step=OuterStep(unit);
    for _,key in ipairs({"Kind","Owner","ID","Value","Extra","BaseDamage","OuterEpoch","OuterType"}) do p:SetProperty(prefix..key,step[key]); end
    Log("legacy nuclear step converted to outer god 20-point damage player="..p:GetID().." step="..index);
   end
  end
  -- Absolute endpoints allow a retry after a native exception without applying
  -- unit/population damage twice. Keep the incomplete receipt across reload.
  local ok,err=pcall(ApplyStep,step,p:GetID(),N(p,"LOTM_STORM_CAST_SERIAL",0));
  if not ok then Log("impact failed player="..p:GetID().." step="..index.." kind="..tostring(step.Kind).." error="..tostring(err)); Result(p,"IMPACT_FAILED"); return; end
  p:SetProperty("LOTM_STORM_PLAN_DONE",index);
 end
 local serial=N(p,"LOTM_STORM_CAST_SERIAL",0);
 p:SetProperty("LOTM_STORM_SETTLED_SERIAL",serial);
 if N(p,"LOTM_STORM_CAST_DEBUG",0)~=1 then p:SetProperty(CHARGES,math.max(0,N(p,CHARGES,0)-1)); end
 p:SetProperty("LOTM_STORM_CAST_DEBUG",0); p:SetProperty("LOTM_STORM_APPLYING",0);
 p:SetProperty("LOTM_STORM_PENDING",0); p:SetProperty("LOTM_STORM_ARMED",0);
 -- New casts already published the gathering/strike animation. Only legacy
 -- partial plans from resource431 and earlier need the old completion FX.
 if N(p,"LOTM_STORM_START_FX_SERIAL",0)==0 then PublishFX(p,"STORM",N(p,"LOTM_STORM_TARGET_PLOT",-1)); end
 Result(p,"FIRED");
 Log("direct impact player="..p:GetID().." serial="..serial.." plot="..N(p,"LOTM_STORM_TARGET_PLOT",-1).." steps="..count.." fallout=0 launcher=NONE");
end
local function ConfirmWars(p,wars,confirmed)
 if #wars>0 then
  local allowed={}; for value in tostring(confirmed or ""):gmatch("%d+") do allowed[tonumber(value)]=true; end
  local diplomacy=p:GetDiplomacy();
  if diplomacy.DeclareWarOn==nil then return "NATIVE_UNAVAILABLE"; end
  -- Permission for a different owner in a stale dialog cannot start a new war.
  -- Native friendship/alliance restrictions remain; no damage precedes war.
  for _,id in ipairs(wars) do
   if not allowed[id] or (diplomacy.HasAllied~=nil and diplomacy:HasAllied(id))
    or (diplomacy.HasDeclaredFriendship~=nil and diplomacy:HasDeclaredFriendship(id))
    or (diplomacy.CanDeclareWarOn~=nil and not diplomacy:CanDeclareWarOn(id)) then
    return "WAR_REQUIRED";
   end
  end
  for _,id in ipairs(wars) do
   -- Firaxis WarMachineScenario.lua uses this exact three-argument binding.
   local declared,err=pcall(function() diplomacy:DeclareWarOn(id,WarTypes.SURPRISE_WAR,true); end);
   if not declared or not diplomacy:IsAtWarWith(id) then
    Log("war declaration failed player="..p:GetID().." target="..id.." error="..tostring(err)); return "WAR_REQUIRED";
   end
  end
 end
 return nil;
end
local function OnFire(playerID,parameters)
 -- Local aiming has no authoritative side effects. Its single confirmation
 -- operation prepares and validates the cast on synchronized Gameplay here.
 if StormEnabled() and type(parameters)=="table" and parameters.ExpectedSerial~=nil then
  local owner=Player(playerID); if owner==nil or not owner:IsHuman() then return; end
  local expected=tonumber(parameters.ExpectedSerial);
  local serial=tonumber(parameters.CastSerial);
  if expected==nil or expected%1~=0 or serial~=expected+1 then return; end
  if serial==N(owner,"LOTM_STORM_SETTLED_SERIAL",-1) and serial==N(owner,"LOTM_STORM_CAST_SERIAL",0) then return; end
  if parameters.ExpectedTurn~=nil and tonumber(parameters.ExpectedTurn)~=Game.GetCurrentGameTurn() then Result(owner,"STALE_REQUEST"); return; end
  if N(owner,"LOTM_STORM_PENDING",0)~=1 then
   if expected~=N(owner,"LOTM_STORM_CAST_SERIAL",0) then Result(owner,"STALE_REQUEST"); return; end
   OnPrepare(playerID,{ExpectedSerial=expected});
  elseif serial~=N(owner,"LOTM_STORM_CAST_SERIAL",0) then
   Result(owner,"INVENTORY_BUSY"); return;
  end
 end
 local p=Session(playerID,parameters); if p==nil then return; end
 if N(p,"LOTM_STORM_CAST_DEBUG",0)==1 and not DebugUnlimited()
  and N(p,"LOTM_STORM_APPLYING",0)~=1 and N(p,"LOTM_STORM_WINDUP",0)~=1 then Cancel(p); return; end
 if N(p,"LOTM_STORM_APPLYING",0)==1 then ResumeImpact(p); return; end
 if N(p,"LOTM_STORM_WINDUP",0)==1 then return; end
 if not p:IsTurnActive() then Result(p,"NOT_YOUR_TURN"); return; end
 if N(p,"LOTM_STORM_PREPARED_TURN",-1)~=Game.GetCurrentGameTurn() then Cancel(p); return; end
 if N(p,"LOTM_STORM_ARMED",0)~=1 or N(p,"LOTM_STORM_SETTLED_SERIAL",0)>=N(p,"LOTM_STORM_CAST_SERIAL",0) then return; end
 local index=tonumber(parameters.PlotIndex); if index==nil or index%1~=0 then return; end
 local target=Map.GetPlotByIndex(index); local visibility=PlayersVisibility[playerID];
 if target==nil or visibility==nil or not visibility:IsRevealed(target:GetX(),target:GetY()) then Result(p,"NO_TARGETS"); return; end
 local ok,plan,wars=pcall(CollectPlan,p,target);
 if not ok then Log("impact preflight failed player="..playerID.." error="..tostring(plan)); Result(p,"NATIVE_UNAVAILABLE"); return; end
 local confirmed=tostring(parameters.ConfirmedWarOwners or "");
 local error=ConfirmWars(p,wars,confirmed); if error~=nil then Result(p,error); return; end
 p:SetProperty("LOTM_STORM_TARGET_PLOT",index);
 p:SetProperty("LOTM_STORM_CONFIRMED_WARS",confirmed);
 p:SetProperty("LOTM_STORM_IMPACT_FRAME",IMPACT_FRAME);
 p:SetProperty("LOTM_STORM_TIMING_VERSION",1);
 p:SetProperty("LOTM_STORM_PLAN_COUNT",0); p:SetProperty("LOTM_STORM_PLAN_DONE",0);
 p:SetProperty("LOTM_STORM_WINDUP",1);
 PublishFX(p,"STORM",index,N(p,"LOTM_STORM_CAST_SERIAL",0));
 p:SetProperty("LOTM_STORM_START_FX_SERIAL",N(p,"LOTM_GOD_FX_SERIAL",0));
 Result(p,"CASTING");
 Log("storm windup player="..playerID.." serial="..N(p,"LOTM_STORM_CAST_SERIAL",0).." plot="..index.." impactFrame="..IMPACT_FRAME);
end
local function AbortWindup(p,error)
 p:SetProperty("LOTM_STORM_WINDUP",0); p:SetProperty("LOTM_STORM_PENDING",0);
 p:SetProperty("LOTM_STORM_ARMED",0); p:SetProperty("LOTM_STORM_CAST_DEBUG",0); Result(p,error);
end
local function OnImpact(playerID,parameters)
 local p=Session(playerID,parameters); if p==nil or N(p,"LOTM_STORM_WINDUP",0)~=1 then return; end
 local fx=N(p,"LOTM_STORM_START_FX_SERIAL",0); local key="LOTM_GOD_FX_"..fx.."_";
 local frame=tonumber(parameters.PresentedFrame);
 if fx<=0 or tonumber(parameters.FXSerial)~=fx or tonumber(parameters.PlotIndex)~=N(p,"LOTM_STORM_TARGET_PLOT",-1)
  or N(p,key.."CAST_SERIAL",-1)~=N(p,"LOTM_STORM_CAST_SERIAL",0)
  or frame==nil or frame%1~=0 or frame<N(p,"LOTM_STORM_IMPACT_FRAME",IMPACT_FRAME) or frame>=216 then return; end
 -- The accepted cast may finish after its turn ends. Snapshot current objects
 -- at impact, so an entity that moved away during gathering is not struck.
 local target=Map.GetPlotByIndex(N(p,"LOTM_STORM_TARGET_PLOT",-1));
 if target==nil then AbortWindup(p,"NO_TARGETS"); return; end
 local ok,plan,wars=pcall(CollectPlan,p,target);
 if not ok then Log("impact snapshot failed player="..playerID.." error="..tostring(plan)); AbortWindup(p,"NATIVE_UNAVAILABLE"); return; end
 local error=ConfirmWars(p,wars,p:GetProperty("LOTM_STORM_CONFIRMED_WARS"));
 if error~=nil then AbortWindup(p,error); return; end
 for order,step in ipairs(plan) do
  local prefix="LOTM_STORM_PLAN_"..order.."_";
  for _,key in ipairs({"Kind","Owner","ID","Value","Extra","BaseDamage","OuterEpoch","OuterType"}) do p:SetProperty(prefix..key,step[key]); end
 end
 p:SetProperty("LOTM_STORM_PLAN_COUNT",#plan); p:SetProperty("LOTM_STORM_PLAN_DONE",0);
 p:SetProperty("LOTM_STORM_WINDUP",0); p:SetProperty("LOTM_STORM_APPLYING",1); ResumeImpact(p);
end
local function MigrateRescueStormBlessing(p)
 if not Rescue() or N(p,"LOTM_RESCUE_STORM_SKILL_VERSION",0)>=1 then return; end
 local tier=N(p,"LOTM_CHURCH_STORM_BLESSING_TIER",0);
 local strength=tostring(p:GetProperty("LOTM_CHURCH_STORM_BLESSING_STRENGTH") or "NONE");
 if (tier==10 or tier==15) and (strength=="FULL" or strength=="HALF") then
  -- Cancel only the old temporary storm bundle; permanent envoy effects and
  -- the other churches are untouched. The existing grant receipt prevents
  -- restoring an already spent resource434 charge.
  if LOTM_WORLD_Churches==nil or LOTM_WORLD_Churches.RemoveLegacyStormBlessing==nil
   or not LOTM_WORLD_Churches.RemoveLegacyStormBlessing(p,tier,strength) then return; end
  if N(p,Quest("STORM",tier,"REWARD_APPLIED"),0)==1
   or N(p,"LOTM_WORLD_PLAYER_TURN",0)<N(p,"LOTM_CHURCH_STORM_BLESSING_UNTIL",0) then
   LOTM_GodBlessings.GrantStorm(p,tier,strength);
  end
  p:SetProperty("LOTM_CHURCH_STORM_BLESSING_TIER",0);
  p:SetProperty("LOTM_CHURCH_STORM_BLESSING_STRENGTH",nil);
  p:SetProperty("LOTM_CHURCH_STORM_BLESSING_UNTIL",-1);
 end
 p:SetProperty("LOTM_RESCUE_STORM_SKILL_VERSION",1);
 Log("rescue storm skill migrated player="..p:GetID().." oldTier="..tier);
end
local function Reconcile(playerID)
 if not StormEnabled() then return; end
 local p=Player(playerID); if p==nil then return; end; LegacyCleanup(p);
 if tonumber(Game.GetProperty("LOTM_STORM_DEBUG_UNLIMITED") or 0)~=(DebugUnlimited() and 1 or 0) then
  Game.SetProperty("LOTM_STORM_DEBUG_UNLIMITED",DebugUnlimited() and 1 or 0);
 end
 if tonumber(Game.GetProperty("LOTM_GOD_BLESSINGS_READY") or 0)~=1 then Game.SetProperty("LOTM_GOD_BLESSINGS_READY",1); end
 -- Two published rescue reward receipts only; no map/unit scan.
 MigrateRescueStormBlessing(p);
 if Rescue() then for _,tier in ipairs({10,15}) do
  local kind=tostring(p:GetProperty(Quest("STORM",tier,"REWARD_KIND")) or "");
  if N(p,Quest("STORM",tier,"REWARD_APPLIED"),0)==1 and (kind=="FULL_BLESSING" or kind=="HALF_BLESSING") then
   LOTM_GodBlessings.GrantStorm(p,tier,kind=="HALF_BLESSING" and "HALF" or "FULL");
  end
 end end
 if N(p,"LOTM_STORM_APPLYING",0)==1 then ResumeImpact(p);
 elseif N(p,"LOTM_STORM_WINDUP",0)==1 then return;
 elseif N(p,"LOTM_STORM_PENDING",0)==1 and N(p,"LOTM_STORM_CAST_DEBUG",0)==1 and not DebugUnlimited() then Cancel(p);
 elseif N(p,"LOTM_STORM_PENDING",0)==1 and Game.GetCurrentGameTurn()>N(p,"LOTM_STORM_PREPARED_TURN",-1) then Cancel(p); end
end
if Loaded() then
 GameEvents.LOTM_Storm_Prepare.Add(OnPrepare);
 GameEvents.LOTM_Storm_Cancel.Add(function(id,args) local p=Session(id,args); if p~=nil then Cancel(p); end end);
 GameEvents.LOTM_Storm_Fire.Add(OnFire);
 GameEvents.LOTM_Storm_Impact.Add(OnImpact);
 if Rescue() then LOTM_MP_TurnSync.AddSynchronized(Reconcile,"GodBlessings");
 else LOTM_MP_TurnSync.Add(Reconcile,"GodBlessings"); end
 LOTM_MP_TurnSync.RunStartup(function()
  Game.SetProperty("LOTM_STORM_DEBUG_UNLIMITED",DebugUnlimited() and 1 or 0);
  Game.SetProperty("LOTM_GOD_BLESSINGS_READY",1);
  Log("initialized rescue="..tostring(Rescue()).." delivery=DIRECT_IMPACT version="..DELIVERY_VERSION.." fallout=0 radius=1 outerGodDamage=20 debugUnlimited="..tostring(DebugUnlimited()));
  local ids=PlayerManager.GetAliveMajorIDs(); table.sort(ids); for _,id in ipairs(ids) do Reconcile(id); end
 end,"GodBlessingsStartup");
end
