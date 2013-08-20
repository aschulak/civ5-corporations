-- Corp_Bootstrap
-- Author: Envoy (@fourfourhero)
-- DateCreated: 8/10/2013 2:57:38 PM
--------------------------------------------------------------
include("Corp_Defines.lua");
include("Corp_Utils.lua");

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
	gT = LoadCorporationsData();
	MapModData.gT = gT; --probably redundant
	
	--PrintCorpOwnerRevenue();
	UpdateCorpHqOwners(nil);
	--PrintCorpHqOwners();
	UpdateCorpSharesOwners(nil);	
	--PrintCorpSharesOwners();
		
	MapModData.gCorpBootstrapInitted = true;
end