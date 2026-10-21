-- AUTO-GENERATED rc.241 standalone network context: LOTM_RESCUE_Phase1; do not edit.
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
LOTM_StartupTrace.Mark("MP.LOTM_RESCUE_Phase1","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"MP.LOTM_RESCUE_Phase1","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"MP.LOTM_RESCUE_Phase1","GameEvents");
-- END RC342 STARTUP TRACE

local m_mp241Network = GameConfiguration ~= nil
	and GameConfiguration.IsAnyMultiplayer ~= nil
	and GameConfiguration.IsAnyMultiplayer();
if m_mp241Network then
	print("[LOTM][MP241] standalone context=LOTM_RESCUE_Phase1");
-- Rescue Mode Phase 1: synchronized, deterministic reservation geometry only.
-- This file deliberately creates no players, cities, units, improvements, or terrain changes.

local VERSION = 4;
local VISIBILITY_VERSION = 2;
local STATE_KEY = "LOTM_RESCUE_PHASE1_STATE";
local ZONES = { "CENTER", "FOOL", "NIGHT", "STORM" };
local CONFIGURATIONS = {
	{ Radius=5, Directions={0,2,4}, Name="0/2/4" },
	{ Radius=5, Directions={1,3,5}, Name="1/3/5" },
	{ Radius=6, Directions={0,2,4}, Name="0/2/4" },
	{ Radius=6, Directions={1,3,5}, Name="1/3/5" }
};
local Fail;

local function IsNaturalWonder(plot)
	return plot~=nil and plot.IsNaturalWonder~=nil and plot:IsNaturalWonder();
end

local function IsOpenLand(plot)
	return plot~=nil and not plot:IsWater() and not plot:IsImpassable() and not plot:IsMountain() and not IsNaturalWonder(plot);
end

local function IsLegalCenter(plot)
	return IsOpenLand(plot) and plot:GetOwner()==-1 and plot:GetDistrictType()<0 and plot:GetImprovementType()<0;
end

local function IsUnoccupiedReservationPlot(plot)
	return plot~=nil and plot:GetOwner()==-1 and plot:GetDistrictType()<0;
end

