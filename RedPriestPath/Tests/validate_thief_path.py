#!/usr/bin/env python3
"""Focused static gate for the normal-mode Thief pathway."""

from pathlib import Path
# Content contracts use unchanged code; test_rc342_startup_trace tests raw diagnostics.
from generate_startup_trace import strip_trace
import re
import xml.etree.ElementTree as ET
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
errors: list[str] = []


def check(value: bool, message: str) -> None:
    if not value:
        errors.append(message)


mod = ET.parse(ROOT / "RedPriestPath.modinfo").getroot()
normal = mod.find("./ActionCriteria/Criteria[@id='LOTM_RP_NORMAL_MODE']")
check(normal is not None, "normal-mode criterion missing")
if normal is not None:
    check(normal.findtext("./ConfigurationValueMatches/ConfigurationId") == "GAMEMODE_LOTM_RESCUE", "normal criterion must key off rescue mode")
    check(normal.findtext("./ConfigurationValueMatches/Value") == "0", "normal criterion must require rescue=0")
for action_id in ("LOTM_TP_GAMEPLAY_DATABASE", "LOTM_TP_ICONS", "LOTM_TP_ART_FILES", "LOTM_TP_CONTROL_PANEL_UI_ADDIN", "LOTM_TP_CITY_ACTION_UI_ADDIN"):
    action = mod.find(f"./InGameActions/*[@id='{action_id}']")
    check(action is not None and action.get("criteria") == "LOTM_RP_NORMAL_MODE", f"{action_id} lacks normal-mode isolation")

gameplay = strip_trace((ROOT / "Scripts" / "LOTM_TP_Thief.lua").read_text(encoding="utf-8"))
lifecycle = strip_trace((ROOT / "Scripts" / "LOTM_RP_Lifecycle.lua").read_text(encoding="utf-8"))
panel = strip_trace((ROOT / "UI" / "LOTM_TP_ControlPanel.lua").read_text(encoding="utf-8"))
shared_hud = strip_trace((ROOT / "UI" / "LOTM_RP_HUD.lua").read_text(encoding="utf-8"))
shared_hud_xml = strip_trace((ROOT / "UI" / "LOTM_RP_HUD.xml").read_text(encoding="utf-8"))
deal_view = strip_trace((ROOT / "UI" / "DiplomacyDealView_LOTM_TP.lua").read_text(encoding="utf-8"))
quick_deals_view = strip_trace((ROOT / "UI" / "LOTM_AI_Cult_Diplomacy_QuickDeals.lua").read_text(encoding="utf-8"))
launch = strip_trace((ROOT / "UI" / "LOTM_RP_LaunchButton.lua").read_text(encoding="utf-8"))
city = strip_trace((ROOT / "UI" / "LOTM_TP_CityAction.lua").read_text(encoding="utf-8"))
city_panel = strip_trace((ROOT / "UI" / "LOTM_AI_Cult_CityPanel.lua").read_text(encoding="utf-8"))
sql = strip_trace((ROOT / "Gameplay" / "LOTM_TP_Thief.sql").read_text(encoding="utf-8"))
icons = strip_trace((ROOT / "Art" / "LOTM_TP_Icons.xml").read_text(encoding="utf-8"))
projects_xml = strip_trace((ROOT / "Gameplay" / "LOTM_TP_Projects.xml").read_text(encoding="utf-8"))
zh_text = strip_trace((ROOT / "Text" / "zh_Hans_CN" / "LOTM_TP_ThiefText.xml").read_text(encoding="utf-8"))

for token in ("PATH_THIEF", "UNIT_LOTM_TP_PATH_HOLDER", "LOTM_RP_STATE_VERSION :number = 36"):
    check(token in lifecycle, f"lifecycle missing {token}")
for command in ("SetTarget", "SetBorrowedAbility", "ChooseFinalBranch", "SettleProduction", "SettleFakeGoldDeal", "DesignateCity"):
    check(f"LOTM_TP_Command_{command}" in gameplay, f"Gameplay command missing: {command}")
check("PlayerOperations.EXECUTE_SCRIPT" in panel and "PlayerOperations.EXECUTE_SCRIPT" in city, "Thief UI must submit synchronized operations")
check("Events.LoadGameViewStateDone.Add(Setup)" in city and "Controls.ActionButton:ChangeParent(stack)" in city,
      "Parasite action must attach its native-style button directly to UnitPanel StandardActionsStack")
