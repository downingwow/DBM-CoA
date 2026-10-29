# DBM-CoA v3.22

Optional ElvUI compatibility and Smart Archive Sync.

**Experimental prerelease: in-game validation is pending.**

v3.15 Archive Test: live enemy cast warnings on first observation; predicted cooldown bars only from stable local samples; rate-limited one-time rebroadcast of saved observed discoveries; smart sync retry; historical NPC/spell ID reference datasets bundled separately (not auto-shared as encounter discoveries). Not in-game tested.


v3.16: ships 900 historical elite NPCs and their archived spell associations; broadcasts reference entries over BBLC25C using DCOAR16 with 3-second pacing, resume cursor and separate storage on receivers. Reference messages are NOT asserted as verified encounter observations. /coaarchive status, on, off, reset. No in-game test performed.


v3.17: Full historical NPC/spell/quest/item ID and label archive distributed via DCOAR17 batches on BBLC25C; resumable saved cursor and deduplicating receiver. Counts: {'N': 41817, 'S': 214152, 'Q': 10776, 'I': 115373}. Historical reference labels are NOT confirmed boss casts, timers or mechanics. Not in-game tested.

v3.18: Learner status window now shows archive sharing status, records sent / 382118, and records received. Window enlarged to prevent clipping. Uses existing v3.17 sharing engine. Not tested in game.\n

v3.19: Fix literal backslash-n in learner status text that rendered every status field on one giant line. Use real line breaks, explicit text bounds, top alignment and taller window. Preserve archive sharing progress and saved discoveries. Not in-game tested.\n

v3.20: Resize learner window by dragging bottom-right grip; saved width and height persist across logins; text adapts to window size. Minimum 320x155, maximum 850x500. Drag main window to move. Not in-game tested.


v3.21: Replaced unconditional 382k archive broadcast with hash-bucket inventory announcements and request-only transfer. Incoming IDs compared against shipped archive and saved remote references. New archive stats in resizable Learner. Compatible legacy DCOAL31 discovery receiver retained. v3.17 archive broadcasts ignored to prevent duplicate import. Experimental, not in-game tested.\n

DBM-CoA v3.22 - Optional ElvUI compatibility (TEST)
- Optional ElvUI-aware Learner window backdrop styling, protected by safe API checks.
- Preserves the original default Blizzard UI and DragonUI presentation if ElvUI is absent.
- No requirement to disable ElvUI or DragonUI.
- Retains v3.21 Smart Archive Sync, resize grip, and SavedVariables.
- In-game compatibility has not been verified.



Install the addon folders from the attached ZIP side by side in `Interface/AddOns`. Preserve WTF/SavedVariables. See the repository README for features, commands, dependencies and limitations.

Maintainer: Uncle Bone — https://github.com/downingwow
Original licenses and attribution are preserved.
