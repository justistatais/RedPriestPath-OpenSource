#!/usr/bin/env python3
"""Validate source-derived bundles and the preserved rc.241 city baseline."""

from __future__ import annotations

import hashlib
import re
import subprocess
import sys
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path
sys.dont_write_bytecode = True

from luaparser import ast as lua_ast
from generate_gameplay_bundle import (
    NETWORK_CURRENT_OVERRIDES, NETWORK_NEW_MODULES, NETWORK_RULE_FUNCTION_OVERRIDES,
    collect_network_modules, generate_current, lua_function_span, network_phase_source,
    read_network_justice_events_source,
    read_network_source, read_rc241_source, read_source,
)
from generate_startup_trace import helper_source, strip_trace


ROOT = Path(__file__).resolve().parents[1]
MODINFO = ROOT / "RedPriestPath.modinfo"
BUNDLE = ROOT / "Scripts" / "LOTM_RP_Gameplay_Bundle.lua"
NETWORK_BUNDLE = ROOT / "Scripts" / "LOTM_MP241_MainBundle.lua"
RC241 = ROOT.parent / "dist" / "RedPriestPath-0.1.0-rc.241.zip"
RC241_SHA256 = "62CF9EA6305BE06BFE19A0C57518249316019359DAC74830D77EC877A798FB61"
PHASE_ACTIONS = {
    "LOTM_RESCUE_PHASE1_GAMEPLAY_ADDIN": ("LOTM_RESCUE_Phase1", "Scripts/LOTM_MP241_Phase1.lua"),
    "LOTM_RESCUE_PHASE2A_GAMEPLAY_ADDIN": ("LOTM_RESCUE_Phase2Test", "Scripts/LOTM_MP241_Phase2.lua"),
    "LOTM_RESCUE_PHASE3_GAMEPLAY_ADDIN": ("LOTM_RESCUE_Phase3", "Scripts/LOTM_MP241_Phase3.lua"),
}
DELTA_MODULES = {
    "LOTM_WORLD_Barbarians",
    "LOTM_UnitAddedPerf", "LOTM_RP_Lifecycle", "LOTM_RESCUE_SyncActions",
    "LOTM_RESCUE_Difficulty", "LOTM_RESCUE_Phase5", "LOTM_RESCUE_Phase10",
    "LOTM_WORLD_Monsters", "LOTM_WORLD_GoodyHuts", "LOTM_PP_Workshops",
}
NEW_MODULES = {
    "LOTM_RESCUE_RuntimeEvents",
    "LOTM_Effects",
    "LOTM_MP241_Compat", "LOTM_RESCUE_DirectMonsters",
    "LOTM_RESCUE_Thief", "LOTM_TP_Thief", "LOTM_JUSTICE_Governor", "LOTM_RESCUE_StarGovernor", "LOTM_GodBlessings",
}
RULE_FUNCTIONS = {
    "LOTM_RP_Progression": {"OnCityProjectCompleted": "ApplyCityProjectCompleted"},
    "LOTM_RP_Advanced": {"OnCityProjectCompleted": "ApplyCityProjectCompleted"},
    "LOTM_PP_Perfect": {"GrantNextRelic": "GrantNextRelic"},
}


