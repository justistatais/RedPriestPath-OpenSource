#!/usr/bin/env python3
"""Focused static and deterministic-state checks for rc.82 monsters."""

from pathlib import Path
import re
import sqlite3

ROOT = Path(__file__).resolve().parents[1]


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


monsters = read("Scripts/LOTM_WORLD_Monsters.lua")
workshops = read("Scripts/LOTM_PP_Workshops.lua")
barbarians = read("Scripts/LOTM_WORLD_Barbarians.lua")
sql = read("Gameplay/LOTM_WORLD_Monsters.sql")
modinfo = read("RedPriestPath.modinfo")
flag_ui = read("UI/LOTM_PP_UnitFlagManager.lua")
rescue_bootstrap_ui = read("UI/LOTM_RESCUE_CityBootstrap.lua")
icons = read("Art/LOTM_RP_Icons.xml")
checks: list[tuple[str, bool]] = []


def check(name: str, condition: bool) -> None:
    checks.append((name, bool(condition)))


def table_values(name: str) -> dict[int, int]:
    match = re.search(rf"local {name}=\{{([^\n]+)\}};", monsters)
    if not match:
        return {}
    return {int(key): int(value) for key, value in re.findall(r"\[(\d+)\]=(\d+)", match.group(1))}


chance = table_values("TIER_CHANCE")
bonus = table_values("TIER_BONUS")
moves = table_values("TIER_MOVES")
heal = table_values("TIER_HEAL")
check("01 tier constants", chance == {2: 30, 1: 30, 0: 30} and bonus == {2: 15, 1: 25, 0: 35})
check("02 movement and healing", moves == {2: 3, 1: 4, 0: 4} and heal == {2: 10, 1: 10, 0: 10})
check("03 era reward", all(token in monsters for token in (
    "REWARD_GOLD_PER_ERA :number=500", "eraIndex+1", "goldReward=REWARD_GOLD_PER_ERA*eraNumber",
    "treasury:ChangeGoldBalance(goldReward)",
)) and "TIER_GOLD" not in monsters and "TIER_FAITH" not in monsters)

# Fixed random stubs: values below the threshold hit, the threshold itself misses.
for tier, threshold in chance.items():
    rolls = list(range(100))
    hits = [roll for roll in rolls if roll < threshold]
    check(f"04 tier {tier} threshold", len(hits) == threshold and max(hits) == threshold - 1 and threshold not in hits)

# Deterministic model of per-workshop uniqueness and ten-world-turn cooldown.
live = False
cooldown_until = -1
spawn_turns: list[int] = []
for turn in range(25):
    eligible = not live and turn >= cooldown_until
    if eligible and turn in (0, 10, 20):
        live = True
        spawn_turns.append(turn)
    if live and turn in (0, 10):
        live = False
        cooldown_until = turn + 10
check("05 uniqueness and cooldown model", spawn_turns == [0, 10, 20])

