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
local BRIBE_FIXED_283_EFFECTS_ATTACHED :string = "LOTM_PP_ARTIFACT_BRIBE_FIXED_283_ATTACHED";
local INSTANCE_PREFIX :string = "LOTM_PP_ARTIFACT_INSTANCE_";
local EXPECTED_TYPE :string = "LOTM_PP_ARTIFACT_EXPECTED_CREATED_TYPE";
local EXPECTED_TURN :string = "LOTM_PP_ARTIFACT_EXPECTED_CREATED_TURN";
local LETTER_TYPE :string = "GREATWORK_LOTM_RP_CONSPIRATOR_LETTER";
local LETTER_PEACE_RESOURCE :string = "RESOURCE_LOTM_RP_LETTER_PEACE_ACTIVE";
local LETTER_WAR_ACTIVE :string = "LOTM_RP_ART_LETTER_WAR_GOLD_ACTIVE";
local LETTER_PEACE_ACTIVE :string = "LOTM_RP_ART_LETTER_PEACE_PENALTY_ACTIVE";
local BRIBE_TYPE :string = "GREATWORK_LOTM_BE_GOLDEN_BRIBE";
local BRIBE_FIXED_NEG_RESOURCE :string = "RESOURCE_LOTM_BE_BRIBE_FIXED_NEG_283";
local pendingNetworkHermesUnits :table = {};
local pendingNetworkHermesKeys :table = {};
local pendingNetworkGreatWorks :table = {};
local pendingNetworkGreatWorkKeys :table = {};

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
local BRIBE_FIXED_283_MODIFIERS :table = {
 "LOTM_BE_ART_BRIBE_DOMESTIC_FOOD_FIXED_283",
 "LOTM_BE_ART_BRIBE_DOMESTIC_PRODUCTION_FIXED_283"
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
 if (p:GetProperty(BRIBE_FIXED_283_EFFECTS_ATTACHED) or 0)~=1 then
  -- The fixed contract uses its own synchronized resource gate.  It does not
  -- reactivate the retired -100/restore chain serialized by earlier builds.
  for _,id in ipairs(BRIBE_FIXED_283_MODIFIERS) do
   pcall(function() p:AttachModifierByID(id); end);
  end
  p:SetProperty(BRIBE_FIXED_283_EFFECTS_ATTACHED,1);
 end
 end
end
local function SetNamedResourceSwitch(p,resourceType,on,forceRefresh,label)
 local info=resourceType and GameInfo.Resources[resourceType] or nil;
 if info==nil then return; end
 local resources=p:GetResources(); local current=resources:GetResourceAmount(info.Index) or 0;
 local wanted=on and 1 or 0;
 local changed=current~=wanted;
 if changed and resources.ChangeResourceAmount~=nil then
  resources:ChangeResourceAmount(info.Index,wanted-current);
 elseif forceRefresh and resources.ChangeResourceAmount~=nil then
  local pulse=wanted==0 and 1 or -1; resources:ChangeResourceAmount(info.Index,pulse); resources:ChangeResourceAmount(info.Index,-pulse);
 end
 if changed or forceRefresh then Log(label.." player="..tostring(p:GetID()).." resource="..tostring(resourceType).." wanted="..tostring(wanted).." actual="..tostring(resources:GetResourceAmount(info.Index) or 0).." forced="..tostring(forceRefresh==true)); end
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
    if artifactType==BRIBE_TYPE then
     SetNamedResourceSwitch(p,BRIBE_FIXED_NEG_RESOURCE,false,false,"rescue retired ordinary Bribe fixed lease");
    end
   else
    local positive,negative=ArtifactPolarity(p,artifactType,on);
    SetNamedResourceSwitch(p,lease76.."_POS",positive,forceRefresh,"positive lease81");
    if artifactType==BRIBE_TYPE then
     -- Retire every legacy Golden Bribe negative modifier and drive only the
     -- independent fixed -3/-3 contract from synchronized Gameplay state.
     SetNamedResourceSwitch(p,lease76.."_NEG",false,false,"retired Bribe negative lease81");
     SetNamedResourceSwitch(p,BRIBE_FIXED_NEG_RESOURCE,negative,forceRefresh,"Bribe fixed negative lease283");
    else
     SetNamedResourceSwitch(p,lease76.."_NEG",negative,forceRefresh,"negative lease81");
    end
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
 if LOTM_MP_TurnSync.IsNetworkGame() and atWar
  and positiveEquipped.GREATWORK_LOTM_RP_CONSPIRATOR_LETTER
  and not RescueActive()
  and (p:GetProperty("LOTM_RP_ART_LETTER_FIRST_WAR_PAID") or 0)~=1 then
  p:SetProperty("LOTM_RP_ART_LETTER_FIRST_WAR_PAID",1);
  p:GetTreasury():ChangeGoldBalance(1000);
  Log("conspirator first-war gold player="..tostring(playerID).." source=SYNC_TURN");
 end
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
local function ValidateRescueEquipmentOwnership(playerID)
 local p=Human(playerID); if p==nil then return false; end
 local changed=false;
 for slot=1,9 do
  local t=p:GetProperty(SLOT_PREFIX..slot); local instance=NumberProperty(p,SLOT_PREFIX..slot.."_INSTANCE");
  if t~=nil and not IsOwned(playerID,t,instance) then
   Log("auto-unequip player="..playerID.." slot="..slot.." type="..t);
   p:SetProperty(SLOT_PREFIX..slot,nil); p:SetProperty(SLOT_PREFIX..slot.."_INSTANCE",nil); changed=true;
  end
 end
 if changed then p:SetProperty("LOTM_PP_ARTIFACT_EQUIPMENT_REV",(p:GetProperty("LOTM_PP_ARTIFACT_EQUIPMENT_REV") or 0)+1); end
 return changed;
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
function LOTM_PP_GrantWorkshopReward(playerID,level,path,stableEventKey)
 local p=Human(playerID); if p==nil then return false,"AI_OR_INVALID"; end
 path=path or "PP";
 local pool={}; for _,t in ipairs(ARTIFACT_ORDER) do local row=ARTIFACTS[t]; local owner=GlobalGet(GLOBAL_OWNER_PREFIX..t); if row.level==level and row.path==path and (owner==nil or tonumber(owner)<0) and not HasKnownType(p,t) then table.insert(pool,t); end end
 table.sort(pool); if #pool==0 then p:SetProperty("LOTM_PP_LAST_REWARD","COMPLETE_LEVEL_"..level); return false,"COMPLETE"; end
 local stableLabel="LOTM PP workshop artifact:player="..tostring(playerID)
  ..":level="..tostring(level)..":path="..tostring(path)
  ..":event="..tostring(stableEventKey or Game.GetCurrentGameTurn());
 local chosen=pool[LOTM_MP_TurnSync.Random(#pool,stableLabel,"LOTM PP workshop artifact")+1];
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
local function ApplyCreated(playerID,instance,artifactType,expectedTurn)
 local p=Human(playerID); if p==nil then return; end
 local t=artifactType or p:GetProperty(EXPECTED_TYPE); local liveExpectedTurn=NumberProperty(p,EXPECTED_TURN);
 if ARTIFACTS[t]==nil or expectedTurn==nil or liveExpectedTurn~=expectedTurn
  or p:GetProperty(EXPECTED_TYPE)~=t then return; end
 if BindInstance(playerID,t,instance,"GreatWorkCreated") then
  p:SetProperty(EXPECTED_TYPE,nil); p:SetProperty(EXPECTED_TURN,nil);
 end
end
local function OnCreated(playerID,creatorID,x,y,buildingID,instance)
 local p=Human(playerID); if p==nil then return; end
 local t=p:GetProperty(EXPECTED_TYPE); local expectedTurn=NumberProperty(p,EXPECTED_TURN);
 if ARTIFACTS[t]==nil or expectedTurn==nil or expectedTurn~=Game.GetCurrentGameTurn() then return; end
 if not LOTM_MP_TurnSync.IsNetworkGame() then ApplyCreated(playerID,instance,t,expectedTurn); return; end
 local normalizedPlayerID=tonumber(playerID); local normalizedInstance=tonumber(instance);
 if normalizedPlayerID==nil or normalizedInstance==nil then return; end
 local key=table.concat({expectedTurn,normalizedPlayerID,normalizedInstance,t},":");
 if pendingNetworkGreatWorkKeys[key]~=nil then return; end
 local entry={QueuedTurn=Game.GetCurrentGameTurn(),ExpectedTurn=expectedTurn,PlayerID=normalizedPlayerID,
  Instance=normalizedInstance,ArtifactType=t,Key=key};
 pendingNetworkGreatWorks[#pendingNetworkGreatWorks+1]=entry; pendingNetworkGreatWorkKeys[key]=entry;
end
local function TriggerRandomKnowledgeCasketEureka(playerID,p,turn)
 local techs=p~=nil and p:GetTechs() or nil; if techs==nil then return false; end
 local choices={};
 for tech in GameInfo.Technologies() do
  if not techs:HasTech(tech.Index) and not techs:HasBoostBeenTriggered(tech.Index) then choices[#choices+1]=tech.Index; end
 end
 table.sort(choices);
 if #choices==0 then Log("knowledge casket no eligible Eureka player="..playerID.." turn="..turn); return true; end
 local stableLabel="LOTM PP knowledge casket:player="..tostring(playerID)
  ..":turn="..tostring(turn)..":choices="..tostring(#choices);
 local selected=choices[LOTM_MP_TurnSync.Random(#choices,stableLabel,"LOTM PP knowledge casket")+1];
 local ok,result=pcall(function() return techs:TriggerBoost(selected,1); end);
 if not ok then Log("WARNING knowledge casket TriggerBoost failed player="..playerID.." turn="..turn.." tech="..selected.." error="..tostring(result)); return false; end
 Log("knowledge casket Eureka player="..playerID.." turn="..turn.." tech="..selected.." result="..tostring(result));
 return true;
end
local function ApplyHermesBuilder(playerID,unitID)
 local p=Human(playerID); if p==nil then return; end
 local unit=UnitManager.GetUnit(playerID,unitID);
 if unit==nil or unit:GetType()~=GameInfo.Units.UNIT_BUILDER.Index
  or (unit:GetProperty("LOTM_PP_HERMES_BONUS") or 0)==1
  or not LOTM_PP_ArtifactPositiveActive(playerID,"GREATWORK_LOTM_PP_HERMES_FURNACE") then return; end
 local ability=unit:GetAbility(); if ability==nil then return; end
 local current=ability:GetAbilityCount("ABILITY_LOTM_PP_HERMES_BUILDER") or 0;
 if current==0 then ability:ChangeAbilityCount("ABILITY_LOTM_PP_HERMES_BUILDER",1); end
 unit:SetProperty("LOTM_PP_HERMES_BONUS",1);
end
local function QueueNetworkHermesUnit(playerID,unitID)
 local normalizedPlayerID=tonumber(playerID); local normalizedUnitID=tonumber(unitID);
 if normalizedPlayerID==nil or normalizedUnitID==nil then return; end
 local key=tostring(normalizedPlayerID)..":"..tostring(normalizedUnitID);
 if pendingNetworkHermesKeys[key]~=nil then return; end
 local entry={PlayerID=normalizedPlayerID,UnitID=normalizedUnitID,
  QueuedTurn=Game.GetCurrentGameTurn(),Key=key};
 pendingNetworkHermesUnits[#pendingNetworkHermesUnits+1]=entry;
 pendingNetworkHermesKeys[key]=entry;
end
local function ProcessNetworkHermesUnits(playerID)
 if not LOTM_MP_TurnSync.IsNetworkGame()
  or not LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID) then return; end
 local currentTurn=Game.GetCurrentGameTurn(); local ready={}; local waiting={};
 for _,entry in ipairs(pendingNetworkHermesUnits) do
  if entry.QueuedTurn<currentTurn then ready[#ready+1]=entry; else waiting[#waiting+1]=entry; end
 end
 pendingNetworkHermesUnits=waiting;
 table.sort(ready,function(a,b)
  if a.PlayerID~=b.PlayerID then return a.PlayerID<b.PlayerID; end
  return a.UnitID<b.UnitID;
 end);
 for _,entry in ipairs(ready) do
  if pendingNetworkHermesKeys[entry.Key]==entry then pendingNetworkHermesKeys[entry.Key]=nil; end
  ApplyHermesBuilder(entry.PlayerID,entry.UnitID);
 end
end
local function ProcessNetworkGreatWorks(playerID)
 if not LOTM_MP_TurnSync.IsNetworkGame()
  or not LOTM_MP_TurnSync.IsStableAnchorPlayer(playerID) then return; end
 local currentTurn=Game.GetCurrentGameTurn(); local ready={}; local waiting={};
 for _,entry in ipairs(pendingNetworkGreatWorks) do
  if entry.QueuedTurn<currentTurn then ready[#ready+1]=entry; else waiting[#waiting+1]=entry; end
 end
 pendingNetworkGreatWorks=waiting;
 table.sort(ready,function(a,b)
  if a.QueuedTurn~=b.QueuedTurn then return a.QueuedTurn<b.QueuedTurn; end
  if a.PlayerID~=b.PlayerID then return a.PlayerID<b.PlayerID; end
  if a.ArtifactType~=b.ArtifactType then return a.ArtifactType<b.ArtifactType; end
  return a.Instance<b.Instance;
 end);
 for _,entry in ipairs(ready) do
  if pendingNetworkGreatWorkKeys[entry.Key]==entry then pendingNetworkGreatWorkKeys[entry.Key]=nil; end
  ApplyCreated(entry.PlayerID,entry.Instance,entry.ArtifactType,entry.ExpectedTurn);
 end
end
local function ProcessTurn(playerID,isFirstTimeThisTurn)
 if isFirstTimeThisTurn==false then return; end
 ProcessNetworkGreatWorks(playerID);
 ProcessNetworkHermesUnits(playerID);
 local p=Human(playerID); if p==nil then return; end EnsureInfrastructure(playerID); RecoverLegacyLedger(playerID);
 GrantAllArtifactsForRescueNewGame(playerID);
 local turn=Game.GetCurrentGameTurn();
 if NumberProperty(p,TURN_SETTLED)==turn then return; end
 -- Persist the deterministic guard before applying any one-shot turn effects.
 -- Re-activation after save/load or a multiplayer reconnect cannot settle twice.
 p:SetProperty(TURN_SETTLED,turn);
 for _,t in ipairs(ARTIFACT_ORDER) do if (p:GetProperty("LOTM_PP_PENDING_"..t) or 0)==1 and not HasKnownType(p,t) then Grant(playerID,t); end end
 if RescueActive() then
  -- Rescue artifacts use the separated Rescue lease namespace. Re-pulsing all
  -- retired ordinary resources each turn produced dozens of redundant engine
  -- updates and log lines. Validate the nine slots every turn, but run the full
  -- ordinary-switch retirement only once or after an explicit equipment change.
  local pending=(p:GetProperty("LOTM_PP_ARTIFACT_EFFECT_REFRESH_PENDING") or 0)==1;
  local ownershipChanged=ValidateRescueEquipmentOwnership(playerID);
  if pending or ownershipChanged or (p:GetProperty("LOTM_PP_RESCUE_SWITCH_CLEANUP_VERSION") or 0)<1 then
   Reconcile(playerID,false); p:SetProperty("LOTM_PP_RESCUE_SWITCH_CLEANUP_VERSION",1);
  end
 else
  -- Ordinary mode keeps its fresh one-turn lease pulse semantics.
  Reconcile(playerID,true);
 end
 p:SetProperty("LOTM_PP_ARTIFACT_EFFECT_REFRESH_PENDING",nil); CleanupLegacyLatchedEffects(playerID);
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
 if LOTM_MP_TurnSync.IsNetworkGame() then return; end
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
 if LOTM_MP_TurnSync.IsNetworkGame() then return; end
 Reconcile(firstPlayerID,true); Reconcile(secondPlayerID,true);
end
local function OnUnitAdded(playerID,unitID)
 if LOTM_MP_TurnSync.IsNetworkGame() then QueueNetworkHermesUnit(playerID,unitID); return; end
 ApplyHermesBuilder(playerID,unitID);
end
local function Initialize()
 GameEvents.LOTM_PP_Command_Artifact.Add(OnCommand); Events.GreatWorkCreated.Add(OnCreated);
 -- GreatWorkMoved is a UI event in the shipped Gathering Storm runtime and is
 -- not available in synchronized Gameplay. Ownership is rechecked on every
 -- player turn, including immediately after a completed diplomatic deal.
 LOTM_MP_TurnSync.Add(ProcessTurn,"Artifacts"); Events.UnitAddedToMap.Add(LOTM_UnitAddedPerf.Wrap("Artifacts",OnUnitAdded));
 GameEvents.OnCombatOccurred.Add(OnCombatOccurred); Events.DiplomacyDeclareWar.Add(OnDiplomacyDeclareWar); Events.DiplomacyMakePeace.Add(OnDiplomacyMakePeace);
 LOTM_MP_TurnSync.RunStartup(function()
  local ids=PlayerManager.GetAliveMajorIDs();
  if LOTM_MP_TurnSync.IsNetworkGame() then
   local ordered={}; for _,id in ipairs(ids or {}) do ordered[#ordered+1]=id; end
   table.sort(ordered); ids=ordered;
  end
  for _,id in ipairs(ids or {}) do EnsureInfrastructure(id); RecoverLegacyLedger(id); RefreshOwnership(id); end
 end,"Artifacts");
 Log("initialized");
end
Initialize();
