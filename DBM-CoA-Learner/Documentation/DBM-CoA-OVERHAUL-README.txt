DBM-CoA AVAILABLE-SOURCE OVERHAUL - DEVELOPMENT PACKAGE

WHAT THIS BUILD DOES
- Preserves existing DBM encounter modules across Vanilla, TBC and WotLK packages, including existing CoA edits.
- Adds a live source-derived timer engine and encounter schedules extracted from four CoA AzerothCore server scripts (Jeklik, Venoxis, Mar'li, Hakkar).
- The source engine emits native DBM bars only for spell IDs absent from the existing stock timer index, avoiding duplicate stock timers.
- Observed spell intervals with >=8 samples can adjust SOURCE-ONLY predictions. Stock modules remain authoritative.
- Preserves existing open-world/dungeon/raid learning and BBLC25C sync protocols.
- /coasources reports source-driven timer coverage; /coaengine, /coacoverage, /coastatus, /coatimings, /coatest remain available.

IMPORTANT LIMITATIONS
- This is the maximum actual implementation completed with retrieved sources in this run, not a claim that every CoA boss script was converted.
- Source-derived initial timers begin when combat log first identifies the boss, which can be later than pull; health phases require a visible unit.
- Existing DBM modules may contain inaccurate historical cooldowns. Source engine intentionally avoids overriding them without in-game confirmation.
- No in-game tests were performed; ZIP integrity is checked.
- CoA server fork is not guaranteed identical to live Conquest Reborn.

SOURCES
https://github.com/Conquest-of-AzerothCore/azerothcore-wotlk-coa
https://coa-development.org/
https://ascension-db.ascension-archive.workers.dev/
