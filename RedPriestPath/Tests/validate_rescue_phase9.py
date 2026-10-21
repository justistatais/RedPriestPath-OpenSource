#!/usr/bin/env python3
"""Static contracts for Rescue Phase 9 player overrides and AI buildup."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
errors: list[str] = []


def text(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


def check(condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)


sql = text("Gameplay/LOTM_RESCUE_Phase9.sql")
lua = text("Scripts/LOTM_RESCUE_Phase9.lua")
gameplay = text("Scripts/LOTM_RP_Gameplay.lua")
modinfo = text("RedPriestPath.modinfo")
lifecycle = text("Scripts/LOTM_RP_Lifecycle.lua")
advanced = text("Scripts/LOTM_RP_Advanced.lua")
arson = text("Scripts/LOTM_RP_Arson.lua")
hud = text("UI/LOTM_RP_HUD.lua")
zh_text = text("Text/zh_Hans_CN/LOTM_RP_GameplayText.xml")
en_text = text("Text/en_US/LOTM_RP_GameplayText.xml")

for snippet in (
    "local VERSION=9;",
    "local function AICombatCap()",
    "LOTM_RESCUE_Difficulty.AICombatCap()",
    "local COMBAT_INDEX_MIGRATION_VERSION=1;",
    'local COMBAT_INDEX_MIGRATION_KEY="LOTM_RESCUE_PHASE9_COMBAT_INDEX_MIGRATION_VERSION";',
    "local function IsCombatUnit(unit)",
    "local function CombatIndex(playerID)",
    "local AddIndexedUnit;",
    "AddIndexedUnit=function(playerID,unit)",
    "local function RemoveIndexedUnit(playerID,unitID)",
    "local function EnforceIndexedAICombatCap(player,preferredRetireID)",
    "local function MigrateCombatIndex(player)",
    "pcall(UnitManager.Kill,unit)",
    'player:SetProperty("LOTM_RESCUE_PHASE9_AI_COMBAT_CAP",cap)',
    "EnforceIndexedAICombatCap(player,unitID)",
    "Events.UnitRemovedFromMap.Add(OnUnitRemoved)",
    'Game.SetProperty("LOTM_RESCUE_PHASE9_STATE","READY")',
    'Game.SetProperty("LOTM_RESCUE_PHASE",9)',
    '"LOTM_RESCUE_PHASE9_DIVINE_LEGION_STATE","RESERVED_FOR_PHASE10"',
    '"LOTM_RESCUE_PHASE9_RP_MAINTENANCE_MODE",sequence<=6 and "FIXED_MINUS_2"',
    'Game.SetProperty("LOTM_RESCUE_PHASE9_ARSON_DAMAGE",70)',
    'player==nil or not player:IsAlive() or not player:IsMajor() or player:IsHuman()',
):
    check(snippet in lua, f"Phase 9 Lua contract missing: {snippet}")

expected_arguments = (
    "('LOTM_RESCUE_P9_AI_MILITARY_PRODUCTION','Amount','50')",
    "('LOTM_RESCUE_P9_AI_MILITARY_PURCHASE','Amount','30')",
    "('LOTM_RESCUE_P9_AI_MILITARY_PURCHASE','IncludeCivilian','false')",
    "('LOTM_RESCUE_P9_RP_S6_MILITARY_PURCHASE','Amount','50')",
    "('LOTM_RESCUE_P9_RP_S6_MAINTENANCE','Amount','2')",
    "('LOTM_RESCUE_P9_RP_S3_PRODUCTION','Amount','100')",
    "('LOTM_RESCUE_P9_RP_S2_STRENGTH','Amount','30')",
    "('LOTM_RESCUE_P9_RP_S2_MOVEMENT','Amount','3')",
    "('LOTM_RESCUE_P9_RP_S1_EXTRA_ATTACK_EFFECT','Amount','1')",
    "('LOTM_RESCUE_P9_RP_S0_PRODUCTION','Amount','800')",
)
for snippet in expected_arguments:
    check(snippet in sql, f"Phase 9 SQL value missing: {snippet}")

check('AttachOnce(player,"LOTM_RESCUE_P9_AI_MILITARY_PURCHASE","LOTM_RESCUE_PHASE9_AI_PURCHASE_ATTACHED")' in lua and '-- AttachOnce(player,"LOTM_RESCUE_P9_AI_MILITARY_PURCHASE"' not in lua, "AI purchase discount attachment must be active")
check("aiProduction=50 aiPurchaseDiscount=30 aiPseudoYields=100 aiWallBuildings=BUILDING_WALLS/BUILDING_CASTLE/BUILDING_STAR_FORT aiCityDefensePseudoYield=100 aiCombatCap=difficulty10/12/15 combatIndex=incremental fullScan=migrationOnly overflowPolicy=retireNewest" in lua, "Phase 9 load diagnostics must report restored military pressure, wall preference and the difficulty-driven combat cap")
sorted_units_body = lua.split("local function SortedUnits(player)", 1)[1].split("local function AliveMajors", 1)[0]
check("player:GetUnits():Members()" in sorted_units_body
      and "table.sort(result,function(a,b) return a:GetID()<b:GetID(); end)" in sorted_units_body,
      "Phase 9 migration full scans must normalize units by UnitID")
check(lua.count("player:GetUnits():Members()") == 1
      and lua.count("SortedUnits(player)") == 3,
      "Phase 9 full scans must be centralized and limited to legacy-ability and combat-index migrations")
migration_body = lua.split("local function MigrateCombatIndex", 1)[1].split("local function ReconcileAI", 1)[0]
unit_added_body = lua.split("local function OnUnitAdded", 1)[1].split("local function OnUnitRemoved", 1)[0]
turn_body = lua.split("local function OnTurn", 1)[1].split("local function OnUnitAdded", 1)[0]
check("SortedUnits(player)" in migration_body, "Phase 9 old-save combat index migration lost its one-time sorted full scan")
check("SortedUnits(" not in unit_added_body and "MigrateCombatIndex" not in unit_added_body, "Phase 9 unit additions must remain incremental")
check("SortedUnits(" not in turn_body and "MigrateCombatIndex" not in turn_body, "Phase 9 normal turn handling must not full-scan the army")

network_processor = lua.split("local function ProcessNetworkUnitAdditions", 1)[1].split("local function ReconcileLegacy", 1)[0]
network_branch = unit_added_body.split("if LOTM_MP_TurnSync.IsNetworkGame() then", 1)[1].split("return;", 1)[0]
unit_removed_body = lua.split("local function OnUnitRemoved", 1)[1].split('LOTM_MP_TurnSync.Add(OnTurn,"RescuePhase9")', 1)[0]
reconcile_body = lua.split("function LOTM_RESCUE_Phase9.ReconcileAll()", 1)[1].split("local function OnTurn", 1)[0]
check("QueueNetworkUnitAdded(playerID,unitID);" in network_branch
      and all(token not in network_branch for token in (
          "ChangeAbilityCount(", "AttachModifierByID(", ":SetProperty(",
          "Game.SetProperty(", "UnitManager.Kill(", "UnitManager.InitUnit(",
      )), "Phase 9 network UnitAdded must only queue a Lua-local identity")
check(all(token in network_processor for token in (
          "LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID)",
          "entry.QueuedTurn<currentTurn", "table.sort(ready,function(a,b)",
          "a.PlayerID~=b.PlayerID", "a.UnitID<b.UnitID",
          "RetireLegacyConquestAbilityFromUnit(player,unit)",
          "AddIndexedUnit(entry.PlayerID,unit)",
      )), "Phase 9 network additions must cross a turn and settle in stable player/unit order")
check("ProcessNetworkUnitAdditions(playerID);" in turn_body
      and "entry.Cancelled=true;" in unit_removed_body
      and "pendingNetworkUnitKeys[key]=nil" in unit_removed_body
      and "RemoveIndexedUnit(playerID,unitID);" in unit_removed_body,
      "Phase 9 turn/removal handlers must drain and cancel the local addition index incrementally")
check("for _,player in ipairs(AliveMajors())" in reconcile_body
      and "table.sort(result,function(a,b) return a:GetID()<b:GetID(); end)" in lua.split("local function AliveMajors", 1)[1].split("local function AttachOnce", 1)[0],
      "Phase 9 startup reconciliation must sort major players before migration writes")
check('Number(player:GetProperty("LOTM_RESCUE_PHASE9_LEGACY_CONQUEST_RETIRED"),0)==1' in lua, "legacy conquest cleanup must be one-time gated")
check("-- ('LOTM_RESCUE_P9_AI_MILITARY_PRODUCTION','Amount','100')" in sql, "former +100% production value must remain commented for possible re-enable")
check("-- ('LOTM_RESCUE_P9_AI_MILITARY_PURCHASE','Amount','50')" in sql, "former purchase discount must remain commented as history")
check('AttachOnce(player,"LOTM_RESCUE_P9_AI_MILITARY_PURCHASE","LOTM_RESCUE_PHASE9_AI_PURCHASE_ATTACHED")' in lua, "AI military Gold purchase discount is not attached")

for pseudo_yield in (
    "PSEUDOYIELD_UNIT_COMBAT",
    "PSEUDOYIELD_UNIT_NAVAL_COMBAT",
    "PSEUDOYIELD_UNIT_AIR_COMBAT",
):
    check(pseudo_yield in sql, f"AI buildup misses {pseudo_yield}")
    check(f"'{pseudo_yield}',1,100" in sql, f"AI military inclination must be 100 for {pseudo_yield}")
for wall_building in ("BUILDING_WALLS", "BUILDING_CASTLE", "BUILDING_STAR_FORT"):
    check(f"'LOTM_RESCUE_P9_MAJOR_WALL_BUILDINGS','{wall_building}',1,0" in sql, f"AI wall preference misses {wall_building}")
check("LOTM_RESCUE_P9_MAJOR_CITY_DEFENSE_PSEUDOYIELDS" in sql and "'PSEUDOYIELD_CITY_DEFENSES',1,100" in sql, "AI city-defense pseudo-yield preference is missing")
check('LOTM_RESCUE_PHASE9_AI_WALL_PREFERENCE' in lua and 'wall preference enabled player=' in lua, "Phase 9 runtime wall preference diagnostic is missing")
check("TRAIT_LEADER_MAJOR_CIV','PseudoYields'" in sql, "major-leader AI list is missing")
check("MODIFIER_PLAYER_CITIES_ADJUST_MILITARY_UNITS_PRODUCTION" in sql, "AI production modifier missing")
check("MODIFIER_PLAYER_ADJUST_UNIT_MAINTENANCE_DISCOUNT" in sql, "fixed maintenance discount modifier missing")
check("ABILITY_LOTM_RESCUE_P9_RP_EXTRA_ATTACK" in sql, "Sequence 1 attack ability missing")
check("CLASS_ALL_COMBAT_UNITS" in sql, "extra attack is not combat-unit restricted")
for project in (
    "PROJECT_LOTM_RP_IRONBLOOD_KNIGHT_POTION",
    "PROJECT_LOTM_PP_ALCHEMIST_POTION",
    "PROJECT_LOTM_BE_COUNT_OF_CORRUPTION_POTION",
):
    check(project in sql, f"rescue Industrialization removal misses {project}")
check("UPDATE Projects SET PrereqTech=NULL" in sql, "database Industrialization prerequisite is not removed")

check('include("LOTM_RESCUE_Phase9")' in gameplay, "Phase 9 is not included")
check('include("LOTM_RESCUE_Phase9Digestion")' in gameplay, "Phase 9 digestion is not included")
check('id="LOTM_RESCUE_PHASE9_DATABASE" criteria="LOTM_RP_RESCUE_MODE"' in modinfo, "Phase 9 SQL is not rescue-only")
check("Gameplay/LOTM_RESCUE_Phase9.sql" in modinfo and "Scripts/LOTM_RESCUE_Phase9.lua" in modinfo, "Phase 9 files missing from modinfo")
check("and not IsRescueMode()" in lifecycle, "ordinary Red Priest modifiers are not rescue-gated")
check("not IsRescueMode() and not HasIndustrialization" in advanced, "rescue Industrialization exception missing")

check("DamageEnemyUnits" in arson and "targetUnit:ChangeDamage(amount)" in arson, "rescue direct-damage interface missing")
rescue_branch = arson.split("if IsRescueMode() then", 1)[1].split("return true;", 1)[0]
for forbidden in ("UnitManager.Kill", "MarkBurning", "UnitManager.FinishMoves"):
    check(forbidden not in rescue_branch, f"rescue Arson must not use {forbidden}")
check('targetUnit:GetProperty("LOTM_RESCUE_PHASE10_IS_GOD")' in arson, "Phase 10 god immunity marker is not checked")
check("not IsGodUnit(targetUnit)" in arson, "god units are not excluded from Rescue Arson")
check("rescue direct-damage value is pending" in arson, "invalid synchronized damage must reject without spending the action")
check("LOC_LOTM_RP_ARSON_DISABLED_RESCUE_PENDING" in hud, "HUD lacks pending-damage explanation")

zh_rescue = zh_text[zh_text.index('<Row Tag="LOC_LOTM_RESCUE_P9_RP_EFFECTS_S9"'):zh_text.index('<Row Tag="LOC_LOTM_RESCUE_P9_RP_DIGEST_S9"')]
en_rescue = en_text[en_text.index('<Row Tag="LOC_LOTM_RESCUE_P9_RP_EFFECTS_S9"'):en_text.index('<Row Tag="LOC_LOTM_RESCUE_P9_RP_DIGEST_S9"')]
check("沿用普通模式" not in zh_rescue, "Rescue skill details still contain an opaque ordinary-mode placeholder")
check("retains its ordinary-mode" not in en_rescue, "English Rescue skill details still contain an opaque placeholder")
for sequence in range(9, -1, -1):
    zh_row = zh_rescue.split(f'LOC_LOTM_RESCUE_P9_RP_EFFECTS_S{sequence}', 1)[1].split("</Row>", 1)[0] if f'LOC_LOTM_RESCUE_P9_RP_EFFECTS_S{sequence}' in zh_rescue else ""
    en_row = en_rescue.split(f'LOC_LOTM_RESCUE_P9_RP_EFFECTS_S{sequence}', 1)[1].split("</Row>", 1)[0] if f'LOC_LOTM_RESCUE_P9_RP_EFFECTS_S{sequence}' in en_rescue else ""
    expected_count = 10 - sequence
    check(zh_row.count("（序列") == expected_count, f"Chinese Rescue Sequence {sequence} does not list every inherited skill")
    check(en_row.count("(Sequence ") == expected_count, f"English Rescue Sequence {sequence} does not list every inherited skill")
    check("猎人本能（序列9）" in zh_row and "Hunter's Instinct (Sequence 9)" in en_row, f"Sequence {sequence} omits Hunter details")
for sequence in range(7, -1, -1):
    marker = f'LOC_LOTM_RESCUE_P9_RP_EFFECTS_S{sequence}'
    zh_row = zh_rescue.split(marker, 1)[1].split("</Row>", 1)[0]
    en_row = en_rescue.split(marker, 1)[1].split("</Row>", 1)[0]
    check("70点伤害" in zh_row and "6格" in zh_row and "冷却5回合" in zh_row, f"Chinese Sequence {sequence} abbreviates Rescue Arson")
    check("70 damage" in en_row and "within 6 hexes" in en_row and "cooldown 5 turns" in en_row, f"English Sequence {sequence} abbreviates Rescue Arson")

check("OUTER_GOD" not in sql + lua and "UnitManager.InitUnit" not in lua, "Phase 10 unit generation leaked into Phase 9")
check("DIVINE_LEGION" not in sql, "Divine Legion gameplay modifiers must wait for Phase 10")

if errors:
    print(f"FAILED: {len(errors)} Rescue Phase 9 checks")
    for error in errors:
        print(f" - {error}")
    raise SystemExit(1)

print("PASS: Rescue Phase 9 static contracts (AI buildup, Red Priest overrides, migration guards, Phase 10 reservation)")
