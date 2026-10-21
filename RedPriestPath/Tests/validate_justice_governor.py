#!/usr/bin/env python3
"""Static gate for the normal-mode Justice governor integration."""

from __future__ import annotations

import sqlite3
import os
import sys
import zlib
import xml.etree.ElementTree as ET
from pathlib import Path

from luaparser import ast
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
GAME = Path("D:/app/steam/steamapps/common/Sid Meier's Civilization VI")


def check(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def main() -> None:
    db = sqlite3.connect(":memory:")
    for path in (
        GAME / "Base/Assets/Gameplay/Data/Schema/01_GameplaySchema.sql",
        GAME / "DLC/Expansion2/Data/Expansion2_Schema.sql",
        ROOT / "Gameplay/LOTM_JUSTICE_Governor.sql",
    ):
        db.executescript(path.read_text(encoding="utf-8-sig"))
    check(db.execute("SELECT count(*) FROM Governors WHERE GovernorType='GOVERNOR_LOTM_JUSTICE'").fetchone()[0] == 1,
          "Justice governor missing")
    check(db.execute("SELECT count(*) FROM GovernorPromotionSets WHERE GovernorType='GOVERNOR_LOTM_JUSTICE'").fetchone()[0] == 6,
          "Justice must have six promotions")
    check(db.execute("SELECT count(*) FROM GovernorPromotionPrereqs WHERE GovernorPromotionType='GOVERNOR_PROMOTION_LOTM_JUSTICE_STORY'").fetchone()[0] == 2,
          "Story must require both branches")
    check(db.execute("""SELECT count(*) FROM GovernorPromotionSets s
                        WHERE s.GovernorType='GOVERNOR_LOTM_JUSTICE'
                        AND NOT EXISTS (SELECT 1 FROM GovernorPromotionModifiers m
                                        WHERE m.GovernorPromotionType=s.GovernorPromotion)""").fetchone() == (0,),
          "every Justice promotion must have a row for Firaxis GovernorPanel")
    check(db.execute("SELECT InternalOnly FROM Buildings WHERE BuildingType='BUILDING_LOTM_JUSTICE_STORY_PAUSE'").fetchone() == (1,),
          "production pause marker must be internal")
    check(db.execute("SELECT InternalOnly FROM Buildings WHERE BuildingType='BUILDING_LOTM_JUSTICE_STORY_LEGACY_OFF'").fetchone() == (1,),
          "legacy suppression building must be internal")
    check(db.execute("""SELECT count(*) FROM RequirementArguments
                        WHERE RequirementId='LOTM_JUSTICE_REQUIRES_STORY_LEGACY_OFF'
                          AND Name='BuildingType' AND Value='BUILDING_LOTM_JUSTICE_STORY_LEGACY_OFF'""").fetchone() == (1,),
          "legacy production gate must require the never-created building")
    check(db.execute("""SELECT count(*) FROM Modifiers
                        WHERE ModifierId IN ('LOTM_JUSTICE_STORY_FREEZE', 'LOTM_JUSTICE_STORY_FREEZE_V2',
                                             'LOTM_JUSTICE_STORY_LEGACY_REPAIR_PLUS',
                                             'LOTM_JUSTICE_STORY_LEGACY_REPAIR_MINUS')
                          AND SubjectRequirementSetId='LOTM_JUSTICE_STORY_LEGACY_DISABLED'""").fetchone() == (4,),
          "all saved production modifiers must use the disabled requirement")
    check(db.execute("SELECT Value FROM ModifierArguments WHERE ModifierId='LOTM_JUSTICE_STORY_FREEZE' AND Name='Amount'").fetchone() == ('0',),
          "legacy governor-owned production penalty must be neutralized")
    check(db.execute("SELECT Value FROM ModifierArguments WHERE ModifierId='LOTM_JUSTICE_STORY_FREEZE_V2' AND Name='Amount'").fetchone() == ('0',),
          "second-generation production penalty must be neutralized")
    check(db.execute("SELECT count(*) FROM BuildingModifiers WHERE ModifierId='LOTM_JUSTICE_STORY_FREEZE_V2'").fetchone() == (0,),
          "internal building must not own a production penalty")
    check(db.execute("SELECT count(*) FROM GovernorPromotionModifiers WHERE ModifierId='LOTM_JUSTICE_STORY_FREEZE'").fetchone()[0] == 0,
          "legacy pause must not remain bound to Story promotion")
    for suffix, amount in (("PLUS", "0"), ("MINUS", "0")):
        check(db.execute("SELECT Value FROM ModifierArguments WHERE ModifierId=? AND Name='Amount'",
                         (f"LOTM_JUSTICE_STORY_LEGACY_REPAIR_{suffix}",)).fetchone() == (amount,),
              f"old-save repair {suffix.lower()} must be neutralized")
    for sign, factor in (("PLUS", 1), ("MINUS", -1)):
        for size in (1000, 10000):
            modifier = f"LOTM_JUSTICE_CACHE_{sign}_{size}"
            check(db.execute("SELECT Value FROM ModifierArguments WHERE ModifierId=? AND Name='Amount'",
                             (modifier,)).fetchone() == (str(factor * size),),
                  "cache counter amounts must remain immutable after saved-game attachment")
            check(db.execute("SELECT SubjectRequirementSetId FROM Modifiers WHERE ModifierId=?",
                             (modifier,)).fetchone() == (None,),
                  "cache correction must not later expire and recreate the saved corruption")
    for promotion, marker in (("COUNSEL", "COUNSEL"), ("TAROT", "TAROT"), ("STORY", "STORY")):
        check(db.execute("SELECT count(*) FROM GovernorPromotionModifiers WHERE GovernorPromotionType=? AND ModifierId=?",
                         (f"GOVERNOR_PROMOTION_LOTM_JUSTICE_{promotion}", f"LOTM_JUSTICE_{marker}_UI_MARKER")).fetchone()[0] == 1,
              f"{promotion} needs a zero-value UI marker for Firaxis GovernorPanel")
        check(db.execute("SELECT Value FROM ModifierArguments WHERE ModifierId=? AND Name='Amount'",
                         (f"LOTM_JUSTICE_{marker}_UI_MARKER",)).fetchone() == ('0',),
              f"{promotion} UI marker must have no yield effect")
    native_gold = db.execute("""
        SELECT m.ModifierId, m.ModifierType, a.Value
        FROM Modifiers m JOIN ModifierArguments a ON a.ModifierId=m.ModifierId
        WHERE m.ModifierId IN ('LOTM_JUSTICE_SPONSOR_GOLD_NATIVE_START',
                               'LOTM_JUSTICE_SPONSOR_GOLD_NATIVE_STOP')
          AND a.Name='Amount' ORDER BY m.ModifierId
    """).fetchall()
    check(native_gold == [
        ('LOTM_JUSTICE_SPONSOR_GOLD_NATIVE_START', 'MODIFIER_PLAYER_ADJUST_YIELD_CHANGE', '15'),
        ('LOTM_JUSTICE_SPONSOR_GOLD_NATIVE_STOP', 'MODIFIER_PLAYER_ADJUST_YIELD_CHANGE', '-15'),
    ], "Sponsor must balance native per-turn Gold with +15 and -15")
    check(db.execute("""SELECT count(*) FROM GovernorPromotionModifiers
                        WHERE GovernorPromotionType='GOVERNOR_PROMOTION_LOTM_JUSTICE_SPONSOR'
                          AND ModifierId='LOTM_JUSTICE_SPONSOR_GOLD'""").fetchone()[0] == 0,
          "retired city-scoped Sponsor gold must not double count")
    check(db.execute("""SELECT count(*) FROM GovernorPromotionModifiers
                        WHERE GovernorPromotionType='GOVERNOR_PROMOTION_LOTM_JUSTICE_SPONSOR'
                          AND ModifierId='LOTM_JUSTICE_SPONSOR_GOLD_PERCENT'""").fetchone()[0] == 1,
          "Sponsor city Gold percentage must remain attached")

    icons = ET.parse(ROOT / "Art/LOTM_JUSTICE_Icons.xml").getroot()
    definitions = {row.attrib['Name']: row.attrib['Atlas']
                   for row in icons.findall('./IconDefinitions/Row')}
    for kind in ('FILL', 'SLOT'):
        atlas = definitions[f'ICON_GOVERNOR_LOTM_JUSTICE_{kind}']
        check(atlas == f'ICON_ATLAS_LOTM_JUSTICE_BANNER_{kind}',
              f'city banner {kind.lower()} must use a separate circular atlas')
        for size in (22, 32):
            name = f'LOTM_JUSTICE_Banner{kind.title()}{size}.dds'
            row = icons.find(f"./IconTextureAtlases/Row[@Name='{atlas}'][@IconSize='{size}']")
            check(row is not None and row.attrib['Filename'] == name,
                  f'city banner {kind.lower()} {size}px atlas missing')
            image = Image.open(ROOT / 'Art' / name).convert('RGBA')
            check(image.size == (size, size) and image.getpixel((0, 0))[3] == 0,
                  f'city banner {kind.lower()} {size}px must have transparent corners')

    mod = ET.parse(ROOT / "RedPriestPath.modinfo").getroot()
    for language in ('zh_Hans_CN', 'en_US'):
        selected = (ROOT / 'Text/Selected' / f'LOTM_RP_Selected_{language}.xml').read_text(encoding='utf-8')
        check('LOC_GOVERNOR_LOTM_JUSTICE_NAME' not in selected,
              'Justice text must load only through its normal-mode UpdateText action')
    for action in mod.findall(".//*[@id]"):
        if action.attrib.get("id", "").startswith("LOTM_JUSTICE_"):
            check(action.attrib.get("criteria") == "LOTM_RP_EXPANSION_2",
                  f"Justice shared action is not Expansion2 gated: {action.attrib['id']}")
    for name in ("Scripts/LOTM_JUSTICE_Governor.lua", "UI/LOTM_JUSTICE_Story.lua"):
        source = (ROOT / name).read_text(encoding="utf-8")
        ast.parse(source)
    ui = (ROOT / "UI/LOTM_JUSTICE_Story.lua").read_text(encoding="utf-8")
    gameplay = (ROOT / "Scripts/LOTM_JUSTICE_Governor.lua").read_text(encoding="utf-8")
    check(":SetProperty(" not in ui and "UI.RequestPlayerOperation" in ui,
          "UI must submit synchronized commands rather than mutate state")
    check("RemoveBuilding" in gameplay and "CreateBuilding(marker.Index)" not in gameplay,
          "new story turns must never create a production pause marker")
    check("GetAt(" not in gameplay and "GetGovernorList(" not in gameplay,
          "Gameplay must not call UI-only governor or queue inspection methods")
    check("elseif count==6 then" in gameplay and "MigratePauseSource" in gameplay
          and "RetireLegacyRepair" in gameplay
          and 'AttachModifierByID("LOTM_JUSTICE_STORY_LEGACY_REPAIR_PLUS")' not in gameplay
          and 'AttachModifierByID("LOTM_JUSTICE_STORY_LEGACY_REPAIR_MINUS")' not in gameplay,
          "Story must remain seven turns and never create a repair modifier")
    check("GameEvents.LOTM_JUSTICE_UpdateGovernor.Add" in gameplay,
          "synchronized governor snapshot command missing")
    check("JUSTICE_STORY_LOAD_AUDIT_SERIAL" in gameplay and "JUSTICE_STORY_LOAD_AUDIT_SERIAL" in ui
          and "Events.LoadGameViewStateDone" in ui,
          "load audit must use a synchronized request and persistent acknowledgement")
    check("BUILDING_LOTM_JUSTICE_STORY_LEGACY_OFF" not in gameplay,
          "Gameplay must never construct the legacy suppression building")
    live_db = (Path(sys.argv[1]) if len(sys.argv)>1 else
               Path(os.environ["LOCALAPPDATA"]) / "Firaxis Games" /
               "Sid Meier's Civilization VI" / "Cache" / "DebugGameplay.sqlite")
    if live_db.is_file():
        old = sqlite3.connect(f"file:{live_db}?mode=ro", uri=True)
        upgraded = sqlite3.connect(":memory:")
        old.backup(upgraded)
        upgraded.create_function("Make_Hash", 1,
                                 lambda value: zlib.crc32(value.encode()) if value else 0)
        upgraded.execute("PRAGMA foreign_keys=ON")
        upgraded.executescript((ROOT / "Gameplay/LOTM_JUSTICE_Governor.sql").read_text(encoding="utf-8"))
        check(upgraded.execute("SELECT Value FROM ModifierArguments WHERE ModifierId='LOTM_JUSTICE_STORY_FREEZE' AND Name='Amount'").fetchone() == ('0',),
              "upgrade must neutralize a previously loaded -10000 freeze")
        check(upgraded.execute("SELECT count(*) FROM GovernorPromotionModifiers WHERE ModifierId='LOTM_JUSTICE_STORY_FREEZE'").fetchone() == (0,),
              "upgrade must remove an existing governor-owned freeze link")
        check(upgraded.execute("SELECT Value FROM ModifierArguments WHERE ModifierId='LOTM_JUSTICE_STORY_FREEZE_V2' AND Name='Amount'").fetchone() == ('0',),
              "upgrade must neutralize the second production freeze")
        check(upgraded.execute("SELECT count(*) FROM BuildingModifiers WHERE ModifierId='LOTM_JUSTICE_STORY_FREEZE_V2'").fetchone() == (0,),
              "upgrade must remove the building-owned freeze link")
        check(upgraded.execute("""SELECT count(*) FROM Modifiers m JOIN ModifierArguments a
                                  ON a.ModifierId=m.ModifierId AND a.Name='Amount'
                                  WHERE m.ModifierId IN ('LOTM_JUSTICE_STORY_LEGACY_REPAIR_PLUS',
                                                         'LOTM_JUSTICE_STORY_LEGACY_REPAIR_MINUS')
                                    AND m.SubjectRequirementSetId='LOTM_JUSTICE_STORY_LEGACY_DISABLED'
                                    AND a.Value='0'""").fetchone() == (2,),
              "upgrade must neutralize both saved positive and negative repair definitions")
        check(not upgraded.execute("PRAGMA foreign_key_check").fetchall(),
              "Justice database upgrade introduced foreign-key errors")
    print("PASS: Justice SQL, native Gold, circular banner, normal-mode gate, Lua syntax, and inert production pause")


if __name__ == "__main__":
    main()
