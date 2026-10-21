-- Gameplay-safe deterministic movement helpers.  Scripted crisis actors retain
-- deterministic placement movement, while church guardians use the engine's
-- native MOVE_TO operation so terrain, roads, zones of control and movement
-- points are resolved by Civilization VI itself.
LOTM_RESCUE_SyncActions=LOTM_RESCUE_SyncActions or {};
local VERSION=9;
local REDEPLOY_RADIUS=12;
print("[LOTM_RESCUE][SyncActions] loaded version="..VERSION.." placeUnit="..tostring(UnitManager~=nil and UnitManager.PlaceUnit~=nil).." kill="..tostring(UnitManager~=nil and UnitManager.Kill~=nil).." genericRedeployRadius="..REDEPLOY_RADIUS.." monsterTargetDistance=5-12 cityTerritoryAllowed=true");

local function Open(plot,requireUnowned,allowedOwner)
	if plot==nil or plot:IsWater() or plot:IsImpassable() or plot:IsCity() then return false; end
	if plot:GetDistrictType()>=0 or plot:GetUnitCount()>0 then return false; end
	if requireUnowned and plot:GetOwner()>=0 then return false; end
	if allowedOwner~=nil and plot:GetOwner()>=0 then
		if type(allowedOwner)=="table" then
			if allowedOwner[plot:GetOwner()]~=true then return false; end
		elseif plot:GetOwner()~=allowedOwner then return false; end
	end
	return true;
end