check("LOTM_TP_CITY_TRANSFER_SUPPORTED" not in city,
      "Parasite UI must not hide the action on a stale capability probe; Gameplay remains authoritative")
check("UI.GetHeadSelectedUnit()" in city
      and "Cities.GetPlotPurchaseCity(plot)" in city
      and "plotOwner ~= localID" in city,
      "Parasite UI must use the selected unit's other-player territory, not only a city-center plot")
check("LOTM_TP_PATH" in launch and "ICON_LOTM_TP_THIEF_MARK" in launch, "Thief must use the shared left LaunchBar")
check("ChooseNextThiefTarget" in shared_hud and "RefreshFakeGoldTopBar" in shared_hud,
      "shared HUD must expose the Thief target and top-bar Counterfeit Gold")
check("ThiefFakeGoldTopBar" in shared_hud_xml and "ThiefFakeGoldTopBarIcon" in shared_hud_xml,
      "Counterfeit Gold must use its own top-bar counter and modeled icon")
check("TopBar_YieldBacking.dds" in shared_hud_xml and 'Style="YieldBacking"' in shared_hud_xml,
      "Counterfeit Gold must restore Civ VI's native resource backing around the transparent coin")
check("CalculateSizeIfSupported" in shared_hud and "SetFakeGoldTopBarIcon" in shared_hud,
      "top-bar refresh must tolerate Civ6 controls and bind the modeled icon at runtime")
check("ControlContainsFakeGoldText" in shared_hud and "control:GetChildren()" in shared_hud,
      "native Counterfeit Gold resource entries must be hidden through their nested labels")
check("RedeemThiefFakeGold" not in shared_hud and "ThiefRedeemButton" not in shared_hud_xml,
      "manual redemption must not remain in the player-facing Thief HUD")
check("ContextPtr:SetHide(true);" in panel, "legacy right-side Thief panel must remain hidden")
check("SetProperty" not in panel and "ChangeResourceAmount" not in panel, "control panel must not mutate authority")
check("SetProperty" not in city and "ChangeResourceAmount" not in city, "city action must not mutate authority")
check('local cityTransferSupported = CityManager ~= nil and CityManager.TransferCity ~= nil' in gameplay
      and 'player:SetProperty(P.CityTransferSupported, cityTransferSupported and 1 or 0)' in gameplay,
      "lossless city transfer must be gated by the native CityManager.TransferCity API")
check("local tradeSupported = not IsNetworkGame()" in gameplay,
      "trade bridge must be enabled only by the explicit single-player gate")
check("CityManager.TransferCity(city, playerID)" in gameplay
      and "api=CityManager.TransferCity" in gameplay
      and "PARASITE_ALREADY_PENDING" in gameplay
      and "NO_OTHER_TERRITORY_CITY" in gameplay
      and "Cities.GetPlotPurchaseCity(plot)" in gameplay
      and "TP:S4:PARASITE:" in gameplay,
      "Sequence 4 parasite must designate, delay five turns, and transfer through CityManager.TransferCity")
check("PARASITE_COOLDOWN" not in gameplay,
      "Sequence 4 Parasite must not impose an extra cooldown after a completed capture")
