#!/usr/bin/env python3
"""Static contracts for the post-first-city Redemption difficulty choice."""

from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
errors: list[str] = []

def text(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")

def check(condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)

difficulty = text("Scripts/LOTM_RESCUE_Difficulty.lua")
phase5 = text("Scripts/LOTM_RESCUE_Phase5.lua")
phase9 = text("Scripts/LOTM_RESCUE_Phase9.lua")
gameplay = text("Scripts/LOTM_RP_Gameplay.lua")
ui = text("UI/LOTM_RESCUE_DifficultyChoice.lua")
xml = text("UI/LOTM_RESCUE_DifficultyChoice.xml")
modinfo = text("RedPriestPath.modinfo")
zh = text("Text/zh_Hans_CN/LOTM_RP_GameplayText.xml")
en = text("Text/en_US/LOTM_RP_GameplayText.xml")

ET.fromstring(xml)
for snippet in (
    'local VERSION=3;',
    'local DEFAULT_CHOICE="MADNESS";',
    'local PLAYER_CHOICE_PROPERTY="LOTM_RESCUE_DIFFICULTY_SAVED_CHOICE";',
    "NORMAL={SpawnPercent=50,CapPercent=50,AICombatCap=10}",
    "HARD={SpawnPercent=70,CapPercent=70,AICombatCap=12}",
    "MADNESS={SpawnPercent=100,CapPercent=100,AICombatCap=15}",
    'GameEvents.LOTM_RESCUE_Command_SelectDifficulty.Add(OnSelect)',
    'Game.SetProperty("LOTM_RESCUE_DIFFICULTY_DECIDED",1)',
    "table.sort(ids)",
    "player:GetCities():GetCount()>0",
    "playerID~=chooser",
    'function LOTM_RESCUE_Difficulty.RestorePersistentChoice()',
    'LOTM_RESCUE_DIFFICULTY_PERSISTED_CHOICE',
    'InferNumericChoice()',
    'recoveredChoice=persistedChoice or playerChoice',
    'rawChoice~=DEFAULT_CHOICE',
    'recovered legacy explicit choice=',
    'LOTM_MP_TurnSync.RunStartup(function() LOTM_RESCUE_Difficulty.RestorePersistentChoice(); end,"RescueDifficulty")',
):
    check(snippet in difficulty, f"difficulty Gameplay contract missing: {snippet}")

check('include("LOTM_RESCUE_Difficulty")' in gameplay, "difficulty authority is not included")
check(gameplay.index('include("LOTM_RESCUE_Difficulty")') < gameplay.index('include("LOTM_RESCUE_Phase5")'), "difficulty must load before Phase 5")
check(gameplay.index('include("LOTM_RESCUE_Difficulty")') < gameplay.index('include("LOTM_RESCUE_Phase9")'), "difficulty must load before Phase 9")
check("LOTM_RESCUE_Difficulty.SpawnPercent()" in phase5 and "LOTM_RESCUE_Difficulty.CapPercent()" in phase5, "Phase 5 does not scale attempts and cap")
for forbidden in ("MONSTER_CHANCE[", "MONSTER_PER_WORKSHOP[", "MONSTER_COOLDOWN[", "MONSTER_BURST["):
    # The fixed arrays remain, but the difficulty module itself must not mutate or scale them.
    check(forbidden not in difficulty, f"difficulty leaked into a forbidden monster parameter: {forbidden}")
check("LOTM_RESCUE_Difficulty.AICombatCap()" in phase9, "Phase 9 AI cap is not difficulty-driven")
check("aiProduction=50" in phase9 and "aiPurchaseDiscount=30" in phase9 and "aiPseudoYields=100" in phase9, "difficulty changed unrelated AI bonuses")

for snippet in (
    'player:GetCities():GetCount()>0',
    'player:GetProperty("LOTM_RP_PATH_DECIDED")',
    'UI.RequestPlayerOperation(id,PlayerOperations.EXECUTE_SCRIPT',
    'Controls.NormalIcon:SetIcon("ICON_LOTM_WORLD_MONSTER_MARK")',
    'Controls.HardIcon:SetIcon("ICON_LOTM_WORLD_MONSTER_MARK")',
    'Controls.MadnessIcon:SetIcon("ICON_LOTM_RESCUE_OUTER_GOD_STAR_MARK")',
    "0xFFFFFFFF",
    "0xFF1800B8",
):
    check(snippet in ui, f"difficulty UI contract missing: {snippet}")
check("SetProperty(" not in ui, "difficulty UI must not mutate synchronized Properties")
for control in ("NormalButton", "HardButton", "MadnessButton", "NormalIcon", "HardIcon", "MadnessIcon"):
    check(f'ID="{control}"' in xml, f"difficulty page lacks {control}")
for removed_control in ("LOC_LOTM_RESCUE_DIFFICULTY_NORMAL_DESC", "LOC_LOTM_RESCUE_DIFFICULTY_HARD_DESC", "LOC_LOTM_RESCUE_DIFFICULTY_MADNESS_DESC"):
    check(removed_control not in xml, f"difficulty page still renders numeric card description: {removed_control}")
check("if Active() then GameEvents.LOTM_RESCUE_Command_SelectDifficulty.Add(OnSelect); end" not in difficulty, "difficulty command registration still depends on load-time mode state")

check('id="LOTM_RESCUE_DIFFICULTY_CHOICE_UI_ADDIN" criteria="LOTM_RP_RESCUE_MODE"' in modinfo, "difficulty UI is not rescue-only")
for path in ("Scripts/LOTM_RESCUE_Difficulty.lua", "UI/LOTM_RESCUE_DifficultyChoice.lua", "UI/LOTM_RESCUE_DifficultyChoice.xml"):
    check(path in modinfo, f"modinfo missing {path}")
for tag in (
    "LOC_LOTM_RESCUE_DIFFICULTY_TITLE",
    "LOC_LOTM_RESCUE_DIFFICULTY_BODY",
    "LOC_LOTM_RESCUE_DIFFICULTY_NORMAL_NAME",
    "LOC_LOTM_RESCUE_DIFFICULTY_HARD_NAME",
    "LOC_LOTM_RESCUE_DIFFICULTY_MADNESS_NAME",
):
    check(tag in zh and tag in en, f"difficulty localization missing {tag}")
check("难度一经确认不可更改。" in zh, "Chinese difficulty page must keep only the requested immutable-choice notice")
for removed in ("疯狂者刷新频率", "AI战斗单位上限", "LOC_LOTM_RESCUE_DIFFICULTY_NORMAL_DESC", "LOC_LOTM_RESCUE_DIFFICULTY_HARD_DESC", "LOC_LOTM_RESCUE_DIFFICULTY_MADNESS_DESC"):
    check(removed not in zh and removed not in en, f"removed difficulty explanation remains: {removed}")

if errors:
    print(f"FAILED: {len(errors)} difficulty checks")
    for error in errors:
        print(f" - {error}")
    raise SystemExit(1)
print("PASS: Redemption difficulty choice contracts (first city, synchronized authority, exact scaling, existing icons)")
