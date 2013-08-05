-- Corp_Utils
-- Author: Envoy (@fourfourhero)
-- DateCreated: 7/27/2013 12:33:42 AM
--------------------------------------------------------------

--
-- GLOBALS
--
local gT = MapModData.gT;

--
-- INIT
--

MapModData.gCorpUtilsInitted = MapModData.gCorpUtilsInitted or false;
print("MapModData.gCorpUtilsInitted", MapModData.gCorpUtilsInitted);

-- only do this once regardless of how many times this file gets included
if not MapModData.gCorpUtilsInitted then
	-- store the buildings that have non-zero corporation spread modifiers for later use
	MapModData.gCorporationSpreadPressureBuildings = MapModData.gCorporationSpreadPressureBuildings or {};
	local i = 1;
	for building in GameInfo.Buildings() do
		if building.CorporationSpreadPressureModifier ~= 0 then
			MapModData.gCorporationSpreadPressureBuildings[i] = building;
			print("stored corp spread pressure building", building.Type);
		end
		i = i + 1;
	end	

	-- store the buildings that have non-zero corporation spread distance modifiers for later use
	MapModData.gCorporationSpreadDistanceBuildings = MapModData.gCorporationSpreadDistanceBuildings or {};
	local i = 1;
	for building in GameInfo.Buildings() do
		if building.CorporationSpreadDistanceModifier ~= 0 then
			MapModData.gCorporationSpreadDistanceBuildings[i] = building;
			print("stored corp spread distance building", building.Type);
		end
		i = i + 1;
	end	
	
	-- store the buildings that have non-zero corporation franchise gold modifiers for later use
	MapModData.gCorporationFranchiseGoldRevenueModifierBuildings = MapModData.gCorporationFranchiseGoldRevenueModifierBuildings or {};
	local i = 1;
	for building in GameInfo.Buildings() do
		if building.CorporationFranchiseGoldRevenueModifier ~= 0 then
			MapModData.gCorporationFranchiseGoldRevenueModifierBuildings[i] = building;
			print("stored corp franchise gold building", building.Type);
		end
		i = i + 1;
	end	
	
	MapModData.gCorpUtilsInitted = true;
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

-- look through all the players and return the city
function GetCityById(cityId)	
	
	for playerNum = 0, GameDefines.MAX_CIV_PLAYERS - 1 do
		local player = Players[playerNum];					
		if (player ~= nil and player:IsAlive() and player:GetNumCities() > 0) then			
			city = player:GetCityByID(cityId);
			if city ~= nil then				
				return city;
			end
		end
	end
		
	return nil;
end

-- get the city with a corporation building id
function GetCityWithCorporationHq(corp, playerWithCorporation)
	print("--GetCityWithCorporationHq");
		
	if playerWithCorporation == nil then
		print("ERROR should never happen");
		--playerWithCorporation = gCorpHqOwners[corp.ID];
		return nil;
	end		
	
	print("corp hq type", corp.HeadquartersBuildingType);
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
	print("--HasPolicy");
	for policy in GameInfo.Policies() do
		if policy.Type == policyType then
			return player:HasPolicy(policy.ID);
		end
	end
	return false;
end

-- Does the Player have all the policies in the Commerce tree?
function HasAllCommercePolicies(player)
	print("--HasAllCommercePolicies");	
	local commerce = "POLICY_COMMERCE";	
	local tradeUnions = "POLICY_TRADE_UNIONS";
	local entepreneurship = "POLICY_ENTREPRENEURSHIP";	
	local mercantilism = "POLICY_MERCANTILISM";
	local caravans = "POLICY_CARAVANS";	
	local protectionism = "POLICY_PROTECTIONISM";
	return HasPolicy(player, commerce) and HasPolicy(player, tradeUnions) and HasPolicy(player, entepreneurship) and HasPolicy(player, mercantilism) and HasPolicy(player, caravans) and HasPolicy(player, protectionism);	
end

