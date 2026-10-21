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
LOTM_StartupTrace.Mark("LOTM_GodBlessingFX","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"LOTM_GodBlessingFX","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"LOTM_GodBlessingFX","GameEvents");
local LuaEvents = LOTM_StartupTrace.Events(LuaEvents,"LOTM_GodBlessingFX","LuaEvents");
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
do
-- END RC342 STARTUP TRACE
include("InstanceManager");
local m_instances=InstanceManager:new("GodBlessingFXInstance","Anchor",Controls.Effects);
local CONFIG={
 STORM={Frames=216,FPS=24,Width=768,Height=512,OffsetY=-147,Z=0,Prefix="LOTM_GOD_FX_STORM_V4_"},
 NIGHT={Frames=168,FPS=24,Width=256,Height=256,OffsetY=-12,Z=12,Prefix="LOTM_GOD_FX_NIGHT_"},
 FOOL={Frames=192,FPS=24,Width=256,Height=256,OffsetY=-12,Z=12,Prefix="LOTM_GOD_FX_FOOL_"}};
local m_seen={};
local m_active={};
local m_initialized=false;
local function Rescue()
 local value=GameConfiguration.GetValue("GAMEMODE_LOTM_RESCUE");
 return value==true or tonumber(value)==1;
end
local function Enabled()
 return GameInfo.WMDs~=nil and GameInfo.WMDs.WMD_LOTM_LIGHTNING_STORM~=nil
  and Rescue()==(tonumber(Game.GetProperty("LOTM_RESCUE_MODE") or 0)==1);
end
local function N(p,k,d)
 local value=p~=nil and p:GetProperty(k) or nil;
 return value~=nil and tonumber(value) or d;
