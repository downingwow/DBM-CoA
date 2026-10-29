-- v3.6 experimental data-driven warnings; never loads remote Lua.
-- Existing DBM encounter modules remain untouched.
local f=CreateFrame("Frame")
local active={} -- per creature GUID and spell
local bars={}
-- Runtime observations are deliberately local to this session. Only real repeated
-- casts can establish a timer; archive references alone never start a timer.
local observed={}
local lastEvent={}
-- Persistent encounter categories: instance type -> instance -> difficulty -> NPC -> spell.
-- All estimates are sourced from actual casts; never seed predictions from the archive.
local function category(instType,inst,diff,nid,sid,name,who)
 local db=DBMCoALearnerDB
 if not db then return end
 db.encounterTimers24=db.encounterTimers24 or {raid={},party={}}
 local root=db.encounterTimers24[instType]
 if not root then return end
 root[inst]=root[inst] or {}
 local difficulty=tostring(diff or 0)
 root[inst][difficulty]=root[inst][difficulty] or {}
 local bosses=root[inst][difficulty]
 local npcKey=tostring(nid)
 bosses[npcKey]=bosses[npcKey] or {name=who or ("NPC "..npcKey),spells={}}
 local boss=bosses[npcKey]
 if who and who~="" then boss.name=who end
 local spellKey=tostring(sid)
 boss.spells[spellKey]=boss.spells[spellKey] or {name=name or ("Spell "..spellKey),samples={},casts=0}
 local spell=boss.spells[spellKey]
 if name and name~="" then spell.name=name end
 spell.casts=(spell.casts or 0)+1
 return spell
