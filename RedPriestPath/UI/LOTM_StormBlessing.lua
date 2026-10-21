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
LOTM_StartupTrace.Mark("LOTM_StormBlessing","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"LOTM_StormBlessing","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"LOTM_StormBlessing","GameEvents");
local LuaEvents = LOTM_StartupTrace.Events(LuaEvents,"LOTM_StormBlessing","LuaEvents");
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
do
-- END RC342 STARTUP TRACE
local m_enteredSerial=-1;
local m_waiting=false;
local m_resultSerial=-1;
local m_localError=nil;
local m_screenX=nil;
local m_screenY=nil;
local m_visible=nil;
local m_lensTitle=nil;
local m_originalLensTitle=nil;
local m_aimExpected=nil;
local m_aimTurn=nil;
local m_aimToken=0;
-- 用户红圈：1920x1080时中心1820,752；距离右边100、底边328。
local RIGHT_CENTER=100;
local BOTTOM_CENTER=328;
local function RealizePosition()
 local screenX,screenY=UIManager:GetScreenSizeVal();
 if screenX==nil or screenY==nil or screenX<=0 or screenY<=0 then return; end
 if screenX==m_screenX and screenY==m_screenY then return; end
 Controls.Root:SetOffsetX(math.max(0,screenX-RIGHT_CENTER-36));
 Controls.Root:SetOffsetY(math.max(0,screenY-BOTTOM_CENTER-38));
 Controls.Root:ReprocessAnchoring();
 Controls.TargetHint:SetOffsetX(math.max(0,math.floor((screenX-288)/2)));
 Controls.TargetHint:ReprocessAnchoring();
 m_screenX=screenX; m_screenY=screenY;
 print("[LOTM][StormUI] position screen="..screenX.."x"..screenY
  .." center="..(screenX-RIGHT_CENTER)..","..(screenY-BOTTOM_CENTER));
end
local function Rescue()
 local value=GameConfiguration.GetValue("GAMEMODE_LOTM_RESCUE");
 return value==true or tonumber(value)==1;
end
local function Enabled()
 return GameInfo.WMDs~=nil and GameInfo.WMDs.WMD_LOTM_LIGHTNING_STORM~=nil
  and Rescue()==(tonumber(Game.GetProperty("LOTM_RESCUE_MODE") or 0)==1);
end
local function Player()
 local id=Game.GetLocalPlayer(); return id~=nil and id>=0 and Players[id] or nil;
end
local function N(p,k,d)
 local value=p~=nil and p:GetProperty(k) or nil;
 return value~=nil and tonumber(value) or d;
end
local function LocalAim(p)
 return p~=nil and m_aimExpected~=nil and p:IsHuman() and p:IsTurnActive()
  and m_aimTurn==Game.GetCurrentGameTurn()
  and m_aimExpected==N(p,"LOTM_STORM_CAST_SERIAL",0)
  and N(p,"LOTM_STORM_PENDING",0)~=1 and N(p,"LOTM_STORM_WINDUP",0)~=1
  and N(p,"LOTM_STORM_CHARGES",0)>0;
end
local function ClearLocalAim()
 m_aimExpected=nil;
 m_aimTurn=nil;
 LuaEvents.LOTM_Storm_LocalAim(-1,-1,-1);
end
local function RealizeTargetTitle(p)
 local aiming=Enabled() and p~=nil and p:IsHuman() and p:IsTurnActive()
  and (LocalAim(p) or (N(p,"LOTM_STORM_PENDING",0)==1 and N(p,"LOTM_STORM_WINDUP",0)~=1 and N(p,"LOTM_STORM_DELIVERY_VERSION",0)==3))
  and UI.GetInterfaceMode()==InterfaceModeTypes.VIEW_MODAL_LENS;
 local title=Locale.Lookup("LOC_LOTM_STORM_NAME");
 if aiming then
  if m_lensTitle==nil then
   m_lensTitle=ContextPtr:LookUpControl("/InGame/ModalLensPanel/LensText");
   if m_lensTitle~=nil then m_originalLensTitle=m_lensTitle:GetText(); end
  end
  if m_lensTitle~=nil then m_lensTitle:SetText(title); end
 elseif m_lensTitle~=nil then
  -- Restore only our own caption; a newly selected native lens owns its title.
  if m_lensTitle:GetText()==title then m_lensTitle:SetText(m_originalLensTitle); end
  m_lensTitle=nil; m_originalLensTitle=nil;
 end
