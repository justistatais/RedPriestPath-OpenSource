#!/usr/bin/env python3
"""Focused contract checks for AI cult V1 (static, not in-game evidence)."""
from pathlib import Path
# Content contracts use unchanged code; test_rc342_startup_trace tests raw diagnostics.
from generate_startup_trace import strip_trace
import re, sys

ROOT=Path(__file__).resolve().parents[1]
core=strip_trace((ROOT/"Scripts/LOTM_AI_Cults.lua").read_text(encoding="utf-8"))
hanged=strip_trace((ROOT/"Scripts/LOTM_AI_Cult_Hanged.lua").read_text(encoding="utf-8"))
sql=strip_trace((ROOT/"Gameplay/LOTM_AI_Cults.sql").read_text(encoding="utf-8"))
flag=strip_trace((ROOT/"UI/LOTM_PP_UnitFlagManager.lua").read_text(encoding="utf-8"))
diplo=strip_trace((ROOT/"UI/LOTM_AI_Cult_Diplomacy.lua").read_text(encoding="utf-8"))
diplo_extension=strip_trace((ROOT/"UI/LOTM_AI_Cult_Diplomacy_Extension.lua").read_text(encoding="utf-8"))
diplo_qd=strip_trace((ROOT/"UI/LOTM_AI_Cult_Diplomacy_QuickDeals.lua").read_text(encoding="utf-8"))
row=strip_trace((ROOT/"UI/LOTM_AI_Cult_DiplomacyRow.lua").read_text(encoding="utf-8"))
gameplay=strip_trace((ROOT/"Scripts/LOTM_RP_Gameplay.lua").read_text(encoding="utf-8"))
texts=strip_trace((ROOT/"Text/zh_Hans_CN/LOTM_AI_CultsText.xml").read_text(encoding="utf-8"))
icons=strip_trace((ROOT/"Art/LOTM_AI_Cult_Icons.xml").read_text(encoding="utf-8"))

checks=[]
def check(ok,msg): checks.append((bool(ok),msg))

