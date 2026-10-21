#!/usr/bin/env python3
"""Focused authority gate for Perfect Path local Gameplay event facts."""

from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
LUA = (ROOT / "Scripts" / "LOTM_PP_Perfect.lua").read_text(encoding="utf-8")
errors: list[str] = []


def check(value: bool, message: str) -> None:
    if not value:
        errors.append(message)


def source_slice(start_marker: str, end_marker: str) -> str:
    start = LUA.find(start_marker)
    if start < 0:
        return ""
    end = LUA.find(end_marker, start + len(start_marker))
    return LUA[start:] if end < 0 else LUA[start:end]


CALLBACKS = (
    (
        "OnTechBoostTriggered",
        "local function ApplyCivicBoostTriggered",
        "TECH_BOOST",
        "ApplyTechBoostTriggered(playerID);",
    ),
    (
        "OnCivicBoostTriggered",
        "local function ApplyGoodyHutReward",
        "CIVIC_BOOST",
        "ApplyCivicBoostTriggered(playerID);",
    ),
    (
        "OnGoodyHutReward",
        "local function ApplyUnitMoveComplete",
        "GOODY_HUT",
        "ApplyGoodyHutReward(playerID, unitID, rewardType, rewardSubType);",
    ),
    (
        "OnUnitMoveComplete",
        "local function ApplyUnitChargesChanged",
        "UNIT_MOVE",
        "ApplyUnitMoveComplete(playerID, unitID, x, y);",
    ),
    (
        "OnUnitChargesChanged",
        "local function ApplyImprovementAddedToMap",
        "UNIT_CHARGES",
        "ApplyUnitChargesChanged(playerID, unitID, newCharges, oldCharges, nil);",
    ),
    (
        "OnImprovementAddedToMap",
        "local function IsCampusBuilding",
        "IMPROVEMENT",
        "ApplyImprovementAddedToMap(x, y, improvementType, ownerID, nil);",
    ),
    (
        "OnDistrictAddedToMap",
        "local function ApplyResearchCompleted",
        "DISTRICT",
        "ApplyDistrictAddedToMap(",
    ),
    (
        "OnResearchCompleted",
        "local function ApplyCivicCompleted",
        "RESEARCH",
        "ApplyResearchCompleted(playerID, techIndex, isCanceled);",
    ),
    (
        "OnCivicCompleted",
        "local function OnUnitAddedToMap",
        "CIVIC",
        "ApplyCivicCompleted(playerID, civicIndex, isCanceled);",
    ),
    (
        "OnCityProjectCompleted",
        "local function ApplyNetworkGameplayEvent",
        "CITY_PROJECT",
        "ApplyCityProjectCompleted(playerID, cityID, projectIndex, nil);",
    ),
    (
        "OnGreatWorkCreated",
        "local function NextEventSerial",
        "GREAT_WORK",
        "ApplyGreatWorkCreated(playerID, unitID, cityX, cityY, buildingID, greatWorkID);",
    ),
)

MUTATION_TOKENS = (
    "LOTM_RP_State.TryAddDigestion(",
    "LOTM_RP_State.AdvanceSequence(",
    "AttachModifierByID(",
    "ChangeAbilityCount(",
    ":SetProperty(",
    "Game.SetProperty(",
    "NextEventSerial(",
    "ProcessRelics(",
    "LOTM_PP_RefreshSequenceState(",
    ":ChangePointsTotal(",
    ":TriggerBoost(",
    "UnitManager.",
)

for callback, end_marker, kind, immediate_call in CALLBACKS:
    body = source_slice(f"local function {callback}", end_marker)
    network_start = body.find("LOTM_MP_TurnSync.IsNetworkGame()")
    network_return = body.find("return;", network_start)
    prefix = body[network_start:network_return] if network_start >= 0 and network_return >= 0 else ""
    check(bool(body), f"missing bounded callback body for {callback}")
    check(network_start >= 0 and network_return > network_start,
          f"{callback} does not return from its network capture branch")
    check("QueueNetworkGameplayEvent(" in prefix and f'"{kind}"' in prefix,
          f"{callback} does not queue its {kind} fact before returning")
    check(not any(token in prefix for token in MUTATION_TOKENS),
          f"{callback} mutates synchronized Gameplay state in its network callback")
    check(immediate_call in body and body.find(immediate_call) > network_return,
          f"{callback} no longer preserves its immediate single-player application")


