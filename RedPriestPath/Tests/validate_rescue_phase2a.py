#!/usr/bin/env python3
"""Static contracts for the neutral-owner, four-city Rescue Phase 2."""

from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    config = ET.parse(ROOT / "Config/LOTM_RP_PathSelection.xml").getroot()
    players = config.findall("./Players/Row[@CivilizationType='CIVILIZATION_LOTM_RESCUE_TEST']")
    assert len(players) == 0, "obsolete test civilization must not enter the random AI pool"
    assert not (ROOT / "Gameplay/LOTM_RESCUE_Phase2Test.xml").exists()
    assert not (ROOT / "UI/LOTM_RESCUE_AdvancedSetup.lua").exists()

    script = (ROOT / "Scripts/LOTM_RESCUE_Phase2Test.lua").read_text(encoding="utf-8")
    assert script.count("player:GetCities():Create(") == 1
    assert 'local ZONES={"CENTER","FOOL","NIGHT","STORM"}' in script
    assert "for _,zone in ipairs(ZONES) do" in script
    assert 'Game.SetProperty("LOTM_RESCUE_"..zone.."_CITY_ID",city:GetID())' in script
    assert 'Game.SetProperty("LOTM_RESCUE_SEAL_CITY_IDS",table.concat(cityIDs,","))' in script
    assert 'cities=4' in script and 'walls=12' in script and 'plots=76' in script
    assert 'Game.GetProperty("LOTM_RESCUE_PHASE1_STATE")~="READY"' in script
    assert 'PlayerManager.GetFreeCitiesPlayerID()' in script
    assert 'player:IsMajor() or player:IsBarbarian()' in script
    assert 'regular~=requested' in script
    assert '#territory~=19' in script and 'owned~=19' in script
    assert 'Game.SetProperty("LOTM_RESCUE_TEST_PLAYER_ID",playerID)' in script
    assert 'Game.SetProperty("LOTM_RESCUE_TEST_CITY_ID",cities.CENTER:GetID())' in script
    assert 'LOTM_RESCUE_PHASE2A_OWNER_KIND","FREE_CITIES"' in script
    assert 'failure=="SPECIAL_PLAYER_NOT_ALIVE"' in script
    assert 'GameConfiguration.GetValue("CITY_STATE_COUNT")' in script
    assert 'MapConfiguration.GetValue("CITY_STATE_COUNT")' not in script
    assert 'city:SetName(CityName(zone))' in script
    for name in ("星空降临", "愚者教会圣城", "黑夜女神教会圣城", "风暴之主教会圣城"):
        assert name in script
    assert 'queue:CreateBuilding(row.Index)' in script
    for building in ("BUILDING_WALLS", "BUILDING_CASTLE", "BUILDING_STAR_FORT"):
        assert building in script
    for obsolete in ("BUILDING_ANCIENT_WALLS", "BUILDING_MEDIEVAL_WALLS", "BUILDING_RENAISSANCE_WALLS"):
        assert script.count(obsolete) == (1 if obsolete == "BUILDING_ANCIENT_WALLS" else 0)
    assert 'GameInfo.Technologies["TECH_CASTLES"]' in script
    assert 'GameInfo.Civics["CIVIC_MEDIEVAL_FAIRES"]' in script
    assert "CityManager.GetDistrictAt(city:GetX(),city:GetY())" in script
    assert "Players[playerID]:GetDistricts():FindID(city:GetDistrictID())" not in script
    assert script.count("[LOTM_RESCUE][Phase2] checkpoint") >= 4
    assert "\nInitialize();" not in script, "city creation must not run during game-view loading"
    assert "GameEvents.LOTM_RESCUE_Command_BootstrapCity.Add(OnBootstrapCity)" in script
    assert "LOTM_MP_TurnSync.RunPendingStartups(requestPlayerID" in script
    assert "LOTM_MP_TurnSync.IsRescueModeConfigured()" in script
    assert '"EXECUTE_SCRIPT:"..tostring(parameters~=nil and parameters.Trigger or "UNKNOWN")' in script
    assert 'Game.GetProperty("LOTM_RESCUE_PHASE1_STATE")=="READY"' in script
    assert 'Game.GetProperty("LOTM_RESCUE_PHASE2A_STATE")=="READY"' in script
    assert "pcall(LOTM_RESCUE_Phase8.EstablishOpeningCoalition)" in script
    assert "pcall(Initialize)" in script and "pcall(RestoreCity,city,owner,zone)" in script
    assert "GameEvents.PlayerTurnStarted.Add(OnSynchronizedTurnStart)" in script
    assert "LowestAliveHumanMajor" in script and "m_anchorTurn" in script
    assert 'tostring(Game.GetProperty(STATE_KEY) or "NONE")' in script
    assert "for row in GameInfo.Technologies()" not in script
    assert "for row in GameInfo.Civics()" not in script
    assert 'district:SetDamage(DefenseTypes.DISTRICT_OUTER,0)' in script
    assert 'district:SetDamage(DefenseTypes.DISTRICT_GARRISON,0)' in script
    assert 'local function LockLoyalty(city)' in script
    assert 'city:GetCulturalIdentity()' not in script
    assert 'city:ChangeLoyalty(100)' in script
    assert 'Events.CityLoyaltyChanged' not in script
    assert 'OnCityLoyaltyChanged' not in script
    assert 'city:SetProperty("LOTM_RESCUE_SEAL_LOYALTY_LOCK",1)' in script
    assert 'loyalty=100 loyaltyPerTurn=10000' in script
    assert 'local CONTENT_VERSION=11' in script
    assert 'failure=="RUNTIME_GUARD"' in script
    assert 'RegisteredSealsExist(owner)' in script
    assert 'Game.GetProperty(STATE_KEY)~="READY" or playerID~=owner' not in script
    assert 'source=maintenance' in script and 'source=event' not in script
    assert 'if registeredOwner>=0 then Maintain(registeredOwner); end' not in script
    for forbidden in ("UnitManager.InitUnit", "RevealAllPlots", "Players[62]", "Players[63]",
                      "SetMinorCiv", "SetSlotStatus", "MakePeace", "DeclareWar"):
        assert forbidden not in script, forbidden

    mod = ET.parse(ROOT / "RedPriestPath.modinfo").getroot()
    gameplay = mod.find("./InGameActions/AddGameplayScripts[@id='LOTM_RP_GAMEPLAY_ADDIN']")
    bridge = mod.find("./FrontEndActions/ReplaceUIScript[@id='LOTM_RESCUE_ADVANCED_SETUP_BRIDGE']")
    assert gameplay is not None and gameplay.get("criteria") == "LOTM_RP_EXPANSION_2"
    assert [node.text for node in gameplay.findall("File")] == ["Scripts/LOTM_RP_Gameplay_Bundle.lua"]
    phase2 = mod.find("./InGameActions/AddGameplayScripts[@id='LOTM_RESCUE_PHASE2A_GAMEPLAY_ADDIN']")
    assert phase2 is not None and phase2.get("criteria") == "LOTM_RP_RESCUE_MODE"
    assert [node.text for node in phase2.findall("File")] == ["Scripts/LOTM_MP241_Phase2.lua"]
    assert bridge is None
    database = mod.find("./InGameActions/UpdateDatabase[@id='LOTM_RESCUE_CITY_DATABASE']")
    assert database is not None and database.get("criteria") == "LOTM_RP_RESCUE_MODE"
    colors = mod.find("./InGameActions/AddUserInterfaces[@id='LOTM_RESCUE_TERRITORY_COLORS_UI_ADDIN']")
    bootstrap = mod.find("./InGameActions/AddUserInterfaces[@id='LOTM_RESCUE_CITY_BOOTSTRAP_UI_ADDIN']")
    banner = mod.find("./InGameActions/ImportFiles[@id='LOTM_RESCUE_CITY_BANNER_EXTENSION']")
    assert colors is None and bootstrap is not None and banner is not None
    assert banner.get("criteria") == "LOTM_RP_RESCUE_MODE"
    assert banner.findtext("File") == "UI/CityBannerManager_LOTM_RESCUE.lua"
    bootstrap_ui = (ROOT / "UI/LOTM_RESCUE_CityBootstrap.lua").read_text(encoding="utf-8")
    assert "local CONTENT_VERSION=11" in bootstrap_ui
    assert "Events.LoadScreenClose.Add(OnLoadScreenClose)" in bootstrap_ui
    assert "m_loadScreenClosed=false" in bootstrap_ui
    assert "if not m_loadScreenClosed" in bootstrap_ui
    assert "PlayerOperations.EXECUTE_SCRIPT" in bootstrap_ui
    assert 'OnStart=command' in bootstrap_ui
    assert 'Request(playerID,COMMAND,trigger)' in bootstrap_ui
    assert 'Request(playerID,MAIN_COMMAND,trigger)' in bootstrap_ui
    assert 'needsBootstrap and m_submitted' in bootstrap_ui
    assert "if m_networkGame then return; end" not in bootstrap_ui
    assert "passive network context; synchronized Gameplay startup owns bootstrap" not in bootstrap_ui
    assert "Events.LoadScreenClose.Add(OnLoadScreenClose)" in bootstrap_ui
    assert "Events.LocalPlayerTurnBegin.Add" in bootstrap_ui
    assert "Events.PlayerTurnActivated.Add" in bootstrap_ui
    # Resource 372 retains the city operation but adds an independently
    # synchronized post-city module load, including READY save contexts.
    assert 'LOTM_RESCUE_Command_BootstrapCity' in bootstrap_ui
    assert 'LOTM_MP241_Command_LoadMain' in bootstrap_ui
    for forbidden in ("Game.SetProperty", "AttachModifierByID", "UnitManager.",
                      "CityManager.", "Game.AddWorldViewText"):
        assert forbidden not in bootstrap_ui, forbidden
    assert "LOTM_RESCUE_Command_NativeAttackConstants" not in bootstrap_ui
    assert "SubmitNativeAttackConstants" not in bootstrap_ui
    assert "UnitOperationMoveModifiers" not in bootstrap_ui
    city_data = (ROOT / "Gameplay/LOTM_RESCUE_City.xml").read_text(encoding="utf-8")
    assert 'Value="200"' in city_data and 'Value="-100"' in city_data
    assert '<Row BuildingType="BUILDING_LOTM_RESCUE_SEAL_CORE" ModifierId="LOTM_RESCUE_SEAL_LOYALTY_LOCK"/>' in city_data
    assert '<Row ModifierId="LOTM_RESCUE_SEAL_LOYALTY_LOCK" ModifierType="MODIFIER_SINGLE_CITY_ADJUST_IDENTITY_PER_TURN" Permanent="true"/>' in city_data
    assert '<Row ModifierId="LOTM_RESCUE_SEAL_LOYALTY_LOCK" Name="Amount" Value="10000"/>' in city_data
    marker_ui = (ROOT / "UI/LOTM_RESCUE_Phase1Markers.lua").read_text(encoding="utf-8")
    assert "local m_viewReady=false" in marker_ui
    assert not marker_ui.rstrip().endswith("Refresh();")
    banner_ui = (ROOT / "UI/CityBannerManager_LOTM_RESCUE.lua").read_text(encoding="utf-8")
    assert 'local SEAL_ZONES={"CENTER","FOOL","NIGHT","STORM"}' in banner_ui
    assert 'populationInstance.CityPopulation:SetText("?")' in banner_ui
    for icon in ("ICON_LOTM_RESCUE_ASTRAL_DESCENT", "ICON_LOTM_CHURCH_FOOL",
                 "ICON_LOTM_CHURCH_NIGHT", "ICON_LOTM_CHURCH_STORM"):
        assert icon in banner_ui
    assert "BASE_LOTM_UpdateInfo=CityBanner.UpdateInfo" in banner_ui
    assert "BASE_LOTM_UpdateColor=CityBanner.UpdateColor" in banner_ui
    assert "BASE_LOTM_Initialize=Initialize" in banner_ui
    assert "m_InfoIconIM.m_AllocatedInstances" in banner_ui
    assert "IconManager:FindIconAtlas(iconName,22)" in banner_ui
    assert "control:SetTexture(x,y,sheet)" in banner_ui
    assert "typeInstance.Icon:SetIcon" not in banner_ui
    assert 'include("CityBannerManager")' not in banner_ui
    assert "Events.GameCoreEventPublishComplete.Add(OnSealPublishComplete)" in banner_ui
    assert "Events.LoadGameViewStateDone.Add(OnSealLoadGameViewStateDone)" in banner_ui
    assert "RefreshBanner(playerID,cityID)" in banner_ui
    for color in ("COLOR_LOTM_CHURCH_FOOL", "COLOR_LOTM_CHURCH_NIGHT",
                  "COLOR_LOTM_CHURCH_STORM"):
        assert color in banner_ui
    assert "self.m_Instance.CityName:SetColor(nameColor,0)" in banner_ui
    print("Rescue Phase 2: four formal seal cities static contracts passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
