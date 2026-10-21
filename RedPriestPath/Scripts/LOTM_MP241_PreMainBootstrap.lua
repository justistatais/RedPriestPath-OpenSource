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
LOTM_StartupTrace.Mark("LOTM_MP241_PreMainBootstrap","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"LOTM_MP241_PreMainBootstrap","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"LOTM_MP241_PreMainBootstrap","GameEvents");
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
do
-- END RC342 STARTUP TRACE
-- The UI submits this separate synchronized operation after it observes the
-- published rc.241 city chain's READY state. Do not include new listeners from
-- inside the operation that is still committing the four native cities.
local isNetwork = GameConfiguration ~= nil
	and GameConfiguration.IsAnyMultiplayer ~= nil
	and GameConfiguration.IsAnyMultiplayer();

local function IsRescueModeConfigured()
	if GameInfo ~= nil and GameInfo.Resources ~= nil
		and GameInfo.Resources["RESOURCE_LOTM_RESCUE_ALLY_BANNER"] ~= nil then return true; end
	local configured = GameConfiguration ~= nil and GameConfiguration.GetValue ~= nil
		and GameConfiguration.GetValue("GAMEMODE_LOTM_RESCUE") or nil;
	return configured == true or tonumber(configured or 0) == 1;
end

if isNetwork and IsRescueModeConfigured() and LOTM_MP241_PREMAIN_BRIDGE == nil then
	-- Context-local: a saved LOADED Property does not mean this Lua context has
	-- restored its listeners. Never skip a fresh context because of old save data.
	LOTM_MP241_PREMAIN_BRIDGE = { State="WAITING" };
	local bridge = LOTM_MP241_PREMAIN_BRIDGE;
	local stateKey = "LOTM_MP241_MAIN_LOAD_STATE";
	local startedTurnKey = "LOTM_MP241_STARTED_TURN";
	local startedPlayersKey = "LOTM_MP241_STARTED_PLAYERS";
	local function CurrentStartedPlayers()
		local ids = {};
		if tonumber(Game.GetProperty(startedTurnKey) or -1) ~= Game.GetCurrentGameTurn() then return ids; end
		local seen = {};
		for part in string.gmatch(tostring(Game.GetProperty(startedPlayersKey) or ""),"[^,]+") do
			local id = tonumber(part);
			if id ~= nil and id >= 0 and id == math.floor(id) and not seen[id] then
				seen[id] = true; ids[#ids + 1] = id;
			end
		end
		table.sort(ids);
		return ids;
	end
	local function RecordStartedPlayer(playerID)
		local id = tonumber(playerID);
		if id == nil or id < 0 or id ~= math.floor(id) then return; end
		-- Only this synchronized event supplies catch-up inputs. A local UI
		-- active-turn flag must never decide which Gameplay turn gets replayed.
		local ids = CurrentStartedPlayers();
		for _,existing in ipairs(ids) do if existing == id then return; end end
		ids[#ids + 1] = id;
		table.sort(ids);
		Game.SetProperty(startedTurnKey,Game.GetCurrentGameTurn());
		Game.SetProperty(startedPlayersKey,table.concat(ids,","));
	end
	local function LoadPost241Main(requestPlayerID)
		local requester = requestPlayerID ~= nil and Players[requestPlayerID] or nil;
		if requester == nil or not requester:IsAlive() or not requester:IsMajor()
			or not requester:IsHuman() then return; end
		if bridge.State == "LOADING" then return; end
		local phase2 = tostring(Game.GetProperty("LOTM_RESCUE_PHASE2A_STATE") or "NONE");
		local version = tonumber(Game.GetProperty("LOTM_RESCUE_PHASE2A_VERSION") or 0) or 0;
		if not IsRescueModeConfigured() or phase2 ~= "READY" or version < 11 then return; end
		local serial = tonumber(Game.GetProperty("LOTM_MP241_MAIN_LOAD_SERIAL") or 0) or 0;
		-- Every accepted synchronized request acknowledges identically on all
		-- peers, including an already-loaded peer when another UI reconnects.
		Game.SetProperty("LOTM_MP241_MAIN_LOAD_SERIAL",serial + 1);
		if bridge.State ~= "WAITING" then return; end
		bridge.State = "LOADING";
		Game.SetProperty(stateKey,"LOADING");
		Game.SetProperty("LOTM_MP241_MAIN_LOAD_FAILURE",nil);
		print("[LOTM][MP241Bootstrap] published chain COMMIT phase2=" .. phase2
			.. " phase3=" .. tostring(Game.GetProperty("LOTM_RESCUE_PHASE3_STATE") or "NONE")
			.. "; loading post-241 main in separate synchronized operation");
		local ok, details = pcall(function()
			include("LOTM_MP241_MainBundle");
			-- Civ VI include can report a script error without throwing to pcall.
			-- The generated bundle publishes this only after every module loads.
			assert(LOTM_MP241_MAIN_READY == true,"post-241 bundle did not publish READY");
			if LOTM_MP_TurnSync ~= nil and LOTM_MP_TurnSync.RunPendingStartups ~= nil then
				if LOTM_MP_TurnSync.RunPendingStartups() == false then
					error("post-241 startup failed; see MP241Compat failure above");
				end
			end
			if LOTM_MP_TurnSync ~= nil and LOTM_MP_TurnSync.RunCurrentTurnCatchUp ~= nil then
				LOTM_MP_TurnSync.RunCurrentTurnCatchUp(CurrentStartedPlayers());
			end
		end);
		-- A failed include may already have installed callbacks or mutated state.
		-- Fail closed for this context; retrying the bundle could register it twice.
		bridge.State = ok and "LOADED" or "FAILED";
		Game.SetProperty(stateKey,bridge.State);
		if ok then
			print("[LOTM][MP241Bootstrap] post-241 main loaded after published chain");
		else
			-- Full native/Lua details may contain different local paths per peer.
			Game.SetProperty("LOTM_MP241_MAIN_LOAD_FAILURE","INCLUDE_OR_STARTUP_FAILED");
			print("[LOTM][MP241Bootstrap] FAILED loading post-241 main details=" .. tostring(details));
		end
	end
	GameEvents.LOTM_MP241_Command_LoadMain.Add(LoadPost241Main);
	GameEvents.PlayerTurnStarted.Add(RecordStartedPlayer);
	print("[LOTM][MP241Bootstrap] separate synchronized main-load listener registered");
end
-- BEGIN RC342 STARTUP TRACE

end
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("LOTM_MP241_PreMainBootstrap","CONTEXT END");
-- END RC342 STARTUP TRACE
