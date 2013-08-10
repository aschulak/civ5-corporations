-- CorpTest
-- Author: Envoy (@fourfourhero)
-- DateCreated: 7/26/2013 8:35:47 PM
--------------------------------------------------------------
include("Corp_Bootstrap.lua");
include("Corp_Utils.lua");
include("Corp_Revenue.lua");
include("Corp_FranchiseSpread.lua");
include("Corp_BuildingConstructs.lua");

--
-- GLOBALS
--

local gT = MapModData.gT;
	
--
-- GAME EVENTS
--

GameEvents.PlayerDoTurn.Add(UpdateCorpHqOwners);
GameEvents.PlayerDoTurn.Add(UpdateCorpSharesOwners);
--GameEvents.PlayerDoTurn.Add(PrintCorpHqOwners);
--GameEvents.PlayerDoTurn.Add(PrintCorpSharesOwners);
--GameEvents.PlayerDoTurn.Add(PrintFranchisePressureMap);
--GameEvents.PlayerDoTurn.Add(PrintFranchiseFanMap);	
	
-- do franchise spread
GameEvents.PlayerDoTurn.Add(FranchiseSpread);

-- reward all corporation owners with their corporation revenue
GameEvents.PlayerDoTurn.Add(RewardCorporationOwners);

print("Corporations.lua loaded.");