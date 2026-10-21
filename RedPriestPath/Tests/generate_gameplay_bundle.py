#!/usr/bin/env python3
"""Generate the self-contained authoritative Gameplay entrypoint.

Civ VI can register an AddGameplayScripts component while omitting a separate
ImportFiles component from the active runtime component list.  The generated
entrypoint embeds every project-local include target as a lazy module loader,
so Gameplay startup no longer depends on cross-action VFS timing.
"""

from __future__ import annotations

import argparse
import hashlib
import re
import zipfile
from functools import lru_cache
from pathlib import Path
from generate_startup_trace import diagnostics_enabled, helper_source, header as trace_header, statements as trace_statements


ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "Scripts"
ENTRY_MODULE = "LOTM_RP_Gameplay"
OUTPUT = SCRIPTS / "LOTM_RP_Gameplay_Bundle.lua"
NETWORK_OUTPUT = SCRIPTS / "LOTM_MP241_MainBundle.lua"
RC241_ARCHIVE = ROOT.parent / "dist" / "RedPriestPath-0.1.0-rc.241.zip"
RC241_ARCHIVE_SHA256 = "62CF9EA6305BE06BFE19A0C57518249316019359DAC74830D77EC877A798FB61"
RC241_PREFIX = "RedPriestPath/Scripts/"
NETWORK_PHASE_OUTPUTS = {
    "LOTM_RESCUE_Phase1": SCRIPTS / "LOTM_MP241_Phase1.lua",
    "LOTM_RESCUE_Phase2Test": SCRIPTS / "LOTM_MP241_Phase2.lua",
    "LOTM_RESCUE_Phase3": SCRIPTS / "LOTM_MP241_Phase3.lua",
}
BUNDLE_VERSION = 1
INCLUDE_PATTERN = re.compile(
    r"\binclude\s*\(\s*([\"'])(LOTM_[A-Za-z0-9_]+)(?:\.lua)?\1\s*\)"
)

COMMON_REQUIRED = (
    "LOTM_Effects",
    "LOTM_UnitAddedPerf",
    "LOTM_RP_Lifecycle",
    "LOTM_RP_Progression",
    "LOTM_PP_Perfect",
    "LOTM_BE_BlackEmperor",
    "LOTM_WORLD_State",
    "LOTM_WORLD_Barbarians",
    "LOTM_RESCUE_SyncActions",
    "LOTM_RESCUE_Difficulty",
    "LOTM_RESCUE_Phase5",
    "LOTM_RESCUE_Phase6",
    "LOTM_AI_Cults",
    "LOTM_AI_Cult_Hanged",
    "LOTM_RESCUE_Phase7",
    "LOTM_RESCUE_Phase8",
    "LOTM_RESCUE_Phase9",
    "LOTM_RESCUE_Phase9Digestion",
    "LOTM_RESCUE_Phase10A",
    "LOTM_RESCUE_Phase10",
    "LOTM_WORLD_Monsters",
    "LOTM_WORLD_Events",
    "LOTM_PP_Artifacts",
    "LOTM_RESCUE_Artifacts",
    "LOTM_WORLD_GoodyHuts",
    "LOTM_PP_Workshops",
    "LOTM_WORLD_Churches",
    "LOTM_RP_Arson",
    "LOTM_RP_Advanced",
    "LOTM_RP_CommandProbe",
    "LOTM_DEV_QuickTest",
)
RESCUE_REQUIRED = (
    "LOTM_RESCUE_Phase1",
    "LOTM_RESCUE_Phase2Test",
    "LOTM_RESCUE_Phase3",
    "LOTM_RESCUE_DirectMonsters",
    "LOTM_RESCUE_Thief",
    "LOTM_JUSTICE_Governor",
    "LOTM_MS_Governors",
    "LOTM_RESCUE_StarGovernor",
    "LOTM_GodBlessings",
)
NORMAL_REQUIRED = ("LOTM_TP_Thief", "LOTM_JUSTICE_Governor", "LOTM_MS_Governors", "LOTM_AI_Cult_Difficulty", "LOTM_GodBlessings")

