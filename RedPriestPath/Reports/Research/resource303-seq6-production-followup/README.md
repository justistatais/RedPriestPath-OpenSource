# Resource 303 — Sequence 6 production follow-up

## Finding

The latest normal-mode Lua log contains no `production stolen` record. Source inspection found that the previous implementation always selected the capital as the destination queue. When the capital had no active production, `hasDestination` was false and all source debits were rolled back.

## Fix

`Scripts/LOTM_TP_Thief.lua` now sorts the player's cities by CityID and selects the first city whose build queue reports an active production item. Source cities remain sorted by CityID. If no own city has an active item, no source production is committed; if destination injection fails, single-player rollback restores every source debit.

## Sequence 5–0 boundary

The existing code already contains the later sequence handlers: knowledge/faith transfer (5), borrowed abilities (4), faith/culture projects (3), borrowed ability application (2–1), and final branch gifts (0). They remain unclaimed as runtime-passed until a new game reaches each sequence and records the corresponding events.

Static validators and the release build do not substitute for that game evidence.
