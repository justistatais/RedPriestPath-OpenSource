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
LOTM_StartupTrace.Mark("LOTM_RP_HUD","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"LOTM_RP_HUD","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"LOTM_RP_HUD","GameEvents");
local LuaEvents = LOTM_StartupTrace.Events(LuaEvents,"LOTM_RP_HUD","LuaEvents");
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
do
-- END RC342 STARTUP TRACE
-- Local details screen, arson target mode, and burn markers.
-- Gameplay mutation remains restricted to synchronized EXECUTE_SCRIPT commands.

include("ToolTipHelper_PlayerYields");
include("InstanceManager");

local LOTM_RP_PATH :string = "PATH_RED_PRIEST";
local LOTM_PP_PATH :string = "PATH_PERFECT";
local LOTM_BE_PATH :string = "PATH_BLACK_EMPEROR";
local LOTM_TP_PATH :string = "PATH_THIEF";
local LOTM_RP_HERO_TYPE :string = "UNIT_LOTM_RP_PATH_HOLDER";
local LOTM_PP_HERO_TYPE :string = "UNIT_LOTM_PP_PATH_HOLDER";
local LOTM_BE_HERO_TYPE :string = "UNIT_LOTM_BE_PATH_HOLDER";
local LOTM_TP_HERO_TYPE :string = "UNIT_LOTM_TP_PATH_HOLDER";
local LOTM_RP_COMMAND_NAME :string = "LOTM_RP_Command_Arson";
local LOTM_RP_PLAN_TARGET_COMMAND_NAME :string = "LOTM_RP_Command_SelectPlanTarget";
local LOTM_RP_DENOUNCE_COMMAND_NAME :string = "LOTM_RP_Command_Denounce";
local LOTM_RP_CHURCH_COMMAND_NAME :string = "LOTM_RP_Command_ChurchFounded";
local LOTM_RP_CHURCH_BELIEF :string = "BELIEF_LOTM_RP_ESTABLISH_CHURCH";
local LOTM_RP_ARSON_RANGE :number = 6;
local LOTM_TP_TARGET_COMMAND_NAME :string = "LOTM_TP_Command_SetTarget";
local LOTM_TP_BORROW_COMMAND_NAME :string = "LOTM_TP_Command_SetBorrowedAbility";
-- TEST ONLY: keep this flag and the matching Gameplay switch centralized.
local LOTM_TEST_COMBAT_TOGGLE_ENABLED :boolean = false;
local LOTM_TEST_COMBAT_COMMAND_NAME :string = "LOTM_RP_Command_TestCombatToggle";
local LOTM_RP_BURN_UNTIL :string = "LOTM_RP_BURN_UNTIL";
local LOTM_RP_BURN_REVISION :string = "LOTM_RP_BURN_REVISION";
local LOTM_RP_TARGET_LAYER :number =
	UILens.CreateLensLayerHash("Hex_Coloring_Attack");
local LOTM_RP_BURN_LAYER :number =
	UILens.CreateLensLayerHash("Hex_Coloring_Great_People");

local m_isTargeting :boolean = false;
local m_targetCommand :string = "";
local m_targetPlots :table = {};
local m_lastBurnRevision :number = -1;
local m_lastBurnTurn :number = -1;
local m_denounceTurns :table = {};
local m_denounceOwner :number = -1;
local m_fakeGoldTopBarAttached :boolean = false;
local m_purificationEnergyTopBarAttached :boolean = false;
local m_lastYieldTooltipSignature :string = "";
local m_borrowAbilityCandidates :table = {};
local m_borrowAbilitySelected :number = -1;
local m_rescueBorrowSelected :table = {};
local m_borrowIM = InstanceManager:new("ThiefAbilityEntry", "Top", Controls.BorrowAbilityStack);
local m_borrowInstances = {};
local m_borrowWaiting = false;
local m_borrowOwner = -1;
local m_lastSkillScrollLogSignature :string = "";

local function CalculateSizeIfSupported(control :table)
	if control ~= nil and control.CalculateSize ~= nil then
		control:CalculateSize();
	end
end

local function SetFakeGoldTopBarIcon()
	local icon = Controls.ThiefFakeGoldTopBarIcon;
	if icon == nil or IconManager == nil or IconManager.FindIconAtlas == nil then
		return false;
	end
	local offsetX, offsetY, textureSheet =
		IconManager:FindIconAtlas("ICON_RESOURCE_LOTM_TP_FAKE_GOLD", 22);
	if textureSheet == nil or textureSheet == "" then
		icon:SetHide(true);
		return false;
	end
	icon:SetTexture(offsetX, offsetY, textureSheet);
	icon:SetHide(false);
	return true;
end

-- Resource-style DDS atlas lookup is required here. Civ VI does not reliably
-- render an imported PNG when assigned directly with Control:SetTexture.
local function SetPurificationEnergyTopBarIcon()
	local icon = Controls.PurificationEnergyTopBarIcon;
	if icon == nil or IconManager == nil or IconManager.FindIconAtlas == nil then
		return false;
	end
	local offsetX, offsetY, textureSheet =
		IconManager:FindIconAtlas("ICON_RESOURCE_LOTM_RESCUE_PURIFICATION_ENERGY", 22);
	if textureSheet == nil or textureSheet == "" then
		icon:SetHide(true);
		return false;
	end
	icon:SetTexture(offsetX, offsetY, textureSheet);
	icon:SetHide(false);
	return true;
end

local function SetNativeYieldIcon(control, iconName)
	if control == nil or IconManager == nil or IconManager.FindIconAtlas == nil then return false; end
	local offsetX, offsetY, textureSheet = IconManager:FindIconAtlas(iconName, 22);
	if textureSheet == nil or textureSheet == "" then control:SetHide(true); return false; end
	control:SetTexture(offsetX, offsetY, textureSheet); control:SetHide(false); return true;
end

local function GetLocalPlayer()
	local playerID = Game.GetLocalPlayer();
	if playerID == nil or playerID < 0 then
		return -1, nil;
	end
	return playerID, Players[playerID];
end

local function GetProperty(player, key :string, defaultValue)
	if player == nil then
		return defaultValue;
	end
	local value = player:GetProperty(key);
	return value ~= nil and value or defaultValue;
end

local function IsPathVisible(player)
	local path = GetProperty(player, "LOTM_RP_PATH", "NONE");
	return player ~= nil and (path == LOTM_RP_PATH or path == LOTM_PP_PATH
		or path == LOTM_BE_PATH or path == LOTM_TP_PATH);
end

local function IsTestCombatAllowed(player)
	if not LOTM_TEST_COMBAT_TOGGLE_ENABLED or player == nil then return false; end
	if GetProperty(Game, "LOTM_RESCUE_MODE", 0) == 1 then return false; end
	if GameConfiguration ~= nil and GameConfiguration.IsAnyMultiplayer ~= nil
		and GameConfiguration.IsAnyMultiplayer() then return false; end
	return IsPathVisible(player) and player:IsTurnActive();
end

local function ControlContainsFakeGoldText(control :table)
	if control == nil then return false; end
	local ok, value = pcall(function() return control:GetText(); end);
	local textValue = ok and tostring(value or "") or "";
	if string.find(textValue, "ICON_RESOURCE_LOTM_TP_FAKE_GOLD", 1, true) ~= nil then
		return true;
	end
	local childrenOK, children = pcall(function() return control:GetChildren(); end);
	if childrenOK and children ~= nil then
		for _, child in pairs(children) do
			if ControlContainsFakeGoldText(child) then return true; end
		end
	end
	return false;
end

local function HideNativeFakeGoldResourceEntries()
	local resourceStack = ContextPtr:LookUpControl("/InGame/TopPanel/ResourceStack");
	if resourceStack == nil then return; end
	for _, child in pairs(resourceStack:GetChildren()) do
		-- ResourceInstance is a Container whose nested ResourceText label owns the
		-- icon markup. Inspect descendants so both the visible stockpile and the
		-- resource-297 legacy carrier are hidden even though the root has no text.
		if ControlContainsFakeGoldText(child) then
			child:SetHide(true);
		end
	end
	CalculateSizeIfSupported(resourceStack);
end

local function RefreshFakeGoldTopBar(player)
	local yieldStack = ContextPtr:LookUpControl("/InGame/TopPanel/YieldStack");
	if not m_fakeGoldTopBarAttached and yieldStack ~= nil then
		Controls.ThiefFakeGoldTopBar:ChangeParent(yieldStack);
		m_fakeGoldTopBarAttached = true;
	end
	local isThief = player ~= nil
		and GetProperty(player, "LOTM_RP_PATH", "NONE") == LOTM_TP_PATH;
	local sequence = isThief and (tonumber(GetProperty(player, "LOTM_RP_SEQUENCE", 9)) or 9) or 9;
	local show = isThief and GetProperty(Game, "LOTM_RESCUE_MODE", 0) ~= 1
		and sequence <= 8 and m_fakeGoldTopBarAttached;
	Controls.ThiefFakeGoldTopBar:SetHide(not show);
	if show then
		local resource = GameInfo.Resources["RESOURCE_LOTM_TP_FAKE_GOLD"];
		local amount = resource ~= nil
			and player:GetResources():GetResourceAmount(resource.Index) or 0;
		local perTurn = sequence <= 4 and 40 or 20;
		Controls.ThiefFakeGoldTopBarBalance:SetText(
			Locale.ToNumber(math.floor(amount), "#,###"));
		Controls.ThiefFakeGoldTopBarPerTurn:SetText(
			Locale.ToNumber(perTurn, "+#,###;-#,###"));
		SetFakeGoldTopBarIcon();
		CalculateSizeIfSupported(Controls.ThiefFakeGoldTopBarStack);
		CalculateSizeIfSupported(Controls.ThiefFakeGoldTopBarBacking);
		CalculateSizeIfSupported(Controls.ThiefFakeGoldTopBar);
		CalculateSizeIfSupported(yieldStack);
	end
	HideNativeFakeGoldResourceEntries();
end

local function RefreshPurificationEnergyTopBar(player)
	local yieldStack = ContextPtr:LookUpControl("/InGame/TopPanel/YieldStack");
	if Controls.PurificationEnergyTopBar == nil then return; end
	if not m_purificationEnergyTopBarAttached and yieldStack ~= nil then
		Controls.PurificationEnergyTopBar:ChangeParent(yieldStack);
		m_purificationEnergyTopBarAttached = true;
	end
	local rescue = GetProperty(Game, "LOTM_RESCUE_MODE", 0) == 1;
	local isPath = player ~= nil and IsPathVisible(player);
	local show = rescue and isPath and m_purificationEnergyTopBarAttached;
	Controls.PurificationEnergyTopBar:SetHide(not show);
	if show then
		local amount = math.max(0, tonumber(GetProperty(player, "LOTM_RESCUE_ENERGY_BALANCE", 0)) or 0);
		Controls.PurificationEnergyTopBarBalance:SetText(Locale.ToNumber(amount, "#,###"));
		local perTurn = 0;
		if player ~= nil and GetProperty(player, "LOTM_RP_PATH", "NONE") == "PATH_THIEF" then
			local sequence = GetProperty(player, "LOTM_RP_SEQUENCE", 9);
			perTurn = 1;
		end
		Controls.PurificationEnergyTopBarPerTurn:SetText(Locale.ToNumber(perTurn, "+#,###;-#,###"));
		SetPurificationEnergyTopBarIcon();
		CalculateSizeIfSupported(Controls.PurificationEnergyTopBarStack);
		CalculateSizeIfSupported(Controls.PurificationEnergyTopBarBacking);
		CalculateSizeIfSupported(Controls.PurificationEnergyTopBar);
		CalculateSizeIfSupported(yieldStack);
	end
