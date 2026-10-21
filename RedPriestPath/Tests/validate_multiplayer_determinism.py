#!/usr/bin/env python3
"""Static multiplayer authority and determinism gate."""

from pathlib import Path
from itertools import permutations
import hashlib
import re
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
LEGACY_NETWORK_BUNDLE = ROOT / "Tests" / "fixtures" / "LOTM_RP_Gameplay_Bundle_resource290.lua"
LEGACY_NETWORK_SHA256 = "0D13F6A72782EA3D90702FC7BADDFB2951818FED1CE8281531084C7E0C97E97A"
errors: list[str] = []

def check(value: bool, message: str) -> None:
    if not value:
        errors.append(message)


def lua_slice(text: str, start_marker: str, end_marker: str | None = None) -> str:
    """Return a bounded source region without truncating on a nested ``end``.

    The Gameplay sources intentionally use compact one-line Lua blocks.  The
    old tests split at the first literal ``end`` and consequently inspected an
    empty wrapper (or only the first nested branch) after the callback was
    moved into a helper.  Explicit neighbouring function markers keep the
    contract tied to the complete function while remaining parser-free.
    """
    start = text.find(start_marker)
    if start < 0:
        return ""
    if end_marker is None:
        return text[start:]
    end = text.find(end_marker, start + len(start_marker))
    return text[start:] if end < 0 else text[start:end]


def network_prefix(function_body: str) -> str:
    """Return the network branch through its first branch return."""
    markers = (
        "LOTM_MP_TurnSync.IsNetworkGame()",
        "GameConfiguration.IsAnyMultiplayer()",
    )
    positions = [function_body.find(marker) for marker in markers]
    positions = [position for position in positions if position >= 0]
    if not positions:
        return ""
    start = min(positions)
    return_index = function_body.find("return", start)
    return function_body[start:] if return_index < 0 else function_body[start:return_index + len("return")]


NETWORK_MUTATION_TOKENS = (
    "ChangeAbilityCount(",
    "AttachModifierByID(",
    ":SetProperty(",
    "Game.SetProperty(",
    "UnitManager.Kill(",
    "UnitManager.InitUnit(",
    ":ChangeDamage(",
    ":ChangeGoldBalance(",
    ":ChangeLoyalty(",
    ":ChangeTokensToGive(",
    ":ChangePointsTotal(",
    ":TriggerBoost(",
    ":SetVeteranName(",
)

scripts = {
    p: p.read_text(encoding="utf-8")
    for p in (ROOT / "Scripts").glob("*.lua")
    if p.name != "LOTM_RP_Gameplay_Bundle.lua"
}
ui = {p: p.read_text(encoding="utf-8") for p in (ROOT / "UI").glob("*.lua")}

# Keep an explicit inventory of every local publication entry point.  A new
# UnitAdded/UnitInitialized listener is an authority review item, not an
# innocuous implementation detail: if it is not listed here the gate fails
# instead of silently allowing a client-local writer into a multiplayer game.
UNIT_EVENT_CONTRACTS: dict[tuple[str, str], str] = {
    ("LOTM_AI_Cult_Hanged.lua", "GameEvents.UnitInitialized"): "TryMarkNewUnit",
    ("LOTM_RP_Lifecycle.lua", "GameEvents.UnitInitialized"): "OnUnitInitialized",
    ("LOTM_AI_Cults.lua", "Events.UnitAddedToMap"): "OnUnitAddedToMap",
    ("LOTM_BE_BlackEmperor.lua", "Events.UnitAddedToMap"): "OnUnitAddedToMap",
    ("LOTM_PP_Artifacts.lua", "Events.UnitAddedToMap"): "OnUnitAdded",
    ("LOTM_PP_Perfect.lua", "Events.UnitAddedToMap"): "OnUnitAddedToMap",
    ("LOTM_PP_Workshops.lua", "Events.UnitAddedToMap"): "OnUnitAdded",
    ("LOTM_RESCUE_Phase7.lua", "Events.UnitAddedToMap"): "OnUnitAdded",
    ("LOTM_RESCUE_Phase9.lua", "Events.UnitAddedToMap"): "OnUnitAdded",
    ("LOTM_RESCUE_Phase9Digestion.lua", "Events.UnitAddedToMap"): "OnUnitAdded",
    ("LOTM_WORLD_Churches.lua", "Events.UnitAddedToMap"): "OnUnitAdded",
    # This listener only closes the performance probe; it is deliberately
    # exempt from state-authority checks below.
    ("LOTM_RP_Gameplay.lua", "Events.UnitAddedToMap"): "LOTM_UnitAddedPerf.EventCompleted",
}

seen_unit_event_contracts: set[tuple[str, str]] = set()
for path, source in scripts.items():
    for event_name in ("Events.UnitAddedToMap", "GameEvents.UnitInitialized"):
        marker = event_name + ".Add("
        occurrences = [match.start() for match in re.finditer(re.escape(marker), source)]
        if not occurrences:
            continue
        key = (path.name, event_name)
        seen_unit_event_contracts.add(key)
        expected_callback = UNIT_EVENT_CONTRACTS.get(key)
        check(expected_callback is not None,
              f"unreviewed local publication entry point: {path.name} {event_name}")
        check(len(occurrences) == 1,
              f"{path.name} registers {event_name} more than once")
        for occurrence in occurrences:
            registration = source[occurrence:occurrence + 320]
            check(expected_callback is not None and expected_callback in registration,
                  f"{path.name} {event_name} does not use its reviewed callback {expected_callback}")
check(seen_unit_event_contracts == set(UNIT_EVENT_CONTRACTS),
      "local UnitAdded/UnitInitialized entry-point inventory is incomplete")

# Inventory every locally published ``Events.*`` listener, not only unit
# creation.  A newly added listener must be reviewed here before it can enter a
# release; focused checks below then prove whether its multiplayer branch is a
# read-only capture, a no-op followed by synchronized reconciliation, or local
# presentation only.  GameEvents are intentionally excluded because they are
# Gameplay's synchronized authority surface.
LOCAL_EVENT_COUNTS: dict[tuple[str, str], int] = {
    ("LOTM_AI_Cult_Hanged.lua", "UnitRemovedFromMap"): 1,
    ("LOTM_AI_Cults.lua", "ResearchCompleted"): 1,
    ("LOTM_AI_Cults.lua", "DiplomacyDeclareWar"): 1,
    ("LOTM_AI_Cults.lua", "DiplomacyMakePeace"): 1,
    ("LOTM_AI_Cults.lua", "UnitAddedToMap"): 1,
    ("LOTM_BE_BlackEmperor.lua", "UnitAddedToMap"): 1,
    ("LOTM_BE_BlackEmperor.lua", "CivicCompleted"): 1,
    ("LOTM_BE_BlackEmperor.lua", "ResearchCompleted"): 1,
    ("LOTM_BE_BlackEmperor.lua", "CityTransfered"): 1,
    ("LOTM_BE_BlackEmperor.lua", "InfluenceChanged"): 1,
    ("LOTM_BE_BlackEmperor.lua", "TradeRouteActivityChanged"): 1,
    ("LOTM_BE_BlackEmperor.lua", "CityProjectCompleted"): 1,
    ("LOTM_MP_TurnSync.lua", "PlayerTurnActivated"): 1,
    ("LOTM_PP_Artifacts.lua", "GreatWorkCreated"): 1,
    ("LOTM_PP_Artifacts.lua", "UnitAddedToMap"): 1,
    ("LOTM_PP_Artifacts.lua", "DiplomacyDeclareWar"): 1,
    ("LOTM_PP_Artifacts.lua", "DiplomacyMakePeace"): 1,
    ("LOTM_PP_Perfect.lua", "TechBoostTriggered"): 1,
    ("LOTM_PP_Perfect.lua", "CivicBoostTriggered"): 1,
    ("LOTM_PP_Perfect.lua", "GoodyHutReward"): 1,
    ("LOTM_PP_Perfect.lua", "UnitMoveComplete"): 1,
    ("LOTM_PP_Perfect.lua", "UnitChargesChanged"): 1,
    ("LOTM_PP_Perfect.lua", "ImprovementAddedToMap"): 1,
    ("LOTM_PP_Perfect.lua", "DistrictAddedToMap"): 1,
    ("LOTM_PP_Perfect.lua", "ResearchCompleted"): 1,
    ("LOTM_PP_Perfect.lua", "CivicCompleted"): 1,
    ("LOTM_PP_Perfect.lua", "UnitAddedToMap"): 1,
    ("LOTM_PP_Perfect.lua", "UnitRemovedFromMap"): 1,
    ("LOTM_PP_Perfect.lua", "CityProjectCompleted"): 1,
    ("LOTM_PP_Perfect.lua", "GreatWorkCreated"): 1,
    ("LOTM_PP_Workshops.lua", "ImprovementAddedToMap"): 2,
    ("LOTM_PP_Workshops.lua", "ImprovementRemovedFromMap"): 1,
    ("LOTM_PP_Workshops.lua", "UnitAddedToMap"): 1,
    ("LOTM_PP_Workshops.lua", "UnitRemovedFromMap"): 1,
    ("LOTM_QD_MultiplayerCompat.lua", "LoadGameViewStateDone"): 1,
    ("LOTM_QD_MultiplayerCompat.lua", "LoadScreenClose"): 1,
    ("LOTM_RESCUE_Artifacts.lua", "DiplomacyDeclareWar"): 1,
    ("LOTM_RESCUE_Artifacts.lua", "DiplomacyMakePeace"): 1,
    ("LOTM_RESCUE_Artifacts.lua", "AllianceChanged"): 1,
    ("LOTM_RESCUE_Phase10.lua", "UnitRemovedFromMap"): 1,
    ("LOTM_RESCUE_Phase10.lua", "UnitMoveComplete"): 1,
    ("LOTM_RESCUE_Phase10.lua", "UnitDamageChanged"): 1,
    ("LOTM_RESCUE_Phase10A.lua", "CityProjectCompleted"): 1,
    ("LOTM_RESCUE_Phase3.lua", "UnitRemovedFromMap"): 2,
    ("LOTM_RESCUE_Phase7.lua", "UnitAddedToMap"): 1,
    ("LOTM_RESCUE_Phase7.lua", "UnitRemovedFromMap"): 1,
    ("LOTM_RESCUE_Phase8.lua", "DiplomacyDeclareWar"): 1,
    ("LOTM_RESCUE_Phase8.lua", "DiplomacyMakePeace"): 1,
    ("LOTM_RESCUE_Phase9.lua", "UnitAddedToMap"): 1,
    ("LOTM_RESCUE_Phase9.lua", "UnitRemovedFromMap"): 1,
    ("LOTM_RESCUE_Phase9Digestion.lua", "UnitAddedToMap"): 1,
    ("LOTM_RESCUE_Phase9Digestion.lua", "UnitRemovedFromMap"): 1,
    ("LOTM_RESCUE_Phase9Digestion.lua", "UnitDamageChanged"): 1,
    ("LOTM_RESCUE_Thief.lua", "CityProjectCompleted"): 1,
    ("LOTM_RP_Advanced.lua", "CityProjectCompleted"): 1,
    ("LOTM_RP_Advanced.lua", "DiplomacyDeclareWar"): 1,
    ("LOTM_RP_Advanced.lua", "DiplomacyMakePeace"): 1,
    ("LOTM_RP_Gameplay.lua", "PlayerTurnActivated"): 1,
    ("LOTM_RP_Gameplay.lua", "UnitAddedToMap"): 1,
    ("LOTM_RP_Lifecycle.lua", "ResearchCompleted"): 1,
    ("LOTM_RP_Lifecycle.lua", "UnitRemovedFromMap"): 1,
    ("LOTM_RP_Progression.lua", "UnitMoveComplete"): 1,
    ("LOTM_RP_Progression.lua", "GoodyHutReward"): 1,
    ("LOTM_RP_Progression.lua", "CityProjectCompleted"): 1,
    ("LOTM_TP_Thief.lua", "ResearchCompleted"): 1,
    ("LOTM_TP_Thief.lua", "CivicCompleted"): 1,
    ("LOTM_TP_Thief.lua", "CityProjectCompleted"): 1,
    ("LOTM_WORLD_Churches.lua", "UnitAddedToMap"): 1,
    ("LOTM_WORLD_Churches.lua", "DiplomacyDeclareWar"): 1,
    ("LOTM_WORLD_Churches.lua", "DiplomacyMakePeace"): 1,
    ("LOTM_WORLD_Monsters.lua", "UnitRemovedFromMap"): 1,
}
observed_local_events: dict[tuple[str, str], int] = {}
local_event_pattern = re.compile(r"(?<!Game)Events\.([A-Za-z0-9_]+)\.Add\s*\(")
for path, source in scripts.items():
    for match in local_event_pattern.finditer(source):
        key = (path.name, match.group(1))
        observed_local_events[key] = observed_local_events.get(key, 0) + 1
check(observed_local_events == LOCAL_EVENT_COUNTS,
      "local Events listener inventory changed without authority review: "
      f"observed={observed_local_events}")

check(not any("Game.GetLocalPlayer(" in text for text in scripts.values()),
      "Gameplay scripts must not branch on the local player")
