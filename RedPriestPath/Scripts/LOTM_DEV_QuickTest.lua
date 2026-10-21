-- Optional synchronized new-game test setup.
-- Production default: disabled.  Change only ENABLED and PROFILE when building
-- a disposable local test package; never publish or use it in multiplayer.

local ENABLED :boolean = false;
local PROFILE :string = "GOLDEN_BRIBE";

local MARKER_PREFIX :string = "LOTM_DEV_QUICK_TEST_APPLIED_";
local BLACK_EMPEROR_PATH :string = "PATH_BLACK_EMPEROR";
local BE_FIRST_CITY_GRANTED :string = "LOTM_BE_FIRST_CITY_REWARD_GRANTED";
local BE_WILDCARD_ATTACHED :string = "LOTM_BE_WILDCARD_SLOT_ATTACHED";
local BE_AUTOMATIC_CIVIC_TURN :string = "LOTM_BE_AUTOMATIC_CIVIC_TURN";
local BE_CIVIC_SCORING_MIGRATED :string = "LOTM_BE_CIVIC_SCORING_V2_MIGRATED";

local function Log(message)
 print("[LOTM_DEV][QuickTest] "..tostring(message));
end

local function Human(playerID)
 local player=Players[playerID];
 return player~=nil and player:IsAlive() and player:IsMajor() and player:IsHuman() and player or nil;
end

local function ResetDigestion(player)
 player:SetProperty("LOTM_RP_DIGEST_A",0); player:SetProperty("LOTM_RP_DIGEST_B",0);
 player:SetProperty("LOTM_RP_DIGEST_TURN",-1); player:SetProperty("LOTM_RP_DIGEST_TURN_GAIN",0);
end

local function PrimeBlackEmperorFoundation(player)
 local playerID=player:GetID(); local culture=player:GetCulture();
 local civic=GameInfo.Civics["CIVIC_CODE_OF_LAWS"];
 if culture==nil or civic==nil then
  Log("waiting for Black Emperor foundation player="..playerID); return false;
 end
 player:SetProperty(BE_AUTOMATIC_CIVIC_TURN,Game.GetCurrentGameTurn());
 if not culture:HasCivic(civic.Index) then
  culture:SetCulturalProgress(civic.Index,culture:GetCultureCost(civic.Index));
  if not culture:HasCivic(civic.Index) then culture:SetCivic(civic.Index,true); end
 end
 if not culture:HasCivic(civic.Index) then
  Log("waiting for Code of Laws player="..playerID); return false;
 end
 LOTM_RP_State.AttachModifierOnce(
  playerID,"LOTM_BE_MOD_RULES_WILDCARD_SLOT",BE_WILDCARD_ATTACHED
 );
 player:SetProperty(BE_FIRST_CITY_GRANTED,1);
 player:SetProperty(BE_CIVIC_SCORING_MIGRATED,1);
 return (player:GetProperty(BE_WILDCARD_ATTACHED) or 0)==1;
end

local function VerifyBlackEmperorState(player,sequence)
 local playerID=player:GetID();
 local valid=LOTM_RP_State.IsBlackEmperorPlayer(playerID)
  and LOTM_RP_State.GetSequence(playerID)==sequence
  and (player:GetProperty(BE_FIRST_CITY_GRANTED) or 0)==1
  and (player:GetProperty(BE_WILDCARD_ATTACHED) or 0)==1;
 if sequence<=8 then
  valid=valid and (player:GetProperty("LOTM_BE_MIGHT_STRENGTH_V2_ATTACHED") or 0)==1
   and (player:GetProperty("LOTM_BE_MIGHT_MOVEMENT_ATTACHED") or 0)==1;
 end
 if sequence<=7 then
  valid=valid and (player:GetProperty("LOTM_BE_TRADE_GOLD_ATTACHED") or 0)==1;
 end
 if sequence<=6 then
  valid=valid and (player:GetProperty("LOTM_BE_WEALTH_ATTACHED") or 0)==1;
 end
 Log("verified player="..playerID.." path="..tostring(player:GetProperty("LOTM_RP_PATH"))
  .." sequence="..tostring(LOTM_RP_State.GetSequence(playerID))
  .." foundation="..tostring(player:GetProperty(BE_FIRST_CITY_GRANTED))
  .." might="..tostring(player:GetProperty("LOTM_BE_MIGHT_STRENGTH_V2_ATTACHED"))
  .." movement="..tostring(player:GetProperty("LOTM_BE_MIGHT_MOVEMENT_ATTACHED"))
  .." trade="..tostring(player:GetProperty("LOTM_BE_TRADE_GOLD_ATTACHED"))
  .." wealth="..tostring(player:GetProperty("LOTM_BE_WEALTH_ATTACHED"))
  .." valid="..tostring(valid));
 return valid;
end

