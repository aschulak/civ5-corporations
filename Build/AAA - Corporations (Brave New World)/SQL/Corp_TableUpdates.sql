-- Buildings
ALTER TABLE Buildings ADD COLUMN 'CorporationOwnershipRequired' BOOLEAN DEFAULT 0;
ALTER TABLE Buildings ADD COLUMN 'CorporationHeadquartersCity' BOOLEAN DEFAULT 0;
ALTER TABLE Buildings ADD COLUMN 'CorporationSpreadPressureModifier' INTEGER DEFAULT 0;
ALTER TABLE Buildings ADD COLUMN 'CorporationSpreadDistanceModifier' INTEGER DEFAULT 0;
UPDATE Buildings SET CorporationSpreadDistanceModifier=25 WHERE Type='BUILDING_BROADCAST_TOWER';
UPDATE Buildings SET Help='TXT_KEY_BUILDING_BROADCAST_TOWER_CORP_HELP' WHERE Type='BUILDING_BROADCAST_TOWER';
UPDATE Buildings SET Strategy='TXT_KEY_BUILDING_BROADCAST_TOWER_CORP_STRATEGY' WHERE Type='BUILDING_BROADCAST_TOWER';
ALTER TABLE Buildings ADD COLUMN 'CorporationFranchiseGoldRevenueModifier' INTEGER DEFAULT 0;

-- Worlds
ALTER TABLE Worlds ADD COLUMN 'CorporationSpreadDistance' INTEGER DEFAULT 18; -- Set Standard as default for map size modders
UPDATE Worlds SET CorporationSpreadDistance=12 WHERE Type='WORLDSIZE_DUEL';
UPDATE Worlds SET CorporationSpreadDistance=12 WHERE Type='WORLDSIZE_TINY';
UPDATE Worlds SET CorporationSpreadDistance=15 WHERE Type='WORLDSIZE_SMALL';
UPDATE Worlds SET CorporationSpreadDistance=18 WHERE Type='WORLDSIZE_STANDARD';
UPDATE Worlds SET CorporationSpreadDistance=21 WHERE Type='WORLDSIZE_LARGE';
UPDATE Worlds SET CorporationSpreadDistance=24 WHERE Type='WORLDSIZE_HUGE';

-- Eras
ALTER TABLE Eras ADD COLUMN 'CorporationSpreadDistanceModifier' INTEGER DEFAULT 0;
UPDATE Eras SET CorporationSpreadDistanceModifier=33 WHERE Type='ERA_MODERN';
UPDATE Eras SET CorporationSpreadDistanceModifier=66 WHERE Type='ERA_POSTMODERN';
UPDATE Eras SET CorporationSpreadDistanceModifier=100 WHERE Type='ERA_FUTURE';

-- Game Speeds
ALTER TABLE GameSpeeds ADD COLUMN 'CorporationPressureNeededToCreateFan' INTEGER DEFAULT 3000; -- Set Standard as default for game speed modders
UPDATE GameSpeeds SET CorporationPressureNeededToCreateFan=1500 WHERE Type='GAMESPEED_QUICK';
UPDATE GameSpeeds SET CorporationPressureNeededToCreateFan=3000 WHERE Type='GAMESPEED_STANDARD';
UPDATE GameSpeeds SET CorporationPressureNeededToCreateFan=6000 WHERE Type='GAMESPEED_EPIC';
UPDATE GameSpeeds SET CorporationPressureNeededToCreateFan=12000 WHERE Type='GAMESPEED_MARATHON';

-- Technologies
ALTER TABLE Technologies ADD COLUMN 'AllowsCorporationSpread' BOOLEAN DEFAULT 0;
ALTER TABLE Technologies ADD COLUMN 'AllowsUnlimitedCorporationSpreadDistance' BOOLEAN DEFAULT 0; -- no distance restriction
UPDATE Technologies SET AllowsUnlimitedCorporationSpreadDistance=1 WHERE Type='TECH_GLOBALIZATION';

-- Policies
ALTER TABLE Policies ADD COLUMN 'CorporationLocalFranchiseGoldRevenueModifier' INTEGER DEFAULT 0;
ALTER TABLE Policies ADD COLUMN 'CorporationForeignFranchiseGoldRevenueModifier' INTEGER DEFAULT 0;
ALTER TABLE Policies ADD COLUMN 'SharedIdeologyCorporationSpreadPressureModifier' INTEGER DEFAULT 0;
ALTER TABLE Policies ADD COLUMN 'DifferentIdeologyCorporationSpreadPressureModifier' INTEGER DEFAULT 0;
UPDATE Policies SET CorporationLocalFranchiseGoldRevenueModifier=100 WHERE Type='POLICY_COMMERCE';
UPDATE Policies SET CorporationForeignFranchiseGoldRevenueModifier=100 WHERE Type='POLICY_PROTECTIONISM'; -- cheat for finisher

-- Traits
ALTER TABLE Traits ADD COLUMN 'CorporationSpreadPressureModifier' INTEGER DEFAULT 0;
UPDATE Traits SET CorporationSpreadPressureModifier=100 WHERE Type='TRAIT_RIVER_EXPANSION';
UPDATE Traits SET Description='TXT_KEY_TRAIT_RIVER_EXPANSION_CORP' WHERE Type='TRAIT_RIVER_EXPANSION';

-- Beliefs
ALTER TABLE Beliefs ADD COLUMN 'CorporationSpreadPressureModifier' INTEGER DEFAULT 0;