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

local function ShuffleBag(player)
	local bag={"G","G","B","B"};
	local playerID=player~=nil and player:GetID() or -1;
	local bagSerial=LOTM_WORLD_State.NumberProperty(player,"LOTM_WORLD_EVENT_BAG_SERIAL",0)+1;
	for index=#bag,2,-1 do
		local swap=LOTM_WORLD_State.Random(index,"event bag shuffle:player="
			..tostring(playerID)..":bag="..tostring(bagSerial)..":step="..tostring(index))+1;
		bag[index],bag[swap]=bag[swap],bag[index];
	end
	if player~=nil then player:SetProperty("LOTM_WORLD_EVENT_BAG_SERIAL",bagSerial); end
	return table.concat(bag,"");
end

local function Draw(player)
	local bag=player:GetProperty("LOTM_WORLD_EVENT_BAG_ORDER");
	local index=LOTM_WORLD_State.NumberProperty(player,"LOTM_WORLD_EVENT_BAG_INDEX",5);
	if bag==nil or #tostring(bag)~=4 or index<1 or index>4 then
		bag=ShuffleBag(player); index=1;
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
	-- NotificationManager and Locale are presentation services.  A client-side
	-- notification failure must never decide whether synchronized Gameplay
	-- retries the event on a later turn.  In multiplayer commit the delivery
	-- ledger first, then make the localized notification best-effort.  The
	-- original single-player retry-on-failure behavior remains below.
	if LOTM_MP_TurnSync.IsNetworkGame() then
		player:SetProperty("LOTM_WORLD_NOTIFICATION_DELIVERED_SERIAL",serial);
		local ok,err=pcall(Notify,player,tostring(kind),player:GetProperty("LOTM_WORLD_EVENT_TARGET"));
		if ok then
			Log("notification delivered player="..tostring(player:GetID()).." serial="..tostring(serial).." path="..tostring(player:GetProperty("LOTM_RP_PATH")).." mode=network-best-effort");
		else
			Log("WARNING network notification skipped after ledger commit player="..tostring(player:GetID()).." serial="..tostring(serial).." error="..tostring(err));
		end
		return;
	end
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
	local eventSerial=LOTM_WORLD_State.NumberProperty(player,"LOTM_WORLD_EVENT_SERIAL",0)+1;
	local eventKey="player="..tostring(player:GetID())..":playerTurn="..tostring(turn)
		..":event="..tostring(eventSerial);
	local useArtifact=#equipped>0 and LOTM_WORLD_State.Random(2,"event target type:"..eventKey)==0;
	local kind="";
	local targetType=nil;
	if useArtifact then
		local target=equipped[LOTM_WORLD_State.Random(#equipped,"artifact event target:"..eventKey)+1];
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
	player:SetProperty("LOTM_WORLD_NEXT_EVENT_TURN",turn+NEXT_MIN
		+LOTM_WORLD_State.Random(NEXT_SPAN,"next event interval:"..eventKey));
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
		nextTurn=turn+FIRST_MIN+LOTM_WORLD_State.Random(FIRST_SPAN,
			"first event interval:player="..tostring(playerID)..":playerTurn="..tostring(turn));
		player:SetProperty("LOTM_WORLD_NEXT_EVENT_TURN",nextTurn);
		Log("scheduled first player="..tostring(playerID).." current="..tostring(turn).." target="..tostring(nextTurn));
	end
	if turn>=nextTurn then Trigger(player,turn); end
	RefreshHolder(player,turn);
end

LOTM_MP_TurnSync.Add(OnTurn,"WorldEvents");
Log("initialized bag=GGBB duration=5 first=12-18 next=10-16 notifications=USER_DEFINED_6-9");
