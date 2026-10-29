-- DBM-CoA AutoLearner v3.4: relay and aggregated ability timing synchronization.
local f=CreateFrame("Frame")
local db, session, recording, elapsed=nil,nil,false,0
local MAX_EVENTS,MAX_SESSIONS=3500,15
local syncQueue, seen, peers, sent, received, discovered = {}, {}, {}, 0, 0, 0
local syncClock, syncSeq = 0, 0
local SEND_INTERVAL=0.75 -- Conservative cap: <= 1.34 messages/sec; batch discoveries where possible.
local retryDelay, retryWait = 1, 0
local controlQueue = {} -- Ping/pong use the same rate limiter as discoveries.
local MAX_CONTROL_QUEUE=12
local PREFIX="DCOAL31" -- keep v3.3 discovery protocol compatible
local MAX_QUEUE=20000
local batchSent=0
local backfillDone=false
local timingQueue, timingQueued, relayQueued = {}, {}, {}
local timingSent, timingReceived, timingDuplicates, relaySent = 0,0,0,0
local lastAbility = {}
local MAX_TIMING_QUEUE=4000
local MAX_INTERVAL=600
local RELAY_LIMIT=2
local lastSyncError="none"
local pings=0
local rawReceived, duplicates, rejected, discoverySent, pingSent = 0,0,0,0,0
local lastReceive="none"
local peerCount=0
local statusFrame, statusText
local known = {}
-- Channel setup is optional and separate from recording. This release does not transmit data.
local SYNC_CHANNEL="BBLC25C" -- shared with LootCollector; do not own or alter membership
local channelElapsed=0
local stableSeconds=0
local previousSignature=nil
local joinAttempted=false
local function channelSignature()
 if type(GetChannelName)~="function" then return nil end
 -- Check channels by number, not just their names. Do not join until stable.
 local parts={}
 for i=1,10 do
  local id,name=GetChannelName(i)
  if type(id)=="number" and id>0 and type(name)=="string" then
   parts[#parts+1]=tostring(i)..":"..name
  end
 end
 return table.concat(parts,"|")
end
local function hideSyncChannel() end
-- Passive channel consumer: LootCollector owns BBLC25C. Never join, leave,
-- reorder, or hide its chat channel from DBM. Safe even if LootCollector is disabled.
local function ensureSyncChannel() end
local function verifyChannels() end
local function say(s) if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffDBM-CoA|r "..s) end end
local function clock() return GetTime() end
-- CoA instance aliases are observed, not blindly trusted. Map IDs are authoritative
-- only after repeated in-client observations; never overwrite a canonical label.
local COA_NAMES = {
 "Deadmines", "Wailing Caverns", "Shadowfang Keep", "Blackfathom Deeps", "The Stockade", "Gnomeregan", "Razorfen Kraul", "Scarlet Monastery", "Razorfen Downs", "Uldaman", "Zul'Farrak", "Maraudon", "Sunken Temple", "Blackrock Depths", "Lower Blackrock Spire", "Upper Blackrock Spire", "Scholomance", "Stratholme",
 "Molten Core", "Onyxia's Lair", "Zul'Gurub", "Blackwing Lair", "Ruins of Ahn'Qiraj", "Temple of Ahn'Qiraj", "Naxxramas",
 "Shadowbone Depths", "Blackrock Caverns", "Road to the Other Side", "Vaults of Inquisition", "Manastorm", "The Radiant Spring", "Stormwind Sewers & Deeprun Tram Maintenance Station", "Orgrimmar Underbelly", "Fading Island Instance", "The Hardluck Sub-Instance", "Dawnrise Citadel / Azzar Raid Prototype"
}
local COA_EVENTS = { [23682]="Headless Horseman", [23775]="Head of the Horseman", [25740]="Ahune", [23872]="Coren Direbrew", [36272]="Apothecary Hummel", [36565]="Apothecary Baxter", [36296]="Apothecary Frye" }
local function cleanInstanceName(n)
 if type(n)~="string" then return "" end
 n=n:gsub("^%s+",""):gsub("%s+$","")
 if #n<3 then return "" end
 return n
end
local function observeInstance(z)
 if not db or not z or (z.type~="party" and z.type~="raid") then return end
 db.instanceNames=db.instanceNames or {}
 local key=tostring(z.map or 0)..":"..tostring(z.type or "")
 local r=db.instanceNames[key] or {names={},canonical=nil}
 db.instanceNames[key]=r
 local n=cleanInstanceName(z.instance)
 if n=="" then return end
 r.names[n]=(r.names[n] or 0)+1
 -- Keep all observed names. A single bad report must not rename the instance.
 local best,bestCount=nil,0
 for name,count in pairs(r.names) do
  if count>bestCount then best,bestCount=name,count end
 end
 if bestCount>=3 and (not r.canonical or (r.names[r.canonical] or 0)<bestCount) then r.canonical=best end
end
local function zone()
 local n,k,d=GetInstanceInfo()
 local zonename=(GetRealZoneText and GetRealZoneText()) or ""
 if type(n)~="string" or #cleanInstanceName(n)==0 then n=zonename end
 n=cleanInstanceName(n)
 return {zone=zonename,map=(GetCurrentMapAreaID and GetCurrentMapAreaID()) or 0,instance=n or "",type=k or "",difficulty=d or 0}
end
local function eligible(z)
 if z.type=="party" or z.type=="raid" or z.type=="pvp" or z.type=="arena" then return true end
 if UnitExists and UnitExists("target") and UnitGUID then
  local g=UnitGUID("target")
  local id=type(g)=="string" and (g:sub(1,2)=="0x" and tonumber(g:sub(9,12),16) or tonumber(g:match("%-(%d+)%-[0-9a-fA-F]+$")))
  if id and COA_EVENTS[id] then z.instance="World Events";z.type="coa_event";z.eventBoss=id;return true end
 end
 return false
end
local function npc(g)
 if type(g)~="string" then return nil end
 if g:sub(1,2)=="0x" then return tonumber(g:sub(9,12),16) end
 if g:find("^Creature%-") or g:find("^Vehicle%-") then return tonumber(g:match("%-(%d+)%-[0-9a-fA-F]+$")) end
end
local function save()
 if not recording or not session then return end
 session.duration=math.floor((clock()-session.started)*100+0.5)/100
 session.started=nil
 if #session.events>0 or next(session.samples) then
  table.insert(db.sessions,session)
  while #db.sessions>MAX_SESSIONS do table.remove(db.sessions,1) end
 end
 recording=false;session=nil
end
local function start(z)
 if not db or db.disabled or not eligible(z) then return end
 session=z;session.date=date("%Y-%m-%d %H:%M:%S");session.started=clock();session.events={};session.samples={};session.dropped=0;lastAbility={} 
 recording=true
end
local function refresh()
 if not db then return end
 local z=zone()
 observeInstance(z)
 if recording then
  if session.type=="coa_event" and z.type=="none" and UnitAffectingCombat and UnitAffectingCombat("player") then z.type="coa_event";z.instance="World Events" end
  if not eligible(z) and z.type~="coa_event" or z.type~=session.type or z.instance~=session.instance or (z.map~=0 and session.map~=0 and z.map~=session.map) then save() end
 end
 if not recording then start(z) end
end
local function safeField(v)
 v=tostring(v or ""):gsub("[|;\r\n%z]", " "):gsub("[^%w %-_%.%,]", " ")
 return v:sub(1,55)
end
local function remember(kind, instance, difficulty, npcId, spellId, label)
 if (not label or label=="") and CoAArchiveRefs then label=(kind=="N" and CoAArchiveRefs.npcs[npcId]) or (kind=="S" and CoAArchiveRefs.spells[spellId]) end
 if not db or db.disabled or not npcId or npcId<=0 then return end
 local key=table.concat({kind,safeField(instance),tostring(difficulty or 0),tostring(npcId),tostring(spellId or 0)}, ";")
 if known[key] then return end
 known[key]=true;discovered=discovered+1
 db.knowledge=db.knowledge or {}
 db.knowledge[key]={kind=kind,instance=safeField(instance),difficulty=difficulty or 0,npc=npcId,spell=spellId or 0,name=safeField(label),seen=date("%Y-%m-%d %H:%M")}
 if #syncQueue<MAX_QUEUE then syncQueue[#syncQueue+1]=key end
end
-- ASCII-only channel protocol, intentionally separate from LootCollector BBLC25C.
-- Prefix and payload are plain printable text; never embed WoW escape/control bytes.
local function syncSend(payload)
 if not db or db.channelDisabled or db.channelUnsafe or db.sharingDisabled then return false end
 local id=type(GetChannelName)=="function" and GetChannelName(SYNC_CHANNEL) or 0
 if type(id)~="number" or id<=0 or type(SendChatMessage)~="function" then return false end
 local msg=PREFIX..";"..payload
 if #msg>240 or msg:find("[^%w ;%-_%.|]") then lastSyncError="invalid payload";return false end
 local ok,err=pcall(SendChatMessage,msg,"CHANNEL",nil,id)
 if ok then sent=sent+1;if payload:sub(1,2)=="D;" then discoverySent=discoverySent+1 elseif payload:sub(1,2)=="T;" then timingSent=timingSent+1 else pingSent=pingSent+1 end;lastSyncError="none" else lastSyncError=tostring(err):sub(1,80) end
 return ok
end
local function queueControl(payload)
 if #controlQueue >= MAX_CONTROL_QUEUE then return false end
 controlQueue[#controlQueue+1]=payload
 return true
end
local function queueBackfill()
 if not db or not db.knowledge then return end
 local queued={}
 for _,k in ipairs(syncQueue) do queued[k]=true end
 local n=0
 for k,entry in pairs(db.knowledge) do
  if not queued[k] and #syncQueue<MAX_QUEUE then
   syncQueue[#syncQueue+1]=k;queued[k]=true;n=n+1
  end
 end
 backfillDone=true
end

-- Timing data is keyed to NPC, spell, instance and difficulty. Store bounded
-- aggregated observations, never raw remote samples or player identifiers.
local function timingKey(inst,diff,nid,sid)
 return table.concat({safeField(inst),tostring(diff or 0),tostring(nid),tostring(sid)}, ";")
end
local function enqueueTiming(key)
 if timingQueued[key] or #timingQueue>=MAX_TIMING_QUEUE then return end
 timingQueued[key]=true;timingQueue[#timingQueue+1]=key
end
local function observeTiming(inst,diff,nid,sid)
 if not db or not nid or not sid or sid<=0 then return end
 local key=timingKey(inst,diff,nid,sid)
 local now=clock()
 local prev=lastAbility[key]
 lastAbility[key]=now
 if not prev then return end
 local delta=now-prev
 if delta<3 or delta>MAX_INTERVAL then return end
 db.timings=db.timings or {}
 local t=db.timings[key]
 if not t then t={instance=safeField(inst),difficulty=diff or 0,npc=nid,spell=sid,count=0,sum=0,min=600,max=0};db.timings[key]=t end
 -- Cap locally recorded observations to avoid unlimited data growth.
 if t.count>=10000 then return end
 local rounded=math.floor(delta*10+0.5)
 t.count=t.count+1;t.sum=t.sum+rounded
 t.min=math.min(t.min,rounded);t.max=math.max(t.max,rounded)
 enqueueTiming(key)
end
local function parseTiming(payload)
 local inst,diff,nid,sid,count,total,lo,hi=payload:match("^T;([^;]*);(%d+);(%d+);(%d+);(%d+);(%d+);(%d+);(%d+)$")
 if not inst or #inst>55 then return nil end
 diff=tonumber(diff);nid=tonumber(nid);sid=tonumber(sid);count=tonumber(count);total=tonumber(total);lo=tonumber(lo);hi=tonumber(hi)
 if diff>100 or nid<1 or nid>100000000 or sid<1 or sid>100000000 or count<1 or count>10000 or lo<30 or hi>6000 or lo>hi or total<count*lo or total>count*hi then return nil end
 return timingKey(inst,diff,nid,sid),{instance=inst,difficulty=diff,npc=nid,spell=sid,count=count,sum=total,min=lo,max=hi}
end

local function receive(msg,sender)
 -- v3.6 batch envelope: old clients ignore B; new clients unpack each
 -- independently validated v3.4 discovery, without executing remote code.
 if type(msg)=="string" and msg:sub(1,#PREFIX+3)==PREFIX..";B;" then
  if #msg>240 then rejected=rejected+1;return end
  local body=msg:sub(#PREFIX+4)
  local parts=0
  for part in (body.."|"):gmatch("(.-)|") do
   parts=parts+1
   if parts>6 or part=="" or part:sub(1,2)~="D;" then rejected=rejected+1;return end
   receive(PREFIX..";"..part,sender)
  end
  return
 end
 if type(msg)~="string" or msg:sub(1,#PREFIX+1)~=PREFIX..";" then return end
 rawReceived=rawReceived+1;lastReceive="message from "..tostring(sender or "?"):sub(1,40)
 peers[sender or "?"]=clock()
 if #msg>240 then rejected=rejected+1;lastReceive="oversized message";return end
 local payload=msg:sub(#PREFIX+2)
 if payload:sub(1,2)=="H;" then
  peers[sender or "?"]=clock()
  if payload=="H;PING" then queueControl("H;PONG") end
  if payload=="H;PONG" then pings=pings+1 end
  return
 end
 if payload:sub(1,2)=="T;" then
  local key,t=parseTiming(payload)
  if not key then rejected=rejected+1;lastReceive="invalid timing format";return end
  db.remoteTimings=db.remoteTimings or {}
  db.remoteTimingSources=db.remoteTimingSources or {}
  local source=tostring(sender or "?")
  local bySource=db.remoteTimingSources[key] or {}
  db.remoteTimingSources[key]=bySource
  -- Each sender contributes only the latest cumulative aggregate. Never add
  -- repeated broadcasts as new samples; this prevents double counting.
  local old=bySource[source]
  if old and old.count>=t.count then timingDuplicates=timingDuplicates+1;return end
  bySource[source]=t
  timingReceived=timingReceived+1
  -- Cap source memory per ability; local observations are stored separately.
  local count=0;for _ in pairs(bySource) do count=count+1 end
  if count>12 then bySource[source]=nil end
  return
 end
 if payload:sub(1,2)~="D;" then return end
 local kind,inst,diff,nid,sid,label=payload:match("^D;([NS]);([^;]*);(%d+);(%d+);(%d+);([^;]*)$")
 if not kind or #inst>55 or #label>55 then rejected=rejected+1;lastReceive="invalid discovery format";return end
 nid=tonumber(nid);sid=tonumber(sid);diff=tonumber(diff)
 if not nid or nid<1 or nid>100000000 or not sid or sid>100000000 or not diff or diff>100 then rejected=rejected+1;lastReceive="invalid discovery values";return end
 local key=table.concat({kind,inst,tostring(diff),tostring(nid),tostring(sid)},";")
 if known[key] then duplicates=duplicates+1;return end
 known[key]=true;received=received+1
 db.knowledge=db.knowledge or {}
 db.knowledge[key]={kind=kind,instance=inst,difficulty=diff,npc=nid,spell=sid,name=label,seen=date("%Y-%m-%d %H:%M"),remote=true}
 -- Relay newly imported discoveries once; never relay a record already known.
 if #syncQueue<MAX_QUEUE and not relayQueued[key] then
  relayQueued[key]=true;syncQueue[#syncQueue+1]=key
 end
end
-- CHAT_MSG_CHANNEL differs between client builds. Accept the channel's base
-- name, display name, or its local numeric index, but never unrelated channels.
local function isSyncChannel(displayName, channelIndex, baseName)
 local function matches(v)
  if type(v)~="string" then return false end
  v=v:gsub("^%s*%d+%.%s*",""):gsub("^%s+",""):gsub("%s+$","")
  return v:lower()==SYNC_CHANNEL:lower()
 end
 if matches(displayName) or matches(baseName) then return true end
 local current=type(GetChannelName)=="function" and GetChannelName(SYNC_CHANNEL) or 0
 return type(current)=="number" and current>0 and tonumber(channelIndex)==current
end
local function channelFilter(self,event,msg,sender,language,displayName,target,flags,zoneId,channelIndex,baseName)
 if type(msg)=="string" and msg:sub(1,#PREFIX+1)==PREFIX..";" and isSyncChannel(displayName,channelIndex,baseName) then return true end
 return false
end
if type(ChatFrame_AddMessageEventFilter)=="function" then ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL",channelFilter) end
local function activePeers()
 local count=0
 for name,t in pairs(peers) do if clock()-t<180 then count=count+1 else peers[name]=nil end end
 return count
end
local function updateStatus()
 if not statusText then return end
 local z=zone()
 local ch=type(GetChannelName)=="function" and GetChannelName(SYNC_CHANNEL) or 0
 local n=0;for _ in pairs(db and db.knowledge or {}) do n=n+1 end
 local a=db and db.archiveSmart21 or {}
 local archiveStatus=(db and db.archiveSharingDisabled) and "Paused" or ((ch>0 and db and not db.sharingDisabled and not db.channelDisabled) and "Smart Sync" or "Offline")
 local lines={
  "DBM-CoA Learner",
  (recording and "Recording" or "Idle").." | Events: "..(session and #session.events or 0),
  "Discoveries: "..n.." | Received: "..received,
  "Sync: "..(ch>0 and not db.sharingDisabled and "Shared channel available" or "Offline").." | Sent: "..sent.." | Queue: "..#syncQueue,
  "Peers (3m): "..activePeers().." | Raw: "..rawReceived.." | Dup: "..duplicates.." | Bad: "..rejected,
  "Timing sent: "..timingSent.." | Imported: "..timingReceived,
  "Archive: "..archiveStatus.." | Sent: "..(a.sent or 0).." | New: "..(a.received or 0),
  "Duplicates: "..(a.duplicates or 0).." | Conflicts: "..(a.conflicts or 0).." | Requests: "..(a.requests or 0)
 }
 statusText:SetText(table.concat(lines,string.char(10)))
end
-- Optional UI skin: no dependency on ElvUI, DragonUI, or third-party APIs.
-- Uses ElvUI's skinning helpers only when present and safely callable.
local function applyOptionalUISkin(frame, closeButton, background)
 if not frame then return end
 local elv=type(ElvUI)=="table" and ElvUI[1] or nil
 if type(elv)~="table" then return end
 if frame.coaElvUISkinned then return end
 frame.coaElvUISkinned=true
 local ok=false
 if type(frame.CreateBackdrop)=="function" then
  ok=pcall(frame.CreateBackdrop,frame,"Transparent")
 end
 if ok then
  if background then background:Hide() end
 elseif type(frame.SetTemplate)=="function" then
  ok=pcall(frame.SetTemplate,frame,"Transparent")
  if ok and background then background:Hide() end
 end
 if closeButton and type(closeButton.SetTemplate)=="function" then
  pcall(closeButton.SetTemplate,closeButton,"Default")
 end
end

local function makeStatus()
 if statusFrame then return end
 statusFrame=CreateFrame("Frame","DBMCoALearnerStatus",UIParent)
 local width=(db and tonumber(db.statusWidth)) or 405
 local height=(db and tonumber(db.statusHeight)) or 165
 width=math.max(320,math.min(850,width))
 height=math.max(155,math.min(500,height))
 statusFrame:SetWidth(width);statusFrame:SetHeight(height)
 statusFrame:SetPoint("CENTER",UIParent,"CENTER",0,180)
 statusFrame:SetFrameStrata("MEDIUM")
 statusFrame:SetResizable(true)
 statusFrame:SetMinResize(320,155)
 statusFrame:SetMaxResize(850,500)
 local bg=statusFrame:CreateTexture(nil,"BACKGROUND")
 bg:SetAllPoints(statusFrame);bg:SetTexture(0,0,0,0.72)
 statusText=statusFrame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
 statusText:SetPoint("TOPLEFT",statusFrame,"TOPLEFT",8,-8)
 statusText:SetPoint("BOTTOMRIGHT",statusFrame,"BOTTOMRIGHT",-18,10)
 statusText:SetJustifyH("LEFT");statusText:SetJustifyV("TOP")
 statusFrame:EnableMouse(true);statusFrame:SetMovable(true)
 statusFrame:RegisterForDrag("LeftButton")
 statusFrame:SetScript("OnDragStart",function(self) self:StartMoving() end)
 statusFrame:SetScript("OnDragStop",function(self) self:StopMovingOrSizing() end)
 local close=CreateFrame("Button",nil,statusFrame,"UIPanelCloseButton")
 close:SetWidth(22);close:SetHeight(22)
 close:SetPoint("TOPRIGHT",statusFrame,"TOPRIGHT",0,0)
 close:SetScript("OnClick",function() if db then db.hideStatus=true end;statusFrame:Hide() end)
 -- Native 3.3.5a-compatible bottom-right sizing grip (no DragonUI dependency).
 local grip=CreateFrame("Button",nil,statusFrame)
 grip:SetWidth(18);grip:SetHeight(18)
 grip:SetPoint("BOTTOMRIGHT",statusFrame,"BOTTOMRIGHT",-2,2)
 grip:SetFrameLevel(statusFrame:GetFrameLevel()+5)
 grip:EnableMouse(true)
 local texture=grip:CreateTexture(nil,"OVERLAY")
 texture:SetAllPoints(grip)
 texture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
 grip:SetNormalTexture(texture)
 grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
 grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
 grip:SetScript("OnMouseDown",function(self,button)
  if button=="LeftButton" then statusFrame:StartSizing("BOTTOMRIGHT") end
 end)
 grip:SetScript("OnMouseUp",function(self,button)
  if button=="LeftButton" then
   statusFrame:StopMovingOrSizing()
   if db then db.statusWidth=math.floor(statusFrame:GetWidth()+0.5);db.statusHeight=math.floor(statusFrame:GetHeight()+0.5) end
  end
 end)
 applyOptionalUISkin(statusFrame,close,bg)
 if db and db.hideStatus then statusFrame:Hide() end
 updateStatus()
end

local function add(ev,sg,sn,dg,dn,spell,name,extra)
 if not recording then return end
 if #session.events>=MAX_EVENTS then session.dropped=session.dropped+1;return end
 if ev=="SPELL_CAST_START" or ev=="SPELL_CAST_SUCCESS" or ev=="SPELL_AURA_APPLIED" then
  local id=npc(sg)
  if id then
   remember("S",session.instance,session.difficulty,id,spell,name or sn)
   -- Count a cast once, not both CAST_START and CAST_SUCCESS.
   if spell and (ev=="SPELL_CAST_START" or ev=="SPELL_CAST_SUCCESS") then
    local castKey=tostring(id)..":"..tostring(spell)
    if ev=="SPELL_CAST_START" then
     session.castStarts=session.castStarts or {};session.castStarts[castKey]=clock()
     observeTiming(session.instance,session.difficulty,id,spell)
    elseif not session.castStarts or not session.castStarts[castKey] or clock()-session.castStarts[castKey]>10 then
     observeTiming(session.instance,session.difficulty,id,spell)
    end
   end
  end
 end
 session.events[#session.events+1]={t=math.floor((clock()-session.started)*100+0.5)/100,e=ev,src=npc(sg),sn=sn,dst=npc(dg),dn=dn,spell=spell,name=name,extra=extra}
end
local function target()
 if not recording or not UnitExists("target") then return end
 local id=npc(UnitGUID("target"))
 if id then session.samples[tostring(id)]=UnitName("target") or "unknown";remember("N",session.instance,session.difficulty,id,0,UnitName("target")) end
end
local function combat(...)
 local ev=select(2,...)
 if type(ev)~="string" then return end
 if ev~="SPELL_CAST_START" and ev~="SPELL_CAST_SUCCESS" and ev~="SPELL_AURA_APPLIED" and ev~="SPELL_AURA_REMOVED" and ev~="SPELL_AURA_APPLIED_DOSE" and ev~="SPELL_SUMMON" and ev~="UNIT_DIED" and ev~="PARTY_KILL" and ev~="SPELL_INTERRUPT" then return end
 local sg,sn,dg,dn,spell,name
 sg,sn=select(3,...),select(4,...)
 -- Legacy header: 8 fields; with sourceRaidFlags and destRaidFlags: 10 fields.
 local a6,a7=select(6,...),select(7,...)
 local header=8
 if type(a6)=="number" and (type(a7)=="string" or a7==nil) then header=10;dg,dn=select(7,...),select(8,...)
 else dg,dn=a6,a7 end
 if ev:find("^SPELL_") then
  local v1,v2=select(header+1,...),select(header+2,...)
  if type(v1)=="number" then spell,name=v1,v2 end
 end
 add(ev,sg,sn,dg,dn,spell,name)
end
f:SetScript("OnEvent",function(self,event,...)
 if event=="ADDON_LOADED" then
  if ...~="DBM-CoA-Learner" then return end
  DBMCoALearnerDB=DBMCoALearnerDB or {}
  db=DBMCoALearnerDB;db.sessions=db.sessions or {};db.knowledge=db.knowledge or {};db.timings=db.timings or {};db.remoteTimingSources=db.remoteTimingSources or {}
  -- Auto-learning is ON for both party (dungeons) and raid instances by default.
  -- Preserve explicit opt-out from previous releases.
  if db.experimentalDisabled==nil then db.experimentalDisabled=false end
  for k in pairs(db.knowledge) do known[k]=true end
  backfillDone=false
  makeStatus()
  -- Preserve old recordings; default to automatic operation.
  refresh();return
 end
 if not db then return end
 if event=="PLAYER_LOGOUT" then save();return end
 if event=="CHAT_MSG_CHANNEL" then
  local msg,sender,language,channelString,target,flags,zoneId,channelIndex,baseName=...
  if isSyncChannel(channelString,channelIndex,baseName) then receive(msg,sender) end
  return
 end
 if event=="PLAYER_ENTERING_WORLD" or event=="ZONE_CHANGED_NEW_AREA" then refresh();return end
 if event=="CHANNEL_UI_UPDATE" or event=="UPDATE_CHAT_WINDOWS" or event=="CHAT_MSG_CHANNEL_NOTICE" then hideSyncChannel();return end
 if not recording then return end
 if event=="PLAYER_TARGET_CHANGED" then refresh();target()
 elseif event=="COMBAT_LOG_EVENT_UNFILTERED" then combat(...)
 elseif event=="PLAYER_REGEN_DISABLED" or event=="PLAYER_REGEN_ENABLED" then add(event)
 elseif event=="CHAT_MSG_MONSTER_YELL" or event=="CHAT_MSG_MONSTER_EMOTE" or event=="CHAT_MSG_RAID_BOSS_EMOTE" then local msg,sender=...;add(event,nil,sender,nil,nil,nil,nil,msg) end
end)
f:SetScript("OnUpdate",function(self,dt)
 -- Keep recording/UI/channel maintenance separate from the outgoing rate limiter.
 elapsed=elapsed+dt
 if elapsed>=2 then
  local delta=elapsed;elapsed=0
  if db then refresh() end
  updateStatus()
  local sig=channelSignature()
  if sig and sig==previousSignature then stableSeconds=stableSeconds+delta else stableSeconds=0;previousSignature=sig end
  channelElapsed=channelElapsed+delta
  if channelElapsed>=10 then
   channelElapsed=0
   if db and db.channelBefore then verifyChannels() end
   ensureSyncChannel()
  end
 end
 if not db or db.sharingDisabled or db.channelDisabled or db.channelUnsafe then return end
 syncClock=syncClock+dt
 if retryWait>0 then retryWait=math.max(0,retryWait-dt) end
 if syncClock<SEND_INTERVAL or retryWait>0 then return end
 -- Consume one time slot even on failure: never send in a rapid burst.
 syncClock=0
 local id=type(GetChannelName)=="function" and GetChannelName(SYNC_CHANNEL) or 0
 if type(id)~="number" or id<=0 then return end
 if not backfillDone then
  -- One-time, rate-limited broadcast of saved, observed discoveries on upgrade.
  -- Name-only historical reference IDs are never presented as observed mechanics.
  if db.lastBroadcastBuild~="3.15" then
   queueBackfill()
   db.lastBroadcastBuild="3.15"
  else backfillDone=true end
  for k in pairs(db.timings or {}) do enqueueTiming(k) end
 end
 local payload,kind,key,batchKeys
 if #controlQueue>0 then
  payload=controlQueue[1];kind="control"
 elseif #syncQueue>0 then
  key=syncQueue[1]
  local entry=db.knowledge and db.knowledge[key]
  if not entry then table.remove(syncQueue,1);return end
  payload=table.concat({"D",entry.kind,entry.instance,entry.difficulty,entry.npc,entry.spell,entry.name},";")
  kind="discovery"
  if not db.fastSyncDisabled then
   batchKeys={key}
   local parts={payload}
   local i=2
   while i<=#syncQueue and #batchKeys<4 do
    local k=syncQueue[i]
    local e=db.knowledge and db.knowledge[k]
    if e then
     local part=table.concat({"D",e.kind,e.instance,e.difficulty,e.npc,e.spell,e.name},";")
     local candidate="B;"..table.concat(parts,"|").."|"..part
     if #PREFIX+1+#candidate>235 then break end
     parts[#parts+1]=part;batchKeys[#batchKeys+1]=k
    end
    i=i+1
   end
   if #batchKeys>1 then payload="B;"..table.concat(parts,"|");kind="batch" end
  end
 elseif #timingQueue>0 then
  key=timingQueue[1]
  local t=db.timings and db.timings[key]
  if not t then timingQueued[key]=nil;table.remove(timingQueue,1);return end
  payload=table.concat({"T",t.instance,t.difficulty,t.npc,t.spell,t.count,t.sum,t.min,t.max},";")
  kind="timing"
 else
  -- Low-frequency presence heartbeat, not an endless discovery rebroadcast.
  syncSeq=syncSeq+1
  if syncSeq>=60 then syncSeq=0;payload="H;1";kind="heartbeat" end
 end
 if not payload then return end
 if syncSend(payload) then
  retryDelay=1;retryWait=0
  if kind=="control" then table.remove(controlQueue,1)
  elseif kind=="discovery" then
   if relayQueued[key] then relaySent=relaySent+1;relayQueued[key]=nil end
   table.remove(syncQueue,1)
  elseif kind=="batch" then
   batchSent=batchSent+1
   for i=1,#batchKeys do
    local k=batchKeys[i]
    if relayQueued[k] then relaySent=relaySent+1;relayQueued[k]=nil end
    table.remove(syncQueue,1)
   end
  elseif kind=="timing" then timingQueued[key]=nil;table.remove(timingQueue,1) end
 else
  -- Preserve the unsent record and retry with capped exponential backoff.
  retryWait=retryDelay
  retryDelay=math.min(retryDelay*2,60)
 end
end)
for _,e in ipairs({"ADDON_LOADED","PLAYER_ENTERING_WORLD","ZONE_CHANGED_NEW_AREA","PLAYER_LOGOUT","COMBAT_LOG_EVENT_UNFILTERED","PLAYER_TARGET_CHANGED","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED","CHAT_MSG_MONSTER_YELL","CHAT_MSG_MONSTER_EMOTE","CHAT_MSG_RAID_BOSS_EMOTE","CHANNEL_UI_UPDATE","UPDATE_CHAT_WINDOWS","CHAT_MSG_CHANNEL_NOTICE","CHAT_MSG_CHANNEL"}) do f:RegisterEvent(e) end
SLASH_DBMCOA1="/dbmcoa"
SlashCmdList.DBMCOA=function(s)
 s=(s or ""):lower():match("^%s*(.-)%s*$")
 if not db then return end
 if s=="options" then if InterfaceOptionsFrame_OpenToCategory and _G.DBMCoAOptionsPanel then InterfaceOptionsFrame_OpenToCategory(_G.DBMCoAOptionsPanel);InterfaceOptionsFrame_OpenToCategory(_G.DBMCoAOptionsPanel) else say("Options unavailable on this client") end
 elseif s=="status" then local z=zone();say("Auto="..tostring(not db.disabled).." recording="..tostring(recording).." instance="..z.instance.." type="..z.type.." saved="..#db.sessions.." sent="..sent.." received="..received.." pending="..#syncQueue.." controlPending="..#controlQueue.." retryWait="..math.floor(retryWait+0.5).." pongs="..pings.." lastError="..lastSyncError.." channel="..tostring(type(GetChannelName)=="function" and GetChannelName(SYNC_CHANNEL) or "unsupported").." raw="..rawReceived.." duplicates="..duplicates.." rejected="..rejected.." discoverySent="..discoverySent.." peers3m="..activePeers().." timingSent="..timingSent.." timingReceived="..timingReceived.." timingDuplicates="..timingDuplicates.." timingPending="..#timingQueue.." batches="..batchSent.." relaySent="..relaySent.." lastReceive="..lastReceive)
 elseif s=="experimental off" then db.experimentalDisabled=true;say("Experimental warnings and bars disabled")
 elseif s=="experimental on" then db.experimentalDisabled=false;say("Experimental warnings and bars enabled")
 elseif s=="fast off" then db.fastSyncDisabled=true;say("Batch sync off; single-record compatibility mode")
 elseif s=="fast on" then db.fastSyncDisabled=false;say("Batch sync enabled; conservative 0.75s pacing")
 elseif s=="share off" then db.sharingDisabled=true;say("Sync sharing disabled; local recording continues")
 elseif s=="share on" then db.sharingDisabled=false;backfillDone=false;say("Sync sharing enabled")
 elseif s=="ping" then if queueControl("H;PING") then say("Ping queued; will send using the 1-second rate limit") else say("Ping queue full; try again shortly") end
 elseif s=="ui off" then db.hideStatus=true;if statusFrame then statusFrame:Hide() end
 elseif s=="ui on" then db.hideStatus=false;makeStatus();statusFrame:Show()
 elseif s=="channel off" then db.channelDisabled=true;say("Shared-channel listening disabled; existing channel membership unchanged")
 elseif s=="channel on" then db.channelDisabled=false;db.channelUnsafe=nil;say("Shared-channel listening enabled (LootCollector owns BBLC25C)")
 elseif s=="off" then db.disabled=true;save();say("Automatic recording disabled")
 elseif s=="on" then db.disabled=false;refresh();say("Automatic recording enabled")
 elseif s=="clear" then db.sessions={};say("Saved sessions cleared")
 elseif s=="save" then save();refresh();say("Current recording saved (if any)")
 else say("Automatic in instances. Settings: /dbmcoa options. Commands: /dbmcoa status | on | off | save | clear | channel on | channel off | share on/off | fast on/off | experimental on/off | ping | ui on/off") end
end
