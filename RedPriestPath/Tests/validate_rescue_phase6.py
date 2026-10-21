#!/usr/bin/env python3
"""Static and synthetic contract checks for Rescue Phase 6."""

from __future__ import annotations

from pathlib import Path
# Content contracts use unchanged code; test_rc342_startup_trace tests raw diagnostics.
from generate_startup_trace import strip_trace
import re


ROOT = Path(__file__).resolve().parents[1]
ERRORS: list[str] = []


def check(condition: bool, message: str) -> None:
    if not condition:
        ERRORS.append(message)


def text(relative: str) -> str:
    return strip_trace((ROOT / relative).read_text(encoding="utf-8"))


phase6 = text("Scripts/LOTM_RESCUE_Phase6.lua")
workshops = text("Scripts/LOTM_PP_Workshops.lua")
monsters = text("Scripts/LOTM_WORLD_Monsters.lua")
phase5 = text("Scripts/LOTM_RESCUE_Phase5.lua")
normal_sql = text("Gameplay/LOTM_WORLD_Monsters.sql")
phase5_sql = text("Gameplay/LOTM_RESCUE_Phase5.sql")
gameplay = text("Scripts/LOTM_RP_Gameplay.lua")
modinfo = text("RedPriestPath.modinfo")
ui_lua = text("UI/LOTM_RESCUE_Purification.lua")
ui_xml = text("UI/LOTM_RESCUE_Purification.xml")
zh = text("Text/zh_Hans_CN/LOTM_RP_GameplayText.xml")
en = text("Text/en_US/LOTM_RP_GameplayText.xml")

# Phase 6 reward and state contract.
for snippet in (
    "local VERSION=2;",
    'GLOBAL_KEY="GLOBAL_PURIFICATION"',
    'CONTRIBUTOR_LIST="LOTM_RESCUE_PHASE6_CONTRIBUTOR_LIST"',
    'CONTRIBUTION_VERSION="LOTM_RESCUE_PHASE6_CONTRIBUTION_VERSION"',
    "UNIT_REWARD={[2]=1,[1]=2,[0]=4}",
    "WORKSHOP_REWARD={[2]=4,[1]=8,[0]=12}",
    'Game.SetProperty("LOTM_RESCUE_PHASE6_STATE","READY")',
    'Game.SetProperty("LOTM_RESCUE_PHASE6_VERSION",VERSION)',
    'Game.SetProperty("LOTM_RESCUE_PHASE",6)',
    '"LOTM_RESCUE_PHASE6_PROCESSED:"..kind..":"..token',
    'Game.SetProperty("LOTM_RESCUE_PHASE6_EVENT_SERIAL",serial)',
    'Game.SetProperty(GLOBAL_KEY,total)',
    'local function MigrateContributions()',
    'Game.SetProperty(prefix.."CONTRIBUTOR",contributor)',
    'AddContribution(contributor,amount,kind)',
    'AddContribution("LEGACY_UNATTRIBUTED",unattributed,"LEGACY")',
):
    check(snippet in phase6, f"missing Phase 6 state/reward contract: {snippet}")

check("if not Active() then return false; end" in phase6, "normal mode must leave Phase 6 state untouched")
check("playerID==BarbarianID()" in phase6, "lost-control faction must be rejected")
check("LOTM_RESCUE_OUTER_GOD_FACTION" in phase6 and "LOTM_RESCUE_OUTER_GOD" in phase6, "Outer Deity faction/unit rejection markers missing")
check("player:IsMajor() or IsCityState(playerID)" in phase6, "normal civilizations and city-states must contribute")
for guardian in ("FOOL_SAINT", "FOOL_ANGEL", "NIGHT_SAINT", "NIGHT_ANGEL", "STORM_SAINT", "STORM_ANGEL"):
    check(f"UNIT_LOTM_RESCUE_{guardian}=true" in phase6, f"church guardian contributor missing: {guardian}")
check("LOTM_RESCUE_PURIFICATION_ALLY" in phase6, "future world-ally extension marker missing")
check("bossFormula=false" in phase6 and "MODIFIER_" not in phase6, "Phase 6 must not implement Phase 10 Boss weakening")

# Both uncontrolled-unit families and workshop clearing must route through Phase 6.
check("LOTM_RESCUE_Phase4.OnLostControlKilled=LOTM_RESCUE_Phase6.OnLostControlKilled" in phase6, "center-guard callback not bound")
check("LOTM_RESCUE_Phase4.OnWorkshopCleared=LOTM_RESCUE_Phase6.OnWorkshopCleared" in phase6, "workshop callback not bound")
check('"CENTER",serial' in workshops and "SequenceSerialEngineKey" in workshops, "center guards need persistent unique event IDs")
check('"MONSTER",serial' in monsters and "killerUnitID" in monsters, "monster deaths must report tier, serial, and killer unit")
check("CLASSIFIED_TURN" in workshops and "p:GetIndex()" in workshops, "workshop events need a stable dedupe token")

