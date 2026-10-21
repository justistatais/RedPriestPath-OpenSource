-- Shared Fors/Leonard A/B state. Rescue Leonard C/D use a separate module.
-- Persistent history and visibility belong
-- to synchronized Gameplay; the UI only submits native governor snapshots.
LOTM_MS = LOTM_MS or {};

local MAG = "MAGICIAN";
local STAR = "STAR";
local RECORD_PROMO = "GOVERNOR_PROMOTION_LOTM_MAGICIAN_RECORD";
local WATCH_PROMO = "GOVERNOR_PROMOTION_LOTM_STAR_WATCHER";
local RECORD_VERSION = 1;
local SIGHT_VERSION = 1;
local historyCache = {};
local PROMOTIONS={
 MAGICIAN={
  "GOVERNOR_PROMOTION_LOTM_MAGICIAN_GATE",
  "GOVERNOR_PROMOTION_LOTM_MAGICIAN_SERIAL",
  "GOVERNOR_PROMOTION_LOTM_MAGICIAN_SUPPLY",
  "GOVERNOR_PROMOTION_LOTM_MAGICIAN_RECORD",
  "GOVERNOR_PROMOTION_LOTM_MAGICIAN_REPLAY",
  "GOVERNOR_PROMOTION_LOTM_MAGICIAN_BESTSELLER"},
 STAR={
  "GOVERNOR_PROMOTION_LOTM_STAR_WATCHER",
  "GOVERNOR_PROMOTION_LOTM_STAR_PATROL",
  "GOVERNOR_PROMOTION_LOTM_STAR_INVESTIGATION",
  "GOVERNOR_PROMOTION_LOTM_STAR_CONTACT",
  "GOVERNOR_PROMOTION_LOTM_STAR_INTERROGATION",
  "GOVERNOR_PROMOTION_LOTM_STAR_GUARDIAN"}
};
local function Log(message) print("[LOTM_MS] "..tostring(message)); end
local function N(object,key,fallback)
 if object==nil then return fallback; end
 local raw=object:GetProperty(key);
 local value=tonumber(raw);
 return value~=nil and value or fallback;
end
local function Player(playerID)
 local player=Players[playerID];
 return player~=nil and player:IsAlive() and player:IsMajor() and player or nil;
end
local function Enabled()
 return GameInfo.Governors~=nil and GameInfo.Governors["GOVERNOR_LOTM_MAGICIAN"]~=nil
  and GameInfo.Governors["GOVERNOR_LOTM_STAR"]~=nil;
end
local function Rescue() return LOTM_MP_TurnSync.IsRescueModeConfigured(); end
local RESCUE_STAR_PROMOTIONS={
 "GOVERNOR_PROMOTION_LOTM_STAR_WATCHER",
 "GOVERNOR_PROMOTION_LOTM_STAR_PATROL",
 "GOVERNOR_PROMOTION_LOTM_STAR_INVESTIGATION",
 "GOVERNOR_PROMOTION_LOTM_STAR_CASE_FILES",
 "GOVERNOR_PROMOTION_LOTM_STAR_RED_GLOVES",
 "GOVERNOR_PROMOTION_LOTM_STAR_HIDDEN_WORLD"};
local function ActiveCity(player,governor,promotion)
 if player==nil or not Enabled() then return nil; end
 local prefix="LOTM_MS_"..governor.."_";
 if N(player,prefix.."ESTABLISHED",0)~=1 or N(player,prefix.."NEUTRALIZED",0)~=0
  or N(player,prefix.."HAS_"..promotion,0)~=1 then return nil; end
 local cityID=N(player,prefix.."CITY_ID",-1);
 local city=cityID>=0 and player:GetCities():FindID(cityID) or nil;
 if city==nil or city:GetOwner()~=player:GetID() then return nil; end
 return city;
end

