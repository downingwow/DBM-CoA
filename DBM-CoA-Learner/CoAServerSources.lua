-- DBM-CoA major overhaul: source-derived encounter schedules from CoA AzerothCore fork.
-- These are runtime timer definitions, not merely informational reference records.
-- Range values are seconds; phase 2 is boss-dependent.
DBMCoAServerSources = DBMCoAServerSources or {}
DBMCoAServerSources[14517] = {name="High Priestess Jeklik", source="Conquest-of-AzerothCore/azerothcore-wotlk-coa:src/server/scripts/EasternKingdoms/ZulGurub/boss_jeklik.cpp", phaseTwoHealth=50, abilities={
 [12097]={phase=1,firstMin=5,firstMax=15,repeatMin=20,repeatMax=30},
 [16098]={phase=2,firstMin=5,firstMax=15,repeatMin=25,repeatMax=30},
 [22644]={phase=1,firstMin=5,firstMax=15,repeatMin=10,repeatMax=20},
 [22884]={phase=2,firstMin=25,firstMax=35,repeatMin=35,repeatMax=45},
 [22911]={phase=1,firstMin=10,firstMax=20,repeatMin=15,repeatMax=30},
 [23918]={phase=1,firstMin=5,firstMax=15,repeatMin=20,repeatMax=30},
 [23919]={phase=1,firstMin=20,firstMax=20,repeatMin=20,repeatMax=30},
 [23952]={phase=2,firstMin=10,firstMax=15,repeatMin=12,repeatMax=18},
 [23953]={phase=2,firstMin=10,firstMax=30,repeatMin=20,repeatMax=40},
 [23954]={phase=2,firstMin=25,firstMax=25,repeatMin=25,repeatMax=25},
}}
DBMCoAServerSources[14507] = {name="High Priest Venoxis", source="Conquest-of-AzerothCore/azerothcore-wotlk-coa:src/server/scripts/EasternKingdoms/ZulGurub/boss_venoxis.cpp", phaseTwoHealth=50, abilities={
 [3391]={phase=1,firstMin=8,firstMax=8,repeatMin=10,repeatMax=20},
 [23858]={phase=1,firstMin=5,firstMax=15,repeatMin=10,repeatMax=24},
 [23859]={phase=1,firstMin=35,firstMax=35,repeatMin=15,repeatMax=20},
 [23860]={phase=1,firstMin=10,firstMax=20,repeatMin=10,repeatMax=24},
 [23861]={phase=2,firstMin=10,firstMax=10,repeatMin=15,repeatMax=20},
 [23862]={phase=2,firstMin=5,firstMax=5,repeatMin=5,repeatMax=15},
 [23866]={phase=2,firstMin=30,firstMax=30,repeatMin=15,repeatMax=15},
 [23895]={phase=1,firstMin=30,firstMax=30,repeatMin=25,repeatMax=30},
 [23979]={phase=1,firstMin=15,firstMax=25,repeatMin=12,repeatMax=22},
}}
DBMCoAServerSources[14510] = {name="High Priestess Mar'li", source="Conquest-of-AzerothCore/azerothcore-wotlk-coa:src/server/scripts/EasternKingdoms/ZulGurub/boss_marli.cpp", phaseTwoHealth=0, abilities={
 [24082]={phase=1,firstMin=30,firstMax=30,repeatMin=20,repeatMax=20},
 [24099]={phase=1,firstMin=15,firstMax=15,repeatMin=10,repeatMax=20},
 [24109]={phase=1,firstMin=10,firstMax=20,repeatMin=20,repeatMax=40},
 [24110]={phase=2,firstMin=5,firstMax=5,repeatMin=15,repeatMax=20},
 [24111]={phase=2,firstMin=1,firstMax=1,repeatMin=25,repeatMax=35},
 [24112]={phase=2,firstMin=5,firstMax=10,repeatMin=10,repeatMax=10},
 [24300]={phase=1,firstMin=30,firstMax=30,repeatMin=20,repeatMax=50},
}}
DBMCoAServerSources[14834] = {name="Hakkar", source="Conquest-of-AzerothCore/azerothcore-wotlk-coa:src/server/scripts/EasternKingdoms/ZulGurub/boss_hakkar.cpp", phaseTwoHealth=0, abilities={
 [24318]={phase=1,firstMin=60,firstMax=60,repeatMin=90,repeatMax=90},
 [24324]={phase=1,firstMin=90,firstMax=90,repeatMin=90,repeatMax=90},
 [24327]={phase=1,firstMin=17,firstMax=17,repeatMin=35,repeatMax=40},
 [24328]={phase=1,firstMin=25,firstMax=25,repeatMin=30,repeatMax=40},
 [24686]={phase=1,firstMin=15,firstMax=15,repeatMin=45,repeatMax=45},
 [24687]={phase=1,firstMin=21,firstMax=21,repeatMin=24,repeatMax=24},
 [24688]={phase=1,firstMin=14,firstMax=14,repeatMin=16,repeatMax=18},
 [24689]={phase=1,firstMin=10,firstMax=10,repeatMin=15,repeatMax=15},
 [24690]={phase=1,firstMin=18,firstMax=18,repeatMin=10,repeatMax=15},
}}
