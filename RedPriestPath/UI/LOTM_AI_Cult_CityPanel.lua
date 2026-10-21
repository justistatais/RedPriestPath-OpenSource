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
LOTM_StartupTrace.Mark("LOTM_AI_Cult_CityPanel","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"LOTM_AI_Cult_CityPanel","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"LOTM_AI_Cult_CityPanel","GameEvents");
local LuaEvents = LOTM_StartupTrace.Events(LuaEvents,"LOTM_AI_Cult_CityPanel","LuaEvents");
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
do
-- END RC342 STARTUP TRACE
-- Preserve Firaxis Expansion 2 CityPanel, then append read-only cult sources.
include("CityPanel_Expansion2");

local LOTM_BASE_ViewMain=ViewMain;

local function AppendSource(tooltip,line)
 if line==nil or line=="" then return tooltip; end
 tooltip=tostring(tooltip or "");
 if string.find(tooltip,line,1,true)~=nil then return tooltip; end
 return tooltip..(#tooltip>0 and "[NEWLINE]" or "")..line;
end

local function DemonessSource()
 local player=Players[Game.GetLocalPlayer()]; if player==nil then return nil,nil; end
 local token=tostring(player:GetProperty("LOTM_CULT_APPLIED_DEMONESS") or "NONE");
 local flat=tonumber(string.match(token,"^DEMONESS_V2_T1_M(%d+)$"));
 if flat~=nil and flat>0 then return Locale.Lookup("LOC_LOTM_CULT_DEMONESS_CITY_FLAT_TOOLTIP",-flat),"FLAT"; end
 local percent=tonumber(string.match(token,"^DEMONESS_T2_P(%d+)$")) or tonumber(string.match(token,"^DEMONESS_T3_A%d+_P(%d+)$"));
 if percent~=nil and percent>0 then return Locale.Lookup("LOC_LOTM_CULT_DEMONESS_CITY_PERCENT_TOOLTIP",-percent),"PERCENT"; end
 return nil,nil;
end

function ViewMain(data)
 local line,mode=DemonessSource();
 if line~=nil then
  data.FoodPerTurnToolTip=AppendSource(data.FoodPerTurnToolTip,line);
  data.ProductionPerTurnToolTip=AppendSource(data.ProductionPerTurnToolTip,line);
  if mode=="FLAT" then
   data.SciencePerTurnToolTip=AppendSource(data.SciencePerTurnToolTip,line);
   data.CulturePerTurnToolTip=AppendSource(data.CulturePerTurnToolTip,line);
  end
 end
 local player=Players[Game.GetLocalPlayer()];
 local targetDebuff=player~=nil and tonumber(player:GetProperty("LOTM_TP_PRODUCTION_DEBUFF_ACTIVE") or 0) or 0;
 if targetDebuff==1 then
  data.ProductionPerTurnToolTip=AppendSource(data.ProductionPerTurnToolTip,Locale.Lookup("LOC_LOTM_TP_PRODUCTION_DEBUFF_TOOLTIP"));
 end
 local stolenAmount=player~=nil and tonumber(player:GetProperty("LOTM_TP_LAST_PRODUCTION_STEAL_AMOUNT") or 0) or 0;
 local stolenCity=player~=nil and tonumber(player:GetProperty("LOTM_TP_LAST_PRODUCTION_STEAL_CITY") or -1) or -1;
 local stolenTurn=player~=nil and tonumber(player:GetProperty("LOTM_TP_LAST_PRODUCTION_STEAL_TURN") or -1) or -1;
 local dataCity=tonumber(data.CityID or data.ID or data.CityId or (data.City~=nil and data.City:GetID()) or -1) or -1;
 if stolenAmount>0 and stolenCity==dataCity and stolenTurn==Game.GetCurrentGameTurn() then
  data.ProductionPerTurnToolTip=AppendSource(data.ProductionPerTurnToolTip,Locale.Lookup("LOC_LOTM_TP_PRODUCTION_STEAL_TOOLTIP",stolenAmount));
 end
 LOTM_BASE_ViewMain(data);
end
-- BEGIN RC342 STARTUP TRACE

end
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("LOTM_AI_Cult_CityPanel","CONTEXT END");
-- END RC342 STARTUP TRACE
