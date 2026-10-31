-- Research-backed encounter NPC roster. Source verified, NOT live verified.
-- Intentionally passive: does not register combat events, start timers or interfere with DBM.
DBMCoAClassic19Research = {
  [33] = { name="Shadowfang Keep", npcIds={3914,3886,3887,4278,4279,4274,3927,4275,14682,3872}, liveVerified=false },
  [34] = { name="The Stockade", npcIds={1696,1666,1717,1716,1663,1720}, liveVerified=false },
  [36] = { name="The Deadmines", npcIds={644,642,1763,646,645,647,639,3586}, liveVerified=false },
  [43] = { name="Wailing Caverns", npcIds={3671,3669,3653,3670,3674,3673,5775,5912}, liveVerified=false },
  [47] = { name="Razorfen Kraul", npcIds={6168,4424,4428,4420,4421,4422,4425,4842}, liveVerified=false },
  [48] = { name="Blackfathom Deeps", npcIds={4887,4831,6243,12902,4830,4832,4829}, liveVerified=false },
  [70] = { name="Uldaman", npcIds={6910,6906,7228,7206,7291,4854,2748,7023}, liveVerified=false },
  [90] = { name="Gnomeregan", npcIds={7079,7361,6235,6229,7800}, liveVerified=false },
  [109] = { name="Sunken Temple", npcIds={5710,5719,5722,5709}, liveVerified=false },
  [129] = { name="Razorfen Downs", npcIds={7355,7357,8567,7358,7356,7354}, liveVerified=false },
  [189] = { name="Scarlet Monastery", npcIds={3983,4543,3974,6487,3975,4542,3977,6489,6490,3976,6488}, liveVerified=false },
  [209] = { name="Zul'Farrak", npcIds={7795,7273,8127,7272,7271,7796,7275,7267,10082,7604}, liveVerified=false },
  [229] = { name="Blackrock Spire", npcIds={10899,10509,10263,10376,9596,9217,9218,9219,9196,9236,9237,10596,9736,10268,10220,9568,9816,10429,10430,10363}, liveVerified=false },
  [230] = { name="Blackrock Depths", npcIds={9018,9025,9319,9024,9017,9041,9056,9016,9033,8983,9537,9502,9543,9499,9156,9039,9938,9019}, liveVerified=false },
  [289] = { name="Scholomance", npcIds={14861,10506,10503,11622,10433,10432,10505,11261,10901,10507,10504,10502,1853,10508}, liveVerified=false },
  [329] = { name="Stratholme", npcIds={10809,10558,10808,10997,11032,10811,10813,10436,10437,10438,10435,10439,10440}, liveVerified=false },
  [349] = { name="Maraudon", npcIds={13282,12258,12236,12225,12203,13601,13596,12201,13738,13739,12237}, liveVerified=false },
  [389] = { name="Ragefire Chasm", npcIds={11517,11520,11518,11519,17830}, liveVerified=false },
  [429] = { name="Dire Maul", npcIds={14506,11467,11490,13280,14327,11492,11488,11487,11496,11489,11486,14326,14322,14321,14323,14325,14324,11501}, liveVerified=false },
}
DBMCoAClassic19ResearchIndex = {}
for mapId, entry in pairs(DBMCoAClassic19Research) do
  for _, npcId in ipairs(entry.npcIds) do
    DBMCoAClassic19ResearchIndex[npcId] = mapId
  end
end
-- Safe lookup for AutoLearner/encounter modules; no global event listeners.
function DBMCoAGetClassicResearchEncounter(mapId, npcId)
  local entry = DBMCoAClassic19Research[tonumber(mapId)]
  if not entry or not npcId then return nil end
  if DBMCoAClassic19ResearchIndex[tonumber(npcId)] == tonumber(mapId) then return entry end
  return nil
end
