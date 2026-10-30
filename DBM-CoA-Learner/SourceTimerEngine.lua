-- CoA source-driven timer engine for 3.3.5a. No new anchors or channels.
-- Adds only mechanics not already timed by a stock DBM encounter module.
-- Existing encounter modules always take priority; learner records discrepancies.
local sources=DBMCoAServerSources or {}
local state={}
local f=CreateFrame("Frame")
local function npc(guid)
 if type(guid)~="string" then return nil end
 if guid:sub(1,6)=="0xF130" then return tonumber(guid:sub(7,10),16) end
 if guid:find("^Creature%-") then return tonumber(guid:match("^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)%-")) end
 return nil
end
local band=bit and bit.band
local function hostile(flags)
 return type(flags)=="number" and band and band(flags,0x800)~=0 and band(flags,0x3000)==0 and band(flags,0x100)==0
end
local function spellName(id)
 local name,_,icon=GetSpellInfo(id)
 return name or ("Spell "..id),icon or "Interface\\Icons\\INV_Misc_PocketWatch_01"
end
local function stock(id,sid)
 local s=DBMCoAStockTimerIndex
 return s and s[id] and s[id][sid]
end
local function learned(id,sid)
 local d=DBMCoALearnerDB
 if not d or not d.encounterTimers24 then return nil end
 local zone,kind,diff=GetInstanceInfo()
 if kind~="party" and kind~="raid" then kind="world" end
 if not zone or zone=="" then zone=GetRealZoneText() end
 local r=d.encounterTimers24[kind]
 r=r and r[zone];r=r and r[tostring(diff or 0)];r=r and r[tostring(id)]
 r=r and r.spells and r.spells[tostring(sid)]
 -- Only adjust when a well-sampled estimate exists, and never override stock modules.
 if r and r.estimate and (r.confidence or 0)>=8 and r.estimate>=5 and r.estimate<=180 then return r.estimate end
 return nil
end
local function timer(id,sid,duration)
 if stock(id,sid) or not DBM or not DBM.Bars or not DBM.Bars.CreateBar then return end
 if not duration or duration<=0 then return end
 local name,icon=spellName(sid)
 DBM.Bars:CreateBar(duration,"[CoA] "..name,icon)
end
local function phaseStart(id,phase,delay)
 local cfg=sources[id];local st=state[id]
 if not cfg or not st then return end
 st.phase=phase
 for sid,ability in pairs(cfg.abilities) do
  if ability.phase==phase and not stock(id,sid) then
   local duration=ability.firstMin or ability.firstMax
   if duration and duration>0 then timer(id,sid,math.max(1,duration-(delay or 0))) end
  end
 end
end
local function reset()
 for id in pairs(state) do state[id]=nil end
end
local function checkHealth(unit)
 if not UnitExists(unit) or not UnitCanAttack("player",unit) then return end
 local id=npc(UnitGUID(unit));local cfg=id and sources[id];local st=id and state[id]
 if not cfg or not st or st.phase~=1 or not cfg.phaseTwoHealth or cfg.phaseTwoHealth<=0 then return end
 local max=UnitHealthMax(unit)
 if max and max>0 and UnitHealth(unit)/max*100<=cfg.phaseTwoHealth then phaseStart(id,2,0) end
end
local function combatLog(...)
 local event=select(2,...);local offset=type(select(3,...))=="boolean" and 1 or 0
 local guid=select(3+offset,...);local flags=select(5+offset,...)
 if not hostile(flags) then return end
 local id=npc(guid);local cfg=id and sources[id]
 if not cfg then return end
 local now=GetTime();local st=state[id]
 if not st then st={phase=1,last={},first=now};state[id]=st;phaseStart(id,1,0) end
 if event=="UNIT_DIED" then state[id]=nil;return end
 if event~="SPELL_CAST_START" and event~="SPELL_CAST_SUCCESS" and event~="SPELL_AURA_APPLIED" then return end
 local sid=select(9+offset,...)
 if type(sid)~="number" then return end
 if id==14510 then
  if sid==24084 then phaseStart(id,2,0)
  elseif sid==24085 then phaseStart(id,1,0) end
 elseif id==14507 and sid==23849 then phaseStart(id,2,0) end
 local ability=cfg.abilities[sid]
 if not ability or stock(id,sid) or st.phase~=ability.phase then return end
 if st.last[sid] and now-st.last[sid]<2 then return end
 st.last[sid]=now
 local duration=learned(id,sid) or ability.repeatMin or ability.repeatMax
 timer(id,sid,duration)
end
f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:RegisterEvent("PLAYER_TARGET_CHANGED")
f:RegisterEvent("UNIT_HEALTH")
f:SetScript("OnEvent",function(self,event,...)
 if event=="COMBAT_LOG_EVENT_UNFILTERED" then combatLog(...)
 elseif event=="PLAYER_ENTERING_WORLD" or event=="PLAYER_REGEN_ENABLED" then reset()
 elseif event=="PLAYER_TARGET_CHANGED" then checkHealth("target")
 elseif event=="UNIT_HEALTH" then local unit=...;if unit then checkHealth(unit) end end
end)
SLASH_COASOURCES1="/coasources"
SlashCmdList.COASOURCES=function()
 local npcs,spells,extra=0,0,0
 for id,cfg in pairs(sources) do
  npcs=npcs+1
  for sid in pairs(cfg.abilities) do spells=spells+1;if not stock(id,sid) then extra=extra+1 end end
 end
 if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("DBM-CoA source timers: "..npcs.." source bosses, "..spells.." scheduled spells, "..extra.." non-stock spell timers eligible for source-driven bars. /dbm move controls their anchors.") end
end
