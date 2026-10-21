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
LOTM_StartupTrace.Mark("LOTM_WORLD_Popup","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"LOTM_WORLD_Popup","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"LOTM_WORLD_Popup","GameEvents");
local LuaEvents = LOTM_StartupTrace.Events(LuaEvents,"LOTM_WORLD_Popup","LuaEvents");
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
do
-- END RC342 STARTUP TRACE
-- Local presentation only. Purchases and dismissals are submitted to Gameplay.
local m_popupSerial :number=0;
local m_offerSerial :number=0;
local m_clearSerial :number=0;
local m_queued :boolean=false;
local m_waitingBuy :boolean=false;
local m_submittedProductionSignature :string="";
local TRANSFORMATION_PROJECT :string="PROJECT_LOTM_BE_TRANSFORMATION";

local function NumberProperty(object,key,default)
 local value=object~=nil and object:GetProperty(key) or nil;
 if value==nil then return default; end return tonumber(value) or default;
end
local function LocalPlayer()
 local id=Game.GetLocalPlayer();
 return id~=nil and id>=0 and id or -1,id~=nil and id>=0 and Players[id] or nil;
end
local function SyncProductionState()
 local playerID,player=LocalPlayer();
 if player==nil or not player:IsHuman() or not player:IsTurnActive() then return; end
 local potionProjects={}; local seen={}; local transformationActive=0;
 for _,city in player:GetCities():Members() do
  local queue=city~=nil and city:GetBuildQueue() or nil;
  local hash=queue~=nil and queue.GetCurrentProductionTypeHash~=nil
   and queue:GetCurrentProductionTypeHash() or nil;
  local project=hash~=nil and GameInfo.Projects[hash] or nil;
  local projectType=project~=nil and project.ProjectType or nil;
  if projectType==TRANSFORMATION_PROJECT then transformationActive=1; end
  if projectType~=nil and string.find(projectType,"^PROJECT_LOTM_")~=nil
   and string.find(projectType,"_POTION$" )~=nil and not seen[projectType] then
   seen[projectType]=true; table.insert(potionProjects,projectType);
  end
 end
 table.sort(potionProjects);
 local joined=table.concat(potionProjects,"|");
 local signature=joined.."#"..tostring(transformationActive);
 local authoritative=tostring(player:GetProperty("LOTM_WORLD_PRODUCTION_SYNC_SIGNATURE") or "");
 if signature==authoritative or signature==m_submittedProductionSignature then return; end
 m_submittedProductionSignature=signature;
 UI.RequestPlayerOperation(playerID,PlayerOperations.EXECUTE_SCRIPT,{
  OnStart="LOTM_WORLD_Command_ProductionSync",
  PotionProjects=joined~="" and joined or "NONE",
  TransformationActive=transformationActive
 });
 print("[LOTM_WORLD][Popup] submitted production sync player="..tostring(playerID)
  .." potions="..joined.." transformation="..tostring(transformationActive));
end
local function Close()
 if m_queued then UIManager:DequeuePopup(ContextPtr); end m_queued=false;
end
local function Submit(action)
 local id,player=LocalPlayer(); if player==nil or not player:IsTurnActive() then return; end
 UI.RequestPlayerOperation(id,PlayerOperations.EXECUTE_SCRIPT,
  {OnStart="LOTM_WORLD_Command_GoodyOffer",Action=action,Serial=m_offerSerial});
 if action=="BUY" then
  m_waitingBuy=true; Controls.BuyButton:SetDisabled(true); Controls.LeaveButton:SetDisabled(true);
 else Close(); end
end
local function ItemName(item)
 local greatWork=item~=nil and GameInfo.GreatWorks[item] or nil;
 local project=item~=nil and GameInfo.Projects[item] or nil;
 if greatWork~=nil then return Locale.Lookup(greatWork.Name); end
 if project~=nil then return Locale.Lookup(project.Name); end
 return tostring(item or "");
end
local function SetItemIcon(item)
 local x,y,sheet=IconManager:FindIconAtlas("ICON_"..tostring(item),256);
 if sheet==nil or sheet=="" then
  print("[LOTM_WORLD][Popup] ICON MISS ICON_"..tostring(item));
  Controls.ItemIcon:SetHide(true); return;
 end
 Controls.ItemIcon:SetTexture(x,y,sheet); Controls.ItemIcon:SetHide(false);
