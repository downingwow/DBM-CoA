-- DBM-CoA v3.8 test settings, WoW 3.3.5 compatible.
local panel=CreateFrame("Frame","DBMCoAOptionsPanel",UIParent)
panel.name="DBM-CoA"
local title=panel:CreateFontString(nil,"ARTWORK","GameFontNormalLarge")
title:SetPoint("TOPLEFT",16,-16);title:SetText("DBM-CoA | Test Settings")
local subtitle=panel:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
subtitle:SetPoint("TOPLEFT",title,"BOTTOMLEFT",0,-10)
subtitle:SetText("Shared channel: BBLC25C (auto-joins after 20 seconds if missing). /dbmcoa status for diagnostics.")
local function checkbox(label,description,key,y,reverse,change)
 local b=CreateFrame("CheckButton",nil,panel,"InterfaceOptionsCheckButtonTemplate")
 b:SetPoint("TOPLEFT",16,y);b:SetWidth(26);b:SetHeight(26)
 local text=b:CreateFontString(nil,"ARTWORK","GameFontNormal")
 text:SetPoint("LEFT",b,"RIGHT",4,0);text:SetText(label)
 local help=panel:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
 help:SetPoint("TOPLEFT",b,"BOTTOMLEFT",30,-1);help:SetText(description)
 b:SetScript("OnShow",function(self)
  local db=DBMCoALearnerDB or {}
  local checked=not not db[key]
  if reverse then checked=not checked end
  self:SetChecked(checked)
 end)
 b:SetScript("OnClick",function(self)
  local db=DBMCoALearnerDB
  if not db then return end
  local value=not not self:GetChecked()
  if reverse then value=not value end
  db[key]=value
  if change then change(value) end
 end)
 return b
end
local function header(name,y)
 local t=panel:CreateFontString(nil,"ARTWORK","GameFontNormal")
 t:SetPoint("TOPLEFT",16,y);t:SetText(name)
end
header("Recording",-70)
checkbox("Automatic encounter recording","Collect observed spells and NPC information while playing.","disabled",-90,true)
header("Synchronization",-151)
checkbox("Share learned data","Uses BBLC25C; automatically joins after 20 seconds if missing.","sharingDisabled",-171,true)
checkbox("Batch synchronization","Conservative batch sending; turn off for single-record compatibility.","fastSyncDisabled",-224,true)
header("Warnings and timers",-285)
checkbox("Experimental encounter warnings","Observed mechanics only; may be inaccurate until corroborated.","experimentalDisabled",-305,true)
header("Status window",-366)
checkbox("Show draggable status window","Close with X to hide it; recording and sharing continue.","hideStatus",-386,true,function(hidden)
 local frame=_G.DBMCoALearnerStatus
 if frame then if hidden then frame:Hide() else frame:Show() end end
end)
local hint=panel:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
hint:SetPoint("TOPLEFT",16,-450);hint:SetText("Responsive addon peers are shown in the status window (last 3 minutes).")
if type(InterfaceOptions_AddCategory)=="function" then InterfaceOptions_AddCategory(panel) end
