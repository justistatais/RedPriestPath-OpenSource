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
LOTM_StartupTrace.Mark("LOTM_RP_Manual","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"LOTM_RP_Manual","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"LOTM_RP_Manual","GameEvents");
local LuaEvents = LOTM_StartupTrace.Events(LuaEvents,"LOTM_RP_Manual","LuaEvents");
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
do
-- END RC342 STARTUP TRACE
-- LOTM manual using the Gathering Storm expansion-intro presentation.
-- All persistence is local UI state. Gameplay is read only to select the
-- ordinary or Rescue-specific book; this context never mutates Gameplay.

local RULESET_TYPE :string = "RULESET_EXPANSION_2";
local OPTIONS_HIDE_KEY :string = "HideLOTMFeaturesScreen";
local OPTIONS_LAST_GAME_KEY :string = "LastShownLOTMGameSignature";
local RESCUE_OPTIONS_HIDE_KEY :string = "HideLOTMRescueFeaturesScreen";
local RESCUE_OPTIONS_LAST_GAME_KEY :string = "LastShownLOTMRescueGameSignature";
local STANDARD_NUM_PAGES :number = 13;
local RESCUE_NUM_PAGES :number = 9;
local m_pageIndex :number = 1;
local m_numPages :number = STANDARD_NUM_PAGES;
local m_isRescue :boolean = false;

local STANDARD_PAGES :table = {};
for i:number = 1, STANDARD_NUM_PAGES do
	STANDARD_PAGES[i] = {
		title = "LOC_LOTM_MANUAL_PAGE_" .. i .. "_TITLE",
		summary = "LOC_LOTM_MANUAL_PAGE_" .. i .. "_SUMMARY",
		details = "LOC_LOTM_MANUAL_PAGE_" .. i .. "_DETAILS",
	};
end

local RESCUE_PAGES :table = {};
for i:number = 1, RESCUE_NUM_PAGES do
	RESCUE_PAGES[i] = {
		title = "LOC_LOTM_RESCUE_MANUAL_PAGE_" .. i .. "_TITLE",
		summary = "LOC_LOTM_RESCUE_MANUAL_PAGE_" .. i .. "_SUMMARY",
		details = "LOC_LOTM_RESCUE_MANUAL_PAGE_" .. i .. "_DETAILS",
	};
end
local m_pages :table = STANDARD_PAGES;

local CONCEPT_ICONS :table = {
	"ICON_UNIT_LOTM_PP_PATH_HOLDER",
	"ICON_UNIT_LOTM_RP_PATH_HOLDER",
	"ICON_UNIT_LOTM_BE_PATH_HOLDER",
};

local PAGE_CONCEPT_ICONS :table = {
	[7] = {"ICON_LOTM_CHURCH_FOOL", "ICON_LOTM_CHURCH_NIGHT", "ICON_LOTM_CHURCH_STORM"},
	[8] = {"ICON_LOTM_CULT_DEMONESS", "ICON_LOTM_CULT_HANGED_MAN", "ICON_LOTM_CULT_CHAINED"},
};

