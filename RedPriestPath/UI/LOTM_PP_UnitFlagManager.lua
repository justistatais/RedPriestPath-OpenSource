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
LOTM_StartupTrace.Mark("LOTM_PP_UnitFlagManager","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"LOTM_PP_UnitFlagManager","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"LOTM_PP_UnitFlagManager","GameEvents");
local LuaEvents = LOTM_StartupTrace.Events(LuaEvents,"LOTM_PP_UnitFlagManager","LuaEvents");
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
do
-- END RC342 STARTUP TRACE
include("UnitFlagManager");

local BASE_SetColor=UnitFlag.SetColor;
local BASE_SetFlagUnitEmblem=UnitFlag.SetFlagUnitEmblem;
-- Multiplayer keeps the existing delayed-property queue.  Single-player
-- retains Firaxis timing for ordinary units and retries only sequence holders,
-- whose gameplay marker can arrive one event after UnitAddedToMap.
local IS_NETWORK_MULTIPLAYER=GameConfiguration~=nil and GameConfiguration.IsAnyMultiplayer~=nil and GameConfiguration.IsAnyMultiplayer() or false;
local WORKSHOP_BASE=UI.GetColorValueFromHexLiteral(0xFF1678A9); -- #A97816 RGB
local WORKSHOP_GOLD=UI.GetColorValueFromHexLiteral(0xFF00D7FF); -- #FFD700 RGB
local MONSTER_BASE=UI.GetColorValueFromHexLiteral(0xFF000000); -- #000000 RGB
local MONSTER_MARK=UI.GetColorValueFromHexLiteral(0xFFFFFFFF); -- #FFFFFF RGB
local OUTER_GOD_MARK=UI.GetColorValueFromHexLiteral(0xFF1800B8); -- #B80018 RGB
local PATH_MARKS={
 RP="ICON_LOTM_RP_RED_PRIEST_MARK",
 PP="ICON_LOTM_PP_PERFECT_MARK",
 BE="ICON_LOTM_BE_BLACK_EMPEROR_MARK",
 TP="ICON_LOTM_TP_THIEF_MARK"
};
local HOLDER_PATHS={};
for path,unitType in pairs({
 RP="UNIT_LOTM_RP_PATH_HOLDER",
 PP="UNIT_LOTM_PP_PATH_HOLDER",
 BE="UNIT_LOTM_BE_PATH_HOLDER",
 TP="UNIT_LOTM_TP_PATH_HOLDER",
 TP_WORM="UNIT_LOTM_RESCUE_TIME_WORM"
}) do
 local info=GameInfo.Units[unitType];
 if info~=nil then HOLDER_PATHS[info.Index]=path; end
end
local GUARDIAN_ICONS={};
for church in pairs({FOOL=true,NIGHT=true,STORM=true}) do
 for _,tier in ipairs({"SAINT","ANGEL"}) do
  local unitType="UNIT_LOTM_RESCUE_"..church.."_"..tier;
  local info=GameInfo.Units[unitType];
  if info~=nil then GUARDIAN_ICONS[info.Index]="ICON_"..unitType; end
 end
 local godType="UNIT_LOTM_RESCUE_GOD_"..church;
 local godInfo=GameInfo.Units[godType];
 if godInfo~=nil then GUARDIAN_ICONS[godInfo.Index]="ICON_"..godType; end
end
local LOST_CONTROL_TYPES={};
for _,unitType in ipairs({"UNIT_LOTM_RESCUE_LOST_CONTROL_LOW","UNIT_LOTM_RESCUE_LOST_CONTROL_MID","UNIT_LOTM_RESCUE_LOST_CONTROL_HIGH"}) do
 local info=GameInfo.Units[unitType]; if info~=nil then LOST_CONTROL_TYPES[info.Index]=true; end
