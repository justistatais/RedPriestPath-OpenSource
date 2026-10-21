-- Phase 01 multiplayer command probe.
-- This handler deliberately performs no Gameplay mutation.

local LOTM_RP_PROBE_EVENT :string = "LOTM_RP_Command_Probe";

local function FormatParameters(parameters :table)
	if parameters == nil then
		return "<nil>";
	end

	local keys :table = {};
	for key, _ in pairs(parameters) do
		table.insert(keys, key);
	end

	table.sort(keys, function(left, right)
		return tostring(left) < tostring(right);
	end);

	local fields :table = {};
	for _, key in ipairs(keys) do
		table.insert(fields, tostring(key) .. "=" .. tostring(parameters[key]));
	end

	return table.concat(fields, ",");
end

local function OnCommandProbe(ownerID :number, unitID :number, parameters :table)
	print(
		"[LOTM_RP][Probe] owner=" .. tostring(ownerID)
		.. " unit=" .. tostring(unitID)
		.. " parameters={" .. FormatParameters(parameters) .. "}"
	);
	return true;
end

local function Initialize()
	GameEvents.LOTM_RP_Command_Probe.Add(OnCommandProbe);
	print("[LOTM_RP][Probe] Gameplay handler registered for " .. LOTM_RP_PROBE_EVENT);
end

Initialize();
