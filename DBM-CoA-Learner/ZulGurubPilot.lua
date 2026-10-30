-- Zul'Gurub pilot: read-only encounter evidence from the user's own SavedVariables.
-- No hardcoded timers are generated from archive spell IDs.
SLASH_COAZG1="/coazg"
SlashCmdList.COAZG=function()
 local db=DBMCoALearnerDB
 local root=db and db.encounterTimers24 and db.encounterTimers24.raid and db.encounterTimers24.raid["Zul'Gurub"]
 local npcs,spells,predicted=0,0,0
 local seen={}
 for _,mobs in pairs(root or {}) do
  for id,mob in pairs(mobs) do
   if not seen[id] then npcs=npcs+1;seen[id]=true end
   for _,rec in pairs(mob.spells or {}) do
    spells=spells+1;if rec.status=="predicted" or rec.status=="verified" then predicted=predicted+1 end
   end
  end
 end
 if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("DBM-CoA Zul'Gurub pilot: "..npcs.." NPCs, "..spells.." learned spell entries, "..predicted.." predicted/verified. /coatimings for details.") end
end