check("Game.GetRandNum" not in gameplay and "GAME_SYNC_RANDOM_SEED" in gameplay and "table.sort(candidates" in gameplay, "boost selection must use stable shared-seed hashing")
check("GetWasEverAliveMajors" in gameplay, "ability pool must retain civilizations that existed")
check(
    all(token in gameplay for token in (
        'GiftGuardTechIndex = "LOTM_TP_GIFT_GUARD_TECH_INDEX"',
        'GiftGuardCivicIndex = "LOTM_TP_GIFT_GUARD_CIVIC_INDEX"',
        "player:SetProperty(P.GiftGuardTechIndex, current);",
        "player:SetProperty(P.GiftGuardCivicIndex, current);",
        "guardIndex==nil or guardIndex==tonumber(techIndex)",
        "guardIndex==nil or guardIndex==tonumber(civicIndex)",
        "ApplyCityProjectCompleted(entry.PlayerID,entry.CityID,entry.ObjectID,entry.QueuedTurn)",
    )),
    "network gift guards must identify the exact nested completion and preserve the event turn",
)
check(
    all(token in gameplay for token in (
        'KnowledgeBonusScience = "LOTM_TP_KNOWLEDGE_BONUS_SCIENCE"',
        'KnowledgeBonusCulture = "LOTM_TP_KNOWLEDGE_BONUS_CULTURE"',
        'KnowledgeBonusFaith = "LOTM_TP_KNOWLEDGE_BONUS_FAITH"',
        "local function SetKnowledgeYieldBonus",
        "player:AttachModifierByID(modifierID)",
        "RestoreKnowledgeYieldBonus",
        "ClearKnowledgeYieldBonuses(playerID, player)",
        "destination=NATIVE_PER_TURN_YIELD",
    ))
    and "destTech:ChangeCurrentResearchProgress" not in gameplay
    and "destCulture:ChangeCurrentCulturalProgress" not in gameplay
    and "destReligion:ChangeFaithBalance" not in gameplay,
    "Sequence 5 destination must use reversible native per-turn yield modifiers without direct progress double-counting",
)
check(
    "sourceCulture:GetCulturalProgress" not in gameplay
    and "sourceCulture.ChangeCurrentCulturalProgress == nil" in gameplay
    and 'category=CULTURE reason=NO_PROGRESS_API' in gameplay,
    "Sequence 5 Gameplay must not call the UI-only GetCulturalProgress API and must fail closed without the mutation API",
)
check(
    all(token in gameplay for token in (
        "sourceTech:ChangeCurrentResearchProgress(-science)",
        "sourceCulture:ChangeCurrentCulturalProgress(-culture)",
        "sourceReligion:ChangeFaithBalance(-faith)",
    )),
    "Sequence 5 must still debit the selected target's real progress and Faith balance",
)
check(
    all(token in sql for token in (
        "LOTM_TP_KNOWLEDGE_SCIENCE_PLUS_1",
        "LOTM_TP_KNOWLEDGE_SCIENCE_MINUS_1",
        "LOTM_TP_KNOWLEDGE_CULTURE_PLUS_1",
        "LOTM_TP_KNOWLEDGE_CULTURE_MINUS_1",
        "LOTM_TP_KNOWLEDGE_FAITH_PLUS_1",
        "LOTM_TP_KNOWLEDGE_FAITH_MINUS_1",
        "MODIFIER_PLAYER_ADJUST_YIELD_CHANGE",
        "YIELD_SCIENCE",
        "YIELD_CULTURE",
        "YIELD_FAITH",
    )),
    "Sequence 5 must define native flat Science, Culture, and Faith yield modifier pairs",
)
check(
    all(token in gameplay for token in (
        'LastKnowledgeSource = "LOTM_TP_LAST_KNOWLEDGE_STEAL_SOURCE"',
        'LastKnowledgeTurn = "LOTM_TP_LAST_KNOWLEDGE_STEAL_TURN"',
        'LastKnowledgeScience = "LOTM_TP_LAST_KNOWLEDGE_STEAL_SCIENCE"',
        'LastKnowledgeCulture = "LOTM_TP_LAST_KNOWLEDGE_STEAL_CULTURE"',
        'LastKnowledgeFaith = "LOTM_TP_LAST_KNOWLEDGE_STEAL_FAITH"',
        'science=" .. movedScience .. " culture=" .. movedCulture',
    )),
    "successful Sequence 5 settlement must publish per-yield source amounts for UI accounting",
)
check(
    "ThiefKnowledgeYieldLine" in shared_hud
    and "LOTM_TP_LAST_KNOWLEDGE_STEAL_SOURCE" in shared_hud
    and "LOTM_TP_LAST_KNOWLEDGE_STEAL_SCIENCE" in shared_hud
    and "LOTM_TP_LAST_KNOWLEDGE_STEAL_CULTURE" in shared_hud
    and "LOTM_TP_LAST_KNOWLEDGE_STEAL_FAITH" in shared_hud
    and "LOC_LOTM_TP_KNOWLEDGE_STEAL_TOOLTIP" in shared_hud
    and "LOC_LOTM_TP_KNOWLEDGE_STEAL_TOOLTIP" in zh_text,
    "top-panel Science, Culture, and Faith tooltips must name the latest synchronized Thief source",
)
check(
    'LOTM_MP_TurnSync.Add(OnSynchronizedTurn,"Thief")' in gameplay
    and "entry.QueuedTurn<currentTurn" in gameplay
    and "LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID)" in gameplay
    and "table.sort(ready,function(a,b)" in gameplay,
    "Thief local completion events must settle after a full turn at the stable sorted anchor",
)


