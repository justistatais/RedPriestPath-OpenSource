#!/usr/bin/env python3
"""Static contracts plus deterministic synthetic geometry tests for Rescue Phase 1.

These tests do not launch Civilization VI and must not be reported as in-game tests.
"""

from __future__ import annotations

import xml.etree.ElementTree as ET
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DIRECTIONS = ((1, 0), (0, 1), (-1, 1), (-1, 0), (0, -1), (1, -1))
CONFIGS = ((5, (0, 2, 4), "0/2/4"), (5, (1, 3, 5), "1/3/5"),
           (6, (0, 2, 4), "0/2/4"), (6, (1, 3, 5), "1/3/5"))


def distance(a: tuple[int, int], b: tuple[int, int]) -> int:
    dq, dr = a[0] - b[0], a[1] - b[1]
    return max(abs(dq), abs(dr), abs(dq + dr))


def disk(center: tuple[int, int], radius: int, cells: set[tuple[int, int]]) -> set[tuple[int, int]]:
    return {cell for cell in cells if distance(center, cell) <= radius}


@dataclass(frozen=True)
class Scenario:
    name: str
    width: int
    height: int
    kind: str
    starts: tuple[tuple[int, int], ...]
    obstacles: tuple[tuple[int, int], ...] = ()


def land_for(s: Scenario, cell: tuple[int, int]) -> bool:
    q, r = cell
    if cell in s.obstacles:
        return False
    if s.kind == "land":
        return True
    if s.kind == "continents":
        return (q // 17) % 2 == 0 or abs(r - s.height // 2) <= 5
    # Synthetic high-water map: a broad central island and deterministic small islands.
    center = (s.width // 2, s.height // 2)
    return distance(cell, center) <= 11 or ((q * 7 + r * 11) % 19) < 3


def solve(s: Scenario):
    cells = {(q, r) for r in range(s.height) for q in range(s.width)}
    center = ((s.width - 1) // 2, (s.height - 1) // 2)
    candidates = []
    for cell in cells:
        if not land_for(s, cell):
            continue
        if any((cell[0] + dq, cell[1] + dr) not in cells or
               not land_for(s, (cell[0] + dq, cell[1] + dr)) for dq, dr in DIRECTIONS):
            continue
        start_min = min((distance(cell, start) for start in s.starts), default=9999)
        if start_min < 10:
            continue
        land_score = sum(land_for(s, p) for p in disk(cell, 4, cells))
        candidates.append((0 if start_min >= 12 else 1, distance(cell, center), -land_score,
                           cell[1] * s.width + cell[0], cell, start_min))
    candidates.sort()
    for _, _, _, _, candidate, start_min in candidates:
        for radius, directions, group in CONFIGS:
            centers = (candidate,) + tuple(
                (candidate[0] + DIRECTIONS[d][0] * radius,
                 candidate[1] + DIRECTIONS[d][1] * radius) for d in directions
            )
            if any(c not in cells or not land_for(s, c) for c in centers):
                continue
            territories = tuple(disk(c, 2, cells) for c in centers)
            if any(len(t) != 19 for t in territories):
                continue
            union = set().union(*territories)
            if len(union) != 76:
                continue
            return centers, territories, radius, group, start_min
    raise AssertionError(f"{s.name}: no layout")


def static_contracts() -> None:
    config = ET.parse(ROOT / "Config/LOTM_RP_PathSelection.xml").getroot()
    row = config.find("./Parameters/Row[@ConfigurationId='GAMEMODE_LOTM_RESCUE']")
    assert row is not None
    expected = {"Domain": "bool", "DefaultValue": "0", "ConfigurationGroup": "Game",
                "NameArrayConfigurationId": "GAMEMODES_ENABLED_NAMES", "GroupId": "GameModes"}
    for key, value in expected.items():
        assert row.get(key) == value, (key, row.get(key), value)

    root = ET.parse(ROOT / "RedPriestPath.modinfo").getroot()
    criteria = root.find("./ActionCriteria/Criteria[@id='LOTM_RP_RESCUE_MODE']")
    assert criteria is not None
    assert criteria.findtext("RuleSetInUse") == "RULESET_EXPANSION_2"
    assert criteria.findtext("./ConfigurationValueMatches/ConfigurationId") == "GAMEMODE_LOTM_RESCUE"
    assert criteria.findtext("./ConfigurationValueMatches/Value") == "1"
    gameplay = root.find("./InGameActions/AddGameplayScripts[@id='LOTM_RP_GAMEPLAY_ADDIN']")
    assert gameplay is not None
    assert [node.text for node in gameplay.findall("File")] == ["Scripts/LOTM_RP_Gameplay_Bundle.lua"]
    phase1 = root.find("./InGameActions/AddGameplayScripts[@id='LOTM_RESCUE_PHASE1_GAMEPLAY_ADDIN']")
    assert phase1 is not None and phase1.get("criteria") == "LOTM_RP_RESCUE_MODE"
    assert [node.text for node in phase1.findall("File")] == ["Scripts/LOTM_MP241_Phase1.lua"]
    markers = root.find("./InGameActions/AddUserInterfaces[@id='LOTM_RESCUE_PHASE1_MARKERS_UI_ADDIN']")
    assert markers is not None and markers.get("criteria") == "LOTM_RP_RESCUE_MODE"

    lua = (ROOT / "Scripts/LOTM_RESCUE_Phase1.lua").read_text(encoding="utf-8")
    assert "math.random" not in lua and "Game.GetRandNum" not in lua
    assert 'state=="READY"' in lua and 'state=="FAILED" and storedVersion>=VERSION' in lua
    assert 'retrying older failed state' in lua
    assert "plot:GetDistrictType()<0" in lua and "plot:GetImprovementType()<0" in lua
    assert "plot:GetOwner()==-1" in lua
    assert "IsUnoccupiedReservationPlot(plot)" in lua
    assert "requested CITY_STATE_COUNT without deleting or moving a minor" in lua
    assert "not plot:IsImpassable()" in lua
    assert "while cursor<=#queue" in lua and "Map.GetAdjacentPlot(current:GetX(),current:GetY(),direction)" in lua
    assert "local function MajorStarts()" in lua and "player:IsMajor()" in lua
    assert "Including every minor StartingPosition here made dense maps have zero" in lua
    assert "local function ClaimReservations(territories)" in lua
    assert "PlayerManager.GetFreeCitiesPlayerID()" in lua
    assert "plot:SetOwner(playerID)" in lua
    assert 'Game.SetProperty("LOTM_RESCUE_RESERVATION_OWNER",reservationOwner)' in lua
    assert "claimedPlots=76" in lua
    assert "PlayerManager.GetAliveMajors()" in lua and "player:IsHuman()" in lua
    assert "visibility:ChangeVisibilityCount(plotIndex,1)" in lua
    assert 'appliedVersion>=VISIBILITY_VERSION' in lua
    assert "local VERSION = 4" in lua and "local VISIBILITY_VERSION = 2" in lua
    assert 'Game.SetProperty("LOTM_RESCUE_VISIBILITY_VERSION",VISIBILITY_VERSION)' in lua
    assert 'if state=="READY" then' in lua and 'RevealReservationsForHumans();' in lua
    for forbidden in ("CityManager", "UnitManager.InitUnit", "TerrainBuilder.Set", "ImprovementBuilder", "RevealAllPlots"):
        assert forbidden not in lua, forbidden
    for required in ("LOTM_RESCUE_CENTER_TERRITORY", "LOTM_RESCUE_FALLBACK_REASON",
                     "LOTM_RESCUE_ZONE_KIND", "LOTM_RESCUE_PHASE1_STATE"):
        # Dynamic concatenation handles zone keys, so CENTER_TERRITORY is represented by its parts.
        if required == "LOTM_RESCUE_CENTER_TERRITORY":
            assert '"LOTM_RESCUE_"..zone.."_TERRITORY"' in lua
        else:
            assert required in lua

    ui = (ROOT / "UI/LOTM_RESCUE_Phase1Markers.lua").read_text(encoding="utf-8")
    assert "Game.SetProperty" not in ui and ":SetProperty" not in ui
    assert "PlayersVisibility" in ui and "IsRevealed" in ui


def main() -> int:
    static_contracts()
    scenarios = (
        Scenario("01_pangaea_standard", 64, 42, "land", ((3, 3), (60, 38))),
        Scenario("02_pangaea_large", 84, 54, "land", ((4, 4), (79, 49), (4, 49))),
        Scenario("03_continents_standard", 72, 44, "continents", ((2, 3), (68, 40))),
        Scenario("04_continents_large", 88, 56, "continents", ((3, 4), (83, 51))),
        Scenario("05_archipelago_standard", 74, 46, "archipelago", ((2, 2), (70, 42))),
        Scenario("06_archipelago_large", 90, 58, "archipelago", ((3, 3), (86, 54))),
        Scenario("07_small_land", 44, 30, "land", ((2, 2), (41, 27))),
        Scenario("08_small_high_water", 48, 32, "archipelago", ((2, 2), (45, 29))),
        Scenario("09_rotated_fallback", 64, 42, "land", ((2, 2), (61, 39)), ((36, 20),)),
        Scenario("10_radius_fallback", 68, 44, "land", ((2, 2), (65, 41)), ((39, 21), (34, 26))),
    )
    lines = ["# Rescue Phase 1 synthetic coordinate log", "",
             "> Static synthetic tests only; these are not Civilization VI game runs.", "",
             "| Case | Size | Kind | Centers | Radius | Directions | Start min |", "|---|---:|---|---|---:|---|---:|"]
    for scenario in scenarios:
        first = solve(scenario)
        second = solve(scenario)
        assert first == second, f"{scenario.name}: nondeterministic reload result"
        centers, territories, radius, group, start_min = first
        assert len(set(centers)) == 4
        assert [len(t) for t in territories] == [19, 19, 19, 19]
        assert len(set().union(*territories)) == 76
        assert start_min >= 10
        centers_text = " / ".join(f"{q},{r}" for q, r in centers)
        lines.append(f"| {scenario.name} | {scenario.width}x{scenario.height} | {scenario.kind} | {centers_text} | {radius} | {group} | {start_min} |")
    output = ROOT / "Deliverables/RescuePhase1/10局合成坐标日志.md"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Rescue Phase 1: static contracts + {len(scenarios)} deterministic synthetic scenarios passed")
    print(f"Coordinate log: {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