end
local function Request(command,values)
 local p=Player(); if p==nil then return; end
 local parameters=values or {}; parameters.OnStart=command;
 UI.RequestPlayerOperation(p:GetID(),PlayerOperations.EXECUTE_SCRIPT,parameters);
end
local function Cancel()
 local p=Player(); if p==nil then return; end
 ClearLocalAim();
 if N(p,"LOTM_STORM_PENDING",0)==1 then Request("LOTM_Storm_Cancel",{CastSerial=N(p,"LOTM_STORM_CAST_SERIAL",0)}); end
 Controls.TargetHint:SetHide(true);
 if UI.GetInterfaceMode()==InterfaceModeTypes.VIEW_MODAL_LENS then
  UI.SetInterfaceMode(InterfaceModeTypes.SELECTION);
 end
end
local function Refresh()
 local p=Player(); local normal=Enabled() and p~=nil;
 -- Firaxis InGame.lua loads every add-in with isHidden=true. Showing Root
 -- alone never shows its parent context; match the existing launch/HUD code.
 ContextPtr:SetHide(not normal);
 if m_visible~=normal then
  m_visible=normal;
  print("[LOTM][StormUI] visible="..tostring(normal).." earnedChargesOnly=true");
 end
 Controls.Root:SetHide(not normal); if not normal then ClearLocalAim(); Controls.TargetHint:SetHide(true); RealizeTargetTitle(nil); return; end
 RealizePosition();
 local charges=N(p,"LOTM_STORM_CHARGES",0);
 local pending=N(p,"LOTM_STORM_PENDING",0)==1;
 local windup=N(p,"LOTM_STORM_WINDUP",0)==1;
 local serial=N(p,"LOTM_STORM_CAST_SERIAL",0);
 local resultSerial=N(p,"LOTM_STORM_RESULT_SERIAL",0);
 if resultSerial~=m_resultSerial then m_resultSerial=resultSerial; m_waiting=false; end
 if m_aimExpected~=nil and not LocalAim(p) then ClearLocalAim(); end
 Controls.Count:SetText(tostring(charges));
 Controls.StormButton:SetDisabled(m_waiting or windup or (charges<=0 and not pending) or not p:IsTurnActive() or tonumber(Game.GetProperty("LOTM_GOD_BLESSINGS_READY") or 0)~=1);
 Controls.StormIcon:SetAlpha(charges>0 and 1 or 0.45);
 local result=tostring(p:GetProperty("LOTM_STORM_RESULT") or "");
 local detail=Locale.Lookup("LOC_LOTM_STORM_TOOLTIP",charges);
 if Rescue() then detail=detail.."[NEWLINE]"..Locale.Lookup("LOC_LOTM_STORM_RESCUE_OUTER_HINT"); end
 if result~="" and result~="READY" and result~="CASTING" and result~="FIRED" and result~="CANCELLED" then
  detail=detail.."[NEWLINE]"..Locale.Lookup("LOC_LOTM_STORM_ERROR_"..result);
 end
 if m_localError~=nil then detail=detail.."[NEWLINE]"..Locale.Lookup(m_localError); end
 Controls.StormButton:SetToolTipString(detail);
 Controls.TargetHint:SetHide((not pending and not LocalAim(p)) or windup);
 if pending and not windup and N(p,"LOTM_STORM_DELIVERY_VERSION",0)==3 then
  if m_enteredSerial~=serial then
   m_enteredSerial=serial; m_localError=nil;
   UILens.SetActive("Default");
   UI.SetInterfaceMode(InterfaceModeTypes.VIEW_MODAL_LENS);
   print("[LOTM][StormUI] direct targeting player="..p:GetID().." serial="..serial);
  end
 elseif not LocalAim(p) and UI.GetInterfaceMode()==InterfaceModeTypes.VIEW_MODAL_LENS and m_enteredSerial>=0 then
  m_enteredSerial=-1; UI.SetInterfaceMode(InterfaceModeTypes.SELECTION);
 end
 RealizeTargetTitle(p);