local RESCUE_PAGE_CONCEPT_ICONS :table = {
	[1] = {"ICON_UNIT_LOTM_PP_PATH_HOLDER", "ICON_UNIT_LOTM_RP_PATH_HOLDER", "ICON_UNIT_LOTM_BE_PATH_HOLDER"},
	[2] = {"ICON_LOTM_CHURCH_FOOL", "ICON_LOTM_CHURCH_NIGHT", "ICON_LOTM_CHURCH_STORM"},
	[3] = {"ICON_UNIT_LOTM_PP_PATH_HOLDER", "ICON_UNIT_LOTM_RP_PATH_HOLDER", "ICON_UNIT_LOTM_BE_PATH_HOLDER"},
	[4] = {"ICON_UNIT_LOTM_RESCUE_FOOL_SAINT", "ICON_UNIT_LOTM_RESCUE_NIGHT_ANGEL", "ICON_UNIT_LOTM_RESCUE_STORM_SAINT"},
	[5] = {"ICON_UNIT_LOTM_PP_PATH_HOLDER", "ICON_UNIT_LOTM_RP_PATH_HOLDER", "ICON_UNIT_LOTM_BE_PATH_HOLDER"},
	[6] = {"ICON_UNIT_LOTM_PP_PATH_HOLDER", "ICON_UNIT_LOTM_RP_PATH_HOLDER", "ICON_UNIT_LOTM_BE_PATH_HOLDER"},
	[7] = {"ICON_UNIT_LOTM_RESCUE_GOD_PERFECT", "ICON_UNIT_LOTM_RESCUE_GOD_RED_PRIEST", "ICON_UNIT_LOTM_RESCUE_GOD_BLACK_EMPEROR"},
	[8] = {"ICON_UNIT_LOTM_RESCUE_GOD_FOOL", "ICON_UNIT_LOTM_RESCUE_GOD_NIGHT", "ICON_UNIT_LOTM_RESCUE_GOD_STORM"},
	[9] = {"ICON_UNIT_LOTM_PP_PATH_HOLDER", "ICON_UNIT_LOTM_RP_PATH_HOLDER", "ICON_UNIT_LOTM_BE_PATH_HOLDER"},
};

local CONCEPT_LAYOUT :table = {
	{x=20,y=48}, {x=272,y=48}, {x=146,y=292},
};

local PAGE_CONCEPT_LAYOUT :table = {
	[7] = {{x=146,y=48}, {x=20,y=292}, {x=272,y=292}},
	[8] = {{x=146,y=48}, {x=20,y=292}, {x=272,y=292}},
};

local PAGE_CONCEPT_DISPLAY_SIZES :table = {
	[8] = {200, 200, 200},
};

local PAGE_CONCEPT_ATLAS_SIZES :table = {
	[8] = {200, 200, 200},
};

local RESCUE_PAGE_CONCEPT_LAYOUT :table = {
	[8] = {{x=146,y=48}, {x=20,y=292}, {x=272,y=292}},
};

local RESCUE_PAGE_CONCEPT_DISPLAY_SIZES :table = {
	[8] = {200, 200, 200},
};

local ARTIFACT_LAYOUT :table = {
	{x=62,y=58}, {x=214,y=58}, {x=366,y=58},
	{x=62,y=220}, {x=214,y=220}, {x=366,y=220},
	{x=214,y=382},
};

local ARTIFACT_PAGES :table = {
	[11] = {
		"GREATWORK_LOTM_PP_GOLDEN_APPRAISAL_MIRROR", "GREATWORK_LOTM_PP_PERPETUAL_GEARBOX",
		"GREATWORK_LOTM_PP_ERROR_ASTROLABE", "GREATWORK_LOTM_PP_HERMES_FURNACE",
		"GREATWORK_LOTM_PP_MYSTERY_BLUEPRINT", "GREATWORK_LOTM_PP_KNOWLEDGE_CASKET",
		"GREATWORK_LOTM_PP_CIVILIZATION_STELE",
	},
	[12] = {
		"GREATWORK_LOTM_RP_DISASTER_EMBER", "GREATWORK_LOTM_RP_CONSPIRATOR_LETTER",
		"GREATWORK_LOTM_RP_BLOOD_HARVEST_SICKLE", "GREATWORK_LOTM_RP_IRONBLOOD_BANNER",
		"GREATWORK_LOTM_RP_WAR_SCRIPTURE", "GREATWORK_LOTM_RP_DISASTER_WEATHER",
		"GREATWORK_LOTM_RP_CONQUEROR_CROWN",
	},
	[13] = {
		"GREATWORK_LOTM_BE_GOLDEN_BRIBE", "GREATWORK_LOTM_BE_CORRUPTION_TAXBOOK",
		"GREATWORK_LOTM_BE_CHAOS_CODEX", "GREATWORK_LOTM_BE_DEPRAVED_FEAST",
		"GREATWORK_LOTM_BE_FRENZY_SCEPTER", "GREATWORK_LOTM_BE_ENTROPY_CROWN",
		"GREATWORK_LOTM_BE_ORDER_CONVERTER",
	},
};

