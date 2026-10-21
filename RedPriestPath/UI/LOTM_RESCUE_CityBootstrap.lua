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
LOTM_StartupTrace.Mark("LOTM_RESCUE_CityBootstrap","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"LOTM_RESCUE_CityBootstrap","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"LOTM_RESCUE_CityBootstrap","GameEvents");
local LuaEvents = LOTM_StartupTrace.Events(LuaEvents,"LOTM_RESCUE_CityBootstrap","LuaEvents");
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
do
-- END RC342 STARTUP TRACE
-- UI observes synchronized state and submits operations. Gameplay remains the
-- sole writer. In network games one stable human requests the global bootstrap.
local COMMAND="LOTM_RESCUE_Command_BootstrapCity";
local MAIN_COMMAND="LOTM_MP241_Command_LoadMain";
local CONTENT_VERSION=11;
local m_loadScreenClosed=false;
local m_submitted=false;
local m_acknowledged=false;
local m_mainSubmitted=false;
local m_mainAcknowledged=false;
local m_mainExpectedSerial=nil;

-- Temporary startup diagnostics: values passed to the shared logger are scalars.
-- Keep the fallback free of game API calls so this UI can still load by itself.
local function Trace(point,...)
	if LOTM_StartupTrace~=nil then LOTM_StartupTrace.Mark("CityBootstrap",point,...);
	else print("[LOTM_TRACE][CityBootstrap] "..point); end
end

local function DiagnosticScalar(value)
	local kind=type(value);
	if kind=="nil" or kind=="boolean" or kind=="number" or kind=="string" then return value; end
	return "<"..kind..">";
end

Trace("SCRIPT.ENTER");

local function IsNetworkGame()
	Trace("IsNetworkGame.ENTER");
	if GameConfiguration==nil then Trace("IsNetworkGame.RETURN.no_configuration",false); return false; end
	if GameConfiguration.IsAnyMultiplayer==nil then Trace("IsNetworkGame.RETURN.no_api",false); return false; end
	Trace("IsNetworkGame.IsAnyMultiplayer.BEFORE");
	local network=GameConfiguration.IsAnyMultiplayer();
	Trace("IsNetworkGame.IsAnyMultiplayer.RETURN",DiagnosticScalar(network));
	Trace("IsNetworkGame.RETURN",DiagnosticScalar(network));
	return network;
end

local function IsRescueModeConfigured()
	Trace("IsRescueModeConfigured.ENTER");
	if GameInfo ~= nil and GameInfo.Resources ~= nil then
		Trace("IsRescueModeConfigured.BannerLookup.BEFORE");
		local banner=GameInfo.Resources["RESOURCE_LOTM_RESCUE_ALLY_BANNER"];
		Trace("IsRescueModeConfigured.BannerLookup.RETURN",banner~=nil);
		if banner~=nil then Trace("IsRescueModeConfigured.RETURN.banner",true); return true; end
	end
	Trace("IsRescueModeConfigured.GetValue.BEFORE",GameConfiguration~=nil and GameConfiguration.GetValue~=nil);
	local configured=GameConfiguration ~= nil and GameConfiguration.GetValue ~= nil
		and GameConfiguration.GetValue("GAMEMODE_LOTM_RESCUE") or nil;
	Trace("IsRescueModeConfigured.GetValue.RETURN",DiagnosticScalar(configured));
	local rescue=configured==true or tonumber(configured or 0)==1;
	Trace("IsRescueModeConfigured.RETURN.configured",rescue);
	return rescue;
end

local function NeedsBootstrap()
	Trace("NeedsBootstrap.ENTER");
	Trace("NeedsBootstrap.StateProperty.BEFORE");
	local state=tostring(Game.GetProperty("LOTM_RESCUE_PHASE2A_STATE") or "");
	Trace("NeedsBootstrap.StateProperty.RETURN",state);
	Trace("NeedsBootstrap.VersionProperty.BEFORE");
	local version=tonumber(Game.GetProperty("LOTM_RESCUE_PHASE2A_VERSION") or 0) or 0;
	Trace("NeedsBootstrap.VersionProperty.RETURN",version);
	local needs=state~="READY" or version<CONTENT_VERSION;
	Trace("NeedsBootstrap.RETURN",needs);
	return needs;
