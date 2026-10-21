-- Authoritative tribal-village gathering settlement.  Firaxis chooses the
-- exclusive subtype before GameEvents.UnitTriggerGoodyHut is raised.
local GATHERING_SUBTYPE :string="GOODYHUT_LOTM_WORLD_GATHERING_REWARD";
local ARTIFACT_CHANCE :number=70;
local ARTIFACT_PRICE :table={[2]=140,[1]=360,[0]=900};
local AI_NORMAL_REWARD :string="GOODY_GOLD_SMALL_MODIFIER";
local ERA_WEIGHTS :table={
 [0]={100,0,0},[1]={90,10,0},[2]={75,25,0},[3]={55,45,0},
 [4]={40,45,15},[5]={30,45,25},[6]={20,45,35},[7]={15,40,45},[8]={10,35,55}
};
local POTIONS :table={
 PATH_RED_PRIEST={[9]="PROJECT_LOTM_RP_PROVOKER_POTION",[8]="PROJECT_LOTM_RP_PYROMANIAC_POTION",[7]="PROJECT_LOTM_RP_CONSPIRATOR_POTION",[6]="PROJECT_LOTM_RP_REAPER_POTION",[5]="PROJECT_LOTM_RP_IRONBLOOD_KNIGHT_POTION",[4]="PROJECT_LOTM_RP_WAR_BISHOP_POTION",[3]="PROJECT_LOTM_RP_WEATHER_WARLOCK_POTION",[2]="PROJECT_LOTM_RP_CONQUEROR_POTION"},
 PATH_PERFECT={[9]="PROJECT_LOTM_PP_ARCHAEOLOGIST_POTION",[8]="PROJECT_LOTM_PP_APPRAISER_POTION",[7]="PROJECT_LOTM_PP_MECHANICAL_EXPERT_POTION",[6]="PROJECT_LOTM_PP_ASTRONOMER_POTION",[5]="PROJECT_LOTM_PP_ALCHEMIST_POTION",[4]="PROJECT_LOTM_PP_MYSTERY_SCHOLAR_POTION",[3]="PROJECT_LOTM_PP_KNOWLEDGE_MENTOR_POTION",[2]="PROJECT_LOTM_PP_ENLIGHTENER_POTION"},
 PATH_BLACK_EMPEROR={[9]="PROJECT_LOTM_BE_BARBARIAN_POTION",[8]="PROJECT_LOTM_BE_BRIBER_POTION",[7]="PROJECT_LOTM_BE_BARON_OF_CORRUPTION_POTION",[6]="PROJECT_LOTM_BE_CHAOS_MENTOR_POTION",[5]="PROJECT_LOTM_BE_COUNT_OF_CORRUPTION_POTION",[4]="PROJECT_LOTM_BE_FRENZY_MAGE_POTION",[3]="PROJECT_LOTM_BE_DUKE_OF_ENTROPY_POTION",[2]="PROJECT_LOTM_BE_PRINCE_OF_ABOLITION_POTION"}
};
-- Rescue Thief projects share the project UI but must never enter the
-- ordinary-mode gathering path.  They are selected only when the rescue
-- runtime gate is active.
local RESCUE_THIEF_POTIONS :table={
 [9]="PROJECT_LOTM_TP_SWINDLER_POTION",[8]="PROJECT_LOTM_TP_CRYPTOLOGIST_POTION",
 [7]="PROJECT_LOTM_TP_PROMETHEUS_POTION",[6]="PROJECT_LOTM_TP_DREAM_STEALER_POTION",
 [5]="PROJECT_LOTM_TP_PARASITE_POTION",[4]="PROJECT_LOTM_TP_MENTOR_OF_DECEIT_POTION",
 [3]="PROJECT_LOTM_TP_FATE_TROJAN_POTION",[2]="PROJECT_LOTM_TP_WORM_OF_TIME_POTION"
};
local ACTIVE_POTIONS_PROPERTY :string="LOTM_WORLD_ACTIVE_POTION_PROJECTS";
local PRODUCTION_SYNC_SIGNATURE :string="LOTM_WORLD_PRODUCTION_SYNC_SIGNATURE";
local TRANSFORMATION_ACTIVE_PROPERTY :string="LOTM_BE_TRANSFORMATION_ACTIVE_SYNC";
local POTION_PROJECTS :table={};
for _,path in ipairs({"PATH_RED_PRIEST","PATH_PERFECT","PATH_BLACK_EMPEROR"}) do
 for sequence=2,9 do
  local projectType=POTIONS[path][sequence];
  if projectType~=nil then POTION_PROJECTS[projectType]=true; end
 end
