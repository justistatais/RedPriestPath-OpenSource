-- Rescue Mode Phase 3: deterministic church Saint/Angel reinforcement and
-- native movement guidance against lost-control monsters and roaming Barbarians.
include("LOTM_RESCUE_SyncActions");

local STATE_KEY="LOTM_RESCUE_PHASE3_STATE";
local CONTENT_VERSION=12;
local CHURCHES={"FOOL","NIGHT","STORM"};
local CAPS={SAINT=3,ANGEL=1};
local REINFORCEMENT_INTERVAL=10;
local LAST_REINFORCEMENT_KEY="LOTM_RESCUE_PHASE3_LAST_REINFORCEMENT_TURN";
local LEGACY_NON_AGGRESSION="ABILITY_LOTM_RESCUE_GUARDIAN_NON_AGGRESSION";
local CENTER_MONSTER_PROPERTY="LOTM_RESCUE_CENTER_MONSTER";
local UNIT_META={};
local m_pendingNetworkRemovals={};
local m_pendingNetworkRemovalKeys={};
for _,church in ipairs(CHURCHES) do
	UNIT_META["UNIT_LOTM_RESCUE_"..church.."_SAINT"]={Church=church,Tier="SAINT"};
	UNIT_META["UNIT_LOTM_RESCUE_"..church.."_ANGEL"]={Church=church,Tier="ANGEL"};
end

local function Log(message) print("[LOTM_RESCUE][Phase3] "..tostring(message)); end
local function Number(value,default) if value==nil then return default; end return tonumber(value) or default; end
local function NetworkSafeFailureValue(singlePlayerDetails,networkCode)
	if GameConfiguration~=nil
		and GameConfiguration.IsAnyMultiplayer~=nil
		and GameConfiguration.IsAnyMultiplayer()==true then
		return tostring(networkCode);
	end
	return tostring(singlePlayerDetails);
end
local function UnitType(church,tier) return "UNIT_LOTM_RESCUE_"..church.."_"..tier; end
local function EngineKey(playerID,unitID) return "LOTM_RESCUE_PHASE3_ENGINE_"..playerID.."_"..unitID; end
local function PendingKey(church,tier) return "LOTM_RESCUE_PHASE3_PENDING_"..church.."_"..tier; end

local function WorldTurn()
	local start=Number(GameConfiguration.GetStartTurn~=nil and GameConfiguration.GetStartTurn() or 0,0);
	return math.max(1,Game.GetCurrentGameTurn()-start+1);
end

local function Owner()
	local playerID=Number(Game.GetProperty("LOTM_RESCUE_TEST_PLAYER_ID"),-1);
	return playerID,playerID>=0 and Players[playerID] or nil;
end

local function IsGuardian(unit)
	if unit==nil then return false,nil,nil; end
	local info=GameInfo.Units[unit:GetType()];
	local unitType=info~=nil and info.UnitType or "";
	local meta=UNIT_META[unitType];
	return meta~=nil,meta~=nil and meta.Church or nil,meta~=nil and meta.Tier or nil;
end

local function RetireLegacyProtocol(unit)
	if unit==nil then return; end
	local abilities=unit:GetAbility();
	if abilities==nil or GameInfo.UnitAbilities[LEGACY_NON_AGGRESSION]==nil then return; end
	local current=abilities:GetAbilityCount(LEGACY_NON_AGGRESSION) or 0;
	if current~=0 then abilities:ChangeAbilityCount(LEGACY_NON_AGGRESSION,-current); end
end

local function IsLostControl(unit)
	if unit==nil then return false; end
	if Number(unit:GetProperty(CENTER_MONSTER_PROPERTY),0)==1 then return true; end
	return LOTM_WORLD_Monsters~=nil and LOTM_WORLD_Monsters.IsMonster~=nil and LOTM_WORLD_Monsters.IsMonster(unit);
end

