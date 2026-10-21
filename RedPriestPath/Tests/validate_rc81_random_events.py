#!/usr/bin/env python3
"""Focused static contracts for the rc.81 synchronized random-status system."""

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


events = read("Scripts/LOTM_WORLD_Events.lua")
state = read("Scripts/LOTM_WORLD_State.lua")
artifacts = read("Scripts/LOTM_PP_Artifacts.lua")
event_sql = read("Gameplay/LOTM_WORLD_Events.sql")
artifact_sql = read("Gameplay/LOTM_PP_Artifacts.sql")
icons = read("Art/LOTM_RP_Icons.xml")
modinfo = read("RedPriestPath.modinfo")
gameplay = read("Scripts/LOTM_RP_Gameplay.lua")
goody = read("Scripts/LOTM_WORLD_GoodyHuts.lua")
lifecycle = read("Scripts/LOTM_RP_Lifecycle.lua")
popup = read("UI/LOTM_WORLD_Popup.lua")
zh = read("Text/zh_Hans_CN/LOTM_RP_GameplayText.xml")
en = read("Text/en_US/LOTM_RP_GameplayText.xml")

checks: list[tuple[str, bool]] = []


def check(name: str, condition: bool) -> None:
    checks.append((name, bool(condition)))


check("01 synchronized RNG only",
      "LOTM_MP_TurnSync.Random" in state
      and "Game.GetRandNum" not in state
      and "math.random" not in events + state)