turn_sync = scripts[ROOT / "Scripts" / "LOTM_MP_TurnSync.lua"]
check('LOTM_MP_TurnSync.VERSION = 7' in turn_sync
      and 'GameEvents.PlayerTurnStarted.Add(DispatchNetworkTurn)' in turn_sync
      and 'Events.PlayerTurnActivated.Add(wrapper)' in turn_sync
      and 'TimedTurnWrapper(handler,label)' in turn_sync
      and 'if not LOTM_MP_TurnSync.IsNetworkGame() then' in turn_sync
      and 'GameConfiguration.IsAnyMultiplayer() == true' in turn_sync
      and 'GameConfiguration.IsNetworkMultiplayer' not in turn_sync,
      "turn adapter must preserve single-player activation and use synchronized multiplayer turns")
thief_gamecore = scripts[ROOT / "Scripts" / "LOTM_TP_Thief.lua"]
check('Events.GameCoreEventPublishComplete.Add' not in thief_gamecore
      and 'LOTM_MP_TurnSync.AddSynchronized(function(playerID, first)' in thief_gamecore
      and 'else\n\t\tlocal startupDone = false;' in thief_gamecore,
      "normal Thief startup must finish once at a synchronized turn, never publish-loop")
check('function LOTM_MP_TurnSync.RunStartup(handler, label)' in turn_sync
      and 'RegisterNetworkStartupHandler(handler,label);' in turn_sync
      and 'function LOTM_MP_TurnSync.RunPendingStartups(triggerPlayerID,source)' in turn_sync
      and 'return "NETWORK_DEFERRED"' in turn_sync,
      "network startup reconciliation must be deferred and explicitly drainable from synchronized Gameplay")
check('function LOTM_MP_TurnSync.AddSynchronized(handler,label)' in turn_sync
      and 'GameEvents.PlayerTurnStarted.Add(wrapper);' in turn_sync
      and 'RegisterNetworkTurnHandler(handler,label);' in turn_sync,
      "legacy synchronized systems must preserve single-player while joining the ordered network dispatcher")
check('if tostring(label) == "RescuePhase2A" then' in turn_sync
      and 'Game.GetProperty("LOTM_RESCUE_PHASE1_STATE") == "READY"' in turn_sync,
      "ordered Rescue Phase 2 startup must depend only on Phase 1 and cannot wait on its own READY state")
check('function LOTM_MP_TurnSync.Random(maxExclusive,label,legacyLabel)' in turn_sync
      and 'return Game.GetRandNum(limit,tostring(legacyLabel or label or "LOTM"));' in turn_sync
      and 'local value = MixStableValue(StableSeed(),turn);' in turn_sync
      and 'value = MixStableValue(value,label or "");' in turn_sync,
      "turn adapter must preserve the legacy single-player RNG and provide a pure multiplayer roll")
random_start = turn_sync.find("function LOTM_MP_TurnSync.Random(maxExclusive,label,legacyLabel)")
random_section = turn_sync[random_start:turn_sync.find("function LOTM_MP_TurnSync.Add", random_start)]
check(random_section.find("if not LOTM_MP_TurnSync.IsNetworkGame() then")
      < random_section.find("if limit == 1 then return 0; end"),
      "single-player max=1 rolls must still call the legacy engine RNG")

def check_startup_anchor_contract(text: str, label: str) -> None:
    """Guard the MP-only startup edge without changing the SP callback path."""
    start = text.find("function LOTM_MP_TurnSync.RunStartup(handler, label)")
    section = text[start:] if start >= 0 else ""
    pending_start = text.find("function LOTM_MP_TurnSync.RunPendingStartups(triggerPlayerID,source)")
    pending_end = text.find("local function DispatchNetworkTurn(playerID)", pending_start)
    pending = text[pending_start:pending_end]
    dispatch_start = text.find("local function DispatchNetworkTurn(playerID)")
    dispatch_end = text.find("local function EnsureNetworkDispatcher()", dispatch_start)
    dispatch = text[dispatch_start:dispatch_end]
    check(start >= 0 and pending_start >= 0 and dispatch_start >= 0
          and "local function LowestAliveMajorID()" in text
          and "PlayerManager.GetAliveMajorIDs() or {}" in text
          and "local anchor = LowestAliveMajorID();" in pending
          and "if anchor == nil then" in pending
          and "startup deferred reason=NO_ALIVE_MAJOR" in pending
          and "local anchor = LowestAliveMajorID();" in dispatch
          and "tonumber(playerID) == anchor" in dispatch
          and 'RunPendingStartups(playerID,"PLAYER_TURN_STARTED")' in dispatch
          and "pcall(entry.Handler,anchor);" in pending,
          f"{label} startup must use the lowest alive major for both turn and synchronized-command drains")
    anchor_guard = dispatch.find("tonumber(playerID) == anchor")
    pending_call = dispatch.find('RunPendingStartups(playerID,"PLAYER_TURN_STARTED")')
    claim_call = dispatch.find("if not ClaimNetworkTurn(playerID) then return; end")
    completed_write = pending.find("entry.Completed = true;")
    handler_call = pending.find("pcall(entry.Handler,anchor);")
    startup_fault = pending.find('LatchDispatcherFault("STARTUP",entry.Label,details);')
    runtime_ready = dispatch.find("if not RescueRuntimeReady() then return; end")
    turn_loop = dispatch.find("LOTM_MP_TurnSync._turnHandlers")
    turn_call = dispatch.find("pcall(InvokeTurnHandler,entry.Handler,entry.Label,playerID,true);")
    turn_fault = dispatch.find('LatchDispatcherFault("TURN",entry.Label,details);')
    check(claim_call >= 0 and anchor_guard >= 0 and pending_call > anchor_guard
          and "if LOTM_MP_TurnSync._dispatcherFault then return; end" in dispatch[pending_call:claim_call]
          and handler_call >= 0 and startup_fault > handler_call
          and completed_write > startup_fault
          and claim_call > pending_call and runtime_ready > claim_call
          and turn_loop > runtime_ready
          and turn_call > turn_loop
          and turn_fault > turn_call,
          f"{label} must latch startup failure before claiming a turn and only complete successful handlers")
    check("local function LatchDispatcherFault(kind,label,details)" in text
          and "if LOTM_MP_TurnSync._dispatcherFault then return false; end" in pending
          and "if LOTM_MP_TurnSync._dispatcherFault then return; end" in dispatch
          and "all later network dispatch disabled" in text,
          f"{label} must permanently fail closed after the first multiplayer handler error")
    check('local function ClaimNetworkTurn(playerID)' in text
          and '"LOTM_MP_TURNSYNC_LAST_CLAIMED_TURN:"' in text
          and 'local function ReadNumericGameProperty(key)' in text
          and 'local rawValue = Game.GetProperty(key);' in text
          and 'return rawValue ~= nil and tonumber(rawValue) or nil;' in text
          and 'local claimedTurn = ReadNumericGameProperty(key);' in text
          and 'if claimedTurn == tonumber(turn) then return false; end' in text
          and 'tonumber(Game.GetProperty(key))' not in text
          and 'tonumber(Game.GetProperty("LOTM_RESCUE_PHASE2A_READY_GAME_TURN"))' not in text
          and text.count('ReadNumericGameProperty("LOTM_RESCUE_PHASE2A_READY_GAME_TURN")') == 2
          and 'Game.SetProperty(key,turn);' in text,
          f"{label} must safely read absent Properties before persistent player/game-turn claims")
    check('if tostring(label) == "RescuePhase2A" then' in text
          and 'Game.GetProperty("LOTM_RESCUE_PHASE1_STATE") == "READY"' in text,
          f"{label} must make Phase 2A eligible after Phase 1 while staging its execution to the next world turn")
    check('"LOTM_MP_TURNSYNC_LAST_RESCUE_STARTUP_TURN"' in pending
          and 'lastRescueStartupTurn == tonumber(currentTurn)' in pending
          and 'tostring(entry.Label)=="RescuePhase1"' in pending
          and 'tostring(entry.Label)=="RescuePhase2A"' in pending
          and 'nextStage=NEXT_WORLD_TURN' in pending,
          f"{label} must execute Phase 1 and Phase 2A on separate synchronized world turns")
    startup_ready_start = text.find("local function RescueStartupReady(label)")
    startup_ready_end = text.find("local function RescueRuntimeReady()", startup_ready_start)
    startup_ready = text[startup_ready_start:startup_ready_end]
    runtime_ready_end = text.find("local function LatchDispatcherFault", startup_ready_end)
    runtime_ready_section = text[startup_ready_end:runtime_ready_end]
    check("currentTurn > readyTurn" in startup_ready
          and "currentTurn >= readyTurn" not in startup_ready
          and "currentTurn > readyTurn" in runtime_ready_section
          and "currentTurn >= readyTurn" not in runtime_ready_section,
          f"{label} must keep every post-Phase2 startup and runtime behind one complete stable turn")
    check(re.search(
              r"if not LOTM_MP_TurnSync\.IsNetworkGame\(\) then\s+handler\(\);",
              section) is not None,
          f"{label} must preserve immediate single-player startup")

check_startup_anchor_contract(turn_sync, "standalone turn adapter")

# Executable regression model for the exact first-turn failure observed in
# resource 286.  Missing the stable-anchor callback must leave the world
# untouched; each synchronized pass may complete only one heavy rescue stage.
# Every other startup and all runtime work remain behind the complete stable
# turn after Phase 2A.
def simulate_rescue_pending(
    current_turn: int,
    completed: dict[str, bool],
    state: dict[str, int | bool | None],
) -> bool:
    last_startup_turn = state.get("last_startup_turn")
    if last_startup_turn == current_turn:
        return False
    labels = ("RescuePhase1", "RescuePhase2A", "Lifecycle")
    for startup_label in labels:
        if completed[startup_label]:
            continue
        if startup_label == "RescuePhase1":
            ready = True
        elif startup_label == "RescuePhase2A":
            ready = bool(state["phase1_ready"])
        else:
            ready_turn = state["phase2_ready_turn"]
            ready = (
                bool(state["phase1_ready"])
                and bool(state["phase2_ready"])
                and isinstance(ready_turn, int)
                and current_turn > ready_turn
            )
        if not ready:
            continue
        completed[startup_label] = True
        if startup_label == "RescuePhase1":
            state["phase1_ready"] = True
            state["last_startup_turn"] = current_turn
            return False
        elif startup_label == "RescuePhase2A":
            state["phase2_ready"] = True
            state["phase2_ready_turn"] = current_turn
            state["last_startup_turn"] = current_turn
            return False
    return all(completed.values())

def modeled_runtime_ready(current_turn: int, state: dict[str, int | bool | None]) -> bool:
    ready_turn = state["phase2_ready_turn"]
    return (
        bool(state["phase1_ready"])
        and bool(state["phase2_ready"])
        and isinstance(ready_turn, int)
        and current_turn > ready_turn
    )

modeled_completed = {
    "RescuePhase1": False,
    "RescuePhase2A": False,
    "Lifecycle": False,
}
modeled_state: dict[str, int | bool | None] = {
    "phase1_ready": False,
    "phase2_ready": False,
    "phase2_ready_turn": None,
    "last_startup_turn": None,
}
check(not any(modeled_completed.values()) and not any(
          bool(modeled_state[key]) for key in ("phase1_ready", "phase2_ready")
      ), "missing the first stable-anchor callback must not partially initialize rescue")
bootstrap_finished = simulate_rescue_pending(1, modeled_completed, modeled_state)
check(not bootstrap_finished
      and modeled_completed["RescuePhase1"]
      and not modeled_completed["RescuePhase2A"]
      and not modeled_completed["Lifecycle"]
      and modeled_state["phase2_ready_turn"] is None
      and not modeled_runtime_ready(1, modeled_state),
      "first synchronized bootstrap turn must complete only Phase 1")
duplicate_completed = dict(modeled_completed)
duplicate_state = dict(modeled_state)
check(not simulate_rescue_pending(1, modeled_completed, modeled_state)
      and modeled_completed == duplicate_completed
      and modeled_state == duplicate_state,
      "duplicate human bootstrap requests in either network order must be idempotent")
next_turn_finished = simulate_rescue_pending(2, modeled_completed, modeled_state)
check(not next_turn_finished and modeled_completed["RescuePhase2A"]
      and not modeled_completed["Lifecycle"]
      and modeled_state["phase2_ready_turn"] == 2
      and not modeled_runtime_ready(2, modeled_state),
      "second synchronized bootstrap turn must complete only Phase 2A")
third_turn_finished = simulate_rescue_pending(3, modeled_completed, modeled_state)
check(third_turn_finished and modeled_completed["Lifecycle"]
      and modeled_runtime_ready(3, modeled_state),
      "post-Phase2 startup and runtime must unlock on the following stable turn")

direct_turn_activation = [
    p.name for p, text in scripts.items()
    if p.name not in {"LOTM_MP_TurnSync.lua", "LOTM_RP_Gameplay.lua"}
    and "Events.PlayerTurnActivated.Add" in text
]
check(not direct_turn_activation,
      f"Gameplay scripts bypass multiplayer turn adapter: {direct_turn_activation}")
