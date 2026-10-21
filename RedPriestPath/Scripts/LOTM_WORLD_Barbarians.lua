-- Authoritative synchronized barbarian baselines shared by workshops and monsters.
LOTM_WORLD_Barbarians = LOTM_WORLD_Barbarians or {};
local RESCUE_CLEANUP_VERSION=2;
local RESCUE_CLEANUP_VERSION_KEY="LOTM_RESCUE_BARBARIAN_CLEANUP_VERSION";
local RESCUE_PENDING_UNITS_KEY="LOTM_RESCUE_NATIVE_PENDING_UNITS";

local MELEE_CHAIN={
	"UNIT_MECHANIZED_INFANTRY",
	"UNIT_INFANTRY",
	"UNIT_LINE_INFANTRY",
	"UNIT_MUSKETMAN",
	"UNIT_MAN_AT_ARMS",
	"UNIT_SWORDSMAN",
	"UNIT_WARRIOR",
};

local function Log(message)
	print("[LOTM_WORLD][Barbarians] "..tostring(message));
end

local function HasPrerequisite(player,unitInfo)
	if unitInfo==nil then return false; end
	if unitInfo.PrereqTech==nil then return true; end
	local techInfo=GameInfo.Technologies[unitInfo.PrereqTech];
	local techs=player~=nil and player:GetTechs() or nil;
	return techInfo~=nil and techs~=nil and techs:HasTech(techInfo.Index);
end

function LOTM_WORLD_Barbarians.ResolveMeleeBaseline(barbarianID)
	local player=barbarianID~=nil and Players[barbarianID] or nil;
	for _,unitType in ipairs(MELEE_CHAIN) do
		local info=GameInfo.Units[unitType];
		if info~=nil and HasPrerequisite(player,info) then
			return {UnitType=unitType,Index=info.Index,Combat=tonumber(info.Combat) or 20,BaseMoves=tonumber(info.BaseMoves) or 2};
		end
	end
	local warrior=GameInfo.Units.UNIT_WARRIOR;
	if warrior~=nil then
		return {UnitType="UNIT_WARRIOR",Index=warrior.Index,Combat=tonumber(warrior.Combat) or 20,BaseMoves=tonumber(warrior.BaseMoves) or 2};
	end
	Log("unable to resolve canonical melee baseline");
	return nil;
end

local function RescueActive()
 if LOTM_MP_TurnSync~=nil and type(LOTM_MP_TurnSync.IsRescueModeConfigured)=="function"
  and LOTM_MP_TurnSync.IsRescueModeConfigured() then return true; end
 return tonumber(Game.GetProperty("LOTM_RESCUE_MODE") or 0)==1;
end

-- A newly restored unit can publish its engine identity before its local
-- Property view. Preserve committed monsters and legacy camp guardians as
-- well as the final-battle types; a native Warrior type alone is not evidence
-- that a unit is an ordinary barbarian.
function LOTM_WORLD_Barbarians.IsProtectedRescueUnit(unit)
 if unit==nil then return false; end
 if (tonumber(unit:GetProperty("LOTM_WORLD_MONSTER_SERIAL") or 0) or 0)>0
  or (tonumber(unit:GetProperty("LOTM_RESCUE_CENTER_MONSTER") or 0) or 0)==1
  or (tonumber(unit:GetProperty("LOTM_PP_WORKSHOP_SEQUENCE") or 0) or 0)==1
  or unit:GetProperty("LOTM_RESCUE_PHASE10_ROLE")~=nil then return true,"UNIT"; end
 for _,unitType in ipairs({"UNIT_LOTM_RESCUE_LOST_CONTROL_LOW","UNIT_LOTM_RESCUE_LOST_CONTROL_MID",
  "UNIT_LOTM_RESCUE_LOST_CONTROL_HIGH","UNIT_LOTM_RESCUE_OUTER_GOD_AVATAR","UNIT_LOTM_RESCUE_OUTER_GOD_MINION"}) do
  local info=GameInfo.Units[unitType];
  if info~=nil and unit:GetType()==info.Index then return true,"TYPE"; end
 end
 local owner=unit:GetOwner(); local id=unit:GetID();
 local serial=tonumber(Game.GetProperty("LOTM_WORLD_MONSTER_ENGINE:"..owner..":"..id) or 0) or 0;
 if serial<=0 then return false; end
 local prefix="LOTM_WORLD_MONSTER:"..serial..":";
 local durable=tonumber(Game.GetProperty(prefix.."LIVE") or 0)==1
  and tonumber(Game.GetProperty(prefix.."OWNER") or -1)==owner
  and tonumber(Game.GetProperty(prefix.."UNIT_ID") or -1)==id;
 return durable,durable and "DURABLE" or nil;