check("02 first interval 12-18", "FIRST_MIN :number=12" in events and "FIRST_SPAN :number=7" in events)
check("03 later interval 10-16", "NEXT_MIN :number=10" in events and "NEXT_SPAN :number=7" in events)
check("04 strict GGBB bag", 'local bag={"G","G","B","B"}' in events)
check("05 cross-bag three-in-a-row guard", "result==last and result==previous" in events and "for swap=index+1,4" in events)
check("06 saved schedule and bag", all(token in events for token in (
    '"LOTM_WORLD_EVENT_BAG_ORDER"', '"LOTM_WORLD_EVENT_BAG_INDEX"',
    '"LOTM_WORLD_NEXT_EVENT_TURN"', '"LOTM_WORLD_EVENT_LAST"',
)))
check("07 starts only after a real holder exists", "local hero=LOTM_RP_State.FindHero(playerID)" in events and "if hero==nil then return; end" in events and '"LOTM_WORLD_EVENTS_STARTED"' in events)
check("08 human pathway players only", "LOTM_RP_State.IsAnyPathPlayer(playerID)" in events and "not player:IsHuman()" in events)
check("09 equipped artifact target is deterministic", "table.sort(result" in events and "artifact event target" in events)
check("10 anomaly is bound to instance", "prefix..tostring(target.Instance)" in events and "prefix..tostring(target.Slot)" not in events)
check("11 all four statuses last five player turns", "local DURATION :number=5" in events and events.count("turn+DURATION") >= 2)
check("12 native right-side notifications", "NotificationManager.SendNotification" in events and all(
    f"NotificationTypes.USER_DEFINED_{number}" in events for number in range(6, 10)
))
check("13 holder good is +5/+1", all(token in event_sql for token in (
    "LOTM_WORLD_HOLDER_GOOD_STRENGTH','Amount','5",
    "LOTM_WORLD_HOLDER_GOOD_MOVE','Amount','1",
)))
check("14 holder unstable is -5/-1", all(token in event_sql for token in (
    "LOTM_WORLD_HOLDER_UNSTABLE_STRENGTH','Amount','-5",
    "LOTM_WORLD_HOLDER_UNSTABLE_MOVE','Amount','-1",
)))
check("15 positive and negative leases are separate", all(token in event_sql for token in (
    "PositiveResourceType", "NegativeResourceType", "LOTM_ArtifactModifierPolarity81",
    "'_LEASE81_'||polarity.Polarity",
)))
check("16 old leases are explicitly retired", 'SetNamedResourceSwitch(p,lease76,false,false,"retired lease76")' in artifacts)
check("17 uncontrolled wins and satisfied suppresses negative", all(token in artifacts for token in (
    "if uncontrolled then return false,true; end",
    "if satisfied then return true,false; end",
    "return true,true;",
)))
check("18 scripted effects use polarity", all(token in artifacts for token in (
    'LOTM_PP_ArtifactPositiveActive(attackerPlayerID,"GREATWORK_LOTM_RP_BLOOD_HARVEST_SICKLE")',
    "positiveEquipped.GREATWORK_LOTM_BE_ORDER_CONVERTER",
    "LOTM_PP_ArtifactPositiveActive",
)))
check("19 world modules load before artifact turn settlement", gameplay.index('include("LOTM_WORLD_Events")') < gameplay.index('include("LOTM_PP_Artifacts")'))
check("20 modinfo registers every new file", all(relative in modinfo for relative in (
    "Gameplay/LOTM_WORLD_Events.sql", "Scripts/LOTM_WORLD_State.lua", "Scripts/LOTM_WORLD_Events.lua",
)))
check("21 missing properties use safe readers", "function LOTM_WORLD_State.NumberProperty" in state and "tonumber(player:GetProperty(" not in events)
check("22 required uncontrolled warning is localized", "可以卸下该封印物规避其负面效果" in zh and "You may unequip it to avoid those effects" in en)
check("23 all notification strings are bilingual", all(
    key in zh and key in en for key in (
        "ARTIFACT_SATISFIED_SUMMARY", "ARTIFACT_SATISFIED_MESSAGE",
        "ARTIFACT_UNCONTROLLED_SUMMARY", "ARTIFACT_UNCONTROLLED_MESSAGE",
        "HOLDER_GOOD_SUMMARY", "HOLDER_GOOD_MESSAGE",
        "HOLDER_UNSTABLE_SUMMARY", "HOLDER_UNSTABLE_MESSAGE",
    )
))
check("24 no UI authority added", not (ROOT / "UI" / "LOTM_WORLD_Events.lua").exists())
check("25 holder death does not pause the player-turn clock", "if not started then" in events and events.index("if not started then") < events.index("LOTM_WORLD_State.NextPlayerTurn(player)"))
check("26 reload/reconnect cannot advance twice", "LOTM_WORLD_PLAYER_TURN_SETTLED_GAME_TURN" in events and "Persist before any draw or settlement" in events)
check("27 notification payload is unique and old saves are replayed once", all(token in events for token in (
    "ParameterTypes.MESSAGE", "ParameterTypes.SUMMARY", "data.AlwaysUnique=true",
    '"LOTM_WORLD_NOTIFICATION_DELIVERED_SERIAL"', "DeliverPendingNotification(player)",
)))
check("28 notification circles use the selected pathway mark", all(token in events + icons for token in (
    "PATH_PERFECT=NotificationTypes.USER_DEFINED_6",
    "PATH_RED_PRIEST=NotificationTypes.USER_DEFINED_7",
    "PATH_BLACK_EMPEROR=NotificationTypes.USER_DEFINED_8",
    'Name="ICON_NOTIFICATION_USER_DEFINED_6" Atlas="ICON_ATLAS_LOTM_PP_PERFECT_MARK"',
    'Name="ICON_NOTIFICATION_USER_DEFINED_7" Atlas="ICON_ATLAS_LOTM_RP_RED_PRIEST_MARK"',
    'Name="ICON_NOTIFICATION_USER_DEFINED_8" Atlas="ICON_ATLAS_LOTM_BE_BLACK_EMPEROR_MARK"',
)))
check("29 conspirator letter copies native war-income attach balance", all(token in artifacts + artifact_sql for token in (
    "PlayerManager.GetAliveMajorIDs()", "PlayerManager.GetAliveMinorIDs()",
    '"LOTM_RP_ART_LETTER_WAR_GOLD_ACTIVE"', "LOTM_RP_ART_LETTER_WAR_GOLD_START",
    "LOTM_RP_ART_LETTER_WAR_GOLD_STOP", "MODIFIER_PLAYER_ADJUST_YIELD_CHANGE",
    "'Amount','50'", "'Amount','-50'", 'LOTM_MP_TurnSync.Add(ProcessTurn,"Artifacts")',
    "Reconcile(playerID,true)",
)) and "other:IsMinor()" not in artifacts)
check("30 conspirator peace penalty copies native attach balance", all(token in artifacts + artifact_sql for token in (
    '"LOTM_RP_ART_LETTER_PEACE_PENALTY_ACTIVE"', "LOTM_RP_ART_LETTER_PEACE_PENALTY_START",
    "LOTM_RP_ART_LETTER_PEACE_PENALTY_STOP", "'Amount','-25'", "'Amount','25'",
    "retired conspirator peace gate", "Events.DiplomacyMakePeace.Add", )))