direct_synchronized_turn = [
    p.name for p, text in scripts.items()
    if p.name not in {
        "LOTM_MP_TurnSync.lua", "LOTM_RP_Gameplay.lua",
        "LOTM_RESCUE_Phase2Test.lua", "LOTM_QD_MultiplayerCompat.lua",
    }
    and "GameEvents.PlayerTurnStarted.Add" in text
]
check(not direct_synchronized_turn,
      f"Gameplay scripts bypass the ordered multiplayer dispatcher: {direct_synchronized_turn}")
for forbidden in (
    ":SetProperty(", "Game.SetProperty(", ":AttachModifierByID(",
    ":ChangeGoldBalance(", ":GrantYield(", "UnitManager.InitUnit(",
    "UnitManager.Kill(", "CityManager.Create", "CityManager.Destroy",
    "ImprovementBuilder.", "TerrainBuilder.", "ResourceBuilder.",
):
    offenders = [p.name for p, text in ui.items() if forbidden in text]
    check(not offenders, f"UI directly mutates synchronized state via {forbidden}: {offenders}")


def check_network_queue_callback(
    source: str,
    callback_start: str,
    callback_end: str,
    queue_token: str,
    label: str,
) -> str:
    body = lua_slice(source, callback_start, callback_end)
    prefix = network_prefix(body)
    check(bool(body) and queue_token in prefix and "return" in prefix,
          f"{label} network publication must queue locally and return before settlement")
    check(not any(token in prefix for token in NETWORK_MUTATION_TOKENS),
          f"{label} network publication mutates synchronized state before its queue return")
    return body


def check_network_early_return(
    source: str,
    callback_start: str,
    callback_end: str,
    label: str,
) -> str:
    body = lua_slice(source, callback_start, callback_end)
    prefix = network_prefix(body)
    check(bool(body) and "return" in prefix,
          f"{label} network publication must return without local settlement")
    check(not any(token in prefix for token in NETWORK_MUTATION_TOKENS),
          f"{label} network publication mutates synchronized state before its return")
    return body


def check_network_processor(
    source: str,
    processor_start: str,
    processor_end: str,
    sort_tokens: tuple[str, ...],
    apply_token: str,
    label: str,
) -> str:
    body = lua_slice(source, processor_start, processor_end)
    check(bool(body)
          and "LOTM_MP_TurnSync.IsNetworkGame()" in body
          and "LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID)" in body
          and re.search(r"QueuedTurn\s*<\s*currentTurn", body) is not None
          and all(token in body for token in sort_tokens)
          and apply_token in body,
          f"{label} queue must settle only at a stable next-turn anchor in deterministic order")
    return body


# Resource 291's local-publication audit.  Each callback either queues a
# captured identity for the ordered Gameplay turn, or (for legacy single-
# player-only fallbacks) exits before any synchronized mutation.  The actual
# writes are asserted in the corresponding stable processor below.
artifacts = scripts[ROOT / "Scripts" / "LOTM_PP_Artifacts.lua"]
artifacts_added = check_network_queue_callback(
    artifacts, "local function OnUnitAdded", "local function Initialize",
    "QueueNetworkHermesUnit", "Artifacts UnitAdded",
)
artifacts_processor = check_network_processor(
    artifacts, "local function ProcessNetworkHermesUnits", "local function ProcessTurn",
    ("table.sort(ready,function(a,b)", "a.PlayerID~=b.PlayerID", "a.UnitID<b.UnitID"),
    "ApplyHermesBuilder(entry.PlayerID,entry.UnitID)", "Artifacts Hermes queue",
)
artifacts_turn = lua_slice(artifacts, "local function ProcessTurn", "local function OnCombatOccurred")
check("ProcessNetworkHermesUnits(playerID);" in artifacts_turn
      and 'LOTM_MP_TurnSync.Add(ProcessTurn,"Artifacts")' in artifacts,
      "Artifacts must drain the Hermes queue before its synchronized turn settlement")
for callback_start, callback_end, label in (
    ("local function OnDiplomacyDeclareWar", "local function OnDiplomacyMakePeace", "Artifacts declare-war"),
    ("local function OnDiplomacyMakePeace", "local function OnUnitAdded", "Artifacts make-peace"),
):
    check_network_early_return(artifacts, callback_start, callback_end, label)

black = scripts[ROOT / "Scripts" / "LOTM_BE_BlackEmperor.lua"]
black_added = check_network_early_return(
    black, "local function OnUnitAddedToMap", "local function OnCivicCompleted",
    "Black Emperor UnitAdded",
)
black_turn = lua_slice(black, "local function OnPlayerTurnActivated", "local function OnCityBuilt")
check("LOTM_BE_RefreshSequenceState(playerID);" in black_turn
      and 'LOTM_MP_TurnSync.Add(OnPlayerTurnActivated,"BlackEmperor")' in black,
      "Black Emperor must refresh legacy builders from its synchronized player turn")
black_civic = lua_slice(black, "local function OnCivicCompleted", "local function ApplyResearchCompleted")
black_research = lua_slice(black, "local function OnResearchCompleted", "local function OnCityPopulationChanged")
black_transfer = lua_slice(black, "local function OnCityTransfered", "local function IsDefeatedUnit")
black_influence = lua_slice(black, "local function OnInfluenceChanged", "local function ApplyCityProjectCompleted")
black_trade = lua_slice(black, "local function OnTradeRouteActivityChanged", "local function OnCommandGoldPurchase")
black_project = lua_slice(black, "local function OnCityProjectCompleted", "local function ApplyNetworkCityTransfer")
check('QueueNetworkEvent(\n\t\t"CIVIC"' in black_civic
      and 'QueueNetworkEvent(\n\t\t"RESEARCH"' in black_research
      and 'QueueNetworkEvent(\n\t\t\t"CITY_TRANSFER"' in black_transfer
      and "LOTM_MP_TurnSync.IsNetworkGame() then\n\t\treturn;" in black_influence
      and 'QueueNetworkEvent("TRADE_ROUTE"' in black_trade
      and 'QueueNetworkEvent(\n\t\t"PROJECT"' in black_project,
      "every Black Emperor local event must queue a captured fact or return in multiplayer")
for body, tail_marker, label in (
    (black_civic, "local normalizedPlayerID", "Black Emperor civic"),
    (black_research, "local normalizedPlayerID", "Black Emperor research"),
    (black_trade, "local normalizedOriginPlayerID", "Black Emperor trade route"),
    (black_project, "local normalizedPlayerID", "Black Emperor project"),
):
    network_tail = body[body.find(tail_marker):]
    check(bool(network_tail) and not any(token in network_tail for token in NETWORK_MUTATION_TOKENS),
          f"{label} capture tail must remain read-only with respect to synchronized state")
black_processor = lua_slice(black, "ProcessNetworkEvents = function", "local function Initialize")
check("LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID)" in black_processor
      and "entry.QueuedTurn < currentTurn" in black_processor
      and "table.sort(ready, function(a, b)" in black_processor
      and "local count = math.max(1, tonumber(entry.Count) or 1);" in black_processor
      and black_processor.count('entry.Kind == "CIVIC"') == 1
      and black_processor.count('entry.Kind == "RESEARCH"') == 1
      and black_processor.count('entry.Kind == "TRADE_ROUTE"') == 1
      and black_processor.count('entry.Kind == "CITY_TRANSFER"') == 1
      and black_processor.count('entry.Kind == "PROJECT"') == 1
      and "for occurrence = 1, count do" in black_processor
      and re.search(r"(?<!i)pairs\s*\(", black) is None,
      "Black Emperor queue must use one reachable Count-aware deterministic dispatch")
black_startup = lua_slice(black, "LOTM_MP_TurnSync.RunStartup(function()", 'end,"BlackEmperor");')
check("SortedMajorIDs()" in black_startup and "table.sort(playerIDs);" in black_startup,
      "Black Emperor startup must apply player-wide modifiers in stable PlayerID order")

ai_cults = scripts[ROOT / "Scripts" / "LOTM_AI_Cults.lua"]
for callback_start, callback_end, label in (
    ("local function OnResearchCompleted", "local function OnDiplomacyChanged", "AI cult research"),
    ("local function OnDiplomacyChanged", "local function OnUnitAddedToMap", "AI cult diplomacy"),
    ("local function OnUnitAddedToMap", "LOTM_MP_TurnSync.Add(OnTurn", "AI cult UnitAdded"),
):
    check_network_early_return(ai_cults, callback_start, callback_end, label)
ai_turn = lua_slice(ai_cults, "local function OnTurn", "local function OnResearchCompleted")
check("LOTM_AI_Cults.Reconcile();" in ai_turn
      and 'LOTM_MP_TurnSync.Add(OnTurn,"AICults")' in ai_cults,
      "AI cult reconciliation must use the synchronized turn fallback in multiplayer")

churches = scripts[ROOT / "Scripts" / "LOTM_WORLD_Churches.lua"]
check_network_early_return(
    churches, "local function OnUnitAdded", "local function OnDiplomacyChanged",
    "World Churches UnitAdded",
)
check_network_early_return(
    churches, "local function OnDiplomacyChanged", "local function OnSendEnvoys",
    "World Churches diplomacy",
)
church_turn = lua_slice(churches, "local function OnPlayerTurn", "local function OnUnitAdded")
check("RefreshAllNightEnemyPenalties();" in church_turn
      and 'LOTM_MP_TurnSync.Add(OnPlayerTurn,"WorldChurches")' in churches
      and "GameEvents.OnUnitMoved.Add(OnUnitMoved)" in churches
      and "Events.UnitMoved" not in churches,
      "World Churches must refresh from the synchronized turn and keep OnUnitMoved as its sole direct movement ability entry")
church_sorted = lua_slice(churches, "RefreshAllNightEnemyPenalties=function()", "local function OnUnitMoved")
check("SortedIDs(ids)" in church_sorted
      and "SortedUnits(owner)" in church_sorted
      and "table.sort(barbarians" in church_sorted,
      "World Churches player, unit, and barbarian reconciliation must be stably ordered")

hanged = scripts[ROOT / "Scripts" / "LOTM_AI_Cult_Hanged.lua"]
hanged_added = check_network_queue_callback(
    hanged, "local function TryMarkNewUnit", "function LOTM_AI_Cult_Hanged.ReconcileAll",
    "QueueNetworkUnitInitialized", "Hanged UnitInitialized",
)
hanged_capture = lua_slice(hanged, "local function QueueNetworkUnitInitialized", "local function ProcessNetworkUnitInitializations")
check(bool(hanged_capture)
      and not any(token in hanged_capture for token in NETWORK_MUTATION_TOKENS)
      and all(token in hanged_capture for token in ("CaptureNewUnit", "QueuedTurn=Game.GetCurrentGameTurn()")),
      "Hanged network UnitInitialized capture must remain read-only and record the event turn")
hanged_processor = check_network_processor(
    hanged, "local function ProcessNetworkUnitInitializations", "local function TryMarkNewUnit",
    ("table.sort(ready,function(a,b)", "a.PlayerID~=b.PlayerID", "a.UnitID<b.UnitID"),
    "ApplyCapturedNewUnit(entry)", "Hanged UnitInitialized queue",
)
hanged_turn = lua_slice(hanged, "local function OnTurn", "local function OnUnitRemoved")
hanged_removed = lua_slice(hanged, "local function OnUnitRemoved", "local function SettleAttackFaith")
check("ProcessNetworkUnitInitializations(playerID);" in hanged_turn
      and 'LOTM_MP_TurnSync.Add(OnTurn,"AICultHanged")' in hanged
      and "entry.Cancelled=true;" in hanged_removed
      and "pendingNetworkUnitKeys[key]=nil" in hanged_removed,
      "Hanged queued UnitInitialized entries must drain on turn and cancel cleanly on removal")

perfect = scripts[ROOT / "Scripts" / "LOTM_PP_Perfect.lua"]
perfect_added = check_network_queue_callback(
    perfect, "local function OnUnitAddedToMap", "local function OnUnitRemovedFromMap",
    "QueueNetworkScientistUnit", "Perfect UnitAdded",
)
perfect_processor = check_network_processor(
    perfect, "local function ProcessNetworkScientistUnits", "local function OnTechBoostTriggered",
    ("table.sort(ready, function(a,b)", "a.PlayerID ~= b.PlayerID", "a.UnitID < b.UnitID"),
    "CommitScientistRecruitment(entry.PlayerID, entry.UnitID)", "Perfect scientist queue",
)
perfect_removed = lua_slice(perfect, "local function OnUnitRemovedFromMap", "local function OnCityProjectCompleted")
check("entry.RemovedBeforeSettlement = true;" in perfect_removed
      and "entry.Cancelled" not in perfect_removed,
      "Perfect scientist removal must preserve the captured event until synchronized settlement")
perfect_commit = lua_slice(perfect, "local function CommitScientistRecruitment", "local function ProcessScientistRecruitment")
ledger_position = perfect_commit.find("player:SetProperty(ledgerKey, 1);")
digestion_position = perfect_commit.find("LOTM_RP_State.TryAddDigestion")
serial_position = perfect_commit.find("NextEventSerial")
check(ledger_position >= 0 and digestion_position > ledger_position and serial_position > digestion_position,
      "Perfect scientist ledger must commit before digestion and its event serial")
