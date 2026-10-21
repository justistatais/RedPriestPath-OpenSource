-- Rescue Mode Phase 2: four sealed cities using the engine's neutral Free
-- Cities owner. Only the four recorded cities/territories are Rescue content;
-- this script never changes global Free Cities diplomacy or other cities.

local STATE_KEY="LOTM_RESCUE_PHASE2A_STATE";
local OWNER_VERSION=7;
local CONTENT_VERSION=11;
local WALL_TYPES={"BUILDING_WALLS","BUILDING_CASTLE","BUILDING_STAR_FORT"};
local ZONES={"CENTER","FOOL","NIGHT","STORM"};
local m_anchorTurn=-1;

local function NetworkSafeFailureValue(singlePlayerDetails,networkCode)
	if GameConfiguration~=nil
		and GameConfiguration.IsAnyMultiplayer~=nil
		and GameConfiguration.IsAnyMultiplayer()==true then
		return tostring(networkCode);
	end
	return tostring(singlePlayerDetails);
end

local function Fail(reason)
	Game.SetProperty(STATE_KEY,"FAILED");
	Game.SetProperty("LOTM_RESCUE_PHASE2A_FAILURE",reason);
	Game.SetProperty("LOTM_RESCUE_PHASE2A_OWNER_VERSION",OWNER_VERSION);
	print("[LOTM_RESCUE][Phase2A] FAILED reason="..reason);
end