local function RefreshPlayerEffects(player)
 if Rescue() then
  -- Retire any existing normal lease; never attach its modifiers in rescue.
  for _,name in ipairs({"CONTACT_ACTIVE","CONTACT_NATIVE419_ACTIVE","GUARDIAN_ACTIVE"}) do
   local row=GameInfo.Resources["RESOURCE_LOTM_MS_"..name];
   if row~=nil then
    local resources=player:GetResources(); local amount=resources:GetResourceAmount(row.Index) or 0;
    if amount~=0 then resources:ChangeResourceAmount(row.Index,-amount); end
   end
  end
  return;
 end
 -- Retire the old saved instance by its own gate; never apply an inverse
 -- visibility modifier, which could subtract another source's contribution.
 local legacy=GameInfo.Resources["RESOURCE_LOTM_MS_CONTACT_ACTIVE"];
 if legacy~=nil then
  local resources=player:GetResources();
  local amount=resources:GetResourceAmount(legacy.Index) or 0;
  if amount~=0 then resources:ChangeResourceAmount(legacy.Index,-amount);Log("retired custom visibility player="..player:GetID());end
 end
 local effects={
  {"CONTACT_NATIVE419","GOVERNOR_PROMOTION_LOTM_STAR_CONTACT",{"LOTM_MS_CONTACT_PLAYER419"}},
  {"GUARDIAN","GOVERNOR_PROMOTION_LOTM_STAR_GUARDIAN",{"LOTM_MS_GUARDIAN_PLAYER417","LOTM_MS_COUNTERSPY_PLAYER417"}}
 };
 for _,entry in ipairs(effects) do
  local row=GameInfo.Resources["RESOURCE_LOTM_MS_"..entry[1].."_ACTIVE"];
  if row~=nil then
   local resource=player:GetResources();
   local wanted=ActiveCity(player,STAR,entry[2])~=nil and 1 or 0;
   for _,modifier in ipairs(entry[3]) do
    local key="LOTM_MS_ATTACHED_"..modifier;
    if N(player,key,0)~=1 then
     local ok,result=pcall(function() return player:AttachModifierByID(modifier); end);
     if ok and result~=false then player:SetProperty(key,1);
     else Log("player effect attach failed "..modifier.." error="..tostring(result)); end
    end
   end
   local current=resource:GetResourceAmount(row.Index) or 0;
   if current~=wanted then
    resource:ChangeResourceAmount(row.Index,wanted-current);
    Log("player effect="..entry[1].." player="..player:GetID().." active="..wanted
     .." actual="..tostring(resource:GetResourceAmount(row.Index)));
   end
  end
 end
end

local function EligibleBuilding(row)
 return row~=nil and (tonumber(row.Cost) or 0)>0 and row.InternalOnly~=true
  and row.InternalOnly~=1;
end
local function EligibleDistrict(row)
 return row~=nil and (tonumber(row.Cost) or 0)>0
  and row.DistrictType~="DISTRICT_CITY_CENTER";
end
local function RecordKey(kind,typeName)
 return "LOTM_MS_RECORD_"..kind.."_"..typeName;
