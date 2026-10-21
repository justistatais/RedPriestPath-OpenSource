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
LOTM_StartupTrace.Mark("LOTM_PP_ArtifactShowcase","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"LOTM_PP_ArtifactShowcase","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"LOTM_PP_ArtifactShowcase","GameEvents");
local LuaEvents = LOTM_StartupTrace.Events(LuaEvents,"LOTM_PP_ArtifactShowcase","LuaEvents");
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
do
-- END RC342 STARTUP TRACE
-- Independent sealed-artifact reveal. It copies the Firaxis GreatWorkShowcase
-- presentation but never replaces that context and never creates a GreatWork.

local m_seenSerial :number = -1;

local DATA :table = {
 GREATWORK_LOTM_PP_GOLDEN_APPRAISAL_MIRROR={path="PP",level=2,pos="LOC_LOTM_PP_SHOWCASE_GOLDEN_POSITIVE",neg="LOC_LOTM_PP_SHOWCASE_GOLDEN_NEGATIVE"},
 GREATWORK_LOTM_PP_PERPETUAL_GEARBOX={path="PP",level=2,pos="LOC_LOTM_PP_SHOWCASE_GEARBOX_POSITIVE",neg="LOC_LOTM_PP_SHOWCASE_GEARBOX_NEGATIVE"},
 GREATWORK_LOTM_PP_ERROR_ASTROLABE={path="PP",level=2,pos="LOC_LOTM_PP_SHOWCASE_ASTROLABE_POSITIVE",neg="LOC_LOTM_PP_SHOWCASE_ASTROLABE_NEGATIVE"},
 GREATWORK_LOTM_PP_HERMES_FURNACE={path="PP",level=1,pos="LOC_LOTM_PP_SHOWCASE_FURNACE_POSITIVE",neg="LOC_LOTM_PP_SHOWCASE_FURNACE_NEGATIVE"},
 GREATWORK_LOTM_PP_MYSTERY_BLUEPRINT={path="PP",level=1,pos="LOC_LOTM_PP_SHOWCASE_BLUEPRINT_POSITIVE",neg="LOC_LOTM_PP_SHOWCASE_BLUEPRINT_NEGATIVE"},
 GREATWORK_LOTM_PP_KNOWLEDGE_CASKET={path="PP",level=0,pos="LOC_LOTM_PP_SHOWCASE_CASKET_POSITIVE",neg="LOC_LOTM_PP_SHOWCASE_CASKET_NEGATIVE"},
 GREATWORK_LOTM_PP_CIVILIZATION_STELE={path="PP",level=0,pos="LOC_LOTM_PP_SHOWCASE_STELE_POSITIVE",neg="LOC_LOTM_PP_SHOWCASE_STELE_NEGATIVE"},
 GREATWORK_LOTM_RP_DISASTER_EMBER={path="RP",level=2,fx="LOC_LOTM_ARTIFACT_SHOWCASE_RP_EMBER_EFFECT",rescueFx="LOC_LOTM_RESCUE_ARTIFACT_RP_EMBER_EFFECT"},
 GREATWORK_LOTM_RP_CONSPIRATOR_LETTER={path="RP",level=2,fx="LOC_LOTM_ARTIFACT_SHOWCASE_RP_LETTER_EFFECT",rescueFx="LOC_LOTM_RESCUE_ARTIFACT_RP_LETTER_EFFECT"},
 GREATWORK_LOTM_RP_BLOOD_HARVEST_SICKLE={path="RP",level=2,fx="LOC_LOTM_ARTIFACT_SHOWCASE_RP_SICKLE_EFFECT"},
 GREATWORK_LOTM_RP_IRONBLOOD_BANNER={path="RP",level=1,fx="LOC_LOTM_ARTIFACT_SHOWCASE_RP_BANNER_EFFECT",rescueFx="LOC_LOTM_RESCUE_ARTIFACT_RP_BANNER_EFFECT"},
 GREATWORK_LOTM_RP_WAR_SCRIPTURE={path="RP",level=1,fx="LOC_LOTM_ARTIFACT_SHOWCASE_RP_SCRIPTURE_EFFECT",rescueFx="LOC_LOTM_RESCUE_ARTIFACT_RP_SCRIPTURE_EFFECT"},
 GREATWORK_LOTM_RP_DISASTER_WEATHER={path="RP",level=0,fx="LOC_LOTM_ARTIFACT_SHOWCASE_RP_WEATHER_EFFECT",rescueFx="LOC_LOTM_RESCUE_ARTIFACT_RP_WEATHER_EFFECT"},
 GREATWORK_LOTM_RP_CONQUEROR_CROWN={path="RP",level=0,fx="LOC_LOTM_ARTIFACT_SHOWCASE_RP_CROWN_EFFECT",rescueFx="LOC_LOTM_RESCUE_ARTIFACT_RP_CROWN_EFFECT"},
 GREATWORK_LOTM_BE_GOLDEN_BRIBE={path="BE",level=2,fx="LOC_LOTM_ARTIFACT_SHOWCASE_BE_BRIBE_EFFECT"},
 GREATWORK_LOTM_BE_CORRUPTION_TAXBOOK={path="BE",level=2,fx="LOC_LOTM_ARTIFACT_SHOWCASE_BE_TAX_EFFECT"},
 GREATWORK_LOTM_BE_CHAOS_CODEX={path="BE",level=2,fx="LOC_LOTM_ARTIFACT_SHOWCASE_BE_CODEX_EFFECT"},
 GREATWORK_LOTM_BE_DEPRAVED_FEAST={path="BE",level=1,fx="LOC_LOTM_ARTIFACT_SHOWCASE_BE_FEAST_EFFECT"},
 GREATWORK_LOTM_BE_FRENZY_SCEPTER={path="BE",level=1,fx="LOC_LOTM_ARTIFACT_SHOWCASE_BE_SCEPTER_EFFECT",rescueFx="LOC_LOTM_RESCUE_ARTIFACT_BE_SCEPTER_EFFECT"},
 GREATWORK_LOTM_BE_ENTROPY_CROWN={path="BE",level=0,fx="LOC_LOTM_ARTIFACT_SHOWCASE_BE_ENTROPY_EFFECT"},
 GREATWORK_LOTM_BE_ORDER_CONVERTER={path="BE",level=0,fx="LOC_LOTM_ARTIFACT_SHOWCASE_BE_ORDER_EFFECT"}
};
local PATH_TEXT :table = {PP="LOC_LOTM_ARTIFACT_TAB_PERFECT",RP="LOC_LOTM_ARTIFACT_TAB_RED_PRIEST",BE="LOC_LOTM_ARTIFACT_TAB_BLACK_EMPEROR"};

