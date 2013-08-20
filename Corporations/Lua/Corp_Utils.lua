-- Corp_Utils
-- Author: Envoy (@fourfourhero)
-- DateCreated: 7/27/2013 12:33:42 AM
--------------------------------------------------------------
include("TableSaverLoader.lua");

--
-- GLOBALS
--

local gT = MapModData.gT;

--
-- INIT
--

MapModData.gCorpUtilsInitted = MapModData.gCorpUtilsInitted or false;
--print("MapModData.gCorpUtilsInitted", MapModData.gCorpUtilsInitted);

-- only do this once regardless of how many times this file gets included
if not MapModData.gCorpUtilsInitted then
	-- store the buildings that have non-zero corporation spread modifiers for later use
	MapModData.gCorporationSpreadPressureBuildings = MapModData.gCorporationSpreadPressureBuildings or {};
	local i = 1;
	for building in GameInfo.Buildings() do
		if building.CorporationSpreadPressureModifier ~= 0 then
			MapModData.gCorporationSpreadPressureBuildings[i] = building;
		end
		i = i + 1;
	end	

	-- store the buildings that have non-zero corporation spread distance modifiers for later use
	MapModData.gCorporationSpreadDistanceBuildings = MapModData.gCorporationSpreadDistanceBuildings or {};
	local i = 1;
	for building in GameInfo.Buildings() do
		if building.CorporationSpreadDistanceModifier ~= 0 then
			MapModData.gCorporationSpreadDistanceBuildings[i] = building;
		end
		i = i + 1;
	end	
	
	-- store the buildings that have non-zero corporation franchise gold modifiers for later use
	MapModData.gCorporationFranchiseGoldRevenueModifierBuildings = MapModData.gCorporationFranchiseGoldRevenueModifierBuildings or {};
	local i = 1;
	for building in GameInfo.Buildings() do
		if building.CorporationFranchiseGoldRevenueModifier ~= 0 then
			MapModData.gCorporationFranchiseGoldRevenueModifierBuildings[i] = building;
		end
		i = i + 1;
	end	
	
	MapModData.gCorpUtilsInitted = true;
end

--
-- DATA
--

function LoadCorporationsData()
	print("--LoadCorporationsData");
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
	
	return gT;
end

-- Save corp data
-- GameEvents.PlayerDoTurn
function SaveCorporationsData()
	--print("--SaveCorporationsData");
	local gT = MapModData.gT;
	TableSave(gT, "CorporationsBNW");
end

--
-- MAIN
--

-- update all the corp hq owners
-- GameEvents.PlayerDoTurn
function UpdateCorpHqOwners(iPlayer)
	--print("--UpdateCorpHqOwners");
	local gCorpHqOwners = gT.gCorpHqOwners;
				
	for playerNum = 0, GameDefines.MAX_CIV_PLAYERS - 1 do
		local player = Players[playerNum];					
		if (player ~= nil and player:IsAlive() and not player:IsMinorCiv() and not player:IsBarbarian() and player:GetNumCities() > 0) then			
			for corp in GameInfo.Corporations() do
				gCorpHqOwners[corp.ID] = gCorpHqOwners[corp.ID] or nil;
				local corpHq = GameInfo.Buildings[corp.HeadquartersBuildingType];
				if player:CountNumBuildings(corpHq.ID) > 0 then
					gCorpHqOwners[corp.ID] = player:GetID();
				end
			end
		end
	end	
end

-- update all the corp share owners
-- GameEvents.PlayerDoTurn
function UpdateCorpSharesOwners(iPlayer)
	--print("--UpdateCorpSharesOwners");
	local gCorpSharesOwners = gT.gCorpSharesOwners;
	
	for playerNum = 0, GameDefines.MAX_CIV_PLAYERS - 1 do
		local player = Players[playerNum];					
		if (player ~= nil and player:IsAlive() and not player:IsMinorCiv() and not player:IsBarbarian() and player:GetNumCities() > 0) then			
			
			for corp in GameInfo.Corporations() do
				local corpShares = GameInfo.Resources[corp.SharesResourceType];
				local numCorpShares = player:GetNumResourceTotal(corpShares.ID, true);
				gCorpSharesOwners[corp.ID] = gCorpSharesOwners[corp.ID] or {};
				gCorpSharesOwners[corp.ID][player:GetID()] = numCorpShares;
			end
		end
	end	
end

--
-- HELPERS
--

-- math!
function round(x)
  if x%2 ~= 0.5 then
    return math.floor(x+0.5);
  end
  return x-0.5;
