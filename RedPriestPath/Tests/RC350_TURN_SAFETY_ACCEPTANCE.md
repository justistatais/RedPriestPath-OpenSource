# rc.350 / resource 382 — turn continuation

- Completely exit Civilization VI and relaunch after installation; Lua contexts cannot hot reload safely.
- Load the save from before the hang, finish turn 17, and confirm turn 18 completes barbarian player 63 and returns control to player 0. Continue several turns.
- Lua.log must show `RuntimeEvents ... loaded version=1`, `early seal ...` and `loaded module=LOTM_RESCUE_RuntimeEvents`; rc349 only showed the UI component.
- Native barbarian birth queues must be cleaned through `native spawn command` or the synchronized fallback. Nonhuman phases wait until a permitted human command boundary; no deletion from an actor's movement callback.
- Clear several camps, confirm each eligible reward and no duplicate on reload; check Seal −10 before/at world turn 20 and removal on 21.
- Verify new/old saves in single player, a one-human multiplayer room, and separate multiplayer clients. Do not treat Lua mocks, database validation, packaging or hashes as this acceptance.
- A save recorded after an engine operation is already stranded may require the previous autosave. No save state is edited by this release.