end
local OUTER_GOD_TYPES={};
local OUTER_GOD_AVATAR_TYPE=-1;
for _,unitType in ipairs({"UNIT_LOTM_RESCUE_OUTER_GOD_AVATAR","UNIT_LOTM_RESCUE_OUTER_GOD_MINION"}) do
 local info=GameInfo.Units[unitType]; if info~=nil then OUTER_GOD_TYPES[info.Index]=true; end
 if unitType=="UNIT_LOTM_RESCUE_OUTER_GOD_AVATAR" and info~=nil then OUTER_GOD_AVATAR_TYPE=info.Index; end
end

local function IsWorkshopSequence(unit)
 if unit==nil then return false; end
 local value=unit:GetProperty("LOTM_PP_WORKSHOP_SEQUENCE");
 return value~=nil and tonumber(value)==1;
end
local function IsMonster(unit)
 if unit==nil then return false; end
	if OUTER_GOD_TYPES[unit:GetType()]==true then return true; end
	local centerValue=unit:GetProperty("LOTM_RESCUE_CENTER_MONSTER");
	if centerValue~=nil and tonumber(centerValue)==1 then return true; end
 -- Civ VI may return zero Lua values for a missing Property.  Always capture
 -- first; never pass GetProperty() directly into tonumber().
 local tierValue=unit:GetProperty("LOTM_WORLD_MONSTER_TIER");
 if tierValue==nil then return false; end
 local serialValue=unit:GetProperty("LOTM_WORLD_MONSTER_SERIAL");
 return serialValue~=nil and tonumber(tierValue)~=nil
  and (tonumber(serialValue) or 0)>0;
end
local function IsLostControl(unit)
 return unit~=nil and LOST_CONTROL_TYPES[unit:GetType()]==true;
end
local function IsOuterGod(unit)
 return unit~=nil and OUTER_GOD_TYPES[unit:GetType()]==true;
end
local function IsOuterGodAvatar(unit)
 return unit~=nil and unit:GetType()==OUTER_GOD_AVATAR_TYPE;
end
local function IsFleshPuppet(unit)
 return unit~=nil and unit:GetProperty("LOTM_CULT_SOURCE_CULT")=="HANGED_MAN";
end
local function GuardianIcon(unit)
 return unit~=nil and GUARDIAN_ICONS[unit:GetType()] or nil;
end
local function PathHolderPath(unit)
 if unit==nil then return nil; end
 local path=HOLDER_PATHS[unit:GetType()];
 if path==nil then return nil; end
 -- The player property is authoritative after a path choice.  Keep the
 -- type-derived value as a deterministic fallback during the one-event
 -- window in which UnitAddedToMap can precede property publication.
 local owner=unit:GetOwner(); local player=owner~=nil and Players[owner] or nil;
 local selected=player~=nil and player:GetProperty("LOTM_RP_PATH") or nil;
 local selectedPath=selected=="PATH_RED_PRIEST" and "RP"
  or (selected=="PATH_PERFECT" and "PP"
  or (selected=="PATH_BLACK_EMPEROR" and "BE"
  or (selected=="PATH_THIEF" and "TP" or nil)));
 return selectedPath or path;
end
local function WorkshopPath(unit)
 if not IsWorkshopSequence(unit) then return nil; end
 local value=unit:GetProperty("LOTM_PP_WORKSHOP_PATH");
 return PATH_MARKS[value]~=nil and value or "PP";
end
local function ApplyMonsterColor(instance)
 instance.FlagBase:SetColor(MONSTER_BASE); instance.HealthBarBG:SetColor(MONSTER_BASE);
 instance.UnitIcon:SetColor(MONSTER_MARK); instance.FlagMouseOut:SetColor(MONSTER_MARK);
 instance.FlagMouseOver:SetColor(MONSTER_MARK);
end
local function ApplyOuterGodColor(instance)
 instance.FlagBase:SetColor(MONSTER_BASE); instance.HealthBarBG:SetColor(MONSTER_BASE);
 instance.UnitIcon:SetColor(OUTER_GOD_MARK); instance.FlagMouseOut:SetColor(OUTER_GOD_MARK);
 instance.FlagMouseOver:SetColor(OUTER_GOD_MARK);
