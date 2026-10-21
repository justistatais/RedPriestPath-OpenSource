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
LOTM_StartupTrace.Mark("LOTM_PP_ArtifactsScreen","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"LOTM_PP_ArtifactsScreen","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"LOTM_PP_ArtifactsScreen","GameEvents");
local LuaEvents = LOTM_StartupTrace.Events(LuaEvents,"LOTM_PP_ArtifactsScreen","LuaEvents");
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
do
-- END RC342 STARTUP TRACE
include("InstanceManager");

local COMMAND :string = "LOTM_PP_Command_Artifact";
local SLOT_PREFIX :string = "LOTM_PP_ARTIFACT_SLOT_";
local SLOT_COUNT :number = 9;
local GROUP_COUNT :number = 3;
local SLOTS_PER_GROUP :number = 3;
local m_launch :table = {};
local m_attached :boolean = false;
local m_open :boolean = false;
local m_columnsBuilt :boolean = false;
local m_equipmentGroupsIM :table = InstanceManager:new("GreatWorkSlot", "TopControl", Controls.EquipmentGroups);
local m_inventoryGroupsIM :table = InstanceManager:new("GreatWorkSlot", "TopControl", Controls.InventoryGroups);
local m_equipmentSlots :table = {};
local m_inventorySlots :table = {};
local m_equipmentTargets :table = {};
local m_inventoryTargets :table = {};
local m_viableDropTargets :table = {};
local m_controlToDestination :table = {};
local m_selectedDropTarget :table = nil;
local m_dragSource :table = nil;
local m_path :string = "PP";

