-- Redemption-mode Thief pathway and Purification Energy ledger.
-- This module is intentionally rescue-only.  The ordinary Thief module is not
-- imported in redemption games and remains a locked normal-mode surface.
include("LOTM_Effects");
LOTM_RESCUE_Thief = LOTM_RESCUE_Thief or {};

local PATH = "PATH_THIEF";
local HERO = "UNIT_LOTM_TP_PATH_HOLDER";
local WORM = "UNIT_LOTM_RESCUE_TIME_WORM";
local CAMP_FOUNDER = "UNIT_LOTM_RESCUE_CAMP_FOUNDER";
local VERSION = 6;
local MADNESS_EFFECT_VERSION = 1;
local WALL_EFFECT_VERSION = 3;
local ARMY_EFFECT_VERSION = 2;
local ABILITIES = {"MADNESS","ECHO","ARMY","WALL"};
-- Rescue defines the same stable project identities as normal Thief, while
-- keeping the normal-mode runtime entirely criteria-gated out.
local POTION_BY_SEQUENCE = {
 [9]="PROJECT_LOTM_TP_SWINDLER_POTION",[8]="PROJECT_LOTM_TP_CRYPTOLOGIST_POTION",
 [7]="PROJECT_LOTM_TP_PROMETHEUS_POTION",[6]="PROJECT_LOTM_TP_DREAM_STEALER_POTION",
 [5]="PROJECT_LOTM_TP_PARASITE_POTION",[4]="PROJECT_LOTM_TP_MENTOR_OF_DECEIT_POTION",
 [3]="PROJECT_LOTM_TP_FATE_TROJAN_POTION",[2]="PROJECT_LOTM_TP_WORM_OF_TIME_POTION",
 [1]="PROJECT_LOTM_TP_ERROR_APOTHEOSIS"
};
local POTIONS={};
for sequence=1,9 do POTIONS[POTION_BY_SEQUENCE[sequence]]={sequence,sequence-1}; end
local pendingPotionProjects={};
local pendingPotionProjectKeys={};
local ResolveProjectRow;
local COSTS = {
 MADNESS={40,60,80,100,120,140,160,180,200,220},
 ECHO={40,60,80,100,120,140,160,180,200,220},
 ARMY={40,60,80,100,120,140,160,180,200,220},
 WALL={40,60,80,100,120,140,160,180,200,220}
};
local YIELDS={"YIELD_FOOD","YIELD_PRODUCTION","YIELD_GOLD","YIELD_SCIENCE","YIELD_CULTURE","YIELD_FAITH"};
local P = {
 Balance="LOTM_RESCUE_ENERGY_BALANCE", Spent="LOTM_RESCUE_ENERGY_SPENT",
 LastGlobal="LOTM_RESCUE_ENERGY_LAST_GLOBAL", Version="LOTM_RESCUE_ENERGY_VERSION",
 LastTurn="LOTM_RESCUE_THIEF_LAST_ENERGY_TURN", LastEffectTurn="LOTM_RESCUE_THIEF_LAST_EFFECT_TURN",
 Allocated="LOTM_RESCUE_ABILITY_ALLOCATED_", Cost="LOTM_RESCUE_ABILITY_ALLOC_COST_",
 Level="LOTM_RESCUE_ABILITY_LEVEL_", Applied="LOTM_RESCUE_ABILITY_APPLIED_",
 Sequence2="LOTM_RESCUE_THIEF_S2_DONE", Worm="LOTM_RESCUE_TIME_WORM_ID",
 WormPlot="LOTM_RESCUE_TIME_WORM_LAST_PLOT", WormCooldown="LOTM_RESCUE_TIME_WORM_COOLDOWN", ConvertTurn="LOTM_RESCUE_CAMP_CONVERT_TURN",
 ConvertMode="LOTM_RESCUE_CAMP_CONVERT_MODE", ConvertPending="LOTM_RESCUE_CAMP_CONVERT_PENDING",
 ConvertPlot="LOTM_RESCUE_CAMP_CONVERT_PLOT", ConvertActor="LOTM_RESCUE_CAMP_CONVERT_ACTOR",
 ConvertCity="LOTM_RESCUE_CAMP_CONVERT_CITY",
 ConvertTempActor="LOTM_RESCUE_CAMP_CONVERT_TEMP_ACTOR",
 ConvertTarget="LOTM_RESCUE_CAMP_CONVERT_TARGET",
 CommandSerial="LOTM_RESCUE_THIEF_COMMAND_SERIAL", ProductionBuffer="LOTM_RESCUE_THIEF_PRODUCTION_BUFFER",
  FoundPlot="LOTM_RESCUE_TIME_WORM_FOUND_PLOT", FoundTempActor="LOTM_RESCUE_TIME_WORM_FOUND_TEMP_ACTOR", FoundPending="LOTM_RESCUE_TIME_WORM_FOUND_PENDING", FoundTarget="LOTM_RESCUE_TIME_WORM_FOUND_TARGET", SwindlerGoldAttached="LOTM_RESCUE_TP_SWINDLER_GOLD_ATTACHED"
  ,LastActivePotion="LOTM_RESCUE_THIEF_LAST_ACTIVE_POTION",
 MadnessRefreshSignature="LOTM_RESCUE_MADNESS_REFRESH_SIGNATURE",
 MadnessEffectMigration="LOTM_RESCUE_MADNESS_EFFECT_MIGRATION_VERSION",
 WallModifierMigration="LOTM_RESCUE_WALL_MODIFIER_MIGRATION_VERSION",
 ArmyModifierMigration="LOTM_RESCUE_ARMY_MODIFIER_MIGRATION_VERSION",
 KnowledgeBonusScience="LOTM_RESCUE_THIEF_KNOWLEDGE_BONUS_SCIENCE",
 KnowledgeBonusCulture="LOTM_RESCUE_THIEF_KNOWLEDGE_BONUS_CULTURE",
  KnowledgeBonusFaith="LOTM_RESCUE_THIEF_KNOWLEDGE_BONUS_FAITH",
  GiftNewCitiesToAI="LOTM_RESCUE_THIEF_GIFT_NEW_CITIES_TO_AI"
};

local function N(value,default) if value==nil then return default; end return tonumber(value) or default; end
local function Log(message) print("[LOTM_RESCUE][Thief] "..tostring(message)); end
local function RunTimedTurnSection(playerID,turn,name,callback)
 -- Reuse the diagnostic timer owned by LOTM_UnitAddedPerf.  Keeping clock
 -- access in that one diagnostic module avoids nondeterministic Gameplay
 -- calls while still publishing per-turn milliseconds in Lua.log.
 local sectionName="RescueThief.Turn."..tostring(name);
 local stat=LOTM_UnitAddedPerf~=nil and LOTM_UnitAddedPerf.Sections~=nil and LOTM_UnitAddedPerf.Sections[sectionName] or nil;
 local before=stat~=nil and tonumber(stat.TotalMs) or 0;
 local started=LOTM_UnitAddedPerf~=nil and LOTM_UnitAddedPerf.BeginSection~=nil and LOTM_UnitAddedPerf.BeginSection() or nil;
 callback();
 if LOTM_UnitAddedPerf~=nil and LOTM_UnitAddedPerf.EndSection~=nil then LOTM_UnitAddedPerf.EndSection(sectionName,started,1); end
 stat=LOTM_UnitAddedPerf~=nil and LOTM_UnitAddedPerf.Sections~=nil and LOTM_UnitAddedPerf.Sections[sectionName] or nil;
 local elapsed=stat~=nil and (tonumber(stat.TotalMs) or 0)-before or nil;
 if elapsed~=nil and elapsed>=0 then
  Log(string.format("perf turn player=%s turn=%s section=%s ms=%.3f",tostring(playerID),tostring(turn),tostring(name),elapsed));
 end
end
local function BeginTurnPerf()
 return LOTM_UnitAddedPerf~=nil and LOTM_UnitAddedPerf.BeginSection~=nil and LOTM_UnitAddedPerf.BeginSection() or nil;
end
local function EndTurnPerf(playerID,turn,started)
 local name="RescueThief.Turn.TOTAL";
 local stat=LOTM_UnitAddedPerf~=nil and LOTM_UnitAddedPerf.Sections~=nil and LOTM_UnitAddedPerf.Sections[name] or nil;
 local before=stat~=nil and tonumber(stat.TotalMs) or 0;
 if LOTM_UnitAddedPerf~=nil and LOTM_UnitAddedPerf.EndSection~=nil then LOTM_UnitAddedPerf.EndSection(name,started,1); end
 stat=LOTM_UnitAddedPerf~=nil and LOTM_UnitAddedPerf.Sections~=nil and LOTM_UnitAddedPerf.Sections[name] or nil;
 local elapsed=stat~=nil and (tonumber(stat.TotalMs) or 0)-before or nil;
 if elapsed~=nil and elapsed>=0 then Log(string.format("perf turn player=%s turn=%s section=TOTAL ms=%.3f",tostring(playerID),tostring(turn),elapsed)); end
end
local function AddDigestion(id,category,key,amount)
 if LOTM_RP_State==nil or LOTM_RP_State.TryAddDigestion==nil then return false; end
 return LOTM_RP_State.TryAddDigestion(id,category,"RESCUE_P9:THIEF:"..tostring(key),amount);
end
local function Active()
 return N(Game.GetProperty("LOTM_RESCUE_MODE"),0)==1
  or (LOTM_MP_TurnSync~=nil and LOTM_MP_TurnSync.IsRescueModeConfigured~=nil and LOTM_MP_TurnSync.IsRescueModeConfigured());
end
local function PlayerOf(id) return id~=nil and Players[id] or nil; end
local function IsMajorHuman(id)
 local p=PlayerOf(id); return p~=nil and p:IsAlive() and p:IsMajor() and p:IsHuman();
end
local function IsCivilized(id)
 local p=PlayerOf(id); if p==nil or not p:IsAlive() then return false; end
 local c=PlayerConfigurations[id];
 return (p:IsMajor() or (c~=nil and c:GetCivilizationLevelTypeName()=="CIVILIZATION_LEVEL_CITY_STATE"));
end
local function PathPlayer(id)
 local p=PlayerOf(id); return IsMajorHuman(id) and p:GetProperty("LOTM_RP_PATH")==PATH
  and LOTM_RP_State~=nil and LOTM_RP_State.GetSequence~=nil;
end
local function AnyHumanPath(id)
 return IsMajorHuman(id) and LOTM_RP_State~=nil and LOTM_RP_State.IsAnyPathPlayer~=nil
  and LOTM_RP_State.IsAnyPathPlayer(id);
end
local function Anchor() return LOTM_MP_TurnSync~=nil and LOTM_MP_TurnSync.GetStableAnchorPlayerID~=nil
 and LOTM_MP_TurnSync.GetStableAnchorPlayerID() or (PlayerManager.GetAliveMajors()[1]~=nil and PlayerManager.GetAliveMajors()[1]:GetID() or -1); end
