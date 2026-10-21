-- Rescue Leonard C/D. Only synchronized Gameplay events/operations write
-- state. UI publication events merely submit completion/lifecycle observations.
LOTM_RESCUE_StarGovernor=LOTM_RESCUE_StarGovernor or {};
local API=LOTM_RESCUE_StarGovernor;
local VERSION=1;
local PREFIX="LOTM_RESCUE_STAR_";
local CASE="GOVERNOR_PROMOTION_LOTM_STAR_CASE_FILES";
local GLOVES="GOVERNOR_PROMOTION_LOTM_STAR_RED_GLOVES";
local WORLD="GOVERNOR_PROMOTION_LOTM_STAR_HIDDEN_WORLD";
local META=PREFIX.."UNIT_META:";
local sessionRestored={};
local function Log(s) print("[LOTM_RESCUE][Star] "..tostring(s)); end
local function N(o,k,d)
 local raw=o~=nil and o:GetProperty(k) or nil; local v=tonumber(raw);
 return v~=nil and v or d;
end
local function GN(k,d)
 local raw=Game.GetProperty(k); local v=tonumber(raw); return v~=nil and v or d;
end
local function Configured()
 return LOTM_MP_TurnSync.IsRescueModeConfigured()
  and GameInfo.GovernorPromotions~=nil and GameInfo.GovernorPromotions[WORLD]~=nil;
end
local function Enabled() return Configured() and GN("LOTM_RESCUE_MODE",0)==1; end
local function Player(id)
 local p=Players[id]; return p~=nil and p:IsAlive() and p:IsMajor() and p or nil;
end
local function Has(p,promotion) return N(p,"LOTM_MS_STAR_HAS_"..promotion,0)==1; end
local function Effective(p,promotion)
 if not Enabled() or p==nil or not p:IsAlive() or not Has(p,promotion)
  or N(p,"LOTM_MS_STAR_ESTABLISHED",0)~=1 or N(p,"LOTM_MS_STAR_NEUTRALIZED",0)~=0 then return false; end
 local c=p:GetCities():FindID(N(p,"LOTM_MS_STAR_CITY_ID",-1));
 if c==nil or c:GetOwner()~=p:GetID() then return false; end
 -- Native support checks all prerequisites. Retain an independent authority
 -- guard here, including imported/saved ownership with a missing branch.
 return promotion~=WORLD or (Has(p,CASE) and Has(p,GLOVES));
end
local function Unit(owner,id)
 if tonumber(owner)==nil or tonumber(id)==nil or owner<0 or id<0 then return nil; end
 return UnitManager.GetUnit(owner,id);
end
local function Dead(u) return u==nil or u:IsDead() or u:IsDelayedDeath(); end
local function CombatRow(row)
 return row~=nil and row.FormationClass~=nil and row.FormationClass~="FORMATION_CLASS_CIVILIAN"
  and row.Spy~=true and row.Spy~=1 and row.MakeTradeRoute~=true and row.MakeTradeRoute~=1
  and ((tonumber(row.Combat) or 0)>0 or (tonumber(row.RangedCombat) or 0)>0
   or (tonumber(row.Bombard) or 0)>0 or (tonumber(row.AirCombat) or 0)>0);
end
local function Recon(u)
 if Dead(u) then return false; end
 local row=GameInfo.Units[u:GetType()];
 return CombatRow(row) and row.PromotionClass=="PROMOTION_CLASS_RECON"
  and not string.find(row.UnitType,"^UNIT_LOTM_") and not string.find(row.UnitType,"^UNIT_HERO_")
  and row.LeaderType==nil;