local ARTIFACT_EFFECTS :table = {
	GREATWORK_LOTM_PP_GOLDEN_APPRAISAL_MIRROR={pos="LOC_LOTM_PP_SHOWCASE_GOLDEN_POSITIVE",neg="LOC_LOTM_PP_SHOWCASE_GOLDEN_NEGATIVE"},
	GREATWORK_LOTM_PP_PERPETUAL_GEARBOX={pos="LOC_LOTM_PP_SHOWCASE_GEARBOX_POSITIVE",neg="LOC_LOTM_PP_SHOWCASE_GEARBOX_NEGATIVE"},
	GREATWORK_LOTM_PP_ERROR_ASTROLABE={pos="LOC_LOTM_PP_SHOWCASE_ASTROLABE_POSITIVE",neg="LOC_LOTM_PP_SHOWCASE_ASTROLABE_NEGATIVE"},
	GREATWORK_LOTM_PP_HERMES_FURNACE={pos="LOC_LOTM_PP_SHOWCASE_FURNACE_POSITIVE",neg="LOC_LOTM_PP_SHOWCASE_FURNACE_NEGATIVE"},
	GREATWORK_LOTM_PP_MYSTERY_BLUEPRINT={pos="LOC_LOTM_PP_SHOWCASE_BLUEPRINT_POSITIVE",neg="LOC_LOTM_PP_SHOWCASE_BLUEPRINT_NEGATIVE"},
	GREATWORK_LOTM_PP_KNOWLEDGE_CASKET={pos="LOC_LOTM_PP_SHOWCASE_CASKET_POSITIVE",neg="LOC_LOTM_PP_SHOWCASE_CASKET_NEGATIVE"},
	GREATWORK_LOTM_PP_CIVILIZATION_STELE={pos="LOC_LOTM_PP_SHOWCASE_STELE_POSITIVE",neg="LOC_LOTM_PP_SHOWCASE_STELE_NEGATIVE"},
	GREATWORK_LOTM_RP_DISASTER_EMBER={fx="LOC_LOTM_ARTIFACT_SHOWCASE_RP_EMBER_EFFECT"},
	GREATWORK_LOTM_RP_CONSPIRATOR_LETTER={fx="LOC_LOTM_ARTIFACT_SHOWCASE_RP_LETTER_EFFECT"},
	GREATWORK_LOTM_RP_BLOOD_HARVEST_SICKLE={fx="LOC_LOTM_ARTIFACT_SHOWCASE_RP_SICKLE_EFFECT"},
	GREATWORK_LOTM_RP_IRONBLOOD_BANNER={fx="LOC_LOTM_ARTIFACT_SHOWCASE_RP_BANNER_EFFECT"},
	GREATWORK_LOTM_RP_WAR_SCRIPTURE={fx="LOC_LOTM_ARTIFACT_SHOWCASE_RP_SCRIPTURE_EFFECT"},
	GREATWORK_LOTM_RP_DISASTER_WEATHER={fx="LOC_LOTM_ARTIFACT_SHOWCASE_RP_WEATHER_EFFECT"},
	GREATWORK_LOTM_RP_CONQUEROR_CROWN={fx="LOC_LOTM_ARTIFACT_SHOWCASE_RP_CROWN_EFFECT"},
	GREATWORK_LOTM_BE_GOLDEN_BRIBE={fx="LOC_LOTM_ARTIFACT_SHOWCASE_BE_BRIBE_EFFECT"},
	GREATWORK_LOTM_BE_CORRUPTION_TAXBOOK={fx="LOC_LOTM_ARTIFACT_SHOWCASE_BE_TAX_EFFECT"},
	GREATWORK_LOTM_BE_CHAOS_CODEX={fx="LOC_LOTM_ARTIFACT_SHOWCASE_BE_CODEX_EFFECT"},
	GREATWORK_LOTM_BE_DEPRAVED_FEAST={fx="LOC_LOTM_ARTIFACT_SHOWCASE_BE_FEAST_EFFECT"},
	GREATWORK_LOTM_BE_FRENZY_SCEPTER={fx="LOC_LOTM_ARTIFACT_SHOWCASE_BE_SCEPTER_EFFECT"},
	GREATWORK_LOTM_BE_ENTROPY_CROWN={fx="LOC_LOTM_ARTIFACT_SHOWCASE_BE_ENTROPY_EFFECT"},
	GREATWORK_LOTM_BE_ORDER_CONVERTER={fx="LOC_LOTM_ARTIFACT_SHOWCASE_BE_ORDER_EFFECT"},
};

