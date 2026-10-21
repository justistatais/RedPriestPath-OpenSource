#!/usr/bin/env python3
"""Static validation for the Red Priest Path phase-05 release candidate.

The script uses only the Python standard library.  With --game-root it also
checks the exact Firaxis files used as schema and Gameplay API references.
"""

from __future__ import annotations

import argparse
import re
import sqlite3
import struct
import sys
import xml.etree.ElementTree as ET
from collections import Counter
from pathlib import Path
# Audit gameplay/UI contracts after removing only generated diagnostics.
# test_rc342_startup_trace verifies the raw code and reversible insertion.
from generate_startup_trace import strip_trace


MOD_ID = "7E4D8D9C-0C96-4B9C-A3D4-6A1E6B19D970"
UNIT_TYPE = "UNIT_LOTM_RP_PATH_HOLDER"
PERFECT_UNIT_TYPE = "UNIT_LOTM_PP_PATH_HOLDER"
BLACK_EMPEROR_UNIT_TYPE = "UNIT_LOTM_BE_PATH_HOLDER"
HUNTER_ABILITY = "ABILITY_LOTM_RP_HUNTER_INSTINCT"
PROVOKER_ABILITY = "ABILITY_LOTM_RP_PROVOKER"
PROVOKER_GARRISON_ABILITY = "ABILITY_LOTM_RP_PROVOKER_GARRISONED"
CONQUEST_ABILITY = "ABILITY_LOTM_RP_CONQUEST_BYPASS_WALLS"
PROVOKER_PROJECT = "PROJECT_LOTM_RP_PROVOKER_POTION"
PYROMANIAC_PROJECT = "PROJECT_LOTM_RP_PYROMANIAC_POTION"
CONSPIRATOR_PROJECT = "PROJECT_LOTM_RP_CONSPIRATOR_POTION"
REAPER_PROJECT = "PROJECT_LOTM_RP_REAPER_POTION"
IRONBLOOD_PROJECT = "PROJECT_LOTM_RP_IRONBLOOD_KNIGHT_POTION"
WAR_BISHOP_PROJECT = "PROJECT_LOTM_RP_WAR_BISHOP_POTION"
WEATHER_WARLOCK_PROJECT = "PROJECT_LOTM_RP_WEATHER_WARLOCK_POTION"
CONQUEROR_PROJECT = "PROJECT_LOTM_RP_CONQUEROR_POTION"
WAR_FESTIVAL_PROJECT = "PROJECT_LOTM_RP_WAR_FESTIVAL"
UNCONSECRATED_WAR_FESTIVAL_PROJECT = "PROJECT_LOTM_RP_WAR_FESTIVAL_UNCONSECRATED"
PP_ARCHAEOLOGIST_PROJECT = "PROJECT_LOTM_PP_ARCHAEOLOGIST_POTION"
PP_APPRAISER_PROJECT = "PROJECT_LOTM_PP_APPRAISER_POTION"
PP_MECHANICAL_PROJECT = "PROJECT_LOTM_PP_MECHANICAL_EXPERT_POTION"
PP_ASTRONOMER_PROJECT = "PROJECT_LOTM_PP_ASTRONOMER_POTION"
PP_ALCHEMIST_PROJECT = "PROJECT_LOTM_PP_ALCHEMIST_POTION"
PP_MYSTERY_SCHOLAR_PROJECT = "PROJECT_LOTM_PP_MYSTERY_SCHOLAR_POTION"
PP_KNOWLEDGE_MENTOR_PROJECT = "PROJECT_LOTM_PP_KNOWLEDGE_MENTOR_POTION"
PP_ENLIGHTENER_PROJECT = "PROJECT_LOTM_PP_ENLIGHTENER_POTION"
PP_CIVILIZATION_ASCENSION_PROJECT = "PROJECT_LOTM_PP_CIVILIZATION_ASCENSION"
PP_UNCONSECRATED_ASCENSION_PROJECT = (
    "PROJECT_LOTM_PP_CIVILIZATION_ASCENSION_UNCONSECRATED"
)
BE_BARBARIAN_PROJECT = "PROJECT_LOTM_BE_BARBARIAN_POTION"
BE_BRIBER_PROJECT = "PROJECT_LOTM_BE_BRIBER_POTION"
BE_BARON_PROJECT = "PROJECT_LOTM_BE_BARON_OF_CORRUPTION_POTION"
BE_CHAOS_MENTOR_PROJECT = "PROJECT_LOTM_BE_CHAOS_MENTOR_POTION"
BE_COUNT_PROJECT = "PROJECT_LOTM_BE_COUNT_OF_CORRUPTION_POTION"
BE_FRENZY_PROJECT = "PROJECT_LOTM_BE_FRENZY_MAGE_POTION"
BE_ENTROPY_PROJECT = "PROJECT_LOTM_BE_DUKE_OF_ENTROPY_POTION"
BE_PRINCE_PROJECT = "PROJECT_LOTM_BE_PRINCE_OF_ABOLITION_POTION"
BE_TRANSFORMATION_PROJECT = "PROJECT_LOTM_BE_TRANSFORMATION"
BE_ENTHRONEMENT_PROJECT = "PROJECT_LOTM_BE_ENTHRONEMENT"
BE_UNCONSECRATED_ENTHRONEMENT_PROJECT = (
    "PROJECT_LOTM_BE_ENTHRONEMENT_UNCONSECRATED"
)
BE_CHAOS_I_POLICY = "POLICY_LOTM_BE_CHAOS_I"
BE_EXTRA_POLICIES = (
    "POLICY_LOTM_BE_CHAOS_II", "POLICY_LOTM_BE_CHAOS_III",
    "POLICY_LOTM_BE_CORRUPTION_I", "POLICY_LOTM_BE_CORRUPTION_II",
    "POLICY_LOTM_BE_CORRUPTION_III", "POLICY_LOTM_BE_FRENZY_I",
    "POLICY_LOTM_BE_FRENZY_II",
)
CHURCH_BELIEF = "BELIEF_LOTM_RP_ESTABLISH_CHURCH"
TRUE_GOD_BELIEF = "BELIEF_LOTM_RP_TRUE_GOD_CHURCH"
WEATHER_OPPOSING_ATTACH_MODIFIER = (
    "MODIFIER_LOTM_RP_MAJOR_OPPOSING_PLAYERS_ATTACH_MODIFIER"
)
TECH_BASE_COMBAT_MODIFIER = (
    "MODIFIER_LOTM_RP_PLAYER_UNITS_ADJUST_BASE_COMBAT_STRENGTH"
)
PROMOTION_CLASS = "PROMOTION_CLASS_LOTM_RP_PATH_HOLDER"
COMBAT_PROMOTIONS = tuple(f"PROMOTION_LOTM_RP_COMBAT_{level}" for level in range(1, 4))
MOVEMENT_PROMOTIONS = tuple(f"PROMOTION_LOTM_RP_MOVEMENT_{level}" for level in range(1, 4))
WAR_AURA_ABILITY = "ABILITY_LOTM_RP_WAR_AURA"
WAR_AURA_SOURCE_V2 = "ABILITY_LOTM_RP_WAR_AURA_SOURCE_V2"
WAR_AURA_V2 = "ABILITY_LOTM_RP_WAR_AURA_V2"
ROOT = Path(__file__).resolve().parents[1]
MODINFO = ROOT / "RedPriestPath.modinfo"


class Validation:
    def __init__(self) -> None:
        self.failures: list[str] = []
        self.checks = 0

    def check(self, condition: bool, message: str) -> None:
        self.checks += 1
        if not condition:
            self.failures.append(message)

    def require_file(self, path: Path, label: str | None = None) -> None:
        self.check(path.is_file(), f"missing {label or 'file'}: {path}")


def parse_xml_files(validation: Validation) -> dict[Path, ET.Element]:
    parsed: dict[Path, ET.Element] = {}
    xml_like = sorted(
        path
        for path in ROOT.rglob("*")
        if path.is_file() and path.suffix.lower() in {".xml", ".modinfo", ".dep", ".artdef"}
    )
    validation.check(bool(xml_like), "no XML-like files found")
    for path in xml_like:
        try:
            parsed[path] = ET.parse(path).getroot()
        except ET.ParseError as exc:
            validation.check(False, f"XML parse error in {path.relative_to(ROOT)}: {exc}")
    return parsed


def validate_structure(validation: Validation) -> None:
    for directory in ("Config", "Gameplay", "Scripts", "UI", "Text", "Art", "Tests"):
        validation.check((ROOT / directory).is_dir(), f"missing required directory: {directory}")
    for filename in (
        "README.md",
        "INSTALL.md",
        "CHANGELOG.md",
        "VERSION.md",
        "KNOWN_LIMITATIONS.md",
        "RedPriestPath.modinfo",
    ):
        validation.require_file(ROOT / filename)
    validation.require_file(ROOT / "Scripts" / "LOTM_RP_StateContract.md", "HUD state contract")
    validation.require_file(ROOT / "Tests" / "COMPATIBILITY_MATRIX.md", "compatibility matrix")
    validation.require_file(ROOT / "Tests" / "DUAL_CLIENT_TESTS.md", "dual-client test script")
    validation.require_file(
        ROOT / "Tests" / "collect_multiplayer_evidence.ps1",
        "dual-client evidence collector",
    )
    validation.require_file(ROOT / "Tests" / "build_release.py", "release builder")
    validation.require_file(ROOT / "Gameplay" / "LOTM_WORLD_Monsters.sql", "rc.82 monster database")
    validation.check(
        not (ROOT / "Gameplay" / "LOTM_WORLD_BarbarianCamps.sql").exists(),
        "retired standalone camp SQL must not remain outside the established database action",
    )
    validation.require_file(ROOT / "Scripts" / "LOTM_WORLD_Barbarians.lua", "barbarian baseline resolver")
    validation.require_file(ROOT / "Scripts" / "LOTM_WORLD_Monsters.lua", "rc.82 monster gameplay")
    validation.require_file(ROOT / "Tests" / "validate_rc82_monsters.py", "rc.82 focused validator")
    validation.require_file(ROOT / "Gameplay" / "LOTM_WORLD_Churches.sql", "rc.83 church database")
    validation.require_file(ROOT / "Scripts" / "LOTM_WORLD_Churches.lua", "rc.83 church gameplay")
    validation.require_file(ROOT / "UI" / "LOTM_WORLD_CityStates.lua", "rc.83 City States injection")
    validation.require_file(ROOT / "Tests" / "validate_rc83_churches.py", "rc.83 focused validator")
    validation.require_file(ROOT / "Scripts" / "LOTM_RESCUE_Phase1.lua", "Rescue Phase 1 synchronized gameplay")
    validation.require_file(ROOT / "UI" / "LOTM_RESCUE_Phase1Markers.lua", "Rescue Phase 1 read-only markers")
    validation.require_file(ROOT / "UI" / "LOTM_RESCUE_Phase1Markers.xml", "Rescue Phase 1 marker context")
    validation.require_file(ROOT / "Tests" / "validate_rescue_phase1.py", "Rescue Phase 1 focused validator")
    validation.require_file(ROOT / "Scripts" / "LOTM_RESCUE_Phase2Test.lua", "Rescue Phase 2A synchronized test city")
    validation.require_file(ROOT / "Tests" / "validate_rescue_phase2a.py", "Rescue Phase 2A focused validator")
    validation.require_file(ROOT / "Gameplay" / "LOTM_RESCUE_Phase3.xml", "Rescue Phase 3 unit database")
    validation.require_file(ROOT / "Scripts" / "LOTM_RESCUE_Phase3.lua", "Rescue Phase 3 synchronized gameplay")
    validation.require_file(ROOT / "Scripts" / "LOTM_RESCUE_SyncActions.lua", "Rescue Gameplay-native movement and clearing helpers")
    validation.require_file(ROOT / "Tests" / "validate_rescue_phase3.py", "Rescue Phase 3 focused validator")
    validation.require_file(ROOT / "Scripts" / "LOTM_RESCUE_Difficulty.lua", "Rescue synchronized difficulty authority")
    validation.require_file(ROOT / "UI" / "LOTM_RESCUE_DifficultyChoice.lua", "Rescue difficulty choice UI")
    validation.require_file(ROOT / "UI" / "LOTM_RESCUE_DifficultyChoice.xml", "Rescue difficulty choice page")
    validation.require_file(ROOT / "Tests" / "validate_rescue_difficulty.py", "Rescue difficulty focused validator")
    validation.require_file(ROOT / "Scripts" / "LOTM_RESCUE_Phase6.lua", "Rescue Phase 6 synchronized purification ledger")
    validation.require_file(ROOT / "UI" / "LOTM_RESCUE_Purification.lua", "Rescue Phase 6 read-only HUD")
    validation.require_file(ROOT / "UI" / "LOTM_RESCUE_Purification.xml", "Rescue Phase 6 HUD context")
    validation.require_file(ROOT / "Tests" / "validate_rescue_phase6.py", "Rescue Phase 6 focused validator")
    validation.require_file(ROOT / "Gameplay" / "LOTM_RESCUE_Phase7.sql", "Rescue Phase 7 doubled cumulative cult bonuses")
    validation.require_file(ROOT / "Scripts" / "LOTM_RESCUE_Phase7.lua", "Rescue Phase 7 synchronized gameplay")
    validation.require_file(ROOT / "Tests" / "validate_rescue_phase7.py", "Rescue Phase 7 focused validator")
    validation.require_file(ROOT / "Gameplay" / "LOTM_RESCUE_Phase8.sql", "Rescue Phase 8 AI peace preferences")
    validation.require_file(ROOT / "Scripts" / "LOTM_RESCUE_Phase8.lua", "Rescue Phase 8 synchronized diplomacy and targeting")
    validation.require_file(ROOT / "Tests" / "validate_rescue_phase8.py", "Rescue Phase 8 focused validator")
    validation.require_file(ROOT / "Gameplay" / "LOTM_RESCUE_Phase9.sql", "Rescue Phase 9 player and AI modifiers")
    validation.require_file(ROOT / "Scripts" / "LOTM_RESCUE_Phase9.lua", "Rescue Phase 9 synchronized overrides")
    validation.require_file(ROOT / "Tests" / "validate_rescue_phase9.py", "Rescue Phase 9 focused validator")
    validation.require_file(ROOT / "Scripts" / "LOTM_RESCUE_Phase9Digestion.lua", "Rescue Phase 9 confirmed digestion override")
    validation.require_file(ROOT / "Tests" / "validate_rescue_phase9_digestion.py", "Rescue Phase 9 digestion validator")
    validation.require_file(ROOT / "Scripts" / "LOTM_RESCUE_Phase10A.lua", "Rescue Phase 10A synchronized measurement gate")
    validation.require_file(ROOT / "Tests" / "validate_rescue_phase10a.py", "Rescue Phase 10A measurement validator")
    validation.require_file(ROOT / "Gameplay" / "LOTM_RESCUE_Phase10.sql", "Rescue Phase 10 gods, Boss and victory database")
    validation.require_file(ROOT / "Scripts" / "LOTM_RESCUE_Phase10.lua", "Rescue Phase 10 synchronized final battle")
    validation.require_file(ROOT / "Scripts" / "LOTM_RESCUE_DirectMonsters.lua", "Rescue-only direct outside-city monster stream")
    validation.require_file(ROOT / "Tests" / "validate_rescue_phase10.py", "Rescue Phase 10 final-battle validator")
    validation.require_file(ROOT / "Tests" / "validate_rescue_artifacts.py", "Rescue artifact isolation validator")
    validation.require_file(ROOT / "Tests" / "validate_ui_compatibility.py", "Rescue HUD and optional UI compatibility validator")
    validation.require_file(ROOT / "Scripts" / "LOTM_RP_Gameplay_Bundle.lua", "self-contained authoritative Gameplay bundle")
    validation.require_file(ROOT / "Tests" / "generate_gameplay_bundle.py", "deterministic Gameplay bundle generator")
    validation.require_file(ROOT / "Tests" / "validate_gameplay_bundle.py", "Gameplay bundle freshness and action validator")

    version_text = strip_trace((ROOT / "VERSION.md").read_text(encoding="utf-8"))
    validation.check(
        "`0.1.0-rc.403`" in version_text,
        "semantic version must be 0.1.0-rc.403 for production Storm charges and immediate local aiming",
    )
    validation.check(
        "双客户端均待实测" in version_text,
        "release status must preserve the unexecuted game/multiplayer boundary",
    )


def validate_release_hygiene(validation: Validation) -> None:
    generated = [
        path.relative_to(ROOT).as_posix()
        for path in ROOT.rglob("*")
        if path.is_file()
        and not path.relative_to(ROOT).as_posix().startswith("backups/")
        and (
            "__pycache__" in path.parts
            or path.suffix.lower() in {".pyc", ".pyo"}
            or path.name in {".DS_Store", "Thumbs.db"}
        )
    ]
    validation.check(
        not generated,
        f"generated cache/desktop files must not ship: {generated}",
    )

    archives = [
        path.relative_to(ROOT).as_posix()
        for path in ROOT.rglob("*")
        if path.is_file()
        and path.suffix.lower() in {".zip", ".7z", ".rar"}
        and not path.relative_to(ROOT).as_posix().startswith("backups/")
    ]
    validation.check(
        not archives,
        f"nested archives must not be stored inside the mod source: {archives}",
    )

    copied_asset_extensions = {
        ".bnk",
        ".dds",
        ".fpk",
        ".gr2",
        ".mp3",
        ".ogg",
        ".wav",
        ".wem",
    }
    allowed_custom_assets = {
        "Art/LOTM_RP_RedPriestMark40.dds",
        "Art/LOTM_RP_RedPriestMark768.dds",
        "Art/LOTM_RP_RedPriestMarkCentered40.dds",
        "Art/LOTM_RP_RedPriestMarkCentered384.dds",
        "Art/LOTM_RP_RedPriestMarkCentered512.dds",
        "Art/LOTM_RP_RedPriestMarkCentered640.dds",
        "Art/LOTM_RP_RedPriestMarkCentered768.dds",
        "Art/LOTM_PP_PerfectMarkCentered40.dds",
        "Art/LOTM_PP_PerfectMarkCentered384.dds",
        "Art/LOTM_PP_PerfectMarkCentered512.dds",
        "Art/LOTM_PP_PerfectMarkCentered640.dds",
        "Art/LOTM_PP_PerfectMarkCentered768.dds",
        "Art/LOTM_WORLD_MonsterMarkSource.png",
        "Art/LOTM_WORLD_MonsterMark40.dds",
        "Art/LOTM_WORLD_MonsterMark256.dds",
        "Art/LOTM_RESCUE_OuterGodStarMarkSource.png",
        "Art/LOTM_RESCUE_OuterGodStarMark40.dds",
        "Art/LOTM_RESCUE_OuterGodStarMark256.dds",
    }
    allowed_custom_assets.update(
        f"Art/LOTM_RP_RedPriestGameIcon{size}.dds"
        for size in (22, 30, 32, 38, 50, 64, 70, 80, 95, 200, 256)
    )
    allowed_custom_assets.update(
        f"Art/LOTM_Church_{church}_{size}.dds"
        for church in ("FOOL", "NIGHT", "STORM")
        for size in (22, 26, 32, 36, 40, 56, 64, 128, 200, 256)
    )
    allowed_custom_assets.add("Art/LOTM_RESCUE_AstralDescent_22.dds")
    allowed_custom_assets.update(
        f"Art/LOTM_GOD_FX_{kind}_{sheet:02d}.dds"
        for kind, count in (("STORM", 13), ("NIGHT", 11), ("FOOL", 12))
        for sheet in range(count)
    )
    allowed_custom_assets.update(
        f"Art/LOTM_GOD_FX_STORM_V4_{sheet:02d}.dds"
        for sheet in range(14)
    )
    allowed_custom_assets.update(
        f"Art/LOTM_StormBlessing{size}.dds"
        for size in (22, 24, 30, 32, 38, 45, 50, 64, 80, 128, 256)
    )
    allowed_custom_assets.update(
        f"Art/LOTM_RESCUE_{church}_GuardianGameIcon{size}.dds"
        for church in ("FOOL", "NIGHT", "STORM")
        for size in (22, 30, 32, 38, 50, 70, 80, 95, 200, 256)
    )
    allowed_custom_assets.update(
        f"Art/LOTM_AI_Cult_{cult}_{size}.dds"
        for cult in ("Demoness", "HangedMan", "Chained")
        for size in (22, 32, 40, 50, 64, 80, 128, 200, 256)
    )
    allowed_custom_assets.update(
        f"Art/LOTM_AI_Cult_FleshPuppetMark_{size}.dds"
        for size in (40, 64, 256)
    )
    allowed_custom_assets.update(
        f"Art/LOTM_PP_PerfectGameIcon{size}.dds"
        for size in (22, 30, 32, 38, 50, 64, 70, 80, 95, 200, 256)
    )
    allowed_custom_assets.update(
        f"Art/LOTM_BE_BlackEmperorMarkCentered{size}.dds"
        for size in (40, 384, 512, 640, 768)
    )
    allowed_custom_assets.update(
        f"Art/LOTM_BE_BlackEmperorGameIcon{size}.dds"
        for size in (22, 30, 32, 38, 50, 64, 70, 80, 95, 200, 256)
    )
    allowed_custom_assets.update(
        f"Art/LOTM_TP_ThiefGameIcon{size}.dds"
        for size in (22, 30, 32, 38, 50, 64, 70, 80, 95, 200, 256)
    )
    allowed_custom_assets.update(
        f"Art/LOTM_TP_ThiefMarkCentered{size}.dds"
        for size in (40, 384, 512, 640, 768)
    )
    allowed_custom_assets.update(
        f"Art/LOTM_TP_FakeGoldIcon{size}.dds"
        for size in (22, 30, 32, 38, 50, 64, 80, 128, 256)
    )
    allowed_custom_assets.update(
        f"Art/LOTM_RESCUE_PurificationEnergy{size}.dds"
        for size in (22, 30, 32, 38, 50, 64, 80, 128, 256)
    )
    allowed_custom_assets.update(
        f"Art/LOTM_RESCUE_TimeWorm{size}.dds"
        for size in (22, 30, 32, 38, 50, 64, 70, 80, 95, 128, 200, 256)
    )
    allowed_custom_assets.update(
        f"Art/LOTM_ArtifactLaunchIcon{size}.dds"
        for size in (40, 64, 256)
    )
    allowed_custom_assets.update(
        f"Art/LOTM_JUSTICE_Audrey{size}.dds"
        for size in (24, 32, 64, 256)
    )
    allowed_custom_assets.update(
        f"Art/LOTM_JUSTICE_Banner{kind}{size}.dds"
        for kind in ("Fill", "Slot") for size in (22, 32)
    )
    allowed_custom_assets.update(
        f"Art/LOTM_MS_{governor}{size}.dds"
        for governor in ("Fors", "Leonard") for size in (24, 32, 64, 256)
    )
    allowed_custom_assets.update(
        f"Art/LOTM_MS_{governor}Banner{kind}{size}.dds"
        for governor in ("Fors", "Leonard")
        for kind in ("Fill", "Slot") for size in (22, 32)
    )
    allowed_custom_assets.update((
        "Art/LOTM_MS_ForsPortrait.png", "Art/LOTM_MS_LeonardPortrait.png"
    ))
    allowed_custom_assets.update(
        f"Art/Comics/LOTM_Comic_{prefix}-{index}.{extension}"
        for prefix, count in ((1, 3), (2, 8), (3, 2))
        for index in range(1, count + 1)
        for extension in ("png", "dds")
    )
    copied_assets = [
        path.relative_to(ROOT).as_posix()
        for path in ROOT.rglob("*")
        if path.is_file()
        and path.suffix.lower() in copied_asset_extensions
        and path.relative_to(ROOT).as_posix() not in allowed_custom_assets
        and not path.relative_to(ROOT).as_posix().startswith("Art/Artifacts/LOTM_ART_")
        and not path.relative_to(ROOT).as_posix().startswith("Art/LOTM_ART_")
    ]
    validation.check(
        not copied_assets,
        f"release candidate must not copy unapproved binary game assets: {copied_assets}",
    )
    release_builder = strip_trace((ROOT / "Tests" / "build_release.py").read_text(encoding="utf-8"))
    validation.check(
        'VERSION = "0.1.0-rc.403"' in release_builder,
		"release builder version must match rc.403",
    )
    validation.check(
        "RESOURCE_VERSION = 435" in release_builder,
		"release builder resource version must match resource 435",
    )
    validation.check(
        "ZIP_TIMESTAMP_EPOCH + timedelta(minutes=RESOURCE_VERSION)" in release_builder
        and "date_time=ZIP_TIMESTAMP.timetuple()[:6]" in release_builder
        and "date_time=(2026, 7, 26, 0, 0, 0)" not in release_builder,
        "release archive timestamps must advance deterministically per resource so Civ VI rescans .modinfo",
    )


def validate_modinfo(validation: Validation, root: ET.Element) -> None:
    validation.check(root.tag == "Mod", "modinfo root must be Mod")
    validation.check(root.attrib.get("id", "").upper() == MOD_ID, "modinfo ID does not match contract")
    validation.check(
        root.attrib.get("version") == "435",
		"rc.403 production Storm charges and immediate local aiming must use resource version 434",
    )
    supports_multiplayer = root.find("./Properties/SupportsMultiplayer")
    validation.check(
        supports_multiplayer is not None and supports_multiplayer.text == "1",
        "modinfo must explicitly declare multiplayer support",
    )

    referenced: list[str] = []
    for file_element in root.findall(".//File"):
        if file_element.text:
            referenced.append(file_element.text.strip())
    validation.check(bool(referenced), "modinfo contains no file references")
    for relative in sorted(set(referenced)):
        validation.require_file(ROOT / Path(relative), f"modinfo referenced file ({relative})")

    packaged_files = {
        node.text.strip()
        for node in root.findall("./Files/File")
        if node.text
    }
    action_files = {
        node.text.strip()
        for section in ("FrontEndActions", "InGameActions")
        for node in root.findall(f"./{section}/*/File")
        if node.text
    }
    validation.check(
        action_files <= packaged_files,
        "action file references missing from <Files>: "
        f"{sorted(action_files - packaged_files)}",
    )
    obsolete_gameplay_import_ids = {
        "LOTM_RP_GAMEPLAY_DEPENDENCY_FILES",
        "LOTM_RESCUE_BOOTSTRAP_GAMEPLAY_DEPENDENCY_FILES",
        "LOTM_TP_GAMEPLAY_DEPENDENCY_FILES",
        "LOTM_RP_GAMEPLAY_SHARED_FILES",
    }
    in_game_action_ids = {
        node.attrib.get("id") for node in root.findall("./InGameActions/*")
    }
    validation.check(
        not (obsolete_gameplay_import_ids & in_game_action_ids),
        "authoritative Gameplay must not rely on the ImportFiles actions omitted by the resource-287 runtime",
    )
    replacement_scripts = {
        node.text.strip()
        for node in root.findall("./InGameActions/ReplaceUIScript/Properties/LuaReplace")
        if node.text
    }
    validation.check(
        replacement_scripts <= packaged_files,
        "ReplaceUIScript paths missing from <Files>: "
        f"{sorted(replacement_scripts - packaged_files)}",
    )
    gameplay_entry = strip_trace((ROOT / "Scripts" / "LOTM_RP_Gameplay.lua").read_text(
        encoding="utf-8"
    ))
    included_gameplay_scripts = {
        f"Scripts/{name}.lua"
        for name in re.findall(r'include\("([A-Za-z0-9_]+)"\)', gameplay_entry)
    }
    validation.check(
        included_gameplay_scripts <= packaged_files,
        "Gameplay include targets missing from <Files>: "
        f"{sorted(included_gameplay_scripts - packaged_files)}",
    )

    dependency_ids = {node.attrib.get("id", "").lower() for node in root.findall("./Dependencies/Mod")}
    validation.check(
        "4873eb62-8ccc-4574-b784-dda455e74e68" in dependency_ids,
        "Gathering Storm dependency is missing",
    )
    criteria = root.find("./ActionCriteria/Criteria[@id='LOTM_RP_EXPANSION_2']/RuleSetInUse")
    validation.check(
        criteria is not None and criteria.text == "RULESET_EXPANSION_2",
        "in-game action criterion must require RULESET_EXPANSION_2",
    )

    expected_actions = {
        "LOTM_RP_CONFIG_DATABASE",
        "LOTM_RP_CONFIG_TEXT",
        "LOTM_RP_GAMEPLAY_DATABASE",
        "LOTM_RP_ART",
        "LOTM_RP_ICONS",
        "LOTM_RP_GAMEPLAY_TEXT_ZH",
        "LOTM_RP_GAMEPLAY_TEXT_EN",
        "LOTM_RP_GAMEPLAY_ADDIN",
        "LOTM_RESCUE_PHASE3_DATABASE",
        "LOTM_RESCUE_PHASE3_ART",
        "LOTM_RESCUE_PHASE3_ICONS",
        "LOTM_RESCUE_PHASE3_ICON_FILES",
        "LOTM_RP_UI_FILES",
        "LOTM_RP_UI_ADDIN",
        "LOTM_RP_HUD_UI_ADDIN",
        "LOTM_RP_COMIC_VIEWER_UI_ADDIN",
        "LOTM_RP_PATH_CHOICE_UI_ADDIN",
        "LOTM_RP_LAUNCH_BUTTON_UI_ADDIN",
        "LOTM_PP_ARTIFACT_SHOWCASE_UI_ADDIN",
        "LOTM_RESCUE_PHASE1_MARKERS_UI_ADDIN",
    }
    action_ids = {node.attrib.get("id") for node in root.findall("./FrontEndActions/*")}
    action_ids.update(node.attrib.get("id") for node in root.findall("./InGameActions/*"))
    validation.check(expected_actions <= action_ids, "one or more required modinfo actions are missing")

    quick_deals_id = "5aceed03-8639-4a81-8cbf-03f54d543502"
    dependency_ids = {node.attrib.get("id") for node in root.findall("./Dependencies/Mod")}
    reference_ids = {node.attrib.get("id") for node in root.findall("./References/Mod")}
    qd_criterion = root.find("./ActionCriteria/Criteria[@id='LOTM_RP_EXPANSION_2_QUICK_DEALS']")
    no_qd_criterion = root.find("./ActionCriteria/Criteria[@id='LOTM_RP_EXPANSION_2_NO_QUICK_DEALS']")
    qd_action = root.find("./InGameActions/AddGameplayScripts[@id='LOTM_QD_MULTIPLAYER_COMPAT']")
    validation.check(
        quick_deals_id not in dependency_ids and quick_deals_id in reference_ids,
        "Quick Deals must remain an optional reference, never a hard dependency",
    )
    validation.check(
        qd_criterion is not None
        and qd_criterion.findtext("./ModInUse") == quick_deals_id
        and qd_action is not None
        and qd_action.attrib.get("criteria") == "LOTM_RP_EXPANSION_2_QUICK_DEALS",
        "Quick Deals compatibility gameplay action must load only when Quick Deals is in use",
    )
    validation.check(
        no_qd_criterion is not None
        and no_qd_criterion.find("./ModInUse") is not None
        and no_qd_criterion.find("./ModInUse").attrib.get("inverse") == "1"
        and no_qd_criterion.findtext("./ModInUse") == quick_deals_id,
        "the no-Quick-Deals UI branch must use the inverse ModInUse criterion",
    )
    qd_compat_text = strip_trace((ROOT / "Scripts" / "LOTM_QD_MultiplayerCompat.lua").read_text(encoding="utf-8"))
    validation.check(
        "ExposedMembers ~= nil and ExposedMembers.QD or nil" in qd_compat_text
        and "qd ~= nil and qd.CacheManager or nil" in qd_compat_text,
        "Quick Deals compatibility script must fail closed when the optional API is absent",
    )
    validation.check(
        'local function ClearLegacyCacheAtSynchronizedTurn(anchor)' in qd_compat_text
        and 'player:SetProperty(key,nil);' in qd_compat_text
        and 'ClearLegacyCacheAtSynchronizedTurn(playerID);' in qd_compat_text
        and 'Events.LoadGameViewStateDone.Add(function() Reconcile("LOAD_GAME_VIEW_STATE_DONE"); end);' in qd_compat_text
        and 'Events.LoadScreenClose.Add(function() Reconcile("LOAD_SCREEN_CLOSE"); end);' in qd_compat_text,
        "Quick Deals legacy cache cleanup must be confined to the synchronized Gameplay turn",
    )
    validation.check(
        'Reconcile("SCRIPT_LOAD")' in qd_compat_text
        and 'Reconcile("SYNCHRONIZED_WORLD_TURN")' in qd_compat_text,
        "Quick Deals local-cache guard must run at startup and the synchronized world-turn anchor",
    )

    expected_languages = {
        "LOTM_RP_LANGUAGE_ZH": None,
        "LOTM_RP_LANGUAGE_EN": "en_US",
    }
    for criterion_id, value in expected_languages.items():
        criterion = root.find(f"./ActionCriteria/Criteria[@id='{criterion_id}']")
        validation.check(criterion is not None, f"missing language criterion {criterion_id}")
        if criterion is None:
            continue
        validation.check(
            criterion.findtext("./RuleSetInUse") == "RULESET_EXPANSION_2",
            f"{criterion_id} must require Gathering Storm",
        )
        match = criterion.find("./ConfigurationValueMatches")
        if value is None:
            validation.check(
                match is None,
                f"{criterion_id} must be the unconditional old-save Chinese fallback",
            )
        else:
            validation.check(
                match is not None
                and match.findtext("./Group") == "Game"
                and match.findtext("./ConfigurationId") == "LOTM_RP_TEXT_LANGUAGE"
                and match.findtext("./Value") == value,
                f"{criterion_id} must select {value}",
            )

    for language, action_id, criterion_id in (
        ("zh_Hans_CN", "LOTM_RP_GAMEPLAY_TEXT_ZH", "LOTM_RP_LANGUAGE_ZH"),
        ("en_US", "LOTM_RP_GAMEPLAY_TEXT_EN", "LOTM_RP_LANGUAGE_EN"),
    ):
        action = root.find(f"./InGameActions/UpdateText[@id='{action_id}']")
        files = [node.text for node in action.findall("./File")] if action is not None else []
        validation.check(
            action is not None
            and action.attrib.get("criteria") == criterion_id
            and files == [f"Text/Selected/LOTM_RP_Selected_{language}.xml"],
            f"{action_id} must load only the generated {language} text pack",
        )

    ui_import = root.find("./InGameActions/ImportFiles[@id='LOTM_RP_UI_FILES']")
    imported_files = {
        node.text.strip()
        for node in ui_import.findall("./File")
        if node.text
    } if ui_import is not None else set()
    artifact_dds = {
        path.relative_to(ROOT).as_posix()
        for path in (ROOT / "Art").glob("LOTM_ART_*.dds")
    }
    validation.check(
        len(artifact_dds) == 63,
        f"expected 63 root artifact DDS files, found {len(artifact_dds)}",
    )
    validation.check(
        artifact_dds <= imported_files,
        f"artifact DDS files missing from UI ImportFiles: {sorted(artifact_dds - imported_files)}",
    )

    for section_name in ("FrontEndActions", "InGameActions"):
        orders: list[int] = []
        for action in root.findall(f"./{section_name}/*"):
            load_order = action.find("./Properties/LoadOrder")
            validation.check(load_order is not None, f"{action.tag} {action.attrib.get('id')} has no LoadOrder")
            if load_order is not None:
                orders.append(int(load_order.text or "0"))
        validation.check(orders == sorted(orders), f"{section_name} actions are not in nondecreasing load order")

    gameplay_action = root.find("./InGameActions/UpdateDatabase[@id='LOTM_RP_GAMEPLAY_DATABASE']")
    validation.check(gameplay_action is not None, "gameplay database action missing")
    if gameplay_action is not None:
        files = gameplay_action.findall("./File")
        priorities = [int(node.attrib.get("Priority", "0")) for node in files]
        names = [node.text for node in files]
        validation.check(
            names
            == [
                "Gameplay/LOTM_RP_Types.xml",
                "Gameplay/LOTM_RP_Promotions.xml",
                "Gameplay/LOTM_RP_Beliefs.xml",
                "Gameplay/LOTM_RP_ProjectSupport.sql",
                "Gameplay/LOTM_RP_Units.xml",
                "Gameplay/LOTM_RP_Projects.xml",
                "Gameplay/LOTM_PP_Perfect.sql",
                "Gameplay/LOTM_PP_Artifacts.sql",
                "Gameplay/LOTM_WORLD_GoodyHuts.sql",
                "Gameplay/LOTM_WORLD_Events.sql",
                "Gameplay/LOTM_WORLD_Monsters.sql",
                "Gameplay/LOTM_WORLD_Churches.sql",
                "Gameplay/LOTM_AI_Cults.sql",
                "Gameplay/LOTM_BE_BlackEmperor.sql",
                "Gameplay/LOTM_RP_Modifiers.xml",
                "Gameplay/LOTM_RP_Abilities.xml",
            ],
            "gameplay database files are missing or out of order",
        )
        validation.check(
            priorities == [6, 5, 5, 5, 4, 3, 2, 2, 1, 1, 1, 1, 1, 1, 2, 1],
            "gameplay database priorities must preserve Types-before-content order",
        )

    gameplay_scripts = root.find("./InGameActions/AddGameplayScripts[@id='LOTM_RP_GAMEPLAY_ADDIN']")
    script_names = (
        [node.text for node in gameplay_scripts.findall("./File")]
        if gameplay_scripts is not None
        else []
    )
    validation.check(
        script_names == ["Scripts/LOTM_RP_Gameplay_Bundle.lua"],
        "Gameplay must load through one self-contained shared-context bundle",
    )


def validate_types(validation: Validation, parsed: dict[Path, ET.Element]) -> None:
    custom_types: list[str] = []
    for root in parsed.values():
        for row in root.findall(".//Types/Row"):
            value = row.attrib.get("Type")
            if value:
                custom_types.append(value)
    counts = Counter(custom_types)
    duplicates = sorted(value for value, count in counts.items() if count > 1)
    validation.check(not duplicates, f"duplicate custom Types: {duplicates}")
    validation.check(
        set(custom_types)
        == {
            UNIT_TYPE,
            PERFECT_UNIT_TYPE,
            BLACK_EMPEROR_UNIT_TYPE,
            HUNTER_ABILITY,
            PROVOKER_ABILITY,
            PROVOKER_GARRISON_ABILITY,
            CONQUEST_ABILITY,
            PROVOKER_PROJECT,
            PYROMANIAC_PROJECT,
            CONSPIRATOR_PROJECT,
            REAPER_PROJECT,
            IRONBLOOD_PROJECT,
            WAR_BISHOP_PROJECT,
            WEATHER_WARLOCK_PROJECT,
            CONQUEROR_PROJECT,
            WAR_FESTIVAL_PROJECT,
            UNCONSECRATED_WAR_FESTIVAL_PROJECT,
            PP_ARCHAEOLOGIST_PROJECT,
            PP_APPRAISER_PROJECT,
            PP_MECHANICAL_PROJECT,
            PP_ASTRONOMER_PROJECT,
            PP_ALCHEMIST_PROJECT,
            PP_MYSTERY_SCHOLAR_PROJECT,
            PP_KNOWLEDGE_MENTOR_PROJECT,
            PP_ENLIGHTENER_PROJECT,
            PP_CIVILIZATION_ASCENSION_PROJECT,
            PP_UNCONSECRATED_ASCENSION_PROJECT,
            "PROJECT_LOTM_TP_SWINDLER_POTION",
            "PROJECT_LOTM_TP_CRYPTOLOGIST_POTION",
            "PROJECT_LOTM_TP_PROMETHEUS_POTION",
            "PROJECT_LOTM_TP_DREAM_STEALER_POTION",
            "PROJECT_LOTM_TP_PARASITE_POTION",
            "PROJECT_LOTM_TP_MENTOR_OF_DECEIT_POTION",
            "PROJECT_LOTM_TP_FATE_TROJAN_POTION",
            "PROJECT_LOTM_TP_WORM_OF_TIME_POTION",
            "PROJECT_LOTM_TP_ERROR_APOTHEOSIS",
            "PROJECT_LOTM_TP_FAITH_TRANSFER",
            "PROJECT_LOTM_TP_CULTURE_TRANSFER",
            "PROJECT_LOTM_TP_FAITH_TRANSFER_II",
            "PROJECT_LOTM_TP_CULTURE_TRANSFER_II",
            BE_BARBARIAN_PROJECT,
            BE_BRIBER_PROJECT,
            BE_BARON_PROJECT,
            BE_CHAOS_MENTOR_PROJECT,
            BE_COUNT_PROJECT,
            BE_FRENZY_PROJECT,
            BE_ENTROPY_PROJECT,
            BE_PRINCE_PROJECT,
            BE_TRANSFORMATION_PROJECT,
            BE_ENTHRONEMENT_PROJECT,
            BE_UNCONSECRATED_ENTHRONEMENT_PROJECT,
            BE_CHAOS_I_POLICY,
            *BE_EXTRA_POLICIES,
            CHURCH_BELIEF,
            TRUE_GOD_BELIEF,
            WEATHER_OPPOSING_ATTACH_MODIFIER,
            TECH_BASE_COMBAT_MODIFIER,
            PROMOTION_CLASS,
            *COMBAT_PROMOTIONS,
            *MOVEMENT_PROMOTIONS,
            WAR_AURA_ABILITY,
            WAR_AURA_SOURCE_V2,
            WAR_AURA_V2,
			"BUILDING_LOTM_RESCUE_SEAL_CORE",
			"MODIFIER_LOTM_RESCUE_SINGLE_CITY_INNER_DEFENSE",
			"MODIFIER_LOTM_RESCUE_SINGLE_CITY_OUTER_DEFENSE",
			"MODIFIER_LOTM_RESCUE_SINGLE_CITY_PROJECT_PRODUCTION",
			"UNIT_LOTM_RESCUE_FOOL_SAINT",
			"UNIT_LOTM_RESCUE_FOOL_ANGEL",
			"UNIT_LOTM_RESCUE_NIGHT_SAINT",
			"UNIT_LOTM_RESCUE_NIGHT_ANGEL",
			"UNIT_LOTM_RESCUE_STORM_SAINT",
			"UNIT_LOTM_RESCUE_STORM_ANGEL",
			"ABILITY_LOTM_RESCUE_GUARDIAN_NON_AGGRESSION",
			"UNIT_LOTM_RESCUE_LOST_CONTROL_LOW",
			"UNIT_LOTM_RESCUE_LOST_CONTROL_MID",
			"UNIT_LOTM_RESCUE_LOST_CONTROL_HIGH",
        },
        f"unexpected custom Types: {custom_types}",
    )
    validation.check(
        all(
            "LOTM_RP_" in value or "LOTM_PP_" in value or "LOTM_BE_" in value or "LOTM_TP_" in value or "LOTM_RESCUE_" in value
            for value in custom_types
        ),
        "custom Type lacks LOTM_RP_, LOTM_PP_, or LOTM_BE_ prefix",
    )


def validate_beliefs(validation: Validation, root: ET.Element) -> None:
    beliefs = {
        row.attrib.get("BeliefType"): row.attrib
        for row in root.findall("./Beliefs/Row")
        if row.attrib.get("BeliefType")
    }
    validation.check(
        set(beliefs) == {CHURCH_BELIEF, TRUE_GOD_BELIEF},
        f"unexpected custom beliefs: {sorted(beliefs)}",
    )
    expected_classes = {
        CHURCH_BELIEF: "BELIEF_CLASS_PANTHEON",
        TRUE_GOD_BELIEF: "BELIEF_CLASS_FOUNDER",
    }
    for belief_type, belief_class in expected_classes.items():
        attrs = beliefs.get(belief_type, {})
        validation.check(
            attrs.get("BeliefClassType") == belief_class,
            f"{belief_type} must use {belief_class}",
        )
        validation.check(
            attrs.get("Name", "").startswith("LOC_LOTM_RP_")
            or attrs.get("Name", "").startswith("LOC_BELIEF_LOTM_RP_"),
            f"{belief_type} name localization lacks LOTM_RP prefix",
        )


def validate_config(validation: Validation, root: ET.Element) -> None:
    language_parameter = root.find("./Parameters/Row[@ParameterId='LOTM_RP_TEXT_LANGUAGE']")
    validation.check(language_parameter is not None, "LOTM_RP_TEXT_LANGUAGE parameter is missing")
    if language_parameter is not None:
        expected_language_attrs = {
            "Key1": "Ruleset",
            "Key2": "RULESET_EXPANSION_2",
            "ConfigurationGroup": "Game",
            "ConfigurationId": "LOTM_RP_TEXT_LANGUAGE",
            "GroupId": "AdvancedOptions",
            "DefaultValue": "zh_Hans_CN",
            "Domain": "LOTM_RP_TEXT_LANGUAGE_VALUES",
            "ChangeableAfterGameStart": "0",
        }
        for key, value in expected_language_attrs.items():
            validation.check(
                language_parameter.attrib.get(key) == value,
                f"LOTM_RP_TEXT_LANGUAGE {key} must be {value}",
            )
        for support_key in (
            "SupportsSinglePlayer",
            "SupportsLANMultiplayer",
            "SupportsInternetMultiplayer",
            "SupportsHotSeat",
            "SupportsPlayByCloud",
        ):
            validation.check(
                language_parameter.attrib.get(support_key) == "1",
                f"LOTM_RP_TEXT_LANGUAGE must support {support_key}",
            )
    language_values = {
        row.attrib.get("Value")
        for row in root.findall("./DomainValues/Row[@Domain='LOTM_RP_TEXT_LANGUAGE_VALUES']")
    }
    validation.check(
        language_values == {"zh_Hans_CN", "en_US"},
        f"unexpected mod language values: {sorted(language_values)}",
    )

    parameter = root.find("./Parameters/Row[@ParameterId='LOTM_RP_PATH']")
    validation.check(parameter is not None, "LOTM_RP_PATH parameter is missing")
    if parameter is None:
        return
    attrs = parameter.attrib
    expected = {
        "Key1": "Ruleset",
        "Key2": "RULESET_EXPANSION_2",
        "ConfigurationGroup": "Player",
        "ConfigurationId": "LOTM_RP_PATH",
        "GroupId": "PlayerOptions",
        "DefaultValue": "NONE",
        "Domain": "LOTM_RP_PATH_VALUES",
        "SupportsHotSeat": "0",
        "SupportsPlayByCloud": "0",
    }
    for key, value in expected.items():
        validation.check(attrs.get(key) == value, f"LOTM_RP_PATH {key} must be {value}")

    values = {
        row.attrib.get("Value")
        for row in root.findall("./DomainValues/Row[@Domain='LOTM_RP_PATH_VALUES']")
    }
    validation.check(
        values == {"NONE", "PATH_RED_PRIEST", "PATH_PERFECT", "PATH_BLACK_EMPEROR"},
        f"unexpected path values: {sorted(values)}",
    )


def validate_unit(validation: Validation, unit_root: ET.Element, types_root: ET.Element) -> None:
    expected = {
        "BaseSightRange": "2",
        "BaseMoves": "3",
        "Combat": "20",
        "Domain": "DOMAIN_LAND",
        "FormationClass": "FORMATION_CLASS_LAND_COMBAT",
        "CanTrain": "false",
        "PromotionClass": PROMOTION_CLASS,
        "Maintenance": "1",
    }
    for unit_type in (UNIT_TYPE, PERFECT_UNIT_TYPE, BLACK_EMPEROR_UNIT_TYPE):
        type_row = types_root.find(f"./Types/Row[@Type='{unit_type}']")
        validation.check(
            type_row is not None and type_row.attrib.get("Kind") == "KIND_UNIT",
            f"{unit_type} Type is invalid",
        )
        unit = unit_root.find(f"./Units/Row[@UnitType='{unit_type}']")
        validation.check(unit is not None, f"{unit_type} row is missing")
        if unit is None:
            continue
        attrs = unit.attrib
        for key, value in expected.items():
            validation.check(attrs.get(key) == value, f"{unit_type} {key} must be {value}")
        validation.check(
            "StrategicResource" not in attrs,
            f"{unit_type} must not require a strategic resource",
        )
        validation.check(
            "PurchaseYield" not in attrs,
            f"{unit_type} must not be directly purchasable",
        )
        xp2 = unit_root.find(f"./Units_XP2/Row[@UnitType='{unit_type}']")
        validation.check(xp2 is not None, f"{unit_type} Units_XP2 row is missing")
        if xp2 is not None:
            validation.check(
                xp2.attrib.get("CanFormMilitaryFormation") == "false",
                f"{unit_type} must not form Corps or Armies",
            )
            validation.check(
                xp2.attrib.get("MajorCivOnly") == "true",
                f"{unit_type} must be major-civilization only",
            )
        tags = {
            row.attrib.get("Tag")
            for row in unit_root.findall(f"./TypeTags/Row[@Type='{unit_type}']")
        }
        validation.check("CLASS_RECON" in tags, f"{unit_type} lacks CLASS_RECON tag")


def validate_promotions(validation: Validation, root: ET.Element) -> None:
    promotion_class = root.find(
        f"./UnitPromotionClasses/Row[@PromotionClassType='{PROMOTION_CLASS}']"
    )
    validation.check(promotion_class is not None, "path-holder promotion class is missing")

    rows = {
        row.attrib.get("UnitPromotionType"): row.attrib
        for row in root.findall("./UnitPromotions/Row")
    }
    expected_types = set(COMBAT_PROMOTIONS + MOVEMENT_PROMOTIONS)
    validation.check(set(rows) == expected_types, f"unexpected path-holder promotions: {sorted(rows)}")
    for level, promotion_type in enumerate(COMBAT_PROMOTIONS, 1):
        attrs = rows.get(promotion_type, {})
        validation.check(
            attrs.get("PromotionClass") == PROMOTION_CLASS
            and attrs.get("Level") == str(level)
            and attrs.get("Column") == "1",
            f"{promotion_type} must occupy left branch level {level}",
        )
    for level, promotion_type in enumerate(MOVEMENT_PROMOTIONS, 1):
        attrs = rows.get(promotion_type, {})
        validation.check(
            attrs.get("PromotionClass") == PROMOTION_CLASS
            and attrs.get("Level") == str(level)
            and attrs.get("Column") == "3",
            f"{promotion_type} must occupy right branch level {level}",
        )

    prereqs = {
        (row.attrib.get("UnitPromotion"), row.attrib.get("PrereqUnitPromotion"))
        for row in root.findall("./UnitPromotionPrereqs/Row")
    }
    expected_prereqs = {
        (COMBAT_PROMOTIONS[1], COMBAT_PROMOTIONS[0]),
        (COMBAT_PROMOTIONS[2], COMBAT_PROMOTIONS[1]),
        (MOVEMENT_PROMOTIONS[1], MOVEMENT_PROMOTIONS[0]),
        (MOVEMENT_PROMOTIONS[2], MOVEMENT_PROMOTIONS[1]),
    }
    validation.check(prereqs == expected_prereqs, "promotion branches must advance independently")

    attached = {
        row.attrib.get("UnitPromotionType"): row.attrib.get("ModifierId")
        for row in root.findall("./UnitPromotionModifiers/Row")
    }
    arguments = {
        row.attrib.get("ModifierId"): row.attrib.get("Value")
        for row in root.findall("./ModifierArguments/Row[@Name='Amount']")
    }
    validation.check(
        [arguments.get(attached.get(p)) for p in COMBAT_PROMOTIONS] == ["10", "15", "15"],
        "Combat Thrill 1/2/3 must grant +10/+15/+15 base Combat Strength",
    )
    modifier_types = {
        row.attrib.get("ModifierId"): row.attrib.get("ModifierType")
        for row in root.findall("./Modifiers/Row")
    }
    validation.check(
        all(
            modifier_types.get(attached.get(p))
            == "MODIFIER_UNIT_ADJUST_BASE_COMBAT_STRENGTH"
            for p in COMBAT_PROMOTIONS
        ),
        "Combat Thrill 1/2/3 must modify panel base Combat Strength",
    )
    validation.check(
        attached.get(COMBAT_PROMOTIONS[2]) == "LOTM_PROMOTION_COMBAT_3_STRENGTH",
        "Combat Thrill 3 must use its direct promotion-owned strength modifier",
    )
    validation.check(
        root.find(
            "./UnitAbilityModifiers/Row"
            f"[@UnitAbilityType='{WAR_AURA_SOURCE_V2}']"
            "[@ModifierId='LOTM_PROMOTION_COMBAT_3_WAR_AURA_GRANT_V2']"
        )
        is not None,
        "the synchronized War Aura source ability must own the V2 grant modifier",
    )
    validation.check(
        root.find(
            f"./TypeTags/Row[@Type='{WAR_AURA_SOURCE_V2}']"
            "[@Tag='CLASS_LOTM_RP_WAR_AURA_SOURCE_V2']"
        )
        is not None,
        "the synchronized source ability must expose only its dedicated source tag",
    )
    units_root = ET.parse(ROOT / "Gameplay" / "LOTM_RP_Units.xml").getroot()
    source_tagged_units = {
        row.attrib.get("Type")
        for row in units_root.findall(
            "./TypeTags/Row[@Tag='CLASS_LOTM_RP_WAR_AURA_SOURCE_V2']"
        )
    }
    validation.check(
        source_tagged_units == {UNIT_TYPE, PERFECT_UNIT_TYPE, BLACK_EMPEROR_UNIT_TYPE},
        "the War Aura source tag must identify exactly the three pathway holder unit types",
    )
    church_sql = strip_trace((ROOT / "Gameplay" / "LOTM_WORLD_Churches.sql").read_text(
        encoding="utf-8"
    ))
    validation.check(
        "WHERE tt.Tag<>'CLASS_LOTM_RP_WAR_AURA_SOURCE_V2'" in church_sql,
        "Fool all-unit sight abilities must exclude the identity-bearing War Aura source tag",
    )
    validation.check(
        root.find(
            f"./TypeTags/Row[@Type='{WAR_AURA_V2}']"
            "[@Tag='CLASS_ALL_COMBAT_UNITS']"
        ) is not None,
        "War Aura V2 must exclude civilians through CLASS_ALL_COMBAT_UNITS",
    )
    grant_v2 = root.find(
        "./Modifiers/Row"
        "[@ModifierId='LOTM_PROMOTION_COMBAT_3_WAR_AURA_GRANT_V2']"
    )
    strength_v2 = root.find(
        "./Modifiers/Row"
        "[@ModifierId='LOTM_PROMOTION_COMBAT_3_WAR_AURA_STRENGTH_V2']"
    )
    validation.check(
        grant_v2 is not None
        and grant_v2.attrib.get("ModifierType") == "MODIFIER_PLAYER_UNITS_GRANT_ABILITY"
        and grant_v2.attrib.get("SubjectRequirementSetId")
        == "LOTM_PROMOTION_WAR_AURA_GRANT_RANGE_V2"
        and root.find(
            "./ModifierArguments/Row"
            "[@ModifierId='LOTM_PROMOTION_COMBAT_3_WAR_AURA_GRANT_V2']"
            f"[@Name='AbilityType'][@Value='{WAR_AURA_V2}']"
        ) is not None,
        "the synchronized source must grant War Aura V2 through its owner-range set",
    )
    validation.check(
        root.find(
            "./Requirements/Row"
            "[@RequirementId='LOTM_PROMOTION_REQUIRES_WAR_AURA_OWNER_RANGE_V2']"
            "[@RequirementType='REQUIREMENT_PLOT_ADJACENT_TO_OWNER']"
        ) is not None
        and root.find(
            "./RequirementArguments/Row"
            "[@RequirementId='LOTM_PROMOTION_REQUIRES_WAR_AURA_OWNER_RANGE_V2']"
            "[@Name='MinDistance'][@Value='0']"
        ) is not None
        and root.find(
            "./RequirementArguments/Row"
            "[@RequirementId='LOTM_PROMOTION_REQUIRES_WAR_AURA_OWNER_RANGE_V2']"
            "[@Name='MaxDistance'][@Value='2']"
        ) is not None,
        "War Aura V2 grant range must copy the Firaxis AOE owner/adjacent shell",
    )
    validation.check(
        strength_v2 is not None
        and strength_v2.attrib.get("ModifierType")
        == "MODIFIER_UNIT_ADJUST_COMBAT_STRENGTH"
        and strength_v2.attrib.get("SubjectRequirementSetId")
        == "LOTM_PROMOTION_WAR_AURA_ADJACENT_REQUIREMENTS_V2"
        and arguments.get("LOTM_PROMOTION_COMBAT_3_WAR_AURA_STRENGTH_V2") == "0"
        and root.find(
            "./UnitAbilityModifiers/Row"
            f"[@UnitAbilityType='{WAR_AURA_V2}']"
            "[@ModifierId='LOTM_PROMOTION_COMBAT_3_WAR_AURA_STRENGTH_V2']"
        ) is not None
        and root.find(
            "./ModifierStrings/Row"
            "[@ModifierId='LOTM_PROMOTION_COMBAT_3_WAR_AURA_STRENGTH_V2']"
            "[@Context='Preview']"
        ) is not None,
        "the retired War Aura V2 recipient modifier must remain neutralized",
    )
    validation.check(
        root.find(
            "./Requirements/Row"
            "[@RequirementId='LOTM_PROMOTION_REQUIRES_ADJACENT_WAR_AURA_SOURCE_V2']"
            "[@RequirementType='REQUIREMENT_PLOT_ADJACENT_FRIENDLY_UNIT_TAG_MATCHES']"
        ) is not None
        and root.find(
            "./RequirementArguments/Row"
            "[@RequirementId='LOTM_PROMOTION_REQUIRES_ADJACENT_WAR_AURA_SOURCE_V2']"
            "[@Name='Tag'][@Value='CLASS_LOTM_RP_WAR_AURA_SOURCE_V2']"
        ) is not None
        and root.find(
            "./RequirementArguments/Row"
            "[@RequirementId='LOTM_PROMOTION_REQUIRES_ADJACENT_WAR_AURA_SOURCE_V2']"
            "[@Name='IncludeCenter'][@Value='false']"
        ) is not None,
        "War Aura V2 strength must find an adjacent synchronized source and exclude center",
    )
    validation.check(
        modifier_types.get("LOTM_PROMOTION_COMBAT_3_WAR_AURA_STRENGTH")
        == "MODIFIER_UNIT_ADJUST_COMBAT_STRENGTH"
        and arguments.get("LOTM_PROMOTION_COMBAT_3_WAR_AURA_STRENGTH") == "0",
        "the serialized legacy War Aura strength modifier must be neutralized",
    )
    validation.check(
        [arguments.get(attached.get(p)) for p in MOVEMENT_PROMOTIONS] == ["1", "2", "2"],
        "movement promotion branch must grant +1/+2/+2",
    )

    camp_sql = strip_trace((ROOT / "Gameplay" / "LOTM_WORLD_Monsters.sql").read_text(
        encoding="utf-8"
    ))
    validation.check(
        "BARBARIAN_CAMP_ODDS_OF_NEW_CAMP_SPAWNING" in camp_sql
        and "SET Value = 9" in camp_sql
        and "BARBARIAN_CAMP_MAX_PER_MAJOR_CIV" not in camp_sql
        and "BARBARIAN_CAMP_MINIMUM_DISTANCE" not in camp_sql,
        "established monster SQL must raise only the engine-owned camp spawn roll from 2 to 9",
    )


def validate_icons_and_art(validation: Validation, parsed: dict[Path, ET.Element]) -> None:
    icons = parsed[ROOT / "Art" / "LOTM_RP_Icons.xml"]
    definitions = {row.attrib.get("Name"): row.attrib for row in icons.findall("./IconDefinitions/Row")}
    expected = {
        "ICON_LOTM_RP_RED_PRIEST_MARK": (
            "ICON_ATLAS_LOTM_RP_RED_PRIEST_MARK",
            "0",
        ),
        "ICON_LOTM_PP_PERFECT_MARK": (
            "ICON_ATLAS_LOTM_PP_PERFECT_MARK",
            "0",
        ),
        "ICON_LOTM_BE_BLACK_EMPEROR_MARK": (
            "ICON_ATLAS_LOTM_BE_BLACK_EMPEROR_MARK",
            "0",
        ),
        "ICON_UNIT_LOTM_RP_PATH_HOLDER": ("ICON_ATLAS_LOTM_RP_RED_PRIEST_GAME", "0"),
        "ICON_UNIT_LOTM_RP_PATH_HOLDER_FOW": ("ICON_ATLAS_LOTM_RP_RED_PRIEST_GAME", "0"),
        "ICON_UNIT_LOTM_RP_PATH_HOLDER_WHITE": ("ICON_ATLAS_LOTM_RP_RED_PRIEST_GAME", "0"),
        "ICON_UNIT_LOTM_RP_PATH_HOLDER_BLACK": ("ICON_ATLAS_LOTM_RP_RED_PRIEST_GAME", "0"),
        "ICON_UNIT_LOTM_RP_PATH_HOLDER_PORTRAIT": ("ICON_ATLAS_LOTM_RP_RED_PRIEST_GAME", "0"),
        "ICON_UNIT_LOTM_PP_PATH_HOLDER": ("ICON_ATLAS_LOTM_PP_PERFECT_GAME", "0"),
        "ICON_UNIT_LOTM_PP_PATH_HOLDER_FOW": ("ICON_ATLAS_LOTM_PP_PERFECT_GAME", "0"),
        "ICON_UNIT_LOTM_PP_PATH_HOLDER_WHITE": ("ICON_ATLAS_LOTM_PP_PERFECT_GAME", "0"),
        "ICON_UNIT_LOTM_PP_PATH_HOLDER_BLACK": ("ICON_ATLAS_LOTM_PP_PERFECT_GAME", "0"),
        "ICON_UNIT_LOTM_PP_PATH_HOLDER_PORTRAIT": ("ICON_ATLAS_LOTM_PP_PERFECT_GAME", "0"),
        "ICON_UNIT_LOTM_BE_PATH_HOLDER": ("ICON_ATLAS_LOTM_BE_BLACK_EMPEROR_GAME", "0"),
        "ICON_UNIT_LOTM_BE_PATH_HOLDER_FOW": ("ICON_ATLAS_LOTM_BE_BLACK_EMPEROR_GAME", "0"),
        "ICON_UNIT_LOTM_BE_PATH_HOLDER_WHITE": ("ICON_ATLAS_LOTM_BE_BLACK_EMPEROR_GAME", "0"),
        "ICON_UNIT_LOTM_BE_PATH_HOLDER_BLACK": ("ICON_ATLAS_LOTM_BE_BLACK_EMPEROR_GAME", "0"),
        "ICON_UNIT_LOTM_BE_PATH_HOLDER_PORTRAIT": ("ICON_ATLAS_LOTM_BE_BLACK_EMPEROR_GAME", "0"),
        "ICON_BELIEF_LOTM_RP_ESTABLISH_CHURCH": ("ICON_ATLAS_BELIEFS_PATHEON", "24"),
        "ICON_BELIEF_LOTM_RP_TRUE_GOD_CHURCH": ("ICON_ATLAS_BELIEFS_PATHEON", "24"),
    }
    for name, (atlas, index) in expected.items():
        row = definitions.get(name)
        validation.check(row is not None, f"missing icon mapping: {name}")
        if row is not None:
            validation.check(
                row.get("Atlas") == atlas and row.get("Index") == index,
                f"wrong icon mapping for {name}",
            )

    red_projects = (
        PROVOKER_PROJECT,
        PYROMANIAC_PROJECT,
        CONSPIRATOR_PROJECT,
        REAPER_PROJECT,
        IRONBLOOD_PROJECT,
        WAR_BISHOP_PROJECT,
        WEATHER_WARLOCK_PROJECT,
        CONQUEROR_PROJECT,
        WAR_FESTIVAL_PROJECT,
        UNCONSECRATED_WAR_FESTIVAL_PROJECT,
    )
    perfect_projects = (
        PP_ARCHAEOLOGIST_PROJECT,
        PP_APPRAISER_PROJECT,
        PP_MECHANICAL_PROJECT,
        PP_ASTRONOMER_PROJECT,
        PP_ALCHEMIST_PROJECT,
        PP_MYSTERY_SCHOLAR_PROJECT,
        PP_KNOWLEDGE_MENTOR_PROJECT,
        PP_ENLIGHTENER_PROJECT,
        PP_CIVILIZATION_ASCENSION_PROJECT,
        PP_UNCONSECRATED_ASCENSION_PROJECT,
    )
    black_emperor_projects = (
        BE_BARBARIAN_PROJECT,
        BE_BRIBER_PROJECT,
        BE_BARON_PROJECT,
        BE_CHAOS_MENTOR_PROJECT,
        BE_COUNT_PROJECT,
        BE_FRENZY_PROJECT,
        BE_ENTROPY_PROJECT,
        BE_PRINCE_PROJECT,
        BE_TRANSFORMATION_PROJECT,
        BE_ENTHRONEMENT_PROJECT,
        BE_UNCONSECRATED_ENTHRONEMENT_PROJECT,
    )
    for project_type, atlas in (
        *((project, "ICON_ATLAS_LOTM_RP_RED_PRIEST_GAME") for project in red_projects),
        *((project, "ICON_ATLAS_LOTM_PP_PERFECT_GAME") for project in perfect_projects),
        *((project, "ICON_ATLAS_LOTM_BE_BLACK_EMPEROR_GAME") for project in black_emperor_projects),
    ):
        name = f"ICON_{project_type}"
        row = definitions.get(name)
        validation.check(row is not None, f"missing project icon mapping: {name}")
        if row is not None:
            validation.check(
                row.get("Atlas") == atlas and row.get("Index") == "0",
                f"wrong pathway project icon mapping for {name}",
            )
    for policy_type in (BE_CHAOS_I_POLICY, *BE_EXTRA_POLICIES):
        name = f"ICON_{policy_type}"
        row = definitions.get(name)
        validation.check(row is not None, f"missing Black Emperor policy icon mapping: {name}")
        if row is not None:
            validation.check(
                row.get("Atlas") == "ICON_ATLAS_LOTM_BE_BLACK_EMPEROR_GAME"
                and row.get("Index") == "0",
                f"wrong Black Emperor policy icon mapping for {name}",
            )

    textures = {
        (row.attrib.get("Name"), row.attrib.get("IconSize")): row.attrib
        for row in icons.findall("./IconTextureAtlases/Row")
    }
    for icon_size, filename in (
        ("40", "LOTM_RP_RedPriestMarkCentered40.dds"),
        ("384", "LOTM_RP_RedPriestMarkCentered384.dds"),
        ("512", "LOTM_RP_RedPriestMarkCentered512.dds"),
        ("640", "LOTM_RP_RedPriestMarkCentered640.dds"),
        ("768", "LOTM_RP_RedPriestMarkCentered768.dds"),
    ):
        row = textures.get(("ICON_ATLAS_LOTM_RP_RED_PRIEST_MARK", icon_size))
        validation.check(
            row is not None
            and row.get("IconsPerRow") == "1"
            and row.get("IconsPerColumn") == "1"
            and row.get("Filename") == filename,
            f"Red Priest icon atlas lacks the {icon_size}px custom texture",
        )
        path = ROOT / "Art" / filename
        validation.require_file(path, f"{icon_size}px Red Priest DDS")
        if path.is_file():
            header = path.read_bytes()[:20]
            valid_header = len(header) == 20 and header[:4] == b"DDS "
            validation.check(valid_header, f"{filename} is not a DDS texture")
            if valid_header:
                height, width = struct.unpack_from("<II", header, 12)
                validation.check(
                    width == int(icon_size) and height == int(icon_size),
                    f"{filename} dimensions must be {icon_size}x{icon_size}",
                )

    for icon_size in ("40", "384", "512", "640", "768"):
        perfect_filename = f"LOTM_PP_PerfectMarkCentered{icon_size}.dds"
        perfect_row = textures.get(("ICON_ATLAS_LOTM_PP_PERFECT_MARK", icon_size))
        validation.check(
            perfect_row is not None
            and perfect_row.get("IconsPerRow") == "1"
            and perfect_row.get("IconsPerColumn") == "1"
            and perfect_row.get("Filename") == perfect_filename,
            f"Perfect Path icon atlas lacks the {icon_size}px user-supplied mark",
        )
        perfect_path = ROOT / "Art" / perfect_filename
        validation.require_file(perfect_path, f"{icon_size}px Perfect Path DDS")
        if perfect_path.is_file():
            header = perfect_path.read_bytes()[:20]
            valid_header = len(header) == 20 and header[:4] == b"DDS "
            validation.check(valid_header, f"{perfect_filename} is not a DDS texture")
            if valid_header:
                height, width = struct.unpack_from("<II", header, 12)
                validation.check(
                    width == int(icon_size) and height == int(icon_size),
                    f"{perfect_filename} dimensions must be {icon_size}x{icon_size}",
                )

        black_filename = f"LOTM_BE_BlackEmperorMarkCentered{icon_size}.dds"
        black_row = textures.get(("ICON_ATLAS_LOTM_BE_BLACK_EMPEROR_MARK", icon_size))
        validation.check(
            black_row is not None
            and black_row.get("IconsPerRow") == "1"
            and black_row.get("IconsPerColumn") == "1"
            and black_row.get("Filename") == black_filename,
            f"Black Emperor icon atlas lacks the {icon_size}px user-supplied mark",
        )
        black_path = ROOT / "Art" / black_filename
        validation.require_file(black_path, f"{icon_size}px Black Emperor DDS")
        if black_path.is_file():
            header = black_path.read_bytes()[:20]
            valid_header = len(header) == 20 and header[:4] == b"DDS "
            validation.check(valid_header, f"{black_filename} is not a DDS texture")
            if valid_header:
                height, width = struct.unpack_from("<II", header, 12)
                validation.check(
                    width == int(icon_size) and height == int(icon_size),
                    f"{black_filename} dimensions must be {icon_size}x{icon_size}",
                )

    game_icon_sizes = (22, 30, 32, 38, 50, 64, 70, 80, 95, 200, 256)
    for atlas, prefix in (
        ("ICON_ATLAS_LOTM_RP_RED_PRIEST_GAME", "LOTM_RP_RedPriest"),
        ("ICON_ATLAS_LOTM_PP_PERFECT_GAME", "LOTM_PP_Perfect"),
        ("ICON_ATLAS_LOTM_BE_BLACK_EMPEROR_GAME", "LOTM_BE_BlackEmperor"),
    ):
        for size in game_icon_sizes:
            filename = f"{prefix}GameIcon{size}.dds"
            row = textures.get((atlas, str(size)))
            validation.check(
                row is not None
                and row.get("IconsPerRow") == "1"
                and row.get("IconsPerColumn") == "1"
                and row.get("Filename") == filename,
                f"{atlas} lacks the {size}px one-cell texture",
            )
            path = ROOT / "Art" / filename
            validation.require_file(path, f"{size}px pathway game icon DDS")
            if path.is_file():
                header = path.read_bytes()[:20]
                valid_header = len(header) == 20 and header[:4] == b"DDS "
                validation.check(valid_header, f"{filename} is not a DDS texture")
                if valid_header:
                    height, width = struct.unpack_from("<II", header, 12)
                    validation.check(
                        width == size and height == size,
                        f"{filename} dimensions must be {size}x{size}",
                    )

    art_text = strip_trace((ROOT / "Art" / "LOTM_RP_Units.artdef").read_text(encoding="utf-8"))
    for marker in (
        'm_Name text="UNIT_LOTM_RP_PATH_HOLDER"',
        'm_Name text="UNIT_LOTM_PP_PATH_HOLDER"',
        'm_Name text="UNIT_LOTM_BE_PATH_HOLDER"',
        'm_ElementName text="Scout"',
        'm_ElementName text="ScoutDog"',
        'm_ElementName text="UNIT_ANCIENTEMBARK_SINGLE"',
    ):
        validation.check(marker in art_text, f"ArtDef reference missing: {marker}")

    dep_text = strip_trace((ROOT / "Art" / "LOTM_RP.dep").read_text(encoding="utf-8"))
    validation.check("LOTM_RP_Units.artdef" in dep_text, "dep does not reference custom ArtDef")
    validation.check("units/units.blp" in dep_text, "dep does not reference original Unit library")


def validate_localization(validation: Validation, parsed: dict[Path, ET.Element]) -> None:
    required_tags = {
        "LOC_LOTM_RP_MOD_NAME",
        "LOC_LOTM_RP_PATH_NAME",
        "LOC_LOTM_RP_PATH_NONE_NAME",
        "LOC_LOTM_RP_PATH_RED_PRIEST_NAME",
        "LOC_LOTM_BE_PATH_NAME",
        "LOC_LOTM_BE_PATH_DESCRIPTION",
        "LOC_UNIT_LOTM_RP_PATH_HOLDER_NAME",
        "LOC_UNIT_LOTM_RP_PATH_HOLDER_DESCRIPTION",
        "LOC_UNIT_LOTM_BE_PATH_HOLDER_NAME",
        "LOC_UNIT_LOTM_BE_PATH_HOLDER_DESCRIPTION",
        "LOC_ABILITY_LOTM_RP_HUNTER_INSTINCT_NAME",
        "LOC_ABILITY_LOTM_RP_HUNTER_INSTINCT_DESCRIPTION",
        "LOC_ABILITY_LOTM_RP_PROVOKER_NAME",
        "LOC_ABILITY_LOTM_RP_PROVOKER_DESCRIPTION",
        "LOC_ABILITY_LOTM_RP_PROVOKER_GARRISONED_NAME",
        "LOC_ABILITY_LOTM_RP_PROVOKER_GARRISONED_DESCRIPTION",
        "LOC_PROJECT_LOTM_RP_PROVOKER_POTION_NAME",
        "LOC_PROJECT_LOTM_RP_PROVOKER_POTION_SHORT_NAME",
        "LOC_PROJECT_LOTM_RP_PROVOKER_POTION_DESCRIPTION",
        "LOC_PROJECT_LOTM_RP_PYROMANIAC_POTION_NAME",
        "LOC_PROJECT_LOTM_RP_PYROMANIAC_POTION_SHORT_NAME",
        "LOC_PROJECT_LOTM_RP_PYROMANIAC_POTION_DESCRIPTION",
        "LOC_PROJECT_LOTM_RP_CONQUEROR_POTION_NAME",
        "LOC_PROJECT_LOTM_RP_CONQUEROR_POTION_SHORT_NAME",
        "LOC_PROJECT_LOTM_RP_CONQUEROR_POTION_DESCRIPTION",
        "LOC_PROJECT_LOTM_RP_WAR_FESTIVAL_NAME",
        "LOC_PROJECT_LOTM_RP_WAR_FESTIVAL_SHORT_NAME",
        "LOC_PROJECT_LOTM_RP_WAR_FESTIVAL_DESCRIPTION",
        "LOC_LOTM_RP_SEQUENCE0_CEREMONY_TITLE",
        "LOC_LOTM_RP_SEQUENCE0_CEREMONY_LINE_1",
        "LOC_LOTM_RP_SEQUENCE0_CEREMONY_LINE_2",
        "LOC_LOTM_RP_SEQUENCE0_CEREMONY_LINE_3",
        "LOC_LOTM_RP_SEQUENCE0_CEREMONY_LINE_4",
        "LOC_LOTM_PP_SEQUENCE0_CEREMONY_TITLE",
        "LOC_LOTM_PP_SEQUENCE0_CEREMONY_LINE_1",
        "LOC_LOTM_PP_SEQUENCE0_CEREMONY_LINE_2",
        "LOC_LOTM_PP_SEQUENCE0_CEREMONY_LINE_3",
        "LOC_LOTM_RP_PREVIEW_HUNTER_COMBAT",
        "LOC_LOTM_RP_PREVIEW_PROVOKER_AURA",
        "LOC_LOTM_RP_PREVIEW_PROVOKER_DEFENSE",
        "LOC_LOTM_RP_PREVIEW_PROVOKER_GARRISON",
        "LOC_PROMOTION_CLASS_LOTM_RP_PATH_HOLDER_NAME",
        "LOC_LOTM_RP_PROBE_BUTTON",
        "LOC_LOTM_RP_PROBE_TOOLTIP",
        "LOC_LOTM_RP_HUD_TITLE",
        "LOC_LOTM_RP_HUD_SEQUENCE",
        "LOC_LOTM_RP_HUD_PROGRESS_SINGLE",
        "LOC_LOTM_RP_HUD_PROGRESS_COMPLETE",
        "LOC_LOTM_RP_HUD_SKILLS_S9",
        "LOC_LOTM_RP_HUD_SKILLS_S8",
        "LOC_LOTM_RP_HUD_SKILLS_S7",
        "LOC_LOTM_RP_HUD_SKILLS_S1",
        "LOC_LOTM_RP_HUD_SKILLS_S0",
        "LOC_LOTM_RP_HUD_NEXT_S9",
        "LOC_LOTM_RP_HUD_NEXT_S8",
        "LOC_LOTM_RP_HUD_NEXT_S7",
        "LOC_LOTM_RP_HUD_NEXT_S5_UNLOCKED",
        "LOC_LOTM_RP_HUD_NEXT_S2",
        "LOC_LOTM_RP_HUD_NEXT_S1",
        "LOC_LOTM_RP_HUD_NEXT_S0",
        "LOC_LOTM_RP_HUD_DIGEST_S9",
        "LOC_LOTM_RP_HUD_DIGEST_S8",
        "LOC_LOTM_RP_HUD_DIGEST_S7",
        "LOC_LOTM_RP_HUD_DIGEST_S6",
        "LOC_LOTM_RP_HUD_DIGEST_S5",
        "LOC_LOTM_RP_HUD_DIGEST_S4",
        "LOC_LOTM_RP_HUD_DIGEST_S3",
        "LOC_LOTM_RP_HUD_DIGEST_S2",
        "LOC_LOTM_RP_HUD_DIGEST_S1",
        "LOC_LOTM_RP_HUD_DIGEST_S0",
        "LOC_LOTM_RP_HUD_ARSON",
        "LOC_LOTM_RP_ARSON_READY",
        "LOC_LOTM_RP_ARSON_COOLDOWN",
        "LOC_LOTM_RP_ARSON_BUTTON",
        "LOC_LOTM_RP_ARSON_BUTTON_COOLDOWN",
        "LOC_LOTM_RP_ARSON_TOOLTIP",
        "LOC_LOTM_RP_ARSON_DISABLED_COOLDOWN",
        "LOC_LOTM_RP_ARSON_DISABLED_INACTIVE_TURN",
        "LOC_LOTM_RP_ARSON_DISABLED_DEAD",
        "LOC_LOTM_RP_ARSON_DISABLED_NO_TARGET",
        "LOC_LOTM_RP_ARSON_TARGET_HINT",
        "LOC_LOTM_RP_ARSON_SUCCESS",
        "LOC_LOTM_RP_PATH_CHOICE_TITLE",
        "LOC_LOTM_RP_PATH_CHOICE_BODY",
        "LOC_LOTM_RP_PATH_CHOICE_ENABLE",
        "LOC_LOTM_RP_PATH_CHOICE_NONE",
        "LOC_LOTM_RP_LAUNCH_TOOLTIP",
        "LOC_LOTM_RP_DETAILS_TITLE",
        "LOC_LOTM_RP_DETAILS_PATH_DESCRIPTION",
        "LOC_LOTM_RP_DETAILS_HERO_ACTIVE",
        "LOC_LOTM_RP_DETAILS_HERO_RESPAWN",
        "LOC_LOTM_RP_DETAILS_HERO_PENDING",
        "LOC_LOTM_RP_DETAILS_LOCATE_HERO",
        "LOC_LOTM_RP_DETAILS_EFFECTS_TITLE",
        "LOC_LOTM_RP_DETAILS_EFFECTS_S9",
        "LOC_LOTM_RP_DETAILS_EFFECTS_S8",
        "LOC_LOTM_RP_DETAILS_EFFECTS_S7",
        "LOC_LOTM_RP_DETAILS_EFFECTS_S1",
        "LOC_LOTM_RP_DETAILS_EFFECTS_S0",
        "LOC_BELIEF_LOTM_RP_ESTABLISH_CHURCH_NAME",
        "LOC_BELIEF_LOTM_RP_ESTABLISH_CHURCH_DESCRIPTION",
        "LOC_BELIEF_LOTM_RP_TRUE_GOD_CHURCH_NAME",
        "LOC_BELIEF_LOTM_RP_TRUE_GOD_CHURCH_DESCRIPTION",
    }
    for promotion_type in COMBAT_PROMOTIONS + MOVEMENT_PROMOTIONS:
        required_tags.add(f"LOC_{promotion_type}_NAME")
        required_tags.add(f"LOC_{promotion_type}_DESCRIPTION")
    for sequence in range(10):
        required_tags.update(
            {
                f"LOC_LOTM_PP_HUD_SKILLS_S{sequence}",
                f"LOC_LOTM_PP_HUD_NEXT_S{sequence}",
                f"LOC_LOTM_PP_HUD_DIGEST_S{sequence}",
                f"LOC_LOTM_PP_DETAILS_EFFECTS_S{sequence}",
            }
        )
    for sequence in range(10):
        required_tags.update(
            {
                f"LOC_LOTM_BE_HUD_SKILLS_S{sequence}",
                f"LOC_LOTM_BE_HUD_NEXT_S{sequence}",
                f"LOC_LOTM_BE_HUD_DIGEST_S{sequence}",
                f"LOC_LOTM_BE_DETAILS_EFFECTS_S{sequence}",
            }
        )
    required_tags.update(
        {
            "LOC_LOTM_BE_PATH_CHOICE_BLACK_EMPEROR",
            "LOC_LOTM_BE_DETAILS_TITLE",
            "LOC_LOTM_BE_DETAILS_PATH_DESCRIPTION",
            "LOC_LOTM_BE_HUD_SEQUENCE",
            "LOC_LOTM_BE_PREVIEW_MIGHT_STRENGTH",
        }
    )
    for project in (
        "BARBARIAN_POTION",
        "BRIBER_POTION",
        "BARON_OF_CORRUPTION_POTION",
        "CHAOS_MENTOR_POTION",
        "COUNT_OF_CORRUPTION_POTION",
        "FRENZY_MAGE_POTION",
        "DUKE_OF_ENTROPY_POTION",
        "PRINCE_OF_ABOLITION_POTION",
        "TRANSFORMATION",
        "ENTHRONEMENT",
        "ENTHRONEMENT_UNCONSECRATED",
    ):
        required_tags.update(
            {
                f"LOC_PROJECT_LOTM_BE_{project}_NAME",
                f"LOC_PROJECT_LOTM_BE_{project}_SHORT_NAME",
                f"LOC_PROJECT_LOTM_BE_{project}_DESCRIPTION",
            }
        )
    required_tags.update(
        {
            "LOC_POLICY_LOTM_BE_CHAOS_I_NAME",
            "LOC_POLICY_LOTM_BE_CHAOS_I_DESCRIPTION",
            *(
                f"LOC_{policy}_NAME" for policy in BE_EXTRA_POLICIES
            ),
            *(
                f"LOC_{policy}_DESCRIPTION" for policy in BE_EXTRA_POLICIES
            ),
        }
    )
    for project in (
        "MYSTERY_SCHOLAR_POTION",
        "KNOWLEDGE_MENTOR_POTION",
        "ENLIGHTENER_POTION",
        "CIVILIZATION_ASCENSION",
    ):
        required_tags.update(
            {
                f"LOC_PROJECT_LOTM_PP_{project}_NAME",
                f"LOC_PROJECT_LOTM_PP_{project}_SHORT_NAME",
                f"LOC_PROJECT_LOTM_PP_{project}_DESCRIPTION",
            }
        )
    for tag_prefix in (
        "LOC_PROJECT_LOTM_RP_WAR_FESTIVAL_UNCONSECRATED",
        "LOC_PROJECT_LOTM_PP_CIVILIZATION_ASCENSION_UNCONSECRATED",
    ):
        required_tags.update(
            {
                f"{tag_prefix}_NAME",
                f"{tag_prefix}_SHORT_NAME",
                f"{tag_prefix}_DESCRIPTION",
            }
        )
    by_language: dict[str, set[str]] = {"en_US": set(), "zh_Hans_CN": set()}
    text_by_language: dict[str, dict[str, str]] = {"en_US": {}, "zh_Hans_CN": {}}
    localized_entries: list[tuple[str, str]] = []
    for path, root in parsed.items():
        if "Text" not in path.parts:
            continue
        for row in root.findall(".//LocalizedText/Row"):
            language = row.attrib.get("Language")
            tag = row.attrib.get("Tag")
            if language in by_language and tag:
                localized_entries.append((language, tag))
                by_language[language].add(tag)
                text_node = row.find("./Text")
                text_by_language[language][tag] = (
                    text_node.text if text_node is not None and text_node.text else ""
                )
    duplicate_entries = sorted(
        f"{language}:{tag}"
        for (language, tag), count in Counter(localized_entries).items()
        if count > 1
    )
    validation.check(
        not duplicate_entries,
        f"duplicate localized Tag/Language entries: {duplicate_entries}",
    )
    for language, tags in by_language.items():
        validation.check(required_tags <= tags, f"{language} is missing localization: {sorted(required_tags - tags)}")

    for language, texts in text_by_language.items():
        hero_active = texts.get("LOC_LOTM_RP_DETAILS_HERO_ACTIVE", "")
        validation.check(
            "UnitID" not in hero_active and "单位ID" not in hero_active,
            f"{language} active-hero text must not expose the internal unit ID",
        )
        effects_s7 = texts.get("LOC_LOTM_RP_DETAILS_EFFECTS_S7", "")
        arson_name = "纵火" if language == "zh_Hans_CN" else "Arson"
        provoker_name = "挑衅者" if language == "zh_Hans_CN" else "Provoker"
        hunter_name = "猎人本能" if language == "zh_Hans_CN" else "Hunter's Instinct"
        validation.check(
            effects_s7.find(arson_name) >= 0
            and effects_s7.find(arson_name) < effects_s7.find(provoker_name)
            < effects_s7.find(hunter_name),
            f"{language} sequence-7 effects must list current-to-previous skills",
        )
        validation.check(
            "继承序列" not in effects_s7 and "retain all" not in effects_s7,
            f"{language} sequence-7 effects must fully describe inherited skills",
        )


def validate_selected_language_packs(
    validation: Validation,
    parsed: dict[Path, ET.Element],
) -> None:
    source_texts: dict[str, dict[str, str]] = {"en_US": {}, "zh_Hans_CN": {}}
    for path, root in parsed.items():
        if "Text" not in path.parts or "Selected" in path.parts:
            continue
        for row in root.findall(".//LocalizedText/Row"):
            language = row.attrib.get("Language")
            tag = row.attrib.get("Tag")
            if language not in source_texts or not tag:
                continue
            source_texts[language][tag] = row.findtext("./Text", default="")
        language = next((part for part in path.parts if part in source_texts), None)
        if language is not None:
            for row in root.findall(".//BaseGameText/Row"):
                tag = row.attrib.get("Tag")
                if tag:
                    source_texts[language][tag] = row.findtext("./Text", default="")

    validation.check(
        set(source_texts["zh_Hans_CN"]) == set(source_texts["en_US"]),
        "Chinese and English source localization tags must match exactly",
    )
    # The two new governors add 32 isolated normal-mode localization tags.
    validation.check(
		len(source_texts["zh_Hans_CN"]) == 1382,
		"source localization must currently contain exactly 1382 tags",
    )

    # Justice has its own normal-mode UpdateText action. Including those rows
    # again in the language-selected pack makes Civ VI reject the duplicate
    # LocalizedText tags, as observed in the resource-394 Database.log.
    justice_tags = {
        row.attrib["Tag"]
        for row in parsed[ROOT / "Text" / "zh_Hans_CN" / "LOTM_JUSTICE_Text.xml"].findall(
            ".//LocalizedText/Row"
        )
    }
    validation.check(len(justice_tags) == 26,
                     "Justice must expose exactly 26 isolated localization tags")
    ms_tags = {
        row.attrib["Tag"]
        for row in parsed[ROOT / "Text" / "zh_Hans_CN" / "LOTM_MS_Text.xml"].findall(
            ".//LocalizedText/Row"
        )
    }
    validation.check(len(ms_tags) == 32,
                     "Magician and Star must expose exactly 32 isolated localization tags")
    rescue_governor_tags = {
        row.attrib["Tag"]
        for row in parsed[ROOT / "Text" / "zh_Hans_CN" / "LOTM_RESCUE_Governors.xml"].findall(".//LocalizedText/Row")
    }
    validation.check(len(rescue_governor_tags) == 6,
                     "rescue Star must expose exactly six isolated localization tags")
    # Holy-city selectors have their own rescue-only UpdateText action, just
    # as the two normal-mode systems above. Do not duplicate them in BaseGameText.
    holy_city_tags = {
        row.attrib["Tag"]
        for row in parsed[ROOT / "Text" / "LOTM_RESCUE_HolyCityArt.xml"].findall(
            ".//LocalizedText/Row"
        )
    }
    validation.check(len(holy_city_tags) == 4,
                     "Holy city art must expose exactly 4 isolated localization tags")
    player_model_tags = {
        row.attrib["Tag"]
        for row in parsed[ROOT / "Text" / "LOTM_PlayerModels.xml"].findall(".//LocalizedText/Row")
    }
    validation.check(len(player_model_tags) == 5,
                     "Player models must expose exactly 5 isolated localization tags")

    for language in ("zh_Hans_CN", "en_US"):
        selected_path = ROOT / "Text" / "Selected" / f"LOTM_RP_Selected_{language}.xml"
        validation.require_file(selected_path, f"generated {language} text pack")
        if not selected_path.is_file():
            continue
        selected_root = parsed.get(selected_path)
        validation.check(selected_root is not None, f"generated {language} text pack did not parse")
        if selected_root is None:
            continue
        element_name = "Replace" if language == "en_US" else "Row"
        selected_rows = selected_root.findall(f"./BaseGameText/{element_name}")
        validation.check(
            not selected_root.findall(f"./BaseGameText/{'Row' if element_name == 'Replace' else 'Replace'}"),
            f"{language} selected pack uses the wrong insert/override element",
        )
        selected_texts = {
            row.attrib.get("Tag", ""): row.findtext("./Text", default="")
            for row in selected_rows
            if row.attrib.get("Tag")
        }
        validation.check(
            not selected_root.findall(".//LocalizedText"),
            f"{language} selected pack must use language-independent BaseGameText",
        )
        validation.check(
            all("Language" not in row.attrib for row in selected_rows),
            f"{language} selected pack rows must not retain Language attributes",
        )
        validation.check(
            selected_texts == {tag: value for tag, value in source_texts[language].items()
                               if tag not in justice_tags and tag not in ms_tags and tag not in holy_city_tags and tag not in player_model_tags and tag not in rescue_governor_tags},
            f"{language} selected pack is stale; run generate_selected_language_text.py",
        )


def validate_probe(validation: Validation) -> None:
    ui = strip_trace((ROOT / "UI" / "LOTM_RP_Probe.lua").read_text(encoding="utf-8"))
    gameplay = strip_trace((ROOT / "Scripts" / "LOTM_RP_CommandProbe.lua").read_text(encoding="utf-8"))

    validation.check(
        "local LOTM_RP_PROBE_ENABLED :boolean = false;" in ui,
        "probe must be disabled by default",
    )
    validation.check("UnitManager.RequestCommand" in ui, "UI probe does not request a unit command")
    validation.check("UnitCommandTypes.EXECUTE_SCRIPT" in ui, "UI probe does not use EXECUTE_SCRIPT")
    validation.check("UnitCommandTypes.PARAM_NAME" in ui, "UI probe does not set PARAM_NAME")
    validation.check('"LOTM_RP_Command_Probe"' in ui, "UI probe command name is wrong")
    validation.check("GameEvents.LOTM_RP_Command_Probe.Add" in gameplay, "Gameplay probe handler is not registered")
    validation.check("SetProperty" not in ui and "SetProperty" not in gameplay, "probe must not write Properties")
    validation.check("LuaEvents" not in ui, "UI probe must not use LuaEvents for Gameplay")

    forbidden_mutations = (
        "ChangeDamage",
        "SetDamage",
        "ChangeMovesRemaining",
        "SetMovesRemaining",
        "UnitManager.Kill",
        "UnitManager.InitUnit",
        "ImprovementBuilder",
    )
    for token in forbidden_mutations:
        validation.check(token not in ui and token not in gameplay, f"phase-01 probe contains mutation: {token}")

    validation.check(
        "LOTM_RP_Command_Arson" not in ui,
        "retained phase-01 probe must not be repurposed as the arson command",
    )


def validate_modifiers(validation: Validation, root: ET.Element) -> None:
    def field(row: ET.Element, name: str) -> str | None:
        return row.attrib.get(name) or row.findtext(name)

    all_modifiers = {
        field(row, "ModifierId"): row
        for row in root.findall("./Modifiers/Row")
        if field(row, "ModifierId")
    }
    expected = {
        "LOTM_RP_MOD_RIFLING_COMBAT": "0",
        "LOTM_RP_MOD_PLASTICS_COMBAT": "0",
        "LOTM_RP_MOD_TECH_IRON_WORKING_COMBAT": "15",
        "LOTM_RP_MOD_TECH_APPRENTICESHIP_COMBAT": "10",
        "LOTM_RP_MOD_TECH_GUNPOWDER_COMBAT": "10",
        "LOTM_RP_MOD_TECH_MILITARY_SCIENCE_COMBAT": "10",
        "LOTM_RP_MOD_TECH_REPLACEABLE_PARTS_COMBAT": "10",
        "LOTM_RP_MOD_TECH_SATELLITES_COMBAT": "10",
    }
    modifiers = {
        modifier_id: all_modifiers.get(modifier_id)
        for modifier_id in expected
        if all_modifiers.get(modifier_id) is not None
    }
    validation.check(
        set(modifiers) == set(expected),
        "missing lifecycle technology modifiers",
    )
    legacy_ids = {
        "LOTM_RP_MOD_RIFLING_COMBAT",
        "LOTM_RP_MOD_PLASTICS_COMBAT",
    }
    for modifier_id in expected:
        row = modifiers.get(modifier_id)
        if row is None:
            continue
        expected_type = (
            "MODIFIER_PLAYER_UNITS_ADJUST_COMBAT_STRENGTH"
            if modifier_id in legacy_ids
            else "MODIFIER_LOTM_RP_PLAYER_UNITS_ADJUST_BASE_COMBAT_STRENGTH"
        )
        validation.check(
            field(row, "ModifierType") == expected_type,
            f"{modifier_id} must use {expected_type}",
        )
        validation.check(
            field(row, "SubjectRequirementSetId") == "LOTM_RP_REQSET_PATH_HOLDER",
            f"{modifier_id} must be restricted to the path-holder unit",
        )
        validation.check(
            field(row, "Permanent") == "true",
            f"{modifier_id} must persist after dynamic attachment",
        )

    dynamic = root.find(
        "./DynamicModifiers/Row"
        "[ModifierType='MODIFIER_LOTM_RP_PLAYER_UNITS_ADJUST_BASE_COMBAT_STRENGTH']"
    )
    validation.check(
        dynamic is not None
        and dynamic.findtext("CollectionType") == "COLLECTION_PLAYER_UNITS"
        and dynamic.findtext("EffectType") == "EFFECT_ADJUST_UNIT_COMBAT_STRENGTH",
        "technology tiers must change Unit:GetCombat() for both the panel and combat resolution",
    )

    amounts = {
        field(row, "ModifierId"): field(row, "Value")
        for row in root.findall("./ModifierArguments/Row")
        if field(row, "Name") == "Amount"
        and field(row, "ModifierId") in expected
    }
    validation.check(
        amounts == expected,
        f"technology combat increments must implement 20→35→45→55→65→75→85, got {amounts}",
    )
    requirement = root.find(
        "./Requirements/Row[RequirementId='LOTM_RP_REQUIRES_PATH_HOLDER']"
    )
    perfect_requirement = root.find(
        "./Requirements/Row[RequirementId='LOTM_PP_REQUIRES_PATH_HOLDER']"
    )
    black_emperor_requirement = root.find(
        "./Requirements/Row[RequirementId='LOTM_BE_REQUIRES_PATH_HOLDER']"
    )
    validation.check(
        requirement is not None
        and requirement.findtext("RequirementType") == "REQUIREMENT_UNIT_TYPE_MATCHES",
        "Red Priest holder unit-type requirement is missing",
    )
    validation.check(
        perfect_requirement is not None
        and perfect_requirement.findtext("RequirementType") == "REQUIREMENT_UNIT_TYPE_MATCHES",
        "Perfect holder unit-type requirement is missing",
    )
    validation.check(
        black_emperor_requirement is not None
        and black_emperor_requirement.findtext("RequirementType")
        == "REQUIREMENT_UNIT_TYPE_MATCHES",
        "Black Emperor holder unit-type requirement is missing",
    )
    unit_argument = root.find(
        "./RequirementArguments/Row[RequirementId='LOTM_RP_REQUIRES_PATH_HOLDER']"
    )
    perfect_unit_argument = root.find(
        "./RequirementArguments/Row[RequirementId='LOTM_PP_REQUIRES_PATH_HOLDER']"
    )
    black_emperor_unit_argument = root.find(
        "./RequirementArguments/Row[RequirementId='LOTM_BE_REQUIRES_PATH_HOLDER']"
    )
    validation.check(
        unit_argument is not None
        and unit_argument.findtext("Name") == "UnitType"
        and unit_argument.findtext("Value") == UNIT_TYPE,
        "combat modifier requirement must match UNIT_LOTM_RP_PATH_HOLDER",
    )
    validation.check(
        perfect_unit_argument is not None
        and perfect_unit_argument.findtext("Name") == "UnitType"
        and perfect_unit_argument.findtext("Value") == PERFECT_UNIT_TYPE,
        "combat modifier requirement must match UNIT_LOTM_PP_PATH_HOLDER",
    )
    validation.check(
        black_emperor_unit_argument is not None
        and black_emperor_unit_argument.findtext("Name") == "UnitType"
        and black_emperor_unit_argument.findtext("Value") == BLACK_EMPEROR_UNIT_TYPE,
        "combat modifier requirement must match UNIT_LOTM_BE_PATH_HOLDER",
    )
    holder_set = root.find(
        "./RequirementSets/Row[RequirementSetId='LOTM_RP_REQSET_PATH_HOLDER']"
    )
    holder_requirements = {
        row.findtext("RequirementId")
        for row in root.findall(
            "./RequirementSetRequirements/Row"
            "[RequirementSetId='LOTM_RP_REQSET_PATH_HOLDER']"
        )
    }
    validation.check(
        holder_set is not None
        and holder_set.findtext("RequirementSetType") == "REQUIREMENTSET_TEST_ANY"
        and holder_requirements
        == {
            "LOTM_RP_REQUIRES_PATH_HOLDER",
            "LOTM_PP_REQUIRES_PATH_HOLDER",
            "LOTM_BE_REQUIRES_PATH_HOLDER",
        },
        "path-holder requirement set must accept exactly the three path-holder unit types",
    )


def validate_projects_and_abilities(
    validation: Validation,
    projects_root: ET.Element,
    abilities_root: ET.Element,
) -> None:
    projects = {
        row.attrib.get("ProjectType"): row
        for row in projects_root.findall("./Projects/Row")
        if row.attrib.get("ProjectType")
    }
    validation.check(
        set(projects)
        == {
            PROVOKER_PROJECT,
            PYROMANIAC_PROJECT,
            CONSPIRATOR_PROJECT,
            REAPER_PROJECT,
            IRONBLOOD_PROJECT,
            WAR_BISHOP_PROJECT,
            WEATHER_WARLOCK_PROJECT,
            CONQUEROR_PROJECT,
            WAR_FESTIVAL_PROJECT,
            UNCONSECRATED_WAR_FESTIVAL_PROJECT,
            PP_ARCHAEOLOGIST_PROJECT,
            PP_APPRAISER_PROJECT,
            PP_MECHANICAL_PROJECT,
            PP_ASTRONOMER_PROJECT,
            PP_ALCHEMIST_PROJECT,
            PP_MYSTERY_SCHOLAR_PROJECT,
            PP_KNOWLEDGE_MENTOR_PROJECT,
            PP_ENLIGHTENER_PROJECT,
            PP_CIVILIZATION_ASCENSION_PROJECT,
            PP_UNCONSECRATED_ASCENSION_PROJECT,
            "PROJECT_LOTM_TP_SWINDLER_POTION",
            "PROJECT_LOTM_TP_CRYPTOLOGIST_POTION",
            "PROJECT_LOTM_TP_PROMETHEUS_POTION",
            "PROJECT_LOTM_TP_DREAM_STEALER_POTION",
            "PROJECT_LOTM_TP_PARASITE_POTION",
            "PROJECT_LOTM_TP_MENTOR_OF_DECEIT_POTION",
            "PROJECT_LOTM_TP_FATE_TROJAN_POTION",
            "PROJECT_LOTM_TP_WORM_OF_TIME_POTION",
            "PROJECT_LOTM_TP_ERROR_APOTHEOSIS",
            "PROJECT_LOTM_TP_FAITH_TRANSFER",
            "PROJECT_LOTM_TP_CULTURE_TRANSFER",
            "PROJECT_LOTM_TP_FAITH_TRANSFER_II",
            "PROJECT_LOTM_TP_CULTURE_TRANSFER_II",
        },
        f"unexpected Red Priest potion projects: {sorted(projects)}",
    )
    for project_type, cost in (
        (PROVOKER_PROJECT, "60"),
        (PYROMANIAC_PROJECT, "100"),
        (CONSPIRATOR_PROJECT, "140"),
        (REAPER_PROJECT, "180"),
        (IRONBLOOD_PROJECT, "220"),
        (WAR_BISHOP_PROJECT, "260"),
        (WEATHER_WARLOCK_PROJECT, "300"),
        (CONQUEROR_PROJECT, "340"),
        (WAR_FESTIVAL_PROJECT, "380"),
        (UNCONSECRATED_WAR_FESTIVAL_PROJECT, "760"),
        (PP_ARCHAEOLOGIST_PROJECT, "60"),
        (PP_APPRAISER_PROJECT, "100"),
        (PP_MECHANICAL_PROJECT, "140"),
        (PP_ASTRONOMER_PROJECT, "180"),
        (PP_ALCHEMIST_PROJECT, "220"),
        (PP_MYSTERY_SCHOLAR_PROJECT, "260"),
        (PP_KNOWLEDGE_MENTOR_PROJECT, "300"),
        (PP_ENLIGHTENER_PROJECT, "340"),
        (PP_CIVILIZATION_ASCENSION_PROJECT, "380"),
        (PP_UNCONSECRATED_ASCENSION_PROJECT, "760"),
        ("PROJECT_LOTM_TP_SWINDLER_POTION", "60"),
        ("PROJECT_LOTM_TP_CRYPTOLOGIST_POTION", "100"),
        ("PROJECT_LOTM_TP_PROMETHEUS_POTION", "140"),
        ("PROJECT_LOTM_TP_DREAM_STEALER_POTION", "180"),
        ("PROJECT_LOTM_TP_PARASITE_POTION", "220"),
        ("PROJECT_LOTM_TP_MENTOR_OF_DECEIT_POTION", "260"),
        ("PROJECT_LOTM_TP_FATE_TROJAN_POTION", "300"),
        ("PROJECT_LOTM_TP_WORM_OF_TIME_POTION", "340"),
        ("PROJECT_LOTM_TP_ERROR_APOTHEOSIS", "380"),
        ("PROJECT_LOTM_TP_FAITH_TRANSFER", "1000"),
        ("PROJECT_LOTM_TP_CULTURE_TRANSFER", "1000"),
        ("PROJECT_LOTM_TP_FAITH_TRANSFER_II", "2000"),
        ("PROJECT_LOTM_TP_CULTURE_TRANSFER_II", "2000"),
    ):
        row = projects.get(project_type)
        if row is None:
            continue
        validation.check(row.attrib.get("Cost") == cost, f"{project_type} cost must be {cost}")
        transfer_project = project_type in {
            "PROJECT_LOTM_TP_FAITH_TRANSFER",
            "PROJECT_LOTM_TP_CULTURE_TRANSFER",
            "PROJECT_LOTM_TP_FAITH_TRANSFER_II",
            "PROJECT_LOTM_TP_CULTURE_TRANSFER_II",
        }
        # Potion projects are one-time progression steps. Transfer projects
        # intentionally omit MaxPlayerInstances so they can be repeated after
        # completion; NULL is Civ VI's unlimited-instance convention.
        expected_max = None if transfer_project else "1"
        validation.check(
            row.attrib.get("MaxPlayerInstances") == expected_max,
            f"{project_type} must use MaxPlayerInstances={expected_max or 'NULL/unlimited'}",
        )
        validation.check(
            row.attrib.get("UnlocksFromEffect") == "true",
            f"{project_type} must unlock only from a modifier effect",
        )
        validation.check(
            "CostProgressionModel" not in row.attrib,
            f"{project_type} must use the base cost and standard game-speed scaling",
        )

    support = strip_trace((ROOT / "Gameplay" / "LOTM_RP_ProjectSupport.sql").read_text(encoding="utf-8"))
    validation.check(
        "INSERT OR IGNORE INTO Types" in support
        and "'MODIFIER_PLAYER_ALLOW_PROJECT'" in support
        and "EFFECT_ADD_PLAYER_PROJECT_AVAILABILITY" in support,
        "idempotent MODIFIER_PLAYER_ALLOW_PROJECT support is missing",
    )

    abilities = {
        row.attrib.get("UnitAbilityType"): row
        for row in abilities_root.findall("./UnitAbilities/Row")
        if row.attrib.get("UnitAbilityType")
    }
    validation.check(
        set(abilities)
        == {
            HUNTER_ABILITY,
            PROVOKER_ABILITY,
            PROVOKER_GARRISON_ABILITY,
            CONQUEST_ABILITY,
        },
        f"unexpected sequence abilities: {sorted(abilities)}",
    )
    for ability_type in (HUNTER_ABILITY, PROVOKER_ABILITY, CONQUEST_ABILITY):
        row = abilities.get(ability_type)
        validation.check(
            row is not None
            and row.attrib.get("Inactive") == "true"
            and row.attrib.get("Permanent") == "true",
            f"{ability_type} must be a permanent dynamically granted ability",
        )

    modifiers = {
        row.findtext("ModifierId"): row
        for row in abilities_root.findall("./Modifiers/Row")
        if row.findtext("ModifierId")
    }
    arguments = {
        (row.attrib.get("ModifierId"), row.attrib.get("Name")): row.attrib.get("Value")
        for row in abilities_root.findall("./ModifierArguments/Row")
    }
    expected_grants = {
        "LOTM_RP_MOD_GRANT_HUNTER_INSTINCT": HUNTER_ABILITY,
        "LOTM_RP_MOD_GRANT_PROVOKER": PROVOKER_ABILITY,
    }
    for modifier_id, ability_type in expected_grants.items():
        row = modifiers.get(modifier_id)
        validation.check(
            row is not None
            and row.findtext("ModifierType") == "MODIFIER_PLAYER_UNITS_GRANT_ABILITY"
            and row.findtext("SubjectRequirementSetId") == "LOTM_RP_REQSET_PATH_HOLDER"
            and row.findtext("Permanent") == "true"
            and arguments.get((modifier_id, "AbilityType")) == ability_type,
            f"{modifier_id} does not permanently grant {ability_type} only to the hero",
        )

    validation.check(
        arguments.get(("LOTM_RP_MOD_HUNTER_SIGHT", "Amount")) == "5",
        "Hunter's Instinct sight bonus must be +5",
    )
    movement_types = {
        arguments.get(("LOTM_RP_MOD_HUNTER_FOREST_MOVE", "Type")),
        arguments.get(("LOTM_RP_MOD_HUNTER_HILLS_MOVE", "Type")),
    }
    validation.check(
        movement_types == {"FOREST", "HILLS"},
        "Hunter's Instinct must use Firaxis FOREST (Woods/Rainforest) and HILLS categories",
    )
    hunter_set = abilities_root.find(
        "./RequirementSets/Row[@RequirementSetId='LOTM_RP_REQSET_OPPONENT_BARB_OR_WOUNDED']"
    )
    validation.check(
        hunter_set is not None
        and hunter_set.attrib.get("RequirementSetType") == "REQUIREMENTSET_TEST_ANY"
        and arguments.get(("LOTM_RP_MOD_HUNTER_COMBAT", "Amount")) == "30",
        "Hunter's Instinct combat bonus must be one +30 modifier with ANY semantics",
    )
    validation.check(
        arguments.get(("LOTM_RP_MOD_HUNTER_MOVEMENT", "Amount")) == "2"
        and modifiers.get("LOTM_RP_MOD_HUNTER_MOVEMENT") is not None
        and modifiers["LOTM_RP_MOD_HUNTER_MOVEMENT"].findtext("ModifierType")
        == "MODIFIER_PLAYER_UNIT_ADJUST_MOVEMENT",
        "Hunter's Instinct must grant +2 movement",
    )
    hunter_requirements = {
        row.attrib.get("RequirementId")
        for row in abilities_root.findall(
            "./RequirementSetRequirements/Row"
            "[@RequirementSetId='LOTM_RP_REQSET_OPPONENT_BARB_OR_WOUNDED']"
        )
    }
    validation.check(
        hunter_requirements
        == {
            "LOTM_RP_REQUIRES_OPPONENT_BARBARIAN",
            "LOTM_RP_REQUIRES_OPPONENT_WOUNDED",
        },
        "Hunter's Instinct must test barbarian OR wounded opponent",
    )
    hunter_attack_set = abilities_root.find(
        "./RequirementSets/Row"
        "[@RequirementSetId='LOTM_RP_REQSET_ATTACKING_BARB_OR_WOUNDED']"
    )
    hunter_attack_requirements = {
        row.attrib.get("RequirementId")
        for row in abilities_root.findall(
            "./RequirementSetRequirements/Row"
            "[@RequirementSetId='LOTM_RP_REQSET_ATTACKING_BARB_OR_WOUNDED']"
        )
    }
    validation.check(
        hunter_attack_set is not None
        and hunter_attack_set.attrib.get("RequirementSetType")
        == "REQUIREMENTSET_TEST_ALL"
        and modifiers.get("LOTM_RP_MOD_HUNTER_COMBAT") is not None
        and modifiers["LOTM_RP_MOD_HUNTER_COMBAT"].findtext(
            "SubjectRequirementSetId"
        )
        == "LOTM_RP_REQSET_ATTACKING_BARB_OR_WOUNDED"
        and hunter_attack_requirements
        == {
            "LOTM_RP_REQUIRES_ATTACKING",
            "LOTM_RP_REQUIRES_OPPONENT_BARB_OR_WOUNDED",
        },
        "Hunter's Instinct must require attacking AND a barbarian-or-wounded opponent",
    )

    for modifier_id in ("LOTM_RP_MOD_PROVOKER_AURA", "LOTM_RP_MOD_PROVOKER_AURA_DEBUFF"):
        row = modifiers.get(modifier_id)
        validation.check(
            row is not None and row.findtext("SubjectStackLimit") == "1",
            f"{modifier_id} must have SubjectStackLimit=1",
        )
    validation.check(
        arguments.get(("LOTM_RP_MOD_PROVOKER_AURA_DEBUFF", "Amount")) == "0"
        and arguments.get(("LOTM_RP_MOD_PROVOKER_MELEE_DEFENSE", "Amount")) == "0",
        "legacy Provoker aura and melee-defense modifiers must be neutralized",
    )
    validation.check(
        arguments.get(("LOTM_RP_MOD_PROVOKER_GARRISON_STRENGTH", "Amount")) == "40"
        and modifiers.get("LOTM_RP_MOD_PROVOKER_GARRISON_STRENGTH") is not None
        and modifiers["LOTM_RP_MOD_PROVOKER_GARRISON_STRENGTH"].findtext(
            "ModifierType"
        )
        == "MODIFIER_UNIT_ADJUST_COMBAT_STRENGTH",
        "fortified Provoker ability must grant +40 combat strength",
    )
    validation.check(
        arguments.get(("LOTM_RP_MOD_IRONBLOOD_FRIENDLY_STRENGTH_EFFECT_V2", "Amount"))
        == "30"
        and arguments.get(("LOTM_RP_MOD_IRONBLOOD_FRIENDLY_MOVEMENT_EFFECT_V2", "Amount"))
        == "3",
        "Iron-Blooded Legion must grant +30 combat strength and +3 movement",
    )
    project_modifiers = {
        "LOTM_RP_MOD_ALLOW_PROVOKER_PROJECT": PROVOKER_PROJECT,
        "LOTM_RP_MOD_ALLOW_PYROMANIAC_PROJECT": PYROMANIAC_PROJECT,
        "LOTM_RP_MOD_ALLOW_CONSPIRATOR_PROJECT": CONSPIRATOR_PROJECT,
        "LOTM_RP_MOD_ALLOW_REAPER_PROJECT": REAPER_PROJECT,
        "LOTM_RP_MOD_ALLOW_IRONBLOOD_PROJECT": IRONBLOOD_PROJECT,
        "LOTM_RP_MOD_ALLOW_WAR_BISHOP_PROJECT": WAR_BISHOP_PROJECT,
        "LOTM_RP_MOD_ALLOW_WEATHER_WARLOCK_PROJECT": WEATHER_WARLOCK_PROJECT,
        "LOTM_RP_MOD_ALLOW_CONQUEROR_PROJECT": CONQUEROR_PROJECT,
        "LOTM_RP_MOD_ALLOW_WAR_FESTIVAL_PROJECT": WAR_FESTIVAL_PROJECT,
    }
    validation.check(
        all(
            arguments.get((modifier_id, "ProjectType")) == project_type
            for modifier_id, project_type in project_modifiers.items()
        ),
        "project availability modifiers target the wrong projects",
    )
    for modifier_id in project_modifiers:
        row = modifiers.get(modifier_id)
        validation.check(
            row is not None
            and row.findtext("ModifierType") == "MODIFIER_PLAYER_ALLOW_PROJECT"
            and row.findtext("Permanent") == "true",
            f"{modifier_id} must use permanent MODIFIER_PLAYER_ALLOW_PROJECT",
        )

    requirements = {
        row.attrib.get("RequirementId"): row
        for row in abilities_root.findall("./Requirements/Row")
        if row.attrib.get("RequirementId")
    }
    validation.check(
        requirements.get("LOTM_RP_REQUIRES_ADJACENT_OWNER_AT_WAR") is not None
        and requirements["LOTM_RP_REQUIRES_ADJACENT_OWNER_AT_WAR"].attrib.get(
            "RequirementType"
        )
        == "REQUIREMENT_PLOT_ADJACENT_TO_OWNER_AT_WAR",
        "Provoker aura adjacency requirement is missing",
    )
    requirement_arguments = {
        (row.attrib.get("RequirementId"), row.attrib.get("Name")): row.attrib.get("Value")
        for row in abilities_root.findall("./RequirementArguments/Row")
    }
    validation.check(
        requirement_arguments.get(
            ("LOTM_RP_REQUIRES_ADJACENT_OWNER_AT_WAR", "MinDistance")
        )
        == "1"
        and requirement_arguments.get(
            ("LOTM_RP_REQUIRES_ADJACENT_OWNER_AT_WAR", "MaxDistance")
        )
        == "1",
        "Provoker aura range must be exactly one hex",
    )
    validation.check(
        requirements.get("LOTM_RP_REQUIRES_DEFENDING") is not None
        and requirements["LOTM_RP_REQUIRES_DEFENDING"].attrib.get("Inverse") == "true"
        and requirements.get("LOTM_RP_REQUIRES_MELEE_COMBAT") is not None
        and requirement_arguments.get(
            ("LOTM_RP_REQUIRES_MELEE_COMBAT", "CombatType")
        )
        == "COMBAT_MELEE",
        "Provoker defense must require defending a melee combat",
    )
    ironblood_grant = modifiers.get("LOTM_RP_MOD_IRONBLOOD_FRIENDLY_STRENGTH_AURA_V2")
    ironblood_strength = modifiers.get("LOTM_RP_MOD_IRONBLOOD_FRIENDLY_STRENGTH_EFFECT_V2")
    ironblood_movement = modifiers.get("LOTM_RP_MOD_IRONBLOOD_FRIENDLY_MOVEMENT_AURA_V2")
    ironblood_movement_effect = modifiers.get("LOTM_RP_MOD_IRONBLOOD_FRIENDLY_MOVEMENT_EFFECT_V2")
    validation.check(
        ironblood_grant is not None
        and ironblood_grant.findtext("ModifierType")
        == "MODIFIER_PLAYER_UNITS_ATTACH_MODIFIER"
        and ironblood_grant.findtext("SubjectRequirementSetId") is None
        and arguments.get(("LOTM_RP_MOD_IRONBLOOD_FRIENDLY_STRENGTH_AURA_V2", "ModifierId"))
        == "LOTM_RP_MOD_IRONBLOOD_FRIENDLY_STRENGTH_EFFECT_V2"
        and ironblood_strength is not None
        and ironblood_strength.findtext("ModifierType") == "MODIFIER_UNIT_ADJUST_COMBAT_STRENGTH"
        and ironblood_strength.findtext("SubjectStackLimit") == "1"
        and ironblood_movement is not None
        and ironblood_movement.findtext("ModifierType")
        == "MODIFIER_PLAYER_UNITS_ATTACH_MODIFIER"
        and ironblood_movement.findtext("SubjectRequirementSetId") is None
        and arguments.get(("LOTM_RP_MOD_IRONBLOOD_FRIENDLY_MOVEMENT_AURA_V2", "ModifierId"))
        == "LOTM_RP_MOD_IRONBLOOD_FRIENDLY_MOVEMENT_EFFECT_V2"
        and ironblood_movement_effect is not None
        and ironblood_movement_effect.findtext("ModifierType")
        == "MODIFIER_PLAYER_UNIT_ADJUST_MOVEMENT"
        and ironblood_movement_effect.findtext("SubjectStackLimit") == "1"
        and arguments.get(("LOTM_RP_MOD_GRANT_IRONBLOOD_LEGION", "Amount")) == "0"
        and arguments.get(("LOTM_RP_MOD_IRONBLOOD_MOVEMENT", "Amount")) == "0"
        and not abilities_root.findall(
            "./TypeTags/Row[@Type='ABILITY_LOTM_RP_IRONBLOOD_LEGION']"
        )
        and "LOTM_RP_REQUIRES_NEAR_PATH_HOLDER" not in requirements,
        "Iron-Blooded Legion must use owner-unit attach chains and neutralize the failed legacy direct modifiers",
    )
    validation.check(
        arguments.get(("LOTM_RP_MOD_WAR_BISHOP_PRODUCTION", "Amount")) == "100"
        and arguments.get(("LOTM_RP_MOD_WAR_BISHOP_PRODUCTION", "YieldType"))
        == "YIELD_PRODUCTION"
        and modifiers.get("LOTM_RP_MOD_WAR_BISHOP_PRODUCTION") is not None
        and modifiers["LOTM_RP_MOD_WAR_BISHOP_PRODUCTION"].findtext("ModifierType")
        == "MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_MODIFIER"
        and arguments.get(("LOTM_RP_MOD_WAR_BISHOP_WEARINESS", "Amount")) == "-100",
        "War Sermon must grant all cities +100% Production and 100% war-weariness reduction",
    )
    weather_auras = (
        ("LOTM_RP_MOD_WEATHER_ENEMY_STRENGTH_AURA_V2", "LOTM_RP_MOD_WEATHER_ENEMY_STRENGTH_V2"),
        ("LOTM_RP_MOD_WEATHER_ENEMY_MOVEMENT_AURA_V2", "LOTM_RP_MOD_WEATHER_ENEMY_MOVEMENT_V2"),
        ("LOTM_RP_MOD_WEATHER_ENEMY_WEARINESS_AURA_V2", "LOTM_RP_MOD_WEATHER_ENEMY_WEARINESS_V2"),
    )
    weather_dynamic = {
        row.findtext("ModifierType"): row
        for row in abilities_root.findall("./DynamicModifiers/Row")
        if row.findtext("ModifierType")
    }
    validation.check(
        weather_dynamic.get(WEATHER_OPPOSING_ATTACH_MODIFIER) is not None
        and weather_dynamic[WEATHER_OPPOSING_ATTACH_MODIFIER].findtext("CollectionType")
        == "COLLECTION_MAJOR_OPPOSING_PLAYERS"
        and weather_dynamic[WEATHER_OPPOSING_ATTACH_MODIFIER].findtext("EffectType")
        == "EFFECT_ATTACH_MODIFIER"
        and
        all(
            modifiers.get(aura) is not None
            and modifiers[aura].findtext("ModifierType")
            == WEATHER_OPPOSING_ATTACH_MODIFIER
            and modifiers[aura].findtext("SubjectRequirementSetId")
            == "LOTM_RP_REQSET_MAJOR_AT_WAR_WITH_OWNER"
            and arguments.get((aura, "ModifierId")) == child
            for aura, child in weather_auras
        ),
        "Weather Manipulation must attach penalties through the opposing-major-player collection",
    )
    validation.check(
        arguments.get(("LOTM_RP_MOD_WEATHER_ENEMY_STRENGTH_V2", "Amount")) == "-20"
        and arguments.get(("LOTM_RP_MOD_WEATHER_ENEMY_MOVEMENT_V2", "Amount")) == "-2"
        and arguments.get(("LOTM_RP_MOD_WEATHER_ENEMY_WEARINESS_V2", "Amount")) == "100"
        and arguments.get(("LOTM_RP_MOD_WEATHER_ENEMY_WEARINESS_V2", "Overall")) == "true"
        and arguments.get(("LOTM_RP_MOD_WEATHER_ENEMY_STRENGTH", "Amount")) == "0"
        and arguments.get(("LOTM_RP_MOD_WEATHER_ENEMY_MOVEMENT", "Amount")) == "0"
        and arguments.get(("LOTM_RP_MOD_WEATHER_ENEMY_WEARINESS", "Amount")) == "0"
        and arguments.get(("LOTM_RP_MOD_WEATHER_FRIENDLY_MOVEMENT_EFFECT_V2", "Amount"))
        == "2"
        and arguments.get(("LOTM_RP_MOD_WEATHER_FRIENDLY_MOVEMENT", "Amount")) == "0"
        and modifiers.get("LOTM_RP_MOD_WEATHER_FRIENDLY_MOVEMENT_AURA_V2") is not None
        and modifiers["LOTM_RP_MOD_WEATHER_FRIENDLY_MOVEMENT_AURA_V2"].findtext(
            "ModifierType"
        )
        == "MODIFIER_PLAYER_UNITS_ATTACH_MODIFIER"
        and arguments.get(("LOTM_RP_MOD_WEATHER_FRIENDLY_MOVEMENT_AURA_V2", "ModifierId"))
        == "LOTM_RP_MOD_WEATHER_FRIENDLY_MOVEMENT_EFFECT_V2",
        "Weather Manipulation values must be enemy -20 Strength/-2 Movement/+100% weariness and friendly +2 Movement",
    )
    validation.check(
        requirements.get("LOTM_RP_REQUIRES_NOT_AT_PEACE_WITH_OWNER") is not None
        and requirements["LOTM_RP_REQUIRES_NOT_AT_PEACE_WITH_OWNER"].attrib.get("RequirementType")
        == "REQUIREMENT_PLAYER_IS_AT_PEACE"
        and requirements["LOTM_RP_REQUIRES_NOT_AT_PEACE_WITH_OWNER"].attrib.get("Inverse")
        == "true"
        and {
            row.attrib.get("RequirementId")
            for row in abilities_root.findall(
                "./RequirementSetRequirements/Row"
                "[@RequirementSetId='LOTM_RP_REQSET_MAJOR_AT_WAR_WITH_OWNER']"
            )
        }
        == {"LOTM_RP_REQUIRES_NOT_AT_PEACE_WITH_OWNER"},
        "Weather Manipulation must filter the opposing-major collection only by war with owner",
    )
    conquest_tags = {
        row.attrib.get("Tag")
        for row in abilities_root.findall(f"./TypeTags/Row[@Type='{CONQUEST_ABILITY}']")
    }
    conquest_ability_modifiers = {
        row.attrib.get("ModifierId")
        for row in abilities_root.findall(
            f"./UnitAbilityModifiers/Row[@UnitAbilityType='{CONQUEST_ABILITY}']"
        )
    }
    validation.check(
        conquest_tags == {"CLASS_ALL_COMBAT_UNITS"}
        and arguments.get(("LOTM_RP_MOD_GRANT_CONQUEST_BYPASS_WALLS", "AbilityType"))
        == CONQUEST_ABILITY
        and conquest_ability_modifiers
        == {
            "LOTM_RP_MOD_CONQUEST_BYPASS_WALLS",
            "LOTM_RP_MOD_CONQUEST_PARTICLE_BEAM_STRENGTH",
        }
        and modifiers.get("LOTM_RP_MOD_CONQUEST_BYPASS_WALLS") is not None
        and modifiers["LOTM_RP_MOD_CONQUEST_BYPASS_WALLS"].findtext("ModifierType")
        == "MODIFIER_PLAYER_UNIT_IGNORE_RANGED_VS_DISTRICT_PENALTY"
        and arguments.get(("LOTM_RP_MOD_CONQUEST_BYPASS_WALLS", "Ignore")) == "true"
        and modifiers.get("LOTM_RP_MOD_CONQUEST_PARTICLE_BEAM_STRENGTH") is not None
        and modifiers["LOTM_RP_MOD_CONQUEST_PARTICLE_BEAM_STRENGTH"].findtext("ModifierType")
        == "MODIFIER_UNIT_ADJUST_COMBAT_STRENGTH"
        and modifiers["LOTM_RP_MOD_CONQUEST_PARTICLE_BEAM_STRENGTH"].findtext(
            "SubjectRequirementSetId"
        )
        == "SIEGE_LASER_STRENGTH_REQUIREMENTS"
        and arguments.get(("LOTM_RP_MOD_CONQUEST_PARTICLE_BEAM_STRENGTH", "Amount"))
        == "150",
        "Sequence 1 must grant five-times GDR Particle Beam district damage to all friendly combat units",
    )
    red_priest = modifiers.get("LOTM_RP_MOD_RED_PRIEST_WAR_PRODUCTION")
    validation.check(
        red_priest is not None
        and red_priest.findtext("ModifierType")
        == "MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_MODIFIER"
        and red_priest.findtext("OwnerRequirementSetId")
        == "LOTM_RP_REQSET_PLAYER_AT_WAR"
        and arguments.get(("LOTM_RP_MOD_RED_PRIEST_WAR_PRODUCTION", "YieldType"))
        == "YIELD_PRODUCTION"
        and arguments.get(("LOTM_RP_MOD_RED_PRIEST_WAR_PRODUCTION", "Amount")) == "800",
        "Sequence 0 must add +800% over inherited Sequence 3 for ten-times wartime Production",
    )


def validate_lifecycle(validation: Validation) -> None:
    path = ROOT / "Scripts" / "LOTM_RP_Lifecycle.lua"
    entrypoint_path = ROOT / "Scripts" / "LOTM_RP_Gameplay.lua"
    validation.require_file(path)
    validation.require_file(entrypoint_path, "single Gameplay entrypoint")
    if not path.is_file() or not entrypoint_path.is_file():
        return
    lua = strip_trace(path.read_text(encoding="utf-8"))
    entrypoint = strip_trace(entrypoint_path.read_text(encoding="utf-8"))
    expected_includes = (
        'include("LOTM_RP_Lifecycle")',
        'include("LOTM_RP_Progression")',
        'include("LOTM_RP_Arson")',
        'include("LOTM_RP_CommandProbe")',
    )
    positions = [entrypoint.find(token) for token in expected_includes]
    validation.check(
        all(position >= 0 for position in positions) and positions == sorted(positions),
        "single Gameplay entrypoint must include lifecycle, progression, arson, then probe",
    )

    required_functions = (
        "LOTM_RP_State.EnsurePlayerState",
        "LOTM_RP_State.IsEnabledPlayer",
        "LOTM_RP_State.GetSequence",
        "LOTM_RP_State.SetSequence",
        "LOTM_RP_State.TryAddDigestion",
        "LOTM_RP_State.GetPublicState",
        "LOTM_RP_State.FindHero",
        "LOTM_RP_State.EnsureHero",
        "LOTM_RP_State.SnapshotHero",
        "LOTM_RP_State.ScheduleRespawn",
        "LOTM_RP_State.AttachModifierOnce",
        "LOTM_RP_State.RefreshSequenceState",
        "LOTM_RP_State.AdvanceSequence",
    )
    for function_name in required_functions:
        validation.check(
            f"function {function_name}" in lua,
            f"missing state interface: {function_name}",
        )

    validation.check(
        all(
            token in lua
            for token in (
                "local function RefreshWarAuraSource",
                'GameInfo.UnitPromotions["PROMOTION_LOTM_RP_COMBAT_3"]',
                "experience:HasPromotion(promotion.Index)",
                'LOTM_Effects.SetAbilityCount(abilities, abilityType, desired)',
                'LOTM_RP_WAR_AURA_SOURCE_V2_STATE',
                'war aura source player=',
            )
        )
        and lua.count("RefreshWarAuraSource(playerID, hero)") >= 2
        and "RefreshWarAuraSource(playerID, unit)" in lua
        and "local function OnPostUnitPromotionEarned" in lua
        and "GameEvents.PostUnitPromotionEarned.Add(OnPostUnitPromotionEarned)" in lua,
        "Gameplay lifecycle must synchronize the V2 War Aura source on load, creation/respawn, and promotion snapshots",
    )

    fixed_properties = (
        "LOTM_RP_STATE_VERSION",
        "LOTM_RP_PATH",
        "LOTM_RP_PATH_DECIDED",
        "LOTM_RP_SEQUENCE",
        "LOTM_RP_DIGEST_A",
        "LOTM_RP_DIGEST_B",
        "LOTM_RP_DIGEST_TURN",
        "LOTM_RP_DIGEST_TURN_GAIN",
        "LOTM_RP_UNIT_ID",
        "LOTM_RP_RESPAWN_AT",
        "LOTM_RP_ARSON_READY_AT",
        "LOTM_RP_PLAN_TARGET_ID",
        "LOTM_RP_PLAN_TARGET_READY_AT",
        "LOTM_RP_SAVED_XP",
        "LOTM_RP_HUNTER_XP_BASELINE",
        "LOTM_RP_CHURCH_START_TURN",
        "LOTM_RP_TRUE_GOD_CHURCH",
        "LOTM_RP_CAN_ADVANCE_SEQUENCE_0",
        "LOTM_RP_SEQUENCE0_CEREMONY_SERIAL",
        "LOTM_RP_SEQUENCE0_CEREMONY_READY_TURN",
        "LOTM_RP_SEQUENCE0_CEREMONY_ACK_SERIAL",
        "LOTM_RP_SAVED_PROMOTIONS",
    )
    for property_name in fixed_properties:
        validation.check(
            f'"{property_name}"' in lua,
            f"missing synchronized player Property: {property_name}",
        )
    for internal_property in (
        "LOTM_RP_MOD_HUNTER_ATTACHED",
        "LOTM_RP_MOD_PROVOKER_ATTACHED",
        "LOTM_RP_PROJECT_PROVOKER_UNLOCKED",
        "LOTM_RP_PROJECT_PYROMANIAC_UNLOCKED",
        "LOTM_RP_MOD_IRONBLOOD_ATTACHED",
        "LOTM_RP_MOD_IRONBLOOD_MOVEMENT_ATTACHED",
        "LOTM_RP_MOD_IRONBLOOD_FRIENDLY_STRENGTH_V2_ATTACHED",
        "LOTM_RP_MOD_IRONBLOOD_FRIENDLY_MOVEMENT_V2_ATTACHED",
        "LOTM_RP_MOD_WAR_BISHOP_PRODUCTION_ATTACHED",
        "LOTM_RP_MOD_WAR_BISHOP_WEARINESS_ATTACHED",
        "LOTM_RP_MOD_WEATHER_ENEMY_STRENGTH_ATTACHED",
        "LOTM_RP_MOD_WEATHER_ENEMY_MOVEMENT_ATTACHED",
        "LOTM_RP_MOD_WEATHER_ENEMY_WEARINESS_ATTACHED",
        "LOTM_RP_MOD_WEATHER_ENEMY_STRENGTH_V2_ATTACHED",
        "LOTM_RP_MOD_WEATHER_ENEMY_MOVEMENT_V2_ATTACHED",
        "LOTM_RP_MOD_WEATHER_ENEMY_WEARINESS_V2_ATTACHED",
        "LOTM_RP_MOD_WEATHER_FRIENDLY_MOVEMENT_ATTACHED",
        "LOTM_RP_MOD_WEATHER_FRIENDLY_MOVEMENT_V2_ATTACHED",
        "LOTM_RP_MOD_CONQUEST_BYPASS_WALLS_ATTACHED",
        "LOTM_RP_MOD_RED_PRIEST_WAR_PRODUCTION_ATTACHED",
        "LOTM_RP_TECH_IRON_WORKING_ATTACHED",
        "LOTM_RP_TECH_APPRENTICESHIP_ATTACHED",
        "LOTM_RP_TECH_GUNPOWDER_ATTACHED",
        "LOTM_RP_TECH_MILITARY_SCIENCE_ATTACHED",
        "LOTM_RP_TECH_REPLACEABLE_PARTS_ATTACHED",
        "LOTM_RP_TECH_SATELLITES_ATTACHED",
        "LOTM_RP_PROJECT_CONSPIRATOR_UNLOCKED",
        "LOTM_RP_PROJECT_REAPER_UNLOCKED",
        "LOTM_RP_PROJECT_IRONBLOOD_UNLOCKED",
        "LOTM_RP_PROJECT_WAR_BISHOP_UNLOCKED",
        "LOTM_RP_PROJECT_WEATHER_WARLOCK_UNLOCKED",
        "LOTM_RP_PROJECT_CONQUEROR_UNLOCKED",
        "LOTM_RP_PROJECT_WAR_FESTIVAL_UNLOCKED",
    ):
        validation.check(
            f'"{internal_property}"' in lua,
            f"missing phase-03 idempotency Property: {internal_property}",
        )
    validation.check(
        "LOTM_RP_STATE_VERSION :number = 36" in lua,
		"Thief pathway migration must use synchronized state 36",
    )

    eligibility_tokens = (
        "player:IsAlive()",
        "player:IsMajor()",
        "player:IsHuman()",
        '"PATH_RED_PRIEST"',
    )
    for token in eligibility_tokens:
        validation.check(token in lua, f"enabled-player validation lacks {token}")

    lifecycle_tokens = (
        "PlayerManager.GetAliveMajorIDs()",
        'LOTM_MP_TurnSync.Add(OnPlayerTurnActivated,"Lifecycle")',
        "UnitManager.InitUnit(",
        "UnitManager.InitUnitValidAdjacentHex(",
        "UnitManager.Kill(hero, false)",
        "GameEvents.OnCombatOccurred.Add",
        "Events.UnitRemovedFromMap.Add",
        "GameEvents.CityBuilt.Add",
        "Game.GetCurrentGameTurn() + LOTM_RP_RESPAWN_DELAY",
        "LOTM_RP_RESPAWN_DELAY :number = 5",
        "experience:GetExperiencePoints()",
        "experience:ChangeExperience(",
        "experience:HasPromotion(",
        "experience:SetPromotion(",
        "experience:GetVeteranName()",
        "experience:SetVeteranName(",
    )
    for token in lifecycle_tokens:
        validation.check(token in lua, f"lifecycle implementation lacks {token}")

    tech_tokens = (
        '"TECH_IRON_WORKING"',
        '"TECH_APPRENTICESHIP"',
        '"TECH_GUNPOWDER"',
        '"TECH_MILITARY_SCIENCE"',
        '"TECH_REPLACEABLE_PARTS"',
        '"TECH_SATELLITES"',
        '"LOTM_RP_MOD_TECH_IRON_WORKING_COMBAT"',
        '"LOTM_RP_MOD_TECH_SATELLITES_COMBAT"',
        "player:AttachModifierByID(modifierID)",
        '"LOTM_RP_TECH_IRON_WORKING_ATTACHED"',
        '"LOTM_RP_TECH_SATELLITES_ATTACHED"',
    )
    for token in tech_tokens:
        validation.check(token in lua, f"technology scaling lacks {token}")

    digestion_tokens = (
        "LOTM_RP_DIGESTION_TARGET :number = 6",
        "LOTM_RP_DIGESTION_TURN_CAP :number = 2",
        'category ~= "A" and category ~= "B"',
        "LOTM_RP_DIGEST_SEEN_S",
        "EncodeStableObjectKey(objectKey)",
        "turnGain >= LOTM_RP_DIGESTION_TURN_CAP",
        "requestedAmount == 1",
        "Explicit multi-point bursts",
        "appliedAmount = math.min(requestedAmount",
        "currentTotal >= LOTM_RP_DIGESTION_TARGET",
        "RefreshProjectUnlock(playerID)",
        "player:SetProperty(counterKey",
        "player:SetProperty(LOTM_RP_PROPERTIES.DigestA, 0)",
        "player:SetProperty(LOTM_RP_PROPERTIES.DigestB, 0)",
        "nextSequence ~= expectedSequence - 1",
    )
    for token in digestion_tokens:
        validation.check(token in lua, f"digestion/advancement implementation lacks {token}")

    sequence_tokens = (
        '"LOTM_RP_MOD_GRANT_HUNTER_INSTINCT"',
        '"LOTM_RP_MOD_GRANT_PROVOKER"',
        '"LOTM_RP_MOD_ALLOW_PROVOKER_PROJECT"',
        '"LOTM_RP_MOD_ALLOW_PYROMANIAC_PROJECT"',
        '"LOTM_RP_MOD_IRONBLOOD_FRIENDLY_STRENGTH_AURA_V2"',
        '"LOTM_RP_MOD_IRONBLOOD_FRIENDLY_MOVEMENT_AURA_V2"',
        '"LOTM_RP_MOD_WAR_BISHOP_PRODUCTION"',
        '"LOTM_RP_MOD_WAR_BISHOP_WEARINESS"',
        '"LOTM_RP_MOD_WEATHER_ENEMY_STRENGTH_AURA_V2"',
        '"LOTM_RP_MOD_WEATHER_ENEMY_MOVEMENT_AURA_V2"',
        '"LOTM_RP_MOD_WEATHER_ENEMY_WEARINESS_AURA_V2"',
        '"LOTM_RP_MOD_WEATHER_FRIENDLY_MOVEMENT_AURA_V2"',
        '"LOTM_RP_MOD_GRANT_CONQUEST_BYPASS_WALLS"',
        '"LOTM_RP_MOD_RED_PRIEST_WAR_PRODUCTION"',
        '"LOTM_RP_MOD_ALLOW_CONSPIRATOR_PROJECT"',
        '"LOTM_RP_MOD_ALLOW_REAPER_PROJECT"',
        '"LOTM_RP_MOD_ALLOW_IRONBLOOD_PROJECT"',
        '"LOTM_RP_MOD_ALLOW_WAR_BISHOP_PROJECT"',
        '"LOTM_RP_MOD_ALLOW_WEATHER_WARLOCK_PROJECT"',
        '"LOTM_RP_MOD_ALLOW_CONQUEROR_PROJECT"',
        '"LOTM_RP_MOD_ALLOW_WAR_FESTIVAL_PROJECT"',
    )
    for token in sequence_tokens:
        validation.check(token in lua, f"sequence state synchronization lacks {token}")
    validation.check(
        "sequence < 0 or sequence > 9" in lua
        and "if sequence < 1 or sequence > 9 then" in lua
        and "if sequence <= 0 then" in lua,
        "state must allow Sequence 0 while refusing further digestion there",
    )
    validation.check(
        "LOTM_RP_PROPERTIES.CanAdvanceSequenceZero" in lua
        and "LOTM_RP_WAR_FESTIVAL_PROJECT_MODIFIER" in lua,
        "normal War Festival unlock must retain the synchronized True God Church discount",
    )
    validation.check(
        "LOTM_RP_UNCONSECRATED_WAR_FESTIVAL_PROJECT_MODIFIER" in lua
        and "LOTM_PP_MOD_ALLOW_UNCONSECRATED_CIVILIZATION_ASCENSION" in lua,
        "both Paths must expose a double-cost final ritual without the True God Church",
    )

    for forbidden in (
        "LOTM_RP_Command_Arson",
        "ImprovementBuilder",
        "SetDamage",
        "SetMovesRemaining",
    ):
        validation.check(forbidden not in lua, f"lifecycle must leave arson effects in the command script: {forbidden}")
    validation.check(
        "local function RetypeHeroForPath" in lua
        and lua.count("replacement:ChangeDamage(damage)") == 1
        and lua.count("replacement:ChangeMovesRemaining(moves - replacementMoves)") == 1,
        "path-specific holder migration must preserve damage and remaining movement exactly once",
    )
    validation.check(
        'local LOTM_PP_HERO_TYPE :string = "UNIT_LOTM_PP_PATH_HOLDER"' in lua
        and "GetExpectedHeroType(playerID)" in lua
        and "RetypeHeroForPath(playerID, hero, migratePromotionTree)" in lua,
        "lifecycle must create and migrate the holder to the selected pathway unit type",
    )
    validation.check(
        'PromotionTreeMigrated = "LOTM_RP_PROMOTION_TREE_MIGRATED"' in lua
        and "storedVersion <= 24" in lua
        and "forceRecreate == true" in lua
        and "cleared legacy Recon promotions" in lua
        and "promotion.PromotionClass == LOTM_PATH_HOLDER_PROMOTION_CLASS" in lua,
        "state 25 must replace legacy Recon promotions for living and pending holders",
    )
    validation.check(
        "m_retypedHeroUnitIDs[playerID] = oldUnitID" in lua
        and "m_retypedHeroUnitIDs[playerID] == unitID" in lua,
        "path-holder icon migration must suppress the exact retired unit removal event",
    )
    validation.check("LuaEvents" not in lua, "lifecycle must not use unsynchronized LuaEvents")


def validate_progression(validation: Validation) -> None:
    path = ROOT / "Scripts" / "LOTM_RP_Progression.lua"
    validation.require_file(path)
    if not path.is_file():
        return
    lua = strip_trace(path.read_text(encoding="utf-8"))

    event_tokens = (
        'LOTM_MP_TurnSync.Add(OnPlayerTurnActivated,"Progression")',
        "Events.UnitMoveComplete.Add",
        "Events.GoodyHutReward.Add",
        "Events.CityProjectCompleted.Add",
        "GameEvents.OnCombatOccurred.Add",
        "GameEvents.PostUnitPromotionEarned.Add",
        "GameEvents.LOTM_RP_Command_Denounce.Add",
        "GameEvents.LOTM_RP_Command_ChurchFounded.Add",
    )
    for token in event_tokens:
        validation.check(token in lua, f"progression event recognition lacks {token}")

    sequence9_tokens = (
        '"LOTM_RP_HUNTER_XP_BASELINE"',
        "hero:GetExperience()",
        "experience:GetExperiencePoints()",
        "currentXP > baseline",
        'LOTM_RP_State.TryAddDigestion(playerID, "A", objectKey)',
        '"HUNTER_XP:"',
    )
    for token in sequence9_tokens:
        validation.check(token in lua, f"sequence-9 event recognition lacks {token}")

    sequence8_tokens = (
        "local function OnCommandDenounce",
        "parameters.TargetPlayerID",
        "targetPlayer:IsAlive()",
        "targetPlayer:IsMajor()",
        '"DENOUNCE_TARGET:"',
        "defenderBase > attackerBase",
        "attackerUnit:GetCombat()",
        "defenderUnit:GetCombat()",
        '"TARGET_UNIT:"',
    )
    for token in sequence8_tokens:
        validation.check(token in lua, f"sequence-8 event recognition lacks {token}")
    provoker_denounce_tokens = (
        "sequence ~= 8",
        "parameters.DenounceTurn",
        "denounceTurn ~= math.floor(denounceTurn)",
        '"DENOUNCE_TARGET:"',
        "sequence8 digestion submitted",
    )
    for token in provoker_denounce_tokens:
        validation.check(
            token in lua,
            f"sequence-8 denouncement digestion lacks {token}",
        )
    validation.check(
        "LOTM_RP_CONSPIRATOR_GOLD" not in lua
        and "LOTM_RP_DENOUNCE_REWARD_TURN" not in lua,
        "general grievance rewards must not remain hard-coded as denouncement-only progression",
    )

    validation.check(
        "LOTM_RP_State.AdvanceSequence(playerID, 9, 8)" in lua
        and "LOTM_RP_State.AdvanceSequence(playerID, 8, 7)" in lua,
        "both project-completion advancement paths are missing",
    )
    church_tokens = (
        '"BELIEF_LOTM_RP_ESTABLISH_CHURCH"',
        '"BELIEF_LOTM_RP_TRUE_GOD_CHURCH"',
        "religion:GetPantheon()",
        "Game.GetReligion()",
        "gameReligion:GetReligions()",
        "(currentTurn - startTurn) % 3 == 0",
        '"CHURCH_TURN:"',
        '"TRUE_GOD_CHURCH_TURN:"',
        "player:SetProperty(LOTM_RP_CAN_ADVANCE_SEQUENCE_0, 1)",
        "local function OnCommandChurchFounded",
        "parameters.BeliefID",
        "LOTM_RP_State.IsAnyPathPlayer(playerID)",
    )
    for token in church_tokens:
        validation.check(token in lua, f"church digestion implementation lacks {token}")
    validation.check(
        "GetDenounceTurn" not in lua,
        "progression must not use UI-only GetDenounceTurn",
    )
    validation.check(
        "local function ObserveHunterExperience(playerID :number, hero)\n"
        "\tif not LOTM_RP_State.IsEnabledPlayer(playerID)" in lua,
        "Red Priest hero-experience digestion must not leak into the Perfect Path",
    )
    for removed_sequence9_api in (
        "PlayersVisibility[playerID]",
        "visibility:IsVisible(plotIndex)",
        "feature.NaturalWonder",
        "PlayerManager.IsBarbarian(opponentPlayerID)",
        "unit:GetPlotId()",
    ):
        validation.check(
            removed_sequence9_api not in lua,
            f"experience-driven sequence 9 must not use legacy scan API: {removed_sequence9_api}",
        )
    for forbidden in (
        "LOTM_RP_Command_Arson",
        "ImprovementBuilder",
        "ChangeDamage",
        "SetDamage",
        "ChangeMovesRemaining",
        "SetMovesRemaining",
        "LuaEvents",
    ):
        validation.check(forbidden not in lua, f"progression script contains arson/UI mutation token: {forbidden}")


def validate_path_choice(validation: Validation) -> None:
    gameplay_path = ROOT / "Scripts" / "LOTM_RP_Lifecycle.lua"
    perfect_path = ROOT / "Scripts" / "LOTM_PP_Perfect.lua"
    ui_path = ROOT / "UI" / "LOTM_RP_PathChoice.lua"
    xml_path = ROOT / "UI" / "LOTM_RP_PathChoice.xml"
    launch_path = ROOT / "UI" / "LOTM_RP_LaunchButton.lua"
    validation.require_file(ui_path, "first-turn path-choice UI script")
    validation.require_file(xml_path, "first-turn path-choice XML")
    validation.require_file(perfect_path, "Perfect Path Gameplay script")
    validation.require_file(launch_path, "path-specific LaunchBar script")
    if not all(
        path.is_file()
        for path in (gameplay_path, perfect_path, ui_path, xml_path, launch_path)
    ):
        return

    gameplay = strip_trace(gameplay_path.read_text(encoding="utf-8"))
    perfect = strip_trace(perfect_path.read_text(encoding="utf-8"))
    ui = strip_trace(ui_path.read_text(encoding="utf-8"))
    xml = strip_trace(xml_path.read_text(encoding="utf-8"))
    launch = strip_trace(launch_path.read_text(encoding="utf-8"))
    for token in (
        '"LOTM_RP_PATH_DECIDED"',
        "local function OnSelectPath",
        "GameEvents.LOTM_RP_Command_SelectPath.Add",
        "player:IsHuman()",
        "choice ~= LOTM_PP_SELECTED_PATH",
        "choice ~= LOTM_BE_SELECTED_PATH",
        'choice ~= "NONE"',
        "LOTM_RP_State.EnsureHero(playerID)",
    ):
        validation.check(token in gameplay, f"path-choice Gameplay validation lacks {token}")
    for token in (
        '"LOTM_RP_Command_SelectPath"',
        "UI.RequestPlayerOperation",
        "PlayerOperations.EXECUTE_SCRIPT",
        "parameters.OnStart",
        "parameters.Choice",
        "Events.GameCoreEventPublishComplete.Add",
        "Events.LoadGameViewStateDone.Add",
    ):
        validation.check(token in ui, f"path-choice synchronized UI flow lacks {token}")
    for token in (
        'ID="ChoicePopup"',
        'ID="ChooseRedPriestButton"',
        'ID="ChooseBlackEmperorButton"',
        'ID="ChooseNoneButton"',
    ):
        validation.check(token in xml, f"path-choice XML lacks {token}")
    for token in (
        '"LOTM_PP_MOD_GRANT_RELIC_V3_"',
        '"LOTM_PP_RELIC_GRANT_V3_"',
        "RepairRecordedRelicGrants(playerID, player)",
        "Events.GreatWorkCreated.Add(OnGreatWorkCreated)",
        "PROJECT_LOTM_PP_CIVILIZATION_ASCENSION = { 1, 0 }",
        "PROJECT_LOTM_PP_CIVILIZATION_ASCENSION_UNCONSECRATED",
        "advance.allowWithoutChurch == true",
        "AttachMysterySystem(playerID)",
        "technologies:TriggerBoost(technology.Index, 1)",
        "culture:TriggerBoost(civic.Index, 1)",
        "points:ChangePointsTotal(scientistClass.Index, 99999)",
        "Events.CivicCompleted.Add(OnCivicCompleted)",
        "Events.ResearchCompleted.Add(OnResearchCompleted)",
        'Events.UnitAddedToMap.Add(LOTM_UnitAddedPerf.Wrap("Perfect",OnUnitAddedToMap))',
    ):
        validation.check(token in perfect, f"Perfect Path implementation lacks {token}")
    black_emperor = strip_trace((ROOT / "Scripts" / "LOTM_BE_BlackEmperor.lua").read_text(
        encoding="utf-8"
    ))
    for token in (
        "GameEvents.OnCityPopulationChanged.Add(OnCityPopulationChanged)",
        "Events.CityTransfered.Add(OnCityTransfered)",
        "CityTransferTypes.BY_CULTURAL_IDENTITY",
        '"LOTM_BE_MOD_CORRUPT_PROSPERITY_FOOD"',
        '"LOTM_BE_MOD_ENTROPY_PRESSURE"',
        '"LOTM_BE_MOD_ENTROPY_LOYALTY"',
    ):
        validation.check(token in black_emperor, f"Black Emperor implementation lacks {token}")
    inherited_names = {
        "zh_Hans_CN": {
            9: "通识", 8: "历史遗物", 7: "价值鉴定", 6: "机械改造",
            5: "星象演算", 4: "炼金生产", 3: "奥秘体系",
            2: "知识传授", 1: "文明启蒙", 0: "完美文明",
        },
        "en_US": {
            9: "Generalist", 8: "Historical Relics", 7: "Appraisal",
            6: "Mechanical Improvement", 5: "Astronomical Calculation",
            4: "Alchemical Production", 3: "Mystery System",
            2: "Knowledge Teaching", 1: "Civilizational Enlightenment",
            0: "Perfect Civilization",
        },
    }
    for sequence in range(6, -1, -1):
        for language, by_sequence in inherited_names.items():
            source = strip_trace((
                ROOT / "Text" / language / "LOTM_RP_GameplayText.xml"
            ).read_text(encoding="utf-8"))
            tag = f'LOC_LOTM_PP_DETAILS_EFFECTS_S{sequence}"'
            start = source.find(tag)
            end = source.find("</Row>", start)
            details = source[start:end] if start >= 0 and end >= 0 else ""
            validation.check(
                all(by_sequence[index] in details for index in range(sequence, 10)),
                f"{language} Perfect S{sequence} must fully explain inherited skills",
            )
    validation.check(
        '"ICON_LOTM_PP_PERFECT_MARK"' in launch,
        "Perfect Path LaunchBar does not use its custom user-supplied mark",
    )


def validate_arson_and_hud(validation: Validation) -> None:
    gameplay_path = ROOT / "Scripts" / "LOTM_RP_Arson.lua"
    ui_path = ROOT / "UI" / "LOTM_RP_HUD.lua"
    xml_path = ROOT / "UI" / "LOTM_RP_HUD.xml"
    launch_ui_path = ROOT / "UI" / "LOTM_RP_LaunchButton.lua"
    launch_xml_path = ROOT / "UI" / "LOTM_RP_LaunchButton.xml"
    validation.require_file(gameplay_path, "phase-04 arson Gameplay script")
    validation.require_file(ui_path, "phase-04 HUD UI script")
    validation.require_file(xml_path, "phase-04 HUD XML")
    validation.require_file(launch_ui_path, "launch-bar button UI script")
    validation.require_file(launch_xml_path, "launch-bar button XML")
    if not all(
        path.is_file()
        for path in (gameplay_path, ui_path, xml_path, launch_ui_path, launch_xml_path)
    ):
        return

    gameplay = strip_trace(gameplay_path.read_text(encoding="utf-8"))
    ui = strip_trace(ui_path.read_text(encoding="utf-8"))
    xml = strip_trace(xml_path.read_text(encoding="utf-8"))
    launch_ui = strip_trace(launch_ui_path.read_text(encoding="utf-8"))
    launch_xml = strip_trace(launch_xml_path.read_text(encoding="utf-8"))
    validation.check(
        "local supportedSequence = math.max(0, math.min(9, sequence));" in ui
        and "math.max(4, math.min(9, sequence))" not in ui,
        "Perfect Path UI must resolve current/detail/next/digestion text for Sequences 0 through 9",
    )

    command_tokens = (
        '"LOTM_RP_Command_Arson"',
        "GameEvents.LOTM_RP_Command_Arson.Add",
        "UnitCommandTypes.PARAM_X",
        "UnitCommandTypes.PARAM_Y",
        "LOTM_RP_State.IsEnabledPlayer(ownerID)",
        "player:IsTurnActive()",
        "LOTM_RP_UNIT_ID_PROPERTY",
        "LOTM_RP_SEQUENCE_PROPERTY",
        "unit:IsDead()",
        "unit:IsDelayedDeath()",
        "LOTM_RP_ARSON_READY_AT_PROPERTY",
        "PlayersVisibility[ownerID]",
        "visibility:IsVisible(plot:GetIndex())",
        "Map.GetPlotDistance",
        "plot:IsWater()",
        "plot:IsCity()",
        "ERROR rejected command",
    )
    for token in command_tokens:
        validation.check(token in gameplay, f"arson Gameplay validation lacks {token}")
    validation.check(
        '(player:GetProperty(LOTM_RP_SEQUENCE_PROPERTY) or 9) > 7' in gameplay
        and 'player is not sequence 7' not in gameplay,
        "Arson Gameplay must remain usable after inheriting Sequence 7",
    )

    effect_tokens = (
        "LOTM_RP_ARSON_RANGE :number = 6",
        "LOTM_RP_ARSON_COOLDOWN :number = 5",
        "LOTM_RP_BURN_DURATION :number = 9",
        "plot:GetDistrictType" not in gameplay,
        "Units.GetUnitsInPlot(plot)",
        "diplomacy:IsAtWarWith(targetUnit:GetOwner())",
        "HasEnemyUnit(ownerID, plot)",
        "KillEnemyUnits(ownerID, plot)",
        "UnitManager.Kill(targetUnit)",
        "UnitManager.FinishMoves(unit)",
        "currentTurn + LOTM_RP_ARSON_COOLDOWN",
        "currentTurn + LOTM_RP_BURN_DURATION",
        'LOTM_RP_State.TryAddDigestion(\n\t\townerID,\n\t\t"A"',
        "Game.AddWorldViewText(\n\t\t0,",
    )
    for token in effect_tokens:
        if isinstance(token, bool):
            validation.check(token, "arson must not mutate or query district pillage state")
        else:
            validation.check(token in gameplay, f"arson Gameplay effects lack {token}")

    pillage_tokens = (
        "GameEvents.OnPillage.Add",
        'LOTM_RP_State.TryAddDigestion(\n\t\tplayerID,\n\t\t"B"',
        '"PILLAGE:"',
    )
    for token in pillage_tokens:
        validation.check(token in gameplay, f"ordinary-pillage digestion lacks {token}")

    burn_tokens = (
        "LOTM_RP_BURN_STARTED_AT",
        "LOTM_RP_BURN_UNTIL",
        "LOTM_RP_BURN_OWNER",
        "LOTM_RP_BURN_REVISION",
        "CleanupExpiredBurning",
        "currentTurn >= burnUntil",
        "plot:SetProperty(LOTM_RP_BURN_UNTIL, nil)",
        'LOTM_MP_TurnSync.Add(OnPlayerTurnActivated,"Arson")',
    )
    for token in burn_tokens:
        validation.check(token in gameplay, f"burn persistence/cleanup lacks {token}")

    for token in (
        "DeclareWar",
        "RequestPlayerOperation",
        "PlayerOperations",
    ):
        validation.check(
            token not in gameplay,
            f"arson must not trigger war or diplomacy through {token}",
        )

    ui_command_tokens = (
        '"LOTM_RP_Command_Arson"',
        "LOTM_RP_ARSON_RANGE :number = 6",
        "UnitManager.RequestCommand",
        "UnitCommandTypes.EXECUTE_SCRIPT",
        "parameters[UnitCommandTypes.PARAM_NAME]",
        "parameters[UnitCommandTypes.PARAM_X]",
        "parameters[UnitCommandTypes.PARAM_Y]",
        "UI.GetCursorPlotID()",
        "ContextPtr:SetInputHandler",
        "MouseEvents.LButtonUp",
        "Keys.VK_ESCAPE",
        "UILens.SetLayerHexesArea",
        "PlayersVisibility[playerID]",
        "Map.GetPlotDistance",
    )
    for token in ui_command_tokens:
        validation.check(token in ui, f"arson UI target/command flow lacks {token}")
    validation.check(
        'GetProperty(player, "LOTM_RP_SEQUENCE", 9) > 7' in ui
        and 'GetProperty(player, "LOTM_RP_SEQUENCE", 9) ~= 7' not in ui,
        "Arson UI must allow targeting after inheriting Sequence 7",
    )
    validation.check(
        "GetAdvancementText(sequence, digestA + digestB)" in ui
        and 'LOC_LOTM_RP_HUD_NEXT_S5_UNLOCKED' in ui,
        "Sequence 5 must explain the Industrialization gate after project unlock",
    )

    hud_tokens = (
        "Game.GetLocalPlayer()",
        "LOTM_RP_PATH",
        "LOTM_RP_SEQUENCE",
        "LOTM_RP_DIGEST_A",
        "LOTM_RP_DIGEST_B",
        "LOTM_RP_ARSON_READY_AT",
        "LOTM_RP_UNIT_ID",
        "LOC_LOTM_RP_HUD_SEQUENCE",
        "LOC_LOTM_RP_HUD_PROGRESS_SINGLE",
        "Events.GameCoreEventPublishComplete.Add",
        "Events.LoadGameViewStateDone.Add",
        'ID="DetailsPopup"',
        'ID="LocateHeroButton"',
        'ID="ArsonButton"',
		'ID="ManualButton"',
        'ID="PlanTargetButton"',
        'ID="TargetHint"',
        'ID="SkillEffectsLabel"',
		'ID="SkillEffectsScroll"',
        'ID="DigestionLabel"',
        'Style="FontNormal16"',
        'LOC_LOTM_RP_HUD_DIGEST_S9',
        'LOC_LOTM_RP_HUD_DIGEST_S2',
        'LOC_LOTM_RP_HUD_DIGEST_S1',
        'LOC_LOTM_RP_HUD_DIGEST_S0',
        "LOC_LOTM_RP_HUD_PROGRESS_SINGLE",
        "LOC_LOTM_RP_HUD_PROGRESS_COMPLETE",
        "LOC_LOTM_RP_DETAILS_EFFECTS",
        "Events.DiplomacyStatement.Add",
        "Events.DiplomacySessionClosed.Add",
        "Events.PantheonFounded.Add",
        "playerDiplomacy:GetDenounceTurn",
        "local function PollDiplomacyChanges",
        "m_denounceTurns",
        "parameters.DenounceTurn",
        '"LOTM_RP_Command_SelectPlanTarget"',
        "LOTM_RP_PLAN_GOLD_ACTIVE",
        "local function RefreshYieldTooltips",
        'ContextPtr:LookUpControl("/InGame/TopPanel/YieldStack")',
        "expenseSectionStart",
        '"LOC_LOTM_RP_PLAN_GOLD_TOOLTIP"',
        '"LOTM_PP_ORDER_CONVERTED_LAST"',
        '"LOC_LOTM_ARTIFACT_YIELD_INCLUDED_TOOLTIP"',
        '"LOTM_RP_Command_Denounce"',
        '"LOTM_RP_Command_ChurchFounded"',
        "UI.RequestPlayerOperation",
        "PlayerOperations.EXECUTE_SCRIPT",
        "LuaEvents.LOTM_RP_UI_ToggleDetails.Add",
		"LuaEvents.InGameTopOptionsMenu_ShowExpansionIntro()",
    )
    combined_ui = ui + "\n" + xml
    for token in hud_tokens:
        validation.check(token in combined_ui, f"local HUD lacks {token}")
    validation.check(
        "CategoryALabel" not in combined_ui
        and "CategoryBLabel" not in combined_ui
        and "LOC_LOTM_RP_HUD_PROGRESS\"" not in combined_ui,
        "details page must not contain A/B category UI",
    )
    validation.check(
        'ID="StormButton"' not in combined_ui
        and "LOTM_RP_Command_WeatherStorm" not in combined_ui
        and 'ID="SkillEffectsScroll"' in xml
        and 'Offset="22,404"' in xml
        and 'Size="754,424"' in xml
        and 'ConsumeMouse="1"' in xml,
        "Weather Storm targeting must be removed and the skill scroll must stay inside the details frame",
    )
    validation.check(
        'ID="SkillsLabel"' in xml
        and 'Hidden="1"' in xml.split('ID="SkillsLabel"', 1)[1].split('/>', 1)[0]
        and "Controls.SkillsLabel:SetHide(true)" in ui
        and "GetSequenceName(path, sequence)" in ui,
        "all paths must hide the standalone skill summary and append the Sequence name to its title",
    )
    for language in ("en_US", "zh_Hans_CN"):
        text = strip_trace((ROOT / "Text" / language / "LOTM_RP_GameplayText.xml").read_text(
            encoding="utf-8"
        ))
        for prefix, sequences in (
            ("LOC_LOTM_RP_HUD_SEQUENCE_NAME_S", range(10)),
            ("LOC_LOTM_PP_HUD_SEQUENCE_NAME_S", range(10)),
            ("LOC_LOTM_BE_HUD_SEQUENCE_NAME_S", range(5, 10)),
        ):
            for sequence in sequences:
                validation.check(
                    f'{prefix}{sequence}"' in text,
                    f"{language} lacks the visible Sequence name {prefix}{sequence}",
                )
    validation.check(
        'ID="SkillEffectsLabel"' in xml
        and 'Size="682,auto"' in xml
        and 'WrapWidth="682"' in xml
        and 'WrapWidth="718"' not in xml
        and 'ID="SkillEffectsStack"' in xml
        and 'StackPadding="10"' in xml
        and 'Style="ScrollVerticalBarAlt"' in xml
        and "math.min(380,math.max(220,innerH-334))" in ui
        and "Controls.RescueCityAIHintLabel:SetColor(UI.GetColorValue(0.78, 0.32, 1.0, 1.0))" in ui,
        "skill text must reserve a right gutter for the vertical scrollbar",
    )
    validation.check(
        "local sequence = GetProperty(player, \"LOTM_RP_SEQUENCE\", 9);" in ui
        and "sequence == 8" in ui
        and 'GetProperty(player, "LOTM_RP_PATH", "NONE") == LOTM_RP_PATH' in ui
        and "previousTurn ~= nil" in ui
        and "denounceTurn ~= previousTurn" in ui
        and "local showPlanTarget = isRedPriest and sequence <= 6" in ui
        and 'GetProperty(Game, "LOTM_RESCUE_MODE", 0) ~= 1' in ui,
        "UI must preserve ordinary denouncement/War Planning while hiding retired rescue War Planning",
    )
    validation.check(
        'ID="HeroLabel"' not in xml
        and 'ID="CooldownLabel"' not in xml
        and "Controls.HeroLabel" not in ui
        and "Controls.CooldownLabel" not in ui
        and "GetCooldownText" not in ui,
        "details page must omit the Path Holder and Arson cooldown status rows",
    )
    for language, filepath, forbidden in (
        ("zh_Hans_CN", ROOT / "Text" / "zh_Hans_CN" / "LOTM_RP_GameplayText.xml", "保留此前全部作用"),
        ("en_US", ROOT / "Text" / "en_US" / "LOTM_RP_GameplayText.xml", "all earlier effects are retained"),
    ):
        text = strip_trace(filepath.read_text(encoding="utf-8"))
        validation.check(
            forbidden not in text,
            f"{language} inherited-skill descriptions must enumerate effects rather than summarize them",
        )
        for sequence in ("S8", "S7", "S6", "S5", "S4", "S3", "S2", "S1", "S0"):
            tag = f"LOC_LOTM_RP_DETAILS_EFFECTS_{sequence}"
            start = text.find(tag)
            end = text.find("</Row>", start)
            effects_text = text[start:end] if start >= 0 and end >= 0 else ""
            validation.check(
                bool(effects_text)
                and "[NEWLINE][NEWLINE]" in effects_text
                and "[NEWLINE]" not in effects_text.replace("[NEWLINE][NEWLINE]", ""),
                f"{language} {sequence} details must separate every skill entry with a blank line",
            )
            validation.check(
                all(
                    token not in effects_text
                    for token in (
                        "消化",
                        "digestion",
                        "digest",
                    )
                ),
                f"{language} {sequence} skill descriptions must not contain digestion rules",
            )
    validation.check(
        'LOC_LOTM_RP_HUD_SKILLS_S0' in ui
        and 'LOC_LOTM_RP_DETAILS_EFFECTS_S0' in ui
        and 'LOC_LOTM_RP_HUD_NEXT_S0' in ui
        and 'LOC_LOTM_RP_HUD_PROGRESS_COMPLETE' in ui,
        "HUD must distinguish Sequence 0 from Sequence 1 and hide the 0/6 progress display",
    )

    forbidden_ui_mutations = (
        "SetProperty",
        "ChangeDamage",
        "SetDamage",
        "FinishMoves",
        "ChangeMovesRemaining",
        "SetImprovementPillaged",
        "ImprovementBuilder",
        "UnitManager.Kill",
        "UnitManager.InitUnit",
    )
    for token in forbidden_ui_mutations:
        validation.check(token not in ui, f"UI contains forbidden Gameplay mutation path: {token}")
    launch_tokens = (
        'ContextPtr:LookUpControl("/InGame/LaunchBar/ButtonStack")',
        'ContextPtr:BuildInstanceForControl("LOTM_RP_LaunchBarItem"',
        "IconManager:FindIconAtlas",
        "LuaEvents.LaunchBar_Resize",
        "LuaEvents.LOTM_RP_UI_ToggleDetails",
        'Name="LOTM_RP_LaunchBarItem"',
        'ID="LaunchItemButton"',
        'ID="LaunchItemIcon" Size="40,40"',
        "LOTM_RP_SEQUENCE0_CEREMONY_SERIAL",
        "LOTM_RP_SEQUENCE0_CEREMONY_ACK_SERIAL",
        "LOTM_RP_SEQUENCE0_CEREMONY_READY_TURN",
        "LuaEvents.LOTM_RP_Sequence0Ceremony_Request()",
        "LuaEvents.LOTM_RP_Sequence0Ceremony_Shown.Add",
    )
    combined_launch = launch_ui + "\n" + launch_xml
    for token in launch_tokens:
        validation.check(token in combined_launch, f"launch-bar integration lacks {token}")


def validate_sequence_zero_ceremony(validation: Validation) -> None:
    lua_path = ROOT / "UI" / "LOTM_RP_Sequence0Ceremony.lua"
    xml_path = ROOT / "UI" / "LOTM_RP_Sequence0Ceremony.xml"
    lifecycle_path = ROOT / "Scripts" / "LOTM_RP_Lifecycle.lua"
    validation.require_file(lua_path, "Sequence 0 ceremony UI script")
    validation.require_file(xml_path, "Sequence 0 ceremony UI XML")
    if not lua_path.is_file() or not xml_path.is_file() or not lifecycle_path.is_file():
        return

    lua = strip_trace(lua_path.read_text(encoding="utf-8"))
    xml = strip_trace(xml_path.read_text(encoding="utf-8"))
    lifecycle = strip_trace(lifecycle_path.read_text(encoding="utf-8"))
    for token in (
        '"LOTM_RP_Command_AcknowledgeSequence0Ceremony"',
        "UI.RequestPlayerOperation",
        "PlayerOperations.EXECUTE_SCRIPT",
        "LuaEvents.LOTM_RP_Sequence0Ceremony_Request.Add(TryShow)",
        "LuaEvents.LOTM_RP_Sequence0Ceremony_Shown(m_pendingSerial)",
        "isBlackEmperor and LOTM_BE_ICON or (m_pendingPath == LOTM_TP_PATH and LOTM_TP_ICON or LOTM_RP_ICON)",
        "local function ConfigureCeremony(path :string)",
        'and "LOC_LOTM_PP_SEQUENCE0_CEREMONY_"',
        "Controls.CeremonyLine4:SetHide(isPerfect)",
        "UI.GetColorValue(1, 0.72, 0, 1)",
        'UI.PlaySound("UI_Era_Change")',
        "UIManager:IsInPopupQueue(ContextPtr)",
        "PopupPriority.High",
        "ContextPtr:SetHide(true)",
        "Keys.VK_ESCAPE",
        "Controls.ContinueButton:RegisterCallback(Mouse.eLClick, OnContinue)",
        "Controls.CeremonyAnimation:Reverse()",
    ):
        validation.check(token in lua, f"Sequence 0 ceremony UI lacks {token}")
    for token in (
        'ID="CeremonyAnimation"',
        'ID="CeremonyMark"',
        'ID="ContinueButton"',
        'String="LOC_CONTINUE"',
        'FontSize="26"',
        'LOC_LOTM_RP_SEQUENCE0_CEREMONY_TITLE',
        'LOC_LOTM_RP_SEQUENCE0_CEREMONY_LINE_4',
        'Color="255,42,28,255"',
    ):
        validation.check(token in xml, f"Sequence 0 ceremony XML lacks {token}")
    validation.check(
        'include("PopupManager")' not in lua
        and "ExclusivePopupManager" not in lua
        and "PopupPriority.Low" not in lua
        and "DelayShow" not in lua
        and "/InGame/NewTurnPanel" not in lua
        and "/InGame/EraCompletePopup" not in lua
        and "ContextPtr:SetUpdate(" not in lua
        and "Events.LocalPlayerTurnBegin.Add" not in lua
        and "Events.LoadGameViewStateDone.Add" not in lua,
        "Sequence 0 ceremony must be requested only by the LaunchBar click",
    )
    on_show_start = lua.find("local function OnShow()")
    on_show_end = lua.find("local function SelectCeremonyIconSize", on_show_start)
    on_continue_start = lua.find("local function OnContinue()")
    on_continue_end = lua.find("local function OnShow()", on_continue_start)
    validation.check(
        on_show_start >= 0
        and on_show_end > on_show_start
        and on_continue_start >= 0
        and on_continue_end > on_continue_start
        and "SubmitAcknowledgement(" not in lua[on_show_start:on_show_end]
        and "SubmitAcknowledgement(" in lua[on_continue_start:on_continue_end],
        "Sequence 0 ceremony must acknowledge only when Continue is clicked",
    )
    validation.check(
        'EndPause="9"' not in xml
        and 'Cycle="OneBounce"' not in xml
        and "MouseEvents.LButtonUp" not in lua
        and "MouseEvents.PointerUp" not in lua,
        "Sequence 0 ceremony must remain visible until Continue is clicked",
    )
    validation.check(
        all(
            (
                f'Name="ICON_ATLAS_LOTM_RP_RED_PRIEST_MARK" IconSize="{size}"'
                in strip_trace((ROOT / "Art" / "LOTM_RP_Icons.xml").read_text(encoding="utf-8"))
                and f'Name="ICON_ATLAS_LOTM_PP_PERFECT_MARK" IconSize="{size}"'
                in strip_trace((ROOT / "Art" / "LOTM_RP_Icons.xml").read_text(encoding="utf-8"))
            )
            for size in (384, 512, 640, 768)
        )
        and "SelectCeremonyIconSize(screenY" in lua
        and "screenY * 0.46" in lua,
        "Sequence 0 ceremony must select a centered exact-size atlas about 20 percent smaller",
    )
    validation.check(
        "SetProperty" not in lua,
        "Sequence 0 ceremony UI must not write Gameplay properties directly",
    )
    for token in (
        "Game.GetCurrentGameTurn()",
        "LOTM_RP_SEQUENCE0_CEREMONY_SERIAL",
        "LOTM_RP_SEQUENCE0_CEREMONY_READY_TURN",
        "LOTM_RP_SEQUENCE0_CEREMONY_ACK_SERIAL",
        "GameEvents.LOTM_RP_Command_AcknowledgeSequence0Ceremony.Add",
        "requestedSerial ~= currentSerial",
        "storedVersion == 12",
        "ceremonySerial - 1",
        "for one deferred replay",
        "LOTM_RP_State.IsAnyPathPlayer(playerID)",
        "backfilled Perfect Path sequence-0 ceremony serial=1",
    ):
        validation.check(token in lifecycle, f"Sequence 0 ceremony Gameplay lacks {token}")
    validation.check(
        "Game.GetCurrentGameTurn() + 1" not in lifecycle,
        "click-triggered Sequence 0 ceremony must be ready in the advancement turn",
    )


def validate_comic_viewer(validation: Validation) -> None:
    builder_path = ROOT / "Tests" / "build_comics.py"
    lua_path = ROOT / "UI" / "LOTM_RP_ComicViewer.lua"
    xml_path = ROOT / "UI" / "LOTM_RP_ComicViewer.xml"
    for path, label in (
        (builder_path, "comic asset builder"),
        (lua_path, "comic viewer UI script"),
        (xml_path, "comic viewer UI XML"),
    ):
        validation.require_file(path, label)
    if not all(path.is_file() for path in (builder_path, lua_path, xml_path)):
        return

    builder = strip_trace(builder_path.read_text(encoding="utf-8"))
    lua = strip_trace(lua_path.read_text(encoding="utf-8"))
    xml = strip_trace(xml_path.read_text(encoding="utf-8"))
    hud = strip_trace((ROOT / "UI" / "LOTM_RP_HUD.lua").read_text(encoding="utf-8"))
    launch = strip_trace((ROOT / "UI" / "LOTM_RP_LaunchButton.lua").read_text(encoding="utf-8"))
    lifecycle = strip_trace((ROOT / "Scripts" / "LOTM_RP_Lifecycle.lua").read_text(encoding="utf-8"))
    modinfo = strip_trace(MODINFO.read_text(encoding="utf-8"))
    dimensions = {
        "1-1": (1122, 1402), "1-2": (1122, 1402), "1-3": (1024, 1536),
        "2-1": (1024, 1536), "2-2": (1086, 1448), "2-3": (1024, 1536),
        "2-4": (1055, 1491), "2-5": (1086, 1448), "2-6": (1122, 1402),
        "2-7": (1122, 1402), "2-8": (1086, 1448),
        "3-1": (1086, 1448), "3-2": (1024, 1536),
    }
    for key, expected_size in dimensions.items():
        png_path = ROOT / "Art" / "Comics" / f"LOTM_Comic_{key}.png"
        dds_path = ROOT / "Art" / "Comics" / f"LOTM_Comic_{key}.dds"
        validation.require_file(png_path, f"original comic PNG {key}")
        validation.require_file(dds_path, f"runtime comic DDS {key}")
        if png_path.is_file():
            header = png_path.read_bytes()[:24]
            valid_png = len(header) == 24 and header[:8] == b"\x89PNG\r\n\x1a\n"
            validation.check(valid_png, f"comic {key} original is not a valid PNG")
            if valid_png:
                width, height = struct.unpack(">II", header[16:24])
                validation.check(
                    (width, height) == expected_size,
                    f"comic {key} PNG dimensions changed from {expected_size}",
                )
        if dds_path.is_file():
            header = dds_path.read_bytes()[:128]
            valid_dds = len(header) == 128 and header[:4] == b"DDS "
            validation.check(valid_dds, f"comic {key} runtime file is not a DDS texture")
            if valid_dds:
                height, width = struct.unpack_from("<II", header, 12)
                validation.check(
                    (width, height) == expected_size,
                    f"comic {key} DDS must preserve PNG dimensions {expected_size}",
                )
                validation.check(
                    header[84:88] == b"DXT5",
                    f"comic {key} DDS must use the Sequence-0-compatible DXT5 path",
                )
        dds_token = f"Art/Comics/LOTM_Comic_{key}.dds"
        png_token = f"Art/Comics/LOTM_Comic_{key}.png"
        validation.check(
            modinfo.count(dds_token) >= 2 and modinfo.count(png_token) >= 1,
            f"comic {key} must import DDS for runtime and retain its original PNG",
        )

    validation.check(
        "copy2(source, png_target)" in builder
        and 'format="DDS"' in builder
        and 'pixel_format="DXT5"' in builder
        and ".resize(" not in builder
        and ".thumbnail(" not in builder
        and ".crop(" not in builder,
        "comic builder must preserve PNGs and create same-size DXT5 without scaling or crop",
    )
    validation.check(
        'local textureName = "LOTM_Comic_" .. key .. ".dds"' in lua
        and "Controls.ComicImage:SetTexture(textureName)" in lua
        and '-- Controls.ComicImage:SetTexture("LOTM_Comic_" .. key .. ".png")' in lua,
        "comic viewer must use DDS while retaining the rejected PNG binding as a comment",
    )
    validation.check(
        "local winningTeam = Game.GetWinningTeam();" in lua
        and "if winningTeam == nil then return; end" in lua
        and "tonumber(Game.GetWinningTeam())" not in lua,
        "comic victory fallback must accept Game.GetWinningTeam returning no values",
    )
    validation.check(
        "math.min(1240, math.max(720, x - 24))" in lua
        and "math.min(1060, math.max(560, y - 24))" in lua
        and "Controls.Popup:GetSizeX() - 48" in lua,
        "comic popup must use the enlarged screen-bounded native-page viewport",
    )
    validation.check(
        '"LOC_LOTM_COMIC_FINISH" or "LOC_LOTM_COMIC_NEXT"' in lua
        and "Controls.Next:SetDisabled(false)" in lua
        and "local function Finish()" in lua
        and "LuaEvents.LOTM_Comic_ReturnToSequence();" in lua
        and "LuaEvents.LOTM_Comic_ReturnToSequence.Add(OpenDetails);" in hud,
        "comic Finish must preserve the prologue return route",
    )
    validation.check(
        'ID="CategoryVictory" Hidden="1"' in xml
        and 'ID="CategoryDefeat" Hidden="1"' in xml
        and "Controls.CategoryVictory:RegisterCallback" not in lua
        and "Controls.CategoryDefeat:RegisterCallback" not in lua
        and 'LuaEvents.LOTM_Comic_ShowReview.Add(function() Show("START"); end)' in lua
        and "Events.TeamVictory.Add" in lua
        and "ShowOutcomeForTeam" in lua,
        "prologue review and automatic outcomes must remain available alongside manual ending review",
    )
    validation.check(
        'Offset="-136,22"' in xml,
        "comic Next/Finish button must move farther left by the requested offset",
    )
    validation.check(
        'LOTM_RP_OPENING_COMIC_SHOWN' in launch
        and 'm_openingComicRequested = true' in launch
        and 'OnStart = LOTM_RP_OPENING_COMIC_COMMAND' in launch
        and 'Options.GetUserOption("Tutorial", optionKey)' not in launch
        and 'OpeningComicShown = "LOTM_RP_OPENING_COMIC_SHOWN"' in lifecycle
        and 'GameEvents.LOTM_RP_Command_MarkOpeningComicShown.Add(OnMarkOpeningComicShown)' in lifecycle,
        "opening comic must use an immediate UI guard plus a synchronized save-persistent marker",
    )


def validate_advanced_sequences(validation: Validation) -> None:
    path = ROOT / "Scripts" / "LOTM_RP_Advanced.lua"
    validation.require_file(path, "sequence-6–0 Gameplay script")
    if not path.is_file():
        return
    lua = strip_trace(path.read_text(encoding="utf-8"))
    lifecycle = strip_trace((ROOT / "Scripts" / "LOTM_RP_Lifecycle.lua").read_text(encoding="utf-8"))
    for token in (
        "GameEvents.OnCombatOccurred.Add",
        "GameEvents.CityConquered.Add",
        "Events.CityProjectCompleted.Add",
        'LOTM_MP_TurnSync.Add(OnPlayerTurnActivated,"Advanced")',
        "GameEvents.LOTM_RP_Command_SelectPlanTarget.Add",
        "LOTM_RP_PROVOKER_GARRISON_ABILITY",
        "hero:GetFortifyTurns()",
        "ability:GetAbilityCount(LOTM_RP_PROVOKER_GARRISON_ABILITY)",
        "ability:ChangeAbilityCount",
        "hero:ChangeDamage(-damage)",
        "LOTM_RP_COMMAND_PLAN_TARGET",
        "LOTM_RP_PLAN_FIRST_WAR_GOLD :number = 1000",
        "LOTM_RP_PLAN_GOLD_START_MODIFIER",
        "LOTM_RP_PLAN_GOLD_STOP_MODIFIER",
        "LOTM_RP_PLAN_GOLD_MODIFIER_ACTIVE",
        "SetPlanningIncomeModifier",
        "player:AttachModifierByID",
        "local function OnCommandSelectPlanTarget",
        "local function ProcessPlannedWarEconomy",
        "Events.DiplomacyDeclareWar.Add",
        "Events.DiplomacyMakePeace.Add",
        "LOTM_RP_PLAN_FIRST_WAR_REWARDED:",
        "ChangeGoldBalance",
        '"PLANNED_WAR:"',
        "local amount = IsLivingHero(attackerUnit, playerID) and 60 or 30;",
        "LOTM_RP_State.TryAddDigestion",
        "LOTM_RP_State.AdvanceSequence",
        "TECH_INDUSTRIALIZATION",
        "MilitaryFormationTypes.CORPS_FORMATION",
        "MilitaryFormationTypes.ARMY_FORMATION",
        "city:ChangeLoyalty(15)",
    ):
        validation.check(token in lua, f"sequence-6–0 Gameplay lacks {token}")
    validation.check(
        "LOTM_RP_PLAN_TURN_GOLD" not in lua
        and "LOTM_RP_PLAN_INCOME_LAST_TURN" not in lua,
        "planning income must use native yield modifiers, not direct per-turn balance changes",
    )
    modifier_xml = strip_trace((ROOT / "Gameplay" / "LOTM_RP_Modifiers.xml").read_text(
        encoding="utf-8"
    ))
    for token in (
        'ModifierId="LOTM_RP_MOD_PLAN_GOLD_PER_TURN_START"',
        'ModifierId="LOTM_RP_MOD_PLAN_GOLD_PER_TURN_STOP"',
        'ModifierType="MODIFIER_PLAYER_ADJUST_YIELD_CHANGE"',
        'Name="YieldType" Value="YIELD_GOLD"',
        'Name="Amount" Value="100"',
        'Name="Amount" Value="-100"',
    ):
        validation.check(token in modifier_xml, f"native planning Gold modifier lacks {token}")
    validation.check(
        "GetGrievanceLogEntries" not in lua
        and "LOTM_RP_GRIEVANCE" not in lua
        and "Command_ScanGrievances" not in lua,
        "obsolete grievance detection must be fully removed from advanced Gameplay",
    )
    for removed_storm_token in (
        "LOTM_RP_Command_WeatherStorm",
        "LOTM_RP_STORM_READY_AT",
        "LOTM_RP_STORM_LAST_PLOT",
        "LOTM_RP_STORM_OWNER",
        "LOTM_RP_STORM_UNTIL",
        "ProcessStorms",
    ):
        validation.check(
            removed_storm_token not in lua,
            f"obsolete Weather Storm Gameplay state remains: {removed_storm_token}",
        )
    for project in (
        CONSPIRATOR_PROJECT,
        REAPER_PROJECT,
        IRONBLOOD_PROJECT,
        WAR_BISHOP_PROJECT,
        WEATHER_WARLOCK_PROJECT,
        CONQUEROR_PROJECT,
        WAR_FESTIVAL_PROJECT,
    ):
        validation.check(project in lua, f"advanced project flow lacks {project}")
    validation.check(
        '"PROJECT_LOTM_RP_CONQUEROR_POTION"] = { from = 2, to = 1 }' in lua
        and '"PROJECT_LOTM_RP_WAR_FESTIVAL"] = {' in lua
        and '"PROJECT_LOTM_RP_WAR_FESTIVAL_UNCONSECRATED"] = {' in lua,
        "advanced project flow must implement Sequence 2→1 and 1→0",
    )
    validation.check(
        "local function ProcessWeatherDigestion" in lua
        and 'LOTM_RP_State.GetSequence(playerID) ~= 2' in lua
        and '"WEATHER_WAR_TURN:" .. tostring(Game.GetCurrentGameTurn())' in lua,
        "Sequence 2 must digest once per player turn while at war with a living major",
    )
    validation.check(
        "sequence == 1 and city ~= nil and type(city.IsOriginalCapital) == \"function\"" in lua
        and "pcall(city.IsOriginalCapital, city)" in lua
        and '"CONQUEROR_ORIGINAL_CAPITAL:"' in lua,
        "Sequence 1 must safely grant an extra point for conquering an original capital",
    )
    validation.check(
        "(player:GetProperty(LOTM_RP_PROPERTIES.TrueGodChurch) or 0) ~= 1" in lifecycle
        and "allowWithoutChurch ~= true" in lifecycle
        and "PROJECT_LOTM_RP_WAR_FESTIVAL_UNCONSECRATED" in lua
        and "project.allowWithoutChurch == true" in lua,
        "Sequence 1->0 must permit only the explicit double-cost ritual to bypass the church discount",
    )


def validate_sync_boundaries(validation: Validation) -> None:
    ui_forbidden = (
        "SetProperty",
        "ChangeDamage",
        "SetDamage",
        "FinishMoves",
        "ChangeMovesRemaining",
        "SetMovesRemaining",
        "SetImprovementPillaged",
        "ImprovementBuilder",
        "TryAddDigestion",
        "AdvanceSequence",
        "ScheduleRespawn",
        "AttachModifierByID",
        "UnitManager.Kill",
        "UnitManager.InitUnit",
    )
    for path in sorted((ROOT / "UI").glob("*.lua")):
        text = strip_trace(path.read_text(encoding="utf-8"))
        relative = path.relative_to(ROOT).as_posix()
        for token in ui_forbidden:
            validation.check(
                token not in text,
                f"{relative} contains forbidden authoritative mutation token: {token}",
            )
        if "UnitManager.RequestCommand" in text:
            validation.check(
                "UnitCommandTypes.EXECUTE_SCRIPT" in text,
                f"{relative} may submit only synchronized EXECUTE_SCRIPT commands",
            )
        validation.check(
            "LuaEvents.LOTM_RP_Command" not in text,
            f"{relative} must not use LuaEvents for authoritative commands",
        )

    gameplay_forbidden = (
        "Game.GetLocalPlayer",
        "Network.GetLocalPlayer",
        "UI.Get",
        "UIManager",
        "UILens",
        "ContextPtr",
        "Controls.",
        "LuaEvents",
        "math.random",
        "TerrainBuilder.GetRandomNumber",
        "os.time",
        "os.clock",
        "Automation.GetTime",
    )
    for path in sorted((ROOT / "Scripts").glob("*.lua")):
        if path.name in {"LOTM_RP_Gameplay_Bundle.lua", "LOTM_MP241_MainBundle.lua"}:
            # Generated bundles duplicate the already-audited source modules.
            # Freshness, provenance and Lua parsing are enforced separately.
            continue
        text = strip_trace(path.read_text(encoding="utf-8"))
        relative = path.relative_to(ROOT).as_posix()
        for token in gameplay_forbidden:
            if path.name == "LOTM_UnitAddedPerf.lua" and token in {"os.clock", "Automation.GetTime"}:
                continue
            validation.check(
                token not in text,
                f"{relative} contains local/nondeterministic Gameplay token: {token}",
            )

        if path.name == "LOTM_UnitAddedPerf.lua":
            validation.check(
                text.count("os.clock") == 1,
                "UnitAdded performance probe must have exactly one fallback local clock source",
            )
            validation.check(
                text.count("Automation.GetTime") == 3,
                "performance probe must guard and use the high-resolution Automation timer",
            )
            for required_probe_token in (
                'm_timerName="Automation.GetTime"',
                "function LOTM_UnitAddedPerf.BeginSection()",
                "function LOTM_UnitAddedPerf.EndSection(name,started,items)",
                "function LOTM_UnitAddedPerf.MarkSection(name,items)",
                "function LOTM_UnitAddedPerf.ReportSections(reason)",
                "timer=%s",
            ):
                validation.check(
                    required_probe_token in text,
                    "high-resolution performance probe lacks " + required_probe_token,
                )
            for forbidden_effect in (
                "SetProperty(", "ChangeAbilityCount(", "AttachModifierByID(",
                "Game.GetRandNum(", "TerrainBuilder.GetRandomNumber", "math.random",
            ):
                validation.check(
                    forbidden_effect not in text,
                    "UnitAdded performance probe must remain diagnostic-only: " + forbidden_effect,
                )

        # CommandProbe sorts its parameter keys before diagnostic output.  No
        # authoritative Gameplay implementation may otherwise depend on Lua's
        # unspecified hash-table iteration order.
        if path.name != "LOTM_RP_CommandProbe.lua":
            validation.check(
                re.search(r"(?<!i)\bpairs\(", text) is None,
                f"{relative} contains unordered pairs() iteration in Gameplay",
            )

    unit_probe = strip_trace((ROOT / "Scripts" / "LOTM_UnitAddedPerf.lua").read_text(encoding="utf-8"))
    root_gameplay = strip_trace((ROOT / "Scripts" / "LOTM_RP_Gameplay.lua").read_text(encoding="utf-8"))
    validation.check('include("LOTM_UnitAddedPerf")' in root_gameplay, "UnitAdded probe must load before Gameplay modules")
    validation.check("LOTM_UnitAddedPerf.Enabled=false" in root_gameplay, "UnitAdded probe must disable itself after the first player turn")
    validation.check("LOTM_UnitAddedPerf.EventCompleted()" in root_gameplay, "UnitAdded probe must count completed event batches")
    probe_modinfo = strip_trace((ROOT / "RedPriestPath.modinfo").read_text(encoding="utf-8"))
    validation.check("<File>Scripts/LOTM_UnitAddedPerf.lua</File>" in probe_modinfo, "UnitAdded probe must be imported")
    for module_name, relative_path in (
        ("Perfect", "Scripts/LOTM_PP_Perfect.lua"),
        ("BlackEmperor", "Scripts/LOTM_BE_BlackEmperor.lua"),
        ("AICults", "Scripts/LOTM_AI_Cults.lua"),
        ("Phase7", "Scripts/LOTM_RESCUE_Phase7.lua"),
        ("Phase9", "Scripts/LOTM_RESCUE_Phase9.lua"),
        ("Phase9Digestion", "Scripts/LOTM_RESCUE_Phase9Digestion.lua"),
        ("Artifacts", "Scripts/LOTM_PP_Artifacts.lua"),
        ("Workshops", "Scripts/LOTM_PP_Workshops.lua"),
        ("Churches", "Scripts/LOTM_WORLD_Churches.lua"),
    ):
        module_text = strip_trace((ROOT / relative_path).read_text(encoding="utf-8"))
        validation.check(
            f'LOTM_UnitAddedPerf.Wrap("{module_name}",' in module_text,
            f"UnitAdded probe missing module wrapper: {module_name}",
        )

    arson = strip_trace((ROOT / "Scripts" / "LOTM_RP_Arson.lua").read_text(encoding="utf-8"))
    validation.check(
        arson.count("GameEvents.LOTM_RP_Command_Arson.Add") == 1,
        "authoritative arson command must have exactly one Gameplay handler",
    )
    validation.check(
        "UnitManager.RequestCommand" not in arson,
        "Gameplay must not recursively submit the arson command",
    )
    validation.check(
        "table.sort(targets" in arson
        and "left:GetOwner() < right:GetOwner()" in arson
        and "left:GetID() < right:GetID()" in arson,
        "arson must kill stacked enemy units in deterministic owner/unit-ID order",
    )
    lifecycle = strip_trace((ROOT / "Scripts" / "LOTM_RP_Lifecycle.lua").read_text(encoding="utf-8"))
    validation.check(
        lifecycle.count("GameEvents.LOTM_RP_Command_SelectPath.Add") == 1,
        "authoritative path-choice command must have exactly one Gameplay handler",
    )
    validation.check(
        lifecycle.count(
            "GameEvents.LOTM_RP_Command_AcknowledgeSequence0Ceremony.Add"
        )
        == 1,
        "Sequence 0 ceremony acknowledgement must have exactly one Gameplay handler",
    )
    progression = strip_trace((ROOT / "Scripts" / "LOTM_RP_Progression.lua").read_text(encoding="utf-8"))
    validation.check(
        progression.count("GameEvents.LOTM_RP_Command_Denounce.Add") == 1,
        "authoritative denounce command must have exactly one Gameplay handler",
    )
    validation.check(
        progression.count("GameEvents.LOTM_RP_Command_ChurchFounded.Add") == 1,
        "authoritative church-founded command must have exactly one Gameplay handler",
    )

    advanced = strip_trace((ROOT / "Scripts" / "LOTM_RP_Advanced.lua").read_text(encoding="utf-8"))
    validation.check(
        "local definition = GameInfo.Projects[projectID]" in advanced
        and "for typeName, project in pairs(LOTM_RP_PROJECTS)" not in advanced,
        "advanced project completion must resolve the synchronized project index directly",
    )

    black_emperor = strip_trace((ROOT / "Scripts" / "LOTM_BE_BlackEmperor.lua").read_text(
        encoding="utf-8"
    ))
    for token in (
        'local LOTM_BE_PATH :string = "PATH_BLACK_EMPEROR"',
        "culture:SetCulturalProgress(civic.Index, culture:GetCultureCost(civic.Index))",
        "culture:SetCivic(civic.Index, true)",
        "P.AutomaticCivicTurn",
        '"LOTM_BE_MOD_MIGHT_BASE_STRENGTH_AURA_V2"',
        '"LOTM_BE_MOD_LEGACY_BASE_STRENGTH_CORRECTION"',
        'LegacyBaseStrengthCorrected = "LOTM_BE_LEGACY_BASE_STRENGTH_CORRECTED"',
        'MightStrengthV2Attached = "LOTM_BE_MIGHT_STRENGTH_V2_ATTACHED"',
        'CivilianBuildersV2Cleaned = "LOTM_BE_CIVILIAN_BUILDERS_V2_CLEANED"',
        'unitInfo.FormationClass == "FORMATION_CLASS_CIVILIAN"',
        "(unitInfo.BuildCharges or 0) > 0",
        "unit:GetBuildCharges() <= 0",
        "UnitManager.Kill(unit, false)",
        "GameEvents.OnCombatOccurred.Add(OnCombatOccurred)",
        "GameEvents.OnPillage.Add(OnPillage)",
        "trade:CountOutgoingRoutes()",
        "influence:CanReceiveInfluence()",
        "GiveFreeTokenToPlayer(destinationPlayerID)",
        "GameEvents.OnDistrictConstructed.Add(OnDistrictConstructed)",
        "GameEvents.BuildingConstructed.Add(OnBuildingConstructed)",
        "greatPeople:GetPastTimeline()",
        "PROJECT_LOTM_BE_BARON_OF_CORRUPTION_POTION",
        "PROJECT_LOTM_BE_CHAOS_MENTOR_POTION",
        "culture:UnlockPolicy(policy.Index)",
        "culture:IsPolicyActive(policy.Index)",
        "Events.ResearchCompleted.Add(OnResearchCompleted)",
        'Events.UnitAddedToMap.Add(LOTM_UnitAddedPerf.Wrap("BlackEmperor",OnUnitAddedToMap))',
        "runtimeCombat >= 10",
        "databaseCombat == 0",
        "(player:GetProperty(P.MightStrengthAttached) or 0) ~= 1",
        'EntropyPressureV2Attached = "LOTM_BE_ENTROPY_PRESSURE_V2_ATTACHED"',
        '"LOTM_BE_MOD_ENTROPY_PRESSURE_V2_BONUS"',
    ):
        validation.check(token in black_emperor, f"Black Emperor Gameplay lacks {token}")
    validation.check(
        "GetActivePolicies" not in black_emperor
        and "GovernmentPolicyChanged" not in black_emperor,
        "Black Emperor Sequence 9 must not scan or score policy cards",
    )
    validation.check(
        black_emperor.count('"CIVIC_COMPLETED:" .. tostring(') == 3
        and black_emperor.count("\n\t\t\t3\n\t\t);") >= 2,
        "automatic Code of Laws and later civic completions must each award 3 digestion",
    )
    validation.check(
        'CivicScoringMigrated = "LOTM_BE_CIVIC_SCORING_V2_MIGRATED"' in black_emperor
        and 'player:SetProperty("LOTM_RP_DIGEST_A", 0)' in black_emperor
        and 'player:SetProperty("LOTM_RP_DIGEST_B", 0)' in black_emperor
        and "table.sort(completed)" in black_emperor,
        "rc.41 Sequence 9 saves must rebuild digestion from completed civics",
    )
    validation.check(
        'if sequence == 9 then' in lifecycle
        and 'return "LOTM_BE_MOD_ALLOW_BARBARIAN_PROJECT"' in lifecycle
        and 'elseif sequence == 7 then' in lifecycle
        and 'return "LOTM_BE_MOD_ALLOW_BARON_OF_CORRUPTION_PROJECT"' in lifecycle
        and 'elseif sequence == 6 then' in lifecycle.split(
            'if path == LOTM_BE_SELECTED_PATH then', 1
        )[1].split('elseif path == LOTM_PP_SELECTED_PATH then', 1)[0],
        "Black Emperor project progression must unlock Sequence 6 to 5",
    )
    black_branch = lifecycle.split('if path == LOTM_BE_SELECTED_PATH then', 1)[1].split(
        'elseif path == LOTM_PP_SELECTED_PATH then', 1
    )[0]
    validation.check(
        'elseif sequence == 2 then' in black_branch
        and 'elseif sequence == 1 then' in black_branch
        and '"PROJECT_LOTM_BE_PRINCE_OF_ABOLITION_POTION", 2, 1' in black_emperor
        and '"PROJECT_LOTM_BE_ENTHRONEMENT", 1, 0' in black_emperor
        and '"PROJECT_LOTM_BE_ENTHRONEMENT_UNCONSECRATED", 1, 0' in black_emperor
        and "allowWithoutChurch = true" in black_emperor,
        "Black Emperor project chain must reach Sequence 0 with both final branches",
    )
    for language in ("en_US", "zh_Hans_CN"):
        black_text_path = ROOT / "Text" / language / "LOTM_RP_GameplayText.xml"
        black_text = strip_trace(black_text_path.read_text(encoding="utf-8"))
        validation.check(
            "LOC_LOTM_RP_DETAILS_RULE" not in black_text,
            f"{language} must remove the universal details rule row",
        )
        validation.check(
            "基础成本60" not in black_text
            and "基础成本100" not in black_text
            and "基础成本140" not in black_text
            and "base cost 60" not in black_text
            and "base cost 100" not in black_text
            and "base cost 140" not in black_text,
            f"{language} Black Emperor HUD must not repeat handwritten base costs",
        )
        localized_rows = {
            row.attrib.get("Tag"): row.findtext("Text") or ""
            for row in ET.parse(black_text_path).getroot().findall(".//Row")
        }
        for current_sequence in range(10):
            detail = localized_rows.get(
                f"LOC_LOTM_BE_DETAILS_EFFECTS_S{current_sequence}", ""
            )
            for inherited_sequence in range(current_sequence, 10):
                marker = (
                    f"（序列{inherited_sequence}）"
                    if language == "zh_Hans_CN"
                    else f"(Sequence {inherited_sequence})"
                )
                validation.check(
                    marker in detail,
                    f"{language} Black Emperor Sequence {current_sequence} details "
                    f"must explicitly list inherited Sequence {inherited_sequence}",
                )
    validation.check(
        "LOTM_RP_State.IsBlackEmperorPlayer(playerID)" in lifecycle
        and "and sequence == 9" in lifecycle
        and "requestedAmount == 1 and not ignoresTurnCap" in lifecycle,
        "only Black Emperor Sequence 9 or explicit Parasite bursts may bypass the per-turn digestion cap",
    )

    black_observer = strip_trace((ROOT / "UI" / "LOTM_BE_EventObserver.lua").read_text(
        encoding="utf-8"
    ))
    for token in (
        "Events.CityMadePurchase.Add",
        "Events.TreasuryChanged.Add",
        "GetPatronizeCost(",
        "GetPastTimeline()",
        "PlayerOperations.EXECUTE_SCRIPT",
    ):
        validation.check(token in black_observer, f"Black Emperor observer lacks {token}")
    validation.check(
        "info ~= nil and info.UnitType ~= nil" in black_observer,
        "Great Person offer scan must reject records without a UnitType table key",
    )
    validation.check(
        black_observer.index("while #m_goldSpendCredits > 0 and m_goldSpendCredits[1].turn < currentTurn")
        < black_observer.index("while #m_goldSpendCredits > 0 and #m_purchaseCandidates > 0"),
        "Black Emperor purchase observer must discard stale queue halves before pairing",
    )
    validation.check(
        "local function CaptureCurrentGoldBalance()" in black_observer
        and black_observer.count("CaptureCurrentGoldBalance();") >= 3,
        "Black Emperor purchase observer must sample the treasury at purchase/publish boundaries",
    )

    black_emperor = strip_trace((ROOT / "Scripts" / "LOTM_BE_BlackEmperor.lua").read_text(
        encoding="utf-8"
    ))
    for token in (
        "Events.TradeRouteActivityChanged.Add(OnTradeRouteActivityChanged)",
        "LOTM_BE_TRADE_ROUTE_ACTIVE_COUNT_274",
        "GetOutgoingTradeRouteCount(player)",
        "GoldenBribePositiveActive(originPlayerID)",
        "LOTM_PP_ArtifactPositiveActive",
        "PlayerManager.GetAliveMinorIDs()",
        "GiveFreeTokenToPlayer(destinationPlayerID)",
        "delta <= 0",
        "reason=NOT_REAL_CITY_STATE",
        "envoy=true",
    ):
        validation.check(token in black_emperor, f"Golden Bribe Gameplay route chain lacks {token}")
    validation.check(
        "Events.TradeRouteActivityChanged.Add" not in black_observer
        and "LOTM_BE_Command_TradeRouteStarted" not in black_observer
        and "GetOutgoingRoutes()" not in black_observer,
        "Golden Bribe route authority must be absent from the local UI observer",
    )
    for token in (
        "LOTM_BE_CITY_INDEX_VERSION",
        "PlayerManager.GetAliveIDs()",
        "LOTM_BE_OBSERVED_CITY_OWNER",
        "CityTransferTypes.BY_CULTURAL_IDENTITY",
        "CityTransferTypes.BY_LOYALTY",
        'ObserveTransferredCity(playerID, city, previousOwner, "event")',
        'QueueNetworkEvent(\n\t\t\t"CITY_TRANSFER"',
        "ApplyNetworkCityTransfer(entry)",
    ):
        validation.check(token in black_emperor, f"loyalty transfer handling lacks {token}")
    validation.check(
        "ScanCityOwnership(true)" not in black_emperor
        and 'ScanCityOwnership(false);' in black_emperor,
        "Black Emperor city ownership must use a one-time migration plus incremental events",
    )

    artifact_sql = strip_trace((ROOT / "Gameplay" / "LOTM_PP_Artifacts.sql").read_text(
        encoding="utf-8"
    ))
    artifact_gameplay = strip_trace((ROOT / "Scripts" / "LOTM_PP_Artifacts.lua").read_text(
        encoding="utf-8"
    ))
    validation.check(
        "LOTM_BE_ART_BRIBE_ZERO_ALL_FOOD" in artifact_sql
        and "LOTM_BE_ART_BRIBE_RESTORE_INTERNATIONAL_FOOD" in artifact_sql
        and "LOTM_BE_ART_BRIBE_LEGACY_FOOD_COMPENSATION_CANCEL_237" in artifact_sql
        and "LOTM_BE_ART_BRIBE_LEGACY_PRODUCTION_COMPENSATION_CANCEL_237" in artifact_sql
        and "LOTM_BE_ART_BRIBE_ZERO_DESTINATION_FOOD_237" in artifact_sql
        and "LOTM_BE_ART_BRIBE_ZERO_DESTINATION_PRODUCTION_237" in artifact_sql
        and "('LOTM_BE_ART_BRIBE_ZERO_DESTINATION_FOOD_237','Destination','1')" in artifact_sql
        and "('LOTM_BE_ART_BRIBE_ZERO_DESTINATION_PRODUCTION_237','Destination','1')" in artifact_sql
        and "EFFECT_ADJUST_PLAYER_INTERNATIONAL_TRADE_ROUTE_YIELD_MODIFIER" in artifact_sql
        and "UPDATE ModifierArguments SET Value='0'" in artifact_sql
        and "('LOTM_BE_ART_BRIBE_DOMESTIC_FOOD','Amount','-100')" not in artifact_sql
        and "('LOTM_BE_ART_BRIBE_DOMESTIC_PRODUCTION','Amount','-100')" not in artifact_sql
        and "LOTM_BE_ART_BRIBE_CANCEL_DISTRICT_" in artifact_sql
        and "MODIFIER_PLAYER_CITIES_ADJUST_TRADE_ROUTE_YIELD_TO_OTHERS" in artifact_sql
        and "YieldChangeAsDomesticDestination" in artifact_sql
        and "'Domestic','true'" in artifact_sql
        and "LOTM_BE_ART_BRIBE_RESTORE_DISTRICT_" in artifact_sql
        and "LOTM_BE_ART_BRIBE_DOMESTIC_FOOD_FIXED_239" in artifact_sql
        and "LOTM_BE_ART_BRIBE_DOMESTIC_PRODUCTION_FIXED_239" in artifact_sql
        and "('LOTM_BE_ART_BRIBE_DOMESTIC_FOOD_FIXED_239','Amount','-3')" in artifact_sql
        and "('LOTM_BE_ART_BRIBE_DOMESTIC_PRODUCTION_FIXED_239','Amount','-3')" in artifact_sql
        and "RESOURCE_LOTM_BE_BRIBE_FIXED_NEG_283" in artifact_sql
        and "LOTM_BE_REQSET_BRIBE_FIXED_NEG_283" in artifact_sql
        and "('LOTM_BE_ART_BRIBE_DOMESTIC_FOOD_FIXED_283','Amount','-3')" in artifact_sql
        and "('LOTM_BE_ART_BRIBE_DOMESTIC_PRODUCTION_FIXED_283','Amount','-3')" in artifact_sql
        and "-999" not in artifact_sql,
        "Golden Bribe must retire the legacy chain and apply the independent fixed -3/-3 lease",
    )
    validation.check(
        "LOTM_PP_ARTIFACT_BRIBE_FIX_237_ATTACHED" in artifact_gameplay
        and "BRIBE_FIX_237_MODIFIERS" in artifact_gameplay,
        "Golden Bribe resource-236 saves must attach the fresh resource-237 correction once",
    )
    validation.check(
        "LOTM_PP_ARTIFACT_BRIBE_FIX_238_ATTACHED" in artifact_gameplay
        and "BRIBE_FIX_238_MODIFIERS" in artifact_gameplay
        and "GameInfo.District_TradeRouteYields" in artifact_gameplay,
        "Golden Bribe resource-237 saves must attach exact resource-238 district cancellations once",
    )
    validation.check(
        "LOTM_PP_ARTIFACT_BRIBE_FIX_239_ATTACHED" in artifact_gameplay
        and "BRIBE_FIX_239_MODIFIERS" in artifact_gameplay
        and "LOTM_BE_ART_BRIBE_RESTORE_DISTRICT_" in artifact_gameplay,
        "Golden Bribe resource-238 saves must attach the resource-239 neutralizer and fixed penalties once",
    )
    validation.check(
        "LOTM_PP_ARTIFACT_BRIBE_FIXED_283_ATTACHED" in artifact_gameplay
        and "BRIBE_FIXED_283_MODIFIERS" in artifact_gameplay
        and 'SetNamedResourceSwitch(p,lease76.."_NEG",false,false,"retired Bribe negative lease81")' in artifact_gameplay
        and "SetNamedResourceSwitch(p,BRIBE_FIXED_NEG_RESOURCE,negative,forceRefresh" in artifact_gameplay,
        "Golden Bribe must keep its legacy negative lease off and use only the synchronized resource-283 gate",
    )
    bribe_texts = "\n".join(
        strip_trace((ROOT / path).read_text(encoding="utf-8"))
        for path in (
            "Text/Selected/LOTM_RP_Selected_zh_Hans_CN.xml",
            "Text/zh_Hans_CN/LOTM_RP_GameplayText.xml",
            "Text/Selected/LOTM_RP_Selected_en_US.xml",
            "Text/en_US/LOTM_RP_GameplayText.xml",
        )
    )
    validation.check(
        "国内路线-3食物、-3生产力" in bribe_texts
        and "domestic routes have -3 Food and -3 Production" in bribe_texts,
        "Golden Bribe Chinese/English descriptions must state fixed -3 Food/-3 Production",
    )

    quick_test = strip_trace((ROOT / "Scripts" / "LOTM_DEV_QuickTest.lua").read_text(
        encoding="utf-8"
    ))
    validation.check(
        "local ENABLED :boolean = false;" in quick_test
        and all(profile in quick_test for profile in (
            "BLACK_EMPEROR_S6_PURCHASE",
            "BLACK_EMPEROR_S2_LOYALTY",
            "GOLDEN_BRIBE",
            "CHURCH_TIER15_RECHECK",
        )),
        "quick-test profiles must exist and remain disabled in production",
    )
    for token in (
        "PrimeBlackEmperorFoundation",
        "LOTM_BE_MOD_RULES_WILDCARD_SLOT",
        "LOTM_BE_FIRST_CITY_REWARD_GRANTED",
        "LOTM_BE_CIVIC_SCORING_V2_MIGRATED",
        "LOTM_BE_RefreshSequenceState",
        "VerifyBlackEmperorState",
        "LOTM_BE_MIGHT_STRENGTH_V2_ATTACHED",
        "LOTM_BE_MIGHT_MOVEMENT_ATTACHED",
        "LOTM_BE_TRADE_GOLD_ATTACHED",
        "LOTM_BE_WEALTH_ATTACHED",
    ):
        validation.check(token in quick_test, f"complete quick-test setup lacks {token}")

    collector = strip_trace((
        ROOT / "Tests" / "collect_multiplayer_evidence.ps1"
    ).read_text(encoding="utf-8"))
    validation.check(
        '"Lua.log"' in collector and '"GameplayScript.log"' not in collector,
        "multiplayer evidence collector must use Civ VI's actual Lua.log",
    )
    validation.check(
        "LOTMGameplayStream" in collector
        and "HostModDirectory" in collector
        and "ClientModDirectory" in collector,
        "multiplayer evidence collector must compare Gameplay streams and installed files",
    )


def validate_database(
    validation: Validation,
    types_root: ET.Element,
    unit_root: ET.Element,
    modifier_root: ET.Element,
    projects_root: ET.Element,
    abilities_root: ET.Element,
) -> None:
    connection = sqlite3.connect(":memory:")
    trace_log: list[str] = []
    connection.set_trace_callback(lambda statement: trace_log.append(statement))
    connection.execute("PRAGMA foreign_keys = ON")
    connection.executescript(
        """
        CREATE TABLE Types(Type TEXT PRIMARY KEY, Kind TEXT NOT NULL);
        CREATE TABLE DynamicModifiers(
            ModifierType TEXT PRIMARY KEY REFERENCES Types(Type),
            CollectionType TEXT NOT NULL,
            EffectType TEXT NOT NULL
        );
        CREATE TABLE Domains(Value TEXT PRIMARY KEY);
        CREATE TABLE FormationClasses(Value TEXT PRIMARY KEY);
        CREATE TABLE PromotionClasses(Value TEXT PRIMARY KEY);
        CREATE TABLE Units(
            UnitType TEXT PRIMARY KEY REFERENCES Types(Type),
            Name TEXT NOT NULL,
            Description TEXT,
            BaseSightRange INTEGER NOT NULL,
            BaseMoves INTEGER NOT NULL,
            Combat INTEGER NOT NULL,
            Domain TEXT NOT NULL REFERENCES Domains(Value),
            FormationClass TEXT NOT NULL REFERENCES FormationClasses(Value),
            Cost INTEGER NOT NULL,
            CanTrain INTEGER NOT NULL CHECK(CanTrain IN (0,1)),
            CanCapture INTEGER NOT NULL DEFAULT 0 CHECK(CanCapture IN (0,1)),
            PromotionClass TEXT REFERENCES PromotionClasses(Value),
            Maintenance INTEGER NOT NULL,
            ZoneOfControl INTEGER NOT NULL DEFAULT 0 CHECK(ZoneOfControl IN (0,1)),
            AdvisorType TEXT,
            CanEarnExperience INTEGER NOT NULL DEFAULT 0 CHECK(CanEarnExperience IN (0,1))
        );
        CREATE TABLE Units_XP2(
            UnitType TEXT PRIMARY KEY REFERENCES Units(UnitType),
            CanEarnExperience INTEGER NOT NULL DEFAULT 0 CHECK(CanEarnExperience IN (0,1)),
            CanFormMilitaryFormation INTEGER NOT NULL CHECK(CanFormMilitaryFormation IN (0,1)),
            MajorCivOnly INTEGER NOT NULL CHECK(MajorCivOnly IN (0,1))
        );
        CREATE TABLE Projects(
            ProjectType TEXT PRIMARY KEY REFERENCES Types(Type),
            Name TEXT NOT NULL,
            ShortName TEXT NOT NULL,
            Description TEXT,
            PrereqTech TEXT,
            Cost INTEGER NOT NULL,
            CostProgressionModel TEXT NOT NULL DEFAULT 'NO_PROGRESSION_MODEL',
            CostProgressionParam1 INTEGER NOT NULL DEFAULT 0,
            MaxPlayerInstances INTEGER,
            AdvisorType TEXT,
            UnlocksFromEffect INTEGER NOT NULL CHECK(UnlocksFromEffect IN (0,1))
        );
        CREATE TABLE Project_YieldConversions(
            ProjectType TEXT NOT NULL REFERENCES Projects(ProjectType),
            YieldType TEXT NOT NULL,
            PercentOfProductionRate INTEGER NOT NULL,
            PRIMARY KEY(ProjectType, YieldType)
        );
        CREATE TABLE Policies(
            PolicyType TEXT PRIMARY KEY REFERENCES Types(Type),
            Name TEXT NOT NULL,
            Description TEXT,
            GovernmentSlotType TEXT NOT NULL,
            ExplicitUnlock INTEGER NOT NULL CHECK(ExplicitUnlock IN (0,1))
        );
        CREATE TABLE UnitAbilities(
            UnitAbilityType TEXT PRIMARY KEY REFERENCES Types(Type),
            Name TEXT,
            Description TEXT,
            Inactive INTEGER NOT NULL CHECK(Inactive IN (0,1)),
            Permanent INTEGER NOT NULL DEFAULT 0 CHECK(Permanent IN (0,1))
        );
        CREATE TABLE TypeTags(
            Type TEXT NOT NULL REFERENCES Types(Type),
            Tag TEXT NOT NULL,
            PRIMARY KEY(Type, Tag)
        );
        CREATE TABLE Modifiers(
            ModifierId TEXT PRIMARY KEY,
            ModifierType TEXT NOT NULL,
            OwnerRequirementSetId TEXT,
            SubjectRequirementSetId TEXT,
            SubjectStackLimit INTEGER,
            RunOnce INTEGER NOT NULL DEFAULT 0 CHECK(RunOnce IN (0,1)),
            Permanent INTEGER NOT NULL CHECK(Permanent IN (0,1))
        );
        CREATE TABLE ModifierArguments(
            ModifierId TEXT NOT NULL REFERENCES Modifiers(ModifierId),
            Name TEXT NOT NULL,
            Value TEXT NOT NULL,
            Extra TEXT,
            PRIMARY KEY(ModifierId, Name)
        );
        CREATE TABLE PolicyModifiers(
            PolicyType TEXT NOT NULL REFERENCES Policies(PolicyType),
            ModifierId TEXT NOT NULL REFERENCES Modifiers(ModifierId),
            PRIMARY KEY(PolicyType, ModifierId)
        );
        CREATE TABLE ModifierStrings(
            ModifierId TEXT NOT NULL REFERENCES Modifiers(ModifierId),
            Context TEXT NOT NULL,
            Text TEXT NOT NULL,
            PRIMARY KEY(ModifierId, Context)
        );
        CREATE TABLE RequirementSets(
            RequirementSetId TEXT PRIMARY KEY,
            RequirementSetType TEXT NOT NULL
        );
        CREATE TABLE Requirements(
            RequirementId TEXT PRIMARY KEY,
            RequirementType TEXT NOT NULL,
            Inverse INTEGER NOT NULL DEFAULT 0 CHECK(Inverse IN (0,1))
        );
        CREATE TABLE RequirementSetRequirements(
            RequirementSetId TEXT NOT NULL REFERENCES RequirementSets(RequirementSetId),
            RequirementId TEXT NOT NULL REFERENCES Requirements(RequirementId),
            PRIMARY KEY(RequirementSetId, RequirementId)
        );
        CREATE TABLE RequirementArguments(
            RequirementId TEXT NOT NULL REFERENCES Requirements(RequirementId),
            Name TEXT NOT NULL,
            Value TEXT NOT NULL,
            PRIMARY KEY(RequirementId, Name)
        );
        CREATE TABLE UnitAbilityModifiers(
            UnitAbilityType TEXT NOT NULL REFERENCES UnitAbilities(UnitAbilityType),
            ModifierId TEXT NOT NULL REFERENCES Modifiers(ModifierId),
            PRIMARY KEY(UnitAbilityType, ModifierId)
        );
        CREATE TABLE GreatWorks(
            GreatWorkType TEXT PRIMARY KEY,
            GreatWorkObjectType TEXT NOT NULL
        );
        CREATE TABLE GreatWork_YieldChanges(
            GreatWorkType TEXT NOT NULL REFERENCES GreatWorks(GreatWorkType),
            YieldType TEXT NOT NULL,
            YieldChange INTEGER NOT NULL
        );
        CREATE TABLE Districts(
            DistrictType TEXT PRIMARY KEY,
            RequiresPopulation INTEGER NOT NULL CHECK(RequiresPopulation IN (0,1))
        );
        CREATE TABLE Yields(YieldType TEXT PRIMARY KEY);
        CREATE TABLE Resources(
            ResourceType TEXT PRIMARY KEY,
            Name TEXT,
            ResourceClassType TEXT,
            Frequency INTEGER,
            LakeEligible INTEGER
        );
        CREATE TABLE Resource_Consumption(
            ResourceType TEXT PRIMARY KEY REFERENCES Resources(ResourceType),
            Accumulate INTEGER NOT NULL DEFAULT 0,
            BaseExtractionRate INTEGER NOT NULL DEFAULT 0,
            ImprovedExtractionRate INTEGER NOT NULL DEFAULT 0,
            StockpileCap INTEGER NOT NULL DEFAULT 0
        );
        INSERT INTO Domains VALUES('DOMAIN_LAND');
        INSERT INTO FormationClasses VALUES('FORMATION_CLASS_LAND_COMBAT');
        INSERT INTO PromotionClasses VALUES('PROMOTION_CLASS_RECON');
        INSERT INTO PromotionClasses VALUES('PROMOTION_CLASS_LOTM_RP_PATH_HOLDER');
        INSERT INTO GreatWorks VALUES('GREATWORK_TEST_WRITING', 'GREATWORKOBJECT_WRITING');
        INSERT INTO GreatWork_YieldChanges VALUES('GREATWORK_TEST_WRITING', 'YIELD_CULTURE', 4);
        INSERT INTO Districts VALUES('DISTRICT_TEST_SPECIALTY', 1);
        INSERT INTO Districts VALUES('DISTRICT_TEST_CITY_CENTER', 0);
        INSERT INTO Yields VALUES('YIELD_FOOD');
        INSERT INTO Yields VALUES('YIELD_PRODUCTION');
        INSERT INTO Yields VALUES('YIELD_GOLD');
        INSERT INTO Yields VALUES('YIELD_SCIENCE');
        INSERT INTO Yields VALUES('YIELD_CULTURE');
        INSERT INTO Yields VALUES('YIELD_FAITH');
        """
    )

    def boolean(value: str) -> int:
        return 1 if value.lower() in {"1", "true"} else 0

    def field(row: ET.Element, name: str) -> str | None:
        return row.attrib.get(name) or row.findtext(name)

    try:
        for row in types_root.findall("./Types/Row"):
            connection.execute(
                "INSERT INTO Types(Type, Kind) VALUES(?, ?)",
                (row.attrib["Type"], row.attrib["Kind"]),
            )
        connection.executescript(
            strip_trace((ROOT / "Gameplay" / "LOTM_RP_ProjectSupport.sql").read_text(encoding="utf-8"))
        )
        unit = unit_root.find(f"./Units/Row[@UnitType='{UNIT_TYPE}']")
        if unit is None:
            raise ValueError("unit row absent")
        attrs = unit.attrib
        connection.execute(
            """
            INSERT INTO Units(
                UnitType, Name, BaseSightRange, BaseMoves, Combat, Domain,
                FormationClass, Cost, CanTrain, PromotionClass, Maintenance
            ) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                attrs["UnitType"],
                attrs["Name"],
                int(attrs["BaseSightRange"]),
                int(attrs["BaseMoves"]),
                int(attrs["Combat"]),
                attrs["Domain"],
                attrs["FormationClass"],
                int(attrs["Cost"]),
                boolean(attrs["CanTrain"]),
                attrs["PromotionClass"],
                int(attrs["Maintenance"]),
            ),
        )
        xp2 = unit_root.find(f"./Units_XP2/Row[@UnitType='{UNIT_TYPE}']")
        if xp2 is None:
            raise ValueError("Units_XP2 row absent")
        connection.execute(
            "INSERT INTO Units_XP2 VALUES(?, ?, ?, ?)",
            (
                xp2.attrib["UnitType"],
                boolean(xp2.attrib.get("CanEarnExperience", "false")),
                boolean(xp2.attrib["CanFormMilitaryFormation"]),
                boolean(xp2.attrib["MajorCivOnly"]),
            ),
        )

        for row in projects_root.findall("./Projects/Row"):
            connection.execute(
                """
                INSERT INTO Projects(
                    ProjectType, Name, ShortName, Description, PrereqTech,
                    Cost, MaxPlayerInstances, AdvisorType, UnlocksFromEffect
                ) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    row.attrib["ProjectType"],
                    row.attrib["Name"],
                    row.attrib["ShortName"],
                    row.attrib.get("Description"),
                    row.attrib.get("PrereqTech"),
                    int(row.attrib["Cost"]),
                    int(row.attrib["MaxPlayerInstances"])
                    if row.attrib.get("MaxPlayerInstances") is not None else None,
                    row.attrib.get("AdvisorType"),
                    boolean(row.attrib["UnlocksFromEffect"]),
                ),
            )
        for row in abilities_root.findall("./UnitAbilities/Row"):
            connection.execute(
                "INSERT INTO UnitAbilities VALUES(?, ?, ?, ?, ?)",
                (
                    row.attrib["UnitAbilityType"],
                    row.attrib.get("Name"),
                    row.attrib.get("Description"),
                    boolean(row.attrib.get("Inactive", "false")),
                    boolean(row.attrib.get("Permanent", "false")),
                ),
            )
        for root in (unit_root, abilities_root):
            for row in root.findall("./TypeTags/Row"):
                connection.execute(
                    "INSERT INTO TypeTags VALUES(?, ?)",
                    (row.attrib["Type"], row.attrib["Tag"]),
                )

        data_roots = (modifier_root, abilities_root)
        for root in data_roots:
            for row in root.findall("./RequirementSets/Row"):
                connection.execute(
                    "INSERT INTO RequirementSets VALUES(?, ?)",
                    (field(row, "RequirementSetId"), field(row, "RequirementSetType")),
                )
            for row in root.findall("./Requirements/Row"):
                connection.execute(
                    "INSERT INTO Requirements VALUES(?, ?, ?)",
                    (
                        field(row, "RequirementId"),
                        field(row, "RequirementType"),
                        boolean(field(row, "Inverse") or "false"),
                    ),
                )
        for root in data_roots:
            for row in root.findall("./Modifiers/Row"):
                connection.execute(
                    """INSERT INTO Modifiers(
                        ModifierId,ModifierType,SubjectRequirementSetId,
                        SubjectStackLimit,RunOnce,Permanent
                    ) VALUES(?, ?, ?, ?, ?, ?)""",
                    (
                        field(row, "ModifierId"),
                        field(row, "ModifierType"),
                        field(row, "SubjectRequirementSetId"),
                        int(field(row, "SubjectStackLimit"))
                        if field(row, "SubjectStackLimit")
                        else None,
                        boolean(field(row, "RunOnce") or "false"),
                        boolean(field(row, "Permanent") or "false"),
                    ),
                )
            for row in root.findall("./ModifierArguments/Row"):
                connection.execute(
                    "INSERT INTO ModifierArguments VALUES(?, ?, ?, ?)",
                    (
                        field(row, "ModifierId"),
                        field(row, "Name"),
                        field(row, "Value"),
                        field(row, "Extra"),
                    ),
                )
            for row in root.findall("./RequirementSetRequirements/Row"):
                connection.execute(
                    "INSERT INTO RequirementSetRequirements VALUES(?, ?)",
                    (field(row, "RequirementSetId"), field(row, "RequirementId")),
                )
            for row in root.findall("./RequirementArguments/Row"):
                connection.execute(
                    "INSERT INTO RequirementArguments VALUES(?, ?, ?)",
                    (
                        field(row, "RequirementId"),
                        field(row, "Name"),
                        field(row, "Value"),
                    ),
                )
        for row in abilities_root.findall("./UnitAbilityModifiers/Row"):
            connection.execute(
                "INSERT INTO UnitAbilityModifiers VALUES(?, ?)",
                (field(row, "UnitAbilityType"), field(row, "ModifierId")),
            )
        connection.executescript(
            strip_trace((ROOT / "Gameplay" / "LOTM_PP_Perfect.sql").read_text(encoding="utf-8"))
        )
        perfect_modifier_count = connection.execute(
            "SELECT COUNT(*) FROM Modifiers WHERE ModifierId LIKE 'LOTM_PP_MOD_%'"
        ).fetchone()[0]
        validation.check(
            perfect_modifier_count >= 20,
            "Perfect Path SQL did not create the expected Firaxis-shell modifiers",
        )
        alchemist_rows = connection.execute(
            """
            SELECT m.ModifierId, m.SubjectRequirementSetId, a.Value
            FROM Modifiers m
            JOIN ModifierArguments a ON a.ModifierId = m.ModifierId
            WHERE m.ModifierId IN (
                'LOTM_PP_MOD_ALCHEMIST_BUILDER_CHARGES',
                'LOTM_PP_MOD_ALCHEMIST_BUILDER_CHARGES_V2',
                'LOTM_PP_MOD_ALCHEMIST_BUILDER_CHARGES_LEGACY_COMPENSATION'
            ) AND a.Name = 'Amount'
            ORDER BY m.ModifierId
            """
        ).fetchall()
        validation.check(
            alchemist_rows
            == [
                ('LOTM_PP_MOD_ALCHEMIST_BUILDER_CHARGES', 'UNIT_IS_BUILDER', '0'),
                (
                    'LOTM_PP_MOD_ALCHEMIST_BUILDER_CHARGES_LEGACY_COMPENSATION',
                    None,
                    '-3',
                ),
                ('LOTM_PP_MOD_ALCHEMIST_BUILDER_CHARGES_V2', 'UNIT_IS_BUILDER', '3'),
            ],
            "Alchemist charges must use builder-only V2 plus an exact legacy inverse",
        )
        relic_v3_rows = connection.execute(
            """
            SELECT ModifierId, RunOnce, Permanent
            FROM Modifiers
            WHERE ModifierId LIKE 'LOTM_PP_MOD_GRANT_RELIC_V3_%'
            ORDER BY ModifierId
            """
        ).fetchall()
        validation.check(
            len(relic_v3_rows) == 5
            and all(run_once == 1 and permanent == 1 for _, run_once, permanent in relic_v3_rows),
            "Perfect Path relic V3 grants must be five RunOnce+Permanent modifiers",
        )
        relic_v3_arguments = connection.execute(
            """
            SELECT ModifierId, Name, Value
            FROM ModifierArguments
            WHERE ModifierId LIKE 'LOTM_PP_MOD_GRANT_RELIC_V3_%'
            """
        ).fetchall()
        relic_v3_argument_map = {
            (modifier_id, name): value
            for modifier_id, name, value in relic_v3_arguments
        }
        validation.check(
            all(
                relic_v3_argument_map.get(
                    (f"LOTM_PP_MOD_GRANT_RELIC_V3_{grant_index}", "Amount")
                ) == "1"
                and relic_v3_argument_map.get(
                    (f"LOTM_PP_MOD_GRANT_RELIC_V3_{grant_index}", "RelicSource")
                ) == "RELIC_SOURCE_TRIBAL_VILLAGE"
                for grant_index in range(1, 6)
            ),
            "every Perfect Path relic V3 grant must include Amount=1 and the archaeological relic source",
        )
        connection.executescript(
            """
            CREATE TABLE LOTM_ArtifactTurnLeases76(
                ArtifactType TEXT PRIMARY KEY NOT NULL,
                LeaseResourceType TEXT NOT NULL UNIQUE,
                LeaseRequirementId TEXT NOT NULL UNIQUE,
                LeaseRequirementSetId TEXT NOT NULL UNIQUE,
                LegacyRequirementSetId TEXT NOT NULL UNIQUE
            );
            INSERT INTO Modifiers(
                ModifierId,ModifierType,OwnerRequirementSetId,RunOnce,Permanent
            ) VALUES(
                'LOTM_PP_FX_GEAR_FOOD','MODIFIER_PLAYER_ADJUST_YIELD_CHANGE',
                'LOTM_TEST_LEGACY_REQSET_01',0,0
            );
            INSERT INTO ModifierArguments(ModifierId,Name,Value)
            VALUES('LOTM_PP_FX_GEAR_FOOD','Amount','-1');
            """
        )
        connection.executemany(
            "INSERT INTO LOTM_ArtifactTurnLeases76 VALUES(?,?,?,?,?)",
            [
                (
                    f"GREATWORK_LOTM_TEST_{index:02d}",
                    f"RESOURCE_LOTM_ARTIFACT_LEASE76_{index:02d}",
                    f"LOTM_REQ_ARTIFACT_LEASE76_{index:02d}",
                    f"LOTM_REQSET_ARTIFACT_LEASE76_{index:02d}",
                    f"LOTM_TEST_LEGACY_REQSET_{index:02d}",
                )
                for index in range(1, 22)
            ],
        )
        connection.executescript(
            strip_trace((ROOT / "Gameplay" / "LOTM_WORLD_Events.sql").read_text(encoding="utf-8"))
        )
        connection.executescript(
            strip_trace((ROOT / "Gameplay" / "LOTM_BE_BlackEmperor.sql").read_text(encoding="utf-8"))
        )
        connection.executescript(
            strip_trace((ROOT / "Gameplay" / "LOTM_TP_Thief.sql").read_text(encoding="utf-8"))
        )
        thief_projects = connection.execute(
            "SELECT Cost FROM Projects WHERE ProjectType LIKE 'PROJECT_LOTM_TP_%POTION' ORDER BY Cost"
        ).fetchall()
        validation.check(
            thief_projects == [(60,), (100,), (140,), (180,), (220,), (260,), (300,), (340,)],
            f"Thief potion costs mismatch: {thief_projects}",
        )
        thief_resource = connection.execute(
            "SELECT ResourceClassType, Frequency FROM Resources WHERE ResourceType='RESOURCE_LOTM_TP_FAKE_GOLD'"
        ).fetchone()
        validation.check(
            thief_resource == ("RESOURCECLASS_STRATEGIC", 0),
            f"Counterfeit Gold must be a non-map strategic resource: {thief_resource}",
        )
        black_projects = connection.execute(
            """
            SELECT ProjectType, Cost, MaxPlayerInstances, UnlocksFromEffect
            FROM Projects
            WHERE ProjectType LIKE 'PROJECT_LOTM_BE_%'
            ORDER BY Cost
            """
        ).fetchall()
        validation.check(
            black_projects
            == [
                (BE_TRANSFORMATION_PROJECT, 25, None, 1),
                (BE_BARBARIAN_PROJECT, 60, 1, 1),
                (BE_BRIBER_PROJECT, 100, 1, 1),
                (BE_BARON_PROJECT, 140, 1, 1),
                (BE_CHAOS_MENTOR_PROJECT, 180, 1, 1),
                (BE_COUNT_PROJECT, 220, 1, 1),
                (BE_FRENZY_PROJECT, 260, 1, 1),
                (BE_ENTROPY_PROJECT, 300, 1, 1),
                (BE_PRINCE_PROJECT, 340, 1, 1),
                (BE_ENTHRONEMENT_PROJECT, 380, 1, 1),
                (BE_UNCONSECRATED_ENTHRONEMENT_PROJECT, 760, 1, 1),
            ],
            "Black Emperor must define the complete Sequence 9-0 project set",
        )
        transformation = connection.execute(
            """
            SELECT Cost, CostProgressionModel, CostProgressionParam1,
                   MaxPlayerInstances
            FROM Projects WHERE ProjectType = ?
            """,
            (BE_TRANSFORMATION_PROJECT,),
        ).fetchone()
        conversions = dict(
            connection.execute(
                """
                SELECT YieldType, PercentOfProductionRate
                FROM Project_YieldConversions WHERE ProjectType = ?
                """,
                (BE_TRANSFORMATION_PROJECT,),
            ).fetchall()
        )
        validation.check(
            transformation == (25, "COST_PROGRESSION_GAME_PROGRESS", 1500, None)
            and conversions
            == {"YIELD_SCIENCE": 100, "YIELD_CULTURE": 100, "YIELD_GOLD": 200},
            "Transformation must be repeatable and convert production to Science/Culture/Gold at 100/100/200 percent",
        )
        chaos_policy = connection.execute(
            """
            SELECT GovernmentSlotType, ExplicitUnlock
            FROM Policies
            WHERE PolicyType = ?
            """,
            (BE_CHAOS_I_POLICY,),
        ).fetchone()
        chaos_modifiers = dict(
            connection.execute(
                """
                SELECT pm.ModifierId, ma.Value
                FROM PolicyModifiers pm
                JOIN ModifierArguments ma ON ma.ModifierId = pm.ModifierId
                WHERE pm.PolicyType = ? AND ma.Name = 'Amount'
                """,
                (BE_CHAOS_I_POLICY,),
            ).fetchall()
        )
        validation.check(
            chaos_policy == ("SLOT_ECONOMIC", 1)
            and chaos_modifiers
            == {
                "LOTM_BE_MOD_CHAOS_I_GOLD": "-100",
                "LOTM_BE_MOD_CHAOS_I_SCIENCE": "100",
            },
            "Chaos I must be an explicitly unlocked Economic policy with Gold -100 and Science +100",
        )
        expected_policy_amounts = {
            "POLICY_LOTM_BE_CHAOS_II": {"-500", "500"},
            "POLICY_LOTM_BE_CHAOS_III": {"-1000", "1000"},
            "POLICY_LOTM_BE_CORRUPTION_I": {"-100", "10"},
            "POLICY_LOTM_BE_CORRUPTION_II": {"-500", "50"},
            "POLICY_LOTM_BE_CORRUPTION_III": {"-1000", "100"},
        }
        for policy_type, expected_amounts in expected_policy_amounts.items():
            actual_amounts = {
                row[0]
                for row in connection.execute(
                    """
                    SELECT ma.Value FROM PolicyModifiers pm
                    JOIN ModifierArguments ma ON ma.ModifierId = pm.ModifierId
                    WHERE pm.PolicyType = ? AND ma.Name = 'Amount'
                    """,
                    (policy_type,),
                ).fetchall()
            }
            validation.check(
                actual_amounts == expected_amounts,
                f"{policy_type} values mismatch: {actual_amounts}",
            )
        count_prereq = connection.execute(
            "SELECT PrereqTech FROM Projects WHERE ProjectType = ?",
            (BE_COUNT_PROJECT,),
        ).fetchone()
        validation.check(
            count_prereq == ("TECH_INDUSTRIALIZATION",),
            "Sequence 5 to 4 project must require Industrialization",
        )
        black_arguments = dict(
            connection.execute(
                """
                SELECT ModifierId || ':' || Name, Value
                FROM ModifierArguments
                WHERE ModifierId LIKE 'LOTM_BE_MOD_%'
                """
            ).fetchall()
        )
        black_modifier_types = dict(
            connection.execute(
                """
                SELECT ModifierId, ModifierType
                FROM Modifiers
                WHERE ModifierId LIKE 'LOTM_BE_MOD_%'
                """
            ).fetchall()
        )
        validation.check(
            black_arguments.get("LOTM_BE_MOD_MIGHT_BASE_STRENGTH:Amount") == "0"
            and black_arguments.get(
                "LOTM_BE_MOD_LEGACY_BASE_STRENGTH_CORRECTION:Amount"
            )
            == "-10"
            and black_arguments.get(
                "LOTM_BE_MOD_MIGHT_BASE_STRENGTH_AURA_V2:ModifierId"
            )
            == "LOTM_BE_MOD_MIGHT_BASE_STRENGTH_EFFECT_V2"
            and black_arguments.get(
                "LOTM_BE_MOD_MIGHT_BASE_STRENGTH_EFFECT_V2:Amount"
            )
            == "10"
            and black_arguments.get("LOTM_BE_MOD_MIGHT_MOVEMENT:Amount") == "1"
            and black_arguments.get("LOTM_BE_MOD_BRIBERY_TRADE_GOLD:Amount") == "10"
            and black_arguments.get("LOTM_BE_MOD_CORRUPT_WEALTH_GOLD:Amount") == "100",
            "Black Emperor inherited modifiers must define the exact legacy -10 correction and use V2 +10 strength, +1 movement, +10 route Gold, and +100% city Gold",
        )
        might_parent_requirement = connection.execute(
            """
            SELECT SubjectRequirementSetId
            FROM Modifiers m
            WHERE m.ModifierId = 'LOTM_BE_MOD_MIGHT_BASE_STRENGTH_AURA_V2'
            """
        ).fetchone()
        might_preview = connection.execute(
            """
            SELECT Context, Text
            FROM ModifierStrings
            WHERE ModifierId = 'LOTM_BE_MOD_MIGHT_BASE_STRENGTH_EFFECT_V2'
            """
        ).fetchone()
        wealth_type = connection.execute(
            """
            SELECT ModifierType
            FROM Modifiers
            WHERE ModifierId = 'LOTM_BE_MOD_CORRUPT_WEALTH_GOLD'
            """
        ).fetchone()
        validation.check(
            black_modifier_types.get("LOTM_BE_MOD_MIGHT_BASE_STRENGTH_AURA_V2")
            == "MODIFIER_PLAYER_UNITS_ATTACH_MODIFIER"
            and black_modifier_types.get(
                "LOTM_BE_MOD_LEGACY_BASE_STRENGTH_CORRECTION"
            )
            == "MODIFIER_LOTM_RP_PLAYER_UNITS_ADJUST_BASE_COMBAT_STRENGTH"
            and black_modifier_types.get("LOTM_BE_MOD_MIGHT_BASE_STRENGTH_EFFECT_V2")
            == "MODIFIER_UNIT_ADJUST_COMBAT_STRENGTH"
            and might_parent_requirement == (None,)
            and might_preview
            == ("Preview", "LOC_LOTM_BE_PREVIEW_MIGHT_STRENGTH"),
            "Black Emperor Might must match Red Priest's ordinary combat-modifier chain and never change base strength",
        )
        validation.check(
            wealth_type == ("MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_MODIFIER",),
            "Corrupt Wealth must modify the recurring Gold yield of all owned cities",
        )
        policy_rows = dict(
            connection.execute(
                """
                SELECT PolicyType, GovernmentSlotType || ':' || ExplicitUnlock
                FROM Policies WHERE PolicyType LIKE 'POLICY_LOTM_BE_%'
                """
            ).fetchall()
        )
        validation.check(
            policy_rows
            == {
                "POLICY_LOTM_BE_CHAOS_I": "SLOT_ECONOMIC:1",
                "POLICY_LOTM_BE_CHAOS_II": "SLOT_ECONOMIC:1",
                "POLICY_LOTM_BE_CHAOS_III": "SLOT_ECONOMIC:1",
                "POLICY_LOTM_BE_CORRUPTION_I": "SLOT_ECONOMIC:1",
                "POLICY_LOTM_BE_CORRUPTION_II": "SLOT_ECONOMIC:1",
                "POLICY_LOTM_BE_CORRUPTION_III": "SLOT_ECONOMIC:1",
                "POLICY_LOTM_BE_FRENZY_I": "SLOT_MILITARY:1",
                "POLICY_LOTM_BE_FRENZY_II": "SLOT_MILITARY:1",
            },
            "Black Emperor policies must use the intended slots and ExplicitUnlock=1",
        )
        validation.check(
            black_modifier_types.get("LOTM_BE_MOD_CORRUPTION_I_AMENITY")
            == "MODIFIER_PLAYER_CITIES_ADJUST_POLICY_AMENITY"
            and black_modifier_types.get("LOTM_BE_MOD_CORRUPTION_II_AMENITY")
            == "MODIFIER_PLAYER_CITIES_ADJUST_POLICY_AMENITY"
            and black_modifier_types.get("LOTM_BE_MOD_CORRUPTION_III_AMENITY")
            == "MODIFIER_PLAYER_CITIES_ADJUST_POLICY_AMENITY"
            and black_modifier_types.get("LOTM_BE_MOD_CORRUPT_PROSPERITY_FOOD")
            == "MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_MODIFIER"
            and black_arguments.get("LOTM_BE_MOD_CORRUPT_PROSPERITY_FOOD:Amount")
            == "100"
            and black_arguments.get("LOTM_BE_MOD_CORRUPT_PROSPERITY_FOOD:YieldType")
            == "YIELD_FOOD",
            "Corruption amenities and Sequence 4 city Food modifier are misconfigured",
        )
        frenzy_aura_rows = connection.execute(
            """
            SELECT ModifierId, SubjectRequirementSetId
            FROM Modifiers
            WHERE ModifierId GLOB 'LOTM_BE_MOD_FRENZY_I_[A-Z]*_AURA'
            ORDER BY ModifierId
            """
        ).fetchall()
        validation.check(
            len(frenzy_aura_rows) == 6
            and all(
                requirement == "LOTM_RP_REQSET_MAJOR_AT_WAR_WITH_OWNER"
                for _, requirement in frenzy_aura_rows
            )
            and all(
                black_modifier_types.get(modifier_id)
                == "MODIFIER_LOTM_RP_MAJOR_OPPOSING_PLAYERS_ATTACH_MODIFIER"
                for modifier_id, _ in frenzy_aura_rows
            )
            and all(
                black_arguments.get(
                    modifier_id.replace("_AURA", "") + ":Amount"
                )
                == "-30"
                for modifier_id, _ in frenzy_aura_rows
            ),
            "Frenzy I must attach six -30% city-yield modifiers only to major war opponents",
        )
        frenzy_ii_aura_rows = connection.execute(
            """
            SELECT ModifierId, SubjectRequirementSetId
            FROM Modifiers
            WHERE ModifierId GLOB 'LOTM_BE_MOD_FRENZY_II_[A-Z]*_AURA'
            ORDER BY ModifierId
            """
        ).fetchall()
        validation.check(
            len(frenzy_ii_aura_rows) == 6
            and all(
                requirement == "LOTM_RP_REQSET_MAJOR_AT_WAR_WITH_OWNER"
                for _, requirement in frenzy_ii_aura_rows
            )
            and all(
                black_arguments.get(modifier_id.replace("_AURA", "") + ":Amount")
                == "-50"
                for modifier_id, _ in frenzy_ii_aura_rows
            ),
            "Frenzy II must attach six -50% city-yield modifiers only to major war opponents",
        )
        tomb_slots = [
            value
            for key, value in black_arguments.items()
            if key.startswith("LOTM_BE_MOD_TOMB_")
            and key.endswith(":GovernmentSlotType")
        ]
        validation.check(
            Counter(tomb_slots)
            == Counter({"SLOT_MILITARY": 3, "SLOT_ECONOMIC": 3, "SLOT_WILDCARD": 3}),
            "Sequence 0 must attach exactly three Military, three Economic, and three Wildcard slots",
        )
        validation.check(
            black_modifier_types.get("LOTM_BE_MOD_ENTROPY_PRESSURE")
            == "MODIFIER_PLAYER_CITIES_ADJUST_IDENTITY_PER_CITIZEN"
            and black_arguments.get("LOTM_BE_MOD_ENTROPY_PRESSURE:Amount") == "2"
            and black_modifier_types.get("LOTM_BE_MOD_ENTROPY_PRESSURE_V2_BONUS")
            == "MODIFIER_PLAYER_CITIES_ADJUST_IDENTITY_PER_CITIZEN"
            and black_arguments.get("LOTM_BE_MOD_ENTROPY_PRESSURE_V2_BONUS:Amount")
            == "2"
            and black_modifier_types.get("LOTM_BE_MOD_ENTROPY_LOYALTY")
            == "MODIFIER_PLAYER_CITIES_ADJUST_IDENTITY_PER_TURN"
            and black_arguments.get("LOTM_BE_MOD_ENTROPY_LOYALTY:Amount") == "99",
            "Sequence 2 must combine legacy +2 and V2 +2 identity per citizen with +99 city loyalty per turn",
        )
        black_lua = strip_trace((ROOT / "Scripts" / "LOTM_BE_BlackEmperor.lua").read_text(
            encoding="utf-8"
        ))
        validation.check(
            "UnlockPolicyOnce(playerID, LOTM_BE_CHAOS_III" in black_lua
            and "UnlockPolicyOnce(playerID, LOTM_BE_CORRUPTION_III" in black_lua
            and "UnlockPolicyOnce(playerID, LOTM_BE_FRENZY_II" in black_lua,
            "Sequence 1 must unlock Chaos III, Corruption III, and Frenzy II",
        )
        lease81_count = connection.execute(
            "SELECT COUNT(*) FROM LOTM_ArtifactTurnLeases81"
        ).fetchone()[0]
        polarity_count = connection.execute(
            "SELECT COUNT(*) FROM LOTM_ArtifactModifierPolarity81"
        ).fetchone()[0]
        polarity_clone_count = connection.execute(
            "SELECT COUNT(*) FROM Modifiers WHERE ModifierId LIKE '%_LEASE81_POS' OR ModifierId LIKE '%_LEASE81_NEG'"
        ).fetchone()[0]
        validation.check(
            lease81_count == 21,
            f"rc.81 must define two live lease resources for all 21 artifacts, found {lease81_count}",
        )
        validation.check(
            polarity_count > 0 and polarity_clone_count == polarity_count,
            f"every classified artifact modifier must have exactly one polarity clone: classifications={polarity_count}, clones={polarity_clone_count}",
        )
        foreign_key_errors = connection.execute("PRAGMA foreign_key_check").fetchall()
        validation.check(not foreign_key_errors, f"static database foreign-key errors: {foreign_key_errors}")
    except (KeyError, ValueError, sqlite3.Error) as exc:
        last_statement = trace_log[-1] if trace_log else "<no statement>"
        validation.check(False, f"static database load failed: {exc}; last SQL: {last_statement}")
    finally:
        connection.close()


def validate_game_references(validation: Validation, game_root: Path) -> None:
    expected = {
        "setup": game_root / "Base" / "Assets" / "Configuration" / "Data" / "SetupParameters.xml",
        "base_units": game_root / "Base" / "Assets" / "Gameplay" / "Data" / "Units.xml",
        "base_unit_panel": game_root / "Base" / "Assets" / "UI" / "Panels" / "UnitPanel.lua",
        "base_beliefs": game_root / "Base" / "Assets" / "Gameplay" / "Data" / "Beliefs.xml",
        "religion_screen": game_root / "Base" / "Assets" / "UI" / "ReligionScreen.lua",
        "diplomacy_action_view": game_root
        / "Base"
        / "Assets"
        / "UI"
        / "DiplomacyActionView.lua",
        "world_congress": game_root
        / "DLC"
        / "Expansion2"
        / "Scripts"
        / "WorldCongress.lua",
        "base_art": game_root / "Base" / "ArtDefs" / "Units.artdef",
        "unit_icons": game_root / "Base" / "Assets" / "UI" / "Icons" / "Icons_Units.xml",
        "flag_icons": game_root / "Base" / "Assets" / "UI" / "Icons" / "Icons_UnitFlags.xml",
        "portrait_icons": game_root / "Base" / "Assets" / "UI" / "Icons" / "Icons_UnitPortraits.xml",
        "xp2_schema": game_root / "DLC" / "Expansion2" / "Data" / "Expansion2_Schema.sql",
        "royale_ui": game_root
        / "DLC"
        / "CivRoyaleScenario"
        / "UI"
        / "Replacements"
        / "WorldInput_CivRoyaleScenario.lua",
        "royale_gameplay": game_root
        / "DLC"
        / "CivRoyaleScenario"
        / "Scripts"
        / "CivRoyaleScenario_UnitCommands.lua",
        "royale_start": game_root
        / "DLC"
        / "CivRoyaleScenario"
        / "Scripts"
        / "CivRoyaleScenario_StartScript.lua",
        "nubia_gameplay": game_root / "DLC" / "NubiaScenario" / "Scripts" / "NubiaScenario.lua",
        "black_death_gameplay": game_root
        / "DLC"
        / "BlackDeathScenario"
        / "Scripts"
        / "BlackDeathScenario.lua",
        "black_death_commands": game_root
        / "DLC"
        / "BlackDeathScenario"
        / "Scripts"
        / "BlackDeathScenario_UnitCommands.lua",
        "black_death_state_utils": game_root
        / "DLC"
        / "BlackDeathScenario"
        / "Scripts"
        / "BlackDeathScenario_StateUtils.lua",
        "base_policies": game_root / "Base" / "Assets" / "Gameplay" / "Data" / "Policies.xml",
        "base_modifiers": game_root / "Base" / "Assets" / "Gameplay" / "Data" / "Modifiers.xml",
        "base_victories": game_root / "Base" / "Assets" / "Gameplay" / "Data" / "Victories.xml",
        "base_abilities": game_root
        / "Base"
        / "Assets"
        / "Gameplay"
        / "Data"
        / "UnitAbilities.xml",
        "base_civilizations": game_root
        / "Base"
        / "Assets"
        / "Gameplay"
        / "Data"
        / "Civilizations.xml",
        "base_leaders": game_root
        / "Base"
        / "Assets"
        / "Gameplay"
        / "Data"
        / "Leaders.xml",
        "base_promotions": game_root
        / "Base"
        / "Assets"
        / "Gameplay"
        / "Data"
        / "UnitPromotions.xml",
        "base_global_parameters": game_root
        / "Base"
        / "Assets"
        / "Gameplay"
        / "Data"
        / "GlobalParameters.xml",
        "byzantium_units": game_root
        / "DLC"
        / "Byzantium_Gaul"
        / "Data"
        / "Byzantium_Gaul_Units.xml",
        "soothsayer_promotions": game_root
        / "DLC"
        / "GranColombia_Maya"
        / "Data"
        / "GranColombia_Maya_UnitPromotions_MODE.xml",
        "gameplay_schema": game_root
        / "Base"
        / "Assets"
        / "Gameplay"
        / "Data"
        / "Schema"
        / "01_GameplaySchema.sql",
        "expansion2_abilities": game_root
        / "DLC"
        / "Expansion2"
        / "Data"
        / "Expansion2_UnitAbilities.xml",
        "expansion2_promotions": game_root
        / "DLC"
        / "Expansion2"
        / "Data"
        / "Expansion2_UnitPromotions.xml",
        "expansion2_tutorial": game_root
        / "DLC"
        / "Expansion2"
        / "UI"
        / "Loaders"
        / "TutorialLoader_Expansion2.lua",
        "pirates_minimap": game_root
        / "DLC"
        / "PiratesScenario"
        / "UI"
        / "Replacements"
        / "MinimapPanel_PiratesScenario.lua",
        "pirates_start": game_root
        / "DLC"
        / "PiratesScenario"
        / "Scripts"
        / "PiratesScenario_StartScript.lua",
        "australia_gameplay": game_root
        / "DLC"
        / "AustraliaScenario"
        / "Scripts"
        / "AustraliaScenario.lua",
        "base_world_input": game_root
        / "Base"
        / "Assets"
        / "UI"
        / "WorldInput.lua",
        "great_people_popup": game_root
        / "Base"
        / "Assets"
        / "UI"
        / "Popups"
        / "GreatPeoplePopup.lua",
        "trade_route_chooser": game_root
        / "Base"
        / "Assets"
        / "UI"
        / "Choosers"
        / "TradeRouteChooser.lua",
        "plot_info": game_root
        / "Base"
        / "Assets"
        / "UI"
        / "WorldView"
        / "PlotInfo.lua",
        "viking_gameplay": game_root
        / "DLC"
        / "VikingsScenario"
        / "Scripts"
        / "VikingScenario.lua",
        "alexander_gameplay": game_root
        / "DLC"
        / "AlexanderScenario"
        / "Scripts"
        / "AlexanderScenario.lua",
        "era_complete_lua": game_root
        / "DLC"
        / "Expansion2"
        / "UI"
        / "Additions"
        / "EraCompletePopup.lua",
        "era_complete_xml": game_root
        / "DLC"
        / "Expansion2"
        / "UI"
        / "Additions"
        / "EraCompletePopup.xml",
        "expansion2_ingame": game_root
        / "DLC"
        / "Expansion2"
        / "UI"
        / "Replacements"
        / "InGame.xml",
        "ethiopia_societies": game_root
        / "DLC"
        / "Ethiopia"
        / "Data"
        / "Ethiopia_SecretSocieties_MODE.xml",
        "babylon_heroes": game_root
        / "DLC"
        / "Babylon"
        / "Data"
        / "Babylon_Heroes_XP2_MODE.xml",
        "babylon_heroes_pedia": game_root
        / "DLC"
        / "Babylon"
        / "Text"
        / "en_US"
        / "Babylon_Heroes_Civilopedia_Text_MODE.xml",
        "barbarian_clans": game_root
        / "DLC"
        / "BarbarianClansMode"
        / "Data"
        / "BarbarianClansMode_GameplayData.xml",
        "base_barbarians": game_root
        / "Base"
        / "Assets"
        / "Gameplay"
        / "Data"
        / "Barbarians.xml",
        "poland_scenario": game_root
        / "DLC"
        / "PolandScenario"
        / "Scripts"
         / "PolandScenario.lua",
        "automation_observer": game_root
        / "Base"
        / "Assets"
        / "UI"
        / "Automation"
        / "Automation_ObserverCamera.lua",
    }
    for label, path in expected.items():
        validation.require_file(path, f"game reference {label}")
    if any(not path.is_file() for path in expected.values()):
        return

    setup = strip_trace(expected["setup"].read_text(encoding="utf-8"))
    base_units = strip_trace(expected["base_units"].read_text(encoding="utf-8"))
    base_unit_panel = strip_trace(expected["base_unit_panel"].read_text(encoding="utf-8"))
    base_beliefs = strip_trace(expected["base_beliefs"].read_text(encoding="utf-8"))
    religion_screen = strip_trace(expected["religion_screen"].read_text(encoding="utf-8"))
    diplomacy_action_view = strip_trace(expected["diplomacy_action_view"].read_text(encoding="utf-8"))
    world_congress = strip_trace(expected["world_congress"].read_text(encoding="utf-8"))
    base_art = strip_trace(expected["base_art"].read_text(encoding="utf-8"))
    unit_icons = strip_trace(expected["unit_icons"].read_text(encoding="utf-8"))
    flag_icons = strip_trace(expected["flag_icons"].read_text(encoding="utf-8"))
    portrait_icons = strip_trace(expected["portrait_icons"].read_text(encoding="utf-8"))
    xp2_schema = strip_trace(expected["xp2_schema"].read_text(encoding="utf-8"))
    royale_ui = strip_trace(expected["royale_ui"].read_text(encoding="utf-8"))
    royale_gameplay = strip_trace(expected["royale_gameplay"].read_text(encoding="utf-8"))
    royale_start = strip_trace(expected["royale_start"].read_text(encoding="utf-8"))
    nubia_gameplay = strip_trace(expected["nubia_gameplay"].read_text(encoding="utf-8"))
    black_death_gameplay = strip_trace(expected["black_death_gameplay"].read_text(encoding="utf-8"))
    black_death_commands = strip_trace(expected["black_death_commands"].read_text(encoding="utf-8"))
    black_death_state_utils = strip_trace(expected["black_death_state_utils"].read_text(encoding="utf-8"))
    base_policies = strip_trace(expected["base_policies"].read_text(encoding="utf-8"))
    base_modifiers = strip_trace(expected["base_modifiers"].read_text(encoding="utf-8"))
    base_victories = strip_trace(expected["base_victories"].read_text(encoding="utf-8"))
    base_abilities = strip_trace(expected["base_abilities"].read_text(encoding="utf-8"))
    base_civilizations = strip_trace(expected["base_civilizations"].read_text(encoding="utf-8"))
    base_leaders = strip_trace(expected["base_leaders"].read_text(encoding="utf-8"))
    base_promotions = strip_trace(expected["base_promotions"].read_text(encoding="utf-8"))
    base_global_parameters = strip_trace(expected["base_global_parameters"].read_text(encoding="utf-8"))
    byzantium_units = strip_trace(expected["byzantium_units"].read_text(encoding="utf-8"))
    soothsayer_promotions = strip_trace(expected["soothsayer_promotions"].read_text(encoding="utf-8"))
    gameplay_schema = strip_trace(expected["gameplay_schema"].read_text(encoding="utf-8"))
    expansion2_abilities = strip_trace(expected["expansion2_abilities"].read_text(encoding="utf-8"))
    expansion2_promotions = strip_trace(expected["expansion2_promotions"].read_text(encoding="utf-8"))
    expansion2_tutorial = strip_trace(expected["expansion2_tutorial"].read_text(encoding="utf-8"))
    pirates_minimap = strip_trace(expected["pirates_minimap"].read_text(encoding="utf-8"))
    pirates_start = strip_trace(expected["pirates_start"].read_text(encoding="utf-8"))
    australia_gameplay = strip_trace(expected["australia_gameplay"].read_text(encoding="utf-8"))
    base_world_input = strip_trace(expected["base_world_input"].read_text(encoding="utf-8"))
    great_people_popup = strip_trace(expected["great_people_popup"].read_text(encoding="utf-8"))
    trade_route_chooser = strip_trace(expected["trade_route_chooser"].read_text(encoding="utf-8"))
    plot_info = strip_trace(expected["plot_info"].read_text(encoding="utf-8"))
    viking_gameplay = strip_trace(expected["viking_gameplay"].read_text(encoding="utf-8"))
    alexander_gameplay = strip_trace(expected["alexander_gameplay"].read_text(encoding="utf-8"))
    era_complete_lua = strip_trace(expected["era_complete_lua"].read_text(encoding="utf-8"))
    era_complete_xml = strip_trace(expected["era_complete_xml"].read_text(encoding="utf-8"))
    expansion2_ingame = strip_trace(expected["expansion2_ingame"].read_text(encoding="utf-8"))
    ethiopia_societies = strip_trace(expected["ethiopia_societies"].read_text(encoding="utf-8"))
    babylon_heroes = strip_trace(expected["babylon_heroes"].read_text(encoding="utf-8"))
    babylon_heroes_pedia = strip_trace(expected["babylon_heroes_pedia"].read_text(encoding="utf-8"))
    barbarian_clans = strip_trace(expected["barbarian_clans"].read_text(encoding="utf-8"))
    base_barbarians = strip_trace(expected["base_barbarians"].read_text(encoding="utf-8"))
    poland_scenario = strip_trace(expected["poland_scenario"].read_text(encoding="utf-8"))
    automation_observer = strip_trace(expected["automation_observer"].read_text(encoding="utf-8"))

    validation.check('ConfigurationGroup="Player"' in setup, "base config lacks Player configuration support")
    validation.check(
        '<Replace Name="BARBARIAN_CAMP_ODDS_OF_NEW_CAMP_SPAWNING" Value="2" />'
        in base_global_parameters,
        "original camp spawn-roll parameter is no longer the expected value 2",
    )
    validation.check(
        all(
            token in byzantium_units
            for token in (
                "TAGMA_GRANT_NONRELIGIOUS_AOE_STRENGTH",
                "MODIFIER_PLAYER_UNITS_GRANT_ABILITY",
                'Type="ABILITY_TAGMA_NONRELIGIOUS_COMBAT" Tag="CLASS_ALL_COMBAT_UNITS"',
            )
        ),
        "Firaxis Tagma combat-unit aura target reference not found",
    )
    validation.check(
        all(
            token in soothsayer_promotions
            for token in (
                "PROMOTION_SOOTHSAYER_INCANTATION",
                "SOOTHSAYER_ADJACENT_UNIT_STRENGTH",
                "MODIFIER_PLAYER_UNITS_GRANT_ABILITY",
                "REQUIREMENT_PLOT_ADJACENT_TO_OWNER",
                "<Name>MinDistance</Name>",
                "<Name>MaxDistance</Name>",
            )
        ),
        "Firaxis Soothsayer promotion-owned adjacent aura reference not found",
    )
    validation.check('UnitType="UNIT_SCOUT"' in base_units, "base UNIT_SCOUT row not found")
    validation.check(
        "unit:GetBuildCharges()" in base_unit_panel,
        "official Builder remaining-charge API reference not found",
    )
    for unit_type, technology, combat in (
        ("UNIT_SWORDSMAN", "TECH_IRON_WORKING", "35"),
        ("UNIT_MAN_AT_ARMS", "TECH_APPRENTICESHIP", "45"),
        ("UNIT_MUSKETMAN", "TECH_GUNPOWDER", "55"),
        ("UNIT_LINE_INFANTRY", "TECH_MILITARY_SCIENCE", "65"),
        ("UNIT_INFANTRY", "TECH_REPLACEABLE_PARTS", "75"),
        ("UNIT_MECHANIZED_INFANTRY", "TECH_SATELLITES", "85"),
    ):
        validation.check(
            f'UnitType="{unit_type}"' in base_units
            and f'Combat="{combat}"' in base_units
            and f'PrereqTech="{technology}"' in base_units,
            f"base melee technology tier missing: {unit_type}/{technology}/{combat}",
        )
    validation.check(
        'ExclusivePopupManager:new("EraCompletePopupXP2")' in era_complete_lua
        and 'UI.PlaySound("UI_Era_Change")' in era_complete_lua
        and "Controls.EraPopupAnimation:Reverse()" in era_complete_lua
        and "Events.LocalPlayerTurnBegin.Add( OnCheckGameEraChanged )" in era_complete_lua
        and 'ID="EraPopupAnimation"' in era_complete_xml
        and 'EndPause="2"' in era_complete_xml
        and 'ID="HeaderSlide"' in era_complete_xml
        and 'ID="EraCompletePopup"' in expansion2_ingame
        and 'FileName="EraCompletePopup"' in expansion2_ingame,
        "Gathering Storm era-complete context/animation reference not found",
    )
    base_unit_tags = {
        row.attrib["Tag"]
        for row in ET.fromstring(base_units).findall("./Tags/Row")
        if row.attrib.get("Tag")
    }
    abilities_root = ET.parse(ROOT / "Gameplay" / "LOTM_RP_Abilities.xml").getroot()
    ability_type_tags = {
        row.attrib["Tag"]
        for row in abilities_root.findall("./TypeTags/Row")
        if row.attrib.get("Tag")
    }
    types_root = ET.parse(ROOT / "Gameplay" / "LOTM_RP_Types.xml").getroot()
    mod_defined_tags = {
        row.attrib["Tag"]
        for row in types_root.findall("./Tags/Row")
        if row.attrib.get("Tag") and row.attrib.get("Vocabulary") == "ABILITY_CLASS"
    }
    ability_requirement_tags = {
        row.attrib["Value"]
        for row in abilities_root.findall("./RequirementArguments/Row")
        if row.attrib.get("Name") == "Tag" and row.attrib.get("Value")
    }
    missing_tags = sorted(
        (ability_type_tags | ability_requirement_tags) - base_unit_tags - mod_defined_tags
    )
    validation.check(
        not missing_tags,
        f"ability TypeTag/requirement tag is absent from the base-game or mod Tags table: {missing_tags}",
    )
    validation.check('m_Name text="UNIT_SCOUT"' in base_art, "base Scout ArtDef not found")
    validation.check('Name="ICON_UNIT_SCOUT"' in unit_icons, "base Scout unit icon not found")
    validation.check('Name="ICON_UNIT_SCOUT_WHITE"' in flag_icons, "base Scout flag icon not found")
    validation.check('Name="ICON_UNIT_SCOUT_PORTRAIT"' in portrait_icons, "base Scout portrait not found")
    validation.check("CanFormMilitaryFormation" in xp2_schema, "Expansion2 Units_XP2 formation field not found")
    validation.check(
        "UnitManager.RequestCommand" in royale_ui and "UnitCommandTypes.EXECUTE_SCRIPT" in royale_ui,
        "official CivRoyale EXECUTE_SCRIPT sender not found",
    )
    validation.check(
        "UI.RequestPlayerOperation(Game.GetLocalPlayer(), PlayerOperations.EXECUTE_SCRIPT" in black_death_state_utils
        and 'kParameters.OnStart = "OnPlayerCommandSetObjectState"' in black_death_state_utils
        and "GameEvents.OnPlayerCommandSetObjectState.Add" in black_death_state_utils,
        "official Black Death UI-to-Gameplay synchronized property-command pattern not found",
    )
    validation.check(
        "parameters :table" in royale_gameplay and "GameEvents.ScenarioCommand_" in royale_gameplay,
        "official CivRoyale Gameplay command handler signature not found",
    )
    validation.check(
        "GameEvents.OnCombatOccurred.Add" in royale_start
        and "GameEvents.PostUnitPromotionEarned.Add" in royale_start,
        "official combat/promotion Gameplay event references not found",
    )
    validation.check(
        "GameEvents.OnDistrictConstructed.Add" in nubia_gameplay,
        "official synchronized district-completion event reference not found",
    )
    validation.check(
        "GetPatronizeCost" in great_people_popup
        and "GetPastTimeline" in great_people_popup
        and "CanPatronizePerson" in great_people_popup,
        "official Great Person patronage price/timeline references not found",
    )
    validation.check(
        "CanReceiveInfluence()" in trade_route_chooser
        and "GiveFreeTokenToPlayer" in alexander_gameplay,
        "official city-state influence APIs not found",
    )
    validation.check(
        "function OnCityMadePurchase(owner:number, cityID:number, plotX:number, plotY:number, purchaseType, objectType)"
        in plot_info,
        "official CityMadePurchase event signature not found",
    )
    validation.check(
        'SetCivic(GameInfo.Civics["CIVIC_CODE_OF_LAWS"].Index, true)'
        in viking_gameplay,
        "official Code of Laws completion API reference not found",
    )
    validation.check(
        "GetExperiencePoints()" in nubia_gameplay and "ChangeExperience(" in nubia_gameplay,
        "official unit experience API references not found",
    )
    validation.check(
        "AttachModifierByID" in black_death_gameplay,
        "official dynamic modifier attachment reference not found",
    )
    validation.check(
        "IsPolicyActive(" in black_death_gameplay
        and "UnlockPolicy(" in black_death_gameplay
        and "IsPolicyActive(" in pirates_start,
        "official active-policy check or explicit policy-unlock Gameplay reference not found",
    )
    validation.check(
        "REQUIREMENT_UNIT_TYPE_MATCHES" in base_policies,
        "base unit-type requirement reference not found",
    )
    validation.check(
        "MODIFIER_PLAYER_UNITS_ADJUST_COMBAT_STRENGTH" in base_modifiers,
        "base player-unit combat modifier type not found",
    )
    validation.check(
        "MODIFIER_UNIT_ADJUST_BASE_COMBAT_STRENGTH" in base_modifiers
        and "EFFECT_ADJUST_UNIT_COMBAT_STRENGTH" in base_modifiers,
        "base Unit:GetCombat()-visible combat-strength effect not found",
    )
    validation.check(
        "MODIFIER_PLAYER_UNITS_ADJUST_MOVEMENT" in base_modifiers
        and "MODIFIER_ALL_PLAYERS_ATTACH_MODIFIER" in base_modifiers
        and "MODIFIER_PLAYER_ADJUST_WAR_WEARINESS" in base_modifiers,
        "base player-wide movement, all-player attachment, or war-weariness modifier type not found",
    )
    validation.check(
        "REQUIREMENT_PLAYER_IS_AT_PEACE" in base_leaders,
        "base dynamic peace-with-owner relationship requirement not found",
    )
    validation.check(
        "COLLECTION_MAJOR_OPPOSING_PLAYERS" in base_victories,
        "base opposing-major-player collection reference not found",
    )
    validation.check(
        "GDR_SIEGE_LASER" in expansion2_promotions
        and "MODIFIER_PLAYER_UNIT_IGNORE_RANGED_VS_DISTRICT_PENALTY"
        in expansion2_promotions
        and "GDR_SIEGE_LASER_RANGE_STR" in expansion2_promotions
        and "SIEGE_LASER_STRENGTH_REQUIREMENTS" in expansion2_promotions
        and "OPPONENT_IS_DISTRICT" in expansion2_promotions
        and "<Value>30</Value>" in expansion2_promotions,
        "Gathering Storm GDR Particle Beam Siege Cannon reference not found",
    )
    validation.check(
        "CLASS_ALL_COMBAT_UNITS" in base_units,
        "base all-combat-units ability meta-class not found",
    )
    validation.check(
        "TRAIT_INCREASE_ENEMY_WAR_WEARINESS" in base_leaders
        and '<Value>100</Value>' in base_leaders
        and "DEFENSEOFMOTHERLAND_DOMESTICWARWEARINESS" in base_policies
        and '<Value>-100</Value>' in base_policies,
        "base +100% enemy / -100% friendly war-weariness sign references not found",
    )
    validation.check(
        "REQUIREMENT_OPPONENT_IS_BARBARIAN" in base_civilizations
        and "REQUIREMENT_OPPONENT_IS_WOUNDED" in base_leaders,
        "base barbarian/wounded combat requirements not found",
    )
    validation.check(
        "REQUIREMENT_COMBAT_TYPE_MATCHES" in base_promotions
        and "<Value>COMBAT_MELEE</Value>" in base_promotions,
        "base melee-defense requirement pattern not found",
    )
    validation.check(
        "RANGER_IGNORE_FOREST_MOVEMENT_PENALTY" in base_promotions
        and "<Value>FOREST</Value>" in base_promotions
        and "<Value>HILLS</Value>" in base_promotions,
        "base recon Woods/Rainforest and Hills movement patterns not found",
    )
    validation.check(
        "UnlocksFromEffect" in gameplay_schema and "MaxPlayerInstances" in gameplay_schema,
        "project effect-unlock/instance-limit schema fields not found",
    )
    validation.check(
        "VARU_NEGATIVE_COMBAT" in expansion2_abilities
        and "<SubjectStackLimit>1</SubjectStackLimit>" in expansion2_abilities,
        "Expansion2 non-stacking adjacent enemy aura pattern not found",
    )
    validation.check(
        "Events.CityProjectCompleted.Add" in expansion2_tutorial,
        "official project-completion event signature not found",
    )
    validation.check(
        "Events.GoodyHutReward.Add" in pirates_minimap
        and "function OnGoodyHutReward" in pirates_minimap,
        "official goody-hut reward event signature not found",
    )
    validation.check(
        "MODIFIER_PLAYER_ALLOW_PROJECT" in ethiopia_societies
        and "EFFECT_ADD_PLAYER_PROJECT_AVAILABILITY" in ethiopia_societies,
        "official allow-project dynamic modifier definition not found",
    )
    validation.check(
        "HeroClassType=" in babylon_heroes
        and 'UnitType="UNIT_HERO_' in babylon_heroes
        and UNIT_TYPE not in babylon_heroes,
        "Heroes & Legends reference or custom-unit namespace separation not found",
    )
    validation.check(
        "Encountering a Tribal Village" in babylon_heroes_pedia,
        "official Heroes & Legends reference must confirm tribal villages can discover heroes",
    )
    validation.check(
        'ImprovementType="IMPROVEMENT_BARBARIAN_CAMP"' in barbarian_clans
        and "<RemoveOnEntry>false</RemoveOnEntry>" in barbarian_clans,
        "Barbarian Clans camp-behavior reference not found",
    )
    validation.check(
        all(token in barbarian_clans for token in (
            'Type="TRIBE_CLAN_MELEE_OPEN"', 'Type="TRIBE_CLAN_MELEE_FOREST"',
            'Type="TRIBE_CLAN_MELEE_HILLS"', 'Type="TRIBE_CLAN_CAVALRY_OPEN"',
            'Type="TRIBE_CLAN_CAVALRY_JUNGLE"', 'Type="TRIBE_CLAN_NAVAL"',
        ))
        and all(token in base_barbarians for token in (
            'TribeType="TRIBE_MELEE"', 'TribeType="TRIBE_CAVALRY"',
            'TribeType="TRIBE_NAVAL"', 'DefenderTag="CLASS_ANTI_CAVALRY"',
        )),
        "official clan and ordinary barbarian tribe types not found",
    )
    validation.check(
        "CreateTribeOfType(eType, iPlotIndex)" in poland_scenario
        and 'CreateTribeUnits(iMarienburgTribeNumber, "CLASS_HEAVY_CAVALRY"' in poland_scenario,
        "official synchronized CreateTribeOfType/CreateTribeUnits Gameplay reference not found",
    )
    validation.check(
        "Automation.GetTime()" in automation_observer,
        "official high-resolution Automation.GetTime reference not found",
    )
    validation.check(
        "GameEvents.OnPillage.Add" in pirates_start
        and "function OnPillage(" in pirates_start,
        "official ordinary-pillage Gameplay event signature not found",
    )
    validation.check(
        "SetImprovementPillaged(pPlot, true)" in australia_gameplay
        and "pUnit:ChangeDamage(" in australia_gameplay
        and "UnitManager.FinishMoves(pUnit)" in australia_gameplay,
        "official improvement pillage, unit damage, or movement exhaustion API reference not found",
    )
    validation.check(
        "Game.AddWorldViewText(0, message, pUnit:GetX(), pUnit:GetY())"
        in black_death_commands,
        "official four-argument world-view text signature not found",
    )
    validation.check(
        "UILens.SetLayerHexesArea" in base_world_input
        and "UI.GetCursorPlotID()" in base_world_input,
        "official target highlighting/cursor plot UI reference not found",
    )
    validation.check(
        'BeliefClassType="BELIEF_CLASS_PANTHEON"' in base_beliefs
        and 'BeliefClassType="BELIEF_CLASS_FOUNDER"' in base_beliefs,
        "official pantheon/founder belief rows not found",
    )
    validation.check(
        'PopulateAvailableBeliefs("BELIEF_CLASS_PANTHEON")' in religion_screen
        and "m_pGameReligion:GetReligions()" in religion_screen,
        "official religion chooser belief enumeration reference not found",
    )
    validation.check(
        "Events.DiplomacyStatement.Add" in diplomacy_action_view
        and "DiplomacyManager.GetKeyName" in diplomacy_action_view
        and 'DiplomacyManager.RequestSession(ms_LocalPlayerID, ms_SelectedPlayerID, "DENOUNCE")'
        in diplomacy_action_view,
        "official denounce statement UI flow reference not found",
    )
    validation.check(
        "Game.GetReligion():GetReligions()" in world_congress,
        "official Gameplay religion enumeration reference not found",
    )


def validate_workshop_artifacts(validation: Validation) -> None:
    sql_path = ROOT / "Gameplay" / "LOTM_PP_Artifacts.sql"
    artifacts_path = ROOT / "Scripts" / "LOTM_PP_Artifacts.lua"
    workshops_path = ROOT / "Scripts" / "LOTM_PP_Workshops.lua"
    ui_path = ROOT / "UI" / "LOTM_PP_ArtifactsScreen.lua"
    ui_xml_path = ROOT / "UI" / "LOTM_PP_ArtifactsScreen.xml"
    flag_path = ROOT / "UI" / "LOTM_PP_UnitFlagManager.lua"
    showcase_path = ROOT / "UI" / "LOTM_PP_ArtifactShowcase.lua"
    showcase_xml_path = ROOT / "UI" / "LOTM_PP_ArtifactShowcase.xml"
    icon_xml_path = ROOT / "Art" / "LOTM_Artifact_Icons.xml"
    icon_builder_path = ROOT / "Tests" / "build_artifact_launch_icon.py"
    artifact_builder_path = ROOT / "Tests" / "build_artifact_dds.py"
    subsystem_paths = (sql_path, artifacts_path, workshops_path, ui_path, ui_xml_path, flag_path, showcase_path, showcase_xml_path, icon_xml_path, icon_builder_path, artifact_builder_path)
    for path in subsystem_paths:
        validation.require_file(path, "complete workshop/artifact subsystem")
    if not all(path.is_file() for path in subsystem_paths):
        return
    sql = strip_trace(sql_path.read_text(encoding="utf-8"))
    artifacts = strip_trace(artifacts_path.read_text(encoding="utf-8"))
    workshops = strip_trace(workshops_path.read_text(encoding="utf-8"))
    ui = strip_trace(ui_path.read_text(encoding="utf-8"))
    ui_xml = strip_trace(ui_xml_path.read_text(encoding="utf-8"))
    flags = strip_trace(flag_path.read_text(encoding="utf-8"))
    showcase = strip_trace(showcase_path.read_text(encoding="utf-8"))
    showcase_xml = strip_trace(showcase_xml_path.read_text(encoding="utf-8"))
    icon_xml = strip_trace(icon_xml_path.read_text(encoding="utf-8"))
    icon_builder = strip_trace(icon_builder_path.read_text(encoding="utf-8"))
    artifact_builder = strip_trace(artifact_builder_path.read_text(encoding="utf-8"))
    zh_artifact_text = strip_trace((ROOT / "Text" / "zh_Hans_CN" / "LOTM_RP_GameplayText.xml").read_text(encoding="utf-8"))
    for token in (
        "MODIFIER_PLAYER_GRANT_RANDOM_RESOURCE_PRODUCT",
        "GREATWORKSLOT_LOTM_PP_SEALED_ARTIFACT",
        "REQUIREMENT_PLAYER_HAS_RESOURCE_OWNED",
        "LOTM_PP_FX_GOLDEN_TOURISM",
        "LOTM_PP_FX_ASTROLABE_SPACE",
        "LOTM_PP_FX_FURNACE_AMENITY",
        "LOTM_PP_FX_BLUEPRINT_GROWTH",
        "LOTM_PP_FX_STELE_PRODUCTION",
        "ABILITY_LOTM_PP_HERMES_BUILDER",
    ):
        validation.check(token in sql, f"artifact SQL lacks {token}")
    validation.check(sql.count("GREATWORK_LOTM_PP_") >= 21, "all seven GreatWork artifacts must be registered and mapped")
    validation.check(
        "('LOTM_PP_FX_GOLDEN_TOURISM','MODIFIER_PLAYER_CITIES_ADJUST_TOURISM'" in sql
        and "('LOTM_PP_FX_GOLDEN_TOURISM','GreatWorkObjectType','GREATWORKOBJECT_WRITING')" in sql
        and sql.count("'ScalingFactor','200'") >= 9
        and "('LOTM_PP_FX_GOLDEN_TOURISM','MODIFIER_PLAYER_ADJUST_TOURISM'" not in sql,
        "Golden Appraisal Mirror must double tourism for each GreatWork class without doubling unrelated tourism",
    )
    validation.check(
        "UPDATE Modifiers SET Permanent=0" in sql
        and "ModifierId LIKE 'LOTM_PP_FX_%'" in sql
        and "ModifierId LIKE 'LOTM_RP_ART_%'" in sql
        and "ModifierId LIKE 'LOTM_BE_ART_%'" in sql,
        "all three paths' requirement-controlled equipment modifiers must be reversible (Permanent=0)",
    )
    validation.check(
        "LOTM_ArtifactTurnLeases" in sql
        and "_LEASE70" in sql
        and "RESOURCE_LOTM_ARTIFACT_LEASE_01" in sql
        and "RESOURCE_LOTM_ARTIFACT_LEASE_21" in sql
        and "_RC70_COUNTER" in sql,
        "artifact effects must use fresh rc.70 per-turn lease IDs and legacy inverse counters",
    )
    validation.check(
        "LOTM_ArtifactTurnLeases76" in sql
        and "RESOURCE_LOTM_ARTIFACT_LEASE76_" in sql
        and "_LEASE76" in sql
        and 'LOTM_PP_ARTIFACT_LEASE76_EFFECTS_ATTACHED' in artifacts
        and 'retired lease70' in artifacts
        and 'retired lease76' in artifacts
        and 'positive lease81' in artifacts
        and 'negative lease81' in artifacts,
        "rc.81 must retire serialized rc.70/rc.76 leases and issue split positive/negative leases",
    )
    for token in (
        "LOTM_RP_ART_EMBER_FAST_PILLAGE",
        "LOTM_RP_ART_LETTER_PEACE_GOLD",
        "LOTM_RP_ART_BANNER_MAINTENANCE",
        "LOTM_RP_ART_SCRIPTURE_WEARINESS",
        "LOTM_RP_ART_WEATHER_ENEMY_STRENGTH_AURA",
        "LOTM_RP_ART_CROWN_ATTACK_DISTRICT",
        "LOTM_BE_ART_BRIBE_ROUTE_GOLD",
        "LOTM_BE_ART_FRENZY_FOOD_AURA",
        "LOTM_BE_ART_ENTROPY_PRESSURE",
        "LOTM_BE_ART_ORDER_PRODUCTION",
    ):
        validation.check(token in sql, f"complete artifact audit lacks {token}")
    validation.check(
        'GameEvents.OnCombatOccurred.Add(OnCombatOccurred)' in artifacts
        and 'Events.DiplomacyDeclareWar.Add(OnDiplomacyDeclareWar)' in artifacts
        and 'ChangeCurrentCulturalProgress(converted)' in artifacts
        and 'local converted=production/3; orderConverted=converted;' in artifacts,
        "artifact combat, first-war, and exact production-conversion settlements are incomplete",
    )
    validation.check(
        "CleanupLegacyLatchedEffects" in artifacts
        and "GameEffects.GetModifierActive" in artifacts
        and "SetLegacySwitchOff" in artifacts
        and "SetTurnLease" in artifacts
        and 'Reconcile(playerID,true)' in artifacts,
        "artifact Gameplay must expire/reissue leases each turn and migrate proven legacy latches",
    )
    validation.check(
        "local function ProcessTurn(playerID,isFirstTimeThisTurn)" in artifacts
        and "if isFirstTimeThisTurn==false then return; end" in artifacts
        and 'local TURN_SETTLED :string = "LOTM_PP_ARTIFACT_TURN_SETTLED";' in artifacts
        and "if NumberProperty(p,TURN_SETTLED)==turn then return; end" in artifacts
        and "p:SetProperty(TURN_SETTLED,turn);" in artifacts,
        "artifact turn settlement must be reconnect-safe and idempotent per game turn",
    )
    for token in (
        "GameEvents.LOTM_PP_Command_Artifact.Add",
        "LOTM_PP_ARTIFACT_EXPECTED_CREATED_TYPE",
        "BindInstance",
        "ChangeResourceAmount",
        "TriggerBoost",
        "ChangePointsTotal",
        "LOTM_BE_ART_CODEX_SCIENCE_FLAT",
        "ABILITY_LOTM_PP_HERMES_BUILDER",
    ):
        validation.check(token in artifacts, f"artifact synchronized Gameplay lacks {token}")
    for token in (
        'local classificationRoll=StableClassificationRoll(plotIndex,"CLASSIFICATION",100)',
        'local workshop=classificationRoll<chance',
        "Game.GetEras():GetCurrentEra()",
        "LOTM_PP_WORKSHOP_SEQUENCE_CREATED",
        "count%2==0",
        "ABILITY_LOTM_PP_WORKSHOP_LEVEL0_STRENGTH",
        "ChangeDamage(-math.min(10",
        "LOTM_PP_GrantWorkshopReward",
        "GameEvents.OnUnitMoved.Add",
    ):
        validation.check(token in workshops, f"workshop synchronized Gameplay lacks {token}")
    validation.check(
        "local function OnTurn(playerID,isFirstTimeThisTurn)" in workshops
        and "if isFirstTimeThisTurn==false then return; end" in workshops,
        "workshop barbarian-turn processing must not repeat on save/load or reconnect activation",
    )
    validation.check(
        'local PATHS={"PP","RP","BE"}' in workshops
        and 'available[StableClassificationRoll(plotIndex,"PATH:"..tostring(level),#available)+1]' in workshops,
        "all currently available workshop paths must be sampled uniformly",
    )
    validation.check(
        "Game.GetRandNum" not in workshops
        and 'GameConfiguration.GetValue("GAME_SYNC_RANDOM_SEED")' in workshops
        and 'MapConfiguration.GetValue("RANDOM_SEED")' in workshops,
        "workshop improvement callbacks must use seed-derived stable rolls without advancing synchronized RNG",
    )
    validation.check(
        "('ABILITY_LOTM_PP_WORKSHOP_SEQUENCE_STRENGTH','CLASS_RECON')" in sql
        and "('ABILITY_LOTM_PP_WORKSHOP_LEVEL0_STRENGTH','CLASS_ALL_COMBAT_UNITS')" in sql,
        "workshop instance abilities must be valid for the sequence guard and normal combat units",
    )
    validation.check(
        "('LOTM_PP_WORKSHOP_SEQUENCE_STRENGTH_MOD','Preview','LOC_LOTM_PP_PREVIEW_BEYONDER_EFFECT')" in sql
        and "('LOTM_PP_WORKSHOP_LEVEL0_STRENGTH_MOD','Preview','LOC_LOTM_PP_PREVIEW_BEYONDER_EFFECT')" in sql,
        "workshop +10 modifiers must expose the shared Beyonder Effect combat-preview label",
    )
    validation.check(
        "<Text>+10 非凡者效果</Text>" in zh_artifact_text,
        "Beyonder combat preview must explicitly show +10",
    )
    for token in (
        'RP={[2]="LOC_LOTM_RP_WORKSHOP_HARVESTER_NAME"',
        'BE={[2]="LOC_LOTM_BE_WORKSHOP_CHAOS_MENTOR_NAME"',
        "ApplySequenceName(unit,path,level)",
        "ApplySequenceName(u,u:GetProperty(PATH)",
    ):
        validation.check(token in workshops, f"workshop path-specific guard naming lacks {token}")
    validation.check(
        "EnsureSequenceStrength(unit,baseline or 20)" in workshops
        and "EnsureSequenceStrength(u,nil); UnitManager.FinishMoves(u); return" in workshops
        and "EnsureSequenceStrength(u,nil)" in workshops
        and "LOTM_Effects.SetAbilityCount(ability,DYNAMIC_STRENGTH_ABILITY,0)" in workshops
        and "ResolveMeleeBaseline" in workshops,
        "sequence guard strength must be attached at creation and repaired for existing saves",
    )
    validation.check(
        "local function NumberValue(value) if value==nil then return nil; end return tonumber(value); end" in workshops
        and "tonumber(desiredCount)" not in workshops,
        "workshop strength migration must not call Civ VI tonumber with a nil argument",
    )
    validation.check(
        'p:SetProperty("LOTM_PP_ARTIFACT_EFFECT_REFRESH_PENDING",1)' in artifacts
        and "Reconcile(playerID,true)" in artifacts
        and "Each player turn reissues effects for that turn" in strip_trace((ROOT / "Text" / "en_US" / "LOTM_RP_GameplayText.xml").read_text(encoding="utf-8")),
        "equip and unequip must schedule a documented next-turn lease refresh",
    )
    validation.check(
        "LOTM_PP_ARTIFACT_SHOWCASE_SERIAL" in artifacts
        and "LOTM_PP_ARTIFACT_SHOWCASE_SERIAL" in showcase
        and "ICON_" in showcase
        and 'Texture="Diplomacy_Banner"' in showcase_xml
        and 'include("GreatWorkShowcase")' not in showcase,
        "artifact reward must use an independent Firaxis-style reveal without replacing GreatWorkShowcase",
    )
    for token in ('Name="GreatWorkSlot"', 'Name="GreatWork"', 'ID="EquipmentGroups"', 'ID="InventoryGroups"', 'Texture="GreatWorks_MuseumSlot"', 'Texture="GreatWorks_EmptySlot"'):
        validation.check(token in ui_xml, f"artifact page XML lacks {token}")
    validation.check("PlayerOperations.EXECUTE_SCRIPT" in ui and "UI.RequestPlayerOperation" in ui, "artifact UI must submit only synchronized equipment commands")
    validation.check(
        'SetIcon(m_launch.LaunchIcon,"ICON_LOTM_ARTIFACT_LAUNCH",40)' in ui
        and 'Name="ICON_LOTM_ARTIFACT_LAUNCH" Atlas="ICON_ATLAS_LOTM_ARTIFACT_LAUNCH"' in icon_xml
        and all(f'IconSize="{size}"' in icon_xml and f'Filename="LOTM_ArtifactLaunchIcon{size}.dds"' in icon_xml for size in (40, 64, 256))
        and "ICON_SIZES = (40, 64, 256)" in icon_builder
        and "from PIL import Image, ImageDraw" in icon_builder
        and "draw.ellipse(" in icon_builder
        and "content_size = max(1, round(size * 0.90))" in icon_builder,
        "artifact LaunchBar entry must use its independent user-supplied eye icon atlas",
    )
    validation.check(
        "def render_contained(image: Image.Image, size: int)" in artifact_builder
        and "fitted.thumbnail((usable, usable), Image.Resampling.LANCZOS)" in artifact_builder
        and "canvas.alpha_composite(" in artifact_builder
        and "rendered.save(DDS_OUTPUT / filename" in artifact_builder
        and "rendered.save(OUTPUT / filename" in artifact_builder
        and "image.crop((left, top, left + side, top + side))" not in artifact_builder,
        "artifact atlas builder must contain the full portrait source without square cropping",
    )
    validation.check(
        "local SLOT_COUNT :number = 9" in ui
        and "for slotNumber=1,SLOT_COUNT do" in ui
        and "local GROUP_COUNT :number = 3" in ui
        and "local SLOTS_PER_GROUP :number = 3" in ui
        and "for slot=1,9 do" in artifacts,
        "artifact equipment state and Great-Works-style page must expose all nine synchronized slots",
    )
    validation.check(
        not (ROOT / "UI" / "LOTM_PP_Artifacts.lua").exists()
        and 'include("LOTM_PP_Artifacts")' in strip_trace((ROOT / "Scripts" / "LOTM_RP_Gameplay.lua").read_text(encoding="utf-8")),
        "artifact UI basename must not shadow the synchronized Gameplay include",
    )
    validation.check(
        "for _,city in p:GetCities():Members()" in artifacts
        and 'LOTM_PP_ARTIFACT_INSTANCE_"..artifactType' in ui
        and "GetNumGreatWorkSlots" not in ui,
        "artifact ownership must use synchronized ledger properties rather than city GreatWork slots",
    )
    validation.check(
        "LOTM_PP_DIPLOMACY_DEAL_FILTER" not in strip_trace((ROOT / "RedPriestPath.modinfo").read_text(encoding="utf-8"))
        and not (ROOT / "UI" / "LOTM_PP_DiplomacyDealView.lua").exists(),
        "isolated artifacts must not replace the stock diplomacy deal context",
    )
    validation.check("0xFF1678A9" in flags and "ICON_LOTM_PP_PERFECT_MARK" in flags, "sequence flag must use #A97816 and the Perfect mark")
    validation.check(
        "GREATWORKSLOT_LOTM_PP_SEALED_ARTIFACT" in sql
        and 'LOTM_PP_GREAT_WORKS_OVERVIEW_FILTER' not in strip_trace((ROOT / "RedPriestPath.modinfo").read_text(encoding="utf-8"))
        and 'LOTM_PP_GREAT_WORK_SHOWCASE_FILTER' not in strip_trace((ROOT / "RedPriestPath.modinfo").read_text(encoding="utf-8"))
        and not (ROOT / "UI" / "LOTM_PP_GreatWorksOverview.lua").exists()
        and not (ROOT / "UI" / "LOTM_PP_GreatWorkShowcase.lua").exists()
        and "STORAGE_CLEANUP_MODIFIER" in artifacts,
        "official Great Works overview and showcase must be left completely stock while old slots are cleaned",
    )
    validation.check(
        "Drag.eDown" in ui
        and "m_viableDropTargets" in ui
        and "GetBestOverlappingControl(m_viableDropTargets)" in ui
        and "HighlightDropTarget" in ui
        and "OnArtifactDrop" in ui
        and 'Style="FullScreenVignetteConsumer"' in ui_xml,
        "artifact drag/drop must follow the Firaxis down-target-drag-drop state machine and consume map input",
    )
    validation.check(
        "Events.GreatWorkMoved" not in artifacts
        and 'LOTM_MP_TurnSync.Add(ProcessTurn,"Artifacts")' in artifacts,
        "synchronized artifact ownership refresh must not subscribe to the UI-only GreatWorkMoved event",
    )
    validation.check(
        "Events.GreatWorkMoved" not in ui
        and "Events.GreatWorkCreated" not in ui
        and 'parameters.Action=="TRANSFER"' in artifacts,
        "independent artifact UI must not observe stock GreatWork lifecycle events",
    )
    validation.check(
        "NumberProperty(p,INSTANCE_PREFIX..artifactType)==tonumber(instance)" in artifacts
        and 'BindInstance(playerID,t,instance,"GreatWorkCreated")' in artifacts
        and 'BindInstance(playerID,t,instance,"rc58-last-reward-migration")' in artifacts
        and "Game.GetGreatWorkPlayer" not in artifacts
        and "Game.GetGreatWorkDataFromIndex" not in artifacts
        and "for candidate=0,2047" not in artifacts,
        "artifact Gameplay validation must use synchronized grant-time type-instance mapping",
    )
    validation.check(
        'BindInstance(playerID,artifactType,synthetic,"isolated-ledger")' in artifacts
        and "LOTM_PP_ARTIFACT_LEDGER_RECOVERED_RC61" in artifacts
        and 'p:GetProperty("LOTM_PP_LAST_REWARD")' in artifacts
        and "GetNumGreatWorkSlots" not in ui,
        "artifact grants and rc.60 recovery must remain isolated from Firaxis GreatWork slots",
    )
    validation.check(
        "UnitManager.FinishMoves" in workshops
        and "SetMovesRemaining" not in workshops
        and "clearerValue~=nil and tonumber(clearerValue) or nil" in workshops,
        "workshop sequence movement and optional clearer property must use runtime-safe APIs",
    )


def validate_gameplay_manual(validation: Validation) -> None:
    manual_lua_path = ROOT / "UI" / "LOTM_RP_Manual.lua"
    manual_xml_path = ROOT / "UI" / "LOTM_RP_Manual.xml"
    bridge_path = ROOT / "UI" / "LOTM_RP_ExpansionIntroBridge.lua"
    zh_path = ROOT / "Text" / "zh_Hans_CN" / "LOTM_RP_ManualText.xml"
    en_path = ROOT / "Text" / "en_US" / "LOTM_RP_ManualText.xml"
    cult_icon_xml_path = ROOT / "Art" / "LOTM_AI_Cult_Icons.xml"
    cult_icon_paths = tuple(
        ROOT / "Art" / f"LOTM_AI_Cult_{name}_200.dds"
        for name in ("Demoness", "HangedMan", "Chained")
    )
    for path in (manual_lua_path, manual_xml_path, bridge_path, zh_path, en_path, cult_icon_xml_path, *cult_icon_paths):
        validation.require_file(path, "gameplay manual file")
    if not all(path.is_file() for path in (manual_lua_path, manual_xml_path, bridge_path)):
        return

    manual = strip_trace(manual_lua_path.read_text(encoding="utf-8"))
    bridge = strip_trace(bridge_path.read_text(encoding="utf-8"))
    modinfo = strip_trace(MODINFO.read_text(encoding="utf-8"))
    validation.check(
        "local STANDARD_NUM_PAGES :number = 13" in manual
        and "local RESCUE_NUM_PAGES :number = 9" in manual
        and "HideLOTMFeaturesScreen" in manual
        and "LastShownLOTMGameSignature" in manual
        and "HideLOTMRescueFeaturesScreen" in manual
        and "LastShownLOTMRescueGameSignature" in manual,
        "manual must contain independent 13-page ordinary and 9-page Rescue books with separate local option keys",
    )
    validation.check(
        "tonumber(lastShownOption or -1)" in manual
        and "tonumber(hideOption or 0)" in manual
        and 'tonumber(Options.GetUserOption("Tutorial", OPTIONS_LAST_GAME_KEY))' not in manual,
        "manual first-run option reads must tolerate Firaxis returning no value",
    )
    manual_xml = strip_trace(manual_xml_path.read_text(encoding="utf-8"))
    validation.check(
        'FontSize="20"' in manual_xml
        and 'FontSize="18"' in manual_xml
        and 'ID="DontShowAgainLabel"' in manual_xml
        and 'SetIcon(control, "ICON_" .. artifactType, 64)' in manual
        and 'control:SetSizeX(64); control:SetSizeY(64);' in manual,
        "manual must use complete 64px artifact icons and enlarged right-column text",
    )
    validation.check(
        'Game.GetProperty("LOTM_RESCUE_MODE")' in manual
        and "m_pages = m_isRescue and RESCUE_PAGES or STANDARD_PAGES" in manual
        and 'Controls.ManualTitle:SetText(Locale.Lookup(m_isRescue and "LOC_LOTM_RESCUE_MANUAL_TITLE" or "LOC_LOTM_MANUAL_TITLE"))' in manual
        and "RESCUE_PAGE_CONCEPT_ICONS" in manual,
        "manual must select the Rescue-only book from read-only synchronized mode state while preserving the ordinary book",
    )
    validation.check(
        '[3] = {"ICON_UNIT_LOTM_PP_PATH_HOLDER", "ICON_UNIT_LOTM_RP_PATH_HOLDER", "ICON_UNIT_LOTM_BE_PATH_HOLDER"}' in manual
        and '[5] = {"ICON_UNIT_LOTM_PP_PATH_HOLDER", "ICON_UNIT_LOTM_RP_PATH_HOLDER", "ICON_UNIT_LOTM_BE_PATH_HOLDER"}' in manual
        and '[9] = {"ICON_UNIT_LOTM_PP_PATH_HOLDER", "ICON_UNIT_LOTM_RP_PATH_HOLDER", "ICON_UNIT_LOTM_BE_PATH_HOLDER"}' in manual
        and '[8] = {"ICON_UNIT_LOTM_RESCUE_GOD_FOOL", "ICON_UNIT_LOTM_RESCUE_GOD_NIGHT", "ICON_UNIT_LOTM_RESCUE_GOD_STORM"}' in manual
        and 'local RESCUE_PAGE_CONCEPT_LAYOUT :table' in manual
        and '[8] = {{x=146,y=48}, {x=20,y=292}, {x=272,y=292}}' in manual
        and 'local RESCUE_PAGE_CONCEPT_ATLAS_SIZES :table' not in manual,
        "Rescue guide pages 3, 5 and 9 must use the three Pathway marks, while page 8 must show Fool, Night and Storm in a triangular layout",
    )
    validation.check(
        '{x=20,y=48}, {x=272,y=48}, {x=146,y=292}' in manual
        and 'local displaySize:number = displaySizes ~= nil and displaySizes[i] or 200;' in manual
        and 'local atlasSize:number = atlasSizes ~= nil and atlasSizes[i] or 200;' in manual,
        "manual concept icons must retain the default layout and support page-specific display and atlas sizes",
    )
    validation.check(
        '[7] = {"ICON_LOTM_CHURCH_FOOL", "ICON_LOTM_CHURCH_NIGHT", "ICON_LOTM_CHURCH_STORM"}' in manual
        and '[7] = {{x=146,y=48}, {x=20,y=292}, {x=272,y=292}}' in manual
        and 'PAGE_CONCEPT_ICONS[m_pageIndex] or CONCEPT_ICONS' in manual,
        "manual church page must place Fool above Evernight and Storm without changing other pages",
    )
    validation.check(
        '[8] = {"ICON_LOTM_CULT_DEMONESS", "ICON_LOTM_CULT_HANGED_MAN", "ICON_LOTM_CULT_CHAINED"}' in manual
        and '[8] = {{x=146,y=48}, {x=20,y=292}, {x=272,y=292}}' in manual
        and '[8] = {200, 200, 200}' in manual
        and '[8] = {200, 200, 200}' in manual
        and "ICON_BELIEF_LOTM_RP_TRUE_GOD_CHURCH" not in manual,
        "manual Evil God Church page must exactly mirror the True God one-above/two-below 200px layout",
    )
    if cult_icon_xml_path.is_file() and all(path.is_file() for path in cult_icon_paths):
        cult_icon_xml = strip_trace(cult_icon_xml_path.read_text(encoding="utf-8"))
        validation.check(
            all(
                f'IconSize="200" IconsPerRow="1" IconsPerColumn="1" Filename="{path.name}"' in cult_icon_xml
                for path in cult_icon_paths
            ),
            "all three Evil God Church emblems must register exact 200px atlases",
        )
        valid_dds = True
        for path in cult_icon_paths:
            header = path.read_bytes()[:128]
            if len(header) < 128:
                valid_dds = False
                continue
            height, width = struct.unpack_from("<II", header, 12)
            valid_dds = valid_dds and header[:4] == b"DDS " and (width, height) == (200, 200) and header[84:88] == b"DXT5"
        validation.check(
            valid_dds,
            "all three Evil God Church manual atlases must be complete 200x200 DXT5 DDS files",
        )
    validation.check(
        "HasSeenXP2FeaturesScreen" not in manual + bridge
        and "HideXP2FeaturesScreen" not in manual + bridge,
        "manual and bridge must never read or write Firaxis XP2 intro option keys",
    )
    validation.check(
        "GameConfiguration.IsAnyMultiplayer()" in manual
        and "Game.GetCurrentGameTurn() == GameConfiguration.GetStartTurn()" in manual
        and "PopupPriority.TutorialHigh" in manual,
        "manual automatic display must remain single-player, start-turn, and tutorial-priority only",
    )
    validation.check(
        "LuaEvents.InGameTopOptionsMenu_ShowExpansionIntro.Add" in manual
        and "Options.SaveOptions()" in manual
        and "Game.SetProperty" not in manual
        and "Player:SetProperty" not in manual,
        "manual must retain the Firaxis menu event and use only local Options persistence",
    )
    validation.check(
        "<LuaContext>ExpansionIntro</LuaContext>" in modinfo
        and "<LuaReplace>UI/LOTM_RP_ExpansionIntroBridge.lua</LuaReplace>" in modinfo
        and modinfo.count("<LuaContext>ExpansionIntro</LuaContext>") == 1,
        "ExpansionIntro must have exactly one bridge replacement",
    )
    validation.check(
        "TutorialUIRoot" not in modinfo
        and "GreatWorksOverview" not in modinfo
        and "GreatWorkShowcase" not in modinfo,
        "manual release must not replace tutorial-root or Firaxis Great Work contexts",
    )
    for language_path, language in ((zh_path, "zh_Hans_CN"), (en_path, "en_US")):
        if not language_path.is_file():
            continue
        text = strip_trace(language_path.read_text(encoding="utf-8"))
        validation.check(
            all(f'LOC_LOTM_MANUAL_PAGE_{page}_TITLE' in text for page in range(1, 14))
            and all(f'LOC_LOTM_MANUAL_PAGE_{page}_SUMMARY' in text for page in range(1, 14))
            and all(f'LOC_LOTM_MANUAL_PAGE_{page}_DETAILS' in text for page in range(1, 14)),
            f"{language} manual must localize all 13 titles, summaries, and detail pages",
        )
        validation.check(
            'LOC_LOTM_RESCUE_MANUAL_TITLE' in text
            and 'LOC_LOTM_RESCUE_MANUAL_HIDE' in text
            and all(f'LOC_LOTM_RESCUE_MANUAL_PAGE_{page}_TITLE' in text for page in range(1, 10))
            and all(f'LOC_LOTM_RESCUE_MANUAL_PAGE_{page}_SUMMARY' in text for page in range(1, 10))
            and all(f'LOC_LOTM_RESCUE_MANUAL_PAGE_{page}_DETAILS' in text for page in range(1, 10)),
            f"{language} manual must localize all 9 Rescue-only pages and controls",
        )
        rescue_text = "\n".join(line for line in text.splitlines() if "LOTM_RESCUE_MANUAL_" in line)
        validation.check(
            all(token in rescue_text for token in ("550", "999／888／777／666／555／444", "75", "101", "150", "225", "450", "1／2／4", "4／8／12"))
            and (("War God" in rescue_text) if language == "en_US" else ("战神遗物" in rescue_text)),
            f"{language} Rescue book must explain current dynamic god strength, schedule, Purification rewards, and final tiers",
        )
        validation.check(
            all(token in rescue_text for token in ("1000", "+30"))
            and (("strictly above 1000" in rescue_text) if language == "en_US" else ("严格大于1000" in rescue_text)),
            f"{language} Rescue player-god page must explain the live-strength mobility threshold",
        )
        validation.check(
            all(token in text for token in ("6／10／15", "10／12／15", "30%", "+30", "500"))
            and ("USER_DEFINED" not in text),
            f"{language} opening manual must explain churches, Oracle tiers, monster odds, Frenzy, and era Gold in player-facing terms",
        )
        if language == "zh_Hans_CN":
            required = (
                'LOC_LOTM_MANUAL_PAGE_8_TITLE" Language="zh_Hans_CN"><Text>邪神教会',
                "每个AI主要文明会永久归属魔女、倒吊人或被缚者教会",
                "三座邪神教会会优先齐全",
                "每座教会独立共享1／2／3阶段",
                "外交情报页面查看其所属教会、共享阶段与当前技能",
                "普通蛮族营地在所有时代采用相同的刷新强度",
            )
            forbidden = ("从2提高到9", "新营地抽取参数9", "战斗爽1：", "炼金生产”的+3劳动力")
        else:
            required = (
                'LOC_LOTM_MANUAL_PAGE_8_TITLE" Language="en_US"><Text>Evil God Churches',
                "Every AI major civilization permanently belongs to the Demoness, Hanged Man, or Chained Church",
                "all three Evil God Churches are prioritized",
                "independently shares tier 1／2／3",
                "diplomatic intelligence screen",
                "Ordinary Barbarian Camps use the same spawn intensity in every era",
            )
            forbidden = ("raised from 2 to 9", "new-camp roll parameter of 9", "Combat Thrill 1 gives", "Alchemical Production grants +3")
        validation.check(
            all(token in text for token in required),
            f"{language} opening manual must add only the current AI cult and all-era Barbarian camp rules",
        )
        validation.check(
            not any(token in text for token in forbidden),
            f"{language} opening manual must not contain implementation history or unrelated repair notes",
        )
        page7 = next((line for line in text.splitlines() if "LOC_LOTM_MANUAL_PAGE_7_DETAILS" in line), "")
        validation.check(
            ("魔女" not in page7 and "Demoness" not in page7),
            f"{language} True God Church page must not mix in Evil God Church rules",
        )


def validate_rc81_village_and_events(validation: Validation) -> None:
    goody_sql = strip_trace((ROOT / "Gameplay" / "LOTM_WORLD_GoodyHuts.sql").read_text(encoding="utf-8"))
    goody_lua = strip_trace((ROOT / "Scripts" / "LOTM_WORLD_GoodyHuts.lua").read_text(encoding="utf-8"))
    popup_lua = strip_trace((ROOT / "UI" / "LOTM_WORLD_Popup.lua").read_text(encoding="utf-8"))
    popup_xml = strip_trace((ROOT / "UI" / "LOTM_WORLD_Popup.xml").read_text(encoding="utf-8"))
    artifacts = strip_trace((ROOT / "Scripts" / "LOTM_PP_Artifacts.lua").read_text(encoding="utf-8"))
    events = strip_trace((ROOT / "Scripts" / "LOTM_WORLD_Events.lua").read_text(encoding="utf-8"))
    event_sql = strip_trace((ROOT / "Gameplay" / "LOTM_WORLD_Events.sql").read_text(encoding="utf-8"))
    validation.check(
        "UPDATE GoodyHuts SET Weight=13" in goody_sql
        and "'GOODYHUT_LOTM_WORLD_GATHERING','IMPROVEMENT_GOODY_HUT',49,0" in goody_sql,
        "tribal-village database weights must encode native 65 / gathering 35",
    )
    validation.check(
        "GameEvents.UnitTriggerGoodyHut.Add(OnUnitTriggerGoodyHut)" in goody_lua
        and "Events.GoodyHutReward.Add" not in goody_lua,
        "gathering must use the selected Firaxis subtype, never a post-reward observer",
    )
    validation.check(
        'goodyHutType~=gathering.Index then return' in goody_lua
        and 'player:AttachModifierByID(AI_NORMAL_REWARD)' in goody_lua,
        "gathering handler must accept only its subtype and keep AI on a native reward",
    )
    validation.check(
        all(token in popup_xml for token in ('ID="ItemIcon"', 'ID="Intro"', 'ID="Item"', 'ID="Question"', 'ID="Price"'))
        and 'Style="FontFlair26"' in popup_xml
        and 'IconManager:FindIconAtlas("ICON_"..tostring(item),256)' in popup_lua,
        "gathering popup must use the requested left-image/right-copy layout and 256 icon",
    )
    validation.check(
        not any(token in popup_lua for token in (":SetProperty(", "ChangeGoldBalance", "AdvanceSequence(", "AttachModifierByID"))
        and "PlayerOperations.EXECUTE_SCRIPT" in popup_lua,
        "gathering UI must remain read-only and submit an EXECUTE_SCRIPT command",
    )
    validation.check(
        "GetMaxHitPoints" not in artifacts
        and "negativeEquipped.GREATWORK_LOTM_RP_BLOOD_HARVEST_SICKLE" in artifacts
        and "maximum-1-current" in artifacts
        and "attacker:ChangeDamage(-math.min(30,damage))" in artifacts,
        "Blood Harvest Sickle must separate nonlethal negative attrition from positive kill healing",
    )
    validation.check(
        "or playerID~=fromID then return" in artifacts
        and "NumberProperty(Game,GLOBAL_OWNER_PREFIX..t)~=fromID" in artifacts,
        "artifact transfer must be initiated by the authoritative current owner",
    )
    validation.check(
        all(token in events for token in (
            'local bag={"G","G","B","B"}', "FIRST_MIN :number=12", "NEXT_MIN :number=10",
            "turn+DURATION", "prefix..tostring(target.Instance)", "NotificationManager.SendNotification",
            "NotificationTypes.USER_DEFINED_6", "NotificationTypes.USER_DEFINED_9"
        )) and "math.random" not in events,
        "rc.81 random events must use synchronized GGBB scheduling, instance state, and native notifications",
    )
    validation.check(
        all(token in event_sql for token in (
            "LOTM_WORLD_HOLDER_GOOD_STRENGTH','Amount','5",
            "LOTM_WORLD_HOLDER_GOOD_MOVE','Amount','1",
            "LOTM_WORLD_HOLDER_UNSTABLE_STRENGTH','Amount','-5",
            "LOTM_WORLD_HOLDER_UNSTABLE_MOVE','Amount','-1",
            "LOTM_ArtifactTurnLeases81", "LOTM_ArtifactModifierPolarity81"
        )),
        "rc.81 must define holder statuses and polarity-split artifact leases",
    )
    validation.check(
        all(token in event_sql for token in (
            "LOTM_WORLD_HOLDER_GOOD_STRENGTH','Preview'",
            "LOTM_WORLD_HOLDER_UNSTABLE_STRENGTH','Preview'",
        )),
        "holder status combat strength must have visible combat-preview strings",
    )
    lifecycle = strip_trace((ROOT / "Scripts" / "LOTM_RP_Lifecycle.lua").read_text(encoding="utf-8"))
    validation.check(
        "RegisterPurchasedPotion" in goody_lua
        and "RegisterPurchasedPotion" in lifecycle
        and "TryConsumePurchasedPotion" in lifecycle
        and "GATHERING_PURCHASE_AFTER_DIGESTION" in lifecycle
        and "LOTM_WORLD_PURCHASED_POTION_SEQUENCE" in goody_lua + lifecycle
        and "LOTM_WORLD_ACTIVE_POTION_PROJECTS" in goody_lua
        and "LOTM_WORLD_Command_ProductionSync" in goody_lua + popup_lua
        and 'PotionProjects=joined~="" and joined or "NONE"' in popup_lua
        and 'if raw=="NONE" or raw=="0" then raw=""; end' in goody_lua
        and "GetCurrentProductionTypeHash" not in goody_lua
        and "GetCurrentProductionTypeHash" in popup_lua
        and "UI.RequestPlayerOperation" in popup_lua
        and "stale-or-project-in-production" in goody_lua
        and "projectWasUnlocked" not in lifecycle
        and "HasProjectPrerequisites(player, rule)" in lifecycle
        and "digestionTotal<LOTM_RP_DIGESTION_TARGET" in lifecycle
        and "purchased potion pending digestion" in lifecycle
        and "for _,playerID in ipairs(PlayerManager.GetAliveMajorIDs())" in goody_lua
        and 'tonumber(player:GetProperty("LOTM_WORLD_PURCHASED_POTION_' not in lifecycle
        and "ProjectHasProgress" not in goody_lua
        and "CityOperationTypes.VALUE_REMOVE_AT" in popup_lua
        and "CityManager.RequestOperation" in popup_lua
        and lifecycle.index("TryConsumePurchasedPotion(playerID)")
            < lifecycle.index("local modifierID, flagKey = GetProjectUnlock"),
        "gathering potion must store a paid entitlement, consume it before project unlock, and reject offers while the project is in production",
    )
    validation.check(
        all(token in artifacts for token in (
            "ArtifactPolarity", 'lease76.."_POS"', 'lease76.."_NEG"',
            "positiveEquipped", "negativeEquipped", "LOTM_PP_ArtifactPositiveActive"
        )),
        "artifact scripted and database effects must both honor satisfied/uncontrolled polarity",
    )
    validation.check(
        all(token in artifacts for token in (
            "PlayerManager.GetAliveMajorIDs()", "PlayerManager.GetAliveMinorIDs()",
            'LOTM_MP_TurnSync.Add(ProcessTurn,"Artifacts")', "Reconcile(playerID,true)",
            "LOTM_RP_ART_LETTER_WAR_GOLD_STOP",
        )) and "other:IsMinor()" not in artifacts,
        "conspirator letter must recheck authoritative major/minor war state every player turn without unsupported IsMinor",
    )
    validation.check((ROOT / "Scripts" / "LOTM_WORLD_Churches.lua").exists(), "rc.83 church system must be present")


def validate_rc82_monsters(validation: Validation) -> None:
    state = strip_trace((ROOT / "Scripts" / "LOTM_WORLD_State.lua").read_text(encoding="utf-8"))
    barbarians = strip_trace((ROOT / "Scripts" / "LOTM_WORLD_Barbarians.lua").read_text(encoding="utf-8"))
    monsters = strip_trace((ROOT / "Scripts" / "LOTM_WORLD_Monsters.lua").read_text(encoding="utf-8"))
    direct_monsters = strip_trace((ROOT / "Scripts" / "LOTM_RESCUE_DirectMonsters.lua").read_text(encoding="utf-8"))
    workshops = strip_trace((ROOT / "Scripts" / "LOTM_PP_Workshops.lua").read_text(encoding="utf-8"))
    monster_sql = strip_trace((ROOT / "Gameplay" / "LOTM_WORLD_Monsters.sql").read_text(encoding="utf-8"))
    gameplay = strip_trace((ROOT / "Scripts" / "LOTM_RP_Gameplay.lua").read_text(encoding="utf-8"))
    modinfo = strip_trace((ROOT / "RedPriestPath.modinfo").read_text(encoding="utf-8"))
    zh = strip_trace((ROOT / "Text" / "zh_Hans_CN" / "LOTM_RP_GameplayText.xml").read_text(encoding="utf-8"))
    en = strip_trace((ROOT / "Text" / "en_US" / "LOTM_RP_GameplayText.xml").read_text(encoding="utf-8"))
    flag_ui = strip_trace((ROOT / "UI" / "LOTM_PP_UnitFlagManager.lua").read_text(encoding="utf-8"))
    icons = strip_trace((ROOT / "Art" / "LOTM_RP_Icons.xml").read_text(encoding="utf-8"))
    black_emperor = strip_trace((ROOT / "Scripts" / "LOTM_BE_BlackEmperor.lua").read_text(encoding="utf-8"))
    rescue_bootstrap_ui = strip_trace((ROOT / "UI" / "LOTM_RESCUE_CityBootstrap.lua").read_text(encoding="utf-8"))
    validation.check("LOTM_WORLD_State.VERSION = 6" in state, "rc.93 world-state contract must be version 6")
    validation.check(all(unit in barbarians for unit in (
        "UNIT_WARRIOR", "UNIT_SWORDSMAN", "UNIT_MAN_AT_ARMS", "UNIT_MUSKETMAN",
        "UNIT_LINE_INFANTRY", "UNIT_INFANTRY", "UNIT_MECHANIZED_INFANTRY",
    )) and "ResolveMeleeBaseline" in barbarians, "barbarian B must use the canonical generic melee chain")
    validation.check(all(token in monsters for token in (
        "local TIER_CHANCE={[2]=30,[1]=30,[0]=30}", "local TIER_BONUS={[2]=15,[1]=25,[0]=35}",
        "local TIER_MOVES={[2]=3,[1]=4,[0]=4}", "local TIER_HEAL={[2]=10,[1]=10,[0]=10}",
        "MAPSIZE_DUEL=1", "MAPSIZE_TINY=2", "MAPSIZE_SMALL=2", "MAPSIZE_STANDARD=3",
        "MAPSIZE_LARGE=4", "MAPSIZE_HUGE=5", "or 10",
    )), "monster tier values, caps, and cooldown must match rc.82")
    validation.check(all(token in monsters for token in (
        "LOTM_WORLD_MONSTER_NEXT_SERIAL", "LOTM_WORLD_WORKSHOP_MONSTER_SERIAL",
        "LOTM_WORLD_MONSTER_ENGINE:", 'MetaKey(serial,"REWARDED")', "LiveMonsters()",
    )), "monster identity, live ledger, cooldown, and reward ledger must persist")
    validation.check(all(token in workshops + monsters for token in (
        "LOTM_PP_WORKSHOP_EXTRA_SPAWN_COUNT", "LOTM_WORLD_MONSTER_ELIGIBLE_CHECKS",
        "TrySpawnFromWorkshop(camp,u)", "LOTM_WORLD_Monsters.IsMonster(u)",
        'u:GetProperty("LOTM_PP_WORKSHOP_EXTRA")', "ResolveMeleeBaseline",
    )), "only confirmed normal workshop spawns may check monsters and diagnostics")
    validation.check(all(token in monsters for token in (
        "SimulateAttackVersus", "ConservativeKillable", "LegalPath", "LOTM_RESCUE_SyncActions.MoveToward",
        "plot:GetOwner()>=0", "plot:GetDistrictType()>=0", "local function ScriptedAttack", "local function ScriptedCityAttack",
        "CombatResultParameters.DAMAGE_TO", "CombatResultParameters.DEFENSE_DAMAGE_TO", "local function EngineComponentID",
        "{player=object:GetOwner(),id=object:GetID(),type=componentType}",
        'LOTM_MP_TurnSync.Add(OnTurn,"WorldMonsters")', "UnitManager.FinishMoves(monster)",
        "combat=engineSimulationAppliedByResource221Flow",
    )) and all(token not in monsters for token in (
        "NativeAttackPlot", "NativeUnitAttack", "NativeCityAttack", "UnitManager.RequestOperation",
		"UnitManager.CanStartOperation", "UnitOperationMoveModifiers", "LOTM_RESCUE_Command_NativeAttackConstants",
        "GetAi_Military", "StartScriptedOperationWithTargetAndRally", "AddUnitToScriptedOperation", "LOTM Rescue Attack Enemy City",
	)), "resource-221 target/action flow must apply Firaxis simulated combat results without MilitaryAI operations")
    validation.check(all(token not in rescue_bootstrap_ui for token in (
        "LOTM_RESCUE_Command_NativeAttackConstants", "SubmitNativeAttackConstants", "UnitOperationMoveModifiers",
    )) and "PlayerOperations.EXECUTE_SCRIPT" in rescue_bootstrap_ui,
        "obsolete UI attack-constant relay must be absent while the Phase2 bootstrap remains synchronized")
    validation.check(all(token in monsters for token in (
        "return LOTM_RESCUE_Phase5.MonsterGlobalCap(),mapSizeType;",
        "player:IsMajor() and (not player:IsHuman() or PlayerHuntUnlocked())", '"CIVILIZATION_LEVEL_CITY_STATE"', "PlayerManager.GetAliveMinors()", "AICityTargets(monster)",
        "RescueActive() or plot:GetContinentType()==source:GetContinentType()", 'targetKind="AI_CITY"',
        "ScriptedCityAttack(monster,target.City)", "CITY_BLOCKED_UNIT_", "CityManager.DestroyCity",
        "district:SetDamage(DefenseTypes.DISTRICT_OUTER", "district:SetDamage(DefenseTypes.DISTRICT_GARRISON",
    )), "rescue monsters must restore resource-221 AI-city targeting, blocked-unit fallback, and lethal-city flow")
    validation.check(all(token in monsters for token in (
        "local function MonsterBurst()", "LOTM_RESCUE_Phase5.MonsterBurst()",
        "local function TrySpawnOne(camp,sourceUnit,periodic,networkSourceOwner,batch)", "for attempt=1,burst do",
        "local maximumRadius=RescueActive() and 3 or 2;",
    )), "rescue monster burst and radius expansion must remain runtime-isolated")
    validation.check(all(token in monsters for token in (
        "function LOTM_WORLD_Monsters.RescueTurnSpawn(worldTurn,requested)",
        "LOTM_WORLD_MONSTER_PERIODIC_LAST_TURN", "periodic worldTurn=",
        "LOTM_WORLD_MONSTER_LOCKED_TARGET_KIND", "LockedTarget(monster) or ChooseLockedTarget(monster)",
        "nearest city locked serial=", "target released serial=",
        "AITerritoryOwners()", "RedeployNearTarget(monster,destination,REDEPLOY_TARGET_MIN_DISTANCE,REDEPLOY_TARGET_MAX_DISTANCE,false,AITerritoryOwners())",
    )), "rescue monsters must retain one synchronized independently-nearest city target until it disappears")
    validation.check(all(token in direct_monsters for token in (
        "LOTM_RESCUE_DirectMonsters = LOTM_RESCUE_DirectMonsters or {}",
        "function LOTM_RESCUE_DirectMonsters.Spawn(worldTurn,requested)",
        "LOTM_RESCUE_MODE", "UnitManager.InitUnit", "LOTM_WORLD_MONSTER_ACTIVE_SERIALS",
        "LOTM_WORLD_MONSTER_SOURCE_WORKSHOP", "LOTM_WORLD_Barbarians.ResolveMeleeBaseline",
        "MIN_CITY_DISTANCE = 3", "directOutsideCity=true", "GLOBAL_CAP",
    )), "rescue direct monster stream must remain isolated from ordinary monster gameplay")
    phase5_source = strip_trace((ROOT / "Scripts" / "LOTM_RESCUE_Phase5.lua").read_text(encoding="utf-8"))
    gameplay_source = strip_trace((ROOT / "Scripts" / "LOTM_RP_Gameplay.lua").read_text(encoding="utf-8"))
    validation.check(
        'include("LOTM_RESCUE_DirectMonsters")' in gameplay_source
        and gameplay_source.index('include("LOTM_RESCUE_DirectMonsters")') < gameplay_source.index('include("LOTM_RESCUE_Phase5")')
        and 'ScaleMonsterSpawnCount(directRaw,"DIRECT",worldTurn)' in phase5_source
        and "LOTM_RESCUE_DirectMonsters.Spawn(worldTurn,directRequested)" in phase5_source
        and 'ScaleMonsterSpawnCount(workshopRaw,"PERIODIC_WORKSHOP",worldTurn)' in phase5_source
        and "LOTM_WORLD_Monsters.RescueTurnSpawn(worldTurn,workshopRequested)" in phase5_source
        and "perf worldTurn=" in phase5_source,
        "Phase 5 must apply the configured monster-rate reduction while preserving camp flow and batched timing logs",
    )
    validation.check(all(token in monsters for token in (
        "Events.UnitRemovedFromMap.Add(OnRemoved)", "GameEvents.OnCombatOccurred.Add(OnCombat)",
        "attackerSerial", "defenderSerial", "REWARD_GOLD_PER_ERA :number=500", "eraIndex+1",
        "treasury:ChangeGoldBalance(goldReward)", "questResolver",
    )), "combat settlement must handle either combat side and reserve the rc.83 resolver")
    validation.check(all(token in monsters for token in (
        'EFFECT_VERSION_PROPERTY="LOTM_WORLD_MONSTER_EFFECT_VERSION"', "CURRENT_EFFECT_VERSION=7", "RESCUE_WEATHER_ABILITY",
        "LEGACY_STRENGTH_ABILITY", "LEGACY_FRENZY_ABILITY", "LOTM_Effects.SetAbilityCount(ability,abilityType,0)",
        "unit:SetProperty(EFFECT_VERSION_PROPERTY,CURRENT_EFFECT_VERSION)", "rebuilt effects serial=",
        "for _,monster in ipairs(LiveMonsters()) do ReconcileMonsterAbilities(monster); end",
    )), "saved monsters must detach stale modifier instances and concentrated targets before rebuilding +15 Frenzy")
    validation.check(all(token in monster_sql for token in (
        "ABILITY_LOTM_WORLD_DYNAMIC_STRENGTH", "ABILITY_LOTM_WORLD_MONSTER_FRENZY_STRENGTH",
        "ABILITY_LOTM_WORLD_MONSTER_FRENZY_STRENGTH_V2", "LOTM_WORLD_MONSTER_FRENZY_STRENGTH_V2_MOD",
        "('LOTM_WORLD_MONSTER_FRENZY_STRENGTH_V2_MOD','Amount','15')",
        "('LOTM_WORLD_MONSTER_TIER_MID_STRENGTH_MOD','Amount','10')",
        "('LOTM_WORLD_MONSTER_TIER_HIGH_STRENGTH_MOD','Amount','20')",
        "ABILITY_LOTM_WORLD_DYNAMIC_MOVEMENT", "ABILITY_LOTM_WORLD_DYNAMIC_MOVEMENT_2",
        "LOC_LOTM_WORLD_PREVIEW_MONSTER_FRENZY", "('LOTM_WORLD_DYNAMIC_MOVEMENT_2_MOD','Amount','2')",
        "MODIFIER_UNIT_ADJUST_COMBAT_STRENGTH", "MODIFIER_PLAYER_UNIT_ADJUST_MOVEMENT",
        "('LOTM_WORLD_MONSTER_FRENZY_STRENGTH_MOD','Amount','15')", "'CLASS_RECON'", "'CLASS_MELEE'",
    )), "guard and monster instance abilities must support exact B targets")
    validation.check(
        gameplay.index('include("LOTM_WORLD_Barbarians")') < gameplay.index('include("LOTM_WORLD_Monsters")') < gameplay.index('include("LOTM_PP_Workshops")'),
        "baseline and monster modules must load before workshops",
    )
    validation.check(all(path in modinfo for path in (
        "Gameplay/LOTM_WORLD_Monsters.sql", "Scripts/LOTM_WORLD_Barbarians.lua", "Scripts/LOTM_WORLD_Monsters.lua",
    )), "modinfo must register every rc.82 file")
    validation.check(all(tag in zh and tag in en for tag in (
        "LOC_LOTM_WORLD_MONSTER_LOW_NAME", "LOC_LOTM_WORLD_MONSTER_MID_NAME", "LOC_LOTM_WORLD_MONSTER_HIGH_NAME",
        "LOC_ABILITY_LOTM_WORLD_DYNAMIC_STRENGTH_NAME", "LOC_ABILITY_LOTM_WORLD_MONSTER_FRENZY_STRENGTH_NAME",
        "LOC_LOTM_WORLD_PREVIEW_MONSTER_FRENZY", "LOC_ABILITY_LOTM_WORLD_DYNAMIC_MOVEMENT_NAME",
    )), "monster and ability text must be bilingual")
    validation.check(all(token in flag_ui for token in (
        "LOTM_WORLD_MONSTER_TIER", "LOTM_WORLD_MONSTER_SERIAL", "MONSTER_BASE",
        "MONSTER_MARK", 'SetIcon("ICON_LOTM_WORLD_MONSTER_MARK")',
        "ApplyMonsterColor", "ApplyPathColor", "WorkshopPath", "PATH_MARKS",
        "RefreshSpecialFlag", "Events.UnitAbilityGained.Add", "Events.UnitSelectionChanged.Add",
        "Events.UnitVisibilityChanged.Add", "Exact Firaxis fallback",
    )) and flag_ui.index("if IsMonster(unit)") < flag_ui.index("if IsWorkshopSequence(unit)")
        and "tonumber(unit:GetProperty" not in flag_ui and "PATH_HOLDER_TYPES" not in flag_ui,
        "monster and workshop flags must refresh without recoloring player pathway holders")
    validation.check(all(token in icons + modinfo for token in (
        "ICON_ATLAS_LOTM_WORLD_MONSTER_MARK", "ICON_LOTM_WORLD_MONSTER_MARK",
        "LOTM_WORLD_MonsterMark40.dds", "LOTM_WORLD_MonsterMark256.dds",
    )), "monster mark atlas and DDS assets must be registered")
    validation.check(
        "GetCurrentProductionTypeHash" not in black_emperor
        and "LOTM_BE_TRANSFORMATION_ACTIVE_SYNC" in black_emperor,
        "Black Emperor gameplay must consume the synchronized production snapshot")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--game-root",
        type=Path,
        help="Optional Civilization VI installation root for original-file reference checks.",
    )
    args = parser.parse_args()

    validation = Validation()
    validate_structure(validation)
    validate_release_hygiene(validation)
    parsed = parse_xml_files(validation)
    if MODINFO in parsed:
        validate_modinfo(validation, parsed[MODINFO])
    else:
        validation.check(False, "modinfo could not be parsed")

    required_parsed = [
        ROOT / "Config" / "LOTM_RP_PathSelection.xml",
        ROOT / "Gameplay" / "LOTM_RP_Types.xml",
        ROOT / "Gameplay" / "LOTM_RP_Promotions.xml",
        ROOT / "Gameplay" / "LOTM_RP_Beliefs.xml",
        ROOT / "Gameplay" / "LOTM_RP_Units.xml",
        ROOT / "Gameplay" / "LOTM_RP_Modifiers.xml",
        ROOT / "Gameplay" / "LOTM_RP_Projects.xml",
        ROOT / "Gameplay" / "LOTM_RP_Abilities.xml",
        ROOT / "Art" / "LOTM_RP_Icons.xml",
    ]
    if all(path in parsed for path in required_parsed):
        validate_types(validation, parsed)
        validate_config(validation, parsed[required_parsed[0]])
        validate_promotions(validation, parsed[required_parsed[2]])
        validate_beliefs(validation, parsed[required_parsed[3]])
        validate_unit(validation, parsed[required_parsed[4]], parsed[required_parsed[1]])
        validate_modifiers(validation, parsed[required_parsed[5]])
        validate_projects_and_abilities(
            validation,
            parsed[required_parsed[6]],
            parsed[required_parsed[7]],
        )
        validate_icons_and_art(validation, parsed)
        validate_localization(validation, parsed)
        validate_selected_language_packs(validation, parsed)
        validate_probe(validation)
        validate_lifecycle(validation)
        validate_path_choice(validation)
        validate_progression(validation)
        validate_arson_and_hud(validation)
        validate_sequence_zero_ceremony(validation)
        validate_comic_viewer(validation)
        validate_advanced_sequences(validation)
        validate_sync_boundaries(validation)
        validate_workshop_artifacts(validation)
        validate_gameplay_manual(validation)
        validate_rc81_village_and_events(validation)
        validate_rc82_monsters(validation)
        validate_database(
            validation,
            parsed[required_parsed[1]],
            parsed[required_parsed[4]],
            parsed[required_parsed[5]],
            parsed[required_parsed[6]],
            parsed[required_parsed[7]],
        )
    else:
        validation.check(False, "one or more required XML inputs did not parse")

    if args.game_root:
        validate_game_references(validation, args.game_root.resolve())

    if validation.failures:
        print(f"FAILED: {len(validation.failures)} of {validation.checks} checks failed")
        for failure in validation.failures:
            print(f" - {failure}")
        return 1

    reference_note = " + original-game references" if args.game_root else ""
    print(f"PASS: {validation.checks} static checks{reference_note}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
