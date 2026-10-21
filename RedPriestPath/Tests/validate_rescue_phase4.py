#!/usr/bin/env python3
"""Static contract checks for Rescue Mode Phase 4 and guardian flags."""

from __future__ import annotations

import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def fail(message: str) -> None:
    print(f"FAIL: {message}")
    raise SystemExit(1)


def main() -> int:
    workshops = (ROOT / "Scripts" / "LOTM_PP_Workshops.lua").read_text(encoding="utf-8")
    flags = (ROOT / "UI" / "LOTM_PP_UnitFlagManager.lua").read_text(encoding="utf-8")
    sql = (ROOT / "Gameplay" / "LOTM_PP_Artifacts.sql").read_text(encoding="utf-8")
    zh_path = ROOT / "Text" / "zh_Hans_CN" / "LOTM_RP_GameplayText.xml"
    en_path = ROOT / "Text" / "en_US" / "LOTM_RP_GameplayText.xml"

    for token in (
        'for _,tier in ipairs({"SAINT","ANGEL"})',
        'local unitType="UNIT_LOTM_RESCUE_"..church.."_"..tier',
        'GUARDIAN_ICONS[info.Index]="ICON_"..unitType',
        "GuardianIcon(unit)",
        "UnitIcon:SetColor(MONSTER_MARK)",
        'unit:GetProperty("LOTM_RESCUE_CENTER_MONSTER")',
        "Events.UnitAddedToMap.Add(RefreshSpecialFlag)",
    ):
        if token not in flags:
            fail(f"six-class guardian flag override lacks {token}")

    for token in (
        'local RESCUE_BONUS={[2]=15,[1]=25,[0]=35}',
        '[2]="LOC_LOTM_WORLD_MONSTER_LOW_NAME"',
        '[1]="LOC_LOTM_WORLD_MONSTER_MID_NAME"',
        '[0]="LOC_LOTM_WORLD_MONSTER_HIGH_NAME"',
        'RESCUE_MONSTER_STRENGTH_ABILITY="ABILITY_LOTM_WORLD_MONSTER_FRENZY_STRENGTH_V2"',
        'RESCUE_MONSTER_UNIT_TYPE="LOTM_RESCUE_CENTER_MONSTER_UNIT_TYPE"',
        'LOTM_WORLD_Barbarians.ResolveMeleeBaseline(barbarianID)',
        'local PHASE4_VERSION=5',
        'ABILITY_LOTM_WORLD_MONSTER_TIER_MID_STRENGTH',
        'ABILITY_LOTM_WORLD_MONSTER_TIER_HIGH_STRENGTH',
        'NumberValue(Game.GetProperty("LOTM_RESCUE_MODE"))==1',
        "baseline+bonus-unitBase",
        "LOTM_RESCUE_PHASE4_STATE",
        "LOTM_RESCUE_PHASE4_VERSION",
        "LOTM_RESCUE_Phase4.OnWorkshopCleared",
        "LOTM_RESCUE_Phase4.OnLostControlKilled",
        "GameEvents.OnCombatOccurred.Add(OnCombat)",
        "UnitManager.FinishMoves(u)",
        "UnitManager.PlaceUnit",
        "local m_barbarianID=nil;",
        "if m_barbarianID==nil or m_barbarianID<0 then",
        "m_barbarianID=-1;",
        "m_barbarianID=p:GetID(); break;",
        "return m_barbarianID;",
        "local WORKSHOP_REGISTRY_VERSION=3;",
        'WORKSHOP_REGISTRY_VERSION_KEY="LOTM_PP_WORKSHOP_REGISTRY_VERSION"',
        'WORKSHOP_REGISTRY_PLOTS_KEY="LOTM_PP_WORKSHOP_REGISTRY_PLOTS"',
        "local m_workshopPlots={};",
        "local m_workshopCoverage={};",
        "local function SaveWorkshopRegistry()",
        "local function RegisterWorkshopPlot(plot)",
        "local function UnregisterWorkshopPlot(plotIndex)",
        "local function BuildWorkshopCoverage()",
        "local function IndexedNearestWorkshop(x,y)",
        "mode=MIGRATION_FULL_SCAN",
        "mode=PERSISTED_INCREMENTAL",
        "fullScan=migrationOnly unitLookup=coverageIndex",
        "classification=stable-v",
        'LOTM_UnitAddedPerf.EndSection("Workshops.InitializePlots"',
        'LOTM_UnitAddedPerf.EndSection("Workshops.InitializeTotal"',
        'LOTM_UnitAddedPerf.EndSection("Workshops.TurnPlots"',
        'LOTM_UnitAddedPerf.EndSection("Workshops.TurnUnits"',
        'LOTM_UnitAddedPerf.EndSection("Workshops.TurnTotal"',
        'LOTM_UnitAddedPerf.ReportSections("firstBarbarianTurn")',
        "LOTM_UnitAddedPerf.SectionEnabled=false",
        'LOTM_UnitAddedPerf.EndSection("Workshops.Lookup.Total"',
        'LOTM_UnitAddedPerf.EndSection("Workshops.Lookup.Legacy"',
        'LOTM_UnitAddedPerf.EndSection("Workshops.Hit.Properties"',
        'LOTM_UnitAddedPerf.EndSection("Workshops.Hit.CreateExtra"',
        'LOTM_UnitAddedPerf.EndSection("Workshops.Hit.MonsterAttempt"',
        'LOTM_UnitAddedPerf.EndSection("Workshops.Hit.Total"',
        'Workshops.Entry.RescueNormalKilled',
        'Workshops.Entry.RescueMonster',
        'Workshops.Entry.RescueFinalBattle',
    ):
        if token not in workshops:
            fail(f"Phase 4 workshop contract lacks {token}")

    # Ordinary mode must retain the three path name tables and the old +10 rule.
    for token in (
        'PP={[2]="LOC_LOTM_PP_ASTRONOMER_NAME"',
        'RP={[2]="LOC_LOTM_RP_WORKSHOP_HARVESTER_NAME"',
        'BE={[2]="LOC_LOTM_BE_WORKSHOP_CHAOS_MENTOR_NAME"',
        "or 10;",
        "RollPath",
        "LOTM_PP_GrantWorkshopReward",
        "TrySpawnFromWorkshop",
        "OnWorkshopResolved",
    ):
        if token not in workshops:
            fail(f"ordinary workshop reuse/regression contract lacks {token}")

    # Preserve the legacy one-instance workshop abilities for old saves and
    # ordinary-mode B+10 guards; rescue center monsters now use Frenzy +30.
    amounts = {
        int(value)
        for value in re.findall(r"WORKSHOP_SEQUENCE_(?:STRENGTH|\d+)_MOD','Amount','(\d+)'", sql)
    }
    baselines = (20, 35, 45, 55, 65, 75, 85)
    expected = {baseline + bonus - 20 for baseline in baselines for bonus in (10, 20, 30)}
    missing = sorted(expected - amounts)
    if missing:
        fail(f"frozen workshop ability amounts missing {missing}")

    tags = {
        "LOC_LOTM_WORLD_MONSTER_LOW_NAME",
        "LOC_LOTM_WORLD_MONSTER_MID_NAME",
        "LOC_LOTM_WORLD_MONSTER_HIGH_NAME",
    }
    for path in (zh_path, en_path):
        root = ET.parse(path).getroot()
        present = {row.attrib.get("Tag") for row in root.findall(".//Row")}
        if not tags <= present:
            fail(f"{path.name} lacks center-monster names")

    barbarian_resolver = workshops.split("local function BarbarianID()", 1)[1].split("local function IsWorkshopPlot", 1)[0]
    if workshops.count("PlayerManager.GetAliveBarbarians()") != 1:
        fail("Workshops must resolve the fixed barbarian player exactly once in the cached resolver")
    # OnUnitAdded is now a deliberately empty adapter.  Inspect the complete
    # implementation helper so the gate cannot pass/fail on the wrapper alone.
    process_unit_added = workshops.split("local function ProcessUnitAdded", 1)[1].split("local function ProcessNetworkLocalUnitAdditions", 1)[0]
    if "PlayerManager.GetAliveBarbarians()" in process_unit_added or "playerID~=BarbarianID()" not in process_unit_added:
        fail("UnitAdded must compare the cached barbarian ID without enumerating alive barbarians")
    if "Game.SetProperty" in barbarian_resolver or "Player:SetProperty" in barbarian_resolver:
        fail("session-local barbarian ID cache must not publish synchronized state")

    initialize_registry = workshops.split("local function InitializeWorkshopRegistry()", 1)[1].split("local function CreateExtra", 1)[0]
    on_turn = workshops.split("local function OnTurn", 1)[1].split("local function Initialize()", 1)[0]
    indexed_lookup = workshops.split("local function IndexedNearestWorkshop", 1)[1].split("local function InitializeWorkshopRegistry", 1)[0]
    if workshops.count("Map.GetPlotCount()") != 1 or "version~=WORKSHOP_REGISTRY_VERSION" not in initialize_registry:
        fail("full-map workshop discovery must exist only behind the one-time registry version gate")
    if "Map.GetPlotCount()" in on_turn or "for _,plotIndex in ipairs(m_workshopPlots)" not in on_turn:
        fail("barbarian turns must maintain only the persistent workshop registry, never scan the whole map")
    if "IndexedNearestWorkshop" not in process_unit_added or "Map.GetPlotXYWithRangeCheck" in process_unit_added:
        fail("UnitAdded must use the coverage index instead of repeating radius map queries")
    if "if #candidates==1" not in indexed_lookup or "local camp=NearestWorkshop(x,y);" not in indexed_lookup:
        fail("coverage overlaps must preserve the exact legacy NearestWorkshop ordering fallback")
    if "RegisterWorkshopPlot(plot)" not in workshops.split("local function Classify", 1)[1].split("local function NearestWorkshop", 1)[0]:
        fail("workshop classification must incrementally register the plot")
    if "UnregisterWorkshopPlot(p:GetIndex())" not in workshops.split("local function OnRemoved", 1)[1].split("local function Dead", 1)[0]:
        fail("workshop removal must incrementally unregister the plot")

    classify = workshops.split("local function Classify", 1)[1].split("local function NearestWorkshop", 1)[0]
    if "StableClassificationRoll" not in classify or "Game.GetRandNum" in classify:
        fail("workshop classification must use the order-independent stable roll, never synchronized RNG")
    if "Game.GetRandNum" in workshops:
        fail("workshop event callbacks must not advance the global synchronized RNG stream")

    expected_section_occurrences = {
        "Workshops.InitializePlots": 1, "Workshops.InitializeTotal": 1,
        "Workshops.TurnPlots": 1, "Workshops.TurnUnits": 1, "Workshops.TurnTotal": 1,
        "Workshops.Lookup.Total": 1, "Workshops.Lookup.Legacy": 1,
        "Workshops.Hit.Properties": 1, "Workshops.Hit.CreateExtra": 1,
        "Workshops.Hit.MonsterAttempt": 1,
        # One completion path kills a duplicate sequence unit; the other handles a normal hit.
        # Sequence-kill, network-queue and unchanged single-player settlement
        # each close the same high-resolution probe exactly once.
        "Workshops.Hit.Total": 3,
    }
    for section, expected_count in expected_section_occurrences.items():
        if workshops.count(section) != expected_count:
            fail(f"high-resolution workshop probe must record {section} {expected_count} time(s) in source")

    # Phase 5/6 are explicitly outside this delivery.
    for forbidden in ("GLOBAL_PURIFICATION", "OnPeriodChanged", "WORKSHOP_PERIOD_BONUS"):
        if forbidden in workshops:
            fail(f"Phase 5/6 leaked into Phase 4: {forbidden}")

    print("PASS: Rescue Phase 4 static contract (six flags, frozen center monsters, tier bonuses +15/+25/+35, hooks, isolation)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
