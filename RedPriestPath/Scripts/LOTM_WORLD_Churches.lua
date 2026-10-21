-- rc.83 synchronized virtual churches.  There are deliberately no Minor players.
LOTM_WORLD_Churches = LOTM_WORLD_Churches or {};

local CHURCHES={
 FOOL={Path="Fool",Name="LOC_LOTM_CHURCH_FOOL_NAME"},
 NIGHT={Path="Darkness",Name="LOC_LOTM_CHURCH_NIGHT_NAME"},
 STORM={Path="Tyrant",Name="LOC_LOTM_CHURCH_STORM_NAME"}
};
local ORDER={"FOOL","NIGHT","STORM"};
local QUEST_TIERS={6,10,15};
local TARGET_LEVEL={[6]=2,[10]=1,[15]=0};
local DURATION={[6]=10,[10]=12,[15]=15};
local ARTIFACT_CHANCE={[6]=30,[10]=35,[15]=40};
local STATE={LOCKED="LOCKED",PENDING="PENDING_TARGET",ACTIVE="ACTIVE",SELF="COMPLETED_SELF",ASSIST="COMPLETED_ASSIST"};
local PREFIX="LOTM_CHURCH_";
local COMMAND="LOTM_WORLD_Churches_SendEnvoys";
local REWARD_NOTIFICATIONS={FOOL=NotificationTypes.USER_DEFINED_1,NIGHT=NotificationTypes.USER_DEFINED_2,STORM=NotificationTypes.USER_DEFINED_3};
local NIGHT_ENEMY_ABILITIES={
 "ABILITY_LOTM_CHURCH_NIGHT_ENEMY_COMBAT_5",
 "ABILITY_LOTM_CHURCH_NIGHT_ENEMY_COMBAT_10",
 "ABILITY_LOTM_CHURCH_NIGHT_ENEMY_COMBAT_20",
 "ABILITY_LOTM_CHURCH_NIGHT_ENEMY_MOVE_1",
 "ABILITY_LOTM_CHURCH_NIGHT_ENEMY_MOVE_2"
};
local NIGHT_HOME_ABILITIES={
 "ABILITY_LOTM_CHURCH_NIGHT_HOME_PERM_5",
 "ABILITY_LOTM_CHURCH_NIGHT_HOME_PERM_10",
 "ABILITY_LOTM_CHURCH_NIGHT_HOME_BLESS_7",
 "ABILITY_LOTM_CHURCH_NIGHT_HOME_BLESS_12",
 "ABILITY_LOTM_CHURCH_NIGHT_HOME_BLESS_15",
 "ABILITY_LOTM_CHURCH_NIGHT_HOME_BLESS_20",
 "ABILITY_LOTM_CHURCH_NIGHT_HOME_BLESS_25",
 "ABILITY_LOTM_CHURCH_NIGHT_HOME_BLESS_40"
};
local FOOL_ALL_SIGHT_ABILITIES={
 "ABILITY_LOTM_CHURCH_FOOL_ALL_SIGHT_1",
 "ABILITY_LOTM_CHURCH_FOOL_ALL_SIGHT_2",
 "ABILITY_LOTM_CHURCH_FOOL_ALL_SIGHT_3",
 "ABILITY_LOTM_CHURCH_FOOL_ALL_SIGHT_4",
 "ABILITY_LOTM_CHURCH_FOOL_ALL_SIGHT_5"
};
local FOOL_RECON_SIGHT_ABILITY="ABILITY_LOTM_CHURCH_FOOL_RECON_SIGHT_1";
local RefreshNightHomeCombat=nil;
local RefreshFoolSight=nil;
local RefreshAllNightEnemyPenalties=nil;

