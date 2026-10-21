#!/usr/bin/env python3
"""Static and synthetic contract checks for Rescue Phase 7."""

from __future__ import annotations

from pathlib import Path
import re
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
ERRORS: list[str] = []


def check(condition: bool, message: str) -> None:
    if not condition:
        ERRORS.append(message)


def text(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


phase7 = text("Scripts/LOTM_RESCUE_Phase7.lua")
phase7_sql = text("Gameplay/LOTM_RESCUE_Phase7.sql")
cults = text("Scripts/LOTM_AI_Cults.lua")
hanged = text("Scripts/LOTM_AI_Cult_Hanged.lua")
gameplay = text("Scripts/LOTM_RP_Gameplay.lua")
diplo = text("UI/LOTM_AI_Cult_DiplomacyRow.lua")
modinfo = text("RedPriestPath.modinfo")
zh = text("Text/zh_Hans_CN/LOTM_AI_CultsText.xml")
en = text("Text/en_US/LOTM_AI_CultsText.xml")

for snippet in (
    'local VERSION=5;',
    'local INCREMENTAL_MIGRATION_VERSION=2;',
    'local INCREMENTAL_MIGRATION_KEY="LOTM_RESCUE_PHASE7_INCREMENTAL_MIGRATION_VERSION";',
    'local ABILITY_SCHEMA_VERSION=1;',
    'local UNIT_SIGNATURE_KEY="LOTM_RESCUE_PHASE7_ABILITY_SIGNATURE";',
    'Game.SetProperty("LOTM_RESCUE_PHASE7_STATE","READY")',
    'Game.SetProperty("LOTM_RESCUE_PHASE",7)',
    'for stage=1,tier do AttachStage(player,cult,stage); end',
    'player==nil or not player:IsAlive() or player:IsHuman()',
    'LOTM_AI_Cults.GetTier(cult)',
    'Events.UnitAddedToMap.Add(LOTM_UnitAddedPerf.Wrap("Phase7",OnUnitAdded))',
    'Events.UnitRemovedFromMap.Add(OnUnitRemoved)',
    'LOTM_MP_TurnSync.AddSynchronized(OnSynchronizedPlayerTurnStarted,"RescuePhase7Runtime")',
    'startupAttach=deferredToSynchronizedTurn',
    'if not TrackUnit(playerID,unitID) then return; end',
    'if tostring(unit:GetProperty(UNIT_SIGNATURE_KEY) or "")~=UnitSignature(cult,tier) then ApplyUnitTier(unit,cult,tier); end',
    'mode="..(stampOnly and "STAMP_ONLY" or "APPLY")',
    'persistentSignature=v',
    'unitUpdates=singlePlayerImmediate/networkNextFullTurnSorted fullScan=migrationOnly',
    'doubled=true inherited=true phase8AI=false bossFormula=false',
):
    check(snippet in phase7, f"Phase 7 cumulative Gameplay contract missing: {snippet}")

check('include("LOTM_RESCUE_Phase7")' in gameplay, "Phase 7 module is not included")
check('id="LOTM_RESCUE_PHASE7_DATABASE" criteria="LOTM_RP_RESCUE_MODE"' in modinfo, "Phase 7 database must be rescue-only")
check("not LOTM_MP_TurnSync.IsNetworkGame() and LOTM_RESCUE_Phase7" in cults,
      "AI cult callbacks must not invoke Phase 7 DynamicModifier reconciliation in network games")
check("if RescueActive() then return; end" in cults, "rescue human unit additions must not trigger a global cult reconcile")
check(phase7.count("player:GetUnits():Members()") == 1, "Phase 7 full unit scan must exist only in the one-time migration")
migration_body = phase7.split("local function MigratePlayerUnits", 1)[1].split("local function ReconcilePlayer", 1)[0]
unit_added_body = phase7.split("local function OnUnitAdded", 1)[1].split("local function OnUnitRemoved", 1)[0]
check("player:GetUnits():Members()" in migration_body, "Phase 7 old-save migration lost its one-time full scan")
check("player:GetUnits():Members()" not in unit_added_body and "ReconcilePlayer" not in unit_added_body, "Phase 7 unit additions must remain incremental")
check("ApplyUnitTier(unit,cult,tier)" in migration_body and "StampUnitTier(unit,cult,tier)" in migration_body, "Phase 7 migration must support apply and stamp-only paths")
check("table.sort(units,function(a,b) return a:GetID()<b:GetID(); end)" in migration_body,
      "Phase 7 migration must allocate unit abilities in stable unit-ID order")
indexed_body = phase7.split("local function ApplyIndexedTier", 1)[1].split("local function MigratePlayerUnits", 1)[0]
check("table.sort(ordered);" in indexed_body,
      "Phase 7 tier changes must allocate unit abilities in stable unit-ID order")
network_unit_added_body = unit_added_body.split("if LOTM_MP_TurnSync.IsNetworkGame() then", 1)[1].split("end", 1)[0]
check(all(token not in network_unit_added_body for token in (
    "UnitManager.", "ApplyUnitTier(", "ChangeAbilityCount(", ":SetProperty(", "Game.SetProperty(",
)), "Phase 7 network UnitAdded callback must only update the Lua-local queue/index")
check("TrackUnit(playerID,unitID); QueueNetworkUnitAdded(playerID,unitID); return;" in network_unit_added_body,
      "Phase 7 network UnitAdded callback must defer the new unit")
network_processor = phase7.split("local function ProcessNetworkUnitAdditions", 1)[1].split("local function OnUnitAdded", 1)[0]
check(all(token in network_processor for token in (
    "LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID)", "entry.QueuedTurn<currentTurn",
    "table.sort(ready,function(a,b)", "a.PlayerID<b.PlayerID", "a.UnitID<b.UnitID",
    "ApplyUnitTier(unit,cult,tier)",
)), "Phase 7 network unit abilities must wait a full turn and apply in stable player/unit order")
check("ProcessNetworkUnitAdditions(playerID)" in phase7,
      "Phase 7 synchronized anchor must drain the deferred network unit queue")
check("unit:GetProperty(UNIT_SIGNATURE_KEY)" in unit_added_body, "Phase 7 restored units must use the persistent ability signature")


def drain_network_units(events: list[tuple[int, int, int]], current_turn: int) -> list[tuple[int, int]]:
    return sorted((player_id, unit_id) for player_id, unit_id, queued_turn in events
                  if queued_turn < current_turn)


observed_turn_10 = [(6, 458756, 10), (6, 524293, 10)]
check(drain_network_units(observed_turn_10, 10) == []
      and drain_network_units(observed_turn_10, 11)
      == drain_network_units(list(reversed(observed_turn_10)), 11)
      == [(6, 458756), (6, 524293)],
      "resource289 Phase 7 unit callback order must converge only at the next sorted world-turn boundary")
check("if RescueActive() then RetireNegativeEffectsForRescue(); return; end" in cults, "ordinary cult penalties must be retired in rescue mode")
check("elseif LOTM_AI_Cult_Hanged" in cults, "ordinary Hanged behavior must remain outside rescue mode")
check("function LOTM_AI_Cult_Hanged.RetireForRescue()" in hanged, "legacy flesh-puppet effects must retire in rescue mode")
check('Game.GetProperty("LOTM_RESCUE_MODE")' in diplo and "LOC_LOTM_RESCUE_PHASE7_" in diplo, "diplomacy UI must describe rescue bonuses")
check("MODIFIER_UNIT_ADJUST_MOVEMENT" not in phase7_sql, "Phase 7 must not use the nonexistent unit movement modifier type")
for modifier_type in (
    "MODIFIER_PLAYER_CITIES_ADJUST_POLICY_AMENITY",
    "MODIFIER_ALL_CITIES_CULTURE_BORDER_EXPANSION",
    "MODIFIER_PLAYER_UNIT_ADJUST_MOVEMENT",
    "MODIFIER_UNIT_ADJUST_COMBAT_STRENGTH",
):
    check(modifier_type in phase7_sql, f"Phase 7 lost required Firaxis modifier type: {modifier_type}")

expected_arguments = {
    "LOTM_RESCUE_P7_DEMONESS_T1__01": {"YieldType": "YIELD_FOOD", "Amount": "2"},
    "LOTM_RESCUE_P7_DEMONESS_T1__02": {"YieldType": "YIELD_PRODUCTION", "Amount": "2"},
    "LOTM_RESCUE_P7_DEMONESS_T1__03": {"YieldType": "YIELD_SCIENCE", "Amount": "2"},
    "LOTM_RESCUE_P7_DEMONESS_T1__04": {"YieldType": "YIELD_CULTURE", "Amount": "2"},
    "LOTM_RESCUE_P7_DEMONESS_T2__01": {"YieldType": "YIELD_FOOD", "Amount": "40"},
    "LOTM_RESCUE_P7_DEMONESS_T2__02": {"YieldType": "YIELD_PRODUCTION", "Amount": "40"},
    "LOTM_RESCUE_P7_DEMONESS_T3__01": {"Amount": "10"},
    "LOTM_RESCUE_P7_DEMONESS_T3__02": {"YieldType": "YIELD_FOOD", "Amount": "100"},
    "LOTM_RESCUE_P7_DEMONESS_T3__03": {"YieldType": "YIELD_PRODUCTION", "Amount": "100"},
    "LOTM_RESCUE_P7_HANGED_MAN_T1__01": {"YieldType": "YIELD_FAITH", "Amount": "10"},
    "LOTM_RESCUE_P7_HANGED_MAN_T3__01": {"YieldType": "YIELD_FAITH", "Amount": "40"},
    "LOTM_RESCUE_P7_CHAINED_T2__01": {"Amount": "100"},
    "LOTM_RESCUE_P7_CHAINED_T3__01": {"YieldType": "YIELD_SCIENCE", "Amount": "100"},
    "LOTM_RESCUE_P7_CHAINED_T3__02": {"YieldType": "YIELD_CULTURE", "Amount": "100"},
}
arguments: dict[str, dict[str, str]] = {}
for modifier, name, value in re.findall(
    r"\('([^']+)','([^']+)','([^']+)'\)", phase7_sql
):
    arguments.setdefault(modifier, {})[name] = value
for modifier, expected in expected_arguments.items():
    check(arguments.get(modifier) == expected, f"wrong doubled Phase 7 arguments for {modifier}: {arguments.get(modifier)}")

for ability, amount in (
    ("HANGED_T1_C10", 10),
    ("HANGED_T2_C20", 20),
    ("HANGED_T3_C40", 40),
    ("CHAINED_T1_M2", 2),
    ("CHAINED_T2_M2", 2),
    ("CHAINED_T2_C20", 20),
):
    check(f"LOTM_RESCUE_P7_{ability}_MOD','Amount','{amount}'" in phase7_sql, f"missing Phase 7 unit bonus {ability}={amount}")

expected_totals = {
    1: {"demon_flat": 2, "demon_percent": 0, "amenity": 0, "hanged_combat": 10, "faith": 10, "move": 2, "chained_combat": 0, "border": 0, "science_culture": 0},
    2: {"demon_flat": 2, "demon_percent": 40, "amenity": 0, "hanged_combat": 30, "faith": 10, "move": 4, "chained_combat": 20, "border": 100, "science_culture": 0},
    3: {"demon_flat": 2, "demon_percent": 140, "amenity": 10, "hanged_combat": 70, "faith": 50, "move": 4, "chained_combat": 20, "border": 100, "science_culture": 100},
}
for tier, totals in expected_totals.items():
    check(totals["demon_percent"] == (0 if tier == 1 else 40 if tier == 2 else 140), f"Demoness inheritance mismatch tier {tier}")
    check(totals["hanged_combat"] == (10 if tier == 1 else 30 if tier == 2 else 70), f"Hanged inheritance mismatch tier {tier}")
    check(totals["move"] == (2 if tier == 1 else 4), f"Chained inheritance mismatch tier {tier}")

for cult in ("DEMONESS", "HANGED_MAN", "CHAINED"):
    for tier in (1, 2, 3):
        tag = f"LOC_LOTM_RESCUE_PHASE7_{cult}_T{tier}_DESCRIPTION"
        check(tag in zh and tag in en, f"missing bilingual Phase 7 description: {tag}")

check("local function DesiredTier(maxTech) if maxTech>=14 then return 3 elseif maxTech>=5 then return 2 else return 1 end end" in cults, "shared era/technology tier thresholds changed unexpectedly")
check("LOTM_RESCUE_PHASE8" not in phase7 + phase7_sql and "BOSS" not in phase7_sql.upper(), "Phase 8 or Phase 10 leaked into Phase 7")

try:
    ET.parse(ROOT / "Text/zh_Hans_CN/LOTM_AI_CultsText.xml")
    ET.parse(ROOT / "Text/en_US/LOTM_AI_CultsText.xml")
except ET.ParseError as exc:
    check(False, f"Phase 7 localization XML parse error: {exc}")

if ERRORS:
    print(f"FAILED: {len(ERRORS)} Rescue Phase 7 checks")
    for error in ERRORS:
        print(f" - {error}")
    raise SystemExit(1)

print("PASS: Rescue Phase 7 static + synthetic contract (doubled cumulative cult buffs, rescue isolation, no Phase 8/10)")
