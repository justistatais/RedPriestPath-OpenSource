-- Shared synchronized helpers for Extraordinary World systems.
LOTM_WORLD_State = LOTM_WORLD_State or {};

LOTM_WORLD_State.VERSION = 6;

function LOTM_WORLD_State.NumberProperty(object,key,default)
	local value=object~=nil and object:GetProperty(key) or nil;
	if value==nil then return default; end
	return tonumber(value) or default;
end

function LOTM_WORLD_State.NumberGameProperty(key,default)
	local value=Game.GetProperty(key);
	if value==nil then return default; end
	return tonumber(value) or default;
end

function LOTM_WORLD_State.GetPlayer(playerID)
	local player=Players[playerID];
	return player~=nil and player:IsAlive() and player:IsMajor() and player or nil;
end

function LOTM_WORLD_State.IsHuman(playerID)
	local player=LOTM_WORLD_State.GetPlayer(playerID);
	return player~=nil and player:IsHuman();
end

function LOTM_WORLD_State.Random(maxExclusive,label)
	if maxExclusive==nil or maxExclusive<=0 then return 0; end
	local fullLabel="LOTM_WORLD:"..tostring(label);
	return LOTM_MP_TurnSync.Random(maxExclusive,fullLabel,fullLabel);
end

function LOTM_WORLD_State.NextPlayerTurn(player)
	local turn=LOTM_WORLD_State.NumberProperty(player,"LOTM_WORLD_PLAYER_TURN",0)+1;
	player:SetProperty("LOTM_WORLD_PLAYER_TURN",turn);
	player:SetProperty("LOTM_WORLD_STATE_VERSION",LOTM_WORLD_State.VERSION);
	return turn;
end

LOTM_MP_TurnSync.RunStartup(function()
	local storedVersion=LOTM_WORLD_State.NumberGameProperty("LOTM_WORLD_STATE_VERSION",0);
	if storedVersion<LOTM_WORLD_State.VERSION then
		Game.SetProperty("LOTM_WORLD_STATE_VERSION",LOTM_WORLD_State.VERSION);
	end
end,"WorldState");

print("[LOTM_WORLD][State] initialized version="..tostring(LOTM_WORLD_State.VERSION));
