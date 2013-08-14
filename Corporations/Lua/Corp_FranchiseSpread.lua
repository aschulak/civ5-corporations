-- Corp_FranchiseSpread
-- Author: Envoy (@Fourfourhero)
-- DateCreated: 7/27/2013 12:37:58 AM
--------------------------------------------------------------

--
-- GLOBALS
--

local gT = MapModData.gT;

--
-- MAIN
--

-- executes franchise spread
-- GameEvents.PlayerDoTurn
function FranchiseSpread(iPlayer) 		
	--print("--FranchiseSpread");
	local gCorpHqOwners = gT.gCorpHqOwners;
	local player = Players[iPlayer];
	
	-- quit if player is minor civ or barbarian
	if player:IsMinorCiv() or player:IsBarbarian() then
		return;
	end
	
	-- quit if the player doesn't even have the Technology that allows corpoation spread
	if not HasCorporationSpreadAllowedTechnology(player) then
		return;
	end
	
	for corp in GameInfo.Corporations() do		
		local corpOwnerID = gCorpHqOwners[corp.ID];
		local corpOwner = Players[corpOwnerID];
		
		if corpOwner ~= nil and corpOwner:GetID() == iPlayer then
			local corpHq = GameInfo.Buildings[corp.HeadquartersBuildingType];
			local corpFranchise = GameInfo.Buildings[corp.FranchiseBuildingType];
			local hqCity = GetCityWithCorporationHq(corp, corpOwner);	
			ApplyFranchisePressure(corpOwner, corpHq, hqCity, corpFranchise);
			ConvertFranchisePressureIntoFans(corpFranchise);
			SpreadFranchisesToCities(corpFranchise);
		end	
	end
	
end

-- resets pressure and fans for a new city 
-- Events.SerialEventCityCreated
function ResetPressureAndFansForNewCities(hexPos, playerID, cityID, cultureType, eraType, continent, populationSize, size, fowState)
	print("--ResetPressureAndFansForNewCities");
	local player = Players[playerID];
	local city = player:GetCityByID(cityID);
	
	-- get previous owner of city
	local prevOwnerId = city:GetPreviousOwner();
	
	-- since unique city ids are based on plot x and y location, reset pressure and fans 
	-- for all new cities. this should prevent new cities being created on top of old 
	-- cities to start fresh
	if (prevOwnerId < 0) then
		print("No previous owner for city, resetting pressure and fans", city:GetName());
		for corp in GameInfo.Corporations() do
			local corpFranchise = GameInfo.Buildings[corp.FranchiseBuildingType];
			ResetPressureAndFansForCity(corpFranchise, city);
		end		
	end

end

--
-- HELPERS
--

