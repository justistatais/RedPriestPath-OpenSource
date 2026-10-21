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
LOTM_StartupTrace.Mark("DiplomacyDealView_LOTM_TP","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"DiplomacyDealView_LOTM_TP","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"DiplomacyDealView_LOTM_TP","GameEvents");
local LuaEvents = LOTM_StartupTrace.Events(LuaEvents,"DiplomacyDealView_LOTM_TP","LuaEvents");
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
do
-- END RC342 STARTUP TRACE
-- Single-player Counterfeit Gold extension for the native diplomacy deal view.
-- The native UI continues to show ordinary Gold. After an enacted lump-sum
-- Gold payment, Gameplay substitutes Counterfeit Gold first and leaves the AI
-- with only the ordinary-Gold remainder.

local LOTM_FAKE_GOLD :string = "RESOURCE_LOTM_TP_FAKE_GOLD";
local LOTM_FAKE_GOLD_TRADE :string = "RESOURCE_LOTM_TP_FAKE_GOLD_TRADE";
local LOTM_SETTLE_COMMAND :string = "LOTM_TP_Command_SettleFakeGoldDeal";
local LOTM_PATH_THIEF :string = "PATH_THIEF";

local m_pendingGoldPayment :table = nil;
local m_settlementQueue :table = {};
local m_serialCounter :number = 0;

local function IsSinglePlayer()
	return GameConfiguration == nil
		or GameConfiguration.IsAnyMultiplayer == nil
		or GameConfiguration.IsAnyMultiplayer() ~= true;
end

local function ResourceIndex(resourceType :string)
	local row = GameInfo.Resources[resourceType];
	return row ~= nil and row.Index or -1;
end

local function ResourceAmount(player :table, resourceType :string)
	local index = ResourceIndex(resourceType);
	local resources = player ~= nil and player:GetResources() or nil;
	if index < 0 or resources == nil then return 0; end
	return math.max(0, math.floor(tonumber(resources:GetResourceAmount(index)) or 0));
end

local function GoldBalance(player :table)
	local treasury = player ~= nil and player:GetTreasury() or nil;
	return treasury ~= nil and (tonumber(treasury:GetGoldBalance()) or 0) or 0;
end

local function IsEligiblePayer(player :table)
	return IsSinglePlayer() and player ~= nil and g_LocalPlayer ~= nil
		and player:GetID() == g_LocalPlayer:GetID()
		and tostring(player:GetProperty("LOTM_RP_PATH") or "NONE") == LOTM_PATH_THIEF
		and (tonumber(player:GetProperty("LOTM_RP_SEQUENCE") or 9) or 9) <= 8;
end

-- Keep both the visible Counterfeit Gold stockpile and the legacy hidden
-- carrier out of the ordinary strategic-resource trade list. Players now use
-- the native Gold row, so no separate Counterfeit Gold offer is shown.
local function PopulateFilteredStrategicResources(player :table, iconList :table)
	local count :number = 0;
	local pForDeal = DealManager.GetWorkingDeal(
		DealDirection.OUTGOING, g_LocalPlayer:GetID(), g_OtherPlayer:GetID());
	local possible = DealManager.GetPossibleDealItems(
		player:GetID(), GetOtherPlayer(player):GetID(), DealItemTypes.RESOURCES, pForDeal);
	if possible ~= nil then
		for _, entry in ipairs(possible) do
			local resource = GameInfo.Resources[entry.ForType];
			if resource ~= nil and entry.MaxAmount > 0
				and resource.ResourceClassType == "RESOURCECLASS_STRATEGIC"
				and resource.ResourceType ~= LOTM_FAKE_GOLD
				and resource.ResourceType ~= LOTM_FAKE_GOLD_TRADE then
				local uiIcon = g_IconOnlyIM:GetInstance(iconList.ListStack);
				SetIconToSize(uiIcon.Icon, "ICON_" .. resource.ResourceType);
				uiIcon.AmountText:SetText(tostring(entry.MaxAmount));
				uiIcon.AmountText:SetHide(false);
				uiIcon.RemoveButton:SetHide(true);
				uiIcon.StopAskingButton:SetHide(true);
				uiIcon.SelectButton:SetDisabled(not entry.IsValid);
				local resourceType = entry.ForType;
				uiIcon.SelectButton:RegisterCallback(Mouse.eLClick, function()
					OnClickAvailableResource(player, resourceType);
				end);
				uiIcon.SelectButton:LocalizeAndSetToolTip(resource.Name);
				count = count + 1;
			end
		end
		iconList.ListStack:CalculateSize();
	end
	iconList.GetTopControl():SetHide(iconList.ListStack:GetSizeX() == 0);
	return count;
end

local LOTM_BasePopulateAvailableStrategicResources = PopulateAvailableStrategicResources;
function PopulateAvailableStrategicResources(player :table, iconList :table)
	if not IsSinglePlayer() then
		return LOTM_BasePopulateAvailableStrategicResources(player, iconList);
	end
	return PopulateFilteredStrategicResources(player, iconList);
end