# The old Multiplayer implementation is sourced from the published rc.241
# archive.  Existing rc.241 modules stay on that source unless a later feature
# genuinely needs an amended module.  These overrides are the narrow runtime
# surface required by post-rc.241 Thief, direct-monster, spawn-rate,
# redeployment, performance and player-god-respawn features.
NETWORK_CURRENT_OVERRIDES = {
    # Resource 380: guarded rescue cleanup v2 and bounded new-camp filtering.
    "LOTM_WORLD_Barbarians",
    "LOTM_UnitAddedPerf",
    "LOTM_RP_Lifecycle",
    "LOTM_RESCUE_SyncActions",
    "LOTM_RESCUE_Difficulty",
    "LOTM_RESCUE_Phase5",
    "LOTM_RESCUE_Phase10",
    "LOTM_WORLD_Monsters",
    "LOTM_WORLD_GoodyHuts",
    "LOTM_PP_Workshops",
}
# Only these audited rule functions may use current source inside an otherwise
# byte-preserved rc.241 module. rc.241 registered project handlers directly;
# today's Apply function supplies the same rule body without importing the
# later event queues or changing the old registration/startup lifecycle.
# Mapping: rc.241 target function -> current source function.
NETWORK_RULE_FUNCTION_OVERRIDES = {
    "LOTM_RP_Progression": {"OnCityProjectCompleted": "ApplyCityProjectCompleted"},
    "LOTM_RP_Advanced": {"OnCityProjectCompleted": "ApplyCityProjectCompleted"},
    "LOTM_PP_Perfect": {"GrantNextRelic": "GrantNextRelic"},
}
NETWORK_NEW_MODULES = (
    "LOTM_Effects",
    "LOTM_MP241_Compat",
    "LOTM_RESCUE_RuntimeEvents",
    "LOTM_RESCUE_DirectMonsters",
    "LOTM_RESCUE_Thief",
    "LOTM_TP_Thief",
    "LOTM_JUSTICE_Governor",
    "LOTM_MS_Governors",
    "LOTM_RESCUE_StarGovernor",
    "LOTM_GodBlessings",
    "LOTM_AI_Cult_Difficulty",
)


def source_path(module_name: str) -> Path:
    return SCRIPTS / f"{module_name}.lua"


def read_source(module_name: str) -> str:
    path = source_path(module_name)
    if not path.is_file():
        raise SystemExit(f"Missing bundled Gameplay module: {path}")
    return path.read_text(encoding="utf-8").replace("\r\n", "\n")


@lru_cache(maxsize=1)
def validate_rc241_archive() -> None:
    if not RC241_ARCHIVE.is_file():
        raise SystemExit(f"Missing published rc.241 archive: {RC241_ARCHIVE}")
    digest = hashlib.sha256(RC241_ARCHIVE.read_bytes()).hexdigest().upper()
    if digest != RC241_ARCHIVE_SHA256:
        raise SystemExit(
            f"Published rc.241 archive hash changed: expected {RC241_ARCHIVE_SHA256}, got {digest}"
        )


@lru_cache(maxsize=None)
def read_rc241_source(module_name: str) -> str:
    validate_rc241_archive()
    member = f"{RC241_PREFIX}{module_name}.lua"
    try:
        with zipfile.ZipFile(RC241_ARCHIVE) as archive:
            return archive.read(member).decode("utf-8").replace("\r\n", "\n")
    except KeyError as exc:
        raise SystemExit(f"rc.241 archive is missing Gameplay module: {member}") from exc


@lru_cache(maxsize=64)
def _lua_function_ranges(source: str) -> dict[str, tuple[tuple[int, int], ...]]:
    """Read exact source ranges through the Lua parser, including nested ends."""
    from antlr4 import InputStream, CommonTokenStream
    from luaparser.parser.LuaLexer import LuaLexer
    from luaparser.parser.LuaParser import LuaParser

    parseable = re.sub(r"\s*:\s*(?:boolean|number|string|table)\b",
                       lambda match: " " * len(match.group()), source)
    parser = LuaParser(CommonTokenStream(LuaLexer(InputStream(parseable))))
    tree = parser.start_()
    if parser.getNumberOfSyntaxErrors():
        raise ValueError("Cannot locate rule functions in invalid Lua")
    found: dict[str, list[tuple[int, int]]] = {}

    def walk(node):
        if type(node).__name__ in ("Stat_localfunctionContext", "Stat_functionContext"):
            start, end = node.start.start, node.stop.stop + 1
            match = re.match(r"(?:local\s+)?function\s+([\w.:]+)", source[start:end])
            if match:
                found.setdefault(match.group(1), []).append((start, end))
        for child in getattr(node, "children", ()) or ():
            walk(child)

    walk(tree)
    return {name: tuple(ranges) for name, ranges in found.items()}


