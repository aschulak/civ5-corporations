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

function CalculatePressureToSpread(city, corpOwner, hqCity, corpHq)
	local cityPlayer = Players[city:GetOwner()];
	local cityTeam = Teams[cityPlayer:GetTeam()];
	local civHasHq = cityPlayer:GetID() == corpOwner:GetID();
	local hqTeam = Teams[corpOwner:GetTeam()];
	
	print("-------------------");
	print("--CalculatePressureToSpread");
	print("city team", cityTeam:GetName());
	print("hq team", hqTeam:GetName());

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
	
	print("pressured city name", city:GetName());
	print("hq civ", corpOwner:GetName());
	print("hq city", hqCity:GetName());	
	print("open borders?", tostring(openBorders));		
	print("is friends?", tostring(isFriends));
	print("is allies?", tostring(isAllies));
	print("modifier from traits", corporationSpreadModifierFromTraits); 	
	print("modifier from buildings", corporationSpreadModifierFromBuildings); 
	print("modifier from religion", corporationSpreadModifierFromReligion);
	print("modifier from ideologies", corporationSpreadModifierFromIdeologies); 

	-- start with base pressure
	local basePressure = GameInfo.CorporationSettings["BasePressureModifier"].Value;
	local pressure = basePressure;
	print("base pressure", pressure);

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
	
	print("pressure before dist", pressure);
	
	-- modify pressure based on distance
	local distance = Map.PlotDistance(city:GetX(), city:GetY(), hqCity:GetX(), hqCity:GetY());
	print("distance", distance);
	local hqCivFranchiseSpreadRadius = GetFranchiseSpreadRadius(corpOwner);		
	print("radius", hqCivFranchiseSpreadRadius);
	
	local corporationSpreadDistanceModifierFromBuildings = GetCorporationSpreadDistanceModifierFromBuildings(hqCity);
	print("corporationSpreadDistanceModifierFromBuildings", corporationSpreadDistanceModifierFromBuildings);
	hqCivFranchiseSpreadRadius = hqCivFranchiseSpreadRadius + round(hqCivFranchiseSpreadRadius * corporationSpreadDistanceModifierFromBuildings / 100);
	print("radius after building modifiers", hqCivFranchiseSpreadRadius);
	
	-- reduce pressure based on how far away the city is from the corporation hq
	local distPercent = distance / hqCivFranchiseSpreadRadius;
	distPercent = round(distPercent * 100);
	
	-- max cap at 90
	if distPercent > 90 then
		distPercent = 90;
	end

	-- min cap at 1
	if distPercent < 1 then
		distPercent = 1;
	end
	
	print("distance percent", distPercent);
	pressure = pressure - round((pressure * (distPercent / 100)));
	print("pressure after dist", pressure);	
	print("pressure final", pressure);
	return pressure;
end

function GetCitiesToSpreadFranchise(corpFranchise, corpOwner, hqCity)	
	local hqTeam = Teams[corpOwner:GetTeam()];
	local hqPressureRadius = GetFranchiseSpreadRadius(corpOwner); -- -1 means unlimited
	-- TODO later version
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
				local distance = Map.PlotDistance(city:GetX(), city:GetY(), hqCity:GetX(), hqCity:GetY());
				local cityIsInRange = (hqPressureRadius == -1 or distance <= hqPressureRadius);
				print("city in range:" .. city:GetName() .. ":" .. tostring(cityIsInRange));
				if cityIsInRange and CityCanBuildFranchise(city, corpFranchise) then
					cities[cityCount] = city;
					cityCount = cityCount + 1;
				end
			end
		end
	end
	
	print("num cities to spread ", cityCount - 1);
	return cities;
end

-- Increases the city's franchise pressure by the passed amount
function IncreaseFranchisePressure(city, corpFranchise, pressure)
	local gFranchiseCityPressureMap = gT.gFranchiseCityPressureMap;	
	local cityPressureMap = gFranchiseCityPressureMap[corpFranchise.Type] or {};	
	local currentCityPressure = cityPressureMap[city:GetID()] or 0;
	cityPressureMap[city:GetID()] = currentCityPressure + pressure;	
	gFranchiseCityPressureMap[corpFranchise.Type] = cityPressureMap;
end

