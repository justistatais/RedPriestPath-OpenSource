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
LOTM_StartupTrace.Mark("LOTM_AI_Cult_Diplomacy_QuickDeals","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"LOTM_AI_Cult_Diplomacy_QuickDeals","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"LOTM_AI_Cult_Diplomacy_QuickDeals","GameEvents");
local LuaEvents = LOTM_StartupTrace.Events(LuaEvents,"LOTM_AI_Cult_Diplomacy_QuickDeals","LuaEvents");
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
do
-- END RC342 STARTUP TRACE
-- Keep Quick Deals fully loaded exactly as supplied by its own mod. The
-- wrapper appends the Red Priest diplomacy row and, in single-player only,
-- observes Quick Deals' public start/end events so a Thief's ordinary
-- lump-sum Gold payment can use Counterfeit Gold first. No Quick Deals source,
-- cache, launch button, valuation, or multiplayer behavior is replaced.
include("diplomacyactionview_qd.lua");
include("LOTM_AI_Cult_Diplomacy_Extension.lua");

local LOTM_QD_SETTLE_COMMAND :string = "LOTM_TP_Command_SettleFakeGoldDeal";
local LOTM_QD_FAKE_GOLD :string = "RESOURCE_LOTM_TP_FAKE_GOLD";
local m_LOTMQDPending :table = nil;
local m_LOTMQDSettlementQueue :table = {};
local m_LOTMQDSerial :number = 0;

local function LOTM_QD_IsSinglePlayer()
	local rescueMode = GameConfiguration ~= nil and GameConfiguration.GetValue ~= nil
		and GameConfiguration.GetValue("GAMEMODE_LOTM_RESCUE") or 0;
	return rescueMode ~= true and tonumber(rescueMode or 0) ~= 1
		and (GameConfiguration == nil
		or GameConfiguration.IsAnyMultiplayer == nil
		or GameConfiguration.IsAnyMultiplayer() ~= true);
end

local function LOTM_QD_GoldBalance(player :table)
	local treasury = player ~= nil and player:GetTreasury() or nil;
	return treasury ~= nil and (tonumber(treasury:GetGoldBalance()) or 0) or 0;
end

local function LOTM_QD_FakeGold(player :table)
	local row = GameInfo.Resources[LOTM_QD_FAKE_GOLD];
	local resources = player ~= nil and player:GetResources() or nil;
	if row == nil or resources == nil then return 0; end
	return math.max(0, math.floor(tonumber(resources:GetResourceAmount(row.Index)) or 0));
end

local function LOTM_QD_IsEligible(playerID :number)
	local player = Players[playerID];
	return LOTM_QD_IsSinglePlayer() and player ~= nil
		and playerID == Game.GetLocalPlayer()
		and tostring(player:GetProperty("LOTM_RP_PATH") or "NONE") == "PATH_THIEF"
		and (tonumber(player:GetProperty("LOTM_RP_SEQUENCE") or 9) or 9) <= 8
		and LOTM_QD_FakeGold(player) > 0;
end

local function LOTM_QD_OnStartAccept(playerID :number, otherPlayerID :number)
	m_LOTMQDPending = nil;
	if not LOTM_QD_IsEligible(playerID) then return; end
	local payer, recipient = Players[playerID], Players[otherPlayerID];
	if recipient == nil then return; end
	m_LOTMQDPending = {
		FromPlayerID = playerID,
		ToPlayerID = otherPlayerID,
		PayerGoldBefore = LOTM_QD_GoldBalance(payer),
		RecipientGoldBefore = LOTM_QD_GoldBalance(recipient),
		FakeGoldBefore = LOTM_QD_FakeGold(payer),
	};
end

local function LOTM_QD_Submit(entry :table)
	UI.RequestPlayerOperation(entry.FromPlayerID, PlayerOperations.EXECUTE_SCRIPT, {
		OnStart = LOTM_QD_SETTLE_COMMAND,
		FromPlayerID = entry.FromPlayerID,
		ToPlayerID = entry.ToPlayerID,
		Amount = entry.Amount,
		IncomingAmount = 0,
		PayerGoldBefore = entry.PayerGoldBefore,
		RecipientGoldBefore = entry.RecipientGoldBefore,
		Serial = entry.Serial,
	});
	entry.Attempts = entry.Attempts + 1;
end

local function LOTM_QD_OnEndAccept(offeredItems :table)
	local entry = m_LOTMQDPending;
	m_LOTMQDPending = nil;
	if entry == nil or offeredItems == nil then return; end
	local amount = 0;
	for _, item in ipairs(offeredItems) do
		if item.Type == DealItemTypes.GOLD
			and tonumber(item.Duration or 0) == 0 then
			amount = amount + math.max(0, math.floor(tonumber(item.Amount) or 0));
		end
	end
	if amount <= 0 then return; end
	local payer, recipient = Players[entry.FromPlayerID], Players[entry.ToPlayerID];
	if math.abs(LOTM_QD_GoldBalance(payer) - (entry.PayerGoldBefore - amount)) >= 0.001
		or math.abs(LOTM_QD_GoldBalance(recipient) - (entry.RecipientGoldBefore + amount)) >= 0.001 then
		return;
	end
	m_LOTMQDSerial = m_LOTMQDSerial + 1;
	entry.Amount = amount;
	entry.Serial = "QD:" .. tostring(Game.GetCurrentGameTurn())
		.. ":" .. tostring(entry.FromPlayerID) .. ":" .. tostring(entry.ToPlayerID)
		.. ":" .. tostring(amount) .. ":" .. tostring(math.floor(entry.PayerGoldBefore))
		.. ":" .. tostring(entry.FakeGoldBefore) .. ":" .. tostring(m_LOTMQDSerial);
	entry.Attempts = 0;
	m_LOTMQDSettlementQueue[#m_LOTMQDSettlementQueue + 1] = entry;
	LOTM_QD_Submit(entry);
end

local function LOTM_QD_RetrySettlements()
	if not LOTM_QD_IsSinglePlayer() or #m_LOTMQDSettlementQueue == 0 then return; end
	local waiting :table = {};
	for _, entry in ipairs(m_LOTMQDSettlementQueue) do
		local payer = Players[entry.FromPlayerID];
		local settled = payer ~= nil
			and payer:GetProperty("LOTM_TP_LAST_FAKE_GOLD_SETTLEMENT_SERIAL") or nil;
		if tostring(settled or "") ~= entry.Serial and entry.Attempts < 5 then
			LOTM_QD_Submit(entry);
			waiting[#waiting + 1] = entry;
		end
	end
	m_LOTMQDSettlementQueue = waiting;
end

LuaEvents.QD_StartAIOfferAccept.Add(LOTM_QD_OnStartAccept);
LuaEvents.QD_EndAIOfferAccept.Add(LOTM_QD_OnEndAccept);
Events.GameCoreEventPublishComplete.Add(LOTM_QD_RetrySettlements);
-- BEGIN RC342 STARTUP TRACE

end
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("LOTM_AI_Cult_Diplomacy_QuickDeals","CONTEXT END");
-- END RC342 STARTUP TRACE
