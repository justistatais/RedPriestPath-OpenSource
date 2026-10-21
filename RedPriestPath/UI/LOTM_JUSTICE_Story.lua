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
LOTM_StartupTrace.Mark("LOTM_JUSTICE_Story","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"LOTM_JUSTICE_Story","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"LOTM_JUSTICE_Story","GameEvents");
local LuaEvents = LOTM_StartupTrace.Events(LuaEvents,"LOTM_JUSTICE_Story","LuaEvents");
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
do
-- END RC342 STARTUP TRACE
-- UI reads the native governor object and submits changes through EXECUTE_SCRIPT.
-- Gameplay alone owns the persistent counters and the production completion.
local GOVERNOR="GOVERNOR_LOTM_JUSTICE";
local PROMOTIONS={
 "GOVERNOR_PROMOTION_LOTM_JUSTICE_SPONSOR",
 "GOVERNOR_PROMOTION_LOTM_JUSTICE_COUNSEL",
 "GOVERNOR_PROMOTION_LOTM_JUSTICE_SALON",
 "GOVERNOR_PROMOTION_LOTM_JUSTICE_SUGGESTION",
 "GOVERNOR_PROMOTION_LOTM_JUSTICE_TAROT",
 "GOVERNOR_PROMOTION_LOTM_JUSTICE_STORY"
};
local lastSnapshot=nil;
local snapshotPolls=0;
local snapshotAttempts=0;
local loadAuditSerial=nil;
local snapshotSerial=nil;
local snapshotTurn=-1;
local auditTurn=-1;
local auditPolls=0;
local auditAttempts=0;
local uiLogState={};
local function UILog(key,message)
 local value=tostring(Game.GetCurrentGameTurn())..":"..message;
 if uiLogState[key]~=value then
  uiLogState[key]=value;
  print("[LOTM_JUSTICE][UI] "..message);
 end
end
local lastState=nil;
local productionAuditCityIDs=nil;
local productionAuditWasFull=false;