-- Increase number of franchise fans in a city by 1
function IncreaseFranchiseFans(city, corpFranchise)
	local gFranchiseCityFanMap = gT.gFranchiseCityFanMap;
	local cityFanMap = gFranchiseCityFanMap[corpFranchise.Type] or {};	
	local currentCityFans = cityFanMap[city:GetID()] or 0;
	cityFanMap[city:GetID()] = currentCityFans + 1;	
	gFranchiseCityFanMap[corpFranchise.Type] = cityFanMap;
end

-- Spreads calculated franchise pressure to a city
function SpreadFranchisePressure(city, cityPlayer, corpOwner, hqCity, corpHq, corpFranchise)
	print("--SpreadFranchisePressure");
	local pressure = CalculatePressureToSpread(city, corpOwner, hqCity, corpHq);
	IncreaseFranchisePressure(city, cityPlayer, corpFranchise, pressure);
end

function ApplyFranchisePressure(corpOwner, corpHq, hqCity, corpFranchise)
	print("--ApplyFranchisePressure");
	local cities = GetCitiesToSpreadFranchise(corpFranchise, corpOwner, hqCity);	
	for i, city in pairs(cities) do
		local cityPlayer = Players[city:GetOwner()];
		SpreadFranchisePressure(city, cityPlayer, corpOwner, hqCity, corpHq, corpFranchise);		
	end
end

function ConvertFranchisePressureIntoFans(corpFranchise)
	print("--ConvertFranchisePressureIntoFans");
	
	local gFranchiseCityPressureMap = gT.gFranchiseCityPressureMap;		
	local pressureBucketSize = GetPressureBucketSize();
	
	cityPressureMap = gFranchiseCityPressureMap[corpFranchise.Type] or {};
	for cityId, pressure in pairs(cityPressureMap) do
		local city = GetCityById(cityId);
		if pressure >= pressureBucketSize then
			print("converting pressure to a fan:" .. city:GetName() .. ":f[" .. corpFranchise.Type .."]");
			IncreaseFranchiseFans(city, corpFranchise);
			cityPressureMap[cityId] = 0;					
		end
	end
	
end

function BuildFranchiseAndNotify(city, corpFranchise)
	print("--BuildFranchiseAndNotify");
	
	-- build
	city:SetNumRealBuilding(corpFranchise.ID, 1);
	
	-- notify	
	local franchiseName = Locale.ConvertTextKey(corpFranchise.Description);
	local header = franchiseName .. " Corporation spreads to " .. city:GetName() .. "!";
	local message = "Due to popular demand, the people of " .. city:GetName() .. " have built a " .. franchiseName .. " franchise.";
	print(message);	
	local activePlayer = Players[Game.GetActivePlayer()];
	activePlayer:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, message, header, city:GetX(), city:GetY());
	
	-- TODO fix when custom notifications gets fixed
	-- local cityPlayer = Players[city:GetOwner()];
	--local plot = Map.GetPlot(city:GetX(), city:GetY());
	--local notificationTable = {{"Building1", corpFranchise.ID, 80, false, 0},{"Civ1", cityPlayer:GetID(), 45, false, 0}};
	--CustomNotification("CorpFranchiseSpread", header, message, plot, 0, "Yellow", notificationTable);
end

function SpreadFranchisesToCities(corpFranchise)	
	print("--SpreadFranchisesToCities");
	local gFranchiseCityFanMap = gT.gFranchiseCityFanMap;
	
	cityFanMap = gFranchiseCityFanMap[corpFranchise.Type] or {};	
	for cityId, fans in pairs(cityFanMap) do
		local city = GetCityById(cityId);
		local population = city:GetPopulation();						
		if fans >= round(population / 2) then
			BuildFranchiseAndNotify(city, corpFranchise);
			cityFanMap[cityId] = -1;
		end	
	end	
end

--
-- HELPERS
--

-- Can the city build the franchise?
function CityCanBuildFranchise(city, corpFranchise)
	local player = Players[city:GetOwner()];	
	return player:CanConstruct(corpFranchise.ID) and city:CanConstruct(corpFranchise.ID);
end

-- how many tiles away can a corporation spread franchises to?
-- return value of -1 means unlimited
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
	print("radius start", radius);
	
	-- apply era modifier to radius
	radius = radius + round(radius * era.CorporationSpreadDistanceModifier / 100);
		
	print("radius final", radius);
	return radius;
end

-- Get the pressure bucket size. Once a bucket is filled up a fan is created.
function GetPressureBucketSize()
	return GameInfo.GameSpeeds[PreGame.GetGameSpeed()].CorporationPressureNeededToCreateFan;
end

print("Corp_FranchiseSpread.lua loaded.");