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
LOTM_StartupTrace.Mark("CityBannerManager_LOTM_RESCUE","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"CityBannerManager_LOTM_RESCUE","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"CityBannerManager_LOTM_RESCUE","GameEvents");
local LuaEvents = LOTM_StartupTrace.Events(LuaEvents,"CityBannerManager_LOTM_RESCUE","LuaEvents");
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
do
-- END RC342 STARTUP TRACE
-- Firaxis loads CityBannerManager_*.lua extensions from the wildcard include
-- at the end of the Gathering Storm CityBannerManager. Do not include the
-- base manager here; wrap its functions before its Initialize() call instead.

local SEAL_ZONES={"CENTER","FOOL","NIGHT","STORM"};
local SEAL_ICONS={
	CENTER="ICON_LOTM_RESCUE_ASTRAL_DESCENT",
	FOOL="ICON_LOTM_CHURCH_FOOL",
	NIGHT="ICON_LOTM_CHURCH_NIGHT",
	STORM="ICON_LOTM_CHURCH_STORM"
};
local SEAL_NAME_COLORS={
	FOOL=UI.GetColorValue("COLOR_LOTM_CHURCH_FOOL"),
	NIGHT=UI.GetColorValue("COLOR_LOTM_CHURCH_NIGHT"),
	STORM=UI.GetColorValue("COLOR_LOTM_CHURCH_STORM")
};
local ICON_WHITE=UI.GetColorValueFromHexLiteral(0xFFFFFFFF);
local NAME_SHADOW=UI.GetColorValueFromHexLiteral(0xFF202020);
local m_lastSealSignature=nil;

local function SealZone(pCity)
	if pCity==nil then return nil; end
	local sealPlayer=tonumber(Game.GetProperty("LOTM_RESCUE_TEST_PLAYER_ID") or -1);
	if pCity:GetOwner()~=sealPlayer then return nil; end
	for _,zone in ipairs(SEAL_ZONES) do
		local sealCity=tonumber(Game.GetProperty("LOTM_RESCUE_"..zone.."_CITY_ID") or -1);
		if pCity:GetID()==sealCity then return zone; end
	end
	return nil;
end

local function SetSealIcon(control,iconName)
	if control==nil or IconManager==nil or IconManager.FindIconAtlas==nil then return false; end
	local x,y,sheet=IconManager:FindIconAtlas(iconName,22);
	if sheet==nil or sheet=="" then
		print("[LOTM_RESCUE][CityBanner] icon atlas miss "..tostring(iconName).." size=22");
		return false;
	end
	control:SetTexture(x,y,sheet);
	control:SetColor(ICON_WHITE);
	return true;
end

local function ApplySealPresentation(self,pCity)
	local zone=SealZone(pCity);
	local iconName=zone~=nil and SEAL_ICONS[zone] or nil;
	if iconName==nil then return; end
	local tooltip=Locale.Lookup(pCity:GetName());
	local typeInstances=self.m_InfoIconIM~=nil and self.m_InfoIconIM.m_AllocatedInstances or nil;
	local typeInstance=typeInstances~=nil and typeInstances[1] or nil;
	if typeInstance~=nil and typeInstance.Icon~=nil then
		SetSealIcon(typeInstance.Icon,iconName);
		typeInstance.Button:SetToolTipString(tooltip);
	end
	if self.m_CivIconInstance~=nil and self.m_CivIconInstance.Icon~=nil then
		SetSealIcon(self.m_CivIconInstance.Icon,iconName);
		self.m_CivIconInstance.Button:SetToolTipString(tooltip);
	end
	local nameColor=SEAL_NAME_COLORS[zone];
	if nameColor~=nil and self.m_Instance~=nil and self.m_Instance.CityName~=nil then
		self.m_Instance.CityName:SetColor(nameColor,0);
		self.m_Instance.CityName:SetColor(NAME_SHADOW,1);
	end
end

local BASE_LOTM_UpdateInfo=CityBanner.UpdateInfo;
function CityBanner.UpdateInfo(self,pCity:table)
	BASE_LOTM_UpdateInfo(self,pCity);
	ApplySealPresentation(self,pCity);
end

local BASE_LOTM_UpdateColor=CityBanner.UpdateColor;
function CityBanner.UpdateColor(self)
	BASE_LOTM_UpdateColor(self);
	ApplySealPresentation(self,self:GetCity());
end

local BASE_LOTM_UpdatePopulation=CityBanner.UpdatePopulation;
function CityBanner.UpdatePopulation(self,isLocalPlayer:boolean,pCity:table,pCityGrowth:table)
	BASE_LOTM_UpdatePopulation(self,isLocalPlayer,pCity,pCityGrowth);
	if SealZone(pCity)~=nil then
		local instances=self.m_StatPopulationIM~=nil and self.m_StatPopulationIM.m_AllocatedInstances or nil;
		local populationInstance=instances~=nil and instances[1] or nil;
		if populationInstance~=nil and populationInstance.CityPopulation~=nil then
			populationInstance.CityPopulation:SetText("?");
		end
	end
end

local function RefreshSealBanners(force)
	local playerID=tonumber(Game.GetProperty("LOTM_RESCUE_TEST_PLAYER_ID") or -1);
	if playerID<0 then return false; end
	local cityIDs={};
	for _,zone in ipairs(SEAL_ZONES) do
		local cityID=tonumber(Game.GetProperty("LOTM_RESCUE_"..zone.."_CITY_ID") or -1);
		if cityID<0 then return false; end
		table.insert(cityIDs,cityID);
	end
	local signature=tostring(playerID)..":"..table.concat(cityIDs,",");
	if not force and signature==m_lastSealSignature then return true; end
	local refreshed=0;
	for _,cityID in ipairs(cityIDs) do
		if GetCityBanner(playerID,cityID)~=nil then
			RefreshBanner(playerID,cityID);
			refreshed=refreshed+1;
		end
	end
	if refreshed==#SEAL_ZONES then
		m_lastSealSignature=signature;
		print("[LOTM_RESCUE][CityBanner] refreshed seal presentations "..signature);
		return true;
	end
	return false;
end

local function OnSealPublishComplete()
	RefreshSealBanners(false);
end

local function OnSealLoadGameViewStateDone()
	m_lastSealSignature=nil;
	RefreshSealBanners(true);
end

local BASE_LOTM_Initialize=Initialize;
function Initialize()
	BASE_LOTM_Initialize();
	Events.GameCoreEventPublishComplete.Add(OnSealPublishComplete);
	Events.LoadGameViewStateDone.Add(OnSealLoadGameViewStateDone);
end
-- BEGIN RC342 STARTUP TRACE

end
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("CityBannerManager_LOTM_RESCUE","CONTEXT END");
-- END RC342 STARTUP TRACE