perfect_mark = lua_slice(perfect, "local function MarkExistingScientists", "local function CommitScientistRecruitment")
perfect_startup = lua_slice(perfect, "LOTM_MP_TurnSync.RunStartup(function()", 'end,"Perfect");')
check("table.sort(units, function(a,b)" in perfect_mark
      and "table.sort(playerIDs);" in perfect_startup
      and perfect_startup.rfind("Game.SetProperty(SCIENTIST_LEDGER_VERSION_KEY")
          > perfect_startup.find("for _, playerID in ipairs(playerIDs)"),
      "Perfect old-save scientist migration must sort units/players and write its version only after the migration")

phase9 = scripts[ROOT / "Scripts" / "LOTM_RESCUE_Phase9.lua"]
phase9_added = check_network_queue_callback(
    phase9, "local function OnUnitAdded", "local function OnUnitRemoved",
    "QueueNetworkUnitAdded", "Rescue Phase 9 UnitAdded",
)
phase9_processor = check_network_processor(
    phase9, "local function ProcessNetworkUnitAdditions", "local function ReconcileLegacy",
    ("table.sort(ready,function(a,b)", "a.PlayerID~=b.PlayerID", "a.UnitID<b.UnitID"),
    "AddIndexedUnit(entry.PlayerID,unit)", "Rescue Phase 9 UnitAdded queue",
)
check("RetireLegacyConquestAbilityFromUnit(player,unit);" in phase9_processor,
      "Rescue Phase 9 must retire legacy unit abilities inside the ordered queue consumer")
phase9_removed = lua_slice(phase9, "local function OnUnitRemoved", 'LOTM_MP_TurnSync.Add(OnTurn,"RescuePhase9")')
phase9_turn = lua_slice(phase9, "local function OnTurn", "local function OnUnitAdded")
phase9_reconcile = lua_slice(phase9, "function LOTM_RESCUE_Phase9.ReconcileAll", "local function OnTurn")
phase9_migration = lua_slice(phase9, "local function MigrateCombatIndex", "local function ReconcileAI")
check("entry.Cancelled=true;" in phase9_removed
      and "pendingNetworkUnitKeys[key]=nil" in phase9_removed
      and "RemoveIndexedUnit(playerID,unitID);" in phase9_removed
      and "ProcessNetworkUnitAdditions(playerID);" in phase9_turn,
      "Rescue Phase 9 must cancel removed queued units and drain additions from its synchronized turn")
check("for _,player in ipairs(AliveMajors())" in phase9_reconcile
      and "for _,unit in ipairs(SortedUnits(player))" in phase9_migration
      and "table.sort(result,function(a,b) return a:GetID()<b:GetID(); end)" in phase9,
      "Rescue Phase 9 migrations must sort players and units before authoritative writes")

digestion = scripts[ROOT / "Scripts" / "LOTM_RESCUE_Phase9Digestion.lua"]
digestion_added = check_network_queue_callback(
    digestion, "local function OnUnitAdded", "local function OnUnitRemoved",
    "QueueNetworkObservation", "Rescue Phase 9 digestion UnitAdded",
)
digestion_processor = check_network_processor(
    digestion, "local function ProcessNetworkObservations", "local function Defeated",
    ("table.sort(ready,function(a,b)", "a.PlayerID~=b.PlayerID", "a.UnitID<b.UnitID"),
    "WriteObservation(entry.PlayerID,entry.UnitID", "Rescue Phase 9 observation queue",
)
digestion_removed = lua_slice(digestion, "local function OnUnitRemoved", "GameEvents.LOTM_RESCUE_P9_Command_GoldMilitaryPurchase")
check("entry.Cancelled=true;" in digestion_removed
      and "pendingNetworkObservationKeys[key]=nil" in digestion_removed,
      "Rescue Phase 9 observation queue must cancel units removed before settlement")
digestion_damage = lua_slice(digestion, "local function OnUnitDamageChanged", "local function ClearNetworkDamageEvidence")
digestion_damage_network = network_prefix(digestion_damage)
check("return" in digestion_damage_network
      and not any(token in digestion_damage_network for token in NETWORK_MUTATION_TOKENS)
      and "recentNetworkDamage[" not in digestion_damage_network,
      "network UnitDamageChanged must be a non-authoritative no-op")
digestion_combat = lua_slice(digestion, "local function OnCombat(", "local function OnCombatCountAttack")
check('Game.GetProperty(defenderDamageKey..":SYNC_CURRENT")' in digestion_combat
      and "ObserveUnit(attackerPlayerID,attackerUnitID)" in digestion_combat
      and "ObserveUnit(defenderPlayerID,defenderUnitID)" in digestion_combat
      and "if not defeated then" in digestion_combat,
      "synchronized OnCombatOccurred must compare and refresh durable damage checkpoints")
digestion_turn = lua_slice(digestion, "local function OnTurn", "local function OnUnitAdded")
check("ProcessNetworkObservations(playerID);" in digestion_turn
      and "LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID)" in digestion_processor
      and "entry.QueuedTurn<currentTurn" in digestion_processor
      and 'LOTM_MP_TurnSync.Add(OnTurn,"RescuePhase9DigestionRuntime")' in digestion,
      "Rescue Phase 9 digestion must drain observations after a full turn at the stable anchor")

phase10 = scripts[ROOT / "Scripts" / "LOTM_RESCUE_Phase10.lua"]
phase10_damage = lua_slice(phase10, "local function OnUnitDamageChanged", "local function OnCombat")
phase10_network_start = phase10_damage.find("if IsNetworkMultiplayer() then")
phase10_network_end = phase10_damage.find("\n end\n local key=", phase10_network_start)
phase10_network_damage = phase10_damage[phase10_network_start:phase10_network_end]
check("return" in phase10_network_damage
      and not any(token in phase10_network_damage for token in NETWORK_MUTATION_TOKENS)
      and not any(token in phase10_network_damage for token in (
          "m_nativeDamageEvents", "m_bossCombatEvents", "m_nativeDamageCorrections",
          "QueueNetworkBossDamage", "ResolveBossDefeat(",
      )), "Rescue Phase 10 network UnitDamageChanged must be a non-authoritative no-op")
phase10_network_correction = lua_slice(
    phase10, "local function CorrectNetworkGodCombatDamage", "local function OnUnitDamageChanged",
)
phase10_combat = lua_slice(phase10, "local function OnCombat", "local function ApplyRemoved")
check("local desired=CombatStrengthDamage(attack,defense)" in phase10_network_correction
      and "if not isBoss and desired>=maximum then" in phase10_network_correction
      and "pcall(UnitManager.Kill,unit)" in phase10_network_correction
      and phase10_network_correction.index("if not isBoss and desired>=maximum then")
          < phase10_network_correction.index("if not isBoss then return; end")
      and "if not isBoss then return; end" in phase10_network_correction
      and "unit:GetProperty(CONFIRMED_DAMAGE_PROPERTY)" in phase10_network_correction
      and "if stored==nil then" in phase10_network_correction
      and "reason=CONFIRMED_DAMAGE_MISSING" in phase10_network_correction
      and "if current<=confirmed then" in phase10_network_correction
      and "reason=NATIVE_DAMAGE_NOT_OBSERVED" in phase10_network_correction
      and "stored==nil and 0" not in phase10_network_correction
      and "local observed=math.max(0,current-confirmed)" in phase10_network_correction
      and "local extra=math.max(0,desired-observed)" in phase10_network_correction
      and "PublishNetworkConfirmedDamage(UnitManager.GetUnit(playerID,unitID))" in phase10_network_correction
      and 'if defenderIsBoss or IsGod(attacker) then CorrectNetworkGodCombatDamage(defender,"DEFENDER",attack,defense,defenderIsBoss); end' in phase10_combat
      and 'if not ranged and (attackerIsBoss or IsGod(defender)) then CorrectNetworkGodCombatDamage(attacker,"ATTACKER_RETALIATION",retaliation,attackerDefense,attackerIsBoss); end' in phase10_combat
      and "PublishNetworkConfirmedDamage(UnitManager.GetUnit(attackerPlayerID,attackerUnitID))" not in phase10_combat
      and "PublishNetworkConfirmedDamage(UnitManager.GetUnit(defenderPlayerID,defenderUnitID))" not in phase10_combat,
      "Rescue Phase 10 must allow baseline-free saturated god kills while requiring post-native evidence and a current-Boss checkpoint for nonlethal correction")
check(all(token not in phase10 for token in (
    "m_pendingNetworkBossDamage", "QueueNetworkBossDamage",
    "ProcessNetworkCombatEvidence", "ProcessNetworkBossDamage",
)), "Rescue Phase 10 must not defer network damage through client-local evidence queues")
phase10_removed = lua_slice(phase10, "local function OnRemoved", "local function ProcessNetworkRemovals")
phase10_removed_network = phase10_removed[phase10_removed.find("if IsNetworkMultiplayer() then"):]
check("QueueNetworkRemoval(playerID,unitID,role); return;" in phase10_removed_network
      and not any(token in phase10_removed_network.split("return;", 1)[0]
                  for token in NETWORK_MUTATION_TOKENS),
      "Rescue Phase 10 UnitRemoved must only capture a local removal fact in multiplayer")
phase10_removal_processor = lua_slice(
    phase10, "local function ProcessNetworkRemovals", "local function OnUnitMoveComplete",
)
check("IsNetworkMultiplayer()" in phase10_removal_processor
      and "LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID)" in phase10_removal_processor
      and re.search(r"QueuedTurn\s*<\s*currentTurn", phase10_removal_processor) is not None
      and all(token in phase10_removal_processor for token in (
          "table.sort(ready,function(a,b)", "a.QueuedTurn~=b.QueuedTurn",
          "a.PlayerID~=b.PlayerID", "a.UnitID~=b.UnitID", "a.Role<b.Role",
          "ApplyRemoved(entry.PlayerID,entry.UnitID",
      )),
      "Rescue Phase 10 removal queue must settle only at a stable next-turn anchor in deterministic order")
phase10_move = lua_slice(phase10, "local function OnUnitMoveComplete", "local function OnSynchronizedRefresh")
check("if IsNetworkMultiplayer() then return; end" in phase10_move,
      "Rescue Phase 10 local UnitMove must not mutate synchronized visibility in multiplayer")

lifecycle = scripts[ROOT / "Scripts" / "LOTM_RP_Lifecycle.lua"]
lifecycle_initialized = lua_slice(
    lifecycle, "local function OnUnitInitialized", "-- TEST ONLY: authoritative reversible +200 combat toggle",
)
check("IsHeroUnit(unit) and not LOTM_MP_TurnSync.IsNetworkGame()" in lifecycle_initialized
      and "ResolveDuplicateHeroes(playerID);" in lifecycle_initialized
      and not any(token in lifecycle_initialized for token in NETWORK_MUTATION_TOKENS),
      "Lifecycle UnitInitialized must leave duplicate-hero mutation to single-player only")
check("table.sort(playerIDs);" in lua_slice(
          lifecycle, "local function ProcessAllPlayers", "local function OnSelectPath"),
      "Lifecycle startup hero creation must be stably ordered by PlayerID")

progression = scripts[ROOT / "Scripts" / "LOTM_RP_Progression.lua"]
check_network_early_return(
    progression, "local function OnUnitMoveComplete", "local function OnGoodyHutReward",
    "Red Priest progression UnitMove",
)
check_network_early_return(
    progression, "local function OnGoodyHutReward", "local function CountStrongerTargetAttack",
    "Red Priest progression goody reward",
)
progression_project = lua_slice(
    progression, "local function OnCityProjectCompleted", "local function Initialize",
)
progression_project_tail = progression_project[progression_project.find("local provoker ="):]
check("pendingNetworkProjects[#pendingNetworkProjects + 1] = entry;" in progression_project_tail
      and not any(token in progression_project_tail for token in NETWORK_MUTATION_TOKENS)
      and "entry.QueuedTurn < currentTurn" in progression
      and "LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID)" in progression
      and "table.sort(playerIDs);" in progression,
      "Red Priest project completion must be a read-only local capture settled at a sorted stable anchor")

advanced = scripts[ROOT / "Scripts" / "LOTM_RP_Advanced.lua"]
check_network_early_return(
    advanced, "local function OnDiplomacyWarStateChanged", "local function ProcessFormationDigestion",
    "Red Priest advanced diplomacy",
)
advanced_project = lua_slice(
    advanced, "local function OnCityProjectCompleted", "local function ProcessNetworkProjects",
)
advanced_project_tail = advanced_project[advanced_project.find("local normalizedPlayerID"):]
check("pendingNetworkProjects[#pendingNetworkProjects+1]=entry" in advanced_project_tail
      and not any(token in advanced_project_tail for token in NETWORK_MUTATION_TOKENS)
      and "entry.QueuedTurn<currentTurn" in advanced
      and "LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID)" in advanced
      and "table.sort(playerIDs);" in advanced,
      "advanced project completion must be a read-only local capture settled at a sorted stable anchor")

