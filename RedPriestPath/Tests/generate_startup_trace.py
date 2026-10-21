"""Reversible startup diagnostics, without rewriting native call expressions.

Statement checkpoints bracket existing expressions as a whole. In particular,
return checkpoints are BEFORE evaluation, not proof that the function returned.
All generated additions are marked; stripping them recovers exact input text.
"""
from __future__ import annotations

import argparse
from collections import defaultdict
from functools import lru_cache
from pathlib import Path
import re
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / "Scripts/LOTM_StartupTrace.lua"
BEGIN = "-- BEGIN RC342 STARTUP TRACE\n"
END = "-- END RC342 STARTUP TRACE\n"
BLOCK = re.compile(re.escape(BEGIN) + r".*?" + re.escape(END), re.S)
POINT = re.compile(r"--\[\[RC342\]\].*?--\[\[/RC342\]\]", re.S)


def strip_trace(source):
    return POINT.sub("", BLOCK.sub("", source))


def helper_source():
    return HELPER.read_text(encoding="utf-8").rstrip() + "\n"


def diagnostics_enabled():
    """Publish no statement checkpoints when the shared diagnostic switch is off."""
    match = re.search(r"\bEnabled\s*=\s*(true|false)\b", helper_source())
    if match is None:
        raise ValueError("startup helper must declare its diagnostic switch")
    return match.group(1) == "true"


def header(context, embed=True, events=True, ui=False):
    return BEGIN + (helper_source() if embed else "") + f'LOTM_StartupTrace.Mark("{context}","CONTEXT BEGIN");\n' + ((
        f'local Events = LOTM_StartupTrace.Events(Events,"{context}","Events");\n'
        f'local GameEvents = LOTM_StartupTrace.Events(GameEvents,"{context}","GameEvents");\n'
        + (f'local LuaEvents = LOTM_StartupTrace.Events(LuaEvents,"{context}","LuaEvents");\n' if ui else "")
    ) if events else "") + END


def footer(context):
    return BEGIN + f'LOTM_StartupTrace.Mark("{context}","CONTEXT END");\n' + END


def point(context, site, kind):
    return f'--[[RC342]] LOTM_StartupTrace.Mark("{context}","{kind} {site}"); --[[/RC342]]'


@lru_cache(maxsize=64)
def statements(source, context, functions=None):
    """Trace call-bearing statements in selected functions, plus chunk startup.

    Never hoist expressions, introduce locals, wrap native calls, or alter short
    circuiting. Keep an original statement terminator before its AFTER marker.
    ``functions`` limits expensive map-search inner loops in Phase 1.
    """
    from antlr4 import InputStream, CommonTokenStream
    from luaparser.parser.LuaLexer import LuaLexer
    from luaparser.parser.LuaParser import LuaParser
    # Civ VI permits type annotations. Spaces retain exact source offsets while
    # the standard Lua parser reads the otherwise identical program.
    parseable = re.sub(r"\s*:\s*(?:boolean|number|string|table)\b",lambda m:" "*len(m.group()),source)
    tokens = CommonTokenStream(LuaLexer(InputStream(parseable)))
    parser = LuaParser(tokens)
    tree = parser.start_()
    if parser.getNumberOfSyntaxErrors():
        raise ValueError(f"cannot instrument invalid Lua: {context}")
    additions = defaultdict(list)

    def walk(node, selected=True):
        kind = type(node).__name__
        definition = kind in ("Stat_localfunctionContext", "Stat_functionContext")
        if definition:
            snippet = source[node.start.start:node.stop.stop+1]
            match = re.match(r"(?:local\s+)?function\s+([\w.:]+)",snippet)
            selected = functions is None or (match and match.group(1) in functions)
        is_return = isinstance(node,LuaParser.RetstatContext)
        if selected and (isinstance(node,LuaParser.StatContext) or is_return) and not definition:
            snippet = source[node.start.start:node.stop.stop+1]
            # Semicolon-only statements and simple scalar assignments add no
            # useful native boundary. Keep control-flow and early-return sites.
            if kind != "Stat_emptyContext" and ("(" in snippet or ":" in snippet or is_return):
                site = f"L{node.start.line}C{node.start.column}:{kind.removesuffix('Context').removeprefix('Stat_')}"
                additions[node.start.start].append(point(context,site,"RETURN BEFORE" if is_return else "BEFORE"))
                if not is_return:
                    # Lua 5.1 does not allow an empty statement. Inserting
                    # Mark(...); before the original terminator produced ;;
                    # and prevented Civ VI from loading the entire script.
                    # Leave the existing terminator with its statement, then
                    # append the new call. Preserve comments/whitespace exactly.
                    position = node.stop.stop + 1
                    for following in tokens.tokens[node.stop.tokenIndex + 1:]:
                        if following.channel != 0:
                            continue
                        if following.text == ";":
                            position = following.stop + 1
                        break
                    additions[position].insert(0,point(context,site,"AFTER"))
        for child in getattr(node,"children",[]) or []:
            walk(child,selected)

    walk(tree)
    result = source
    for position in sorted(additions,reverse=True):
        result = result[:position] + "".join(additions[position]) + result[position:]
    # Every injected byte (including whitespace) must be removable.
    assert strip_trace(result) == source, "diagnostic statement insertion must be exactly reversible"
    return result


def runtime_source(source, context, detailed=False, embed=True):
    base = strip_trace(source)
    traced = statements(base,context) if detailed else base
    # A marked do-block keeps a possible chunk return legal. Strip the complete
    # marked header/footer to recover the unchanged original chunk and scope.
    ui = context not in ("LOTM_MP241_PreMainBootstrap", "LOTM_QD_MultiplayerCompat")
    return (header(context,embed,ui=ui) + BEGIN + "do\n" + END + traced
            + BEGIN + "\nend\n" + END + footer(context))


def runtime_files():
    mod = ET.parse(ROOT / "RedPriestPath.modinfo").getroot()
    paths = set()
    for node in mod.findall("./InGameActions/*/File") + mod.findall("./InGameActions/*/Properties/LuaReplace"):
        if node.text and node.text.strip().startswith("UI/"):
            relative = Path(node.text.strip()).with_suffix(".lua").as_posix()
            if (ROOT / relative).is_file():
                paths.add(relative)
    paths.update(("Scripts/LOTM_MP241_PreMainBootstrap.lua", "Scripts/LOTM_QD_MultiplayerCompat.lua"))
    return [ROOT / relative for relative in sorted(paths) if (ROOT / relative).is_file()]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check",action="store_true")
    args = parser.parse_args()
    for path in runtime_files():
        original = path.read_text(encoding="utf-8")
        # Detailed checkpoints in the authoritative pre-main bridge. UI city
        # bootstrap has handwritten scalar-result diagnostics in addition.
        expected = runtime_source(original,path.stem,
                                  detailed=diagnostics_enabled() and path.name != "LOTM_RESCUE_CityBootstrap.lua")
        if original != expected:
            if args.check:
                raise SystemExit(f"STALE diagnostics: {path}")
            path.write_text(expected,encoding="utf-8",newline="\n")
    print(f"PASS: startup diagnostics detailed={diagnostics_enabled()} in {len(runtime_files())} active UI/bridge files")


if __name__ == "__main__":
    main()
