-- DBM-CoA v5.0 experimental, research-backed Classic dungeon cast alerts.
-- Research source: downingwow/CoA-Research research/dbm (2026-10-30)
-- These are SOURCE candidates, not live-verified. Never schedules predictive bars.
-- This supplement never modifies stock DBM modules or the BBLC25C protocol.
local spellByMap={
  [36]={[975011]=true,[2102553]=true,[2102580]=true,[2102576]=true,[2102577]=true,[674]=true,[5200]=true,[5141]=true,[2102559]=true,[2102569]=true,[2102554]=true,[2102590]=true,[2102589]=true,[2102527]=true,[40505]=true,[5208]=true,[2101111]=true,[5213]=true,[2102571]=true},
  [48]={[2102687]=true},
  [209]={[975011]=true},
  [229]={[975011]=true,[2102619]=true,[2102203]=true,[2102552]=true,[2100428]=true,[2100148]=true,[2100345]=true,[2102189]=true,[2102825]=true,[2102850]=true,[2100255]=true,[2102851]=true,[2102192]=true,[2102159]=true,[2100205]=true,[2100439]=true,[2100465]=true,[15284]=true,[15615]=true,[10966]=true,[14516]=true,[11972]=true,[15749]=true,[2102741]=true,[2102840]=true,[15580]=true,[16172]=true,[6253]=true,[2102553]=true,[2102138]=true,[2102137]=true},
  [230]={[975011]=true,[505347]=true,[92603]=true,[92606]=true,[381251]=true,[815637]=true,[14033]=true,[17203]=true},
  [289]={[2100397]=true,[2100398]=true,[2100389]=true,[2100393]=true,[2100034]=true,[975011]=true,[2100004]=true},
  [329]={[816867]=true,[975011]=true},
  [349]={[21833]=true},
  [389]={[2102516]=true,[2102517]=true,[2102518]=true,[2102519]=true},
  [429]={[2100236]=true},
}
local frame=CreateFrame("Frame")
local last={}
local currentMap=0
local function idFromGuid(guid)
 if type(guid)~="string" then return nil end
 if guid:sub(1,6)=="0xF130" then return tonumber(guid:sub(7,10),16) end
 if guid:find("^Creature%-") then return tonumber(guid:match("^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)%-")) end
 return nil
end
local band=bit and bit.band
local function enemy(flags)
 return type(flags)=="number" and band and band(flags,0x800)~=0 and band(flags,0x3000)==0 and band(flags,0x100)==0
end
local function updateZone()
 local _,kind,_,_,_,_,_,mapId=GetInstanceInfo()
 currentMap=(kind=="party") and (tonumber(mapId) or 0) or 0
 -- 3.3.5a GetInstanceInfo returns instance ID as 8th return on supported clients.
 last={}
end
local function isStock(npcId,spellId)
 local stock=DBMCoAStockTimerIndex
 return stock and stock[npcId] and stock[npcId][spellId]
end
local function onCombatLog(...)
 local db=DBMCoALearnerDB
 if not db or db.coaDungeonResearchEnabled==false or db.coaDungeonResearchWarnings==false then return end
 local spells=spellByMap[currentMap]
 if not spells then return end
 local event=select(2,...)
 if event~="SPELL_CAST_START" and event~="SPELL_CAST_SUCCESS" then return end
 local offset=type(select(3,...))=="boolean" and 1 or 0
 local guid=select(3+offset,...)
 local flags=select(5+offset,...)
 if not enemy(flags) then return end
 local npcId=idFromGuid(guid)
 if not npcId or not DBMCoAGetClassicResearchEncounter or not DBMCoAGetClassicResearchEncounter(currentMap,npcId) then return end
 local sid=select(9+offset,...)
 if type(sid)~="number" or not spells[sid] or isStock(npcId,sid) then return end
 local key=tostring(npcId)..":"..sid
 local now=GetTime()
 if last[key] and now-last[key]<8 then return end
 last[key]=now
 local name=GetSpellInfo(sid) or ("Spell "..sid)
 -- Warn only on ACTUAL observed enemy casts, never on player/pet effects.
 if DBM and DBM.AddMsg then
  DBM:AddMsg("[CoA experimental] "..name.." ("..sid..")")
 elseif DEFAULT_CHAT_FRAME then
  DEFAULT_CHAT_FRAME:AddMessage("|cffffbb44[CoA experimental]|r "..name.." ("..sid..")")
 end
end
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:SetScript("OnEvent",function(self,event,...)
 if event=="COMBAT_LOG_EVENT_UNFILTERED" then onCombatLog(...) else updateZone() end
end)
-- In-game options panel extends existing DBM-CoA category, without replacing it.
local panel=CreateFrame("Frame","DBMCoADungeonResearchOptions",UIParent)
panel.name="Dungeon Research"
panel.parent="DBM-CoA"
local title=panel:CreateFontString(nil,"ARTWORK","GameFontNormalLarge")
title:SetPoint("TOPLEFT",16,-16);title:SetText("DBM-CoA v5.0.2 | Dungeon Research")
local note=panel:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
note:SetPoint("TOPLEFT",16,-45);note:SetWidth(500);note:SetJustifyH("LEFT")
note:SetText("Experimental source-backed cast alerts. All 19 dungeon NPC rosters are indexed. Source repeat bars are experimental, cast-triggered, and not live verified.")
local function option(key,label,y,default)
 local b=CreateFrame("CheckButton",nil,panel,"InterfaceOptionsCheckButtonTemplate")
 b:SetPoint("TOPLEFT",16,y)
 local txt=panel:CreateFontString(nil,"ARTWORK","GameFontNormal")
 txt:SetPoint("LEFT",b,"RIGHT",4,0);txt:SetText(label)
 b:SetScript("OnShow",function(self)
  local db=DBMCoALearnerDB
  if db and db[key]==nil then db[key]=default end
  self:SetChecked(db and db[key])
 end)
 b:SetScript("OnClick",function(self)
  if DBMCoALearnerDB then DBMCoALearnerDB[key]=not not self:GetChecked() end
 end)
end
option("coaDungeonResearchEnabled","Enable experimental dungeon research",-100,true)
option("coaDungeonResearchWarnings","Show researched enemy cast warnings",-145,true)
option("coaDungeonPredictiveTimers","Experimental source repeat timers (unverified)",-185,true)
local footer=panel:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
footer:SetPoint("TOPLEFT",16,-240);footer:SetWidth(510);footer:SetJustifyH("LEFT")
footer:SetText("Existing raid modules, AutoLearner, stock timers, and BBLC25C sharing remain unchanged. Source-only research is not proof of live encounter behavior.")
if type(InterfaceOptions_AddCategory)=="function" then InterfaceOptions_AddCategory(panel) end