def lua_function_span(source: str, name: str) -> tuple[int, int]:
    ranges = _lua_function_ranges(source).get(name, ())
    if len(ranges) != 1:
        raise ValueError(f"Expected one Lua function {name}, found {len(ranges)}")
    return ranges[0]


def read_network_rule_source(module_name: str) -> str:
    base = read_rc241_source(module_name)
    current = read_source(module_name)
    edits = []
    for target_name, source_name in NETWORK_RULE_FUNCTION_OVERRIDES[module_name].items():
        start, end = lua_function_span(base, target_name)
        source_start, source_end = lua_function_span(current, source_name)
        replacement = current[source_start:source_end]
        if target_name != source_name:
            replacement, count = re.subn(
                r"\A(local\s+function\s+)" + re.escape(source_name) + r"\b",
                lambda match: match.group(1) + target_name, replacement, count=1,
            )
            if count != 1:
                raise ValueError(f"Rule function is not a local declaration: {module_name}.{source_name}")
        edits.append((start, end, replacement))
    # Keep every byte outside the declared function spans, including original
    # comments, variable scopes, event registrations and module initialization.
    for start, end, replacement in sorted(edits, reverse=True):
        base = base[:start] + replacement + base[end:]
    return base


def read_network_justice_events_source() -> str:
    """Add only normal-mode Counseling checks to the frozen event source."""
    source = read_rc241_source("LOTM_WORLD_Events")
    replacements = (
        (
            '\tlocal badWanted=turn<LOTM_WORLD_State.NumberProperty(player,"LOTM_HOLDER_UNSTABLE_STATE_UNTIL",-1);\n',
            '\tlocal badWanted=turn<LOTM_WORLD_State.NumberProperty(player,"LOTM_HOLDER_UNSTABLE_STATE_UNTIL",-1);\n'
            '\tif LOTM_JUSTICE~=nil and LOTM_JUSTICE.IsCounselingActive~=nil\n'
            '\t\tand LOTM_JUSTICE.IsCounselingActive(player:GetID()) then badWanted=false; end\n',
        ),
        (
            '\tif kind==nil or NOTIFICATION_TYPES[tostring(player:GetProperty("LOTM_RP_PATH") or "")] == nil then return; end\n',
            '\tif kind==nil or (kind~="HOLDER_COUNSELED"\n'
            '\t\tand NOTIFICATION_TYPES[tostring(player:GetProperty("LOTM_RP_PATH") or "")] == nil) then return; end\n',
        ),
        (
            '\t\tlocal key=nature=="G" and "LOTM_HOLDER_GOOD_STATE_UNTIL" or "LOTM_HOLDER_UNSTABLE_STATE_UNTIL";\n'
            '\t\tplayer:SetProperty(key,turn+DURATION);\n'
            '\t\tkind=nature=="G" and "HOLDER_GOOD" or "HOLDER_UNSTABLE";\n',
            '\t\tlocal counseled=nature=="B" and LOTM_JUSTICE~=nil\n'
            '\t\t\tand LOTM_JUSTICE.IsCounselingActive~=nil\n'
            '\t\t\tand LOTM_JUSTICE.IsCounselingActive(player:GetID());\n'
            '\t\tif counseled then\n'
            '\t\t\tkind="HOLDER_COUNSELED";\n'
            '\t\telse\n'
            '\t\t\tlocal key=nature=="G" and "LOTM_HOLDER_GOOD_STATE_UNTIL" or "LOTM_HOLDER_UNSTABLE_STATE_UNTIL";\n'
            '\t\t\tplayer:SetProperty(key,turn+DURATION);\n'
            '\t\t\tkind=nature=="G" and "HOLDER_GOOD" or "HOLDER_UNSTABLE";\n'
            '\t\tend\n',
        ),
    )
    for old, new in replacements:
        if source.count(old) != 1:
            raise ValueError("rc.241 World Events Counseling patch anchor changed")
        source = source.replace(old, new, 1)
    return source


