-- v3.6 experimental data-driven warnings; never loads remote Lua.
-- Existing DBM encounter modules remain untouched.
local f=CreateFrame("Frame")
local active={} -- per creature GUID and spell
local bars={}
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
 return n or "",diff or 0
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
 if event=="PLAYER_ENTERING_WORLD" or event=="ZONE_CHANGED_NEW_AREA" then active={};for i=1,#bars do bars[i]:Hide() end;return end
 if event=="PLAYER_REGEN_ENABLED" then active={};for i=1,#bars do bars[i]:Hide() end;return end
 if event~="COMBAT_LOG_EVENT_UNFILTERED" or not enabled() then return end
 local inst,diff=currentInstance();if not inst then return end
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
 active[k]=now
 local e=lookup(nid,sid,inst,diff)
 -- Observed enemy cast is real; warn immediately even on the first sighting.
 -- Predicted bars still require five stable local timing samples.
 local name=(type(spell)=="string" and spell~="" and spell) or (e and e.name and e.name~="" and e.name) or ("Spell "..sid)
 -- Live cast notification, once per GUID+spell per 3 seconds.
 warn(name,who or ("NPC "..nid))
 local duration=prediction(nid,sid,inst,diff)
 if duration then startBar(name.." (experimental)",duration) end
end)
for _,e in ipairs({"COMBAT_LOG_EVENT_UNFILTERED","PLAYER_ENTERING_WORLD","ZONE_CHANGED_NEW_AREA","PLAYER_REGEN_ENABLED"}) do f:RegisterEvent(e) end