end

local function GetPerfectText(prefix :string, sequence :number)
	local supportedSequence = math.max(0, math.min(9, sequence));
	return Locale.Lookup(prefix .. tostring(supportedSequence));
end

local function GetBlackEmperorText(prefix :string, sequence :number)
	local supportedSequence = math.max(0, math.min(9, sequence));
	return Locale.Lookup(prefix .. tostring(supportedSequence));
end

local function GetSequenceName(path :string, sequence :number)
	local prefix = "LOC_LOTM_RP_HUD_SEQUENCE_NAME_S";
	local supportedSequence = math.max(0, math.min(9, sequence));
	if path == LOTM_PP_PATH then
		prefix = "LOC_LOTM_PP_HUD_SEQUENCE_NAME_S";
	elseif path == LOTM_BE_PATH then
		prefix = "LOC_LOTM_BE_HUD_SEQUENCE_NAME_S";
		supportedSequence = math.max(0, supportedSequence);
	elseif path == LOTM_TP_PATH then
		prefix = "LOC_LOTM_TP_HUD_SEQUENCE_NAME_S";
	end
	return Locale.Lookup(prefix .. tostring(supportedSequence));
end

local function IsHeroUnit(unit, playerID :number)
	if unit == nil or unit:GetOwner() ~= playerID then
		return false;
	end
	local unitInfo = GameInfo.Units[unit:GetType()];
	return unitInfo ~= nil and (unitInfo.UnitType == LOTM_RP_HERO_TYPE
		or unitInfo.UnitType == LOTM_PP_HERO_TYPE
		or unitInfo.UnitType == LOTM_BE_HERO_TYPE
		or unitInfo.UnitType == LOTM_TP_HERO_TYPE);
end

local function GetRegisteredHero()
	local playerID, player = GetLocalPlayer();
	if player == nil then
		return nil;
	end
	local unitID = GetProperty(player, "LOTM_RP_UNIT_ID", -1);
	local unit = unitID >= 0 and player:GetUnits():FindID(unitID) or nil;
	return IsHeroUnit(unit, playerID) and unit or nil;
end

local function GetSelectedLocalHero()
	local playerID, player = GetLocalPlayer();
	local unit = UI.GetHeadSelectedUnit();
	if player == nil
		or not IsHeroUnit(unit, playerID)
		or GetProperty(player, "LOTM_RP_UNIT_ID", -1) ~= unit:GetID() then
		return nil;
	end
	return unit;
end

local function GetThiefCandidates(playerID :number)
	local player = Players[playerID];
	local result :table = {};
	if player == nil then return result; end
	for _, target in ipairs(PlayerManager.GetWasEverAliveMajors() or {}) do
		local targetID = target:GetID();
		if targetID ~= playerID and target:IsAlive()
			and target:GetTeam() ~= player:GetTeam()
			and player:GetDiplomacy():HasMet(targetID) then
			table.insert(result, targetID);
		end
	end
	table.sort(result);
	return result;
end

