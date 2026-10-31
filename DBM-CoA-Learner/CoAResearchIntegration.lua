-- CoA-Research integration v4.2.1 (Conquest Reborn, 3.3.5a)
-- Lightweight runtime inventory. This file does not import SQL/DBC datasets.
-- Historical server scripts are candidates, not verified live timers.
local f=CreateFrame("Frame")
local function count(t)
  local n=0
  if type(t)=="table" then for _ in pairs(t) do n=n+1 end end
  return n
end
local function report()
  local source=DBMCoAServerSources or {}
  local bosses, spells=0,0
  for _,boss in pairs(source) do
    bosses=bosses+1
    spells=spells+count(boss.abilities)
  end
  local stock=DBMCoAStockTimerIndex or {}
  local stockBosses=count(stock)
  local learned=DBMCoALearnerDB
  local learnedState=learned and "loaded" or "not yet initialized"
  local msg="DBM-CoA research: "..bosses.." server-script candidate bosses / "..spells..
    " candidate spell schedules; "..stockBosses.." indexed stock boss keys; learner "..learnedState..
    ". Candidate timings are NOT verified Conquest Reborn timings."
  if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff66ccff"..msg.."|r") end
end
SLASH_DBMCOARESEARCH1="/coaresearch"
SlashCmdList["DBMCOARESEARCH"]=report
-- Compact provenance/validation policy for encounter development.
DBMCoAResearchPolicy={
  client="Conquest Reborn / WoW 3.3.5a",
  live="Observed live combat log / verified client",
  extracted="Client DBC/WDB extract (versioned)",
  historical="Historical CoA AzerothCore server script (candidate)",
  validation="Do not replace stock encounter timers without observed live evidence",
  source="https://github.com/downingwow/CoA-Research"
}
