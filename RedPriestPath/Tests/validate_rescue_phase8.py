#!/usr/bin/env python3
"""Static and synthetic contract checks for Rescue Phase 8."""

from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ERRORS: list[str] = []


def check(condition: bool, message: str) -> None:
    if not condition:
        ERRORS.append(message)


def text(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


phase8 = text("Scripts/LOTM_RESCUE_Phase8.lua")
phase8_sql = text("Gameplay/LOTM_RESCUE_Phase8.sql")
gameplay = text("Scripts/LOTM_RP_Gameplay.lua")
modinfo = text("RedPriestPath.modinfo")
phase3 = text("Scripts/LOTM_RESCUE_Phase3.lua")

for snippet in (
    "local VERSION=7;",
    'local LAST_RECONCILE_TURN="LOTM_RESCUE_PHASE8_LAST_RECONCILE_TURN";',
    "local function AnchorMajorID()",
    "playerID~=AnchorMajorID()",
    "Game.SetProperty(LAST_RECONCILE_TURN,worldTurn)",
    "local GUIDE_INTERVAL=2;",
    "local MAX_GUIDED_UNITS=2;",
    'Game.SetProperty("LOTM_RESCUE_PHASE8_STATE","READY")',
    'Game.SetProperty("LOTM_RESCUE_PHASE",8)',
    "if minimum<=6 then return 0,minimum; end",
    "if minimum<=10 then return 1,minimum; end",
    "if sameContinent then return 2,minimum; end",
    'Number(player:GetProperty("LOTM_RESCUE_PHASE8_LAST_GUIDE_TURN"),-1)==Game.GetCurrentGameTurn()',
    "for _,entry in ipairs(EligibleUnits(player,target.Plot)) do",
    "if guided>=MAX_GUIDED_UNITS then break; end",
    'player:SetProperty("LOTM_RESCUE_PHASE8_LAST_GUIDE_TURN",Game.GetCurrentGameTurn())',
    "freeModeHumanWarPreserved=true specialUnits=false bossFormula=false",
):
    check(snippet in phase8, f"Phase 8 contract missing: {snippet}")

check('include("LOTM_RESCUE_Phase8")' in gameplay, "Phase 8 is not included in shared Gameplay")
check("Scripts/LOTM_RESCUE_Phase8.lua" in modinfo, "Phase 8 is missing from modinfo")
check('id="LOTM_RESCUE_PHASE8_DATABASE" criteria="LOTM_RP_RESCUE_MODE"' in modinfo, "Phase 8 database must be rescue-only")
check("Gameplay/LOTM_RESCUE_Phase8.sql" in modinfo, "Phase 8 database file is missing from modinfo")
check('Game.GetProperty("LOTM_RESCUE_MODE")' in phase8, "Phase 8 lacks rescue-mode isolation")

# Diplomacy: the default setup creates an engine-level permanent alliance;
# the explicit advanced-setup opt-out retains human wars and the peace fallback.
config = text("Config/LOTM_RP_PathSelection.xml")
config_zh = text("Text/zh_Hans_CN/LOTM_RP_ConfigText.xml")
config_en = text("Text/en_US/LOTM_RP_ConfigText.xml")
check('ParameterId="LOTM_RESCUE_MAJOR_ALLIANCE"' in config, "permanent-alliance advanced option is missing")
check('ConfigurationId="LOTM_RESCUE_MAJOR_ALLIANCE"' in config, "permanent-alliance configuration id is missing")
check('DefaultValue="1"' in config.split('ParameterId="LOTM_RESCUE_MAJOR_ALLIANCE"', 1)[1].split('/>', 1)[0], "permanent alliance must default on")
check('ParameterId="LOTM_RESCUE_MAJOR_ALLIANCE" ConfigurationGroup="Game" ConfigurationId="GAMEMODE_LOTM_RESCUE" Operator="Equals" ConfigurationValue="1"' in config, "alliance option must only appear with Rescue Mode enabled")
for locale, locale_text in (("zh_Hans_CN", config_zh), ("en_US", config_en)):
    check("LOC_LOTM_RESCUE_MAJOR_ALLIANCE_NAME" in locale_text, f"{locale} alliance option name is missing")
    check("LOC_LOTM_RESCUE_MAJOR_ALLIANCE_DESCRIPTION" in locale_text, f"{locale} alliance option description is missing")
check('GameConfiguration.GetValue(ALLIANCE_CONFIG)' in phase8, "Gameplay does not read the setup option")
check('diplomacy:SetPermanentAlliance(second:GetID())' in phase8, "default coalition lacks engine-level permanent alliance")
check('diplomacy:SetHasMet(second:GetID())' in phase8 and 'reverseDiplomacy:SetHasMet(first:GetID())' in phase8, "coalition members must meet before the permanent alliance is formed")
check('Game.SetProperty("LOTM_RESCUE_PHASE8_ALLIANCE_MODE","PERMANENT")' in phase8, "permanent coalition mode is not published")
check('Game.SetProperty("LOTM_RESCUE_PHASE8_ALLIANCE_MODE","FREE")' in phase8, "free diplomacy mode is not published")
check("SetTeam" not in phase8, "direct team-slot reassignment is forbidden")
check("if acting:IsHuman() then" in phase8, "human acting-player branch is missing")
check("Game.SetProperty(PairKey(actingID,reactingID),1)" in phase8, "human aggression persistence is missing")
check('ForcePeace(actingID,reactingID,reacting:IsHuman() and "AI_ON_HUMAN" or "AI_ON_AI")' in phase8, "AI aggression peace guard is missing")
check("diplomacy:MakePeaceWith(reactingID)" in phase8, "peace correction does not use the player diplomacy API")
check("MODIFIER_ADJUST_DIPLOMATIC_ACTION_PREFERENCE" in phase8_sql, "AI peace preference modifier is missing")
check("AttachPeacePreference(player)" in phase8, "AI peace preference is not attached")
check("player:IsHuman()" in phase8, "peace preference attachment does not exclude humans")
on_war = phase8.split("local function OnWar", 1)[1].split("local function OnPeace", 1)[0]
on_peace = phase8.split("local function OnPeace", 1)[1].split("local function OnTurn", 1)[0]
check("if LOTM_MP_TurnSync.IsNetworkGame() then return; end" in on_war
      and on_war.index("if LOTM_MP_TurnSync.IsNetworkGame() then return; end") < on_war.index("if not Active() then return; end"),
      "network DiplomacyDeclareWar callback must return before Gameplay mutation")
check("if LOTM_MP_TurnSync.IsNetworkGame() then return; end" in on_peace
      and on_peace.index("if LOTM_MP_TurnSync.IsNetworkGame() then return; end") < on_peace.index("Game.SetProperty("),
      "network DiplomacyMakePeace callback must return before Gameplay mutation")
reconcile_all = phase8.split("function LOTM_RESCUE_Phase8.ReconcileAll", 1)[1].split("local function OnWar", 1)[0]
check("ReconcilePeace();" in reconcile_all and "EstablishPermanentCoalition();" in reconcile_all
      and 'LOTM_MP_TurnSync.Add(OnTurn,"RescuePhase8")' in phase8,
      "network diplomacy must be repaired only by the synchronized ReconcileAll turn fallback")
opening_start = phase8.index("function LOTM_RESCUE_Phase8.EstablishOpeningCoalition()")
opening_end = phase8.index("local function ReconcilePeace()", opening_start)
opening = phase8[opening_start:opening_end]
phase2 = text("Scripts/LOTM_RESCUE_Phase2Test.lua")
check("if not LOTM_MP_TurnSync.IsNetworkGame()" in opening
      and "LOTM_RP_MASTER_GAMEPLAY_CONTEXT~=true" in opening
      and "LOTM_MP_TurnSync.IsRescueModeConfigured()" in opening
      and 'Game.GetProperty("LOTM_RESCUE_PHASE1_STATE")~="READY"' in opening
      and 'Game.GetProperty("LOTM_RESCUE_PHASE2A_STATE")~="READY"' in opening
      and "EstablishPermanentCoalition()" in opening
      and 'if failed==0 then Game.SetProperty(OPENING_COALITION_READY,1); end' in opening
      and 'failed==0 and "READY" or "RETRY_PENDING"' in opening
      and "AttachPeacePreference" not in opening
      and "ReconcileAll" not in opening
      and "deferredModifiers=true" in opening
      and "pcall(LOTM_RESCUE_Phase8.EstablishOpeningCoalition)" in phase2,
      "network opening command must establish only the permanent coalition after Phase 1/2 and defer modifiers/full Phase 8")
war_actions = (
    "DIPLOACTION_DECLARE_SURPRISE_WAR",
    "DIPLOACTION_DECLARE_FORMAL_WAR",
    "DIPLOACTION_DECLARE_HOLY_WAR",
    "DIPLOACTION_DECLARE_LIBERATION_WAR",
    "DIPLOACTION_DECLARE_RECONQUEST_WAR",
    "DIPLOACTION_DECLARE_PROTECTORATE_WAR",
    "DIPLOACTION_DECLARE_COLONIAL_WAR",
    "DIPLOACTION_DECLARE_TERRITORIAL_WAR",
    "DIPLOACTION_DECLARE_GOLDEN_AGE_WAR",
    "DIPLOACTION_DECLARE_WAR_OF_RETRIBUTION",
    "DIPLOACTION_DECLARE_IDEOLOGICAL_WAR",
    "DIPLOACTION_JOINT_WAR",
)
for action in war_actions:
    check(action in phase8_sql, f"missing AI war preference: {action}")
check(phase8_sql.count("'Favored','false'") == len(war_actions), "every major war action must be disfavored")

# Clearing guidance uses only ordinary AI combat units and existing targets.
check('WORKSHOP_PROPERTY="LOTM_PP_WORKSHOP_IS_WORKSHOP"' in phase8, "workshop target property missing")
check('CENTER_PROPERTY="LOTM_RESCUE_CENTER_MONSTER"' in phase8, "center lost-control target missing")
check("LOTM_WORLD_Monsters.IsMonster(unit)" in phase8, "roaming monster target missing")
check("player==nil or player:IsHuman() or AtWarWithHuman(player)" in phase8, "AI defense skip is missing")
check("unit:GetCombat()>0" in phase8, "guidance is not restricted to combat units")
check('unit:GetProperty("LOTM_RESCUE_GUARDIAN_SERIAL")' in phase8, "church guardians are not excluded")
check("UnitManager.InitUnit" not in phase8, "Phase 8 must not create AI special units")
check("LOTM_RESCUE_SyncActions.MoveToward" in phase8, "AI guidance must use Gameplay-native movement")
check("LOTM_RESCUE_SyncActions.ScriptedKill" in phase8, "AI guidance must use synchronized scripted clearing")
check('LOTM_RESCUE_SyncActions==nil' in phase8 and '"HELPER_UNAVAILABLE"' in phase8, "missing synchronized helper must fail safely without aborting the turn event")
check("UnitManager.FinishMoves(unit)" in phase8, "guided unit must not spend remaining moves against non-targets")
check("UnitManager.RequestOperation" not in phase8 and "UnitManager.CanStartOperation" not in phase8, "UI-only operation APIs leaked into Gameplay guidance")
check("for _,unit in player:GetUnits():Members()" in phase8, "ordinary unit candidate scan is missing")
check("LOTM_RESCUE_PHASE9" not in phase8 and "LOTM_RESCUE_PHASE10" not in phase8 and "OUTER_GOD" not in phase8, "Phase 9 or 10 leaked into Phase 8")

# Phase 3 now guides church guardians only toward a synchronized barbarian/lost-control whitelist;
# Phase 8 must continue excluding those units from ordinary-major AI guidance.
check(
    all(token in phase3 for token in (
        "GuideGuardians(player)", "PlayerManager.GetAliveBarbarians",
        "LOTM_RESCUE_SyncActions.MoveToward", "UnitManager.FinishMoves(unit)",
    ))
    and "FreezeGuardians" not in phase3
    and 'unit:GetProperty("LOTM_RESCUE_GUARDIAN_SERIAL")' in phase8
    and "ABILITY_LOTM_RESCUE_GUARDIAN_NON_AGGRESSION" not in phase8,
    "Phase 8 changed guardian safety",
)

def rank(distance: int, same_continent: bool) -> int | None:
    if distance <= 6:
        return 0
    if distance <= 10:
        return 1
    if same_continent:
        return 2
    return None


synthetic = [
    (0, True, 0),
    (6, False, 0),
    (7, True, 1),
    (10, False, 1),
    (11, True, 2),
    (30, True, 2),
    (11, False, None),
]
for distance, same_continent, expected in synthetic:
    check(rank(distance, same_continent) == expected, f"wrong synthetic target rank: {distance}/{same_continent}")

if ERRORS:
    print(f"FAILED: {len(ERRORS)} Rescue Phase 8 checks")
    for error in ERRORS:
        print(f" - {error}")
    raise SystemExit(1)

print("PASS: Rescue Phase 8 static + synthetic contract (default permanent coalition, setup opt-out, peace fallback, two-unit lightweight lost-control guidance)")
