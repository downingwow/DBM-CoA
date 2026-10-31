# DBM-CoA — Deadly Boss Mods for Conquest Reborn

**Maintained by Uncle Bone** · [CoA Research & Addons](https://coa-research.unclebone.workers.dev/) · [Report an issue](https://github.com/downingwow/DBM-CoA/issues)

**Current development build: v5.0.3 (TEST)** — WoW 3.3.5a / Ascension Conquest of Azeroth / Conquest Reborn.

> **Important:** v5.0.3 is a test build, not a live-verified stable release. Check [GitHub Releases](https://github.com/downingwow/DBM-CoA/releases) for published downloads and version labels. The README version does not mean the corresponding ZIP has been published to GitHub.

## 🚨 REQUIRED UPDATE STEP: DELETE THE OLD `DBM-CoA-Observer` FOLDER

**`DBM-CoA-Observer` is an ADDON FOLDER inside your WoW `Interface/AddOns` directory. You MUST DELETE THAT ENTIRE FOLDER when updating from a build that included it.**

1. **Close World of Warcraft.**
2. Open your WoW installation's **`Interface/AddOns/`** directory.
3. Find the **folder** named **`DBM-CoA-Observer`**.
4. **DELETE THE ENTIRE `DBM-CoA-Observer` FOLDER.**
5. Extract all included DBM addon folders from the new ZIP into `Interface/AddOns/`, replacing old addon files.
6. Start the game. **No slash commands or setup are needed.**

**Why:** `DBM-CoA-Observer` was discontinued and is no longer distributed. Installing a new ZIP does **not** automatically remove old addon folders. Do not delete `DBM-CoA-Learner` or `DBM-Core`.

Back up your `WTF` SavedVariables before updating. Keeping SavedVariables preserves learner history and user preferences.

## What's new since v4.2.1

### Dungeon research and experimental timers

- Research coverage for **19 Vanilla dungeon maps**, including **190 documented encounter NPC IDs**.
- Research-backed experimental dungeon cast warnings where supported by evidence.
- **80 source-derived repeat-timer candidates across six dungeon maps**.
- Timer predictions start **after an observed matching NPC spell cast**; they do not guarantee a correct first-cast timer.
- Strict dungeon map, creature NPC ID and spell ID matching reduces unrelated warnings.
- Existing DBM boss modules remain available; custom Conquest Reborn mechanics may differ from stock DBM encounters.
- **Expanded Ascension-specific Zul'Gurub boss scripts are still in development**, not implemented in this build.

### Plug and play

- Dungeon Research, cast warnings and experimental source-repeat timers **enabled by default on fresh installations**.
- AutoLearner continues recording encounter evidence automatically.
- Normal operation requires **no slash commands, setup wizard or manual activation**.
- Existing saved on/off preferences are respected.
- In-game DBM interface remains available for adjustments.

### AutoLearner and compatible sharing

- Continues using the shared **`BBLC25C`** channel alongside compatible Questie-X and LootCollector builds.
- Keeps existing DBM-specific message protocols **`DCOAL31`** and **`DCOAR21`**, rather than introducing a new incompatible format.
- Preserves existing receiving, duplicate suppression and rate-limit behavior.
- Outgoing sharing is automatically restricted inside instances as previously designed.
- **Exact compatibility with every historical DBM-CoA version has not been verified**; older clients must understand the existing protocol.
- Sharing only occurs while the game and addon are running.

### UI, architecture and performance

- Preserves the original **multi-folder DBM architecture**, including core, GUI and load-on-demand encounter modules.
- Removes the discontinued `DBM-CoA-Observer` from the distributed package.
- Updates the visible DBM GUI footer to identify **DBM-CoA**, **Uncle Bone**, the GitHub maintainer and the CoA Research website.
- Designed for the default Blizzard UI, DragonUI and ElvUI environments; compatibility still needs in-game validation.
- Keeps existing raid modules, learner data and saved preferences.

## What DBM-CoA does

DBM-CoA adapts Deadly Boss Mods for the custom Conquest Reborn client. Supported encounters can provide boss warnings, countdown bars, sounds and on-screen alerts. Its **AutoLearner** records observed spell activity and timing patterns, saves evidence between sessions, and exchanges compatible discoveries with other players.

Research-backed candidate timers and learned predictions are **experimental**. Source schedules may not reflect the live realm, difficulty scaling, phases or modified encounters. Do not treat every listed dungeon or boss as having a complete, verified custom encounter module.

## Installation

1. Close WoW and back up SavedVariables.
2. **Delete `Interface/AddOns/DBM-CoA-Observer/` if it exists.**
3. Replace old DBM addon folders with the folders from the current release ZIP. Keep all supplied DBM folders alongside one another; do **not** combine them into one folder.
4. Start Conquest Reborn and play. The learner and new research features start automatically unless previously disabled in saved settings.

**Version note:** This README documents the **v5.0.3 development/test package**. A GitHub release is only available when it appears under [Releases](https://github.com/downingwow/DBM-CoA/releases).

## Known limits

- Dungeon research roster coverage is not the same as fully implemented boss warnings for all 19 dungeons.
- The 80 timer candidates are source-derived and **not live verified**.
- Custom Zul'Gurub Ascension-specific encounter scripts are **not yet integrated**.
- Legacy sharing across all older versions and default UI/DragonUI/ElvUI behavior need player testing.
- The discontinued Observer's separately saved data is not automatically merged into the AutoLearner.

## Credits, support and licensing

**CoA maintainer:** Uncle Bone · [GitHub: downingwow](https://github.com/downingwow)

**Research and addon hub:** https://coa-research.unclebone.workers.dev/

Based on [Deadly Boss Mods](https://github.com/DeadlyBossMods/DeadlyBossMods) and its upstream contributors. Required third-party licensing and attribution notices remain applicable. This is a community adaptation, not an official DBM or Ascension release.

[GitHub Releases](https://github.com/downingwow/DBM-CoA/releases) · [Issues](https://github.com/downingwow/DBM-CoA/issues)
