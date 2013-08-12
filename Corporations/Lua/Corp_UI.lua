-- Corp_UI
-- Author: Envoy (@fourfourhero)
-- DateCreated: 7/28/2013 5:05:52 PM
--------------------------------------------------------------
include("Corp_Bootstrap.lua");
include("Corp_Utils.lua");

local gT = MapModData.gT;

--
-- MAIN
--

function GetCorporationCityTooltip(player, city)
	local tooltip = nil;
	
	-- TODO remove
	tooltip = "CityID " .. city:GetID() .. "[NEWLINE]";
	tooltip = tooltip .. "Unique CityID " .. GetUniqueCityId(city) .. "[NEWLINE]";
	
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
	--print("--GetCorporationRevenue");		
	local gCorpOwnerRevenue = gT.gCorpOwnerRevenue;
	
	-- these are stored when rewarded for faster UI display
	return gCorpOwnerRevenue[player:GetID()] or 0;	
end

print("Corp_UI.lua loaded.");