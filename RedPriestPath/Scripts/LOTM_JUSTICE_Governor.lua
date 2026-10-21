-- Audrey Hall uses the same skills in normal and rescue games.
-- All persistent state is Gameplay-owned; database availability gates loading.
LOTM_JUSTICE = LOTM_JUSTICE or {};

local GOVERNOR = "GOVERNOR_LOTM_JUSTICE";
local PROMO = {
 SPONSOR="GOVERNOR_PROMOTION_LOTM_JUSTICE_SPONSOR",
 COUNSEL="GOVERNOR_PROMOTION_LOTM_JUSTICE_COUNSEL",
 SALON="GOVERNOR_PROMOTION_LOTM_JUSTICE_SALON",
 SUGGESTION="GOVERNOR_PROMOTION_LOTM_JUSTICE_SUGGESTION",
 TAROT="GOVERNOR_PROMOTION_LOTM_JUSTICE_TAROT",
 STORY="GOVERNOR_PROMOTION_LOTM_JUSTICE_STORY"
};
local STORY_COMMAND="LOTM_JUSTICE_CompleteStory";
local PAUSE_BUILDING="BUILDING_LOTM_JUSTICE_STORY_PAUSE";
local PAUSE_SOURCE_VERSION=5;
local LEGACY_REPAIR_PHASE="JUSTICE_STORY_LEGACY_REPAIR_PHASE";
local LEGACY_REPAIR_COUNT="JUSTICE_STORY_LEGACY_REPAIR_COUNT";
local SPONSOR_ACTIVE="JUSTICE_SPONSOR_GOLD_NATIVE_ACTIVE";
local SPONSOR_START="LOTM_JUSTICE_SPONSOR_GOLD_NATIVE_START";
local SPONSOR_STOP="LOTM_JUSTICE_SPONSOR_GOLD_NATIVE_STOP";
local function Log(s) print("[LOTM_JUSTICE] "..tostring(s)); end
local function N(o,k,d)
 if o==nil then return d; end
 -- Native GetProperty can return no values for an unset key. Capture it first
 -- so tonumber always receives one argument, including on a new game.
 local raw=o:GetProperty(k);
 local v=tonumber(raw);
 return v~=nil and v or d;
end
local function Player(id)
 local p=Players[id]; return p~=nil and p:IsAlive() and p:IsMajor() and p or nil;
end
local function Enabled()
 return GameInfo.Governors~=nil and GameInfo.Governors[GOVERNOR]~=nil;
end
local function ActiveCity(p,typeName)
 if p==nil or not Enabled() or N(p,"JUSTICE_GOVERNOR_ESTABLISHED",0)~=1
  or N(p,"JUSTICE_GOVERNOR_NEUTRALIZED",0)~=0
  or N(p,"JUSTICE_GOVERNOR_HAS_"..typeName,0)~=1 then return nil; end
 local cityID=N(p,"JUSTICE_GOVERNOR_CITY_ID",-1);
 local city=cityID>=0 and p:GetCities():FindID(cityID) or nil;
 if city==nil or city:GetOwner()~=p:GetID() then return nil; end
 return city;
end

local function SetSponsorIncome(p)
 local active=ActiveCity(p,PROMO.SPONSOR)~=nil;
 local attached=N(p,SPONSOR_ACTIVE,0)==1;
 if active==attached then return; end
 -- The same native Gold-per-turn modifier as the mod's planning income is
 -- player-owned. A matching -15 attachment reverses it on transfer, removal,
 -- or neutralization; the property makes retries and reloads idempotent.
 p:AttachModifierByID(active and SPONSOR_START or SPONSOR_STOP);
 p:SetProperty(SPONSOR_ACTIVE,active and 1 or 0);
 Log("sponsor income player="..p:GetID().." active="..tostring(active));
end

function LOTM_JUSTICE.IsCounselingActive(playerID)
 return ActiveCity(Player(playerID),PROMO.COUNSEL)~=nil;
end

local function ClearHolderUnstable(p)
 if not LOTM_JUSTICE.IsCounselingActive(p:GetID()) then return; end
 local turn=N(p,"LOTM_WORLD_PLAYER_TURN",0);
 local untilTurn=N(p,"LOTM_HOLDER_UNSTABLE_STATE_UNTIL",-1);
 if untilTurn>turn then p:SetProperty("LOTM_HOLDER_UNSTABLE_STATE_UNTIL",turn); end
 local holder=LOTM_RP_State~=nil and LOTM_RP_State.FindHero(p:GetID()) or nil;
 local ability=holder~=nil and holder:GetAbility() or nil;
 if ability~=nil then
  local count=ability:GetAbilityCount("ABILITY_LOTM_WORLD_HOLDER_UNSTABLE") or 0;
  if count>0 then ability:ChangeAbilityCount("ABILITY_LOTM_WORLD_HOLDER_UNSTABLE",-count); end
 end
