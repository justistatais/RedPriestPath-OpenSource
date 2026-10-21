#!/usr/bin/env python3
"""Focused static and deterministic checks for rc.83 virtual churches."""
from pathlib import Path
# Content contracts use unchanged code; test_rc342_startup_trace tests raw diagnostics.
from generate_startup_trace import strip_trace
from PIL import Image
import re
import sys

ROOT=Path(__file__).resolve().parents[1]
failures=[]; checks=0
def check(name,condition):
 global checks; checks+=1
 if not condition: failures.append(name)
church=strip_trace((ROOT/"Scripts/LOTM_WORLD_Churches.lua").read_text(encoding="utf-8"))
sql=strip_trace((ROOT/"Gameplay/LOTM_WORLD_Churches.sql").read_text(encoding="utf-8"))
ui=strip_trace((ROOT/"UI/LOTM_WORLD_CityStates.lua").read_text(encoding="utf-8"))
panel=strip_trace((ROOT/"UI/LOTM_WORLD_ChurchPanel.lua").read_text(encoding="utf-8"))
markers=strip_trace((ROOT/"UI/LOTM_WORLD_ChurchQuestMarkers.lua").read_text(encoding="utf-8"))
markers_xml=strip_trace((ROOT/"UI/LOTM_WORLD_ChurchQuestMarkers.xml").read_text(encoding="utf-8"))
workshops=strip_trace((ROOT/"Scripts/LOTM_PP_Workshops.lua").read_text(encoding="utf-8"))
monsters=strip_trace((ROOT/"Scripts/LOTM_WORLD_Monsters.lua").read_text(encoding="utf-8"))
modinfo=strip_trace((ROOT/"RedPriestPath.modinfo").read_text(encoding="utf-8"))
texts=strip_trace((ROOT/"Text/zh_Hans_CN/LOTM_WORLD_ChurchesText.xml").read_text(encoding="utf-8"))+strip_trace((ROOT/"Text/en_US/LOTM_WORLD_ChurchesText.xml").read_text(encoding="utf-8"))
icons=strip_trace((ROOT/"Art/LOTM_Church_Icons.xml").read_text(encoding="utf-8"))

