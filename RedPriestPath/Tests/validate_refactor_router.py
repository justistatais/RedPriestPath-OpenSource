#!/usr/bin/env python3
"""Execute the generated route with real Lua and stubbed module bodies.

This covers the rc.339 log contradiction (router rescue=false, module
rescue=true), including boolean/string lobby values and READY saves.
No Civ VI native-engine behavior is simulated or claimed by this check.
"""
from pathlib import Path
import sys
from unittest.mock import patch
sys.dont_write_bytecode = True

ROOT = Path(__file__).resolve().parents[1]
try:
    from lupa import LuaRuntime
except ImportError:
    sys.path.insert(0, str(ROOT.parent / ".tmp" / "refactor-rc340-python"))
    from lupa import LuaRuntime

import generate_gameplay_bundle as generator


def main() -> int:
    with patch.object(generator, "generate_current", return_value="singleLoaded = true;\n"), \
         patch.object(generator, "generate_rc241_network", return_value="networkLoaded = true;\n"):
        route = generator.generate()
    count = 0
    for network in (True, False):
        for marker in (True, False):
            for value in (None, False, True, 0, 1, "0", "1"):
                lua = LuaRuntime(unpack_returned_tuples=True)
                lua.execute("print = function() end; GameConfiguration = {}; GameInfo = {Resources={}}")
                lua.globals().GameConfiguration.IsAnyMultiplayer = lambda: network
                lua.globals().GameConfiguration.GetValue = lambda _key: value
                if marker:
                    lua.globals().GameInfo.Resources["RESOURCE_LOTM_RESCUE_ALLY_BANNER"] = lua.table()
                lua.execute(route)
                rescue = marker or value is True or value == 1 or value == "1"
                assert bool(lua.globals().networkLoaded) == (network and not rescue), (network, marker, value)
                assert bool(lua.globals().singleLoaded) == (not network), (network, marker, value)
                count += 1
    # The network dependency closure must include dependencies of new modules,
    # even if no rc.241 module happens to include them.
    sources = {
        generator.ENTRY_MODULE: "",
        "LOTM_NewFeature": 'include("LOTM_Dependency")',
        "LOTM_Dependency": 'include("LOTM_Leaf")',
        "LOTM_Leaf": "",
    }
    with patch.object(generator, "NETWORK_NEW_MODULES", ("LOTM_NewFeature",)), \
         patch.object(generator, "read_network_source", side_effect=sources.__getitem__):
        assert set(generator.collect_network_modules()) == set(sources)
    print(f"PASS: {count} executed mode routes and new-module dependency closure")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
