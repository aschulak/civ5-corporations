-- AdvertisingAgency
-- Author: Envoy (@fourfourhero)
-- DateCreated: 7/26/2013 11:11:06 PM
--------------------------------------------------------------

--
-- GLOBALS
--

local gT = MapModData.gT;

-- can the player contruct a franchise of one of the corporations?
function CanConstructFranchise(iPlayer, buildingTypeID)	
	local gCorpHqOwners = gT.gCorpHqOwners;
	local buildingType = GameInfo.Buildings[buildingTypeID].Type;
	
	--for corp in GameInfo.Corporations() do
	for corp in GameInfo.Corporations() do
		if buildingType == corp.FranchiseBuildingType then
			return gCorpHqOwners[corp.ID] ~= nil;
		end
	end		

	return true;
end
GameEvents.PlayerCanConstruct.Add(CanConstructFranchise);

-- can the player contruct a building that requires corporation ownership?
function CanConstructCorporationOwnershipRequiredBuilding(iPlayer, buildingTypeID)
	----print("--CanConstructCorporationOwnershipRequiredBuilding");	
	local gCorpHqOwners = gT.gCorpHqOwners;
	local corporationOwnershipRequired = GameInfo.Buildings[buildingTypeID].CorporationOwnershipRequired;
	
	if corporationOwnershipRequired == 1 then		
		for corp in GameInfo.Corporations() do			
			local corpOwnerID = gCorpHqOwners[corp.ID];
			local corpOwner = Players[corpOwnerID];

			--print("corpOwner", corpOwner);
			if corpOwner ~= nil then				
				if corpOwner:GetID() == iPlayer then
					return true;
				end
			end
		end
		return false;
	end
	
	return true;
end
GameEvents.PlayerCanConstruct.Add(CanConstructCorporationOwnershipRequiredBuilding);

-- can the player construct a building that requires a corporation headquarters be in that city?
function CanConstructCorporationHeadquartersCityBuilding(iPlayer, iCity, buildingTypeID)
	----print("--CanConstructCorporationHeadquartersCityBuilding");
	local gCorpHqOwners = gT.gCorpHqOwners;
	local corporationHeadquartersCity = GameInfo.Buildings[buildingTypeID].CorporationHeadquartersCity;
	
	if corporationHeadquartersCity == 1 then
		for corp in GameInfo.Corporations() do	
			local corpOwnerID = gCorpHqOwners[corp.ID];
			local corpOwner = Players[corpOwnerID];
			--print("corpOwner", corpOwner);
			if corpOwner ~= nil then				
				if corpOwner:GetID() == iPlayer then					
					local city = corpOwner:GetCityByID(iCity);
					local corpHq = GameInfo.Buildings[corp.HeadquartersBuildingType];
					if city:GetNumRealBuilding(corpHq.ID) > 0 then
						return true;
					end					
				end
			end
		end
		return false;
	end
	
	return true;
end
GameEvents.CityCanConstruct.Add(CanConstructCorporationHeadquartersCityBuilding);

print("Corp_BuildingConstructs.lua loaded.");