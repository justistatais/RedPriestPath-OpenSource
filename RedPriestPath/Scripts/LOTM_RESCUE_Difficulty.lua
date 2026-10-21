-- Redemption-mode difficulty authority. UI submits one synchronized choice;
-- Gameplay owns the immutable global state and all numeric scaling.
LOTM_RESCUE_Difficulty=LOTM_RESCUE_Difficulty or {};

local VERSION=3;
local COMMAND="LOTM_RESCUE_Command_SelectDifficulty";
local DEFAULT_CHOICE="MADNESS";
local PLAYER_CHOICE_PROPERTY="LOTM_RESCUE_DIFFICULTY_SAVED_CHOICE";
local CHOICES={
 NORMAL={SpawnPercent=50,CapPercent=50,AICombatCap=10},
 HARD={SpawnPercent=70,CapPercent=70,AICombatCap=12},
 MADNESS={SpawnPercent=100,CapPercent=100,AICombatCap=15}
};
local DIRECT_SPAWN={NORMAL=2,HARD=4,MADNESS=6};

local function Log(message) print("[LOTM_RESCUE][Difficulty] "..tostring(message)); end
local function Active() return tonumber(Game.GetProperty("LOTM_RESCUE_MODE") or 0)==1; end

local function HumanChooserID()
 local ids={};
 for _,player in ipairs(PlayerManager.GetAliveMajors()) do
  if player:IsHuman() and player:GetCities():GetCount()>0 then ids[#ids+1]=player:GetID(); end
 end
 table.sort(ids); return ids[1] or -1;
end

local function Property(key)
 local value=Game.GetProperty(key); return value;
end

local function ValidChoice(value)
 local choice=value~=nil and tostring(value) or "";
 return CHOICES[choice]~=nil and choice or nil;
end

local function InferNumericChoice()
 local spawn=tonumber(Property("LOTM_RESCUE_DIFFICULTY_SPAWN_PERCENT"));
 local cap=tonumber(Property("LOTM_RESCUE_DIFFICULTY_CAP_PERCENT"));
 local ai=tonumber(Property("LOTM_RESCUE_DIFFICULTY_AI_COMBAT_CAP"));
 for _,choice in ipairs({"NORMAL","HARD","MADNESS"}) do
  local data=CHOICES[choice];
  if spawn==data.SpawnPercent and cap==data.CapPercent and ai==data.AICombatCap then return choice; end
 end
 return nil;
end

local function SavedPlayerChoice()
 local chooser=tonumber(Property("LOTM_RESCUE_DIFFICULTY_CHOOSER")) or HumanChooserID();
 local player=chooser>=0 and Players[chooser] or nil;
 local choice=ValidChoice(player~=nil and player:GetProperty(PLAYER_CHOICE_PROPERTY) or nil);
 if choice~=nil then return choice,chooser; end
 chooser=HumanChooserID(); player=chooser>=0 and Players[chooser] or nil;
 return ValidChoice(player~=nil and player:GetProperty(PLAYER_CHOICE_PROPERTY) or nil),chooser;
end

local function ResolveChoice()
 local choice=ValidChoice(Property("LOTM_RESCUE_DIFFICULTY"));
 if choice~=nil then return choice,"GAME_CHOICE"; end
 choice=ValidChoice(Property("LOTM_RESCUE_DIFFICULTY_PERSISTED_CHOICE"));
 if choice~=nil then return choice,"GAME_PERSISTED"; end
 local chooser=-1; choice,chooser=SavedPlayerChoice();
 if choice~=nil then return choice,"PLAYER_PERSISTED:"..tostring(chooser); end
 choice=InferNumericChoice();
 if choice~=nil then return choice,"NUMERIC_SNAPSHOT"; end
 return DEFAULT_CHOICE,"SAFE_DEFAULT";
end

local function ChoiceData()
 local choice=ResolveChoice();
 return choice,CHOICES[choice] or CHOICES[DEFAULT_CHOICE];
end

function LOTM_RESCUE_Difficulty.Choice() local choice=ChoiceData(); return choice; end
function LOTM_RESCUE_Difficulty.SpawnPercent() local _,data=ChoiceData(); return data.SpawnPercent; end
function LOTM_RESCUE_Difficulty.CapPercent() local _,data=ChoiceData(); return data.CapPercent; end
function LOTM_RESCUE_Difficulty.AICombatCap() local _,data=ChoiceData(); return data.AICombatCap; end
function LOTM_RESCUE_Difficulty.DirectSpawnBase()
 local choice=ChoiceData(); return DIRECT_SPAWN[choice] or DIRECT_SPAWN[DEFAULT_CHOICE];
end
function LOTM_RESCUE_Difficulty.Scale(base,percent)
 return math.max(1,math.floor((tonumber(base) or 0)*(tonumber(percent) or 100)/100));
end

local function Publish(choice,data,chooser)
 Game.SetProperty("LOTM_RESCUE_DIFFICULTY",choice);
 Game.SetProperty("LOTM_RESCUE_DIFFICULTY_PERSISTED_CHOICE",choice);
 Game.SetProperty("LOTM_RESCUE_DIFFICULTY_DECIDED",1);
 Game.SetProperty("LOTM_RESCUE_DIFFICULTY_CHOOSER",chooser);
 Game.SetProperty("LOTM_RESCUE_DIFFICULTY_SPAWN_PERCENT",data.SpawnPercent);
 Game.SetProperty("LOTM_RESCUE_DIFFICULTY_CAP_PERCENT",data.CapPercent);
 Game.SetProperty("LOTM_RESCUE_DIFFICULTY_AI_COMBAT_CAP",data.AICombatCap);
 Game.SetProperty("LOTM_RESCUE_DIFFICULTY_DIRECT_SPAWN_BASE",DIRECT_SPAWN[choice]);
 Game.SetProperty("LOTM_RESCUE_DIFFICULTY_VERSION",VERSION);
 local player=chooser~=nil and chooser>=0 and Players[chooser] or nil;
 if player~=nil and player:IsHuman() then player:SetProperty(PLAYER_CHOICE_PROPERTY,choice); end
end

function LOTM_RESCUE_Difficulty.RestorePersistentChoice()
 if not Active() then return false; end
 local choice,source=ResolveChoice(); local data=CHOICES[choice];
 local decided=tonumber(Property("LOTM_RESCUE_DIFFICULTY_DECIDED") or 0)==1;
 local chooser=tonumber(Property("LOTM_RESCUE_DIFFICULTY_CHOOSER")) or HumanChooserID();
 -- Older builds wrote NORMAL/HARD and their numeric snapshots before the
 -- DECIDED marker was introduced.  Recover those explicit non-default
 -- choices instead of silently replacing them with the MADNESS default.
 local rawChoice=ValidChoice(Property("LOTM_RESCUE_DIFFICULTY"));
 local persistedChoice=ValidChoice(Property("LOTM_RESCUE_DIFFICULTY_PERSISTED_CHOICE"));
 local playerChoice,playerChooser=SavedPlayerChoice();
 local numericChoice=InferNumericChoice();
 local recoveredChoice=persistedChoice or playerChoice
  or ((rawChoice~=nil and rawChoice~=DEFAULT_CHOICE) and rawChoice or nil)
  or ((numericChoice~=nil and numericChoice~=DEFAULT_CHOICE) and numericChoice or nil);
 if decided or recoveredChoice~=nil then
  if not decided and recoveredChoice~=nil then
   choice=recoveredChoice; data=CHOICES[choice];
   if playerChoice~=nil and playerChooser>=0 then chooser=playerChooser; end
   Log("recovered legacy explicit choice="..choice.." source="..source);
  end
  Publish(choice,data,chooser);
  Log("restored choice="..choice.." source="..source.." chooser="..tostring(chooser)
   .." spawnPercent="..data.SpawnPercent.." capPercent="..data.CapPercent
   .." directSpawnBase="..DIRECT_SPAWN[choice].." aiCombatCap="..data.AICombatCap);
 else
  -- Before the chooser confirms a difficulty, publish only the safe runtime
  -- default.  Keeping DECIDED unset preserves the choice popup.
  Game.SetProperty("LOTM_RESCUE_DIFFICULTY",DEFAULT_CHOICE);
  Game.SetProperty("LOTM_RESCUE_DIFFICULTY_SPAWN_PERCENT",CHOICES[DEFAULT_CHOICE].SpawnPercent);
  Game.SetProperty("LOTM_RESCUE_DIFFICULTY_CAP_PERCENT",CHOICES[DEFAULT_CHOICE].CapPercent);
  Game.SetProperty("LOTM_RESCUE_DIFFICULTY_AI_COMBAT_CAP",CHOICES[DEFAULT_CHOICE].AICombatCap);
  Game.SetProperty("LOTM_RESCUE_DIFFICULTY_DIRECT_SPAWN_BASE",DIRECT_SPAWN[DEFAULT_CHOICE]);
  Game.SetProperty("LOTM_RESCUE_DIFFICULTY_VERSION",VERSION);
  Log("initialized undecided safeDefault="..DEFAULT_CHOICE.." chooser="..tostring(chooser));
 end
 return true;
end

local function OnSelect(playerID,parameters)
 local choice=parameters~=nil and tostring(parameters.Choice or "") or "";
 local data=CHOICES[choice]; local player=Players[playerID]; local chooser=HumanChooserID();
 if not Active() or data==nil or player==nil or not player:IsHuman() or not player:IsAlive()
  or not player:IsMajor() or player:GetCities():GetCount()<1 or playerID~=chooser then
  Log("rejected player="..tostring(playerID).." choice="..choice.." chooser="..chooser); return;
 end
 if tonumber(Game.GetProperty("LOTM_RESCUE_DIFFICULTY_DECIDED") or 0)==1 then
  Log("rejected duplicate player="..playerID.." choice="..choice); return;
 end
 Publish(choice,data,playerID);
 Log("selected player="..playerID.." choice="..choice.." spawnPercent="..data.SpawnPercent.." capPercent="..data.CapPercent.." directSpawnBase="..DIRECT_SPAWN[choice].." aiCombatCap="..data.AICombatCap);
 if LOTM_RESCUE_Phase9~=nil and LOTM_RESCUE_Phase9.ReconcileAll~=nil then LOTM_RESCUE_Phase9.ReconcileAll(); end
end

-- The script loads before the path choice can activate Redemption mode, so the
-- synchronized command must always be registered. OnSelect remains the runtime
-- gate and rejects every request outside an active Redemption game.
GameEvents.LOTM_RESCUE_Command_SelectDifficulty.Add(OnSelect);
LOTM_MP_TurnSync.RunStartup(function() LOTM_RESCUE_Difficulty.RestorePersistentChoice(); end,"RescueDifficulty");
Log("loaded version="..VERSION.." active="..tostring(Active()).." choices=NORMAL:50/50/10/direct2,HARD:70/70/12/direct4,MADNESS:100/100/15/direct6 defaultUntilSelected=MADNESS persistence=game+player+numeric chooser=lowestHumanWithCity");