def read_network_source(module_name: str) -> str:
    if module_name == "LOTM_AI_Cult_Hanged":
        # Keep the sealed rescue branch byte-for-byte, with the repaired
        # unit lifecycle confined to normal games.
        return ("if not LOTM_MP_TurnSync.IsRescueModeConfigured() then\n"
                + read_source(module_name) + "\nelse\n"
                + read_rc241_source(module_name) + "\nend\n")
    if module_name == "LOTM_RP_Advanced":
        source = read_network_rule_source(module_name)
        old = 'local LOTM_RP_PLAN_FIRST_WAR_GOLD :number = 2000;'
        new = ('local LOTM_RP_PLAN_FIRST_WAR_GOLD :number = '
               'LOTM_MP_TurnSync.IsRescueModeConfigured() and 2000 or 1000;')
        assert source.count(old) == 1
        return source.replace(old, new)
    if module_name in NETWORK_NEW_MODULES or module_name in NETWORK_CURRENT_OVERRIDES:
        return read_source(module_name)
    if module_name == "LOTM_WORLD_Events":
        return read_network_justice_events_source()
    if module_name in NETWORK_RULE_FUNCTION_OVERRIDES:
        return read_network_rule_source(module_name)
    return read_rc241_source(module_name)


def local_dependencies(source: str) -> list[str]:
    result: list[str] = []
    for match in INCLUDE_PATTERN.finditer(source):
        module_name = match.group(2)
        if not source_path(module_name).is_file():
            raise SystemExit(
                f"Project-local Gameplay include has no source file: {module_name}"
            )
        if module_name not in result:
            result.append(module_name)
    return result


def collect_modules() -> list[str]:
    discovered: set[str] = set()
    pending = [ENTRY_MODULE]
    while pending:
        module_name = pending.pop()
        if module_name in discovered:
            continue
        discovered.add(module_name)
        pending.extend(reversed(local_dependencies(read_source(module_name))))
    return sorted(discovered)


def network_local_dependencies(source: str) -> list[str]:
    result: list[str] = []
    for match in INCLUDE_PATTERN.finditer(source):
        module_name = match.group(2)
        if module_name not in result:
            result.append(module_name)
    return result


def collect_network_modules() -> list[str]:
    discovered: set[str] = set()
    # New modules have dependencies too; walk their closure instead of adding
    # just their names after the traversal has already finished.
    pending = [ENTRY_MODULE, *NETWORK_NEW_MODULES]
    while pending:
        module_name = pending.pop()
        if module_name in discovered:
            continue
        discovered.add(module_name)
        pending.extend(reversed(network_local_dependencies(read_network_source(module_name))))
    return sorted(discovered)


def transform(source: str) -> str:
    return INCLUDE_PATTERN.sub(
        lambda match: f'LOTM_RP_LoadBundledModule("{match.group(2)}")', source
    )


def lua_string_list(values: tuple[str, ...]) -> str:
    return ",".join(f'"{value}"' for value in values)


