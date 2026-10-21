-- BEGIN RC342 STARTUP TRACE
-- Optional startup diagnostics, resource 393. Embedded by generate_startup_trace.py so a
-- missing VFS import cannot hide the first startup checkpoint.
-- Keep disabled in releases: high-frequency UI tracing caused severe stutter.
-- To diagnose a new failure, enable and rerun both startup/bundle generators.
if LOTM_StartupTrace == nil then
	LOTM_StartupTrace = { Enabled=false, Resource=393 };
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
		print("[LOTM_DIAG] r=393 seq=" .. sequence .. " ctx=" .. context
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
LOTM_StartupTrace.Mark("LOTM_RP_Sequence0Ceremony","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"LOTM_RP_Sequence0Ceremony","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"LOTM_RP_Sequence0Ceremony","GameEvents");
local LuaEvents = LOTM_StartupTrace.Events(LuaEvents,"LOTM_RP_Sequence0Ceremony","LuaEvents");
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
do
-- END RC342 STARTUP TRACE
-- Local-only presentation for the synchronized Sequence 0 advancement.
-- Gameplay properties are read here; acknowledgement is submitted through
-- PlayerOperations.EXECUTE_SCRIPT and validated again in Gameplay.

local LOTM_RP_COMMAND :string =
	"LOTM_RP_Command_AcknowledgeSequence0Ceremony";
local LOTM_RP_PATH :string = "PATH_RED_PRIEST";
local LOTM_PP_PATH :string = "PATH_PERFECT";
local LOTM_BE_PATH :string = "PATH_BLACK_EMPEROR";
local LOTM_TP_PATH :string = "PATH_THIEF";
local LOTM_TP_ICON :string = "ICON_LOTM_TP_THIEF_MARK";
local LOTM_RP_ICON :string = "ICON_LOTM_RP_RED_PRIEST_MARK";
local LOTM_PP_ICON :string = "ICON_LOTM_PP_PERFECT_MARK";
local LOTM_BE_ICON :string = "ICON_LOTM_BE_BLACK_EMPEROR_MARK";
local m_isClosing :boolean = false;
local m_lastShownSerial :number = 0;
local m_isQueued :boolean = false;
local m_pendingPlayerID :number = -1;
local m_pendingSerial :number = 0;
local m_pendingPath :string = LOTM_RP_PATH;
local SubmitAcknowledgement;
local TryShow;

local function GetLocalPlayer()
	local playerID = Game.GetLocalPlayer();
	if playerID == nil or playerID < 0 then
		return -1, nil;
	end
	return playerID, Players[playerID];
end

local function FinishClose()
	if m_isQueued or not ContextPtr:IsHidden() then
		UIManager:DequeuePopup(ContextPtr);
	end
	m_isQueued = false;
	m_pendingPlayerID = -1;
	m_pendingSerial = 0;
	m_pendingPath = LOTM_RP_PATH;
	Controls.CeremonyAnimation:Stop();
	Controls.ContentSlide:Stop();
	LuaEvents.LOTM_RP_Sequence0Ceremony_Closed();
end

local function OnCeremonyAnimationEnd()
	if m_isClosing and Controls.CeremonyAnimation:IsReversing() then
		FinishClose();
	end
end

local function OnContinue()
	if m_isClosing then
		return;
	end
	m_isClosing = true;
	if m_pendingPlayerID >= 0 and m_pendingSerial > 0 then
		SubmitAcknowledgement(m_pendingPlayerID, m_pendingSerial);
	end
	Controls.CeremonyAnimation:Reverse();
end

local function OnShow()
	-- Do not acknowledge while merely queued.  Firaxis' era/age popups use a
	-- higher priority and may keep this context waiting for several seconds.
	-- Acknowledging here proves that the ceremony actually became visible.
	if m_pendingPlayerID >= 0 and m_pendingSerial > 0 then
		m_lastShownSerial = m_pendingSerial;
		LuaEvents.LOTM_RP_Sequence0Ceremony_Shown(m_pendingSerial);
	end
	UI.PlaySound("Pause_TechCivic_Speech");
	UI.PlaySound("UI_Era_Change");
	Controls.CeremonyAnimation:SetToBeginning();
	Controls.CeremonyAnimation:Play();
	Controls.ContentAlpha:SetToBeginning();
	Controls.ContentAlpha:Play();
	Controls.ContentSlide:SetBeginVal(0, 50);
	Controls.ContentSlide:SetEndVal(0, 0);
	Controls.ContentSlide:SetToBeginning();
	Controls.ContentSlide:Play();
end

local function SelectCeremonyIconSize(screenY :number)
	local targetSize = screenY * 0.46;
	if targetSize <= 448 then
		return 384;
	elseif targetSize <= 576 then
		return 512;
	elseif targetSize <= 704 then
		return 640;
	end
	return 768;
end

local function Resize()
	local screenX, screenY = UIManager:GetScreenSizeVal();
	local artSize = SelectCeremonyIconSize(screenY);
	local panelHeight =
		math.floor(math.min(screenY - 24, math.max(680, artSize + 340)));
	local panelWidth = math.floor(math.min(screenX - 24, math.max(820, artSize + 260)));
	local titleOffset = -math.floor(artSize * 0.68);
	local firstLineOffset = math.floor(artSize * 0.45);
	local lineStep = math.max(32, math.floor(screenY * 0.033));
	local isPerfect = m_pendingPath == LOTM_PP_PATH;
	local isBlackEmperor = m_pendingPath == LOTM_BE_PATH;
	local continueOffset =
		firstLineOffset + lineStep * (isPerfect and 2 or 3) + 54;

	Controls.CeremonyBackdrop:SetSizeVal(panelWidth, panelHeight);
	Controls.GradientT:SetSizeX(panelWidth);
	Controls.GradientB:SetSizeX(panelWidth);
	Controls.CeremonyMark:SetSizeVal(artSize, artSize);
	Controls.CeremonyMark:SetOffsetY(-math.floor(artSize * 0.09));
	local ceremonyIcon = isPerfect and LOTM_PP_ICON
		or (isBlackEmperor and LOTM_BE_ICON or (m_pendingPath == LOTM_TP_PATH and LOTM_TP_ICON or LOTM_RP_ICON));
	local offsetX, offsetY, textureSheet =
		IconManager:FindIconAtlas(
			ceremonyIcon,
			artSize
		);
	if textureSheet ~= nil and textureSheet ~= "" then
		Controls.CeremonyMark:SetTexture(offsetX, offsetY, textureSheet);
	end
	Controls.CeremonyTitle:SetOffsetY(titleOffset);
	Controls.CeremonyLine1:SetOffsetY(firstLineOffset);
	Controls.CeremonyLine2:SetOffsetY(firstLineOffset + lineStep);
	Controls.CeremonyLine3:SetOffsetY(firstLineOffset + lineStep * 2);
	Controls.CeremonyLine4:SetOffsetY(firstLineOffset + lineStep * 3);
	Controls.CeremonyLine4:SetHide(isPerfect);
	Controls.ContinueButton:SetOffsetY(continueOffset);
end

local function ConfigureCeremony(path :string)
	local isPerfect = path == LOTM_PP_PATH;
	local isBlackEmperor = path == LOTM_BE_PATH;
	local prefix = isPerfect and "LOC_LOTM_PP_SEQUENCE0_CEREMONY_"
		or (isBlackEmperor and "LOC_LOTM_BE_SEQUENCE0_CEREMONY_"
		or "LOC_LOTM_RP_SEQUENCE0_CEREMONY_");
	local color = isPerfect and UI.GetColorValue(1, 0.72, 0, 1)
		or (isBlackEmperor and UI.GetColorValue(0.68, 0.24, 1, 1)
		or UI.GetColorValue(1, 0.22, 0.16, 1));
	Controls.CeremonyTitle:SetText(Locale.Lookup(prefix .. "TITLE"));
	Controls.CeremonyLine1:SetText(Locale.Lookup(prefix .. "LINE_1"));
	Controls.CeremonyLine2:SetText(Locale.Lookup(prefix .. "LINE_2"));
	Controls.CeremonyLine3:SetText(Locale.Lookup(prefix .. "LINE_3"));
	Controls.CeremonyLine4:SetText(
		isPerfect and "" or Locale.Lookup(prefix .. "LINE_4")
	);
	Controls.CeremonyTitle:SetColor(color);
	if path == LOTM_TP_PATH then
		Controls.CeremonyTitle:SetText(Locale.Lookup("LOC_LOTM_TP_CEREMONY_TITLE"));
		for i = 1, 4 do Controls["CeremonyLine" .. i]:SetText(Locale.Lookup("LOC_LOTM_TP_CEREMONY_LINE_" .. i)); end
		color = UI.GetColorValue(0.28, 0.86, 1, 1);
		Controls.CeremonyTitle:SetColor(color);
	end
	Controls.CeremonyLine1:SetColor(color);
	Controls.CeremonyLine2:SetColor(color);
	Controls.CeremonyLine3:SetColor(color);
	Controls.CeremonyLine4:SetColor(color);
end

SubmitAcknowledgement = function(playerID :number, serial :number)
	local parameters :table = {};
	parameters.OnStart = LOTM_RP_COMMAND;
	parameters.Serial = serial;
	UI.RequestPlayerOperation(
		playerID,
		PlayerOperations.EXECUTE_SCRIPT,
		parameters
	);
end

TryShow = function()
	if m_isQueued
		or UIManager:IsInPopupQueue(ContextPtr)
		or not ContextPtr:IsHidden() then
		return;
	end
	local playerID, player = GetLocalPlayer();
	if player == nil or not player:IsAlive() or not player:IsMajor() then
		return;
	end
	local serial =
		player:GetProperty("LOTM_RP_SEQUENCE0_CEREMONY_SERIAL") or 0;
	local acknowledged =
		player:GetProperty("LOTM_RP_SEQUENCE0_CEREMONY_ACK_SERIAL") or 0;
	local readyTurn =
		player:GetProperty("LOTM_RP_SEQUENCE0_CEREMONY_READY_TURN") or -1;
	local path = player:GetProperty("LOTM_RP_PATH") or "NONE";
	if (path ~= LOTM_RP_PATH and path ~= LOTM_PP_PATH
		and path ~= LOTM_BE_PATH and path ~= LOTM_TP_PATH)
		or (player:GetProperty("LOTM_RP_SEQUENCE") or 9) ~= 0
		or serial <= 0
		or serial <= acknowledged
		or serial <= m_lastShownSerial
		or readyTurn < 0
		or Game.GetCurrentGameTurn() < readyTurn then
		return;
	end

	m_isClosing = false;
	m_isQueued = true;
	m_pendingPlayerID = playerID;
	m_pendingSerial = serial;
	m_pendingPath = path;
	ConfigureCeremony(path);
	Resize();
	-- The player explicitly requested the pending ceremony from the LaunchBar.
	UIManager:QueuePopup(ContextPtr, PopupPriority.High);
end

local function OnInputHandler(input :table)
	local message = input:GetMessageType();
	if message == KeyEvents.KeyUp and input:GetKey() == Keys.VK_ESCAPE then
		-- This ceremony is intentionally modal.  Only the Continue button ends it.
		return true;
	end
	return false;
end

local function OnUpdateUI(updateType :number)
	if updateType == SystemUpdateUI.ScreenResize then
		Resize();
	end
end

local function OnShutdown()
	m_isQueued = false;
	m_pendingPlayerID = -1;
	m_pendingSerial = 0;
	m_pendingPath = LOTM_RP_PATH;
end

local function Initialize()
	-- AddUserInterfaces contexts are not hidden automatically.  Without this,
	-- TryShow sees its own context as already visible and exits forever.
	ContextPtr:SetHide(true);
	ContextPtr:SetInputHandler(OnInputHandler, true);
	ContextPtr:SetShowHandler(OnShow);
	ContextPtr:SetShutdown(OnShutdown);
	Controls.CeremonyAnimation:RegisterEndCallback(OnCeremonyAnimationEnd);
	Controls.ContinueButton:RegisterCallback(Mouse.eLClick, OnContinue);
	Events.SystemUpdateUI.Add(OnUpdateUI);
	LuaEvents.LOTM_RP_Sequence0Ceremony_Request.Add(TryShow);
	Resize();
end

Initialize();
-- BEGIN RC342 STARTUP TRACE

end
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("LOTM_RP_Sequence0Ceremony","CONTEXT END");
-- END RC342 STARTUP TRACE
