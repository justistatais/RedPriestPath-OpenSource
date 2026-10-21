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
LOTM_StartupTrace.Mark("LOTM_MS_Governors","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"LOTM_MS_Governors","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"LOTM_MS_Governors","GameEvents");
local LuaEvents = LOTM_StartupTrace.Events(LuaEvents,"LOTM_MS_Governors","LuaEvents");
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
do
-- END RC342 STARTUP TRACE
-- Read native governors in the local UI. The synchronized operation owns all
-- Gameplay property writes; this context never awards yields or visibility.
local DEFINITIONS={
 MAGICIAN={
  Governor="GOVERNOR_LOTM_MAGICIAN",
  Promotions={
   "GOVERNOR_PROMOTION_LOTM_MAGICIAN_GATE",
   "GOVERNOR_PROMOTION_LOTM_MAGICIAN_SERIAL",
   "GOVERNOR_PROMOTION_LOTM_MAGICIAN_SUPPLY",
   "GOVERNOR_PROMOTION_LOTM_MAGICIAN_RECORD",
   "GOVERNOR_PROMOTION_LOTM_MAGICIAN_REPLAY",
   "GOVERNOR_PROMOTION_LOTM_MAGICIAN_BESTSELLER"}},
 STAR={
  Governor="GOVERNOR_LOTM_STAR",
  Promotions={
   "GOVERNOR_PROMOTION_LOTM_STAR_WATCHER",
   "GOVERNOR_PROMOTION_LOTM_STAR_PATROL",
   "GOVERNOR_PROMOTION_LOTM_STAR_INVESTIGATION",
   "GOVERNOR_PROMOTION_LOTM_STAR_CONTACT",
   "GOVERNOR_PROMOTION_LOTM_STAR_INTERROGATION",
   "GOVERNOR_PROMOTION_LOTM_STAR_GUARDIAN"}}
};
local function Rescue()
 local configured=GameConfiguration~=nil and GameConfiguration.GetValue~=nil
  and GameConfiguration.GetValue("GAMEMODE_LOTM_RESCUE") or nil;
 if configured==true or tonumber(configured or 0)==1 then return true; end
 local raw=Game.GetProperty~=nil and Game.GetProperty("LOTM_RESCUE_MODE") or nil;
 return tonumber(raw or 0)==1;
end
if Rescue() then
 DEFINITIONS.STAR.Promotions={
  "GOVERNOR_PROMOTION_LOTM_STAR_WATCHER","GOVERNOR_PROMOTION_LOTM_STAR_PATROL",
  "GOVERNOR_PROMOTION_LOTM_STAR_INVESTIGATION","GOVERNOR_PROMOTION_LOTM_STAR_CASE_FILES",
  "GOVERNOR_PROMOTION_LOTM_STAR_RED_GLOVES","GOVERNOR_PROMOTION_LOTM_STAR_HIDDEN_WORLD"};
end
local lastSnapshot=nil;
local serial=nil;
local retryTurn=-1;
local attempts=0;
local polls=0;
local auditedDigest=nil;
local function AuditVisibility(player,state,digest)
 if Rescue() then return; end
 if auditedDigest==digest then return;end
 auditedDigest=digest;
 if PlayerManager==nil or PlayerManager.GetAliveMajors==nil then return;end
 local diplomacy=player:GetDiplomacy();
 local source=GameInfo.DiplomaticVisibilitySources["SOURCE_GREAT_PERSON_JOURNALISM"];
 for _,other in ipairs(PlayerManager.GetAliveMajors()) do
  local target=other:GetID();
  if target~=player:GetID() and diplomacy:HasMet(target) then
   local ok,level,active=pcall(function()
    return diplomacy:GetVisibilityOn(target),source~=nil and diplomacy:IsVisibilitySourceActive(target,source.Index);
   end);
   print("[LOTM_MS][UI] visibility audit target="..target.." nativeOwned="..state.GOVERNOR_PROMOTION_LOTM_STAR_CONTACT
    .." established="..state.STAR_Established.." neutralized="..state.STAR_Neutralized
    .." readable="..tostring(ok).." level="..tostring(level).." sourceActive="..tostring(active));
  end
 end
end

local function Snapshot()
 local playerID=Game.GetLocalPlayer();
 if playerID==nil or playerID<0 then return nil,nil; end
 local player=Players[playerID]; if player==nil then return nil,nil; end
 local result={OnStart="LOTM_MS_UpdateGovernor"};
 local count,list=player:GetGovernors():GetGovernorList();
 if list==nil and (tonumber(count) or 0)>0 then return nil,nil; end
 for key,definition in pairs(DEFINITIONS) do
  local row=GameInfo.Governors[definition.Governor];
  if row==nil then return nil,nil; end
  result[key.."_CityID"]=-1;
  result[key.."_Established"]=0;
  result[key.."_Neutralized"]=0;
  for _,promotion in ipairs(definition.Promotions) do result[promotion]=0; end
  for _,governor in ipairs(list or {}) do
   if governor:GetType()==row.Index then
    local city=governor:GetAssignedCity();
    if city~=nil and city:GetOwner()==playerID then result[key.."_CityID"]=city:GetID(); end
    if governor:IsEstablished() then result[key.."_Established"]=1; end
    if (governor:GetNeutralizedTurns() or 0)>0 then result[key.."_Neutralized"]=1; end
    for _,promotion in ipairs(definition.Promotions) do
     local promotionRow=GameInfo.GovernorPromotions[promotion];
     if promotionRow~=nil and governor:HasPromotion(promotionRow.Hash) then
      result[promotion]=1;
     end
    end
    break;
   end
  end
 end
 return playerID,result;
