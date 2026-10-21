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
LOTM_StartupTrace.Mark("LOTM_WORLD_ChurchPanel","CONTEXT BEGIN");
local Events = LOTM_StartupTrace.Events(Events,"LOTM_WORLD_ChurchPanel","Events");
local GameEvents = LOTM_StartupTrace.Events(GameEvents,"LOTM_WORLD_ChurchPanel","GameEvents");
local LuaEvents = LOTM_StartupTrace.Events(LuaEvents,"LOTM_WORLD_ChurchPanel","LuaEvents");
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
do
-- END RC342 STARTUP TRACE
local current=nil;
local Close=nil;
local DEFINITIONS={
 FOOL={Name="LOC_LOTM_CHURCH_FOOL_NAME",Path="LOC_LOTM_CHURCH_FOOL_PATH",Icon="ICON_LOTM_CHURCH_FOOL",Color="COLOR_LOTM_CHURCH_FOOL"},
 NIGHT={Name="LOC_LOTM_CHURCH_NIGHT_NAME",Path="LOC_LOTM_CHURCH_NIGHT_PATH",Icon="ICON_LOTM_CHURCH_NIGHT",Color="COLOR_LOTM_CHURCH_NIGHT"},
 STORM={Name="LOC_LOTM_CHURCH_STORM_NAME",Path="LOC_LOTM_CHURCH_STORM_PATH",Icon="ICON_LOTM_CHURCH_STORM",Color="COLOR_LOTM_CHURCH_STORM"}
};

local function Log(message)
 print("[LOTM_WORLD][ChurchPanel] "..tostring(message));
end

local function LocalPlayer()
 local id=Game.GetLocalPlayer();
 return id~=nil and id>=0 and Players[id] or nil;
end

local function P(suffix,default)
 local player=LocalPlayer();
 local value=player~=nil and player:GetProperty("LOTM_CHURCH_"..tostring(current).."_"..suffix) or nil;
 return value==nil and default or value;
end

local function SafeSetIcon(control,iconName,size)
 if control==nil then Log("missing ChurchIcon control"); return false; end
 if IconManager==nil or IconManager.FindIconAtlas==nil then Log("IconManager unavailable"); return false; end
 local x,y,sheet=IconManager:FindIconAtlas(iconName,size);
 if sheet==nil or sheet=="" then Log("icon miss "..tostring(iconName).." size="..tostring(size)); return false; end
 control:SetTexture(x,y,sheet);
 Log("icon hit "..tostring(iconName).." size="..tostring(size).." sheet="..tostring(sheet));
 return true;
end

local function LocalizedQuestState(value)
 return Locale.Lookup("LOC_LOTM_CHURCH_STATE_"..tostring(value or "LOCKED"));
end

local function LocalizedTargetKind(value)
 return Locale.Lookup("LOC_LOTM_CHURCH_TARGET_KIND_"..tostring(value or "NONE"));
end

local function TargetPlotIndex()
 local kind=tostring(P("TARGET_KIND","NONE")); local stored=tonumber(P("TARGET_PLOT",-1)) or -1;
 if kind=="MONSTER" then
  local serial=tonumber(P("TARGET_ID",-1)) or -1;
  local ownerValue=Game.GetProperty("LOTM_WORLD_MONSTER:"..serial..":OWNER"); local unitValue=Game.GetProperty("LOTM_WORLD_MONSTER:"..serial..":UNIT_ID");
  local owner=ownerValue~=nil and tonumber(ownerValue) or nil; local unitID=unitValue~=nil and tonumber(unitValue) or nil;
  local unit=owner~=nil and unitID~=nil and UnitManager.GetUnit(owner,unitID) or nil;
  if unit~=nil then local currentPlot=Map.GetPlot(unit:GetX(),unit:GetY()); if currentPlot~=nil then return currentPlot:GetIndex(); end end
 end
 return stored;
end