check("01 fixed churches", 'local ORDER={"FOOL","NIGHT","STORM"}' in church and "MAPSIZE_" not in church)
check("02 virtual not minor", "PlayerManager.GetAliveMinors" not in church and "InitUnit" not in church and "CityManager" not in church)
check("03 envoy API", "ChangeTokensToGive(-total)" in church and "GetTokensToGive()" in church and "EXECUTE_SCRIPT" in ui)
check("04 no suzerain", "BonusImageSuzerainOff:SetHide(true)" in ui and "SuzerainLabel:SetHide(true)" in ui)
check("05 permanent thresholds", "PermanentBand" in church and all(f"PERM_{n}_" in sql for n in (1,3,6)))
check("06 oracle thresholds", "local QUEST_TIERS={6,10,15}" in church and "for _,tier in ipairs(QUEST_TIERS)" in church)
check("07 target levels", "local TARGET_LEVEL={[6]=2,[10]=1,[15]=0}" in church)
check("08 five turn retry", "CurrentPlayerTurn(p)+5" in church)
check("09 nearest city bands", all(x in church for x in ("NearestCityDistance","distance<=20","distance<=30")))
check("10 identities", 'Kind="WORKSHOP",Id=index' in church and 'Kind="MONSTER",Id=serial' in church)
check("11 serial queue", "ACTIVE_TIER" in church and "AdvanceQuestQueue" in church)
check("12 reward odds", "local ARTIFACT_CHANCE={[6]=30,[10]=35,[15]=40}" in church)
check("13 self assist", all(x in church for x in ("COMPLETED_SELF","COMPLETED_ASSIST","ApplyBlessing(p,church,tier,\"HALF\")")))
check("14 durations", "local DURATION={[6]=10,[10]=12,[15]=15}" in church)
check("14b duration begins on the settled current player turn", all(x in church for x in ('LOTM_WORLD_PLAYER_TURN_SETTLED_GAME_TURN','durationBase=durationBase+1','durationBase+DURATION[tier]')))
check("15 monster resolver", "RegisterQuestResolver(LOTM_WORLD_Churches.ResolveMonsterQuest)" in church and "result==true" in monsters)
check("16 workshop resolver", "LOTM_WORLD_Churches.OnWorkshopResolved" in workshops)
check("17 boosts deterministic", "LOTM_WORLD_State.Random" in church and "math.random" not in church)
check("17b gameplay boost API and protected side effects", "CanTriggerBoost(" not in church and "pcall(function() techs:TriggerBoost" in church and "pcall(function() culture:TriggerBoost" in church)
check("18 no wonder reward", "NaturalWonder" not in church and "100金币" not in texts)
check("19 effect states", len(set(re.findall(r"LOTM_CHURCH_(?:FOOL|NIGHT|STORM)_(?:PERM|BLESS)_[A-Z0-9_]+_ON",sql)))>=27)
check("20 combat preview", "ModifierStrings" in sql and all(x in texts for x in ("FOOL_COMBAT_PREVIEW","NIGHT_COMBAT_PREVIEW","STORM_COMBAT_PREVIEW")))
check("night ability description has no missing preview argument", "LOC_LOTM_CHURCH_NIGHT_HOME_ABILITY_DESCRIPTION" in sql and "黑夜庇护：在己方领土内获得战斗力加成。" in texts and "'LOC_LOTM_CHURCH_NIGHT_NAME','LOC_LOTM_CHURCH_NIGHT_COMBAT_PREVIEW',1" not in sql)
check("21 UI detail", all(x in panel for x in ("QUEST_6_STATE","QUEST_10_STATE","QUEST_15_STATE","BLESSING_REMAINING")) or "BLESSING_UNTIL" in panel)
check("22 colors", all(x in sql for x in ("COLOR_LOTM_CHURCH_FOOL","COLOR_LOTM_CHURCH_NIGHT","COLOR_LOTM_CHURCH_STORM")))
check("23 mod registration", all(x in modinfo for x in ("Gameplay/LOTM_WORLD_Churches.sql","Scripts/LOTM_WORLD_Churches.lua","UI/LOTM_WORLD_CityStates.lua","LOTM_WORLD_VIRTUAL_CHURCH_CITY_STATES")))
check("24 legal resolver avoids unavailable IsMinor API", "p:IsMinor()" not in workshops and "CIVILIZATION_LEVEL_CITY_STATE" in workshops)
check("25 night enemy penalties are territorial, wartime and immediately reversible", all(x in church for x in ("NightEnemyPenaltyForTerritory","IsAtWarWith(unitOwnerID)","RefreshNightEnemyPenalty","GameEvents.OnUnitMoved.Add","Events.DiplomacyDeclareWar.Add(OnDiplomacyChanged)","Events.DiplomacyMakePeace.Add(OnDiplomacyChanged)","RefreshAllNightEnemyPenalties();")) and all(x in sql for x in ("NIGHT_ENEMY_COMBAT_5","NIGHT_ENEMY_COMBAT_10","NIGHT_ENEMY_COMBAT_20","NIGHT_ENEMY_MOVE_1","NIGHT_ENEMY_MOVE_2")))
check("25b night home combat uses Firaxis unit ability plot context", all(x in church for x in ("NIGHT_HOME_ABILITIES","RefreshNightHomeCombatForUnit",'Events.UnitAddedToMap.Add(LOTM_UnitAddedPerf.Wrap("Churches",OnUnitAdded))')) and all(x in sql for x in ("ABILITY_LOTM_CHURCH_NIGHT_HOME_PERM_5","LOTM_CHURCH_NIGHT_HOME_PERM_5_MOD","MODIFIER_UNIT_ADJUST_COMBAT_STRENGTH","LOTM_CHURCH_REQSET_OWN_TERRITORY_COMBAT")) and "('LOTM_CHURCH_NIGHT_PERM_3_ON__027','Amount','0')" in sql)
check("25c fool recon includes custom pathway holders", all(x in sql for x in ("'LOTM_CHURCH_REQ_SCOUT','REQUIREMENT_UNIT_TAG_MATCHES',0", "'LOTM_CHURCH_REQ_SCOUT','Tag','CLASS_RECON'")) and "'LOTM_CHURCH_REQ_SCOUT','UnitPromotionClass','PROMOTION_CLASS_RECON'" not in sql)
check("25d fool sight uses synchronized unit abilities without cloning the War Aura source identity", all(x in church for x in ("FOOL_ALL_SIGHT_ABILITIES","FOOL_RECON_SIGHT_ABILITY","FoolSightAmounts","RefreshFoolSightForUnit","RefreshFoolSight(p)","fool sight player=")) and all(x in sql for x in ("ABILITY_LOTM_CHURCH_FOOL_ALL_SIGHT_1","ABILITY_LOTM_CHURCH_FOOL_ALL_SIGHT_5","ABILITY_LOTM_CHURCH_FOOL_RECON_SIGHT_1","LOTM_CHURCH_FOOL_RECON_SIGHT_1_MOD","SELECT DISTINCT tt.Tag","JOIN Units u ON u.UnitType=tt.Type","WHERE tt.Tag<>'CLASS_LOTM_RP_WAR_AURA_SOURCE_V2'")) and "('LOTM_CHURCH_FOOL_PERM_1_ON__004','Amount','0')" in sql)
check("25e night city defense enumerates player cities", all(x in sql for x in ("MODIFIER_LOTM_CHURCH_PLAYER_CITIES_ADJUST_INNER_DEFENSE","'COLLECTION_PLAYER_CITIES','EFFECT_ADJUST_CITY_INNER_DEFENSE'")) and "'MODIFIER_PLAYER_CITIES_ADJUST_INNER_DEFENSE'" not in sql)
storm6_rows=re.findall(r"\('LOTM_CHURCH_STORM_PERM_6_ON__\d+','([^']+)',(?:'([^']+)'|NULL),1\)",sql)
storm6_requirements={row[1] for row in storm6_rows if row[1]}
check("25f storm permanent 6 preserves permanent 3 harbor and sea-resource effects", len(storm6_rows)==22 and all(x in storm6_requirements for x in ("DISTRICT_IS_HARBOR","LOTM_CHURCH_REQSET_IMPROVED_SEA_BONUS","LOTM_CHURCH_REQSET_IMPROVED_SEA_LUXURY","LOTM_CHURCH_REQSET_IMPROVED_SEA_STRATEGIC","LOTM_CHURCH_REQSET_CITY_HAS_HARBOR")))
check("26 oracle reveal releases live sight", "ChangeVisibilityCount(candidate:GetIndex(),1); visibility:ChangeVisibilityCount(candidate:GetIndex(),-1)" in church)
check("27 naval production covers classes and real eras", "NO_ERA" not in sql and all(x in sql for x in ("PROMOTION_CLASS_NAVAL_MELEE","PROMOTION_CLASS_NAVAL_RANGED","PROMOTION_CLASS_NAVAL_RAIDER","PROMOTION_CLASS_NAVAL_CARRIER","ERA_ANCIENT","ERA_FUTURE")))
check("28 confirmation keeps church total through Firaxis accounting", ui.index("BASE_OnConfirmPlacement();") < ui.index("m_Changes={FOOL=0,NIGHT=0,STORM=0};", ui.index("function OnConfirmPlacement")) and "LOTM_CHURCH_ENVOY_CHANGE_SERIAL" in ui and "m_PendingChurchPublishSerial" in ui)
check("29 church row and panel use proven atlas textures safely", 'SetChurchIcon(instance.Icon,church.Icon,32)' in ui and 'SafeSetIcon(Controls.ChurchIcon,d.Icon,32)' in panel and 'sheet==nil or sheet==""' in ui and ":SetIcon(" not in panel)
check("30 no-target uses five-turn retry and migrates old camp fallback", all(x in church for x in ('SetQuestState(p,church,tier,STATE.PENDING)','CurrentPlayerTurn(p)+5','if kind=="BARB_CAMP_COUNT" then return false; end','function LOTM_WORLD_Churches.OnBarbarianCampResolved','return false;')) and 'target="BARB_CAMP_COUNT' not in church and "OnBarbarianCampResolved" in workshops)
check("31 Firaxis-style quest hover", all(x in ui for x in ('instance.QuestIcon:SetToolTipString(questTooltip)','instance.Button:SetToolTipString(questTooltip)','instance.NameButton:SetToolTipString(questTooltip)','LOC_CITY_STATES_QUESTS','[ICON_CityStateQuest]')) and all(x in texts for x in ('LOC_LOTM_CHURCH_ORACLE_TITLE','LOC_LOTM_CHURCH_ORACLE_REWARD','LOC_LOTM_CHURCH_ORACLE_STATES')))
check("32 localized quest states", all(f"LOC_LOTM_CHURCH_STATE_{state}" in texts for state in ("LOCKED","PENDING_TARGET","ACTIVE","COMPLETED_SELF","COMPLETED_ASSIST")) and "LocalizedQuestState" in ui and "LocalizedQuestState" in panel)
check("33 current target location and camera", "LOTM_WORLD_MONSTER:" in ui and "UnitManager.GetUnit" in ui and "UI.LookAtPlot" in ui and "LOC_LOTM_CHURCH_COORDINATES" in texts and "ID=\"Locate\"" in strip_trace((ROOT/"UI/LOTM_WORLD_ChurchPanel.xml").read_text(encoding="utf-8")))
check("34 persistent world marker UI", all(x in markers for x in ("InstanceManager:new","SetWorldPositionVal","UI.GridToWorld","UI.LookAtPlot","GameCoreEventPublishComplete","UnitManager.GetUnit")) and '<Context Layer="WorldAnchor">' in markers_xml and "LOTM_WORLD_CHURCH_MARKERS_UI_ADDIN" in modinfo)
check("35 reward ledger, recovery and immediate target cleanup", all(x in church for x in ("REWARD_SERIAL","REWARD_ARTIFACT","REWARD_STRENGTH","NOTIFICATION_DELIVERED","ReconcileCompletedRewards","FinalizeResolved","ClearActive(p,church)")) and church.index("ClearActive(p,church);",church.index("local function FinalizeResolved")) < church.index("RewardSelf",church.index("local function FinalizeResolved")))
check("36 distinct church reward notifications", all(f"NotificationTypes.USER_DEFINED_{n}" in church for n in (1,2,3)) and all(f'ICON_NOTIFICATION_USER_DEFINED_{n}' in icons for n in (1,2,3)) and all(x in texts for x in ("REWARD_NOTIFICATION_MESSAGE","REWARD_STATUS_ARTIFACT","REWARD_STATUS_BLESSING")))
check("37 published detail cleanup with acknowledged envoy-only list rebuild", all(x in ui for x in ("OnGameCoreEventPublishComplete","if m_PendingChurchPublishSerial==nil then return; end","if published<=m_PendingChurchPublishSerial then return; end","Events.GameCoreEventPublishComplete.Add")) and "Events.GameCoreEventPublishComplete.Add" in panel and "Events.GameCoreEventPublishComplete.Add" in markers and "tier<=0" in panel)
check("38 Firaxis-style stable envoy controls", all(x in ui for x in ("m_ChurchInstances","RealizeEnvoyChangeButtons(); RealizeListHeader();","Controls.CityStateScroll:CalculateSize()","Controls.ConfirmButton:SetDisabled(not m_isLocalPlayerTurn or SumEnvoyChanges()==0)")) and "m_Changes[churchType]=m_Changes[churchType]+1; Refresh();" not in ui)
check("39 healing skips units without a synchronized map plot", all(x in church for x in ('plot=Map.GetPlot(unit:GetX(),unit:GetY())','plot~=nil and plot:GetOwner()==p:GetID()','reason=PLOT_MISSING')) and 'Map.GetPlot(unit:GetX(),unit:GetY()):GetOwner()' not in church)
check("40 three churches remain while defeated real city-state placeholders are removed", all(x in ui for x in ('local BASE_AddCityStateRow=AddCityStateRow','local function GetLivingCityStatesMetNum()','cityState:IsAlive()','influence:CanReceiveInfluence()','return GetLivingCityStatesMetNum()+#CHURCHES','not cityState.isAlive','instance.CityStateBase:SetHide(true)')) and 'BASE_GetCityStatesMetNum' not in ui)
for church_type in ("FOOL","NIGHT","STORM"):
 for size in (22,26,32,36,40,56,64,128,200,256):
  data=(ROOT/f"Art/LOTM_Church_{church_type}_{size}.dds").read_bytes()
  check(f"24 dxt5 {church_type} {size}",data[:4]==b"DDS " and data[84:88]==b"DXT5")
 manual_icon=Image.open(ROOT/f"Art/LOTM_Church_{church_type}_200.dds").convert("RGBA")
 alpha=manual_icon.getchannel("A")
 check(f"24b transparent manual icon {church_type}",alpha.getbbox() is not None and all(alpha.getpixel(point)<=8 for point in ((0,0),(199,0),(0,199),(199,199))) and alpha.getextrema()[1]>=200)
banner_center=Image.open(ROOT/"Art/LOTM_RESCUE_AstralDescent_22.dds").convert("RGBA")
check("24c Astral Descent banner icon",banner_center.size==(22,22) and banner_center.getchannel("A").getbbox() is not None)

# Small deterministic model for the irreversible threshold ledger and queue order.
def crossed(old,new): return [n for n in (6,10,15) if old<n<=new]
check("39 crossing order",crossed(5,15)==[6,10,15])
states={6:"LOCKED",10:"LOCKED",15:"LOCKED"}; active=None
for tier in crossed(5,15):
 if active is None: active=tier; states[tier]="ACTIVE"
check("40 one active",active==6 and states[10]=="LOCKED" and states[15]=="LOCKED")

if failures:
 print(f"FAILED: {len(failures)} of {checks} rc.83 checks failed")
 for failure in failures: print(" -",failure)
 sys.exit(1)
print(f"PASS: {checks} rc.83 static/stub checks")