local function CapturePendingGoldPayment()
	m_pendingGoldPayment = nil;
	if not IsEligiblePayer(g_LocalPlayer) or g_OtherPlayer == nil
		or ResourceAmount(g_LocalPlayer, LOTM_FAKE_GOLD) <= 0 then
		return;
	end
	local pDeal = DealManager.GetWorkingDeal(
		DealDirection.OUTGOING, g_LocalPlayer:GetID(), g_OtherPlayer:GetID());
	if pDeal == nil then return; end
	local outgoing, incoming = 0, 0;
	local itemIdentity :table = {};
	for item in pDeal:Items() do
		if item:GetType() == DealItemTypes.GOLD
			and item:GetDuration() == 0 and item:GetAmount() > 0 then
			local amount = math.floor(item:GetAmount());
			if item:GetFromPlayerID() == g_LocalPlayer:GetID() then
				outgoing = outgoing + amount;
			elseif item:GetFromPlayerID() == g_OtherPlayer:GetID() then
				incoming = incoming + amount;
			end
			itemIdentity[#itemIdentity + 1] = tostring(math.floor(item:GetID()));
		end
	end
	if outgoing <= 0 then return; end
	m_serialCounter = m_serialCounter + 1;
	local fakeGoldBefore = ResourceAmount(g_LocalPlayer, LOTM_FAKE_GOLD);
	m_pendingGoldPayment = {
		FromPlayerID = g_LocalPlayer:GetID(),
		ToPlayerID = g_OtherPlayer:GetID(),
		Amount = outgoing,
		IncomingAmount = incoming,
		PayerGoldBefore = GoldBalance(g_LocalPlayer),
		RecipientGoldBefore = GoldBalance(g_OtherPlayer),
		Serial = "NATIVE:" .. tostring(Game.GetCurrentGameTurn())
			.. ":" .. tostring(g_LocalPlayer:GetID()) .. ":" .. tostring(g_OtherPlayer:GetID())
			.. ":" .. tostring(outgoing) .. ":" .. tostring(math.floor(GoldBalance(g_LocalPlayer)))
			.. ":" .. tostring(fakeGoldBefore) .. ":" .. tostring(m_serialCounter)
			.. ":" .. table.concat(itemIdentity, "_"),
		Attempts = 0,
	};
end

local LOTM_BaseProposeWorkingDeal = ProposeWorkingDeal;
function ProposeWorkingDeal(isAutoPropose :boolean)
	CapturePendingGoldPayment();
	return LOTM_BaseProposeWorkingDeal(isAutoPropose);
end

local LOTM_BaseOnProposeOrAcceptDeal = OnProposeOrAcceptDeal;
function OnProposeOrAcceptDeal()
	CapturePendingGoldPayment();
	return LOTM_BaseOnProposeOrAcceptDeal();
end

local function SubmitSettlement(entry :table)
	UI.RequestPlayerOperation(entry.FromPlayerID, PlayerOperations.EXECUTE_SCRIPT, {
		OnStart = LOTM_SETTLE_COMMAND,
		FromPlayerID = entry.FromPlayerID,
		ToPlayerID = entry.ToPlayerID,
		Amount = entry.Amount,
		IncomingAmount = entry.IncomingAmount,
		PayerGoldBefore = entry.PayerGoldBefore,
		RecipientGoldBefore = entry.RecipientGoldBefore,
		Serial = entry.Serial,
	});
	entry.Attempts = entry.Attempts + 1;
end

local function OnGoldDealEnacted()
	local entry = m_pendingGoldPayment;
	m_pendingGoldPayment = nil;
	if not IsSinglePlayer() or entry == nil then return; end
	-- The enacted notification may arrive just before the UI observes the native
	-- treasury deltas. Gameplay validates the exact before/after balances, while
	-- this bounded idempotent queue retries across publish boundaries.
	m_settlementQueue[#m_settlementQueue + 1] = entry;
	SubmitSettlement(entry);
end

local function OnGoldIncomingDeal(fromPlayerID :number, toPlayerID :number, action :number)
	if action == DealProposalAction.REJECTED
		or action == DealProposalAction.REJECTED_PERMANENT
		or action == DealProposalAction.EQUALIZE_FAILED
		or action == DealProposalAction.CLOSED then
		m_pendingGoldPayment = nil;
	end
end

local function OnGoldDealSessionOpened()
	m_pendingGoldPayment = nil;
end

local function RetryGoldSettlements()
	if not IsSinglePlayer() or #m_settlementQueue == 0 then return; end
	local waiting :table = {};
	for _, entry in ipairs(m_settlementQueue) do
		local payer = Players[entry.FromPlayerID];
		local settled = payer ~= nil
			and payer:GetProperty("LOTM_TP_LAST_FAKE_GOLD_SETTLEMENT_SERIAL") or nil;
		if tostring(settled or "") ~= entry.Serial and entry.Attempts < 5 then
			SubmitSettlement(entry);
			waiting[#waiting + 1] = entry;
		end
	end
	m_settlementQueue = waiting;
end

Events.DiplomacyDealEnacted.Add(OnGoldDealEnacted);
Events.DiplomacyIncomingDeal.Add(OnGoldIncomingDeal);
Events.GameCoreEventPublishComplete.Add(RetryGoldSettlements);
LuaEvents.DiploPopup_ShowMakeDeal.Add(OnGoldDealSessionOpened);
LuaEvents.DiploPopup_ShowMakeDemand.Add(OnGoldDealSessionOpened);
-- BEGIN RC342 STARTUP TRACE

end
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("DiplomacyDealView_LOTM_TP","CONTEXT END");
-- END RC342 STARTUP TRACE