thief = scripts[ROOT / "Scripts" / "LOTM_TP_Thief.lua"]
for callback_start, callback_end, queue_kind, label in (
    ("local function OnResearchCompleted", "local function OnCivicCompleted", 'QueueNetworkEvent("RESEARCH"', "Thief research"),
    ("local function OnCivicCompleted", "local function OnCityProjectCompleted", 'QueueNetworkEvent("CIVIC"', "Thief civic"),
    ("local function OnCityProjectCompleted", "local function ProcessNetworkEvents", 'QueueNetworkEvent("PROJECT"', "Thief project"),
):
    body = lua_slice(thief, callback_start, callback_end)
    queue_start = body.find(queue_kind)
    check(queue_start >= 0
          and not any(token in body[queue_start:] for token in NETWORK_MUTATION_TOKENS),
          f"{label} network callback must only capture a local fact")
check("entry.QueuedTurn<currentTurn" in thief
      and "LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID)" in thief
      and "table.sort(ready,function(a,b)" in thief
      and 'GiftGuardTechIndex = "LOTM_TP_GIFT_GUARD_TECH_INDEX"' in thief
      and 'GiftGuardCivicIndex = "LOTM_TP_GIFT_GUARD_CIVIC_INDEX"' in thief
      and "guardIndex==nil or guardIndex==tonumber(techIndex)" in thief
      and "guardIndex==nil or guardIndex==tonumber(civicIndex)" in thief
      and "ApplyCityProjectCompleted(entry.PlayerID,entry.CityID,entry.ObjectID,entry.QueuedTurn)" in thief,
      "Thief queue must distinguish nested gifts, preserve event turns, and settle in stable order")

rescue_thief = scripts[ROOT / "Scripts" / "LOTM_RESCUE_Thief.lua"]
rescue_project = lua_slice(
    rescue_thief, "local function OnCityProjectCompleted", "local function ProcessPotionProjects",
)
check("pendingPotionProjects[#pendingPotionProjects+1]=entry" in rescue_project
      and not any(token in rescue_project for token in NETWORK_MUTATION_TOKENS)
      and "ApplyPotionProjectCompleted(playerID,cityID,projectID,nil)" in rescue_project
      and "PathPlayer(playerID)" in rescue_project,
      "Rescue Thief potion completion must queue network facts and only mutate directly in single-player")
check("entry.QueuedTurn<turn" in rescue_thief
      and "LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID)" in rescue_thief
      and "table.sort(ready,function(a,b)" in rescue_thief
      and "ApplyPotionProjectCompleted(entry.PlayerID,entry.CityID,entry.ProjectID,entry.QueuedTurn)" in rescue_thief,
      "Rescue Thief potion queue must settle at a deterministic next-turn anchor")

phase10a = scripts[ROOT / "Scripts" / "LOTM_RESCUE_Phase10A.lua"]
check_network_queue_callback(
    phase10a, "local function OnCityProjectCompleted", "function LOTM_RESCUE_Phase10A.RefreshAll",
    "QueueNetworkCityProjectCompleted", "Rescue Phase 10A project",
)
phase10a_processor = check_network_processor(
    phase10a, "local function ProcessNetworkCityProjectCompletions", "local function OnCityProjectCompleted",
    ("table.sort(ready,function(a,b)", "a.PlayerID~=b.PlayerID", "a.CityID~=b.CityID", "a.ProjectID<b.ProjectID"),
    "ApplyCityProjectCompleted(entry.PlayerID,entry.CityID,entry.ProjectID)",
    "Rescue Phase 10A project queue",
)
check("city changed; preserving completion" in phase10a_processor
      and "cityStillOwned" in phase10a_processor,
      "Phase 10A must diagnose city ownership changes without discarding a captured completion")

workshops = scripts[ROOT / "Scripts" / "LOTM_PP_Workshops.lua"]
check("Game.GetRandNum(" not in workshops, "workshop callbacks must not advance synchronized RNG")
check("Game.GetRandNum(" not in thief, "Thief turn callbacks must use stable seed hashing, not synchronized RNG")
rescue_mode_start = workshops.index("local function IsRescueMode()")
rescue_mode_end = workshops.index("local function NormalizeStableValue", rescue_mode_start)
rescue_mode = workshops[rescue_mode_start:rescue_mode_end]
check('type(LOTM_MP_TurnSync.IsRescueModeConfigured)=="function"' in rescue_mode
      and "LOTM_MP_TurnSync.IsRescueModeConfigured()" in rescue_mode
      and rescue_mode.index("LOTM_MP_TurnSync.IsRescueModeConfigured()")
      < rescue_mode.index('Game.GetProperty("LOTM_RESCUE_MODE")'),
      "workshop rescue detection must prefer the criteria-selected database marker before the Phase 1 Property exists")

workshop_added = lua_slice(workshops, "local function OnUnitAdded", "local function OnUnitMoved")
workshop_process_added = lua_slice(workshops, "local function ProcessUnitAdded", "local function ProcessNetworkLocalUnitAdditions")
workshop_process_network = network_prefix(workshop_process_added)
check("ProcessUnitAdded(playerID,unitID,x,y,false,nil);" in workshop_added
      and "QueueLocalNetworkUnitAdded(playerID,unitID,x,y);" in workshop_process_network
      and "return" in workshop_process_network
      and not any(token in workshop_process_network for token in NETWORK_MUTATION_TOKENS),
      "Workshops UnitAdded must enter the Lua-local queue before any network Gameplay mutation")
workshop_local_capture = lua_slice(workshops, "local function QueueLocalNetworkUnitAdded", "local function ProcessUnitAdded")
check("local queuedTurn=Game.GetCurrentGameTurn()" in workshop_local_capture
      and "LocalNetworkUnitBatchKey(normalizedPlayerID,normalizedUnitID,queuedTurn)" in workshop_local_capture
      and "m_networkUnitRemovalBatches[key]~=nil" in workshop_local_capture
      and "local unitType=unit~=nil and unit:GetType() or nil" in workshop_local_capture
      and "CaptureToken=captureToken,RemovedBeforeSettlement=false" in workshop_local_capture
      and "existing.Ambiguous=true; existing.Cancelled=true;" in workshop_local_capture
      and "m_networkUnitGenerationOrdinals" not in workshops
      and "unit:GetProperty(MP_UNIT_GENERATION_PROPERTY)~=nil" in workshop_local_capture
      and not any(token in workshop_local_capture for token in NETWORK_MUTATION_TOKENS),
      "Workshops local UnitAdded capture must preserve event facts without synchronized writes")
workshop_local_processor = check_network_processor(
    workshops, "local function ProcessNetworkLocalUnitAdditions", "local function OnUnitAdded",
    ("table.sort(ready,function(a,b)", "a.QueuedTurn~=b.QueuedTurn", "a.PlayerID~=b.PlayerID",
     "a.UnitID~=b.UnitID", "(a.X or -1)", "(a.Y or -1)"),
    "ProcessUnitAdded(entry.PlayerID,entry.UnitID,entry.X,entry.Y,true,entry.QueuedTurn,",
    "Workshops local UnitAdded queue",
)
check("entry.UnitType,entry.Filtered,nil,entry.RemovedBeforeSettlement" in workshop_local_processor
      and "capturedRemoved==true" in workshop_process_added
      and "if generationDetached then u=nil; end" in workshop_process_added
      and "NextSynchronizedUnitGeneration(entry.PlayerID,entry.UnitID)" not in workshop_local_processor
      and "NextSynchronizedUnitGeneration(" not in workshop_process_added,
      "Workshops delayed UnitAdded must detach a removed or mismatched engine generation")

workshop_unit_removed = lua_slice(workshops, "local function OnUnitRemoved", "local function ProcessNetworkUnitRemovals")
workshop_unit_removed_network = network_prefix(workshop_unit_removed)
check("m_networkUnitRemovalBatches[batchKey]=removedTurn;" in workshop_unit_removed
      and "if pending.QueuedTurn==removedTurn then" in workshop_unit_removed
      and "pending.Cancelled=true;" in workshop_unit_removed
      and "pending.RemovedBeforeSettlement=true;" in workshop_unit_removed
      and "QueueNetworkUnitRemoved(playerID,unitID);" in workshop_unit_removed_network
      and "return" in workshop_unit_removed_network
      and not any(token in workshop_unit_removed_network for token in NETWORK_MUTATION_TOKENS),
      "Workshops UnitRemoved must tombstone every same-turn ID addition without a Gameplay write")
check("table.sort(m_networkUnitRemovalBatchKeys)" in workshop_local_processor
      and "for _,key in ipairs(m_networkUnitRemovalBatchKeys) do" in workshop_local_processor
      and "removedTurn<currentTurn" in workshop_local_processor
      and "m_networkUnitRemovalBatchKeys=retainedRemovalBatchKeys" in workshop_local_processor
      and "pairs(m_networkUnitRemovalBatches)" not in workshop_local_processor,
      "Workshops unit removal tombstones must survive the whole local callback batch and then be bounded")


def normalize_workshop_unit_batch(
    events: tuple[tuple[str, int, int, int, str], ...],
) -> tuple[tuple[int, int, int, str], ...]:
    """Model the reviewed local-publication contract, independent of order."""
    additions: dict[tuple[int, int, int], str] = {}
    tombstones: set[tuple[int, int, int]] = set()
    ambiguous: set[tuple[int, int, int]] = set()
    for kind, turn, owner, unit_id, capture in events:
        key = (turn, owner, unit_id)
        if kind == "REMOVE":
            tombstones.add(key)
            additions.pop(key, None)
        elif key not in tombstones and key not in ambiguous:
            previous = additions.get(key)
            if previous is None:
                additions[key] = capture
            elif previous != capture:
                additions.pop(key, None)
                ambiguous.add(key)
    return tuple(sorted((*key, capture) for key, capture in additions.items()
                        if key not in tombstones and key not in ambiguous))


reused_id_batch = (
    ("ADD", 41, 63, 7, "old-type@10,10"),
    ("REMOVE", 41, 63, 7, ""),
    ("ADD", 41, 63, 7, "new-type@10,10"),
)
check({normalize_workshop_unit_batch(order) for order in permutations(reused_id_batch)} == {()},
      "Workshops same-turn UnitID reuse must be removal-wins for every Add/Remove permutation")
duplicate_add_batch = (
    ("ADD", 42, 63, 8, "type@11,10"),
    ("ADD", 42, 63, 8, "type@11,10"),
)
check({normalize_workshop_unit_batch(order) for order in permutations(duplicate_add_batch)}
      == {((42, 63, 8, "type@11,10"),)},
      "Workshops duplicate UnitAdded publications must normalize to one persistent fact")
conflicting_add_batch = (
    ("ADD", 43, 63, 9, "old-type@12,10"),
    ("ADD", 43, 63, 9, "new-type@12,10"),
)
check({normalize_workshop_unit_batch(order) for order in permutations(conflicting_add_batch)} == {()},
      "Workshops conflicting same-batch additions without an identity boundary must fail closed")

workshop_persistent_enqueue = lua_slice(
    workshops, "local function QueueNetworkWorkshopUnitAddition", "local function CreateNetworkExtra",
)
generation_allocation = 'if generation=="" then generation=NextSynchronizedUnitGeneration(owner,unitID); end'
check(generation_allocation in workshop_persistent_enqueue
      and workshop_persistent_enqueue.index("for _,entry in ipairs(entries) do")
          < workshop_persistent_enqueue.index(generation_allocation)
      and "return tostring(entry.Generation or \"\"),false;" in workshop_persistent_enqueue
      and "return generation,true;" in workshop_persistent_enqueue
      and workshop_process_added.count("QueueNetworkWorkshopUnitAddition(") == 1,
      "Workshops generation may advance only after a fact wins normalization and persistent deduplication")
workshop_persistent_units = lua_slice(
    workshops, "local function ProcessNetworkWorkshopUnitAddition", "local function ProcessNetworkWorkshopUnitAdditions",
)
check(all(token in workshops for token in (
          'local MP_UNIT_GENERATION_PROPERTY="LOTM_PP_WORKSHOP_MP_UNIT_GENERATION"',
          "Type=unitType,Removed=removed,Generation=generation",
          "CampEpoch=normalizedCampEpoch",
          "local function NextSynchronizedUnitGeneration",
          "SaveNetworkPendingUnitAdditions(entries);",
      ))
      and all(token in workshop_persistent_units for token in (
          "local generationMatches=entry.Removed~=true", "unit:GetType()==entry.Type",
          "unit:GetProperty(MP_UNIT_GENERATION_PROPERTY)", "if stage<1 and generationMatches then",
          'NetworkUnitStageKey(entry,"COUNT_TARGET")',
          "CreateNetworkExtra(entry.Type,camp,entry)",
          "TrySpawnFromWorkshopNetwork(camp,entry.Owner,eventToken)",
          "capturedCampEpoch~=nil and currentCampEpoch~=capturedCampEpoch",
          'return true,"STALE_CAMP_GENERATION"',
      ))
      and workshop_persistent_units.index("if stage<1 and generationMatches then")
          < workshop_persistent_units.index('NetworkUnitStageKey(entry,"COUNT_TARGET")'),
      "Workshops persistent queue must keep dead-event derivatives while never mutating a reused unit generation")