end
local function Keys(t)
 t=t or {}; local r={}; local k=next(t);
 while k~=nil do r[#r+1]=k; k=next(t,k); end
 table.sort(r); return r;
end
local function Copy(t)
 t=t or {}; local r={}; for _,k in ipairs(Keys(t)) do r[k]=t[k]; end; return r;
end
local function Identity(u)
 local id=N(u,PREFIX.."IDENTITY",0);
 if id==0 then
  id=GN(PREFIX.."NEXT_IDENTITY",0)+1;
  Game.SetProperty(PREFIX.."NEXT_IDENTITY",id); u:SetProperty(PREFIX.."IDENTITY",id);
 end
 return id;
end
local function Observe(owner,id)
 local u=Unit(owner,id); if u==nil then return nil; end
 local plot=Map.GetPlot(u:GetX(),u:GetY()); local row=GameInfo.Units[u:GetType()];
 if plot==nil or row==nil or u:GetOwner()~=owner then return nil; end
 local fact={Identity=Identity(u),Type=u:GetType(),Plot=plot:GetIndex(),Owner=owner,UnitID=id};
 Game.SetProperty(META..owner..":"..id,fact); return fact;
end
local function PlotList(value)
 local r={}; for token in string.gmatch(tostring(value or ""),"[^,]+") do
  local i=tonumber(token); if i~=nil and Map.GetPlotByIndex(i)~=nil then r[#r+1]=i; end
 end; return r;
end
local function CSV(t)
 local r={}; for _,i in ipairs(t) do r[#r+1]=tostring(i); end; return table.concat(r,",");
end
local function Ring(plot)
 local r={}; local seen={};
 for dx=-1,1 do for dy=-1,1 do
  local p=Map.GetPlotXYWithRangeCheck(plot:GetX(),plot:GetY(),dx,dy,1);
  if p~=nil and not seen[p:GetIndex()] then seen[p:GetIndex()]=true; r[#r+1]=p:GetIndex(); end
 end end; table.sort(r); return r;
end
local function Change(p,plots,delta)
 local visibility=PlayersVisibility[p:GetID()]; if visibility==nil then return false; end
 for _,i in ipairs(plots) do
  if delta>0 or visibility:GetVisibilityCount(i)>0 then visibility:ChangeVisibilityCount(i,delta); end
 end; return true;
end
local function Patrols(p) return Copy(p:GetProperty(PREFIX.."PATROL_REFERENCES")); end
local function DropPatrol(p,key,ledger)
 local e=ledger[key]; if e==nil then return; end
 if Change(p,PlotList(e.Plots),-1) then ledger[key]=nil; end
end
local function ReconcilePatrols(p,clearAll)
 local ledger=Patrols(p);
 for _,key in ipairs(Keys(ledger)) do
  local e=ledger[key]; local u=Unit(p:GetID(),e.UnitID);
  if clearAll or not Recon(u) or u:GetOwner()~=p:GetID() or N(u,PREFIX.."IDENTITY",0)~=e.Identity
   or u:GetType()~=e.Type then
   DropPatrol(p,key,ledger);
  end
 end
 p:SetProperty(PREFIX.."PATROL_REFERENCES",ledger);
end
local function RestoreReferences(p)
 if sessionRestored[p:GetID()] then return; end
 local visibility=PlayersVisibility[p:GetID()]; if visibility==nil then return; end
 local expected={};
 local function Count(list) for _,i in ipairs(list) do expected[i]=(expected[i] or 0)+1; end end
 Count(PlotList(p:GetProperty("LOTM_MS_STAR_SIGHT_PLOTS_V1")));
 local patrols=Patrols(p);
 for _,key in ipairs(Keys(patrols)) do Count(PlotList(patrols[key].Plots)); end
 if N(p,PREFIX.."FULL_VISION_ACTIVE",0)==1 then
  for i=0,Map.GetPlotCount()-1 do expected[i]=(expected[i] or 0)+1; end
 end
 local indices=Keys(expected);
 local restored=0;
 for _,i in ipairs(indices) do
  local missing=expected[i]-visibility:GetVisibilityCount(i);
  if missing>0 then visibility:ChangeVisibilityCount(i,missing); restored=restored+missing; end
 end
 sessionRestored[p:GetID()]=true;
 Log("load references player="..p:GetID().." checked="..#indices.." restored="..restored);
 -- Saved native counts and a saved source ledger are retained. Positive
 -- counts alone cannot prove source identity after a native engine rebuild;
 -- that mixed-source load case remains an explicit native acceptance test.
end
local function Movement(p,on)
 local row=GameInfo.Resources["RESOURCE_LOTM_RESCUE_STAR_PATROL_ACTIVE"];
 if row==nil then return; end
 if N(p,PREFIX.."MOVEMENT_ATTACHED",0)~=1 then
  local ok,r=pcall(function() return p:AttachModifierByID("LOTM_RESCUE_STAR_PATROL_MOVEMENT"); end);
  if not ok or r==false then Log("movement attach rejected player="..p:GetID()); return; end
  p:SetProperty(PREFIX.."MOVEMENT_ATTACHED",1);
 end
 local resources=p:GetResources(); local current=resources:GetResourceAmount(row.Index) or 0;
 local wanted=on and 1 or 0;
 if current~=wanted then
  resources:ChangeResourceAmount(row.Index,wanted-current);
  p:SetProperty(PREFIX.."MOVEMENT_EPOCH",N(p,PREFIX.."MOVEMENT_EPOCH",0)+1);
 end
 p:SetProperty(PREFIX.."MOVEMENT_ACTIVE",wanted);
end
local function FullVision(p,on)
 local active=N(p,PREFIX.."FULL_VISION_ACTIVE",0)==1;
 if active==on then return; end
 local visibility=PlayersVisibility[p:GetID()]; if visibility==nil then return; end
 local changed=0; local before=visibility:GetVisibilityCount(0);
 -- This is an activation/deactivation edge, never a recurring turn scan.
 for i=0,Map.GetPlotCount()-1 do
  if on or visibility:GetVisibilityCount(i)>0 then
   visibility:ChangeVisibilityCount(i,on and 1 or -1); changed=changed+1;
  end
 end
 p:SetProperty(PREFIX.."FULL_VISION_ACTIVE",on and 1 or 0);
 Log("full vision player="..p:GetID().." active="..tostring(on).." plots="..changed
  .." sample0="..before.."->"..visibility:GetVisibilityCount(0));
end
local function InitializeUnitLedger()
 if GN(PREFIX.."UNIT_LEDGER_VERSION",0)>=VERSION then return true; end
 local ids=PlayerManager.GetAliveIDs(); table.sort(ids);
 if #ids==0 then return false; end
 for _,owner in ipairs(ids) do if Players[owner]==nil then return false; end end
 for _,owner in ipairs(ids) do
  local p=Players[owner]; local units={};
  for _,u in p:GetUnits():Members() do units[#units+1]=u; end
  table.sort(units,function(a,b) return a:GetID()<b:GetID(); end);
  for _,u in ipairs(units) do Observe(owner,u:GetID()); end
 end
 Game.SetProperty(PREFIX.."UNIT_LEDGER_VERSION",VERSION);
 Log("one-time unit ledger initialized version="..VERSION);
 return true;
end
function API.Refresh(playerID)
 if not Enabled() then return; end
 if not InitializeUnitLedger() then return; end
 local p=Players[playerID]; if p==nil or not p:IsMajor() then return; end
 if LOTM_MS~=nil and LOTM_MS.RefreshStarSight~=nil then LOTM_MS.RefreshStarSight(playerID); end
 RestoreReferences(p);
 local patrol=Effective(p,GLOVES);
 Movement(p,patrol); ReconcilePatrols(p,not patrol); FullVision(p,Effective(p,WORLD));
 p:SetProperty(PREFIX.."STATE_VERSION",VERSION);
end
local function OnMoved(owner,id)
 if not Enabled() then return; end
 local fact=Observe(owner,id); if fact==nil then return; end
 local u=Unit(owner,id); if not Recon(u) then return; end
 local p=Player(owner); if not Effective(p,GLOVES) then return; end
 local serial=N(u,PREFIX.."MOVE_SERIAL",0)+1;
 u:SetProperty(PREFIX.."MOVE_SERIAL",serial);
 u:SetProperty(PREFIX.."MOVE_TURN",Game.GetCurrentGameTurn());
 u:SetProperty(PREFIX.."MOVE_EFFECT_EPOCH",N(p,PREFIX.."MOVEMENT_EPOCH",0));
 -- The synchronous per-step hook records proof only. UnitMoveComplete in
 -- UI requests the final endpoint, rather than granting sight while walking.
end
local function OnMoveComplete(playerID,data)
 if not Enabled() or data==nil then return; end
 local p=Player(playerID); if not Effective(p,GLOVES) then return; end
 local u=Unit(playerID,tonumber(data.UnitID) or -1); if not Recon(u) then return; end
 local turn=Game.GetCurrentGameTurn(); local serial=N(u,PREFIX.."MOVE_SERIAL",0);
 local plot=Map.GetPlot(u:GetX(),u:GetY());
 if serial<=0 or tonumber(data.MoveSerial)~=serial or tonumber(data.Identity)~=N(u,PREFIX.."IDENTITY",0)
  or tonumber(data.Turn)~=turn or N(u,PREFIX.."MOVE_TURN",-1)~=turn
  or N(u,PREFIX.."MOVE_EFFECT_EPOCH",-1)~=N(p,PREFIX.."MOVEMENT_EPOCH",0)
  or plot==nil or tonumber(data.PlotIndex)~=plot:GetIndex() then return; end
 API.Refresh(playerID);
 local ledger=Patrols(p); local key=tostring(u:GetID()); local old=ledger[key];
 if old~=nil and old.Identity==N(u,PREFIX.."IDENTITY",0) and old.MoveSerial==serial then return; end
 DropPatrol(p,key,ledger);
 local plots=Ring(plot);
 if Change(p,plots,1) then
  ledger[key]={UnitID=u:GetID(),Identity=N(u,PREFIX.."IDENTITY",0),Type=u:GetType(),Plots=CSV(plots),MoveSerial=serial,Turn=turn};
  p:SetProperty(PREFIX.."PATROL_REFERENCES",ledger);
  p:SetProperty(PREFIX.."MOVE_ACK_"..u:GetID(),tostring(N(u,PREFIX.."IDENTITY",0))..":"..serial);
  Log("patrol stop player="..playerID.." unit="..u:GetID().." serial="..serial.." plots="..#plots);
 end
end
local function OnLifecycle(playerID,data)
 if not Enabled() or data==nil then return; end
 local owner=tonumber(data.OwnerID); local id=tonumber(data.UnitID);
 if owner==nil or id==nil or owner<0 or id<0 then return; end
 -- A UI notification cannot invent unit metadata: read the native object now.
 Observe(owner,id);
 API.Refresh(owner);
 if data.Token~=nil then
  local sender=Player(playerID);
  if sender~=nil then sender:SetProperty(PREFIX.."LIFE_ACK_"..owner..":"..id,tostring(data.Token)); end
 end
end
local function Enemy(p,victimOwner)
 if victimOwner==p:GetID() or Players[victimOwner]==nil then return false; end
 local diplomacy=p:GetDiplomacy();
 return diplomacy~=nil and diplomacy:IsAtWarWith(victimOwner);
end
local function SettleKill(killerOwner,killerUnitID,victimOwner,victimID,killerDistrictID,confirmedKill)
 if tonumber(victimOwner)==nil or tonumber(victimID)==nil or victimOwner<0 or victimID<0 then return; end
 local p=Player(killerOwner); if not Effective(p,CASE) or not Enemy(p,victimOwner) then return; end
 local victim=Unit(victimOwner,victimID);
 if not Dead(victim) then return; end -- No reward for saved/converted living units.
 local attacker=Unit(killerOwner,killerUnitID);
 local attributable=attacker~=nil and attacker:GetOwner()==killerOwner
  and CombatRow(GameInfo.Units[attacker:GetType()]);
 if not attributable and killerDistrictID~=nil and killerDistrictID>=0 then
  -- Native OnCombatOccurred's district identity, never a UI-supplied city.
  if p.GetDistricts~=nil then
   local districts=p:GetDistricts();
   local d=districts~=nil and districts.FindID~=nil and districts:FindID(killerDistrictID) or nil;
   attributable=d~=nil and d:GetOwner()==killerOwner;
  end
 end
 if not attributable then return; end
 local fact=victim~=nil and Observe(victimOwner,victimID) or Game.GetProperty(META..victimOwner..":"..victimID);
 if type(fact)~="table" or not CombatRow(GameInfo.Units[fact.Type]) then
  Log("kill skipped missing native victim evidence owner="..victimOwner.." unit="..victimID); return;
 end
 local proof=Game.GetProperty(META..victimOwner..":"..victimID..":KILL_PROOF");
 local proved=type(proof)=="table" and proof.Identity==fact.Identity
  and proof.KillerOwner==killerOwner and proof.KillerUnitID==killerUnitID
  and proof.Turn==Game.GetCurrentGameTurn();
 -- A vanished object by itself is not a kill. Without the synchronized kill
 -- hook's native proof, script deletion/conversion cannot become a reward.
 if victim==nil and not proved then
  Log("kill skipped absent fatal proof owner="..victimOwner.." unit="..victimID);return;
 end
 local key=PREFIX.."KILL:"..victimOwner..":"..victimID..":"..fact.Identity;
 if GN(key,0)~=0 then return; end
 local plot=Map.GetPlotByIndex(proved and proof.Plot or fact.Plot);
 local territory=proved and proof.TerritoryOwner or (plot~=nil and plot:GetOwner() or -1);
 if plot==nil or territory~=killerOwner then Game.SetProperty(key,-1);return; end
 local choice=GN(key..":CHOICE",-1);
 if choice<0 then
  choice=LOTM_MP_TurnSync.Random(2,"Star case:"..killerOwner..":"..victimOwner..":"..victimID..":"..fact.Identity);
  Game.SetProperty(key..":CHOICE",choice);
 end
 if choice==0 then p:GetTechs():ChangeCurrentResearchProgress(300);
 else p:GetCulture():ChangeCurrentCulturalProgress(300); end
 Game.SetProperty(key,1);
 p:SetProperty(PREFIX.."LAST_REWARD",choice==0 and "SCIENCE" or "CULTURE");
 p:SetProperty(PREFIX.."REWARD_SERIAL",N(p,PREFIX.."REWARD_SERIAL",0)+1);
 Log("case kill player="..killerOwner.." victim="..victimOwner..":"..victimID
  .." identity="..fact.Identity.." plot="..fact.Plot.." yield="..(choice==0 and "SCIENCE" or "CULTURE").." amount=300");
end
local function OnCombat(a,au,d,du,ad,dd)
 if not Enabled() then return; end
 SettleKill(a,au,d,du,ad,false); SettleKill(d,du,a,au,dd,false);
 -- Refresh surviving identities at this synchronous endpoint.
 Observe(a,au); Observe(d,du);
 API.Refresh(a); if d~=a then API.Refresh(d); end
end
local function OnKilled(victimOwner,victimID,killerOwner,killerID)
 if not Enabled() then return; end
 -- Preserve the victim before native removal if this synchronized hook
 -- precedes the final combat endpoint. Alive/saved units never pay here.
 local fact=Observe(victimOwner,victimID) or Game.GetProperty(META..victimOwner..":"..victimID);
 if type(fact)=="table" then
  local plot=Map.GetPlotByIndex(fact.Plot);
  Game.SetProperty(META..victimOwner..":"..victimID..":KILL_PROOF",{Identity=fact.Identity,
   KillerOwner=killerOwner,KillerUnitID=killerID,Turn=Game.GetCurrentGameTurn(),Plot=fact.Plot,
   TerritoryOwner=plot~=nil and plot:GetOwner() or -1});
 end
 SettleKill(killerOwner,killerID,victimOwner,victimID,nil,true);
 local p=Player(victimOwner); if p~=nil and Dead(Unit(victimOwner,victimID)) then
  local ledger=Patrols(p); DropPatrol(p,tostring(victimID),ledger); p:SetProperty(PREFIX.."PATROL_REFERENCES",ledger);
 end
end
local function OnTurn(playerID,first)
 if not Enabled() or first==false then return; end
 local p=Player(playerID); if p==nil then return; end
 local turn=Game.GetCurrentGameTurn();
 API.Refresh(playerID);
 if N(p,PREFIX.."PATROL_CLEAR_TURN",-1)==turn then return; end
 ReconcilePatrols(p,true); p:SetProperty(PREFIX.."PATROL_CLEAR_TURN",turn);
end
if Configured() then
 GameEvents.OnUnitMoved.Add(OnMoved);
 GameEvents.OnCombatOccurred.Add(OnCombat);
 GameEvents.UnitKilledInCombat.Add(OnKilled);
 GameEvents.LOTM_RESCUE_StarMoveComplete.Add(OnMoveComplete);
 GameEvents.LOTM_RESCUE_StarUnitLifecycle.Add(OnLifecycle);
 LOTM_MP_TurnSync.AddSynchronized(OnTurn,"RescueStarGovernor");
 Log("registered rescue C/D version="..VERSION.." movement=completionProof vision=sourceLedger kill=identityDedup");
end