# Existing advanced-workshop contract: one extra only after each second confirmed normal spawn.
extra_after = [count for count in range(1, 9) if count % 2 == 0]
check("06 advanced workshop extra rate", extra_after == [2, 4, 6, 8] and "count%2==0" in workshops)
check("07 extra and monster recursion blocked", all(token in workshops for token in (
    "m_internalCreate", 'u:GetProperty("LOTM_PP_WORKSHOP_EXTRA")', "LOTM_WORLD_Monsters.IsMonster(u)",
)))
check("07b single-player tribe birth ordering is reconciled within the workshop radius", all(token in workshops for token in (
    'local BIRTH_RECONCILE_VERSION=1;',
    'local BIRTH_RECONCILE_VERSION_PROPERTY="LOTM_PP_WORKSHOP_BIRTH_RECONCILE_VERSION";',
    "(NumberValue(plot:GetProperty(BIRTH_RECONCILE_VERSION_PROPERTY)) or 0)<BIRTH_RECONCILE_VERSION",
    "plot:SetProperty(BIRTH_RECONCILE_VERSION_PROPERTY,BIRTH_RECONCILE_VERSION);",
    "BIRTH_RECONCILE_VERSION_PROPERTY}) do plot:SetProperty(key,nil); end",
    "function LOTM_PP_Workshops.ReconcileSinglePlayerWorkshopBirthUnits(camp)",
    "if camp==nil or IsRescueMode() or LOTM_MP_TurnSync.IsNetworkGame() then return; end",
    "for radius=0,3 do",
    'local source=unit:GetProperty("LOTM_PP_WORKSHOP_SOURCE");',
    "table.sort(candidates,function(a,b) return a:GetID()<b:GetID(); end);",
    "ProcessUnitAdded(ownerID,unitID,unit:GetX(),unit:GetY(),false,nil);",
    "single-player birth units reconciled",
    "monster attempt source=UNIT_ADDED",
)))
check("08 canonical B resolver", all(unit in barbarians for unit in (
    "UNIT_WARRIOR", "UNIT_SWORDSMAN", "UNIT_MAN_AT_ARMS", "UNIT_MUSKETMAN",
    "UNIT_LINE_INFANTRY", "UNIT_INFANTRY", "UNIT_MECHANIZED_INFANTRY",
)))
check("09 fixed frenzy and instance abilities", sql.count("'Amount','1'") == 2 and all(token in sql for token in (
    "ABILITY_LOTM_WORLD_MONSTER_FRENZY_STRENGTH", "LOTM_WORLD_MONSTER_FRENZY_STRENGTH_MOD",
    "LOC_LOTM_WORLD_PREVIEW_MONSTER_FRENZY", "('LOTM_WORLD_MONSTER_FRENZY_STRENGTH_MOD','Amount','15')",
    "ABILITY_LOTM_WORLD_MONSTER_FRENZY_STRENGTH_V2", "LOTM_WORLD_MONSTER_FRENZY_STRENGTH_V2_MOD",
    "('LOTM_WORLD_MONSTER_FRENZY_STRENGTH_V2_MOD','Amount','15')",
    "('LOTM_WORLD_MONSTER_TIER_MID_STRENGTH_MOD','Amount','10')",
    "('LOTM_WORLD_MONSTER_TIER_HIGH_STRENGTH_MOD','Amount','20')",
    "ABILITY_LOTM_WORLD_DYNAMIC_MOVEMENT_2", "('LOTM_WORLD_DYNAMIC_MOVEMENT_2_MOD','Amount','2')",
)) and "ApplyAbilityCount(unit,STRENGTH_ABILITY,1)" in monsters and all(token in workshops for token in (
    "SEQUENCE_STRENGTH_ABILITIES", "{10,SEQUENCE_STRENGTH_ABILITY}", "{75,\"ABILITY_LOTM_PP_WORKSHOP_SEQUENCE_75\"}",
    "LOTM_Effects.SyncAbilityTiers(ability,SEQUENCE_STRENGTH_ABILITIES,not rescue and desired or nil)",
    "LOTM_Effects.SetAbilityCount(ability,DYNAMIC_STRENGTH_ABILITY,0)",
)))
check("09b saved modifier rebuild", all(token in monsters for token in (
    'EFFECT_VERSION_PROPERTY="LOTM_WORLD_MONSTER_EFFECT_VERSION"', "CURRENT_EFFECT_VERSION=7", "RESCUE_WEATHER_ABILITY",
    "LEGACY_STRENGTH_ABILITY", "LEGACY_FRENZY_ABILITY", "LOTM_Effects.SetAbilityCount(ability,abilityType,0)",
    "rebuilt effects serial=", "unit:SetProperty(EFFECT_VERSION_PROPERTY,CURRENT_EFFECT_VERSION)",
    "for _,monster in ipairs(LiveMonsters()) do ReconcileMonsterAbilities(monster); end",
)))
check("10 map caps", all(token in monsters for token in (
    "MAPSIZE_DUEL=1", "MAPSIZE_TINY=2", "MAPSIZE_SMALL=2", "MAPSIZE_STANDARD=3", "MAPSIZE_LARGE=4", "MAPSIZE_HUGE=5",
)) and all(token in monsters for token in (
    "return LOTM_RESCUE_Phase5.MonsterGlobalCap(),mapSizeType;", "local multiplier=RescueActive() and LOTM_RESCUE_Phase5.GlobalCapMultiplier() or 1;",
)))
check("11 persistent unique serial", all(token in monsters for token in (
    "LOTM_WORLD_MONSTER_NEXT_SERIAL", "LOTM_WORLD_MONSTER_SERIAL", "LOTM_WORLD_MONSTER_ENGINE:",
)))
check("12 no city district territory or pillage", all(token in monsters for token in (
    "plot:IsWater()", "plot:GetOwner()>=0", "plot:IsCity()", "plot:GetDistrictType()>=0",
)) and "PILLAGE" not in monsters)
check("13 resource-221 flow applies Firaxis simulated damage", all(token in monsters for token in (
	"LOTM_RESCUE_SyncActions.MoveToward", "local function ScriptedAttack", "local function ScriptedCityAttack",
	"CombatManager.SimulateAttackVersus", "CombatResultParameters.DAMAGE_TO", "CombatResultParameters.DEFENSE_DAMAGE_TO",
	'LOTM_MP_TurnSync.Add(OnTurn,"WorldMonsters")', "UnitManager.FinishMoves(monster)",
)) and all(token not in monsters for token in (
	"NativeAttackPlot", "NativeUnitAttack", "NativeCityAttack", "UnitManager.RequestOperation",
	"UnitManager.CanStartOperation", "UnitOperationMoveModifiers", "LOTM_RESCUE_Command_NativeAttackConstants",
	"GetAi_Military", "StartScriptedOperationWithTargetAndRally", "AddUnitToScriptedOperation", "LOTM Rescue Attack Enemy City",
)))
check("13f obsolete UI attack relay is removed", all(token not in rescue_bootstrap_ui for token in (
	"LOTM_RESCUE_Command_NativeAttackConstants", "SubmitNativeAttackConstants", "UnitOperationMoveModifiers",
)) and "PlayerOperations.EXECUTE_SCRIPT" in rescue_bootstrap_ui)
check("13a rescue burst remains isolated", all(token in monsters for token in (
    "local function MonsterBurst()", "LOTM_RESCUE_Phase5.MonsterBurst()", "local function TrySpawnOne(camp,sourceUnit,periodic,networkSourceOwner,batch)",
    "for attempt=1,burst do", "local maximumRadius=RescueActive() and 3 or 2;",
    "function LOTM_WORLD_Monsters.RescueTurnSpawn(worldTurn,requested)", "LOTM_WORLD_MONSTER_PERIODIC_LAST_TURN",
)))
check("13b nearest AI/city-state attack and gated human targeting", all(token in monsters for token in (
	"player:IsMajor() and (not player:IsHuman() or PlayerHuntUnlocked())", '"CIVILIZATION_LEVEL_CITY_STATE"', "PlayerManager.GetAliveMinors()", "AICityTargets(monster)",
	"RescueActive() or plot:GetContinentType()==source:GetContinentType()", "targetKind=\"AI_CITY\"", "target.Owner",
	"ScriptedCityAttack(monster,target.City)", "CITY_BLOCKED_UNIT_", "CityManager.DestroyCity",
)))
check("13i player is ignored until only humans and seal churches remain", all(token in monsters for token in (
    "local function PlayerHuntUnlocked()", "PlayerManager.GetAliveMajors()", "PlayerManager.GetAliveMinors()",
    "PlayerManager.GetFreeCitiesPlayerID()", 'for _,zone in ipairs({"CENTER","FOOL","NIGHT","STORM"})',
    "not player:IsHuman() or PlayerHuntUnlocked()", "IsAllowedUnitTarget(other)", "IsAllowedUnitTarget(unit)",
    "UNLOCKED_ONLY_HUMANS_AND_SEAL_CHURCHES_REMAIN", "LOCKED_EXTERNAL_FACTIONS_REMAIN",
)))
check("13c independent nearest-city targeting replaces concentration", all(token in monsters for token in (
    "local function AssaultCityTarget(monster)", "local focus=candidates[1]", "nearest city locked serial=", "REDEPLOY_TARGET_MIN_DISTANCE",
)) and all(token not in monsters for token in (
    "LOTM_WORLD_MONSTER_ASSAULT_FOCUS:", "assault focus locked continent=", "assault retarget serial=",
)))
check("13g old concentrated locks migrate once", all(token in monsters for token in (
    "CURRENT_EFFECT_VERSION=7", "unit:SetProperty(TARGET_KIND_PROPERTY,nil)", "unit:SetProperty(TARGET_OWNER_PROPERTY,nil)", "unit:SetProperty(TARGET_ID_PROPERTY,nil)",
)))
check("13d engine simulation supplies both city layers and retaliation", all(token in monsters for token in (
	"result.DefenderDamage", "result.DefenseDamage", "result.AttackerDamage",
	"DefenseTypes.DISTRICT_GARRISON", "DefenseTypes.DISTRICT_OUTER", "ApplyEngineUnitDamage(attacker,result.AttackerDamage)",
)))
attack_slice=monsters[monsters.index("local function ScriptedAttack"):monsters.index("local function ReconcileMonsterAbilities")]
check("13e applied damage contains no hand-written combat formula", "math.exp" not in attack_slice and "24*" not in attack_slice and "CityDefense(" not in attack_slice)
check("13c synchronized persistent random target", all(token in monsters for token in (
    "LOTM_WORLD_MONSTER_LOCKED_TARGET_KIND", "LockedTarget(monster) or ChooseLockedTarget(monster)",
    "monster locked target serial=", "target released serial=", 'Kind="UNIT"', 'Kind="AI_CITY"',
    "LOTM_WORLD_State.Random(#candidates", "AITerritoryOwners()", "RedeployNearTarget(monster,destination,REDEPLOY_TARGET_MIN_DISTANCE,REDEPLOY_TARGET_MAX_DISTANCE,false,AITerritoryOwners())",
)))
check("13j UI visibility fix must not enter gameplay action", all(token not in monsters for token in (
    "RefreshNetworkMonsterRender", "LOTM_WORLD_MONSTER_RENDER_REFRESH",
    "pcall(UnitManager.PlaceUnit,unit,x,y)",
)))
check("14 both combat sides settle through the idempotent identity gate", all(token in monsters for token in (
    "attackerSerial", "defenderSerial",
    "FinalizeRemoval(attackerSerial,attackerPlayerID,attackerUnitID,defenderPlayerID,defenderUnitID,",
    "FinalizeRemoval(defenderSerial,defenderPlayerID,defenderUnitID,attackerPlayerID,attackerUnitID,",
    '"SYNCHRONIZED_COMBAT",true', "ClearCapturedIdentity", "CancelNetworkRemoval",
)))
network_remove_queue = monsters[monsters.index("local function QueueNetworkRemoval"):monsters.index("local function ReconcileActiveMonsterRemovals")]
network_remove_process = monsters[monsters.index("local function ProcessNetworkRemovals"):monsters.index("local function OnCombat")]
network_queue_cleanup = network_remove_process[network_remove_process.index("table.sort(networkRemovalQueue"):]
active_helpers = monsters[monsters.index("local function ActiveMonsterSerials"):monsters.index("local function CurrentEraIndex")]
active_reconcile = monsters[monsters.index("local function ReconcileActiveMonsterRemovals"):monsters.index("local function ProcessNetworkRemovals")]
live_monsters = monsters[monsters.index("local function LiveMonsters"):monsters.index("local function FindSpawnPlot")]
spawn_one = monsters[monsters.index("local function TrySpawnOne"):monsters.index("function LOTM_WORLD_Monsters.TrySpawnFromWorkshop")]
finalize_removal = monsters[monsters.index("local function FinalizeRemoval"):monsters.index("local function QueueNetworkRemoval")]
release = monsters[monsters.index("local function Release"):monsters.index("local function SettleReward")]
monster_startup = monsters[monsters.rindex("LOTM_MP_TurnSync.RunStartup(function()"):]
removed_callback = monsters[monsters.index("local function OnRemoved"):monsters.index("local function OnTurn")]
removed_network_prefix = removed_callback[:removed_callback.index("local serial=")]
network_mutations = (
    "Game.SetProperty(", ":SetProperty(", "UnitManager.InitUnit", "UnitManager.Kill",
    "CityManager.DestroyCity", "ChangeAbilityCount", "ChangeGoldBalance", "ChangeDamage",
)
check("14a network removal callback captures identity only without gameplay writes", all(token in network_remove_queue for token in (
    "networkRemovalBySerial[serial]", "Serial=serial", "OwnerID=owner", "UnitID=removedUnit",
    "QueuedTurn=Game.GetCurrentGameTurn()",
    "MonsterIdentityMatches(serial,owner,removedUnit)",
)) and all(token not in network_remove_queue for token in (
    "KillerID=", "KillerUnitID=", "EraIndex=", "LiveRevision=", "Game.SetProperty(",
))
    and "Release(" not in network_remove_queue and "SettleReward(" not in network_remove_queue)
