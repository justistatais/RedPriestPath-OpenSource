-- AUTO-GENERATED network main context loaded after the verbatim rc.241 rescue bootstrap.
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
LOTM_StartupTrace.Mark("MP.MainContext","CONTEXT BEGIN");
-- END RC342 STARTUP TRACE

local m_isNetworkGame = GameConfiguration ~= nil
	and GameConfiguration.IsAnyMultiplayer ~= nil
	and GameConfiguration.IsAnyMultiplayer();
if m_isNetworkGame then
	print("[LOTM][BundleRouter] route=NETWORK_RC241_PLUS_DELTAS phase2BeforeMain="
		.. tostring(Game.GetProperty("LOTM_RESCUE_PHASE2A_STATE") or "NOT_RESCUE"));
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

-- AUTO-GENERATED rc.241 multiplayer main context; do not edit.
-- Published rc.241 old-module graph SHA-256: AAA746709B5B557200550977FF8B428C80DFA8F4AAF510B590C848D581962C5B
-- Old modules come from rc.241; explicit module and rule-function allowlists use current sources.

LOTM_MP241_BUNDLE_LOADED = {};
local m_mp241Loaders = {};
local m_mp241State = {};

function LOTM_MP241_LoadBundledModule(moduleName)
	local state = m_mp241State[moduleName];
	if state == "LOADED" then return true; end
	if state == "LOADING" then error("[LOTM][MP241] cyclic module load: "..tostring(moduleName)); end
	local loader = m_mp241Loaders[moduleName];
	if type(loader) ~= "function" then error("[LOTM][MP241] missing module: "..tostring(moduleName)); end
	m_mp241State[moduleName] = "LOADING";
	LOTM_StartupTrace.Mark("MP.Bundle", "MODULE BEGIN", moduleName);
	local ok,details = pcall(loader);
	LOTM_StartupTrace.Mark("MP.Bundle", "MODULE RETURN", moduleName, ok);
	if not ok then
		m_mp241State[moduleName] = "FAILED";
		error("[LOTM][MP241] module="..tostring(moduleName).." failed: "..tostring(details));
	end
	m_mp241State[moduleName] = "LOADED";
	LOTM_MP241_BUNDLE_LOADED[moduleName] = true;
	print("[LOTM][MP241] loaded module="..tostring(moduleName));
	return true;
end

m_mp241Loaders["LOTM_AI_Cult_Hanged"] = function()
-- BEGIN RC241 MODULE: Scripts/LOTM_AI_Cult_Hanged.lua
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("MP.LOTM_AI_Cult_Hanged","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"MP.LOTM_AI_Cult_Hanged","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"MP.LOTM_AI_Cult_Hanged","GameEvents");
-- END RC342 STARTUP TRACE

-- Hanged Man flesh-puppet equivalent replacements. No unit is killed or
-- rebuilt: a newly created current-baseline melee unit keeps its model,
-- experience, promotions, formation and AI mission, while receiving a fixed
-- +10/+20 ability, synchronized properties, name and UI emblem.
LOTM_AI_Cult_Hanged = LOTM_AI_Cult_Hanged or {};

local ABILITY_10="ABILITY_LOTM_CULT_FLESH_PUPPET_10";
local ABILITY_20="ABILITY_LOTM_CULT_FLESH_PUPPET_20";
local SOURCE_PROPERTY="LOTM_CULT_SOURCE_CULT";
local TIER_PROPERTY="LOTM_CULT_TIER_AT_CREATE";
local BASELINE_PROPERTY="LOTM_CULT_BASELINE_MELEE_STRENGTH";

local function Log(message) print("[LOTM_CULT][Hanged] "..tostring(message)); end
local function Number(value,default) if value==nil then return default; end return tonumber(value) or default; end
local function RescueActive() return Number(Game.GetProperty("LOTM_RESCUE_MODE"),0)==1; end
local function IsFormalHuman(player)
 return player~=nil and LOTM_RP_State~=nil and LOTM_RP_State.IsAnyPathPlayer~=nil
  and LOTM_RP_State.IsAnyPathPlayer(player:GetID());
end
local function IsPuppet(unit) return unit~=nil and unit:GetProperty(SOURCE_PROPERTY)=="HANGED_MAN"; end

local function SetAbility(unit,abilityType,desired)
 local abilities=unit~=nil and unit:GetAbility() or nil; if abilities==nil then return; end
 local current=abilities:GetAbilityCount(abilityType) or 0; if current~=desired then abilities:ChangeAbilityCount(abilityType,desired-current); end
end
local function ApplyTier(unit,tier)
 if unit==nil or not IsPuppet(unit) then return; end
 SetAbility(unit,ABILITY_10,tier==2 and 1 or 0); SetAbility(unit,ABILITY_20,tier==3 and 1 or 0);
 unit:SetProperty("LOTM_CULT_FLESH_PUPPET_ACTIVE_TIER",tier);
 local experience=unit:GetExperience(); if experience~=nil then experience:SetVeteranName(Locale.Lookup("LOC_UNIT_LOTM_CULT_FLESH_PUPPET_NAME")); end
end

local function TryMarkNewUnit(playerID,unitID)
 if RescueActive() then return; end
 local player=Players[playerID]; if player==nil or player:IsHuman() or not player:IsAlive() or not player:IsMajor() then return; end
 if LOTM_AI_Cults.GetPlayerCult(playerID)~="HANGED_MAN" then return; end
 local tier=LOTM_AI_Cults.GetTier("HANGED_MAN"); if tier~=2 and tier~=3 then return; end
 local unit=UnitManager.GetUnit(playerID,unitID); if unit==nil or IsPuppet(unit) then return; end
 local baseline=LOTM_WORLD_Barbarians.ResolveMeleeBaseline(playerID); if baseline==nil or unit:GetType()~=baseline.Index then return; end
 unit:SetProperty(SOURCE_PROPERTY,"HANGED_MAN"); unit:SetProperty(TIER_PROPERTY,tier); unit:SetProperty(BASELINE_PROPERTY,baseline.Combat); unit:SetProperty("LOTM_CULT_BASELINE_MELEE_UNIT_TYPE",baseline.UnitType);
 ApplyTier(unit,tier); Log("marked player="..playerID.." unit="..unitID.." baseline="..baseline.UnitType..":"..baseline.Combat.." tier="..tier);
end

function LOTM_AI_Cult_Hanged.ReconcileAll()
 if RescueActive() then return; end
 local tier=LOTM_AI_Cults.GetTier("HANGED_MAN"); if tier~=2 and tier~=3 then return; end
 for _,player in ipairs(PlayerManager.GetAliveMajors()) do
  if not player:IsHuman() and LOTM_AI_Cults.GetPlayerCult(player:GetID())=="HANGED_MAN" then
   for _,unit in player:GetUnits():Members() do if IsPuppet(unit) then ApplyTier(unit,tier); end end
  end
 end
end

function LOTM_AI_Cult_Hanged.RetireForRescue()
 if not RescueActive() then return; end
 for _,player in ipairs(PlayerManager.GetAliveMajors()) do
  if not player:IsHuman() then for _,unit in player:GetUnits():Members() do if IsPuppet(unit) then
   SetAbility(unit,ABILITY_10,0); SetAbility(unit,ABILITY_20,0);
   unit:SetProperty(SOURCE_PROPERTY,nil); unit:SetProperty("LOTM_CULT_FLESH_PUPPET_ACTIVE_TIER",0);
  end end end
 end
end

local function SettleAttackFaith(attackerPlayerID,defenderPlayerID,defenderUnitID)
 if RescueActive() then return; end
 local defender=UnitManager.GetUnit(defenderPlayerID,defenderUnitID); if not IsPuppet(defender) then return; end
 local attacker=Players[attackerPlayerID]; if not IsFormalHuman(attacker) then return; end
 local tier=LOTM_AI_Cults.GetTier("HANGED_MAN"); if tier~=2 and tier~=3 then return; end
 local base=tier==2 and 10 or 20; local targetTier=LOTM_AI_Cults.GetTargetTier(attacker); local amount=math.floor(base*LOTM_AI_Cults.GetMultiplier(tier,targetTier)+0.000001); if amount<=0 then return; end
 local religion=attacker:GetReligion(); if religion==nil then return; end local balance=Number(religion:GetFaithBalance(),0); religion:ChangeFaithBalance(-math.min(balance,amount));
 attacker:SetProperty("LOTM_CULT_FLESH_PUPPET_LAST_ATTACK_TURN",Game.GetCurrentGameTurn()); attacker:SetProperty("LOTM_CULT_FLESH_PUPPET_LAST_ATTACK_TARGET",tostring(defenderPlayerID)..":"..tostring(defenderUnitID));
 Log("attack faith attacker="..attackerPlayerID.." defender="..defenderPlayerID..":"..defenderUnitID.." amount="..amount.." tier="..tier);
end

local function OnCombat(attackerPlayerID,attackerUnitID,defenderPlayerID,defenderUnitID)
 -- The combat event fires only for the active attacker. This includes unit and
 -- city ranged attacks; a puppet attacking the player has the arguments
 -- reversed and therefore never charges faith.
 SettleAttackFaith(attackerPlayerID,defenderPlayerID,defenderUnitID);
end

GameEvents.UnitInitialized.Add(TryMarkNewUnit);
GameEvents.OnCombatOccurred.Add(OnCombat);
LOTM_AI_Cult_Hanged.ReconcileAll();
Log("initialized equivalent replacement bonus=10/20");
-- END RC241 MODULE: Scripts/LOTM_AI_Cult_Hanged.lua
end;

m_mp241Loaders["LOTM_AI_Cults"] = function()
-- BEGIN RC241 MODULE: Scripts/LOTM_AI_Cults.lua
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("MP.LOTM_AI_Cults","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"MP.LOTM_AI_Cults","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"MP.LOTM_AI_Cults","GameEvents");
-- END RC342 STARTUP TRACE

-- Synchronized AI cult assignment, independent tiers, target scaling and
-- reversible continuous effects. UI reads these Properties but never writes.
LOTM_AI_Cults = LOTM_AI_Cults or {};

local CULTS={"DEMONESS","HANGED_MAN","CHAINED"};
local TIER_KEYS={
 DEMONESS="LOTM_CULT_DEMONESS_TIER",
 HANGED_MAN="LOTM_CULT_HANGED_MAN_TIER",
 CHAINED="LOTM_CULT_CHAINED_TIER"
};
local MAX_KEYS={
 DEMONESS="LOTM_CULT_DEMONESS_MAX_POSTINDUSTRIAL_TECH",
 HANGED_MAN="LOTM_CULT_HANGED_MAX_POSTINDUSTRIAL_TECH",
 CHAINED="LOTM_CULT_CHAINED_MAX_POSTINDUSTRIAL_TECH"
};
local STATE_VERSION=4;
local prefixCache={};
local HANGED_WAR_ABILITIES={
 [1]="ABILITY_LOTM_CULT_HANGED_WAR_C1",[5]="ABILITY_LOTM_CULT_HANGED_WAR_C5",
 [20]="ABILITY_LOTM_CULT_HANGED_WAR_C20",[40]="ABILITY_LOTM_CULT_HANGED_WAR_C40",
 [60]="ABILITY_LOTM_CULT_HANGED_WAR_C60"
};
local CHAINED_WAR_ABILITIES={
 [2]="ABILITY_LOTM_CULT_CHAINED_WAR_C2",[10]="ABILITY_LOTM_CULT_CHAINED_WAR_C10",
 [20]="ABILITY_LOTM_CULT_CHAINED_WAR_C20"
};
local WAR_COMBAT_ABILITIES={
 "ABILITY_LOTM_CULT_HANGED_WAR_C1","ABILITY_LOTM_CULT_HANGED_WAR_C5",
 "ABILITY_LOTM_CULT_HANGED_WAR_C20","ABILITY_LOTM_CULT_HANGED_WAR_C40",
 "ABILITY_LOTM_CULT_HANGED_WAR_C60","ABILITY_LOTM_CULT_CHAINED_WAR_C2",
 "ABILITY_LOTM_CULT_CHAINED_WAR_C10","ABILITY_LOTM_CULT_CHAINED_WAR_C20"
};

local function Log(message) print("[LOTM_CULT] "..tostring(message)); end
local function Number(value,default) if value==nil then return default; end return tonumber(value) or default; end
local function AliveMajors()
 local result={};
 for _,player in ipairs(PlayerManager.GetAliveMajors()) do table.insert(result,player); end
 table.sort(result,function(a,b) return a:GetID()<b:GetID(); end);
 return result;
end
local function AliveAIMajors()
 local result={}; for _,player in ipairs(AliveMajors()) do if not player:IsHuman() then table.insert(result,player); end end return result;
end
local function IsCult(path) return path=="DEMONESS" or path=="HANGED_MAN" or path=="CHAINED"; end
local function PlayerCult(player) local value=player~=nil and player:GetProperty("LOTM_CULT_PATH") or nil; return IsCult(value) and value or "NONE"; end
local function RescueActive() return Number(Game.GetProperty("LOTM_RESCUE_MODE"),0)==1; end

local function SetPlayerCult(player,path)
 if player==nil or player:IsHuman() or not IsCult(path) then return; end
 if PlayerCult(player)=="NONE" then
  player:SetProperty("LOTM_CULT_PATH",path);
  Game.SetProperty("LOTM_CULT_PATH_"..tostring(player:GetID()),path);
  Log("assigned player="..player:GetID().." path="..path);
 end
end

local function InitializeAssignments()
 local ai=AliveAIMajors(); if #ai==0 then return; end
 local missing={}; local present={}; local unassigned={};
 for _,player in ipairs(ai) do
  local path=PlayerCult(player); if IsCult(path) then present[path]=true else table.insert(unassigned,player); end
 end
 for _,path in ipairs(CULTS) do if not present[path] then table.insert(missing,path); end end
 -- With at least three AI, consume every missing path first. A synchronized
 -- rotation keeps which AI receives which guaranteed path unpredictable.
 if #ai>=3 and #unassigned>0 then
  local offset=LOTM_WORLD_State.Random(#missing>0 and #missing or 1,"CULT_GUARANTEE_ROTATION");
  local rotated={}; for index=1,#missing do table.insert(rotated,missing[((index+offset-1)%#missing)+1]); end
  missing=rotated;
 end
 for index,player in ipairs(unassigned) do
  local path=nil;
  if #ai>=3 and index<=#missing then path=missing[index];
  else path=CULTS[LOTM_WORLD_State.Random(#CULTS,"CULT_ASSIGN_PLAYER_"..player:GetID())+1]; end
  SetPlayerCult(player,path);
 end
 Game.SetProperty("LOTM_CULT_ASSIGNMENTS_INITIALIZED",1);
end

local function IndustrialEraChronology()
 local row=GameInfo.Eras.ERA_INDUSTRIAL; return row~=nil and Number(row.ChronologyIndex,row.Index) or 3;
end
local function PostIndustrialTechCount(player)
 if player==nil then return 0; end local techs=player:GetTechs(); if techs==nil then return 0; end
 local threshold=IndustrialEraChronology(); local count=0;
 for tech in GameInfo.Technologies() do
  local era=tech.EraType~=nil and GameInfo.Eras[tech.EraType] or nil;
  if era~=nil and Number(era.ChronologyIndex,era.Index)>=threshold and techs:HasTech(tech.Index) then count=count+1; end
 end
 return count;
end

local function DesiredTier(maxTech) if maxTech>=14 then return 3 elseif maxTech>=5 then return 2 else return 1 end end
local function ReconcileTiers()
 for _,cult in ipairs(CULTS) do
  local highest=0;
  for _,player in ipairs(AliveAIMajors()) do if PlayerCult(player)==cult then highest=math.max(highest,PostIndustrialTechCount(player)); end end
  local historical=Number(Game.GetProperty(MAX_KEYS[cult]),0); if highest>historical then historical=highest; Game.SetProperty(MAX_KEYS[cult],historical); end
  local oldTier=Number(Game.GetProperty(TIER_KEYS[cult]),1); local newTier=math.max(oldTier,DesiredTier(historical));
  if Game.GetProperty(TIER_KEYS[cult])==nil or newTier~=oldTier then Game.SetProperty(TIER_KEYS[cult],newTier); Log("tier cult="..cult.." old="..oldTier.." new="..newTier.." maxTech="..historical); end
 end
end

function LOTM_AI_Cults.GetTier(cult) return Number(Game.GetProperty(TIER_KEYS[cult]),1); end
function LOTM_AI_Cults.GetPlayerCult(playerID) return PlayerCult(Players[playerID]); end
function LOTM_AI_Cults.PostIndustrialTechCount(player) return PostIndustrialTechCount(player); end

local function HasFormalPath(player)
 if player==nil or LOTM_RP_State==nil or LOTM_RP_State.IsAnyPathPlayer==nil then return false; end
 -- Reuse the authoritative pathway-state API.  The synchronized property
 -- stores PATH_RED_PRIEST / PATH_PERFECT / PATH_BLACK_EMPEROR, not the old
 -- RP / PP / BE shorthand.  Keeping a second literal check here previously
 -- blocked both war modifiers and per-turn Faith settlement.
 return LOTM_RP_State.IsAnyPathPlayer(player:GetID());
end
function LOTM_AI_Cults.GetTargetTier(player)
 if HasFormalPath(player) then
  local sequence=Number(player:GetProperty("LOTM_RP_SEQUENCE"),9);
  if sequence>=5 then return 1 elseif sequence>=3 then return 2 else return 3 end -- Sequence 2..0 is tier 3.
 end
 return DesiredTier(PostIndustrialTechCount(player));
end
function LOTM_AI_Cults.GetMultiplier(cultTier,targetTier)
 local difference=targetTier-cultTier;
 if difference==0 then return 1 elseif difference==1 then return 0.2 elseif difference>=2 then return 0 elseif difference==-1 then return 2 else return 3 end
end
local function ScaledInt(base,cultTier,targetTier) return math.floor(base*LOTM_AI_Cults.GetMultiplier(cultTier,targetTier)+0.000001); end
local function ScaledPercent(base,cultTier,targetTier) return math.min(100,ScaledInt(base,cultTier,targetTier)); end

function LOTM_AI_Cults.GetHighestScoreMajorCivilization()
 local selected=nil; local best=nil;
 for _,player in ipairs(AliveMajors()) do
  local score=Number(player:GetScore(),0);
  if best==nil or score>best or (score==best and player:GetID()<selected:GetID()) then selected=player; best=score; end
 end
 return selected;
end

local function HasLivingCult(cult) for _,player in ipairs(AliveAIMajors()) do if PlayerCult(player)==cult then return true; end end return false; end
local function AtWarWithCult(player,cult)
 if player==nil then return false; end local diplomacy=player:GetDiplomacy(); if diplomacy==nil then return false; end
 for _,enemy in ipairs(AliveAIMajors()) do if PlayerCult(enemy)==cult and diplomacy:IsAtWarWith(enemy:GetID()) then return true; end end
 return false;
end

local function PrefixIds(prefix)
 if prefixCache[prefix]~=nil then return prefixCache[prefix]; end local found={};
 for row in GameInfo.Modifiers() do if string.sub(row.ModifierId,1,#prefix)==prefix then table.insert(found,row.ModifierId); end end
 table.sort(found); prefixCache[prefix]=found; return found;
end
local function AttachPrefix(player,prefix)
 local ids=PrefixIds(prefix); for _,modifierID in ipairs(ids) do player:AttachModifierByID(modifierID); end
 if #ids==0 then Log("modifier prefix missing="..prefix); end
end
local function NotifyEffect(player,slot,active)
 if player==nil or not player:IsHuman() then return; end
 local cult=nil; local notificationType=NotificationTypes.USER_DEFINED_9;
 if slot=="DEMONESS" then cult="DEMONESS"; notificationType=NotificationTypes.USER_DEFINED_4;
 elseif slot=="HANGED_WAR" then cult="HANGED_MAN"; notificationType=NotificationTypes.USER_DEFINED_5;
 elseif slot=="CHAINED_WAR" or slot=="CHAINED_BORDER" then cult="CHAINED"; end
 if cult==nil then return; end local tier=LOTM_AI_Cults.GetTier(cult); local name=Locale.Lookup("LOC_LOTM_CULT_"..cult.."_NAME"); local skill=Locale.Lookup("LOC_LOTM_CULT_"..cult.."_T"..tier.."_NAME");
 local data={}; data[ParameterTypes.MESSAGE]=Locale.Lookup(active and "LOC_LOTM_CULT_NOTIFICATION_APPLIED" or "LOC_LOTM_CULT_NOTIFICATION_ENDED",name,skill); data[ParameterTypes.SUMMARY]=active and Locale.Lookup("LOC_LOTM_CULT_"..cult.."_T"..tier.."_DESCRIPTION") or Locale.Lookup("LOC_LOTM_CULT_NOTIFICATION_ENDED_SUMMARY"); data.AlwaysUnique=true; data.ShowIcon=false;
 local ok,err=pcall(function() NotificationManager.SendNotification(player:GetID(),notificationType,data); end); if not ok then Log("notification failed slot="..slot.." error="..tostring(err)); end
end
local function ApplySwitch(player,slot,desired)
 local property="LOTM_CULT_APPLIED_"..slot; local old=tostring(player:GetProperty(property) or "NONE"); desired=desired or "NONE";
 if old==desired then return; end
 if old~="NONE" then AttachPrefix(player,"LOTM_CULT_"..old.."_OFF__"); end
 if desired~="NONE" then AttachPrefix(player,"LOTM_CULT_"..desired.."_ON__"); end
 player:SetProperty(property,desired); NotifyEffect(player,slot,desired~="NONE"); Log("switch player="..player:GetID().." slot="..slot.." old="..old.." new="..desired);
end
local function RetireLegacySwitch(player,slot)
 local property="LOTM_CULT_APPLIED_"..slot; local old=tostring(player:GetProperty(property) or "NONE");
 if old=="NONE" then return; end
 AttachPrefix(player,"LOTM_CULT_"..old.."_OFF__");
 player:SetProperty(property,"NONE");
 Log("retired legacy switch player="..player:GetID().." slot="..slot.." old="..old);
end
local function RefreshWarNotification(player,slot,desired)
 local property="LOTM_CULT_ACTIVE_"..slot; local old=tostring(player:GetProperty(property) or "NONE"); desired=desired or "NONE";
 if old==desired then return; end
 player:SetProperty(property,desired); NotifyEffect(player,slot,desired~="NONE");
 Log("war notification state player="..player:GetID().." slot="..slot.." old="..old.." new="..desired);
end

local function RefreshEffectAudit(player,hangedWar,hangedTier,hangedCombatAmount,chainedWar,chainedTier,chainedMove,chainedCombatAmount,chainedYield)
 local targetTier=LOTM_AI_Cults.GetTargetTier(player);
 local state=table.concat({
  "TARGET_T"..tostring(targetTier),
  "HANGED="..(hangedWar and ("T"..tostring(hangedTier)..":C"..tostring(hangedCombatAmount)) or "OFF"),
  "CHAINED="..(chainedWar and ("T"..tostring(chainedTier)..":MOVE_"..tostring(chainedMove or "NONE")..":C"..tostring(chainedCombatAmount)..":YIELD_"..tostring(chainedYield or "NONE")) or "OFF")
 },"|");
 local property="LOTM_CULT_EFFECT_AUDIT";
 if tostring(player:GetProperty(property) or "")~=state then
  player:SetProperty(property,state);
  Log("effect audit player="..player:GetID().." "..state);
 end
end

local function DemonessToken(player,tier)
 local target=LOTM_AI_Cults.GetTargetTier(player);
 if tier==1 then local amount=ScaledInt(1,tier,target); return amount>0 and "DEMONESS_V2_T1_M"..amount or nil; end
 if tier==2 then local percent=ScaledPercent(20,tier,target); return percent>0 and "DEMONESS_T2_P"..percent or nil; end
 local amenity=ScaledInt(5,tier,target); local percent=ScaledPercent(50,tier,target);
 return percent>0 and ("DEMONESS_T3_A"..amenity.."_P"..percent) or nil;
end
local function HangedToken(player,tier)
 local amount=0; if tier==1 then amount=ScaledInt(5,tier,LOTM_AI_Cults.GetTargetTier(player)); elseif tier==3 then amount=ScaledInt(20,tier,LOTM_AI_Cults.GetTargetTier(player)); end
 return amount>0 and ("HANGED_T"..tier.."_C"..amount) or nil,amount;
end
local function HangedFaithToken(player,tier)
 local _,amount=HangedToken(player,tier);
 return amount>0 and ("HANGED_FAITH_T"..tier.."_F"..amount) or nil,amount;
end
local function ChainedMoveToken(player,tier)
 local target=LOTM_AI_Cults.GetTargetTier(player);
 if tier==1 then local move=ScaledInt(1,tier,target); return move>0 and "CHAINED_MOVE_T1_M1" or nil; end
 if tier==2 then local move=ScaledInt(1,tier,target); return move>0 and ("CHAINED_MOVE_T2_M"..move) or nil; end
 return nil;
end
local function ChainedYieldToken(player,tier)
 if tier~=3 then return nil; end
 local percent=ScaledPercent(50,tier,LOTM_AI_Cults.GetTargetTier(player));
 return percent>0 and "CHAINED_YIELD_T3_P"..percent or nil;
end
local function ChainedCombatAmount(player,tier)
 return tier==2 and ScaledInt(10,tier,LOTM_AI_Cults.GetTargetTier(player)) or 0;
end
local function ChainedBorderToken(player,tier)
 if tier~=2 then return nil; end local percent=ScaledPercent(50,tier,LOTM_AI_Cults.GetTargetTier(player)); return percent>0 and "CHAINED_BORDER_P"..percent or nil;
end

local function SetUnitAbility(unit,abilityType,desired)
 local abilities=unit~=nil and unit:GetAbility() or nil; if abilities==nil then return; end
 local current=abilities:GetAbilityCount(abilityType) or 0;
 if current~=desired then abilities:ChangeAbilityCount(abilityType,desired-current); end
end
local function RefreshWarCombatAbilities(player,hangedAmount,chainedAmount)
 if player==nil then return; end
 local hangedAbility=HANGED_WAR_ABILITIES[hangedAmount]; local chainedAbility=CHAINED_WAR_ABILITIES[chainedAmount];
 for _,unit in player:GetUnits():Members() do
  for _,abilityType in ipairs(WAR_COMBAT_ABILITIES) do
   local desired=(abilityType==hangedAbility or abilityType==chainedAbility) and 1 or 0;
   SetUnitAbility(unit,abilityType,desired);
  end
 end
end

local function RetireNegativeEffectsForRescue()
 for _,player in ipairs(AliveMajors()) do
  ApplySwitch(player,"DEMONESS",nil);
  ApplySwitch(player,"CHAINED_BORDER",nil);
  RetireLegacySwitch(player,"HANGED_WAR");
  ApplySwitch(player,"HANGED_FAITH",nil);
  player:SetProperty("LOTM_CULT_HANGED_FAITH_PER_TURN",0);
  RetireLegacySwitch(player,"CHAINED_WAR");
  ApplySwitch(player,"CHAINED_MOVE",nil);
  ApplySwitch(player,"CHAINED_YIELD",nil);
  RefreshWarCombatAbilities(player,0,0);
  RefreshWarNotification(player,"HANGED_WAR",nil);
  RefreshWarNotification(player,"CHAINED_WAR",nil);
  player:SetProperty("LOTM_CULT_AT_WAR_WITH_HANGED",0);
  player:SetProperty("LOTM_CULT_AT_WAR_WITH_CHAINED",0);
  player:SetProperty("LOTM_CULT_EFFECT_AUDIT","RESCUE_POSITIVE_ONLY");
 end
end

local function ReconcileEffects()
 if RescueActive() then RetireNegativeEffectsForRescue(); return; end
 local top=LOTM_AI_Cults.GetHighestScoreMajorCivilization(); local topID=top~=nil and top:GetID() or -1; Game.SetProperty("LOTM_CULT_TOP_SCORE_PLAYER",topID);
 local demonTier=LOTM_AI_Cults.GetTier("DEMONESS"); local hangedTier=LOTM_AI_Cults.GetTier("HANGED_MAN"); local chainedTier=LOTM_AI_Cults.GetTier("CHAINED");
 local demonAlive=HasLivingCult("DEMONESS"); local hangedAlive=HasLivingCult("HANGED_MAN"); local chainedAlive=HasLivingCult("CHAINED");
 for _,player in ipairs(AliveMajors()) do
  local isTop=player:GetID()==topID;
  local demonDesired=nil; if demonAlive and isTop and PlayerCult(player)~="DEMONESS" then demonDesired=DemonessToken(player,demonTier); end
  ApplySwitch(player,"DEMONESS",demonDesired);
  local borderDesired=nil; if chainedAlive and isTop and PlayerCult(player)~="CHAINED" then borderDesired=ChainedBorderToken(player,chainedTier); end
  ApplySwitch(player,"CHAINED_BORDER",borderDesired);
  local formalHuman=HasFormalPath(player);
  local hangedWar=formalHuman and hangedAlive and AtWarWithCult(player,"HANGED_MAN");
  local chainedWar=formalHuman and chainedAlive and AtWarWithCult(player,"CHAINED");
  player:SetProperty("LOTM_CULT_AT_WAR_WITH_HANGED",hangedWar and 1 or 0); player:SetProperty("LOTM_CULT_AT_WAR_WITH_CHAINED",chainedWar and 1 or 0);
  local hangedDesired=nil; local hangedCombatAmount=0;
  if hangedWar and (hangedTier==1 or hangedTier==3) then hangedDesired,hangedCombatAmount=HangedToken(player,hangedTier); end
  -- Retire resource 111-114 permanent combat switches. Their OFF pair keeps
  -- old saves numerically neutral; removable Unit Abilities own live combat.
  RetireLegacySwitch(player,"HANGED_WAR");
  local hangedFaithDesired=nil; local hangedFaithAmount=0;
  if hangedWar and (hangedTier==1 or hangedTier==3) then hangedFaithDesired,hangedFaithAmount=HangedFaithToken(player,hangedTier); end
  ApplySwitch(player,"HANGED_FAITH",hangedFaithDesired);
  player:SetProperty("LOTM_CULT_HANGED_FAITH_PER_TURN",hangedFaithDesired~=nil and -hangedFaithAmount or 0);
  RetireLegacySwitch(player,"CHAINED_WAR");
  local chainedMove=nil; local chainedYield=nil; local chainedCombatAmount=0;
  if chainedWar then
   chainedMove=ChainedMoveToken(player,chainedTier);
   chainedYield=ChainedYieldToken(player,chainedTier);
   chainedCombatAmount=ChainedCombatAmount(player,chainedTier);
  end
  ApplySwitch(player,"CHAINED_MOVE",chainedMove);
  ApplySwitch(player,"CHAINED_YIELD",chainedYield);
  RefreshWarCombatAbilities(player,hangedCombatAmount,chainedCombatAmount);
  RefreshWarNotification(player,"HANGED_WAR",hangedDesired);
  -- A war relation alone is not an active effect. Tier scaling can truncate
  -- every integer effect to zero, or grant complete immunity.
  local chainedWarDesired=nil;
  if chainedWar and (chainedMove~=nil or chainedCombatAmount>0 or chainedYield~=nil) then chainedWarDesired="CHAINED_T"..tostring(chainedTier); end
  RefreshWarNotification(player,"CHAINED_WAR",chainedWarDesired);
  RefreshEffectAudit(player,hangedWar,hangedTier,hangedCombatAmount,chainedWar,chainedTier,chainedMove,chainedCombatAmount,chainedYield);
 end
end

function LOTM_AI_Cults.Reconcile()
 InitializeAssignments(); ReconcileTiers(); ReconcileEffects();
 Game.SetProperty("LOTM_CULT_STATE_VERSION",STATE_VERSION);
 if RescueActive() then
  if LOTM_AI_Cult_Hanged~=nil and LOTM_AI_Cult_Hanged.RetireForRescue~=nil then LOTM_AI_Cult_Hanged.RetireForRescue(); end
 elseif LOTM_AI_Cult_Hanged~=nil and LOTM_AI_Cult_Hanged.ReconcileAll~=nil then LOTM_AI_Cult_Hanged.ReconcileAll(); end
 if LOTM_RESCUE_Phase7~=nil and LOTM_RESCUE_Phase7.ReconcileAll~=nil then LOTM_RESCUE_Phase7.ReconcileAll(); end
end

local function OnTurn(playerID,isFirstTimeThisTurn)
 if isFirstTimeThisTurn==false then return; end LOTM_AI_Cults.Reconcile();
end
local function OnResearchCompleted(playerID,techIndex,isCanceled) if isCanceled~=true then LOTM_AI_Cults.Reconcile(); end end
-- Match the proven planned-war economy: diplomacy events refresh immediately,
-- while PlayerTurnActivated remains the authoritative fallback and settlement.
local function OnDiplomacyChanged() LOTM_AI_Cults.Reconcile(); end
local function OnUnitAddedToMap(playerID)
 if RescueActive() then return; end
 local player=Players[playerID]; if player~=nil and player:IsHuman() then LOTM_AI_Cults.Reconcile(); end
end

Events.PlayerTurnActivated.Add(OnTurn);
Events.ResearchCompleted.Add(OnResearchCompleted);
Events.DiplomacyDeclareWar.Add(OnDiplomacyChanged);
Events.DiplomacyMakePeace.Add(OnDiplomacyChanged);
Events.UnitAddedToMap.Add(LOTM_UnitAddedPerf.Wrap("AICults",OnUnitAddedToMap));
LOTM_AI_Cults.Reconcile();
Log("initialized stateVersion="..STATE_VERSION.." tiers=1..3 thresholds=5/14");
-- END RC241 MODULE: Scripts/LOTM_AI_Cults.lua
end;

m_mp241Loaders["LOTM_BE_BlackEmperor"] = function()
-- BEGIN RC241 MODULE: Scripts/LOTM_BE_BlackEmperor.lua
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("MP.LOTM_BE_BlackEmperor","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"MP.LOTM_BE_BlackEmperor","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"MP.LOTM_BE_BlackEmperor","GameEvents");
-- END RC342 STARTUP TRACE

-- Black Emperor Path (Sequences 9-2).
-- All persistent mutations in this module run in synchronized Gameplay.

local LOTM_BE_PATH :string = "PATH_BLACK_EMPEROR";
local LOTM_BE_CODE_OF_LAWS :string = "CIVIC_CODE_OF_LAWS";
local LOTM_BE_CHAOS_I :string = "POLICY_LOTM_BE_CHAOS_I";
local LOTM_BE_CHAOS_II :string = "POLICY_LOTM_BE_CHAOS_II";
local LOTM_BE_CHAOS_III :string = "POLICY_LOTM_BE_CHAOS_III";
local LOTM_BE_CORRUPTION_I :string = "POLICY_LOTM_BE_CORRUPTION_I";
local LOTM_BE_CORRUPTION_II :string = "POLICY_LOTM_BE_CORRUPTION_II";
local LOTM_BE_CORRUPTION_III :string = "POLICY_LOTM_BE_CORRUPTION_III";
local LOTM_BE_FRENZY_I :string = "POLICY_LOTM_BE_FRENZY_I";
local LOTM_BE_FRENZY_II :string = "POLICY_LOTM_BE_FRENZY_II";
local LOTM_BE_TRANSFORMATION_PROJECT :string = "PROJECT_LOTM_BE_TRANSFORMATION";
local LOTM_BE_CITY_OWNER_PROPERTY :string = "LOTM_BE_OBSERVED_CITY_OWNER";
local LOTM_BE_CITY_TRANSFER_AWARD_PROPERTY :string = "LOTM_BE_SEQ2_TRANSFER_AWARD_KEY";
local LOTM_BE_CITY_SCAN_TURN_PROPERTY :string = "LOTM_BE_CITY_SCAN_TURN";
local ScanCityOwnership;

local P :table = {
	FirstCityGranted = "LOTM_BE_FIRST_CITY_REWARD_GRANTED",
	WildcardAttached = "LOTM_BE_WILDCARD_SLOT_ATTACHED",
	MightStrengthAttached = "LOTM_BE_MIGHT_STRENGTH_ATTACHED",
	MightStrengthV2Attached = "LOTM_BE_MIGHT_STRENGTH_V2_ATTACHED",
	LegacyBaseStrengthCorrected = "LOTM_BE_LEGACY_BASE_STRENGTH_CORRECTED",
	CivilianBuildersV2Cleaned = "LOTM_BE_CIVILIAN_BUILDERS_V2_CLEANED",
	MightMovementAttached = "LOTM_BE_MIGHT_MOVEMENT_ATTACHED",
	TradeGoldAttached = "LOTM_BE_TRADE_GOLD_ATTACHED",
	WealthAttached = "LOTM_BE_WEALTH_ATTACHED",
	EnvoyBaseline = "LOTM_BE_ENVOY_BASELINE",
	AutomaticCivicTurn = "LOTM_BE_AUTOMATIC_CIVIC_TURN",
	CivicScoringMigrated = "LOTM_BE_CIVIC_SCORING_V2_MIGRATED",
	ChaosIUnlocked = "LOTM_BE_CHAOS_I_UNLOCKED",
	ChaosIIUnlocked = "LOTM_BE_CHAOS_II_UNLOCKED",
	ChaosIIIUnlocked = "LOTM_BE_CHAOS_III_UNLOCKED",
	CorruptionIUnlocked = "LOTM_BE_CORRUPTION_I_UNLOCKED",
	CorruptionIIUnlocked = "LOTM_BE_CORRUPTION_II_UNLOCKED",
	CorruptionIIIUnlocked = "LOTM_BE_CORRUPTION_III_UNLOCKED",
	FrenzyIUnlocked = "LOTM_BE_FRENZY_I_UNLOCKED",
	FrenzyIIUnlocked = "LOTM_BE_FRENZY_II_UNLOCKED",
	TransformationProjectAttached = "LOTM_BE_TRANSFORMATION_PROJECT_ATTACHED",
	CorruptProsperityFoodAttached = "LOTM_BE_CORRUPT_PROSPERITY_FOOD_ATTACHED",
	EntropyPressureAttached = "LOTM_BE_ENTROPY_PRESSURE_ATTACHED",
	EntropyPressureV2Attached = "LOTM_BE_ENTROPY_PRESSURE_V2_ATTACHED",
	EntropyLoyaltyAttached = "LOTM_BE_ENTROPY_LOYALTY_ATTACHED",
};

local LOTM_BE_TOMB_SLOT_MODIFIERS :table = {
	{ "LOTM_BE_MOD_TOMB_MILITARY_SLOT_1", "LOTM_BE_TOMB_MILITARY_SLOT_1_ATTACHED" },
	{ "LOTM_BE_MOD_TOMB_MILITARY_SLOT_2", "LOTM_BE_TOMB_MILITARY_SLOT_2_ATTACHED" },
	{ "LOTM_BE_MOD_TOMB_MILITARY_SLOT_3", "LOTM_BE_TOMB_MILITARY_SLOT_3_ATTACHED" },
	{ "LOTM_BE_MOD_TOMB_ECONOMIC_SLOT_1", "LOTM_BE_TOMB_ECONOMIC_SLOT_1_ATTACHED" },
	{ "LOTM_BE_MOD_TOMB_ECONOMIC_SLOT_2", "LOTM_BE_TOMB_ECONOMIC_SLOT_2_ATTACHED" },
	{ "LOTM_BE_MOD_TOMB_ECONOMIC_SLOT_3", "LOTM_BE_TOMB_ECONOMIC_SLOT_3_ATTACHED" },
	{ "LOTM_BE_MOD_TOMB_WILDCARD_SLOT_1", "LOTM_BE_TOMB_WILDCARD_SLOT_1_ATTACHED" },
	{ "LOTM_BE_MOD_TOMB_WILDCARD_SLOT_2", "LOTM_BE_TOMB_WILDCARD_SLOT_2_ATTACHED" },
	{ "LOTM_BE_MOD_TOMB_WILDCARD_SLOT_3", "LOTM_BE_TOMB_WILDCARD_SLOT_3_ATTACHED" },
};

local function Log(message :string)
	print("[LOTM_BE] " .. message);
end

local function GetPlayer(playerID :number)
	return playerID ~= nil and Players[playerID] or nil;
end

local function IsBlackEmperor(playerID :number)
	return LOTM_RP_State ~= nil
		and LOTM_RP_State.IsBlackEmperorPlayer ~= nil
		and LOTM_RP_State.IsBlackEmperorPlayer(playerID);
end

local function GetSequence(playerID :number)
	return LOTM_RP_State.GetSequence(playerID);
end

local function AddDigestion(playerID :number, category :string, key :string, amount :number)
	local added = 0;
	for index = 1, math.max(0, amount or 1) do
		if LOTM_RP_State.TryAddDigestion(
			playerID,
			category,
			key .. ":POINT:" .. tostring(index)
		) then
			added = added + 1;
		end
	end
	return added;
end

local function HasAnyCity(player)
	if player == nil then
		return false;
	end
	for _, city in player:GetCities():Members() do
		return city ~= nil;
	end
	return false;
end

local function GrantFirstCityReward(playerID :number)
	local player = GetPlayer(playerID);
	if player == nil or not IsBlackEmperor(playerID) or not HasAnyCity(player)
		or (player:GetProperty(P.FirstCityGranted) or 0) == 1 then
		return false;
	end

	LOTM_RP_State.AttachModifierOnce(
		playerID,
		"LOTM_BE_MOD_RULES_WILDCARD_SLOT",
		P.WildcardAttached
	);
	local civic = GameInfo.Civics[LOTM_BE_CODE_OF_LAWS];
	local culture = player:GetCulture();
	if civic ~= nil and culture ~= nil and not culture:HasCivic(civic.Index) then
		-- CivicCompleted may be raised by the normal progress-completion path.
		-- Mark this grant first so
		-- the event handler cannot award the same automatic civic a second time.
		player:SetProperty(P.AutomaticCivicTurn, Game.GetCurrentGameTurn());
		-- Firaxis' Player tuner completes civics by filling their cultural
		-- progress. This also refreshes the current-research state immediately;
		-- SetCivic alone can leave the UI cache stale until the tree is opened.
		culture:SetCulturalProgress(civic.Index, culture:GetCultureCost(civic.Index));
		if not culture:HasCivic(civic.Index) then
			culture:SetCivic(civic.Index, true);
		end
		AddDigestion(
			playerID,
			"A",
			"CIVIC_COMPLETED:" .. tostring(civic.Index),
			3
		);
	end
	player:SetProperty(P.FirstCityGranted, 1);
	Log("player=" .. tostring(playerID) .. " received Code of Laws and wildcard slot");
	return true;
end

local function GetTotalEnvoys(playerID :number)
	local player = GetPlayer(playerID);
	local influence = player ~= nil and player:GetInfluence() or nil;
	if influence == nil then
		return 0;
	end
	local total = influence:GetTokensToGive() or 0;
	for _, minorID in ipairs(PlayerManager.GetAliveMinorIDs()) do
		local minor = GetPlayer(minorID);
		local minorInfluence = minor ~= nil and minor:GetInfluence() or nil;
		if minorInfluence ~= nil then
			total = total + (minorInfluence:GetTokensReceived(playerID) or 0);
		end
	end
	if LOTM_WORLD_Churches ~= nil and LOTM_WORLD_Churches.GetEnvoys ~= nil then
		for _, churchType in ipairs({"FOOL", "NIGHT", "STORM"}) do
			total = total + LOTM_WORLD_Churches.GetEnvoys(playerID, churchType);
		end
	end
	return total;
end

local function MigrateSequence9CivicScoring(playerID :number)
	if not IsBlackEmperor(playerID) or GetSequence(playerID) ~= 9 then
		return;
	end
	local player = GetPlayer(playerID);
	if player == nil or (player:GetProperty(P.CivicScoringMigrated) or 0) == 1
		or (player:GetProperty(P.FirstCityGranted) or 0) ~= 1 then
		return;
	end
	local culture = player:GetCulture();
	if culture == nil then
		return;
	end

	-- rc.41 awarded two points for civics and could retain policy-card points.
	-- Rebuild once from authoritative completed civics under the rc.42 rule.
	local completed :table = {};
	for civic in GameInfo.Civics() do
		if culture:HasCivic(civic.Index) then
			table.insert(completed, civic.Index);
		end
	end
	table.sort(completed);
	player:SetProperty("LOTM_RP_DIGEST_A", 0);
	player:SetProperty("LOTM_RP_DIGEST_B", 0);
	player:SetProperty("LOTM_RP_DIGEST_TURN", -1);
	player:SetProperty("LOTM_RP_DIGEST_TURN_GAIN", 0);
	for _, civicIndex in ipairs(completed) do
		AddDigestion(
			playerID,
			"A",
			"CIVIC_COMPLETED:" .. tostring(civicIndex),
			3
		);
	end
	player:SetProperty(P.CivicScoringMigrated, 1);
	Log("player=" .. tostring(playerID)
		.. " migrated Sequence 9 civic scoring completed="
		.. tostring(#completed));
end

local function RefreshEnvoyBaseline(playerID :number, allowGain :boolean)
	if not IsBlackEmperor(playerID) or GetSequence(playerID) ~= 7 then
		return;
	end
	local player = GetPlayer(playerID);
	local total = GetTotalEnvoys(playerID);
	local baseline = player:GetProperty(P.EnvoyBaseline);
	if baseline == nil or baseline < 0 then
		player:SetProperty(P.EnvoyBaseline, total);
		return;
	end
	if allowGain and total > baseline then
		for serial = baseline + 1, total do
			LOTM_RP_State.TryAddDigestion(
				playerID,
				"B",
				"ENVOY_GAIN:" .. tostring(Game.GetCurrentGameTurn())
					.. ":" .. tostring(serial)
			);
		end
	end
	player:SetProperty(P.EnvoyBaseline, total);
end

function LOTM_BE_RefreshEnvoyBaseline(playerID :number, allowGain :boolean)
	RefreshEnvoyBaseline(playerID, allowGain == true);
end

local function UnlockPolicyOnce(playerID :number, policyType :string, flagKey :string)
	local player = GetPlayer(playerID);
	if player == nil or (player:GetProperty(flagKey) or 0) == 1 then
		return false;
	end
	local policy = GameInfo.Policies[policyType];
	local culture = player:GetCulture();
	if policy == nil or culture == nil then
		return false;
	end
	culture:UnlockPolicy(policy.Index);
	player:SetProperty(flagKey, 1);
	Log("player=" .. tostring(playerID) .. " unlocked policy=" .. policyType);
	return true;
end

local function IsPolicyActive(playerID :number, policyType :string)
	local player = GetPlayer(playerID);
	local policy = GameInfo.Policies[policyType];
	local culture = player ~= nil and player:GetCulture() or nil;
	return policy ~= nil and culture ~= nil and culture:IsPolicyActive(policy.Index);
end

local function IsTransformationActive(playerID :number)
	local player = GetPlayer(playerID);
	return player ~= nil
		and tonumber(player:GetProperty("LOTM_BE_TRANSFORMATION_ACTIVE_SYNC")) == 1;
end

local function UnlockSequencePolicies(playerID :number, sequence :number)
	if sequence <= 5 then
		UnlockPolicyOnce(playerID, LOTM_BE_CHAOS_I, P.ChaosIUnlocked);
	end
	if sequence <= 4 then
		UnlockPolicyOnce(playerID, LOTM_BE_CHAOS_II, P.ChaosIIUnlocked);
		UnlockPolicyOnce(playerID, LOTM_BE_CORRUPTION_I, P.CorruptionIUnlocked);
	end
	if sequence <= 3 then
		UnlockPolicyOnce(playerID, LOTM_BE_FRENZY_I, P.FrenzyIUnlocked);
		UnlockPolicyOnce(playerID, LOTM_BE_CORRUPTION_II, P.CorruptionIIUnlocked);
	end
	if sequence <= 1 then
		UnlockPolicyOnce(playerID, LOTM_BE_CHAOS_III, P.ChaosIIIUnlocked);
		UnlockPolicyOnce(playerID, LOTM_BE_CORRUPTION_III, P.CorruptionIIIUnlocked);
		UnlockPolicyOnce(playerID, LOTM_BE_FRENZY_II, P.FrenzyIIUnlocked);
	end
end

local function CleanupStrandedCivilianBuilders(playerID :number)
	local player = GetPlayer(playerID);
	if player == nil
		or (player:GetProperty(P.CivilianBuildersV2Cleaned) or 0) == 1 then
		return false;
	end
	local stranded :table = {};
	for _, unit in player:GetUnits():Members() do
		local unitInfo = unit ~= nil and GameInfo.Units[unit:GetType()] or nil;
		if unitInfo ~= nil
			and unitInfo.FormationClass == "FORMATION_CLASS_CIVILIAN"
			and (unitInfo.BuildCharges or 0) > 0
			and unit:GetBuildCharges() <= 0 then
			table.insert(stranded, unit);
		end
	end
	table.sort(stranded, function(left, right)
		return left:GetID() < right:GetID();
	end);
	for _, unit in ipairs(stranded) do
		Log("removing stranded zero-charge civilian builder player="
			.. tostring(playerID) .. " unit=" .. tostring(unit:GetID()));
		UnitManager.Kill(unit, false);
	end
	player:SetProperty(P.CivilianBuildersV2Cleaned, 1);
	return #stranded > 0;
end

local function CorrectLegacyBuilderBaseStrength(playerID :number)
	local player = GetPlayer(playerID);
	if player == nil or not IsBlackEmperor(playerID)
		or GetSequence(playerID) > 8
		or (player:GetProperty(P.MightStrengthAttached) or 0) ~= 1
		or (player:GetProperty(P.LegacyBaseStrengthCorrected) or 0) == 1 then
		return false;
	end

	-- rc.41-46 permanently attached a player-wide +10 base-strength modifier.
	-- Permanent instances are serialized in the save and retain their original
	-- argument even though the current database row is now zero.  Detect the
	-- actual saved instance from a civilian builder instead of guessing from a
	-- version/property flag, so clean new games never receive this correction.
	for _, unit in player:GetUnits():Members() do
		local unitInfo = unit ~= nil and GameInfo.Units[unit:GetType()] or nil;
		local databaseCombat = unitInfo ~= nil
			and (tonumber(unitInfo.Combat) or 0) or 0;
		local runtimeCombat = unit ~= nil and (unit:GetCombat() or 0) or 0;
		if unitInfo ~= nil
			and unitInfo.FormationClass == "FORMATION_CLASS_CIVILIAN"
			and (unitInfo.BuildCharges or 0) > 0
			and databaseCombat == 0
			and runtimeCombat >= 10 then
			local attached = LOTM_RP_State.AttachModifierOnce(
				playerID,
				"LOTM_BE_MOD_LEGACY_BASE_STRENGTH_CORRECTION",
				P.LegacyBaseStrengthCorrected
			);
			Log("legacy base-strength migration player=" .. tostring(playerID)
				.. " unit=" .. tostring(unit:GetID())
				.. " unitType=" .. tostring(unitInfo.UnitType)
				.. " databaseCombat=" .. tostring(databaseCombat)
				.. " runtimeBefore=" .. tostring(runtimeCombat)
				.. " runtimeAfter=" .. tostring(unit:GetCombat())
				.. " attached=" .. tostring(attached));
			return attached;
		end
	end
	return false;
end

function LOTM_BE_RefreshSequenceState(playerID :number)
	if not IsBlackEmperor(playerID) then
		return false;
	end
	local sequence = GetSequence(playerID);
	GrantFirstCityReward(playerID);
	MigrateSequence9CivicScoring(playerID);
	if sequence <= 8 then
		CorrectLegacyBuilderBaseStrength(playerID);
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			"LOTM_BE_MOD_MIGHT_BASE_STRENGTH_AURA_V2",
			P.MightStrengthV2Attached
		);
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			"LOTM_BE_MOD_MIGHT_MOVEMENT",
			P.MightMovementAttached
		);
		CleanupStrandedCivilianBuilders(playerID);
	end
	if sequence <= 7 then
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			"LOTM_BE_MOD_BRIBERY_TRADE_GOLD",
			P.TradeGoldAttached
		);
	end
	if sequence <= 6 then
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			"LOTM_BE_MOD_CORRUPT_WEALTH_GOLD",
			P.WealthAttached
		);
	end
	if sequence <= 5 then
		UnlockSequencePolicies(playerID, sequence);
	end
	if sequence <= 4 then
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			"LOTM_BE_MOD_CORRUPT_PROSPERITY_FOOD",
			P.CorruptProsperityFoodAttached
		);
	end
	if sequence <= 2 then
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			"LOTM_BE_MOD_ENTROPY_PRESSURE",
			P.EntropyPressureAttached
		);
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			"LOTM_BE_MOD_ENTROPY_PRESSURE_V2_BONUS",
			P.EntropyPressureV2Attached
		);
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			"LOTM_BE_MOD_ENTROPY_LOYALTY",
			P.EntropyLoyaltyAttached
		);
	end
	if sequence <= 1 then
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			"LOTM_BE_MOD_ALLOW_TRANSFORMATION_PROJECT",
			P.TransformationProjectAttached
		);
	end
	if sequence <= 0 then
		for _, entry in ipairs(LOTM_BE_TOMB_SLOT_MODIFIERS) do
			LOTM_RP_State.AttachModifierOnce(playerID, entry[1], entry[2]);
		end
	end
	if sequence == 7 then
		RefreshEnvoyBaseline(playerID, false);
	end
	return true;
end

function LOTM_BE_OnPathSelected(playerID :number)
	LOTM_BE_RefreshSequenceState(playerID);
end

local function OnPlayerTurnActivated(playerID :number, isFirstTimeThisTurn :boolean)
	if isFirstTimeThisTurn then
		ScanCityOwnership(true);
	end
	if not IsBlackEmperor(playerID) then
		return;
	end
	LOTM_BE_RefreshSequenceState(playerID);
	if isFirstTimeThisTurn then
		RefreshEnvoyBaseline(playerID, true);
		local sequence = GetSequence(playerID);
		if sequence == 5 and IsPolicyActive(playerID, LOTM_BE_CHAOS_I) then
			LOTM_RP_State.TryAddDigestion(
				playerID,
				"A",
				"CHAOS_I_ACTIVE:" .. tostring(Game.GetCurrentGameTurn())
			);
		elseif sequence == 4 and (
			IsPolicyActive(playerID, LOTM_BE_CORRUPTION_I)
			or IsPolicyActive(playerID, LOTM_BE_CHAOS_II)
		) then
			LOTM_RP_State.TryAddDigestion(
				playerID, "B", "SEQUENCE4_POLICY_ACTIVE:"
					.. tostring(Game.GetCurrentGameTurn())
			);
		elseif sequence == 3 then
			if IsPolicyActive(playerID, LOTM_BE_FRENZY_I) then
				LOTM_RP_State.TryAddDigestion(
					playerID, "A", "FRENZY_I_ACTIVE:"
						.. tostring(Game.GetCurrentGameTurn())
				);
			end
			if IsPolicyActive(playerID, LOTM_BE_CORRUPTION_II) then
				LOTM_RP_State.TryAddDigestion(
					playerID, "B", "CORRUPTION_II_ACTIVE:"
						.. tostring(Game.GetCurrentGameTurn())
				);
			end
		elseif sequence == 1 then
			if IsTransformationActive(playerID) then
				LOTM_RP_State.TryAddDigestion(
					playerID, "A", "TRANSFORMATION_ACTIVE:"
						.. tostring(Game.GetCurrentGameTurn())
				);
			end
			if IsPolicyActive(playerID, LOTM_BE_CHAOS_III)
				or IsPolicyActive(playerID, LOTM_BE_CORRUPTION_III)
				or IsPolicyActive(playerID, LOTM_BE_FRENZY_II) then
				LOTM_RP_State.TryAddDigestion(
					playerID, "B", "SEQUENCE1_POLICY_ACTIVE:"
						.. tostring(Game.GetCurrentGameTurn())
				);
			end
		end
	end
end

local function OnCityBuilt(playerID :number, cityID :number)
	if IsBlackEmperor(playerID) then
		GrantFirstCityReward(playerID);
	end
end

local function OnUnitAddedToMap(playerID :number, unitID :number)
	if IsBlackEmperor(playerID) and GetSequence(playerID) <= 8 then
		CorrectLegacyBuilderBaseStrength(playerID);
	end
end

local function OnCivicCompleted(playerID :number, civicIndex :number, isCanceled :boolean)
	if IsBlackEmperor(playerID) and GetSequence(playerID) == 9 and not isCanceled then
		local player = GetPlayer(playerID);
		local civic = GameInfo.Civics[LOTM_BE_CODE_OF_LAWS];
		if player ~= nil and civic ~= nil and civic.Index == civicIndex
			and player:GetProperty(P.AutomaticCivicTurn) == Game.GetCurrentGameTurn() then
			return;
		end
		AddDigestion(
			playerID,
			"A",
			"CIVIC_COMPLETED:" .. tostring(civicIndex),
			3
		);
	end
end

local function OnResearchCompleted(playerID :number, techIndex :number, isCanceled :boolean)
	if IsBlackEmperor(playerID) and GetSequence(playerID) == 5 and not isCanceled then
		LOTM_RP_State.TryAddDigestion(
			playerID,
			"B",
			"TECH_COMPLETED:" .. tostring(techIndex)
		);
	end
end

local function OnCityPopulationChanged(playerID :number, cityID :number, changeAmount :number)
	if IsBlackEmperor(playerID) and GetSequence(playerID) == 4
		and (changeAmount or 0) > 0 then
		LOTM_RP_State.TryAddDigestion(
			playerID,
			"A",
			"POPULATION_GROWTH:" .. tostring(Game.GetCurrentGameTurn())
				.. ":" .. tostring(cityID) .. ":" .. tostring(changeAmount)
		);
	end
end

local function IsLoyaltyTransfer(city)
	if city == nil or CityTransferTypes == nil then
		return false;
	end
	local transferType = city:GetLastTransferType();
	return transferType ~= nil and (
		(CityTransferTypes.BY_CULTURAL_IDENTITY ~= nil
			and transferType == CityTransferTypes.BY_CULTURAL_IDENTITY)
		or (CityTransferTypes.BY_LOYALTY ~= nil
			and transferType == CityTransferTypes.BY_LOYALTY)
	);
end

local function ObserveTransferredCity(playerID :number, city, previousOwner, source :string)
	if city == nil then
		return false;
	end
	local plot = Map.GetPlot(city:GetX(), city:GetY());
	if plot == nil then
		return false;
	end
	local currentOwner = city:GetOwner();
	local awardKey = tostring(previousOwner) .. ":" .. tostring(currentOwner)
		.. ":" .. tostring(Game.GetCurrentGameTurn());
	local shouldAward = previousOwner ~= nil and previousOwner ~= currentOwner
		and currentOwner == playerID
		and IsBlackEmperor(playerID) and GetSequence(playerID) == 2
		and IsLoyaltyTransfer(city)
		and plot:GetProperty(LOTM_BE_CITY_TRANSFER_AWARD_PROPERTY) ~= awardKey;
	plot:SetProperty(LOTM_BE_CITY_OWNER_PROPERTY, currentOwner);
	if not shouldAward then
		return false;
	end
	plot:SetProperty(LOTM_BE_CITY_TRANSFER_AWARD_PROPERTY, awardKey);
	local added = AddDigestion(
		playerID,
		"A",
		"LOYALTY_CITY_TRANSFER:" .. tostring(plot:GetIndex())
			.. ":" .. awardKey,
		3
	);
	Log("loyalty city transfer player=" .. tostring(playerID)
		.. " city=" .. tostring(city:GetID())
		.. " plot=" .. tostring(plot:GetIndex())
		.. " oldOwner=" .. tostring(previousOwner)
		.. " source=" .. tostring(source)
		.. " added=" .. tostring(added));
	return added > 0;
end

ScanCityOwnership = function(allowAwards :boolean)
	local currentTurn = Game.GetCurrentGameTurn();
	if allowAwards and Game:GetProperty(LOTM_BE_CITY_SCAN_TURN_PROPERTY) == currentTurn then
		return;
	end
	for _, ownerID in ipairs(PlayerManager.GetAliveIDs()) do
		local owner = GetPlayer(ownerID);
		if owner ~= nil then
			for _, city in owner:GetCities():Members() do
				local plot = Map.GetPlot(city:GetX(), city:GetY());
				if plot ~= nil then
					local previousOwner = plot:GetProperty(LOTM_BE_CITY_OWNER_PROPERTY);
					if allowAwards and previousOwner ~= nil and previousOwner ~= ownerID then
						ObserveTransferredCity(ownerID, city, previousOwner, "turn-scan");
					else
						plot:SetProperty(LOTM_BE_CITY_OWNER_PROPERTY, ownerID);
					end
				end
			end
		end
	end
	if allowAwards then
		Game:SetProperty(LOTM_BE_CITY_SCAN_TURN_PROPERTY, currentTurn);
	end
end

local function OnCityTransfered(playerID :number, cityID :number)
	local player = GetPlayer(playerID);
	local city = player ~= nil and player:GetCities():FindID(cityID) or nil;
	if city == nil then
		return;
	end
	local plot = Map.GetPlot(city:GetX(), city:GetY());
	local previousOwner = plot ~= nil
		and plot:GetProperty(LOTM_BE_CITY_OWNER_PROPERTY) or nil;
	ObserveTransferredCity(playerID, city, previousOwner, "event");
end

local function IsDefeatedUnit(unitID :number, unit)
	return unitID ~= nil and unitID >= 0
		and (unit == nil or unit:IsDead() or unit:IsDelayedDeath());
end

local function OnCombatOccurred(
	attackerPlayerID :number,
	attackerUnitID :number,
	defenderPlayerID :number,
	defenderUnitID :number
)
	local attackerPlayer = GetPlayer(attackerPlayerID);
	local attacker = attackerPlayer ~= nil
		and attackerPlayer:GetUnits():FindID(attackerUnitID) or nil;
	local defenderPlayer = GetPlayer(defenderPlayerID);
	local defender = defenderPlayer ~= nil
		and defenderPlayer:GetUnits():FindID(defenderUnitID) or nil;
	if IsBlackEmperor(attackerPlayerID) and GetSequence(attackerPlayerID) == 8
		and IsDefeatedUnit(defenderUnitID, defender) then
		AddDigestion(
			attackerPlayerID,
			"A",
			"KILL:" .. tostring(Game.GetCurrentGameTurn()) .. ":"
				.. tostring(attackerUnitID) .. ":" .. tostring(defenderPlayerID)
				.. ":" .. tostring(defenderUnitID),
			2
		);
	elseif IsBlackEmperor(defenderPlayerID) and GetSequence(defenderPlayerID) == 8
		and IsDefeatedUnit(attackerUnitID, attacker) then
		AddDigestion(
			defenderPlayerID,
			"A",
			"KILL:" .. tostring(Game.GetCurrentGameTurn()) .. ":"
				.. tostring(defenderUnitID) .. ":" .. tostring(attackerPlayerID)
				.. ":" .. tostring(attackerUnitID),
			2
		);
	end
end

local function OnPillage(
	playerID :number,
	unitID :number,
	improvementType :number,
	buildingType :number,
	districtType :number,
	plotIndex :number
)
	if IsBlackEmperor(playerID) and GetSequence(playerID) == 8 then
		LOTM_RP_State.TryAddDigestion(
			playerID,
			"B",
			"PILLAGE:" .. tostring(Game.GetCurrentGameTurn()) .. ":"
				.. tostring(unitID) .. ":" .. tostring(plotIndex)
		);
	end
end

local function IsCommercialOrHarborDistrict(districtType :string)
	return districtType == "DISTRICT_COMMERCIAL_HUB"
		or districtType == "DISTRICT_HARBOR";
end

local function OnDistrictConstructed(
	playerID :number,
	districtType :number,
	x :number,
	y :number
)
	if not IsBlackEmperor(playerID) or GetSequence(playerID) ~= 6 then
		return;
	end
	local info = GameInfo.Districts[districtType];
	if info ~= nil and IsCommercialOrHarborDistrict(info.DistrictType) then
		LOTM_RP_State.TryAddDigestion(
			playerID,
			"A",
			"DISTRICT:" .. tostring(Game.GetCurrentGameTurn()) .. ":"
				.. tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(districtType)
		);
	end
end

local function OnBuildingConstructed(
	playerID :number,
	cityID :number,
	buildingIndex :number,
	plotIndex :number,
	isOriginalConstruction :boolean
)
	if not IsBlackEmperor(playerID) or GetSequence(playerID) ~= 6
		or not isOriginalConstruction then
		return;
	end
	local building = GameInfo.Buildings[buildingIndex];
	if building ~= nil and IsCommercialOrHarborDistrict(building.PrereqDistrict) then
		LOTM_RP_State.TryAddDigestion(
			playerID,
			"A",
			"BUILDING:" .. tostring(cityID) .. ":" .. tostring(buildingIndex)
		);
	end
end

local function FindOutgoingRoute(playerID :number, parameters :table)
	local player = GetPlayer(playerID);
	if player == nil or parameters == nil then
		return nil;
	end
	for _, city in player:GetCities():Members() do
		for _, route in ipairs(city:GetTrade():GetOutgoingRoutes()) do
			if route.TraderUnitID == tonumber(parameters.TraderUnitID)
				and route.OriginCityID == tonumber(parameters.OriginCityID)
				and route.DestinationCityPlayer == tonumber(parameters.DestinationPlayerID)
				and route.DestinationCityID == tonumber(parameters.DestinationCityID) then
				return route;
			end
		end
	end
	return nil;
end

local function OnCommandTradeRouteStarted(playerID :number, parameters :table)
	local player = GetPlayer(playerID);
	local hasContract = false;
	if player ~= nil then
		for slot = 1, 9 do
			if player:GetProperty("LOTM_PP_ARTIFACT_SLOT_" .. tostring(slot))
				== "GREATWORK_LOTM_BE_GOLDEN_BRIBE" then
				hasContract = true;
				break;
			end
		end
	end
	local isBriber = IsBlackEmperor(playerID) and GetSequence(playerID) == 7;
	if not isBriber and not hasContract then
		return;
	end
	local route = FindOutgoingRoute(playerID, parameters);
	if route == nil then
		Log("rejected stale trade-route command player=" .. tostring(playerID));
		return;
	end
	local routeKey = tostring(Game.GetCurrentGameTurn()) .. ":"
		.. tostring(route.TraderUnitID) .. ":" .. tostring(route.OriginCityID)
		.. ":" .. tostring(route.DestinationCityPlayer) .. ":"
		.. tostring(route.DestinationCityID);
	if isBriber then
		LOTM_RP_State.TryAddDigestion(playerID, "A", "TRADE_ROUTE:" .. routeKey);
	end

	local destination = GetPlayer(route.DestinationCityPlayer);
	local destinationInfluence = destination ~= nil and destination:GetInfluence() or nil;
	if destination ~= nil and destinationInfluence ~= nil
		and destinationInfluence:CanReceiveInfluence() then
		GetPlayer(playerID):GetInfluence():GiveFreeTokenToPlayer(route.DestinationCityPlayer);
		if isBriber then
			LOTM_RP_State.TryAddDigestion(playerID, "B", "TRADE_ENVOY:" .. routeKey);
		end
		RefreshEnvoyBaseline(playerID, false);
	end
end

local function OnCommandGoldPurchase(playerID :number, parameters :table)
	if not IsBlackEmperor(playerID) or GetSequence(playerID) ~= 6 then
		return;
	end
	local kind = parameters ~= nil and tostring(parameters.Kind or "") or "";
	if kind ~= "UNIT" and kind ~= "BUILDING" and kind ~= "GREAT_PERSON" then
		return;
	end
	local serial = parameters ~= nil and tostring(parameters.Serial or "") or "";
	if serial == "" then
		return;
	end
	if kind == "GREAT_PERSON" then
		local individualID = tonumber(parameters.IndividualID);
		local goldCost = tonumber(parameters.GoldCost);
		local goldSpent = tonumber(parameters.GoldSpent);
		local greatPeople = Game.GetGreatPeople();
		local confirmed = false;
		if individualID ~= nil and goldCost ~= nil and goldCost > 0
			and goldSpent == goldCost and greatPeople ~= nil then
			for _, entry in ipairs(greatPeople:GetPastTimeline()) do
				if entry.Individual == individualID and entry.Claimant == playerID then
					confirmed = true;
					break;
				end
			end
		end
		if not confirmed then
			Log("rejected unconfirmed Great Person purchase player=" .. tostring(playerID));
			return;
		end
	end
	LOTM_RP_State.TryAddDigestion(
		playerID,
		"B",
		"GOLD_PURCHASE:" .. kind .. ":" .. serial
	);
end

local function OnInfluenceChanged(playerID :number)
	if playerID ~= nil and playerID >= 0 then
		RefreshEnvoyBaseline(playerID, true);
		return;
	end
	for _, majorID in ipairs(PlayerManager.GetAliveMajorIDs()) do
		RefreshEnvoyBaseline(majorID, true);
	end
end

local function OnCityProjectCompleted(playerID :number, cityID :number, projectID :number)
	if not IsBlackEmperor(playerID) then
		return;
	end
	local projectType :string = nil;
	local expectedSequence :number = nil;
	local nextSequence :number = nil;
	local barbarian = GameInfo.Projects["PROJECT_LOTM_BE_BARBARIAN_POTION"];
	local briber = GameInfo.Projects["PROJECT_LOTM_BE_BRIBER_POTION"];
	local baron = GameInfo.Projects["PROJECT_LOTM_BE_BARON_OF_CORRUPTION_POTION"];
	local chaosMentor = GameInfo.Projects["PROJECT_LOTM_BE_CHAOS_MENTOR_POTION"];
	local countOfCorruption = GameInfo.Projects["PROJECT_LOTM_BE_COUNT_OF_CORRUPTION_POTION"];
	local frenzyMage = GameInfo.Projects["PROJECT_LOTM_BE_FRENZY_MAGE_POTION"];
	local dukeOfEntropy = GameInfo.Projects["PROJECT_LOTM_BE_DUKE_OF_ENTROPY_POTION"];
	local princeOfAbolition = GameInfo.Projects["PROJECT_LOTM_BE_PRINCE_OF_ABOLITION_POTION"];
	local enthronement = GameInfo.Projects["PROJECT_LOTM_BE_ENTHRONEMENT"];
	local unconsecratedEnthronement =
		GameInfo.Projects["PROJECT_LOTM_BE_ENTHRONEMENT_UNCONSECRATED"];
	local allowWithoutChurch :boolean = false;
	if barbarian ~= nil and barbarian.Index == projectID then
		projectType, expectedSequence, nextSequence =
			"PROJECT_LOTM_BE_BARBARIAN_POTION", 9, 8;
	elseif briber ~= nil and briber.Index == projectID then
		projectType, expectedSequence, nextSequence =
			"PROJECT_LOTM_BE_BRIBER_POTION", 8, 7;
	elseif baron ~= nil and baron.Index == projectID then
		projectType, expectedSequence, nextSequence =
			"PROJECT_LOTM_BE_BARON_OF_CORRUPTION_POTION", 7, 6;
	elseif chaosMentor ~= nil and chaosMentor.Index == projectID then
		projectType, expectedSequence, nextSequence =
			"PROJECT_LOTM_BE_CHAOS_MENTOR_POTION", 6, 5;
	elseif countOfCorruption ~= nil and countOfCorruption.Index == projectID then
		projectType, expectedSequence, nextSequence =
			"PROJECT_LOTM_BE_COUNT_OF_CORRUPTION_POTION", 5, 4;
	elseif frenzyMage ~= nil and frenzyMage.Index == projectID then
		projectType, expectedSequence, nextSequence =
			"PROJECT_LOTM_BE_FRENZY_MAGE_POTION", 4, 3;
	elseif dukeOfEntropy ~= nil and dukeOfEntropy.Index == projectID then
		projectType, expectedSequence, nextSequence =
			"PROJECT_LOTM_BE_DUKE_OF_ENTROPY_POTION", 3, 2;
	elseif princeOfAbolition ~= nil and princeOfAbolition.Index == projectID then
		projectType, expectedSequence, nextSequence =
			"PROJECT_LOTM_BE_PRINCE_OF_ABOLITION_POTION", 2, 1;
	elseif enthronement ~= nil and enthronement.Index == projectID then
		projectType, expectedSequence, nextSequence =
			"PROJECT_LOTM_BE_ENTHRONEMENT", 1, 0;
	elseif unconsecratedEnthronement ~= nil
		and unconsecratedEnthronement.Index == projectID then
		projectType, expectedSequence, nextSequence =
			"PROJECT_LOTM_BE_ENTHRONEMENT_UNCONSECRATED", 1, 0;
		allowWithoutChurch = true;
	else
		return;
	end
	if not LOTM_RP_State.AdvanceSequence(
		playerID,
		expectedSequence,
		nextSequence,
		allowWithoutChurch
	) then
		Log("rejected project transition player=" .. tostring(playerID)
			.. " project=" .. projectType);
	end
end

local function Initialize()
	Events.PlayerTurnActivated.Add(OnPlayerTurnActivated);
	Events.UnitAddedToMap.Add(LOTM_UnitAddedPerf.Wrap("BlackEmperor",OnUnitAddedToMap));
	GameEvents.CityBuilt.Add(OnCityBuilt);
	Events.CivicCompleted.Add(OnCivicCompleted);
	Events.ResearchCompleted.Add(OnResearchCompleted);
	GameEvents.OnCityPopulationChanged.Add(OnCityPopulationChanged);
	if Events.CityTransfered ~= nil then
		Events.CityTransfered.Add(OnCityTransfered);
	else
		Log("warning: CityTransfered event unavailable; using turn-scan loyalty fallback only");
	end
	Events.InfluenceChanged.Add(OnInfluenceChanged);
	GameEvents.OnDistrictConstructed.Add(OnDistrictConstructed);
	Events.CityProjectCompleted.Add(OnCityProjectCompleted);
	GameEvents.OnCombatOccurred.Add(OnCombatOccurred);
	GameEvents.OnPillage.Add(OnPillage);
	GameEvents.BuildingConstructed.Add(OnBuildingConstructed);
	GameEvents.LOTM_BE_Command_TradeRouteStarted.Add(OnCommandTradeRouteStarted);
	GameEvents.LOTM_BE_Command_GoldPurchase.Add(OnCommandGoldPurchase);
	ScanCityOwnership(false);
	for _, playerID in ipairs(PlayerManager.GetAliveMajorIDs()) do
		if IsBlackEmperor(playerID) then
			LOTM_BE_RefreshSequenceState(playerID);
		end
	end
	Log("initialized sequences 9-0");
end

Initialize();
-- END RC241 MODULE: Scripts/LOTM_BE_BlackEmperor.lua
end;

m_mp241Loaders["LOTM_DEV_QuickTest"] = function()
-- BEGIN RC241 MODULE: Scripts/LOTM_DEV_QuickTest.lua
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("MP.LOTM_DEV_QuickTest","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"MP.LOTM_DEV_QuickTest","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"MP.LOTM_DEV_QuickTest","GameEvents");
-- END RC342 STARTUP TRACE

-- Optional synchronized new-game test setup.
-- Production default: disabled.  Change only ENABLED and PROFILE when building
-- a disposable local test package; never publish or use it in multiplayer.

local ENABLED :boolean = false;
local PROFILE :string = "GOLDEN_BRIBE";

local MARKER_PREFIX :string = "LOTM_DEV_QUICK_TEST_APPLIED_";
local BLACK_EMPEROR_PATH :string = "PATH_BLACK_EMPEROR";
local BE_FIRST_CITY_GRANTED :string = "LOTM_BE_FIRST_CITY_REWARD_GRANTED";
local BE_WILDCARD_ATTACHED :string = "LOTM_BE_WILDCARD_SLOT_ATTACHED";
local BE_AUTOMATIC_CIVIC_TURN :string = "LOTM_BE_AUTOMATIC_CIVIC_TURN";
local BE_CIVIC_SCORING_MIGRATED :string = "LOTM_BE_CIVIC_SCORING_V2_MIGRATED";

local function Log(message)
 print("[LOTM_DEV][QuickTest] "..tostring(message));
end

local function Human(playerID)
 local player=Players[playerID];
 return player~=nil and player:IsAlive() and player:IsMajor() and player:IsHuman() and player or nil;
end

local function ResetDigestion(player)
 player:SetProperty("LOTM_RP_DIGEST_A",0); player:SetProperty("LOTM_RP_DIGEST_B",0);
 player:SetProperty("LOTM_RP_DIGEST_TURN",-1); player:SetProperty("LOTM_RP_DIGEST_TURN_GAIN",0);
end

local function PrimeBlackEmperorFoundation(player)
 local playerID=player:GetID(); local culture=player:GetCulture();
 local civic=GameInfo.Civics["CIVIC_CODE_OF_LAWS"];
 if culture==nil or civic==nil then
  Log("waiting for Black Emperor foundation player="..playerID); return false;
 end
 player:SetProperty(BE_AUTOMATIC_CIVIC_TURN,Game.GetCurrentGameTurn());
 if not culture:HasCivic(civic.Index) then
  culture:SetCulturalProgress(civic.Index,culture:GetCultureCost(civic.Index));
  if not culture:HasCivic(civic.Index) then culture:SetCivic(civic.Index,true); end
 end
 if not culture:HasCivic(civic.Index) then
  Log("waiting for Code of Laws player="..playerID); return false;
 end
 LOTM_RP_State.AttachModifierOnce(
  playerID,"LOTM_BE_MOD_RULES_WILDCARD_SLOT",BE_WILDCARD_ATTACHED
 );
 player:SetProperty(BE_FIRST_CITY_GRANTED,1);
 player:SetProperty(BE_CIVIC_SCORING_MIGRATED,1);
 return (player:GetProperty(BE_WILDCARD_ATTACHED) or 0)==1;
end

local function VerifyBlackEmperorState(player,sequence)
 local playerID=player:GetID();
 local valid=LOTM_RP_State.IsBlackEmperorPlayer(playerID)
  and LOTM_RP_State.GetSequence(playerID)==sequence
  and (player:GetProperty(BE_FIRST_CITY_GRANTED) or 0)==1
  and (player:GetProperty(BE_WILDCARD_ATTACHED) or 0)==1;
 if sequence<=8 then
  valid=valid and (player:GetProperty("LOTM_BE_MIGHT_STRENGTH_V2_ATTACHED") or 0)==1
   and (player:GetProperty("LOTM_BE_MIGHT_MOVEMENT_ATTACHED") or 0)==1;
 end
 if sequence<=7 then
  valid=valid and (player:GetProperty("LOTM_BE_TRADE_GOLD_ATTACHED") or 0)==1;
 end
 if sequence<=6 then
  valid=valid and (player:GetProperty("LOTM_BE_WEALTH_ATTACHED") or 0)==1;
 end
 Log("verified player="..playerID.." path="..tostring(player:GetProperty("LOTM_RP_PATH"))
  .." sequence="..tostring(LOTM_RP_State.GetSequence(playerID))
  .." foundation="..tostring(player:GetProperty(BE_FIRST_CITY_GRANTED))
  .." might="..tostring(player:GetProperty("LOTM_BE_MIGHT_STRENGTH_V2_ATTACHED"))
  .." movement="..tostring(player:GetProperty("LOTM_BE_MIGHT_MOVEMENT_ATTACHED"))
  .." trade="..tostring(player:GetProperty("LOTM_BE_TRADE_GOLD_ATTACHED"))
  .." wealth="..tostring(player:GetProperty("LOTM_BE_WEALTH_ATTACHED"))
  .." valid="..tostring(valid));
 return valid;
end

local function ConfigureBlackEmperor(player,sequence)
 local playerID=player:GetID(); local decided=player:GetProperty("LOTM_RP_PATH_DECIDED") or 0;
 local path=player:GetProperty("LOTM_RP_PATH");
 if decided==1 and path~=BLACK_EMPEROR_PATH then
  Log("refused to overwrite existing path player="..playerID.." path="..tostring(path)); return false;
 end
 LOTM_RP_State.EnsurePlayerState(playerID);
 player:SetProperty("LOTM_RP_PATH",BLACK_EMPEROR_PATH); player:SetProperty("LOTM_RP_PATH_DECIDED",1);
 -- Recreate the complete normal foundation before jumping to the requested
 -- sequence.  Doing this after the jump would incorrectly award the initial
 -- Code of Laws digestion to Sequence 6.
 LOTM_RP_State.SetSequence(playerID,9); ResetDigestion(player);
 if not PrimeBlackEmperorFoundation(player) then return false; end
 LOTM_RP_State.SetSequence(playerID,sequence); ResetDigestion(player);
 LOTM_RP_State.EnsureHero(playerID);
 if LOTM_BE_RefreshSequenceState~=nil then LOTM_BE_RefreshSequenceState(playerID);
 elseif LOTM_BE_OnPathSelected~=nil then LOTM_BE_OnPathSelected(playerID); end
 ResetDigestion(player);
 return VerifyBlackEmperorState(player,sequence);
end

local function AddTestGold(player,amount)
 local key="LOTM_DEV_QUICK_TEST_GOLD_"..PROFILE;
 if (player:GetProperty(key) or 0)~=1 then
  player:GetTreasury():ChangeGoldBalance(amount); player:SetProperty(key,1);
 end
end

local function PrimeForeignCityLoyalty(player)
 local best=nil; local bestDistance=nil; local capital=player:GetCities():GetCapitalCity();
 if capital==nil then return false; end
 for _,otherID in ipairs(PlayerManager.GetAliveMajorIDs()) do
  if otherID~=player:GetID() then
   local other=Players[otherID];
   if other~=nil then for _,city in other:GetCities():Members() do
    local distance=Map.GetPlotDistance(capital:GetX(),capital:GetY(),city:GetX(),city:GetY());
    if bestDistance==nil or distance<bestDistance then best=city; bestDistance=distance; end
   end end
  end
 end
 if best==nil then return false; end
 local identity=best:GetCulturalIdentity(); local loyalty=identity~=nil and identity:GetLoyalty() or nil;
 if loyalty~=nil and loyalty>1 then best:ChangeLoyalty(1-loyalty); end
 player:SetProperty("LOTM_DEV_QUICK_TEST_LOYALTY_TARGET_OWNER",best:GetOwner());
 player:SetProperty("LOTM_DEV_QUICK_TEST_LOYALTY_TARGET_CITY",best:GetID());
 Log("primed loyalty target owner="..best:GetOwner().." city="..best:GetID().." distance="..tostring(bestDistance));
 return true;
end

local function ConfigureChurchRecheck(player)
 -- Jump directly to the tier-15 pending state.  The official church turn
 -- reconciler will either select a real high-tier target or schedule +5 turns.
 player:SetProperty("LOTM_CHURCH_NIGHT_ENVOYS",15);
 player:SetProperty("LOTM_CHURCH_NIGHT_ACTIVE_TIER",15);
 player:SetProperty("LOTM_CHURCH_NIGHT_QUEST_6_STATE","COMPLETED_SELF");
 player:SetProperty("LOTM_CHURCH_NIGHT_QUEST_6_REWARD_APPLIED",1);
 player:SetProperty("LOTM_CHURCH_NIGHT_QUEST_10_STATE","COMPLETED_SELF");
 player:SetProperty("LOTM_CHURCH_NIGHT_QUEST_10_REWARD_APPLIED",1);
 player:SetProperty("LOTM_CHURCH_NIGHT_QUEST_15_STATE","PENDING_TARGET");
 player:SetProperty("LOTM_CHURCH_NIGHT_TARGET_KIND",nil);
 player:SetProperty("LOTM_CHURCH_NIGHT_TARGET_ID",nil);
 player:SetProperty("LOTM_CHURCH_NIGHT_NEXT_RECHECK",0);
 return true;
end

local function Configure(playerID)
 if not ENABLED then return; end
 local player=Human(playerID); if player==nil then return; end
 local marker=MARKER_PREFIX..PROFILE; if (player:GetProperty(marker) or 0)==1 then return; end
 local applied=false;
 if PROFILE=="BLACK_EMPEROR_S6_PURCHASE" then
  applied=ConfigureBlackEmperor(player,6); if applied then AddTestGold(player,10000); end
 elseif PROFILE=="BLACK_EMPEROR_S2_LOYALTY" then
  applied=ConfigureBlackEmperor(player,2) and PrimeForeignCityLoyalty(player);
 elseif PROFILE=="GOLDEN_BRIBE" then
  applied=ConfigureBlackEmperor(player,2);
  if applied then
   AddTestGold(player,10000);
   applied=LOTM_PP_QuickTestGrantAndEquip~=nil
    and LOTM_PP_QuickTestGrantAndEquip(playerID,"GREATWORK_LOTM_BE_GOLDEN_BRIBE",1);
  end
 elseif PROFILE=="CHURCH_TIER15_RECHECK" then
  applied=ConfigureChurchRecheck(player);
 else
  Log("unknown profile="..tostring(PROFILE)); return;
 end
 if applied then player:SetProperty(marker,1); Log("applied profile="..PROFILE.." player="..playerID); end
end

local function ConfigureAll()
 if not ENABLED then return; end
 for _,playerID in ipairs(PlayerManager.GetAliveMajorIDs()) do Configure(playerID); end
end

if ENABLED then
 Events.PlayerTurnActivated.Add(function(playerID,isFirstTime) if isFirstTime~=false then Configure(playerID); end end);
 ConfigureAll();
 Log("ENABLED profile="..PROFILE.."; local disposable test build only");
end
-- END RC241 MODULE: Scripts/LOTM_DEV_QuickTest.lua
end;

m_mp241Loaders["LOTM_Effects"] = function()
-- BEGIN POST_RC241_NEW MODULE: Scripts/LOTM_Effects.lua
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("MP.LOTM_Effects","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"MP.LOTM_Effects","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"MP.LOTM_Effects","GameEvents");
-- END RC342 STARTUP TRACE

-- Shared effect arithmetic and idempotent unit ability updates.
-- This module owns no events, player selection, Properties or scans. Callers
-- retain their mode gates and invoke mutations only from synchronized Gameplay.
LOTM_Effects = LOTM_Effects or {};
LOTM_Effects.VERSION = 1;

-- Percent is expressed as 50 for 50%, never 0.5. Keep the multiplier first:
-- base * (percent / 100) preserves the existing floating-point rounding used
-- by 10%, 20% and 50% effects. The caller decides whether to aggregate sources
-- before this operation; floor(sum * p) and sum(floor(source * p)) differ.
function LOTM_Effects.PercentFloor(base, percent)
 local positiveBase = math.max(0, tonumber(base) or 0);
 return math.floor(positiveBase * ((tonumber(percent) or 0) / 100));
end

-- A treasury may expose a fractional balance. Cap AFTER rounding the yield
-- share, without rounding the balance, as the existing gold transfer does.
function LOTM_Effects.CappedPercentFloor(base, percent, available)
 return math.min(math.max(0, tonumber(available) or 0),
  LOTM_Effects.PercentFloor(base, percent));
end

-- Only issue a native write when the exact desired count differs. No cached
-- count or Property can substitute for the unit's authoritative ability state.
-- Returns whether a write was requested; callers needing confirmed success
-- must retain their native readback (a native write can silently be refused).
function LOTM_Effects.SetAbilityCount(abilities, abilityType, desired)
 if abilities == nil then return false; end
 local current = abilities:GetAbilityCount(abilityType) or 0;
 if current == desired then return false; end
 abilities:ChangeAbilityCount(abilityType, desired - current);
 return true;
end

-- Tiers are the caller's small, ordered {value, abilityType} definition array.
-- The first matching tier is selected. A nil/unknown value clears the group.
-- An optional database table skips abilities absent in the active game mode.
-- Iteration order is stable, including removal of legacy stacked counts.
function LOTM_Effects.SyncAbilityTiers(abilities, tiers, selectedValue, definitions)
 local selected = nil;
 for _, entry in ipairs(tiers) do
  if entry[1] == selectedValue then selected = entry[2]; break; end
 end
 local changed = 0;
 for _, entry in ipairs(tiers) do
  local abilityType = entry[2];
  if definitions == nil or definitions[abilityType] ~= nil then
   if LOTM_Effects.SetAbilityCount(abilities, abilityType,
    abilityType == selected and 1 or 0) then changed = changed + 1; end
  end
 end
 return selected, changed;
end
-- END POST_RC241_NEW MODULE: Scripts/LOTM_Effects.lua
end;

m_mp241Loaders["LOTM_MP241_Compat"] = function()
-- BEGIN POST_RC241_NEW MODULE: Scripts/LOTM_MP241_Compat.lua
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("MP.LOTM_MP241_Compat","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"MP.LOTM_MP241_Compat","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"MP.LOTM_MP241_Compat","GameEvents");
-- END RC342 STARTUP TRACE

-- Multiplayer-only compatibility surface for features added after rc.241.
--
-- The rc.241 Gameplay modules keep their original event registrations and do
-- not call this adapter.  Only post-rc.241 modules use these helpers.  In
-- particular, this file does not install a shared turn dispatcher. Each new
-- handler registers directly on GameEvents.PlayerTurnStarted; client-local
-- activation notifications must not write authoritative state in multiplayer.

LOTM_MP_TurnSync = LOTM_MP_TurnSync or {};
LOTM_MP_TurnSync.VERSION = 241;
LOTM_MP_TurnSync._wrappers = LOTM_MP_TurnSync._wrappers or {};
LOTM_MP_TurnSync._startupWrappers = LOTM_MP_TurnSync._startupWrappers or {};
LOTM_MP_TurnSync._registered = LOTM_MP_TurnSync._registered or {};
LOTM_MP_TurnSync._startups = LOTM_MP_TurnSync._startups or {};

local STABLE_MODULUS = 2147483647;

local function NormalizeStableValue(value)
	local numeric = tonumber(value);
	if numeric == nil then
		local result = 0;
		local source = tostring(value or "");
		for index = 1, #source do
			result = (result * 131 + string.byte(source,index)) % STABLE_MODULUS;
		end
		return result;
	end
	numeric = math.floor(numeric) % STABLE_MODULUS;
	if numeric < 0 then numeric = numeric + STABLE_MODULUS; end
	return numeric;
end

local function MixStableValue(value,component)
	return (NormalizeStableValue(value) * 48271
		+ NormalizeStableValue(component) + 1) % STABLE_MODULUS;
end

local function StableSeed()
	local gameSeed = GameConfiguration ~= nil
		and GameConfiguration.GetValue ~= nil
		and GameConfiguration.GetValue("GAME_SYNC_RANDOM_SEED") or 0;
	local mapSeed = MapConfiguration ~= nil
		and MapConfiguration.GetValue ~= nil
		and MapConfiguration.GetValue("RANDOM_SEED") or nil;
	if mapSeed == nil and GameConfiguration ~= nil
		and GameConfiguration.GetValue ~= nil then
		mapSeed = GameConfiguration.GetValue("MAP_RANDOM_SEED");
	end
	return MixStableValue(MixStableValue(104729,gameSeed),mapSeed or 0);
end

function LOTM_MP_TurnSync.IsNetworkGame()
	return GameConfiguration ~= nil
		and GameConfiguration.IsAnyMultiplayer ~= nil
		and GameConfiguration.IsAnyMultiplayer() == true;
end

function LOTM_MP_TurnSync.IsRescueModeConfigured()
	if GameInfo ~= nil and GameInfo.Resources ~= nil
		and GameInfo.Resources["RESOURCE_LOTM_RESCUE_ALLY_BANNER"] ~= nil then
		return true;
	end
	local configured = GameConfiguration ~= nil
		and GameConfiguration.GetValue ~= nil
		and GameConfiguration.GetValue("GAMEMODE_LOTM_RESCUE") or nil;
	return configured == true or tonumber(configured or 0) == 1;
end

function LOTM_MP_TurnSync.Random(maxExclusive,label,legacyLabel)
	local limit = math.floor(tonumber(maxExclusive) or 0);
	if limit <= 0 then return 0; end
	if limit == 1 then return 0; end
	local turn = Game ~= nil and Game.GetCurrentGameTurn ~= nil
		and Game.GetCurrentGameTurn() or 0;
	local value = MixStableValue(StableSeed(),turn);
	value = MixStableValue(value,label or legacyLabel or "LOTM_MP241");
	value = MixStableValue(value,limit);
	return value % limit;
end

function LOTM_MP_TurnSync.GetStableAnchorPlayerID()
	local best = nil;
	for _,player in ipairs(PlayerManager.GetAliveMajors() or {}) do
		local playerID = player:GetID();
		if best == nil or playerID < best then best = playerID; end
	end
	return best or -1;
end

function LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID)
	return tonumber(playerID) == LOTM_MP_TurnSync.GetStableAnchorPlayerID();
end

local function Guarded(handler,label,playerID,isFirstTimeThisTurn)
	local ok,details = pcall(handler,playerID,isFirstTimeThisTurn);
	if not ok then
		print("[LOTM][MP241Compat] handler failed label="..tostring(label)
			.." details="..tostring(details));
	end
	return ok;
end

local function RunStartupEntry(entry)
	if entry == nil then return true; end
	if entry.State ~= "WAITING" then return entry.State ~= "FAILED"; end
	-- Reserve first; a partially applied startup must never run twice.
	entry.State = "RUNNING";
	local ok,details = pcall(entry.Handler);
	-- A false result is a completed reconciliation with no applicable content
	-- (e.g. Thief's thiefFound=false), not permission for an unbounded rescan.
	-- The former immediate adapter also ran these handlers only once per load.
	entry.State = ok and "DONE" or "FAILED";
	if not ok then
		print("[LOTM][MP241Compat] startup failed label="..tostring(entry.Label)
			.." details="..tostring(details));
	end
	return ok;
end

local function RegisterSynchronized(handler,label)
	if type(handler) ~= "function" or GameEvents == nil
		or GameEvents.PlayerTurnStarted == nil then return false; end
	-- All production callers supply stable, unique labels. The function key
	-- still provides context-local de-duplication for unlabeled callers.
	local key = label or handler;
	if LOTM_MP_TurnSync._registered[key] ~= nil then return false; end
	local lastTurns = {};
	local wrapper = function(playerID)
		local id = tonumber(playerID);
		if id == nil or id < 0 or id ~= math.floor(id) then return; end
		local turn = Game.GetCurrentGameTurn();
		if lastTurns[id] == turn then return; end
		local propertyKey = label ~= nil and ("LOTM_MP241_TURN_"..tostring(label).."_"..id) or nil;
		if propertyKey ~= nil and tonumber(Game.GetProperty(propertyKey) or -1) == turn then return; end
		-- Reserve before the callback and persist it before any native mutation.
		-- Re-entry and same-turn reload must not replay a partially applied turn.
		lastTurns[id] = turn;
		if propertyKey ~= nil then Game.SetProperty(propertyKey,turn); end
		if not RunStartupEntry(LOTM_MP_TurnSync._startups[key]) then return; end
		Guarded(handler,label,playerID,true);
	end;
	LOTM_MP_TurnSync._registered[key] = wrapper;
	LOTM_MP_TurnSync._wrappers[#LOTM_MP_TurnSync._wrappers + 1] = wrapper;
	GameEvents.PlayerTurnStarted.Add(wrapper);
	return true;
end

function LOTM_MP_TurnSync.Add(handler,label)
	return RegisterSynchronized(handler,label);
end

function LOTM_MP_TurnSync.AddSynchronized(handler,label)
	return RegisterSynchronized(handler,label);
end

function LOTM_MP_TurnSync.RunStartup(handler,label)
	if type(handler) ~= "function" or GameEvents == nil
		or GameEvents.PlayerTurnStarted == nil then return false; end
	local key = label or handler;
	if LOTM_MP_TurnSync._startups[key] ~= nil then return false; end
	local entry = { Handler=handler, Label=label, State="WAITING" };
	LOTM_MP_TurnSync._startups[key] = entry;
	LOTM_MP_TurnSync._startupWrappers[#LOTM_MP_TurnSync._startupWrappers + 1] = entry;
	-- A separate direct listener also restores startup-only modules on load.
	-- Matching turn callbacks invoke their startup first, regardless of order.
	GameEvents.PlayerTurnStarted.Add(function() RunStartupEntry(entry); end);
	return true;
end

-- Called only by the separate synchronized main-load command after include.
-- This startup-only pass has no recurring full-world dispatcher or scan.
function LOTM_MP_TurnSync.RunPendingStartups()
	local ok = true;
	for _,entry in ipairs(LOTM_MP_TurnSync._startupWrappers) do
		if not RunStartupEntry(entry) then ok = false; end
	end
	return ok;
end

-- The bridge records these IDs from synchronized PlayerTurnStarted events
-- before this bundle is loaded. Restore only this turn's missed callbacks;
-- persisted per-handler turn guards make a saved/repeated request idempotent.
function LOTM_MP_TurnSync.RunCurrentTurnCatchUp(playerIDs)
	local ordered = {}; local seen = {};
	for _,value in ipairs(playerIDs or {}) do
		local id = tonumber(value);
		if id ~= nil and id >= 0 and id == math.floor(id) and not seen[id] then
			seen[id] = true; ordered[#ordered + 1] = id;
		end
	end
	table.sort(ordered);
	for _,id in ipairs(ordered) do
		for _,wrapper in ipairs(LOTM_MP_TurnSync._wrappers) do wrapper(id); end
	end
end

print("[LOTM][MP241Compat] initialized version=241 directEvents=true synchronized=true unifiedDispatcher=false");
-- END POST_RC241_NEW MODULE: Scripts/LOTM_MP241_Compat.lua
end;

m_mp241Loaders["LOTM_PP_Artifacts"] = function()
-- BEGIN RC241 MODULE: Scripts/LOTM_PP_Artifacts.lua
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("MP.LOTM_PP_Artifacts","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"MP.LOTM_PP_Artifacts","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"MP.LOTM_PP_Artifacts","GameEvents");
-- END RC342 STARTUP TRACE

-- 完美者封印物：同步 GreatWork 授予、九装备槽、所有权复核和回合效果。

local COMMAND :string = "LOTM_PP_Command_Artifact";
local STORAGE_MODIFIER :string = "LOTM_PP_MOD_ARTIFACT_STORAGE_SLOTS";
local STORAGE_CLEANUP_MODIFIER :string = "LOTM_PP_MOD_ARTIFACT_STORAGE_CLEANUP";
local STORAGE_ATTACHED :string = "LOTM_PP_ARTIFACT_STORAGE_ATTACHED";
local STORAGE_CLEANED :string = "LOTM_PP_ARTIFACT_STORAGE_CLEANED";
local SLOT_PREFIX :string = "LOTM_PP_ARTIFACT_SLOT_";
local TURN_SETTLED :string = "LOTM_PP_ARTIFACT_TURN_SETTLED";
local LEASE_EFFECTS_ATTACHED :string = "LOTM_PP_ARTIFACT_LEASE76_EFFECTS_ATTACHED";
local POLARITY_EFFECTS_ATTACHED :string = "LOTM_PP_ARTIFACT_LEASE81_EFFECTS_ATTACHED";
local BRIBE_ZERO_EFFECTS_ATTACHED :string = "LOTM_PP_ARTIFACT_BRIBE_ZERO_118_ATTACHED";
local BRIBE_FIX_237_EFFECTS_ATTACHED :string = "LOTM_PP_ARTIFACT_BRIBE_FIX_237_ATTACHED";
local BRIBE_FIX_238_EFFECTS_ATTACHED :string = "LOTM_PP_ARTIFACT_BRIBE_FIX_238_ATTACHED";
local BRIBE_FIX_239_EFFECTS_ATTACHED :string = "LOTM_PP_ARTIFACT_BRIBE_FIX_239_ATTACHED";
local INSTANCE_PREFIX :string = "LOTM_PP_ARTIFACT_INSTANCE_";
local EXPECTED_TYPE :string = "LOTM_PP_ARTIFACT_EXPECTED_CREATED_TYPE";
local EXPECTED_TURN :string = "LOTM_PP_ARTIFACT_EXPECTED_CREATED_TURN";
local LETTER_TYPE :string = "GREATWORK_LOTM_RP_CONSPIRATOR_LETTER";
local LETTER_PEACE_RESOURCE :string = "RESOURCE_LOTM_RP_LETTER_PEACE_ACTIVE";
local LETTER_WAR_ACTIVE :string = "LOTM_RP_ART_LETTER_WAR_GOLD_ACTIVE";
local LETTER_PEACE_ACTIVE :string = "LOTM_RP_ART_LETTER_PEACE_PENALTY_ACTIVE";

local ARTIFACTS :table = {
  GREATWORK_LOTM_PP_GOLDEN_APPRAISAL_MIRROR={level=2,path="PP",resource="RESOURCE_LOTM_PP_ARTIFACT_GOLDEN_MIRROR",lease="RESOURCE_LOTM_ARTIFACT_LEASE_01"},
  GREATWORK_LOTM_PP_PERPETUAL_GEARBOX={level=2,path="PP",resource="RESOURCE_LOTM_PP_ARTIFACT_PERPETUAL_GEARBOX",lease="RESOURCE_LOTM_ARTIFACT_LEASE_02"},
  GREATWORK_LOTM_PP_ERROR_ASTROLABE={level=2,path="PP",resource="RESOURCE_LOTM_PP_ARTIFACT_ERROR_ASTROLABE",lease="RESOURCE_LOTM_ARTIFACT_LEASE_03"},
  GREATWORK_LOTM_PP_HERMES_FURNACE={level=1,path="PP",resource="RESOURCE_LOTM_PP_ARTIFACT_HERMES_FURNACE",lease="RESOURCE_LOTM_ARTIFACT_LEASE_04"},
  GREATWORK_LOTM_PP_MYSTERY_BLUEPRINT={level=1,path="PP",resource="RESOURCE_LOTM_PP_ARTIFACT_MYSTERY_BLUEPRINT",lease="RESOURCE_LOTM_ARTIFACT_LEASE_05"},
  GREATWORK_LOTM_PP_KNOWLEDGE_CASKET={level=0,path="PP",resource="RESOURCE_LOTM_PP_ARTIFACT_KNOWLEDGE_CASKET",lease="RESOURCE_LOTM_ARTIFACT_LEASE_06"},
  GREATWORK_LOTM_PP_CIVILIZATION_STELE={level=0,path="PP",resource="RESOURCE_LOTM_PP_ARTIFACT_CIVILIZATION_STELE",lease="RESOURCE_LOTM_ARTIFACT_LEASE_07"},
  GREATWORK_LOTM_RP_DISASTER_EMBER={level=2,path="RP",resource="RESOURCE_LOTM_RP_DISASTER_EMBER",lease="RESOURCE_LOTM_ARTIFACT_LEASE_08"},
  GREATWORK_LOTM_RP_CONSPIRATOR_LETTER={level=2,path="RP",resource="RESOURCE_LOTM_RP_CONSPIRATOR_LETTER",lease="RESOURCE_LOTM_ARTIFACT_LEASE_09"},
  GREATWORK_LOTM_RP_BLOOD_HARVEST_SICKLE={level=2,path="RP",resource="RESOURCE_LOTM_RP_BLOOD_HARVEST_SICKLE",lease="RESOURCE_LOTM_ARTIFACT_LEASE_10"},
  GREATWORK_LOTM_RP_IRONBLOOD_BANNER={level=1,path="RP",resource="RESOURCE_LOTM_RP_IRONBLOOD_BANNER",lease="RESOURCE_LOTM_ARTIFACT_LEASE_11"},
  GREATWORK_LOTM_RP_WAR_SCRIPTURE={level=1,path="RP",resource="RESOURCE_LOTM_RP_WAR_SCRIPTURE",lease="RESOURCE_LOTM_ARTIFACT_LEASE_12"},
  GREATWORK_LOTM_RP_DISASTER_WEATHER={level=0,path="RP",resource="RESOURCE_LOTM_RP_DISASTER_WEATHER",lease="RESOURCE_LOTM_ARTIFACT_LEASE_13"},
  GREATWORK_LOTM_RP_CONQUEROR_CROWN={level=0,path="RP",resource="RESOURCE_LOTM_RP_CONQUEROR_CROWN",lease="RESOURCE_LOTM_ARTIFACT_LEASE_14"},
  GREATWORK_LOTM_BE_GOLDEN_BRIBE={level=2,path="BE",resource="RESOURCE_LOTM_BE_GOLDEN_BRIBE",lease="RESOURCE_LOTM_ARTIFACT_LEASE_15"},
  GREATWORK_LOTM_BE_CORRUPTION_TAXBOOK={level=2,path="BE",resource="RESOURCE_LOTM_BE_CORRUPTION_TAXBOOK",lease="RESOURCE_LOTM_ARTIFACT_LEASE_16"},
  GREATWORK_LOTM_BE_CHAOS_CODEX={level=2,path="BE",resource="RESOURCE_LOTM_BE_CHAOS_CODEX",lease="RESOURCE_LOTM_ARTIFACT_LEASE_17"},
  GREATWORK_LOTM_BE_DEPRAVED_FEAST={level=1,path="BE",resource="RESOURCE_LOTM_BE_DEPRAVED_FEAST",lease="RESOURCE_LOTM_ARTIFACT_LEASE_18"},
  GREATWORK_LOTM_BE_FRENZY_SCEPTER={level=1,path="BE",resource="RESOURCE_LOTM_BE_FRENZY_SCEPTER",lease="RESOURCE_LOTM_ARTIFACT_LEASE_19"},
  GREATWORK_LOTM_BE_ENTROPY_CROWN={level=0,path="BE",resource="RESOURCE_LOTM_BE_ENTROPY_CROWN",lease="RESOURCE_LOTM_ARTIFACT_LEASE_20"},
  GREATWORK_LOTM_BE_ORDER_CONVERTER={level=0,path="BE",resource="RESOURCE_LOTM_BE_ORDER_CONVERTER",lease="RESOURCE_LOTM_ARTIFACT_LEASE_21"}
};
local ARTIFACT_ORDER :table = {
 "GREATWORK_LOTM_PP_GOLDEN_APPRAISAL_MIRROR","GREATWORK_LOTM_PP_PERPETUAL_GEARBOX","GREATWORK_LOTM_PP_ERROR_ASTROLABE",
 "GREATWORK_LOTM_PP_HERMES_FURNACE","GREATWORK_LOTM_PP_MYSTERY_BLUEPRINT","GREATWORK_LOTM_PP_KNOWLEDGE_CASKET","GREATWORK_LOTM_PP_CIVILIZATION_STELE",
 "GREATWORK_LOTM_RP_DISASTER_EMBER","GREATWORK_LOTM_RP_CONSPIRATOR_LETTER","GREATWORK_LOTM_RP_BLOOD_HARVEST_SICKLE","GREATWORK_LOTM_RP_IRONBLOOD_BANNER","GREATWORK_LOTM_RP_WAR_SCRIPTURE","GREATWORK_LOTM_RP_DISASTER_WEATHER","GREATWORK_LOTM_RP_CONQUEROR_CROWN",
 "GREATWORK_LOTM_BE_GOLDEN_BRIBE","GREATWORK_LOTM_BE_CORRUPTION_TAXBOOK","GREATWORK_LOTM_BE_CHAOS_CODEX","GREATWORK_LOTM_BE_DEPRAVED_FEAST","GREATWORK_LOTM_BE_FRENZY_SCEPTER","GREATWORK_LOTM_BE_ENTROPY_CROWN","GREATWORK_LOTM_BE_ORDER_CONVERTER"
};

-- BEGIN TEMP TEST FEATURE: Rescue new games receive all 21 artifacts.
-- Comment out this one line (or change true to false) before the public build;
-- the guarded implementation below then becomes inert without touching normal play.
local TEST_RESCUE_NEW_GAME_ALL_ARTIFACTS :boolean = false;
-- END TEMP TEST FEATURE SWITCH.
local GLOBAL_OWNER_PREFIX :string = "LOTM_PP_GLOBAL_OWNER_";
local function GlobalGet(key) if Game.GetProperty~=nil then return Game.GetProperty(key); end return nil; end
local function GlobalSet(key,value) if Game.SetProperty~=nil then Game.SetProperty(key,value); end end
local EFFECT_MODIFIERS :table = {
 "LOTM_PP_FX_GOLDEN_TOURISM","LOTM_PP_FX_GW_TOURISM_MUSIC","LOTM_PP_FX_GW_TOURISM_SCULPTURE","LOTM_PP_FX_GW_TOURISM_PORTRAIT","LOTM_PP_FX_GW_TOURISM_LANDSCAPE","LOTM_PP_FX_GW_TOURISM_RELIGIOUS","LOTM_PP_FX_GW_TOURISM_ARTIFACT","LOTM_PP_FX_GW_TOURISM_RELIC","LOTM_PP_FX_GW_TOURISM_HERO","LOTM_PP_FX_GOLDEN_GPP","LOTM_PP_FX_GOLDEN_GPP_ADMIRAL","LOTM_PP_FX_GOLDEN_GPP_ARTIST","LOTM_PP_FX_GOLDEN_GPP_ENGINEER","LOTM_PP_FX_GOLDEN_GPP_GENERAL","LOTM_PP_FX_GOLDEN_GPP_MERCHANT","LOTM_PP_FX_GOLDEN_GPP_MUSICIAN","LOTM_PP_FX_GOLDEN_GPP_PROPHET","LOTM_PP_FX_GOLDEN_GPP_WRITER",
 "LOTM_PP_FX_GW_WRITING","LOTM_PP_FX_GW_MUSIC","LOTM_PP_FX_GW_SCULPTURE","LOTM_PP_FX_GW_PORTRAIT","LOTM_PP_FX_GW_LANDSCAPE","LOTM_PP_FX_GW_RELIGIOUS","LOTM_PP_FX_GW_ARTIFACT","LOTM_PP_FX_GW_RELIC","LOTM_PP_FX_GEAR_PRODUCTION","LOTM_PP_FX_GEAR_FOOD",
 "LOTM_PP_FX_ASTROLABE_CAMPUS","LOTM_PP_FX_ASTROLABE_BUILDINGS","LOTM_PP_FX_ASTROLABE_SPACE","LOTM_PP_FX_ASTROLABE_FAITH","LOTM_PP_FX_ASTROLABE_CULTURE",
 "LOTM_PP_FX_FURNACE_PRODUCTION","LOTM_PP_FX_FURNACE_GOLD","LOTM_PP_FX_FURNACE_AMENITY",
 "LOTM_PP_FX_BLUEPRINT_FOOD_DISTRICT","LOTM_PP_FX_BLUEPRINT_PRODUCTION_DISTRICT","LOTM_PP_FX_BLUEPRINT_GOLD_DISTRICT","LOTM_PP_FX_BLUEPRINT_SCIENCE_DISTRICT","LOTM_PP_FX_BLUEPRINT_CULTURE_DISTRICT","LOTM_PP_FX_BLUEPRINT_FAITH_DISTRICT","LOTM_PP_FX_BLUEPRINT_FOOD","LOTM_PP_FX_BLUEPRINT_GROWTH",
 "LOTM_PP_FX_CASKET_CULTURE","LOTM_PP_FX_STELE_SCIENCE","LOTM_PP_FX_STELE_CULTURE","LOTM_PP_FX_STELE_PRODUCTION","LOTM_PP_FX_STELE_GOLD_FLAT",
 "LOTM_RP_ART_EMBER_AMENITY","LOTM_RP_ART_EMBER_FAST_PILLAGE","LOTM_RP_ART_EMBER_IMPROVEMENT_LOOT","LOTM_RP_ART_EMBER_DISTRICT_LOOT","LOTM_RP_ART_LETTER_PEACE_GOLD","LOTM_RP_ART_BANNER_GOLD","LOTM_RP_ART_BANNER_COMBAT","LOTM_RP_ART_BANNER_MOVE","LOTM_RP_ART_BANNER_MAINTENANCE","LOTM_RP_ART_SCRIPTURE_PRODUCTION","LOTM_RP_ART_SCRIPTURE_PEACE_PRODUCTION","LOTM_RP_ART_SCRIPTURE_WEARINESS","LOTM_RP_ART_WEATHER_FOOD","LOTM_RP_ART_WEATHER_AMENITY","LOTM_RP_ART_WEATHER_FRIENDLY_MOVE","LOTM_RP_ART_WEATHER_ENEMY_STRENGTH_AURA","LOTM_RP_ART_WEATHER_ENEMY_MOVE_AURA","LOTM_RP_ART_CROWN_ATTACK_DISTRICT","LOTM_RP_ART_CROWN_DEFENSE",
 "LOTM_BE_ART_BRIBE_ROUTE_GOLD","LOTM_BE_ART_BRIBE_DOMESTIC_FOOD","LOTM_BE_ART_BRIBE_DOMESTIC_PRODUCTION","LOTM_BE_ART_BRIBE_LEGACY_FOOD_COMPENSATION","LOTM_BE_ART_BRIBE_LEGACY_PRODUCTION_COMPENSATION","LOTM_BE_ART_BRIBE_ZERO_ALL_FOOD","LOTM_BE_ART_BRIBE_ZERO_ALL_PRODUCTION","LOTM_BE_ART_BRIBE_RESTORE_INTERNATIONAL_FOOD","LOTM_BE_ART_BRIBE_RESTORE_INTERNATIONAL_PRODUCTION","LOTM_BE_ART_BRIBE_LEGACY_FOOD_COMPENSATION_CANCEL_237","LOTM_BE_ART_BRIBE_LEGACY_PRODUCTION_COMPENSATION_CANCEL_237","LOTM_BE_ART_BRIBE_ZERO_DESTINATION_FOOD_237","LOTM_BE_ART_BRIBE_ZERO_DESTINATION_PRODUCTION_237","LOTM_BE_ART_TAX_GOLD","LOTM_BE_ART_TAX_CULTURE","LOTM_BE_ART_CODEX_SCIENCE_FLAT","LOTM_BE_ART_CODEX_GOLD_FLAT","LOTM_BE_ART_FEAST_FOOD","LOTM_BE_ART_FEAST_AMENITY","LOTM_BE_ART_FEAST_GOLD_FLAT","LOTM_BE_ART_FRENZY_FOOD_AURA","LOTM_BE_ART_FRENZY_PRODUCTION_AURA","LOTM_BE_ART_FRENZY_GOLD_AURA","LOTM_BE_ART_FRENZY_SCIENCE_AURA","LOTM_BE_ART_FRENZY_CULTURE_AURA","LOTM_BE_ART_FRENZY_FAITH_AURA","LOTM_BE_ART_FRENZY_AMENITY","LOTM_BE_ART_FRENZY_GOLD_FLAT","LOTM_BE_ART_ENTROPY_CULTURE","LOTM_BE_ART_ENTROPY_PRESSURE","LOTM_BE_ART_ORDER_PRODUCTION"
};
local BRIBE_ZERO_MODIFIERS :table = {
 "LOTM_BE_ART_BRIBE_LEGACY_FOOD_COMPENSATION",
 "LOTM_BE_ART_BRIBE_LEGACY_PRODUCTION_COMPENSATION",
 "LOTM_BE_ART_BRIBE_ZERO_ALL_FOOD",
 "LOTM_BE_ART_BRIBE_ZERO_ALL_PRODUCTION",
 "LOTM_BE_ART_BRIBE_RESTORE_INTERNATIONAL_FOOD",
 "LOTM_BE_ART_BRIBE_RESTORE_INTERNATIONAL_PRODUCTION"
};
local BRIBE_FIX_237_MODIFIERS :table = {
 "LOTM_BE_ART_BRIBE_LEGACY_FOOD_COMPENSATION_CANCEL_237",
 "LOTM_BE_ART_BRIBE_LEGACY_PRODUCTION_COMPENSATION_CANCEL_237",
 "LOTM_BE_ART_BRIBE_ZERO_DESTINATION_FOOD_237",
 "LOTM_BE_ART_BRIBE_ZERO_DESTINATION_PRODUCTION_237"
};
local BRIBE_FIX_238_MODIFIERS :table = {};
local BRIBE_FIX_239_MODIFIERS :table = {
 "LOTM_BE_ART_BRIBE_DOMESTIC_FOOD_FIXED_239",
 "LOTM_BE_ART_BRIBE_DOMESTIC_PRODUCTION_FIXED_239"
};
do
 local seen :table = {};
 if GameInfo.District_TradeRouteYields~=nil then
  for row in GameInfo.District_TradeRouteYields() do
   local amount=tonumber(row.YieldChangeAsDomesticDestination) or 0;
   if amount>0 and (row.YieldType=="YIELD_FOOD" or row.YieldType=="YIELD_PRODUCTION") then
    local id="LOTM_BE_ART_BRIBE_CANCEL_DISTRICT_"..tostring(row.DistrictType).."_"..tostring(row.YieldType).."_238";
    if not seen[id] then
     seen[id]=true;
     table.insert(BRIBE_FIX_238_MODIFIERS,id);
     table.insert(EFFECT_MODIFIERS,id);
    end
    local restoreId="LOTM_BE_ART_BRIBE_RESTORE_DISTRICT_"..tostring(row.DistrictType).."_"..tostring(row.YieldType).."_239";
    if not seen[restoreId] then
     seen[restoreId]=true;
     table.insert(BRIBE_FIX_239_MODIFIERS,restoreId);
     table.insert(EFFECT_MODIFIERS,restoreId);
    end
   end
  end
 end
 table.sort(BRIBE_FIX_238_MODIFIERS);
 table.sort(BRIBE_FIX_239_MODIFIERS);
end
table.insert(EFFECT_MODIFIERS,"LOTM_BE_ART_BRIBE_DOMESTIC_FOOD_FIXED_239");
table.insert(EFFECT_MODIFIERS,"LOTM_BE_ART_BRIBE_DOMESTIC_PRODUCTION_FIXED_239");
local LEGACY_COUNTERS :table = {};
for _,id in ipairs(EFFECT_MODIFIERS) do LEGACY_COUNTERS[id]=id.."_RC70_COUNTER"; end

local function Log(s) print("[LOTM_PP][Artifacts] " .. tostring(s)); end
local function RescueActive()
 return tonumber(Game.GetProperty("LOTM_RESCUE_MODE") or 0)==1;
end
local function Human(playerID)
 local p=Players[playerID];
 return p~=nil and p:IsAlive() and p:IsMajor() and p:IsHuman() and p or nil;
end
local function IsAtWarWithCivilization(p)
 local playerID=p:GetID(); local diplomacy=p:GetDiplomacy();
 if diplomacy==nil then return false; end
 -- Gameplay Player objects do not consistently expose IsMinor(). Use the
 -- Firaxis major/minor ID lists, as the base CityStates UI and this mod's
 -- Black Emperor controller do, then query the authoritative diplomacy state.
 for _,civilizationIDs in ipairs({
  PlayerManager.GetAliveMajorIDs(),PlayerManager.GetAliveMinorIDs()
 }) do
  for _,otherID in ipairs(civilizationIDs) do
   if otherID~=playerID and diplomacy:IsAtWarWith(otherID) then return true; end
  end
 end
 return false;
end
local function NumberProperty(object,key)
 local value=object:GetProperty(key); return value~=nil and tonumber(value) or nil;
end
local function FindCity(p)
 local c=p:GetCities():GetCapitalCity(); if c~=nil then return c; end
 for _,city in p:GetCities():Members() do return city; end
 return nil;
end
local function InstanceMappedElsewhere(playerID,artifactType,instance)
 for _,otherID in ipairs(PlayerManager.GetAliveMajorIDs()) do
  local other=Players[otherID];
  if other~=nil then
   for _,otherType in ipairs(ARTIFACT_ORDER) do
    if (otherID~=playerID or otherType~=artifactType) and NumberProperty(other,INSTANCE_PREFIX..otherType)==instance then return true; end
   end
  end
 end
 return false;
end
local function BindInstance(playerID,artifactType,instance,source)
 local p=Human(playerID); instance=tonumber(instance);
 if p==nil or ARTIFACTS[artifactType]==nil or instance==nil or instance<0 or instance%1~=0 then return false; end
 local old=NumberProperty(p,INSTANCE_PREFIX..artifactType);
 if old~=nil then return old==instance; end
 if InstanceMappedElsewhere(playerID,artifactType,instance) then
  Log("ERROR refused duplicate mapping player="..playerID.." type="..artifactType.." instance="..instance); return false;
 end
 p:SetProperty(INSTANCE_PREFIX..artifactType,instance);
 p:SetProperty("LOTM_PP_ARTIFACT_REV",(p:GetProperty("LOTM_PP_ARTIFACT_REV") or 0)+1);
 Log("bound instance player="..playerID.." type="..artifactType.." instance="..instance.." source="..tostring(source));
 return true;
end
local function IsOwned(playerID,artifactType,instance)
 if ARTIFACTS[artifactType]==nil or tonumber(instance)==nil then return false; end
 local p=Human(playerID); if p==nil then return false; end
 return NumberProperty(p,INSTANCE_PREFIX..artifactType)==tonumber(instance);
end
local function EnsureInfrastructure(playerID)
 local p=Human(playerID); if p==nil then return; end
 if (p:GetProperty(STORAGE_ATTACHED) or 0)==1 and (p:GetProperty(STORAGE_CLEANED) or 0)~=1 then
  p:AttachModifierByID(STORAGE_CLEANUP_MODIFIER); p:SetProperty(STORAGE_CLEANED,1);
 end
 if not RescueActive() then
 if (p:GetProperty(LEASE_EFFECTS_ATTACHED) or 0)~=1 then
  for _,id in ipairs(EFFECT_MODIFIERS) do p:AttachModifierByID(id.."_LEASE76"); end
  p:SetProperty(LEASE_EFFECTS_ATTACHED,1);
 end
 if (p:GetProperty(POLARITY_EFFECTS_ATTACHED) or 0)~=1 then
  for _,id in ipairs(EFFECT_MODIFIERS) do
   pcall(function() p:AttachModifierByID(id.."_LEASE81_POS"); end);
   pcall(function() p:AttachModifierByID(id.."_LEASE81_NEG"); end);
  end
  p:SetProperty(POLARITY_EFFECTS_ATTACHED,1);
  p:SetProperty(BRIBE_ZERO_EFFECTS_ATTACHED,1);
  p:SetProperty(BRIBE_FIX_238_EFFECTS_ATTACHED,1);
  p:SetProperty(BRIBE_FIX_239_EFFECTS_ATTACHED,1);
 elseif (p:GetProperty(BRIBE_ZERO_EFFECTS_ATTACHED) or 0)~=1 then
  -- Existing resource-117 saves already marked the general polarity bundle as
  -- attached.  Add only the six new resource-118 Bribe modifiers so no old
  -- effect ID is attached twice.
  for _,id in ipairs(BRIBE_ZERO_MODIFIERS) do
   pcall(function() p:AttachModifierByID(id.."_LEASE81_NEG"); end);
  end
  p:SetProperty(BRIBE_ZERO_EFFECTS_ATTACHED,1);
 end
 if (p:GetProperty(BRIBE_FIX_237_EFFECTS_ATTACHED) or 0)~=1 then
  -- Fresh IDs are mandatory for resource-236 saves whose lease81 modifier
  -- instances are already serialized. Attach only the four correction
  -- modifiers once; the existing positive/negative lease resources continue
  -- to control whether the contract is equipped.
  for _,id in ipairs(BRIBE_FIX_237_MODIFIERS) do
   pcall(function() p:AttachModifierByID(id.."_LEASE81_NEG"); end);
  end
 p:SetProperty(BRIBE_FIX_237_EFFECTS_ATTACHED,1);
 end
 if (p:GetProperty(BRIBE_FIX_238_EFFECTS_ATTACHED) or 0)~=1 then
  -- Resource-237 saves already serialized the general lease bundle.  Add only
  -- the exact district-source cancellations once; the existing negative lease
  -- resource still controls equip/unequip without leaving permanent penalties.
  for _,id in ipairs(BRIBE_FIX_238_MODIFIERS) do
   pcall(function() p:AttachModifierByID(id.."_LEASE81_NEG"); end);
  end
 p:SetProperty(BRIBE_FIX_238_EFFECTS_ATTACHED,1);
 end
 if (p:GetProperty(BRIBE_FIX_239_EFFECTS_ATTACHED) or 0)~=1 then
  -- Resource-238 saves already carry the source-by-source cancellation.  The
  -- fresh inverse bundle neutralizes it, then the fixed -3/-3 pair supplies
  -- the revised contract without duplicating either half on later reloads.
  for _,id in ipairs(BRIBE_FIX_239_MODIFIERS) do
   pcall(function() p:AttachModifierByID(id.."_LEASE81_NEG"); end);
  end
  p:SetProperty(BRIBE_FIX_239_EFFECTS_ATTACHED,1);
 end
 end
end
local function SetNamedResourceSwitch(p,resourceType,on,forceRefresh,label)
 local info=resourceType and GameInfo.Resources[resourceType] or nil;
 if info==nil then return; end
 local resources=p:GetResources(); local current=resources:GetResourceAmount(info.Index) or 0;
 local wanted=on and 1 or 0;
 if current~=wanted and resources.ChangeResourceAmount~=nil then
  resources:ChangeResourceAmount(info.Index,wanted-current);
 elseif forceRefresh and resources.ChangeResourceAmount~=nil then
  local pulse=wanted==0 and 1 or -1; resources:ChangeResourceAmount(info.Index,pulse); resources:ChangeResourceAmount(info.Index,-pulse);
 end
 Log(label.." player="..tostring(p:GetID()).." resource="..tostring(resourceType).." wanted="..tostring(wanted).." actual="..tostring(resources:GetResourceAmount(info.Index) or 0).." forced="..tostring(forceRefresh==true));
end
local function SetLegacySwitchOff(p,artifactType)
 local row=ARTIFACTS[artifactType]; if row~=nil then SetNamedResourceSwitch(p,row.resource,false,false,"legacy switch"); end
end
local function SetLetterModifierPair(p,property,shouldBeActive,startModifier,stopModifier,label)
 local isActive=(p:GetProperty(property) or 0)==1;
 if isActive==shouldBeActive then return; end
 p:AttachModifierByID(shouldBeActive and startModifier or stopModifier);
 p:SetProperty(property,shouldBeActive and 1 or 0);
 Log(label.." player="..tostring(p:GetID()).." active="..tostring(shouldBeActive));
end
local IsEquipped;
local function ArtifactPolarity(p,artifactType,on)
 if not on then return false,false; end
 local instance=NumberProperty(p,INSTANCE_PREFIX..artifactType);
 local turn=NumberProperty(p,"LOTM_WORLD_PLAYER_TURN") or 0;
 local satisfiedUntil=instance~=nil and NumberProperty(p,"LOTM_ARTIFACT_SATISFIED_UNTIL_"..tostring(instance)) or nil;
 local uncontrolledUntil=instance~=nil and NumberProperty(p,"LOTM_ARTIFACT_UNCONTROLLED_UNTIL_"..tostring(instance)) or nil;
 local satisfied=satisfiedUntil~=nil and turn<satisfiedUntil;
 local uncontrolled=uncontrolledUntil~=nil and turn<uncontrolledUntil;
 if uncontrolled then return false,true; end
 if satisfied then return true,false; end
 return true,true;
end
function LOTM_PP_ArtifactPositiveActive(playerID,artifactType)
 local p=Human(playerID); if p==nil or not IsEquipped(p,artifactType) then return false; end
 local positive=ArtifactPolarity(p,artifactType,true); return positive;
end
function LOTM_PP_ArtifactNegativeActive(playerID,artifactType)
 local p=Human(playerID); if p==nil or not IsEquipped(p,artifactType) then return false; end
 local _,negative=ArtifactPolarity(p,artifactType,true); return negative;
end
local function SetTurnLease(p,artifactType,on,forceRefresh)
 local row=ARTIFACTS[artifactType];
 if row~=nil then
  -- Retire rc.70/rc.76 switches, then issue polarity-split rc.81 leases.
  SetNamedResourceSwitch(p,row.lease,false,false,"retired lease70");
  local lease76=string.gsub(row.lease,"RESOURCE_LOTM_ARTIFACT_LEASE_","RESOURCE_LOTM_ARTIFACT_LEASE76_");
  SetNamedResourceSwitch(p,lease76,false,false,"retired lease76");
   if RescueActive() then
    -- Rescue Mode has a separate lease/effect namespace.  Explicitly retire
    -- ordinary resources so serialized Lease81 modifiers cannot leak across.
    SetNamedResourceSwitch(p,lease76.."_POS",false,false,"rescue retired ordinary positive lease81");
    SetNamedResourceSwitch(p,lease76.."_NEG",false,false,"rescue retired ordinary negative lease81");
   else
    local positive,negative=ArtifactPolarity(p,artifactType,on);
    SetNamedResourceSwitch(p,lease76.."_POS",positive,forceRefresh,"positive lease81");
    SetNamedResourceSwitch(p,lease76.."_NEG",negative,forceRefresh,"negative lease81");
   end
  end
end
IsEquipped=function(p,artifactType)
 if p==nil then return false; end
 for slot=1,9 do if p:GetProperty(SLOT_PREFIX..slot)==artifactType then return true; end end
 return false;
end
local function Reconcile(playerID,forceRefresh)
 local p=Human(playerID); if p==nil then return; end
 local equipped={};
 for slot=1,9 do
  local t=p:GetProperty(SLOT_PREFIX..slot); local instance=NumberProperty(p,SLOT_PREFIX..slot.."_INSTANCE");
  if t~=nil and not IsOwned(playerID,t,instance) then
   Log("auto-unequip player="..playerID.." slot="..slot.." type="..t);
   p:SetProperty(SLOT_PREFIX..slot,nil); p:SetProperty(SLOT_PREFIX..slot.."_INSTANCE",nil);
  elseif t~=nil then equipped[t]=true; end
 end
 local atWar=IsAtWarWithCivilization(p);
 local letterPositive=false; local letterNegative=false;
 if equipped[LETTER_TYPE] then letterPositive,letterNegative=ArtifactPolarity(p,LETTER_TYPE,true); end
 -- Keep the rc.86 resource gate permanently off so a saved -25 lease cannot
 -- stack with the copied native attach/balance implementation below.
 SetNamedResourceSwitch(p,LETTER_PEACE_RESOURCE,false,forceRefresh,"retired conspirator peace gate");
 local ordinaryLetter=not RescueActive();
 SetLetterModifierPair(p,LETTER_WAR_ACTIVE,ordinaryLetter and letterPositive and atWar,
  "LOTM_RP_ART_LETTER_WAR_GOLD_START","LOTM_RP_ART_LETTER_WAR_GOLD_STOP","conspirator native war income");
 SetLetterModifierPair(p,LETTER_PEACE_ACTIVE,ordinaryLetter and letterNegative and not atWar,
  "LOTM_RP_ART_LETTER_PEACE_PENALTY_START","LOTM_RP_ART_LETTER_PEACE_PENALTY_STOP","conspirator native peace penalty");
 for _,t in ipairs(ARTIFACT_ORDER) do
  local active=equipped[t]==true;
  SetLegacySwitchOff(p,t);
  SetTurnLease(p,t,active,forceRefresh);
 end
 p:SetProperty("LOTM_PP_ARTIFACT_EQUIPMENT_REV",(p:GetProperty("LOTM_PP_ARTIFACT_EQUIPMENT_REV") or 0)+1);
end

-- Old Permanent=1 modifier instances retain their saved arguments even after
-- the database row is corrected.  After legacy switches have remained zero
-- for a full turn, inspect synchronized GameEffects.  Only a proven active old
-- instance owned by this player receives its exact inverse counter.
local function CleanupLegacyLatchedEffects(playerID)
 local p=Human(playerID); if p==nil or (p:GetProperty("LOTM_PP_ARTIFACT_LEGACY_CLEANUP_RC70") or 0)==1 then return; end
 local turn=Game.GetCurrentGameTurn(); local armed=NumberProperty(p,"LOTM_PP_ARTIFACT_LEGACY_CLEANUP_ARMED_TURN");
 if armed==nil then p:SetProperty("LOTM_PP_ARTIFACT_LEGACY_CLEANUP_ARMED_TURN",turn); Log("legacy cleanup armed player="..playerID.." turn="..turn); return; end
 if turn<=armed then return; end
 if GameEffects==nil or GameEffects.GetModifiers==nil or GameEffects.GetModifierDefinition==nil
  or GameEffects.GetModifierOwner==nil or GameEffects.GetObjectsPlayerId==nil or GameEffects.GetModifierActive==nil then
  if (p:GetProperty("LOTM_PP_ARTIFACT_LEGACY_CLEANUP_API_WARNED") or 0)~=1 then
   p:SetProperty("LOTM_PP_ARTIFACT_LEGACY_CLEANUP_API_WARNED",1); Log("WARNING legacy cleanup GameEffects API unavailable player="..playerID);
  end
  return;
 end
 local ok,counts=pcall(function()
  local found={};
  for _,instanceID in ipairs(GameEffects.GetModifiers() or {}) do
   local definition=GameEffects.GetModifierDefinition(instanceID);
   local id=definition and definition.Id or nil;
   local active=GameEffects.GetModifierActive(instanceID);
   if not active and GameEffects.GetModifierSubjectCount~=nil then active=(GameEffects.GetModifierSubjectCount(instanceID) or 0)>0; end
   if id~=nil and LEGACY_COUNTERS[id]~=nil and active then
    local owner=GameEffects.GetModifierOwner(instanceID);
    if owner~=nil and GameEffects.GetObjectsPlayerId(owner)==playerID then found[id]=(found[id] or 0)+1; end
   end
  end
  return found;
 end);
 if not ok then Log("WARNING legacy cleanup scan failed player="..playerID.." error="..tostring(counts)); return; end
 local total=0;
 for _,id in ipairs(EFFECT_MODIFIERS) do
  local desired=counts[id] or 0; local key="LOTM_PP_ARTIFACT_COUNTER_RC70_"..id; local applied=NumberProperty(p,key) or 0;
  while applied<desired do p:AttachModifierByID(LEGACY_COUNTERS[id]); applied=applied+1; total=total+1; end
  if applied>0 then p:SetProperty(key,applied); end
 end
 p:SetProperty("LOTM_PP_ARTIFACT_LEGACY_CLEANUP_RC70",1);
 Log("legacy cleanup completed player="..playerID.." counters="..total);
end
local function Grant(playerID,artifactType)
 local p=Human(playerID); local row=ARTIFACTS[artifactType]; if p==nil or row==nil then return false; end
 EnsureInfrastructure(playerID);
 local ordinal=1; for i,t in ipairs(ARTIFACT_ORDER) do if t==artifactType then ordinal=i; break; end end
 local globalKey=GLOBAL_OWNER_PREFIX..artifactType; local current=GlobalGet(globalKey);
 if current~=nil and tonumber(current)~=nil and tonumber(current)>=0 then return false; end
 local synthetic=2000000 + ordinal;
 if BindInstance(playerID,artifactType,synthetic,"isolated-ledger") then
 GlobalSet(globalKey,playerID); GlobalSet("LOTM_PP_GLOBAL_INSTANCE_"..artifactType,synthetic);
  p:SetProperty("LOTM_PP_PENDING_"..artifactType,nil);
  p:SetProperty("LOTM_PP_ARTIFACT_SHOWCASE_TYPE",artifactType); p:SetProperty("LOTM_PP_ARTIFACT_SHOWCASE_TURN",Game.GetCurrentGameTurn()); p:SetProperty("LOTM_PP_ARTIFACT_SHOWCASE_SERIAL",(p:GetProperty("LOTM_PP_ARTIFACT_SHOWCASE_SERIAL") or 0)+1);
  Log("granted isolated artifact player="..playerID.." type="..artifactType.." instance="..synthetic); return true;
 end
 return false;
end
local function HasKnownType(p,t)
 local owner=GlobalGet(GLOBAL_OWNER_PREFIX..t);
 if owner~=nil and tonumber(owner)~=nil and tonumber(owner)>=0 then return tonumber(owner)==p:GetID(); end
 return NumberProperty(p,INSTANCE_PREFIX..t)~=nil;
end

-- BEGIN TEMP TEST FEATURE IMPLEMENTATION.
local function IsPrimaryHuman(playerID)
 local primary=nil;
 for _,candidateID in ipairs(PlayerManager.GetAliveMajorIDs()) do
  if Human(candidateID)~=nil and (primary==nil or candidateID<primary) then primary=candidateID; end
 end
 return primary~=nil and playerID==primary;
end
local function GrantAllArtifactsForRescueNewGame(playerID)
 if TEST_RESCUE_NEW_GAME_ALL_ARTIFACTS~=true or not RescueActive() or not IsPrimaryHuman(playerID) then return; end
 local p=Human(playerID); if p==nil or (p:GetProperty("LOTM_TEST_RESCUE_ALL_ARTIFACTS_269") or 0)==1 then return; end
 local startTurn=tonumber(GameConfiguration.GetStartTurn~=nil and GameConfiguration.GetStartTurn() or 0) or 0;
 if Game.GetCurrentGameTurn()~=startTurn then return; end
 local owned=0; local granted=0;
 for _,artifactType in ipairs(ARTIFACT_ORDER) do
  if HasKnownType(p,artifactType) then owned=owned+1;
  elseif Grant(playerID,artifactType) then owned=owned+1; granted=granted+1; end
 end
 if owned==#ARTIFACT_ORDER then
  p:SetProperty("LOTM_TEST_RESCUE_ALL_ARTIFACTS_269",1);
  p:SetProperty("LOTM_PP_ARTIFACT_EFFECT_REFRESH_PENDING",1);
  Log("TEMP TEST granted all Rescue new-game artifacts player="..playerID.." granted="..granted.." total="..owned);
 else
  Log("WARNING TEMP TEST incomplete Rescue artifact grant player="..playerID.." granted="..granted.." owned="..owned.." expected="..#ARTIFACT_ORDER);
 end
end
-- END TEMP TEST FEATURE IMPLEMENTATION.
local function RecoverLegacyLedger(playerID)
 local p=Human(playerID); if p==nil or (p:GetProperty("LOTM_PP_ARTIFACT_LEDGER_RECOVERED_RC61") or 0)==1 then return; end
 local candidates={};
 local last=p:GetProperty("LOTM_PP_LAST_REWARD"); if ARTIFACTS[last]~=nil then candidates[last]=true; end
 for slot=1,9 do local equipped=p:GetProperty(SLOT_PREFIX..slot); if ARTIFACTS[equipped]~=nil then candidates[equipped]=true; end end
 for _,artifactType in ipairs(ARTIFACT_ORDER) do
  if candidates[artifactType] and not HasKnownType(p,artifactType) then Grant(playerID,artifactType); end
 end
 p:SetProperty("LOTM_PP_ARTIFACT_LEDGER_RECOVERED_RC61",1);
end
local function RefreshOwnership(playerID)
 local p=Human(playerID); if p==nil then return; end
 for _,t in ipairs(ARTIFACT_ORDER) do if NumberProperty(p,INSTANCE_PREFIX..t)~=nil and GlobalGet(GLOBAL_OWNER_PREFIX..t)==nil then GlobalSet(GLOBAL_OWNER_PREFIX..t,playerID); GlobalSet("LOTM_PP_GLOBAL_INSTANCE_"..t,NumberProperty(p,INSTANCE_PREFIX..t)); end HasKnownType(p,t); end
 Reconcile(playerID);
end
function LOTM_PP_HasAvailableArtifact(path,level)
 for _,t in ipairs(ARTIFACT_ORDER) do local row=ARTIFACTS[t]; local owner=GlobalGet(GLOBAL_OWNER_PREFIX..t); if row.path==path and row.level==level and (owner==nil or tonumber(owner)<0) then return true; end end
 return false;
end
function LOTM_PP_GetAvailableArtifacts(level,path)
 local pool={};
 for _,t in ipairs(ARTIFACT_ORDER) do
  local row=ARTIFACTS[t]; local owner=GlobalGet(GLOBAL_OWNER_PREFIX..t);
  if row.level==level and (path==nil or row.path==path)
   and (owner==nil or tonumber(owner)<0) then
   table.insert(pool,{ArtifactType=t,Level=row.level,Path=row.path});
  end
 end
 table.sort(pool,function(a,b) return a.ArtifactType<b.ArtifactType; end);
 return pool;
end
function LOTM_PP_GrantSpecificArtifact(playerID,artifactType)
 return Grant(playerID,artifactType);
end
function LOTM_PP_GrantWorkshopReward(playerID,level,path)
 local p=Human(playerID); if p==nil then return false,"AI_OR_INVALID"; end
 path=path or "PP";
 local pool={}; for _,t in ipairs(ARTIFACT_ORDER) do local row=ARTIFACTS[t]; local owner=GlobalGet(GLOBAL_OWNER_PREFIX..t); if row.level==level and row.path==path and (owner==nil or tonumber(owner)<0) and not HasKnownType(p,t) then table.insert(pool,t); end end
 table.sort(pool); if #pool==0 then p:SetProperty("LOTM_PP_LAST_REWARD","COMPLETE_LEVEL_"..level); return false,"COMPLETE"; end
 local chosen=pool[Game.GetRandNum(#pool,"LOTM PP workshop artifact")+1];
 p:SetProperty("LOTM_PP_LAST_REWARD",chosen); return Grant(playerID,chosen),chosen;
end
local function Equip(playerID,parameters)
 local p=Human(playerID); local slot=tonumber(parameters.Slot); local t=parameters.ArtifactType; local instance=tonumber(parameters.Instance);
 -- rc.58 created the GreatWork before synchronized type-instance binding was
 -- available. Permit exactly the recorded last workshop reward to migrate on
 -- its first equip request; arbitrary UI claims remain rejected.
 if p~=nil and ARTIFACTS[t]~=nil and instance~=nil and not IsOwned(playerID,t,instance)
  and NumberProperty(p,INSTANCE_PREFIX..t)==nil and p:GetProperty("LOTM_PP_LAST_REWARD")==t
  and (p:GetProperty("LOTM_PP_ARTIFACT_LEGACY_CLAIMED_"..t) or 0)~=1 then
  if BindInstance(playerID,t,instance,"rc58-last-reward-migration") then p:SetProperty("LOTM_PP_ARTIFACT_LEGACY_CLAIMED_"..t,1); end
 end
 if p==nil or slot==nil or slot<1 or slot>9 or slot%1~=0 or not IsOwned(playerID,t,instance) then
  Log("rejected equip player="..tostring(playerID).." slot="..tostring(slot).." type="..tostring(t).." instance="..tostring(instance).." mapped="..tostring(p~=nil and NumberProperty(p,INSTANCE_PREFIX..t) or nil)); return;
 end
 local old=p:GetProperty(SLOT_PREFIX..slot); local oldInstance=p:GetProperty(SLOT_PREFIX..slot.."_INSTANCE"); local previous=nil;
 for candidate=1,9 do if candidate~=slot and p:GetProperty(SLOT_PREFIX..candidate)==t then previous=candidate; break; end end
 if previous~=nil then
  p:SetProperty(SLOT_PREFIX..previous,old); p:SetProperty(SLOT_PREFIX..previous.."_INSTANCE",oldInstance);
 end
 p:SetProperty(SLOT_PREFIX..slot,t); p:SetProperty(SLOT_PREFIX..slot.."_INSTANCE",instance); Reconcile(playerID);
 p:SetProperty("LOTM_PP_ARTIFACT_EFFECT_REFRESH_PENDING",1);
end

-- Synchronized helper used only by the default-disabled quick-test module.
-- Keeping the ownership grant and equip validation here exercises the same
-- ledger and reconciliation path as normal play instead of forging UI state.
function LOTM_PP_QuickTestGrantAndEquip(playerID,artifactType,slot)
 local p=Human(playerID); slot=tonumber(slot) or 1;
 if p==nil or ARTIFACTS[artifactType]==nil or slot<1 or slot>9 then return false; end
 if not HasKnownType(p,artifactType) and not Grant(playerID,artifactType) then return false; end
 local instance=NumberProperty(p,INSTANCE_PREFIX..artifactType); if instance==nil then return false; end
 Equip(playerID,{Slot=slot,ArtifactType=artifactType,Instance=instance});
 return p:GetProperty(SLOT_PREFIX..slot)==artifactType;
end

local function Unequip(playerID,parameters)
 local p=Human(playerID); local slot=tonumber(parameters.Slot); if p==nil or slot==nil or slot<1 or slot>9 or slot%1~=0 then return; end
 p:SetProperty(SLOT_PREFIX..slot,nil); p:SetProperty(SLOT_PREFIX..slot.."_INSTANCE",nil); p:SetProperty("LOTM_PP_ARTIFACT_EFFECT_REFRESH_PENDING",1); Reconcile(playerID);
end
local function Transfer(playerID,parameters)
 local fromID=tonumber(parameters.FromPlayer); local toID=tonumber(parameters.ToPlayer); local t=parameters.ArtifactType;
 local from=Human(fromID); local to=Human(toID);
 if Human(playerID)==nil or from==nil or to==nil or fromID==toID or ARTIFACTS[t]==nil
  or playerID~=fromID then return; end
 local instance=NumberProperty(from,INSTANCE_PREFIX..t);
 if instance==nil or NumberProperty(to,INSTANCE_PREFIX..t)~=nil
  or NumberProperty(Game,GLOBAL_OWNER_PREFIX..t)~=fromID then return; end
 from:SetProperty(INSTANCE_PREFIX..t,nil); to:SetProperty(INSTANCE_PREFIX..t,instance);
 GlobalSet(GLOBAL_OWNER_PREFIX..t,toID);
 from:SetProperty("LOTM_PP_ARTIFACT_REV",(from:GetProperty("LOTM_PP_ARTIFACT_REV") or 0)+1);
 to:SetProperty("LOTM_PP_ARTIFACT_REV",(to:GetProperty("LOTM_PP_ARTIFACT_REV") or 0)+1);
 for slot=1,9 do
  if from:GetProperty(SLOT_PREFIX..slot)==t then
   from:SetProperty(SLOT_PREFIX..slot,nil); from:SetProperty(SLOT_PREFIX..slot.."_INSTANCE",nil);
  end
 end
 from:SetProperty("LOTM_PP_ARTIFACT_EFFECT_REFRESH_PENDING",1); to:SetProperty("LOTM_PP_ARTIFACT_EFFECT_REFRESH_PENDING",1); Reconcile(fromID); Reconcile(toID);
 Log("transferred type="..t.." instance="..instance.." from="..fromID.." to="..toID);
end
local function OnCommand(playerID,parameters)
 if parameters==nil then return; end
 if parameters.Action=="EQUIP" then Equip(playerID,parameters)
 elseif parameters.Action=="UNEQUIP" then Unequip(playerID,parameters)
 elseif parameters.Action=="TRANSFER" then Transfer(playerID,parameters) end
end
local function OnCreated(playerID,creatorID,x,y,buildingID,instance)
 local p=Human(playerID); if p==nil then return; end
 local t=p:GetProperty(EXPECTED_TYPE); local expectedTurn=NumberProperty(p,EXPECTED_TURN);
 if ARTIFACTS[t]==nil or expectedTurn==nil or expectedTurn~=Game.GetCurrentGameTurn() then return; end
 if BindInstance(playerID,t,instance,"GreatWorkCreated") then
  p:SetProperty(EXPECTED_TYPE,nil); p:SetProperty(EXPECTED_TURN,nil);
 end
end
local function TriggerRandomKnowledgeCasketEureka(playerID,p,turn)
 local techs=p~=nil and p:GetTechs() or nil; if techs==nil then return false; end
 local choices={};
 for tech in GameInfo.Technologies() do
  if not techs:HasTech(tech.Index) and not techs:HasBoostBeenTriggered(tech.Index) then choices[#choices+1]=tech.Index; end
 end
 table.sort(choices);
 if #choices==0 then Log("knowledge casket no eligible Eureka player="..playerID.." turn="..turn); return true; end
 local selected=choices[Game.GetRandNum(#choices,"LOTM PP knowledge casket")+1];
 local ok,result=pcall(function() return techs:TriggerBoost(selected,1); end);
 if not ok then Log("WARNING knowledge casket TriggerBoost failed player="..playerID.." turn="..turn.." tech="..selected.." error="..tostring(result)); return false; end
 Log("knowledge casket Eureka player="..playerID.." turn="..turn.." tech="..selected.." result="..tostring(result));
 return true;
end
local function ProcessTurn(playerID,isFirstTimeThisTurn)
 if isFirstTimeThisTurn==false then return; end
 local p=Human(playerID); if p==nil then return; end EnsureInfrastructure(playerID); RecoverLegacyLedger(playerID);
 GrantAllArtifactsForRescueNewGame(playerID);
 local turn=Game.GetCurrentGameTurn();
 if NumberProperty(p,TURN_SETTLED)==turn then return; end
 -- Persist the deterministic guard before applying any one-shot turn effects.
 -- Re-activation after save/load or a multiplayer reconnect cannot settle twice.
 p:SetProperty(TURN_SETTLED,turn);
 for _,t in ipairs(ARTIFACT_ORDER) do if (p:GetProperty("LOTM_PP_PENDING_"..t) or 0)==1 and not HasKnownType(p,t) then Grant(playerID,t); end end
 -- Every player turn is a fresh one-turn lease.  Clear/reissue happens even if
 -- the slot list is unchanged, so effects cannot accumulate across refreshes.
 Reconcile(playerID,true); p:SetProperty("LOTM_PP_ARTIFACT_EFFECT_REFRESH_PENDING",nil); CleanupLegacyLatchedEffects(playerID);
 local equipped={}; local positiveEquipped={}; local negativeEquipped={};
 for slot=1,9 do
  local equippedType=p:GetProperty(SLOT_PREFIX..slot);
  if equippedType~=nil then
   equipped[equippedType]=true;
   local positive,negative=ArtifactPolarity(p,equippedType,true);
   positiveEquipped[equippedType]=positive; negativeEquipped[equippedType]=negative;
  end
 end
 local atWar=IsAtWarWithCivilization(p);
 if negativeEquipped.GREATWORK_LOTM_RP_BLOOD_HARVEST_SICKLE then
  local eligible=0; local changed=0; local totalDamage=0;
  for _,u in p:GetUnits():Members() do
   if (tonumber(u:GetCombat()) or 0)>0 or (tonumber(u:GetRangedCombat()) or 0)>0 or (tonumber(u:GetBombardCombat()) or 0)>0 then
    eligible=eligible+1;
    local current=tonumber(u:GetDamage()) or 0; local maximum=tonumber(u:GetMaxDamage()) or 100;
    local applied=math.min(5,math.max(0,maximum-1-current));
    if applied>0 then u:ChangeDamage(applied); changed=changed+1; totalDamage=totalDamage+applied; end
   end
  end
  Log("sickle attrition player="..playerID.." eligible="..eligible.." changed="..changed.." damage="..totalDamage);
 end
 if positiveEquipped.GREATWORK_LOTM_BE_ENTROPY_CROWN then for _,city in p:GetCities():Members() do city:ChangeLoyalty(99); end end
 local orderConverted=0;
 if positiveEquipped.GREATWORK_LOTM_BE_ORDER_CONVERTER then
  local production=0; local yieldIndex=GameInfo.Yields.YIELD_PRODUCTION.Index;
  for _,city in p:GetCities():Members() do production=production+(city:GetYield(yieldIndex) or 0); end
   local converted=production/3; orderConverted=converted;
  if converted>0 then
   local techs=p:GetTechs(); if techs~=nil and techs.ChangeCurrentResearchProgress~=nil then techs:ChangeCurrentResearchProgress(converted); end
   local culture=p:GetCulture(); if culture~=nil and culture.ChangeCurrentCulturalProgress~=nil then culture:ChangeCurrentCulturalProgress(converted); end
   p:GetTreasury():ChangeGoldBalance(converted);
  end
 end
 p:SetProperty("LOTM_PP_ORDER_CONVERTED_LAST",orderConverted);
 if positiveEquipped.GREATWORK_LOTM_PP_KNOWLEDGE_CASKET then
  if p:GetProperty("LOTM_PP_CASKET_TURN")~=turn then
   if TriggerRandomKnowledgeCasketEureka(playerID,p,turn) then p:SetProperty("LOTM_PP_CASKET_TURN",turn); end
  end
 end
 if positiveEquipped.GREATWORK_LOTM_PP_CIVILIZATION_STELE or negativeEquipped.GREATWORK_LOTM_PP_CIVILIZATION_STELE then
  if p:GetProperty("LOTM_PP_STELE_TURN")~=turn then
   if positiveEquipped.GREATWORK_LOTM_PP_CIVILIZATION_STELE and p:GetGreatPeoplePoints().ChangePointsTotal~=nil then p:GetGreatPeoplePoints():ChangePointsTotal(GameInfo.GreatPersonClasses.GREAT_PERSON_CLASS_SCIENTIST.Index,500); end
   p:SetProperty("LOTM_PP_STELE_TURN",turn);
  end
 end
end
local function OnCombatOccurred(attackerPlayerID,attackerUnitID,defenderPlayerID,defenderUnitID)
 local p=Human(attackerPlayerID); if p==nil or not LOTM_PP_ArtifactPositiveActive(attackerPlayerID,"GREATWORK_LOTM_RP_BLOOD_HARVEST_SICKLE") then return; end
 local attacker=p:GetUnits():FindID(attackerUnitID); local defenderPlayer=Players[defenderPlayerID];
 local defender=defenderPlayer~=nil and defenderPlayer:GetUnits():FindID(defenderUnitID) or nil;
 local defeated=defenderUnitID~=nil and defenderUnitID>=0 and (defender==nil or defender:IsDead() or defender:IsDelayedDeath());
 if attacker~=nil and defeated then local damage=attacker:GetDamage() or 0; if damage>0 then attacker:ChangeDamage(-math.min(30,damage)); end end
end
local function OnDiplomacyDeclareWar(firstPlayerID,secondPlayerID)
 for _,playerID in ipairs({firstPlayerID,secondPlayerID}) do
  local p=Human(playerID);
  if not RescueActive() and p~=nil and LOTM_PP_ArtifactPositiveActive(playerID,"GREATWORK_LOTM_RP_CONSPIRATOR_LETTER")
   and (p:GetProperty("LOTM_RP_ART_LETTER_FIRST_WAR_PAID") or 0)~=1 then
   p:SetProperty("LOTM_RP_ART_LETTER_FIRST_WAR_PAID",1); p:GetTreasury():ChangeGoldBalance(1000);
   Log("conspirator first-war gold player="..tostring(playerID));
  end
 end
 Reconcile(firstPlayerID,true); Reconcile(secondPlayerID,true);
end
local function OnDiplomacyMakePeace(firstPlayerID,secondPlayerID)
 Reconcile(firstPlayerID,true); Reconcile(secondPlayerID,true);
end
local function OnUnitAdded(playerID,unitID)
 local p=Human(playerID); if p==nil then return; end local unit=UnitManager.GetUnit(playerID,unitID); if unit==nil or unit:GetType()~=GameInfo.Units.UNIT_BUILDER.Index then return; end
 local furnace=LOTM_PP_ArtifactPositiveActive(playerID,"GREATWORK_LOTM_PP_HERMES_FURNACE");
 if furnace then
  local ability=unit:GetAbility(); if ability~=nil then ability:ChangeAbilityCount("ABILITY_LOTM_PP_HERMES_BUILDER",1); unit:SetProperty("LOTM_PP_HERMES_BONUS",1); end
 end
end
local function Initialize()
 GameEvents.LOTM_PP_Command_Artifact.Add(OnCommand); Events.GreatWorkCreated.Add(OnCreated);
 -- GreatWorkMoved is a UI event in the shipped Gathering Storm runtime and is
 -- not available in synchronized Gameplay. Ownership is rechecked on every
 -- player turn, including immediately after a completed diplomatic deal.
 Events.PlayerTurnActivated.Add(ProcessTurn); Events.UnitAddedToMap.Add(LOTM_UnitAddedPerf.Wrap("Artifacts",OnUnitAdded));
 GameEvents.OnCombatOccurred.Add(OnCombatOccurred); Events.DiplomacyDeclareWar.Add(OnDiplomacyDeclareWar); Events.DiplomacyMakePeace.Add(OnDiplomacyMakePeace);
 for _,id in ipairs(PlayerManager.GetAliveMajorIDs()) do EnsureInfrastructure(id); RecoverLegacyLedger(id); RefreshOwnership(id); end
 Log("initialized");
end
Initialize();
-- END RC241 MODULE: Scripts/LOTM_PP_Artifacts.lua
end;

m_mp241Loaders["LOTM_PP_Perfect"] = function()
-- BEGIN POST_RC241_RULES MODULE: Scripts/LOTM_PP_Perfect.lua
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("MP.LOTM_PP_Perfect","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"MP.LOTM_PP_Perfect","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"MP.LOTM_PP_Perfect","GameEvents");
-- END RC342 STARTUP TRACE

-- Perfect Path Sequence 9 through Sequence 0.
-- Gameplay owns every mutation; UI only reads the synchronized properties.

local LOTM_PP_PATH :string = "PATH_PERFECT";
local LOTM_PP_RELIC_INTERVAL :number = 5;
local LOTM_PP_RELIC_LIMIT :number = 5;

local LOTM_PP_PROJECT_ADVANCES :table = {
	PROJECT_LOTM_PP_ARCHAEOLOGIST_POTION = { 9, 8 },
	PROJECT_LOTM_PP_APPRAISER_POTION = { 8, 7 },
	PROJECT_LOTM_PP_MECHANICAL_EXPERT_POTION = { 7, 6 },
	PROJECT_LOTM_PP_ASTRONOMER_POTION = { 6, 5 },
	PROJECT_LOTM_PP_ALCHEMIST_POTION = { 5, 4 },
	PROJECT_LOTM_PP_MYSTERY_SCHOLAR_POTION = { 4, 3 },
	PROJECT_LOTM_PP_KNOWLEDGE_MENTOR_POTION = { 3, 2 },
	PROJECT_LOTM_PP_ENLIGHTENER_POTION = { 2, 1 },
	PROJECT_LOTM_PP_CIVILIZATION_ASCENSION = { 1, 0 },
	PROJECT_LOTM_PP_CIVILIZATION_ASCENSION_UNCONSECRATED = {
		1, 0, allowWithoutChurch = true
	},
};

local LOTM_PP_BASE_YIELDS :table = {
	YIELD_FOOD = true,
	YIELD_PRODUCTION = true,
	YIELD_GOLD = true,
	YIELD_SCIENCE = true,
	YIELD_CULTURE = true,
	YIELD_FAITH = true,
};

local LOTM_PP_SEQUENCE_MODIFIERS :table = {
	[9] = {
		{ "LOTM_PP_MOD_GENERALIST_TECH_BOOST", "LOTM_PP_GENERALIST_TECH_ATTACHED" },
		{ "LOTM_PP_MOD_GENERALIST_CIVIC_BOOST", "LOTM_PP_GENERALIST_CIVIC_ATTACHED" },
	},
	[8] = {
		{ "LOTM_PP_MOD_PALACE_RELIC_SLOTS", "LOTM_PP_RELIC_SLOTS_ATTACHED" },
	},
	[6] = {
		{ "LOTM_PP_MOD_MECHANICAL_IMPROVED_PLOT_PRODUCTION",
			"LOTM_PP_MECHANICAL_PLOTS_ATTACHED" },
	},
	[5] = {
		{ "LOTM_PP_MOD_ASTRONOMER_CAMPUS_YIELD",
			"LOTM_PP_ASTRONOMER_CAMPUS_ATTACHED" },
		{ "LOTM_PP_MOD_ASTRONOMER_CAMPUS_BUILDINGS",
			"LOTM_PP_ASTRONOMER_BUILDINGS_ATTACHED" },
		{ "LOTM_PP_MOD_ASTRONOMER_SPACE_PROJECTS",
			"LOTM_PP_ASTRONOMER_SPACE_ATTACHED" },
	},
	[4] = {
		{ "LOTM_PP_MOD_ALCHEMIST_BUILDER_CHARGES_V2",
			"LOTM_PP_ALCHEMIST_CHARGES_V2_ATTACHED" },
		{ "LOTM_PP_MOD_ALCHEMIST_CITY_PRODUCTION",
			"LOTM_PP_ALCHEMIST_PRODUCTION_ATTACHED" },
	},
	[1] = {
		{ "LOTM_PP_MOD_ENLIGHTENER_SCIENCE",
			"LOTM_PP_ENLIGHTENER_SCIENCE_ATTACHED" },
		{ "LOTM_PP_MOD_ENLIGHTENER_CULTURE",
			"LOTM_PP_ENLIGHTENER_CULTURE_ATTACHED" },
	},
	[0] = {
		{ "LOTM_PP_MOD_PERFECT_FOOD", "LOTM_PP_PERFECT_FOOD_ATTACHED" },
		{ "LOTM_PP_MOD_PERFECT_PRODUCTION", "LOTM_PP_PERFECT_PRODUCTION_ATTACHED" },
		{ "LOTM_PP_MOD_PERFECT_GOLD", "LOTM_PP_PERFECT_GOLD_ATTACHED" },
		{ "LOTM_PP_MOD_PERFECT_SCIENCE", "LOTM_PP_PERFECT_SCIENCE_ATTACHED" },
		{ "LOTM_PP_MOD_PERFECT_CULTURE", "LOTM_PP_PERFECT_CULTURE_ATTACHED" },
		{ "LOTM_PP_MOD_PERFECT_FAITH", "LOTM_PP_PERFECT_FAITH_ATTACHED" },
	},
};

local function Log(message :string)
	print("[LOTM_PP][Perfect] " .. message);
end

local function GetPlayer(playerID :number)
	return playerID ~= nil and Players[playerID] or nil;
end

local function IsPerfect(playerID :number)
	return LOTM_RP_State ~= nil
		and LOTM_RP_State.IsPerfectPlayer(playerID)
		and LOTM_RP_State.GetPath(playerID) == LOTM_PP_PATH;
end

local function GetSequence(playerID :number)
	return LOTM_RP_State.GetSequence(playerID);
end

local function RepairLegacyAlchemistCharges(playerID :number)
	local player = GetPlayer(playerID);
	if player == nil
		or (player:GetProperty("LOTM_PP_ALCHEMIST_CHARGES_ATTACHED") or 0) ~= 1
		or (player:GetProperty("LOTM_PP_ALCHEMIST_CHARGES_LEGACY_COMPENSATED") or 0) == 1 then
		return;
	end
	player:AttachModifierByID(
		"LOTM_PP_MOD_ALCHEMIST_BUILDER_CHARGES_LEGACY_COMPENSATION"
	);
	player:SetProperty("LOTM_PP_ALCHEMIST_CHARGES_LEGACY_COMPENSATED", 1);
	Log("player=" .. tostring(playerID)
		.. " compensated legacy unrestricted Alchemist builder charges");
end

local function AttachSequenceModifiers(playerID :number, sequence :number)
	for unlockSequence = 9, 0, -1 do
		if sequence <= unlockSequence then
			for _, entry in ipairs(LOTM_PP_SEQUENCE_MODIFIERS[unlockSequence] or {}) do
				LOTM_RP_State.AttachModifierOnce(playerID, entry[1], entry[2]);
			end
		end
	end
end

local function IsSpecialtyDistrict(district)
	return district ~= nil
		and (district.RequiresPopulation == true or district.RequiresPopulation == 1);
end

local function AttachMysterySystem(playerID :number)
	local player = GetPlayer(playerID);
	if player == nil
		or (player:GetProperty("LOTM_PP_MYSTERY_SYSTEM_ATTACHED") or 0) == 1 then
		return;
	end
	local attached = 0;
	for district in GameInfo.Districts() do
		if IsSpecialtyDistrict(district) then
			for yieldInfo in GameInfo.Yields() do
				if LOTM_PP_BASE_YIELDS[yieldInfo.YieldType] then
					player:AttachModifierByID(
						"LOTM_PP_MOD_MYSTERY_DISTRICT_"
							.. district.DistrictType .. "_" .. yieldInfo.YieldType
					);
					player:AttachModifierByID(
						"LOTM_PP_MOD_MYSTERY_BUILDING_"
							.. district.DistrictType .. "_" .. yieldInfo.YieldType
					);
					attached = attached + 2;
				end
			end
		end
	end
	player:SetProperty("LOTM_PP_MYSTERY_SYSTEM_ATTACHED", 1);
	Log("player=" .. tostring(playerID)
		.. " attached mystery-system modifiers=" .. tostring(attached));
end

local function ApplyKnowledgeTeaching(playerID :number)
	local player = GetPlayer(playerID);
	if player == nil then
		return;
	end
	local technologies = player:GetTechs();
	for technology in GameInfo.Technologies() do
		if not technologies:HasTech(technology.Index)
			and not technologies:HasBoostBeenTriggered(technology.Index) then
			technologies:TriggerBoost(technology.Index, 1);
		end
	end
	local culture = player:GetCulture();
	for civic in GameInfo.Civics() do
		if not culture:HasCivic(civic.Index)
			and not culture:HasBoostBeenTriggered(civic.Index) then
			culture:TriggerBoost(civic.Index, 1);
		end
	end
end

local function GrantEnlightenerScientistPoints(playerID :number)
	local player = GetPlayer(playerID);
	if player == nil
		or (player:GetProperty("LOTM_PP_ENLIGHTENER_POINTS_GRANTED") or 0) == 1 then
		return;
	end
	local scientistClass = GameInfo.GreatPersonClasses[
		"GREAT_PERSON_CLASS_SCIENTIST"
	];
	local points = player:GetGreatPeoplePoints();
	if scientistClass == nil or points == nil then
		Log("ERROR unable to grant Enlightener Great Scientist points player="
			.. tostring(playerID));
		return;
	end
	points:ChangePointsTotal(scientistClass.Index, 99999);
	player:SetProperty("LOTM_PP_ENLIGHTENER_POINTS_GRANTED", 1);
	Log("player=" .. tostring(playerID)
		.. " granted Enlightener Great Scientist points=99999");
end

local function AttachAppraiserModifiers(playerID :number)
	local player = GetPlayer(playerID);
	if player == nil or (player:GetProperty("LOTM_PP_APPRAISER_ATTACHED") or 0) == 1 then
		return;
	end
	local attached = 0;
	local seen :table = {};
	for yieldChange in GameInfo.GreatWork_YieldChanges() do
		local greatWork = GameInfo.GreatWorks[yieldChange.GreatWorkType];
		if greatWork ~= nil then
			local modifierID = "LOTM_PP_MOD_GREATWORK_"
				.. greatWork.GreatWorkObjectType .. "_" .. yieldChange.YieldType;
			if not seen[modifierID] then
				player:AttachModifierByID(modifierID);
				seen[modifierID] = true;
				attached = attached + 1;
			end
		end
	end
	player:SetProperty("LOTM_PP_APPRAISER_ATTACHED", 1);
	Log("player=" .. tostring(playerID)
		.. " attached appraiser great-work modifiers=" .. tostring(attached));
end

local function GrantNextRelic(playerID :number)
	local player = GetPlayer(playerID);
	if player == nil then
		return false;
	end
	local count = player:GetProperty("LOTM_PP_RELIC_COUNT") or 0;
	if count >= LOTM_PP_RELIC_LIMIT then
		return false;
	end
	local nextCount = count + 1;
	LOTM_RP_State.AttachModifierOnce(
		playerID,
		"LOTM_PP_MOD_GRANT_RELIC_V3_" .. tostring(nextCount),
		"LOTM_PP_RELIC_GRANT_V3_" .. tostring(nextCount)
	);
	player:SetProperty("LOTM_PP_RELIC_COUNT", nextCount);
	player:SetProperty(
		"LOTM_PP_NEXT_RELIC_TURN",
		nextCount < LOTM_PP_RELIC_LIMIT
			and Game.GetCurrentGameTurn() + LOTM_PP_RELIC_INTERVAL
			or -1
	);
	-- The relic ability is inherited, but its digestion task belongs only to
	-- the Archaeologist.  Later sequences keep their own event-based tasks.
	if GetSequence(playerID) == 8 then
		LOTM_RP_State.TryAddDigestion(
			playerID,
			"A",
			"PERFECT_RELIC:" .. tostring(nextCount)
		);
	end
	Log("player=" .. tostring(playerID)
		.. " granted path relic " .. tostring(nextCount)
		.. "/" .. tostring(LOTM_PP_RELIC_LIMIT));
	return true;
end

local function RepairRecordedRelicGrants(playerID :number, player)
	local count = math.min(
		LOTM_PP_RELIC_LIMIT,
		math.max(0, player:GetProperty("LOTM_PP_RELIC_COUNT") or 0)
	);
	for grantIndex = 1, count do
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			"LOTM_PP_MOD_GRANT_RELIC_V3_" .. tostring(grantIndex),
			"LOTM_PP_RELIC_GRANT_V3_" .. tostring(grantIndex)
		);
	end
end

local function ProcessRelics(playerID :number, allowTurnGrant :boolean)
	if GetSequence(playerID) > 8 then
		return;
	end
	local player = GetPlayer(playerID);
	if player == nil then
		return;
	end
	-- rc.26/27 recorded relic counters although their effects respectively
	-- lacked RunOnce or Amount. Attach corrected V3 grants for every recorded
	-- item; per-index properties make this save-safe.
	RepairRecordedRelicGrants(playerID, player);
	if (player:GetProperty("LOTM_PP_RELIC_STARTED") or 0) ~= 1 then
		player:SetProperty("LOTM_PP_RELIC_STARTED", 1);
		player:SetProperty("LOTM_PP_RELIC_COUNT", 0);
		player:SetProperty("LOTM_PP_NEXT_RELIC_TURN", Game.GetCurrentGameTurn());
		-- Continents already occupied when Sequence 8 begins are historical
		-- knowledge, not a new-continent discovery.
		for _, city in player:GetCities():Members() do
			local cityPlot = Map.GetPlot(city:GetX(), city:GetY());
			local continent = cityPlot ~= nil and cityPlot:GetContinentType() or -1;
			if continent >= 0 then
				player:SetProperty(
					"LOTM_PP_CONTINENT_SEEN_" .. tostring(continent),
					1
				);
			end
		end
		GrantNextRelic(playerID);
		return;
	end
	local nextTurn = player:GetProperty("LOTM_PP_NEXT_RELIC_TURN") or -1;
	if allowTurnGrant and nextTurn >= 0 and Game.GetCurrentGameTurn() >= nextTurn then
		GrantNextRelic(playerID);
	end
end

function LOTM_PP_RefreshSequenceState(playerID :number)
	if not IsPerfect(playerID) then
		return false;
	end
	local sequence = GetSequence(playerID);
	RepairLegacyAlchemistCharges(playerID);
	AttachSequenceModifiers(playerID, sequence);
	if sequence <= 3 then
		AttachMysterySystem(playerID);
	end
	if sequence <= 2 then
		ApplyKnowledgeTeaching(playerID);
	end
	if sequence <= 1 then
		GrantEnlightenerScientistPoints(playerID);
	end
	if sequence <= 7 then
		AttachAppraiserModifiers(playerID);
	end
	return true;
end

local function OnGreatWorkCreated(
	playerID :number,
	unitID :number,
	cityX :number,
	cityY :number,
	buildingID :number,
	greatWorkID :number
)
	if not IsPerfect(playerID) or GetSequence(playerID) ~= 7 then
		return;
	end
	local workKey = tostring(greatWorkID)
		.. ":" .. tostring(cityX) .. ":" .. tostring(cityY)
		.. ":" .. tostring(buildingID);
	LOTM_RP_State.TryAddDigestion(
		playerID, "A", "GREAT_WORK_ACQUIRED:" .. workKey
	);
	LOTM_RP_State.TryAddDigestion(
		playerID, "B", "GREAT_WORK_PLACED:" .. workKey
	);
end

local function NextEventSerial(player, property :string)
	local serial = (player:GetProperty(property) or 0) + 1;
	player:SetProperty(property, serial);
	return serial;
end

local function OnTechBoostTriggered(playerID :number)
	if not IsPerfect(playerID) or GetSequence(playerID) ~= 9 then
		return;
	end
	local player = GetPlayer(playerID);
	LOTM_RP_State.TryAddDigestion(
		playerID,
		"A",
		"TECH_BOOST:" .. tostring(NextEventSerial(player, "LOTM_PP_TECH_BOOST_SERIAL"))
	);
end

local function OnCivicBoostTriggered(playerID :number)
	if not IsPerfect(playerID) or GetSequence(playerID) ~= 9 then
		return;
	end
	local player = GetPlayer(playerID);
	LOTM_RP_State.TryAddDigestion(
		playerID,
		"B",
		"CIVIC_BOOST:" .. tostring(NextEventSerial(player, "LOTM_PP_CIVIC_BOOST_SERIAL"))
	);
end

local function OnGoodyHutReward(
	playerID :number,
	unitID :number,
	rewardType :number,
	rewardSubType :number
)
	if IsPerfect(playerID) and GetSequence(playerID) == 8 then
		local player = GetPlayer(playerID);
		LOTM_RP_State.TryAddDigestion(
			playerID,
			"B",
			"GOODY_HUT:"
				.. tostring(NextEventSerial(player, "LOTM_PP_GOODY_HUT_SERIAL"))
		);
	end
end

local function OnUnitMoveComplete(
	playerID :number,
	unitID :number,
	x :number,
	y :number
)
	if not IsPerfect(playerID) or GetSequence(playerID) ~= 8 then
		return;
	end
	local player = GetPlayer(playerID);
	local plot = Map.GetPlot(x, y);
	if player == nil or plot == nil then
		return;
	end
	local continent = plot:GetContinentType();
	if continent ~= nil and continent >= 0
		and (player:GetProperty("LOTM_PP_CONTINENT_SEEN_" .. tostring(continent)) or 0) ~= 1 then
		player:SetProperty("LOTM_PP_CONTINENT_SEEN_" .. tostring(continent), 1);
		LOTM_RP_State.TryAddDigestion(
			playerID, "B", "CONTINENT:" .. tostring(continent)
		);
	end
	local feature = GameInfo.Features[plot:GetFeatureType()];
	if feature ~= nil and feature.NaturalWonder
		and (player:GetProperty("LOTM_PP_WONDER_SEEN_" .. feature.FeatureType) or 0) ~= 1 then
		player:SetProperty("LOTM_PP_WONDER_SEEN_" .. feature.FeatureType, 1);
		LOTM_RP_State.TryAddDigestion(
			playerID, "B", "NATURAL_WONDER:" .. feature.FeatureType
		);
	end
end

local function OnUnitChargesChanged(
	playerID :number,
	unitID :number,
	newCharges :number,
	oldCharges :number
)
	if not IsPerfect(playerID)
		or (GetSequence(playerID) ~= 6 and GetSequence(playerID) ~= 4)
		or newCharges == nil or oldCharges == nil
		or newCharges >= oldCharges then
		return;
	end
	local player = GetPlayer(playerID);
	local unit = player ~= nil and player:GetUnits():FindID(unitID) or nil;
	local builder = GameInfo.Units["UNIT_BUILDER"];
	if unit == nil or builder == nil or unit:GetType() ~= builder.Index then
		return;
	end
	local serial = NextEventSerial(player, "LOTM_PP_BUILDER_CHARGE_SERIAL");
	LOTM_RP_State.TryAddDigestion(
		playerID, "A", "BUILDER_CHARGE:" .. tostring(serial)
	);
end

local function OnImprovementAddedToMap(
	x :number,
	y :number,
	improvementType :number,
	ownerID :number
)
	if IsPerfect(ownerID) and GetSequence(ownerID) == 6 then
		LOTM_RP_State.TryAddDigestion(
			ownerID,
			"B",
			"IMPROVEMENT:" .. tostring(x) .. ":" .. tostring(y)
				.. ":" .. tostring(Game.GetCurrentGameTurn())
		);
	end
end

local function IsCampusBuilding(buildingIndex :number)
	local building = GameInfo.Buildings[buildingIndex];
	return building ~= nil and building.PrereqDistrict == "DISTRICT_CAMPUS";
end

local function IsSpecialtyBuilding(buildingIndex :number)
	local building = GameInfo.Buildings[buildingIndex];
	local district = building ~= nil
		and GameInfo.Districts[building.PrereqDistrict] or nil;
	return IsSpecialtyDistrict(district);
end

local function OnBuildingConstructed(
	playerID :number,
	cityID :number,
	buildingIndex :number,
	plotIndex :number,
	isOriginalConstruction :boolean
)
	if not IsPerfect(playerID) or not isOriginalConstruction then
		return;
	end
	local sequence = GetSequence(playerID);
	if sequence == 5 and IsCampusBuilding(buildingIndex) then
		LOTM_RP_State.TryAddDigestion(
			playerID, "B", "CAMPUS_BUILDING:" .. tostring(cityID)
				.. ":" .. tostring(buildingIndex)
		);
	elseif sequence == 4 then
		LOTM_RP_State.TryAddDigestion(
			playerID, "B", "BUILDING:" .. tostring(cityID)
				.. ":" .. tostring(buildingIndex)
		);
	elseif sequence == 3 and IsSpecialtyBuilding(buildingIndex) then
		LOTM_RP_State.TryAddDigestion(
			playerID, "B", "SPECIALTY_BUILDING:" .. tostring(cityID)
				.. ":" .. tostring(buildingIndex)
		);
	end
end

local function OnDistrictAddedToMap(
	playerID :number,
	districtID :number,
	cityID :number,
	x :number,
	y :number,
	districtType :number,
	percentComplete :number
)
	if not IsPerfect(playerID) or percentComplete == nil or percentComplete < 100 then
		return;
	end
	local sequence = GetSequence(playerID);
	local district = GameInfo.Districts[districtType];
	if sequence == 5
		and district ~= nil
		and district.DistrictType == "DISTRICT_CAMPUS" then
		LOTM_RP_State.TryAddDigestion(
			playerID, "B", "CAMPUS_DISTRICT:" .. tostring(cityID)
				.. ":" .. tostring(districtID)
		);
	elseif sequence == 4 then
		LOTM_RP_State.TryAddDigestion(
			playerID, "B", "DISTRICT:" .. tostring(cityID)
				.. ":" .. tostring(districtID)
		);
	elseif sequence == 3 and IsSpecialtyDistrict(district) then
		LOTM_RP_State.TryAddDigestion(
			playerID, "A", "SPECIALTY_DISTRICT:" .. tostring(cityID)
				.. ":" .. tostring(districtID)
		);
	end
end

local function OnResearchCompleted(
	playerID :number,
	techIndex :number,
	isCanceled :boolean
)
	if not IsPerfect(playerID) or isCanceled then
		return;
	end
	local sequence = GetSequence(playerID);
	if sequence == 5 then
		LOTM_RP_State.TryAddDigestion(
			playerID, "A", "TECH_COMPLETED:" .. tostring(techIndex)
		);
	elseif sequence == 2 then
		LOTM_RP_State.TryAddDigestion(
			playerID, "A", "MENTOR_TECH:" .. tostring(techIndex)
		);
	elseif sequence == 1 then
		LOTM_RP_State.TryAddDigestion(
			playerID, "B", "ENLIGHTENER_KNOWLEDGE_TECH:" .. tostring(techIndex)
		);
	end
end

local function OnCivicCompleted(
	playerID :number,
	civicIndex :number,
	isCanceled :boolean
)
	if not IsPerfect(playerID) or isCanceled then
		return;
	end
	local sequence = GetSequence(playerID);
	if sequence == 2 then
		LOTM_RP_State.TryAddDigestion(
			playerID, "B", "MENTOR_CIVIC:" .. tostring(civicIndex)
		);
	elseif sequence == 1 then
		LOTM_RP_State.TryAddDigestion(
			playerID, "B", "ENLIGHTENER_KNOWLEDGE_CIVIC:" .. tostring(civicIndex)
		);
	end
end

local function OnUnitAddedToMap(playerID :number, unitID :number)
	if not IsPerfect(playerID) or GetSequence(playerID) ~= 1 then
		return;
	end
	local player = GetPlayer(playerID);
	local unit = player ~= nil and player:GetUnits():FindID(unitID) or nil;
	local unitInfo = unit ~= nil and GameInfo.Units[unit:GetType()] or nil;
	if unitInfo == nil or unitInfo.UnitType ~= "UNIT_GREAT_SCIENTIST" then
		return;
	end
	LOTM_RP_State.TryAddDigestion(
		playerID,
		"A",
		"GREAT_SCIENTIST_RECRUITED:"
			.. tostring(NextEventSerial(player, "LOTM_PP_SCIENTIST_RECRUIT_SERIAL"))
	);
end

local function OnCityProjectCompleted(
	playerID :number,
	cityID :number,
	projectIndex :number
)
	if not IsPerfect(playerID) then
		return;
	end
	local project = GameInfo.Projects[projectIndex];
	if project == nil then
		return;
	end
	local advance = LOTM_PP_PROJECT_ADVANCES[project.ProjectType];
	if advance ~= nil then
		if not LOTM_RP_State.AdvanceSequence(
			playerID,
			advance[1],
			advance[2],
			advance.allowWithoutChurch == true
		) then
			Log("ERROR rejected project advancement player=" .. tostring(playerID)
				.. " project=" .. project.ProjectType);
		elseif advance[2] == 8 then
			ProcessRelics(playerID, true);
		end
		return;
	end
	local sequence = GetSequence(playerID);
	if sequence == 5 and project.SpaceRace then
		LOTM_RP_State.TryAddDigestion(
			playerID, "B", "SPACE_PROJECT:" .. tostring(project.ProjectType)
				.. ":" .. tostring(Game.GetCurrentGameTurn())
		);
	elseif sequence == 4 then
		LOTM_RP_State.TryAddDigestion(
			playerID, "B", "CITY_PROJECT:" .. tostring(project.ProjectType)
				.. ":" .. tostring(cityID)
				.. ":" .. tostring(Game.GetCurrentGameTurn())
		);
	end
end

local function ProcessPlayer(playerID :number, allowTurnGrant :boolean)
	if not IsPerfect(playerID) then
		return;
	end
	LOTM_PP_RefreshSequenceState(playerID);
	ProcessRelics(playerID, allowTurnGrant);
end

function LOTM_PP_OnPathSelected(playerID :number)
	ProcessPlayer(playerID, true);
end

local function OnPlayerTurnActivated(playerID :number, isFirstTimeThisTurn :boolean)
	ProcessPlayer(playerID, isFirstTimeThisTurn);
end

local function Initialize()
	Events.PlayerTurnActivated.Add(OnPlayerTurnActivated);
	Events.TechBoostTriggered.Add(OnTechBoostTriggered);
	Events.CivicBoostTriggered.Add(OnCivicBoostTriggered);
	Events.GoodyHutReward.Add(OnGoodyHutReward);
	Events.UnitMoveComplete.Add(OnUnitMoveComplete);
	Events.UnitChargesChanged.Add(OnUnitChargesChanged);
	Events.ImprovementAddedToMap.Add(OnImprovementAddedToMap);
	Events.DistrictAddedToMap.Add(OnDistrictAddedToMap);
	Events.ResearchCompleted.Add(OnResearchCompleted);
	Events.CivicCompleted.Add(OnCivicCompleted);
	Events.UnitAddedToMap.Add(LOTM_UnitAddedPerf.Wrap("Perfect",OnUnitAddedToMap));
	Events.CityProjectCompleted.Add(OnCityProjectCompleted);
	Events.GreatWorkCreated.Add(OnGreatWorkCreated);
	GameEvents.BuildingConstructed.Add(OnBuildingConstructed);
	for _, playerID in ipairs(PlayerManager.GetAliveMajorIDs()) do
		ProcessPlayer(playerID, false);
	end
	Log("initialized Perfect Path Sequence 9 through Sequence 0");
end

Initialize();
-- END POST_RC241_RULES MODULE: Scripts/LOTM_PP_Perfect.lua
end;

m_mp241Loaders["LOTM_PP_Workshops"] = function()
-- BEGIN POST_RC241_DELTA MODULE: Scripts/LOTM_PP_Workshops.lua
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("MP.LOTM_PP_Workshops","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"MP.LOTM_PP_Workshops","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"MP.LOTM_PP_Workshops","GameEvents");
-- END RC342 STARTUP TRACE

-- 全局失控工坊。保持原版 BARBARIAN_CAMP 改良与部落 AI，只在同步端
-- 记录分类、守卫、额外刷兵、0级来源强化和人类清营奖励。
LOTM_MP241_LoadBundledModule("LOTM_Effects");

local CAMP :number = GameInfo.Improvements.IMPROVEMENT_BARBARIAN_CAMP.Index;
local NORMAL_SEQUENCE_UNIT :number = GameInfo.Units.UNIT_LOTM_PP_PATH_HOLDER.Index;
local RESCUE_LEGACY_TYPES={
 [2]="UNIT_LOTM_RESCUE_LOST_CONTROL_LOW",
 [1]="UNIT_LOTM_RESCUE_LOST_CONTROL_MID",
 [0]="UNIT_LOTM_RESCUE_LOST_CONTROL_HIGH"
};
local RESCUE_FINAL_BATTLE_TYPES={};
for _,unitType in ipairs({"UNIT_LOTM_RESCUE_OUTER_GOD_AVATAR","UNIT_LOTM_RESCUE_OUTER_GOD_MINION"}) do
 local info=GameInfo.Units[unitType]; if info~=nil then RESCUE_FINAL_BATTLE_TYPES[info.Index]=true; end
end
local CLASSIFIED="LOTM_PP_WORKSHOP_CLASSIFIED"; local IS_WORKSHOP="LOTM_PP_WORKSHOP_IS_WORKSHOP";
local LEVEL="LOTM_PP_WORKSHOP_LEVEL"; local SETTLED="LOTM_PP_WORKSHOP_REWARD_SETTLED";
local SPAWNS="LOTM_PP_WORKSHOP_NORMAL_SPAWN_COUNT"; local CLEARER="LOTM_PP_WORKSHOP_LAST_HUMAN";
local SEQUENCE_CREATED="LOTM_PP_WORKSHOP_SEQUENCE_CREATED";
local m_internalCreate=false;
local m_barbarianID=nil;
-- Version 3 is a one-time resource-287 migration.  It deterministically
-- rediscovers resource-286 camps that may have been saved after their local
-- ImprovementAddedToMap callback but before the next synchronized anchor.
local WORKSHOP_REGISTRY_VERSION=3;
local WORKSHOP_REGISTRY_VERSION_KEY="LOTM_PP_WORKSHOP_REGISTRY_VERSION";
local WORKSHOP_REGISTRY_PLOTS_KEY="LOTM_PP_WORKSHOP_REGISTRY_PLOTS";
local CLASSIFICATION_VERSION=1;
local CLASSIFICATION_VERSION_PROPERTY="LOTM_PP_WORKSHOP_DETERMINISTIC_VERSION";
local BIRTH_RECONCILE_VERSION=1;
local BIRTH_RECONCILE_VERSION_PROPERTY="LOTM_PP_WORKSHOP_BIRTH_RECONCILE_VERSION";
local STABLE_MODULUS=2147483647;
local m_classificationSeed=nil;
local m_workshopPlots={};
local m_workshopSet={};
local m_workshopCoverage={};
local m_registryReady=false;
-- ImprovementAddedToMap is a local publication callback.  In network games
-- its delivery may be interleaved with synchronized player operations in a
-- different order on each peer, so it may only populate this Lua-local queue.
-- All Gameplay mutation is delayed to a later stable world-turn edge.
local m_networkImprovementAdditions={};
local m_networkImprovementPlots={};
local m_networkImprovementBoundaryTurn=nil;
local m_networkUnitAdditionsLocal={};
local m_networkUnitAdditionKeys={};
local m_networkUnitRemovalBatches={};
local m_networkUnitRemovalBatchKeys={};
local m_networkImprovementRemovals={};
local m_networkImprovementRemovalKeys={};
local m_networkImprovementRemovedPlots={};
local m_networkImprovementRemovalProcessedPlots={};
local m_networkImprovementRemovalProcessedPlotKeys={};
local m_networkUnitRemovals={};
local m_networkUnitRemovalKeys={};
local QueueNetworkWorkshopSettlement;
LOTM_PP_Workshops=LOTM_PP_Workshops or {};
local PATH="LOTM_PP_WORKSHOP_PATH";
local PATHS={"PP","RP","BE"};
local SEQUENCE_STRENGTH_ABILITY="ABILITY_LOTM_PP_WORKSHOP_SEQUENCE_STRENGTH";
local DYNAMIC_STRENGTH_ABILITY="ABILITY_LOTM_WORLD_DYNAMIC_STRENGTH";
local RESCUE_MONSTER_STRENGTH_ABILITY="ABILITY_LOTM_WORLD_MONSTER_FRENZY_STRENGTH_V2";
local RESCUE_TIER_STRENGTH_ABILITIES={{1,"ABILITY_LOTM_WORLD_MONSTER_TIER_MID_STRENGTH"},{0,"ABILITY_LOTM_WORLD_MONSTER_TIER_HIGH_STRENGTH"}};
local RESCUE_MONSTER_UNIT_TYPE="LOTM_RESCUE_CENTER_MONSTER_UNIT_TYPE";
local SEQUENCE_STRENGTH_ABILITIES={
 {10,SEQUENCE_STRENGTH_ABILITY},
 {20,"ABILITY_LOTM_PP_WORKSHOP_SEQUENCE_20"},
 {30,"ABILITY_LOTM_PP_WORKSHOP_SEQUENCE_30"},
 {25,"ABILITY_LOTM_PP_WORKSHOP_SEQUENCE_25"},
 {35,"ABILITY_LOTM_PP_WORKSHOP_SEQUENCE_35"},
 {45,"ABILITY_LOTM_PP_WORKSHOP_SEQUENCE_45"},
 {55,"ABILITY_LOTM_PP_WORKSHOP_SEQUENCE_55"},
 {65,"ABILITY_LOTM_PP_WORKSHOP_SEQUENCE_65"},
 {75,"ABILITY_LOTM_PP_WORKSHOP_SEQUENCE_75"},
 {85,"ABILITY_LOTM_PP_WORKSHOP_SEQUENCE_85"},
 {95,"ABILITY_LOTM_PP_WORKSHOP_SEQUENCE_95"}
};
local SEQUENCE_STRENGTH_COUNT="LOTM_PP_WORKSHOP_STRENGTH_COUNT";
local PERIOD_STRENGTH_PROPERTY="LOTM_RESCUE_PHASE5_BIRTH_BONUS";
local RESCUE_SEQUENCE_SERIAL="LOTM_RESCUE_PHASE4_SEQUENCE_SERIAL";
local CLEARER_UNIT="LOTM_PP_WORKSHOP_CLEARER_UNIT";
local CLASSIFIED_TURN="LOTM_RESCUE_WORKSHOP_CLASSIFIED_TURN";
local CAMP_EPOCH="LOTM_PP_WORKSHOP_CAMP_EPOCH";
local CAMP_TRIBE_INDEX="LOTM_PP_WORKSHOP_CAMP_TRIBE_INDEX";
local CAMP_REBUILD_PENDING="LOTM_PP_WORKSHOP_CAMP_REBUILD_PENDING";
local CAMP_EPOCH_COUNTER_PREFIX="LOTM_PP_WORKSHOP_CAMP_EPOCH_COUNTER:";
local MP_PENDING_SETTLEMENTS="LOTM_PP_WORKSHOP_MP_PENDING_SETTLEMENTS";
local MP_PENDING="LOTM_PP_WORKSHOP_MP_PENDING";
local MP_PENDING_OWNER="LOTM_PP_WORKSHOP_MP_PENDING_OWNER";
local MP_PENDING_CLEARER="LOTM_PP_WORKSHOP_MP_PENDING_CLEARER";
local MP_PENDING_CLEARER_UNIT="LOTM_PP_WORKSHOP_MP_PENDING_CLEARER_UNIT";
local MP_PENDING_LEVEL="LOTM_PP_WORKSHOP_MP_PENDING_LEVEL";
local MP_PENDING_PATH="LOTM_PP_WORKSHOP_MP_PENDING_PATH";
local MP_PENDING_CLASSIFIED_TURN="LOTM_PP_WORKSHOP_MP_PENDING_CLASSIFIED_TURN";
local MP_PENDING_CAMP_EPOCH="LOTM_PP_WORKSHOP_MP_PENDING_CAMP_EPOCH";
-- Multiplayer queues are committed at a synchronized turn boundary only.
-- Keep the enqueue turn separate from the legacy classification turn so a
-- callback arriving after the anchor event cannot be settled in the same
-- turn.  The two boundary markers also make reconnect/repeated callbacks
-- harmless: each queue is considered at most once per world turn.
local MP_PENDING_QUEUED_TURN="LOTM_PP_WORKSHOP_MP_PENDING_QUEUED_TURN";
local MP_UNIT_QUEUE_LAST_BOUNDARY="LOTM_PP_WORKSHOP_MP_UNIT_QUEUE_LAST_BOUNDARY";
local MP_SETTLEMENT_QUEUE_LAST_BOUNDARY="LOTM_PP_WORKSHOP_MP_SETTLEMENT_QUEUE_LAST_BOUNDARY";
local MP_UNIT_COMMITTED_TOKEN="LOTM_PP_WORKSHOP_MP_UNIT_COMMITTED_TOKEN";
local MP_UNIT_GENERATION_PROPERTY="LOTM_PP_WORKSHOP_MP_UNIT_GENERATION";
local MP_UNIT_EPOCH_PREFIX="LOTM_PP_WORKSHOP_MP_UNIT_EPOCH:";
local MP_UNIT_STAGE_PREFIX="LOTM_PP_WORKSHOP_MP_UNIT_STAGE:";
local MP_CHURCH_SETTLED="LOTM_PP_WORKSHOP_MP_CHURCH_SETTLED";
local MP_PHASE4_SETTLED="LOTM_PP_WORKSHOP_MP_PHASE4_SETTLED";
local MP_REWARD_SETTLED="LOTM_PP_WORKSHOP_MP_REWARD_SETTLED";
local MP_PENDING_UNIT_ADDITIONS="LOTM_PP_WORKSHOP_MP_PENDING_UNIT_ADDITIONS";
local PERIOD_STRENGTH_ABILITIES={
 {10,"ABILITY_LOTM_RESCUE_PERIOD_STRENGTH_10"},
 {20,"ABILITY_LOTM_RESCUE_PERIOD_STRENGTH_20"},
 {30,"ABILITY_LOTM_RESCUE_PERIOD_STRENGTH_30"},
 {40,"ABILITY_LOTM_RESCUE_PERIOD_STRENGTH_40"}
};
local SEQUENCE_NAMES={
 PP={[2]="LOC_LOTM_PP_ASTRONOMER_NAME",[1]="LOC_LOTM_PP_MYSTICIST_NAME",[0]="LOC_LOTM_PP_ENLIGHTENER_NAME"},
 RP={[2]="LOC_LOTM_RP_WORKSHOP_HARVESTER_NAME",[1]="LOC_LOTM_RP_WORKSHOP_WAR_BISHOP_NAME",[0]="LOC_LOTM_RP_WORKSHOP_CONQUEROR_NAME"},
 BE={[2]="LOC_LOTM_BE_WORKSHOP_CHAOS_MENTOR_NAME",[1]="LOC_LOTM_BE_WORKSHOP_FRENZY_MAGE_NAME",[0]="LOC_LOTM_BE_WORKSHOP_PRINCE_NAME"}
};
local RESCUE_NAMES={
 [2]="LOC_LOTM_WORLD_MONSTER_LOW_NAME",
 [1]="LOC_LOTM_WORLD_MONSTER_MID_NAME",
 [0]="LOC_LOTM_WORLD_MONSTER_HIGH_NAME"
};
local RESCUE_BONUS={[2]=15,[1]=25,[0]=35};
local PHASE4_VERSION=5;
LOTM_RESCUE_Phase4=LOTM_RESCUE_Phase4 or {};

local function Log(s) print("[LOTM_PP][Workshops] "..tostring(s)); end
local function NumberValue(value) if value==nil then return nil; end return tonumber(value); end
local function Verbose() return NumberValue(Game.GetProperty("LOTM_RESCUE_VERBOSE_LOGS"))==1; end
local function Trace(s) if Verbose() then Log(s); end end
local function RemoveNetworkPendingSettlementIndex(plotIndex)
 local indices={}; local seen={};
 for token in string.gmatch(tostring(Game.GetProperty(MP_PENDING_SETTLEMENTS) or ""),"[^,]+") do
  local current=tonumber(token);
  if current~=nil and current>=0 and current~=plotIndex and not seen[current] then
   seen[current]=true; indices[#indices+1]=current;
  end
 end
 table.sort(indices);
 local serialized=table.concat(indices,",");
 if tostring(Game.GetProperty(MP_PENDING_SETTLEMENTS) or "")~=serialized then
  Game.SetProperty(MP_PENDING_SETTLEMENTS,serialized);
 end
end
local function LocalNetworkUnitBatchKey(owner,unitID,queuedTurn)
 return table.concat({tonumber(queuedTurn) or -1,tonumber(owner) or -1,tonumber(unitID) or -1},":");
end
local function MarkNetworkUnitAdditionFiltered(unit)
 if unit==nil or LOTM_MP_TurnSync==nil or not LOTM_MP_TurnSync.IsNetworkGame() then return; end
 local owner=tonumber(unit:GetOwner()); local unitID=tonumber(unit:GetID());
 if owner==nil or unitID==nil then return; end
 local entry=m_networkUnitAdditionKeys[LocalNetworkUnitBatchKey(owner,unitID,Game.GetCurrentGameTurn())];
 if entry~=nil then entry.Filtered=true; end
end
function LOTM_PP_Workshops.MarkNetworkUnitFiltered(unit)
 MarkNetworkUnitAdditionFiltered(unit);
end
local function IsRescueMode()
 if LOTM_MP_TurnSync~=nil
  and type(LOTM_MP_TurnSync.IsRescueModeConfigured)=="function"
  and LOTM_MP_TurnSync.IsRescueModeConfigured() then return true; end
 return NumberValue(Game.GetProperty("LOTM_RESCUE_MODE"))==1;
end
-- Direct rescue monsters write their durable owner:unit -> serial index just
-- after InitUnit.  UnitAddedToMap can be delivered one turn later (especially
-- in single-player save/load), before the transient unit properties are
-- visible to this callback.  Treat a live durable index as monster identity so
-- the rescue normal-barbarian cleanup cannot kill freshly spawned Madness units.
-- The ordinary confirmed-spawn path remains guarded by LOTM_WORLD_Monsters.IsMonster(u).
local function IsDurableRescueMonster(playerID,unitID,unit)
 if unit~=nil and LOTM_WORLD_Monsters~=nil and LOTM_WORLD_Monsters.IsMonster~=nil
  and LOTM_WORLD_Monsters.IsMonster(unit) then return true; end
 local owner=tonumber(playerID); local id=tonumber(unitID); if owner==nil or id==nil then return false; end
 local serial=tonumber(Game.GetProperty("LOTM_WORLD_MONSTER_ENGINE:"..owner..":"..id) or 0) or 0;
 if serial<=0 then return false; end
 return (tonumber(Game.GetProperty("LOTM_WORLD_MONSTER:"..serial..":LIVE") or 0) or 0)==1;
end
local function NormalizeStableValue(value)
 local numeric=math.floor(tonumber(value) or 0)%STABLE_MODULUS;
 if numeric<0 then numeric=numeric+STABLE_MODULUS; end
 return numeric;
end
local function MixStableValue(value,component)
 return (NormalizeStableValue(value)*48271+NormalizeStableValue(component)+1)%STABLE_MODULUS;
end
local function StableTextValue(value)
 local result=0; local text=tostring(value or "");
 for index=1,#text do result=(result*131+string.byte(text,index))%STABLE_MODULUS; end
 return result;
end
local function ClassificationSeed()
 if m_classificationSeed==nil then
  local gameSeed=GameConfiguration~=nil and GameConfiguration.GetValue~=nil and GameConfiguration.GetValue("GAME_SYNC_RANDOM_SEED") or 0;
  local mapSeed=MapConfiguration~=nil and MapConfiguration.GetValue~=nil and MapConfiguration.GetValue("RANDOM_SEED") or nil;
  if mapSeed==nil and GameConfiguration~=nil and GameConfiguration.GetValue~=nil then mapSeed=GameConfiguration.GetValue("MAP_RANDOM_SEED"); end
  m_classificationSeed=MixStableValue(MixStableValue(104729,gameSeed),mapSeed or 0);
 end
 return m_classificationSeed;
end
local function StableClassificationRoll(plotIndex,channel,maxExclusive)
 local limit=math.floor(tonumber(maxExclusive) or 0); if limit<=1 then return 0; end
 local value=MixStableValue(ClassificationSeed(),plotIndex);
 value=MixStableValue(value,StableTextValue(channel));
 return value%limit;
end
local function BarbarianID()
 if m_barbarianID==nil or m_barbarianID<0 then
  m_barbarianID=-1;
  for _,p in ipairs(PlayerManager.GetAliveBarbarians()) do m_barbarianID=p:GetID(); break; end
 end
 return m_barbarianID;
end
local function IsWorkshopPlot(plot)
 return plot~=nil and plot:GetImprovementType()==CAMP and (plot:GetProperty(IS_WORKSHOP) or 0)==1;
end
local function InsertWorkshopIndex(plotIndex)
 if plotIndex==nil or plotIndex<0 or m_workshopSet[plotIndex] then return false; end
 local inserted=false;
 for position,current in ipairs(m_workshopPlots) do
  if plotIndex<current then table.insert(m_workshopPlots,position,plotIndex); inserted=true; break; end
 end
 if not inserted then m_workshopPlots[#m_workshopPlots+1]=plotIndex; end
 m_workshopSet[plotIndex]=true;
 return true;
end
local function SaveWorkshopRegistry()
 local serialized=table.concat(m_workshopPlots,",");
 if tostring(Game.GetProperty(WORKSHOP_REGISTRY_PLOTS_KEY) or "")~=serialized then Game.SetProperty(WORKSHOP_REGISTRY_PLOTS_KEY,serialized); end
 if NumberValue(Game.GetProperty(WORKSHOP_REGISTRY_VERSION_KEY))~=WORKSHOP_REGISTRY_VERSION then Game.SetProperty(WORKSHOP_REGISTRY_VERSION_KEY,WORKSHOP_REGISTRY_VERSION); end
end
local function AddWorkshopCoverage(plot)
 if not IsWorkshopPlot(plot) then return; end
 local plotIndex=plot:GetIndex();
 for dx=-3,3 do for dy=-3,3 do
  local covered=Map.GetPlotXYWithRangeCheck(plot:GetX(),plot:GetY(),dx,dy,3);
  if covered~=nil then
   local coveredIndex=covered:GetIndex(); local candidates=m_workshopCoverage[coveredIndex];
   if candidates==nil then candidates={}; m_workshopCoverage[coveredIndex]=candidates; end
   local exists=false; for _,candidate in ipairs(candidates) do if candidate==plotIndex then exists=true; break; end end
   if not exists then candidates[#candidates+1]=plotIndex; end
  end
 end end
end
local function BuildWorkshopCoverage()
 m_workshopCoverage={};
 for _,plotIndex in ipairs(m_workshopPlots) do AddWorkshopCoverage(Map.GetPlotByIndex(plotIndex)); end
end
local function RegisterWorkshopPlot(plot)
 if not IsWorkshopPlot(plot) then return false; end
 if not InsertWorkshopIndex(plot:GetIndex()) then return false; end
 if m_registryReady then AddWorkshopCoverage(plot); SaveWorkshopRegistry(); end
 return true;
end
local function UnregisterWorkshopPlot(plotIndex)
 if not m_workshopSet[plotIndex] then return false; end
 for position,current in ipairs(m_workshopPlots) do if current==plotIndex then table.remove(m_workshopPlots,position); break; end end
 m_workshopSet[plotIndex]=nil;
 if m_registryReady then BuildWorkshopCoverage(); SaveWorkshopRegistry(); end
 return true;
end
local function ResetWorkshopRegistry()
 m_workshopPlots={}; m_workshopSet={}; m_workshopCoverage={}; m_registryReady=false;
end
local function LoadWorkshopRegistry()
 ResetWorkshopRegistry();
 local serialized=tostring(Game.GetProperty(WORKSHOP_REGISTRY_PLOTS_KEY) or ""); local rejected=0;
 for token in string.gmatch(serialized,"[^,]+") do
  local plotIndex=tonumber(token); local plot=plotIndex~=nil and Map.GetPlotByIndex(plotIndex) or nil;
  if plotIndex~=nil and plotIndex>=0 and IsWorkshopPlot(plot) then
   InsertWorkshopIndex(plotIndex);
  else
   rejected=rejected+1;
   -- If a network save was taken after the camp vanished but before its
   -- local removal publication crossed the next stable turn, the serialized
   -- registry is the durable evidence. Recover only that stale indexed plot;
   -- never rescan the map during ordinary reloads.
   if LOTM_MP_TurnSync.IsNetworkGame() and plot~=nil
    and (plot:GetProperty(CLASSIFIED) or 0)==1
    and (plot:GetProperty(IS_WORKSHOP) or 0)==1
    and (plot:GetProperty(SETTLED) or 0)~=1
    and QueueNetworkWorkshopSettlement~=nil then
    QueueNetworkWorkshopSettlement(plot,plot:GetOwner());
   end
  end
 end
 BuildWorkshopCoverage(); m_registryReady=true; SaveWorkshopRegistry();
 return rejected;
end
local function SequenceEngineKey(playerID,unitID) return "LOTM_RESCUE_PHASE4_ENGINE_"..tostring(playerID).."_"..tostring(unitID); end
local function SequenceSerialEngineKey(playerID,unitID) return "LOTM_RESCUE_PHASE4_SERIAL_ENGINE_"..tostring(playerID).."_"..tostring(unitID); end
local function EnsurePhase4State()
 if not IsRescueMode() then return; end
 if NumberValue(Game.GetProperty("LOTM_RESCUE_PHASE4_VERSION"))~=PHASE4_VERSION then
  Game.SetProperty("LOTM_RESCUE_PHASE4_VERSION",PHASE4_VERSION);
  Game.SetProperty("LOTM_RESCUE_PHASE4_STATE","READY");
  Log("phase4 READY version="..PHASE4_VERSION.." centerMonster=true tierBonus=15/25/35 purification=false");
 end
 local phase=NumberValue(Game.GetProperty("LOTM_RESCUE_PHASE")) or 0;
 if phase<4 then Game.SetProperty("LOTM_RESCUE_PHASE",4); end
end
local function RescueUnitIndex(unit)
 local frozenType=unit~=nil and unit:GetProperty(RESCUE_MONSTER_UNIT_TYPE) or nil;
 local frozenInfo=frozenType~=nil and GameInfo.Units[frozenType] or nil;
 if frozenInfo~=nil then return frozenInfo.Index; end
 local barbarianID=BarbarianID();
 local resolved=barbarianID>=0 and LOTM_WORLD_Barbarians.ResolveMeleeBaseline(barbarianID) or nil;
 return resolved~=nil and resolved.Index or NORMAL_SEQUENCE_UNIT;
end
local function SequenceUnitIndex(level,unit)
 return IsRescueMode() and RescueUnitIndex(unit) or NORMAL_SEQUENCE_UNIT;
end
local function CurrentPeriodBonus()
 if not IsRescueMode() or LOTM_RESCUE_Phase5==nil or LOTM_RESCUE_Phase5.BirthStrengthBonus==nil then return 0; end
 return LOTM_RESCUE_Phase5.BirthStrengthBonus();
end
if LOTM_RESCUE_Phase4.OnWorkshopCleared==nil then
 function LOTM_RESCUE_Phase4.OnWorkshopCleared(workshopLevel,clearerPlayerID) end
end
if LOTM_RESCUE_Phase4.OnLostControlKilled==nil then
 function LOTM_RESCUE_Phase4.OnLostControlKilled(lostControlTier,killerPlayerID) end
end
local function IsHumanMajor(id)
 local p=Players[id]; return p~=nil and p:IsAlive() and p:IsMajor() and p:IsHuman();
end
local function IsLegalResolver(id)
 local p=Players[id]; if p==nil or not p:IsAlive() then return false; end
 if p:IsMajor() then return true; end
 local config=PlayerConfigurations[id];
 return config~=nil and config:GetCivilizationLevelTypeName()=="CIVILIZATION_LEVEL_CITY_STATE";
end
local function RollLevel(plotIndex)
 local r=StableClassificationRoll(plotIndex,"LEVEL",100);
 if IsRescueMode() and LOTM_RESCUE_Phase5~=nil and LOTM_RESCUE_Phase5.WorkshopLevelChances~=nil then
  local low,mid,high=LOTM_RESCUE_Phase5.WorkshopLevelChances();
  if r<low then return 2 elseif r<low+mid then return 1 else return 0; end
 end
 local era=Game.GetEras():GetCurrentEra();
 if era<=2 then return 2 elseif era==3 then return r<60 and 2 or 1
 elseif era==4 then return r<30 and 2 or (r<75 and 1 or 0)
 elseif era==5 then return r<20 and 2 or (r<55 and 1 or 0)
 elseif era==6 then return r<15 and 2 or (r<40 and 1 or 0)
 elseif era==7 then return r<10 and 2 or (r<30 and 1 or 0)
 else return r<10 and 2 or (r<25 and 1 or 0) end
end
local function EnsureSequenceStrength(unit,desiredCount)
 local ability=unit:GetAbility(); if ability==nil then Log("sequence ability interface missing unit="..tostring(unit:GetID())); return; end
 local baseline=NumberValue(desiredCount) or NumberValue(unit:GetProperty("LOTM_PP_WORKSHOP_BASELINE_V2"));
 if baseline==nil then local resolved=LOTM_WORLD_Barbarians.ResolveMeleeBaseline(unit:GetOwner()); baseline=resolved~=nil and resolved.Combat or 20; end
 local info=GameInfo.Units[unit:GetType()]; local unitBase=info~=nil and (NumberValue(info.Combat) or 20) or 20;
 local level=NumberValue(unit:GetProperty(LEVEL)) or 2;
 local rescue=IsRescueMode(); local bonus=rescue and (RESCUE_BONUS[level] or 15) or 10;
 local desired=rescue and 0 or math.max(0,baseline+bonus-unitBase); unit:SetProperty("LOTM_PP_WORKSHOP_BASELINE_V2",baseline); unit:SetProperty(SEQUENCE_STRENGTH_COUNT,rescue and bonus or desired);
 LOTM_Effects.SetAbilityCount(ability,DYNAMIC_STRENGTH_ABILITY,0);
 local selected=LOTM_Effects.SyncAbilityTiers(ability,SEQUENCE_STRENGTH_ABILITIES,not rescue and desired or nil);
 if GameInfo.UnitAbilities[RESCUE_MONSTER_STRENGTH_ABILITY]~=nil then LOTM_Effects.SetAbilityCount(ability,RESCUE_MONSTER_STRENGTH_ABILITY,rescue and 1 or 0); end
 LOTM_Effects.SyncAbilityTiers(ability,RESCUE_TIER_STRENGTH_ABILITIES,rescue and level or nil,GameInfo.UnitAbilities);
 local periodBonus=IsRescueMode() and (NumberValue(unit:GetProperty(PERIOD_STRENGTH_PROPERTY)) or 0) or 0;
 LOTM_Effects.SyncAbilityTiers(ability,PERIOD_STRENGTH_ABILITIES,periodBonus,GameInfo.UnitAbilities);
 if rescue and LOTM_RESCUE_Artifacts~=nil and LOTM_RESCUE_Artifacts.ApplyMonsterWeather~=nil then LOTM_RESCUE_Artifacts.ApplyMonsterWeather(unit); end
 Trace("sequence strength unit="..tostring(unit:GetID()).." B="..tostring(baseline).." level="..level.." bonus="..bonus.." periodBonus="..periodBonus.." target="..tostring(baseline+bonus+periodBonus).." ability="..tostring(rescue and RESCUE_MONSTER_STRENGTH_ABILITY or selected));
end
local function ApplySequenceName(unit,path,level)
 local numericLevel=NumberValue(level) or 2;
 local names=SEQUENCE_NAMES[path] or SEQUENCE_NAMES.PP;
 local tag=IsRescueMode() and (RESCUE_NAMES[numericLevel] or RESCUE_NAMES[2]) or (names[numericLevel] or names[2]);
 local veteranName=Locale.Lookup(tag);
 if LOTM_MP_TurnSync.IsNetworkGame() then
  veteranName=IsRescueMode() and ("LOTM_RESCUE_MONSTER_"..numericLevel)
   or ("LOTM_WORKSHOP_SEQUENCE_"..tostring(path or "PP").."_"..numericLevel);
 end
 local experience=unit:GetExperience(); experience:SetExperienceLocked(true); experience:SetVeteranName(veteranName);
end
local function EnsureSequenceSerial(unit)
 if not IsRescueMode() then return 0; end
 local serial=NumberValue(unit:GetProperty(RESCUE_SEQUENCE_SERIAL));
 if serial==nil or serial<=0 then serial=(NumberValue(Game.GetProperty("LOTM_RESCUE_PHASE4_NEXT_SEQUENCE_SERIAL")) or 0)+1; Game.SetProperty("LOTM_RESCUE_PHASE4_NEXT_SEQUENCE_SERIAL",serial); unit:SetProperty(RESCUE_SEQUENCE_SERIAL,serial); end
 Game.SetProperty(SequenceSerialEngineKey(unit:GetOwner(),unit:GetID()),serial);
 return serial;
end
local function MarkSequence(unit,level,plotIndex,path,baseline,periodBonus,baselineType)
 unit:SetProperty("LOTM_PP_WORKSHOP_SEQUENCE",1); unit:SetProperty("LOTM_PP_WORKSHOP_LEVEL",level); unit:SetProperty("LOTM_PP_WORKSHOP_PATH",path); unit:SetProperty("LOTM_PP_WORKSHOP_PLOT",plotIndex); unit:SetProperty("LOTM_PP_WORKSHOP_BASELINE",baseline or 20);
 if IsRescueMode() then local info=GameInfo.Units[unit:GetType()]; unit:SetProperty("LOTM_RESCUE_CENTER_MONSTER",1); unit:SetProperty(RESCUE_MONSTER_UNIT_TYPE,baselineType or (info~=nil and info.UnitType or nil)); end
 unit:SetProperty(PERIOD_STRENGTH_PROPERTY,IsRescueMode() and (NumberValue(periodBonus) or 0) or 0);
 MarkNetworkUnitAdditionFiltered(unit);
 EnsureSequenceStrength(unit,baseline or 20);
 if IsRescueMode() then Game.SetProperty(SequenceEngineKey(unit:GetOwner(),unit:GetID()),NumberValue(level) or 2); EnsureSequenceSerial(unit); end
 ApplySequenceName(unit,path,level); UnitManager.FinishMoves(unit);
end
local function EnsureSequence(plot)
 EnsurePhase4State();
 if IsRescueMode() then return; end
 if (plot:GetProperty(IS_WORKSHOP) or 0)~=1 then return; end
 local barb=BarbarianID(); if barb<0 then return; end
 local existingUnits=Units.GetUnitsInPlot(plot) or {};
 if LOTM_MP_TurnSync.IsNetworkGame() then table.sort(existingUnits,function(a,b) if a:GetOwner()~=b:GetOwner() then return a:GetOwner()<b:GetOwner(); end return a:GetID()<b:GetID(); end); end
 for _,u in ipairs(existingUnits) do if u:GetOwner()==barb and (u:GetProperty("LOTM_PP_WORKSHOP_SEQUENCE") or 0)==1 then
  local level=NumberValue(u:GetProperty(LEVEL) or plot:GetProperty(LEVEL)) or 2; local expectedType=SequenceUnitIndex(level,u);
  if u:GetType()~=expectedType then
   local baseline=NumberValue(u:GetProperty("LOTM_PP_WORKSHOP_BASELINE_V2")) or NumberValue(u:GetProperty("LOTM_PP_WORKSHOP_BASELINE")) or 20;
   local path=u:GetProperty(PATH) or plot:GetProperty(PATH) or "PP"; local periodBonus=NumberValue(u:GetProperty(PERIOD_STRENGTH_PROPERTY)) or 0;
   Game.SetProperty(SequenceEngineKey(u:GetOwner(),u:GetID()),nil); Game.SetProperty(SequenceSerialEngineKey(u:GetOwner(),u:GetID()),nil); UnitManager.Kill(u);
   m_internalCreate=true; local migrated=UnitManager.InitUnit(barb,expectedType,plot:GetX(),plot:GetY()); m_internalCreate=false;
   local expectedInfo=GameInfo.Units[expectedType];
   if migrated~=nil then MarkSequence(migrated,level,plot:GetIndex(),path,baseline,periodBonus,expectedInfo~=nil and expectedInfo.UnitType or nil); Log("sequence migrated plot="..plot:GetIndex().." level="..level.." unitType="..tostring(expectedInfo~=nil and expectedInfo.UnitType or expectedType).." centerMonster="..tostring(IsRescueMode())); end
   return;
  end
  if IsRescueMode() and u:GetProperty(RESCUE_MONSTER_UNIT_TYPE)==nil then local info=GameInfo.Units[u:GetType()]; if info~=nil then u:SetProperty(RESCUE_MONSTER_UNIT_TYPE,info.UnitType); u:SetProperty("LOTM_RESCUE_CENTER_MONSTER",1); end end
  ApplySequenceName(u,u:GetProperty(PATH) or plot:GetProperty(PATH) or "PP",level); if IsRescueMode() then Game.SetProperty(SequenceEngineKey(u:GetOwner(),u:GetID()),level); EnsureSequenceSerial(u); end EnsureSequenceStrength(u,nil); UnitManager.FinishMoves(u); return;
 end end
 if (plot:GetProperty(SEQUENCE_CREATED) or 0)==1 then return; end
 -- Replace only the original center guard; scouts and units outside the center remain original.
 local centerUnits=Units.GetUnitsInPlot(plot) or {};
 if LOTM_MP_TurnSync.IsNetworkGame() then
  table.sort(centerUnits,function(a,b)
   if a:GetOwner()~=b:GetOwner() then return a:GetOwner()<b:GetOwner(); end
   return a:GetID()<b:GetID();
  end);
 end
 for _,u in ipairs(centerUnits) do if u:GetOwner()==barb then UnitManager.Kill(u); break; end end
 local resolved=LOTM_WORLD_Barbarians.ResolveMeleeBaseline(barb); local baseline=resolved~=nil and resolved.Combat or 20;
 local level=plot:GetProperty(LEVEL) or 2; local periodBonus=CurrentPeriodBonus();
 local sequenceType=SequenceUnitIndex(level,nil); m_internalCreate=true; local u=UnitManager.InitUnit(barb,sequenceType,plot:GetX(),plot:GetY()); m_internalCreate=false;
 if u~=nil then local sequenceInfo=GameInfo.Units[sequenceType]; MarkSequence(u,level,plot:GetIndex(),plot:GetProperty(PATH) or "PP",baseline,periodBonus,resolved~=nil and resolved.UnitType or (sequenceInfo~=nil and sequenceInfo.UnitType or nil)); plot:SetProperty(SEQUENCE_CREATED,1); Log("sequence spawned plot="..plot:GetIndex().." path="..tostring(plot:GetProperty(PATH)).." B="..baseline.." periodBonus="..periodBonus.." unitType="..tostring(sequenceInfo~=nil and sequenceInfo.UnitType or sequenceType).." centerMonster="..tostring(IsRescueMode())); end
end
local function RollPath(level,plotIndex)
 local available={}; for _,path in ipairs(PATHS) do if LOTM_PP_HasAvailableArtifact==nil or LOTM_PP_HasAvailableArtifact(path,level) then table.insert(available,path); end end
 if #available==0 then return nil; end return available[StableClassificationRoll(plotIndex,"PATH:"..tostring(level),#available)+1];
end
local function ResolveCampTribeIndex(plot)
 if plot==nil or Game.GetBarbarianManager==nil then return nil; end
 local manager=Game.GetBarbarianManager();
 if manager==nil or manager.GetTribeIndexAtLocation==nil then return nil; end
 local ok,value=pcall(manager.GetTribeIndexAtLocation,manager,plot:GetX(),plot:GetY());
 value=ok and tonumber(value) or nil;
 return value~=nil and value>=0 and value or nil;
end
local function CampNeedsNewGeneration(plot,forced)
 if forced==true then return true; end
 local stored=NumberValue(plot~=nil and plot:GetProperty(CAMP_TRIBE_INDEX) or nil);
 local current=ResolveCampTribeIndex(plot);
 return stored~=nil and current~=nil and stored~=current;
end
local function ResetCampGeneration(plot)
 local plotIndex=plot:GetIndex();
 for _,unit in ipairs(Units.GetUnitsInPlot(plot) or {}) do
  if unit:GetOwner()==BarbarianID() and (unit:GetProperty("LOTM_PP_WORKSHOP_SEQUENCE") or 0)==1 then
   pcall(UnitManager.Kill,unit);
  end
 end
 UnregisterWorkshopPlot(plotIndex);
 for _,key in ipairs({CLASSIFIED,IS_WORKSHOP,LEVEL,PATH,SETTLED,SPAWNS,SEQUENCE_CREATED,CLEARER,CLEARER_UNIT,
   CLASSIFICATION_VERSION_PROPERTY,CLASSIFIED_TURN,"LOTM_RESCUE_PHASE5_LEVEL_PERIOD",
   "LOTM_RESCUE_PHASE5_LEVEL_CHANCES","LOTM_RESCUE_PHASE5_CLASSIFICATION_CHANCE",
   "LOTM_PP_WORKSHOP_EXTRA_SPAWN_COUNT","LOTM_WORLD_WORKSHOP_MONSTER_SERIAL",
   "LOTM_WORLD_WORKSHOP_MONSTER_COOLDOWN_UNTIL",MP_PENDING,MP_PENDING_OWNER,
   MP_PENDING_CLEARER,MP_PENDING_CLEARER_UNIT,MP_PENDING_LEVEL,MP_PENDING_PATH,
   MP_PENDING_CLASSIFIED_TURN,MP_PENDING_CAMP_EPOCH,MP_PENDING_QUEUED_TURN,MP_CHURCH_SETTLED,
   MP_PHASE4_SETTLED,MP_REWARD_SETTLED,CAMP_REBUILD_PENDING,BIRTH_RECONCILE_VERSION_PROPERTY}) do plot:SetProperty(key,nil); end
 RemoveNetworkPendingSettlementIndex(plotIndex);
 local counterKey=CAMP_EPOCH_COUNTER_PREFIX..tostring(plotIndex);
 local epoch=math.max(NumberValue(Game.GetProperty(counterKey)) or 0,
  NumberValue(plot:GetProperty(CAMP_EPOCH)) or 0)+1;
 Game.SetProperty(counterKey,epoch); plot:SetProperty(CAMP_EPOCH,epoch);
 plot:SetProperty(CAMP_TRIBE_INDEX,nil);
 local tribe=ResolveCampTribeIndex(plot); if tribe~=nil then plot:SetProperty(CAMP_TRIBE_INDEX,tribe); end
 Log("camp generation reset plot="..plotIndex.." epoch="..epoch.." tribe="..tostring(tribe));
end
local function EnsureCampGeneration(plot,forced)
 if CampNeedsNewGeneration(plot,forced) then
  if (plot:GetProperty(MP_PENDING) or 0)==1 then
   if (plot:GetProperty(CAMP_REBUILD_PENDING) or 0)~=1 then plot:SetProperty(CAMP_REBUILD_PENDING,1); end
   Trace("camp generation deferred for old settlement plot="..plot:GetIndex());
   return false;
  end
  ResetCampGeneration(plot); return true;
 end
 if NumberValue(plot:GetProperty(CAMP_EPOCH))==nil then
  local counterKey=CAMP_EPOCH_COUNTER_PREFIX..tostring(plot:GetIndex());
  local epoch=(NumberValue(Game.GetProperty(counterKey)) or 0)+1;
  Game.SetProperty(counterKey,epoch); plot:SetProperty(CAMP_EPOCH,epoch);
 end
 local tribe=ResolveCampTribeIndex(plot);
 if tribe~=nil and NumberValue(plot:GetProperty(CAMP_TRIBE_INDEX))~=tribe then plot:SetProperty(CAMP_TRIBE_INDEX,tribe); end
 return true;
end
local function Classify(plot)
 if plot==nil or plot:GetImprovementType()~=CAMP then return false; end
 if not EnsureCampGeneration(plot,(plot:GetProperty(CAMP_REBUILD_PENDING) or 0)==1) then return false; end
 if (plot:GetProperty(CLASSIFIED) or 0)~=1 then
  local chance=IsRescueMode() and LOTM_RESCUE_Phase5~=nil and LOTM_RESCUE_Phase5.WorkshopChance~=nil and LOTM_RESCUE_Phase5.WorkshopChance() or 50;
  local plotIndex=plot:GetIndex(); local classificationRoll=StableClassificationRoll(plotIndex,"CLASSIFICATION",100);
  local workshop=classificationRoll<chance;
  plot:SetProperty(CLASSIFIED,1); plot:SetProperty(IS_WORKSHOP,workshop and 1 or 0);
  plot:SetProperty(CLASSIFICATION_VERSION_PROPERTY,CLASSIFICATION_VERSION);
  if IsRescueMode() then plot:SetProperty(CLASSIFIED_TURN,Game.GetCurrentGameTurn()); end
  if workshop then local level=RollLevel(plotIndex); local path=RollPath(level,plotIndex); if path==nil then workshop=false; plot:SetProperty(IS_WORKSHOP,0); else plot:SetProperty(LEVEL,level); plot:SetProperty(PATH,path); end plot:SetProperty(SETTLED,0); plot:SetProperty(SPAWNS,0);
   if IsRescueMode() and LOTM_RESCUE_Phase5~=nil and LOTM_RESCUE_Phase5.WorkshopLevelChances~=nil then local low,mid,high=LOTM_RESCUE_Phase5.WorkshopLevelChances(); plot:SetProperty("LOTM_RESCUE_PHASE5_LEVEL_PERIOD",LOTM_RESCUE_Phase5.CurrentPeriod()); plot:SetProperty("LOTM_RESCUE_PHASE5_LEVEL_CHANCES",low..","..mid..","..high); end
  end
  plot:SetProperty("LOTM_RESCUE_PHASE5_CLASSIFICATION_CHANCE",chance);
	  -- Civ VI's C binding may return zero Lua values for a missing Property.
	  -- Store it first so tostring always receives exactly one argument.
	  local loggedLevel=plot:GetProperty(LEVEL); local loggedChances=plot:GetProperty("LOTM_RESCUE_PHASE5_LEVEL_CHANCES");
	  Log("classified plot="..plot:GetIndex().." workshop="..tostring(workshop).." chance="..chance.." roll="..classificationRoll.." deterministicVersion="..CLASSIFICATION_VERSION.." level="..tostring(loggedLevel or "NONE").." levelChances="..tostring(loggedChances or "NONE"));
 end
 if (plot:GetProperty(IS_WORKSHOP) or 0)==1 and plot:GetProperty(PATH)==nil then plot:SetProperty(PATH,RollPath(plot:GetProperty(LEVEL) or 2,plot:GetIndex()) or "PP"); end
 if (plot:GetProperty(IS_WORKSHOP) or 0)==1 then RegisterWorkshopPlot(plot); end
 EnsureSequence(plot);
 if (plot:GetProperty(IS_WORKSHOP) or 0)==1 and not IsRescueMode()
  and not LOTM_MP_TurnSync.IsNetworkGame()
  and LOTM_PP_Workshops.ReconcileSinglePlayerWorkshopBirthUnits~=nil
  and (NumberValue(plot:GetProperty(BIRTH_RECONCILE_VERSION_PROPERTY)) or 0)<BIRTH_RECONCILE_VERSION then
  local reconcileOK,reconcileError=pcall(LOTM_PP_Workshops.ReconcileSinglePlayerWorkshopBirthUnits,plot);
  if reconcileOK then
   plot:SetProperty(BIRTH_RECONCILE_VERSION_PROPERTY,BIRTH_RECONCILE_VERSION);
  else
   Log("single-player birth reconciliation failed plot="..plot:GetIndex()
    .." error="..tostring(reconcileError));
  end
 end
 return true;
end
local function QueueNetworkImprovementAdded(x,y,improvementType,ownerID)
 if improvementType~=CAMP then return; end
 local plot=Map.GetPlot(x,y); if plot==nil then return; end
 local plotIndex=plot:GetIndex(); local queuedTurn=Game.GetCurrentGameTurn();
 local existing=m_networkImprovementAdditions[plotIndex];
 if existing==nil then
  m_networkImprovementPlots[#m_networkImprovementPlots+1]=plotIndex;
  m_networkImprovementAdditions[plotIndex]={QueuedTurn=queuedTurn,PlotIndex=plotIndex,
    Rebuilt=m_networkImprovementRemovedPlots[plotIndex]==true};
 elseif queuedTurn<existing.QueuedTurn then
  existing.QueuedTurn=queuedTurn;
  existing.Rebuilt=existing.Rebuilt==true or m_networkImprovementRemovedPlots[plotIndex]==true;
 end
end
local function ClassifySinglePlayerImprovementAdded(x,y,improvementType,ownerID)
 if improvementType==CAMP then Classify(Map.GetPlot(x,y)); end
end
local function ProcessNetworkImprovementAdditions(playerID)
 if not LOTM_MP_TurnSync.IsNetworkGame() then return; end
 if not LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID) then return; end
 local currentTurn=Game.GetCurrentGameTurn();
 if m_networkImprovementBoundaryTurn==currentTurn then return; end
 m_networkImprovementBoundaryTurn=currentTurn;
 table.sort(m_networkImprovementPlots);
 local remaining={}; local classified=0;
 for _,plotIndex in ipairs(m_networkImprovementPlots) do
  local entry=m_networkImprovementAdditions[plotIndex];
  -- A callback batch must cross at least one complete world-turn boundary.
  if entry~=nil and entry.QueuedTurn<currentTurn then
   local plot=Map.GetPlotByIndex(plotIndex);
    local rebuildRequested=entry.Rebuilt==true or m_networkImprovementRemovedPlots[plotIndex]==true
     or (plot~=nil and (plot:GetProperty(CAMP_REBUILD_PENDING) or 0)==1);
    local rebuilt=plot~=nil and plot:GetImprovementType()==CAMP and CampNeedsNewGeneration(plot,rebuildRequested);
    if rebuilt and (plot:GetProperty(MP_PENDING) or 0)==1 then
    -- Preserve the old generation's plot-backed settlement until its next-turn
    -- checkpoint completes; only then may the new camp reuse these fields.
     if (plot:GetProperty(CAMP_REBUILD_PENDING) or 0)~=1 then plot:SetProperty(CAMP_REBUILD_PENDING,1); end
     remaining[#remaining+1]=plotIndex;
    else
     if plot~=nil and plot:GetImprovementType()==CAMP then
      if rebuildRequested then plot:SetProperty(CAMP_REBUILD_PENDING,1); end
      Classify(plot);
    end
    m_networkImprovementAdditions[plotIndex]=nil;
    classified=classified+1;
   end
  elseif entry~=nil then
   remaining[#remaining+1]=plotIndex;
  end
 end
 m_networkImprovementPlots=remaining;
 if classified>0 then
  Trace("network improvement batch turn="..currentTurn.." classified="..classified);
 end
end
local function NearestWorkshop(x,y)
 for radius=0,3 do for dx=-radius,radius do for dy=-radius,radius do local p=Map.GetPlotXYWithRangeCheck(x,y,dx,dy,radius); if p~=nil and p:GetImprovementType()==CAMP and (p:GetProperty(IS_WORKSHOP) or 0)==1 then return p; end end end end
 return nil;
end
local function IndexedNearestWorkshop(x,y)
 local source=Map.GetPlot(x,y); if source==nil then return nil,"NO_SOURCE",0; end
 local candidates=m_workshopCoverage[source:GetIndex()]; if candidates==nil or #candidates==0 then return nil,"NO_CANDIDATE",0; end
 if #candidates==1 then
  local camp=Map.GetPlotByIndex(candidates[1]);
  if IsWorkshopPlot(camp) then return camp,"UNIQUE",1; end
 end
 -- Overlapping coverage retains the exact legacy radius/dx/dy selection order.
 local legacyStarted=LOTM_UnitAddedPerf.BeginSection();
 local camp=NearestWorkshop(x,y);
 LOTM_UnitAddedPerf.EndSection("Workshops.Lookup.Legacy",legacyStarted,#candidates);
 return camp,#candidates==1 and "STALE_LEGACY" or "OVERLAP_LEGACY",#candidates;
end
local function InitializeWorkshopRegistry()
 local version=NumberValue(Game.GetProperty(WORKSHOP_REGISTRY_VERSION_KEY)); local campCount=0;
 if version~=WORKSHOP_REGISTRY_VERSION then
  ResetWorkshopRegistry();
  for i=0,Map.GetPlotCount()-1 do
   local plot=Map.GetPlotByIndex(i);
   if plot:GetImprovementType()==CAMP then campCount=campCount+1; Classify(plot); end
  end
  BuildWorkshopCoverage(); m_registryReady=true; SaveWorkshopRegistry();
  Log("registry initialized version="..WORKSHOP_REGISTRY_VERSION.." mode=MIGRATION_FULL_SCAN camps="..campCount.." workshops="..#m_workshopPlots);
  return campCount;
 end
 local rejected=LoadWorkshopRegistry();
 for _,plotIndex in ipairs(m_workshopPlots) do local plot=Map.GetPlotByIndex(plotIndex); if plot~=nil then Classify(plot); campCount=campCount+1; end end
 Log("registry initialized version="..WORKSHOP_REGISTRY_VERSION.." mode=PERSISTED_INCREMENTAL workshops="..campCount.." rejected="..rejected);
 return campCount;
end
local function CreateExtra(source,camp)
 local barb=BarbarianID(); if barb<0 then return; end
 for dir=0,5 do local p=Map.GetAdjacentPlot(camp:GetX(),camp:GetY(),dir); if p~=nil and not p:IsWater() and p:GetUnitCount()==0 then
  m_internalCreate=true; local u=UnitManager.InitUnit(barb,source:GetType(),p:GetX(),p:GetY()); m_internalCreate=false;
  if u~=nil then u:SetProperty("LOTM_PP_WORKSHOP_EXTRA",1); u:SetProperty("LOTM_PP_WORKSHOP_SOURCE",camp:GetIndex());
   MarkNetworkUnitAdditionFiltered(u);
   if (camp:GetProperty(LEVEL) or 2)==0 then local a=u:GetAbility(); if a~=nil then a:ChangeAbilityCount("ABILITY_LOTM_PP_WORKSHOP_LEVEL0_STRENGTH",1); end end
   camp:SetProperty("LOTM_PP_WORKSHOP_EXTRA_SPAWN_COUNT",(camp:GetProperty("LOTM_PP_WORKSHOP_EXTRA_SPAWN_COUNT") or 0)+1);
   Game.SetProperty("LOTM_PP_WORKSHOP_EXTRA_SPAWN_TOTAL",LOTM_WORLD_State.NumberGameProperty("LOTM_PP_WORKSHOP_EXTRA_SPAWN_TOTAL",0)+1);
   Trace("extra unit plot="..camp:GetIndex().." type="..source:GetType().." extraCount="..tostring(camp:GetProperty("LOTM_PP_WORKSHOP_EXTRA_SPAWN_COUNT"))); return;
  end
 end end
end
local function NetworkPendingUnitAdditions()
 local result={}; local seen={};
 for token in string.gmatch(tostring(Game.GetProperty(MP_PENDING_UNIT_ADDITIONS) or ""),"[^;]+") do
  local fields={}; for value in string.gmatch(token,"[^:]+") do fields[#fields+1]=value; end
  local turn=tonumber(fields[1]); local camp=tonumber(fields[2]); local owner=tonumber(fields[3]);
  local unitID=tonumber(fields[4]); local unitType=tonumber(fields[5]);
  if turn~=nil and camp~=nil and owner~=nil and unitID~=nil and unitType~=nil then
   -- Five fields are the resource-291 legacy format. They remain consumable,
   -- but without a generation token they can never mutate a possibly reused
   -- live unit. New entries append Removed and Generation fields.
   local removed=#fields>=6 and tonumber(fields[6])==1 or false;
    local generation=#fields>=7 and tostring(fields[7]) or "LEGACY";
    local campEpoch=#fields>=8 and tonumber(fields[8]) or nil;
    local normalizedCampEpoch=campEpoch~=nil and campEpoch or "LEGACY";
    local key=table.concat({turn,camp,owner,unitID,unitType,removed and 1 or 0,generation,normalizedCampEpoch},":");
   if not seen[key] then
    seen[key]=true;
    -- `Turn` was the name used by the first network queue format.  Expose
    -- the same value as QueuedTurn internally so processing can explicitly
    -- enforce a full-turn delay while still reading old saves.
    result[#result+1]={QueuedTurn=turn,Turn=turn,Camp=camp,Owner=owner,Unit=unitID,
     Type=unitType,Removed=removed,Generation=generation,CampEpoch=normalizedCampEpoch};
   end
  end
 end
 table.sort(result,function(a,b)
  if a.QueuedTurn~=b.QueuedTurn then return a.QueuedTurn<b.QueuedTurn; end
  if a.Camp~=b.Camp then return a.Camp<b.Camp; end
  if a.Owner~=b.Owner then return a.Owner<b.Owner; end
  if a.Unit~=b.Unit then return a.Unit<b.Unit; end
  if a.Type~=b.Type then return a.Type<b.Type; end
  if a.Removed~=b.Removed then return a.Removed==true; end
   if tostring(a.Generation or "")~=tostring(b.Generation or "") then return tostring(a.Generation or "")<tostring(b.Generation or ""); end
   return tostring(a.CampEpoch or "LEGACY")<tostring(b.CampEpoch or "LEGACY");
 end);
 return result;
end
local function SaveNetworkPendingUnitAdditions(entries)
 local values={};
 for _,entry in ipairs(entries) do
  values[#values+1]=table.concat({entry.QueuedTurn or entry.Turn,entry.Camp,entry.Owner,
    entry.Unit,entry.Type,entry.Removed==true and 1 or 0,entry.Generation or "LEGACY",
    entry.CampEpoch or "LEGACY"},":");
 end
 local serialized=table.concat(values,";");
 if tostring(Game.GetProperty(MP_PENDING_UNIT_ADDITIONS) or "")~=serialized then
  Game.SetProperty(MP_PENDING_UNIT_ADDITIONS,serialized);
 end
end
local function NetworkUnitEntryToken(entry)
  return table.concat({entry.QueuedTurn or entry.Turn,entry.Camp,entry.Owner,entry.Unit,
   entry.Type,entry.Removed==true and 1 or 0,entry.Generation or "LEGACY",
   entry.CampEpoch or "LEGACY"},":");
end
local function GenerationNetworkUnitEntryToken(entry)
 return table.concat({entry.QueuedTurn or entry.Turn,entry.Camp,entry.Owner,entry.Unit,
  entry.Type,entry.Removed==true and 1 or 0,entry.Generation or "LEGACY"},":");
end
local function LegacyNetworkUnitEntryToken(entry)
 return table.concat({entry.QueuedTurn or entry.Turn,entry.Camp,entry.Owner,entry.Unit,entry.Type},":");
end
local function NetworkUnitStageKey(entry,suffix)
 return MP_UNIT_STAGE_PREFIX..NetworkUnitEntryToken(entry)..":"..tostring(suffix);
end
local function ClearNetworkUnitStages(entry)
 for _,suffix in ipairs({"STAGE","COUNT_TARGET","GLOBAL_TARGET","EXTRA_COUNT_TARGET","EXTRA_GLOBAL_TARGET"}) do
  Game.SetProperty(NetworkUnitStageKey(entry,suffix),nil);
 end
end
local function NextSynchronizedUnitGeneration(owner,unitID)
 local key=MP_UNIT_EPOCH_PREFIX..tostring(owner)..":"..tostring(unitID);
 local epoch=(NumberValue(Game.GetProperty(key)) or 0)+1;
 Game.SetProperty(key,epoch);
 return table.concat({"S",owner,unitID,epoch},".");
end
local function RecoverCommittedNetworkUnitEntry(entries)
 local committed=tostring(Game.GetProperty(MP_UNIT_COMMITTED_TOKEN) or "");
 if committed=="" then return entries; end
 for index,entry in ipairs(entries) do
  if NetworkUnitEntryToken(entry)==committed or GenerationNetworkUnitEntryToken(entry)==committed
   or LegacyNetworkUnitEntryToken(entry)==committed then
   table.remove(entries,index);
   SaveNetworkPendingUnitAdditions(entries);
   Trace("network unit recovered committed token="..committed);
   break;
  end
 end
 -- If the queue write succeeded but clearing this marker did not, the token is
 -- absent and can also be discarded safely.  Only one item is ever in flight.
 Game.SetProperty(MP_UNIT_COMMITTED_TOKEN,nil);
 return entries;
end
local function QueueNetworkWorkshopUnitAddition(unit,camp,queuedTurnOverride,ownerOverride,unitIDOverride,unitTypeOverride,generationOverride,removedOverride,campEpochOverride)
 local entries=NetworkPendingUnitAdditions();
 local queuedTurn=tonumber(queuedTurnOverride) or Game.GetCurrentGameTurn();
 local owner=unit~=nil and unit:GetOwner() or tonumber(ownerOverride);
 local unitID=unit~=nil and unit:GetID() or tonumber(unitIDOverride);
 local unitType=unit~=nil and unit:GetType() or tonumber(unitTypeOverride);
 if owner==nil or unitID==nil or unitType==nil then return nil,false; end
 local campEpoch=tonumber(campEpochOverride); if campEpoch==nil then campEpoch=NumberValue(camp:GetProperty(CAMP_EPOCH)) or 0; end
 -- A local callback batch is normalized before reaching this function, but a
 -- reconnect can still replay the same captured fact while its durable queue
 -- entry already exists. Detect that identity before allocating a generation:
 -- generation epochs are authoritative state and may advance only for a fact
 -- that will actually be appended to the persistent queue.
 for _,entry in ipairs(entries) do
  if entry.QueuedTurn==queuedTurn and entry.Camp==camp:GetIndex() and entry.Owner==owner
   and entry.Unit==unitID and entry.Type==unitType and entry.Removed==(removedOverride==true)
   and tostring(entry.CampEpoch or "LEGACY")==tostring(campEpoch) then
   return tostring(entry.Generation or ""),false;
  end
 end
 local generation=tostring(generationOverride or "");
 if generation=="" then generation=NextSynchronizedUnitGeneration(owner,unitID); end
 local candidate={QueuedTurn=queuedTurn,Turn=queuedTurn,Camp=camp:GetIndex(),Owner=owner,
  Unit=unitID,Type=unitType,Generation=generation,Removed=removedOverride==true,CampEpoch=campEpoch};
 entries[#entries+1]=candidate;
 table.sort(entries,function(a,b)
  if a.QueuedTurn~=b.QueuedTurn then return a.QueuedTurn<b.QueuedTurn; end
  if a.Camp~=b.Camp then return a.Camp<b.Camp; end
  if a.Owner~=b.Owner then return a.Owner<b.Owner; end
  if a.Unit~=b.Unit then return a.Unit<b.Unit; end
  if a.Type~=b.Type then return a.Type<b.Type; end
  if a.Removed~=b.Removed then return a.Removed==true; end
  if tostring(a.Generation)~=tostring(b.Generation) then return tostring(a.Generation)<tostring(b.Generation); end
  return tostring(a.CampEpoch or "LEGACY")<tostring(b.CampEpoch or "LEGACY");
 end);
 SaveNetworkPendingUnitAdditions(entries);
 Trace("network unit queued turn="..candidate.QueuedTurn.." camp="..candidate.Camp
   .." owner="..candidate.Owner.." unit="..candidate.Unit.." type="..candidate.Type
   .." generation="..candidate.Generation.." campEpoch="..tostring(candidate.CampEpoch)
   .." removed="..tostring(candidate.Removed));
 return generation,true;
end

local function CreateNetworkExtra(sourceType,camp,entry)
 local barb=BarbarianID(); if barb<0 then return; end
 local eventToken=NetworkUnitEntryToken(entry); local existing=nil; local spawnPlot=nil;
 for dir=0,5 do
  local plot=Map.GetAdjacentPlot(camp:GetX(),camp:GetY(),dir);
  if plot~=nil then
   for _,candidate in ipairs(Units.GetUnitsInPlot(plot) or {}) do
    if candidate:GetProperty("LOTM_PP_WORKSHOP_EXTRA_EVENT_TOKEN")==eventToken then existing=candidate; break; end
   end
   if existing~=nil then break; end
   if spawnPlot==nil and not plot:IsWater() and plot:GetUnitCount()==0 then spawnPlot=plot; end
  end
 end
 local extraTarget=NumberValue(Game.GetProperty(NetworkUnitStageKey(entry,"EXTRA_COUNT_TARGET")));
 local globalTarget=NumberValue(Game.GetProperty(NetworkUnitStageKey(entry,"EXTRA_GLOBAL_TARGET")));
 if existing==nil and spawnPlot~=nil then
  if extraTarget==nil then
   extraTarget=(NumberValue(camp:GetProperty("LOTM_PP_WORKSHOP_EXTRA_SPAWN_COUNT")) or 0)+1;
   Game.SetProperty(NetworkUnitStageKey(entry,"EXTRA_COUNT_TARGET"),extraTarget);
  end
  if globalTarget==nil then
   globalTarget=LOTM_WORLD_State.NumberGameProperty("LOTM_PP_WORKSHOP_EXTRA_SPAWN_TOTAL",0)+1;
   Game.SetProperty(NetworkUnitStageKey(entry,"EXTRA_GLOBAL_TARGET"),globalTarget);
  end
  m_internalCreate=true;
  local initOK,unit=pcall(UnitManager.InitUnit,barb,sourceType,spawnPlot:GetX(),spawnPlot:GetY());
  m_internalCreate=false;
  if not initOK then error(unit); end
  if unit~=nil then
   unit:SetProperty("LOTM_PP_WORKSHOP_EXTRA_EVENT_TOKEN",eventToken);
   unit:SetProperty("LOTM_PP_WORKSHOP_EXTRA",1); unit:SetProperty("LOTM_PP_WORKSHOP_SOURCE",camp:GetIndex());
   MarkNetworkUnitAdditionFiltered(unit); existing=unit;
  end
 end
 if existing~=nil then
  if (camp:GetProperty(LEVEL) or 2)==0 then
   LOTM_Effects.SetAbilityCount(existing:GetAbility(),"ABILITY_LOTM_PP_WORKSHOP_LEVEL0_STRENGTH",1);
  end
  if extraTarget~=nil and (NumberValue(camp:GetProperty("LOTM_PP_WORKSHOP_EXTRA_SPAWN_COUNT")) or 0)<extraTarget then camp:SetProperty("LOTM_PP_WORKSHOP_EXTRA_SPAWN_COUNT",extraTarget); end
  if globalTarget~=nil and LOTM_WORLD_State.NumberGameProperty("LOTM_PP_WORKSHOP_EXTRA_SPAWN_TOTAL",0)<globalTarget then Game.SetProperty("LOTM_PP_WORKSHOP_EXTRA_SPAWN_TOTAL",globalTarget); end
  Trace("network extra unit plot="..camp:GetIndex().." type="..sourceType.." extraCount="..tostring(camp:GetProperty("LOTM_PP_WORKSHOP_EXTRA_SPAWN_COUNT")));
 end
end
local function NetworkQueueBoundary(playerID,lastBoundaryProperty)
 if not LOTM_MP_TurnSync.IsNetworkGame() then return false,nil; end
 if not LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID) then return false,nil; end
 local currentTurn=Game.GetCurrentGameTurn();
 if NumberValue(Game.GetProperty(lastBoundaryProperty))==currentTurn then return false,currentTurn; end
 -- Claim the stable anchor before touching either queue.  A repeated
 -- PlayerTurnStarted/reconnect callback in this world turn must not replay a
 -- partially completed batch; an unsuccessful item remains for the next
 -- boundary.
 Game.SetProperty(lastBoundaryProperty,currentTurn);
 return true,currentTurn;
end

local function ProcessNetworkWorkshopUnitAddition(entry,camp)
 if camp==nil then return true,"WORKSHOP_GONE"; end
 if not IsWorkshopPlot(camp) then return true,"WORKSHOP_GONE"; end
 local currentCampEpoch=NumberValue(camp:GetProperty(CAMP_EPOCH));
 local capturedCampEpoch=tonumber(entry.CampEpoch);
 if (camp:GetProperty(CAMP_REBUILD_PENDING) or 0)==1
  or (capturedCampEpoch~=nil and currentCampEpoch~=capturedCampEpoch) then
  Trace("network unit camp generation detached plot="..entry.Camp
   .." captured="..tostring(entry.CampEpoch).." live="..tostring(currentCampEpoch));
  return true,"STALE_CAMP_GENERATION";
 end
 local stage=NumberValue(Game.GetProperty(NetworkUnitStageKey(entry,"STAGE"))) or 0;
 local unit=UnitManager.GetUnit(entry.Owner,entry.Unit);
 local unitGeneration=unit~=nil and unit:GetProperty(MP_UNIT_GENERATION_PROPERTY) or nil;
 local generationMatches=entry.Removed~=true and unit~=nil and unit:GetType()==entry.Type
  and entry.Generation~="LEGACY" and tostring(unitGeneration or "")==tostring(entry.Generation or "");
 if stage<1 and generationMatches then
  unit:SetProperty("LOTM_PP_WORKSHOP_SOURCE",entry.Camp);
  if (camp:GetProperty(LEVEL) or 2)==0 then
   local ability=unit:GetAbility();
   LOTM_Effects.SetAbilityCount(ability,"ABILITY_LOTM_PP_WORKSHOP_LEVEL0_STRENGTH",1);
  end
 elseif stage<1 then
  Trace("network unit generation detached owner="..entry.Owner.." unit="..entry.Unit
   .." captured="..tostring(entry.Generation).." live="..tostring(unitGeneration)
   .." removed="..tostring(entry.Removed));
 end
 if stage<1 then Game.SetProperty(NetworkUnitStageKey(entry,"STAGE"),1); stage=1; end
 local count=NumberValue(Game.GetProperty(NetworkUnitStageKey(entry,"COUNT_TARGET")));
 local globalCount=NumberValue(Game.GetProperty(NetworkUnitStageKey(entry,"GLOBAL_TARGET")));
 if count==nil then
  count=(NumberValue(camp:GetProperty(SPAWNS)) or 0)+1;
  Game.SetProperty(NetworkUnitStageKey(entry,"COUNT_TARGET"),count);
 end
 if globalCount==nil then
  globalCount=LOTM_WORLD_State.NumberGameProperty("LOTM_PP_WORKSHOP_NORMAL_SPAWN_TOTAL",0)+1;
  Game.SetProperty(NetworkUnitStageKey(entry,"GLOBAL_TARGET"),globalCount);
 end
 if stage<2 then
  if (NumberValue(camp:GetProperty(SPAWNS)) or 0)<count then camp:SetProperty(SPAWNS,count); end
  if LOTM_WORLD_State.NumberGameProperty("LOTM_PP_WORKSHOP_NORMAL_SPAWN_TOTAL",0)<globalCount then Game.SetProperty("LOTM_PP_WORKSHOP_NORMAL_SPAWN_TOTAL",globalCount); end
  Game.SetProperty(NetworkUnitStageKey(entry,"STAGE"),2); stage=2;
 end
 Trace("network normal spawn turn="..tostring(entry.QueuedTurn or entry.Turn).." plot="..entry.Camp.." type="..entry.Type
  .." normalCount="..count.." globalNormal="..tostring(Game.GetProperty("LOTM_PP_WORKSHOP_NORMAL_SPAWN_TOTAL")));
 if stage<3 then
  if (camp:GetProperty(LEVEL) or 2)<=1 and count%2==0 then CreateNetworkExtra(entry.Type,camp,entry); end
  Game.SetProperty(NetworkUnitStageKey(entry,"STAGE"),3); stage=3;
 end
 if stage<4 then
  local eventToken=NetworkUnitEntryToken(entry);
  if LOTM_WORLD_Monsters~=nil and LOTM_WORLD_Monsters.TrySpawnFromWorkshopNetwork~=nil then
   LOTM_WORLD_Monsters.TrySpawnFromWorkshopNetwork(camp,entry.Owner,eventToken);
  elseif generationMatches and LOTM_WORLD_Monsters~=nil and LOTM_WORLD_Monsters.TrySpawnFromWorkshop~=nil then
   LOTM_WORLD_Monsters.TrySpawnFromWorkshop(camp,unit);
  end
  Game.SetProperty(NetworkUnitStageKey(entry,"STAGE"),4);
 end
 return true,"SETTLED";
end

local function ProcessNetworkWorkshopUnitAdditions(playerID)
 local claimed,currentTurn=NetworkQueueBoundary(playerID,MP_UNIT_QUEUE_LAST_BOUNDARY);
 if not claimed then return; end
 local entries=RecoverCommittedNetworkUnitEntry(NetworkPendingUnitAdditions());
 local index=1;
 while index<=#entries do
  local entry=entries[index];
  -- Entries created after this anchor are deliberately left for the next
  -- turn, ensuring all peers observe one complete callback batch.
  if (entry.QueuedTurn or entry.Turn or currentTurn)>=currentTurn then
   index=index+1;
  else
   local ok,result=pcall(ProcessNetworkWorkshopUnitAddition,entry,Map.GetPlotByIndex(entry.Camp));
   if not ok then Log("network unit settlement error turn="..tostring(entry.QueuedTurn or entry.Turn)
    .." camp="..entry.Camp.." owner="..entry.Owner.." unit="..entry.Unit.." error="..tostring(result)); end
   if not ok then
    -- Keep this and every later sorted entry for a future synchronized
    -- boundary.  Earlier entries were already removed and checkpointed.  Let
    -- the ordered dispatcher latch the unexpected exception fail-closed.
    error(result);
   end
   -- Inner effects have replay-safe stages and monotonic targets. This final
   -- commit marker only bridges completed settlement and queue removal.
   Game.SetProperty(MP_UNIT_COMMITTED_TOKEN,NetworkUnitEntryToken(entry));
   table.remove(entries,index);
   SaveNetworkPendingUnitAdditions(entries);
   ClearNetworkUnitStages(entry);
   Game.SetProperty(MP_UNIT_COMMITTED_TOKEN,nil);
   Trace("network unit checkpoint turn="..tostring(entry.QueuedTurn or entry.Turn)
    .." camp="..entry.Camp.." owner="..entry.Owner.." unit="..entry.Unit.." result="..tostring(result));
  end
 end
end
local function QueueLocalNetworkUnitAdded(playerID,unitID,x,y)
 local normalizedPlayerID=tonumber(playerID); local normalizedUnitID=tonumber(unitID);
 if normalizedPlayerID==nil or normalizedUnitID==nil then return; end
 local queuedTurn=Game.GetCurrentGameTurn();
 local key=LocalNetworkUnitBatchKey(normalizedPlayerID,normalizedUnitID,queuedTurn);
 local rescueCleanup=IsRescueMode();
 -- UnitRemovedFromMap and UnitAddedToMap are local publications and their
 -- relative order is not an authority signal. Once this owner:unitID batch
 -- has any removal fact, every same-turn addition loses, including an Add
 -- delivered after the Remove for a newly reused engine ID.
 if not rescueCleanup and m_networkUnitRemovalBatches[key]~=nil then return; end
 local unit=UnitManager.GetUnit(normalizedPlayerID,normalizedUnitID);
 -- A load-time UnitAdded replay for an already captured/settled generation is
 -- not a new spawn fact. Both markers are written only at synchronized stages.
 if not rescueCleanup and unit~=nil and (unit:GetProperty(MP_UNIT_GENERATION_PROPERTY)~=nil
  or unit:GetProperty("LOTM_PP_WORKSHOP_SOURCE")~=nil) then return; end
 local filtered=unit~=nil and ((unit:GetProperty("LOTM_PP_WORKSHOP_SEQUENCE") or 0)==1
  or (unit:GetProperty("LOTM_PP_WORKSHOP_EXTRA") or 0)==1
  or (LOTM_WORLD_Monsters~=nil and LOTM_WORLD_Monsters.IsMonster~=nil and LOTM_WORLD_Monsters.IsMonster(unit))) or false;
 local unitType=unit~=nil and unit:GetType() or nil;
 -- The engine's unit ID is a generation boundary.  Do not add a client-local
 -- arrival ordinal: duplicate callback delivery must serialize to the same
 -- captured token on every peer.
 local captureToken=table.concat({"C",queuedTurn,normalizedPlayerID,normalizedUnitID,
  unitType or -1,tonumber(x) or -1,tonumber(y) or -1},".");
 local existing=m_networkUnitAdditionKeys[key];
 if existing~=nil then
  if rescueCleanup then existing.RescueCleanup=true; existing.Cancelled=false; return; end
  -- Exact duplicate delivery is one fact. Conflicting same-batch observations
  -- cannot identify a stable engine generation, so remember the ambiguity and
  -- fail closed independent of which observation arrived first.
  if tostring(existing.CaptureToken or "")~=captureToken then
   existing.Ambiguous=true; existing.Cancelled=true;
  end
  if filtered then existing.Filtered=true; end
  return;
 end
 local entry={PlayerID=normalizedPlayerID,UnitID=normalizedUnitID,
  X=tonumber(x),Y=tonumber(y),QueuedTurn=queuedTurn,Key=key,
  UnitType=unitType,Filtered=filtered,CaptureToken=captureToken,RemovedBeforeSettlement=false,
  RescueCleanup=rescueCleanup};
 m_networkUnitAdditionsLocal[#m_networkUnitAdditionsLocal+1]=entry;
 m_networkUnitAdditionKeys[key]=entry;
end
local function ProcessUnitAdded(playerID,unitID,x,y,fromNetworkQueue,queuedTurnOverride,capturedUnitType,capturedFiltered,capturedGeneration,capturedRemoved)
 if playerID~=BarbarianID() then LOTM_UnitAddedPerf.MarkSection("Workshops.Entry.NonBarbarian",1); return; end
 -- UnitAddedToMap is only a local publication callback.  In a network game
 -- do not let creator-local timing flags decide whether a unit enters the
 -- queue: those flags can be true on one peer while the same publication is
 -- delivered after the creator returned on another.  The later synchronized
 -- consumer filters from captured facts and durable unit properties instead.
 if LOTM_MP_TurnSync.IsNetworkGame() and not fromNetworkQueue then
  QueueLocalNetworkUnitAdded(playerID,unitID,x,y); LOTM_UnitAddedPerf.MarkSection("Workshops.Entry.NetworkQueued",1); return;
 end
 if LOTM_RESCUE_Phase10~=nil and LOTM_RESCUE_Phase10.IsCreating~=nil and LOTM_RESCUE_Phase10.IsCreating() then
  LOTM_UnitAddedPerf.MarkSection("Workshops.Entry.Phase10Create",1); return;
 end
 if m_internalCreate then LOTM_UnitAddedPerf.MarkSection("Workshops.Entry.InternalCreate",1); return; end
 if LOTM_WORLD_Monsters~=nil and LOTM_WORLD_Monsters.IsCreating~=nil and LOTM_WORLD_Monsters.IsCreating() then LOTM_UnitAddedPerf.MarkSection("Workshops.Entry.MonsterCreate",1); return; end
 local u=UnitManager.GetUnit(playerID,unitID);
 local generationDetached=fromNetworkQueue and (capturedRemoved==true or u==nil
  or (capturedUnitType~=nil and u:GetType()~=capturedUnitType));
 if generationDetached then u=nil; end
 if u==nil and not fromNetworkQueue then LOTM_UnitAddedPerf.MarkSection("Workshops.Entry.MissingUnit",1); return; end
 if IsRescueMode() and LOTM_WORLD_Barbarians~=nil and LOTM_WORLD_Barbarians.IsProtectedRescueUnit~=nil then
  if u==nil then LOTM_UnitAddedPerf.MarkSection("Workshops.Entry.MissingUnit",1); return; end
  local protected,identity=LOTM_WORLD_Barbarians.IsProtectedRescueUnit(u);
  if protected and identity~="DURABLE" then LOTM_UnitAddedPerf.MarkSection("Workshops.Entry.RescueMonster",1); return; end
  -- The network branch returned to its local-only queue above. Single-player
  -- keeps immediate handling, while recording any failed removal for the
  -- existing synchronized Phase5 turn boundary to retry.
  if LOTM_WORLD_Barbarians.ProcessRescueUnitCandidates~=nil then
   local _,removed=LOTM_WORLD_Barbarians.ProcessRescueUnitCandidates({{Owner=playerID,Unit=unitID}});
   LOTM_UnitAddedPerf.MarkSection("Workshops.Entry.RescueNormalKilled",removed or 0);
  end
  return;
 end
 local filtered=u~=nil and ((u:GetProperty("LOTM_PP_WORKSHOP_SEQUENCE") or 0)==1
  or (u:GetProperty("LOTM_PP_WORKSHOP_EXTRA") or 0)==1
  or IsDurableRescueMonster(playerID,unitID,u))
  or capturedFiltered==true;
 if filtered then LOTM_UnitAddedPerf.MarkSection("Workshops.Entry.FilteredUnit",1); return; end
 if IsRescueMode() then
  if u==nil then LOTM_UnitAddedPerf.MarkSection("Workshops.Entry.MissingUnit",1); return; end
  if IsDurableRescueMonster(playerID,unitID,u) then LOTM_UnitAddedPerf.MarkSection("Workshops.Entry.RescueMonster",1); return; end
  if RESCUE_FINAL_BATTLE_TYPES[u:GetType()]~=true then
   pcall(UnitManager.Kill,u); LOTM_UnitAddedPerf.MarkSection("Workshops.Entry.RescueNormalKilled",1);
  else LOTM_UnitAddedPerf.MarkSection("Workshops.Entry.RescueFinalBattle",1); end
  return;
 end
 local eventX=fromNetworkQueue and tonumber(x) or u:GetX();
 local eventY=fromNetworkQueue and tonumber(y) or u:GetY();
 if (eventX==nil or eventY==nil) and u~=nil then eventX=u:GetX(); eventY=u:GetY(); end
 if eventX==nil or eventY==nil then LOTM_UnitAddedPerf.MarkSection("Workshops.Entry.MissingCoordinates",1); return; end
 local lookupStarted=LOTM_UnitAddedPerf.BeginSection();
 local camp,lookupMode,candidateCount=IndexedNearestWorkshop(eventX,eventY);
 LOTM_UnitAddedPerf.EndSection("Workshops.Lookup.Total",lookupStarted,candidateCount);
 LOTM_UnitAddedPerf.MarkSection("Workshops.Lookup."..lookupMode,1);
 if camp==nil then return; end
 if LOTM_MP_TurnSync.IsNetworkGame() and ((camp:GetProperty(CAMP_REBUILD_PENDING) or 0)==1
  or m_networkImprovementRemovedPlots[camp:GetIndex()]==true) then
  LOTM_UnitAddedPerf.MarkSection("Workshops.Hit.CampGenerationDetached",1); return;
 end
 local hitStarted=LOTM_UnitAddedPerf.BeginSection();
 if eventX==camp:GetX() and eventY==camp:GetY() and (camp:GetProperty(SEQUENCE_CREATED) or 0)==1 then
  local killStarted=LOTM_UnitAddedPerf.BeginSection(); if u~=nil then UnitManager.Kill(u); end LOTM_UnitAddedPerf.EndSection("Workshops.Hit.SequenceKill",killStarted,1);
  LOTM_UnitAddedPerf.EndSection("Workshops.Hit.Total",hitStarted,1); return;
 end
 if LOTM_MP_TurnSync.IsNetworkGame() then
  local generation=QueueNetworkWorkshopUnitAddition(u,camp,queuedTurnOverride,playerID,unitID,capturedUnitType,
   capturedGeneration,generationDetached,NumberValue(camp:GetProperty(CAMP_EPOCH)) or 0);
  -- Persist the captured fact before binding its generation to a live unit.
  -- A failure or reload between the two safely degrades to detached settlement
  -- (counts/derivatives preserved, no possibly reused unit mutated).
  if u~=nil and generation~=nil and generation~="" then u:SetProperty(MP_UNIT_GENERATION_PROPERTY,generation); end
  LOTM_UnitAddedPerf.EndSection("Workshops.Hit.Total",hitStarted,1); return;
 end
 local propertyStarted=LOTM_UnitAddedPerf.BeginSection();
 u:SetProperty("LOTM_PP_WORKSHOP_SOURCE",camp:GetIndex());
 if (camp:GetProperty(LEVEL) or 2)==0 then local a=u:GetAbility(); if a~=nil then a:ChangeAbilityCount("ABILITY_LOTM_PP_WORKSHOP_LEVEL0_STRENGTH",1); end end
 local count=(camp:GetProperty(SPAWNS) or 0)+1; camp:SetProperty(SPAWNS,count);
 Game.SetProperty("LOTM_PP_WORKSHOP_NORMAL_SPAWN_TOTAL",LOTM_WORLD_State.NumberGameProperty("LOTM_PP_WORKSHOP_NORMAL_SPAWN_TOTAL",0)+1);
 LOTM_UnitAddedPerf.EndSection("Workshops.Hit.Properties",propertyStarted,1);
 Trace("normal spawn plot="..camp:GetIndex().." type="..u:GetType().." normalCount="..count.." globalNormal="..tostring(Game.GetProperty("LOTM_PP_WORKSHOP_NORMAL_SPAWN_TOTAL")));
 if (camp:GetProperty(LEVEL) or 2)<=1 and count%2==0 then
  local extraStarted=LOTM_UnitAddedPerf.BeginSection(); CreateExtra(u,camp); LOTM_UnitAddedPerf.EndSection("Workshops.Hit.CreateExtra",extraStarted,1);
 end
 if LOTM_WORLD_Monsters~=nil and LOTM_WORLD_Monsters.TrySpawnFromWorkshop~=nil then
  local monsterStarted=LOTM_UnitAddedPerf.BeginSection();
  local monsterSpawned,monsterReason=LOTM_WORLD_Monsters.TrySpawnFromWorkshop(camp,u);
  LOTM_UnitAddedPerf.EndSection("Workshops.Hit.MonsterAttempt",monsterStarted,1);
  if not LOTM_MP_TurnSync.IsNetworkGame() then
   Log("monster attempt source=UNIT_ADDED plot="..camp:GetIndex().." unit="..u:GetID()
    .." spawned="..tostring(monsterSpawned).." result="..tostring(monsterReason));
  end
 end
 LOTM_UnitAddedPerf.EndSection("Workshops.Hit.Total",hitStarted,1);
end

local function ProcessNetworkLocalUnitAdditions(playerID)
 if not LOTM_MP_TurnSync.IsNetworkGame() or not LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID) then return; end
 local currentTurn=Game.GetCurrentGameTurn(); local ready={}; local waiting={};
 for _,entry in ipairs(m_networkUnitAdditionsLocal) do
  if entry.Cancelled==true and entry.RescueCleanup~=true then
   if m_networkUnitAdditionKeys[entry.Key]==entry then m_networkUnitAdditionKeys[entry.Key]=nil; end
  elseif entry.QueuedTurn<currentTurn then ready[#ready+1]=entry;
  else waiting[#waiting+1]=entry; end
 end
 m_networkUnitAdditionsLocal=waiting;
 table.sort(ready,function(a,b)
  if a.QueuedTurn~=b.QueuedTurn then return a.QueuedTurn<b.QueuedTurn; end
  if a.PlayerID~=b.PlayerID then return a.PlayerID<b.PlayerID; end
  if a.UnitID~=b.UnitID then return a.UnitID<b.UnitID; end
  if (a.X or -1)~=(b.X or -1) then return (a.X or -1)<(b.X or -1); end
  if (a.Y or -1)~=(b.Y or -1) then return (a.Y or -1)<(b.Y or -1); end
  if (a.UnitType or -1)~=(b.UnitType or -1) then return (a.UnitType or -1)<(b.UnitType or -1); end
  if a.RemovedBeforeSettlement~=b.RemovedBeforeSettlement then return a.RemovedBeforeSettlement==true; end
  return tostring(a.CaptureToken or "")<tostring(b.CaptureToken or "");
 end);
 local rescueCandidates={}; local rescueEntries={};
 for _,entry in ipairs(ready) do
  if entry.RescueCleanup==true and IsRescueMode() then
   rescueCandidates[#rescueCandidates+1]={Owner=entry.PlayerID,Unit=entry.UnitID}; rescueEntries[#rescueEntries+1]=entry;
  else
   if m_networkUnitAdditionKeys[entry.Key]==entry then m_networkUnitAdditionKeys[entry.Key]=nil; end
   ProcessUnitAdded(entry.PlayerID,entry.UnitID,entry.X,entry.Y,true,entry.QueuedTurn,
    entry.UnitType,entry.Filtered,nil,entry.RemovedBeforeSettlement);
  end
 end
 if IsRescueMode() then
  local committed=LOTM_WORLD_Barbarians~=nil and LOTM_WORLD_Barbarians.ProcessRescueUnitCandidates~=nil
   and LOTM_WORLD_Barbarians.ProcessRescueUnitCandidates(rescueCandidates);
  for _,entry in ipairs(rescueEntries) do
   if committed then
    if m_networkUnitAdditionKeys[entry.Key]==entry then m_networkUnitAdditionKeys[entry.Key]=nil; end
   else
    m_networkUnitAdditionsLocal[#m_networkUnitAdditionsLocal+1]=entry;
   end
  end
 end
 table.sort(m_networkUnitRemovalBatchKeys);
 local retainedRemovalBatchKeys={};
 for _,key in ipairs(m_networkUnitRemovalBatchKeys) do
  local removedTurn=tonumber(m_networkUnitRemovalBatches[key]);
  if removedTurn~=nil and removedTurn<currentTurn then
   m_networkUnitRemovalBatches[key]=nil;
  elseif removedTurn~=nil then
   retainedRemovalBatchKeys[#retainedRemovalBatchKeys+1]=key;
  end
 end
 m_networkUnitRemovalBatchKeys=retainedRemovalBatchKeys;
end
local function ClearProcessedNetworkImprovementRemovalFacts()
 local stillPending={};
 for _,entry in ipairs(m_networkImprovementRemovals) do stillPending[entry.PlotIndex]=true; end
 table.sort(m_networkImprovementRemovalProcessedPlotKeys);
 for _,plotIndex in ipairs(m_networkImprovementRemovalProcessedPlotKeys) do
  if not stillPending[plotIndex] then m_networkImprovementRemovedPlots[plotIndex]=nil; end
  m_networkImprovementRemovalProcessedPlots[plotIndex]=nil;
 end
 m_networkImprovementRemovalProcessedPlotKeys={};
end
local function OnUnitAdded(playerID,unitID,x,y)
 ProcessUnitAdded(playerID,unitID,x,y,false,nil);
end
local function OnUnitMoved(playerID,unitID)
 if IsRescueMode() and playerID==BarbarianID() then
  -- OnUnitMoved runs inside the native unit operation. Deleting its actor
  -- here can strand barbarian AI turn processing. Birth publications are
  -- handled by the separate synchronized command and the turn queue.
  return;
 end
 if not IsLegalResolver(playerID) then return; end local u=UnitManager.GetUnit(playerID,unitID); if u==nil then return; end local p=Map.GetPlot(u:GetX(),u:GetY());
 if p~=nil and (p:GetImprovementType()==CAMP
  or (IsRescueMode() and (p:GetProperty(CLASSIFIED) or 0)==1 and (p:GetProperty(IS_WORKSHOP) or 0)==1
   and (p:GetProperty(SETTLED) or 0)~=1 and (p:GetProperty(MP_PENDING) or 0)~=1)) then
  p:SetProperty(CLEARER,playerID); p:SetProperty(CLEARER_UNIT,unitID);
 end
end
local function NetworkPendingIndices()
 local result={}; local seen={};
 for token in string.gmatch(tostring(Game.GetProperty(MP_PENDING_SETTLEMENTS) or ""),"[^,]+") do
  local plotIndex=tonumber(token);
  if plotIndex~=nil and plotIndex>=0 and not seen[plotIndex] then seen[plotIndex]=true; result[#result+1]=plotIndex; end
 end
 table.sort(result); return result;
end
local function SaveNetworkPendingIndices(indices)
 local values={}; for _,plotIndex in ipairs(indices) do values[#values+1]=tostring(plotIndex); end
 local serialized=table.concat(values,",");
 if tostring(Game.GetProperty(MP_PENDING_SETTLEMENTS) or "")~=serialized then
  Game.SetProperty(MP_PENDING_SETTLEMENTS,serialized);
 end
end
local function StableNetworkClearer(plot)
 local clearerValue=plot:GetProperty(CLEARER);
 if clearerValue~=nil and IsLegalResolver(tonumber(clearerValue)) then
  return tonumber(clearerValue),NumberValue(plot:GetProperty(CLEARER_UNIT));
 end
 -- Preserve the existing fallback at the shared synchronized boundary.
 -- Never snapshot these occupants in the local removal-publication callback:
 -- different publication timing must not become different reward owners.
 local candidates={};
 for _,unit in ipairs(Units.GetUnitsInPlot(plot) or {}) do
  if IsLegalResolver(unit:GetOwner()) then candidates[#candidates+1]={Owner=unit:GetOwner(),Unit=unit:GetID()}; end
 end
 table.sort(candidates,function(a,b) if a.Owner~=b.Owner then return a.Owner<b.Owner; end return a.Unit<b.Unit; end);
 if #candidates==0 then return nil,nil; end
 return candidates[1].Owner,candidates[1].Unit;
end
QueueNetworkWorkshopSettlement=function(plot,ownerID)
 if (plot:GetProperty(MP_PENDING) or 0)==1 then return; end
 local clearer,clearerUnit=StableNetworkClearer(plot);
 local queuedTurn=Game.GetCurrentGameTurn();
 plot:SetProperty(MP_PENDING,1);
 plot:SetProperty(MP_PENDING_OWNER,ownerID);
 plot:SetProperty(MP_PENDING_CLEARER,clearer);
 plot:SetProperty(MP_PENDING_CLEARER_UNIT,clearerUnit);
 plot:SetProperty(MP_PENDING_LEVEL,NumberValue(plot:GetProperty(LEVEL)) or 2);
 plot:SetProperty(MP_PENDING_PATH,plot:GetProperty(PATH) or "PP");
 plot:SetProperty(MP_PENDING_CLASSIFIED_TURN,NumberValue(plot:GetProperty(CLASSIFIED_TURN)) or Game.GetCurrentGameTurn());
 plot:SetProperty(MP_PENDING_CAMP_EPOCH,NumberValue(plot:GetProperty(CAMP_EPOCH)) or 0);
 plot:SetProperty(MP_PENDING_QUEUED_TURN,queuedTurn);
 local indices=NetworkPendingIndices(); local found=false;
 for _,plotIndex in ipairs(indices) do if plotIndex==plot:GetIndex() then found=true; break; end end
 if not found then indices[#indices+1]=plot:GetIndex(); table.sort(indices); end
 SaveNetworkPendingIndices(indices);
 Log("network settlement queued plot="..plot:GetIndex().." clearer="..tostring(clearer)
  .." queuedTurn="..queuedTurn.." earliestSettlementTurn="..(queuedTurn+1));
end

local function PendingSettlementQueuedTurn(plot,currentTurn)
 local queuedTurn=NumberValue(plot:GetProperty(MP_PENDING_QUEUED_TURN));
 if queuedTurn==nil then
  -- No released build had a pending network settlement before this field was
  -- introduced.  Treat a legacy/incomplete record as newly queued and defer
  -- it one full synchronized turn instead of racing a load-time callback.
  queuedTurn=currentTurn;
  plot:SetProperty(MP_PENDING_QUEUED_TURN,queuedTurn);
 end
 return queuedTurn;
end
local function SettleNetworkWorkshop(plot)
 local plotIndex=plot:GetIndex();
 local pendingCampEpoch=NumberValue(plot:GetProperty(MP_PENDING_CAMP_EPOCH));
 if pendingCampEpoch~=nil and pendingCampEpoch~=(NumberValue(plot:GetProperty(CAMP_EPOCH)) or 0) then
  Log("network settlement discarded stale camp generation plot="..plotIndex
   .." captured="..pendingCampEpoch.." current="..tostring(plot:GetProperty(CAMP_EPOCH)));
  plot:SetProperty(MP_PENDING,nil);
  return true;
 end
 local clearer=NumberValue(plot:GetProperty(MP_PENDING_CLEARER));
 local clearerUnit=NumberValue(plot:GetProperty(MP_PENDING_CLEARER_UNIT));
 local level=NumberValue(plot:GetProperty(MP_PENDING_LEVEL)) or 2;
 local path=plot:GetProperty(MP_PENDING_PATH) or "PP";
 local classificationTurn=NumberValue(plot:GetProperty(MP_PENDING_CLASSIFIED_TURN)) or Game.GetCurrentGameTurn();
 if (plot:GetProperty(MP_CHURCH_SETTLED) or 0)~=1 then
  local ok,details=pcall(function()
   if LOTM_WORLD_Churches~=nil and LOTM_WORLD_Churches.OnWorkshopResolved~=nil then
    LOTM_WORLD_Churches.OnWorkshopResolved(plotIndex,clearer or -1);
   end
  end);
  if not ok then Log("network church settlement error plot="..plotIndex.." error="..tostring(details)); return false; end
  plot:SetProperty(MP_CHURCH_SETTLED,1);
 end
 if IsRescueMode() and (plot:GetProperty(MP_PHASE4_SETTLED) or 0)~=1 then
  local ok,details=pcall(LOTM_RESCUE_Phase4.OnWorkshopCleared,level,clearer or -1,
   clearerUnit or -1,plotIndex,classificationTurn);
  if not ok then Log("network Phase4 settlement error plot="..plotIndex.." error="..tostring(details)); return false; end
  plot:SetProperty(MP_PHASE4_SETTLED,1);
 end
 if (plot:GetProperty(MP_REWARD_SETTLED) or 0)~=1 then
  if clearer~=nil and IsHumanMajor(clearer) and LOTM_PP_GrantWorkshopReward~=nil then
   local eventKey=tostring(plotIndex)..":"..tostring(classificationTurn);
   local ok,granted,result=pcall(LOTM_PP_GrantWorkshopReward,clearer,level,path,eventKey);
   if not ok then Log("network reward error player="..clearer.." plot="..plotIndex.." error="..tostring(granted)); return false; end
   -- Grant mutates the authoritative artifact ledger.  Commit the durable
   -- settlement flags immediately after a successful/complete result, before
   -- any localized notification work that may be unavailable in a peer's
   -- context.  This closes the reload window that could grant a second item.
   if granted==true or result=="COMPLETE" then
    plot:SetProperty(SETTLED,1);
    plot:SetProperty(MP_REWARD_SETTLED,1);
    local notifyOK,notifyError=pcall(function()
     local message=result=="COMPLETE" and Locale.Lookup("LOC_LOTM_PP_WORKSHOP_ALL_COLLECTED")
      or Locale.Lookup("LOC_LOTM_PP_WORKSHOP_REWARD",GameInfo.GreatWorks[result]
       and Locale.Lookup(GameInfo.GreatWorks[result].Name) or tostring(result));
     Game.AddWorldViewText(clearer,message,plot:GetX(),plot:GetY());
    end);
    if not notifyOK then Log("network reward notification deferred player="..clearer.." plot="..plotIndex.." error="..tostring(notifyError)); end
    Log("network cleared player="..clearer.." plot="..plotIndex.." path="..tostring(path)
     .." granted="..tostring(granted).." result="..tostring(result)
     .." settledTurn="..Game.GetCurrentGameTurn());
   else
    Log("network reward not committed player="..clearer.." plot="..plotIndex.." result="..tostring(result));
    return false;
   end
  else Log("network cleared without human reward plot="..plotIndex
    .." clearer="..tostring(clearer).." improvementOwner="..tostring(plot:GetProperty(MP_PENDING_OWNER))); end
  if clearer==nil or not IsHumanMajor(clearer) or LOTM_PP_GrantWorkshopReward==nil then
   plot:SetProperty(SETTLED,1);
   plot:SetProperty(MP_REWARD_SETTLED,1);
  end
 end
 plot:SetProperty(MP_PENDING,nil);
 return true;
end
local function ProcessNetworkWorkshopSettlements(playerID)
 local claimed,currentTurn=NetworkQueueBoundary(playerID,MP_SETTLEMENT_QUEUE_LAST_BOUNDARY);
 if not claimed then return; end
 local pending=NetworkPendingIndices();
 local index=1;
 while index<=#pending do
  local plotIndex=pending[index];
  local plot=Map.GetPlotByIndex(plotIndex);
  if plot==nil or (plot:GetProperty(MP_PENDING) or 0)~=1 then
   -- Stale index is a successful no-op; remove it immediately so a reload
   -- cannot keep retrying a destroyed/cleared camp forever.
   table.remove(pending,index); SaveNetworkPendingIndices(pending);
  elseif PendingSettlementQueuedTurn(plot,currentTurn)>=currentTurn then
   index=index+1;
  else
   local ok,result=pcall(SettleNetworkWorkshop,plot);
   if not ok then
    Log("network settlement error plot="..plotIndex.." error="..tostring(result));
    -- Preserve the failed suffix and let the dispatcher stop later writers.
    error(result);
   end
   if result~=true then
    -- Preserve this entry and every later PlotIndex until the next boundary;
    -- all entries removed before it have durable checkpoints.
    break;
   end
   table.remove(pending,index); SaveNetworkPendingIndices(pending);
   Trace("network settlement checkpoint plot="..plotIndex.." result="..tostring(result));
  end
 end
end
local function QueueNetworkImprovementRemoved(x,y,ownerID)
 local plot=Map.GetPlot(x,y); if plot==nil then return; end
 if (plot:GetProperty(CLASSIFIED) or 0)~=1 and not m_workshopSet[plot:GetIndex()] then return; end
 local queuedTurn=Game.GetCurrentGameTurn();
 local campEpoch=NumberValue(plot:GetProperty(CAMP_EPOCH)) or 0;
 local key=tostring(plot:GetIndex())..":"..tostring(campEpoch)..":"..tostring(queuedTurn);
 if m_networkImprovementRemovalKeys[key]~=nil then return; end
 local entry={X=tonumber(x),Y=tonumber(y),OwnerID=tonumber(ownerID),
  PlotIndex=plot:GetIndex(),CampEpoch=campEpoch,QueuedTurn=queuedTurn,Key=key};
 m_networkImprovementRemovals[#m_networkImprovementRemovals+1]=entry;
 m_networkImprovementRemovalKeys[key]=entry;
 m_networkImprovementRemovedPlots[plot:GetIndex()]=true;
 Log("network removal observed plot="..plot:GetIndex()
  .." observedTurn="..queuedTurn.." earliestSettlementTurn="..(queuedTurn+2));
end
local function OnRemoved(x,y,ownerID,fromNetworkQueue,capturedCampEpoch)
 if LOTM_MP_TurnSync.IsNetworkGame() and not fromNetworkQueue then
  QueueNetworkImprovementRemoved(x,y,ownerID); return;
 end
 local p=Map.GetPlot(x,y); if p==nil then return; end
 if fromNetworkQueue and tonumber(capturedCampEpoch)~=(NumberValue(p:GetProperty(CAMP_EPOCH)) or 0) then
  Trace("stale camp removal ignored plot="..p:GetIndex().." capturedEpoch="..tostring(capturedCampEpoch)
   .." currentEpoch="..tostring(p:GetProperty(CAMP_EPOCH))); return;
 end
 UnregisterWorkshopPlot(p:GetIndex());
 if (p:GetProperty(CLASSIFIED) or 0)~=1 then return; end
 p:SetProperty(CAMP_REBUILD_PENDING,1);
 if LOTM_MP_TurnSync.IsNetworkGame() and (p:GetProperty(IS_WORKSHOP) or 0)==1 then
  if (p:GetProperty(SETTLED) or 0)~=1 then QueueNetworkWorkshopSettlement(p,ownerID); end
  return;
 end
 local clearerValue=p:GetProperty(CLEARER); local clearer=clearerValue~=nil and tonumber(clearerValue) or nil; local clearerUnit=NumberValue(p:GetProperty(CLEARER_UNIT));
 if clearer==nil then for _,unit in ipairs(Units.GetUnitsInPlot(p) or {}) do if IsLegalResolver(unit:GetOwner()) then clearer=unit:GetOwner(); clearerUnit=unit:GetID(); break; end end end
 if (p:GetProperty(IS_WORKSHOP) or 0)~=1 then
  if LOTM_WORLD_Churches~=nil and LOTM_WORLD_Churches.OnBarbarianCampResolved~=nil then LOTM_WORLD_Churches.OnBarbarianCampResolved(p:GetIndex(),clearer or -1); end
  return;
 end
 if (p:GetProperty(SETTLED) or 0)==1 then return; end
 if LOTM_WORLD_Churches~=nil and LOTM_WORLD_Churches.OnWorkshopResolved~=nil then LOTM_WORLD_Churches.OnWorkshopResolved(p:GetIndex(),clearer or -1); end
 if IsRescueMode() then
  local ok,details=pcall(LOTM_RESCUE_Phase4.OnWorkshopCleared,NumberValue(p:GetProperty(LEVEL)) or 2,clearer or -1,clearerUnit or -1,p:GetIndex(),NumberValue(p:GetProperty(CLASSIFIED_TURN)) or Game.GetCurrentGameTurn());
  if not ok then Log("OnWorkshopCleared interface error="..tostring(details)); end
 end
 if clearer~=nil and IsHumanMajor(clearer) and LOTM_PP_GrantWorkshopReward~=nil then local ok,granted,result=pcall(LOTM_PP_GrantWorkshopReward,clearer,p:GetProperty(LEVEL) or 2,p:GetProperty(PATH) or "PP"); if ok then p:SetProperty(SETTLED,1); local message=result=="COMPLETE" and Locale.Lookup("LOC_LOTM_PP_WORKSHOP_ALL_COLLECTED") or Locale.Lookup("LOC_LOTM_PP_WORKSHOP_REWARD",GameInfo.GreatWorks[result] and Locale.Lookup(GameInfo.GreatWorks[result].Name) or tostring(result)); Game.AddWorldViewText(clearer,message,x,y); Log("cleared player="..clearer.." path="..tostring(p:GetProperty(PATH)).." granted="..tostring(granted).." result="..tostring(result)); else Log("reward error player="..clearer.." error="..tostring(granted)); end
 else Log("cleared without human reward owner="..tostring(ownerID)); end
end
-- Called only from an authenticated EXECUTE_SCRIPT Gameplay command. The UI
-- supplies an identity to inspect, never the claimed clearer or reward.
function LOTM_PP_Workshops.ResolveRemovedCamp(plotIndex,campEpoch)
 if not IsRescueMode() then return false; end
 local plot=Map.GetPlotByIndex(plotIndex);
 if plot==nil or plot:GetImprovementType()==CAMP
  or NumberValue(plot:GetProperty(CAMP_EPOCH))~=campEpoch
  or (plot:GetProperty(CLASSIFIED) or 0)~=1 or (plot:GetProperty(IS_WORKSHOP) or 0)~=1 then return false; end
 if (plot:GetProperty(SETTLED) or 0)==1 then return true; end
 if not LOTM_MP_TurnSync.IsNetworkGame() then OnRemoved(plot:GetX(),plot:GetY(),plot:GetOwner()); return (plot:GetProperty(SETTLED) or 0)==1; end
 OnRemoved(plot:GetX(),plot:GetY(),plot:GetOwner(),true,campEpoch);
 if (plot:GetProperty(MP_PENDING) or 0)~=1 then return false; end
 local ok,done=pcall(SettleNetworkWorkshop,plot);
 if ok and done then RemoveNetworkPendingSettlementIndex(plotIndex);
 else Log("synchronized camp command retry plot="..plotIndex.." detail="..tostring(done)); end
 return ok and done==true;
end

local function ProcessNetworkImprovementRemovals(playerID)
 if not LOTM_MP_TurnSync.IsNetworkGame()
  or not LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID) then return; end
 local currentTurn=Game.GetCurrentGameTurn(); local ready={}; local waiting={};
 for _,entry in ipairs(m_networkImprovementRemovals) do
  if entry.QueuedTurn<currentTurn then ready[#ready+1]=entry;
  else waiting[#waiting+1]=entry; end
 end
 m_networkImprovementRemovals=waiting;
 table.sort(ready,function(a,b)
  if a.QueuedTurn~=b.QueuedTurn then return a.QueuedTurn<b.QueuedTurn; end
  if a.PlotIndex~=b.PlotIndex then return a.PlotIndex<b.PlotIndex; end
  if (a.CampEpoch or 0)~=(b.CampEpoch or 0) then return (a.CampEpoch or 0)<(b.CampEpoch or 0); end
  if (a.OwnerID or -1)~=(b.OwnerID or -1) then return (a.OwnerID or -1)<(b.OwnerID or -1); end
  if (a.X or -1)~=(b.X or -1) then return (a.X or -1)<(b.X or -1); end
  return (a.Y or -1)<(b.Y or -1);
 end);
 for _,entry in ipairs(ready) do
  m_networkImprovementRemovalKeys[entry.Key]=nil;
  OnRemoved(entry.X,entry.Y,entry.OwnerID,true,entry.CampEpoch);
  if m_networkImprovementRemovalProcessedPlots[entry.PlotIndex]~=true then
   m_networkImprovementRemovalProcessedPlotKeys[#m_networkImprovementRemovalProcessedPlotKeys+1]=entry.PlotIndex;
  end
  m_networkImprovementRemovalProcessedPlots[entry.PlotIndex]=true;
 end
end
local function Dead(unit) return unit==nil or unit:IsDead() or unit:IsDelayedDeath(); end
local function SettleLostControlKill(playerID,unitID,killerPlayerID,killerUnitID,capturedLevel,capturedSerial,confirmedRemoved)
 if not IsRescueMode() then return; end
 local key=SequenceEngineKey(playerID,unitID); local serialKey=SequenceSerialEngineKey(playerID,unitID);
 local level=NumberValue(capturedLevel); local serial=NumberValue(capturedSerial);
 if level==nil then level=NumberValue(Game.GetProperty(key)); end
 if serial==nil then serial=NumberValue(Game.GetProperty(serialKey)); end
 if level==nil or (confirmedRemoved~=true and not Dead(UnitManager.GetUnit(playerID,unitID))) then return; end
 local currentUnit=UnitManager.GetUnit(playerID,unitID);
 local currentUnitSerial=currentUnit~=nil and NumberValue(currentUnit:GetProperty(RESCUE_SEQUENCE_SERIAL)) or nil;
 local identityReused=currentUnit~=nil and (serial==nil or currentUnitSerial~=serial);
 if not identityReused and LOTM_RESCUE_Phase9Digestion~=nil
  and type(LOTM_RESCUE_Phase9Digestion.RecordLostControlIdentity)=="function" then
  LOTM_RESCUE_Phase9Digestion.RecordLostControlIdentity(playerID,unitID,
   currentUnit~=nil and (currentUnit:GetCombat() or 0) or 0);
 end
 -- A later unit may already own the same engine ID. Clear the engine mapping
 -- only while it still names the sequence generation being settled.
 if not identityReused and serial~=nil and NumberValue(Game.GetProperty(serialKey))==serial then
  Game.SetProperty(key,nil); Game.SetProperty(serialKey,nil);
 end
 local ok,details=pcall(LOTM_RESCUE_Phase4.OnLostControlKilled,level,killerPlayerID or -1,killerUnitID or -1,"CENTER",serial or (tostring(playerID)..":"..tostring(unitID)));
 if not ok then Log("OnLostControlKilled interface error="..tostring(details)); end
end
local function ProcessUnitRemoved(playerID,unitID,killerPlayerID,killerUnitID,capturedLevel,capturedSerial)
 local prefix="LOTM_RESCUE_SCRIPTED_KILLER:"..playerID..":"..unitID..":";
 local expectedSerial=NumberValue(capturedSerial);
 if expectedSerial==nil then expectedSerial=NumberValue(Game.GetProperty(SequenceSerialEngineKey(playerID,unitID))); end
 local scriptedIdentityMatches=expectedSerial~=nil and expectedSerial>0
  and tostring(Game.GetProperty(prefix.."TARGET_KIND") or "")=="SEQUENCE"
  and NumberValue(Game.GetProperty(prefix.."TARGET_SERIAL"))==expectedSerial;
 local resolvedKillerPlayerID=NumberValue(killerPlayerID);
 local resolvedKillerUnitID=NumberValue(killerUnitID);
 if resolvedKillerPlayerID==nil and scriptedIdentityMatches then resolvedKillerPlayerID=NumberValue(Game.GetProperty(prefix.."PLAYER")); end
 if resolvedKillerUnitID==nil and scriptedIdentityMatches then resolvedKillerUnitID=NumberValue(Game.GetProperty(prefix.."UNIT")); end
 if resolvedKillerPlayerID==nil then return; end
 if scriptedIdentityMatches then
  local storedKiller=NumberValue(Game.GetProperty(prefix.."PLAYER"));
  local storedKillerUnit=NumberValue(Game.GetProperty(prefix.."UNIT"));
  if storedKiller==resolvedKillerPlayerID and (storedKillerUnit or -1)==(resolvedKillerUnitID or -1) then
   Game.SetProperty(prefix.."PLAYER",nil); Game.SetProperty(prefix.."UNIT",nil);
   Game.SetProperty(prefix.."TARGET_KIND",nil); Game.SetProperty(prefix.."TARGET_SERIAL",nil);
  end
 end
 SettleLostControlKill(playerID,unitID,resolvedKillerPlayerID,resolvedKillerUnitID or -1,
  capturedLevel,expectedSerial,true);
end
local function QueueNetworkUnitRemoved(playerID,unitID)
 local normalizedPlayerID=tonumber(playerID); local normalizedUnitID=tonumber(unitID);
 if normalizedPlayerID==nil or normalizedUnitID==nil then return; end
 local prefix="LOTM_RESCUE_SCRIPTED_KILLER:"..normalizedPlayerID..":"..normalizedUnitID..":";
 local sequenceSerial=NumberValue(Game.GetProperty(SequenceSerialEngineKey(normalizedPlayerID,normalizedUnitID)));
 if sequenceSerial==nil or sequenceSerial<=0
  or tostring(Game.GetProperty(prefix.."TARGET_KIND") or "")~="SEQUENCE"
  or NumberValue(Game.GetProperty(prefix.."TARGET_SERIAL"))~=sequenceSerial then return; end
 local killerPlayerID=NumberValue(Game.GetProperty(prefix.."PLAYER"));
 if killerPlayerID==nil then return; end
 local queuedTurn=Game.GetCurrentGameTurn();
 local key=tostring(normalizedPlayerID)..":"..tostring(normalizedUnitID)..":"..tostring(queuedTurn);
 if m_networkUnitRemovalKeys[key]~=nil then return; end
 local entry={PlayerID=normalizedPlayerID,UnitID=normalizedUnitID,
  KillerPlayerID=killerPlayerID,KillerUnitID=NumberValue(Game.GetProperty(prefix.."UNIT")),
  Level=NumberValue(Game.GetProperty(SequenceEngineKey(normalizedPlayerID,normalizedUnitID))),
  Serial=sequenceSerial,
  QueuedTurn=queuedTurn,Key=key};
 m_networkUnitRemovals[#m_networkUnitRemovals+1]=entry;
 m_networkUnitRemovalKeys[key]=entry;
end
local function OnUnitRemoved(playerID,unitID)
 if LOTM_MP_TurnSync.IsNetworkGame() then
  local normalizedPlayerID=tonumber(playerID); local normalizedUnitID=tonumber(unitID);
  if normalizedPlayerID~=nil and normalizedUnitID~=nil then
    local removedTurn=Game.GetCurrentGameTurn();
    local batchKey=LocalNetworkUnitBatchKey(normalizedPlayerID,normalizedUnitID,removedTurn);
    if m_networkUnitRemovalBatches[batchKey]==nil then
     m_networkUnitRemovalBatchKeys[#m_networkUnitRemovalBatchKeys+1]=batchKey;
    end
    m_networkUnitRemovalBatches[batchKey]=removedTurn;
   for _,pending in ipairs(m_networkUnitAdditionsLocal) do
    if pending.PlayerID==normalizedPlayerID and pending.UnitID==normalizedUnitID then
     if pending.QueuedTurn==removedTurn then
      pending.Cancelled=true;
     else
      pending.RemovedBeforeSettlement=true;
     end
    end
   end
  end
  QueueNetworkUnitRemoved(playerID,unitID); return;
 end
 ProcessUnitRemoved(playerID,unitID,nil,nil,nil,nil);
end
local function ProcessNetworkUnitRemovals(playerID)
 if not LOTM_MP_TurnSync.IsNetworkGame()
  or not LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID) then return; end
 local currentTurn=Game.GetCurrentGameTurn(); local ready={}; local waiting={};
 for _,entry in ipairs(m_networkUnitRemovals) do
  if entry.QueuedTurn<currentTurn then ready[#ready+1]=entry;
  else waiting[#waiting+1]=entry; end
 end
 m_networkUnitRemovals=waiting;
 table.sort(ready,function(a,b)
  if a.QueuedTurn~=b.QueuedTurn then return a.QueuedTurn<b.QueuedTurn; end
  if a.PlayerID~=b.PlayerID then return a.PlayerID<b.PlayerID; end
  if a.UnitID~=b.UnitID then return a.UnitID<b.UnitID; end
  if (a.KillerPlayerID or -1)~=(b.KillerPlayerID or -1) then return (a.KillerPlayerID or -1)<(b.KillerPlayerID or -1); end
  return (a.KillerUnitID or -1)<(b.KillerUnitID or -1);
 end);
 for _,entry in ipairs(ready) do
  m_networkUnitRemovalKeys[entry.Key]=nil;
  ProcessUnitRemoved(entry.PlayerID,entry.UnitID,entry.KillerPlayerID,entry.KillerUnitID,entry.Level,entry.Serial);
 end
end
local function OnCombat(attackerPlayerID,attackerUnitID,defenderPlayerID,defenderUnitID)
 SettleLostControlKill(attackerPlayerID,attackerUnitID,defenderPlayerID,defenderUnitID);
 SettleLostControlKill(defenderPlayerID,defenderUnitID,attackerPlayerID,attackerUnitID);
end

-- Barbarian tribe creation publishes its initial UnitAddedToMap callbacks
-- before ImprovementAddedToMap on some single-player runs.  The new camp is
-- therefore not classified yet and those units cannot find their workshop.
-- Reconcile only the bounded radius used by the existing lookup, only for the
-- freshly classified camp, and only for units that still have no source.
function LOTM_PP_Workshops.ReconcileSinglePlayerWorkshopBirthUnits(camp)
 if camp==nil or IsRescueMode() or LOTM_MP_TurnSync.IsNetworkGame() then return; end
 local barb=BarbarianID(); if barb<0 then return; end
 local candidates={}; local seenPlots={}; local seenUnits={};
 for radius=0,3 do
  for dx=-radius,radius do for dy=-radius,radius do
   local plot=Map.GetPlotXYWithRangeCheck(camp:GetX(),camp:GetY(),dx,dy,radius);
   local plotIndex=plot~=nil and plot:GetIndex() or -1;
   if plot~=nil and not seenPlots[plotIndex] then
    seenPlots[plotIndex]=true;
    for _,unit in ipairs(Units.GetUnitsInPlot(plot) or {}) do
     local source=unit:GetProperty("LOTM_PP_WORKSHOP_SOURCE");
     local key=tostring(unit:GetOwner())..":"..tostring(unit:GetID());
     if unit:GetOwner()==barb and source==nil and not seenUnits[key]
      and (unit:GetProperty("LOTM_PP_WORKSHOP_SEQUENCE") or 0)~=1
      and (unit:GetProperty("LOTM_PP_WORKSHOP_EXTRA") or 0)~=1
      and not (LOTM_WORLD_Monsters~=nil and LOTM_WORLD_Monsters.IsMonster~=nil
       and LOTM_WORLD_Monsters.IsMonster(unit)) then
      seenUnits[key]=true; candidates[#candidates+1]=unit;
     end
    end
   end
  end end
 end
 table.sort(candidates,function(a,b) return a:GetID()<b:GetID(); end);
 local repaired=0;
 for _,unit in ipairs(candidates) do
  local ownerID=unit:GetOwner(); local unitID=unit:GetID();
  ProcessUnitAdded(ownerID,unitID,unit:GetX(),unit:GetY(),false,nil);
  local live=UnitManager.GetUnit(ownerID,unitID);
  local source=live~=nil and live:GetProperty("LOTM_PP_WORKSHOP_SOURCE") or nil;
  if tonumber(source)==camp:GetIndex() then repaired=repaired+1; end
 end
 Log("single-player birth units reconciled plot="..camp:GetIndex()
  .." candidates="..#candidates.." repaired="..repaired);
end

local function OnTurn(playerID,isFirstTimeThisTurn)
 if isFirstTimeThisTurn==false then return; end
 if LOTM_MP_TurnSync.IsNetworkGame() then
  -- Queue consumption is anchored to exactly one synchronized major-player
  -- boundary.  Single-player continues directly to its legacy barbarian
  -- turn path below; no queue state is consulted there.
  ProcessNetworkImprovementRemovals(playerID);
  ProcessNetworkUnitRemovals(playerID);
   ProcessNetworkImprovementAdditions(playerID);
   ProcessNetworkLocalUnitAdditions(playerID);
   ClearProcessedNetworkImprovementRemovalFacts();
  ProcessNetworkWorkshopUnitAdditions(playerID);
  ProcessNetworkWorkshopSettlements(playerID);
 end
 if playerID==BarbarianID() then
  local turnStarted=LOTM_UnitAddedPerf.BeginSection();
  EnsurePhase4State();
  local plotStarted=LOTM_UnitAddedPerf.BeginSection(); local campCount=0; local stale={};
  for _,plotIndex in ipairs(m_workshopPlots) do
   local p=Map.GetPlotByIndex(plotIndex);
   if IsWorkshopPlot(p) then campCount=campCount+1; Classify(p); else stale[#stale+1]=plotIndex; end
  end
  for _,plotIndex in ipairs(stale) do UnregisterWorkshopPlot(plotIndex); end
  LOTM_UnitAddedPerf.EndSection("Workshops.TurnPlots",plotStarted,campCount);
  local unitsStarted=LOTM_UnitAddedPerf.BeginSection(); local unitCount=0;
  local barb=Players[playerID]; if barb~=nil then
   local units={}; for _,u in barb:GetUnits():Members() do units[#units+1]=u; end
   if LOTM_MP_TurnSync.IsNetworkGame() then table.sort(units,function(a,b) return a:GetID()<b:GetID(); end); end
   for _,u in ipairs(units) do
    unitCount=unitCount+1;
    if (u:GetProperty("LOTM_PP_WORKSHOP_SEQUENCE") or 0)==1 then
     EnsureSequenceStrength(u,nil);
     local source=Map.GetPlotByIndex(u:GetProperty("LOTM_PP_WORKSHOP_PLOT") or -1);
     if source~=nil and (u:GetX()~=source:GetX() or u:GetY()~=source:GetY()) then
      if UnitManager.PlaceUnit~=nil then UnitManager.PlaceUnit(u,source:GetX(),source:GetY()); Trace("sequence movement corrected plot="..source:GetIndex()); end
     end
     UnitManager.FinishMoves(u)
   elseif u:GetProperty("LOTM_PP_WORKSHOP_SOURCE")~=nil then local camp=Map.GetPlotByIndex(u:GetProperty("LOTM_PP_WORKSHOP_SOURCE")); if camp~=nil and (camp:GetProperty(LEVEL) or 2)==0 and u:GetDamage()>0 then u:ChangeDamage(-math.min(10,u:GetDamage())); end end
   end
  end
  LOTM_UnitAddedPerf.EndSection("Workshops.TurnUnits",unitsStarted,unitCount);
  LOTM_UnitAddedPerf.EndSection("Workshops.TurnTotal",turnStarted,campCount+unitCount);
  if LOTM_UnitAddedPerf.SectionEnabled then LOTM_UnitAddedPerf.ReportSections("firstBarbarianTurn"); LOTM_UnitAddedPerf.SectionEnabled=false; end
 end
end
local function Initialize()
 local initializeStarted=LOTM_UnitAddedPerf.BeginSection();
 if LOTM_MP_TurnSync.IsNetworkGame() then
  Events.ImprovementAddedToMap.Add(QueueNetworkImprovementAdded);
 else
  -- Preserve the original immediate single-player path exactly.
  Events.ImprovementAddedToMap.Add(ClassifySinglePlayerImprovementAdded);
 end
 Events.ImprovementRemovedFromMap.Add(OnRemoved); Events.UnitAddedToMap.Add(LOTM_UnitAddedPerf.Wrap("Workshops",OnUnitAdded)); Events.UnitRemovedFromMap.Add(OnUnitRemoved); GameEvents.OnUnitMoved.Add(OnUnitMoved); GameEvents.OnCombatOccurred.Add(OnCombat); LOTM_MP_TurnSync.Add(OnTurn,"Workshops");
 LOTM_MP_TurnSync.RunStartup(function()
  local scanStarted=LOTM_UnitAddedPerf.BeginSection(); local campCount=InitializeWorkshopRegistry();
  LOTM_UnitAddedPerf.EndSection("Workshops.InitializePlots",scanStarted,campCount);
  LOTM_UnitAddedPerf.EndSection("Workshops.InitializeTotal",initializeStarted,campCount);
  Log("initialized registryVersion="..WORKSHOP_REGISTRY_VERSION.." workshops="..#m_workshopPlots.." fullScan=migrationOnly unitLookup=coverageIndex classification=stable-v"..CLASSIFICATION_VERSION);
 end,"Workshops");
end
Initialize();
-- END POST_RC241_DELTA MODULE: Scripts/LOTM_PP_Workshops.lua
end;

m_mp241Loaders["LOTM_RESCUE_Artifacts"] = function()
-- BEGIN RC241 MODULE: Scripts/LOTM_RESCUE_Artifacts.lua
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("MP.LOTM_RESCUE_Artifacts","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"MP.LOTM_RESCUE_Artifacts","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"MP.LOTM_RESCUE_Artifacts","GameEvents");
-- END RC342 STARTUP TRACE

-- Resource 268: synchronized Rescue-only artifact effects.
-- UI may request an action, but every mutation and reward is revalidated here.
LOTM_RESCUE_Artifacts=LOTM_RESCUE_Artifacts or {};

local VERSION=3;
local SLOT_PREFIX="LOTM_PP_ARTIFACT_SLOT_";
local INSTANCE_PREFIX="LOTM_PP_ARTIFACT_INSTANCE_";
local WEATHER_ABILITY="ABILITY_LOTM_RESCUE_WEATHER_MONSTER_DEBUFF";
local ATTACHED_PROPERTY="LOTM_RESCUE_ARTIFACT_MODIFIERS_268";
local UPGRADE_ATTACHED_PROPERTY="LOTM_RESCUE_ARTIFACT_MODIFIERS_270";
local UPGRADE271_ATTACHED_PROPERTY="LOTM_RESCUE_ARTIFACT_MODIFIERS_271";
local ALLY_ATTACHED_PROPERTY="LOTM_RESCUE_ARTIFACT_ALLY_MODIFIERS_268";
local ALLY_UPGRADE_ATTACHED_PROPERTY="LOTM_RESCUE_ARTIFACT_ALLY_MODIFIERS_270";
local ALLY_UPGRADE271_ATTACHED_PROPERTY="LOTM_RESCUE_ARTIFACT_ALLY_MODIFIERS_271";
local MIGRATION_PROPERTY="LOTM_RESCUE_ARTIFACT_MIGRATION_268";
local WEATHER_RECONCILE_VERSION=2;
local WEATHER_RECONCILE_PROPERTY="LOTM_RESCUE_ARTIFACT_WEATHER_RECONCILE_VERSION";
local ARTIFACTS={
 "GREATWORK_LOTM_PP_GOLDEN_APPRAISAL_MIRROR","GREATWORK_LOTM_PP_PERPETUAL_GEARBOX","GREATWORK_LOTM_PP_ERROR_ASTROLABE",
 "GREATWORK_LOTM_PP_HERMES_FURNACE","GREATWORK_LOTM_PP_MYSTERY_BLUEPRINT","GREATWORK_LOTM_PP_KNOWLEDGE_CASKET",
 "GREATWORK_LOTM_PP_CIVILIZATION_STELE","GREATWORK_LOTM_RP_DISASTER_EMBER","GREATWORK_LOTM_RP_CONSPIRATOR_LETTER",
 "GREATWORK_LOTM_RP_BLOOD_HARVEST_SICKLE","GREATWORK_LOTM_RP_IRONBLOOD_BANNER","GREATWORK_LOTM_RP_WAR_SCRIPTURE",
 "GREATWORK_LOTM_RP_DISASTER_WEATHER","GREATWORK_LOTM_RP_CONQUEROR_CROWN","GREATWORK_LOTM_BE_GOLDEN_BRIBE",
 "GREATWORK_LOTM_BE_CORRUPTION_TAXBOOK","GREATWORK_LOTM_BE_CHAOS_CODEX","GREATWORK_LOTM_BE_DEPRAVED_FEAST",
 "GREATWORK_LOTM_BE_FRENZY_SCEPTER","GREATWORK_LOTM_BE_ENTROPY_CROWN","GREATWORK_LOTM_BE_ORDER_CONVERTER"
};

local function Log(message) print("[LOTM_RESCUE][Artifacts] "..tostring(message)); end
local function Number(value,default) if value==nil then return default; end return tonumber(value) or default; end
local function Active() return Number(Game.GetProperty("LOTM_RESCUE_MODE"),0)==1; end
local function Human(playerID)
 local p=Players[playerID];
 return p~=nil and p:IsAlive() and p:IsMajor() and p:IsHuman() and p or nil;
end
local function ResourceType(index,positive)
 return string.format("RESOURCE_LOTM_RESCUE_ARTIFACT_LEASE_%02d_%s",index,positive and "POS" or "NEG");
end
local function OrdinaryResourceType(index,positive)
 return string.format("RESOURCE_LOTM_ARTIFACT_LEASE76_%02d_%s",index,positive and "POS" or "NEG");
end
local function SetResource(player,resourceType,wanted)
 local row=GameInfo.Resources[resourceType]; if player==nil or row==nil then return false; end
 local resources=player:GetResources(); local current=resources:GetResourceAmount(row.Index) or 0;
 local target=wanted and 1 or 0;
 if current~=target and resources.ChangeResourceAmount~=nil then resources:ChangeResourceAmount(row.Index,target-current); return true; end
 return false;
end
local function IsEquipped(player,artifactType)
 for slot=1,9 do if player:GetProperty(SLOT_PREFIX..slot)==artifactType then return true; end end
 return false;
end
local function Polarity(player,artifactType)
 if not IsEquipped(player,artifactType) then return false,false; end
 local instance=Number(player:GetProperty(INSTANCE_PREFIX..artifactType),-1);
 local playerTurn=Number(player:GetProperty("LOTM_WORLD_PLAYER_TURN"),0);
 local satisfiedUntil=instance>=0 and Number(player:GetProperty("LOTM_ARTIFACT_SATISFIED_UNTIL_"..instance),-1) or -1;
 local uncontrolledUntil=instance>=0 and Number(player:GetProperty("LOTM_ARTIFACT_UNCONTROLLED_UNTIL_"..instance),-1) or -1;
 if uncontrolledUntil>playerTurn then return false,true; end
 if satisfiedUntil>playerTurn then return true,false; end
 return true,true;
end
local function PositiveActive(player,artifactType)
 local positive=Polarity(player,artifactType); return positive;
end

local rescueModifierIds=nil;
local function RescueModifierIds()
 if rescueModifierIds~=nil then return rescueModifierIds; end
 rescueModifierIds={};
 if GameInfo.LOTM_RescueArtifactModifiers268~=nil then
  for row in GameInfo.LOTM_RescueArtifactModifiers268() do rescueModifierIds[#rescueModifierIds+1]=row.ModifierId; end
 end
 table.sort(rescueModifierIds); return rescueModifierIds;
end
local function EnsureHumanInfrastructure(player)
 if Number(player:GetProperty(ATTACHED_PROPERTY),0)~=1 then
  local ids=RescueModifierIds();
  for _,modifierID in ipairs(ids) do pcall(function() player:AttachModifierByID(modifierID); end); end
  player:SetProperty(ATTACHED_PROPERTY,1); player:SetProperty(UPGRADE_ATTACHED_PROPERTY,1); player:SetProperty(UPGRADE271_ATTACHED_PROPERTY,1);
  Log("holder modifiers attached player="..player:GetID().." count="..#ids);
 else
  if Number(player:GetProperty(UPGRADE_ATTACHED_PROPERTY),0)~=1 then
   local ids={
   "LOTM_RESCUE_LETTER_GOLD","LOTM_RESCUE_LETTER_PRODUCTION",
   "LOTM_RESCUE_SCRIPTURE_PRODUCTION","LOTM_RESCUE_SCRIPTURE_FOOD",
   "LOTM_RESCUE_SCRIPTURE_OLD_WAR_PRODUCTION_NEUTRALIZE268",
   "LOTM_RESCUE_SCRIPTURE_OLD_PEACE_PRODUCTION_NEUTRALIZE268",
   "LOTM_RESCUE_SCRIPTURE_OLD_WEARINESS_NEUTRALIZE268"
   };
   for _,modifierID in ipairs(ids) do pcall(function() player:AttachModifierByID(modifierID); end); end
   player:SetProperty(UPGRADE_ATTACHED_PROPERTY,1);
   Log("holder resource270 modifiers attached player="..player:GetID().." count="..#ids);
  elseif Number(player:GetProperty(UPGRADE271_ATTACHED_PROPERTY),0)~=1 then
   local ids={"LOTM_RESCUE_CROWN_SELF_COMBAT_NEUTRALIZE270","LOTM_RESCUE_CROWN_SELF_INNER_RESTORE270","LOTM_RESCUE_CROWN_SELF_OUTER_RESTORE270"};
   for _,modifierID in ipairs(ids) do pcall(function() player:AttachModifierByID(modifierID); end); end
   Log("holder resource271 crown repair attached player="..player:GetID().." count="..#ids);
  end
  player:SetProperty(UPGRADE271_ATTACHED_PROPERTY,1);
 end
end
local function EnsureAllyInfrastructure(player)
 if player==nil or not player:IsAlive() or not player:IsMajor() or player:IsHuman() then return; end
 local baseAttached=Number(player:GetProperty(ALLY_ATTACHED_PROPERTY),0)==1;
 local upgradeAttached=Number(player:GetProperty(ALLY_UPGRADE_ATTACHED_PROPERTY),0)==1;
 local upgrade271Attached=Number(player:GetProperty(ALLY_UPGRADE271_ATTACHED_PROPERTY),0)==1;
 if baseAttached and upgradeAttached and upgrade271Attached then return; end
 local base={
  "LOTM_RESCUE_ALLY_BANNER_COMBAT",
  "LOTM_RESCUE_ALLY_CROWN_INNER","LOTM_RESCUE_ALLY_CROWN_OUTER"
 };
 if not baseAttached then for _,modifierID in ipairs(base) do pcall(function() player:AttachModifierByID(modifierID); end); end end
 if baseAttached and upgradeAttached and not upgrade271Attached then
  local repair={"LOTM_RESCUE_ALLY_CROWN_COMBAT_NEUTRALIZE270","LOTM_RESCUE_ALLY_CROWN_INNER_RESTORE270","LOTM_RESCUE_ALLY_CROWN_OUTER_RESTORE270"};
  for _,modifierID in ipairs(repair) do pcall(function() player:AttachModifierByID(modifierID); end); end
 end
 player:SetProperty(ALLY_ATTACHED_PROPERTY,1); player:SetProperty(ALLY_UPGRADE_ATTACHED_PROPERTY,1);
 player:SetProperty(ALLY_UPGRADE271_ATTACHED_PROPERTY,1);
end
local function ReconcileHolder(player)
 EnsureHumanInfrastructure(player);
 local changed=false;
 for index,artifactType in ipairs(ARTIFACTS) do
  local positive,negative=Polarity(player,artifactType);
  -- Rescue owns the active namespace. Retire every ordinary polarity lease,
  -- including those serialized by an older save.
  changed=SetResource(player,OrdinaryResourceType(index,true),false) or changed;
  changed=SetResource(player,OrdinaryResourceType(index,false),false) or changed;
  changed=SetResource(player,ResourceType(index,true),positive) or changed;
  changed=SetResource(player,ResourceType(index,false),negative) or changed;
 end
 if Number(player:GetProperty(MIGRATION_PROPERTY),0)~=1 then
  player:SetProperty(MIGRATION_PROPERTY,1);
  Log("old-save lease migration player="..player:GetID());
 end
 return changed;
end
local function PairKey(firstID,secondID)
 local low=math.min(firstID,secondID); local high=math.max(firstID,secondID);
 return "LOTM_RESCUE_PHASE8_PERMANENT_ALLIANCE:"..low..":"..high;
end
local function Allied(first,secondID)
 local diplomacy=first~=nil and first:GetDiplomacy() or nil;
 local official=false;
 if diplomacy~=nil and diplomacy.HasAllied~=nil then
  local ok,result=pcall(function() return diplomacy:HasAllied(secondID); end); official=ok and result==true;
 end
 return official or Number(Game.GetProperty(PairKey(first:GetID(),secondID)),0)==1;
end
local function HumanHolders()
 local result={};
 for _,player in ipairs(PlayerManager.GetAliveMajors()) do if player:IsHuman() then result[#result+1]=player; end end
 table.sort(result,function(a,b) return a:GetID()<b:GetID(); end); return result;
end
local function IsWeatherTarget(unit)
 if unit==nil then return false; end
 local roaming=LOTM_WORLD_Monsters~=nil and LOTM_WORLD_Monsters.IsMonster~=nil and LOTM_WORLD_Monsters.IsMonster(unit);
 return roaming or Number(unit:GetProperty("LOTM_RESCUE_CENTER_MONSTER"),0)==1;
end
local function ApplyWeatherAbility(unit,desired)
 if not IsWeatherTarget(unit) then return false; end
 local ability=unit:GetAbility(); if ability==nil or GameInfo.UnitAbilities[WEATHER_ABILITY]==nil then return false; end
 local current=ability:GetAbilityCount(WEATHER_ABILITY) or 0; local wanted=desired and 1 or 0;
 if current~=wanted then ability:ChangeAbilityCount(WEATHER_ABILITY,wanted-current); return true; end
 return false;
end
local function ReconcileMonsters(weatherActive)
 local changed=0; local targets=0;
 for _,playerID in ipairs(PlayerManager.GetAliveIDs()) do
  local player=Players[playerID];
  if player~=nil then for _,unit in player:GetUnits():Members() do
   if IsWeatherTarget(unit) then targets=targets+1; if ApplyWeatherAbility(unit,weatherActive) then changed=changed+1; end end
  end end
 end
 return changed,targets;
end
local function ReconcileGlobal(reason)
 if not Active() then return; end
 local holders=HumanHolders(); local weather=false; local frenzy=false; local crown=false; local bannerAllies=0; local crownAllies=0;
 for _,holder in ipairs(holders) do
  ReconcileHolder(holder);
  weather=weather or PositiveActive(holder,"GREATWORK_LOTM_RP_DISASTER_WEATHER");
  frenzy=frenzy or PositiveActive(holder,"GREATWORK_LOTM_BE_FRENZY_SCEPTER");
  crown=crown or PositiveActive(holder,"GREATWORK_LOTM_RP_CONQUEROR_CROWN");
 end
 local oldWeather=Number(Game.GetProperty("LOTM_RESCUE_ARTIFACT_WEATHER_ACTIVE"),0)==1;
 Game.SetProperty("LOTM_RESCUE_ARTIFACT_WEATHER_ACTIVE",weather and 1 or 0);
 Game.SetProperty("LOTM_RESCUE_ARTIFACT_FRENZY_ACTIVE",frenzy and 1 or 0);
 local reconcileVersion=Number(Game.GetProperty(WEATHER_RECONCILE_PROPERTY),0);
 local mustReconcile=oldWeather~=weather or reconcileVersion<WEATHER_RECONCILE_VERSION;
 local monsterChanges=0; local monsterTargets=-1;
 if mustReconcile then monsterChanges,monsterTargets=ReconcileMonsters(weather); end
 if mustReconcile then Game.SetProperty(WEATHER_RECONCILE_PROPERTY,WEATHER_RECONCILE_VERSION); end
 for _,ai in ipairs(PlayerManager.GetAliveMajors()) do
  if not ai:IsHuman() then
   EnsureAllyInfrastructure(ai);
   local banner=false; local crown=false;
   for _,holder in ipairs(holders) do if Allied(holder,ai:GetID()) then
    banner=banner or PositiveActive(holder,"GREATWORK_LOTM_RP_IRONBLOOD_BANNER");
    crown=crown or PositiveActive(holder,"GREATWORK_LOTM_RP_CONQUEROR_CROWN");
   end end
   SetResource(ai,"RESOURCE_LOTM_RESCUE_ALLY_BANNER",banner);
   SetResource(ai,"RESOURCE_LOTM_RESCUE_ALLY_CROWN",crown);
   if banner then bannerAllies=bannerAllies+1; end
   if crown then crownAllies=crownAllies+1; end
  end
 end
 if LOTM_RESCUE_Phase5~=nil and LOTM_RESCUE_Phase5.RefreshState~=nil then LOTM_RESCUE_Phase5.RefreshState(); end
 Log("reconciled reason="..tostring(reason).." holders="..#holders.." weather="..tostring(weather).." crown="..tostring(crown).." frenzy="..tostring(frenzy).." bannerAllies="..bannerAllies.." crownAllies="..crownAllies.." monsterTargets="..monsterTargets.." monsterChanges="..monsterChanges);
end

-- Public hook used by the monster creation/reconciliation chain.
function LOTM_RESCUE_Artifacts.WeatherActive()
 return Active() and Number(Game.GetProperty("LOTM_RESCUE_ARTIFACT_WEATHER_ACTIVE"),0)==1;
end
function LOTM_RESCUE_Artifacts.ApplyMonsterWeather(unit)
 return ApplyWeatherAbility(unit,LOTM_RESCUE_Artifacts.WeatherActive());
end

local function PlunderReward(player,unit,plunderType,baseAmount)
 -- PlunderAmount is already the native operation reward for the current
 -- ruleset. Applying game-speed CostMultiplier here halved Online rewards a
 -- second time (latest runtime evidence: base 25 became 26 instead of 50).
 local doubled=math.max(0,math.floor(Number(baseAmount,0)+0.5))*2; local amount=doubled;
 if amount<=0 then return 0,doubled; end
 if plunderType=="PLUNDER_GOLD" then player:GetTreasury():ChangeGoldBalance(amount);
 elseif plunderType=="PLUNDER_FAITH" then local religion=player:GetReligion(); if religion~=nil then religion:ChangeFaithBalance(amount); end
 elseif plunderType=="PLUNDER_SCIENCE" then local techs=player:GetTechs(); if techs~=nil and techs.ChangeCurrentResearchProgress~=nil then techs:ChangeCurrentResearchProgress(amount); end
 elseif plunderType=="PLUNDER_CULTURE" then local culture=player:GetCulture(); if culture~=nil and culture.ChangeCurrentCulturalProgress~=nil then culture:ChangeCurrentCulturalProgress(amount); end
 elseif plunderType=="PLUNDER_HEAL" then local damage=unit:GetDamage() or 0; amount=math.min(damage,amount); unit:ChangeDamage(-amount);
 else return 0,doubled; end
 return amount,doubled;
end
local function ShowPlunderWorldText(playerID,plunderType,amount,x,y)
 if amount<=0 or Game.AddWorldViewText==nil then return; end
 local styles={
  PLUNDER_GOLD={"COLOR_FLOAT_GOLD","ICON_Gold"},
  PLUNDER_FAITH={"COLOR_FLOAT_FAITH","ICON_Faith"},
  PLUNDER_SCIENCE={"COLOR_FLOAT_SCIENCE","ICON_Science"},
  PLUNDER_CULTURE={"COLOR_FLOAT_CULTURE","ICON_Culture"},
  PLUNDER_HEAL={"COLOR_FLOAT_FOOD","ICON_Health"}
 };
 local style=styles[plunderType]; if style==nil then return; end
 Game.AddWorldViewText(playerID,"["..style[1].."]+"..tostring(amount).." ["..style[2].."][ENDCOLOR]",x,y);
end
local function MoveCost(unit)
 local cost=Number(GlobalParameters.PILLAGE_MOVEMENT_COST,3)*60;
 local moves=unit:GetMovesRemaining() or 0; unit:ChangeMovesRemaining(-math.min(moves,cost));
end
local function CommandOwnPillage(ownerID,unitID,parameters)
 if not Active() then return false; end
 local player=Human(ownerID); local unit=player~=nil and player:GetUnits():FindID(unitID) or nil;
 if player==nil or unit==nil or unit:IsDead() or unit:IsDelayedDeath() or not player:IsTurnActive() then return false; end
 if not PositiveActive(player,"GREATWORK_LOTM_RP_DISASTER_EMBER") then Log("own pillage rejected reason=EMBER_INACTIVE player="..ownerID); return false; end
 if (unit:GetCombat() or 0)<=0 and (unit:GetRangedCombat() or 0)<=0 and (unit:GetBombardCombat() or 0)<=0 then return false; end
 if (unit:GetMovesRemaining() or 0)<=0 then return false; end
 local x=Number(parameters[UnitCommandTypes.PARAM_X],-1); local y=Number(parameters[UnitCommandTypes.PARAM_Y],-1);
 local plot=Map.GetPlot(x,y); if plot==nil or unit:GetX()~=x or unit:GetY()~=y or plot:GetOwner()~=ownerID then return false; end
 local key="LOTM_RESCUE_OWN_PILLAGE:"..ownerID..":"..unitID..":"..plot:GetIndex();
 if Number(Game.GetProperty(key),-1)==Game.GetCurrentGameTurn() then return false; end
 local plunderType=nil; local baseAmount=0; local layer="NONE"; local changed=false;
 local improvement=GameInfo.Improvements[plot:GetImprovementType()];
 if improvement~=nil and not plot:IsImprovementPillaged() and improvement.PlunderType~="NO_PLUNDER" and improvement.PlunderType~="PLUNDER_NONE" then
  plunderType=improvement.PlunderType; baseAmount=improvement.PlunderAmount; layer="IMPROVEMENT";
  local ok=pcall(function() ImprovementBuilder.SetImprovementPillaged(plot,true); end); changed=ok and plot:IsImprovementPillaged();
 else
  local district=CityManager.GetDistrictAt(x,y); local districtInfo=district~=nil and GameInfo.Districts[district:GetType()] or nil;
  if district~=nil and districtInfo~=nil and districtInfo.PlunderType~="NO_PLUNDER" and districtInfo.PlunderType~="PLUNDER_NONE" then
   plunderType=districtInfo.PlunderType; baseAmount=districtInfo.PlunderAmount;
   local city=Cities.GetPlotPurchaseCity(plot); local buildings=city~=nil and city:GetBuildings() or nil;
   if buildings~=nil then
    local candidates={}; for building in GameInfo.Buildings() do
     if building.PrereqDistrict==districtInfo.DistrictType and buildings:HasBuilding(building.Index) and not buildings:IsPillaged(building.Index) and Number(building.Pillage,1)~=0 then candidates[#candidates+1]=building; end
    end
    table.sort(candidates,function(a,b) return a.Index<b.Index; end);
    if #candidates>0 then
     local target=candidates[1]; local ok=pcall(function() buildings:SetPillaged(target.Index,true); end);
     changed=ok and buildings:IsPillaged(target.Index); layer="BUILDING:"..target.BuildingType;
    elseif not district:IsPillaged() then local ok=pcall(function() district:SetPillaged(true); end); changed=ok and district:IsPillaged(); layer="DISTRICT"; end
   end
  end
 end
 if not changed then Log("own pillage rejected reason=NO_VALID_LAYER player="..ownerID.." plot="..plot:GetIndex()); return false; end
 Game.SetProperty(key,Game.GetCurrentGameTurn()); MoveCost(unit);
 local reward,doubled=PlunderReward(player,unit,plunderType,baseAmount);
 ShowPlunderWorldText(ownerID,plunderType,reward,x,y);
 Log("own pillage committed player="..ownerID.." unit="..unitID.." plot="..plot:GetIndex().." layer="..layer.." plunder="..tostring(plunderType).." base="..tostring(baseAmount).." double="..doubled.." reward="..reward);
 return true;
end

local function OnPlayerTurn(playerID,isFirstTime)
 if isFirstTime==false or Human(playerID)==nil then return; end ReconcileGlobal("PLAYER_TURN:"..playerID);
end
local function OnArtifactCommand() ReconcileGlobal("ARTIFACT_COMMAND"); end
local function OnDiplomacy(firstID,secondID) ReconcileGlobal("DIPLOMACY:"..tostring(firstID)..":"..tostring(secondID)); end

GameEvents.LOTM_RESCUE_Command_OwnPillage.Add(CommandOwnPillage);
GameEvents.LOTM_PP_Command_Artifact.Add(OnArtifactCommand);
Events.PlayerTurnActivated.Add(OnPlayerTurn);
Events.DiplomacyDeclareWar.Add(OnDiplomacy); Events.DiplomacyMakePeace.Add(OnDiplomacy);
if Events.AllianceChanged~=nil then Events.AllianceChanged.Add(OnDiplomacy); end
ReconcileGlobal("INITIALIZE");
Log("initialized version="..VERSION.." separatedLeases=21 ownPillage=synchronized ally=HasAlliedOrPermanentPair");
-- END RC241 MODULE: Scripts/LOTM_RESCUE_Artifacts.lua
end;

m_mp241Loaders["LOTM_RESCUE_Difficulty"] = function()
-- BEGIN POST_RC241_DELTA MODULE: Scripts/LOTM_RESCUE_Difficulty.lua
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("MP.LOTM_RESCUE_Difficulty","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"MP.LOTM_RESCUE_Difficulty","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"MP.LOTM_RESCUE_Difficulty","GameEvents");
-- END RC342 STARTUP TRACE

-- Redemption-mode difficulty authority. UI submits one synchronized choice;
-- Gameplay owns the immutable global state and all numeric scaling.
LOTM_RESCUE_Difficulty=LOTM_RESCUE_Difficulty or {};

local VERSION=3;
local COMMAND="LOTM_RESCUE_Command_SelectDifficulty";
local DEFAULT_CHOICE="MADNESS";
local PLAYER_CHOICE_PROPERTY="LOTM_RESCUE_DIFFICULTY_SAVED_CHOICE";
local CHOICES={
 NORMAL={SpawnPercent=50,CapPercent=50,AICombatCap=10},
 HARD={SpawnPercent=70,CapPercent=70,AICombatCap=12},
 MADNESS={SpawnPercent=100,CapPercent=100,AICombatCap=15}
};
local DIRECT_SPAWN={NORMAL=2,HARD=4,MADNESS=6};

local function Log(message) print("[LOTM_RESCUE][Difficulty] "..tostring(message)); end
local function Active() return tonumber(Game.GetProperty("LOTM_RESCUE_MODE") or 0)==1; end

local function HumanChooserID()
 local ids={};
 for _,player in ipairs(PlayerManager.GetAliveMajors()) do
  if player:IsHuman() and player:GetCities():GetCount()>0 then ids[#ids+1]=player:GetID(); end
 end
 table.sort(ids); return ids[1] or -1;
end

local function Property(key)
 local value=Game.GetProperty(key); return value;
end

local function ValidChoice(value)
 local choice=value~=nil and tostring(value) or "";
 return CHOICES[choice]~=nil and choice or nil;
end

local function InferNumericChoice()
 local spawn=tonumber(Property("LOTM_RESCUE_DIFFICULTY_SPAWN_PERCENT"));
 local cap=tonumber(Property("LOTM_RESCUE_DIFFICULTY_CAP_PERCENT"));
 local ai=tonumber(Property("LOTM_RESCUE_DIFFICULTY_AI_COMBAT_CAP"));
 for _,choice in ipairs({"NORMAL","HARD","MADNESS"}) do
  local data=CHOICES[choice];
  if spawn==data.SpawnPercent and cap==data.CapPercent and ai==data.AICombatCap then return choice; end
 end
 return nil;
end

local function SavedPlayerChoice()
 local chooser=tonumber(Property("LOTM_RESCUE_DIFFICULTY_CHOOSER")) or HumanChooserID();
 local player=chooser>=0 and Players[chooser] or nil;
 local choice=ValidChoice(player~=nil and player:GetProperty(PLAYER_CHOICE_PROPERTY) or nil);
 if choice~=nil then return choice,chooser; end
 chooser=HumanChooserID(); player=chooser>=0 and Players[chooser] or nil;
 return ValidChoice(player~=nil and player:GetProperty(PLAYER_CHOICE_PROPERTY) or nil),chooser;
end

local function ResolveChoice()
 local choice=ValidChoice(Property("LOTM_RESCUE_DIFFICULTY"));
 if choice~=nil then return choice,"GAME_CHOICE"; end
 choice=ValidChoice(Property("LOTM_RESCUE_DIFFICULTY_PERSISTED_CHOICE"));
 if choice~=nil then return choice,"GAME_PERSISTED"; end
 local chooser=-1; choice,chooser=SavedPlayerChoice();
 if choice~=nil then return choice,"PLAYER_PERSISTED:"..tostring(chooser); end
 choice=InferNumericChoice();
 if choice~=nil then return choice,"NUMERIC_SNAPSHOT"; end
 return DEFAULT_CHOICE,"SAFE_DEFAULT";
end

local function ChoiceData()
 local choice=ResolveChoice();
 return choice,CHOICES[choice] or CHOICES[DEFAULT_CHOICE];
end

function LOTM_RESCUE_Difficulty.Choice() local choice=ChoiceData(); return choice; end
function LOTM_RESCUE_Difficulty.SpawnPercent() local _,data=ChoiceData(); return data.SpawnPercent; end
function LOTM_RESCUE_Difficulty.CapPercent() local _,data=ChoiceData(); return data.CapPercent; end
function LOTM_RESCUE_Difficulty.AICombatCap() local _,data=ChoiceData(); return data.AICombatCap; end
function LOTM_RESCUE_Difficulty.DirectSpawnBase()
 local choice=ChoiceData(); return DIRECT_SPAWN[choice] or DIRECT_SPAWN[DEFAULT_CHOICE];
end
function LOTM_RESCUE_Difficulty.Scale(base,percent)
 return math.max(1,math.floor((tonumber(base) or 0)*(tonumber(percent) or 100)/100));
end

local function Publish(choice,data,chooser)
 Game.SetProperty("LOTM_RESCUE_DIFFICULTY",choice);
 Game.SetProperty("LOTM_RESCUE_DIFFICULTY_PERSISTED_CHOICE",choice);
 Game.SetProperty("LOTM_RESCUE_DIFFICULTY_DECIDED",1);
 Game.SetProperty("LOTM_RESCUE_DIFFICULTY_CHOOSER",chooser);
 Game.SetProperty("LOTM_RESCUE_DIFFICULTY_SPAWN_PERCENT",data.SpawnPercent);
 Game.SetProperty("LOTM_RESCUE_DIFFICULTY_CAP_PERCENT",data.CapPercent);
 Game.SetProperty("LOTM_RESCUE_DIFFICULTY_AI_COMBAT_CAP",data.AICombatCap);
 Game.SetProperty("LOTM_RESCUE_DIFFICULTY_DIRECT_SPAWN_BASE",DIRECT_SPAWN[choice]);
 Game.SetProperty("LOTM_RESCUE_DIFFICULTY_VERSION",VERSION);
 local player=chooser~=nil and chooser>=0 and Players[chooser] or nil;
 if player~=nil and player:IsHuman() then player:SetProperty(PLAYER_CHOICE_PROPERTY,choice); end
end

function LOTM_RESCUE_Difficulty.RestorePersistentChoice()
 if not Active() then return false; end
 local choice,source=ResolveChoice(); local data=CHOICES[choice];
 local decided=tonumber(Property("LOTM_RESCUE_DIFFICULTY_DECIDED") or 0)==1;
 local chooser=tonumber(Property("LOTM_RESCUE_DIFFICULTY_CHOOSER")) or HumanChooserID();
 -- Older builds wrote NORMAL/HARD and their numeric snapshots before the
 -- DECIDED marker was introduced.  Recover those explicit non-default
 -- choices instead of silently replacing them with the MADNESS default.
 local rawChoice=ValidChoice(Property("LOTM_RESCUE_DIFFICULTY"));
 local persistedChoice=ValidChoice(Property("LOTM_RESCUE_DIFFICULTY_PERSISTED_CHOICE"));
 local playerChoice,playerChooser=SavedPlayerChoice();
 local numericChoice=InferNumericChoice();
 local recoveredChoice=persistedChoice or playerChoice
  or ((rawChoice~=nil and rawChoice~=DEFAULT_CHOICE) and rawChoice or nil)
  or ((numericChoice~=nil and numericChoice~=DEFAULT_CHOICE) and numericChoice or nil);
 if decided or recoveredChoice~=nil then
  if not decided and recoveredChoice~=nil then
   choice=recoveredChoice; data=CHOICES[choice];
   if playerChoice~=nil and playerChooser>=0 then chooser=playerChooser; end
   Log("recovered legacy explicit choice="..choice.." source="..source);
  end
  Publish(choice,data,chooser);
  Log("restored choice="..choice.." source="..source.." chooser="..tostring(chooser)
   .." spawnPercent="..data.SpawnPercent.." capPercent="..data.CapPercent
   .." directSpawnBase="..DIRECT_SPAWN[choice].." aiCombatCap="..data.AICombatCap);
 else
  -- Before the chooser confirms a difficulty, publish only the safe runtime
  -- default.  Keeping DECIDED unset preserves the choice popup.
  Game.SetProperty("LOTM_RESCUE_DIFFICULTY",DEFAULT_CHOICE);
  Game.SetProperty("LOTM_RESCUE_DIFFICULTY_SPAWN_PERCENT",CHOICES[DEFAULT_CHOICE].SpawnPercent);
  Game.SetProperty("LOTM_RESCUE_DIFFICULTY_CAP_PERCENT",CHOICES[DEFAULT_CHOICE].CapPercent);
  Game.SetProperty("LOTM_RESCUE_DIFFICULTY_AI_COMBAT_CAP",CHOICES[DEFAULT_CHOICE].AICombatCap);
  Game.SetProperty("LOTM_RESCUE_DIFFICULTY_DIRECT_SPAWN_BASE",DIRECT_SPAWN[DEFAULT_CHOICE]);
  Game.SetProperty("LOTM_RESCUE_DIFFICULTY_VERSION",VERSION);
  Log("initialized undecided safeDefault="..DEFAULT_CHOICE.." chooser="..tostring(chooser));
 end
 return true;
end

local function OnSelect(playerID,parameters)
 local choice=parameters~=nil and tostring(parameters.Choice or "") or "";
 local data=CHOICES[choice]; local player=Players[playerID]; local chooser=HumanChooserID();
 if not Active() or data==nil or player==nil or not player:IsHuman() or not player:IsAlive()
  or not player:IsMajor() or player:GetCities():GetCount()<1 or playerID~=chooser then
  Log("rejected player="..tostring(playerID).." choice="..choice.." chooser="..chooser); return;
 end
 if tonumber(Game.GetProperty("LOTM_RESCUE_DIFFICULTY_DECIDED") or 0)==1 then
  Log("rejected duplicate player="..playerID.." choice="..choice); return;
 end
 Publish(choice,data,playerID);
 Log("selected player="..playerID.." choice="..choice.." spawnPercent="..data.SpawnPercent.." capPercent="..data.CapPercent.." directSpawnBase="..DIRECT_SPAWN[choice].." aiCombatCap="..data.AICombatCap);
 if LOTM_RESCUE_Phase9~=nil and LOTM_RESCUE_Phase9.ReconcileAll~=nil then LOTM_RESCUE_Phase9.ReconcileAll(); end
end

-- The script loads before the path choice can activate Redemption mode, so the
-- synchronized command must always be registered. OnSelect remains the runtime
-- gate and rejects every request outside an active Redemption game.
GameEvents.LOTM_RESCUE_Command_SelectDifficulty.Add(OnSelect);
LOTM_MP_TurnSync.RunStartup(function() LOTM_RESCUE_Difficulty.RestorePersistentChoice(); end,"RescueDifficulty");
Log("loaded version="..VERSION.." active="..tostring(Active()).." choices=NORMAL:50/50/10/direct2,HARD:70/70/12/direct4,MADNESS:100/100/15/direct6 defaultUntilSelected=MADNESS persistence=game+player+numeric chooser=lowestHumanWithCity");
-- END POST_RC241_DELTA MODULE: Scripts/LOTM_RESCUE_Difficulty.lua
end;

m_mp241Loaders["LOTM_RESCUE_DirectMonsters"] = function()
-- BEGIN POST_RC241_NEW MODULE: Scripts/LOTM_RESCUE_DirectMonsters.lua
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("MP.LOTM_RESCUE_DirectMonsters","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"MP.LOTM_RESCUE_DirectMonsters","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"MP.LOTM_RESCUE_DirectMonsters","GameEvents");
-- END RC342 STARTUP TRACE

-- Rescue-only direct uncontrolled-monster stream.
--
-- This module deliberately lives outside LOTM_WORLD_Monsters.lua.  The latter
-- is the protected ordinary-mode monster implementation; direct rescue
-- refreshes only need to create the same durable monster identity and can
-- therefore remain isolated behind the rescue runtime gate.
LOTM_MP241_LoadBundledModule("LOTM_Effects");
LOTM_RESCUE_DirectMonsters = LOTM_RESCUE_DirectMonsters or {};

local VERSION = 2;
local LAST_TURN_KEY = "LOTM_RESCUE_DIRECT_MONSTER_LAST_TURN";
local LAST_ATTEMPTS_KEY = "LOTM_RESCUE_DIRECT_MONSTER_LAST_ATTEMPTS";
local LAST_SPAWNED_KEY = "LOTM_RESCUE_DIRECT_MONSTER_LAST_SPAWNED";
local LAST_PLOTS_KEY = "LOTM_RESCUE_DIRECT_MONSTER_LAST_PLOTS";
local LAST_TIERS_KEY = "LOTM_RESCUE_DIRECT_MONSTER_LAST_TIERS";
local LAST_REASON_KEY = "LOTM_RESCUE_DIRECT_MONSTER_LAST_REASON";
local MONSTER_TIER = "LOTM_WORLD_MONSTER_TIER";
local MONSTER_SERIAL = "LOTM_WORLD_MONSTER_SERIAL";
local MONSTER_SOURCE = "LOTM_WORLD_MONSTER_SOURCE_WORKSHOP";
local PERIOD_BONUS_PROPERTY = "LOTM_RESCUE_PHASE5_BIRTH_BONUS";
local EFFECT_VERSION_PROPERTY = "LOTM_WORLD_MONSTER_EFFECT_VERSION";
local CURRENT_EFFECT_VERSION = 7;
local ENGINE_PREFIX = "LOTM_WORLD_MONSTER_ENGINE:";
local ACTIVE_SERIALS_KEY = "LOTM_WORLD_MONSTER_ACTIVE_SERIALS";
local ACTIVE_INDEX_VERSION_KEY = "LOTM_WORLD_MONSTER_ACTIVE_INDEX_VERSION";
local STRENGTH_ABILITY = "ABILITY_LOTM_WORLD_MONSTER_FRENZY_STRENGTH_V2";
local TIER_STRENGTH_ABILITIES = {
    {1,"ABILITY_LOTM_WORLD_MONSTER_TIER_MID_STRENGTH"},
    {0,"ABILITY_LOTM_WORLD_MONSTER_TIER_HIGH_STRENGTH"}
};
local LEGACY_STRENGTH_ABILITY = "ABILITY_LOTM_WORLD_DYNAMIC_STRENGTH";
local LEGACY_FRENZY_ABILITY = "ABILITY_LOTM_WORLD_MONSTER_FRENZY_STRENGTH";
local MOVEMENT_ABILITIES = {
    {1,"ABILITY_LOTM_WORLD_DYNAMIC_MOVEMENT"},
    {2,"ABILITY_LOTM_WORLD_DYNAMIC_MOVEMENT_2"}
};
local RESCUE_WEATHER_ABILITY = "ABILITY_LOTM_RESCUE_WEATHER_MONSTER_DEBUFF";
local PERIOD_STRENGTH_ABILITIES = {
    {10,"ABILITY_LOTM_RESCUE_PERIOD_STRENGTH_10"},
    {20,"ABILITY_LOTM_RESCUE_PERIOD_STRENGTH_20"},
    {30,"ABILITY_LOTM_RESCUE_PERIOD_STRENGTH_30"},
    {40,"ABILITY_LOTM_RESCUE_PERIOD_STRENGTH_40"}
};
local TIER_BONUS = {[2]=15,[1]=25,[0]=35};
-- Rescue-only stream moves faster than ordinary camp units so a late-game
-- direct spawn can actually reach an AI city before the next refresh cycle.
local TIER_MOVES = {[2]=4,[1]=5,[0]=6};
local TIER_NAME = {
    [2]="LOC_LOTM_WORLD_MONSTER_LOW_NAME",
    [1]="LOC_LOTM_WORLD_MONSTER_MID_NAME",
    [0]="LOC_LOTM_WORLD_MONSTER_HIGH_NAME"
};
local MIN_CITY_DISTANCE = 3;
-- Candidate enumeration is the hottest part of the direct stream on large
-- maps.  A spawn turn can ask for the fog-safe list and then the visible
-- fallback list; cache each list for that turn and only retain plot indices
-- (the caller is free to remove entries from its returned table).
local candidateCacheTurn=-1;
local candidateCache={};

local function Log(message)
    print("[LOTM_RESCUE][DirectMonsters] "..tostring(message));
end

local function Number(value,default)
    if value==nil then return default; end
    return tonumber(value) or default;
end

local function Active()
    return Number(Game.GetProperty("LOTM_RESCUE_MODE"),0)==1;
end

local function NumberGameProperty(key,default)
    if LOTM_WORLD_State~=nil and LOTM_WORLD_State.NumberGameProperty~=nil then
        return LOTM_WORLD_State.NumberGameProperty(key,default);
    end
    return Number(Game.GetProperty(key),default);
end

local function BarbarianID()
    for _,player in ipairs(PlayerManager.GetAliveBarbarians() or {}) do
        return player:GetID();
    end
    return -1;
end

local function EngineKey(ownerID,unitID)
    return ENGINE_PREFIX..tostring(ownerID)..":"..tostring(unitID);
end

local function MetaKey(serial,suffix)
    return "LOTM_WORLD_MONSTER:"..tostring(serial)..":"..suffix;
end

local function ActiveSerials()
    local result={}; local seen={};
    for token in string.gmatch(tostring(Game.GetProperty(ACTIVE_SERIALS_KEY) or ""),"[^,]+") do
        local serial=tonumber(token);
        if serial~=nil and serial>0 and not seen[serial] then
            seen[serial]=true; result[#result+1]=serial;
        end
    end
    table.sort(result);
    return result;
end

local function SaveActiveSerials(serials)
    local values={};
    for _,serial in ipairs(serials) do values[#values+1]=tostring(serial); end
    local serialized=table.concat(values,",");
    if tostring(Game.GetProperty(ACTIVE_SERIALS_KEY) or "")~=serialized then Game.SetProperty(ACTIVE_SERIALS_KEY,serialized); end
end

local function RegisterActiveSerial(serial)
    local normalized=tonumber(serial);
    if normalized==nil or normalized<=0 then return; end
    local serials=ActiveSerials();
    for _,value in ipairs(serials) do
        if value==normalized then return; end
    end
    serials[#serials+1]=normalized;
    table.sort(serials);
    SaveActiveSerials(serials);
end

local function ApplyAbilityCount(unit,abilityType,desired)
    if GameInfo.UnitAbilities[abilityType]==nil then return desired==0; end
    local ability=unit~=nil and unit:GetAbility() or nil;
    if ability==nil then return false; end
    LOTM_Effects.SetAbilityCount(ability,abilityType,desired);
    return (ability:GetAbilityCount(abilityType) or 0)==desired;
end

local function ApplyMonsterAbilities(unit,tier,moveDelta,periodBonus)
    if Number(unit:GetProperty(EFFECT_VERSION_PROPERTY),0)<CURRENT_EFFECT_VERSION then
        local ability=unit:GetAbility();
        if ability~=nil then
            local rebuild={
                LEGACY_STRENGTH_ABILITY,LEGACY_FRENZY_ABILITY,STRENGTH_ABILITY,
                TIER_STRENGTH_ABILITIES[1][2],TIER_STRENGTH_ABILITIES[2][2],
                MOVEMENT_ABILITIES[1][2],MOVEMENT_ABILITIES[2][2],
                PERIOD_STRENGTH_ABILITIES[1][2],PERIOD_STRENGTH_ABILITIES[2][2],
                PERIOD_STRENGTH_ABILITIES[3][2],PERIOD_STRENGTH_ABILITIES[4][2],
                RESCUE_WEATHER_ABILITY
            };
            for _,abilityType in ipairs(rebuild) do
                if GameInfo.UnitAbilities[abilityType]~=nil then
                    LOTM_Effects.SetAbilityCount(ability,abilityType,0);
                end
            end
        end
        unit:SetProperty("LOTM_WORLD_MONSTER_LOCKED_TARGET_KIND",nil);
        unit:SetProperty("LOTM_WORLD_MONSTER_LOCKED_TARGET_OWNER",nil);
        unit:SetProperty("LOTM_WORLD_MONSTER_LOCKED_TARGET_ID",nil);
        unit:SetProperty(EFFECT_VERSION_PROPERTY,CURRENT_EFFECT_VERSION);
    end
    ApplyAbilityCount(unit,STRENGTH_ABILITY,1);
    for _,entry in ipairs(TIER_STRENGTH_ABILITIES) do
        ApplyAbilityCount(unit,entry[2],entry[1]==tier and 1 or 0);
    end
    for _,entry in ipairs(MOVEMENT_ABILITIES) do
        ApplyAbilityCount(unit,entry[2],entry[1]==moveDelta and 1 or 0);
    end
    for _,entry in ipairs(PERIOD_STRENGTH_ABILITIES) do
        ApplyAbilityCount(unit,entry[2],entry[1]==periodBonus and 1 or 0);
    end
    local weather=Number(Game.GetProperty("LOTM_RESCUE_ARTIFACT_WEATHER_ACTIVE"),0)==1;
    ApplyAbilityCount(unit,RESCUE_WEATHER_ABILITY,Active() and weather and 1 or 0);
    if LOTM_RESCUE_RuntimeEvents~=nil then LOTM_RESCUE_RuntimeEvents.ApplyEarlySeal(unit); end
end

local function ReservedIndices()
    local result={};
    for _,zone in ipairs({"CENTER","FOOL","NIGHT","STORM"}) do
        local csv=tostring(Game.GetProperty("LOTM_RESCUE_"..zone.."_TERRITORY") or "");
        for value in string.gmatch(csv,"[^,]+") do
            local index=tonumber(value);
            if index~=nil and index>=0 then result[index]=true; end
        end
    end
    return result;
end

local function MajorVisibilities()
    local result={};
    for _,player in ipairs(PlayerManager.GetAliveMajors() or {}) do
        local visibility=PlayersVisibility[player:GetID()];
        if visibility~=nil then result[#result+1]=visibility; end
    end
    return result;
end

local function HumanVisibilities()
    local result={};
    for _,player in ipairs(PlayerManager.GetAliveMajors() or {}) do
        if player:IsHuman() then
            local visibility=PlayersVisibility[player:GetID()];
            if visibility~=nil then result[#result+1]=visibility; end
        end
    end
    return result;
end

local function VisibleToAnyMajor(plotIndex,visibilities)
    for _,visibility in ipairs(visibilities) do
        if visibility:IsVisible(plotIndex) then return true; end
    end
    return false;
end

local function CityIndices()
    local result={};
    for _,player in ipairs(PlayerManager.GetAliveMajors() or {}) do
        for _,city in player:GetCities():Members() do
            result[#result+1]=Map.GetPlot(city:GetX(),city:GetY()):GetIndex();
        end
    end
    for _,player in ipairs(PlayerManager.GetAliveMinors() or {}) do
        for _,city in player:GetCities():Members() do
            result[#result+1]=Map.GetPlot(city:GetX(),city:GetY()):GetIndex();
        end
    end
    return result;
end

local function FarEnoughFromCities(plotIndex,cities)
    for _,cityIndex in ipairs(cities) do
        if Map.GetPlotDistance(plotIndex,cityIndex)<MIN_CITY_DISTANCE then return false; end
    end
    return true;
end

local function Candidates(allowHumanVisible)
    local turn=Game.GetCurrentGameTurn();
    local cacheKey=allowHumanVisible==true and "VISIBLE" or "FOG_SAFE";
    if candidateCacheTurn==turn and candidateCache[cacheKey]~=nil then
        local cached={};
        for _,index in ipairs(candidateCache[cacheKey]) do
            local plot=Map.GetPlotByIndex(index); if plot~=nil then cached[#cached+1]=plot; end
        end
        return cached;
    end
    local result={};
    local cities=CityIndices();
    local reserved=ReservedIndices();
    local aiCities={};
    for _,player in ipairs(PlayerManager.GetAliveMajors() or {}) do
        if not player:IsHuman() then
            for _,city in player:GetCities():Members() do
                aiCities[#aiCities+1]=Map.GetPlot(city:GetX(),city:GetY()):GetIndex();
            end
        end
    end
    -- Keep only a bounded nearest-AI window while scanning.  The old code
    -- materialized every legal plot and then sorted it with a distance
    -- comparator that recomputed distance to every AI city repeatedly.  That
    -- became an O(N log N * cities) end-of-turn spike on large maps.
    local buckets={};
    local maxDistance=0;
    -- Do not block a spawn merely because an AI has already revealed the plot:
    -- that made most near-city candidates ineligible and left monsters deep in
    -- empty wilderness.  Human fog-of-war is still respected to avoid visible
    -- pop-in on the player's screen.
    local visibilities=HumanVisibilities();
    for index=0,Map.GetPlotCount()-1 do
        local plot=Map.GetPlotByIndex(index);
        if plot~=nil and not plot:IsWater() and not plot:IsImpassable()
            and plot:GetOwner()==-1 and not plot:IsCity()
            and plot:GetDistrictType()==-1 and plot:GetImprovementType()==-1
            and plot:GetUnitCount()==0 and not reserved[index]
            and (allowHumanVisible==true or not VisibleToAnyMajor(index,visibilities))
            and FarEnoughFromCities(index,cities) then
            if #aiCities==0 then
                result[#result+1]=plot;
            else
                local nearest=0x7fffffff;
                for _,cityIndex in ipairs(aiCities) do
                    local distance=Map.GetPlotDistance(index,cityIndex);
                    if distance<nearest then nearest=distance; end
                end
                local bucket=buckets[nearest];
                if bucket==nil then bucket={}; buckets[nearest]=bucket; end
                bucket[#bucket+1]=plot;
                if nearest<0x7fffffff and nearest>maxDistance then maxDistance=nearest; end
            end
        end
    end
    local limit=math.max(12,NumberGameProperty("LOTM_RESCUE_DIRECT_MONSTER_CANDIDATE_WINDOW",48));
    if #aiCities==0 then
        -- No AI cities yet: preserve the deterministic map-order fallback.
        if #result>limit then
            while #result>limit do table.remove(result); end
        end
    else
        -- Distances are bounded on a Civ VI map, so walking integer buckets
        -- avoids a second sort and still keeps pressure adjacent to AI cities.
        for distance=0,maxDistance do
            local bucket=buckets[distance];
            if bucket~=nil then
                for _,plot in ipairs(bucket) do
                    result[#result+1]=plot;
                    if #result>=limit then return result; end
                end
            end
        end
    end
    local indices={};
    for _,plot in ipairs(result) do indices[#indices+1]=plot:GetIndex(); end
    if candidateCacheTurn~=turn then candidateCacheTurn=turn; candidateCache={}; end
    candidateCache[cacheKey]=indices;
    return result;
end

local function PickTier(worldTurn,slot,period)
    local low,mid,high=60,30,10;
    if LOTM_RESCUE_Phase5~=nil and LOTM_RESCUE_Phase5.WorkshopLevelChances~=nil then
        low,mid,high=LOTM_RESCUE_Phase5.WorkshopLevelChances(period);
    end
    local roll=LOTM_WORLD_State.Random(100,
        "direct monster tier turn="..tostring(worldTurn)..":slot="..tostring(slot));
    if roll<low then return 2,roll; end
    if roll<low+mid then return 1,roll; end
    return 0,roll;
end

local function SpawnOne(plot,worldTurn,slot,period,batch)
    local ownerID=BarbarianID();
    if ownerID<0 then return false,"NO_BARBARIAN_PLAYER"; end
    if LOTM_WORLD_Barbarians==nil or LOTM_WORLD_Barbarians.ResolveMeleeBaseline==nil then
        return false,"NO_BASELINE_API";
    end
    local baseline=batch~=nil and batch.Baseline or LOTM_WORLD_Barbarians.ResolveMeleeBaseline(ownerID);
    if baseline==nil then return false,"NO_BASELINE"; end
    local tier,roll=PickTier(worldTurn,slot,period);
    -- UnitAddedToMap is a local publication.  In single-player the workshop
    -- callback can run synchronously inside InitUnit and would otherwise
    -- treat this as an ordinary barbarian unit and remove it before its
    -- durable monster properties are written.  Temporarily use the existing
    -- protected monster creation sentinel; network callbacks are additionally
    -- marked filtered below once the identity is committed.
    local previousCreating=nil;
    local patchedCreating=false;
    if LOTM_WORLD_Monsters~=nil and LOTM_WORLD_Monsters.IsCreating~=nil then
        previousCreating=LOTM_WORLD_Monsters.IsCreating;
        LOTM_WORLD_Monsters.IsCreating=function() return true; end;
        patchedCreating=true;
    end
    local ok,unit=pcall(UnitManager.InitUnit,ownerID,baseline.Index,plot:GetX(),plot:GetY());
    if patchedCreating then LOTM_WORLD_Monsters.IsCreating=previousCreating; end
    if not ok or unit==nil then return false,"INIT_FAILED"; end
    local serial=NumberGameProperty("LOTM_WORLD_MONSTER_NEXT_SERIAL",0)+1;
    Game.SetProperty("LOTM_WORLD_MONSTER_NEXT_SERIAL",serial);
    local periodBonus=(LOTM_RESCUE_Phase5~=nil and LOTM_RESCUE_Phase5.BirthStrengthBonus~=nil)
        and LOTM_RESCUE_Phase5.BirthStrengthBonus() or 0;
    local unitInfo=GameInfo.Units[unit:GetType()];
    local nativeCombat=unitInfo~=nil and Number(unitInfo.Combat,baseline.Combat) or baseline.Combat;
    local nativeMoves=unitInfo~=nil and Number(unitInfo.BaseMoves,baseline.BaseMoves) or baseline.BaseMoves;
    local targetStrength=baseline.Combat+(TIER_BONUS[tier] or 15)+periodBonus;
    local moveDelta=math.max(0,(TIER_MOVES[tier] or 3)-nativeMoves);
    unit:SetProperty(MONSTER_TIER,tier);
    unit:SetProperty(MONSTER_SERIAL,serial);
    unit:SetProperty(MONSTER_SOURCE,-1);
    unit:SetProperty(PERIOD_BONUS_PROPERTY,periodBonus);
    unit:SetProperty("LOTM_WORLD_MONSTER_BASELINE",baseline.Combat);
    unit:SetProperty("LOTM_WORLD_MONSTER_UNIT_TYPE",baseline.UnitType);
    unit:SetProperty("LOTM_WORLD_MONSTER_TARGET_STRENGTH",targetStrength);
    unit:SetProperty("LOTM_WORLD_MONSTER_TARGET_MOVES",TIER_MOVES[tier] or 3);
    Game.SetProperty(MetaKey(serial,"LIVE"),1);
    Game.SetProperty(MetaKey(serial,"OWNER"),unit:GetOwner());
    Game.SetProperty(MetaKey(serial,"UNIT_ID"),unit:GetID());
    Game.SetProperty(MetaKey(serial,"TIER"),tier);
    Game.SetProperty(MetaKey(serial,"SOURCE"),-1);
    Game.SetProperty(MetaKey(serial,"BASELINE"),baseline.Combat);
    Game.SetProperty(EngineKey(unit:GetOwner(),unit:GetID()),serial);
    if batch~=nil then
        if not batch.ActiveSeen[serial] then batch.ActiveSeen[serial]=true; batch.ActiveSerials[#batch.ActiveSerials+1]=serial; end
    else
        RegisterActiveSerial(serial);
    end
    if LOTM_PP_Workshops~=nil and LOTM_PP_Workshops.MarkNetworkUnitFiltered~=nil then
        LOTM_PP_Workshops.MarkNetworkUnitFiltered(unit);
    end
    if tonumber(Game.GetProperty(ACTIVE_INDEX_VERSION_KEY) or 0)<1 then
        Game.SetProperty(ACTIVE_INDEX_VERSION_KEY,1);
    end
    ApplyMonsterAbilities(unit,tier,moveDelta,periodBonus);
    local experience=unit:GetExperience();
    if experience~=nil then
        experience:SetExperienceLocked(true);
        experience:SetVeteranName(LOTM_MP_TurnSync~=nil and LOTM_MP_TurnSync.IsNetworkGame()
            and ("LOTM_WORLD_MONSTER_"..tostring(tier))
            or Locale.Lookup(TIER_NAME[tier] or TIER_NAME[2]));
    end
    UnitManager.FinishMoves(unit);
    if batch==nil then
        local current=NumberGameProperty("LOTM_WORLD_MONSTER_LIVE_COUNT",0);
        Game.SetProperty("LOTM_WORLD_MONSTER_LIVE_COUNT",current+1);
    end
    Log("spawned serial="..serial.." tier="..tier.." plot="..plot:GetIndex()
        .." unit="..baseline.UnitType.." B="..baseline.Combat.." target="..targetStrength
        .." periodBonus="..periodBonus.." tierRoll="..roll);
    return true,"SPAWNED",serial,tier;
end

function LOTM_RESCUE_DirectMonsters.Spawn(worldTurn,requested)
    if not Active() then return 0,"INACTIVE"; end
    local turn=Number(worldTurn,0);
    if NumberGameProperty(LAST_TURN_KEY,-1)==turn then return 0,"DUPLICATE"; end
    -- Claim before scanning or drawing synchronized random values.  A save
    -- reload or duplicate callback therefore cannot create another stream.
    Game.SetProperty(LAST_TURN_KEY,turn);
    local attempts=0; local spawned=0; local plots={}; local tiers={};
    local reason="NONE";
    local cap=(LOTM_RESCUE_Phase5~=nil and LOTM_RESCUE_Phase5.MonsterGlobalCap~=nil)
        and LOTM_RESCUE_Phase5.MonsterGlobalCap() or 3;
    local live=NumberGameProperty("LOTM_WORLD_MONSTER_LIVE_COUNT",0);
    local target=math.max(0,Number(requested,0));
	local activeSerials=ActiveSerials(); local activeSeen={};
	for _,serial in ipairs(activeSerials) do activeSeen[serial]=true; end
	local batch={Baseline=LOTM_WORLD_Barbarians.ResolveMeleeBaseline(BarbarianID()),ActiveSerials=activeSerials,ActiveSeen=activeSeen};
    -- Once the persistent live cap is reached there is no legal spawn to
    -- discover.  The old path still scanned every plot, every city and every
    -- visibility object before discovering the cap in the first loop.  On
    -- large late-game maps this ran once per world turn and was the dominant
    -- end-turn spike.  Return before any map scan while preserving diagnostics.
    if target>0 and live>=cap then
        Game.SetProperty(LAST_ATTEMPTS_KEY,0);
        Game.SetProperty(LAST_SPAWNED_KEY,0);
        Game.SetProperty(LAST_PLOTS_KEY,"");
        Game.SetProperty(LAST_TIERS_KEY,"");
        Game.SetProperty(LAST_REASON_KEY,"GLOBAL_CAP");
        Log("worldTurn="..turn.." period=pending requested="..target
            .." attempts=0 spawned=0 cap="..cap.." liveBefore="..live
            .." candidatesInitial=0 reason=GLOBAL_CAP");
        return 0,"GLOBAL_CAP";
    end
    local candidates=target>0 and Candidates() or {};
    -- A late-game map is often almost completely revealed by the human
    -- player.  The old fog-only filter then returned an empty list and made
    -- the Madness stream appear to have been deleted.  Keep the no-pop-in
    -- pass first, but deterministically fall back to legal visible wilderness
    -- when it cannot satisfy even one requested spawn.  Cities, districts,
    -- improvements, occupied plots and reserved sanctuaries remain excluded.
    if target>0 and #candidates==0 then
        candidates=Candidates(true);
        if #candidates>0 then reason="VISIBLE_FALLBACK"; end
    end
    local period=(LOTM_RESCUE_Phase5~=nil and LOTM_RESCUE_Phase5.CurrentPeriod~=nil)
        and LOTM_RESCUE_Phase5.CurrentPeriod() or 1;
    for slot=1,target do
        if live+spawned>=cap then reason="GLOBAL_CAP"; break; end
        if #candidates==0 then reason="NO_LEGAL_PLOT"; break; end
        attempts=attempts+1;
        -- Draw from a bounded nearest-city window rather than the entire map;
        -- this keeps deterministic variety while ensuring the stream creates
        -- pressure that can reach AI cities in later periods.
        local candidateWindow=math.max(1,math.min(#candidates,math.max(target*4,12)));
        local choice=LOTM_WORLD_State.Random(candidateWindow,
            "direct monster plot turn="..tostring(turn)..":slot="..tostring(slot));
        local plot=table.remove(candidates,choice+1);
        local ok,spawnReason,serial,tier=SpawnOne(plot,turn,slot,period,batch);
        if ok then
            spawned=spawned+1; plots[#plots+1]=tostring(plot:GetIndex()); tiers[#tiers+1]=tostring(tier);
        else
            reason=spawnReason; break;
        end
    end
    if target==0 then reason="NOT_REQUESTED"; elseif spawned==target then reason="DONE"; end
    Game.SetProperty(LAST_ATTEMPTS_KEY,attempts);
    Game.SetProperty(LAST_SPAWNED_KEY,spawned);
    Game.SetProperty(LAST_PLOTS_KEY,table.concat(plots,","));
    Game.SetProperty(LAST_TIERS_KEY,table.concat(tiers,","));
    Game.SetProperty(LAST_REASON_KEY,reason);
	table.sort(batch.ActiveSerials); SaveActiveSerials(batch.ActiveSerials);
	Game.SetProperty("LOTM_WORLD_MONSTER_LIVE_COUNT",live+spawned);
    Log("worldTurn="..turn.." period="..period.." requested="..target
        .." attempts="..attempts.." spawned="..spawned.." cap="..cap
        .." liveBefore="..live.." candidatesInitial="..tostring(#candidates+spawned)
        .." reason="..reason.." plots="..table.concat(plots,","));
    return spawned,reason;
end

Log("loaded version="..VERSION.." rescueOnly=true directOutsideCity=true minCityDistance="..MIN_CITY_DISTANCE);
-- END POST_RC241_NEW MODULE: Scripts/LOTM_RESCUE_DirectMonsters.lua
end;

m_mp241Loaders["LOTM_RESCUE_Phase10"] = function()
-- BEGIN POST_RC241_DELTA MODULE: Scripts/LOTM_RESCUE_Phase10.lua
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("MP.LOTM_RESCUE_Phase10","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"MP.LOTM_RESCUE_Phase10","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"MP.LOTM_RESCUE_Phase10","GameEvents");
-- END RC342 STARTUP TRACE

-- Rescue Mode Phase 10: fixed descent, true gods, Divine Legion, purification
-- tiers, Outer God phases/minions, and rescue victory.
LOTM_MP241_LoadBundledModule("LOTM_Effects");
LOTM_MP241_LoadBundledModule("LOTM_RESCUE_SyncActions");
LOTM_RESCUE_Phase10=LOTM_RESCUE_Phase10 or {};

local VERSION=40;
local ALLIED_ACTION_VERSION=4;
local VISIBILITY_VERSION=2;
local BOSS_POSITION_VERSION=5;
local GOD_PROPERTY="LOTM_RESCUE_PHASE10_IS_GOD";
local CONFIRMED_DAMAGE_PROPERTY="LOTM_RESCUE_PHASE10_LAST_CONFIRMED_DAMAGE";
local LEGACY_PLUS_ABILITY="ABILITY_LOTM_RESCUE_P10_STRENGTH_PLUS";
local MINUS_ABILITY="ABILITY_LOTM_RESCUE_P10_STRENGTH_MINUS";
local DIVINE_LEGION_ABILITY="ABILITY_LOTM_RESCUE_DIVINE_LEGION";
local PLAYER_GOD_MOBILITY_ABILITY="ABILITY_LOTM_RESCUE_PLAYER_GOD_MOBILITY_30";
local PLAYER_GOD_BASE_STRENGTH=550;
local PLAYER_GOD_MOBILITY_THRESHOLD=1000;
local PLAYER_GOD_MOBILITY_BONUS=30;
local STRENGTH_BITS={1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192};
local ATTACK_BITS={1,2,4};
local BOSS_TYPE="UNIT_LOTM_RESCUE_OUTER_GOD_AVATAR";
local MINION_TYPE="UNIT_LOTM_RESCUE_OUTER_GOD_MINION";
local PATH_GODS={
 PATH_RED_PRIEST="UNIT_LOTM_RESCUE_GOD_RED_PRIEST",
 PATH_PERFECT="UNIT_LOTM_RESCUE_GOD_PERFECT",
 PATH_BLACK_EMPEROR="UNIT_LOTM_RESCUE_GOD_BLACK_EMPEROR",
 PATH_THIEF="UNIT_LOTM_RESCUE_GOD_THIEF"
};
local PERFECT_MODEL_PATHS={PATH_RED_PRIEST=true,PATH_BLACK_EMPEROR=true};
local PERFECT_MODEL_TYPE="UNIT_LOTM_RESCUE_GOD_PERFECT";
local CHURCH_GODS={
 {Role="FOOL",Type="UNIT_LOTM_RESCUE_GOD_FOOL"},
 {Role="NIGHT",Type="UNIT_LOTM_RESCUE_GOD_NIGHT"},
 {Role="STORM",Type="UNIT_LOTM_RESCUE_GOD_STORM"}
};
local m_spawnReserved={};
local m_roleUnits={};
local m_phase10Creating=false;
local m_bossIntentionalDefeat={};
local m_nativeDamageEvents={};
local m_bossCombatEvents={};
local m_nativeDamageCorrections={};
local m_pendingNetworkRemovals={};
local m_pendingNetworkRemovalKeys={};
local ResolveBossDefeat;

function LOTM_RESCUE_Phase10.IsCreating()
 return m_phase10Creating;
end

-- First public balance candidate. All values are centralized for the complete
-- post-Phase-10 test and can be tuned without changing the state machine.
local TIERS={
  {Min=0,   Max=499, Strength=999,Phases=2,Heal=20,Summon=3,Cap=10,Skills=5},
  {Min=500, Max=999, Strength=888,Phases=2,Heal=15,Summon=4,Cap=8, Skills=4},
  {Min=1000,Max=1499,Strength=777,Phases=2,Heal=12,Summon=5,Cap=6, Skills=3},
  {Min=1500,Max=1999,Strength=666,Phases=2,Heal=8, Summon=6,Cap=4, Skills=2},
 {Min=2000,Max=2999,Strength=555,Phases=2,Heal=5,Summon=8,Cap=2,Skills=1},
 {Min=3000,Max=2147483647,Strength=444,Phases=2,Heal=5,Summon=8,Cap=2,Skills=1}
};
local BEST_TIER_THRESHOLD=TIERS[#TIERS].Min;
local PURIFICATION_DISPLAY_MAX=3000;
local BATTLEFIELD_REVEAL_RADIUS=6;
local BOSS_SIGHT_RADIUS=6;
local BOSS_SIGHT_VERSION=2;
local CHURCH_GOD_RESPAWN_DELAY=5;
local CHURCH_GOD_RESPAWN_VERSION=2;
local PLAYER_GOD_RESPAWN_DELAY=5;
local BOSS_LIVES=2;
local EXHAUSTED_BOSS_RECOVERY_VERSION=1;
local BOSS_DEATH_RECOVERY_VERSION=1;
local VICTORY_PRESENTATION_VERSION=1;

local function Log(message) print("[LOTM_RESCUE][Phase10] "..tostring(message)); end
local function Number(value,default) if value==nil then return default; end return tonumber(value) or default; end
local function Active() return Number(Game.GetProperty("LOTM_RESCUE_MODE"),0)==1; end
local function IsNetworkMultiplayer()
 return GameConfiguration~=nil and GameConfiguration.IsAnyMultiplayer~=nil and GameConfiguration.IsAnyMultiplayer() or false;
end
local function PublishNetworkConfirmedDamage(unit)
 if not IsNetworkMultiplayer() or unit==nil or unit:IsDead() or unit:IsDelayedDeath() then return -1; end
 local current=Number(unit:GetDamage(),0);
 if Number(unit:GetProperty(CONFIRMED_DAMAGE_PROPERTY),-1)~=current then unit:SetProperty(CONFIRMED_DAMAGE_PROPERTY,current); end
 return current;
end
local function WorldTurn() return LOTM_RESCUE_Phase5.WorldTurn(); end
-- Persisted birth turn covers initial descent and the single allowed respawn.
-- Read-only predicate; damage/kill callers retain their synchronized ownership.
function LOTM_RESCUE_Phase10.IsDescentProtected(unit)
 if not Active() or unit==nil or Number(unit:GetProperty(GOD_PROPERTY),0)~=1 then return false; end
 local role=tostring(unit:GetProperty("LOTM_RESCUE_PHASE10_ROLE") or "");
 local friendly=role=="FOOL" or role=="NIGHT" or role=="STORM" or string.match(role,"^PLAYER_GOD_%d+$")~=nil;
 return friendly and Number(unit:GetProperty("LOTM_RESCUE_PHASE10_SPAWN_TURN"),-1)==WorldTurn();
end
local function ProtectDescent(unit,source)
 if not LOTM_RESCUE_Phase10.IsDescentProtected(unit) then return false; end
 Log("descent protection role="..tostring(unit:GetProperty("LOTM_RESCUE_PHASE10_ROLE")).." unit="..unit:GetOwner()..":"..unit:GetID().." turn="..WorldTurn().." source="..source);
 return true;
end

local function FinalTurn() return LOTM_RESCUE_Phase5.FinalTurn(); end
local function RoleKey(role,suffix) return "LOTM_RESCUE_PHASE10_"..role.."_"..suffix; end
local function EngineKey(playerID,unitID) return "LOTM_RESCUE_PHASE10_ENGINE:"..tostring(playerID)..":"..tostring(unitID); end
local function BossEpoch()
 return Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_EPOCH"),0);
end
local function IndependentOwnerID()
 local owner=Number(Game.GetProperty("LOTM_RESCUE_TEST_PLAYER_ID"),-1);
 return owner>=0 and Players[owner]~=nil and Players[owner]:IsAlive() and owner or -1;
end

local function HumanPlayers()
 local result={};
 for _,player in ipairs(PlayerManager.GetAliveMajors()) do if player:IsHuman() then table.insert(result,player); end end
 table.sort(result,function(a,b) return a:GetID()<b:GetID(); end); return result;
end

local function CenterPlot()
 local index=Number(Game.GetProperty("LOTM_RESCUE_CENTER_CITY_PLOT"),Number(Game.GetProperty("LOTM_RESCUE_CENTER_PLOT"),-1));
 return index>=0 and Map.GetPlotByIndex(index) or nil;
end

local function CandidatePlots(maxRange,minRange)
 local center=CenterPlot(); if center==nil then return {}; end
 local rows={}; minRange=math.max(1,Number(minRange,1));
 for dx=-maxRange,maxRange do for dy=-maxRange,maxRange do
  local plot=Map.GetPlotXYWithRangeCheck(center:GetX(),center:GetY(),dx,dy,maxRange);
  local distance=plot~=nil and Map.GetPlotDistance(center:GetX(),center:GetY(),plot:GetX(),plot:GetY()) or -1;
  if plot~=nil and plot:GetIndex()~=center:GetIndex() and not plot:IsWater() and not plot:IsImpassable()
   and distance>=minRange and not plot:IsCity() and plot:GetDistrictType()<0 and plot:GetUnitCount()==0 and not m_spawnReserved[plot:GetIndex()] then
   table.insert(rows,{Plot=plot,Distance=distance});
  end
 end end
 table.sort(rows,function(a,b) if a.Distance~=b.Distance then return a.Distance<b.Distance; end return a.Plot:GetIndex()<b.Plot:GetIndex(); end);
 return rows;
end

local function SetAbilityCount(unit,abilityType,desired)
 local abilities=unit~=nil and unit:GetAbility() or nil; if abilities==nil or GameInfo.UnitAbilities[abilityType]==nil then return false; end
 LOTM_Effects.SetAbilityCount(abilities,abilityType,desired);
 return (abilities:GetAbilityCount(abilityType) or 0)==desired;
end

local function BitAbility(prefix,value) return prefix..tostring(value); end

local function ApplyBits(unit,prefix,bits,value)
 value=math.max(0,math.floor(Number(value,0))); local applied=0;
 for _,bit in ipairs(bits) do
  local enabled=math.floor(value/bit)%2==1 and 1 or 0;
  if SetAbilityCount(unit,BitAbility(prefix,bit),enabled) then applied=applied+enabled*bit; end
 end
 return applied;
end

local function ExactStrength(unit,target)
 if unit==nil then return false; end
 local abilities=unit:GetAbility(); if abilities==nil then return false; end
 -- Ability modifiers apply once regardless of Ability count. Resource 191's
 -- +1 ability stacked N times therefore remained +1. Fixed binary abilities
 -- make every target exact while changing only fourteen 0/1 counters.
 SetAbilityCount(unit,LEGACY_PLUS_ABILITY,0); SetAbilityCount(unit,MINUS_ABILITY,0);
 local info=GameInfo.Units[unit:GetType()]; local baseline=info~=nil and Number(info.Combat,0) or Number(unit:GetCombat(),0);
 local targetValue=math.max(1,math.floor(Number(target,baseline))); local delta=math.max(0,targetValue-baseline);
 local applied=ApplyBits(unit,"ABILITY_LOTM_RESCUE_P10_STRENGTH_",STRENGTH_BITS,delta);
 unit:SetProperty("LOTM_RESCUE_PHASE10_TARGET_STRENGTH",target);
 unit:SetProperty("LOTM_RESCUE_PHASE10_BASELINE_STRENGTH",baseline);
 unit:SetProperty("LOTM_RESCUE_PHASE10_APPLIED_STRENGTH",baseline+applied);
 return baseline+applied==targetValue;
end

local function PlacedUnit(unit,expectedOwner,expectedUnitID)
 if unit==nil then return nil,nil,"NIL_UNIT"; end
 local ok,dead,delayed,owner,unitID,x,y=pcall(function()
  return unit:IsDead(),unit:IsDelayedDeath(),unit:GetOwner(),unit:GetID(),unit:GetX(),unit:GetY();
 end);
 if not ok then return nil,nil,"UNIT_API"; end
 if dead or delayed then return nil,nil,"DEAD_OR_DELAYED"; end
 if owner~=expectedOwner or unitID~=expectedUnitID then return nil,nil,"IDENTITY_MISMATCH"; end
 local direct=UnitManager.GetUnit(expectedOwner,expectedUnitID);
 if direct==nil then return nil,nil,"NOT_IN_OWNER_INDEX"; end
 local plot=Map.GetPlot(x,y);
 if plot==nil then return nil,nil,"NOT_ON_MAP"; end
 local present=false;
 for _,candidate in ipairs(Units.GetUnitsInPlot(plot) or {}) do
  if candidate:GetOwner()==expectedOwner and candidate:GetID()==expectedUnitID then present=true; break; end
 end
 if not present then return nil,nil,"NOT_IN_PLOT_INDEX"; end
 return direct,plot,"OK";
end

local function PlacementAllowed(plot,minRange,maxRange,attemptDistance)
 local center=CenterPlot(); if plot==nil or center==nil then return false,-1,"PLOT_OR_CENTER_MISSING"; end
 local distance=Map.GetPlotDistance(center:GetX(),center:GetY(),plot:GetX(),plot:GetY());
 if plot:GetIndex()==center:GetIndex() then return false,distance,"CENTER_PLOT"; end
 if plot:IsWater() or plot:IsImpassable() or plot:IsCity() or plot:GetDistrictType()>=0 then return false,distance,"ILLEGAL_TERRAIN"; end
 if distance<minRange or distance>maxRange then return false,distance,"OUT_OF_RANGE"; end
 if distance>attemptDistance then return false,distance,"OUTSIDE_ATTEMPT_RING"; end
 if m_spawnReserved[plot:GetIndex()] then return false,distance,"RESERVED"; end
 return true,distance,"OK";
end

local function Spawn(playerID,unitType,role,maxRange,minRange)
 local info=GameInfo.Units[unitType]; if info==nil then Log("spawn failed role="..role.." reason=TYPE_MISSING"); return nil; end
 maxRange=math.max(1,Number(maxRange,4)); minRange=math.max(1,Number(minRange,1));
 local candidates=CandidatePlots(maxRange,minRange); if #candidates==0 then Log("spawn delayed role="..role.." reason=NO_PLOT"); return nil; end
 local initFailures=0; local rejected=0;
 for attempt,entry in ipairs(candidates) do
  local requested=entry.Plot;
  m_phase10Creating=true;
  local ok,unit=pcall(UnitManager.InitUnit,playerID,info.Index,requested:GetX(),requested:GetY());
  m_phase10Creating=false;
  if not ok or unit==nil then
   initFailures=initFailures+1;
   Log("spawn attempt failed role="..role.." attempt="..attempt.."/"..#candidates.." reason=INIT_FAILED requestedPlot="..requested:GetIndex().." requestedDistance="..entry.Distance);
  else
   local unitID=-1; local idOK,idValue=pcall(function() return unit:GetID(); end); if idOK then unitID=Number(idValue,-1); end
   local placed,actualPlot,reason=PlacedUnit(unit,playerID,unitID);
   if (placed==nil or actualPlot:GetIndex()~=requested:GetIndex()) and UnitManager.PlaceUnit~=nil then
    pcall(UnitManager.PlaceUnit,unit,requested:GetX(),requested:GetY());
    placed,actualPlot,reason=PlacedUnit(unit,playerID,unitID);
   end
   local accepted=false; local actualDistance=-1; local placementReason=reason;
   if placed~=nil then accepted,actualDistance,placementReason=PlacementAllowed(actualPlot,minRange,maxRange,entry.Distance); end
   if accepted then
    unit=placed;
    m_spawnReserved[actualPlot:GetIndex()]=true;
    unit:SetProperty(GOD_PROPERTY,role~="MINION" and 1 or 0);
    unit:SetProperty("LOTM_RESCUE_PHASE10_ROLE",role);
    unit:SetProperty("LOTM_RESCUE_PHASE10_SPAWN_TURN",WorldTurn());
    if role~="MINION" then PublishNetworkConfirmedDamage(unit); end
    Game.SetProperty(EngineKey(playerID,unit:GetID()),role);
    Game.SetProperty(RoleKey(role,"OWNER"),playerID); Game.SetProperty(RoleKey(role,"UNIT"),unit:GetID());
    m_roleUnits[role]=unit;
    local experience=unit:GetExperience(); if experience~=nil then experience:SetExperienceLocked(true); end
    Log("spawn committed role="..role.." type="..unitType.." owner="..playerID.." unit="..unit:GetID().." attempt="..attempt.."/"..#candidates.." requestedPlot="..requested:GetIndex().." plot="..actualPlot:GetIndex().." centerDistance="..actualDistance);
    return unit;
   end
   rejected=rejected+1;
   local actual=actualPlot~=nil and actualPlot:GetIndex() or -1;
   Log("spawn rejected role="..role.." attempt="..attempt.."/"..#candidates.." reason="..tostring(placementReason).." owner="..playerID.." unit="..unitID.." requestedPlot="..requested:GetIndex().." requestedDistance="..entry.Distance.." actualPlot="..actual.." actualDistance="..actualDistance);
   if unitID>=0 then Game.SetProperty(EngineKey(playerID,unitID),nil); end
   pcall(UnitManager.Kill,unit);
  end
 end
 Log("spawn delayed role="..role.." reason=ALL_CANDIDATES_REJECTED candidates="..#candidates.." initFailures="..initFailures.." rejected="..rejected.." range="..minRange.."-"..maxRange);
 return nil;
end

local function FindRole(role)
 local cached=m_roleUnits[role];
 if cached~=nil then
  local owner=Number(Game.GetProperty(RoleKey(role,"OWNER")),-1); local unitID=Number(Game.GetProperty(RoleKey(role,"UNIT")),-1);
  local placed=PlacedUnit(cached,owner,unitID);
  if placed~=nil then return placed; end
  m_roleUnits[role]=nil;
 end
 local owner=Number(Game.GetProperty(RoleKey(role,"OWNER")),-1); local unitID=Number(Game.GetProperty(RoleKey(role,"UNIT")),-1);
 if owner<0 or unitID<0 then return nil; end
 if UnitManager~=nil and UnitManager.GetUnit~=nil then
  local ok,direct=pcall(UnitManager.GetUnit,owner,unitID); if ok and direct~=nil then
   local placed=PlacedUnit(direct,owner,unitID); if placed~=nil then m_roleUnits[role]=placed; return placed; end
  end
 end
 local player=Players[owner]; local found=player~=nil and player:GetUnits():FindID(unitID) or nil;
 if found~=nil then local placed=PlacedUnit(found,owner,unitID); if placed~=nil then m_roleUnits[role]=placed; return placed; end end
  Game.SetProperty(EngineKey(owner,unitID),nil);
  Log("role lookup unavailable role="..role.." owner="..owner.." unit="..unitID.." reason=NOT_PLACED_METADATA_PRESERVED");
 return nil;
end

local function TierFor(purification)
 for index,tier in ipairs(TIERS) do if purification>=tier.Min and purification<=tier.Max then return index,tier; end end
 return #TIERS,TIERS[#TIERS];
end

local function PublishTier(purification)
 purification=Number(purification,Number(Game.GetProperty("GLOBAL_PURIFICATION"),0)); local index,tier=TierFor(purification);
 Game.SetProperty("LOTM_RESCUE_PHASE10_PURIFICATION_LOCKED",purification);
 Game.SetProperty("LOTM_RESCUE_PHASE10_PURIFICATION_TIER",index);
 Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_STRENGTH",tier.Strength);
 Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_MAX_HEALTH",tier.Phases*100);
 Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_HEAL",tier.Heal);
 Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_SUMMON_INTERVAL",tier.Summon);
 Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_SKILLS",tier.Skills);
 return index,tier,purification;
end

local function ChurchGodMeta(role)
 for _,meta in ipairs(CHURCH_GODS) do if meta.Role==role then return meta; end end
 return nil;
end

local function BossSpawnCount()
 local stored=Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_SPAWN_COUNT");
 if stored~=nil then return math.max(0,Number(stored,0)); end
 local generated=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_GENERATED"),0)==1;
 local remaining=math.max(0,Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_PHASES_REMAINING"),BOSS_LIVES));
 local count=generated and math.min(BOSS_LIVES,math.max(1,BOSS_LIVES-math.min(BOSS_LIVES,remaining)+1)) or 0;
 Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_SPAWN_COUNT",count);
 Log("boss lives migrated spawned="..count.." remaining="..remaining.." max="..BOSS_LIVES);
 return count;
end

local function ScheduleChurchGodRespawn(role)
 if ChurchGodMeta(role)==nil then return false; end
 local used=Number(Game.GetProperty(RoleKey(role,"RESPAWN_USED")),0);
 if used>=1 then
  Game.SetProperty(RoleKey(role,"STATE"),"DEAD"); Game.SetProperty(RoleKey(role,"RESPAWN_TURN"),nil);
  Log("church god permanently destroyed role="..role.." turn="..WorldTurn()); return false;
 end
 local due=WorldTurn()+CHURCH_GOD_RESPAWN_DELAY;
 Game.SetProperty(RoleKey(role,"STATE"),"RESPAWN_PENDING"); Game.SetProperty(RoleKey(role,"RESPAWN_TURN"),due);
 Log("church god respawn scheduled role="..role.." deathTurn="..WorldTurn().." respawnTurn="..due.." remaining=1"); return true;
end

local function MigrateChurchGodRespawns()
 local previous=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_CHURCH_RESPAWN_VERSION"),0);
 if previous>=CHURCH_GOD_RESPAWN_VERSION then return; end
 if previous==1 and Number(Game.GetProperty("LOTM_RESCUE_PHASE10_DESCENT_TRIGGERED"),0)==1 then
  Game.SetProperty(RoleKey("FOOL","RESPAWN_USED"),1);
  Log("church god respawn migration role=FOOL remaining=0 reason=LEGACY_REPEATED_RESPAWN_EVIDENCE");
 end
 for _,meta in ipairs(CHURCH_GODS) do
  if FindRole(meta.Role)==nil and Game.GetProperty(RoleKey(meta.Role,"STATE"))=="DEAD" and Number(Game.GetProperty(RoleKey(meta.Role,"RESPAWN_USED")),0)==0 then ScheduleChurchGodRespawn(meta.Role); end
 end
 Game.SetProperty("LOTM_RESCUE_PHASE10_CHURCH_RESPAWN_VERSION",CHURCH_GOD_RESPAWN_VERSION);
end

local function SpawnBoss()
 if Number(Game.GetProperty("LOTM_RESCUE_PHASE10_VICTORY"),0)==1 then return nil; end
 local spawnCount=BossSpawnCount();
 if spawnCount>=BOSS_LIVES then Log("boss spawn blocked reason=LIVES_EXHAUSTED count="..spawnCount.." max="..BOSS_LIVES); return nil; end
 local barbID=-1; for _,player in ipairs(PlayerManager.GetAliveBarbarians()) do barbID=player:GetID(); break; end
 if barbID<0 then Log("boss delayed reason=BARBARIAN_OWNER_MISSING"); return nil; end
 local purification=Game.GetProperty("LOTM_RESCUE_PHASE10_PURIFICATION_LOCKED");
 if purification==nil then Log("boss delayed reason=PURIFICATION_NOT_LOCKED"); return nil; end
 local index,tier=TierFor(Number(purification,0));
 local independentOwner=IndependentOwnerID();
 local ownerMode=tostring(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_OWNER_MODE") or "BARBARIAN_FIRST");
 local owner=ownerMode=="INDEPENDENT_FREE_CITIES" and independentOwner or barbID;
 if owner<0 then owner=barbID; ownerMode="BARBARIAN_FIRST"; end
 local unit=Spawn(owner,BOSS_TYPE,"BOSS",2,1);
 if unit==nil and owner==barbID and independentOwner>=0 then
  Log("boss owner fallback from=BARBARIAN to=INDEPENDENT_FREE_CITIES reason=NEAR_CENTER_PLACEMENT_REJECTED owner="..independentOwner);
  owner=independentOwner; ownerMode="INDEPENDENT_FREE_CITIES";
  unit=Spawn(owner,BOSS_TYPE,"BOSS",2,1);
 end
 if unit==nil then return nil; end
 Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_OWNER_MODE",ownerMode);
 local strengthOK=ExactStrength(unit,tier.Strength); local attacks=ApplyBits(unit,"ABILITY_LOTM_RESCUE_P10_EXTRA_ATTACK_",ATTACK_BITS,math.max(0,tier.Skills-1));
 unit:SetProperty("LOTM_RESCUE_PHASE10_BOSS_TIER",index); unit:SetProperty("LOTM_RESCUE_PHASE10_BOSS_PHASE",Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_PHASES_REMAINING"),tier.Phases));
  spawnCount=spawnCount+1; Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_SPAWN_COUNT",spawnCount); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_GENERATED",1); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_RESPAWN_PENDING",0);
  local epoch=BossEpoch()+1; Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_EPOCH",epoch);
  unit:SetProperty("LOTM_RESCUE_PHASE10_BOSS_EPOCH",epoch);
 local plot=Map.GetPlot(unit:GetX(),unit:GetY()); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_OWNER",unit:GetOwner()); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_UNIT",unit:GetID()); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_PLOT",plot~=nil and plot:GetIndex() or -1); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_X",unit:GetX()); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_Y",unit:GetY());
 Log("boss ready tier="..index.." ownerMode="..ownerMode.." owner="..unit:GetOwner().." strength="..tier.Strength.." applied="..Number(unit:GetProperty("LOTM_RESCUE_PHASE10_APPLIED_STRENGTH"),-1).." strengthOK="..tostring(strengthOK).." extraAttacks="..attacks.." phasesRemaining="..Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_PHASES_REMAINING"),tier.Phases).." heal="..tier.Heal.." summon="..tier.Summon.." skills="..tier.Skills);
 return unit;
end

local function MigrateBossPosition()
 if Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_POSITION_VERSION"),0)>=BOSS_POSITION_VERSION then return true; end
 local boss=FindRole("BOSS"); local center=CenterPlot();
 if boss==nil then Log("boss position migration delayed reason=BOSS_NOT_INDEXED"); return false; end
 if center==nil then Log("boss position migration delayed reason=CENTER_MISSING"); return false; end
 local bossPlot=Map.GetPlot(boss:GetX(),boss:GetY());
 if bossPlot==nil then Log("boss position migration delayed reason=BOSS_PLOT_MISSING unit="..boss:GetID()); return false; end
 local before=Map.GetPlotDistance(center:GetX(),center:GetY(),bossPlot:GetX(),bossPlot:GetY());
 if before>=1 and before<=2 then
  Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_POSITION_VERSION",BOSS_POSITION_VERSION);
  Log("boss position migration retained unit="..boss:GetID().." distance="..before.." plot="..bossPlot:GetIndex());
  return true;
 end
 local candidates=CandidatePlots(2,1);
 if #candidates==0 or UnitManager==nil or UnitManager.PlaceUnit==nil then
  Log("boss position migration delayed reason=NO_NEAR_CENTER_PLOT distance="..before); return false;
 end
 for attempt,entry in ipairs(candidates) do
  local destination=entry.Plot;
  local ok,result=pcall(UnitManager.PlaceUnit,boss,destination:GetX(),destination:GetY());
  local moved=ok and result~=false and boss:GetX()==destination:GetX() and boss:GetY()==destination:GetY();
  if moved then
   Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_POSITION_VERSION",BOSS_POSITION_VERSION);
   Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_PLOT",destination:GetIndex());
   Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_X",boss:GetX()); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_Y",boss:GetY());
   Log("boss position migrated unit="..boss:GetID().." fromDistance="..before.." attempt="..attempt.."/"..#candidates.." toPlot="..destination:GetIndex().." toDistance="..entry.Distance);
   return true;
  end
 end
 Log("boss position migration delayed reason=ALL_NEAR_CENTER_PLACES_FAILED distance="..before.." candidates="..#candidates); return false;
end

local function EnsureChurchGods()
 local owner=Number(Game.GetProperty("LOTM_RESCUE_TEST_PLAYER_ID"),-1);
 if owner<0 or Players[owner]==nil or not Players[owner]:IsAlive() then Log("church gods delayed reason=INDEPENDENT_OWNER_MISSING"); return false; end
 for _,meta in ipairs(CHURCH_GODS) do
  local unit=FindRole(meta.Role); local state=tostring(Game.GetProperty(RoleKey(meta.Role,"STATE")) or "");
  local canSpawn=state=="";
  local respawning=state=="RESPAWN_PENDING" and WorldTurn()>=Number(Game.GetProperty(RoleKey(meta.Role,"RESPAWN_TURN")),2147483647);
  if unit==nil and state=="ACTIVE" then
   if Number(Game.GetProperty(RoleKey(meta.Role,"RESPAWN_USED")),0)>=1 then
    Game.SetProperty(RoleKey(meta.Role,"STATE"),"DEAD"); state="DEAD";
   else
    ScheduleChurchGodRespawn(meta.Role); state="RESPAWN_PENDING";
   end
  end
  if unit==nil and (canSpawn or respawning) then
   unit=Spawn(owner,meta.Type,meta.Role,4);
   if unit~=nil then
    ExactStrength(unit,550); Game.SetProperty(RoleKey(meta.Role,"STATE"),"ACTIVE");
    if respawning then Game.SetProperty(RoleKey(meta.Role,"RESPAWN_USED"),1); Game.SetProperty(RoleKey(meta.Role,"RESPAWN_TURN"),nil); Log("church god respawned role="..meta.Role.." turn="..WorldTurn().." remaining=0"); end
   end
  end
  -- Existing saves can enter this version with the god already serialized.
  -- Reapply the exact synchronized target so the 255-clamp correction never
  -- depends on creating a replacement unit.
  if unit~=nil then ExactStrength(unit,PLAYER_GOD_BASE_STRENGTH); PublishNetworkConfirmedDamage(unit); end
 end
 return true;
end

local function RevealBattlefield()
 if Number(Game.GetProperty("LOTM_RESCUE_PHASE10_VISIBILITY_VERSION"),0)>=VISIBILITY_VERSION then return; end
 local center=CenterPlot(); if center==nil then return; end
 local revealed=0;
 for _,player in ipairs(HumanPlayers()) do
  local visibility=PlayersVisibility[player:GetID()];
  if visibility~=nil then
   for dx=-BATTLEFIELD_REVEAL_RADIUS,BATTLEFIELD_REVEAL_RADIUS do for dy=-BATTLEFIELD_REVEAL_RADIUS,BATTLEFIELD_REVEAL_RADIUS do
    local plot=Map.GetPlotXYWithRangeCheck(center:GetX(),center:GetY(),dx,dy,BATTLEFIELD_REVEAL_RADIUS);
    if plot~=nil then visibility:ChangeVisibilityCount(plot:GetIndex(),1); revealed=revealed+1; end
   end end
  end
 end
 Game.SetProperty("LOTM_RESCUE_PHASE10_VISIBILITY_VERSION",VISIBILITY_VERSION);
 Log("battlefield revealed center="..center:GetIndex().." radius="..BATTLEFIELD_REVEAL_RADIUS.." visibilityEntries="..revealed);
end

local function PlotSetCSV(indices)
 local text={}; for _,index in ipairs(indices) do text[#text+1]=tostring(index); end
 return table.concat(text,",");
end

local function PlotSetFromCSV(value)
 local result={}; local seen={}; for token in string.gmatch(tostring(value or ""),"[^,]+") do
  local index=tonumber(token); if index~=nil and not seen[index] and Map.GetPlotByIndex(index)~=nil then result[#result+1]=index; seen[index]=true; end
 end
 table.sort(result);
 return result;
end

local function BossSightPlots(boss)
 local result={}; local seen={}; if boss==nil then return result; end
 for dx=-BOSS_SIGHT_RADIUS,BOSS_SIGHT_RADIUS do for dy=-BOSS_SIGHT_RADIUS,BOSS_SIGHT_RADIUS do
  local plot=Map.GetPlotXYWithRangeCheck(boss:GetX(),boss:GetY(),dx,dy,BOSS_SIGHT_RADIUS);
  local index=plot~=nil and plot:GetIndex() or -1;
  if index>=0 and not seen[index] then result[#result+1]=index; seen[index]=true; end
 end end
 table.sort(result);
 return result;
end

local function MaintainBossVisibility()
 if Number(Game.GetProperty("LOTM_RESCUE_PHASE10_DESCENT_TRIGGERED"),0)~=1 then return; end
 local boss=FindRole("BOSS"); local bossPlot=boss~=nil and Map.GetPlot(boss:GetX(),boss:GetY()) or nil;
 local bossPlotIndex=bossPlot~=nil and bossPlot:GetIndex() or -1;
 local current=BossSightPlots(boss); local currentSet={}; for _,index in ipairs(current) do currentSet[index]=true; end
 local currentCSV=PlotSetCSV(current);
 local changed=0; local restored=0;
 for _,player in ipairs(HumanPlayers()) do
  local visibility=PlayersVisibility[player:GetID()];
  if visibility~=nil then
    local key="LOTM_RESCUE_PHASE10_BOSS_SIGHT_PLOTS_V"..BOSS_SIGHT_VERSION;
    local previous=PlotSetFromCSV(player:GetProperty(key));
   local previousSet={}; for _,index in ipairs(previous) do previousSet[index]=true; end
   for _,index in ipairs(previous) do
    if not currentSet[index] and visibility:GetVisibilityCount(index)>0 then visibility:ChangeVisibilityCount(index,-1); changed=changed+1; end
   end
   for _,index in ipairs(current) do
    if not previousSet[index] then visibility:ChangeVisibilityCount(index,1); changed=changed+1;
    elseif not visibility:IsVisible(index) then visibility:ChangeVisibilityCount(index,1); restored=restored+1; end
   end
   player:SetProperty(key,currentCSV);
   player:SetProperty("LOTM_RESCUE_PHASE10_BOSS_SIGHT_UNIT",boss~=nil and boss:GetID() or -1);
   player:SetProperty("LOTM_RESCUE_PHASE10_BOSS_SIGHT_PLOT",bossPlotIndex);
  end
 end
  Log("boss sight maintained unit="..tostring(boss~=nil and boss:GetID() or -1).." plot="..tostring(bossPlotIndex).." radius="..BOSS_SIGHT_RADIUS.." changed="..changed.." restored="..restored.." humans="..#HumanPlayers());
end

 local function CombatStrengthDamage(attack,defense)
  return math.max(1,math.min(100,math.floor(24*math.exp((attack-defense)/25))));
end

local function EffectiveCombatStrength(unit,fallback)
 if unit==nil then return fallback; end
 -- Final-battle strengths intentionally exceed GameCore's native display
 -- range.  GetCombat() is observed to clamp those units at 255, so using it
 -- made a 550/999-strength god retaliate for only one damage.  The exact
 -- synchronized target published by ExactStrength is authoritative for gods;
 -- ordinary units continue to use their live runtime value.
 if Number(unit:GetProperty(GOD_PROPERTY),0)==1 then
  local applied=Number(unit:GetProperty("LOTM_RESCUE_PHASE10_APPLIED_STRENGTH"),0);
  if applied>0 then return applied; end
 end
 local runtime=Number(unit:GetCombat(),0);
 if runtime>0 then return runtime; end
 return Number(unit:GetProperty("LOTM_RESCUE_PHASE10_APPLIED_STRENGTH"),fallback);
end

local function EffectiveAttackStrength(unit,fallback)
 if unit==nil then return fallback; end
 if Number(unit:GetProperty(GOD_PROPERTY),0)==1 then return EffectiveCombatStrength(unit,fallback); end
 return math.max(Number(unit:GetCombat(),0),Number(unit:GetRangedCombat(),0),Number(unit:GetBombardCombat(),0),fallback or 0);
end

local function IsGod(unit)
 return unit~=nil and Number(unit:GetProperty(GOD_PROPERTY),0)==1;
end

local function UnitKey(playerID,unitID)
 return tostring(playerID)..":"..tostring(unitID);
end

local function QueueNetworkRemoval(playerID,unitID,role)
 local normalizedPlayerID=tonumber(playerID); local normalizedUnitID=tonumber(unitID);
 if normalizedPlayerID==nil or normalizedUnitID==nil or role==nil or role=="" then return; end
 local key=UnitKey(normalizedPlayerID,normalizedUnitID);
 local epoch=tostring(role)=="BOSS" and BossEpoch() or 0;
 local queueKey=tostring(role)=="BOSS" and (key..":E"..tostring(epoch)) or key;
 local existing=m_pendingNetworkRemovalKeys[queueKey];
 if existing~=nil then
  existing.Intentional=existing.Intentional==true or m_bossIntentionalDefeat[key]==true;
  return;
 end
 local entry={PlayerID=normalizedPlayerID,UnitID=normalizedUnitID,Role=tostring(role),
  QueuedTurn=Game.GetCurrentGameTurn(),Key=queueKey,IdentityKey=key,Epoch=epoch,
  Intentional=m_bossIntentionalDefeat[key]==true};
 m_pendingNetworkRemovals[#m_pendingNetworkRemovals+1]=entry; m_pendingNetworkRemovalKeys[queueKey]=entry;
end

-- Civ VI can clamp scripted damage at maxDamage-1, leaving the Boss visibly
-- alive with one hit point and never emitting a reliable combat-death event.
-- Treat that terminal damage state as lethal and route it through the normal
-- UnitRemoved/ResolveBossDefeat path.  Model migration clears EngineKey first,
-- so migration kills cannot enter this path.
local function KillBossAtTerminalDamage(boss,reason)
 if boss==nil or boss:IsDead() or boss:IsDelayedDeath() then return false; end
 local maximum=Number(boss:GetMaxDamage(),100); local current=Number(boss:GetDamage(),0);
 if current<math.max(0,maximum-1) then return false; end
 local key=boss:GetOwner()..":"..boss:GetID(); m_bossIntentionalDefeat[key]=true;
 local ok,result=pcall(UnitManager.Kill,boss);
 Log("boss terminal damage kill owner="..boss:GetOwner().." unit="..boss:GetID().." damage="..current.." max="..maximum.." reason="..tostring(reason).." ok="..tostring(ok).." result="..tostring(result));
 return ok and result~=false;
end

local function AlliedAttack(attacker,boss)
 if attacker==nil or boss==nil or boss:IsDead() or boss:IsDelayedDeath() then return false,"TARGET_GONE",0; end
 local attack=EffectiveCombatStrength(attacker,550);
 local defense=EffectiveCombatStrength(boss,540);
 local damage=math.min(35,CombatStrengthDamage(attack,defense));
 local maximum=Number(boss:GetMaxDamage(),100); local current=Number(boss:GetDamage(),0);
 if current+damage>=math.max(0,maximum-1) then
  local owner=boss:GetOwner(); local unitID=boss:GetID(); local epoch=BossEpoch();
  local ok=KillBossAtTerminalDamage(boss,"ALLIED_ATTACK");
  if ok and IsNetworkMultiplayer() and ResolveBossDefeat~=nil then
   ResolveBossDefeat(owner,unitID,"ALLIED_SIEGE",epoch);
  end
  return ok,ok and "PHASE_DEFEATED" or "KILL_FAILED",damage;
 end
 boss:ChangeDamage(damage); PublishNetworkConfirmedDamage(boss); return true,"DAMAGE",damage;
end

local function OuterGodUnitAttack(boss,target)
 if boss==nil or target==nil or target:IsDead() or target:IsDelayedDeath() then return false,"TARGET_GONE",0; end
 if ProtectDescent(target,"OUTER_GOD_ATTACK") then return false,"DESCENT_PROTECTED",0; end
 local attack=EffectiveCombatStrength(boss,555);
 local defense=EffectiveCombatStrength(target,550);
 local damage=CombatStrengthDamage(attack,defense);
 local maximum=Number(target:GetMaxDamage(),100); local current=Number(target:GetDamage(),0);
 if current+damage>=maximum then
  local ok=pcall(UnitManager.Kill,target); return ok,ok and "GOD_DESTROYED" or "KILL_FAILED",damage;
 end
 target:ChangeDamage(damage); PublishNetworkConfirmedDamage(target); return true,"DAMAGE",damage;
end

local function AdjacentCityBlocker(target)
 if target==nil or target.City==nil then return nil; end
 local player=Players[target.Owner]; if player==nil or not player:IsAlive() then return nil; end
 local candidates={};
 for _,unit in player:GetUnits():Members() do
  if not unit:IsDead() and not unit:IsDelayedDeath() and Map.GetPlotDistance(unit:GetX(),unit:GetY(),target.City:GetX(),target.City:GetY())==1 then
   candidates[#candidates+1]=unit;
  end
 end
 table.sort(candidates,function(a,b) return a:GetID()<b:GetID(); end);
 return candidates[1];
end

local function OpenFirstRingCount(targetPlot)
 if targetPlot==nil then return 0; end local count=0; local seen={};
 for dx=-1,1 do for dy=-1,1 do
  local plot=Map.GetPlotXYWithRangeCheck(targetPlot:GetX(),targetPlot:GetY(),dx,dy,1);
  if plot~=nil and not seen[plot:GetIndex()] and Map.GetPlotDistance(plot:GetX(),plot:GetY(),targetPlot:GetX(),targetPlot:GetY())==1 then
   seen[plot:GetIndex()]=true;
   if not plot:IsWater() and not plot:IsImpassable() and not plot:IsCity() and plot:GetDistrictType()<0 and plot:GetUnitCount()==0 then count=count+1; end
  end
 end end
 return count;
end

local function PlacementRejected(moveDiagnostic)
 if type(moveDiagnostic)~="table" then return false; end
 return moveDiagnostic.Status=="PLACE_FAILED_ALL" or moveDiagnostic.Status=="PLACE_FAILED_UNEXPECTED_COORD_CHANGE";
end

local function AttackAdjacentCityBlocker(attacker,target)
 local blocker=AdjacentCityBlocker(target); if blocker==nil then return false,"NO_CITY_BLOCKER",0,-1,-1; end
 local owner=blocker:GetOwner(); local unitID=blocker:GetID();
 local attacked,reason,damage=OuterGodUnitAttack(attacker,blocker);
 if attacked and reason=="GOD_DESTROYED" then reason="CITY_BLOCKER_DESTROYED"; end
 return attacked,reason,damage,owner,unitID;
end

local function FirstRingEntries(targetPlot)
 local entries={}; local seen={};
 for dx=-1,1 do for dy=-1,1 do
  local plot=Map.GetPlotXYWithRangeCheck(targetPlot:GetX(),targetPlot:GetY(),dx,dy,1);
  if plot~=nil and Map.GetPlotDistance(plot:GetX(),plot:GetY(),targetPlot:GetX(),targetPlot:GetY())==1 and not seen[plot:GetIndex()] then
   seen[plot:GetIndex()]=true;
   local water=plot:IsWater(); local impassable=plot:IsImpassable(); local city=plot:IsCity();
   local district=plot:GetDistrictType(); local units=plot:GetUnitCount();
   local open=not water and not impassable and not city and district<0 and units==0;
   entries[#entries+1]={Index=plot:GetIndex(),Text=table.concat({
    "plot="..plot:GetIndex(),"xy="..plot:GetX()..":"..plot:GetY(),"owner="..plot:GetOwner(),
    "terrain="..plot:GetTerrainType(),"feature="..plot:GetFeatureType(),"continent="..plot:GetContinentType(),
    "water="..tostring(water),"impassable="..tostring(impassable),"city="..tostring(city),
    "district="..district,"units="..units,"open="..tostring(open)
   },",")};
  end
 end end
 table.sort(entries,function(a,b) return a.Index<b.Index; end);
 local result={}; for _,entry in ipairs(entries) do result[#result+1]="{"..entry.Text.."}"; end
 return table.concat(result,";");
end

local function LogCityAssaultDiagnostic(actor,target,stage,moveDiagnostic)
 if not IsNetworkMultiplayer() or actor==nil or target==nil or target.City==nil then return; end
 local targetPlot=Map.GetPlot(target.City:GetX(),target.City:GetY()); if targetPlot==nil then return; end
 local details="";
 if type(moveDiagnostic)=="table" then
  details=" status="..tostring(moveDiagnostic.Status).." source="..tostring(moveDiagnostic.Source).." target="..tostring(moveDiagnostic.Target)..
   " candidates="..tostring(moveDiagnostic.CandidateCount).." crossContinent="..tostring(moveDiagnostic.CrossContinent)..
   " selection="..tostring(moveDiagnostic.Selection).." destination="..tostring(moveDiagnostic.Destination)..
   " destinationDistance="..tostring(moveDiagnostic.DestinationDistance).." callOK="..tostring(moveDiagnostic.CallOK)..
   " retryCandidates="..tostring(moveDiagnostic.RetryCandidateCount).." attemptCount="..tostring(moveDiagnostic.AttemptCount)..
   " rawResultType="..tostring(moveDiagnostic.RawResultType).." rawResult="..tostring(moveDiagnostic.RawResult)..
   " failureReason="..tostring(moveDiagnostic.FailureReason).." finalXY="..tostring(moveDiagnostic.FinalX)..":"..tostring(moveDiagnostic.FinalY)..
   " moved="..tostring(moveDiagnostic.Moved).." attempts="..tostring(type(moveDiagnostic.Attempts)=="table" and table.concat(moveDiagnostic.Attempts,"|") or "");
 end
 Log("city assault diagnostic stage="..stage.." actorOwner="..actor:GetOwner().." actorUnit="..actor:GetID()..
  " cityOwner="..target.Owner.." city="..target.ID..details.." firstRing="..FirstRingEntries(targetPlot));
end

local function NearestChurchGod(boss)
 local candidates={};
 for _,meta in ipairs(CHURCH_GODS) do
  local unit=FindRole(meta.Role);
  if unit~=nil then candidates[#candidates+1]={Role=meta.Role,Unit=unit,Distance=Map.GetPlotDistance(boss:GetX(),boss:GetY(),unit:GetX(),unit:GetY())}; end
 end
 table.sort(candidates,function(a,b) if a.Distance~=b.Distance then return a.Distance<b.Distance; end return a.Role<b.Role; end);
 return candidates[1];
end

local function NearestCity(unit)
 local candidates={}; local protected={};
 for _,zone in ipairs({"CENTER","FOOL","NIGHT","STORM"}) do
  local plotIndex=Number(Game.GetProperty("LOTM_RESCUE_"..zone.."_CITY_PLOT"),-1); if plotIndex>=0 then protected[plotIndex]=true; end
 end
 for _,playerID in ipairs(PlayerManager.GetAliveIDs()) do
  local player=Players[playerID];
  if player~=nil and player:IsAlive() then
   for _,city in player:GetCities():Members() do
    local plot=Map.GetPlot(city:GetX(),city:GetY());
    if plot~=nil and protected[plot:GetIndex()]~=true then
      local distance=Map.GetPlotDistance(unit:GetX(),unit:GetY(),city:GetX(),city:GetY());
     candidates[#candidates+1]={City=city,Owner=playerID,ID=city:GetID(),Distance=distance};
    end
   end
  end
 end
 table.sort(candidates,function(a,b)
  if a.Distance~=b.Distance then return a.Distance<b.Distance; end
  if a.Owner~=b.Owner then return a.Owner<b.Owner; end
  return a.ID<b.ID;
 end);
 return candidates[1];
end

local function LockedCityTarget(unit)
 local owner=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_CITY_LOCK_OWNER"),-1);
 local cityID=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_CITY_LOCK_ID"),-1);
 if owner<0 or cityID<0 then return nil; end
 local city=CityManager.GetCity(owner,cityID); if city==nil then return nil; end
 local plot=Map.GetPlot(city:GetX(),city:GetY()); if plot==nil then return nil; end
 for _,zone in ipairs({"CENTER","FOOL","NIGHT","STORM"}) do
  if plot:GetIndex()==Number(Game.GetProperty("LOTM_RESCUE_"..zone.."_CITY_PLOT"),-1) then return nil; end
 end
 return {City=city,Owner=owner,ID=cityID,Distance=Map.GetPlotDistance(unit:GetX(),unit:GetY(),city:GetX(),city:GetY())};
end

local function UpdateBossCityLock(target,turn)
 local owner=target~=nil and target.Owner or -1; local cityID=target~=nil and target.ID or -1;
 local previousOwner=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_CITY_LOCK_OWNER"),-1);
 local previousCity=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_CITY_LOCK_ID"),-1);
 local start=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_CITY_LOCK_START"),turn);
 if owner~=previousOwner or cityID~=previousCity then
  start=turn; Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_CITY_LOCK_OWNER",owner); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_CITY_LOCK_ID",cityID); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_CITY_LOCK_START",start);
 end
 return start,math.max(1,turn-start+1);
end

local function ClearBossCityLock(reason)
 local owner=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_CITY_LOCK_OWNER"),-1); local cityID=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_CITY_LOCK_ID"),-1);
 if owner>=0 or cityID>=0 then Log("outer god city lock cleared owner="..owner.." city="..cityID.." reason="..tostring(reason)); end
 Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_CITY_LOCK_OWNER",nil); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_CITY_LOCK_ID",nil); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_CITY_LOCK_START",nil);
end

local DestroyCityDirect;
local function GuideMinions(playerID,force)
 local humans=HumanPlayers(); local anchor=#humans>0 and humans[1]:GetID() or -1;
 if not force and playerID~=anchor then return; end
 local turn=WorldTurn(); if Number(Game.GetProperty("LOTM_RESCUE_PHASE10_MINION_ACTION_TURN"),-1)==turn then return; end
 if LOTM_RESCUE_SyncActions==nil then return; end
 local minions={};
 for _,barbarian in ipairs(PlayerManager.GetAliveBarbarians()) do
  for _,unit in barbarian:GetUnits():Members() do
   if Number(unit:GetProperty("LOTM_RESCUE_PHASE10_IS_MINION"),0)==1 and not unit:IsDead() and not unit:IsDelayedDeath() then minions[#minions+1]=unit; end
  end
 end
 table.sort(minions,function(a,b) if a:GetOwner()~=b:GetOwner() then return a:GetOwner()<b:GetOwner(); end return a:GetID()<b:GetID(); end);
 for _,minion in ipairs(minions) do
  local target=NearestCity(minion); local targetPlot=target~=nil and Map.GetPlot(target.City:GetX(),target.City:GetY()) or nil;
  if target~=nil and targetPlot~=nil then
   local before=Map.GetPlotDistance(minion:GetX(),minion:GetY(),targetPlot:GetX(),targetPlot:GetY()); local moved=false; local moveReason="ADJACENT"; local destination=-1; local moveDiagnostic=IsNetworkMultiplayer() and {} or nil;
   if before>1 then LogCityAssaultDiagnostic(minion,target,"BEFORE_MOVE",nil); moved,moveReason,destination=LOTM_RESCUE_SyncActions.MoveToward(minion,targetPlot,5,false,true,nil,nil,moveDiagnostic); LogCityAssaultDiagnostic(minion,target,"AFTER_MOVE",moveDiagnostic); end
   local after=Map.GetPlotDistance(minion:GetX(),minion:GetY(),targetPlot:GetX(),targetPlot:GetY()); local destroyed=false; local destroyReason="OUT_OF_RANGE";
   local blockerAttacked=false; local blockerReason="NOT_NEEDED"; local blockerDamage=0; local blockerOwner=-1; local blockerUnit=-1;
   if after<=1 then destroyed,destroyReason=DestroyCityDirect(target.City);
   elseif after==2 then
    blockerAttacked,blockerReason,blockerDamage,blockerOwner,blockerUnit=AttackAdjacentCityBlocker(minion,target);
    if not blockerAttacked and IsNetworkMultiplayer() and PlacementRejected(moveDiagnostic) and OpenFirstRingCount(targetPlot)>0 then
     destroyed,destroyReason=DestroyCityDirect(target.City); if destroyed then destroyReason="FORCED_SIEGE_"..destroyReason; end
    end
   end
   if before>1 then LogCityAssaultDiagnostic(minion,target,"AFTER_ACTION",nil); end
   UnitManager.FinishMoves(minion);
   Log("outer god minion action turn="..turn.." owner="..minion:GetOwner().." unit="..minion:GetID().." cityOwner="..target.Owner.." city="..target.ID.." before="..before.." after="..after.." moved="..tostring(moved).." moveReason="..moveReason.." destination="..destination.." destroyed="..tostring(destroyed).." destroyReason="..destroyReason.." blockerAttacked="..tostring(blockerAttacked).." blockerReason="..blockerReason.." blockerDamage="..blockerDamage.." blockerOwner="..blockerOwner.." blockerUnit="..blockerUnit);
  else
   UnitManager.FinishMoves(minion); Log("outer god minion action delayed turn="..turn.." owner="..minion:GetOwner().." unit="..minion:GetID().." reason=NO_UNPROTECTED_CITY");
  end
 end
 Game.SetProperty("LOTM_RESCUE_PHASE10_MINION_ACTION_TURN",turn);
end

DestroyCityDirect=function(city)
 if city==nil then return false,"CITY_MISSING"; end
 local owner=city:GetOwner(); local cityID=city:GetID(); local live=CityManager.GetCity(owner,cityID);
 if live==nil then return false,"CITY_MISSING"; end
 if CityManager.DestroyCity~=nil then
  local ok,result=pcall(CityManager.DestroyCity,live);
  if ok and result~=false and CityManager.GetCity(owner,cityID)==nil then return true,"CITY_DESTROYED"; end
 end
 if CityManager.RequestCommand==nil or CityCommandTypes==nil or CityCommandTypes.DESTROY==nil or CityDestroyDirectives==nil or CityDestroyDirectives.RAZE==nil or UnitOperationTypes==nil or UnitOperationTypes.PARAM_FLAGS==nil then return false,"CITY_DESTROY_API_UNAVAILABLE"; end
 local parameters={}; parameters[UnitOperationTypes.PARAM_FLAGS]=CityDestroyDirectives.RAZE;
 local ok,result=pcall(CityManager.RequestCommand,live,CityCommandTypes.DESTROY,parameters);
 if not ok or result==false then return false,"CITY_DESTROY_REQUEST_FAILED"; end
 return true,"CITY_DESTROY_REQUESTED";
end

local function GuideOuterGod(playerID,force)
 local humans=HumanPlayers(); local anchor=#humans>0 and humans[1]:GetID() or -1;
 if not force and playerID~=anchor then return; end
 local turn=WorldTurn(); if Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_ACTION_TURN"),-1)==turn then return; end
 local boss=FindRole("BOSS"); if boss==nil or LOTM_RESCUE_SyncActions==nil then return; end
 local _,lockedTier=TierFor(Number(Game.GetProperty("LOTM_RESCUE_PHASE10_PURIFICATION_LOCKED"),0));
 ExactStrength(boss,lockedTier.Strength);
 local target=NearestChurchGod(boss); local targetPlot=nil; local kind="CHURCH_GOD"; local owner=-1; local id=-1; local role="";
 if target~=nil then targetPlot=Map.GetPlot(target.Unit:GetX(),target.Unit:GetY()); owner=target.Unit:GetOwner(); id=target.Unit:GetID(); role=target.Role;
 else
  target=LockedCityTarget(boss) or NearestCity(boss); kind="CITY";
  if target~=nil then targetPlot=Map.GetPlot(target.City:GetX(),target.City:GetY()); owner=target.Owner; id=target.ID; end
 end
 if target==nil or targetPlot==nil then Log("outer god action delayed reason=NO_TARGET turn="..turn); return; end
 local lockStart=-1; local lockAge=0;
 if kind=="CITY" then lockStart,lockAge=UpdateBossCityLock(target,turn); else ClearBossCityLock("NON_CITY_TARGET"); end
 local before=Map.GetPlotDistance(boss:GetX(),boss:GetY(),targetPlot:GetX(),targetPlot:GetY()); local moved=false; local reason="ADJACENT"; local destination=-1; local moveDiagnostic=IsNetworkMultiplayer() and kind=="CITY" and {} or nil;
 if before>1 then if kind=="CITY" then LogCityAssaultDiagnostic(boss,target,"BEFORE_MOVE",nil); end moved,reason,destination=LOTM_RESCUE_SyncActions.MoveToward(boss,targetPlot,6,false,true,nil,nil,moveDiagnostic); if kind=="CITY" then LogCityAssaultDiagnostic(boss,target,"AFTER_MOVE",moveDiagnostic); end end
 local after=Map.GetPlotDistance(boss:GetX(),boss:GetY(),targetPlot:GetX(),targetPlot:GetY()); local attacked=false; local attackReason="OUT_OF_RANGE"; local damage=0; local blockerOwner=-1; local blockerUnit=-1;
 if after<=1 then
  if kind=="CHURCH_GOD" then attacked,attackReason,damage=OuterGodUnitAttack(boss,target.Unit);
  else attacked,attackReason=DestroyCityDirect(target.City); end
 elseif kind=="CITY" and after==2 then
  attacked,attackReason,damage,blockerOwner,blockerUnit=AttackAdjacentCityBlocker(boss,target);
  if not attacked and IsNetworkMultiplayer() and PlacementRejected(moveDiagnostic) and OpenFirstRingCount(targetPlot)>0 then
   attacked,attackReason=DestroyCityDirect(target.City); if attacked then attackReason="FORCED_SIEGE_"..attackReason; end
  end
 end
 local cityResolved=kind=="CITY" and attacked and (string.find(attackReason,"CITY_DESTROY",1,true)~=nil);
 if kind=="CITY" and not cityResolved and lockAge>=3 then
  local forced,forcedReason=DestroyCityDirect(target.City);
  if forced then attacked=true; attackReason="LOCK_TIMEOUT_3_"..forcedReason; cityResolved=true; end
 end
 if cityResolved then ClearBossCityLock(attackReason); end
 if kind=="CITY" and before>1 then LogCityAssaultDiagnostic(boss,target,"AFTER_ACTION",nil); end
 UnitManager.FinishMoves(boss); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_ACTION_TURN",turn);
 Log("outer god action turn="..turn.." kind="..kind.." role="..role.." owner="..owner.." id="..id.." before="..before.." after="..after.." moved="..tostring(moved).." moveReason="..reason.." destination="..destination.." attacked="..tostring(attacked).." attackReason="..attackReason.." damage="..damage.." blockerOwner="..blockerOwner.." blockerUnit="..blockerUnit.." lockStart="..lockStart.." lockAge="..lockAge.." cityResolved="..tostring(cityResolved));
end

local function GuideChurchGods(playerID,force)
 local humans=HumanPlayers(); local anchor=#humans>0 and humans[1]:GetID() or -1;
 if not force and playerID~=anchor then return; end
 local turn=WorldTurn(); local appliedVersion=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_ALLIED_ACTION_VERSION"),0);
 if appliedVersion>=ALLIED_ACTION_VERSION and Number(Game.GetProperty("LOTM_RESCUE_PHASE10_ALLIED_ACTION_TURN"),-1)==turn then return; end
 local boss=FindRole("BOSS");
 if boss==nil then Log("allied siege delayed reason=BOSS_NOT_INDEXED turn="..turn); return; end
 if LOTM_RESCUE_SyncActions==nil then Log("allied siege delayed reason=SYNC_ACTIONS_MISSING turn="..turn); return; end
 local target=Map.GetPlot(boss:GetX(),boss:GetY()); if target==nil then Log("allied siege delayed reason=BOSS_PLOT_MISSING turn="..turn); return; end
 local indexed={};
 for _,meta in ipairs(CHURCH_GODS) do local unit=FindRole(meta.Role); if unit~=nil then indexed[#indexed+1]={Meta=meta,Unit=unit}; end end
 local found=#indexed;
 if found==0 then Log("allied siege delayed reason=NO_CHURCH_GODS_INDEXED turn="..turn); return; end
 if found<#CHURCH_GODS then Log("allied siege delayed reason=PARTIAL_CHURCH_GODS_INDEXED found="..found.." expected="..#CHURCH_GODS.." turn="..turn); return; end
 for _,entry in ipairs(indexed) do
  local meta=entry.Meta; local unit=entry.Unit;
   local before=Map.GetPlotDistance(unit:GetX(),unit:GetY(),target:GetX(),target:GetY()); local moved=false; local reason="ADJACENT"; local source=Map.GetPlot(unit:GetX(),unit:GetY()); local destination=source~=nil and source:GetIndex() or -1;
   if before>1 then
    local info=GameInfo.Units[unit:GetType()];
    moved,reason,destination=LOTM_RESCUE_SyncActions.MoveToward(unit,target,info~=nil and Number(info.BaseMoves,1) or 1,false,true);
   end
   local after=Map.GetPlotDistance(unit:GetX(),unit:GetY(),target:GetX(),target:GetY()); local attacked=false; local attackReason="OUT_OF_RANGE"; local damage=0;
   if after<=1 then attacked,attackReason,damage=AlliedAttack(unit,boss); end
   UnitManager.FinishMoves(unit);
   Log("allied siege role="..meta.Role.." boss="..boss:GetID().." before="..before.." after="..after.." moved="..tostring(moved).." moveReason="..reason.." destination="..destination.." attacked="..tostring(attacked).." attackReason="..attackReason.." damage="..damage);
   if FindRole("BOSS")==nil then break; end
 end
 Game.SetProperty("LOTM_RESCUE_PHASE10_ALLIED_ACTION_VERSION",ALLIED_ACTION_VERSION);
 Game.SetProperty("LOTM_RESCUE_PHASE10_ALLIED_ACTION_TURN",turn);
 Log("allied siege completed turn="..turn.." godsProcessed="..found);
end

local function FreezeIndependentGodAI(playerID)
 local owner=IndependentOwnerID(); if playerID~=owner then return; end
 for _,meta in ipairs(CHURCH_GODS) do local unit=FindRole(meta.Role); if unit~=nil then UnitManager.FinishMoves(unit); end end
 local boss=FindRole("BOSS"); if boss~=nil and boss:GetOwner()==owner then UnitManager.FinishMoves(boss); end
end

local function MigrateChurchGodOwnership()
 if Number(Game.GetProperty("LOTM_RESCUE_PHASE10_OWNERSHIP_VERSION"),0)>=1 then return; end
 local owner=Number(Game.GetProperty("LOTM_RESCUE_TEST_PLAYER_ID"),-1); local retired=0;
 if owner<0 or Players[owner]==nil or not Players[owner]:IsAlive() then Log("ownership migration delayed reason=INDEPENDENT_OWNER_MISSING"); return; end
 for _,meta in ipairs(CHURCH_GODS) do
  local storedOwner=Number(Game.GetProperty(RoleKey(meta.Role,"OWNER")),-1); local unit=FindRole(meta.Role);
  if unit~=nil and storedOwner~=owner then
   local unitID=unit:GetID(); Game.SetProperty(EngineKey(storedOwner,unitID),nil);
   Game.SetProperty(RoleKey(meta.Role,"OWNER"),nil); Game.SetProperty(RoleKey(meta.Role,"UNIT"),nil); Game.SetProperty(RoleKey(meta.Role,"STATE"),nil);
   local ok=pcall(UnitManager.Kill,unit); if ok then retired=retired+1; end
  end
 end
 Game.SetProperty("LOTM_RESCUE_PHASE10_OWNERSHIP_VERSION",1);
 Log("ownership migration independentOwner="..owner.." retiredHumanChurchGods="..retired);
end

local function PlayerGodRole(playerID) return "PLAYER_GOD_"..tostring(playerID); end
local function PlayerGodIDFromRole(role) return tonumber(string.match(tostring(role or ""),"^PLAYER_GOD_(%d+)$")); end
local function DesiredPlayerGodType(path)
 if PERFECT_MODEL_PATHS[path] then return PERFECT_MODEL_TYPE; end
 return PATH_GODS[path];
end
local function EnsurePlayerGod(player)
 if player==nil or not player:IsHuman() then return nil; end
 local path=tostring(player:GetProperty("LOTM_RP_PATH") or "NONE"); local sequence=Number(player:GetProperty("LOTM_RP_SEQUENCE"),9);
 if sequence>0 or PATH_GODS[path]==nil then return nil; end
 local role=PlayerGodRole(player:GetID()); local unit=FindRole(role); local desiredType=DesiredPlayerGodType(path); local desiredInfo=GameInfo.Units[desiredType];
 if unit~=nil and desiredInfo~=nil and unit:GetType()~=desiredInfo.Index then
  local oldOwner=unit:GetOwner(); local oldID=unit:GetID(); Game.SetProperty(EngineKey(oldOwner,oldID),nil); m_roleUnits[role]=nil;
  Game.SetProperty(RoleKey(role,"OWNER"),nil); Game.SetProperty(RoleKey(role,"UNIT"),nil);
  local ok=pcall(UnitManager.Kill,unit); unit=nil;
  Log("player god model migrated player="..player:GetID().." path="..path.." old="..oldOwner..":"..oldID.." desiredType="..desiredType.." killed="..tostring(ok));
 end
 local state=tostring(Game.GetProperty(RoleKey(role,"STATE")) or "");
 if unit==nil and state=="ACTIVE" then
  if Number(Game.GetProperty(RoleKey(role,"RESPAWN_USED")),0)>=1 then
   Game.SetProperty(RoleKey(role,"STATE"),"DEAD"); state="DEAD";
  else
   local due=WorldTurn()+PLAYER_GOD_RESPAWN_DELAY;
   Game.SetProperty(RoleKey(role,"STATE"),"RESPAWN_PENDING"); Game.SetProperty(RoleKey(role,"RESPAWN_TURN"),due); state="RESPAWN_PENDING";
   Log("player god respawn scheduled role="..role.." deathTurn="..WorldTurn().." respawnTurn="..due.." remaining=1");
  end
 elseif unit==nil and state=="DEAD" and Number(Game.GetProperty(RoleKey(role,"RESPAWN_USED")),0)==0 then
  -- Repair rc.331 saves whose player god was marked DEAD permanently.
  local due=WorldTurn()+PLAYER_GOD_RESPAWN_DELAY;
  Game.SetProperty(RoleKey(role,"STATE"),"RESPAWN_PENDING"); Game.SetProperty(RoleKey(role,"RESPAWN_TURN"),due); state="RESPAWN_PENDING";
  Log("player god respawn migrated role="..role.." deathTurn="..WorldTurn().." respawnTurn="..due.." remaining=1");
 end
 local respawning=state=="RESPAWN_PENDING" and WorldTurn()>=Number(Game.GetProperty(RoleKey(role,"RESPAWN_TURN")),2147483647);
 if unit==nil and (state=="" or respawning) then
  unit=Spawn(player:GetID(),desiredType,role,5);
  if unit~=nil then
   Game.SetProperty(RoleKey(role,"STATE"),"ACTIVE"); player:SetProperty("LOTM_RESCUE_PHASE10_PLAYER_GOD_STATE","ACTIVE"); unit:SetProperty("LOTM_RESCUE_PHASE10_PLAYER_GOD_PATH",path); unit:SetProperty("LOTM_RESCUE_PHASE10_MODEL_SOURCE",desiredType);
   if respawning then Game.SetProperty(RoleKey(role,"RESPAWN_USED"),1); Game.SetProperty(RoleKey(role,"RESPAWN_TURN"),nil); Log("player god respawned role="..role.." turn="..WorldTurn().." remaining=0"); end
  end
 end
 if unit~=nil then
  LOTM_RESCUE_Phase10A.RefreshAll();
  local inherited=Number(player:GetProperty("LOTM_RESCUE_PHASE10A_DIVINE_LEGION_TOTAL"),0);
  local skillReady=Number(player:GetProperty("LOTM_RESCUE_WAR_GOD_RELIC_COMPLETED"),0)==1;
  SetAbilityCount(unit,DIVINE_LEGION_ABILITY,skillReady and 1 or 0);
  local target=PLAYER_GOD_BASE_STRENGTH+(skillReady and math.max(0,inherited) or 0);
  local strengthOK=ExactStrength(unit,target); unit:SetProperty("LOTM_RESCUE_PHASE10_DIVINE_LEGION_TOTAL",inherited); unit:SetProperty("LOTM_RESCUE_PHASE10_DIVINE_LEGION_SKILL",skillReady and 1 or 0);
  local runtimeCombat=Number(unit:GetCombat(),0); local mobilityActive=runtimeCombat>PLAYER_GOD_MOBILITY_THRESHOLD;
  local mobilityOK=SetAbilityCount(unit,PLAYER_GOD_MOBILITY_ABILITY,mobilityActive and 1 or 0);
   unit:SetProperty("LOTM_RESCUE_PHASE10_PLAYER_GOD_RUNTIME_COMBAT",runtimeCombat);
   unit:SetProperty("LOTM_RESCUE_PHASE10_PLAYER_GOD_MOBILITY_BONUS",mobilityActive and PLAYER_GOD_MOBILITY_BONUS or 0);
   PublishNetworkConfirmedDamage(unit);
   Log("divineLegion applied player="..player:GetID().." godUnit="..unit:GetID().." skillReady="..tostring(skillReady).." base="..PLAYER_GOD_BASE_STRENGTH.." inherited="..inherited.." target="..target.." applied="..Number(unit:GetProperty("LOTM_RESCUE_PHASE10_APPLIED_STRENGTH"),-1).." strengthOK="..tostring(strengthOK).." runtimeCombat="..runtimeCombat.." mobilityThreshold="..PLAYER_GOD_MOBILITY_THRESHOLD.." mobilityBonus="..(mobilityActive and PLAYER_GOD_MOBILITY_BONUS or 0).." mobilityOK="..tostring(mobilityOK));
 end
 return unit;
end

-- Called only after Gameplay commits a successful Sequence 0 advancement.
function LOTM_RESCUE_Phase10.OnSequenceZeroAdvanced(playerID)
 if not Active() or Number(Game.GetProperty("LOTM_RESCUE_PHASE10_VICTORY"),0)==1 then return false; end
 if Number(Game.GetProperty("LOTM_RESCUE_PHASE10_DESCENT_TRIGGERED"),0)~=1 then
  Log("sequence zero god player="..tostring(playerID).." reason=WAIT_WORLD_DESCENT"); return false;
 end
 local unit=EnsurePlayerGod(Players[playerID]);
 Log("sequence zero god player="..tostring(playerID).." spawned="..tostring(unit~=nil).." turn="..WorldTurn());
 return unit~=nil;
end

local function CountMinions()
 local barbID=-1; for _,candidate in ipairs(PlayerManager.GetAliveBarbarians()) do barbID=candidate:GetID(); break; end
 local player=barbID>=0 and Players[barbID] or nil; if player==nil then return 0; end
 local count=0; for _,unit in player:GetUnits():Members() do if Number(unit:GetProperty("LOTM_RESCUE_PHASE10_IS_MINION"),0)==1 then count=count+1; end end return count;
end

local function MaintainBoss(playerID)
 local boss=FindRole("BOSS"); if boss==nil then
  Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_PLOT",-1); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_UNIT",-1);
   if Number(Game.GetProperty("LOTM_RESCUE_PHASE10_DESCENT_TRIGGERED"),0)==1
    and Number(Game.GetProperty("LOTM_RESCUE_PHASE10_VICTORY"),0)~=1
    and BossSpawnCount()<BOSS_LIVES then SpawnBoss(); end
  return;
 end
 local bossPlot=Map.GetPlot(boss:GetX(),boss:GetY()); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_OWNER",boss:GetOwner()); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_UNIT",boss:GetID()); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_PLOT",bossPlot~=nil and bossPlot:GetIndex() or -1); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_X",boss:GetX()); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_Y",boss:GetY());
 local barbID=-1; for _,candidate in ipairs(PlayerManager.GetAliveBarbarians()) do barbID=candidate:GetID(); break; end
 if playerID~=boss:GetOwner() then return; end
 local _,tier=TierFor(Number(Game.GetProperty("LOTM_RESCUE_PHASE10_PURIFICATION_LOCKED"),0));
 local damage=Number(boss:GetDamage(),0); if damage>0 then boss:ChangeDamage(-math.min(tier.Heal,damage)); end
 PublishNetworkConfirmedDamage(boss);
 local turn=WorldTurn(); local last=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_LAST_SUMMON_TURN"),-1000000);
 if turn-last>=tier.Summon and CountMinions()<tier.Cap then
  local minion=Spawn(barbID,MINION_TYPE,"MINION",6);
  if minion~=nil then minion:SetProperty(GOD_PROPERTY,0); minion:SetProperty("LOTM_RESCUE_PHASE10_IS_MINION",1); Game.SetProperty("LOTM_RESCUE_PHASE10_LAST_SUMMON_TURN",turn); end
 end
end

local function PublishVictoryPresentation(reason)
 local humans=HumanPlayers();
 if #humans==0 then Log("victory presentation delayed reason=NO_HUMAN_PLAYER source="..tostring(reason)); return false; end
 local winningTeam=humans[1]:GetTeam();
 Game.SetProperty("LOTM_RESCUE_PHASE10_WINNING_TEAM",winningTeam);
 for _,player in ipairs(humans) do
  player:SetProperty("LOTM_RESCUE_PHASE10_VICTORY",1);
 end
 Game.SetProperty("LOTM_RESCUE_PHASE10_VICTORY_PRESENTATION_VERSION",VICTORY_PRESENTATION_VERSION);
 Log("victory presentation published reason="..tostring(reason).." winningTeam="..winningTeam.." humans="..#humans.." gameCoreConquest=false");
 return true;
end

local function GrantVictory()
 local first=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_VICTORY"),0)~=1;
 Game.SetProperty("LOTM_RESCUE_PHASE10_VICTORY",1); Game.SetProperty("LOTM_RESCUE_PHASE10_STATE","VICTORY");
 if first then Game.SetProperty("LOTM_RESCUE_PHASE10_VICTORY_TURN",WorldTurn()); end
 PublishVictoryPresentation(first and "GRANT" or "RECONCILE");
 Log("VICTORY bossDefeated=true worldTurn="..WorldTurn().." purification="..Number(Game.GetProperty("LOTM_RESCUE_PHASE10_PURIFICATION_LOCKED"),0));
end

local function ReconcileVictoryPresentation()
 if Number(Game.GetProperty("LOTM_RESCUE_PHASE10_VICTORY"),0)~=1 then return false; end
 return PublishVictoryPresentation("PRESENTATION_RECONCILE");
end

-- Resources before Phase 10 v30 could consume both Boss spawns while a late or
-- missing removal callback left the save outside the victory state.  A third
-- life would violate the two-life contract, so reconcile this exact old-save
-- terminal state once and award the already-earned victory.
local function MigrateExhaustedBossVictory()
 if Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_DEATH_RECOVERY_VERSION"),0)>=BOSS_DEATH_RECOVERY_VERSION then return false; end
 if Number(Game.GetProperty("LOTM_RESCUE_PHASE10_DESCENT_TRIGGERED"),0)~=1 then return false; end
 if Number(Game.GetProperty("LOTM_RESCUE_PHASE10_VICTORY"),0)==1 then
  Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_DEATH_RECOVERY_VERSION",BOSS_DEATH_RECOVERY_VERSION); return false;
 end
 local boss=FindRole("BOSS"); local spawnCount=BossSpawnCount();
 local defeatCount=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_DEFEAT_COUNT"),0);
 -- New saves carry the authoritative death counter.  For older saves, the
 -- already-proven exhausted-spawn state is the only recoverable evidence.
 local exhausted=(defeatCount>=BOSS_LIVES) or (defeatCount==0 and spawnCount>=BOSS_LIVES);
 if boss~=nil or not exhausted then
  Game.SetProperty("LOTM_RESCUE_PHASE10_EXHAUSTED_BOSS_RECOVERY_VERSION",EXHAUSTED_BOSS_RECOVERY_VERSION); return false;
 end
 Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_PHASES_REMAINING",0);
 Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_RESPAWN_PENDING",0);
 Game.SetProperty(RoleKey("BOSS","STATE"),"DEFEATED_MIGRATED");
  Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_DEATH_RECOVERY_VERSION",BOSS_DEATH_RECOVERY_VERSION);
  Game.SetProperty("LOTM_RESCUE_PHASE10_EXHAUSTED_BOSS_RECOVERY_VERSION",EXHAUSTED_BOSS_RECOVERY_VERSION);
 Log("legacy exhausted boss reconciled spawnCount="..spawnCount.." defeatCount="..defeatCount.." lives="..BOSS_LIVES.." action=GRANT_VICTORY");
 GrantVictory(); return true;
end

local function BeginDescent()
 if Number(Game.GetProperty("LOTM_RESCUE_PHASE10_DESCENT_TRIGGERED"),0)==1 then return true; end
 local center=CenterPlot(); if center==nil then Log("descent delayed reason=CENTER_MISSING"); return false; end
 local purification=Number(Game.GetProperty("GLOBAL_PURIFICATION"),0);
 local index,tier=PublishTier(purification);
 Game.SetProperty("LOTM_RESCUE_PHASE10_DESCENT_TRIGGERED",1); Game.SetProperty("LOTM_RESCUE_PHASE10_DESCENT_TURN",WorldTurn());
 Game.SetProperty("LOTM_RESCUE_PHASE10_SEAL_STATE","RELEASED"); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_PHASES_REMAINING",tier.Phases);
 Game.SetProperty("LOTM_RESCUE_PHASE10_STATE","FINAL_BATTLE"); Game.SetProperty("LOTM_RESCUE_PHASE",10);
 MigrateChurchGodOwnership(); MigrateChurchGodRespawns(); SpawnBoss(); MigrateBossPosition(); EnsureChurchGods(); for _,player in ipairs(HumanPlayers()) do EnsurePlayerGod(player); end RevealBattlefield(); GuideOuterGod(-1,true); GuideChurchGods(-1,true); MaintainBossVisibility();
 Log("DESCENT worldTurn="..WorldTurn().." finalTurn="..FinalTurn().." purification="..purification.." tier="..index.." center="..center:GetIndex());
 return true;
end

local function Refresh(playerID,isFirstTimeThisTurn)
 if not Active() or isFirstTimeThisTurn==false then return; end
 -- Single-player damage callbacks can precede or follow OnCombatOccurred.
 -- Network games never consume this local evidence.
 m_nativeDamageEvents={}; m_bossCombatEvents={};
 Game.SetProperty("LOTM_RESCUE_PHASE10_VERSION",VERSION); Game.SetProperty("LOTM_RESCUE_PHASE10_FINAL_TURN",FinalTurn()); Game.SetProperty("LOTM_RESCUE_PHASE10_BEST_TIER_THRESHOLD",BEST_TIER_THRESHOLD);
 Game.SetProperty("LOTM_RESCUE_PURIFICATION_DISPLAY_MAX",PURIFICATION_DISPLAY_MAX);
 for index=2,#TIERS do Game.SetProperty("LOTM_RESCUE_PHASE10_TIER_THRESHOLD_"..index,TIERS[index].Min); end
 if WorldTurn()>=FinalTurn() then BeginDescent(); end
 local existingBoss=FindRole("BOSS");
 if Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_EPOCH"),0)<=0 and existingBoss~=nil then
  local migratedEpoch=math.max(1,BossSpawnCount());
  Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_EPOCH",migratedEpoch);
  existingBoss:SetProperty("LOTM_RESCUE_PHASE10_BOSS_EPOCH",migratedEpoch);
  Log("boss epoch migrated epoch="..migratedEpoch.." reason=LEGACY_SAVE");
 elseif existingBoss~=nil and Number(existingBoss:GetProperty("LOTM_RESCUE_PHASE10_BOSS_EPOCH"),0)<=0 then
  existingBoss:SetProperty("LOTM_RESCUE_PHASE10_BOSS_EPOCH",BossEpoch());
 end
 PublishNetworkConfirmedDamage(existingBoss);
 MigrateExhaustedBossVictory();
 ReconcileVictoryPresentation();
 if Number(Game.GetProperty("LOTM_RESCUE_PHASE10_DESCENT_TRIGGERED"),0)==1 and Number(Game.GetProperty("LOTM_RESCUE_PHASE10_VICTORY"),0)~=1 then
  MigrateChurchGodOwnership(); MigrateChurchGodRespawns(); MigrateBossPosition(); EnsureChurchGods(); RevealBattlefield();
  local player=Players[playerID]; if player~=nil and player:IsHuman() then EnsurePlayerGod(player); end
  GuideOuterGod(playerID,false);
  GuideMinions(playerID,false);
  GuideChurchGods(playerID,false);
  FreezeIndependentGodAI(playerID);
  MaintainBoss(playerID);
  MaintainBossVisibility();
 end
end

ResolveBossDefeat=function(playerID,unitID,source,epoch)
 local key=playerID..":"..unitID;
 local resolvedEpoch=Number(epoch,BossEpoch());
 local lastEpoch=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_LAST_DEFEATED_EPOCH"),-1);
 if Number(Game.GetProperty("LOTM_RESCUE_PHASE10_VICTORY"),0)==1
  or (Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_LAST_DEFEATED_OWNER"),-1)==playerID
   and Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_LAST_DEFEATED_UNIT"),-1)==unitID
   and (lastEpoch==resolvedEpoch or lastEpoch<0)) then return; end
 Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_LAST_DEFEATED_OWNER",playerID); Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_LAST_DEFEATED_UNIT",unitID);
 Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_LAST_DEFEATED_EPOCH",resolvedEpoch);
 local defeats=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_DEFEAT_COUNT"),0)+1;
 Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_DEFEAT_COUNT",defeats);
 local remaining=math.max(0,Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_PHASES_REMAINING"),1)-1);
 Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_PHASES_REMAINING",remaining);
 if remaining>0 then Game.SetProperty("LOTM_RESCUE_PHASE10_BOSS_RESPAWN_PENDING",1); Game.SetProperty(RoleKey("BOSS","STATE"),"PHASE_DEFEATED"); Log("boss phase defeated remaining="..remaining.." source="..source);
 else
  -- Use the established single-player victory finalizer after the second
  -- actual Boss death.  Multiplayer delivery is an optional outer layer;
  -- it must never decide whether the Boss was defeated.
  Log("boss defeat count="..defeats.." lives="..BOSS_LIVES.." action=GRANT_VICTORY");
  GrantVictory();
 end
 m_bossIntentionalDefeat[key]=nil;
end

local function CorrectNativeGodCombatDamage(key)
 local event=m_nativeDamageEvents[key]; local combat=m_bossCombatEvents[key]; if event==nil or combat==nil then return; end
 m_nativeDamageEvents[key]=nil; m_bossCombatEvents[key]=nil;
 local unit=UnitManager.GetUnit(combat.Player,combat.Unit);
 if unit==nil or unit:IsDead() or unit:IsDelayedDeath() then return; end
 if ProtectDescent(unit,"COMBAT_CORRECTION") then return; end
 -- Reject a stale heal/scripted-damage event.  The event paired with this
 -- combat must still describe the unit's current damage and must be damage.
 if event.New~=Number(unit:GetDamage(),0) or event.New<=event.Old then
  Log("god combat correction skipped role="..combat.Role.." unit="..key.." reason=STALE_OR_NON_DAMAGE_EVENT old="..event.Old.." new="..event.New.." current="..Number(unit:GetDamage(),0));
  return;
 end
 local observed=math.max(0,event.New-event.Old); local extra=math.max(0,combat.Desired-observed);
 if extra>0 then
  local maximum=Number(unit:GetMaxDamage(),100); local current=Number(unit:GetDamage(),0);
  if current+extra>=maximum then
   if combat.IsBoss then
    local applied=math.max(0,maximum-1-current);
    if applied>0 then m_nativeDamageCorrections[key]={Old=current,New=current+applied}; unit:ChangeDamage(applied); end
    KillBossAtTerminalDamage(unit,"NATIVE_GOD_COMBAT_CORRECTION");
   else
    pcall(UnitManager.Kill,unit);
   end
  else
   m_nativeDamageCorrections[key]={Old=current,New=current+extra}; unit:ChangeDamage(extra);
  end
 end
 Log("god combat damage correction role="..combat.Role.." unit="..key.." attack="..combat.Attack.." defense="..combat.Defense.." observed="..observed.." desired="..combat.Desired.." extra="..extra);
end

local function CorrectNetworkGodCombatDamage(unit,role,attack,defense,isBoss)
 if unit==nil or unit:IsDead() or unit:IsDelayedDeath() then return; end
 if ProtectDescent(unit,"COMBAT_CORRECTION") then return; end
 local playerID=unit:GetOwner(); local unitID=unit:GetID(); local key=UnitKey(playerID,unitID);
 local maximum=Number(unit:GetMaxDamage(),100); local current=Number(unit:GetDamage(),0);
 local desired=CombatStrengthDamage(attack,defense);
 -- A saturated custom result is lethal without needing any pre-combat damage
 -- baseline.  This restores a final god's intended kill against ordinary
 -- targets while keeping Boss deaths on the terminal-damage/epoch path below.
 if not isBoss and desired>=maximum then
  local ok,result=pcall(UnitManager.Kill,unit);
  Log("god combat synchronized saturated kill role="..role.." unit="..key.." attack="..attack.." defense="..defense.." desired="..desired.." max="..maximum.." ok="..tostring(ok).." result="..tostring(result));
  return;
 end
 -- Only the current Boss has a provably closed damage ledger here: every
 -- Phase-10 heal and scripted hit publishes a checkpoint.  Ordinary units and
 -- player/church gods can heal or take damage in other systems between fights,
 -- so their last checkpoint cannot be used as a pre-combat value without a
 -- stale-baseline overcorrection.
 if not isBoss then return; end
 local stored=unit:GetProperty(CONFIRMED_DAMAGE_PROPERTY);
 if stored==nil then
  PublishNetworkConfirmedDamage(unit);
  Log("god combat synchronized correction skipped role="..role.." unit="..key.." reason=CONFIRMED_DAMAGE_MISSING current="..current);
  return;
 end
 local confirmed=Number(stored,current);
 confirmed=math.max(0,math.min(maximum,confirmed));
 -- OnCombatOccurred is the synchronized owner of this path, but its ordering
 -- relative to the native damage publication is not assumed.  A non-positive
 -- delta is not evidence that native damage has landed, so fail closed instead
 -- of adding the full desired damage before the engine result.
 if current<=confirmed then
  PublishNetworkConfirmedDamage(unit);
  Log("god combat synchronized correction skipped role="..role.." unit="..key.." reason=NATIVE_DAMAGE_NOT_OBSERVED confirmed="..confirmed.." current="..current);
  return;
 end
 local observed=math.max(0,current-confirmed);
 local extra=math.max(0,desired-observed);
 if extra>0 then
  if current+extra>=maximum then
   if isBoss then
    local applied=math.max(0,maximum-1-current);
    if applied>0 then unit:ChangeDamage(applied); end
   else
    pcall(UnitManager.Kill,unit);
   end
  else
   unit:ChangeDamage(extra);
  end
 end
 PublishNetworkConfirmedDamage(UnitManager.GetUnit(playerID,unitID));
 Log("god combat synchronized correction role="..role.." unit="..key.." attack="..attack.." defense="..defense.." confirmed="..confirmed.." current="..current.." observed="..observed.." desired="..desired.." extra="..extra);
end

local function OnUnitDamageChanged(playerID,unitID,newDamage,oldDamage)
 if not Active() or Number(Game.GetProperty("LOTM_RESCUE_PHASE10_DESCENT_TRIGGERED"),0)~=1 then return; end
 if IsNetworkMultiplayer() then
  -- This event is locally published and is never evidence for network state.
  -- Synchronized OnCombatOccurred owns correction, checkpoints and Boss death.
  return;
 end
 local key=UnitKey(playerID,unitID); local newValue=Number(newDamage,0); local oldValue=Number(oldDamage,0);
 local correction=m_nativeDamageCorrections[key];
 if correction~=nil and correction.Old==oldValue and correction.New==newValue then
  m_nativeDamageCorrections[key]=nil;
  local bossOwner=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_OWNER"),-1); local bossUnit=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_UNIT"),-1);
  if playerID==bossOwner and unitID==bossUnit then KillBossAtTerminalDamage(UnitManager.GetUnit(playerID,unitID),"DAMAGE_EVENT"); end
  return;
 end
 if correction~=nil then m_nativeDamageCorrections[key]=nil; end
 m_nativeDamageEvents[key]={New=newValue,Old=oldValue}; CorrectNativeGodCombatDamage(key);
 local bossOwner=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_OWNER"),-1); local bossUnit=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_UNIT"),-1);
 if playerID==bossOwner and unitID==bossUnit then KillBossAtTerminalDamage(UnitManager.GetUnit(playerID,unitID),"DAMAGE_EVENT_TERMINAL"); end
end

local function OnCombat(attackerPlayerID,attackerUnitID,defenderPlayerID,defenderUnitID)
 if not Active() then return; end
 local networkGame=IsNetworkMultiplayer();
 local bossOwner=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_OWNER"),-1); local bossUnit=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_UNIT"),-1);
 local attacker=UnitManager.GetUnit(attackerPlayerID,attackerUnitID); local defender=UnitManager.GetUnit(defenderPlayerID,defenderUnitID);
 if attacker~=nil and defender~=nil and (IsGod(attacker) or IsGod(defender)) then
  local attack=EffectiveAttackStrength(attacker,0); local defense=EffectiveCombatStrength(defender,0);
  local ranged=math.max(Number(attacker:GetRangedCombat(),0),Number(attacker:GetBombardCombat(),0))>0;
  if networkGame then
   local retaliation=EffectiveCombatStrength(defender,0); local attackerDefense=EffectiveCombatStrength(attacker,0);
   local defenderIsBoss=defenderPlayerID==bossOwner and defenderUnitID==bossUnit;
   local attackerIsBoss=attackerPlayerID==bossOwner and attackerUnitID==bossUnit;
   if defenderIsBoss or IsGod(attacker) then CorrectNetworkGodCombatDamage(defender,"DEFENDER",attack,defense,defenderIsBoss); end
   if not ranged and (attackerIsBoss or IsGod(defender)) then CorrectNetworkGodCombatDamage(attacker,"ATTACKER_RETALIATION",retaliation,attackerDefense,attackerIsBoss); end
  else
   local defenderKey=UnitKey(defenderPlayerID,defenderUnitID);
   m_bossCombatEvents[defenderKey]={Player=defenderPlayerID,Unit=defenderUnitID,Role="DEFENDER",Attack=attack,Defense=defense,Desired=CombatStrengthDamage(attack,defense),IsBoss=defenderPlayerID==bossOwner and defenderUnitID==bossUnit};
   CorrectNativeGodCombatDamage(defenderKey);
   if not ranged then
    local retaliation=EffectiveCombatStrength(defender,0); local attackerDefense=EffectiveCombatStrength(attacker,0); local attackerKey=UnitKey(attackerPlayerID,attackerUnitID);
    m_bossCombatEvents[attackerKey]={Player=attackerPlayerID,Unit=attackerUnitID,Role="ATTACKER_RETALIATION",Attack=retaliation,Defense=attackerDefense,Desired=CombatStrengthDamage(retaliation,attackerDefense),IsBoss=attackerPlayerID==bossOwner and attackerUnitID==bossUnit};
    CorrectNativeGodCombatDamage(attackerKey);
   end
  end
 end
 if (attackerPlayerID==bossOwner and attackerUnitID==bossUnit) or (defenderPlayerID==bossOwner and defenderUnitID==bossUnit) then
  local epoch=BossEpoch(); local boss=UnitManager.GetUnit(bossOwner,bossUnit); local resolved=false;
  if networkGame and boss~=nil and not boss:IsDead() and not boss:IsDelayedDeath() then
   local killed=KillBossAtTerminalDamage(boss,"SYNCHRONIZED_COMBAT");
   if killed and ResolveBossDefeat~=nil then ResolveBossDefeat(bossOwner,bossUnit,"SYNCHRONIZED_COMBAT",epoch); end
   resolved=killed;
   boss=UnitManager.GetUnit(bossOwner,bossUnit);
  end
  if not resolved and (boss==nil or boss:IsDead() or boss:IsDelayedDeath()) then ResolveBossDefeat(bossOwner,bossUnit,networkGame and "SYNCHRONIZED_COMBAT" or "COMBAT",epoch); end
 end
end

local function ApplyRemoved(playerID,unitID,role,intentionalDefeat,epoch)
 local cached=m_roleUnits[role];
 if cached~=nil and cached:GetOwner()==playerID and cached:GetID()==unitID then m_roleUnits[role]=nil; end
 if role=="MINION" then Game.SetProperty(EngineKey(playerID,unitID),nil); return; end
 local currentRoleMatches=not IsNetworkMultiplayer()
  or (Number(Game.GetProperty(RoleKey(role,"OWNER")),-1)==playerID
   and Number(Game.GetProperty(RoleKey(role,"UNIT")),-1)==unitID
   and (role~="BOSS" or Number(epoch,BossEpoch())==BossEpoch()));
 if currentRoleMatches then Game.SetProperty(EngineKey(playerID,unitID),nil); end
 if currentRoleMatches then
  if ChurchGodMeta(role)~=nil then
   if Game.GetProperty(RoleKey(role,"STATE"))~="RESPAWN_PENDING" then ScheduleChurchGodRespawn(role); end
  elseif PlayerGodIDFromRole(role)~=nil then
   local used=Number(Game.GetProperty(RoleKey(role,"RESPAWN_USED")),0);
   if used>=1 then
    Game.SetProperty(RoleKey(role,"STATE"),"DEAD"); Game.SetProperty(RoleKey(role,"RESPAWN_TURN"),nil);
    Log("player god permanently destroyed role="..role.." turn="..WorldTurn());
   else
    local due=WorldTurn()+PLAYER_GOD_RESPAWN_DELAY;
    Game.SetProperty(RoleKey(role,"STATE"),"RESPAWN_PENDING"); Game.SetProperty(RoleKey(role,"RESPAWN_TURN"),due);
    Log("player god respawn scheduled role="..role.." deathTurn="..WorldTurn().." respawnTurn="..due.." remaining=1");
   end
  else Game.SetProperty(RoleKey(role,"STATE"),"DEAD"); end
 end
  if role=="BOSS" and Number(Game.GetProperty("LOTM_RESCUE_PHASE10_VICTORY"),0)~=1 then
  local key=playerID..":"..unitID;
  local resolvedEpoch=Number(epoch,BossEpoch());
  local alreadyResolved=Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_LAST_DEFEATED_OWNER"),-1)==playerID
   and Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_LAST_DEFEATED_UNIT"),-1)==unitID
   and Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_LAST_DEFEATED_EPOCH"),-1)==resolvedEpoch;
  -- A Boss removed from the map is a valid phase defeat.  Older logic treated
  -- a missed/late combat callback as abnormal removal, leaving phases stuck
  -- forever after the player visibly killed the Boss twice.
  ResolveBossDefeat(playerID,unitID,(intentionalDefeat==true or m_bossIntentionalDefeat[key]) and "ALLIED_SIEGE" or (alreadyResolved and "COMBAT_ALREADY_RESOLVED" or "COMBAT_REMOVAL"),epoch);
  elseif ChurchGodMeta(role)==nil then Log("god removed role="..role.." owner="..playerID.." unit="..unitID); end
   if role=="BOSS" and currentRoleMatches then MaintainBossVisibility(); end
end

local function OnRemoved(playerID,unitID)
 if not Active() then return; end
 local role=tostring(Game.GetProperty(EngineKey(playerID,unitID)) or ""); if role=="" then return; end
 if IsNetworkMultiplayer() then QueueNetworkRemoval(playerID,unitID,role); return; end
 ApplyRemoved(playerID,unitID,role,false,nil);
end

local function ProcessNetworkRemovals(playerID)
 if not IsNetworkMultiplayer() or not LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID) then return; end
 local currentTurn=Game.GetCurrentGameTurn(); local ready={}; local waiting={};
 for _,entry in ipairs(m_pendingNetworkRemovals) do
  if entry.QueuedTurn<currentTurn then ready[#ready+1]=entry; else waiting[#waiting+1]=entry; end
 end
 m_pendingNetworkRemovals=waiting;
 table.sort(ready,function(a,b)
  if a.QueuedTurn~=b.QueuedTurn then return a.QueuedTurn<b.QueuedTurn; end
  if a.PlayerID~=b.PlayerID then return a.PlayerID<b.PlayerID; end
  if a.UnitID~=b.UnitID then return a.UnitID<b.UnitID; end
  return a.Role<b.Role;
 end);
 for _,entry in ipairs(ready) do
  m_pendingNetworkRemovalKeys[entry.Key]=nil;
  local unit=UnitManager.GetUnit(entry.PlayerID,entry.UnitID); local liveRole=tostring(Game.GetProperty(EngineKey(entry.PlayerID,entry.UnitID)) or "");
  local staleBossEpoch=entry.Role=="BOSS" and entry.Epoch<BossEpoch();
  if (unit==nil or unit:IsDead() or unit:IsDelayedDeath() or staleBossEpoch) and (liveRole=="" or liveRole==entry.Role) then
   ApplyRemoved(entry.PlayerID,entry.UnitID,entry.Role,entry.Intentional,entry.Epoch);
  else
   Log("deferred removal discarded player="..entry.PlayerID.." unit="..entry.UnitID.." role="..entry.Role.." liveRole="..liveRole);
  end
 end
end

local function OnUnitMoveComplete(playerID,unitID,x,y)
 if IsNetworkMultiplayer() then return; end
 if not Active() or Number(Game.GetProperty("LOTM_RESCUE_PHASE10_DESCENT_TRIGGERED"),0)~=1 then return; end
 if playerID==Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_OWNER"),-1)
  and unitID==Number(Game.GetProperty("LOTM_RESCUE_PHASE10_BOSS_UNIT"),-1) then MaintainBossVisibility(); end
end

local function OnSynchronizedRefresh(playerID,isFirstTimeThisTurn)
 if IsNetworkMultiplayer() and isFirstTimeThisTurn~=false and LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID) then
  ProcessNetworkRemovals(playerID);
 end
 Refresh(playerID,isFirstTimeThisTurn);
end

LOTM_MP_TurnSync.Add(OnSynchronizedRefresh,"RescuePhase10");
Events.UnitRemovedFromMap.Add(OnRemoved);
Events.UnitMoveComplete.Add(OnUnitMoveComplete);
Events.UnitDamageChanged.Add(OnUnitDamageChanged);
GameEvents.OnCombatOccurred.Add(OnCombat);
LOTM_MP_TurnSync.RunStartup(function()
 if Active() then
  Game.SetProperty("LOTM_RESCUE_PHASE10_VERSION",VERSION); Game.SetProperty("LOTM_RESCUE_PHASE10_FINAL_TURN",FinalTurn()); Game.SetProperty("LOTM_RESCUE_PHASE10_BEST_TIER_THRESHOLD",BEST_TIER_THRESHOLD);
  Game.SetProperty("LOTM_RESCUE_PURIFICATION_DISPLAY_MAX",PURIFICATION_DISPLAY_MAX);
  for index=2,#TIERS do Game.SetProperty("LOTM_RESCUE_PHASE10_TIER_THRESHOLD_"..index,TIERS[index].Min); end
  if WorldTurn()>=FinalTurn() then
   BeginDescent();
   MigrateExhaustedBossVictory();
   ReconcileVictoryPresentation();
   if Number(Game.GetProperty("LOTM_RESCUE_PHASE10_DESCENT_TRIGGERED"),0)==1 and Number(Game.GetProperty("LOTM_RESCUE_PHASE10_VICTORY"),0)~=1 then
    MigrateChurchGodOwnership(); MigrateChurchGodRespawns(); local startupBoss=FindRole("BOSS"); if startupBoss==nil then startupBoss=SpawnBoss(); end PublishNetworkConfirmedDamage(startupBoss); MigrateBossPosition(); EnsureChurchGods(); for _,player in ipairs(HumanPlayers()) do EnsurePlayerGod(player); end RevealBattlefield(); GuideOuterGod(-1,true); GuideMinions(-1,true); GuideChurchGods(-1,true); MaintainBossVisibility();
   end
  end
 end
end,"RescuePhase10");
Log("loaded version="..VERSION.." finalTurns=costMultiplierScaled standard=150 tiers=0/500/1000/1500/2000/3000 strengths=999/888/777/666/555/444 playerGodBase=550 divineLegion=basePlusWarGodRelicOneTenth playerGodMobility=runtimeCombatAbove1000:+30 displayMax=3000 churchGodOwner=freeCities churchGodRespawn=5turnsOnce:v1 playerGodRespawn=5turnsOnce:v1 bossOwner=barbarianThenFreeCitiesFallback bossTargets=churchGodsCombatDamageThenNearestUnprotectedCity alliedSiege=humanTurn:v4 battlefieldReveal=6:v2 bossSight=radius6:persistent:v2 bossPosition=firstOrSecondRing:v5 spawnCommit=verifiedCandidateIteration exhaustedBossRecovery=v1 strength=binaryExact victory=rescuePropertyToFiraxisEndGameUI nativeConquestDisabled");
-- END POST_RC241_DELTA MODULE: Scripts/LOTM_RESCUE_Phase10.lua
end;

m_mp241Loaders["LOTM_RESCUE_Phase10A"] = function()
-- BEGIN RC241 MODULE: Scripts/LOTM_RESCUE_Phase10A.lua
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("MP.LOTM_RESCUE_Phase10A","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"MP.LOTM_RESCUE_Phase10A","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"MP.LOTM_RESCUE_Phase10A","GameEvents");
-- END RC342 STARTUP TRACE

-- Rescue Mode Phase 10A: synchronized endgame measurement and descent gate.
-- This deliberately does not generate gods/Boss units or invent balance values.
LOTM_RESCUE_Phase10A=LOTM_RESCUE_Phase10A or {};

local VERSION=3;
local PATH_NONE="NONE";
local GOD_UNIT_PROPERTY="LOTM_RESCUE_PHASE10_IS_GOD";
local MAX_BREAKDOWN_LENGTH=3500;
local RELIC_PROJECT="PROJECT_LOTM_RESCUE_WAR_GOD_RELIC";
local RELIC_UNLOCK_MODIFIER="LOTM_RESCUE_P10_ALLOW_WAR_GOD_RELIC";

local function Log(message) print("[LOTM_RESCUE][Phase10A] "..tostring(message)); end
local function Number(value,default) if value==nil then return default; end return tonumber(value) or default; end
local function Active() return Number(Game.GetProperty("LOTM_RESCUE_MODE"),0)==1; end
local function SetChanged(owner,key,value)
 if owner:GetProperty(key)~=value then owner:SetProperty(key,value); end
end

local function ChurchEnvoys(player,church)
 return math.max(0,Number(player:GetProperty("LOTM_CHURCH_"..church.."_ENVOYS"),0));
end

local function ReconcileWarGodRelic(player)
 if player==nil or not player:IsAlive() or not player:IsMajor() or not player:IsHuman() then return false; end
 local fool=ChurchEnvoys(player,"FOOL"); local night=ChurchEnvoys(player,"NIGHT"); local storm=ChurchEnvoys(player,"STORM");
 local qualified=fool>=6 and night>=6 and storm>=6;
 if qualified and Number(player:GetProperty("LOTM_RESCUE_WAR_GOD_RELIC_UNLOCK_ATTACHED"),0)~=1 then
  player:AttachModifierByID(RELIC_UNLOCK_MODIFIER);
  player:SetProperty("LOTM_RESCUE_WAR_GOD_RELIC_UNLOCK_ATTACHED",1);
  player:SetProperty("LOTM_RESCUE_WAR_GOD_RELIC_STATE","PROJECT_AVAILABLE");
  Log("warGodRelic unlocked player="..player:GetID().." envoys="..fool.."/"..night.."/"..storm);
 end
 SetChanged(player,"LOTM_RESCUE_WAR_GOD_RELIC_REQUIREMENT_MET",qualified and 1 or 0);
 return qualified;
end

function LOTM_RESCUE_Phase10A.OnChurchEnvoysChanged(playerID)
 if not Active() then return false; end
 return ReconcileWarGodRelic(Players[playerID]);
end

local function IsMilitaryCombatUnit(unit)
 if unit==nil or unit:IsDead() or unit:IsDelayedDeath() then return false; end
 if Number(unit:GetProperty(GOD_UNIT_PROPERTY),0)==1 then return false; end
 local info=GameInfo.Units[unit:GetType()]; if info==nil then return false; end
 local formation=tostring(info.FormationClass or "");
 if formation~="FORMATION_CLASS_LAND_COMBAT" and formation~="FORMATION_CLASS_NAVAL" and formation~="FORMATION_CLASS_AIR" then return false; end
 return math.max(Number(unit:GetCombat(),0),Number(unit:GetRangedCombat(),0),Number(unit:GetBombardCombat(),0))>0;
end

local function EffectiveStrength(unit)
 -- Runtime getters include the unit's current formation, promotions and
 -- persistent Ability/Modifier changes, while excluding combat-preview-only
 -- terrain, target, attack/defence and other contextual modifiers.
 return math.max(Number(unit:GetCombat(),0),Number(unit:GetRangedCombat(),0),Number(unit:GetBombardCombat(),0));
end

local function BuildBreakdown(player)
 local rows={}; local total=0; local count=0;
 for _,unit in player:GetUnits():Members() do
  if IsMilitaryCombatUnit(unit) then
   local strength=EffectiveStrength(unit); local info=GameInfo.Units[unit:GetType()];
   count=count+1; total=total+strength;
   table.insert(rows,{id=unit:GetID(),text=tostring(info.UnitType).."#"..tostring(unit:GetID()).."="..tostring(strength)});
  end
 end
 table.sort(rows,function(left,right) return left.id<right.id; end);
 local parts={}; for _,row in ipairs(rows) do table.insert(parts,row.text); end
 local breakdown=table.concat(parts,";");
 if string.len(breakdown)>MAX_BREAKDOWN_LENGTH then breakdown=string.sub(breakdown,1,MAX_BREAKDOWN_LENGTH)..";TRUNCATED"; end
 return total,count,breakdown,rows;
end

local function PublishSchedule()
 local worldTurn=LOTM_RESCUE_Phase5.WorldTurn(); local finalTurn=LOTM_RESCUE_Phase5.FinalTurn();
 SetChanged(Game,"LOTM_RESCUE_PHASE10A_VERSION",VERSION);
 SetChanged(Game,"LOTM_RESCUE_PHASE10A_WORLD_TURN",worldTurn);
 SetChanged(Game,"LOTM_RESCUE_PHASE10A_FINAL_TURN",finalTurn);
 SetChanged(Game,"LOTM_RESCUE_PHASE10A_TURNS_REMAINING",math.max(0,finalTurn-worldTurn));
 SetChanged(Game,"LOTM_RESCUE_PHASE10A_PURIFICATION_PREVIEW",Number(Game.GetProperty("GLOBAL_PURIFICATION"),0));
 if worldTurn>=finalTurn then
  SetChanged(Game,"LOTM_RESCUE_PHASE10A_DESCENT_DUE",1);
  SetChanged(Game,"LOTM_RESCUE_PHASE10A_STATE","BALANCE_DATA_REQUIRED");
  SetChanged(Game,"LOTM_RESCUE_PHASE10A_BOSS_GENERATED",0);
 else
  SetChanged(Game,"LOTM_RESCUE_PHASE10A_DESCENT_DUE",0);
  SetChanged(Game,"LOTM_RESCUE_PHASE10A_STATE","MEASUREMENT_READY");
 end
 return worldTurn,finalTurn;
end

local function RefreshPlayer(playerID)
 if not Active() then return false; end
 local player=Players[playerID];
 if player==nil or not player:IsAlive() or not player:IsMajor() or not player:IsHuman() then return false; end
 ReconcileWarGodRelic(player);
 local rawTotal,count,breakdown,rows=BuildBreakdown(player);
 local skillReady=Number(player:GetProperty("LOTM_RESCUE_WAR_GOD_RELIC_COMPLETED"),0)==1;
 local total=skillReady and math.floor(rawTotal/10) or 0;
 local previous=Number(player:GetProperty("LOTM_RESCUE_PHASE10A_DIVINE_LEGION_TOTAL"),-1);
 local path=tostring(player:GetProperty("LOTM_RP_PATH") or PATH_NONE);
 local sequence=Number(player:GetProperty("LOTM_RP_SEQUENCE"),9);
 local qualified=path~=PATH_NONE and sequence<=0;
 SetChanged(player,"LOTM_RESCUE_PHASE10A_DIVINE_LEGION_TOTAL",total);
 SetChanged(player,"LOTM_RESCUE_PHASE10A_DIVINE_LEGION_RAW_TOTAL",rawTotal);
 SetChanged(player,"LOTM_RESCUE_PHASE10A_DIVINE_LEGION_INHERIT_DIVISOR",10);
 SetChanged(player,"LOTM_RESCUE_PHASE10A_DIVINE_LEGION_COUNT",count);
 SetChanged(player,"LOTM_RESCUE_PHASE10A_DIVINE_LEGION_BREAKDOWN",breakdown);
 SetChanged(player,"LOTM_RESCUE_PHASE10A_DIVINE_LEGION_QUALIFIED",qualified and skillReady and 1 or 0);
 SetChanged(player,"LOTM_RESCUE_PHASE10A_PLAYER_GOD_STATE",not qualified and "NOT_SEQUENCE_ZERO" or skillReady and "DIVINE_LEGION_READY" or "WAR_GOD_RELIC_REQUIRED");
 if previous~=total then
  Log("divineLegion player="..tostring(playerID).." path="..path.." sequence="..tostring(sequence).." rawTotal="..tostring(rawTotal).." inherited="..tostring(total).." divisor=10 skillReady="..tostring(skillReady).." units="..tostring(count));
  for _,row in ipairs(rows) do Log("divineLegionUnit player="..tostring(playerID).." "..row.text); end
 end
 return true;
end

local function OnCityProjectCompleted(playerID,cityID,projectID)
 if not Active() then return; end
 local project=GameInfo.Projects[projectID]; if project==nil or project.ProjectType~=RELIC_PROJECT then return; end
 local player=Players[playerID]; if player==nil or not ReconcileWarGodRelic(player) then
  Log("warGodRelic completion rejected player="..tostring(playerID).." reason=ENVOYS_BELOW_6"); return;
 end
 if Number(player:GetProperty("LOTM_RESCUE_WAR_GOD_RELIC_COMPLETED"),0)~=1 then
  player:SetProperty("LOTM_RESCUE_WAR_GOD_RELIC_COMPLETED",1);
  player:SetProperty("LOTM_RESCUE_WAR_GOD_RELIC_STATE","DIVINE_LEGION_GRANTED");
  player:SetProperty("LOTM_RESCUE_WAR_GOD_RELIC_COMPLETED_TURN",LOTM_RESCUE_Phase5.WorldTurn());
  Log("warGodRelic completed player="..playerID.." city="..cityID.." divineLegion=true");
 end
 RefreshPlayer(playerID);
end

function LOTM_RESCUE_Phase10A.RefreshAll()
 if not Active() then return false; end
 local worldTurn,finalTurn=PublishSchedule();
 for _,player in ipairs(PlayerManager.GetAliveMajors()) do if player:IsHuman() then RefreshPlayer(player:GetID()); end end
 if worldTurn>=finalTurn and Number(Game.GetProperty("LOTM_RESCUE_PHASE10A_GATE_LOGGED"),0)~=1 then
  Game.SetProperty("LOTM_RESCUE_PHASE10A_GATE_LOGGED",1);
  Log("descentGate worldTurn="..tostring(worldTurn).." finalTurn="..tostring(finalTurn)
   .." purification="..tostring(Number(Game.GetProperty("GLOBAL_PURIFICATION"),0))
   .." godsGenerated=false bossGenerated=false reason=balance_data_required");
 end
 return true;
end

Events.PlayerTurnActivated.Add(function(playerID,isFirstTimeThisTurn)
 if not Active() or isFirstTimeThisTurn==false then return; end
 PublishSchedule(); RefreshPlayer(playerID);
end);
Events.CityProjectCompleted.Add(OnCityProjectCompleted);
LOTM_RESCUE_Phase10A.RefreshAll();
Log("loaded version="..VERSION.." measurement=true scaledSchedule=costMultiplier standardFinalTurn=150 divineLegion=warGodRelicOneTenthBonus changedWritesOnly=true godGeneration=false bossGeneration=false bossFormula=false");
-- END RC241 MODULE: Scripts/LOTM_RESCUE_Phase10A.lua
end;

m_mp241Loaders["LOTM_RESCUE_Phase5"] = function()
-- BEGIN POST_RC241_DELTA MODULE: Scripts/LOTM_RESCUE_Phase5.lua
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("MP.LOTM_RESCUE_Phase5","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"MP.LOTM_RESCUE_Phase5","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"MP.LOTM_RESCUE_Phase5","GameEvents");
-- END RC342 STARTUP TRACE

-- Rescue Mode Phase 5: synchronized world-period configuration and aggressive
-- barbarian-camp pressure. All mutations and random choices stay in Gameplay.
LOTM_RESCUE_Phase5=LOTM_RESCUE_Phase5 or {};

local VERSION=26;
local CAMP=GameInfo.Improvements.IMPROVEMENT_BARBARIAN_CAMP.Index;
local NO_TEAM=-1;
local STANDARD_FINAL_TURN=150;
local WORKSHOP_CHANCE={80,85,90,95,100};
local WORKSHOP_LEVEL_CHANCE={
	{85,15,0},
	{60,30,10},
	{35,40,25},
	{15,40,45},
	{5,20,75}
};
local MONSTER_CHANCE={80,90,100,100,100};
local MONSTER_PER_WORKSHOP={6,8,10,12,16};
local MONSTER_COOLDOWN={3,2,1,1,1};
local MONSTER_BURST={2,2,3,3,4};
local MONSTER_TURN_ATTEMPTS={6,8,10,12,15};
local PERIOD_STRENGTH={0,10,20,30,40};
local GLOBAL_CAP_MULTIPLIER={2,2,3,3,4};
local MONSTER_GLOBAL_CAP={40,50,60,70,80};
local BONUS_CAMP_LIMIT={20,23,26,29,32};
local CAMP_TARGET_PER_MAJOR=6;
local CAMP_TURN_FLOW=10;
local MIN_CITY_DISTANCE=4;
local MIN_CAMP_DISTANCE=7;
local LAST_TURN_KEY="LOTM_RESCUE_PHASE5_LAST_BONUS_CAMP_TURN";
local MAP_SCALE_PERCENT={
 MAPSIZE_DUEL=25,
 MAPSIZE_TINY=50,
 MAPSIZE_SMALL=75,
 MAPSIZE_STANDARD=100,
 MAPSIZE_LARGE=125,
 MAPSIZE_HUGE=150
};
local DIRECT_PERIOD_MULTIPLIER={1.00,1.25,1.50,1.75,2.00};
local EARLY_MONSTER_RATE_END_TURN=20;
local EARLY_MONSTER_RATE_PERCENT=50;
local LATE_MONSTER_RATE_PERCENT=75;

local function Log(message) print("[LOTM_RESCUE][Phase5] "..tostring(message)); end
local function Number(value,default) if value==nil then return default; end return tonumber(value) or default; end
local function PerfNow()
	return LOTM_UnitAddedPerf~=nil and LOTM_UnitAddedPerf.BeginSection~=nil
		and LOTM_UnitAddedPerf.BeginSection() or nil;
end
local function PerfElapsed(started)
	return LOTM_UnitAddedPerf~=nil and LOTM_UnitAddedPerf.ElapsedSince~=nil
		and LOTM_UnitAddedPerf.ElapsedSince(started) or 0;
end

function LOTM_RESCUE_Phase5.IsActive()
	return Number(Game.GetProperty("LOTM_RESCUE_MODE"),0)==1;
end

function LOTM_RESCUE_Phase5.WorldTurn()
	local start=Number(GameConfiguration.GetStartTurn~=nil and GameConfiguration.GetStartTurn() or 0,0);
	return math.max(1,Game.GetCurrentGameTurn()-start+1);
end

function LOTM_RESCUE_Phase5.FinalTurn()
	local speedType=GameConfiguration.GetGameSpeedType();
	local speed=GameInfo.GameSpeeds[speedType];
	local multiplier=speed~=nil and Number(speed.CostMultiplier,100) or 100;
	return math.max(1,math.floor(STANDARD_FINAL_TURN*multiplier/100+0.5));
end

function LOTM_RESCUE_Phase5.PeriodForTurn(worldTurn)
	local finalTurn=LOTM_RESCUE_Phase5.FinalTurn(); local activeTurns=math.max(5,finalTurn-1);
	local turn=math.max(1,Number(worldTurn,1));
	if turn>=finalTurn then return 5; end
	for period=1,4 do if turn<=math.floor(period*activeTurns/5) then return period; end end
	return 5;
end

function LOTM_RESCUE_Phase5.CurrentPeriod()
	if not LOTM_RESCUE_Phase5.IsActive() then return 1; end
	return LOTM_RESCUE_Phase5.PeriodForTurn(LOTM_RESCUE_Phase5.WorldTurn());
end

function LOTM_RESCUE_Phase5.MapScalePercent()
 local mapInfo=GameInfo.Maps[Map.GetMapSize()];
 local mapSizeType=mapInfo~=nil and mapInfo.MapSizeType or "MAPSIZE_STANDARD";
 local configured=MAP_SCALE_PERCENT[mapSizeType];
 if configured~=nil then return configured,mapSizeType; end
 -- Custom map scripts retain a deterministic fallback based on the standard
 -- 84x54 map area.  Never let a malformed map shrink the stream below one.
 local plotCount=Map.GetPlotCount();
 return math.max(25,math.floor((tonumber(plotCount) or 4536)*100/4536+0.5)),mapSizeType;
end

function LOTM_RESCUE_Phase5.ScaleRefreshCount(base)
 local percent=LOTM_RESCUE_Phase5.MapScalePercent();
 return math.max(1,math.floor((tonumber(base) or 0)*percent/100+0.5));
end

function LOTM_RESCUE_Phase5.MonsterSpawnPercent(worldTurn)
	local turn=math.max(1,Number(worldTurn,LOTM_RESCUE_Phase5.WorldTurn()));
	return turn<=EARLY_MONSTER_RATE_END_TURN and EARLY_MONSTER_RATE_PERCENT or LATE_MONSTER_RATE_PERCENT;
end

-- Reduce every rescue monster stream without changing camps, caps, tiers or
-- combat strength.  A persisted per-channel remainder gives the requested
-- long-run 50%/75% rate even when a burst contains an odd number of units.
-- Reset the remainder at the turn-20 boundary so neither phase borrows rate
-- from the other.  All callers execute from synchronized Gameplay events.
function LOTM_RESCUE_Phase5.ScaleMonsterSpawnCount(base,channel,worldTurn)
	if not LOTM_RESCUE_Phase5.IsActive() then return math.max(0,math.floor(Number(base,0))); end
	local raw=math.max(0,math.floor(Number(base,0)));
	local percent=LOTM_RESCUE_Phase5.MonsterSpawnPercent(worldTurn);
	local normalized=string.gsub(string.upper(tostring(channel or "GENERIC")),"[^A-Z0-9_]","_");
	local prefix="LOTM_RESCUE_MONSTER_RATE_"..normalized;
	local previousPercent=Number(Game.GetProperty(prefix.."_PERCENT"),-1);
	local carry=previousPercent==percent and Number(Game.GetProperty(prefix.."_REMAINDER"),0) or 0;
	local numerator=raw*percent+carry;
	local scaled=math.floor(numerator/100);
	Game.SetProperty(prefix.."_PERCENT",percent);
	Game.SetProperty(prefix.."_REMAINDER",numerator-scaled*100);
	Game.SetProperty(prefix.."_RAW",raw);
	Game.SetProperty(prefix.."_SCALED",scaled);
	return scaled;
end

function LOTM_RESCUE_Phase5.WorkshopChance()
	return WORKSHOP_CHANCE[LOTM_RESCUE_Phase5.CurrentPeriod()];
end
function LOTM_RESCUE_Phase5.WorkshopLevelChances(period)
	local row=WORKSHOP_LEVEL_CHANCE[math.max(1,math.min(5,Number(period,LOTM_RESCUE_Phase5.CurrentPeriod())))];
	return row[1],row[2],row[3];
end
function LOTM_RESCUE_Phase5.MonsterChance()
	return MONSTER_CHANCE[LOTM_RESCUE_Phase5.CurrentPeriod()];
end
function LOTM_RESCUE_Phase5.MonsterPerWorkshopCap()
	return MONSTER_PER_WORKSHOP[LOTM_RESCUE_Phase5.CurrentPeriod()];
end
function LOTM_RESCUE_Phase5.MonsterCooldown()
	return MONSTER_COOLDOWN[LOTM_RESCUE_Phase5.CurrentPeriod()];
end
function LOTM_RESCUE_Phase5.MonsterBurst()
	return MONSTER_BURST[LOTM_RESCUE_Phase5.CurrentPeriod()];
end
function LOTM_RESCUE_Phase5.MonsterTurnAttempts()
	local base=MONSTER_TURN_ATTEMPTS[LOTM_RESCUE_Phase5.CurrentPeriod()];
	local scaled=LOTM_RESCUE_Difficulty~=nil and LOTM_RESCUE_Difficulty.Scale(base,LOTM_RESCUE_Difficulty.SpawnPercent()) or base;
	if Number(Game.GetProperty("LOTM_RESCUE_ARTIFACT_FRENZY_ACTIVE"),0)==1 then scaled=scaled-2; end
	scaled=math.max(1,scaled);
	return LOTM_RESCUE_Phase5.ScaleRefreshCount(scaled);
end
function LOTM_RESCUE_Phase5.DirectSpawnCount()
 local base=LOTM_RESCUE_Difficulty~=nil and LOTM_RESCUE_Difficulty.DirectSpawnBase~=nil
  and LOTM_RESCUE_Difficulty.DirectSpawnBase() or 6;
 local period=LOTM_RESCUE_Phase5.CurrentPeriod();
 local multiplier=DIRECT_PERIOD_MULTIPLIER[period] or 1;
 return LOTM_RESCUE_Phase5.ScaleRefreshCount(math.floor(base*multiplier+0.5));
end
function LOTM_RESCUE_Phase5.BirthStrengthBonus()
	return PERIOD_STRENGTH[LOTM_RESCUE_Phase5.CurrentPeriod()];
end
function LOTM_RESCUE_Phase5.GlobalCapMultiplier()
	return GLOBAL_CAP_MULTIPLIER[LOTM_RESCUE_Phase5.CurrentPeriod()];
end
function LOTM_RESCUE_Phase5.MonsterGlobalCap()
	local base=MONSTER_GLOBAL_CAP[LOTM_RESCUE_Phase5.CurrentPeriod()];
	local scaled=LOTM_RESCUE_Difficulty~=nil and LOTM_RESCUE_Difficulty.Scale(base,LOTM_RESCUE_Difficulty.CapPercent()) or base;
	if Number(Game.GetProperty("LOTM_RESCUE_ARTIFACT_FRENZY_ACTIVE"),0)==1 then scaled=scaled-3; end
	scaled=math.max(1,scaled);
	return LOTM_RESCUE_Phase5.ScaleRefreshCount(scaled);
end
function LOTM_RESCUE_Phase5.BonusCampLimit()
	return BONUS_CAMP_LIMIT[LOTM_RESCUE_Phase5.CurrentPeriod()];
end
function LOTM_RESCUE_Phase5.TargetCampCount()
	return #PlayerManager.GetAliveMajors()*CAMP_TARGET_PER_MAJOR;
end

function LOTM_RESCUE_Phase5.AnchorMajorID()
	local anchor=nil;
	for _,player in ipairs(PlayerManager.GetAliveMajors()) do
		local playerID=player:GetID();
		if anchor==nil or playerID<anchor then anchor=playerID; end
	end
	return anchor;
end

local function ReservedIndices()
	local result={};
	for _,zone in ipairs({"CENTER","FOOL","NIGHT","STORM"}) do
		local csv=tostring(Game.GetProperty("LOTM_RESCUE_"..zone.."_TERRITORY") or "");
		for value in string.gmatch(csv,"[^,]+") do local index=Number(value,-1); if index>=0 then result[index]=true; end end
	end
	return result;
end

local function IsReserved(plot,reserved)
	if plot:GetProperty("LOTM_RESCUE_ZONE_KIND")~=nil then return true; end
	return reserved[plot:GetIndex()]==true;
end

local function MajorVisibilities()
	local result={};
	for _,player in ipairs(PlayerManager.GetAliveMajors()) do
		local visibility=PlayersVisibility[player:GetID()];
		if visibility~=nil then result[#result+1]=visibility; end
	end
	return result;

end
local function VisibleToAnyMajor(plotIndex,visibilities)
	for _,visibility in ipairs(visibilities) do if visibility:IsVisible(plotIndex) then return true; end end
	return false;
end

local function FarEnough(plotIndex,indices,distance)
	for _,otherIndex in ipairs(indices) do
		if Map.GetPlotDistance(plotIndex,otherIndex)<distance then return false; end
	end
	return true;
end

local function ScanOccupied()
	local camps={}; local cities={};
	for index=0,Map.GetPlotCount()-1 do
		local plot=Map.GetPlotByIndex(index);
		if plot~=nil then
			if plot:GetImprovementType()==CAMP then camps[#camps+1]=index; end
			if plot:IsCity() then cities[#cities+1]=index; end
		end
	end
	return camps,cities;
end

local function IsLegalCandidate(plot,camps,cities,reserved,visibilities)
	if plot==nil or plot:IsWater() or plot:IsImpassable() or plot:GetOwner()~=-1 then return false; end
	if plot:GetDistrictType()~=-1 or plot:GetImprovementType()~=-1 or plot:GetUnitCount()>0 then return false; end
	if IsReserved(plot,reserved) or VisibleToAnyMajor(plot:GetIndex(),visibilities) then return false; end
	if not FarEnough(plot:GetIndex(),cities,MIN_CITY_DISTANCE) or not FarEnough(plot:GetIndex(),camps,MIN_CAMP_DISTANCE) then return false; end
	return ImprovementBuilder.CanHaveImprovement(plot,CAMP,NO_TEAM);
end

local function Candidates(camps,cities,reserved,visibilities)
	local result={};
	for index=0,Map.GetPlotCount()-1 do
		local plot=Map.GetPlotByIndex(index);
		if IsLegalCandidate(plot,camps,cities,reserved,visibilities) then result[#result+1]=plot; end
	end
	table.sort(result,function(a,b) return a:GetIndex()<b:GetIndex(); end);
	return result;
end

local function IsCoastal(plot)
	for direction=0,5 do local adjacent=Map.GetAdjacentPlot(plot:GetX(),plot:GetY(),direction); if adjacent~=nil and adjacent:IsWater() then return true; end end
	return false;
end

local function FeatureName(plot)
	local row=GameInfo.Features[plot:GetFeatureType()]; return row~=nil and row.FeatureType or "";
end

local function HasNearbyHorses(plot)
	local horse=GameInfo.Resources.RESOURCE_HORSES; if horse==nil then return false; end
	for dx=-3,3 do for dy=-3,3 do
		local nearby=Map.GetPlotXYWithRangeCheck(plot:GetX(),plot:GetY(),dx,dy,3);
		if nearby~=nil and nearby:GetResourceType()==horse.Index then return true; end
	end end
	return false;
end

local function ExistingTribe(typeName)
	local row=GameInfo.BarbarianTribes[typeName]; return row~=nil and row or nil;
end

local function SelectTribe(plot)
	local clans=ExistingTribe("TRIBE_CLAN_MELEE_OPEN")~=nil;
	local coastal=IsCoastal(plot); local feature=FeatureName(plot); local horses=HasNearbyHorses(plot);
	local typeName=nil;
	if clans then
		if coastal then typeName="TRIBE_CLAN_NAVAL";
		elseif horses and feature=="FEATURE_JUNGLE" then typeName="TRIBE_CLAN_CAVALRY_JUNGLE";
		elseif horses and not plot:IsHills() then typeName="TRIBE_CLAN_CAVALRY_OPEN";
		elseif feature=="FEATURE_FOREST" or feature=="FEATURE_JUNGLE" then typeName="TRIBE_CLAN_MELEE_FOREST";
		elseif plot:IsHills() then typeName="TRIBE_CLAN_MELEE_HILLS";
		else typeName="TRIBE_CLAN_MELEE_OPEN"; end
	else
		if coastal then typeName="TRIBE_NAVAL"; elseif horses then typeName="TRIBE_CAVALRY"; else typeName="TRIBE_MELEE"; end
	end
	local row=ExistingTribe(typeName);
	if row==nil then row=ExistingTribe(coastal and "TRIBE_NAVAL" or (horses and "TRIBE_CAVALRY" or "TRIBE_MELEE")); end
	return row,typeName,clans;
end

local function RecordAttempt(worldTurn,attempts,successes,reason,plots,current,target,candidates)
	Game.SetProperty(LAST_TURN_KEY,worldTurn);
	Game.SetProperty("LOTM_RESCUE_PHASE5_BONUS_CAMP_ATTEMPTS",attempts);
	Game.SetProperty("LOTM_RESCUE_PHASE5_BONUS_CAMP_SUCCESSES",successes);
	Game.SetProperty("LOTM_RESCUE_PHASE5_BONUS_CAMP_FAILURE",reason);
	Game.SetProperty("LOTM_RESCUE_PHASE5_BONUS_CAMP_PLOTS",table.concat(plots,","));
	Game.SetProperty("LOTM_RESCUE_PHASE5_BONUS_CAMP_CURRENT",current);
	Game.SetProperty("LOTM_RESCUE_PHASE5_BONUS_CAMP_TARGET",target);
	Game.SetProperty("LOTM_RESCUE_PHASE5_BONUS_CAMP_CANDIDATES",candidates);
end

local function RemoveNearCandidates(candidates,plotIndex)
	local result={};
	for _,candidate in ipairs(candidates) do
		if candidate:GetIndex()~=plotIndex and Map.GetPlotDistance(candidate:GetIndex(),plotIndex)>=MIN_CAMP_DISTANCE then result[#result+1]=candidate; end
	end
	return result;
end

local function CreateCamp(manager,plot)
	local tribeRow,typeName,clans=SelectTribe(plot);
	if tribeRow==nil then return false,"TRIBE_TYPE_MISSING",typeName; end
	local ok,tribeIndex=pcall(function() return manager:CreateTribeOfType(tribeRow.Index,plot:GetIndex()); end);
	if not ok or tribeIndex==nil or tribeIndex<0 then return false,"CREATE_TRIBE_FAILED",typeName; end
	local defenderTag=tribeRow.DefenderTag or "CLASS_ANTI_CAVALRY";
	local unitOK,unitResult=pcall(function() return manager:CreateTribeUnits(tribeIndex,defenderTag,1,plot:GetIndex(),1); end);
	if not unitOK then return false,"CREATE_DEFENDER_FAILED",typeName; end
	if plot:GetImprovementType()~=CAMP then return false,"CAMP_NOT_CREATED",typeName; end
	local normalRemoved=0;
	if LOTM_WORLD_Barbarians~=nil and LOTM_WORLD_Barbarians.CleanupRescueCampUnits~=nil then
		normalRemoved=LOTM_WORLD_Barbarians.CleanupRescueCampUnits(plot);
	end
	Log("bonus camp plot="..plot:GetIndex().." tribe="..tostring(typeName).." tribeIndex="..tostring(tribeIndex)
		.." defenderTag="..tostring(defenderTag).." defenderResult="..tostring(unitResult).." normalRemoved="..normalRemoved.." clans="..tostring(clans));
	return true,"NONE",typeName;
end

function LOTM_RESCUE_Phase5.TrySupplementCamps(playerID)
	if not LOTM_RESCUE_Phase5.IsActive() then return; end
	local anchor=LOTM_RESCUE_Phase5.AnchorMajorID();
	if anchor==nil or playerID~=anchor then return; end
	local worldTurn=LOTM_RESCUE_Phase5.WorldTurn();
	if Number(Game.GetProperty(LAST_TURN_KEY),-1)==worldTurn then Log("bonus camps skipped duplicate worldTurn="..worldTurn); return; end
	-- Claim the turn before any random call so save/reload or duplicate callbacks cannot reroll it.
	RecordAttempt(worldTurn,0,0,"NONE",{},0,LOTM_RESCUE_Phase5.TargetCampCount(),0);
	local manager=Game.GetBarbarianManager~=nil and Game.GetBarbarianManager() or nil;
	if manager==nil or manager.CreateTribeOfType==nil or manager.CreateTribeUnits==nil then
		RecordAttempt(worldTurn,0,0,"API_MISSING",{},0,LOTM_RESCUE_Phase5.TargetCampCount(),0); Log("bonus camps stopped reason=API_MISSING"); return;
	end
	local camps,cities=ScanOccupied(); local current=#camps; local target=LOTM_RESCUE_Phase5.TargetCampCount();
	-- Resource 181 deliberately supplies a stable high-flow stream instead of
	-- filling the whole enlarged target in one frame. Firaxis natural spawning
	-- remains enabled in parallel, so the actual same-turn total may exceed 10.
	local requested=math.min(CAMP_TURN_FLOW,math.max(0,target-current));
	local candidates={}; local initialLegalCount=0;
	if requested>0 then candidates=Candidates(camps,cities,ReservedIndices(),MajorVisibilities()); initialLegalCount=#candidates; end
	local attempts=0; local successes=0; local generated={}; local reason=requested==0 and "TARGET_MET" or (#candidates==0 and "NO_LEGAL_PLOT" or "NONE");
	for slot=1,requested do
		if #candidates==0 then reason="NO_LEGAL_PLOT"; break; end
		local stableLabel="LOTM Rescue Phase5 bonus camp:worldTurn="..tostring(worldTurn)
			..":slot="..tostring(slot)..":candidates="..tostring(#candidates);
		local choice=LOTM_MP_TurnSync.Random(#candidates,stableLabel,"LOTM Rescue Phase5 bonus camp")+1;
		local plot=candidates[choice]; attempts=attempts+1;
		local created,failure=CreateCamp(manager,plot);
		if not created then reason=failure; break; end
		successes=successes+1; generated[#generated+1]=tostring(plot:GetIndex()); camps[#camps+1]=plot:GetIndex();
		candidates=RemoveNearCandidates(candidates,plot:GetIndex());
	end
	RecordAttempt(worldTurn,attempts,successes,reason,generated,current,target,initialLegalCount);
	Game.SetProperty("LOTM_RESCUE_PHASE5_BONUS_CAMP_CANDIDATES_REMAINING",#candidates);
	Log("bonus camps worldTurn="..worldTurn.." period="..LOTM_RESCUE_Phase5.CurrentPeriod().." current="..current
		.." target="..target.." flow="..CAMP_TURN_FLOW.." periodCap="..LOTM_RESCUE_Phase5.BonusCampLimit().." requested="..requested
		.." candidatesInitial="..initialLegalCount.." candidatesRemaining="..#candidates.." scans=1 attempts="..attempts.." successes="..successes.." reason="..reason
		.." plots="..table.concat(generated,","));
end

function LOTM_RESCUE_Phase5.RefreshState()
	if not LOTM_RESCUE_Phase5.IsActive() then return; end
	local period=LOTM_RESCUE_Phase5.CurrentPeriod(); local previous=Number(Game.GetProperty("LOTM_RESCUE_PHASE5_PERIOD"),0);
	local low,mid,high=LOTM_RESCUE_Phase5.WorkshopLevelChances(period);
	Game.SetProperty("LOTM_RESCUE_PHASE5_VERSION",VERSION);
	Game.SetProperty("LOTM_RESCUE_PHASE5_STATE","READY");
	Game.SetProperty("LOTM_RESCUE_PHASE5_PERIOD",period);
	Game.SetProperty("LOTM_RESCUE_PHASE5_WORLD_TURN",LOTM_RESCUE_Phase5.WorldTurn());
	Game.SetProperty("LOTM_RESCUE_PHASE5_FINAL_TURN",LOTM_RESCUE_Phase5.FinalTurn());
	Game.SetProperty("LOTM_RESCUE_PHASE5_BONUS_CAMP_LIMIT",LOTM_RESCUE_Phase5.BonusCampLimit());
	Game.SetProperty("LOTM_RESCUE_PHASE5_CAMP_TURN_FLOW",CAMP_TURN_FLOW);
	Game.SetProperty("LOTM_RESCUE_PHASE5_MONSTER_GLOBAL_CAP",LOTM_RESCUE_Phase5.MonsterGlobalCap());
	Game.SetProperty("LOTM_RESCUE_PHASE5_MONSTER_TURN_ATTEMPTS",LOTM_RESCUE_Phase5.MonsterTurnAttempts());
	Game.SetProperty("LOTM_RESCUE_PHASE5_DIRECT_SPAWN_COUNT",LOTM_RESCUE_Phase5.DirectSpawnCount());
	Game.SetProperty("LOTM_RESCUE_PHASE5_MONSTER_SPAWN_PERCENT",LOTM_RESCUE_Phase5.MonsterSpawnPercent());
	local mapScale,mapSizeType=LOTM_RESCUE_Phase5.MapScalePercent();
	Game.SetProperty("LOTM_RESCUE_PHASE5_MAP_SCALE_PERCENT",mapScale);
	Game.SetProperty("LOTM_RESCUE_PHASE5_MAP_SIZE_TYPE",mapSizeType);
	Game.SetProperty("LOTM_RESCUE_PHASE5_BONUS_CAMP_TARGET",LOTM_RESCUE_Phase5.TargetCampCount());
	Game.SetProperty("LOTM_RESCUE_PHASE5_WORKSHOP_LEVEL_CHANCE",low..","..mid..","..high);
	local phase=Number(Game.GetProperty("LOTM_RESCUE_PHASE"),0); if phase<5 then Game.SetProperty("LOTM_RESCUE_PHASE",5); end
	if previous~=period then
		Log("period="..period.." worldTurn="..LOTM_RESCUE_Phase5.WorldTurn().." finalTurn="..LOTM_RESCUE_Phase5.FinalTurn()
			.." workshopChance="..WORKSHOP_CHANCE[period].." workshopLevels="..low.."/"..mid.."/"..high
			.." monsterChance="..MONSTER_CHANCE[period].." perWorkshop="..MONSTER_PER_WORKSHOP[period]
			.." cooldown="..MONSTER_COOLDOWN[period].." burst="..MONSTER_BURST[period].." strength="..PERIOD_STRENGTH[period]
			.." turnAttempts="..LOTM_RESCUE_Phase5.MonsterTurnAttempts().." baseTurnAttempts="..MONSTER_TURN_ATTEMPTS[period]
			.." directSpawn="..LOTM_RESCUE_Phase5.DirectSpawnCount()
			.." capMultiplier="..GLOBAL_CAP_MULTIPLIER[period].." monsterGlobalCap="..LOTM_RESCUE_Phase5.MonsterGlobalCap().." baseMonsterGlobalCap="..MONSTER_GLOBAL_CAP[period].." bonusCampLimit="..BONUS_CAMP_LIMIT[period]
			.." mapScalePercent="..LOTM_RESCUE_Phase5.MapScalePercent()
			.." targetCamps="..LOTM_RESCUE_Phase5.TargetCampCount());
	end
end

local function OnPlayerTurnStarted(playerID)
	if not LOTM_RESCUE_Phase5.IsActive() or playerID~=LOTM_RESCUE_Phase5.AnchorMajorID() then return; end
	if LOTM_WORLD_Barbarians~=nil and LOTM_WORLD_Barbarians.CleanupRescueUnits~=nil then
		LOTM_WORLD_Barbarians.CleanupRescueUnits();
	end
	if not LOTM_MP_TurnSync.IsNetworkGame() and LOTM_WORLD_Barbarians~=nil
		and LOTM_WORLD_Barbarians.ProcessRescueUnitCandidates~=nil then
		LOTM_WORLD_Barbarians.ProcessRescueUnitCandidates({});
	end
	local totalStarted=PerfNow(); local sectionStarted=totalStarted;
	LOTM_RESCUE_Phase5.RefreshState();
	local refreshMs=PerfElapsed(sectionStarted); sectionStarted=PerfNow();
	LOTM_RESCUE_Phase5.TrySupplementCamps(playerID);
	local campsMs=PerfElapsed(sectionStarted); sectionStarted=PerfNow();
	local worldTurn=LOTM_RESCUE_Phase5.WorldTurn();
	local workshopRaw=LOTM_RESCUE_Phase5.MonsterTurnAttempts();
	local workshopRequested=LOTM_RESCUE_Phase5.ScaleMonsterSpawnCount(workshopRaw,"PERIODIC_WORKSHOP",worldTurn);
	local workshopSpawned=0;
	if LOTM_WORLD_Monsters~=nil and LOTM_WORLD_Monsters.RescueTurnSpawn~=nil then
		workshopSpawned=Number(LOTM_WORLD_Monsters.RescueTurnSpawn(worldTurn,workshopRequested),0);
	else Log("monster turn spawn skipped worldTurn="..worldTurn.." reason=API_MISSING"); end
	local workshopMs=PerfElapsed(sectionStarted); sectionStarted=PerfNow();
	local directRaw=LOTM_RESCUE_Phase5.DirectSpawnCount();
	local directRequested=LOTM_RESCUE_Phase5.ScaleMonsterSpawnCount(directRaw,"DIRECT",worldTurn);
	local directSpawned=0;
	if LOTM_RESCUE_DirectMonsters~=nil and LOTM_RESCUE_DirectMonsters.Spawn~=nil then
		directSpawned=Number(LOTM_RESCUE_DirectMonsters.Spawn(worldTurn,directRequested),0);
	else Log("direct monster turn spawn skipped worldTurn="..worldTurn.." reason=API_MISSING"); end
	local directMs=PerfElapsed(sectionStarted);
	Log("perf worldTurn="..worldTurn
		.." refreshMs="..string.format("%.3f",refreshMs)
		.." campsMs="..string.format("%.3f",campsMs)
		.." workshopMs="..string.format("%.3f",workshopMs)
		.." directMs="..string.format("%.3f",directMs)
		.." totalMs="..string.format("%.3f",PerfElapsed(totalStarted))
		.." spawnPercent="..LOTM_RESCUE_Phase5.MonsterSpawnPercent(worldTurn)
		.." workshop="..workshopSpawned.."/"..workshopRequested.." raw="..workshopRaw
		.." direct="..directSpawned.."/"..directRequested.." raw="..directRaw);
end

LOTM_MP_TurnSync.AddSynchronized(OnPlayerTurnStarted,"RescuePhase5Runtime");
LOTM_MP_TurnSync.RunStartup(function()
 LOTM_RESCUE_Phase5.RefreshState();
 if LOTM_RESCUE_Phase5.IsActive() and LOTM_WORLD_Barbarians~=nil and LOTM_WORLD_Barbarians.CleanupRescueUnits~=nil then
  LOTM_WORLD_Barbarians.CleanupRescueUnits();
 end
end,"RescuePhase5");
Log("loaded version="..VERSION.." waitingForRescueMode=true turnEvent=GameEvents.PlayerTurnStarted anchor=lowestAliveMajor candidateScansPerTurn=1 reservedCache=turnLocal campOddsDatabase=100 campMaxPerMajor=10 bonusCampLimits=20/23/26/29/32 campTurnFlow=10 monsterGlobalCaps=40/50/60/70/80 monsterTurnAttempts=6/8/10/12/15 directSpawnDifficulty2/4/6 monsterSpawnRate=50pctTurns1to20/75pctAfter20 mapScale=25/50/75/100/125/150 targetPerMajor=6");
-- END POST_RC241_DELTA MODULE: Scripts/LOTM_RESCUE_Phase5.lua
end;

m_mp241Loaders["LOTM_RESCUE_Phase6"] = function()
-- BEGIN RC241 MODULE: Scripts/LOTM_RESCUE_Phase6.lua
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("MP.LOTM_RESCUE_Phase6","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"MP.LOTM_RESCUE_Phase6","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"MP.LOTM_RESCUE_Phase6","GameEvents");
-- END RC342 STARTUP TRACE

-- Rescue Mode Phase 6: synchronized global purification ledger.
-- UI is read-only; every mutation and deduplication key lives in Gameplay.
LOTM_RESCUE_Phase6=LOTM_RESCUE_Phase6 or {};
LOTM_RESCUE_Phase4=LOTM_RESCUE_Phase4 or {};

local VERSION=2;
local GLOBAL_KEY="GLOBAL_PURIFICATION";
local CONTRIBUTOR_LIST="LOTM_RESCUE_PHASE6_CONTRIBUTOR_LIST";
local CONTRIBUTION_VERSION="LOTM_RESCUE_PHASE6_CONTRIBUTION_VERSION";
local UNIT_REWARD={[2]=1,[1]=2,[0]=4};
local WORKSHOP_REWARD={[2]=4,[1]=8,[0]=12};
local GUARDIAN_TYPES={
	UNIT_LOTM_RESCUE_FOOL_SAINT=true, UNIT_LOTM_RESCUE_FOOL_ANGEL=true,
	UNIT_LOTM_RESCUE_NIGHT_SAINT=true, UNIT_LOTM_RESCUE_NIGHT_ANGEL=true,
	UNIT_LOTM_RESCUE_STORM_SAINT=true, UNIT_LOTM_RESCUE_STORM_ANGEL=true
};
local GUARDIAN_FACTIONS={
	UNIT_LOTM_RESCUE_FOOL_SAINT="CHURCH_FOOL", UNIT_LOTM_RESCUE_FOOL_ANGEL="CHURCH_FOOL",
	UNIT_LOTM_RESCUE_NIGHT_SAINT="CHURCH_NIGHT", UNIT_LOTM_RESCUE_NIGHT_ANGEL="CHURCH_NIGHT",
	UNIT_LOTM_RESCUE_STORM_SAINT="CHURCH_STORM", UNIT_LOTM_RESCUE_STORM_ANGEL="CHURCH_STORM"
};

local function Log(message) print("[LOTM_RESCUE][Phase6] "..tostring(message)); end
local function Number(value,default) if value==nil then return default; end return tonumber(value) or default; end
local function Active() return Number(Game.GetProperty("LOTM_RESCUE_MODE"),0)==1; end
local function BarbarianID() for _,player in ipairs(PlayerManager.GetAliveBarbarians()) do return player:GetID(); end return -1; end

local function UnitType(unit)
	local info=unit~=nil and GameInfo.Units[unit:GetType()] or nil;
	return info~=nil and info.UnitType or "";
end

local function IsCityState(playerID)
	local config=PlayerConfigurations[playerID];
	return config~=nil and config:GetCivilizationLevelTypeName()=="CIVILIZATION_LEVEL_CITY_STATE";
end

local function ContributorKey(playerID,unitID)
	if playerID==nil or playerID<0 then return nil; end
	local unit=unitID~=nil and unitID>=0 and UnitManager.GetUnit(playerID,unitID) or nil;
	local church=unit~=nil and GUARDIAN_FACTIONS[UnitType(unit)] or nil;
	if church~=nil then return church; end
	return "PLAYER_"..tostring(playerID);
end

local function AddContribution(key,amount,kind)
	if key==nil or amount<=0 then return; end
	local seenKey="LOTM_RESCUE_PHASE6_CONTRIBUTOR_SEEN:"..key;
	if Number(Game.GetProperty(seenKey),0)~=1 then
		local list=tostring(Game.GetProperty(CONTRIBUTOR_LIST) or "");
		Game.SetProperty(CONTRIBUTOR_LIST,list=="" and key or (list..","..key));
		Game.SetProperty(seenKey,1);
	end
	local prefix="LOTM_RESCUE_PHASE6_CONTRIBUTION:"..key..":";
	Game.SetProperty(prefix.."TOTAL",Number(Game.GetProperty(prefix.."TOTAL"),0)+amount);
	Game.SetProperty(prefix.."EVENTS",Number(Game.GetProperty(prefix.."EVENTS"),0)+1);
	Game.SetProperty(prefix.."KIND_"..tostring(kind or "UNKNOWN"),Number(Game.GetProperty(prefix.."KIND_"..tostring(kind or "UNKNOWN")),0)+amount);
end

local function MigrateContributions()
	if Number(Game.GetProperty(CONTRIBUTION_VERSION),0)>=VERSION then return; end
	local rebuilt=0; local serialMax=Number(Game.GetProperty("LOTM_RESCUE_PHASE6_EVENT_SERIAL"),0);
	for serial=1,serialMax do
		local prefix="LOTM_RESCUE_PHASE6_EVENT:"..serial..":";
		local amount=Number(Game.GetProperty(prefix.."DELTA"),0);
		if amount>0 then
			local key=Game.GetProperty(prefix.."CONTRIBUTOR") or ContributorKey(Number(Game.GetProperty(prefix.."KILLER"),-1),Number(Game.GetProperty(prefix.."KILLER_UNIT"),-1));
			if key~=nil then AddContribution(tostring(key),amount,tostring(Game.GetProperty(prefix.."KIND") or "UNKNOWN")); rebuilt=rebuilt+amount; end
		end
	end
	local unattributed=math.max(0,Number(Game.GetProperty(GLOBAL_KEY),0)-rebuilt);
	if unattributed>0 then AddContribution("LEGACY_UNATTRIBUTED",unattributed,"LEGACY"); end
	Game.SetProperty(CONTRIBUTION_VERSION,VERSION);
	Log("contribution migration version="..VERSION.." events="..serialMax.." rebuilt="..rebuilt.." unattributed="..unattributed);
end

local function IsContributor(playerID,unitID)
	if playerID==nil or playerID<0 or playerID==BarbarianID() then return false,"LOST_CONTROL_FACTION"; end
	local player=Players[playerID]; if player==nil or not player:IsAlive() then return false,"INVALID_PLAYER"; end
	local unit=unitID~=nil and unitID>=0 and UnitManager.GetUnit(playerID,unitID) or nil;
	if Number(player:GetProperty("LOTM_RESCUE_OUTER_GOD_FACTION"),0)==1 then return false,"OUTER_GOD_FACTION"; end
	if unit~=nil then
		if Number(unit:GetProperty("LOTM_RESCUE_OUTER_GOD"),0)==1 then return false,"OUTER_GOD_UNIT"; end
		if Number(unit:GetProperty("LOTM_WORLD_MONSTER_SERIAL"),0)>0 or Number(unit:GetProperty("LOTM_PP_WORKSHOP_SEQUENCE"),0)==1 then return false,"LOST_CONTROL_UNIT"; end
	end
	if player:IsMajor() or IsCityState(playerID) then return true,"NORMAL_FACTION"; end
	if unit~=nil and GUARDIAN_TYPES[UnitType(unit)] then return true,"CHURCH_GUARDIAN"; end
	if unit~=nil and Number(unit:GetProperty("LOTM_RESCUE_PURIFICATION_ALLY"),0)==1 then return true,"REGISTERED_ALLY"; end
	return false,"UNAPPROVED_FACTION";
end

local function EnsureState()
	if not Active() then return false; end
	if Game.GetProperty(GLOBAL_KEY)==nil then Game.SetProperty(GLOBAL_KEY,0); end
	Game.SetProperty("LOTM_RESCUE_PHASE6_VERSION",VERSION);
	Game.SetProperty("LOTM_RESCUE_PHASE6_STATE","READY");
	local phase=Number(Game.GetProperty("LOTM_RESCUE_PHASE"),0); if phase<6 then Game.SetProperty("LOTM_RESCUE_PHASE",6); end
	MigrateContributions();
	return true;
end

local function Award(kind,tier,amount,killerPlayerID,killerUnitID,eventToken)
	if not EnsureState() then return false,"INACTIVE"; end
	local token=tostring(eventToken or "MISSING");
	local key="LOTM_RESCUE_PHASE6_PROCESSED:"..kind..":"..token;
	if Number(Game.GetProperty(key),0)==1 then Log("duplicate kind="..kind.." token="..token); return false,"DUPLICATE"; end
	Game.SetProperty(key,1);
	local eligible,source=IsContributor(killerPlayerID,killerUnitID);
	if not eligible then
		Game.SetProperty("LOTM_RESCUE_PHASE6_REJECTED_EVENTS",Number(Game.GetProperty("LOTM_RESCUE_PHASE6_REJECTED_EVENTS"),0)+1);
		Log("rejected kind="..kind.." tier="..tostring(tier).." killer="..tostring(killerPlayerID).." unit="..tostring(killerUnitID).." reason="..source.." token="..token);
		return false,source;
	end
	local previous=Number(Game.GetProperty(GLOBAL_KEY),0); local total=previous+amount;
	Game.SetProperty(GLOBAL_KEY,total);
	local serial=Number(Game.GetProperty("LOTM_RESCUE_PHASE6_EVENT_SERIAL"),0)+1;
	Game.SetProperty("LOTM_RESCUE_PHASE6_EVENT_SERIAL",serial);
	local prefix="LOTM_RESCUE_PHASE6_EVENT:"..serial..":";
	local contributor=ContributorKey(killerPlayerID,killerUnitID) or "LEGACY_UNATTRIBUTED";
	Game.SetProperty(prefix.."KIND",kind); Game.SetProperty(prefix.."TIER",tier); Game.SetProperty(prefix.."DELTA",amount);
	Game.SetProperty(prefix.."KILLER",killerPlayerID); Game.SetProperty(prefix.."KILLER_UNIT",killerUnitID or -1); Game.SetProperty(prefix.."TOTAL",total); Game.SetProperty(prefix.."TURN",Game.GetCurrentGameTurn());
	Game.SetProperty(prefix.."CONTRIBUTOR",contributor); AddContribution(contributor,amount,kind);
	Game.SetProperty("LOTM_RESCUE_PHASE6_LAST_KIND",kind); Game.SetProperty("LOTM_RESCUE_PHASE6_LAST_DELTA",amount); Game.SetProperty("LOTM_RESCUE_PHASE6_LAST_TOTAL",total); Game.SetProperty("LOTM_RESCUE_PHASE6_LAST_KILLER",killerPlayerID); Game.SetProperty("LOTM_RESCUE_PHASE6_LAST_TURN",Game.GetCurrentGameTurn());
	Log("award event="..serial.." kind="..kind.." tier="..tostring(tier).." delta="..amount.." previous="..previous.." total="..total.." killer="..tostring(killerPlayerID).." unit="..tostring(killerUnitID).." source="..source.." token="..token);
	return true,total;
end

function LOTM_RESCUE_Phase6.OnLostControlKilled(tier,killerPlayerID,killerUnitID,sourceKind,sourceSerial)
	local numericTier=Number(tier,2); local amount=UNIT_REWARD[numericTier];
	if amount==nil then return false,"INVALID_TIER"; end
	return Award(sourceKind=="MONSTER" and "MONSTER" or "CENTER",numericTier,amount,killerPlayerID,killerUnitID,tostring(sourceKind or "CENTER")..":"..tostring(sourceSerial or "MISSING"));
end

function LOTM_RESCUE_Phase6.OnWorkshopCleared(level,clearerPlayerID,clearerUnitID,plotIndex,classificationTurn)
	local numericLevel=Number(level,2); local amount=WORKSHOP_REWARD[numericLevel];
	if amount==nil then return false,"INVALID_LEVEL"; end
	local token=tostring(plotIndex or -1)..":"..tostring(classificationTurn or Game.GetCurrentGameTurn());
	return Award("WORKSHOP",numericLevel,amount,clearerPlayerID,clearerUnitID,token);
end

LOTM_RESCUE_Phase4.OnLostControlKilled=LOTM_RESCUE_Phase6.OnLostControlKilled;
LOTM_RESCUE_Phase4.OnWorkshopCleared=LOTM_RESCUE_Phase6.OnWorkshopCleared;

Events.PlayerTurnActivated.Add(function(playerID,isFirstTimeThisTurn) if isFirstTimeThisTurn~=false then EnsureState(); end end);
EnsureState();
Log("loaded version="..VERSION.." active="..tostring(Active()).." rewards=1/2/4 workshops=4/8/12 contributionLeaderboard=true bossFormula=false");
-- END RC241 MODULE: Scripts/LOTM_RESCUE_Phase6.lua
end;

m_mp241Loaders["LOTM_RESCUE_Phase7"] = function()
-- BEGIN RC241 MODULE: Scripts/LOTM_RESCUE_Phase7.lua
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("MP.LOTM_RESCUE_Phase7","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"MP.LOTM_RESCUE_Phase7","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"MP.LOTM_RESCUE_Phase7","GameEvents");
-- END RC342 STARTUP TRACE

-- Rescue Mode Phase 7: cumulative positive support for AI cult civilizations.
-- Existing ordinary-mode cult penalties are retired by LOTM_AI_Cults while
-- rescue mode is active. Phase 8 targeting AI and Phase 10 Boss rules are out.
LOTM_RESCUE_Phase7=LOTM_RESCUE_Phase7 or {};

local VERSION=3;
local INCREMENTAL_MIGRATION_VERSION=2;
local INCREMENTAL_MIGRATION_KEY="LOTM_RESCUE_PHASE7_INCREMENTAL_MIGRATION_VERSION";
local ABILITY_SCHEMA_VERSION=1;
local UNIT_SIGNATURE_KEY="LOTM_RESCUE_PHASE7_ABILITY_SIGNATURE";
local CULTS={DEMONESS=true,HANGED_MAN=true,CHAINED=true};
local ABILITIES={
 HANGED_MAN={
  [1]="ABILITY_LOTM_RESCUE_P7_HANGED_T1_C10",
  [2]="ABILITY_LOTM_RESCUE_P7_HANGED_T2_C20",
  [3]="ABILITY_LOTM_RESCUE_P7_HANGED_T3_C40"
 },
 CHAINED={
  [1]="ABILITY_LOTM_RESCUE_P7_CHAINED_T1_M2",
  [2]="ABILITY_LOTM_RESCUE_P7_CHAINED_T2_M2_C20"
 }
};
local ABILITY_CULT_ORDER={"HANGED_MAN","CHAINED"};
local prefixCache={};
local unitIndexByPlayer={};

local function Log(message) print("[LOTM_RESCUE][Phase7] "..tostring(message)); end
local function Number(value,default) if value==nil then return default; end return tonumber(value) or default; end
local function Active() return Number(Game.GetProperty("LOTM_RESCUE_MODE"),0)==1; end
local function Cult(player) local value=player~=nil and player:GetProperty("LOTM_CULT_PATH") or nil; return CULTS[value] and value or nil; end

local function PrefixIds(prefix)
 if prefixCache[prefix]~=nil then return prefixCache[prefix]; end
 local result={}; for row in GameInfo.Modifiers() do if string.sub(row.ModifierId,1,#prefix)==prefix then table.insert(result,row.ModifierId); end end
 table.sort(result); prefixCache[prefix]=result; return result;
end
local function AttachStage(player,cult,stage)
 local property="LOTM_RESCUE_PHASE7_APPLIED:"..cult..":"..stage;
 if Number(player:GetProperty(property),0)==1 then return; end
 local prefix="LOTM_RESCUE_P7_"..cult.."_T"..stage.."__";
 local ids=PrefixIds(prefix); for _,modifierID in ipairs(ids) do player:AttachModifierByID(modifierID); end
 player:SetProperty(property,1);
 Log("attached player="..player:GetID().." cult="..cult.." stage="..stage.." modifiers="..#ids);
end
local function SetAbility(unit,abilityType,desired)
 local abilities=unit~=nil and unit:GetAbility() or nil; if abilities==nil or GameInfo.UnitAbilities[abilityType]==nil then return; end
 local current=abilities:GetAbilityCount(abilityType) or 0; if current~=desired then abilities:ChangeAbilityCount(abilityType,desired-current); end
end
local function UnitIndex(playerID)
 local index=unitIndexByPlayer[playerID];
 if index==nil then index={ids={},order={}}; unitIndexByPlayer[playerID]=index; end
 return index;
end
local function TrackUnit(playerID,unitID)
 local index=UnitIndex(playerID); if index.ids[unitID] then return false; end
 index.ids[unitID]=true; index.order[#index.order+1]=unitID; return true;
end
local function UntrackUnit(playerID,unitID)
 local index=unitIndexByPlayer[playerID]; if index~=nil then index.ids[unitID]=nil; end
end
local function UnitSignature(cult,tier)
 return "v"..ABILITY_SCHEMA_VERSION..":"..tostring(cult)..":"..tostring(tier);
end
local function StampUnitTier(unit,cult,tier)
 unit:SetProperty(UNIT_SIGNATURE_KEY,UnitSignature(cult,tier));
end
local function ApplyUnitTier(unit,cult,tier)
 if unit==nil then return; end
 for _,abilityCult in ipairs(ABILITY_CULT_ORDER) do
  local cultAbilities=ABILITIES[abilityCult];
  for stage=1,#cultAbilities do
   SetAbility(unit,cultAbilities[stage],abilityCult==cult and stage<=tier and 1 or 0);
  end
 end
 StampUnitTier(unit,cult,tier);
end
local function ApplyIndexedTier(player,cult,tier)
 local index=UnitIndex(player:GetID()); local compact={};
 for _,unitID in ipairs(index.order) do
  if index.ids[unitID] then
  local unit=player:GetUnits():FindID(unitID);
   if unit~=nil then ApplyUnitTier(unit,cult,tier); compact[#compact+1]=unitID; else index.ids[unitID]=nil; end
  end
 end
 index.order=compact;
end
local function MigratePlayerUnits(player,cult,tier,stampOnly)
 unitIndexByPlayer[player:GetID()]={ids={},order={}};
 local count=0;
 for _,unit in player:GetUnits():Members() do
  TrackUnit(player:GetID(),unit:GetID());
  if stampOnly then StampUnitTier(unit,cult,tier); else ApplyUnitTier(unit,cult,tier); end
  count=count+1;
 end
 return count;
end
local function ReconcilePlayer(player,allowFullMigration,stampOnly)
 if player==nil or not player:IsAlive() or player:IsHuman() then return; end
 local cult=Cult(player); if cult==nil then return; end
 local tier=math.max(1,math.min(3,LOTM_AI_Cults.GetTier(cult)));
 for stage=1,tier do AttachStage(player,cult,stage); end
 local oldTier=Number(player:GetProperty("LOTM_RESCUE_PHASE7_TIER"),0);
 local oldCult=tostring(player:GetProperty("LOTM_RESCUE_PHASE7_CULT") or "NONE");
 if allowFullMigration then
  local count=MigratePlayerUnits(player,cult,tier,stampOnly);
  Log("signature migration player="..player:GetID().." cult="..cult.." tier="..tier.." units="..count.." mode="..(stampOnly and "STAMP_ONLY" or "APPLY"));
 elseif oldTier~=tier or oldCult~=cult then
  ApplyIndexedTier(player,cult,tier);
 end
 player:SetProperty("LOTM_RESCUE_PHASE7_TIER",tier);
 player:SetProperty("LOTM_RESCUE_PHASE7_CULT",cult);
end
function LOTM_RESCUE_Phase7.ReconcileAll()
 if not Active() then return false; end
 Game.SetProperty("LOTM_RESCUE_PHASE7_VERSION",VERSION);
 Game.SetProperty("LOTM_RESCUE_PHASE7_STATE","READY");
 local phase=Number(Game.GetProperty("LOTM_RESCUE_PHASE"),0); if phase<7 then Game.SetProperty("LOTM_RESCUE_PHASE",7); end
 local previousMigration=Number(Game.GetProperty(INCREMENTAL_MIGRATION_KEY),0);
 local migrate=previousMigration<INCREMENTAL_MIGRATION_VERSION;
 local stampOnly=previousMigration>=1;
 for _,player in ipairs(PlayerManager.GetAliveMajors()) do ReconcilePlayer(player,migrate,stampOnly); end
 if migrate then Game.SetProperty(INCREMENTAL_MIGRATION_KEY,INCREMENTAL_MIGRATION_VERSION); end
 if LOTM_AI_Cult_Hanged~=nil and LOTM_AI_Cult_Hanged.RetireForRescue~=nil then LOTM_AI_Cult_Hanged.RetireForRescue(); end
 return true;
end

local function OnUnitAdded(playerID,unitID)
 if not Active() then return; end
 local player=Players[playerID]; if player==nil or player:IsHuman() or Cult(player)==nil then return; end
 local unit=UnitManager.GetUnit(playerID,unitID); if unit==nil then return; end
 local cult=Cult(player); local tier=math.max(1,math.min(3,LOTM_AI_Cults.GetTier(cult)));
 if not TrackUnit(playerID,unitID) then return; end
 if tostring(unit:GetProperty(UNIT_SIGNATURE_KEY) or "")~=UnitSignature(cult,tier) then ApplyUnitTier(unit,cult,tier); end
end
local function OnUnitRemoved(playerID,unitID) UntrackUnit(playerID,unitID); end
Events.UnitAddedToMap.Add(LOTM_UnitAddedPerf.Wrap("Phase7",OnUnitAdded));
Events.UnitRemovedFromMap.Add(OnUnitRemoved);
LOTM_RESCUE_Phase7.ReconcileAll();
Log("loaded version="..VERSION.." active="..tostring(Active()).." unitUpdates=incremental fullScan=migrationOnly persistentSignature=v"..ABILITY_SCHEMA_VERSION.." doubled=true inherited=true phase8AI=false bossFormula=false");
-- END RC241 MODULE: Scripts/LOTM_RESCUE_Phase7.lua
end;

m_mp241Loaders["LOTM_RESCUE_Phase8"] = function()
-- BEGIN RC241 MODULE: Scripts/LOTM_RESCUE_Phase8.lua
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("MP.LOTM_RESCUE_Phase8","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"MP.LOTM_RESCUE_Phase8","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"MP.LOTM_RESCUE_Phase8","GameEvents");
-- END RC342 STARTUP TRACE

-- Rescue Mode Phase 8: configurable permanent major coalition and lightweight
-- lost-control targeting. The default permanent coalition blocks declarations at
-- engine level; the advanced-setup opt-out retains the reactive peace fallback.
LOTM_RESCUE_Phase8=LOTM_RESCUE_Phase8 or {};

local VERSION=6;
local GUIDE_INTERVAL=2;
local MAX_GUIDED_UNITS=2;
local ALLIANCE_CONFIG="LOTM_RESCUE_MAJOR_ALLIANCE";
local WORKSHOP_PROPERTY="LOTM_PP_WORKSHOP_IS_WORKSHOP";
local CENTER_PROPERTY="LOTM_RESCUE_CENTER_MONSTER";
local HUMAN_WAR_PREFIX="LOTM_RESCUE_PHASE8_HUMAN_WAR:";
local ALLIANCE_PAIR_PREFIX="LOTM_RESCUE_PHASE8_PERMANENT_ALLIANCE:";
local PEACE_PREFIX="LOTM_RESCUE_P8_PEACE__";
local peaceModifierIds=nil;
local LAST_RECONCILE_TURN="LOTM_RESCUE_PHASE8_LAST_RECONCILE_TURN";

local function Log(message) print("[LOTM_RESCUE][Phase8] "..tostring(message)); end
local function Number(value,default) if value==nil then return default; end return tonumber(value) or default; end
local function Active() return Number(Game.GetProperty("LOTM_RESCUE_MODE"),0)==1; end
local function PermanentAllianceEnabled()
 local value=GameConfiguration.GetValue(ALLIANCE_CONFIG);
 if value==nil then return true; end
 return value==true or Number(value,0)==1 or string.lower(tostring(value))=="true";
end
local function PairKey(firstID,secondID)
 local low=math.min(firstID,secondID); local high=math.max(firstID,secondID);
 return HUMAN_WAR_PREFIX..low..":"..high;
end
local function AlliancePairKey(firstID,secondID)
 local low=math.min(firstID,secondID); local high=math.max(firstID,secondID);
 return ALLIANCE_PAIR_PREFIX..low..":"..high;
end
local function AliveMajor(player)
 return player~=nil and player:IsAlive() and player:IsMajor();
end
local function SortedMajors()
 local result={};
 for _,player in ipairs(PlayerManager.GetAliveMajors()) do result[#result+1]=player; end
 table.sort(result,function(a,b) return a:GetID()<b:GetID(); end);
 return result;
end
local function AnchorMajorID()
 local majors=SortedMajors(); return #majors>0 and majors[1]:GetID() or -1;
end
local function PeaceModifierIds()
 if peaceModifierIds~=nil then return peaceModifierIds; end
 peaceModifierIds={};
 for row in GameInfo.Modifiers() do if string.sub(row.ModifierId,1,#PEACE_PREFIX)==PEACE_PREFIX then peaceModifierIds[#peaceModifierIds+1]=row.ModifierId; end end
 table.sort(peaceModifierIds); return peaceModifierIds;
end
local function AttachPeacePreference(player)
 if player==nil or player:IsHuman() or Number(player:GetProperty("LOTM_RESCUE_PHASE8_PEACE_PREFERENCE"),0)==1 then return; end
 local ids=PeaceModifierIds(); for _,modifierID in ipairs(ids) do player:AttachModifierByID(modifierID); end
 if #ids>0 then player:SetProperty("LOTM_RESCUE_PHASE8_PEACE_PREFERENCE",1); end
 Log("peace preference player="..player:GetID().." modifiers="..#ids);
end
local function AtWar(first,secondID)
 local diplomacy=first~=nil and first:GetDiplomacy() or nil;
 return diplomacy~=nil and diplomacy:IsAtWarWith(secondID);
end
local function ForcePeace(actingID,reactingID,reason)
 local acting=Players[actingID]; local reacting=Players[reactingID];
 if not AliveMajor(acting) or not AliveMajor(reacting) or not AtWar(acting,reactingID) then return true; end
 local diplomacy=acting:GetDiplomacy();
 if diplomacy==nil or diplomacy.MakePeaceWith==nil then
  Log("peace unavailable acting="..actingID.." reacting="..reactingID.." reason="..reason);
  return false;
 end
 local ok,result=pcall(function() return diplomacy:MakePeaceWith(reactingID); end);
 Log("peace request acting="..actingID.." reacting="..reactingID.." reason="..reason.." ok="..tostring(ok).." result="..tostring(result));
 return ok;
end
local function HumanWarAllowed(firstID,secondID)
 return Number(Game.GetProperty(PairKey(firstID,secondID)),0)==1;
end
local function EstablishPermanentCoalition()
 if not PermanentAllianceEnabled() then
  Game.SetProperty("LOTM_RESCUE_PHASE8_ALLIANCE_MODE","FREE");
  return 0,0;
 end
 Game.SetProperty("LOTM_RESCUE_PHASE8_ALLIANCE_MODE","PERMANENT");
 local majors=SortedMajors(); local formed=0; local failed=0;
 for firstIndex=1,#majors do for secondIndex=firstIndex+1,#majors do
  local first=majors[firstIndex]; local second=majors[secondIndex];
  local key=AlliancePairKey(first:GetID(),second:GetID());
  if Number(Game.GetProperty(key),0)~=1 then
   if AtWar(first,second:GetID()) then ForcePeace(first:GetID(),second:GetID(),"PERMANENT_COALITION"); end
   local diplomacy=first:GetDiplomacy();
   local reverseDiplomacy=second:GetDiplomacy();
   local ok=false; local result=nil;
   if diplomacy~=nil and diplomacy.SetPermanentAlliance~=nil then
    if diplomacy.SetHasMet~=nil then pcall(function() diplomacy:SetHasMet(second:GetID()); end); end
    if reverseDiplomacy~=nil and reverseDiplomacy.SetHasMet~=nil then pcall(function() reverseDiplomacy:SetHasMet(first:GetID()); end); end
    ok,result=pcall(function() return diplomacy:SetPermanentAlliance(second:GetID()); end);
   end
   if ok and result~=false then
    Game.SetProperty(key,1); formed=formed+1;
    Log("permanent alliance formed first="..first:GetID().." second="..second:GetID());
   else
    Game.SetProperty(key,-1); failed=failed+1;
    Log("permanent alliance failed first="..first:GetID().." second="..second:GetID().." ok="..tostring(ok).." result="..tostring(result));
   end
  end
 end end
 return formed,failed;
end
local function ReconcilePeace()
 local majors=SortedMajors();
 for firstIndex=1,#majors do for secondIndex=firstIndex+1,#majors do
  local first=majors[firstIndex]; local second=majors[secondIndex];
  if AtWar(first,second:GetID()) then
   local anyHuman=first:IsHuman() or second:IsHuman();
   if PermanentAllianceEnabled() or (not anyHuman) or (not HumanWarAllowed(first:GetID(),second:GetID())) then
    ForcePeace(first:GetID(),second:GetID(),anyHuman and "AI_AGGRESSION" or "AI_VS_AI");
   end
  end
 end end
end
local function IsLostControl(unit)
 if unit==nil then return false; end
 if Number(unit:GetProperty(CENTER_PROPERTY),0)==1 then return true; end
 return LOTM_WORLD_Monsters~=nil and LOTM_WORLD_Monsters.IsMonster~=nil and LOTM_WORLD_Monsters.IsMonster(unit);
end
local function TargetEntries()
 local byPlot={};
 for _,barbarian in ipairs(PlayerManager.GetAliveBarbarians()) do
  for _,unit in barbarian:GetUnits():Members() do if IsLostControl(unit) then
   local plot=Map.GetPlot(unit:GetX(),unit:GetY());
   if plot~=nil then byPlot[plot:GetIndex()]={Plot=plot,Unit=unit,Kind="LOST_CONTROL",HasUnit=true}; end
  end end
 end
 local camp=GameInfo.Improvements.IMPROVEMENT_BARBARIAN_CAMP;
 if camp~=nil then for plotIndex=0,Map.GetPlotCount()-1 do
  local plot=Map.GetPlotByIndex(plotIndex);
  if plot:GetImprovementType()==camp.Index and Number(plot:GetProperty(WORKSHOP_PROPERTY),0)==1 and byPlot[plotIndex]==nil then
   byPlot[plotIndex]={Plot=plot,Kind="WORKSHOP",HasUnit=#(Units.GetUnitsInPlot(plot) or {})>0};
  end
 end end
 local result={}; for plotIndex=0,Map.GetPlotCount()-1 do if byPlot[plotIndex]~=nil then result[#result+1]=byPlot[plotIndex]; end end
 return result;
end
local function TargetRank(player,target)
 local minimum=nil; local sameContinent=false;
 for _,city in player:GetCities():Members() do
  local cityPlot=Map.GetPlot(city:GetX(),city:GetY());
  local distance=Map.GetPlotDistance(city:GetX(),city:GetY(),target.Plot:GetX(),target.Plot:GetY());
  if minimum==nil or distance<minimum then minimum=distance; end
  if cityPlot~=nil and cityPlot:GetContinentType()==target.Plot:GetContinentType() then sameContinent=true; end
 end
 if minimum==nil then return nil; end
 if minimum<=6 then return 0,minimum; end
 if minimum<=10 then return 1,minimum; end
 if sameContinent then return 2,minimum; end
 return nil;
end
local function BestTarget(player,targets)
 local ranked={};
 for _,target in ipairs(targets) do
  local priority,distance=TargetRank(player,target);
  if priority~=nil then ranked[#ranked+1]={Target=target,Priority=priority,CityDistance=distance}; end
 end
 table.sort(ranked,function(a,b)
  if a.Priority~=b.Priority then return a.Priority<b.Priority; end
  if a.CityDistance~=b.CityDistance then return a.CityDistance<b.CityDistance; end
  if a.Target.Kind~=b.Target.Kind then return a.Target.Kind<b.Target.Kind; end
  return a.Target.Plot:GetIndex()<b.Target.Plot:GetIndex();
 end);
 return #ranked>0 and ranked[1] or nil;
end
local function AtWarWithHuman(player)
 local diplomacy=player~=nil and player:GetDiplomacy() or nil; if diplomacy==nil then return false; end
 for _,other in ipairs(SortedMajors()) do if other:IsHuman() and diplomacy:IsAtWarWith(other:GetID()) then return true; end end
 return false;
end
local function EligibleUnits(player,targetPlot)
 local result={};
 for _,unit in player:GetUnits():Members() do
  local info=GameInfo.Units[unit:GetType()];
  if unit:GetCombat()>0 and info~=nil and info.FormationClass~="FORMATION_CLASS_CIVILIAN"
   and not IsLostControl(unit) and Number(unit:GetProperty("LOTM_RESCUE_GUARDIAN_SERIAL"),0)==0 then
   result[#result+1]={Unit=unit,Distance=Map.GetPlotDistance(unit:GetX(),unit:GetY(),targetPlot:GetX(),targetPlot:GetY()),Damage=unit:GetDamage() or 0};
  end
 end
 table.sort(result,function(a,b)
  if a.Distance~=b.Distance then return a.Distance<b.Distance; end
  if a.Damage~=b.Damage then return a.Damage<b.Damage; end
  return a.Unit:GetID()<b.Unit:GetID();
 end);
 return result;
end
local function ClearTarget(unit,target)
 if LOTM_RESCUE_SyncActions==nil then return false,"HELPER_UNAVAILABLE"; end
 if target.HasUnit and target.Unit~=nil and not target.Unit:IsDead() and not target.Unit:IsDelayedDeath() then
  return LOTM_RESCUE_SyncActions.ScriptedKill(target.Unit,unit),"UNIT_CLEARED";
 end
 local camp=GameInfo.Improvements.IMPROVEMENT_BARBARIAN_CAMP;
 if camp~=nil and target.Plot:GetImprovementType()==camp.Index and ImprovementBuilder~=nil and ImprovementBuilder.SetImprovementType~=nil then
  target.Plot:SetProperty("LOTM_PP_WORKSHOP_LAST_HUMAN",unit:GetOwner()); target.Plot:SetProperty("LOTM_PP_WORKSHOP_CLEARER_UNIT",unit:GetID());
  return pcall(ImprovementBuilder.SetImprovementType,target.Plot,-1,-1),"WORKSHOP_CLEARED";
 end
 return false,"TARGET_GONE";
end
local function ExecuteGuide(unit,target)
 if LOTM_RESCUE_SyncActions==nil then return false,"HELPER_UNAVAILABLE"; end
 local distance=Map.GetPlotDistance(unit:GetX(),unit:GetY(),target.Plot:GetX(),target.Plot:GetY());
 if distance<=1 then local cleared,reason=ClearTarget(unit,target); UnitManager.FinishMoves(unit); return cleared,reason; end
 local info=GameInfo.Units[unit:GetType()]; local moves=info~=nil and Number(info.BaseMoves,1) or 1;
 local moved,reason=LOTM_RESCUE_SyncActions.MoveToward(unit,target.Plot,moves,false,false);
 if moved and Map.GetPlotDistance(unit:GetX(),unit:GetY(),target.Plot:GetX(),target.Plot:GetY())<=1 then local cleared,clearReason=ClearTarget(unit,target); reason=reason.."+"..clearReason; moved=cleared; end
 if moved then UnitManager.FinishMoves(unit); end
 return moved,reason;
end
local function GuidePlayer(player,targets)
 if player==nil or player:IsHuman() or AtWarWithHuman(player) then return; end
 if Number(player:GetProperty("LOTM_RESCUE_PHASE8_LAST_GUIDE_TURN"),-1)==Game.GetCurrentGameTurn() then return; end
 local ranked=BestTarget(player,targets);
 if ranked==nil then player:SetProperty("LOTM_RESCUE_PHASE8_TARGET_PLOT",-1); return; end
 local target=ranked.Target;
 player:SetProperty("LOTM_RESCUE_PHASE8_TARGET_PLOT",target.Plot:GetIndex());
 player:SetProperty("LOTM_RESCUE_PHASE8_TARGET_PRIORITY",ranked.Priority);
 player:SetProperty("LOTM_RESCUE_PHASE8_TARGET_KIND",target.Kind);
 local requested=false; local reason="NO_UNIT"; local selected={}; local guided=0;
 for _,entry in ipairs(EligibleUnits(player,target.Plot)) do
  requested,reason=ExecuteGuide(entry.Unit,target); selected[#selected+1]=entry.Unit:GetID();
  if requested then guided=guided+1; end
  if guided>=MAX_GUIDED_UNITS then break; end
 end
 player:SetProperty("LOTM_RESCUE_PHASE8_LAST_GUIDE_TURN",Game.GetCurrentGameTurn());
 Log("guide player="..player:GetID().." units="..table.concat(selected,",").." guided="..guided.." target="..target.Plot:GetIndex().." kind="..target.Kind.." priority="..ranked.Priority.." cityDistance="..ranked.CityDistance.." lastRequested="..tostring(requested).." reason="..reason);
end
function LOTM_RESCUE_Phase8.ReconcileAll(forceGuide)
 if not Active() then return false; end
 local worldTurn=Game.GetCurrentGameTurn();
 if not forceGuide and Number(Game.GetProperty(LAST_RECONCILE_TURN),-1)==worldTurn then return true; end
 Game.SetProperty(LAST_RECONCILE_TURN,worldTurn);
 Game.SetProperty("LOTM_RESCUE_PHASE8_VERSION",VERSION);
 Game.SetProperty("LOTM_RESCUE_PHASE8_STATE","READY");
 local phase=Number(Game.GetProperty("LOTM_RESCUE_PHASE"),0); if phase<8 then Game.SetProperty("LOTM_RESCUE_PHASE",8); end
 for _,player in ipairs(SortedMajors()) do AttachPeacePreference(player); end
 ReconcilePeace();
 local formed,failed=EstablishPermanentCoalition();
 Game.SetProperty("LOTM_RESCUE_PHASE8_ALLIANCES_FORMED",formed);
 Game.SetProperty("LOTM_RESCUE_PHASE8_ALLIANCES_FAILED",failed);
 if forceGuide or worldTurn%GUIDE_INTERVAL==0 then
  local targets=TargetEntries();
  for _,player in ipairs(SortedMajors()) do GuidePlayer(player,targets); end
 end
 return true;
end
local function OnWar(actingID,reactingID)
 if not Active() then return; end
 local acting=Players[actingID]; local reacting=Players[reactingID]; if not AliveMajor(acting) or not AliveMajor(reacting) then return; end
 if PermanentAllianceEnabled() then
  ForcePeace(actingID,reactingID,"PERMANENT_COALITION_BREACH");
 elseif acting:IsHuman() then
  Game.SetProperty(PairKey(actingID,reactingID),1);
  Log("human war preserved acting="..actingID.." reacting="..reactingID);
 else
  ForcePeace(actingID,reactingID,reacting:IsHuman() and "AI_ON_HUMAN" or "AI_ON_AI");
 end
end
local function OnPeace(firstID,secondID) if Active() then Game.SetProperty(PairKey(firstID,secondID),nil); end end
local function OnTurn(playerID,isFirstTimeThisTurn)
 if isFirstTimeThisTurn==false or not Active() or playerID~=AnchorMajorID() then return; end
 LOTM_RESCUE_Phase8.ReconcileAll(false);
end
local function OnBootstrap() LOTM_RESCUE_Phase8.ReconcileAll(true); end

Events.DiplomacyDeclareWar.Add(OnWar);
Events.DiplomacyMakePeace.Add(OnPeace);
Events.PlayerTurnActivated.Add(OnTurn);
GameEvents.LOTM_RESCUE_Command_BootstrapCity.Add(OnBootstrap);
LOTM_RESCUE_Phase8.ReconcileAll(false);
Log("loaded version="..VERSION.." active="..tostring(Active()).." anchor=lowestAliveMajor reconcileOncePerWorldTurn=true permanentAlliance="..tostring(PermanentAllianceEnabled()).." guideInterval="..GUIDE_INTERVAL.." maxGuidedUnitsPerAI="..MAX_GUIDED_UNITS.." freeModeHumanWarPreserved=true specialUnits=false bossFormula=false");
-- END RC241 MODULE: Scripts/LOTM_RESCUE_Phase8.lua
end;

m_mp241Loaders["LOTM_RESCUE_Phase9"] = function()
-- BEGIN RC241 MODULE: Scripts/LOTM_RESCUE_Phase9.lua
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("MP.LOTM_RESCUE_Phase9","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"MP.LOTM_RESCUE_Phase9","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"MP.LOTM_RESCUE_Phase9","GameEvents");
-- END RC342 STARTUP TRACE

-- Rescue Mode Phase 9: Red Priest rescue overrides, universal advancement
-- exception plumbing, Divine Legion reservation, and AI military buildup.
LOTM_RESCUE_Phase9=LOTM_RESCUE_Phase9 or {};

local VERSION=9;
local RED_PRIEST_PATH="PATH_RED_PRIEST";
local OLD_CONQUEST_ABILITY="ABILITY_LOTM_RP_CONQUEST_BYPASS_WALLS";
local function AICombatCap()
 return LOTM_RESCUE_Difficulty~=nil and LOTM_RESCUE_Difficulty.AICombatCap() or 15;
end
local COMBAT_INDEX_MIGRATION_VERSION=1;
local COMBAT_INDEX_MIGRATION_KEY="LOTM_RESCUE_PHASE9_COMBAT_INDEX_MIGRATION_VERSION";
local combatIndexByPlayer={};

local function Log(message) print("[LOTM_RESCUE][Phase9] "..tostring(message)); end
local function Number(value,default) if value==nil then return default; end return tonumber(value) or default; end
local function Active() return Number(Game.GetProperty("LOTM_RESCUE_MODE"),0)==1; end
local function AttachOnce(player,modifierID,property)
 if player==nil or Number(player:GetProperty(property),0)==1 then return false; end
 player:AttachModifierByID(modifierID); player:SetProperty(property,1);
 Log("attached player="..player:GetID().." modifier="..modifierID); return true;
end
local function RetireLegacyConquestAbility(player)
 if Number(player:GetProperty("LOTM_RP_MOD_CONQUEST_BYPASS_WALLS_ATTACHED"),0)~=1
  or Number(player:GetProperty("LOTM_RESCUE_PHASE9_LEGACY_CONQUEST_RETIRED"),0)==1 then return; end
 for _,unit in player:GetUnits():Members() do
  local abilities=unit:GetAbility();
  if abilities~=nil then
   local current=abilities:GetAbilityCount(OLD_CONQUEST_ABILITY) or 0;
   if current~=0 then abilities:ChangeAbilityCount(OLD_CONQUEST_ABILITY,-current); end
  end
 end
 player:SetProperty("LOTM_RESCUE_PHASE9_LEGACY_CONQUEST_RETIRED",1);
end
local function RetireLegacyConquestAbilityFromUnit(player,unit)
 if player==nil or unit==nil or Number(player:GetProperty("LOTM_RP_MOD_CONQUEST_BYPASS_WALLS_ATTACHED"),0)~=1 then return; end
 local abilities=unit:GetAbility(); if abilities==nil then return; end
 local current=abilities:GetAbilityCount(OLD_CONQUEST_ABILITY) or 0;
 if current~=0 then abilities:ChangeAbilityCount(OLD_CONQUEST_ABILITY,-current); end
end
local function ReconcileLegacy(player)
 if Number(player:GetProperty("LOTM_RP_MOD_WAR_BISHOP_PRODUCTION_ATTACHED"),0)==1 then
  AttachOnce(player,"LOTM_RESCUE_P9_LEGACY_S3_PRODUCTION_OFF","LOTM_RESCUE_P9_OLD_S3_PROD_OFF");
 end
 if Number(player:GetProperty("LOTM_RP_MOD_WAR_BISHOP_WEARINESS_ATTACHED"),0)==1 then
  AttachOnce(player,"LOTM_RESCUE_P9_LEGACY_S3_WEARINESS_OFF","LOTM_RESCUE_P9_OLD_S3_WEARINESS_OFF");
 end
 if Number(player:GetProperty("LOTM_RP_MOD_WEATHER_ENEMY_STRENGTH_V2_ATTACHED"),0)==1 then
  AttachOnce(player,"LOTM_RESCUE_P9_LEGACY_S2_ENEMY_STRENGTH_AURA_OFF","LOTM_RESCUE_P9_OLD_S2_ENEMY_STRENGTH_OFF");
 end
 if Number(player:GetProperty("LOTM_RP_MOD_WEATHER_ENEMY_MOVEMENT_V2_ATTACHED"),0)==1 then
  AttachOnce(player,"LOTM_RESCUE_P9_LEGACY_S2_ENEMY_MOVEMENT_AURA_OFF","LOTM_RESCUE_P9_OLD_S2_ENEMY_MOVEMENT_OFF");
 end
 if Number(player:GetProperty("LOTM_RP_MOD_WEATHER_ENEMY_WEARINESS_V2_ATTACHED"),0)==1 then
  AttachOnce(player,"LOTM_RESCUE_P9_LEGACY_S2_ENEMY_WEARINESS_AURA_OFF","LOTM_RESCUE_P9_OLD_S2_ENEMY_WEARINESS_OFF");
 end
 if Number(player:GetProperty("LOTM_RP_MOD_WEATHER_FRIENDLY_MOVEMENT_V2_ATTACHED"),0)==1 then
  AttachOnce(player,"LOTM_RESCUE_P9_LEGACY_S2_FRIENDLY_MOVEMENT_OFF","LOTM_RESCUE_P9_OLD_S2_FRIENDLY_MOVEMENT_OFF");
 end
 if Number(player:GetProperty("LOTM_RP_MOD_RED_PRIEST_WAR_PRODUCTION_ATTACHED"),0)==1 then
  AttachOnce(player,"LOTM_RESCUE_P9_LEGACY_S0_PRODUCTION_OFF","LOTM_RESCUE_P9_OLD_S0_PRODUCTION_OFF");
 end
 RetireLegacyConquestAbility(player);
end
local function IsCombatUnit(unit)
 if unit==nil or unit:IsDead() or unit:IsDelayedDeath() then return false; end
 local info=GameInfo.Units[unit:GetType()]; if info==nil then return false; end
 return Number(info.Combat,0)>0 or Number(info.RangedCombat,0)>0 or Number(info.Bombard,0)>0 or Number(info.AntiAirCombat,0)>0;
end
local function CombatIndex(playerID)
 local index=combatIndexByPlayer[playerID];
 if index==nil then index={ids={},order={},count=0}; combatIndexByPlayer[playerID]=index; end
 return index;
end
local function RemoveIndexedUnit(playerID,unitID)
 local index=combatIndexByPlayer[playerID];
 if index~=nil and index.ids[unitID] then index.ids[unitID]=nil; index.count=math.max(0,index.count-1); end
end
local function AddIndexedUnit(playerID,unit)
 if not IsCombatUnit(unit) then return false; end
 local index=CombatIndex(playerID); local unitID=unit:GetID();
 if index.ids[unitID] then return false; end
 index.ids[unitID]=true; index.order[#index.order+1]=unitID; index.count=index.count+1; return true;
end
local function SelectRetireID(index,preferredRetireID,attempted)
 if preferredRetireID~=nil and index.ids[preferredRetireID] and not attempted[preferredRetireID] then return preferredRetireID; end
 local selected=nil; for _,unitID in ipairs(index.order) do if index.ids[unitID] and not attempted[unitID] and (selected==nil or unitID>selected) then selected=unitID; end end
 return selected;
end
local function EnforceIndexedAICombatCap(player,preferredRetireID)
 if player==nil or not player:IsAlive() or not player:IsMajor() or player:IsHuman() then return 0; end
 local index=CombatIndex(player:GetID()); local before=index.count; local retired=0; local failed=0; local attempted={};
 local cap=AICombatCap();
 while index.count>cap do
  local unitID=SelectRetireID(index,preferredRetireID,attempted); if unitID==nil then break; end
  attempted[unitID]=true; local unit=player:GetUnits():FindID(unitID);
  if unit==nil then RemoveIndexedUnit(player:GetID(),unitID);
  else
   local ok=UnitManager.Kill~=nil and pcall(UnitManager.Kill,unit);
   if ok and player:GetUnits():FindID(unitID)==nil then RemoveIndexedUnit(player:GetID(),unitID); retired=retired+1; else failed=failed+1; end
  end
 end
 local live=index.count;
 player:SetProperty("LOTM_RESCUE_PHASE9_AI_COMBAT_CAP",cap);
 player:SetProperty("LOTM_RESCUE_PHASE9_AI_COMBAT_LIVE",live);
 player:SetProperty("LOTM_RESCUE_PHASE9_AI_COMBAT_RETIRED",Number(player:GetProperty("LOTM_RESCUE_PHASE9_AI_COMBAT_RETIRED"),0)+retired);
 if retired>0 or failed>0 then Log("ai combat cap player="..player:GetID().." before="..before.." cap="..cap.." retired="..retired.." failed="..failed.." live="..live); end
 return live;
end
local function MigrateCombatIndex(player)
 local index=CombatIndex(player:GetID()); index.ids={}; index.order={}; index.count=0;
 for _,unit in player:GetUnits():Members() do AddIndexedUnit(player:GetID(),unit); end
 return EnforceIndexedAICombatCap(player,nil);
end
local function ReconcileAI(player)
 if player==nil or not player:IsAlive() or not player:IsMajor() or player:IsHuman() then return; end
 AttachOnce(player,"LOTM_RESCUE_P9_AI_MILITARY_PRODUCTION","LOTM_RESCUE_PHASE9_AI_PRODUCTION_ATTACHED");
 AttachOnce(player,"LOTM_RESCUE_P9_AI_MILITARY_PURCHASE","LOTM_RESCUE_PHASE9_AI_PURCHASE_ATTACHED");
 player:SetProperty("LOTM_RESCUE_PHASE9_AI_MILITARY_POSTURE","STRONG_CLEANUP");
 EnforceIndexedAICombatCap(player,nil);
end
local function ReconcilePathPlayer(player)
 if player==nil or not player:IsAlive() or not player:IsMajor() then return; end
 local path=tostring(player:GetProperty("LOTM_RP_PATH") or "NONE");
 local sequence=Number(player:GetProperty("LOTM_RP_SEQUENCE"),9);
 if sequence<=0 and path~="NONE" then
  player:SetProperty("LOTM_RESCUE_PHASE9_DIVINE_LEGION_READY",1);
  player:SetProperty("LOTM_RESCUE_PHASE9_DIVINE_LEGION_STATE","RESERVED_FOR_PHASE10");
 end
 if path~=RED_PRIEST_PATH then return; end
 ReconcileLegacy(player);
 if sequence<=6 then
  AttachOnce(player,"LOTM_RESCUE_P9_RP_S6_MILITARY_PURCHASE","LOTM_RESCUE_PHASE9_RP_S6_PURCHASE_ATTACHED");
  AttachOnce(player,"LOTM_RESCUE_P9_RP_S6_MAINTENANCE","LOTM_RESCUE_PHASE9_RP_S6_MAINTENANCE_ATTACHED");
 end
 if sequence<=3 then AttachOnce(player,"LOTM_RESCUE_P9_RP_S3_PRODUCTION","LOTM_RESCUE_PHASE9_RP_S3_PRODUCTION_ATTACHED"); end
 if sequence<=2 then
  AttachOnce(player,"LOTM_RESCUE_P9_RP_S2_STRENGTH","LOTM_RESCUE_PHASE9_RP_S2_STRENGTH_ATTACHED");
  AttachOnce(player,"LOTM_RESCUE_P9_RP_S2_MOVEMENT","LOTM_RESCUE_PHASE9_RP_S2_MOVEMENT_ATTACHED");
 end
 if sequence<=1 then AttachOnce(player,"LOTM_RESCUE_P9_RP_S1_GRANT_EXTRA_ATTACK","LOTM_RESCUE_PHASE9_RP_S1_ATTACK_ATTACHED"); end
 if sequence<=0 then AttachOnce(player,"LOTM_RESCUE_P9_RP_S0_PRODUCTION","LOTM_RESCUE_PHASE9_RP_S0_PRODUCTION_ATTACHED"); end
 player:SetProperty("LOTM_RESCUE_PHASE9_RP_MAINTENANCE_MODE",sequence<=6 and "FIXED_MINUS_2" or "LOCKED");
end
function LOTM_RESCUE_Phase9.ReconcileAll()
 if not Active() then return false; end
 Game.SetProperty("LOTM_RESCUE_PHASE9_VERSION",VERSION);
 Game.SetProperty("LOTM_RESCUE_PHASE9_STATE","READY");
 Game.SetProperty("LOTM_RESCUE_PHASE9_ARSON_DAMAGE",70);
 Game.SetProperty("LOTM_RESCUE_PHASE9_DIVINE_LEGION_READY",1);
 Game.SetProperty("LOTM_RESCUE_PHASE9_DIVINE_LEGION_STATE","RESERVED_FOR_PHASE10");
 local phase=Number(Game.GetProperty("LOTM_RESCUE_PHASE"),0); if phase<9 then Game.SetProperty("LOTM_RESCUE_PHASE",9); end
 local migrate=Number(Game.GetProperty(COMBAT_INDEX_MIGRATION_KEY),0)<COMBAT_INDEX_MIGRATION_VERSION;
 for _,player in ipairs(PlayerManager.GetAliveMajors()) do
  if migrate and not player:IsHuman() then MigrateCombatIndex(player); end
  ReconcileAI(player); ReconcilePathPlayer(player);
 end
 if migrate then Game.SetProperty(COMBAT_INDEX_MIGRATION_KEY,COMBAT_INDEX_MIGRATION_VERSION); end
 return true;
end
local function OnTurn(playerID,isFirstTimeThisTurn)
 if not Active() or not isFirstTimeThisTurn then return; end
 local player=Players[playerID]; ReconcileAI(player); ReconcilePathPlayer(player);
end
local function OnUnitAdded(playerID,unitID)
 if not Active() then return; end
 local player=Players[playerID]; if player==nil then return; end
 local unit=UnitManager.GetUnit(playerID,unitID); RetireLegacyConquestAbilityFromUnit(player,unit);
 if not player:IsHuman() and AddIndexedUnit(playerID,unit) then EnforceIndexedAICombatCap(player,unitID); end
end
local function OnUnitRemoved(playerID,unitID) RemoveIndexedUnit(playerID,unitID); end
Events.PlayerTurnActivated.Add(OnTurn);
Events.UnitAddedToMap.Add(LOTM_UnitAddedPerf.Wrap("Phase9",OnUnitAdded));
Events.UnitRemovedFromMap.Add(OnUnitRemoved);
LOTM_RESCUE_Phase9.ReconcileAll();
Log("loaded version="..VERSION.." active="..tostring(Active()).." aiProduction=50 aiPurchaseDiscount=30 aiPseudoYields=100 aiCombatCap=difficulty10/12/15 combatIndex=incremental fullScan=migrationOnly overflowPolicy=retireNewest playerMaintenance=fixedMinus2 arsonDamage=70 divineLegion=phase10");
-- END RC241 MODULE: Scripts/LOTM_RESCUE_Phase9.lua
end;

m_mp241Loaders["LOTM_RESCUE_Phase9Digestion"] = function()
-- BEGIN RC241 MODULE: Scripts/LOTM_RESCUE_Phase9Digestion.lua
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("MP.LOTM_RESCUE_Phase9Digestion","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"MP.LOTM_RESCUE_Phase9Digestion","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"MP.LOTM_RESCUE_Phase9Digestion","GameEvents");
-- END RC342 STARTUP TRACE

-- Rescue Mode Phase 9: confirmed Red Priest digestion override.
-- UI-only purchase/production observations arrive through validated
-- EXECUTE_SCRIPT commands; all actual state mutation remains in Gameplay.
LOTM_RESCUE_Phase9Digestion=LOTM_RESCUE_Phase9Digestion or {};

local VERSION=2;
local PATH="PATH_RED_PRIEST";
local GOLD_PURCHASE_COMMAND="LOTM_RESCUE_P9_Command_GoldMilitaryPurchase";
local TRAINED_COMMAND="LOTM_RESCUE_P9_Command_MilitaryTrained";
local META_PREFIX="LOTM_RESCUE_P9_UNIT_META:";
local DAMAGE_PREFIX="LOTM_RESCUE_P9_DAMAGE:";

local function Log(message) print("[LOTM_RESCUE][Phase9Digestion] "..tostring(message)); end
local function Number(value,default) if value==nil then return default; end return tonumber(value) or default; end
local function Active() return Number(Game.GetProperty("LOTM_RESCUE_MODE"),0)==1; end
local function Player(playerID) return playerID~=nil and Players[playerID] or nil; end
local function Eligible(playerID,sequence)
 local player=Player(playerID);
 return Active() and player~=nil and player:IsAlive() and player:IsMajor() and player:IsHuman()
  and player:GetProperty("LOTM_RP_PATH")==PATH and Number(player:GetProperty("LOTM_RP_SEQUENCE"),9)==sequence;
end
local function Key(playerID,unitID,suffix) return suffix..tostring(playerID)..":"..tostring(unitID); end
local function ResolveUnitInfo(value)
 local info=GameInfo.Units[value]; if info~=nil then return info; end
 local numeric=tonumber(value); if numeric==nil then return nil; end
 for row in GameInfo.Units() do if row.Hash==numeric or row.Index==numeric then return row; end end
 return nil;
end
local function IsMilitaryInfo(info)
	return info~=nil and info.FormationClass~=nil and info.FormationClass~="FORMATION_CLASS_CIVILIAN";
end
local function IsLostControl(unit)
 if unit==nil then return false; end
 if Number(unit:GetProperty("LOTM_RESCUE_CENTER_MONSTER"),0)==1 or Number(unit:GetProperty("LOTM_PP_WORKSHOP_SEQUENCE"),0)==1 then return true; end
 return LOTM_WORLD_Monsters~=nil and LOTM_WORLD_Monsters.IsMonster~=nil and LOTM_WORLD_Monsters.IsMonster(unit);
end
local function ObserveUnit(playerID,unitID)
 local unit=UnitManager.GetUnit(playerID,unitID); if unit==nil then return; end
 local base=unit:GetCombat() or 0;
 local baseKey=Key(playerID,unitID,META_PREFIX)..":BASE"; local lostKey=Key(playerID,unitID,META_PREFIX)..":LOST";
 local lost=IsLostControl(unit) and 1 or 0;
 if Number(Game.GetProperty(baseKey),nil)~=base then Game.SetProperty(baseKey,base); end
 if Number(Game.GetProperty(lostKey),nil)~=lost then Game.SetProperty(lostKey,lost); end
end
local function Defeated(playerID,unitID)
 local unit=UnitManager.GetUnit(playerID,unitID);
 return unitID~=nil and unitID>=0 and (unit==nil or unit:IsDead() or unit:IsDelayedDeath());
end
local function HeroWithin(playerID,x,y)
 local hero=LOTM_RP_State.FindHero(playerID);
 return hero~=nil and not hero:IsDead() and not hero:IsDelayedDeath()
  and Map.GetPlotDistance(hero:GetX(),hero:GetY(),x,y)<=6;
end
local function Add(playerID,category,eventKey)
 return LOTM_RP_State.TryAddDigestion(playerID,category,"RESCUE_P9:"..eventKey);
end

local function OnUnitDamageChanged(playerID,unitID,newDamage,oldDamage)
 if not Active() then return; end
 ObserveUnit(playerID,unitID);
 local prefix=Key(playerID,unitID,DAMAGE_PREFIX);
 Game.SetProperty(prefix..":TURN",Game.GetCurrentGameTurn());
 Game.SetProperty(prefix..":OLD",Number(oldDamage,0));
 Game.SetProperty(prefix..":NEW",Number(newDamage,0));
end

local function OnCombat(attackerPlayerID,attackerUnitID,defenderPlayerID,defenderUnitID)
 if not Active() then return; end
 ObserveUnit(attackerPlayerID,attackerUnitID); ObserveUnit(defenderPlayerID,defenderUnitID);
 local serial=Number(Game.GetProperty("LOTM_RESCUE_P9_COMBAT_SERIAL"),0)+1;
 Game.SetProperty("LOTM_RESCUE_P9_COMBAT_SERIAL",serial);
 local attacker=UnitManager.GetUnit(attackerPlayerID,attackerUnitID);
 local defender=UnitManager.GetUnit(defenderPlayerID,defenderUnitID);
 local defeated=Defeated(defenderPlayerID,defenderUnitID);
 local sequence=LOTM_RP_State.IsEnabledPlayer(attackerPlayerID) and LOTM_RP_State.GetSequence(attackerPlayerID) or -1;

 if sequence==8 and attacker~=nil and attacker:GetID()==Number(Player(attackerPlayerID):GetProperty("LOTM_RP_UNIT_ID"),-1) then
  local lost=defender~=nil and IsLostControl(defender) or Number(Game.GetProperty(Key(defenderPlayerID,defenderUnitID,META_PREFIX)..":LOST"),0)==1;
  if lost then Add(attackerPlayerID,"A","S8_LOST_CONTROL_ATTACK:"..serial); end
  local attackerBase=attacker:GetCombat() or 0;
  local defenderBase=defender~=nil and (defender:GetCombat() or 0) or Number(Game.GetProperty(Key(defenderPlayerID,defenderUnitID,META_PREFIX)..":BASE"),0);
  if defenderBase>attackerBase then Add(attackerPlayerID,"B","S8_STRONGER_ATTACK:"..serial); end
 end

 if not defeated then return; end
 local killKey=tostring(Game.GetCurrentGameTurn())..":"..tostring(attackerUnitID)..":"..tostring(defenderPlayerID)..":"..tostring(defenderUnitID);
 if sequence==5 then
  Add(attackerPlayerID,"A","S5_KILL:"..killKey);
  local damagePrefix=Key(defenderPlayerID,defenderUnitID,DAMAGE_PREFIX);
  local damageTurn=Number(Game.GetProperty(damagePrefix..":TURN"),-1);
  local oldDamage=Number(Game.GetProperty(damagePrefix..":OLD"),0);
  if damageTurn==Game.GetCurrentGameTurn() and oldDamage>0 then Add(attackerPlayerID,"B","S5_WOUNDED_KILL:"..killKey); end
 elseif sequence==4 and attacker~=nil and HeroWithin(attackerPlayerID,attacker:GetX(),attacker:GetY()) then
  Add(attackerPlayerID,"A","S4_KILL_WITHIN_6:"..killKey);
 elseif sequence==1 and attacker~=nil then
  -- The second-attack bookkeeping below awards the kill bonus after its base point.
 end

 if sequence==1 and attacker~=nil then
  local turn=Game.GetCurrentGameTurn();
  local attackTurn=Number(attacker:GetProperty("LOTM_RESCUE_P9_ATTACK_TURN"),-1);
  local count=attackTurn==turn and Number(attacker:GetProperty("LOTM_RESCUE_P9_ATTACK_COUNT"),0) or 0;
  count=count+1; attacker:SetProperty("LOTM_RESCUE_P9_ATTACK_TURN",turn); attacker:SetProperty("LOTM_RESCUE_P9_ATTACK_COUNT",count);
  if count==2 then
   Add(attackerPlayerID,"A","S1_SECOND_ATTACK:"..turn..":"..attackerUnitID);
   Add(attackerPlayerID,"B","S1_SECOND_ATTACK_KILL:"..killKey);
  end
 end
end

local function OnCombatCountAttack(attackerPlayerID,attackerUnitID,defenderPlayerID,defenderUnitID)
 if not Eligible(attackerPlayerID,1) then return; end
 local attacker=UnitManager.GetUnit(attackerPlayerID,attackerUnitID); if attacker==nil then return; end
 local turn=Game.GetCurrentGameTurn();
 local attackTurn=Number(attacker:GetProperty("LOTM_RESCUE_P9_ATTACK_TURN"),-1);
 local count=attackTurn==turn and Number(attacker:GetProperty("LOTM_RESCUE_P9_ATTACK_COUNT"),0) or 0;
 -- Kill events are counted in OnCombat so the base and kill point stay ordered.
 if Defeated(defenderPlayerID,defenderUnitID) then return; end
 count=count+1; attacker:SetProperty("LOTM_RESCUE_P9_ATTACK_TURN",turn); attacker:SetProperty("LOTM_RESCUE_P9_ATTACK_COUNT",count);
 if count==2 then Add(attackerPlayerID,"A","S1_SECOND_ATTACK:"..turn..":"..attackerUnitID); end
end

local function OnGoldMilitaryPurchase(playerID,parameters)
 if not Eligible(playerID,6) then return; end
 local info=ResolveUnitInfo(parameters~=nil and parameters.UnitType or nil);
 local spent=Number(parameters~=nil and parameters.GoldSpent or nil,0);
 local serial=tostring(parameters~=nil and parameters.Serial or "");
 if not IsMilitaryInfo(info) or spent<=0 or serial=="" then Log("rejected gold military purchase player="..tostring(playerID)); return; end
 Add(playerID,"A","S6_GOLD_MILITARY:"..serial..":"..info.UnitType);
end

local function OnMilitaryTrained(playerID,parameters)
 local sequence=LOTM_RP_State.IsEnabledPlayer(playerID) and LOTM_RP_State.GetSequence(playerID) or -1;
 if sequence~=6 and sequence~=3 then return; end
 local info=ResolveUnitInfo(parameters~=nil and parameters.UnitType or nil);
 local serial=tostring(parameters~=nil and parameters.Serial or "");
 if not IsMilitaryInfo(info) or serial=="" then Log("rejected military training player="..tostring(playerID)); return; end
	local eventName=sequence==6 and "S6_MILITARY_TRAINED:" or "S3_MILITARY_TRAINED:";
	Add(playerID,sequence==6 and "B" or "A",eventName..serial..":"..info.UnitType);
end

local baseLostControlKilled=LOTM_RESCUE_Phase6.OnLostControlKilled;
local function OnLostControlKilled(tier,killerPlayerID,killerUnitID,sourceKind,sourceSerial)
 local first,second=baseLostControlKilled(tier,killerPlayerID,killerUnitID,sourceKind,sourceSerial);
 if Eligible(killerPlayerID,2) then
  local numericTier=Number(tier,2); local token=tostring(sourceKind)..":"..tostring(sourceSerial);
  if numericTier==1 then Add(killerPlayerID,"A","S2_MID_KILL:"..token);
  elseif numericTier==0 then Add(killerPlayerID,"A","S2_HIGH_KILL_A:"..token); Add(killerPlayerID,"B","S2_HIGH_KILL_B:"..token); end
 end
 return first,second;
end
LOTM_RESCUE_Phase6.OnLostControlKilled=OnLostControlKilled;
LOTM_RESCUE_Phase4.OnLostControlKilled=OnLostControlKilled;

local baseWorkshopCleared=LOTM_RESCUE_Phase4.OnWorkshopCleared;
LOTM_RESCUE_Phase4.OnWorkshopCleared=function(level,clearerPlayerID,clearerUnitID,plotIndex,classificationTurn)
 local first,second=baseWorkshopCleared(level,clearerPlayerID,clearerUnitID,plotIndex,classificationTurn);
 if Eligible(clearerPlayerID,4) then
  local plot=Map.GetPlotByIndex(Number(plotIndex,-1));
  if plot~=nil and HeroWithin(clearerPlayerID,plot:GetX(),plot:GetY()) then
   Add(clearerPlayerID,"B","S4_WORKSHOP_WITHIN_6:"..tostring(plotIndex)..":"..tostring(classificationTurn));
  end
 end
 return first,second;
end

GameEvents.LOTM_RESCUE_P9_Command_GoldMilitaryPurchase.Add(OnGoldMilitaryPurchase);
GameEvents.LOTM_RESCUE_P9_Command_MilitaryTrained.Add(OnMilitaryTrained);
Events.UnitAddedToMap.Add(LOTM_UnitAddedPerf.Wrap("Phase9Digestion",function(playerID,unitID) if Active() then ObserveUnit(playerID,unitID); end end));
Events.UnitDamageChanged.Add(OnUnitDamageChanged);
GameEvents.OnCombatOccurred.Add(OnCombatCountAttack);
GameEvents.OnCombatOccurred.Add(OnCombat);
if Active() then
 Game.SetProperty("LOTM_RESCUE_PHASE9_DIGESTION_VERSION",VERSION);
 Game.SetProperty("LOTM_RESCUE_PHASE9_DIGESTION_STATE","READY");
end
Log("loaded version="..VERSION.." active="..tostring(Active()).." rangeRule=hex_distance_lte_6 metaWrites=changedOnly ordinaryMode=false");
-- END RC241 MODULE: Scripts/LOTM_RESCUE_Phase9Digestion.lua
end;

m_mp241Loaders["LOTM_RESCUE_RuntimeEvents"] = function()
-- BEGIN POST_RC241_NEW MODULE: Scripts/LOTM_RESCUE_RuntimeEvents.lua
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("MP.LOTM_RESCUE_RuntimeEvents","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"MP.LOTM_RESCUE_RuntimeEvents","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"MP.LOTM_RESCUE_RuntimeEvents","GameEvents");
-- END RC342 STARTUP TRACE

-- UI publications request a synchronized operation; only this Gameplay side
-- validates current engine state and changes units or rewards.
LOTM_MP241_LoadBundledModule("LOTM_Effects");
LOTM_RESCUE_RuntimeEvents=LOTM_RESCUE_RuntimeEvents or {};
local SEAL="ABILITY_LOTM_RESCUE_EARLY_SEAL";
local function Active() return tonumber(Game.GetProperty("LOTM_RESCUE_MODE") or 0)==1; end
local function Log(s) print("[LOTM_RESCUE][RuntimeEvents] "..s); end
local function Requester(id)
 for _,p in ipairs(PlayerManager.GetAliveMajors() or {}) do
  if p:GetID()==tonumber(id) and p:IsHuman() then return p; end
 end
 return nil;
end
local function Number(value) local n=tonumber(value); if n~=nil and n>=0 and n<=2147483647 and n==math.floor(n) then return n; end return nil; end
local function WorldTurn()
 if LOTM_RESCUE_Phase5~=nil and LOTM_RESCUE_Phase5.WorldTurn~=nil then return LOTM_RESCUE_Phase5.WorldTurn(); end
 local start=GameConfiguration~=nil and GameConfiguration.GetStartTurn~=nil and GameConfiguration.GetStartTurn() or 0;
 return math.max(1,Game.GetCurrentGameTurn()-(tonumber(start) or 0)+1);
end
local function SealTarget(unit)
 if unit==nil or unit:GetProperty("LOTM_RESCUE_PHASE10_ROLE")~=nil then return false; end
 for _,name in ipairs({"UNIT_LOTM_RESCUE_OUTER_GOD_AVATAR","UNIT_LOTM_RESCUE_OUTER_GOD_MINION"}) do
  local info=GameInfo.Units[name]; if info~=nil and unit:GetType()==info.Index then return false; end
 end
 if (tonumber(unit:GetProperty("LOTM_WORLD_MONSTER_SERIAL") or 0) or 0)>0
  or tonumber(unit:GetProperty("LOTM_RESCUE_CENTER_MONSTER") or 0)==1 then return true; end
 for _,name in ipairs({"UNIT_LOTM_RESCUE_LOST_CONTROL_LOW","UNIT_LOTM_RESCUE_LOST_CONTROL_MID","UNIT_LOTM_RESCUE_LOST_CONTROL_HIGH"}) do
  local info=GameInfo.Units[name]; if info~=nil and unit:GetType()==info.Index then return true; end
 end
 return false;
end
function LOTM_RESCUE_RuntimeEvents.ApplyEarlySeal(unit)
 if not Active() or not SealTarget(unit) or GameInfo.UnitAbilities[SEAL]==nil then return false; end
 local ability=unit:GetAbility(); if ability==nil then return false; end
 local wanted=WorldTurn()<=20 and 1 or 0;
 LOTM_Effects.SetAbilityCount(ability,SEAL,wanted);
 return (ability:GetAbilityCount(SEAL) or 0)==wanted;
end
local function ReconcileSeal()
 if not Active() then return; end
 local active=WorldTurn()<=20 and 1 or 0;
 local migrated=tonumber(Game.GetProperty("LOTM_RESCUE_EARLY_SEAL_VERSION") or 0)==1;
 if migrated and tonumber(Game.GetProperty("LOTM_RESCUE_EARLY_SEAL_ACTIVE"))==active then return; end
 local units={}; local seen={}; local legacy={};
 local function Add(unit)
  if unit==nil or not SealTarget(unit) then return; end
  local key=unit:GetOwner()..":"..unit:GetID(); if seen[key] then return; end
  seen[key]=true; units[#units+1]=unit;
  if (tonumber(unit:GetProperty("LOTM_WORLD_MONSTER_SERIAL") or 0) or 0)<=0 then legacy[#legacy+1]=key; end
 end
 if not migrated then
  -- New-feature old-save migration only. Subsequent threshold changes read
  -- the existing active-monster index and these few legacy identities.
  local natives={};
  for _,player in ipairs(PlayerManager.GetAliveBarbarians() or {}) do
   for _,unit in player:GetUnits():Members() do
    Add(unit); natives[#natives+1]={Owner=unit:GetOwner(),Unit=unit:GetID()};
   end
  end
  -- The same one-time migration covers pre-bridge native survivors whose
  -- birth was published before this context existed. No second unit scan.
  if LOTM_WORLD_Barbarians==nil or LOTM_WORLD_Barbarians.ProcessRescueUnitCandidates==nil
   or not LOTM_WORLD_Barbarians.ProcessRescueUnitCandidates(natives) then return; end
 else
  for token in string.gmatch(tostring(Game.GetProperty("LOTM_WORLD_MONSTER_ACTIVE_SERIALS") or ""),"[^,]+") do
   local serial=tonumber(token);
   if serial~=nil and serial>0 then
    local prefix="LOTM_WORLD_MONSTER:"..serial..":";
    local owner=Number(Game.GetProperty(prefix.."OWNER")); local id=Number(Game.GetProperty(prefix.."UNIT_ID"));
    if tonumber(Game.GetProperty(prefix.."LIVE"))==1 and owner~=nil and id~=nil then
     local unit=UnitManager.GetUnit(owner,id);
     if unit~=nil and tonumber(unit:GetProperty("LOTM_WORLD_MONSTER_SERIAL"))==serial then Add(unit); end
    end
   end
  end
  for owner,id in string.gmatch(tostring(Game.GetProperty("LOTM_RESCUE_EARLY_SEAL_LEGACY_UNITS") or ""),"(%d+):(%d+)") do Add(UnitManager.GetUnit(tonumber(owner),tonumber(id))); end
 end
 table.sort(units,function(a,b) if a:GetOwner()~=b:GetOwner() then return a:GetOwner()<b:GetOwner(); end return a:GetID()<b:GetID(); end);
 for _,unit in ipairs(units) do if not LOTM_RESCUE_RuntimeEvents.ApplyEarlySeal(unit) then return; end end
 table.sort(legacy);
 Game.SetProperty("LOTM_RESCUE_EARLY_SEAL_LEGACY_UNITS",table.concat(legacy,","));
 Game.SetProperty("LOTM_RESCUE_EARLY_SEAL_VERSION",1);
 Game.SetProperty("LOTM_RESCUE_EARLY_SEAL_ACTIVE",active);
 Log("early seal worldTurn="..WorldTurn().." active="..active.." combat="..(active==1 and -10 or 0).." reconciled="..#units);
end
local function CommandCleanup(playerID,parameters)
 if not Active() or Requester(playerID)==nil or type(parameters)~="table" then return; end
 local csv=parameters.Units; if type(csv)~="string" or #csv>2048 then return; end
 local candidates={};
 for owner,id in string.gmatch(csv,"(%d+):(%d+)") do
  if #candidates>=64 then return; end
  owner=Number(owner); id=Number(id);
  if owner==nil or id==nil then return; end
  candidates[#candidates+1]={Owner=owner,Unit=id};
 end
 if #candidates==0 then return; end
 if LOTM_WORLD_Barbarians~=nil and LOTM_WORLD_Barbarians.ProcessRescueUnitCandidates~=nil then
  local ok,removed=LOTM_WORLD_Barbarians.ProcessRescueUnitCandidates(candidates);
  Log("native spawn command candidates="..#candidates.." removed="..tostring(removed or 0).." accepted="..tostring(ok));
 end
end
local function CommandCamp(playerID,parameters)
 if not Active() or Requester(playerID)==nil or type(parameters)~="table" then return; end
 local plot=Number(parameters.PlotIndex); local epoch=Number(parameters.CampEpoch);
 if plot==nil or epoch==nil or LOTM_PP_Workshops==nil or LOTM_PP_Workshops.ResolveRemovedCamp==nil then return; end
 local done=LOTM_PP_Workshops.ResolveRemovedCamp(plot,epoch);
 Log("camp command plot="..plot.." epoch="..epoch.." settled="..tostring(done).." turn="..Game.GetCurrentGameTurn());
end
local function OnTurn(playerID)
 if not Active() or not LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID) then return; end
 ReconcileSeal();
end
local function CommandPotion(playerID,parameters)
 if not Active() or Requester(playerID)==nil or type(parameters)~="table" then return; end
 local target=Number(parameters.TargetPlayerID);
 if target==nil or Requester(target)==nil or LOTM_RESCUE_Thief==nil
  or LOTM_RESCUE_Thief.ReconcileCompletedPotion==nil then return; end
 local done=LOTM_RESCUE_Thief.ReconcileCompletedPotion(target);
 Log("potion command target="..target.." advanced="..tostring(done).." turn="..Game.GetCurrentGameTurn());
end
GameEvents.LOTM_RESCUE_Command_NativeCleanup.Add(CommandCleanup);
GameEvents.LOTM_RESCUE_Command_CampRemoved.Add(CommandCamp);
GameEvents.LOTM_RESCUE_Command_PotionCompleted.Add(CommandPotion);
LOTM_MP_TurnSync.AddSynchronized(OnTurn,"RescueRuntimeEvents");
LOTM_MP_TurnSync.RunStartup(function()
 if Active() then ReconcileSeal(); Game.SetProperty("LOTM_RESCUE_RUNTIME_EVENTS_READY",1); end
end,"RescueRuntimeEvents");
Log("loaded version=1 nativeSpawn=executeScript campReward=executeScript earlySeal=turns1to20");
-- END POST_RC241_NEW MODULE: Scripts/LOTM_RESCUE_RuntimeEvents.lua
end;

m_mp241Loaders["LOTM_RESCUE_SyncActions"] = function()
-- BEGIN POST_RC241_DELTA MODULE: Scripts/LOTM_RESCUE_SyncActions.lua
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("MP.LOTM_RESCUE_SyncActions","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"MP.LOTM_RESCUE_SyncActions","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"MP.LOTM_RESCUE_SyncActions","GameEvents");
-- END RC342 STARTUP TRACE

-- Gameplay-safe deterministic movement helpers.  Scripted crisis actors retain
-- deterministic placement movement, while church guardians use the engine's
-- native MOVE_TO operation so terrain, roads, zones of control and movement
-- points are resolved by Civilization VI itself.
LOTM_RESCUE_SyncActions=LOTM_RESCUE_SyncActions or {};
local VERSION=9;
local REDEPLOY_RADIUS=12;
print("[LOTM_RESCUE][SyncActions] loaded version="..VERSION.." placeUnit="..tostring(UnitManager~=nil and UnitManager.PlaceUnit~=nil).." kill="..tostring(UnitManager~=nil and UnitManager.Kill~=nil).." genericRedeployRadius="..REDEPLOY_RADIUS.." monsterTargetDistance=5-12 cityTerritoryAllowed=true");

local function Open(plot,requireUnowned,allowedOwner)
	if plot==nil or plot:IsWater() or plot:IsImpassable() or plot:IsCity() then return false; end
	if plot:GetDistrictType()>=0 or plot:GetUnitCount()>0 then return false; end
	if requireUnowned and plot:GetOwner()>=0 then return false; end
	if allowedOwner~=nil and plot:GetOwner()>=0 then
		if type(allowedOwner)=="table" then
			if allowedOwner[plot:GetOwner()]~=true then return false; end
		elseif plot:GetOwner()~=allowedOwner then return false; end
	end
	return true;
end

local function RedeployCandidates(target,requireUnowned,allowedOwner)
	local result={};
	for dx=-REDEPLOY_RADIUS,REDEPLOY_RADIUS do for dy=-REDEPLOY_RADIUS,REDEPLOY_RADIUS do
		local plot=Map.GetPlotXYWithRangeCheck(target:GetX(),target:GetY(),dx,dy,REDEPLOY_RADIUS);
		if Open(plot,requireUnowned,allowedOwner) then
			local distance=Map.GetPlotDistance(plot:GetX(),plot:GetY(),target:GetX(),target:GetY());
			if distance>=1 then result[#result+1]={Plot=plot,Distance=distance}; end
		end
	end end
	table.sort(result,function(a,b)
		if a.Distance~=b.Distance then return a.Distance<b.Distance; end
		return a.Plot:GetIndex()<b.Plot:GetIndex();
	end);
	return result;
end

local function RedeployOpen(target,requireUnowned,allowedOwner)
	local result=RedeployCandidates(target,requireUnowned,allowedOwner);
	return #result>0 and result[1].Plot or nil,#result>0 and result[1].Distance or -1,result;
end

function LOTM_RESCUE_SyncActions.RedeployNearTarget(unit,target,minRadius,maxRadius,requireUnowned,allowedOwner)
	if unit==nil or target==nil or UnitManager.PlaceUnit==nil then return false,"API",-1,-1; end
	local minimum=math.max(1,math.floor(tonumber(minRadius) or 5));
	local radius=math.max(minimum,math.floor(tonumber(maxRadius) or REDEPLOY_RADIUS));
	local candidates={}; local seen={};
	for dx=-radius,radius do for dy=-radius,radius do
		local plot=Map.GetPlotXYWithRangeCheck(target:GetX(),target:GetY(),dx,dy,radius);
		if plot~=nil and not seen[plot:GetIndex()] and Open(plot,requireUnowned,allowedOwner) then
			seen[plot:GetIndex()]=true;
			local distance=Map.GetPlotDistance(plot:GetX(),plot:GetY(),target:GetX(),target:GetY());
			if distance>=minimum and distance<=radius then candidates[#candidates+1]={Plot=plot,Distance=distance}; end
		end
	end end
	-- The user-facing rule is at least five tiles from the target city. Prefer
	-- ring five, then expand one ring at a time up to twelve when occupied or
	-- illegal. Owned target territory is valid through allowedOwner.
	table.sort(candidates,function(a,b)
		if a.Distance~=b.Distance then return a.Distance<b.Distance; end
		return a.Plot:GetIndex()<b.Plot:GetIndex();
	end);
	for _,entry in ipairs(candidates) do
		local ok,result=pcall(UnitManager.PlaceUnit,unit,entry.Plot:GetX(),entry.Plot:GetY());
		local moved=ok and result~=false and unit:GetX()==entry.Plot:GetX() and unit:GetY()==entry.Plot:GetY();
		if moved then return true,"TARGET_REDEPLOY_RING_"..entry.Distance,entry.Plot:GetIndex(),entry.Distance; end
	end
	return false,#candidates>0 and "PLACE_FAILED" or "NO_REDEPLOY_PLOT",-1,-1;
end

function LOTM_RESCUE_SyncActions.MoveToward(unit,target,maxSteps,requireUnowned,allowRedeploy,allowedOwner,forceRedeployDistance,moveDiagnostic)
	local diagnostic=type(moveDiagnostic)=="table" and moveDiagnostic or nil;
	if diagnostic~=nil then diagnostic.Status="START"; diagnostic.CallOK=nil; diagnostic.RawResult=nil; diagnostic.RawResultType=""; end
	if unit==nil or target==nil or UnitManager.PlaceUnit==nil then if diagnostic~=nil then diagnostic.Status="API"; end return false,"API",-1; end
	local source=Map.GetPlot(unit:GetX(),unit:GetY()); if source==nil then if diagnostic~=nil then diagnostic.Status="SOURCE"; end return false,"SOURCE",-1; end
	local before=Map.GetPlotDistance(unit:GetX(),unit:GetY(),target:GetX(),target:GetY());
	if diagnostic~=nil then diagnostic.Before=before; diagnostic.Source=source:GetIndex(); diagnostic.Target=target:GetIndex(); end
	if before<=1 then if diagnostic~=nil then diagnostic.Status="ADJACENT"; diagnostic.Destination=source:GetIndex(); end return true,"ADJACENT",source:GetIndex(); end
	local candidates={}; local steps=math.max(1,tonumber(maxSteps) or 1);
	for dx=-steps,steps do for dy=-steps,steps do
		local plot=Map.GetPlotXYWithRangeCheck(unit:GetX(),unit:GetY(),dx,dy,steps);
		if Open(plot,requireUnowned,allowedOwner) then
			local distance=Map.GetPlotDistance(plot:GetX(),plot:GetY(),target:GetX(),target:GetY());
			if distance<before then candidates[#candidates+1]={Plot=plot,Distance=distance}; end
		end
	end end
	table.sort(candidates,function(a,b)
		if a.Distance~=b.Distance then return a.Distance<b.Distance; end
		return a.Plot:GetIndex()<b.Plot:GetIndex();
	end);
	if diagnostic~=nil then diagnostic.CandidateCount=#candidates; end
	local placementOptions=candidates; local destination=#candidates>0 and candidates[1].Plot or nil; local reason="STEP";
	local crossContinent=source:GetContinentType()~=target:GetContinentType();
	local forceRedeploy=allowRedeploy and tonumber(forceRedeployDistance)~=nil and before>tonumber(forceRedeployDistance);
	if diagnostic~=nil then diagnostic.CrossContinent=crossContinent; diagnostic.ForceRedeploy=forceRedeploy; end
	if allowRedeploy and (destination==nil or crossContinent or forceRedeploy) then
		local ring=-1; destination,ring,placementOptions=RedeployOpen(target,requireUnowned,allowedOwner);
		reason=destination~=nil and (forceRedeploy and "ASSAULT_REDEPLOY_RING_" or "REDEPLOY_RING_")..tostring(ring) or "NO_REDEPLOY_PLOT";
	end
	if destination==nil then if diagnostic~=nil then diagnostic.Status="NO_PLOT"; diagnostic.Selection=reason; end return false,"NO_PLOT",-1; end
	local destinationDistance=Map.GetPlotDistance(destination:GetX(),destination:GetY(),target:GetX(),target:GetY());
	if diagnostic~=nil then diagnostic.Selection=reason; diagnostic.Destination=destination:GetIndex(); diagnostic.DestinationDistance=destinationDistance; diagnostic.Attempts={}; end
	if diagnostic==nil then
		local ok,result=pcall(UnitManager.PlaceUnit,unit,destination:GetX(),destination:GetY());
		local moved=ok and result~=false and unit:GetX()==destination:GetX() and unit:GetY()==destination:GetY();
		return moved,moved and reason or "PLACE_FAILED",destination:GetIndex();
	end
	local retryOptions={};
	for _,entry in ipairs(placementOptions or {}) do if entry.Distance==destinationDistance then retryOptions[#retryOptions+1]=entry; end end
	diagnostic.RetryCandidateCount=#retryOptions;
	local lastDestination=destination; local lastOutcome="NO_ATTEMPT";
	for attempt,entry in ipairs(retryOptions) do
		destination=entry.Plot; lastDestination=destination;
		local beforeX,beforeY=unit:GetX(),unit:GetY();
		local ok,result=pcall(UnitManager.PlaceUnit,unit,destination:GetX(),destination:GetY());
		local finalX,finalY=unit:GetX(),unit:GetY(); local unchanged=finalX==beforeX and finalY==beforeY;
		local moved=ok and result~=false and finalX==destination:GetX() and finalY==destination:GetY();
		local outcome="";
		if moved then outcome="MOVED";
		elseif not ok then outcome="PCALL_ERROR";
		elseif result==false then outcome="API_FALSE";
		elseif unchanged and result==nil then outcome="API_NIL_NO_MOVE";
		elseif unchanged then outcome="API_"..string.upper(type(result)).."_NO_MOVE";
		else outcome="UNEXPECTED_COORD_CHANGE"; end
		lastOutcome=outcome;
		diagnostic.Attempts[#diagnostic.Attempts+1]="attempt="..attempt..",plot="..destination:GetIndex()..",distance="..entry.Distance..",callOK="..tostring(ok)..",rawType="..type(result)..",raw="..tostring(result)..",finalXY="..finalX..":"..finalY..",outcome="..outcome;
		diagnostic.CallOK=ok; diagnostic.RawResult=tostring(result); diagnostic.RawResultType=type(result); diagnostic.FinalX=finalX; diagnostic.FinalY=finalY; diagnostic.Moved=moved; diagnostic.Destination=destination:GetIndex(); diagnostic.DestinationDistance=entry.Distance; diagnostic.FailureReason=moved and "" or outcome;
		if moved then diagnostic.Status="MOVED"; diagnostic.AttemptCount=attempt; return true,attempt==1 and reason or reason.."_RETRY_"..attempt,destination:GetIndex(); end
		if not unchanged then diagnostic.Status="PLACE_FAILED_UNEXPECTED_COORD_CHANGE"; diagnostic.AttemptCount=attempt; return false,"PLACE_FAILED_"..outcome,destination:GetIndex(); end
	end
	diagnostic.Status="PLACE_FAILED_ALL"; diagnostic.AttemptCount=#retryOptions; diagnostic.FailureReason=lastOutcome;
	return false,"PLACE_FAILED_ALL_"..#retryOptions,lastDestination:GetIndex();
end

function LOTM_RESCUE_SyncActions.MoveTowardNative(unit,target)
	if unit==nil or target==nil or UnitManager.CanStartOperation==nil or UnitManager.RequestOperation==nil
		or UnitOperationTypes==nil or UnitOperationTypes.MOVE_TO==nil
		or UnitOperationTypes.PARAM_X==nil or UnitOperationTypes.PARAM_Y==nil then return false,"NATIVE_API",-1; end
	local source=Map.GetPlot(unit:GetX(),unit:GetY()); if source==nil then return false,"SOURCE",-1; end
	if Map.GetPlotDistance(source:GetX(),source:GetY(),target:GetX(),target:GetY())<=1 then return true,"ADJACENT",source:GetIndex(); end
	local candidates={}; local seen={};
	for dx=-1,1 do for dy=-1,1 do
		local plot=Map.GetPlotXYWithRangeCheck(target:GetX(),target:GetY(),dx,dy,1);
		if plot~=nil and not seen[plot:GetIndex()] and Open(plot,false,nil) then
			seen[plot:GetIndex()]=true;
			candidates[#candidates+1]={Plot=plot,Distance=Map.GetPlotDistance(source:GetX(),source:GetY(),plot:GetX(),plot:GetY())};
		end
	end end
	table.sort(candidates,function(a,b)
		if a.Distance~=b.Distance then return a.Distance<b.Distance; end
		return a.Plot:GetIndex()<b.Plot:GetIndex();
	end);
	for _,entry in ipairs(candidates) do
		local parameters={};
		parameters[UnitOperationTypes.PARAM_X]=entry.Plot:GetX();
		parameters[UnitOperationTypes.PARAM_Y]=entry.Plot:GetY();
		local canOK,canStart=pcall(UnitManager.CanStartOperation,unit,UnitOperationTypes.MOVE_TO,nil,parameters);
		if canOK and canStart then
			local beforeX,beforeY=unit:GetX(),unit:GetY();
			local requestOK,requested=pcall(UnitManager.RequestOperation,unit,UnitOperationTypes.MOVE_TO,parameters);
			local moved=requestOK and requested~=false and (unit:GetX()~=beforeX or unit:GetY()~=beforeY);
			if moved then
				local plot=Map.GetPlot(unit:GetX(),unit:GetY());
				return true,"NATIVE_MOVE",plot~=nil and plot:GetIndex() or -1;
			end
		end
	end
	return false,"NATIVE_NO_PATH",-1;
end

function LOTM_RESCUE_SyncActions.MarkScriptedKiller(target,killer)
	if target==nil or killer==nil then return; end
	local prefix="LOTM_RESCUE_SCRIPTED_KILLER:"..target:GetOwner()..":"..target:GetID()..":";
	-- Unit IDs can be reused after removal.  Bind the attribution to the
	-- target's durable gameplay identity so an old scripted-kill record can
	-- never reward or settle a later unit generation with the same owner/ID.
	local monsterSerial=tonumber(target:GetProperty("LOTM_WORLD_MONSTER_SERIAL") or 0) or 0;
	local sequenceSerial=tonumber(target:GetProperty("LOTM_RESCUE_PHASE4_SEQUENCE_SERIAL") or 0) or 0;
	local targetKind="UNIT"; local targetSerial=0;
	if monsterSerial>0 then targetKind="MONSTER"; targetSerial=monsterSerial;
	elseif sequenceSerial>0 then targetKind="SEQUENCE"; targetSerial=sequenceSerial; end
	-- Clear the commit fields first.  If an unexpected exception interrupts the
	-- following writes, consumers fail closed instead of pairing a new identity
	-- with a stale killer.
	Game.SetProperty(prefix.."PLAYER",nil);
	Game.SetProperty(prefix.."UNIT",nil);
	Game.SetProperty(prefix.."TARGET_KIND",targetKind);
	Game.SetProperty(prefix.."TARGET_SERIAL",targetSerial);
	Game.SetProperty(prefix.."PLAYER",killer:GetOwner());
	Game.SetProperty(prefix.."UNIT",killer:GetID());
end

function LOTM_RESCUE_SyncActions.ScriptedKill(target,killer)
	if target==nil or killer==nil or UnitManager.Kill==nil then return false; end
	if LOTM_RESCUE_Phase10~=nil and LOTM_RESCUE_Phase10.IsDescentProtected~=nil
	 and LOTM_RESCUE_Phase10.IsDescentProtected(target) then return false; end
	local owner=target:GetOwner(); local unitID=target:GetID();
	LOTM_RESCUE_SyncActions.MarkScriptedKiller(target,killer);
	local ok=pcall(UnitManager.Kill,target);
	if not ok then return false; end
	local checked,current=pcall(UnitManager.GetUnit,owner,unitID);
	return checked and current==nil;
end
-- END POST_RC241_DELTA MODULE: Scripts/LOTM_RESCUE_SyncActions.lua
end;

m_mp241Loaders["LOTM_RESCUE_Thief"] = function()
-- BEGIN POST_RC241_NEW MODULE: Scripts/LOTM_RESCUE_Thief.lua
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("MP.LOTM_RESCUE_Thief","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"MP.LOTM_RESCUE_Thief","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"MP.LOTM_RESCUE_Thief","GameEvents");
-- END RC342 STARTUP TRACE

-- Redemption-mode Thief pathway and Purification Energy ledger.
-- This module is intentionally rescue-only.  The ordinary Thief module is not
-- imported in redemption games and remains a locked normal-mode surface.
LOTM_MP241_LoadBundledModule("LOTM_Effects");
LOTM_RESCUE_Thief = LOTM_RESCUE_Thief or {};

local PATH = "PATH_THIEF";
local HERO = "UNIT_LOTM_TP_PATH_HOLDER";
local WORM = "UNIT_LOTM_RESCUE_TIME_WORM";
local CAMP_FOUNDER = "UNIT_LOTM_RESCUE_CAMP_FOUNDER";
local VERSION = 6;
local MADNESS_EFFECT_VERSION = 1;
local WALL_EFFECT_VERSION = 3;
local ARMY_EFFECT_VERSION = 2;
local ABILITIES = {"MADNESS","ECHO","ARMY","WALL"};
-- Rescue defines the same stable project identities as normal Thief, while
-- keeping the normal-mode runtime entirely criteria-gated out.
local POTION_BY_SEQUENCE = {
 [9]="PROJECT_LOTM_TP_SWINDLER_POTION",[8]="PROJECT_LOTM_TP_CRYPTOLOGIST_POTION",
 [7]="PROJECT_LOTM_TP_PROMETHEUS_POTION",[6]="PROJECT_LOTM_TP_DREAM_STEALER_POTION",
 [5]="PROJECT_LOTM_TP_PARASITE_POTION",[4]="PROJECT_LOTM_TP_MENTOR_OF_DECEIT_POTION",
 [3]="PROJECT_LOTM_TP_FATE_TROJAN_POTION",[2]="PROJECT_LOTM_TP_WORM_OF_TIME_POTION",
 [1]="PROJECT_LOTM_TP_ERROR_APOTHEOSIS"
};
local POTIONS={};
for sequence=1,9 do POTIONS[POTION_BY_SEQUENCE[sequence]]={sequence,sequence-1}; end
local pendingPotionProjects={};
local pendingPotionProjectKeys={};
local ResolveProjectRow;
local COSTS = {
 MADNESS={40,60,80,100,120,140,160,180,200,220},
 ECHO={40,60,80,100,120,140,160,180,200,220},
 ARMY={40,60,80,100,120,140,160,180,200,220},
 WALL={40,60,80,100,120,140,160,180,200,220}
};
local YIELDS={"YIELD_FOOD","YIELD_PRODUCTION","YIELD_GOLD","YIELD_SCIENCE","YIELD_CULTURE","YIELD_FAITH"};
local P = {
 Balance="LOTM_RESCUE_ENERGY_BALANCE", Spent="LOTM_RESCUE_ENERGY_SPENT",
 LastGlobal="LOTM_RESCUE_ENERGY_LAST_GLOBAL", Version="LOTM_RESCUE_ENERGY_VERSION",
 LastTurn="LOTM_RESCUE_THIEF_LAST_ENERGY_TURN", LastEffectTurn="LOTM_RESCUE_THIEF_LAST_EFFECT_TURN",
 Allocated="LOTM_RESCUE_ABILITY_ALLOCATED_", Cost="LOTM_RESCUE_ABILITY_ALLOC_COST_",
 Level="LOTM_RESCUE_ABILITY_LEVEL_", Applied="LOTM_RESCUE_ABILITY_APPLIED_",
 Sequence2="LOTM_RESCUE_THIEF_S2_DONE", Worm="LOTM_RESCUE_TIME_WORM_ID",
 WormPlot="LOTM_RESCUE_TIME_WORM_LAST_PLOT", WormCooldown="LOTM_RESCUE_TIME_WORM_COOLDOWN", ConvertTurn="LOTM_RESCUE_CAMP_CONVERT_TURN",
 ConvertMode="LOTM_RESCUE_CAMP_CONVERT_MODE", ConvertPending="LOTM_RESCUE_CAMP_CONVERT_PENDING",
 ConvertPlot="LOTM_RESCUE_CAMP_CONVERT_PLOT", ConvertActor="LOTM_RESCUE_CAMP_CONVERT_ACTOR",
 ConvertCity="LOTM_RESCUE_CAMP_CONVERT_CITY",
 ConvertTempActor="LOTM_RESCUE_CAMP_CONVERT_TEMP_ACTOR",
 ConvertTarget="LOTM_RESCUE_CAMP_CONVERT_TARGET",
 CommandSerial="LOTM_RESCUE_THIEF_COMMAND_SERIAL", ProductionBuffer="LOTM_RESCUE_THIEF_PRODUCTION_BUFFER",
  FoundPlot="LOTM_RESCUE_TIME_WORM_FOUND_PLOT", FoundTempActor="LOTM_RESCUE_TIME_WORM_FOUND_TEMP_ACTOR", FoundPending="LOTM_RESCUE_TIME_WORM_FOUND_PENDING", FoundTarget="LOTM_RESCUE_TIME_WORM_FOUND_TARGET", SwindlerGoldAttached="LOTM_RESCUE_TP_SWINDLER_GOLD_ATTACHED"
  ,LastActivePotion="LOTM_RESCUE_THIEF_LAST_ACTIVE_POTION",
 MadnessRefreshSignature="LOTM_RESCUE_MADNESS_REFRESH_SIGNATURE",
 MadnessEffectMigration="LOTM_RESCUE_MADNESS_EFFECT_MIGRATION_VERSION",
 WallModifierMigration="LOTM_RESCUE_WALL_MODIFIER_MIGRATION_VERSION",
 ArmyModifierMigration="LOTM_RESCUE_ARMY_MODIFIER_MIGRATION_VERSION",
 KnowledgeBonusScience="LOTM_RESCUE_THIEF_KNOWLEDGE_BONUS_SCIENCE",
 KnowledgeBonusCulture="LOTM_RESCUE_THIEF_KNOWLEDGE_BONUS_CULTURE",
  KnowledgeBonusFaith="LOTM_RESCUE_THIEF_KNOWLEDGE_BONUS_FAITH",
  GiftNewCitiesToAI="LOTM_RESCUE_THIEF_GIFT_NEW_CITIES_TO_AI"
};

local function N(value,default) if value==nil then return default; end return tonumber(value) or default; end
local function Log(message) print("[LOTM_RESCUE][Thief] "..tostring(message)); end
local function RunTimedTurnSection(playerID,turn,name,callback)
 -- Reuse the diagnostic timer owned by LOTM_UnitAddedPerf.  Keeping clock
 -- access in that one diagnostic module avoids nondeterministic Gameplay
 -- calls while still publishing per-turn milliseconds in Lua.log.
 local sectionName="RescueThief.Turn."..tostring(name);
 local stat=LOTM_UnitAddedPerf~=nil and LOTM_UnitAddedPerf.Sections~=nil and LOTM_UnitAddedPerf.Sections[sectionName] or nil;
 local before=stat~=nil and tonumber(stat.TotalMs) or 0;
 local started=LOTM_UnitAddedPerf~=nil and LOTM_UnitAddedPerf.BeginSection~=nil and LOTM_UnitAddedPerf.BeginSection() or nil;
 callback();
 if LOTM_UnitAddedPerf~=nil and LOTM_UnitAddedPerf.EndSection~=nil then LOTM_UnitAddedPerf.EndSection(sectionName,started,1); end
 stat=LOTM_UnitAddedPerf~=nil and LOTM_UnitAddedPerf.Sections~=nil and LOTM_UnitAddedPerf.Sections[sectionName] or nil;
 local elapsed=stat~=nil and (tonumber(stat.TotalMs) or 0)-before or nil;
 if elapsed~=nil and elapsed>=0 then
  Log(string.format("perf turn player=%s turn=%s section=%s ms=%.3f",tostring(playerID),tostring(turn),tostring(name),elapsed));
 end
end
local function BeginTurnPerf()
 return LOTM_UnitAddedPerf~=nil and LOTM_UnitAddedPerf.BeginSection~=nil and LOTM_UnitAddedPerf.BeginSection() or nil;
end
local function EndTurnPerf(playerID,turn,started)
 local name="RescueThief.Turn.TOTAL";
 local stat=LOTM_UnitAddedPerf~=nil and LOTM_UnitAddedPerf.Sections~=nil and LOTM_UnitAddedPerf.Sections[name] or nil;
 local before=stat~=nil and tonumber(stat.TotalMs) or 0;
 if LOTM_UnitAddedPerf~=nil and LOTM_UnitAddedPerf.EndSection~=nil then LOTM_UnitAddedPerf.EndSection(name,started,1); end
 stat=LOTM_UnitAddedPerf~=nil and LOTM_UnitAddedPerf.Sections~=nil and LOTM_UnitAddedPerf.Sections[name] or nil;
 local elapsed=stat~=nil and (tonumber(stat.TotalMs) or 0)-before or nil;
 if elapsed~=nil and elapsed>=0 then Log(string.format("perf turn player=%s turn=%s section=TOTAL ms=%.3f",tostring(playerID),tostring(turn),elapsed)); end
end
local function AddDigestion(id,category,key,amount)
 if LOTM_RP_State==nil or LOTM_RP_State.TryAddDigestion==nil then return false; end
 return LOTM_RP_State.TryAddDigestion(id,category,"RESCUE_P9:THIEF:"..tostring(key),amount);
end
local function Active()
 return N(Game.GetProperty("LOTM_RESCUE_MODE"),0)==1
  or (LOTM_MP_TurnSync~=nil and LOTM_MP_TurnSync.IsRescueModeConfigured~=nil and LOTM_MP_TurnSync.IsRescueModeConfigured());
end
local function PlayerOf(id) return id~=nil and Players[id] or nil; end
local function IsMajorHuman(id)
 local p=PlayerOf(id); return p~=nil and p:IsAlive() and p:IsMajor() and p:IsHuman();
end
local function IsCivilized(id)
 local p=PlayerOf(id); if p==nil or not p:IsAlive() then return false; end
 local c=PlayerConfigurations[id];
 return (p:IsMajor() or (c~=nil and c:GetCivilizationLevelTypeName()=="CIVILIZATION_LEVEL_CITY_STATE"));
end
local function PathPlayer(id)
 local p=PlayerOf(id); return IsMajorHuman(id) and p:GetProperty("LOTM_RP_PATH")==PATH
  and LOTM_RP_State~=nil and LOTM_RP_State.GetSequence~=nil;
end
local function AnyHumanPath(id)
 return IsMajorHuman(id) and LOTM_RP_State~=nil and LOTM_RP_State.IsAnyPathPlayer~=nil
  and LOTM_RP_State.IsAnyPathPlayer(id);
end
local function Anchor() return LOTM_MP_TurnSync~=nil and LOTM_MP_TurnSync.GetStableAnchorPlayerID~=nil
 and LOTM_MP_TurnSync.GetStableAnchorPlayerID() or (PlayerManager.GetAliveMajors()[1]~=nil and PlayerManager.GetAliveMajors()[1]:GetID() or -1); end
local function Sequence0Anchor()
 local lowest=nil; for _,p in ipairs(PlayerManager.GetAliveMajors() or {}) do if p:IsHuman() and p:GetProperty("LOTM_RP_PATH")==PATH and N(p:GetProperty("LOTM_RP_SEQUENCE"),9)==0 then if lowest==nil or p:GetID()<lowest then lowest=p:GetID(); end end end; return lowest or -1;
end
local function StableRand(limit,label)
 if limit<=0 then return 0; end
 if LOTM_MP_TurnSync~=nil and LOTM_MP_TurnSync.Random~=nil then return LOTM_MP_TurnSync.Random(limit,label); end
 local value=104729; local text=tostring(label or "RESCUE");
 for i=1,#text do value=(value*131+string.byte(text,i))%2147483647; end
 return value%limit;
end
local function Global(key,default) return N(Game.GetProperty(key),default or 0); end
local function SetGlobal(key,value) Game.SetProperty(key,math.floor(tonumber(value) or 0)); end
local function Balance(p) return math.max(0,N(p:GetProperty(P.Balance),0)); end
local function SetBalance(p,value) p:SetProperty(P.Balance,math.max(0,math.floor(value))); end
local function Seq(id) return N(PlayerOf(id):GetProperty("LOTM_RP_SEQUENCE"),9); end

local function GetOtherMajors(id)
 local result={};
 for _,p in ipairs(PlayerManager.GetAliveMajors() or {}) do if p:GetID()~=id then result[#result+1]=p; end end
 table.sort(result,function(a,b) return a:GetID()<b:GetID(); end); return result;
end

local function GrantEnergyForPurification()
 if not Active() or not (LOTM_MP_TurnSync==nil or LOTM_MP_TurnSync.IsStableAnchorPlayer==nil or LOTM_MP_TurnSync.IsStableAnchorPlayer(Anchor())) then return; end
 local total=Global("GLOBAL_PURIFICATION",0);
 for _,p in ipairs(PlayerManager.GetAliveMajors() or {}) do
  local id=p:GetID(); if p:IsHuman() then
   local last=N(p:GetProperty(P.LastGlobal),0);
   if last<total and AnyHumanPath(id) then SetBalance(p,Balance(p)+(total-last)); end
   if last<total then p:SetProperty(P.LastGlobal,total); end
   if N(p:GetProperty(P.Version),0)<VERSION then p:SetProperty(P.Version,VERSION); end
  end
 end
end

local function GrantThiefPerTurn(id)
 if not PathPlayer(id) then return; end
 local p=Players[id]; local turn=Game.GetCurrentGameTurn();
 if N(p:GetProperty(P.LastTurn),-1)==turn then return; end
 -- Redemption Sequence 4 now uses its slot for the camp-city parasite
 -- ability; it no longer grants a separate +2 energy burst.  All rescue
 -- Thief sequences therefore receive the same inherited +1 energy income.
 local amount=1;
 SetBalance(p,Balance(p)+amount); p:SetProperty(P.LastTurn,turn);
 Log("energy income player="..id.." turn="..turn.." amount="..amount.." balance="..Balance(p));
end

local function EnsureSwindlerGold(id)
 if not PathPlayer(id) or Seq(id)>8 then return false; end
 local p=Players[id]; if p.AttachModifierByID==nil then return false; end
 if N(p:GetProperty(P.SwindlerGoldAttached),0)==1 then return true; end
 local ok=pcall(function() p:AttachModifierByID("LOTM_RESCUE_TP_SWINDLER_GOLD"); end)
 if ok then p:SetProperty(P.SwindlerGoldAttached,1); Log("swindler gold modifier attached player="..id.." amount=20"); end
 return ok;
end

local function AttachToCivilizations(modifierID)
 local attached=0;
 for _,p in ipairs(PlayerManager.GetAliveMajors() or {}) do if p.AttachModifierByID~=nil then local ok=pcall(function() p:AttachModifierByID(modifierID); end); if ok then attached=attached+1; end end end
 for _,p in ipairs(PlayerManager.GetAliveMinors() or {}) do if p.AttachModifierByID~=nil then local ok=pcall(function() p:AttachModifierByID(modifierID); end); if ok then attached=attached+1; end end end
 return attached;
end

local function DetachAllFromCivilizations(modifierID)
 local detached=0;
 local function clear(player)
  if player==nil or player.DetachModifierByID==nil then return; end
  -- DetachModifierByID removes one instance on each call.  The loop is
  -- intentionally bounded above the ten-point cap so old saves with stacked
  -- copies are fully normalized without an unbounded scan.
  for _=1,20 do
   local ok=pcall(function() player:DetachModifierByID(modifierID); end);
   if not ok then break; end
   detached=detached+1;
  end
 end
 for _,p in ipairs(PlayerManager.GetAliveMajors() or {}) do clear(p); end
 for _,p in ipairs(PlayerManager.GetAliveMinors() or {}) do clear(p); end
 return detached;
end

local function RebuildWallEffects(level)
 -- A wall point is a global level applied to every civilization.  Rebuilding
 -- all legacy/exact IDs from zero makes deallocation and old-save migration
 -- idempotent.  One exact +5..+50 modifier is attached instead of stacking
 -- the same ID repeatedly, which the engine may collapse in existing saves.
 local cleared=DetachAllFromCivilizations("LOTM_RESCUE_PURIF_WALL_PLUS")
  +DetachAllFromCivilizations("LOTM_RESCUE_PURIF_WALL_MINUS");
 for i=1,10 do cleared=cleared+DetachAllFromCivilizations("LOTM_RESCUE_PURIF_WALL_LEVEL_"..tostring(i)); end
 local attached=0;
 local exactLevel=math.max(0,math.min(10,level));
 if exactLevel>0 then attached=AttachToCivilizations("LOTM_RESCUE_PURIF_WALL_LEVEL_"..tostring(exactLevel)); end
 Log("wall effects rebuilt version="..WALL_EFFECT_VERSION.." level="..tostring(exactLevel).." amount="..tostring(exactLevel*5).." cleared="..cleared.." attached="..attached.." modifierType=MODIFIER_PLAYER_CITIES_ADJUST_OUTER_DEFENSE exactLevelModifier=true");
end

local function RebuildArmyEffects(level)
 -- Match the Red Priest's explicit player-scoped base-strength modifier
 -- chain. Normalize legacy repeated +/-5 attachments first, then attach one
 -- unique total-level modifier so visible strength and combat both get the
 -- exact +5..+50 value.
 local cleared=DetachAllFromCivilizations("LOTM_RESCUE_PURIF_ARMY_PLUS")
  +DetachAllFromCivilizations("LOTM_RESCUE_PURIF_ARMY_MINUS");
 for i=1,10 do cleared=cleared+DetachAllFromCivilizations("LOTM_RESCUE_PURIF_ARMY_LEVEL_"..tostring(i)); end
 local attached=0;
 local exactLevel=math.max(0,math.min(10,level));
 if exactLevel>0 then attached=AttachToCivilizations("LOTM_RESCUE_PURIF_ARMY_LEVEL_"..tostring(exactLevel)); end
 Log("army effects rebuilt version="..ARMY_EFFECT_VERSION.." level="..tostring(exactLevel).." amount="..tostring(exactLevel*5).." cleared="..cleared.." attached="..attached.." modifierType=MODIFIER_LOTM_RP_PLAYER_UNITS_ADJUST_BASE_COMBAT_STRENGTH exactLevelModifier=true");
end

local function ApplyLevelEffects(name,oldLevel,newLevel)
 if newLevel==oldLevel then return; end
 local delta=newLevel-oldLevel; local plus,minus;
 if name=="MADNESS" then return; end
 if name=="WALL" then RebuildWallEffects(newLevel); SetGlobal(P.Applied..name,newLevel); return; end
 if name=="ARMY" then RebuildArmyEffects(newLevel); SetGlobal(P.Applied..name,newLevel); return; end
 if name=="ECHO" then
  for _,yield in ipairs(YIELDS) do
   plus="LOTM_RESCUE_PURIF_ECHO_"..string.sub(yield,7).."_PLUS"; minus="LOTM_RESCUE_PURIF_ECHO_"..string.sub(yield,7).."_MINUS";
   for _=1,math.abs(delta) do AttachToCivilizations(delta>0 and plus or minus); end
  end
 end
 local attached=0;
 if plus~=nil then for _=1,math.abs(delta) do attached=attached+AttachToCivilizations(delta>0 and plus or minus); end end
 SetGlobal(P.Applied..name,newLevel); Log("ability effect name="..name.." level="..newLevel.." delta="..delta.." civilizationAttachments="..attached);
end

local function IsOuterGod(unit)
 return unit~=nil and (N(unit:GetProperty("LOTM_RESCUE_OUTER_GOD"),0)==1 or N(unit:GetProperty("LOTM_RESCUE_OUTER_GOD_MINION"),0)==1);
end
function LOTM_RESCUE_Thief.ApplyMadnessToUnit(unit)
 if not Active() or unit==nil or IsOuterGod(unit) then return false; end
 local level=Global(P.Level.."MADNESS",0); local ability=unit:GetAbility(); if ability==nil then return false; end
 local desired=level>0 and ("LOTM_RESCUE_PURIFICATION_MADNESS_"..tostring(level*5)) or nil;
 for i=1,10 do local id="LOTM_RESCUE_PURIFICATION_MADNESS_"..tostring(i*5); if GameInfo.UnitAbilities[id]~=nil then LOTM_Effects.SetAbilityCount(ability,id,id==desired and 1 or 0); end end
 return true;
end

local function RefreshMadness()
 if not Active() or PlayerManager.GetAliveBarbarians==nil then return; end
 local level=Global(P.Level.."MADNESS",0);
 local activeSerials=tostring(Game.GetProperty("LOTM_WORLD_MONSTER_ACTIVE_SERIALS") or "");
 local signature=tostring(level)..":"..activeSerials;
 if tostring(Game.GetProperty(P.MadnessRefreshSignature) or "")==signature then return; end
 local monsters=0; local applied=0;
 for _,barb in ipairs(PlayerManager.GetAliveBarbarians() or {}) do for _,unit in barb:GetUnits():Members() do
  if LOTM_WORLD_Monsters~=nil and LOTM_WORLD_Monsters.IsMonster~=nil and LOTM_WORLD_Monsters.IsMonster(unit) then
   monsters=monsters+1; if LOTM_RESCUE_Thief.ApplyMadnessToUnit(unit) then applied=applied+1; end
  end
 end end
 Game.SetProperty(P.MadnessRefreshSignature,signature);
 Log("madness effects refreshed version="..MADNESS_EFFECT_VERSION.." level="..level.." strengthDelta="..(-5*level).." monsters="..monsters.." applied="..applied.." abilityTag=CLASS_ALL_COMBAT_UNITS");
end

local function RefreshEffects()
 -- rc.325 changed the wall effect from an unregistered built-in modifier name
 -- to the rescue dynamic player-city modifier.  Existing saves retain the
 -- numeric level/applied properties, so force one level-delta replay exactly
 -- once to materialize the modifier on every existing city after load.
 local wallLevel=math.max(0,math.min(10,Global(P.Level.."WALL",0)));
 local armyLevel=math.max(0,math.min(10,Global(P.Level.."ARMY",0)));
 local forceMadnessMigration=Global(P.MadnessEffectMigration,0)<MADNESS_EFFECT_VERSION;
 if forceMadnessMigration then Game.SetProperty(P.MadnessRefreshSignature,nil); end
 if Global(P.WallModifierMigration,0)<WALL_EFFECT_VERSION then
  RebuildWallEffects(wallLevel);
  SetGlobal(P.Applied.."WALL",wallLevel);
  SetGlobal(P.WallModifierMigration,WALL_EFFECT_VERSION);
 end
 if Global(P.ArmyModifierMigration,0)<ARMY_EFFECT_VERSION then
  RebuildArmyEffects(armyLevel);
  SetGlobal(P.Applied.."ARMY",armyLevel);
  SetGlobal(P.ArmyModifierMigration,ARMY_EFFECT_VERSION);
 end
 for _,name in ipairs(ABILITIES) do local level=math.max(0,math.min(10,Global(P.Level..name,0))); local applied=Global(P.Applied..name,0); if name=="MADNESS" then RefreshMadness(); SetGlobal(P.Applied..name,level); else if applied~=level then ApplyLevelEffects(name,applied,level); end end end
 if forceMadnessMigration then SetGlobal(P.MadnessEffectMigration,MADNESS_EFFECT_VERSION); end
end

local function Allocate(id,name)
 if not Active() or not AnyHumanPath(id) or COSTS[name]==nil then return false,"PLAYER_OR_ABILITY"; end
 local p=Players[id]; local level=Global(P.Level..name,0); if level>=10 then return false,"MAX_LEVEL"; end
 local cost=COSTS[name][level+1]; if Balance(p)<cost then return false,"ENERGY"; end
 SetBalance(p,Balance(p)-cost); p:SetProperty(P.Spent,N(p:GetProperty(P.Spent),0)+cost);
 p:SetProperty(P.Allocated..name,N(p:GetProperty(P.Allocated..name),0)+1);
 local serial=N(p:GetProperty(P.CommandSerial),0)+1; p:SetProperty(P.CommandSerial,serial); p:SetProperty(P.Cost..name.."_"..serial,cost);
 SetGlobal(P.Level..name,level+1); RefreshEffects(); Log("allocate player="..id.." ability="..name.." level="..(level+1).." cost="..cost); return true;
end

-- The row-level minus button removes exactly the most recent point in this
-- ability. Costs come from the per-allocation ledger rather than being
-- recalculated, so refunds remain correct if a later resource changes costs.
local function DeallocateOne(id,name)
 if not Active() or not AnyHumanPath(id) or COSTS[name]==nil then return false,"PLAYER_OR_ABILITY"; end
 local p=Players[id]; local count=N(p:GetProperty(P.Allocated..name),0); if count<=0 then return false,"NO_POINTS"; end
 local level=Global(P.Level..name,0); if level<=0 then return false,"NO_GLOBAL_LEVEL"; end
 local serialTop=N(p:GetProperty(P.CommandSerial),0); local serial=nil; local refund=0;
 for candidate=serialTop,1,-1 do
  local key=P.Cost..name.."_"..candidate; local raw=p:GetProperty(key);
  if raw~=nil then serial=candidate; refund=math.max(0,N(raw,0)); p:SetProperty(key,nil); break; end
 end
 if serial==nil then Log("deallocate rejected player="..id.." ability="..name.." reason=MISSING_COST_LEDGER"); return false,"MISSING_COST_LEDGER"; end
 SetBalance(p,Balance(p)+refund); p:SetProperty(P.Spent,math.max(0,N(p:GetProperty(P.Spent),0)-refund)); p:SetProperty(P.Allocated..name,count-1);
 SetGlobal(P.Level..name,level-1); RefreshEffects(); Log("deallocate player="..id.." ability="..name.." level="..(level-1).." refund="..refund.." serial="..serial); return true;
end

local function ResetOne(id,name)
 if not Active() or not AnyHumanPath(id) or COSTS[name]==nil then return false; end
 local p=Players[id]; local count=N(p:GetProperty(P.Allocated..name),0); if count<=0 then return false; end
 local refund=0; for serial=1,N(p:GetProperty(P.CommandSerial),0) do local key=P.Cost..name.."_"..serial; local cost=p:GetProperty(key); if cost~=nil then refund=refund+N(cost,0); p:SetProperty(key,nil); end end
 SetBalance(p,Balance(p)+refund); p:SetProperty(P.Allocated..name,0); p:SetProperty(P.Spent,math.max(0,N(p:GetProperty(P.Spent),0)-refund));
 local level=Global(P.Level..name,0); SetGlobal(P.Level..name,math.max(0,level-count)); RefreshEffects(); Log("reset player="..id.." ability="..name.." points="..count.." refund="..refund); return true;
end
local function ResetAll(id) local changed=false; for _,name in ipairs(ABILITIES) do changed=ResetOne(id,name) or changed; end return changed; end

local function CopyGold(id)
 local p=Players[id]; local total=0; for _,other in ipairs(GetOtherMajors(id)) do total=total+math.max(0,N(other:GetTreasury():GetGoldYield(),0)); end
 local amount=LOTM_Effects.PercentFloor(total,50); if amount>0 then p:GetTreasury():ChangeGoldBalance(amount); Log("copy gold player="..id.." amount="..amount.." sourceTotal="..total); end
 return amount>0,amount;
end
local function CopyProduction(id)
 local function Producing(queue)
  return queue~=nil and queue.GetCurrentProductionTypeHash~=nil
   and N(queue:GetCurrentProductionTypeHash(),0)~=0;
 end
 local p=Players[id]; local total=0;
 for _,other in ipairs(GetOtherMajors(id)) do for _,city in other:GetCities():Members() do
  if Producing(city:GetBuildQueue()) then total=total+math.max(0,N(city:GetYield(YieldTypes.PRODUCTION),0)); end
 end end
 local amount=LOTM_Effects.PercentFloor(total,10);
 local pending=math.max(0,N(p:GetProperty(P.ProductionBuffer),0))+amount;
 if pending<=0 then return false,0; end
 local city=p:GetCities():GetCapitalCity(); local q=city~=nil and city:GetBuildQueue() or nil; local ok=false;
 if Producing(q) and q.AddProgress~=nil then
  local called,result=pcall(function() return q:AddProgress(pending); end); ok=called and result~=false;
 end
 p:SetProperty(P.ProductionBuffer,ok and 0 or pending);
 Log("copy production player="..id.." amount="..amount.." delivered="..(ok and pending or 0).." queued="..tostring(ok));
 return ok,amount;
end

-- Keep rescue knowledge on the native player yield stack, matching the
-- ordinary Thief's SetKnowledgeYieldBonus implementation.  Only the delta is
-- attached, so repeated turns neither lose nor multiply the previous bonus.
local KNOWLEDGE_BONUS = {
 SCIENCE={Property=P.KnowledgeBonusScience,Plus="LOTM_RESCUE_KNOWLEDGE_SCIENCE_PLUS_1",Minus="LOTM_RESCUE_KNOWLEDGE_SCIENCE_MINUS_1"},
 CULTURE={Property=P.KnowledgeBonusCulture,Plus="LOTM_RESCUE_KNOWLEDGE_CULTURE_PLUS_1",Minus="LOTM_RESCUE_KNOWLEDGE_CULTURE_MINUS_1"},
 FAITH={Property=P.KnowledgeBonusFaith,Plus="LOTM_RESCUE_KNOWLEDGE_FAITH_PLUS_1",Minus="LOTM_RESCUE_KNOWLEDGE_FAITH_MINUS_1"}
};
local function SetKnowledgeYieldBonus(id,player,category,desired)
 local definition=KNOWLEDGE_BONUS[category]; if player==nil or definition==nil or player.AttachModifierByID==nil then return false,0; end
 desired=math.max(0,math.floor(N(desired,0))); local old=math.max(0,math.floor(N(player:GetProperty(definition.Property),0))); local delta=desired-old;
 if delta==0 then return true,old; end
 local modifierID=delta>0 and definition.Plus or definition.Minus; local rollbackID=delta>0 and definition.Minus or definition.Plus; local count=math.abs(delta); local applied=0;
 for _=1,count do
  local ok=pcall(function() player:AttachModifierByID(modifierID); end);
  if not ok then for _=1,applied do pcall(function() player:AttachModifierByID(rollbackID); end); end; Log("knowledge native attach failed player="..id.." category="..category.." old="..old.." desired="..desired.." applied="..applied); return false,old; end
  applied=applied+1;
 end
 player:SetProperty(definition.Property,desired); return true,old;
end

local function CopyKnowledge(id)
 local p=Players[id]; local science,culture,faith=0,0,0;
 for _,other in ipairs(GetOtherMajors(id)) do
  -- Redemption knowledge copy is deliberately half of the previous 20% rate.
  -- Sources are read-only; only the thief's synchronized progress is changed.
  science=science+LOTM_Effects.PercentFloor(other:GetTechs():GetScienceYield(),10);
  culture=culture+LOTM_Effects.PercentFloor(other:GetCulture():GetCultureYield(),10);
  faith=faith+LOTM_Effects.PercentFloor(other:GetReligion():GetFaithYield(),10);
 end
 -- Native modifiers own the actual per-turn settlement and top-panel total.
 -- Do not call ChangeCurrentResearchProgress/ChangeCurrentCulturalProgress or
 -- ChangeFaithBalance here: those APIs either debit a source or create a
 -- one-off progress change, which caused the old rescue implementation to
 -- disappear from the total and to double-apply on later turns.
 SetKnowledgeYieldBonus(id,p,"SCIENCE",science);
 SetKnowledgeYieldBonus(id,p,"CULTURE",culture);
 SetKnowledgeYieldBonus(id,p,"FAITH",faith);
 p:SetProperty("LOTM_RESCUE_THIEF_COPY_SCIENCE_LAST",science);
 p:SetProperty("LOTM_RESCUE_THIEF_COPY_CULTURE_LAST",culture);
 p:SetProperty("LOTM_RESCUE_THIEF_COPY_FAITH_LAST",faith);
 p:SetProperty("LOTM_RESCUE_THIEF_COPY_SCIENCE_TOTAL",N(p:GetProperty("LOTM_RESCUE_THIEF_COPY_SCIENCE_TOTAL"),0)+science);
 p:SetProperty("LOTM_RESCUE_THIEF_COPY_CULTURE_TOTAL",N(p:GetProperty("LOTM_RESCUE_THIEF_COPY_CULTURE_TOTAL"),0)+culture);
 p:SetProperty("LOTM_RESCUE_THIEF_COPY_FAITH_TOTAL",N(p:GetProperty("LOTM_RESCUE_THIEF_COPY_FAITH_TOTAL"),0)+faith);
 Log("copy knowledge player="..id.." science="..science.." culture="..culture.." faith="..faith);
 return science>0 or culture>0 or faith>0,science+culture+faith;
end
local function TriggerBoost(id)
 local p=Players[id]; local candidates={}; local tech=p:GetTechs(); local civ=p:GetCulture();
 for row in GameInfo.Technologies() do if not tech:HasTech(row.Index) and not tech:HasBoostBeenTriggered(row.Index) then candidates[#candidates+1]={"TECH",row.Index}; end end
 for row in GameInfo.Civics() do if not civ:HasCivic(row.Index) and not civ:HasBoostBeenTriggered(row.Index) then candidates[#candidates+1]={"CIVIC",row.Index}; end end
 table.sort(candidates,function(a,b) if a[1]~=b[1] then return a[1]<b[1]; end return a[2]<b[2]; end); if #candidates==0 then return; end
 local pick=candidates[StableRand(#candidates,"RESCUE_THIEF_S7:"..id..":"..Game.GetCurrentGameTurn())+1]; local ok=false; if pick[1]=="TECH" then ok=pcall(function() tech:TriggerBoost(pick[2],1); end) else ok=pcall(function() civ:TriggerBoost(pick[2],1); end) end; return ok;
end

local function DigestBorrowedAbilities(id)
 if not Active() or not PathPlayer(id) or Seq(id)~=2 then return false; end
 local p=Players[id];
 if N(p:GetProperty(P.Sequence2),0)~=2
  or tostring(p:GetProperty("LOTM_RESCUE_THIEF_S2_ABILITIES") or "")==""
  or tostring(p:GetProperty("LOTM_RESCUE_THIEF_S2_TRAITS") or "")=="" then return false; end
 -- Selection and the synchronized turn share one stable per-turn identity.
 -- A valid selection starts its first of six digestion turns immediately.
 return AddDigestion(id,"A","S2_BORROW_ACTIVE:"..Game.GetCurrentGameTurn());
end

local function ProcessThief(id)
 if not PathPlayer(id) then return; end
 local p=Players[id]; local turn=Game.GetCurrentGameTurn(); GrantThiefPerTurn(id); EnsureSwindlerGold(id); if N(p:GetProperty(P.LastEffectTurn),-1)==turn then return; end
  local seq=Seq(id);
  -- Sequence 9 is intentionally limited to its fixed +1 Purification Energy
  -- income.  The rescue gold-copy effect starts at Sequence 8 and is inherited
  -- by lower sequences; do not let the shared per-turn dispatcher leak it into
  -- a newly selected Sequence 9 Thief.
 if seq==9 then AddDigestion(id,"A","S9_ENERGY:"..turn); end
  if seq<=8 then local copied=CopyGold(id); if copied and seq==8 then AddDigestion(id,"A","S8_GOLD:"..turn); end end
 -- Sequence 8 and below inherit the native recurring +20 Gold modifier. It
 -- appears in the top-panel income breakdown and is attached only once.
 if seq<=7 then
  local lastBoost=N(p:GetProperty("LOTM_RESCUE_THIEF_LAST_BOOST_TURN"),-999);
  if turn-lastBoost>=2 and TriggerBoost(id) then if seq==7 then AddDigestion(id,"A","S7_BOOST:"..turn); end p:SetProperty("LOTM_RESCUE_THIEF_LAST_BOOST_TURN",turn); end
 end
 if seq<=6 then local copied=CopyProduction(id); if copied and seq==6 then AddDigestion(id,"A","S6_PRODUCTION:"..turn); end end
 if seq<=5 then local copied=CopyKnowledge(id); if copied and seq==5 then AddDigestion(id,"A","S5_YIELDS:"..turn); end end
 if seq==2 then DigestBorrowedAbilities(id); end
 -- Sequence 2 is selected through the civilization-ability chooser; do not
 -- auto-randomize before the player confirms a source.
 if seq<=1 then LOTM_RESCUE_Thief.CopyThreeAbilities(id); end
 p:SetProperty(P.LastEffectTurn,turn);
end

ResolveProjectRow=function(projectID)
 local row=projectID~=nil and GameInfo.Projects[projectID] or nil;
 if row~=nil then return row; end
 for candidate in GameInfo.Projects() do
  if candidate.Index==projectID or candidate.Hash==projectID or candidate.ProjectType==projectID then return candidate; end
 end
 return nil;
end

local function CivPortableAbilities(civType)
 local result={}; local unique={};
 for row in GameInfo.Units() do if row.TraitType then unique[row.TraitType]=true; end end
 for row in GameInfo.Buildings() do if row.TraitType then unique[row.TraitType]=true; end end
 for row in GameInfo.Districts() do if row.TraitType then unique[row.TraitType]=true; end end
 for row in GameInfo.Improvements() do if row.TraitType then unique[row.TraitType]=true; end end
 for link in GameInfo.CivilizationTraits() do
  if link.CivilizationType==civType and not unique[link.TraitType] then
   local modifiers={};
   for tm in GameInfo.TraitModifiers() do if tm.TraitType==link.TraitType and GameInfo.Modifiers[tm.ModifierId] then modifiers[#modifiers+1]=tm.ModifierId; end end
   if #modifiers>0 then table.sort(modifiers); result[#result+1]={TraitType=link.TraitType,Modifiers=modifiers}; end
  end
 end
 table.sort(result,function(a,b) return a.TraitType<b.TraitType; end); return result;
end
local function CSVSet(value)
 local result={}; for token in string.gmatch(tostring(value or ""),"[^,]+") do result[token]=true; end; return result;
end
local function EncodeStableObjectKey(value)
 local encoded={}; local text=tostring(value or ""); for index=1,#text do encoded[index]=string.format("%02X",string.byte(text,index)); end; return table.concat(encoded);
end
local function FindLegacySelectedSources(id,p)
 local candidates={};
 for _,source in ipairs(PlayerManager.GetWasEverAliveMajors() or {}) do if source:GetID()~=id then candidates[#candidates+1]=source:GetID(); end end
 table.sort(candidates);
 local function WasSelected(list)
  local objectKey="RESCUE_P9:THIEF:S2_ABILITIES_SELECTED:"..table.concat(list,",");
  local dedupKey="LOTM_RP_DIGEST_SEEN_S2_A_"..EncodeStableObjectKey(objectKey);
  return N(p:GetProperty(dedupKey),0)==1;
 end
 for _,a in ipairs(candidates) do for _,b in ipairs(candidates) do if b~=a then for _,c in ipairs(candidates) do
  if c~=a and c~=b and WasSelected({a,b,c}) then return {a,b,c}; end
  end end end end
 for _,a in ipairs(candidates) do for _,b in ipairs(candidates) do if b~=a and WasSelected({a,b}) then return {a,b}; end end end
 for _,a in ipairs(candidates) do if WasSelected({a}) then return {a}; end end
 return {};
end
local function ApplySelectedSources(id,sources,existingModifiers)
 local p=Players[id]; local own=PlayerConfigurations[id]:GetCivilizationTypeName(); local attached={}; local attachedSet=existingModifiers or {}; local traits={}; local traitSet={}; local savedSources={};
 for mod in string.gmatch(tostring(p:GetProperty("LOTM_RESCUE_THIEF_S2_ABILITIES") or ""),"[^,]+") do if attachedSet[mod] then attached[#attached+1]=mod; end end
 for slot,sid in ipairs(sources or {}) do if slot<=3 then
  local source=Players[tonumber(sid)]; local civ=source~=nil and PlayerConfigurations[source:GetID()]:GetCivilizationTypeName() or nil;
  local abilities=civ~=nil and civ~=own and CivPortableAbilities(civ) or {};
  if #abilities>0 then
   local pick=abilities[StableRand(#abilities,"RESCUE_THIEF_S2_TRAIT:"..id..":"..tostring(sid)..":"..slot)+1];
   if pick~=nil and not traitSet[pick.TraitType] then
    traitSet[pick.TraitType]=true; traits[#traits+1]=pick.TraitType; savedSources[#savedSources+1]=tonumber(sid);
    for _,mod in ipairs(pick.Modifiers) do
     if not attachedSet[mod] then local ok=pcall(function() p:AttachModifierByID(mod); end); if ok then attachedSet[mod]=true; attached[#attached+1]=mod; end end
    end
   end
  end
 end end
 table.sort(attached);
 p:SetProperty("LOTM_RESCUE_THIEF_S2_ABILITIES",table.concat(attached,","));
 p:SetProperty("LOTM_RESCUE_THIEF_S2_TRAITS",table.concat(traits,","));
 p:SetProperty("LOTM_RESCUE_THIEF_S2_SOURCES",table.concat(savedSources,","));
 return #traits,#attached;
end
function LOTM_RESCUE_Thief.CopyThreeAbilities(id,sourcePlayerID)
 if not Active() or not PathPlayer(id) or Seq(id)>2 then return false; end
 local p=Players[id]; if p==nil or N(p:GetProperty(P.Sequence2),0)==2 then return false; end
 local sources={};
 if type(sourcePlayerID)=="table" then
  for _,sid in ipairs(sourcePlayerID) do sources[#sources+1]=sid; end
 elseif sourcePlayerID~=nil then
  sources[1]=sourcePlayerID;
 else
  local pool={}; local own=PlayerConfigurations[id]:GetCivilizationTypeName();
  for _,other in ipairs(PlayerManager.GetAliveMajors() or {}) do
   local sid=other:GetID(); local config=PlayerConfigurations[sid]; local civ=config~=nil and config:GetCivilizationTypeName() or nil;
   if sid~=id and civ~=nil and civ~=own and #CivPortableAbilities(civ)>0 then pool[#pool+1]=sid; end
  end
  table.sort(pool);
  while #pool>0 and #sources<3 do local index=StableRand(#pool,"RESCUE_THIEF_S2_SOURCE:"..id..":"..#sources); sources[#sources+1]=table.remove(pool,index+1); end
 end
 -- Validate every source before attaching anything.  The chooser also uses
 -- this registry, including defeated majors; arbitrary Players slots are not
 -- safe to dereference merely because the native wrapper is non-nil.
 if #sources<1 or #sources>3 then return false; end
 local registered={};
 for _,source in ipairs(PlayerManager.GetWasEverAliveMajors() or {}) do registered[source:GetID()]=true; end
 local seen={}; local own=PlayerConfigurations[id]:GetCivilizationTypeName();
 for index,raw in ipairs(sources) do
  local sid=tonumber(raw);
  if sid==nil or sid~=math.floor(sid) or sid==id or not registered[sid] or seen[sid] then return false; end
  local config=PlayerConfigurations[sid]; local civ=config~=nil and config:GetCivilizationTypeName() or nil;
  if civ==nil or civ==own or #CivPortableAbilities(civ)==0 then return false; end
  seen[sid]=true; sources[index]=sid;
 end
 local abilityCount,modifierCount=ApplySelectedSources(id,sources,{}); if abilityCount<=0 or modifierCount<=0 then return false; end
 p:SetProperty(P.Sequence2,2); p:SetProperty("LOTM_RESCUE_THIEF_S2_MIGRATION_VERSION",2);
 Log("sequence2 copied player="..id.." selectedSources="..#sources.." abilities="..abilityCount.." modifiers="..modifierCount); return true;
end
local function OnSelectAbility(id,params)
 if not PathPlayer(id) or Seq(id)~=2 then return; end
 local sources={}; if params~=nil then for i=1,3 do local sid=params["SourcePlayerID"..i]; if sid~=nil then sources[#sources+1]=sid; end end; if #sources==0 and params.SourcePlayerID~=nil then sources[1]=params.SourcePlayerID; end end
 if #sources>0 and #sources<=3 and LOTM_RESCUE_Thief.CopyThreeAbilities(id,sources) then DigestBorrowedAbilities(id); end
end
local function MigrateLegacyS2Selection(id)
 local p=Players[id]; if p==nil or N(p:GetProperty(P.Sequence2),0)~=2 or N(p:GetProperty("LOTM_RESCUE_THIEF_S2_MIGRATION_VERSION"),0)>=2 then return; end
 local existing=CSVSet(p:GetProperty("LOTM_RESCUE_THIEF_S2_ABILITIES")); local sources=FindLegacySelectedSources(id,p);
 local abilityCount,modifierCount=ApplySelectedSources(id,sources,existing);
 if abilityCount==0 then
  local traits={}; local seen={};
  for link in GameInfo.CivilizationTraits() do if not seen[link.TraitType] then for tm in GameInfo.TraitModifiers() do if tm.TraitType==link.TraitType and existing[tm.ModifierId] then seen[link.TraitType]=true; traits[#traits+1]=link.TraitType; break; end end end end
  table.sort(traits); p:SetProperty("LOTM_RESCUE_THIEF_S2_TRAITS",table.concat(traits,",")); abilityCount=#traits;
 end
 p:SetProperty("LOTM_RESCUE_THIEF_S2_MIGRATION_VERSION",2);
 Log("sequence2 legacy migration player="..id.." recoveredSources="..#sources.." abilities="..abilityCount.." modifiers="..modifierCount);
end

local function ActiveMonsterEntries()
	local entries={}; local csv=tostring(Game.GetProperty("LOTM_WORLD_MONSTER_ACTIVE_SERIALS") or "");
	for token in string.gmatch(csv,"[^,]+") do local serial=N(token,0); if serial>0 and N(Game.GetProperty("LOTM_WORLD_MONSTER:"..serial..":LIVE"),0)==1 then
		local owner=N(Game.GetProperty("LOTM_WORLD_MONSTER:"..serial..":OWNER"),-1); local unitID=N(Game.GetProperty("LOTM_WORLD_MONSTER:"..serial..":UNIT_ID"),-1); local unit=owner>=0 and unitID>=0 and UnitManager.GetUnit(owner,unitID) or nil;
		if unit~=nil and not unit:IsDead() and not unit:IsDelayedDeath() and not IsOuterGod(unit) then entries[#entries+1]={Serial=serial,Unit=unit,Tier=N(Game.GetProperty("LOTM_WORLD_MONSTER:"..serial..":TIER"),2)}; end
	end end
	table.sort(entries,function(a,b) return a.Serial<b.Serial; end); return entries;
end
local function WorkshopEntries()
	local entries={}; local csv=tostring(Game.GetProperty("LOTM_PP_WORKSHOP_REGISTRY_PLOTS") or "");
	for token in string.gmatch(csv,"[^,]+") do local index=N(token,-1); local plot=index>=0 and Map.GetPlotByIndex(index) or nil; if plot~=nil and plot:GetImprovementType()==GameInfo.Improvements.IMPROVEMENT_BARBARIAN_CAMP.Index and N(plot:GetProperty("LOTM_PP_WORKSHOP_IS_WORKSHOP"),0)==1 and N(plot:GetProperty("LOTM_RESCUE_WORKSHOP_AUTO_CLEARED"),0)~=1 then entries[#entries+1]=plot; end end
	table.sort(entries,function(a,b) return a:GetIndex()<b:GetIndex(); end); return entries;
end
local function AutoErrorClear(id)
	if not PathPlayer(id) or Seq(id)~=0 or N(Game.GetProperty("LOTM_RESCUE_THIEF_S0_LAST_TURN"),-1)==Game.GetCurrentGameTurn() then return; end
 local anchor=Sequence0Anchor(); if anchor<0 or id~=anchor then return; end
	local candidates={}; for _,entry in ipairs(ActiveMonsterEntries()) do candidates[#candidates+1]={Kind="MONSTER",Entry=entry,Key=entry.Serial}; end
	for _,plot in ipairs(WorkshopEntries()) do candidates[#candidates+1]={Kind="WORKSHOP",Plot=plot,Key=plot:GetIndex()}; end
	if #candidates==0 then Game.SetProperty("LOTM_RESCUE_THIEF_S0_LAST_TURN",Game.GetCurrentGameTurn()); return; end
	local amount=math.max(1,math.floor(#candidates/5)); local selected={};
	for slot=1,math.min(amount,#candidates) do local pick=StableRand(#candidates,"RESCUE_THIEF_S0:"..Game.GetCurrentGameTurn()..":"..slot); selected[#selected+1]=table.remove(candidates,pick+1); end
	for _,target in ipairs(selected) do
		if target.Kind=="MONSTER" then
			local killer=Players[id]:GetUnits():FindID(N(Players[id]:GetProperty("LOTM_RP_UNIT_ID"),-1));
			if killer~=nil and LOTM_RESCUE_SyncActions~=nil and LOTM_RESCUE_SyncActions.MarkScriptedKiller~=nil then LOTM_RESCUE_SyncActions.MarkScriptedKiller(target.Entry.Unit,killer); end
			if UnitManager.Kill~=nil then pcall(UnitManager.Kill,target.Entry.Unit); end
			Log("sequence0 auto-cleared monster player="..id.." serial="..target.Entry.Serial);
		else
			local plot=target.Plot; local killer=Players[id]:GetUnits():FindID(N(Players[id]:GetProperty("LOTM_RP_UNIT_ID"),-1));
			plot:SetProperty("LOTM_PP_WORKSHOP_LAST_HUMAN",id); plot:SetProperty("LOTM_PP_WORKSHOP_CLEARER_UNIT",killer~=nil and killer:GetID() or -1); plot:SetProperty("LOTM_RESCUE_WORKSHOP_AUTO_CLEARED",1);
			if ImprovementBuilder~=nil and ImprovementBuilder.SetImprovementType~=nil then pcall(ImprovementBuilder.SetImprovementType,plot,-1,-1); end
			Log("sequence0 auto-cleared workshop player="..id.." plot="..plot:GetIndex());
		end
	end
	Game.SetProperty("LOTM_RESCUE_THIEF_S0_LAST_TURN",Game.GetCurrentGameTurn());
end

function LOTM_RESCUE_Thief.OnPathSelected(id)
 if not Active() or not PathPlayer(id) then return false; end
 local p=Players[id]; local total=Global("GLOBAL_PURIFICATION",0); local hadBalance=p:GetProperty(P.Balance)~=nil;
 -- Lifecycle calls this initializer immediately after writing PATH_THIEF and
 -- before EnsureHero.  A legacy save may already contain the +1 per-turn
 -- grant but no global baseline; in that case add the historical purification
 -- total exactly once instead of silently losing it.
 if not hadBalance then SetBalance(p,total); end
 if p:GetProperty(P.LastGlobal)==nil then
  if hadBalance and total>0 then SetBalance(p,Balance(p)+total); end
  p:SetProperty(P.LastGlobal,total);
 end
 if p:GetProperty(P.Version)==nil then p:SetProperty(P.Version,VERSION); end
 Log("rescue thief selected player="..id.." purification="..total.." balance="..Balance(p)); return true;
end

function LOTM_RESCUE_Thief.RefreshSequenceState(id)
 if not Active() or not PathPlayer(id) then return false; end
 ProcessThief(id); RefreshEffects(); return true;
end

function LOTM_RESCUE_Thief.ShouldReflectAttack(attacker,target,attackSerial)
 if not Active() or attacker==nil or target==nil then return false; end
 if LOTM_WORLD_Monsters==nil or LOTM_WORLD_Monsters.IsMonster==nil or not LOTM_WORLD_Monsters.IsMonster(attacker) or IsOuterGod(attacker) then return false; end
 local eligible=false; for _,p in ipairs(PlayerManager.GetAliveMajors() or {}) do if PathPlayer(p:GetID()) and Seq(p:GetID())<=3 then eligible=true; break; end end
 if not eligible then return false; end
 local serial=N(attacker:GetProperty("LOTM_WORLD_MONSTER_SERIAL"),0); local turn=Game.GetCurrentGameTurn(); local label="RESCUE_REFLECT:"..turn..":"..serial..":"..tostring(attackSerial or 0); local reflected=StableRand(100,label)<33;
 if reflected then for _,p in ipairs(PlayerManager.GetAliveMajors() or {}) do if PathPlayer(p:GetID()) and Seq(p:GetID())==3 then AddDigestion(p:GetID(),"A","S3_REFLECT:"..turn..":"..serial..":"..tostring(attackSerial or 0)); end end end
 return reflected;
end

local function OnAllocate(id,params) Allocate(id,tostring(params~=nil and params.Ability or "")); end
local function OnDeallocate(id,params) DeallocateOne(id,tostring(params~=nil and params.Ability or "")); end
local function OnReset(id,params) ResetOne(id,tostring(params~=nil and params.Ability or "")); end
local function OnResetAll(id) ResetAll(id); end
local function OnConvert(id,params) LOTM_RESCUE_Thief.ConvertBarbarianCamp(id,tonumber(params~=nil and params.PlotIndex or -1),tostring(params~=nil and params.Mode or "SELF")); end
local function FindRandomMajorAI(playerID,label)
 local candidates={};
 for _,ai in ipairs(PlayerManager.GetAliveMajors() or {}) do
  if ai:IsAlive() and not ai:IsHuman() and ai:GetID()~=playerID then candidates[#candidates+1]=ai; end
 end
 table.sort(candidates,function(a,b) return a:GetID()<b:GetID(); end);
 if #candidates==0 then return nil; end
 return candidates[StableRand(#candidates,"RESCUE_NEW_CITY_OWNER:"..tostring(Game.GetCurrentGameTurn())..":"..tostring(playerID)..":"..tostring(label or "CITY"))+1];
end
local function OnSetCampGiftAI(id)
 if not PathPlayer(id) then return; end
 local p=Players[id]; local enabled=N(p:GetProperty(P.GiftNewCitiesToAI),0)==1; local nextValue=enabled and 0 or 1;
 p:SetProperty(P.GiftNewCitiesToAI,nextValue);
 Log("new city gift toggle player="..tostring(id).." enabled="..tostring(nextValue==1));
end
local function OnPrepareConvert(id,params)
 if not PathPlayer(id) or Seq(id)>4 then return; end; local plotIndex=tonumber(params~=nil and params.PlotIndex or -1); local plot=Map.GetPlotByIndex(plotIndex); local hero=LOTM_RP_State.FindHero(id);
 if plot==nil or hero==nil or hero:GetX()~=plot:GetX() or hero:GetY()~=plot:GetY() or plot:GetImprovementType()~=GameInfo.Improvements.IMPROVEMENT_BARBARIAN_CAMP.Index then return; end
 if N(Players[id]:GetProperty(P.ConvertTurn),-1)==Game.GetCurrentGameTurn() then return; end
 local p=Players[id]; local mode=N(p:GetProperty(P.GiftNewCitiesToAI),0)==1 and "AI" or "SELF";
 p:SetProperty(P.ConvertPlot,plotIndex); p:SetProperty(P.ConvertActor,hero:GetID()); p:SetProperty(P.ConvertTurn,Game.GetCurrentGameTurn()); p:SetProperty(P.ConvertMode,mode); p:SetProperty(P.ConvertPending,1); Log("camp conversion prepared player="..id.." plot="..plotIndex.." mode="..mode);
end
local function OnFinalizeConvert(id,params)
 local p=Players[id]; if p==nil or N(p:GetProperty(P.ConvertPending),0)~=2 then return; end; local cityID=N(p:GetProperty(P.ConvertCity),-1); local city=cityID>=0 and CityManager.GetCity(id,cityID) or nil; if city==nil then return; end
 local mode=tostring(params~=nil and params.Mode or "SELF"); local ownerOK=true; local finalOwner=id;
 if mode=="AI" then local candidates={}; for _,ai in ipairs(PlayerManager.GetAliveMajors() or {}) do if not ai:IsHuman() and ai:GetID()~=id then candidates[#candidates+1]=ai; end end; table.sort(candidates,function(a,b)return a:GetID()<b:GetID();end); if #candidates==0 then return; end; local target=candidates[StableRand(#candidates,"RESCUE_CAMP_GIFT:"..Game.GetCurrentGameTurn()..":"..cityID)+1]; local ok,result=pcall(CityManager.TransferCity,city,target:GetID()); ownerOK=ok and result~=false; finalOwner=target:GetID(); end
 if ownerOK and Seq(id)==4 then AddDigestion(id,"A","S4_CAMP_CITY:"..Game.GetCurrentGameTurn()..":"..cityID); end; p:SetProperty(P.ConvertPending,0); Log("camp conversion finalized player="..id.." city="..cityID.." mode="..mode.." owner="..finalOwner);
end
local function OnFound(id,params) LOTM_RESCUE_Thief.FoundTimeWormCity(id,tonumber(params~=nil and params.UnitID or -1),tostring(params~=nil and params.Mode or "SELF")); end

local function RememberWormPlot(player,unit)
 if player==nil or unit==nil then return; end
 local info=GameInfo.Units[unit:GetType()];
 if info==nil or info.UnitType~=WORM then return; end
 local plot=Map.GetPlot(unit:GetX(),unit:GetY());
 if plot~=nil then
  player:SetProperty(P.Worm,unit:GetID());
  player:SetProperty(P.WormPlot,plot:GetIndex());
 end
end

local function FindLiveWorm(player)
 if player==nil then return nil; end
 local unitID=N(player:GetProperty(P.Worm),-1);
 local registered=unitID>=0 and player:GetUnits():FindID(unitID) or nil;
 if registered~=nil and not registered:IsDead() and not registered:IsDelayedDeath() then return registered; end
 -- FOUND_CITY can invalidate the registered wrapper before CityBuilt is
 -- published, so fall back to the player's authoritative unit collection.
 for _,candidate in player:GetUnits():Members() do
  local info=GameInfo.Units[candidate:GetType()];
  if info~=nil and info.UnitType==WORM and not candidate:IsDead() and not candidate:IsDelayedDeath() then return candidate; end
 end
 return nil;
end

local function RestoreWormInCity(player,city)
 if player==nil or city==nil then return nil; end
 local row=GameInfo.Units[WORM]; if row==nil or UnitManager.InitUnit==nil then return nil; end
 local live=FindLiveWorm(player);
 if live~=nil and live:GetX()==city:GetX() and live:GetY()==city:GetY() then RememberWormPlot(player,live); return live; end
 if live~=nil and UnitManager.Kill~=nil then pcall(UnitManager.Kill,live,false); end
 local made=UnitManager.InitUnit(player:GetID(),row.Index,city:GetX(),city:GetY());
 if made~=nil then
  RememberWormPlot(player,made);
  if UnitManager.FinishMoves~=nil then UnitManager.FinishMoves(made); end
  Log("time worm restored in founded city player="..player:GetID().." city="..city:GetID().." unit="..made:GetID());
 else
  Log("time worm restore failed in founded city player="..player:GetID().." city="..city:GetID());
 end
 return made;
end

local function ResolvePlayerCity(player,cityID)
 if player==nil then return nil; end
 local cities=player:GetCities();
 if cities~=nil and cities.FindID~=nil then
  local ok,city=pcall(cities.FindID,cities,cityID); if ok and city~=nil then return city; end
 end
 -- Some game builds expose only Members() on the city collection.
 if cities~=nil and cities.Members~=nil then
  for _,city in cities:Members() do if city~=nil and city:GetID()==cityID then return city; end end
 end
 if CityManager~=nil and CityManager.GetCity~=nil then
  local ok,city=pcall(CityManager.GetCity,player:GetID(),cityID); if ok and city~=nil then return city; end
 end
 return nil;
end

local function OnWormMoved(playerID,unitID)
 local player=Players[playerID]; if player==nil or not PathPlayer(playerID) or Seq(playerID)>1 then return; end
 local unit=UnitManager.GetUnit(playerID,unitID); RememberWormPlot(player,unit);
end

local function TransferNewCityToRandomAI(playerID,city,label)
 if city==nil or N(Players[playerID]:GetProperty(P.GiftNewCitiesToAI),0)~=1 then return true,playerID,false; end
 local candidates={};
 for _,ai in ipairs(PlayerManager.GetAliveMajors() or {}) do
  if ai:IsAlive() and not ai:IsHuman() and ai:GetID()~=playerID then candidates[#candidates+1]=ai; end
 end
 table.sort(candidates,function(a,b) return a:GetID()<b:GetID(); end);
 if #candidates==0 then
  Log("new city gift skipped player="..tostring(playerID).." reason=NO_SURVIVING_MAJOR_AI");
  return false,playerID,false;
 end
 local cityID=city.GetID~=nil and city:GetID() or -1;
 local target=candidates[StableRand(#candidates,"RESCUE_NEW_CITY_GIFT:"..Game.GetCurrentGameTurn()..":"..tostring(cityID)..":"..tostring(label or "CITY"))+1];
 local targetID=target:GetID();
 local ok,result=pcall(function() return CityManager.TransferCity(city,targetID); end);
 -- Do not dereference the pre-transfer city or iterate Player:GetCities() here:
 -- the native transfer invalidates that wrapper, and Members() yields numeric
 -- handles on some builds.  Re-resolve through CityManager after the transfer.
 local transferred=ok and result~=false; local owner=-1; local moved=nil;
 if transferred and CityManager.GetCity~=nil then
  local resolveOK,resolved=pcall(CityManager.GetCity,targetID,cityID);
  if resolveOK and resolved~=nil then moved=resolved; owner=resolved.GetOwner~=nil and resolved:GetOwner() or targetID; end
  transferred=moved~=nil and owner==targetID;
 end
 Log("new city gift player="..tostring(playerID).." city="..tostring(cityID).." target="..tostring(targetID).." ok="..tostring(ok).." result="..tostring(result).." owner="..tostring(owner));
 return transferred,transferred and targetID or playerID,true;
end

-- UI operations are not exposed in synchronized Gameplay. Use the same native
-- PlayerCities:Create entry point as Phase 2 and the Firaxis Australia scenario.
local OnCityBuilt;
local creatingAbilityCity={};
local function ClearCampRequest(player)
 player:SetProperty(P.ConvertPending,0); player:SetProperty(P.ConvertTarget,nil);
 player:SetProperty(P.ConvertActor,nil); player:SetProperty(P.ConvertPlot,nil);
 player:SetProperty(P.ConvertTempActor,nil);
end
local function FoundingFailure(player,plot,reason)
 Log("advanced city refused player="..player:GetID().." plot="..tostring(plot and plot:GetIndex() or -1).." reason="..reason);
 if plot~=nil and Game.AddWorldViewText~=nil and Locale~=nil then
  pcall(Game.AddWorldViewText,player:GetID(),Locale.Lookup("LOC_LOTM_RESCUE_FOUND_FAILED",Locale.Lookup("LOC_LOTM_RESCUE_FOUND_REASON_"..reason)),plot:GetX(),plot:GetY());
 end
 return false;
end
local function AreaID(plot)
 if plot.GetArea==nil then return nil; end
 local area=plot:GetArea();
 if type(area)=="number" then return area; end
 return area~=nil and area:GetID() or nil;
end
local function ValidateFoundingPlot(player,plot)
 if plot==nil then return false,"TERRAIN"; end
 if plot:IsCity() or plot:GetDistrictType()>=0 or (plot.GetWonderType~=nil and plot:GetWonderType()>=0) then return false,"OCCUPIED"; end
 if plot:IsWater() or plot:IsImpassable() then return false,"TERRAIN"; end
 local feature=GameInfo.Features[plot:GetFeatureType()];
 if feature~=nil and (feature.Settlement==false or feature.Settlement==0 or feature.NaturalWonder==true or feature.NaturalWonder==1) then return false,"TERRAIN"; end
 local owner=plot:GetOwner(); if owner~=-1 and owner~=player:GetID() then return false,"FOREIGN"; end
 -- Bounded neighborhood only; never enumerate the map or all cities on click.
 local row=GameInfo.GlobalParameters.CITY_MIN_RANGE;
 local radius=math.max(0,math.floor(N(row and row.Value,3)));
 local area=AreaID(plot);
 for dx=-radius,radius do for dy=-radius,radius do
  local other=Map.GetPlotXYWithRangeCheck(plot:GetX(),plot:GetY(),dx,dy,radius);
  if other~=nil and other:IsCity() then
   local distance=Map.GetPlotDistance(plot:GetX(),plot:GetY(),other:GetX(),other:GetY());
   local otherArea=AreaID(other);
   local minimum=(area~=nil and otherArea~=nil and area~=otherArea) and math.max(0,radius-1) or radius;
   if distance<=minimum then return false,"CITY_DISTANCE"; end
  end
 end end
 return true,nil;
end
local function CreateAdvancedCity(player,plot)
 local cities=player:GetCities();
 if cities==nil or cities.Create==nil or CityManager==nil or CityManager.GetCityAt==nil then
  return FoundingFailure(player,plot,"API");
 end
 local id=player:GetID(); local x,y=plot:GetX(),plot:GetY();
 creatingAbilityCity[id]=true;
 local ok,result=pcall(cities.Create,cities,x,y);
 creatingAbilityCity[id]=nil;
 -- Create can return nil despite success. Resolve the authoritative city after
 -- native initialization; do not grant modifiers from a mid-creation callback.
 local city=CityManager.GetCityAt(x,y);
 if city==nil or city:GetOwner()~=id or city:GetX()~=x or city:GetY()~=y then
  Log("advanced city create result player="..id.." callOK="..tostring(ok).." result="..tostring(result));
  return FoundingFailure(player,plot,"CREATE");
 end
 OnCityBuilt(id,city:GetID());
 Log("advanced city verified player="..id.." city="..city:GetID().." plot="..plot:GetIndex().." api=PlayerCities.Create");
 return true;
end

-- These native one-shot city effects are scoped to the confirmed new city.
-- Receipt is written first because attaching a modifier may publish events.
local function GrantAdvancedCity(player,city,source)
 if city==nil or city:GetOwner()~=player:GetID() then return; end
 local receipt="LOTM_RESCUE_ADVANCED_CITY_"..tostring(city:GetID());
 if N(player:GetProperty(receipt),0)==1 then return; end
 player:SetProperty(receipt,1);
 for _,modifier in ipairs({"LOTM_RESCUE_ADVANCED_CITY_POPULATION","LOTM_RESCUE_ADVANCED_CITY_WALLS"}) do
  local ok,result=pcall(function() return city:AttachModifierByID(modifier); end);
  Log("advanced city effect player="..player:GetID().." city="..city:GetID().." source="..source.." modifier="..modifier.." accepted="..tostring(ok and result~=false));
 end
end

function LOTM_RESCUE_Thief.ConvertBarbarianCamp(id,plotIndex,mode)
 Log("parasite city command player="..tostring(id).." plot="..tostring(plotIndex));
 if not Active() or not PathPlayer(id) or Seq(id)>4 then return false; end
 local p=Players[id];
 if N(p:GetProperty(P.ConvertPending),0)~=0 or N(p:GetProperty(P.FoundPending),0)~=0 or N(p:GetProperty(P.ConvertTurn),-1)==Game.GetCurrentGameTurn() then return false; end
 plotIndex=tonumber(plotIndex);
 if plotIndex==nil or plotIndex<0 or plotIndex~=math.floor(plotIndex) then return false; end
 local plot=Map.GetPlotByIndex(plotIndex);
 if plot==nil or plot:IsCity() then return false; end
 local hero=LOTM_RP_State.FindHero~=nil and LOTM_RP_State.FindHero(id) or nil;
 local info=hero~=nil and GameInfo.Units[hero:GetType()] or nil;
 if hero==nil or hero:IsDead() or hero:IsDelayedDeath() or hero:GetOwner()~=id
  or info==nil or info.UnitType~=HERO or hero:GetX()~=plot:GetX() or hero:GetY()~=plot:GetY() then return false; end
 local heroID=hero:GetID();
 local legal,reason=ValidateFoundingPlot(p,plot);
 if not legal then return FoundingFailure(p,plot,reason); end
 p:SetProperty(P.ConvertTarget,id); p:SetProperty(P.ConvertPlot,plotIndex);
 p:SetProperty(P.ConvertActor,heroID); p:SetProperty(P.ConvertMode,"SELF");
 p:SetProperty(P.ConvertPending,1);
 local oldTurn=p:GetProperty(P.ConvertTurn);
 p:SetProperty(P.ConvertTurn,Game.GetCurrentGameTurn());
 if not CreateAdvancedCity(p,plot) then
  ClearCampRequest(p); p:SetProperty(P.ConvertTurn,oldTurn); return false;
 end
 return true;
end

OnCityBuilt=function(playerID,cityID)
 if not Active() or creatingAbilityCity[playerID] then return; end
 for _,p in ipairs(PlayerManager.GetAliveMajors() or {}) do
  if p:IsHuman() and p:GetProperty("LOTM_RP_PATH")==PATH then
    local campPending=N(p:GetProperty(P.ConvertPending),0)==1;
    local campPlot=N(p:GetProperty(P.ConvertPlot),-1);
    local campCity=campPending and playerID==p:GetID() and ResolvePlayerCity(p,cityID) or nil;
    local campLocation=campCity~=nil and Map.GetPlot(campCity:GetX(),campCity:GetY()) or nil;
    local campReceipt="LOTM_RESCUE_CAMP_FOUNDED_CITY_"..tostring(cityID);
    local matchesCampRequest=campLocation~=nil and campLocation:GetIndex()==campPlot;
    local isCampCity=matchesCampRequest or (playerID==p:GetID() and N(p:GetProperty(campReceipt),0)==1);
    if matchesCampRequest then
     p:SetProperty(campReceipt,1);
     local actorID=N(p:GetProperty(P.ConvertActor),-1);
     local actor=actorID>=0 and p:GetUnits():FindID(actorID) or nil;
     local actorInfo=actor~=nil and GameInfo.Units[actor:GetType()] or nil;
     -- Clear the pending flag before Kill publishes any reentrant events.
     ClearCampRequest(p);
     GrantAdvancedCity(p,campCity,"PARASITE");
     if Seq(p:GetID())<=4 and actorInfo~=nil and actorInfo.UnitType==HERO
      and actor:GetOwner()==p:GetID()
      and not actor:IsDead() and not actor:IsDelayedDeath() then
      local killed,result=pcall(UnitManager.Kill,actor);
      if killed and result~=false then
       if LOTM_RP_State.ScheduleRespawn~=nil then LOTM_RP_State.ScheduleRespawn(p:GetID()); end
       if Seq(p:GetID())==4 then AddDigestion(p:GetID(),"A","S4_CAMP_CITY:"..Game.GetCurrentGameTurn()..":"..tostring(cityID)..":"..campPlot); end
       Log("camp conversion committed player="..p:GetID().." city="..cityID.." holder="..actorID.." respawnTurns=5");
      else Log("camp conversion holder removal failed player="..p:GetID().." holder="..actorID); end
     end
    end
    local foundPlot=N(p:GetProperty(P.FoundPlot),-1);
    local builtCity=playerID==p:GetID() and ResolvePlayerCity(p,cityID) or nil;
    local location=builtCity~=nil and Map.GetPlot(builtCity:GetX(),builtCity:GetY()) or nil;
    if not isCampCity and N(p:GetProperty(P.FoundPending),0)==1
     and Seq(p:GetID())<=1 and location~=nil and location:GetIndex()==foundPlot then
     -- Only the requested owner/plot can commit. Clearing first makes duplicate
     -- and reentrant CityBuilt notifications harmless, including after reload.
     p:SetProperty(P.FoundPending,0); p:SetProperty(P.FoundTarget,nil);
     p:SetProperty(P.FoundPlot,nil); p:SetProperty(P.FoundTempActor,nil);
     p:SetProperty(P.WormCooldown,Game.GetCurrentGameTurn()+3);
     GrantAdvancedCity(p,builtCity,"TIME_WORM");
     local worm=p:GetUnits():FindID(N(p:GetProperty(P.Worm),-1));
     if worm~=nil and not worm:IsDead() and UnitManager.FinishMoves~=nil then UnitManager.FinishMoves(worm); end
     if Seq(p:GetID())==1 then AddDigestion(p:GetID(),"A","S1_WORM_CITY:"..Game.GetCurrentGameTurn()..":"..tostring(cityID)); end
     Log("time worm found committed player="..p:GetID().." city="..cityID.." cooldownTurns=3");
    end

  end
 end
end
function LOTM_RESCUE_Thief.FoundTimeWormCity(id,unitID,mode)
 Log("time worm city command player="..tostring(id).." unit="..tostring(unitID));
 if not Active() or not PathPlayer(id) or Seq(id)>1 then return false; end
 local p=Players[id]; unitID=tonumber(unitID);
 if unitID==nil or unitID<0 or unitID~=math.floor(unitID) or N(p:GetProperty(P.FoundPending),0)==1 or N(p:GetProperty(P.ConvertPending),0)~=0 then return false; end
 local worm=p:GetUnits():FindID(unitID); if worm==nil or worm:IsDead() or worm:IsDelayedDeath() then return false; end
 local info=GameInfo.Units[worm:GetType()]; if info==nil or info.UnitType~=WORM then return false; end
 local ready=N(p:GetProperty(P.WormCooldown),-1); if ready>Game.GetCurrentGameTurn() then return false; end
 if worm:GetOwner()~=id then return false; end
 local plot=Map.GetPlot(worm:GetX(),worm:GetY());
 if plot==nil or plot:IsCity() then return false; end
 local legal,reason=ValidateFoundingPlot(p,plot);
 if not legal then return FoundingFailure(p,plot,reason); end
 RememberWormPlot(p,worm);
 p:SetProperty(P.FoundPending,1); p:SetProperty(P.FoundTarget,id);
 p:SetProperty(P.FoundPlot,plot:GetIndex());
 if not CreateAdvancedCity(p,plot) then
  p:SetProperty(P.FoundPending,0); p:SetProperty(P.FoundTarget,nil); p:SetProperty(P.FoundPlot,nil);
  return false;
 end
 return true;
end

local function EnsureWorm(id)
 if not PathPlayer(id) or Seq(id)>1 then return; end
 local p=Players[id]; local row=GameInfo.Units[WORM]; if row==nil then return; end; local unitID=N(p:GetProperty(P.Worm),-1); local unit=unitID>=0 and p:GetUnits():FindID(unitID) or nil; if unit~=nil and not unit:IsDead() then RememberWormPlot(p,unit); return; end
 -- Recovery after loss uses the last owned city location, then the capital.
 -- Recovery is not a founding receipt and must never grant city bonuses.
  local restorePlot=N(p:GetProperty(P.WormPlot),-1); local city=nil;
  if restorePlot>=0 then
   local cities=p:GetCities();
   if cities~=nil and cities.Members~=nil then
    for _,candidate in cities:Members() do
     if candidate~=nil and Map.GetPlot(candidate:GetX(),candidate:GetY())~=nil
       and Map.GetPlot(candidate:GetX(),candidate:GetY()):GetIndex()==restorePlot then city=candidate; break; end
    end
   end
   if city==nil then
    local restoreCity=Map.GetPlotByIndex(restorePlot);
    if restoreCity~=nil and restoreCity:IsCity() and CityManager~=nil and CityManager.GetCityAt~=nil then city=CityManager.GetCityAt(restoreCity:GetX(),restoreCity:GetY()); end
   end
  end
  if city==nil then city=p:GetCities():GetCapitalCity(); end
  if city==nil then return; end
  local made=RestoreWormInCity(p,city);

end

local function ApplyPotionProjectCompleted(playerID,cityID,projectID,eventTurn)
 if not PathPlayer(playerID) then return false; end
 local row=ResolveProjectRow(projectID); local advance=row~=nil and POTIONS[row.ProjectType] or nil;
 if advance==nil then return false; end
 local current=Seq(playerID);
 if current~=advance[1] then
  Log("potion completion rejected player="..playerID.." project="..tostring(row.ProjectType).." sequence="..current.." expected="..advance[1]);
  return false;
 end
 local ok=LOTM_RP_State.AdvanceSequence(playerID,advance[1],advance[2],true);
 if ok then Log("potion completed player="..playerID.." project="..row.ProjectType.." sequence="..advance[1].."->"..advance[2].." turn="..tostring(eventTurn or Game.GetCurrentGameTurn())); end
 return ok;
end

local function OnCityProjectCompleted(playerID,cityID,projectID)
 local row=ResolveProjectRow(projectID);
 if row==nil then Log("project completion observed but project row unresolved player="..tostring(playerID).." city="..tostring(cityID).." project="..tostring(projectID)); return; end
 if not PathPlayer(playerID) or POTIONS[row.ProjectType]==nil then return; end
 Log("project completion observed player="..tostring(playerID).." city="..tostring(cityID).." project="..tostring(row.ProjectType));
 if LOTM_MP_TurnSync~=nil and LOTM_MP_TurnSync.IsNetworkGame~=nil and LOTM_MP_TurnSync.IsNetworkGame() then
  local turn=Game.GetCurrentGameTurn(); local key=table.concat({turn,playerID,cityID,projectID},":");
  if pendingPotionProjectKeys[key]~=nil then return; end
  local entry={QueuedTurn=turn,PlayerID=tonumber(playerID),CityID=tonumber(cityID),ProjectID=tonumber(projectID),Key=key};
  if entry.PlayerID~=nil and entry.CityID~=nil and entry.ProjectID~=nil then pendingPotionProjects[#pendingPotionProjects+1]=entry; pendingPotionProjectKeys[key]=entry; end
 else
  ApplyPotionProjectCompleted(playerID,cityID,projectID,nil);
 end
end

-- The engine's ProjectCompletionModifiers writes this player property at
-- completion, using the same property effect as our native goody-hut marker.
-- UI requests only ask us to read it; they cannot create a completion.
local potionReceiptStatus={};
local function ReceiptStatus(playerID,projectType,status)
 local signature=projectType..":"..status;
 if potionReceiptStatus[playerID]~=signature then
  potionReceiptStatus[playerID]=signature;
  Log("native potion receipt player="..playerID.." project="..projectType.." status="..status.." turn="..Game.GetCurrentGameTurn());
 end
end
function LOTM_RESCUE_Thief.ReconcileCompletedPotion(playerID)
 if not Active() or not PathPlayer(playerID) then return false; end
 local current=Seq(playerID); local projectType=POTION_BY_SEQUENCE[current];
 if projectType==nil then return false; end
 if GameInfo.LOTM_RESCUE_PotionCompletions==nil then ReceiptStatus(playerID,projectType,"MISSING_TABLE"); return false; end
 local receipt=GameInfo.LOTM_RESCUE_PotionCompletions[projectType];
 local row=GameInfo.Projects[projectType];
 if receipt==nil or row==nil then ReceiptStatus(playerID,projectType,"MISSING_ROW"); return false; end
 local player=Players[playerID];
 if (tonumber(player:GetProperty(receipt.PropertyKey) or 0) or 0)<=0 then ReceiptStatus(playerID,projectType,"WAIT_PROJECT_MARKER"); return false; end
 local done=ApplyPotionProjectCompleted(playerID,-1,row.Index,Game.GetCurrentGameTurn());
 ReceiptStatus(playerID,projectType,done and "ADVANCED" or "PROGRESSION_REJECTED");
 if done then Log("native potion receipt consumed player="..playerID.." project="..projectType.." turn="..Game.GetCurrentGameTurn()); end
 return done;
end

local function ProcessPotionProjects(playerID)
 if LOTM_MP_TurnSync==nil or not LOTM_MP_TurnSync.IsNetworkGame() or not LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID) then return; end
 local turn=Game.GetCurrentGameTurn(); local ready={}; local waiting={};
 for _,entry in ipairs(pendingPotionProjects) do if entry.QueuedTurn<turn then ready[#ready+1]=entry; else waiting[#waiting+1]=entry; end end
 pendingPotionProjects=waiting;
 table.sort(ready,function(a,b) if a.QueuedTurn~=b.QueuedTurn then return a.QueuedTurn<b.QueuedTurn; end if a.PlayerID~=b.PlayerID then return a.PlayerID<b.PlayerID; end if a.ProjectID~=b.ProjectID then return a.ProjectID<b.ProjectID; end return a.CityID<b.CityID; end);
 for _,entry in ipairs(ready) do if pendingPotionProjectKeys[entry.Key]==entry then pendingPotionProjectKeys[entry.Key]=nil; end ApplyPotionProjectCompleted(entry.PlayerID,entry.CityID,entry.ProjectID,entry.QueuedTurn); end
end

-- An active project disappearing also means cancellation, queue switching,
-- or loss of its city.  This old breadcrumb cannot prove a completion. Clear
-- it on the next synchronized turn; only actual completion events may award
-- a potion, and a legacy save without such evidence receives no guessed one.
local function RecoverPotionCompletionFromProduction(playerID)
 if not PathPlayer(playerID) then return; end
 local p=Players[playerID];
 if p:GetProperty(P.LastActivePotion)~=nil then
  p:SetProperty(P.LastActivePotion,nil);
  Log("legacy potion breadcrumb cleared player="..tostring(playerID).." reason=NO_COMPLETION_EVIDENCE");
 end
end

local function OnTurn(id,isFirst)
 if not Active() or isFirst==false then return; end
 local network=LOTM_MP_TurnSync~=nil and LOTM_MP_TurnSync.IsNetworkGame~=nil and LOTM_MP_TurnSync.IsNetworkGame();
 if network and id~=Anchor() then return; end
 local turn=Game.GetCurrentGameTurn(); local turnStarted=BeginTurnPerf();
 RunTimedTurnSection(id,turn,"ProcessPotionProjects",function() ProcessPotionProjects(id); end);
 -- In single-player PlayerTurnActivated fires for every major civilization.
 -- The previous implementation rescanned every human pathway and every
 -- barbarian monster on each AI activation.  Process only the active human;
 -- multiplayer keeps its synchronized anchor pass over all human players.
 if network then
  RunTimedTurnSection(id,turn,"GrantEnergyForPurification",function() GrantEnergyForPurification(); end);
  for _,p in ipairs(PlayerManager.GetAliveMajors() or {}) do if p:IsHuman() then
   if N(p:GetProperty(P.ConvertPending),0)==1 and Game.GetCurrentGameTurn()-N(p:GetProperty(P.ConvertTurn),Game.GetCurrentGameTurn())>1 then ClearCampRequest(p); Log("camp conversion request expired player="..p:GetID().." plot="..tostring(p:GetProperty(P.ConvertPlot))); end
   RunTimedTurnSection(p:GetID(),turn,"MigrateLegacyS2Selection",function() MigrateLegacyS2Selection(p:GetID()); end);
   RunTimedTurnSection(p:GetID(),turn,"RecoverPotionCompletionFromProduction",function() RecoverPotionCompletionFromProduction(p:GetID()); end);
   RunTimedTurnSection(p:GetID(),turn,"ReconcileCompletedPotion",function() LOTM_RESCUE_Thief.ReconcileCompletedPotion(p:GetID()); end);
   RunTimedTurnSection(p:GetID(),turn,"ProcessThief",function() ProcessThief(p:GetID()); end);
   RunTimedTurnSection(p:GetID(),turn,"EnsureWorm",function() EnsureWorm(p:GetID()); end);
   RunTimedTurnSection(p:GetID(),turn,"AutoErrorClear",function() AutoErrorClear(p:GetID()); end);
  end end
 else
  local p=Players[id];
  if p==nil or not p:IsHuman() then return; end
  if N(p:GetProperty(P.ConvertPending),0)==1 and Game.GetCurrentGameTurn()-N(p:GetProperty(P.ConvertTurn),Game.GetCurrentGameTurn())>1 then
   Log("camp conversion request expired player="..id.." plot="..tostring(p:GetProperty(P.ConvertPlot)));
   ClearCampRequest(p);
  end
  RunTimedTurnSection(id,turn,"GrantEnergyForPurification",function() GrantEnergyForPurification(); end);
  RunTimedTurnSection(id,turn,"MigrateLegacyS2Selection",function() MigrateLegacyS2Selection(id); end);
  RunTimedTurnSection(id,turn,"RecoverPotionCompletionFromProduction",function() RecoverPotionCompletionFromProduction(id); end);
  RunTimedTurnSection(id,turn,"ReconcileCompletedPotion",function() LOTM_RESCUE_Thief.ReconcileCompletedPotion(id); end);
  RunTimedTurnSection(id,turn,"ProcessThief",function() ProcessThief(id); end);
  RunTimedTurnSection(id,turn,"EnsureWorm",function() EnsureWorm(id); end);
  RunTimedTurnSection(id,turn,"AutoErrorClear",function() AutoErrorClear(id); end);
 end
 RunTimedTurnSection(id,turn,"RefreshEffects",function() RefreshEffects(); end);
 EndTurnPerf(id,turn,turnStarted);
end

if Active() then
 GameEvents.LOTM_RESCUE_Command_AllocatePurificationAbility.Add(OnAllocate);
 GameEvents.LOTM_RESCUE_Command_DeallocatePurificationAbility.Add(OnDeallocate);
 GameEvents.LOTM_RESCUE_Command_ResetPurificationAbility.Add(OnReset);
 GameEvents.LOTM_RESCUE_Command_ResetAllPurificationAbilities.Add(OnResetAll);
 -- Legacy city-gift command intentionally not registered.  Rescue cities are
 -- always founded for the human player; keeping this callback unreachable
 -- prevents old-save/UI state from reopening the removed transfer path.
 GameEvents.LOTM_RESCUE_Command_ConvertBarbarianCamp.Add(OnConvert);
 GameEvents.LOTM_RESCUE_Command_FoundTimeWormCity.Add(OnFound);
 GameEvents.LOTM_RESCUE_Command_SelectAbility.Add(OnSelectAbility);
 Events.CityProjectCompleted.Add(OnCityProjectCompleted);
 GameEvents.CityBuilt.Add(OnCityBuilt);
 GameEvents.OnUnitMoved.Add(OnWormMoved);
 LOTM_MP_TurnSync.Add(OnTurn,"RescueThief");
 LOTM_MP_TurnSync.RunStartup(function() OnTurn(Anchor(),true); end,"RescueThief");
 Log("loaded version="..VERSION.." rescueOnly=true");
end
-- END POST_RC241_NEW MODULE: Scripts/LOTM_RESCUE_Thief.lua
end;

m_mp241Loaders["LOTM_RP_Advanced"] = function()
-- BEGIN POST_RC241_RULES MODULE: Scripts/LOTM_RP_Advanced.lua
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("MP.LOTM_RP_Advanced","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"MP.LOTM_RP_Advanced","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"MP.LOTM_RP_Advanced","GameEvents");
-- END RC342 STARTUP TRACE

-- Sequence 6–0 authoritative Gameplay layer.
-- Sequence 2 Weather Manipulation is implemented by synchronized database
-- modifiers; Lua remains responsible for the earlier event-driven effects.

local LOTM_RP_HERO_TYPE :string = "UNIT_LOTM_RP_PATH_HOLDER";
local LOTM_RP_COMMAND_PLAN_TARGET :string = "LOTM_RP_Command_SelectPlanTarget";
local LOTM_RP_PLAN_TARGET_ID :string = "LOTM_RP_PLAN_TARGET_ID";
local LOTM_RP_PLAN_TARGET_READY_AT :string = "LOTM_RP_PLAN_TARGET_READY_AT";
local LOTM_RP_PLAN_WAS_AT_WAR :string = "LOTM_RP_PLAN_WAS_AT_WAR";
local LOTM_RP_PLAN_GOLD_ACTIVE :string = "LOTM_RP_PLAN_GOLD_ACTIVE";
local LOTM_RP_PLAN_GOLD_MODIFIER_ACTIVE :string =
	"LOTM_RP_PLAN_GOLD_MODIFIER_ACTIVE";
local LOTM_RP_PLAN_GOLD_START_MODIFIER :string =
	"LOTM_RP_MOD_PLAN_GOLD_PER_TURN_START";
local LOTM_RP_PLAN_GOLD_STOP_MODIFIER :string =
	"LOTM_RP_MOD_PLAN_GOLD_PER_TURN_STOP";
local LOTM_RP_REAPER_HEAL_TURN :string = "LOTM_RP_REAPER_HEAL_TURN";
local LOTM_RP_FORMATION_BASELINED :string = "LOTM_RP_S4_FORMATION_BASELINED";
local LOTM_RP_FORMATION_OBSERVED :string = "LOTM_RP_S4_FORMATION_OBSERVED";
local LOTM_RP_PROVOKER_GARRISON_ABILITY :string =
	"ABILITY_LOTM_RP_PROVOKER_GARRISONED";
local LOTM_RP_PLAN_TARGET_COOLDOWN :number = 10;
local LOTM_RP_PLAN_FIRST_WAR_GOLD :number = 2000;

local LOTM_RP_PROJECTS :table = {
	["PROJECT_LOTM_RP_CONSPIRATOR_POTION"] = { from = 7, to = 6 },
	["PROJECT_LOTM_RP_REAPER_POTION"] = { from = 6, to = 5 },
	["PROJECT_LOTM_RP_IRONBLOOD_KNIGHT_POTION"] = { from = 5, to = 4 },
	["PROJECT_LOTM_RP_WAR_BISHOP_POTION"] = { from = 4, to = 3 },
	["PROJECT_LOTM_RP_WEATHER_WARLOCK_POTION"] = { from = 3, to = 2 },
	["PROJECT_LOTM_RP_CONQUEROR_POTION"] = { from = 2, to = 1 },
	["PROJECT_LOTM_RP_WAR_FESTIVAL"] = {
		from = 1, to = 0, requiresChurch = true
	},
	["PROJECT_LOTM_RP_WAR_FESTIVAL_UNCONSECRATED"] = {
		from = 1, to = 0, allowWithoutChurch = true
	},
};

local function Log(message :string)
	print("[LOTM_RP][Advanced] " .. message);
end

local function GetPlayer(playerID :number)
	return playerID ~= nil and Players[playerID] or nil;
end

local function GetHeroTypeIndex()
	local definition = GameInfo.Units[LOTM_RP_HERO_TYPE];
	return definition ~= nil and definition.Index or -1;
end

local function IsLivingHero(unit, playerID :number)
	return unit ~= nil
		and unit:GetOwner() == playerID
		and not unit:IsDead()
		and not unit:IsDelayedDeath()
		and unit:GetType() == GetHeroTypeIndex();
end

local function IsAtWar(playerID :number, targetID :number)
	local player = GetPlayer(playerID);
	local diplomacy = player ~= nil and player:GetDiplomacy() or nil;
	return diplomacy ~= nil and diplomacy:IsAtWarWith(targetID);
end

local function IsMajorLivingOpponent(playerID :number, targetID :number)
	local target = GetPlayer(targetID);
	return targetID ~= playerID
		and target ~= nil
		and target:IsAlive()
		and target:IsMajor();
end

local function SetPlanningIncomeModifier(player, shouldBeActive :boolean)
	if player == nil then
		return;
	end
	local isActive =
		(player:GetProperty(LOTM_RP_PLAN_GOLD_MODIFIER_ACTIVE) or 0) == 1;
	if shouldBeActive == isActive then
		return;
	end
	-- Firaxis uses MODIFIER_PLAYER_ADJUST_YIELD_CHANGE + YIELD_GOLD for
	-- genuine Gold-per-turn income.  Attach a balancing -100 modifier when
	-- peace begins because Player exposes AttachModifierByID but no matching
	-- detach operation.
	player:AttachModifierByID(
		shouldBeActive
			and LOTM_RP_PLAN_GOLD_START_MODIFIER
			or LOTM_RP_PLAN_GOLD_STOP_MODIFIER
	);
	player:SetProperty(
		LOTM_RP_PLAN_GOLD_MODIFIER_ACTIVE,
		shouldBeActive and 1 or 0
	);
	Log("player=" .. tostring(player:GetID())
		.. " native planned income active=" .. tostring(shouldBeActive));
end

local function GetIntegerParameter(parameters :table, key)
	local value = parameters ~= nil and tonumber(parameters[key]) or nil;
	return value ~= nil and value == math.floor(value) and value or nil;
end

local function HasIndustrialization(playerID :number)
	local player = GetPlayer(playerID);
	local technology = GameInfo.Technologies["TECH_INDUSTRIALIZATION"];
	return player ~= nil and technology ~= nil
		and player:GetTechs():HasTech(technology.Index);
end

local function IsRescueMode()
	local state = tonumber(Game.GetProperty("LOTM_RESCUE_MODE") or 0) or 0;
	if state == 1 then
		return true;
	end
	local configured = GameConfiguration.GetValue("GAMEMODE_LOTM_RESCUE");
	return configured == true or tonumber(configured or 0) == 1;
end

local function IsCorpsOrArmy(unit)
	if unit == nil then
		return false;
	end
	local formation = unit:GetMilitaryFormation();
	return formation == MilitaryFormationTypes.CORPS_FORMATION
		or formation == MilitaryFormationTypes.ARMY_FORMATION;
end

local function ProcessProvokerGarrison(playerID :number)
	if not LOTM_RP_State.IsEnabledPlayer(playerID) then
		return;
	end
	local hero = LOTM_RP_State.FindHero(playerID);
	if not IsLivingHero(hero, playerID) then
		return;
	end
	local ability = hero:GetAbility();
	if ability == nil then
		return;
	end
	local shouldBeActive = LOTM_RP_State.GetSequence(playerID) <= 8
		and (hero:GetFortifyTurns() or 0) > 0;
	local currentCount = ability:GetAbilityCount(LOTM_RP_PROVOKER_GARRISON_ABILITY) or 0;
	if shouldBeActive and currentCount < 1 then
		ability:ChangeAbilityCount(LOTM_RP_PROVOKER_GARRISON_ABILITY, 1);
	elseif not shouldBeActive and currentCount > 0 then
		ability:ChangeAbilityCount(
			LOTM_RP_PROVOKER_GARRISON_ABILITY,
			-currentCount
		);
	end
	if shouldBeActive then
		local damage = hero:GetDamage() or 0;
		if damage > 0 then
			hero:ChangeDamage(-damage);
		end
	end
end

local function OnCommandSelectPlanTarget(playerID :number, parameters :table)
	local player = GetPlayer(playerID);
	local targetID = GetIntegerParameter(parameters, "TargetPlayerID");
	if player == nil
		or not LOTM_RP_State.IsEnabledPlayer(playerID)
		or IsRescueMode()
		or LOTM_RP_State.GetSequence(playerID) > 6
		or targetID == nil
		or not IsMajorLivingOpponent(playerID, targetID) then
		Log("ERROR rejected plan target player=" .. tostring(playerID));
		return;
	end

	local currentTurn = Game.GetCurrentGameTurn();
	local currentTarget = player:GetProperty(LOTM_RP_PLAN_TARGET_ID) or -1;
	local readyAt = player:GetProperty(LOTM_RP_PLAN_TARGET_READY_AT) or -1;
	if targetID ~= currentTarget and readyAt >= 0 and currentTurn < readyAt then
		Log("ERROR rejected plan target cooldown player=" .. tostring(playerID));
		return;
	end
	if targetID ~= currentTarget then
		local isAtWar = IsAtWar(playerID, targetID);
		player:SetProperty(LOTM_RP_PLAN_TARGET_ID, targetID);
		player:SetProperty(
			LOTM_RP_PLAN_TARGET_READY_AT,
			currentTurn + LOTM_RP_PLAN_TARGET_COOLDOWN
		);
		-- Selecting an already-warring civilization does not fabricate a new
		-- "first entered war" event, but its continuing-war income is active.
		player:SetProperty(LOTM_RP_PLAN_WAS_AT_WAR, isAtWar and 1 or 0);
		player:SetProperty(LOTM_RP_PLAN_GOLD_ACTIVE, isAtWar and 1 or 0);
		SetPlanningIncomeModifier(player, isAtWar);
	end
	Log("player=" .. tostring(playerID) .. " planned target=" .. tostring(targetID));
end

local function ProcessPlannedWarEconomy(playerID :number)
	if not LOTM_RP_State.IsEnabledPlayer(playerID)
		or LOTM_RP_State.GetSequence(playerID) > 6 then
		return;
	end
	local player = GetPlayer(playerID);
	if IsRescueMode() then
		if player ~= nil then
			SetPlanningIncomeModifier(player, false);
			player:SetProperty(LOTM_RP_PLAN_GOLD_ACTIVE, 0);
		end
		return;
	end
	local targetID = player ~= nil
		and (player:GetProperty(LOTM_RP_PLAN_TARGET_ID) or -1) or -1;
	if player == nil or not IsMajorLivingOpponent(playerID, targetID) then
		if player ~= nil then
			player:SetProperty(LOTM_RP_PLAN_GOLD_ACTIVE, 0);
			SetPlanningIncomeModifier(player, false);
		end
		return;
	end

	local isAtWar = IsAtWar(playerID, targetID);
	local wasAtWar = player:GetProperty(LOTM_RP_PLAN_WAS_AT_WAR);
	if wasAtWar == nil or wasAtWar < 0 then
		-- Save/load baseline: do not retroactively pay 2000 Gold for a war
		-- which began before this version observed the relationship.
		player:SetProperty(LOTM_RP_PLAN_WAS_AT_WAR, isAtWar and 1 or 0);
		player:SetProperty(LOTM_RP_PLAN_GOLD_ACTIVE, isAtWar and 1 or 0);
		SetPlanningIncomeModifier(player, isAtWar);
		return;
	end
	if isAtWar and wasAtWar == 0 then
		local firstWarProperty =
			"LOTM_RP_PLAN_FIRST_WAR_REWARDED:" .. tostring(targetID);
		if (player:GetProperty(firstWarProperty) or 0) ~= 1 then
			player:SetProperty(firstWarProperty, 1);
			player:GetTreasury():ChangeGoldBalance(LOTM_RP_PLAN_FIRST_WAR_GOLD);
			if LOTM_RP_State.GetSequence(playerID) == 6 then
				LOTM_RP_State.TryAddDigestion(
					playerID,
					"A",
					"PLANNED_WAR:" .. tostring(targetID)
				);
			end
			Log("player=" .. tostring(playerID)
				.. " first planned war target=" .. tostring(targetID)
				.. " gold=" .. tostring(LOTM_RP_PLAN_FIRST_WAR_GOLD));
		end
	end
	player:SetProperty(LOTM_RP_PLAN_WAS_AT_WAR, isAtWar and 1 or 0);
	player:SetProperty(LOTM_RP_PLAN_GOLD_ACTIVE, isAtWar and 1 or 0);
	SetPlanningIncomeModifier(player, isAtWar);
end

local function OnDiplomacyWarStateChanged(firstPlayerID :number, secondPlayerID :number)
	ProcessPlannedWarEconomy(firstPlayerID);
	ProcessPlannedWarEconomy(secondPlayerID);
end

local function ProcessFormationDigestion(playerID :number)
	if not LOTM_RP_State.IsEnabledPlayer(playerID)
		or LOTM_RP_State.GetSequence(playerID) ~= 4 then
		return;
	end
	local player = GetPlayer(playerID);
	if player == nil then
		return;
	end
	local baseline = player:GetProperty(LOTM_RP_FORMATION_BASELINED) or 0;
	for _, unit in player:GetUnits():Members() do
		if IsCorpsOrArmy(unit) then
			local key = LOTM_RP_FORMATION_OBSERVED .. ":" .. tostring(unit:GetID());
			if baseline ~= 1 then
				unit:SetProperty(key, 1);
			elseif (unit:GetProperty(key) or 0) ~= 1 then
				unit:SetProperty(key, 1);
				LOTM_RP_State.TryAddDigestion(
					playerID,
					"A",
					"FORMATION:" .. tostring(unit:GetID())
				);
			end
		end
	end
	if baseline ~= 1 then
		player:SetProperty(LOTM_RP_FORMATION_BASELINED, 1);
	end
end

local function ProcessWeatherDigestion(playerID :number)
	if not LOTM_RP_State.IsEnabledPlayer(playerID)
		or LOTM_RP_State.GetSequence(playerID) ~= 2 then
		return;
	end
	for _, targetID in ipairs(PlayerManager.GetAliveMajorIDs()) do
		if IsMajorLivingOpponent(playerID, targetID) and IsAtWar(playerID, targetID) then
			LOTM_RP_State.TryAddDigestion(
				playerID,
				"A",
				"WEATHER_WAR_TURN:" .. tostring(Game.GetCurrentGameTurn())
			);
			return;
		end
	end
end

local function IsWithinHeroRange(playerID :number, unit)
	local hero = LOTM_RP_State.FindHero(playerID);
	return hero ~= nil and unit ~= nil
		and Map.GetPlotDistance(hero:GetX(), hero:GetY(), unit:GetX(), unit:GetY())
			<= 6;
end

local function IsDefeatedUnit(defenderUnitID :number, defenderUnit)
	return defenderUnitID ~= nil and defenderUnitID >= 0
		and (defenderUnit == nil or defenderUnit:IsDead() or defenderUnit:IsDelayedDeath());
end

local function HealAfterKill(playerID :number, attackerUnit)
	local currentTurn = Game.GetCurrentGameTurn();
	if attackerUnit == nil
		or (attackerUnit:GetProperty(LOTM_RP_REAPER_HEAL_TURN) or -1) == currentTurn then
		return;
	end
	local amount = IsLivingHero(attackerUnit, playerID) and 60 or 30;
	local damage = attackerUnit:GetDamage() or 0;
	if damage > 0 then
		attackerUnit:ChangeDamage(-math.min(amount, damage));
	end
	attackerUnit:SetProperty(LOTM_RP_REAPER_HEAL_TURN, currentTurn);
end

local function OnCombatOccurred(
	attackerPlayerID :number,
	attackerUnitID :number,
	defenderPlayerID :number,
	defenderUnitID :number
)
	local attackerPlayer = GetPlayer(attackerPlayerID);
	local defenderPlayer = GetPlayer(defenderPlayerID);
	local attacker = attackerPlayer ~= nil
		and attackerPlayer:GetUnits():FindID(attackerUnitID) or nil;
	local defender = defenderPlayer ~= nil
		and defenderPlayer:GetUnits():FindID(defenderUnitID) or nil;
	if attacker == nil or not IsDefeatedUnit(defenderUnitID, defender) then
		return;
	end

	local sequence = LOTM_RP_State.IsEnabledPlayer(attackerPlayerID)
		and LOTM_RP_State.GetSequence(attackerPlayerID) or 10;
	if sequence <= 5 then
		HealAfterKill(attackerPlayerID, attacker);
	end
	if sequence == 5 then
		LOTM_RP_State.TryAddDigestion(
			attackerPlayerID,
			"B",
			"REAPER_KILL:" .. tostring(Game.GetCurrentGameTurn())
				.. ":" .. tostring(attackerUnitID) .. ":" .. tostring(defenderPlayerID)
				.. ":" .. tostring(defenderUnitID)
		);
		if defender ~= nil and (defender:GetDamage() or 0) > 0 then
			LOTM_RP_State.TryAddDigestion(
				attackerPlayerID,
				"A",
				"REAPER_WOUNDED_KILL:" .. tostring(Game.GetCurrentGameTurn())
					.. ":" .. tostring(attackerUnitID) .. ":" .. tostring(defenderPlayerID)
					.. ":" .. tostring(defenderUnitID)
			);
		end
	elseif sequence == 4 and IsWithinHeroRange(attackerPlayerID, attacker) then
		LOTM_RP_State.TryAddDigestion(
			attackerPlayerID,
			"B",
			"IRONBLOOD_AURA_KILL:" .. tostring(Game.GetCurrentGameTurn())
				.. ":" .. tostring(attackerUnitID) .. ":" .. tostring(defenderPlayerID)
				.. ":" .. tostring(defenderUnitID)
		);
	end
end

local function OnCityConquered(
	capturerID :number,
	ownerID :number,
	cityID :number,
	cityX :number,
	cityY :number
)
	if not LOTM_RP_State.IsEnabledPlayer(capturerID) then
		return;
	end
	local sequence = LOTM_RP_State.GetSequence(capturerID);
	if sequence ~= 3 and sequence ~= 1 then
		return;
	end
	local player = GetPlayer(capturerID);
	local city = player ~= nil and player:GetCities():FindID(cityID) or nil;
	if sequence == 3 and city ~= nil and not IsRescueMode() then
		city:ChangeLoyalty(15);
	end
	LOTM_RP_State.TryAddDigestion(
		capturerID,
		"B",
		(sequence == 1 and "CONQUEROR_CITY:" or "CITY_CONQUERED:")
			.. tostring(cityX) .. ":" .. tostring(cityY)
			.. ":" .. tostring(Game.GetCurrentGameTurn())
	);
	if sequence == 1 and city ~= nil and type(city.IsOriginalCapital) == "function" then
		local ok, isOriginalCapital = pcall(city.IsOriginalCapital, city);
		if ok and isOriginalCapital then
			LOTM_RP_State.TryAddDigestion(
				capturerID,
				"A",
				"CONQUEROR_ORIGINAL_CAPITAL:" .. tostring(cityX) .. ":" .. tostring(cityY)
					.. ":" .. tostring(Game.GetCurrentGameTurn())
			);
		end
	end
end

local function OnCityProjectCompleted(playerID :number, cityID :number, projectID :number)
	-- The shared advancement helper validates sequence and digestion, while
	-- this project handler owns the Red Priest path restriction.
	if not LOTM_RP_State.IsEnabledPlayer(playerID) then
		return;
	end
	-- Resolve the engine's synchronized project index directly.  Avoiding a
	-- hash-table scan removes table-order dependence without changing which
	-- project is recognized or any advancement condition.
	local definition = GameInfo.Projects[projectID];
	local projectType = definition ~= nil and definition.ProjectType or nil;
	if projectType == nil then
		return;
	end
	local project = LOTM_RP_PROJECTS[projectType];
	if project == nil then
		return;
	end
	if project.from == 5 and not IsRescueMode() and not HasIndustrialization(playerID) then
		Log("ERROR rejected ironblood advancement without industrialization player=" .. tostring(playerID));
		return;
	end
	if project.requiresChurch then
		local player = GetPlayer(playerID);
		if player == nil or (player:GetProperty("LOTM_RP_CAN_ADVANCE_SEQUENCE_0") or 0) ~= 1 then
			Log("ERROR rejected Red Priest advancement without True God Church player=" .. tostring(playerID));
			return;
		end
	end
	if not LOTM_RP_State.AdvanceSequence(
		playerID,
		project.from,
		project.to,
		project.allowWithoutChurch == true
	) then
		Log("ERROR rejected advanced project player=" .. tostring(playerID)
			.. " project=" .. projectType);
	elseif project.to == 6 then
		ProcessPlannedWarEconomy(playerID);
	end
end

local function OnPlayerTurnActivated(playerID :number, isFirstTimeThisTurn :boolean)
	if not isFirstTimeThisTurn then
		return;
	end
	ProcessProvokerGarrison(playerID);
	ProcessPlannedWarEconomy(playerID);
	ProcessFormationDigestion(playerID);
	ProcessWeatherDigestion(playerID);
end

local function Initialize()
	GameEvents.LOTM_RP_Command_SelectPlanTarget.Add(OnCommandSelectPlanTarget);
	GameEvents.OnCombatOccurred.Add(OnCombatOccurred);
	GameEvents.CityConquered.Add(OnCityConquered);
	Events.CityProjectCompleted.Add(OnCityProjectCompleted);
	Events.DiplomacyDeclareWar.Add(OnDiplomacyWarStateChanged);
	Events.DiplomacyMakePeace.Add(OnDiplomacyWarStateChanged);
	Events.PlayerTurnActivated.Add(OnPlayerTurnActivated);
	for _, playerID in ipairs(PlayerManager.GetAliveMajorIDs()) do
		ProcessProvokerGarrison(playerID);
		ProcessPlannedWarEconomy(playerID);
		ProcessFormationDigestion(playerID);
		ProcessWeatherDigestion(playerID);
	end
	Log("initialized sequence 6-0 core");
end

Initialize();
-- END POST_RC241_RULES MODULE: Scripts/LOTM_RP_Advanced.lua
end;

m_mp241Loaders["LOTM_RP_Arson"] = function()
-- BEGIN RC241 MODULE: Scripts/LOTM_RP_Arson.lua
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("MP.LOTM_RP_Arson","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"MP.LOTM_RP_Arson","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"MP.LOTM_RP_Arson","GameEvents");
-- END RC342 STARTUP TRACE

-- Phase 05 release-candidate deterministic sequence-7 arson command and
-- ordinary-pillage digestion.
-- Every mutation in this file runs in Gameplay after an EXECUTE_SCRIPT command
-- or an authoritative Gameplay event.

local LOTM_RP_COMMAND_NAME :string = "LOTM_RP_Command_Arson";
local LOTM_RP_HERO_TYPE :string = "UNIT_LOTM_RP_PATH_HOLDER";
local LOTM_RP_SEQUENCE_PROPERTY :string = "LOTM_RP_SEQUENCE";
local LOTM_RP_UNIT_ID_PROPERTY :string = "LOTM_RP_UNIT_ID";
local LOTM_RP_ARSON_READY_AT_PROPERTY :string = "LOTM_RP_ARSON_READY_AT";
local LOTM_RP_ARSON_RANGE :number = 6;
local LOTM_RP_ARSON_COOLDOWN :number = 5;
local LOTM_RP_BURN_DURATION :number = 9;

local LOTM_RP_BURN_STARTED_AT :string = "LOTM_RP_BURN_STARTED_AT";
local LOTM_RP_BURN_UNTIL :string = "LOTM_RP_BURN_UNTIL";
local LOTM_RP_BURN_OWNER :string = "LOTM_RP_BURN_OWNER";
local LOTM_RP_BURN_REVISION :string = "LOTM_RP_BURN_REVISION";
local LOTM_RESCUE_ARSON_DAMAGE :string = "LOTM_RESCUE_PHASE9_ARSON_DAMAGE";

local function Log(message :string)
	print("[LOTM_RP][Arson] " .. message);
end

local function Reject(ownerID :number, unitID :number, reason :string)
	Log("ERROR rejected command owner=" .. tostring(ownerID)
		.. " unit=" .. tostring(unitID)
		.. " reason=" .. reason);
	return false;
end

local function IsRescueMode()
	return (tonumber(Game.GetProperty("LOTM_RESCUE_MODE") or 0) or 0) == 1;
end

local function GetHeroTypeIndex()
	local definition = GameInfo.Units[LOTM_RP_HERO_TYPE];
	return definition ~= nil and definition.Index or -1;
end

local function GetIntegerParameter(parameters :table, key)
	if parameters == nil then
		return nil;
	end
	local value = tonumber(parameters[key]);
	if value == nil or value ~= math.floor(value) then
		return nil;
	end
	return value;
end

local function IsEnemyUnit(ownerID :number, targetUnit)
	if targetUnit == nil
		or targetUnit:IsDead()
		or targetUnit:IsDelayedDeath()
		or targetUnit:GetOwner() == ownerID then
		return false;
	end
	local player = Players[ownerID];
	local diplomacy = player ~= nil and player:GetDiplomacy() or nil;
	return diplomacy ~= nil and diplomacy:IsAtWarWith(targetUnit:GetOwner());
end

local function IsGodUnit(targetUnit)
	return targetUnit ~= nil
		and (tonumber(targetUnit:GetProperty("LOTM_RESCUE_PHASE10_IS_GOD") or 0) or 0) == 1;
end

local function HasEnemyUnit(ownerID :number, plot)
	for _, targetUnit in ipairs(Units.GetUnitsInPlot(plot)) do
		if IsEnemyUnit(ownerID, targetUnit)
			and (not IsRescueMode() or not IsGodUnit(targetUnit)) then
			return true;
		end
	end
	return false;
end

local function IsLegalTarget(ownerID :number, unit, plot)
	if plot == nil then
		return false, "missing target plot";
	end
	if plot:IsWater() then
		return false, "target is water";
	end
	if plot:IsCity() then
		return false, "target is a city center";
	end
	if Map.GetPlotDistance(unit:GetX(), unit:GetY(), plot:GetX(), plot:GetY())
		> LOTM_RP_ARSON_RANGE then
		return false, "target is outside range";
	end
	local visibility = PlayersVisibility[ownerID];
	if visibility == nil or not visibility:IsVisible(plot:GetIndex()) then
		return false, "target is not currently visible";
	end
	if not HasEnemyUnit(ownerID, plot) then
		return false, "target has no enemy unit";
	end
	return true, nil;
end

local function MarkBurning(plot, ownerID :number, currentTurn :number)
	plot:SetProperty(LOTM_RP_BURN_STARTED_AT, currentTurn);
	plot:SetProperty(LOTM_RP_BURN_UNTIL, currentTurn + LOTM_RP_BURN_DURATION);
	plot:SetProperty(LOTM_RP_BURN_OWNER, ownerID);
	Game:SetProperty(
		LOTM_RP_BURN_REVISION,
		(Game:GetProperty(LOTM_RP_BURN_REVISION) or 0) + 1
	);
end

local function KillEnemyUnits(ownerID :number, plot)
	local targets = {};
	for _, targetUnit in ipairs(Units.GetUnitsInPlot(plot)) do
		if IsEnemyUnit(ownerID, targetUnit) then
			table.insert(targets, targetUnit);
		end
	end
	-- Units.GetUnitsInPlot does not promise a network-stable iteration order.
	-- Killing in owner/unit-ID order preserves the exact same targets and
	-- effects while making any downstream death events deterministic.
	table.sort(targets, function(left, right)
		if left:GetOwner() ~= right:GetOwner() then
			return left:GetOwner() < right:GetOwner();
		end
		return left:GetID() < right:GetID();
	end);
	for _, targetUnit in ipairs(targets) do
		UnitManager.Kill(targetUnit);
	end
	return #targets;
end

local function DamageEnemyUnits(ownerID :number, plot, amount :number)
	local targets = {};
	for _, targetUnit in ipairs(Units.GetUnitsInPlot(plot)) do
		if IsEnemyUnit(ownerID, targetUnit) and not IsGodUnit(targetUnit) then table.insert(targets, targetUnit); end
	end
	table.sort(targets, function(left, right)
		if left:GetOwner() ~= right:GetOwner() then return left:GetOwner() < right:GetOwner(); end
		return left:GetID() < right:GetID();
	end);
	local killed = 0;
	for _, targetUnit in ipairs(targets) do
		targetUnit:ChangeDamage(amount);
		if targetUnit:IsDead() or targetUnit:IsDelayedDeath() then killed = killed + 1; end
	end
	return #targets, killed;
end

local function AddSuccessWorldText(plot)
	-- Firaxis Gameplay scripts use the four-argument signature.  Keeping this
	-- on the authoritative command path means every client receives the same
	-- activation before rendering its local flyover text.
	Game.AddWorldViewText(
		0,
		Locale.Lookup("LOC_LOTM_RP_ARSON_SUCCESS"),
		plot:GetX(),
		plot:GetY()
	);
end

local function OnCommandArson(
	ownerID :number,
	unitID :number,
	parameters :table
)
	if not LOTM_RP_State.IsEnabledPlayer(ownerID) then
		return Reject(ownerID, unitID, "player is not an enabled path player");
	end

	local player = Players[ownerID];
	if player == nil then
		return Reject(ownerID, unitID, "missing player");
	end
	if not player:IsTurnActive() then
		return Reject(ownerID, unitID, "player turn is not active");
	end
	local unit = player:GetUnits():FindID(unitID);
	if unit == nil
		or unit:IsDead()
		or unit:IsDelayedDeath()
		or unit:GetType() ~= GetHeroTypeIndex() then
		return Reject(ownerID, unitID, "unit is not a living path hero");
	end
	if (player:GetProperty(LOTM_RP_UNIT_ID_PROPERTY) or -1) ~= unitID then
		return Reject(ownerID, unitID, "unit is not the registered hero");
	end
	if (player:GetProperty(LOTM_RP_SEQUENCE_PROPERTY) or 9) > 7 then
		return Reject(ownerID, unitID, "player has not reached sequence 7");
	end

	local currentTurn = Game.GetCurrentGameTurn();
	local readyAt = player:GetProperty(LOTM_RP_ARSON_READY_AT_PROPERTY) or -1;
	if readyAt >= 0 and currentTurn < readyAt then
		return Reject(ownerID, unitID, "cooldown ready at turn " .. tostring(readyAt));
	end
	local rescueDamage = tonumber(Game.GetProperty(LOTM_RESCUE_ARSON_DAMAGE) or 0) or 0;
	if IsRescueMode() and rescueDamage <= 0 then
		return Reject(ownerID, unitID, "rescue direct-damage value is pending");
	end

	local targetX = GetIntegerParameter(parameters, UnitCommandTypes.PARAM_X);
	local targetY = GetIntegerParameter(parameters, UnitCommandTypes.PARAM_Y);
	if targetX == nil or targetY == nil then
		return Reject(ownerID, unitID, "missing or non-integer target coordinates");
	end
	local plot = Map.GetPlot(targetX, targetY);
	local isLegal, reason = IsLegalTarget(ownerID, unit, plot);
	if not isLegal then
		return Reject(ownerID, unitID, reason);
	end

	if IsRescueMode() then
		local damagedCount, killedCount = DamageEnemyUnits(ownerID, plot, rescueDamage);
		player:SetProperty(LOTM_RP_ARSON_READY_AT_PROPERTY,currentTurn + LOTM_RP_ARSON_COOLDOWN);
		LOTM_RP_State.TryAddDigestion(ownerID,"A","RESCUE_P9:ARSON_DAMAGE:"..tostring(currentTurn)..":"..tostring(unitID)..":"..tostring(plot:GetIndex()));
		if killedCount > 0 then
			LOTM_RP_State.TryAddDigestion(ownerID,"B","RESCUE_P9:ARSON_KILL:"..tostring(currentTurn)..":"..tostring(unitID)..":"..tostring(plot:GetIndex()));
		end
		AddSuccessWorldText(plot);
		Log("executed rescue direct damage owner="..tostring(ownerID).." unit="..tostring(unitID).." plot="..tostring(plot:GetIndex()).." damagedEnemyUnits="..tostring(damagedCount).." killedEnemyUnits="..tostring(killedCount).." amount="..tostring(rescueDamage).." readyAt="..tostring(currentTurn + LOTM_RP_ARSON_COOLDOWN));
		return true;
	end

	local killedCount = KillEnemyUnits(ownerID, plot);
	UnitManager.FinishMoves(unit);
	player:SetProperty(
		LOTM_RP_ARSON_READY_AT_PROPERTY,
		currentTurn + LOTM_RP_ARSON_COOLDOWN
	);
	MarkBurning(plot, ownerID, currentTurn);
	LOTM_RP_State.TryAddDigestion(
		ownerID,
		"A",
		"ARSON:" .. tostring(currentTurn)
			.. ":" .. tostring(unitID)
			.. ":" .. tostring(plot:GetIndex())
	);
	AddSuccessWorldText(plot);

	Log("executed owner=" .. tostring(ownerID)
		.. " unit=" .. tostring(unitID)
		.. " plot=" .. tostring(plot:GetIndex())
		.. " killedEnemyUnits=" .. tostring(killedCount)
		.. " readyAt=" .. tostring(currentTurn + LOTM_RP_ARSON_COOLDOWN));
	return true;
end

local function OnPillage(
	playerID :number,
	unitID :number,
	improvementType :number,
	buildingType :number,
	districtType :number,
	plotIndex :number
)
	if not LOTM_RP_State.IsEnabledPlayer(playerID)
		or LOTM_RP_State.GetSequence(playerID) > 7 then
		return;
	end
	local player = Players[playerID];
	local unit = player ~= nil and player:GetUnits():FindID(unitID) or nil;
	if unit == nil
		or unit:IsDead()
		or unit:IsDelayedDeath()
		or unit:GetType() ~= GetHeroTypeIndex()
		or (player:GetProperty(LOTM_RP_UNIT_ID_PROPERTY) or -1) ~= unitID then
		return;
	end

	local currentTurn = Game.GetCurrentGameTurn();

	LOTM_RP_State.TryAddDigestion(
		playerID,
		"B",
		"PILLAGE:" .. tostring(currentTurn)
			.. ":" .. tostring(unitID)
			.. ":" .. tostring(plotIndex)
			.. ":" .. tostring(improvementType)
			.. ":" .. tostring(buildingType)
			.. ":" .. tostring(districtType)
	);
end

local function CleanupExpiredBurning()
	local currentTurn = Game.GetCurrentGameTurn();
	local changed = false;
	for plotIndex = 0, Map.GetPlotCount() - 1 do
		local plot = Map.GetPlotByIndex(plotIndex);
		local burnUntil = plot ~= nil and plot:GetProperty(LOTM_RP_BURN_UNTIL) or nil;
		if burnUntil ~= nil and currentTurn >= burnUntil then
			plot:SetProperty(LOTM_RP_BURN_STARTED_AT, nil);
			plot:SetProperty(LOTM_RP_BURN_UNTIL, nil);
			plot:SetProperty(LOTM_RP_BURN_OWNER, nil);
			changed = true;
		end

	end
	if changed then
		Game:SetProperty(
			LOTM_RP_BURN_REVISION,
			(Game:GetProperty(LOTM_RP_BURN_REVISION) or 0) + 1
		);
	end
end

local function OnPlayerTurnActivated(playerID :number, isFirstTimeThisTurn :boolean)
	if isFirstTimeThisTurn then
		CleanupExpiredBurning();
	end
end

local function Initialize()
	if Game:GetProperty(LOTM_RP_BURN_REVISION) == nil then
		Game:SetProperty(LOTM_RP_BURN_REVISION, 0);
	end
	GameEvents.LOTM_RP_Command_Arson.Add(OnCommandArson);
	GameEvents.OnPillage.Add(OnPillage);
	Events.PlayerTurnActivated.Add(OnPlayerTurnActivated);
	CleanupExpiredBurning();
	Log("initialized command=" .. LOTM_RP_COMMAND_NAME);
end

Initialize();
-- END RC241 MODULE: Scripts/LOTM_RP_Arson.lua
end;

m_mp241Loaders["LOTM_RP_CommandProbe"] = function()
-- BEGIN RC241 MODULE: Scripts/LOTM_RP_CommandProbe.lua
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("MP.LOTM_RP_CommandProbe","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"MP.LOTM_RP_CommandProbe","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"MP.LOTM_RP_CommandProbe","GameEvents");
-- END RC342 STARTUP TRACE

-- Phase 01 multiplayer command probe.
-- This handler deliberately performs no Gameplay mutation.

local LOTM_RP_PROBE_EVENT :string = "LOTM_RP_Command_Probe";

local function FormatParameters(parameters :table)
	if parameters == nil then
		return "<nil>";
	end

	local keys :table = {};
	for key, _ in pairs(parameters) do
		table.insert(keys, key);
	end

	table.sort(keys, function(left, right)
		return tostring(left) < tostring(right);
	end);

	local fields :table = {};
	for _, key in ipairs(keys) do
		table.insert(fields, tostring(key) .. "=" .. tostring(parameters[key]));
	end

	return table.concat(fields, ",");
end

local function OnCommandProbe(ownerID :number, unitID :number, parameters :table)
	print(
		"[LOTM_RP][Probe] owner=" .. tostring(ownerID)
		.. " unit=" .. tostring(unitID)
		.. " parameters={" .. FormatParameters(parameters) .. "}"
	);
	return true;
end

local function Initialize()
	GameEvents.LOTM_RP_Command_Probe.Add(OnCommandProbe);
	print("[LOTM_RP][Probe] Gameplay handler registered for " .. LOTM_RP_PROBE_EVENT);
end

Initialize();
-- END RC241 MODULE: Scripts/LOTM_RP_CommandProbe.lua
end;

m_mp241Loaders["LOTM_RP_Gameplay"] = function()
-- BEGIN RC241 MODULE: Scripts/LOTM_RP_Gameplay.lua
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("MP.LOTM_RP_Gameplay","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"MP.LOTM_RP_Gameplay","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"MP.LOTM_RP_Gameplay","GameEvents");
-- END RC342 STARTUP TRACE

-- Single authoritative Gameplay context.
-- The included modules intentionally share LOTM_RP_State in this environment.

LOTM_MP241_LoadBundledModule("LOTM_UnitAddedPerf");

LOTM_MP241_LoadBundledModule("LOTM_RP_Lifecycle");
LOTM_MP241_LoadBundledModule("LOTM_RP_Progression");
LOTM_MP241_LoadBundledModule("LOTM_PP_Perfect");
LOTM_MP241_LoadBundledModule("LOTM_BE_BlackEmperor");
LOTM_MP241_LoadBundledModule("LOTM_WORLD_State");
LOTM_MP241_LoadBundledModule("LOTM_WORLD_Barbarians");
LOTM_MP241_LoadBundledModule("LOTM_RESCUE_SyncActions");
LOTM_MP241_LoadBundledModule("LOTM_RESCUE_Difficulty");
LOTM_MP241_LoadBundledModule("LOTM_RESCUE_Phase5");
LOTM_MP241_LoadBundledModule("LOTM_RESCUE_Phase6");
LOTM_MP241_LoadBundledModule("LOTM_AI_Cults");
LOTM_MP241_LoadBundledModule("LOTM_AI_Cult_Hanged");
LOTM_MP241_LoadBundledModule("LOTM_RESCUE_Phase7");
LOTM_MP241_LoadBundledModule("LOTM_RESCUE_Phase8");
LOTM_MP241_LoadBundledModule("LOTM_RESCUE_Phase9");
LOTM_MP241_LoadBundledModule("LOTM_RESCUE_Phase9Digestion");
LOTM_MP241_LoadBundledModule("LOTM_RESCUE_Phase10A");
LOTM_MP241_LoadBundledModule("LOTM_RESCUE_Phase10");
LOTM_MP241_LoadBundledModule("LOTM_WORLD_Monsters");
LOTM_MP241_LoadBundledModule("LOTM_WORLD_Events");
LOTM_MP241_LoadBundledModule("LOTM_PP_Artifacts");
LOTM_MP241_LoadBundledModule("LOTM_RESCUE_Artifacts");
LOTM_MP241_LoadBundledModule("LOTM_WORLD_GoodyHuts");
LOTM_MP241_LoadBundledModule("LOTM_PP_Workshops");
LOTM_MP241_LoadBundledModule("LOTM_WORLD_Churches");
LOTM_MP241_LoadBundledModule("LOTM_RP_Arson");
LOTM_MP241_LoadBundledModule("LOTM_RP_Advanced");
LOTM_MP241_LoadBundledModule("LOTM_RP_CommandProbe");
LOTM_MP241_LoadBundledModule("LOTM_DEV_QuickTest");

-- Registered last so each event batch report includes every module above.
Events.UnitAddedToMap.Add(function() LOTM_UnitAddedPerf.EventCompleted(); end);
Events.PlayerTurnActivated.Add(function(playerID,isFirstTimeThisTurn)
	if not LOTM_UnitAddedPerf.FirstTurnReported and isFirstTimeThisTurn~=false then
		LOTM_UnitAddedPerf.FirstTurnReported=true;
		LOTM_UnitAddedPerf.Report("firstPlayerTurn");
		LOTM_UnitAddedPerf.Enabled=false;
	end
end);
-- END RC241 MODULE: Scripts/LOTM_RP_Gameplay.lua
end;

m_mp241Loaders["LOTM_RP_Lifecycle"] = function()
-- BEGIN POST_RC241_DELTA MODULE: Scripts/LOTM_RP_Lifecycle.lua
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("MP.LOTM_RP_Lifecycle","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"MP.LOTM_RP_Lifecycle","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"MP.LOTM_RP_Lifecycle","GameEvents");
-- END RC342 STARTUP TRACE

-- Phase 05 release-candidate authoritative Gameplay state, path selection,
-- hero lifecycle, digestion, and sequence grants.
LOTM_MP241_LoadBundledModule("LOTM_Effects");

local LOTM_RP_STATE_VERSION :number = 36;
local LOTM_PATH_HOLDER_PROMOTION_CLASS :string = "PROMOTION_CLASS_LOTM_RP_PATH_HOLDER";
local LOTM_RP_HERO_TYPE :string = "UNIT_LOTM_RP_PATH_HOLDER";
local LOTM_PP_HERO_TYPE :string = "UNIT_LOTM_PP_PATH_HOLDER";
local LOTM_BE_HERO_TYPE :string = "UNIT_LOTM_BE_PATH_HOLDER";
local LOTM_TP_HERO_TYPE :string = "UNIT_LOTM_TP_PATH_HOLDER";
local LOTM_RP_SELECTED_PATH :string = "PATH_RED_PRIEST";
local LOTM_PP_SELECTED_PATH :string = "PATH_PERFECT";
local LOTM_BE_SELECTED_PATH :string = "PATH_BLACK_EMPEROR";
local LOTM_TP_SELECTED_PATH :string = "PATH_THIEF";
local LOTM_RP_RESPAWN_DELAY :number = 5;
local LOTM_RP_DIGESTION_TARGET :number = 6;
local LOTM_RP_DIGESTION_TURN_CAP :number = 2;
local LOTM_RP_HUNTER_MODIFIER :string = "LOTM_RP_MOD_GRANT_HUNTER_INSTINCT";
local LOTM_RP_PROVOKER_MODIFIER :string = "LOTM_RP_MOD_GRANT_PROVOKER";
local LOTM_RP_PROVOKER_PROJECT_MODIFIER :string = "LOTM_RP_MOD_ALLOW_PROVOKER_PROJECT";
local LOTM_RP_PYROMANIAC_PROJECT_MODIFIER :string = "LOTM_RP_MOD_ALLOW_PYROMANIAC_PROJECT";
local LOTM_RP_CONSPIRATOR_PROJECT_MODIFIER :string = "LOTM_RP_MOD_ALLOW_CONSPIRATOR_PROJECT";
local LOTM_RP_REAPER_PROJECT_MODIFIER :string = "LOTM_RP_MOD_ALLOW_REAPER_PROJECT";
local LOTM_RP_IRONBLOOD_PROJECT_MODIFIER :string = "LOTM_RP_MOD_ALLOW_IRONBLOOD_PROJECT";
local LOTM_RP_WAR_BISHOP_PROJECT_MODIFIER :string = "LOTM_RP_MOD_ALLOW_WAR_BISHOP_PROJECT";
local LOTM_RP_WEATHER_WARLOCK_PROJECT_MODIFIER :string = "LOTM_RP_MOD_ALLOW_WEATHER_WARLOCK_PROJECT";
local LOTM_RP_CONQUEROR_PROJECT_MODIFIER :string = "LOTM_RP_MOD_ALLOW_CONQUEROR_PROJECT";
local LOTM_RP_WAR_FESTIVAL_PROJECT_MODIFIER :string = "LOTM_RP_MOD_ALLOW_WAR_FESTIVAL_PROJECT";
local LOTM_RP_UNCONSECRATED_WAR_FESTIVAL_PROJECT_MODIFIER :string =
	"LOTM_RP_MOD_ALLOW_UNCONSECRATED_WAR_FESTIVAL_PROJECT";
local LOTM_RP_IRONBLOOD_MODIFIER :string = "LOTM_RP_MOD_IRONBLOOD_FRIENDLY_STRENGTH_AURA_V2";
local LOTM_RP_IRONBLOOD_MOVEMENT_MODIFIER :string = "LOTM_RP_MOD_IRONBLOOD_FRIENDLY_MOVEMENT_AURA_V2";
local LOTM_RP_WAR_BISHOP_PRODUCTION_MODIFIER :string = "LOTM_RP_MOD_WAR_BISHOP_PRODUCTION";
local LOTM_RP_WAR_BISHOP_WEARINESS_MODIFIER :string = "LOTM_RP_MOD_WAR_BISHOP_WEARINESS";
local LOTM_RP_WEATHER_ENEMY_STRENGTH_MODIFIER :string = "LOTM_RP_MOD_WEATHER_ENEMY_STRENGTH_AURA_V2";
local LOTM_RP_WEATHER_ENEMY_MOVEMENT_MODIFIER :string = "LOTM_RP_MOD_WEATHER_ENEMY_MOVEMENT_AURA_V2";
local LOTM_RP_WEATHER_ENEMY_WEARINESS_MODIFIER :string = "LOTM_RP_MOD_WEATHER_ENEMY_WEARINESS_AURA_V2";
local LOTM_RP_WEATHER_FRIENDLY_MOVEMENT_MODIFIER :string = "LOTM_RP_MOD_WEATHER_FRIENDLY_MOVEMENT_AURA_V2";
local LOTM_RP_CONQUEST_BYPASS_WALLS_MODIFIER :string = "LOTM_RP_MOD_GRANT_CONQUEST_BYPASS_WALLS";
local LOTM_RP_RED_PRIEST_WAR_PRODUCTION_MODIFIER :string = "LOTM_RP_MOD_RED_PRIEST_WAR_PRODUCTION";
-- Resource 378 revalidates old unlocks against actual digestion and the
-- canonical database rule before repairing a missing project modifier.
local LOTM_RP_PROJECT_UNLOCK_REPAIR_VERSION :number = 5;
-- TEST ONLY: set false (or comment this block) to remove the combat toggle.
local LOTM_TEST_COMBAT_TOGGLE_ENABLED :boolean = false;
local LOTM_TEST_COMBAT_COMMAND :string = "LOTM_RP_Command_TestCombatToggle";
local LOTM_TEST_COMBAT_PLUS_MODIFIER :string = "LOTM_TP_TEST_COMBAT_PLUS_200";
local LOTM_TEST_COMBAT_MINUS_MODIFIER :string = "LOTM_TP_TEST_COMBAT_MINUS_200";
local LOTM_TEST_CAPITAL_PRODUCTION_PLUS_MODIFIER :string = "LOTM_TP_TEST_CAPITAL_PRODUCTION_PLUS_999";
local LOTM_TEST_CAPITAL_PRODUCTION_MINUS_MODIFIER :string = "LOTM_TP_TEST_CAPITAL_PRODUCTION_MINUS_999";
-- A saved property can outlive a runtime modifier instance.  Reconcile the
-- active test state once per player after the save has restored Player data.
local LOTM_TEST_COMBAT_RECONCILED :table = {};

local function IsRescueMode()
	local state = tonumber(Game.GetProperty("LOTM_RESCUE_MODE") or 0) or 0;
	if state == 1 then
		return true;
	end
	if LOTM_MP_TurnSync ~= nil
		and type(LOTM_MP_TurnSync.IsRescueModeConfigured) == "function" then
		return LOTM_MP_TurnSync.IsRescueModeConfigured();
	end
	local configured = GameConfiguration.GetValue("GAMEMODE_LOTM_RESCUE");
	return configured == true or tonumber(configured or 0) == 1;
end

local LOTM_RP_PROPERTIES :table = {
	StateVersion = "LOTM_RP_STATE_VERSION",
	Path = "LOTM_RP_PATH",
	PathDecided = "LOTM_RP_PATH_DECIDED",
	Sequence = "LOTM_RP_SEQUENCE",
	DigestA = "LOTM_RP_DIGEST_A",
	DigestB = "LOTM_RP_DIGEST_B",
	DigestTurn = "LOTM_RP_DIGEST_TURN",
	DigestTurnGain = "LOTM_RP_DIGEST_TURN_GAIN",
	UnitID = "LOTM_RP_UNIT_ID",
	RespawnAt = "LOTM_RP_RESPAWN_AT",
	ArsonReadyAt = "LOTM_RP_ARSON_READY_AT",
	PlanTargetID = "LOTM_RP_PLAN_TARGET_ID",
	PlanTargetReadyAt = "LOTM_RP_PLAN_TARGET_READY_AT",
	PlanWasAtWar = "LOTM_RP_PLAN_WAS_AT_WAR",
	PlanGoldActive = "LOTM_RP_PLAN_GOLD_ACTIVE",
	PlanGoldModifierActive = "LOTM_RP_PLAN_GOLD_MODIFIER_ACTIVE",
	SavedXP = "LOTM_RP_SAVED_XP",
	HunterXPBaseline = "LOTM_RP_HUNTER_XP_BASELINE",
	ChurchStartTurn = "LOTM_RP_CHURCH_START_TURN",
	TrueGodChurch = "LOTM_RP_TRUE_GOD_CHURCH",
	CanAdvanceSequenceZero = "LOTM_RP_CAN_ADVANCE_SEQUENCE_0",
	SequenceZeroCeremonySerial = "LOTM_RP_SEQUENCE0_CEREMONY_SERIAL",
	SequenceZeroCeremonyReadyTurn = "LOTM_RP_SEQUENCE0_CEREMONY_READY_TURN",
	SequenceZeroCeremonyAckSerial = "LOTM_RP_SEQUENCE0_CEREMONY_ACK_SERIAL",
	OpeningComicShown = "LOTM_RP_OPENING_COMIC_SHOWN",
	SavedPromotions = "LOTM_RP_SAVED_PROMOTIONS",
	PromotionTreeMigrated = "LOTM_RP_PROMOTION_TREE_MIGRATED",
	SavedName = "LOTM_RP_SAVED_NAME",
	RiflingAttached = "LOTM_RP_MOD_RIFLING_ATTACHED",
	PlasticsAttached = "LOTM_RP_MOD_PLASTICS_ATTACHED",
	TechIronWorkingAttached = "LOTM_RP_TECH_IRON_WORKING_ATTACHED",
	TechApprenticeshipAttached = "LOTM_RP_TECH_APPRENTICESHIP_ATTACHED",
	TechGunpowderAttached = "LOTM_RP_TECH_GUNPOWDER_ATTACHED",
	TechMilitaryScienceAttached = "LOTM_RP_TECH_MILITARY_SCIENCE_ATTACHED",
	TechReplaceablePartsAttached = "LOTM_RP_TECH_REPLACEABLE_PARTS_ATTACHED",
	TechSatellitesAttached = "LOTM_RP_TECH_SATELLITES_ATTACHED",
	HunterAttached = "LOTM_RP_MOD_HUNTER_ATTACHED",
	ProvokerAttached = "LOTM_RP_MOD_PROVOKER_ATTACHED",
	IronbloodAttached = "LOTM_RP_MOD_IRONBLOOD_ATTACHED",
	IronbloodMovementAttached = "LOTM_RP_MOD_IRONBLOOD_MOVEMENT_ATTACHED",
	IronbloodFriendlyStrengthV2Attached = "LOTM_RP_MOD_IRONBLOOD_FRIENDLY_STRENGTH_V2_ATTACHED",
	IronbloodFriendlyMovementV2Attached = "LOTM_RP_MOD_IRONBLOOD_FRIENDLY_MOVEMENT_V2_ATTACHED",
	WarBishopProductionAttached = "LOTM_RP_MOD_WAR_BISHOP_PRODUCTION_ATTACHED",
	WarBishopWearinessAttached = "LOTM_RP_MOD_WAR_BISHOP_WEARINESS_ATTACHED",
	WeatherEnemyStrengthAttached = "LOTM_RP_MOD_WEATHER_ENEMY_STRENGTH_ATTACHED",
	WeatherEnemyMovementAttached = "LOTM_RP_MOD_WEATHER_ENEMY_MOVEMENT_ATTACHED",
	WeatherEnemyWearinessAttached = "LOTM_RP_MOD_WEATHER_ENEMY_WEARINESS_ATTACHED",
	WeatherEnemyStrengthV2Attached = "LOTM_RP_MOD_WEATHER_ENEMY_STRENGTH_V2_ATTACHED",
	WeatherEnemyMovementV2Attached = "LOTM_RP_MOD_WEATHER_ENEMY_MOVEMENT_V2_ATTACHED",
	WeatherEnemyWearinessV2Attached = "LOTM_RP_MOD_WEATHER_ENEMY_WEARINESS_V2_ATTACHED",
	WeatherFriendlyMovementAttached = "LOTM_RP_MOD_WEATHER_FRIENDLY_MOVEMENT_ATTACHED",
	WeatherFriendlyMovementV2Attached = "LOTM_RP_MOD_WEATHER_FRIENDLY_MOVEMENT_V2_ATTACHED",
	ConquestBypassWallsAttached = "LOTM_RP_MOD_CONQUEST_BYPASS_WALLS_ATTACHED",
	RedPriestWarProductionAttached = "LOTM_RP_MOD_RED_PRIEST_WAR_PRODUCTION_ATTACHED",
	TestCombatBoostActive = "LOTM_TEST_COMBAT_BOOST_ACTIVE",
	ProvokerProjectUnlocked = "LOTM_RP_PROJECT_PROVOKER_UNLOCKED",
	PyromaniacProjectUnlocked = "LOTM_RP_PROJECT_PYROMANIAC_UNLOCKED",
	ConspiratorProjectUnlocked = "LOTM_RP_PROJECT_CONSPIRATOR_UNLOCKED",
	ReaperProjectUnlocked = "LOTM_RP_PROJECT_REAPER_UNLOCKED",
	IronbloodProjectUnlocked = "LOTM_RP_PROJECT_IRONBLOOD_UNLOCKED",
	WarBishopProjectUnlocked = "LOTM_RP_PROJECT_WAR_BISHOP_UNLOCKED",
	WeatherWarlockProjectUnlocked = "LOTM_RP_PROJECT_WEATHER_WARLOCK_UNLOCKED",
	ConquerorProjectUnlocked = "LOTM_RP_PROJECT_CONQUEROR_UNLOCKED",
	WarFestivalProjectUnlocked = "LOTM_RP_PROJECT_WAR_FESTIVAL_UNLOCKED",
	UnconsecratedWarFestivalProjectUnlocked =
		"LOTM_RP_PROJECT_UNCONSECRATED_WAR_FESTIVAL_UNLOCKED",
	ProjectUnlockRepairVersion = "LOTM_RP_PROJECT_UNLOCK_REPAIR_VERSION",
};

local LOTM_RP_DEFAULTS :table = {
	{ key = LOTM_RP_PROPERTIES.Path, value = "NONE" },
	{ key = LOTM_RP_PROPERTIES.PathDecided, value = 0 },
	{ key = LOTM_RP_PROPERTIES.Sequence, value = 9 },
	{ key = LOTM_RP_PROPERTIES.DigestA, value = 0 },
	{ key = LOTM_RP_PROPERTIES.DigestB, value = 0 },
	{ key = LOTM_RP_PROPERTIES.DigestTurn, value = -1 },
	{ key = LOTM_RP_PROPERTIES.DigestTurnGain, value = 0 },
	{ key = LOTM_RP_PROPERTIES.UnitID, value = -1 },
	{ key = LOTM_RP_PROPERTIES.RespawnAt, value = -1 },
	{ key = LOTM_RP_PROPERTIES.ArsonReadyAt, value = -1 },
	{ key = LOTM_RP_PROPERTIES.PlanTargetID, value = -1 },
	{ key = LOTM_RP_PROPERTIES.PlanTargetReadyAt, value = -1 },
	{ key = LOTM_RP_PROPERTIES.PlanWasAtWar, value = -1 },
	{ key = LOTM_RP_PROPERTIES.PlanGoldActive, value = 0 },
	{ key = LOTM_RP_PROPERTIES.PlanGoldModifierActive, value = 0 },
	{ key = LOTM_RP_PROPERTIES.SavedXP, value = 0 },
	{ key = LOTM_RP_PROPERTIES.HunterXPBaseline, value = -1 },
	{ key = LOTM_RP_PROPERTIES.ChurchStartTurn, value = -1 },
	{ key = LOTM_RP_PROPERTIES.TrueGodChurch, value = 0 },
	{ key = LOTM_RP_PROPERTIES.CanAdvanceSequenceZero, value = 0 },
	{ key = LOTM_RP_PROPERTIES.SequenceZeroCeremonySerial, value = 0 },
	{ key = LOTM_RP_PROPERTIES.SequenceZeroCeremonyReadyTurn, value = -1 },
	{ key = LOTM_RP_PROPERTIES.SequenceZeroCeremonyAckSerial, value = 0 },
	{ key = LOTM_RP_PROPERTIES.OpeningComicShown, value = 0 },
	{ key = LOTM_RP_PROPERTIES.SavedPromotions, value = "" },
	{ key = LOTM_RP_PROPERTIES.PromotionTreeMigrated, value = 1 },
	{ key = LOTM_RP_PROPERTIES.SavedName, value = "" },
	{ key = LOTM_RP_PROPERTIES.RiflingAttached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.PlasticsAttached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.TechIronWorkingAttached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.TechApprenticeshipAttached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.TechGunpowderAttached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.TechMilitaryScienceAttached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.TechReplaceablePartsAttached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.TechSatellitesAttached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.HunterAttached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.ProvokerAttached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.IronbloodAttached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.IronbloodMovementAttached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.IronbloodFriendlyStrengthV2Attached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.IronbloodFriendlyMovementV2Attached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.WarBishopProductionAttached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.WarBishopWearinessAttached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.WeatherEnemyStrengthAttached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.WeatherEnemyMovementAttached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.WeatherEnemyWearinessAttached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.WeatherEnemyStrengthV2Attached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.WeatherEnemyMovementV2Attached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.WeatherEnemyWearinessV2Attached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.WeatherFriendlyMovementAttached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.WeatherFriendlyMovementV2Attached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.ConquestBypassWallsAttached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.RedPriestWarProductionAttached, value = 0 },
	{ key = LOTM_RP_PROPERTIES.TestCombatBoostActive, value = 0 },
	{ key = LOTM_RP_PROPERTIES.ProvokerProjectUnlocked, value = 0 },
	{ key = LOTM_RP_PROPERTIES.PyromaniacProjectUnlocked, value = 0 },
	{ key = LOTM_RP_PROPERTIES.ConspiratorProjectUnlocked, value = 0 },
	{ key = LOTM_RP_PROPERTIES.ReaperProjectUnlocked, value = 0 },
	{ key = LOTM_RP_PROPERTIES.IronbloodProjectUnlocked, value = 0 },
	{ key = LOTM_RP_PROPERTIES.WarBishopProjectUnlocked, value = 0 },
	{ key = LOTM_RP_PROPERTIES.WeatherWarlockProjectUnlocked, value = 0 },
	{ key = LOTM_RP_PROPERTIES.ConquerorProjectUnlocked, value = 0 },
	{ key = LOTM_RP_PROPERTIES.WarFestivalProjectUnlocked, value = 0 },
	{ key = LOTM_RP_PROPERTIES.UnconsecratedWarFestivalProjectUnlocked, value = 0 },
	{ key = LOTM_RP_PROPERTIES.ProjectUnlockRepairVersion, value = 0 },
};

local m_creatingHero :table = {};

local function Log(message :string)
	print("[LOTM_RP][Lifecycle] " .. message);
end

local function GetPlayer(playerID :number)
	if playerID == nil then
		return nil;
	end
	return Players[playerID];
end

local function GetHeroTypeIndex(typeName :string)
	local definition = GameInfo.Units[typeName];
	return definition ~= nil and definition.Index or -1;
end

local function IsHeroUnit(unit)
	local unitType = unit ~= nil and unit:GetType() or -1;
	return unit ~= nil
		and not unit:IsDead()
		and not unit:IsDelayedDeath()
		and (unitType == GetHeroTypeIndex(LOTM_RP_HERO_TYPE)
			or unitType == GetHeroTypeIndex(LOTM_PP_HERO_TYPE)
			or unitType == GetHeroTypeIndex(LOTM_BE_HERO_TYPE)
			or unitType == GetHeroTypeIndex(LOTM_TP_HERO_TYPE));
end

local function GetExpectedHeroType(playerID :number)
	local player = GetPlayer(playerID);
	local path = player ~= nil and player:GetProperty(LOTM_RP_PROPERTIES.Path) or "NONE";
	if path == LOTM_PP_SELECTED_PATH then
		return LOTM_PP_HERO_TYPE;
	elseif path == LOTM_BE_SELECTED_PATH then
		return LOTM_BE_HERO_TYPE;
	elseif path == LOTM_TP_SELECTED_PATH then
		return LOTM_TP_HERO_TYPE;
	end
	return LOTM_RP_HERO_TYPE;
end

LOTM_RP_State = LOTM_RP_State or {};

function LOTM_RP_State.EnsurePlayerState(playerID :number)
	local player = GetPlayer(playerID);
	if player == nil then
		return nil;
	end

	local storedVersion = player:GetProperty(LOTM_RP_PROPERTIES.StateVersion);
	if storedVersion ~= nil and storedVersion > LOTM_RP_STATE_VERSION then
		Log("ERROR player=" .. tostring(playerID)
			.. " state version=" .. tostring(storedVersion)
			.. " is newer than supported=" .. tostring(LOTM_RP_STATE_VERSION));
		return player;
	end

	for _, defaultEntry in ipairs(LOTM_RP_DEFAULTS) do
		if player:GetProperty(defaultEntry.key) == nil then
			player:SetProperty(defaultEntry.key, defaultEntry.value);
		end
	end
	-- rc.40 replaces the Recon promotion class. Recreating an existing holder is
	-- required because Gameplay exposes SetPromotion but no removal counterpart;
	-- the one-shot flag prevents inherited Recon modifiers from surviving in saves.
	if storedVersion ~= nil and storedVersion <= 24 then
		player:SetProperty(LOTM_RP_PROPERTIES.PromotionTreeMigrated, 0);
	end

	-- Migrate an already-enabled version-3 save without asking a second time.
	local storedPath = player:GetProperty(LOTM_RP_PROPERTIES.Path);
	if storedVersion ~= nil
		and storedVersion <= 3
		and storedPath == LOTM_RP_SELECTED_PATH then
		player:SetProperty(LOTM_RP_PROPERTIES.Path, LOTM_RP_SELECTED_PATH);
		player:SetProperty(LOTM_RP_PROPERTIES.PathDecided, 1);
	end
	-- rc.20 acknowledged the Sequence 0 ceremony when its UI context entered
	-- the popup queue.  A Firaxis era/age popup could then suppress it even
	-- though Gameplay had already recorded it as shown.  Re-open exactly that
	-- rc.20 serial once on migration; pre-rc.20 Sequence 0 saves have serial 0
	-- and deliberately remain ineligible for backfill.
	if storedVersion == 12
		and (player:GetProperty(LOTM_RP_PROPERTIES.Sequence) or 9) == 0 then
		local ceremonySerial =
			player:GetProperty(LOTM_RP_PROPERTIES.SequenceZeroCeremonySerial) or 0;
		local acknowledgedSerial =
			player:GetProperty(LOTM_RP_PROPERTIES.SequenceZeroCeremonyAckSerial) or 0;
		if ceremonySerial > 0 and acknowledgedSerial >= ceremonySerial then
			player:SetProperty(
				LOTM_RP_PROPERTIES.SequenceZeroCeremonyAckSerial,
				ceremonySerial - 1
			);
			player:SetProperty(
				LOTM_RP_PROPERTIES.SequenceZeroCeremonyReadyTurn,
				Game.GetCurrentGameTurn()
			);
			Log("player=" .. tostring(playerID)
				.. " migrated rc.20 ceremony serial="
				.. tostring(ceremonySerial) .. " for one deferred replay");
		end
	end
	-- rc.29/30 could already advance the Perfect Path to Sequence 0 but did
	-- not schedule its own ceremony. Backfill exactly one pending ceremony
	-- for those saves; the synchronized serial/acknowledgement flow remains
	-- identical to the Red Priest ceremony.
	if storedVersion ~= nil
		and storedVersion <= 17
		and storedPath == LOTM_PP_SELECTED_PATH
		and (player:GetProperty(LOTM_RP_PROPERTIES.Sequence) or 9) == 0
		and (player:GetProperty(LOTM_RP_PROPERTIES.SequenceZeroCeremonySerial) or 0) == 0 then
		player:SetProperty(LOTM_RP_PROPERTIES.SequenceZeroCeremonySerial, 1);
		player:SetProperty(
			LOTM_RP_PROPERTIES.SequenceZeroCeremonyReadyTurn,
			Game.GetCurrentGameTurn()
		);
		Log("player=" .. tostring(playerID)
			.. " backfilled Perfect Path sequence-0 ceremony serial=1");
	end
	player:SetProperty(LOTM_RP_PROPERTIES.StateVersion, LOTM_RP_STATE_VERSION);
	return player;
end

function LOTM_RP_State.IsEnabledPlayer(playerID :number)
	local player = GetPlayer(playerID);
	if player == nil
		or not player:IsAlive()
		or not player:IsMajor()
		or not player:IsHuman() then
		return false;
	end

	player = LOTM_RP_State.EnsurePlayerState(playerID);
	if (player:GetProperty(LOTM_RP_PROPERTIES.PathDecided) or 0) ~= 1 then
		return false;
	end
	return player:GetProperty(LOTM_RP_PROPERTIES.Path) == LOTM_RP_SELECTED_PATH;
end

function LOTM_RP_State.GetPath(playerID :number)
	local player = LOTM_RP_State.EnsurePlayerState(playerID);
	if player == nil
		or (player:GetProperty(LOTM_RP_PROPERTIES.PathDecided) or 0) ~= 1 then
		return "NONE";
	end
	return player:GetProperty(LOTM_RP_PROPERTIES.Path) or "NONE";
end

function LOTM_RP_State.IsPerfectPlayer(playerID :number)
	local player = GetPlayer(playerID);
	return player ~= nil
		and player:IsAlive()
		and player:IsMajor()
		and player:IsHuman()
		and LOTM_RP_State.GetPath(playerID) == LOTM_PP_SELECTED_PATH;
end

function LOTM_RP_State.IsBlackEmperorPlayer(playerID :number)
	local player = GetPlayer(playerID);
	return player ~= nil
		and player:IsAlive()
		and player:IsMajor()
		and player:IsHuman()
		and LOTM_RP_State.GetPath(playerID) == LOTM_BE_SELECTED_PATH;
end

function LOTM_RP_State.IsThiefPlayer(playerID :number)
	local player = GetPlayer(playerID);
	return player ~= nil
		and player:IsAlive()
		and player:IsMajor()
		and player:IsHuman()
		and not IsRescueMode()
		and LOTM_RP_State.GetPath(playerID) == LOTM_TP_SELECTED_PATH;
end

function LOTM_RP_State.IsRescueThiefPlayer(playerID :number)
	local player = GetPlayer(playerID);
	return player ~= nil and player:IsAlive() and player:IsMajor() and player:IsHuman()
		and IsRescueMode() and LOTM_RP_State.GetPath(playerID) == LOTM_TP_SELECTED_PATH;
end

function LOTM_RP_State.IsAnyPathPlayer(playerID :number)
	return LOTM_RP_State.IsEnabledPlayer(playerID)
		or LOTM_RP_State.IsPerfectPlayer(playerID)
		or LOTM_RP_State.IsBlackEmperorPlayer(playerID)
		or LOTM_RP_State.IsThiefPlayer(playerID)
		or LOTM_RP_State.IsRescueThiefPlayer(playerID);
end

function LOTM_RP_State.GetSequence(playerID :number)
	local player = LOTM_RP_State.EnsurePlayerState(playerID);
	return player ~= nil and player:GetProperty(LOTM_RP_PROPERTIES.Sequence) or 9;
end

function LOTM_RP_State.SetSequence(playerID :number, sequence :number)
	local player = LOTM_RP_State.EnsurePlayerState(playerID);
	if player == nil or type(sequence) ~= "number"
		or sequence < 0 or sequence > 9 then
		return false;
	end
	player:SetProperty(LOTM_RP_PROPERTIES.Sequence, sequence);
	return true;
end

local function EncodeStableObjectKey(objectKey)
	local text = tostring(objectKey or "");
	local encoded :table = {};
	for index = 1, #text do
		encoded[index] = string.format("%02X", string.byte(text, index));
	end
	return table.concat(encoded);
end

local function GetDigestionTotal(player)
	return (player:GetProperty(LOTM_RP_PROPERTIES.DigestA) or 0)
		+ (player:GetProperty(LOTM_RP_PROPERTIES.DigestB) or 0);
end

local function GetProjectUnlock(player, sequence :number)
	local path = player:GetProperty(LOTM_RP_PROPERTIES.Path);
	if path == LOTM_TP_SELECTED_PATH then
		local modifiers = {
			[9] = "LOTM_TP_MOD_ALLOW_SWINDLER_PROJECT",
			[8] = "LOTM_TP_MOD_ALLOW_CRYPTOLOGIST_PROJECT",
			[7] = "LOTM_TP_MOD_ALLOW_PROMETHEUS_PROJECT",
			[6] = "LOTM_TP_MOD_ALLOW_DREAM_STEALER_PROJECT",
			[5] = "LOTM_TP_MOD_ALLOW_PARASITE_PROJECT",
			[4] = "LOTM_TP_MOD_ALLOW_MENTOR_OF_DECEIT_PROJECT",
			[3] = "LOTM_TP_MOD_ALLOW_FATE_TROJAN_PROJECT",
			[2] = "LOTM_TP_MOD_ALLOW_WORM_OF_TIME_PROJECT",
			[1] = "LOTM_TP_MOD_ALLOW_ERROR_PROJECT",
		};
		local modifierID = modifiers[sequence];
		if modifierID ~= nil then
			return modifierID, "LOTM_TP_PROJECT_S" .. tostring(sequence) .. "_UNLOCKED";
		end
		return nil, nil;
	elseif path == LOTM_BE_SELECTED_PATH then
		if sequence == 9 then
			return "LOTM_BE_MOD_ALLOW_BARBARIAN_PROJECT",
				"LOTM_BE_PROJECT_BARBARIAN_UNLOCKED";
		elseif sequence == 8 then
			return "LOTM_BE_MOD_ALLOW_BRIBER_PROJECT",
				"LOTM_BE_PROJECT_BRIBER_UNLOCKED";
		elseif sequence == 7 then
			return "LOTM_BE_MOD_ALLOW_BARON_OF_CORRUPTION_PROJECT",
				"LOTM_BE_PROJECT_BARON_OF_CORRUPTION_UNLOCKED";
		elseif sequence == 6 then
			return "LOTM_BE_MOD_ALLOW_CHAOS_MENTOR_PROJECT",
				"LOTM_BE_PROJECT_CHAOS_MENTOR_UNLOCKED";
		elseif sequence == 5 then
			return "LOTM_BE_MOD_ALLOW_COUNT_OF_CORRUPTION_PROJECT",
				"LOTM_BE_PROJECT_COUNT_OF_CORRUPTION_UNLOCKED";
		elseif sequence == 4 then
			return "LOTM_BE_MOD_ALLOW_FRENZY_MAGE_PROJECT",
				"LOTM_BE_PROJECT_FRENZY_MAGE_UNLOCKED";
		elseif sequence == 3 then
			return "LOTM_BE_MOD_ALLOW_DUKE_OF_ENTROPY_PROJECT",
				"LOTM_BE_PROJECT_DUKE_OF_ENTROPY_UNLOCKED";
		elseif sequence == 2 then
			return "LOTM_BE_MOD_ALLOW_PRINCE_OF_ABOLITION_PROJECT",
				"LOTM_BE_PROJECT_PRINCE_OF_ABOLITION_UNLOCKED";
		elseif sequence == 1 then
			if (player:GetProperty(LOTM_RP_PROPERTIES.TrueGodChurch) or 0) == 1 then
				return "LOTM_BE_MOD_ALLOW_ENTHRONEMENT_PROJECT",
					"LOTM_BE_PROJECT_ENTHRONEMENT_UNLOCKED";
			end
			return "LOTM_BE_MOD_ALLOW_UNCONSECRATED_ENTHRONEMENT_PROJECT",
				"LOTM_BE_PROJECT_UNCONSECRATED_ENTHRONEMENT_UNLOCKED";
		end
		return nil, nil;
	elseif path == LOTM_PP_SELECTED_PATH then
		if sequence == 9 then
			return "LOTM_PP_MOD_ALLOW_ARCHAEOLOGIST_PROJECT",
				"LOTM_PP_PROJECT_ARCHAEOLOGIST_UNLOCKED";
		elseif sequence == 8 then
			return "LOTM_PP_MOD_ALLOW_APPRAISER_PROJECT",
				"LOTM_PP_PROJECT_APPRAISER_UNLOCKED";
		elseif sequence == 7 then
			return "LOTM_PP_MOD_ALLOW_MECHANICAL_EXPERT_PROJECT",
				"LOTM_PP_PROJECT_MECHANICAL_EXPERT_UNLOCKED";
		elseif sequence == 6 then
			return "LOTM_PP_MOD_ALLOW_ASTRONOMER_PROJECT",
				"LOTM_PP_PROJECT_ASTRONOMER_UNLOCKED";
		elseif sequence == 5 then
			return "LOTM_PP_MOD_ALLOW_ALCHEMIST_PROJECT",
				"LOTM_PP_PROJECT_ALCHEMIST_UNLOCKED";
		elseif sequence == 4 then
			return "LOTM_PP_MOD_ALLOW_MYSTERY_SCHOLAR_PROJECT",
				"LOTM_PP_PROJECT_MYSTERY_SCHOLAR_UNLOCKED";
		elseif sequence == 3 then
			return "LOTM_PP_MOD_ALLOW_KNOWLEDGE_MENTOR_PROJECT",
				"LOTM_PP_PROJECT_KNOWLEDGE_MENTOR_UNLOCKED";
		elseif sequence == 2 then
			return "LOTM_PP_MOD_ALLOW_ENLIGHTENER_PROJECT",
				"LOTM_PP_PROJECT_ENLIGHTENER_UNLOCKED";
		elseif sequence == 1 then
			if (player:GetProperty(LOTM_RP_PROPERTIES.TrueGodChurch) or 0) == 1 then
				return "LOTM_PP_MOD_ALLOW_CIVILIZATION_ASCENSION",
					"LOTM_PP_PROJECT_CIVILIZATION_ASCENSION_UNLOCKED";
			end
			return "LOTM_PP_MOD_ALLOW_UNCONSECRATED_CIVILIZATION_ASCENSION",
				"LOTM_PP_PROJECT_UNCONSECRATED_CIVILIZATION_ASCENSION_UNLOCKED";
		end
		return nil, nil;
	elseif path ~= LOTM_RP_SELECTED_PATH then
		return nil, nil;
	end
	if sequence == 9 then
		return LOTM_RP_PROVOKER_PROJECT_MODIFIER,
			LOTM_RP_PROPERTIES.ProvokerProjectUnlocked;
	elseif sequence == 8 then
		return LOTM_RP_PYROMANIAC_PROJECT_MODIFIER,
			LOTM_RP_PROPERTIES.PyromaniacProjectUnlocked;
	elseif sequence == 7 then
		return LOTM_RP_CONSPIRATOR_PROJECT_MODIFIER,
			LOTM_RP_PROPERTIES.ConspiratorProjectUnlocked;
	elseif sequence == 6 then
		return LOTM_RP_REAPER_PROJECT_MODIFIER,
			LOTM_RP_PROPERTIES.ReaperProjectUnlocked;
	elseif sequence == 5 then
		return LOTM_RP_IRONBLOOD_PROJECT_MODIFIER,
			LOTM_RP_PROPERTIES.IronbloodProjectUnlocked;
	elseif sequence == 4 then
		return LOTM_RP_WAR_BISHOP_PROJECT_MODIFIER,
			LOTM_RP_PROPERTIES.WarBishopProjectUnlocked;
	elseif sequence == 3 then
		return LOTM_RP_WEATHER_WARLOCK_PROJECT_MODIFIER,
			LOTM_RP_PROPERTIES.WeatherWarlockProjectUnlocked;
	elseif sequence == 2 then
		return LOTM_RP_CONQUEROR_PROJECT_MODIFIER,
			LOTM_RP_PROPERTIES.ConquerorProjectUnlocked;
	elseif sequence == 1 then
		if (player:GetProperty(LOTM_RP_PROPERTIES.TrueGodChurch) or 0) == 1 then
			return LOTM_RP_WAR_FESTIVAL_PROJECT_MODIFIER,
				LOTM_RP_PROPERTIES.WarFestivalProjectUnlocked;
		end
		return LOTM_RP_UNCONSECRATED_WAR_FESTIVAL_PROJECT_MODIFIER,
			LOTM_RP_PROPERTIES.UnconsecratedWarFestivalProjectUnlocked;
	end
	return nil, nil;
end

-- The immutable database manifest is read once per context. Qualification
-- resources are authoritative, save-persistent native project prerequisites;
-- they also close old saves whose permanent AllowProject was attached early.
local PROJECT_GATE_VERSION = 1;
local PROJECT_GATE_VERSION_KEY = "LOTM_PATH_PROJECT_GATE_VERSION";
local PROJECT_GATE_ACTIVE_KEY = "LOTM_PATH_PROJECT_GATE_ACTIVE";
local projectRules = nil;
local projectRulesByType = nil;
local projectRulesByStage = nil;

local function LoadProjectRules()
	if projectRules ~= nil then return true; end
	if GameInfo.LOTM_PathProjectRules == nil then return false; end
	local rows = {};
	for row in GameInfo.LOTM_PathProjectRules() do rows[#rows + 1] = row; end
	if #rows == 0 then return false; end
	table.sort(rows, function(a,b) return a.ProjectType < b.ProjectType; end);
	projectRules = rows;
	projectRulesByType = {};
	projectRulesByStage = {};
	for _,row in ipairs(rows) do
		projectRulesByType[row.ProjectType] = row;
		local key = row.PathType .. ":" .. tostring(row.FromSequence);
		projectRulesByStage[key] = projectRulesByStage[key] or {};
		projectRulesByStage[key][#projectRulesByStage[key] + 1] = row;
	end
	return true;
end

local function CurrentProjectRule(player)
	if not LoadProjectRules() then return nil; end
	local path = player:GetProperty(LOTM_RP_PROPERTIES.Path) or "NONE";
	local sequence = player:GetProperty(LOTM_RP_PROPERTIES.Sequence) or 9;
	local church = tonumber(player:GetProperty(LOTM_RP_PROPERTIES.TrueGodChurch) or 0) == 1 and 1 or 0;
	for _,row in ipairs(projectRulesByStage[path .. ":" .. tostring(sequence)] or {}) do
		if row.ChurchRequired == -1 or row.ChurchRequired == church then return row; end
	end
	return nil;
end

local function HasProjectPrerequisites(player, rule)
	local project = rule ~= nil and GameInfo.Projects[rule.ProjectType] or nil;
	if project == nil then return false; end
	-- Read the effective database. Rescue mode deliberately clears the normal
	-- industrialization prerequisite; no duplicated hardcoded tech rule.
	if project.PrereqTech ~= nil and project.PrereqTech ~= "" then
		local tech = GameInfo.Technologies[project.PrereqTech];
		local techs = player:GetTechs();
		if tech == nil or techs == nil or not techs:HasTech(tech.Index) then return false; end
	end
	return true;
end

local function SetProjectGate(player, rule, enabled)
	local resource = GameInfo.Resources[rule.GateResourceType];
	local resources = player:GetResources();
	if resource == nil or resources == nil or resources.ChangeResourceAmount == nil then return false; end
	local amount = resources:GetResourceAmount(resource.Index);
	local current = tonumber(amount or 0) or 0;
	local wanted = enabled and 1 or 0;
	if current ~= wanted then resources:ChangeResourceAmount(resource.Index, wanted-current); end
	local after = resources:GetResourceAmount(resource.Index);
	return (tonumber(after or 0) or 0) == wanted;
end

local function SyncProjectQualification(player, eligibleRule)
	if not LoadProjectRules() then return false; end
	local active = player:GetProperty(PROJECT_GATE_ACTIVE_KEY) or "";
	local wanted = eligibleRule ~= nil and eligibleRule.ProjectType or "";
	if (tonumber(player:GetProperty(PROJECT_GATE_VERSION_KEY) or 0) or 0) < PROJECT_GATE_VERSION then
		-- One new-feature/old-save migration; later events touch only the old
		-- and current project token. Never scan cities, players or modifiers.
		for _,row in ipairs(projectRules) do
			if not SetProjectGate(player,row,row.ProjectType == wanted) then return false; end
		end
		player:SetProperty(PROJECT_GATE_VERSION_KEY,PROJECT_GATE_VERSION);
	else
		if active ~= wanted and projectRulesByType[active] ~= nil then
			if not SetProjectGate(player,projectRulesByType[active],false) then return false; end
		end
		if eligibleRule ~= nil and not SetProjectGate(player,eligibleRule,true) then return false; end
	end
	if active ~= wanted then player:SetProperty(PROJECT_GATE_ACTIVE_KEY,wanted); end
	return true;
end

local function RefreshProjectUnlock(playerID :number)
	local player = LOTM_RP_State.EnsurePlayerState(playerID);
	if player == nil or not LOTM_RP_State.IsAnyPathPlayer(playerID) then return false; end
	-- A purchased potion is held until real digestion reaches six. Consume it
	-- before publishing any production qualification for the old sequence.
	if LOTM_RP_State.TryConsumePurchasedPotion ~= nil
		and LOTM_RP_State.TryConsumePurchasedPotion(playerID) then return true; end
	local modifierID, flagKey = GetProjectUnlock(player,player:GetProperty(LOTM_RP_PROPERTIES.Sequence) or 9);
	local rule = CurrentProjectRule(player);
	local digestionTotal = GetDigestionTotal(player);
	local eligible = rule ~= nil and rule.ModifierId == modifierID and rule.UnlockFlag == flagKey
		and digestionTotal >= LOTM_RP_DIGESTION_TARGET and HasProjectPrerequisites(player,rule);
	if not SyncProjectQualification(player,eligible and rule or nil) then return false; end
	local repairVersion = tonumber(player:GetProperty(LOTM_RP_PROPERTIES.ProjectUnlockRepairVersion) or 0) or 0;
	if not eligible then
		if flagKey ~= nil and (tonumber(player:GetProperty(flagKey) or 0) or 0) ~= 0 then
			player:SetProperty(flagKey,0);
		end
		if repairVersion < LOTM_RP_PROJECT_UNLOCK_REPAIR_VERSION then
			player:SetProperty(LOTM_RP_PROPERTIES.ProjectUnlockRepairVersion,LOTM_RP_PROJECT_UNLOCK_REPAIR_VERSION);
		end
		return false;
	end
	if repairVersion < LOTM_RP_PROJECT_UNLOCK_REPAIR_VERSION then
		if player.AttachModifierByID == nil or GameInfo.Modifiers[modifierID] == nil then return false; end
		local ok,details = pcall(function() player:AttachModifierByID(modifierID); end);
		if not ok then Log("project repair pending player="..tostring(playerID).." reason="..tostring(details)); return false; end
		player:SetProperty(flagKey,1);
		player:SetProperty(LOTM_RP_PROPERTIES.ProjectUnlockRepairVersion,LOTM_RP_PROJECT_UNLOCK_REPAIR_VERSION);
		Log("qualified project repair player="..tostring(playerID).." project="..rule.ProjectType);
		return true;
	end
	return LOTM_RP_State.AttachModifierOnce(playerID,modifierID,flagKey);
end

function LOTM_RP_State.TryAddDigestion(playerID :number, category :string, objectKey :string, amount :number)
	if not LOTM_RP_State.IsAnyPathPlayer(playerID)
		or (category ~= "A" and category ~= "B")
		or objectKey == nil or tostring(objectKey) == "" then
		return false;
	end

	local player = LOTM_RP_State.EnsurePlayerState(playerID);
	local requestedAmount = math.max(1, math.floor(tonumber(amount or 1) or 1));
	if IsRescueMode() and LOTM_RP_State.IsEnabledPlayer(playerID)
		and string.sub(tostring(objectKey), 1, 10) ~= "RESCUE_P9:" then
		-- Rescue Red Priest digestion is an explicit Phase 9 allow-list. This
		-- central guard prevents older denounce/war/city/church hooks from
		-- leaking points while leaving ordinary mode and the other paths intact.
		return false;
	end
	local sequence = player:GetProperty(LOTM_RP_PROPERTIES.Sequence) or 9;
	if sequence < 1 or sequence > 9 then
		return false;
	end
	local currentTotal = GetDigestionTotal(player);
	if currentTotal >= LOTM_RP_DIGESTION_TARGET then
		RefreshProjectUnlock(playerID);
		return false;
	end

	local currentTurn = Game.GetCurrentGameTurn();
	local digestTurn = player:GetProperty(LOTM_RP_PROPERTIES.DigestTurn) or -1;
	local turnGain = player:GetProperty(LOTM_RP_PROPERTIES.DigestTurnGain) or 0;
	if digestTurn ~= currentTurn then
		digestTurn = currentTurn;
		turnGain = 0;
	end
	local ignoresTurnCap = LOTM_RP_State.IsBlackEmperorPlayer(playerID)
		and sequence == 9;
	-- Explicit multi-point bursts (currently Sequence 4 Parasite's +3 capture)
	-- are one idempotent event and intentionally bypass the normal +2/turn cap.
	if requestedAmount == 1 and not ignoresTurnCap and turnGain >= LOTM_RP_DIGESTION_TURN_CAP then
		return false;
	end

	local dedupKey = "LOTM_RP_DIGEST_SEEN_S" .. tostring(sequence)
		.. "_" .. category .. "_" .. EncodeStableObjectKey(objectKey);
	if player:GetProperty(dedupKey) == 1 then
		return false;
	end

	local counterKey = category == "A"
		and LOTM_RP_PROPERTIES.DigestA
		or LOTM_RP_PROPERTIES.DigestB;
	player:SetProperty(dedupKey, 1);
	local appliedAmount = math.min(requestedAmount, LOTM_RP_DIGESTION_TARGET - currentTotal);
	player:SetProperty(counterKey, (player:GetProperty(counterKey) or 0) + appliedAmount);
	player:SetProperty(LOTM_RP_PROPERTIES.DigestTurn, digestTurn);
	player:SetProperty(LOTM_RP_PROPERTIES.DigestTurnGain, turnGain + appliedAmount);

	Log("player=" .. tostring(playerID)
		.. " sequence=" .. tostring(sequence)
		.. " digestion category=" .. category
		.. " object=" .. tostring(objectKey)
		.. " amount=" .. tostring(appliedAmount)
		.. " total=" .. tostring(GetDigestionTotal(player)));
	RefreshProjectUnlock(playerID);
	return true;
end

function LOTM_RP_State.GetPublicState(playerID :number)
	local player = LOTM_RP_State.EnsurePlayerState(playerID);
	if player == nil then
		return nil;
	end
	return {
		version = player:GetProperty(LOTM_RP_PROPERTIES.StateVersion),
		path = player:GetProperty(LOTM_RP_PROPERTIES.Path),
		sequence = player:GetProperty(LOTM_RP_PROPERTIES.Sequence),
		digestA = player:GetProperty(LOTM_RP_PROPERTIES.DigestA),
		digestB = player:GetProperty(LOTM_RP_PROPERTIES.DigestB),
		digestTurn = player:GetProperty(LOTM_RP_PROPERTIES.DigestTurn),
		digestTurnGain = player:GetProperty(LOTM_RP_PROPERTIES.DigestTurnGain),
		unitID = player:GetProperty(LOTM_RP_PROPERTIES.UnitID),
		respawnAt = player:GetProperty(LOTM_RP_PROPERTIES.RespawnAt),
		arsonReadyAt = player:GetProperty(LOTM_RP_PROPERTIES.ArsonReadyAt),
		planTargetID = player:GetProperty(LOTM_RP_PROPERTIES.PlanTargetID),
		planTargetReadyAt = player:GetProperty(LOTM_RP_PROPERTIES.PlanTargetReadyAt),
	};
end

local function CollectHeroUnits(playerID :number)
	local heroes :table = {};
	local player = GetPlayer(playerID);
	if player == nil then
		return heroes;
	end
	for _, unit in player:GetUnits():Members() do
		if IsHeroUnit(unit) then
			table.insert(heroes, unit);
		end
	end
	table.sort(heroes, function(left, right)
		return left:GetID() < right:GetID();
	end);
	return heroes;
end

function LOTM_RP_State.FindHero(playerID :number)
	local player = GetPlayer(playerID);
	if player == nil then
		return nil;
	end

	local registeredID = player:GetProperty(LOTM_RP_PROPERTIES.UnitID);
	if registeredID ~= nil and registeredID >= 0 then
		local registeredUnit = player:GetUnits():FindID(registeredID);
		if IsHeroUnit(registeredUnit) then
			return registeredUnit;
		end
	end

	local heroes = CollectHeroUnits(playerID);
	return heroes[1];
end

local function SerializePromotions(unit)
	local promotions :table = {};
	local experience = unit:GetExperience();
	if experience == nil then
		return "";
	end
	for promotion in GameInfo.UnitPromotions() do
		if promotion.PromotionClass == LOTM_PATH_HOLDER_PROMOTION_CLASS
			and experience:HasPromotion(promotion.Index) then
			table.insert(promotions, promotion.UnitPromotionType);
		end
	end
	table.sort(promotions);
	return table.concat(promotions, ",");
end

function LOTM_RP_State.SnapshotHero(playerID :number, unit)
	local player = LOTM_RP_State.EnsurePlayerState(playerID);
	if player == nil or unit == nil or unit:GetOwner() ~= playerID
		or not IsHeroUnit(unit) then
		return false;
	end

	local experience = unit:GetExperience();
	if experience ~= nil then
		player:SetProperty(
			LOTM_RP_PROPERTIES.SavedXP,
			experience:GetExperiencePoints() or 0
		);
		player:SetProperty(LOTM_RP_PROPERTIES.SavedPromotions, SerializePromotions(unit));
		player:SetProperty(LOTM_RP_PROPERTIES.SavedName, experience:GetVeteranName() or "");
	end
	return true;
end

function LOTM_RP_State.ScheduleRespawn(playerID :number)
	local player = LOTM_RP_State.EnsurePlayerState(playerID);
	if player == nil then
		return false;
	end
	if (player:GetProperty(LOTM_RP_PROPERTIES.RespawnAt) or -1) < 0 then
		local respawnTurn = Game.GetCurrentGameTurn() + LOTM_RP_RESPAWN_DELAY;
		player:SetProperty(LOTM_RP_PROPERTIES.RespawnAt, respawnTurn);
		Log("player=" .. tostring(playerID) .. " respawn scheduled for turn=" .. tostring(respawnTurn));
	end
	player:SetProperty(LOTM_RP_PROPERTIES.UnitID, -1);
	return true;
end

function LOTM_RP_State.AttachModifierOnce(playerID :number, modifierID :string, flagKey :string)
	local player = LOTM_RP_State.EnsurePlayerState(playerID);
	if player == nil or modifierID == nil or flagKey == nil then
		return false;
	end
	if (player:GetProperty(flagKey) or 0) == 1 then
		return false;
	end
	player:AttachModifierByID(modifierID);
	player:SetProperty(flagKey, 1);
	Log("player=" .. tostring(playerID) .. " attached modifier=" .. modifierID);
	return true;
end

function LOTM_RP_State.RefreshSequenceState(playerID :number)
	local player = LOTM_RP_State.EnsurePlayerState(playerID);
	if player == nil then
		return false;
	end
	if LOTM_RP_State.IsPerfectPlayer(playerID) then
		if LOTM_PP_RefreshSequenceState ~= nil then
			LOTM_PP_RefreshSequenceState(playerID);
		end
		RefreshProjectUnlock(playerID);
		return true;
	elseif LOTM_RP_State.IsBlackEmperorPlayer(playerID) then
		if LOTM_BE_RefreshSequenceState ~= nil then
			LOTM_BE_RefreshSequenceState(playerID);
		end
		RefreshProjectUnlock(playerID);
		return true;
	elseif LOTM_RP_State.IsThiefPlayer(playerID) then
		if LOTM_TP_RefreshSequenceState ~= nil then
			LOTM_TP_RefreshSequenceState(playerID);
		end
		RefreshProjectUnlock(playerID);
		return true;
	elseif LOTM_RP_State.IsRescueThiefPlayer(playerID) then
		if LOTM_RESCUE_Thief ~= nil and LOTM_RESCUE_Thief.RefreshSequenceState ~= nil then
			LOTM_RESCUE_Thief.RefreshSequenceState(playerID);
		end
		RefreshProjectUnlock(playerID);
		return true;
	elseif not LOTM_RP_State.IsEnabledPlayer(playerID) then
		return false;
	end
	local sequence = player:GetProperty(LOTM_RP_PROPERTIES.Sequence) or 9;
	if sequence <= 9 then
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			LOTM_RP_HUNTER_MODIFIER,
			LOTM_RP_PROPERTIES.HunterAttached
		);
	end
	if sequence <= 8 then
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			LOTM_RP_PROVOKER_MODIFIER,
			LOTM_RP_PROPERTIES.ProvokerAttached
		);
	end
	if sequence <= 4 then
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			LOTM_RP_IRONBLOOD_MODIFIER,
			LOTM_RP_PROPERTIES.IronbloodFriendlyStrengthV2Attached
		);
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			LOTM_RP_IRONBLOOD_MOVEMENT_MODIFIER,
			LOTM_RP_PROPERTIES.IronbloodFriendlyMovementV2Attached
		);
	end
	if sequence <= 3 and not IsRescueMode() then
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			LOTM_RP_WAR_BISHOP_PRODUCTION_MODIFIER,
			LOTM_RP_PROPERTIES.WarBishopProductionAttached
		);
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			LOTM_RP_WAR_BISHOP_WEARINESS_MODIFIER,
			LOTM_RP_PROPERTIES.WarBishopWearinessAttached
		);
	end
	if sequence <= 2 and not IsRescueMode() then
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			LOTM_RP_WEATHER_ENEMY_STRENGTH_MODIFIER,
			LOTM_RP_PROPERTIES.WeatherEnemyStrengthV2Attached
		);
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			LOTM_RP_WEATHER_ENEMY_MOVEMENT_MODIFIER,
			LOTM_RP_PROPERTIES.WeatherEnemyMovementV2Attached
		);
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			LOTM_RP_WEATHER_ENEMY_WEARINESS_MODIFIER,
			LOTM_RP_PROPERTIES.WeatherEnemyWearinessV2Attached
		);
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			LOTM_RP_WEATHER_FRIENDLY_MOVEMENT_MODIFIER,
			LOTM_RP_PROPERTIES.WeatherFriendlyMovementV2Attached
		);
	end
	if sequence <= 1 and not IsRescueMode() then
		LOTM_RP_State.AttachModifierOnce(
			playerID,
			LOTM_RP_CONQUEST_BYPASS_WALLS_MODIFIER,
			LOTM_RP_PROPERTIES.ConquestBypassWallsAttached
		);
	end
	if sequence <= 0 then
		if not IsRescueMode() then
			LOTM_RP_State.AttachModifierOnce(
				playerID,
				LOTM_RP_RED_PRIEST_WAR_PRODUCTION_MODIFIER,
				LOTM_RP_PROPERTIES.RedPriestWarProductionAttached
			);
		end
	end
	RefreshProjectUnlock(playerID);
	return true;
end

local function CompleteSequenceAdvance(playerID :number, player, expectedSequence :number, nextSequence :number, source :string)
	player:SetProperty(LOTM_RP_PROPERTIES.Sequence, nextSequence);
	player:SetProperty(LOTM_RP_PROPERTIES.DigestA, 0);
	player:SetProperty(LOTM_RP_PROPERTIES.DigestB, 0);
	player:SetProperty(LOTM_RP_PROPERTIES.DigestTurn, -1);
	player:SetProperty(LOTM_RP_PROPERTIES.DigestTurnGain, 0);
	if nextSequence == 0 and LOTM_RP_State.IsAnyPathPlayer(playerID) then
		local ceremonySerial =
			(player:GetProperty(LOTM_RP_PROPERTIES.SequenceZeroCeremonySerial) or 0) + 1;
		player:SetProperty(
			LOTM_RP_PROPERTIES.SequenceZeroCeremonySerial,
			ceremonySerial
		);
		player:SetProperty(
			LOTM_RP_PROPERTIES.SequenceZeroCeremonyReadyTurn,
				Game.GetCurrentGameTurn()
		);
		Log("player=" .. tostring(playerID)
			.. " scheduled sequence-0 ceremony serial=" .. tostring(ceremonySerial)
			.. " readyTurn="
			.. tostring(player:GetProperty(LOTM_RP_PROPERTIES.SequenceZeroCeremonyReadyTurn)));
	end
	LOTM_RP_State.RefreshSequenceState(playerID);
	Log("player=" .. tostring(playerID)
		.. " advanced sequence " .. tostring(expectedSequence)
		.. "->" .. tostring(nextSequence)
		.. " source=" .. tostring(source));
	if nextSequence == 0 and LOTM_RESCUE_Phase10 ~= nil
		and LOTM_RESCUE_Phase10.OnSequenceZeroAdvanced ~= nil then
		LOTM_RESCUE_Phase10.OnSequenceZeroAdvanced(playerID);
	end
	return true;
end

function LOTM_RP_State.TryConsumePurchasedPotion(playerID :number)
	if not LOTM_RP_State.IsAnyPathPlayer(playerID) then return false; end
	local player=LOTM_RP_State.EnsurePlayerState(playerID);
	-- Civ VI may expose an absent Property as zero Lua return values. Passing
	-- GetProperty() directly as tonumber's sole argument then calls tonumber
	-- with no arguments and aborts the entire refresh before project unlock.
	local purchasedSequenceValue=player:GetProperty("LOTM_WORLD_PURCHASED_POTION_SEQUENCE");
	local purchasedSequence=purchasedSequenceValue~=nil
		and tonumber(purchasedSequenceValue) or nil;
	if purchasedSequence==nil then return false; end
	local sequence=player:GetProperty(LOTM_RP_PROPERTIES.Sequence) or 9;
	if sequence~=purchasedSequence or sequence<2 or sequence>9 then return false; end
	local digestionTotal=GetDigestionTotal(player);
	if digestionTotal<LOTM_RP_DIGESTION_TARGET then
		Log("purchased potion pending digestion player="..tostring(playerID)
			.." sequence="..tostring(sequence).." digestion="..tostring(digestionTotal));
		return false;
	end
	local projectType=player:GetProperty("LOTM_WORLD_PURCHASED_POTION_PROJECT");
	local rule=CurrentProjectRule(player);
	if rule==nil or rule.ProjectType~=projectType or not HasProjectPrerequisites(player,rule) then return false; end
	local purchaseSerialValue=player:GetProperty("LOTM_WORLD_PURCHASED_POTION_SERIAL");
	local purchaseSerial=purchaseSerialValue~=nil and tonumber(purchaseSerialValue) or 0;
	-- Clear the entitlement first so RefreshSequenceState cannot consume it
	-- again while CompleteSequenceAdvance refreshes inherited abilities.
	player:SetProperty("LOTM_WORLD_PURCHASED_POTION_SEQUENCE",nil);
	player:SetProperty("LOTM_WORLD_PURCHASED_POTION_PROJECT",nil);
	player:SetProperty("LOTM_WORLD_PURCHASED_POTION_SERIAL",nil);
	player:SetProperty("LOTM_WORLD_GOODY_POTION_CLEAR_PROJECT",projectType);
	player:SetProperty("LOTM_WORLD_GOODY_POTION_CLEAR_SERIAL",purchaseSerial);
	Log("player="..tostring(playerID).." consumed purchased potion after digestion sequence="
		..tostring(sequence).."->"..tostring(sequence-1).." project="..tostring(projectType)
		.." digestion="..tostring(digestionTotal));
	return CompleteSequenceAdvance(playerID,player,sequence,sequence-1,"GATHERING_PURCHASE_AFTER_DIGESTION");
end

function LOTM_RP_State.AdvanceSequence(
	playerID :number,
	expectedSequence :number,
	nextSequence :number,
	allowWithoutChurch :boolean
)
	if not LOTM_RP_State.IsAnyPathPlayer(playerID) then return false; end
	local player = LOTM_RP_State.EnsurePlayerState(playerID);
	local sequence = player:GetProperty(LOTM_RP_PROPERTIES.Sequence) or 9;
	if sequence ~= expectedSequence
		or nextSequence ~= expectedSequence - 1
		or GetDigestionTotal(player) < LOTM_RP_DIGESTION_TARGET then return false; end
	local rule = CurrentProjectRule(player);
	if rule == nil or rule.FromSequence ~= expectedSequence or rule.ToSequence ~= nextSequence
		or not HasProjectPrerequisites(player,rule) then return false; end
	if expectedSequence == 1 and nextSequence == 0
		and (player:GetProperty(LOTM_RP_PROPERTIES.TrueGodChurch) or 0) ~= 1
		and allowWithoutChurch ~= true then
		Log("ERROR rejected sequence 1->0 without True God Church player="..tostring(playerID));
		return false;
	end
	return CompleteSequenceAdvance(playerID,player,expectedSequence,nextSequence,"PROJECT");
end

function LOTM_RP_State.RegisterPurchasedPotion(playerID :number, expectedSequence :number, projectType :string, serial :number)
	if not LOTM_RP_State.IsAnyPathPlayer(playerID) then return false; end
	local player=LOTM_RP_State.EnsurePlayerState(playerID);
	local sequence=player:GetProperty(LOTM_RP_PROPERTIES.Sequence) or 9;
	-- Purchase may precede completed digestion, but only one exact current-
	-- sequence entitlement can exist. Sequence 1->0 is never purchasable.
	if sequence~=expectedSequence or expectedSequence<2 or expectedSequence>9
		or projectType==nil or tostring(projectType)==""
		or tonumber(serial)==nil
		or player:GetProperty("LOTM_WORLD_PURCHASED_POTION_SEQUENCE")~=nil then return false; end
	local rule=CurrentProjectRule(player);
	if rule==nil or rule.ProjectType~=projectType or rule.FromSequence~=expectedSequence then return false; end
	player:SetProperty("LOTM_WORLD_PURCHASED_POTION_SEQUENCE",expectedSequence);
	player:SetProperty("LOTM_WORLD_PURCHASED_POTION_PROJECT",projectType);
	player:SetProperty("LOTM_WORLD_PURCHASED_POTION_SERIAL",serial);
	Log("player="..tostring(playerID).." registered purchased potion sequence="
		..tostring(expectedSequence).." project="..tostring(projectType).." serial="..tostring(serial));
	LOTM_RP_State.TryConsumePurchasedPotion(playerID);
	return true;
end

local function RestoreHeroSnapshot(playerID :number, unit)
	local player = GetPlayer(playerID);
	local experience = unit ~= nil and unit:GetExperience() or nil;
	if player == nil or experience == nil then
		return;
	end

	local savedPromotions = player:GetProperty(LOTM_RP_PROPERTIES.SavedPromotions) or "";
	local promotionSet :table = {};
	for promotionType in string.gmatch(savedPromotions, "[^,]+") do
		promotionSet[promotionType] = true;
	end
	for promotion in GameInfo.UnitPromotions() do
		if promotion.PromotionClass == LOTM_PATH_HOLDER_PROMOTION_CLASS
			and promotionSet[promotion.UnitPromotionType]
			and not experience:HasPromotion(promotion.Index) then
			experience:SetPromotion(promotion.Index);
		end
	end

	local currentXP = experience:GetExperiencePoints() or 0;
	local savedXP = player:GetProperty(LOTM_RP_PROPERTIES.SavedXP) or 0;
	if savedXP ~= currentXP then
		experience:ChangeExperience(savedXP - currentXP);
	end

	local savedName = player:GetProperty(LOTM_RP_PROPERTIES.SavedName) or "";
	if savedName ~= "" then
		experience:SetVeteranName(savedName);
	end
end

local function ResolveDuplicateHeroes(playerID :number)
	local player = GetPlayer(playerID);
	if player == nil then
		return nil;
	end
	local heroes = CollectHeroUnits(playerID);
	if #heroes == 0 then
		return nil;
	end

	local registeredID = player:GetProperty(LOTM_RP_PROPERTIES.UnitID) or -1;
	local keeper = nil;
	for _, hero in ipairs(heroes) do
		if hero:GetID() == registeredID then
			keeper = hero;
			break;
		end
	end
	if keeper == nil then
		keeper = heroes[1];
		player:SetProperty(LOTM_RP_PROPERTIES.UnitID, keeper:GetID());
	end

	if #heroes > 1 then
		Log("ERROR player=" .. tostring(playerID)
			.. " has duplicate path holders"
			.. "; keeping registered unit=" .. tostring(keeper:GetID()));
		for _, hero in ipairs(heroes) do
			if hero:GetID() ~= keeper:GetID() then
				UnitManager.Kill(hero, false);
			end
		end
	end
	return keeper;
end

local function GetSpawnCity(playerID :number)
	local player = GetPlayer(playerID);
	if player == nil then
		return nil;
	end
	local cities = player:GetCities();
	local capital = cities:GetCapitalCity();
	if capital ~= nil then
		return capital;
	end
	local fallbackCity = nil;
	for _, city in cities:Members() do
		if fallbackCity == nil or city:GetID() < fallbackCity:GetID() then
			fallbackCity = city;
		end
	end
	return fallbackCity;
end

local function CreateHeroAtCity(playerID :number, city)
	local existingIDs :table = {};
	for _, hero in ipairs(CollectHeroUnits(playerID)) do
		existingIDs[hero:GetID()] = true;
	end

	m_creatingHero[playerID] = true;
	local heroType = GetExpectedHeroType(playerID);
	local created = UnitManager.InitUnit(playerID, heroType, city:GetX(), city:GetY());
	if created == nil then
		UnitManager.InitUnitValidAdjacentHex(
			playerID,
			heroType,
			city:GetX(),
			city:GetY(),
			1
		);
	end
	m_creatingHero[playerID] = nil;

	if created ~= nil and IsHeroUnit(created) then
		return created;
	end
	for _, hero in ipairs(CollectHeroUnits(playerID)) do
		if not existingIDs[hero:GetID()] then
			return hero;
		end
	end
	return nil;
end

local m_retypingHero :table = {};
local m_retypedHeroUnitIDs :table = {};

local function RetypeHeroForPath(playerID :number, hero, forceRecreate :boolean)
	if hero == nil then
		return nil;
	end
	local expectedType = GetExpectedHeroType(playerID);
	local expectedIndex = GetHeroTypeIndex(expectedType);
	if hero:GetType() == expectedIndex and forceRecreate ~= true then
		return hero;
	end

	local player = GetPlayer(playerID);
	if player == nil or expectedIndex < 0 then
		return hero;
	end
	LOTM_RP_State.SnapshotHero(playerID, hero);
	local x, y = hero:GetX(), hero:GetY();
	local oldUnitID = hero:GetID();
	local damage = hero:GetDamage() or 0;
	local moves = hero:GetMovesRemaining() or 0;
	m_retypingHero[playerID] = true;
	m_retypedHeroUnitIDs[playerID] = oldUnitID;
	UnitManager.Kill(hero, false);
	local replacement = UnitManager.InitUnit(playerID, expectedType, x, y);
	if replacement == nil then
		UnitManager.InitUnitValidAdjacentHex(playerID, expectedType, x, y, 1);
		for _, candidate in ipairs(CollectHeroUnits(playerID)) do
			if candidate:GetType() == expectedIndex then
				replacement = candidate;
				break;
			end
		end
	end
	m_retypingHero[playerID] = nil;
	if replacement == nil then
		LOTM_RP_State.ScheduleRespawn(playerID);
		Log("ERROR player=" .. tostring(playerID)
			.. " failed path-holder icon migration to " .. expectedType);
		return nil;
	end
	RestoreHeroSnapshot(playerID, replacement);
	if damage > 0 then
		replacement:ChangeDamage(damage);
	end
	local replacementMoves = replacement:GetMovesRemaining() or 0;
	if replacementMoves ~= moves then
		replacement:ChangeMovesRemaining(moves - replacementMoves);
	end
	player:SetProperty(LOTM_RP_PROPERTIES.UnitID, replacement:GetID());
	Log("player=" .. tostring(playerID)
		.. (forceRecreate == true and " migrated promotion tree; unit type="
			or " migrated path-holder unit type=") .. expectedType
		.. " unit=" .. tostring(replacement:GetID()));
	return replacement;
end

local function AttachTechnologyModifiers(playerID :number)
	local player = GetPlayer(playerID);
	if player == nil then
		return;
	end
	local technologies = player:GetTechs();
	local steps :table = {
		{
			technology = "TECH_IRON_WORKING",
			modifier = "LOTM_RP_MOD_TECH_IRON_WORKING_COMBAT",
			flag = LOTM_RP_PROPERTIES.TechIronWorkingAttached,
		},
		{
			technology = "TECH_APPRENTICESHIP",
			modifier = "LOTM_RP_MOD_TECH_APPRENTICESHIP_COMBAT",
			flag = LOTM_RP_PROPERTIES.TechApprenticeshipAttached,
		},
		{
			technology = "TECH_GUNPOWDER",
			modifier = "LOTM_RP_MOD_TECH_GUNPOWDER_COMBAT",
			flag = LOTM_RP_PROPERTIES.TechGunpowderAttached,
		},
		{
			technology = "TECH_MILITARY_SCIENCE",
			modifier = "LOTM_RP_MOD_TECH_MILITARY_SCIENCE_COMBAT",
			flag = LOTM_RP_PROPERTIES.TechMilitaryScienceAttached,
		},
		{
			technology = "TECH_REPLACEABLE_PARTS",
			modifier = "LOTM_RP_MOD_TECH_REPLACEABLE_PARTS_COMBAT",
			flag = LOTM_RP_PROPERTIES.TechReplaceablePartsAttached,
		},
		{
			technology = "TECH_SATELLITES",
			modifier = "LOTM_RP_MOD_TECH_SATELLITES_COMBAT",
			flag = LOTM_RP_PROPERTIES.TechSatellitesAttached,
		},
	};
	for _, step in ipairs(steps) do
		local technology = GameInfo.Technologies[step.technology];
		if technology ~= nil and technologies:HasTech(technology.Index) then
			LOTM_RP_State.AttachModifierOnce(
				playerID,
				step.modifier,
				step.flag
			);
		end
	end
end

local function OnAcknowledgeSequenceZeroCeremony(playerID :number, parameters :table)
	if not LOTM_RP_State.IsAnyPathPlayer(playerID) then
		return;
	end
	local player = LOTM_RP_State.EnsurePlayerState(playerID);
	local requestedSerial = parameters ~= nil and tonumber(parameters.Serial) or nil;
	local currentSerial =
		player:GetProperty(LOTM_RP_PROPERTIES.SequenceZeroCeremonySerial) or 0;
	local readyTurn =
		player:GetProperty(LOTM_RP_PROPERTIES.SequenceZeroCeremonyReadyTurn) or -1;
	local acknowledgedSerial =
		player:GetProperty(LOTM_RP_PROPERTIES.SequenceZeroCeremonyAckSerial) or 0;
	if requestedSerial == nil
		or requestedSerial ~= math.floor(requestedSerial)
		or requestedSerial ~= currentSerial
		or requestedSerial <= acknowledgedSerial
		or (player:GetProperty(LOTM_RP_PROPERTIES.Sequence) or 9) ~= 0
		or readyTurn < 0
		or Game.GetCurrentGameTurn() < readyTurn then
		Log("ERROR rejected sequence-0 ceremony acknowledgement player="
			.. tostring(playerID) .. " serial=" .. tostring(requestedSerial));
		return;
	end
	player:SetProperty(
		LOTM_RP_PROPERTIES.SequenceZeroCeremonyAckSerial,
		requestedSerial
	);
	Log("player=" .. tostring(playerID)
		.. " acknowledged sequence-0 ceremony serial=" .. tostring(requestedSerial));
end

local function OnMarkOpeningComicShown(playerID :number, parameters :table)
	if not LOTM_RP_State.IsAnyPathPlayer(playerID) then
		Log("ERROR rejected opening-comic acknowledgement player=" .. tostring(playerID));
		return;
	end
	local player = LOTM_RP_State.EnsurePlayerState(playerID);
	if tonumber(player:GetProperty(LOTM_RP_PROPERTIES.OpeningComicShown) or 0) == 1 then
		return;
	end
	player:SetProperty(LOTM_RP_PROPERTIES.OpeningComicShown, 1);
	Log("player=" .. tostring(playerID) .. " acknowledged opening comic");
end

local function RefreshWarAuraSource(playerID :number, hero)
	if not IsHeroUnit(hero) then
		return;
	end
	local promotion = GameInfo.UnitPromotions["PROMOTION_LOTM_RP_COMBAT_3"];
	local experience = hero:GetExperience();
	local abilities = hero:GetAbility();
	if promotion == nil or experience == nil or abilities == nil then
		Log("ERROR war aura source interface missing player=" .. tostring(playerID));
		return;
	end
	local hasPromotion = experience:HasPromotion(promotion.Index);
	local desired = hasPromotion and 1 or 0;
	local abilityType = "ABILITY_LOTM_RP_WAR_AURA_SOURCE_V2";
	LOTM_Effects.SetAbilityCount(abilities, abilityType, desired);
	local actual = abilities:GetAbilityCount(abilityType) or 0;
	local signature = tostring(desired) .. ":" .. tostring(actual);
	if hero:GetProperty("LOTM_RP_WAR_AURA_SOURCE_V2_STATE") ~= signature then
		hero:SetProperty("LOTM_RP_WAR_AURA_SOURCE_V2_STATE", signature);
		Log("war aura source player=" .. tostring(playerID)
			.. " unit=" .. tostring(hero:GetID())
			.. " promotion=" .. tostring(hasPromotion)
			.. " desired=" .. tostring(desired)
			.. " actual=" .. tostring(actual));
	end
end

function LOTM_RP_State.EnsureHero(playerID :number)
	if not LOTM_RP_State.IsAnyPathPlayer(playerID) then
		return nil;
	end

	local player = LOTM_RP_State.EnsurePlayerState(playerID);
	AttachTechnologyModifiers(playerID);
	LOTM_RP_State.RefreshSequenceState(playerID);
	local hero = ResolveDuplicateHeroes(playerID);
	if hero ~= nil then
		local migratePromotionTree =
			(player:GetProperty(LOTM_RP_PROPERTIES.PromotionTreeMigrated) or 0) ~= 1;
		hero = RetypeHeroForPath(playerID, hero, migratePromotionTree);
		if hero == nil then
			return nil;
		end
		if migratePromotionTree then
			player:SetProperty(LOTM_RP_PROPERTIES.PromotionTreeMigrated, 1);
		end
		player:SetProperty(LOTM_RP_PROPERTIES.UnitID, hero:GetID());
		player:SetProperty(LOTM_RP_PROPERTIES.RespawnAt, -1);
		RefreshWarAuraSource(playerID, hero);
		LOTM_RP_State.SnapshotHero(playerID, hero);
		return hero;
	end
	if (player:GetProperty(LOTM_RP_PROPERTIES.PromotionTreeMigrated) or 0) ~= 1 then
		-- A dead/pending holder has no live stale promotion modifiers to remove.
		player:SetProperty(LOTM_RP_PROPERTIES.SavedPromotions, "");
		player:SetProperty(LOTM_RP_PROPERTIES.PromotionTreeMigrated, 1);
		Log("player=" .. tostring(playerID)
			.. " cleared legacy Recon promotions before holder respawn");
	end

	local respawnAt = player:GetProperty(LOTM_RP_PROPERTIES.RespawnAt) or -1;
	local registeredID = player:GetProperty(LOTM_RP_PROPERTIES.UnitID) or -1;
	if registeredID >= 0 and respawnAt < 0 then
		LOTM_RP_State.ScheduleRespawn(playerID);
		respawnAt = player:GetProperty(LOTM_RP_PROPERTIES.RespawnAt) or -1;
	end
	if respawnAt >= 0 and Game.GetCurrentGameTurn() < respawnAt then
		return nil;
	end

	local city = GetSpawnCity(playerID);
	if city == nil then
		return nil;
	end
	local isRespawn = respawnAt >= 0;
	hero = CreateHeroAtCity(playerID, city);
	if hero == nil then
		Log("player=" .. tostring(playerID) .. " has no legal capital or adjacent spawn plot");
		return nil;
	end

	player:SetProperty(LOTM_RP_PROPERTIES.UnitID, hero:GetID());
	player:SetProperty(LOTM_RP_PROPERTIES.RespawnAt, -1);
	if isRespawn then
		RestoreHeroSnapshot(playerID, hero);
	end
	RefreshWarAuraSource(playerID, hero);
	LOTM_RP_State.SnapshotHero(playerID, hero);
	Log("player=" .. tostring(playerID)
		.. (isRespawn and " respawned" or " created")
		.. " hero unit=" .. tostring(hero:GetID()));
	return hero;
end

local function ReconcileTestCombatToggle(playerID :number)
	if LOTM_TEST_COMBAT_RECONCILED[playerID] == true
		or not LOTM_TEST_COMBAT_TOGGLE_ENABLED
		or IsRescueMode()
		or (LOTM_MP_TurnSync ~= nil and LOTM_MP_TurnSync.IsNetworkGame ~= nil
			and LOTM_MP_TurnSync.IsNetworkGame())
		or not LOTM_RP_State.IsAnyPathPlayer(playerID) then
		return;
	end
	local player = GetPlayer(playerID);
	if player == nil then return; end
	local active = (tonumber(player:GetProperty(LOTM_RP_PROPERTIES.TestCombatBoostActive) or 0) or 0) == 1;
	if not active then
		LOTM_TEST_COMBAT_RECONCILED[playerID] = true;
		return;
	end
	if GameInfo.Modifiers[LOTM_TEST_COMBAT_PLUS_MODIFIER] == nil
		or GameInfo.Modifiers[LOTM_TEST_CAPITAL_PRODUCTION_PLUS_MODIFIER] == nil then
		Log("ERROR test combat reconcile modifier missing player=" .. tostring(playerID));
		return;
	end
	local ok, details = pcall(function()
		player:AttachModifierByID(LOTM_TEST_COMBAT_PLUS_MODIFIER);
		player:AttachModifierByID(LOTM_TEST_CAPITAL_PRODUCTION_PLUS_MODIFIER);
	end);
	if ok then
		LOTM_TEST_COMBAT_RECONCILED[playerID] = true;
	end
	local capital = player:GetCities() ~= nil and player:GetCities():GetCapitalCity() or nil;
	local observedProduction = -1;
	if capital ~= nil and YieldTypes ~= nil and YieldTypes.PRODUCTION ~= nil
		and capital.GetYield ~= nil then
		observedProduction = tonumber(capital:GetYield(YieldTypes.PRODUCTION) or -1) or -1;
	end
	Log("test combat reconcile player=" .. tostring(playerID)
		.. " active=true reattached=" .. tostring(ok)
		.. " details=" .. tostring(details or "")
		.. " capital=" .. tostring(capital ~= nil and capital:GetID() or -1)
		.. " observedProduction=" .. tostring(observedProduction));
end

local function ProcessPlayer(playerID :number)
	if LOTM_RP_State.IsAnyPathPlayer(playerID) then
		LOTM_RP_State.EnsureHero(playerID);
		ReconcileTestCombatToggle(playerID);
	end
end

local function ProcessAllPlayers()
	local playerIDs :table = {};
	for _, playerID in ipairs(PlayerManager.GetAliveMajorIDs() or {}) do
		playerIDs[#playerIDs + 1] = playerID;
	end
	table.sort(playerIDs);
	for _, playerID in ipairs(playerIDs) do
		ProcessPlayer(playerID);
	end
end

local function OnSelectPath(playerID :number, parameters :table)
	local player = GetPlayer(playerID);
	local choice = parameters ~= nil and parameters.Choice or nil;
	if player == nil
		or not player:IsAlive()
		or not player:IsMajor()
		or not player:IsHuman()
		or (choice ~= LOTM_RP_SELECTED_PATH
			and choice ~= LOTM_PP_SELECTED_PATH
			and choice ~= LOTM_BE_SELECTED_PATH
			and choice ~= LOTM_TP_SELECTED_PATH
			and choice ~= "NONE") then
		Log("ERROR rejected path-selection command player=" .. tostring(playerID));
		return;
	end

	player = LOTM_RP_State.EnsurePlayerState(playerID);
	if (player:GetProperty(LOTM_RP_PROPERTIES.PathDecided) or 0) == 1 then
		Log("ERROR rejected duplicate path-selection command player=" .. tostring(playerID));
		return;
	end

	player:SetProperty(LOTM_RP_PROPERTIES.Path, choice);
	player:SetProperty(LOTM_RP_PROPERTIES.PathDecided, 1);
	Log("player=" .. tostring(playerID) .. " selected path=" .. tostring(choice));
	-- Rescue Thief must seed its purification-energy baseline before EnsureHero
	-- runs the per-turn rescue effects.  Otherwise the hero refresh grants the
	-- first +1 energy and leaves the historical GLOBAL_PURIFICATION delta to a
	-- later turn, making a newly selected Thief appear to have no loaded energy.
	local rescueThiefSelected = choice == LOTM_TP_SELECTED_PATH
		and IsRescueMode()
		and LOTM_RESCUE_Thief ~= nil
		and LOTM_RESCUE_Thief.OnPathSelected ~= nil;
	if rescueThiefSelected then
		LOTM_RESCUE_Thief.OnPathSelected(playerID);
	end
	if choice == LOTM_RP_SELECTED_PATH
		or choice == LOTM_PP_SELECTED_PATH
		or choice == LOTM_BE_SELECTED_PATH
		or choice == LOTM_TP_SELECTED_PATH then
		local hero = LOTM_RP_State.EnsureHero(playerID);
		if hero == nil then
			Log("player=" .. tostring(playerID)
				.. " hero creation pending capital/city initialization");
		end
		if choice == LOTM_PP_SELECTED_PATH and LOTM_PP_OnPathSelected ~= nil then
			LOTM_PP_OnPathSelected(playerID);
		elseif choice == LOTM_BE_SELECTED_PATH and LOTM_BE_OnPathSelected ~= nil then
			LOTM_BE_OnPathSelected(playerID);
		elseif choice == LOTM_TP_SELECTED_PATH and rescueThiefSelected then
			-- Seeded above, before EnsureHero; do not run the initializer twice.
		elseif choice == LOTM_TP_SELECTED_PATH and LOTM_TP_OnPathSelected ~= nil then
			LOTM_TP_OnPathSelected(playerID);
		end
	end
end

local function OnPlayerTurnActivated(playerID :number, isFirstTimeThisTurn :boolean)
	ProcessPlayer(playerID);
end

local function OnCityBuilt(playerID :number, cityID :number)
	ProcessPlayer(playerID);
end

local function OnResearchCompleted(playerID :number, techIndex :number, isCanceled :boolean)
	-- ResearchCompleted is locally published.  Network turns already call
	-- EnsureHero -> AttachTechnologyModifiers from the synchronized dispatcher,
	-- so the callback must not allocate modifiers in client-specific order.
	if LOTM_MP_TurnSync.IsNetworkGame() then return; end
	if not isCanceled and LOTM_RP_State.IsAnyPathPlayer(playerID) then
		AttachTechnologyModifiers(playerID);
	end
end

local function SnapshotEventUnit(playerID :number, unitID :number)
	local player = GetPlayer(playerID);
	if player == nil then
		return;
	end
	local unit = player:GetUnits():FindID(unitID);
	if IsHeroUnit(unit) then
		RefreshWarAuraSource(playerID, unit);
		LOTM_RP_State.SnapshotHero(playerID, unit);
		if unit:IsDead() or unit:IsDelayedDeath() then
			LOTM_RP_State.ScheduleRespawn(playerID);
		end
	end
end

local function OnCombatOccurred(
	attackerPlayerID :number,
	attackerUnitID :number,
	defenderPlayerID :number,
	defenderUnitID :number
)
	SnapshotEventUnit(attackerPlayerID, attackerUnitID);
	SnapshotEventUnit(defenderPlayerID, defenderUnitID);
end

local function OnPostUnitPromotionEarned(
	playerID :number,
	unitID :number,
	promotionType :number
)
	SnapshotEventUnit(playerID, unitID);
end

local function OnUnitRemovedFromMap(playerID :number, unitID :number)
	if LOTM_MP_TurnSync.IsNetworkGame() then
		-- These flags are Lua-local retype bookkeeping only.  Missing registered
		-- heroes are detected and scheduled by synchronized EnsureHero next turn.
		if m_retypedHeroUnitIDs[playerID] == unitID then m_retypedHeroUnitIDs[playerID] = nil; end
		return;
	end
	if m_retypedHeroUnitIDs[playerID] == unitID then
		m_retypedHeroUnitIDs[playerID] = nil;
		return;
	end
	if m_retypingHero[playerID] then
		return;
	end
	local player = GetPlayer(playerID);
	if player == nil then
		return;
	end
	local registeredID = player:GetProperty(LOTM_RP_PROPERTIES.UnitID) or -1;
	if registeredID == unitID then
		LOTM_RP_State.ScheduleRespawn(playerID);
	end
end

local function OnUnitInitialized(playerID :number, unitID :number)
	if m_creatingHero[playerID] or not LOTM_RP_State.IsAnyPathPlayer(playerID) then
		return;
	end
	local player = GetPlayer(playerID);
	local unit = player ~= nil and player:GetUnits():FindID(unitID) or nil;
	if IsHeroUnit(unit) and not LOTM_MP_TurnSync.IsNetworkGame() then
		ResolveDuplicateHeroes(playerID);
	end
end

-- TEST ONLY: authoritative reversible +200 combat toggle.  UI submits the
-- command; this handler alone mutates synchronized state and modifier stacks.
local function OnTestCombatToggle(playerID :number, parameters :table)
	if not LOTM_TEST_COMBAT_TOGGLE_ENABLED or IsRescueMode()
		or (LOTM_MP_TurnSync ~= nil and LOTM_MP_TurnSync.IsNetworkGame ~= nil
			and LOTM_MP_TurnSync.IsNetworkGame()) then
		Log("test combat toggle rejected mode or disabled player=" .. tostring(playerID));
		return;
	end
	if not LOTM_RP_State.IsAnyPathPlayer(playerID) then
		Log("test combat toggle rejected non-path player=" .. tostring(playerID));
		return;
	end
	local player = GetPlayer(playerID);
	if player == nil or not player:IsTurnActive() then
		Log("test combat toggle rejected inactive player=" .. tostring(playerID));
		return;
	end
	local registeredID = player:GetProperty(LOTM_RP_PROPERTIES.UnitID) or -1;
	local requestedID = parameters ~= nil and tonumber(parameters.UnitID) or registeredID;
	if requestedID ~= registeredID then
		Log("test combat toggle rejected unit mismatch player=" .. tostring(playerID));
		return;
	end
	local hero = LOTM_RP_State.FindHero(playerID);
	if hero == nil or hero:IsDead() or hero:IsDelayedDeath() then
		Log("test combat toggle rejected missing hero player=" .. tostring(playerID));
		return;
	end
	local active = (tonumber(player:GetProperty(LOTM_RP_PROPERTIES.TestCombatBoostActive) or 0) or 0) == 1;
	local modifierID = active and LOTM_TEST_COMBAT_MINUS_MODIFIER or LOTM_TEST_COMBAT_PLUS_MODIFIER;
	local productionModifierID = active
		and LOTM_TEST_CAPITAL_PRODUCTION_MINUS_MODIFIER
		or LOTM_TEST_CAPITAL_PRODUCTION_PLUS_MODIFIER;
	if GameInfo.Modifiers[modifierID] == nil or GameInfo.Modifiers[productionModifierID] == nil then
		Log("ERROR test combat modifier missing combat=" .. modifierID
			.. " production=" .. productionModifierID);
		return;
	end
	player:AttachModifierByID(modifierID);
	player:AttachModifierByID(productionModifierID);
	player:SetProperty(LOTM_RP_PROPERTIES.TestCombatBoostActive, active and 0 or 1);
	local capital = player:GetCities() ~= nil and player:GetCities():GetCapitalCity() or nil;
	local observedProduction = -1;
	if capital ~= nil and YieldTypes ~= nil and YieldTypes.PRODUCTION ~= nil
		and capital.GetYield ~= nil then
		observedProduction = tonumber(capital:GetYield(YieldTypes.PRODUCTION) or -1) or -1;
	end
	Log("test combat toggle player=" .. tostring(playerID)
		.. " unit=" .. tostring(requestedID)
		.. " active=" .. tostring(not active)
		.. " modifier=" .. modifierID
		.. " capitalProductionModifier=" .. productionModifierID
		.. " capital=" .. tostring(capital ~= nil and capital:GetID() or -1)
		.. " observedProduction=" .. tostring(observedProduction));
end

local function Initialize()
	LOTM_MP_TurnSync.Add(OnPlayerTurnActivated,"Lifecycle");
	GameEvents.CityBuilt.Add(OnCityBuilt);
	Events.ResearchCompleted.Add(OnResearchCompleted);
	Events.UnitRemovedFromMap.Add(OnUnitRemovedFromMap);
	GameEvents.OnCombatOccurred.Add(OnCombatOccurred);
	GameEvents.PostUnitPromotionEarned.Add(OnPostUnitPromotionEarned);
	GameEvents.UnitInitialized.Add(OnUnitInitialized);
	GameEvents.LOTM_RP_Command_SelectPath.Add(OnSelectPath);
	GameEvents.LOTM_RP_Command_AcknowledgeSequence0Ceremony.Add(
		OnAcknowledgeSequenceZeroCeremony
	);
	GameEvents.LOTM_RP_Command_MarkOpeningComicShown.Add(OnMarkOpeningComicShown);
	-- TEST ONLY: keep this single registration adjacent to the switch above.
	GameEvents.LOTM_RP_Command_TestCombatToggle.Add(OnTestCombatToggle);
	LOTM_MP_TurnSync.RunStartup(ProcessAllPlayers,"Lifecycle");
	Log("initialized state version=" .. tostring(LOTM_RP_STATE_VERSION));
end

Initialize();
-- END POST_RC241_DELTA MODULE: Scripts/LOTM_RP_Lifecycle.lua
end;

m_mp241Loaders["LOTM_RP_Progression"] = function()
-- BEGIN POST_RC241_RULES MODULE: Scripts/LOTM_RP_Progression.lua
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("MP.LOTM_RP_Progression","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"MP.LOTM_RP_Progression","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"MP.LOTM_RP_Progression","GameEvents");
-- END RC342 STARTUP TRACE

-- Sequence-9/8 progression and project advancement.
-- Sequence 9 intentionally observes synchronized unit experience instead of
-- reconstructing discovery/combat events with UI-only visibility APIs.

local LOTM_RP_HERO_TYPE :string = "UNIT_LOTM_RP_PATH_HOLDER";
local LOTM_RP_SEQUENCE_PROPERTY :string = "LOTM_RP_SEQUENCE";
local LOTM_RP_HUNTER_XP_BASELINE :string = "LOTM_RP_HUNTER_XP_BASELINE";
local LOTM_RP_PROJECT_PROVOKER :string = "PROJECT_LOTM_RP_PROVOKER_POTION";
local LOTM_RP_PROJECT_PYROMANIAC :string = "PROJECT_LOTM_RP_PYROMANIAC_POTION";
local LOTM_RP_BELIEF_CHURCH :string = "BELIEF_LOTM_RP_ESTABLISH_CHURCH";
local LOTM_RP_BELIEF_TRUE_GOD :string = "BELIEF_LOTM_RP_TRUE_GOD_CHURCH";
local LOTM_RP_CHURCH_START_TURN :string = "LOTM_RP_CHURCH_START_TURN";
local LOTM_RP_TRUE_GOD_CHURCH :string = "LOTM_RP_TRUE_GOD_CHURCH";
local LOTM_RP_CAN_ADVANCE_SEQUENCE_0 :string = "LOTM_RP_CAN_ADVANCE_SEQUENCE_0";

local function Log(message :string)
	print("[LOTM_RP][Progression] " .. message);
end

local function GetPlayer(playerID :number)
	return playerID ~= nil and Players[playerID] or nil;
end

local function GetHeroTypeIndex()
	local definition = GameInfo.Units[LOTM_RP_HERO_TYPE];
	return definition ~= nil and definition.Index or -1;
end

local function IsHero(unit, playerID :number)
	return unit ~= nil
		and unit:GetOwner() == playerID
		and unit:GetType() == GetHeroTypeIndex();
end

local function GetSequence(playerID :number)
	return LOTM_RP_State.GetSequence(playerID);
end

local function IsRescueMode()
	return (tonumber(Game.GetProperty("LOTM_RESCUE_MODE") or 0) or 0) == 1;
end

local function GetHeroExperience(hero)
	if hero == nil then
		return nil;
	end
	local experience = hero:GetExperience();
	if experience == nil then
		return nil;
	end
	return experience:GetExperiencePoints() or 0;
end

local function ObserveHunterExperience(playerID :number, hero)
	if not LOTM_RP_State.IsEnabledPlayer(playerID)
		or GetSequence(playerID) ~= 9
		or not IsHero(hero, playerID) then
		return false;
	end
	local player = GetPlayer(playerID);
	local currentXP = GetHeroExperience(hero);
	if player == nil or currentXP == nil then
		return false;
	end

	local baseline = player:GetProperty(LOTM_RP_HUNTER_XP_BASELINE);
	if baseline == nil or baseline < 0 or currentXP < baseline then
		-- First observation, migration, or a defensive reset never grants
		-- historical progress. Respawned units restore the same XP and baseline.
		player:SetProperty(LOTM_RP_HUNTER_XP_BASELINE, currentXP);
		return false;
	end
	if currentXP > baseline then
		player:SetProperty(LOTM_RP_HUNTER_XP_BASELINE, currentXP);
		local objectKey = (IsRescueMode() and "RESCUE_P9:HUNTER_XP:" or "HUNTER_XP:")
			.. tostring(hero:GetID()) .. ":" .. tostring(currentXP);
		local added = LOTM_RP_State.TryAddDigestion(playerID, "A", objectKey);
		if added then
			Log("hunter experience progress player=" .. tostring(playerID)
				.. " xp=" .. tostring(currentXP));
		end
		return added;
	end
	return false;
end

local function GetBeliefIndex(beliefType :string)
	local definition = GameInfo.Beliefs[beliefType];
	return definition ~= nil and definition.Index or -1;
end

local function HasChurchPantheon(playerID :number)
	local player = GetPlayer(playerID);
	local religion = player ~= nil and player:GetReligion() or nil;
	local churchBeliefIndex = GetBeliefIndex(LOTM_RP_BELIEF_CHURCH);
	return religion ~= nil
		and churchBeliefIndex >= 0
		and religion:GetPantheon() == churchBeliefIndex;
end

local function HasFoundedBelief(playerID :number, beliefType :string)
	local beliefIndex = GetBeliefIndex(beliefType);
	if beliefIndex < 0 then
		return false;
	end
	local gameReligion = Game.GetReligion();
	local religions = gameReligion ~= nil and gameReligion:GetReligions() or {};
	for _, religion in ipairs(religions) do
		if religion.Founder == playerID then
			for _, religionBelief in ipairs(religion.Beliefs or {}) do
				if religionBelief == beliefIndex then
					return true;
				end
			end
		end
	end
	return false;
end

local function ProcessChurchEffects(playerID :number, allowGrant :boolean)
	local player = GetPlayer(playerID);
	if player == nil or not LOTM_RP_State.IsAnyPathPlayer(playerID) then
		return;
	end

	local currentTurn = Game.GetCurrentGameTurn();
	if HasChurchPantheon(playerID) then
		local startTurn = player:GetProperty(LOTM_RP_CHURCH_START_TURN);
		if startTurn == nil or startTurn < 0 then
			player:SetProperty(LOTM_RP_CHURCH_START_TURN, currentTurn);
			startTurn = currentTurn;
		end
		if allowGrant
			and currentTurn > startTurn
			and (currentTurn - startTurn) % 3 == 0 then
			LOTM_RP_State.TryAddDigestion(
				playerID,
				"A",
				(IsRescueMode() and "RESCUE_P9:AUX:CHURCH_TURN:" or "CHURCH_TURN:") .. tostring(currentTurn)
			);
		end
	end

	if HasFoundedBelief(playerID, LOTM_RP_BELIEF_TRUE_GOD) then
		player:SetProperty(LOTM_RP_TRUE_GOD_CHURCH, 1);
		player:SetProperty(LOTM_RP_CAN_ADVANCE_SEQUENCE_0, 1);
		if allowGrant then
			LOTM_RP_State.TryAddDigestion(
				playerID,
				"A",
				(IsRescueMode() and "RESCUE_P9:AUX:TRUE_GOD_CHURCH_TURN:" or "TRUE_GOD_CHURCH_TURN:") .. tostring(currentTurn)
			);
		end
	end
end

local function OnCommandChurchFounded(playerID :number, parameters :table)
	local player = GetPlayer(playerID);
	local churchBeliefIndex = GetBeliefIndex(LOTM_RP_BELIEF_CHURCH);
	local beliefID = parameters ~= nil and parameters.BeliefID or -1;
	if player == nil
		or not LOTM_RP_State.IsAnyPathPlayer(playerID)
		or churchBeliefIndex < 0
		or beliefID ~= churchBeliefIndex
		or not HasChurchPantheon(playerID) then
		Log("ERROR rejected church-founded command player=" .. tostring(playerID));
		return;
	end
	if (player:GetProperty(LOTM_RP_CHURCH_START_TURN) or -1) < 0 then
		player:SetProperty(
			LOTM_RP_CHURCH_START_TURN,
			Game.GetCurrentGameTurn()
		);
	end
end

local function OnCommandDenounce(playerID :number, parameters :table)
	local targetPlayerID = parameters ~= nil and parameters.TargetPlayerID or -1;
	local denounceTurn = parameters ~= nil
		and tonumber(parameters.DenounceTurn) or -1;
	local targetPlayer = GetPlayer(targetPlayerID);
	local sequence = GetSequence(playerID);
	local currentTurn = Game.GetCurrentGameTurn();
	if not LOTM_RP_State.IsEnabledPlayer(playerID)
		or sequence ~= 8
		or targetPlayerID == playerID
		or targetPlayer == nil
		or not targetPlayer:IsAlive()
		or not targetPlayer:IsMajor()
		or denounceTurn < 0
		or denounceTurn ~= math.floor(denounceTurn)
		or denounceTurn > currentTurn then
		Log("ERROR rejected denounce command player=" .. tostring(playerID)
			.. " target=" .. tostring(targetPlayerID)
			.. " denounceTurn=" .. tostring(denounceTurn)
			.. " currentTurn=" .. tostring(currentTurn));
		return;
	end
	LOTM_RP_State.TryAddDigestion(
		playerID,
		"A",
		"DENOUNCE_TARGET:" .. tostring(targetPlayerID)
			.. ":" .. tostring(denounceTurn)
	);
	Log("player=" .. tostring(playerID)
		.. " denounced target=" .. tostring(targetPlayerID)
		.. " turn=" .. tostring(denounceTurn)
		.. " sequence8 digestion submitted");
end

local function ProcessProgressionPlayer(playerID :number, allowTurnGrant :boolean)
	if not LOTM_RP_State.IsAnyPathPlayer(playerID) then
		return;
	end
	LOTM_RP_State.RefreshSequenceState(playerID);
	local sequence = GetSequence(playerID);
	if LOTM_RP_State.IsEnabledPlayer(playerID) and sequence == 9 then
		ObserveHunterExperience(playerID, LOTM_RP_State.FindHero(playerID));
	end
	ProcessChurchEffects(playerID, allowTurnGrant);
end

local function OnPlayerTurnActivated(playerID :number, isFirstTimeThisTurn :boolean)
	ProcessProgressionPlayer(playerID, isFirstTimeThisTurn);
end

local function OnUnitMoveComplete(playerID :number, unitID :number, x :number, y :number)
	local player = GetPlayer(playerID);
	local unit = player ~= nil and player:GetUnits():FindID(unitID) or nil;
	ObserveHunterExperience(playerID, unit);
end

local function OnGoodyHutReward(
	playerID :number,
	unitID :number,
	rewardType :number,
	rewardSubType :number
)
	local player = GetPlayer(playerID);
	local unit = player ~= nil and player:GetUnits():FindID(unitID) or nil;
	ObserveHunterExperience(playerID, unit);
end

local function CountStrongerTargetAttack(
	attackerPlayerID :number,
	attackerUnit,
	defenderPlayerID :number,
	defenderUnit
)
	if not IsHero(attackerUnit, attackerPlayerID)
		or defenderUnit == nil
		or GetSequence(attackerPlayerID) ~= 8 then
		return;
	end
	local attackerBase = attackerUnit:GetCombat() or 0;
	local defenderBase = defenderUnit:GetCombat() or 0;
	if defenderBase > attackerBase then
		LOTM_RP_State.TryAddDigestion(
			attackerPlayerID,
			"B",
			"TARGET_UNIT:" .. tostring(defenderPlayerID)
				.. ":" .. tostring(defenderUnit:GetID())
		);
	end
end

local function OnCombatOccurred(
	attackerPlayerID :number,
	attackerUnitID :number,
	defenderPlayerID :number,
	defenderUnitID :number
)
	local attackerPlayer = GetPlayer(attackerPlayerID);
	local defenderPlayer = GetPlayer(defenderPlayerID);
	local attackerUnit = attackerPlayer ~= nil
		and attackerPlayer:GetUnits():FindID(attackerUnitID) or nil;
	local defenderUnit = defenderPlayer ~= nil
		and defenderPlayer:GetUnits():FindID(defenderUnitID) or nil;

	ObserveHunterExperience(attackerPlayerID, attackerUnit);
	ObserveHunterExperience(defenderPlayerID, defenderUnit);
	CountStrongerTargetAttack(
		attackerPlayerID,
		attackerUnit,
		defenderPlayerID,
		defenderUnit
	);
end

local function OnPostUnitPromotionEarned(
	playerID :number,
	unitID :number,
	promotionType :number
)
	local player = GetPlayer(playerID);
	local unit = player ~= nil and player:GetUnits():FindID(unitID) or nil;
	ObserveHunterExperience(playerID, unit);
end

local function OnCityProjectCompleted(
	playerID :number,
	cityID :number,
	projectID :number
)
	-- AdvanceSequence is shared by every path.  A stale or externally granted
	-- Red Priest project must not advance a different path at the same sequence.
	if not LOTM_RP_State.IsEnabledPlayer(playerID) then
		return;
	end
	local provoker = GameInfo.Projects[LOTM_RP_PROJECT_PROVOKER];
	local pyromaniac = GameInfo.Projects[LOTM_RP_PROJECT_PYROMANIAC];
	local advanced = false;
	if provoker ~= nil and projectID == provoker.Index then
		advanced = LOTM_RP_State.AdvanceSequence(playerID, 9, 8);
	elseif pyromaniac ~= nil and projectID == pyromaniac.Index then
		advanced = LOTM_RP_State.AdvanceSequence(playerID, 8, 7);
	else
		return;
	end

	if not advanced then
		Log("ERROR rejected project completion player=" .. tostring(playerID)
			.. " project=" .. tostring(projectID)
			.. " sequence=" .. tostring(GetSequence(playerID)));
	end
end

local function Initialize()
	Events.PlayerTurnActivated.Add(OnPlayerTurnActivated);
	Events.UnitMoveComplete.Add(OnUnitMoveComplete);
	Events.GoodyHutReward.Add(OnGoodyHutReward);
	Events.CityProjectCompleted.Add(OnCityProjectCompleted);
	GameEvents.OnCombatOccurred.Add(OnCombatOccurred);
	GameEvents.PostUnitPromotionEarned.Add(OnPostUnitPromotionEarned);
	GameEvents.LOTM_RP_Command_Denounce.Add(OnCommandDenounce);
	GameEvents.LOTM_RP_Command_ChurchFounded.Add(OnCommandChurchFounded);

	for _, playerID in ipairs(PlayerManager.GetAliveMajorIDs()) do
		ProcessProgressionPlayer(playerID, false);
	end
	Log("initialized experience-driven sequence-9/8 progression");
end

Initialize();
-- END POST_RC241_RULES MODULE: Scripts/LOTM_RP_Progression.lua
end;

m_mp241Loaders["LOTM_TP_Thief"] = function()
-- BEGIN POST_RC241_NEW MODULE: Scripts/LOTM_TP_Thief.lua
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("MP.LOTM_TP_Thief","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"MP.LOTM_TP_Thief","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"MP.LOTM_TP_Thief","GameEvents");
-- END RC342 STARTUP TRACE

-- Thief pathway authoritative Gameplay module (normal mode only).
-- UI may only request the synchronized commands registered at the bottom.
LOTM_MP241_LoadBundledModule("LOTM_Effects");

local PATH = "PATH_THIEF";
local HERO = "UNIT_LOTM_TP_PATH_HOLDER";
local FAKE_GOLD = "RESOURCE_LOTM_TP_FAKE_GOLD";
local FAKE_GOLD_TRADE = "RESOURCE_LOTM_TP_FAKE_GOLD_TRADE";
local TOURISM_LUXURY = "RESOURCE_LOTM_TP_TOURISM_LUXURY";
local TARGET_COOLDOWN = 5;
local PROBE_VERSION = 4;
local LEGACY_TRADE_CARRIER_CLEANUP_VERSION = 1;
local PRODUCTION_DEBUFF_MINUS = "LOTM_TP_TARGET_PRODUCTION_MINUS_10";
local PRODUCTION_DEBUFF_PLUS = "LOTM_TP_TARGET_PRODUCTION_PLUS_10";
local pendingNetworkEvents = {};
local pendingNetworkEventKeys = {};

local P = {
	Target = "LOTM_TP_TARGET_PLAYER",
	TargetChangedTurn = "LOTM_TP_TARGET_CHANGED_TURN",
	BoostTurn = "LOTM_TP_LAST_BOOST_TURN",
	ProductionBuffer = "LOTM_TP_PRODUCTION_BUFFER",
	ScienceBuffer = "LOTM_TP_SCIENCE_BUFFER",
	CultureBuffer = "LOTM_TP_CULTURE_BUFFER",
	BorrowedCiv = "LOTM_TP_BORROWED_CIV",
	FinalBranch = "LOTM_TP_FINAL_BRANCH",
	TechNatural = "LOTM_TP_TECH_NATURAL_COUNT",
	CivicNatural = "LOTM_TP_CIVIC_NATURAL_COUNT",
	TechBurst = "LOTM_TP_TECH_BURST_ACTIVE",
	CivicBurst = "LOTM_TP_CIVIC_BURST_ACTIVE",
	PendingTech = "LOTM_TP_PENDING_TECH_GIFT",
	PendingCivic = "LOTM_TP_PENDING_CIVIC_GIFT",
	GiftGuardTech = "LOTM_TP_GIFT_GUARD_TECH",
	GiftGuardCivic = "LOTM_TP_GIFT_GUARD_CIVIC",
	GiftGuardTechIndex = "LOTM_TP_GIFT_GUARD_TECH_INDEX",
	GiftGuardCivicIndex = "LOTM_TP_GIFT_GUARD_CIVIC_INDEX",
	ProbeVersion = "LOTM_TP_PROBE_VERSION",
	CityTransferSupported = "LOTM_TP_CITY_TRANSFER_SUPPORTED",
	ProductionTransferSupported = "LOTM_TP_PRODUCTION_TRANSFER_SUPPORTED",
	AbilityDetachSupported = "LOTM_TP_ABILITY_DETACH_SUPPORTED",
	ReligionPressureSupported = "LOTM_TP_RELIGION_PRESSURE_SUPPORTED",
	TradeBridgeSupported = "LOTM_TP_TRADE_BRIDGE_SUPPORTED",
	LastProcessedTurn = "LOTM_TP_LAST_PROCESSED_TURN",
	LastProductionSettlementTurn = "LOTM_TP_LAST_PRODUCTION_SETTLEMENT_TURN",
	LastKnowledgeSource = "LOTM_TP_LAST_KNOWLEDGE_STEAL_SOURCE",
	LastKnowledgeTurn = "LOTM_TP_LAST_KNOWLEDGE_STEAL_TURN",
	LastKnowledgeScience = "LOTM_TP_LAST_KNOWLEDGE_STEAL_SCIENCE",
	LastKnowledgeCulture = "LOTM_TP_LAST_KNOWLEDGE_STEAL_CULTURE",
	LastKnowledgeFaith = "LOTM_TP_LAST_KNOWLEDGE_STEAL_FAITH",
	KnowledgeBonusScience = "LOTM_TP_KNOWLEDGE_BONUS_SCIENCE",
	KnowledgeBonusCulture = "LOTM_TP_KNOWLEDGE_BONUS_CULTURE",
	KnowledgeBonusFaith = "LOTM_TP_KNOWLEDGE_BONUS_FAITH",
	LastFakeGoldSettlement = "LOTM_TP_LAST_FAKE_GOLD_SETTLEMENT_SERIAL",
	LegacyTradeCarrierCleanup = "LOTM_TP_LEGACY_TRADE_CARRIER_CLEANUP_VERSION",
	ProductionDebuffTarget = "LOTM_TP_PRODUCTION_DEBUFF_TARGET",
	ParasiteOwner = "LOTM_TP_PARASITE_TARGET_OWNER",
	ParasiteCity = "LOTM_TP_PARASITE_TARGET_CITY",
	ParasiteX = "LOTM_TP_PARASITE_TARGET_X",
	ParasiteY = "LOTM_TP_PARASITE_TARGET_Y",
	ParasiteStartTurn = "LOTM_TP_PARASITE_START_TURN",
	ParasiteDueTurn = "LOTM_TP_PARASITE_DUE_TURN",
	LastParasiteCity = "LOTM_TP_LAST_PARASITE_CITY",
	LastParasiteTurn = "LOTM_TP_LAST_PARASITE_TURN",
	TourismBurstCleanupTurn = "LOTM_TP_TOURISM_BURST_CLEANUP_TURN",
	TourismBurstStock = "LOTM_TP_TOURISM_BURST_STOCK",
};

local POTIONS = {
	PROJECT_LOTM_TP_SWINDLER_POTION = {9, 8},
	PROJECT_LOTM_TP_CRYPTOLOGIST_POTION = {8, 7},
	PROJECT_LOTM_TP_PROMETHEUS_POTION = {7, 6},
	PROJECT_LOTM_TP_DREAM_STEALER_POTION = {6, 5},
	PROJECT_LOTM_TP_PARASITE_POTION = {5, 4},
	PROJECT_LOTM_TP_MENTOR_OF_DECEIT_POTION = {4, 3},
	PROJECT_LOTM_TP_FATE_TROJAN_POTION = {3, 2},
	PROJECT_LOTM_TP_WORM_OF_TIME_POTION = {2, 1},
	PROJECT_LOTM_TP_ERROR_APOTHEOSIS = {1, 0},
};

local function Log(message)
	print("[LOTM_TP][Thief] " .. tostring(message));
end

local function IsRescueMode()
	local state = tonumber(Game.GetProperty("LOTM_RESCUE_MODE") or 0) or 0;
	if state == 1 then return true; end
	if LOTM_MP_TurnSync ~= nil
		and type(LOTM_MP_TurnSync.IsRescueModeConfigured) == "function" then
		return LOTM_MP_TurnSync.IsRescueModeConfigured();
	end
	local configured = GameConfiguration.GetValue("GAMEMODE_LOTM_RESCUE");
	return configured == true or tonumber(configured or 0) == 1;
end

local function IsNetworkGame()
	return LOTM_MP_TurnSync ~= nil
		and type(LOTM_MP_TurnSync.IsNetworkGame) == "function"
		and LOTM_MP_TurnSync.IsNetworkGame() == true;
end

local function IsThief(playerID)
	return not IsRescueMode() and LOTM_RP_State ~= nil
		and LOTM_RP_State.IsThiefPlayer ~= nil
		and LOTM_RP_State.IsThiefPlayer(playerID);
end

local function GetSequence(playerID)
	return LOTM_RP_State.GetSequence(playerID);
end

local function StableRand(limit, label)
	if limit <= 0 then return 0; end
	local modulus, value = 2147483647, 104729;
	local gameSeed = GameConfiguration ~= nil and GameConfiguration.GetValue ~= nil
		and GameConfiguration.GetValue("GAME_SYNC_RANDOM_SEED") or 0;
	local mapSeed = MapConfiguration ~= nil and MapConfiguration.GetValue ~= nil
		and MapConfiguration.GetValue("RANDOM_SEED") or 0;
	local text = tostring(gameSeed) .. ":" .. tostring(mapSeed) .. ":LOTM_TP:" .. tostring(label);
	for index = 1, #text do value = (value * 131 + string.byte(text, index)) % modulus; end
	return value % limit;
end

local function GetResourceIndex()
	local row = GameInfo.Resources[FAKE_GOLD];
	return row ~= nil and row.Index or -1;
end

local function GetTradeBackingIndex()
	local row = GameInfo.Resources[FAKE_GOLD_TRADE];
	return row ~= nil and row.Index or -1;
end

local function GetTourismLuxuryIndex()
	local row = GameInfo.Resources[TOURISM_LUXURY];
	return row ~= nil and row.Index or -1;
end

local function GetResourceAmount(player, resourceIndex)
	local resources = player ~= nil and player:GetResources() or nil;
	if resourceIndex < 0 or resources == nil then return 0; end
	return math.max(0, math.floor(tonumber(resources:GetResourceAmount(resourceIndex)) or 0));
end

local function ChangeResourceAmount(player, resourceIndex, amount)
	local resources = player ~= nil and player:GetResources() or nil;
	if resourceIndex < 0 or resources == nil or resources.ChangeResourceAmount == nil then return false; end
	local current = GetResourceAmount(player, resourceIndex);
	local delta = math.floor(tonumber(amount) or 0);
	if delta < 0 then delta = -math.min(current, -delta); end
	if delta == 0 then return true; end
	resources:ChangeResourceAmount(resourceIndex, delta);
	return GetResourceAmount(player, resourceIndex) == current + delta;
end

local function GetFakeGold(player)
	return GetResourceAmount(player, GetResourceIndex());
end

local function ChangeFakeGold(player, amount)
	return ChangeResourceAmount(player, GetResourceIndex(), amount);
end

-- Tourism is granted by a native player tourism modifier.  The previous
-- implementation tried to fake an excess luxury inventory, but GameCore does
-- not count arbitrary ChangeResourceAmount stock as excess luxuries.
local function ReadInternationalTourists(player)
	local ok, value = pcall(function() return player:GetCulture():GetTouristsTo(); end);
	return ok and tonumber(value) or nil;
end

-- Civ VI exposes GetTouristsTo/GetTouristsFrom as read-only accessors in the
-- public Lua surface.  Keep the direct grant isolated here: if a game build
-- exposes a setter/change method, use it and verify the observed delta; if it
-- does not, leave the existing tourism modifier intact and record the exact
-- limitation instead of pretending a percentage is a fixed tourist grant.
local function GrantDirectInternationalTourists(player, amount)
	local before = ReadInternationalTourists(player);
	local directAmount = math.max(0, math.floor(tonumber(amount) or 0));
	if before == nil or directAmount <= 0 then return false, "NO_BASELINE"; end
	local culture = player ~= nil and player:GetCulture() or nil;
	local attempts = {
		{culture, "ChangeTouristsTo", function(target) return before + directAmount; end},
		{culture, "ChangeTourism", function() return directAmount; end},
		{culture, "SetTouristsTo", function() return before + directAmount; end},
		{player, "ChangeTourism", function() return directAmount; end},
		{player, "ChangeTourists", function() return directAmount; end},
		{player, "SetTouristsTo", function() return before + directAmount; end},
	};
	for _, attempt in ipairs(attempts) do
		local target, method, argument = attempt[1], attempt[2], attempt[3];
		local ok, available = pcall(function() return target ~= nil and type(target[method]) == "function"; end);
		if ok and available then
			local callOK = pcall(function() target[method](target, argument(target)); end);
			local after = ReadInternationalTourists(player);
			if callOK and after ~= nil and after >= before + directAmount then
				return true, method;
			end
		end
	end
	return false, "NO_PUBLIC_SETTER";
end

-- Select a fresh pre-registered instance for every serial so repeated projects
-- add another tourism-only modifier instead of being deduplicated.
local function ResolveTourismBurstModifier(baseID, serial)
	local branch = baseID == "LOTM_TP_TOURISM_BURST_II" and "II" or "I";
	local slot = math.floor(tonumber(serial) or 0);
	if slot >= 1 and slot <= 64 then
		return "LOTM_TP_TOURISM_BURST_" .. branch .. "_" .. tostring(slot);
	end
	return baseID;
end

local function ApplyTourismBurst(playerID, modifierID, amount)
	local player = Players[playerID];
	if player == nil then
		Log("culture transfer tourism failed player=" .. tostring(playerID)
			.. " modifier=" .. tostring(modifierID) .. " reason=NO_PLAYER");
		return false;
	end
	local touristsBefore = ReadInternationalTourists(player);
	local serial = (tonumber(player:GetProperty("LOTM_TP_TOURISM_SERIAL") or 0) or 0) + 1;
	local appliedModifierID = ResolveTourismBurstModifier(modifierID, serial);
	local ok, err = pcall(function() return player:AttachModifierByID(appliedModifierID); end);
	if not ok or err == false then
		Log("culture transfer tourism failed player=" .. tostring(playerID)
			.. " modifier=" .. tostring(appliedModifierID) .. " reason=ATTACH error=" .. tostring(err));
		return false;
	end
	local directAmount = modifierID == "LOTM_TP_TOURISM_BURST_II" and 15 or 5;
	local directOK, directReason = GrantDirectInternationalTourists(player, directAmount);
	player:SetProperty("LOTM_TP_TOURISM_SERIAL", serial);
	player:SetProperty("LOTM_TP_TOURISM_BEFORE", touristsBefore);
	player:SetProperty("LOTM_TP_TOURISM_AMOUNT", amount);
	player:SetProperty("LOTM_TP_TOURISM_DIRECT_AMOUNT", directAmount);
	Log("culture transfer tourism requested player=" .. tostring(playerID) .. " serial=" .. serial
		.. " modifier=" .. tostring(appliedModifierID) .. " amount=" .. tostring(amount)
		.. " effect=PLAYER_ADJUST_TOURISM"
		.. " directTourists=" .. tostring(directAmount)
		.. " directApplied=" .. tostring(directOK)
		.. " directMethod=" .. tostring(directReason)
		.. " touristsBefore=" .. tostring(touristsBefore) .. " touristsAfter=" .. tostring(ReadInternationalTourists(player)));
	return true;
end

local function CleanupTourismBurst(playerID, player, turn)
	local version = tonumber(player:GetProperty("LOTM_TP_TOURISM_CLEANUP_VERSION") or 0) or 0;
	if version >= 2 then return; end
	-- Clear only legacy rc.311–rc.315 carrier stock.  New transfers never
	-- create this resource and therefore cannot affect trade or luxury counts.
	local index = GetTourismLuxuryIndex();
	local stock = index >= 0 and GetResourceAmount(player, index) or 0;
	if stock > 0 and not ChangeResourceAmount(player, index, -stock) then
		Log("legacy tourism carrier cleanup failed player=" .. tostring(playerID)
			.. " amount=" .. tostring(stock));
		return;
	end
	player:SetProperty(P.TourismBurstCleanupTurn, nil);
	player:SetProperty(P.TourismBurstStock, nil);
	player:SetProperty("LOTM_TP_TOURISM_CLEANUP_VERSION", 2);
	if stock > 0 then
		Log("legacy tourism carrier cleared player=" .. tostring(playerID) .. " amount=" .. tostring(stock));
	end
end

local function ClearLegacyTradeCarrier(playerID)
	if IsNetworkGame() then return false; end
	local player = Players[playerID];
	if player == nil then return false; end
	local migrated = tonumber(player:GetProperty(P.LegacyTradeCarrierCleanup) or 0) or 0;
	if migrated >= LEGACY_TRADE_CARRIER_CLEANUP_VERSION then return true; end
	local backingIndex = GetTradeBackingIndex();
	if backingIndex < 0 then
		player:SetProperty(P.LegacyTradeCarrierCleanup, LEGACY_TRADE_CARRIER_CLEANUP_VERSION);
		return true;
	end
	local current = GetResourceAmount(player, backingIndex);
	if current > 0 and not ChangeResourceAmount(player, backingIndex, -current) then
		Log("legacy trade carrier cleanup failed player=" .. tostring(playerID)
			.. " amount=" .. tostring(current));
		return false;
	end
	player:SetProperty(P.LegacyTradeCarrierCleanup, LEGACY_TRADE_CARRIER_CLEANUP_VERSION);
	if current > 0 then
		Log("legacy trade carrier cleared player=" .. tostring(playerID)
			.. " amount=" .. tostring(current));
	end
	return true;
end

local function IsSameTeam(a, b)
	return a ~= nil and b ~= nil and a:GetTeam() == b:GetTeam();
end

local function HasMet(player, targetID)
	local diplomacy = player ~= nil and player:GetDiplomacy() or nil;
	return diplomacy ~= nil and diplomacy:HasMet(targetID);
end

local function IsLegalTarget(playerID, targetID)
	local player = Players[playerID];
	local target = Players[targetID];
	return targetID ~= nil and targetID >= 0 and targetID ~= playerID
		and player ~= nil and target ~= nil and target:IsAlive() and target:IsMajor()
		and not IsSameTeam(player, target) and HasMet(player, targetID);
end

local function ResolveTarget(playerID)
	local player = Players[playerID];
	local targetID = player ~= nil and tonumber(player:GetProperty(P.Target) or -1) or -1;
	if not IsLegalTarget(playerID, targetID) then
		if player ~= nil and targetID >= 0 then
			player:SetProperty(P.Target, -1);
			Log("target cleared player=" .. playerID .. " target=" .. targetID);
		end
		return -1, nil;
	end
	return targetID, Players[targetID];
end

local function AddDigestion(playerID, category, key, amount)
	if LOTM_RP_State ~= nil and LOTM_RP_State.TryAddDigestion ~= nil then
		return LOTM_RP_State.TryAddDigestion(playerID, category, key, amount);
	end
	return false;
end

local function TransferGold(playerID, targetID, target)
	local player = Players[playerID];
	local treasury = player ~= nil and player:GetTreasury() or nil;
	local targetTreasury = target ~= nil and target:GetTreasury() or nil;
	if treasury == nil or targetTreasury == nil then return 0; end
	local yield = math.max(0, tonumber(targetTreasury:GetGoldYield()) or 0);
	local amount = LOTM_Effects.CappedPercentFloor(yield, 50,
		targetTreasury:GetGoldBalance());
	if amount <= 0 then return 0; end
	local networkGame = LOTM_MP_TurnSync ~= nil and LOTM_MP_TurnSync.IsNetworkGame ~= nil
		and LOTM_MP_TurnSync.IsNetworkGame() == true;
	if not networkGame then
		-- A single-player transfer is committed only when both observable balance
		-- deltas match.  This also makes future logs prove that the 50% calculation
		-- reached the player's treasury instead of merely reaching this function.
		local playerBefore = tonumber(treasury:GetGoldBalance()) or 0;
		local targetBefore = tonumber(targetTreasury:GetGoldBalance()) or 0;
		local debitOK = pcall(function() targetTreasury:ChangeGoldBalance(-amount); end);
		local targetAfterDebit = tonumber(targetTreasury:GetGoldBalance()) or targetBefore;
		local actualDebit = targetBefore - targetAfterDebit;
		local creditOK = false;
		if debitOK and math.abs(actualDebit - amount) < 0.001 then
			creditOK = pcall(function() treasury:ChangeGoldBalance(amount); end);
		end
		local playerAfter = tonumber(treasury:GetGoldBalance()) or playerBefore;
		local actualCredit = playerAfter - playerBefore;
		if not debitOK or not creditOK or math.abs(actualDebit - amount) >= 0.001
			or math.abs(actualCredit - amount) >= 0.001 then
			-- Reverse only the deltas actually observed; a partial API failure must
			-- not create gold or silently delete it.
			if math.abs(actualDebit) >= 0.001 then
				pcall(function() targetTreasury:ChangeGoldBalance(actualDebit); end);
			end
			if math.abs(actualCredit) >= 0.001 then
				pcall(function() treasury:ChangeGoldBalance(-actualCredit); end);
			end
			Log("gold transfer rolled back player=" .. playerID .. " target=" .. targetID
				.. " requested=" .. amount .. " debited=" .. actualDebit .. " credited=" .. actualCredit);
			return 0;
		end
		Log("gold stolen player=" .. playerID .. " target=" .. targetID
			.. " yield=" .. yield .. " rate=50pct amount=" .. amount
			.. " targetBefore=" .. targetBefore .. " targetAfter=" .. targetAfterDebit
			.. " playerBefore=" .. playerBefore .. " playerAfter=" .. playerAfter);
		local capital = player:GetCities() ~= nil and player:GetCities():GetCapitalCity() or nil;
		if capital ~= nil and Game.AddWorldViewText ~= nil then
			-- Match the mod's existing yield-float presentation.  This is deliberately
			-- best-effort and runs only after the authoritative balance transaction.
			pcall(function()
				Game.AddWorldViewText(playerID,
					"[COLOR_FLOAT_GOLD]+" .. tostring(amount) .. " [ICON_Gold][ENDCOLOR]",
					capital:GetX(), capital:GetY());
			end);
		end
		return amount;
	end
	targetTreasury:ChangeGoldBalance(-amount);
	treasury:ChangeGoldBalance(amount);
	Log("gold stolen player=" .. playerID .. " target=" .. targetID .. " amount=" .. amount);
	return amount;
end

local function ApplyProgressBuffer(player, kind)
	local key = kind == "TECH" and P.ScienceBuffer or P.CultureBuffer;
	local amount = math.floor(tonumber(player:GetProperty(key) or 0) or 0);
	if amount <= 0 then return 0; end
	local object = kind == "TECH" and player:GetTechs() or player:GetCulture();
	if object == nil then return 0; end
	local current = kind == "TECH" and object:GetResearchingTech() or object:GetProgressingCivic();
	if current == nil or current < 0 then return 0; end
	local ok = pcall(function()
		if kind == "TECH" then object:ChangeCurrentResearchProgress(amount);
		else object:ChangeCurrentCulturalProgress(amount); end
	end);
	if ok then player:SetProperty(key, 0); return amount; end
	return 0;
end

local KNOWLEDGE_BONUS = {
	SCIENCE = {
		Property = P.KnowledgeBonusScience,
		Plus = "LOTM_TP_KNOWLEDGE_SCIENCE_PLUS_1",
		Minus = "LOTM_TP_KNOWLEDGE_SCIENCE_MINUS_1",
	},
	CULTURE = {
		Property = P.KnowledgeBonusCulture,
		Plus = "LOTM_TP_KNOWLEDGE_CULTURE_PLUS_1",
		Minus = "LOTM_TP_KNOWLEDGE_CULTURE_MINUS_1",
	},
	FAITH = {
		Property = P.KnowledgeBonusFaith,
		Plus = "LOTM_TP_KNOWLEDGE_FAITH_PLUS_1",
		Minus = "LOTM_TP_KNOWLEDGE_FAITH_MINUS_1",
	},
};

-- MODIFIER_PLAYER_ADJUST_YIELD_CHANGE is the same native flat-yield effect
-- already used by this mod's artifact and Hanged Man systems.  Keeping the
-- current net amount in a synchronized Property lets Gameplay attach only the
-- delta; the yield engine then updates both the top-panel total and settlement.
local function SetKnowledgeYieldBonus(playerID, player, category, desired)
	local definition = KNOWLEDGE_BONUS[category];
	if player == nil or definition == nil or player.AttachModifierByID == nil then
		return false, 0;
	end
	desired = math.max(0, math.floor(tonumber(desired or 0) or 0));
	local old = math.max(0, math.floor(tonumber(player:GetProperty(definition.Property) or 0) or 0));
	local delta = desired - old;
	if delta == 0 then return true, old; end
	local modifierID = delta > 0 and definition.Plus or definition.Minus;
	local rollbackID = delta > 0 and definition.Minus or definition.Plus;
	local count = math.abs(delta);
	local applied = 0;
	for _ = 1, count do
		local ok = pcall(function() player:AttachModifierByID(modifierID); end);
		if not ok then
			for _ = 1, applied do
				pcall(function() player:AttachModifierByID(rollbackID); end);
			end
			Log("knowledge yield bonus failed player=" .. playerID
				.. " category=" .. category .. " old=" .. old
				.. " desired=" .. desired .. " applied=" .. applied);
			return false, old;
		end
		applied = applied + 1;
	end
	player:SetProperty(definition.Property, desired);
	Log("knowledge yield bonus player=" .. playerID .. " category=" .. category
		.. " old=" .. old .. " desired=" .. desired .. " delta=" .. delta);
	return true, old;
end

local function RestoreKnowledgeYieldBonus(playerID, player, category, old)
	local restored = SetKnowledgeYieldBonus(playerID, player, category, old);
	if not restored then
		Log("knowledge yield bonus rollback failed player=" .. playerID
			.. " category=" .. category .. " desired=" .. tostring(old));
	end
end

local function ClearKnowledgeYieldBonuses(playerID, player)
	SetKnowledgeYieldBonus(playerID, player, "SCIENCE", 0);
	SetKnowledgeYieldBonus(playerID, player, "CULTURE", 0);
	SetKnowledgeYieldBonus(playerID, player, "FAITH", 0);
end

local function TransferKnowledgeAndFaith(playerID, targetID, target)
	local player = Players[playerID];
	if player == nil or target == nil then return 0; end
	-- Settle any legacy buffer once, then use native per-turn modifiers only.
	ApplyProgressBuffer(player, "TECH");
	ApplyProgressBuffer(player, "CIVIC");
	local movedScience, movedCulture, movedFaith = 0, 0, 0;
	local sourceTech = target:GetTechs();
	local sourceTechID = sourceTech ~= nil and sourceTech:GetResearchingTech() or -1;
	local science = sourceTech ~= nil and LOTM_Effects.PercentFloor(sourceTech:GetScienceYield(), 20) or 0;
	if science > 0 and sourceTechID ~= nil and sourceTechID >= 0 then
		science = math.min(science, math.floor(math.max(0, sourceTech:GetResearchProgress(sourceTechID))));
	else
		science = 0;
	end
	local scienceBonusOK, oldScience = SetKnowledgeYieldBonus(playerID, player, "SCIENCE", science);
	if scienceBonusOK and science > 0 then
		local ok, failure = pcall(function() sourceTech:ChangeCurrentResearchProgress(-science); end);
		if ok then movedScience = science;
		else
			RestoreKnowledgeYieldBonus(playerID, player, "SCIENCE", oldScience);
			Log("knowledge transfer failed player=" .. playerID .. " category=SCIENCE reason=" .. tostring(failure));
		end
	end
	local sourceCulture = target:GetCulture();
	local sourceCivicID = sourceCulture ~= nil and sourceCulture:GetProgressingCivic() or -1;
	local culture = sourceCulture ~= nil and LOTM_Effects.PercentFloor(sourceCulture:GetCultureYield(), 20) or 0;
	if culture > 0 and sourceCivicID ~= nil and sourceCivicID >= 0
		and sourceCulture.ChangeCurrentCulturalProgress == nil then
		Log("knowledge transfer failed player=" .. playerID .. " category=CULTURE reason=NO_PROGRESS_API");
	end
	if culture <= 0 or sourceCivicID == nil or sourceCivicID < 0
		or sourceCulture.ChangeCurrentCulturalProgress == nil then
		culture = 0;
	end
	local cultureBonusOK, oldCulture = SetKnowledgeYieldBonus(playerID, player, "CULTURE", culture);
	if cultureBonusOK and culture > 0 then
		-- GetCulturalProgress is exposed to Firaxis UI contexts but is nil in
		-- authoritative Gameplay.  Sequence 5 steals current positive Culture
		-- yield, so debit the calculated share without a UI-only progress read.
		local ok, failure = pcall(function() sourceCulture:ChangeCurrentCulturalProgress(-culture); end);
		if ok then movedCulture = culture;
		else
			RestoreKnowledgeYieldBonus(playerID, player, "CULTURE", oldCulture);
			Log("knowledge transfer failed player=" .. playerID .. " category=CULTURE reason=" .. tostring(failure));
		end
	end
	local sourceReligion = target:GetReligion();
	local faithYield = sourceReligion ~= nil and LOTM_Effects.PercentFloor(sourceReligion:GetFaithYield(), 20) or 0;
	local faith = sourceReligion ~= nil and math.min(faithYield, math.floor(math.max(0, sourceReligion:GetFaithBalance()))) or 0;
	local faithBonusOK, oldFaith = SetKnowledgeYieldBonus(playerID, player, "FAITH", faith);
	if faithBonusOK and faith > 0 then
		local ok, failure = pcall(function() sourceReligion:ChangeFaithBalance(-faith); end);
		if ok then movedFaith = faith;
		else
			RestoreKnowledgeYieldBonus(playerID, player, "FAITH", oldFaith);
			Log("knowledge transfer failed player=" .. playerID .. " category=FAITH reason=" .. tostring(failure));
		end
	end
	local moved = movedScience + movedCulture + movedFaith;
	if moved > 0 then
		local turn = Game.GetCurrentGameTurn();
		player:SetProperty(P.LastKnowledgeSource, targetID);
		player:SetProperty(P.LastKnowledgeTurn, turn);
		player:SetProperty(P.LastKnowledgeScience, movedScience);
		player:SetProperty(P.LastKnowledgeCulture, movedCulture);
		player:SetProperty(P.LastKnowledgeFaith, movedFaith);
		Log("knowledge stolen player=" .. playerID .. " target=" .. targetID
			.. " science=" .. movedScience .. " culture=" .. movedCulture
			.. " faith=" .. movedFaith .. " total=" .. moved
			.. " destination=NATIVE_PER_TURN_YIELD");
	end
	return moved;
end

local function TriggerRandomBoost(playerID)
	local player = Players[playerID];
	if player == nil then return false; end
	local candidates = {};
	local techs = player:GetTechs();
	for row in GameInfo.Technologies() do
		if not techs:HasTech(row.Index) and not techs:HasBoostBeenTriggered(row.Index) then
			table.insert(candidates, {kind="TECH", index=row.Index});
		end
	end
	local culture = player:GetCulture();
	for row in GameInfo.Civics() do
		if not culture:HasCivic(row.Index) and not culture:HasBoostBeenTriggered(row.Index) then
			table.insert(candidates, {kind="CIVIC", index=row.Index});
		end
	end
	table.sort(candidates, function(a,b) if a.kind == b.kind then return a.index < b.index; end return a.kind < b.kind; end);
	if #candidates == 0 then return false; end
	local pick = candidates[StableRand(#candidates, playerID .. ":BOOST:" .. Game.GetCurrentGameTurn()) + 1];
	local ok = pcall(function()
		if pick.kind == "TECH" then techs:TriggerBoost(pick.index, 1);
		else culture:TriggerBoost(pick.index, 1); end
	end);
	if ok then Log("boost player=" .. playerID .. " kind=" .. pick.kind .. " index=" .. pick.index); end
	return ok;
end

local function ProbePlayer(playerID)
	local player = Players[playerID];
	if player == nil then return; end
	local oldVersion = tonumber(player:GetProperty(P.ProbeVersion) or 0) or 0;
	local oldProduction = tonumber(player:GetProperty(P.ProductionTransferSupported) or -1) or -1;
	local oldDetach = tonumber(player:GetProperty(P.AbilityDetachSupported) or -1) or -1;
	local oldReligion = tonumber(player:GetProperty(P.ReligionPressureSupported) or -1) or -1;
	local oldTrade = tonumber(player:GetProperty(P.TradeBridgeSupported) or -1) or -1;
	player:SetProperty(P.ProbeVersion, PROBE_VERSION);
	-- CityManager.TransferCity is the native, lossless ownership API used by
	-- the subscribed Amon mod.  Expose the capability only when the runtime
	-- actually provides it; the UI remains hidden on builds without it.
	local cityTransferSupported = CityManager ~= nil and CityManager.TransferCity ~= nil;
	player:SetProperty(P.CityTransferSupported, cityTransferSupported and 1 or 0);
	local tradeSupported = not IsNetworkGame();
	player:SetProperty(P.TradeBridgeSupported, tradeSupported and 1 or 0);
	local capital = player:GetCities() ~= nil and player:GetCities():GetCapitalCity() or nil;
	local queue = capital ~= nil and capital:GetBuildQueue() or nil;
	-- The shipped Gameplay build queue exposes AddProgress (the same API used
	-- by the subscribed Amon mod), not ChangeCurrentProductionProgress.
	local productionSupported = queue ~= nil and queue.AddProgress ~= nil;
	player:SetProperty(P.ProductionTransferSupported, productionSupported and 1 or 0);
	player:SetProperty(P.AbilityDetachSupported, player.DetachModifierByID ~= nil and 1 or 0);
	local cityReligion = capital ~= nil and capital:GetReligion() or nil;
	player:SetProperty(P.ReligionPressureSupported,
		cityReligion ~= nil and cityReligion.AddReligiousPressure ~= nil and 1 or 0);
	local productionValue = productionSupported and 1 or 0;
	local detachValue = player.DetachModifierByID ~= nil and 1 or 0;
	local religionValue = cityReligion ~= nil and cityReligion.AddReligiousPressure ~= nil and 1 or 0;
	if oldVersion < PROBE_VERSION or oldProduction ~= productionValue
		or oldTrade ~= (tradeSupported and 1 or 0)
		or oldDetach ~= detachValue or oldReligion ~= religionValue then
			Log("probe player=" .. playerID
			.. " cityTransfer=" .. tostring(cityTransferSupported)
			.. " production=" .. tostring(productionSupported)
			.. " detach=" .. tostring(player.DetachModifierByID ~= nil)
			.. " religion=" .. tostring(cityReligion ~= nil and cityReligion.AddReligiousPressure ~= nil));
	end
end

local function AttachProductionDebuff(target, modifierID)
	if target == nil or target.AttachModifierByID == nil then return false; end
	return pcall(function() target:AttachModifierByID(modifierID); end);
end

local function DetachProductionDebuff(target, modifierID)
	if target == nil or target.DetachModifierByID == nil then return false; end
	return pcall(function() target:DetachModifierByID(modifierID); end);
end

local function ChangeProductionDebuffOwner(target, delta)
	if target == nil then return; end
	local count = math.max(0, tonumber(target:GetProperty("LOTM_TP_PRODUCTION_DEBUFF_COUNT") or 0) or 0);
	local nextCount = math.max(0, count + delta);
	if count == 0 and nextCount > 0 then
		AttachProductionDebuff(target, PRODUCTION_DEBUFF_MINUS);
	elseif count > 0 and nextCount == 0 then
		if not DetachProductionDebuff(target, PRODUCTION_DEBUFF_MINUS) then
			AttachProductionDebuff(target, PRODUCTION_DEBUFF_PLUS);
		end
	end
	target:SetProperty("LOTM_TP_PRODUCTION_DEBUFF_COUNT", nextCount);
	target:SetProperty("LOTM_TP_PRODUCTION_DEBUFF_ACTIVE", nextCount > 0 and 1 or 0);
end

local function SyncProductionDebuff(playerID, targetID, target)
	local player = Players[playerID];
	if player == nil then return; end
	local oldID = tonumber(player:GetProperty(P.ProductionDebuffTarget) or -1) or -1;
	if oldID == targetID then return; end
	if oldID >= 0 and Players[oldID] ~= nil then ChangeProductionDebuffOwner(Players[oldID], -1); end
	if targetID ~= nil and targetID >= 0 and target ~= nil then ChangeProductionDebuffOwner(target, 1); end
	player:SetProperty(P.ProductionDebuffTarget, targetID ~= nil and targetID or -1);
	Log("production debuff target player=" .. playerID .. " target=" .. tostring(targetID or -1));
end

local function AccrueProduction(playerID, targetID, target)
	local player = Players[playerID];
	if player == nil or target == nil or (player:GetProperty(P.ProductionTransferSupported) or 0) ~= 1 then return 0; end
	-- The target cities carry the authoritative -10% modifier. Read their
	-- post-debuff production and transfer the corresponding lost share.
	local cities = {};
	for _, city in target:GetCities():Members() do cities[#cities + 1] = city; end
	table.sort(cities, function(a, b) return a:GetID() < b:GetID(); end);
	local total = 0;
	local postProductionTotal = 0;
	for _, city in ipairs(cities) do
		local after = math.max(0, tonumber(city:GetYield(YieldTypes.PRODUCTION)) or 0);
		postProductionTotal = postProductionTotal + after;
		local amount = math.floor((after / 0.9) * 0.1 + 0.0001);
		if amount > 0 then total = total + amount; end
	end
	if total <= 0 then return 0; end

	local buffered = math.floor(tonumber(player:GetProperty(P.ProductionBuffer) or 0) or 0);
	local nextBuffer = buffered + total;
	player:SetProperty(P.ProductionBuffer, nextBuffer);
	Log("production accrued player=" .. playerID .. " target=" .. targetID
		.. " postDebuffProduction=" .. postProductionTotal .. " amount=" .. total
		.. " buffer=" .. nextBuffer .. " awaiting=EXECUTE_SCRIPT");
	return total;
end

local function GetProductionQueue(city)
	local queue = city ~= nil and city:GetBuildQueue() or nil;
	if queue == nil or queue.AddProgress == nil then return nil, 0; end
	local currentHash = -1;
	if queue.GetCurrentProductionTypeHash ~= nil then
		local ok = pcall(function() currentHash = queue:GetCurrentProductionTypeHash(); end);
		if ok and tonumber(currentHash or 0) == 0 then return nil, 0; end
	end
	return queue, tonumber(currentHash or -1) or -1;
end

local function ProductionDestinations(playerID, player)
	local result, fallback = {}, {};
	local capital = player:GetCities():GetCapitalCity();
	local capitalQueue, capitalHash = GetProductionQueue(capital);
	if capitalQueue ~= nil then
		result[#result + 1] = {City=capital, Queue=capitalQueue, Hash=capitalHash};
	end
	for _, city in player:GetCities():Members() do
		if capital == nil or city:GetID() ~= capital:GetID() then
			local queue, currentHash = GetProductionQueue(city);
			if queue ~= nil then fallback[#fallback + 1] = {City=city, Queue=queue, Hash=currentHash}; end
		end
	end
	table.sort(fallback, function(a, b) return a.City:GetID() < b.City:GetID(); end);
	if #fallback > 0 then
		local start = StableRand(#fallback, playerID .. ":S6:DEST:" .. Game.GetCurrentGameTurn()) + 1;
		for offset = 0, #fallback - 1 do
			result[#result + 1] = fallback[((start + offset - 1) % #fallback) + 1];
		end
	end
	return result;
end

local function OnSettleProduction(playerID, parameters)
	if not IsThief(playerID) or GetSequence(playerID) > 6 then return; end
	local player = Players[playerID];
	local turn = Game.GetCurrentGameTurn();
	if tonumber(player:GetProperty(P.LastProductionSettlementTurn) or -1) == turn then return; end
	local amount = math.floor(tonumber(player:GetProperty(P.ProductionBuffer) or 0) or 0);
	if amount <= 0 or (player:GetProperty(P.ProductionTransferSupported) or 0) ~= 1 then return; end
	local lastError = "NO_RECEIVING_QUEUE";
	for _, destination in ipairs(ProductionDestinations(playerID, player)) do
		local accepted, failure = pcall(function() destination.Queue:AddProgress(amount); end);
		if accepted then
			player:SetProperty(P.ProductionBuffer, 0);
			player:SetProperty(P.LastProductionSettlementTurn, turn);
			player:SetProperty("LOTM_TP_LAST_PRODUCTION_STEAL_AMOUNT", amount);
			player:SetProperty("LOTM_TP_LAST_PRODUCTION_STEAL_CITY", destination.City:GetID());
			player:SetProperty("LOTM_TP_LAST_PRODUCTION_STEAL_TURN", turn);
			Log("production stolen player=" .. playerID .. " amount=" .. amount
				.. " destinationCity=" .. destination.City:GetID()
				.. " productionHash=" .. destination.Hash
				.. " mode=YIELD_DEBUFF api=EXECUTE_SCRIPT:AddProgress");
			local sequence = GetSequence(playerID);
			if sequence == 6 then AddDigestion(playerID, "A", "TP:S6:PROD:" .. turn); end
			if sequence == 1 then AddDigestion(playerID, "A", "TP:S1:THEFT:" .. turn); end
			return;
		end
		lastError = tostring(failure or "ADD_PROGRESS_REJECTED");
	end
	Log("production settlement deferred player=" .. playerID .. " amount=" .. amount
		.. " reason=" .. lastError);
end

local function GetCivType(playerID)
	local config = PlayerConfigurations[playerID];
	return config ~= nil and config:GetCivilizationTypeName() or "";
end

local function TraitIsUniqueObject(traitType)
	for row in GameInfo.Units() do if row.TraitType == traitType then return true; end end
	for row in GameInfo.Buildings() do if row.TraitType == traitType then return true; end end
	for row in GameInfo.Districts() do if row.TraitType == traitType then return true; end end
	for row in GameInfo.Improvements() do if row.TraitType == traitType then return true; end end
	return false;
end

local function GetCivAbilityModifiers(civType)
	local result = {};
	for link in GameInfo.CivilizationTraits() do
		if link.CivilizationType == civType and not TraitIsUniqueObject(link.TraitType) then
			local trait = GameInfo.Traits[link.TraitType];
			if trait ~= nil and trait.Description ~= nil and trait.Description ~= "" then
				for tm in GameInfo.TraitModifiers() do
					if tm.TraitType == link.TraitType and GameInfo.Modifiers[tm.ModifierId] ~= nil then
						table.insert(result, tm.ModifierId);
					end
				end
			end
		end
	end
	table.sort(result);
	return result;
end

local function ApplyBorrowedAbility(playerID, civType)
	local player = Players[playerID];
	if civType == "" or civType == GetCivType(playerID) then
		Log("ability switch blocked player=" .. playerID .. " reason=NATIVE_OR_EMPTY_CIV");
		return false;
	end
	if player == nil or tostring(player:GetProperty(P.BorrowedCiv) or "") ~= "" then
		Log("ability choice rejected player=" .. playerID .. " reason=ALREADY_CHOSEN");
		return false;
	end
	local modifiers = GetCivAbilityModifiers(civType);
	if #modifiers == 0 then return false; end
	-- Persist the in-flight choice as well: a partial attach failure may retry
	-- this civilization only, and never stacks already attached modifiers.
	local pending = tostring(player:GetProperty("LOTM_TP_BORROW_PENDING_CIV") or "");
	if pending ~= "" and pending ~= civType then return false; end
	player:SetProperty("LOTM_TP_BORROW_PENDING_CIV", civType);
	local seen = {};
	for _, modifierID in ipairs(modifiers) do
		local key = "LOTM_TP_BORROW_APPLIED_" .. modifierID;
		if not seen[modifierID] and (player:GetProperty(key) or 0) ~= 1 then
			local ok, result = pcall(function() return player:AttachModifierByID(modifierID); end);
			if not ok or result == false then
				Log("ability choice failed player=" .. playerID .. " modifier=" .. modifierID);
				return false;
			end
			player:SetProperty(key, 1);
		end
		seen[modifierID] = true;
	end
	player:SetProperty(P.BorrowedCiv, civType);
	Log("ability switched player=" .. playerID .. " civ=" .. civType);
	return true;
end

local function ApplyAllAbilities(playerID)
	local player = Players[playerID];
	if player == nil then return; end
	if (player:GetProperty("LOTM_TP_ALL_ABILITIES_AUDIT_VERSION") or 0) >= 1 then
		local pending = tostring(player:GetProperty("LOTM_TP_ALL_ABILITIES_RETRY") or "");
		if pending == "" then return; end
		local remaining = {};
		local count = tonumber(player:GetProperty("LOTM_TP_ALL_ABILITIES_LOADED")) or 0;
		for modifierID in string.gmatch(pending, "[^,]+") do
			local ok, result = pcall(function() return player:AttachModifierByID(modifierID); end);
			if ok and result ~= false then
				player:SetProperty("LOTM_TP_ALL_APPLIED_" .. modifierID, 1);
				player:SetProperty("LOTM_TP_ALL_STATUS_" .. modifierID, "ATTACHED"); count = count + 1;
			else table.insert(remaining, modifierID); end
		end
		player:SetProperty("LOTM_TP_ALL_ABILITIES_RETRY", table.concat(remaining, ","));
		player:SetProperty("LOTM_TP_ALL_ABILITIES_LOADED", count);
		player:SetProperty("LOTM_TP_ALL_ABILITIES_ATTACHED", count == player:GetProperty("LOTM_TP_ALL_ABILITIES_TOTAL") and 1 or 0);
		return;
	end
	-- One migration for the old aggregate flag. Inspect actual instances before
	-- filling gaps, including the ability already borrowed at Sequence 2.
	local legacy = (player:GetProperty("LOTM_TP_ALL_ABILITIES_ATTACHED") or 0) == 1;
	local attached, inspected = {}, false;
	if GameEffects ~= nil and GameEffects.GetModifiers ~= nil
		and GameEffects.GetModifierDefinition ~= nil and GameEffects.GetModifierOwner ~= nil
		and GameEffects.GetObjectsPlayerId ~= nil then
		inspected = pcall(function()
			for _, id in ipairs(GameEffects.GetModifiers() or {}) do
				local def = GameEffects.GetModifierDefinition(id);
				local owner = GameEffects.GetModifierOwner(id);
				if def ~= nil and owner ~= nil and GameEffects.GetObjectsPlayerId(owner) == playerID then
					attached[def.Id] = true;
				end
			end
		end);
	end
	local seen = {};
	local complete = true;
	local retry = {};
	local total, loaded = 0, 0;
	local sources = PlayerManager.GetWasEverAliveMajors();
	if LOTM_MP_TurnSync.IsNetworkGame() then
		local ordered = {}; for _, source in ipairs(sources or {}) do table.insert(ordered, source); end
		table.sort(ordered, function(a,b) return a:GetID() < b:GetID(); end); sources = ordered;
	end
	for _, source in ipairs(sources or {}) do
		local sourceID = source:GetID();
		if sourceID ~= playerID and GetCivType(sourceID) ~= GetCivType(playerID) then
			for _, modifierID in ipairs(GetCivAbilityModifiers(GetCivType(sourceID))) do
				if not seen[modifierID] then
					seen[modifierID] = true; total = total + 1;
					local key = "LOTM_TP_ALL_APPLIED_" .. modifierID;
					local present = attached[modifierID] == true or (player:GetProperty(key) or 0) == 1
						or (not inspected and (player:GetProperty("LOTM_TP_BORROW_APPLIED_" .. modifierID) or 0) == 1);
					local status = present and "CONFIRMED" or "MISSING";
					if not present and legacy and not inspected then
						status = "LEGACY_UNVERIFIED";
					elseif not present then
						local ok, result = pcall(function() return player:AttachModifierByID(modifierID); end);
						present = ok and result ~= false;
						status = present and "ATTACHED" or "FAILED";
					end
					if present then loaded = loaded + 1; player:SetProperty(key, 1); else complete = false; end
					player:SetProperty("LOTM_TP_ALL_STATUS_" .. modifierID, status);
					if status == "FAILED" then table.insert(retry, modifierID); end
					Log("ability audit player=" .. playerID .. " civ=" .. GetCivType(sourceID)
						.. " modifier=" .. modifierID .. " status=" .. status);
				end
			end
		end
	end
	player:SetProperty("LOTM_TP_ALL_ABILITIES_ATTACHED", complete and 1 or 0);
	player:SetProperty("LOTM_TP_ALL_ABILITIES_AUDIT_VERSION", 1);
	player:SetProperty("LOTM_TP_ALL_ABILITIES_TOTAL", total);
	player:SetProperty("LOTM_TP_ALL_ABILITIES_RETRY", table.concat(retry, ","));
	player:SetProperty("LOTM_TP_ALL_ABILITIES_LOADED", loaded);
	Log("all abilities audited player=" .. playerID .. " loaded=" .. loaded .. " total=" .. total
		.. " inspected=" .. tostring(inspected));
end

local function ApplyReligionPressure(player, city, amount)
	local religion = player:GetReligion();
	local religionID = religion ~= nil and religion:GetReligionTypeCreated() or -1;
	local cityReligion = city ~= nil and city:GetReligion() or nil;
	if religionID == nil or religionID < 0 or cityReligion == nil
		or cityReligion.AddReligiousPressure == nil then return false; end
	return pcall(function() cityReligion:AddReligiousPressure(religionID, amount); end);
end

local function GetMissionarySpreadPressure()
	local missionary = GameInfo.Units["UNIT_MISSIONARY"];
	local strength = missionary ~= nil and tonumber(missionary.ReligiousStrength) or 100;
	return math.max(1, math.floor(strength or 100));
end

local function CompleteFaithTransfer(playerID, allMajors)
	local player = Players[playerID];
	if player == nil then return false; end
	local capital = player:GetCities():GetCapitalCity();
	if capital == nil then return false; end
	local religionID = player:GetReligion():GetReligionTypeCreated();
	if religionID == nil or religionID < 0 then return false; end
	local candidates = {};
	local owners = PlayerManager.GetAliveMajorIDs();
	for _, ownerID in ipairs(owners) do
		local owner = Players[ownerID];
		if owner ~= nil and owner:IsAlive() and owner:IsMajor() then
			for _, city in owner:GetCities():Members() do
				local cityReligion = city:GetReligion();
				if cityReligion ~= nil and cityReligion:GetMajorityReligion() ~= religionID then
					table.insert(candidates, city);
				end
			end
		end
	end
	local spreadPressure = GetMissionarySpreadPressure();
	local spreadsPerCity = 10;
	local function CityDistance(city)
		return Map.GetPlotDistance(capital:GetX(), capital:GetY(), city:GetX(), city:GetY());
	end
	table.sort(candidates, function(a,b)
		local da, db = CityDistance(a), CityDistance(b);
		if da == db then
			if a:GetOwner() == b:GetOwner() then return a:GetID() < b:GetID(); end
			return a:GetOwner() < b:GetOwner();
		end
		return da < db;
	end);
	local limit = allMajors and 5 or 1;
	local changed = 0;
	for index = 1, math.min(limit, #candidates) do
		local city = candidates[index];
		local pressure = spreadPressure;
		local appliedCount = 0;
		for _ = 1, spreadsPerCity do
			if ApplyReligionPressure(player, city, pressure) then appliedCount = appliedCount + 1; end
		end
		local applied = appliedCount == spreadsPerCity;
		if applied then
			changed = changed + 1;
			Log("faith transfer applied player=" .. tostring(playerID)
				.. " mode=" .. (allMajors and "II" or "I")
				.. " owner=" .. tostring(city:GetOwner()) .. " city=" .. tostring(city:GetID())
				.. " spreads=" .. tostring(spreadsPerCity)
				.. " pressurePerSpread=" .. tostring(pressure)
				.. " applied=" .. tostring(appliedCount));
		end
	end
	return changed > 0;
end

local function GiftCurrent(playerID, kind)
	local player = Players[playerID];
	if player == nil then return false; end
	if kind == "TECH" then
		local techs = player:GetTechs(); local current = techs:GetResearchingTech();
		if current == nil or current < 0 then player:SetProperty(P.PendingTech, 1); return false; end
		player:SetProperty(P.GiftGuardTech, 1);
		player:SetProperty(P.GiftGuardTechIndex, current);
		techs:SetResearchProgress(current, techs:GetResearchCost(current));
		player:SetProperty(P.PendingTech, 0); return true;
	else
		local culture = player:GetCulture(); local current = culture:GetProgressingCivic();
		if current == nil or current < 0 then player:SetProperty(P.PendingCivic, 1); return false; end
		player:SetProperty(P.GiftGuardCivic, 1);
		player:SetProperty(P.GiftGuardCivicIndex, current);
		culture:SetCulturalProgress(current, culture:GetCultureCost(current));
		player:SetProperty(P.PendingCivic, 0); return true;
	end
end

local function ProcessTurn(playerID)
	if not IsThief(playerID) then return; end
	local player = Players[playerID];
	local turn = Game.GetCurrentGameTurn();
	local networkGame = LOTM_MP_TurnSync ~= nil and LOTM_MP_TurnSync.IsNetworkGame ~= nil
		and LOTM_MP_TurnSync.IsNetworkGame() == true;
	if not networkGame then
		local lastTurn = tonumber(player:GetProperty(P.LastProcessedTurn) or -1) or -1;
		if lastTurn == turn then return; end
	player:SetProperty(P.LastProcessedTurn, turn);
	end
	CleanupTourismBurst(playerID, player, turn);
	ProbePlayer(playerID);
	-- Resolve a previously designated city before accruing this turn's other
	-- effects.  The transfer itself is authoritative and idempotently verified.
	local function ProcessParasite()
		local due = tonumber(player:GetProperty(P.ParasiteDueTurn) or -1) or -1;
		if due < 0 or due > turn then return; end
		local ownerID = tonumber(player:GetProperty(P.ParasiteOwner) or -1) or -1;
		local cityID = tonumber(player:GetProperty(P.ParasiteCity) or -1) or -1;
		local city = ownerID >= 0 and cityID >= 0 and CityManager.GetCity(ownerID, cityID) or nil;
		local valid = city ~= nil and city:GetOwner() == ownerID and ownerID ~= playerID;
		if valid then
			local owner = Players[ownerID];
			valid = owner ~= nil and owner:IsAlive();
		end
		if not valid then
			Log("parasite cancelled player=" .. playerID .. " owner=" .. ownerID
				.. " city=" .. cityID .. " reason=TARGET_INVALID");
			for _, key in ipairs({P.ParasiteOwner,P.ParasiteCity,P.ParasiteX,P.ParasiteY,P.ParasiteStartTurn,P.ParasiteDueTurn}) do player:SetProperty(key, nil); end
			return;
		end
		local ok, result = pcall(function() return CityManager.TransferCity(city, playerID); end);
		local transferred = ok and result ~= false;
		local owned = CityManager.GetCity(playerID, cityID);
		if transferred and owned ~= nil and owned:GetOwner() == playerID then
			player:SetProperty(P.LastParasiteCity, cityID);
			player:SetProperty(P.LastParasiteTurn, turn);
			if GetSequence(playerID) == 4 then AddDigestion(playerID, "A", "TP:S4:PARASITE:" .. cityID .. ":" .. turn, 3); end
			Log("parasite completed player=" .. playerID .. " owner=" .. ownerID
				.. " city=" .. cityID .. " due=" .. due .. " api=CityManager.TransferCity");
		else
			Log("parasite transfer failed player=" .. playerID .. " owner=" .. ownerID
				.. " city=" .. cityID .. " api=CityManager.TransferCity ok=" .. tostring(ok)
				.. " result=" .. tostring(result));
		end
		for _, key in ipairs({P.ParasiteOwner,P.ParasiteCity,P.ParasiteX,P.ParasiteY,P.ParasiteStartTurn,P.ParasiteDueTurn}) do player:SetProperty(key, nil); end
	end
	ProcessParasite();
	local sequence = GetSequence(playerID);
	local targetID, target = ResolveTarget(playerID);
	if sequence > 5 or target == nil then
		ClearKnowledgeYieldBonuses(playerID, player);
	end
	if sequence <= 6 then
		SyncProductionDebuff(playerID, target ~= nil and targetID or -1, target);
	else
		SyncProductionDebuff(playerID, -1, nil);
	end
	local theftOccurred = false;
	if target ~= nil then
		local gold = TransferGold(playerID, targetID, target); theftOccurred = gold > 0 or theftOccurred;
		if sequence == 9 and gold > 0 then AddDigestion(playerID, "A", "TP:S9:GOLD:" .. turn); end
		if sequence <= 6 then
			AccrueProduction(playerID, targetID, target);
		end
		if sequence <= 5 then
			local knowledge = TransferKnowledgeAndFaith(playerID, targetID, target); theftOccurred = knowledge > 0 or theftOccurred;
			if sequence == 5 and knowledge > 0 then AddDigestion(playerID, "A", "TP:S5:YIELDS:" .. turn); end
		end
	end
	if sequence <= 8 then
		ChangeFakeGold(player, sequence <= 4 and 40 or 20);
	end
	if sequence <= 7 then
		local last = tonumber(player:GetProperty(P.BoostTurn) or -999) or -999;
		if turn - last >= 2 and TriggerRandomBoost(playerID) then
			player:SetProperty(P.BoostTurn, turn);
			if sequence == 7 then AddDigestion(playerID, "A", "TP:S7:BOOST:" .. turn); end
		end
	end
	if sequence == 2 and tostring(player:GetProperty(P.BorrowedCiv) or "") ~= "" then
		AddDigestion(playerID, "A", "TP:S2:BORROW:" .. turn);
	elseif sequence <= 1 then
		ApplyAllAbilities(playerID);
		if sequence == 1 and theftOccurred then AddDigestion(playerID, "A", "TP:S1:THEFT:" .. turn); end
	end
	if sequence == 0 and player:GetProperty(P.FinalBranch) == "TECH_CIVIC" then
		if (player:GetProperty(P.PendingTech) or 0) == 1 then GiftCurrent(playerID, "TECH"); end
		if (player:GetProperty(P.PendingCivic) or 0) == 1 then GiftCurrent(playerID, "CIVIC"); end
	end
end

function LOTM_TP_RefreshSequenceState(playerID)
	if not IsThief(playerID) then return false; end
	local player = Players[playerID];
	local sequence = GetSequence(playerID);
	ProbePlayer(playerID);
	if sequence <= 3 then
		-- Sequence 3's special ability projects are sequence-gated, not
		-- digestion-gated.  Reconcile them once for old saves whose legacy
		-- marker says attached although the actual modifiers were lost.
		local repair = tonumber(player:GetProperty("LOTM_TP_SPECIAL_PROJECT_REPAIR_VERSION") or 0) or 0;
		if repair < 3 then
			local okFaith = pcall(function() player:AttachModifierByID("LOTM_TP_MOD_ALLOW_FAITH_TRANSFER"); end);
			local okCulture = pcall(function() player:AttachModifierByID("LOTM_TP_MOD_ALLOW_CULTURE_TRANSFER"); end);
			player:SetProperty("LOTM_TP_SPECIAL_I_ATTACHED", 1);
			player:SetProperty("LOTM_TP_SPECIAL_PROJECT_REPAIR_VERSION", 3);
			Log("sequence3 special projects reconciled player=" .. tostring(playerID)
				.. " faith=" .. tostring(okFaith) .. " culture=" .. tostring(okCulture));
		end
	end
	if sequence <= 1 then ApplyAllAbilities(playerID); end
	return true;
end

function LOTM_TP_OnPathSelected(playerID)
	if IsThief(playerID) then
		local player = Players[playerID];
		player:SetProperty(P.Target, -1);
		player:SetProperty(P.TargetChangedTurn, -999);
		player:SetProperty(P.FinalBranch, "NONE");
		ProbePlayer(playerID);
		LOTM_TP_RefreshSequenceState(playerID);
	end
end

local function OnSetTarget(playerID, parameters)
	if not IsThief(playerID) then return; end
	local targetID = tonumber(parameters ~= nil and parameters.TargetPlayerID or -1) or -1;
	local player = Players[playerID];
	local turn = Game.GetCurrentGameTurn();
	local changed = tonumber(player:GetProperty(P.TargetChangedTurn) or -999) or -999;
	if not IsLegalTarget(playerID, targetID) or turn - changed < TARGET_COOLDOWN then
		Log("target command rejected player=" .. playerID .. " target=" .. targetID);
		return;
	end
	player:SetProperty(P.Target, targetID);
	player:SetProperty(P.TargetChangedTurn, turn);
	Log("target selected player=" .. playerID .. " target=" .. targetID);
end

local function OnSetBorrowedAbility(playerID, parameters)
	if not IsThief(playerID) or GetSequence(playerID) ~= 2 then return; end
	if tostring(Players[playerID]:GetProperty(P.BorrowedCiv) or "") ~= "" then
		Log("ability choice rejected player=" .. playerID .. " reason=ALREADY_CHOSEN"); return;
	end
	local sourceID = tonumber(parameters ~= nil and parameters.SourcePlayerID or -1) or -1;
	if sourceID < 0 or sourceID == playerID then return; end
	local found = false;
	for _, source in ipairs(PlayerManager.GetWasEverAliveMajors()) do
		if source:GetID() == sourceID then found = true; break; end
	end
	if not found then return; end
	ApplyBorrowedAbility(playerID, GetCivType(sourceID));
end

local function OnChooseFinalBranch(playerID, parameters)
	if not IsThief(playerID) or GetSequence(playerID) ~= 0 then return; end
	local player = Players[playerID];
	if tostring(player:GetProperty(P.FinalBranch) or "NONE") ~= "NONE" then return; end
	local branch = tostring(parameters ~= nil and parameters.Branch or "");
	if branch ~= "TECH_CIVIC" and branch ~= "FAITH" and branch ~= "CULTURE" then return; end
	player:SetProperty(P.FinalBranch, branch);
	if branch == "FAITH" then player:AttachModifierByID("LOTM_TP_MOD_ALLOW_FAITH_TRANSFER_II"); end
	if branch == "CULTURE" then player:AttachModifierByID("LOTM_TP_MOD_ALLOW_CULTURE_TRANSFER_II"); end
	Log("final branch player=" .. playerID .. " branch=" .. branch);
end

-- The native deal remains an ordinary lump-sum Gold payment, so its displayed
-- value and AI valuation stay unchanged. After DiplomacyDealEnacted, this
-- synchronized command substitutes Counterfeit Gold first: refund the payer's
-- matching ordinary Gold and remove the same amount from the recipient. The AI
-- therefore receives no Counterfeit Gold and cannot store or convert it.
local function OnSettleFakeGoldDeal(playerID, parameters)
	if IsNetworkGame() or not IsThief(playerID) or GetSequence(playerID) > 8 then return; end
	local fromID = math.floor(tonumber(parameters ~= nil and parameters.FromPlayerID or -1) or -1);
	local toID = math.floor(tonumber(parameters ~= nil and parameters.ToPlayerID or -1) or -1);
	local amount = math.max(0, math.floor(tonumber(parameters ~= nil and parameters.Amount or 0) or 0));
	local incoming = math.max(0, math.floor(tonumber(parameters ~= nil and parameters.IncomingAmount or 0) or 0));
	local payerGoldBefore = tonumber(parameters ~= nil and parameters.PayerGoldBefore or nil);
	local recipientGoldBefore = tonumber(parameters ~= nil and parameters.RecipientGoldBefore or nil);
	local serial = tostring(parameters ~= nil and parameters.Serial or "");
	if fromID ~= playerID or toID < 0 or toID == fromID or amount <= 0
		or payerGoldBefore == nil or recipientGoldBefore == nil
		or #serial < 1 or #serial > 120 or string.match(serial, "^[%w_:%-]+$") == nil then
		Log("fake gold deal rejected player=" .. tostring(playerID) .. " reason=BAD_REQUEST");
		return;
	end
	local payer, recipient = Players[fromID], Players[toID];
	local payerTreasury = payer ~= nil and payer:GetTreasury() or nil;
	local recipientTreasury = recipient ~= nil and recipient:GetTreasury() or nil;
	if payer == nil or recipient == nil or payerTreasury == nil or recipientTreasury == nil then return; end
	local settledValue = payer:GetProperty(P.LastFakeGoldSettlement);
	if tostring(settledValue or "") == serial then return; end
	local payerGoldAfterDeal = tonumber(payerTreasury:GetGoldBalance()) or payerGoldBefore;
	local recipientGoldAfterDeal = tonumber(recipientTreasury:GetGoldBalance()) or recipientGoldBefore;
	local expectedPayer = payerGoldBefore - amount + incoming;
	local expectedRecipient = recipientGoldBefore + amount - incoming;
	if math.abs(payerGoldAfterDeal - expectedPayer) >= 0.001
		or math.abs(recipientGoldAfterDeal - expectedRecipient) >= 0.001 then
		Log("fake gold deal pending player=" .. tostring(playerID) .. " serial=" .. serial
			.. " reason=NATIVE_GOLD_DELTA_MISMATCH payer=" .. tostring(payerGoldAfterDeal)
			.. "/" .. tostring(expectedPayer) .. " recipient=" .. tostring(recipientGoldAfterDeal)
			.. "/" .. tostring(expectedRecipient));
		return;
	end
	local fakeBefore = GetFakeGold(payer);
	local substitute = math.min(fakeBefore, amount);
	if substitute <= 0 then
		payer:SetProperty(P.LastFakeGoldSettlement, serial);
		return;
	end
	local ok, failure = pcall(function()
		if not ChangeFakeGold(payer, -substitute) then error("FAKE_GOLD_DEBIT_REJECTED"); end
		payerTreasury:ChangeGoldBalance(substitute);
		recipientTreasury:ChangeGoldBalance(-substitute);
		if GetFakeGold(payer) ~= fakeBefore - substitute
			or math.abs((tonumber(payerTreasury:GetGoldBalance()) or 0)
				- (payerGoldAfterDeal + substitute)) >= 0.001
			or math.abs((tonumber(recipientTreasury:GetGoldBalance()) or 0)
				- (recipientGoldAfterDeal - substitute)) >= 0.001 then
			error("SETTLEMENT_DELTA_MISMATCH");
		end
	end);
	if not ok then
		local rollbackOK = true;
		local fakeNow = GetFakeGold(payer);
		if not ChangeFakeGold(payer, fakeBefore - fakeNow) or GetFakeGold(payer) ~= fakeBefore then
			rollbackOK = false;
		end
		local payerNow = tonumber(payerTreasury:GetGoldBalance()) or payerGoldAfterDeal;
		local payerRestoreOK = pcall(function()
			payerTreasury:ChangeGoldBalance(payerGoldAfterDeal - payerNow);
		end);
		if not payerRestoreOK or math.abs((tonumber(payerTreasury:GetGoldBalance()) or payerGoldAfterDeal)
			- payerGoldAfterDeal) >= 0.001 then rollbackOK = false; end
		local recipientNow = tonumber(recipientTreasury:GetGoldBalance()) or recipientGoldAfterDeal;
		local recipientRestoreOK = pcall(function()
			recipientTreasury:ChangeGoldBalance(recipientGoldAfterDeal - recipientNow);
		end);
		if not recipientRestoreOK or math.abs((tonumber(recipientTreasury:GetGoldBalance()) or recipientGoldAfterDeal)
			- recipientGoldAfterDeal) >= 0.001 then rollbackOK = false; end
		if not rollbackOK then
			-- Do not retry a partially restored transaction: repeating it could amplify
			-- an engine-level treasury failure. Preserve the serial and emit a fatal log.
			payer:SetProperty(P.LastFakeGoldSettlement, serial);
		end
		Log("fake gold deal rolled back player=" .. tostring(playerID) .. " serial=" .. serial
			.. " rollbackOK=" .. tostring(rollbackOK) .. " failure=" .. tostring(failure));
		return;
	end
	payer:SetProperty(P.LastFakeGoldSettlement, serial);
	if GetSequence(playerID) == 8 then
		AddDigestion(playerID, "A", "TP:S8:DEAL:" .. serial);
	end
	Log("fake gold deal settled payer=" .. tostring(fromID) .. " recipient=" .. tostring(toID)
		.. " negotiatedGold=" .. tostring(amount) .. " fakeSpent=" .. tostring(substitute)
		.. " trueGoldSpent=" .. tostring(amount - substitute)
		.. " aiGoldReceived=" .. tostring(amount - substitute) .. " serial=" .. serial);
end

local function OnDesignateCity(playerID, parameters)
	if not IsThief(playerID) or GetSequence(playerID) > 4 then return; end
	local player = Players[playerID];
	if player == nil or (player:GetProperty(P.CityTransferSupported) or 0) ~= 1 then
		Log("city designation rejected player=" .. tostring(playerID) .. " reason=LOSSLESS_TRANSFER_GATE_CLOSED");
		return;
	end
	local turn = Game.GetCurrentGameTurn();
	local pendingDue = tonumber(player:GetProperty(P.ParasiteDueTurn) or -1) or -1;
	if pendingDue >= turn then
		Log("city designation rejected player=" .. playerID .. " reason=PARASITE_ALREADY_PENDING");
		return;
	end
	local unitID = math.floor(tonumber(parameters ~= nil and parameters.UnitID or -1) or -1);
	local x = math.floor(tonumber(parameters ~= nil and parameters.X or -1) or -1);
	local y = math.floor(tonumber(parameters ~= nil and parameters.Y or -1) or -1);
	local unit = unitID >= 0 and UnitManager.GetUnit(playerID, unitID) or nil;
	local unitInfo = unit ~= nil and GameInfo.Units[unit:GetType()] or nil;
	if unit == nil or unitInfo == nil or unitInfo.UnitType ~= HERO then
		Log("city designation rejected player=" .. playerID .. " reason=INVALID_HOLDER"); return;
	end
	if unit:GetX() ~= x or unit:GetY() ~= y then x, y = unit:GetX(), unit:GetY(); end
	local plot = Map.GetPlot(x, y);
	local cityOwner = plot ~= nil and tonumber(plot:GetOwner() or -1) or -1;
	local city = plot ~= nil and cityOwner >= 0 and cityOwner ~= playerID
		and Cities.GetPlotPurchaseCity(plot) or nil;
	if city == nil or city:GetOwner() ~= cityOwner then
		Log("city designation rejected player=" .. playerID .. " owner=" .. cityOwner
			.. " reason=NO_OTHER_TERRITORY_CITY"); return;
	end
	player:SetProperty(P.ParasiteOwner, cityOwner);
	player:SetProperty(P.ParasiteCity, city:GetID());
	player:SetProperty(P.ParasiteX, x);
	player:SetProperty(P.ParasiteY, y);
	player:SetProperty(P.ParasiteStartTurn, turn);
	player:SetProperty(P.ParasiteDueTurn, turn + 5);
	Log("parasite designated player=" .. playerID .. " owner=" .. cityOwner
		.. " city=" .. city:GetID() .. " start=" .. turn .. " due=" .. (turn + 5));
end

local function ApplyResearchCompleted(playerID, techIndex, isCanceled, capturedGift)
	if isCanceled or not IsThief(playerID) then return; end
	local player = Players[playerID];
	if capturedGift == true
		or (capturedGift == nil and (player:GetProperty(P.GiftGuardTech) or 0) == 1) then
		player:SetProperty(P.GiftGuardTech, 0);
		player:SetProperty(P.GiftGuardTechIndex, nil);
		return;
	end
	if GetSequence(playerID) ~= 0 or player:GetProperty(P.FinalBranch) ~= "TECH_CIVIC" then return; end
	local count = (player:GetProperty(P.TechNatural) or 0) + 1; player:SetProperty(P.TechNatural, count);
	if (player:GetProperty(P.TechBurst) or 0) == 1 then GiftCurrent(playerID, "TECH");
	elseif count >= 3 then player:SetProperty(P.TechBurst, 1); GiftCurrent(playerID, "TECH"); end
end

local function ApplyCivicCompleted(playerID, civicIndex, isCanceled, capturedGift)
	if isCanceled or not IsThief(playerID) then return; end
	local player = Players[playerID];
	if capturedGift == true
		or (capturedGift == nil and (player:GetProperty(P.GiftGuardCivic) or 0) == 1) then
		player:SetProperty(P.GiftGuardCivic, 0);
		player:SetProperty(P.GiftGuardCivicIndex, nil);
		return;
	end
	if GetSequence(playerID) ~= 0 or player:GetProperty(P.FinalBranch) ~= "TECH_CIVIC" then return; end
	local count = (player:GetProperty(P.CivicNatural) or 0) + 1; player:SetProperty(P.CivicNatural, count);
	if (player:GetProperty(P.CivicBurst) or 0) == 1 then GiftCurrent(playerID, "CIVIC");
	elseif count >= 3 then player:SetProperty(P.CivicBurst, 1); GiftCurrent(playerID, "CIVIC"); end
end

local function ApplyCityProjectCompleted(playerID, cityID, projectID, eventTurn)
	if not IsThief(playerID) then return; end
	local row = GameInfo.Projects[projectID];
	if row == nil then return; end
	local advance = POTIONS[row.ProjectType];
	if advance ~= nil then
		LOTM_RP_State.AdvanceSequence(playerID, advance[1], advance[2], true);
		return;
	end
	-- Project visibility and old queued production do not confer a current
	-- ability. Revalidate both inherited Sequence 3 projects and the mutually
	-- exclusive Sequence 0 branch before applying any completion reward.
	local sequence = GetSequence(playerID);
	local branch = tostring(Players[playerID]:GetProperty(P.FinalBranch) or "NONE");
	if row.ProjectType == "PROJECT_LOTM_TP_FAITH_TRANSFER_II" then
		if sequence ~= 0 or branch ~= "FAITH" then return; end
	elseif row.ProjectType == "PROJECT_LOTM_TP_CULTURE_TRANSFER_II" then
		if sequence ~= 0 or branch ~= "CULTURE" then return; end
	elseif sequence > 3 then
		return;
	end
	if row.ProjectType == "PROJECT_LOTM_TP_FAITH_TRANSFER" then
		if CompleteFaithTransfer(playerID, false) and GetSequence(playerID) == 3 then
			local identityTurn = eventTurn ~= nil and eventTurn or Game.GetCurrentGameTurn();
			AddDigestion(playerID, "A", "TP:S3:FAITH:" .. identityTurn);
			AddDigestion(playerID, "B", "TP:S3:FAITH2:" .. identityTurn);
		end
	elseif row.ProjectType == "PROJECT_LOTM_TP_FAITH_TRANSFER_II" then
		CompleteFaithTransfer(playerID, true);
	elseif row.ProjectType == "PROJECT_LOTM_TP_CULTURE_TRANSFER" then
		local success = ApplyTourismBurst(playerID, "LOTM_TP_TOURISM_BURST_I", 2500);
		if success and GetSequence(playerID) == 3 then
			local identityTurn = eventTurn ~= nil and eventTurn or Game.GetCurrentGameTurn();
			AddDigestion(playerID, "A", "TP:S3:CULTURE:" .. identityTurn);
			AddDigestion(playerID, "B", "TP:S3:CULTURE2:" .. identityTurn);
		end
	elseif row.ProjectType == "PROJECT_LOTM_TP_CULTURE_TRANSFER_II" then
		ApplyTourismBurst(playerID, "LOTM_TP_TOURISM_BURST_II", 9500);
	end
end

local function QueueNetworkEvent(kind, playerID, objectID, cityID, capturedGift)
	local normalizedPlayerID=tonumber(playerID); local normalizedObjectID=tonumber(objectID);
	if normalizedPlayerID==nil or normalizedObjectID==nil then return; end
	local turn=Game.GetCurrentGameTurn(); local normalizedCityID=tonumber(cityID) or -1;
	local key=table.concat({turn,kind,normalizedPlayerID,normalizedObjectID,normalizedCityID,capturedGift==true and 1 or 0},":");
	if pendingNetworkEventKeys[key]~=nil then return; end
	local entry={QueuedTurn=turn,Kind=kind,PlayerID=normalizedPlayerID,ObjectID=normalizedObjectID,
		CityID=normalizedCityID,CapturedGift=capturedGift==true,Key=key};
	pendingNetworkEvents[#pendingNetworkEvents+1]=entry; pendingNetworkEventKeys[key]=entry;
end

local function OnResearchCompleted(playerID,techIndex,isCanceled)
	if not LOTM_MP_TurnSync.IsNetworkGame() then ApplyResearchCompleted(playerID,techIndex,isCanceled,nil); return; end
	if isCanceled or not IsThief(playerID) then return; end
	local player=Players[playerID];
	local guardIndex=player~=nil and tonumber(player:GetProperty(P.GiftGuardTechIndex)) or nil;
	local capturedGift=player~=nil and (player:GetProperty(P.GiftGuardTech) or 0)==1
		and (guardIndex==nil or guardIndex==tonumber(techIndex));
	QueueNetworkEvent("RESEARCH",playerID,techIndex,-1,capturedGift);
end

local function OnCivicCompleted(playerID,civicIndex,isCanceled)
	if not LOTM_MP_TurnSync.IsNetworkGame() then ApplyCivicCompleted(playerID,civicIndex,isCanceled,nil); return; end
	if isCanceled or not IsThief(playerID) then return; end
	local player=Players[playerID];
	local guardIndex=player~=nil and tonumber(player:GetProperty(P.GiftGuardCivicIndex)) or nil;
	local capturedGift=player~=nil and (player:GetProperty(P.GiftGuardCivic) or 0)==1
		and (guardIndex==nil or guardIndex==tonumber(civicIndex));
	QueueNetworkEvent("CIVIC",playerID,civicIndex,-1,capturedGift);
end

local function OnCityProjectCompleted(playerID,cityID,projectID)
	if not LOTM_MP_TurnSync.IsNetworkGame() then ApplyCityProjectCompleted(playerID,cityID,projectID,nil); return; end
	local row=GameInfo.Projects[projectID];
	if not IsThief(playerID) or row==nil or (POTIONS[row.ProjectType]==nil
		and row.ProjectType~="PROJECT_LOTM_TP_FAITH_TRANSFER"
		and row.ProjectType~="PROJECT_LOTM_TP_FAITH_TRANSFER_II"
		and row.ProjectType~="PROJECT_LOTM_TP_CULTURE_TRANSFER"
		and row.ProjectType~="PROJECT_LOTM_TP_CULTURE_TRANSFER_II") then return; end
	QueueNetworkEvent("PROJECT",playerID,projectID,cityID,false);
end

local function ProcessNetworkEvents(playerID)
	if not LOTM_MP_TurnSync.IsNetworkGame() or not LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID) then return; end
	local currentTurn=Game.GetCurrentGameTurn(); local ready={}; local waiting={};
	for _,entry in ipairs(pendingNetworkEvents) do
		if entry.QueuedTurn<currentTurn then ready[#ready+1]=entry; else waiting[#waiting+1]=entry; end
	end
	pendingNetworkEvents=waiting;
	local priority={RESEARCH=1,CIVIC=2,PROJECT=3};
	table.sort(ready,function(a,b)
		if a.QueuedTurn~=b.QueuedTurn then return a.QueuedTurn<b.QueuedTurn; end
		if a.PlayerID~=b.PlayerID then return a.PlayerID<b.PlayerID; end
		if priority[a.Kind]~=priority[b.Kind] then return priority[a.Kind]<priority[b.Kind]; end
		if a.ObjectID~=b.ObjectID then return a.ObjectID<b.ObjectID; end
		return a.CityID<b.CityID;
	end);
	for _,entry in ipairs(ready) do
		if pendingNetworkEventKeys[entry.Key]==entry then pendingNetworkEventKeys[entry.Key]=nil; end
		if entry.Kind=="RESEARCH" then ApplyResearchCompleted(entry.PlayerID,entry.ObjectID,false,entry.CapturedGift);
		elseif entry.Kind=="CIVIC" then ApplyCivicCompleted(entry.PlayerID,entry.ObjectID,false,entry.CapturedGift);
		else ApplyCityProjectCompleted(entry.PlayerID,entry.CityID,entry.ObjectID,entry.QueuedTurn); end
	end
end

local function OnSynchronizedTurn(playerID,first)
	if first==false then return; end
	ProcessNetworkEvents(playerID); ProcessTurn(playerID);
end

local function Initialize()
	if IsRescueMode() then Log("disabled rescue mode"); return; end
	LOTM_MP_TurnSync.Add(OnSynchronizedTurn,"Thief");
	Events.ResearchCompleted.Add(OnResearchCompleted);
	Events.CivicCompleted.Add(OnCivicCompleted);
	Events.CityProjectCompleted.Add(OnCityProjectCompleted);
	GameEvents.LOTM_TP_Command_SetTarget.Add(OnSetTarget);
	GameEvents.LOTM_TP_Command_SetBorrowedAbility.Add(OnSetBorrowedAbility);
	GameEvents.LOTM_TP_Command_ChooseFinalBranch.Add(OnChooseFinalBranch);
	GameEvents.LOTM_TP_Command_SettleProduction.Add(OnSettleProduction);
	GameEvents.LOTM_TP_Command_SettleFakeGoldDeal.Add(OnSettleFakeGoldDeal);
	GameEvents.LOTM_TP_Command_DesignateCity.Add(OnDesignateCity);
	local function RefreshThiefStartup()
		local playerIDs={};
		local thiefFound = false;
		for _, playerID in ipairs(PlayerManager.GetAliveMajorIDs() or {}) do playerIDs[#playerIDs+1]=playerID; end
		table.sort(playerIDs);
		for _, playerID in ipairs(playerIDs) do
			ClearLegacyTradeCarrier(playerID);
			if IsThief(playerID) then
				thiefFound = true;
				ProbePlayer(playerID);
				-- Use the shared lifecycle refresh on load so old saves restore
				-- both pathway abilities and any unlocked city project modifier.
				LOTM_RP_State.RefreshSequenceState(playerID);
			end
		end
		Log("startup refresh complete players=" .. tostring(#playerIDs)
			.. " thiefFound=" .. tostring(thiefFound));
		return thiefFound;
	end
	-- Restored Properties must be read at a Gameplay turn boundary. A new game
	-- without a selected Thief is a successful startup, not a retry condition.
	-- Never migrate/refresh from the high-frequency local core-publish event.
	if LOTM_MP_TurnSync.IsNetworkGame() then
		LOTM_MP_TurnSync.RunStartup(RefreshThiefStartup,"Thief");
	else
		local startupDone = false;
		LOTM_MP_TurnSync.AddSynchronized(function(playerID, first)
			if startupDone or first == false or Players[playerID] == nil then return; end
			local ids = PlayerManager.GetAliveMajorIDs() or {};
			if #ids == 0 then return; end
			for _, id in ipairs(ids) do if Players[id] == nil then return; end end
			-- Close the gate before mutating state, including callbacks from native APIs.
			startupDone = true;
			RefreshThiefStartup();
			Log("startup refresh committed source=SYNCHRONIZED_PLAYER_TURN_STARTED");
		end,"ThiefLoad");
	end
	Log("initialized probeVersion=" .. PROBE_VERSION);
end

Initialize();
-- END POST_RC241_NEW MODULE: Scripts/LOTM_TP_Thief.lua
end;

m_mp241Loaders["LOTM_UnitAddedPerf"] = function()
-- BEGIN POST_RC241_DELTA MODULE: Scripts/LOTM_UnitAddedPerf.lua
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("MP.LOTM_UnitAddedPerf","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"MP.LOTM_UnitAddedPerf","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"MP.LOTM_UnitAddedPerf","GameEvents");
-- END RC342 STARTUP TRACE

-- Diagnostic-only timing for UnitAddedToMap handlers and bounded sections.
-- The local clock affects only in-memory reports and print output.  It never
-- writes synchronized Properties, consumes random numbers, or changes results.
LOTM_UnitAddedPerf={Stats={},Order={},Events=0,FirstTurnReported=false,Enabled=true,Sections={},SectionOrder={},SectionEnabled=true,TurnStats={}};

local m_timerName="LuaFallback";
local m_now=os.clock;
if Automation~=nil and Automation.GetTime~=nil then
 local candidate=Automation.GetTime;
 local ok,sample=pcall(candidate);
 if ok and type(sample)=="number" then m_timerName="Automation.GetTime"; m_now=candidate; end
end
local function PerfNow() return m_now(); end

function LOTM_UnitAddedPerf.MeasureTurn(label,callback,playerID,isFirstTimeThisTurn)
 local started=PerfNow();
 callback(playerID,isFirstTimeThisTurn);
 local elapsed=(PerfNow()-started)*1000;
 local name=tostring(label or "UNNAMED"); local stat=LOTM_UnitAddedPerf.TurnStats[name];
 if stat==nil then stat={Calls=0,TotalMs=0,MaxMs=0}; LOTM_UnitAddedPerf.TurnStats[name]=stat; end
 stat.Calls=stat.Calls+1; stat.TotalMs=stat.TotalMs+elapsed; if elapsed>stat.MaxMs then stat.MaxMs=elapsed; end
 -- Keep normal turns quiet while preserving every measurable hot path. The
 -- shipped clock has millisecond granularity, so sub-millisecond zeroes add
 -- noise without helping diagnosis.
 if elapsed>=1 then
  print(string.format("[LOTM_PERF][Turn] timer=%s turn=%s player=%s module=%s ms=%.3f",m_timerName,tostring(Game~=nil and Game.GetCurrentGameTurn~=nil and Game.GetCurrentGameTurn() or -1),tostring(playerID),name,elapsed));
 end
end

local function EnsureSection(name)
 local stat=LOTM_UnitAddedPerf.Sections[name];
 if stat==nil then
  stat={Calls=0,TotalMs=0,MaxMs=0,Items=0};
  LOTM_UnitAddedPerf.Sections[name]=stat;
  LOTM_UnitAddedPerf.SectionOrder[#LOTM_UnitAddedPerf.SectionOrder+1]=name;
 end
 return stat;
end

function LOTM_UnitAddedPerf.Wrap(name,callback)
 local stat={Calls=0,TotalMs=0,MaxMs=0};
 LOTM_UnitAddedPerf.Stats[name]=stat;
 LOTM_UnitAddedPerf.Order[#LOTM_UnitAddedPerf.Order+1]=name;
 return function(playerID,unitID,x,y)
  if not LOTM_UnitAddedPerf.Enabled then callback(playerID,unitID,x,y); return; end
  local started=PerfNow(); callback(playerID,unitID,x,y);
  local elapsed=(PerfNow()-started)*1000;
  stat.Calls=stat.Calls+1; stat.TotalMs=stat.TotalMs+elapsed;
  if elapsed>stat.MaxMs then stat.MaxMs=elapsed; end
 end
end

function LOTM_UnitAddedPerf.Report(reason)
 for _,name in ipairs(LOTM_UnitAddedPerf.Order) do
  local stat=LOTM_UnitAddedPerf.Stats[name];
  local average=stat.Calls>0 and stat.TotalMs/stat.Calls or 0;
  print(string.format("[LOTM_PERF][UnitAdded] timer=%s reason=%s events=%d module=%s calls=%d totalMs=%.3f avgMs=%.3f maxMs=%.3f",m_timerName,tostring(reason),LOTM_UnitAddedPerf.Events,name,stat.Calls,stat.TotalMs,average,stat.MaxMs));
 end
end

function LOTM_UnitAddedPerf.BeginSection()
 if not LOTM_UnitAddedPerf.SectionEnabled then return nil; end
 return PerfNow();
end

-- Diagnostic-only elapsed time for callers that need one immediate structured
-- log line.  The returned value must never drive synchronized gameplay state.
function LOTM_UnitAddedPerf.ElapsedSince(started)
 if started==nil then return 0; end
 return math.max(0,(PerfNow()-started)*1000);
end

function LOTM_UnitAddedPerf.EndSection(name,started,items)
 if not LOTM_UnitAddedPerf.SectionEnabled or started==nil then return; end
 local elapsed=(PerfNow()-started)*1000;
 local stat=EnsureSection(name);
 stat.Calls=stat.Calls+1; stat.TotalMs=stat.TotalMs+elapsed; stat.Items=stat.Items+(tonumber(items) or 0);
 if elapsed>stat.MaxMs then stat.MaxMs=elapsed; end
end

function LOTM_UnitAddedPerf.MarkSection(name,items)
 if not LOTM_UnitAddedPerf.SectionEnabled then return; end
 local stat=EnsureSection(name);
 stat.Calls=stat.Calls+1; stat.Items=stat.Items+(tonumber(items) or 0);
end

function LOTM_UnitAddedPerf.ReportSections(reason)
 for _,name in ipairs(LOTM_UnitAddedPerf.SectionOrder) do
  local stat=LOTM_UnitAddedPerf.Sections[name];
  local average=stat.Calls>0 and stat.TotalMs/stat.Calls or 0;
  print(string.format("[LOTM_PERF][Section] timer=%s reason=%s section=%s calls=%d items=%d totalMs=%.3f avgMs=%.3f maxMs=%.3f",m_timerName,tostring(reason),name,stat.Calls,stat.Items,stat.TotalMs,average,stat.MaxMs));
 end
end

function LOTM_UnitAddedPerf.EventCompleted()
 if LOTM_UnitAddedPerf.Enabled then LOTM_UnitAddedPerf.Events=LOTM_UnitAddedPerf.Events+1; end
end

print("[LOTM_PERF][UnitAdded] probe loaded timer="..m_timerName.." report=firstPlayerTurn stateWrites=false random=false");
-- END POST_RC241_DELTA MODULE: Scripts/LOTM_UnitAddedPerf.lua
end;

m_mp241Loaders["LOTM_WORLD_Barbarians"] = function()
-- BEGIN POST_RC241_DELTA MODULE: Scripts/LOTM_WORLD_Barbarians.lua
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("MP.LOTM_WORLD_Barbarians","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"MP.LOTM_WORLD_Barbarians","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"MP.LOTM_WORLD_Barbarians","GameEvents");
-- END RC342 STARTUP TRACE

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
-- END POST_RC241_DELTA MODULE: Scripts/LOTM_WORLD_Barbarians.lua
end;

m_mp241Loaders["LOTM_WORLD_Churches"] = function()
-- BEGIN RC241 MODULE: Scripts/LOTM_WORLD_Churches.lua
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("MP.LOTM_WORLD_Churches","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"MP.LOTM_WORLD_Churches","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"MP.LOTM_WORLD_Churches","GameEvents");
-- END RC342 STARTUP TRACE

-- rc.83 synchronized virtual churches.  There are deliberately no Minor players.
LOTM_WORLD_Churches = LOTM_WORLD_Churches or {};

local CHURCHES={
 FOOL={Path="Fool",Name="LOC_LOTM_CHURCH_FOOL_NAME"},
 NIGHT={Path="Darkness",Name="LOC_LOTM_CHURCH_NIGHT_NAME"},
 STORM={Path="Tyrant",Name="LOC_LOTM_CHURCH_STORM_NAME"}
};
local ORDER={"FOOL","NIGHT","STORM"};
local QUEST_TIERS={6,10,15};
local TARGET_LEVEL={[6]=2,[10]=1,[15]=0};
local DURATION={[6]=10,[10]=12,[15]=15};
local ARTIFACT_CHANCE={[6]=30,[10]=35,[15]=40};
local STATE={LOCKED="LOCKED",PENDING="PENDING_TARGET",ACTIVE="ACTIVE",SELF="COMPLETED_SELF",ASSIST="COMPLETED_ASSIST"};
local PREFIX="LOTM_CHURCH_";
local COMMAND="LOTM_WORLD_Churches_SendEnvoys";
local REWARD_NOTIFICATIONS={FOOL=NotificationTypes.USER_DEFINED_1,NIGHT=NotificationTypes.USER_DEFINED_2,STORM=NotificationTypes.USER_DEFINED_3};
local NIGHT_ENEMY_ABILITIES={
 "ABILITY_LOTM_CHURCH_NIGHT_ENEMY_COMBAT_5",
 "ABILITY_LOTM_CHURCH_NIGHT_ENEMY_COMBAT_10",
 "ABILITY_LOTM_CHURCH_NIGHT_ENEMY_COMBAT_20",
 "ABILITY_LOTM_CHURCH_NIGHT_ENEMY_MOVE_1",
 "ABILITY_LOTM_CHURCH_NIGHT_ENEMY_MOVE_2"
};
local NIGHT_HOME_ABILITIES={
 "ABILITY_LOTM_CHURCH_NIGHT_HOME_PERM_5",
 "ABILITY_LOTM_CHURCH_NIGHT_HOME_PERM_10",
 "ABILITY_LOTM_CHURCH_NIGHT_HOME_BLESS_7",
 "ABILITY_LOTM_CHURCH_NIGHT_HOME_BLESS_12",
 "ABILITY_LOTM_CHURCH_NIGHT_HOME_BLESS_15",
 "ABILITY_LOTM_CHURCH_NIGHT_HOME_BLESS_20",
 "ABILITY_LOTM_CHURCH_NIGHT_HOME_BLESS_25",
 "ABILITY_LOTM_CHURCH_NIGHT_HOME_BLESS_40"
};
local FOOL_ALL_SIGHT_ABILITIES={
 "ABILITY_LOTM_CHURCH_FOOL_ALL_SIGHT_1",
 "ABILITY_LOTM_CHURCH_FOOL_ALL_SIGHT_2",
 "ABILITY_LOTM_CHURCH_FOOL_ALL_SIGHT_3",
 "ABILITY_LOTM_CHURCH_FOOL_ALL_SIGHT_4",
 "ABILITY_LOTM_CHURCH_FOOL_ALL_SIGHT_5"
};
local FOOL_RECON_SIGHT_ABILITY="ABILITY_LOTM_CHURCH_FOOL_RECON_SIGHT_1";
local RefreshNightHomeCombat=nil;
local RefreshFoolSight=nil;
local RefreshAllNightEnemyPenalties=nil;

local function Log(s) print("[LOTM_WORLD][Churches] "..tostring(s)); end
local function Player(id) local p=Players[id]; return p~=nil and p:IsAlive() and p:IsMajor() and p or nil; end
local function N(o,k,d) return LOTM_WORLD_State.NumberProperty(o,k,d); end
local function K(church,suffix) return PREFIX..church.."_"..suffix; end
local function QK(church,tier,suffix) return K(church,"QUEST_"..tier.."_"..suffix); end
local function ValidChurch(church) return type(church)=="string" and CHURCHES[church]~=nil; end
local function RescueActive() return LOTM_WORLD_State.NumberGameProperty("LOTM_RESCUE_MODE",0)==1; end
local function CurrentPlayerTurn(p) return N(p,"LOTM_WORLD_PLAYER_TURN",0); end
local function Attach(p,id)
 if p==nil then return false; end
 if GameInfo.Modifiers[id]~=nil then p:AttachModifierByID(id); return true; end
 local prefix=id.."__"; local found={}; for row in GameInfo.Modifiers() do if string.sub(row.ModifierId,1,#prefix)==prefix then table.insert(found,row.ModifierId); end end
 table.sort(found); for _,modifierID in ipairs(found) do p:AttachModifierByID(modifierID); end
 if #found==0 then Log("WARNING missing modifier bundle "..tostring(id)); return false; end return true;
end

function LOTM_WORLD_Churches.GetEnvoys(playerID,church)
 local p=Player(playerID); if p==nil or not ValidChurch(church) then return 0; end
 return math.max(0,N(p,K(church,"ENVOYS"),0));
end

local function SetQuestState(p,church,tier,value)
 p:SetProperty(QK(church,tier,"STATE"),value);
end

local function QuestState(p,church,tier)
 return tostring(p:GetProperty(QK(church,tier,"STATE")) or STATE.LOCKED);
end

local function NearestCityDistance(p,plot)
 local best=nil;
 for _,city in p:GetCities():Members() do
  local distance=Map.GetPlotDistance(city:GetX(),city:GetY(),plot:GetX(),plot:GetY());
  if best==nil or distance<best then best=distance; end
 end
 return best or 999999;
end

local function RevealTarget(p,plot)
 local visibility=PlayersVisibility[p:GetID()]; if visibility==nil or plot==nil then return; end
 local plots={plot}; for direction=0,5 do local adjacent=Map.GetAdjacentPlot(plot:GetX(),plot:GetY(),direction); if adjacent~=nil then table.insert(plots,adjacent); end end
 for _,candidate in ipairs(plots) do if not visibility:IsRevealed(candidate:GetX(),candidate:GetY()) then
  -- Touch visibility once to mark the plot explored, then release the live
  -- sight count immediately; the oracle must not grant permanent vision.
  visibility:ChangeVisibilityCount(candidate:GetIndex(),1); visibility:ChangeVisibilityCount(candidate:GetIndex(),-1);
 end end
end

local function CandidateBand(distance)
 if distance<=20 then return 1; elseif distance<=30 then return 2; end return 3;
end

local function FindTarget(p,tier)
 local level=TARGET_LEVEL[tier]; local candidates={};
 local campType=GameInfo.Improvements.IMPROVEMENT_BARBARIAN_CAMP.Index;
 for index=0,Map.GetPlotCount()-1 do
  local plot=Map.GetPlotByIndex(index);
  if plot:GetImprovementType()==campType and N(plot,"LOTM_PP_WORKSHOP_IS_WORKSHOP",0)==1 and N(plot,"LOTM_PP_WORKSHOP_LEVEL",2)==level then
   local distance=NearestCityDistance(p,plot); table.insert(candidates,{Kind="WORKSHOP",Id=index,Plot=plot,Distance=distance,Band=CandidateBand(distance)});
  end
 end
 for serial=1,LOTM_WORLD_State.NumberGameProperty("LOTM_WORLD_MONSTER_NEXT_SERIAL",0) do
  if LOTM_WORLD_State.NumberGameProperty("LOTM_WORLD_MONSTER:"..serial..":LIVE",0)==1 and LOTM_WORLD_State.NumberGameProperty("LOTM_WORLD_MONSTER:"..serial..":TIER",-1)==level then
   local owner=LOTM_WORLD_State.NumberGameProperty("LOTM_WORLD_MONSTER:"..serial..":OWNER",-1);
   local unitID=LOTM_WORLD_State.NumberGameProperty("LOTM_WORLD_MONSTER:"..serial..":UNIT_ID",-1);
   local unit=UnitManager.GetUnit(owner,unitID); local plot=unit~=nil and Map.GetPlot(unit:GetX(),unit:GetY()) or nil;
   if plot~=nil then local distance=NearestCityDistance(p,plot); table.insert(candidates,{Kind="MONSTER",Id=serial,Plot=plot,Distance=distance,Band=CandidateBand(distance)}); end
  end
 end
 table.sort(candidates,function(a,b)
  if a.Band~=b.Band then return a.Band<b.Band; end
  if a.Distance~=b.Distance then return a.Distance<b.Distance; end
  if a.Kind~=b.Kind then return a.Kind<b.Kind; end
  return a.Id<b.Id;
 end);
 return candidates[1];
end

local function ClearActive(p,church)
 p:SetProperty(K(church,"ACTIVE_TIER"),0); p:SetProperty(K(church,"TARGET_KIND"),nil);
 p:SetProperty(K(church,"TARGET_ID"),nil); p:SetProperty(K(church,"TARGET_PLOT"),nil); p:SetProperty(K(church,"TARGET_PROGRESS"),nil);
end

local function ActivateOrPend(p,church,tier)
 local target=FindTarget(p,tier);
 p:SetProperty(K(church,"ACTIVE_TIER"),tier);
 if target==nil then
  -- Matching uncontrolled targets can legitimately be absent for a while.
  -- Keep the oracle pending and retry; ordinary camps may disappear entirely
  -- in late games and must never become an irreversible fallback objective.
  SetQuestState(p,church,tier,STATE.PENDING); p:SetProperty(K(church,"TARGET_KIND"),nil); p:SetProperty(K(church,"TARGET_ID"),nil);
  p:SetProperty(K(church,"TARGET_PLOT"),nil); p:SetProperty(K(church,"TARGET_PROGRESS"),nil); p:SetProperty(K(church,"NEXT_RECHECK"),CurrentPlayerTurn(p)+5);
  Log("pending target player="..p:GetID().." church="..church.." tier="..tier.." recheck="..N(p,K(church,"NEXT_RECHECK"),-1)); return;
 end
 SetQuestState(p,church,tier,STATE.ACTIVE); p:SetProperty(K(church,"TARGET_KIND"),target.Kind); p:SetProperty(K(church,"TARGET_ID"),target.Id);
 p:SetProperty(K(church,"TARGET_PLOT"),target.Plot:GetIndex()); p:SetProperty(K(church,"NEXT_RECHECK"),-1); RevealTarget(p,target.Plot);
 Log("active player="..p:GetID().." church="..church.." tier="..tier.." target="..target.Kind..":"..target.Id);
end

local function AdvanceQuestQueue(p,church)
 if N(p,K(church,"ACTIVE_TIER"),0)>0 then return; end
 local envoys=LOTM_WORLD_Churches.GetEnvoys(p:GetID(),church);
 for _,tier in ipairs(QUEST_TIERS) do
  -- In rescue mode the three separate tier-6 oracles are replaced by one
  -- shared milestone: all churches at six envoys unlock War God's Relic.
  if (not RescueActive() or tier~=6) and envoys>=tier and QuestState(p,church,tier)==STATE.LOCKED then ActivateOrPend(p,church,tier); return; end
 end
end

local function MigrateRescueTier6Quest(p,church)
 if not RescueActive() or N(p,"LOTM_RESCUE_CHURCH_QUEST_VERSION",0)>=1 then return; end
 local state=QuestState(p,church,6); local active=N(p,K(church,"ACTIVE_TIER"),0);
 if active==6 and (state==STATE.PENDING or state==STATE.ACTIVE) then
  ClearActive(p,church); SetQuestState(p,church,6,STATE.LOCKED);
  Log("rescue tier6 replaced player="..p:GetID().." church="..church.." oldState="..state.." replacement=WAR_GOD_RELIC");
 end
end

local function FinishRescueTier6Migration(p)
 if not RescueActive() or N(p,"LOTM_RESCUE_CHURCH_QUEST_VERSION",0)>=1 then return; end
 for _,church in ipairs(ORDER) do MigrateRescueTier6Quest(p,church); end
 p:SetProperty("LOTM_RESCUE_CHURCH_QUEST_VERSION",1);
end

local function PermanentBand(envoys) if envoys>=6 then return 6 elseif envoys>=3 then return 3 elseif envoys>=1 then return 1 end return 0; end
local function RefreshPermanent(p,church)
 local desired=PermanentBand(LOTM_WORLD_Churches.GetEnvoys(p:GetID(),church)); local applied=N(p,K(church,"PERMANENT_APPLIED"),0);
 if desired==applied then return; end
 if applied>0 then Attach(p,"LOTM_CHURCH_"..church.."_PERM_"..applied.."_OFF"); end
 if desired>0 then Attach(p,"LOTM_CHURCH_"..church.."_PERM_"..desired.."_ON"); end
 p:SetProperty(K(church,"PERMANENT_APPLIED"),desired);
 Log("permanent player="..p:GetID().." church="..church.." from="..applied.." to="..desired);
end

function LOTM_WORLD_Churches.ChangeEnvoys(playerID,church,delta,sourceKey)
 local p=Player(playerID); delta=tonumber(delta); if p==nil or not ValidChurch(church) or delta==nil or delta%1~=0 then return false; end
 local dedupe=K(church,"ENVOY_SOURCE_"..tostring(sourceKey or "")); if sourceKey~=nil and N(p,dedupe,0)==1 then return false; end
 local old=LOTM_WORLD_Churches.GetEnvoys(playerID,church); local value=math.max(0,old+delta); if value==old then return false; end
 p:SetProperty(K(church,"ENVOYS"),value); if sourceKey~=nil then p:SetProperty(dedupe,1); end
 RefreshPermanent(p,church); AdvanceQuestQueue(p,church);
 if church=="NIGHT" then
  if RefreshNightHomeCombat~=nil then RefreshNightHomeCombat(p); end
  if RefreshAllNightEnemyPenalties~=nil then RefreshAllNightEnemyPenalties(); end
 end
 if church=="FOOL" and RefreshFoolSight~=nil then RefreshFoolSight(p); end
 if LOTM_BE_RefreshEnvoyBaseline~=nil then LOTM_BE_RefreshEnvoyBaseline(playerID,true); end
 p:SetProperty("LOTM_CHURCH_ENVOY_CHANGE_SERIAL",N(p,"LOTM_CHURCH_ENVOY_CHANGE_SERIAL",0)+1);
 if LOTM_RESCUE_Phase10A~=nil and LOTM_RESCUE_Phase10A.OnChurchEnvoysChanged~=nil then LOTM_RESCUE_Phase10A.OnChurchEnvoysChanged(playerID); end
 Log("envoys player="..playerID.." church="..church.." old="..old.." new="..value.." source="..tostring(sourceKey)); return true;
end

local function TriggerRandomBoosts(p,techCount,civicCount,label)
 local techs=p:GetTechs(); local technologies={};
 -- CanTriggerBoost exists only in the UI context on the current game build.
 -- Gameplay can safely select unfinished, unboosted rows and call TriggerBoost.
 for row in GameInfo.Technologies() do if not techs:HasTech(row.Index) and not techs:HasBoostBeenTriggered(row.Index) then table.insert(technologies,row.Index); end end
 table.sort(technologies); for index=1,math.min(techCount,#technologies) do local pick=LOTM_WORLD_State.Random(#technologies,label..":TECH:"..index)+1; local value=table.remove(technologies,pick); local ok,err=pcall(function() techs:TriggerBoost(value,1); end); if not ok then Log("WARNING tech boost failed index="..tostring(value).." error="..tostring(err)); end end
 local culture=p:GetCulture(); local civics={};
 for row in GameInfo.Civics() do if not culture:HasCivic(row.Index) and not culture:HasBoostBeenTriggered(row.Index) then table.insert(civics,row.Index); end end
 table.sort(civics); for index=1,math.min(civicCount,#civics) do local pick=LOTM_WORLD_State.Random(#civics,label..":CIVIC:"..index)+1; local value=table.remove(civics,pick); local ok,err=pcall(function() culture:TriggerBoost(value,1); end); if not ok then Log("WARNING civic boost failed index="..tostring(value).." error="..tostring(err)); end end
 return true;
end

local function BlessingRank(tier,strength) return tier*10+(strength=="FULL" and 2 or 1); end
local function ApplyBlessing(p,church,tier,strength)
 local oldTier=N(p,K(church,"BLESSING_TIER"),0); local oldStrength=tostring(p:GetProperty(K(church,"BLESSING_STRENGTH")) or "NONE");
 if oldTier>0 and BlessingRank(oldTier,oldStrength)>BlessingRank(tier,strength) then return false; end
 if oldTier==tier and oldStrength==strength and CurrentPlayerTurn(p)<N(p,K(church,"BLESSING_UNTIL"),0) then return true; end
 if oldTier>0 then Attach(p,"LOTM_CHURCH_"..church.."_BLESS_"..oldTier.."_"..oldStrength.."_OFF"); end
 Attach(p,"LOTM_CHURCH_"..church.."_BLESS_"..tier.."_"..strength.."_ON");
 p:SetProperty(K(church,"BLESSING_TIER"),tier); p:SetProperty(K(church,"BLESSING_STRENGTH"),strength);
 local durationBase=CurrentPlayerTurn(p); if N(p,"LOTM_WORLD_PLAYER_TURN_SETTLED_GAME_TURN",-1)~=Game.GetCurrentGameTurn() then durationBase=durationBase+1; end
 p:SetProperty(K(church,"BLESSING_UNTIL"),durationBase+DURATION[tier]);
 if church=="NIGHT" then
  if RefreshNightHomeCombat~=nil then RefreshNightHomeCombat(p); end
  if RefreshAllNightEnemyPenalties~=nil then RefreshAllNightEnemyPenalties(); end
 end
 if church=="FOOL" and RefreshFoolSight~=nil then RefreshFoolSight(p); end
 Log("blessing player="..p:GetID().." church="..church.." tier="..tier.." strength="..strength); return true;
end

local function ArtifactName(artifactType)
 local row=artifactType~=nil and GameInfo.GreatWorks[artifactType] or nil;
 return row~=nil and Locale.Lookup(row.Name) or tostring(artifactType or "");
end

local function RecordReward(p,church,tier,kind,artifact,strength)
 p:SetProperty(QK(church,tier,"REWARD_KIND"),kind); p:SetProperty(QK(church,tier,"REWARD_ARTIFACT"),artifact); p:SetProperty(QK(church,tier,"REWARD_STRENGTH"),strength);
 if N(p,QK(church,tier,"REWARD_SERIAL"),0)<=0 then
  local serial=N(p,"LOTM_CHURCH_REWARD_SERIAL",0)+1; p:SetProperty("LOTM_CHURCH_REWARD_SERIAL",serial); p:SetProperty(QK(church,tier,"REWARD_SERIAL"),serial);
  p:SetProperty("LOTM_CHURCH_REWARD_CHURCH",church); p:SetProperty("LOTM_CHURCH_REWARD_TIER",tier); p:SetProperty("LOTM_CHURCH_REWARD_KIND",kind); p:SetProperty("LOTM_CHURCH_REWARD_ARTIFACT",artifact); p:SetProperty("LOTM_CHURCH_REWARD_STRENGTH",strength);
 end
end

local function RunBlessingExtras(p,church,tier,strength)
 if church~="FOOL" or N(p,QK(church,tier,"BOOSTS_DONE"),0)==1 then return; end
 local counts={FULL={[6]={2,2},[10]={3,3},[15]={5,5}},HALF={[6]={1,1},[10]={1,1},[15]={2,2}}}; local c=counts[strength] and counts[strength][tier] or nil;
 if c~=nil then TriggerRandomBoosts(p,c[1],c[2],"church quest blessing:"..p:GetID()..":"..church..":"..tier..":"..strength); end
 p:SetProperty(QK(church,tier,"BOOSTS_DONE"),1);
end

local function NotifyReward(p,church,tier)
 if N(p,QK(church,tier,"NOTIFICATION_DELIVERED"),0)==1 then return; end
 local kind=tostring(p:GetProperty(QK(church,tier,"REWARD_KIND")) or ""); if kind=="" then return; end
 local churchName=Locale.Lookup(CHURCHES[church].Name); local detail="";
 if kind=="ARTIFACT" then detail=Locale.Lookup("LOC_LOTM_CHURCH_REWARD_ARTIFACT",ArtifactName(p:GetProperty(QK(church,tier,"REWARD_ARTIFACT"))));
 else local strength=tostring(p:GetProperty(QK(church,tier,"REWARD_STRENGTH")) or (kind=="HALF_BLESSING" and "HALF" or "FULL")); detail=Locale.Lookup(kind=="HALF_BLESSING" and "LOC_LOTM_CHURCH_REWARD_HALF_BLESSING" or "LOC_LOTM_CHURCH_REWARD_FULL_BLESSING",Locale.Lookup("LOC_LOTM_CHURCH_BLESS_"..church.."_"..tier.."_"..strength)); end
 local data={}; data[ParameterTypes.MESSAGE]=Locale.Lookup("LOC_LOTM_CHURCH_REWARD_NOTIFICATION_MESSAGE",churchName,tier); data[ParameterTypes.SUMMARY]=detail; data.AlwaysUnique=true; data.ShowIcon=true;
 local ok,err=pcall(function() NotificationManager.SendNotification(p:GetID(),REWARD_NOTIFICATIONS[church],data); end);
 if ok then p:SetProperty(QK(church,tier,"NOTIFICATION_DELIVERED"),1); p:SetProperty("LOTM_CHURCH_NOTIFICATION_DELIVERED_SERIAL",N(p,QK(church,tier,"REWARD_SERIAL"),0)); else Log("WARNING reward notification failed error="..tostring(err)); end
end

local function EnsureArtifactReward(p,church,tier)
 local selected=p:GetProperty(QK(church,tier,"REWARD_ARTIFACT"));
 if selected==nil and LOTM_PP_GetAvailableArtifacts~=nil then local pool=LOTM_PP_GetAvailableArtifacts(TARGET_LEVEL[tier],nil); if #pool>0 then local row=pool[LOTM_WORLD_State.Random(#pool,"church artifact:"..p:GetID()..":"..church..":"..tier)+1]; selected=row and row.ArtifactType or nil; p:SetProperty(QK(church,tier,"REWARD_ARTIFACT"),selected); end end
 if selected==nil or LOTM_PP_GrantSpecificArtifact==nil then return false,nil; end
 if p:GetProperty("LOTM_PP_ARTIFACT_INSTANCE_"..selected)~=nil then return true,selected; end
 local ok,result=pcall(function() return LOTM_PP_GrantSpecificArtifact(p:GetID(),selected); end); return ok and result==true,selected;
end

local function RewardSelf(p,church,tier,targetKey)
 LOTM_WORLD_Churches.ChangeEnvoys(p:GetID(),church,1,"QUEST:"..tier..":"..targetKey);
 local kind=p:GetProperty(QK(church,tier,"REWARD_KIND"));
 -- Repair rc.83 saves that crashed inside the Fool boost call after the blessing
 -- and envoy were already persisted but before REWARD_KIND/ClearActive.
 if kind==nil and N(p,K(church,"BLESSING_TIER"),0)==tier and tostring(p:GetProperty(K(church,"BLESSING_STRENGTH")) or "")=="FULL" then kind="FULL_BLESSING"; RecordReward(p,church,tier,kind,nil,"FULL"); p:SetProperty(QK(church,tier,"REWARD_APPLIED"),1); end
 if kind==nil then
  local roll=N(p,QK(church,tier,"REWARD_ROLL"),-1); if roll<0 then roll=LOTM_WORLD_State.Random(100,"church reward:"..p:GetID()..":"..church..":"..tier..":"..targetKey); p:SetProperty(QK(church,tier,"REWARD_ROLL"),roll); end
  local artifact,artifactType=false,nil; if roll<ARTIFACT_CHANCE[tier] then artifact,artifactType=EnsureArtifactReward(p,church,tier); end
  kind=artifact and "ARTIFACT" or "FULL_BLESSING"; RecordReward(p,church,tier,kind,artifactType,artifact and nil or "FULL");
 end
 if N(p,QK(church,tier,"REWARD_APPLIED"),0)~=1 then
  if kind=="ARTIFACT" then local granted=EnsureArtifactReward(p,church,tier); if granted then p:SetProperty(QK(church,tier,"REWARD_APPLIED"),1); end
  else ApplyBlessing(p,church,tier,"FULL"); p:SetProperty(QK(church,tier,"REWARD_APPLIED"),1); end
 end
 if kind~="ARTIFACT" then RunBlessingExtras(p,church,tier,"FULL"); end
 NotifyReward(p,church,tier);
end

local function RewardAssist(p,church,tier)
 local kind=p:GetProperty(QK(church,tier,"REWARD_KIND")); if kind==nil then RecordReward(p,church,tier,"HALF_BLESSING",nil,"HALF"); end
 if N(p,QK(church,tier,"REWARD_APPLIED"),0)~=1 then ApplyBlessing(p,church,tier,"HALF"); p:SetProperty(QK(church,tier,"REWARD_APPLIED"),1); end
 RunBlessingExtras(p,church,tier,"HALF"); NotifyReward(p,church,tier);
end

local function FinalizeResolved(p,church,tier,state,targetKey)
 p:SetProperty(QK(church,tier,"RESOLUTION_TARGET"),targetKey); ClearActive(p,church);
 local ok,err=pcall(function() if state==STATE.SELF then RewardSelf(p,church,tier,targetKey); else RewardAssist(p,church,tier); end end);
 if not ok then Log("WARNING reward finalization deferred player="..p:GetID().." church="..church.." tier="..tier.." error="..tostring(err)); end
 AdvanceQuestQueue(p,church);
end

local function ResolveTarget(kind,id,resolverPlayerID)
 local selfHandled=false; local targetKey=kind..":"..tostring(id);
 for _,majorID in ipairs(PlayerManager.GetAliveMajorIDs()) do local p=Player(majorID); if p~=nil then
  for _,church in ipairs(ORDER) do local tier=N(p,K(church,"ACTIVE_TIER"),0);
   if tier>0 and QuestState(p,church,tier)==STATE.ACTIVE and p:GetProperty(K(church,"TARGET_KIND"))==kind and N(p,K(church,"TARGET_ID"),-1)==id then
    local key=QK(church,tier,"SETTLED_"..targetKey); if N(p,key,0)~=1 then
     p:SetProperty(key,1); if majorID==resolverPlayerID then SetQuestState(p,church,tier,STATE.SELF); FinalizeResolved(p,church,tier,STATE.SELF,targetKey); selfHandled=true;
     else SetQuestState(p,church,tier,STATE.ASSIST); FinalizeResolved(p,church,tier,STATE.ASSIST,targetKey); end
    end
   end
  end
 end end
 return selfHandled;
end

function LOTM_WORLD_Churches.OnWorkshopResolved(plotIndex,resolverPlayerID) return ResolveTarget("WORKSHOP",tonumber(plotIndex) or -1,tonumber(resolverPlayerID) or -1); end
function LOTM_WORLD_Churches.ResolveMonsterQuest(killerPlayerID,serial) return ResolveTarget("MONSTER",tonumber(serial) or -1,tonumber(killerPlayerID) or -1); end

function LOTM_WORLD_Churches.OnBarbarianCampResolved(plotIndex,resolverPlayerID)
 -- Ordinary camps are no longer oracle targets. Returning false preserves the
 -- normal workshop/camp reward path for new games and migrated saves.
 return false;
end

local function TargetStillValid(kind,id,tier)
 if kind=="WORKSHOP" then local plot=Map.GetPlotByIndex(id); return plot~=nil and N(plot,"LOTM_PP_WORKSHOP_IS_WORKSHOP",0)==1 and N(plot,"LOTM_PP_WORKSHOP_LEVEL",2)==TARGET_LEVEL[tier] and plot:GetImprovementType()==GameInfo.Improvements.IMPROVEMENT_BARBARIAN_CAMP.Index; end
 if kind=="MONSTER" then return LOTM_WORLD_State.NumberGameProperty("LOTM_WORLD_MONSTER:"..id..":LIVE",0)==1 and LOTM_WORLD_State.NumberGameProperty("LOTM_WORLD_MONSTER:"..id..":TIER",-1)==TARGET_LEVEL[tier]; end
 -- Resource-110 saves stuck on the old fallback migrate to pending/recheck.
 if kind=="BARB_CAMP_COUNT" then return false; end
 return false;
end

local function ReconcileQuest(p,church)
 local tier=N(p,K(church,"ACTIVE_TIER"),0); if tier<=0 then AdvanceQuestQueue(p,church); return; end
 local state=QuestState(p,church,tier);
 if state==STATE.SELF or state==STATE.ASSIST then local kind=tostring(p:GetProperty(K(church,"TARGET_KIND")) or "UNKNOWN"); local id=N(p,K(church,"TARGET_ID"),-1); FinalizeResolved(p,church,tier,state,tostring(p:GetProperty(QK(church,tier,"RESOLUTION_TARGET")) or (kind..":"..id)));
 elseif state==STATE.PENDING and CurrentPlayerTurn(p)>=N(p,K(church,"NEXT_RECHECK"),0) then ActivateOrPend(p,church,tier);
 elseif state==STATE.ACTIVE then local kind=tostring(p:GetProperty(K(church,"TARGET_KIND")) or ""); local id=N(p,K(church,"TARGET_ID"),-1);
  if not TargetStillValid(kind,id,tier) then SetQuestState(p,church,tier,STATE.PENDING); p:SetProperty(K(church,"TARGET_KIND"),nil); p:SetProperty(K(church,"TARGET_ID"),nil); p:SetProperty(K(church,"TARGET_PLOT"),nil); p:SetProperty(K(church,"NEXT_RECHECK"),CurrentPlayerTurn(p)+5); end
 end
end

local function ReconcileCompletedRewards(p,church)
 for _,tier in ipairs(QUEST_TIERS) do local state=QuestState(p,church,tier); if state==STATE.SELF then local target=tostring(p:GetProperty(QK(church,tier,"RESOLUTION_TARGET")) or ("RECOVERED:"..tier)); local ok,err=pcall(function() RewardSelf(p,church,tier,target); end); if not ok then Log("WARNING self reward retry failed error="..tostring(err)); end elseif state==STATE.ASSIST then local ok,err=pcall(function() RewardAssist(p,church,tier); end); if not ok then Log("WARNING assist reward retry failed error="..tostring(err)); end end end
end

local function EffectiveHeal(p,church)
 local tier=N(p,K(church,"BLESSING_TIER"),0); local strength=tostring(p:GetProperty(K(church,"BLESSING_STRENGTH")) or "NONE");
 if church=="NIGHT" then if tier==6 then return strength=="FULL" and 20 or 10 elseif tier==10 then return strength=="FULL" and 30 or 15 elseif tier==15 then return strength=="FULL" and 50 or 25 end
  return LOTM_WORLD_Churches.GetEnvoys(p:GetID(),church)>=6 and 10 or 0;
 elseif church=="STORM" then if tier==6 then return strength=="FULL" and 20 or 10 elseif tier==10 then return strength=="FULL" and 30 or 15 elseif tier==15 then return strength=="FULL" and 50 or 25 end end
 return 0;
end

local function HealUnits(p,church,amount)
 if amount<=0 then return; end
 for _,unit in p:GetUnits():Members() do
  local info=GameInfo.Units[unit:GetType()]; local plot=nil;
  if church=="NIGHT" and info~=nil and info.FormationClass~="FORMATION_CLASS_CIVILIAN" then
   plot=Map.GetPlot(unit:GetX(),unit:GetY());
   if plot==nil then Log("heal skipped player="..p:GetID().." church="..church.." unit="..unit:GetID().." reason=PLOT_MISSING xy="..unit:GetX()..":"..unit:GetY()); end
  end
  local eligible=church=="STORM" and info~=nil and info.Domain=="DOMAIN_SEA" or church=="NIGHT" and info~=nil and info.FormationClass~="FORMATION_CLASS_CIVILIAN" and plot~=nil and plot:GetOwner()==p:GetID();
  if eligible and unit:GetDamage()>0 then unit:ChangeDamage(-math.min(amount,unit:GetDamage())); end
 end
end

local function ExpireBlessing(p,church)
 local tier=N(p,K(church,"BLESSING_TIER"),0); if tier<=0 or CurrentPlayerTurn(p)<N(p,K(church,"BLESSING_UNTIL"),0) then return; end
 local strength=tostring(p:GetProperty(K(church,"BLESSING_STRENGTH")) or "NONE"); Attach(p,"LOTM_CHURCH_"..church.."_BLESS_"..tier.."_"..strength.."_OFF");
 p:SetProperty(K(church,"BLESSING_TIER"),0); p:SetProperty(K(church,"BLESSING_STRENGTH"),nil); p:SetProperty(K(church,"BLESSING_UNTIL"),-1); Log("blessing expired player="..p:GetID().." church="..church);
 if church=="NIGHT" then
  if RefreshNightHomeCombat~=nil then RefreshNightHomeCombat(p); end
  if RefreshAllNightEnemyPenalties~=nil then RefreshAllNightEnemyPenalties(); end
 end
 if church=="FOOL" and RefreshFoolSight~=nil then RefreshFoolSight(p); end
end

local function SetAbility(unit,abilityType,desired)
 local abilities=unit~=nil and unit:GetAbility() or nil; if abilities==nil then return; end
 local current=abilities:GetAbilityCount(abilityType) or 0;
 if current~=desired then abilities:ChangeAbilityCount(abilityType,desired-current); end
end

local function FoolSightAmounts(p)
 local envoys=LOTM_WORLD_Churches.GetEnvoys(p:GetID(),"FOOL");
 local allSight=0; local reconExtra=0;
 if envoys>=1 then allSight=1; reconExtra=1; end
 if envoys>=6 then allSight=allSight+1; end
 local tier=N(p,K("FOOL","BLESSING_TIER"),0);
 if tier>0 and CurrentPlayerTurn(p)<N(p,K("FOOL","BLESSING_UNTIL"),0) then
  local strength=tostring(p:GetProperty(K("FOOL","BLESSING_STRENGTH")) or "NONE");
  if tier==6 then allSight=allSight+(strength=="FULL" and 2 or 1);
  elseif tier==15 then allSight=allSight+(strength=="FULL" and 3 or 1); end
 end
 return math.max(0,math.min(5,allSight)),reconExtra;
end

local function RefreshFoolSightForUnit(p,unit,allSight,reconExtra)
 if p==nil or unit==nil then return; end
 for amount,abilityType in ipairs(FOOL_ALL_SIGHT_ABILITIES) do
  SetAbility(unit,abilityType,amount==allSight and 1 or 0);
 end
 SetAbility(unit,FOOL_RECON_SIGHT_ABILITY,reconExtra>0 and 1 or 0);
end

RefreshFoolSight=function(p)
 if p==nil then return; end
 local allSight,reconExtra=FoolSightAmounts(p);
 for _,unit in p:GetUnits():Members() do RefreshFoolSightForUnit(p,unit,allSight,reconExtra); end
 local signature=tostring(allSight)..":"..tostring(reconExtra);
 if tostring(p:GetProperty(K("FOOL","SIGHT_ABILITY_STATE")) or "")~=signature then
  p:SetProperty(K("FOOL","SIGHT_ABILITY_STATE"),signature);
  Log("fool sight player="..p:GetID().." all="..allSight.." reconExtra="..reconExtra);
 end
end

local function NightHomeAbilities(p)
 local permanent=nil; local envoys=LOTM_WORLD_Churches.GetEnvoys(p:GetID(),"NIGHT");
 if envoys>=6 then permanent="ABILITY_LOTM_CHURCH_NIGHT_HOME_PERM_10";
 elseif envoys>=3 then permanent="ABILITY_LOTM_CHURCH_NIGHT_HOME_PERM_5"; end
 local blessing=nil; local tier=N(p,K("NIGHT","BLESSING_TIER"),0);
 if tier>0 and CurrentPlayerTurn(p)<N(p,K("NIGHT","BLESSING_UNTIL"),0) then
  local strength=tostring(p:GetProperty(K("NIGHT","BLESSING_STRENGTH")) or "NONE");
  local amount=nil;
  if tier==6 then amount=strength=="FULL" and 15 or 7;
  elseif tier==10 then amount=strength=="FULL" and 25 or 12;
  elseif tier==15 then amount=strength=="FULL" and 40 or 20; end
  if amount~=nil then blessing="ABILITY_LOTM_CHURCH_NIGHT_HOME_BLESS_"..tostring(amount); end
 end
 return permanent,blessing;
end

local function RefreshNightHomeCombatForUnit(p,unit)
 if p==nil or unit==nil then return; end
 local permanent,blessing=NightHomeAbilities(p);
 for _,abilityType in ipairs(NIGHT_HOME_ABILITIES) do
  SetAbility(unit,abilityType,(abilityType==permanent or abilityType==blessing) and 1 or 0);
 end
end

RefreshNightHomeCombat=function(p)
 if p==nil then return; end
 for _,unit in p:GetUnits():Members() do RefreshNightHomeCombatForUnit(p,unit); end
end

local function NightEnemyPenaltyForTerritory(owner)
 if owner==nil or not owner:IsAlive() or not owner:IsMajor() then return nil,nil; end
 local tier=N(owner,K("NIGHT","BLESSING_TIER"),0);
 if tier~=10 and tier~=15 then return nil,nil; end
 if CurrentPlayerTurn(owner)>=N(owner,K("NIGHT","BLESSING_UNTIL"),0) then return nil,nil; end
 local strength=tostring(owner:GetProperty(K("NIGHT","BLESSING_STRENGTH")) or "NONE");
 if tier==10 then return strength=="FULL" and 10 or 5,strength=="FULL" and 1 or 0; end
 return strength=="FULL" and 20 or 10,strength=="FULL" and 2 or 1;
end

local function RefreshNightEnemyPenalty(unitOwnerID,unit)
 local combat,movement=nil,nil; local plot=unit~=nil and Map.GetPlot(unit:GetX(),unit:GetY()) or nil;
 local territoryID=plot~=nil and plot:GetOwner() or -1;
 if territoryID~=nil and territoryID>=0 and territoryID~=unitOwnerID then
  local territoryOwner=Players[territoryID]; local unitOwner=Players[unitOwnerID];
  local diplomacy=territoryOwner~=nil and territoryOwner:GetDiplomacy() or nil;
  if unitOwner~=nil and diplomacy~=nil and diplomacy:IsAtWarWith(unitOwnerID) then combat,movement=NightEnemyPenaltyForTerritory(territoryOwner); end
 end
 local wanted={
  ABILITY_LOTM_CHURCH_NIGHT_ENEMY_COMBAT_5=combat==5 and 1 or 0,
  ABILITY_LOTM_CHURCH_NIGHT_ENEMY_COMBAT_10=combat==10 and 1 or 0,
  ABILITY_LOTM_CHURCH_NIGHT_ENEMY_COMBAT_20=combat==20 and 1 or 0,
  ABILITY_LOTM_CHURCH_NIGHT_ENEMY_MOVE_1=movement==1 and 1 or 0,
  ABILITY_LOTM_CHURCH_NIGHT_ENEMY_MOVE_2=movement==2 and 1 or 0
 };
 for _,abilityType in ipairs(NIGHT_ENEMY_ABILITIES) do SetAbility(unit,abilityType,wanted[abilityType]); end
end

RefreshAllNightEnemyPenalties=function()
 local groups={PlayerManager.GetAliveMajorIDs(),PlayerManager.GetAliveMinorIDs()};
 for _,ids in ipairs(groups) do for _,ownerID in ipairs(ids) do local owner=Players[ownerID]; if owner~=nil then
  for _,unit in owner:GetUnits():Members() do RefreshNightEnemyPenalty(ownerID,unit); end
 end end end
 for _,owner in ipairs(PlayerManager.GetAliveBarbarians()) do for _,unit in owner:GetUnits():Members() do RefreshNightEnemyPenalty(owner:GetID(),unit); end end
end

local function OnUnitMoved(playerID,unitID)
 local unit=UnitManager.GetUnit(playerID,unitID); if unit~=nil then RefreshNightEnemyPenalty(playerID,unit); end
end

local function FoolEraBoon(p)
 if LOTM_WORLD_Churches.GetEnvoys(p:GetID(),"FOOL")<6 then return; end local era=Game.GetEras():GetCurrentEra() or 0;
 if N(p,K("FOOL","LAST_ERA_BOON"),-1)==era then return; end p:SetProperty(K("FOOL","LAST_ERA_BOON"),era); TriggerRandomBoosts(p,1,1,"fool era:"..p:GetID()..":"..era);
end

local function OnPlayerTurn(playerID,isFirstTime)
 if isFirstTime==false then return; end local p=Player(playerID); if p==nil then return; end
 FinishRescueTier6Migration(p);
 for _,church in ipairs(ORDER) do RefreshPermanent(p,church); ExpireBlessing(p,church); ReconcileQuest(p,church); ReconcileCompletedRewards(p,church); HealUnits(p,church,EffectiveHeal(p,church)); end RefreshNightHomeCombat(p); RefreshFoolSight(p); FoolEraBoon(p); RefreshAllNightEnemyPenalties();
end

local function OnUnitAdded(playerID,unitID)
 local unit=UnitManager.GetUnit(playerID,unitID); if unit~=nil then
  local p=Player(playerID);
  if p~=nil then
   RefreshNightHomeCombatForUnit(p,unit);
   local allSight,reconExtra=FoolSightAmounts(p); RefreshFoolSightForUnit(p,unit,allSight,reconExtra);
  end
  RefreshNightEnemyPenalty(playerID,unit);
 end
end

local function OnDiplomacyChanged()
 RefreshAllNightEnemyPenalties();
end

local function OnSendEnvoys(playerID,parameters)
 local p=Player(playerID); if p==nil or type(parameters)~="table" then return; end local counts={}; local total=0;
 for _,church in ipairs(ORDER) do local value=tonumber(parameters[church] or 0) or 0; if value<0 or value%1~=0 or value>99 then Log("rejected invalid envoy batch player="..playerID); return; end counts[church]=value; total=total+value; end
 local serial=tostring(parameters.Serial or ""); if serial=="" or N(p,"LOTM_CHURCH_COMMAND_"..serial,0)==1 then return; end local influence=p:GetInfluence();
 if influence==nil or total<=0 or (influence:GetTokensToGive() or 0)<total then Log("rejected stale envoy batch player="..playerID.." total="..total); return; end
 influence:ChangeTokensToGive(-total); p:SetProperty("LOTM_CHURCH_COMMAND_"..serial,1);
 for _,church in ipairs(ORDER) do if counts[church]>0 then LOTM_WORLD_Churches.ChangeEnvoys(playerID,church,counts[church],"COMMAND:"..serial); end end
 Log("accepted envoy batch player="..playerID.." total="..total.." serial="..serial);
end

function LOTM_WORLD_Churches.GetUISnapshot(playerID)
 local p=Player(playerID); local snapshot={Version=4,Churches={}}; if p==nil then return snapshot; end
 for _,church in ipairs(ORDER) do local active=N(p,K(church,"ACTIVE_TIER"),0); snapshot.Churches[church]={ChurchType=church,Path=CHURCHES[church].Path,Name=CHURCHES[church].Name,Envoys=LOTM_WORLD_Churches.GetEnvoys(playerID,church),Quest6=QuestState(p,church,6),Quest10=QuestState(p,church,10),Quest15=QuestState(p,church,15),ActiveTier=active,TargetKind=p:GetProperty(K(church,"TARGET_KIND")),TargetId=N(p,K(church,"TARGET_ID"),-1),TargetPlot=N(p,K(church,"TARGET_PLOT"),-1),BlessingTier=N(p,K(church,"BLESSING_TIER"),0),BlessingStrength=p:GetProperty(K(church,"BLESSING_STRENGTH")),BlessingRemaining=math.max(0,N(p,K(church,"BLESSING_UNTIL"),0)-CurrentPlayerTurn(p))}; end return snapshot;
end

GameEvents[COMMAND].Add(OnSendEnvoys);
Events.PlayerTurnActivated.Add(OnPlayerTurn);
Events.UnitAddedToMap.Add(LOTM_UnitAddedPerf.Wrap("Churches",OnUnitAdded));
Events.DiplomacyDeclareWar.Add(OnDiplomacyChanged);
Events.DiplomacyMakePeace.Add(OnDiplomacyChanged);
GameEvents.OnUnitMoved.Add(OnUnitMoved);
if LOTM_WORLD_Monsters~=nil and LOTM_WORLD_Monsters.RegisterQuestResolver~=nil then LOTM_WORLD_Monsters.RegisterQuestResolver(LOTM_WORLD_Churches.ResolveMonsterQuest); end
for _,id in ipairs(PlayerManager.GetAliveMajorIDs()) do local p=Player(id); if p~=nil then FinishRescueTier6Migration(p); for _,church in ipairs(ORDER) do for _,tier in ipairs(QUEST_TIERS) do if p:GetProperty(QK(church,tier,"STATE"))==nil then SetQuestState(p,church,tier,STATE.LOCKED); end end RefreshPermanent(p,church); ReconcileQuest(p,church); ReconcileCompletedRewards(p,church); end RefreshNightHomeCombat(p); RefreshFoolSight(p); end end
Log("initialized virtual=3 thresholds=1/3/6 quests=ordinary:6/10/15 rescue:allThreeAt6WarGodRelicThen10/15 state=4");
-- END RC241 MODULE: Scripts/LOTM_WORLD_Churches.lua
end;

m_mp241Loaders["LOTM_WORLD_Events"] = function()
-- BEGIN RC241 MODULE: Scripts/LOTM_WORLD_Events.lua
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("MP.LOTM_WORLD_Events","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"MP.LOTM_WORLD_Events","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"MP.LOTM_WORLD_Events","GameEvents");
-- END RC342 STARTUP TRACE

-- Authoritative, synchronized Extraordinary World random status events.
local GOOD_ABILITY :string="ABILITY_LOTM_WORLD_HOLDER_GOOD";
local BAD_ABILITY :string="ABILITY_LOTM_WORLD_HOLDER_UNSTABLE";
local SLOT_PREFIX :string="LOTM_PP_ARTIFACT_SLOT_";
local FIRST_MIN :number=12;
local FIRST_SPAN :number=7;
local NEXT_MIN :number=10;
local NEXT_SPAN :number=7;
local DURATION :number=5;

local NOTIFICATION_TYPES :table={
	PATH_PERFECT=NotificationTypes.USER_DEFINED_6,
	PATH_RED_PRIEST=NotificationTypes.USER_DEFINED_7,
	PATH_BLACK_EMPEROR=NotificationTypes.USER_DEFINED_8
};

local function Log(value) print("[LOTM_WORLD][Events] "..tostring(value)); end

local function ShuffleBag()
	local bag={"G","G","B","B"};
	for index=#bag,2,-1 do
		local swap=LOTM_WORLD_State.Random(index,"event bag shuffle")+1;
		bag[index],bag[swap]=bag[swap],bag[index];
	end
	return table.concat(bag,"");
end

local function Draw(player)
	local bag=player:GetProperty("LOTM_WORLD_EVENT_BAG_ORDER");
	local index=LOTM_WORLD_State.NumberProperty(player,"LOTM_WORLD_EVENT_BAG_INDEX",5);
	if bag==nil or #tostring(bag)~=4 or index<1 or index>4 then
		bag=ShuffleBag(); index=1;
	end
	local result=string.sub(bag,index,index);
	local last=tostring(player:GetProperty("LOTM_WORLD_EVENT_LAST") or "");
	local previous=tostring(player:GetProperty("LOTM_WORLD_EVENT_PREVIOUS") or "");
	if result==last and result==previous then
		for swap=index+1,4 do
			if string.sub(bag,swap,swap)~=result then
				local replacement=string.sub(bag,swap,swap);
				bag=string.sub(bag,1,index-1)..replacement..string.sub(bag,index+1,swap-1)..result..string.sub(bag,swap+1);
				result=replacement;
				break;
			end
		end
	end
	player:SetProperty("LOTM_WORLD_EVENT_BAG_ORDER",bag);
	player:SetProperty("LOTM_WORLD_EVENT_BAG_INDEX",index+1);
	player:SetProperty("LOTM_WORLD_EVENT_PREVIOUS",last);
	player:SetProperty("LOTM_WORLD_EVENT_LAST",result);
	return result;
end

local function Equipped(player)
	local result={};
	for slot=1,9 do
		local artifactType=player:GetProperty(SLOT_PREFIX..slot);
		local instance=LOTM_WORLD_State.NumberProperty(player,SLOT_PREFIX..slot.."_INSTANCE",nil);
		if artifactType~=nil and instance~=nil then
			table.insert(result,{Type=artifactType,Instance=instance,Slot=slot});
		end
	end
	table.sort(result,function(a,b)
		if a.Slot~=b.Slot then return a.Slot<b.Slot; end
		return a.Type<b.Type;
	end);
	return result;
end

local function SetAbility(unit,abilityType,wanted)
	local abilities=unit~=nil and unit:GetAbility() or nil;
	if abilities==nil then return -1; end
	local current=abilities:GetAbilityCount(abilityType) or 0;
	local target=wanted and 1 or 0;
	if current~=target then abilities:ChangeAbilityCount(abilityType,target-current); end
	return abilities:GetAbilityCount(abilityType) or 0;
end

local function RefreshHolder(player,turn)
	local hero=LOTM_RP_State.FindHero(player:GetID());
	local goodWanted=turn<LOTM_WORLD_State.NumberProperty(player,"LOTM_HOLDER_GOOD_STATE_UNTIL",-1);
	local badWanted=turn<LOTM_WORLD_State.NumberProperty(player,"LOTM_HOLDER_UNSTABLE_STATE_UNTIL",-1);
	local goodActual=SetAbility(hero,GOOD_ABILITY,goodWanted);
	local badActual=SetAbility(hero,BAD_ABILITY,badWanted);
	Log("holder effects player="..tostring(player:GetID()).." turn="..tostring(turn)
		.." good="..tostring(goodWanted).."/"..tostring(goodActual)
		.." unstable="..tostring(badWanted).."/"..tostring(badActual));
end

local function ArtifactName(artifactType)
	local row=artifactType~=nil and GameInfo.GreatWorks[artifactType] or nil;
	return row~=nil and Locale.Lookup(row.Name) or tostring(artifactType or "");
end

local function Notify(player,kind,artifactType)
	local messageKey="LOC_LOTM_WORLD_NOTIFICATION_"..kind.."_MESSAGE";
	local summaryKey="LOC_LOTM_WORLD_NOTIFICATION_"..kind.."_SUMMARY";
	local name=ArtifactName(artifactType);
	local path=tostring(player:GetProperty("LOTM_RP_PATH") or "PATH_RED_PRIEST");
	local notificationType=NOTIFICATION_TYPES[path] or NotificationTypes.USER_DEFINED_9;
	local data={};
	data[ParameterTypes.MESSAGE]=Locale.Lookup(messageKey,name);
	data[ParameterTypes.SUMMARY]=Locale.Lookup(summaryKey,name);
	data.AlwaysUnique=true;
	data.ShowIcon=true;
	NotificationManager.SendNotification(player:GetID(),notificationType,data);
end

local function RecordEvent(player,kind,item,turn)
	player:SetProperty("LOTM_WORLD_EVENT_KIND",kind);
	player:SetProperty("LOTM_WORLD_EVENT_TARGET",item);
	player:SetProperty("LOTM_WORLD_EVENT_TRIGGER_TURN",turn);
	player:SetProperty("LOTM_WORLD_EVENT_SERIAL",LOTM_WORLD_State.NumberProperty(player,"LOTM_WORLD_EVENT_SERIAL",0)+1);
end

local function RestoreExpiredPendingEffect(player,kind)
	local turn=LOTM_WORLD_State.NumberProperty(player,"LOTM_WORLD_PLAYER_TURN",0);
	local triggerTurn=LOTM_WORLD_State.NumberProperty(player,"LOTM_WORLD_EVENT_TRIGGER_TURN",turn);
	if turn<triggerTurn+DURATION then return; end
	if kind=="HOLDER_GOOD" or kind=="HOLDER_UNSTABLE" then
		local key=kind=="HOLDER_GOOD" and "LOTM_HOLDER_GOOD_STATE_UNTIL" or "LOTM_HOLDER_UNSTABLE_STATE_UNTIL";
		player:SetProperty(key,turn+DURATION);
		Log("restored expired pending holder effect player="..tostring(player:GetID()).." kind="..kind.." until="..tostring(turn+DURATION));
		return;
	end
	local targetType=player:GetProperty("LOTM_WORLD_EVENT_TARGET");
	for _,target in ipairs(Equipped(player)) do
		if target.Type==targetType then
			local prefix=kind=="ARTIFACT_SATISFIED" and "LOTM_ARTIFACT_SATISFIED_UNTIL_" or "LOTM_ARTIFACT_UNCONTROLLED_UNTIL_";
			player:SetProperty(prefix..tostring(target.Instance),turn+DURATION);
			player:SetProperty("LOTM_PP_ARTIFACT_EFFECT_REFRESH_PENDING",1);
			Log("restored expired pending artifact effect player="..tostring(player:GetID()).." kind="..kind.." until="..tostring(turn+DURATION));
			return;
		end
	end
end

local function RepairV87LastEventOnce(player)
	if LOTM_WORLD_State.NumberProperty(player,"LOTM_WORLD_EFFECT_VISIBILITY_REPAIR87",0)==1 then return; end
	-- Persist first: reload/reconnect cannot repeatedly extend the compensation.
	player:SetProperty("LOTM_WORLD_EFFECT_VISIBILITY_REPAIR87",1);
	local kind=player:GetProperty("LOTM_WORLD_EVENT_KIND");
	if kind~=nil then RestoreExpiredPendingEffect(player,tostring(kind)); end
end

local function DeliverPendingNotification(player)
	local serial=LOTM_WORLD_State.NumberProperty(player,"LOTM_WORLD_EVENT_SERIAL",0);
	local delivered=LOTM_WORLD_State.NumberProperty(player,"LOTM_WORLD_NOTIFICATION_DELIVERED_SERIAL",0);
	if serial<=0 or serial<=delivered then return; end
	local kind=player:GetProperty("LOTM_WORLD_EVENT_KIND");
	if kind==nil or NOTIFICATION_TYPES[tostring(player:GetProperty("LOTM_RP_PATH") or "")] == nil then return; end
	RestoreExpiredPendingEffect(player,tostring(kind));
	local ok,err=pcall(Notify,player,tostring(kind),player:GetProperty("LOTM_WORLD_EVENT_TARGET"));
	if ok then
		player:SetProperty("LOTM_WORLD_NOTIFICATION_DELIVERED_SERIAL",serial);
		Log("notification delivered player="..tostring(player:GetID()).." serial="..tostring(serial).." path="..tostring(player:GetProperty("LOTM_RP_PATH")));
	else
		Log("WARNING notification failed player="..tostring(player:GetID()).." serial="..tostring(serial).." error="..tostring(err));
	end
end

local function Trigger(player,turn)
	local nature=Draw(player);
	local equipped=Equipped(player);
	local useArtifact=#equipped>0 and LOTM_WORLD_State.Random(2,"event target type")==0;
	local kind="";
	local targetType=nil;
	if useArtifact then
		local target=equipped[LOTM_WORLD_State.Random(#equipped,"artifact event target")+1];
		local prefix=nature=="G" and "LOTM_ARTIFACT_SATISFIED_UNTIL_" or "LOTM_ARTIFACT_UNCONTROLLED_UNTIL_";
		player:SetProperty(prefix..tostring(target.Instance),turn+DURATION);
		kind=nature=="G" and "ARTIFACT_SATISFIED" or "ARTIFACT_UNCONTROLLED";
		targetType=target.Type;
	else
		local key=nature=="G" and "LOTM_HOLDER_GOOD_STATE_UNTIL" or "LOTM_HOLDER_UNSTABLE_STATE_UNTIL";
		player:SetProperty(key,turn+DURATION);
		kind=nature=="G" and "HOLDER_GOOD" or "HOLDER_UNSTABLE";
	end
	RecordEvent(player,kind,targetType,turn);
	DeliverPendingNotification(player);
	player:SetProperty("LOTM_WORLD_NEXT_EVENT_TURN",turn+NEXT_MIN+LOTM_WORLD_State.Random(NEXT_SPAN,"next event interval"));
	player:SetProperty("LOTM_PP_ARTIFACT_EFFECT_REFRESH_PENDING",1);
	Log("trigger player="..tostring(player:GetID()).." playerTurn="..tostring(turn).." kind="..kind.." target="..tostring(targetType));
end

local function OnTurn(playerID,isFirstTimeThisTurn)
	if isFirstTimeThisTurn==false or not LOTM_RP_State.IsAnyPathPlayer(playerID) then return; end
	local player=Players[playerID];
	if player==nil or not player:IsHuman() then return; end
	local hero=LOTM_RP_State.FindHero(playerID);
	local started=LOTM_WORLD_State.NumberProperty(player,"LOTM_WORLD_EVENTS_STARTED",0)==1;
	if not started and player:GetProperty("LOTM_WORLD_NEXT_EVENT_TURN")~=nil then started=true; end
	if not started then
		if hero==nil then return; end
		player:SetProperty("LOTM_WORLD_EVENTS_STARTED",1);
	end
	-- rc.81 repair: resend an already-settled event once when the old string
	-- overload produced no visible notification on a live save.
	RepairV87LastEventOnce(player);
	DeliverPendingNotification(player);
	local gameTurn=Game.GetCurrentGameTurn();
	if LOTM_WORLD_State.NumberProperty(player,"LOTM_WORLD_PLAYER_TURN_SETTLED_GAME_TURN",-1)==gameTurn then
		RefreshHolder(player,LOTM_WORLD_State.NumberProperty(player,"LOTM_WORLD_PLAYER_TURN",0));
		return;
	end
	-- Persist before any draw or settlement so reload/reconnect cannot advance twice.
	player:SetProperty("LOTM_WORLD_PLAYER_TURN_SETTLED_GAME_TURN",gameTurn);
	local turn=LOTM_WORLD_State.NextPlayerTurn(player);
	local nextTurn=LOTM_WORLD_State.NumberProperty(player,"LOTM_WORLD_NEXT_EVENT_TURN",nil);
	if nextTurn==nil then
		nextTurn=turn+FIRST_MIN+LOTM_WORLD_State.Random(FIRST_SPAN,"first event interval");
		player:SetProperty("LOTM_WORLD_NEXT_EVENT_TURN",nextTurn);
		Log("scheduled first player="..tostring(playerID).." current="..tostring(turn).." target="..tostring(nextTurn));
	end
	if turn>=nextTurn then Trigger(player,turn); end
	RefreshHolder(player,turn);
end

Events.PlayerTurnActivated.Add(OnTurn);
Log("initialized bag=GGBB duration=5 first=12-18 next=10-16 notifications=USER_DEFINED_6-9");
-- END RC241 MODULE: Scripts/LOTM_WORLD_Events.lua
end;

m_mp241Loaders["LOTM_WORLD_GoodyHuts"] = function()
-- BEGIN POST_RC241_DELTA MODULE: Scripts/LOTM_WORLD_GoodyHuts.lua
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("MP.LOTM_WORLD_GoodyHuts","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"MP.LOTM_WORLD_GoodyHuts","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"MP.LOTM_WORLD_GoodyHuts","GameEvents");
-- END RC342 STARTUP TRACE

-- Authoritative tribal-village gathering settlement.  Firaxis chooses the
-- exclusive subtype before GameEvents.UnitTriggerGoodyHut is raised.
local GATHERING_SUBTYPE :string="GOODYHUT_LOTM_WORLD_GATHERING_REWARD";
local ARTIFACT_CHANCE :number=70;
local ARTIFACT_PRICE :table={[2]=140,[1]=360,[0]=900};
local AI_NORMAL_REWARD :string="GOODY_GOLD_SMALL_MODIFIER";
local ERA_WEIGHTS :table={
 [0]={100,0,0},[1]={90,10,0},[2]={75,25,0},[3]={55,45,0},
 [4]={40,45,15},[5]={30,45,25},[6]={20,45,35},[7]={15,40,45},[8]={10,35,55}
};
local POTIONS :table={
 PATH_RED_PRIEST={[9]="PROJECT_LOTM_RP_PROVOKER_POTION",[8]="PROJECT_LOTM_RP_PYROMANIAC_POTION",[7]="PROJECT_LOTM_RP_CONSPIRATOR_POTION",[6]="PROJECT_LOTM_RP_REAPER_POTION",[5]="PROJECT_LOTM_RP_IRONBLOOD_KNIGHT_POTION",[4]="PROJECT_LOTM_RP_WAR_BISHOP_POTION",[3]="PROJECT_LOTM_RP_WEATHER_WARLOCK_POTION",[2]="PROJECT_LOTM_RP_CONQUEROR_POTION"},
 PATH_PERFECT={[9]="PROJECT_LOTM_PP_ARCHAEOLOGIST_POTION",[8]="PROJECT_LOTM_PP_APPRAISER_POTION",[7]="PROJECT_LOTM_PP_MECHANICAL_EXPERT_POTION",[6]="PROJECT_LOTM_PP_ASTRONOMER_POTION",[5]="PROJECT_LOTM_PP_ALCHEMIST_POTION",[4]="PROJECT_LOTM_PP_MYSTERY_SCHOLAR_POTION",[3]="PROJECT_LOTM_PP_KNOWLEDGE_MENTOR_POTION",[2]="PROJECT_LOTM_PP_ENLIGHTENER_POTION"},
 PATH_BLACK_EMPEROR={[9]="PROJECT_LOTM_BE_BARBARIAN_POTION",[8]="PROJECT_LOTM_BE_BRIBER_POTION",[7]="PROJECT_LOTM_BE_BARON_OF_CORRUPTION_POTION",[6]="PROJECT_LOTM_BE_CHAOS_MENTOR_POTION",[5]="PROJECT_LOTM_BE_COUNT_OF_CORRUPTION_POTION",[4]="PROJECT_LOTM_BE_FRENZY_MAGE_POTION",[3]="PROJECT_LOTM_BE_DUKE_OF_ENTROPY_POTION",[2]="PROJECT_LOTM_BE_PRINCE_OF_ABOLITION_POTION"}
};
-- Rescue Thief projects share the project UI but must never enter the
-- ordinary-mode gathering path.  They are selected only when the rescue
-- runtime gate is active.
local RESCUE_THIEF_POTIONS :table={
 [9]="PROJECT_LOTM_TP_SWINDLER_POTION",[8]="PROJECT_LOTM_TP_CRYPTOLOGIST_POTION",
 [7]="PROJECT_LOTM_TP_PROMETHEUS_POTION",[6]="PROJECT_LOTM_TP_DREAM_STEALER_POTION",
 [5]="PROJECT_LOTM_TP_PARASITE_POTION",[4]="PROJECT_LOTM_TP_MENTOR_OF_DECEIT_POTION",
 [3]="PROJECT_LOTM_TP_FATE_TROJAN_POTION",[2]="PROJECT_LOTM_TP_WORM_OF_TIME_POTION"
};
local ACTIVE_POTIONS_PROPERTY :string="LOTM_WORLD_ACTIVE_POTION_PROJECTS";
local PRODUCTION_SYNC_SIGNATURE :string="LOTM_WORLD_PRODUCTION_SYNC_SIGNATURE";
local TRANSFORMATION_ACTIVE_PROPERTY :string="LOTM_BE_TRANSFORMATION_ACTIVE_SYNC";
local POTION_PROJECTS :table={};
for _,path in ipairs({"PATH_RED_PRIEST","PATH_PERFECT","PATH_BLACK_EMPEROR"}) do
 for sequence=2,9 do
  local projectType=POTIONS[path][sequence];
  if projectType~=nil then POTION_PROJECTS[projectType]=true; end
 end
end

local function Log(value) print("[LOTM_WORLD][Goody] "..tostring(value)); end
local function NumberProperty(object,key,default)
 local value=object~=nil and object:GetProperty(key) or nil;
 if value==nil then return default; end return tonumber(value) or default;
end
local function Human(playerID)
 local player=Players[playerID];
 return player~=nil and player:IsAlive() and player:IsMajor() and player:IsHuman() and player or nil;
end
local function IsRescueMode()
 local state=tonumber(Game.GetProperty("LOTM_RESCUE_MODE") or 0) or 0;
 if state==1 then return true; end
 return LOTM_MP_TurnSync~=nil and LOTM_MP_TurnSync.IsRescueModeConfigured~=nil
  and LOTM_MP_TurnSync.IsRescueModeConfigured() or false;
end
local function Random(maxExclusive,label)
 if maxExclusive==nil or maxExclusive<=0 then return 0; end
 local fullLabel="LOTM_WORLD_GOODY:"..tostring(label);
 return LOTM_MP_TurnSync.Random(maxExclusive,fullLabel,fullLabel);
end
local function CostMultiplier()
 local speed=GameInfo.GameSpeeds[GameConfiguration.GetGameSpeedType()];
 return speed~=nil and (tonumber(speed.CostMultiplier) or 100)/100 or 1;
end
local function RoundNearest10(value) return math.floor((value+5)/10)*10; end
local function RoundUp10(value) return math.ceil(value/10)*10; end
local function Publish(player,item)
 player:SetProperty("LOTM_WORLD_POPUP_KIND","GOODY");
 player:SetProperty("LOTM_WORLD_POPUP_ITEM",item);
 player:SetProperty("LOTM_WORLD_POPUP_SERIAL",NumberProperty(player,"LOTM_WORLD_POPUP_SERIAL",0)+1);
end

local function WeightedLevel(eventKey)
 local era=math.min(8,Game.GetEras():GetCurrentEra() or 0);
 local weights=ERA_WEIGHTS[era] or ERA_WEIGHTS[8]; local legal={}; local total=0;
 for level=2,0,-1 do
  if #LOTM_PP_GetAvailableArtifacts(level,nil)>0 then
   local weight=weights[3-level] or 0; total=total+weight;
   table.insert(legal,{level=level,weight=weight});
  end
 end
 if total<=0 then return nil; end
 local roll=Random(total,"artifact level:"..tostring(eventKey));
 for _,entry in ipairs(legal) do
  if roll<entry.weight then return entry.level; end roll=roll-entry.weight;
 end
 return legal[#legal].level;
end
local function ChooseArtifact(eventKey)
 local level=WeightedLevel(eventKey); if level==nil then return nil; end
 local paths={"RP","PP","BE"}; local available={};
 for _,path in ipairs(paths) do
  if #LOTM_PP_GetAvailableArtifacts(level,path)>0 then table.insert(available,path); end
 end
 if #available==0 then return nil; end
 local path=available[Random(#available,"artifact path:"..tostring(eventKey)..":level="..tostring(level))+1];
 local pool=LOTM_PP_GetAvailableArtifacts(level,path);
 return pool[Random(#pool,"artifact item:"..tostring(eventKey)..":level="..tostring(level)..":path="..tostring(path))+1];
end
local function IsProjectInProduction(player,projectType)
 local project=projectType~=nil and GameInfo.Projects[projectType] or nil;
 if player==nil or project==nil then return false; end
 local active=tostring(player:GetProperty(ACTIVE_POTIONS_PROPERTY) or "");
 return string.find("|"..active.."|","|"..projectType.."|",1,true)~=nil;
end
local function PotionFor(player)
 local sequence=NumberProperty(player,"LOTM_RP_SEQUENCE",9);
 local path=player:GetProperty("LOTM_RP_PATH");
 local potionMap=(path=="PATH_THIEF" and IsRescueMode()) and RESCUE_THIEF_POTIONS or POTIONS[path];
 local projectType=potionMap and potionMap[sequence] or nil;
 local project=projectType~=nil and GameInfo.Projects[projectType] or nil;
 if project==nil or sequence<=1
  or player:GetProperty("LOTM_WORLD_PURCHASED_POTION_SEQUENCE")~=nil
  or IsProjectInProduction(player,projectType) then return nil; end
 return {ProjectType=projectType,Sequence=sequence,
  Price=RoundUp10((tonumber(project.Cost) or 0)*0.8*CostMultiplier())};
end
local function SetOffer(player,plot,kind,item,level,path,price)
 local serial=NumberProperty(player,"LOTM_WORLD_GOODY_OFFER_SERIAL",0)+1;
 player:SetProperty("LOTM_WORLD_GOODY_OFFER_SERIAL",serial);
 player:SetProperty("LOTM_WORLD_GOODY_OFFER_SETTLED",0);
 player:SetProperty("LOTM_WORLD_GOODY_OFFER_PLOT",plot:GetIndex());
 player:SetProperty("LOTM_WORLD_GOODY_OFFER_TYPE",kind);
 player:SetProperty("LOTM_WORLD_GOODY_OFFER_ID",item);
 player:SetProperty("LOTM_WORLD_GOODY_OFFER_LEVEL",level);
 player:SetProperty("LOTM_WORLD_GOODY_OFFER_PATH",path);
 player:SetProperty("LOTM_WORLD_GOODY_OFFER_PRICE",price);
 plot:SetProperty("LOTM_WORLD_GOODY_RESOLVED","EXTRAORDINARY");
 Publish(player,item);
end
local function CreateOffer(player,plot)
 local eventKey="player="..tostring(player:GetID())..":plot="..tostring(plot:GetIndex())
  ..":offer="..tostring(NumberProperty(player,"LOTM_WORLD_GOODY_OFFER_SERIAL",0)+1);
 local artifact=Random(100,"offer type:"..eventKey)<ARTIFACT_CHANCE and ChooseArtifact(eventKey..":primary") or nil;
 if artifact~=nil then
  SetOffer(player,plot,"ARTIFACT",artifact.ArtifactType,artifact.Level,artifact.Path,
   RoundNearest10(ARTIFACT_PRICE[artifact.Level]*CostMultiplier())); return true;
 end
 local potion=PotionFor(player);
 if potion~=nil then
  SetOffer(player,plot,"POTION",potion.ProjectType,potion.Sequence-1,
   player:GetProperty("LOTM_RP_PATH"),potion.Price); return true;
 end
 artifact=ChooseArtifact(eventKey..":fallback");
 if artifact~=nil then
  SetOffer(player,plot,"ARTIFACT",artifact.ArtifactType,artifact.Level,artifact.Path,
   RoundNearest10(ARTIFACT_PRICE[artifact.Level]*CostMultiplier())); return true;
 end
 return false;
end
local function GrantOrdinaryFallback(player)
 player:AttachModifierByID(AI_NORMAL_REWARD);
end
local function OnUnitTriggerGoodyHut(playerID,unitID,goodyHutType)
 local gathering=GameInfo.GoodyHutSubTypes[GATHERING_SUBTYPE];
 if gathering==nil or goodyHutType~=gathering.Index then return; end
 local player=Players[playerID]; local unit=player~=nil and player:GetUnits():FindID(unitID) or nil;
 local plot=unit~=nil and Map.GetPlot(unit:GetX(),unit:GetY()) or nil;
 if player==nil or plot==nil or plot:GetProperty("LOTM_WORLD_GOODY_RESOLVED")~=nil then return; end
 if not player:IsHuman() then
  plot:SetProperty("LOTM_WORLD_GOODY_RESOLVED","NORMAL_AI"); GrantOrdinaryFallback(player); return;
 end
 if not CreateOffer(player,plot) then
  plot:SetProperty("LOTM_WORLD_GOODY_RESOLVED","NORMAL_FALLBACK"); GrantOrdinaryFallback(player);
 end
end
local function OnCommand(playerID,parameters)
 local player=Human(playerID); if player==nil or parameters==nil then return; end
 local serial=tonumber(parameters.Serial) or -1;
 if serial~=NumberProperty(player,"LOTM_WORLD_GOODY_OFFER_SERIAL",-2)
  or player:GetProperty("LOTM_WORLD_GOODY_OFFER_SETTLED")==1 then return; end
 if parameters.Action=="LEAVE" then player:SetProperty("LOTM_WORLD_GOODY_OFFER_SETTLED",1); return; end
 if parameters.Action~="BUY" then return; end
 local kind=player:GetProperty("LOTM_WORLD_GOODY_OFFER_TYPE");
 local item=player:GetProperty("LOTM_WORLD_GOODY_OFFER_ID");
 local price=NumberProperty(player,"LOTM_WORLD_GOODY_OFFER_PRICE",-1);
 local treasury=player:GetTreasury(); local balanceBefore=treasury:GetGoldBalance(); local charged=false;
 if price<0 or balanceBefore<price then
  Log("rejected purchase insufficient gold player="..tostring(playerID).." price="..tostring(price).." balance="..tostring(balanceBefore)); return;
 end
 if kind=="ARTIFACT" then
  if not LOTM_PP_GrantSpecificArtifact(playerID,item) then return; end
 elseif kind=="POTION" then
  local sequence=NumberProperty(player,"LOTM_RP_SEQUENCE",9); local expected=PotionFor(player);
  if expected==nil or expected.ProjectType~=item or expected.Price~=price or sequence<=1 then
   Log("rejected potion purchase player="..tostring(playerID).." serial="..tostring(serial)
    .." reason=stale-or-project-in-production"); return;
  end
  -- Charge first so a successful sequence advance can never be free.  The
  -- exact amount is refunded if the authoritative advancement check fails.
  treasury:ChangeGoldBalance(-price); charged=true;
  if not LOTM_RP_State.RegisterPurchasedPotion(playerID,sequence,item,serial) then
   treasury:ChangeGoldBalance(price);
   Log("rejected potion registration and refunded player="..tostring(playerID).." sequence="..tostring(sequence)
    .." price="..tostring(price).." balance="..tostring(treasury:GetGoldBalance())); return;
  end
  Log("potion purchased and stored player="..tostring(playerID).." sequence="..tostring(sequence)
   .." project="..tostring(item).." digestion="
   ..tostring(NumberProperty(player,"LOTM_RP_DIGEST_A",0)+NumberProperty(player,"LOTM_RP_DIGEST_B",0)));
 else return; end
 if not charged then treasury:ChangeGoldBalance(-price); end
 player:SetProperty("LOTM_WORLD_GOODY_OFFER_SETTLED",1);
 Log("purchase settled player="..tostring(playerID).." kind="..tostring(kind).." item="..tostring(item)
  .." price="..tostring(price).." balance="..tostring(balanceBefore).."->"..tostring(treasury:GetGoldBalance()));
end

-- BuildQueue's current-production query is UI-only.  The local UI reports a
-- canonical, validated snapshot through EXECUTE_SCRIPT; Gameplay owns and
-- persists the resulting properties used by gatherings and Black Emperor.
local function OnProductionSync(playerID,parameters)
 local player=Human(playerID); if player==nil or parameters==nil then return; end
 local raw=tostring(parameters.PotionProjects or "");
 if raw=="NONE" or raw=="0" then raw=""; end
 if #raw>2048 then Log("rejected production sync player="..tostring(playerID).." reason=oversize"); return; end
 local seen={}; local active={};
 for projectType in string.gmatch(raw,"[^|]+") do
  local rescueAllowed=IsRescueMode() and player:GetProperty("LOTM_RP_PATH")=="PATH_THIEF"
   and RESCUE_THIEF_POTIONS[tonumber(player:GetProperty("LOTM_RP_SEQUENCE") or 9)]==projectType;
  if (not POTION_PROJECTS[projectType] and not rescueAllowed) or GameInfo.Projects[projectType]==nil then
   Log("rejected production sync player="..tostring(playerID).." project="..tostring(projectType)); return;
  end
  if not seen[projectType] then seen[projectType]=true; table.insert(active,projectType); end
 end
 table.sort(active);
 local canonical=table.concat(active,"|");
 local transformation=tonumber(parameters.TransformationActive)==1 and 1 or 0;
 player:SetProperty(ACTIVE_POTIONS_PROPERTY,canonical);
 player:SetProperty(TRANSFORMATION_ACTIVE_PROPERTY,transformation);
 player:SetProperty(PRODUCTION_SYNC_SIGNATURE,canonical.."#"..tostring(transformation));
 Log("production sync player="..tostring(playerID).." potions="..canonical
  .." transformation="..tostring(transformation));
end

GameEvents.UnitTriggerGoodyHut.Add(OnUnitTriggerGoodyHut);
GameEvents.LOTM_WORLD_Command_GoodyOffer.Add(OnCommand);
GameEvents.LOTM_WORLD_Command_ProductionSync.Add(OnProductionSync);
-- Lifecycle initializes before this module. Reconcile paid entitlements once
-- more after the gathering command layer is loaded so rc.89 read saves cannot
-- remain stuck until another digestion-producing event occurs.
LOTM_MP_TurnSync.RunStartup(function()
 for _,playerID in ipairs(PlayerManager.GetAliveMajorIDs()) do
  LOTM_RP_State.TryConsumePurchasedPotion(playerID);
 end
end,"WorldGoodyHuts");
Log("initialized exclusive normal=65 gathering=35 artifact=70 potion=30");
-- END POST_RC241_DELTA MODULE: Scripts/LOTM_WORLD_GoodyHuts.lua
end;

m_mp241Loaders["LOTM_WORLD_Monsters"] = function()
-- BEGIN POST_RC241_DELTA MODULE: Scripts/LOTM_WORLD_Monsters.lua
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("MP.LOTM_WORLD_Monsters","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"MP.LOTM_WORLD_Monsters","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"MP.LOTM_WORLD_Monsters","GameEvents");
-- END RC342 STARTUP TRACE

-- rc.82 synchronized uncontrolled monsters. UI is deliberately not authoritative.
LOTM_MP241_LoadBundledModule("LOTM_Effects");
LOTM_WORLD_Monsters = LOTM_WORLD_Monsters or {};

local TIER_CHANCE={[2]=30,[1]=30,[0]=30};
local TIER_BONUS={[2]=15,[1]=25,[0]=35};
local TIER_MOVES={[2]=3,[1]=4,[0]=4};
local TIER_HEAL={[2]=10,[1]=10,[0]=10};
local REWARD_GOLD_PER_ERA :number=500;
local TIER_NAME={[2]="LOC_LOTM_WORLD_MONSTER_LOW_NAME",[1]="LOC_LOTM_WORLD_MONSTER_MID_NAME",[0]="LOC_LOTM_WORLD_MONSTER_HIGH_NAME"};
local MAP_CAP={MAPSIZE_DUEL=1,MAPSIZE_TINY=2,MAPSIZE_SMALL=2,MAPSIZE_STANDARD=3,MAPSIZE_LARGE=4,MAPSIZE_HUGE=5};
local STRENGTH_ABILITY="ABILITY_LOTM_WORLD_MONSTER_FRENZY_STRENGTH_V2";
local TIER_STRENGTH_ABILITIES={{1,"ABILITY_LOTM_WORLD_MONSTER_TIER_MID_STRENGTH"},{0,"ABILITY_LOTM_WORLD_MONSTER_TIER_HIGH_STRENGTH"}};
local LEGACY_STRENGTH_ABILITY="ABILITY_LOTM_WORLD_DYNAMIC_STRENGTH";
local LEGACY_FRENZY_ABILITY="ABILITY_LOTM_WORLD_MONSTER_FRENZY_STRENGTH";
local MOVEMENT_ABILITIES={{1,"ABILITY_LOTM_WORLD_DYNAMIC_MOVEMENT"},{2,"ABILITY_LOTM_WORLD_DYNAMIC_MOVEMENT_2"}};
local RESCUE_WEATHER_ABILITY="ABILITY_LOTM_RESCUE_WEATHER_MONSTER_DEBUFF";
local EFFECT_VERSION_PROPERTY="LOTM_WORLD_MONSTER_EFFECT_VERSION";
local CURRENT_EFFECT_VERSION=7;
local MONSTER_TIER="LOTM_WORLD_MONSTER_TIER";
local MONSTER_SERIAL="LOTM_WORLD_MONSTER_SERIAL";
local MONSTER_SOURCE="LOTM_WORLD_MONSTER_SOURCE_WORKSHOP";
local MONSTER_SOURCE_CAMP_EPOCH="LOTM_WORLD_MONSTER_SOURCE_CAMP_EPOCH";
local PERIOD_BONUS_PROPERTY="LOTM_RESCUE_PHASE5_BIRTH_BONUS";
local TARGET_KIND_PROPERTY="LOTM_WORLD_MONSTER_LOCKED_TARGET_KIND";
local TARGET_OWNER_PROPERTY="LOTM_WORLD_MONSTER_LOCKED_TARGET_OWNER";
local TARGET_ID_PROPERTY="LOTM_WORLD_MONSTER_LOCKED_TARGET_ID";
local REDEPLOYED_TURN_PROPERTY="LOTM_WORLD_MONSTER_REDEPLOYED_TURN";
local REDEPLOY_DISTANCE=12;
local REDEPLOY_TARGET_MIN_DISTANCE=5;
local REDEPLOY_TARGET_MAX_DISTANCE=12;
local PERIOD_STRENGTH_ABILITIES={
	{10,"ABILITY_LOTM_RESCUE_PERIOD_STRENGTH_10"},
	{20,"ABILITY_LOTM_RESCUE_PERIOD_STRENGTH_20"},
	{30,"ABILITY_LOTM_RESCUE_PERIOD_STRENGTH_30"},
	{40,"ABILITY_LOTM_RESCUE_PERIOD_STRENGTH_40"}
};
local questResolver=nil;
local creatingMonster=false;
local playerHuntCacheTurn=-1;
local playerHuntCache=false;
local CAMP=GameInfo.Improvements.IMPROVEMENT_BARBARIAN_CAMP.Index;
-- UnitRemovedFromMap is only a local publication callback in a network game.
-- It may collect evidence, but Release/SettleReward must wait for the one
-- synchronized, lowest-major turn boundary shared by every peer.
local networkRemovalQueue={};
local networkRemovalBySerial={};
local ACTIVE_MONSTER_SERIALS="LOTM_WORLD_MONSTER_ACTIVE_SERIALS";
local ACTIVE_MONSTER_INDEX_VERSION="LOTM_WORLD_MONSTER_ACTIVE_INDEX_VERSION";
local CURRENT_ACTIVE_MONSTER_INDEX_VERSION=1;

local function Log(message)
	print("[LOTM_WORLD][Monsters] "..tostring(message));
end
local function Verbose()
	return tonumber(Game.GetProperty("LOTM_RESCUE_VERBOSE_LOGS") or 0)==1;
end
local function Trace(message)
	if Verbose() then Log(message); end
end

local function BarbarianID()
	for _,player in ipairs(PlayerManager.GetAliveBarbarians()) do return player:GetID(); end
	return -1;
end

local function NumberProperty(object,key,default)
	return LOTM_WORLD_State.NumberProperty(object,key,default);
end
local function RescueActive()
	return LOTM_RESCUE_Phase5~=nil and LOTM_RESCUE_Phase5.IsActive~=nil and LOTM_RESCUE_Phase5.IsActive();
end
local function MonsterChance(tier)
	return RescueActive() and LOTM_RESCUE_Phase5.MonsterChance() or TIER_CHANCE[tier];
end
local function MonsterCooldown()
	return RescueActive() and LOTM_RESCUE_Phase5.MonsterCooldown() or 10;
end
local function MonsterPerWorkshopCap()
	return RescueActive() and LOTM_RESCUE_Phase5.MonsterPerWorkshopCap() or 1;
end
local function MonsterBurst()
	return RescueActive() and LOTM_RESCUE_Phase5.MonsterBurst~=nil and LOTM_RESCUE_Phase5.MonsterBurst() or 1;
end
local function BirthPeriodBonus()
	return RescueActive() and LOTM_RESCUE_Phase5.BirthStrengthBonus() or 0;
end

local function IncrementProperty(object,key)
	local value=NumberProperty(object,key,0)+1;
	object:SetProperty(key,value);
	return value;
end

local function IncrementGame(key)
	local value=LOTM_WORLD_State.NumberGameProperty(key,0)+1;
	Game.SetProperty(key,value);
	return value;
end

local function EngineKey(ownerID,unitID)
	return "LOTM_WORLD_MONSTER_ENGINE:"..tostring(ownerID)..":"..tostring(unitID);
end

local function MetaKey(serial,suffix)
	return "LOTM_WORLD_MONSTER:"..tostring(serial)..":"..suffix;
end

local function ActiveMonsterSerials()
	local result={}; local seen={};
	for token in string.gmatch(tostring(Game.GetProperty(ACTIVE_MONSTER_SERIALS) or ""),"[^,]+") do
		local serial=tonumber(token);
		if serial~=nil and serial>0 and not seen[serial] then
			seen[serial]=true; result[#result+1]=serial;
		end
	end
	table.sort(result);
	return result;
end

local function SaveActiveMonsterSerials(serials)
	local values={};
	for _,serial in ipairs(serials) do values[#values+1]=tostring(serial); end
	local serialized=table.concat(values,",");
	if tostring(Game.GetProperty(ACTIVE_MONSTER_SERIALS) or "")~=serialized then
		Game.SetProperty(ACTIVE_MONSTER_SERIALS,serialized);
	end
end

local function SetPropertyIfChanged(object,key,value)
	if object~=nil and object:GetProperty(key)~=value then object:SetProperty(key,value); end
end

local function RegisterActiveMonsterSerial(serial)
	local normalized=tonumber(serial); if normalized==nil or normalized<=0 then return; end
	local serials=ActiveMonsterSerials(); local found=false;
	for _,value in ipairs(serials) do if value==normalized then found=true; break; end end
	if not found then serials[#serials+1]=normalized; table.sort(serials); SaveActiveMonsterSerials(serials); end
end

local function RemoveActiveMonsterSerial(serial)
	local normalized=tonumber(serial); if normalized==nil or normalized<=0 then return; end
	local remaining={};
	for _,value in ipairs(ActiveMonsterSerials()) do
		if value~=normalized then remaining[#remaining+1]=value; end
	end
	SaveActiveMonsterSerials(remaining);
end

local function MigrateActiveMonsterIndex()
	if LOTM_WORLD_State.NumberGameProperty(ACTIVE_MONSTER_INDEX_VERSION,0)>=CURRENT_ACTIVE_MONSTER_INDEX_VERSION then return; end
	local serials=ActiveMonsterSerials(); local seen={};
	for _,serial in ipairs(serials) do seen[serial]=true; end
	local lastSerial=math.max(0,LOTM_WORLD_State.NumberGameProperty("LOTM_WORLD_MONSTER_NEXT_SERIAL",0));
	for serial=1,lastSerial do
		if LOTM_WORLD_State.NumberGameProperty(MetaKey(serial,"LIVE"),0)==1 and not seen[serial] then
			seen[serial]=true; serials[#serials+1]=serial;
		end
	end
	table.sort(serials); SaveActiveMonsterSerials(serials);
	Game.SetProperty(ACTIVE_MONSTER_INDEX_VERSION,CURRENT_ACTIVE_MONSTER_INDEX_VERSION);
	Log("active index migrated version="..CURRENT_ACTIVE_MONSTER_INDEX_VERSION.." scannedSerials="..lastSerial.." active="..#serials);
end

local function CurrentEraIndex()
	if Game.GetEras==nil then return 0; end
	local eras=Game.GetEras();
	if eras==nil or eras.GetCurrentEra==nil then return 0; end
	local currentEra=eras:GetCurrentEra();
	return tonumber(currentEra) or 0;
end

local function IsLegalWilderness(plot,requireEmpty)
	if plot==nil or plot:IsWater() or plot:GetOwner()>=0 or plot:IsCity() then return false; end
	if plot:GetDistrictType()>=0 then return false; end
	if requireEmpty and plot:GetUnitCount()>0 then return false; end
	return true;
end

local function MapCap()
	local mapInfo=GameInfo.Maps[Map.GetMapSize()];
	local mapSizeType=mapInfo~=nil and mapInfo.MapSizeType or "MAPSIZE_STANDARD";
	if RescueActive() and LOTM_RESCUE_Phase5.MonsterGlobalCap~=nil then return LOTM_RESCUE_Phase5.MonsterGlobalCap(),mapSizeType; end
	local base=MAP_CAP[mapSizeType] or 3;
	local multiplier=RescueActive() and LOTM_RESCUE_Phase5.GlobalCapMultiplier() or 1;
	return math.max(1,math.floor(base*multiplier)),mapSizeType;
end

function LOTM_WORLD_Monsters.IsMonster(unit)
	return unit~=nil and NumberProperty(unit,MONSTER_TIER,-1)>=0 and NumberProperty(unit,MONSTER_SERIAL,0)>0;
end

function LOTM_WORLD_Monsters.IsCreating()
	return creatingMonster;
end

function LOTM_WORLD_Monsters.RegisterQuestResolver(callback)
	questResolver=type(callback)=="function" and callback or nil;
end

local function ApplyAbilityCount(unit,abilityType,desired)
	if GameInfo.UnitAbilities[abilityType]==nil then return desired==0; end
	local ability=unit~=nil and unit:GetAbility() or nil;
	if ability==nil then return false; end
	LOTM_Effects.SetAbilityCount(ability,abilityType,desired);
	return (ability:GetAbilityCount(abilityType) or 0)==desired;
end

local function ApplyMonsterAbilities(unit,tier,moveDelta,periodBonus)
	if NumberProperty(unit,EFFECT_VERSION_PROPERTY,0)<CURRENT_EFFECT_VERSION then
		local ability=unit~=nil and unit:GetAbility() or nil;
		if ability~=nil then
			local rebuild={LEGACY_STRENGTH_ABILITY,LEGACY_FRENZY_ABILITY,STRENGTH_ABILITY,TIER_STRENGTH_ABILITIES[1][2],TIER_STRENGTH_ABILITIES[2][2],MOVEMENT_ABILITIES[1][2],MOVEMENT_ABILITIES[2][2],PERIOD_STRENGTH_ABILITIES[1][2],PERIOD_STRENGTH_ABILITIES[2][2],PERIOD_STRENGTH_ABILITIES[3][2],PERIOD_STRENGTH_ABILITIES[4][2],RESCUE_WEATHER_ABILITY};
			for _,abilityType in ipairs(rebuild) do
				if GameInfo.UnitAbilities[abilityType]~=nil then LOTM_Effects.SetAbilityCount(ability,abilityType,0); end
			end
		end
		unit:SetProperty(TARGET_KIND_PROPERTY,nil); unit:SetProperty(TARGET_OWNER_PROPERTY,nil); unit:SetProperty(TARGET_ID_PROPERTY,nil);
		unit:SetProperty(EFFECT_VERSION_PROPERTY,CURRENT_EFFECT_VERSION);
		Log("rebuilt effects serial="..NumberProperty(unit,MONSTER_SERIAL,0).." version="..CURRENT_EFFECT_VERSION);
	end
	ApplyAbilityCount(unit,STRENGTH_ABILITY,1);
	for _,entry in ipairs(TIER_STRENGTH_ABILITIES) do
		ApplyAbilityCount(unit,entry[2],entry[1]==tier and 1 or 0);
	end
	for _,entry in ipairs(MOVEMENT_ABILITIES) do
		ApplyAbilityCount(unit,entry[2],entry[1]==moveDelta and 1 or 0);
	end
	for _,entry in ipairs(PERIOD_STRENGTH_ABILITIES) do
		ApplyAbilityCount(unit,entry[2],entry[1]==periodBonus and 1 or 0);
	end
	ApplyAbilityCount(unit,RESCUE_WEATHER_ABILITY,RescueActive() and NumberProperty(Game,"LOTM_RESCUE_ARTIFACT_WEATHER_ACTIVE",0)==1 and 1 or 0);
	if LOTM_RESCUE_RuntimeEvents~=nil then LOTM_RESCUE_RuntimeEvents.ApplyEarlySeal(unit); end
end

local function LiveMonsters()
	local result={};
	local activeSerials=ActiveMonsterSerials(); local activeSeen={};
	for _,serial in ipairs(activeSerials) do activeSeen[serial]=true; end
	local barbarianID=BarbarianID();
	local player=barbarianID>=0 and Players[barbarianID] or nil;
	if player==nil then return result; end
	for _,unit in player:GetUnits():Members() do
		if LOTM_WORLD_Monsters.IsMonster(unit) then
			table.insert(result,unit);
			local serial=NumberProperty(unit,MONSTER_SERIAL,0);
			local tier=NumberProperty(unit,MONSTER_TIER,2);
			local source=NumberProperty(unit,MONSTER_SOURCE,-1);
			local baseline=NumberProperty(unit,"LOTM_WORLD_MONSTER_BASELINE",0);
			SetPropertyIfChanged(Game,MetaKey(serial,"LIVE"),1);
			SetPropertyIfChanged(Game,MetaKey(serial,"OWNER"),unit:GetOwner());
			SetPropertyIfChanged(Game,MetaKey(serial,"UNIT_ID"),unit:GetID());
			SetPropertyIfChanged(Game,MetaKey(serial,"TIER"),tier);
			SetPropertyIfChanged(Game,MetaKey(serial,"SOURCE"),source);
			SetPropertyIfChanged(Game,MetaKey(serial,"BASELINE"),baseline);
			local sourceEpoch=unit:GetProperty(MONSTER_SOURCE_CAMP_EPOCH);
			if sourceEpoch~=nil then SetPropertyIfChanged(Game,MetaKey(serial,"SOURCE_CAMP_EPOCH"),sourceEpoch); end
			SetPropertyIfChanged(Game,EngineKey(unit:GetOwner(),unit:GetID()),serial);
			if not activeSeen[serial] then activeSeen[serial]=true; activeSerials[#activeSerials+1]=serial; end
		end
	end
	table.sort(result,function(a,b) return NumberProperty(a,MONSTER_SERIAL,0)<NumberProperty(b,MONSTER_SERIAL,0); end);
	table.sort(activeSerials); SaveActiveMonsterSerials(activeSerials);
	SetPropertyIfChanged(Game,"LOTM_WORLD_MONSTER_LIVE_COUNT",#result);
	return result;
end

local function FindSpawnPlot(camp)
	local maximumRadius=RescueActive() and 3 or 2;
	for radius=1,maximumRadius do
		local candidates={};
		for dx=-radius,radius do for dy=-radius,radius do
			local plot=Map.GetPlotXYWithRangeCheck(camp:GetX(),camp:GetY(),dx,dy,radius);
			if IsLegalWilderness(plot,true) and plot:GetImprovementType()<0 then table.insert(candidates,plot); end
		end end
		table.sort(candidates,function(a,b) return a:GetIndex()<b:GetIndex(); end);
		if #candidates>0 then return candidates[1]; end
	end
	return nil;
end

local function Suppress(camp,tier,reason)
	IncrementProperty(camp,"LOTM_WORLD_MONSTER_SUPPRESSED_"..reason);
	IncrementGame("LOTM_WORLD_MONSTER_TIER_"..tier.."_SUPPRESSED_"..reason);
	if reason=="NO_PLOT" or reason=="NO_BASELINE" or reason=="INIT_FAILED" then
		Log("check suppressed reason="..reason.." tier="..tier.." camp="..camp:GetIndex());
	else
		Trace("check suppressed reason="..reason.." tier="..tier.." camp="..camp:GetIndex());
	end
	return false,reason;
end
local function LiveFromWorkshop(live,campIndex)
	local count=0;
	for _,unit in ipairs(live) do if NumberProperty(unit,MONSTER_SOURCE,-1)==campIndex then count=count+1; end end
	return count;
end

local function TrySpawnOne(camp,sourceUnit,periodic,networkSourceOwner,batch)
	if camp==nil or camp:GetImprovementType()~=CAMP or NumberProperty(camp,"LOTM_PP_WORKSHOP_IS_WORKSHOP",0)~=1 then return false,"INVALID"; end
	if not periodic then
		if sourceUnit==nil and networkSourceOwner==nil then return false,"INVALID"; end
		if sourceUnit~=nil then
			if LOTM_WORLD_Monsters.IsMonster(sourceUnit) or NumberProperty(sourceUnit,"LOTM_PP_WORKSHOP_EXTRA",0)==1 or NumberProperty(sourceUnit,"LOTM_PP_WORKSHOP_SEQUENCE",0)==1 then return false,"NOT_NORMAL"; end
			if NumberProperty(sourceUnit,"LOTM_PP_WORKSHOP_SOURCE",-1)~=camp:GetIndex() then return false,"SOURCE_MISMATCH"; end
		end
	end
	local tier=NumberProperty(camp,"LOTM_PP_WORKSHOP_LEVEL",2);
	if TIER_CHANCE[tier]==nil then tier=2; end
	local turn=Game.GetCurrentGameTurn();
	if turn<NumberProperty(camp,"LOTM_WORLD_WORKSHOP_MONSTER_COOLDOWN_UNTIL",-1) then return Suppress(camp,tier,"COOLDOWN"); end
	local live=batch~=nil and batch.Live or LiveMonsters(); local cap=batch~=nil and batch.Cap or MapCap();
	if #live>=cap then return Suppress(camp,tier,"CAP"); end
	local sourceLive=LiveFromWorkshop(live,camp:GetIndex()); local sourceCap=MonsterPerWorkshopCap();
	if sourceLive>=sourceCap then return Suppress(camp,tier,"LIVE"); end
	local spawnPlot=FindSpawnPlot(camp);
	if spawnPlot==nil then return Suppress(camp,tier,"NO_PLOT"); end
	local ownerID=periodic and BarbarianID() or (sourceUnit~=nil and sourceUnit:GetOwner() or networkSourceOwner);
	local baseline=batch~=nil and batch.Baseline or LOTM_WORLD_Barbarians.ResolveMeleeBaseline(ownerID);
	if baseline==nil then return Suppress(camp,tier,"NO_BASELINE"); end
	local rollOrdinal=IncrementProperty(camp,"LOTM_WORLD_MONSTER_ELIGIBLE_CHECKS");
	IncrementGame("LOTM_WORLD_MONSTER_TIER_"..tier.."_ELIGIBLE_CHECKS");
	local roll=LOTM_WORLD_State.Random(100,"monster tier="..tier
		.." camp="..camp:GetIndex().." ordinal="..tostring(rollOrdinal)
		.." periodic="..tostring(periodic==true));
	camp:SetProperty("LOTM_WORLD_MONSTER_LAST_ROLL",roll);
	IncrementProperty(camp,"LOTM_WORLD_MONSTER_ROLLS");
	IncrementGame("LOTM_WORLD_MONSTER_TIER_"..tier.."_ROLLS");
	local chance=MonsterChance(tier);
	Trace("roll tier="..tier.." camp="..camp:GetIndex().." value="..roll.." chance="..chance.." sourceLive="..sourceLive.." sourceCap="..sourceCap.." globalCap="..cap);
	if roll>=chance then return false,"ROLL_MISS"; end
	IncrementProperty(camp,"LOTM_WORLD_MONSTER_ROLL_HITS");
	IncrementGame("LOTM_WORLD_MONSTER_TIER_"..tier.."_ROLL_HITS");
	creatingMonster=true;
	local initOK,unit=pcall(UnitManager.InitUnit,ownerID,baseline.Index,spawnPlot:GetX(),spawnPlot:GetY());
	creatingMonster=false;
	if not initOK then unit=nil; end
	if unit==nil then return Suppress(camp,tier,"INIT_FAILED"); end
	local serial=IncrementGame("LOTM_WORLD_MONSTER_NEXT_SERIAL");
	local periodBonus=BirthPeriodBonus();
	local targetStrength=baseline.Combat+TIER_BONUS[tier]+periodBonus;
	local strengthDelta=math.max(0,targetStrength-(tonumber(GameInfo.Units[unit:GetType()].Combat) or baseline.Combat));
	local moveDelta=math.max(0,TIER_MOVES[tier]-(tonumber(GameInfo.Units[unit:GetType()].BaseMoves) or baseline.BaseMoves));
	local sourceCampEpoch=camp:GetProperty("LOTM_PP_WORKSHOP_CAMP_EPOCH");
	unit:SetProperty(MONSTER_TIER,tier); unit:SetProperty(MONSTER_SERIAL,serial); unit:SetProperty(MONSTER_SOURCE,camp:GetIndex()); unit:SetProperty(PERIOD_BONUS_PROPERTY,periodBonus);
	if sourceCampEpoch~=nil then unit:SetProperty(MONSTER_SOURCE_CAMP_EPOCH,sourceCampEpoch); end
	unit:SetProperty("LOTM_WORLD_MONSTER_BASELINE",baseline.Combat); unit:SetProperty("LOTM_WORLD_MONSTER_UNIT_TYPE",baseline.UnitType);
	unit:SetProperty("LOTM_WORLD_MONSTER_TARGET_STRENGTH",targetStrength); unit:SetProperty("LOTM_WORLD_MONSTER_TARGET_MOVES",TIER_MOVES[tier]);
	-- Commit the recoverable identity before optional cross-module, ability, or
	-- presentation work. LiveMonsters can reconstruct every core field from the
	-- unit if an interruption occurs after this point.
	camp:SetProperty("LOTM_WORLD_WORKSHOP_MONSTER_SERIAL",serial);
	Game.SetProperty(MetaKey(serial,"LIVE"),1); Game.SetProperty(MetaKey(serial,"OWNER"),unit:GetOwner()); Game.SetProperty(MetaKey(serial,"UNIT_ID"),unit:GetID());
	Game.SetProperty(MetaKey(serial,"TIER"),tier); Game.SetProperty(MetaKey(serial,"SOURCE"),camp:GetIndex()); Game.SetProperty(MetaKey(serial,"BASELINE"),baseline.Combat);
	if sourceCampEpoch~=nil then Game.SetProperty(MetaKey(serial,"SOURCE_CAMP_EPOCH"),sourceCampEpoch); end
	Game.SetProperty(EngineKey(unit:GetOwner(),unit:GetID()),serial);
	if batch~=nil then
		batch.Live[#batch.Live+1]=unit;
		if not batch.ActiveSeen[serial] then batch.ActiveSeen[serial]=true; batch.ActiveSerials[#batch.ActiveSerials+1]=serial; end
	else
		RegisterActiveMonsterSerial(serial);
	end
	-- InitUnit publishes UnitAddedToMap before it returns.  Backfill the
	-- already-enqueued Workshops evidence as soon as this durable monster
	-- identity exists, without relying on the client-local IsCreating flag.
	if LOTM_PP_Workshops~=nil and type(LOTM_PP_Workshops.MarkNetworkUnitFiltered)=="function" then
		LOTM_PP_Workshops.MarkNetworkUnitFiltered(unit);
	end
	ApplyMonsterAbilities(unit,tier,moveDelta,periodBonus);
	local experience=unit:GetExperience(); if experience~=nil then
		experience:SetExperienceLocked(true);
		local veteranName=LOTM_MP_TurnSync.IsNetworkGame() and ("LOTM_WORLD_MONSTER_"..tostring(tier)) or Locale.Lookup(TIER_NAME[tier]);
		experience:SetVeteranName(veteranName);
	end
	IncrementProperty(camp,"LOTM_WORLD_MONSTER_SPAWNED"); IncrementGame("LOTM_WORLD_MONSTER_TIER_"..tier.."_SPAWNED");
	if batch==nil then SetPropertyIfChanged(Game,"LOTM_WORLD_MONSTER_LIVE_COUNT",#live+1); end
	UnitManager.FinishMoves(unit);
	Log("spawned serial="..serial.." tier="..tier.." camp="..camp:GetIndex().." unit="..baseline.UnitType.." B="..baseline.Combat.." periodBonus="..periodBonus.." target="..targetStrength);
	return true,"SPAWNED";
end

function LOTM_WORLD_Monsters.TrySpawnFromWorkshop(camp,sourceUnit)
	local rawBurst=math.max(1,MonsterBurst());
	local burst=RescueActive() and LOTM_RESCUE_Phase5~=nil and LOTM_RESCUE_Phase5.ScaleMonsterSpawnCount~=nil
		and LOTM_RESCUE_Phase5.ScaleMonsterSpawnCount(rawBurst,"WORKSHOP_EVENT",LOTM_RESCUE_Phase5.WorldTurn()) or rawBurst;
	local spawned=0; local lastReason=burst>0 and "NONE" or "RATE_REDUCED";
	for attempt=1,burst do
		local success,reason=TrySpawnOne(camp,sourceUnit,false); lastReason=reason;
		if success then spawned=spawned+1; end
		if reason=="INVALID" or reason=="NOT_NORMAL" or reason=="SOURCE_MISMATCH" or reason=="COOLDOWN" or reason=="CAP" or reason=="LIVE" or reason=="NO_PLOT" or reason=="NO_BASELINE" or reason=="INIT_FAILED" then break; end
	end
	Trace("burst camp="..tostring(camp~=nil and camp:GetIndex() or -1).." raw="..rawBurst.." requested="..burst.." spawned="..spawned.." lastReason="..lastReason);
	return spawned>0,spawned>0 and "SPAWNED_"..spawned or lastReason;
end

-- Network workshop unit callbacks are batched and sorted before they compete
-- for the global monster cap/serial. The source may have died before the next
-- synchronized turn boundary, so the already-validated owner is sufficient.
-- The single-player path above still validates and uses the live source unit.
function LOTM_WORLD_Monsters.TrySpawnFromWorkshopNetwork(camp,sourceOwnerID,eventToken)
	if not LOTM_MP_TurnSync.IsNetworkGame() then return false,"NETWORK_ONLY"; end
	local ownerID=tonumber(sourceOwnerID);
	if ownerID==nil then return false,"INVALID"; end
	local token=tostring(eventToken or "");
	local eventKey=token~="" and ("LOTM_WORLD_MONSTER_WORKSHOP_EVENT:"..token) or nil;
	if eventKey~=nil and Game.GetProperty(eventKey)~=nil then return false,"DUPLICATE_EVENT"; end
	-- Claim before any roll/counter/unit mutation. If an unexpected exception
	-- interrupts the attempt, reload fails closed instead of replaying a partly
	-- applied monster event. Normal completion upgrades the marker to DONE.
	if eventKey~=nil then Game.SetProperty(eventKey,"PREPARED"); end
	local rawBurst=math.max(1,MonsterBurst());
	local burst=RescueActive() and LOTM_RESCUE_Phase5~=nil and LOTM_RESCUE_Phase5.ScaleMonsterSpawnCount~=nil
		and LOTM_RESCUE_Phase5.ScaleMonsterSpawnCount(rawBurst,"WORKSHOP_EVENT",LOTM_RESCUE_Phase5.WorldTurn()) or rawBurst;
	local spawned=0; local lastReason=burst>0 and "NONE" or "RATE_REDUCED";
	for attempt=1,burst do
		local success,reason=TrySpawnOne(camp,nil,false,ownerID); lastReason=reason;
		if success then spawned=spawned+1; end
		if reason=="INVALID" or reason=="COOLDOWN" or reason=="CAP" or reason=="LIVE" or reason=="NO_PLOT" or reason=="NO_BASELINE" or reason=="INIT_FAILED" then break; end
	end
	if eventKey~=nil then Game.SetProperty(eventKey,"DONE"); end
	Trace("network burst camp="..tostring(camp~=nil and camp:GetIndex() or -1).." raw="..rawBurst.." requested="..burst.." spawned="..spawned.." lastReason="..lastReason);
	return spawned>0,spawned>0 and "SPAWNED_"..spawned or lastReason;
end

function LOTM_WORLD_Monsters.RescueTurnSpawn(worldTurn,requested)
	if not RescueActive() then return 0,"INACTIVE"; end
	local turn=tonumber(worldTurn) or 0; local key="LOTM_WORLD_MONSTER_PERIODIC_LAST_TURN";
	if LOTM_WORLD_State.NumberGameProperty(key,-1)==turn then return 0,"DUPLICATE"; end
	Game.SetProperty(key,turn);
	local workshops={};
	for index=0,Map.GetPlotCount()-1 do
		local plot=Map.GetPlotByIndex(index);
		if plot~=nil and plot:GetImprovementType()==CAMP and NumberProperty(plot,"LOTM_PP_WORKSHOP_IS_WORKSHOP",0)==1 then workshops[#workshops+1]=plot; end
	end
	table.sort(workshops,function(a,b) return a:GetIndex()<b:GetIndex(); end);
	local ownerID=BarbarianID(); local live=LiveMonsters(); local activeSerials=ActiveMonsterSerials(); local activeSeen={};
	for _,serial in ipairs(activeSerials) do activeSeen[serial]=true; end
	local batch={Live=live,Cap=MapCap(),Baseline=LOTM_WORLD_Barbarians.ResolveMeleeBaseline(ownerID),ActiveSerials=activeSerials,ActiveSeen=activeSeen};
	local attempts=math.max(0,tonumber(requested) or 0); local executed=0; local spawned=0; local reasons={}; local plots={};
	for slot=1,attempts do
		if #workshops==0 then break; end
		local choice=LOTM_WORLD_State.Random(#workshops,"periodic monster turn="..turn.." slot="..slot)+1;
		local camp=table.remove(workshops,choice); executed=executed+1; plots[#plots+1]=tostring(camp:GetIndex());
		local success,reason=TrySpawnOne(camp,nil,true,nil,batch); if success then spawned=spawned+1; end
		reasons[#reasons+1]=reason;
		if reason=="CAP" then break; end
	end
	Game.SetProperty("LOTM_WORLD_MONSTER_PERIODIC_LAST_ATTEMPTS",executed);
	Game.SetProperty("LOTM_WORLD_MONSTER_PERIODIC_LAST_SPAWNED",spawned);
	Game.SetProperty("LOTM_WORLD_MONSTER_PERIODIC_LAST_PLOTS",table.concat(plots,","));
	Game.SetProperty("LOTM_WORLD_MONSTER_PERIODIC_LAST_REASONS",table.concat(reasons,","));
	table.sort(batch.ActiveSerials); SaveActiveMonsterSerials(batch.ActiveSerials);
	SetPropertyIfChanged(Game,"LOTM_WORLD_MONSTER_LIVE_COUNT",#batch.Live);
	Log("periodic worldTurn="..turn.." requested="..attempts.." attempts="..executed.." spawned="..spawned.." plots="..table.concat(plots,",").." reasons="..table.concat(reasons,","));
	return spawned,"DONE";
end

local function LegalPath(unit,destination)
	return unit~=nil and destination~=nil and IsLegalWilderness(destination,false);
end

local function ConservativeKillable(attacker,defender)
	local remaining=math.max(1,(defender:GetMaxDamage() or 100)-(defender:GetDamage() or 0));
	if defender:GetCombat()<=0 then return true; end
	local minimumDamage=math.max(1,math.floor(24*math.exp((attacker:GetCombat()-defender:GetCombat())/25)));
	return remaining<=minimumDamage;
end

local function SimulatedKillable(attacker,defender)
	if CombatManager==nil or CombatManager.SimulateAttackVersus==nil or CombatResultParameters==nil then return ConservativeKillable(attacker,defender); end
	local combatType=CombatTypes~=nil and CombatTypes.MELEE or nil;
	local ok,result=pcall(CombatManager.SimulateAttackVersus,attacker:GetComponentID(),defender:GetComponentID(),combatType);
	if not ok or type(result)~="table" then return ConservativeKillable(attacker,defender); end
	local data=result[CombatResultParameters.DEFENDER];
	if type(data)~="table" then return ConservativeKillable(attacker,defender); end
	local final=data[CombatResultParameters.FINAL_DAMAGE_TO]; local maximum=data[CombatResultParameters.MAX_HIT_POINTS];
	if final==nil or maximum==nil then return ConservativeKillable(attacker,defender); end
	return final>=maximum;
end

local function TargetClass(unit)
	local info=GameInfo.Units[unit:GetType()];
	if unit:GetCombat()>0 or unit:GetRangedCombat()>0 or (info~=nil and (tonumber(info.Bombard) or 0)>0) then return 0; end
	if info~=nil and info.FormationClass=="FORMATION_CLASS_CIVILIAN" then return 1; end
	return 2;
end

local function ProtectedSealPlots()
	local result={};
	for _,zone in ipairs({"CENTER","FOOL","NIGHT","STORM"}) do
		local plotIndex=LOTM_WORLD_State.NumberGameProperty("LOTM_RESCUE_"..zone.."_CITY_PLOT",-1);
		if plotIndex>=0 then result[plotIndex]=true; end
	end
	return result;
end

local function PlayerHuntUnlocked()
	if not RescueActive() then return false; end
	local turn=Game.GetCurrentGameTurn() or 0;
	if playerHuntCacheTurn==turn then return playerHuntCache; end
	playerHuntCacheTurn=turn; playerHuntCache=true;
	for _,player in ipairs(PlayerManager.GetAliveMajors()) do
		if not player:IsHuman() then playerHuntCache=false; break; end
	end
	if playerHuntCache then
		for _ in ipairs(PlayerManager.GetAliveMinors()) do playerHuntCache=false; break; end
	end
	if playerHuntCache then
		local freeID=PlayerManager.GetFreeCitiesPlayerID(); local free=freeID~=nil and freeID>=0 and Players[freeID] or nil;
		if free~=nil and free:IsAlive() then
			local protected=ProtectedSealPlots();
			for _,city in free:GetCities():Members() do
				local plot=Map.GetPlot(city:GetX(),city:GetY());
				if plot==nil or not protected[plot:GetIndex()] then playerHuntCache=false; break; end
			end
		end
	end
	local state=playerHuntCache and 1 or 0;
	local previous=LOTM_WORLD_State.NumberGameProperty("LOTM_WORLD_MONSTER_PLAYER_HUNT_UNLOCKED",-1);
	Game.SetProperty("LOTM_WORLD_MONSTER_PLAYER_HUNT_UNLOCKED",state);
	if previous~=state then Log("player hunt state="..(playerHuntCache and "UNLOCKED_ONLY_HUMANS_AND_SEAL_CHURCHES_REMAIN" or "LOCKED_EXTERNAL_FACTIONS_REMAIN").." worldTurn="..turn); end
	return playerHuntCache;
end

local function IsAllowedUnitTarget(unit)
	if unit==nil then return false; end
	local player=Players[unit:GetOwner()];
	return player~=nil and (not player:IsHuman() or PlayerHuntUnlocked());
end

local function LegalTargets(monster)
	local result={}; local maxDistance=NumberProperty(monster,"LOTM_WORLD_MONSTER_TARGET_MOVES",3);
	for dx=-maxDistance,maxDistance do for dy=-maxDistance,maxDistance do
		local plot=Map.GetPlotXYWithRangeCheck(monster:GetX(),monster:GetY(),dx,dy,maxDistance);
		if IsLegalWilderness(plot,false) and LegalPath(monster,plot) then
			for _,other in ipairs(Units.GetUnitsInPlot(plot) or {}) do
				if other:GetOwner()~=monster:GetOwner() and IsAllowedUnitTarget(other) then
					table.insert(result,{Unit=other,Plot=plot,Killable=SimulatedKillable(monster,other),Class=TargetClass(other),Distance=Map.GetPlotDistance(monster:GetX(),monster:GetY(),plot:GetX(),plot:GetY()),Remaining=(other:GetMaxDamage() or 100)-(other:GetDamage() or 0)});
				end
			end
		end
	end end
	table.sort(result,function(a,b)
		if a.Killable~=b.Killable then return a.Killable; end
		if a.Class~=b.Class then return a.Class<b.Class; end
		if a.Distance~=b.Distance then return a.Distance<b.Distance; end
		if a.Remaining~=b.Remaining then return a.Remaining<b.Remaining; end
		if a.Unit:GetOwner()~=b.Unit:GetOwner() then return a.Unit:GetOwner()<b.Unit:GetOwner(); end
		return a.Unit:GetID()<b.Unit:GetID();
	end);
	return result;
end

local function IsCityStatePlayer(player)
	if player==nil then return false; end
	local config=PlayerConfigurations[player:GetID()];
	return config~=nil and config:GetCivilizationLevelTypeName()=="CIVILIZATION_LEVEL_CITY_STATE";
end

local function IsAttackableCityOwner(player)
	return player~=nil and player:IsAlive() and ((player:IsMajor() and (not player:IsHuman() or PlayerHuntUnlocked())) or IsCityStatePlayer(player));
end

local function AICityTargets(monster)
	local result={}; local source=Map.GetPlot(monster:GetX(),monster:GetY());
	if source==nil then return result; end
	local owners={};
	for _,player in ipairs(PlayerManager.GetAliveMajors()) do owners[#owners+1]=player; end
	for _,player in ipairs(PlayerManager.GetAliveMinors()) do owners[#owners+1]=player; end
	for _,player in ipairs(owners) do
		if IsAttackableCityOwner(player) then
			for _,city in player:GetCities():Members() do
				local plot=Map.GetPlot(city:GetX(),city:GetY());
				if plot~=nil and (RescueActive() or plot:GetContinentType()==source:GetContinentType()) then
					result[#result+1]={City=city,Plot=plot,Owner=player:GetID(),CityID=city:GetID(),Distance=Map.GetPlotDistance(monster:GetX(),monster:GetY(),city:GetX(),city:GetY())};
				end
			end
		end
	end
	table.sort(result,function(a,b)
		if a.Distance~=b.Distance then return a.Distance<b.Distance; end
		if a.Owner~=b.Owner then return a.Owner<b.Owner; end
		return a.CityID<b.CityID;
	end);
	return result;
end

local function AssaultCityTarget(monster)
	if not RescueActive() then return nil; end
	local candidates=AICityTargets(monster); if #candidates==0 then return nil; end
	local focus=candidates[1];
	return {Kind="AI_CITY",City=focus.City,Plot=focus.Plot,Owner=focus.Owner,ID=focus.CityID};
end

local function AITerritoryOwners()
	local result={};
	for _,player in ipairs(PlayerManager.GetAliveMajors()) do if IsAttackableCityOwner(player) then result[player:GetID()]=true; end end
	for _,player in ipairs(PlayerManager.GetAliveMinors()) do if IsAttackableCityOwner(player) then result[player:GetID()]=true; end end
	return result;
end

local function ClearLockedTarget(monster)
	monster:SetProperty(TARGET_KIND_PROPERTY,nil); monster:SetProperty(TARGET_OWNER_PROPERTY,nil); monster:SetProperty(TARGET_ID_PROPERTY,nil);
end

local function LockedTarget(monster)
	local kind=tostring(monster:GetProperty(TARGET_KIND_PROPERTY) or "");
	local owner=NumberProperty(monster,TARGET_OWNER_PROPERTY,-1); local id=NumberProperty(monster,TARGET_ID_PROPERTY,-1);
	if kind=="UNIT" then
		local unit=owner>=0 and id>=0 and UnitManager.GetUnit(owner,id) or nil;
		if unit~=nil and not unit:IsDead() and not unit:IsDelayedDeath() and IsAllowedUnitTarget(unit) then
			local plot=Map.GetPlot(unit:GetX(),unit:GetY()); if plot~=nil then return {Kind="UNIT",Unit=unit,Plot=plot,Owner=owner,ID=id}; end
		end
	elseif kind=="AI_CITY" then
		local city=owner>=0 and id>=0 and CityManager.GetCity(owner,id) or nil;
		if city~=nil and IsAttackableCityOwner(Players[city:GetOwner()]) then
			local plot=Map.GetPlot(city:GetX(),city:GetY()); if plot~=nil then return {Kind="AI_CITY",City=city,Plot=plot,Owner=owner,ID=id}; end
		end
	end
	if kind~="" then ClearLockedTarget(monster); Log("target released serial="..NumberProperty(monster,MONSTER_SERIAL,0).." kind="..kind.." owner="..owner.." id="..id); end
	return nil;
end

local function ChooseLockedTarget(monster)
	local focus=AssaultCityTarget(monster);
	if focus~=nil then
		monster:SetProperty(TARGET_KIND_PROPERTY,"AI_CITY"); monster:SetProperty(TARGET_OWNER_PROPERTY,focus.Owner); monster:SetProperty(TARGET_ID_PROPERTY,focus.ID);
		Log("nearest city locked serial="..NumberProperty(monster,MONSTER_SERIAL,0).." owner="..focus.Owner.." city="..focus.ID.." plot="..focus.Plot:GetIndex());
		return focus;
	end
	local candidates={};
	for _,entry in ipairs(LegalTargets(monster)) do candidates[#candidates+1]={Kind="UNIT",Unit=entry.Unit,Plot=entry.Plot,Owner=entry.Unit:GetOwner(),ID=entry.Unit:GetID()}; end
	for _,entry in ipairs(AICityTargets(monster)) do candidates[#candidates+1]={Kind="AI_CITY",City=entry.City,Plot=entry.Plot,Owner=entry.Owner,ID=entry.CityID}; end
	if #candidates==0 then return nil; end
	local serial=NumberProperty(monster,MONSTER_SERIAL,0);
	local choice=LOTM_WORLD_State.Random(#candidates,"monster locked target serial="..serial)+1; local target=candidates[choice];
	monster:SetProperty(TARGET_KIND_PROPERTY,target.Kind); monster:SetProperty(TARGET_OWNER_PROPERTY,target.Owner); monster:SetProperty(TARGET_ID_PROPERTY,target.ID);
	Log("target locked serial="..serial.." kind="..target.Kind.." owner="..target.Owner.." id="..target.ID.." candidates="..#candidates);
	return target;
end

local function RoamPlot(monster)
	local candidates={}; local maxDistance=NumberProperty(monster,"LOTM_WORLD_MONSTER_TARGET_MOVES",3);
	for dx=-maxDistance,maxDistance do for dy=-maxDistance,maxDistance do
		local plot=Map.GetPlotXYWithRangeCheck(monster:GetX(),monster:GetY(),dx,dy,maxDistance);
		if plot~=nil and plot:GetIndex()~=(Map.GetPlot(monster:GetX(),monster:GetY())):GetIndex() and IsLegalWilderness(plot,true) and LegalPath(monster,plot) then table.insert(candidates,plot); end
	end end
	table.sort(candidates,function(a,b) return a:GetIndex()<b:GetIndex(); end);
	if #candidates==0 then return nil; end
	return candidates[LOTM_WORLD_State.Random(#candidates,"monster roam serial="..NumberProperty(monster,MONSTER_SERIAL,0))+1];
end

local function EngineComponentID(object,componentType)
	if object==nil then return nil; end
	if object.GetComponentID~=nil then
		local ok,value=pcall(object.GetComponentID,object); if ok and type(value)=="table" then return value; end
	end
	if componentType==nil or object.GetOwner==nil or object.GetID==nil then return nil; end
	return {player=object:GetOwner(),id=object:GetID(),type=componentType};
end

local function SimulateEngineMelee(attacker,defender,defenderComponentType)
	if attacker==nil or defender==nil or CombatManager==nil or CombatManager.SimulateAttackVersus==nil or CombatResultParameters==nil or ComponentType==nil then
		return nil,"ENGINE_COMBAT_API_UNAVAILABLE";
	end
	local attackerComponentID=EngineComponentID(attacker,ComponentType.UNIT); local defenderComponentID=EngineComponentID(defender,defenderComponentType);
	if attackerComponentID==nil or defenderComponentID==nil then return nil,"ENGINE_COMPONENT_ID_UNAVAILABLE"; end
	local combatType=CombatTypes~=nil and CombatTypes.MELEE or nil;
	local ok,result=pcall(CombatManager.SimulateAttackVersus,attackerComponentID,defenderComponentID,combatType);
	if not ok or type(result)~="table" then return nil,"ENGINE_COMBAT_SIMULATION_FAILED"; end
	local attackerData=result[CombatResultParameters.ATTACKER]; local defenderData=result[CombatResultParameters.DEFENDER];
	if type(attackerData)~="table" or type(defenderData)~="table" then return nil,"ENGINE_COMBAT_RESULT_UNAVAILABLE"; end
	local attackerDamage=tonumber(attackerData[CombatResultParameters.DAMAGE_TO]);
	local defenderDamage=tonumber(defenderData[CombatResultParameters.DAMAGE_TO]);
	local defenseDamage=CombatResultParameters.DEFENSE_DAMAGE_TO~=nil and tonumber(defenderData[CombatResultParameters.DEFENSE_DAMAGE_TO]) or 0;
	if attackerDamage==nil or defenderDamage==nil then return nil,"ENGINE_COMBAT_DAMAGE_UNAVAILABLE"; end
	return {AttackerDamage=math.max(0,attackerDamage),DefenderDamage=math.max(0,defenderDamage),DefenseDamage=math.max(0,defenseDamage or 0)},"ENGINE_COMBAT_READY";
end

local function ApplyEngineUnitDamage(unit,damage)
	if unit==nil or damage<=0 or unit:IsDead() or unit:IsDelayedDeath() then return true,false; end
	local maximum=unit:GetMaxDamage() or 100; local current=unit:GetDamage() or 0;
	if current+damage>=maximum then
		local ok,result=pcall(UnitManager.Kill,unit);
		return ok and result~=false,true;
	end
	unit:ChangeDamage(damage); return true,false;
end

local function ScriptedAttack(attacker,defender)
	if attacker==nil or defender==nil or defender:IsDead() or defender:IsDelayedDeath() then return false,"TARGET_GONE"; end
	local result,reason=SimulateEngineMelee(attacker,defender,ComponentType~=nil and ComponentType.UNIT or nil); if result==nil then return false,reason; end
	local attackSerial=NumberProperty(attacker,"LOTM_WORLD_MONSTER_ATTACK_SERIAL",0)+1;
	attacker:SetProperty("LOTM_WORLD_MONSTER_ATTACK_SERIAL",attackSerial);
	local reflected=LOTM_RESCUE_Thief~=nil and LOTM_RESCUE_Thief.ShouldReflectAttack~=nil
		and LOTM_RESCUE_Thief.ShouldReflectAttack(attacker,defender,attackSerial);
	if reflected then
		if LOTM_RESCUE_SyncActions~=nil and LOTM_RESCUE_SyncActions.MarkScriptedKiller~=nil then
			LOTM_RESCUE_SyncActions.MarkScriptedKiller(attacker,defender);
		end
		local attackerOK,attackerKilled=ApplyEngineUnitDamage(attacker,result.DefenderDamage);
		if not attackerOK then return false,"ENGINE_REFLECT_DAMAGE_APPLY_FAILED"; end
		return true,"REFLECTED_33PCT_DAMAGE_"..result.DefenderDamage.."_KILLS_"..tostring(attackerKilled);
	end
	local defenderOK,defenderKilled=ApplyEngineUnitDamage(defender,result.DefenderDamage);
	local attackerOK,attackerKilled=ApplyEngineUnitDamage(attacker,result.AttackerDamage);
	if not defenderOK or not attackerOK then return false,"ENGINE_UNIT_DAMAGE_APPLY_FAILED"; end
	return true,"ENGINE_UNIT_DAMAGE_"..result.DefenderDamage.."_RETALIATION_"..result.AttackerDamage.."_KILLS_"..tostring(defenderKilled).."/"..tostring(attackerKilled);
end

local function ScriptedCityAttack(attacker,target)
	if attacker==nil or target==nil or not IsAttackableCityOwner(Players[target:GetOwner()]) then return false,"CITY_TARGET_INVALID"; end
	local district=CityManager.GetDistrictAt(target:GetX(),target:GetY());
	if district==nil or DefenseTypes==nil or DefenseTypes.DISTRICT_GARRISON==nil or DefenseTypes.DISTRICT_OUTER==nil then return false,"CITY_DISTRICT_UNAVAILABLE"; end
	local result,reason=SimulateEngineMelee(attacker,district,ComponentType~=nil and ComponentType.DISTRICT or nil); if result==nil then return false,reason; end
	local attackSerial=NumberProperty(attacker,"LOTM_WORLD_MONSTER_ATTACK_SERIAL",0)+1;
	attacker:SetProperty("LOTM_WORLD_MONSTER_ATTACK_SERIAL",attackSerial);
	local reflected=LOTM_RESCUE_Thief~=nil and LOTM_RESCUE_Thief.ShouldReflectAttack~=nil
		and LOTM_RESCUE_Thief.ShouldReflectAttack(attacker,target,attackSerial);
	if reflected then
		local killer=nil;
		for _,candidate in ipairs(PlayerManager.GetAliveMajors() or {}) do
			if candidate:IsHuman() and candidate:GetProperty("LOTM_RP_PATH")=="PATH_THIEF"
				and tonumber(candidate:GetProperty("LOTM_RP_SEQUENCE") or 9)<=3 then
				killer=candidate:GetUnits():FindID(tonumber(candidate:GetProperty("LOTM_RP_UNIT_ID") or -1));
				if killer~=nil then break; end
			end
		end
		if killer~=nil and LOTM_RESCUE_SyncActions~=nil and LOTM_RESCUE_SyncActions.MarkScriptedKiller~=nil then
			LOTM_RESCUE_SyncActions.MarkScriptedKiller(attacker,killer);
		end
		local attackerOK,attackerKilled=ApplyEngineUnitDamage(attacker,result.DefenderDamage);
		if not attackerOK then return false,"ENGINE_REFLECT_DAMAGE_APPLY_FAILED"; end
		return true,"REFLECTED_33PCT_CITY_DAMAGE_"..result.DefenderDamage.."_KILLS_"..tostring(attackerKilled);
	end
	local garrisonOK,garrison=pcall(function() return district:GetDamage(DefenseTypes.DISTRICT_GARRISON); end);
	local garrisonMaxOK,garrisonMax=pcall(function() return district:GetMaxDamage(DefenseTypes.DISTRICT_GARRISON); end);
	local outerOK,outer=pcall(function() return district:GetDamage(DefenseTypes.DISTRICT_OUTER); end);
	local outerMaxOK,outerMax=pcall(function() return district:GetMaxDamage(DefenseTypes.DISTRICT_OUTER); end);
	if not garrisonOK or not garrisonMaxOK or not outerOK or not outerMaxOK then return false,"CITY_DAMAGE_READ_FAILED"; end
	garrison=tonumber(garrison) or 0; garrisonMax=tonumber(garrisonMax) or 100; outer=tonumber(outer) or 0; outerMax=tonumber(outerMax) or 0;
	if garrisonMax<=0 then garrisonMax=100; end
	local nextGarrison=math.min(garrisonMax,garrison+result.DefenderDamage); local nextOuter=outerMax>0 and math.min(outerMax,outer+result.DefenseDamage) or outer;
	local writeOK=pcall(function()
		district:SetDamage(DefenseTypes.DISTRICT_GARRISON,nextGarrison);
		if outerMax>0 then district:SetDamage(DefenseTypes.DISTRICT_OUTER,nextOuter); end
	end);
	if not writeOK then return false,"CITY_DAMAGE_WRITE_FAILED"; end
	local attackerOK=ApplyEngineUnitDamage(attacker,result.AttackerDamage); if not attackerOK then return false,"ENGINE_RETALIATION_APPLY_FAILED"; end
	if nextGarrison>=garrisonMax then
		local live=CityManager.GetCity(target:GetOwner(),target:GetID());
		if live==nil or not IsAttackableCityOwner(Players[live:GetOwner()]) then return false,"CITY_LETHAL_REVALIDATION_FAILED"; end
		local ownerID=live:GetOwner(); local cityID=live:GetID();
		if CityManager.DestroyCity~=nil then
			local destroyOK,destroyed=pcall(CityManager.DestroyCity,live);
			if destroyOK and destroyed~=false and CityManager.GetCity(ownerID,cityID)==nil then return true,"AI_CITY_DESTROYED"; end
		end
		if CityManager.RequestCommand==nil or CityCommandTypes==nil or CityCommandTypes.DESTROY==nil or CityDestroyDirectives==nil or CityDestroyDirectives.RAZE==nil or UnitOperationTypes==nil or UnitOperationTypes.PARAM_FLAGS==nil then
			return false,"CITY_DESTROY_API_UNAVAILABLE";
		end
		local parameters={}; parameters[UnitOperationTypes.PARAM_FLAGS]=CityDestroyDirectives.RAZE;
		local requestOK,requested=pcall(CityManager.RequestCommand,live,CityCommandTypes.DESTROY,parameters);
		if not requestOK or requested==false then return false,"AI_CITY_DESTROY_REQUEST_FAILED"; end
		return true,"AI_CITY_DESTROY_REQUESTED";
	end
	return true,"ENGINE_CITY_GARRISON_"..result.DefenderDamage.."_WALL_"..result.DefenseDamage.."_RETALIATION_"..result.AttackerDamage;
end

local function ReconcileMonsterAbilities(monster)
	local tier=NumberProperty(monster,MONSTER_TIER,2);
	local info=GameInfo.Units[monster:GetType()];
	local baseMoves=info~=nil and (tonumber(info.BaseMoves) or 2) or 2;
	ApplyMonsterAbilities(monster,tier,math.max(0,NumberProperty(monster,"LOTM_WORLD_MONSTER_TARGET_MOVES",TIER_MOVES[tier])-baseMoves),NumberProperty(monster,PERIOD_BONUS_PROPERTY,0));
	return tier;
end

local function Act(monster)
	local tier=ReconcileMonsterAbilities(monster); local damage=monster:GetDamage() or 0;
	if damage>0 then monster:ChangeDamage(-math.min(TIER_HEAL[tier],damage)); end
	if LOTM_RESCUE_SyncActions==nil then UnitManager.FinishMoves(monster); Log("action serial="..NumberProperty(monster,MONSTER_SERIAL,0).." gameplayNative=false reason=HELPER_UNAVAILABLE attack=false destination=-1"); return; end
	local currentTurn=Game.GetCurrentGameTurn();
	if NumberProperty(monster,REDEPLOYED_TURN_PROPERTY,-1)==currentTurn then
		UnitManager.FinishMoves(monster);
		Log("action serial="..NumberProperty(monster,MONSTER_SERIAL,0).." gameplayNative=false reason=REDEPLOY_COOLDOWN attack=false destination=-1 attackEligibleTurn="..tostring(currentTurn+1));
		return;
	end
	local target=LockedTarget(monster) or ChooseLockedTarget(monster); local destination=nil; local attack=false; local acted=false; local reason="NO_DESTINATION"; local targetKind="NONE"; local targetOwner=-1; local targetCity=-1;
	if target~=nil and target.Kind=="UNIT" then
		destination=target.Plot; attack=true; targetKind="UNIT"; targetOwner=target.Owner;
		local distance=Map.GetPlotDistance(monster:GetX(),monster:GetY(),destination:GetX(),destination:GetY());
		if distance>1 then acted,reason=LOTM_RESCUE_SyncActions.MoveToward(monster,destination,NumberProperty(monster,"LOTM_WORLD_MONSTER_TARGET_MOVES",3),true,false); end
		if Map.GetPlotDistance(monster:GetX(),monster:GetY(),destination:GetX(),destination:GetY())<=1 then acted,reason=ScriptedAttack(monster,target.Unit); end
	elseif target~=nil and target.Kind=="AI_CITY" then
		destination=target.Plot; attack=true; targetKind="AI_CITY"; targetOwner=target.Owner; targetCity=target.ID;
		local distance=Map.GetPlotDistance(monster:GetX(),monster:GetY(),destination:GetX(),destination:GetY());
		local source=Map.GetPlot(monster:GetX(),monster:GetY());
		local crossContinent=source~=nil and source:GetContinentType()~=destination:GetContinentType();
		if distance>REDEPLOY_DISTANCE or crossContinent then
			local from=source~=nil and source:GetIndex() or -1; local redeployPlot=-1; local redeployDistance=-1;
			acted,reason,redeployPlot,redeployDistance=LOTM_RESCUE_SyncActions.RedeployNearTarget(monster,destination,REDEPLOY_TARGET_MIN_DISTANCE,REDEPLOY_TARGET_MAX_DISTANCE,false,AITerritoryOwners());
			if acted then
				local placed=Map.GetPlot(monster:GetX(),monster:GetY());
				monster:SetProperty(REDEPLOYED_TURN_PROPERTY,currentTurn);
				UnitManager.FinishMoves(monster);
				Log("redeployed serial="..NumberProperty(monster,MONSTER_SERIAL,0).." from="..from.." to="..tostring(placed~=nil and placed:GetIndex() or redeployPlot)
					.." targetKind=AI_CITY targetOwner="..targetOwner.." targetID="..targetCity.." distanceBefore="..distance
					.." distanceAfter="..redeployDistance.." attackEligibleTurn="..tostring(currentTurn+1).." reason="..reason);
				Log("action serial="..NumberProperty(monster,MONSTER_SERIAL,0).." gameplayNative=true reason=REDEPLOY_COOLDOWN attack=false targetKind=AI_CITY targetOwner="..targetOwner.." targetCity="..targetCity.." destination="..destination:GetIndex());
				return;
			end
		end
		if distance>1 then acted,reason=LOTM_RESCUE_SyncActions.MoveToward(monster,destination,NumberProperty(monster,"LOTM_WORLD_MONSTER_TARGET_MOVES",3),false,false,AITerritoryOwners()); end
		-- The first long-distance redeploy can leave a monster inside the target's
		-- five-tile ring but behind a newly occupied or unusable route. Distance
		-- alone would then suppress every later redeploy. Retry another legal ring
		-- tile on NO_PLOT and preserve the same no-attack-until-next-turn rule.
		if reason=="NO_PLOT" then
			local blockedSource=Map.GetPlot(monster:GetX(),monster:GetY());
			local blockedFrom=blockedSource~=nil and blockedSource:GetIndex() or -1;
			local distanceBeforeRetry=Map.GetPlotDistance(monster:GetX(),monster:GetY(),destination:GetX(),destination:GetY());
			local retryPlot=-1; local retryDistance=-1; local retryReason="NO_REDEPLOY_PLOT";
			acted,retryReason,retryPlot,retryDistance=LOTM_RESCUE_SyncActions.RedeployNearTarget(monster,destination,REDEPLOY_TARGET_MIN_DISTANCE,REDEPLOY_TARGET_MAX_DISTANCE,false,AITerritoryOwners());
			if acted then
				local placed=Map.GetPlot(monster:GetX(),monster:GetY());
				monster:SetProperty(REDEPLOYED_TURN_PROPERTY,currentTurn);
				UnitManager.FinishMoves(monster);
				Log("redeployed serial="..NumberProperty(monster,MONSTER_SERIAL,0).." from="..blockedFrom.." to="..tostring(placed~=nil and placed:GetIndex() or retryPlot)
					.." targetKind=AI_CITY targetOwner="..targetOwner.." targetID="..targetCity.." distanceBefore="..distanceBeforeRetry
					.." distanceAfter="..retryDistance.." attackEligibleTurn="..tostring(currentTurn+1).." reason=BLOCKED_"..retryReason);
				Log("action serial="..NumberProperty(monster,MONSTER_SERIAL,0).." gameplayNative=true reason=REDEPLOY_COOLDOWN attack=false targetKind=AI_CITY targetOwner="..targetOwner.." targetCity="..targetCity.." destination="..destination:GetIndex());
				return;
			end
			reason=retryReason;
		end
		if Map.GetPlotDistance(monster:GetX(),monster:GetY(),destination:GetX(),destination:GetY())<=1 then
			acted,reason=ScriptedCityAttack(monster,target.City);
		else
			for _,entry in ipairs(LegalTargets(monster)) do
				if entry.Distance<=1 then
					local fallbackReason="NONE"; acted,fallbackReason=ScriptedAttack(monster,entry.Unit);
					reason="CITY_BLOCKED_UNIT_"..fallbackReason; targetKind="UNIT"; targetOwner=entry.Unit:GetOwner(); targetCity=-1; destination=entry.Plot;
					break;
				end
			end
		end
	else
		destination=RoamPlot(monster);
		if destination~=nil then acted,reason=LOTM_RESCUE_SyncActions.MoveToward(monster,destination,NumberProperty(monster,"LOTM_WORLD_MONSTER_TARGET_MOVES",3),true,false); end
	end
	-- Single-player only: an AI city can remain a valid CityManager object while
	-- no legal approach plot exists (for example after ownership/terrain changes).
	-- Do not keep the permanent lock in that case, otherwise every later turn
	-- repeats NO_PLOT and this civilization is effectively never attacked.
	if (reason=="NO_PLOT" or reason=="NO_REDEPLOY_PLOT" or reason=="PLACE_FAILED") and targetKind=="AI_CITY"
		and (LOTM_MP_TurnSync==nil or not LOTM_MP_TurnSync.IsNetworkGame()) then
		ClearLockedTarget(monster);
		Log("target released serial="..NumberProperty(monster,MONSTER_SERIAL,0)
			.." kind=AI_CITY owner="..tostring(targetOwner).." id="..tostring(targetCity)
			.." reason="..tostring(reason).."_SP_RESELECT");
	end
	UnitManager.FinishMoves(monster);
	local actionMessage="action serial="..NumberProperty(monster,MONSTER_SERIAL,0).." gameplayNative="..tostring(acted).." reason="..reason.." attack="..tostring(attack).." targetKind="..targetKind.." targetOwner="..targetOwner.." targetCity="..targetCity.." destination="..tostring(destination~=nil and destination:GetIndex() or -1);
	if string.find(reason,"AI_CITY_",1,true)==1 or string.find(reason,"ENGINE_",1,true)==1 or reason=="NO_PLOT" or reason=="PLACE_FAILED" or reason=="HELPER_UNAVAILABLE" or string.find(reason,"FAILED",1,true)~=nil or string.find(reason,"UNAVAILABLE",1,true)~=nil then Log(actionMessage); else Trace(actionMessage); end
end

local function Release(serial,removedTurn,liveCountAlreadyReconciled)
	if serial==nil or serial<=0 then return; end
	if LOTM_WORLD_State.NumberGameProperty(MetaKey(serial,"LIVE"),0)~=1 then return; end
	local source=LOTM_WORLD_State.NumberGameProperty(MetaKey(serial,"SOURCE"),-1);
	local camp=Map.GetPlotByIndex(source);
	local sourceEpochValue=Game.GetProperty(MetaKey(serial,"SOURCE_CAMP_EPOCH"));
	local sourceEpoch=sourceEpochValue~=nil and tonumber(sourceEpochValue) or nil;
	local currentEpochValue=camp~=nil and camp:GetProperty("LOTM_PP_WORKSHOP_CAMP_EPOCH") or nil;
	local currentEpoch=currentEpochValue~=nil and tonumber(currentEpochValue) or nil;
	local currentSlot=camp~=nil and NumberProperty(camp,"LOTM_WORLD_WORKSHOP_MONSTER_SERIAL",0) or 0;
	-- Resource-290 monsters have no frozen camp epoch.  For those legacy units,
	-- the still-matching source slot is the only proof that this is the original
	-- camp generation.  Missing epoch data must not authorize cooldown writes to
	-- a rebuilt camp on the same plot.
	local sameCampGeneration=false;
	if sourceEpoch~=nil and currentEpoch~=nil then
		sameCampGeneration=sourceEpoch==currentEpoch;
	elseif currentSlot==serial then
		sameCampGeneration=true;
	end
	local releaseTurn=NumberProperty(Game,MetaKey(serial,"RELEASE_TURN"),-1);
	if releaseTurn<0 then
		releaseTurn=tonumber(removedTurn) or Game.GetCurrentGameTurn();
		Game.SetProperty(MetaKey(serial,"RELEASE_TURN"),releaseTurn);
	end
	local cooldownUntil=NumberProperty(Game,MetaKey(serial,"RELEASE_COOLDOWN_UNTIL"),-1);
	if cooldownUntil<0 then
		cooldownUntil=releaseTurn+MonsterCooldown();
		Game.SetProperty(MetaKey(serial,"RELEASE_COOLDOWN_UNTIL"),cooldownUntil);
	end
	if camp~=nil and sameCampGeneration then
		if currentSlot==serial then
			camp:SetProperty("LOTM_WORLD_WORKSHOP_MONSTER_SERIAL",0);
		end
		camp:SetProperty("LOTM_WORLD_WORKSHOP_MONSTER_COOLDOWN_UNTIL",cooldownUntil);
	end
	if liveCountAlreadyReconciled~=true then
		local count=0;
		for _,activeSerial in ipairs(ActiveMonsterSerials()) do
			if activeSerial~=serial and LOTM_WORLD_State.NumberGameProperty(MetaKey(activeSerial,"LIVE"),0)==1 then count=count+1; end
		end
		Game.SetProperty("LOTM_WORLD_MONSTER_LIVE_COUNT",count);
	end
	Log("released serial="..serial.." cooldownUntil="..cooldownUntil.." sameCampGeneration="..tostring(sameCampGeneration));
end

local function SettleReward(serial,killerID,killerUnitID,capturedEraIndex)
	if serial==nil or serial<=0 or LOTM_WORLD_State.NumberGameProperty(MetaKey(serial,"REWARDED"),0)==1 then return; end
	if RescueActive() and LOTM_RESCUE_Phase6~=nil and LOTM_RESCUE_Phase6.OnLostControlKilled~=nil then
		local tier=LOTM_WORLD_State.NumberGameProperty(MetaKey(serial,"TIER"),2);
		local ok,result=pcall(LOTM_RESCUE_Phase6.OnLostControlKilled,tier,killerID,killerUnitID,"MONSTER",serial);
		if not ok then Log("Phase6 purification error serial="..serial.." error="..tostring(result)); end
	end
	local killer=Players[killerID]; if killer==nil or not killer:IsAlive() or not killer:IsMajor() then return; end
	Game.SetProperty(MetaKey(serial,"REWARDED"),1);
	local handled=false;
	if questResolver~=nil then local ok,result=pcall(questResolver,killerID,serial); handled=ok and result==true; end
	local tier=LOTM_WORLD_State.NumberGameProperty(MetaKey(serial,"TIER"),2);
	local eraIndex=tonumber(capturedEraIndex); if eraIndex==nil then eraIndex=Game.GetEras():GetCurrentEra() or 0; end
	local eraNumber=math.max(1,eraIndex+1);
	local goldReward=REWARD_GOLD_PER_ERA*eraNumber;
	if not handled then
		local treasury=killer:GetTreasury(); if treasury~=nil then treasury:ChangeGoldBalance(goldReward); end
	end
	Log("reward serial="..serial.." killer="..killerID.." tier="..tier.." era="..eraNumber.." gold="..goldReward.." questHandled="..tostring(handled));
end

local function Dead(unit)
	return unit==nil or unit:IsDead() or unit:IsDelayedDeath();
end

local function ScriptedKillerPrefix(ownerID,unitID)
	return "LOTM_RESCUE_SCRIPTED_KILLER:"..tostring(ownerID)..":"..tostring(unitID)..":";
end

local function MonsterIdentityMatches(serial,ownerID,unitID)
	return LOTM_WORLD_State.NumberGameProperty(MetaKey(serial,"OWNER"),-1)==tonumber(ownerID)
		and LOTM_WORLD_State.NumberGameProperty(MetaKey(serial,"UNIT_ID"),-1)==tonumber(unitID);
end

local function CancelNetworkRemoval(serial,reason)
	local entry=networkRemovalBySerial[tonumber(serial)];
	if entry~=nil then
		entry.Cancelled=true;
		networkRemovalBySerial[entry.Serial]=nil;
		Trace("network removal cancelled serial="..entry.Serial.." reason="..tostring(reason));
	end
end

local function ClearCapturedIdentity(ownerID,unitID,serial,killerID,killerUnitID)
	local engineKey=EngineKey(ownerID,unitID);
	if LOTM_WORLD_State.NumberGameProperty(engineKey,0)~=serial then return; end
	Game.SetProperty(engineKey,nil);
	local prefix=ScriptedKillerPrefix(ownerID,unitID);
	if killerID~=nil and killerID>=0
		and tostring(Game.GetProperty(prefix.."TARGET_KIND") or "")=="MONSTER"
		and LOTM_WORLD_State.NumberGameProperty(prefix.."TARGET_SERIAL",-1)==serial
		and LOTM_WORLD_State.NumberGameProperty(prefix.."PLAYER",-1)==killerID
		and LOTM_WORLD_State.NumberGameProperty(prefix.."UNIT",-1)==(killerUnitID or -1) then
		Game.SetProperty(prefix.."PLAYER",nil); Game.SetProperty(prefix.."UNIT",nil);
		Game.SetProperty(prefix.."TARGET_KIND",nil); Game.SetProperty(prefix.."TARGET_SERIAL",nil);
	end
end

local function FinalizeRemoval(serial,ownerID,unitID,killerID,killerUnitID,removedTurn,rewardEraIndex,liveCountAlreadyReconciled,source,cancelQueued)
	local normalizedSerial=tonumber(serial); local normalizedOwner=tonumber(ownerID); local normalizedUnit=tonumber(unitID);
	if normalizedSerial==nil or normalizedSerial<=0 or normalizedOwner==nil or normalizedUnit==nil then return false,"INVALID_IDENTITY"; end
	if not MonsterIdentityMatches(normalizedSerial,normalizedOwner,normalizedUnit) then
		Log("removal rejected source="..tostring(source).." serial="..normalizedSerial.." owner="..normalizedOwner.." unit="..normalizedUnit.." reason=IDENTITY_MISMATCH");
		return false,"IDENTITY_MISMATCH";
	end
	local current=UnitManager.GetUnit(normalizedOwner,normalizedUnit);
	local identityReused=current~=nil and NumberProperty(current,MONSTER_SERIAL,0)~=normalizedSerial;
	if not identityReused and LOTM_RESCUE_Phase9Digestion~=nil
		and type(LOTM_RESCUE_Phase9Digestion.RecordLostControlIdentity)=="function" then
		LOTM_RESCUE_Phase9Digestion.RecordLostControlIdentity(normalizedOwner,normalizedUnit,
			LOTM_WORLD_State.NumberGameProperty(MetaKey(normalizedSerial,"BASELINE"),0));
	end
	Release(normalizedSerial,removedTurn,liveCountAlreadyReconciled);
	local normalizedKiller=tonumber(killerID) or -1; local normalizedKillerUnit=tonumber(killerUnitID) or -1;
	if normalizedKiller>=0 then SettleReward(normalizedSerial,normalizedKiller,normalizedKillerUnit,rewardEraIndex); end
	-- Clear owner:unitID state only while it still names this serial.  A later
	-- unit generation may already have reused the same engine ID.
	ClearCapturedIdentity(normalizedOwner,normalizedUnit,normalizedSerial,normalizedKiller,normalizedKillerUnit);
	Game.SetProperty(MetaKey(normalizedSerial,"MISSING_SINCE"),nil);
	Game.SetProperty(MetaKey(normalizedSerial,"LIVE"),0);
	RemoveActiveMonsterSerial(normalizedSerial);
	if cancelQueued then CancelNetworkRemoval(normalizedSerial,source); end
	return true,"SETTLED";
end

local function QueueNetworkRemoval(playerID,unitID)
	local owner=tonumber(playerID); local removedUnit=tonumber(unitID);
	if owner==nil or removedUnit==nil then return; end
	local serial=LOTM_WORLD_State.NumberGameProperty(EngineKey(owner,removedUnit),0);
	if serial<=0 or LOTM_WORLD_State.NumberGameProperty(MetaKey(serial,"LIVE"),0)~=1 then return; end
	if not MonsterIdentityMatches(serial,owner,removedUnit) then
		Log("network removal enqueue rejected serial="..serial.." owner="..owner.." unit="..removedUnit.." reason=IDENTITY_MISMATCH");
		return;
	end
	local existing=networkRemovalBySerial[serial];
	if existing~=nil then
		Trace("network removal duplicate serial="..serial.." queuedTurn="..existing.QueuedTurn);
		return;
	end
	local entry={
		Serial=serial,OwnerID=owner,UnitID=removedUnit,
		QueuedTurn=Game.GetCurrentGameTurn(),
		Cancelled=false
	};
	networkRemovalQueue[#networkRemovalQueue+1]=entry;
	networkRemovalBySerial[serial]=entry;
	Trace("network removal queued serial="..serial.." owner="..owner.." unit="..removedUnit.." queuedTurn="..entry.QueuedTurn);
end

local function ReconcileActiveMonsterRemovals(source)
	local missing={}; local liveCount=0;
	local currentTurn=Game.GetCurrentGameTurn();
	for _,serial in ipairs(ActiveMonsterSerials()) do
		if LOTM_WORLD_State.NumberGameProperty(MetaKey(serial,"LIVE"),0)~=1 then
			Game.SetProperty(MetaKey(serial,"MISSING_SINCE"),nil);
			RemoveActiveMonsterSerial(serial);
		else
			local owner=LOTM_WORLD_State.NumberGameProperty(MetaKey(serial,"OWNER"),-1);
			local unitID=LOTM_WORLD_State.NumberGameProperty(MetaKey(serial,"UNIT_ID"),-1);
			local unit=owner>=0 and unitID>=0 and UnitManager.GetUnit(owner,unitID) or nil;
			local unitSerial=unit~=nil and NumberProperty(unit,MONSTER_SERIAL,0) or 0;
			if not Dead(unit) and unitSerial==serial then
				liveCount=liveCount+1;
				if Game.GetProperty(MetaKey(serial,"MISSING_SINCE"))~=nil then Game.SetProperty(MetaKey(serial,"MISSING_SINCE"),nil); end
			else
				local identityReused=unit~=nil and unitSerial~=serial;
				local missingSinceValue=Game.GetProperty(MetaKey(serial,"MISSING_SINCE"));
				local missingSince=missingSinceValue~=nil and tonumber(missingSinceValue) or nil;
				if identityReused or (missingSince~=nil and missingSince<currentTurn) then
					missing[#missing+1]={Serial=serial,OwnerID=owner,UnitID=unitID,IdentityReused=identityReused};
				elseif missingSince==nil then
					Game.SetProperty(MetaKey(serial,"MISSING_SINCE"),currentTurn);
					Trace("active removal awaiting confirmation serial="..serial.." turn="..currentTurn);
				end
			end
		end
	end
	-- The active index is bounded by the monster cap. Recounting it avoids a
	-- full unit/map scan at every stable anchor and makes fallback release safe.
	Game.SetProperty("LOTM_WORLD_MONSTER_LIVE_COUNT",liveCount);
	for _,entry in ipairs(missing) do
		local prefix=ScriptedKillerPrefix(entry.OwnerID,entry.UnitID);
		local engineOwnsIdentity=LOTM_WORLD_State.NumberGameProperty(EngineKey(entry.OwnerID,entry.UnitID),0)==entry.Serial;
		local scriptedIdentityMatches=tostring(Game.GetProperty(prefix.."TARGET_KIND") or "")=="MONSTER"
			and LOTM_WORLD_State.NumberGameProperty(prefix.."TARGET_SERIAL",-1)==entry.Serial;
		local killerID=engineOwnsIdentity and not entry.IdentityReused and scriptedIdentityMatches
			and LOTM_WORLD_State.NumberGameProperty(prefix.."PLAYER",-1) or -1;
		local killerUnitID=killerID>=0 and LOTM_WORLD_State.NumberGameProperty(prefix.."UNIT",-1) or -1;
		local settled,reason=FinalizeRemoval(entry.Serial,entry.OwnerID,entry.UnitID,
			killerID,killerUnitID,Game.GetCurrentGameTurn(),CurrentEraIndex(),true,
			source or "ACTIVE_INDEX",true);
		Trace("active removal reconcile serial="..entry.Serial.." settled="..tostring(settled).." reason="..tostring(reason));
	end
end

local function CombatMonsterSerial(ownerID,unitID)
	local serial=LOTM_WORLD_State.NumberGameProperty(EngineKey(ownerID,unitID),0);
	if serial<=0 then return 0; end
	local unit=UnitManager.GetUnit(ownerID,unitID);
	if unit~=nil and NumberProperty(unit,MONSTER_SERIAL,0)~=serial then return 0; end
	return serial;
end

local function ProcessNetworkRemovals(playerID)
	if not LOTM_MP_TurnSync.IsNetworkGame()
		or not LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID) then return; end
	local currentTurn=Game.GetCurrentGameTurn();
	-- The durable active index is the sole ordering authority.  Reconcile it
	-- first so peers with a delivered, delayed, or save-lost local callback all
	-- finalize the same missing serials in the same order from anchor-time facts.
	ReconcileActiveMonsterRemovals("ACTIVE_INDEX_RUNTIME");
	table.sort(networkRemovalQueue,function(a,b)
		if a.QueuedTurn~=b.QueuedTurn then return a.QueuedTurn<b.QueuedTurn; end
		if a.Serial~=b.Serial then return a.Serial<b.Serial; end
		if a.OwnerID~=b.OwnerID then return a.OwnerID<b.OwnerID; end
		if a.UnitID~=b.UnitID then return a.UnitID<b.UnitID; end
		return a.UnitID<b.UnitID;
	end);
	local index=1;
	while index<=#networkRemovalQueue do
		local entry=networkRemovalQueue[index];
		if entry.Cancelled then
			if networkRemovalBySerial[entry.Serial]==entry then networkRemovalBySerial[entry.Serial]=nil; end
			table.remove(networkRemovalQueue,index);
		elseif entry.QueuedTurn>=currentTurn then
			-- Cross one complete world-turn edge before any Gameplay mutation.
			break;
		else
			-- The synchronized active-index pass above is the only Gameplay
			-- authority.  An aged local publication that did not match a missing
			-- active identity is stale evidence and may only be forgotten.
			if networkRemovalBySerial[entry.Serial]==entry then networkRemovalBySerial[entry.Serial]=nil; end
			table.remove(networkRemovalQueue,index);
			Trace("network removal discarded serial="..entry.Serial.." reason=STALE_LOCAL_PUBLICATION");
		end
	end
end

local function OnCombat(attackerPlayerID,attackerUnitID,defenderPlayerID,defenderUnitID,attackerDistrictID,defenderDistrictID)
	local attackerSerial=CombatMonsterSerial(attackerPlayerID,attackerUnitID);
	local defenderSerial=CombatMonsterSerial(defenderPlayerID,defenderUnitID);
	if attackerSerial>0 then
		Log("engine combat attackerSerial="..attackerSerial.." defenderPlayer="..tostring(defenderPlayerID)
			.." defenderUnit="..tostring(defenderUnitID).." defenderDistrict="..tostring(defenderDistrictID));
	end
	if attackerSerial>0 and Dead(UnitManager.GetUnit(attackerPlayerID,attackerUnitID)) then
		FinalizeRemoval(attackerSerial,attackerPlayerID,attackerUnitID,defenderPlayerID,defenderUnitID,
			Game.GetCurrentGameTurn(),nil,false,"SYNCHRONIZED_COMBAT",true);
	end
	if defenderSerial>0 and Dead(UnitManager.GetUnit(defenderPlayerID,defenderUnitID)) then
		FinalizeRemoval(defenderSerial,defenderPlayerID,defenderUnitID,attackerPlayerID,attackerUnitID,
			Game.GetCurrentGameTurn(),nil,false,"SYNCHRONIZED_COMBAT",true);
	end
end

local function OnRemoved(playerID,unitID)
	if LOTM_MP_TurnSync.IsNetworkGame() then QueueNetworkRemoval(playerID,unitID); return; end
	local serial=LOTM_WORLD_State.NumberGameProperty(EngineKey(playerID,unitID),0);
	if serial>0 then
		local prefix=ScriptedKillerPrefix(playerID,unitID);
		local scriptedIdentityMatches=tostring(Game.GetProperty(prefix.."TARGET_KIND") or "")=="MONSTER"
			and LOTM_WORLD_State.NumberGameProperty(prefix.."TARGET_SERIAL",-1)==serial;
		local killerID=scriptedIdentityMatches and LOTM_WORLD_State.NumberGameProperty(prefix.."PLAYER",-1) or -1;
		local killerUnitID=LOTM_WORLD_State.NumberGameProperty(prefix.."UNIT",-1);
		-- Single-player is immediate, but it must use the same durable completion
		-- gate as combat/network reconciliation.  In particular, LIVE=0 is only
		-- committed after release, optional reward, and captured-identity cleanup.
		FinalizeRemoval(serial,playerID,unitID,killerID,killerUnitID,
			Game.GetCurrentGameTurn(),nil,false,"SINGLE_PLAYER_CALLBACK",true);
	end
end

local function OnTurn(playerID,isFirstTimeThisTurn)
	if isFirstTimeThisTurn==false then return; end
	if LOTM_MP_TurnSync.IsNetworkGame() then ProcessNetworkRemovals(playerID); end
	if playerID~=BarbarianID() then return; end
	for _,monster in ipairs(LiveMonsters()) do Act(monster); end
end

LOTM_MP_TurnSync.Add(OnTurn,"WorldMonsters");
Events.UnitRemovedFromMap.Add(OnRemoved);
GameEvents.OnCombatOccurred.Add(OnCombat);
LOTM_MP_TurnSync.RunStartup(function()
	MigrateActiveMonsterIndex();
	for _,monster in ipairs(LiveMonsters()) do ReconcileMonsterAbilities(monster); end
	if LOTM_MP_TurnSync.IsNetworkGame() then ReconcileActiveMonsterRemovals("ACTIVE_INDEX_STARTUP"); end
end,"WorldMonsters");
Log("initialized ordinary chances=30/30/30 bonus=30 heal=10 reward=500*era caps=1/2/2/3/4/5 cooldown=10 rescuePhase5=dynamic combat=engineSimulationAppliedByResource221Flow turn=multiplayerSynchronized");
-- END POST_RC241_DELTA MODULE: Scripts/LOTM_WORLD_Monsters.lua
end;

m_mp241Loaders["LOTM_WORLD_State"] = function()
-- BEGIN RC241 MODULE: Scripts/LOTM_WORLD_State.lua
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("MP.LOTM_WORLD_State","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"MP.LOTM_WORLD_State","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"MP.LOTM_WORLD_State","GameEvents");
-- END RC342 STARTUP TRACE

-- Shared synchronized helpers for Extraordinary World systems.
LOTM_WORLD_State = LOTM_WORLD_State or {};

LOTM_WORLD_State.VERSION = 6;

function LOTM_WORLD_State.NumberProperty(object,key,default)
	local value=object~=nil and object:GetProperty(key) or nil;
	if value==nil then return default; end
	return tonumber(value) or default;
end

function LOTM_WORLD_State.NumberGameProperty(key,default)
	local value=Game.GetProperty(key);
	if value==nil then return default; end
	return tonumber(value) or default;
end

function LOTM_WORLD_State.GetPlayer(playerID)
	local player=Players[playerID];
	return player~=nil and player:IsAlive() and player:IsMajor() and player or nil;
end

function LOTM_WORLD_State.IsHuman(playerID)
	local player=LOTM_WORLD_State.GetPlayer(playerID);
	return player~=nil and player:IsHuman();
end

function LOTM_WORLD_State.Random(maxExclusive,label)
	if maxExclusive==nil or maxExclusive<=0 then return 0; end
	return Game.GetRandNum(maxExclusive,"LOTM_WORLD:"..tostring(label));
end

function LOTM_WORLD_State.NextPlayerTurn(player)
	local turn=LOTM_WORLD_State.NumberProperty(player,"LOTM_WORLD_PLAYER_TURN",0)+1;
	player:SetProperty("LOTM_WORLD_PLAYER_TURN",turn);
	player:SetProperty("LOTM_WORLD_STATE_VERSION",LOTM_WORLD_State.VERSION);
	return turn;
end

local storedVersion=LOTM_WORLD_State.NumberGameProperty("LOTM_WORLD_STATE_VERSION",0);
if storedVersion<LOTM_WORLD_State.VERSION then
	Game.SetProperty("LOTM_WORLD_STATE_VERSION",LOTM_WORLD_State.VERSION);
end

print("[LOTM_WORLD][State] initialized version="..tostring(LOTM_WORLD_State.VERSION));
-- END RC241 MODULE: Scripts/LOTM_WORLD_State.lua
end;

LOTM_MP241_LoadBundledModule("LOTM_MP241_Compat");
local m_mp241Rescue = LOTM_MP_TurnSync.IsRescueModeConfigured();
if m_mp241Rescue then
	LOTM_MP241_LoadBundledModule("LOTM_RESCUE_DirectMonsters");
end
LOTM_MP241_LoadBundledModule("LOTM_RP_Gameplay");
if m_mp241Rescue then
	LOTM_MP241_LoadBundledModule("LOTM_RESCUE_RuntimeEvents");
	LOTM_MP241_LoadBundledModule("LOTM_RESCUE_Thief");
else
	LOTM_MP241_LoadBundledModule("LOTM_TP_Thief");
end
print("[LOTM][MP241] verified oldBase=rc.241 resource=273 rescue="..tostring(m_mp241Rescue)
	.." unifiedDispatcher=false loaded="..tostring(#(function() local t={} for k in pairs(LOTM_MP241_BUNDLE_LOADED) do t[#t+1]=k; end return t; end)()));
LOTM_MP241_MAIN_READY = true;
end