end
local function estimate(samples)
 if #samples<3 then return nil end
 local a={}
 for _,v in ipairs(samples) do if type(v)=="number" and v>=5 and v<=180 then a[#a+1]=v end end
 if #a<3 then return nil end
 table.sort(a)
 local median=a[math.floor((#a+1)/2)]
 local good={}
 for _,v in ipairs(a) do if math.abs(v-median)<=math.max(3,median*0.2) then good[#good+1]=v end end
 if #good<3 then return nil end
 local sum=0
 for _,v in ipairs(good) do sum=sum+v end
 local avg=sum/#good
 return avg,#good
end
local function learnInterval(nid,sid,inst,instType,diff,guid,now,name,who)
 local key=table.concat({instType,inst,diff,nid,sid},";")
 local rec=observed[key]
 if not rec then rec={lastByGuid={}};observed[key]=rec end
 local previous=rec.lastByGuid[guid]
 rec.lastByGuid[guid]=now
 local saved=category(instType,inst,diff,nid,sid,name,who)
 if not saved then return end
 if previous then
  local delta=now-previous
  if delta>=5 and delta<=180 then
   saved.samples[#saved.samples+1]=math.floor(delta*10+0.5)/10
   if #saved.samples>24 then table.remove(saved.samples,1) end
  end
 end
 local avg,count=estimate(saved.samples)
 saved.estimate=avg
 saved.confidence=count or 0
 return avg
end
local MAX_BARS=5
local function data() return DBMCoALearnerDB end
local function enabled()
 local d=data();return d and not d.disabled and not d.experimentalDisabled
end
local function npc(g)
 if type(g)~="string" then return nil end
 if g:sub(1,2)=="0x" then return tonumber(g:sub(9,12),16) end
 if g:find("^Creature%-") or g:find("^Vehicle%-") then return tonumber(g:match("%-(%d+)%-[0-9a-fA-F]+$")) end
end
local function currentInstance()
 local n,typ,diff=GetInstanceInfo()
 if typ~="party" and typ~="raid" then return nil end
 if type(n)~="string" or #n<3 then n=(GetRealZoneText and GetRealZoneText()) or "" end
 return n or "",diff or 0,typ
end
local function lookup(nid,sid,inst,diff)
 local d=data();if not d then return nil end
 local exact=table.concat({"S",inst,diff,nid,sid},";")
 local e=d.knowledge and d.knowledge[exact]
 if e then return e end
 -- Older clients sometimes stored blank/malformed instance names.
 -- Only use those for labels, never for timers.
 for _,v in pairs(d.knowledge or {}) do
  if v.kind=="S" and v.npc==nid and v.spell==sid then return v end
 end
end
local function prediction(nid,sid,inst,diff)
 local d=data();if not d then return end
 local k=table.concat({inst,diff,nid,sid},";")
 local t=d.timings and d.timings[k]
 -- Only trust new correctly keyed local observations. No old blank keys.
 if not t or (t.count or 0)<5 then return end
 local mean=t.sum/t.count/10
 local lo=t.min/10;local hi=t.max/10
 if mean<5 or mean>180 or hi-lo>math.max(4,mean*0.25) then return end
 return mean
end
local function warn(label,who)
 if RaidWarningFrame and RaidNotice_AddMessage and ChatTypeInfo and ChatTypeInfo.RAID_WARNING then
  RaidNotice_AddMessage(RaidWarningFrame,"[Learned] "..who..": "..label,ChatTypeInfo.RAID_WARNING)
 elseif DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00[DBM Learned]|r "..who..": "..label) end
end
local anchor=CreateFrame("Frame",nil,UIParent)
anchor:SetWidth(240);anchor:SetHeight(125);anchor:SetPoint("CENTER",UIParent,"CENTER",300,80)
local function bar(i)
 if bars[i] then return bars[i] end
 local b=CreateFrame("StatusBar",nil,anchor)
 b:SetWidth(220);b:SetHeight(16);b:SetPoint("TOP",anchor,"TOP",0,-(i-1)*24)
 b:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
 b:SetMinMaxValues(0,1)
 local bg=b:CreateTexture(nil,"BACKGROUND");bg:SetAllPoints(b);bg:SetTexture(0,0,0,0.65)
 local txt=b:CreateFontString(nil,"OVERLAY","GameFontNormalSmall");txt:SetPoint("CENTER",b,"CENTER");b.txt=txt
 b:Hide();bars[i]=b;return b
end
local function startBar(label,duration)
 if not enabled() then return end
 local now=GetTime()
 local chosen
 for i=1,MAX_BARS do local b=bar(i);if not b.untilTime or b.untilTime<=now then chosen=b;break end end
 if not chosen then return end
 chosen.duration=duration;chosen.untilTime=now+duration;chosen.label=label;chosen:Show()
end
local elapsed=0
f:SetScript("OnUpdate",function(self,dt)
 elapsed=elapsed+dt;if elapsed<0.1 then return end;elapsed=0
 local now=GetTime()
 for i=1,#bars do
  local b=bars[i]
  if b:IsShown() then
   if not enabled() or not b.untilTime or b.untilTime<=now then b:Hide()
   else local left=b.untilTime-now;b:SetValue(left/b.duration);b.txt:SetText(b.label.." - "..math.ceil(left).."s") end
  end
 end
end)
f:SetScript("OnEvent",function(self,event,...)
 if event=="PLAYER_ENTERING_WORLD" or event=="ZONE_CHANGED_NEW_AREA" then active={};observed={};lastEvent={};for i=1,#bars do bars[i]:Hide() end;return end
 if event=="PLAYER_REGEN_ENABLED" then active={};observed={};lastEvent={};for i=1,#bars do bars[i]:Hide() end;return end
 if event~="COMBAT_LOG_EVENT_UNFILTERED" or not enabled() then return end
 local inst,diff,instType=currentInstance();if not inst then return end
 local ev=select(2,...)
 if ev~="SPELL_CAST_START" and ev~="SPELL_CAST_SUCCESS" then return end
 local guid,who=select(3,...),select(4,...)
 local nid=npc(guid);if not nid then return end
 local a6,a7=select(6,...),select(7,...)
 local header=(type(a6)=="number" and (type(a7)=="string" or a7==nil)) and 10 or 8
 local sid,spell=select(header+1,...),select(header+2,...)
 if type(sid)~="number" or sid<=0 then return end
 local k=tostring(guid)..":"..sid
 local now=GetTime()
 local old=active[k]
 if old and now-old<3 then return end -- suppress CAST_START/CAST_SUCCESS double warning
 -- Some Ascension clients duplicate the same combat event. Suppress identical
 -- source+spell+event reports in a short window without losing real recasts.
 local eventKey=k..":"..ev
 if lastEvent[eventKey] and now-lastEvent[eventKey]<0.5 then return end
 lastEvent[eventKey]=now
 active[k]=now
 local e=lookup(nid,sid,inst,diff)
 -- Observed enemy cast is real; warn immediately even on the first sighting.
 -- Predicted bars still require five stable local timing samples.
 local name=(type(spell)=="string" and spell~="" and spell) or (e and e.name and e.name~="" and e.name) or ("Spell "..sid)
 -- Live cast notification, once per GUID+spell per 3 seconds.
 warn(name,who or ("NPC "..nid))
 local duration=nil
 -- Require at least three clean same-creature recast intervals before showing
 -- a session-derived prediction. No invented cast duration or first-pull timer.
 local sessionDuration=learnInterval(nid,sid,inst,instType,diff,tostring(guid),now,name,who)
 if sessionDuration then duration=sessionDuration end
 if duration then startBar((who or "Enemy")..": "..name.." (learned)",duration) end
end)
for _,e in ipairs({"COMBAT_LOG_EVENT_UNFILTERED","PLAYER_ENTERING_WORLD","ZONE_CHANGED_NEW_AREA","PLAYER_REGEN_ENABLED"}) do f:RegisterEvent(e) end

-- Raid-test inspection: /coatimings opens categorized learned timers, including Zul'Gurub.
local listFrame,listText
local function buildList()
 local db=DBMCoALearnerDB
 local data=db and db.encounterTimers24 or {}
 local lines={"DBM-CoA Learned Timers (observed only)","Raid / Dungeon -> Instance -> Difficulty -> NPC -> Spell"}
 local total=0
 for _,typeName in ipairs({"raid","party"}) do
  local root=data[typeName] or {}
  local instances={}
  for k in pairs(root) do instances[#instances+1]=k end
  table.sort(instances)
  for _,inst in ipairs(instances) do
   lines[#lines+1]=(typeName=="raid" and "[RAID] " or "[DUNGEON] ")..inst
   local diffs={}
   for k in pairs(root[inst]) do diffs[#diffs+1]=k end
   table.sort(diffs)
   for _,diff in ipairs(diffs) do
    for id,boss in pairs(root[inst][diff]) do
     for spellId,rec in pairs(boss.spells or {}) do
      total=total+1
      if #lines<250 then
       lines[#lines+1]="  Diff "..diff.." | "..(boss.name or id).." ("..id..") | "..(rec.name or spellId).." ["..spellId.."] "..(rec.estimate and (string.format("%.1fs",rec.estimate).." / "..(rec.confidence or 0).." intervals") or "learning")
      end
     end
    end
   end
  end
 end
 if total==0 then lines[#lines+1]="No categorized observations yet. Enter a dungeon or raid and fight enemies." end
 if total>245 then lines[#lines+1]="(additional records hidden)" end
 return table.concat(lines,"\n")
end
SLASH_COATIMINGS1="/coatimings"
SlashCmdList.COATIMINGS=function()
 if not listFrame then
  listFrame=CreateFrame("Frame","DBMCoALearnedTimersWindow",UIParent)
  listFrame:SetWidth(640);listFrame:SetHeight(430)
  listFrame:SetPoint("CENTER")
  listFrame:SetFrameStrata("DIALOG")
  listFrame:SetMovable(true);listFrame:EnableMouse(true)
  listFrame:RegisterForDrag("LeftButton")
  listFrame:SetScript("OnDragStart",function(self) self:StartMoving() end)
  listFrame:SetScript("OnDragStop",function(self) self:StopMovingOrSizing() end)
  local bg=listFrame:CreateTexture(nil,"BACKGROUND")
  bg:SetAllPoints(listFrame);bg:SetTexture(0,0,0,0.9)
  local close=CreateFrame("Button",nil,listFrame,"UIPanelCloseButton")
  close:SetPoint("TOPRIGHT",0,0)
  local scroll=CreateFrame("ScrollFrame",nil,listFrame,"UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT",12,-32);scroll:SetPoint("BOTTOMRIGHT",-34,12)
  listText=CreateFrame("EditBox",nil,scroll)
  listText:SetMultiLine(true);listText:SetAutoFocus(false)
  listText:SetFontObject(GameFontHighlightSmall)
  listText:SetWidth(565);listText:SetHeight(12000)
  listText:EnableMouse(false)
  scroll:SetScrollChild(listText)
 end
 listText:SetText(buildList())
 listFrame:Show()
end

-- Inspect automatic dungeon and raid learning without changing saved preferences.
SLASH_COALEARNING1="/coalearning"
SlashCmdList.COALEARNING=function()
 local d=DBMCoALearnerDB or {}
 local name,kind,difficulty=GetInstanceInfo()
 local scope=(kind=="party" and "Dungeon") or (kind=="raid" and "Raid") or "Outside instance"
 local state=(d.disabled or d.experimentalDisabled) and "OFF" or "ON"
 if DEFAULT_CHAT_FRAME then
  DEFAULT_CHAT_FRAME:AddMessage("DBM-CoA automatic learning: "..state.." | "..scope.." | "..tostring(name or "Unknown").." | difficulty "..tostring(difficulty or 0))
  DEFAULT_CHAT_FRAME:AddMessage("Saved encounter categories: /coatimings | Toggle: /dbmcoa experimental on/off")
 end
end
