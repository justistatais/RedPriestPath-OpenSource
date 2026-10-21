-- Shared effect arithmetic and idempotent unit ability updates.
-- This module owns no events, player selection, Properties or scans. Callers
-- retain their mode gates and invoke mutations only from synchronized Gameplay.
LOTM_Effects = LOTM_Effects or {};
LOTM_Effects.VERSION = 1;

-- Percent is expressed as 50 for 50%, never 0.5. Keep the multiplier first:
-- base * (percent / 100) preserves the existing floating-point rounding used
-- by 10%, 20% and 50% effects. The caller decides whether to aggregate sources
-- before this operation; floor(sum * p) and sum(floor(source * p)) differ.
function LOTM_Effects.PercentFloor(base, percent)
 local positiveBase = math.max(0, tonumber(base) or 0);
 return math.floor(positiveBase * ((tonumber(percent) or 0) / 100));
end

-- A treasury may expose a fractional balance. Cap AFTER rounding the yield
-- share, without rounding the balance, as the existing gold transfer does.
function LOTM_Effects.CappedPercentFloor(base, percent, available)
 return math.min(math.max(0, tonumber(available) or 0),
  LOTM_Effects.PercentFloor(base, percent));
end

-- Only issue a native write when the exact desired count differs. No cached
-- count or Property can substitute for the unit's authoritative ability state.
-- Returns whether a write was requested; callers needing confirmed success
-- must retain their native readback (a native write can silently be refused).
function LOTM_Effects.SetAbilityCount(abilities, abilityType, desired)
 if abilities == nil then return false; end
 local current = abilities:GetAbilityCount(abilityType) or 0;
 if current == desired then return false; end
 abilities:ChangeAbilityCount(abilityType, desired - current);
 return true;
end

-- Tiers are the caller's small, ordered {value, abilityType} definition array.
-- The first matching tier is selected. A nil/unknown value clears the group.
-- An optional database table skips abilities absent in the active game mode.
-- Iteration order is stable, including removal of legacy stacked counts.
function LOTM_Effects.SyncAbilityTiers(abilities, tiers, selectedValue, definitions)
 local selected = nil;
 for _, entry in ipairs(tiers) do
  if entry[1] == selectedValue then selected = entry[2]; break; end
 end
 local changed = 0;
 for _, entry in ipairs(tiers) do
  local abilityType = entry[2];
  if definitions == nil or definitions[abilityType] ~= nil then
   if LOTM_Effects.SetAbilityCount(abilities, abilityType,
    abilityType == selected and 1 or 0) then changed = changed + 1; end
  end
 end
 return selected, changed;
end