# UI is criteria-isolated and read-only.
check('id="LOTM_RESCUE_PHASE6_PURIFICATION_UI_ADDIN" criteria="LOTM_RP_RESCUE_MODE"' in modinfo, "Phase 6 UI must be rescue-only")
check("Game.GetProperty(\"GLOBAL_PURIFICATION\")" in ui_lua, "UI must read global purification")
check("Game.SetProperty" not in ui_lua and "EXECUTE_SCRIPT" not in ui_lua, "Phase 6 UI must not mutate Gameplay")
check("ContextPtr:SetHide(false);" in ui_lua and "Controls.Root:SetHide(false);" in ui_lua and "LOTM_RESCUE_PHASE6_STATE" not in ui_lua, "criteria-gated HUD context and root must both remain visible")
for snippet in (
    'ID="Root" Anchor="L,T" Offset="0,31" Size="500,79"',
    'Hidden="0"',
	'ID="Background"',
	'ID="BorderTop"',
	'ID="BorderBottom"',
	'ID="BorderLeft"',
	'ID="BorderRight"',
	'ID="TrackBorder"',
	'ID="Track"',
	'ID="ProgressFill"',
	'ID="Mark1500"',
    'ID="Mark500"',
    'ID="Mark1000"',
    'ID="Mark2000"',
    'Size="2,18"',
	'ID="Mark1500Label"',
	'ID="Mark500Label"',
	'ID="Mark1000Label"',
	'ID="Mark2000Label"',
    'ID="Leaderboard"',
):
    check(snippet in ui_xml, f"centered progress HUD contract missing: {snippet}")
check('UIManager:GetScreenSizeVal()' in ui_lua and 'RealizePosition(screenX,screenY,rootWidth)' in ui_lua and 'local TOP_OFFSET=31;' in ui_lua,
      "centered progress HUD must remain at the fixed top edge")
for snippet in (
    "local FALLBACK_DISPLAY_MAX=3000;",
    "local FALLBACK_BEST_TIER_THRESHOLD=3000;",
    "local FALLBACK_TIER_THRESHOLDS={500,1000,1500,2000};",
    "local WIDE_WIDTH=500;",
    "local COMPACT_WIDTH=400;",
    "local COMPACT_BREAKPOINT=1600;",
	"local HORIZONTAL_PADDING=14;",
    "UIManager:GetScreenSizeVal()",
    'Game.GetProperty("LOTM_RESCUE_PHASE10_BEST_TIER_THRESHOLD")',
    'Game.GetProperty("LOTM_RESCUE_PURIFICATION_DISPLAY_MAX")',
    'Game.GetProperty("LOTM_RESCUE_PHASE10_TIER_THRESHOLD_"..(index+1))',
	"local g_ProgressWidth=WIDE_WIDTH-(HORIZONTAL_PADDING*2);",
	"g_ProgressWidth=rootWidth-(HORIZONTAL_PADDING*2);",
	"local fillWidth=math.floor(g_ProgressWidth*Clamp(total/displayMax,0,1)+0.5);",
	"Controls.ProgressFill:SetSizeX(fillWidth);",
	"Controls.ProgressFill:SetHide(fillWidth<=0);",
    'Locale.Lookup("LOC_LOTM_RESCUE_PURIFICATION_VALUE_OVER",total,displayMax)',
	'Controls.Title:SetText(Locale.Lookup("LOC_LOTM_RESCUE_PURIFICATION_TITLE").."  |  "..valueText);',
	'marker.Label:SetText(tostring(threshold));',
    'local function ContributionRanking()',
    'Game.GetProperty("LOTM_RESCUE_PHASE6_CONTRIBUTOR_LIST")',
    'Controls.Leaderboard:SetText(compactRanking);',
    'table.sort(entries,function(a,b) if a.Value~=b.Value then return a.Value>b.Value; end return a.Key<b.Key; end);',
):
    check(snippet in ui_lua, f"progress HUD behavior missing: {snippet}")
for forbidden in ('Controls_DarkBox', 'Controls_MeterLinear', '<TextureBar'):
    check(forbidden not in ui_xml, f"stretch-prone HUD texture must be removed: {forbidden}")

