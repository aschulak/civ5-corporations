-- Corp_UI
-- Author: Envoy (@fourfourhero)
-- DateCreated: 7/28/2013 5:05:52 PM
--------------------------------------------------------------
include("Corp_Defines.lua");
include("Corp_Utils.lua");
include("TableSaverLoader.lua");

MapModData.gT = MapModData.gT or {};
local gT = MapModData.gT;

--
-- INIT
--
MapModData.gCorpUiInitted = MapModData.gCorpUiInitted or false;
print("MapModData.gCorpUiInitted", MapModData.gCorpUiInitted);

-- only do this once regardless of how many times this file gets included
if not MapModData.gCorpUiInitted then	
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

	-- print loaded data
	print("corp owners");
	for corpID, playerID in pairs(gT.gCorpHqOwners) do
		print(corpID, playerID);
	end
		
	print("revenue");
	for playerId, revenue in pairs(gT.gCorpOwnerRevenue) do
		print(playerId, revenue);
	end

	function SaveFranchiseSpreadData()
		print("--SaveFranchiseSpreadData");
		TableSave(gT, "CorporationsBNW");
	end
	GameEvents.PlayerDoTurn.Add(SaveFranchiseSpreadData);
	
	local gCorpHqOwners = gT.gCorpHqOwners;
		
	for playerNum = 0, GameDefines.MAX_CIV_PLAYERS - 1 do
		local player = Players[playerNum];					
		if (player ~= nil and player:IsAlive() and not player:IsMinorCiv() and not player:IsBarbarian() and player:GetNumCities() > 0) then			
			--print("ICHO Player", player:GetName());		
			for corp in GameInfo.Corporations() do
				--print("ICHO Corp", corp.Type);
				local corpHq = GameInfo.Buildings[corp.HeadquartersBuildingType];
				if player:CountNumBuildings(corpHq.ID) > 0 then
					--print("ICHO Owns Hq");
					gCorpHqOwners[corp.ID] = player:GetID();
				end
			end
		end
	end			
	
	MapModData.gCorpUiInitted = true;
end

--
-- UI CALLS
--

function GetCorporationCityTooltip(player, city)
	local tooltip = nil;
	
	-- Do Corp HQ listings first
	for corp in GameInfo.Corporations() do 
		local corpHq = GameInfo.Buildings[corp.HeadquartersBuildingType];
		local corpFranchise = GameInfo.Buildings[corp.FranchiseBuildingType];
			
		-- Is Corp HQ?
		if city:GetNumBuilding(corpHq.ID) > 0 then
			if tooltip == nil then 
				tooltip = "";
			end;
			tooltip = tooltip .. Locale.ConvertTextKey("TXT_KEY_CORP_TOOLTIP_HEADQUARTERS", corp.IconString, corpFranchise.Description) .. "[NEWLINE]";
		end
	end

	-- Do Corp franchises listings next
	for corp in GameInfo.Corporations() do 
		local corpFranchise = GameInfo.Buildings[corp.FranchiseBuildingType];
			
		if city:GetNumBuilding(corpFranchise.ID) > 0 then
			if tooltip == nil then 
				tooltip = "";
			end;
			tooltip = tooltip .. Locale.ConvertTextKey("TXT_KEY_CORP_TOOLTIP_FRANCHISE", corp.IconString, corpFranchise.Description) .. "[NEWLINE]";
		end
	end
	
	-- do pressure and fans last
	local gFranchiseCityPressureMap = gT.gFranchiseCityPressureMap;
	local gFranchiseCityFanMap = gT.gFranchiseCityFanMap;

	if gFranchiseCityPressureMap ~= nil and gFranchiseCityFanMap ~= nil then		
		for corp in GameInfo.Corporations() do 
			local corpHq = GameInfo.Buildings[corp.HeadquartersBuildingType];
			local corpFranchise = GameInfo.Buildings[corp.FranchiseBuildingType];

			local pressure = GetPressureForCity(corpFranchise, city);
			local fans = GetFansForCity(corpFranchise, city);
						
			if pressure > 0 or fans > 0 then
				if tooltip == nil then 
					tooltip = "";
				end;
				local fanDesc = "Fans";
				if fans == 1 then
					fanDesc = "Fan";
				end
				local pressureString =  fans .. " " .. fanDesc .. " (+" .. pressure .. " Pressure)";
				tooltip = tooltip .. Locale.ConvertTextKey("TXT_KEY_CORP_TOOLTIP_PRESSURED", corp.IconString, corpFranchise.Description, pressureString) .. "[NEWLINE]";				
			end			
		end
	end	
	
	return tooltip;
end

function GetCorporationRevenue(player)
	local gCorpOwnerRevenue = gT.gCorpOwnerRevenue;
	
	-- these are stored when rewarded for faster UI display
	return gCorpOwnerRevenue[player:GetID()] or 5;	
end

function GetCorporationRevenueForCity(city)
	local gCorpCityRevenue = gT.gCorpCityRevenue;
	
	return gCorpCityRevenue[city:GetID()] or 5;	
end

print("Corp_UI.lua loaded.");