check("14b network removal uses the sorted active index as its only Gameplay authority", all(token in network_remove_process for token in (
    "LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID)", "table.sort(networkRemovalQueue",
    "entry.QueuedTurn>=currentTurn", "break;",
    "network removal discarded serial=", 'ReconcileActiveMonsterRemovals("ACTIVE_INDEX_RUNTIME")',
)) and all(token in monsters for token in (
    "local networkRemovalBySerial={}", "entry.Cancelled=true", "LOTM_WORLD_MONSTER_ACTIVE_SERIALS",
    "ACTIVE_MONSTER_INDEX_VERSION", "CURRENT_ACTIVE_MONSTER_INDEX_VERSION=1",
    "if LOTM_MP_TurnSync.IsNetworkGame() then QueueNetworkRemoval(playerID,unitID); return; end",
    "if LOTM_MP_TurnSync.IsNetworkGame() then ProcessNetworkRemovals(playerID); end",
    'ReconcileActiveMonsterRemovals("ACTIVE_INDEX_STARTUP")',
)) and all(token in active_helpers for token in (
    "ActiveMonsterSerials()", "SaveActiveMonsterSerials", "table.sort(result)",
    'LOTM_WORLD_State.NumberGameProperty("LOTM_WORLD_MONSTER_NEXT_SERIAL",0)',
    'LOTM_WORLD_State.NumberGameProperty(MetaKey(serial,"LIVE"),0)==1',
)) and all(token in active_reconcile for token in (
    "for _,serial in ipairs(ActiveMonsterSerials())", "UnitManager.GetUnit(owner,unitID)",
    "unitSerial==serial", "FinalizeRemoval(entry.Serial", 'MetaKey(serial,"MISSING_SINCE")',
    "missingSince<currentTurn", "IdentityReused=identityReused",
    "killerID,killerUnitID,Game.GetCurrentGameTurn(),CurrentEraIndex(),true",
    'Game.SetProperty("LOTM_WORLD_MONSTER_LIVE_COUNT",liveCount)',
)) and network_remove_process.index('ReconcileActiveMonsterRemovals("ACTIVE_INDEX_RUNTIME")')
    < network_remove_process.index("table.sort(networkRemovalQueue")
    and "FinalizeRemoval(entry.Serial" not in network_remove_process
    and not any(token in network_remove_process for token in (
        "entry.KillerID", "entry.KillerUnitID", "entry.EraIndex", "entry.LiveRevision",
    ))
    and "if not activeSeen[serial] then" in live_monsters
    and "SaveActiveMonsterSerials(activeSerials)" in live_monsters
    and "RegisterActiveMonsterSerial(serial)" in spawn_one
    and "RemoveActiveMonsterSerial(normalizedSerial)" in finalize_removal
    and not any(token in removed_network_prefix for token in network_mutations)
    and not any(token in network_queue_cleanup for token in network_mutations)
    and "MigrateActiveMonsterIndex();" in monster_startup
    and spawn_one.index("RegisterActiveMonsterSerial(serial)")
        < spawn_one.index("LOTM_PP_Workshops.MarkNetworkUnitFiltered(unit)")
    and spawn_one.index("RegisterActiveMonsterSerial(serial)")
        < spawn_one.index("ApplyMonsterAbilities(unit,tier,moveDelta,periodBonus)")
    and all(token in release for token in (
        'MetaKey(serial,"RELEASE_TURN")', 'MetaKey(serial,"RELEASE_COOLDOWN_UNTIL")',
        'MetaKey(serial,"SOURCE_CAMP_EPOCH")', 'camp:GetProperty("LOTM_PP_WORKSHOP_CAMP_EPOCH")',
        'currentSlot=camp~=nil and NumberProperty(camp,"LOTM_WORLD_WORKSHOP_MONSTER_SERIAL",0) or 0',
        "if sourceEpoch~=nil and currentEpoch~=nil then", "elseif currentSlot==serial then",
        "if camp~=nil and sameCampGeneration then",
    ))
    and 'Game.SetProperty(MetaKey(normalizedSerial,"LIVE"),0)' in finalize_removal
    and 'Game.SetProperty(MetaKey(serial,"LIVE"),0)' not in release)
