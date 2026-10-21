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
LOTM_StartupTrace.Mark("LOTM_StormWorldInput","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"LOTM_StormWorldInput","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"LOTM_StormWorldInput","GameEvents");
local LuaEvents = LOTM_StartupTrace.Events(LuaEvents,"LOTM_StormWorldInput","LuaEvents");
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
do
-- END RC342 STARTUP TRACE
-- Keep Firaxis' full XP2/XP1 input chain. Only our active aiming session
-- handles map clicks; ordinary nuclear missiles keep their original handlers.
include("WorldInput_Expansion2");
local BASE_OnInputHandler=OnInputHandler;
local layer=UILens.CreateLensLayerHash("Hex_Coloring_Attack");
local lastPreview=-1;
local localAim=nil;
local function N(p,key,default)
 local value=p~=nil and p:GetProperty(key) or nil;
 return value~=nil and tonumber(value) or default;
end
local function Rescue()
 local value=GameConfiguration.GetValue("GAMEMODE_LOTM_RESCUE");
 return value==true or tonumber(value)==1;
end
local function Enabled()
 return GameInfo.WMDs~=nil and GameInfo.WMDs.WMD_LOTM_LIGHTNING_STORM~=nil
  and Rescue()==(tonumber(Game.GetProperty("LOTM_RESCUE_MODE") or 0)==1);
end
local function Session(serial)
 local id=Game.GetLocalPlayer(); local p=id~=nil and id>=0 and Players[id] or nil;
 if p==nil or not p:IsTurnActive() or not p:IsHuman()
  or not Enabled() or N(p,"LOTM_STORM_WINDUP",0)==1 then return nil; end
 local cast=N(p,"LOTM_STORM_CAST_SERIAL",0);
 if N(p,"LOTM_STORM_PENDING",0)==1 and N(p,"LOTM_STORM_DELIVERY_VERSION",0)==3 then
  if serial~=nil and cast~=serial then return nil; end
  return p,cast,nil,nil;
 end
 if localAim~=nil and localAim.Owner==id and localAim.Expected==cast
  and localAim.Turn==Game.GetCurrentGameTurn()
  and N(p,"LOTM_STORM_PENDING",0)~=1
  and tonumber(Game.GetProperty("LOTM_GOD_BLESSINGS_READY") or 0)==1
  and N(p,"LOTM_STORM_CHARGES",0)>0
  and (serial==nil or serial==cast+1) then return p,cast+1,cast,localAim.Token; end
 return nil;
end
local function ClearPreview()
 if lastPreview<0 then return; end
 UILens.ToggleLayerOff(layer); UILens.ClearLayerHexes(layer); lastPreview=-1;
 UIManager:SetUICursor(CursorTypes.NORMAL);