end
local function ApplyPathColor(instance)
 instance.FlagBase:SetColor(WORKSHOP_BASE); instance.HealthBarBG:SetColor(WORKSHOP_BASE);
 instance.UnitIcon:SetColor(WORKSHOP_GOLD); instance.FlagMouseOut:SetColor(WORKSHOP_GOLD);
 instance.FlagMouseOver:SetColor(WORKSHOP_GOLD);
end
function UnitFlag.SetColor(self)
 local unit=self:GetUnit();
 if IsOuterGod(unit) then
  BASE_SetColor(self); ApplyOuterGodColor(self.m_Instance); return;
 end
 if IsMonster(unit) or IsLostControl(unit) then
  BASE_SetColor(self); ApplyMonsterColor(self.m_Instance); return;
 end
 if IsWorkshopSequence(unit) then
  BASE_SetColor(self); ApplyPathColor(self.m_Instance); return;
 end
 if GuardianIcon(unit)~=nil then
  -- Preserve the church color baked into the dedicated guardian DDS instead
  -- of multiplying it by the shared Free Cities secondary color.
  BASE_SetColor(self); self.m_Instance.UnitIcon:SetColor(MONSTER_MARK); return;
 end
 -- Flesh Puppets deliberately retain the owner's unmodified Firaxis
 -- civilization colors; only SetFlagUnitEmblem changes their mark.
 -- Exact Firaxis fallback: normal units touch no custom flag controls.
 BASE_SetColor(self);
end
function UnitFlag.SetFlagUnitEmblem(self)
 local unit=self:GetUnit();
 if IsOuterGod(unit) then
  self.m_Instance.UnitIcon:SetIcon(IsOuterGodAvatar(unit) and "ICON_LOTM_RESCUE_OUTER_GOD_STAR_MARK" or "ICON_LOTM_WORLD_MONSTER_MARK"); return;
 end
 if IsMonster(unit) or IsLostControl(unit) then
  self.m_Instance.UnitIcon:SetIcon("ICON_LOTM_WORLD_MONSTER_MARK"); return;
 end
 if IsFleshPuppet(unit) then
  self.m_Instance.UnitIcon:SetIcon("ICON_LOTM_CULT_FLESH_PUPPET"); return;
 end
 local guardianIcon=GuardianIcon(unit);
 if guardianIcon~=nil then
   self.m_Instance.UnitIcon:SetIcon(guardianIcon); return;
 end
 local holderPath=PathHolderPath(unit);
 if holderPath~=nil then
  self.m_Instance.UnitIcon:SetIcon(PATH_MARKS[holderPath]); return;
 end
 local path=WorkshopPath(unit);
 if path~=nil then
  self.m_Instance.UnitIcon:SetIcon(PATH_MARKS[path]); return;
 end
 -- Public Civ VI UI mods use this cached-base fallback for every unit that is
 -- not their explicitly targeted special type.
 BASE_SetFlagUnitEmblem(self);
end

-- In a network game UnitAddedToMap can be published before the synchronized
-- Unit properties arrive.  Keep those identifiers and retry after the game
-- core publish completes; this is incremental (only units seen in an event),
-- rather than a per-turn/full-map scan.
local pendingFlags={};
local function PendingKey(playerID,unitID) return tostring(playerID)..":"..tostring(unitID); end
local function QueueFlagRefresh(playerID,unitID)
 if playerID==nil or unitID==nil then return; end
 local key=PendingKey(playerID,unitID); local entry=pendingFlags[key];
 if entry==nil then pendingFlags[key]={playerID=playerID,unitID=unitID,tries=0}; end