local function NextThiefCandidate(candidates :table, current :number)
	if #candidates == 0 then return -1; end
	for index, value in ipairs(candidates) do
		if value == current then return candidates[index % #candidates + 1]; end
	end
	return candidates[1];
end

local function IsLegalTarget(playerID :number, unit, plot)
	if unit == nil or plot == nil or plot:IsWater() or plot:IsCity() then
		return false;
	end
	if Map.GetPlotDistance(unit:GetX(), unit:GetY(), plot:GetX(), plot:GetY())
		> LOTM_RP_ARSON_RANGE then
		return false;
	end
	local visibility = PlayersVisibility[playerID];
	if visibility == nil or not visibility:IsVisible(plot:GetIndex()) then
		return false;
	end
	local player = Players[playerID];
	local diplomacy = player ~= nil and player:GetDiplomacy() or nil;
	if diplomacy == nil then
		return false;
	end
	for _, targetUnit in ipairs(Units.GetUnitsInPlot(plot)) do
		if targetUnit ~= nil
			and not targetUnit:IsDead()
			and not targetUnit:IsDelayedDeath()
			and targetUnit:GetOwner() ~= playerID
			and diplomacy:IsAtWarWith(targetUnit:GetOwner()) then
			return true;
		end
	end
	return false;
end

local function HasLegalTarget(playerID :number, unit)
	for plotIndex = 0, Map.GetPlotCount() - 1 do
		if IsLegalTarget(playerID, unit, Map.GetPlotByIndex(plotIndex)) then
			return true;
		end
	end
	return false;
end

local function GetSkillsText(sequence :number)
	if sequence <= 0 then
		return Locale.Lookup("LOC_LOTM_RP_HUD_SKILLS_S0");
	elseif sequence == 1 then
		return Locale.Lookup("LOC_LOTM_RP_HUD_SKILLS_S1");
	elseif sequence == 2 then
		return Locale.Lookup("LOC_LOTM_RP_HUD_SKILLS_S2");
	elseif sequence == 3 then
		return Locale.Lookup("LOC_LOTM_RP_HUD_SKILLS_S3");
	elseif sequence == 4 then
		return Locale.Lookup("LOC_LOTM_RP_HUD_SKILLS_S4");
	elseif sequence == 5 then
		return Locale.Lookup("LOC_LOTM_RP_HUD_SKILLS_S5");
	elseif sequence == 6 then
		return Locale.Lookup("LOC_LOTM_RP_HUD_SKILLS_S6");
	elseif sequence <= 7 then
		return Locale.Lookup("LOC_LOTM_RP_HUD_SKILLS_S7");
	elseif sequence == 8 then
		return Locale.Lookup("LOC_LOTM_RP_HUD_SKILLS_S8");
	end
	return Locale.Lookup("LOC_LOTM_RP_HUD_SKILLS_S9");
end

local function GetNextText(sequence :number)
	if sequence == 9 then
		return Locale.Lookup("LOC_LOTM_RP_HUD_NEXT_S9");
	elseif sequence == 8 then
		return Locale.Lookup("LOC_LOTM_RP_HUD_NEXT_S8");
	elseif sequence == 7 then
		return Locale.Lookup("LOC_LOTM_RP_HUD_NEXT_S7");
	elseif sequence == 6 then
		return Locale.Lookup("LOC_LOTM_RP_HUD_NEXT_S6");
	elseif sequence == 5 then
		return Locale.Lookup("LOC_LOTM_RP_HUD_NEXT_S5");
	elseif sequence == 4 then
		return Locale.Lookup("LOC_LOTM_RP_HUD_NEXT_S4");
	elseif sequence == 3 then
		return Locale.Lookup("LOC_LOTM_RP_HUD_NEXT_S3");
	elseif sequence == 2 then
		return Locale.Lookup("LOC_LOTM_RP_HUD_NEXT_S2");
	elseif sequence == 1 then
		return Locale.Lookup("LOC_LOTM_RP_HUD_NEXT_S1");
	end
	return Locale.Lookup("LOC_LOTM_RP_HUD_NEXT_S0");
end

local function GetAdvancementText(sequence :number, digestionTotal :number)
	if sequence <= 0 then
		return Locale.Lookup("LOC_LOTM_RP_HUD_NEXT_S0");
	end
	if sequence == 5 and digestionTotal >= 6 then
		return Locale.Lookup("LOC_LOTM_RP_HUD_NEXT_S5_UNLOCKED");
	end
	return GetNextText(sequence);
end

local function GetDigestionText(sequence :number)
	if GetProperty(Game, "LOTM_RESCUE_MODE", 0) == 1 then
		local rescueSequence = math.max(0, math.min(9, sequence));
		return Locale.Lookup("LOC_LOTM_RESCUE_P9_RP_DIGEST_S" .. tostring(rescueSequence));
	end
	if sequence <= 0 then
		return Locale.Lookup("LOC_LOTM_RP_HUD_DIGEST_S0");
	elseif sequence == 1 then
		return Locale.Lookup("LOC_LOTM_RP_HUD_DIGEST_S1");
	elseif sequence == 2 then
		return Locale.Lookup("LOC_LOTM_RP_HUD_DIGEST_S2");
	elseif sequence == 3 then
		return Locale.Lookup("LOC_LOTM_RP_HUD_DIGEST_S3");
	elseif sequence == 4 then
		return Locale.Lookup("LOC_LOTM_RP_HUD_DIGEST_S4");
	elseif sequence == 5 then
		return Locale.Lookup("LOC_LOTM_RP_HUD_DIGEST_S5");
	elseif sequence == 6 then
		return Locale.Lookup("LOC_LOTM_RP_HUD_DIGEST_S6");
	elseif sequence == 7 then
		return Locale.Lookup("LOC_LOTM_RP_HUD_DIGEST_S7");
	elseif sequence == 8 then
		return Locale.Lookup("LOC_LOTM_RP_HUD_DIGEST_S8");
	end
	return Locale.Lookup("LOC_LOTM_RP_HUD_DIGEST_S9");
end

local function GetSkillEffectsText(sequence :number)
	if GetProperty(Game, "LOTM_RESCUE_MODE", 0) == 1 then
		local rescueSequence = math.max(0, math.min(9, sequence));
		return Locale.Lookup("LOC_LOTM_RESCUE_P9_RP_EFFECTS_S" .. tostring(rescueSequence));
	end
	if sequence <= 0 then
		return Locale.Lookup("LOC_LOTM_RP_DETAILS_EFFECTS_S0");
	elseif sequence == 1 then
		return Locale.Lookup("LOC_LOTM_RP_DETAILS_EFFECTS_S1");
	elseif sequence == 2 then
		return Locale.Lookup("LOC_LOTM_RP_DETAILS_EFFECTS_S2");
	elseif sequence == 3 then
		return Locale.Lookup("LOC_LOTM_RP_DETAILS_EFFECTS_S3");
	elseif sequence == 4 then
		return Locale.Lookup("LOC_LOTM_RP_DETAILS_EFFECTS_S4");
	elseif sequence == 5 then
		return Locale.Lookup("LOC_LOTM_RP_DETAILS_EFFECTS_S5");
	elseif sequence == 6 then
		return Locale.Lookup("LOC_LOTM_RP_DETAILS_EFFECTS_S6");
	elseif sequence <= 7 then
		return Locale.Lookup("LOC_LOTM_RP_DETAILS_EFFECTS_S7");
	elseif sequence == 8 then
		return Locale.Lookup("LOC_LOTM_RP_DETAILS_EFFECTS_S8");
	end
	return Locale.Lookup("LOC_LOTM_RP_DETAILS_EFFECTS_S9");
end

local function GetRescueThiefEffectsText(sequence :number)
	local rescueSequence = math.max(0, math.min(9, sequence));
	return Locale.Lookup("LOC_LOTM_RESCUE_TP_EFFECTS_S" .. tostring(rescueSequence));
end

local function ClearTargetHighlights()
	UILens.ToggleLayerOff(LOTM_RP_TARGET_LAYER);
	UILens.ClearLayerHexes(LOTM_RP_TARGET_LAYER);
	m_targetPlots = {};
end

local function CancelTargeting()
	if not m_isTargeting then
		return;
	end
	m_isTargeting = false;
	m_targetCommand = "";
	UIManager:SetUICursor(CursorTypes.NORMAL);
	ClearTargetHighlights();
	Controls.TargetHint:SetHide(true);
end

local function CloseDetails()
	Controls.DetailsPopup:SetHide(true);
	Controls.BorrowAbilityPopup:SetHide(true);
	Controls.Vignette:SetHide(true);
	UI.PlaySound("UI_Screen_Close");
end

local function GetCivilizationName(playerID :number)
	local config = playerID ~= nil and playerID >= 0 and PlayerConfigurations[playerID] or nil;
	if config == nil then return tostring(playerID); end
	local civType = config:GetCivilizationTypeName();
	local civ = civType ~= nil and GameInfo.Civilizations[civType] or nil;
	return civ ~= nil and Locale.Lookup(civ.Name) or Locale.Lookup(config:GetCivilizationDescription());
end

local function IsBorrowAbilityVisible(player, sequence :number)
	return player ~= nil and GetProperty(player, "LOTM_RP_PATH", "NONE") == LOTM_TP_PATH
		and sequence == 2
		and (GetProperty(Game, "LOTM_RESCUE_MODE", 0) ~= 1 or tostring(GetProperty(player, "LOTM_RESCUE_THIEF_S2_DONE", "")) ~= "2")
		and tostring(GetProperty(player, "LOTM_TP_BORROWED_CIV", "")) == "";
end

-- Same card structure as Haikesi: ability name, full description, selection
-- brace, then a separate confirmation. No eight-player truncation.
local function GetRescueSelectedAbilitySets(player)
	local selected = {};
	local selectedTraits = {};
	if player == nil or GetProperty(Game, "LOTM_RESCUE_MODE", 0) ~= 1 then
		return selected, selectedTraits;
	end
	local csv = tostring(GetProperty(player, "LOTM_RESCUE_THIEF_S2_ABILITIES", "") or "");
	for modifierID in string.gmatch(csv, "[^,]+") do
		modifierID = tostring(modifierID):gsub("^%s+", ""):gsub("%s+$", "");
		if modifierID ~= "" then selected[modifierID] = true; end
	end
	local traitsCSV = tostring(GetProperty(player, "LOTM_RESCUE_THIEF_S2_TRAITS", "") or "");
	for traitType in string.gmatch(traitsCSV, "[^,]+") do
		traitType = tostring(traitType):gsub("^%s+", ""):gsub("%s+$", "");
		if traitType ~= "" then selectedTraits[traitType] = true; end
	end
	return selected, selectedTraits;
end

local function GetBorrowDescription(civType, selectedAbilitySet, selectedTraitSet)
	local lines = {};
	for link in GameInfo.CivilizationTraits() do
		if link.CivilizationType == civType then
			local trait = GameInfo.Traits[link.TraitType];
			local hasModifier = false;
			local selectedModifier = false;
			for tm in GameInfo.TraitModifiers() do
				if tm.TraitType == link.TraitType and GameInfo.Modifiers[tm.ModifierId] ~= nil then
					hasModifier = true;
					if selectedAbilitySet ~= nil and selectedAbilitySet[tm.ModifierId] then selectedModifier = true; end
				end
			end
			local unique = false;
			for _, rows in ipairs({GameInfo.Units, GameInfo.Buildings, GameInfo.Districts, GameInfo.Improvements}) do
				for row in rows() do if row.TraitType == link.TraitType then unique = true; break; end end
			end
			local hasSavedTrait = selectedTraitSet ~= nil and next(selectedTraitSet) ~= nil;
			local isSelected = selectedAbilitySet == nil
				or (hasSavedTrait and selectedTraitSet[link.TraitType])
				or (not hasSavedTrait and selectedModifier);
			if hasModifier and isSelected
				and not unique and trait ~= nil and trait.Description ~= nil and trait.Description ~= "" then
				table.insert(lines, Locale.Lookup(trait.Name or link.TraitType) .. "[NEWLINE]" .. Locale.Lookup(trait.Description));
			end
		end
	end
	return table.concat(lines, "[NEWLINE][NEWLINE]");
end

local m_abilityReadOnly = false;
local m_removeSelection=-1;
local m_removeReceipt=-1;
local function OpenBorrowAbilityPopup(readOnly)
	local playerID, player = GetLocalPlayer();
	local sequence = tonumber(GetProperty(player, "LOTM_RP_SEQUENCE", 9)) or 9;
	local canInspect = player ~= nil and GetProperty(player, "LOTM_RP_PATH", "NONE") == LOTM_TP_PATH and sequence <= 1;
	if readOnly == true and canInspect then
		m_abilityReadOnly = true;
		Controls.BorrowAbilityPopup:SetHide(true);
	elseif m_abilityReadOnly and canInspect and m_borrowOwner == playerID then
		return;
	else m_abilityReadOnly = false; end
	local pending = IsBorrowAbilityVisible(player, tonumber(GetProperty(player, "LOTM_RP_SEQUENCE", 9)) or 9);
	if m_borrowOwner ~= playerID then
		Controls.BorrowAbilityPopup:SetHide(true);
		m_borrowWaiting = false;
		m_borrowOwner = playerID;
	end
	if not pending and not m_abilityReadOnly then
		Controls.BorrowAbilityPopup:SetHide(true);
		m_borrowWaiting = false;
		return;
	end
	if not m_abilityReadOnly and not player:IsTurnActive() then Controls.BorrowAbilityPopup:SetHide(true); return; end
	if not Controls.BorrowAbilityPopup:IsHidden() then
		Controls.BorrowAbilityConfirm:SetDisabled(m_borrowWaiting or m_borrowAbilitySelected < 0);
		return;
	end
	m_borrowIM:ResetInstances();
	m_borrowInstances = {};
	m_borrowAbilitySelected = -1;
	m_removeSelection=-1;
	m_removeReceipt=tonumber(GetProperty(player,"LOTM_TP_REMOVAL_SERIAL",0)) or 0;
	m_rescueBorrowSelected = {};
	local candidates = {};
	for _, source in ipairs(PlayerManager.GetWasEverAliveMajors() or {}) do
		if source:GetID() ~= playerID then table.insert(candidates, source:GetID()); end
	end
	table.sort(candidates);
	local seen = {};
	local pendingCiv = tostring(GetProperty(player, "LOTM_TP_BORROW_PENDING_CIV", ""));
	if m_abilityReadOnly then pendingCiv = ""; end
	local rescueSelectedAbilitySet = nil;
	local rescueSelectedTraitSet = nil;
	if m_abilityReadOnly and GetProperty(Game, "LOTM_RESCUE_MODE", 0) == 1 then
		rescueSelectedAbilitySet, rescueSelectedTraitSet = GetRescueSelectedAbilitySets(player);
	end
	for _, sourceID in ipairs(candidates) do
		local config = PlayerConfigurations[sourceID];
		local civType = config ~= nil and config:GetCivilizationTypeName() or "";
		local description = GetBorrowDescription(civType, rescueSelectedAbilitySet, rescueSelectedTraitSet);
		if civType ~= PlayerConfigurations[playerID]:GetCivilizationTypeName()
			and (pendingCiv == "" or pendingCiv == civType)
			and (not m_abilityReadOnly or GetProperty(Game,"LOTM_RESCUE_MODE",0)==1
			 or GetProperty(player,"LOTM_TP_REMOVAL_DONE_"..civType,0)~=1)
			and not seen[civType] and description ~= "" then
			seen[civType] = true;
			local entry = m_borrowIM:GetInstance();
			entry.Name:SetText(GetCivilizationName(sourceID));
			entry.Info:SetText(description);
			-- Label updates its measured height with SetText; unlike Stack it
			-- does not expose CalculateSize on the shipped Civ VI UI runtime.
			CalculateSizeIfSupported(entry.Info);
			local removable=m_abilityReadOnly and GetProperty(Game,"LOTM_RESCUE_MODE",0)~=1;
			local height = math.max(100, entry.Info:GetSizeY() + (removable and 108 or 64));
			entry.Top:SetSizeY(height);
			entry.Button:SetSizeY(height);
			entry.SelectorBrace:SetSizeY(height);
			entry.SelectorBrace:SetColor(UI.GetColorValue(1, 1, 1, 0));
			entry.Button:SetSelected(false);
			entry.SourcePlayerID = sourceID;
			table.insert(m_borrowInstances, entry);
			local selectedID = sourceID;
			entry.Remove:SetHide(not removable);
			if removable then
			 entry.Remove:SetDisabled(not player:IsTurnActive());
			 entry.Remove:SetText(Locale.Lookup("LOC_LOTM_TP_REMOVE_ABILITY"));
			 entry.Remove:RegisterCallback(Mouse.eLClick,function()
			  if not player:IsTurnActive() then return;end
			  if m_removeSelection~=selectedID then
			   m_removeSelection=selectedID;
			   for _,other in ipairs(m_borrowInstances) do other.Remove:SetText(Locale.Lookup("LOC_LOTM_TP_REMOVE_ABILITY"));end
			   entry.Remove:SetText(Locale.Lookup("LOC_LOTM_TP_REMOVE_CONFIRM"));
			   Controls.BorrowAbilityHint:SetText(Locale.Lookup("LOC_LOTM_TP_REMOVE_WARNING"));
			   return;
			  end
			  UI.RequestPlayerOperation(playerID,PlayerOperations.EXECUTE_SCRIPT,{
			   OnStart="LOTM_TP_Command_RemoveAbility",SourcePlayerID=selectedID});
			  Controls.BorrowAbilityHint:SetText(Locale.Lookup("LOC_LOTM_TP_REMOVE_PENDING"));
			 end);
			end
			entry.Button:RegisterCallback(Mouse.eLClick, function()
				if m_borrowWaiting or m_abilityReadOnly then return; end
				if GetProperty(Game, "LOTM_RESCUE_MODE", 0) == 1 then
					local found = false; for i,v in ipairs(m_rescueBorrowSelected) do if v == selectedID then table.remove(m_rescueBorrowSelected,i); found=true; break; end end
					if not found and #m_rescueBorrowSelected < 3 then m_rescueBorrowSelected[#m_rescueBorrowSelected+1] = selectedID; end
					for _,other in ipairs(m_borrowInstances) do local active=false; for _,v in ipairs(m_rescueBorrowSelected) do if other.SourcePlayerID==v then active=true; break; end end; other.Button:SetSelected(active); other.SelectorBrace:SetColor(UI.GetColorValue(1,1,1,active and 1 or 0)); end
					m_borrowAbilitySelected = m_rescueBorrowSelected[1] or -1;
				else
				m_borrowAbilitySelected = selectedID;
					for _, other in ipairs(m_borrowInstances) do other.Button:SetSelected(other == entry); other.SelectorBrace:SetColor(UI.GetColorValue(1,1,1,other==entry and 1 or 0)); end
				end
				Controls.BorrowAbilityConfirm:SetDisabled(m_borrowAbilitySelected < 0);
			end);
		end
	end
	if #m_borrowInstances == 0 and not m_abilityReadOnly then return; end
	Controls.BorrowAbilityTitle:SetText(Locale.Lookup(m_abilityReadOnly and "LOC_LOTM_TP_ALL_ABILITIES_TITLE" or "LOC_LOTM_TP_ABILITY_CHOOSER_TITLE"));
	if m_abilityReadOnly and GetProperty(Game, "LOTM_RESCUE_MODE", 0) == 1 then
		local selectedCount = 0; for _ in pairs(rescueSelectedTraitSet or {}) do selectedCount = selectedCount + 1; end
		Controls.BorrowAbilityHint:SetText("仅显示此前选中的文明能力（共 " .. tostring(selectedCount) .. " 项）。");
	else
		Controls.BorrowAbilityHint:SetText(m_abilityReadOnly and Locale.Lookup("LOC_LOTM_TP_ALL_ABILITIES_HINT",
			GetProperty(player, "LOTM_TP_ALL_ABILITIES_LOADED", 0), GetProperty(player, "LOTM_TP_ALL_ABILITIES_TOTAL", 0))
			or Locale.Lookup("LOC_LOTM_TP_ABILITY_CHOOSER_HINT"));
	end
	Controls.BorrowAbilityConfirm:SetText(Locale.Lookup(m_abilityReadOnly and "LOC_CLOSE" or "LOC_LOTM_TP_ABILITY_CONFIRM"));
	local _, screenY = UIManager:GetScreenSizeVal();
	Controls.BorrowAbilityPopup:SetSizeY(math.min(768, math.max(400, screenY - 40)));
	Controls.BorrowAbilityStack:CalculateSize();
	Controls.BorrowAbilityStack:ReprocessAnchoring();
	Controls.BorrowAbilityScroll:CalculateInternalSize();
	Controls.BorrowAbilityConfirm:SetDisabled(not m_abilityReadOnly);
	Controls.BorrowAbilityPopup:SetHide(false);
	UI.PlaySound("CityStates_Panel_Open");
end

local function RefreshRemovalReceipt()
 if not m_abilityReadOnly or Controls.BorrowAbilityPopup:IsHidden()
  or GetProperty(Game,"LOTM_RESCUE_MODE",0)==1 then return;end
 local _,player=GetLocalPlayer();if player==nil then return;end
 local receipt=tonumber(GetProperty(player,"LOTM_TP_REMOVAL_SERIAL",0)) or 0;
 if receipt==m_removeReceipt then return;end
 local result=GetProperty(player,"LOTM_TP_REMOVAL_RESULT","");
 if result=="REMOVED" then OpenBorrowAbilityPopup(true);
 else
  m_removeReceipt=receipt;
  Controls.BorrowAbilityHint:SetText(Locale.Lookup(result=="PENDING" and "LOC_LOTM_TP_REMOVE_PENDING" or "LOC_LOTM_TP_REMOVE_FAILED"));
 end
end
Events.GameCoreEventPublishComplete.Add(RefreshRemovalReceipt);

local function ConfirmBorrowAbility()
	if m_abilityReadOnly then
		m_abilityReadOnly = false; Controls.BorrowAbilityPopup:SetHide(true); return;
	end
	local playerID, player = GetLocalPlayer();
	if m_borrowWaiting or player == nil or not player:IsTurnActive() or m_borrowAbilitySelected < 0
		or not IsBorrowAbilityVisible(player, tonumber(GetProperty(player, "LOTM_RP_SEQUENCE", 9)) or 9) then return; end
	m_borrowWaiting = true;
	Controls.BorrowAbilityConfirm:SetDisabled(true);
	UI.RequestPlayerOperation(playerID, PlayerOperations.EXECUTE_SCRIPT, {
		OnStart = GetProperty(Game, "LOTM_RESCUE_MODE", 0) == 1 and "LOTM_RESCUE_Command_SelectAbility" or LOTM_TP_BORROW_COMMAND_NAME,
		SourcePlayerID = m_borrowAbilitySelected,
		SourcePlayerID1 = GetProperty(Game, "LOTM_RESCUE_MODE", 0) == 1 and m_rescueBorrowSelected[1] or nil,
		SourcePlayerID2 = GetProperty(Game, "LOTM_RESCUE_MODE", 0) == 1 and m_rescueBorrowSelected[2] or nil,
		SourcePlayerID3 = GetProperty(Game, "LOTM_RESCUE_MODE", 0) == 1 and m_rescueBorrowSelected[3] or nil
	});
	-- Close only after the synchronized saved choice is published.
end

local function CloseOtherPanels()
	LuaEvents.LaunchBar_CloseTechTree();
	LuaEvents.LaunchBar_CloseCivicsTree();
	LuaEvents.LaunchBar_CloseGovernmentPanel();
	LuaEvents.LaunchBar_CloseReligionPanel();
	LuaEvents.LaunchBar_CloseGreatPeoplePopup();
	LuaEvents.LaunchBar_CloseGreatWorksOverview();
	LuaEvents.GovernorPanel_Close();
	LuaEvents.HistoricMoments_Close();
	LuaEvents.Launchbar_Expansion2_ClimateScreen_Close();
end

local function RefreshBurnMarkers(force :boolean)
	local playerID = Game.GetLocalPlayer();
	if playerID == nil or playerID < 0 then
		return;
	end
	local revision = Game:GetProperty(LOTM_RP_BURN_REVISION) or 0;
	local currentTurn = Game.GetCurrentGameTurn();
	if not force
		and revision == m_lastBurnRevision
		and currentTurn == m_lastBurnTurn then
		return;
	end
	m_lastBurnRevision = revision;
	m_lastBurnTurn = currentTurn;

	local visibility = PlayersVisibility[playerID];
	local burningPlots :table = {};
	for plotIndex = 0, Map.GetPlotCount() - 1 do
		local plot = Map.GetPlotByIndex(plotIndex);
		local burnUntil = plot ~= nil and plot:GetProperty(LOTM_RP_BURN_UNTIL) or -1;
		if burnUntil > currentTurn
			and visibility ~= nil
			and visibility:IsVisible(plotIndex) then
			table.insert(burningPlots, plotIndex);
		end
	end
	UILens.ClearLayerHexes(LOTM_RP_BURN_LAYER);
	if #burningPlots > 0 then
		UILens.ToggleLayerOn(LOTM_RP_BURN_LAYER);
		UILens.SetLayerHexesArea(LOTM_RP_BURN_LAYER, playerID, burningPlots);
	else
		UILens.ToggleLayerOff(LOTM_RP_BURN_LAYER);
	end
end

local function GetFinalBranchEffect(branch :string)
	if branch == "TECH_CIVIC" then return Locale.Lookup("LOC_LOTM_TP_FINAL_EFFECT_TECH"); end
	if branch == "FAITH" then return Locale.Lookup("LOC_LOTM_TP_FINAL_EFFECT_FAITH"); end
	if branch == "CULTURE" then return Locale.Lookup("LOC_LOTM_TP_FINAL_EFFECT_CULTURE"); end
	return "";
end
local function RefreshRescueCampAction(player)
	if Controls.RescueCampActionButton ~= nil then Controls.RescueCampActionButton:SetHide(true); end
	if player == nil or tonumber(GetProperty(Game, "LOTM_RESCUE_MODE", 0)) ~= 1 or player:GetProperty("LOTM_RP_PATH") ~= LOTM_TP_PATH or (tonumber(player:GetProperty("LOTM_RP_SEQUENCE") or 9) or 9) > 4 then return; end
	local unit = UI.GetHeadSelectedUnit(); local info = unit ~= nil and GameInfo.Units[unit:GetType()] or nil; if unit == nil or unit:GetOwner() ~= Game.GetLocalPlayer() or info == nil then return; end
	local isHero=info.UnitType==LOTM_TP_HERO_TYPE; local isWorm=info.UnitType=="UNIT_LOTM_RESCUE_TIME_WORM"; if not isHero and not isWorm then return; end
	if unit:IsDead() or unit:IsDelayedDeath() then return; end
 local turn=Game.GetCurrentGameTurn();
 if isHero and ((tonumber(player:GetProperty("LOTM_RESCUE_CAMP_CONVERT_PENDING") or 0) or 0)~=0 or (tonumber(player:GetProperty("LOTM_RESCUE_CAMP_CONVERT_TURN") or -1) or -1)==turn) then return; end
 if isWorm and ((tonumber(player:GetProperty("LOTM_RP_SEQUENCE") or 9) or 9)>1 or (tonumber(player:GetProperty("LOTM_RESCUE_TIME_WORM_FOUND_PENDING") or 0) or 0)~=0 or (tonumber(player:GetProperty("LOTM_RESCUE_TIME_WORM_COOLDOWN") or -1) or -1)>turn) then return; end
 local plot = Map.GetPlot(unit:GetX(), unit:GetY()); if plot ~= nil and not plot:IsCity() and not (plot.IsWater~=nil and plot:IsWater()) then
		-- Do not submit a synchronized operation from Refresh().  Unit selection,
		-- tooltip and panel refreshes can fire many times per frame; submitting
		-- PrepareCampConversion here caused a gameplay operation storm and made
		-- end-turn processing block.  The native Found City command (or the
		-- explicit rescue action) now performs all registration on click only.
		if Controls.RescueCampActionButton ~= nil then Controls.RescueCampActionButton:SetHide(false); Controls.RescueCampActionButton:SetToolTipString(Locale.Lookup(isWorm and "LOC_LOTM_RESCUE_WORM_FOUND_TOOLTIP" or "LOC_LOTM_RESCUE_PARASITE_FOUND_TOOLTIP")); end
	end
end
local function SubmitRescueCampAction()
	local id, player=GetLocalPlayer(); local unit=UI.GetHeadSelectedUnit();
	if id==nil or id<0 or player==nil or unit==nil then return; end
	local plot=Map.GetPlot(unit:GetX(),unit:GetY()); if plot==nil then return; end
	local info=GameInfo.Units[unit:GetType()];
	if info~=nil and info.UnitType==LOTM_TP_HERO_TYPE then
		UI.RequestPlayerOperation(id,PlayerOperations.EXECUTE_SCRIPT,{OnStart="LOTM_RESCUE_Command_ConvertBarbarianCamp",PlotIndex=plot:GetIndex(),Mode="SELF"});
	elseif info~=nil and info.UnitType=="UNIT_LOTM_RESCUE_TIME_WORM" then
		UI.RequestPlayerOperation(id,PlayerOperations.EXECUTE_SCRIPT,{OnStart="LOTM_RESCUE_Command_FoundTimeWormCity",UnitID=unit:GetID(),Mode="SELF"});
	end
end
local function ToggleRescueCampGiftAI()
	local id, player = GetLocalPlayer();
	if id == nil or id < 0 or player == nil then return; end
	UI.RequestPlayerOperation(id, PlayerOperations.EXECUTE_SCRIPT, {OnStart="LOTM_RESCUE_Command_SetCampGiftAI"});
end

local function Refresh()
	local playerID, player = GetLocalPlayer();
	RefreshRescueCampAction(player);
	RefreshFakeGoldTopBar(player);
	RefreshPurificationEnergyTopBar(player);
	if playerID < 0 or not IsPathVisible(player) then
		Controls.ComicButton:SetHide(true);
		if Controls.PurificationButton ~= nil then Controls.PurificationButton:SetHide(true); end
		Controls.DetailsPopup:SetHide(true);
		Controls.Vignette:SetHide(true);
		Controls.BorrowAbilityPopup:SetHide(true);
		CancelTargeting();
		return;
	end
	Controls.ComicButton:SetHide(GetProperty(Game, "LOTM_RESCUE_MODE", 0) ~= 1);

	local sequence = GetProperty(player, "LOTM_RP_SEQUENCE", 9);
	local digestA = GetProperty(player, "LOTM_RP_DIGEST_A", 0);
	local digestB = GetProperty(player, "LOTM_RP_DIGEST_B", 0);
	local path = GetProperty(player, "LOTM_RP_PATH", "NONE");
	local isPerfect = path == LOTM_PP_PATH;
	local isBlackEmperor = path == LOTM_BE_PATH;
	local isThief = path == LOTM_TP_PATH;
	local isRedPriest = path == LOTM_RP_PATH;
	Controls.DetailsTitleLabel:SetText(Locale.Lookup(isThief
		and "LOC_LOTM_TP_DETAILS_TITLE" or (isPerfect
		and "LOC_LOTM_PP_DETAILS_TITLE" or (isBlackEmperor
		and "LOC_LOTM_BE_DETAILS_TITLE" or "LOC_LOTM_RP_DETAILS_TITLE"))));
	Controls.PathDescriptionLabel:SetText(Locale.Lookup(isThief
		and "LOC_LOTM_TP_DETAILS_PATH_DESCRIPTION" or (isPerfect
		and "LOC_LOTM_PP_DETAILS_PATH_DESCRIPTION" or (isBlackEmperor
		and "LOC_LOTM_BE_DETAILS_PATH_DESCRIPTION" or "LOC_LOTM_RP_DETAILS_PATH_DESCRIPTION"))));
	Controls.SequenceLabel:SetText(
		Locale.Lookup(isThief and "LOC_LOTM_TP_HUD_SEQUENCE" or (isPerfect and "LOC_LOTM_PP_HUD_SEQUENCE"
			or (isBlackEmperor and "LOC_LOTM_BE_HUD_SEQUENCE"
			or "LOC_LOTM_RP_HUD_SEQUENCE")), sequence,
			GetSequenceName(path, sequence))
	);
	Controls.ProgressLabel:SetText(sequence <= 0
		and Locale.Lookup("LOC_LOTM_RP_HUD_PROGRESS_COMPLETE")
		or Locale.Lookup("LOC_LOTM_RP_HUD_PROGRESS_SINGLE", digestA + digestB));
	Controls.AllAbilitiesButton:SetHide(not (isThief and sequence <= 1));
	Controls.AllAbilitiesButton:SetOffsetX(22 + Controls.SequenceLabel:GetSizeX() + 12);
	if Controls.PurificationButton ~= nil then
		Controls.PurificationButton:SetHide(not (GetProperty(Game, "LOTM_RESCUE_MODE", 0) == 1 and IsPathVisible(player)));
	end
	Controls.SkillsLabel:SetHide(true);
	local effectText = (isThief and GetProperty(Game, "LOTM_RESCUE_MODE", 0) == 1)
		and GetRescueThiefEffectsText(sequence)
		or (isThief and GetPerfectText("LOC_LOTM_TP_DETAILS_EFFECTS_S", sequence))
		or (isPerfect and GetPerfectText("LOC_LOTM_PP_DETAILS_EFFECTS_S", sequence)
		or (isBlackEmperor and GetBlackEmperorText("LOC_LOTM_BE_DETAILS_EFFECTS_S", sequence)
		or GetSkillEffectsText(sequence)));

	if isThief and sequence == 0 then
		local finalBranch = tostring(GetProperty(player, "LOTM_TP_FINAL_BRANCH", "NONE"));
		local selectedEffect = GetFinalBranchEffect(finalBranch);
		if selectedEffect ~= "" then
			effectText = effectText .. "[NEWLINE][NEWLINE]"
				.. Locale.Lookup("LOC_LOTM_TP_FINAL_EFFECT_PREFIX") .. selectedEffect;
		end
	end
	Controls.SkillEffectsLabel:SetText(effectText);
	CalculateSizeIfSupported(Controls.SkillEffectsLabel);
	local showRescueCityAIHint = isThief and GetProperty(Game, "LOTM_RESCUE_MODE", 0) == 1 and sequence <= 4;
	if Controls.RescueCityAIHintLabel ~= nil then
		Controls.RescueCityAIHintLabel:SetHide(not showRescueCityAIHint);
		Controls.RescueCityAIHintLabel:SetText(showRescueCityAIHint and "城市过多时可交由 AI 管理。" or "");
		-- Do not rely on a named ColorSet here.  Several base-game themes resolve
		-- unknown/custom sets to the default grey, which is exactly what happened
		-- in the rescue details panel.  Apply an explicit vivid purple at runtime.
		Controls.RescueCityAIHintLabel:SetColor(UI.GetColorValue(0.78, 0.32, 1.0, 1.0));
		CalculateSizeIfSupported(Controls.RescueCityAIHintLabel);
	end
	if Controls.SkillEffectsStack ~= nil then
		Controls.SkillEffectsStack:CalculateSize();
		Controls.SkillEffectsStack:ReprocessAnchoring();
	end
	if Controls.SkillEffectsScroll ~= nil and Controls.SkillEffectsScroll.CalculateInternalSize ~= nil then
		Controls.SkillEffectsScroll:CalculateInternalSize();
	end
	if Controls.SkillEffectsStack ~= nil and Controls.SkillEffectsScroll ~= nil then
		local scrollLogSignature=tostring(Controls.SkillEffectsStack:GetSizeY())..":"
			..tostring(Controls.SkillEffectsScroll:GetSizeY())..":"..tostring(showRescueCityAIHint);
		if scrollLogSignature~=m_lastSkillScrollLogSignature then
			m_lastSkillScrollLogSignature=scrollLogSignature;
			print("[LOTM_RP][HUD] skill scroll contentH="..tostring(Controls.SkillEffectsStack:GetSizeY())
				.." viewportH="..tostring(Controls.SkillEffectsScroll:GetSizeY())
				.." hint="..tostring(showRescueCityAIHint));
		end
	end
	Controls.NextLabel:SetText(isThief and GetPerfectText("LOC_LOTM_TP_HUD_NEXT_S", sequence)
		or (isPerfect and GetPerfectText("LOC_LOTM_PP_HUD_NEXT_S", sequence)
		or (isBlackEmperor and GetBlackEmperorText("LOC_LOTM_BE_HUD_NEXT_S", sequence)
		or GetAdvancementText(sequence, digestA + digestB))));
	local rescueThief = isThief and GetProperty(Game, "LOTM_RESCUE_MODE", 0) == 1;
	Controls.DigestionLabel:SetText(rescueThief and Locale.Lookup("LOC_LOTM_RESCUE_TP_DIGEST_S" .. tostring(math.max(0, math.min(9, sequence))))
		or (isThief and GetPerfectText("LOC_LOTM_TP_HUD_DIGEST_S", sequence)
		or (isPerfect and GetPerfectText("LOC_LOTM_PP_HUD_DIGEST_S", sequence)
		or (isBlackEmperor and GetBlackEmperorText("LOC_LOTM_BE_HUD_DIGEST_S", sequence)
		or GetDigestionText(sequence)))));

	local hero = GetRegisteredHero();
	Controls.LocateHeroButton:SetHide(hero == nil);
	local showTestCombat = IsTestCombatAllowed(player) and hero ~= nil;
	Controls.TestCombatButton:SetHide(not showTestCombat);
	if showTestCombat then
		local active = (tonumber(GetProperty(player, "LOTM_TEST_COMBAT_BOOST_ACTIVE", 0)) or 0) == 1;
		Controls.TestCombatButton:SetText(Locale.Lookup(active
			and "LOC_LOTM_TEST_COMBAT_NORMAL" or "LOC_LOTM_TEST_COMBAT_PLUS"));
		Controls.TestCombatButton:SetToolTipString(Locale.Lookup("LOC_LOTM_TEST_COMBAT_TOOLTIP"));
	end

	local showArson = isRedPriest and sequence <= 7 and hero ~= nil;
	local showPlanTarget = isRedPriest and sequence <= 6
		and GetProperty(Game, "LOTM_RESCUE_MODE", 0) ~= 1;
	local showThiefTarget = isThief and sequence <= 9
		and GetProperty(Game, "LOTM_RESCUE_MODE", 0) ~= 1;
	Controls.ArsonButton:SetHide(not showArson);
	Controls.PlanTargetButton:SetHide(not (showPlanTarget or showThiefTarget));
	if isThief then
		Controls.PlanTargetButton:SetText(Locale.Lookup("LOC_LOTM_TP_TARGET_NEXT"));
		Controls.PlanTargetButton:SetDisabled(
			math.max(0, 5 - (Game.GetCurrentGameTurn() - GetProperty(player, "LOTM_TP_TARGET_CHANGED_TURN", -999))) > 0
			or not player:IsTurnActive() or #GetThiefCandidates(playerID) == 0);
	else
		Controls.PlanTargetButton:SetText(Locale.Lookup("LOC_LOTM_RP_PLAN_TARGET_BUTTON"));
	end
	if showArson then
		local readyAt = GetProperty(player, "LOTM_RP_ARSON_READY_AT", -1);
		local cooldownTurns = readyAt >= 0
			and math.max(0, readyAt - Game.GetCurrentGameTurn()) or 0;
		local disabledReason = nil;
		local rescueArsonPending = GetProperty(Game, "LOTM_RESCUE_MODE", 0) == 1
			and GetProperty(Game, "LOTM_RESCUE_PHASE9_ARSON_DAMAGE", 70) <= 0;
		if rescueArsonPending then
			disabledReason = Locale.Lookup("LOC_LOTM_RP_ARSON_DISABLED_RESCUE_PENDING");
		elseif not player:IsTurnActive() then
			disabledReason = Locale.Lookup("LOC_LOTM_RP_ARSON_DISABLED_INACTIVE_TURN");
		elseif hero:IsDead() or hero:IsDelayedDeath() then
			disabledReason = Locale.Lookup("LOC_LOTM_RP_ARSON_DISABLED_DEAD");
		elseif cooldownTurns > 0 then
			disabledReason = Locale.Lookup("LOC_LOTM_RP_ARSON_DISABLED_COOLDOWN", cooldownTurns);
		elseif not HasLegalTarget(playerID, hero) then
			disabledReason = Locale.Lookup("LOC_LOTM_RP_ARSON_DISABLED_NO_TARGET");
		end
		Controls.ArsonButton:SetDisabled(disabledReason ~= nil);
		Controls.ArsonButton:SetText(cooldownTurns > 0
			and Locale.Lookup("LOC_LOTM_RP_ARSON_BUTTON_COOLDOWN", cooldownTurns)
			or Locale.Lookup("LOC_LOTM_RP_ARSON_BUTTON"));
		Controls.ArsonButton:SetToolTipString(disabledReason or Locale.Lookup("LOC_LOTM_RP_ARSON_TOOLTIP"));
	end
	if showThiefTarget then
		local targetID = GetProperty(player, "LOTM_TP_TARGET_PLAYER", -1);
		local targetConfig = targetID >= 0 and PlayerConfigurations[targetID] or nil;
		Controls.PlanLabel:SetText(targetConfig ~= nil
			and Locale.Lookup("LOC_LOTM_TP_TARGET_CURRENT", targetConfig:GetPlayerName())
			or Locale.Lookup("LOC_LOTM_TP_TARGET_NONE"));
	elseif showPlanTarget then
		local targetID = GetProperty(player, "LOTM_RP_PLAN_TARGET_ID", -1);
		local targetConfig = targetID >= 0 and PlayerConfigurations[targetID] or nil;
		Controls.PlanLabel:SetText(targetConfig ~= nil
			and Locale.Lookup("LOC_LOTM_RP_PLAN_TARGET_CURRENT", targetConfig:GetPlayerName())
			or Locale.Lookup("LOC_LOTM_RP_PLAN_TARGET_NONE"));
		local targetReadyAt = GetProperty(player, "LOTM_RP_PLAN_TARGET_READY_AT", -1);
		local targetTurns = targetReadyAt >= 0
			and math.max(0, targetReadyAt - Game.GetCurrentGameTurn()) or 0;
		Controls.PlanTargetButton:SetDisabled(targetTurns > 0 or not player:IsTurnActive());
		Controls.PlanTargetButton:SetToolTipString(targetTurns > 0
			and Locale.Lookup("LOC_LOTM_RP_PLAN_TARGET_COOLDOWN", targetTurns)
			or Locale.Lookup("LOC_LOTM_RP_PLAN_TARGET_TOOLTIP"));
	else
		Controls.PlanLabel:SetText("");
	end
end

local function ResizeDetailsPopup()
 if UIManager==nil or UIManager.GetScreenSizeVal==nil then return; end
 local screenX,screenY=UIManager:GetScreenSizeVal();
 local width=math.floor(math.min(840,math.max(640,screenX-40)));
 local height=math.floor(math.min(1040,math.max(560,screenY-40)));
 local innerW=width-40;
 local innerH=math.max(420,height-166);
	-- Keep the skill viewport deliberately shorter than the full Sequence 0
	-- rescue description.  Previously the viewport expanded to ~515px, so all
	-- text fitted and AutoScrollBar correctly hid itself; visually this was not
	-- the requested scrollable presentation.  The hint remains inside the same
	-- content stack and therefore scrolls with the abilities.
	local scrollH=math.min(380,math.max(220,innerH-334));
 Controls.DetailsPopup:SetSizeVal(width,height);
 Controls.DetailsBackground:SetSizeVal(width,height);
 Controls.DetailsHeader:SetSizeX(width);
 Controls.DetailsFrame:SetSizeVal(innerW,innerH);
 Controls.SkillEffectsScroll:SetSizeX(innerW-46);
	Controls.SkillEffectsScroll:SetSizeY(scrollH);
	local effectWidth=innerW-118;
	Controls.SkillEffectsStack:SetSizeX(effectWidth);
	Controls.SkillEffectsLabel:SetSizeX(effectWidth);
	Controls.SkillEffectsLabel:SetWrapWidth(effectWidth);
	if Controls.RescueCityAIHintLabel~=nil then
		Controls.RescueCityAIHintLabel:SetSizeX(effectWidth);
		Controls.RescueCityAIHintLabel:SetWrapWidth(effectWidth);
	end
 Controls.CloseButton:SetOffsetX(12);
 print("[LOTM_RP][HUD] details resized screen="..screenX.."x"..screenY.." popup="..width.."x"..height.." scrollH="..scrollH);
end

local function OpenDetails()
	local _, player = GetLocalPlayer();
	if not IsPathVisible(player) then
		return;
	end
	CloseOtherPanels();
	ResizeDetailsPopup();
	Refresh();
	Controls.Vignette:SetHide(false);
	Controls.DetailsPopup:SetHide(false);
	UI.PlaySound("UI_Screen_Open");
end

local function ToggleDetails()
	if Controls.DetailsPopup:IsHidden() then
		OpenDetails();
	else
		CloseDetails();
	end
end

local function LocateHero()
	local hero = GetRegisteredHero();
	if hero == nil then
		return;
	end
	CloseDetails();
	UI.SelectUnit(hero);
	UI.LookAtPlot(Map.GetPlot(hero:GetX(), hero:GetY()));
end

local function BeginTargeting()
	local playerID, player = GetLocalPlayer();
	local unit = GetRegisteredHero();
	if player == nil
		or unit == nil
		or not player:IsTurnActive()
		or GetProperty(player, "LOTM_RP_SEQUENCE", 9) > 7 then
		return;
	end
	local readyAt = GetProperty(player, "LOTM_RP_ARSON_READY_AT", -1);
	if readyAt >= 0 and Game.GetCurrentGameTurn() < readyAt then
		return;
	end

	CloseDetails();
	UI.SelectUnit(unit);
	CancelTargeting();
	m_isTargeting = true;
	m_targetCommand = LOTM_RP_COMMAND_NAME;
	m_targetPlots = {};
	for plotIndex = 0, Map.GetPlotCount() - 1 do
		local plot = Map.GetPlotByIndex(plotIndex);
		if IsLegalTarget(playerID, unit, plot) then
			m_targetPlots[plotIndex] = true;
		end
	end
	local highlights :table = {};
	for plotIndex, _ in pairs(m_targetPlots) do
		table.insert(highlights, plotIndex);
	end
	table.sort(highlights);
	UIManager:SetUICursor(CursorTypes.RANGE_ATTACK);
	if #highlights > 0 then
		UILens.ToggleLayerOn(LOTM_RP_TARGET_LAYER);
		UILens.SetLayerHexesArea(LOTM_RP_TARGET_LAYER, playerID, highlights);
	end
	Controls.TargetHint:SetHide(false);
end

local function SubmitTarget(plotID :number)
	if not m_isTargeting or not m_targetPlots[plotID] then
		return false;
	end
	local plot = Map.GetPlotByIndex(plotID);
	local unit = GetSelectedLocalHero();
	if plot == nil or unit == nil then
		CancelTargeting();
		return false;
	end
	local parameters :table = {};
	parameters[UnitCommandTypes.PARAM_NAME] = m_targetCommand;
	parameters[UnitCommandTypes.PARAM_X] = plot:GetX();
	parameters[UnitCommandTypes.PARAM_Y] = plot:GetY();
	UnitManager.RequestCommand(unit, UnitCommandTypes.EXECUTE_SCRIPT, parameters);
	CancelTargeting();
	return true;
end

local function ChooseNextPlanTarget()
	local playerID, player = GetLocalPlayer();
	if player == nil
		or GetProperty(player, "LOTM_RP_PATH", "NONE") ~= LOTM_RP_PATH
		or GetProperty(player, "LOTM_RP_SEQUENCE", 9) > 6 then
		return;
	end
	local current = GetProperty(player, "LOTM_RP_PLAN_TARGET_ID", -1);
	local candidates :table = {};
	for _, targetID in ipairs(PlayerManager.GetAliveMajorIDs()) do
		if targetID ~= playerID then
			table.insert(candidates, targetID);
		end
	end
	if #candidates == 0 then
		return;
	end
	table.sort(candidates);
	local selected = candidates[1];
	for index, targetID in ipairs(candidates) do
		if targetID == current then
			selected = candidates[(index % #candidates) + 1];
			break;
		end
	end
	local parameters :table = {};
	parameters.OnStart = LOTM_RP_PLAN_TARGET_COMMAND_NAME;
	parameters.TargetPlayerID = selected;
	UI.RequestPlayerOperation(playerID, PlayerOperations.EXECUTE_SCRIPT, parameters);
end

local function ChooseNextThiefTarget()
	local playerID, player = GetLocalPlayer();
	if player == nil or not player:IsTurnActive() then return; end
	local current = GetProperty(player, "LOTM_TP_TARGET_PLAYER", -1);
	local targetID = NextThiefCandidate(GetThiefCandidates(playerID), current);
	if targetID < 0 then return; end
	UI.RequestPlayerOperation(playerID, PlayerOperations.EXECUTE_SCRIPT, {
		OnStart=LOTM_TP_TARGET_COMMAND_NAME, TargetPlayerID=targetID
	});
end

local function ToggleTestCombat()
	local playerID, player = GetLocalPlayer();
	local hero = GetRegisteredHero();
	if not IsTestCombatAllowed(player) or hero == nil then return; end
	UI.RequestPlayerOperation(playerID, PlayerOperations.EXECUTE_SCRIPT, {
		OnStart = LOTM_TEST_COMBAT_COMMAND_NAME,
		UnitID = hero:GetID()
	});
end

local function OnInputHandler(input :table)
	if not Controls.BorrowAbilityPopup:IsHidden() then
		if m_abilityReadOnly and input:GetMessageType() == KeyEvents.KeyUp and input:GetKey() == Keys.VK_ESCAPE then ConfirmBorrowAbility(); return true; end
		return input:GetMessageType() == KeyEvents.KeyUp and input:GetKey() == Keys.VK_ESCAPE;
	end
	local messageType = input:GetMessageType();
	if not m_isTargeting then
		if messageType == KeyEvents.KeyUp
			and input:GetKey() == Keys.VK_ESCAPE
			and not Controls.DetailsPopup:IsHidden() then
			CloseDetails();
			return true;
		end
		return false;
	end
	if messageType == KeyEvents.KeyUp and input:GetKey() == Keys.VK_ESCAPE then
		CancelTargeting();
		return true;
	elseif messageType == MouseEvents.RButtonUp then
		CancelTargeting();
		return true;
	elseif messageType == MouseEvents.LButtonUp
		or messageType == MouseEvents.PointerUp then
		local plotID = UI.GetCursorPlotID();
		if Map.IsPlot(plotID) then
			SubmitTarget(plotID);
		end
		return true;
	end
	return false;
end

local function PollDiplomacyChanges()
	local playerID, player = GetLocalPlayer();
	if player == nil then
		return;
	end
	if m_denounceOwner ~= playerID then
		m_denounceOwner = playerID;
		m_denounceTurns = {};
	end

	local playerDiplomacy = player:GetDiplomacy();
	if playerDiplomacy == nil then
		return;
	end
	local sequence = GetProperty(player, "LOTM_RP_SEQUENCE", 9);
	local isRedPriest =
		GetProperty(player, "LOTM_RP_PATH", "NONE") == LOTM_RP_PATH;
	for _, targetPlayerID in ipairs(PlayerManager.GetAliveMajorIDs()) do
		if targetPlayerID ~= playerID then
			local denounceTurn =
				tonumber(playerDiplomacy:GetDenounceTurn(targetPlayerID)) or -1;
			local previousTurn = m_denounceTurns[targetPlayerID];
			m_denounceTurns[targetPlayerID] = denounceTurn;
			-- A nil previous value is the save/load baseline.  Never back-pay a
			-- historical denouncement merely because this UI context reloaded.
			if previousTurn ~= nil
				and denounceTurn >= 0
				and denounceTurn ~= previousTurn
				and isRedPriest
				and sequence == 8 then
				local parameters :table = {};
				parameters.OnStart = LOTM_RP_DENOUNCE_COMMAND_NAME;
				parameters.TargetPlayerID = targetPlayerID;
				parameters.DenounceTurn = denounceTurn;
				print("[LOTM_RP][HUD] detected denounce player="
					.. tostring(playerID)
					.. " target=" .. tostring(targetPlayerID)
					.. " turn=" .. tostring(denounceTurn));
				UI.RequestPlayerOperation(
					playerID,
					PlayerOperations.EXECUTE_SCRIPT,
					parameters
				);
			end

		end
	end
end

local function FindYieldBacking(control, headerTag :string)
	if control == nil then
		return nil;
	end
	local tooltip = control:GetToolTipString();
	local yieldHeader = Locale.Lookup(headerTag);
	if tooltip ~= nil
		and yieldHeader ~= nil
		and string.find(tooltip, yieldHeader, 1, true) == 1 then
		return control;
	end
	for _, child in ipairs(control:GetChildren() or {}) do
		local found = FindYieldBacking(child, headerTag);
		if found ~= nil then
			return found;
		end
	end
	return nil;
end

local function GetArtifactPolarity(player, artifactType :string)
	local equipped = false;
	for slot = 1, 9 do
		if GetProperty(player, "LOTM_PP_ARTIFACT_SLOT_" .. tostring(slot), "")
			== artifactType then
			equipped = true;
			break;
		end
	end
	if not equipped then
		return false, false;
	end
	local instance = tonumber(GetProperty(
		player,
		"LOTM_PP_ARTIFACT_INSTANCE_" .. artifactType,
		-1
	));
	local worldTurn = tonumber(GetProperty(player, "LOTM_WORLD_PLAYER_TURN", 0)) or 0;
	local satisfiedUntil = instance ~= nil and instance >= 0 and tonumber(GetProperty(
		player,
		"LOTM_ARTIFACT_SATISFIED_UNTIL_" .. tostring(instance),
		-1
	)) or -1;
	local uncontrolledUntil = instance ~= nil and instance >= 0 and tonumber(GetProperty(
		player,
		"LOTM_ARTIFACT_UNCONTROLLED_UNTIL_" .. tostring(instance),
		-1
	)) or -1;
	if uncontrolledUntil ~= nil and worldTurn < uncontrolledUntil then
		return false, true;
	end
	if satisfiedUntil ~= nil and worldTurn < satisfiedUntil then
		return true, false;
	end
	return true, true;
end

local function ArtifactYieldLine(nameTag :string, amount :number, settled :boolean)
	local amountText = Locale.ToNumber(amount, "+#,###.#;-#,###.#");
	return Locale.Lookup(
		settled and "LOC_LOTM_ARTIFACT_YIELD_SETTLED_TOOLTIP"
			or "LOC_LOTM_ARTIFACT_YIELD_INCLUDED_TOOLTIP",
		Locale.Lookup(nameTag),
		amountText
	);
end

local function ThiefKnowledgeYieldLine(amount :number, sourceName :string)
	return Locale.Lookup(
		"LOC_LOTM_TP_KNOWLEDGE_STEAL_TOOLTIP",
		Locale.ToNumber(amount, "+#,###.#;-#,###.#"),
		sourceName
	);
end

local function AppendYieldSources(tooltip :string, sourceLines :table, beforeExpenses :boolean)
	if #sourceLines == 0 then
		return tooltip;
	end
	local sourceText = "";
	for _, line in ipairs(sourceLines) do
		sourceText = sourceText .. "[NEWLINE]  " .. line;
	end
	if beforeExpenses then
		-- Gold has separate income and expense sections.  Keep Firaxis' complete
		-- tooltip and insert our named accounting lines between those sections.
		local firstSectionEnd = string.find(tooltip, "[NEWLINE][NEWLINE]", 1, true);
		local expenseSectionStart = firstSectionEnd ~= nil and string.find(
			tooltip,
			"[NEWLINE][NEWLINE]",
			firstSectionEnd + 1,
			true
		) or nil;
		if expenseSectionStart ~= nil then
			return string.sub(tooltip, 1, expenseSectionStart - 1)
				.. sourceText
				.. string.sub(tooltip, expenseSectionStart);
		end
	end
	return tooltip .. sourceText;
end

local function RefreshYieldTooltips()
	local _, player = GetLocalPlayer();
	local yieldStack =
		ContextPtr:LookUpControl("/InGame/TopPanel/YieldStack");
	if player == nil or yieldStack == nil then
		return;
	end
	local path = GetProperty(player, "LOTM_RP_PATH", "NONE");
	local sequence = tonumber(GetProperty(player, "LOTM_RP_SEQUENCE", 9)) or 9;
	local currentTurn = Game.GetCurrentGameTurn();
	local treasury = player:GetTreasury();
	local techs = player:GetTechs();
	local culture = player:GetCulture();
	local religion = player:GetReligion();
	local rescueScience = tonumber(GetProperty(player, "LOTM_RESCUE_THIEF_COPY_SCIENCE_LAST", 0)) or 0;
	local rescueCulture = tonumber(GetProperty(player, "LOTM_RESCUE_THIEF_COPY_CULTURE_LAST", 0)) or 0;
	local rescueFaith = tonumber(GetProperty(player, "LOTM_RESCUE_THIEF_COPY_FAITH_LAST", 0)) or 0;
	local rescueScienceTotal = tonumber(GetProperty(player, "LOTM_RESCUE_THIEF_COPY_SCIENCE_TOTAL", 0)) or 0;
	local rescueCultureTotal = tonumber(GetProperty(player, "LOTM_RESCUE_THIEF_COPY_CULTURE_TOTAL", 0)) or 0;
	local signature = table.concat({
		tostring(currentTurn), tostring(path), tostring(sequence),
		tostring(rescueScience), tostring(rescueCulture), tostring(rescueFaith),
		tostring(rescueScienceTotal), tostring(rescueCultureTotal),
		tostring(tonumber(treasury ~= nil and treasury:GetGoldBalance() or 0) or 0),
		tostring(tonumber(treasury ~= nil and treasury:GetGoldYield() or 0) or 0),
		tostring(tonumber(techs ~= nil and techs:GetScienceYield() or 0) or 0),
		tostring(tonumber(culture ~= nil and culture:GetCultureYield() or 0) or 0),
		tostring(tonumber(religion ~= nil and religion:GetFaithYield() or 0) or 0)
	}, "|");
	if signature == m_lastYieldTooltipSignature then return; end
	m_lastYieldTooltipSignature = signature;
	local goldLines :table = {};
	local scienceLines :table = {};
	local cultureLines :table = {};
	local faithLines :table = {};
	local knowledgeTurn = tonumber(GetProperty(
		player, "LOTM_TP_LAST_KNOWLEDGE_STEAL_TURN", -1
	)) or -1;
	if path == LOTM_TP_PATH
		and sequence <= 5
		and knowledgeTurn == Game.GetCurrentGameTurn() then
		local sourceID = tonumber(GetProperty(
			player, "LOTM_TP_LAST_KNOWLEDGE_STEAL_SOURCE", -1
		)) or -1;
		local sourceConfig = sourceID >= 0 and PlayerConfigurations[sourceID] or nil;
		local sourceName = sourceConfig ~= nil and sourceConfig:GetPlayerName()
			or Locale.Lookup("LOC_LOTM_TP_TARGET_NONE");
		local science = tonumber(GetProperty(
			player, "LOTM_TP_LAST_KNOWLEDGE_STEAL_SCIENCE", 0
		)) or 0;
		local culture = tonumber(GetProperty(
			player, "LOTM_TP_LAST_KNOWLEDGE_STEAL_CULTURE", 0
		)) or 0;
		local faith = tonumber(GetProperty(
			player, "LOTM_TP_LAST_KNOWLEDGE_STEAL_FAITH", 0
		)) or 0;
		if science > 0 then table.insert(scienceLines, ThiefKnowledgeYieldLine(science, sourceName)); end
		if culture > 0 then table.insert(cultureLines, ThiefKnowledgeYieldLine(culture, sourceName)); end
		if faith > 0 then table.insert(faithLines, ThiefKnowledgeYieldLine(faith, sourceName)); end
	end
	if GetProperty(player, "LOTM_RP_PLAN_GOLD_ACTIVE", 0) == 1
		and GetProperty(player, "LOTM_RP_PATH", "NONE") == LOTM_RP_PATH
		and GetProperty(player, "LOTM_RP_SEQUENCE", 9) <= 6 then
		table.insert(goldLines, Locale.Lookup("LOC_LOTM_RP_PLAN_GOLD_TOOLTIP", 100));
	end
	if GetProperty(player, "LOTM_RP_ART_LETTER_WAR_GOLD_ACTIVE", 0) == 1 then
		table.insert(goldLines, Locale.Lookup("LOC_LOTM_RP_LETTER_GOLD_TOOLTIP", 50));
	end
	local codexPositive, codexNegative = GetArtifactPolarity(
		player,
		"GREATWORK_LOTM_BE_CHAOS_CODEX"
	);
	if codexPositive then
		table.insert(scienceLines, ArtifactYieldLine(
			"LOC_GREATWORK_LOTM_BE_CHAOS_CODEX_NAME", 30, false
		));
	end
	if codexNegative then
		table.insert(goldLines, ArtifactYieldLine(
			"LOC_GREATWORK_LOTM_BE_CHAOS_CODEX_NAME", -100, false
		));
	end
	local _, feastNegative = GetArtifactPolarity(
		player,
		"GREATWORK_LOTM_BE_DEPRAVED_FEAST"
	);
	if feastNegative then
		table.insert(goldLines, ArtifactYieldLine(
			"LOC_GREATWORK_LOTM_BE_DEPRAVED_FEAST_NAME", -500, false
		));
	end
	local _, frenzyNegative = GetArtifactPolarity(
		player,
		"GREATWORK_LOTM_BE_FRENZY_SCEPTER"
	);
	if frenzyNegative then
		table.insert(goldLines, ArtifactYieldLine(
			"LOC_GREATWORK_LOTM_BE_FRENZY_SCEPTER_NAME", -500, false
		));
	end
	local _, steleNegative = GetArtifactPolarity(
		player,
		"GREATWORK_LOTM_PP_CIVILIZATION_STELE"
	);
	if steleNegative then
		table.insert(goldLines, ArtifactYieldLine(
			"LOC_GREATWORK_LOTM_PP_CIVILIZATION_STELE_NAME", -500, false
		));
	end
	local converted = tonumber(GetProperty(player, "LOTM_PP_ORDER_CONVERTED_LAST", 0)) or 0;
	local orderPositive = GetArtifactPolarity(
		player,
		"GREATWORK_LOTM_BE_ORDER_CONVERTER"
	);
	if orderPositive and converted > 0 then
		local convertedLine = ArtifactYieldLine(
			"LOC_GREATWORK_LOTM_BE_ORDER_CONVERTER_NAME", converted, true
		);
		table.insert(goldLines, convertedLine);
		table.insert(scienceLines, convertedLine);
		table.insert(cultureLines, convertedLine);
	end
	local hangedFaith = tonumber(GetProperty(
		player, "LOTM_CULT_HANGED_FAITH_PER_TURN", 0
	)) or 0;
	if hangedFaith ~= 0 then
		table.insert(faithLines, Locale.Lookup(
			"LOC_LOTM_CULT_HANGED_FAITH_TOOLTIP", hangedFaith
		));
	end
	local chainedToken = tostring(GetProperty(
		player, "LOTM_CULT_APPLIED_CHAINED_YIELD", "NONE"
	));
	local chainedPercent = tonumber(string.match(
		chainedToken, "^CHAINED_YIELD_T3_P(%d+)$"
	));
	if chainedPercent ~= nil and chainedPercent > 0 then
		local line = Locale.Lookup(
			"LOC_LOTM_CULT_CHAINED_TOP_YIELD_TOOLTIP", chainedPercent
		);
		table.insert(scienceLines, line);
		table.insert(cultureLines, line);
	end

	local goldBacking = FindYieldBacking(yieldStack, "LOC_TOP_PANEL_GOLD_YIELD");
	if goldBacking ~= nil then
		goldBacking:SetToolTipString(AppendYieldSources(GetGoldTooltip(), goldLines, true));
	end
	local scienceBacking = FindYieldBacking(yieldStack, "LOC_TOP_PANEL_SCIENCE_YIELD");
	if scienceBacking ~= nil then
		scienceBacking:SetToolTipString(AppendYieldSources(
			GetScienceTooltip(), scienceLines, false
		));
	end
	local cultureBacking = FindYieldBacking(yieldStack, "LOC_TOP_PANEL_CULTURE_YIELD");
	if cultureBacking ~= nil then
		cultureBacking:SetToolTipString(AppendYieldSources(
			GetCultureTooltip(), cultureLines, false
		));
	end
	local faithBacking = FindYieldBacking(yieldStack, "LOC_TOP_PANEL_FAITH_YIELD");
	if faithBacking ~= nil then
		faithBacking:SetToolTipString(AppendYieldSources(
			GetFaithTooltip(), faithLines, false
		));
	end
end

local m_ceremonyVisible = false;
local m_finalChoiceWaiting = false;
local function RefreshFinalChoice()
	local _, player = GetLocalPlayer();
	local branch = player ~= nil and tostring(GetProperty(player, "LOTM_TP_FINAL_BRANCH", "NONE")) or "NONE";
	local show = player ~= nil and GetProperty(player, "LOTM_RP_PATH", "NONE") == LOTM_TP_PATH
		and tonumber(GetProperty(player, "LOTM_RP_SEQUENCE", 9)) == 0
		and GetProperty(Game, "LOTM_RESCUE_MODE", 0) ~= 1
		and branch == "NONE"
		and tonumber(GetProperty(player, "LOTM_RP_SEQUENCE0_CEREMONY_ACK_SERIAL", 0)) >= tonumber(GetProperty(player, "LOTM_RP_SEQUENCE0_CEREMONY_SERIAL", 0))
		and not m_ceremonyVisible and player:IsTurnActive();
	Controls.ThiefFinalPopup:SetHide(not show);
	if Controls.ThiefFinalEffect ~= nil then
		Controls.ThiefFinalEffect:SetText(Locale.Lookup("LOC_LOTM_TP_FINAL_EFFECT_PREFIX") .. GetFinalBranchEffect(branch));
	end
	for _, button in ipairs({Controls.ThiefFinalTech, Controls.ThiefFinalFaith, Controls.ThiefFinalCulture}) do button:SetDisabled(m_finalChoiceWaiting); end
end
local function ChooseFinalBranch(branch)
	local playerID, player = GetLocalPlayer();
	if m_finalChoiceWaiting or player == nil or Controls.ThiefFinalPopup:IsHidden() or not player:IsTurnActive() then return; end
	m_finalChoiceWaiting = true; RefreshFinalChoice();
	UI.RequestPlayerOperation(playerID, PlayerOperations.EXECUTE_SCRIPT, {OnStart="LOTM_TP_Command_ChooseFinalBranch", Branch=branch});
end

local m_tourismObservedOwner = -1;
local m_tourismObservedSerial = -1;
local m_tourismObservedTurn = -1;
local m_tourismPrevious = nil;
local m_tourismAwaitingTurn = false;
local function ObserveTourism()
	local playerID, player = GetLocalPlayer();
	if player == nil or GetProperty(player, "LOTM_RP_PATH", "NONE") ~= LOTM_TP_PATH then return; end
	local ok, tourists = pcall(function() return player:GetCulture():GetTouristsTo(); end);
	if not ok then return; end
	local serial = tonumber(GetProperty(player, "LOTM_TP_TOURISM_SERIAL", 0)) or 0;
	local turn = Game.GetCurrentGameTurn();
	if m_tourismObservedOwner ~= playerID then
		m_tourismObservedOwner = playerID; m_tourismObservedSerial = serial;
		m_tourismPrevious = tourists; m_tourismObservedTurn = turn; m_tourismAwaitingTurn = false;
		print("[LOTM_TP][TourismUI] baseline tourists=" .. tostring(tourists) .. " serial=" .. serial);
	elseif serial ~= m_tourismObservedSerial or (m_tourismAwaitingTurn and turn > m_tourismObservedTurn) then
		print("[LOTM_TP][TourismUI] serial=" .. serial .. " turn=" .. turn .. " previous=" .. tostring(m_tourismPrevious)
			.. " current=" .. tostring(tourists) .. " delta=" .. tostring(tourists - m_tourismPrevious)
			.. " phase=" .. (serial ~= m_tourismObservedSerial and "PROJECT_PUBLISHED" or "NEXT_TURN"));
		for _, source in ipairs(PlayerManager.GetWasEverAliveMajors() or {}) do
			if source:GetID() ~= playerID then
				local readOK, value = pcall(function() return player:GetCulture():GetTouristsFrom(source:GetID()); end);
				if readOK then print("[LOTM_TP][TourismUI] source=" .. source:GetID() .. " tourists=" .. tostring(value)); end
			end
		end
		m_tourismAwaitingTurn = serial ~= m_tourismObservedSerial;
		m_tourismObservedSerial = serial; m_tourismObservedTurn = turn;
	end
	m_tourismPrevious = tourists;
end

local function OnPublishComplete()
	m_finalChoiceWaiting = false;
	RefreshFinalChoice();
	ObserveTourism();
	m_borrowWaiting = false;
	PollDiplomacyChanges();
	Refresh();
	RefreshBurnMarkers(false);
	RefreshYieldTooltips();
	OpenBorrowAbilityPopup();
end

local function OnDiplomacyStatement()
	-- Sequence 8 digestion still observes the original denouncement turn.
	-- War-planning gold is handled authoritatively by synchronized Gameplay.
	PollDiplomacyChanges();
end

local function OnPantheonFounded(playerID :number, beliefID :number)
	local localPlayerID, player = GetLocalPlayer();
	local churchBelief = GameInfo.Beliefs[LOTM_RP_CHURCH_BELIEF];
	if player == nil
		or playerID ~= localPlayerID
		or not IsPathVisible(player)
		or churchBelief == nil
		or beliefID ~= churchBelief.Index then
		return;
	end
	local parameters :table = {};
	parameters.OnStart = LOTM_RP_CHURCH_COMMAND_NAME;
	parameters.BeliefID = beliefID;
	UI.RequestPlayerOperation(
		localPlayerID,
		PlayerOperations.EXECUTE_SCRIPT,
		parameters
	);
end

local function Initialize()
	ContextPtr:SetHide(false);
	if Controls.ModalScreenClose ~= nil then Controls.ModalScreenClose:SetHide(true); end
	ResizeDetailsPopup();
	ContextPtr:SetInputHandler(OnInputHandler, true);
	Controls.CloseButton:RegisterCallback(Mouse.eLClick, CloseDetails);
	local rescueActionStack=ContextPtr:LookUpControl("/InGame/UnitPanel/StandardActionsStack");
	if rescueActionStack~=nil and Controls.RescueCampActionButton~=nil then Controls.RescueCampActionButton:ChangeParent(rescueActionStack); end
	if Controls.RescueCampActionButton~=nil then Controls.RescueCampActionButton:RegisterCallback(Mouse.eLClick,SubmitRescueCampAction); end
	Controls.LocateHeroButton:RegisterCallback(Mouse.eLClick, LocateHero);
	Controls.ArsonButton:RegisterCallback(Mouse.eLClick, BeginTargeting);
	Controls.PlanTargetButton:RegisterCallback(Mouse.eLClick, function()
		local _, player = GetLocalPlayer();
		if player ~= nil and GetProperty(player, "LOTM_RP_PATH", "NONE") == LOTM_TP_PATH then
			ChooseNextThiefTarget();
		else
			ChooseNextPlanTarget();
		end
	end);
	Controls.BorrowAbilityConfirm:RegisterCallback(Mouse.eLClick, ConfirmBorrowAbility);
	Controls.AllAbilitiesButton:RegisterCallback(Mouse.eLClick, function() OpenBorrowAbilityPopup(true); end);
	if Controls.PurificationButton ~= nil then
		Controls.PurificationButton:RegisterCallback(Mouse.eLClick, function()
			LuaEvents.LOTM_RESCUE_EnergyPanel_Open();
		end);
	end
	Controls.ThiefFinalTech:RegisterCallback(Mouse.eLClick, function() ChooseFinalBranch("TECH_CIVIC"); end);
	Controls.ThiefFinalFaith:RegisterCallback(Mouse.eLClick, function() ChooseFinalBranch("FAITH"); end);
	Controls.ThiefFinalCulture:RegisterCallback(Mouse.eLClick, function() ChooseFinalBranch("CULTURE"); end);
	LuaEvents.LOTM_RP_Sequence0Ceremony_Shown.Add(function() m_ceremonyVisible = true; RefreshFinalChoice(); end);
	LuaEvents.LOTM_RP_Sequence0Ceremony_Closed.Add(function() m_ceremonyVisible = false; RefreshFinalChoice(); end);
	-- TEST ONLY: Gameplay owns the actual modifier/state mutation.
	Controls.TestCombatButton:RegisterCallback(Mouse.eLClick, ToggleTestCombat);
	Controls.ComicButton:RegisterCallback(Mouse.eLClick, function()
		if GetProperty(Game, "LOTM_RESCUE_MODE", 0) ~= 1 then return; end
		CloseDetails();
		LuaEvents.LOTM_Comic_ShowReview("START");
	end);
	Controls.ManualButton:RegisterCallback(Mouse.eLClick, function()
		CloseDetails();
		LuaEvents.InGameTopOptionsMenu_ShowExpansionIntro();
	end);
	LuaEvents.LOTM_RP_UI_ToggleDetails.Add(ToggleDetails);
	LuaEvents.LOTM_Comic_ReturnToSequence.Add(OpenDetails);
	Events.UnitSelectionChanged.Add(Refresh);
	Events.LocalPlayerTurnBegin.Add(OnPublishComplete);
	Events.GameCoreEventPublishComplete.Add(OnPublishComplete);
	Events.LoadGameViewStateDone.Add(OnPublishComplete);
	Events.DiplomacyDeclareWar.Add(OnPublishComplete);
	Events.DiplomacyMakePeace.Add(OnPublishComplete);
	Events.TreasuryChanged.Add(RefreshYieldTooltips);
	Events.PlayerResourceChanged.Add(OnPublishComplete);
	Events.DiplomacyStatement.Add(OnDiplomacyStatement);
	Events.DiplomacySessionClosed.Add(PollDiplomacyChanges);
	Events.PantheonFounded.Add(OnPantheonFounded);
	PollDiplomacyChanges();
	Refresh();
	RefreshBurnMarkers(true);
	RefreshYieldTooltips();
end

Initialize();
-- BEGIN RC342 STARTUP TRACE

end
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("LOTM_RP_HUD","CONTEXT END");
-- END RC342 STARTUP TRACE