local function TargetEntries()
	local byPlot={};
	local camp=GameInfo.Improvements.IMPROVEMENT_BARBARIAN_CAMP;
	for _,barbarian in ipairs(PlayerManager.GetAliveBarbarians()) do
		for _,unit in barbarian:GetUnits():Members() do
			if unit~=nil and not unit:IsDead() and not unit:IsDelayedDeath()
				and Number(unit:GetProperty("LOTM_RESCUE_PHASE10_IS_GOD"),0)~=1 then
				local plot=Map.GetPlot(unit:GetX(),unit:GetY());
				if plot~=nil then
					local lost=IsLostControl(unit);
					local onCamp=camp~=nil and plot:GetImprovementType()==camp.Index;
					-- Lost-control monsters remain valid even when born on a workshop,
					-- but ordinary camp defenders are ignored so guardians never strip
					-- or clear camps on behalf of the world coalition.
					if lost or not onCamp then
						if lost then unit:SetProperty("LOTM_RESCUE_GLOBAL_CLEANUP_TARGET",1); end
						local candidate={Plot=plot,Unit=unit,Kind=lost and "LOST_CONTROL" or "BARBARIAN",KindRank=lost and 0 or 1,HasUnit=true};
						local existing=byPlot[plot:GetIndex()];
						if not LOTM_MP_TurnSync.IsNetworkGame() or existing==nil
							or candidate.KindRank<existing.KindRank
							or (candidate.KindRank==existing.KindRank and (unit:GetOwner()<existing.Unit:GetOwner()
								or (unit:GetOwner()==existing.Unit:GetOwner() and unit:GetID()<existing.Unit:GetID()))) then
							byPlot[plot:GetIndex()]=candidate;
						end
					end
				end
			end
		end
	end
	local result={};
	for plotIndex=0,Map.GetPlotCount()-1 do if byPlot[plotIndex]~=nil then result[#result+1]=byPlot[plotIndex]; end end
	return result;
end

local function TargetRank(unit,target)
	local source=Map.GetPlot(unit:GetX(),unit:GetY()); if source==nil then return 4,2147483647; end
	local distance=Map.GetPlotDistance(unit:GetX(),unit:GetY(),target.Plot:GetX(),target.Plot:GetY());
	if distance<=6 then return 0,distance; end
	if distance<=10 then return 1,distance; end
	if source:GetContinentType()==target.Plot:GetContinentType() then return 2,distance; end
	return 3,distance;
end

local function BestTarget(unit,targets,reserved)
	local ranked={};
	for _,target in ipairs(targets) do
		local band,distance=TargetRank(unit,target);
		ranked[#ranked+1]={Target=target,Band=band,Distance=distance,Reserved=reserved[target.Plot:GetIndex()] and 1 or 0};
	end
	table.sort(ranked,function(a,b)
		if a.Reserved~=b.Reserved then return a.Reserved<b.Reserved; end
		if a.Target.KindRank~=b.Target.KindRank then return a.Target.KindRank<b.Target.KindRank; end
		if a.Band~=b.Band then return a.Band<b.Band; end
		if a.Distance~=b.Distance then return a.Distance<b.Distance; end
		return a.Target.Plot:GetIndex()<b.Target.Plot:GetIndex();
	end);
	return ranked[1];
end

local function ClearTarget(unit,target)
	if LOTM_RESCUE_SyncActions==nil then return false,"HELPER_UNAVAILABLE"; end
	if target.HasUnit and target.Unit~=nil and not target.Unit:IsDead() and not target.Unit:IsDelayedDeath() then
		return LOTM_RESCUE_SyncActions.ScriptedKill(target.Unit,unit),"UNIT_CLEARED";
	end
	return false,"TARGET_GONE";
end

local function ExecuteGuide(unit,target)
	if LOTM_RESCUE_SyncActions==nil then return false,"HELPER_UNAVAILABLE"; end
	local distance=Map.GetPlotDistance(unit:GetX(),unit:GetY(),target.Plot:GetX(),target.Plot:GetY());
	if distance<=1 then return ClearTarget(unit,target); end
	-- UnitOperation MOVE_TO and its parameter constants are UI-side APIs and are
	-- absent in this synchronized Gameplay context.  Use the established
	-- Gameplay-safe helper so guardians actually spend their configured per-turn
	-- movement toward the selected lost-control target.
	local info=GameInfo.Units[unit:GetType()];
	local moves=info~=nil and Number(info.BaseMoves,1) or 1;
	local moved,reason,destination=LOTM_RESCUE_SyncActions.MoveToward(unit,target.Plot,moves,false,true);
	unit:SetProperty("LOTM_RESCUE_GUARDIAN_LAST_DESTINATION",destination);
	if not moved then return false,reason; end
	local after=Map.GetPlotDistance(unit:GetX(),unit:GetY(),target.Plot:GetX(),target.Plot:GetY());
	if after<=1 then local cleared,clearReason=ClearTarget(unit,target); return cleared,reason.."+"..clearReason; end
	return true,reason;
end

local function GuideGuardians(player)
	if player==nil then return; end
	local targets=TargetEntries(); local guardians={}; local reserved={};
	for _,unit in player:GetUnits():Members() do
		local guardian=IsGuardian(unit);
		if guardian then RetireLegacyProtocol(unit); guardians[#guardians+1]=unit; end
	end
	table.sort(guardians,function(a,b) return a:GetID()<b:GetID(); end);
	for _,unit in ipairs(guardians) do
		local ranked=BestTarget(unit,targets,reserved); local requested=false; local reason="NO_TARGET";
		if ranked~=nil then
			requested,reason=ExecuteGuide(unit,ranked.Target);
			if requested then reserved[ranked.Target.Plot:GetIndex()]=true; end
			unit:SetProperty("LOTM_RESCUE_GUARDIAN_TARGET_PLOT",ranked.Target.Plot:GetIndex());
			unit:SetProperty("LOTM_RESCUE_GUARDIAN_TARGET_KIND",ranked.Target.Kind);
			unit:SetProperty("LOTM_RESCUE_GUARDIAN_TARGET_X",ranked.Target.Plot:GetX());
			unit:SetProperty("LOTM_RESCUE_GUARDIAN_TARGET_Y",ranked.Target.Plot:GetY());
			Log("guide unit="..unit:GetID().." target="..ranked.Target.Plot:GetIndex().." kind="..ranked.Target.Kind.." band="..ranked.Band.." distance="..ranked.Distance.." requested="..tostring(requested).." reason="..reason);
		else
			unit:SetProperty("LOTM_RESCUE_GUARDIAN_TARGET_PLOT",-1);
		end
		-- PlaceUnit/clear has already resolved synchronously; now prevent the Free
		-- Cities AI from spending the same unit against non-whitelisted targets.
		UnitManager.FinishMoves(unit);
	end
end

local function Count(player,church,tier)
	local expected=GameInfo.Units[UnitType(church,tier)];
	if player==nil or expected==nil then return 0; end
	local count=0;
	for _,unit in player:GetUnits():Members() do if unit:GetType()==expected.Index then count=count+1; end end
	return count;
end

local function MigrationCaps(turn)
	local slots=math.min(4,1+math.floor((math.max(1,turn)-1)/REINFORCEMENT_INTERVAL));
	return {SAINT=math.min(CAPS.SAINT,slots),ANGEL=slots>=4 and CAPS.ANGEL or 0};
end

local function RetireSurplus(playerID,player,turn)
	local retired=0; local failed=0;
	local migrationCaps=MigrationCaps(turn);
	for _,church in ipairs(CHURCHES) do
		for _,tier in ipairs({"SAINT","ANGEL"}) do
			local expected=GameInfo.Units[UnitType(church,tier)]; local units={};
			if expected~=nil then
				for _,unit in player:GetUnits():Members() do if unit:GetType()==expected.Index then units[#units+1]=unit; end end
			end
			table.sort(units,function(a,b) return a:GetID()<b:GetID(); end);
			for index=migrationCaps[tier]+1,#units do
				local unit=units[index]; local unitID=unit:GetID();
				local engineMeta=Game.GetProperty(EngineKey(playerID,unitID));
				Game.SetProperty(EngineKey(playerID,unitID),nil);
				unit:SetProperty("LOTM_RESCUE_PHASE3_BALANCE_RETIRE",1);
				local ok=pcall(UnitManager.Kill,unit);
				local removed=ok and player:GetUnits():FindID(unitID)==nil;
				if removed then
					retired=retired+1; Log("balance retired church="..church.." tier="..tier.." unit="..unitID.." migrationCap="..migrationCaps[tier].." worldTurn="..turn);
				else
					failed=failed+1; Game.SetProperty(EngineKey(playerID,unitID),engineMeta); unit:SetProperty("LOTM_RESCUE_PHASE3_BALANCE_RETIRE",nil);
					Log("balance retire failed church="..church.." tier="..tier.." unit="..unitID);
				end
			end
			Game.SetProperty(PendingKey(church,tier),0);
		end
	end
	Log("balance migration retired="..retired.." failed="..failed.." worldTurn="..turn.." migrationSaintCap="..migrationCaps.SAINT.." migrationAngelCap="..migrationCaps.ANGEL.." finalSaintCap=3 finalAngelCap=1 sharedInterval="..REINFORCEMENT_INTERVAL);
	return failed==0;
end

local function CandidatePlots(church)
	local cityPlotIndex=Number(Game.GetProperty("LOTM_RESCUE_"..church.."_CITY_PLOT"),-1);
	local ownerID=Number(Game.GetProperty("LOTM_RESCUE_TEST_PLAYER_ID"),-1);
	local center=cityPlotIndex>=0 and Map.GetPlotByIndex(cityPlotIndex) or nil;
	if center==nil then return {}; end
	local candidates={}; local seen={};
	local function Add(plot,scope,allowDistrict)
		if plot==nil then return; end
		local index=plot:GetIndex(); local owner=plot:GetOwner();
		if seen[index] or plot:IsWater() or plot:IsImpassable()
			or (not allowDistrict and plot:GetDistrictType()>=0)
			or #(Units.GetUnitsInPlot(plot) or {})~=0 then return; end
		if scope==2 and owner~=-1 and owner~=ownerID then return; end
		seen[index]=true;
		candidates[#candidates+1]={Plot=plot,Scope=scope,Distance=Map.GetPlotDistance(center:GetX(),center:GetY(),plot:GetX(),plot:GetY())};
	end
	local csv=tostring(Game.GetProperty("LOTM_RESCUE_"..church.."_TERRITORY") or "");
	for value in string.gmatch(csv,"[^,]+") do
		local index=tonumber(value); local plot=index~=nil and Map.GetPlotByIndex(index) or nil;
		if plot~=nil and index~=cityPlotIndex and plot:GetOwner()==ownerID then Add(plot,0,false); end
	end
	-- A one-tile island church can own nineteen valid reservation plots while
	-- every non-center plot is water or impassable.  An empty city center is a
	-- legal, deterministic emergency spawn and does not overwrite a unit.
	if center:GetOwner()==ownerID then Add(center,1,true); end
	-- If the center is occupied, search nearby neutral/church land without ever
	-- entering another player's territory. Plot index traversal is synchronized.
	for plotIndex=0,Map.GetPlotCount()-1 do
		local plot=Map.GetPlotByIndex(plotIndex);
		if plot~=nil and Map.GetPlotDistance(center:GetX(),center:GetY(),plot:GetX(),plot:GetY())<=6 then Add(plot,2,false); end
	end
	table.sort(candidates,function(a,b)
		if a.Scope~=b.Scope then return a.Scope<b.Scope; end
		if a.Distance~=b.Distance then return a.Distance<b.Distance; end
		return a.Plot:GetIndex()<b.Plot:GetIndex();
	end);
	return candidates;
end

local function Spawn(playerID,church,tier,turn,cap,live)
	local info=GameInfo.Units[UnitType(church,tier)];
	if info==nil then Log("spawn delayed reason=UNIT_TYPE_MISSING church="..church.." tier="..tier); return false; end
	local candidates=CandidatePlots(church);
	if #candidates==0 then Log("spawn delayed reason=NO_LEGAL_EMPTY_PLOT church="..church.." tier="..tier.." turn="..turn.." fallbackRadius=6"); return false; end
	local selected=candidates[1];
	local ok,unit=pcall(UnitManager.InitUnit,playerID,info.Index,selected.Plot:GetX(),selected.Plot:GetY());
	if not ok or unit==nil then Log("spawn delayed reason=INIT_FAILED church="..church.." tier="..tier.." turn="..turn); return false; end
	local serial=Number(Game.GetProperty("LOTM_RESCUE_PHASE3_NEXT_SERIAL"),0)+1;
	Game.SetProperty("LOTM_RESCUE_PHASE3_NEXT_SERIAL",serial);
	unit:SetProperty("LOTM_RESCUE_GUARDIAN_CHURCH",church);
	unit:SetProperty("LOTM_RESCUE_GUARDIAN_TIER",tier);
	unit:SetProperty("LOTM_RESCUE_GUARDIAN_SERIAL",serial);
	Game.SetProperty(EngineKey(playerID,unit:GetID()),church..":"..tier..":"..serial);
	local experience=unit:GetExperience(); if experience~=nil then experience:SetExperienceLocked(true); end
	UnitManager.FinishMoves(unit);
	local pending=Number(Game.GetProperty(PendingKey(church,tier)),0);
	local reason=pending>0 and "DEATH_REPLACEMENT" or "TARGET_DEFICIT";
	if pending>0 then Game.SetProperty(PendingKey(church,tier),pending-1); end
	Log("spawned turn="..turn.." church="..church.." tier="..tier.." serial="..serial.." unit="..unit:GetID().." plot="..selected.Plot:GetIndex().." scope="..selected.Scope.." legalCandidates="..#candidates.." live="..(live+1).." cap="..cap.." reason="..reason);
	return true;
end

local function ReinforcementTier(player,church)
	for _,tier in ipairs({"SAINT","ANGEL"}) do
		if Count(player,church,tier)<CAPS[tier] and Number(Game.GetProperty(PendingKey(church,tier)),0)>0 then return tier; end
	end
	for _,tier in ipairs({"SAINT","ANGEL"}) do if Count(player,church,tier)<CAPS[tier] then return tier; end end
	return nil;
end

local function RunReinforcementCheck(turn)
	local last=Number(Game.GetProperty(LAST_REINFORCEMENT_KEY),-1000000);
	if turn-last<REINFORCEMENT_INTERVAL then return; end
	Game.SetProperty(LAST_REINFORCEMENT_KEY,turn);
	local playerID,player=Owner(); if player==nil then return; end
	Log("reinforcement check turn="..turn.." interval="..REINFORCEMENT_INTERVAL.." maxPerChurch=1");
	for _,church in ipairs(CHURCHES) do
		local tier=ReinforcementTier(player,church);
		if tier~=nil then Spawn(playerID,church,tier,turn,CAPS[tier],Count(player,church,tier)); end
	end
end

local function EnsureOpeningSaints(playerID,player,turn)
	for _,church in ipairs(CHURCHES) do
		local live=Count(player,church,"SAINT");
		if live<1 then Spawn(playerID,church,"SAINT",turn,CAPS.SAINT,live); end
	end
	Game.SetProperty(LAST_REINFORCEMENT_KEY,turn);
end

local function Initialize()
	if Game.GetProperty("LOTM_RESCUE_PHASE2A_STATE")~="READY" then return false; end
	local playerID,player=Owner();
	if player==nil or not player:IsAlive() then Log("initialize delayed reason=OWNER_NOT_READY"); return false; end
	local speed=GameConfiguration.GetGameSpeedType(); local turn=WorldTurn();
	local version=Number(Game.GetProperty("LOTM_RESCUE_PHASE3_VERSION"),0);
	if Game.GetProperty(STATE_KEY)~="READY" or version<CONTENT_VERSION then
		if version<CONTENT_VERSION and not RetireSurplus(playerID,player,turn) then return false; end
		Game.SetProperty("LOTM_RESCUE_PHASE3_VERSION",CONTENT_VERSION);
		Game.SetProperty("LOTM_RESCUE_PHASE3_GAME_SPEED",speed);
		EnsureOpeningSaints(playerID,player,turn);
		Game.SetProperty(STATE_KEY,"READY");
		Game.SetProperty("LOTM_RESCUE_PHASE",3);
		Log("READY version="..CONTENT_VERSION.." owner="..playerID.." speed="..tostring(speed).." worldTurn="..turn.." saintCap=3 angelCap=1 sharedInterval=10 maxPerChurchPerCheck=1 opening=saint_only cleanupGuidance=gameplay_sync_move_lost_control_first_no_camps persistentMarks=true");
	end
	for _,unit in player:GetUnits():Members() do local guardian=IsGuardian(unit); if guardian then RetireLegacyProtocol(unit); end end
	return true;
end

local function ApplyRemoved(playerID,unitID,capturedMeta)
	local ownerID=Number(Game.GetProperty("LOTM_RESCUE_TEST_PLAYER_ID"),-1);
	if playerID~=ownerID then return; end
	local meta=tostring(capturedMeta or Game.GetProperty(EngineKey(playerID,unitID)) or "");
	local church,tier,serial=string.match(meta,"^([^:]+):([^:]+):(%d+)$");
	if UNIT_META["UNIT_LOTM_RESCUE_"..tostring(church).."_"..tostring(tier)]==nil then return; end
	Game.SetProperty(EngineKey(playerID,unitID),nil);
	local pending=Number(Game.GetProperty(PendingKey(church,tier)),0)+1;
	Game.SetProperty(PendingKey(church,tier),pending);
	Log("removed turn="..WorldTurn().." church="..church.." tier="..tier.." serial="..serial.." unit="..unitID.." pendingReplacement="..pending.." nextSharedCheckInterval="..REINFORCEMENT_INTERVAL);
end

local function QueueNetworkRemoval(playerID,unitID)
	local normalizedPlayerID=tonumber(playerID); local normalizedUnitID=tonumber(unitID);
	if normalizedPlayerID==nil or normalizedUnitID==nil then return; end
	local ownerID=Number(Game.GetProperty("LOTM_RESCUE_TEST_PLAYER_ID"),-1);
	if normalizedPlayerID~=ownerID then return; end
	local meta=tostring(Game.GetProperty(EngineKey(normalizedPlayerID,normalizedUnitID)) or "");
	local church,tier,serial=string.match(meta,"^([^:]+):([^:]+):(%d+)$");
	serial=tonumber(serial);
	if serial==nil or UNIT_META["UNIT_LOTM_RESCUE_"..tostring(church).."_"..tostring(tier)]==nil then return; end
	local key=tostring(normalizedPlayerID)..":"..tostring(normalizedUnitID)..":"..meta;
	if m_pendingNetworkRemovalKeys[key]~=nil then return; end
	local entry={Church=church,Tier=tier,Serial=serial,PlayerID=normalizedPlayerID,UnitID=normalizedUnitID,
		Meta=meta,QueuedTurn=Game.GetCurrentGameTurn(),Key=key};
	m_pendingNetworkRemovals[#m_pendingNetworkRemovals+1]=entry;
	m_pendingNetworkRemovalKeys[key]=entry;
end

local function ProcessNetworkRemovals(playerID)
	if not LOTM_MP_TurnSync.IsNetworkGame() or not LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID) then return; end
	local currentTurn=Game.GetCurrentGameTurn(); local ready={}; local waiting={};
	for _,entry in ipairs(m_pendingNetworkRemovals) do
		if entry.QueuedTurn<currentTurn then ready[#ready+1]=entry; else waiting[#waiting+1]=entry; end
	end
	m_pendingNetworkRemovals=waiting;
	table.sort(ready,function(a,b)
		if a.Church~=b.Church then return a.Church<b.Church; end
		if a.Tier~=b.Tier then return a.Tier<b.Tier; end
		if a.Serial~=b.Serial then return a.Serial<b.Serial; end
		if a.PlayerID~=b.PlayerID then return a.PlayerID<b.PlayerID; end
		return a.UnitID<b.UnitID;
	end);
	for _,entry in ipairs(ready) do
		if m_pendingNetworkRemovalKeys[entry.Key]==entry then m_pendingNetworkRemovalKeys[entry.Key]=nil; end
		local liveMeta=tostring(Game.GetProperty(EngineKey(entry.PlayerID,entry.UnitID)) or "");
		local liveChurch,liveTier,liveSerial=string.match(liveMeta,"^([^:]+):([^:]+):(%d+)$");
		liveSerial=tonumber(liveSerial);
		local unit=UnitManager.GetUnit(entry.PlayerID,entry.UnitID);
		local removed=unit==nil or unit:IsDead() or unit:IsDelayedDeath();
		if removed and liveMeta==entry.Meta and liveChurch==entry.Church and liveTier==entry.Tier and liveSerial==entry.Serial then
			ApplyRemoved(entry.PlayerID,entry.UnitID,entry.Meta);
		else
			local unitSerial=unit~=nil and Number(unit:GetProperty("LOTM_RESCUE_GUARDIAN_SERIAL"),-1) or -1;
			Log("deferred removal discarded church="..entry.Church.." tier="..entry.Tier.." serial="..entry.Serial
				.." player="..entry.PlayerID.." unit="..entry.UnitID.." liveMeta="..liveMeta.." liveSerial="..tostring(liveSerial)
				.." unitSerial="..unitSerial.." removed="..tostring(removed));
		end
	end
end

local function OnRemoved(playerID,unitID)
	if LOTM_MP_TurnSync.IsNetworkGame() then QueueNetworkRemoval(playerID,unitID); return; end
	ApplyRemoved(playerID,unitID,nil);
end

local function OnSynchronizedCombat(attackerPlayerID,attackerUnitID,defenderPlayerID,defenderUnitID)
	if not LOTM_MP_TurnSync.IsNetworkGame() then return; end
	for _,entry in ipairs({
		{PlayerID=attackerPlayerID,UnitID=attackerUnitID},
		{PlayerID=defenderPlayerID,UnitID=defenderUnitID}
	}) do
		local unit=UnitManager.GetUnit(entry.PlayerID,entry.UnitID);
		if entry.UnitID~=nil and entry.UnitID>=0
			and (unit==nil or unit:IsDead() or unit:IsDelayedDeath())
			and Game.GetProperty(EngineKey(entry.PlayerID,entry.UnitID))~=nil then
			ApplyRemoved(entry.PlayerID,entry.UnitID,nil);
		end
	end
end

local function ProcessTurn(playerID,isFirstTimeThisTurn)
	if isFirstTimeThisTurn==false then return; end
	local version=Number(Game.GetProperty("LOTM_RESCUE_PHASE3_VERSION"),0);
	if Game.GetProperty(STATE_KEY)~="READY" or version<CONTENT_VERSION then if not Initialize() then return; end end
	if LOTM_MP_TurnSync.IsNetworkGame() then ProcessNetworkRemovals(playerID); end
	local ownerID,player=Owner(); if playerID~=ownerID or player==nil then return; end
	local turn=WorldTurn();
	RunReinforcementCheck(turn);
	GuideGuardians(player);
end

local function OnBootstrapCity()
	local ok,details=pcall(Initialize);
	if not ok then
		Game.SetProperty("LOTM_RESCUE_PHASE3_RUNTIME_FAILURE",
			NetworkSafeFailureValue(details,"RUNTIME_GUARD_BOOTSTRAP"));
		Log("guarded failure details="..tostring(details));
	end
end

local networkGame=GameConfiguration~=nil
	and GameConfiguration.IsAnyMultiplayer~=nil
	and GameConfiguration.IsAnyMultiplayer()==true;
local authoritativeNetworkContext=networkGame
	and LOTM_RP_MASTER_GAMEPLAY_CONTEXT==true;
if not networkGame then
	-- Preserve the independent single-player add-in and original listeners.
	GameEvents.LOTM_RESCUE_Command_BootstrapCity.Add(OnBootstrapCity);
	if LOTM_MP_TurnSync==nil then include("LOTM_MP_TurnSync"); end
	LOTM_MP_TurnSync.Add(ProcessTurn,"RescuePhase3");
	Events.UnitRemovedFromMap.Add(OnRemoved);
	Log("loaded state="..tostring(Game.GetProperty(STATE_KEY) or "NONE").." waitingForPhase2=true");
elseif authoritativeNetworkContext then
	if LOTM_MP_TurnSync==nil or type(LOTM_MP_TurnSync.Add)~="function" then
		error("[LOTM_RESCUE][Phase3] master multiplayer turn adapter unavailable");
	end
	LOTM_MP_TurnSync.Add(ProcessTurn,"RescuePhase3");
	Events.UnitRemovedFromMap.Add(OnRemoved);
	GameEvents.OnCombatOccurred.Add(OnSynchronizedCombat);
	Log("loaded state="..tostring(Game.GetProperty(STATE_KEY) or "NONE").." waitingForStablePostPhase2Turn=true context=multiplayer-master");
else
	Log("passive standalone network context; master Gameplay owns commands, turns, and unit events");
end
