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
LOTM_StartupTrace.Mark("EndGameMenu_LOTM_Redemption","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"EndGameMenu_LOTM_Redemption","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"EndGameMenu_LOTM_Redemption","GameEvents");
local LuaEvents = LOTM_StartupTrace.Events(LuaEvents,"EndGameMenu_LOTM_Redemption","LuaEvents");
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
do
-- END RC342 STARTUP TRACE
-- Redemption Mode extension for Firaxis EndGameMenu.
-- Reuse the base settlement flow and its included PopupDialog button template.

local NATIVE_REDEMPTION_VICTORY="VICTORY_CONQUEST";
print("[LOTM_RESCUE][EndGame] redemption extension loaded");
local PATH_ICONS={
 PATH_RED_PRIEST="ICON_UNIT_LOTM_RP_PATH_HOLDER",
 PATH_PERFECT="ICON_UNIT_LOTM_PP_PATH_HOLDER",
 PATH_BLACK_EMPEROR="ICON_UNIT_LOTM_BE_PATH_HOLDER",
 PATH_THIEF="ICON_UNIT_LOTM_TP_PATH_HOLDER"
};

local BASE_LOTM_TeamVictoryData=TeamVictoryData;
function TeamVictoryData(winningTeamID,victoryType)
 local data=BASE_LOTM_TeamVictoryData(winningTeamID,victoryType);
 if victoryType==NATIVE_REDEMPTION_VICTORY and tonumber(Game.GetProperty("LOTM_RESCUE_MODE") or 0)==1 then
  local localPlayer=Players[Game.GetLocalPlayer()];
  local path=localPlayer~=nil and tostring(localPlayer:GetProperty("LOTM_RP_PATH") or "") or "";
  local icon=PATH_ICONS[path];
  if icon~=nil then
   data.VictoryTypeIcon=icon;
   if data.IsWinnerLocalPlayer then data.RibbonIcon=icon; end
  end
  if data.IsWinnerLocalPlayer then data.RibbonText="LOC_VICTORY_LOTM_RESCUE_NAME"; end
 end
 return data;
end

local m_endingCategory=nil;
local m_comicButton=nil;
local function RefreshEndingComicButton()
 if m_comicButton==nil then
  local instance={};
  ContextPtr:BuildInstanceForControl("PopupButtonInstance",instance,Controls.ButtonStack);
  m_comicButton=instance.Button;
  m_comicButton:SetSizeX(140);
  m_comicButton:SetText(Locale.Lookup("LOC_LOTM_COMIC_VIEW_ENDING"));
  m_comicButton:RegisterCallback(Mouse.eLClick,function()
   if m_endingCategory~=nil then LuaEvents.LOTM_Comic_ShowEnding(m_endingCategory); end
  end);
 end
 m_comicButton:SetHide(m_endingCategory==nil);
 Controls.ButtonStack:CalculateSize();
 Controls.ButtonStack:ReprocessAnchoring();
end

local BASE_LOTM_EndGameView=View;
function View(data)
 local player=Players[Game.GetLocalPlayer()];
 local path=player~=nil and tostring(player:GetProperty("LOTM_RP_PATH") or "") or "";
 m_endingCategory=nil;
 if tonumber(Game.GetProperty("LOTM_RESCUE_MODE") or 0)==1 and PATH_ICONS[path]~=nil then
  m_endingCategory=data.IsWinnerLocalPlayer and "VICTORY" or "DEFEAT";
 end
 BASE_LOTM_EndGameView(data);
 RefreshEndingComicButton();
end

-- Gameplay alone decides whether the two-life Boss condition is complete.
-- This UI reads that synchronized result and reuses Firaxis' conquest end-game
-- presentation function.  It does not fire Events.TeamVictory, call a victory
-- setter, or change Game.GetWinningTeam; native conquest is disabled by the
-- rescue-only Gameplay requirement.
local m_redemptionShown=false;
local function ShowRedemptionVictory(source)
 if m_redemptionShown or tonumber(Game.GetProperty("LOTM_RESCUE_MODE") or 0)~=1 or tonumber(Game.GetProperty("LOTM_RESCUE_PHASE10_VICTORY") or 0)~=1 then return; end
 local team=tonumber(Game.GetProperty("LOTM_RESCUE_PHASE10_WINNING_TEAM") or -1);
 local victory=GameInfo.Victories[NATIVE_REDEMPTION_VICTORY];
 if team<0 or victory==nil then return; end
 local beforeTeam,beforeType=Game.GetWinningTeam();
 m_redemptionShown=true;
 print("[LOTM_RESCUE][EndGame] rescue presentation source="..tostring(source).." team="..team.." gameCoreBefore="..tostring(beforeTeam)..":"..tostring(beforeType));
 OnTeamVictory(team,victory.Index,0);
 local afterTeam,afterType=Game.GetWinningTeam();
 print("[LOTM_RESCUE][EndGame] rescue presentation shown gameCoreAfter="..tostring(afterTeam)..":"..tostring(afterType).." gameCoreChanged="..tostring(beforeTeam~=afterTeam or beforeType~=afterType));
end

Events.LoadGameViewStateDone.Add(function() ShowRedemptionVictory("LOAD_GAME_VIEW_STATE_DONE"); end);
Events.GameCoreEventPublishComplete.Add(function() ShowRedemptionVictory("GAMECORE_PUBLISH_COMPLETE"); end);
Events.LocalPlayerTurnBegin.Add(function() ShowRedemptionVictory("LOCAL_PLAYER_TURN_BEGIN"); end);
-- BEGIN RC342 STARTUP TRACE

end
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("EndGameMenu_LOTM_Redemption","CONTEXT END");
-- END RC342 STARTUP TRACE