local ART_CONTROLS :table = {
	Controls.Artifact1, Controls.Artifact2, Controls.Artifact3, Controls.Artifact4,
	Controls.Artifact5, Controls.Artifact6, Controls.Artifact7,
};

local function ResizeLayout()
	if UIManager==nil or UIManager.GetScreenSizeVal==nil then return; end
	local screenX,screenY=UIManager:GetScreenSizeVal();
	local width=math.floor(math.min(1056,math.max(720,screenX-24)));
	local height=math.floor(math.min(800,math.max(560,screenY-32)));
	local compact=height<760;
	local columnH=math.max(410,height-250);
	Controls.Background:SetSizeVal(width,height);
	Controls.IllustrationPanel:SetSizeVal(492,columnH);
	Controls.DescriptionColumn:SetSizeVal(492,columnH);
	Controls.IllustrationPanel:SetOffsetY(compact and 132 or 160);
	Controls.DescriptionColumn:SetOffsetY(compact and 142 or 170);
	Controls.TopDescription:SetSizeY(compact and 150 or 190);
	Controls.FrameDeco:SetSizeY(math.max(210,columnH-(compact and 150 or 190)));
	Controls.ManualTitle:SetOffsetY(compact and 34 or 55);
	Controls.PageTitle:SetOffsetY(compact and 82 or 112);
	Controls.Close:SetOffsetY(compact and -2 or -5);
	print("[LOTM_RP][Manual] resized screen="..screenX.."x"..screenY.." background="..width.."x"..height.." columnH="..columnH);
end

local function SetIcon(control:table, iconName:string, size:number)
	local x:number, y:number, sheet:string = IconManager:FindIconAtlas(iconName, size);
	if sheet == nil or sheet == "" then
		print("[LOTM_RP][Manual] icon miss " .. tostring(iconName) .. " size=" .. tostring(size));
		control:SetHide(true);
		return;
	end
	control:SetTexture(x, y, sheet);
	control:SetHide(false);
end

local function ArtifactDetails(types:table)
	local lines:table = {};
	for _, artifactType:string in ipairs(types) do
		local row:table = GameInfo.GreatWorks[artifactType];
		local data:table = ARTIFACT_EFFECTS[artifactType];
		if row ~= nil and data ~= nil then
			local effect:string;
			if data.fx ~= nil then
				effect = Locale.Lookup(data.fx);
			else
				effect = Locale.Lookup("LOC_LOTM_MANUAL_POS_NEG", Locale.Lookup(data.pos), Locale.Lookup(data.neg));
			end
			table.insert(lines, Locale.Lookup("LOC_LOTM_MANUAL_ARTIFACT_LINE", Locale.Lookup(row.Name), effect));
		end
	end
	return table.concat(lines, "[NEWLINE][NEWLINE]");
end

local function RescueActive()
	return tonumber(Game.GetProperty("LOTM_RESCUE_MODE") or 0) == 1;
end

local function ConfigureBook()
	m_isRescue = RescueActive();
	m_numPages = m_isRescue and RESCUE_NUM_PAGES or STANDARD_NUM_PAGES;
	m_pages = m_isRescue and RESCUE_PAGES or STANDARD_PAGES;
	Controls.ManualTitle:SetText(Locale.Lookup(m_isRescue and "LOC_LOTM_RESCUE_MANUAL_TITLE" or "LOC_LOTM_MANUAL_TITLE"));
	Controls.DontShowAgainLabel:SetText(Locale.Lookup(m_isRescue and "LOC_LOTM_RESCUE_MANUAL_HIDE" or "LOC_LOTM_MANUAL_HIDE"));
	local hideKey:string = m_isRescue and RESCUE_OPTIONS_HIDE_KEY or OPTIONS_HIDE_KEY;
	Controls.DontShowAgain:SetCheck(tonumber(Options.GetUserOption("Tutorial", hideKey) or 0) == 1);
