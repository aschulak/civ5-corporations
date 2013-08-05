-- CorpTest
-- Author: Envoy (@fourfourhero)
-- DateCreated: 7/26/2013 8:35:47 PM
--------------------------------------------------------------
include("Corp_UI.lua");
include("Corp_Utils.lua");
include("Corp_FranchiseSpread.lua");
include("Corp_BuildingConstructs.lua");

--
-- GLOBALS
--

gSendNotifications = true;
gSendNotificationsTurnCounter = 5;

MapModData.gT = MapModData.gT or {};
local gT = MapModData.gT;
	
--
-- GAME EVENTS
--

-- cycle through all the players and store the owner for each corporation in global vars
function UpdateCorpHqOwners(iPlayer)
	print("--UpdateCorpHqOwners");
	local gCorpHqOwners = gT.gCorpHqOwners;
	
	for playerNum = 0, GameDefines.MAX_CIV_PLAYERS - 1 do
		local player = Players[playerNum];					
		if (player ~= nil and player:IsAlive() and not player:IsMinorCiv() and not player:IsBarbarian() and player:GetNumCities() > 0) then			
			--print("UCHO Player", player:GetName());		
			for corp in GameInfo.Corporations() do
				--print("UCHO Corp", corp.Type);
				local corpHq = GameInfo.Buildings[corp.HeadquartersBuildingType];
				if player:CountNumBuildings(corpHq.ID) > 0 then
					--print("UCHO Owns Hq");
					gCorpHqOwners[corp.ID] = player:GetID();
				end
			end
		end
	end	
end
GameEvents.PlayerDoTurn.Add(UpdateCorpHqOwners);

-- do franchise spread
function FranchiseSpread(iPlayer) 		
	print("--FranchiseSpread");
	local gCorpHqOwners = gT.gCorpHqOwners;
	local player = Players[iPlayer];
	
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

	--SaveFranchiseSpreadData();
	PrintFranchisePressureMap();
	PrintFranchiseFanMap();
end
GameEvents.PlayerDoTurn.Add(FranchiseSpread);

-- reward all corporation owners with their corporation revenue
function RewardCorporationOwners(iPlayer)
	print("--RewardCorporationOwners");
	local player = Players[iPlayer];
	
	-- quit if minor or barb
	if player:IsMinorCiv() or player:IsBarbarian() then
		return;
	end
		
	local gCorpHqOwners = gT.gCorpHqOwners;
	local gCorpOwnerRevenue = {};
	local gCorpCityRevenue = {};
	
	for corp in GameInfo.Corporations() do
		local corpOwnerID = gCorpHqOwners[corp.ID];
		local corpOwner = Players[corpOwnerID];
		local corpCity = GetCityWithCorporationHq(corp, corpOwner);
				
		if corpOwner ~= nil and corpOwner:GetID() == iPlayer then
			local franchiseCount, corporationRevenue = ProcessCorporationRevenue(corp);
			
			-- store for city UI tooltip. want to store the base, will add multiplier back in UI
			gCorpCityRevenue[corpCity:GetID()] = gCorpCityRevenue[corpCity:GetID()] or 0;
			gCorpCityRevenue[corpCity:GetID()] = gCorpCityRevenue[corpCity:GetID()] + corporationRevenue;
			gT.gCorpCityRevenue = gCorpCityRevenue;
			
			-- apply city gold modifier to revenue
			local goldModifier = corpCity:GetBaseYieldRateModifier(YieldTypes.YIELD_GOLD);
			corporationRevenue = corporationRevenue * (goldModifier / 100);
			corporationRevenue = round(corporationRevenue);
			
			-- store total with modifier for UI tooltip
			gCorpOwnerRevenue[corpOwner:GetID()] = gCorpOwnerRevenue[corpOwner:GetID()] or 0;
			gCorpOwnerRevenue[corpOwner:GetID()] = gCorpOwnerRevenue[corpOwner:GetID()] + corporationRevenue;
			gT.gCorpOwnerRevenue = gCorpOwnerRevenue;

			-- give the corp owner the gold
			corpOwner:ChangeGold(corporationRevenue);						
			print("gave " .. corpOwner:GetName() .. " " .. corporationRevenue .. " gold in corporation revenue.");

			local sendNotifications = ShouldSendNotifications();
			if sendNotifications then
				local corpHq = GameInfo.Buildings[corp.HeadquartersBuildingType];
				local corpFranchise = GameInfo.Buildings[corp.FranchiseBuildingType];
				
				local header = "Financial update from " .. Locale.ConvertTextKey(corpHq.Description);
				local message = 'You gain ' .. corporationRevenue .. ' [ICON_GOLD] Gold per turn from the ' .. franchiseCount .. ' ' .. Locale.ConvertTextKey(corpFranchise.Description) .. ' franchises in the world.';
				print(message);
				corpOwner:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, message, header);
				
				-- keep around in case someone fixes custom notifications
				--local hqCity = GetCityWithCorporationHq(gCorpHamburgerHqId, gPlayerWithHamburgerHq);
				--local notificationTable = {{"Building1", gCorpHamburgerHqId, 80, false, 0}}
				--CustomNotification("CorpFinancialUpdate", header, message, 0, hqCity, 0, notificationTable);
			end		
		end		
	end
	
end
GameEvents.PlayerDoTurn.Add(RewardCorporationOwners);

--
-- HELPERS
--

-- cycle through all players to determine how much gold in corporation revenue to collect
function ProcessCorporationRevenue(corp)
	print('--ProcessCorporationRevenue');
	print("corp", corp.Type);
	
	local corpFranchise = GameInfo.Buildings[corp.FranchiseBuildingType];
	local gCorpHqOwners = gT.gCorpHqOwners;
	local corpOwnerID = gCorpHqOwners[corp.ID];
	local corpOwner = Players[corpOwnerID];
	
	local totalFranchises = 0;
	local totalCorporationRevenue = 0;		
	
	for playerNum = 0, GameDefines.MAX_CIV_PLAYERS - 1 do		
		local player = Players[playerNum];
		if (player ~= nil and player:IsAlive() and player:GetNumCities() > 0) then		
			for city in player:Cities() do
				local buildingCount = city:GetNumBuilding(corpFranchise.ID);
				local corporationRevenue = 0;
				
				-- local
				if player:GetID() == corpOwner:GetID() then
					corporationRevenue = corp.LocalFranchiseGoldRevenue * buildingCount;
					corporationRevenue = corporationRevenue + round(corporationRevenue * (GetLocalFranchiseGoldRevenueModifier(corpOwner) / 100));
					
					-- apply modifier from buildings only for franchises of owned corporations
					corporationRevenue = corporationRevenue + round(corporationRevenue * (GetCorporationFranchiseGoldRevenueModifierFromBuildings(city) / 100));				
				else -- foreign
					corporationRevenue = corp.ForeignFranchiseGoldRevenue * buildingCount;
					corporationRevenue = corporationRevenue + round(corporationRevenue * (GetForeignFranchiseGoldRevenueModifier(corpOwner) / 100));			
				end				
								
				totalFranchises = totalFranchises + buildingCount;
				totalCorporationRevenue = totalCorporationRevenue + corporationRevenue;						
			end
		end
	end
		
	print("total franchises", totalFranchises);		
	print("total corp. revenue", totalCorporationRevenue);
	return totalFranchises, totalCorporationRevenue;
end

-- Should a notification be sent?
function ShouldSendNotifications()
	return gSendNotifications and (Game.GetGameTurn() % gSendNotificationsTurnCounter == 0)
end

print("Corporations.lua loaded.");
