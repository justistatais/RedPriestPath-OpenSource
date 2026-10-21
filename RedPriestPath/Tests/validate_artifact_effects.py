#!/usr/bin/env python3
"""Validate all 21 sealed-artifact effects against a Civ VI Gameplay DB.

The source DB is copied to memory.  Only the rc.76 migration suffix is applied,
so this is read-only and also exercises upgrading an rc.75 runtime database.
"""
from __future__ import annotations

import argparse
import re
import sqlite3
import zlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SQL = ROOT / "Gameplay" / "LOTM_PP_Artifacts.sql"
EVENT_SQL = ROOT / "Gameplay" / "LOTM_WORLD_Events.sql"
LUA = ROOT / "Scripts" / "LOTM_PP_Artifacts.lua"
BE_LUA = ROOT / "Scripts" / "LOTM_BE_BlackEmperor.lua"
BE_UI = ROOT / "UI" / "LOTM_BE_EventObserver.lua"
HUD = ROOT / "UI" / "LOTM_RP_HUD.lua"

ARTIFACTS = (
    "GREATWORK_LOTM_PP_GOLDEN_APPRAISAL_MIRROR",
    "GREATWORK_LOTM_PP_PERPETUAL_GEARBOX",
    "GREATWORK_LOTM_PP_ERROR_ASTROLABE",
    "GREATWORK_LOTM_PP_HERMES_FURNACE",
    "GREATWORK_LOTM_PP_MYSTERY_BLUEPRINT",
    "GREATWORK_LOTM_PP_KNOWLEDGE_CASKET",
    "GREATWORK_LOTM_PP_CIVILIZATION_STELE",
    "GREATWORK_LOTM_RP_DISASTER_EMBER",
    "GREATWORK_LOTM_RP_CONSPIRATOR_LETTER",
    "GREATWORK_LOTM_RP_BLOOD_HARVEST_SICKLE",
    "GREATWORK_LOTM_RP_IRONBLOOD_BANNER",
    "GREATWORK_LOTM_RP_WAR_SCRIPTURE",
    "GREATWORK_LOTM_RP_DISASTER_WEATHER",
    "GREATWORK_LOTM_RP_CONQUEROR_CROWN",
    "GREATWORK_LOTM_BE_GOLDEN_BRIBE",
    "GREATWORK_LOTM_BE_CORRUPTION_TAXBOOK",
    "GREATWORK_LOTM_BE_CHAOS_CODEX",
    "GREATWORK_LOTM_BE_DEPRAVED_FEAST",
    "GREATWORK_LOTM_BE_FRENZY_SCEPTER",
    "GREATWORK_LOTM_BE_ENTROPY_CROWN",
    "GREATWORK_LOTM_BE_ORDER_CONVERTER",
)

