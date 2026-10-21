-- Cosmetic state only. Native GDR-style AttachmentVisibility reads promotions.
-- All writes occur on synchronized Gameplay events; never recreate a hero.
local VERSION = 1;
local RECEIPT = "LOTM_PLAYER_MODEL_TIER_V1";
local ALLOWED = {
 UNIT_LOTM_RP_PATH_HOLDER = true, UNIT_LOTM_PP_PATH_HOLDER = true,
 UNIT_LOTM_BE_PATH_HOLDER = true, UNIT_LOTM_TP_PATH_HOLDER = true
};
local m_failure = {};

local function Tier(value)
 local n = tonumber(value);
 if n == nil or n ~= math.floor(n) or n < 0 or n > 9 then return nil; end
 if n == 0 then return 3; elseif n <= 2 then return 2; elseif n <= 4 then return 1; end
 return 0;
end

local function Apply(playerID, unitID)
 local player = Players[playerID];
 if player == nil or unitID == nil then return; end
 local sequence = player:GetProperty("LOTM_RP_SEQUENCE");
 local tier = Tier(sequence);
 if tier == nil then return; end
 local unit = player:GetUnits():FindID(unitID);
 if unit == nil or unit:GetOwner() ~= playerID then return; end
 local row = GameInfo.Units[unit:GetType()];
 if row == nil or not ALLOWED[row.UnitType] then return; end
 local xp = unit:GetExperience();
 if xp == nil then return; end
 local promos = {};
 for i = 1, 3 do
  local promotion = GameInfo.UnitPromotions["PROMOTION_LPM_TIER_"..i];
  if promotion == nil then return; end
  promos[i] = promotion.Index;
 end
 -- Three cumulative visual markers: a normal ascent only adds one marker.
 -- Boolean false also reconciles a reset/downgrade without touching gameplay promotions.
 for i = 1, 3 do
  local wanted = i <= tier;
  if xp:HasPromotion(promos[i]) ~= wanted then xp:SetPromotion(promos[i], wanted); end
 end
 for i = 1, 3 do
  if xp:HasPromotion(promos[i]) ~= (i <= tier) then
   error("native promotion state did not match requested tier "..tier);
  end
 end
 if unit:GetProperty(RECEIPT) ~= tier then
  unit:SetProperty(RECEIPT, tier);
  print("[LOTM][PlayerModels] player="..playerID.." unit="..unitID.." tier="..tier.." version="..VERSION);
 end
end

local function SafeApply(playerID, unitID)
 local ok, reason = pcall(Apply, playerID, unitID);
 if not ok then
  local key = tostring(playerID)..":"..tostring(unitID);
  if m_failure[key] ~= tostring(reason) then
   m_failure[key] = tostring(reason);
   print("[LOTM][PlayerModels] pending "..key.." reason="..tostring(reason));
  end
 end
end

local function OnTurn(playerID)
 local player = Players[playerID];
 if player == nil then return; end
 -- Existing authoritative hero identity gives an O(1) lookup, including old saves.
 local unitID = player:GetProperty("LOTM_RP_UNIT_ID");
 SafeApply(playerID, unitID);
end

if GameEvents ~= nil then
 if GameEvents.PlayerTurnStarted ~= nil then GameEvents.PlayerTurnStarted.Add(OnTurn); end
 if GameEvents.UnitInitialized ~= nil then GameEvents.UnitInitialized.Add(SafeApply); end
end
print("[LOTM][PlayerModels] loaded version="..VERSION.." route=synchronizedGameplay");
