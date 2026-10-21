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
LOTM_StartupTrace.Mark("LOTM_RP_LaunchButton","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"LOTM_RP_LaunchButton","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"LOTM_RP_LaunchButton","GameEvents");
local LuaEvents = LOTM_StartupTrace.Events(LuaEvents,"LOTM_RP_LaunchButton","LuaEvents");
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
do
-- END RC342 STARTUP TRACE
-- Launch-bar hook based on the same instance pattern used by Quick Deals.

local LOTM_RP_PATH :string = "PATH_RED_PRIEST";
local LOTM_PP_PATH :string = "PATH_PERFECT";
local LOTM_BE_PATH :string = "PATH_BLACK_EMPEROR";
local LOTM_TP_PATH :string = "PATH_THIEF";
local LOTM_RP_OPENING_COMIC_SHOWN :string = "LOTM_RP_OPENING_COMIC_SHOWN";
local LOTM_RP_OPENING_COMIC_COMMAND :string = "LOTM_RP_Command_MarkOpeningComicShown";
local m_button :table = {};
local m_pin :table = {};
local m_attached :boolean = false;
local m_locallyPlayedCeremonySerial :number = 0;
local m_openingComicRequested :boolean = false;

local function ShowOpeningComicOnce()
	if tonumber(Game.GetProperty("LOTM_RESCUE_MODE") or 0) ~= 1 then return false; end
	local playerID = tonumber(Game.GetLocalPlayer()) or -1;
	local player = playerID >= 0 and Players[playerID] or nil;
	if player == nil
		or m_openingComicRequested
		or tonumber(player:GetProperty(LOTM_RP_OPENING_COMIC_SHOWN) or 0) == 1 then
		return false;
	end
	-- Gameplay owns the save-persistent marker.  The local flag closes the
	-- publish-delay window so repeated clicks cannot queue the prologue twice.
	if not player:IsTurnActive() then return false; end
	m_openingComicRequested = true;
	UI.RequestPlayerOperation(playerID, PlayerOperations.EXECUTE_SCRIPT, {
		OnStart = LOTM_RP_OPENING_COMIC_COMMAND
	});
	LuaEvents.LOTM_Comic_ShowStart();
	return true;
end

local function ResizeLaunchBar(buttonStack)
	buttonStack:CalculateSize();
	local backing = ContextPtr:LookUpControl("/InGame/LaunchBar/LaunchBacking");
	local backingTile = ContextPtr:LookUpControl("/InGame/LaunchBar/LaunchBackingTile");
	if backing ~= nil then
		backing:SetSizeX(buttonStack:GetSizeX() + 116);
	end
	if backingTile ~= nil then
		backingTile:SetSizeX(math.max(0, buttonStack:GetSizeX() - 20));
	end
	LuaEvents.LaunchBar_Resize(buttonStack:GetSizeX());
end

local function GetSelectedPath()
	local playerID = Game.GetLocalPlayer();
	local player = playerID ~= nil and playerID >= 0 and Players[playerID] or nil;
	return player ~= nil and player:GetProperty("LOTM_RP_PATH") or "NONE";
end

local function Refresh()
	if not m_attached then
		return;
	end
	local path = GetSelectedPath();
	local visible = path == LOTM_RP_PATH or path == LOTM_PP_PATH or path == LOTM_BE_PATH or path == LOTM_TP_PATH;
	m_button.LaunchItemButton:SetHide(not visible);
	m_pin.Pin:SetHide(not visible);
	if visible then
		local iconName = path == LOTM_PP_PATH and "ICON_LOTM_PP_PERFECT_MARK"
			or (path == LOTM_BE_PATH and "ICON_LOTM_BE_BLACK_EMPEROR_MARK"
			or (path == LOTM_TP_PATH and "ICON_LOTM_TP_THIEF_MARK"
			or "ICON_LOTM_RP_RED_PRIEST_MARK"));
		local offsetX, offsetY, textureSheet =
			IconManager:FindIconAtlas(iconName, 40);
		if textureSheet ~= nil and textureSheet ~= "" then
			m_button.LaunchItemIcon:SetTexture(offsetX, offsetY, textureSheet);
		end
		m_button.LaunchItemButton:SetToolTipString(
			Locale.Lookup(path == LOTM_PP_PATH and "LOC_LOTM_PP_DETAILS_TITLE"
				or (path == LOTM_BE_PATH and "LOC_LOTM_BE_DETAILS_TITLE"
				or (path == LOTM_TP_PATH and "LOC_LOTM_TP_DETAILS_TITLE"
				or "LOC_LOTM_RP_DETAILS_TITLE")))
		);
	end
	local buttonStack = ContextPtr:LookUpControl("/InGame/LaunchBar/ButtonStack");
	if buttonStack ~= nil then
		ResizeLaunchBar(buttonStack);
	end
end

local function HasPendingSequenceZeroCeremony()
	local playerID = Game.GetLocalPlayer();
	local player = playerID ~= nil and playerID >= 0 and Players[playerID] or nil;
	if player == nil or (player:GetProperty("LOTM_RP_SEQUENCE") or 9) ~= 0 then
		return false;
	end
	local serial =
		player:GetProperty("LOTM_RP_SEQUENCE0_CEREMONY_SERIAL") or 0;
	local acknowledged =
		player:GetProperty("LOTM_RP_SEQUENCE0_CEREMONY_ACK_SERIAL") or 0;
	local readyTurn =
		player:GetProperty("LOTM_RP_SEQUENCE0_CEREMONY_READY_TURN") or -1;
	return serial > 0
		and serial > acknowledged
		and serial > m_locallyPlayedCeremonySerial
		and readyTurn >= 0
		and Game.GetCurrentGameTurn() >= readyTurn;
end

local function OnSequenceZeroCeremonyShown(serial :number)
	if serial ~= nil and serial > m_locallyPlayedCeremonySerial then
		m_locallyPlayedCeremonySerial = serial;
	end
end

local function OnLaunchButtonClicked()
	if HasPendingSequenceZeroCeremony() then
		LuaEvents.LOTM_RP_Sequence0Ceremony_Request();
		return;
	end
	if ShowOpeningComicOnce() then
		return;
	end
	LuaEvents.LOTM_RP_UI_ToggleDetails();
end

local function Attach()
	if m_attached then
		Refresh();
		return;
	end
	local buttonStack = ContextPtr:LookUpControl("/InGame/LaunchBar/ButtonStack");
	if buttonStack == nil then
		return;
	end
	ContextPtr:BuildInstanceForControl("LOTM_RP_LaunchBarItem", m_button, buttonStack);
	ContextPtr:BuildInstanceForControl("LOTM_RP_LaunchBarPin", m_pin, buttonStack);
	m_button.LaunchItemButton:RegisterCallback(Mouse.eLClick, OnLaunchButtonClicked);
	m_attached = true;
	Refresh();
end

local function Initialize()
	ContextPtr:SetHide(false);
	Events.LoadGameViewStateDone.Add(Attach);
	Events.GameCoreEventPublishComplete.Add(Refresh);
	Events.LocalPlayerTurnBegin.Add(Refresh);
	LuaEvents.LOTM_RP_Sequence0Ceremony_Shown.Add(
		OnSequenceZeroCeremonyShown
	);
end

Initialize();
-- BEGIN RC342 STARTUP TRACE

end
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("LOTM_RP_LaunchButton","CONTEXT END");
-- END RC342 STARTUP TRACE
