-- Normal-mode AI self-bonuses. The host's game option is committed once to
-- synchronized saved state, before the legacy cult startup assigns any AI.
LOTM_AI_Cult_Difficulty = LOTM_AI_Cult_Difficulty or {};
local KEY="LOTM_CULT_DIFFICULTY";
local prefixCache={};
local militaryPending={};
local registered=false;
local VALUES={
 HARD={science={20,40,60},economy={30,60,90},combat={2,4,6},maintenance={10,20,30},
  food={10,20,30},amenities={1,2,3},heal={3,5,8},territory={2,3,4}},
 INSANE={science={40,80,120},economy={60,120,180},combat={4,7,10},maintenance={20,35,50},
  food={20,40,60},amenities={2,3,4},heal={5,8,12},territory={3,5,7}}
};
local function Number(value,default) return tonumber(value) or default; end
local function Log(message) print("[LOTM_CDIFF] "..tostring(message)); end
local function RescueActive()
 return LOTM_MP_TurnSync.IsRescueModeConfigured()
  or Number(Game.GetProperty("LOTM_RESCUE_MODE"),0)==1;
end
local function Normalize(value)
 return (value=="HARD" or value=="INSANE") and value or "EASY";
end
function LOTM_AI_Cult_Difficulty.Get() return Normalize(Game.GetProperty(KEY)); end
function LOTM_AI_Cult_Difficulty.Initialize()
 if RescueActive() then return; end
 if Game.GetProperty(KEY)~=nil then return; end
 -- A preexisting cult ledger identifies old saves even when a new front-end
 -- default or room configuration is present. Never reset assignments/tiers.
 local legacy=Game.GetProperty("LOTM_CULT_STATE_VERSION")~=nil
  or Game.GetProperty("LOTM_CULT_ASSIGNMENTS_INITIALIZED")~=nil;
 local configured=GameConfiguration.GetValue(KEY);
 local difficulty=legacy and "EASY" or Normalize(configured);
 Game.SetProperty(KEY,difficulty);
 Game.SetProperty("LOTM_CULT_DIFFICULTY_SOURCE",legacy and "LEGACY_SAVE" or "GAME_CONFIG");
 Game.SetProperty("LOTM_CULT_DIFFICULTY_VERSION",1);
 Log("locked="..difficulty.." source="..(legacy and "LEGACY_SAVE" or "GAME_CONFIG"));
end
local function IsCultAI(player)
 if player==nil or not player:IsAlive() or not player:IsMajor() or player:IsHuman() then return false; end
 local path=player:GetProperty("LOTM_CULT_PATH");
 return path=="DEMONESS" or path=="HANGED_MAN" or path=="CHAINED";