check("31 stale notification restores its visible five-turn effect", all(token in events for token in (
    "RestoreExpiredPendingEffect", "turn+DURATION", "restored expired pending holder effect",
    "restored expired pending artifact effect", "holder effects player=",
    '"LOTM_WORLD_EFFECT_VISIBILITY_REPAIR87"', "RepairV87LastEventOnce(player)",
)))
check("32 holder combat modifiers have visible preview sources", all(token in event_sql + zh + en for token in (
    "LOTM_WORLD_HOLDER_GOOD_STRENGTH','Preview'",
    "LOTM_WORLD_HOLDER_UNSTABLE_STRENGTH','Preview'",
    "LOC_LOTM_WORLD_PREVIEW_HOLDER_GOOD_STRENGTH",
    "LOC_LOTM_WORLD_PREVIEW_HOLDER_UNSTABLE_STRENGTH",
)))
check("33 gathering potion purchase is stored then consumed before project unlock", all(token in goody + lifecycle + popup for token in (
    "RegisterPurchasedPotion", "TryConsumePurchasedPotion", "GATHERING_PURCHASE_AFTER_DIGESTION",
    "LOTM_WORLD_PURCHASED_POTION_SEQUENCE", "LOTM_WORLD_PURCHASED_POTION_PROJECT",
    "LOTM_WORLD_PURCHASED_POTION_SERIAL", "digestionTotal<LOTM_RP_DIGESTION_TARGET",
    "LOTM_WORLD_GOODY_POTION_CLEAR_PROJECT", "LOTM_WORLD_GOODY_POTION_CLEAR_SERIAL",
    "CityOperationTypes.VALUE_REMOVE_AT", "CityManager.RequestOperation", "m_waitingBuy",
    "Gameplay rejected the command", "if settled then", "and refunded", "purchase settled player=",
    "LOTM_WORLD_ACTIVE_POTION_PROJECTS", "LOTM_WORLD_Command_ProductionSync",
    "GetCurrentProductionTypeHash", "UI.RequestPlayerOperation", "stale-or-project-in-production",
    "CurrentProjectRule", "HasProjectPrerequisites(player, rule)", "purchased potion pending digestion",
    "for _,playerID in ipairs(PlayerManager.GetAliveMajorIDs())",
)) and "projectWasUnlocked" not in lifecycle
    and "GetCurrentProductionTypeHash" not in goody
    and "ProjectHasProgress" not in goody
    and 'tonumber(player:GetProperty("LOTM_WORLD_PURCHASED_POTION_' not in lifecycle
    and lifecycle.index("TryConsumePurchasedPotion(playerID)") < lifecycle.index("local modifierID, flagKey = GetProjectUnlock"))

failed = [name for name, ok in checks if not ok]
for name, ok in checks:
    print(("PASS" if ok else "FAIL") + ": " + name)
if failed:
    print(f"FAILED: {len(failed)} of {len(checks)} rc.81 checks", file=sys.stderr)
    raise SystemExit(1)
print(f"PASS: {len(checks)} rc.81 random-event checks")
