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
LOTM_StartupTrace.Mark("LOTM_QD_MultiplayerCompat","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"LOTM_QD_MultiplayerCompat","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"LOTM_QD_MultiplayerCompat","GameEvents");
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
do
-- END RC342 STARTUP TRACE
-- Quick Deals multiplayer compatibility shim.
--
-- Quick Deals stores a local-player-derived UI cache in synchronized Player
-- Properties. Keep that cache local in network games. Never mutate persisted
-- Player Properties during script load: old saves must finish deserializing
-- before any synchronized gameplay event is allowed to change state.

local function IsNetworkGame()
    return GameConfiguration ~= nil
       and GameConfiguration.IsAnyMultiplayer ~= nil
       and GameConfiguration.IsAnyMultiplayer() == true;
end

if not IsNetworkGame() then return; end

local localCache = { sell = {}, buy = {} };
local installedManager = nil;
local LEGACY_CACHE_KEYS = { "QD_SELLABLE_DEALS", "QD_BUYABLE_DEALS" };
local LEGACY_CACHE_MIGRATION_KEY = "LOTM_QD_LOCAL_CACHE_MIGRATION_VERSION";
local LEGACY_CACHE_MIGRATION_VERSION = 1;

local function GetCachedDeals(isSell)
    return localCache[isSell and "sell" or "buy"];
end

local function SetCachedDeals(deals, isSell)
    localCache[isSell and "sell" or "buy"] = deals or {};
    return true;
end

local function InstallLocalCache(reason)
    local qd = ExposedMembers ~= nil and ExposedMembers.QD or nil;
    local manager = qd ~= nil and qd.CacheManager or nil;
    if manager == nil then return false; end
    if manager ~= installedManager
       or manager.GetCachedDeals ~= GetCachedDeals
       or manager.SetCachedDeals ~= SetCachedDeals then
        manager.GetCachedDeals = GetCachedDeals;
        manager.SetCachedDeals = SetCachedDeals;
        installedManager = manager;
        print("[LOTM][QDCompat] multiplayer local cache installed reason="..tostring(reason));
    end
    return true;
end

local function LowestAliveMajorID()
    if PlayerManager == nil or PlayerManager.GetAliveMajorIDs == nil then return nil; end
    local ids = PlayerManager.GetAliveMajorIDs();
    table.sort(ids);
    return ids[1];
end