local function Territory(zone)
	local plots={}; local seen={};
	local csv=tostring(Game.GetProperty("LOTM_RESCUE_"..zone.."_TERRITORY") or "");
	for value in string.gmatch(csv,"[^,]+") do
		local index=tonumber(value);
		local plot=index~=nil and Map.GetPlotByIndex(index) or nil;
		if plot~=nil and not seen[index] then seen[index]=true; plots[#plots+1]=plot; end
	end
	table.sort(plots,function(a,b) return a:GetIndex()<b:GetIndex(); end);
	return plots;
end

local function RegularMinorCount()
	local count=0;
	for _ in ipairs(PlayerManager.GetAliveMinors()) do count=count+1; end
	return count;
end

local function NeutralOwner()
	local playerID=PlayerManager.GetFreeCitiesPlayerID();
	if playerID==nil or playerID<0 then return nil,nil; end
	return playerID,Players[playerID];
end

local function RegisteredSealsExist(playerID)
	if playerID==nil or playerID<0 then return false; end
	for _,zone in ipairs(ZONES) do
		local plotIndex=tonumber(Game.GetProperty("LOTM_RESCUE_"..zone.."_CITY_PLOT") or -1);
		local cityID=tonumber(Game.GetProperty("LOTM_RESCUE_"..zone.."_CITY_ID") or -1);
		local plot=plotIndex~=nil and plotIndex>=0 and Map.GetPlotByIndex(plotIndex) or nil;
		local city=plot~=nil and CityManager.GetCityAt(plot:GetX(),plot:GetY()) or nil;
		if city==nil or city:GetOwner()~=playerID or city:GetID()~=cityID then return false; end
	end
	return true;
end

local function CityName(zone)
	local english=GameConfiguration.GetValue("LOTM_RP_TEXT_LANGUAGE")=="en_US";
	local names=english and {
		CENTER="Astral Descent",FOOL="Church of the Fool Holy City",
		NIGHT="Church of the Evernight Goddess Holy City",STORM="Church of the Lord of Storms Holy City"
	} or {
		CENTER="星空降临",FOOL="愚者教会圣城",
		NIGHT="黑夜女神教会圣城",STORM="风暴之主教会圣城"
	};
	return names[zone];
end

local function CompleteMedievalDevelopment(player)
	local techs=player:GetTechs(); local culture=player:GetCulture();
	if techs==nil or culture==nil then return false,"DEVELOPMENT_COMPONENT_MISSING"; end
	-- One medieval technology and one medieval civic are sufficient to put the
	-- neutral owner in medieval development. Completing every earlier entry
	-- during game initialization caused hundreds of completion events and kept
	-- the client in WAIT_FOR_PLAYERS for more than three minutes.
	local tech=GameInfo.Technologies["TECH_CASTLES"];
	local civic=GameInfo.Civics["CIVIC_MEDIEVAL_FAIRES"];
	if tech==nil or civic==nil then return false,"MEDIEVAL_DEVELOPMENT_TYPE_MISSING"; end
	if not techs:HasTech(tech.Index) then techs:SetResearchProgress(tech.Index,techs:GetResearchCost(tech.Index)); end
	if not culture:HasCivic(civic.Index) then culture:SetCulturalProgress(civic.Index,culture:GetCultureCost(civic.Index)); end
	return true,nil;
end

local function CreateAndVerifyBuildings(city)
	local queue=city:GetBuildQueue(); local buildings=city:GetBuildings();
	if queue==nil or buildings==nil then return false,"CITY_BUILDING_COMPONENT_MISSING"; end
	local required={"BUILDING_LOTM_RESCUE_SEAL_CORE"};
	for _,buildingType in ipairs(WALL_TYPES) do required[#required+1]=buildingType; end
	for _,buildingType in ipairs(required) do
		local row=GameInfo.Buildings[buildingType];
		if row==nil then return false,"BUILDING_TYPE_MISSING_"..buildingType; end
		if not buildings:HasBuilding(row.Index) then queue:CreateBuilding(row.Index); end
		if not buildings:HasBuilding(row.Index) then return false,"BUILDING_CREATE_FAILED_"..buildingType; end
	end
	return true,nil;
end

local function LockLoyalty(city)
	if city==nil then return false; end
	city:SetProperty("LOTM_RESCUE_SEAL_LOYALTY_LOCK",1);
	-- GetCulturalIdentity is a UI-only method on the current Gathering Storm
	-- runtime. Gameplay does expose ChangeLoyalty, which clamps at the normal
	-- 100-point ceiling. Never call this from CityLoyaltyChanged: that event is
	-- queued after ChangeLoyalty returns and would form an unbounded feedback
	-- loop. Initialization and the Free Cities owner turn are sufficient.
	city:ChangeLoyalty(100);
	return true;
end

local function RestoreCity(city,playerID,zone)
	if city==nil or city:GetOwner()~=playerID then return; end
	if city:GetPopulation()~=1 then city:ChangePopulation(1-city:GetPopulation()); end
	local loyaltyCorrected=LockLoyalty(city);
	for _,plot in ipairs(Territory(zone)) do if plot:GetOwner()~=playerID then plot:SetOwner(playerID); end end
	-- City:GetDistrictID() is exposed to UI contexts but is nil in synchronized
	-- Gameplay on the current Gathering Storm runtime.  Resolve the city-center
	-- district through the engine's coordinate API, as Firaxis scenarios do.
	local district=CityManager.GetDistrictAt(city:GetX(),city:GetY());
	if district~=nil then
		district:SetDamage(DefenseTypes.DISTRICT_OUTER,0);
		district:SetDamage(DefenseTypes.DISTRICT_GARRISON,0);
	end
	return loyaltyCorrected;
end

local function ValidateZone(zone,playerID,allowRegisteredReclaim)
	local centerIndex=tonumber(Game.GetProperty("LOTM_RESCUE_"..zone.."_PLOT") or -1);
	local center=centerIndex~=nil and centerIndex>=0 and Map.GetPlotByIndex(centerIndex) or nil;
	if center==nil then return nil,nil,"MISSING"; end
	local territory=Territory(zone);
	if #territory~=19 then return nil,nil,"TERRITORY_NOT_19"; end
	local city=CityManager.GetCityAt(center:GetX(),center:GetY());
	if city~=nil and city:GetOwner()~=playerID then return nil,nil,"CENTER_OCCUPIED"; end
	if city==nil and center:GetDistrictType()>=0 then return nil,nil,"CENTER_DISTRICT_OCCUPIED"; end
	for _,plot in ipairs(territory) do
		local owner=plot:GetOwner();
		if owner~=-1 and owner~=playerID and not (allowRegisteredReclaim and city~=nil) then
			return nil,nil,"TERRITORY_ALREADY_OWNED_"..plot:GetIndex();
		end
	end
	return center,territory,nil;
end

local function CreateOrUpgradeZone(playerID,player,zone,center,territory)
	local city=CityManager.GetCityAt(center:GetX(),center:GetY());
	if city==nil then
		player:GetCities():Create(center:GetX(),center:GetY());
		city=CityManager.GetCityAt(center:GetX(),center:GetY());
	end
	if city==nil or city:GetOwner()~=playerID then return nil,"CITY_CREATE_FAILED"; end
	print("[LOTM_RESCUE][Phase2] checkpoint city-created zone="..zone.." player="..playerID.." city="..city:GetID().." plot="..center:GetIndex());
	city:SetName(CityName(zone));
	if city:GetPopulation()~=1 then city:ChangePopulation(1-city:GetPopulation()); end
	for _,plot in ipairs(territory) do if plot:GetOwner()~=playerID then plot:SetOwner(playerID); end end
	local owned=0;
	for _,plot in ipairs(territory) do if plot:GetOwner()==playerID then owned=owned+1; end end
	if owned~=19 then return nil,"OWNED_TERRITORY_"..owned.."_OF_19"; end
	local built,buildingFailure=CreateAndVerifyBuildings(city);
	if not built then return nil,buildingFailure; end
	RestoreCity(city,playerID,zone);
	Game.SetProperty("LOTM_RESCUE_"..zone.."_CITY_ID",city:GetID());
	Game.SetProperty("LOTM_RESCUE_"..zone.."_CITY_PLOT",center:GetIndex());
	return city,nil;
end

local function Initialize()
	local existing=Game.GetProperty(STATE_KEY);
	-- A load-screen UI command can arrive before the first synchronized network
	-- turn. Phase 1 now establishes its map reservation at that turn boundary;
	-- do not permanently fail Phase 2 merely because a local UI context loaded
	-- first. Single-player retains the legacy immediate failure semantics.
	if Game.GetProperty("LOTM_RESCUE_PHASE1_STATE")~="READY"
		and GameConfiguration~=nil
		and GameConfiguration.IsAnyMultiplayer~=nil
		and GameConfiguration.IsAnyMultiplayer()==true then
		if existing=="FAILED" and tostring(Game.GetProperty("LOTM_RESCUE_PHASE2A_FAILURE") or "")=="PHASE1_NOT_READY" then
			Game.SetProperty(STATE_KEY,nil);
			Game.SetProperty("LOTM_RESCUE_PHASE2A_FAILURE",nil);
		end
		print("[LOTM_RESCUE][Phase2A] network bootstrap deferred reason=PHASE1_NOT_READY");
		return false;
	end
	if existing=="READY" then
		local version=tonumber(Game.GetProperty("LOTM_RESCUE_PHASE2A_VERSION") or 0) or 0;
		if version>=CONTENT_VERSION then
			if GameConfiguration.IsAnyMultiplayer~=nil and GameConfiguration.IsAnyMultiplayer()==true
				and Game.GetProperty("LOTM_RESCUE_PHASE2A_READY_GAME_TURN")==nil then
				Game.SetProperty("LOTM_RESCUE_PHASE2A_READY_GAME_TURN",Game.GetCurrentGameTurn());
			end
			print("[LOTM_RESCUE][Phase2A] reload state=READY"); return;
		end
		print("[LOTM_RESCUE][Phase2A] upgrading existing seal city content version="..version.."->"..CONTENT_VERSION);
	end
	if existing=="FAILED" then
		local failure=tostring(Game.GetProperty("LOTM_RESCUE_PHASE2A_FAILURE") or "");
		local ownerVersion=tonumber(Game.GetProperty("LOTM_RESCUE_PHASE2A_OWNER_VERSION") or 0) or 0;
		local recoveryAttempt=tonumber(Game.GetProperty("LOTM_RESCUE_PHASE2A_RECOVERY_ATTEMPT_VERSION") or 0) or 0;
		local legacyMigratable=failure=="PHASE1_NOT_READY"
			or failure=="SPECIAL_PLAYER_NOT_ALIVE"
			or string.match(failure,"^CITY_STATE_COUNT_CHANGED_requested_%-1_regular_%d+$")~=nil
			or failure=="BUILDING_TYPE_MISSING_BUILDING_ANCIENT_WALLS";
		local runtimeMigratable=failure=="RUNTIME_GUARD" and recoveryAttempt<CONTENT_VERSION;
		if (not legacyMigratable or ownerVersion>=OWNER_VERSION) and not runtimeMigratable then
			print("[LOTM_RESCUE][Phase2A] reload state=FAILED reason="..failure);
			return;
		end
		if runtimeMigratable then
			Game.SetProperty("LOTM_RESCUE_PHASE2A_RECOVERY_ATTEMPT_VERSION",CONTENT_VERSION);
			print("[LOTM_RESCUE][Phase2A] recovering registered seal cities from runtime guard contentVersion="..CONTENT_VERSION
				.." previousDetails="..tostring(Game.GetProperty("LOTM_RESCUE_PHASE2A_RUNTIME_FAILURE") or "UNKNOWN"));
		else
			print("[LOTM_RESCUE][Phase2A] migrating resource136 failed slot probe to neutral owner");
		end
	end
	if Game.GetProperty("LOTM_RESCUE_PHASE1_STATE")~="READY" then Fail("PHASE1_NOT_READY"); return; end

	local playerID,player=NeutralOwner();
	if player==nil or not player:IsAlive() then Fail("NEUTRAL_OWNER_NOT_ALIVE"); return; end
	if player:IsMajor() or player:IsBarbarian() then Fail("NEUTRAL_OWNER_CLASSIFICATION_INVALID"); return; end
	Game.SetProperty("LOTM_RESCUE_TEST_PLAYER_ID",playerID);
	Game.SetProperty("LOTM_RESCUE_PHASE2A_OWNER_KIND","FREE_CITIES");
	local registeredSeals=RegisteredSealsExist(playerID);

	local requested=tonumber(GameConfiguration.GetValue("CITY_STATE_COUNT") or -1) or -1;
	local regular=RegularMinorCount();
	Game.SetProperty("LOTM_RESCUE_REQUESTED_CITY_STATES",requested);
	Game.SetProperty("LOTM_RESCUE_REGULAR_CITY_STATES",regular);
	if not registeredSeals and (requested<0 or regular~=requested) then
		Fail("CITY_STATE_COUNT_CHANGED_requested_"..requested.."_regular_"..regular);
		return;
	end
	if registeredSeals and regular~=requested then
		print("[LOTM_RESCUE][Phase2A] registered old-save cities bypass mutable city-state count requested="..requested.." currentAlive="..regular);
	end

	local validated={};
	for _,zone in ipairs(ZONES) do
		local center,territory,zoneFailure=ValidateZone(zone,playerID,registeredSeals);
		if zoneFailure~=nil then Fail(zone.."_"..zoneFailure); return; end
		validated[zone]={Center=center,Territory=territory};
	end
	print("[LOTM_RESCUE][Phase2] checkpoint reservations-valid zones=4 plots=76 cityStates="..regular);
	local developed,developmentFailure=CompleteMedievalDevelopment(player);
	if not developed then Fail(developmentFailure); return; end
	print("[LOTM_RESCUE][Phase2] checkpoint medieval-development");
	local cities={}; local cityIDs={};
	for _,zone in ipairs(ZONES) do
		local data=validated[zone];
		local city,zoneFailure=CreateOrUpgradeZone(playerID,player,zone,data.Center,data.Territory);
		if city==nil then Fail(zone.."_"..zoneFailure); return; end
		cities[zone]=city; cityIDs[#cityIDs+1]=tostring(city:GetID());
	end
	table.sort(cityIDs);
	print("[LOTM_RESCUE][Phase2] checkpoint buildings-created cities=4 walls=12");

	Game.SetProperty("LOTM_RESCUE_PHASE",2);
	Game.SetProperty("LOTM_RESCUE_PHASE2A_VERSION",CONTENT_VERSION);
	Game.SetProperty("LOTM_RESCUE_PHASE2A_OWNER_VERSION",OWNER_VERSION);
	Game.SetProperty("LOTM_RESCUE_TEST_CITY_ID",cities.CENTER:GetID());
	Game.SetProperty("LOTM_RESCUE_TEST_CITY_PLOT",validated.CENTER.Center:GetIndex());
	Game.SetProperty("LOTM_RESCUE_SEAL_CITY_IDS",table.concat(cityIDs,","));
	Game.SetProperty("LOTM_RESCUE_PHASE2A_FAILURE","NONE");
	Game.SetProperty("LOTM_RESCUE_PHASE2A_RUNTIME_FAILURE",nil);
	if GameConfiguration.IsAnyMultiplayer~=nil and GameConfiguration.IsAnyMultiplayer()==true then
		Game.SetProperty("LOTM_RESCUE_PHASE2A_READY_GAME_TURN",Game.GetCurrentGameTurn());
	end
	Game.SetProperty(STATE_KEY,"READY");
	print("[LOTM_RESCUE][Phase2] READY owner=FREE_CITIES player="..playerID.." cities=4 cityIDs="..table.concat(cityIDs,",").." population=1 each era="..tostring(player:GetEra()).." walls=3 each defenseBonus=200/200 loyalty=100 loyaltyPerTurn=10000 gameplayCorrection=ChangeLoyalty territory=19 each regularCityStates="..regular.." requestedCityStates="..requested);
end

local function OnBootstrapCity(requestPlayerID,parameters)
	local requester=Players[requestPlayerID];
	if requester==nil or not requester:IsAlive() or not requester:IsMajor() or not requester:IsHuman() then
		print("[LOTM_RESCUE][Phase2A] bootstrap rejected player="..tostring(requestPlayerID));
		return;
	end
	print("[LOTM_RESCUE][Phase2A] bootstrap accepted player="..requestPlayerID
		.." trigger="..tostring(parameters~=nil and parameters.Trigger or "UNKNOWN"));
	if LOTM_MP_TurnSync~=nil
		and type(LOTM_MP_TurnSync.IsNetworkGame)=="function"
		and LOTM_MP_TurnSync.IsNetworkGame()
		and type(LOTM_MP_TurnSync.IsRescueModeConfigured)=="function"
		and LOTM_MP_TurnSync.IsRescueModeConfigured()
		and type(LOTM_MP_TurnSync.RunPendingStartups)=="function" then
		LOTM_MP_TurnSync.RunPendingStartups(requestPlayerID,
			"EXECUTE_SCRIPT:"..tostring(parameters~=nil and parameters.Trigger or "UNKNOWN"));
		if Game.GetProperty("LOTM_RESCUE_PHASE1_STATE")=="READY"
			and Game.GetProperty("LOTM_RESCUE_PHASE2A_STATE")=="READY"
			and LOTM_RESCUE_Phase8~=nil
			and type(LOTM_RESCUE_Phase8.EstablishOpeningCoalition)=="function" then
			local ok,result,reason=pcall(LOTM_RESCUE_Phase8.EstablishOpeningCoalition);
			if not ok then
				print("[LOTM_RESCUE][Phase2A] opening coalition local failure details="
					..tostring(result));
			else
				print("[LOTM_RESCUE][Phase2A] opening coalition result="..tostring(result)
					.." reason="..tostring(reason));
			end
		end
		return;
	end
	local ok,details=pcall(Initialize);
	if not ok then
		Game.SetProperty("LOTM_RESCUE_PHASE2A_RUNTIME_FAILURE",
			NetworkSafeFailureValue(details,"RUNTIME_GUARD_BOOTSTRAP"));
		Fail("RUNTIME_GUARD");
		print("[LOTM_RESCUE][Phase2A] guarded runtime failure details="..tostring(details));
	end
end
-- Preserve the original single-player synchronized-turn fallback. Network
-- startup is owned by the master Gameplay dispatcher above.
local function LowestAliveHumanMajor()
 local best=nil;
 for _,player in ipairs(PlayerManager.GetAliveMajors()) do
  if player:IsHuman() and (best==nil or player:GetID()<best) then best=player:GetID(); end
 end
 return best;
end
local function OnSynchronizedTurnStart(playerID)
 if m_anchorTurn==Game.GetCurrentGameTurn() then return; end
 if Game.GetProperty(STATE_KEY)=="READY" then
  if playerID==LowestAliveHumanMajor()
   and GameConfiguration.IsAnyMultiplayer~=nil and GameConfiguration.IsAnyMultiplayer()==true
   and Game.GetProperty("LOTM_RESCUE_PHASE2A_READY_GAME_TURN")==nil then
   Game.SetProperty("LOTM_RESCUE_PHASE2A_READY_GAME_TURN",Game.GetCurrentGameTurn());
  end
  return;
 end
 if Game.GetProperty("LOTM_RESCUE_PHASE1_STATE")~="READY" then return; end
 if playerID~=LowestAliveHumanMajor() then return; end
 m_anchorTurn=Game.GetCurrentGameTurn();
 local ok,details=pcall(Initialize);
 if not ok then
  Game.SetProperty("LOTM_RESCUE_PHASE2A_RUNTIME_FAILURE",
   NetworkSafeFailureValue(details,"RUNTIME_GUARD_SYNCHRONIZED_BOOTSTRAP"));
  Fail("RUNTIME_GUARD");
  print("[LOTM_RESCUE][Phase2A] synchronized bootstrap runtime failure details="..tostring(details));
 end
end

local function Maintain(playerID)
	local owner=tonumber(Game.GetProperty("LOTM_RESCUE_TEST_PLAYER_ID") or -1);
	if playerID~=owner or not RegisteredSealsExist(owner) then return; end
	local player=Players[owner]; if player==nil then return; end
	for _,zone in ipairs(ZONES) do
		local cityID=tonumber(Game.GetProperty("LOTM_RESCUE_"..zone.."_CITY_ID") or -1);
		local city=player:GetCities():FindID(cityID);
		local ok,corrected=pcall(RestoreCity,city,owner,zone);
		if not ok then
			Game.SetProperty("LOTM_RESCUE_PHASE2A_MAINTENANCE_FAILURE",
				NetworkSafeFailureValue(zone..":"..tostring(corrected),"MAINTENANCE_"..zone));
			print("[LOTM_RESCUE][Phase2] guarded maintenance failure zone="..zone.." details="..tostring(corrected));
		elseif corrected then
			print("[LOTM_RESCUE][Phase2] loyalty restored zone="..zone.." city="..cityID.." source=maintenance");
		end
	end
end

local function RunAuthoritativeNetworkInitialize()
	local ok,details=pcall(Initialize);
	if not ok then
		Game.SetProperty("LOTM_RESCUE_PHASE2A_RUNTIME_FAILURE",
			NetworkSafeFailureValue(details,"RUNTIME_GUARD_ORDERED_STARTUP"));
		Fail("RUNTIME_GUARD");
		print("[LOTM_RESCUE][Phase2A] ordered startup runtime failure details="..tostring(details));
	end
end

local networkGame=GameConfiguration~=nil
	and GameConfiguration.IsAnyMultiplayer~=nil
	and GameConfiguration.IsAnyMultiplayer()==true;
local authoritativeNetworkContext=networkGame
	and LOTM_RP_MASTER_GAMEPLAY_CONTEXT==true;
if not networkGame then
	-- Preserve the independent single-player add-in and its original command,
	-- synchronized fallback, and PlayerTurnActivated maintenance registrations.
	GameEvents.LOTM_RESCUE_Command_BootstrapCity.Add(OnBootstrapCity);
	if GameEvents.PlayerTurnStarted~=nil then GameEvents.PlayerTurnStarted.Add(OnSynchronizedTurnStart); end
	if LOTM_MP_TurnSync==nil then include("LOTM_MP_TurnSync"); end
	LOTM_MP_TurnSync.Add(Maintain,"RescuePhase2");
	print("[LOTM_RESCUE][Phase2A] deferred until synchronized post-load command state="
		..tostring(Game.GetProperty(STATE_KEY) or "NONE").." version="
		..tostring(Game.GetProperty("LOTM_RESCUE_PHASE2A_VERSION") or 0));
elseif authoritativeNetworkContext then
	if LOTM_MP_TurnSync==nil
		or type(LOTM_MP_TurnSync.RunStartup)~="function"
		or type(LOTM_MP_TurnSync.RunPendingStartups)~="function"
		or type(LOTM_MP_TurnSync.IsRescueModeConfigured)~="function"
		or type(LOTM_MP_TurnSync.Add)~="function" then
		error("[LOTM_RESCUE][Phase2A] master multiplayer startup adapter unavailable");
	end
	LOTM_MP_TurnSync.RunStartup(RunAuthoritativeNetworkInitialize,"RescuePhase2A");
	LOTM_MP_TurnSync.Add(Maintain,"RescuePhase2");
	GameEvents.LOTM_RESCUE_Command_BootstrapCity.Add(OnBootstrapCity);
	print("[LOTM_RESCUE][Phase2A] ordered master network registration state="
		..tostring(Game.GetProperty(STATE_KEY) or "NONE").." version="
		..tostring(Game.GetProperty("LOTM_RESCUE_PHASE2A_VERSION") or 0));
else
	print("[LOTM_RESCUE][Phase2A] passive standalone network context; master Gameplay owns commands and turns");
end
