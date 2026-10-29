-- DBM-CoA v3.21: demand-driven archive sync. Never auto-broadcast the whole archive.
-- Historical references are NOT verified combat discoveries.
local CHANNEL="BBLC25C"
local PREFIX="DCOAR21"
local KINDS={"N","S","Q","I"}
local f=CreateFrame("Frame")
local tick,announce=0,0
local queue,requests,seenRequests={}, {}, {}
local manifest,localIndex={},{}
local function hash(s)
 local h=5381
 for i=1,#s do h=(h*33+s:byte(i))%2147483647 end
 return h
end
local function getDB()
 local db=DBMCoALearnerDB
 if not db then return end
 db.archiveSmart21=db.archiveSmart21 or {sent=0,received=0,duplicates=0,requests=0,peers=0,conflicts=0}
 db.archiveRemote17=db.archiveRemote17 or {N={},S={},Q={},I={}}
 return db
end
local function parseIndex()
 if manifest.N then return end
 for _,kind in ipairs(KINDS) do
  manifest[kind]={};localIndex[kind]={}
  for b=0,63 do manifest[kind][b]={count=0,hash=0} end
  for _,chunk in ipairs(CoAFullArchive and CoAFullArchive[kind] or {}) do
   for record in (chunk.."|"):gmatch("(.-)|") do
    local k,id,label=record:match("^([NSQI]);(%d+);(.+)$")
    id=tonumber(id)
    if k==kind and id and label then
     local bucket=id%64
     local v=manifest[kind][bucket]
     v.count=v.count+1
     v.hash=(v.hash+hash(record))%2147483647
     localIndex[kind][id]=label
    end
   end
  end
 end
end
local function channelId()
 local id=GetChannelName and GetChannelName(CHANNEL) or 0
 if type(id)=="number" and id>0 then return id end
end
local function send(payload)
 local db=getDB()
 if not db or db.sharingDisabled or db.channelDisabled or db.channelUnsafe or db.archiveSharingDisabled then return false end
 local id=channelId()
 if not id or #payload>230 or not payload:match("^[%w ;%-_%.%,:]+$") then return false end
 return pcall(SendChatMessage,payload,"CHANNEL",nil,id)
end
local function enqueue(s)
 if #queue<5000 then queue[#queue+1]=s end
end
local function receive(msg,sender)
 if type(msg)~="string" or #msg>230 or msg:sub(1,8)~=PREFIX..";" then return end
 local db=getDB();if not db then return end
 parseIndex()
 local stats=db.archiveSmart21
 local typ,body=msg:match("^DCOAR21;([HQRD]);(.+)$")
 if not typ then return end
 if typ=="H" then
  local kind,bucket,count,digest=body:match("^([NSQI]);(%d+);(%d+);(%d+)$")
  bucket=tonumber(bucket);count=tonumber(count);digest=tonumber(digest)
  if not bucket or bucket>63 or not count or not digest then return end
  local ours=manifest[kind][bucket]
  if ours and (ours.count~=count or ours.hash~=digest) then
   local key=kind..":"..bucket..":"..tostring(sender)
   if not seenRequests[key] or GetTime()-seenRequests[key]>300 then
    seenRequests[key]=GetTime()
    enqueue(PREFIX..";Q;"..kind..";"..bucket)
    stats.requests=stats.requests+1
   end
  end
 elseif typ=="Q" then
  local kind,bucket=body:match("^([NSQI]);(%d+)$")
  bucket=tonumber(bucket)
  if not bucket or bucket>63 then return end
  local key=kind..":"..bucket..":"..tostring(sender)
  if requests[key] and GetTime()-requests[key]<120 then return end
  requests[key]=GetTime()
  -- Serve only requested buckets; do not flood clients with the full archive.
  -- Limit the transfer queue and let additional requests retry later.
  local n=0
  for _,chunk in ipairs(CoAFullArchive and CoAFullArchive[kind] or {}) do
   for record in (chunk.."|"):gmatch("(.-)|") do
    local id=tonumber(record:match("^[NSQI];(%d+);"))
    if id and id%64==bucket then
     enqueue(PREFIX..";D;"..record)
     n=n+1
     if n>=4500 then return end
    end
   end
  end
 elseif typ=="D" then
  local kind,id,label=body:match("^([NSQI]);(%d+);(.+)$")
  id=tonumber(id)
  if not kind or not id or id<1 or id>100000000 or #label>50 or not label:match("^[%w %-_%.%,]+$") then return end
  local localLabel=localIndex[kind][id]
  if localLabel then
   if localLabel==label then stats.duplicates=stats.duplicates+1
   else stats.conflicts=stats.conflicts+1 end
   return
  end
  local t=db.archiveRemote17[kind]
  if t[id] then
   if t[id]==label then stats.duplicates=stats.duplicates+1 else stats.conflicts=stats.conflicts+1 end
  else
   t[id]=label;stats.received=stats.received+1
  end
 end
end
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("CHAT_MSG_CHANNEL")
f:SetScript("OnEvent",function(self,event,...)
 if event=="ADDON_LOADED" then
  if ...=="DBM-CoA-Learner" then getDB() end
 elseif event=="CHAT_MSG_CHANNEL" then
  local msg,sender,language,displayName,target,flags,zoneId,index,baseName=...
  local id=channelId()
  local function eq(v) return type(v)=="string" and v:gsub("^%d+%.%s*",""):lower()==CHANNEL:lower() end
  if eq(displayName) or eq(baseName) or (id and tonumber(index)==id) then receive(msg,sender) end
 end
end)
local cursor=0
f:SetScript("OnUpdate",function(self,dt)
 tick=tick+dt;announce=announce+dt
 if tick<3 then return end
 tick=0
 local db=getDB()
 if not db or db.archiveSharingDisabled or db.sharingDisabled or db.channelDisabled then return end
 if not channelId() then return end
 parseIndex()
 if #queue>0 then
  if send(queue[1]) then
   if queue[1]:sub(1,9)==PREFIX..";D" then db.archiveSmart21.sent=db.archiveSmart21.sent+1 end
   table.remove(queue,1)
  end
 elseif announce>=12 then
  announce=0
  local kind=KINDS[math.floor(cursor/64)+1]
  local bucket=cursor%64
  local v=manifest[kind][bucket]
  send(PREFIX..";H;"..kind..";"..bucket..";"..v.count..";"..v.hash)
  cursor=(cursor+1)%256
 end
end)
SLASH_COAARCHIVE1="/coaarchive"
SlashCmdList.COAARCHIVE=function(arg)
 local db=getDB();if not db then return end
 local s=db.archiveSmart21
 arg=(arg or ""):lower():match("^%s*(.-)%s*$")
 if arg=="off" then db.archiveSharingDisabled=true
 elseif arg=="on" then db.archiveSharingDisabled=false
 elseif arg=="reset" then db.archiveSmart21={sent=0,received=0,duplicates=0,requests=0,peers=0,conflicts=0};s=db.archiveSmart21 end
 if DEFAULT_CHAT_FRAME then
  DEFAULT_CHAT_FRAME:AddMessage("DBM-CoA Smart Archive: "..(db.archiveSharingDisabled and "paused" or "enabled").." | sent "..s.sent.." | new "..s.received.." | duplicates "..s.duplicates.." | conflicts "..s.conflicts.." | requests "..s.requests.." | queue "..#queue)
 end
end