local function ProductionAuditData(p,state)
 local version=tonumber(p:GetProperty("JUSTICE_PRODUCTION_AUDIT_VERSION") or 0) or 0;
 if productionAuditWasFull and version>=1 then productionAuditCityIDs=nil; productionAuditWasFull=false; end
 if productionAuditCityIDs==nil then
  local seen={}; productionAuditCityIDs={};
  local function Add(id)
   if id~=nil and id>=0 and not seen[id] then
    seen[id]=true; productionAuditCityIDs[#productionAuditCityIDs+1]=id;
   end
  end
  Add(state.CityID);
  local tracked=p:GetProperty("JUSTICE_PRODUCTION_AUDIT_CITIES") or "";
  for id in tostring(tracked):gmatch("%d+") do Add(tonumber(id)); end
  -- A single old-save migration scan, then only known affected cities.
  if version<1 and (tonumber(p:GetProperty("JUSTICE_STORY_PAUSE_SOURCE_VERSION") or 0) or 0)>0 then
   for _,city in p:GetCities():Members() do Add(city:GetID()); end
   productionAuditWasFull=true;
  end
  table.sort(productionAuditCityIDs);
 end
 local records={};
 for _,id in ipairs(productionAuditCityIDs) do
  local city=p:GetCities():FindID(id);
  if city~=nil and city:GetOwner()==Game.GetLocalPlayer() then
   local tip=city:GetYieldToolTip(YieldTypes.PRODUCTION);
   if type(tip)~="string" then return nil,"city="..id.." tooltipType="..type(tip); end
   local exceptional=0;
   -- Native localization uses signed integer +#;-# for percentages (no
   -- grouping/decimal separator). Keep ordinary bonuses in the remainder.
   for number in tip:gmatch("([%+%-]%d+)%%") do
    local amount=tonumber(number);
    local units=math.floor(math.abs(amount)/1000+0.5);
    if units>0 and math.abs(math.abs(amount)-units*1000)<=100 then
     if exceptional~=0 then return nil,"city="..id.." ambiguous percentages"; end
     exceptional=amount;
    end
   end
   records[#records+1]=id..","..exceptional..","..tostring(city:GetYield(YieldTypes.PRODUCTION));
  end
 end
 return table.concat(records,";");
end

local function EntryKind(entry)
 if entry==nil then return "NONE",-1; end
 if entry.Directive==CityProductionDirectives.CONSTRUCT then return "BUILDING",entry.BuildingType; end
 if entry.Directive==CityProductionDirectives.PROJECT then return "PROJECT",entry.ProjectType; end
 if entry.Directive==CityProductionDirectives.TRAIN then return "UNIT",entry.UnitType; end
 if entry.Directive==CityProductionDirectives.ZONE then return "DISTRICT",entry.DistrictType; end
 return "NONE",-1;
end

local function LocalPlayer()
 local id=Game.GetLocalPlayer();
 if id==nil or id<0 then return nil,nil; end
 return id,Players[id];
end

local function Snapshot()
 local id,p=LocalPlayer(); if p==nil then return nil,nil,nil; end
 local row=GameInfo.Governors[GOVERNOR]; if row==nil then return nil,nil,nil; end
 local state={CityID=-1,Established=0,Neutralized=0};
 for _,name in ipairs(PROMOTIONS) do state[name]=0; end
 local count,list=p:GetGovernors():GetGovernorList();
 if list==nil and (tonumber(count) or 0)>0 then return id,p,nil; end
 for _,governor in ipairs(list or {}) do
  if governor:GetType()==row.Index then
   local city=governor:GetAssignedCity();
   if city~=nil and city:GetOwner()==id then state.CityID=city:GetID(); end
   if governor:IsEstablished() then state.Established=1; end
   if (governor:GetNeutralizedTurns() or 0)>0 then state.Neutralized=1; end
   for _,name in ipairs(PROMOTIONS) do
    local promotion=GameInfo.GovernorPromotions[name];
    if promotion~=nil and governor:HasPromotion(promotion.Hash) then state[name]=1; end
   end
   break;
  end
 end
 return id,p,state;
end

local function SyncGovernor(id,p,state,forceRetry)
 if state==nil then UILog("snapshot","snapshot waiting for native governor list"); return false; end
 if snapshotSerial==nil then
  local raw=p:GetProperty("JUSTICE_GOVERNOR_SNAPSHOT_SERIAL");
  snapshotSerial=(tonumber(raw) or 0)+1;
 end
 local parts={tostring(state.CityID),tostring(state.Established),tostring(state.Neutralized)};
 for _,name in ipairs(PROMOTIONS) do parts[#parts+1]=tostring(state[name]); end
 local digest=table.concat(parts,":");
 local rawAck=p:GetProperty("JUSTICE_GOVERNOR_SNAPSHOT_SERIAL");
 if p:GetProperty("JUSTICE_GOVERNOR_SNAPSHOT_DIGEST")==digest
  and (tonumber(rawAck) or 0)>=snapshotSerial then
  UILog("snapshot","snapshot acknowledged serial="..snapshotSerial.." city="..state.CityID);
  return true;
 end
 local turn=Game.GetCurrentGameTurn();
 if digest~=lastSnapshot or snapshotTurn~=turn then
  lastSnapshot=digest; snapshotTurn=turn; snapshotPolls=0; snapshotAttempts=0;
 end
 snapshotPolls=snapshotPolls+1;
 if not p:IsTurnActive() then UILog("snapshot","snapshot waiting for active player turn="..turn); return false; end
 if snapshotAttempts>=12 then UILog("snapshot","snapshot retry budget reached turn="..turn); return false; end
 if snapshotAttempts>0 and not forceRetry and snapshotPolls<20 then return false; end
 snapshotAttempts=snapshotAttempts+1; snapshotPolls=0;
 state.OnStart="LOTM_JUSTICE_UpdateGovernor";
 state.SnapshotSerial=snapshotSerial;
 -- Ownership must reach Gameplay even when production observations are absent.
 local ok,accepted=pcall(UI.RequestPlayerOperation,id,PlayerOperations.EXECUTE_SCRIPT,state);
 UILog("snapshot","snapshot submitted serial="..snapshotSerial.." attempt="..snapshotAttempts
  .." city="..state.CityID.." nativeStory="..tostring(state[PROMOTIONS[6]])
  .." accepted="..tostring(ok and accepted~=false));
 return false;
end

local function SyncProductionAudit(id,p,state,forceRetry)
 if loadAuditSerial==nil then
  local raw=p:GetProperty("JUSTICE_STORY_LOAD_AUDIT_SERIAL");
  loadAuditSerial=(tonumber(raw) or 0)+1;
 end
 local rawAck=p:GetProperty("JUSTICE_STORY_LOAD_AUDIT_SERIAL");
 if (tonumber(rawAck) or 0)>=loadAuditSerial then
  if (tonumber(p:GetProperty("JUSTICE_PRODUCTION_VERIFY_NEEDED") or 0) or 0)==1 then
   loadAuditSerial=(tonumber(rawAck) or 0)+1; auditAttempts=0; auditPolls=0;
  else
   UILog("audit","production audit acknowledged serial="..loadAuditSerial);
   return;
  end
 end
 local turn=Game.GetCurrentGameTurn();
 if auditTurn~=turn then auditTurn=turn; auditPolls=0; auditAttempts=0; end
 auditPolls=auditPolls+1;
 if not p:IsTurnActive() or auditAttempts>=12 then return; end
 if auditAttempts>0 and not forceRetry and auditPolls<20 then return; end
 auditAttempts=auditAttempts+1; auditPolls=0;
 local readOK,data,reason=pcall(ProductionAuditData,p,state);
 if not readOK or data==nil then
  UILog("audit","production audit deferred: "..tostring(readOK and reason or data));
  return;
 end
 local ok,accepted=pcall(UI.RequestPlayerOperation,id,PlayerOperations.EXECUTE_SCRIPT,{
  OnStart="LOTM_JUSTICE_AuditProduction",LoadAuditSerial=loadAuditSerial,
  GovernorSnapshotSerial=snapshotSerial,ProductionAuditData=data});
 UILog("audit","production audit submitted serial="..loadAuditSerial.." attempt="..auditAttempts
  .." accepted="..tostring(ok and accepted~=false));
end

local function Refresh(forceSync)
 Controls.StoryPanel:SetHide(true);
 local id,p=LocalPlayer(); if p==nil then return; end
 if forceSync or lastState==nil then
  local _,_,state=Snapshot();
  lastState=state;
 end
 local state=lastState;
 if SyncGovernor(id,p,state,forceSync) then SyncProductionAudit(id,p,state,forceSync); end
 if tonumber(p:GetProperty("JUSTICE_STORY_PENDING") or 0)~=1 then
  return;
 end
 if state==nil or state.Established~=1 or state.Neutralized~=0
  or state["GOVERNOR_PROMOTION_LOTM_JUSTICE_STORY"]~=1 then return; end
 if tonumber(p:GetProperty("JUSTICE_STORY_PENDING_TURN") or -1)~=Game.GetCurrentGameTurn() then return; end
 local cityID=tonumber(p:GetProperty("JUSTICE_STORY_CITY_ID") or -1);
 if cityID~=state.CityID then return; end
 local city=p:GetCities():FindID(cityID); if city==nil then return; end
 Controls.CompleteButton:SetDisabled(false);
 local result=p:GetProperty("JUSTICE_STORY_RESULT");
 Controls.HintLabel:SetText(Locale.Lookup(result or "LOC_LOTM_JUSTICE_STORY_HINT"));
 Controls.CityLabel:SetText(Locale.Lookup(city:GetName()));
 Controls.StoryPanel:SetHide(false);
 UILog("panel","story panel shown city="..cityID.." turn="..Game.GetCurrentGameTurn()
  .." contextHidden="..tostring(ContextPtr:IsHidden())
  .." originalCaptured="..tostring(p:GetProperty("JUSTICE_STORY_ORIGINAL_CAPTURED") or 0));
end

local function ClickFeedback(key)
 Controls.HintLabel:SetText(Locale.Lookup(key));
 UILog("click",key);
end

local function Complete()
 UILog("click","complete clicked");
 local id,p,state=Snapshot();
 if p==nil or state==nil then ClickFeedback("LOC_LOTM_JUSTICE_STORY_WAIT"); return; end
 if not SyncGovernor(id,p,state,true) then ClickFeedback("LOC_LOTM_JUSTICE_STORY_WAIT"); return; end
 if state.Established~=1 or state.Neutralized~=0
  or state["GOVERNOR_PROMOTION_LOTM_JUSTICE_STORY"]~=1 then
  ClickFeedback("LOC_LOTM_JUSTICE_STORY_INACTIVE"); return;
 end
 local cityID=tonumber(p:GetProperty("JUSTICE_STORY_CITY_ID") or -1);
 local city=p:GetCities():FindID(cityID);
 if city==nil or state.CityID~=cityID then ClickFeedback("LOC_LOTM_JUSTICE_STORY_INACTIVE"); return; end
 local queue=city:GetBuildQueue();
 local kind,rawID=EntryKind(queue:GetAt(0));
 -- Native queue entries may identify rows by type name, hash or index.
 -- Resolve through GameInfo as Firaxis ProductionHelper does; send canonical IDs.
 local target=nil;
 if kind=="BUILDING" then target=GameInfo.Buildings[rawID];
 elseif kind=="PROJECT" then target=GameInfo.Projects[rawID]; end
 if target==nil then ClickFeedback("LOC_LOTM_JUSTICE_STORY_SELECT"); return; end
 ClickFeedback("LOC_LOTM_JUSTICE_STORY_SUBMIT");
 UILog("submit","complete submitted city="..cityID.." kind="..kind
  .." rawID="..tostring(rawID).." index="..target.Index.." hash="..target.Hash);
 local ok,accepted=pcall(UI.RequestPlayerOperation,id,PlayerOperations.EXECUTE_SCRIPT,{
  OnStart="LOTM_JUSTICE_CompleteStory",TargetHash=target.Hash,
  TargetKind=kind,TargetID=target.Index,CityID=cityID
 });
 if not ok or accepted==false then ClickFeedback("LOC_LOTM_JUSTICE_STORY_WAIT"); end
end

-- Base InGame.Initialize loads every AddUserInterfaces context with isHidden=true.
-- Showing StoryPanel alone cannot reveal a child of that hidden context.
-- Keep the context available; Refresh controls the child for the one-turn window.
ContextPtr:SetHide(false);
Controls.CompleteButton:RegisterCallback(Mouse.eLClick,Complete);
Events.PlayerTurnActivated.Add(function() Refresh(true); end);
Events.CityProductionQueueChanged.Add(function() Refresh(false); end);
Events.GovernorChanged.Add(function() Refresh(true); end);
Events.GovernorAssigned.Add(function() Refresh(true); end);
Events.GovernorPromoted.Add(function() Refresh(true); end);
if Events.GovernorEstablished~=nil then
 Events.GovernorEstablished.Add(function() Refresh(true); end);
end
Events.GameCoreEventPublishComplete.Add(function() Refresh(false); end);
if Events.LoadGameViewStateDone~=nil then
 Events.LoadGameViewStateDone.Add(function() Refresh(true); end);
end
if Events.LoadScreenClose~=nil then
 Events.LoadScreenClose.Add(function() Refresh(true); end);
end
Refresh(true);
-- BEGIN RC342 STARTUP TRACE

end
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("LOTM_JUSTICE_Story","CONTEXT END");
-- END RC342 STARTUP TRACE
