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
LOTM_StartupTrace.Mark("LOTM_BE_EventObserver","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"LOTM_BE_EventObserver","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"LOTM_BE_EventObserver","GameEvents");
local LuaEvents = LOTM_StartupTrace.Events(LuaEvents,"LOTM_BE_EventObserver","LuaEvents");
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
do
-- END RC342 STARTUP TRACE
-- Read-only observer for official UI-only events. It never writes Gameplay
-- state directly; validated requests are submitted through EXECUTE_SCRIPT.

local LOTM_BE_PATH :string = "PATH_BLACK_EMPEROR";
local PURCHASE_COMMAND :string = "LOTM_BE_Command_GoldPurchase";
local RESCUE_GOLD_MILITARY_COMMAND :string = "LOTM_RESCUE_P9_Command_GoldMilitaryPurchase";
local RESCUE_TRAINED_COMMAND :string = "LOTM_RESCUE_P9_Command_MilitaryTrained";
-- OrderTypes is not exported in every UI context. Firaxis TutorialUIRoot uses
-- the stable event payload value 0 for ORDER_TRAIN.
local ORDER_TRAIN :number = 0;

local m_lastGoldBalance :number = nil;
local m_goldSpendCredits :table = {};
local m_purchaseCandidates :table = {};
local m_greatPersonOffers :table = {};
local m_serial :number = 0;

local function GetLocalPlayer()
	local playerID = Game.GetLocalPlayer();
	if playerID == nil or playerID < 0 then
		return -1, nil;
	end
	return playerID, Players[playerID];
end

local function IsBlackEmperorSequence(sequence :number)
	local _, player = GetLocalPlayer();
	return player ~= nil
		and player:GetProperty("LOTM_RP_PATH") == LOTM_BE_PATH
		and (player:GetProperty("LOTM_RP_SEQUENCE") or 9) == sequence;
end

local function IsRescueRedPriestSequence(sequence :number)
	local _, player = GetLocalPlayer();
	return player ~= nil
		and (Game:GetProperty("LOTM_RESCUE_MODE") or 0) == 1
		and player:GetProperty("LOTM_RP_PATH") == "PATH_RED_PRIEST"
		and (player:GetProperty("LOTM_RP_SEQUENCE") or 9) == sequence;
end

local function Submit(command :string, parameters :table)
	local playerID, player = GetLocalPlayer();
	if player == nil or not player:IsTurnActive() then
		return;
	end
	parameters.OnStart = command;
	UI.RequestPlayerOperation(playerID, PlayerOperations.EXECUTE_SCRIPT, parameters);
end

local function QueueCandidate(kind :string, details :table)
	table.insert(m_purchaseCandidates, {
		kind = kind,
		turn = Game.GetCurrentGameTurn(),
		details = details or {},
	});
end

local function CaptureCurrentGoldBalance()
	local _, player = GetLocalPlayer();
	if player == nil then
		return;
	end
	local balance = player:GetTreasury():GetGoldBalance();
	if m_lastGoldBalance ~= nil and balance < m_lastGoldBalance then
		table.insert(m_goldSpendCredits, {
			turn = Game.GetCurrentGameTurn(),
			amount = m_lastGoldBalance - balance,
		});
	end
	m_lastGoldBalance = balance;
end

local function TryDispatchPurchases()
	local currentTurn = Game.GetCurrentGameTurn();
	-- Clear stale halves before pairing.  The old order paired an unmatched
	-- previous-turn credit with a new purchase and discarded both.
	while #m_goldSpendCredits > 0 and m_goldSpendCredits[1].turn < currentTurn do
		table.remove(m_goldSpendCredits, 1);
	end
	while #m_purchaseCandidates > 0 and m_purchaseCandidates[1].turn < currentTurn do
		table.remove(m_purchaseCandidates, 1);
	end
	while #m_goldSpendCredits > 0 and #m_purchaseCandidates > 0 do
		local candidate = m_purchaseCandidates[1];
		local creditIndex = 1;
		if candidate.kind == "GREAT_PERSON" then
			creditIndex = nil;
			for index, credit in ipairs(m_goldSpendCredits) do
				if credit.turn == candidate.turn
					and credit.amount == (candidate.details.GoldCost or math.huge) then
					creditIndex = index;
					break;
				end
			end
			if creditIndex == nil then
				break;
			end
		end
		local credit = table.remove(m_goldSpendCredits, creditIndex);
		table.remove(m_purchaseCandidates, 1);
		if credit.turn == candidate.turn
			and candidate.kind ~= "EXCLUDED"
			and (candidate.kind ~= "GREAT_PERSON"
				or credit.amount == (candidate.details.GoldCost or math.huge)) then
			m_serial = m_serial + 1;
			local serial = tostring(currentTurn) .. ":" .. tostring(m_serial);
			if IsBlackEmperorSequence(6) then
				Submit(PURCHASE_COMMAND, {
					Kind = candidate.kind,
					Serial = serial,
					IndividualID = candidate.details.IndividualID,
					GoldCost = candidate.details.GoldCost,
					GoldSpent = credit.amount,
				});
			elseif IsRescueRedPriestSequence(6) and candidate.kind == "UNIT" then
				Submit(RESCUE_GOLD_MILITARY_COMMAND, {
					Serial = serial,
					UnitType = candidate.details.ObjectType,
					GoldSpent = credit.amount,
				});
			end
		end
	end