check("RecoverNetworkWorkshopUnitsAtStartup" not in workshops
      and "startup recovered uncaptured workshop units=" not in workshops,
      "Workshops startup must not infer UnitAdded facts by scanning all barbarian units")
camp_reset = lua_slice(workshops, "local function ResetCampGeneration", "local function EnsureCampGeneration")
camp_generation = lua_slice(workshops, "local function EnsureCampGeneration", "local function Classify")
camp_additions = lua_slice(workshops, "local function ProcessNetworkImprovementAdditions", "local function NearestWorkshop")
check(all(token in camp_reset for token in (
          "CLEARER,CLEARER_UNIT", "MP_PENDING,MP_PENDING_OWNER", "MP_PENDING_CLEARER",
          "MP_PENDING_CLEARER_UNIT", "MP_PENDING_LEVEL", "MP_PENDING_PATH",
          "MP_PENDING_CLASSIFIED_TURN", "MP_PENDING_CAMP_EPOCH", "MP_PENDING_QUEUED_TURN", "MP_CHURCH_SETTLED",
          "MP_PHASE4_SETTLED", "MP_REWARD_SETTLED", "CAMP_REBUILD_PENDING",
          "RemoveNetworkPendingSettlementIndex(plotIndex)",
      ))
      and "(plot:GetProperty(MP_PENDING) or 0)==1" in camp_generation
      and "plot:SetProperty(CAMP_REBUILD_PENDING,1)" in camp_generation
      and "return false" in camp_generation
      and "entry.Rebuilt==true or m_networkImprovementRemovedPlots[plotIndex]==true" in camp_additions,
      "Workshops camp generations must settle the old epoch before clearing every plot-backed checkpoint")
check("m_networkImprovementRemovedPlots[camp:GetIndex()]==true" in workshop_process_added
      and workshop_process_added.index("m_networkImprovementRemovedPlots[camp:GetIndex()]==true")
          < workshop_process_added.index("QueueNetworkWorkshopUnitAddition("),
      "Workshops must reject a same-batch unit fact before allocating a generation for a rebuilt camp")
check_network_processor(
    workshops, "local function ProcessNetworkUnitRemovals", "local function OnCombat",
    ("table.sort(ready,function(a,b)", "a.QueuedTurn~=b.QueuedTurn", "a.PlayerID~=b.PlayerID",
     "a.UnitID~=b.UnitID", "a.KillerPlayerID", "a.KillerUnitID"),
    "ProcessUnitRemoved(entry.PlayerID,entry.UnitID", "Workshops UnitRemoved queue",
)
workshop_scripted_capture = lua_slice(
    workshops, "local function QueueNetworkUnitRemoved", "local function OnUnitRemoved",
)
workshop_scripted_consumer = lua_slice(
    workshops, "local function ProcessUnitRemoved", "local function QueueNetworkUnitRemoved",
)
check(all(token in workshop_scripted_capture for token in (
          'Game.GetProperty(prefix.."TARGET_KIND")', 'prefix.."TARGET_SERIAL"',
          '~="SEQUENCE"', "~=sequenceSerial then return",
      ))
      and all(token in workshop_scripted_consumer for token in (
          'Game.GetProperty(prefix.."TARGET_KIND")', 'prefix.."TARGET_SERIAL"',
          '=="SEQUENCE"', "==expectedSerial", "if scriptedIdentityMatches then",
      )),
      "Workshops scripted-killer capture/cleanup must bind to the exact sequence serial")
workshop_improvement_removed = lua_slice(workshops, "local function OnRemoved", "local function Dead")
workshop_improvement_removed_network = network_prefix(workshop_improvement_removed)
check("QueueNetworkImprovementRemoved(x,y,ownerID);" in workshop_improvement_removed_network
      and "return" in workshop_improvement_removed_network
      and not any(token in workshop_improvement_removed_network for token in NETWORK_MUTATION_TOKENS),
      "Workshops ImprovementRemoved must queue before unregistering or settling in multiplayer")
check_network_processor(
    workshops, "local function ProcessNetworkImprovementRemovals", "local function Dead",
    ("table.sort(ready,function(a,b)", "a.QueuedTurn~=b.QueuedTurn", "a.PlotIndex~=b.PlotIndex",
     "a.OwnerID", "a.X", "a.Y"),
    "OnRemoved(entry.X,entry.Y,entry.OwnerID,true,entry.CampEpoch)", "Workshops ImprovementRemoved queue",
)
workshop_removed_capture = lua_slice(
    workshops, "local function QueueNetworkImprovementRemoved", "local function OnRemoved",
)
check("Units.GetUnitsInPlot" not in workshop_removed_capture
      and "Clearer=" not in workshop_removed_capture
      and not any(token in workshop_removed_capture for token in NETWORK_MUTATION_TOKENS),
      "workshop local removal publication must not assign reward authority from local occupancy")
workshop_reward_resolver = lua_slice(
    workshops, "local function StableNetworkClearer", "QueueNetworkWorkshopSettlement=function",
)
check("plot:GetProperty(CLEARER)" in workshop_reward_resolver
      and "Units.GetUnitsInPlot" in workshop_reward_resolver
      and "table.sort(candidates,function(a,b)" in workshop_reward_resolver,
      "network workshop rewards must preserve clearer priority and the stable shared-boundary fallback")

network_improvement_start = workshops.index("local function QueueNetworkImprovementAdded")
network_improvement_end = workshops.index("local function ClassifySinglePlayerImprovementAdded",
                                          network_improvement_start)
network_improvement_callback = workshops[network_improvement_start:network_improvement_end]
check(all(token not in network_improvement_callback for token in (
    "Classify(", "EnsureSequence(", "UnitManager.", "ChangeAbilityCount(",
    ":SetProperty(", "Game.SetProperty(",
)), "network ImprovementAddedToMap callback must not allocate a unit, DynamicModifier, or ability")
check("m_networkImprovementAdditions[plotIndex]={QueuedTurn=queuedTurn,PlotIndex=plotIndex," in network_improvement_callback
      and "Rebuilt=m_networkImprovementRemovedPlots[plotIndex]==true" in network_improvement_callback
      and "Events.ImprovementAddedToMap.Add(QueueNetworkImprovementAdded);" in workshops
      and "Events.ImprovementAddedToMap.Add(ClassifySinglePlayerImprovementAdded);" in workshops,
      "network and single-player improvement callbacks must be explicitly separated")

network_improvement_processor_start = workshops.index("local function ProcessNetworkImprovementAdditions")
network_improvement_processor_end = workshops.index("local function NearestWorkshop",
                                                     network_improvement_processor_start)
network_improvement_processor = workshops[
    network_improvement_processor_start:network_improvement_processor_end
]
classification_start = workshops.index("local function Classify(plot)")
classification_end = workshops.index("local function QueueNetworkImprovementAdded",
                                     classification_start)
classification = workshops[classification_start:classification_end]
registration_start = workshops.index("local function RegisterWorkshopPlot(plot)")
registration_end = workshops.index("local function UnregisterWorkshopPlot",
                                   registration_start)
registration = workshops[registration_start:registration_end]
check("LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID)" in network_improvement_processor
      and "entry.QueuedTurn<currentTurn" in network_improvement_processor
      and "table.sort(m_networkImprovementPlots);" in network_improvement_processor
      and "Classify(plot);" in network_improvement_processor
      and "RegisterWorkshopPlot(plot);" in classification
      and "EnsureSequence(plot);" in classification
      and "SaveWorkshopRegistry();" in registration,
      "network improvement queue must cross a full turn, then classify/register/save/create in stable PlotIndex order at the shared anchor")
workshop_turn_start = workshops.index("local function OnTurn(playerID,isFirstTimeThisTurn)")
workshop_turn_end = workshops.index("local function Initialize()", workshop_turn_start)
workshop_turn = workshops[workshop_turn_start:workshop_turn_end]
expected_workshop_network_order = (
    "ProcessNetworkImprovementRemovals(playerID);",
    "ProcessNetworkUnitRemovals(playerID);",
    "ProcessNetworkImprovementAdditions(playerID);",
    "ProcessNetworkLocalUnitAdditions(playerID);",
    "ProcessNetworkWorkshopUnitAdditions(playerID);",
    "ProcessNetworkWorkshopSettlements(playerID);",
)
workshop_network_positions = [workshop_turn.find(token) for token in expected_workshop_network_order]
check(all(position >= 0 for position in workshop_network_positions)
      and workshop_network_positions == sorted(workshop_network_positions),
      "Workshops synchronized turn must drain removal, classification, capture, unit, and settlement queues in the reviewed order")


def settle_same_plot_workshop_batch(events: tuple[str, ...]) -> bool:
    """Return whether the batch can persist its captured unit addition."""
    removal_fact = False
    addition_rebuilt = False
    unit_captured = False
    for event in events:
        if event == "CAMP_REMOVE":
            removal_fact = True
        elif event == "CAMP_ADD":
            addition_rebuilt = addition_rebuilt or removal_fact
        elif event == "UNIT_ADD":
            unit_captured = True
    rebuild_requested = addition_rebuilt or removal_fact
    return unit_captured and not rebuild_requested and not removal_fact


same_plot_workshop_batch = ("CAMP_REMOVE", "CAMP_ADD", "UNIT_ADD")
check({settle_same_plot_workshop_batch(order)
       for order in permutations(same_plot_workshop_batch)} == {False},
      "Workshops same-plot camp remove/add/unit-add batches must be removal-wins for every callback permutation")

def drain_improvement_events(events: list[tuple[int, int]], current_turn: int) -> list[int]:
    return sorted(plot_index for queued_turn, plot_index in events
                  if queued_turn < current_turn)


observed_workshops = [(1, 5806), (1, 8202), (1, 6385),
                      (1, 5684), (1, 2774), (1, 3453)]
check(drain_improvement_events(observed_workshops, 1) == []
      and drain_improvement_events(observed_workshops, 2)
      == drain_improvement_events(list(reversed(observed_workshops)), 2)
      == sorted(plot_index for _, plot_index in observed_workshops),
      "resource286 workshop callback order must converge only after the next PlotIndex-sorted boundary")
registry_start = workshops.index("local function InitializeWorkshopRegistry()")
registry_end = workshops.index("local function CreateExtra", registry_start)
registry_recovery = workshops[registry_start:registry_end]
check("local WORKSHOP_REGISTRY_VERSION=3;" in workshops
      and "if version~=WORKSHOP_REGISTRY_VERSION then" in registry_recovery
      and "for i=0,Map.GetPlotCount()-1 do" in registry_recovery
      and registry_recovery.count("for i=0,Map.GetPlotCount()-1 do") == 1
      and "Classify(plot);" in registry_recovery
      and "local rejected=LoadWorkshopRegistry();" in registry_recovery
      and "m_networkImprovement" not in registry_recovery,
      "workshop full-map discovery must remain a one-time version migration, not a callback-time registry merge")
direct_rng = [
    p.name for p, text in scripts.items()
    if p.name not in {"LOTM_MP_TurnSync.lua", "LOTM_RP_Gameplay.lua"}
    and "Game.GetRandNum(" in text
]
check(not direct_rng,
      f"Gameplay modules bypass multiplayer-stable random adapter: {direct_rng}")
check("ProcessNetworkWorkshopSettlements(playerID);" in workshops
      and "table.sort(result); return result;" in workshops
      and "pcall(LOTM_PP_GrantWorkshopReward,clearer,level,path,eventKey)" in workshops
      and "if LOTM_MP_TurnSync.IsNetworkGame()" in workshops,
      "network workshop rewards must settle in stable PlotIndex order with a stable event key")
check(all(token in workshops for token in (
    'local MP_PENDING_QUEUED_TURN="LOTM_PP_WORKSHOP_MP_PENDING_QUEUED_TURN"',
    "LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID)",
    "if (entry.QueuedTurn or entry.Turn or currentTurn)>=currentTurn then",
    "elseif PendingSettlementQueuedTurn(plot,currentTurn)>=currentTurn then",
    "ProcessNetworkWorkshopUnitAdditions(playerID);",
    "ProcessNetworkWorkshopSettlements(playerID);",
)), "network workshop callback queues must wait one full turn and settle only at the stable anchor")
check(all(token in workshops for token in (
    "table.remove(entries,index);",
    "SaveNetworkPendingUnitAdditions(entries);",
    "RecoverCommittedNetworkUnitEntry(NetworkPendingUnitAdditions())",
    "Game.SetProperty(MP_UNIT_COMMITTED_TOKEN,NetworkUnitEntryToken(entry));",
    "table.remove(pending,index); SaveNetworkPendingIndices(pending);",
    "if result~=true then",
    "error(result);",
)), "network workshop queues must checkpoint each sorted item and retain the failed suffix")
reward_start = workshops.index("if (plot:GetProperty(MP_REWARD_SETTLED) or 0)~=1 then")
reward_end = workshops.index("plot:SetProperty(MP_PENDING,nil);", reward_start)
reward_slice = workshops[reward_start:reward_end]
check(reward_slice.index("plot:SetProperty(MP_REWARD_SETTLED,1)")
      < reward_slice.index("Game.AddWorldViewText")
      and "local notifyOK,notifyError=pcall(function()" in reward_slice,
      "network artifact ledger must commit before optional localized notification work")