def check(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def parse_lua(path: Path) -> None:
    source = path.read_text(encoding="utf-8")
    parseable = re.sub(r"\s+:(?:boolean|number|string|table)\b", "", source)
    try:
        lua_ast.parse(parseable)
    except Exception as exc:
        raise AssertionError(f"invalid Lua: {path}: {exc}") from exc


def validate_network_rule_sources() -> None:
    """Explicitly bound current rule fixes inside the preserved old modules."""
    check(NETWORK_RULE_FUNCTION_OVERRIDES == RULE_FUNCTIONS,
          "network rule-function allowlist changed without matching review gate")
    check(not (set(RULE_FUNCTIONS) & set(NETWORK_CURRENT_OVERRIDES)),
          "a narrowly patched rule module was replaced wholesale")
    for module in collect_network_modules():
        if module in NETWORK_CURRENT_OVERRIDES or module in NETWORK_NEW_MODULES:
            continue
        old, routed = read_rc241_source(module), read_network_source(module)
        if module == "LOTM_WORLD_Events":
            check(routed == read_network_justice_events_source(),
                  "shared Counseling delta differs from guarded rc.241 patch")
            continue
        if module == "LOTM_AI_Cult_Hanged":
            expected = ("if not LOTM_MP_TurnSync.IsRescueModeConfigured() then\n"
                        + read_source(module) + "\nelse\n" + old + "\nend\n")
            check(routed == expected, "normal Hanged lifecycle delta must preserve the exact rc.241 rescue branch")
            continue
        if module == "LOTM_RP_Advanced":
            routed = routed.replace(
                'local LOTM_RP_PLAN_FIRST_WAR_GOLD :number = LOTM_MP_TurnSync.IsRescueModeConfigured() and 2000 or 1000;',
                'local LOTM_RP_PLAN_FIRST_WAR_GOLD :number = 2000;')
        if module not in RULE_FUNCTIONS:
            check(routed == old, f"undeclared current changes in rc.241 module: {module}")
            continue
        current = read_source(module)
        restore = []
        for target, source in RULE_FUNCTIONS[module].items():
            old_start, old_end = lua_function_span(old, target)
            start, end = lua_function_span(routed, target)
            current_start, current_end = lua_function_span(current, source)
            expected = current[current_start:current_end]
            if target != source:
                expected = re.sub(r"\A(local\s+function\s+)" + re.escape(source) + r"\b",
                                  lambda match: match.group(1) + target, expected, count=1)
            check(routed[start:end] == expected,
                  f"network rule differs from current function: {module}.{target}")
            restore.append((start, end, old[old_start:old_end]))
        for start, end, original_function in sorted(restore, reverse=True):
            routed = routed[:start] + original_function + routed[end:]
        check(routed == old, f"non-allowlisted bytes changed in rc.241 module: {module}")


def main() -> int:
    freshness = subprocess.run(
        [sys.executable, str(ROOT / "Tests" / "generate_gameplay_bundle.py"), "--check"],
        cwd=ROOT,
        check=False,
    )
    check(freshness.returncode == 0, "generated Gameplay artifacts are stale")
    check(RC241.is_file(), "published rc.241 archive is missing")
    check(hashlib.sha256(RC241.read_bytes()).hexdigest().upper() == RC241_SHA256,
          "published rc.241 archive hash changed")
    validate_network_rule_sources()

    root = ET.parse(MODINFO).getroot()
    main_action = root.find("./InGameActions/AddGameplayScripts[@id='LOTM_RP_GAMEPLAY_ADDIN']")
    check(main_action is not None, "main Gameplay action is missing")
    check([n.text.strip() for n in main_action.findall("./File") if n.text]
          == ["Scripts/LOTM_RP_Gameplay_Bundle.lua"],
          "main Gameplay action must load only the dual router")
    for action_id, (_, expected_file) in PHASE_ACTIONS.items():
        action = root.find(f"./InGameActions/AddGameplayScripts[@id='{action_id}']")
        check(action is not None and action.get("criteria") == "LOTM_RP_RESCUE_MODE",
              f"rc.241 standalone action missing or not rescue-gated: {action_id}")
        check([n.text.strip() for n in action.findall("./File") if n.text] == [expected_file],
              f"wrong runtime file for {action_id}")

    packaged = {n.text.strip() for n in root.findall("./Files/File") if n.text}
    required_files = [
        "Scripts/LOTM_RP_Gameplay_Bundle.lua",
        "Scripts/LOTM_MP241_Compat.lua",
        "Scripts/LOTM_MP241_PreMainBootstrap.lua",
        "Scripts/LOTM_MP241_MainBundle.lua",
    ]
    required_files.extend(value[1] for value in PHASE_ACTIONS.values())
    for relative in required_files:
        check(relative in packaged, f"runtime file is not packaged: {relative}")

    bundle = BUNDLE.read_text(encoding="utf-8")
    network_bundle = NETWORK_BUNDLE.read_text(encoding="utf-8")
    check("[LOTM][BundleRouter] route=NETWORK_RC241_PLUS_DELTAS" in network_bundle,
          "rc.241 multiplayer route sentinel is missing from the post-bootstrap action")
    check("network rescue main deferred until published rc.241 UI bootstrap" in bundle
          and "phase2BeforeMain=" in network_bundle,
          "post-rc.241 main context is not deferred until the rc.241 city chain completes")
    check("[LOTM][BundleRouter] route=CURRENT_SINGLE_PLAYER" in bundle,
          "single-player route sentinel is missing")
    check("NETWORK_LEGACY_RESOURCE290" not in network_bundle and "Phase2Audit" not in network_bundle,
          "rejected resource-290/audit implementation remains in the runtime bundle")
    check("unifiedDispatcher=false" in network_bundle,
          "multiplayer delta layer does not attest the direct-event rc.241 boundary")
    check("LOTM_MP_TurnSync.VERSION = 241" in network_bundle,
          "rc.241-style compatibility adapter is missing")
    for module in DELTA_MODULES:
        check(f"-- BEGIN POST_RC241_DELTA MODULE: Scripts/{module}.lua" in network_bundle,
              f"post-rc.241 delta provenance is missing: {module}")
    for module in NEW_MODULES:
        check(f"-- BEGIN POST_RC241_NEW MODULE: Scripts/{module}.lua" in network_bundle,
              f"post-rc.241 new-module provenance is missing: {module}")
    for module in RULE_FUNCTIONS:
        check(f"-- BEGIN POST_RC241_RULES MODULE: Scripts/{module}.lua" in network_bundle,
              f"post-rc.241 function-level rule provenance is missing: {module}")
    check("-- BEGIN RC241 MODULE: Scripts/LOTM_RP_Gameplay.lua" in network_bundle,
          "published rc.241 main entry is not the multiplayer base")

    single_marker = '\tprint("[LOTM][BundleRouter] route=CURRENT_SINGLE_PLAYER");\n'
    single_start = bundle.index(single_marker) + len(single_marker)
    single_end = bundle.rfind("\nend\n")
    single = bundle[single_start:single_end] + "\n"
    check(single == generate_current(),
          "single-player branch does not match current source modules")
    for runtime in (single, network_bundle):
        check('LOTM_Effects.SetAbilityCount' in runtime
              and 'LOTM_Effects.PercentFloor' in runtime,
              "shared effect layer is missing from a runtime branch")
    check('GameInfo.Resources["RESOURCE_LOTM_RESCUE_ALLY_BANNER"]' in bundle.replace(helper_source(), "")[:2500]
          and 'm_configured == true or tonumber(m_configured) == 1' in bundle.replace(helper_source(), "")[:2500],
          "outer router must recognize rescue database markers and boolean lobby values")

    with zipfile.ZipFile(RC241) as archive:
        for _, (module, relative) in PHASE_ACTIONS.items():
            source = archive.read(f"RedPriestPath/Scripts/{module}.lua").decode("utf-8").replace("\r\n", "\n").rstrip("\n")
            routed = (ROOT / relative).read_text(encoding="utf-8")
            expected_phase = network_phase_source(module)
            check(expected_phase in routed, f"standalone context differs from the audited rc.241 phase: {module}")
            if module == "LOTM_RESCUE_Phase2Test":
                check('GameEvents.PlayerTurnStarted.Add(OnSynchronizedTurnStart)' not in routed
                      and 'bootstrap policy=COMMAND_ONLY resource=373' in routed
                      and 'GameEvents.LOTM_RESCUE_Command_BootstrapCity.Add(OnBootstrapCity)' in routed,
                      "network cities must be created only by the post-load synchronized operation")
                for forbidden in (
                    "LOTM_RESCUE_PHASE2A_MP241_DEVELOPMENT_BYPASS",
                    "medieval-development bypassed networkCompat=rc241",
                    "network-stage BEGIN",
                    "submission=staged-same-world-turn",
                ):
                    check(forbidden not in routed,
                          f"published rc.241 Phase 2 was modified: {forbidden}")
            check("GameConfiguration.IsAnyMultiplayer" in routed,
                  f"standalone context is not network-only: {module}")

    bootstrap = (ROOT / "Scripts" / "LOTM_MP241_PreMainBootstrap.lua").read_text(encoding="utf-8")
    check('include("LOTM_MP241_MainBundle")' in bootstrap
          and "GameEvents.LOTM_MP241_Command_LoadMain.Add" in bootstrap
          and "GameEvents.LOTM_RESCUE_Command_BootstrapCity.Add" not in bootstrap
          and "LOTM_RESCUE_Command_BootstrapCity.Call" not in bootstrap,
          "post-bootstrap bridge must load deltas through a separate synchronized operation")
    bridge_action = root.find("./InGameActions/AddGameplayScripts[@id='LOTM_MP241_PRE_MAIN_BOOTSTRAP']")
    check(bridge_action is not None
          and bridge_action.get("criteria") == "LOTM_RP_RESCUE_MODE"
          and bridge_action.findtext("./Properties/LoadOrder") == "208"
          and [n.text.strip() for n in bridge_action.findall("./File") if n.text]
              == ["Scripts/LOTM_MP241_PreMainBootstrap.lua"],
          "pre-main rc.241 bootstrap action is missing or ordered incorrectly")
    network_action = root.find("./InGameActions/ImportFiles[@id='LOTM_MP241_MAIN_AFTER_BOOTSTRAP']")
    check(network_action is not None
          and network_action.get("criteria") == "LOTM_RP_RESCUE_MODE"
          and network_action.findtext("./Properties/LoadOrder") == "203"
          and [n.text.strip() for n in network_action.findall("./File") if n.text]
              == ["Scripts/LOTM_MP241_MainBundle.lua"],
          "network main bundle is not imported for post-bootstrap loading")
    helper_action = root.find("./InGameActions/ImportFiles[@id='LOTM_MP241_PHASE3_HELPER']")
    check(helper_action is not None and helper_action.get("criteria") == "LOTM_RP_RESCUE_MODE"
          and helper_action.findtext("./Properties/LoadOrder") == "203"
          and helper_action.findtext("./File") == "Scripts/LOTM_RESCUE_SyncActions.lua",
          "standalone Phase 3 helper must be imported before its independent context")
    expected_orders = {
        "LOTM_RP_GAMEPLAY_ADDIN": "204",
        "LOTM_RESCUE_PHASE1_GAMEPLAY_ADDIN": "205",
        "LOTM_RESCUE_PHASE2A_GAMEPLAY_ADDIN": "206",
        "LOTM_RESCUE_PHASE3_GAMEPLAY_ADDIN": "207",
    }
    for action_id, expected_order in expected_orders.items():
        action = root.find(f"./InGameActions/AddGameplayScripts[@id='{action_id}']")
        check(action is not None and action.findtext("./Properties/LoadOrder") == expected_order,
              f"wrong pre-main load order for {action_id}")

    current_ui = (ROOT / "UI" / "LOTM_RESCUE_CityBootstrap.lua").read_text(encoding="utf-8").replace("\r\n", "\n")
    check('LOTM_RESCUE_Command_BootstrapCity' in current_ui
          and 'LOTM_MP241_Command_LoadMain' in current_ui
          and 'PlayerOperations.EXECUTE_SCRIPT' in current_ui
          and ':SetProperty(' not in current_ui and 'Game.SetProperty(' not in current_ui,
          "UI must retain the city command and request delta loading without authoritative writes")

    for path in [BUNDLE, NETWORK_BUNDLE, ROOT / "Scripts" / "LOTM_MP241_PreMainBootstrap.lua"] \
            + [ROOT / value[1] for value in PHASE_ACTIONS.values()]:
        parse_lua(path)
    print("PASS: rc.241 city baseline, synchronized post-241 deltas, and source-derived effect bundles")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
