-- AdvertisingAgency
-- Author: Envoy (@fourfourhero)
-- DateCreated: 7/26/2013 11:11:06 PM
--------------------------------------------------------------

--
-- GLOBALS
--

local gT = MapModData.gT;

--
-- MAIN
--

-- can the player construct a franchise of one of the corporations?
-- GameEvents.PlayerCanConstruct
function CanConstructFranchise(iPlayer, buildingTypeID)
	--print("CanConstructFranchise");
	local gCorpHqOwners = gT.gCorpHqOwners;
	local buildingType = GameInfo.Buildings[buildingTypeID].Type;
		
	for corp in GameInfo.Corporations() do
		if buildingType == corp.FranchiseBuildingType then
			return gCorpHqOwners[corp.ID] ~= nil;
		end
	end		

	return true;
end

-- can the player construct a building that requires corporation ownership?
-- GameEvents.PlayerCanConstruct
function CanConstructCorporationOwnershipRequiredBuilding(iPlayer, buildingTypeID)
	--print("--CanConstructCorporationOwnershipRequiredBuilding");	
	local gCorpHqOwners = gT.gCorpHqOwners;
	local corporationOwnershipRequired = GameInfo.Buildings[buildingTypeID].CorporationOwnershipRequired;
	
	if corporationOwnershipRequired == 1 then		
		for corp in GameInfo.Corporations() do			
			local corpOwnerID = gCorpHqOwners[corp.ID];
			local corpOwner = Players[corpOwnerID];

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

-- can the player construct a building that requires a corporation headquarters be in that city?
-- GameEvents.CityCanConstruct
function CanConstructCorporationHeadquartersCityBuilding(iPlayer, iCity, buildingTypeID)
	--print("--CanConstructCorporationHeadquartersCityBuilding");
	local gCorpHqOwners = gT.gCorpHqOwners;
	local corporationHeadquartersCity = GameInfo.Buildings[buildingTypeID].CorporationHeadquartersCity;
	
	if corporationHeadquartersCity == 1 then
		for corp in GameInfo.Corporations() do	
			local corpOwnerID = gCorpHqOwners[corp.ID];
			local corpOwner = Players[corpOwnerID];
			
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

print("Corp_BuildingConstructs.lua loaded.");