world_events = scripts[ROOT / "Scripts" / "LOTM_WORLD_Events.lua"]
event_notify_start = world_events.index("if LOTM_MP_TurnSync.IsNetworkGame() then",
                                        world_events.index("local function DeliverPendingNotification"))
event_notify_end = world_events.index("\n\tend\n\tlocal ok,err=pcall(Notify", event_notify_start)
event_notify_network = world_events[event_notify_start:event_notify_end]
check(event_notify_network.index('player:SetProperty("LOTM_WORLD_NOTIFICATION_DELIVERED_SERIAL",serial)')
      < event_notify_network.index("pcall(Notify")
      and "return;" in event_notify_network,
      "network world-event notification ledger must commit before optional localized notification work")

churches = scripts[ROOT / "Scripts" / "LOTM_WORLD_Churches.lua"]
church_notify_start = churches.index("if LOTM_MP_TurnSync.IsNetworkGame() then",
                                      churches.index("local function NotifyReward"))
church_notify_end = churches.index("\n+ end\n+ local churchName", church_notify_start) \
    if "\n+ end\n+ local churchName" in churches[church_notify_start:] \
    else churches.index("\n end\n local churchName", church_notify_start)
church_notify_network = churches[church_notify_start:church_notify_end]
check(church_notify_network.index('p:SetProperty(QK(church,tier,"NOTIFICATION_DELIVERED"),1)')
      < church_notify_network.index("pcall(function()")
      and "return;" in church_notify_network,
      "network church reward ledger must commit before optional localized notification work")

ai_cults = scripts[ROOT / "Scripts" / "LOTM_AI_Cults.lua"]
ai_notify_start = ai_cults.index("if LOTM_MP_TurnSync.IsNetworkGame() then",
                                 ai_cults.index("local function NotifyEffect"))
ai_notify_end = ai_cults.index("\n end\n local name=Locale.Lookup", ai_notify_start)
ai_notify_network = ai_cults[ai_notify_start:ai_notify_end]
check("local ok,err=pcall(function()" in ai_notify_network
      and ai_notify_network.index("pcall(function()")
          < ai_notify_network.index("Locale.Lookup")
      and "NotificationManager.SendNotification" in ai_notify_network
      and "return;" in ai_notify_network,
      "network AI-cult notification construction must be best-effort after Gameplay commit")

arson = scripts[ROOT / "Scripts" / "LOTM_RP_Arson.lua"]
rescue_artifacts = scripts[ROOT / "Scripts" / "LOTM_RESCUE_Artifacts.lua"]
check("if LOTM_MP_TurnSync.IsNetworkGame() then" in arson
      and "network arson world text skipped after Gameplay commit" in arson
      and "local ok,details=pcall(function()" in arson,
      "network arson flyover text must be best-effort and unable to abort Gameplay settlement")
check("if LOTM_MP_TurnSync.IsNetworkGame() then" in rescue_artifacts
      and "network own-pillage world text skipped after Gameplay commit" in rescue_artifacts
      and "local ok,details=pcall(function()" in rescue_artifacts,
      "network own-pillage flyover text must be best-effort and unable to abort Gameplay settlement")

black = scripts[ROOT / "Scripts" / "LOTM_BE_BlackEmperor.lua"]
check("trade:CountOutgoingRoutes()" in black and "city:GetTrade():GetOutgoingRoutes()" not in black,
      "Gameplay trade-route counting must use guarded PlayerTrade.CountOutgoingRoutes")
check("reason=COUNT_API_UNAVAILABLE" in black,
      "trade-route counting must fail closed when the Gameplay API is unavailable")

phase7 = scripts[ROOT / "Scripts" / "LOTM_RESCUE_Phase7.lua"]
check('LOTM_MP_TurnSync.AddSynchronized(OnSynchronizedPlayerTurnStarted,"RescuePhase7Runtime")' in phase7,
      "Phase 7 runtime modifiers must attach from a synchronized turn anchor")
check("Events.UnitRemovedFromMap.Add(OnUnitRemoved);\nLOTM_RESCUE_Phase7.ReconcileAll();" not in phase7,
      "Phase 7 must not attach dynamic modifiers during unsynchronized script startup")
phase7_unit_added = lua_slice(phase7, "local function OnUnitAdded", "local function OnUnitRemoved")
phase7_network_unit_added = network_prefix(phase7_unit_added)
check(all(token not in phase7_network_unit_added for token in (
    "UnitManager.", "ApplyUnitTier(", *NETWORK_MUTATION_TOKENS,
)) and "TrackUnit(playerID,unitID)" in phase7_network_unit_added
      and "QueueNetworkUnitAdded(playerID,unitID)" in phase7_network_unit_added,
      "Phase 7 network UnitAdded callback must only queue Lua-local identities")
phase7_network_processor = check_network_processor(
    phase7, "local function ProcessNetworkUnitAdditions", "local function OnUnitAdded",
    ("table.sort(ready,function(a,b)", "a.PlayerID<b.PlayerID", "a.UnitID<b.UnitID"),
    "ApplyUnitTier(unit,cult,tier)", "Phase 7 network abilities",
)
check("not LOTM_MP_TurnSync.IsNetworkGame() and LOTM_RESCUE_Phase7" in scripts[ROOT / "Scripts" / "LOTM_AI_Cults.lua"],
      "network AI-cult event callbacks must not directly reconcile Phase 7 DynamicModifiers")

root = ET.parse(ROOT / "RedPriestPath.modinfo").getroot()
packaged = {n.text.strip() for n in root.findall("./Files/File") if n.text}
action_files = {
    n.text.strip()
    for section in ("FrontEndActions", "InGameActions")
    for n in root.findall(f"./{section}/*/File") if n.text
}
check(action_files <= packaged, f"action files missing from package: {sorted(action_files - packaged)}")
check("Scripts/LOTM_QD_MultiplayerCompat.lua" in packaged,
      "Quick Deals compatibility script is not packaged")
check("Scripts/LOTM_MP_TurnSync.lua" in packaged,
      "multiplayer turn adapter is not packaged")
bundle_path = ROOT / "Scripts" / "LOTM_RP_Gameplay_Bundle.lua"
bundle = bundle_path.read_text(encoding="utf-8")
legacy_network_bundle = LEGACY_NETWORK_BUNDLE.read_text(encoding="utf-8")
check("Scripts/LOTM_RP_Gameplay_Bundle.lua" in packaged,
      "self-contained authoritative Gameplay bundle is not packaged")
check(hashlib.sha256(legacy_network_bundle.encode("utf-8")).hexdigest().upper()
      == LEGACY_NETWORK_SHA256,
      "resource-290 audited network Gameplay snapshot changed")
check('[LOTM][BundleRouter] route=NETWORK_LEGACY_RESOURCE290' in bundle
      and '[LOTM][BundleRouter] route=CURRENT_SINGLE_PLAYER' in bundle
      and legacy_network_bundle in bundle,
      "authoritative bundle must route multiplayer through the verbatim resource-290 snapshot")
check('LOTM_MP_TurnSync.VERSION = 6;' in legacy_network_bundle
      and 'LOTM_MP_TURNSYNC_LAST_RESCUE_STARTUP_TURN' not in legacy_network_bundle
      and 'LOTM_RESCUE_DirectMonsters' not in legacy_network_bundle
      and 'LOTM_RESCUE_Thief' not in legacy_network_bundle,
      "legacy multiplayer route must retain the published resource-290 startup chain")
check('[LOTM_RESCUE][Phase2Audit] BEGIN stage=' in legacy_network_bundle
      and '[LOTM_RESCUE][Phase2Audit] COMMIT stage=' in legacy_network_bundle
      and 'LOTM_RESCUE_PHASE2A_AUDIT_LAST_TURN' in legacy_network_bundle
      and legacy_network_bundle.count('if completedOrDetails == false then') == 2,
      "audited network route must stage Phase 2 native mutations and preserve both TurnSync mirrors")
check('LOTM_RP_GAMEPLAY_BUNDLE_VERSION = 1;' in bundle
      and '[LOTM][Bundle] verified version=' in bundle
      and not re.search(r'\binclude\s*\(\s*["\']LOTM_', bundle),
      "authoritative bundle must embed and attest every project-local Gameplay dependency")
gameplay = scripts[ROOT / "Scripts" / "LOTM_RP_Gameplay.lua"]
check('local function InstallTurnSyncEntrypoint()' in gameplay
      and 'VERSION = 7' in gameplay
      and 'LOTM_RP_MASTER_GAMEPLAY_CONTEXT = true;' in gameplay
      and '[LOTM][MPTurnSync] FATAL entrypoint bootstrap failed' in gameplay
      and 'source=ENTRYPOINT' in gameplay
      and 'include("LOTM_MP_TurnSync")' not in gameplay
      and gameplay.index('InstallTurnSyncEntrypoint();') < gameplay.index('include("LOTM_UnitAddedPerf")')
      and gameplay.index('InstallTurnSyncEntrypoint();') < gameplay.index('include("LOTM_RP_Lifecycle")'),
      "authoritative entrypoint must bootstrap and validate turn synchronization before every dependent module")
check_startup_anchor_contract(gameplay, "entrypoint bootstrap")
rescue_db_marker = 'GameInfo.Resources["RESOURCE_LOTM_RESCUE_ALLY_BANNER"]'
for adapter_text, adapter_label in (
    (turn_sync, "standalone turn adapter"),
    (gameplay, "entrypoint bootstrap"),
):
    check('function LOTM_MP_TurnSync.IsRescueModeConfigured()' in adapter_text
          and rescue_db_marker in adapter_text,
          f"{adapter_label} must prefer the rescue-only Gameplay database marker over the loading-time custom configuration")
check('local rescueConfigured = LOTM_MP_TurnSync.IsRescueModeConfigured();' in gameplay
      and 'local rescueConfigured = GameConfiguration.GetValue("GAMEMODE_LOTM_RESCUE")' not in gameplay
      and 'if rescueConfigured then' in gameplay
      and 'if not rescueConfigured then\n\tinclude("LOTM_TP_Thief");' in gameplay,
      "bundled master Gameplay must use one database-backed mode decision for Rescue and normal-mode Thief isolation")
check('include("LOTM_RESCUE_Phase1")' in gameplay
      and 'include("LOTM_RESCUE_Phase2Test")' in gameplay
      and 'include("LOTM_RESCUE_Phase3")' in gameplay
      and gameplay.index('include("LOTM_RESCUE_Phase1")')
          < gameplay.index('include("LOTM_RESCUE_Phase2Test")')
          < gameplay.index('include("LOTM_RESCUE_Phase3")')
          < gameplay.index('include("LOTM_RP_Lifecycle")')
      and gameplay.index('LOTM_RP_MASTER_GAMEPLAY_CONTEXT = true;')
          < gameplay.index('include("LOTM_RESCUE_Phase1")')
      and 'if LOTM_RESCUE_SyncActions==nil then include("LOTM_RESCUE_SyncActions"); end' in gameplay
      and 'if not entry.Completed and RescueStartupReady(entry.Label) then' in gameplay
      and 'Game.GetProperty("LOTM_RESCUE_PHASE1_STATE") == "READY"' in gameplay,
      "network Rescue must load Phase 1/2/3 in order inside the explicit master Gameplay context")
check('local function LabelIndex(entries,label)' in gameplay
      and 'LabelIndex(LOTM_MP_TurnSync._startupHandlers,"RescuePhase1")' in gameplay
      and 'LabelIndex(LOTM_MP_TurnSync._startupHandlers,"RescuePhase2A")' in gameplay
      and 'LabelIndex(LOTM_MP_TurnSync._turnHandlers,"RescuePhase2")' in gameplay
      and 'LabelIndex(LOTM_MP_TurnSync._turnHandlers,"RescuePhase3")' in gameplay
      and 'phase1Startup>=phase2Startup' in gameplay
      and 'phase2Turn>=phase3Turn' in gameplay
      and 'FATAL ordered network bootstrap registration incomplete' in gameplay
      and 'ordered network bootstrap registration verified' in gameplay,
      "master Gameplay must fail loudly unless Phase1<Phase2A startup and Phase2<Phase3 runtime registration order is complete")
check('if tostring(label) == "RescuePhase2A" then' in gameplay,
      "entrypoint adapter must make ordered Phase 2 eligible after Phase 1")
check('Game.GetProperty("LOTM_RESCUE_PHASE2A_STATE") == "READY"' in gameplay
      and 'ReadNumericGameProperty("LOTM_RESCUE_PHASE2A_READY_GAME_TURN")' in gameplay
      and 'currentTurn > readyTurn' in gameplay
      and 'currentTurn >= readyTurn' not in gameplay
      and 'if not entry.Completed then return; end' in gameplay,
      "every post-Phase2 startup and network turn handler must wait one complete stable boundary")