end

local SALON_ORDER={"GREAT_PERSON_CLASS_WRITER","GREAT_PERSON_CLASS_ARTIST","GREAT_PERSON_CLASS_MUSICIAN"};
local SALON_CLASSES={
 GREAT_PERSON_CLASS_WRITER=true,
 GREAT_PERSON_CLASS_ARTIST=true,
 GREAT_PERSON_CLASS_MUSICIAN=true
};
local function WorkingDistrict(districts,index)
 local district=districts:GetDistrictByType(index);
 return district~=nil and district:IsComplete() and not district:IsPillaged();
end
local function SalonPoints(city)
 local result={};
 local districts=city:GetDistricts();
 local buildings=city:GetBuildings();
 for row in GameInfo.District_GreatPersonPoints() do
  if SALON_CLASSES[row.GreatPersonClassType] then
   local district=GameInfo.Districts[row.DistrictType];
   if district~=nil and WorkingDistrict(districts,district.Index) then
    result[row.GreatPersonClassType]=(result[row.GreatPersonClassType] or 0)+(tonumber(row.PointsPerTurn) or 0);
   end
  end
 end
 for row in GameInfo.Building_GreatPersonPoints() do
  if SALON_CLASSES[row.GreatPersonClassType] then
   local building=GameInfo.Buildings[row.BuildingType];
   if building~=nil and buildings:HasBuilding(building.Index)
    and not buildings:IsPillaged(building.Index) then
    result[row.GreatPersonClassType]=(result[row.GreatPersonClassType] or 0)+(tonumber(row.PointsPerTurn) or 0);
   end
  end
 end
 -- Oracle's writer points are a district modifier, not a row in either
 -- GreatPersonPoints table. Read its native Amount rather than hard-code it.
 local oracle=GameInfo.Buildings.BUILDING_ORACLE;
 if oracle~=nil and buildings:HasBuilding(oracle.Index) and not buildings:IsPillaged(oracle.Index) then
  local theater=GameInfo.Districts.DISTRICT_THEATER;
  local hasTheater=theater~=nil and WorkingDistrict(districts,theater.Index);
  if not hasTheater and GameInfo.DistrictReplaces~=nil then
   for row in GameInfo.DistrictReplaces() do
    local replacement=GameInfo.Districts[row.CivUniqueDistrictType];
    if row.ReplacesDistrictType=='DISTRICT_THEATER' and replacement~=nil
     and WorkingDistrict(districts,replacement.Index) then hasTheater=true;break;end
   end
  end
  if hasTheater then
   for row in GameInfo.ModifierArguments() do
    if row.ModifierId=='ORACLE_GREATWRITERPOINTS' and row.Name=='Amount' then
     result.GREAT_PERSON_CLASS_WRITER=(result.GREAT_PERSON_CLASS_WRITER or 0)+(tonumber(row.Value) or 0);
    end
   end
  end
 end
 return result;
end
local function GrantSalonPoints(p)
 local city=ActiveCity(p,PROMO.SALON); if city==nil then return; end
 local gpp=p:GetGreatPeoplePoints(); if gpp==nil then return; end
 local sources=SalonPoints(city);
 for _,classType in ipairs(SALON_ORDER) do
 local points=sources[classType] or 0;
 local row=GameInfo.GreatPersonClasses[classType];
  if row~=nil and points>0 then
   local key="JUSTICE_SALON_HALF_POINT_"..classType;
   local exact=points*0.5+N(p,key,0);
   local award=math.floor(exact);
   p:SetProperty(key,exact-award);
   if award>0 then gpp:ChangePointsTotal(row.Index,award); end
  end
 end
end

