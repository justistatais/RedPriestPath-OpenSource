#!/usr/bin/env python3
"""Focused gate for the rc.241 multiplayer architecture restoration."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def check(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def main() -> int:
    base = subprocess.run(
        [sys.executable, str(ROOT / "Tests" / "validate_gameplay_bundle.py")],
        cwd=ROOT,
        check=False,
    )
    check(base.returncode == 0, "rc.241 bundle/action validation failed")
    compat = (ROOT / "Scripts" / "LOTM_MP241_Compat.lua").read_text(encoding="utf-8")
    check("Events.PlayerTurnActivated.Add(" not in compat,
          "post-rc.241 writers must not depend on local turn activation")
    check("GameEvents.PlayerTurnStarted.Add(wrapper)" in compat,
          "post-rc.241 synchronized additions must register directly")
    for forbidden in (
        "_turnHandlers", "_startupHandlers", "DispatchNetworkTurn",
        "LOTM_MP_TURNSYNC_LAST_RESCUE_STARTUP_TURN",
    ):
        check(forbidden not in compat, f"later unified dispatcher leaked into rc.241 adapter: {forbidden}")
    router = (ROOT / "Scripts" / "LOTM_RP_Gameplay_Bundle.lua").read_text(encoding="utf-8")
    bundle = (ROOT / "Scripts" / "LOTM_MP241_MainBundle.lua").read_text(encoding="utf-8")
    check('LOTM_MP241_LoadBundledModule("LOTM_MP241_Compat")' in bundle,
          "delta adapter must load before the rc.241 main entry")
    check(bundle.index('LOTM_MP241_LoadBundledModule("LOTM_MP241_Compat")')
          < bundle.index('LOTM_MP241_LoadBundledModule("LOTM_RP_Gameplay")'),
          "delta adapter load order is unsafe")
    check('LOTM_MP241_LoadBundledModule("LOTM_RESCUE_DirectMonsters")' in bundle
          and 'LOTM_MP241_LoadBundledModule("LOTM_RESCUE_Thief")' in bundle
          and 'LOTM_MP241_LoadBundledModule("LOTM_TP_Thief")' in bundle,
          "post-rc.241 new Gameplay features are missing from the network route")
    check("LOTM_RESCUE_PHASE1_GAMEPLAY_ADDIN" not in bundle,
          "standalone phase ownership must stay outside the main context")
    check("network rescue main deferred until published rc.241 UI bootstrap" in router,
          "post-rc.241 listeners load before the published city bootstrap")
    phase2 = (ROOT / "Scripts" / "LOTM_MP241_Phase2.lua").read_text(encoding="utf-8")
    check("checkpoint medieval-development" in phase2
          and "DEVELOPMENT_BYPASS" not in phase2
          and "network-stage" not in phase2
          and 'bootstrap policy=COMMAND_ONLY resource=373' in phase2
          and 'GameEvents.PlayerTurnStarted.Add(OnSynchronizedTurnStart)' not in phase2,
          "rc.241 city content must remain intact with command-only initialization")
    print("PASS: rc.241 multiplayer direct-event architecture with isolated post-241 features")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