local DATA :table = {
 {t="GREATWORK_LOTM_PP_GOLDEN_APPRAISAL_MIRROR",level=2,sequence=7,positive="LOC_LOTM_PP_SHOWCASE_GOLDEN_POSITIVE",negative="LOC_LOTM_PP_SHOWCASE_GOLDEN_NEGATIVE"},
 {t="GREATWORK_LOTM_PP_PERPETUAL_GEARBOX",level=2,sequence=6,positive="LOC_LOTM_PP_SHOWCASE_GEARBOX_POSITIVE",negative="LOC_LOTM_PP_SHOWCASE_GEARBOX_NEGATIVE"},
 {t="GREATWORK_LOTM_PP_ERROR_ASTROLABE",level=2,sequence=5,positive="LOC_LOTM_PP_SHOWCASE_ASTROLABE_POSITIVE",negative="LOC_LOTM_PP_SHOWCASE_ASTROLABE_NEGATIVE"},
 {t="GREATWORK_LOTM_PP_HERMES_FURNACE",level=1,sequence=4,positive="LOC_LOTM_PP_SHOWCASE_FURNACE_POSITIVE",negative="LOC_LOTM_PP_SHOWCASE_FURNACE_NEGATIVE"},
 {t="GREATWORK_LOTM_PP_MYSTERY_BLUEPRINT",level=1,sequence=3,positive="LOC_LOTM_PP_SHOWCASE_BLUEPRINT_POSITIVE",negative="LOC_LOTM_PP_SHOWCASE_BLUEPRINT_NEGATIVE"},
 {t="GREATWORK_LOTM_PP_KNOWLEDGE_CASKET",level=0,sequence=2,positive="LOC_LOTM_PP_SHOWCASE_CASKET_POSITIVE",negative="LOC_LOTM_PP_SHOWCASE_CASKET_NEGATIVE"},
 {t="GREATWORK_LOTM_PP_CIVILIZATION_STELE",level=0,sequence=1,positive="LOC_LOTM_PP_SHOWCASE_STELE_POSITIVE",negative="LOC_LOTM_PP_SHOWCASE_STELE_NEGATIVE"}
};
for _,data in ipairs(DATA) do data.path="PP"; end
local EXTRA_DATA :table = {
 {t="GREATWORK_LOTM_RP_DISASTER_EMBER",path="RP",level=2,sequence=7,effect="LOC_LOTM_ARTIFACT_SHOWCASE_RP_EMBER_EFFECT",rescueEffect="LOC_LOTM_RESCUE_ARTIFACT_RP_EMBER_EFFECT"},
 {t="GREATWORK_LOTM_RP_CONSPIRATOR_LETTER",path="RP",level=2,sequence=6,effect="LOC_LOTM_ARTIFACT_SHOWCASE_RP_LETTER_EFFECT",rescueEffect="LOC_LOTM_RESCUE_ARTIFACT_RP_LETTER_EFFECT"},
 {t="GREATWORK_LOTM_RP_BLOOD_HARVEST_SICKLE",path="RP",level=2,sequence=5,effect="LOC_LOTM_ARTIFACT_SHOWCASE_RP_SICKLE_EFFECT"},
 {t="GREATWORK_LOTM_RP_IRONBLOOD_BANNER",path="RP",level=1,sequence=4,effect="LOC_LOTM_ARTIFACT_SHOWCASE_RP_BANNER_EFFECT",rescueEffect="LOC_LOTM_RESCUE_ARTIFACT_RP_BANNER_EFFECT"},
 {t="GREATWORK_LOTM_RP_WAR_SCRIPTURE",path="RP",level=1,sequence=3,effect="LOC_LOTM_ARTIFACT_SHOWCASE_RP_SCRIPTURE_EFFECT",rescueEffect="LOC_LOTM_RESCUE_ARTIFACT_RP_SCRIPTURE_EFFECT"},
 {t="GREATWORK_LOTM_RP_DISASTER_WEATHER",path="RP",level=0,sequence=2,effect="LOC_LOTM_ARTIFACT_SHOWCASE_RP_WEATHER_EFFECT",rescueEffect="LOC_LOTM_RESCUE_ARTIFACT_RP_WEATHER_EFFECT"},
 {t="GREATWORK_LOTM_RP_CONQUEROR_CROWN",path="RP",level=0,sequence=1,effect="LOC_LOTM_ARTIFACT_SHOWCASE_RP_CROWN_EFFECT",rescueEffect="LOC_LOTM_RESCUE_ARTIFACT_RP_CROWN_EFFECT"},
 {t="GREATWORK_LOTM_BE_GOLDEN_BRIBE",path="BE",level=2,sequence=7,effect="LOC_LOTM_ARTIFACT_SHOWCASE_BE_BRIBE_EFFECT"},
 {t="GREATWORK_LOTM_BE_CORRUPTION_TAXBOOK",path="BE",level=2,sequence=6,effect="LOC_LOTM_ARTIFACT_SHOWCASE_BE_TAX_EFFECT"},
 {t="GREATWORK_LOTM_BE_CHAOS_CODEX",path="BE",level=2,sequence=5,effect="LOC_LOTM_ARTIFACT_SHOWCASE_BE_CODEX_EFFECT"},
 {t="GREATWORK_LOTM_BE_DEPRAVED_FEAST",path="BE",level=1,sequence=4,effect="LOC_LOTM_ARTIFACT_SHOWCASE_BE_FEAST_EFFECT"},
 {t="GREATWORK_LOTM_BE_FRENZY_SCEPTER",path="BE",level=1,sequence=3,effect="LOC_LOTM_ARTIFACT_SHOWCASE_BE_SCEPTER_EFFECT",rescueEffect="LOC_LOTM_RESCUE_ARTIFACT_BE_SCEPTER_EFFECT"},
 {t="GREATWORK_LOTM_BE_ENTROPY_CROWN",path="BE",level=0,sequence=2,effect="LOC_LOTM_ARTIFACT_SHOWCASE_BE_ENTROPY_EFFECT"},
 {t="GREATWORK_LOTM_BE_ORDER_CONVERTER",path="BE",level=0,sequence=1,effect="LOC_LOTM_ARTIFACT_SHOWCASE_BE_ORDER_EFFECT"}
};
for _,data in ipairs(EXTRA_DATA) do table.insert(DATA,data); end
local BY :table = {};
for _,data in ipairs(DATA) do BY[data.t]=data; end

local function Player()
 local id=Game.GetLocalPlayer();
 local player=id~=nil and id>=0 and Players[id] or nil;
 if player==nil or not player:IsHuman() or not player:IsMajor() then return -1,nil; end
 return id,player;
end

local function NumberProperty(object,key)
 local value=object:GetProperty(key); return value~=nil and tonumber(value) or nil;
end

local function SetIcon(control,iconName,size)
 local x,y,sheet=IconManager:FindIconAtlas(iconName,size);
 if sheet~=nil and sheet~="" then control:SetTexture(x,y,sheet); print("[LOTM_PP][ArtifactUI] icon hit "..tostring(iconName).." size="..tostring(size).." sheet="..tostring(sheet)); return true; end
 print("[LOTM_PP][ArtifactUI] ICON MISS "..tostring(iconName).." size="..tostring(size));
 return false;
end

local function ScanOwned(player)
 local result={};
 for artifactType in pairs(BY) do
  local mapped=NumberProperty(player,"LOTM_PP_ARTIFACT_INSTANCE_"..artifactType);
  if mapped~=nil then result[artifactType]=mapped; end
 end
 return result;
end

