-- BEGIN RC342 STARTUP TRACE
-- Optional startup diagnostics, resource 435. Embedded by generate_startup_trace.py so a
-- missing VFS import cannot hide the first startup checkpoint.
-- Keep disabled in releases: high-frequency UI tracing caused severe stutter.
-- To diagnose a new failure, enable and rerun both startup/bundle generators.
if LOTM_StartupTrace == nil then
	LOTM_StartupTrace = { Enabled=false, Resource=435 };
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
		print("[LOTM_DIAG] r=435 seq=" .. sequence .. " ctx=" .. context
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
LOTM_StartupTrace.Mark("LOTM_RESCUE_GovernorDetailsPanel","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"LOTM_RESCUE_GovernorDetailsPanel","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"LOTM_RESCUE_GovernorDetailsPanel","GameEvents");
local LuaEvents = LOTM_StartupTrace.Events(LuaEvents,"LOTM_RESCUE_GovernorDetailsPanel","LuaEvents");
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
do
-- END RC342 STARTUP TRACE
-- Copyright 2020, Firaxis Games

-- ===========================================================================
--	UI for managing and appointing Governors	
-- ===========================================================================

include("InstanceManager");
include("TabSupport");
include("SupportFunctions");
include("Civ6Common");
include("ModalScreen_PlayerYieldsHelper");
include("GovernorSupport");

-- ===========================================================================
--	CONSTANTS
-- ===========================================================================

local RELOAD_CACHE_ID:string = "GovernorDetailsPanel"; -- Must be unique (usually the same as the file name)

local PROMOTION_X_OFFSET = 110;
local PROMOTION_Y_OFFSET = 147;
local PROMOTION_LINE_Y_OFFSET = 77;
local EXTRA_MIDDLE_PROMOTION_LINE_X_OFFSET = 20;
local PROMOTION_NAME_TRUNCATE_WIDTH = 195;

-- ===========================================================================
--	VARIABLES
-- ===========================================================================

local m_PromotionTreeIM:table = InstanceManager:new("PromotionTreeInstance", "TopGrid", Controls.PromotionAnchor);
local m_SecretPromotionTreeIM:table = InstanceManager:new("SecretSocietyPromotionTreeInstance", "TopGrid", Controls.PromotionAnchor);

local m_PromotionIM:table = InstanceManager:new("PromotionInstance", "PromotionButton");
local m_SecretPromotionIM:table = InstanceManager:new("SecretSocietyPromotionInstance", "PromotionButton");

local m_ReqLinesLeftIM:table = InstanceManager:new("ReqLinesLeft", "Top");
local m_ReqLinesRightIM:table = InstanceManager:new("ReqLinesRight", "Top");
local m_ReqLinesDownIM:table = InstanceManager:new("ReqLinesDown", "Top");

local m_GovernorIndex:number = -1;

local m_SelectedPromotion:number = -1;

local m_TopPanelConsideredHeight:number = 0;

local m_isReadOnly : boolean = false;
-- ===========================================================================
function Refresh()
	local localPlayerID:number = Game.GetLocalPlayer();
	if m_GovernorIndex == -1 or localPlayerID == PlayerTypes.NONE or localPlayerID == PlayerTypes.OBSERVER then
		return;
	end

	local pGovernorDef:table = GameInfo.Governors[m_GovernorIndex];	
	local pGovernor:table = GetAppointedGovernor(localPlayerID, m_GovernorIndex);
	local pLocalPlayer:table = Players[localPlayerID];
	local pPlayerGovernors:table = pLocalPlayer:GetGovernors();
	local bIsSecretGovernor:boolean = IsCannotAssign(pGovernorDef);

	-- Update governor name and title
	Controls.GovernorNameLabel:SetText(Locale.ToUpper(pGovernorDef.Name));
	Controls.GovernorTitleLabel:SetText(Locale.Lookup(pGovernorDef.Title));
	Controls.GovernorBioLabel:SetText(Locale.Lookup(pGovernorDef.Description));

	-- Show/hide elements based on if this is a secret, non-assignable governor
	if not bIsSecretGovernor then
		Controls.GovernorNamePlaque:SetTexture("Governors_NamePlaque");

		-- Update governor transition strength and identity pressure
		Controls.TransitionStrengthLabel:SetText(pPlayerGovernors:GetTurnsToEstablish(pGovernorDef.Hash));
		Controls.IdentityPressureLabel:SetText(pGovernorDef.IdentityPressure);
		Controls.GovernorStatsContainer:SetHide(false);

		SetGovernorStatus(pGovernorDef, pGovernor);
		Controls.GovernorStatusContainer:SetHide(false);

		Controls.SecretSocietyIcon:SetHide(true);

		-- Update assign button
		if pGovernor then
			local pAssignedCity:table = pGovernor:GetAssignedCity();
			if pAssignedCity then
				Controls.AssignButtonLabel:SetText(Locale.Lookup("LOC_GOVERNORS_SCREEN_BUTTON_REASSIGN_GOVERNOR"));
			else
				Controls.AssignButtonLabel:SetText(Locale.Lookup("LOC_GOVERNORS_SCREEN_BUTTON_ASSIGN_GOVERNOR"));
			end
			Controls.AssignButton:SetVoid1(pGovernorDef.Index);
			Controls.AssignButton:RegisterCallback( Mouse.eLClick, OnAssignGovernor );
			local bCanAssign:boolean = pPlayerGovernors:HasGovernor(pGovernorDef.Hash) and pGovernor:GetNeutralizedTurns() == 0;
			Controls.AssignButton:SetDisabled((not bCanAssign) or m_isReadOnly);
		else
			Controls.AssignButtonLabel:SetText(Locale.Lookup("LOC_GOVERNORS_SCREEN_BUTTON_APPOINT_GOVERNOR"));
			Controls.AssignButton:SetVoid1(pGovernorDef.Index);
			Controls.AssignButton:RegisterCallback( Mouse.eLClick, OnAppointGovernor );
			local bCanAppoint:boolean = pPlayerGovernors:CanAppoint();
			Controls.AssignButton:SetDisabled((not bCanAppoint) or m_isReadOnly);
		end

		Controls.AssignButton:SetHide(false);
		
		Controls.MainContainer:SetTexture("Governors_BackgroundTile_ColumnOff");
	else
		Controls.GovernorNamePlaque:SetTexture("Secret_NamePlaque");

		-- The first, and only, element in SecretSocietyCollection should be the
		-- associated secret society. Safetly looping through it here just as precaution
		local kSecretSocietyDef:table = nil;
		for i, societyDef in ipairs(pGovernorDef.SecretSocietyCollection) do
			if societyDef ~= nil then
				kSecretSocietyDef = societyDef;
				break;
			end
		end

		if kSecretSocietyDef then
			Controls.SecretSocietyIcon:SetTexture(kSecretSocietyDef.SmallIcon);
		end

		Controls.SecretSocietyIcon:SetHide(false);

		Controls.GovernorStatsContainer:SetHide(true);
		Controls.GovernorStatusContainer:SetHide(true);
		Controls.AssignButton:SetHide(true);

		Controls.MainContainer:SetTexture("Secret_Column_BackgroundTile");
	end

	-- Update governor portrait
	Controls.GovernorPortrait:SetTexture(pGovernorDef.PortraitImageSelected);

	m_PromotionTreeIM:ResetInstances();
	m_SecretPromotionTreeIM:ResetInstances();

	if not bIsSecretGovernor then
		CreatePromotionTree(localPlayerID, pGovernor, pGovernorDef, pPlayerGovernors);
	else
		CreateSecretPromotionTree(localPlayerID, pGovernor, pGovernorDef, pPlayerGovernors);
	end

	if m_SelectedPromotion ~= -1 then
		Controls.ConfirmButton:SetHide(false);
		Controls.BackButton:SetHide(true);		
	else
		Controls.ConfirmButton:SetHide(true);
		Controls.BackButton:SetHide(false);
	end
end

-- ===========================================================================
-- BEGIN LOTM RESCUE STAR AND PREREQUISITES
local function LOTM_StarBranchesOwned(governor,promotion)
 if promotion==nil or promotion.GovernorPromotionType~="GOVERNOR_PROMOTION_LOTM_STAR_HIDDEN_WORLD" then return true; end
 local a=GameInfo.GovernorPromotions["GOVERNOR_PROMOTION_LOTM_STAR_CASE_FILES"];
 local b=GameInfo.GovernorPromotions["GOVERNOR_PROMOTION_LOTM_STAR_RED_GLOVES"];
 return governor~=nil and a~=nil and b~=nil and governor:HasPromotion(a.Hash) and governor:HasPromotion(b.Hash);
end
-- END LOTM RESCUE STAR AND PREREQUISITES

function CreatePromotionTree(localPlayerID:number, pGovernor:table, pGovernorDef:table, pPlayerGovernors:table)
	
	local pPromotionTreeInst:table = m_PromotionTreeIM:GetInstance();

	-- Define promotion tree matrix used to determine promotion requirement lines
	local promotionTreeMatrix:table = {{}, {}, {}};

	-- Create the promotion button instances and fill the promotion matrix
	m_PromotionIM:ResetInstances();
	for promotionSet in GameInfo.GovernorPromotionSets() do
		if promotionSet.GovernorType == pGovernorDef.GovernorType then
			local kPromotion:table = GameInfo.GovernorPromotions[promotionSet.GovernorPromotion];
			
			local sName:string = Locale.ToUpper(kPromotion.Name);
			local sDescription:string = Locale.Lookup(kPromotion.Description);
			if (IsPromotionHidden(kPromotion.Hash, localPlayerID, pGovernorDef.Index)) then
				sName = GetPromotionHiddenName(kPromotion.Hash);
				sDescription = GetPromotionHiddenDescription(kPromotion.Hash);
			end
			
			if kPromotion.BaseAbility then
				local iconName:string = "ICON_" .. pGovernorDef.GovernorType .. "_PROMOTION";
				pPromotionTreeInst.BaseAbilityIcon:SetIcon(iconName);
				pPromotionTreeInst.BaseAbilityLabel:SetText(sDescription);
			else
				if kPromotion.Level ~= 0 then
					local pPromotionInst:table = m_PromotionIM:GetInstance(pPromotionTreeInst.PromotionContainer);
					TruncateStringWithTooltip(pPromotionInst.PromotionName, PROMOTION_NAME_TRUNCATE_WIDTH, sName);
					pPromotionInst.PromotionDesc:SetText(sDescription);

					local xOffset:number = PROMOTION_X_OFFSET * (kPromotion.Column);
					-- Subtract 1 from level to discount the BaseAbility which is the only level 0 promotion
					local yOffset:number = PROMOTION_Y_OFFSET * (kPromotion.Level - 1);
					pPromotionInst.PromotionButton:SetOffsetVal(xOffset, yOffset);

					-- Determine if this promotion can currently be earn by this governor due to requirements, etc
					local canEarnPromotion:boolean = pPlayerGovernors:CanEarnPromotion(pGovernorDef.Hash, kPromotion.Hash);
					canEarnPromotion = canEarnPromotion and LOTM_StarBranchesOwned(pGovernor,kPromotion);

					-- Update button state and callback depending on the promotion state
					if (pGovernor and pGovernor:HasPromotion(kPromotion.Hash)) then
						pPromotionInst.PromotionButton:SetDisabled(true);
						pPromotionInst.PromotionButton:SetVisState(4);
						pPromotionInst.PromotionButton:ClearCallback( Mouse.eLClick );
					elseif m_SelectedPromotion == kPromotion.Index then
						pPromotionInst.PromotionButton:SetDisabled(false);
						pPromotionInst.PromotionButton:SetSelected(true);
						pPromotionInst.PromotionButton:SetVisState(5);
						pPromotionInst.PromotionButton:SetVoid1(m_GovernorIndex);
						pPromotionInst.PromotionButton:SetVoid2(kPromotion.Index);
						pPromotionInst.PromotionButton:RegisterCallback( Mouse.eLClick, OnPromoteGovernor );
					elseif not canEarnPromotion then
						pPromotionInst.PromotionButton:SetDisabled(true);
						pPromotionInst.PromotionButton:SetSelected(false);
						pPromotionInst.PromotionButton:SetVisState(3);
						pPromotionInst.PromotionButton:ClearCallback( Mouse.eLClick );
					else
						pPromotionInst.PromotionButton:SetDisabled(m_isReadOnly);
						pPromotionInst.PromotionButton:SetSelected(false);
						pPromotionInst.PromotionButton:SetVisState(0);
						pPromotionInst.PromotionButton:SetVoid1(m_GovernorIndex);
						pPromotionInst.PromotionButton:SetVoid2(kPromotion.Index);
						pPromotionInst.PromotionButton:RegisterCallback( Mouse.eLClick, OnPromoteGovernor );
					end

					-- Insert this promotion into the matrix
					local matrixX:number = kPromotion.Column + 1;
					local matrixY:number = kPromotion.Level;
					if matrixX >= 1 and matrixX <= 3 and matrixY >= 1 and matrixY <= 3 then
						promotionTreeMatrix[matrixX][matrixY] = kPromotion;
					end
				end
			end
		end
	end

	m_ReqLinesLeftIM:ResetInstances();
	m_ReqLinesRightIM:ResetInstances();
	m_ReqLinesDownIM:ResetInstances();

	-- Loop through the matrix to determine where we have to display requirement lines
	for x=1,3,1 do
		for y=1,2,1 do
			local kPromotion:table = promotionTreeMatrix[x][y];
			if kPromotion then
				
				local xOffset:number = PROMOTION_X_OFFSET * (x - 1);
				local yOffset:number = (PROMOTION_Y_OFFSET * (y - 1)) + PROMOTION_LINE_Y_OFFSET;

				-- Check if we unlock the promotion below us
				local kPromotionBelow = promotionTreeMatrix[x][y+1]
				if kPromotionBelow then
					local pLineInst:table = m_ReqLinesDownIM:GetInstance(pPromotionTreeInst.PromotionLinesContainer);
					pLineInst.Top:SetOffsetVal(xOffset, yOffset);
				end

				-- Check if we unlock the promotion to the right of us
				if x < 3 then
					local kPromotionToRight:table = promotionTreeMatrix[x+1][y+1];
					if kPromotionToRight then
						local pLineInst:table = m_ReqLinesRightIM:GetInstance(pPromotionTreeInst.PromotionLinesContainer);
						local adjustedXOffset:number = x ~= 2 and xOffset or xOffset + EXTRA_MIDDLE_PROMOTION_LINE_X_OFFSET;
						pLineInst.Top:SetOffsetVal(adjustedXOffset, yOffset);
					end
				end

				-- Check if we unlock the promotion to the left of us
				if x > 1 then
					local kPromotionToLeft:table = promotionTreeMatrix[x-1][y+1];
					if kPromotionToLeft then
						local pLineInst:table = m_ReqLinesLeftIM:GetInstance(pPromotionTreeInst.PromotionLinesContainer);
						local adjustedXOffset:number = x ~= 2 and xOffset or xOffset - EXTRA_MIDDLE_PROMOTION_LINE_X_OFFSET;
						pLineInst.Top:SetOffsetVal(adjustedXOffset, yOffset);
					end
				end
			end
		end
	end
end

-- ===========================================================================
function CreateSecretPromotionTree(localPlayerID:number, pGovernor:table, pGovernorDef:table, pPlayerGovernors:table)
	
	local pSecretPromotionTreeInst:table = m_SecretPromotionTreeIM:GetInstance();

	m_SecretPromotionIM:ResetInstances();
	for promotionSet in GameInfo.GovernorPromotionSets() do
		if promotionSet.GovernorType == pGovernorDef.GovernorType then
			local kPromotion:table = GameInfo.GovernorPromotions[promotionSet.GovernorPromotion];
			
			local sName:string = Locale.ToUpper(kPromotion.Name);
			local sDescription:string = Locale.Lookup(kPromotion.Description);
			local isHidden:boolean = IsPromotionHidden(kPromotion.Hash, localPlayerID, pGovernorDef.Index);
			if isHidden then
				sName = GetPromotionHiddenName(kPromotion.Hash);
				sDescription = GetPromotionHiddenDescription(kPromotion.Hash);
			end
			
			local promotionInst:table = m_SecretPromotionIM:GetInstance(pSecretPromotionTreeInst.PromotionContainer);
			TruncateStringWithTooltip(promotionInst.PromotionName, PROMOTION_NAME_TRUNCATE_WIDTH, sName);
			promotionInst.PromotionDesc:SetText(sDescription);

			-- Determine if this promotion can currently be earn by this governor due to requirements, etc
			local canEarnPromotion:boolean = pPlayerGovernors:CanEarnPromotion(pGovernorDef.Hash, kPromotion.Hash);
					canEarnPromotion = canEarnPromotion and LOTM_StarBranchesOwned(pGovernor,kPromotion);

			-- Update button state and callback depending on the promotion state
			if (pGovernor and pGovernor:HasPromotion(kPromotion.Hash)) then
				promotionInst.PromotionButton:SetDisabled(true);
				promotionInst.PromotionButton:SetVisState(4);
				promotionInst.PromotionButton:ClearCallback( Mouse.eLClick );
			elseif m_SelectedPromotion == kPromotion.Index then
				promotionInst.PromotionButton:SetDisabled(false);
				promotionInst.PromotionButton:SetSelected(true);
				promotionInst.PromotionButton:SetVisState(5);
				promotionInst.PromotionButton:SetVoid1(m_GovernorIndex);
				promotionInst.PromotionButton:SetVoid2(kPromotion.Index);
				promotionInst.PromotionButton:RegisterCallback( Mouse.eLClick, OnPromoteGovernor );
			elseif not canEarnPromotion then
				promotionInst.PromotionButton:SetDisabled(true);
				promotionInst.PromotionButton:SetSelected(false);
				promotionInst.PromotionButton:SetVisState(3);
				promotionInst.PromotionButton:ClearCallback( Mouse.eLClick );
			else
				promotionInst.PromotionButton:SetDisabled(m_isReadOnly);
				promotionInst.PromotionButton:SetSelected(false);
				promotionInst.PromotionButton:SetVisState(0);
				promotionInst.PromotionButton:SetVoid1(m_GovernorIndex);
				promotionInst.PromotionButton:SetVoid2(kPromotion.Index);
				promotionInst.PromotionButton:RegisterCallback( Mouse.eLClick, OnPromoteGovernor );
			end

			-- Add secret promotions to list so we can play effects on them
			promotionInst.NeedsSmokeEffect = isHidden;
		end
	end

    pSecretPromotionTreeInst.PromotionContainer:CalculateSize();
    RefreshSmokeEffects();
end

-- ===========================================================================
function SetGovernorStatus(governorDef:table, governor:table)
	local status, statusDetails = GetGovernorStatus(governorDef, governor);
	Controls.GovernorStatus:SetText(status);
	Controls.GovernorStatusDetails:SetText(statusDetails);
end

-- ===========================================================================
function OnAppointGovernor( eGovernor:number )
	local pLocalPlayer = Players[Game.GetLocalPlayer()];
	if (pLocalPlayer ~= nil) then
		local kParameters:table = {};
		kParameters[PlayerOperations.PARAM_GOVERNOR_TYPE] = eGovernor;
		UI.RequestPlayerOperation(Game.GetLocalPlayer(), PlayerOperations.APPOINT_GOVERNOR, kParameters);
	end
end

-- ===========================================================================
function OnAssignGovernor( eGovernor:number )
	LuaEvents.GovernorAssignmentChooser_RequestAssignment( eGovernor );
	Close();
	LuaEvents.GovernorPanel_AssignDetails();
end

-- ===========================================================================
function OnPromoteGovernor(eGovernor:number, ePromotion:number)
	local promotion=GameInfo.GovernorPromotions[ePromotion];
	local governor=GetAppointedGovernor(Game.GetLocalPlayer(),eGovernor);
	if not LOTM_StarBranchesOwned(governor,promotion) then return; end
	
	if m_SelectedPromotion == ePromotion then
		m_SelectedPromotion = -1;
	else
		m_SelectedPromotion = ePromotion;
	end

	Refresh();
end

-- ===========================================================================
function OnConfirm()
	ApplyPromotion();
end

-- ===========================================================================
function ApplyPromotion()
	local promotion=GameInfo.GovernorPromotions[m_SelectedPromotion];
	local governor=GetAppointedGovernor(Game.GetLocalPlayer(),m_GovernorIndex);
	if not LOTM_StarBranchesOwned(governor,promotion) then m_SelectedPromotion=-1;Refresh();return; end
	local pLocalPlayer = Players[Game.GetLocalPlayer()];
	if (pLocalPlayer ~= nil) then
		local kParameters:table = {};
		kParameters[PlayerOperations.PARAM_GOVERNOR_TYPE] = m_GovernorIndex;
		kParameters[PlayerOperations.PARAM_GOVERNOR_PROMOTION_TYPE] = m_SelectedPromotion;
		UI.RequestPlayerOperation(Game.GetLocalPlayer(), PlayerOperations.PROMOTE_GOVERNOR, kParameters);
	end

	m_SelectedPromotion = -1;
end

-- ===========================================================================
function OnBack()
	Close();
	LuaEvents.GovernorPanel_ClosedDetails();
end

-- ===========================================================================
function OnOpenDetails( governorIndex:number, isReadOnly : boolean )
	m_GovernorIndex = governorIndex;
	m_isReadOnly = isReadOnly;
	Open();
end

-- ===========================================================================
function Open()
	-- Clear promotion queue
	m_SelectedPromotion = -1;
	
	Refresh();
	ContextPtr:SetHide(false);
end

-- ===========================================================================
function Close()
	ContextPtr:SetHide(true);
end

-- ===========================================================================
function OnInit( isReload:boolean )
	if isReload then		
		LuaEvents.GameDebug_GetValues( RELOAD_CACHE_ID );	
	end
end

-- =======================================================================================
function OnShutdown()
	LuaEvents.GameDebug_AddValue(RELOAD_CACHE_ID, "isVisible", ContextPtr:IsVisible());
	LuaEvents.GameDebug_AddValue(RELOAD_CACHE_ID, "governorIndex", m_GovernorIndex);

	Unsubscribe();
end

-- ===========================================================================
function RefreshSmokeEffects()
	for i=1, m_SecretPromotionIM.m_iCount, 1 do
		local pPromotionInstance:table = m_SecretPromotionIM:GetAllocatedInstance(i);
		if pPromotionInstance.NeedsSmokeEffect then
			EffectsManager:PlayEffect(pPromotionInstance.PromotionButton, "FireFX_SecretSocietySmoke");
		else
			EffectsManager:StopEffect(pPromotionInstance.PromotionButton);
		end
	end
end

-- ===========================================================================s
function OnGameDebugReturn( context:string, contextTable:table )
	if context ~= RELOAD_CACHE_ID then
		return;
	end

	if contextTable["governorIndex"] then
		m_GovernorIndex = contextTable["governorIndex"];
	end

	if contextTable["isVisible"] and contextTable["isVisible"] == true then
		Open();
	end
end

-- ===========================================================================
--	Input
--	UI Event Handler
-- ===========================================================================
function OnInputHandler( pInputStruct:table )

	if ContextPtr:IsHidden() then return; end

	local key = pInputStruct:GetKey();
	local msg = pInputStruct:GetMessageType();
	if msg == KeyEvents.KeyUp and key == Keys.VK_ESCAPE then 
		OnBack();
		return true;
	end;
	return false;
end

-- ===========================================================================
function OnLocalPlayerTurnEnd()
	if GameConfiguration.IsHotseat() and ContextPtr:IsVisible() then
		Close();
	end
end

-- ===========================================================================
function Subscribe()
	-- Lua Events
	LuaEvents.GameDebug_Return.Add( OnGameDebugReturn );

	-- Context Events
	LuaEvents.GovernorDetailsPanel_OpenDetails.Add( OnOpenDetails );

	-- Game Events
	Events.GovernorAppointed.Add( Refresh );
	Events.GovernorAssigned.Add( Refresh );
	Events.GovernorChanged.Add( Refresh );
	Events.GovernorPointsChanged.Add( Refresh );
	Events.GovernorPromoted.Add( Refresh );
	Events.LocalPlayerTurnBegin.Add( Refresh );	
	Events.LocalPlayerTurnEnd.Add( OnLocalPlayerTurnEnd );
end

-- ===========================================================================
function Unsubscribe()
	-- Lua Events
	LuaEvents.GameDebug_Return.Remove( OnGameDebugReturn );

	-- Context Events
	LuaEvents.GovernorDetailsPanel_OpenDetails.Remove( OnOpenDetails );

	-- Game Events
	Events.GovernorAppointed.Remove( Refresh );
	Events.GovernorAssigned.Remove( Refresh );
	Events.GovernorChanged.Remove( Refresh );
	Events.GovernorPointsChanged.Remove( Refresh );
	Events.GovernorPromoted.Remove( Refresh );
	Events.LocalPlayerTurnBegin.Remove( Refresh );	
	Events.LocalPlayerTurnEnd.Remove( OnLocalPlayerTurnEnd );
end

-- ===========================================================================
-- ===========================================================================
function Initialize()

	-- Start off hidden
	ContextPtr:SetHide(true);
	ContextPtr:SetInitHandler( OnInit );
	ContextPtr:SetShutdown( OnShutdown );
	ContextPtr:SetInputHandler( OnInputHandler, true );

	-- Control Events
	Controls.ConfirmButton:RegisterCallback( Mouse.eLClick, OnConfirm );
	Controls.BackButton:RegisterCallback( Mouse.eLClick, OnBack );

	Subscribe();

	m_TopPanelConsideredHeight = Controls.Vignette:GetSizeY() - TOP_PANEL_OFFSET;
end
Initialize();
-- BEGIN RC342 STARTUP TRACE

end
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("LOTM_RESCUE_GovernorDetailsPanel","CONTEXT END");
-- END RC342 STARTUP TRACE