end
local function Refresh()
 local playerID,state=Snapshot(); if state==nil then return; end
 local fields={};
 for key,value in pairs(state) do fields[#fields+1]=key.."="..tostring(value); end
 table.sort(fields);
 local digest=table.concat(fields,";");
 local player=Players[playerID];
 if serial==nil then serial=(tonumber(player:GetProperty("LOTM_MS_SNAPSHOT_SERIAL") or 0) or 0)+1; end
 if player:GetProperty("LOTM_MS_SNAPSHOT_DIGEST")==digest
  and (tonumber(player:GetProperty("LOTM_MS_SNAPSHOT_SERIAL") or 0) or 0)>=serial then
  AuditVisibility(player,state,digest);return;
 end
 local turn=Game.GetCurrentGameTurn();
 if lastSnapshot~=digest or retryTurn~=turn then attempts=0;polls=0;retryTurn=turn;lastSnapshot=digest;end
 if not player:IsTurnActive() or attempts>=12 then return; end
 polls=polls+1;
 if attempts>0 and polls<20 then return; end
 attempts=attempts+1;polls=0;
 state.SnapshotDigest=digest;state.SnapshotSerial=serial;
 local ok,result=pcall(UI.RequestPlayerOperation,playerID,PlayerOperations.EXECUTE_SCRIPT,state);
 print("[LOTM_MS][UI] snapshot submit serial="..serial.." attempt="..attempts.." accepted="..tostring(ok and result~=false));
end

local pendingCases={};
local function SubmitCases()
 local id=Game.GetLocalPlayer();local player=Players[id];
 if player==nil or not player:IsTurnActive() then return;end
 local keys={};for key in pairs(pendingCases) do keys[#keys+1]=key;end;table.sort(keys);
 for _,key in ipairs(keys) do
  local entry=pendingCases[key];local data=entry.data;
  if player:GetProperty(key)==1 or Game.GetCurrentGameTurn()-data.CompletionTurn>1 then
   pendingCases[key]=nil;
  else
   entry.polls=entry.polls+1;
   if entry.turn~=Game.GetCurrentGameTurn() then entry.attempts=0;entry.turn=Game.GetCurrentGameTurn();end
   if entry.attempts<12 and (entry.attempts==0 or entry.polls>=20) then
    entry.attempts=entry.attempts+1;entry.polls=0;
    UI.RequestPlayerOperation(id,PlayerOperations.EXECUTE_SCRIPT,data);
   end
  end
 end
end
local function OnSpyMissionCompleted(attacker,missionID)
 if Rescue() then return; end
 local id,state=Snapshot();
 if state==nil or attacker==id or state.STAR_Established~=1 or state.STAR_Neutralized~=0
  or state.GOVERNOR_PROMOTION_LOTM_STAR_INTERROGATION~=1 then return;end
 local other=Players[attacker];if other==nil then return;end
 local ok,mission=pcall(function() return other:GetDiplomacy():GetMission(attacker,missionID);end);
 if not ok or type(mission)~="table" then return;end
 if mission.InitialResult~=EspionageResultTypes.CAPTURED
  and mission.EscapeResult~=EspionageResultTypes.CAPTURED then return;end
 local plot=Map.GetPlotByIndex(mission.PlotIndex);
 local city=plot~=nil and Cities.GetPlotPurchaseCity(plot) or nil;
 if city==nil or city:GetOwner()~=id or city:GetID()~=state.STAR_CityID then return;end
 local key="LOTM_MS_INTERROGATION_CASE_"..attacker.."_"..missionID;
 if Players[id]:GetProperty(key)==1 or pendingCases[key]~=nil then return;end
 pendingCases[key]={attempts=0,polls=0,turn=-1,data={OnStart="LOTM_MS_Interrogation",
  AttackerID=attacker,MissionID=missionID,CompletionTurn=mission.CompletionTurn,
  PlotIndex=mission.PlotIndex,CityID=city:GetID(),Captured=1}};
 Refresh();SubmitCases();
end
Events.SpyMissionCompleted.Add(OnSpyMissionCompleted);
Events.PlayerTurnActivated.Add(SubmitCases);
Events.GameCoreEventPublishComplete.Add(SubmitCases);

Events.PlayerTurnActivated.Add(Refresh);
Events.GovernorChanged.Add(Refresh);
Events.GovernorAssigned.Add(Refresh);
Events.GovernorPromoted.Add(Refresh);
if Events.GovernorEstablished~=nil then Events.GovernorEstablished.Add(Refresh); end
Events.GameCoreEventPublishComplete.Add(Refresh);
-- Initial loading can accept EXECUTE_SCRIPT without executing it. Do not let
-- those early attempts exhaust the budget for the first playable turn.
local function OnViewReady()
 attempts=0;polls=0;retryTurn=-1;
 Refresh();
end
Events.LoadGameViewStateDone.Add(OnViewReady);
if Events.LoadScreenClose~=nil then Events.LoadScreenClose.Add(OnViewReady);end

-- Rescue C4: publish-only callbacks observe the end of a native movement.
-- Requests carry the synchronous OnUnitMoved receipt; Gameplay rechecks it.
if Rescue() then
 local prefix="LOTM_RESCUE_STAR_";
 local stops={}; local life={}; local lifeSerial=0;
 local function PNum(o,k,d)
  local raw=o~=nil and o:GetProperty(k) or nil; return tonumber(raw) or d;
 end
 local function LocalPlayer()
  local id=Game.GetLocalPlayer(); return id,Players[id];
 end
 local function CompleteMovement(owner,unitID,x,y)
  local id,p=LocalPlayer(); if p==nil or owner~=id then return; end
  local _,native=Snapshot();
  if native==nil or native.STAR_Established~=1 or native.STAR_Neutralized~=0
   or native.GOVERNOR_PROMOTION_LOTM_STAR_RED_GLOVES~=1 then return; end
  local u=UnitManager.GetUnit(owner,unitID); if u==nil then return; end
  local plot=Map.GetPlot(u:GetX(),u:GetY()); if plot==nil then return; end
  stops[unitID]={PlotIndex=plot:GetIndex(),Turn=Game.GetCurrentGameTurn(),Polls=20,Attempts=0};
 end
 local function Lifecycle(owner,unitID)
  if tonumber(owner)==nil or tonumber(unitID)==nil then return; end
  local id,p=LocalPlayer(); if p==nil then return; end
  lifeSerial=lifeSerial+1; local key=owner..":"..unitID;
  life[key]={OwnerID=owner,UnitID=unitID,Token=Game.GetCurrentGameTurn()..":"..lifeSerial,Polls=20,Attempts=0};
 end
 local function Pump()
  local id,p=LocalPlayer(); if p==nil or not p:IsTurnActive() then return; end
  local now=Game.GetCurrentGameTurn();
  local keys={}; for k in pairs(stops) do keys[#keys+1]=k; end; table.sort(keys);
  for _,unitID in ipairs(keys) do
   local e=stops[unitID]; local u=UnitManager.GetUnit(id,unitID);
   local plot=u~=nil and Map.GetPlot(u:GetX(),u:GetY()) or nil;
   if u==nil or e.Turn~=now or plot==nil or plot:GetIndex()~=e.PlotIndex then stops[unitID]=nil;
   else
    local identity=PNum(u,prefix.."IDENTITY",0); local move=PNum(u,prefix.."MOVE_SERIAL",0);
    if p:GetProperty(prefix.."MOVE_ACK_"..unitID)==identity..":"..move then stops[unitID]=nil;
    else
     e.Polls=e.Polls+1;
     if identity>0 and move>0 and e.Attempts<12 and e.Polls>=20 then
      e.Polls=0;e.Attempts=e.Attempts+1;
      Refresh();
      UI.RequestPlayerOperation(id,PlayerOperations.EXECUTE_SCRIPT,{OnStart="LOTM_RESCUE_StarMoveComplete",
       UnitID=unitID,Identity=identity,MoveSerial=move,PlotIndex=e.PlotIndex,Turn=e.Turn});
     end
    end
   end
  end
  keys={}; for k in pairs(life) do keys[#keys+1]=k; end; table.sort(keys);
  for _,key in ipairs(keys) do
   local e=life[key];
   if e.RetryTurn~=now then e.RetryTurn=now;e.Attempts=0;e.Polls=20;end
   if p:GetProperty(prefix.."LIFE_ACK_"..key)==e.Token then life[key]=nil;
   else
    e.Polls=e.Polls+1;
    if e.Attempts<12 and e.Polls>=20 then
     e.Polls=0;e.Attempts=e.Attempts+1;
     UI.RequestPlayerOperation(id,PlayerOperations.EXECUTE_SCRIPT,{OnStart="LOTM_RESCUE_StarUnitLifecycle",
      OwnerID=e.OwnerID,UnitID=e.UnitID,Token=e.Token});
    end
   end
  end
 end
 Events.UnitMoveComplete.Add(CompleteMovement);
 Events.UnitAddedToMap.Add(Lifecycle);
 Events.UnitRemovedFromMap.Add(Lifecycle);
 if Events.UnitUpgraded~=nil then Events.UnitUpgraded.Add(Lifecycle); end
 Events.GameCoreEventPublishComplete.Add(Pump);
 Events.PlayerTurnActivated.Add(Pump);
end
Refresh();
-- BEGIN RC342 STARTUP TRACE

end
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("LOTM_MS_Governors","CONTEXT END");
-- END RC342 STARTUP TRACE