end
local function PlayersOrdered()
 local ids={}; for _,p in ipairs(PlayerManager.GetWasEverAliveMajors()) do ids[#ids+1]=p:GetID(); end
 table.sort(ids); return ids;
end
local function Active(owner,serial)
 for _,effect in ipairs(m_active) do if effect.Owner==owner and effect.FXSerial==serial then return true; end end
 return false;
end
local function Start(kind,plotIndex,owner,fxSerial)
 if Rescue() and kind~="STORM" then return; end
 local config=CONFIG[kind]; local plot=Map.GetPlotByIndex(plotIndex);
 if config==nil or plot==nil then return; end
 local localID=Game.GetLocalPlayer(); local visibility=PlayersVisibility[localID];
 if localID~=owner and (visibility==nil or not visibility:IsVisible(plot:GetX(),plot:GetY())) then return; end
 if fxSerial~=nil and Active(owner,fxSerial) then return; end
 local instance=m_instances:GetInstance(); local x,y=UI.GridToWorld(plotIndex);
 instance.Anchor:SetWorldPositionVal(x,y,config.Z);
 instance.Frames:SetSizeVal(config.Width,config.Height);
 -- The v4 scene's ground origin projects147px above the image bottom.
 -- Align that point to the target hex; keep all five clouds in full framing.
 instance.Frames:SetOffsetY(config.OffsetY);
 local p=Players[owner]; local key="LOTM_GOD_FX_"..tostring(fxSerial or 0).."_";
 m_active[#m_active+1]={Kind=kind,Config=config,Instance=instance,Age=0,LastFrame=-1,Owner=owner,Plot=plotIndex,
  FXSerial=fxSerial or 0,CastSerial=N(p,key.."CAST_SERIAL",0),ImpactFrame=N(p,key.."IMPACT_FRAME",-1),CueAge=0,LastRequestAge=-1};
 print("[LOTM][GodFX] start kind="..kind.." plot="..plotIndex.." owner="..owner);
end
local function Refresh()
 -- Native add-ins start hidden, including this WorldAnchor parent. Keep the
 -- active-mode gate while allowing the storm animation to render.
 local normal=Enabled(); ContextPtr:SetHide(not normal);
 if not normal then return; end
 for _,id in ipairs(PlayersOrdered()) do
  local p=Players[id]; local latest=N(p,"LOTM_GOD_FX_SERIAL",0);
  local previous=m_seen[id];
  if previous==nil then m_seen[id]=latest;
  else
   for serial=previous+1,latest do
    local key="LOTM_GOD_FX_"..serial.."_";
    Start(tostring(p:GetProperty(key.."KIND") or ""),N(p,key.."PLOT",-1),id,serial);
   end
   m_seen[id]=latest;
  end
  -- Historical blessings remain suppressed on load. Replay only the durable
  -- storm that was accepted but has not reached its impact operation yet.
  if N(p,"LOTM_STORM_WINDUP",0)==1 then
   local serial=N(p,"LOTM_STORM_START_FX_SERIAL",0); local key="LOTM_GOD_FX_"..serial.."_";
   if serial>0 and N(p,key.."CAST_SERIAL",-1)==N(p,"LOTM_STORM_CAST_SERIAL",0) then
    Start("STORM",N(p,key.."PLOT",-1),id,serial);
   end
  end
 end
 m_initialized=true;
end
local function AwaitingImpact(effect)
 local p=Players[effect.Owner];
 return effect.Kind=="STORM" and effect.CastSerial>0 and p~=nil and p:IsAlive() and p:IsHuman()
  and N(p,"LOTM_STORM_WINDUP",0)==1 and N(p,"LOTM_STORM_CAST_SERIAL",0)==effect.CastSerial
  and N(p,"LOTM_STORM_START_FX_SERIAL",0)==effect.FXSerial;
end
local function DrawFrame(effect,frame)
 if frame==effect.LastFrame then return; end
 effect.LastFrame=frame;
 local sheet=math.floor(frame/16); local cell=frame%16;
 effect.Instance.Frames:SetTexture((cell%4)*effect.Config.Width,math.floor(cell/4)*effect.Config.Height,
  string.format("%s%02d.dds",effect.Config.Prefix,sheet));
 local remaining=effect.Config.Frames/effect.Config.FPS-effect.Age;
 effect.Instance.Frames:SetAlpha(math.min(1,remaining/0.35));
end
local function RequestImpact(effect,frame)
 if not Enabled() or Game.GetLocalPlayer()~=effect.Owner or not AwaitingImpact(effect)
  or effect.ImpactFrame<0 or frame<effect.ImpactFrame or effect.CueAge-effect.LastRequestAge<0.75 then return; end
 effect.LastRequestAge=effect.CueAge;
 -- Only the owning client reports the visible cue. Damage/costs/receipts are
 -- changed by the synchronized Gameplay handler, never by this render clock.
 UI.RequestPlayerOperation(effect.Owner,PlayerOperations.EXECUTE_SCRIPT,
  {OnStart="LOTM_Storm_Impact",CastSerial=effect.CastSerial,FXSerial=effect.FXSerial,PlotIndex=effect.Plot,PresentedFrame=frame});
 print("[LOTM][GodFX] impact cue owner="..effect.Owner.." cast="..effect.CastSerial.." fx="..effect.FXSerial.." frame="..frame);
end
local function Update(delta)
 if not m_initialized or #m_active==0 then return; end
 for i=#m_active,1,-1 do
  local effect=m_active[i]; effect.Age=effect.Age+delta; effect.CueAge=effect.CueAge+delta;
  local frame=math.floor(effect.Age*effect.Config.FPS);
  -- A stalled UI can jump past the entire clip. Show the reviewed strike
  -- frame and deliver its cue rather than silently dropping the damage.
  if AwaitingImpact(effect) and effect.ImpactFrame>=0
   and ((effect.LastFrame<effect.ImpactFrame and frame>=effect.ImpactFrame) or frame>=effect.Config.Frames) then
   frame=effect.ImpactFrame; effect.Age=frame/effect.Config.FPS;
  end
  if frame>=effect.Config.Frames then
   m_instances:ReleaseInstance(effect.Instance); table.remove(m_active,i);
  else
   DrawFrame(effect,frame); RequestImpact(effect,frame);
  end
 end
end
ContextPtr:SetUpdate(Update);
Events.LoadGameViewStateDone.Add(Refresh);
Events.GameCoreEventPublishComplete.Add(Refresh);
Events.LocalPlayerChanged.Add(function() m_instances:ResetInstances(); m_active={}; m_seen={}; Refresh(); end);
Refresh();

-- BEGIN RC342 STARTUP TRACE

end
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("LOTM_GodBlessingFX","CONTEXT END");
-- END RC342 STARTUP TRACE
