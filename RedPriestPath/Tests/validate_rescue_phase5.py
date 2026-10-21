#!/usr/bin/env python3
"""Static contract checks for Rescue Mode Phase 5 and Phase 4 unit migration."""

from __future__ import annotations

import sys
import sqlite3
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def check(condition: bool, message: str) -> None:
    if not condition:
        print(f"FAIL: {message}")
        raise SystemExit(1)


def main() -> int:
    phase4_db = ET.parse(ROOT / "Gameplay" / "LOTM_RESCUE_Phase4.xml").getroot()
    phase5_sql = (ROOT / "Gameplay" / "LOTM_RESCUE_Phase5.sql").read_text(encoding="utf-8")
    phase5 = (ROOT / "Scripts" / "LOTM_RESCUE_Phase5.lua").read_text(encoding="utf-8")
    gameplay = (ROOT / "Scripts" / "LOTM_RP_Gameplay.lua").read_text(encoding="utf-8")
    direct = (ROOT / "Scripts" / "LOTM_RESCUE_DirectMonsters.lua").read_text(encoding="utf-8")
    workshops = (ROOT / "Scripts" / "LOTM_PP_Workshops.lua").read_text(encoding="utf-8")
    monsters = (ROOT / "Scripts" / "LOTM_WORLD_Monsters.lua").read_text(encoding="utf-8")
    art = (ROOT / "Art" / "LOTM_RESCUE_Phase4_Units.artdef").read_text(encoding="utf-8")
    icons = (ROOT / "Art" / "LOTM_RESCUE_Phase4_Icons.xml").read_text(encoding="utf-8")
    modinfo = (ROOT / "RedPriestPath.modinfo").read_text(encoding="utf-8")
    ordinary_sql = (ROOT / "Gameplay" / "LOTM_WORLD_Monsters.sql").read_text(encoding="utf-8")
    clan_sql = (ROOT / "Gameplay" / "LOTM_RESCUE_ClanRegistry.sql").read_text(encoding="utf-8")
    clan_icons = ET.parse(ROOT / "Art" / "LOTM_RESCUE_ClanRegistry_Icons.xml").getroot()
    clan_text_zh = ET.parse(ROOT / "Text" / "zh_Hans_CN" / "LOTM_RESCUE_ClanRegistryText.xml").getroot()
    clan_text_en = ET.parse(ROOT / "Text" / "en_US" / "LOTM_RESCUE_ClanRegistryText.xml").getroot()

    expected_units = {
        "UNIT_LOTM_RESCUE_LOST_CONTROL_LOW": "LOC_LOTM_RESCUE_LOST_CONTROL_LOW_NAME",
        "UNIT_LOTM_RESCUE_LOST_CONTROL_MID": "LOC_LOTM_RESCUE_LOST_CONTROL_MID_NAME",
        "UNIT_LOTM_RESCUE_LOST_CONTROL_HIGH": "LOC_LOTM_RESCUE_LOST_CONTROL_HIGH_NAME",
    }
    units = {row.attrib["UnitType"]: row.attrib for row in phase4_db.findall("./Units/Row")}
    check(set(units) == set(expected_units), "Phase 4 must retain exactly three legacy UnitTypes for save migration")
    for unit_type, name in expected_units.items():
        check(units[unit_type].get("Name") == name and units[unit_type].get("Combat") == "20", f"invalid legacy migration unit {unit_type}")
        check(f'm_Name text="{unit_type}"' in art, f"Phase 4 art lacks {unit_type}")
        check(f'ICON_{unit_type}' in icons, f"Phase 4 icons lack {unit_type}")

    for token in (
        'local STANDARD_FINAL_TURN=150',
        'GameInfo.GameSpeeds[speedType]',
        'speed.CostMultiplier',
        'math.floor(STANDARD_FINAL_TURN*multiplier/100+0.5)',
        'local VERSION=26',
        'local EARLY_MONSTER_RATE_END_TURN=20',
        'local EARLY_MONSTER_RATE_PERCENT=50',
        'local LATE_MONSTER_RATE_PERCENT=75',
        'function LOTM_RESCUE_Phase5.MonsterSpawnPercent(worldTurn)',
        'function LOTM_RESCUE_Phase5.ScaleMonsterSpawnCount(base,channel,worldTurn)',

        'scaled=scaled-2', 'scaled=scaled-3', 'math.max(1,scaled)',
        'local NO_TEAM=-1',
        'local WORKSHOP_CHANCE={80,85,90,95,100}',
        'local WORKSHOP_LEVEL_CHANCE=',
        '{85,15,0}', '{60,30,10}', '{35,40,25}', '{15,40,45}', '{5,20,75}',
        'local MONSTER_CHANCE={80,90,100,100,100}',
        'local MONSTER_PER_WORKSHOP={6,8,10,12,16}',
        'local MONSTER_COOLDOWN={3,2,1,1,1}',
        'local MONSTER_BURST={2,2,3,3,4}',
        'local MONSTER_TURN_ATTEMPTS={6,8,10,12,15}',
        'local MAP_SCALE_PERCENT=',
        'function LOTM_RESCUE_Phase5.MapScalePercent()',
        'function LOTM_RESCUE_Phase5.ScaleRefreshCount(base)',
        'function LOTM_RESCUE_Phase5.DirectSpawnCount()',
        'local PERIOD_STRENGTH={0,10,20,30,40}',
        'local GLOBAL_CAP_MULTIPLIER={2,2,3,3,4}',
        'local MONSTER_GLOBAL_CAP={40,50,60,70,80}',
        'local BONUS_CAMP_LIMIT={20,23,26,29,32}',
        'local CAMP_TARGET_PER_MAJOR=6',
        'local CAMP_TURN_FLOW=10',
        'math.floor(period*activeTurns/5)',
        'LOTM_RESCUE_PHASE5_STATE","READY"',
    ):
        check(token in phase5, f"Phase 5 period module lacks {token}")

    def period(turn: int, final_turn: int = 150) -> int:
        if turn >= final_turn:
            return 5
        active = final_turn - 1
        for value in range(1, 5):
            if turn <= (value * active) // 5:
                return value
        return 5

    check([period(t) for t in (1, 29, 30, 59, 60, 89, 90, 119, 120, 149, 150)] == [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 5], "150-turn test-schedule period boundaries are wrong")
    check([int(150 * value / 100 + 0.5) for value in (50, 67, 100, 150, 300)] == [75, 101, 150, 225, 450], "game-speed proportional final-turn schedule is wrong")

    # Dynamic aggressive camp pressure and deterministic synchronized creation.
    for token in (
        'function LOTM_RESCUE_Phase5.BonusCampLimit()',
        'function LOTM_RESCUE_Phase5.MonsterGlobalCap()',
        'function LOTM_RESCUE_Phase5.MonsterBurst()',
        'function LOTM_RESCUE_Phase5.MonsterTurnAttempts()',
        'LOTM_RESCUE_Difficulty.Scale(base,LOTM_RESCUE_Difficulty.SpawnPercent())',
        'LOTM_RESCUE_Difficulty.Scale(base,LOTM_RESCUE_Difficulty.CapPercent())',
        'function LOTM_RESCUE_Phase5.TargetCampCount()',
        'function LOTM_RESCUE_Phase5.AnchorMajorID()',
        'function LOTM_RESCUE_Phase5.WorkshopLevelChances(period)',
        'LOTM_RESCUE_PHASE5_LAST_BONUS_CAMP_TURN',
        'LOTM_MP_TurnSync.AddSynchronized(OnPlayerTurnStarted,"RescuePhase5Runtime")',
        'playerID~=LOTM_RESCUE_Phase5.AnchorMajorID()',
        'RecordAttempt(worldTurn,0,0,"NONE"',
        'LOTM_MP_TurnSync.Random(#candidates,stableLabel,"LOTM Rescue Phase5 bonus camp")',
        'table.sort(result,function(a,b) return a:GetIndex()<b:GetIndex(); end)',
        'local function ReservedIndices()', 'local function MajorVisibilities()',
        'local function RemoveNearCandidates(candidates,plotIndex)',
        'LOTM_RESCUE_PHASE5_BONUS_CAMP_CANDIDATES_REMAINING',
        'candidatesInitial=', 'candidatesRemaining=', 'scans=1',
        'manager:CreateTribeOfType(tribeRow.Index,plot:GetIndex())',
        'manager:CreateTribeUnits(tribeIndex,defenderTag,1,plot:GetIndex(),1)',
        'TRIBE_CLAN_MELEE_OPEN', 'TRIBE_CLAN_MELEE_FOREST', 'TRIBE_CLAN_MELEE_HILLS',
        'TRIBE_CLAN_CAVALRY_OPEN', 'TRIBE_CLAN_CAVALRY_JUNGLE', 'TRIBE_CLAN_NAVAL',
        'TRIBE_MELEE', 'TRIBE_CAVALRY', 'TRIBE_NAVAL',
        'plot:GetOwner()~=-1', 'plot:GetDistrictType()~=-1', 'plot:GetUnitCount()>0',
        'ImprovementBuilder.CanHaveImprovement(plot,CAMP,NO_TEAM)',
        'VisibleToAnyMajor(plot:GetIndex(),visibilities)', 'MIN_CITY_DISTANCE=4', 'MIN_CAMP_DISTANCE=7',
        'LOTM_RESCUE_ZONE_KIND', 'LOTM_RESCUE_PHASE5_BONUS_CAMP_FAILURE',
        'LOTM_RESCUE_PHASE5_BONUS_CAMP_PLOTS', 'LOTM_RESCUE_PHASE5_BONUS_CAMP_CANDIDATES',
        'LOTM_RESCUE_PHASE5_MONSTER_GLOBAL_CAP', 'monsterGlobalCap=',
        'API_MISSING', 'NO_LEGAL_PLOT', 'CREATE_TRIBE_FAILED',
    ):
        check(token in phase5, f"Phase 5 aggressive camp contract lacks {token}")

    check("ImprovementBuilder.SetImprovementType" not in phase5, "Phase 5 must never place a fake camp improvement")
    check("UnitManager.InitUnit" not in phase5, "Phase 5 must let the tribe API choose era-legal ordinary defenders")
    check("Events.PlayerTurnActivated.Add" not in phase5, "Phase 5 must not wait for the non-firing barbarian PlayerTurnActivated event")
    check("ImprovementBuilder.CanHaveImprovement(plot,CAMP,NO_TEAM)" in phase5, "candidate legality must pass the explicit integer NO_TEAM value")
    for token in ('LOTM_RESCUE_VERBOSE_LOGS', 'local function Trace(s)', 'Trace("sequence strength unit="', 'Trace("normal spawn plot="'):
        check(token in workshops, f"workshop high-frequency logging guard lacks {token}")
    for token in ('LOTM_RESCUE_VERBOSE_LOGS', 'local function Trace(message)', 'Trace("roll tier="', 'Trace("burst camp="'):
        check(token in monsters, f"monster high-frequency logging guard lacks {token}")

    # Rescue + Barbarian Clans mode receives 200 additional unique tribe slots.
    clan_types = (
        "TRIBE_CLAN_MELEE_OPEN", "TRIBE_CLAN_MELEE_FOREST", "TRIBE_CLAN_MELEE_HILLS",
        "TRIBE_CLAN_CAVALRY_OPEN", "TRIBE_CLAN_CAVALRY_JUNGLE", "TRIBE_CLAN_CAVALRY_CHARIOT",
        "TRIBE_CLAN_NAVAL",
    )
    db = sqlite3.connect(":memory:")
    db.executescript("""
        CREATE TABLE Types(Type TEXT PRIMARY KEY, Kind TEXT NOT NULL);
        CREATE TABLE BarbarianTribes(TribeType TEXT PRIMARY KEY);
        CREATE TABLE BarbarianTribeNames(TribeNameType TEXT PRIMARY KEY, TribeType TEXT NOT NULL, TribeDisplayName TEXT NOT NULL);
    """)
    db.executemany("INSERT INTO BarbarianTribes(TribeType) VALUES (?)", ((value,) for value in clan_types))
    db.executescript(clan_sql)
    names = db.execute("SELECT TribeNameType, TribeType, TribeDisplayName FROM BarbarianTribeNames ORDER BY TribeNameType").fetchall()
    check(len(names) == 200, f"expected 200 extra clan names, got {len(names)}")
    check(len({row[0] for row in names}) == 200 and len({row[2] for row in names}) == 200, "custom clan IDs/localization tags must be unique")
    counts = dict(db.execute("SELECT TribeType, COUNT(*) FROM BarbarianTribeNames GROUP BY TribeType"))
    check(sorted(counts.values()) == [28, 28, 28, 29, 29, 29, 29], f"200 clan slots must be evenly spread across seven types: {counts}")
    check(db.execute("SELECT COUNT(*) FROM Types WHERE Kind='KIND_BARBARIAN_TRIBE'").fetchone()[0] == 200, "all custom clan names need KIND_BARBARIAN_TRIBE Types")
    db.close()

    no_clans = sqlite3.connect(":memory:")
    no_clans.executescript("""
        CREATE TABLE Types(Type TEXT PRIMARY KEY, Kind TEXT NOT NULL);
        CREATE TABLE BarbarianTribes(TribeType TEXT PRIMARY KEY);
        CREATE TABLE BarbarianTribeNames(TribeNameType TEXT PRIMARY KEY, TribeType TEXT NOT NULL, TribeDisplayName TEXT NOT NULL);
    """)
    no_clans.executescript(clan_sql)
    check(no_clans.execute("SELECT COUNT(*) FROM Types").fetchone()[0] == 0, "registry must add nothing when Barbarian Clans types are absent")
    check(no_clans.execute("SELECT COUNT(*) FROM BarbarianTribeNames").fetchone()[0] == 0, "ordinary mode must not receive custom clan names")
    no_clans.close()

    expected_ids = {f"BARBARIAN_CLAN_LOTM_WORKSHOP_{value:03d}" for value in range(1, 201)}
    icon_rows = clan_icons.findall("./IconDefinitions/Row")
    check({row.attrib.get("Name", "").removeprefix("ICON_") for row in icon_rows} == expected_ids, "custom clan icon IDs must cover all 200 tribe names")
    icon_indices = {int(row.attrib["Index"]) for row in icon_rows}
    check(icon_indices == set(range(35)), "custom clans must deterministically reuse all 35 Firaxis clan symbols")
    check(all(row.attrib.get("Atlas") == "ICON_ATLAS_BARBARIAN_CLANS_CIVILIZATIONS" for row in icon_rows), "custom clan icons must reuse the Firaxis clan atlas")

    localized = clan_text_zh.findall("./LocalizedText/Row") + clan_text_en.findall("./LocalizedText/Row")
    check(len(localized) == 400, f"expected 200 bilingual clan names, got {len(localized)} rows")
    for value in range(1, 201):
        tag = f"LOC_LOTM_RESCUE_CLAN_WORKSHOP_{value:03d}"
        rows = [row for row in localized if row.attrib.get("Tag") == tag]
        by_language = {row.attrib.get("Language"): row.findtext("Text") for row in rows}
        check(by_language == {"zh_Hans_CN": f"失控工坊{value}", "en_US": f"Rampager Workshop {value}"}, f"invalid bilingual clan name {tag}")

    def extra_count(current: int, majors: int) -> int:
        return min(10, max(0, majors * 6 - current))

    check(extra_count(0, 20) == 10, "high-flow camp stream must be capped at ten per world turn")
    check(extra_count(35, 6) == 1 and extra_count(36, 6) == 0, "six-per-major camp target is wrong")

    check("SET Value=100" in phase5_sql and "BARBARIAN_CAMP_ODDS_OF_NEW_CAMP_SPAWNING" in phase5_sql, "Rescue camp odds must be 100")
    check("SET Value=10" in phase5_sql and "BARBARIAN_CAMP_MAX_PER_MAJOR_CIV" in phase5_sql, "Rescue camp maximum must be 10 per major civilization")
    check("SET Value = 9" in ordinary_sql, "ordinary mode camp odds must remain 9")
    check("BARBARIAN_CAMP_MAX_PER_MAJOR_CIV" not in ordinary_sql, "ordinary mode camp maximum must remain Firaxis default")
    for amount in (10, 20, 30, 40):
        check(f"ABILITY_LOTM_RESCUE_PERIOD_STRENGTH_{amount}" in phase5_sql, f"missing frozen +{amount} ability")

    for token in (
        'UNIT_LOTM_RESCUE_LOST_CONTROL_LOW', 'UNIT_LOTM_RESCUE_LOST_CONTROL_MID', 'UNIT_LOTM_RESCUE_LOST_CONTROL_HIGH',
        'sequence migrated plot=', 'SequenceUnitIndex(level,u)', 'LOTM_RESCUE_PHASE5_BIRTH_BONUS',
        'ABILITY_LOTM_WORLD_MONSTER_FRENZY_STRENGTH_V2', 'LOTM_RESCUE_CENTER_MONSTER_UNIT_TYPE',
        'local RESCUE_BONUS={[2]=15,[1]=25,[0]=35}',
        'LOTM_RESCUE_Phase5.WorkshopChance()', 'or 50', 'periodBonus=CurrentPeriodBonus()',
        'LOTM_RESCUE_Phase5.WorkshopLevelChances()',
        'if r<low then return 2 elseif r<low+mid then return 1 else return 0; end',
        'local era=Game.GetEras():GetCurrentEra();',
        'LOTM_RESCUE_PHASE5_LEVEL_CHANCES',
        'local CLASSIFICATION_VERSION=1;',
        'GameConfiguration.GetValue("GAME_SYNC_RANDOM_SEED")',
        'MapConfiguration.GetValue("RANDOM_SEED")',
        'StableClassificationRoll(plotIndex,"CLASSIFICATION",100)',
        'StableClassificationRoll(plotIndex,"LEVEL",100)',
        'StableClassificationRoll(plotIndex,"PATH:"..tostring(level),#available)',
        'LOTM_PP_WORKSHOP_DETERMINISTIC_VERSION',
        'deterministicVersion=',
    ):
        check(token in workshops, f"workshop Phase 4/5 integration lacks {token}")
    check("Game.GetRandNum" not in workshops, "workshop callbacks must never advance synchronized RNG")

    # Mirror the compact Lua mixer and prove that callback order cannot change
    # the per-plot classification/level/path results or consume shared state.
    stable_modulus = 2_147_483_647

    def normalize_stable(value: int) -> int:
        return int(value) % stable_modulus

    def mix_stable(value: int, component: int) -> int:
        return (normalize_stable(value) * 48_271 + normalize_stable(component) + 1) % stable_modulus

    def stable_text(value: str) -> int:
        result = 0
        for byte in value.encode("ascii"):
            result = (result * 131 + byte) % stable_modulus
        return result

    classification_seed = mix_stable(mix_stable(104_729, -1_234_567_890), 987_654_321)

    def stable_roll(plot_index: int, channel: str, limit: int) -> int:
        value = mix_stable(classification_seed, plot_index)
        value = mix_stable(value, stable_text(channel))
        return value % limit if limit > 1 else 0

    plots = list(range(0, 4096, 7))

    def classify(order: list[int]) -> dict[int, tuple[int, int, int]]:
        return {
            plot: (
                stable_roll(plot, "CLASSIFICATION", 100),
                stable_roll(plot, "LEVEL", 100),
                stable_roll(plot, "PATH:2", 3),
            )
            for plot in order
        }

    forward = classify(plots)
    reverse = classify(list(reversed(plots)))
    interleaved = classify(plots[::2] + plots[1::2])
    check(forward == reverse == interleaved, "stable workshop results changed with callback order")
    check(all(0 <= values[0] < 100 and 0 <= values[1] < 100 and 0 <= values[2] < 3 for values in forward.values()), "stable workshop roll escaped its bound")
    check("local loggedLevel=plot:GetProperty(LEVEL)" in workshops and 'tostring(loggedLevel or "NONE")' in workshops, "workshop classification logging must normalize missing C-binding Property values")
    check("tostring(plot:GetProperty(LEVEL))" not in workshops, "workshop classification still passes a zero-value Property return directly to tostring")

    for token in (
        'LOTM_RESCUE_Phase5.MonsterChance()', 'LOTM_RESCUE_Phase5.MonsterCooldown()',
        'LOTM_RESCUE_Phase5.MonsterPerWorkshopCap()', 'LOTM_RESCUE_Phase5.GlobalCapMultiplier()',
        'LOTM_RESCUE_Phase5.MonsterGlobalCap()',
        'LOTM_RESCUE_Phase5.MonsterBurst()', 'local function TrySpawnOne(camp,sourceUnit,periodic,networkSourceOwner,batch)',
        'for attempt=1,burst do', 'requested="..burst.." spawned="..spawned',
        'local maximumRadius=RescueActive() and 3 or 2;',
        'function LOTM_WORLD_Monsters.RescueTurnSpawn(worldTurn,requested)',
        'LOTM_WORLD_MONSTER_PERIODIC_LAST_TURN', 'periodic worldTurn=',
        'LiveFromWorkshop', 'sourceLive>=sourceCap', 'BirthPeriodBonus()',
        'PERIOD_BONUS_PROPERTY', 'baseline.Combat+TIER_BONUS[tier]+periodBonus',
        'return LOTM_RESCUE_Phase5.MonsterGlobalCap(),mapSizeType;',
        'player:IsMajor() and (not player:IsHuman() or PlayerHuntUnlocked())', 'AICityTargets(monster)',
        'targetKind="AI_CITY"', 'ScriptedCityAttack(monster,target.City)', 'CITY_BLOCKED_UNIT_',
        'CombatManager.SimulateAttackVersus', 'CombatResultParameters.DEFENSE_DAMAGE_TO',
        'LOTM_MP_TurnSync.Add(OnTurn,"WorldMonsters")',
    ):
        check(token in monsters, f"monster Phase 5 integration lacks {token}")

    for token in (
        'LOTM_RESCUE_DirectMonsters = LOTM_RESCUE_DirectMonsters or {};',
        'function LOTM_RESCUE_DirectMonsters.Spawn(worldTurn,requested)',
        'UnitManager.InitUnit', 'LOTM_WORLD_MONSTER_SOURCE_WORKSHOP',
        'LOTM_WORLD_MONSTER_ACTIVE_SERIALS', 'RegisterActiveSerial',
        'LOTM_RESCUE_MODE', 'directOutsideCity=true',
        'LOTM_WORLD_Barbarians.ResolveMeleeBaseline',
        'MIN_CITY_DISTANCE = 3', 'VisibleToAnyMajor',
        'GLOBAL_CAP', 'direct monster plot turn=', 'direct monster tier turn=',
    ):
        check(token in direct, f"rescue direct monster module lacks {token}")
    check('LOTM Rescue Attack Enemy City' not in phase5_sql and 'StartScriptedOperationWithTargetAndRally' not in monsters, "failed MilitaryAI operation route must be removed")
    check('UnitManager.RequestOperation' not in monsters, "resource-221 flow must not restore unavailable UI attack APIs")

    check('LOTM_WORLD_Monsters.RescueTurnSpawn(worldTurn,workshopRequested)' in phase5, "Phase 5 anchor must apply the unified workshop spawn-rate scale")
    check('LOTM_RESCUE_DirectMonsters.Spawn(worldTurn,directRequested)' in phase5, "Phase 5 anchor must apply the unified direct spawn-rate scale")
    check('ScaleMonsterSpawnCount(workshopRaw,"PERIODIC_WORKSHOP",worldTurn)' in phase5, "periodic workshop stream is not rate-scaled")
    check('ScaleMonsterSpawnCount(directRaw,"DIRECT",worldTurn)' in phase5, "direct stream is not rate-scaled")
    check('ScaleMonsterSpawnCount(rawBurst,"WORKSHOP_EVENT",LOTM_RESCUE_Phase5.WorldTurn())' in monsters, "event-driven workshop stream is not rate-scaled")
    check('LOTM_RESCUE_PHASE5_CAMP_TURN_FLOW' in phase5 and 'requested=math.min(CAMP_TURN_FLOW' in phase5, "monster-rate change must not alter camp flow")
    check('perf worldTurn=' in phase5 and 'workshopMs=' in phase5 and 'directMs=' in phase5, "Phase 5 must log substage timings without changing spawn results")
    check('batch={Live=live,Cap=MapCap(),Baseline=' in monsters and 'SaveActiveMonsterSerials(batch.ActiveSerials)' in monsters, "workshop monster batches must reuse one live scan/baseline and commit the active index once")
    check('batch={Baseline=LOTM_WORLD_Barbarians.ResolveMeleeBaseline' in direct and 'SaveActiveSerials(batch.ActiveSerials)' in direct, "direct monster batches must reuse one baseline and commit the active index once")
    check('include("LOTM_RESCUE_DirectMonsters")' in gameplay and 'if rescueConfigured then' in gameplay, "direct rescue module must load only inside rescue branch")
    check('LOTM_RESCUE_PHASE5_MONSTER_TURN_ATTEMPTS' in phase5, "Phase 5 must publish the period-scaled attempt diagnostic Property")

    # The synchronized carry must produce exact long-run rates for odd bursts.
    def scaled_stream(values: list[int], percent: int) -> list[int]:
        carry = 0
        result: list[int] = []
        for raw in values:
            numerator = raw * percent + carry
            result.append(numerator // 100)
            carry = numerator % 100
        return result

    early_direct = scaled_stream([9] * 14 + [12] * 6, 50)
    check(sum(early_direct) == 99, f"early direct stream is not exactly 50% over turns 1-20: {early_direct}")
    late_direct = scaled_stream([12] * 4, 75)
    check(late_direct == [9, 9, 9, 9], f"late direct stream is not 75%: {late_direct}")
    check('previousPercent==percent' in phase5, "rate remainder must reset at the turn-20 percentage boundary")

    for token in (
        'local REDEPLOYED_TURN_PROPERTY="LOTM_WORLD_MONSTER_REDEPLOYED_TURN"',
        'local REDEPLOY_DISTANCE=12', 'local REDEPLOY_TARGET_MIN_DISTANCE=5',
        'local REDEPLOY_TARGET_MAX_DISTANCE=12',
        'RescueActive() or plot:GetContinentType()==source:GetContinentType()',
        'LOTM_RESCUE_SyncActions.RedeployNearTarget(monster,destination,REDEPLOY_TARGET_MIN_DISTANCE,REDEPLOY_TARGET_MAX_DISTANCE,false,AITerritoryOwners())',
        'monster:SetProperty(REDEPLOYED_TURN_PROPERTY,currentTurn)',
        'reason=REDEPLOY_COOLDOWN attack=false', 'attackEligibleTurn=',
        'reason=BLOCKED_', 'distanceBeforeRetry',
    ):
        check(token in monsters, f"monster remote redeploy/cooldown contract lacks {token}")
    sync_actions = (ROOT / "Scripts" / "LOTM_RESCUE_SyncActions.lua").read_text(encoding="utf-8")
    for token in (
        'local VERSION=9;', 'function LOTM_RESCUE_SyncActions.RedeployNearTarget(unit,target,minRadius,maxRadius,requireUnowned,allowedOwner)',
        'if distance>=minimum and distance<=radius',
        'if a.Distance~=b.Distance then return a.Distance<b.Distance; end',
        'cityTerritoryAllowed=true',
        '"TARGET_REDEPLOY_RING_"..entry.Distance',
    ):
        check(token in sync_actions, f"sync redeploy helper lacks {token}")

    for token in (
        'id="LOTM_RESCUE_PHASE4_DATABASE" criteria="LOTM_RP_RESCUE_MODE"',
        'id="LOTM_RESCUE_PHASE5_DATABASE" criteria="LOTM_RP_RESCUE_MODE"',
        'id="LOTM_RESCUE_CLAN_REGISTRY_DATABASE" criteria="LOTM_RP_RESCUE_CLANS_MODE"',
        'id="LOTM_RESCUE_CLAN_REGISTRY_ICONS" criteria="LOTM_RP_RESCUE_CLANS_MODE"',
        '<ConfigurationId>GAMEMODE_BARBARIAN_CLANS</ConfigurationId>',
        'Gameplay/LOTM_RESCUE_ClanRegistry.sql',
        'Art/LOTM_RESCUE_ClanRegistry_Icons.xml',
        'Text/zh_Hans_CN/LOTM_RESCUE_ClanRegistryText.xml',
        'Text/en_US/LOTM_RESCUE_ClanRegistryText.xml',
        'id="LOTM_RESCUE_PHASE4_ART" criteria="LOTM_RP_RESCUE_MODE"',
        'id="LOTM_RESCUE_PHASE4_ICONS" criteria="LOTM_RP_RESCUE_MODE"',
        'Scripts/LOTM_RESCUE_Phase5.lua',
    ):
        check(token in modinfo, f"modinfo isolation lacks {token}")

    for forbidden in ("GLOBAL_PURIFICATION", "OnWorkshopPurified", "PURIFICATION_VALUE"):
        check(forbidden not in phase5 + workshops + monsters + phase5_sql, f"Phase 6 leaked into Phase 5: {forbidden}")

    print("PASS: Rescue Phase 5 static contract (center monsters, five periods, spawn pressure, frozen bonuses, isolation)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
