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
LOTM_StartupTrace.Mark("LOTM_RESCUE_DiplomacyRibbon","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"LOTM_RESCUE_DiplomacyRibbon","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"LOTM_RESCUE_DiplomacyRibbon","GameEvents");
local LuaEvents = LOTM_StartupTrace.Events(LuaEvents,"LOTM_RESCUE_DiplomacyRibbon","LuaEvents");
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
do
-- END RC342 STARTUP TRACE
-- Rescue-mode two-row diplomacy ribbon.
-- Keep Firaxis' complete Gathering Storm chain, then constrain the ribbon to
-- the screen area to the right of the centered purification HUD.
include("DiplomacyRibbon_Expansion2");

local LOTM_BASE_RealizeSize=RealizeSize;
local LEADER_WIDTH=63;
local WIDE_HUD_HALF=250;
local COMPACT_HUD_HALF=200;
local COMPACT_BREAKPOINT=1600;
local HUD_GAP=16;
local MIN_ROW_SLOTS=4;

function RealizeSize(additionalElementsWidth:number)
 LOTM_BASE_RealizeSize(additionalElementsWidth);

 local screenX:number=UIManager:GetScreenSizeVal();
 local hudHalf:number=screenX<COMPACT_BREAKPOINT and COMPACT_HUD_HALF or WIDE_HUD_HALF;
 local rightReserved:number=math.max(0,Controls.RibbonContainer:GetOffsetX());
 local padding:number=Controls.LeaderStack:GetStackPadding();
 local leaderStep:number=math.max(1,LEADER_WIDTH+padding);
 local safeWidth:number=math.max(leaderStep*MIN_ROW_SLOTS,math.floor((screenX/2)-hudHalf-HUD_GAP-rightReserved));
 local preferredSlots:number=math.max(MIN_ROW_SLOTS,math.floor(safeWidth/leaderStep));
 local children:table=Controls.LeaderStack:GetChildren();
 local childCount:number=table.count(children);

 -- Always keep every met leader visible in at most two rows.  In ordinary
 -- games preferredSlots is already sufficient; the ceil fallback only grows
 -- the ribbon for unusually large player counts or very narrow resolutions.
 local rowSlots:number=math.max(1,math.min(math.max(preferredSlots,math.ceil(childCount/2)),math.max(1,childCount)));
 local wrapWidth:number=rowSlots*leaderStep;
 Controls.LeaderStack:SetWrapWidth(wrapWidth);
 Controls.LeaderStack:CalculateSize();

 local rows:number=math.max(1,math.ceil(childCount/rowSlots));
 local stackHeight:number=math.max(60,Controls.LeaderStack:GetSizeY());
 local viewportHeight:number=math.max(60,math.ceil(stackHeight/rows)*rows+8);
 local viewportWidth:number=wrapWidth+8;
 Controls.ScrollContainer:SetSizeX(viewportWidth);
 Controls.ScrollContainer:SetSizeY(viewportHeight);
 Controls.LeaderScroll:SetSizeX(viewportWidth);
 Controls.LeaderScroll:SetSizeY(viewportHeight);
 Controls.RibbonContainer:SetSizeX(viewportWidth+50);
 Controls.RibbonContainer:SetSizeY(viewportHeight);

 -- Base scrolling counts leaders, not the Congress child.  Two-row capacity
 -- is deliberately large enough to suppress arrows while all children fit.
 g_maxNumLeaders=math.max(g_maxNumLeaders,rowSlots*2);
 Controls.LeaderScroll:CalculateSize();
 RealizeScroll();
end

print("[LOTM_RESCUE][DiplomacyRibbon] loaded layout=two-row hudSafe=true");
-- BEGIN RC342 STARTUP TRACE

end
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("LOTM_RESCUE_DiplomacyRibbon","CONTEXT END");
-- END RC342 STARTUP TRACE
