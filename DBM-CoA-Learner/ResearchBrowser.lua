-- DBM-CoA v3.34: opt-in in-game lookup of observed NPC spell evidence.
-- Evidence is not an encounter warning, verified cooldown, or timer prediction.
local function say(s)
 if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage('|cff66ccffDBM-CoA Research|r '..s) end
end
local function npcFromTarget()
 if not UnitExists or not UnitExists('target') then return nil end
 local guid=UnitGUID and UnitGUID('target')
 if type(guid)~='string' then return nil end
 -- WoW 3.3.5a GUID: creature entry is hex positions 7-10.
 local id=tonumber(string.sub(guid,7,10),16)
 if not id or id==0 then return nil end
 return id
end
local function report(id)
 local index=DBMCoAResearchIndex
 local entry=index and index[id]
 if not entry then say('No observed research for NPC '..tostring(id)..'.');return end
 local spells=entry.spells or {}
 say((entry.name or (DBMCoACompactNames and DBMCoACompactNames.npc[id]) or 'NPC')..' ('..id..'): '..#spells..' observed spell/event records. Research only.')
 local n=0
 for i=1,#spells do
  local s=spells[i]
  if s[2]=='SPELL_CAST_START' or s[2]=='SPELL_CAST_SUCCESS' then
   local name=GetSpellInfo and GetSpellInfo(s[1]) or nil
   say((name or (DBMCoACompactNames and DBMCoACompactNames.spell[s[1]]) or ('Spell '..s[1]))..' ['..s[1]..'] '..s[2]..' x'..(s[3] or '?'))
   n=n+1
   if n>=12 then say('Showing first 12 casts; research is not an active boss timer.');break end
  end
 end
 if n==0 then say('No cast events in current research; aura-only evidence may exist.') end
end
SLASH_COARESEARCH1='/coaresearch'
SlashCmdList.COARESEARCH=function(msg)
 local id=tonumber(msg)
 if not id then id=npcFromTarget() end
 if not id then say('Target an NPC and type /coaresearch, or use /coaresearch <NPC ID>.');return end
 report(id)
end