end
local function Cache(player)
 local playerID=player:GetID();
 if historyCache[playerID]~=nil then return historyCache[playerID]; end
 local cache={B={},D={},hasB={},hasD={}};
 for row in GameInfo.Buildings() do
  if EligibleBuilding(row) and N(player,RecordKey("B",row.BuildingType),0)==1 then
   cache.B[#cache.B+1]=row.BuildingType; cache.hasB[row.BuildingType]=true;
  end
 end
 for row in GameInfo.Districts() do
  if EligibleDistrict(row) and N(player,RecordKey("D",row.DistrictType),0)==1 then
   cache.D[#cache.D+1]=row.DistrictType; cache.hasD[row.DistrictType]=true;
  end
 end
 table.sort(cache.B); table.sort(cache.D);
 historyCache[playerID]=cache;
 return cache;
end
local function SetCityModifier(city,playerID,kind,typeName,enable)
 if city==nil then return false; end
 local stateKey="LOTM_MS_RECORD_APPLIED_"..playerID.."_"..kind.."_"..typeName;
 local attached=N(city,stateKey,0)==1;
 if attached==enable then return true; end
 local modifier="LOTM_MS_RECORD_"..kind.."_"..(enable and "POS_" or "NEG_")..typeName;
 local ok,result=pcall(function() return city:AttachModifierByID(modifier); end);
 if not ok or result==false then
  Log("record modifier rejected city="..city:GetID().." modifier="..modifier.." error="..tostring(result));
  return false;
 end
 city:SetProperty(stateKey,enable and 1 or 0);
 return true;
end
local function ApplyAll(player,city,enable)
 if city==nil then return; end
 local cache=Cache(player);
 for _,typeName in ipairs(cache.B) do SetCityModifier(city,player:GetID(),"B",typeName,enable); end
 for _,typeName in ipairs(cache.D) do SetCityModifier(city,player:GetID(),"D",typeName,enable); end
end
local function FormerCity(player)
 local x=N(player,"LOTM_MS_RECORD_ACTIVE_X",-1);
 local y=N(player,"LOTM_MS_RECORD_ACTIVE_Y",-1);
 local plot=x>=0 and y>=0 and Map.GetPlot(x,y) or nil;
 return plot~=nil and Cities.GetCityInPlot(plot:GetIndex()) or nil;
end
local function RefreshRecordCity(player)
 local desired=ActiveCity(player,MAG,RECORD_PROMO);
 local desiredID=desired~=nil and desired:GetID() or -1;
 local currentID=N(player,"LOTM_MS_RECORD_ACTIVE_CITY",-1);
 local currentX=N(player,"LOTM_MS_RECORD_ACTIVE_X",-1);
 local currentY=N(player,"LOTM_MS_RECORD_ACTIVE_Y",-1);
 if currentID==desiredID and (desired==nil or
  (currentX==desired:GetX() and currentY==desired:GetY())) then return; end
 if currentID>=0 then ApplyAll(player,FormerCity(player),false); end
 if desired~=nil then ApplyAll(player,desired,true); end
 player:SetProperty("LOTM_MS_RECORD_ACTIVE_CITY",desiredID);
 player:SetProperty("LOTM_MS_RECORD_ACTIVE_X",desired~=nil and desired:GetX() or -1);
 player:SetProperty("LOTM_MS_RECORD_ACTIVE_Y",desired~=nil and desired:GetY() or -1);
 Log("record city player="..player:GetID().." old="..currentID.." new="..desiredID);
end
local function Record(player,kind,row)
 if row==nil then return; end
 local typeName=kind=="B" and row.BuildingType or row.DistrictType;
 if kind=="B" and not EligibleBuilding(row) then return; end
 if kind=="D" and not EligibleDistrict(row) then return; end
 local key=RecordKey(kind,typeName);
 if N(player,key,0)==1 then return; end
 player:SetProperty(key,1);
 local cache=Cache(player);
 local membership=kind=="B" and cache.hasB or cache.hasD;
 if not membership[typeName] then
  membership[typeName]=true;
  cache[kind][#cache[kind]+1]=typeName;
  table.sort(cache[kind]);
 end
 local city=ActiveCity(player,MAG,RECORD_PROMO);
 if city~=nil then SetCityModifier(city,player:GetID(),kind,typeName,true); end
 Log("history player="..player:GetID().." kind="..kind.." type="..typeName);
end
local function MigrateHistory(player)
 if N(player,"LOTM_MS_RECORD_VERSION",0)>=RECORD_VERSION then return; end
 local oldSave=Game.GetCurrentGameTurn()>1;
 local buildings=0; local districts=0;
 if oldSave then
  -- One-time compatibility scan only. A new game records completed events.
  for _,city in player:GetCities():Members() do
   local cityBuildings=city:GetBuildings();
   for row in GameInfo.Buildings() do
    if EligibleBuilding(row) and cityBuildings:HasBuilding(row.Index) then
     local before=N(player,RecordKey("B",row.BuildingType),0);
     Record(player,"B",row);
     if before==0 then buildings=buildings+1; end
    end
   end
   local cityDistricts=city:GetDistricts();
   for row in GameInfo.Districts() do
    if EligibleDistrict(row) and cityDistricts:HasDistrict(row.Index,true) then
     local before=N(player,RecordKey("D",row.DistrictType),0);
     Record(player,"D",row);
     if before==0 then districts=districts+1; end
    end
   end
  end
 end
 player:SetProperty("LOTM_MS_RECORD_VERSION",RECORD_VERSION);
 player:SetProperty("LOTM_MS_RECORD_MIGRATED_BUILDINGS",buildings);
 player:SetProperty("LOTM_MS_RECORD_MIGRATED_DISTRICTS",districts);
 Log("history initialized player="..player:GetID().." oldSave="..tostring(oldSave).." B="..buildings.." D="..districts);
end

local function CSV(indices)
 local parts={}; for _,index in ipairs(indices) do parts[#parts+1]=tostring(index); end
 return table.concat(parts,",");
end
local function FromCSV(value)
 local result={}; local seen={};
 for token in string.gmatch(tostring(value or ""),"[^,]+") do
  local index=tonumber(token);
  if index~=nil and not seen[index] and Map.GetPlotByIndex(index)~=nil then
   result[#result+1]=index; seen[index]=true;
  end
 end
 return result;
end
local function SightPlots(city)
 local result={}; local seen={};
 if city==nil then return result; end
 for dx=-6,6 do for dy=-6,6 do
  local plot=Map.GetPlotXYWithRangeCheck(city:GetX(),city:GetY(),dx,dy,6);
  local index=plot~=nil and plot:GetIndex() or -1;
  if index>=0 and not seen[index] then result[#result+1]=index; seen[index]=true; end
 end end
 table.sort(result);
 return result;
end
local function RefreshSight(player)
 local visibility=PlayersVisibility[player:GetID()]; if visibility==nil then return; end
 local city=ActiveCity(player,STAR,WATCH_PROMO);
 local wanted=SightPlots(city);
 local wantedCSV=CSV(wanted);
 local key="LOTM_MS_STAR_SIGHT_PLOTS_V"..SIGHT_VERSION;
 local previousCSV=player:GetProperty(key) or "";
 local previous=FromCSV(previousCSV);
 local oldSet={}; local newSet={};
 for _,index in ipairs(previous) do oldSet[index]=true; end
 for _,index in ipairs(wanted) do newSet[index]=true; end
 local restored=0;
 -- The plot ledger survives a save. Restore a missing visibility contribution
 -- when the engine has rebuilt sight without its runtime count.
 for _,index in ipairs(wanted) do
  if oldSet[index] and not visibility:IsVisible(index) then
   visibility:ChangeVisibilityCount(index,1);
   restored=restored+1;
  end
 end
 if previousCSV==wantedCSV then
  if restored>0 then Log("sight restored player="..player:GetID().." plots="..restored); end
  return;
 end
 for _,index in ipairs(previous) do
  if not newSet[index] and visibility:GetVisibilityCount(index)>0 then
   visibility:ChangeVisibilityCount(index,-1);
  end
 end
 for _,index in ipairs(wanted) do
  if not oldSet[index] then visibility:ChangeVisibilityCount(index,1); end
 end
 player:SetProperty(key,wantedCSV);
 Log("sight player="..player:GetID().." city="..tostring(city~=nil and city:GetID() or -1).." plots="..#wanted.." restored="..restored);
end

function LOTM_MS.RefreshStarSight(playerID)
 local p=Players[playerID];
 if p~=nil and p:IsMajor() and Enabled() then RefreshSight(p); end
end

local function OnBuildingConstructed(playerID,cityID,buildingIndex,plotIndex,isOriginalConstruction)
 if not Enabled() or not isOriginalConstruction then return; end
 local player=Player(playerID); if player==nil then return; end
 local city=player:GetCities():FindID(cityID);
 local row=GameInfo.Buildings[buildingIndex];
 if city~=nil and row~=nil and city:GetBuildings():HasBuilding(row.Index) then
  Record(player,"B",row);
 end
end
local function OnDistrictConstructed(playerID,districtIndex,x,y)
 if not Enabled() then return; end
 local player=Player(playerID); if player==nil then return; end
 local row=GameInfo.Districts[districtIndex];
 local plot=Map.GetPlot(x,y);
 local city=plot~=nil and Cities.GetCityInPlot(plot:GetIndex()) or nil;
 if city~=nil and city:GetOwner()==playerID and row~=nil
  and city:GetDistricts():HasDistrict(row.Index,true) then Record(player,"D",row); end
end
local function AuditPlayerEffects(player)
 if Rescue() then return; end
 -- One-time old-save audit, never a per-turn modifier scan. Native binding
 -- usage follows Bug_Amon_Gameplay.GetExtraBoostFromModifiers.
 if N(player,"LOTM_MS_EFFECT_AUDIT419",0)==1 or GameEffects==nil then return;end
 local ok,err=pcall(function()
  local found=0;
  for _,id in ipairs(GameEffects.GetModifiers()) do
   local definition=GameEffects.GetModifierDefinition(id);
   if definition~=nil and (definition.Id=="LOTM_MS_CONTACT_PLAYER417" or definition.Id=="LOTM_MS_CONTACT_PLAYER419"
    or definition.Id=="LOTM_MS_GUARDIAN_PLAYER417" or definition.Id=="LOTM_MS_COUNTERSPY_PLAYER417") then
    local owner=GameEffects.GetModifierOwner(id);
    if GameEffects.GetObjectsPlayerId(owner)==player:GetID() then
     found=found+1;
     local requirement=GameEffects.GetModifierOwnerRequirementSet(id);
     local state=requirement and GameEffects.GetRequirementSetState(requirement) or "none";
     Log("native effect audit player="..player:GetID().." id="..definition.Id
      .." active="..tostring(GameEffects.GetModifierActive(id)).." ownerRequirement="..tostring(state));
    end
   end
  end
  Log("native effect audit player="..player:GetID().." instances="..found);
 end);
 -- The observation itself is optional and must never block snapshot receipts.
 player:SetProperty("LOTM_MS_EFFECT_AUDIT419",1);
 if not ok then Log("native effect audit unavailable: "..tostring(err));end
end
local function OnGovernorSnapshot(playerID,parameters)
 if not Enabled() or parameters==nil then return; end
 local player=Player(playerID); if player==nil then return; end
 for _,governor in ipairs({MAG,STAR}) do
  local statePrefix=governor.."_";
  if parameters[statePrefix.."CityID"]~=nil then
   local cityID=tonumber(parameters[statePrefix.."CityID"]) or -1;
   local city=cityID>=0 and player:GetCities():FindID(cityID) or nil;
   if cityID==-1 or city~=nil then
    local prefix="LOTM_MS_"..governor.."_";
    player:SetProperty(prefix.."CITY_ID",cityID);
    player:SetProperty(prefix.."ESTABLISHED",parameters[statePrefix.."Established"]==1 and 1 or 0);
    player:SetProperty(prefix.."NEUTRALIZED",parameters[statePrefix.."Neutralized"]==1 and 1 or 0);
    -- Native HasPromotion is ownership; purchase prerequisites are not rechecked.
    local promotions=governor==STAR and Rescue() and RESCUE_STAR_PROMOTIONS or PROMOTIONS[governor];
    for _,promotion in ipairs(promotions) do
     player:SetProperty(prefix.."HAS_"..promotion,parameters[promotion]==1 and 1 or 0);
    end
    if governor==STAR and Rescue() then
     for _,promotion in ipairs({"CONTACT","INTERROGATION","GUARDIAN"}) do
      player:SetProperty(prefix.."HAS_GOVERNOR_PROMOTION_LOTM_STAR_"..promotion,0);
     end
    end
   end
  end
 end
 MigrateHistory(player);
 RefreshRecordCity(player);
 RefreshSight(player);
 RefreshPlayerEffects(player);
 AuditPlayerEffects(player);
 if Rescue() and LOTM_RESCUE_StarGovernor~=nil then LOTM_RESCUE_StarGovernor.Refresh(playerID); end
 if parameters.SnapshotDigest~=nil then
  player:SetProperty("LOTM_MS_SNAPSHOT_DIGEST",parameters.SnapshotDigest);
  player:SetProperty("LOTM_MS_SNAPSHOT_SERIAL",parameters.SnapshotSerial);
  Log("snapshot acknowledged player="..playerID.." serial="..tostring(parameters.SnapshotSerial));
 end
end
local function OnInterrogation(playerID,parameters)
 if not Enabled() or Rescue() or parameters==nil or parameters.Captured~=1 then return; end
 local player=Player(playerID); if player==nil then return; end
 local city=ActiveCity(player,STAR,"GOVERNOR_PROMOTION_LOTM_STAR_INTERROGATION");
 local attacker=tonumber(parameters.AttackerID);
 local mission=tonumber(parameters.MissionID);
 local completion=tonumber(parameters.CompletionTurn);
 local now=Game.GetCurrentGameTurn();
 if city==nil or city:GetID()~=tonumber(parameters.CityID)
  or attacker==nil or attacker==playerID or Player(attacker)==nil
  or mission==nil or mission<0 or mission~=math.floor(mission)
  or completion==nil or completion>now or now-completion>1 then return; end
 local plot=Map.GetPlotByIndex(tonumber(parameters.PlotIndex) or -1);
 local targetCity=plot~=nil and Cities.GetPlotPurchaseCity(plot) or nil;
 if targetCity==nil or targetCity:GetOwner()~=playerID or targetCity:GetID()~=city:GetID() then return; end
 local key="LOTM_MS_INTERROGATION_CASE_"..attacker.."_"..mission;
 if N(player,key,0)==1 then return; end
 local choiceKey=key.."_CHOICE";
 local choice=N(player,choiceKey,-1);
 if choice<0 then
  choice=LOTM_MP_TurnSync.Random(2,"MS interrogation:"..playerID..":"..attacker..":"..mission);
  player:SetProperty(choiceKey,choice);
 end
 local ok,err=pcall(function()
  if choice==0 then player:GetTechs():ChangeCurrentResearchProgress(300);
  else player:GetCulture():ChangeCurrentCulturalProgress(300); end
 end);
 if not ok then Log("interrogation reward failed "..tostring(err));return;end
 player:SetProperty(key,1);
 Log("interrogation player="..playerID.." case="..attacker..":"..mission
  .." yield="..(choice==0 and "SCIENCE" or "CULTURE").." amount=300");
end

local function OnTurn(playerID,isFirstTimeThisTurn)
 if not Enabled() or isFirstTimeThisTurn==false then return; end
 local player=Player(playerID); if player==nil then return; end
 MigrateHistory(player);
 RefreshRecordCity(player);
 RefreshSight(player);
 RefreshPlayerEffects(player);
end

if Enabled() then
 GameEvents.BuildingConstructed.Add(OnBuildingConstructed);
 GameEvents.OnDistrictConstructed.Add(OnDistrictConstructed);
 GameEvents.LOTM_MS_UpdateGovernor.Add(OnGovernorSnapshot);
 GameEvents.LOTM_MS_Interrogation.Add(OnInterrogation);
 if Rescue() then LOTM_MP_TurnSync.AddSynchronized(OnTurn,"MagicianStarGovernors");
 else LOTM_MP_TurnSync.Add(OnTurn,"MagicianStarGovernors"); end
 Log("initialized governors; rescue="..tostring(Rescue()).." record="..RECORD_VERSION.." sight="..SIGHT_VERSION);
end