local function PlotLocation(plotIndex)
 local plot=plotIndex~=nil and plotIndex>=0 and Map.GetPlotByIndex(plotIndex) or nil;
 return plot~=nil and Locale.Lookup("LOC_LOTM_CHURCH_COORDINATES",plot:GetX(),plot:GetY()) or Locale.Lookup("LOC_LOTM_CHURCH_LOCATION_UNKNOWN");
end

local function RewardSummary(church,tier)
 local prefix="QUEST_"..tostring(tier).."_"; local kind=tostring(P(prefix.."REWARD_KIND","")); if kind=="" then return nil; end
 if kind=="ARTIFACT" then local artifact=P(prefix.."REWARD_ARTIFACT",nil); local row=artifact~=nil and GameInfo.GreatWorks[artifact] or nil; return Locale.Lookup("LOC_LOTM_CHURCH_REWARD_STATUS_ARTIFACT",tier,row~=nil and Locale.Lookup(row.Name) or tostring(artifact or "")); end
 local strength=tostring(P(prefix.."REWARD_STRENGTH",kind=="HALF_BLESSING" and "HALF" or "FULL")); return Locale.Lookup("LOC_LOTM_CHURCH_REWARD_STATUS_BLESSING",tier,Locale.Lookup("LOC_LOTM_CHURCH_BLESS_"..church.."_"..tier.."_"..strength));
end