end

local function GetRequestingPlayer(needsBootstrap)
	Trace("GetRequestingPlayer.ENTER",needsBootstrap);
	Trace("GetRequestingPlayer.GetLocalPlayer.BEFORE");
	local playerID=Game.GetLocalPlayer();
	Trace("GetRequestingPlayer.GetLocalPlayer.RETURN",DiagnosticScalar(playerID));
	Trace("GetRequestingPlayer.PlayerLookup.BEFORE",DiagnosticScalar(playerID));
	local player=playerID~=nil and playerID>=0 and Players[playerID] or nil;
	Trace("GetRequestingPlayer.PlayerLookup.RETURN",player~=nil);
	if player==nil then Trace("GetRequestingPlayer.RETURN.no_player"); return nil; end
	Trace("GetRequestingPlayer.IsAlive.BEFORE",playerID);
	local alive=player:IsAlive();
	Trace("GetRequestingPlayer.IsAlive.RETURN",DiagnosticScalar(alive));
	if not alive then Trace("GetRequestingPlayer.RETURN.dead",playerID); return nil; end
	Trace("GetRequestingPlayer.IsMajor.BEFORE",playerID);
	local major=player:IsMajor();
	Trace("GetRequestingPlayer.IsMajor.RETURN",DiagnosticScalar(major));
	if not major then Trace("GetRequestingPlayer.RETURN.not_major",playerID); return nil; end
	Trace("GetRequestingPlayer.IsHuman.BEFORE",playerID);
	local human=player:IsHuman();
	Trace("GetRequestingPlayer.IsHuman.RETURN",DiagnosticScalar(human));
	if not human then Trace("GetRequestingPlayer.RETURN.not_human",playerID); return nil; end
	-- Elect one source for global city creation. Main-context recovery may be
	-- requested by any human UI, including a non-anchor reconnecting client.
	if IsNetworkGame() and needsBootstrap then
		local first=nil;
		Trace("GetRequestingPlayer.GetAliveMajors.BEFORE");
		local candidates=PlayerManager.GetAliveMajors() or {};
		Trace("GetRequestingPlayer.GetAliveMajors.RETURN");
		for candidateNumber,candidate in ipairs(candidates) do
			Trace("GetRequestingPlayer.Candidate.IsAlive.BEFORE",candidateNumber);
			local candidateAlive=candidate:IsAlive();
			Trace("GetRequestingPlayer.Candidate.IsAlive.RETURN",candidateNumber,DiagnosticScalar(candidateAlive));
			if candidateAlive then
				Trace("GetRequestingPlayer.Candidate.IsHuman.BEFORE",candidateNumber);
				local candidateHuman=candidate:IsHuman();
				Trace("GetRequestingPlayer.Candidate.IsHuman.RETURN",candidateNumber,DiagnosticScalar(candidateHuman));
				if candidateHuman then
					Trace("GetRequestingPlayer.Candidate.GetID.BEFORE",candidateNumber);
					local id=candidate:GetID();
					Trace("GetRequestingPlayer.Candidate.GetID.RETURN",candidateNumber,DiagnosticScalar(id));
					if first==nil or id<first then first=id; end
				else Trace("GetRequestingPlayer.Candidate.SKIP.not_human",candidateNumber); end
			else Trace("GetRequestingPlayer.Candidate.SKIP.dead",candidateNumber); end
		end
		if first~=playerID then
			Trace("GetRequestingPlayer.RETURN.not_elected",playerID,DiagnosticScalar(first));
			return nil;
		end
	end
	Trace("GetRequestingPlayer.IsTurnActive.BEFORE",playerID);
	local active=player:IsTurnActive();
	Trace("GetRequestingPlayer.IsTurnActive.RETURN",DiagnosticScalar(active));
	if not active then Trace("GetRequestingPlayer.RETURN.inactive",playerID); return nil; end
	Trace("GetRequestingPlayer.RETURN.player",playerID);
	return playerID;