local function Sequence0Anchor()
 local lowest=nil; for _,p in ipairs(PlayerManager.GetAliveMajors() or {}) do if p:IsHuman() and p:GetProperty("LOTM_RP_PATH")==PATH and N(p:GetProperty("LOTM_RP_SEQUENCE"),9)==0 then if lowest==nil or p:GetID()<lowest then lowest=p:GetID(); end end end; return lowest or -1;
end
local function StableRand(limit,label)
 if limit<=0 then return 0; end
 if LOTM_MP_TurnSync~=nil and LOTM_MP_TurnSync.Random~=nil then return LOTM_MP_TurnSync.Random(limit,label); end
 local value=104729; local text=tostring(label or "RESCUE");
 for i=1,#text do value=(value*131+string.byte(text,i))%2147483647; end
 return value%limit;
end
local function Global(key,default) return N(Game.GetProperty(key),default or 0); end
local function SetGlobal(key,value) Game.SetProperty(key,math.floor(tonumber(value) or 0)); end
local function Balance(p) return math.max(0,N(p:GetProperty(P.Balance),0)); end
local function SetBalance(p,value) p:SetProperty(P.Balance,math.max(0,math.floor(value))); end
local function Seq(id) return N(PlayerOf(id):GetProperty("LOTM_RP_SEQUENCE"),9); end