def generate_current() -> str:
    modules = collect_modules()
    sources = {name: read_source(name) for name in modules}
    digest = hashlib.sha256(
        "".join(
            f"{name}\0{sources[name]}\0" for name in modules
        ).encode("utf-8")
    ).hexdigest().upper()

    lines = [
        helper_source(),
        "-- AUTO-GENERATED by Tests/generate_gameplay_bundle.py; do not edit.",
        f"-- Bundle version: {BUNDLE_VERSION}",
        f"-- Source graph SHA-256: {digest}",
        "",
        f"LOTM_RP_GAMEPLAY_BUNDLE_VERSION = {BUNDLE_VERSION};",
        "LOTM_RP_GAMEPLAY_BUNDLE_LOADED = {};",
        "local m_bundleLoaders = {};",
        "local m_bundleState = {};",
        "",
        "function LOTM_RP_LoadBundledModule(moduleName)",
        "\tlocal state = m_bundleState[moduleName];",
        "\tif state == \"LOADED\" then return true; end",
        "\tif state == \"LOADING\" then",
        "\t\terror(\"[LOTM][Bundle] cyclic module load: \" .. tostring(moduleName));",
        "\tend",
        "\tlocal loader = m_bundleLoaders[moduleName];",
        "\tif type(loader) ~= \"function\" then",
        "\t\terror(\"[LOTM][Bundle] missing embedded module: \" .. tostring(moduleName));",
        "\tend",
        "\tm_bundleState[moduleName] = \"LOADING\";",
        '\tLOTM_StartupTrace.Mark("SP.Bundle", "MODULE BEGIN", moduleName);',
        "\tlocal ok, details = pcall(loader);",
        '\tLOTM_StartupTrace.Mark("SP.Bundle", "MODULE RETURN", moduleName, ok);',
        "\tif not ok then",
        "\t\tm_bundleState[moduleName] = \"FAILED\";",
        "\t\terror(\"[LOTM][Bundle] module=\" .. tostring(moduleName)",
        "\t\t\t.. \" failed: \" .. tostring(details));",
        "\tend",
        "\tm_bundleState[moduleName] = \"LOADED\";",
        "\tLOTM_RP_GAMEPLAY_BUNDLE_LOADED[moduleName] = true;",
        "\tprint(\"[LOTM][Bundle] loaded module=\" .. tostring(moduleName));",
        "\treturn true;",
        "end",
        "",
    ]
    for module_name in modules:
        transformed = transform(sources[module_name]).rstrip("\n")
        lines.extend(
            (
                f'm_bundleLoaders["{module_name}"] = function()',
                f"-- BEGIN EMBEDDED MODULE: Scripts/{module_name}.lua",
                trace_header("SP." + module_name, embed=False),
                transformed,
                f"-- END EMBEDDED MODULE: Scripts/{module_name}.lua",
                "end;",
                "",
            )
        )

    lines.extend(
        (
            f'LOTM_RP_LoadBundledModule("{ENTRY_MODULE}");',
            "",
            f"local requiredModules = {{{lua_string_list(COMMON_REQUIRED)}}};",
            "local rescueMode = LOTM_MP_TurnSync ~= nil",
            "\tand LOTM_MP_TurnSync.IsRescueModeConfigured ~= nil",
            "\tand LOTM_MP_TurnSync.IsRescueModeConfigured();",
            "local modeModules = rescueMode",
            f"\tand {{{lua_string_list(RESCUE_REQUIRED)}}}",
            f"\tor {{{lua_string_list(NORMAL_REQUIRED)}}};",
            "for _, moduleName in ipairs(modeModules) do",
            "\trequiredModules[#requiredModules + 1] = moduleName;",
            "end",
            "table.sort(requiredModules);",
            "for _, moduleName in ipairs(requiredModules) do",
            "\tif LOTM_RP_GAMEPLAY_BUNDLE_LOADED[moduleName] ~= true then",
            "\t\terror(\"[LOTM][Bundle] required module was not loaded: \" .. tostring(moduleName));",
            "\tend",
            "end",
            "print(\"[LOTM][Bundle] verified version=\"",
            "\t.. tostring(LOTM_RP_GAMEPLAY_BUNDLE_VERSION)",
            "\t.. \" modules=\" .. tostring(#requiredModules)",
            "\t.. \" rescueMode=\" .. tostring(rescueMode));",
            "",
        )
    )
    return "\n".join(lines)