end
local function Click()
 local p=Player(); if p==nil or not Enabled() then return; end
 if N(p,"LOTM_STORM_PENDING",0)==1 then
  if N(p,"LOTM_STORM_WINDUP",0)==1 then return; end
  if N(p,"LOTM_STORM_APPLYING",0)==1 then
   Request("LOTM_Storm_Fire",{CastSerial=N(p,"LOTM_STORM_CAST_SERIAL",0),
    PlotIndex=N(p,"LOTM_STORM_TARGET_PLOT",-1)}); return;
  end
  m_enteredSerial=-1; Refresh(); return;
 end
 if m_waiting or N(p,"LOTM_STORM_CHARGES",0)<=0 or not p:IsTurnActive() then return; end
 m_localError=nil;
 -- Opening/cancelling aiming is presentation only. Avoid a Gameplay operation
 -- and the large-save publication/refresh boundary before showing the cursor.
 m_aimExpected=N(p,"LOTM_STORM_CAST_SERIAL",0); m_aimToken=m_aimToken+1;
 m_aimTurn=Game.GetCurrentGameTurn();
 m_enteredSerial=m_aimExpected+1;
 LuaEvents.LOTM_Storm_LocalAim(p:GetID(),m_aimExpected,m_aimToken,m_aimTurn);
 UILens.SetActive("Default"); UI.SetInterfaceMode(InterfaceModeTypes.VIEW_MODAL_LENS);
 print("[LOTM][StormUI] local targeting player="..p:GetID().." expected="..m_aimExpected.." prepareOperations=0");
 Refresh();
end
Controls.StormButton:RegisterCallback(Mouse.eLClick,Click);
Controls.Cancel:RegisterCallback(Mouse.eLClick,Cancel);
Events.GameCoreEventPublishComplete.Add(Refresh);
Events.LoadGameViewStateDone.Add(Refresh);
LuaEvents.LOTM_Storm_LocalAimCleared.Add(function() m_aimExpected=nil; Controls.TargetHint:SetHide(true); end);
LuaEvents.LOTM_Storm_LocalCastSubmitted.Add(function(id)
 local p=Player(); if p==nil or id~=p:GetID() then return; end
 m_aimExpected=nil; m_waiting=true; m_resultSerial=N(p,"LOTM_STORM_RESULT_SERIAL",0);
 Controls.StormButton:SetDisabled(true); Controls.TargetHint:SetHide(true);
end);
Events.InterfaceModeChanged.Add(function()
 if UI.GetInterfaceMode()~=InterfaceModeTypes.VIEW_MODAL_LENS then ClearLocalAim(); Controls.TargetHint:SetHide(true); end
 RealizeTargetTitle(Player());
end);
Events.SystemUpdateUI.Add(function(updateType)
 if updateType==SystemUpdateUI.ScreenResize then m_screenX=nil; m_screenY=nil; Refresh(); end
end);
Events.PlayerTurnActivated.Add(function(id) if id==Game.GetLocalPlayer() then Refresh(); end end);
Events.LocalPlayerChanged.Add(function() ClearLocalAim(); m_enteredSerial=-1; m_resultSerial=-1; m_waiting=false; Refresh(); end);
Refresh();
-- BEGIN RC342 STARTUP TRACE

end
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("LOTM_StormBlessing","CONTEXT END");
-- END RC342 STARTUP TRACE