local function GetOtherMajors(id)
 local result={};
 for _,p in ipairs(PlayerManager.GetAliveMajors() or {}) do if p:GetID()~=id then result[#result+1]=p; end end
 table.sort(result,function(a,b) return a:GetID()<b:GetID(); end); return result;
end

local function GrantEnergyForPurification()
 if not Active() or not (LOTM_MP_TurnSync==nil or LOTM_MP_TurnSync.IsStableAnchorPlayer==nil or LOTM_MP_TurnSync.IsStableAnchorPlayer(Anchor())) then return; end
 local total=Global("GLOBAL_PURIFICATION",0);
 for _,p in ipairs(PlayerManager.GetAliveMajors() or {}) do
  local id=p:GetID(); if p:IsHuman() then
   local last=N(p:GetProperty(P.LastGlobal),0);
   if last<total and AnyHumanPath(id) then SetBalance(p,Balance(p)+(total-last)); end
   if last<total then p:SetProperty(P.LastGlobal,total); end
   if N(p:GetProperty(P.Version),0)<VERSION then p:SetProperty(P.Version,VERSION); end
  end
 end
end

local function GrantThiefPerTurn(id)
 if not PathPlayer(id) then return; end
 local p=Players[id]; local turn=Game.GetCurrentGameTurn();
 if N(p:GetProperty(P.LastTurn),-1)==turn then return; end
 -- Redemption Sequence 4 now uses its slot for the camp-city parasite
 -- ability; it no longer grants a separate +2 energy burst.  All rescue
 -- Thief sequences therefore receive the same inherited +1 energy income.
 local amount=1;
 SetBalance(p,Balance(p)+amount); p:SetProperty(P.LastTurn,turn);
 Log("energy income player="..id.." turn="..turn.." amount="..amount.." balance="..Balance(p));
end

local function EnsureSwindlerGold(id)
 if not PathPlayer(id) or Seq(id)>8 then return false; end
 local p=Players[id]; if p.AttachModifierByID==nil then return false; end
 if N(p:GetProperty(P.SwindlerGoldAttached),0)==1 then return true; end
 local ok=pcall(function() p:AttachModifierByID("LOTM_RESCUE_TP_SWINDLER_GOLD"); end)
 if ok then p:SetProperty(P.SwindlerGoldAttached,1); Log("swindler gold modifier attached player="..id.." amount=20"); end
 return ok;
end

local function AttachToCivilizations(modifierID)
 local attached=0;
 for _,p in ipairs(PlayerManager.GetAliveMajors() or {}) do if p.AttachModifierByID~=nil then local ok=pcall(function() p:AttachModifierByID(modifierID); end); if ok then attached=attached+1; end end end
 for _,p in ipairs(PlayerManager.GetAliveMinors() or {}) do if p.AttachModifierByID~=nil then local ok=pcall(function() p:AttachModifierByID(modifierID); end); if ok then attached=attached+1; end end end
 return attached;
end

local function DetachAllFromCivilizations(modifierID)
 local detached=0;
 local function clear(player)
  if player==nil or player.DetachModifierByID==nil then return; end
  -- DetachModifierByID removes one instance on each call.  The loop is
  -- intentionally bounded above the ten-point cap so old saves with stacked
  -- copies are fully normalized without an unbounded scan.
  for _=1,20 do
   local ok=pcall(function() player:DetachModifierByID(modifierID); end);
   if not ok then break; end
   detached=detached+1;
  end
 end
 for _,p in ipairs(PlayerManager.GetAliveMajors() or {}) do clear(p); end
 for _,p in ipairs(PlayerManager.GetAliveMinors() or {}) do clear(p); end
 return detached;
end

local function RebuildWallEffects(level)
 -- A wall point is a global level applied to every civilization.  Rebuilding
 -- all legacy/exact IDs from zero makes deallocation and old-save migration
 -- idempotent.  One exact +5..+50 modifier is attached instead of stacking
 -- the same ID repeatedly, which the engine may collapse in existing saves.
 local cleared=DetachAllFromCivilizations("LOTM_RESCUE_PURIF_WALL_PLUS")
  +DetachAllFromCivilizations("LOTM_RESCUE_PURIF_WALL_MINUS");
 for i=1,10 do cleared=cleared+DetachAllFromCivilizations("LOTM_RESCUE_PURIF_WALL_LEVEL_"..tostring(i)); end
 local attached=0;
 local exactLevel=math.max(0,math.min(10,level));
 if exactLevel>0 then attached=AttachToCivilizations("LOTM_RESCUE_PURIF_WALL_LEVEL_"..tostring(exactLevel)); end
 Log("wall effects rebuilt version="..WALL_EFFECT_VERSION.." level="..tostring(exactLevel).." amount="..tostring(exactLevel*5).." cleared="..cleared.." attached="..attached.." modifierType=MODIFIER_PLAYER_CITIES_ADJUST_OUTER_DEFENSE exactLevelModifier=true");
end

local function RebuildArmyEffects(level)
 -- Match the Red Priest's explicit player-scoped base-strength modifier
 -- chain. Normalize legacy repeated +/-5 attachments first, then attach one
 -- unique total-level modifier so visible strength and combat both get the
 -- exact +5..+50 value.
 local cleared=DetachAllFromCivilizations("LOTM_RESCUE_PURIF_ARMY_PLUS")
  +DetachAllFromCivilizations("LOTM_RESCUE_PURIF_ARMY_MINUS");
 for i=1,10 do cleared=cleared+DetachAllFromCivilizations("LOTM_RESCUE_PURIF_ARMY_LEVEL_"..tostring(i)); end
 local attached=0;
 local exactLevel=math.max(0,math.min(10,level));
 if exactLevel>0 then attached=AttachToCivilizations("LOTM_RESCUE_PURIF_ARMY_LEVEL_"..tostring(exactLevel)); end
 Log("army effects rebuilt version="..ARMY_EFFECT_VERSION.." level="..tostring(exactLevel).." amount="..tostring(exactLevel*5).." cleared="..cleared.." attached="..attached.." modifierType=MODIFIER_LOTM_RP_PLAYER_UNITS_ADJUST_BASE_COMBAT_STRENGTH exactLevelModifier=true");
end

local function ApplyLevelEffects(name,oldLevel,newLevel)
 if newLevel==oldLevel then return; end
 local delta=newLevel-oldLevel; local plus,minus;
 if name=="MADNESS" then return; end
 if name=="WALL" then RebuildWallEffects(newLevel); SetGlobal(P.Applied..name,newLevel); return; end
 if name=="ARMY" then RebuildArmyEffects(newLevel); SetGlobal(P.Applied..name,newLevel); return; end
 if name=="ECHO" then
  for _,yield in ipairs(YIELDS) do
   plus="LOTM_RESCUE_PURIF_ECHO_"..string.sub(yield,7).."_PLUS"; minus="LOTM_RESCUE_PURIF_ECHO_"..string.sub(yield,7).."_MINUS";
   for _=1,math.abs(delta) do AttachToCivilizations(delta>0 and plus or minus); end
  end
 end
 local attached=0;
 if plus~=nil then for _=1,math.abs(delta) do attached=attached+AttachToCivilizations(delta>0 and plus or minus); end end
 SetGlobal(P.Applied..name,newLevel); Log("ability effect name="..name.." level="..newLevel.." delta="..delta.." civilizationAttachments="..attached);
end

local function IsOuterGod(unit)
 return unit~=nil and (N(unit:GetProperty("LOTM_RESCUE_OUTER_GOD"),0)==1 or N(unit:GetProperty("LOTM_RESCUE_OUTER_GOD_MINION"),0)==1);
end
function LOTM_RESCUE_Thief.ApplyMadnessToUnit(unit)
 if not Active() or unit==nil or IsOuterGod(unit) then return false; end
 local level=Global(P.Level.."MADNESS",0); local ability=unit:GetAbility(); if ability==nil then return false; end
 local desired=level>0 and ("LOTM_RESCUE_PURIFICATION_MADNESS_"..tostring(level*5)) or nil;
 for i=1,10 do local id="LOTM_RESCUE_PURIFICATION_MADNESS_"..tostring(i*5); if GameInfo.UnitAbilities[id]~=nil then LOTM_Effects.SetAbilityCount(ability,id,id==desired and 1 or 0); end end
 return true;
end

local function RefreshMadness()
 if not Active() or PlayerManager.GetAliveBarbarians==nil then return; end
 local level=Global(P.Level.."MADNESS",0);
 local activeSerials=tostring(Game.GetProperty("LOTM_WORLD_MONSTER_ACTIVE_SERIALS") or "");
 local signature=tostring(level)..":"..activeSerials;
 if tostring(Game.GetProperty(P.MadnessRefreshSignature) or "")==signature then return; end
 local monsters=0; local applied=0;
 for _,barb in ipairs(PlayerManager.GetAliveBarbarians() or {}) do for _,unit in barb:GetUnits():Members() do
  if LOTM_WORLD_Monsters~=nil and LOTM_WORLD_Monsters.IsMonster~=nil and LOTM_WORLD_Monsters.IsMonster(unit) then
   monsters=monsters+1; if LOTM_RESCUE_Thief.ApplyMadnessToUnit(unit) then applied=applied+1; end
  end
 end end
 Game.SetProperty(P.MadnessRefreshSignature,signature);
 Log("madness effects refreshed version="..MADNESS_EFFECT_VERSION.." level="..level.." strengthDelta="..(-5*level).." monsters="..monsters.." applied="..applied.." abilityTag=CLASS_ALL_COMBAT_UNITS");
end

local function RefreshEffects()
 -- rc.325 changed the wall effect from an unregistered built-in modifier name
 -- to the rescue dynamic player-city modifier.  Existing saves retain the
 -- numeric level/applied properties, so force one level-delta replay exactly
 -- once to materialize the modifier on every existing city after load.
 local wallLevel=math.max(0,math.min(10,Global(P.Level.."WALL",0)));
 local armyLevel=math.max(0,math.min(10,Global(P.Level.."ARMY",0)));
 local forceMadnessMigration=Global(P.MadnessEffectMigration,0)<MADNESS_EFFECT_VERSION;
 if forceMadnessMigration then Game.SetProperty(P.MadnessRefreshSignature,nil); end
 if Global(P.WallModifierMigration,0)<WALL_EFFECT_VERSION then
  RebuildWallEffects(wallLevel);
  SetGlobal(P.Applied.."WALL",wallLevel);
  SetGlobal(P.WallModifierMigration,WALL_EFFECT_VERSION);
 end
 if Global(P.ArmyModifierMigration,0)<ARMY_EFFECT_VERSION then
  RebuildArmyEffects(armyLevel);
  SetGlobal(P.Applied.."ARMY",armyLevel);
  SetGlobal(P.ArmyModifierMigration,ARMY_EFFECT_VERSION);
 end
 for _,name in ipairs(ABILITIES) do local level=math.max(0,math.min(10,Global(P.Level..name,0))); local applied=Global(P.Applied..name,0); if name=="MADNESS" then RefreshMadness(); SetGlobal(P.Applied..name,level); else if applied~=level then ApplyLevelEffects(name,applied,level); end end end
 if forceMadnessMigration then SetGlobal(P.MadnessEffectMigration,MADNESS_EFFECT_VERSION); end
end

local function Allocate(id,name)
 if not Active() or not AnyHumanPath(id) or COSTS[name]==nil then return false,"PLAYER_OR_ABILITY"; end
 local p=Players[id]; local level=Global(P.Level..name,0); if level>=10 then return false,"MAX_LEVEL"; end
 local cost=COSTS[name][level+1]; if Balance(p)<cost then return false,"ENERGY"; end
 SetBalance(p,Balance(p)-cost); p:SetProperty(P.Spent,N(p:GetProperty(P.Spent),0)+cost);
 p:SetProperty(P.Allocated..name,N(p:GetProperty(P.Allocated..name),0)+1);
 local serial=N(p:GetProperty(P.CommandSerial),0)+1; p:SetProperty(P.CommandSerial,serial); p:SetProperty(P.Cost..name.."_"..serial,cost);
 SetGlobal(P.Level..name,level+1); RefreshEffects(); Log("allocate player="..id.." ability="..name.." level="..(level+1).." cost="..cost); return true;
end

-- The row-level minus button removes exactly the most recent point in this
-- ability. Costs come from the per-allocation ledger rather than being
-- recalculated, so refunds remain correct if a later resource changes costs.
local function DeallocateOne(id,name)
 if not Active() or not AnyHumanPath(id) or COSTS[name]==nil then return false,"PLAYER_OR_ABILITY"; end
 local p=Players[id]; local count=N(p:GetProperty(P.Allocated..name),0); if count<=0 then return false,"NO_POINTS"; end
 local level=Global(P.Level..name,0); if level<=0 then return false,"NO_GLOBAL_LEVEL"; end
 local serialTop=N(p:GetProperty(P.CommandSerial),0); local serial=nil; local refund=0;
 for candidate=serialTop,1,-1 do
  local key=P.Cost..name.."_"..candidate; local raw=p:GetProperty(key);
  if raw~=nil then serial=candidate; refund=math.max(0,N(raw,0)); p:SetProperty(key,nil); break; end
 end
 if serial==nil then Log("deallocate rejected player="..id.." ability="..name.." reason=MISSING_COST_LEDGER"); return false,"MISSING_COST_LEDGER"; end
 SetBalance(p,Balance(p)+refund); p:SetProperty(P.Spent,math.max(0,N(p:GetProperty(P.Spent),0)-refund)); p:SetProperty(P.Allocated..name,count-1);
 SetGlobal(P.Level..name,level-1); RefreshEffects(); Log("deallocate player="..id.." ability="..name.." level="..(level-1).." refund="..refund.." serial="..serial); return true;
end

local function ResetOne(id,name)
 if not Active() or not AnyHumanPath(id) or COSTS[name]==nil then return false; end
 local p=Players[id]; local count=N(p:GetProperty(P.Allocated..name),0); if count<=0 then return false; end
 local refund=0; for serial=1,N(p:GetProperty(P.CommandSerial),0) do local key=P.Cost..name.."_"..serial; local cost=p:GetProperty(key); if cost~=nil then refund=refund+N(cost,0); p:SetProperty(key,nil); end end
 SetBalance(p,Balance(p)+refund); p:SetProperty(P.Allocated..name,0); p:SetProperty(P.Spent,math.max(0,N(p:GetProperty(P.Spent),0)-refund));
 local level=Global(P.Level..name,0); SetGlobal(P.Level..name,math.max(0,level-count)); RefreshEffects(); Log("reset player="..id.." ability="..name.." points="..count.." refund="..refund); return true;
end
local function ResetAll(id) local changed=false; for _,name in ipairs(ABILITIES) do changed=ResetOne(id,name) or changed; end return changed; end

local function CopyGold(id)
 local p=Players[id]; local total=0; for _,other in ipairs(GetOtherMajors(id)) do total=total+math.max(0,N(other:GetTreasury():GetGoldYield(),0)); end
 local amount=LOTM_Effects.PercentFloor(total,50); if amount>0 then p:GetTreasury():ChangeGoldBalance(amount); Log("copy gold player="..id.." amount="..amount.." sourceTotal="..total); end
 return amount>0,amount;
end
local function CopyProduction(id)
 local function Producing(queue)
  return queue~=nil and queue.GetCurrentProductionTypeHash~=nil
   and N(queue:GetCurrentProductionTypeHash(),0)~=0;
 end
 local p=Players[id]; local total=0;
 for _,other in ipairs(GetOtherMajors(id)) do for _,city in other:GetCities():Members() do
  if Producing(city:GetBuildQueue()) then total=total+math.max(0,N(city:GetYield(YieldTypes.PRODUCTION),0)); end
 end end
 local amount=LOTM_Effects.PercentFloor(total,10);
 local pending=math.max(0,N(p:GetProperty(P.ProductionBuffer),0))+amount;
 if pending<=0 then return false,0; end
 local city=p:GetCities():GetCapitalCity(); local q=city~=nil and city:GetBuildQueue() or nil; local ok=false;
 if Producing(q) and q.AddProgress~=nil then
  local called,result=pcall(function() return q:AddProgress(pending); end); ok=called and result~=false;
 end
 p:SetProperty(P.ProductionBuffer,ok and 0 or pending);
 Log("copy production player="..id.." amount="..amount.." delivered="..(ok and pending or 0).." queued="..tostring(ok));
 return ok,amount;
end

-- Keep rescue knowledge on the native player yield stack, matching the
-- ordinary Thief's SetKnowledgeYieldBonus implementation.  Only the delta is
-- attached, so repeated turns neither lose nor multiply the previous bonus.
local KNOWLEDGE_BONUS = {
 SCIENCE={Property=P.KnowledgeBonusScience,Plus="LOTM_RESCUE_KNOWLEDGE_SCIENCE_PLUS_1",Minus="LOTM_RESCUE_KNOWLEDGE_SCIENCE_MINUS_1"},
 CULTURE={Property=P.KnowledgeBonusCulture,Plus="LOTM_RESCUE_KNOWLEDGE_CULTURE_PLUS_1",Minus="LOTM_RESCUE_KNOWLEDGE_CULTURE_MINUS_1"},
 FAITH={Property=P.KnowledgeBonusFaith,Plus="LOTM_RESCUE_KNOWLEDGE_FAITH_PLUS_1",Minus="LOTM_RESCUE_KNOWLEDGE_FAITH_MINUS_1"}
};
local function SetKnowledgeYieldBonus(id,player,category,desired)
 local definition=KNOWLEDGE_BONUS[category]; if player==nil or definition==nil or player.AttachModifierByID==nil then return false,0; end
 desired=math.max(0,math.floor(N(desired,0))); local old=math.max(0,math.floor(N(player:GetProperty(definition.Property),0))); local delta=desired-old;
 if delta==0 then return true,old; end
 local modifierID=delta>0 and definition.Plus or definition.Minus; local rollbackID=delta>0 and definition.Minus or definition.Plus; local count=math.abs(delta); local applied=0;
 for _=1,count do
  local ok=pcall(function() player:AttachModifierByID(modifierID); end);
  if not ok then for _=1,applied do pcall(function() player:AttachModifierByID(rollbackID); end); end; Log("knowledge native attach failed player="..id.." category="..category.." old="..old.." desired="..desired.." applied="..applied); return false,old; end
  applied=applied+1;
 end
 player:SetProperty(definition.Property,desired); return true,old;
end

local function CopyKnowledge(id)
 local p=Players[id]; local science,culture,faith=0,0,0;
 for _,other in ipairs(GetOtherMajors(id)) do
  -- Redemption knowledge copy is deliberately half of the previous 20% rate.
  -- Sources are read-only; only the thief's synchronized progress is changed.
  science=science+LOTM_Effects.PercentFloor(other:GetTechs():GetScienceYield(),10);
  culture=culture+LOTM_Effects.PercentFloor(other:GetCulture():GetCultureYield(),10);
  faith=faith+LOTM_Effects.PercentFloor(other:GetReligion():GetFaithYield(),10);
 end
 -- Native modifiers own the actual per-turn settlement and top-panel total.
 -- Do not call ChangeCurrentResearchProgress/ChangeCurrentCulturalProgress or
 -- ChangeFaithBalance here: those APIs either debit a source or create a
 -- one-off progress change, which caused the old rescue implementation to
 -- disappear from the total and to double-apply on later turns.
 SetKnowledgeYieldBonus(id,p,"SCIENCE",science);
 SetKnowledgeYieldBonus(id,p,"CULTURE",culture);
 SetKnowledgeYieldBonus(id,p,"FAITH",faith);
 p:SetProperty("LOTM_RESCUE_THIEF_COPY_SCIENCE_LAST",science);
 p:SetProperty("LOTM_RESCUE_THIEF_COPY_CULTURE_LAST",culture);
 p:SetProperty("LOTM_RESCUE_THIEF_COPY_FAITH_LAST",faith);
 p:SetProperty("LOTM_RESCUE_THIEF_COPY_SCIENCE_TOTAL",N(p:GetProperty("LOTM_RESCUE_THIEF_COPY_SCIENCE_TOTAL"),0)+science);
 p:SetProperty("LOTM_RESCUE_THIEF_COPY_CULTURE_TOTAL",N(p:GetProperty("LOTM_RESCUE_THIEF_COPY_CULTURE_TOTAL"),0)+culture);
 p:SetProperty("LOTM_RESCUE_THIEF_COPY_FAITH_TOTAL",N(p:GetProperty("LOTM_RESCUE_THIEF_COPY_FAITH_TOTAL"),0)+faith);
 Log("copy knowledge player="..id.." science="..science.." culture="..culture.." faith="..faith);
 return science>0 or culture>0 or faith>0,science+culture+faith;
end
local function TriggerBoost(id)
 local p=Players[id]; local candidates={}; local tech=p:GetTechs(); local civ=p:GetCulture();
 for row in GameInfo.Technologies() do if not tech:HasTech(row.Index) and not tech:HasBoostBeenTriggered(row.Index) then candidates[#candidates+1]={"TECH",row.Index}; end end
 for row in GameInfo.Civics() do if not civ:HasCivic(row.Index) and not civ:HasBoostBeenTriggered(row.Index) then candidates[#candidates+1]={"CIVIC",row.Index}; end end
 table.sort(candidates,function(a,b) if a[1]~=b[1] then return a[1]<b[1]; end return a[2]<b[2]; end); if #candidates==0 then return; end
 local pick=candidates[StableRand(#candidates,"RESCUE_THIEF_S7:"..id..":"..Game.GetCurrentGameTurn())+1]; local ok=false; if pick[1]=="TECH" then ok=pcall(function() tech:TriggerBoost(pick[2],1); end) else ok=pcall(function() civ:TriggerBoost(pick[2],1); end) end; return ok;
end

local function DigestBorrowedAbilities(id)
 if not Active() or not PathPlayer(id) or Seq(id)~=2 then return false; end
 local p=Players[id];
 if N(p:GetProperty(P.Sequence2),0)~=2
  or tostring(p:GetProperty("LOTM_RESCUE_THIEF_S2_ABILITIES") or "")==""
  or tostring(p:GetProperty("LOTM_RESCUE_THIEF_S2_TRAITS") or "")=="" then return false; end
 -- Selection and the synchronized turn share one stable per-turn identity.
 -- A valid selection starts its first of six digestion turns immediately.
 return AddDigestion(id,"A","S2_BORROW_ACTIVE:"..Game.GetCurrentGameTurn());
end

local function ProcessThief(id)
 if not PathPlayer(id) then return; end
 local p=Players[id]; local turn=Game.GetCurrentGameTurn(); GrantThiefPerTurn(id); EnsureSwindlerGold(id); if N(p:GetProperty(P.LastEffectTurn),-1)==turn then return; end
  local seq=Seq(id);
  -- Sequence 9 is intentionally limited to its fixed +1 Purification Energy
  -- income.  The rescue gold-copy effect starts at Sequence 8 and is inherited
  -- by lower sequences; do not let the shared per-turn dispatcher leak it into
  -- a newly selected Sequence 9 Thief.
 if seq==9 then AddDigestion(id,"A","S9_ENERGY:"..turn); end
  if seq<=8 then local copied=CopyGold(id); if copied and seq==8 then AddDigestion(id,"A","S8_GOLD:"..turn); end end
 -- Sequence 8 and below inherit the native recurring +20 Gold modifier. It
 -- appears in the top-panel income breakdown and is attached only once.
 if seq<=7 then
  local lastBoost=N(p:GetProperty("LOTM_RESCUE_THIEF_LAST_BOOST_TURN"),-999);
  if turn-lastBoost>=2 and TriggerBoost(id) then if seq==7 then AddDigestion(id,"A","S7_BOOST:"..turn); end p:SetProperty("LOTM_RESCUE_THIEF_LAST_BOOST_TURN",turn); end
 end
 if seq<=6 then local copied=CopyProduction(id); if copied and seq==6 then AddDigestion(id,"A","S6_PRODUCTION:"..turn); end end
 if seq<=5 then local copied=CopyKnowledge(id); if copied and seq==5 then AddDigestion(id,"A","S5_YIELDS:"..turn); end end
 if seq==2 then DigestBorrowedAbilities(id); end
 -- Sequence 2 is selected through the civilization-ability chooser; do not
 -- auto-randomize before the player confirms a source.
 if seq<=1 then LOTM_RESCUE_Thief.CopyThreeAbilities(id); end
 p:SetProperty(P.LastEffectTurn,turn);
end

ResolveProjectRow=function(projectID)
 local row=projectID~=nil and GameInfo.Projects[projectID] or nil;
 if row~=nil then return row; end
 for candidate in GameInfo.Projects() do
  if candidate.Index==projectID or candidate.Hash==projectID or candidate.ProjectType==projectID then return candidate; end
 end
 return nil;
end

local function CivPortableAbilities(civType)
 local result={}; local unique={};
 for row in GameInfo.Units() do if row.TraitType then unique[row.TraitType]=true; end end
 for row in GameInfo.Buildings() do if row.TraitType then unique[row.TraitType]=true; end end
 for row in GameInfo.Districts() do if row.TraitType then unique[row.TraitType]=true; end end
 for row in GameInfo.Improvements() do if row.TraitType then unique[row.TraitType]=true; end end
 for link in GameInfo.CivilizationTraits() do
  if link.CivilizationType==civType and not unique[link.TraitType] then
   local modifiers={};
   for tm in GameInfo.TraitModifiers() do if tm.TraitType==link.TraitType and GameInfo.Modifiers[tm.ModifierId] then modifiers[#modifiers+1]=tm.ModifierId; end end
   if #modifiers>0 then table.sort(modifiers); result[#result+1]={TraitType=link.TraitType,Modifiers=modifiers}; end
  end
 end
 table.sort(result,function(a,b) return a.TraitType<b.TraitType; end); return result;
end
local function CSVSet(value)
 local result={}; for token in string.gmatch(tostring(value or ""),"[^,]+") do result[token]=true; end; return result;
end
local function EncodeStableObjectKey(value)
 local encoded={}; local text=tostring(value or ""); for index=1,#text do encoded[index]=string.format("%02X",string.byte(text,index)); end; return table.concat(encoded);
end
local function FindLegacySelectedSources(id,p)
 local candidates={};
 for _,source in ipairs(PlayerManager.GetWasEverAliveMajors() or {}) do if source:GetID()~=id then candidates[#candidates+1]=source:GetID(); end end
 table.sort(candidates);
 local function WasSelected(list)
  local objectKey="RESCUE_P9:THIEF:S2_ABILITIES_SELECTED:"..table.concat(list,",");
  local dedupKey="LOTM_RP_DIGEST_SEEN_S2_A_"..EncodeStableObjectKey(objectKey);
  return N(p:GetProperty(dedupKey),0)==1;
 end
 for _,a in ipairs(candidates) do for _,b in ipairs(candidates) do if b~=a then for _,c in ipairs(candidates) do
  if c~=a and c~=b and WasSelected({a,b,c}) then return {a,b,c}; end
  end end end end
 for _,a in ipairs(candidates) do for _,b in ipairs(candidates) do if b~=a and WasSelected({a,b}) then return {a,b}; end end end
 for _,a in ipairs(candidates) do if WasSelected({a}) then return {a}; end end
 return {};
end
local function ApplySelectedSources(id,sources,existingModifiers)
 local p=Players[id]; local own=PlayerConfigurations[id]:GetCivilizationTypeName(); local attached={}; local attachedSet=existingModifiers or {}; local traits={}; local traitSet={}; local savedSources={};
 for mod in string.gmatch(tostring(p:GetProperty("LOTM_RESCUE_THIEF_S2_ABILITIES") or ""),"[^,]+") do if attachedSet[mod] then attached[#attached+1]=mod; end end
 for slot,sid in ipairs(sources or {}) do if slot<=3 then
  local source=Players[tonumber(sid)]; local civ=source~=nil and PlayerConfigurations[source:GetID()]:GetCivilizationTypeName() or nil;
  local abilities=civ~=nil and civ~=own and CivPortableAbilities(civ) or {};
  if #abilities>0 then
   local pick=abilities[StableRand(#abilities,"RESCUE_THIEF_S2_TRAIT:"..id..":"..tostring(sid)..":"..slot)+1];
   if pick~=nil and not traitSet[pick.TraitType] then
    traitSet[pick.TraitType]=true; traits[#traits+1]=pick.TraitType; savedSources[#savedSources+1]=tonumber(sid);
    for _,mod in ipairs(pick.Modifiers) do
     if not attachedSet[mod] then local ok=pcall(function() p:AttachModifierByID(mod); end); if ok then attachedSet[mod]=true; attached[#attached+1]=mod; end end
    end
   end
  end
 end end
 table.sort(attached);
 p:SetProperty("LOTM_RESCUE_THIEF_S2_ABILITIES",table.concat(attached,","));
 p:SetProperty("LOTM_RESCUE_THIEF_S2_TRAITS",table.concat(traits,","));
 p:SetProperty("LOTM_RESCUE_THIEF_S2_SOURCES",table.concat(savedSources,","));
 return #traits,#attached;
end
function LOTM_RESCUE_Thief.CopyThreeAbilities(id,sourcePlayerID)
 if not Active() or not PathPlayer(id) or Seq(id)>2 then return false; end
 local p=Players[id]; if p==nil or N(p:GetProperty(P.Sequence2),0)==2 then return false; end
 local sources={};
 if type(sourcePlayerID)=="table" then
  for _,sid in ipairs(sourcePlayerID) do sources[#sources+1]=sid; end
 elseif sourcePlayerID~=nil then
  sources[1]=sourcePlayerID;
 else
  local pool={}; local own=PlayerConfigurations[id]:GetCivilizationTypeName();
  for _,other in ipairs(PlayerManager.GetAliveMajors() or {}) do
   local sid=other:GetID(); local config=PlayerConfigurations[sid]; local civ=config~=nil and config:GetCivilizationTypeName() or nil;
   if sid~=id and civ~=nil and civ~=own and #CivPortableAbilities(civ)>0 then pool[#pool+1]=sid; end
  end
  table.sort(pool);
  while #pool>0 and #sources<3 do local index=StableRand(#pool,"RESCUE_THIEF_S2_SOURCE:"..id..":"..#sources); sources[#sources+1]=table.remove(pool,index+1); end
 end
 -- Validate every source before attaching anything.  The chooser also uses
 -- this registry, including defeated majors; arbitrary Players slots are not
 -- safe to dereference merely because the native wrapper is non-nil.
 if #sources<1 or #sources>3 then return false; end
 local registered={};
 for _,source in ipairs(PlayerManager.GetWasEverAliveMajors() or {}) do registered[source:GetID()]=true; end
 local seen={}; local own=PlayerConfigurations[id]:GetCivilizationTypeName();
 for index,raw in ipairs(sources) do
  local sid=tonumber(raw);
  if sid==nil or sid~=math.floor(sid) or sid==id or not registered[sid] or seen[sid] then return false; end
  local config=PlayerConfigurations[sid]; local civ=config~=nil and config:GetCivilizationTypeName() or nil;
  if civ==nil or civ==own or #CivPortableAbilities(civ)==0 then return false; end
  seen[sid]=true; sources[index]=sid;
 end
 local abilityCount,modifierCount=ApplySelectedSources(id,sources,{}); if abilityCount<=0 or modifierCount<=0 then return false; end
 p:SetProperty(P.Sequence2,2); p:SetProperty("LOTM_RESCUE_THIEF_S2_MIGRATION_VERSION",2);
 Log("sequence2 copied player="..id.." selectedSources="..#sources.." abilities="..abilityCount.." modifiers="..modifierCount); return true;
end
local function OnSelectAbility(id,params)
 if not PathPlayer(id) or Seq(id)~=2 then return; end
 local sources={}; if params~=nil then for i=1,3 do local sid=params["SourcePlayerID"..i]; if sid~=nil then sources[#sources+1]=sid; end end; if #sources==0 and params.SourcePlayerID~=nil then sources[1]=params.SourcePlayerID; end end
 if #sources>0 and #sources<=3 and LOTM_RESCUE_Thief.CopyThreeAbilities(id,sources) then DigestBorrowedAbilities(id); end
end
local function MigrateLegacyS2Selection(id)
 local p=Players[id]; if p==nil or N(p:GetProperty(P.Sequence2),0)~=2 or N(p:GetProperty("LOTM_RESCUE_THIEF_S2_MIGRATION_VERSION"),0)>=2 then return; end
 local existing=CSVSet(p:GetProperty("LOTM_RESCUE_THIEF_S2_ABILITIES")); local sources=FindLegacySelectedSources(id,p);
 local abilityCount,modifierCount=ApplySelectedSources(id,sources,existing);
 if abilityCount==0 then
  local traits={}; local seen={};
  for link in GameInfo.CivilizationTraits() do if not seen[link.TraitType] then for tm in GameInfo.TraitModifiers() do if tm.TraitType==link.TraitType and existing[tm.ModifierId] then seen[link.TraitType]=true; traits[#traits+1]=link.TraitType; break; end end end end
  table.sort(traits); p:SetProperty("LOTM_RESCUE_THIEF_S2_TRAITS",table.concat(traits,",")); abilityCount=#traits;
 end
 p:SetProperty("LOTM_RESCUE_THIEF_S2_MIGRATION_VERSION",2);
 Log("sequence2 legacy migration player="..id.." recoveredSources="..#sources.." abilities="..abilityCount.." modifiers="..modifierCount);
end

local function ActiveMonsterEntries()
	local entries={}; local csv=tostring(Game.GetProperty("LOTM_WORLD_MONSTER_ACTIVE_SERIALS") or "");
	for token in string.gmatch(csv,"[^,]+") do local serial=N(token,0); if serial>0 and N(Game.GetProperty("LOTM_WORLD_MONSTER:"..serial..":LIVE"),0)==1 then
		local owner=N(Game.GetProperty("LOTM_WORLD_MONSTER:"..serial..":OWNER"),-1); local unitID=N(Game.GetProperty("LOTM_WORLD_MONSTER:"..serial..":UNIT_ID"),-1); local unit=owner>=0 and unitID>=0 and UnitManager.GetUnit(owner,unitID) or nil;
		if unit~=nil and not unit:IsDead() and not unit:IsDelayedDeath() and not IsOuterGod(unit) then entries[#entries+1]={Serial=serial,Unit=unit,Tier=N(Game.GetProperty("LOTM_WORLD_MONSTER:"..serial..":TIER"),2)}; end
	end end
	table.sort(entries,function(a,b) return a.Serial<b.Serial; end); return entries;
end
local function WorkshopEntries()
	local entries={}; local csv=tostring(Game.GetProperty("LOTM_PP_WORKSHOP_REGISTRY_PLOTS") or "");
	for token in string.gmatch(csv,"[^,]+") do local index=N(token,-1); local plot=index>=0 and Map.GetPlotByIndex(index) or nil; if plot~=nil and plot:GetImprovementType()==GameInfo.Improvements.IMPROVEMENT_BARBARIAN_CAMP.Index and N(plot:GetProperty("LOTM_PP_WORKSHOP_IS_WORKSHOP"),0)==1 and N(plot:GetProperty("LOTM_RESCUE_WORKSHOP_AUTO_CLEARED"),0)~=1 then entries[#entries+1]=plot; end end
	table.sort(entries,function(a,b) return a:GetIndex()<b:GetIndex(); end); return entries;
end
local function AutoErrorClear(id)
	if not PathPlayer(id) or Seq(id)~=0 or N(Game.GetProperty("LOTM_RESCUE_THIEF_S0_LAST_TURN"),-1)==Game.GetCurrentGameTurn() then return; end
 local anchor=Sequence0Anchor(); if anchor<0 or id~=anchor then return; end
	local candidates={}; for _,entry in ipairs(ActiveMonsterEntries()) do candidates[#candidates+1]={Kind="MONSTER",Entry=entry,Key=entry.Serial}; end
	for _,plot in ipairs(WorkshopEntries()) do candidates[#candidates+1]={Kind="WORKSHOP",Plot=plot,Key=plot:GetIndex()}; end
	if #candidates==0 then Game.SetProperty("LOTM_RESCUE_THIEF_S0_LAST_TURN",Game.GetCurrentGameTurn()); return; end
	local amount=math.max(1,math.floor(#candidates/5)); local selected={};
	for slot=1,math.min(amount,#candidates) do local pick=StableRand(#candidates,"RESCUE_THIEF_S0:"..Game.GetCurrentGameTurn()..":"..slot); selected[#selected+1]=table.remove(candidates,pick+1); end
	for _,target in ipairs(selected) do
		if target.Kind=="MONSTER" then
			local killer=Players[id]:GetUnits():FindID(N(Players[id]:GetProperty("LOTM_RP_UNIT_ID"),-1));
			if killer~=nil and LOTM_RESCUE_SyncActions~=nil and LOTM_RESCUE_SyncActions.MarkScriptedKiller~=nil then LOTM_RESCUE_SyncActions.MarkScriptedKiller(target.Entry.Unit,killer); end
			if UnitManager.Kill~=nil then pcall(UnitManager.Kill,target.Entry.Unit); end
			Log("sequence0 auto-cleared monster player="..id.." serial="..target.Entry.Serial);
		else
			local plot=target.Plot; local killer=Players[id]:GetUnits():FindID(N(Players[id]:GetProperty("LOTM_RP_UNIT_ID"),-1));
			plot:SetProperty("LOTM_PP_WORKSHOP_LAST_HUMAN",id); plot:SetProperty("LOTM_PP_WORKSHOP_CLEARER_UNIT",killer~=nil and killer:GetID() or -1); plot:SetProperty("LOTM_RESCUE_WORKSHOP_AUTO_CLEARED",1);
			if ImprovementBuilder~=nil and ImprovementBuilder.SetImprovementType~=nil then pcall(ImprovementBuilder.SetImprovementType,plot,-1,-1); end
			Log("sequence0 auto-cleared workshop player="..id.." plot="..plot:GetIndex());
		end
	end
	Game.SetProperty("LOTM_RESCUE_THIEF_S0_LAST_TURN",Game.GetCurrentGameTurn());
end

function LOTM_RESCUE_Thief.OnPathSelected(id)
 if not Active() or not PathPlayer(id) then return false; end
 local p=Players[id]; local total=Global("GLOBAL_PURIFICATION",0); local hadBalance=p:GetProperty(P.Balance)~=nil;
 -- Lifecycle calls this initializer immediately after writing PATH_THIEF and
 -- before EnsureHero.  A legacy save may already contain the +1 per-turn
 -- grant but no global baseline; in that case add the historical purification
 -- total exactly once instead of silently losing it.
 if not hadBalance then SetBalance(p,total); end
 if p:GetProperty(P.LastGlobal)==nil then
  if hadBalance and total>0 then SetBalance(p,Balance(p)+total); end
  p:SetProperty(P.LastGlobal,total);
 end
 if p:GetProperty(P.Version)==nil then p:SetProperty(P.Version,VERSION); end
 Log("rescue thief selected player="..id.." purification="..total.." balance="..Balance(p)); return true;
end

function LOTM_RESCUE_Thief.RefreshSequenceState(id)
 if not Active() or not PathPlayer(id) then return false; end
 ProcessThief(id); RefreshEffects(); return true;
end

function LOTM_RESCUE_Thief.ShouldReflectAttack(attacker,target,attackSerial)
 if not Active() or attacker==nil or target==nil then return false; end
 if LOTM_WORLD_Monsters==nil or LOTM_WORLD_Monsters.IsMonster==nil or not LOTM_WORLD_Monsters.IsMonster(attacker) or IsOuterGod(attacker) then return false; end
 local eligible=false; for _,p in ipairs(PlayerManager.GetAliveMajors() or {}) do if PathPlayer(p:GetID()) and Seq(p:GetID())<=3 then eligible=true; break; end end
 if not eligible then return false; end
 local serial=N(attacker:GetProperty("LOTM_WORLD_MONSTER_SERIAL"),0); local turn=Game.GetCurrentGameTurn(); local label="RESCUE_REFLECT:"..turn..":"..serial..":"..tostring(attackSerial or 0); local reflected=StableRand(100,label)<33;
 if reflected then for _,p in ipairs(PlayerManager.GetAliveMajors() or {}) do if PathPlayer(p:GetID()) and Seq(p:GetID())==3 then AddDigestion(p:GetID(),"A","S3_REFLECT:"..turn..":"..serial..":"..tostring(attackSerial or 0)); end end end
 return reflected;
end

local function OnAllocate(id,params) Allocate(id,tostring(params~=nil and params.Ability or "")); end
local function OnDeallocate(id,params) DeallocateOne(id,tostring(params~=nil and params.Ability or "")); end
local function OnReset(id,params) ResetOne(id,tostring(params~=nil and params.Ability or "")); end
local function OnResetAll(id) ResetAll(id); end
local function OnConvert(id,params) LOTM_RESCUE_Thief.ConvertBarbarianCamp(id,tonumber(params~=nil and params.PlotIndex or -1),tostring(params~=nil and params.Mode or "SELF")); end
local function FindRandomMajorAI(playerID,label)
 local candidates={};
 for _,ai in ipairs(PlayerManager.GetAliveMajors() or {}) do
  if ai:IsAlive() and not ai:IsHuman() and ai:GetID()~=playerID then candidates[#candidates+1]=ai; end
 end
 table.sort(candidates,function(a,b) return a:GetID()<b:GetID(); end);
 if #candidates==0 then return nil; end
 return candidates[StableRand(#candidates,"RESCUE_NEW_CITY_OWNER:"..tostring(Game.GetCurrentGameTurn())..":"..tostring(playerID)..":"..tostring(label or "CITY"))+1];
end
local function OnSetCampGiftAI(id)
 if not PathPlayer(id) then return; end
 local p=Players[id]; local enabled=N(p:GetProperty(P.GiftNewCitiesToAI),0)==1; local nextValue=enabled and 0 or 1;
 p:SetProperty(P.GiftNewCitiesToAI,nextValue);
 Log("new city gift toggle player="..tostring(id).." enabled="..tostring(nextValue==1));
end
local function OnPrepareConvert(id,params)
 if not PathPlayer(id) or Seq(id)>4 then return; end; local plotIndex=tonumber(params~=nil and params.PlotIndex or -1); local plot=Map.GetPlotByIndex(plotIndex); local hero=LOTM_RP_State.FindHero(id);
 if plot==nil or hero==nil or hero:GetX()~=plot:GetX() or hero:GetY()~=plot:GetY() or plot:GetImprovementType()~=GameInfo.Improvements.IMPROVEMENT_BARBARIAN_CAMP.Index then return; end
 if N(Players[id]:GetProperty(P.ConvertTurn),-1)==Game.GetCurrentGameTurn() then return; end
 local p=Players[id]; local mode=N(p:GetProperty(P.GiftNewCitiesToAI),0)==1 and "AI" or "SELF";
 p:SetProperty(P.ConvertPlot,plotIndex); p:SetProperty(P.ConvertActor,hero:GetID()); p:SetProperty(P.ConvertTurn,Game.GetCurrentGameTurn()); p:SetProperty(P.ConvertMode,mode); p:SetProperty(P.ConvertPending,1); Log("camp conversion prepared player="..id.." plot="..plotIndex.." mode="..mode);
end
local function OnFinalizeConvert(id,params)
 local p=Players[id]; if p==nil or N(p:GetProperty(P.ConvertPending),0)~=2 then return; end; local cityID=N(p:GetProperty(P.ConvertCity),-1); local city=cityID>=0 and CityManager.GetCity(id,cityID) or nil; if city==nil then return; end
 local mode=tostring(params~=nil and params.Mode or "SELF"); local ownerOK=true; local finalOwner=id;
 if mode=="AI" then local candidates={}; for _,ai in ipairs(PlayerManager.GetAliveMajors() or {}) do if not ai:IsHuman() and ai:GetID()~=id then candidates[#candidates+1]=ai; end end; table.sort(candidates,function(a,b)return a:GetID()<b:GetID();end); if #candidates==0 then return; end; local target=candidates[StableRand(#candidates,"RESCUE_CAMP_GIFT:"..Game.GetCurrentGameTurn()..":"..cityID)+1]; local ok,result=pcall(CityManager.TransferCity,city,target:GetID()); ownerOK=ok and result~=false; finalOwner=target:GetID(); end
 if ownerOK and Seq(id)==4 then AddDigestion(id,"A","S4_CAMP_CITY:"..Game.GetCurrentGameTurn()..":"..cityID); end; p:SetProperty(P.ConvertPending,0); Log("camp conversion finalized player="..id.." city="..cityID.." mode="..mode.." owner="..finalOwner);
end
local function OnFound(id,params) LOTM_RESCUE_Thief.FoundTimeWormCity(id,tonumber(params~=nil and params.UnitID or -1),tostring(params~=nil and params.Mode or "SELF")); end

local function RememberWormPlot(player,unit)
 if player==nil or unit==nil then return; end
 local info=GameInfo.Units[unit:GetType()];
 if info==nil or info.UnitType~=WORM then return; end
 local plot=Map.GetPlot(unit:GetX(),unit:GetY());
 if plot~=nil then
  player:SetProperty(P.Worm,unit:GetID());
  player:SetProperty(P.WormPlot,plot:GetIndex());
 end
end

local function FindLiveWorm(player)
 if player==nil then return nil; end
 local unitID=N(player:GetProperty(P.Worm),-1);
 local registered=unitID>=0 and player:GetUnits():FindID(unitID) or nil;
 if registered~=nil and not registered:IsDead() and not registered:IsDelayedDeath() then return registered; end
 -- FOUND_CITY can invalidate the registered wrapper before CityBuilt is
 -- published, so fall back to the player's authoritative unit collection.
 for _,candidate in player:GetUnits():Members() do
  local info=GameInfo.Units[candidate:GetType()];
  if info~=nil and info.UnitType==WORM and not candidate:IsDead() and not candidate:IsDelayedDeath() then return candidate; end
 end
 return nil;
end

local function RestoreWormInCity(player,city)
 if player==nil or city==nil then return nil; end
 local row=GameInfo.Units[WORM]; if row==nil or UnitManager.InitUnit==nil then return nil; end
 local live=FindLiveWorm(player);
 if live~=nil and live:GetX()==city:GetX() and live:GetY()==city:GetY() then RememberWormPlot(player,live); return live; end
 if live~=nil and UnitManager.Kill~=nil then pcall(UnitManager.Kill,live,false); end
 local made=UnitManager.InitUnit(player:GetID(),row.Index,city:GetX(),city:GetY());
 if made~=nil then
  RememberWormPlot(player,made);
  if UnitManager.FinishMoves~=nil then UnitManager.FinishMoves(made); end
  Log("time worm restored in founded city player="..player:GetID().." city="..city:GetID().." unit="..made:GetID());
 else
  Log("time worm restore failed in founded city player="..player:GetID().." city="..city:GetID());
 end
 return made;
end

local function ResolvePlayerCity(player,cityID)
 if player==nil then return nil; end
 local cities=player:GetCities();
 if cities~=nil and cities.FindID~=nil then
  local ok,city=pcall(cities.FindID,cities,cityID); if ok and city~=nil then return city; end
 end
 -- Some game builds expose only Members() on the city collection.
 if cities~=nil and cities.Members~=nil then
  for _,city in cities:Members() do if city~=nil and city:GetID()==cityID then return city; end end
 end
 if CityManager~=nil and CityManager.GetCity~=nil then
  local ok,city=pcall(CityManager.GetCity,player:GetID(),cityID); if ok and city~=nil then return city; end
 end
 return nil;
end

local function OnWormMoved(playerID,unitID)
 local player=Players[playerID]; if player==nil or not PathPlayer(playerID) or Seq(playerID)>1 then return; end
 local unit=UnitManager.GetUnit(playerID,unitID); RememberWormPlot(player,unit);
end

local function TransferNewCityToRandomAI(playerID,city,label)
 if city==nil or N(Players[playerID]:GetProperty(P.GiftNewCitiesToAI),0)~=1 then return true,playerID,false; end
 local candidates={};
 for _,ai in ipairs(PlayerManager.GetAliveMajors() or {}) do
  if ai:IsAlive() and not ai:IsHuman() and ai:GetID()~=playerID then candidates[#candidates+1]=ai; end
 end
 table.sort(candidates,function(a,b) return a:GetID()<b:GetID(); end);
 if #candidates==0 then
  Log("new city gift skipped player="..tostring(playerID).." reason=NO_SURVIVING_MAJOR_AI");
  return false,playerID,false;
 end
 local cityID=city.GetID~=nil and city:GetID() or -1;
 local target=candidates[StableRand(#candidates,"RESCUE_NEW_CITY_GIFT:"..Game.GetCurrentGameTurn()..":"..tostring(cityID)..":"..tostring(label or "CITY"))+1];
 local targetID=target:GetID();
 local ok,result=pcall(function() return CityManager.TransferCity(city,targetID); end);
 -- Do not dereference the pre-transfer city or iterate Player:GetCities() here:
 -- the native transfer invalidates that wrapper, and Members() yields numeric
 -- handles on some builds.  Re-resolve through CityManager after the transfer.
 local transferred=ok and result~=false; local owner=-1; local moved=nil;
 if transferred and CityManager.GetCity~=nil then
  local resolveOK,resolved=pcall(CityManager.GetCity,targetID,cityID);
  if resolveOK and resolved~=nil then moved=resolved; owner=resolved.GetOwner~=nil and resolved:GetOwner() or targetID; end
  transferred=moved~=nil and owner==targetID;
 end
 Log("new city gift player="..tostring(playerID).." city="..tostring(cityID).." target="..tostring(targetID).." ok="..tostring(ok).." result="..tostring(result).." owner="..tostring(owner));
 return transferred,transferred and targetID or playerID,true;
end

-- UI operations are not exposed in synchronized Gameplay. Use the same native
-- PlayerCities:Create entry point as Phase 2 and the Firaxis Australia scenario.
local OnCityBuilt;
local creatingAbilityCity={};
local function ClearCampRequest(player)
 player:SetProperty(P.ConvertPending,0); player:SetProperty(P.ConvertTarget,nil);
 player:SetProperty(P.ConvertActor,nil); player:SetProperty(P.ConvertPlot,nil);
 player:SetProperty(P.ConvertTempActor,nil);
end
local function FoundingFailure(player,plot,reason)
 Log("advanced city refused player="..player:GetID().." plot="..tostring(plot and plot:GetIndex() or -1).." reason="..reason);
 if plot~=nil and Game.AddWorldViewText~=nil and Locale~=nil then
  pcall(Game.AddWorldViewText,player:GetID(),Locale.Lookup("LOC_LOTM_RESCUE_FOUND_FAILED",Locale.Lookup("LOC_LOTM_RESCUE_FOUND_REASON_"..reason)),plot:GetX(),plot:GetY());
 end
 return false;
end
local function AreaID(plot)
 if plot.GetArea==nil then return nil; end
 local area=plot:GetArea();
 if type(area)=="number" then return area; end
 return area~=nil and area:GetID() or nil;
end
local function ValidateFoundingPlot(player,plot)
 if plot==nil then return false,"TERRAIN"; end
 if plot:IsCity() or plot:GetDistrictType()>=0 or (plot.GetWonderType~=nil and plot:GetWonderType()>=0) then return false,"OCCUPIED"; end
 if plot:IsWater() or plot:IsImpassable() then return false,"TERRAIN"; end
 local feature=GameInfo.Features[plot:GetFeatureType()];
 if feature~=nil and (feature.Settlement==false or feature.Settlement==0 or feature.NaturalWonder==true or feature.NaturalWonder==1) then return false,"TERRAIN"; end
 local owner=plot:GetOwner(); if owner~=-1 and owner~=player:GetID() then return false,"FOREIGN"; end
 -- Bounded neighborhood only; never enumerate the map or all cities on click.
 local row=GameInfo.GlobalParameters.CITY_MIN_RANGE;
 local radius=math.max(0,math.floor(N(row and row.Value,3)));
 local area=AreaID(plot);
 for dx=-radius,radius do for dy=-radius,radius do
  local other=Map.GetPlotXYWithRangeCheck(plot:GetX(),plot:GetY(),dx,dy,radius);
  if other~=nil and other:IsCity() then
   local distance=Map.GetPlotDistance(plot:GetX(),plot:GetY(),other:GetX(),other:GetY());
   local otherArea=AreaID(other);
   local minimum=(area~=nil and otherArea~=nil and area~=otherArea) and math.max(0,radius-1) or radius;
   if distance<=minimum then return false,"CITY_DISTANCE"; end
  end
 end end
 return true,nil;
end
local function CreateAdvancedCity(player,plot)
 local cities=player:GetCities();
 if cities==nil or cities.Create==nil or CityManager==nil or CityManager.GetCityAt==nil then
  return FoundingFailure(player,plot,"API");
 end
 local id=player:GetID(); local x,y=plot:GetX(),plot:GetY();
 creatingAbilityCity[id]=true;
 local ok,result=pcall(cities.Create,cities,x,y);
 creatingAbilityCity[id]=nil;
 -- Create can return nil despite success. Resolve the authoritative city after
 -- native initialization; do not grant modifiers from a mid-creation callback.
 local city=CityManager.GetCityAt(x,y);
 if city==nil or city:GetOwner()~=id or city:GetX()~=x or city:GetY()~=y then
  Log("advanced city create result player="..id.." callOK="..tostring(ok).." result="..tostring(result));
  return FoundingFailure(player,plot,"CREATE");
 end
 OnCityBuilt(id,city:GetID());
 Log("advanced city verified player="..id.." city="..city:GetID().." plot="..plot:GetIndex().." api=PlayerCities.Create");
 return true;
end

-- These native one-shot city effects are scoped to the confirmed new city.
-- Receipt is written first because attaching a modifier may publish events.
local function GrantAdvancedCity(player,city,source)
 if city==nil or city:GetOwner()~=player:GetID() then return; end
 local receipt="LOTM_RESCUE_ADVANCED_CITY_"..tostring(city:GetID());
 if N(player:GetProperty(receipt),0)==1 then return; end
 player:SetProperty(receipt,1);
 for _,modifier in ipairs({"LOTM_RESCUE_ADVANCED_CITY_POPULATION","LOTM_RESCUE_ADVANCED_CITY_WALLS"}) do
  local ok,result=pcall(function() return city:AttachModifierByID(modifier); end);
  Log("advanced city effect player="..player:GetID().." city="..city:GetID().." source="..source.." modifier="..modifier.." accepted="..tostring(ok and result~=false));
 end
end

function LOTM_RESCUE_Thief.ConvertBarbarianCamp(id,plotIndex,mode)
 Log("parasite city command player="..tostring(id).." plot="..tostring(plotIndex));
 if not Active() or not PathPlayer(id) or Seq(id)>4 then return false; end
 local p=Players[id];
 if N(p:GetProperty(P.ConvertPending),0)~=0 or N(p:GetProperty(P.FoundPending),0)~=0 or N(p:GetProperty(P.ConvertTurn),-1)==Game.GetCurrentGameTurn() then return false; end
 plotIndex=tonumber(plotIndex);
 if plotIndex==nil or plotIndex<0 or plotIndex~=math.floor(plotIndex) then return false; end
 local plot=Map.GetPlotByIndex(plotIndex);
 if plot==nil or plot:IsCity() then return false; end
 local hero=LOTM_RP_State.FindHero~=nil and LOTM_RP_State.FindHero(id) or nil;
 local info=hero~=nil and GameInfo.Units[hero:GetType()] or nil;
 if hero==nil or hero:IsDead() or hero:IsDelayedDeath() or hero:GetOwner()~=id
  or info==nil or info.UnitType~=HERO or hero:GetX()~=plot:GetX() or hero:GetY()~=plot:GetY() then return false; end
 local heroID=hero:GetID();
 local legal,reason=ValidateFoundingPlot(p,plot);
 if not legal then return FoundingFailure(p,plot,reason); end
 p:SetProperty(P.ConvertTarget,id); p:SetProperty(P.ConvertPlot,plotIndex);
 p:SetProperty(P.ConvertActor,heroID); p:SetProperty(P.ConvertMode,"SELF");
 p:SetProperty(P.ConvertPending,1);
 local oldTurn=p:GetProperty(P.ConvertTurn);
 p:SetProperty(P.ConvertTurn,Game.GetCurrentGameTurn());
 if not CreateAdvancedCity(p,plot) then
  ClearCampRequest(p); p:SetProperty(P.ConvertTurn,oldTurn); return false;
 end
 return true;
end

OnCityBuilt=function(playerID,cityID)
 if not Active() or creatingAbilityCity[playerID] then return; end
 for _,p in ipairs(PlayerManager.GetAliveMajors() or {}) do
  if p:IsHuman() and p:GetProperty("LOTM_RP_PATH")==PATH then
    local campPending=N(p:GetProperty(P.ConvertPending),0)==1;
    local campPlot=N(p:GetProperty(P.ConvertPlot),-1);
    local campCity=campPending and playerID==p:GetID() and ResolvePlayerCity(p,cityID) or nil;
    local campLocation=campCity~=nil and Map.GetPlot(campCity:GetX(),campCity:GetY()) or nil;
    local campReceipt="LOTM_RESCUE_CAMP_FOUNDED_CITY_"..tostring(cityID);
    local matchesCampRequest=campLocation~=nil and campLocation:GetIndex()==campPlot;
    local isCampCity=matchesCampRequest or (playerID==p:GetID() and N(p:GetProperty(campReceipt),0)==1);
    if matchesCampRequest then
     p:SetProperty(campReceipt,1);
     local actorID=N(p:GetProperty(P.ConvertActor),-1);
     local actor=actorID>=0 and p:GetUnits():FindID(actorID) or nil;
     local actorInfo=actor~=nil and GameInfo.Units[actor:GetType()] or nil;
     -- Clear the pending flag before Kill publishes any reentrant events.
     ClearCampRequest(p);
     GrantAdvancedCity(p,campCity,"PARASITE");
     if Seq(p:GetID())<=4 and actorInfo~=nil and actorInfo.UnitType==HERO
      and actor:GetOwner()==p:GetID()
      and not actor:IsDead() and not actor:IsDelayedDeath() then
      local killed,result=pcall(UnitManager.Kill,actor);
      if killed and result~=false then
       if LOTM_RP_State.ScheduleRespawn~=nil then LOTM_RP_State.ScheduleRespawn(p:GetID()); end
       if Seq(p:GetID())==4 then AddDigestion(p:GetID(),"A","S4_CAMP_CITY:"..Game.GetCurrentGameTurn()..":"..tostring(cityID)..":"..campPlot); end
       Log("camp conversion committed player="..p:GetID().." city="..cityID.." holder="..actorID.." respawnTurns=5");
      else Log("camp conversion holder removal failed player="..p:GetID().." holder="..actorID); end
     end
    end
    local foundPlot=N(p:GetProperty(P.FoundPlot),-1);
    local builtCity=playerID==p:GetID() and ResolvePlayerCity(p,cityID) or nil;
    local location=builtCity~=nil and Map.GetPlot(builtCity:GetX(),builtCity:GetY()) or nil;
    if not isCampCity and N(p:GetProperty(P.FoundPending),0)==1
     and Seq(p:GetID())<=1 and location~=nil and location:GetIndex()==foundPlot then
     -- Only the requested owner/plot can commit. Clearing first makes duplicate
     -- and reentrant CityBuilt notifications harmless, including after reload.
     p:SetProperty(P.FoundPending,0); p:SetProperty(P.FoundTarget,nil);
     p:SetProperty(P.FoundPlot,nil); p:SetProperty(P.FoundTempActor,nil);
     p:SetProperty(P.WormCooldown,Game.GetCurrentGameTurn()+3);
     GrantAdvancedCity(p,builtCity,"TIME_WORM");
     local worm=p:GetUnits():FindID(N(p:GetProperty(P.Worm),-1));
     if worm~=nil and not worm:IsDead() and UnitManager.FinishMoves~=nil then UnitManager.FinishMoves(worm); end
     if Seq(p:GetID())==1 then AddDigestion(p:GetID(),"A","S1_WORM_CITY:"..Game.GetCurrentGameTurn()..":"..tostring(cityID)); end
     Log("time worm found committed player="..p:GetID().." city="..cityID.." cooldownTurns=3");
    end

  end
 end
end
function LOTM_RESCUE_Thief.FoundTimeWormCity(id,unitID,mode)
 Log("time worm city command player="..tostring(id).." unit="..tostring(unitID));
 if not Active() or not PathPlayer(id) or Seq(id)>1 then return false; end
 local p=Players[id]; unitID=tonumber(unitID);
 if unitID==nil or unitID<0 or unitID~=math.floor(unitID) or N(p:GetProperty(P.FoundPending),0)==1 or N(p:GetProperty(P.ConvertPending),0)~=0 then return false; end
 local worm=p:GetUnits():FindID(unitID); if worm==nil or worm:IsDead() or worm:IsDelayedDeath() then return false; end
 local info=GameInfo.Units[worm:GetType()]; if info==nil or info.UnitType~=WORM then return false; end
 local ready=N(p:GetProperty(P.WormCooldown),-1); if ready>Game.GetCurrentGameTurn() then return false; end
 if worm:GetOwner()~=id then return false; end
 local plot=Map.GetPlot(worm:GetX(),worm:GetY());
 if plot==nil or plot:IsCity() then return false; end
 local legal,reason=ValidateFoundingPlot(p,plot);
 if not legal then return FoundingFailure(p,plot,reason); end
 RememberWormPlot(p,worm);
 p:SetProperty(P.FoundPending,1); p:SetProperty(P.FoundTarget,id);
 p:SetProperty(P.FoundPlot,plot:GetIndex());
 if not CreateAdvancedCity(p,plot) then
  p:SetProperty(P.FoundPending,0); p:SetProperty(P.FoundTarget,nil); p:SetProperty(P.FoundPlot,nil);
  return false;
 end
 return true;
end

local function EnsureWorm(id)
 if not PathPlayer(id) or Seq(id)>1 then return; end
 local p=Players[id]; local row=GameInfo.Units[WORM]; if row==nil then return; end; local unitID=N(p:GetProperty(P.Worm),-1); local unit=unitID>=0 and p:GetUnits():FindID(unitID) or nil; if unit~=nil and not unit:IsDead() then RememberWormPlot(p,unit); return; end
 -- Recovery after loss uses the last owned city location, then the capital.
 -- Recovery is not a founding receipt and must never grant city bonuses.
  local restorePlot=N(p:GetProperty(P.WormPlot),-1); local city=nil;
  if restorePlot>=0 then
   local cities=p:GetCities();
   if cities~=nil and cities.Members~=nil then
    for _,candidate in cities:Members() do
     if candidate~=nil and Map.GetPlot(candidate:GetX(),candidate:GetY())~=nil
       and Map.GetPlot(candidate:GetX(),candidate:GetY()):GetIndex()==restorePlot then city=candidate; break; end
    end
   end
   if city==nil then
    local restoreCity=Map.GetPlotByIndex(restorePlot);
    if restoreCity~=nil and restoreCity:IsCity() and CityManager~=nil and CityManager.GetCityAt~=nil then city=CityManager.GetCityAt(restoreCity:GetX(),restoreCity:GetY()); end
   end
  end
  if city==nil then city=p:GetCities():GetCapitalCity(); end
  if city==nil then return; end
  local made=RestoreWormInCity(p,city);

end

local function ApplyPotionProjectCompleted(playerID,cityID,projectID,eventTurn)
 if not PathPlayer(playerID) then return false; end
 local row=ResolveProjectRow(projectID); local advance=row~=nil and POTIONS[row.ProjectType] or nil;
 if advance==nil then return false; end
 local current=Seq(playerID);
 if current~=advance[1] then
  Log("potion completion rejected player="..playerID.." project="..tostring(row.ProjectType).." sequence="..current.." expected="..advance[1]);
  return false;
 end
 local ok=LOTM_RP_State.AdvanceSequence(playerID,advance[1],advance[2],true);
 if ok then Log("potion completed player="..playerID.." project="..row.ProjectType.." sequence="..advance[1].."->"..advance[2].." turn="..tostring(eventTurn or Game.GetCurrentGameTurn())); end
 return ok;
end

local function OnCityProjectCompleted(playerID,cityID,projectID)
 local row=ResolveProjectRow(projectID);
 if row==nil then Log("project completion observed but project row unresolved player="..tostring(playerID).." city="..tostring(cityID).." project="..tostring(projectID)); return; end
 if not PathPlayer(playerID) or POTIONS[row.ProjectType]==nil then return; end
 Log("project completion observed player="..tostring(playerID).." city="..tostring(cityID).." project="..tostring(row.ProjectType));
 if LOTM_MP_TurnSync~=nil and LOTM_MP_TurnSync.IsNetworkGame~=nil and LOTM_MP_TurnSync.IsNetworkGame() then
  local turn=Game.GetCurrentGameTurn(); local key=table.concat({turn,playerID,cityID,projectID},":");
  if pendingPotionProjectKeys[key]~=nil then return; end
  local entry={QueuedTurn=turn,PlayerID=tonumber(playerID),CityID=tonumber(cityID),ProjectID=tonumber(projectID),Key=key};
  if entry.PlayerID~=nil and entry.CityID~=nil and entry.ProjectID~=nil then pendingPotionProjects[#pendingPotionProjects+1]=entry; pendingPotionProjectKeys[key]=entry; end
 else
  ApplyPotionProjectCompleted(playerID,cityID,projectID,nil);
 end
end

-- The engine's ProjectCompletionModifiers writes this player property at
-- completion, using the same property effect as our native goody-hut marker.
-- UI requests only ask us to read it; they cannot create a completion.
local potionReceiptStatus={};
local function ReceiptStatus(playerID,projectType,status)
 local signature=projectType..":"..status;
 if potionReceiptStatus[playerID]~=signature then
  potionReceiptStatus[playerID]=signature;
  Log("native potion receipt player="..playerID.." project="..projectType.." status="..status.." turn="..Game.GetCurrentGameTurn());
 end
end
function LOTM_RESCUE_Thief.ReconcileCompletedPotion(playerID)
 if not Active() or not PathPlayer(playerID) then return false; end
 local current=Seq(playerID); local projectType=POTION_BY_SEQUENCE[current];
 if projectType==nil then return false; end
 if GameInfo.LOTM_RESCUE_PotionCompletions==nil then ReceiptStatus(playerID,projectType,"MISSING_TABLE"); return false; end
 local receipt=GameInfo.LOTM_RESCUE_PotionCompletions[projectType];
 local row=GameInfo.Projects[projectType];
 if receipt==nil or row==nil then ReceiptStatus(playerID,projectType,"MISSING_ROW"); return false; end
 local player=Players[playerID];
 if (tonumber(player:GetProperty(receipt.PropertyKey) or 0) or 0)<=0 then ReceiptStatus(playerID,projectType,"WAIT_PROJECT_MARKER"); return false; end
 local done=ApplyPotionProjectCompleted(playerID,-1,row.Index,Game.GetCurrentGameTurn());
 ReceiptStatus(playerID,projectType,done and "ADVANCED" or "PROGRESSION_REJECTED");
 if done then Log("native potion receipt consumed player="..playerID.." project="..projectType.." turn="..Game.GetCurrentGameTurn()); end
 return done;
end

local function ProcessPotionProjects(playerID)
 if LOTM_MP_TurnSync==nil or not LOTM_MP_TurnSync.IsNetworkGame() or not LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID) then return; end
 local turn=Game.GetCurrentGameTurn(); local ready={}; local waiting={};
 for _,entry in ipairs(pendingPotionProjects) do if entry.QueuedTurn<turn then ready[#ready+1]=entry; else waiting[#waiting+1]=entry; end end
 pendingPotionProjects=waiting;
 table.sort(ready,function(a,b) if a.QueuedTurn~=b.QueuedTurn then return a.QueuedTurn<b.QueuedTurn; end if a.PlayerID~=b.PlayerID then return a.PlayerID<b.PlayerID; end if a.ProjectID~=b.ProjectID then return a.ProjectID<b.ProjectID; end return a.CityID<b.CityID; end);
 for _,entry in ipairs(ready) do if pendingPotionProjectKeys[entry.Key]==entry then pendingPotionProjectKeys[entry.Key]=nil; end ApplyPotionProjectCompleted(entry.PlayerID,entry.CityID,entry.ProjectID,entry.QueuedTurn); end
end

-- An active project disappearing also means cancellation, queue switching,
-- or loss of its city.  This old breadcrumb cannot prove a completion. Clear
-- it on the next synchronized turn; only actual completion events may award
-- a potion, and a legacy save without such evidence receives no guessed one.
local function RecoverPotionCompletionFromProduction(playerID)
 if not PathPlayer(playerID) then return; end
 local p=Players[playerID];
 if p:GetProperty(P.LastActivePotion)~=nil then
  p:SetProperty(P.LastActivePotion,nil);
  Log("legacy potion breadcrumb cleared player="..tostring(playerID).." reason=NO_COMPLETION_EVIDENCE");
 end
end

local function OnTurn(id,isFirst)
 if not Active() or isFirst==false then return; end
 local network=LOTM_MP_TurnSync~=nil and LOTM_MP_TurnSync.IsNetworkGame~=nil and LOTM_MP_TurnSync.IsNetworkGame();
 if network and id~=Anchor() then return; end
 local turn=Game.GetCurrentGameTurn(); local turnStarted=BeginTurnPerf();
 RunTimedTurnSection(id,turn,"ProcessPotionProjects",function() ProcessPotionProjects(id); end);
 -- In single-player PlayerTurnActivated fires for every major civilization.
 -- The previous implementation rescanned every human pathway and every
 -- barbarian monster on each AI activation.  Process only the active human;
 -- multiplayer keeps its synchronized anchor pass over all human players.
 if network then
  RunTimedTurnSection(id,turn,"GrantEnergyForPurification",function() GrantEnergyForPurification(); end);
  for _,p in ipairs(PlayerManager.GetAliveMajors() or {}) do if p:IsHuman() then
   if N(p:GetProperty(P.ConvertPending),0)==1 and Game.GetCurrentGameTurn()-N(p:GetProperty(P.ConvertTurn),Game.GetCurrentGameTurn())>1 then ClearCampRequest(p); Log("camp conversion request expired player="..p:GetID().." plot="..tostring(p:GetProperty(P.ConvertPlot))); end
   RunTimedTurnSection(p:GetID(),turn,"MigrateLegacyS2Selection",function() MigrateLegacyS2Selection(p:GetID()); end);
   RunTimedTurnSection(p:GetID(),turn,"RecoverPotionCompletionFromProduction",function() RecoverPotionCompletionFromProduction(p:GetID()); end);
   RunTimedTurnSection(p:GetID(),turn,"ReconcileCompletedPotion",function() LOTM_RESCUE_Thief.ReconcileCompletedPotion(p:GetID()); end);
   RunTimedTurnSection(p:GetID(),turn,"ProcessThief",function() ProcessThief(p:GetID()); end);
   RunTimedTurnSection(p:GetID(),turn,"EnsureWorm",function() EnsureWorm(p:GetID()); end);
   RunTimedTurnSection(p:GetID(),turn,"AutoErrorClear",function() AutoErrorClear(p:GetID()); end);
  end end
 else
  local p=Players[id];
  if p==nil or not p:IsHuman() then return; end
  if N(p:GetProperty(P.ConvertPending),0)==1 and Game.GetCurrentGameTurn()-N(p:GetProperty(P.ConvertTurn),Game.GetCurrentGameTurn())>1 then
   Log("camp conversion request expired player="..id.." plot="..tostring(p:GetProperty(P.ConvertPlot)));
   ClearCampRequest(p);
  end
  RunTimedTurnSection(id,turn,"GrantEnergyForPurification",function() GrantEnergyForPurification(); end);
  RunTimedTurnSection(id,turn,"MigrateLegacyS2Selection",function() MigrateLegacyS2Selection(id); end);
  RunTimedTurnSection(id,turn,"RecoverPotionCompletionFromProduction",function() RecoverPotionCompletionFromProduction(id); end);
  RunTimedTurnSection(id,turn,"ReconcileCompletedPotion",function() LOTM_RESCUE_Thief.ReconcileCompletedPotion(id); end);
  RunTimedTurnSection(id,turn,"ProcessThief",function() ProcessThief(id); end);
  RunTimedTurnSection(id,turn,"EnsureWorm",function() EnsureWorm(id); end);
  RunTimedTurnSection(id,turn,"AutoErrorClear",function() AutoErrorClear(id); end);
 end
 RunTimedTurnSection(id,turn,"RefreshEffects",function() RefreshEffects(); end);
 EndTurnPerf(id,turn,turnStarted);
end

if Active() then
 GameEvents.LOTM_RESCUE_Command_AllocatePurificationAbility.Add(OnAllocate);
 GameEvents.LOTM_RESCUE_Command_DeallocatePurificationAbility.Add(OnDeallocate);
 GameEvents.LOTM_RESCUE_Command_ResetPurificationAbility.Add(OnReset);
 GameEvents.LOTM_RESCUE_Command_ResetAllPurificationAbilities.Add(OnResetAll);
 -- Legacy city-gift command intentionally not registered.  Rescue cities are
 -- always founded for the human player; keeping this callback unreachable
 -- prevents old-save/UI state from reopening the removed transfer path.
 GameEvents.LOTM_RESCUE_Command_ConvertBarbarianCamp.Add(OnConvert);
 GameEvents.LOTM_RESCUE_Command_FoundTimeWormCity.Add(OnFound);
 GameEvents.LOTM_RESCUE_Command_SelectAbility.Add(OnSelectAbility);
 Events.CityProjectCompleted.Add(OnCityProjectCompleted);
 GameEvents.CityBuilt.Add(OnCityBuilt);
 GameEvents.OnUnitMoved.Add(OnWormMoved);
 LOTM_MP_TurnSync.Add(OnTurn,"RescueThief");
 LOTM_MP_TurnSync.RunStartup(function() OnTurn(Anchor(),true); end,"RescueThief");
 Log("loaded version="..VERSION.." rescueOnly=true");
end