end

-- from http://lua-users.org/wiki/SplitJoin
function split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
	 table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end

-- city ids are NOT unique, make a new one based on the x and y location
function GetUniqueCityId(city)	
	return city:GetX() .. ":" .. city:GetY();
end

-- look through all the players and return the city
-- cityId is unique id from above
function GetCityById(uniqueCityId)	
	----print("--GetCityById");
	local uniqueCityIdInfo = split(uniqueCityId, ":");	
	local cityX = tonumber(uniqueCityIdInfo[1]);
	local cityY = tonumber(uniqueCityIdInfo[2]);
		
	for playerNum = 0, GameDefines.MAX_CIV_PLAYERS - 1 do
		local player = Players[playerNum];					
		if (player ~= nil and player:IsAlive() and player:GetNumCities() > 0) then			
			for city in player:Cities() do				
				if city ~= nil and city:GetX() == cityX and city:GetY() == cityY then
					return city;
				end
			end
		end
	end
		
	return nil;
end

-- get the city with a corporation building id
function GetCityWithCorporationHq(corp, playerWithCorporation)
	--print("--GetCityWithCorporationHq");
		
	if playerWithCorporation == nil then
		return nil;
	end		
		
	local corpHq = GameInfo.Buildings[corp.HeadquartersBuildingType];	
	for city in playerWithCorporation:Cities() do
		if city:GetNumBuilding(corpHq.ID) > 0 then
			return city;
		end
	end
	
	return nil;
end

-- Does the Player have this Policy?
-- Borrowed from Emigration mod
function HasPolicy(player, policyType)	-- policyType is a string, e.g. "POLICY_LIBERTY"
	--print("--HasPolicy");
	for policy in GameInfo.Policies() do
		if policy.Type == policyType then
			return player:HasPolicy(policy.ID);
		end
	end
	return false;
end

-- Get the franchise pressure on a city
function GetPressureForCity(corpFranchise, city)
	local pressure = 0;
	
	local uniqueCityId = GetUniqueCityId(city);
	local gFranchiseCityPressureMap = gT.gFranchiseCityPressureMap;		
	
	if gFranchiseCityPressureMap[corpFranchise.Type] ~= nil then	
		local cityPressureMap = gFranchiseCityPressureMap[corpFranchise.Type];
		if cityPressureMap[uniqueCityId] ~= nil then
			pressure = cityPressureMap[uniqueCityId];
		end		
	end
	
	return pressure;
end

-- Get the franchise fans for a city
function GetFansForCity(corpFranchise, city)
	local fans = 0;
		
	local uniqueCityId = GetUniqueCityId(city);
	local gFranchiseCityFanMap = gT.gFranchiseCityFanMap;
	
	if gFranchiseCityFanMap[corpFranchise.Type] ~= nil then
		local cityFanMap = gFranchiseCityFanMap[corpFranchise.Type];
		if cityFanMap[uniqueCityId] ~= nil then				
			fans = cityFanMap[uniqueCityId];
		end
	end
	
	return fans;
end

-- reset pressure and fans to 0 for a city and corp
function ResetPressureAndFansForCity(corpFranchise, city)
	local uniqueCityId = GetUniqueCityId(city);
	local gFranchiseCityPressureMap = gT.gFranchiseCityPressureMap;	
	local cityPressureMap = gFranchiseCityPressureMap[corpFranchise.Type] or {};	
	cityPressureMap[uniqueCityId] = nil;
	local gFranchiseCityFanMap = gT.gFranchiseCityFanMap;
	local cityFanMap = gFranchiseCityFanMap[corpFranchise.Type] or {};
	cityFanMap[uniqueCityId] = nil;
end

-- Get the profit modifier for corporation profits from local franchises
function GetLocalFranchiseGoldRevenueModifier(player)
	local modifier = 0;
	
	for policy in GameInfo.Policies() do
		if player:HasPolicy(policy.ID) then
			modifier = modifier + policy.CorporationLocalFranchiseGoldRevenueModifier;
		end
	end
	
	return modifier;
end

-- Get the profit modifier for corporation profits from foreign franchises
function GetForeignFranchiseGoldRevenueModifier(player)
	local modifier = 0;
	
	for policy in GameInfo.Policies() do
		if player:HasPolicy(policy.ID) then			
			modifier = modifier + policy.CorporationForeignFranchiseGoldRevenueModifier;
		end
	end
		
	return modifier;
end

