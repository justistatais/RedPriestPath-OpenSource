-- Rescue-only direct uncontrolled-monster stream.
--
-- This module deliberately lives outside LOTM_WORLD_Monsters.lua.  The latter
-- is the protected ordinary-mode monster implementation; direct rescue
-- refreshes only need to create the same durable monster identity and can
-- therefore remain isolated behind the rescue runtime gate.
include("LOTM_Effects");
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
