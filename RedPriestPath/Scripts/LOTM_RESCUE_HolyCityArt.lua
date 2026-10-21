-- Cosmetic city selectors. Only synchronized Gameplay events create buildings.
-- This independent add-in leaves the frozen Phase2 and city bootstrap code intact.
local VERSION = 2;
local ZONES = { "FOOL", "NIGHT", "STORM", "CENTER" };
-- V2 adds the existing registered Astral Descent city; retain the old receipt.
local RECEIPT = "LOTM_RESCUE_HOLY_CITY_ART_IDENTITY_V2";
local m_lastFailure = {};

local function Active()
 return GameInfo ~= nil and GameInfo.Buildings ~= nil
  and GameInfo.Buildings["BUILDING_LOTM_RESCUE_HOLY_CITY_FOOL"] ~= nil
  and tonumber(Game.GetProperty("LOTM_RESCUE_MODE") or 0) == 1;
end

local function Number(value)
 local n = tonumber(value);
 if n == nil or n < 0 or n ~= math.floor(n) then return nil; end
 return n;
end

local function LogFailure(zone, reason)
 if m_lastFailure[zone] ~= reason then
  print("[LOTM_RESCUE][HolyCityArt] pending zone="..zone.." reason="..reason);
  m_lastFailure[zone] = reason;
 end
end

local function Apply(zone, owner, cityID, plotID)
 local plot = Map.GetPlotByIndex(plotID);
 if plot == nil then return false, "PLOT_MISSING"; end
 local city = CityManager.GetCityAt(plot:GetX(), plot:GetY());
 if city == nil or city:GetOwner() ~= owner or city:GetID() ~= cityID then
  return false, "REGISTERED_CITY_MISMATCH";
 end
 local row = GameInfo.Buildings["BUILDING_LOTM_RESCUE_HOLY_CITY_"..zone];
 if row == nil then return false, "BUILDING_TYPE_MISSING"; end
 local buildings = city:GetBuildings();
 if buildings == nil then return false, "BUILDINGS_UNAVAILABLE"; end
 if buildings:HasBuilding(row.Index) then return true; end
 local queue = city:GetBuildQueue();
 if queue == nil then return false, "QUEUE_UNAVAILABLE"; end
 queue:CreateBuilding(row.Index);
 if not buildings:HasBuilding(row.Index) then return false, "CREATE_NOT_CONFIRMED"; end
 print("[LOTM_RESCUE][HolyCityArt] installed version="..VERSION.." zone="..zone
  .." owner="..owner.." city="..cityID.." plot="..plotID);
 return true;
end

local function Reconcile()
 if not Active() or Game.GetProperty("LOTM_RESCUE_PHASE2A_STATE") ~= "READY" then return; end
 local owner = Number(Game.GetProperty("LOTM_RESCUE_TEST_PLAYER_ID"));
 if owner == nil or owner ~= PlayerManager.GetFreeCitiesPlayerID() then return; end
 local identities = {};
 local parts = { tostring(VERSION), tostring(owner) };
 for _, zone in ipairs(ZONES) do
  -- Native GetProperty may return no Lua values: preserve a normal local argument.
  local idValue = Game.GetProperty("LOTM_RESCUE_"..zone.."_CITY_ID");
  local plotValue = Game.GetProperty("LOTM_RESCUE_"..zone.."_CITY_PLOT");
  local id, plot = Number(idValue), Number(plotValue);
  if id == nil or plot == nil then return; end
  identities[zone] = { id, plot };
  parts[#parts + 1] = zone..":"..id..":"..plot;
 end
 local key = table.concat(parts, "|");
 -- Constant-size identity check; no city/map scans and no repeated native changes.
 if Game.GetProperty(RECEIPT) == key then return; end
 local complete = true;
 for _, zone in ipairs(ZONES) do
  local identity = identities[zone];
  local ok, applied, reason = pcall(Apply, zone, owner, identity[1], identity[2]);
  if not ok or not applied then
   complete = false;
   LogFailure(zone, ok and tostring(reason) or "NATIVE_CALL_ERROR");
  else
   m_lastFailure[zone] = nil;
  end
 end
 if complete then
  Game.SetProperty(RECEIPT, key);
  print("[LOTM_RESCUE][HolyCityArt] READY version="..VERSION.." identity="..key);
 end
end

-- Both are synchronized Gameplay anchors already used by the current mod.
-- Bootstrap may run before Phase2 in another context; the turn hook retries safely.
if GameEvents ~= nil then
 if GameEvents.PlayerTurnStarted ~= nil then GameEvents.PlayerTurnStarted.Add(Reconcile); end
 if GameEvents.LOTM_RESCUE_Command_BootstrapCity ~= nil then
  GameEvents.LOTM_RESCUE_Command_BootstrapCity.Add(Reconcile);
 end
end
print("[LOTM_RESCUE][HolyCityArt] loaded version="..VERSION.." writeRoute=synchronizedGameplay");