-- Get the franchise pressure on a city
function GetPressureForCity(corpFranchise, city)
	local pressure = 0;
	
	local gFranchiseCityPressureMap = gT.gFranchiseCityPressureMap;		
	
	if gFranchiseCityPressureMap[corpFranchise.Type] ~= nil then		
		if gFranchiseCityPressureMap[corpFranchise.Type][city:GetID()] ~= nil then
			pressure = gFranchiseCityPressureMap[corpFranchise.Type][city:GetID()];
		end		
	end
	
	return pressure;
end

-- Get the franchise fans for a city
function GetFansForCity(corpFranchise, city)
	local fans = 0;
		
	local gFranchiseCityFanMap = gT.gFranchiseCityFanMap;
	
	if gFranchiseCityFanMap[corpFranchise.Type] ~= nil then		
		if gFranchiseCityFanMap[corpFranchise.Type][city:GetID()] ~= nil then				
			fans = gFranchiseCityFanMap[corpFranchise.Type][city:GetID()];
		end
	end
	
	return fans;
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
	print("--HasCorporationSpreadAllowedTechnology");
	
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
	print("--HasUnlimitedCorporationSpreadDistanceTechnology");
	
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
	print("--GetCorporationSpreadDistanceModifierFromBuildings");
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
	print("--GetCorporationSpreadModifierFromBuildings");
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
	print("--GetCorporationFranchiseGoldRevenueModifierFromBuildings");
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
	print("--GetCorporationSpreadModifierFromIdeologies");	
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
	print("--GetCorporationSpreadModifierFromTraits");	
	local leader = GameInfo.Leaders[player:GetLeaderType()];
	local leaderTrait = GameInfo.Leader_Traits("LeaderType ='" .. leader.Type .. "'")();
	local traitType = leaderTrait.TraitType;
	local trait = GameInfo.Traits[traitType];
	return trait.CorporationSpreadPressureModifier;
end

function GetCorporationSpreadModifierFromReligion(hqPlayer, city)
	print("--GetCorporationSpreadModifierFromReligion");	
	local modifier = 0;
	
	local religionId = hqPlayer:GetReligionCreatedByPlayer();
	print("religionId", religionId);
	if religionId > 0 then
		if religionId == city:GetReligiousMajority() then
			print("same religion as city");
			for i, beliefId in ipairs(Game.GetBeliefsInReligion(religionId)) do
				print("beliefId", beliefId);
				local belief = GameInfo.Beliefs[beliefId];
				print("belief type", belief.Type);
				print("belief csm", belief.CorporationSpreadPressureModifier);
				modifier = modifier + belief.CorporationSpreadPressureModifier;
			end
		end
	end
	
	print("religious mod", modifier);
	return modifier;
end

-- DEPRECATED? Shouldnt need this
function SaveFranchiseSpreadData()
	MapModData.gT = gT;
end

function PrintFranchisePressureMap()
	print("--PrintFranchisePressureMap");	
	local gFranchiseCityPressureMap = gT.gFranchiseCityPressureMap;
	
	for franchiseId, cityPressureMap in pairs(gFranchiseCityPressureMap) do					
		for cityId, pressure in pairs(cityPressureMap) do
			local city = GetCityById(cityId);
			print(city:GetName() .. " = f[" .. franchiseId .. "] Pressure:" .. pressure);
		end		
	end
	print("--PrintFranchisePressureMap DONE");	
end

function PrintFranchiseFanMap()
	print("--PrintFranchiseFanMap");	
	
	local gFranchiseCityFanMap = gT.gFranchiseCityFanMap;
	for franchiseId, cityFanMap in pairs(gFranchiseCityFanMap) do		
		for cityId, fan in pairs(cityFanMap) do
			local city = GetCityById(cityId);
			print(city:GetName() .. " = f[" .. franchiseId .. "] Fans:" .. fan);
		end		
	end
	print("--PrintFranchiseFanMap DONE");	
end

print("Corp_Utils.lua loaded.");