end

local function Realize()
	ResizeLayout();
	local page:table = m_pages[m_pageIndex];
	Controls.PageTitle:SetText(Locale.Lookup(page.title));
	Controls.Description:SetText(Locale.Lookup(page.summary));
	local details:string = Locale.Lookup(page.details);
	if not m_isRescue and m_pageIndex==8 then
		local difficulty=Game.GetProperty("LOTM_CULT_DIFFICULTY");
		if difficulty~="HARD" and difficulty~="INSANE" then difficulty="EASY"; end
		details=Locale.Lookup("LOC_LOTM_CULT_DIFFICULTY_CURRENT",Locale.Lookup("LOC_LOTM_CULT_DIFFICULTY_"..difficulty.."_NAME"))
			.."[NEWLINE]"..Locale.Lookup("LOC_LOTM_CULT_DIFFICULTY_"..difficulty.."_MANUAL").."[NEWLINE][NEWLINE]"..details;
	end
	local artifacts:table = not m_isRescue and ARTIFACT_PAGES[m_pageIndex] or nil;
	for _, control:table in ipairs(ART_CONTROLS) do control:SetHide(true); end
	if artifacts ~= nil then
		for i:number, artifactType:string in ipairs(artifacts) do
			local control:table = ART_CONTROLS[i];
			control:SetSizeX(64); control:SetSizeY(64);
			control:SetOffsetX(ARTIFACT_LAYOUT[i].x); control:SetOffsetY(ARTIFACT_LAYOUT[i].y);
			SetIcon(control, "ICON_" .. artifactType, 64);
		end
		details = details .. "[NEWLINE][NEWLINE]" .. ArtifactDetails(artifacts);
	else
		local conceptIcons:table = m_isRescue and RESCUE_PAGE_CONCEPT_ICONS[m_pageIndex] or PAGE_CONCEPT_ICONS[m_pageIndex] or CONCEPT_ICONS;
		local conceptLayout:table = m_isRescue and RESCUE_PAGE_CONCEPT_LAYOUT[m_pageIndex] or PAGE_CONCEPT_LAYOUT[m_pageIndex] or CONCEPT_LAYOUT;
		local displaySizes:table = m_isRescue and RESCUE_PAGE_CONCEPT_DISPLAY_SIZES[m_pageIndex] or PAGE_CONCEPT_DISPLAY_SIZES[m_pageIndex];
		local atlasSizes:table = PAGE_CONCEPT_ATLAS_SIZES[m_pageIndex];
		for i:number, iconName:string in ipairs(conceptIcons) do
			local control:table = ART_CONTROLS[i];
			local displaySize:number = displaySizes ~= nil and displaySizes[i] or 200;
			local atlasSize:number = atlasSizes ~= nil and atlasSizes[i] or 200;
			control:SetSizeX(displaySize); control:SetSizeY(displaySize);
			control:SetOffsetX(conceptLayout[i].x); control:SetOffsetY(conceptLayout[i].y);
			SetIcon(control, iconName, atlasSize);
		end
	end
	Controls.Description2:SetText(details);
	Controls.DetailScroll:SetScrollValue(0);
	Controls.Next:SetText(Locale.Lookup(m_pageIndex == m_numPages and "LOC_LOTM_MANUAL_CONTINUE" or "LOC_LOTM_MANUAL_NEXT"));
	Controls.Previous:SetHide(m_pageIndex == 1);
	Controls.ButtonStack:CalculateSize();
end

local function Close()
	UIManager:DequeuePopup(ContextPtr);
end

local function Show(priority:number)
	ConfigureBook();
	m_pageIndex = 1;
	Realize();
	UIManager:QueuePopup(ContextPtr, priority);
end