def captured_gift(guard_active: bool, guarded_index: int | None, event_index: int) -> bool:
    return guard_active and (guarded_index is None or guarded_index == event_index)


check(captured_gift(True, 42, 42), "the synchronized gifted completion must be captured")
check(not captured_gift(True, 42, 43),
      "a natural completion later in the same turn must not be swallowed by the gift guard")
check(captured_gift(True, None, 43),
      "a legacy transient guard without an object index must remain backward compatible")
check(
    all(token in sql for token in (
        "RESOURCE_LOTM_TP_FAKE_GOLD",
        "RESOURCE_LOTM_TP_FAKE_GOLD_TRADE",
        "Legacy compatibility only",
    )),
    "Counterfeit Gold currency or legacy-carrier migration declaration missing",
)
check("ICON_RESOURCE_LOTM_TP_FAKE_GOLD" in icons,
      "Counterfeit Gold modeled icon definition missing")
check("LastProcessedTurn" in gameplay and "if lastTurn == turn then return" in gameplay,
      "Thief turn processing must be idempotent")
check(
    all(token in gameplay for token in (
        "if not networkGame then",
        "local actualDebit = targetBefore - targetAfterDebit;",
        "local actualCredit = playerAfter - playerBefore;",
        "math.abs(actualDebit - amount) >= 0.001",
        "math.abs(actualCredit - amount) >= 0.001",
        "gold transfer rolled back",
        'rate=50pct amount=',
        '"[COLOR_FLOAT_GOLD]+" .. tostring(amount) .. " [ICON_Gold][ENDCOLOR]"',
        "Game.AddWorldViewText(playerID,",
    )),
    "single-player 50% gold theft must verify both balance deltas, roll back partial transfers, and show the committed gain",
)
check(
    all(token in gameplay for token in (
        "OnSettleFakeGoldDeal",
        "if IsNetworkGame()",
        "ChangeFakeGold(payer, -substitute)",
        "payerTreasury:ChangeGoldBalance(substitute)",
        "recipientTreasury:ChangeGoldBalance(-substitute)",
        "fake gold deal rolled back",
        "rollbackOK=",
        "fake gold deal settled",
        "trueGoldSpent=",
        "aiGoldReceived=",
        "ClearLegacyTradeCarrier",
        "LEGACY_TRADE_CARRIER_CLEANUP_VERSION",
    )),
    "Counterfeit Gold must transactionally substitute native Gold and leave no value with the AI",
)
check("SyncFakeGoldTradeBacking" not in gameplay,
      "legacy hidden trade stockpile must never be mirrored again")
check(
    all(token in deal_view for token in (
        "DiplomacyDealEnacted",
        "LOTM_TP_Command_SettleFakeGoldDeal",
        "DealItemTypes.GOLD",
        "CapturePendingGoldPayment",
        "PayerGoldBefore",
        "RecipientGoldBefore",
        "GameConfiguration.IsAnyMultiplayer() ~= true",
    )),
    "native diplomacy must keep the Gold row and submit enacted lump-sum payments for substitution",
)
check("this bounded idempotent queue retries across publish boundaries" in deal_view,
      "native diplomacy must tolerate an enacted event preceding observable treasury deltas")
check("OnClickAvailableFakeGold" not in deal_view and "CreateHorizontalGroup" not in deal_view,
      "native diplomacy must not expose a separate Counterfeit Gold trade row")
check(
    all(token in quick_deals_view for token in (
        "LuaEvents.QD_StartAIOfferAccept",
        "LuaEvents.QD_EndAIOfferAccept",
        "LOTM_TP_Command_SettleFakeGoldDeal",
        "DealItemTypes.GOLD",
        "GameConfiguration.IsAnyMultiplayer() ~= true",
        'GameConfiguration.GetValue("GAMEMODE_LOTM_RESCUE")',
    )),
    "Quick Deals public acceptance events must use the same single-player Gold substitution",
)


