# CoA Memory Audit — Test Baseline

This branch is for source-backed memory optimization. Do not deploy as a release until verified on the 3.3.5a Conquest Reborn client.

## Baseline (after forced Lua garbage collection)
- Questie-X + WotLKDB: 132 MB (Questie-X 49 MB, WotLKDB 83 MB)
- DBM-CoA Learner + Observer: 66 MB (Learner 40 MB, Observer 26 MB)

## Safe rules
- Preserve all SavedVariables, discoveries, custom Ascension records and BBLC25C wire formats.
- Do not disable WotLKDB: it contains cross-expansion and Vanilla data.
- Do not assume separate addon memory attribution means duplicate physical tables.
- Do not remove archival evidence until its consumers are identified.
- Compare before/after memory after a forced GC, and measure login/zone-load stutter.

## Source findings
Questie-X WotLKDB/Loader.lua merges correction tables then injects NPC, item, object and quest data.
Questie-X/Modules/Libs/QuestiePluginAPI.lua merges by field and reuses entry tables for new IDs.
DBM-CoA-Observer/LearnerObserver.lua already caps fights, events and abilities.
DBM-CoA-Learner/Learner.lua already caps sessions and sharing queues.

## Next engineering checks
1. Trace QuestieDB overrides through compiler and runtime caches; identify reachable duplicate data.
2. Determine whether Ascension/CoA database plugin overlays retain redundant tables.
3. Profile DBM archive tables, live sessions and observer SavedVariables independently.
4. Implement one reversible optimization at a time, followed by in-game verification.