def generate_rc241_network() -> str:
    modules = collect_network_modules()
    sources = {name: read_network_source(name) for name in modules}
    rc241_modules = sorted(
        name for name in modules
        if name not in NETWORK_NEW_MODULES and name not in NETWORK_CURRENT_OVERRIDES
    )
    rc241_digest = hashlib.sha256(
        "".join(f"{name}\0{read_rc241_source(name)}\0" for name in rc241_modules).encode("utf-8")
    ).hexdigest().upper()
    lines = [
        helper_source(),
        "-- AUTO-GENERATED rc.241 multiplayer main context; do not edit.",
        f"-- Published rc.241 old-module graph SHA-256: {rc241_digest}",
        "-- Old modules come from rc.241; explicit module and rule-function allowlists use current sources.",
        "",
        "LOTM_MP241_BUNDLE_LOADED = {};",
        "local m_mp241Loaders = {};",
        "local m_mp241State = {};",
        "",
        "function LOTM_MP241_LoadBundledModule(moduleName)",
        "\tlocal state = m_mp241State[moduleName];",
        "\tif state == \"LOADED\" then return true; end",
        "\tif state == \"LOADING\" then error(\"[LOTM][MP241] cyclic module load: \"..tostring(moduleName)); end",
        "\tlocal loader = m_mp241Loaders[moduleName];",
        "\tif type(loader) ~= \"function\" then error(\"[LOTM][MP241] missing module: \"..tostring(moduleName)); end",
        "\tm_mp241State[moduleName] = \"LOADING\";",
        '\tLOTM_StartupTrace.Mark("MP.Bundle", "MODULE BEGIN", moduleName);',
        "\tlocal ok,details = pcall(loader);",
        '\tLOTM_StartupTrace.Mark("MP.Bundle", "MODULE RETURN", moduleName, ok);',
        "\tif not ok then",
        "\t\tm_mp241State[moduleName] = \"FAILED\";",
        "\t\terror(\"[LOTM][MP241] module=\"..tostring(moduleName)..\" failed: \"..tostring(details));",
        "\tend",
        "\tm_mp241State[moduleName] = \"LOADED\";",
        "\tLOTM_MP241_BUNDLE_LOADED[moduleName] = true;",
        "\tprint(\"[LOTM][MP241] loaded module=\"..tostring(moduleName));",
        "\treturn true;",
        "end",
        "",
    ]
    for module_name in modules:
        transformed = INCLUDE_PATTERN.sub(
            lambda match: f'LOTM_MP241_LoadBundledModule("{match.group(2)}")',
            sources[module_name],
        ).rstrip("\n")
        provenance = (
            "POST_RC241_NEW" if module_name in NETWORK_NEW_MODULES
            else "POST_RC241_DELTA" if module_name in NETWORK_CURRENT_OVERRIDES
            else "POST_RC241_RULES" if module_name in NETWORK_RULE_FUNCTION_OVERRIDES
            else "RC241"
        )
        lines.extend((
            f'm_mp241Loaders["{module_name}"] = function()',
            f"-- BEGIN {provenance} MODULE: Scripts/{module_name}.lua",
            trace_header("MP." + module_name, embed=False),
            transformed,
            f"-- END {provenance} MODULE: Scripts/{module_name}.lua",
            "end;",
            "",
        ))
    lines.extend((
        'LOTM_MP241_LoadBundledModule("LOTM_MP241_Compat");',
        "local m_mp241Rescue = LOTM_MP_TurnSync.IsRescueModeConfigured();",
        "if m_mp241Rescue then",
        '\tLOTM_MP241_LoadBundledModule("LOTM_RESCUE_DirectMonsters");',
        "else",
        '\tLOTM_MP241_LoadBundledModule("LOTM_AI_Cult_Difficulty");',
        "end",
        f'LOTM_MP241_LoadBundledModule("{ENTRY_MODULE}");',
        "if m_mp241Rescue then",
        '\tLOTM_MP241_LoadBundledModule("LOTM_RESCUE_RuntimeEvents");',
        '\tLOTM_MP241_LoadBundledModule("LOTM_RESCUE_Thief");',
        '\tLOTM_MP241_LoadBundledModule("LOTM_RESCUE_StarGovernor");',
        "else",
        '\tLOTM_MP241_LoadBundledModule("LOTM_TP_Thief");',
        '\tLOTM_AI_Cult_Difficulty.Register();',
        "end",
        'LOTM_MP241_LoadBundledModule("LOTM_JUSTICE_Governor");',
        'LOTM_MP241_LoadBundledModule("LOTM_MS_Governors");',
        'LOTM_MP241_LoadBundledModule("LOTM_GodBlessings");',
        'print("[LOTM][MP241] verified oldBase=rc.241 resource=273 rescue="..tostring(m_mp241Rescue)',
        '\t.." unifiedDispatcher=false loaded="..tostring(#(function() local t={} for k in pairs(LOTM_MP241_BUNDLE_LOADED) do t[#t+1]=k; end return t; end)()));',
        'LOTM_MP241_MAIN_READY = true;',
        "",
    ))
    return "\n".join(lines)