local function Submit(action,slot,artifactType,instanceID)
 local playerID,player=Player(); if player==nil then return; end
 UI.RequestPlayerOperation(playerID,PlayerOperations.EXECUTE_SCRIPT,{OnStart=COMMAND,Action=action,Slot=slot,ArtifactType=artifactType,Instance=instanceID});
end

local function ClearTransfer()
 for _,slot in ipairs(m_equipmentSlots) do slot.EmptySlotHighlight:SetHide(true); end
 for _,slot in ipairs(m_inventorySlots) do slot.EmptySlotHighlight:SetHide(true); end
 m_viableDropTargets={}; m_controlToDestination={}; m_selectedDropTarget=nil; m_dragSource=nil;
end

local function ConfigureGroup(group,title,subtitle)
 group.DefaultBG:SetHide(false); group.DisabledBG:SetHide(true); group.HighlightedBG:SetHide(true);
 group.BuildingName:SetText(title); group.CityName:SetText(subtitle); group.ThemingLabel:SetText("");
 group.GreatWorks:SetStackPadding(20);
end

local function BuildColumns()
 if m_columnsBuilt then return; end
 m_equipmentSlots={}; m_inventorySlots={}; m_equipmentTargets={}; m_inventoryTargets={};
 for groupIndex=1,GROUP_COUNT do
  local equipGroup=m_equipmentGroupsIM:GetInstance();
  local inventoryGroup=m_inventoryGroupsIM:GetInstance();
  ConfigureGroup(equipGroup,Locale.Lookup("LOC_LOTM_PP_ARTIFACT_EQUIPMENT_GROUP",groupIndex),Locale.Lookup("LOC_LOTM_PP_ARTIFACT_GROUP_SLOTS",(groupIndex-1)*3+1,groupIndex*3));
  ConfigureGroup(inventoryGroup,Locale.Lookup("LOC_LOTM_PP_ARTIFACT_INVENTORY_GROUP",groupIndex),Locale.Lookup("LOC_LOTM_PP_ARTIFACT_GROUP_SLOTS",(groupIndex-1)*3+1,groupIndex*3));
  for inner=1,SLOTS_PER_GROUP do
   local slotNumber=(groupIndex-1)*SLOTS_PER_GROUP+inner;
   local equipSlot={}; ContextPtr:BuildInstanceForControl("GreatWork",equipSlot,equipGroup.GreatWorks);
   local inventorySlot={}; ContextPtr:BuildInstanceForControl("GreatWork",inventorySlot,inventoryGroup.GreatWorks);
   m_equipmentSlots[slotNumber]=equipSlot; m_inventorySlots[slotNumber]=inventorySlot;
   table.insert(m_equipmentTargets,equipSlot.TopControl); table.insert(m_inventoryTargets,inventorySlot.TopControl);
  end
  equipGroup.GreatWorks:CalculateSize(); equipGroup.GreatWorks:ReprocessAnchoring();
  inventoryGroup.GreatWorks:CalculateSize(); inventoryGroup.GreatWorks:ReprocessAnchoring();
 end
 Controls.EquipmentGroups:CalculateSize(); Controls.InventoryGroups:CalculateSize();
 m_columnsBuilt=true;
end

local function AddDropTarget(slot,destination)
 table.insert(m_viableDropTargets,slot.TopControl); m_controlToDestination[slot.TopControl]=destination;
end

local function BeginTransfer(sourceKind,sourceSlot,artifactType,instanceID)
 ClearTransfer();
 m_dragSource={kind=sourceKind,slot=sourceSlot,artifactType=artifactType,instanceID=instanceID};
 for slotNumber,slot in ipairs(m_equipmentSlots) do AddDropTarget(slot,{kind="EQUIPMENT",slot=slotNumber}); end
 if sourceKind=="EQUIPMENT" then
  for position,slot in ipairs(m_inventorySlots) do AddDropTarget(slot,{kind="INVENTORY",position=position}); end
 end
 UI.PlaySound("UI_GreatWorks_Pick_Up");
end

local function HighlightDropTarget(bestTarget)
 for _,target in ipairs(m_viableDropTargets) do
  local destination=m_controlToDestination[target];
  local slot=destination.kind=="EQUIPMENT" and m_equipmentSlots[destination.slot] or m_inventorySlots[destination.position];
  slot.EmptySlotHighlight:SetHide(target~=bestTarget);
 end
end


local function OnArtifactDrag(dragStruct)
 if m_dragSource==nil then return; end
 local dragControl=dragStruct:GetControl();
 local bestTarget=dragControl:GetBestOverlappingControl(m_viableDropTargets);
 HighlightDropTarget(bestTarget); m_selectedDropTarget=bestTarget;
end