end
local function PrefixIds(prefix)
 if prefixCache[prefix]~=nil then return prefixCache[prefix]; end
 local result={};
 for row in GameInfo.Modifiers() do
  if string.sub(row.ModifierId,1,#prefix)==prefix then result[#result+1]=row.ModifierId; end
 end
 table.sort(result); prefixCache[prefix]=result; return result;
end
local function Attach(player,token,direction)
 local ids=PrefixIds("LOTM_CDIFF_"..token.."_"..direction.."__");
 assert(#ids>0,"missing cult difficulty SQL token "..token.." "..direction);
 for _,id in ipairs(ids) do player:AttachModifierByID(id); end
end
local function Eligibility(player,token,desired)
 local row=GameInfo.Resources["RESOURCE_LOTM_CDIFF_"..token];
 assert(row~=nil,"missing cult difficulty eligibility resource "..token);
 local resources=player:GetResources();
 local amount=Number(resources:GetResourceAmount(row.Index),0);
 if amount~=desired then resources:ChangeResourceAmount(row.Index,desired-amount); end
end
local function EnsureMilitary(player,slot,token)
 if slot~="COMMON" and slot~="CHAINED" then return; end
 -- A distinct receipt and native ID leave serialized rc390 effects alone.
 -- The owner gate uses the same current stage resource as economy: when
 -- that stage is retired, this parent and its non-permanent children expire.
 local receipt="LOTM_CDIFF_MILITARY_V2_ATTACHED_"..token;
 if Number(player:GetProperty(receipt),0)==1 then return; end
 local ids=PrefixIds("LOTM_CDIFF_MILITARY_V2_"..token.."_ON__");
 if #ids~=1 then
  if not militaryPending[token] then
   Log("military pending token="..token.." reason=MISSING_NATIVE_V2 count="..#ids);
   militaryPending[token]=true;
  end
  return;
 end
 player:AttachModifierByID(ids[1]);
 player:SetProperty(receipt,1);
 Log("military v2 player="..player:GetID().." token="..token.." modifier="..ids[1]);
end
local function Switch(player,slot,desired)
 local key="LOTM_CDIFF_APPLIED_"..slot;
 local old=player:GetProperty(key) or "NONE"; desired=desired or "NONE";
 if old~="NONE" and old~=desired then Eligibility(player,old,0); end
 if desired~="NONE" then
  local receipt="LOTM_CDIFF_ATTACHED_"..desired;
  if Number(player:GetProperty(receipt),0)~=1 then
   Attach(player,desired,"ON"); player:SetProperty(receipt,1);
  end
  Eligibility(player,desired,1);
  EnsureMilitary(player,slot,desired);
 end
 if old==desired then return; end
 player:SetProperty(key,desired);
 Log("player="..player:GetID().." slot="..slot.." old="..old.." new="..desired);
end
function LOTM_AI_Cult_Difficulty.Reconcile()
 if RescueActive() then return; end
 LOTM_AI_Cult_Difficulty.Initialize();
 local difficulty=LOTM_AI_Cult_Difficulty.Get();
 local majors={};
 for _,player in ipairs(PlayerManager.GetAliveMajors()) do majors[#majors+1]=player; end
 table.sort(majors,function(a,b) return a:GetID()<b:GetID(); end);
 for _,player in ipairs(majors) do
  local valid=IsCultAI(player) and VALUES[difficulty]~=nil;
  local path=player:GetProperty("LOTM_CULT_PATH");
  local tier=valid and LOTM_AI_Cults.GetTier(path) or 1;
  tier=math.max(1,math.min(3,Number(tier,1)));
  local token=valid and (difficulty.."_T"..tier) or nil;
  Switch(player,"COMMON",token and ("COMMON_"..token));
  Switch(player,"DEMONESS",token and path=="DEMONESS" and ("DEMONESS_"..token) or nil);
  Switch(player,"CHAINED",token and path=="CHAINED" and ("CHAINED_"..token) or nil);
 end
end
local function Military(unit)
 local row=GameInfo.Units[unit:GetType()];
 return row~=nil and (Number(row.Combat,0)>0 or Number(row.RangedCombat,0)>0
  or Number(row.Bombard,0)>0);
end
local function SettleMaintenance(player,percent,turn)
 local key="LOTM_CDIFF_MAINTENANCE_TURN";
 if Number(player:GetProperty(key),-1)==turn then return; end
 local treasury=player:GetTreasury();
 -- Firaxis' unit-maintenance modifier is a flat Gold discount per unit.
 -- Refund the specified percentage of actual net unit upkeep instead: no
 -- building/WMD upkeep, no refund on zero/negative costs, no yield multiplier.
 if treasury==nil or type(treasury.GetUnitMaintenance)~="function" then
  Log("maintenance pending player="..player:GetID().." reason=NO_NATIVE_GET_UNIT_MAINTENANCE"); return;
 end
 local cost=Number(treasury:GetUnitMaintenance(),0);
 cost=math.max(0,cost);
 local refund=math.min(cost,cost*math.max(0,math.min(50,percent))/100);
 if refund>0 then treasury:ChangeGoldBalance(refund); end
 player:SetProperty(key,turn);
 player:SetProperty("LOTM_CDIFF_MAINTENANCE_BASE",cost);
 player:SetProperty("LOTM_CDIFF_MAINTENANCE_REFUND",refund);
 Log("maintenance player="..player:GetID().." turn="..turn.." base="..cost.." percent="..percent.." refund="..refund);
end
local function HealUnits(player,amount,turn)
 local units={}; for _,unit in player:GetUnits():Members() do units[#units+1]=unit; end
 table.sort(units,function(a,b) return a:GetID()<b:GetID(); end);
 for _,unit in ipairs(units) do
  if Military(unit) and not unit:IsDead() and not unit:IsDelayedDeath()
   and Number(unit:GetProperty("LOTM_CDIFF_HEAL_TURN"),-1)~=turn then
   local damage=math.max(0,Number(unit:GetDamage(),0));
   local heal=math.min(damage,amount);
   if heal>0 then unit:ChangeDamage(-heal); end
   unit:SetProperty("LOTM_CDIFF_HEAL_TURN",turn);
  end
 end
end
local function OnTurn(playerID,isFirstTimeThisTurn)
 if isFirstTimeThisTurn==false or RescueActive() then return; end
 LOTM_AI_Cult_Difficulty.Reconcile();
 local player=Players[playerID];
 local values=VALUES[LOTM_AI_Cult_Difficulty.Get()];
 if values==nil or not IsCultAI(player) then return; end
 local tier=math.max(1,math.min(3,Number(LOTM_AI_Cults.GetTier(player:GetProperty("LOTM_CULT_PATH")),1)));
 local turn=Game.GetCurrentGameTurn();
 SettleMaintenance(player,values.maintenance[tier],turn);
 if player:GetProperty("LOTM_CULT_PATH")=="HANGED_MAN" then HealUnits(player,values.heal[tier],turn); end
end
function LOTM_AI_Cult_Difficulty.Register()
 if registered or RescueActive() then return; end
 registered=true;
 LOTM_MP_TurnSync.Add(OnTurn,"AICultDifficulty");
 LOTM_MP_TurnSync.RunStartup(LOTM_AI_Cult_Difficulty.Reconcile,"AICultDifficulty");
end
LOTM_MP_TurnSync.RunStartup(LOTM_AI_Cult_Difficulty.Initialize,"AICultDifficultyLock");