end

local function Request(playerID,command,trigger)
	Trace("Request.ENTER",playerID,command,DiagnosticScalar(trigger));
	Trace("Request.RequestPlayerOperation.BEFORE",playerID,command);
	local ok,result=pcall(UI.RequestPlayerOperation,playerID,PlayerOperations.EXECUTE_SCRIPT,
		{OnStart=command,Trigger=tostring(trigger)});
	Trace("Request.RequestPlayerOperation.RETURN",ok,DiagnosticScalar(result));
	if not ok or result==false then
		print("[LOTM_RESCUE][Phase2AUI] request failed command="..command.." details="..tostring(DiagnosticScalar(result)));
		Trace("Request.RETURN.failed",ok,DiagnosticScalar(result));
		return false;
	end
	Trace("Request.RETURN.accepted");
	return true;
end

local function Submit(trigger)
	Trace("Submit.ENTER",DiagnosticScalar(trigger));
	if not m_loadScreenClosed then Trace("Submit.RETURN.load_screen_open"); return; end
	if not IsRescueModeConfigured() then Trace("Submit.RETURN.not_rescue"); return; end
	local needsBootstrap=NeedsBootstrap();
	if needsBootstrap and m_submitted then Trace("Submit.RETURN.city_already_submitted"); return; end
	if not needsBootstrap then
		if not IsNetworkGame() then Trace("Submit.RETURN.ready_singleplayer"); return; end
		if m_mainSubmitted then Trace("Submit.RETURN.main_already_submitted"); return; end
	end
	local playerID=GetRequestingPlayer(needsBootstrap);
	if playerID==nil then Trace("Submit.RETURN.no_requesting_player"); return; end
	if needsBootstrap then
		-- Reserve before entering the API: UI publish callbacks can re-enter.
		m_submitted=true;
		Trace("Submit.CityReservation.SET",playerID);
		if not Request(playerID,COMMAND,trigger) then
			m_submitted=false;
			Trace("Submit.RETURN.city_request_failed");
			return;
		end
		print("[LOTM_RESCUE][Phase2AUI] bootstrap submitted player="..playerID.." trigger="..tostring(trigger));
		Trace("Submit.RETURN.city_submitted",playerID);
		return;
	end
	-- A new UI context always sends one load operation, including READY saves.
	-- Persisted LOADED/FAILED properties belong to the previous Gameplay context.
	if IsNetworkGame() and not m_mainSubmitted then
		m_mainSubmitted=true;
		Trace("Submit.MainReservation.SET",playerID);
		Trace("Submit.MainSerialProperty.BEFORE");
		m_mainExpectedSerial=(tonumber(Game.GetProperty("LOTM_MP241_MAIN_LOAD_SERIAL") or 0) or 0)+1;
		Trace("Submit.MainSerialProperty.RETURN.expected",m_mainExpectedSerial);
		if not Request(playerID,MAIN_COMMAND,trigger) then
			m_mainSubmitted=false;
			Trace("Submit.RETURN.main_request_failed");
			return;
		end
		print("[LOTM_RESCUE][Phase2AUI] post-241 main submitted player="..playerID.." trigger="..tostring(trigger));
		Trace("Submit.Main.SUBMITTED",playerID);
	else
		Trace("Submit.Main.SKIP.network_or_submission_changed");
	end
	Trace("Submit.RETURN.done");
end