local function RedeployCandidates(target,requireUnowned,allowedOwner)
	local result={};
	for dx=-REDEPLOY_RADIUS,REDEPLOY_RADIUS do for dy=-REDEPLOY_RADIUS,REDEPLOY_RADIUS do
		local plot=Map.GetPlotXYWithRangeCheck(target:GetX(),target:GetY(),dx,dy,REDEPLOY_RADIUS);
		if Open(plot,requireUnowned,allowedOwner) then
			local distance=Map.GetPlotDistance(plot:GetX(),plot:GetY(),target:GetX(),target:GetY());
			if distance>=1 then result[#result+1]={Plot=plot,Distance=distance}; end
		end
	end end
	table.sort(result,function(a,b)
		if a.Distance~=b.Distance then return a.Distance<b.Distance; end
		return a.Plot:GetIndex()<b.Plot:GetIndex();
	end);
	return result;
end

local function RedeployOpen(target,requireUnowned,allowedOwner)
	local result=RedeployCandidates(target,requireUnowned,allowedOwner);
	return #result>0 and result[1].Plot or nil,#result>0 and result[1].Distance or -1,result;
end

function LOTM_RESCUE_SyncActions.RedeployNearTarget(unit,target,minRadius,maxRadius,requireUnowned,allowedOwner)
	if unit==nil or target==nil or UnitManager.PlaceUnit==nil then return false,"API",-1,-1; end
	local minimum=math.max(1,math.floor(tonumber(minRadius) or 5));
	local radius=math.max(minimum,math.floor(tonumber(maxRadius) or REDEPLOY_RADIUS));
	local candidates={}; local seen={};
	for dx=-radius,radius do for dy=-radius,radius do
		local plot=Map.GetPlotXYWithRangeCheck(target:GetX(),target:GetY(),dx,dy,radius);
		if plot~=nil and not seen[plot:GetIndex()] and Open(plot,requireUnowned,allowedOwner) then
			seen[plot:GetIndex()]=true;
			local distance=Map.GetPlotDistance(plot:GetX(),plot:GetY(),target:GetX(),target:GetY());
			if distance>=minimum and distance<=radius then candidates[#candidates+1]={Plot=plot,Distance=distance}; end
		end
	end end
	-- The user-facing rule is at least five tiles from the target city. Prefer
	-- ring five, then expand one ring at a time up to twelve when occupied or
	-- illegal. Owned target territory is valid through allowedOwner.
	table.sort(candidates,function(a,b)
		if a.Distance~=b.Distance then return a.Distance<b.Distance; end
		return a.Plot:GetIndex()<b.Plot:GetIndex();
	end);
	for _,entry in ipairs(candidates) do
		local ok,result=pcall(UnitManager.PlaceUnit,unit,entry.Plot:GetX(),entry.Plot:GetY());
		local moved=ok and result~=false and unit:GetX()==entry.Plot:GetX() and unit:GetY()==entry.Plot:GetY();
		if moved then return true,"TARGET_REDEPLOY_RING_"..entry.Distance,entry.Plot:GetIndex(),entry.Distance; end
	end
	return false,#candidates>0 and "PLACE_FAILED" or "NO_REDEPLOY_PLOT",-1,-1;
end

function LOTM_RESCUE_SyncActions.MoveToward(unit,target,maxSteps,requireUnowned,allowRedeploy,allowedOwner,forceRedeployDistance,moveDiagnostic)
	local diagnostic=type(moveDiagnostic)=="table" and moveDiagnostic or nil;
	if diagnostic~=nil then diagnostic.Status="START"; diagnostic.CallOK=nil; diagnostic.RawResult=nil; diagnostic.RawResultType=""; end
	if unit==nil or target==nil or UnitManager.PlaceUnit==nil then if diagnostic~=nil then diagnostic.Status="API"; end return false,"API",-1; end
	local source=Map.GetPlot(unit:GetX(),unit:GetY()); if source==nil then if diagnostic~=nil then diagnostic.Status="SOURCE"; end return false,"SOURCE",-1; end
	local before=Map.GetPlotDistance(unit:GetX(),unit:GetY(),target:GetX(),target:GetY());
	if diagnostic~=nil then diagnostic.Before=before; diagnostic.Source=source:GetIndex(); diagnostic.Target=target:GetIndex(); end
	if before<=1 then if diagnostic~=nil then diagnostic.Status="ADJACENT"; diagnostic.Destination=source:GetIndex(); end return true,"ADJACENT",source:GetIndex(); end
	local candidates={}; local steps=math.max(1,tonumber(maxSteps) or 1);
	for dx=-steps,steps do for dy=-steps,steps do
		local plot=Map.GetPlotXYWithRangeCheck(unit:GetX(),unit:GetY(),dx,dy,steps);
		if Open(plot,requireUnowned,allowedOwner) then
			local distance=Map.GetPlotDistance(plot:GetX(),plot:GetY(),target:GetX(),target:GetY());
			if distance<before then candidates[#candidates+1]={Plot=plot,Distance=distance}; end
		end
	end end
	table.sort(candidates,function(a,b)
		if a.Distance~=b.Distance then return a.Distance<b.Distance; end
		return a.Plot:GetIndex()<b.Plot:GetIndex();
	end);
	if diagnostic~=nil then diagnostic.CandidateCount=#candidates; end
	local placementOptions=candidates; local destination=#candidates>0 and candidates[1].Plot or nil; local reason="STEP";
	local crossContinent=source:GetContinentType()~=target:GetContinentType();
	local forceRedeploy=allowRedeploy and tonumber(forceRedeployDistance)~=nil and before>tonumber(forceRedeployDistance);
	if diagnostic~=nil then diagnostic.CrossContinent=crossContinent; diagnostic.ForceRedeploy=forceRedeploy; end
	if allowRedeploy and (destination==nil or crossContinent or forceRedeploy) then
		local ring=-1; destination,ring,placementOptions=RedeployOpen(target,requireUnowned,allowedOwner);
		reason=destination~=nil and (forceRedeploy and "ASSAULT_REDEPLOY_RING_" or "REDEPLOY_RING_")..tostring(ring) or "NO_REDEPLOY_PLOT";
	end
	if destination==nil then if diagnostic~=nil then diagnostic.Status="NO_PLOT"; diagnostic.Selection=reason; end return false,"NO_PLOT",-1; end
	local destinationDistance=Map.GetPlotDistance(destination:GetX(),destination:GetY(),target:GetX(),target:GetY());
	if diagnostic~=nil then diagnostic.Selection=reason; diagnostic.Destination=destination:GetIndex(); diagnostic.DestinationDistance=destinationDistance; diagnostic.Attempts={}; end
	if diagnostic==nil then
		local ok,result=pcall(UnitManager.PlaceUnit,unit,destination:GetX(),destination:GetY());
		local moved=ok and result~=false and unit:GetX()==destination:GetX() and unit:GetY()==destination:GetY();
		return moved,moved and reason or "PLACE_FAILED",destination:GetIndex();
	end
	local retryOptions={};
	for _,entry in ipairs(placementOptions or {}) do if entry.Distance==destinationDistance then retryOptions[#retryOptions+1]=entry; end end
	diagnostic.RetryCandidateCount=#retryOptions;
	local lastDestination=destination; local lastOutcome="NO_ATTEMPT";
	for attempt,entry in ipairs(retryOptions) do
		destination=entry.Plot; lastDestination=destination;
		local beforeX,beforeY=unit:GetX(),unit:GetY();
		local ok,result=pcall(UnitManager.PlaceUnit,unit,destination:GetX(),destination:GetY());
		local finalX,finalY=unit:GetX(),unit:GetY(); local unchanged=finalX==beforeX and finalY==beforeY;
		local moved=ok and result~=false and finalX==destination:GetX() and finalY==destination:GetY();
		local outcome="";
		if moved then outcome="MOVED";
		elseif not ok then outcome="PCALL_ERROR";
		elseif result==false then outcome="API_FALSE";
		elseif unchanged and result==nil then outcome="API_NIL_NO_MOVE";
		elseif unchanged then outcome="API_"..string.upper(type(result)).."_NO_MOVE";
		else outcome="UNEXPECTED_COORD_CHANGE"; end
		lastOutcome=outcome;
		diagnostic.Attempts[#diagnostic.Attempts+1]="attempt="..attempt..",plot="..destination:GetIndex()..",distance="..entry.Distance..",callOK="..tostring(ok)..",rawType="..type(result)..",raw="..tostring(result)..",finalXY="..finalX..":"..finalY..",outcome="..outcome;
		diagnostic.CallOK=ok; diagnostic.RawResult=tostring(result); diagnostic.RawResultType=type(result); diagnostic.FinalX=finalX; diagnostic.FinalY=finalY; diagnostic.Moved=moved; diagnostic.Destination=destination:GetIndex(); diagnostic.DestinationDistance=entry.Distance; diagnostic.FailureReason=moved and "" or outcome;
		if moved then diagnostic.Status="MOVED"; diagnostic.AttemptCount=attempt; return true,attempt==1 and reason or reason.."_RETRY_"..attempt,destination:GetIndex(); end
		if not unchanged then diagnostic.Status="PLACE_FAILED_UNEXPECTED_COORD_CHANGE"; diagnostic.AttemptCount=attempt; return false,"PLACE_FAILED_"..outcome,destination:GetIndex(); end
	end
	diagnostic.Status="PLACE_FAILED_ALL"; diagnostic.AttemptCount=#retryOptions; diagnostic.FailureReason=lastOutcome;
	return false,"PLACE_FAILED_ALL_"..#retryOptions,lastDestination:GetIndex();
end

function LOTM_RESCUE_SyncActions.MoveTowardNative(unit,target)
	if unit==nil or target==nil or UnitManager.CanStartOperation==nil or UnitManager.RequestOperation==nil
		or UnitOperationTypes==nil or UnitOperationTypes.MOVE_TO==nil
		or UnitOperationTypes.PARAM_X==nil or UnitOperationTypes.PARAM_Y==nil then return false,"NATIVE_API",-1; end
	local source=Map.GetPlot(unit:GetX(),unit:GetY()); if source==nil then return false,"SOURCE",-1; end
	if Map.GetPlotDistance(source:GetX(),source:GetY(),target:GetX(),target:GetY())<=1 then return true,"ADJACENT",source:GetIndex(); end
	local candidates={}; local seen={};
	for dx=-1,1 do for dy=-1,1 do
		local plot=Map.GetPlotXYWithRangeCheck(target:GetX(),target:GetY(),dx,dy,1);
		if plot~=nil and not seen[plot:GetIndex()] and Open(plot,false,nil) then
			seen[plot:GetIndex()]=true;
			candidates[#candidates+1]={Plot=plot,Distance=Map.GetPlotDistance(source:GetX(),source:GetY(),plot:GetX(),plot:GetY())};
		end
	end end
	table.sort(candidates,function(a,b)
		if a.Distance~=b.Distance then return a.Distance<b.Distance; end
		return a.Plot:GetIndex()<b.Plot:GetIndex();
	end);
	for _,entry in ipairs(candidates) do
		local parameters={};
		parameters[UnitOperationTypes.PARAM_X]=entry.Plot:GetX();
		parameters[UnitOperationTypes.PARAM_Y]=entry.Plot:GetY();
		local canOK,canStart=pcall(UnitManager.CanStartOperation,unit,UnitOperationTypes.MOVE_TO,nil,parameters);
		if canOK and canStart then
			local beforeX,beforeY=unit:GetX(),unit:GetY();
			local requestOK,requested=pcall(UnitManager.RequestOperation,unit,UnitOperationTypes.MOVE_TO,parameters);
			local moved=requestOK and requested~=false and (unit:GetX()~=beforeX or unit:GetY()~=beforeY);
			if moved then
				local plot=Map.GetPlot(unit:GetX(),unit:GetY());
				return true,"NATIVE_MOVE",plot~=nil and plot:GetIndex() or -1;
			end
		end
	end
	return false,"NATIVE_NO_PATH",-1;
end

function LOTM_RESCUE_SyncActions.MarkScriptedKiller(target,killer)
	if target==nil or killer==nil then return; end
	local prefix="LOTM_RESCUE_SCRIPTED_KILLER:"..target:GetOwner()..":"..target:GetID()..":";
	-- Unit IDs can be reused after removal.  Bind the attribution to the
	-- target's durable gameplay identity so an old scripted-kill record can
	-- never reward or settle a later unit generation with the same owner/ID.
	local monsterSerial=tonumber(target:GetProperty("LOTM_WORLD_MONSTER_SERIAL") or 0) or 0;
	local sequenceSerial=tonumber(target:GetProperty("LOTM_RESCUE_PHASE4_SEQUENCE_SERIAL") or 0) or 0;
	local targetKind="UNIT"; local targetSerial=0;
	if monsterSerial>0 then targetKind="MONSTER"; targetSerial=monsterSerial;
	elseif sequenceSerial>0 then targetKind="SEQUENCE"; targetSerial=sequenceSerial; end
	-- Clear the commit fields first.  If an unexpected exception interrupts the
	-- following writes, consumers fail closed instead of pairing a new identity
	-- with a stale killer.
	Game.SetProperty(prefix.."PLAYER",nil);
	Game.SetProperty(prefix.."UNIT",nil);
	Game.SetProperty(prefix.."TARGET_KIND",targetKind);
	Game.SetProperty(prefix.."TARGET_SERIAL",targetSerial);
	Game.SetProperty(prefix.."PLAYER",killer:GetOwner());
	Game.SetProperty(prefix.."UNIT",killer:GetID());
end

function LOTM_RESCUE_SyncActions.ScriptedKill(target,killer)
	if target==nil or killer==nil or UnitManager.Kill==nil then return false; end
	if LOTM_RESCUE_Phase10~=nil and LOTM_RESCUE_Phase10.IsDescentProtected~=nil
	 and LOTM_RESCUE_Phase10.IsDescentProtected(target) then return false; end
	local owner=target:GetOwner(); local unitID=target:GetID();
	LOTM_RESCUE_SyncActions.MarkScriptedKiller(target,killer);
	local ok=pcall(UnitManager.Kill,target);
	if not ok then return false; end
	local checked,current=pcall(UnitManager.GetUnit,owner,unitID);
	return checked and current==nil;
end
