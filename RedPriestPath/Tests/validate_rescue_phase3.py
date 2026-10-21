#!/usr/bin/env python3
"""Static contract checks for Rescue Mode Phase 3."""

from __future__ import annotations

import sys
import struct
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CHURCHES = ("FOOL", "NIGHT", "STORM")
TIERS = ("SAINT", "ANGEL")
ICON_SIZES = (22, 30, 32, 38, 50, 70, 80, 95, 200, 256)


def fail(message: str) -> None:
    raise AssertionError(message)


def action_for(root: ET.Element, tag: str, action_id: str) -> ET.Element:
    for action in root.findall(f"./InGameActions/{tag}"):
        if action.get("id") == action_id:
            return action
    fail(f"missing {tag} action {action_id}")


def dxt5_alpha(path: Path, x: int, y: int) -> int:
    data = path.read_bytes()
    if data[:4] != b"DDS " or data[84:88] != b"DXT5":
        fail(f"guardian icon is not classic DXT5 DDS: {path.name}")
    width, height = struct.unpack_from("<II", data, 12)
    blocks_w = (width + 3) // 4
    offset = 128 + ((y // 4) * blocks_w + (x // 4)) * 16
    alpha0, alpha1 = data[offset], data[offset + 1]
    codes = [alpha0, alpha1]
    if alpha0 > alpha1:
        codes.extend(((7 - i) * alpha0 + i * alpha1) // 7 for i in range(1, 7))
    else:
        codes.extend(((5 - i) * alpha0 + i * alpha1) // 5 for i in range(1, 5))
        codes.extend((0, 255))
    indices = int.from_bytes(data[offset + 2:offset + 8], "little")
    pixel = (y % 4) * 4 + (x % 4)
    return codes[(indices >> (pixel * 3)) & 0x7]


def main() -> int:
    database_path = ROOT / "Gameplay" / "LOTM_RESCUE_Phase3.xml"
    script_path = ROOT / "Scripts" / "LOTM_RESCUE_Phase3.lua"
    zh_text_path = ROOT / "Text" / "zh_Hans_CN" / "LOTM_RP_GameplayText.xml"
    en_text_path = ROOT / "Text" / "en_US" / "LOTM_RP_GameplayText.xml"
    artdef_path = ROOT / "Art" / "LOTM_RESCUE_Phase3_Units.artdef"
    dep_path = ROOT / "Art" / "LOTM_RESCUE_Phase3.dep"
    icons_path = ROOT / "Art" / "LOTM_RESCUE_Phase3_Icons.xml"
    icon_builder_path = ROOT / "Tests" / "build_rescue_guardian_icons.py"
    modinfo_path = ROOT / "RedPriestPath.modinfo"
    for path in (database_path, script_path, zh_text_path, en_text_path, artdef_path, dep_path, icons_path, icon_builder_path, modinfo_path):
        if not path.is_file():
            fail(f"missing file: {path}")
        ET.parse(path) if path.suffix.lower() in {".xml", ".artdef", ".dep", ".modinfo"} else None

    database = ET.parse(database_path).getroot()
    units = {row.get("UnitType"): row for row in database.findall("./Units/Row")}
    expected = {f"UNIT_LOTM_RESCUE_{church}_{tier}" for church in CHURCHES for tier in TIERS}
    if set(units) != expected:
        fail(f"six explicit unit types required, got {sorted(units)}")
    for unit_type, row in units.items():
        tier = unit_type.rsplit("_", 1)[1]
        wanted = {"Combat": "90", "BaseMoves": "3", "BaseSightRange": "3"} if tier == "SAINT" else {"Combat": "130", "BaseMoves": "4", "BaseSightRange": "4"}
        for key, value in wanted.items():
            if row.get(key) != value:
                fail(f"{unit_type} {key} must be {value}")
        for key, value in {"CanTrain": "false", "CanCapture": "false", "CanEarnExperience": "false"}.items():
            if row.get(key) != value:
                fail(f"{unit_type} {key} must be {value}")
    tags = {(row.get("Type"), row.get("Tag")) for row in database.findall("./TypeTags/Row")}
    for unit_type in expected:
        if (unit_type, "CLASS_LOTM_RESCUE_GUARDIAN") not in tags:
            fail(f"guardian tag missing for {unit_type}")
        if (unit_type, "CLASS_MELEE") in tags:
            fail(f"generic melee abilities would alter fixed stats for {unit_type}")
    ability_modifiers = {(row.get("UnitAbilityType"), row.get("ModifierId")) for row in database.findall("./UnitAbilityModifiers/Row")}
    if ("ABILITY_LOTM_RESCUE_GUARDIAN_NON_AGGRESSION", "CANNOT_ATTACK") not in ability_modifiers:
        fail("retired CANNOT_ATTACK ability must remain available for old-save migration")
    if ("ABILITY_LOTM_RESCUE_GUARDIAN_NON_AGGRESSION", "CLASS_LOTM_RESCUE_GUARDIAN") in tags:
        fail("new guardians must not receive the retired CANNOT_ATTACK ability")

    script = script_path.read_text(encoding="utf-8")
    required_script = (
        "local CAPS={SAINT=3,ANGEL=1}", "local REINFORCEMENT_INTERVAL=10",
        "LAST_REINFORCEMENT_KEY", "RunReinforcementCheck(turn)", "EnsureOpeningSaints",
        'Spawn(playerID,church,"SAINT",turn,CAPS.SAINT,live)', "ReinforcementTier", "UnitManager.InitUnit",
        "Units.GetUnitsInPlot", "NO_LEGAL_EMPTY_PLOT", "DEATH_REPLACEMENT",
        "Events.UnitRemovedFromMap.Add(OnRemoved)", "UnitManager.FinishMoves",
        'Game.GetProperty("LOTM_RESCUE_PHASE2A_STATE")~="READY"',
        "local CONTENT_VERSION=12", "RetireLegacyProtocol", "RetireSurplus", "MigrationCaps", "migrationAngelCap=", "balance migration retired=", "TargetEntries",
        "PlayerManager.GetAliveBarbarians", "IsLostControl", "local onCamp=camp~=nil",
        "BARBARIAN_CAMP", "distance<=6", "distance<=10", "GetContinentType",
        'return 3,distance', "BestTarget", 'include("LOTM_RESCUE_SyncActions")',
        "LOTM_RESCUE_SyncActions.MoveToward(unit,target.Plot,moves,false,true)", "LOTM_RESCUE_SyncActions.ScriptedKill",
        'LOTM_RESCUE_SyncActions==nil', '"HELPER_UNAVAILABLE"',
        "UnitManager.FinishMoves(unit)",
        'unit:GetProperty("LOTM_RESCUE_PHASE10_IS_GOD")',
        "GuideGuardians(player)", "cleanupGuidance=gameplay_sync_move_lost_control_first_no_camps",
        'unit:SetProperty("LOTM_RESCUE_GLOBAL_CLEANUP_TARGET",1)',
        'unit:SetProperty("LOTM_RESCUE_GUARDIAN_TARGET_X"',
        'unit:SetProperty("LOTM_RESCUE_GUARDIAN_TARGET_Y"',
        "if center:GetOwner()==ownerID then Add(center,1,true); end", "fallbackRadius=6", "scope=", "legalCandidates=",
    )
    missing = [token for token in required_script if token not in script]
    if missing:
        fail(f"script contract tokens missing: {missing}")
    forbidden_script = ("Boss", "BOSS", "净化", "purification", "UnitManager.RequestOperation", "UnitManager.CanStartOperation", "CityManager.TransferCity")
    present = [token for token in forbidden_script if token in script]
    if present:
        fail(f"future-phase implementation leaked into Phase 3: {present}")
    if "(FOOL|NIGHT|STORM)" in script or "(SAINT|ANGEL)" in script:
        fail("Lua patterns do not support alternation")
    for obsolete in ("TARGETS=", "DESCENT_TURN=", "PeriodForTurn", "period=", "descent="):
        if obsolete in script:
            fail(f"superseded period target remains in script: {obsolete}")
    if "FreezeGuardians" in script:
        fail("retired guardian freeze loop must not return")
    if "MoveTowardNative(unit,target.Plot)" in script:
        fail("guardians must not return to the Gameplay-unavailable UnitOperation MOVE_TO path")
    for forbidden in ("ImprovementBuilder.SetImprovementType", 'Kind="WORKSHOP"', 'Kind="BARBARIAN_CAMP"', 'plot:SetProperty("LOTM_RESCUE_GLOBAL_CLEANUP_TARGET"'):
        if forbidden in script:
            fail(f"guardians must not target or clear camps: {forbidden}")

    helper = (ROOT / "Scripts" / "LOTM_RESCUE_SyncActions.lua").read_text(encoding="utf-8")
    for token in (
        "local VERSION=9", "local REDEPLOY_RADIUS=12", "local function RedeployOpen",
        "distance>=1", "forceRedeployDistance", '"ASSAULT_REDEPLOY_RING_"', '"REDEPLOY_RING_"', 'or "NO_REDEPLOY_PLOT"',
        "if a.Distance~=b.Distance", "a.Plot:GetIndex()<b.Plot:GetIndex()",
        "function LOTM_RESCUE_SyncActions.MoveTowardNative", "UnitManager.CanStartOperation",
        "UnitManager.RequestOperation", "UnitOperationTypes.MOVE_TO", "UnitOperationTypes.PARAM_X",
        "UnitOperationTypes.PARAM_Y", 'return false,"NATIVE_NO_PATH",-1',
    ):
        if token not in helper:
            fail(f"synchronized path fallback lacks {token}")
    if "AdjacentOpen" in helper:
        fail("single-ring redeploy fallback must not return")
    native_move = helper.split("function LOTM_RESCUE_SyncActions.MoveTowardNative", 1)[1].split("function LOTM_RESCUE_SyncActions.MarkScriptedKiller", 1)[0]
    if "UnitManager.PlaceUnit" in native_move or "RedeployOpen" in native_move:
        fail("guardian native movement must not teleport or use redeployment")
    for obsolete in ('RunCheck("SAINT"', 'RunCheck("ANGEL"', "intervals=20/30", "opening=1_each"):
        if obsolete in script:
            fail(f"superseded independent guardian schedule remains: {obsolete}")
    on_removed = script.split("local function OnRemoved", 1)[1].split("local function ProcessTurn", 1)[0]
    network_removed = on_removed.split("if LOTM_MP_TurnSync.IsNetworkGame() then", 1)[1].split("return; end", 1)[0]
    if "QueueNetworkRemoval(playerID,unitID);" not in network_removed or any(token in network_removed for token in (
        "Game.SetProperty(", "UnitManager.", ":SetProperty(", "ApplyRemoved(",
    )):
        fail("network UnitRemovedFromMap callback must only capture Lua-local removal evidence")
    network_settlement = script.split("local function ProcessNetworkRemovals", 1)[1].split("local function OnRemoved", 1)[0]
    for token in (
        "LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID)", "entry.QueuedTurn<currentTurn",
        "if a.Church~=b.Church", "if a.Tier~=b.Tier", "if a.Serial~=b.Serial",
        "if a.PlayerID~=b.PlayerID", "return a.UnitID<b.UnitID",
        "liveMeta==entry.Meta", "liveSerial==entry.Serial", "ApplyRemoved(entry.PlayerID,entry.UnitID,entry.Meta)",
    ):
        if token not in network_settlement:
            fail(f"deferred guardian removal settlement lacks stable/full-turn identity guard: {token}")
    if "ProcessNetworkRemovals(playerID)" not in script:
        fail("synchronized Phase 3 turn handler must drain deferred network removals")
    sort_body = script.split("table.sort(ranked", 1)[1].split("end);", 1)[0]
    if sort_body.index("KindRank") > sort_body.index("Band"):
        fail("global lost-control/workshop marks must outrank distance bands")

    modinfo = ET.parse(modinfo_path).getroot()
    action_specs = (
        ("UpdateDatabase", "LOTM_RESCUE_PHASE3_DATABASE", "Gameplay/LOTM_RESCUE_Phase3.xml"),
        ("UpdateArt", "LOTM_RESCUE_PHASE3_ART", "Art/LOTM_RESCUE_Phase3.dep"),
        ("UpdateIcons", "LOTM_RESCUE_PHASE3_ICONS", "Art/LOTM_RESCUE_Phase3_Icons.xml"),
    )
    for tag, action_id, filename in action_specs:
        action = action_for(modinfo, tag, action_id)
        if action.get("criteria") != "LOTM_RP_RESCUE_MODE":
            fail(f"{action_id} is not isolated behind rescue-mode criteria")
        if [node.text for node in action.findall("File")] != [filename]:
            fail(f"{action_id} file mismatch")
    gameplay = action_for(modinfo, "AddGameplayScripts", "LOTM_RP_GAMEPLAY_ADDIN")
    if [node.text for node in gameplay.findall("File")] != ["Scripts/LOTM_RP_Gameplay_Bundle.lua"]:
        fail("authoritative Gameplay action must use the self-contained bundle")
    phase3_action = modinfo.find("./InGameActions/AddGameplayScripts[@id='LOTM_RESCUE_PHASE3_GAMEPLAY_ADDIN']")
    if phase3_action is None or phase3_action.get("criteria") != "LOTM_RP_RESCUE_MODE":
        fail("Phase 3 rc.241 standalone Gameplay context is missing or not rescue-gated")
    elif [node.text for node in phase3_action.findall("File")] != ["Scripts/LOTM_MP241_Phase3.lua"]:
        fail("Phase 3 rc.241 standalone Gameplay context file mismatch")
    guardian_assets = {
        f"Art/LOTM_RESCUE_{church}_GuardianGameIcon{size}.dds"
        for church in CHURCHES for size in ICON_SIZES
    }
    icon_import = action_for(modinfo, "ImportFiles", "LOTM_RESCUE_PHASE3_ICON_FILES")
    if icon_import.get("criteria") != "LOTM_RP_RESCUE_MODE":
        fail("guardian icon assets are not isolated behind rescue-mode criteria")
    if {node.text for node in icon_import.findall("File")} != guardian_assets:
        fail("guardian icon ImportFiles action must contain exactly 30 DDS assets")
    phase3_names = {filename for _, _, filename in action_specs}
    for action in modinfo.findall("./InGameActions/*"):
        files = {node.text for node in action.findall("File")}
        if files & phase3_names and action.get("criteria") != "LOTM_RP_RESCUE_MODE":
            fail(f"Phase 3 file loaded outside rescue mode by {action.get('id')}")

    artdef = artdef_path.read_text(encoding="utf-8")
    for unit_type in expected:
        if f'<m_Name text="{unit_type}"/>' not in artdef:
            fail(f"art proxy missing for {unit_type}")
    if artdef.count('text="UNIT_SPEC_OPS"') != 3 or artdef.count('text="UNIT_GIANT_DEATH_ROBOT"') != 3:
        fail("Saint/Angel proxy art split must be 3/3")
    icon_names = {row.get("Name") for row in ET.parse(icons_path).getroot().findall("./IconDefinitions/Row")}
    icon_root = ET.parse(icons_path).getroot()
    textures = icon_root.findall("./IconTextureAtlases/Row")
    if len(textures) != 30:
        fail(f"guardian atlas must contain 30 exact-size textures, got {len(textures)}")
    texture_contract = {
        (row.get("Name"), int(row.get("IconSize", "0")), row.get("Filename"))
        for row in textures
    }
    packaged = {node.text for node in modinfo.findall("./Files/File")}
    builder = icon_builder_path.read_text(encoding="utf-8")
    for token in ('"FOOL": (245, 245, 255)', '"NIGHT": (185, 170, 255)', '"STORM": (55, 235, 225)', '(8, 10, 14, 255)', 'Image.new("RGBA", (extent, extent), (0, 0, 0, 0))'):
        if token not in builder:
            fail(f"guardian builder color/transparency contract missing: {token}")
    for unit_type in expected:
        for suffix in ("", "_FOW", "_WHITE", "_BLACK", "_PORTRAIT"):
            if f"ICON_{unit_type}{suffix}" not in icon_names:
                fail(f"icon mapping missing: ICON_{unit_type}{suffix}")
    for church in CHURCHES:
        atlas = f"ICON_ATLAS_LOTM_RESCUE_GUARDIAN_{church}"
        for size in ICON_SIZES:
            filename = f"LOTM_RESCUE_{church}_GuardianGameIcon{size}.dds"
            if (atlas, size, filename) not in texture_contract:
                fail(f"guardian texture mapping missing: {church} {size}")
            relative = f"Art/{filename}"
            path = ROOT / relative
            if relative not in packaged or relative not in guardian_assets or not path.is_file():
                fail(f"guardian DDS is not packaged/imported: {relative}")
            data = path.read_bytes()
            width, height = struct.unpack_from("<II", data, 12)
            if (width, height) != (size, size):
                fail(f"guardian DDS dimension mismatch: {filename} is {width}x{height}")
            if dxt5_alpha(path, 0, 0) > 48 or dxt5_alpha(path, size // 2, size // 2) < 200:
                fail(f"guardian DDS must have transparent corners and opaque circular center: {filename}")
    definitions = icon_root.findall("./IconDefinitions/Row")
    for row in definitions:
        name = row.get("Name", "")
        if name.startswith("ICON_UNIT_LOTM_RESCUE_"):
            church = next((value for value in CHURCHES if f"_{value}_" in name), None)
            if church is None or row.get("Atlas") != f"ICON_ATLAS_LOTM_RESCUE_GUARDIAN_{church}":
                fail(f"guardian unit icon still points at a panel/city atlas: {name}")

    localized = ET.parse(zh_text_path).getroot().findall("./LocalizedText/Row")
    exact_zh_names = {
        "LOC_UNIT_LOTM_RESCUE_FOOL_SAINT_NAME": "愚者教会-圣者",
        "LOC_UNIT_LOTM_RESCUE_FOOL_ANGEL_NAME": "愚者教会-天使",
        "LOC_UNIT_LOTM_RESCUE_NIGHT_SAINT_NAME": "黑夜女神教会-圣者",
        "LOC_UNIT_LOTM_RESCUE_NIGHT_ANGEL_NAME": "黑夜女神教会-天使",
        "LOC_UNIT_LOTM_RESCUE_STORM_SAINT_NAME": "风暴之主教会-圣者",
        "LOC_UNIT_LOTM_RESCUE_STORM_ANGEL_NAME": "风暴之主教会-天使",
    }
    zh = {row.get("Tag"): row.findtext("Text") for row in localized if row.get("Language") == "zh_Hans_CN"}
    if any(zh.get(tag) != value for tag, value in exact_zh_names.items()):
        fail("Chinese guardian names do not match the authority task book")
    en_tags = {row.get("Tag") for row in ET.parse(en_text_path).getroot().findall("./LocalizedText/Row") if row.get("Language") == "en_US"}
    if not set(exact_zh_names) <= en_tags:
        fail("English guardian names are incomplete")
    zh_saint = zh.get("LOC_UNIT_LOTM_RESCUE_SAINT_DESCRIPTION", "")
    zh_angel = zh.get("LOC_UNIT_LOTM_RESCUE_ANGEL_DESCRIPTION", "")
    for label, description, movement in (("Saint", zh_saint, "3"), ("Angel", zh_angel, "4")):
        for token in (f"移动力{movement}", "每回合同步按移动力", "失控魔物", "普通蛮族", "不会攻击或清除营地与失控工坊", "不主动攻击玩家或正常AI"):
            if token not in description:
                fail(f"Chinese {label} cleanup guidance text missing: {token}")
    en = {row.get("Tag"): row.findtext("Text") or "" for row in ET.parse(en_text_path).getroot().findall("./LocalizedText/Row") if row.get("Language") == "en_US"}
    for label, tag, movement in (("Saint", "LOC_UNIT_LOTM_RESCUE_SAINT_DESCRIPTION", "3"), ("Angel", "LOC_UNIT_LOTM_RESCUE_ANGEL_DESCRIPTION", "4")):
        description = en.get(tag, "")
        for token in (f"Movement {movement}", "synchronously advances up to its Movement", "uncontrolled monsters", "ordinary Barbarians", "never attacks or clears camps and workshops", "never deliberately attacks players or normal AIs"):
            if token not in description:
                fail(f"English {label} cleanup guidance text missing: {token}")

    print("PASS: Rescue Phase 3 static contract (6 units, replenishment, Gameplay-sync movement, monsters-first/no-camp guidance, old-save migration, isolation, art/text)")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"FAILED: {exc}", file=sys.stderr)
        raise SystemExit(1)
