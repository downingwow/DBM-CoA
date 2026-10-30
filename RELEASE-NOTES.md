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