check('local CULTS={"DEMONESS","HANGED_MAN","CHAINED"}' in core,"exactly three cult paths")
check("local STATE_VERSION=4;" in core,"zero-strength notification migration uses AI cult state version 4")
check("TIER4" not in core+sql+row+texts and "TIER_4" not in core+sql+row+texts,"no tier-four token")
check("return 3 end -- Sequence 2..0 is tier 3" in core,"sequence 0 maps to target tier 3")
check(all(key in core for key in ("LOTM_CULT_DEMONESS_TIER","LOTM_CULT_HANGED_MAN_TIER","LOTM_CULT_CHAINED_TIER")),"independent shared tier keys")
check("math.max(oldTier,DesiredTier(historical))" in core,"tiers only increase")
check("maxTech>=14" in core and "maxTech>=5" in core,"5/14 thresholds")
check("if PlayerCult(player)==cult then highest=math.max" in core,"each cult uses only its own AI maximum")
check(all(token in core for token in ("return 1","return 0.2","return 0","return 2","return 3")),"five fixed multipliers")
check(all(token in sql for token in ("DEMONESS_V2_T1_M1","MODIFIER_PLAYER_DISTRICTS_ADJUST_YIELD_CHANGE","LOTM_CULT_REQSET_CITY_CENTER","YIELD_FOOD','Amount','-1'","YIELD_PRODUCTION','Amount','-1'","YIELD_SCIENCE','Amount','-1'","YIELD_CULTURE','Amount','-1'")),"Demoness I uses City Center fixed Food/Production plus proven city Science/Culture")
check(all(token in sql for token in ("DEMONESS_T2_P20","YIELD_FOOD','Amount','-20'","YIELD_PRODUCTION','Amount','-20'")),"Demoness II exact percentages")
check(all(token in sql for token in ("DEMONESS_T3_A5_P50","Amount','-5'","YIELD_FOOD','Amount','-50'","YIELD_PRODUCTION','Amount','-50'")),"Demoness III exact effects")
check("if tier==1" in core and "if tier==2" in core and "DEMONESS_T3" in core,"Demoness stages select one exclusive token")
check('PlayerCult(player)~="DEMONESS"' in core,"Demoness score-leader self immunity")
check('ApplySwitch(player,"DEMONESS",demonDesired)' in core,"one Demoness switch per target")
check("HANGED_T1_C5" in sql and "ScaledInt(5" in core,"Hanged I combat and faith base 5")
check("tier==2 and 1 or 0" in hanged and "bonus=10/20" in hanged,"Hanged II only puppet +10 path")
check(all(token in core+hanged+sql for token in ("HANGED_T3_C20","base=tier==2 and 10 or 20","ABILITY_LOTM_CULT_FLESH_PUPPET_20")),"Hanged III war 20 and puppet 20")
check('RetireLegacySwitch(player,"HANGED_WAR")' in core,"legacy permanent Hanged combat switch is silently retired")
check("AtWarWithCult(player,\"HANGED_MAN\")" in core,"any living Hanged enemy maintains war state")
check('hangedDesired=nil' in core,"Hanged peace/tier II clears old war switch")
check("CHAINED_MOVE_T1_M1" in sql,"Chained I only movement base 1")
check(all(token in sql for token in ("CHAINED_MOVE_T2_M1","ABILITY_LOTM_CULT_CHAINED_WAR_C10","CHAINED_BORDER_P50")),"Chained II movement/combat/border")
check(all(token in sql for token in ("CHAINED_YIELD_T3_P50","YIELD_SCIENCE','Amount','-50'","YIELD_CULTURE','Amount','-50'")),"Chained III science/culture only")
check("ChainedMoveToken" in core and "ChainedYieldToken" in core and "ChainedCombatAmount" in core,"Chained stages use independently removable effects")
check('PlayerCult(player)~="CHAINED"' in core,"Chained score-leader self immunity")
check("LOTM_CULT_APPLIED_" in core and "_OFF__" in core and "_ON__" in core,"reversible one-slot modifier ledger")
check("math.min(100,ScaledInt" in core,"negative percentage magnitude capped at 100")
check("math.floor(base*LOTM_AI_Cults.GetMultiplier" in core,"integer scaling truncates toward zero")
required_effect_tokens={
 "DEMONESS_V2_T1_M1","DEMONESS_T2_P4","DEMONESS_T2_P20","DEMONESS_T2_P40",
 "DEMONESS_T3_A5_P50","DEMONESS_T3_A10_P100","DEMONESS_T3_A15_P100",
 "HANGED_FAITH_T1_F1","HANGED_FAITH_T1_F5","HANGED_FAITH_T3_F20",
 "HANGED_FAITH_T3_F40","HANGED_FAITH_T3_F60",
 "CHAINED_MOVE_T1_M1","CHAINED_MOVE_T2_M1","CHAINED_MOVE_T2_M2",
 "CHAINED_YIELD_T3_P50","CHAINED_YIELD_T3_P100",
 "CHAINED_BORDER_P10","CHAINED_BORDER_P50","CHAINED_BORDER_P100",
}
check(all(("'"+token+"'") in sql for token in required_effect_tokens),"every token reachable from the five target-tier multipliers has SQL backing")
check("ABILITY_LOTM_CULT_FLESH_PUPPET_10" in sql and "Amount',10" in sql,"puppet +10 is fixed unit ability")
check("ABILITY_LOTM_CULT_FLESH_PUPPET_20" in sql and "Amount',20" in sql,"puppet +20 is fixed unit ability")
check("GetMultiplier(tier,targetTier)" in hanged,"puppet attack faith is target-tier scaled")
check("HasFormalPath(player)" in core and "LOTM_RP_State.IsAnyPathPlayer(player:GetID())" in core,"war debuffs reuse authoritative formal-path state API")
check('path=="RP"' not in core and 'path=="PP"' not in core and 'path=="BE"' not in core,"obsolete shorthand path literals cannot block war effects")
check(all(token in core for token in ("Events.DiplomacyDeclareWar.Add(OnDiplomacyChanged)","Events.DiplomacyMakePeace.Add(OnDiplomacyChanged)",'LOTM_MP_TurnSync.Add(OnTurn,"AICults")',"LOTM_AI_Cults.Reconcile()")),"war effects use immediate single-player diplomacy events and the synchronized multiplayer turn fallback")

research_event=core.split("local function OnResearchCompleted",1)[1].split("local function OnDiplomacyChanged",1)[0]
diplomacy_event=core.split("local function OnDiplomacyChanged",1)[1].split("local function OnUnitAddedToMap",1)[0]
unit_event=core.split("local function OnUnitAddedToMap",1)[1].split('LOTM_MP_TurnSync.Add(OnTurn,"AICults")',1)[0]
for body,label in (
 (research_event,"research"),
 (diplomacy_event,"diplomacy"),
 (unit_event,"UnitAdded"),
):
 network_prefix=body.split("if LOTM_MP_TurnSync.IsNetworkGame() then",1)[1].split("return;",1)[0]
 check(all(token not in network_prefix for token in (
  "SetProperty(","AttachModifierByID(","ChangeAbilityCount(",
  "UnitManager.Kill(","UnitManager.InitUnit(","Reconcile(",
 )),f"AI cult {label} publication must return before network state mutation")