LUA_ONLY = {
    "GREATWORK_LOTM_RP_BLOOD_HARVEST_SICKLE": ("OnCombatOccurred", "negativeEquipped.GREATWORK_LOTM_RP_BLOOD_HARVEST_SICKLE"),
}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("database", type=Path)
    args = parser.parse_args()

    source = sqlite3.connect(f"file:{args.database.as_posix()}?mode=ro", uri=True)
    db = sqlite3.connect(":memory:")
    source.backup(db)
    db.create_function("Make_Hash", 1, lambda value: zlib.crc32(str(value).encode()))
    source.close()

    candidate = SQL.read_text(encoding="utf-8")
    marker = "-- rc.76 complete 21-artifact audit."
    db.executescript(marker + candidate.split(marker, 1)[1])
    db.executescript(EVENT_SQL.read_text(encoding="utf-8"))
    db.execute("PRAGMA foreign_keys=ON")
    failures: list[str] = []

    def check(ok: bool, message: str) -> None:
        if not ok:
            failures.append(message)

    check(not db.execute("PRAGMA foreign_key_check").fetchall(), "foreign-key errors")
    leases = dict(db.execute(
        "SELECT ArtifactType,LeaseRequirementSetId FROM LOTM_ArtifactTurnLeases76"
    ))
    check(set(leases) == set(ARTIFACTS), "rc.76 lease map is not exactly 21 artifacts")

    gameplay = LUA.read_text(encoding="utf-8")
    block = gameplay.split("local EFFECT_MODIFIERS :table = {", 1)[1].split("};", 1)[0]
    attached = set(re.findall(r'"(LOTM_(?:PP_FX|RP_ART|BE_ART)_[A-Z0-9_]+)"', block))
    district_cancellations = {
        row[0]
        for row in db.execute(
            "SELECT ModifierId FROM Modifiers "
            "WHERE ModifierId LIKE 'LOTM_BE_ART_BRIBE_CANCEL_DISTRICT_%_238'"
        )
    }
    bribe_239 = {
        row[0]
        for row in db.execute(
            "SELECT ModifierId FROM Modifiers WHERE "
            "ModifierId LIKE 'LOTM_BE_ART_BRIBE_RESTORE_DISTRICT_%_239' OR "
            "ModifierId IN ('LOTM_BE_ART_BRIBE_DOMESTIC_FOOD_FIXED_239',"
            "'LOTM_BE_ART_BRIBE_DOMESTIC_PRODUCTION_FIXED_239')"
        )
    }
    check(
        all(token in gameplay for token in (
            "GameInfo.District_TradeRouteYields",
            '"LOTM_BE_ART_BRIBE_CANCEL_DISTRICT_"',
            "table.insert(EFFECT_MODIFIERS,id)",
        )),
        "resource-238 generated Bribe modifiers are not attached by Gameplay",
    )
    attached.update(district_cancellations)
    attached.update(bribe_239)
    generated = {
        row[0][:-8]
        for row in db.execute("SELECT ModifierId FROM Modifiers WHERE ModifierId LIKE '%_LEASE76'")
    }
    check(attached == generated, f"Lua/DB attachment mismatch: {sorted(attached ^ generated)}")

    coverage: dict[str, int] = {}
    for artifact in ARTIFACTS:
        reqset = leases.get(artifact, "")
        count = db.execute(
            """SELECT count(*) FROM Modifiers
                WHERE ModifierId LIKE '%_LEASE76'
                  AND (OwnerRequirementSetId=? OR SubjectRequirementSetId=?)""",
            (reqset, reqset),
        ).fetchone()[0]
        coverage[artifact] = count
        if artifact in LUA_ONLY:
            check(all(token in gameplay for token in LUA_ONLY[artifact]), f"{artifact} Lua effect missing")
        else:
            check(count > 0, f"{artifact} has no rc.76 continuous effect")

    arguments = dict(db.execute(
        "SELECT ModifierId||':'||Name,Value FROM ModifierArguments WHERE ModifierId LIKE 'LOTM_%'"
    ))
    types = dict(db.execute(
        "SELECT ModifierId,ModifierType FROM Modifiers WHERE ModifierId LIKE 'LOTM_%'"
    ))
    check(arguments.get("LOTM_BE_ART_BRIBE_ROUTE_GOLD:Amount") == "10", "bribe route Gold is not +10")
    check(arguments.get("LOTM_BE_ART_BRIBE_DOMESTIC_FOOD:Amount") == "0", "legacy bribe Food flat penalty is not neutralized")
    check(arguments.get("LOTM_BE_ART_BRIBE_DOMESTIC_PRODUCTION:Amount") == "0", "legacy bribe Production flat penalty is not neutralized")
    check(arguments.get("LOTM_BE_ART_BRIBE_DOMESTIC_FOOD_FIXED_239:Amount") == "-3", "resource-239 domestic Food penalty is not -3")
    check(arguments.get("LOTM_BE_ART_BRIBE_DOMESTIC_PRODUCTION_FIXED_239:Amount") == "-3", "resource-239 domestic Production penalty is not -3")
    expected_district_cancellations = {
        (
            f"LOTM_BE_ART_BRIBE_CANCEL_DISTRICT_{district}_{yield_type}_238",
            yield_type,
            str(-amount),
        )
        for district, yield_type, amount in db.execute(
            "SELECT DistrictType,YieldType,YieldChangeAsDomesticDestination "
            "FROM District_TradeRouteYields "
            "WHERE YieldType IN ('YIELD_FOOD','YIELD_PRODUCTION') "
            "AND YieldChangeAsDomesticDestination>0"
        )
    }
    check(bool(expected_district_cancellations), "no domestic district yields found for Bribe cancellation")
    for modifier_id, yield_type, amount in expected_district_cancellations:
        check(types.get(modifier_id) == "MODIFIER_PLAYER_CITIES_ADJUST_TRADE_ROUTE_YIELD_TO_OTHERS", f"{modifier_id} type mismatch")
        check(arguments.get(f"{modifier_id}:YieldType") == yield_type, f"{modifier_id} yield mismatch")
        check(arguments.get(f"{modifier_id}:Amount") == amount, f"{modifier_id} is not the exact inverse of its district source")
        check(arguments.get(f"{modifier_id}:Domestic") == "true", f"{modifier_id} is not domestic-only")
        check(arguments.get(f"{modifier_id}_LEASE81_NEG:Amount") == amount, f"{modifier_id} negative lease clone missing")
        restore_id = modifier_id.replace("BRIBE_CANCEL_DISTRICT_", "BRIBE_RESTORE_DISTRICT_").replace("_238", "_239")
        check(types.get(restore_id) == "MODIFIER_PLAYER_CITIES_ADJUST_TRADE_ROUTE_YIELD_TO_OTHERS", f"{restore_id} type mismatch")
        check(arguments.get(f"{restore_id}:YieldType") == yield_type, f"{restore_id} yield mismatch")
        check(arguments.get(f"{restore_id}:Amount") == str(-float(amount)), f"{restore_id} does not exactly neutralize resource 238")
        check(arguments.get(f"{restore_id}:Domestic") == "true", f"{restore_id} is not domestic-only")
    check(
        not db.execute(
            "SELECT 1 FROM ModifierArguments WHERE ModifierId LIKE 'LOTM_BE_ART_BRIBE%' "
            "AND Name='Amount' AND CAST(Value AS REAL)<=-999 LIMIT 1"
        ).fetchone(),
        "Golden Bribe must never use -999 or a larger catch-all penalty",
    )
    for modifier_id, amount in {
        "LOTM_BE_ART_BRIBE_LEGACY_FOOD_COMPENSATION": "100",
        "LOTM_BE_ART_BRIBE_LEGACY_PRODUCTION_COMPENSATION": "100",
        "LOTM_BE_ART_BRIBE_ZERO_ALL_FOOD": "-100",
        "LOTM_BE_ART_BRIBE_ZERO_ALL_PRODUCTION": "-100",
        "LOTM_BE_ART_BRIBE_RESTORE_INTERNATIONAL_FOOD": "100",
        "LOTM_BE_ART_BRIBE_RESTORE_INTERNATIONAL_PRODUCTION": "100",
        "LOTM_BE_ART_BRIBE_LEGACY_FOOD_COMPENSATION_CANCEL_237": "-100",
        "LOTM_BE_ART_BRIBE_LEGACY_PRODUCTION_COMPENSATION_CANCEL_237": "-100",
        "LOTM_BE_ART_BRIBE_ZERO_DESTINATION_FOOD_237": "-100",
        "LOTM_BE_ART_BRIBE_ZERO_DESTINATION_PRODUCTION_237": "-100",
    }.items():
        check(arguments.get(f"{modifier_id}:Amount") == amount, f"{modifier_id} amount mismatch")
    for modifier_id in (
        "LOTM_BE_ART_BRIBE_ZERO_DESTINATION_FOOD_237",
        "LOTM_BE_ART_BRIBE_ZERO_DESTINATION_PRODUCTION_237",
    ):
        check(arguments.get(f"{modifier_id}:Destination") == "1", f"{modifier_id} is not destination-side")
        check(arguments.get(f"{modifier_id}_LEASE81_NEG:Amount") == "-100", f"{modifier_id} negative lease missing")
    check(arguments.get("LOTM_RP_ART_BANNER_MAINTENANCE:Amount") == "-100", "banner maintenance is not +100%")
    check(arguments.get("LOTM_RP_ART_SCRIPTURE_WEARINESS:Amount") == "-100", "scripture weariness is not -100%")
    check(arguments.get("LOTM_RP_ART_CROWN_ATTACK_DISTRICT:Amount") == "150", "crown attack is not +150")
    check(arguments.get("LOTM_RP_ART_CROWN_DEFENSE:Amount") == "-20", "crown defense is not -20")
    expected_letter = {
        "LOTM_RP_ART_LETTER_WAR_GOLD_START": ("MODIFIER_PLAYER_ADJUST_YIELD_CHANGE", "50"),
        "LOTM_RP_ART_LETTER_WAR_GOLD_STOP": ("MODIFIER_PLAYER_ADJUST_YIELD_CHANGE", "-50"),
        "LOTM_RP_ART_LETTER_PEACE_PENALTY_START": ("MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_MODIFIER", "-25"),
        "LOTM_RP_ART_LETTER_PEACE_PENALTY_STOP": ("MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_MODIFIER", "25"),
    }
    for modifier_id, (modifier_type, amount) in expected_letter.items():
        check(types.get(modifier_id) == modifier_type, f"{modifier_id} type mismatch")
        check(arguments.get(f"{modifier_id}:Amount") == amount, f"{modifier_id} amount mismatch")
    check(arguments.get("LOTM_RP_ART_LETTER_PEACE_GOLD:Amount") == "0", "legacy letter peace lease is not neutralized")
    expected_flat = {
        "LOTM_BE_ART_CODEX_SCIENCE_FLAT": ("YIELD_SCIENCE", "30", "POS"),
        "LOTM_BE_ART_CODEX_GOLD_FLAT": ("YIELD_GOLD", "-100", "NEG"),
        "LOTM_BE_ART_FEAST_GOLD_FLAT": ("YIELD_GOLD", "-500", "NEG"),
        "LOTM_BE_ART_FRENZY_GOLD_FLAT": ("YIELD_GOLD", "-500", "NEG"),
        "LOTM_PP_FX_STELE_GOLD_FLAT": ("YIELD_GOLD", "-500", "NEG"),
    }
    polarities = dict(db.execute(
        "SELECT ModifierId,Polarity FROM LOTM_ArtifactModifierPolarity81"
    ))
    for modifier_id in (
        "LOTM_BE_ART_BRIBE_LEGACY_FOOD_COMPENSATION",
        "LOTM_BE_ART_BRIBE_LEGACY_PRODUCTION_COMPENSATION",
        "LOTM_BE_ART_BRIBE_ZERO_ALL_FOOD",
        "LOTM_BE_ART_BRIBE_ZERO_ALL_PRODUCTION",
        "LOTM_BE_ART_BRIBE_RESTORE_INTERNATIONAL_FOOD",
        "LOTM_BE_ART_BRIBE_RESTORE_INTERNATIONAL_PRODUCTION",
    ):
        check(polarities.get(modifier_id) == "NEG", f"{modifier_id} must use the negative lease")
        check(f"{modifier_id}_LEASE81_NEG" in types, f"{modifier_id} negative lease clone missing")
    for modifier_id in district_cancellations:
        check(polarities.get(modifier_id) == "NEG", f"{modifier_id} must use the negative lease")
    for modifier_id in bribe_239:
        check(polarities.get(modifier_id) == "NEG", f"{modifier_id} must use the negative lease")
    for modifier_id, (yield_type, amount, polarity) in expected_flat.items():
        check(types.get(modifier_id) == "MODIFIER_PLAYER_ADJUST_YIELD_CHANGE", f"{modifier_id} is not a native flat yield")
        check(arguments.get(f"{modifier_id}:YieldType") == yield_type, f"{modifier_id} yield mismatch")
        check(arguments.get(f"{modifier_id}:Amount") == amount, f"{modifier_id} amount mismatch")
        check(polarities.get(modifier_id) == polarity, f"{modifier_id} polarity mismatch")
        lease_id = f"{modifier_id}_LEASE81_{polarity}"
        check(types.get(lease_id) == "MODIFIER_PLAYER_ADJUST_YIELD_CHANGE", f"{lease_id} clone missing")
        check(arguments.get(f"{lease_id}:YieldType") == yield_type, f"{lease_id} yield mismatch")
        check(arguments.get(f"{lease_id}:Amount") == amount, f"{lease_id} amount mismatch")
        check(f'"{modifier_id}"' in gameplay, f"{modifier_id} is not attached by Gameplay")
    check("ChangeCurrentResearchProgress(30)" not in gameplay and "ChangeGoldBalance(-100)" not in gameplay and "ChangeGoldBalance(-500)" not in gameplay, "fixed per-turn artifacts are still directly settled")
    check("local converted=production/3; orderConverted=converted;" in gameplay and "ChangeCurrentCulturalProgress(converted)" in gameplay and "ChangeGoldBalance(converted)" in gameplay and 'p:SetProperty("LOTM_PP_ORDER_CONVERTED_LAST",orderConverted)' in gameplay, "order conversion outputs/property mismatch")
    frenzy = [name for name, modifier_type in types.items() if name.startswith("LOTM_BE_ART_FRENZY_") and name.endswith("_AURA") and modifier_type == "MODIFIER_LOTM_ART_MAJOR_OPPOSING_PLAYERS_ATTACH_MODIFIER"]
    check(len(frenzy) == 6, "frenzy must have six enemy-only auras")
    check("if equipped.GREATWORK_LOTM_BE_ORDER_CONVERTER then p:GetTreasury():ChangeGoldBalance(200); end" not in gameplay, "old fixed order +200 remains")
    check("retired lease70" in gameplay and "retired lease76" in gameplay, "old leases are not retired")

    be_gameplay = BE_LUA.read_text(encoding="utf-8")
    be_ui = BE_UI.read_text(encoding="utf-8")
    hud = HUD.read_text(encoding="utf-8")
    check(all(token in be_gameplay for token in (
        'GOLDEN_BRIBE_ARTIFACT :string = "GREATWORK_LOTM_BE_GOLDEN_BRIBE"',
        "Events.TradeRouteActivityChanged.Add(OnTradeRouteActivityChanged)",
        "TradeRouteActiveCount274", "GetOutgoingTradeRouteCount(player)",
        "GoldenBribePositiveActive(originPlayerID)", "LOTM_PP_ArtifactPositiveActive",
        "PlayerManager.GetAliveMinorIDs()", "GiveFreeTokenToPlayer(destinationPlayerID)",
        "player:SetProperty(P.TradeRouteActiveCount274, current)",
        "delta <= 0", "reason=NOT_STARTED", "reason=NOT_REAL_CITY_STATE", "envoy=true",
    )), "bribe envoy settlement is not a synchronized, positive-polarity, idempotent Gameplay chain")
    check("Events.TradeRouteActivityChanged.Add" not in be_ui
          and "LOTM_BE_Command_TradeRouteStarted" not in be_ui
          and "GetOutgoingRoutes()" not in be_ui,
          "bribe envoy authority must not remain in the local UI observer")
    check(all(token in hud for token in (
        "RefreshYieldTooltips", "FindYieldBacking", "GetScienceTooltip()",
        "GetCultureTooltip()", "LOTM_PP_ORDER_CONVERTED_LAST",
        "LOC_LOTM_ARTIFACT_YIELD_INCLUDED_TOOLTIP",
        "LOC_LOTM_ARTIFACT_YIELD_SETTLED_TOOLTIP",
    )), "artifact yield tooltip integration is incomplete")

    if failures:
        print(f"FAILED: {len(failures)} artifact audit failures")
        for failure in failures:
            print(" -", failure)
        return 1
    for artifact in ARTIFACTS:
        mode = f"{coverage[artifact]} modifier(s)" if coverage[artifact] else "synchronized Lua"
        print(f"PASS {artifact}: {mode}")
    print(f"PASS: all 21 artifacts; {len(generated)} rc.76 live modifiers; zero foreign-key errors")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
