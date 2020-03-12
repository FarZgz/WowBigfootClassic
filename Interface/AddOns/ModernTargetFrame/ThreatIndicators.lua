--[[	Modern TargetFrame ThreatIndicators Module
	by SDPhantom
	https://www.wowinterface.com/forums/member.php?u=34145
	https://www.curseforge.com/members/sdphantomgamer/projects	]]
--------------------------------------------------------------------------

--------------------------
--[[	Namespace	]]
--------------------------
local AddOn=select(2,...);
AddOn.Options=AddOn.Options or {};

----------------------------------
--[[	Options Defaults	]]
----------------------------------
AddOn.Options.ThreatIndicatorNumber=true;
AddOn.Options.ThreatIndicatorGlow=true;

--------------------------
--[[	Library Loader	]]
--------------------------
local LibThreatClassic=LibStub and LibStub("LibThreatClassic2",true);
if not LibThreatClassic then return; end--	If there's a problem loading the library, stop here (we want option defaults to persist though)

--------------------------
--[[	Custom API	]]
--------------------------
local function UnitThreatPercentageOfLead(unit,mob)--	Hack to implement UnitThreatPercentageOfLead()
	local unitguid,mobguid=UnitGUID(unit),UnitGUID(mob);
	if not (unitguid and unitguid) then return nil; end

	local unitval=LibThreatClassic:GetThreat(unitguid,mobguid);
	if unitval>0 then
		local maxval=0;
		for otherguid in next,LibThreatClassic.threatTargets do
			if otherguid~=unitguid then
				local val=LibThreatClassic:GetThreat(otherguid,mobguid);
				if val>maxval then maxval=val; end
			end
		end
		return maxval>0 and 100*unitval/maxval or 100;
	else return 0; end
end

----------------------------------
--[[	Numerical Threat Frame	]]
----------------------------------
local ThreatFrame=CreateFrame("Frame",nil,TargetFrame);
ThreatFrame:SetPoint("BOTTOM",TargetFrame,"TOP",-50,-22);
ThreatFrame:SetSize(49,18);
ThreatFrame:Hide();

ThreatFrame.Text=ThreatFrame:CreateFontString(nil,"BACKGROUND","GameFontHighlight");
ThreatFrame.Text:SetPoint("TOP",0,-4);
ThreatFrame.Text:SetText("0%");

ThreatFrame.Background=ThreatFrame:CreateTexture(nil,"BACKGROUND");
ThreatFrame.Background:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");
ThreatFrame.Background:SetPoint("TOP",0,-3);
ThreatFrame.Background:SetSize(37,14);

do	local border=ThreatFrame:CreateTexture(nil,"ARTWORK");
	border:SetTexture("Interface\\TargetingFrame\\NumericThreatBorder");
	border:SetTexCoord(0,0.765625,0,0.5625);
	border:SetAllPoints(ThreatFrame);
end

----------------------------------
--[[	Threat Border Glow	]]
----------------------------------
local ThreatGlow=TargetFrame:CreateTexture(nil,"BACKGROUND");
ThreatGlow:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Flash");
ThreatGlow:SetTexCoord(0,0.9453125,0,0.181640625);
ThreatGlow:SetPoint("TOPLEFT",-24,0);
ThreatGlow:SetSize(242,93);
ThreatGlow:Hide();

--------------------------------------------------
--[[	Update Functions, Hooks, & Callbacks	]]
--------------------------------------------------
local function TargetFrame_UpdateThreat()
	local EnableNumeric,EnableGlow=AddOn.Options.ThreatIndicatorNumber,AddOn.Options.ThreatIndicatorGlow;
	if (EnableNumeric or EnableGlow) and UnitExists("target") and LibThreatClassic:IsActive() then
		local tanking,status,_,percent=LibThreatClassic:UnitDetailedThreatSituation("player","target");
		local r,g,b=LibThreatClassic:GetThreatStatusColor(status or 0);

		if EnableNumeric then
			if tanking then percent=UnitThreatPercentageOfLead("player","target"); end--	Hacked implementation pulling from LibThreatClassic
			if percent and percent>0 then
				ThreatFrame.Text:SetFormattedText("%.0f%%",percent);
				ThreatFrame.Background:SetVertexColor(r,g,b);
				ThreatFrame:Show();
			else ThreatFrame:Hide(); end
		else ThreatFrame:Hide(); end

		if EnableGlow and status and status>0 then
			ThreatGlow:SetVertexColor(r,g,b);
			ThreatGlow:Show();
		else ThreatGlow:Hide(); end
	else ThreatFrame:Hide(); ThreatGlow:Hide(); end--	Inactive
end

ThreatFrame:RegisterEvent("PLAYER_TARGET_CHANGED");
ThreatFrame:SetScript("OnEvent",TargetFrame_UpdateThreat);

local LTCIdentifier={};--	CallbackHandler-1.0 can take any value as an identifier, same identifiers overwrite each other on the same events
LibThreatClassic.RegisterCallback(LTCIdentifier,"Activate",TargetFrame_UpdateThreat);
LibThreatClassic.RegisterCallback(LTCIdentifier,"Deactivate",function() ThreatFrame:Hide(); ThreatGlow:Hide(); end);
LibThreatClassic.RegisterCallback(LTCIdentifier,"ThreatUpdated",function(event,unitguid,targetguid)
	if targetguid==UnitGUID("target") then TargetFrame_UpdateThreat(); end
end);
LibThreatClassic:RequestActiveOnSolo();

----------------------------------
--[[	Feature Registration	]]
----------------------------------
AddOn.RegisterFeature("ThreatIndicatorNumber",TargetFrame_UpdateThreat);
AddOn.RegisterFeature("ThreatIndicatorGlow",TargetFrame_UpdateThreat);