local function Refresh()
 local d=DEFINITIONS[current];
 if d==nil then return; end
 local color=UI.GetColorValue(d.Color);
 -- The 32px church atlas is already proven by the live City States reward slots.
 -- A missing icon must never prevent the synchronized quest text from rendering.
 SafeSetIcon(Controls.ChurchIcon,d.Icon,32);
 if Controls.ChurchIcon~=nil then Controls.ChurchIcon:SetColor(color); end
 if Controls.Title~=nil then Controls.Title:SetText(Locale.Lookup(d.Name)); Controls.Title:SetColor(color); end
 if Controls.Path~=nil then Controls.Path:SetText(Locale.Lookup(d.Path)); end

 local envoys=tonumber(P("ENVOYS",0)) or 0;
 if Controls.Envoys~=nil then Controls.Envoys:SetText(Locale.Lookup("LOC_LOTM_CHURCH_ENVOY_COUNT",envoys)); end
 if Controls.Permanent~=nil then Controls.Permanent:SetText(Locale.Lookup("LOC_LOTM_CHURCH_PERMANENT_HEADER").."[NEWLINE]"..Locale.Lookup("LOC_LOTM_CHURCH_"..current.."_PERM_1").."[NEWLINE]"..Locale.Lookup("LOC_LOTM_CHURCH_"..current.."_PERM_3").."[NEWLINE]"..Locale.Lookup("LOC_LOTM_CHURCH_"..current.."_PERM_6")); end

 local q6=LocalizedQuestState(P("QUEST_6_STATE","LOCKED"));
 local q10=LocalizedQuestState(P("QUEST_10_STATE","LOCKED"));
 local q15=LocalizedQuestState(P("QUEST_15_STATE","LOCKED"));
 if Controls.Quests~=nil then
  local rescue=tonumber(Game.GetProperty("LOTM_RESCUE_MODE") or 0)==1; local questText=nil; local rewardTiers=nil;
  if rescue then
   local player=LocalPlayer(); local shared=player~=nil and tonumber(player:GetProperty("LOTM_RESCUE_WAR_GOD_RELIC_COMPLETED") or 0)==1 and "LOC_LOTM_RESCUE_WAR_GOD_RELIC_TASK_COMPLETE"
    or player~=nil and tonumber(player:GetProperty("LOTM_RESCUE_WAR_GOD_RELIC_REQUIREMENT_MET") or 0)==1 and "LOC_LOTM_RESCUE_WAR_GOD_RELIC_TASK_PROJECT"
    or "LOC_LOTM_RESCUE_WAR_GOD_RELIC_TASK_ENVOYS";
   questText=Locale.Lookup(shared).."[NEWLINE]"..Locale.Lookup("LOC_LOTM_RESCUE_CHURCH_ORACLE_STATES",q10,q15); rewardTiers={10,15};
  else questText=Locale.Lookup("LOC_LOTM_CHURCH_QUESTS",q6,q10,q15); rewardTiers={6,10,15}; end
  for _,completedTier in ipairs(rewardTiers) do local reward=RewardSummary(current,completedTier); if reward~=nil then questText=questText.."[NEWLINE]"..reward; end end Controls.Quests:SetText(questText);
 end

 local tier=tonumber(P("ACTIVE_TIER",0)) or 0;
 local kind=tostring(P("TARGET_KIND","NONE"));
 local plot=TargetPlotIndex(); local location=PlotLocation(plot);
 local progress=tonumber(P("TARGET_PROGRESS",0)) or 0;
 if Controls.Target~=nil then
  if tier<=0 then Controls.Target:SetText(Locale.Lookup("LOC_LOTM_CHURCH_ORACLE_NO_ACTIVE"));
  elseif kind=="BARB_CAMP_COUNT" then Controls.Target:SetText(Locale.Lookup("LOC_LOTM_CHURCH_CAMP_TARGET",tier,progress,2));
  else Controls.Target:SetText(Locale.Lookup("LOC_LOTM_CHURCH_TARGET",tier,LocalizedTargetKind(kind),location)); end
 end
 if Controls.Locate~=nil then Controls.Locate:SetHide(tier<=0 or plot<0); Controls.Locate:RegisterCallback(Mouse.eLClick,function() local target=TargetPlotIndex(); local p=target>=0 and Map.GetPlotByIndex(target) or nil; if p~=nil then Close(); UI.LookAtPlot(p:GetX(),p:GetY()); end end); end

 local bt=tonumber(P("BLESSING_TIER",0)) or 0;
 local bs=tostring(P("BLESSING_STRENGTH","NONE"));
 local untilTurn=tonumber(P("BLESSING_UNTIL",0)) or 0;
 local player=LocalPlayer();
 local turnValue=player~=nil and player:GetProperty("LOTM_WORLD_PLAYER_TURN") or nil;
 local now=turnValue~=nil and (tonumber(turnValue) or 0) or 0;
 local summary=bt>0 and Locale.Lookup("LOC_LOTM_CHURCH_BLESS_"..current.."_"..bt.."_"..bs) or Locale.Lookup("LOC_LOTM_CHURCH_BLESSING",0,"NONE",0);
 if Controls.Blessing~=nil then Controls.Blessing:SetText(Locale.Lookup("LOC_LOTM_CHURCH_BLESSING",bt,bs,math.max(0,untilTurn-now)).."[NEWLINE]"..summary); end
 if Controls.Content~=nil then Controls.Content:CalculateSize(); end
 Log("refreshed church="..current.." envoys="..envoys.." tier="..tier.." target="..kind..":"..tostring(plot));
end

local function Open(church)
 if DEFINITIONS[church]==nil then return; end
 current=church; Refresh();
 if Controls.Root~=nil then Controls.Root:SetHide(false); end
end

Close=function()
 if Controls.Root~=nil then Controls.Root:SetHide(true); end
 current=nil;
end

if Controls.Close~=nil then Controls.Close:RegisterCallback(Mouse.eLClick,Close); end
LuaEvents.LOTM_ChurchPanel_Open.Add(Open);
Events.PlayerTurnActivated.Add(function(id) if current~=nil and id==Game.GetLocalPlayer() then Refresh(); end end);
Events.GameCoreEventPublishComplete.Add(function() if current~=nil then Refresh(); end end);
-- BEGIN RC342 STARTUP TRACE

end
-- END RC342 STARTUP TRACE
-- BEGIN RC342 STARTUP TRACE
LOTM_StartupTrace.Mark("LOTM_WORLD_ChurchPanel","CONTEXT END");
-- END RC342 STARTUP TRACE
