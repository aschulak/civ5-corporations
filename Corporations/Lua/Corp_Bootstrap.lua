-- Corp_Bootstrap
-- Author: Envoy (@fourfourhero)
-- DateCreated: 8/10/2013 2:57:38 PM
--------------------------------------------------------------
include("Corp_Defines.lua");
include("Corp_Utils.lua");
include("TableSaverLoader.lua");

--
-- GLOBALS
--

local gT = MapModData.gT;

--
-- INIT
--

MapModData.gCorpBootstrapInitted = MapModData.gCorpBootstrapInitted or false;
print("MapModData.gCorpBootstrapInitted", MapModData.gCorpBootstrapInitted);

-- only do this once regardless of how many times this file gets included
if not MapModData.gCorpBootstrapInitted then			
	-- load data
	local DBQuery = Modding.OpenSaveData().Query;
	local bNewGame = true;
	for row in DBQuery("SELECT name FROM sqlite_master WHERE name='CorporationsBNW_Info'") do
		if row.name then bNewGame = false end
	end
	if bNewGame then
		TableSave(gT, "CorporationsBNW");		
	else
		TableLoad(gT, "CorporationsBNW");		
	end	
	MapModData.gT = gT;

	-- TODO remove
	--gT.gFranchiseCityPressureMap = {};
	--gT.gFranchiseCityFanMap = {};	
	
	PrintCorpOwnerRevenue();
	UpdateCorpHqOwners(nil);
	PrintCorpHqOwners();
	UpdateCorpSharesOwners(nil);	
	PrintCorpSharesOwners();
	
	function SaveCorporationsData()
		print("--SaveCorporationsData");
		TableSave(gT, "CorporationsBNW");
	end
	GameEvents.PlayerDoTurn.Add(SaveCorporationsData);	
	
	MapModData.gCorpBootstrapInitted = true;
end