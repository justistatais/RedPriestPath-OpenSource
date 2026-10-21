#!/usr/bin/env python3
"""Focused static contracts for rescue HUD and optional UI-mod compatibility."""

from pathlib import Path
# Content contracts use unchanged code; test_rc342_startup_trace tests raw diagnostics.
from generate_startup_trace import strip_trace
import sys

ROOT = Path(__file__).resolve().parents[1]


def require(condition: bool, message: str, failures: list[str]) -> None:
    if not condition:
        failures.append(message)


def main() -> int:
    failures: list[str] = []
    modinfo = strip_trace((ROOT / "RedPriestPath.modinfo").read_text(encoding="utf-8"))
    purification_lua = strip_trace((ROOT / "UI/LOTM_RESCUE_Purification.lua").read_text(encoding="utf-8"))
    purification_xml = strip_trace((ROOT / "UI/LOTM_RESCUE_Purification.xml").read_text(encoding="utf-8"))
    ribbon_lua = strip_trace((ROOT / "UI/LOTM_RESCUE_DiplomacyRibbon.lua").read_text(encoding="utf-8"))
    ribbon_xml = strip_trace((ROOT / "UI/DiplomacyRibbon.xml").read_text(encoding="utf-8"))
    city_states = strip_trace((ROOT / "UI/LOTM_WORLD_CityStates.lua").read_text(encoding="utf-8"))
    city_states_better = strip_trace((ROOT / "UI/LOTM_WORLD_CityStates_Better.lua").read_text(encoding="utf-8"))
    hud = strip_trace((ROOT / "UI/LOTM_RP_HUD.lua").read_text(encoding="utf-8"))
    hud_xml = strip_trace((ROOT / "UI/LOTM_RP_HUD.xml").read_text(encoding="utf-8"))
    manual = strip_trace((ROOT / "UI/LOTM_RP_Manual.lua").read_text(encoding="utf-8"))
    quick_deals = strip_trace((ROOT / "UI/LOTM_AI_Cult_Diplomacy_QuickDeals.lua").read_text(encoding="utf-8"))
    icons = strip_trace((ROOT / "Art/LOTM_RP_Icons.xml").read_text(encoding="utf-8"))

    require('Game.GetProperty("LOTM_RESCUE_PHASE10_DESCENT_TRIGGERED")' in purification_lua,
            "purification HUD must read the synchronized descent property", failures)
    require('ContextPtr:SetHide(true)' in purification_lua and 'Controls.Root:SetHide(true)' in purification_lua,
            "descent must hide both the add-in context and root", failures)
    require('Offset="0,31"' in purification_xml,
            "purification HUD XML must default near the top edge", failures)
    require('UIManager:GetScreenSizeVal()' in purification_lua and
            'RealizePosition(screenX,screenY,rootWidth)' in purification_lua and
            'centeredTop=true position=viewportFixed' in purification_lua and
            'Controls.Root:SetOffsetX(math.floor((screenX-rootWidth)/2))' in purification_lua and
            'Controls.Root:ReprocessAnchoring()' in purification_lua,
            "purification HUD must re-anchor at fixed viewport top-center", failures)

    require('WrapGrowth="Bottom"' in ribbon_xml and 'StackGrowth="Left"' in ribbon_xml,
            "diplomacy ribbon XML must enable downward wrapping", failures)
    require('SetWrapWidth' in ribbon_lua and 'math.ceil(childCount/2)' in ribbon_lua,
            "diplomacy ribbon must calculate a maximum two-row layout", failures)
    require('include("DiplomacyRibbon_Expansion2")' in ribbon_lua,
            "diplomacy wrapper must preserve the Gathering Storm chain", failures)
    require("UIManager:GetScreenSizeVal()" in hud and "ResizeDetailsPopup()" in hud,
            "sequence details popup must adapt to the current screen size", failures)
    require("DetailsBackground" in hud_xml and "DetailsFrame" in hud_xml,
            "sequence details popup must expose resizable frame controls", failures)
    require("UIManager:GetScreenSizeVal()" in manual and "ResizeLayout()" in manual,
            "manual must adapt to the current screen size", failures)
    require('include("diplomacyactionview_qd.lua")' in quick_deals and
            'include("LOTM_AI_Cult_Diplomacy_Extension.lua")' in quick_deals and
            "CacheManager" not in quick_deals and
            "QD_ToggleDealPopup" not in quick_deals,
            "Quick Deals wrapper must preserve the original cache and launch-button implementation", failures)
    require("LOTM_RP_QuickDealsRecovery.lua" not in modinfo and
            "LOTM_RP_QuickDealsRecovery.xml" not in modinfo,
            "removed Quick Deals recovery layer must not remain in the mod manifest", failures)
    require(all(f'IconSize="64"' in icons and filename in icons for filename in (
        "LOTM_RP_RedPriestGameIcon64.dds", "LOTM_PP_PerfectGameIcon64.dds",
        "LOTM_BE_BlackEmperorGameIcon64.dds")),
            "path-holder atlases must provide true 64px icon mappings", failures)

    better_id = "13E8BCDF-98EC-4C03-3641-72D519B0047C"
    require(better_id in modinfo and 'LOTM_RP_EXPANSION_2_BETTER_CITY_STATES' in modinfo,
            "modinfo must detect Better City States without making it mandatory", failures)
    require('<LoadOrder>99989</LoadOrder><LuaContext>CityStates</LuaContext>' in modinfo,
            "Better City States church wrapper must load after Workshop order 321", failures)
    require('include("citystates_bst_xp2")' in city_states,
            "church injection must use Better City States' GS entry point when active", failures)
    require("local BASE_ViewList=ViewList" in city_states and
            "local BASE_OnConfirmPlacement=OnConfirmPlacement" in city_states and
            "BASE_ViewList(); RefreshChurchRows();" in city_states,
            "church injection must retain the complete base City States list and envoy confirmation flow", failures)
    require("local BASE_AddCityStateRow=AddCityStateRow" in city_states and
            "return GetLivingCityStatesMetNum()+#CHURCHES" in city_states and
            "instance.CityStateBase:SetHide(true)" in city_states,
            "dead real city-state placeholders must be hidden while all three virtual churches remain", failures)
    require("local BASE_ViewRelationships=ViewRelationships" in city_states and
            "GetLivingCityStatesMetNum()==0" in city_states and
            "reason=NO_LIVING_REAL_CITY_STATES" in city_states,
            "relationship tab must fall back to the church list after the final real city-state dies", failures)
    require('g_LOTM_BETTER_CITY_STATES_ACTIVE=true' in city_states_better,
            "optional compatibility entry point must select the Better base", failures)
    require('if instance.QuestIcon~=nil' in city_states and 'if instance.SuzerainLabel~=nil' in city_states,
            "controls removed by Better City States must be nil-safe", failures)
    require('instance.CuiCityStateQuest:SetText(questText)' in city_states and
            'instance.Resources:SetText(noneText)' in city_states,
            "Better City States quest/resource placeholders must be initialized", failures)
    require('instance.SpyInfo:SetHide(true)' in city_states and
            'instance.TradeRoute:SetHide(true)' in city_states and
            'instance.TradingPost:SetHide(true)' in city_states,
            "inapplicable Better City States church-row fields must be hidden", failures)

    if failures:
        for failure in failures:
            print(f"[FAIL] {failure}")
        return 1
    print("UI compatibility validation passed: 23 checks")
    return 0


if __name__ == "__main__":
    sys.exit(main())