function CalculatePressureToSpread(city, corpOwner, hqCity, corpHq)
	local cityPlayer = Players[city:GetOwner()];
	local cityTeam = Teams[cityPlayer:GetTeam()];
	local civHasHq = cityPlayer:GetID() == corpOwner:GetID();
	local hqTeam = Teams[corpOwner:GetTeam()];
	
	--print("-------------------");
	--print("--CalculatePressureToSpread");
	--print("city team", cityTeam:GetName());
	--print("hq team", hqTeam:GetName());

	-- minor modifiers
	local openBorders = false;	
	local isFriends = false; -- DoF for major
	local isAllies = false; -- allies for minor, defensive pact for major

	if not cityPlayer:IsMinorCiv() then
		-- civ
		openBorders = cityTeam:IsAllowsOpenBordersToTeam(hqTeam:GetID());
		isFriends = corpOwner:IsDoF(cityPlayer:GetID());
		isAllies = hqTeam:IsDefensivePact(cityTeam:GetID());		
	else
		-- city state
		openBorders = cityPlayer:IsPlayerHasOpenBorders(corpOwner:GetID());
		isFriends = cityPlayer:IsFriends(corpOwner:GetID());
		isAllies = cityPlayer:IsAllies(corpOwner:GetID());
	end
					
	-- major modifiers
	local corporationSpreadModifierFromTraits = GetCorporationSpreadModifierFromTraits(corpOwner);
	local corporationSpreadModifierFromBuildings = GetCorporationSpreadModifierFromBuildings(hqCity);
	local corporationSpreadModifierFromReligion = GetCorporationSpreadModifierFromReligion(corpOwner, city);
	local corporationSpreadModifierFromIdeologies = GetCorporationSpreadModifierFromIdeologies(corpOwner, cityPlayer);	
	
	--print("pressured city name", city:GetName());
	--print("hq civ", corpOwner:GetName());
	--print("hq city", hqCity:GetName());	
	--print("open borders?", tostring(openBorders));		
	--print("is friends?", tostring(isFriends));
	--print("is allies?", tostring(isAllies));
	--print("modifier from traits", corporationSpreadModifierFromTraits); 	
	--print("modifier from buildings", corporationSpreadModifierFromBuildings); 
	--print("modifier from religion", corporationSpreadModifierFromReligion);
	--print("modifier from ideologies", corporationSpreadModifierFromIdeologies); 

	-- start with base pressure
	local basePressure = GameInfo.CorporationSettings["BasePressureModifier"].Value;
	local pressure = basePressure;
	--print("base pressure", pressure);

	-- apply modifiers from game settings	
	if openBorders then
		pressure = pressure + round(pressure * GameInfo.CorporationSettings["OpenBordersPressureModifier"].Value / 100);
	else
		pressure = pressure + round(pressure * GameInfo.CorporationSettings["ClosedBordersPressureModifier"].Value / 100);
	end

	if isFriends then
		pressure = pressure + round(pressure * GameInfo.CorporationSettings["FriendsPressureModifier"].Value / 100);
	end

	if isAllies then
		pressure = pressure + round(pressure * GameInfo.CorporationSettings["AlliesPressureModifier"].Value / 100);
	end	

	-- traits
	pressure = pressure + round(pressure * corporationSpreadModifierFromTraits / 100);
	
	-- buildings
	pressure = pressure + round(pressure * corporationSpreadModifierFromBuildings / 100);	
	
	-- religion
	pressure = pressure + round(pressure * corporationSpreadModifierFromReligion / 100);
	
	-- ideologies
	pressure = pressure + round(pressure * corporationSpreadModifierFromIdeologies / 100);
	
	--print("pressure before dist", pressure);
	
	-- modify pressure based on distance
	local distance = Map.PlotDistance(city:GetX(), city:GetY(), hqCity:GetX(), hqCity:GetY());
	----print("distance", distance);
	local hqCivFranchiseSpreadRadius = GetFranchiseSpreadRadius(corpOwner);		
	----print("radius", hqCivFranchiseSpreadRadius);
	
	-- only use distance modifiers if the radius is limited
	if hqCivFranchiseSpreadRadius ~= -1 then	
		local corporationSpreadDistanceModifierFromBuildings = GetCorporationSpreadDistanceModifierFromBuildings(hqCity);
		----print("corporationSpreadDistanceModifierFromBuildings", corporationSpreadDistanceModifierFromBuildings);
		hqCivFranchiseSpreadRadius = hqCivFranchiseSpreadRadius + round(hqCivFranchiseSpreadRadius * corporationSpreadDistanceModifierFromBuildings / 100);
		--print("radius after building modifiers", hqCivFranchiseSpreadRadius);
	end
	
	-- reduce pressure based on how far away the city is from the corporation hq
	local distPercent = distance / hqCivFranchiseSpreadRadius;
	distPercent = round(distPercent * 100);
	
	-- max cap at 80
	if distPercent > 80 then
		distPercent = 80;
	end

	-- min cap at 1
	-- grants the effect that if the radius is unlimited, pressure spread is full and not reduced
	if distPercent < 1 then
		distPercent = 1;
	end
	
	----print("distance percent", distPercent);
	pressure = pressure - round((pressure * (distPercent / 100)));
	----print("pressure after dist", pressure);	
	--print("pressure final", pressure);
	return pressure;
end