local function CurrentGameSignature()
	local gameSeed:number = tonumber(GameConfiguration.GetValue("GAME_SYNC_RANDOM_SEED")) or 0;
	local mapSeed:number = tonumber(MapConfiguration.GetValue("RANDOM_SEED")) or tonumber(GameConfiguration.GetValue("MAP_RANDOM_SEED")) or 0;
	local startTurn:number = tonumber(GameConfiguration.GetStartTurn()) or 0;
	local localPlayer:number = tonumber(Game.GetLocalPlayer()) or -1;
	return math.floor((gameSeed * 31 + mapSeed * 17 + startTurn * 13 + localPlayer + 2147483647) % 2147483647);
end

local function OnLoadGameViewStateDone()
	local localPlayer:number = Game.GetLocalPlayer();
	local rescue:boolean = RescueActive();
	local hideKey:string = rescue and RESCUE_OPTIONS_HIDE_KEY or OPTIONS_HIDE_KEY;
	local lastGameKey:string = rescue and RESCUE_OPTIONS_LAST_GAME_KEY or OPTIONS_LAST_GAME_KEY;
	local hideOption = Options.GetUserOption("Tutorial", hideKey);
	local showScreen:boolean = GameConfiguration.GetRuleSet() == RULESET_TYPE
		and not GameConfiguration.IsAnyMultiplayer()
		and localPlayer ~= nil and localPlayer >= 0
		and Game.GetCurrentGameTurn() == GameConfiguration.GetStartTurn()
		and tonumber(hideOption or 0) ~= 1;
	print("[LOTM_RP][Manual] load check show=" .. tostring(showScreen) .. " hide=" .. tostring(hideOption) .. " turn=" .. tostring(Game.GetCurrentGameTurn()) .. " start=" .. tostring(GameConfiguration.GetStartTurn()));
	if not showScreen then return; end
	local signature:number = CurrentGameSignature();
	local lastShownOption = Options.GetUserOption("Tutorial", lastGameKey);
	if tonumber(lastShownOption or -1) == signature then
		print("[LOTM_RP][Manual] automatic display already completed signature=" .. tostring(signature));
		return;
	end
	Options.SetUserOption("Tutorial", lastGameKey, signature);
	Options.SaveOptions();
	print("[LOTM_RP][Manual] automatic display queued signature=" .. tostring(signature));
	Show(PopupPriority.TutorialHigh);
end

local function Initialize()
	ContextPtr:SetHide(true);
	ContextPtr:SetInputHandler(function(input:table)
		if input:GetMessageType() == KeyEvents.KeyUp and input:GetKey() == Keys.VK_ESCAPE then Close(); end
		return true;
	end, true);
	Controls.Close:RegisterCallback(Mouse.eLClick, Close);
	Controls.Next:RegisterCallback(Mouse.eLClick, function()
		if m_pageIndex >= m_numPages then Close(); else m_pageIndex = m_pageIndex + 1; Realize(); end
	end);
	Controls.Previous:RegisterCallback(Mouse.eLClick, function()
		m_pageIndex = math.max(1, m_pageIndex - 1); Realize();
	end);
	for _, control:table in ipairs({Controls.Close, Controls.Next, Controls.Previous}) do
		control:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	end
	Controls.DontShowAgain:RegisterCheckHandler(function(checked:boolean)
		local hideKey:string = m_isRescue and RESCUE_OPTIONS_HIDE_KEY or OPTIONS_HIDE_KEY;
		Options.SetUserOption("Tutorial", hideKey, checked and 1 or 0);
		Options.SaveOptions();
	end);
	Events.LoadGameViewStateDone.Add(OnLoadGameViewStateDone);
	LuaEvents.InGameTopOptionsMenu_ShowExpansionIntro.Add(function() Show(PopupPriority.Current); end);
	LuaEvents.DiplomacyActionView_HideIngameUI.Add(function() if not ContextPtr:IsHidden() then Close(); end end);
end

Initialize();
-- BEGIN RC342 STARTUP TRACE

end
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("LOTM_RP_Manual","CONTEXT END");
-- END RC342 STARTUP TRACE
