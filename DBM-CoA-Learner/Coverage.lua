-- DBM-CoA v4.0: prebuilt encounter coverage diagnostics.
SLASH_COACOVERAGE1="/coacoverage"
SlashCmdList.COACOVERAGE=function()
 local total=0;local pairsCount=0
 for _,spells in pairs(DBMCoAStockTimerIndex or {}) do total=total+1;for _ in pairs(spells) do pairsCount=pairsCount+1 end end
 local msg="DBM-CoA prebuilt index: "..total.." NPC IDs, "..pairsCount.." NPC/spell timer associations. Existing DBM encounter modules provide the actual bars; the learner only adds missing predictions."
 if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(msg) end
end
