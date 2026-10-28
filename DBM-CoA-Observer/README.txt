DBM-CoA Overnight Observer v1 (companion to v3.4)

Passive extra encounter evidence: NPC/spell/event associations, first casts,
inter-cast interval statistics, target-health milestones, emotes, and fight boundaries.
Records are capped to protect memory and are saved in:
WTF/Account/<Account>/SavedVariables/DBM-CoA-Observer.lua

No additional chat channels, no extra outgoing messages, no changes to
DBM-CoA-Learner or DBM-Core. Existing v3.4 discovery and timing sharing remains
unchanged. This companion does NOT synchronize its detailed evidence; volunteers
can submit the SavedVariables file for deeper analysis.

Optional command: /dbmcoaobs status

Caveats: combat state may split boss fights; client event formats may differ;
health observations depend on player targeting. Data is research evidence,
not validated boss timers. Test on two clients before broad deployment.