local function ClearStory(p,reason)
 local marker=GameInfo.Buildings[PAUSE_BUILDING];
 local cityID=N(p,"JUSTICE_STORY_PAUSE_CLEANUP_ID",-1);
 local city=cityID>=0 and p:GetCities():FindID(cityID) or nil;
 if city==nil and cityID>=0 then
  local plot=Map.GetPlot(N(p,"JUSTICE_STORY_CITY_X",-1),N(p,"JUSTICE_STORY_CITY_Y",-1));
  city=plot~=nil and Cities.GetCityInPlot(plot:GetIndex()) or nil;
 end
 if marker~=nil and city~=nil and city:GetBuildings():HasBuilding(marker.Index) then
  city:SetProperty("JUSTICE_PRODUCTION_LEGACY_SOURCE",1);
  local ok,err=pcall(function() city:GetBuildings():RemoveBuilding(marker.Index); end);
  if not ok then Log("WARNING pause marker removal failed player="..p:GetID().." city="..cityID.." error="..tostring(err)); end
 end
 if city==nil or marker==nil or not city:GetBuildings():HasBuilding(marker.Index) then
  p:SetProperty("JUSTICE_STORY_PAUSE_CLEANUP_ID",-1);
 end
 p:SetProperty("JUSTICE_STORY_PENDING",0);
 p:SetProperty("JUSTICE_STORY_ARMED_CITY_ID",-1);
 p:SetProperty("JUSTICE_STORY_CITY_ID",-1);
 p:SetProperty("JUSTICE_STORY_PENDING_TURN",-1);
 p:SetProperty("JUSTICE_STORY_ORIGINAL_CAPTURED",0);
 local remaining=city~=nil and marker~=nil and city:GetBuildings():HasBuilding(marker.Index);
 Log("story cleared player="..p:GetID().." reason="..tostring(reason)
  .." marker="..tostring(remaining).." cleanupCity="..N(p,"JUSTICE_STORY_PAUSE_CLEANUP_ID",-1));
end
local function MigratePauseSource(p)
 local previous=N(p,"JUSTICE_STORY_PAUSE_SOURCE_VERSION",0);
 if previous>=PAUSE_SOURCE_VERSION then return true; end
 local marker=GameInfo.Buildings[PAUSE_BUILDING];
 local removed=0;
 local complete=true;
 -- One version-gated old-save scan. All pause buildings are inert from this
 -- release onward; keep armed/pending story state without their yield effect.
 if marker~=nil then
  for _,city in p:GetCities():Members() do
   local buildings=city:GetBuildings();
    if buildings:HasBuilding(marker.Index) then
     city:SetProperty("JUSTICE_PRODUCTION_LEGACY_SOURCE",1);
    local ok,err=pcall(function() buildings:RemoveBuilding(marker.Index); end);
    if not ok or buildings:HasBuilding(marker.Index) then
     Log("WARNING legacy pause marker retained player="..p:GetID().." city="..city:GetID().." error="..tostring(err));
     complete=false;
    else
     removed=removed+1;
     if N(p,"JUSTICE_STORY_PAUSE_CLEANUP_ID",-1)==city:GetID() then
      p:SetProperty("JUSTICE_STORY_PAUSE_CLEANUP_ID",-1);
     end
    end
   end
  end
 end
 if not complete then return false; end
 p:SetProperty("JUSTICE_STORY_PAUSE_SOURCE_VERSION",PAUSE_SOURCE_VERSION);
 Log("pause source migration player="..p:GetID().." removed="..removed);
 return true;
end

local function RetireLegacyRepair(p)
 if N(p,"JUSTICE_STORY_LEGACY_REPAIR_RETIRE_VERSION",0)>=2 then return true; end
 local oldCount=N(p,LEGACY_REPAIR_COUNT,0);
 local oldPhase=N(p,LEGACY_REPAIR_PHASE,0);
 local receiptsCleared=0;
 local seen={};
 local key="JUSTICE_STORY_LEGACY_REPAIR_APPLIED_"..p:GetID();
 local function RetireCity(city)
  if city==nil then return true; end
  local location=city:GetX()..":"..city:GetY();
  if seen[location] then return true; end
  seen[location]=true;
  local applied=N(city,key,0);
  if applied<0 or applied>4 then
   Log("WARNING legacy repair ledger invalid player="..p:GetID().." city="..city:GetID()
    .." applied="..applied);
   return false;
  end
  if applied>0 then
   city:SetProperty(key,0);
   receiptsCleared=receiptsCleared+applied;
  end
  return true;
 end
 -- The database now makes both saved repair modifiers inert. Clear their old
 -- bookkeeping without attaching an inverse that could itself persist.
 if oldCount>0 or oldPhase>0 then
  for _,city in p:GetCities():Members() do
   if not RetireCity(city) then return false; end
  end
  local x=N(p,"JUSTICE_STORY_LEGACY_REPAIR_X",-1);
  local y=N(p,"JUSTICE_STORY_LEGACY_REPAIR_Y",-1);
  local plot=x>=0 and y>=0 and Map.GetPlot(x,y) or nil;
  local former=plot~=nil and Cities.GetCityInPlot(plot:GetIndex()) or nil;
  if not RetireCity(former) then return false; end
 end
 p:SetProperty(LEGACY_REPAIR_COUNT,0);
 p:SetProperty(LEGACY_REPAIR_PHASE,5);
 p:SetProperty("JUSTICE_STORY_LEGACY_REPAIR_RETIRE_VERSION",2);
 if oldCount>0 or receiptsCleared>0 then
  Log("legacy repair disabled player="..p:GetID().." recorded="..oldCount
   .." receiptsCleared="..receiptsCleared);
 end
 return true;