end
-- A path-holder (the normal-mode sequence unit) can publish its gameplay
-- properties one UI event after UnitAddedToMap even in single-player.  Keep a
-- tiny event-scoped retry queue for that one type only; this does not scan the
-- map and does not alter the multiplayer queue below.
local singlePlayerPendingFlags={};
local function QueueSinglePlayerFlagRefresh(playerID,unitID)
 if playerID==nil or unitID==nil then return; end
 local key=PendingKey(playerID,unitID);
 if singlePlayerPendingFlags[key]==nil then singlePlayerPendingFlags[key]={playerID=playerID,unitID=unitID,tries=0}; end
end
local function RefreshSpecialFlag(playerID,unitID)
 if IS_NETWORK_MULTIPLAYER then QueueFlagRefresh(playerID,unitID); end
 local flag=GetUnitFlag(playerID,unitID);
 if flag==nil then return false; end
 local unit=flag:GetUnit();
 if unit==nil then return false; end
 if not IsMonster(unit) and not IsWorkshopSequence(unit) and not IsFleshPuppet(unit)
  and GuardianIcon(unit)==nil and PathHolderPath(unit)==nil then
  -- In multiplayer the unit can exist before its synchronized Properties.
  -- Keep it pending until the bounded publish retries expire.  This is the
  -- essential difference from resource 249; no Gameplay object is mutated.
  if IS_NETWORK_MULTIPLAYER then return false; end
   if HOLDER_PATHS[unit:GetType()]~=nil then
   QueueSinglePlayerFlagRefresh(playerID,unitID);
   return false;
  end
  return true;
 end
 flag:SetFlagUnitEmblem();
 flag:SetColor();
 if IS_NETWORK_MULTIPLAYER then pendingFlags[PendingKey(playerID,unitID)]=nil; end
 singlePlayerPendingFlags[PendingKey(playerID,unitID)]=nil;
 return true;
end
local function FlushPendingFlags()
 if not IS_NETWORK_MULTIPLAYER then return; end
 local retry={};
 for key,entry in pairs(pendingFlags) do
  entry.tries=(entry.tries or 0)+1;
  if not RefreshSpecialFlag(entry.playerID,entry.unitID) and entry.tries<6 then retry[key]=entry; end
 end
 pendingFlags=retry;
end
local function FlushSinglePlayerPendingFlags()
 if IS_NETWORK_MULTIPLAYER then return; end
 local retry={};
 for key,entry in pairs(singlePlayerPendingFlags) do
  entry.tries=(entry.tries or 0)+1;
  if not RefreshSpecialFlag(entry.playerID,entry.unitID) and entry.tries<6 then retry[key]=entry; end
 end
 singlePlayerPendingFlags=retry;
end

-- InitUnit raises UnitAddedToMap before Gameplay can attach monster/workshop
-- properties. Ability gain, selection, and visibility are the first reliable
-- UI-side points at which those synchronized properties are available.
Events.UnitAbilityGained.Add(RefreshSpecialFlag);
Events.UnitAddedToMap.Add(RefreshSpecialFlag);
Events.UnitSelectionChanged.Add(function(playerID,unitID,hexI,hexJ,hexK,isSelected)
 if isSelected then RefreshSpecialFlag(playerID,unitID); end
end);
Events.UnitVisibilityChanged.Add(function(playerID,unitID)
 RefreshSpecialFlag(playerID,unitID);
end);
Events.GameCoreEventPublishComplete.Add(FlushPendingFlags);
Events.LoadGameViewStateDone.Add(FlushPendingFlags);
Events.LocalPlayerTurnBegin.Add(FlushPendingFlags);
Events.GameCoreEventPublishComplete.Add(FlushSinglePlayerPendingFlags);
Events.LoadGameViewStateDone.Add(FlushSinglePlayerPendingFlags);
Events.LocalPlayerTurnBegin.Add(FlushSinglePlayerPendingFlags);
-- BEGIN RC342 STARTUP TRACE

end
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("LOTM_PP_UnitFlagManager","CONTEXT END");
-- END RC342 STARTUP TRACE
