#!/usr/bin/env python3
"""Static contracts for Phase 10A endgame measurement without invented Boss balance."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
errors: list[str] = []


def text(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


def check(condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)


lua = text("Scripts/LOTM_RESCUE_Phase10A.lua")
gameplay = text("Scripts/LOTM_RP_Gameplay.lua")
modinfo = text("RedPriestPath.modinfo")

for snippet in (
    "local VERSION=6;",
    "LOTM_RESCUE_Phase5.WorldTurn()",
    "LOTM_RESCUE_Phase5.FinalTurn()",
    'SetChanged(Game,"LOTM_RESCUE_PHASE10A_STATE","BALANCE_DATA_REQUIRED")',
    'SetChanged(Game,"LOTM_RESCUE_PHASE10A_BOSS_GENERATED",0)',
    'SetChanged(player,"LOTM_RESCUE_PHASE10A_DIVINE_LEGION_TOTAL",total)',
    'SetChanged(player,"LOTM_RESCUE_PHASE10A_DIVINE_LEGION_BREAKDOWN",tostring(player:GetProperty("LOTM_RESCUE_PHASE10A_DIVINE_LEGION_SACRIFICE_LOG") or ""))',
    'local total=skillReady and sacrificed or 0;',
    'SetChanged(player,"LOTM_RESCUE_PHASE10A_DIVINE_LEGION_RAW_TOTAL",sacrificed*10)',
    'SetChanged(player,"LOTM_RESCUE_PHASE10A_DIVINE_LEGION_INHERIT_DIVISOR",10)',
    'local RELIC_PROJECT="PROJECT_LOTM_RESCUE_WAR_GOD_RELIC";',
    'ChurchEnvoys(player,"FOOL")',
    'ChurchEnvoys(player,"NIGHT")',
    'ChurchEnvoys(player,"STORM")',
    'player:AttachModifierByID(RELIC_UNLOCK_MODIFIER)',
    'Events.CityProjectCompleted.Add(OnCityProjectCompleted)',
    "math.max(Number(unit:GetCombat(),0),Number(unit:GetRangedCombat(),0),Number(unit:GetBombardCombat(),0))",
    'Number(unit:GetProperty(GOD_UNIT_PROPERTY),0)==1',
    'local function SetChanged(owner,key,value)',
):
    check(snippet in lua, f"Phase 10A contract missing: {snippet}")

check('include("LOTM_RESCUE_Phase10A")' in gameplay, "Phase 10A is not included after Phase 9")
check("Scripts/LOTM_RESCUE_Phase10A.lua" in modinfo, "Phase 10A file is missing from modinfo")
check("UnitManager.InitUnit" not in lua, "Phase 10A must not generate gods or the Boss")
check("ChangeDamage" not in lua, "measurement/project phase must not alter combat state")
check("BOSS_STRENGTH" not in lua and "PURIFICATION_TIER" not in lua, "unconfirmed Boss values leaked into Phase 10A")
check('Game.SetProperty("LOTM_RESCUE_PHASE",10)' not in lua, "measurement-only Phase 10A must not claim full Phase 10 completion")
check(all(token not in lua for token in (
    'formation~="FORMATION_CLASS_LAND_COMBAT"',
    'formation~="FORMATION_CLASS_NAVAL"',
    'formation~="FORMATION_CLASS_AIR"',
)), "special combat units must not be rejected by a standard FormationClass whitelist")
sacrifice_ui = text("UI/LOTM_RESCUE_Sacrifice.lua")
check('path~="NONE"' in sacrifice_ui and 'LOTM_RP_SEQUENCE' in sacrifice_ui,
      "retained sacrifice implementation must preserve all Sequence 0 pathways")
check('path=="PATH_THIEF"' not in sacrifice_ui,
      "retained sacrifice implementation must not become Thief-only")

project_callback = lua.split("local function OnCityProjectCompleted", 1)[1].split("function LOTM_RESCUE_Phase10A.RefreshAll", 1)[0]
network_prefix = project_callback.split("if LOTM_MP_TurnSync.IsNetworkGame() then", 1)[1].split("return; end", 1)[0]
check("QueueNetworkCityProjectCompleted(playerID,cityID,projectID);" in network_prefix
      and all(token not in network_prefix for token in (
          "SetProperty(", "AttachModifierByID(", "ApplyCityProjectCompleted(", "RefreshPlayer(",
      )), "network CityProjectCompleted callback must only capture Lua-local completion evidence")
network_settlement = lua.split("local function ProcessNetworkCityProjectCompletions", 1)[1].split("local function OnCityProjectCompleted", 1)[0]
for token in (
    "LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID)", "entry.QueuedTurn<currentTurn",
    "if a.QueuedTurn~=b.QueuedTurn", "if a.PlayerID~=b.PlayerID", "if a.CityID~=b.CityID",
    "return a.ProjectID<b.ProjectID", "GameInfo.Projects[entry.ProjectID]",
    "player:GetCities():FindID(entry.CityID)", "city:GetOwner()==entry.PlayerID",
    "ApplyCityProjectCompleted(entry.PlayerID,entry.CityID,entry.ProjectID)",
):
    check(token in network_settlement, f"deferred project settlement lacks stable/full-turn revalidation: {token}")
check("ProcessNetworkCityProjectCompletions(playerID)" in lua,
      "synchronized Phase 10A turn handler must drain deferred network project completions")
refresh_all = lua.split("function LOTM_RESCUE_Phase10A.RefreshAll", 1)[1].split("LOTM_MP_TurnSync.Add", 1)[0]
check("table.sort(majors,function(a,b) return a:GetID()<b:GetID(); end);" in refresh_all,
      "Phase 10A startup modifier attachment must traverse major players in stable ID order")

if errors:
    print(f"FAILED: {len(errors)} Rescue Phase 10A checks")
    for error in errors:
        print(f" - {error}")
    raise SystemExit(1)

print("PASS: Rescue Phase 10A measurement contracts (schedule, Divine Legion detail, no invented Boss balance)")