-- Players[id] may expose a non-nil native wrapper for an unused slot.
-- Only the synchronized engine registry establishes which IDs are safe to use.
-- Include eliminated players because older saves may retain their QD caches.
local function LegacyCachePlayerIDs()
    if PlayerManager == nil or type(PlayerManager.GetWasEverAliveIDs) ~= "function" then
        LOTM_StartupTrace.Mark("QDCompat", "CACHE MIGRATION DEFERRED", "registry unavailable");
        return nil;
    end
    LOTM_StartupTrace.Mark("QDCompat", "PLAYER REGISTRY BEFORE", "GetWasEverAliveIDs");
    local registered = PlayerManager.GetWasEverAliveIDs();
    LOTM_StartupTrace.Mark("QDCompat", "PLAYER REGISTRY AFTER", type(registered));
    if type(registered) ~= "table" then
        LOTM_StartupTrace.Mark("QDCompat", "CACHE MIGRATION DEFERRED", "invalid registry");
        return nil;
    end
    local ids = {};
    local seen = {};
    for _, playerID in ipairs(registered) do
        if type(playerID) ~= "number" or playerID < 0 or playerID > 63 or playerID % 1 ~= 0 then
            LOTM_StartupTrace.Mark("QDCompat", "CACHE MIGRATION DEFERRED", "invalid player ID", playerID);
            return nil;
        end
        if not seen[playerID] then
            seen[playerID] = true;
            ids[#ids + 1] = playerID;
        end
    end
    if #ids == 0 then
        LOTM_StartupTrace.Mark("QDCompat", "CACHE MIGRATION DEFERRED", "empty registry");
        return nil;
    end
    table.sort(ids);
    LOTM_StartupTrace.Mark("QDCompat", "PLAYER REGISTRY IDS", #ids, table.concat(ids, ","));
    return ids;
end

local function ClearLegacyCacheAtSynchronizedTurn(anchor)
    local migratedVersion = tonumber(Game.GetProperty(LEGACY_CACHE_MIGRATION_KEY) or 0) or 0;
    if migratedVersion >= LEGACY_CACHE_MIGRATION_VERSION then return; end
    local cleared = 0;
    -- Quick Deals can write these local UI tables before this compatibility
    -- context takes control. Clear them only from a shared Gameplay turn event,
    -- never while GameCore is deserializing a save or network snapshot. This
    -- versioned migration runs once, including on saves with no old QD keys.
    -- Do not gate it on the local ExposedMembers manager: its load timing can
    -- differ between peers, whereas persisted keys and this marker are shared.
    local playerIDs = LegacyCachePlayerIDs();
    if playerIDs == nil then return; end
    for _, playerID in ipairs(playerIDs) do
        local player = Players ~= nil and Players[playerID] or nil;
        if player == nil then
            LOTM_StartupTrace.Mark("QDCompat", "CACHE MIGRATION DEFERRED", "registered player unavailable", playerID);
            return;
        end
        if player ~= nil then
            for _, key in ipairs(LEGACY_CACHE_KEYS) do
                LOTM_StartupTrace.Mark("QDCompat","CACHE READ BEFORE",playerID,key);
                local stored = player:GetProperty(key);
                LOTM_StartupTrace.Mark("QDCompat","CACHE READ AFTER",playerID,key,stored~=nil);
                if stored ~= nil then
                    LOTM_StartupTrace.Mark("QDCompat","CACHE CLEAR BEFORE",playerID,key);
                    player:SetProperty(key,nil);
                    LOTM_StartupTrace.Mark("QDCompat","CACHE CLEAR AFTER",playerID,key);
                    cleared = cleared + 1;
                end
            end
        end
    end
    Game.SetProperty(LEGACY_CACHE_MIGRATION_KEY, LEGACY_CACHE_MIGRATION_VERSION);
    LOTM_StartupTrace.Mark("QDCompat", "CACHE MIGRATION COMPLETE", #playerIDs, cleared, LEGACY_CACHE_MIGRATION_VERSION);
    -- One summary per migration remains useful after verbose tracing is off.
    print("[LOTM][QDCompat] synchronized legacy cache migration complete anchor="
        .. tostring(anchor) .. " players=" .. tostring(#playerIDs)
        .. " entries=" .. tostring(cleared)
        .. " migration=" .. tostring(LEGACY_CACHE_MIGRATION_VERSION));
end

local function LogAbilityIndexFingerprint()
    if GameInfo == nil or GameInfo.UnitAbilities == nil then return; end
    local types = {
        "ABILITY_BP_CONSUMED_CHARGE_1", "ABILITY_BP_CONSUMED_CHARGE_2",
        "ABILITY_NW_UNBOUND_ARMY", "ABILITY_NW_UNBOUND_PEOPLE"
    };
    local values = {};
    for _, abilityType in ipairs(types) do
        local row = GameInfo.UnitAbilities[abilityType];
        values[#values + 1] = abilityType.."="..tostring(row ~= nil and row.Index or "MISSING");
    end
    print("[LOTM][MPFingerprint] UnitAbilities "..table.concat(values, ","));
end

local fingerprintLogged = false;
local function Reconcile(reason)
    InstallLocalCache(reason);
    if not fingerprintLogged then fingerprintLogged = true; LogAbilityIndexFingerprint(); end
end

-- Install only local wrappers at load and synchronized turn anchors. Legacy
-- QD_* properties are deliberately preserved; deleting them during load can
-- corrupt the save/host snapshot and cause an OOS or client exit.
Reconcile("SCRIPT_LOAD");
if Events ~= nil and Events.LoadGameViewStateDone ~= nil then
    Events.LoadGameViewStateDone.Add(function() Reconcile("LOAD_GAME_VIEW_STATE_DONE"); end);
end
if Events ~= nil and Events.LoadScreenClose ~= nil then
    Events.LoadScreenClose.Add(function() Reconcile("LOAD_SCREEN_CLOSE"); end);
end
if GameEvents ~= nil and GameEvents.PlayerTurnStarted ~= nil then
    GameEvents.PlayerTurnStarted.Add(function(playerID)
        if playerID == LowestAliveMajorID() then
            Reconcile("SYNCHRONIZED_WORLD_TURN");
            ClearLegacyCacheAtSynchronizedTurn(playerID);
        end
    end);
end

print("[LOTM][QDCompat] multiplayer local cache guard loaded resource=395 diagnostics=off; legacy QD_* cleanup deferred to synchronized turn");
-- BEGIN RC342 STARTUP TRACE

end
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("LOTM_QD_MultiplayerCompat","CONTEXT END");
-- END RC342 STARTUP TRACE
