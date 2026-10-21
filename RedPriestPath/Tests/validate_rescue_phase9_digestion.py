#!/usr/bin/env python3
"""Rescue Phase 9 Red Priest digestion override contracts."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
errors: list[str] = []


def text(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


def check(condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)


digestion = text("Scripts/LOTM_RESCUE_Phase9Digestion.lua")
lifecycle = text("Scripts/LOTM_RP_Lifecycle.lua")
progression = text("Scripts/LOTM_RP_Progression.lua")
arson = text("Scripts/LOTM_RP_Arson.lua")
observer = text("UI/LOTM_BE_EventObserver.lua")
gameplay = text("Scripts/LOTM_RP_Gameplay.lua")
modinfo = text("RedPriestPath.modinfo")
hud = text("UI/LOTM_RP_HUD.lua")
zh = text("Text/zh_Hans_CN/LOTM_RP_GameplayText.xml")
en = text("Text/en_US/LOTM_RP_GameplayText.xml")

check('include("LOTM_RESCUE_Phase9Digestion")' in gameplay, "digestion module missing from shared Gameplay")
check("Scripts/LOTM_RESCUE_Phase9Digestion.lua" in modinfo, "digestion module missing from modinfo")
check("local VERSION=2;" in digestion, "Phase 9 digestion changed-write version must be 2")
check('string.sub(tostring(objectKey), 1, 10) ~= "RESCUE_P9:"' in lifecycle, "legacy rescue digestion is not centrally blocked")
check('"RESCUE_P9:HUNTER_XP:"' in progression, "Sequence 9 XP key missing")
check('"RESCUE_P9:AUX:CHURCH_TURN:"' in progression, "rescue pantheon auxiliary digestion missing")
check('"RESCUE_P9:AUX:TRUE_GOD_CHURCH_TURN:"' in progression, "rescue true-god church auxiliary digestion missing")

for token in (
    "S8_LOST_CONTROL_ATTACK", "S8_STRONGER_ATTACK", "ARSON_DAMAGE", "ARSON_KILL",
    "S6_GOLD_MILITARY", "S6_MILITARY_TRAINED", "S5_KILL", "S5_WOUNDED_KILL",
    "S4_KILL_WITHIN_6", "S4_WORKSHOP_WITHIN_6", "S3_MILITARY_TRAINED",
    "S2_MID_KILL", "S2_HIGH_KILL_A", "S2_HIGH_KILL_B",
    "S1_SECOND_ATTACK", "S1_SECOND_ATTACK_KILL",
):
    check(token in digestion + arson, f"confirmed digestion condition missing: {token}")

check("Map.GetPlotDistance(hero:GetX(),hero:GetY(),x,y)<=6" in digestion, "six-hex check is not inclusive")
check("HeroWithin(attackerPlayerID,attacker:GetX(),attacker:GetY())" in digestion, "kill does not test the attacking friendly unit against the holder")
check("HeroWithin(clearerPlayerID,plot:GetX(),plot:GetY())" in digestion, "workshop clear does not test the workshop plot against the holder")
check("baseWorkshopCleared=LOTM_RESCUE_Phase4.OnWorkshopCleared" in digestion, "existing workshop callback is not reused")

check("m_goldSpendCredits" in observer and "credit.amount" in observer, "Gold-spend pairing was removed")
check("IsRescueRedPriestSequence(6) and candidate.kind == \"UNIT\"" in observer, "rescue Gold military purchase filter missing")
check("RESCUE_GOLD_MILITARY_COMMAND" in observer and "GoldSpent = credit.amount" in observer, "Gold purchase command payload missing")
check("Events.CityProductionCompleted.Add(OnCityProductionCompleted)" in observer, "normal training observer missing")
check("local ORDER_TRAIN :number = 0" in observer and "orderType ~= ORDER_TRAIN" in observer, "normal training is not restricted to Firaxis' UI event value for train orders")
check("OrderTypes.ORDER_TRAIN" not in observer, "UI observer still dereferences the unavailable OrderTypes global")
check("LOTM_RP_State.TryAddDigestion" not in observer, "UI observer must not mutate Gameplay digestion")

check("Events.UnitDamageChanged.Add(OnUnitDamageChanged)" in digestion, "pre-attack wound snapshot event missing")
check('Game.SetProperty(prefix..":OLD",Number(oldDamage,0))' in digestion, "old damage is not snapshotted")
check("woundedBefore" in digestion, "wounded-before-attack condition missing")
check("if count==2 then" in digestion, "second attack must be exact, not second-or-later")
check("numericTier==0" in digestion and digestion.count("S2_HIGH_KILL_") == 2, "high-tier kill must submit exactly two points")
check("baseLostControlKilled=LOTM_RESCUE_Phase6.OnLostControlKilled" in digestion, "roaming monster callback is not reused")
check("LOTM_RESCUE_Phase6.OnLostControlKilled=OnLostControlKilled" in digestion and "LOTM_RESCUE_Phase4.OnLostControlKilled=OnLostControlKilled" in digestion, "roaming and workshop-center monster kills do not share the tier digestion hook")

check('"LOC_LOTM_RESCUE_P9_RP_DIGEST_S" .. tostring(rescueSequence)' in hud, "HUD does not route to rescue digestion text")
for sequence in range(10):
    tag = f"LOC_LOTM_RESCUE_P9_RP_DIGEST_S{sequence}"
    check(tag in zh and tag in en, f"localized rescue digestion text missing for Sequence {sequence}")

check('Game.SetProperty("LOTM_RESCUE_PHASE9_DIGESTION_STATE","READY")' in digestion, "ready state missing")
check('LOTM_MP_TurnSync.RunStartup(function()\n if Active() then\n  Game.SetProperty("LOTM_RESCUE_PHASE9_DIGESTION_VERSION"' in digestion
      and 'end,"RescuePhase9Digestion");' in digestion,
      "ordinary mode would publish rescue digestion state or network load would write it eagerly")
write_observation = digestion.split("local function WriteObservation", 1)[1].split("local function ObserveUnit", 1)[0]
check('if Number(Game.GetProperty(baseKey),nil)~=base then Game.SetProperty(baseKey,base); end' in write_observation, "unit base metadata must write only when missing or changed")
check('if Number(Game.GetProperty(lostKey),nil)~=lost then Game.SetProperty(lostKey,lost); end' in write_observation, "lost-control metadata must write only when missing or changed")
check("metaWrites=changedOnly" in digestion, "changed-only metadata mode must be visible in runtime logs")

unit_added = digestion.split("local function OnUnitAdded", 1)[1].split("local function OnUnitRemoved", 1)[0]
unit_added_network = unit_added.split("if LOTM_MP_TurnSync.IsNetworkGame() then", 1)[1].split("return;", 1)[0]
network_observations = digestion.split("local function ProcessNetworkObservations", 1)[1].split("local function Defeated", 1)[0]
unit_removed = digestion.split("local function OnUnitRemoved", 1)[1].split("GameEvents.LOTM_RESCUE_P9_Command_GoldMilitaryPurchase", 1)[0]
check("QueueNetworkObservation(playerID,unitID);" in unit_added_network
      and all(token not in unit_added_network for token in (
          "Game.SetProperty(", ":SetProperty(", "ChangeAbilityCount(",
          "AttachModifierByID(", "UnitManager.Kill(", "UnitManager.InitUnit(",
      )), "network UnitAdded must only queue a Lua-local observation")
check(all(token in network_observations for token in (
          "LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID)",
          "entry.QueuedTurn<currentTurn", "table.sort(ready,function(a,b)",
          "a.PlayerID~=b.PlayerID", "a.UnitID<b.UnitID",
          "WriteObservation(entry.PlayerID,entry.UnitID",
      )), "network unit observations must cross a turn and settle in stable player/unit order")
check("entry.Cancelled=true;" in unit_removed
      and "pendingNetworkObservationKeys[key]=nil" in unit_removed,
      "removed units must cancel their queued metadata observation")

damage_changed = digestion.split("local function OnUnitDamageChanged", 1)[1].split("local function OnCombat(", 1)[0]
network_damage = damage_changed.split("if LOTM_MP_TurnSync.IsNetworkGame() then", 1)[1].split("return;", 1)[0]
check("contributes no branch input" in network_damage
      and "recentNetworkDamage" not in network_damage
      and all(token not in network_damage for token in (
          "Game.SetProperty(", ":SetProperty(", "ChangeAbilityCount(",
          "AttachModifierByID(", "UnitManager.Kill(", "UnitManager.InitUnit(",
      )), "network UnitDamageChanged must neither mutate state nor capture branch input")
combat = digestion.split("local function OnCombat(", 1)[1].split("local function OnCombatCountAttack", 1)[0]
check('defenderDamageKey..":SYNC_CURRENT"' in combat
      and "defenderDamageBefore=network" in combat
      and "ObserveUnit(attackerPlayerID,attackerUnitID);" in combat
      and "ObserveUnit(defenderPlayerID,defenderUnitID);" in combat
      and "woundedBefore=defenderDamageBefore>0" in combat
      and "recentNetworkDamage" not in combat,
      "synchronized combat must derive pre-fight wounds only from durable synchronized damage")
lost_hook = digestion.split(
    "function LOTM_RESCUE_Phase9Digestion.RecordLostControlIdentity", 1
)[1].split("local function Defeated", 1)[0]
check('META_PREFIX)..":BASE"' in lost_hook
      and 'DAMAGE_PREFIX)..":SYNC_CURRENT"' in lost_hook
      and "WriteObservation(playerID,unitID" in lost_hook,
      "lost-control death hook must preserve synchronized identity before unit cleanup")
turn = digestion.split("local function OnTurn", 1)[1].split("local function OnUnitAdded", 1)[0]
check("ProcessNetworkObservations(playerID);" in turn
      and 'LOTM_MP_TurnSync.Add(OnTurn,"RescuePhase9DigestionRuntime")' in digestion,
      "network observation queue must drain from the ordered synchronized turn")

if errors:
    print(f"FAILED: {len(errors)} Rescue Phase 9 digestion checks")
    for error in errors:
        print(f" - {error}")
    raise SystemExit(1)

print("PASS: Rescue Phase 9 confirmed Red Priest digestion contracts (inclusive six-hex kill/workshop focus)")