end
local function Blast(target)
 local result={}; local seen={};
 for dy=-1,1 do for dx=-1,1 do
  local plot=Map.GetPlotXYWithRangeCheck(target:GetX(),target:GetY(),dx,dy,1);
  if plot~=nil and not seen[plot:GetIndex()] then seen[plot:GetIndex()]=true; result[#result+1]=plot; end
 end end
 table.sort(result,function(a,b) return a:GetIndex()<b:GetIndex(); end); return result;
end
local function Revealed(p,target)
 return target~=nil and PlayersVisibility[p:GetID()]:IsRevealed(target:GetX(),target:GetY());
end
local function Preview(p)
 local index=UI.GetCursorPlotID(); local target=Map.GetPlotByIndex(index);
 if not Revealed(p,target) then ClearPreview(); return; end
 if lastPreview==index then return; end
 ClearPreview(); local indices={}; for _,plot in ipairs(Blast(target)) do indices[#indices+1]=plot:GetIndex(); end
 UILens.ToggleLayerOn(layer); UILens.SetLayerHexesArea(layer,p:GetID(),indices);
 lastPreview=index; UIManager:SetUICursor(CursorTypes.RANGE_ATTACK);
end
local function Wars(p,target)
 local seen={}; local diplomacy=p:GetDiplomacy();
 local function Owner(id)
  if id~=nil and id>=0 and id~=p:GetID() and Players[id]~=nil and not diplomacy:IsAtWarWith(id) then seen[id]=true; end
 end
 for _,plot in ipairs(Blast(target)) do
  Owner(plot:GetOwner());
  for _,unit in ipairs(Units.GetUnitsInPlot(plot) or {}) do Owner(unit:GetOwner()); end
  for _,unit in ipairs(plot:GetAirUnits() or {}) do Owner(unit:GetOwner()); end
 end
 local result={}; for id in pairs(seen) do result[#result+1]=id; end; table.sort(result); return result;
end
local function Strike(p,target,serial,wars,expected,token)
 local current,currentSerial,currentExpected,currentToken=Session(serial);
 if current~=p or currentSerial~=serial or currentExpected~=expected or currentToken~=token or N(p,"LOTM_STORM_APPLYING",0)==1 then return; end
 -- The dialog authorizes only these affected owners. Gameplay revalidates
 -- them and performs native declarations before any damage is applied.
 local confirmed={}; for _,id in ipairs(wars) do confirmed[#confirmed+1]=tostring(id); end
 local parameters={OnStart="LOTM_Storm_Fire",CastSerial=serial,ExpectedSerial=expected,ExpectedTurn=localAim~=nil and localAim.Turn or nil,PlotIndex=target:GetIndex(),ConfirmedWarOwners=table.concat(confirmed,",")};
 localAim=nil; LuaEvents.LOTM_Storm_LocalCastSubmitted(p:GetID());
 UI.RequestPlayerOperation(p:GetID(),PlayerOperations.EXECUTE_SCRIPT,parameters);
 print("[LOTM][StormUI] direct impact requested player="..p:GetID().." serial="..serial.." plot="..target:GetIndex());
 ClearPreview(); UI.SetInterfaceMode(InterfaceModeTypes.SELECTION);
end
local function Confirm(p)
 if N(p,"LOTM_STORM_APPLYING",0)==1 then return; end
 local target=Map.GetPlotByIndex(UI.GetCursorPlotID()); if not Revealed(p,target) then return; end
 local current,serial,expected,token=Session(); if current~=p then return; end
 local wars=Wars(p,target);
 local strike=function() Strike(p,target,serial,wars,expected,token); end;
 -- Copy only Firaxis' target/confirmation presentation; no native launch call.
 if #wars>0 then
  LuaEvents.WorldInput_ConfirmWarDialog(p:GetID(),wars,WarTypes.SURPRISE_WAR,strike);
 else
  local popup=PopupDialogInGame:new("ConfirmLOTMStormImpact");
  popup:AddText(Locale.Lookup("LOC_LOTM_STORM_CONFIRM"));
  popup:AddCancelButton(Locale.Lookup("LOC_LOTM_STORM_CONFIRM_CANCEL"),nil);
  popup:AddConfirmButton(Locale.Lookup("LOC_LOTM_STORM_CONFIRM_FIRE"),strike); popup:Open();
 end
end
function OnInputHandler(input)
 local p=Session(); local mode=UI.GetInterfaceMode();
 if p==nil or mode~=InterfaceModeTypes.VIEW_MODAL_LENS then
  ClearPreview(); return BASE_OnInputHandler(input);
 end
 local message=input:GetMessageType();
 if (message==KeyEvents.KeyUp and input:GetKey()==Keys.VK_ESCAPE) or message==MouseEvents.RButtonUp then
  if N(p,"LOTM_STORM_PENDING",0)==1 then
   UI.RequestPlayerOperation(p:GetID(),PlayerOperations.EXECUTE_SCRIPT,
    {OnStart="LOTM_Storm_Cancel",CastSerial=N(p,"LOTM_STORM_CAST_SERIAL",0)});
  end
  localAim=nil; LuaEvents.LOTM_Storm_LocalAimCleared();
  ClearPreview(); UI.SetInterfaceMode(InterfaceModeTypes.SELECTION); return true;
 elseif message==MouseEvents.LButtonDown or message==MouseEvents.PointerDown then return true;
 elseif message==MouseEvents.LButtonUp or message==MouseEvents.PointerUp then Confirm(p); return true;
 end
 Preview(p); return BASE_OnInputHandler(input);
end
-- Firaxis Initialize registered its original handler while included.
-- Rebind this one wrapper; native initialization remains complete.
ContextPtr:SetInputHandler(OnInputHandler,true);
LuaEvents.LOTM_Storm_LocalAim.Add(function(owner,expected,token,turn)
 localAim=owner>=0 and {Owner=owner,Expected=expected,Token=token,Turn=turn} or nil;
end);
Events.InterfaceModeChanged.Add(function()
 if UI.GetInterfaceMode()~=InterfaceModeTypes.VIEW_MODAL_LENS then localAim=nil; ClearPreview(); end
end);
Events.LocalPlayerChanged.Add(function() localAim=nil; ClearPreview(); end);
Events.GameCoreEventPublishComplete.Add(function()
 if Session()==nil or UI.GetInterfaceMode()~=InterfaceModeTypes.VIEW_MODAL_LENS then ClearPreview(); end
end);
-- BEGIN RC342 STARTUP TRACE

end
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("LOTM_StormWorldInput","CONTEXT END");
-- END RC342 STARTUP TRACE
