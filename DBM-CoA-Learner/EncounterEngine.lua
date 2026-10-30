-- DBM-CoA v4.1: native module audit and safe adaptive diagnostics.
-- Only prebuilt DBM encounter modules create stock timers; no duplicate anchor or timer.
local M={}
DBMCoAEncounterEngine=M
local function db()
 local d=DBMCoALearnerDB
 if not d then return nil end
 d.adaptive41=d.adaptive41 or {enabled=true,seen={},review={},lastZone=""}
 return d.adaptive41
end
local function say(msg)
 if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffDBM-CoA:|r "..msg) end
end
local function context()
 local name,kind,difficulty=GetInstanceInfo()
 if not name or name=="" then name=(GetRealZoneText and GetRealZoneText()) or "Unknown" end
 return name,kind or "none",difficulty or 0
end
local function total()
 local npcCount,spellCount,definitionCount=0,0,0
 for _,spells in pairs(DBMCoAStockTimerIndex or {}) do
  npcCount=npcCount+1
  for _,times in pairs(spells) do spellCount=spellCount+1;definitionCount=definitionCount+#times end
 end
 return npcCount,spellCount,definitionCount
end
local f=CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
f:SetScript("OnEvent",function()
 local d=db();if not d then return end
 d.lastZone=context()
end)
SLASH_COAENGINE1="/coaengine"
SlashCmdList.COAENGINE=function(input)
 local d=db();if not d then say("SavedVariables not initialized yet.");return end
 input=string.lower((input or ""):match("^%s*(.-)%s*$"))
 if input=="on" then d.enabled=true;say("Adaptive observation enabled. Stock DBM timers remain authoritative.");return end
 if input=="off" then d.enabled=false;say("Adaptive discrepancy tracking disabled. Existing DBM encounter modules remain active.");return end
 local zone,kind,diff=context()
 local npcs,spells,defs=total()
 local learned,review=0,0
 for _,areas in pairs((DBMCoALearnerDB or {}).encounterTimers24 or {}) do
  for _,diffs in pairs(areas) do
   for _,mobs in pairs(diffs) do
    for _,mob in pairs(mobs) do
     for _,rec in pairs(mob.spells or {}) do
      learned=learned+1
      if rec.needsReview then review=review+1 end
     end
    end
   end
  end
 end
 say("Zone: "..zone.." ("..kind..", "..diff..") | prebuilt index: "..npcs.." NPCs, "..spells.." NPC/spell pairs, "..defs.." timing values")
 say("Observed mechanics: "..learned.." | stock discrepancies flagged: "..review.." | adaptive: "..(d.enabled and "on" or "off"))
 say("/coaengine on|off | /coacoverage | /coatimings | /coatest | /dbm move")
end