local function OnArtifactDrop()
 local source=m_dragSource; local destination=m_controlToDestination[m_selectedDropTarget];
 if source~=nil and destination~=nil then
  if destination.kind=="EQUIPMENT" then
   if source.kind=="INVENTORY" or destination.slot~=source.slot then
    Submit("EQUIP",destination.slot,source.artifactType,source.instanceID); UI.PlaySound("UI_GreatWorks_Put_Down");
   end
  elseif source.kind=="EQUIPMENT" then
   Submit("UNEQUIP",source.slot,nil,nil); UI.PlaySound("UI_GreatWorks_Put_Down");
  end
 end
 ClearTransfer();
end

local function EmptySlot(slot,tooltip)
 slot.GreatWorkIcon:SetHide(true); slot.SlotTypeIcon:SetHide(false); slot.EmptySlotHighlight:SetHide(true);
 slot.GreatWorkDraggable:SetDisabled(true); slot.EmptySlot:SetToolTipString(tooltip); slot.GreatWorkDraggable:SetToolTipString(tooltip);
 SetIcon(slot.SlotTypeIcon,"ICON_GREATWORKOBJECT_RELIC",40);
end

local function ArtifactTooltip(data,row,equippedSlot)
 local state=equippedSlot~=nil and Locale.Lookup("LOC_LOTM_PP_ARTIFACT_TOOLTIP_EQUIPPED",equippedSlot) or Locale.Lookup("LOC_LOTM_PP_ARTIFACT_TOOLTIP_INVENTORY");
 local pathKey="LOC_LOTM_ARTIFACT_TAB_"..(data.path=="PP" and "PERFECT" or data.path=="RP" and "RED_PRIEST" or "BLACK_EMPEROR");
 local sequencePrefix=data.path=="PP" and "LOTM_PP" or data.path=="RP" and "LOTM_RP" or "LOTM_BE";
 local sequenceName=Locale.Lookup("LOC_"..sequencePrefix.."_HUD_SEQUENCE_NAME_S"..tostring(data.sequence));
 local meta=Locale.Lookup("LOC_LOTM_ARTIFACT_TOOLTIP_META",data.level,Locale.Lookup(pathKey),data.sequence,sequenceName);
 local rescue=tonumber(Game.GetProperty("LOTM_RESCUE_MODE") or 0)==1;
 local effectTag=rescue and data.rescueEffect or data.effect;
 local effect=effectTag~=nil and Locale.Lookup(effectTag) or
  Locale.Lookup("LOC_LOTM_PP_ARTIFACT_SHOWCASE_POSITIVE",Locale.Lookup(data.positive)).."[NEWLINE]"..
  Locale.Lookup("LOC_LOTM_PP_ARTIFACT_SHOWCASE_NEGATIVE",Locale.Lookup(data.negative));
 return Locale.Lookup(row.Name).."[NEWLINE]"..meta.."[NEWLINE]"..effect.."[NEWLINE]"..state;
end

local function ShowArtifact(slot,data,instanceID,equippedSlot)
 local row=GameInfo.GreatWorks[data.t];
 slot.GreatWorkIcon:SetHide(false); slot.SlotTypeIcon:SetHide(true); slot.EmptySlotHighlight:SetHide(true);
 SetIcon(slot.GreatWorkIcon,"ICON_"..data.t,64);
 local tooltip=ArtifactTooltip(data,row,equippedSlot);
 slot.EmptySlot:SetToolTipString(tooltip); slot.GreatWorkDraggable:SetToolTipString(tooltip);
 slot.GreatWorkDraggable:SetDisabled(false);
end

local function FirstEmptyEquipmentSlot(player)
 for slot=1,SLOT_COUNT do if player:GetProperty(SLOT_PREFIX..slot)==nil then return slot; end end
 return 1;
end