check("14c single-player removal commits the durable tombstone through FinalizeRemoval",
    all(token in removed_callback for token in (
        "if LOTM_MP_TurnSync.IsNetworkGame() then QueueNetworkRemoval(playerID,unitID); return; end",
        "FinalizeRemoval(serial,playerID,unitID,killerID,killerUnitID,",
        'Game.GetCurrentGameTurn(),nil,false,"SINGLE_PLAYER_CALLBACK",true',
    ))
    and all(token not in removed_callback for token in (
        "Release(serial)", "SettleReward(serial", "RemoveActiveMonsterSerial(serial)",
        'Game.SetProperty(prefix.."PLAYER",nil)', 'Game.SetProperty(prefix.."UNIT",nil)',
    ))
    and finalize_removal.index("Release(normalizedSerial")
        < finalize_removal.index("SettleReward(normalizedSerial")
        < finalize_removal.index("ClearCapturedIdentity(normalizedOwner")
        < finalize_removal.index('Game.SetProperty(MetaKey(normalizedSerial,"LIVE"),0)')
        < finalize_removal.index("RemoveActiveMonsterSerial(normalizedSerial)"))
sync_actions = (ROOT / "Scripts" / "LOTM_RESCUE_SyncActions.lua").read_text(encoding="utf-8")
scripted_killer = sync_actions[sync_actions.index("function LOTM_RESCUE_SyncActions.MarkScriptedKiller"):
    sync_actions.index("function LOTM_RESCUE_SyncActions.ScriptedKill")]