PHASE2_TURN_FALLBACK_REGISTRATION = (
    "if GameEvents.PlayerTurnStarted~=nil then GameEvents.PlayerTurnStarted.Add(OnSynchronizedTurnStart); end"
)
PHASE2_COMMAND_ONLY_REGISTRATION = (
    '-- Resource 373: native city creation is an EXECUTE_SCRIPT operation, not turn-start processing.\n'
    'print("[LOTM_RESCUE][Phase2A] bootstrap policy=COMMAND_ONLY resource=373 turnStartCreation=false");'
)


def network_phase_source(module_name: str) -> str:
    source = read_rc241_source(module_name).rstrip("\n")
    if module_name == "LOTM_RESCUE_Phase2Test":
        # The resource-372 single-human room crash completes all four cities
        # inside PlayerTurnStarted, before any UI operation can be submitted.
        # Preserve every native city/content function. Only remove the early
        # fallback registration so the existing post-load command owns creation.
        if source.count(PHASE2_TURN_FALLBACK_REGISTRATION) != 1:
            raise SystemExit("rc.241 Phase 2 turn registration contract changed")
        source = source.replace(PHASE2_TURN_FALLBACK_REGISTRATION, PHASE2_COMMAND_ONLY_REGISTRATION)
    elif module_name == "LOTM_RESCUE_Phase3":
        # READY is logged only after the first native guardian creation. Make
        # the boundary observable without changing the call or its arguments.
        native_spawn = "\tlocal ok,unit=pcall(UnitManager.InitUnit,playerID,info.Index,selected.Plot:GetX(),selected.Plot:GetY());"
        if source.count(native_spawn) != 1:
            raise SystemExit("rc.241 Phase 3 guardian creation contract changed")
        source = source.replace(native_spawn, "\n".join((
            '\tLog("native-unit BEGIN player="..playerID.." church="..church.." tier="..tier.." plot="..selected.Plot:GetIndex());',
            native_spawn,
            '\tLog("native-unit RETURN ok="..tostring(ok).." exists="..tostring(unit~=nil));',
        )))
        init_guard = '\tif Game.GetProperty("LOTM_RESCUE_PHASE2A_STATE")~="READY" then return false; end'
        if source.count(init_guard) != 1:
            raise SystemExit("rc.241 Phase 3 readiness contract changed")
        source = source.replace(init_guard, init_guard + '\n\tLog("initialize BEGIN resource=373 phase2=READY");')
    # Quiet releases contain no per-statement calls, including no disabled
    # calls in expensive map searches. Detailed generation remains available.
    if not diagnostics_enabled():
        return source
    # Statement-level native boundaries in the early independent contexts.
    # Phase 1's pure map search inner loops are deliberately not expanded;
    # its reservation/visibility mutations and whole Initialize are traced.
    functions = ("Initialize", "MajorStarts", "ClaimReservations", "RevealReservationsForHumans", "Store") if module_name == "LOTM_RESCUE_Phase1" else None
    return trace_statements(source, "MP." + module_name, functions)


def generate_phase_router(module_name: str) -> str:
    source = network_phase_source(module_name)
    return "\n".join((
        f"-- AUTO-GENERATED rc.241 standalone network context: {module_name}; do not edit.",
        trace_header("MP." + module_name),
        "local m_mp241Network = GameConfiguration ~= nil",
        "\tand GameConfiguration.IsAnyMultiplayer ~= nil",
        "\tand GameConfiguration.IsAnyMultiplayer();",
        "if m_mp241Network then",
        f'\tprint("[LOTM][MP241] standalone context={module_name}");',
        source,
        "end",
        "",
    ))


