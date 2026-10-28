# DBM-CoA — Deadly Boss Mods for Conquest of Azeroth

A legacy-client DBM package with an experimental **CoA encounter AutoLearner**, built for **Ascension: Conquest of Azeroth / Conquest Reborn** (Interface 30300).

## Features

- DBM core, GUI, timers, warnings, and included raid, dungeon, and PvP modules.
- Encounter observation and **experimental live-learning** of combat events and timing evidence while playing.
- Persistent learned encounter data in SavedVariables; independent Observer component also included in the current package.
- Instance-aware encounter detection and timing-data synchronization.
- Shared-channel synchronization over LootCollector's `BBLC25C` channel, using DBM-CoA-specific protocol messages and delayed cooperative startup.
- Sync diagnostics including sent, received, duplicate, rejected, pending, and peer-response counters.
- Compact DBM-CoA settings integrated with the DBM options interface, and a draggable learner status window.
- Compatibility-focused changes for the legacy WoW API.

**Experimental:** Learned warnings and timers require validation. Presence of legacy DBM PvP modules does not mean that automatic battleground or arena learning is already implemented; that is planned work.

## Current source package

**v3.12 — Safe Channel Startup** is the latest available package. The source and a downloadable GitHub Release have **not yet been published**.

## Installation

Once released, extract **all addon folders** from the release ZIP into `Interface/AddOns` (including DBM-Core, DBM-GUI, the encounter modules, and DBM-CoA components). Do not install only one folder.

## Downloads and support

[Releases](https://github.com/downingwow/DBM-CoA/releases) · [Issues](https://github.com/downingwow/DBM-CoA/issues) · [Changelog](CHANGELOG.md)

**Credits:** Deadly Boss Mods upstream authors and contributors; CoA learner adaptation maintained by Uncle Bone. Community project; not an official DBM or Ascension release.