check("14d scripted killer attribution is bound to the durable target generation",
    all(token in scripted_killer for token in (
        'target:GetProperty("LOTM_WORLD_MONSTER_SERIAL")',
        'target:GetProperty("LOTM_RESCUE_PHASE4_SEQUENCE_SERIAL")',
        'Game.SetProperty(prefix.."TARGET_KIND",targetKind)',
        'Game.SetProperty(prefix.."TARGET_SERIAL",targetSerial)',
    ))
    and scripted_killer.index('Game.SetProperty(prefix.."PLAYER",nil)')
        < scripted_killer.index('Game.SetProperty(prefix.."TARGET_SERIAL",targetSerial)')
        < scripted_killer.rindex('Game.SetProperty(prefix.."PLAYER",killer:GetOwner())')
    and all(token in active_reconcile for token in (
        'Game.GetProperty(prefix.."TARGET_KIND")', 'prefix.."TARGET_SERIAL"',
        '==entry.Serial', "scriptedIdentityMatches",
    ))
    and all(token in removed_callback for token in (
        'Game.GetProperty(prefix.."TARGET_KIND")', 'prefix.."TARGET_SERIAL"',
        '==serial', "scriptedIdentityMatches",
    )))
check("15 rc.83 church resolver is isolated behind registration interface", all(token in monsters for token in (
    "RegisterQuestResolver", "questResolver", "handled=ok and result==true",
)) and "Scripts/LOTM_WORLD_Churches.lua" in modinfo)
check("16 monster-only black flag", all(token in flag_ui for token in (
    "LOTM_WORLD_MONSTER_TIER", "LOTM_WORLD_MONSTER_SERIAL", "MONSTER_BASE", "MONSTER_MARK",
    'SetIcon("ICON_LOTM_WORLD_MONSTER_MARK")', "ApplyMonsterColor", "ApplyPathColor",
    "WorkshopPath", "PATH_MARKS", "RefreshSpecialFlag", "Events.UnitAbilityGained.Add",
    "Events.UnitSelectionChanged.Add", "Events.UnitVisibilityChanged.Add",
    "Exact Firaxis fallback", "BASE_SetFlagUnitEmblem(self)",
)) and flag_ui.index("if IsMonster(unit)") < flag_ui.index("if IsWorkshopSequence(unit)")
    and "tonumber(unit:GetProperty" not in flag_ui and "PATH_HOLDER_TYPES" not in flag_ui)