local function Log(s) print("[LOTM_WORLD][Churches] "..tostring(s)); end
local function Player(id) local p=Players[id]; return p~=nil and p:IsAlive() and p:IsMajor() and p or nil; end
local function N(o,k,d) return LOTM_WORLD_State.NumberProperty(o,k,d); end
local function K(church,suffix) return PREFIX..church.."_"..suffix; end
local function QK(church,tier,suffix) return K(church,"QUEST_"..tier.."_"..suffix); end
local function ValidChurch(church) return type(church)=="string" and CHURCHES[church]~=nil; end
local function RescueActive() return LOTM_WORLD_State.NumberGameProperty("LOTM_RESCUE_MODE",0)==1; end
local function CurrentPlayerTurn(p) return N(p,"LOTM_WORLD_PLAYER_TURN",0); end
local function SortedUnits(player)
 local result={}; if player==nil then return result; end
 for _,unit in player:GetUnits():Members() do result[#result+1]=unit; end
 table.sort(result,function(a,b) return a:GetID()<b:GetID(); end);
 return result;
end
local function SortedIDs(ids)
 local result={}; for _,id in ipairs(ids or {}) do result[#result+1]=id; end
 table.sort(result); return result;
end
local function Attach(p,id)
 if p==nil then return false; end
 if GameInfo.Modifiers[id]~=nil then p:AttachModifierByID(id); return true; end
 local prefix=id.."__"; local found={}; for row in GameInfo.Modifiers() do if string.sub(row.ModifierId,1,#prefix)==prefix then table.insert(found,row.ModifierId); end end
 table.sort(found); for _,modifierID in ipairs(found) do p:AttachModifierByID(modifierID); end
 if #found==0 then Log("WARNING missing modifier bundle "..tostring(id)); return false; end return true;
end

function LOTM_WORLD_Churches.GetEnvoys(playerID,church)
 local p=Player(playerID); if p==nil or not ValidChurch(church) then return 0; end
 return math.max(0,N(p,K(church,"ENVOYS"),0));
end

local function SetQuestState(p,church,tier,value)
 p:SetProperty(QK(church,tier,"STATE"),value);
end

local function QuestState(p,church,tier)
 return tostring(p:GetProperty(QK(church,tier,"STATE")) or STATE.LOCKED);
end

local function NearestCityDistance(p,plot)
 local best=nil;
 for _,city in p:GetCities():Members() do
  local distance=Map.GetPlotDistance(city:GetX(),city:GetY(),plot:GetX(),plot:GetY());
  if best==nil or distance<best then best=distance; end
 end
 return best or 999999;
end

local function RevealTarget(p,plot)
 local visibility=PlayersVisibility[p:GetID()]; if visibility==nil or plot==nil then return; end
 local plots={plot}; for direction=0,5 do local adjacent=Map.GetAdjacentPlot(plot:GetX(),plot:GetY(),direction); if adjacent~=nil then table.insert(plots,adjacent); end end
 for _,candidate in ipairs(plots) do if not visibility:IsRevealed(candidate:GetX(),candidate:GetY()) then
  -- Touch visibility once to mark the plot explored, then release the live
  -- sight count immediately; the oracle must not grant permanent vision.
  visibility:ChangeVisibilityCount(candidate:GetIndex(),1); visibility:ChangeVisibilityCount(candidate:GetIndex(),-1);
 end end
end

local function CandidateBand(distance)
 if distance<=20 then return 1; elseif distance<=30 then return 2; end return 3;
end

local function FindTarget(p,tier)
 local level=TARGET_LEVEL[tier]; local candidates={};
 local campType=GameInfo.Improvements.IMPROVEMENT_BARBARIAN_CAMP.Index;
 for index=0,Map.GetPlotCount()-1 do
  local plot=Map.GetPlotByIndex(index);
  if plot:GetImprovementType()==campType and N(plot,"LOTM_PP_WORKSHOP_IS_WORKSHOP",0)==1 and N(plot,"LOTM_PP_WORKSHOP_LEVEL",2)==level then
   local distance=NearestCityDistance(p,plot); table.insert(candidates,{Kind="WORKSHOP",Id=index,Plot=plot,Distance=distance,Band=CandidateBand(distance)});
  end
 end
 for serial=1,LOTM_WORLD_State.NumberGameProperty("LOTM_WORLD_MONSTER_NEXT_SERIAL",0) do
  if LOTM_WORLD_State.NumberGameProperty("LOTM_WORLD_MONSTER:"..serial..":LIVE",0)==1 and LOTM_WORLD_State.NumberGameProperty("LOTM_WORLD_MONSTER:"..serial..":TIER",-1)==level then
   local owner=LOTM_WORLD_State.NumberGameProperty("LOTM_WORLD_MONSTER:"..serial..":OWNER",-1);
   local unitID=LOTM_WORLD_State.NumberGameProperty("LOTM_WORLD_MONSTER:"..serial..":UNIT_ID",-1);
   local unit=UnitManager.GetUnit(owner,unitID); local plot=unit~=nil and Map.GetPlot(unit:GetX(),unit:GetY()) or nil;
   if plot~=nil then local distance=NearestCityDistance(p,plot); table.insert(candidates,{Kind="MONSTER",Id=serial,Plot=plot,Distance=distance,Band=CandidateBand(distance)}); end
  end
 end
 table.sort(candidates,function(a,b)
  if a.Band~=b.Band then return a.Band<b.Band; end
  if a.Distance~=b.Distance then return a.Distance<b.Distance; end
  if a.Kind~=b.Kind then return a.Kind<b.Kind; end
  return a.Id<b.Id;
 end);
 return candidates[1];
end

local function ClearActive(p,church)
 p:SetProperty(K(church,"ACTIVE_TIER"),0); p:SetProperty(K(church,"TARGET_KIND"),nil);
 p:SetProperty(K(church,"TARGET_ID"),nil); p:SetProperty(K(church,"TARGET_PLOT"),nil); p:SetProperty(K(church,"TARGET_PROGRESS"),nil);
end

local function ActivateOrPend(p,church,tier)
 local target=FindTarget(p,tier);
 p:SetProperty(K(church,"ACTIVE_TIER"),tier);
 if target==nil then
  -- Matching uncontrolled targets can legitimately be absent for a while.
  -- Keep the oracle pending and retry; ordinary camps may disappear entirely
  -- in late games and must never become an irreversible fallback objective.
  SetQuestState(p,church,tier,STATE.PENDING); p:SetProperty(K(church,"TARGET_KIND"),nil); p:SetProperty(K(church,"TARGET_ID"),nil);
  p:SetProperty(K(church,"TARGET_PLOT"),nil); p:SetProperty(K(church,"TARGET_PROGRESS"),nil); p:SetProperty(K(church,"NEXT_RECHECK"),CurrentPlayerTurn(p)+5);
  Log("pending target player="..p:GetID().." church="..church.." tier="..tier.." recheck="..N(p,K(church,"NEXT_RECHECK"),-1)); return;
 end
 SetQuestState(p,church,tier,STATE.ACTIVE); p:SetProperty(K(church,"TARGET_KIND"),target.Kind); p:SetProperty(K(church,"TARGET_ID"),target.Id);
 p:SetProperty(K(church,"TARGET_PLOT"),target.Plot:GetIndex()); p:SetProperty(K(church,"NEXT_RECHECK"),-1); RevealTarget(p,target.Plot);
 Log("active player="..p:GetID().." church="..church.." tier="..tier.." target="..target.Kind..":"..target.Id);
end

local function AdvanceQuestQueue(p,church)
 if N(p,K(church,"ACTIVE_TIER"),0)>0 then return; end
 local envoys=LOTM_WORLD_Churches.GetEnvoys(p:GetID(),church);
 for _,tier in ipairs(QUEST_TIERS) do
  -- In rescue mode the three separate tier-6 oracles are replaced by one
  -- shared milestone: all churches at six envoys unlock War God's Relic.
  if (not RescueActive() or tier~=6) and envoys>=tier and QuestState(p,church,tier)==STATE.LOCKED then ActivateOrPend(p,church,tier); return; end
 end
end

local function MigrateRescueTier6Quest(p,church)
 if not RescueActive() or N(p,"LOTM_RESCUE_CHURCH_QUEST_VERSION",0)>=1 then return; end
 local state=QuestState(p,church,6); local active=N(p,K(church,"ACTIVE_TIER"),0);
 if active==6 and (state==STATE.PENDING or state==STATE.ACTIVE) then
  ClearActive(p,church); SetQuestState(p,church,6,STATE.LOCKED);
  Log("rescue tier6 replaced player="..p:GetID().." church="..church.." oldState="..state.." replacement=WAR_GOD_RELIC");
 end
end

local function FinishRescueTier6Migration(p)
 if not RescueActive() or N(p,"LOTM_RESCUE_CHURCH_QUEST_VERSION",0)>=1 then return; end
 for _,church in ipairs(ORDER) do MigrateRescueTier6Quest(p,church); end
 p:SetProperty("LOTM_RESCUE_CHURCH_QUEST_VERSION",1);
end

local function PermanentBand(envoys) if envoys>=6 then return 6 elseif envoys>=3 then return 3 elseif envoys>=1 then return 1 end return 0; end
local function RefreshPermanent(p,church)
 local desired=PermanentBand(LOTM_WORLD_Churches.GetEnvoys(p:GetID(),church)); local applied=N(p,K(church,"PERMANENT_APPLIED"),0);
 if desired==applied then return; end
 if applied>0 then Attach(p,"LOTM_CHURCH_"..church.."_PERM_"..applied.."_OFF"); end
 if desired>0 then Attach(p,"LOTM_CHURCH_"..church.."_PERM_"..desired.."_ON"); end
 p:SetProperty(K(church,"PERMANENT_APPLIED"),desired);
 Log("permanent player="..p:GetID().." church="..church.." from="..applied.." to="..desired);
end

function LOTM_WORLD_Churches.ChangeEnvoys(playerID,church,delta,sourceKey)
 local p=Player(playerID); delta=tonumber(delta); if p==nil or not ValidChurch(church) or delta==nil or delta%1~=0 then return false; end
 local dedupe=K(church,"ENVOY_SOURCE_"..tostring(sourceKey or "")); if sourceKey~=nil and N(p,dedupe,0)==1 then return false; end
 local old=LOTM_WORLD_Churches.GetEnvoys(playerID,church); local value=math.max(0,old+delta); if value==old then return false; end
 p:SetProperty(K(church,"ENVOYS"),value); if sourceKey~=nil then p:SetProperty(dedupe,1); end
 RefreshPermanent(p,church); AdvanceQuestQueue(p,church);
 if church=="NIGHT" then
  if RefreshNightHomeCombat~=nil then RefreshNightHomeCombat(p); end
  if RefreshAllNightEnemyPenalties~=nil then RefreshAllNightEnemyPenalties(); end
 end
 if church=="FOOL" and RefreshFoolSight~=nil then RefreshFoolSight(p); end
 if LOTM_BE_RefreshEnvoyBaseline~=nil then LOTM_BE_RefreshEnvoyBaseline(playerID,true); end
 p:SetProperty("LOTM_CHURCH_ENVOY_CHANGE_SERIAL",N(p,"LOTM_CHURCH_ENVOY_CHANGE_SERIAL",0)+1);
 if LOTM_RESCUE_Phase10A~=nil and LOTM_RESCUE_Phase10A.OnChurchEnvoysChanged~=nil then LOTM_RESCUE_Phase10A.OnChurchEnvoysChanged(playerID); end
 Log("envoys player="..playerID.." church="..church.." old="..old.." new="..value.." source="..tostring(sourceKey)); return true;
end

local function TriggerRandomBoosts(p,techCount,civicCount,label)
 local techs=p:GetTechs(); local technologies={};
 -- CanTriggerBoost exists only in the UI context on the current game build.
 -- Gameplay can safely select unfinished, unboosted rows and call TriggerBoost.
 for row in GameInfo.Technologies() do if not techs:HasTech(row.Index) and not techs:HasBoostBeenTriggered(row.Index) then table.insert(technologies,row.Index); end end
 table.sort(technologies); for index=1,math.min(techCount,#technologies) do local pick=LOTM_WORLD_State.Random(#technologies,label..":TECH:"..index)+1; local value=table.remove(technologies,pick); local ok,err=pcall(function() techs:TriggerBoost(value,1); end); if not ok then Log("WARNING tech boost failed index="..tostring(value).." error="..tostring(err)); end end
 local culture=p:GetCulture(); local civics={};
 for row in GameInfo.Civics() do if not culture:HasCivic(row.Index) and not culture:HasBoostBeenTriggered(row.Index) then table.insert(civics,row.Index); end end
 table.sort(civics); for index=1,math.min(civicCount,#civics) do local pick=LOTM_WORLD_State.Random(#civics,label..":CIVIC:"..index)+1; local value=table.remove(civics,pick); local ok,err=pcall(function() culture:TriggerBoost(value,1); end); if not ok then Log("WARNING civic boost failed index="..tostring(value).." error="..tostring(err)); end end
 return true;
end

local function BlessingRank(tier,strength) return tier*10+(strength=="FULL" and 2 or 1); end
local function ApplyBlessing(p,church,tier,strength)
 if church=="STORM" and (not RescueActive() or tier==10 or tier==15) then
  return LOTM_GodBlessings~=nil and LOTM_GodBlessings.GrantStorm(p,tier,strength) or false;
 end
 local oldTier=N(p,K(church,"BLESSING_TIER"),0); local oldStrength=tostring(p:GetProperty(K(church,"BLESSING_STRENGTH")) or "NONE");
 if oldTier>0 and BlessingRank(oldTier,oldStrength)>BlessingRank(tier,strength) then return false; end
 if oldTier==tier and oldStrength==strength and CurrentPlayerTurn(p)<N(p,K(church,"BLESSING_UNTIL"),0) then return true; end
 if oldTier>0 then Attach(p,"LOTM_CHURCH_"..church.."_BLESS_"..oldTier.."_"..oldStrength.."_OFF"); end
 Attach(p,"LOTM_CHURCH_"..church.."_BLESS_"..tier.."_"..strength.."_ON");
 p:SetProperty(K(church,"BLESSING_TIER"),tier); p:SetProperty(K(church,"BLESSING_STRENGTH"),strength);
 local durationBase=CurrentPlayerTurn(p); if N(p,"LOTM_WORLD_PLAYER_TURN_SETTLED_GAME_TURN",-1)~=Game.GetCurrentGameTurn() then durationBase=durationBase+1; end
 p:SetProperty(K(church,"BLESSING_UNTIL"),durationBase+DURATION[tier]);
 if church=="NIGHT" then
  if RefreshNightHomeCombat~=nil then RefreshNightHomeCombat(p); end
  if RefreshAllNightEnemyPenalties~=nil then RefreshAllNightEnemyPenalties(); end
 end
 if church=="FOOL" and RefreshFoolSight~=nil then RefreshFoolSight(p); end
 Log("blessing player="..p:GetID().." church="..church.." tier="..tier.." strength="..strength); return true;
end

function LOTM_WORLD_Churches.RemoveLegacyStormBlessing(p,tier,strength)
 if not RescueActive() or (tier~=10 and tier~=15) or (strength~="FULL" and strength~="HALF") then return false; end
 return Attach(p,"LOTM_CHURCH_STORM_BLESS_"..tier.."_"..strength.."_OFF");
end

local function ArtifactName(artifactType)
 local row=artifactType~=nil and GameInfo.GreatWorks[artifactType] or nil;
 return row~=nil and Locale.Lookup(row.Name) or tostring(artifactType or "");
end

local function RecordReward(p,church,tier,kind,artifact,strength)
 p:SetProperty(QK(church,tier,"REWARD_KIND"),kind); p:SetProperty(QK(church,tier,"REWARD_ARTIFACT"),artifact); p:SetProperty(QK(church,tier,"REWARD_STRENGTH"),strength);
 if N(p,QK(church,tier,"REWARD_SERIAL"),0)<=0 then
  local serial=N(p,"LOTM_CHURCH_REWARD_SERIAL",0)+1; p:SetProperty("LOTM_CHURCH_REWARD_SERIAL",serial); p:SetProperty(QK(church,tier,"REWARD_SERIAL"),serial);
  p:SetProperty("LOTM_CHURCH_REWARD_CHURCH",church); p:SetProperty("LOTM_CHURCH_REWARD_TIER",tier); p:SetProperty("LOTM_CHURCH_REWARD_KIND",kind); p:SetProperty("LOTM_CHURCH_REWARD_ARTIFACT",artifact); p:SetProperty("LOTM_CHURCH_REWARD_STRENGTH",strength);
 end
end

local function MigrateNormalGodBlessings(p)
 if RescueActive() or LOTM_GodBlessings==nil or not LOTM_GodBlessings.IsEnabled() or N(p,"LOTM_GOD_BLESSINGS_VERSION",0)>=1 then return; end
 LOTM_GodBlessings.BaselineCapitalFX(p);
 local tier=N(p,K("STORM","BLESSING_TIER"),0);
 local strength=tostring(p:GetProperty(K("STORM","BLESSING_STRENGTH")) or "NONE");
 if tier>0 then
  -- Each serialized old ON bundle is cancelled exactly once. Expired rewards
  -- are not awarded again; a still-active storm blessing becomes one charge.
  Attach(p,"LOTM_CHURCH_STORM_BLESS_"..tier.."_"..strength.."_OFF");
  if CurrentPlayerTurn(p)<N(p,K("STORM","BLESSING_UNTIL"),0) then
   if p:GetProperty(QK("STORM",tier,"REWARD_KIND"))==nil then
    RecordReward(p,"STORM",tier,strength=="HALF" and "HALF_BLESSING" or "FULL_BLESSING",nil,strength);
    p:SetProperty(QK("STORM",tier,"REWARD_APPLIED"),1);
   end
   LOTM_GodBlessings.GrantStorm(p,tier,strength);
  end
  p:SetProperty(K("STORM","BLESSING_TIER"),0);
  p:SetProperty(K("STORM","BLESSING_STRENGTH"),nil);
  p:SetProperty(K("STORM","BLESSING_UNTIL"),-1);
 end
 p:SetProperty("LOTM_GOD_BLESSINGS_VERSION",1);
 Log("normal god blessings migrated player="..p:GetID().." oldStormTier="..tier);
end

local function RunBlessingExtras(p,church,tier,strength)
 if church~="FOOL" or N(p,QK(church,tier,"BOOSTS_DONE"),0)==1 then return; end
 local counts={FULL={[6]={2,2},[10]={3,3},[15]={5,5}},HALF={[6]={1,1},[10]={1,1},[15]={2,2}}}; local c=counts[strength] and counts[strength][tier] or nil;
 if c~=nil then TriggerRandomBoosts(p,c[1],c[2],"church quest blessing:"..p:GetID()..":"..church..":"..tier..":"..strength); end
 p:SetProperty(QK(church,tier,"BOOSTS_DONE"),1);
end

local function NotifyReward(p,church,tier)
 if N(p,QK(church,tier,"NOTIFICATION_DELIVERED"),0)==1 then return; end
 local kind=tostring(p:GetProperty(QK(church,tier,"REWARD_KIND")) or ""); if kind=="" then return; end
 if LOTM_MP_TurnSync.IsNetworkGame() then
  -- Localized notification construction is not authoritative Gameplay.  The
  -- reward was already committed above, so persist its deterministic delivery
  -- ledger before any Locale/NotificationManager call can fail on one peer.
  p:SetProperty(QK(church,tier,"NOTIFICATION_DELIVERED"),1);
  p:SetProperty("LOTM_CHURCH_NOTIFICATION_DELIVERED_SERIAL",N(p,QK(church,tier,"REWARD_SERIAL"),0));
  local ok,err=pcall(function()
   local churchName=Locale.Lookup(CHURCHES[church].Name); local detail="";
   if kind=="ARTIFACT" then detail=Locale.Lookup("LOC_LOTM_CHURCH_REWARD_ARTIFACT",ArtifactName(p:GetProperty(QK(church,tier,"REWARD_ARTIFACT"))));
   else local strength=tostring(p:GetProperty(QK(church,tier,"REWARD_STRENGTH")) or (kind=="HALF_BLESSING" and "HALF" or "FULL")); detail=Locale.Lookup(kind=="HALF_BLESSING" and "LOC_LOTM_CHURCH_REWARD_HALF_BLESSING" or "LOC_LOTM_CHURCH_REWARD_FULL_BLESSING",Locale.Lookup("LOC_LOTM_CHURCH_BLESS_"..church.."_"..tier.."_"..strength)); end
   local data={}; data[ParameterTypes.MESSAGE]=Locale.Lookup("LOC_LOTM_CHURCH_REWARD_NOTIFICATION_MESSAGE",churchName,tier); data[ParameterTypes.SUMMARY]=detail; data.AlwaysUnique=true; data.ShowIcon=true;
   NotificationManager.SendNotification(p:GetID(),REWARD_NOTIFICATIONS[church],data);
  end);
  if not ok then Log("WARNING network reward notification skipped after ledger commit error="..tostring(err)); end
  return;
 end
 local churchName=Locale.Lookup(CHURCHES[church].Name); local detail="";
 if kind=="ARTIFACT" then detail=Locale.Lookup("LOC_LOTM_CHURCH_REWARD_ARTIFACT",ArtifactName(p:GetProperty(QK(church,tier,"REWARD_ARTIFACT"))));
 else local strength=tostring(p:GetProperty(QK(church,tier,"REWARD_STRENGTH")) or (kind=="HALF_BLESSING" and "HALF" or "FULL")); detail=Locale.Lookup(kind=="HALF_BLESSING" and "LOC_LOTM_CHURCH_REWARD_HALF_BLESSING" or "LOC_LOTM_CHURCH_REWARD_FULL_BLESSING",Locale.Lookup("LOC_LOTM_CHURCH_BLESS_"..church.."_"..tier.."_"..strength)); end
 local data={}; data[ParameterTypes.MESSAGE]=Locale.Lookup("LOC_LOTM_CHURCH_REWARD_NOTIFICATION_MESSAGE",churchName,tier); data[ParameterTypes.SUMMARY]=detail; data.AlwaysUnique=true; data.ShowIcon=true;
 local ok,err=pcall(function() NotificationManager.SendNotification(p:GetID(),REWARD_NOTIFICATIONS[church],data); end);
 if ok then p:SetProperty(QK(church,tier,"NOTIFICATION_DELIVERED"),1); p:SetProperty("LOTM_CHURCH_NOTIFICATION_DELIVERED_SERIAL",N(p,QK(church,tier,"REWARD_SERIAL"),0)); else Log("WARNING reward notification failed error="..tostring(err)); end
end

local function EnsureArtifactReward(p,church,tier)
 local selected=p:GetProperty(QK(church,tier,"REWARD_ARTIFACT"));
 if selected==nil and LOTM_PP_GetAvailableArtifacts~=nil then local pool=LOTM_PP_GetAvailableArtifacts(TARGET_LEVEL[tier],nil); if #pool>0 then local row=pool[LOTM_WORLD_State.Random(#pool,"church artifact:"..p:GetID()..":"..church..":"..tier)+1]; selected=row and row.ArtifactType or nil; p:SetProperty(QK(church,tier,"REWARD_ARTIFACT"),selected); end end
 if selected==nil or LOTM_PP_GrantSpecificArtifact==nil then return false,nil; end
 if p:GetProperty("LOTM_PP_ARTIFACT_INSTANCE_"..selected)~=nil then return true,selected; end
 local ok,result=pcall(function() return LOTM_PP_GrantSpecificArtifact(p:GetID(),selected); end); return ok and result==true,selected;
end

local function RewardSelf(p,church,tier,targetKey)
 LOTM_WORLD_Churches.ChangeEnvoys(p:GetID(),church,1,"QUEST:"..tier..":"..targetKey);
 local kind=p:GetProperty(QK(church,tier,"REWARD_KIND"));
 -- Repair rc.83 saves that crashed inside the Fool boost call after the blessing
 -- and envoy were already persisted but before REWARD_KIND/ClearActive.
 if kind==nil and N(p,K(church,"BLESSING_TIER"),0)==tier and tostring(p:GetProperty(K(church,"BLESSING_STRENGTH")) or "")=="FULL" then kind="FULL_BLESSING"; RecordReward(p,church,tier,kind,nil,"FULL"); p:SetProperty(QK(church,tier,"REWARD_APPLIED"),1); end
 if kind==nil then
  local roll=N(p,QK(church,tier,"REWARD_ROLL"),-1); if roll<0 then roll=LOTM_WORLD_State.Random(100,"church reward:"..p:GetID()..":"..church..":"..tier..":"..targetKey); p:SetProperty(QK(church,tier,"REWARD_ROLL"),roll); end
  local artifact,artifactType=false,nil; if roll<ARTIFACT_CHANCE[tier] then artifact,artifactType=EnsureArtifactReward(p,church,tier); end
  kind=artifact and "ARTIFACT" or "FULL_BLESSING"; RecordReward(p,church,tier,kind,artifactType,artifact and nil or "FULL");
 end
 if N(p,QK(church,tier,"REWARD_APPLIED"),0)~=1 then
  if kind=="ARTIFACT" then local granted=EnsureArtifactReward(p,church,tier); if granted then p:SetProperty(QK(church,tier,"REWARD_APPLIED"),1); end
  else local applied=ApplyBlessing(p,church,tier,"FULL"); if applied or church~="STORM" or (RescueActive() and tier==6) then p:SetProperty(QK(church,tier,"REWARD_APPLIED"),1); end end
 end
 if kind~="ARTIFACT" then RunBlessingExtras(p,church,tier,"FULL"); end
 if kind~="ARTIFACT" and N(p,QK(church,tier,"REWARD_APPLIED"),0)==1 and not RescueActive() and LOTM_GodBlessings~=nil then LOTM_GodBlessings.RecordCapitalFX(p,church,tier); end
 NotifyReward(p,church,tier);
end

local function RewardAssist(p,church,tier)
 local kind=p:GetProperty(QK(church,tier,"REWARD_KIND")); if kind==nil then RecordReward(p,church,tier,"HALF_BLESSING",nil,"HALF"); end
 if N(p,QK(church,tier,"REWARD_APPLIED"),0)~=1 then local applied=ApplyBlessing(p,church,tier,"HALF"); if applied or church~="STORM" or (RescueActive() and tier==6) then p:SetProperty(QK(church,tier,"REWARD_APPLIED"),1); end end
 if N(p,QK(church,tier,"REWARD_APPLIED"),0)==1 and not RescueActive() and LOTM_GodBlessings~=nil then LOTM_GodBlessings.RecordCapitalFX(p,church,tier); end
 RunBlessingExtras(p,church,tier,"HALF"); NotifyReward(p,church,tier);
end

local function FinalizeResolved(p,church,tier,state,targetKey)
 p:SetProperty(QK(church,tier,"RESOLUTION_TARGET"),targetKey); ClearActive(p,church);
 local ok,err=pcall(function() if state==STATE.SELF then RewardSelf(p,church,tier,targetKey); else RewardAssist(p,church,tier); end end);
 if not ok then Log("WARNING reward finalization deferred player="..p:GetID().." church="..church.." tier="..tier.." error="..tostring(err)); end
 AdvanceQuestQueue(p,church);
end

local function ResolveTarget(kind,id,resolverPlayerID)
 local selfHandled=false; local targetKey=kind..":"..tostring(id);
 local majorIDs=PlayerManager.GetAliveMajorIDs();
 if LOTM_MP_TurnSync.IsNetworkGame() then
  local ordered={}; for _,majorID in ipairs(majorIDs or {}) do ordered[#ordered+1]=majorID; end
  table.sort(ordered); majorIDs=ordered;
 end
 for _,majorID in ipairs(majorIDs or {}) do local p=Player(majorID); if p~=nil then
  for _,church in ipairs(ORDER) do local tier=N(p,K(church,"ACTIVE_TIER"),0);
   if tier>0 and QuestState(p,church,tier)==STATE.ACTIVE and p:GetProperty(K(church,"TARGET_KIND"))==kind and N(p,K(church,"TARGET_ID"),-1)==id then
    local key=QK(church,tier,"SETTLED_"..targetKey); if N(p,key,0)~=1 then
     p:SetProperty(key,1); if majorID==resolverPlayerID then SetQuestState(p,church,tier,STATE.SELF); FinalizeResolved(p,church,tier,STATE.SELF,targetKey); selfHandled=true;
     else SetQuestState(p,church,tier,STATE.ASSIST); FinalizeResolved(p,church,tier,STATE.ASSIST,targetKey); end
    end
   end
  end
 end end
 return selfHandled;
end

function LOTM_WORLD_Churches.OnWorkshopResolved(plotIndex,resolverPlayerID) return ResolveTarget("WORKSHOP",tonumber(plotIndex) or -1,tonumber(resolverPlayerID) or -1); end
function LOTM_WORLD_Churches.ResolveMonsterQuest(killerPlayerID,serial) return ResolveTarget("MONSTER",tonumber(serial) or -1,tonumber(killerPlayerID) or -1); end

function LOTM_WORLD_Churches.OnBarbarianCampResolved(plotIndex,resolverPlayerID)
 -- Ordinary camps are no longer oracle targets. Returning false preserves the
 -- normal workshop/camp reward path for new games and migrated saves.
 return false;
end

local function TargetStillValid(kind,id,tier)
 if kind=="WORKSHOP" then local plot=Map.GetPlotByIndex(id); return plot~=nil and N(plot,"LOTM_PP_WORKSHOP_IS_WORKSHOP",0)==1 and N(plot,"LOTM_PP_WORKSHOP_LEVEL",2)==TARGET_LEVEL[tier] and plot:GetImprovementType()==GameInfo.Improvements.IMPROVEMENT_BARBARIAN_CAMP.Index; end
 if kind=="MONSTER" then return LOTM_WORLD_State.NumberGameProperty("LOTM_WORLD_MONSTER:"..id..":LIVE",0)==1 and LOTM_WORLD_State.NumberGameProperty("LOTM_WORLD_MONSTER:"..id..":TIER",-1)==TARGET_LEVEL[tier]; end
 -- Resource-110 saves stuck on the old fallback migrate to pending/recheck.
 if kind=="BARB_CAMP_COUNT" then return false; end
 return false;
end

local function ReconcileQuest(p,church)
 local tier=N(p,K(church,"ACTIVE_TIER"),0); if tier<=0 then AdvanceQuestQueue(p,church); return; end
 local state=QuestState(p,church,tier);
 if state==STATE.SELF or state==STATE.ASSIST then local kind=tostring(p:GetProperty(K(church,"TARGET_KIND")) or "UNKNOWN"); local id=N(p,K(church,"TARGET_ID"),-1); FinalizeResolved(p,church,tier,state,tostring(p:GetProperty(QK(church,tier,"RESOLUTION_TARGET")) or (kind..":"..id)));
 elseif state==STATE.PENDING and CurrentPlayerTurn(p)>=N(p,K(church,"NEXT_RECHECK"),0) then ActivateOrPend(p,church,tier);
 elseif state==STATE.ACTIVE then local kind=tostring(p:GetProperty(K(church,"TARGET_KIND")) or ""); local id=N(p,K(church,"TARGET_ID"),-1);
  if not TargetStillValid(kind,id,tier) then SetQuestState(p,church,tier,STATE.PENDING); p:SetProperty(K(church,"TARGET_KIND"),nil); p:SetProperty(K(church,"TARGET_ID"),nil); p:SetProperty(K(church,"TARGET_PLOT"),nil); p:SetProperty(K(church,"NEXT_RECHECK"),CurrentPlayerTurn(p)+5); end
 end
end

local function ReconcileCompletedRewards(p,church)
 for _,tier in ipairs(QUEST_TIERS) do local state=QuestState(p,church,tier); if state==STATE.SELF then local target=tostring(p:GetProperty(QK(church,tier,"RESOLUTION_TARGET")) or ("RECOVERED:"..tier)); local ok,err=pcall(function() RewardSelf(p,church,tier,target); end); if not ok then Log("WARNING self reward retry failed error="..tostring(err)); end elseif state==STATE.ASSIST then local ok,err=pcall(function() RewardAssist(p,church,tier); end); if not ok then Log("WARNING assist reward retry failed error="..tostring(err)); end end end
end

local function EffectiveHeal(p,church)
 if church=="STORM" and not RescueActive() then return 0; end
 local tier=N(p,K(church,"BLESSING_TIER"),0); local strength=tostring(p:GetProperty(K(church,"BLESSING_STRENGTH")) or "NONE");
 if church=="STORM" and (tier==10 or tier==15) then return 0; end
 if church=="NIGHT" then if tier==6 then return strength=="FULL" and 20 or 10 elseif tier==10 then return strength=="FULL" and 30 or 15 elseif tier==15 then return strength=="FULL" and 50 or 25 end
  return LOTM_WORLD_Churches.GetEnvoys(p:GetID(),church)>=6 and 10 or 0;
 elseif church=="STORM" then if tier==6 then return strength=="FULL" and 20 or 10 elseif tier==10 then return strength=="FULL" and 30 or 15 elseif tier==15 then return strength=="FULL" and 50 or 25 end end
 return 0;
end

local function HealUnits(p,church,amount)
 if amount<=0 then return; end
 for _,unit in ipairs(SortedUnits(p)) do
  local info=GameInfo.Units[unit:GetType()]; local plot=nil;
  if church=="NIGHT" and info~=nil and info.FormationClass~="FORMATION_CLASS_CIVILIAN" then
   plot=Map.GetPlot(unit:GetX(),unit:GetY());
   if plot==nil then Log("heal skipped player="..p:GetID().." church="..church.." unit="..unit:GetID().." reason=PLOT_MISSING xy="..unit:GetX()..":"..unit:GetY()); end
  end
  local eligible=church=="STORM" and info~=nil and info.Domain=="DOMAIN_SEA" or church=="NIGHT" and info~=nil and info.FormationClass~="FORMATION_CLASS_CIVILIAN" and plot~=nil and plot:GetOwner()==p:GetID();
  if eligible and unit:GetDamage()>0 then unit:ChangeDamage(-math.min(amount,unit:GetDamage())); end
 end
end

local function ExpireBlessing(p,church)
 local tier=N(p,K(church,"BLESSING_TIER"),0); if tier<=0 or CurrentPlayerTurn(p)<N(p,K(church,"BLESSING_UNTIL"),0) then return; end
 local strength=tostring(p:GetProperty(K(church,"BLESSING_STRENGTH")) or "NONE"); Attach(p,"LOTM_CHURCH_"..church.."_BLESS_"..tier.."_"..strength.."_OFF");
 p:SetProperty(K(church,"BLESSING_TIER"),0); p:SetProperty(K(church,"BLESSING_STRENGTH"),nil); p:SetProperty(K(church,"BLESSING_UNTIL"),-1); Log("blessing expired player="..p:GetID().." church="..church);
 if church=="NIGHT" then
  if RefreshNightHomeCombat~=nil then RefreshNightHomeCombat(p); end
  if RefreshAllNightEnemyPenalties~=nil then RefreshAllNightEnemyPenalties(); end
 end
 if church=="FOOL" and RefreshFoolSight~=nil then RefreshFoolSight(p); end
end

local function SetAbility(unit,abilityType,desired)
 local abilities=unit~=nil and unit:GetAbility() or nil; if abilities==nil then return; end
 local current=abilities:GetAbilityCount(abilityType) or 0;
 if current~=desired then abilities:ChangeAbilityCount(abilityType,desired-current); end
end

local function FoolSightAmounts(p)
 local envoys=LOTM_WORLD_Churches.GetEnvoys(p:GetID(),"FOOL");
 local allSight=0; local reconExtra=0;
 if envoys>=1 then allSight=1; reconExtra=1; end
 if envoys>=6 then allSight=allSight+1; end
 local tier=N(p,K("FOOL","BLESSING_TIER"),0);
 if tier>0 and CurrentPlayerTurn(p)<N(p,K("FOOL","BLESSING_UNTIL"),0) then
  local strength=tostring(p:GetProperty(K("FOOL","BLESSING_STRENGTH")) or "NONE");
  if tier==6 then allSight=allSight+(strength=="FULL" and 2 or 1);
  elseif tier==15 then allSight=allSight+(strength=="FULL" and 3 or 1); end
 end
 return math.max(0,math.min(5,allSight)),reconExtra;
end

local function RefreshFoolSightForUnit(p,unit,allSight,reconExtra)
 if p==nil or unit==nil then return; end
 for amount,abilityType in ipairs(FOOL_ALL_SIGHT_ABILITIES) do
  SetAbility(unit,abilityType,amount==allSight and 1 or 0);
 end
 SetAbility(unit,FOOL_RECON_SIGHT_ABILITY,reconExtra>0 and 1 or 0);
end

RefreshFoolSight=function(p)
 if p==nil then return; end
 local allSight,reconExtra=FoolSightAmounts(p);
 for _,unit in ipairs(SortedUnits(p)) do RefreshFoolSightForUnit(p,unit,allSight,reconExtra); end
 local signature=tostring(allSight)..":"..tostring(reconExtra);
 if tostring(p:GetProperty(K("FOOL","SIGHT_ABILITY_STATE")) or "")~=signature then
  p:SetProperty(K("FOOL","SIGHT_ABILITY_STATE"),signature);
  Log("fool sight player="..p:GetID().." all="..allSight.." reconExtra="..reconExtra);
 end
end

local function NightHomeAbilities(p)
 local permanent=nil; local envoys=LOTM_WORLD_Churches.GetEnvoys(p:GetID(),"NIGHT");
 if envoys>=6 then permanent="ABILITY_LOTM_CHURCH_NIGHT_HOME_PERM_10";
 elseif envoys>=3 then permanent="ABILITY_LOTM_CHURCH_NIGHT_HOME_PERM_5"; end
 local blessing=nil; local tier=N(p,K("NIGHT","BLESSING_TIER"),0);
 if tier>0 and CurrentPlayerTurn(p)<N(p,K("NIGHT","BLESSING_UNTIL"),0) then
  local strength=tostring(p:GetProperty(K("NIGHT","BLESSING_STRENGTH")) or "NONE");
  local amount=nil;
  if tier==6 then amount=strength=="FULL" and 15 or 7;
  elseif tier==10 then amount=strength=="FULL" and 25 or 12;
  elseif tier==15 then amount=strength=="FULL" and 40 or 20; end
  if amount~=nil then blessing="ABILITY_LOTM_CHURCH_NIGHT_HOME_BLESS_"..tostring(amount); end
 end
 return permanent,blessing;
end

local function RefreshNightHomeCombatForUnit(p,unit)
 if p==nil or unit==nil then return; end
 local permanent,blessing=NightHomeAbilities(p);
 for _,abilityType in ipairs(NIGHT_HOME_ABILITIES) do
  SetAbility(unit,abilityType,(abilityType==permanent or abilityType==blessing) and 1 or 0);
 end
end

RefreshNightHomeCombat=function(p)
 if p==nil then return; end
 for _,unit in ipairs(SortedUnits(p)) do RefreshNightHomeCombatForUnit(p,unit); end
end

local function NightEnemyPenaltyForTerritory(owner)
 if owner==nil or not owner:IsAlive() or not owner:IsMajor() then return nil,nil; end
 local tier=N(owner,K("NIGHT","BLESSING_TIER"),0);
 if tier~=10 and tier~=15 then return nil,nil; end
 if CurrentPlayerTurn(owner)>=N(owner,K("NIGHT","BLESSING_UNTIL"),0) then return nil,nil; end
 local strength=tostring(owner:GetProperty(K("NIGHT","BLESSING_STRENGTH")) or "NONE");
 if tier==10 then return strength=="FULL" and 10 or 5,strength=="FULL" and 1 or 0; end
 return strength=="FULL" and 20 or 10,strength=="FULL" and 2 or 1;
end

local function RefreshNightEnemyPenalty(unitOwnerID,unit)
 local combat,movement=nil,nil; local plot=unit~=nil and Map.GetPlot(unit:GetX(),unit:GetY()) or nil;
 local territoryID=plot~=nil and plot:GetOwner() or -1;
 if territoryID~=nil and territoryID>=0 and territoryID~=unitOwnerID then
  local territoryOwner=Players[territoryID]; local unitOwner=Players[unitOwnerID];
  local diplomacy=territoryOwner~=nil and territoryOwner:GetDiplomacy() or nil;
  if unitOwner~=nil and diplomacy~=nil and diplomacy:IsAtWarWith(unitOwnerID) then combat,movement=NightEnemyPenaltyForTerritory(territoryOwner); end
 end
 local wanted={
  ABILITY_LOTM_CHURCH_NIGHT_ENEMY_COMBAT_5=combat==5 and 1 or 0,
  ABILITY_LOTM_CHURCH_NIGHT_ENEMY_COMBAT_10=combat==10 and 1 or 0,
  ABILITY_LOTM_CHURCH_NIGHT_ENEMY_COMBAT_20=combat==20 and 1 or 0,
  ABILITY_LOTM_CHURCH_NIGHT_ENEMY_MOVE_1=movement==1 and 1 or 0,
  ABILITY_LOTM_CHURCH_NIGHT_ENEMY_MOVE_2=movement==2 and 1 or 0
 };
 for _,abilityType in ipairs(NIGHT_ENEMY_ABILITIES) do SetAbility(unit,abilityType,wanted[abilityType]); end
end

RefreshAllNightEnemyPenalties=function()
 local groups={PlayerManager.GetAliveMajorIDs(),PlayerManager.GetAliveMinorIDs()};
 for _,ids in ipairs(groups) do for _,ownerID in ipairs(SortedIDs(ids)) do local owner=Players[ownerID]; if owner~=nil then
  for _,unit in ipairs(SortedUnits(owner)) do RefreshNightEnemyPenalty(ownerID,unit); end
 end end end
 local barbarians={}; for _,owner in ipairs(PlayerManager.GetAliveBarbarians()) do barbarians[#barbarians+1]=owner; end
 table.sort(barbarians,function(a,b) return a:GetID()<b:GetID(); end);
 for _,owner in ipairs(barbarians) do for _,unit in ipairs(SortedUnits(owner)) do RefreshNightEnemyPenalty(owner:GetID(),unit); end end
end

local function OnUnitMoved(playerID,unitID)
 local unit=UnitManager.GetUnit(playerID,unitID); if unit~=nil then RefreshNightEnemyPenalty(playerID,unit); end
end

local function FoolEraBoon(p)
 if LOTM_WORLD_Churches.GetEnvoys(p:GetID(),"FOOL")<6 then return; end local era=Game.GetEras():GetCurrentEra() or 0;
 if N(p,K("FOOL","LAST_ERA_BOON"),-1)==era then return; end p:SetProperty(K("FOOL","LAST_ERA_BOON"),era); TriggerRandomBoosts(p,1,1,"fool era:"..p:GetID()..":"..era);
end

local function OnPlayerTurn(playerID,isFirstTime)
 if isFirstTime==false then return; end local p=Player(playerID); if p==nil then return; end
 FinishRescueTier6Migration(p);
 MigrateNormalGodBlessings(p);
 for _,church in ipairs(ORDER) do RefreshPermanent(p,church); ExpireBlessing(p,church); ReconcileQuest(p,church); ReconcileCompletedRewards(p,church); HealUnits(p,church,EffectiveHeal(p,church)); end RefreshNightHomeCombat(p); RefreshFoolSight(p); FoolEraBoon(p); RefreshAllNightEnemyPenalties();
end

local function OnUnitAdded(playerID,unitID)
 if LOTM_MP_TurnSync.IsNetworkGame() then return; end
 local unit=UnitManager.GetUnit(playerID,unitID); if unit~=nil then
  local p=Player(playerID);
  if p~=nil then
   RefreshNightHomeCombatForUnit(p,unit);
   local allSight,reconExtra=FoolSightAmounts(p); RefreshFoolSightForUnit(p,unit,allSight,reconExtra);
  end
  RefreshNightEnemyPenalty(playerID,unit);
 end
end

local function OnDiplomacyChanged()
 if LOTM_MP_TurnSync.IsNetworkGame() then return; end
 RefreshAllNightEnemyPenalties();
end

local function OnSendEnvoys(playerID,parameters)
 local p=Player(playerID); if p==nil or type(parameters)~="table" then return; end local counts={}; local total=0;
 for _,church in ipairs(ORDER) do local value=tonumber(parameters[church] or 0) or 0; if value<0 or value%1~=0 or value>99 then Log("rejected invalid envoy batch player="..playerID); return; end counts[church]=value; total=total+value; end
 local serial=tostring(parameters.Serial or ""); if serial=="" or N(p,"LOTM_CHURCH_COMMAND_"..serial,0)==1 then return; end local influence=p:GetInfluence();
 if influence==nil or total<=0 or (influence:GetTokensToGive() or 0)<total then Log("rejected stale envoy batch player="..playerID.." total="..total); return; end
 influence:ChangeTokensToGive(-total); p:SetProperty("LOTM_CHURCH_COMMAND_"..serial,1);
 for _,church in ipairs(ORDER) do if counts[church]>0 then LOTM_WORLD_Churches.ChangeEnvoys(playerID,church,counts[church],"COMMAND:"..serial); end end
 Log("accepted envoy batch player="..playerID.." total="..total.." serial="..serial);
end

function LOTM_WORLD_Churches.GetUISnapshot(playerID)
 local p=Player(playerID); local snapshot={Version=4,Churches={}}; if p==nil then return snapshot; end
 for _,church in ipairs(ORDER) do local active=N(p,K(church,"ACTIVE_TIER"),0); snapshot.Churches[church]={ChurchType=church,Path=CHURCHES[church].Path,Name=CHURCHES[church].Name,Envoys=LOTM_WORLD_Churches.GetEnvoys(playerID,church),Quest6=QuestState(p,church,6),Quest10=QuestState(p,church,10),Quest15=QuestState(p,church,15),ActiveTier=active,TargetKind=p:GetProperty(K(church,"TARGET_KIND")),TargetId=N(p,K(church,"TARGET_ID"),-1),TargetPlot=N(p,K(church,"TARGET_PLOT"),-1),BlessingTier=N(p,K(church,"BLESSING_TIER"),0),BlessingStrength=p:GetProperty(K(church,"BLESSING_STRENGTH")),BlessingRemaining=math.max(0,N(p,K(church,"BLESSING_UNTIL"),0)-CurrentPlayerTurn(p))}; end return snapshot;
end

GameEvents[COMMAND].Add(OnSendEnvoys);
LOTM_MP_TurnSync.Add(OnPlayerTurn,"WorldChurches");
Events.UnitAddedToMap.Add(LOTM_UnitAddedPerf.Wrap("Churches",OnUnitAdded));
Events.DiplomacyDeclareWar.Add(OnDiplomacyChanged);
Events.DiplomacyMakePeace.Add(OnDiplomacyChanged);
GameEvents.OnUnitMoved.Add(OnUnitMoved);
if LOTM_WORLD_Monsters~=nil and LOTM_WORLD_Monsters.RegisterQuestResolver~=nil then LOTM_WORLD_Monsters.RegisterQuestResolver(LOTM_WORLD_Churches.ResolveMonsterQuest); end
LOTM_MP_TurnSync.RunStartup(function()
 for _,id in ipairs(SortedIDs(PlayerManager.GetAliveMajorIDs())) do local p=Player(id); if p~=nil then FinishRescueTier6Migration(p); MigrateNormalGodBlessings(p); for _,church in ipairs(ORDER) do for _,tier in ipairs(QUEST_TIERS) do if p:GetProperty(QK(church,tier,"STATE"))==nil then SetQuestState(p,church,tier,STATE.LOCKED); end end RefreshPermanent(p,church); ReconcileQuest(p,church); ReconcileCompletedRewards(p,church); end RefreshNightHomeCombat(p); RefreshFoolSight(p); end end
end,"WorldChurches");
Log("initialized virtual=3 thresholds=1/3/6 quests=ordinary:6/10/15 rescue:allThreeAt6WarGodRelicThen10/15 state=4");