queue = source_slice(
    "local function QueueNetworkGameplayEvent",
    "local function NetworkGameplayEventLess",
)
check('local queuedTurn = Game.GetCurrentGameTurn();' in queue
      and 'tostring(queuedTurn)' in queue
      and 'kind' in queue
      and 'tostring(normalizedPlayerID)' in queue,
      "network fact identity must include turn, kind, and player")
check("existing.Count = existing.Count + 1;" in queue and "Count = 1," in queue,
      "identical network facts must aggregate an explicit occurrence Count")

ordering = source_slice(
    "local function NetworkGameplayEventLess",
    "local function ApplyGreatWorkCreated",
)
for token in (
    "left.QueuedTurn < right.QueuedTurn",
    "left.Order < right.Order",
    "left.PlayerID < right.PlayerID",
    "left.SortKey < right.SortKey",
):
    check(token in ordering, f"network fact stable ordering lacks {token}")

order_table = source_slice(
    "local NETWORK_GAMEPLAY_EVENT_ORDER",
    "local LOTM_PP_PROJECT_ADVANCES",
)
orders = {
    name: int(value)
    for name, value in re.findall(r"^\s*([A-Z_]+)\s*=\s*(\d+),", order_table, re.MULTILINE)
}
check(set(orders) == {kind for _, _, kind, _ in CALLBACKS},
      "network fact ordering table does not exactly cover the reviewed callbacks")
check(len(set(orders.values())) == len(orders),
      "network fact ordering priorities must be unique")
check(bool(orders) and orders.get("CITY_PROJECT", -1) == max(orders.values()),
      "CityProjectCompleted must settle after same-turn digestion facts")


def modeled_settlement(
    publications: list[tuple[int, str, int, tuple[int, ...]]],
    current_turn: int,
) -> list[tuple[int, str, int, tuple[int, ...], int]]:
    grouped: dict[tuple[int, str, int, tuple[int, ...]], int] = {}
    for publication in publications:
        grouped[publication] = grouped.get(publication, 0) + 1
    ready = [
        (*identity, count)
        for identity, count in grouped.items()
        if identity[0] < current_turn
    ]
    return sorted(
        ready,
        key=lambda entry: (entry[0], orders[entry[1]], entry[2], entry[3]),
    )


modeled_publications = [
    (7, "CITY_PROJECT", 0, (9, 81)),
    (7, "TECH_BOOST", 0, (12,)),
    (7, "TECH_BOOST", 0, (12,)),
    (7, "CIVIC_BOOST", 0, (4,)),
]
check(modeled_settlement(modeled_publications, 7) == [],
      "same-turn facts must not settle before a full world-turn boundary")
forward = modeled_settlement(modeled_publications, 8)
reverse = modeled_settlement(list(reversed(modeled_publications)), 8)
check(forward == reverse
      and forward[0][1] == "TECH_BOOST"
      and forward[0][-1] == 2
      and forward[-1][1] == "CITY_PROJECT",
      "fact model must preserve duplicate Count, input-order independence, and project-last settlement")

processor = source_slice(
    "local function ProcessNetworkGameplayEvents",
    "local function ProcessPlayer",
)
for token in (
    "LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID)",
    "entry.QueuedTurn < currentTurn",
    "table.sort(ready, NetworkGameplayEventLess);",
    "for occurrence = 1, entry.Count do",
    "ApplyNetworkGameplayEvent(entry);",
    "local ok, details = pcall(function()",
    "entry.AppliedCount = occurrence - 1;",
    "for restoreIndex = index, #ready do",
    "pendingNetworkGameplayEventKeys[restore.SortKey] = restore;",
    'error("Perfect deferred network fact failed: "',
):
    check(token in processor, f"network fact consumer lacks {token}")
check(processor.find("pendingNetworkGameplayEventKeys[restore.SortKey] = restore;")
      < processor.find('error("Perfect deferred network fact failed: "'),
      "failed fact and untouched suffix must be restored before fail-closed rethrow")