turn_event=core.split("local function OnTurn",1)[1].split("local function OnResearchCompleted",1)[0]
check("LOTM_AI_Cults.Reconcile();" in turn_event
      and 'LOTM_MP_TurnSync.RunStartup(LOTM_AI_Cults.Reconcile,"AICults")' in core,
      "AI cult network reconciliation must run from synchronized turn/startup ownership")

hanged_initialized=hanged.split("local function TryMarkNewUnit",1)[1].split("function LOTM_AI_Cult_Hanged.ReconcileAll",1)[0]
hanged_network=hanged_initialized.split("if LOTM_MP_TurnSync.IsNetworkGame() then",1)[1].split("return;",1)[0]
hanged_capture=hanged.split("local function QueueNetworkUnitInitialized",1)[1].split("local function ProcessNetworkUnitInitializations",1)[0]
hanged_processor=hanged.split("local function ProcessNetworkUnitInitializations",1)[1].split("local function TryMarkNewUnit",1)[0]
hanged_removed=hanged.split("local function OnUnitRemoved",1)[1].split("local function SettleAttackFaith",1)[0]
check("QueueNetworkUnitInitialized(playerID,unitID);" in hanged_network
      and all(token not in hanged_network+hanged_capture for token in (
          "SetProperty(","AttachModifierByID(","ChangeAbilityCount(",
          "UnitManager.Kill(","UnitManager.InitUnit(","SetVeteranName(",
      )),"Hanged UnitInitialized must capture event-time facts without network writes")
check(all(token in hanged_processor for token in (
          "LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID)",
          "entry.QueuedTurn<currentTurn","table.sort(ready,function(a,b)",
          "a.PlayerID~=b.PlayerID","a.UnitID<b.UnitID","ApplyCapturedNewUnit(entry)",
      )),"Hanged network units must cross a full turn and settle in stable player/unit order")
check("entry.Cancelled=true;" in hanged_removed
      and "pendingNetworkUnitKeys[key]=nil" in hanged_removed
      and "ProcessNetworkUnitInitializations(playerID);" in hanged.split("local function OnTurn",1)[1].split("local function OnUnitRemoved",1)[0],
      "Hanged removal/turn handlers must cancel and drain the local queue")
check("for _,player in ipairs(AliveMajors())" in hanged
      and hanged.count("for _,unit in ipairs(SortedUnits(player))") == 2
      and "table.sort(result,function(a,b) return a:GetID()<b:GetID(); end)" in hanged,
      "Hanged reconcile and rescue retirement must sort players and units")