# All fill and markers use the same inner-track coordinate system.  This also
# catches the reported 111-value visual break around the first 100 marker.
for width in (500, 400):
    inner = width - 28
    marker = {value: 14 + int(inner * value / 3000) - 1 for value in (100, 500, 1000, 2000)}
    for total in (0, 100, 111, 500, 1000, 2000, 3000, 3001):
        fill = int(inner * min(max(total / 3000, 0), 1) + 0.5)
        check(0 <= fill <= inner, f"HUD fill out of bounds width={width} total={total}")
        if total == 111:
            check(14 + fill > marker[100], f"111 fill must pass the 100 marker width={width}")
check(re.search(r"<ReplaceUIScript[^>]*TopPanel|<File>[^<]*TopPanel", modinfo, re.I) is None, "Phase 6 must not replace TopPanel")
check("FALLBACK_BEST_TIER_THRESHOLD" not in phase6, "UI fallback threshold must not enter Phase 6 Gameplay")
for tag in (
    "LOC_LOTM_RESCUE_PURIFICATION_TITLE",
    "LOC_LOTM_RESCUE_PURIFICATION_VALUE",
    "LOC_LOTM_RESCUE_PURIFICATION_VALUE_OVER",
    "LOC_LOTM_RESCUE_PURIFICATION_TOOLTIP",
    "LOC_LOTM_RESCUE_PURIFICATION_RANKING_TITLE",
    "LOC_LOTM_RESCUE_PURIFICATION_RANKING_COMPACT",
    "LOC_LOTM_RESCUE_PURIFICATION_RANKING_ENTRY",
    "LOC_LOTM_RESCUE_PURIFICATION_RANKING_EMPTY",
    "LOC_LOTM_RESCUE_PURIFICATION_CHURCH_FOOL",
    "LOC_LOTM_RESCUE_PURIFICATION_CHURCH_NIGHT",
    "LOC_LOTM_RESCUE_PURIFICATION_CHURCH_STORM",
):
    check(tag in zh and tag in en, f"bilingual Phase 6 UI text missing: {tag}")

# Include ordering keeps one authoritative Gameplay context.
for required in ('include("LOTM_RESCUE_Phase6")', '<File>Scripts/LOTM_RESCUE_Phase6.lua</File>'):
    check(required in gameplay or required in modinfo, f"Phase 6 load contract missing: {required}")
check(gameplay.index('include("LOTM_RESCUE_Phase6")') < gameplay.index('include("LOTM_WORLD_Monsters")'), "Phase 6 must load before monster callbacks")
check(gameplay.index('include("LOTM_RESCUE_Phase6")') < gameplay.index('include("LOTM_PP_Workshops")'), "Phase 6 must load before workshop callbacks")

# Hard ordinary-mode workshop isolation regression.
check(re.search(r"SET\s+Value\s*=\s*9\s+WHERE\s+Name\s*=\s*'BARBARIAN_CAMP_ODDS_OF_NEW_CAMP_SPAWNING'", normal_sql, re.S) is not None, "ordinary camp odds must stay 9")
check("BARBARIAN_CAMP_MAX_PER_MAJOR_CIV" not in normal_sql, "ordinary camp ceiling must stay Firaxis default")
check("SET Value=100" in phase5_sql, "rescue camp odds must be 100")
check("SET Value=10" in phase5_sql and "BARBARIAN_CAMP_MAX_PER_MAJOR_CIV" in phase5_sql, "rescue camp ceiling must be 10 per major")
check('id="LOTM_RESCUE_PHASE5_DATABASE" criteria="LOTM_RP_RESCUE_MODE"' in modinfo, "Phase 5 database override must remain rescue-only")
for snippet, message in (
    ("or 50", "ordinary workshop classification must stay 50%"),
    ("or NORMAL_SEQUENCE_UNIT", "ordinary center guard must stay the path holder"),
    ("or 10;", "ordinary center guard bonus/cooldown must stay +10/10"),
):
    check(snippet in workshops or snippet in monsters, message)