dispatch = source_slice(
    "local function ApplyNetworkGameplayEvent",
    "local function ProcessNetworkGameplayEvents",
)
for _, _, kind, _ in CALLBACKS:
    check(f'entry.Kind == "{kind}"' in dispatch,
          f"network fact consumer does not dispatch {kind}")

charges = source_slice(
    "local function OnUnitChargesChanged",
    "local function ApplyImprovementAddedToMap",
)
check("local unitType = unit ~= nil and unit:GetType() or nil;" in charges
      and "UnitType = unitType," in charges
      and "unitID, newCharges, oldCharges, unitType" in charges,
      "UnitChargesChanged must capture the event-time unit type")
check("payload.UnitType" in dispatch,
      "UnitChargesChanged settlement must use the captured unit type")

charges_apply = source_slice(
    "local function ApplyUnitChargesChanged",
    "local function OnUnitChargesChanged",
)
check("capturedUnitType == nil" in charges_apply
      and "player:GetUnits():FindID(unitID)" in charges_apply
      and "capturedUnitType ~= nil and capturedUnitType" in charges_apply,
      "queued builder-charge settlement must not require the consumed unit to survive")
check("payload.ImprovementType, entry.PlayerID," in dispatch
      and "entry.QueuedTurn" in dispatch,
      "improvement settlement must receive its captured event turn")
check("payload.ProjectIndex," in dispatch
      and "entry.QueuedTurn" in dispatch[dispatch.find('entry.Kind == "CITY_PROJECT"'):],
      "project settlement must receive its captured event turn")

improvement_apply = source_slice(
    "local function ApplyImprovementAddedToMap",
    "local function OnImprovementAddedToMap",
)
project_apply = source_slice(
    "local function ApplyCityProjectCompleted",
    "local function OnCityProjectCompleted",
)
check("eventTurn :number" in improvement_apply
      and "eventTurn or Game.GetCurrentGameTurn()" in improvement_apply,
      "improvement digestion identity must use the captured turn in multiplayer")
check("eventTurn :number" in project_apply
      and project_apply.count("eventTurn or Game.GetCurrentGameTurn()") == 2,
      "project digestion identities must use the captured turn in multiplayer")

turn = source_slice(
    "local function OnPlayerTurnActivated",
    "local function Initialize",
)
scientist_position = turn.find("ProcessNetworkScientistUnits(playerID);")
facts_position = turn.find("ProcessNetworkGameplayEvents(playerID);")
player_position = turn.find("ProcessPlayer(playerID, isFirstTimeThisTurn);")
check(0 <= scientist_position < facts_position < player_position,
      "stable Perfect turn must drain scientist and Gameplay facts before player refresh")

check("client-local Events publications routed through the fact queue" in LUA
      and LUA.count("GameEvents.BuildingConstructed.Add(OnBuildingConstructed);") == 1,
      "synchronized BuildingConstructed must remain an explicit, singly registered queue exception")

for event_name, callback in (
    ("TechBoostTriggered", "OnTechBoostTriggered"),
    ("CivicBoostTriggered", "OnCivicBoostTriggered"),
    ("GoodyHutReward", "OnGoodyHutReward"),
    ("UnitMoveComplete", "OnUnitMoveComplete"),
    ("UnitChargesChanged", "OnUnitChargesChanged"),
    ("ImprovementAddedToMap", "OnImprovementAddedToMap"),
    ("DistrictAddedToMap", "OnDistrictAddedToMap"),
    ("ResearchCompleted", "OnResearchCompleted"),
    ("CivicCompleted", "OnCivicCompleted"),
    ("CityProjectCompleted", "OnCityProjectCompleted"),
    ("GreatWorkCreated", "OnGreatWorkCreated"),
):
    check(f"Events.{event_name}.Add({callback});" in LUA,
          f"{event_name} is not registered to reviewed callback {callback}")


if errors:
    print(f"Perfect network event queue validation failed: {len(errors)} issue(s)")
    for issue in errors:
        print(f" - {issue}")
    raise SystemExit(1)

print(
    "Perfect network event queue validation passed: "
    "11 local callbacks are capture-only in multiplayer and immediate in single-player"
)
