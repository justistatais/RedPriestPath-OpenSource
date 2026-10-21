#!/usr/bin/env python3
"""Static contracts for Rescue Phase 10 final battle and victory."""

from pathlib import Path
import math
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
errors: list[str] = []


def text(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


def check(condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)


lua = text("Scripts/LOTM_RESCUE_Phase10.lua")
sql = text("Gameplay/LOTM_RESCUE_Phase10.sql")
phase10a = text("Scripts/LOTM_RESCUE_Phase10A.lua")
arson = text("Scripts/LOTM_RP_Arson.lua")
gameplay = text("Scripts/LOTM_RP_Gameplay.lua")
modinfo = text("RedPriestPath.modinfo")
icons = text("Art/LOTM_RESCUE_Phase10_Icons.xml")
artdef = text("Art/LOTM_RESCUE_Phase10_Units.artdef")
unit_flags = text("UI/LOTM_PP_UnitFlagManager.lua")
end_game = text("UI/EndGameMenu_LOTM_Redemption.lua")
setup = text("Config/LOTM_RP_PathSelection.xml")
workshops = text("Scripts/LOTM_PP_Workshops.lua")
churches = text("Scripts/LOTM_WORLD_Churches.lua")
zh = text("Text/zh_Hans_CN/LOTM_RP_GameplayText.xml")
en = text("Text/en_US/LOTM_RP_GameplayText.xml")

for snippet in (
    "local VERSION=40;",
    "local ALLIED_ACTION_VERSION=4;",
    "local BOSS_POSITION_VERSION=5;",
    "local function FinalTurn() return LOTM_RESCUE_Phase5.FinalTurn(); end",
    "finalTurns=costMultiplierScaled standard=150",
    "{Min=0,   Max=499, Strength=999,Phases=2,Heal=20,Summon=3,Cap=10,Skills=5}",
    "{Min=500, Max=999, Strength=888,Phases=2,Heal=15,Summon=4,Cap=8, Skills=4}",
    "{Min=1000,Max=1499,Strength=777,Phases=2,Heal=12,Summon=5,Cap=6, Skills=3}",
    "{Min=1500,Max=1999,Strength=666,Phases=2,Heal=8, Summon=6,Cap=4, Skills=2}",
    "{Min=2000,Max=2999,Strength=555,Phases=2,Heal=5,Summon=8,Cap=2,Skills=1}",
    "{Min=3000,Max=2147483647,Strength=444,Phases=2,Heal=5,Summon=8,Cap=2,Skills=1}",
    "local BEST_TIER_THRESHOLD=TIERS[#TIERS].Min;",
    "local PURIFICATION_DISPLAY_MAX=3000;",
    'Game.SetProperty("LOTM_RESCUE_PHASE10_BEST_TIER_THRESHOLD",BEST_TIER_THRESHOLD)',
    'Game.SetProperty("LOTM_RESCUE_PURIFICATION_DISPLAY_MAX",PURIFICATION_DISPLAY_MAX)',
    'Game.SetProperty("LOTM_RESCUE_PHASE10_TIER_THRESHOLD_"..index,TIERS[index].Min)',
    'Game.SetProperty("LOTM_RESCUE_PHASE10_PURIFICATION_LOCKED",purification)',
    'local purification=Game.GetProperty("LOTM_RESCUE_PHASE10_PURIFICATION_LOCKED")',
    'Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_PHASES_REMAINING",tier.Phases)',
    'Game.SetProperty("LOTM_RESCUE_PHASE10_SEAL_STATE","RELEASED")',
    'Game.SetProperty("LOTM_RESCUE_PHASE",10)',
    "ExactStrength(unit,550)",
    "LOTM_RESCUE_Phase10A.RefreshAll()",
    "local skillReady=Number(player:GetProperty(\"LOTM_RESCUE_WAR_GOD_RELIC_COMPLETED\"),0)==1;",
    "SetAbilityCount(unit,DIVINE_LEGION_ABILITY,skillReady and 1 or 0)",
    "local PLAYER_GOD_BASE_STRENGTH=550;",
    "local PLAYER_GOD_MOBILITY_THRESHOLD=1000;",
    "local PLAYER_GOD_MOBILITY_BONUS=30;",
    "local runtimeCombat=Number(unit:GetCombat(),0);",
    "local mobilityActive=runtimeCombat>PLAYER_GOD_MOBILITY_THRESHOLD;",
    "SetAbilityCount(unit,PLAYER_GOD_MOBILITY_ABILITY,mobilityActive and 1 or 0)",
    "local target=PLAYER_GOD_BASE_STRENGTH+(skillReady and math.max(0,inherited) or 0);",
    "boss:ChangeDamage(-math.min(tier.Heal,damage))",
    "CountMinions()<tier.Cap",
    'Number(Game.GetProperty("LOTM_RESCUE_PHASE10_DESCENT_TRIGGERED"),0)==1',
    'ApplyBits(unit,"ABILITY_LOTM_RESCUE_P10_EXTRA_ATTACK_",ATTACK_BITS,math.max(0,tier.Skills-1))',
    'local owner=Number(Game.GetProperty("LOTM_RESCUE_TEST_PLAYER_ID"),-1)',
    "MigrateChurchGodOwnership()",
    "GuideChurchGods(playerID,false)",
    "RevealBattlefield()",
    "local BOSS_SIGHT_RADIUS=6;",
    "local BOSS_SIGHT_VERSION=2;",
    "MaintainBossVisibility()",
    '"LOTM_RESCUE_PHASE10_BOSS_SIGHT_PLOTS_V"..BOSS_SIGHT_VERSION',
    "Events.UnitMoveComplete.Add(OnUnitMoveComplete)",
    "MigrateBossPosition()",
    "AlliedAttack(unit,boss)",
    "FreezeIndependentGodAI(playerID)",
    'Game.SetProperty("LOTM_RESCUE_PHASE10_ALLIED_ACTION_VERSION",ALLIED_ACTION_VERSION)',
    'Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_PLOT"',
    'Spawn(owner,BOSS_TYPE,"BOSS",2,1)',
    'boss owner fallback from=BARBARIAN to=INDEPENDENT_FREE_CITIES',
    'Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_OWNER_MODE",ownerMode)',
    'CandidatePlots(2,1)',
    'reason=BOSS_PLOT_MISSING',
    'reason=NO_CHURCH_GODS_INDEXED',
    'reason=PARTIAL_CHURCH_GODS_INDEXED',
    'reason=BOSS_NOT_INDEXED',
    "m_spawnReserved[actualPlot:GetIndex()]=true",
    "Events.UnitRemovedFromMap.Add(OnRemoved)",
    "GameEvents.OnCombatOccurred.Add(OnCombat)",
    "Events.UnitDamageChanged.Add(OnUnitDamageChanged)",
    "ResolveBossDefeat",
    "boss terminal damage kill",
    "GrantVictory()",
    "MigrateExhaustedBossVictory()",
):
    check(snippet in lua, f"Phase 10 Lua contract missing: {snippet}")

spawn_boss = lua.split("local function SpawnBoss()", 1)[1].split("local function EnsureChurchGods()", 1)[0]
check("PublishTier()" not in spawn_boss, "Boss respawn must not re-read or re-lock live Purification")
check('Game.GetProperty("GLOBAL_PURIFICATION")' not in spawn_boss, "Boss respawn reads live Purification")

find_role = lua.split("local function FindRole(role)", 1)[1].split("local function TierFor", 1)[0]
check("UnitManager.GetUnit" in find_role, "Role lookup must directly resolve freshly spawned units before player collection indexing")
check("local m_roleUnits={};" in lua, "Freshly spawned role objects are not cached for same-turn coordination")
check("m_roleUnits[role]=unit;" in lua, "Spawn does not cache the returned role object")
check("PlacedUnit(cached,owner,unitID)" in find_role, "Cached roles are trusted without verifying real map placement")
check('Log("role lookup unavailable role="' in find_role and 'NOT_PLACED_METADATA_PRESERVED' in find_role, "Unavailable old-save roles do not preserve removal metadata")

spawn = lua.split("local function Spawn(playerID", 1)[1].split("local function FindRole(role)", 1)[0]
check("m_phase10Creating=true;" in spawn and "m_phase10Creating=false;" in spawn, "Phase 10 spawn does not guard synchronous UnitAdded listeners")
check("PlacedUnit(unit,playerID,unitID)" in spawn, "Spawn accepts a non-nil InitUnit result without real placement verification")
check("UnitManager.PlaceUnit" in spawn, "Spawn lacks a synchronized placement fallback")
check("for attempt,entry in ipairs(candidates) do" in spawn, "Spawn does not iterate every ordered candidate")
check('reason=ALL_CANDIDATES_REJECTED' in spawn, "Spawn does not summarize total candidate exhaustion")
check("PlacementAllowed(actualPlot,minRange,maxRange,entry.Distance)" in spawn, "Spawn does not validate the actual plot against the active candidate ring")
check('"OUTSIDE_ATTEMPT_RING"' in lua, "A first-ring attempt can silently accept an engine relocation into the second ring")
check("pcall(UnitManager.Kill,unit)" in spawn, "Rejected temporary spawn units are not cleaned before the next candidate")
commit = spawn.index('Game.SetProperty(RoleKey(role,"OWNER"),playerID)')
verification = spawn.index("if accepted then")
success_log = spawn.index('Log("spawn committed role="')
check(commit > verification and success_log > commit, "Role state or success log is committed before actual placement verification")
check('Log("spawned role="' not in spawn, "Spawn retains the old unverified success log")

spawn_boss_owner = lua.split("local function SpawnBoss()", 1)[1].split("local function MigrateBossPosition()", 1)[0]
check('ownerMode=="INDEPENDENT_FREE_CITIES" and independentOwner or barbID' in spawn_boss_owner, "Boss respawn does not reuse the proven near-center owner fallback")
check('unit=Spawn(owner,BOSS_TYPE,"BOSS",2,1)' in spawn_boss_owner, "Boss fallback does not preserve the first/second-ring placement contract")
check('if unit==nil and owner==barbID and independentOwner>=0 then' in spawn_boss_owner, "Boss does not fall back only after the barbarian placement attempt fails")

guide = lua.split("local function GuideChurchGods", 1)[1].split("local function FreezeIndependentGodAI", 1)[0]
completion_write = guide.index('Game.SetProperty("LOTM_RESCUE_PHASE10_ALLIED_ACTION_VERSION",ALLIED_ACTION_VERSION)')
found_guard = guide.index('if found<#CHURCH_GODS then Log("allied siege delayed reason=PARTIAL_CHURCH_GODS_INDEXED')
action_loop = guide.index("for _,entry in ipairs(indexed) do")
check(completion_write > found_guard and completion_write > action_loop, "Allied siege completion is written before all three church gods are indexed and processed")
check('Log("allied siege completed turn="..turn.." godsProcessed="..found)' in guide, "Allied siege completion count is not logged")

freeze = lua.split("local function FreezeIndependentGodAI", 1)[1].split("local function MigrateChurchGodOwnership", 1)[0]
check('boss:GetOwner()==owner' in freeze and 'UnitManager.FinishMoves(boss)' in freeze, "A free-cities fallback Boss can move under native AI before the shared siege")

check('local function GuideOuterGod' in lua and 'NearestChurchGod(boss)' in lua and 'NearestCity(boss)' in lua, "Outer God target priority is not explicit")
check('DestroyCityDirect(target.City)' in lua and 'CityDestroyDirectives.RAZE' in lua, "Outer God city target does not use direct synchronized destruction")
check('MoveToward(boss,targetPlot,6,false,true,nil,nil,moveDiagnostic)' in lua, "Outer God action does not use six movement points with explicit diagnostics")
boss_sight = lua.split("local function MaintainBossVisibility()", 1)[1].split("local function CombatStrengthDamage", 1)[0]
check("BossSightPlots(boss)" in boss_sight, "Persistent sight does not follow the current Boss position")
check("visibility:ChangeVisibilityCount(index,-1)" in boss_sight, "Persistent sight does not remove the previous Boss area")
check("visibility:ChangeVisibilityCount(index,1)" in boss_sight, "Persistent sight does not reveal the current Boss area")
check("visibility:IsVisible(index)" in boss_sight, "Persistent sight is not restored when save/load loses the active visibility source")
begin_descent = lua.split("local function BeginDescent()", 1)[1].split("local function Refresh", 1)[0]
check(begin_descent.index("MaintainBossVisibility()") > begin_descent.index("GuideOuterGod(-1,true)"), "Initial descent does not refresh sight after the Boss moves")
refresh = lua.split("local function Refresh", 1)[1].split("ResolveBossDefeat=function", 1)[0]
check(refresh.index("MaintainBossVisibility()") > refresh.index("MaintainBoss(playerID)"), "Turn refresh does not maintain sight after Boss movement or respawn")
removed = lua.split("local function ApplyRemoved", 1)[1].split("local function OnRemoved", 1)[0]
check('role=="BOSS" and currentRoleMatches then MaintainBossVisibility(); end' in removed, "Boss removal does not clear its tracked visibility source")
check('local CHURCH_GOD_RESPAWN_DELAY=5;' in lua and 'local CHURCH_GOD_RESPAWN_VERSION=2;' in lua and 'RESPAWN_PENDING' in lua and 'RESPAWN_USED' in lua, "Church gods do not use a five-turn one-time respawn state")
check('math.floor(24*math.exp((attack-defense)/25))' in lua and 'target:ChangeDamage(damage)' in lua, "Final battle does not use the original combat-strength differential curve")
check('local BOSS_LIVES=2;' in lua and 'LOTM_RESCUE_PHASE10_BOSS_SPAWN_COUNT' in lua and 'reason=LIVES_EXHAUSTED' in lua, "Boss is not limited to one respawn/two total lives")
check('LOTM_RESCUE_PHASE10_BOSS_EPOCH' in lua and 'local function BossEpoch()' in lua
      and 'unit:SetProperty("LOTM_RESCUE_PHASE10_BOSS_EPOCH",epoch)' in lua,
      "Boss persistent identity epoch is not assigned on every spawn")
check('local function KillBossAtTerminalDamage' in lua and 'maximum-1' in lua and 'boss terminal damage kill' in lua, "Boss terminal one-hit-point clamp is not converted into a lethal removal")
check('ResolveBossDefeat(playerID,unitID,' in removed and 'm_bossIntentionalDefeat[key]' in removed and 'boss removed without valid defeat' not in lua, "Boss removal must resolve a phase even when the combat callback arrives late")
ensure_player_god = lua.split("local function EnsurePlayerGod", 1)[1].split("local function CountMinions", 1)[0]
check(ensure_player_god.index("ExactStrength(unit,target)") < ensure_player_god.index("unit:GetCombat()"), "Player-god mobility reads Combat before current-turn strength is refreshed")
check("runtimeCombat>PLAYER_GOD_MOBILITY_THRESHOLD" in ensure_player_god and "runtimeCombat>=" not in ensure_player_god, "Player-god mobility threshold must be strictly above 1000")
church_gods = lua.split("local function EnsureChurchGods", 1)[1].split("local function RevealBattlefield", 1)[0]
check("PLAYER_GOD_MOBILITY_ABILITY" not in church_gods, "Church gods incorrectly receive the player-god mobility ability")
check('reason=NOT_PLACED_METADATA_PRESERVED' in lua and 'local canSpawn=state=="";' in lua, "Missing church-god roles can bypass the one-respawn gate")
check('if unit~=nil then ExactStrength(unit,PLAYER_GOD_BASE_STRENGTH); PublishNetworkConfirmedDamage(unit); end' in church_gods, "Existing-save church gods are not recalibrated without respawning")
check('god combat damage correction role=' in lua and 'CorrectNativeGodCombatDamage' in lua, "Single-player final-god native combat damage correction is missing")
check('unit:GetProperty("LOTM_RESCUE_PHASE10_APPLIED_STRENGTH")' in lua and 'if applied>0 then return applied; end' in lua, "Final-god damage does not prioritize the exact synchronized strength above GameCore's 255 display clamp")
check('EffectiveAttackStrength(attacker,0)' in lua and 'EffectiveCombatStrength(defender,0)' in lua, "God combat correction does not use separate live attack and defense strengths")
check('Role="ATTACKER_RETALIATION"' in lua and 'if not ranged then' in lua, "Melee retaliation involving a final god is not corrected symmetrically")
check('m_nativeDamageCorrections[key]={Old=current,New=current+extra}' in lua and 'correction.Old==oldValue and correction.New==newValue' in lua, "Scripted god-combat damage can leak into the next combat correction")
check('m_nativeDamageEvents={}; m_bossCombatEvents={};' in lua, "Stale native damage evidence is not cleared at each active turn boundary")
check('local CONFIRMED_DAMAGE_PROPERTY="LOTM_RESCUE_PHASE10_LAST_CONFIRMED_DAMAGE";' in lua
      and 'local function PublishNetworkConfirmedDamage(unit)' in lua
      and 'unit:SetProperty(CONFIRMED_DAMAGE_PROPERTY,current)' in lua,
      "Network final gods do not persist their synchronized last-confirmed damage")
damage_handler = lua.split("local function OnUnitDamageChanged", 1)[1].split("local function OnCombat", 1)[0]
network_damage = damage_handler.split("if IsNetworkMultiplayer() then", 1)[1].split("\n end\n local key=", 1)[0]
check("return;" in network_damage
      and all(token not in network_damage for token in (
          "m_nativeDamageEvents", "m_bossCombatEvents", "m_nativeDamageCorrections",
          "SetProperty(", "ChangeDamage(", "UnitManager.Kill", "KillBossAtTerminalDamage(",
          "ResolveBossDefeat(", "QueueNetworkBossDamage(",
      )), "Network UnitDamageChanged must be a non-authoritative no-op")
network_removed = lua.split("local function OnRemoved", 1)[1].split("local function ProcessNetworkRemovals", 1)[0]
check("if IsNetworkMultiplayer() then QueueNetworkRemoval(playerID,unitID,role); return; end" in network_removed
      and all(token not in network_removed for token in ("Game.SetProperty(", "ResolveBossDefeat(", "MaintainBossVisibility(")),
      "Network UnitRemovedFromMap must only queue Lua-local removal evidence")
network_removals = lua.split("local function ProcessNetworkRemovals", 1)[1].split("local function OnUnitMoveComplete", 1)[0]
check(all(token in network_removals for token in (
    "LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID)", "entry.QueuedTurn<currentTurn",
    "table.sort(ready,function(a,b)", "a.PlayerID<b.PlayerID", "a.UnitID<b.UnitID",
    "ApplyRemoved(entry.PlayerID,entry.UnitID,entry.Role,entry.Intentional,entry.Epoch)",
)), "Network removals must cross a full turn and settle in stable player/unit order")
check('entry.Epoch<BossEpoch()' in network_removals
      and 'role~="BOSS" or Number(epoch,BossEpoch())==BossEpoch()' in removed
      and 'Game.SetProperty(EngineKey(playerID,unitID),nil)' in removed,
      "Deferred removals must use the Boss epoch before clearing persistent identity")
network_correction = lua.split("local function CorrectNetworkGodCombatDamage", 1)[1].split("local function OnUnitDamageChanged", 1)[0]
check(all(token in network_correction for token in (
    "local desired=CombatStrengthDamage(attack,defense)", "if not isBoss and desired>=maximum then",
    "pcall(UnitManager.Kill,unit)", "god combat synchronized saturated kill role=",
    "if not isBoss then return; end", "unit:GetProperty(CONFIRMED_DAMAGE_PROPERTY)",
    "if stored==nil then", "reason=CONFIRMED_DAMAGE_MISSING", "if current<=confirmed then",
    "reason=NATIVE_DAMAGE_NOT_OBSERVED", "local observed=math.max(0,current-confirmed)",
    "local extra=math.max(0,desired-observed)", "unit:ChangeDamage(extra)",
    "PublishNetworkConfirmedDamage(UnitManager.GetUnit(playerID,unitID))",
)) and "stored==nil and 0" not in network_correction,
      "Synchronized combat lacks baseline-free saturated kills or a real post-native Boss checkpoint before nonlethal supplementation")
check(network_correction.index("if not isBoss and desired>=maximum then")
      < network_correction.index("if not isBoss then return; end")
      < network_correction.index("unit:GetProperty(CONFIRMED_DAMAGE_PROPERTY)"),
      "Ordinary targets must receive only baseline-free saturated kills, while checkpoint correction remains Boss-only")
on_combat = lua.split("local function OnCombat", 1)[1].split("local function ApplyRemoved", 1)[0]
check('if networkGame then' in on_combat
      and 'if defenderIsBoss or IsGod(attacker) then CorrectNetworkGodCombatDamage(defender,"DEFENDER",attack,defense,defenderIsBoss); end' in on_combat
      and 'if not ranged and (attackerIsBoss or IsGod(defender)) then CorrectNetworkGodCombatDamage(attacker,"ATTACKER_RETALIATION",retaliation,attackerDefense,attackerIsBoss); end' in on_combat,
      "Synchronized combat does not cover Boss ledger correction plus saturated god attacks and retaliation in both directions")
check('PublishNetworkConfirmedDamage(UnitManager.GetUnit(attackerPlayerID,attackerUnitID))' not in on_combat
      and 'PublishNetworkConfirmedDamage(UnitManager.GetUnit(defenderPlayerID,defenderUnitID))' not in on_combat,
      "Ordinary combat survivors must not receive a stale persistent damage baseline")
check('KillBossAtTerminalDamage(boss,"SYNCHRONIZED_COMBAT")' in on_combat,
      "Synchronized combat does not own the network Boss terminal-damage kill")
check('ResolveBossDefeat(bossOwner,bossUnit,"SYNCHRONIZED_COMBAT",epoch)' in on_combat,
      "Synchronized combat does not immediately commit a confirmed Boss terminal kill")
check(all(token not in lua for token in (
    "m_pendingNetworkBossDamage", "QueueNetworkBossDamage", "ProcessNetworkCombatEvidence",
    "ProcessNetworkBossDamage", 'QueuedTurn=Game.GetCurrentGameTurn()};\n   CorrectNativeGodCombatDamage',
)), "Network damage correction still depends on a Lua-local deferred queue")
move_complete = lua.split("local function OnUnitMoveComplete", 1)[1].split("local function OnSynchronizedRefresh", 1)[0]
check(move_complete.index("if IsNetworkMultiplayer() then return; end") < move_complete.index("MaintainBossVisibility()"),
      "Network UnitMoveComplete still writes authoritative Boss visibility")
check('LOTM_MP_TurnSync.Add(OnSynchronizedRefresh,"RescuePhase10")' in lua
      and "ProcessNetworkRemovals(playerID);" in lua,
      "Phase 10 synchronized refresh does not drain the remaining removal queue")
check('PublishNetworkConfirmedDamage(boss)' in lua
      and 'PublishNetworkConfirmedDamage(target)' in lua
      and 'PublishNetworkConfirmedDamage(existingBoss)' in lua
      and 'PublishNetworkConfirmedDamage(unit)' in church_gods
      and 'PublishNetworkConfirmedDamage(unit)' in ensure_player_god,
      "Boss and church/player gods do not maintain confirmed damage after synchronized scripted changes and refresh")
check(max(1, min(100, math.floor(24 * math.exp((999 - 78) / 25)))) == 100, "Synthetic 999-vs-78 god retaliation must be lethal-strength damage")
check(max(1, min(100, math.floor(24 * math.exp((78 - 999) / 25)))) == 1, "Synthetic 78-vs-999 attack must retain the original one-damage floor")
check('for _,zone in ipairs({"CENTER","FOOL","NIGHT","STORM"}) do' in lua and 'protected[plot:GetIndex()]~=true' in lua, "Outer God city targeting does not exclude descent and church cities")
check('local function GuideMinions(playerID,force)' in lua and 'LOTM_RESCUE_PHASE10_IS_MINION' in lua, "Outer God minions lack synchronized city guidance")
check('MoveToward(minion,targetPlot,5,false,true,nil,nil,moveDiagnostic)' in lua and 'DestroyCityDirect(target.City)' in lua, "Outer God minions do not move five tiles with explicit diagnostics and destroy adjacent cities")
check('LOTM_RESCUE_PHASE10_MINION_ACTION_TURN' in lua and 'outer god minion action turn=' in lua, "Outer God minion actions are not once-per-world-turn and auditable")
check('local VERSION=40;' in lua, "Phase 10 player-god recovery version is not active")
for token in (
    'local PLAYER_GOD_RESPAWN_DELAY=5;', 'local function PlayerGodIDFromRole(role)',
    'Game.SetProperty(RoleKey(role,"STATE"),"RESPAWN_PENDING")',
    'Game.SetProperty(RoleKey(role,"RESPAWN_USED"),1)',
    'Log("player god permanently destroyed role="..role',
):
    check(token in lua, f"player-god one-time five-turn recovery contract missing: {token}")
check('local EXHAUSTED_BOSS_RECOVERY_VERSION=1;' in lua and 'local BOSS_DEATH_RECOVERY_VERSION=1;' in lua and 'BOSS_DEFEAT_COUNT' in lua and 'legacy exhausted boss reconciled' in lua and 'defeatCount>=BOSS_LIVES' in lua and 'Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_PHASES_REMAINING",0)' in lua, "Old saves with two Boss deaths and no Boss are not reconciled through the established victory finalizer")
check('local VICTORY_PRESENTATION_VERSION=1;' in lua and 'local function ReconcileVictoryPresentation()' in lua and 'victory presentation published reason=' in lua and 'LOTM_RESCUE_PHASE10_WINNING_TEAM' in lua, "Previously marked victories do not reconcile the synchronized rescue presentation state")
check('Game.SetWinningTeam' not in lua and 'CommitTeamVictory' not in lua and 'MigrateVictoryDelivery' not in lua, "Phase 10 must not submit victory through a parallel Lua API path")
check(all(x in sql for x in ('LOTM_RESCUE_DISABLE_NATIVE_CONQUEST','REQUIREMENT_COLLECTION_COUNT_EQUALS','COLLECTION_MAJOR_TEAMS',"('LOTM_RESCUE_DISABLE_NATIVE_CONQUEST','Count','-1')")), "Native conquest is not protected by a deterministically impossible rescue-only requirement")
check("WHERE VictoryType='VICTORY_CONQUEST'" in sql and "WHERE VictoryType <> 'VICTORY_CONQUEST'" in sql, "Rescue mode does not retain only the native conquest victory pipeline")
check('VICTORY_LOTM_REDEMPTION' not in sql and 'VICTORY_LOTM_REDEMPTION' not in setup, "Rescue mode still registers a parallel custom victory type")
check('REQUIREMENT_PLAYER_HAS_BUILDING' not in sql and "DELETE FROM Buildings WHERE BuildingType='BUILDING_LOTM_RESCUE_VICTORY_TOKEN'" in sql, "Rescue victory still uses a token/native-victory bridge")
check('local BOSS_SIGHT_RADIUS=6;' in lua and 'local BOSS_SIGHT_VERSION=2;' in lua, "Boss persistent sight must match the single-player six-tile sight and migrate old saves")
check('GameConfiguration.IsAnyMultiplayer()' in lua, "City-state blocker clearing is not restricted to multiplayer")
blocker = lua.split("local function AdjacentCityBlocker", 1)[1].split("local function NearestChurchGod", 1)[0]
check('IsCityStateOwner' not in blocker, "Outer God blocker clearing still excludes major-player cities")
check('Map.GetPlotDistance(unit:GetX(),unit:GetY(),target.City:GetX(),target.City:GetY())==1' in blocker, "Outer God blocker clearing is not restricted to the besieged city first ring")
check('table.sort(candidates,function(a,b) return a:GetID()<b:GetID(); end)' in blocker, "Outer God blocker selection is not deterministic")
check('elseif kind=="CITY" and after==2 then' in lua and 'AttackAdjacentCityBlocker(boss,target)' in lua, "Outer God does not clear a city blocker when stranded on the second ring")
check('elseif after==2 then' in lua and 'blockerAttacked,blockerReason,blockerDamage,blockerOwner,blockerUnit=AttackAdjacentCityBlocker(minion,target)' in lua, "Outer God minions do not clear city blockers when stranded on the second ring")
check('CITY_BLOCKER_DESTROYED' in lua and 'blockerOwner=' in lua and 'blockerUnit=' in lua, "City blocker attacks are not auditable")
check('local function FirstRingEntries(targetPlot)' in lua and 'open=' in lua and 'district=' in lua and 'units=' in lua, "Phase 10 does not log first-ring placement conditions")
check('city assault diagnostic stage=' in lua and 'BEFORE_MOVE' in lua and 'AFTER_MOVE' in lua and 'AFTER_ACTION' in lua, "Phase 10 city-assault diagnostic stages are incomplete")
check('rawResultType=' in lua and 'rawResult=' in lua and 'destinationDistance=' in lua, "Phase 10 does not expose PlaceUnit selection and raw result diagnostics")
sync_actions = text("Scripts/LOTM_RESCUE_SyncActions.lua")
check('moveDiagnostic)' in sync_actions and 'diagnostic.CallOK=ok' in sync_actions and 'diagnostic.RawResult=tostring(result)' in sync_actions, "Synchronized movement does not capture the raw PlaceUnit result when explicitly requested")
check('local VERSION=9;' in sync_actions, "Synchronized movement expanding target-ring version is not active")
check('for attempt,entry in ipairs(retryOptions) do' in sync_actions and 'reason.."_RETRY_"..attempt' in sync_actions, "Explicitly diagnosed Phase 10 movement does not try another equally close candidate")
check('API_NIL_NO_MOVE' in sync_actions and 'API_FALSE' in sync_actions and 'PCALL_ERROR' in sync_actions and 'UNEXPECTED_COORD_CHANGE' in sync_actions, "Placement attempts do not return specific observable failure reasons")
check('diagnostic==nil then' in sync_actions and 'pcall(UnitManager.PlaceUnit,unit,destination:GetX(),destination:GetY())' in sync_actions, "Legacy/single-player movement is not isolated from multi-candidate retry")
check('attempts=' in lua and 'failureReason=' in lua and 'retryCandidates=' in lua, "Phase 10 does not log every placement attempt and its specific reason")
check('local function PlacementRejected(moveDiagnostic)' in lua and 'local function OpenFirstRingCount(targetPlot)' in lua, "Network Phase 10 cannot prove a rejected placement with a statically open first ring")
check('FORCED_SIEGE_' in lua and 'PlacementRejected(moveDiagnostic)' in lua and 'OpenFirstRingCount(targetPlot)>0' in lua, "Network Phase 10 lacks the forced siege fallback after engine placement rejection")
check('DeclareWar' not in lua and 'NO_WAR_API' not in lua, "Unavailable diplomacy declaration experiment was not removed")
check('PERFECT_MODEL_PATHS={PATH_RED_PRIEST=true,PATH_BLACK_EMPEROR=true}' in lua and 'PERFECT_MODEL_TYPE="UNIT_LOTM_RESCUE_GOD_PERFECT"' in lua, "Red Priest and Black Emperor gods do not reuse the Perfect model type")
desired_player_god = lua.split("local function DesiredPlayerGodType(path)", 1)[1].split("local function EnsurePlayerGod", 1)[0]
check('PERFECT_MODEL_PATHS[path]' in desired_player_god and "IsNetworkMultiplayer" not in desired_player_god, "Perfect-model substitution must apply in both single-player and network multiplayer")
check('player god model migrated' in lua and 'Game.SetProperty(EngineKey(oldOwner,oldID),nil)' in lua, "Existing player gods are not safely migrated to the Perfect model type")
check('local function UpdateBossCityLock(target,turn)' in lua and 'turn-start+1' in lua and 'lockAge>=3' in lua, "Outer God city lock does not force resolution on the third locked turn")
check('local function LockedCityTarget(unit)' in lua and 'target=LockedCityTarget(boss) or NearestCity(boss)' in lua, "Outer God can teleport into a nearer-city retarget loop instead of keeping the current city lock")
locked_city = lua.split("local function LockedCityTarget", 1)[1].split("local function UpdateBossCityLock", 1)[0]
check('for _,zone in ipairs({"CENTER","FOOL","NIGHT","STORM"}) do' in locked_city, "A persisted city lock can bypass protected central/church-city filtering")
check('LOCK_TIMEOUT_3_' in lua and 'lockStart=' in lua and 'lockAge=' in lua and 'cityResolved=' in lua, "Three-turn Outer God city resolution is not auditable")
outer_god_guide = lua.split("local function GuideOuterGod", 1)[1].split("local function GuideChurchGods", 1)[0]
check('ExactStrength(boss,lockedTier.Strength)' in outer_god_guide, "Existing-save Boss is not recalibrated before its first action")
lock_timeout = outer_god_guide.split('if kind=="CITY" and not cityResolved and lockAge>=3 then', 1)[1].split("if cityResolved then", 1)[0]
check("IsCityStateOwner" not in outer_god_guide, "Major-player cities are still excluded from the target lock and timeout")
check("IsNetworkMultiplayer" not in lock_timeout, "Three-turn city timeout must apply in both single-player and network multiplayer")

boss_migration = lua.split("local function MigrateBossPosition()", 1)[1].split("local function EnsureChurchGods()", 1)[0]
check('Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_POSITION_VERSION",BOSS_POSITION_VERSION)' in boss_migration, "Boss position migration is not version gated")
check("CandidatePlots(2,1)" in boss_migration, "Old Boss migration is not limited to the first or second center ring")
check("for attempt,entry in ipairs(candidates) do" in boss_migration, "Old Boss migration does not try every first/second-ring candidate")

check("Workshops.Entry.Phase10Create" in workshops, "Workshop cleanup does not guard Phase 10's synchronous creation window")
check("RESCUE_FINAL_BATTLE_TYPES[u:GetType()]~=true" in workshops, "Workshop cleanup does not use stable type-index exemptions for final battle units")

for unit_type in (
    "UNIT_LOTM_RESCUE_GOD_FOOL",
    "UNIT_LOTM_RESCUE_GOD_NIGHT",
    "UNIT_LOTM_RESCUE_GOD_STORM",
    "UNIT_LOTM_RESCUE_GOD_RED_PRIEST",
    "UNIT_LOTM_RESCUE_GOD_PERFECT",
    "UNIT_LOTM_RESCUE_GOD_THIEF",
    "UNIT_LOTM_RESCUE_GOD_BLACK_EMPEROR",
    "UNIT_LOTM_RESCUE_OUTER_GOD_AVATAR",
    "UNIT_LOTM_RESCUE_OUTER_GOD_MINION",
):
    check(unit_type in sql, f"Phase 10 database misses {unit_type}")
    check(f'm_Name text="{unit_type}"' in artdef, f"Phase 10 ArtDef misses {unit_type}")
    for suffix in ("", "_FOW", "_WHITE", "_BLACK", "_PORTRAIT"):
        check(f'Name="ICON_{unit_type}{suffix}"' in icons, f"Phase 10 icon misses {unit_type}{suffix}")

for player_god in (
    "UNIT_LOTM_RESCUE_GOD_RED_PRIEST",
    "UNIT_LOTM_RESCUE_GOD_PERFECT",
    "UNIT_LOTM_RESCUE_GOD_THIEF",
    "UNIT_LOTM_RESCUE_GOD_BLACK_EMPEROR",
):
    check(
        f"('{player_god}','LOC_UNIT_" in sql
        and f"{player_god}_NAME','LOC_UNIT_LOTM_RESCUE_PLAYER_GOD_DESCRIPTION',5,8,550,'DOMAIN_LAND'" in sql,
        f"{player_god} database base Combat must be 550",
    )

for snippet in (
    "MODIFIER_UNIT_ADJUST_COMBAT_STRENGTH",
    "MODIFIER_LOTM_RESCUE_UNIT_ADJUST_BASE_COMBAT_STRENGTH",
    "EFFECT_ADJUST_UNIT_COMBAT_STRENGTH",
    "ABILITY_LOTM_RESCUE_P10_STRENGTH_",
    "MODIFIER_UNIT_ADJUST_NUM_ATTACKS",
    "REQUIREMENTS_LOTM_RESCUE_DISABLE_NATIVE_CONQUEST",
    "VICTORY_CONQUEST",
    "LOC_VICTORY_LOTM_RESCUE_FINAL",
    "CriticalPercentage=100",
    "PROJECT_LOTM_RESCUE_WAR_GOD_RELIC",
    "LOTM_RESCUE_P10_ALLOW_WAR_GOD_RELIC",
    "MODIFIER_PLAYER_ALLOW_PROJECT",
    "ABILITY_LOTM_RESCUE_DIVINE_LEGION",
    "LOC_ABILITY_LOTM_RESCUE_DIVINE_LEGION_DESCRIPTION",
    "ABILITY_LOTM_RESCUE_PLAYER_GOD_MOBILITY_30",
    "LOTM_RESCUE_PLAYER_GOD_MOBILITY_30_MOD",
    "MODIFIER_PLAYER_UNIT_ADJUST_MOVEMENT",
    "('LOTM_RESCUE_PLAYER_GOD_MOBILITY_30_MOD','Amount','30')",
    "LOC_ABILITY_LOTM_RESCUE_PLAYER_GOD_MOBILITY_DESCRIPTION",
):
    check(snippet in sql, f"Phase 10 database contract missing: {snippet}")

check('include("LOTM_RESCUE_Phase10A")' in gameplay, "Phase 10A measurement must load before Phase 10")
check('include("LOTM_RESCUE_Phase10")' in gameplay, "Phase 10 is not included")
check(gameplay.index('include("LOTM_RESCUE_Phase10A")') < gameplay.index('include("LOTM_RESCUE_Phase10")'), "Phase 10 include order is wrong")
check('id="LOTM_RESCUE_PHASE10_DATABASE" criteria="LOTM_RP_RESCUE_MODE"' in modinfo, "Phase 10 database is not Rescue-only")
# Keep VICTORY_CONQUEST only as the Firaxis presentation template while its
# native GameCore condition is deterministically impossible in rescue mode.
check(
    "DELETE FROM Victories" in sql
    and "VictoryType <> 'VICTORY_CONQUEST'" in sql
    and "WHERE VictoryType='VICTORY_CONQUEST'" in sql
    and "RequirementSetId='REQUIREMENTS_LOTM_RESCUE_DISABLE_NATIVE_CONQUEST'" in sql,
    "Rescue Mode must retain VICTORY_CONQUEST only as a disabled presentation template",
)
for runtime_file in (
    "Gameplay/LOTM_RESCUE_Phase10.sql",
    "Scripts/LOTM_RESCUE_Phase10.lua",
    "Art/LOTM_RESCUE_Phase10.dep",
    "Art/LOTM_RESCUE_Phase10_Units.artdef",
    "Art/LOTM_RESCUE_Phase10_Icons.xml",
    "UI/EndGameMenu_LOTM_Redemption.lua",
):
    check(runtime_file in modinfo, f"modinfo misses {runtime_file}")

check('unit:GetProperty(GOD_UNIT_PROPERTY)' in phase10a, "Divine Legion does not exclude true gods")
check('(not RescueActive() or tier~=6)' in churches, "Rescue mode does not replace the three separate tier-6 church quests")
check('replacement=WAR_GOD_RELIC' in churches and 'LOTM_RESCUE_CHURCH_QUEST_VERSION' in churches, "Old active rescue tier-6 quests lack a version-gated migration")
check('LOTM_RESCUE_Phase10A.OnChurchEnvoysChanged(playerID)' in churches, "Three-church envoy milestone is not refreshed immediately")
check('local godType="UNIT_LOTM_RESCUE_GOD_"..church' in unit_flags, "Church gods do not reuse guardian emblems")
check('"UNIT_LOTM_RESCUE_OUTER_GOD_AVATAR","UNIT_LOTM_RESCUE_OUTER_GOD_MINION"' in unit_flags, "Outer God flags do not use the monster mark")
check('local OUTER_GOD_MARK=UI.GetColorValueFromHexLiteral(0xFF1800B8)' in unit_flags, "Outer God mark is not blood red")
check('ApplyOuterGodColor(self.m_Instance)' in unit_flags, "Outer God flag does not apply black/blood-red colors")
emblem = unit_flags.split("function UnitFlag.SetFlagUnitEmblem(self)", 1)[1].split("local function RefreshSpecialFlag", 1)[0]
check(emblem.index("if IsOuterGod(unit) then") < emblem.index("if IsMonster(unit) or IsLostControl(unit) then"), "Outer God emblem branch is shadowed by ordinary monster handling")
check('ICON_LOTM_RESCUE_OUTER_GOD_STAR_MARK' in emblem and 'IsOuterGodAvatar(unit)' in emblem, "Outer God avatar flag lacks the distinguishing star emblem")
check('or "ICON_LOTM_WORLD_MONSTER_MARK"' in emblem, "Outer God minions do not retain the unstarred monster emblem")
check('LOTM_RESCUE_OuterGodStarMark40.dds' in modinfo and 'LOTM_RESCUE_OuterGodStarMark256.dds' in modinfo, "Outer God star flag textures are not shipped")
check('targetUnit:GetProperty("LOTM_RESCUE_PHASE10_IS_GOD")' in arson, "Arson does not inspect the divine immunity marker")
check("not IsGodUnit(targetUnit)" in arson, "Arson does not exclude divine targets")
check("LOTM_PP_Perfect.lua" not in lua and "LOTM_BE_BlackEmperor.lua" not in lua, "Phase 10 rewrites existing Perfect/Black Emperor skill modules")

for snippet in (
    'local NATIVE_REDEMPTION_VICTORY="VICTORY_CONQUEST"',
    'PATH_RED_PRIEST="ICON_UNIT_LOTM_RP_PATH_HOLDER"',
    'PATH_PERFECT="ICON_UNIT_LOTM_PP_PATH_HOLDER"',
    'PATH_BLACK_EMPEROR="ICON_UNIT_LOTM_BE_PATH_HOLDER"',
    'local BASE_LOTM_TeamVictoryData=TeamVictoryData',
    'OnTeamVictory(team,victory.Index,0)',
    'Game.GetProperty("LOTM_RESCUE_PHASE10_VICTORY")',
    'gameCoreChanged=',
):
    check(snippet in end_game, f"Redemption EndGame extension missing: {snippet}")

for tag in (
    "LOC_UNIT_LOTM_RESCUE_GOD_FOOL_NAME",
    "LOC_UNIT_LOTM_RESCUE_PLAYER_GOD_DESCRIPTION",
    "LOC_UNIT_LOTM_RESCUE_OUTER_GOD_AVATAR_DESCRIPTION",
    "LOC_ABILITY_LOTM_RESCUE_P10_DIVINE_POWER_NAME",
    "LOC_ABILITY_LOTM_RESCUE_P10_OUTER_SKILLS_NAME",
    "LOC_BUILDING_LOTM_RESCUE_VICTORY_TOKEN_NAME",
    "LOC_VICTORY_LOTM_RESCUE_NAME",
    "LOC_VICTORY_LOTM_RESCUE_REQUIREMENT",
    "LOC_VICTORY_LOTM_RESCUE_FINAL",
):
    check(tag in zh and tag in en, f"bilingual Phase 10 text misses {tag}")

for xml_file in (
    "Art/LOTM_RESCUE_Phase10_Icons.xml",
    "Text/zh_Hans_CN/LOTM_RP_GameplayText.xml",
    "Text/en_US/LOTM_RP_GameplayText.xml",
):
    try:
        ET.parse(ROOT / xml_file)
    except ET.ParseError as exc:
        check(False, f"invalid XML {xml_file}: {exc}")

if errors:
    print(f"FAILED: {len(errors)} Rescue Phase 10 checks")
    for error in errors:
        print(f" - {error}")
    raise SystemExit(1)

print("PASS: Rescue Phase 10 static contracts (locked tiers, gods, phased Boss, minions, victory, isolation)")