-- Does the Player have a Technology that allows the spread of corporations?
function HasCorporationSpreadAllowedTechnology(player)
	--print("--HasCorporationSpreadAllowedTechnology");
	
	-- quick cheat to save time
	local massMediaTech = GameInfo.Technologies["TECH_MASS_MEDIA"];
	if massMediaTech.AllowsCorporationSpread == 1 then
		local team = Teams[player:GetTeam()];
		if team:IsHasTech(massMediaTech.ID) then
			return true;
		end
	end
	
	-- continue on for modders
	for tech in GameInfo.Technologies() do
		if tech.AllowsCorporationSpread == 1 then
			local team = Teams[player:GetTeam()];
			if team:IsHasTech(tech.ID) then
				return true;
			end
		end
	end
	
	return false;
end

-- Does the Player have a Technology that allows unlimited Corporation spread distance?
function HasUnlimitedCorporationSpreadDistanceTechnology(player)
	--print("--HasUnlimitedCorporationSpreadDistanceTechnology");
	
	-- quick cheat to save time
	local globalTech = GameInfo.Technologies["TECH_GLOBALIZATION"];
	if globalTech.AllowsUnlimitedCorporationSpreadDistance == 1 then
		local team = Teams[player:GetTeam()];
		if team:IsHasTech(globalTech.ID) then
			return true;
		end
	end
	
	-- continue on for modders
	for tech in GameInfo.Technologies() do
		if tech.AllowsUnlimitedCorporationSpreadDistance == 1 then
			local team = Teams[player:GetTeam()];
			if team:IsHasTech(tech.ID) then
				return true;
			end
		end
	end
	
	return false;
end

-- spread distance modifier based on buildings
function GetCorporationSpreadDistanceModifierFromBuildings(city) 
	--print("--GetCorporationSpreadDistanceModifierFromBuildings");
	local modifier = 0;
	
	for i, building in pairs(MapModData.gCorporationSpreadDistanceBuildings) do		
		if city:GetNumBuilding(building.ID) > 0 then
			modifier = modifier + building.CorporationSpreadDistanceModifier;
		end
	end
	
	return modifier;
end

-- spread pressure modifier based on buildings
function GetCorporationSpreadModifierFromBuildings(city)
	--print("--GetCorporationSpreadModifierFromBuildings");
	local modifier = 0;
	
	for i, building in pairs(MapModData.gCorporationSpreadPressureBuildings) do		
		if city:GetNumBuilding(building.ID) > 0 then
			modifier = modifier + building.CorporationSpreadPressureModifier;
		end
	end
	
	return modifier;
end

-- spread distance modifier based on buildings
function GetCorporationFranchiseGoldRevenueModifierFromBuildings(city) 
	--print("--GetCorporationFranchiseGoldRevenueModifierFromBuildings");
	local modifier = 0;
		
	for i, building in pairs(MapModData.gCorporationFranchiseGoldRevenueModifierBuildings) do		
		if city:GetNumBuilding(building.ID) > 0 then
			modifier = modifier + building.CorporationFranchiseGoldRevenueModifier;
		end
	end
	
	return modifier;
end

-- Get the spread pressure modifier for civs with the same ideology
function GetSharedIdeologyCorporationSpreadPressureModifier(player)
	local modifier = 0;
	
	for policy in GameInfo.Policies() do
		if player:HasPolicy(policy.ID) then
			modifier = modifier + policy.SharedIdeologyCorporationSpreadPressureModifier;
		end
	end
	
	return modifier;
end

-- Get the spread pressure modifier for civs with the different ideology
function GetDifferentIdeologyCorporationSpreadPressureModifier(player)
	local modifier = 0;
	
	for policy in GameInfo.Policies() do
		if player:HasPolicy(policy.ID) then
			modifier = modifier + policy.DifferentIdeologyCorporationSpreadPressureModifier;
		end
	end
	
	return modifier;
end

function GetIdeology(player)
	local ideology = nil;

	local freedom = "POLICY_BRANCH_FREEDOM";	
	local autocracy = "POLICY_BRANCH_AUTOCRACY";	
	local order = "POLICY_BRANCH_ORDER";
	
	if player:IsPolicyBranchUnlocked(freedom) then
		ideology = freedom;
	elseif player:IsPolicyBranchUnlocked(autocracy) then
		ideology = autocracy;
	elseif player:IsPolicyBranchUnlocked(order) then
		ideology = order;
	end
	
	return ideology;
end

