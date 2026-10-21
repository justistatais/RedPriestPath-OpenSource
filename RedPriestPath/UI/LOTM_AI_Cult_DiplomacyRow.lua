-- BEGIN RC342 STARTUP TRACE
-- Optional startup diagnostics, resource 393. Embedded by generate_startup_trace.py so a
-- missing VFS import cannot hide the first startup checkpoint.
-- Keep disabled in releases: high-frequency UI tracing caused severe stutter.
-- To diagnose a new failure, enable and rerun both startup/bundle generators.
if LOTM_StartupTrace == nil then
	LOTM_StartupTrace = { Enabled=false, Resource=393 };
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
		print("[LOTM_DIAG] r=393 seq=" .. sequence .. " ctx=" .. context
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
LOTM_StartupTrace.Mark("LOTM_AI_Cult_DiplomacyRow","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"LOTM_AI_Cult_DiplomacyRow","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"LOTM_AI_Cult_DiplomacyRow","GameEvents");
local LuaEvents = LOTM_StartupTrace.Events(LuaEvents,"LOTM_AI_Cult_DiplomacyRow","LuaEvents");
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
do
-- END RC342 STARTUP TRACE
local PATHS={
 DEMONESS={Name="LOC_LOTM_CULT_DEMONESS_NAME",Icon="ICON_LOTM_CULT_DEMONESS"},
 HANGED_MAN={Name="LOC_LOTM_CULT_HANGED_MAN_NAME",Icon="ICON_LOTM_CULT_HANGED_MAN"},
 CHAINED={Name="LOC_LOTM_CULT_CHAINED_NAME",Icon="ICON_LOTM_CULT_CHAINED"}
};

local function SetIcon(iconName)
 local x,y,sheet=IconManager:FindIconAtlas(iconName,32); if sheet~=nil and sheet~="" then Controls.CultIcon:SetTexture(x,y,sheet); Controls.CultIcon:SetHide(false); else Controls.CultIcon:SetHide(true); end
end
local function Refresh(selectedPlayerID:number)
 local player=Players[selectedPlayerID]; local localPlayer=Players[Game.GetLocalPlayer()];
 local met=false; if player~=nil and localPlayer~=nil then local diplomacy=localPlayer:GetDiplomacy(); met=selectedPlayerID==Game.GetLocalPlayer() or (diplomacy~=nil and diplomacy:HasMet(selectedPlayerID)); end
 local path=player~=nil and tostring(player:GetProperty("LOTM_CULT_PATH") or "NONE") or "NONE"; local info=PATHS[path];
 if player==nil or player:IsHuman() or info==nil or not met then Controls.Top:SetHide(true); ContextPtr:SetAutoSize(true); return; end
 Controls.Top:SetHide(false); SetIcon(info.Icon);
 local tier=tonumber(Game.GetProperty("LOTM_CULT_"..path.."_TIER")) or 1;
 local skillTag="LOC_LOTM_CULT_"..path.."_T"..tostring(tier).."_NAME";
 local rescue=tonumber(Game.GetProperty("LOTM_RESCUE_MODE") or 0)==1;
 local descriptionTag=rescue and ("LOC_LOTM_RESCUE_PHASE7_"..path.."_T"..tostring(tier).."_DESCRIPTION") or ("LOC_LOTM_CULT_"..path.."_T"..tostring(tier).."_DESCRIPTION");
 Controls.CultText:SetText(Locale.Lookup("LOC_LOTM_CULT_DIPLO_VALUE",Locale.Lookup(info.Name),tier,Locale.Lookup(skillTag)));
 Controls.CultText:SetToolTipString(Locale.Lookup(descriptionTag)); Controls.CultIcon:SetToolTipString(Locale.Lookup(descriptionTag)); ContextPtr:SetAutoSize(true);
end
local function Initialize() ContextPtr:SetAutoSize(true); LuaEvents.DiploScene_RefreshOverviewRows.Add(Refresh); end
Initialize();
-- BEGIN RC342 STARTUP TRACE

end
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("LOTM_AI_Cult_DiplomacyRow","CONTEXT END");
-- END RC342 STARTUP TRACE
