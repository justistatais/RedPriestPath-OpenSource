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
LOTM_StartupTrace.Mark("LOTM_RESCUE_ArtifactPillage","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"LOTM_RESCUE_ArtifactPillage","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"LOTM_RESCUE_ArtifactPillage","GameEvents");
local LuaEvents = LOTM_StartupTrace.Events(LuaEvents,"LOTM_RESCUE_ArtifactPillage","LuaEvents");
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
do
-- END RC342 STARTUP TRACE
-- Rescue Ember fallback action. Gameplay is authoritative and revalidates all
-- fields received through EXECUTE_SCRIPT.
local COMMAND="LOTM_RESCUE_Command_OwnPillage";
local function LocalUnit()
 local playerID=Game.GetLocalPlayer(); local unit=UI.GetHeadSelectedUnit();
 if playerID==nil or playerID<0 or unit==nil or unit:GetOwner()~=playerID then return nil,nil; end
 return playerID,unit;
end
local function EmberActive(player)
 local row=GameInfo.Resources["RESOURCE_LOTM_RESCUE_ARTIFACT_LEASE_08_POS"];
 return row~=nil and player~=nil and (player:GetResources():GetResourceAmount(row.Index) or 0)>0;
end
local function HasOwnPillageTarget(playerID,unit)
 if unit==nil or (unit:GetMovesRemaining() or 0)<=0 then return false; end
 if (unit:GetCombat() or 0)<=0 and (unit:GetRangedCombat() or 0)<=0 and (unit:GetBombardCombat() or 0)<=0 then return false; end
 local plot=Map.GetPlot(unit:GetX(),unit:GetY()); if plot==nil or plot:GetOwner()~=playerID then return false; end
 local improvement=GameInfo.Improvements[plot:GetImprovementType()];
 if improvement~=nil and not plot:IsImprovementPillaged() and improvement.PlunderType~="NO_PLUNDER" and improvement.PlunderType~="PLUNDER_NONE" then return true; end
 local district=CityManager.GetDistrictAt(unit:GetX(),unit:GetY()); local info=district~=nil and GameInfo.Districts[district:GetType()] or nil;
 if info==nil or info.PlunderType=="NO_PLUNDER" or info.PlunderType=="PLUNDER_NONE" then return false; end
 local city=Cities.GetPlotPurchaseCity(plot); local buildings=city~=nil and city:GetBuildings() or nil;
 if buildings~=nil then for building in GameInfo.Buildings() do
  if building.PrereqDistrict==info.DistrictType and buildings:HasBuilding(building.Index) and not buildings:IsPillaged(building.Index) and tonumber(building.Pillage or 1)~=0 then return true; end
 end end
 return not district:IsPillaged();
end
local function NativePillageAvailable(unit)
 local operation=GameInfo.UnitOperations["UNITOPERATION_PILLAGE"];
 if unit==nil or operation==nil then return false; end
 local ok,result=pcall(function() return UnitManager.CanStartOperation(unit,operation.Hash,nil,false,OperationResultsTypes.NO_TARGETS); end);
 return ok and result==true;
end
local function Refresh()
 local playerID,unit=LocalUnit(); local player=playerID~=nil and Players[playerID] or nil;
 local show=player~=nil and player:IsTurnActive() and EmberActive(player) and HasOwnPillageTarget(playerID,unit) and not NativePillageAvailable(unit);
 Controls.OwnPillageButton:SetHide(not show);
end
local function Submit()
 local playerID,unit=LocalUnit(); if playerID==nil or not HasOwnPillageTarget(playerID,unit) then Refresh(); return; end
 local parameters={}; parameters[UnitCommandTypes.PARAM_NAME]=COMMAND; parameters[UnitCommandTypes.PARAM_X]=unit:GetX(); parameters[UnitCommandTypes.PARAM_Y]=unit:GetY();
 UnitManager.RequestCommand(unit,UnitCommandTypes.EXECUTE_SCRIPT,parameters);
end
local function Initialize()
 ContextPtr:SetHide(false); Controls.OwnPillageButton:RegisterCallback(Mouse.eLClick,Submit);
 Events.UnitSelectionChanged.Add(Refresh); Events.LocalPlayerTurnBegin.Add(Refresh);
 if Events.UnitMovementPointsChanged~=nil then Events.UnitMovementPointsChanged.Add(Refresh); end
 if Events.ImprovementChanged~=nil then Events.ImprovementChanged.Add(Refresh); end
 if Events.DistrictPillaged~=nil then Events.DistrictPillaged.Add(Refresh); end
 if Events.GameCoreEventPublishComplete~=nil then Events.GameCoreEventPublishComplete.Add(Refresh); end
 Refresh();
end
Initialize();
-- BEGIN RC342 STARTUP TRACE

end
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("LOTM_RESCUE_ArtifactPillage","CONTEXT END");
-- END RC342 STARTUP TRACE