gameplay_action = root.find("./InGameActions/AddGameplayScripts[@id='LOTM_RP_GAMEPLAY_ADDIN']")
gameplay_order = int(gameplay_action.findtext("./Properties/LoadOrder", "0")) if gameplay_action is not None else 0
gameplay_action_files = {
    n.text.strip() for n in gameplay_action.findall("./File") if n.text
} if gameplay_action is not None else set()
check(gameplay_action_files == {"Scripts/LOTM_RP_Gameplay_Bundle.lua"},
      "the authoritative Gameplay action must load only the self-contained bundle")
rescue_marker_action = root.find(
    "./InGameActions/UpdateDatabase[@id='LOTM_RESCUE_ARTIFACT_DATABASE']"
)
rescue_marker_order = int(
    rescue_marker_action.findtext("./Properties/LoadOrder", "0")
) if rescue_marker_action is not None else 0
rescue_marker_files = {
    n.text.strip() for n in rescue_marker_action.findall("./File") if n.text
} if rescue_marker_action is not None else set()
rescue_artifact_sql = (ROOT / "Gameplay" / "LOTM_RESCUE_Artifacts.sql").read_text(encoding="utf-8")
check(rescue_marker_action is not None
      and rescue_marker_action.get("criteria") == "LOTM_RP_RESCUE_MODE"
      and rescue_marker_order < gameplay_order
      and rescue_marker_files == {"Gameplay/LOTM_RESCUE_Artifacts.sql"}
      and "RESOURCE_LOTM_RESCUE_ALLY_BANNER" in rescue_artifact_sql,
      "the rescue database marker must be Criteria-isolated and applied before master Gameplay loads")

obsolete_runtime_actions = {
    "LOTM_RP_GAMEPLAY_DEPENDENCY_FILES",
    "LOTM_TP_GAMEPLAY_DEPENDENCY_FILES",
    "LOTM_RESCUE_BOOTSTRAP_GAMEPLAY_DEPENDENCY_FILES",
    "LOTM_RP_GAMEPLAY_SHARED_FILES",
    "LOTM_RESCUE_PHASE1_GAMEPLAY_ADDIN",
    "LOTM_RESCUE_PHASE2A_GAMEPLAY_ADDIN",
    "LOTM_RESCUE_PHASE3_GAMEPLAY_ADDIN",
}
runtime_action_ids = {node.get("id") for node in root.findall("./InGameActions/*")}
check(not (obsolete_runtime_actions & runtime_action_ids),
      "resource-288 must remove the cross-action VFS dependencies and duplicate standalone phase contexts")

startup_labels = {
    "Lifecycle", "Progression", "Perfect", "BlackEmperor", "Arson",
    "Advanced", "Thief", "WorldState", "AICults", "Artifacts",
    "Workshops", "RescuePhase5", "RescuePhase6", "RescuePhase8",
    "RescuePhase9", "RescuePhase10A", "RescuePhase10", "RescueArtifacts",
    "AICultHanged", "WorldMonsters", "WorldChurches", "WorldGoodyHuts",
    "RescuePhase1", "RescuePhase2A", "RescuePhase9Digestion",
}
missing_startup = sorted(
    label for label in startup_labels
    if f',"{label}")' not in "\n".join(scripts.values())
)
check(not missing_startup,
      f"stateful startup reconciliation bypasses the network defer gate: {missing_startup}")
phase1 = scripts[ROOT / "Scripts" / "LOTM_RESCUE_Phase1.lua"]
phase2 = scripts[ROOT / "Scripts" / "LOTM_RESCUE_Phase2Test.lua"]
phase3 = scripts[ROOT / "Scripts" / "LOTM_RESCUE_Phase3.lua"]
phase9_digestion = scripts[ROOT / "Scripts" / "LOTM_RESCUE_Phase9Digestion.lua"]
check('LOTM_MP_TurnSync.RunStartup(Initialize,"RescuePhase1");' in phase1
      and 'local authoritativeNetworkContext=networkGame' in phase1
      and 'if not networkGame or authoritativeNetworkContext then' in phase1
      and 'passive standalone network context; master Gameplay owns startup' in phase1
      and not re.search(r"\nInitialize\(\);\s*$", phase1),
      "standalone Phase 1 must stay passive in multiplayer while preserving its single-player startup")
check('network bootstrap deferred reason=PHASE1_NOT_READY' in phase2
      and 'GameConfiguration.IsAnyMultiplayer()==true' in phase2
      and 'LOTM_RESCUE_PHASE2A_READY_GAME_TURN' in phase2
      and 'LOTM_MP_TurnSync.RunStartup(RunAuthoritativeNetworkInitialize,"RescuePhase2A")' in phase2
      and 'passive standalone network context; master Gameplay owns commands and turns' in phase2,
      "network Phase 2 must initialize from the master ordered startup and disable its standalone context")
bootstrap_ui = ui[ROOT / "UI" / "LOTM_RESCUE_CityBootstrap.lua"]
check('local COMMAND="LOTM_RESCUE_Command_BootstrapCity"' in bootstrap_ui
      and "UI.RequestPlayerOperation(playerID,PlayerOperations.EXECUTE_SCRIPT" in bootstrap_ui
      and "{OnStart=COMMAND,Trigger=tostring(trigger)}" in bootstrap_ui
      and "if not m_loadScreenClosed or m_submitted or not NeedsBootstrap() then return; end" in bootstrap_ui
      and "Events.LoadScreenClose.Add(OnLoadScreenClose)" in bootstrap_ui
      and "Events.LocalPlayerTurnBegin.Add" in bootstrap_ui
      and "Events.PlayerTurnActivated.Add" in bootstrap_ui
      and "if m_networkGame then return; end" not in bootstrap_ui
      and all(token not in bootstrap_ui for token in (
          "Game.SetProperty(", ":SetProperty(", "UnitManager.InitUnit(",
          "UnitManager.Kill(", "CityManager.Create", "CityManager.Destroy",
      )),
      "Published rc.241 Rescue bootstrap UI must only submit a synchronized operation after the game view is ready")
check('local function OnBootstrapCity(requestPlayerID,parameters)' in phase2
      and 'type(LOTM_MP_TurnSync.RunPendingStartups)=="function"' in phase2
      and 'type(LOTM_MP_TurnSync.IsRescueModeConfigured)=="function"' in phase2
      and 'LOTM_MP_TurnSync.IsRescueModeConfigured()' in phase2
      and 'LOTM_MP_TurnSync.RunPendingStartups(requestPlayerID,' in phase2
      and '"EXECUTE_SCRIPT:"..tostring' in phase2,
      "master Phase 2 Gameplay must receive the synchronized bootstrap command and drain pending startup")
phase8 = scripts[ROOT / "Scripts" / "LOTM_RESCUE_Phase8.lua"]
opening_coalition_start = phase8.index("function LOTM_RESCUE_Phase8.EstablishOpeningCoalition()")
opening_coalition_end = phase8.index("local function ReconcilePeace()", opening_coalition_start)
opening_coalition = phase8[opening_coalition_start:opening_coalition_end]
check('Game.GetProperty("LOTM_RESCUE_PHASE1_STATE")~="READY"' in opening_coalition
      and 'Game.GetProperty("LOTM_RESCUE_PHASE2A_STATE")~="READY"' in opening_coalition
      and "LOTM_RP_MASTER_GAMEPLAY_CONTEXT~=true" in opening_coalition
      and "LOTM_MP_TurnSync.IsRescueModeConfigured()" in opening_coalition
      and "EstablishPermanentCoalition()" in opening_coalition
      and 'if failed==0 then Game.SetProperty(OPENING_COALITION_READY,1); end' in opening_coalition
      and "AttachPeacePreference" not in opening_coalition
      and "ReconcileAll" not in opening_coalition
      and 'Game.SetProperty("LOTM_RESCUE_PHASE8_STATE"' not in opening_coalition
      and "pcall(LOTM_RESCUE_Phase8.EstablishOpeningCoalition)" in phase2,
      "opening synchronized command may establish only the engine coalition after Phase1/2 READY")
check('local function NetworkSafeFailureValue(singlePlayerDetails,networkCode)' in phase2
      and 'return tostring(singlePlayerDetails);' in phase2
      and 'NetworkSafeFailureValue(details,"RUNTIME_GUARD_ORDERED_STARTUP")' in phase2
      and 'NetworkSafeFailureValue(zone..":"..tostring(corrected),"MAINTENANCE_"..zone)' in phase2,
      "Phase 2 multiplayer failure properties must use stable codes while single-player keeps detailed diagnostics")
phase2_single = phase2.index("if not networkGame then")
phase2_master = phase2.index("elseif authoritativeNetworkContext then", phase2_single)
phase2_passive = phase2.index("\nelse\n", phase2_master)
phase2_command_first = phase2.index("GameEvents.LOTM_RESCUE_Command_BootstrapCity.Add(OnBootstrapCity)")
phase2_command_last = phase2.rindex("GameEvents.LOTM_RESCUE_Command_BootstrapCity.Add(OnBootstrapCity)")
check(phase2_single
      < phase2_command_first
      < phase2_master
      and phase2_single
      < phase2.index("GameEvents.PlayerTurnStarted.Add(OnSynchronizedTurnStart)")
      < phase2_master
      and phase2_master
      < phase2.index('LOTM_MP_TurnSync.RunStartup(RunAuthoritativeNetworkInitialize,"RescuePhase2A")')
      < phase2_command_last
      < phase2_passive,
      "Phase 2 must preserve the single-player bootstrap while only its master network context receives the synchronized command")
check('local authoritativeNetworkContext=networkGame' in phase3
      and 'passive standalone network context; master Gameplay owns commands, turns, and unit events' in phase3,
      "standalone Phase 3 must not register synchronized writers in multiplayer")
check('local function NetworkSafeFailureValue(singlePlayerDetails,networkCode)' in phase3
      and 'return tostring(singlePlayerDetails);' in phase3
      and 'NetworkSafeFailureValue(details,"RUNTIME_GUARD_BOOTSTRAP")' in phase3,
      "Phase 3 multiplayer failure properties must use a stable code while single-player keeps detailed diagnostics")
phase3_single = phase3.index("if not networkGame then")
phase3_master = phase3.index("elseif authoritativeNetworkContext then", phase3_single)
phase3_passive = phase3.index("\nelse\n", phase3_master)
check(phase3_single
      < phase3.index("GameEvents.LOTM_RESCUE_Command_BootstrapCity.Add(OnBootstrapCity)")
      < phase3_master
      and phase3.count('LOTM_MP_TurnSync.Add(ProcessTurn,"RescuePhase3")') == 2
      and phase3_master
      < phase3.rindex('LOTM_MP_TurnSync.Add(ProcessTurn,"RescuePhase3")')
      < phase3_passive
      and "Events.UnitRemovedFromMap.Add" not in phase3[phase3_passive:],
      "Phase 3 command must remain single-player-only and its network turn/unit listeners must belong only to the master context")
check('if rescueConfigured then' in gameplay
      and 'if LOTM_MP_TurnSync.IsNetworkGame() then' in gameplay,
      "the bundled context must own Phase 1/2/3 for both modes while keeping only the order gate network-specific")
check('end,"RescuePhase9Digestion");' in phase9_digestion,
      "Rescue Phase 9 digestion READY state must use deferred network startup")
quick_test = scripts[ROOT / "Scripts" / "LOTM_DEV_QuickTest.lua"]
check('local ENABLED :boolean = false;' in quick_test
      and 'LOTM_MP_TurnSync.RunStartup(ConfigureAll,"DevQuickTest")' in quick_test,
      "production quick-test must remain disabled and cannot mutate network state during load")

qd = scripts[ROOT / "Scripts" / "LOTM_QD_MultiplayerCompat.lua"]
check("Game.GetLocalPlayer(" not in qd,
      "Quick Deals compatibility must never select a synchronized player from local UI state")
check('Reconcile("SCRIPT_LOAD")' in qd
      and 'Reconcile("SYNCHRONIZED_WORLD_TURN")' in qd,
      "Quick Deals local-cache guard must cover load and the synchronized turn anchor")
check('local LEGACY_CACHE_KEYS = { "QD_SELLABLE_DEALS", "QD_BUYABLE_DEALS" };' in qd
      and 'local function ClearLegacyCacheAtSynchronizedTurn(anchor)' in qd
      and 'local stored = player:GetProperty(key);' in qd
      and 'player:SetProperty(key,nil);' in qd
      and 'ClearLegacyCacheAtSynchronizedTurn(playerID);' in qd
      and qd.count('ClearLegacyCacheAtSynchronizedTurn(') == 2,
      "Quick Deals legacy synchronized caches must converge only at the shared turn anchor")
check('Events.LoadGameViewStateDone.Add(function() Reconcile("LOAD_GAME_VIEW_STATE_DONE"); end);' in qd
      and 'Events.LoadScreenClose.Add(function() Reconcile("LOAD_SCREEN_CLOSE"); end);' in qd,
      "Quick Deals load callbacks must remain read/local-only during GameCore deserialization")
check('GameConfiguration.IsAnyMultiplayer() == true' in qd,
      "Quick Deals compatibility must use Civ VI's supported multiplayer predicate")

if errors:
    print(f"FAILED: {len(errors)} multiplayer determinism checks")
    for error in errors:
        print(f" - {error}")
    raise SystemExit(1)
print("PASS: multiplayer authority/determinism gate")