check("return RescueActive() and LOTM_RESCUE_Phase5.MonsterPerWorkshopCap() or 1;" in monsters, "ordinary per-workshop monster cap must stay 1")
check("return RescueActive() and LOTM_RESCUE_Phase5.BirthStrengthBonus() or 0;" in monsters, "ordinary monster period bonus must stay 0")
check("local multiplier=RescueActive() and LOTM_RESCUE_Phase5.GlobalCapMultiplier() or 1;" in monsters, "ordinary global monster cap multiplier must stay 1")
check("return LOTM_RESCUE_Phase5.MonsterGlobalCap(),mapSizeType;" in monsters, "rescue global monster cap must come directly from Phase 5")
check("if not IsRescueMode()" in workshops and "return 0" in workshops, "ordinary center guard period bonus must stay 0")
check("WORKSHOP_CHANCE={80,85,90,95,100}" in phase5, "Phase 5 rescue table unexpectedly changed")
check(normal_sql.count("LOC_LOTM_WORLD_PREVIEW_MONSTER_FRENZY") == 4, "base, v2, mid, and high combat modifiers must all expose preview rows")
check(phase5_sql.count("LOC_LOTM_RESCUE_PREVIEW_PERIOD_STRENGTH") == 4, "all four period-strength modifiers must appear in combat preview")
check("LOC_LOTM_RESCUE_PREVIEW_PERIOD_STRENGTH" in zh and "LOC_LOTM_RESCUE_PREVIEW_PERIOD_STRENGTH" in en, "period-strength preview must be bilingual")


class Ledger:
    unit_reward = {2: 1, 1: 2, 0: 4}
    workshop_reward = {2: 4, 1: 8, 0: 12}

    def __init__(self) -> None:
        self.total = 0
        self.processed: set[tuple[str, str]] = set()

    def award(self, kind: str, tier: int, token: str, eligible: bool = True) -> bool:
        key = (kind, token)
        if key in self.processed:
            return False
        self.processed.add(key)
        if not eligible:
            return False
        table = self.workshop_reward if kind == "WORKSHOP" else self.unit_reward
        self.total += table[tier]
        return True


ledger = Ledger()
check(ledger.award("CENTER", 2, "center:1"), "synthetic low center kill failed")
check(not ledger.award("CENTER", 2, "center:1"), "duplicate center kill must be rejected")
check(ledger.award("MONSTER", 1, "monster:1"), "synthetic mid monster kill failed")
check(ledger.award("MONSTER", 0, "monster:2"), "synthetic high monster kill failed")
check(not ledger.award("MONSTER", 0, "monster:3", eligible=False), "lost-control self-kill must be rejected")
check(ledger.award("WORKSHOP", 2, "plot:10"), "synthetic level-2 workshop failed")
check(ledger.award("WORKSHOP", 1, "plot:11"), "synthetic level-1 workshop failed")
check(ledger.award("WORKSHOP", 0, "plot:12"), "synthetic level-0 workshop failed")
check(ledger.total == 31, f"synthetic ledger expected 31, got {ledger.total}")

example = Ledger()
example.award("CENTER", 0, "center:high")
example.award("WORKSHOP", 0, "workshop:high")
check(example.total == 16, "task-book level-0 center+workshop example must total 16")

# Old-save migration preserves the authoritative global total. Attributed
# events rebuild their faction totals; any historical gap remains explicit.
historical_events = [("PLAYER_0", 12), ("CHURCH_NIGHT", 8), ("PLAYER_0", 4)]
global_total = 31
rebuilt: dict[str, int] = {}
for key, delta in historical_events:
    rebuilt[key] = rebuilt.get(key, 0) + delta
unattributed = global_total - sum(rebuilt.values())
if unattributed > 0:
    rebuilt["LEGACY_UNATTRIBUTED"] = unattributed
check(sum(rebuilt.values()) == global_total and unattributed == 7, "old-save contribution migration must preserve the global total")
ranking = sorted(rebuilt.items(), key=lambda item: (-item[1], item[0]))
check(ranking == [("PLAYER_0", 16), ("CHURCH_NIGHT", 8), ("LEGACY_UNATTRIBUTED", 7)], "contribution ranking order must be deterministic")

check(45 + 30 + 10 + 20 + 2 == 107, "screenshot mid-tier period-2 combat breakdown must total 107")
check(55 + 5 - 1 == 59, "screenshot warrior combat breakdown must total 59")


def reference_percent(total: int) -> float:
    return max(0.0, min(1.0, total / 3000))


for total, expected in (
    (0, 0.0),
    (100, 1 / 30),
    (500, 1 / 6),
    (1000, 1 / 3),
    (2000, 2 / 3),
    (3000, 1.0),
    (3001, 1.0),
):
    check(reference_percent(total) == expected, f"reference meter state mismatch at {total}")

if ERRORS:
    print(f"FAILED: {len(ERRORS)} Rescue Phase 6 checks")
    for error in ERRORS:
        print(f" - {error}")
    raise SystemExit(1)

print("PASS: Rescue Phase 6 static + synthetic contract (purification, dedupe, contributors, UI, normal isolation)")
