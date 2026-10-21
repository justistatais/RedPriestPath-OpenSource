-- Diagnostic-only timing for UnitAddedToMap handlers and bounded sections.
-- The local clock affects only in-memory reports and print output.  It never
-- writes synchronized Properties, consumes random numbers, or changes results.
LOTM_UnitAddedPerf={Stats={},Order={},Events=0,FirstTurnReported=false,Enabled=true,Sections={},SectionOrder={},SectionEnabled=true,TurnStats={}};

local m_timerName="LuaFallback";
local m_now=os.clock;
if Automation~=nil and Automation.GetTime~=nil then
 local candidate=Automation.GetTime;
 local ok,sample=pcall(candidate);
 if ok and type(sample)=="number" then m_timerName="Automation.GetTime"; m_now=candidate; end
end
local function PerfNow() return m_now(); end

function LOTM_UnitAddedPerf.MeasureTurn(label,callback,playerID,isFirstTimeThisTurn)
 local started=PerfNow();
 callback(playerID,isFirstTimeThisTurn);
 local elapsed=(PerfNow()-started)*1000;
 local name=tostring(label or "UNNAMED"); local stat=LOTM_UnitAddedPerf.TurnStats[name];
 if stat==nil then stat={Calls=0,TotalMs=0,MaxMs=0}; LOTM_UnitAddedPerf.TurnStats[name]=stat; end
 stat.Calls=stat.Calls+1; stat.TotalMs=stat.TotalMs+elapsed; if elapsed>stat.MaxMs then stat.MaxMs=elapsed; end
 -- Keep normal turns quiet while preserving every measurable hot path. The
 -- shipped clock has millisecond granularity, so sub-millisecond zeroes add
 -- noise without helping diagnosis.
 if elapsed>=1 then
  print(string.format("[LOTM_PERF][Turn] timer=%s turn=%s player=%s module=%s ms=%.3f",m_timerName,tostring(Game~=nil and Game.GetCurrentGameTurn~=nil and Game.GetCurrentGameTurn() or -1),tostring(playerID),name,elapsed));
 end
end

local function EnsureSection(name)
 local stat=LOTM_UnitAddedPerf.Sections[name];
 if stat==nil then
  stat={Calls=0,TotalMs=0,MaxMs=0,Items=0};
  LOTM_UnitAddedPerf.Sections[name]=stat;
  LOTM_UnitAddedPerf.SectionOrder[#LOTM_UnitAddedPerf.SectionOrder+1]=name;
 end
 return stat;
end

function LOTM_UnitAddedPerf.Wrap(name,callback)
 local stat={Calls=0,TotalMs=0,MaxMs=0};
 LOTM_UnitAddedPerf.Stats[name]=stat;
 LOTM_UnitAddedPerf.Order[#LOTM_UnitAddedPerf.Order+1]=name;
 return function(playerID,unitID,x,y)
  if not LOTM_UnitAddedPerf.Enabled then callback(playerID,unitID,x,y); return; end
  local started=PerfNow(); callback(playerID,unitID,x,y);
  local elapsed=(PerfNow()-started)*1000;
  stat.Calls=stat.Calls+1; stat.TotalMs=stat.TotalMs+elapsed;
  if elapsed>stat.MaxMs then stat.MaxMs=elapsed; end
 end
end

function LOTM_UnitAddedPerf.Report(reason)
 for _,name in ipairs(LOTM_UnitAddedPerf.Order) do
  local stat=LOTM_UnitAddedPerf.Stats[name];
  local average=stat.Calls>0 and stat.TotalMs/stat.Calls or 0;
  print(string.format("[LOTM_PERF][UnitAdded] timer=%s reason=%s events=%d module=%s calls=%d totalMs=%.3f avgMs=%.3f maxMs=%.3f",m_timerName,tostring(reason),LOTM_UnitAddedPerf.Events,name,stat.Calls,stat.TotalMs,average,stat.MaxMs));
 end
end

function LOTM_UnitAddedPerf.BeginSection()
 if not LOTM_UnitAddedPerf.SectionEnabled then return nil; end
 return PerfNow();
end

-- Diagnostic-only elapsed time for callers that need one immediate structured
-- log line.  The returned value must never drive synchronized gameplay state.
function LOTM_UnitAddedPerf.ElapsedSince(started)
 if started==nil then return 0; end
 return math.max(0,(PerfNow()-started)*1000);
end

function LOTM_UnitAddedPerf.EndSection(name,started,items)
 if not LOTM_UnitAddedPerf.SectionEnabled or started==nil then return; end
 local elapsed=(PerfNow()-started)*1000;
 local stat=EnsureSection(name);
 stat.Calls=stat.Calls+1; stat.TotalMs=stat.TotalMs+elapsed; stat.Items=stat.Items+(tonumber(items) or 0);
 if elapsed>stat.MaxMs then stat.MaxMs=elapsed; end
end

function LOTM_UnitAddedPerf.MarkSection(name,items)
 if not LOTM_UnitAddedPerf.SectionEnabled then return; end
 local stat=EnsureSection(name);
 stat.Calls=stat.Calls+1; stat.Items=stat.Items+(tonumber(items) or 0);
end

function LOTM_UnitAddedPerf.ReportSections(reason)
 for _,name in ipairs(LOTM_UnitAddedPerf.SectionOrder) do
  local stat=LOTM_UnitAddedPerf.Sections[name];
  local average=stat.Calls>0 and stat.TotalMs/stat.Calls or 0;
  print(string.format("[LOTM_PERF][Section] timer=%s reason=%s section=%s calls=%d items=%d totalMs=%.3f avgMs=%.3f maxMs=%.3f",m_timerName,tostring(reason),name,stat.Calls,stat.Items,stat.TotalMs,average,stat.MaxMs));
 end
end

function LOTM_UnitAddedPerf.EventCompleted()
 if LOTM_UnitAddedPerf.Enabled then LOTM_UnitAddedPerf.Events=LOTM_UnitAddedPerf.Events+1; end
end

print("[LOTM_PERF][UnitAdded] probe loaded timer="..m_timerName.." report=firstPlayerTurn stateWrites=false random=false");