end

local function Log(value) print("[LOTM_WORLD][Goody] "..tostring(value)); end
local function NumberProperty(object,key,default)
 local value=object~=nil and object:GetProperty(key) or nil;
 if value==nil then return default; end return tonumber(value) or default;
end
local function Human(playerID)
 local player=Players[playerID];
 return player~=nil and player:IsAlive() and player:IsMajor() and player:IsHuman() and player or nil;
end
local function IsRescueMode()
 local state=tonumber(Game.GetProperty("LOTM_RESCUE_MODE") or 0) or 0;
 if state==1 then return true; end
 return LOTM_MP_TurnSync~=nil and LOTM_MP_TurnSync.IsRescueModeConfigured~=nil
  and LOTM_MP_TurnSync.IsRescueModeConfigured() or false;
end
local function Random(maxExclusive,label)
 if maxExclusive==nil or maxExclusive<=0 then return 0; end
 local fullLabel="LOTM_WORLD_GOODY:"..tostring(label);
 return LOTM_MP_TurnSync.Random(maxExclusive,fullLabel,fullLabel);
end
local function CostMultiplier()
 local speed=GameInfo.GameSpeeds[GameConfiguration.GetGameSpeedType()];
 return speed~=nil and (tonumber(speed.CostMultiplier) or 100)/100 or 1;
end
local function RoundNearest10(value) return math.floor((value+5)/10)*10; end
local function RoundUp10(value) return math.ceil(value/10)*10; end
local function Publish(player,item)
 player:SetProperty("LOTM_WORLD_POPUP_KIND","GOODY");
 player:SetProperty("LOTM_WORLD_POPUP_ITEM",item);
 player:SetProperty("LOTM_WORLD_POPUP_SERIAL",NumberProperty(player,"LOTM_WORLD_POPUP_SERIAL",0)+1);
end

