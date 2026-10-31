# DBM-CoA — Boss Warnings, Encounter Timers & Experimental Auto-Learning

> **[⬇ Download v4.2.1]( https://github.com/downingwow/DBM-CoA/releases/download/v4.2.1/DBM-CoA-v4.2.1.zip )**


## Current release

# DBM-CoA v4.3 — Available-source overhaul, clean installation

This release versions the newest previously unnumbered clean-install development package as v4.3. It includes the available-source overhaul following v4.2.

- Retains the packaged Vanilla, TBC and Wrath encounter modules.
- Adds source-derived encounter schedules for Jeklik, Venoxis, Mar'li and Hakkar: four bosses and 35 spell schedules in the supplied coverage report.
- Source-derived native DBM bars are limited to spells absent from the stock timer index to reduce duplicate bars. Stock modules remain authoritative.
- Source-only predictions can adapt after at least eight observed intervals; historical references are not confirmed live mechanics.
- Retains game-wide learning, BBLC25C sharing protocols, research tools, native timer rendering and saved data.
- Uses the supplied clean-install organization, with historical documentation under Documentation.

Commands include `/coasources`, `/coaengine`, `/coacoverage`, `/coastatus`, `/coatimings` and `/coatest`. Use `/dbm move` for native timer anchors.

This is published on the stable release channel by maintainer request. The engine and source conversion remain experimental and have not been validated in the live Conquest Reborn client. This is not a conversion of every CoA encounter. Initial source timers start when combat-log identification occurs, which can be later than pull; health phases require a visible unit. Existing stock cooldowns may be inaccurate.

Install all DBM-* folders together into Interface/AddOns. Back up existing addon files and WTF/SavedVariables first. Replace old addon folders to avoid leftover files; retain SavedVariables.

Maintainer: Uncle Bone — https://github.com/downingwow


**DBM-CoA helps you react to dangerous fights.** It combines the familiar **Deadly Boss Mods (DBM)** boss-mod system with a custom experimental learner for **Ascension: Conquest of Azeroth / Conquest Reborn**.

## What DBM does during a fight

When a supported encounter is recognized, DBM can provide **warnings, countdown bars, sounds, and on-screen alerts** for important boss abilities. This helps a group anticipate mechanics rather than relying only on the combat log. The included package contains DBM's core interface and modules for many classic-era dungeons, raids, world events, and PvP content.

**Important:** A packaged boss module is not proof that a specific custom CoA encounter has fully accurate warnings. Custom bosses may require new data.

## What makes DBM-CoA different: AutoLearner

Many custom CoA bosses do not have handcrafted DBM modules. **DBM-CoA AutoLearner** watches supported combat information while you are actively playing and tries to build evidence about how encounters work.

- **Records combat events** such as observed spell activity and timing evidence during encounters.
- **Builds local encounter history** that can be used to study patterns and improve future warnings.
- **Learns timing information** from repeated observations rather than requiring every encounter to be manually programmed from scratch.
- **Stores learned data** in WoW SavedVariables so it survives logouts and restarts.
- **Synchronizes compatible learning data** with other addon users, potentially improving knowledge faster than one player's runs alone.
- **Provides diagnostics** for sent and received messages, duplicate or rejected records, retries, and responsive addon peers.
- **Offers a draggable status display** and learner-related controls integrated with DBM's options.

This system is **experimental**. Observed timing patterns are not necessarily exact cooldowns, and incomplete or malformed data can lead to unreliable warnings. Players should still pay attention to the encounter.

## Sharing and other addon compatibility

DBM-CoA uses the **existing LootCollector channel `BBLC25C`**, with DBM-specific messages rather than creating a competing global channel. Startup joining is delayed to avoid interfering with existing channels. The latest build is designed to coexist with compatible Questie-X and LootCollector builds.

The peer-response count reflects other responding addon users, **not necessarily everyone present in the chat channel**. Learning and sync only happen when the game client and addon are running; this is not an overnight server-side monitor.

## Observer component

The current ZIP also includes **DBM-CoA-Observer**, a separate passive evidence-collection addon. It stores its own data independently of the main learner. Its presence does **not** mean the Observer and AutoLearner databases have already been merged.

## PvP: current versus planned

The package includes traditional **DBM-PvP** content. A future expansion of the **CoA learner** is planned to collect battleground objective events and carefully validated arena/player spell timing evidence. **Do not confuse the included PvP modules with a finished automatic PvP-learning system.**

## What's included

The package contains multiple separate addon folders, including **DBM-Core**, **DBM-GUI**, encounter modules, **DBM-CoA-Learner**, and **DBM-CoA-Observer**. The complete package must be extracted into `Interface/AddOns` so all required components sit side by side.

## Install / update

1. Back up `DBMCoALearnerDB`, `DBMCoAObserverDB`, and other DBM SavedVariables before updating.
2. Extract **all top-level folders** from the release ZIP into `World of Warcraft/Interface/AddOns`.
3. Restart the game and check that DBM-Core and the CoA learner are enabled.
4. Configure learner recording, sharing, and diagnostics in DBM's options. Review experimental warnings before relying on them.

## Current build and known limits

**Current source build: v4.3.** Optional ElvUI compatibility and Smart Archive Sync. Installable ZIPs and version history are published through [GitHub Releases](https://github.com/downingwow/DBM-CoA/releases).

The learner can receive duplicate or invalid timing records, and older versions may not support all current message types. Learned encounter warnings and exact backward compatibility still require in-game verification. Interface target: **30300**.

## Credits and support

Based on [Deadly Boss Mods](https://github.com/DeadlyBossMods/DeadlyBossMods) by its original authors and contributors. CoA-specific learner adaptation and distribution by **Uncle Bone**. Community project, not an official DBM or Ascension release.

[Report issues / request features](https://github.com/downingwow/DBM-CoA/issues) · [Changelog](CHANGELOG.md)


## v3.22 changes

Optional ElvUI-aware learner-window styling retains the default UI and DragonUI fallback. Includes Smart Archive Sync, the resizable learner window and historical archive reference data. Archive references are not verified observations; live compatibility remains untested.

## v3.25 — Raid and dungeon learning

Experimental encounter learning defaults on for fresh users in dungeon and raid instances; explicit opt-outs remain respected. `/coalearning` shows learning status and instance type. `/coatimings` browses saved timings organized by instance, difficulty, creature and spell. Live alerts use observed casts; predictions need repeated consistent intervals. No fabricated boss timers are supplied. Preserves archive sync, resizing, saved data and optional ElvUI/DragonUI styling. Published as a stable release channel at the maintainer's request; live Conquest Reborn validation remains pending.


The repository stores the offline research SQLite database as `.sqlite.gz` to fit upload limits. Decompress it for local research. The release workflow verifies its SHA-256 and restores the original `.sqlite` inside the release ZIP. This file is offline research data and is not loaded by WoW.