local function OnLoadScreenClose()
	Trace("Event.LoadScreenClose.ENTER");
	m_loadScreenClosed=true;
	print("[LOTM_RESCUE][Phase2AUI] load screen closed");
	Submit("LOAD_SCREEN_CLOSE");
	Trace("Event.LoadScreenClose.RETURN");
end

Trace("Register.LoadScreenClose.BEFORE");
Events.LoadScreenClose.Add(OnLoadScreenClose);
Trace("Register.LoadScreenClose.RETURN");
Trace("Register.LocalPlayerTurnBegin.BEFORE");
Events.LocalPlayerTurnBegin.Add(function()
	Trace("Event.LocalPlayerTurnBegin.ENTER");
	Submit("LOCAL_PLAYER_TURN_BEGIN");
	Trace("Event.LocalPlayerTurnBegin.RETURN");
end);
Trace("Register.LocalPlayerTurnBegin.RETURN");
Trace("Register.PlayerTurnActivated.BEFORE");
Events.PlayerTurnActivated.Add(function(playerID)
	Trace("Event.PlayerTurnActivated.ENTER",DiagnosticScalar(playerID));
	Trace("Event.PlayerTurnActivated.GetLocalPlayer.BEFORE");
	local localPlayerID=Game.GetLocalPlayer();
	Trace("Event.PlayerTurnActivated.GetLocalPlayer.RETURN",DiagnosticScalar(localPlayerID));
	if playerID==localPlayerID then Submit("PLAYER_TURN_ACTIVATED");
	else Trace("Event.PlayerTurnActivated.SKIP.not_local",DiagnosticScalar(playerID)); end
	Trace("Event.PlayerTurnActivated.RETURN");
end);
Trace("Register.PlayerTurnActivated.RETURN");
Trace("Register.GameCoreEventPublishComplete.BEFORE");
Events.GameCoreEventPublishComplete.Add(function()
	Trace("Event.GameCoreEventPublishComplete.ENTER");
	Submit("PUBLISH_COMPLETE");
	Trace("Ack.City.ENTER",m_submitted,m_acknowledged);
	if m_submitted and not m_acknowledged and not NeedsBootstrap() then
		m_acknowledged=true;
		print("[LOTM_RESCUE][Phase2AUI] bootstrap acknowledged state=READY");
		Trace("Ack.City.READY");
	end
	Trace("Ack.City.RETURN",m_acknowledged);
	Trace("Ack.MainStateProperty.BEFORE");
	local mainState=tostring(Game.GetProperty("LOTM_MP241_MAIN_LOAD_STATE") or "WAITING");
	Trace("Ack.MainStateProperty.RETURN",mainState);
	Trace("Ack.MainSerialProperty.BEFORE");
	local mainSerial=tonumber(Game.GetProperty("LOTM_MP241_MAIN_LOAD_SERIAL") or 0) or 0;
	Trace("Ack.MainSerialProperty.RETURN",mainSerial);
	Trace("Ack.Main.ENTER",m_mainSubmitted,m_mainAcknowledged,mainSerial,m_mainExpectedSerial,mainState);
	if m_mainSubmitted and not m_mainAcknowledged and mainSerial>=m_mainExpectedSerial
		and (mainState=="LOADED" or mainState=="FAILED") then
		m_mainAcknowledged=true;
		print("[LOTM_RESCUE][Phase2AUI] post-241 main acknowledged state="..mainState);
		Trace("Ack.Main.COMPLETE",mainState);
	end
	Trace("Ack.Main.RETURN",m_mainAcknowledged);
	Trace("Event.GameCoreEventPublishComplete.RETURN");
end);
Trace("Register.GameCoreEventPublishComplete.RETURN");
print("[LOTM_RESCUE][Phase2AUI] initialized; no Gameplay mutation before LoadScreenClose");
Trace("SCRIPT.RETURN");
-- BEGIN RC342 STARTUP TRACE

end
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("LOTM_RESCUE_CityBootstrap","CONTEXT END");
-- END RC342 STARTUP TRACE