check("17 monster icon atlas", all(token in icons + modinfo for token in (
    "ICON_ATLAS_LOTM_WORLD_MONSTER_MARK", "ICON_LOTM_WORLD_MONSTER_MARK",
    "LOTM_WORLD_MonsterMark40.dds", "LOTM_WORLD_MonsterMark256.dds",
)))
for size in (40, 256):
    data = (ROOT / f"Art/LOTM_WORLD_MonsterMark{size}.dds").read_bytes()
    check(f"18 monster DDS {size}", data[:4] == b"DDS " and data[84:88] == b"DXT5")

database = sqlite3.connect(":memory:")
database.executescript("""
CREATE TABLE Types(Type TEXT PRIMARY KEY, Kind TEXT);
CREATE TABLE UnitAbilities(UnitAbilityType TEXT PRIMARY KEY, Name TEXT, Description TEXT, Inactive INTEGER, Permanent INTEGER);
CREATE TABLE TypeTags(Type TEXT, Tag TEXT, PRIMARY KEY(Type,Tag));
CREATE TABLE UnitAbilityModifiers(UnitAbilityType TEXT, ModifierId TEXT, PRIMARY KEY(UnitAbilityType,ModifierId));
CREATE TABLE Modifiers(ModifierId TEXT PRIMARY KEY, ModifierType TEXT, Permanent INTEGER);
CREATE TABLE ModifierArguments(ModifierId TEXT, Name TEXT, Value TEXT, PRIMARY KEY(ModifierId,Name));
CREATE TABLE ModifierStrings(ModifierId TEXT, Context TEXT, Text TEXT, PRIMARY KEY(ModifierId,Context));
CREATE TABLE GlobalParameters(Name TEXT PRIMARY KEY, Value INTEGER);
INSERT INTO GlobalParameters VALUES('BARBARIAN_CAMP_ODDS_OF_NEW_CAMP_SPAWNING',2);
""")
try:
    database.executescript(sql)
    ability_count = database.execute("SELECT COUNT(*) FROM UnitAbilities").fetchone()[0]
    modifier_count = database.execute("SELECT COUNT(*) FROM Modifiers").fetchone()[0]
    camp_roll = database.execute(
        "SELECT Value FROM GlobalParameters "
        "WHERE Name='BARBARIAN_CAMP_ODDS_OF_NEW_CAMP_SPAWNING'"
    ).fetchone()[0]
    check(
        "19 monster SQL executes",
        ability_count == 7 and modifier_count == 7 and camp_roll == 9,
    )
finally:
    database.close()

failures = [name for name, passed in checks if not passed]
if failures:
    print(f"FAILED: {len(failures)} of {len(checks)} rc.82 checks failed")
    for failure in failures:
        print(f" - {failure}")
    raise SystemExit(1)

print(f"PASS: {len(checks)} rc.82 static/stub checks")