function GetCitiesToSpreadFranchise(corpFranchise, corpOwner, hqCity)	
	local hqTeam = Teams[corpOwner:GetTeam()];
	local hqPressureRadius = GetFranchiseSpreadRadius(corpOwner); -- -1 means unlimited

	-- apply building distance modifiers
	if hqPressureRadius ~= -1 then
		local corporationSpreadDistanceModifierFromBuildings = GetCorporationSpreadDistanceModifierFromBuildings(hqCity);	
		hqPressureRadius = hqPressureRadius + round(hqPressureRadius * corporationSpreadDistanceModifierFromBuildings / 100);
	end
	
	local cities = {};	
	
	local cityCount = 1;
	for playerNum = 0, GameDefines.MAX_CIV_PLAYERS - 1 do
		local player = Players[playerNum];
		local team = Teams[player:GetTeam()];
		
		local playerIsValid = player ~= nil and player:IsAlive() and player:GetNumCities() > 0;
		local playerDoesNotOwnHq = player:GetID() ~= corpOwner:GetID();
		local playerHasMetHqOwner = hqTeam:IsHasMet(team);
				
		if (playerIsValid and playerDoesNotOwnHq and playerHasMetHqOwner) then
			for city in player:Cities() do
				local cityHasFranchise = city:GetNumBuilding(corpFranchise.ID) > 0;
				
				-- make sure pressure and fans gets reset to 0 if the city has a franchise
				if cityHasFranchise then
					--print("city already has franchise!");
					ResetPressureAndFansForCity(corpFranchise, city);
				end
				
				local cityCanBuildFranchise = CityCanBuildFranchise(city, corpFranchise);
				--print("can build", cityCanBuildFranchise);
				local distance = Map.PlotDistance(city:GetX(), city:GetY(), hqCity:GetX(), hqCity:GetY());
				local cityIsInRange = (hqPressureRadius == -1 or distance <= hqPressureRadius);
				--print("city is in range", tostring(cityIsInRange));
				
				if (not cityHasFranchise) and cityIsInRange and cityCanBuildFranchise then
					--print("can spread to", city:GetName());
					cities[cityCount] = city;
					cityCount = cityCount + 1;
				end
			end
		end
	end
	
	--print("num cities to spread ", cityCount - 1);
	return cities;
end

-- Increases the city's franchise pressure by the passed amount
function IncreaseFranchisePressure(city, corpFranchise, pressure)
	--print("--IncreaseFranchisePressure");
	local uniqueCityId = GetUniqueCityId(city);
	local gFranchiseCityPressureMap = gT.gFranchiseCityPressureMap;	
	local cityPressureMap = gFranchiseCityPressureMap[corpFranchise.Type] or {};	
	local currentCityPressure = cityPressureMap[uniqueCityId] or 0;
	cityPressureMap[uniqueCityId] = currentCityPressure + pressure;	
	gFranchiseCityPressureMap[corpFranchise.Type] = cityPressureMap;
end

-- Spreads calculated franchise pressure to a city
function SpreadFranchisePressure(city, corpOwner, hqCity, corpHq, corpFranchise)
	--print("--SpreadFranchisePressure");
	local pressure = CalculatePressureToSpread(city, corpOwner, hqCity, corpHq);
	IncreaseFranchisePressure(city, corpFranchise, pressure);
end

function ApplyFranchisePressure(corpOwner, corpHq, hqCity, corpFranchise)
	--print("--ApplyFranchisePressure");
	--print("corp franchise", corpFranchise.Type);
	local cities = GetCitiesToSpreadFranchise(corpFranchise, corpOwner, hqCity);	
	for i, city in ipairs(cities) do
		print("city", city:GetName());
		local cityPlayer = Players[city:GetOwner()];
		SpreadFranchisePressure(city, corpOwner, hqCity, corpHq, corpFranchise);		
	end
end

-- Increase number of franchise fans in a city by 1
function IncreaseFranchiseFans(city, corpFranchise)
	--print("IncreaseFranchiseFans");
	--print("city", city:GetName());
	--print("corp", corpFranchise.Type);

	local uniqueCityId = GetUniqueCityId(city);
	local gFranchiseCityFanMap = gT.gFranchiseCityFanMap;
	local cityFanMap = gFranchiseCityFanMap[corpFranchise.Type] or {};	
	local currentCityFans = cityFanMap[uniqueCityId] or 0;
	cityFanMap[uniqueCityId] = currentCityFans + 1;	
	gFranchiseCityFanMap[corpFranchise.Type] = cityFanMap;