def fake_first_settlement(payment: int, counterfeit: int) -> tuple[int, int, int]:
    fake_spent = min(max(counterfeit, 0), max(payment, 0))
    real_spent = max(payment, 0) - fake_spent
    return fake_spent, real_spent, real_spent


check(fake_first_settlement(10, 20) == (10, 0, 0),
      "full Counterfeit Gold coverage must preserve payer and AI real Gold")
check(fake_first_settlement(10, 6) == (6, 4, 4),
      "partial Counterfeit Gold coverage must pass only the real-Gold remainder to the AI")
check(fake_first_settlement(10, 0) == (0, 10, 10),
      "zero Counterfeit Gold must preserve the native Gold payment")
check(
    mod.find("./InGameActions/ImportFiles[@id='LOTM_TP_ART_FILES']/File[.='UI/DiplomacyDealView_LOTM_TP.lua']") is not None,
    "Counterfeit Gold DiplomacyDealView wildcard extension is not imported in normal mode",
)
check(
    all(term not in zh_text for term in ("技术门（1=通过）", "Quick Deals扣款桥", "生产队列进度接口探针")),
    "player-facing Thief descriptions must contain skill names and effects, not development diagnostics",
)
check(
    all(token in gameplay for token in (
        "LOTM_TP_TARGET_PRODUCTION_MINUS_10",
        "LOTM_TP_TARGET_PRODUCTION_PLUS_10",
        "SyncProductionDebuff",
        "LOTM_TP_PRODUCTION_DEBUFF_COUNT",
        "mode=YIELD_DEBUFF",
    )),
    "Sequence 6 must attach a reversible -10% target-city production debuff",
)
check(
    all(token in gameplay for token in (
        "local after = math.max(0, tonumber(city:GetYield(YieldTypes.PRODUCTION)) or 0)",
        "local amount = math.floor((after / 0.9) * 0.1",
        "GetCapitalCity()",
        "S6:DEST",
        "queue.AddProgress ~= nil",
        "destination.Queue:AddProgress(amount)",
        "GameEvents.LOTM_TP_Command_SettleProduction.Add(OnSettleProduction)",
        "awaiting=EXECUTE_SCRIPT",
        "api=EXECUTE_SCRIPT:AddProgress",
    )),
    "Sequence 6 must accrue loss authoritatively and inject AddProgress through synchronized EXECUTE_SCRIPT",
)
check("local PROBE_VERSION = 4" in gameplay
      and ".ChangeCurrentProductionProgress(" not in gameplay,
      "Sequence 6 must re-probe old saves and retire the unavailable production API")
check('OnStart = PRODUCTION_COMMAND' in panel
      and 'PlayerOperations.EXECUTE_SCRIPT' in panel
      and 'LOTM_TP_PRODUCTION_BUFFER' in panel
      and 'LOTM_TP_LAST_PRODUCTION_SETTLEMENT_TURN' in panel,
      "Thief UI must request buffered production settlement once per active local turn")
check("LOTM_TP_TARGET_PRODUCTION_MINUS_10" in sql
      and "YIELD_PRODUCTION" in sql
      and "'Amount', '-10'" in sql,
      "Sequence 6 target production modifier database rows missing")
check("<Projects>" in projects_xml and projects_xml.count("<Row ProjectType=\"PROJECT_LOTM_TP_") == 13,
      "Thief project definitions must be explicitly present in the normal-mode project database surface")
check(projects_xml.count('PrereqDistrict="DISTRICT_CITY_CENTER"') == 0
      and projects_xml.count('MaxPlayerInstances="1"') >= 9
      and 'PROJECT_LOTM_TP_FAITH_TRANSFER"' in projects_xml
      and 'PROJECT_LOTM_TP_CULTURE_TRANSFER"' in projects_xml,
      "Thief potion projects must remain one-time while transfer projects remain repeatable global projects")
check("ProjectUnlockRepairVersion" in lifecycle
      and "qualified project repair player=" in lifecycle
      and "AttachModifierByID(modifierID)" in lifecycle
      and "digestionTotal >= LOTM_RP_DIGESTION_TARGET and HasProjectPrerequisites(player,rule)" in lifecycle
      and "SyncProjectQualification(player,eligible and rule or nil)" in lifecycle,
      "old saves must reattach a lost project modifier only after actual qualification")
