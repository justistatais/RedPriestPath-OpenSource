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
LOTM_StartupTrace.Mark("LOTM_RESCUE_RuntimeEvents","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"LOTM_RESCUE_RuntimeEvents","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"LOTM_RESCUE_RuntimeEvents","GameEvents");
local LuaEvents = LOTM_StartupTrace.Events(LuaEvents,"LOTM_RESCUE_RuntimeEvents","LuaEvents");
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
do
-- END RC342 STARTUP TRACE
-- Read-only event batching. No local publication changes Gameplay state.
local units={}; local camps={}; local potions={}; local rejected={}; local rejectedTurn=nil; local flushing=false;
local lastDeferred=nil;
-- READY is saved with the game. A reloaded UI must wait for this session's
-- synchronized main-loader acknowledgement before submitting to its handlers.
local initialMainSerial=tonumber(Game.GetProperty("LOTM_MP241_MAIN_LOAD_SERIAL") or 0) or 0;
local function GameplayReady()
 if tonumber(Game.GetProperty("LOTM_RESCUE_RUNTIME_EVENTS_READY") or 0)~=1 then return false; end
 if GameConfiguration~=nil and GameConfiguration.IsAnyMultiplayer~=nil and GameConfiguration.IsAnyMultiplayer() then
  return (tonumber(Game.GetProperty("LOTM_MP241_MAIN_LOAD_SERIAL") or 0) or 0)>initialMainSerial
   and Game.GetProperty("LOTM_MP241_MAIN_LOAD_STATE")=="LOADED";
 end
 return true;
end
local function Log(s) print("[LOTM_RESCUE][RuntimeEventsUI] "..s); end
local function Active() return tonumber(Game.GetProperty("LOTM_RESCUE_MODE") or 0)==1; end
local function Sender()
 local id=Game.GetLocalPlayer(); if id==nil or id<0 then return nil; end
 local chosen=nil;
 for _,player in ipairs(PlayerManager.GetAliveMajors() or {}) do
  if player:IsHuman() and player:IsTurnActive() then
   if chosen==nil or player:GetID()<chosen then chosen=player:GetID(); end
  end
 end
 if chosen==id then return id; end
 return nil;
end
local function Send(id,parameters)
 local key=parameters.OnStart..":"..tostring(parameters.Units or parameters.PlotIndex or parameters.TargetPlayerID)..":"..tostring(parameters.CampEpoch or "");
 local turn=Game.GetCurrentGameTurn();
 if rejectedTurn~=turn then rejected={}; rejectedTurn=turn; end
 if rejected[key]==turn then return false; end
 local ok,result=pcall(UI.RequestPlayerOperation,id,PlayerOperations.EXECUTE_SCRIPT,parameters);
 local accepted=ok and result~=false;
 if accepted then rejected[key]=nil; else rejected[key]=turn; end
 Log("submit command="..parameters.OnStart.." player="..id.." turn="..turn
  .." plot="..tostring(parameters.PlotIndex or "-").." accepted="..tostring(accepted));
 return accepted;
end
local function Flush()
 if flushing or (next(units)==nil and next(camps)==nil and next(potions)==nil) then return; end
 if not Active() then return; end
 local ready=GameplayReady();
 local id=ready and Sender() or nil;
 if id==nil then
  local reason=ready and "NO_ACTIVE_SENDER" or "GAMEPLAY_NOT_READY";
  if lastDeferred~=reason then Log("deferred reason="..reason); lastDeferred=reason; end
  return;
 end
 lastDeferred=nil; flushing=true;
 local keys={}; for key in pairs(units) do keys[#keys+1]=key; end; table.sort(keys);
 local batch={};
 for _,key in ipairs(keys) do
  batch[#batch+1]=key;
  if #batch==64 then
   if Send(id,{OnStart="LOTM_RESCUE_Command_NativeCleanup",Units=table.concat(batch,",")}) then
    for _,sent in ipairs(batch) do units[sent]=nil; end
   end
   batch={};
  end
 end
 if #batch>0 and Send(id,{OnStart="LOTM_RESCUE_Command_NativeCleanup",Units=table.concat(batch,",")}) then
  for _,sent in ipairs(batch) do units[sent]=nil; end
 end
 local plots={}; for plotIndex in pairs(camps) do plots[#plots+1]=plotIndex; end; table.sort(plots);
 for _,plotIndex in ipairs(plots) do
  local plot=Map.GetPlotByIndex(plotIndex);
  if plot==nil or tonumber(plot:GetProperty("LOTM_PP_WORKSHOP_REWARD_SETTLED") or 0)==1 then camps[plotIndex]=nil;
  else
   local epoch=tonumber(plot:GetProperty("LOTM_PP_WORKSHOP_CAMP_EPOCH"));
   if epoch~=nil and Send(id,{OnStart="LOTM_RESCUE_Command_CampRemoved",PlotIndex=plotIndex,CampEpoch=epoch}) then camps[plotIndex]=nil; end
  end
 end
 local players={}; for playerID in pairs(potions) do players[#players+1]=playerID; end; table.sort(players);
 for _,playerID in ipairs(players) do
  if Send(id,{OnStart="LOTM_RESCUE_Command_PotionCompleted",TargetPlayerID=playerID}) then potions[playerID]=nil; end
 end
 flushing=false;
end
local function OnUnitAdded(owner,id)
 if not Active() or tonumber(owner)==nil or tonumber(id)==nil then return; end
 units[tostring(owner)..":"..tostring(id)]=true;
end
local function OnCampRemoved(x,y)
 if not Active() then return; end
 local plot=Map.GetPlot(x,y);
 if plot~=nil and tonumber(plot:GetProperty("LOTM_PP_WORKSHOP_CLASSIFIED") or 0)==1 then
  camps[plot:GetIndex()]=true;
  Log("camp observed plot="..plot:GetIndex().." turn="..Game.GetCurrentGameTurn());
 end
end
local function OnProjectCompleted(playerID,cityID,projectID)
 if not Active() then return; end
 local row=GameInfo.Projects[projectID];
 if row~=nil and GameInfo.LOTM_RESCUE_PotionCompletions~=nil
  and GameInfo.LOTM_RESCUE_PotionCompletions[row.ProjectType]~=nil then potions[playerID]=true; end
end
local function OnLoaded()
 if Active() then
  for _,player in ipairs(PlayerManager.GetAliveMajors() or {}) do
   if player:IsHuman() then potions[player:GetID()]=true; end
  end
 end
 Flush();
end
-- This context has no visual controls. RequestRefresh is not a reliable
-- dispatcher for it. Submit after the native publication batch has finished,
-- using the same boundary as the working city bootstrap UI. Never mutate
-- Gameplay inside UnitAdded/ImprovementRemoved or depend on a rendered frame.
Events.UnitAddedToMap.Add(OnUnitAdded);
Events.ImprovementRemovedFromMap.Add(OnCampRemoved);
Events.CityProjectCompleted.Add(OnProjectCompleted);
Events.GameCoreEventPublishComplete.Add(Flush);
Events.PlayerTurnActivated.Add(Flush);
Events.LoadGameViewStateDone.Add(OnLoaded);
print("[LOTM_RESCUE][RuntimeEventsUI] loaded version=5 dispatch=publishComplete potionReceipt=projectCompletionProperty mainSerial="..initialMainSerial);
-- BEGIN RC342 STARTUP TRACE

end
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("LOTM_RESCUE_RuntimeEvents","CONTEXT END");
-- END RC342 STARTUP TRACE