end

-- The UI submits this once per loaded session through EXECUTE_SCRIPT. The
-- monotonically increasing receipt prevents repeated city scans when the UI
-- retries an operation whose acknowledgement was delayed.
local function AuditProductionCache(p,data)
 if type(data)~="string" then return true; end
 local rows={}; local seen={};
 for record in data:gmatch("[^;]+") do
  local idText,percentText,yieldText=record:match("^([^,]+),([^,]+),([^,]+)$");
  local id,percent,observed=tonumber(idText),tonumber(percentText),tonumber(yieldText);
  if id==nil or percent==nil or observed==nil or percent~=math.floor(percent)
   or math.abs(percent)>50000 or observed~=observed then return false; end
  local city=p:GetCities():FindID(id);
  if city==nil or city:GetOwner()~=p:GetID() or seen[id] then return false; end
  seen[id]=true;
  local actual=city:GetYield(YieldTypes.PRODUCTION);
  if type(actual)~="number" or math.abs(actual-observed)>0.11 then
   Log("production audit stale city="..id.." observed="..observed.." actual="..tostring(actual));
   return false;
  end
  rows[#rows+1]={city=city,percent=percent,before=actual};
 end
 local tracked={}; local trackedSet={};
 local function Track(id)
  if not trackedSet[id] then trackedSet[id]=true; tracked[#tracked+1]=id; end
 end
 local previous=p:GetProperty("JUSTICE_PRODUCTION_AUDIT_CITIES") or "";
 for id in tostring(previous):gmatch("%d+") do Track(tonumber(id)); end
 local needsVerify=false;
 for _,row in ipairs(rows) do
  local city,percent=row.city,row.percent;
  local id=city:GetID();
  local pending=N(city,"JUSTICE_PRODUCTION_CACHE_PENDING",0);
  if pending~=0 then
   if percent~=0 then
    -- The UI may still be reading the pre-operation snapshot. Never attach
    -- another counter until the previous operation has been observed.
    Log("production cache awaiting verification city="..id.." percent="..percent.." yield="..row.before);
    return false;
   end
   city:SetProperty("JUSTICE_PRODUCTION_CACHE_PENDING",0);
   Log("production cache VERIFIED city="..id.." yield="..row.before);
  elseif percent~=0 then
   local rawReceipt=city:GetProperty("JUSTICE_STORY_LEGACY_REPAIR_APPLIED_"..p:GetID());
   local legacy=rawReceipt~=nil or N(city,"JUSTICE_PRODUCTION_LEGACY_SOURCE",0)==1
    or (N(p,"JUSTICE_STORY_CITY_X",-1)==city:GetX()
      and N(p,"JUSTICE_STORY_CITY_Y",-1)==city:GetY())
    or (N(p,"JUSTICE_STORY_LEGACY_REPAIR_X",-1)==city:GetX()
      and N(p,"JUSTICE_STORY_LEGACY_REPAIR_Y",-1)==city:GetY());
   local units=math.floor(math.abs(percent)/1000+0.5)*(percent<0 and -1 or 1);
   if not legacy or units==0 or math.abs(percent-units*1000)>100 then
    Log("production cache not attributed to Justice city="..id.." percent="..percent);
   else
    city:SetProperty("JUSTICE_PRODUCTION_LEGACY_SOURCE",1);
    local prefix=units>0 and "LOTM_JUSTICE_CACHE_MINUS_" or "LOTM_JUSTICE_CACHE_PLUS_";
    for index=1,math.floor(math.abs(units)/10) do city:AttachModifierByID(prefix.."10000"); end
    for index=1,math.abs(units)%10 do city:AttachModifierByID(prefix.."1000"); end
    city:SetProperty("JUSTICE_PRODUCTION_CACHE_UNITS",N(city,"JUSTICE_PRODUCTION_CACHE_UNITS",0)-units);
    city:SetProperty("JUSTICE_PRODUCTION_CACHE_PENDING",percent);
    Track(id);
    needsVerify=true;
    Log("production cache corrected city="..id.." percent="..percent.." correction="..(-units*1000)
     .." before="..row.before.." after="..tostring(city:GetYield(YieldTypes.PRODUCTION)));
   end
  end
 end
 table.sort(tracked);
 local text={}; for _,id in ipairs(tracked) do text[#text+1]=tostring(id); end
 p:SetProperty("JUSTICE_PRODUCTION_AUDIT_CITIES",table.concat(text,","));
 p:SetProperty("JUSTICE_PRODUCTION_AUDIT_VERSION",1);
 p:SetProperty("JUSTICE_PRODUCTION_VERIFY_NEEDED",needsVerify and 1 or 0);
 return true;
end

local function AuditStoryLoad(p,serial,parameters)
 local previous=N(p,"JUSTICE_STORY_LOAD_AUDIT_SERIAL",0);
 if serial<=previous then return true; end
 if serial~=previous+1 then return false; end
 local migrated=MigratePauseSource(p);
 local retired=RetireLegacyRepair(p);
 if not migrated or not retired then return false; end
 if not AuditProductionCache(p,parameters and parameters.ProductionAuditData) then return false; end
 local turn=Game.GetCurrentGameTurn();
 local pending=N(p,"JUSTICE_STORY_PENDING",0)==1;
 local special=pending and N(p,"JUSTICE_STORY_PENDING_TURN",-1)==turn;
 if pending and not special then ClearStory(p,"load-non-special-turn"); end
 -- Version 5 performed the one-time full old-save scan. On later loads,
 -- inspect only the current/cleanup city; no per-event all-city iteration.
 local marker=GameInfo.Buildings[PAUSE_BUILDING];
 local seen={};
 local checked=0;
 local removed=0;
 local function CheckCity(cityID)
  if cityID<0 or seen[cityID] then return true; end
  seen[cityID]=true;
  local city=p:GetCities():FindID(cityID);
  if city==nil or marker==nil then return true; end
  checked=checked+1;
  local buildings=city:GetBuildings();
   if not buildings:HasBuilding(marker.Index) then return true; end
  local ok,err=pcall(function() buildings:RemoveBuilding(marker.Index); end);
  if not ok or buildings:HasBuilding(marker.Index) then
   Log("WARNING load audit pause marker retained player="..p:GetID().." city="..cityID
    .." error="..tostring(err));
   return false;
  end
  removed=removed+1;
  return true;
 end
 if not CheckCity(N(p,"JUSTICE_GOVERNOR_CITY_ID",-1))
  or not CheckCity(N(p,"JUSTICE_STORY_CITY_ID",-1))
  or not CheckCity(N(p,"JUSTICE_STORY_PAUSE_CLEANUP_ID",-1)) then return false; end
 p:SetProperty("JUSTICE_STORY_PAUSE_CLEANUP_ID",-1);
 p:SetProperty("JUSTICE_STORY_LOAD_AUDIT_SERIAL",serial);
 Log("load production audit player="..p:GetID().." serial="..serial.." turn="..turn
  .." special="..tostring(special).." checked="..checked.." markersRemoved="..removed
  .." legacyRepairRetired="..N(p,"JUSTICE_STORY_LEGACY_REPAIR_RETIRE_VERSION",0));
 return true;
end
local function ArmStory(p,city)
 p:SetProperty("JUSTICE_STORY_ARMED_CITY_ID",city:GetID());
 Log("story armed player="..p:GetID().." city="..city:GetID());
 return true;
end
local function BeginStory(p,city,turn)
 if N(p,"JUSTICE_STORY_ARMED_CITY_ID",-1)~=city:GetID() then return false; end
 p:SetProperty("JUSTICE_STORY_ARMED_CITY_ID",-1);
 p:SetProperty("JUSTICE_STORY_ORIGINAL_CAPTURED",0);
 p:SetProperty("JUSTICE_STORY_RESULT",nil);
 p:SetProperty("JUSTICE_STORY_CITY_ID",city:GetID());
 p:SetProperty("JUSTICE_STORY_PENDING_TURN",turn);
 p:SetProperty("JUSTICE_STORY_PENDING",1);
 Log("story ready player="..p:GetID().." city="..city:GetID().." turn="..turn);
 return true;
end

local function OnRecordStoryOriginal(playerID,parameters)
 if not Enabled() or parameters==nil then return; end
 local p=Player(playerID); if p==nil then return; end
 if N(p,"JUSTICE_STORY_PENDING",0)~=1 or N(p,"JUSTICE_STORY_ORIGINAL_CAPTURED",0)==1
  or N(p,"JUSTICE_STORY_PENDING_TURN",-1)~=Game.GetCurrentGameTurn()
  or tonumber(parameters.CityID)~=N(p,"JUSTICE_STORY_CITY_ID",-1) then return; end
 local kind=parameters.Kind;
 if kind~="BUILDING" and kind~="PROJECT" and kind~="UNIT"
  and kind~="DISTRICT" and kind~="NONE" then return; end
 local typeIndex=tonumber(parameters.TypeID) or -1;
 local progress=tonumber(parameters.Progress) or 0;
 if typeIndex< -1 or progress<0 then return; end
 p:SetProperty("JUSTICE_STORY_ORIGINAL_PRODUCTION_TYPE",kind);
 p:SetProperty("JUSTICE_STORY_ORIGINAL_PRODUCTION_ID",typeIndex);
 p:SetProperty("JUSTICE_STORY_ORIGINAL_PROGRESS",progress);
 p:SetProperty("JUSTICE_STORY_ORIGINAL_CAPTURED",1);
end

local function OnTurn(playerID,isFirstTimeThisTurn)
 if not Enabled() or isFirstTimeThisTurn==false then return; end
 local p=Player(playerID); if p==nil then return; end
 MigratePauseSource(p);
 RetireLegacyRepair(p);
 local turn=Game.GetCurrentGameTurn();
 if N(p,"JUSTICE_LAST_SETTLED_TURN",-1)==turn then return; end
 p:SetProperty("JUSTICE_LAST_SETTLED_TURN",turn);
 if N(p,"JUSTICE_STORY_PAUSE_CLEANUP_ID",-1)>=0 and N(p,"JUSTICE_STORY_PENDING",0)~=1
  and N(p,"JUSTICE_STORY_ARMED_CITY_ID",-1)<0 then
  ClearStory(p,"retry-pause-cleanup");
 end
 if N(p,"JUSTICE_STORY_PENDING",0)==1 and N(p,"JUSTICE_STORY_PENDING_TURN",-1)<turn then
  ClearStory(p,"expired-on-next-turn");
 end
 SetSponsorIncome(p);
 ClearHolderUnstable(p);
 GrantSalonPoints(p);
 local envoyCity=ActiveCity(p,PROMO.TAROT);
 if envoyCity~=nil then
  local count=N(p,"JUSTICE_FOOL_ENVOY_COUNTER",0)+1;
  if count>=7 then
   local source="JUSTICE:"..playerID..":"..turn;
   local ok=LOTM_WORLD_Churches~=nil and LOTM_WORLD_Churches.ChangeEnvoys(playerID,"FOOL",1,source);
   if ok then p:SetProperty("JUSTICE_FOOL_ENVOY_COUNTER",0);
   else p:SetProperty("JUSTICE_FOOL_ENVOY_COUNTER",6); end
   Log("envoy player="..playerID.." turn="..turn.." changed="..tostring(ok));
  else p:SetProperty("JUSTICE_FOOL_ENVOY_COUNTER",count); end
 end
 local storyCity=ActiveCity(p,PROMO.STORY);
 if N(p,"JUSTICE_STORY_ARMED_CITY_ID",-1)>=0
  and (storyCity==nil or storyCity:GetID()~=N(p,"JUSTICE_STORY_ARMED_CITY_ID",-1)) then
  ClearStory(p,"armed-governor-inactive");
 end
 if storyCity~=nil then
  local count=N(p,"JUSTICE_STORY_COUNTER",0)+1;
  Log("story clock player="..playerID.." city="..storyCity:GetID().." turn="..turn.." count="..count.."/7");
  if count>=7 then
   if BeginStory(p,storyCity,turn) then p:SetProperty("JUSTICE_STORY_COUNTER",0);
   else
    ArmStory(p,storyCity);
    p:SetProperty("JUSTICE_STORY_COUNTER",6);
   end
  elseif count==6 then
   if ArmStory(p,storyCity) then p:SetProperty("JUSTICE_STORY_COUNTER",6);
   else p:SetProperty("JUSTICE_STORY_COUNTER",5); end
  else p:SetProperty("JUSTICE_STORY_COUNTER",count); end
 end
end

local function OnCompleteStory(playerID,parameters)
 if not Enabled() then return; end
 local p=Player(playerID); if p==nil or parameters==nil then return; end
 local turn=Game.GetCurrentGameTurn();
 if N(p,"JUSTICE_STORY_PENDING",0)~=1
  or N(p,"JUSTICE_STORY_PENDING_TURN",-1)~=turn
  or N(p,"JUSTICE_STORY_USED_TURN",-1)==turn then return; end
 local city=ActiveCity(p,PROMO.STORY);
 if city==nil or city:GetID()~=N(p,"JUSTICE_STORY_CITY_ID",-1) then
  ClearStory(p,"governor-inactive"); return;
 end
 if tonumber(parameters.CityID)~=city:GetID() then
  Log("story rejected player="..playerID.." reason=city-mismatch"); return;
 end
 local queue=city:GetBuildQueue(); if queue==nil then return; end
 local kind=parameters.TargetKind;
 local typeIndex=tonumber(parameters.TargetID) or -1;
 if kind~="BUILDING" and kind~="PROJECT" then
  Log("story rejected player="..playerID.." reason=invalid-target kind="..tostring(kind)); return;
 end
 local target=kind=="BUILDING" and GameInfo.Buildings[typeIndex] or GameInfo.Projects[typeIndex];
 if target==nil or tonumber(parameters.TargetHash)~=target.Hash then
  p:SetProperty("JUSTICE_STORY_RESULT","LOC_LOTM_JUSTICE_STORY_SELECT");
  Log("story rejected invalid target id="..tostring(parameters.TargetID)); return;
 end
 -- Validate the item already accepted by the native queue. CanProduce is a
 -- start-production/UI query, not a Gameplay completion precondition.
 local readOK,current=pcall(function() return queue:CurrentlyBuilding(); end);
 local currentRow=nil;
 if readOK and current~=nil then
  if kind=="BUILDING" then currentRow=GameInfo.Buildings[current];
  elseif kind=="PROJECT" then currentRow=GameInfo.Projects[current]; end
 end
 if currentRow==nil or currentRow.Hash~=target.Hash then
  p:SetProperty("JUSTICE_STORY_RESULT","LOC_LOTM_JUSTICE_STORY_SELECT");
  Log("story rejected player="..playerID.." reason=current-target-mismatch target="
   ..tostring(target.Hash).." readOK="..tostring(readOK).." current="..tostring(current)); return;
 end
 -- FinishProgress commits precisely the selected production item. Unlike
 -- AddProgress(99999), it cannot carry unspent production into another item.
 Log("story execute city="..city:GetID().." target="..target.Hash.." turn="..turn);
 p:SetProperty("JUSTICE_STORY_USED_TURN",turn);
 local finished,err=pcall(function() queue:FinishProgress(); end);
 if not finished then
  p:SetProperty("JUSTICE_STORY_USED_TURN",-1);
  p:SetProperty("JUSTICE_STORY_RESULT","LOC_LOTM_JUSTICE_STORY_FAILED");
  Log("WARNING story finish failed player="..playerID.." error="..tostring(err)); return;
 end
 ClearStory(p,"completed:"..kind..":"..tostring(target.Hash));
end

local function OnGovernorChanged(playerID)
 if not Enabled() then return; end
 local p=Player(playerID); if p==nil then return; end
 SetSponsorIncome(p);
 ClearHolderUnstable(p);
 if N(p,"JUSTICE_STORY_PENDING",0)==1 then
  local city=ActiveCity(p,PROMO.STORY);
  if city==nil or city:GetID()~=N(p,"JUSTICE_STORY_CITY_ID",-1) then
   ClearStory(p,"governor-changed");
  end
 end
 if N(p,"JUSTICE_STORY_ARMED_CITY_ID",-1)>=0 then
  local city=ActiveCity(p,PROMO.STORY);
  if city==nil or city:GetID()~=N(p,"JUSTICE_STORY_ARMED_CITY_ID",-1) then
   ClearStory(p,"armed-governor-changed");
  end
 end
 if N(p,"JUSTICE_STORY_COUNTER",0)==6 and N(p,"JUSTICE_STORY_PENDING",0)~=1
  and N(p,"JUSTICE_STORY_ARMED_CITY_ID",-1)<0 then
  local city=ActiveCity(p,PROMO.STORY);
  if city~=nil then ArmStory(p,city); end
 end
end

local function OnGovernorSnapshot(playerID,parameters)
 if not Enabled() or parameters==nil then return; end
 local p=Player(playerID); if p==nil then return; end
 local snapshotSerial=tonumber(parameters.SnapshotSerial);
 local previousSerial=N(p,"JUSTICE_GOVERNOR_SNAPSHOT_SERIAL",0);
 if snapshotSerial~=nil and (snapshotSerial~=math.floor(snapshotSerial)
  or snapshotSerial<previousSerial or snapshotSerial>previousSerial+1) then return; end
 local cityID=tonumber(parameters.CityID) or -1;
 local city=cityID>=0 and p:GetCities():FindID(cityID) or nil;
 if cityID>=0 and city==nil then return; end
 p:SetProperty("JUSTICE_GOVERNOR_CITY_ID",cityID);
 p:SetProperty("JUSTICE_GOVERNOR_ESTABLISHED",parameters.Established==1 and 1 or 0);
 p:SetProperty("JUSTICE_GOVERNOR_NEUTRALIZED",parameters.Neutralized==1 and 1 or 0);
 local has={};
 for _,typeName in ipairs({PROMO.SPONSOR,PROMO.COUNSEL,PROMO.SALON,
   PROMO.SUGGESTION,PROMO.TAROT,PROMO.STORY}) do
  has[typeName]=parameters[typeName]==1;
 end
 -- HasPromotion is the ownership check. A saved, already purchased promotion
 -- must not be revoked by reapplying today's purchase prerequisites.
 -- The native governor tree still controls purchasing new promotions.
 for _,typeName in ipairs({PROMO.SPONSOR,PROMO.COUNSEL,PROMO.SALON,
   PROMO.SUGGESTION,PROMO.TAROT,PROMO.STORY}) do
  p:SetProperty("JUSTICE_GOVERNOR_HAS_"..typeName,has[typeName] and 1 or 0);
 end
 Log("governor snapshot player="..playerID.." city="..cityID
  .." established="..N(p,"JUSTICE_GOVERNOR_ESTABLISHED",0)
  .." neutralized="..N(p,"JUSTICE_GOVERNOR_NEUTRALIZED",0)
  .." counsel="..N(p,"JUSTICE_GOVERNOR_HAS_"..PROMO.COUNSEL,0)
  .." salon="..N(p,"JUSTICE_GOVERNOR_HAS_"..PROMO.SALON,0)
  .." suggestion="..N(p,"JUSTICE_GOVERNOR_HAS_"..PROMO.SUGGESTION,0)
  .." tarot="..N(p,"JUSTICE_GOVERNOR_HAS_"..PROMO.TAROT,0)
  .." nativeStory="..tostring(parameters[PROMO.STORY]==1 and 1 or 0)
  .." story="..N(p,"JUSTICE_GOVERNOR_HAS_"..PROMO.STORY,0));
 OnGovernorChanged(playerID);
 local parts={tostring(cityID),tostring(parameters.Established==1 and 1 or 0),
  tostring(parameters.Neutralized==1 and 1 or 0)};
 for _,typeName in ipairs({PROMO.SPONSOR,PROMO.COUNSEL,PROMO.SALON,
   PROMO.SUGGESTION,PROMO.TAROT,PROMO.STORY}) do
  parts[#parts+1]=tostring(parameters[typeName]==1 and 1 or 0);
 end
 p:SetProperty("JUSTICE_GOVERNOR_SNAPSHOT_DIGEST",table.concat(parts,":"));
 if snapshotSerial~=nil then p:SetProperty("JUSTICE_GOVERNOR_SNAPSHOT_SERIAL",snapshotSerial); end
 -- The ownership receipt is independent of optional old-save production work.
 -- Retain the old combined command only for already queued legacy UI requests.
 MigratePauseSource(p);
 RetireLegacyRepair(p);
 local serial=tonumber(parameters.LoadAuditSerial);
 if serial~=nil then AuditStoryLoad(p,serial,parameters); end
end

local function OnProductionAudit(playerID,parameters)
 if not Enabled() or parameters==nil then return; end
 local p=Player(playerID); if p==nil then return; end
 if tonumber(parameters.GovernorSnapshotSerial)~=N(p,"JUSTICE_GOVERNOR_SNAPSHOT_SERIAL",-1)
  or type(parameters.ProductionAuditData)~="string" then
  Log("production audit rejected: missing snapshot receipt or observation player="..playerID);
  return;
 end
 local serial=tonumber(parameters.LoadAuditSerial);
 if serial==nil or serial~=math.floor(serial) then return; end
 AuditStoryLoad(p,serial,parameters);
end

if Enabled() then
 if LOTM_MP_TurnSync.IsRescueModeConfigured() then
  LOTM_MP_TurnSync.AddSynchronized(OnTurn,"JusticeGovernor");
 else LOTM_MP_TurnSync.Add(OnTurn,"JusticeGovernor"); end
 GameEvents[STORY_COMMAND].Add(OnCompleteStory);
 GameEvents.LOTM_JUSTICE_RecordStoryOriginal.Add(OnRecordStoryOriginal);
 GameEvents.LOTM_JUSTICE_UpdateGovernor.Add(OnGovernorSnapshot);
 GameEvents.LOTM_JUSTICE_AuditProduction.Add(OnProductionAudit);
 Log("initialized governor; story command="..STORY_COMMAND);
end