function GetCorporationSpreadModifierFromIdeologies(hqPlayer, cityPlayer)
	--print("--GetCorporationSpreadModifierFromIdeologies");	
	local modifier = 0;
	
	local hqIdeology = GetIdeology(hqPlayer);
	local cityIdeology = GetIdeology(cityPlayer);
	
	-- one of the players must have an ideology
	if hqIdeology ~= nil or cityIdeology ~= nil then
		if hqIdeology == cityIdeology then
			-- shared ideology
			modifier = GetSharedIdeologyCorporationSpreadPressureModifier(hqPlayer);
			modifier = modifier + GetSharedIdeologyCorporationSpreadPressureModifier(cityPlayer);
		else
			-- different ideology
			modifier = GetDifferentIdeologyCorporationSpreadPressureModifier(hqPlayer);
			modifier = modifier + GetDifferentIdeologyCorporationSpreadPressureModifier(cityPlayer);
		end						
	end
	
	return modifier;
end

function GetCorporationSpreadModifierFromTraits(player)
	--print("--GetCorporationSpreadModifierFromTraits");	
	local leader = GameInfo.Leaders[player:GetLeaderType()];
	local leaderTrait = GameInfo.Leader_Traits("LeaderType ='" .. leader.Type .. "'")();
	local traitType = leaderTrait.TraitType;
	local trait = GameInfo.Traits[traitType];
	return trait.CorporationSpreadPressureModifier;
end

function GetCorporationSpreadModifierFromReligion(hqPlayer, city)
	--print("--GetCorporationSpreadModifierFromReligion");	
	local modifier = 0;
	
	local religionId = hqPlayer:GetReligionCreatedByPlayer();
	if religionId > 0 then
		local rm = city:GetReligiousMajority();
		if religionId == city:GetReligiousMajority() then
			for i, beliefId in ipairs(Game.GetBeliefsInReligion(religionId)) do
				local belief = GameInfo.Beliefs[beliefId];
				modifier = modifier + belief.CorporationSpreadPressureModifier;
			end
		end
	end
	
	return modifier;
end

--
-- PRINT
--

function PrintFranchisePressureMap()
	print("--PrintFranchisePressureMap");	
	local gFranchiseCityPressureMap = gT.gFranchiseCityPressureMap;
	
	for franchiseId, cityPressureMap in pairs(gFranchiseCityPressureMap) do		
		print("---franchise id", franchiseId);
		for cityId, pressure in pairs(cityPressureMap) do
			print("----unique city id", cityId);
			print("----pressure", pressure);
			--local city = GetCityById(cityId);
			--print(city:GetName() .. " = f[" .. franchiseId .. "] Pressure:" .. pressure);
		end		
	end
	print("--PrintFranchisePressureMap DONE");	
end

function PrintFranchiseFanMap()
	print("--PrintFranchiseFanMap");	
	
	local gFranchiseCityFanMap = gT.gFranchiseCityFanMap;
	for franchiseId, cityFanMap in pairs(gFranchiseCityFanMap) do	
		print("---franchise id", franchiseId);	
		for cityId, fans in pairs(cityFanMap) do
			print("----unique city id", cityId);
			print("----fans", fans);
			--local city = GetCityById(cityId);
			----print(city:GetName() .. " = f[" .. franchiseId .. "] Fans:" .. fans);
		end		
	end
	print("--PrintFranchiseFanMap DONE");	
end


function PrintCorpHqOwners(iPlayer)
	print("--PrintCorpHqOwners");
	local gCorpHqOwners = gT.gCorpHqOwners;
	
	for corp in GameInfo.Corporations() do
		local playerId = gCorpHqOwners[corp.ID];	
		print("Corp: " .. corp.ID .. " - " .. tostring(playerId));		
	end
	
end

function PrintCorpSharesOwners(iPlayer)
	print("--PrintCorpSharesOwners");
	local gCorpSharesOwners = gT.gCorpSharesOwners;
	
	for corpId, playerCorpShares in pairs(gCorpSharesOwners) do
		for playerId, numCorpShares in pairs(playerCorpShares) do
			print("Corp: " .. corpId .. " - " .. playerId .. " #" .. numCorpShares);
		end
	end
	
end

function PrintCorpOwnerRevenue()
	print("--PrintCorpOwnerRevenue");
	local gCorpOwnerRevenue = gT.gCorpOwnerRevenue;
	for playerId, revenue in pairs(gCorpOwnerRevenue) do
		print("player id: " .. playerId .. " rev: " .. revenue);
	end	
end

print("Corp_Utils.lua loaded.");