local function ConfigureBlackEmperor(player,sequence)
 local playerID=player:GetID(); local decided=player:GetProperty("LOTM_RP_PATH_DECIDED") or 0;
 local path=player:GetProperty("LOTM_RP_PATH");
 if decided==1 and path~=BLACK_EMPEROR_PATH then
  Log("refused to overwrite existing path player="..playerID.." path="..tostring(path)); return false;
 end
 LOTM_RP_State.EnsurePlayerState(playerID);
 player:SetProperty("LOTM_RP_PATH",BLACK_EMPEROR_PATH); player:SetProperty("LOTM_RP_PATH_DECIDED",1);
 -- Recreate the complete normal foundation before jumping to the requested
 -- sequence.  Doing this after the jump would incorrectly award the initial
 -- Code of Laws digestion to Sequence 6.
 LOTM_RP_State.SetSequence(playerID,9); ResetDigestion(player);
 if not PrimeBlackEmperorFoundation(player) then return false; end
 LOTM_RP_State.SetSequence(playerID,sequence); ResetDigestion(player);
 LOTM_RP_State.EnsureHero(playerID);
 if LOTM_BE_RefreshSequenceState~=nil then LOTM_BE_RefreshSequenceState(playerID);
 elseif LOTM_BE_OnPathSelected~=nil then LOTM_BE_OnPathSelected(playerID); end
 ResetDigestion(player);
 return VerifyBlackEmperorState(player,sequence);
end

local function AddTestGold(player,amount)
 local key="LOTM_DEV_QUICK_TEST_GOLD_"..PROFILE;
 if (player:GetProperty(key) or 0)~=1 then
  player:GetTreasury():ChangeGoldBalance(amount); player:SetProperty(key,1);
 end
end

local function PrimeForeignCityLoyalty(player)
 local best=nil; local bestDistance=nil; local capital=player:GetCities():GetCapitalCity();
 if capital==nil then return false; end
 for _,otherID in ipairs(PlayerManager.GetAliveMajorIDs()) do
  if otherID~=player:GetID() then
   local other=Players[otherID];
   if other~=nil then for _,city in other:GetCities():Members() do
    local distance=Map.GetPlotDistance(capital:GetX(),capital:GetY(),city:GetX(),city:GetY());
    if bestDistance==nil or distance<bestDistance then best=city; bestDistance=distance; end
   end end
  end
 end
 if best==nil then return false; end
 local identity=best:GetCulturalIdentity(); local loyalty=identity~=nil and identity:GetLoyalty() or nil;
 if loyalty~=nil and loyalty>1 then best:ChangeLoyalty(1-loyalty); end
 player:SetProperty("LOTM_DEV_QUICK_TEST_LOYALTY_TARGET_OWNER",best:GetOwner());
 player:SetProperty("LOTM_DEV_QUICK_TEST_LOYALTY_TARGET_CITY",best:GetID());
 Log("primed loyalty target owner="..best:GetOwner().." city="..best:GetID().." distance="..tostring(bestDistance));
 return true;
end

local function ConfigureChurchRecheck(player)
 -- Jump directly to the tier-15 pending state.  The official church turn
 -- reconciler will either select a real high-tier target or schedule +5 turns.
 player:SetProperty("LOTM_CHURCH_NIGHT_ENVOYS",15);
 player:SetProperty("LOTM_CHURCH_NIGHT_ACTIVE_TIER",15);
 player:SetProperty("LOTM_CHURCH_NIGHT_QUEST_6_STATE","COMPLETED_SELF");
 player:SetProperty("LOTM_CHURCH_NIGHT_QUEST_6_REWARD_APPLIED",1);
 player:SetProperty("LOTM_CHURCH_NIGHT_QUEST_10_STATE","COMPLETED_SELF");
 player:SetProperty("LOTM_CHURCH_NIGHT_QUEST_10_REWARD_APPLIED",1);
 player:SetProperty("LOTM_CHURCH_NIGHT_QUEST_15_STATE","PENDING_TARGET");
 player:SetProperty("LOTM_CHURCH_NIGHT_TARGET_KIND",nil);
 player:SetProperty("LOTM_CHURCH_NIGHT_TARGET_ID",nil);
 player:SetProperty("LOTM_CHURCH_NIGHT_NEXT_RECHECK",0);
 return true;
end

local function Configure(playerID)
 if not ENABLED then return; end
 local player=Human(playerID); if player==nil then return; end
 local marker=MARKER_PREFIX..PROFILE; if (player:GetProperty(marker) or 0)==1 then return; end
 local applied=false;
 if PROFILE=="BLACK_EMPEROR_S6_PURCHASE" then
  applied=ConfigureBlackEmperor(player,6); if applied then AddTestGold(player,10000); end
 elseif PROFILE=="BLACK_EMPEROR_S2_LOYALTY" then
  applied=ConfigureBlackEmperor(player,2) and PrimeForeignCityLoyalty(player);
 elseif PROFILE=="GOLDEN_BRIBE" then
  applied=ConfigureBlackEmperor(player,2);
  if applied then
   AddTestGold(player,10000);
   applied=LOTM_PP_QuickTestGrantAndEquip~=nil
    and LOTM_PP_QuickTestGrantAndEquip(playerID,"GREATWORK_LOTM_BE_GOLDEN_BRIBE",1);
  end
 elseif PROFILE=="CHURCH_TIER15_RECHECK" then
  applied=ConfigureChurchRecheck(player);
 else
  Log("unknown profile="..tostring(PROFILE)); return;
 end
 if applied then player:SetProperty(marker,1); Log("applied profile="..PROFILE.." player="..playerID); end
end

local function ConfigureAll()
 if not ENABLED then return; end
 for _,playerID in ipairs(PlayerManager.GetAliveMajorIDs()) do Configure(playerID); end
end

if ENABLED then
 LOTM_MP_TurnSync.Add(function(playerID,isFirstTime) if isFirstTime~=false then Configure(playerID); end end,"DevQuickTest");
 LOTM_MP_TurnSync.RunStartup(ConfigureAll,"DevQuickTest");
 Log("ENABLED profile="..PROFILE.."; local disposable test build only");
end