end

local function CreationInProgress()
 return (LOTM_WORLD_Monsters~=nil and type(LOTM_WORLD_Monsters.IsCreating)=="function" and LOTM_WORLD_Monsters.IsCreating())
  or (LOTM_RESCUE_Phase10~=nil and type(LOTM_RESCUE_Phase10.IsCreating)=="function" and LOTM_RESCUE_Phase10.IsCreating());
end

local function RemoveNormalUnit(unit)
 if LOTM_WORLD_Barbarians.IsProtectedRescueUnit(unit) then return 0,true; end
 local owner=unit:GetOwner(); local id=unit:GetID();
 local ok=pcall(UnitManager.Kill,unit);
 local lookupOK,remaining=pcall(UnitManager.GetUnit,owner,id);
 -- Kill may fail without throwing. Only a confirmed removal counts as a
 -- completed migration, so a failed native operation can be retried safely.
 return lookupOK and remaining==nil and 1 or 0,ok and lookupOK and remaining==nil;
end

function LOTM_WORLD_Barbarians.CleanupRescueUnits()
 if not RescueActive() or tonumber(Game.GetProperty(RESCUE_CLEANUP_VERSION_KEY) or 0)>=RESCUE_CLEANUP_VERSION then return 0; end
 if CreationInProgress() or PlayerManager==nil or type(PlayerManager.GetAliveBarbarians)~="function"
  or UnitManager==nil or type(UnitManager.Kill)~="function" or type(UnitManager.GetUnit)~="function" then return 0; end
 local rosterOK,barbarians=pcall(PlayerManager.GetAliveBarbarians);
 if not rosterOK or type(barbarians)~="table" then return 0; end
 local ordered={}; for _,player in ipairs(barbarians) do ordered[#ordered+1]=player; end
 if #ordered==0 then return 0; end
 table.sort(ordered,function(a,b) return a:GetID()<b:GetID(); end);
 -- Capture the complete roster before mutating it. An unavailable collection
 -- must not permanently consume this one-time old-save repair.
 local collected,pending=pcall(function()
  local all={};
  for _,player in ipairs(ordered) do
   local units=player:GetUnits(); if units==nil then error("UNIT_COLLECTION_UNAVAILABLE"); end
   for _,unit in units:Members() do all[#all+1]=unit; end
  end
  table.sort(all,function(a,b) if a:GetOwner()~=b:GetOwner() then return a:GetOwner()<b:GetOwner(); end return a:GetID()<b:GetID(); end);
  return all;
 end);
 if not collected then Log("rescue cleanup pending version="..RESCUE_CLEANUP_VERSION.." reason=UNIT_COLLECTION_UNAVAILABLE"); return 0; end
 local removed=0; local failed=0;
 for _,unit in ipairs(pending) do
  local called,count,complete=pcall(RemoveNormalUnit,unit);
  if called then removed=removed+count; end
  if not called or not complete then failed=failed+1; end
 end
 if failed==0 then Game.SetProperty(RESCUE_CLEANUP_VERSION_KEY,RESCUE_CLEANUP_VERSION); end
 Log("rescue cleanup version="..RESCUE_CLEANUP_VERSION.." inspected="..#pending.." removed="..removed.." failed="..failed.." complete="..tostring(failed==0));
 return removed;
end

-- This helper is called only by Phase5's synchronized camp creator after its
-- native CreateTribeUnits call. Inspect that camp's fixed seven-hex vicinity,
-- never the map or all units, to remove our own temporary native defenders.
function LOTM_WORLD_Barbarians.CleanupRescueCampUnits(camp)
 if camp==nil or not RescueActive() or CreationInProgress() then return 0; end
 if Units==nil or type(Units.GetUnitsInPlot)~="function" or Map==nil or type(Map.GetAdjacentPlot)~="function"
  or PlayerManager==nil or type(PlayerManager.GetAliveBarbarians)~="function"
  or UnitManager==nil or type(UnitManager.Kill)~="function" or type(UnitManager.GetUnit)~="function" then return 0; end
 local barbarians={}; for _,player in ipairs(PlayerManager.GetAliveBarbarians() or {}) do barbarians[player:GetID()]=true; end
 local plots={camp};
 for direction=0,5 do local plot=Map.GetAdjacentPlot(camp:GetX(),camp:GetY(),direction); if plot~=nil then plots[#plots+1]=plot; end end
 local pending={}; local seen={};
 for _,plot in ipairs(plots) do
  for _,unit in ipairs(Units.GetUnitsInPlot(plot) or {}) do
   local key=unit:GetOwner()..":"..unit:GetID();
   if barbarians[unit:GetOwner()] and not seen[key] then seen[key]=true; pending[#pending+1]=unit; end
  end
 end
 table.sort(pending,function(a,b) if a:GetOwner()~=b:GetOwner() then return a:GetOwner()<b:GetOwner(); end return a:GetID()<b:GetID(); end);
 local candidates={}; for _,unit in ipairs(pending) do candidates[#candidates+1]={Owner=unit:GetOwner(),Unit=unit:GetID()}; end
 local _,removed=LOTM_WORLD_Barbarians.ProcessRescueUnitCandidates(candidates);
 return removed or 0;
end

-- Called by the existing synchronized workshop boundary, never by a local
-- UnitAdded/Removed publication. Rescue suppression concerns the currently
-- live unit, not the old spawn generation used by ordinary workshop rewards.
-- Persist only the bounded candidate IDs so failed native kills survive a
-- save/reload and can retry without scanning all units again.
function LOTM_WORLD_Barbarians.ProcessRescueUnitCandidates(candidates)
 if not RescueActive() or CreationInProgress() then return false; end
 if PlayerManager==nil or type(PlayerManager.GetAliveBarbarians)~="function"
  or UnitManager==nil or type(UnitManager.GetUnit)~="function" or type(UnitManager.Kill)~="function" then return false; end
 local rosterOK,roster=pcall(PlayerManager.GetAliveBarbarians);
 if not rosterOK or type(roster)~="table" or #roster==0 then return false; end
 local barbarians={}; for _,player in ipairs(roster) do barbarians[player:GetID()]=true; end
 local keys={}; local seen={};
 local function Add(owner,id)
  owner=tonumber(owner); id=tonumber(id);
  if owner==nil or id==nil or owner<0 or id<0 or owner~=math.floor(owner) or id~=math.floor(id) or not barbarians[owner] then return; end
  local key=owner..":"..id;
  if not seen[key] then seen[key]={Owner=owner,Unit=id}; keys[#keys+1]=key; end
 end
 for owner,id in string.gmatch(tostring(Game.GetProperty(RESCUE_PENDING_UNITS_KEY) or ""),"(%d+):(%d+)") do Add(owner,id); end
 for _,candidate in ipairs(candidates or {}) do Add(candidate.Owner,candidate.Unit); end
 if #keys==0 then return true; end
 table.sort(keys,function(a,b)
  local x=seen[a]; local y=seen[b]; if x.Owner~=y.Owner then return x.Owner<y.Owner; end return x.Unit<y.Unit;
 end);
 -- Commit before native mutation, so a reload after a partial native failure
 -- retains every not-yet-confirmed ID. The next pass rechecks live identity.
 Game.SetProperty(RESCUE_PENDING_UNITS_KEY,table.concat(keys,","));
 local pending={}; local removed=0;
 for _,key in ipairs(keys) do
  local entry=seen[key];
  local ok,count,complete=pcall(function()
   local unit=UnitManager.GetUnit(entry.Owner,entry.Unit);
   if unit==nil then return 0,true; end
   local protected,kind=LOTM_WORLD_Barbarians.IsProtectedRescueUnit(unit);
   -- A durable index may be awaiting restored unit properties or removal
   -- reconciliation. Keep this one ID pending until the unit confirms its
   -- own identity, so a stale index cannot exempt an ordinary unit forever.
   if protected and kind=="DURABLE" then return 0,false; end
   return RemoveNormalUnit(unit);
  end);
  if ok then removed=removed+count; end
  if not ok or not complete then pending[#pending+1]=key; end
 end
 Game.SetProperty(RESCUE_PENDING_UNITS_KEY,#pending>0 and table.concat(pending,",") or nil);
 Log("rescue native suppression checked="..#keys.." removed="..removed.." pending="..#pending);
 return true,removed;
end

Log("initialized canonical melee chain=Warrior..Mechanized Infantry");