local function WeightedLevel(eventKey)
 local era=math.min(8,Game.GetEras():GetCurrentEra() or 0);
 local weights=ERA_WEIGHTS[era] or ERA_WEIGHTS[8]; local legal={}; local total=0;
 for level=2,0,-1 do
  if #LOTM_PP_GetAvailableArtifacts(level,nil)>0 then
   local weight=weights[3-level] or 0; total=total+weight;
   table.insert(legal,{level=level,weight=weight});
  end
 end
 if total<=0 then return nil; end
 local roll=Random(total,"artifact level:"..tostring(eventKey));
 for _,entry in ipairs(legal) do
  if roll<entry.weight then return entry.level; end roll=roll-entry.weight;
 end
 return legal[#legal].level;
end
local function ChooseArtifact(eventKey)
 local level=WeightedLevel(eventKey); if level==nil then return nil; end
 local paths={"RP","PP","BE"}; local available={};
 for _,path in ipairs(paths) do
  if #LOTM_PP_GetAvailableArtifacts(level,path)>0 then table.insert(available,path); end
 end
 if #available==0 then return nil; end
 local path=available[Random(#available,"artifact path:"..tostring(eventKey)..":level="..tostring(level))+1];
 local pool=LOTM_PP_GetAvailableArtifacts(level,path);
 return pool[Random(#pool,"artifact item:"..tostring(eventKey)..":level="..tostring(level)..":path="..tostring(path))+1];
end
local function IsProjectInProduction(player,projectType)
 local project=projectType~=nil and GameInfo.Projects[projectType] or nil;
 if player==nil or project==nil then return false; end
 local active=tostring(player:GetProperty(ACTIVE_POTIONS_PROPERTY) or "");
 return string.find("|"..active.."|","|"..projectType.."|",1,true)~=nil;
end
local function PotionFor(player)
 local sequence=NumberProperty(player,"LOTM_RP_SEQUENCE",9);
 local path=player:GetProperty("LOTM_RP_PATH");
 local potionMap=(path=="PATH_THIEF" and IsRescueMode()) and RESCUE_THIEF_POTIONS or POTIONS[path];
 local projectType=potionMap and potionMap[sequence] or nil;
 local project=projectType~=nil and GameInfo.Projects[projectType] or nil;
 if project==nil or sequence<=1
  or player:GetProperty("LOTM_WORLD_PURCHASED_POTION_SEQUENCE")~=nil
  or IsProjectInProduction(player,projectType) then return nil; end
 return {ProjectType=projectType,Sequence=sequence,
  Price=RoundUp10((tonumber(project.Cost) or 0)*0.8*CostMultiplier())};
end
local function SetOffer(player,plot,kind,item,level,path,price)
 local serial=NumberProperty(player,"LOTM_WORLD_GOODY_OFFER_SERIAL",0)+1;
 player:SetProperty("LOTM_WORLD_GOODY_OFFER_SERIAL",serial);
 player:SetProperty("LOTM_WORLD_GOODY_OFFER_SETTLED",0);
 player:SetProperty("LOTM_WORLD_GOODY_OFFER_PLOT",plot:GetIndex());
 player:SetProperty("LOTM_WORLD_GOODY_OFFER_TYPE",kind);
 player:SetProperty("LOTM_WORLD_GOODY_OFFER_ID",item);
 player:SetProperty("LOTM_WORLD_GOODY_OFFER_LEVEL",level);
 player:SetProperty("LOTM_WORLD_GOODY_OFFER_PATH",path);
 player:SetProperty("LOTM_WORLD_GOODY_OFFER_PRICE",price);
 plot:SetProperty("LOTM_WORLD_GOODY_RESOLVED","EXTRAORDINARY");
 Publish(player,item);
end
local function CreateOffer(player,plot)
 local eventKey="player="..tostring(player:GetID())..":plot="..tostring(plot:GetIndex())
  ..":offer="..tostring(NumberProperty(player,"LOTM_WORLD_GOODY_OFFER_SERIAL",0)+1);
 local artifact=Random(100,"offer type:"..eventKey)<ARTIFACT_CHANCE and ChooseArtifact(eventKey..":primary") or nil;
 if artifact~=nil then
  SetOffer(player,plot,"ARTIFACT",artifact.ArtifactType,artifact.Level,artifact.Path,
   RoundNearest10(ARTIFACT_PRICE[artifact.Level]*CostMultiplier())); return true;
 end
 local potion=PotionFor(player);
 if potion~=nil then
  SetOffer(player,plot,"POTION",potion.ProjectType,potion.Sequence-1,
   player:GetProperty("LOTM_RP_PATH"),potion.Price); return true;
 end
 artifact=ChooseArtifact(eventKey..":fallback");
 if artifact~=nil then
  SetOffer(player,plot,"ARTIFACT",artifact.ArtifactType,artifact.Level,artifact.Path,
   RoundNearest10(ARTIFACT_PRICE[artifact.Level]*CostMultiplier())); return true;
 end
 return false;
end
local function GrantOrdinaryFallback(player)
 player:AttachModifierByID(AI_NORMAL_REWARD);
end
local function OnUnitTriggerGoodyHut(playerID,unitID,goodyHutType)
 local gathering=GameInfo.GoodyHutSubTypes[GATHERING_SUBTYPE];
 if gathering==nil or goodyHutType~=gathering.Index then return; end
 local player=Players[playerID]; local unit=player~=nil and player:GetUnits():FindID(unitID) or nil;
 local plot=unit~=nil and Map.GetPlot(unit:GetX(),unit:GetY()) or nil;
 if player==nil or plot==nil or plot:GetProperty("LOTM_WORLD_GOODY_RESOLVED")~=nil then return; end
 if not player:IsHuman() then
  plot:SetProperty("LOTM_WORLD_GOODY_RESOLVED","NORMAL_AI"); GrantOrdinaryFallback(player); return;
 end
 if not CreateOffer(player,plot) then
  plot:SetProperty("LOTM_WORLD_GOODY_RESOLVED","NORMAL_FALLBACK"); GrantOrdinaryFallback(player);
 end
end
local function OnCommand(playerID,parameters)
 local player=Human(playerID); if player==nil or parameters==nil then return; end
 local serial=tonumber(parameters.Serial) or -1;
 if serial~=NumberProperty(player,"LOTM_WORLD_GOODY_OFFER_SERIAL",-2)
  or player:GetProperty("LOTM_WORLD_GOODY_OFFER_SETTLED")==1 then return; end
 if parameters.Action=="LEAVE" then player:SetProperty("LOTM_WORLD_GOODY_OFFER_SETTLED",1); return; end
 if parameters.Action~="BUY" then return; end
 local kind=player:GetProperty("LOTM_WORLD_GOODY_OFFER_TYPE");
 local item=player:GetProperty("LOTM_WORLD_GOODY_OFFER_ID");
 local price=NumberProperty(player,"LOTM_WORLD_GOODY_OFFER_PRICE",-1);
 local treasury=player:GetTreasury(); local balanceBefore=treasury:GetGoldBalance(); local charged=false;
 if price<0 or balanceBefore<price then
  Log("rejected purchase insufficient gold player="..tostring(playerID).." price="..tostring(price).." balance="..tostring(balanceBefore)); return;
 end
 if kind=="ARTIFACT" then
  if not LOTM_PP_GrantSpecificArtifact(playerID,item) then return; end
 elseif kind=="POTION" then
  local sequence=NumberProperty(player,"LOTM_RP_SEQUENCE",9); local expected=PotionFor(player);
  if expected==nil or expected.ProjectType~=item or expected.Price~=price or sequence<=1 then
   Log("rejected potion purchase player="..tostring(playerID).." serial="..tostring(serial)
    .." reason=stale-or-project-in-production"); return;
  end
  -- Charge first so a successful sequence advance can never be free.  The
  -- exact amount is refunded if the authoritative advancement check fails.
  treasury:ChangeGoldBalance(-price); charged=true;
  if not LOTM_RP_State.RegisterPurchasedPotion(playerID,sequence,item,serial) then
   treasury:ChangeGoldBalance(price);
   Log("rejected potion registration and refunded player="..tostring(playerID).." sequence="..tostring(sequence)
    .." price="..tostring(price).." balance="..tostring(treasury:GetGoldBalance())); return;
  end
  Log("potion purchased and stored player="..tostring(playerID).." sequence="..tostring(sequence)
   .." project="..tostring(item).." digestion="
   ..tostring(NumberProperty(player,"LOTM_RP_DIGEST_A",0)+NumberProperty(player,"LOTM_RP_DIGEST_B",0)));
 else return; end
 if not charged then treasury:ChangeGoldBalance(-price); end
 player:SetProperty("LOTM_WORLD_GOODY_OFFER_SETTLED",1);
 Log("purchase settled player="..tostring(playerID).." kind="..tostring(kind).." item="..tostring(item)
  .." price="..tostring(price).." balance="..tostring(balanceBefore).."->"..tostring(treasury:GetGoldBalance()));
end

-- BuildQueue's current-production query is UI-only.  The local UI reports a
-- canonical, validated snapshot through EXECUTE_SCRIPT; Gameplay owns and
-- persists the resulting properties used by gatherings and Black Emperor.
local function OnProductionSync(playerID,parameters)
 local player=Human(playerID); if player==nil or parameters==nil then return; end
 local raw=tostring(parameters.PotionProjects or "");
 if raw=="NONE" or raw=="0" then raw=""; end
 if #raw>2048 then Log("rejected production sync player="..tostring(playerID).." reason=oversize"); return; end
 local seen={}; local active={};
 for projectType in string.gmatch(raw,"[^|]+") do
  local rescueAllowed=IsRescueMode() and player:GetProperty("LOTM_RP_PATH")=="PATH_THIEF"
   and RESCUE_THIEF_POTIONS[tonumber(player:GetProperty("LOTM_RP_SEQUENCE") or 9)]==projectType;
  if (not POTION_PROJECTS[projectType] and not rescueAllowed) or GameInfo.Projects[projectType]==nil then
   Log("rejected production sync player="..tostring(playerID).." project="..tostring(projectType)); return;
  end
  if not seen[projectType] then seen[projectType]=true; table.insert(active,projectType); end
 end
 table.sort(active);
 local canonical=table.concat(active,"|");
 local transformation=tonumber(parameters.TransformationActive)==1 and 1 or 0;
 player:SetProperty(ACTIVE_POTIONS_PROPERTY,canonical);
 player:SetProperty(TRANSFORMATION_ACTIVE_PROPERTY,transformation);
 player:SetProperty(PRODUCTION_SYNC_SIGNATURE,canonical.."#"..tostring(transformation));
 Log("production sync player="..tostring(playerID).." potions="..canonical
  .." transformation="..tostring(transformation));
end

GameEvents.UnitTriggerGoodyHut.Add(OnUnitTriggerGoodyHut);
GameEvents.LOTM_WORLD_Command_GoodyOffer.Add(OnCommand);
GameEvents.LOTM_WORLD_Command_ProductionSync.Add(OnProductionSync);
-- Lifecycle initializes before this module. Reconcile paid entitlements once
-- more after the gathering command layer is loaded so rc.89 read saves cannot
-- remain stuck until another digestion-producing event occurs.
LOTM_MP_TurnSync.RunStartup(function()
 for _,playerID in ipairs(PlayerManager.GetAliveMajorIDs()) do
  LOTM_RP_State.TryConsumePurchasedPotion(playerID);
 end
end,"WorldGoodyHuts");
Log("initialized exclusive normal=65 gathering=35 artifact=70 potion=30");
