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
LOTM_StartupTrace.Mark("LOTM_RP_ComicViewer","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"LOTM_RP_ComicViewer","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"LOTM_RP_ComicViewer","GameEvents");
local LuaEvents = LOTM_StartupTrace.Events(LuaEvents,"LOTM_RP_ComicViewer","LuaEvents");
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
do
-- END RC342 STARTUP TRACE
-- Native-size comic reader for the three user-provided story sets.
-- This UI only reads game state and stores local presentation acknowledgements.

local SETS :table = {
    START = {"1-1", "1-2", "1-3"},
    VICTORY = {"2-1", "2-2", "2-3", "2-4", "2-5", "2-6", "2-7", "2-8"},
    DEFEAT = {"3-1", "3-2"},
};
local DIMENSIONS :table = {
    ["1-1"]={1122,1402}, ["1-2"]={1122,1402}, ["1-3"]={1024,1536},
    ["2-1"]={1024,1536}, ["2-2"]={1086,1448}, ["2-3"]={1024,1536},
    ["2-4"]={1055,1491}, ["2-5"]={1086,1448}, ["2-6"]={1122,1402},
    ["2-7"]={1122,1402}, ["2-8"]={1086,1448},
    ["3-1"]={1086,1448}, ["3-2"]={1024,1536},
};
local m_category :string = "START";
local m_page :number = 1;
local m_signature :number = -1;
local m_returnToEnding :boolean = false;

local function GetLocalPlayer()
    local id = Game.GetLocalPlayer();
    if id == nil or id < 0 then return -1, nil; end
    return id, Players[id];
end

local function PathVisible(player)
    local path = player ~= nil and player:GetProperty("LOTM_RP_PATH") or "NONE";
    return path == "PATH_RED_PRIEST" or path == "PATH_PERFECT"
        or path == "PATH_BLACK_EMPEROR" or path == "PATH_THIEF";
end

local function GameSignature()
    local gameSeed = tonumber(GameConfiguration.GetValue("GAME_SYNC_RANDOM_SEED")) or 0;
    local mapSeed = tonumber(MapConfiguration.GetValue("RANDOM_SEED"))
        or tonumber(GameConfiguration.GetValue("MAP_RANDOM_SEED")) or 0;
    local startTurn = tonumber(GameConfiguration.GetStartTurn()) or 0;
    local localPlayer = tonumber(Game.GetLocalPlayer()) or -1;
    return math.floor((gameSeed * 31 + mapSeed * 17 + startTurn * 13 + localPlayer + 2147483647) % 2147483647);
end

local function OutcomeOption(category :string)
    return "LOTMComicShown_" .. tostring(GameSignature()) .. "_" .. category;
end

local function ResizePopup()
    if UIManager == nil or UIManager.GetScreenSizeVal == nil then return; end
    local x, y = UIManager:GetScreenSizeVal();
    Controls.Popup:SetSizeVal(math.min(1240, math.max(720, x - 24)), math.min(1060, math.max(560, y - 24)));
    Controls.ComicScroll:SetSizeX(Controls.Popup:GetSizeX() - 48);
    Controls.ComicScroll:SetSizeY(Controls.Popup:GetSizeY() - 190);
    print("[LOTM_COMIC] resized screen=" .. tostring(x) .. "x" .. tostring(y)
        .. " popup=" .. tostring(Controls.Popup:GetSizeX()) .. "x"
        .. tostring(Controls.Popup:GetSizeY()));
end

