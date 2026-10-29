# DBM-CoA — Boss Warnings, Encounter Timers & Experimental Auto-Learning

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

**Current source build: v3.22 (experimental test build).** Optional ElvUI compatibility and Smart Archive Sync. Installable ZIPs and version history are published through [GitHub Releases](https://github.com/downingwow/DBM-CoA/releases).

The learner can receive duplicate or invalid timing records, and older versions may not support all current message types. Learned encounter warnings and exact backward compatibility still require in-game verification. Interface target: **30300**.

## Credits and support

Based on [Deadly Boss Mods](https://github.com/DeadlyBossMods/DeadlyBossMods) by its original authors and contributors. CoA-specific learner adaptation and distribution by **Uncle Bone**. Community project, not an official DBM or Ascension release.

[Report issues / request features](https://github.com/downingwow/DBM-CoA/issues) · [Changelog](CHANGELOG.md)


## v3.22 changes

Optional ElvUI-aware learner-window styling retains the default UI and DragonUI fallback. Includes Smart Archive Sync, the resizable learner window and historical archive reference data. Archive references are not verified observations; live compatibility remains untested.
