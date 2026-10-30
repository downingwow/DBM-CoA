-- v3.38 universal zone research lookup; observations are NOT verified mechanics.
DBMCoAZoneResearch = DBMCoAZoneResearch or {}
local cacheZone,cache=nil,{}
function DBMCoAZoneResearch:GetCurrent()
 local zone=(GetRealZoneText and GetRealZoneText()) or ""
 if zone==cacheZone then return cache end
 cacheZone=zone;cache={}
 if DBMCoAResearchIndex then
  for id,record in pairs(DBMCoAResearchIndex) do
   if record.zone==zone then cache[id]=record end
  end
 end
 return cache
end
