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
LOTM_StartupTrace.Mark("LOTM_RP_PathChoice","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"LOTM_RP_PathChoice","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"LOTM_RP_PathChoice","GameEvents");
local LuaEvents = LOTM_StartupTrace.Events(LuaEvents,"LOTM_RP_PathChoice","LuaEvents");
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
do
-- END RC342 STARTUP TRACE
-- Local first-turn path choice.  This UI never writes Gameplay properties;
-- it submits a synchronized player operation which Gameplay validates again.

local LOTM_RP_PATH_DECIDED :string = "LOTM_RP_PATH_DECIDED";
local LOTM_RP_COMMAND_NAME :string = "LOTM_RP_Command_SelectPath";
local LOTM_RP_RED_PRIEST :string = "PATH_RED_PRIEST";
local LOTM_PP_PERFECT :string = "PATH_PERFECT";
local LOTM_BE_BLACK_EMPEROR :string = "PATH_BLACK_EMPEROR";
local LOTM_TP_THIEF :string = "PATH_THIEF";
local m_waitingForPublish :boolean = false;
local m_focusNewHero :boolean = false;

local function GetLocalPlayer()
	local playerID = Game.GetLocalPlayer();
	if playerID == nil or playerID < 0 then
		return -1, nil;
	end
	return playerID, Players[playerID];
end

local function Refresh()
	local playerID, player = GetLocalPlayer();
	if player == nil or not player:IsAlive() or not player:IsMajor() then
		Controls.ChoicePopup:SetHide(true);
		return;
	end

	local decided = (player:GetProperty(LOTM_RP_PATH_DECIDED) or 0) == 1;
	-- The rescue ruleset has its own Thief implementation, so the Thief
	-- choice must remain available there.  The previous rescue-only hide made
	-- the pathway impossible to select even though Gameplay accepted
	-- PATH_THIEF and the rescue module was bundled.
	Controls.ChooseThiefButton:SetHide(false);
	if decided then
		m_waitingForPublish = false;
	end
	Controls.ChoicePopup:SetHide(decided or m_waitingForPublish);
end

local function SubmitChoice(choice :string)
	if m_waitingForPublish then
		return;
	end
	local playerID, player = GetLocalPlayer();
	if player == nil
		or (player:GetProperty(LOTM_RP_PATH_DECIDED) or 0) == 1 then
		Refresh();
		return;
	end

	local parameters :table = {};
	parameters.OnStart = LOTM_RP_COMMAND_NAME;
	parameters.Choice = choice;
	m_focusNewHero = choice == LOTM_RP_RED_PRIEST
		or choice == LOTM_PP_PERFECT
		or choice == LOTM_BE_BLACK_EMPEROR
		or choice == LOTM_TP_THIEF;
	m_waitingForPublish = true;
	Controls.ChoicePopup:SetHide(true);
	UI.RequestPlayerOperation(
		playerID,
		PlayerOperations.EXECUTE_SCRIPT,
		parameters
	);
end

local function OnChooseRedPriest()
	SubmitChoice(LOTM_RP_RED_PRIEST);
end

local function OnChoosePerfect()
	SubmitChoice(LOTM_PP_PERFECT);
end

local function OnChooseBlackEmperor()
	SubmitChoice(LOTM_BE_BLACK_EMPEROR);
end

local function OnChooseThief()
	SubmitChoice(LOTM_TP_THIEF);
end

local function OnChooseNone()
	SubmitChoice("NONE");
end

local function OnPublishComplete()
	m_waitingForPublish = false;
	Refresh();
	if not m_focusNewHero then
		return;
	end
	local _, player = GetLocalPlayer();
	local unitID = player ~= nil and player:GetProperty("LOTM_RP_UNIT_ID") or -1;
	if unitID == nil or unitID < 0 then
		return;
	end
	local unit = player:GetUnits():FindID(unitID);
	if unit == nil then
		return;
	end
	m_focusNewHero = false;
	UI.SelectUnit(unit);
	UI.LookAtPlot(Map.GetPlot(unit:GetX(), unit:GetY()));
end

local function Initialize()
	ContextPtr:SetHide(false);
	Controls.ChooseRedPriestButton:RegisterCallback(Mouse.eLClick, OnChooseRedPriest);
	Controls.ChoosePerfectButton:RegisterCallback(Mouse.eLClick, OnChoosePerfect);
	Controls.ChooseBlackEmperorButton:RegisterCallback(Mouse.eLClick, OnChooseBlackEmperor);
	Controls.ChooseThiefButton:RegisterCallback(Mouse.eLClick, OnChooseThief);
	Controls.ChooseNoneButton:RegisterCallback(Mouse.eLClick, OnChooseNone);
	Events.LocalPlayerTurnBegin.Add(Refresh);
	Events.GameCoreEventPublishComplete.Add(OnPublishComplete);
	Events.LoadGameViewStateDone.Add(Refresh);
	Refresh();
end

Initialize();
-- BEGIN RC342 STARTUP TRACE

end
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("LOTM_RP_PathChoice","CONTEXT END");
-- END RC342 STARTUP TRACE