check("LOTM_RP_State.RefreshSequenceState(playerID);" in gameplay,
      "Thief startup must refresh shared project unlock state for old saves")
for project in (
    "SWINDLER_POTION", "CRYPTOLOGIST_POTION", "PROMETHEUS_POTION",
    "DREAM_STEALER_POTION", "PARASITE_POTION", "MENTOR_OF_DECEIT_POTION",
    "FATE_TROJAN_POTION", "WORM_OF_TIME_POTION", "ERROR_APOTHEOSIS",
    "FAITH_TRANSFER", "CULTURE_TRANSFER", "FAITH_TRANSFER_II", "CULTURE_TRANSFER_II",
):
    check(
        f'Name="ICON_PROJECT_LOTM_TP_{project}" Atlas="ICON_ATLAS_LOTM_TP_MARK"' in icons,
        f"Thief project must use the Thief pathway mark icon: {project}",
    )
check("LOTM_TP_PRODUCTION_DEBUFF_ACTIVE" in city_panel,
      "CityPanel must show the active Sequence 6 target production debuff")
check('LOTM_TEST_COMBAT_TOGGLE_ENABLED' in lifecycle
      and 'LOTM_RP_Command_TestCombatToggle' in lifecycle
      and 'IsNetworkGame' in lifecycle
      and 'IsRescueMode' in lifecycle
      and 'LOTM_TP_TEST_COMBAT_PLUS_200' in lifecycle
      and 'LOTM_TP_TEST_COMBAT_MINUS_200' in lifecycle
      and 'LOTM_TP_TEST_CAPITAL_PRODUCTION_PLUS_999' in lifecycle
      and 'LOTM_TP_TEST_CAPITAL_PRODUCTION_MINUS_999' in lifecycle,
      "test combat toggle must be centralized, authoritative, and mode-gated")
check('ID="TestCombatButton"' in shared_hud_xml
      and 'LOTM_TEST_COMBAT_TOGGLE_ENABLED' in shared_hud
      and 'PlayerOperations.EXECUTE_SCRIPT' in shared_hud
      and 'LOTM_RP_Command_TestCombatToggle' in shared_hud,
      "test combat button must submit an EXECUTE_SCRIPT command from the shared HUD")
check('LOTM_TP_TEST_COMBAT_PLUS_200' in sql
      and "'Amount', '200'" in sql
      and "'Amount', '-200'" in sql
      and 'LOTM_TP_TEST_CAPITAL_PRODUCTION_PLUS_999' in sql
      and 'LOTM_TP_TEST_CAPITAL_PRODUCTION_MINUS_999' in sql
      and "'Amount', '999'" in sql
      and "'Amount', '-999'" in sql
      and 'MODIFIER_PLAYER_CAPITAL_CITY_ADJUST_CITY_YIELD_CHANGE' in sql,
      "test combat database modifiers must be exact reversible +/-200 combat and +/-999 capital production values")
for cost in (60, 100, 140, 180, 220, 260, 300, 340, 380, 1000, 2000):
    check(re.search(rf"\b{cost}\b", sql) is not None, f"project cost missing: {cost}")
for size in (22, 30, 32, 38, 50, 64, 70, 80, 95, 200, 256):
    check((ROOT / "Art" / f"LOTM_TP_ThiefGameIcon{size}.dds").is_file(), f"Thief icon missing: {size}")
for size in (22, 30, 32, 38, 50, 64, 80, 128, 256):
    check((ROOT / "Art" / f"LOTM_TP_FakeGoldIcon{size}.dds").is_file(), f"fake-gold icon missing: {size}")

transparent_source = Image.open(ROOT / "ArtSources" / "LOTM_TP_FakeGoldTransparent.png").convert("RGBA")
alpha_min, alpha_max = transparent_source.getchannel("A").getextrema()
check(alpha_min == 0 and alpha_max == 255,
      "Counterfeit Gold source must preserve a real transparent alpha channel")

if errors:
    print(f"FAILED: {len(errors)} Thief checks")
    for error in errors:
        print(" -", error)
    raise SystemExit(1)
print("PASS: Thief pathway static gate")
