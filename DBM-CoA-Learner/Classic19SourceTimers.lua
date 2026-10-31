-- Source-backed dungeon predictive timers; never live-verified.
-- Enabled by default; explicit saved opt-outs respected. Map+NPC+spell strict matching.
local rows={
 {36,646,975011,7550,9550,8000,9000},
 {36,646,2102553,15000,17000,15000,17000},
 {36,646,2102580,2600,4600,10000,12000},
 {36,646,2102576,5000,8000,65000,67000},
 {36,646,2102577,5000,8000,20000,22000},
 {36,642,975011,8400,8400,7800,7800},
 {36,642,2102559,12000,15000,20000,25000},
 {36,642,2102569,5000,8000,15000,20000},
 {36,644,975011,8400,8400,7800,7800},
 {36,644,2102553,12000,16000,15000,20000},
 {36,644,2102554,8000,10000,15000,20000},
 {36,645,2102590,20000,25000,30000,40000},
 {36,645,2102589,1500,2500,1600,1700},
 {36,645,2102527,8000,12000,12000,18000},
 {36,647,40505,1000,7000,10000,15000},
 {36,647,5208,10000,12000,25000,35000},
 {36,647,975011,8400,8400,7800,7800},
 {36,647,2101111,15000,20000,20000,25000},
 {36,1763,5213,1000,6000,15000,25000},
 {36,1763,975011,8400,8400,7800,7800},
 {36,1763,2102571,10000,14000,18000,24000},
 {209,7604,975011,5800,7800,8000,9000},
 {229,10363,975011,8500,10500,9000,10000},
 {229,10363,2102619,14600,16600,15000,17000},
 {229,10363,2102203,22000,24000,25000,27000},
 {229,10220,2100428,4000,6000,10000,12000},
 {229,10220,975011,7000,9000,7000,8000},
 {229,9196,975011,7000,9000,7000,8000},
 {229,9196,2100148,13600,15600,15000,17000},
 {229,9568,2100345,10000,12000,10000,12000},
 {229,9568,975011,7000,9000,7000,8000},
 {229,9816,975011,8000,10000,8000,9000},
 {229,9816,2102825,8000,12000,12000,16000},
 {229,9736,2102850,1000,3000,20000,22000},
 {229,9736,2100255,2600,4600,10000,12000},
 {229,9736,2102851,5000,7000,10000,12000},
 {229,9736,975011,7000,9000,7000,8000},
 {229,10430,2102192,1000,3000,20000,22000},
 {229,10430,975011,9000,11000,9000,10000},
 {229,10430,2102159,29000,31000,35000,37000},
 {229,10430,2100205,8000,12000,10000,14000},
 {229,10430,2100439,5000,8000,20000,22000},
 {229,9237,2100465,3550,5550,15000,17000},
 {229,9237,975011,7449,9450,8000,9000},
 {229,9237,15284,8000,10000,10000,12000},
 {229,9237,15615,10000,12000,16000,18000},
 {229,9237,10966,12000,14000,14000,16000},
 {229,10509,14516,5000,7000,4000,6000},
 {229,10509,15749,10000,10000,5000,15000},
 {229,10509,2102840,8000,12000,15000,20000},
 {229,10509,975011,7700,9700,8000,9000},
 {229,10899,15580,5000,7000,4000,6000},
 {229,10899,16172,5000,10000,20000,20000},
 {229,10899,6253,10000,10000,10000,10000},
 {229,10899,2102553,8000,10000,12000,16000},
 {229,10899,2102138,6000,6000,25000,30000},
 {229,10899,2102137,16000,16000,25000,30000},
 {229,10899,975011,5000,7000,6000,8000},
 {230,9156,975011,8000,10000,8000,9000},
 {230,9039,975011,7000,9000,7000,8000},
 {230,9039,505347,5000,8000,20000,22000},
 {230,9019,975011,8000,10000,8000,9000},
 {230,9019,92603,10000,12000,10000,12000},
 {230,9019,92606,15000,17000,15000,17000},
 {230,9019,381251,8000,12000,18000,22000},
 {230,9019,815637,5000,8000,20000,22000},
 {230,9033,975011,7449,9450,10000,11000},
 {230,9018,975011,9000,11000,9000,10000},
 {230,9018,14033,3000,4000,4000,4500},
 {230,9938,975011,8000,10000,8000,9000},
 {230,9502,975011,8000,10000,8000,9000},
 {230,9502,17203,8000,10000,15000,17000},
 {289,1853,2100398,1500,2000,3000,3500},
 {289,1853,2100389,1000,1500,2900,3400},
 {289,1853,2100393,10000,12000,10000,12000},
 {289,10506,2100034,3100,3600,3100,3600},
 {289,10506,975011,8000,10000,8000,9000},
 {289,10506,2100004,10000,12000,10000,12000},
 {329,10436,816867,10000,12000,10000,12000},
 {329,10436,975011,8000,10000,8000,9000},
}
local byMap={}
for _,r in ipairs(rows) do local m=r[1];byMap[m]=byMap[m] or {};local n=r[2];byMap[m][n]=byMap[m][n] or {};byMap[m][n][r[3]]=r end
local f=CreateFrame("Frame")
local map=0;local last={};local band=bit and bit.band
local function npc(g) if type(g)~="string" then return end if g:sub(1,6)=="0xF130" then return tonumber(g:sub(7,10),16) end return tonumber(g:match("^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)%-")) end
local function zone() local _,kind,_,_,_,_,_,id=GetInstanceInfo();map=kind=="party" and (tonumber(id) or 0) or 0;last={} end
local function stock(n,s) local t=DBMCoAStockTimerIndex;return t and t[n] and t[n][s] end
local function bar(sec,sid) if not DBM or not DBM.Bars or not DBM.Bars.CreateBar then return end local name,_,icon=GetSpellInfo(sid);DBM.Bars:CreateBar(sec,"[CoA source?] "..(name or tostring(sid)),icon or "Interface\\Icons\\INV_Misc_PocketWatch_01") end
local function log(...)
 local db=DBMCoALearnerDB;if not db or db.coaDungeonResearchEnabled==false or db.coaDungeonPredictiveTimers==false then return end
 local t=byMap[map];if not t then return end
 local ev=select(2,...);if ev~="SPELL_CAST_START" and ev~="SPELL_CAST_SUCCESS" then return end
 local off=type(select(3,...))=="boolean" and 1 or 0;local guid=select(3+off,...);local flags=select(5+off,...)
 if type(flags)~="number" or not band or band(flags,0x800)==0 or band(flags,0x3000)~=0 or band(flags,0x100)~=0 then return end
 local id=npc(guid);local spells=id and t[id];if not spells then return end
 local sid=select(9+off,...);local r=spells[sid];if not r or stock(id,sid) then return end
 local key=tostring(id)..":"..sid;local now=GetTime();if last[key] and now-last[key]<2 then return end;last[key]=now
 -- On observed cast, use lower bound of source repeat range; never infer unobserved first casts.
 local ms=r[6];if ms and ms>=1000 then bar(ms/1000,sid) end
end
f:RegisterEvent("PLAYER_ENTERING_WORLD");f:RegisterEvent("ZONE_CHANGED_NEW_AREA");f:RegisterEvent("PLAYER_REGEN_ENABLED");f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
f:SetScript("OnEvent",function(_,event,...) if event=="COMBAT_LOG_EVENT_UNFILTERED" then log(...) elseif event=="PLAYER_REGEN_ENABLED" then last={} else zone() end end)