def generate() -> str:
    network = generate_rc241_network().rstrip("\n")
    network_digest = hashlib.sha256(network.encode("utf-8")).hexdigest().upper()
    current = generate_current().rstrip("\n")
    return "\n".join(
        (
            "-- AUTO-GENERATED dual Gameplay entrypoint; do not edit.",
            "-- Multiplayer executes the rc.241 four-context baseline plus explicit post-241 deltas.",
            f"-- rc.241 network main-context SHA-256: {network_digest}",
            # Keep the small outer routing decision visible at the top of the
            # file; install helper after it and before either branch executes.
            "",
            helper_source(),
            'LOTM_StartupTrace.Mark("BundleRouter", "NETWORK QUERY BEFORE");',
            "local m_isNetworkGame = GameConfiguration ~= nil",
            "\tand GameConfiguration.IsAnyMultiplayer ~= nil",
            "\tand GameConfiguration.IsAnyMultiplayer();",
            'LOTM_StartupTrace.Mark("BundleRouter", "NETWORK DETECTED", m_isNetworkGame);',
            "if m_isNetworkGame then",
            # Same database-backed decision as the Gameplay adapter. Civ VI
            # configuration values can be booleans, numbers, strings or nil.
            '\tlocal m_configured = GameConfiguration.GetValue ~= nil',
            '\t\tand GameConfiguration.GetValue("GAMEMODE_LOTM_RESCUE") or nil;',
            '\tlocal m_rescue = (GameInfo ~= nil and GameInfo.Resources ~= nil',
            '\t\tand GameInfo.Resources["RESOURCE_LOTM_RESCUE_ALLY_BANNER"] ~= nil)',
            '\t\tor m_configured == true or tonumber(m_configured) == 1;',
            "\tif m_rescue then",
            '\t\tprint("[LOTM][BundleRouter] network rescue main deferred until published rc.241 UI bootstrap");',
            "\telse",
            '\t\tprint("[LOTM][BundleRouter] route=NETWORK_RC241_PLUS_DELTAS rescue=false");',
            network,
            "\tend",
            "else",
            '\tprint("[LOTM][BundleRouter] route=CURRENT_SINGLE_PLAYER");',
            current,
            "end",
            "",
        )
    )


def generate_network_output() -> str:
    network = generate_rc241_network().rstrip("\n")
    return "\n".join((
        "-- AUTO-GENERATED network main context loaded after the verbatim rc.241 rescue bootstrap.",
        trace_header("MP.MainContext",events=False),
        "local m_isNetworkGame = GameConfiguration ~= nil",
        "\tand GameConfiguration.IsAnyMultiplayer ~= nil",
        "\tand GameConfiguration.IsAnyMultiplayer();",
        "if m_isNetworkGame then",
        '\tprint("[LOTM][BundleRouter] route=NETWORK_RC241_PLUS_DELTAS phase2BeforeMain="',
        '\t\t.. tostring(Game.GetProperty("LOTM_RESCUE_PHASE2A_STATE") or "NOT_RESCUE"));',
        network,
        "end",
        "",
    ))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--check",
        action="store_true",
        help="Fail if the committed bundle is absent or stale.",
    )
    args = parser.parse_args()
    generated = generate()
    if args.check:
        if not OUTPUT.is_file() or OUTPUT.read_text(encoding="utf-8") != generated:
            print(f"STALE: {OUTPUT}")
            return 1
        expected_network = generate_network_output()
        if not NETWORK_OUTPUT.is_file() or NETWORK_OUTPUT.read_text(encoding="utf-8") != expected_network:
            print(f"STALE: {NETWORK_OUTPUT}")
            return 1
        for module_name, output in NETWORK_PHASE_OUTPUTS.items():
            expected = generate_phase_router(module_name)
            if not output.is_file() or output.read_text(encoding="utf-8") != expected:
                print(f"STALE: {output}")
                return 1
        print(f"PASS: Gameplay bundle is current ({OUTPUT.name})")
        return 0
    OUTPUT.write_text(generated, encoding="utf-8", newline="\n")
    NETWORK_OUTPUT.write_text(generate_network_output(), encoding="utf-8", newline="\n")
    for module_name, output in NETWORK_PHASE_OUTPUTS.items():
        output.write_text(generate_phase_router(module_name), encoding="utf-8", newline="\n")
    print(f"Generated {OUTPUT} ({len(generated.encode('utf-8'))} bytes)")
    print(f"Generated {NETWORK_OUTPUT} ({NETWORK_OUTPUT.stat().st_size} bytes)")
    print("Generated rc.241 standalone contexts: "
          + ", ".join(path.name for path in NETWORK_PHASE_OUTPUTS.values()))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
