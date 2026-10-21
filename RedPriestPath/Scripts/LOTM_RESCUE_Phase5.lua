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
