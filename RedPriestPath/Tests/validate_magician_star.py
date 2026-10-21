"""Check the two normal-mode governors against the current game database."""

from pathlib import Path
import os
import sqlite3
import sys
import xml.etree.ElementTree as ET
import zlib

from luaparser import ast
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
DB = (Path(sys.argv.pop(1)) if len(sys.argv)>1 and not sys.argv[1].startswith('-')
      else Path(os.environ["LOCALAPPDATA"]) / "Firaxis Games" /
      "Sid Meier's Civilization VI" / "Cache" / "DebugGameplay.sqlite")


def need(condition, message):
    if not condition:
        raise AssertionError(message)


def main():
    source = sqlite3.connect(f"file:{DB}?mode=ro", uri=True)
    db = sqlite3.connect(":memory:")
    source.backup(db)
    db.create_function("Make_Hash", 1, lambda value: zlib.crc32(value.encode()) if value else 0)
    db.execute("PRAGMA foreign_keys=ON")
    db.executescript((ROOT / "Gameplay/LOTM_MS_Governors.sql").read_text(encoding="utf-8"))

    governors = dict(db.execute("SELECT GovernorType,TransitionStrength FROM Governors "
                                "WHERE GovernorType IN ('GOVERNOR_LOTM_MAGICIAN','GOVERNOR_LOTM_STAR')"))
    need(governors == {"GOVERNOR_LOTM_MAGICIAN": 100000, "GOVERNOR_LOTM_STAR": 100},
         "governor rows or transition settings missing")
    for name in governors:
        need(db.execute("SELECT count(*) FROM GovernorPromotionSets WHERE GovernorType=?",
                        (name,)).fetchone()[0] == 6, f"{name} must have six promotions")
        need(db.execute("""SELECT count(*) FROM GovernorPromotionSets s WHERE s.GovernorType=?
                           AND NOT EXISTS (SELECT 1 FROM GovernorPromotionModifiers m
                                           WHERE m.GovernorPromotionType=s.GovernorPromotion)""",
                        (name,)).fetchone()[0] == 0,
             f"{name} must not show Firaxis <NOT IMPLEMENTED> in the governor UI")
    for name in ("GOVERNOR_PROMOTION_LOTM_MAGICIAN_BESTSELLER",
                 "GOVERNOR_PROMOTION_LOTM_STAR_GUARDIAN"):
        need(db.execute("SELECT count(*) FROM GovernorPromotionPrereqs WHERE GovernorPromotionType=?",
                        (name,)).fetchone()[0] == 2, f"{name} requires both branches")

    def args(modifier):
        return dict(db.execute("SELECT Name,Value FROM ModifierArguments WHERE ModifierId=?",
                               (modifier,)))

    for yield_type, modifier in (("YIELD_FOOD", "LOTM_MS_SUPPLY_FOOD"),
                                 ("YIELD_PRODUCTION", "LOTM_MS_SUPPLY_PRODUCTION")):
        need(args(modifier) == {"YieldType": yield_type, "Amount": "3", "Domestic": "1"},
             f"{modifier} must be a native domestic destination route bonus")
    need(args("LOTM_MS_REPLAY_PROMOTION")["Amount"] == "-1",
         "free promotion must use Victor's native sentinel")
    need(args("LOTM_MS_STAR_LOCAL_SPY")["Amount"] == "2" and
         args("LOTM_MS_GUARDIAN_PLAYER417")["Amount"] == "3", "spy defense tiers changed")
    need(db.execute("SELECT Inverse FROM Requirements WHERE RequirementId='LOTM_MS_REQ_NO_GUARDIAN'").fetchone() == (1,),
         "local -2 must turn off with empire -3")
    need(args("LOTM_MS_STAR_CONTACT")["Amount"]=="0" and args("LOTM_MS_STAR_EMPIRE_SPY")["Amount"]=="0",
         "legacy city-owned global modifiers must be inert")
    need(args("LOTM_MS_CONTACT_PLAYER417")["Amount"]=="1" and
         args("LOTM_MS_COUNTERSPY_PLAYER417")=={"Offense":"0","Amount":"2"},
         "native player visibility and defensive spy bonus required")
    need(args("LOTM_MS_CONTACT_PLAYER419")==args("GREATPERSON_DIPLO_VISIBILITY"),
         "visibility must use the exact base-game amount and recognized source")
    need(db.execute("SELECT OwnerRequirementSetId FROM Modifiers WHERE ModifierId='LOTM_MS_CONTACT_PLAYER419'").fetchone()[0]
         =="LOTM_MS_CONTACT_NATIVE419_SET", "new visibility must not reactivate the retired gate")
    for name in ("CONTACT", "GUARDIAN", "COUNTERSPY"):
        need(db.execute("SELECT OwnerRequirementSetId FROM Modifiers WHERE ModifierId=?",
                        (f"LOTM_MS_{name}_PLAYER417",)).fetchone()[0] is not None,
             "player attachment must have a reversible owner resource gate")
    for target, kind, argument in (("BUILDING_LIBRARY", "B", "BuildingType"),
                                   ("DISTRICT_CAMPUS", "D", "DistrictType")):
        for sign, amount in (("POS", "50"), ("NEG", "-50")):
            data = args(f"LOTM_MS_RECORD_{kind}_{sign}_{target}")
            need(data.get(argument) == target and data.get("Amount") == amount,
                 f"history modifier for {target} must be target specific and reversible")
    need(db.execute("SELECT count(*) FROM RequirementSetRequirements "
                    "WHERE RequirementSetId='LOTM_MS_PATROL_ELIGIBLE'").fetchone()[0] > 0,
         "recon whitelist must use current ruleset")
    need(db.execute("SELECT count(*) FROM RequirementSetRequirements "
                    "WHERE RequirementId LIKE '%UNIT_LOTM_%'").fetchone()[0] == 0,
         "Path holders must be excluded from ordinary birth whitelists")
    for promotion, modifier in (
        ("GOVERNOR_PROMOTION_LOTM_MAGICIAN_RECORD", "LOTM_MS_RECORD_UI_MARKER"),
        ("GOVERNOR_PROMOTION_LOTM_STAR_INTERROGATION", "LOTM_MS_INTERROGATION_UI_MARKER"),
    ):
        need(db.execute("SELECT count(*) FROM GovernorPromotionModifiers WHERE GovernorPromotionType=? AND ModifierId=?",
                        (promotion, modifier)).fetchone()[0] == 1,
             f"{promotion} requires a Firaxis UI marker")
        need(args(modifier).get("Amount") == "0", f"{modifier} must not grant a yield")

    mod = ET.parse(ROOT / "RedPriestPath.modinfo").getroot()
    for node in mod.findall(".//*[@id]"):
        if node.get("id", "").startswith("LOTM_MS_"):
            need(node.get("criteria") == "LOTM_RP_EXPANSION_2",
                 f"{node.get('id')} must be shared Expansion2 gated")
    for name in ("Scripts/LOTM_MS_Governors.lua", "UI/LOTM_MS_Governors.lua"):
        ast.parse((ROOT / name).read_text(encoding="utf-8"))
    for language in ("zh_Hans_CN", "en_US"):
        text = ET.parse(ROOT / "Text" / language / "LOTM_MS_Text.xml")
        need(len(text.getroot().findall("./LocalizedText/Row")) == 32,
             f"{language} text must have 32 tags")
        selected = (ROOT / "Text/Selected" / f"LOTM_RP_Selected_{language}.xml").read_text(encoding="utf-8")
        need("LOC_GOVERNOR_LOTM_MAGICIAN_NAME" not in selected,
             "normal-only text must not be in the shared selected pack")
    icons = ET.parse(ROOT / "Art/LOTM_MS_Icons.xml").getroot()
    need(len(icons.findall("./IconDefinitions/Row")) == 8,
         "both governors need portrait and circular banner icons")
    for name in ("Fors", "Leonard"):
        for kind in ("Fill", "Slot"):
            for size in (22, 32):
                image = Image.open(ROOT / "Art" / f"LOTM_MS_{name}Banner{kind}{size}.dds").convert("RGBA")
                need(image.size == (size, size) and image.getpixel((0, 0))[3] == 0,
                     f"{name} {kind} {size}px banner must have transparent corners")
    print("PASS: Magician/Star SQL, routing, art, text and modifier contracts")


if __name__ == "__main__":
    main()