local function Disk(plot,radius)
	local result={}; local seen={};
	for dx=-radius,radius do
		for dy=-radius,radius do
			local other=Map.GetPlotXYWithRangeCheck(plot:GetX(),plot:GetY(),dx,dy,radius);
			if other~=nil and not seen[other:GetIndex()] then
				seen[other:GetIndex()]=true; result[#result+1]=other;
			end
		end
	end
	table.sort(result,function(a,b) return a:GetIndex()<b:GetIndex(); end);
	return result;
end

local function Step(plot,direction,distance)
	local current=plot;
	for _=1,distance do
		if current==nil then return nil; end
		current=Map.GetAdjacentPlot(current:GetX(),current:GetY(),direction);
	end
	return current;
end

local function HasLegalCenterRing(plot)
	if not IsLegalCenter(plot) then return false; end
	for direction=0,5 do
		if not IsOpenLand(Map.GetAdjacentPlot(plot:GetX(),plot:GetY(),direction)) then return false; end
	end
	return true;
end

local function LandScore(plot)
	local allowed={}; for _,other in ipairs(Disk(plot,4)) do if IsOpenLand(other) then allowed[other:GetIndex()]=other; end end
	local visited={[plot:GetIndex()]=true}; local queue={plot}; local score=0; local cursor=1;
	while cursor<=#queue do
		local current=queue[cursor]; cursor=cursor+1; score=score+1;
		for direction=0,5 do
			local adjacent=Map.GetAdjacentPlot(current:GetX(),current:GetY(),direction);
			if adjacent~=nil and allowed[adjacent:GetIndex()]~=nil and not visited[adjacent:GetIndex()] then
				visited[adjacent:GetIndex()]=true; queue[#queue+1]=adjacent;
			end
		end
	end
	return score;
end

local function MajorStarts()
	local starts={};
	for playerID=0,GameDefines.MAX_PLAYERS-1 do
		local player=Players[playerID]; local config=PlayerConfigurations[playerID];
		if player~=nil and config~=nil and player:IsAlive() and player:IsMajor() then
			local location=config:GetStartingPosition();
			if location~=nil and location.x~=nil and location.y~=nil then
				local plot=Map.GetPlot(location.x,location.y); if plot~=nil then starts[#starts+1]=plot; end
			end
		end
	end
	table.sort(starts,function(a,b) return a:GetIndex()<b:GetIndex(); end);
	return starts;
end

local function ClaimReservations(territories)
	local playerID=PlayerManager.GetFreeCitiesPlayerID();
	local player=playerID~=nil and playerID>=0 and Players[playerID] or nil;
	if player==nil or not player:IsAlive() or player:IsMajor() or player:IsBarbarian() then
		return nil,"FREE_CITIES_OWNER_UNAVAILABLE";
	end
	local claimed=0;
	for _,territory in ipairs(territories) do
		for _,plot in ipairs(territory) do
			if plot:GetOwner()~=playerID then plot:SetOwner(playerID); end
			if plot:GetOwner()~=playerID then return nil,"CLAIM_FAILED_"..plot:GetIndex(); end
			claimed=claimed+1;
		end
	end
	if claimed~=76 then return nil,"CLAIM_COUNT_"..claimed; end
	return playerID,nil;
end

local function StartDistance(plot,starts)
	local minimum=9999;
	for _,startPlot in ipairs(starts) do minimum=math.min(minimum,Map.GetPlotDistance(plot:GetIndex(),startPlot:GetIndex())); end
	return minimum;
end

local function BuildReservation(center,configuration)
	local centers={center};
	for _,direction in ipairs(configuration.Directions) do
		local plot=Step(center,direction,configuration.Radius);
		if not IsLegalCenter(plot) then return nil; end
		centers[#centers+1]=plot;
	end
	local territories={}; local occupied={};
	for zoneIndex,zoneCenter in ipairs(centers) do
		local plots=Disk(zoneCenter,2); if #plots~=19 then return nil; end
		for _,plot in ipairs(plots) do
			-- Phase 1 runs after the engine has placed majors and ordinary city
			-- states.  Reject the entire geometry if any of its 76 plots is
			-- already owned or contains a city/district.  This preserves the
			-- requested CITY_STATE_COUNT without deleting or moving a minor.
			if not IsUnoccupiedReservationPlot(plot) then return nil; end
			local index=plot:GetIndex(); if occupied[index] then return nil; end
			occupied[index]=true;
		end
		territories[zoneIndex]=plots;
	end
	return centers,territories;
end

local function CSV(plots)
	local values={}; for _,plot in ipairs(plots) do values[#values+1]=tostring(plot:GetIndex()); end
	return table.concat(values,",");
end

local function RevealReservationsForHumans()
	if Game.GetProperty(STATE_KEY)~="READY" then return; end
	local appliedVersion=tonumber(Game.GetProperty("LOTM_RESCUE_VISIBILITY_VERSION") or 0) or 0;
	if appliedVersion>=VISIBILITY_VERSION then return; end
	local plotIndices={}; local seen={};
	for _,zone in ipairs(ZONES) do
		local csv=tostring(Game.GetProperty("LOTM_RESCUE_"..zone.."_TERRITORY") or "");
		for value in string.gmatch(csv,"[^,]+") do
			local index=tonumber(value);
			if index~=nil and Map.GetPlotByIndex(index)~=nil and not seen[index] then seen[index]=true; plotIndices[#plotIndices+1]=index; end
		end
	end
	table.sort(plotIndices);
	if #plotIndices~=76 then print("[LOTM_RESCUE][Phase1] WARNING reveal skipped territoryCount="..tostring(#plotIndices)); return; end
	local humanCount=0;
	for _,player in ipairs(PlayerManager.GetAliveMajors()) do
		if player:IsHuman() then
			local visibility=PlayersVisibility[player:GetID()];
			if visibility~=nil then
				-- A positive visibility source keeps the reservation live-visible like
				-- allied/shared sight.  The version property makes this a one-time,
				-- save-persistent grant instead of stacking another source on reload.
				for _,plotIndex in ipairs(plotIndices) do visibility:ChangeVisibilityCount(plotIndex,1); end
				humanCount=humanCount+1;
			end
		end
	end
	Game.SetProperty("LOTM_RESCUE_VISIBILITY_VERSION",VISIBILITY_VERSION);
	print("[LOTM_RESCUE][Phase1] persistent visibility plots=76 humanPlayers="..humanCount.." visibilityVersion="..VISIBILITY_VERSION);
end

local function Store(centers,territories,configuration,minDistance,fallback)
	local reservationOwner,claimFailure=ClaimReservations(territories);
	if reservationOwner==nil then Fail(claimFailure); return false; end
	Game.SetProperty("LOTM_RESCUE_MODE",1);
	Game.SetProperty("LOTM_RESCUE_PHASE",1);
	Game.SetProperty("LOTM_RESCUE_PHASE1_VERSION",VERSION);
	Game.SetProperty("LOTM_RESCUE_SEAL_RADIUS",configuration.Radius);
	Game.SetProperty("LOTM_RESCUE_DIRECTION_GROUP",configuration.Name);
	Game.SetProperty("LOTM_RESCUE_START_MIN_DISTANCE",minDistance);
	Game.SetProperty("LOTM_RESCUE_FALLBACK_REASON",fallback);
	Game.SetProperty("LOTM_RESCUE_RESERVATION_OWNER",reservationOwner);
	for i,zone in ipairs(ZONES) do
		Game.SetProperty("LOTM_RESCUE_"..zone.."_PLOT",centers[i]:GetIndex());
		Game.SetProperty("LOTM_RESCUE_"..zone.."_TERRITORY",CSV(territories[i]));
		for _,plot in ipairs(territories[i]) do
			plot:SetProperty("LOTM_RESCUE_ZONE_KIND",zone);
			plot:SetProperty("LOTM_RESCUE_ZONE_CENTER",centers[i]:GetIndex());
		end
	end
	Game.SetProperty(STATE_KEY,"READY");
	RevealReservationsForHumans();
	print("[LOTM_RESCUE][Phase1] READY center="..centers[1]:GetIndex().." radius="..configuration.Radius.." directions="..configuration.Name.." startDistance="..minDistance.." fallback="..fallback.." reservationOwner="..reservationOwner.." claimedPlots=76");
	return true;
end

Fail=function(reason)
	Game.SetProperty("LOTM_RESCUE_MODE",1); Game.SetProperty("LOTM_RESCUE_PHASE",1);
	Game.SetProperty("LOTM_RESCUE_PHASE1_VERSION",VERSION); Game.SetProperty("LOTM_RESCUE_FALLBACK_REASON",reason);
	Game.SetProperty(STATE_KEY,"FAILED");
	print("[LOTM_RESCUE][Phase1] FAILED reason="..reason);
end

local function Initialize()
	local state=Game.GetProperty(STATE_KEY);
	local storedVersion=tonumber(Game.GetProperty("LOTM_RESCUE_PHASE1_VERSION") or 0) or 0;
	if state=="READY" then
		RevealReservationsForHumans();
		print("[LOTM_RESCUE][Phase1] reload state=READY; coordinates unchanged"); return;
	end
	if state=="FAILED" and storedVersion>=VERSION then
		print("[LOTM_RESCUE][Phase1] reload state=FAILED version="..storedVersion.."; failure unchanged"); return;
	end
	if state=="FAILED" then
		print("[LOTM_RESCUE][Phase1] retrying older failed state oldVersion="..storedVersion.." newVersion="..VERSION);
	end
	local width,height=Map.GetGridSize(); local geometric=Map.GetPlot(math.floor((width-1)/2),math.floor((height-1)/2));
	if geometric==nil then Fail("NO_GEOMETRIC_CENTER"); return; end
	-- The hard distance threshold protects major-civilization starts only.
	-- Minor starts are already settled by the time this Gameplay add-in runs;
	-- BuildReservation rejects every owned/district plot in their live territory.
	-- Including every minor StartingPosition here made dense maps have zero
	-- candidates even when a fully unowned 76-plot reservation existed.
	local starts=MajorStarts(); local candidates={};
	for index=0,Map.GetPlotCount()-1 do
		local plot=Map.GetPlotByIndex(index);
		if HasLegalCenterRing(plot) then
			local distance=StartDistance(plot,starts);
			if distance>=10 then candidates[#candidates+1]={Plot=plot,CenterDistance=Map.GetPlotDistance(plot:GetIndex(),geometric:GetIndex()),Land=LandScore(plot),StartDistance=distance}; end
		end
	end
	table.sort(candidates,function(a,b)
		if a.StartDistance>=12 and b.StartDistance<12 then return true; end
		if a.StartDistance<12 and b.StartDistance>=12 then return false; end
		if a.CenterDistance~=b.CenterDistance then return a.CenterDistance<b.CenterDistance; end
		if a.Land~=b.Land then return a.Land>b.Land; end
		return a.Plot:GetIndex()<b.Plot:GetIndex();
	end);
	for _,candidate in ipairs(candidates) do
		for configIndex,configuration in ipairs(CONFIGURATIONS) do
			local centers,territories=BuildReservation(candidate.Plot,configuration);
			if centers~=nil then
				local reasons={};
				if candidate.StartDistance<12 then reasons[#reasons+1]="START_DISTANCE_"..candidate.StartDistance; end
				if configIndex>1 then reasons[#reasons+1]="GEOMETRY_"..configuration.Radius.."_"..string.gsub(configuration.Name,"/","-"); end
				if Store(centers,territories,configuration,candidate.StartDistance,#reasons==0 and "NONE" or table.concat(reasons,";")) then return; end
				return;
			end
		end
	end
	Fail("NO_NATURAL_LAYOUT_AT_HARD_MINIMUM_10");
end

Initialize();
end
