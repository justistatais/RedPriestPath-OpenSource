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
LOTM_StartupTrace.Mark("LOTM_RESCUE_DifficultyChoice","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"LOTM_RESCUE_DifficultyChoice","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"LOTM_RESCUE_DifficultyChoice","GameEvents");
local LuaEvents = LOTM_StartupTrace.Events(LuaEvents,"LOTM_RESCUE_DifficultyChoice","LuaEvents");
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
do
-- END RC342 STARTUP TRACE
-- Local presentation only. The synchronized Gameplay command validates and
-- publishes the global Redemption difficulty.
local COMMAND="LOTM_RESCUE_Command_SelectDifficulty";
local m_waiting=false;

local function LocalPlayer()
 local id=Game.GetLocalPlayer(); return id~=nil and id>=0 and id or -1,id~=nil and id>=0 and Players[id] or nil;
end

local function HumanChooserID()
 local ids={};
 for _,player in ipairs(PlayerManager.GetAliveMajors()) do
  if player:IsHuman() and player:GetCities():GetCount()>0 then ids[#ids+1]=player:GetID(); end
 end
 table.sort(ids); return ids[1] or -1;
end

local function Refresh()
 local id,player=LocalPlayer(); local decided=tonumber(Game.GetProperty("LOTM_RESCUE_DIFFICULTY_DECIDED") or 0)==1;
 if decided then m_waiting=false; end
 local ready=player~=nil and player:IsAlive() and player:IsMajor() and player:IsHuman()
  and player:GetCities():GetCount()>0 and id==HumanChooserID()
  and tonumber(player:GetProperty("LOTM_RP_PATH_DECIDED") or 0)==1;
 Controls.DifficultyPopup:SetHide(decided or m_waiting or not ready);
end

local function Submit(choice)
 if m_waiting or tonumber(Game.GetProperty("LOTM_RESCUE_DIFFICULTY_DECIDED") or 0)==1 then Refresh(); return; end
 local id,player=LocalPlayer(); if player==nil or player:GetCities():GetCount()<1 or id~=HumanChooserID() then Refresh(); return; end
 m_waiting=true; Controls.DifficultyPopup:SetHide(true);
 UI.RequestPlayerOperation(id,PlayerOperations.EXECUTE_SCRIPT,{OnStart=COMMAND,Choice=choice});
 print("[LOTM_RESCUE][DifficultyUI] submitted player="..id.." choice="..choice);
end

local function Initialize()
 ContextPtr:SetHide(false);
 Controls.NormalIcon:SetIcon("ICON_LOTM_WORLD_MONSTER_MARK");
 Controls.HardIcon:SetIcon("ICON_LOTM_WORLD_MONSTER_MARK");
 Controls.MadnessIcon:SetIcon("ICON_LOTM_RESCUE_OUTER_GOD_STAR_MARK");
 Controls.NormalIcon:SetColor(UI.GetColorValueFromHexLiteral(0xFFFFFFFF));
 local blood=UI.GetColorValueFromHexLiteral(0xFF1800B8);
 Controls.HardIcon:SetColor(blood); Controls.MadnessIcon:SetColor(blood);
 Controls.NormalButton:RegisterCallback(Mouse.eLClick,function() Submit("NORMAL"); end);
 Controls.HardButton:RegisterCallback(Mouse.eLClick,function() Submit("HARD"); end);
 Controls.MadnessButton:RegisterCallback(Mouse.eLClick,function() Submit("MADNESS"); end);
 Events.LocalPlayerTurnBegin.Add(Refresh);
 Events.GameCoreEventPublishComplete.Add(Refresh);
 Events.LoadGameViewStateDone.Add(Refresh);
 if Events.CityAddedToMap~=nil then Events.CityAddedToMap.Add(Refresh); end
 Refresh();
end

Initialize();
-- BEGIN RC342 STARTUP TRACE

end
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("LOTM_RESCUE_DifficultyChoice","CONTEXT END");
-- END RC342 STARTUP TRACE