local function Realize()
    local pages = SETS[m_category] or SETS.START;
    m_page = math.max(1, math.min(#pages, m_page));
    local key = pages[m_page];
    local dimensions = DIMENSIONS[key] or {1024,1536};
    -- Resource 308 tried the following direct PNG binding; Civ VI rendered it
    -- blank in-game even though the PNG was imported and byte-identical:
    -- Controls.ComicImage:SetTexture("LOTM_Comic_" .. key .. ".png");
    local textureName = "LOTM_Comic_" .. key .. ".dds";
    Controls.ComicImage:SetTexture(textureName);
    Controls.ComicImage:SetSizeVal(dimensions[1], dimensions[2]);
    Controls.ComicScroll:SetScrollValue(0);
    Controls.PageLabel:SetText(Locale.Lookup("LOC_LOTM_COMIC_PAGE", m_page, #pages));
    Controls.Previous:SetDisabled(m_page <= 1);
    Controls.Next:SetDisabled(false);
    Controls.Next:SetText(Locale.Lookup(m_page >= #pages
        and "LOC_LOTM_COMIC_FINISH" or "LOC_LOTM_COMIC_NEXT"));
    Controls.CategoryStack:SetHide(m_category ~= "START");
    ResizePopup();
    print("[LOTM_COMIC] page=" .. key .. " texture=" .. textureName
        .. " size=" .. tostring(dimensions[1]) .. "x" .. tostring(dimensions[2]));
end

local function Close()
    Controls.Popup:SetHide(true);
    Controls.Vignette:SetHide(true);
    UIManager:DequeuePopup(ContextPtr);
end

local function Finish()
    local completedCategory = m_category;
    local returnToEnding = m_returnToEnding;
    Close();
    print("[LOTM_COMIC] completed category=" .. tostring(completedCategory));
    if not returnToEnding then LuaEvents.LOTM_Comic_ReturnToSequence(); end
end

local function Show(category :string, returnToEnding :boolean)
    if tonumber(Game.GetProperty("LOTM_RESCUE_MODE") or 0) ~= 1 then return; end
    if category ~= "START" and category ~= "VICTORY" and category ~= "DEFEAT" then category = "START"; end
    m_category = category; m_page = 1; m_signature = GameSignature();
    m_returnToEnding = returnToEnding == true;
    Realize();
    Controls.Vignette:SetHide(false); Controls.Popup:SetHide(false);
    local priority = m_returnToEnding and (PopupPriority.EndGameMenu + 1) or PopupPriority.Current;
    UIManager:QueuePopup(ContextPtr, priority);
end

local function ShowOutcome(category :string)
    if tonumber(Game.GetProperty("LOTM_RESCUE_MODE") or 0) ~= 1 then return; end
    local _, player = GetLocalPlayer();
    if not PathVisible(player) then return; end
    local option = OutcomeOption(category);
    if tonumber(Options.GetUserOption("Tutorial", option) or 0) == 1 then return; end
    Options.SetUserOption("Tutorial", option, 1); Options.SaveOptions();
    Show(category);
end

local function ShowOutcomeForTeam(winningTeam :number)
    local id, player = GetLocalPlayer();
    if id < 0 or not PathVisible(player) or winningTeam == nil or winningTeam < 0 then return; end
    local category = player:GetTeam() == winningTeam and "VICTORY" or "DEFEAT";
    ShowOutcome(category);
end

local function TryWinningTeam()
    if Game.GetWinningTeam == nil then return; end
    local winningTeam = Game.GetWinningTeam();
    if winningTeam == nil then return; end
    ShowOutcomeForTeam(tonumber(winningTeam) or -1);
end

local function Initialize()
    ContextPtr:SetHide(true);
    ContextPtr:SetInputHandler(function(input :table)
        if input:GetMessageType() == KeyEvents.KeyUp and input:GetKey() == Keys.VK_ESCAPE then Close(); return true; end
        return true;
    end, true);
    Controls.Close:RegisterCallback(Mouse.eLClick, Close);
    Controls.Previous:RegisterCallback(Mouse.eLClick, function() if m_page > 1 then m_page = m_page - 1; Realize(); end end);
    Controls.Next:RegisterCallback(Mouse.eLClick, function()
        local pages = SETS[m_category] or SETS.START;
        if m_page < #pages then
            m_page = m_page + 1;
            Realize();
        else
            Finish();
        end
    end);
    Controls.CategoryStart:RegisterCallback(Mouse.eLClick, function() Show("START"); end);
    LuaEvents.LOTM_Comic_ShowStart.Add(function() Show("START"); end);
    LuaEvents.LOTM_Comic_ShowReview.Add(function() Show("START"); end);
    -- Explicit ending review bypasses the automatic once-per-game acknowledgement.
    LuaEvents.LOTM_Comic_ShowEnding.Add(function(category)
        if category ~= "VICTORY" and category ~= "DEFEAT" then return; end
        local _, player = GetLocalPlayer();
        if not PathVisible(player) then return; end
        Show(category, true);
    end);
    if Events.TeamVictory ~= nil then Events.TeamVictory.Add(function(teamID) ShowOutcomeForTeam(tonumber(teamID) or -1); end); end
    Events.GameCoreEventPublishComplete.Add(TryWinningTeam);
    Events.LocalPlayerTurnBegin.Add(TryWinningTeam);
    Events.LoadGameViewStateDone.Add(TryWinningTeam);
end

Initialize();
-- BEGIN RC342 STARTUP TRACE

end
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("LOTM_RP_ComicViewer","CONTEXT END");
-- END RC342 STARTUP TRACE
