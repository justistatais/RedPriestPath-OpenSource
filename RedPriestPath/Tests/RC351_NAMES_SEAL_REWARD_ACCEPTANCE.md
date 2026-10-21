# rc351 / resource383

- Restart Civilization VI. On the same existing save, `LOTM_WORLD_MONSTER_2/1/0` must display the established low/mid/high monster names in flags and combat preview. Both selected language packs include aliases; saved names and synchronized unit properties are unchanged.
- Seal uses **world turns 1–20 inclusive**, removed at 21. Check one ordinary monster in the combat preview before 21 for Seal −10, then after 21 for its removal. Excludes outer gods/minions; preserves other bonuses. The captured rc350 log already verified native ability counts at turn16 (21 units) and removal at21 (30 units), but not a screenshot of pre21 combat calculation.
- Clear multiple camps in a human turn. Logs should show UI `camp observed`, `submit ... CampRemoved accepted=true`, then Gameplay `camp command ... settled=true`, with the reward `settledTurn` in the **same game turn**. Publication completion/command delivery may take a short moment; there is no intentional extra-turn wait on this path.
- Old pending rewards retain the existing fallback. Duplicate publication, reload and late fallback must not award twice. Unknown clearers are not fabricated.
- UI commands wait while no elected human is active. Refused submissions retry at most once per command identity per game turn. Do not delete native moving actors.
- Validate single-player, one-human multiplayer room, separate clients and reconnect. Static, database, mock integration and hash validation are not in-game acceptance.
