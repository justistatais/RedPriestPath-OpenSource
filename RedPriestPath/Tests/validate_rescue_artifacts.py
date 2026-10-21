#!/usr/bin/env python3
"""Static contracts for Resource 268 effects through Resource 271 fixes."""
from __future__ import annotations

import argparse
import sqlite3
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def check(condition: bool, message: str) -> None:
    if not condition:
        print(f"FAIL: {message}")
        raise SystemExit(1)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--database", type=Path)
    args = parser.parse_args()
    sql = (ROOT / "Gameplay" / "LOTM_RESCUE_Artifacts.sql").read_text(encoding="utf-8")
    common = (ROOT / "Scripts" / "LOTM_PP_Artifacts.lua").read_text(encoding="utf-8")
    rescue = (ROOT / "Scripts" / "LOTM_RESCUE_Artifacts.lua").read_text(encoding="utf-8")
    phase5 = (ROOT / "Scripts" / "LOTM_RESCUE_Phase5.lua").read_text(encoding="utf-8")
    monsters = (ROOT / "Scripts" / "LOTM_WORLD_Monsters.lua").read_text(encoding="utf-8")
    modinfo = (ROOT / "RedPriestPath.modinfo").read_text(encoding="utf-8")
    ui = (ROOT / "UI" / "LOTM_RESCUE_ArtifactPillage.lua").read_text(encoding="utf-8")
    artifact_screen = (ROOT / "UI" / "LOTM_PP_ArtifactsScreen.lua").read_text(encoding="utf-8")
    artifact_showcase = (ROOT / "UI" / "LOTM_PP_ArtifactShowcase.lua").read_text(encoding="utf-8")
    rescue_text = (ROOT / "Text" / "zh_Hans_CN" / "LOTM_RP_GameplayText.xml").read_text(encoding="utf-8")

    check("local VERSION=4;" in rescue, "Rescue artifact stable bulk-ordering version is not active")
    check("LOTM_RescueArtifactLeases268" in sql, "missing Rescue lease table")
    check("criteria=\"LOTM_RP_RESCUE_MODE\"" in modinfo and "Gameplay/LOTM_RESCUE_Artifacts.sql" in modinfo,
          "Rescue database action is not criteria isolated")
    check("if not RescueActive() then" in common and "rescue retired ordinary positive lease81" in common,
          "ordinary attachments/resources are not runtime-isolated")
    check("CanTriggerBoost" not in common and all(token in common for token in (
        "TriggerRandomKnowledgeCasketEureka", "table.sort(choices)", "pcall(function() return techs:TriggerBoost(selected,1); end)",
    )), "Knowledge Casket does not use the safe Paragon Eureka chain")
    check(all(token in common for token in (
        "local TEST_RESCUE_NEW_GAME_ALL_ARTIFACTS :boolean = false;",
        "BEGIN TEMP TEST FEATURE", "GrantAllArtifactsForRescueNewGame",
        "TEST_RESCUE_NEW_GAME_ALL_ARTIFACTS~=true", "not RescueActive()",
        "IsPrimaryHuman(playerID)", "GameConfiguration.GetStartTurn()",
        'p:SetProperty("LOTM_TEST_RESCUE_ALL_ARTIFACTS_269",1)',
        "elseif Grant(playerID,artifactType)",
    )), "Resource 269 test grant is not retained behind one disabled switch")
    temp_block = common.split("BEGIN TEMP TEST FEATURE IMPLEMENTATION", 1)[1].split("END TEMP TEST FEATURE IMPLEMENTATION", 1)[0]
    check("Grant(" in temp_block and "Remove" not in temp_block and "SetResource" not in temp_block,
          "Disabling the temporary grant must not revoke formally owned artifacts from existing saves")

    for token in (
        "LOTM_RESCUE_EMBER_ALLOW_PILLAGE", "LOTM_RP_ART_EMBER_FAST_PILLAGE",
        "('LOTM_RESCUE_WEATHER_FRIENDLY_MOVE','Amount','2')",
        "('LOTM_RESCUE_WEATHER_AMENITY','Amount','-2')",
        "('LOTM_RESCUE_WEATHER_MONSTER_STRENGTH','Amount','-10')",
        "('LOTM_RESCUE_WEATHER_MONSTER_MOVE','Amount','-1')",
        "('LOTM_RESCUE_CROWN_SELF_INNER','Amount','50')",
        "('LOTM_RESCUE_CROWN_SELF_OUTER','Amount','50')",
        "('LOTM_RESCUE_ALLY_BANNER_COMBAT','Amount','15')",
        "('LOTM_RESCUE_ALLY_CROWN_INNER','Amount','30')",
        "('LOTM_RESCUE_ALLY_CROWN_OUTER','Amount','30')",
        "('LOTM_RESCUE_FRENZY_GOLD','Amount','-50')",
    ):
        check(token in sql, f"Rescue SQL lacks {token}")
    check(all(token in rescue for token in (
        "diplomacy:HasAllied(secondID)", "LOTM_RESCUE_PHASE8_PERMANENT_ALLIANCE:",
        "LOTM_WORLD_Monsters.IsMonster(unit)", 'unit:GetProperty("LOTM_RESCUE_CENTER_MONSTER")',
        "WEATHER_RECONCILE_VERSION=2", "ImprovementBuilder.SetImprovementPillaged(plot,true)",
        "buildings:SetPillaged(target.Index,true)", "district:SetPillaged(true)",
        "PlunderReward(player,unit,plunderType,baseAmount)", "MoveCost(unit)",
    )), "Rescue synchronized coordinator lacks a complete ally/weather/pillage chain")
    check(all(token in rescue for token in (
        'ATTACHED_PROPERTY="LOTM_RESCUE_ARTIFACT_MODIFIERS_268"',
        'UPGRADE_ATTACHED_PROPERTY="LOTM_RESCUE_ARTIFACT_MODIFIERS_270"',
        'UPGRADE271_ATTACHED_PROPERTY="LOTM_RESCUE_ARTIFACT_MODIFIERS_271"',
        'ALLY_ATTACHED_PROPERTY="LOTM_RESCUE_ARTIFACT_ALLY_MODIFIERS_268"',
        'ALLY_UPGRADE_ATTACHED_PROPERTY="LOTM_RESCUE_ARTIFACT_ALLY_MODIFIERS_270"',
        'ALLY_UPGRADE271_ATTACHED_PROPERTY="LOTM_RESCUE_ARTIFACT_ALLY_MODIFIERS_271"',
        "holder resource270 modifiers attached",
        "holder resource271 crown repair attached",
    )), "Resource 270/271 must add only version-gated modifiers to old saves")
    check('ReconcileGlobal("INITIALIZE")' in rescue and 'Events.LoadGameViewStateDone' not in rescue,
          "Existing-save artifacts must reconcile from synchronized Gameplay initialization, not a UI-only load event")
    diplomacy = rescue.split("local function OnDiplomacy", 1)[1].split("GameEvents.LOTM_RESCUE_Command_OwnPillage", 1)[0]
    check("if LOTM_MP_TurnSync.IsNetworkGame() then return; end" in diplomacy
          and diplomacy.index("return; end") < diplomacy.index("ReconcileGlobal("),
          "Network diplomacy publication callbacks must not mutate artifact Gameplay state")
    check('LOTM_MP_TurnSync.Add(OnPlayerTurn,"RescueArtifacts")' in rescue
          and 'LOTM_MP_TurnSync.RunStartup(function() ReconcileGlobal("INITIALIZE"); end,"RescueArtifacts")' in rescue,
          "Rescue artifact reconciliation must retain synchronized turn/startup fallbacks")
    check("local speedPercent=" not in rescue and "GameInfo.GameSpeeds[GameConfiguration.GetGameSpeedType()]" not in rescue
          and "math.floor(Number(baseAmount,0)+0.5))*2" in rescue,
          "own pillage must double native PlunderAmount without a second speed scaling")
    check(all(token in rescue for token in (
        "ShowPlunderWorldText", "Game.AddWorldViewText(playerID",
        "COLOR_FLOAT_GOLD", "COLOR_FLOAT_FAITH", "COLOR_FLOAT_SCIENCE",
        "COLOR_FLOAT_CULTURE", "ICON_Health",
    )), "own pillage lacks original-style yield world text")
    check(all(token in rescue for token in (
        'double="..doubled', 'bannerAllies=', 'crownAllies=',
    )) and "reason=FULL_HEALTH_HEAL" not in rescue,
          "Resource 271 must retain full-health pillaging and add explicit double/ally evidence logs")
    check(all(token in common for token in (
        "negativeEquipped.GREATWORK_LOTM_RP_BLOOD_HARVEST_SICKLE",
        "maximum-1-current", "sickle attrition player=",
    )) and "ChangeDamage(-math.min(5,damage))" not in common,
          "Sickle attrition must apply five nonlethal damage only on the negative polarity")
    workshops = (ROOT / "Scripts" / "LOTM_PP_Workshops.lua").read_text(encoding="utf-8")
    check("LOTM_RESCUE_Artifacts.ApplyMonsterWeather(unit)" in workshops,
          "central-workshop monsters do not enter the incremental Weather chain")
    check(all(token in sql for token in (
        "CLASS_ALL_COMBAT_UNITS", "EFFECT_ADJUST_CITY_COMBAT_BONUS",
        "('LOTM_RESCUE_CROWN_SELF_INNER','Amount','50')",
        "('LOTM_RESCUE_CROWN_SELF_OUTER','Amount','50')",
        "('LOTM_RESCUE_ALLY_CROWN_INNER','Amount','30')",
        "('LOTM_RESCUE_ALLY_CROWN_OUTER','Amount','30')",
        "('LOTM_RESCUE_CROWN_SELF_COMBAT_NEUTRALIZE270','Amount','-50')",
        "('LOTM_RESCUE_CROWN_SELF_INNER_RESTORE270','Amount','50')",
        "('LOTM_RESCUE_CROWN_SELF_OUTER_RESTORE270','Amount','50')",
        "('LOTM_RESCUE_ALLY_CROWN_COMBAT_NEUTRALIZE270','Amount','-30')",
        "('LOTM_RESCUE_ALLY_CROWN_INNER_RESTORE270','Amount','30')",
        "('LOTM_RESCUE_ALLY_CROWN_OUTER_RESTORE270','Amount','30')",
        "('LOTM_RESCUE_LETTER_GOLD','Amount','50')",
        "('LOTM_RESCUE_LETTER_PRODUCTION','Amount','-20')",
        "('LOTM_RESCUE_SCRIPTURE_PRODUCTION','Amount','60')",
        "('LOTM_RESCUE_SCRIPTURE_FOOD','Amount','-20')",
        "('LOTM_RESCUE_CROWN_SELF_INNER','Preview','LOC_LOTM_RESCUE_ARTIFACT_CROWN_SELF_PREVIEW')",
        "('LOTM_RESCUE_ALLY_CROWN_INNER','Preview','LOC_LOTM_RESCUE_ARTIFACT_CROWN_ALLY_PREVIEW')",
    )), "Resource 271 Weather/Crown/Letter/Scripture SQL is incomplete")
    check("local ordinaryLetter=not RescueActive()" in common and "if not RescueActive() and p~=nil" in common,
          "ordinary Conspirator war/peace Lua effects are not disabled in Rescue Mode")
    for token in ("LOC_LOTM_RESCUE_ARTIFACT_RP_LETTER_EFFECT", "LOC_LOTM_RESCUE_ARTIFACT_RP_SCRIPTURE_EFFECT"):
        check(token in artifact_screen and token in artifact_showcase and token in rescue_text,
              f"Rescue UI/text chain lacks {token}")
    check("UnitManager.CanStartOperation" in ui and "UnitManager.RequestCommand" in ui,
          "Ember UI lacks native probe and synchronized fallback")
    check(all(token in phase5 for token in (
        'Game.GetProperty("LOTM_RESCUE_ARTIFACT_FRENZY_ACTIVE")', "scaled=scaled-2", "scaled=scaled-3", "math.max(1,scaled)",
    )), "Frenzy Scepter is not applied after difficulty scaling in both final functions")
    check("CURRENT_EFFECT_VERSION=7" in monsters and "RESCUE_WEATHER_ABILITY" in monsters,
          "new and saved monsters do not reconcile the Weather ability")
    check(all(token in rescue for token in (
        "local function SortedAliveIDs()", "local function SortedAliveMajors()",
        "local function SortedUnits(player)",
        "for _,playerID in ipairs(SortedAliveIDs()) do",
        "for _,unit in ipairs(SortedUnits(player)) do",
        "for _,ai in ipairs(SortedAliveMajors()) do",
    )), "Rescue artifact synchronized Ability/Modifier reconciliation is not stably ordered")

    if args.database:
        source = sqlite3.connect(f"file:{args.database.resolve().as_posix()}?mode=ro", uri=True)
        db = sqlite3.connect(":memory:")
        source.backup(db)
        db.create_function("Make_Hash", 1, lambda value: zlib.crc32(str(value).encode("utf-8")))
        db.executescript(sql)
        check(db.execute("SELECT count(*) FROM LOTM_RescueArtifactLeases268").fetchone()[0] == 21,
              "database must contain 21 Rescue leases")
        check(not db.execute("PRAGMA foreign_key_check").fetchall(), "Rescue artifact SQL has foreign-key errors")
        check(db.execute(
            "SELECT count(*) FROM TypeTags WHERE Type='ABILITY_LOTM_RESCUE_WEATHER_MONSTER_DEBUFF' AND Tag='CLASS_ALL_COMBAT_UNITS'"
        ).fetchone()[0] == 1, "Weather ability must apply to every combat class")
        check(db.execute(
            "SELECT count(*) FROM TypeTags WHERE Type='ABILITY_LOTM_RESCUE_WEATHER_MONSTER_DEBUFF' AND Tag<>'CLASS_ALL_COMBAT_UNITS'"
        ).fetchone()[0] == 0, "Weather ability retained a narrower combat tag")
        for modifier_id, amount in (
            ("LOTM_RESCUE_LETTER_GOLD", "50"),
            ("LOTM_RESCUE_LETTER_PRODUCTION", "-20"),
            ("LOTM_RESCUE_SCRIPTURE_PRODUCTION", "60"),
            ("LOTM_RESCUE_SCRIPTURE_FOOD", "-20"),
            ("LOTM_RESCUE_CROWN_SELF_INNER", "50"),
            ("LOTM_RESCUE_CROWN_SELF_OUTER", "50"),
            ("LOTM_RESCUE_ALLY_CROWN_INNER", "30"),
            ("LOTM_RESCUE_ALLY_CROWN_OUTER", "30"),
        ):
            check(db.execute(
                "SELECT count(*) FROM ModifierArguments WHERE ModifierId=? AND Name='Amount' AND Value=?",
                (modifier_id, amount),
            ).fetchone()[0] == 1, f"database value mismatch for {modifier_id}")
        for excluded in (
            "LOTM_RESCUE_CROWN_SELF_COMBAT",
            "LOTM_RESCUE_CROWN_SELF_INNER_NEUTRALIZE268",
            "LOTM_RESCUE_CROWN_SELF_OUTER_NEUTRALIZE268",
        ):
            check(db.execute(
                "SELECT count(*) FROM LOTM_RescueArtifactModifiers268 WHERE ModifierId=?", (excluded,)
            ).fetchone()[0] == 0, f"new games would attach retired Resource 270 Crown modifier: {excluded}")
        for forbidden in (
            "LOTM_RP_ART_EMBER_FAST_PILLAGE_RESCUE268_POS",
            "LOTM_RP_ART_LETTER_PEACE_GOLD_RESCUE268_NEG",
            "LOTM_RP_ART_SCRIPTURE_PRODUCTION_RESCUE268_POS",
            "LOTM_RP_ART_SCRIPTURE_PEACE_PRODUCTION_RESCUE268_NEG",
            "LOTM_RP_ART_SCRIPTURE_WEARINESS_RESCUE268_POS",
            "LOTM_RP_ART_CROWN_ATTACK_DISTRICT_RESCUE268_POS",
            "LOTM_BE_ART_FRENZY_GOLD_FLAT_RESCUE268_NEG",
        ):
            check(db.execute("SELECT count(*) FROM Modifiers WHERE ModifierId=?", (forbidden,)).fetchone()[0] == 0,
                  f"retired Rescue modifier survived: {forbidden}")
    print("PASS: Resource 268 effects through Resource 271 evidence and attrition fixes")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
