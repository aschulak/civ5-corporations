-- Corp_Revenue
-- Author: Envoy (@fourfourhero)
-- DateCreated: 8/10/2013 1:48:46 PM
--------------------------------------------------------------

--
-- GLOBALS
--

local gT = MapModData.gT;
local gSendNotificationsTurnCounter = 5;

--
-- MAIN
--

-- reward all corporation owners with their corporation revenue
-- GameEvents.PlayerDoTurn
function RewardCorporationOwners(iPlayer)
	--print("--RewardCorporationOwners");
	local player = Players[iPlayer];
	
	-- quit if minor or barb
	if player:IsMinorCiv() or player:IsBarbarian() then
		return;
	end
			
	local gCorpHqOwners = gT.gCorpHqOwners;
	local gCorpSharesOwners = gT.gCorpSharesOwners;
	local gCorpOwnerRevenue = gT.gCorpOwnerRevenue;
	
	-- reset value for this turn
	gCorpOwnerRevenue[player:GetID()] = 0;
	
	for corpId, playerCorpShares in pairs(gCorpSharesOwners) do
		local corp = GameInfo.Corporations[corpId];
		local corpHqOwnerId = gCorpHqOwners[corpId];
		
		-- loop only if there is an owner of the hq
		if corpHqOwnerId ~= nil then						
			local corpHqOwner = Players[corpHqOwnerId];
			local corpCity = GetCityWithCorporationHq(corp, corpHqOwner);		

			for corpOwnerId, numCorpShares in pairs(playerCorpShares) do				
				local corpOwner = Players[corpOwnerId];
										
				if corpOwner ~= nil and corpOwner:GetID() == iPlayer and numCorpShares > 0 then
					local franchiseCount, corporationRevenue = ProcessCorporationRevenue(corp, corpOwner, numCorpShares);
										
					-- store total with modifier for UI tooltip
					gCorpOwnerRevenue[corpOwner:GetID()] = gCorpOwnerRevenue[corpOwner:GetID()] or 0;
					gCorpOwnerRevenue[corpOwner:GetID()] = gCorpOwnerRevenue[corpOwner:GetID()] + corporationRevenue;
					gT.gCorpOwnerRevenue = gCorpOwnerRevenue; -- probably not needed anymore

					-- give the corp owner the gold
					corpOwner:ChangeGold(corporationRevenue);						
					--print("gave " .. corpOwner:GetName() .. " " .. corporationRevenue .. " gold in corporation revenue.");

					local sendNotifications = ShouldSendNotifications();
					if sendNotifications then
						local corpHq = GameInfo.Buildings[corp.HeadquartersBuildingType];
						local corpFranchise = GameInfo.Buildings[corp.FranchiseBuildingType];
						
						local header = "Financial update from " .. Locale.ConvertTextKey(corpHq.Description);
						local message = 'You gain ' .. corporationRevenue .. ' [ICON_GOLD] Gold per turn from the ' .. franchiseCount .. ' ' .. Locale.ConvertTextKey(corpFranchise.Description) .. ' franchises in the world.';
						corpOwner:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, message, header);
						
						-- keep around in case someone fixes custom notifications
						--local hqCity = GetCityWithCorporationHq(gCorpHamburgerHqId, gPlayerWithHamburgerHq);
						--local notificationTable = {{"Building1", gCorpHamburgerHqId, 80, false, 0}}
						--CustomNotification("CorpFinancialUpdate", header, message, 0, hqCity, 0, notificationTable);
					end		
				end
			end
		end
	end
		
end

--
-- HELPERS
--

-- cycle through all players to determine how much gold in corporation revenue to collect
function ProcessCorporationRevenue(corp, corpSharesOwner, numCorpShares)
	--print('--ProcessCorporationRevenue');
	
	local corpFranchise = GameInfo.Buildings[corp.FranchiseBuildingType];
		
	local totalFranchises = 0;
	local totalCorporationRevenue = 0;		
	
	for playerNum = 0, GameDefines.MAX_CIV_PLAYERS - 1 do		
		local player = Players[playerNum];
		if (player ~= nil and player:IsAlive() and player:GetNumCities() > 0) then		
			for city in player:Cities() do
				local buildingCount = city:GetNumBuilding(corpFranchise.ID);
				local corporationRevenue = 0;
				
				-- local
				if player:GetID() == corpSharesOwner:GetID() then
					corporationRevenue = corp.LocalFranchiseGoldRevenuePerShare * buildingCount;
					corporationRevenue = corporationRevenue + round(corporationRevenue * (GetLocalFranchiseGoldRevenueModifier(corpSharesOwner) / 100));
					
					-- apply modifier from buildings only for franchises of owned corporations
					corporationRevenue = corporationRevenue + round(corporationRevenue * (GetCorporationFranchiseGoldRevenueModifierFromBuildings(city) / 100));				
				else -- foreign
					corporationRevenue = corp.ForeignFranchiseGoldRevenuePerShare * buildingCount;
					corporationRevenue = corporationRevenue + round(corporationRevenue * (GetForeignFranchiseGoldRevenueModifier(corpSharesOwner) / 100));			
				end				
								
				-- multiply by number of stock
				corporationRevenue = corporationRevenue * numCorpShares;
				
				totalFranchises = totalFranchises + buildingCount;
				totalCorporationRevenue = totalCorporationRevenue + corporationRevenue;						
			end
		end
	end
		
	--print("total franchises", totalFranchises);		
	--print("total corp. revenue", totalCorporationRevenue);
	return totalFranchises, totalCorporationRevenue;
end

-- Should a notification be sent?
function ShouldSendNotifications()
	return (Game.GetGameTurn() % gSendNotificationsTurnCounter == 0)
end

print("Corp_Revenue.lua loaded.");