local function Refresh()
 local _,player=Player();
 if player==nil then ContextPtr:SetHide(true); return; end
 ContextPtr:SetHide(false); if not m_open then return; end
 BuildColumns();
 local owned=ScanOwned(player); local equipped={}; local equippedCount=0;
 for slotNumber=1,SLOT_COUNT do
  local slot=m_equipmentSlots[slotNumber];
  local artifactType=player:GetProperty(SLOT_PREFIX..slotNumber); local data=BY[artifactType];
  local instanceID=NumberProperty(player,SLOT_PREFIX..slotNumber.."_INSTANCE");
  if data==nil or owned[artifactType]~=instanceID then
   EmptySlot(slot,Locale.Lookup("LOC_LOTM_PP_ARTIFACT_EMPTY_EQUIPMENT_TOOLTIP",slotNumber));
  else
   equipped[artifactType]=true; equippedCount=equippedCount+1; ShowArtifact(slot,data,instanceID,slotNumber);
   slot.GreatWorkDraggable:RegisterCallback(Drag.eDown,function() BeginTransfer("EQUIPMENT",slotNumber,artifactType,instanceID); end);
   slot.GreatWorkDraggable:RegisterCallback(Drag.eDrag,OnArtifactDrag);
   slot.GreatWorkDraggable:RegisterCallback(Drag.eDrop,OnArtifactDrop);
   slot.GreatWorkDraggable:RegisterCallback(Mouse.eRClick,function() Submit("UNEQUIP",slotNumber,nil,nil); end);
  end
 end

 local inventoryCount=0;
 for _,data in ipairs(DATA) do
  local instanceID=owned[data.t];
  if data.path==m_path and instanceID~=nil and not equipped[data.t] then
   inventoryCount=inventoryCount+1; local slot=m_inventorySlots[inventoryCount]; ShowArtifact(slot,data,instanceID,nil);
   slot.GreatWorkDraggable:RegisterCallback(Drag.eDown,function() BeginTransfer("INVENTORY",nil,data.t,instanceID); end);
   slot.GreatWorkDraggable:RegisterCallback(Drag.eDrag,OnArtifactDrag);
   slot.GreatWorkDraggable:RegisterCallback(Drag.eDrop,OnArtifactDrop);
  end
 end
 for position=inventoryCount+1,SLOT_COUNT do EmptySlot(m_inventorySlots[position],Locale.Lookup("LOC_LOTM_PP_ARTIFACT_EMPTY_INVENTORY_TOOLTIP")); end
 Controls.EquipmentCount:SetText(Locale.Lookup("LOC_LOTM_PP_ARTIFACT_EQUIPPED_COUNT",equippedCount,SLOT_COUNT));
 Controls.InventoryCount:SetText(Locale.Lookup("LOC_LOTM_PP_ARTIFACT_INVENTORY_COUNT",inventoryCount));
end

local function Toggle()
 m_open=not m_open; Controls.Screen:SetHide(not m_open); if m_open then Refresh(); else ClearTransfer(); end
end

local function ResizeLaunchBar(stack)
 stack:CalculateSize();
 local backing=ContextPtr:LookUpControl("/InGame/LaunchBar/LaunchBacking"); local tile=ContextPtr:LookUpControl("/InGame/LaunchBar/LaunchBackingTile");
 if backing~=nil then backing:SetSizeX(stack:GetSizeX()+116); end
 if tile~=nil then tile:SetSizeX(math.max(0,stack:GetSizeX()-20)); end
 LuaEvents.LaunchBar_Resize(stack:GetSizeX());
end

local function Attach()
 if m_attached then return; end
 local stack=ContextPtr:LookUpControl("/InGame/LaunchBar/ButtonStack"); if stack==nil then return; end
 ContextPtr:BuildInstanceForControl("LOTM_PP_ArtifactLaunchItem",m_launch,stack);
 m_launch.LaunchButton:RegisterCallback(Mouse.eLClick,Toggle); SetIcon(m_launch.LaunchIcon,"ICON_LOTM_ARTIFACT_LAUNCH",40);
 m_attached=true; ResizeLaunchBar(stack);
end

local function Initialize()
 ContextPtr:SetHide(false); Controls.Screen:SetHide(true); Controls.ModalScreenTitle:SetText(Locale.ToUpper(Locale.Lookup("LOC_LOTM_PP_ARTIFACTS_TITLE")));
 Controls.ModalScreenClose:RegisterCallback(Mouse.eLClick,function() m_open=false; Controls.Screen:SetHide(true); ClearTransfer(); end);
 Events.LoadGameViewStateDone.Add(Attach); Events.GameCoreEventPublishComplete.Add(Refresh);
 Events.LocalPlayerTurnBegin.Add(Refresh); Attach();
 Controls.PathPerfect:RegisterCallback(Mouse.eLClick,function() m_path="PP"; Refresh(); end);
 Controls.PathRedPriest:RegisterCallback(Mouse.eLClick,function() m_path="RP"; Refresh(); end);
 Controls.PathBlackEmperor:RegisterCallback(Mouse.eLClick,function() m_path="BE"; Refresh(); end);
 LuaEvents.LOTM_PP_OpenArtifacts.Add(function() m_open=true; Controls.Screen:SetHide(false); Refresh(); end);
end

Initialize();
-- BEGIN RC342 STARTUP TRACE

end
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("LOTM_PP_ArtifactsScreen","CONTEXT END");
-- END RC342 STARTUP TRACE
