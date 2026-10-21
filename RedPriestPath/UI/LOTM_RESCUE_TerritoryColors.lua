-- Read-only Rescue territory presentation. Gameplay remains authoritative.
-- No UILens or UI function may run while the engine is still constructing the
-- game view.  Creating/toggling the layer during context initialization can
-- prevent Firaxis LoadGameViewStateDone from ever being published.
local LAYER=nil;
local COLORS=nil;
local m_viewReady=false;
local m_lens="Default";

local function InitializeViewResources()
	if LAYER~=nil then return; end
	-- Great-People coloring is cleared whenever unit selection refreshes, which
	-- made the Rescue colors disappear during normal play. Government coloring
	-- is idle on the Default lens and is therefore safe for the persistent map
	-- overlay; Rescue clears it before every redraw and hides it on other lenses.
	LAYER=UILens.CreateLensLayerHash("Hex_Coloring_Government");
	COLORS={
		CENTER=UI.GetColorValueFromHexLiteral(0xB4181010),
		FOOL=UI.GetColorValueFromHexLiteral(0xB4F2F2F2),
		NIGHT=UI.GetColorValueFromHexLiteral(0xB4B82F6B),
		STORM=UI.GetColorValueFromHexLiteral(0xB4D8C820)
	};
end

local function PlotsFor(zone,playerID)
	local result={}; local visibility=PlayersVisibility[playerID];
	if visibility==nil then return result; end
	for value in string.gmatch(tostring(Game.GetProperty("LOTM_RESCUE_"..zone.."_TERRITORY") or ""),"[^,]+") do
		local index=tonumber(value); local plot=index~=nil and Map.GetPlotByIndex(index) or nil;
		if plot~=nil and visibility:IsRevealed(plot:GetX(),plot:GetY()) then result[#result+1]=index; end
	end
	table.sort(result); return result;
end

local function Hide()
	if not m_viewReady or LAYER==nil then return; end
	UILens.ClearLayerHexes(LAYER);
	if UILens.IsLayerOn(LAYER) then UILens.ToggleLayerOff(LAYER); end
end

local function Refresh()
	if not m_viewReady then return; end
	InitializeViewResources();
	Hide();
	if m_lens~="Default" or Game.GetProperty("LOTM_RESCUE_PHASE1_STATE")~="READY" then return; end
	local playerID=Game.GetLocalPlayer(); if playerID==nil or playerID<0 then return; end
	local total=0;
	for _,zone in ipairs({"CENTER","FOOL","NIGHT","STORM"}) do
		local plots=PlotsFor(zone,playerID); total=total+#plots;
		if #plots>0 then UILens.SetLayerHexesColoredArea(LAYER,playerID,plots,COLORS[zone]); end
	end
	if total>0 then UILens.ToggleLayerOn(LAYER); end
end

local function OnLensChanged(newLens)
	m_lens=tostring(newLens or "Default"); Refresh();
end

Events.LensChanged.Add(OnLensChanged);
local function EnableAfterViewReady(trigger)
	if m_viewReady then Refresh(); return; end
	m_viewReady=true;
	print("[LOTM_RESCUE][ColorsUI] view ready trigger="..tostring(trigger).."; enabling territory layer");
	Refresh();
end
Events.LoadGameViewStateDone.Add(function() EnableAfterViewReady("LOAD_GAME_VIEW_STATE_DONE"); end);
Events.LoadScreenClose.Add(function() EnableAfterViewReady("LOAD_SCREEN_CLOSE"); end);
Events.GameCoreEventPublishComplete.Add(Refresh);
Events.LocalPlayerChanged.Add(Refresh);
Events.UnitSelectionChanged.Add(Refresh);
Events.PlayerTurnActivated.Add(function(id) if id==Game.GetLocalPlayer() then Refresh(); end end);
ContextPtr:SetShutdown(function() if m_viewReady then Hide(); end end);
print("[LOTM_RESCUE][ColorsUI] initialized dormant until game view ready");