end
local function ClearPurchasedPotionQueues(playerID,player)
 local serial=NumberProperty(player,"LOTM_WORLD_GOODY_POTION_CLEAR_SERIAL",0);
 if serial<=m_clearSerial then return; end
 local projectType=player:GetProperty("LOTM_WORLD_GOODY_POTION_CLEAR_PROJECT");
 local project=projectType~=nil and GameInfo.Projects[projectType] or nil;
 m_clearSerial=serial;
 if project==nil then return; end
 for _,city in player:GetCities():Members() do
  local queue=city:GetBuildQueue(); local size=queue~=nil and queue:GetSize() or 0;
  for index=size-1,0,-1 do
   local entry=queue:GetAt(index);
   if entry~=nil and entry.Directive==CityProductionDirectives.PROJECT
    and (entry.ProjectType==project.Index or entry.ProjectType==project.Hash
     or entry.ProjectType==project.ProjectType) then
    local parameters={};
    parameters[CityOperationTypes.PARAM_INSERT_MODE]=CityOperationTypes.VALUE_REMOVE_AT;
    parameters[CityOperationTypes.PARAM_QUEUE_LOCATION]=index;
    CityManager.RequestOperation(city,CityOperationTypes.BUILD,parameters);
    print("[LOTM_WORLD][Popup] removed purchased potion queue city="..tostring(city:GetID()).." index="..tostring(index).." project="..tostring(projectType));
   end
  end
 end
end
local function Refresh()
 local playerID,player=LocalPlayer(); if player==nil then return; end
 ClearPurchasedPotionQueues(playerID,player);
 local serial=NumberProperty(player,"LOTM_WORLD_POPUP_SERIAL",0);
 local settled=NumberProperty(player,"LOTM_WORLD_GOODY_OFFER_SETTLED",0)==1;
 if settled then
  m_popupSerial=math.max(m_popupSerial,serial); m_waitingBuy=false;
  if m_queued then Close(); end
  return;
 end
 if m_waitingBuy then
  -- A publish with SETTLED still false means Gameplay rejected the command.
  -- Keep the offer visible instead of pretending that the purchase succeeded.
  m_waitingBuy=false; Controls.LeaveButton:SetDisabled(false);
  Controls.BuyButton:SetDisabled(player:GetTreasury():GetGoldBalance()
   < NumberProperty(player,"LOTM_WORLD_GOODY_OFFER_PRICE",0));
 end
 if serial<=m_popupSerial or player:GetProperty("LOTM_WORLD_POPUP_KIND")~="GOODY" then return; end
 m_popupSerial=serial;
 local item=player:GetProperty("LOTM_WORLD_POPUP_ITEM");
 local kind=player:GetProperty("LOTM_WORLD_GOODY_OFFER_TYPE");
 local price=NumberProperty(player,"LOTM_WORLD_GOODY_OFFER_PRICE",0);
 local gold=player:GetTreasury():GetGoldBalance();
 Controls.Title:SetText(Locale.Lookup("LOC_LOTM_WORLD_GATHERING_TITLE"));
 Controls.Intro:SetText(Locale.Lookup(kind=="ARTIFACT"
  and "LOC_LOTM_WORLD_GATHERING_ARTIFACT_INTRO"
  or "LOC_LOTM_WORLD_GATHERING_POTION_INTRO"));
 Controls.Item:SetText(ItemName(item));
 Controls.Question:SetText(Locale.Lookup("LOC_LOTM_WORLD_GATHERING_QUESTION"));
 Controls.Price:SetText(Locale.Lookup("LOC_LOTM_WORLD_GATHERING_PRICE",price,gold));
 SetItemIcon(item);
 Controls.BuyButton:SetDisabled(gold<price);
 m_offerSerial=NumberProperty(player,"LOTM_WORLD_GOODY_OFFER_SERIAL",0);
 if not m_queued then UIManager:QueuePopup(ContextPtr,PopupPriority.Medium); m_queued=true; end
end
local function Initialize()
 Controls.BuyButton:RegisterCallback(Mouse.eLClick,function() Submit("BUY"); end);
 Controls.LeaveButton:RegisterCallback(Mouse.eLClick,function() Submit("LEAVE"); end);
 Events.GameCoreEventPublishComplete.Add(SyncProductionState);
 Events.GameCoreEventPublishComplete.Add(Refresh);
 Events.LoadGameViewStateDone.Add(SyncProductionState);
 Events.LoadGameViewStateDone.Add(Refresh);
 Events.PlayerTurnActivated.Add(function(playerID)
  if playerID==Game.GetLocalPlayer() then m_submittedProductionSignature=""; SyncProductionState(); end
 end);
 if Events.CityProductionChanged~=nil then Events.CityProductionChanged.Add(function() m_submittedProductionSignature=""; SyncProductionState(); end); end
 ContextPtr:SetHide(true);
end
Initialize();
-- BEGIN RC342 STARTUP TRACE

end
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("LOTM_WORLD_Popup","CONTEXT END");
-- END RC342 STARTUP TRACE