end

local function OnCityProductionCompleted(playerID, cityID, orderType, unitType, canceled, typeModifier)
	if playerID ~= Game.GetLocalPlayer()
		or canceled == true
		or orderType ~= ORDER_TRAIN
		or (not IsRescueRedPriestSequence(6) and not IsRescueRedPriestSequence(3)) then
		return;
	end
	m_serial = m_serial + 1;
	Submit(RESCUE_TRAINED_COMMAND, {
		Serial = tostring(Game.GetCurrentGameTurn()) .. ":" .. tostring(m_serial)
			.. ":" .. tostring(cityID),
		UnitType = unitType,
		CityID = cityID,
		TypeModifier = typeModifier,
	});
end

local function OnTreasuryChanged(playerID :number, yieldType :number, balance :number)
	local localPlayerID = Game.GetLocalPlayer();
	if playerID ~= localPlayerID or yieldType ~= YieldTypes.GOLD then
		return;
	end
	if m_lastGoldBalance ~= nil and balance < m_lastGoldBalance then
		table.insert(m_goldSpendCredits, {
			turn = Game.GetCurrentGameTurn(),
			amount = m_lastGoldBalance - balance,
		});
	end
	m_lastGoldBalance = balance;
	TryDispatchPurchases();
end

local function OnCityMadePurchase(
	owner :number,
	cityID :number,
	plotX :number,
	plotY :number,
	purchaseType,
	objectType
)
	if owner ~= Game.GetLocalPlayer() then
		return;
	end
	CaptureCurrentGoldBalance();
	if purchaseType == EventSubTypes.UNIT then
		QueueCandidate("UNIT", { ObjectType = objectType });
	elseif purchaseType == EventSubTypes.BUILDING then
		QueueCandidate("BUILDING", { ObjectType = objectType });
	else
		-- Districts and plots consume a matching gold change but do not digest.
		QueueCandidate("EXCLUDED");
	end
	TryDispatchPurchases();
end

local function RefreshGreatPersonOffers()
	local playerID = Game.GetLocalPlayer();
	local greatPeople = Game.GetGreatPeople();
	if playerID == nil or playerID < 0 or greatPeople == nil then
		return;
	end
	for _, entry in ipairs(greatPeople:GetTimeline()) do
		if entry.Individual ~= nil then
			local cost = greatPeople:GetPatronizeCost(
				playerID,
				entry.Individual,
				YieldTypes.GOLD
			);
			local info = GameInfo.GreatPersonIndividuals[entry.Individual];
			if info ~= nil and info.UnitType ~= nil
				and cost ~= nil and cost > 0 and cost < 1000000 then
				m_greatPersonOffers[info.UnitType] = {
					IndividualID = entry.Individual,
					GoldCost = cost,
				};
			end
		end
	end
end

local function IsClaimedByLocalPlayer(individualID :number)
	local greatPeople = Game.GetGreatPeople();
	if greatPeople == nil then
		return false;
	end
	for _, entry in ipairs(greatPeople:GetPastTimeline()) do
		if entry.Individual == individualID
			and entry.Claimant == Game.GetLocalPlayer() then
			return true;
		end
	end
	return false;
end

local function OnUnitAddedToMap(playerID :number, unitID :number)
	if playerID ~= Game.GetLocalPlayer() then
		return;
	end
	local player = Players[playerID];
	local unit = player ~= nil and player:GetUnits():FindID(unitID) or nil;
	local info = unit ~= nil and GameInfo.Units[unit:GetType()] or nil;
	local offer = info ~= nil and m_greatPersonOffers[info.UnitType] or nil;
	if offer ~= nil and IsClaimedByLocalPlayer(offer.IndividualID) then
		CaptureCurrentGoldBalance();
		QueueCandidate("GREAT_PERSON", offer);
		TryDispatchPurchases();
	end
end

local function ResetBaselines()
	m_goldSpendCredits = {};
	m_purchaseCandidates = {};
	m_greatPersonOffers = {};
	local _, player = GetLocalPlayer();
	m_lastGoldBalance = player ~= nil and player:GetTreasury():GetGoldBalance() or nil;
	RefreshGreatPersonOffers();
end

local function OnPublishComplete()
	CaptureCurrentGoldBalance();
	TryDispatchPurchases();
	RefreshGreatPersonOffers();
end

local function Initialize()
	ContextPtr:SetHide(true);
	Events.CityMadePurchase.Add(OnCityMadePurchase);
	Events.TreasuryChanged.Add(OnTreasuryChanged);
	Events.UnitAddedToMap.Add(OnUnitAddedToMap);
	Events.CityProductionCompleted.Add(OnCityProductionCompleted);
	Events.GameCoreEventPublishComplete.Add(OnPublishComplete);
	Events.LocalPlayerChanged.Add(ResetBaselines);
	Events.LoadGameViewStateDone.Add(ResetBaselines);
	ResetBaselines();
end

Initialize();
-- BEGIN RC342 STARTUP TRACE

end
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("LOTM_BE_EventObserver","CONTEXT END");
-- END RC342 STARTUP TRACE
