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

LOTM_MP_TurnSync.Add(function(playerID,isFirstTimeThisTurn) if isFirstTimeThisTurn~=false then EnsureState(); end end,"RescuePhase6");
LOTM_MP_TurnSync.RunStartup(EnsureState,"RescuePhase6");
Log("loaded version="..VERSION.." active="..tostring(Active()).." rewards=1/2/4 workshops=4/8/12 contributionLeaderboard=true bossFormula=false");
