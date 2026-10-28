-- DBM-CoA Observer v1: passive, bounded encounter evidence collection.
-- Independent of DBM-Core and DBM-CoA-Learner: no channel joins, no chat filters,
-- no writes to the learner's tables, and no outgoing messages.
local f=CreateFrame("Frame")
local db, active, elapsed, fight, combatOn, lastTarget = nil, false, 0, nil, false, nil
local MAX_FIGHTS, MAX_ABILITIES, MAX_EVENTS, MAX_NPCS = 100, 300, 500, 250
local function now() return GetTime() end
local function npc(g)
 if type(g)~="string" then return nil end
 if g:sub(1,2)=="0x" then return tonumber(g:sub(9,12),16) end
 if g:find("^Creature%-") or g:find("^Vehicle%-") then return tonumber(g:match("%-(%d+)%-[0-9a-fA-F]+$")) end
end
local function instance()
 local name,kind,diff=GetInstanceInfo()
 return {name=name or "",kind=kind or "none",difficulty=diff or 0,map=(GetCurrentMapAreaID and GetCurrentMapAreaID()) or 0}
end
local function eligible(z) return z.kind=="party" or z.kind=="raid" or z.kind=="pvp" or z.kind=="arena" end
local function safe(v) return tostring(v or ""):gsub("[%c|;]"," "):sub(1,70) end
local function putEvent(e,source,spell,detail)
 if not fight or #fight.events>=MAX_EVENTS then return end
 fight.events[#fight.events+1]={t=math.floor((now()-fight.start)*10+0.5)/10,event=e,npc=source or 0,spell=spell or 0,detail=safe(detail)}
end
local function finish(reason)
 if not fight then return end
 fight.duration=math.floor((now()-fight.start)*10+0.5)/10
 fight.start=nil;fight.reason=reason
 if fight.eventCount>0 or next(fight.npcs) then
  db.fights[#db.fights+1]=fight
  while #db.fights>MAX_FIGHTS do table.remove(db.fights,1) end
 end
 fight=nil;lastTarget=nil
end
local function begin()
 if fight or not active or not combatOn then return end
 local z=instance()
 fight={zone=safe(z.name),type=z.kind,difficulty=z.difficulty,map=z.map,date=date("%Y-%m-%d %H:%M"),start=now(),eventCount=0,npcs={},abilities={},events={},emotes={},health={},truncated=0}
end
local function checkZone()
 local z=instance()
 local ok=eligible(z)
 if fight and (not ok or z.name~=fight.zone or z.difficulty~=fight.difficulty) then finish("zone") end
 active=ok
 if active and combatOn then begin() end
end
local function ability(id,spell,ev,label)
 if not fight or not id or not spell or spell<=0 then return end
 local key=tostring(id)..":"..tostring(spell)..":"..ev
 local a=fight.abilities[key]
 if not a then
  local n=0;for _ in pairs(fight.abilities) do n=n+1 end
  if n>=MAX_ABILITIES then fight.truncated=fight.truncated+1;return end
  a={npc=id,spell=spell,event=ev,name=safe(label),count=0,first=nil,last=nil,minGap=nil,maxGap=nil,sumGap=0,gaps=0}
  fight.abilities[key]=a
 end
 local t=math.floor((now()-fight.start)*10+0.5)/10
 if a.last and t-a.last>=1 then
  local gap=math.floor((t-a.last)*10+0.5)/10
  a.minGap=math.min(a.minGap or gap,gap);a.maxGap=math.max(a.maxGap or gap,gap)
  a.sumGap=a.sumGap+gap;a.gaps=a.gaps+1
 end
 a.first=a.first or t;a.last=t;a.count=a.count+1
end
local function target()
 if not fight or not UnitExists("target") then return end
 local id=npc(UnitGUID("target"))
 if not id then return end
 if not fight.npcs[tostring(id)] then
  local n=0;for _ in pairs(fight.npcs) do n=n+1 end
  if n<MAX_NPCS then fight.npcs[tostring(id)]={name=safe(UnitName("target")),first=math.floor((now()-fight.start)*10)/10} end
 end
 if UnitCanAttack and UnitCanAttack("player","target") and UnitHealth and UnitHealthMax then
  local max=UnitHealthMax("target")
  if max and max>0 then
   local pct=math.floor(UnitHealth("target")*100/max+0.5)
   local prev=lastTarget
   if not prev or prev.id~=id or math.abs(pct-prev.pct)>=10 then
    if #fight.health<80 then fight.health[#fight.health+1]={t=math.floor((now()-fight.start)*10)/10,npc=id,pct=pct} end
    lastTarget={id=id,pct=pct}
   end
  end
 end
end
local function combat(...)
 if not fight then return end
 local ev=select(2,...)
 if type(ev)~="string" then return end
 local sourceGUID,sourceName=select(3,...),select(4,...)
 local id=npc(sourceGUID)
 if not id then return end -- record creature-driven events, not player damage spam
 fight.eventCount=fight.eventCount+1
 local key=tostring(id)
 if not fight.npcs[key] then
  local n=0;for _ in pairs(fight.npcs) do n=n+1 end
  if n<MAX_NPCS then fight.npcs[key]={name=safe(sourceName),first=math.floor((now()-fight.start)*10)/10} end
 end
 -- Combat-log header differs across client builds; inspect header conservatively.
 local a6,a7=select(6,...),select(7,...)
 local header=(type(a6)=="number" and (type(a7)=="string" or a7==nil)) and 10 or 8
 local spell,spellName
 if ev:find("^SPELL_") or ev:find("^RANGE_") then
  local s,n=select(header+1,...),select(header+2,...)
  if type(s)=="number" then spell,spellName=s,n end
 end
 if ev=="SPELL_CAST_START" or ev=="SPELL_CAST_SUCCESS" or ev=="SPELL_AURA_APPLIED" or ev=="SPELL_AURA_REMOVED" or ev=="SPELL_AURA_APPLIED_DOSE" or ev=="SPELL_INTERRUPT" or ev=="SPELL_DISPEL" or ev=="SPELL_SUMMON" then
  ability(id,spell,ev,spellName)
  putEvent(ev,id,spell,spellName)
 elseif ev=="UNIT_DIED" or ev=="PARTY_KILL" then
  putEvent(ev,id,0,sourceName)
 end
end
f:SetScript("OnEvent",function(self,event,...)
 if event=="ADDON_LOADED" then
  if ...~="DBM-CoA-Observer" then return end
  DBMCoAObserverDB=DBMCoAObserverDB or {fights={}}
  db=DBMCoAObserverDB;db.fights=db.fights or {}
  checkZone();return
 end
 if not db then return end
 if event=="PLAYER_LOGOUT" then finish("logout");return end
 if event=="PLAYER_ENTERING_WORLD" or event=="ZONE_CHANGED_NEW_AREA" then checkZone();return end
 if event=="PLAYER_REGEN_DISABLED" then combatOn=true;begin();return end
 if event=="PLAYER_REGEN_ENABLED" then combatOn=false;finish("combat ended");return end
 if not fight then return end
 if event=="PLAYER_TARGET_CHANGED" then target()
 elseif event=="COMBAT_LOG_EVENT_UNFILTERED" then combat(...)
 elseif event=="CHAT_MSG_MONSTER_YELL" or event=="CHAT_MSG_MONSTER_EMOTE" or event=="CHAT_MSG_RAID_BOSS_EMOTE" or event=="CHAT_MSG_RAID_BOSS_WHISPER" then
  local msg,sender=...
  if #fight.emotes<40 then fight.emotes[#fight.emotes+1]={t=math.floor((now()-fight.start)*10)/10,event=event,sender=safe(sender),message=safe(msg)} end
 end
end)
f:SetScript("OnUpdate",function(self,dt)
 elapsed=elapsed+dt
 if elapsed<2 then return end
 elapsed=0
 if db then checkZone();target() end
end)
for _,event in ipairs({"ADDON_LOADED","PLAYER_LOGOUT","PLAYER_ENTERING_WORLD","ZONE_CHANGED_NEW_AREA","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED","PLAYER_TARGET_CHANGED","COMBAT_LOG_EVENT_UNFILTERED","CHAT_MSG_MONSTER_YELL","CHAT_MSG_MONSTER_EMOTE","CHAT_MSG_RAID_BOSS_EMOTE","CHAT_MSG_RAID_BOSS_WHISPER"}) do f:RegisterEvent(event) end
SLASH_DBMCOAOBS1="/dbmcoaobs"
SlashCmdList.DBMCOAOBS=function(s)
 if not db then return end
 local cmd=(s or ""):lower():match("^%s*(.-)%s*$")
 if cmd=="status" or cmd=="" then
  local a=0;if fight then for _ in pairs(fight.abilities) do a=a+1 end end
  if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("DBM-CoA Observer: instance="..tostring(active).." fight="..tostring(fight~=nil).." saved="..#db.fights.." currentAbilities="..a) end
 end
end