local function LocalPlayer()
 local id=Game.GetLocalPlayer(); local p=id~=nil and id>=0 and Players[id] or nil;
 if p==nil or not p:IsHuman() or not p:IsMajor() then return nil; end return p;
end

local function SetIcon(control,iconName,size)
 local x,y,sheet=IconManager:FindIconAtlas(iconName,size);
 if sheet==nil or sheet=="" then print("[LOTM_PP][ArtifactShowcase] ICON MISS "..tostring(iconName)); return false; end
 control:SetTexture(x,y,sheet); return true;
end

local function Hide()
 ContextPtr:SetHide(true);
end

local function Show(artifactType)
 local data=DATA[artifactType]; local row=GameInfo.GreatWorks[artifactType]; if data==nil or row==nil then return; end
 Controls.GreatWorkHeader:SetText(Locale.Lookup("LOC_LOTM_PP_ARTIFACT_SHOWCASE_HEADER"));
 Controls.GreatWorkName:SetText(Locale.ToUpper(Locale.Lookup(row.Name)));
 Controls.ArtifactMeta:SetText(Locale.Lookup("LOC_LOTM_PP_ARTIFACT_SHOWCASE_META_ALL",data.level,Locale.Lookup(PATH_TEXT[data.path])));
 local rescue=tonumber(Game.GetProperty("LOTM_RESCUE_MODE") or 0)==1;
 local effectTag=rescue and data.rescueFx or data.fx;
 local effect=effectTag~=nil and Locale.Lookup(effectTag) or (Locale.Lookup("LOC_LOTM_PP_ARTIFACT_SHOWCASE_POSITIVE",Locale.Lookup(data.pos)).."[NEWLINE]"..Locale.Lookup("LOC_LOTM_PP_ARTIFACT_SHOWCASE_NEGATIVE",Locale.Lookup(data.neg)));
 Controls.ArtifactEffect:SetText(effect); SetIcon(Controls.GreatWorkImage,"ICON_"..artifactType,256);
 ContextPtr:SetHide(false); UI.PlaySound("UI_GreatWorks_Pick_Up");
end

local function Check()
 if not ContextPtr:IsHidden() then return; end
 local p=LocalPlayer(); if p==nil then return; end
 local serial=p:GetProperty("LOTM_PP_ARTIFACT_SHOWCASE_SERIAL");
 if serial==nil or tonumber(serial)==nil or tonumber(serial)<=m_seenSerial then return; end
 if tonumber(p:GetProperty("LOTM_PP_ARTIFACT_SHOWCASE_TURN") or -1)~=Game.GetCurrentGameTurn() then m_seenSerial=tonumber(serial); return; end
 m_seenSerial=tonumber(serial); Show(p:GetProperty("LOTM_PP_ARTIFACT_SHOWCASE_TYPE"));
end

local function Initialize()
 ContextPtr:SetHide(true); ContextPtr:SetInputHandler(function(input) if input:GetMessageType()==KeyEvents.KeyUp and input:GetKey()==Keys.VK_ESCAPE then Hide(); return true; end return false; end,true);
 Controls.CloseButton:RegisterCallback(Mouse.eLClick,Hide);
 Controls.ViewArtifacts:RegisterCallback(Mouse.eLClick,function() Hide(); LuaEvents.LOTM_PP_OpenArtifacts(); end);
 Events.GameCoreEventPublishComplete.Add(Check); Events.LocalPlayerTurnBegin.Add(Check); Events.LoadGameViewStateDone.Add(Check);
end
Initialize();
-- BEGIN RC342 STARTUP TRACE

end
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("LOTM_PP_ArtifactShowcase","CONTEXT END");
-- END RC342 STARTUP TRACE
