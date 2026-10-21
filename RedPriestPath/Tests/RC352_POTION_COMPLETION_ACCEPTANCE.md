# rc352 / resource384

- Restart and load the user's turn18 save: sequence8 with 6 digestion and a completed Cryptologist project should reconcile to sequence7 using native project completion history. Do not advance from an incomplete/cancelled project or from fewer than6 digestion.
- Logs: `native potion receipt armed`, `potion command ... advanced=true`, `native potion receipt consumed`, or existing `potion completed ... 8->7`. Verify the holder panel shows7, digestion resets, and inherited skills remain correct.
- Complete a new potion project: at publication completion submit EXECUTE_SCRIPT, validate native receipt, advance in the same game turn. Test save/reload after completion and before local fallback, repeated callbacks, and delayed old queue: no duplicate advancement.
- The new native requirement→bonus-resource bridge has database and Lua substitute tests, but its engine update timing must be verified in a real game. Existing next-turn completion processing remains as fallback.
- No difficulty tuning: this logged HARD game at world turn18 had periodic2 + direct3 actual spawns, current shared cap35, 50% early-period rate applied through turn20. Limits and random/placement failure still apply.
- Validate single-player, one-human multiplayer room and two clients separately; do not equate build/hash checks with engine success.