check("与他人交战时，另一方军事单位-5战斗力且每回合-5信仰。" in texts,"Hanged I Chinese description matches requested wording")
check("SetProperty" not in row and "AttachModifier" not in row and "ChangeFaith" not in row,"diplomacy UI is read-only")
check("Game.GetLocalPlayer" not in core+hanged,"Gameplay never uses local player")
check("math.random" not in core+hanged and "Game.GetRandNum" not in core,"core uses shared synchronized random wrapper")
check("CULT_GUARANTEE_ROTATION" in core and "#ai>=3" in core,"three-path guarantee for at least three AI")
check("player:IsHuman() or not IsCult" in core,"human players cannot receive a cult")
check(all(token in sql for token in ("HANGED_FAITH_T1_F5","HANGED_FAITH_T3_F20","MODIFIER_PLAYER_ADJUST_YIELD_CHANGE","'YIELD_FAITH'")),"Hanged Faith uses native reversible per-turn yield modifiers")
check('ApplySwitch(player,"HANGED_FAITH",hangedFaithDesired)' in core and "LOTM_CULT_HANGED_FAITH_PER_TURN" in core,"Hanged Faith has an independent old-save-safe switch and synchronized UI value")
check("ChangeFaithBalance" not in core and "SettleHangedFaith" not in core,"legacy direct Faith settlement cannot double-charge native yield")
check("DELETE FROM ModifierStrings" in sql and "LOTM_CULT_HANGED_T%_ON__%" in sql and "LOTM_CULT_CHAINED_T%_ON__%" in sql,"legacy permanent combat preview strings are removed")
check(all(token in sql for token in ("ABILITY_LOTM_CULT_HANGED_WAR_C1","ABILITY_LOTM_CULT_HANGED_WAR_C5","ABILITY_LOTM_CULT_HANGED_WAR_C20","ABILITY_LOTM_CULT_HANGED_WAR_C40","ABILITY_LOTM_CULT_HANGED_WAR_C60","ABILITY_LOTM_CULT_CHAINED_WAR_C2","ABILITY_LOTM_CULT_CHAINED_WAR_C10","ABILITY_LOTM_CULT_CHAINED_WAR_C20")),"all scaled war combat values have removable unit abilities")
check("ChangeAbilityCount" in core and "RefreshWarCombatAbilities" in core,"war combat abilities are added and removed synchronously")
check('RetireLegacySwitch(player,"CHAINED_WAR")' in core,"legacy permanent Chained combat switch is silently retired")
check('RefreshWarNotification(player,"HANGED_WAR",hangedDesired)' in core and 'RefreshWarNotification(player,"CHAINED_WAR",chainedWarDesired)' in core,"war notifications follow removable live effects")
check('chainedMove~=nil or chainedCombatAmount>0 or chainedYield~=nil' in core and 'chainedWar and ("CHAINED_T"' not in core,"Chained war notification cannot activate from war alone when every scaled effect is zero")
check("LOTM_CULT_EFFECT_AUDIT" in core and "effect audit player=" in core,"state-change audit records target tier and live war-effect channels")
hud=strip_trace((ROOT/"UI/LOTM_RP_HUD.lua").read_text(encoding="utf-8"))
city_panel=strip_trace((ROOT/"UI/LOTM_AI_Cult_CityPanel.lua").read_text(encoding="utf-8"))
check(all(token in texts+hud for token in ("LOC_LOTM_CULT_HANGED_FAITH_TOOLTIP","LOC_LOTM_CULT_CHAINED_TOP_YIELD_TOOLTIP","faithLines","chainedToken")),"player-wide cult yields have named top-panel accounting")
check("DEMONESS_T1_M" not in hud and "LOC_LOTM_CULT_DEMONESS_TOP_YIELD_TOOLTIP" not in hud,"Demoness is not falsely aggregated in the top panel")
check("DEMONESS_V2_T1_M" in core+sql+city_panel and "REQUIRES_DISTRICT_IS_CITY_CENTER" in sql,"Demoness V2 forces old-save migration and one fixed Food/Production adjustment per city")
check(all(token in city_panel+texts for token in ("include(\"CityPanel_Expansion2\")","LOTM_BASE_ViewMain","LOTM_CULT_APPLIED_DEMONESS","FoodPerTurnToolTip","ProductionPerTurnToolTip","SciencePerTurnToolTip","CulturePerTurnToolTip","LOC_LOTM_CULT_DEMONESS_CITY_FLAT_TOOLTIP","LOC_LOTM_CULT_DEMONESS_CITY_PERCENT_TOOLTIP")),"Demoness effects are named in each affected city yield tooltip")
check("NotificationManager.SendNotification" in core and "LOC_LOTM_CULT_NOTIFICATION_APPLIED" in texts,"human victims receive named cult notifications")
check("GetHighestScoreMajorCivilization" in core and "score==best" in core,"deterministic score leader and PlayerID tie break")
check("ResolveMeleeBaseline" in hanged and "unit:GetType()~=baseline.Index" in hanged,"puppet uses current canonical melee baseline")
check("SetVeteranName" in hanged and "LOC_UNIT_LOTM_CULT_FLESH_PUPPET_NAME" in texts,"puppet has independent displayed name")
check("UNIT_LOTM_CULT_FLESH_PUPPET" in sql and "Civilopedia entry" in strip_trace((ROOT/"Text/en_US/LOTM_AI_CultsText.xml").read_text(encoding="utf-8")),"puppet has an informational Civilopedia entry")
check("ICON_LOTM_CULT_FLESH_PUPPET" in flag+icons,"puppet emblem is registered and applied")
check('if IsFleshPuppet(unit) then\n  self.m_Instance.UnitIcon:SetIcon("ICON_LOTM_CULT_FLESH_PUPPET"); return;' in flag
      and "Flesh Puppets deliberately retain" in flag,"puppet changes emblem while retaining civilization colors")
check("DiplomacyActionView_Expansion2.lua" in diplo and "AddOverviewRow" in diplo_extension,"diplomacy row extends Firaxis Expansion 2 overview")
check("diplomacyactionview_qd.lua" in diplo_qd and "LOTM_AI_Cult_Diplomacy_Extension.lua" in diplo_qd,"Quick Deals base is retained before appending the cult row")
check("diplomacy:HasMet" in row,"diplomacy row does not reveal unmet AI")
check(all(name in gameplay for name in ("LOTM_AI_Cults","LOTM_AI_Cult_Hanged")),"modules loaded by authoritative Gameplay context")

failed=[msg for ok,msg in checks if not ok]
if failed:
 print(f"FAILED: {len(failed)} of {len(checks)} AI cult checks failed")
 for msg in failed: print(" -",msg)
 sys.exit(1)
print(f"PASS: {len(checks)} AI cult static contract checks")
