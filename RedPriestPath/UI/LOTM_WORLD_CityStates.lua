-- BEGIN RC342 STARTUP TRACE
-- Optional startup diagnostics, resource 435. Embedded by generate_startup_trace.py so a
-- missing VFS import cannot hide the first startup checkpoint.
-- Keep disabled in releases: high-frequency UI tracing caused severe stutter.
-- To diagnose a new failure, enable and rerun both startup/bundle generators.
if LOTM_StartupTrace == nil then
	LOTM_StartupTrace = { Enabled=false, Resource=435 };
	local trace = LOTM_StartupTrace;
	local sequence = 0;
	local unpackValues = table.unpack or unpack;
	local function Pack(...) return { n=select("#",...), ... }; end
	local function Scalar(value)
		local kind = type(value);
		if kind == "nil" then return "nil"; end
		if kind == "boolean" or kind == "number" then return tostring(value); end
		if kind == "string" then return string.sub(value:gsub("[\r\n\t]"," "),1,240); end
		-- Never tostring engine userdata or tables: __tostring can call native code.
		return "<" .. kind .. ">";
	end
	function trace.Mark(context,point,...)
		if not trace.Enabled then return; end
		sequence = sequence + 1;
		local fields = {};
		for index=1,select("#",...) do fields[index] = Scalar(select(index,...)); end
		print("[LOTM_DIAG] r=435 seq=" .. sequence .. " ctx=" .. context
			.. " point=" .. point .. (#fields>0 and " args=" .. table.concat(fields,"|") or ""));
	end
	-- A lexical proxy belongs to this module only. The actual Events tables,
	-- other mods' listeners, registration order and synchronization are untouched.
	function trace.Events(source,context,bus)
		if source == nil or not trace.Enabled then return source; end
		local events = {};
		return setmetatable({}, { __index=function(_,name)
			local real = source[name];
			if real == nil then return nil; end
			if events[name] ~= nil then return events[name]; end
			local wrappers = {};
			local nextID = 0;
			local proxy = setmetatable({}, {
				__index=function(_,member) return real[member]; end,
				__call=function(_,...) return real(...); end
			});
			proxy.Add = function(callback)
				local wrapped = wrappers[callback];
				if wrapped == nil then
					nextID = nextID + 1;
					local point = bus .. "." .. name .. "#" .. nextID;
					wrapped = function(...)
						trace.Mark(context,"EVENT BEGIN " .. point,...);
						-- No pcall: preserve the original error and engine error handling.
						local result = Pack(callback(...));
						trace.Mark(context,"EVENT END " .. point);
						return unpackValues(result,1,result.n);
					end;
					wrappers[callback] = wrapped;
				end
				trace.Mark(context,"REGISTER BEFORE " .. bus .. "." .. name);
				local result = Pack(real.Add(wrapped));
				trace.Mark(context,"REGISTER AFTER " .. bus .. "." .. name);
				return unpackValues(result,1,result.n);
			end;
			proxy.Remove = function(callback)
				-- Keep the identity for remove/re-add and duplicate registration.
				return real.Remove(wrappers[callback] or callback);
			end;
			events[name] = proxy;
			return proxy;
		end });
	end
end
LOTM_StartupTrace.Mark("LOTM_WORLD_CityStates","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"LOTM_WORLD_CityStates","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"LOTM_WORLD_CityStates","GameEvents");
local LuaEvents = LOTM_StartupTrace.Events(LuaEvents,"LOTM_WORLD_CityStates","LuaEvents");
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
do
-- END RC342 STARTUP TRACE
-- Inject three virtual churches into the active Expansion 2 City States screen.
-- The compatibility entry point sets this flag before including this file.
if g_LOTM_BETTER_CITY_STATES_ACTIVE then
 include("citystates_bst_xp2");
else
 include("CityStates_Expansion2");
end
include("InstanceManager");

local BASE_ViewList=ViewList;
local BASE_ViewRelationships=ViewRelationships;
local BASE_SumEnvoyChanges=SumEnvoyChanges;
local BASE_OnConfirmPlacement=OnConfirmPlacement;
local BASE_AddCityStateRow=AddCityStateRow;
local m_ChurchRows=InstanceManager:new("CityStateRowInstance","CityStateBase",Controls.CityStateStack);
local m_ChurchInstances={};
local m_Changes={FOOL=0,NIGHT=0,STORM=0};
local m_CommandSerial=0;
local m_PendingChurchPublishSerial=nil;
local CHURCHES={
 {Type="FOOL",Name="LOC_LOTM_CHURCH_FOOL_NAME",Icon="ICON_LOTM_CHURCH_FOOL",Color=UI.GetColorValue("COLOR_LOTM_CHURCH_FOOL")},
 {Type="NIGHT",Name="LOC_LOTM_CHURCH_NIGHT_NAME",Icon="ICON_LOTM_CHURCH_NIGHT",Color=UI.GetColorValue("COLOR_LOTM_CHURCH_NIGHT")},
 {Type="STORM",Name="LOC_LOTM_CHURCH_STORM_NAME",Icon="ICON_LOTM_CHURCH_STORM",Color=UI.GetColorValue("COLOR_LOTM_CHURCH_STORM")}
};

local function Property(church,suffix,default)
 local player=Players[Game.GetLocalPlayer()]; if player==nil then return default; end local value=player:GetProperty("LOTM_CHURCH_"..church.."_"..suffix); return value==nil and default or value;
end
local function Envoys(church) return tonumber(Property(church,"ENVOYS",0)) or 0; end
local function ChurchSum() local total=0; for _,value in pairs(m_Changes) do total=total+value; end return total; end
function SumEnvoyChanges() return BASE_SumEnvoyChanges()+ChurchSum(); end

local function GetLivingCityStatesMetNum()
 local localPlayerID=Game.GetLocalPlayer(); local localPlayer=Players[localPlayerID];
 if localPlayer==nil then return 0; end
 local diplomacy=localPlayer:GetDiplomacy(); local total=0;
 for _,cityState in ipairs(PlayerManager.GetAliveMinors()) do
  local cityStateID=cityState:GetID(); local influence=cityState:GetInfluence();
  if cityStateID~=localPlayerID and cityState:IsAlive() and influence~=nil and influence:CanReceiveInfluence() and diplomacy:HasMet(cityStateID) then total=total+1; end
 end
 return total;
end

-- Firaxis keeps met but defeated minors in its private list and normally draws
-- them as destroyed placeholders.  The churches are the permanent recipients;
-- count only living, met real city-states and hide dead rows returned by the
-- original renderer.
function GetCityStatesMetNum()
 return GetLivingCityStatesMetNum()+#CHURCHES;
end

function AddCityStateRow(cityState)
 local instance=BASE_AddCityStateRow(cityState);
 if instance~=nil and cityState~=nil and not cityState.isAlive and instance.CityStateBase~=nil then instance.CityStateBase:SetHide(true); end
 return instance;
end

local function SetChurchIcon(control,iconName,size)
 if control==nil or IconManager==nil or IconManager.FindIconAtlas==nil then print("[LOTM_WORLD][ChurchesUI] icon controls unavailable "..tostring(iconName)); return false; end
 local x,y,sheet=IconManager:FindIconAtlas(iconName,size);
 if sheet==nil or sheet=="" then print("[LOTM_WORLD][ChurchesUI] ICON MISS "..tostring(iconName).." size="..tostring(size)); return false; end
 control:SetTexture(x,y,sheet); print("[LOTM_WORLD][ChurchesUI] icon hit "..tostring(iconName).." size="..tostring(size).." sheet="..tostring(sheet)); return true;
end

local function LocalizedQuestState(state)
 local key="LOC_LOTM_CHURCH_STATE_"..tostring(state or "LOCKED");
 return Locale.Lookup(key);
end

local function QuestState(church,tier)
 return LocalizedQuestState(Property(church,"QUEST_"..tostring(tier).."_STATE","LOCKED"));
end

local function RewardSummary(church,tier)
 local prefix="QUEST_"..tostring(tier).."_"; local kind=tostring(Property(church,prefix.."REWARD_KIND","")); if kind=="" then return nil; end
 if kind=="ARTIFACT" then local artifact=Property(church,prefix.."REWARD_ARTIFACT",nil); local row=artifact~=nil and GameInfo.GreatWorks[artifact] or nil; local name=row~=nil and Locale.Lookup(row.Name) or tostring(artifact or ""); return Locale.Lookup("LOC_LOTM_CHURCH_REWARD_STATUS_ARTIFACT",tier,name); end
 local strength=tostring(Property(church,prefix.."REWARD_STRENGTH",kind=="HALF_BLESSING" and "HALF" or "FULL"));
 return Locale.Lookup("LOC_LOTM_CHURCH_REWARD_STATUS_BLESSING",tier,Locale.Lookup("LOC_LOTM_CHURCH_BLESS_"..church.."_"..tier.."_"..strength));
end

local function TargetPlotIndex(church)
 local kind=tostring(Property(church,"TARGET_KIND","NONE"));
 local stored=tonumber(Property(church,"TARGET_PLOT",-1)) or -1;
 if kind=="MONSTER" then
  local serial=tonumber(Property(church,"TARGET_ID",-1)) or -1;
  local ownerValue=Game.GetProperty("LOTM_WORLD_MONSTER:"..serial..":OWNER");
  local unitValue=Game.GetProperty("LOTM_WORLD_MONSTER:"..serial..":UNIT_ID");
  local owner=ownerValue~=nil and tonumber(ownerValue) or nil; local unitID=unitValue~=nil and tonumber(unitValue) or nil;
  local unit=owner~=nil and unitID~=nil and UnitManager.GetUnit(owner,unitID) or nil;
  if unit~=nil then local currentPlot=Map.GetPlot(unit:GetX(),unit:GetY()); if currentPlot~=nil then return currentPlot:GetIndex(); end end
 end
 return stored;
end

local function PlotLocation(plotIndex)
 local plot=plotIndex~=nil and plotIndex>=0 and Map.GetPlotByIndex(plotIndex) or nil;
 if plot==nil then return Locale.Lookup("LOC_LOTM_CHURCH_LOCATION_UNKNOWN"); end
 return Locale.Lookup("LOC_LOTM_CHURCH_COORDINATES",plot:GetX(),plot:GetY());
end

local function ChurchQuestTooltip(church)
 local tier=tonumber(Property(church,"ACTIVE_TIER",0)) or 0;
 local kind=tostring(Property(church,"TARGET_KIND","NONE"));
 local plot=TargetPlotIndex(church); local location=PlotLocation(plot);
 local progress=tonumber(Property(church,"TARGET_PROGRESS",0)) or 0;
 local text=Locale.Lookup("LOC_CITY_STATES_QUESTS");
 local rescue=tonumber(Game.GetProperty("LOTM_RESCUE_MODE") or 0)==1;
 if rescue then
  local player=Players[Game.GetLocalPlayer()];
  local shared=player~=nil and tonumber(player:GetProperty("LOTM_RESCUE_WAR_GOD_RELIC_COMPLETED") or 0)==1 and "LOC_LOTM_RESCUE_WAR_GOD_RELIC_TASK_COMPLETE"
   or player~=nil and tonumber(player:GetProperty("LOTM_RESCUE_WAR_GOD_RELIC_REQUIREMENT_MET") or 0)==1 and "LOC_LOTM_RESCUE_WAR_GOD_RELIC_TASK_PROJECT"
   or "LOC_LOTM_RESCUE_WAR_GOD_RELIC_TASK_ENVOYS";
  text=text.."[NEWLINE]"..Locale.Lookup(shared);
 end
 if tier>0 then
  text=text.."[NEWLINE][ICON_CityStateQuest] "..Locale.Lookup("LOC_LOTM_CHURCH_ORACLE_TITLE",tier);
  if kind=="MONSTER" then text=text.."[NEWLINE]"..Locale.Lookup("LOC_LOTM_CHURCH_ORACLE_MONSTER_TARGET",tier,location);
  elseif kind=="WORKSHOP" then text=text.."[NEWLINE]"..Locale.Lookup("LOC_LOTM_CHURCH_ORACLE_WORKSHOP_TARGET",tier,location);
  elseif kind=="BARB_CAMP_COUNT" then text=text.."[NEWLINE]"..Locale.Lookup("LOC_LOTM_CHURCH_CAMP_TARGET",tier,progress,2);
  else text=text.."[NEWLINE]"..Locale.Lookup("LOC_LOTM_CHURCH_ORACLE_PENDING",tier); end
  text=text.."[NEWLINE]"..Locale.Lookup("LOC_LOTM_CHURCH_ORACLE_REWARD",tier);
 else
  text=text.."[NEWLINE]"..Locale.Lookup("LOC_LOTM_CHURCH_ORACLE_NO_ACTIVE");
 end
 if rescue then text=text.."[NEWLINE][NEWLINE]"..Locale.Lookup("LOC_LOTM_RESCUE_CHURCH_ORACLE_STATES",QuestState(church,10),QuestState(church,15));
 else text=text.."[NEWLINE][NEWLINE]"..Locale.Lookup("LOC_LOTM_CHURCH_ORACLE_STATES",QuestState(church,6),QuestState(church,10),QuestState(church,15)); end
 for _,completedTier in ipairs(rescue and {10,15} or {6,10,15}) do local reward=RewardSummary(church,completedTier); if reward~=nil then text=text.."[NEWLINE]"..reward; end end
 return text;
end

local function RefreshChurchRows()
 m_ChurchRows:ResetInstances(); m_ChurchInstances={}; local sendMode=not Controls.ConfirmFrame:IsHidden();
 local available=Players[Game.GetLocalPlayer()]:GetInfluence():GetTokensToGive()-SumEnvoyChanges();
 for _,church in ipairs(CHURCHES) do
  local churchType=church.Type; local instance=m_ChurchRows:GetInstance(); m_ChurchInstances[churchType]=instance; local value=Envoys(churchType)+(m_Changes[churchType] or 0);
  instance.NameLabel:SetText(Locale.ToUpper(Locale.Lookup(church.Name))); instance.NameLabel:SetColor(church.Color);
  -- 26px reward emblems already resolve in live games; use the same atlas family
  -- at 32px for this 36px control instead of falling through to Firaxis' question mark.
  SetChurchIcon(instance.Icon,church.Icon,32); instance.Icon:SetColor(church.Color); instance.Icon:SetToolTipString(Locale.Lookup("LOC_LOTM_CHURCH_VIRTUAL_TOOLTIP"));
  instance.DiplomacyPip:SetHide(true);
  local activeTier=tonumber(Property(church.Type,"ACTIVE_TIER",0)) or 0; local questTooltip=ChurchQuestTooltip(church.Type);
  -- Match Firaxis CityStates.lua: the blue quest callout owns the quest tooltip.
  -- Also attach it to the virtual church row so its larger hit area is usable.
  -- Better City States comments out QuestIcon and SuzerainLabel; both are
  -- optional decoration, so keep the virtual row functional without them.
  if instance.QuestIcon~=nil then instance.QuestIcon:SetText("[ICON_CityStateQuest]"); instance.QuestIcon:SetHide(activeTier<=0); instance.QuestIcon:SetToolTipString(questTooltip); end
  instance.Button:SetToolTipString(questTooltip); instance.NameButton:SetToolTipString(questTooltip);
  if instance.CityStateBase~=nil then instance.CityStateBase:SetToolTipString(questTooltip); end
  instance.LookAtButton:SetHide(true); instance.AmbassadorButton:SetHide(true); instance.BonusImageSuzerainOff:SetHide(true); instance.BonusImageSuzerainOn:SetHide(true);
  instance.BonusIconSuzerain:SetHide(true); instance.BonusTextSuzerain:SetHide(true); if instance.SuzerainLabel~=nil then instance.SuzerainLabel:SetHide(true); end instance.Suzerain:SetHide(true);
  -- Better City States adds extra row fields whose XML defaults are literal
  -- placeholders.  Virtual churches have no map resources, spies or trade
  -- connections; initialize every optional field instead of leaking $...$.
  local noneText=Locale.Lookup("LOC_LOTM_CHURCH_TARGET_KIND_NONE");
  if instance.CuiCityStateQuest~=nil then
   local questText=activeTier>0 and Locale.Lookup("LOC_LOTM_CHURCH_ORACLE_TITLE",activeTier) or noneText;
   if tonumber(Game.GetProperty("LOTM_RESCUE_MODE") or 0)==1 then
    local localPlayer=Players[Game.GetLocalPlayer()];
    if localPlayer~=nil then
     if tonumber(localPlayer:GetProperty("LOTM_RESCUE_WAR_GOD_RELIC_COMPLETED") or 0)==1 then questText=Locale.Lookup("LOC_LOTM_RESCUE_WAR_GOD_RELIC_TASK_COMPLETE");
     elseif tonumber(localPlayer:GetProperty("LOTM_RESCUE_WAR_GOD_RELIC_REQUIREMENT_MET") or 0)==1 then questText=Locale.Lookup("LOC_LOTM_RESCUE_WAR_GOD_RELIC_TASK_PROJECT");
     elseif activeTier<=0 then questText=Locale.Lookup("LOC_LOTM_RESCUE_WAR_GOD_RELIC_TASK_ENVOYS"); end
    end
   end
   instance.CuiCityStateQuest:SetText(questText); instance.CuiCityStateQuest:SetColor(church.Color); instance.CuiCityStateQuest:SetToolTipString(questTooltip);
  end
  if instance.Resources~=nil then instance.Resources:SetText(noneText); instance.Resources:SetToolTipString(noneText); end
  if instance.SpyLabel~=nil then instance.SpyLabel:SetHide(true); end
  if instance.SpyInfo~=nil then instance.SpyInfo:SetHide(true); instance.SpyInfo:SetText(""); end
  if instance.OurAmbassador~=nil then instance.OurAmbassador:SetHide(true); end
  if instance.TradeRoute~=nil then instance.TradeRoute:SetHide(true); end
  if instance.TradingPost~=nil then instance.TradingPost:SetHide(true); end
  RealizeEnvoyToken(value,instance.EnvoyCount);
  for _,threshold in ipairs({1,3,6}) do local active=value>=threshold; local image=instance["BonusImage"..threshold]; local icon=instance["BonusIcon"..threshold]; local text=instance["BonusText"..threshold]; image:SetTexture(active and "CityState_BonusSlotOn" or "CityState_BonusSlotOff"); image:SetToolTipString(Locale.Lookup("LOC_LOTM_CHURCH_"..church.Type.."_PERM_"..threshold)); SetChurchIcon(icon,church.Icon,26); icon:SetColor(active and church.Color or UI.GetColorValueFromHexLiteral(0xff606060)); text:SetColor(active and UI.GetColorValueFromHexLiteral(0xffb0b0b0) or UI.GetColorValueFromHexLiteral(0xff606060)); end
  local function Open() LuaEvents.LOTM_ChurchPanel_Open(church.Type); end
  local function Locate()
   local plotIndex=TargetPlotIndex(church.Type); local plot=plotIndex>=0 and Map.GetPlotByIndex(plotIndex) or nil;
   if plot==nil then Open(); return; end
   if type(Close)=="function" then Close(); end UI.LookAtPlot(plot:GetX(),plot:GetY());
  end
  instance.NameButton:RegisterCallback(Mouse.eLClick,Open); instance.Button:RegisterCallback(Mouse.eLClick,activeTier>0 and Locate or Open);
  instance.EnvoyMoreButton:SetHide(not sendMode); instance.EnvoyLessButton:SetHide(not sendMode or m_Changes[churchType]<=0);
  instance.EnvoyMoreButton:SetDisabled(available<=0); instance.EnvoyLessButton:SetDisabled(m_Changes[churchType]<=0);
  instance.EnvoyMoreButton:RegisterCallback(Mouse.eLClick,function()
   if Players[Game.GetLocalPlayer()]:GetInfluence():GetTokensToGive()>SumEnvoyChanges() then
    m_Changes[churchType]=m_Changes[churchType]+1; UI.PlaySound("UI_Click_Sweetener_Metal_Button_Small");
    RealizeEnvoyToken(Envoys(churchType)+m_Changes[churchType],instance.EnvoyCount); RealizeEnvoyChangeButtons(); RealizeListHeader();
    for typeName,row in pairs(m_ChurchInstances) do row.EnvoyMoreButton:SetDisabled(Players[Game.GetLocalPlayer()]:GetInfluence():GetTokensToGive()<=SumEnvoyChanges()); row.EnvoyLessButton:SetHide(m_Changes[typeName]<=0); row.EnvoyLessButton:SetDisabled(m_Changes[typeName]<=0); end
   end
  end);
  instance.EnvoyLessButton:RegisterCallback(Mouse.eLClick,function()
   if m_Changes[churchType]>0 then
    m_Changes[churchType]=m_Changes[churchType]-1; UI.PlaySound("UI_Click_Sweetener_Metal_Button_Small");
    RealizeEnvoyToken(Envoys(churchType)+m_Changes[churchType],instance.EnvoyCount); RealizeEnvoyChangeButtons(); RealizeListHeader();
    for typeName,row in pairs(m_ChurchInstances) do row.EnvoyMoreButton:SetDisabled(Players[Game.GetLocalPlayer()]:GetInfluence():GetTokensToGive()<=SumEnvoyChanges()); row.EnvoyLessButton:SetHide(m_Changes[typeName]<=0); row.EnvoyLessButton:SetDisabled(m_Changes[typeName]<=0); end
   end
  end);
 end
 Controls.CityStateStack:CalculateSize(); Controls.CityStateScroll:CalculateSize();
 Controls.ConfirmButton:SetDisabled(not m_isLocalPlayerTurn or SumEnvoyChanges()==0);
end

function ViewList() BASE_ViewList(); RefreshChurchRows(); end

-- Firaxis' relationship page assumes at least one living real city-state and
-- takes the length of a nil relationship list after the final minor dies. The
-- churches are virtual envoy recipients, not diplomacy actors, so retain the
-- forced-open City States screen on its valid list view in that state.
function ViewRelationships(...)
 if GetLivingCityStatesMetNum()==0 then
  print("[LOTM_WORLD][ChurchesUI] relationships redirected reason=NO_LIVING_REAL_CITY_STATES churches="..tostring(#CHURCHES));
  ViewList();
  return;
 end
 return BASE_ViewRelationships(...);
end

function OnConfirmPlacement()
 local total=ChurchSum(); if total>0 then
  m_CommandSerial=m_CommandSerial+1; local playerID=Game.GetLocalPlayer(); local player=Players[playerID];
  m_PendingChurchPublishSerial=tonumber(player~=nil and player:GetProperty("LOTM_CHURCH_ENVOY_CHANGE_SERIAL") or 0) or 0;
  local parameters={OnStart="LOTM_WORLD_Churches_SendEnvoys",FOOL=m_Changes.FOOL,NIGHT=m_Changes.NIGHT,STORM=m_Changes.STORM,Serial=tostring(Game.GetCurrentGameTurn())..":"..tostring(m_CommandSerial)};
  UI.RequestPlayerOperation(playerID,PlayerOperations.EXECUTE_SCRIPT,parameters);
 end
 -- Keep church changes visible while the Firaxis confirmation calculates
 -- totalLeft.  Reset only after that calculation; Gameplay acknowledgement is
 -- asynchronous and is handled by OnGameCoreEventPublishComplete below.
 BASE_OnConfirmPlacement();
 m_Changes={FOOL=0,NIGHT=0,STORM=0};
end

local function OnGameCoreEventPublishComplete()
 if m_PendingChurchPublishSerial==nil then return; end
 local player=Players[Game.GetLocalPlayer()];
 local published=tonumber(player~=nil and player:GetProperty("LOTM_CHURCH_ENVOY_CHANGE_SERIAL") or 0) or 0;
 if published<=m_PendingChurchPublishSerial then return; end
 m_PendingChurchPublishSerial=nil;
 -- EXECUTE_SCRIPT publishes after the confirmation callback returns.  Only
 -- rebuild the list for this acknowledged church batch, never every publish.
 ViewList();
end

Controls.ConfirmButton:RegisterCallback(Mouse.eLClick,OnConfirmPlacement);
Events.GameCoreEventPublishComplete.Add(OnGameCoreEventPublishComplete);
print("[LOTM_WORLD][ChurchesUI] City States injection initialized");
-- BEGIN RC342 STARTUP TRACE

end
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("LOTM_WORLD_CityStates","CONTEXT END");
-- END RC342 STARTUP TRACE