end

function ConvertFranchisePressureIntoFans(corpFranchise)
	--print("--ConvertFranchisePressureIntoFans");
	--print("corpFranchise", corpFranchise.Type);
	
	local gFranchiseCityPressureMap = gT.gFranchiseCityPressureMap;		
	local pressureBucketSize = GetPressureBucketSize();
	
	cityPressureMap = gFranchiseCityPressureMap[corpFranchise.Type] or {};
	for uniqueCityId, pressure in pairs(cityPressureMap) do
		local city = GetCityById(uniqueCityId);
				
		if city ~= nil then
			if pressure >= pressureBucketSize then
				IncreaseFranchiseFans(city, corpFranchise);
				cityPressureMap[uniqueCityId] = 0;					
			end	
		else
			-- city might have been razed
			cityPressureMap[uniqueCityId] = nil;
		end				
	end
	
end

function BuildFranchiseAndNotify(city, corpFranchise)
	--print("--BuildFranchiseAndNotify");
	
	-- build
	city:SetNumRealBuilding(corpFranchise.ID, 1);
	
	-- notify	
	local franchiseName = Locale.ConvertTextKey(corpFranchise.Description);
	local header = franchiseName .. " Corporation spreads to " .. city:GetName() .. "!";
	local message = "Due to popular demand, the people of " .. city:GetName() .. " have built a " .. franchiseName .. " franchise.";
	--print(message);	
	local activePlayer = Players[Game.GetActivePlayer()];
	activePlayer:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, message, header, city:GetX(), city:GetY());
	
	-- TODO fix when custom notifications gets fixed
	-- local cityPlayer = Players[city:GetOwner()];
	--local plot = Map.GetPlot(city:GetX(), city:GetY());
	--local notificationTable = {{"Building1", corpFranchise.ID, 80, false, 0},{"Civ1", cityPlayer:GetID(), 45, false, 0}};
	--CustomNotification("CorpFranchiseSpread", header, message, plot, 0, "Yellow", notificationTable);
end

function SpreadFranchisesToCities(corpFranchise)	
	--print("--SpreadFranchisesToCities");
	local gFranchiseCityFanMap = gT.gFranchiseCityFanMap;
	
	cityFanMap = gFranchiseCityFanMap[corpFranchise.Type] or {};	
	for uniqueCityId, fans in pairs(cityFanMap) do
		local city = GetCityById(uniqueCityId);
		
		if city ~= nil then
			local population = city:GetPopulation();						
			if fans > 0 and fans >= round(population / 2) then
				BuildFranchiseAndNotify(city, corpFranchise);
				cityFanMap[uniqueCityId] = nil;
			end	
		else
			-- city might have been razed
			cityFanMap[uniqueCityId] = nil;			
		end
	end	
end

-- Can the city build the franchise?
function CityCanBuildFranchise(city, corpFranchise)
	--print("--CityCanBuildFranchise");
	local player = Players[city:GetOwner()];
	return player:CanConstruct(corpFranchise.ID) and city:CanConstruct(corpFranchise.ID);
end

-- how many tiles away can a corporation spread franchises to?
-- TODO the tech bonus should be separated out
function GetFranchiseSpreadRadius(player)
	
	-- Technologies can unlock unlimited spread distance
	if HasUnlimitedCorporationSpreadDistanceTechnology(player) then		
		return -1; 
	end	

	-- get world	
	local world = GameInfo.Worlds[Map.GetWorldSize()];
	
	-- get era	
	local era = GameInfo.Eras[player:GetCurrentEra()];	
	
	-- base radius based on world size
	local radius = world.CorporationSpreadDistance;	
	
	-- apply era modifier to radius
	radius = radius + round(radius * era.CorporationSpreadDistanceModifier / 100);
		
	return radius;
end

-- Get the pressure bucket size. Once a bucket is filled up a fan is created.
function GetPressureBucketSize()
	return GameInfo.GameSpeeds[PreGame.GetGameSpeed()].CorporationPressureNeededToCreateFan;
end

print("Corp_FranchiseSpread.lua loaded.");