-----------------------------------------------------------------------------------------------
-- 			PDA: Personnel Data Accessor
-- 			By: Togglebutton
--			Thanks to: Sinalot, PacketDancer, Draftomatic
-----------------------------------------------------------------------------------------------
require "Window"
require "GameLib"
require "Unit"
require "GameLib"

-----------------------------------------------------------------------------------------------
-- PDA Module Definition
-----------------------------------------------------------------------------------------------
local PDA = {}
local RPCore
local GeminiColor
local GeminiRichText
local PerspectivePlates

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local ktLocalizationStrings = {
	enUS = {
		_name = "Name",
		_title = "Title",
		_species = "Species",
		_gender = "Gender",
		_age = "Age",
		_height = "Height",
		_build = "Build",
		_occupation = "Occupation",
		_description = "Description",
		_slashHelp = " \nPDA Help:\n----------------------------\nType /pda off to hide all nameplates.\nType /pda on to show nameplates.\nType /pda status [0-7] to change your RP Flag status.\nType /pda to show the main UI.",
	},
}

local karRaceToString = { [GameLib.CodeEnumRace.Human] 	= Apollo.GetString("RaceHuman"), [GameLib.CodeEnumRace.Granok] 	= Apollo.GetString("RaceGranok"), [GameLib.CodeEnumRace.Aurin] 	= Apollo.GetString("RaceAurin"), [GameLib.CodeEnumRace.Draken] = Apollo.GetString("RaceDraken"), [GameLib.CodeEnumRace.Mechari] 	= Apollo.GetString("RaceMechari"), [GameLib.CodeEnumRace.Chua] 	= Apollo.GetString("RaceChua"), [GameLib.CodeEnumRace.Mordesh] 	= Apollo.GetString("CRB_Mordesh"),}

local karGenderToString = { [0] = Apollo.GetString("CRB_Male"), [1] = Apollo.GetString("CRB_Female"), [2] = Apollo.GetString("CRB_UnknownType"),}

local ktNamePlateOptions = {
	nXoffset = 0,
	nYoffset = -50,
	bShowMyNameplate = true,
	bShowNames = true,
	bShowTitles = true,
	bScaleNameplates = false,
	nNameplateDistance = 50,
	nAnchor = 1,
}

local ktStateColors = {
	[0] = "ffffffff", -- white
	[1] = "ffffff00", --yellow
	[2] = "ff0000ff", --blue
	[3] = "ff00ff00", --green
	[4] = "ffff0000", --red
	[5] = "ff800080", --purple
	[6] = "ff00ffff", --cyan
	[7] = "ffff00ff", --magenta
}

local ktStyles = {
	{tag = "h1", font = "CRB_Interface14_BBO", color = "FF00FA9A", align = "Center"},
	{tag = "h2", font = "CRB_Interface12_BO", color = "FF00FFFF", align = "Left"},
	{tag = "h3", font = "CRB_Interface12_I", color = "FF00FFFF", align = "Left"},
	{tag = "p", font = "CRB_Interface12", color = "FF00FFFF", align = "Left"},
	{tag = "li", font = "CRB_Interface12", color = "FF00FFFF", align = "Left", bullet = "●", indent = "  "},
	{tag = "alien", font = "CRB_AlienMedium", color = "FF00FFFF", align = "Left"},
	{tag = "name", font = "CRB_Interface12_BO", color = "FF00FF7F", align = "Center"},
	{tag = "title", font = "CRB_Interface10", color = "FF00FFFF", align = "Center"},
	{tag = "csentry", font = "CRB_Header13_O", color = "FF00FFFF", align = "Left"},
	{tag = "cscontents", font = "CRB_Interface12_BO", color = "FF00FF7F", align = "Left"},
}

local ktRaceSprites =
{
	[GameLib.CodeEnumRace.Human] = {[0] = "CRB_CharacterCreateSprites:btnCharC_RG_HuM_ExFlyby", [1] = "CRB_CharacterCreateSprites:btnCharC_RG_HuF_ExFlyby", [2] = "CRB_CharacterCreateSprites:btnCharC_RG_HuM_DomFlyby", [3] = "CRB_CharacterCreateSprites:btnCharC_RG_HuF_DomFlyby"},
	[GameLib.CodeEnumRace.Granok] = {[0] = "CRB_CharacterCreateSprites:btnCharC_RG_GrMFlyby", [1] = "CRB_CharacterCreateSprites:btnCharC_RG_GrFFlyby"},
	[GameLib.CodeEnumRace.Aurin] = {[0] = "CRB_CharacterCreateSprites:btnCharC_RG_AuMFlyby", [1] = "CRB_CharacterCreateSprites:btnCharC_RG_AuFFlyby"},
	[GameLib.CodeEnumRace.Draken] = {[0] = "CRB_CharacterCreateSprites:btnCharC_RG_DrMFlyby", [1] = "CRB_CharacterCreateSprites:btnCharC_RG_DrFFlyby"},
	[GameLib.CodeEnumRace.Mechari] = {[0] = "CRB_CharacterCreateSprites:btnCharC_RG_MeMFlyby", [1] = "CRB_CharacterCreateSprites:btnCharC_RG_MeFFlyby"},
	[GameLib.CodeEnumRace.Chua] = {[0] = "CRB_CharacterCreateSprites:btnCharC_RG_ChuFlyby", [1] = "CRB_CharacterCreateSprites:btnCharC_RG_ChuFlyby"},
	[GameLib.CodeEnumRace.Mordesh] = {[0] = "CRB_CharacterCreateSprites:btnCharC_RG_MoMFlyby", [1] = "CRB_CharacterCreateSprites:btnCharC_RG_MoMFlyby"},
}

local ksVersion

-----------------------------------------------------------------------------------------------
-- Local Functions
-----------------------------------------------------------------------------------------------

local function DistanceToUnit(unitTarget)
	--if self.bUseDistance ~= true then return nil end
	
	local unitPlayer = GameLib.GetPlayerUnit()
	if type(unitTarget) == "string" then
		unitTarget = GameLib.GetPlayerUnitByName(tostring(unitTarget))
	end
	
	if not unitTarget or not unitPlayer then
		return 0
	end

	tPosTarget = unitTarget:GetPosition()
	tPosPlayer = unitPlayer:GetPosition()

	if tPosTarget == nil or tPosPlayer == nil then
		return 0
	end

	local nDeltaX = tPosTarget.x - tPosPlayer.x
	local nDeltaY = tPosTarget.y - tPosPlayer.y
	local nDeltaZ = tPosTarget.z - tPosPlayer.z

	local nDistance = math.floor(math.sqrt((nDeltaX ^ 2) + (nDeltaY ^ 2) + (nDeltaZ ^ 2)))
	return nDistance
end

local function GetLocale()
	local strCancel = Apollo.GetString(1)
	if strCancel == "Abbrechen" and ktLocalizationStrings["frFR"] then
		return "frFR"
	elseif strCancel == "Annuler" and ktLocalizationStrings["deDE"] then
		return "deDE"
	else
		return "enUS"
	end
end

local function strsplit(sep, str)
        local sep, fields = sep or ":", {}
        local pattern = string.format("([^%s]+)", sep)
        string.gsub(str ,pattern, function(c) fields[#fields+1] = c end)
        return fields
end

local function CompareVersionNumberTable(tVersionCurrent, tVersionChecking)
	local nVersionCurrent = tVersionCurrent[1];
	local nVersionChecking = tVersionChecking[1];
	nVersionCurrent = tonumber(nVersionCurrent) or 0;
	nVersionChecking = tonumber(nVersionChecking) or 0;

	if nVersionCurrent > nVersionChecking then
		return false;
	elseif nVersionCurrent < nVersionChecking then
		return true;
	else --  v1 = nVersionChecking
		table.remove(tVersionCurrent, 1);
		table.remove(tVersionChecking, 1);
		if #(tVersionCurrent) == 0 then
			return true;
		elseif #(tVersionChecking) == 0 then
			return false;
		else
			return CompareVersionNumberTable(tVersionCurrent, tVersionChecking);
		end
	end
end

local function CompareVersions(strVersionChecking)
	local strVersionCurrent = ksVersion
	if not (type(strVersionCurrent) == "string" or type(strVersionCurrent) == "number") then return false end
	if not (type(strVersionChecking) == "string" or type(strVersionChecking) == "number") then return false end
	local tVersionCurrent = strsplit(".", strVersionCurrent);
	local tVersionChecking = strsplit(".", strVersionChecking);
	return CompareVersionNumberTable(tVersionCurrent, tVersionChecking);
end

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function PDA:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    -- initialize variables here
	o.arUnit2Nameplate = {}
	o.arWnd2Nameplate = {}
	
	o.tStyles = {}
	o.tStateColors = {}
	o.tNamePlateOptions = {}
	
	for i,v in pairs(ktStyles) do
		o.tStyles[i] = v
	end
	
	for i,v in pairs(ktStateColors) do
		o.tStateColors[i] = v
	end
	
	for i,v in pairs(ktNamePlateOptions) do
		o.tNamePlateOptions[i] = v
	end
	
	o.bHideAllNameplates = false
	
	self.unitPlayer = GameLib.GetPlayerUnit()
    return o
end

function PDA:Init()
	local bHasConfigureButton = true
	local strConfigureButtonText = "PDA"
	local tDependencies = {
	--"RPCore",
	"GeminiColor",
	"GeminiRichText",
	"PerspectivePlates",
	}
    Apollo.RegisterAddon(self, bHasConfigureButton, strConfigureButtonText, tDependencies)
end

-----------------------------------------------------------------------------------------------
-- PDA Default Apollo Methods
-----------------------------------------------------------------------------------------------
function PDA:OnDependencyError(strDep, strError)
	if strDep == "PerspectivePlates" then
		return true
	else
		return false
	end
end

function PDA:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("PDA.xml")
	self.xmlDoc:RegisterCallback("OnDocumentLoaded", self)
	ksVersion = XmlDoc.CreateFromFile("toc.xml"):ToTable().Version
end

function PDA:OnDocumentLoaded()

	GeminiColor = Apollo.GetPackage("GeminiColor").tPackage
	GeminiRichText = Apollo.GetPackage("GeminiRichText").tPackage
	PerspectivePlates = Apollo.GetAddon("PerspectivePlates")
	RPCore = _G["GeminiPackages"]:GetPackage("RPCore-1.1")
	
	self.wndMain = Apollo.LoadForm(self.xmlDoc, "PDAEditForm", nil, self)
	self.wndMain:FindChild("wnd_Title"):SetText(string.format("PDA %s", ksVersion))
	self.wndMain:Show(false)
	self.wndMain:FindChild("btn_Help"):FindChild("wnd_DD"):Show(false)
	self.wndMain:FindChild("btn_DD_Status"):FindChild("wnd_DD"):Show(false)
	self.wndMain:FindChild("btn_LookupProfile"):SetCheck(true)
	self.wndMain:FindChild("wnd_EditProfile"):Show(false)
	self.wndMain:FindChild("wnd_LookupProfile"):Show(true)
	self.wndMain:FindChild("wnd_EditBackground"):Show(false)
	self.wndMarkupEditor = GeminiRichText:CreateMarkupEditControl(self.wndMain:FindChild("wnd_EditBackground:wnd_Editor"), "Holo", { nCharacterLimit = 2500, }, self)

	self.wndOptions = Apollo.LoadForm(self.xmlDoc, "OptionsForm", nil, self)
	self.wndStyleEditor = GeminiRichText:CreateMarkupStyleEditor(self.wndOptions:FindChild("group_Styles"):FindChild("wnd_Styles"), self.tStyles)
	self.wndOptions:FindChild("wnd_ScrollFrame:group_NameplatePosition"):FindChild("input_n_OffsetX"):SetMinMax(-200, 200, 0)
	self.wndOptions:FindChild("wnd_ScrollFrame:group_NameplatePosition"):FindChild("input_n_OffsetY"):SetMinMax(-200, 200, 0)
	self.wndOptions:Show(false)
	
	self.wndCS = Apollo.LoadForm(self.xmlDoc, "CharSheetForm", nil, self)
	self.wndCS:FindChild("wnd_Title"):SetText(string.format("PDA %s", ksVersion))
	self.wndCS:FindChild("btn_Help:wnd_DD"):Show(false)
	self.wndCS:FindChild("btn_BioLink:wnd_DD"):Show(false)
	self.wndCS:FindChild("btn_BioLink"):Enable(false)
	self.wndCS:Show(false)

	Apollo.LoadSprites("PDA_Sprites.xml", "PDA_Sprites")

	Apollo.RegisterEventHandler("UnitCreated","OnUnitCreated",self) 
	Apollo.RegisterEventHandler("UnitDestroyed","OnUnitDestroyed",self)
	Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", "OnInterfaceMenuListHasLoaded", self)
	Apollo.RegisterEventHandler("ToggleAddon_PDA", "OnPDAOn", self)
	Apollo.RegisterEventHandler("RPCore_VersionUpdated", "OnRPCoreCallback", self)
	Apollo.RegisterEventHandler("ChangeWorld", "OnWorldChange", self)

	Apollo.RegisterSlashCommand("pda", "OnPDASlashCommand", self)
	
	-- time, repeat, callback, self
	self.tmrNamePlareRefresh = ApolloTimer.Create(1, true, "RefreshPlates", self)
	self.tmrUpdateMyNameplate = ApolloTimer.Create(5, false, "UpdateMyNameplate", self)
	self.tmrRefreshCharacterSheet = ApolloTimer.Create(5, true, "UpdateCharacterSheet", self)
	self.tmrRefreshCharacterSheet:Stop()
	
	self.locale = GetLocale()
	--Event_FireGenericEvent("GenericEvent_PerspectivePlates_RegisterOffsets", -15 + self.tNamePlateOptions.nXoffset, -15 + self.tNamePlateOptions.nYoffset, 15 + self.tNamePlateOptions.nXoffset, 15 + self.tNamePlateOptions.nYoffset)
end

function PDA:OnInterfaceMenuListHasLoaded()
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", "PDA", {"ToggleAddon_PDA", "", "PDA_Sprites:RPIcon"})
end

function PDA:OnSave(eLevel)
	if (eLevel ~= GameLib.CodeEnumAddonSaveLevel.Account) then return nil end
	local tSavedData = {
		["tNamePlateOptions"] = {},
		["tStateColors"] = {},
		["tStyles"] = {},
	}
	
	for i,v in pairs(self.tNamePlateOptions) do
		tSavedData.tNamePlateOptions[i] = v
	end
	
	for i,v in pairs(self.tStateColors) do
		tSavedData.tStateColors[i] = v
	end
	
	for i,v in pairs(self.tStyles) do
		tSavedData.tStyles[i] = v
	end
	
	return tSavedData
end

function PDA:OnRestore(eLevel, tData)
	self.OldData = tData
	if tData.tNamePlateOptions then
		for i, v in pairs(tData.tNamePlateOptions) do
				self.tNamePlateOptions[i] = v
		end
	end
	
	if tData.tStateColors then
		for i, v in pairs(tData.tStateColors) do
			self.tStateColors[i] = v
		end
	end
	
	if tData.tStyles then
		for i, v in pairs(tData.tStyles) do
			self.tStyles[i] = v
		end
	end
end

function PDA:OnConfigure()
	self.wndOptions:Show(true)
end

-----------------------------------------------------------------------------------------------
-- PDA Functions
-----------------------------------------------------------------------------------------------
function PDA:OnPDAOn(strCommand, ...)
	self.wndMain:Invoke() -- show the window
end

function PDA:OnPDASlashCommand(strCommand, strArgs)
	local tArgs = strsplit(" ", string.lower(strArgs))
	if tArgs[1] == "on" then
		self.bHideAllNameplates = false
	elseif tArgs[1] == "off" then
		self.bHideAllNameplates = true
	elseif tArgs[1] == "status" then
		local rpState = tonumber(tArgs[2])
		RPCore:SetLocalTrait("rpflag",rpState)
	elseif tArgs[1] == "help" then
		Print(ktLocalizationStrings[self.locale]._slashHelp)
	else
		self.wndMain:Show(true)
	end
end

function PDA:ClearCache()
	RPCore:ClearCachedPlayerList()
end

-----------------------------------------------------------------------------------------------
-- PDA Nameplate Functions
-----------------------------------------------------------------------------------------------
function PDA:UpdateMyNameplate()
	self.unitPlayer = GameLib.GetPlayerUnit()
	if self.tNamePlateOptions.bShowMyNameplate then
		self:OnRPCoreCallback({player = self.unitPlayer:GetName()})
	end
end

function PDA:OnUnitCreated(unitNew)
	if not self.unitPlayer then
		self.unitPlayer = GameLib.GetPlayerUnit()
	end
	if unitNew:IsThePlayer() then
		self:OnRPCoreCallback({player = unitNew:GetName()})
	end
	if unitNew:IsACharacter() then
		for i, player in pairs(RPCore:GetCachedPlayerList()) do
			if unitNew:GetName() == player then
				self:OnRPCoreCallback({player = unitNew:GetName()})
			end
		end
		local rpVersion, rpAddons = RPCore:QueryVersion(unitNew:GetName())
	end
end

function PDA:OnWorldChange()
	for i, v in pairs(self.arUnit2Nameplate) do
		local wndNameplate = self.arUnit2Nameplate[i].wndNameplate
		wndNameplate:Destroy()
		self.arWnd2Nameplate[i] = nil
		self.arUnit2Nameplate[i] = nil
	end
	self.tmrUpdateMyNameplate:Start()
end

function PDA:OnRPCoreCallback(tArgs)
	local strUnitName = tArgs.player
	local unit = GameLib.GetPlayerUnitByName(strUnitName)
	if unit == nil then return end
	local idUnit = unit:GetId()
	if self.arUnit2Nameplate[idUnit] ~= nil and self.arUnit2Nameplate[idUnit].wndNameplate:IsValid() then
		return
	end
	
	local wnd = Apollo.LoadForm(self.xmlDoc, "OverheadForm", "InWorldHudStratum", self)
	wnd:Show(false, true)
	wnd:SetUnit(unit, self.tNamePlateOptions.nAnchor)
	wnd:SetName("wnd_"..strUnitName)
	
	local tNameplate =
	{
		unitOwner 		= unit,
		idUnit 			= unit:GetId(),
		unitName		= strUnitName,
		wndNameplate	= wnd,
		bOnScreen 		= wnd:IsOnScreen(),
		bOccluded 		= wnd:IsOccluded(),
		eDisposition	= unit:GetDispositionTo(self.unitPlayer),
		bShow			= false,
	}
	
	wnd:SetData(
		{
			unitName = strUnitName,
			unitOwner = unit,
		}
	)
	
	self.arUnit2Nameplate[idUnit] = tNameplate
	self.arWnd2Nameplate[wnd:GetId()] = tNameplate
	
	self:DrawNameplate(tNameplate)
end

function PDA:OnUnitDestroyed(unitOwner)
	if unitOwner:IsACharacter() then
		local idUnit = unitOwner:GetId()
		if self.arUnit2Nameplate[idUnit] == nil then
			return
		end
		
		local wndNameplate = self.arUnit2Nameplate[idUnit].wndNameplate
		
		self.arWnd2Nameplate[wndNameplate:GetId()] = nil
		wndNameplate:Destroy()
		self.arUnit2Nameplate[idUnit] = nil
	end
end

function PDA:ScaleNameplate(tNameplate)
	if tNameplate.unitOwner:IsThePlayer() then return end
	local wndNameplate = tNameplate.wndNameplate
	local nDistance = DistanceToUnit(tNameplate.unitOwner)
	local fDistancePercentage = ((self.tNamePlateOptions.nNameplateDistance / nDistance) - 0.5)
	if fDistancePercentage > 1 then
		fDistancePercentage = 1
	end
	wndNameplate:SetScale(fDistancePercentage)
end

function PDA:RefreshPlates()
	for idx, tNameplate in pairs(self.arUnit2Nameplate) do
		if self.bHideAllNameplates == true then
			tNameplate.wndNameplate:Show(false, false)
			tNameplate.bShow = false
		else
			local bNewShow = self:HelperVerifyVisibilityOptions(tNameplate) and (DistanceToUnit(tNameplate.unitOwner) <= self.tNamePlateOptions.nNameplateDistance)
			if bNewShow ~= tNameplate.bShow then
				tNameplate.wndNameplate:Show(bNewShow, false)
				tNameplate.bShow = bNewShow
			end
			self:DrawNameplate(tNameplate)
		end
	end
end

function PDA:HelperVerifyVisibilityOptions(tNameplate)
	local unitOwner = tNameplate.unitOwner
	local bHiddenUnit = not unitOwner:ShouldShowNamePlate()
	
	if bHiddenUnit then
		return false
	end
	
	if tNameplate.bOccluded or not tNameplate.bOnScreen then
		return false
	end
	
	if unitOwner:IsThePlayer() then
		return self.tNamePlateOptions.bShowMyNameplate
	end
	
	return true
end

function PDA:OnUnitOcclusionChanged(wndHandler, wndControl, bOccluded)
	local idUnit = wndHandler:GetId()
	if self.arWnd2Nameplate[idUnit] ~= nil then
		self.arWnd2Nameplate[idUnit].bOccluded = bOccluded
		self:UpdateNameplateVisibility(self.arWnd2Nameplate[idUnit])
	end
end

function PDA:UpdateNameplateVisibility(tNameplate)
	local bNewShow = self:HelperVerifyVisibilityOptions(tNameplate) and (DistanceToUnit(tNameplate.unitOwner) <= self.tNamePlateOptions.nNameplateDistance)
	if bNewShow ~= tNameplate.bShow then
		tNameplate.wndNameplate:Show(bNewShow, false)
		tNameplate.bShow = bNewShow
	end
end

function PDA:OnWorldLocationOnScreen(wndHandler, wndControl, bOnScreen)
	local idUnit = wndHandler:GetId()
	if self.arWnd2Nameplate[idUnit] ~= nil then
		self.arWnd2Nameplate[idUnit].bOnScreen = bOnScreen
	end
end

function PDA:DrawNameplate(tNameplate)
	
	if not tNameplate.bShow then
		return
	end
	
	local unitPlayer = self.unitPlayer
	local unitOwner = tNameplate.unitOwner
	local wndNameplate = tNameplate.wndNameplate

	tNameplate.eDisposition = unitOwner:GetDispositionTo(unitPlayer)
	
	if unitOwner:IsMounted() and wndNameplate:GetUnit() == unitOwner then
		wndNameplate:SetUnit(unitOwner:GetUnitMount(), 1)
	elseif not unitOwner:IsMounted() and wndNameplate:GetUnit() ~= unitOwner then
		wndNameplate:SetUnit(unitOwner, self.tNamePlateOptions.nAnchor)
	end

	local bShowNameplate = (DistanceToUnit(tNameplate.unitOwner) <= self.tNamePlateOptions.nNameplateDistance) and self:HelperVerifyVisibilityOptions(tNameplate)
	wndNameplate:Show(bShowNameplate, false)
	if not bShowNameplate then
		return
	end
	
	if self.tNamePlateOptions.nXoffset or self.tNamePlateOptions.nYoffset then
		wndNameplate:SetAnchorOffsets(-15 + (self.tNamePlateOptions.nXoffset or 0), -15 + (self.tNamePlateOptions.nYoffset or 0), 15 + (self.tNamePlateOptions.nXoffset or 0), 15 + (self.tNamePlateOptions.nYoffset or 0))
	end
	
	if self.tNamePlateOptions.bScaleNameplates == true then
		--if PerspectivePlates ~= nil then 
		--	PerspectivePlates:OnRequestedResize(tNameplate)
		--else
			self:ScaleNameplate(tNameplate)
		--end
	end
	
	--Event_FireGenericEvent("GenericEvent_PerspectivePlates_PerspectiveResize", tNameplate)
	
	self:DrawRPNamePlate(tNameplate)
end

function PDA:DrawRPNamePlate(tNameplate)
	local tRPColors, tCSColors
	local rpFullname, rpTitle, rpStatus
	local unitName = tNameplate.unitName
	local xmlNamePlate = XmlDoc:new()
	local wndNameplate = tNameplate.wndNameplate
	local wndData = wndNameplate:FindChild("wnd_Data")
	local btnRP = wndNameplate:FindChild("btn_RP")
	
	rpFullname = RPCore:GetTrait(unitName,"fullname") or unitName
	rpTitle = RPCore:FetchTrait(unitName,"title")
	rpStatus = RPCore:GetTrait(unitName, "rpflag")
	
	local strNameString = ""
	if self.tNamePlateOptions.bShowNames == true then
		strNameString = strNameString .. string.format("{name}%s{/name}\n", rpFullname)
		if self.tNamePlateOptions.bShowTitles == true and rpTitle ~= nil then
			strNameString = strNameString .. string.format("{title}%s{/title}", rpTitle)
		end	
	end
	
	local strNamePlate = GeminiRichText:ParseMarkup(strNameString, self.tStyles)

	wndData:SetAML(strNamePlate)
	wndData:SetHeightToContentHeight()
	
	if rpStatus == nil then rpStatus = 0 end
	
	local strState = RPCore:FlagsToString(rpStatus)
	local xmlTooltip = XmlDoc.new()
	xmlTooltip:StartTooltip(Tooltip.TooltipWidth)
	if self.tNamePlateOptions.bShowNames == false then
		xmlTooltip:AddLine(rpFullname, "FF009999", "CRB_InterfaceMedium_BO")
		if self.tNamePlateOptions.bShowTitles == true and rpTitle ~= nil then
			xmlTooltip:AddLine(rpTitle, "FF99FFFF", "CRB_InterfaceMedium_BO")
		end
		xmlTooltip:AddLine("――――――――――――――――――――", "FF99FFFF", "CRB_InterfaceMedium_BO")
	end
	xmlTooltip:AddLine(strState, self.tStateColors[rpStatus], "CRB_InterfaceMedium_BO")
	btnRP:SetTooltipDoc(xmlTooltip)
	btnRP:SetBGColor(self.tStateColors[rpStatus] or "FFFFFFFF")
end

-----------------------------------------------------------------------------------------------
-- PDA Character Sheet Functions
-----------------------------------------------------------------------------------------------

function PDA:OnCharacterSheetShow(wndHandler, wndControl)
	if wndHandler ~= wndControl then return end
	self.tmrRefreshCharacterSheet:Start()
end

function PDA:OnCharacterSheetClose(wndHandler, wndControl)
	if wndHandler ~= wndControl then return end
	self.tmrRefreshCharacterSheet:Stop()
end

function PDA:DrawCharacterProfile(unitName, unit)

	local rpFullname, rpTitle, rpShortDesc, rpStateString, rpHeight, rpWeight, rpAge, rpRace, rpGender, rpJob
	local xmlCS = XmlDoc.new()
	
	if not unit then
		unit = GameLib.GetPlayerUnitByName(unitName)
	end
	
	local strCharacterSheet = ""
	local strParsedSheet
	
	rpFullname = RPCore:GetTrait(unitName,"fullname") or unitName
	
	rpTitle = RPCore:FetchTrait(unitName,"title")
	rpShortDesc = RPCore:GetTrait(unitName,"shortdesc")
	rpHeight = RPCore:GetTrait(unitName,"height")
	rpWeight = RPCore:GetTrait(unitName,"weight")
	rpAge = RPCore:GetTrait(unitName,"age")
			
	if unit then
		rpRace = RPCore:GetTrait(unitName, "race") or karRaceToString[unit:GetRaceId()]
		rpGender = RPCore:GetTrait(unitName, "gender") or karGenderToString[unit:GetGender()]
		rpJob = RPCore:GetTrait(unitName,"job") or GameLib.CodeEnumClass[unit:GetClassId()]
	else
		rpRace = RPCore:GetTrait(unitName, "race")
		rpGender = RPCore:GetTrait(unitName, "gender")
		rpJob = RPCore:GetTrait(unitName,"job")
	end
	

	local strLabelColor = "FF009999"
	local strEntryColor = "FF99FFFF"
	
	if (rpFullname ~= nil) then
		strCharacterSheet = strCharacterSheet .. string.format("{csentry}%s:{cscontents}  %s{/cscontents}{/csentry}", ktLocalizationStrings[self.locale]._name, rpFullname)
	end
	
	if (rpTitle ~= nil) then
		strCharacterSheet = strCharacterSheet .. string.format("{csentry}%s:{cscontents}  %s{/cscontents}{/csentry}", ktLocalizationStrings[self.locale]._title, rpTitle)
	end
	
	if (rpRace ~= nil) then 
		if type(rpRace) == "string" then
			strCharacterSheet = strCharacterSheet .. string.format("{csentry}%s:{cscontents}  %s{/cscontents}{/csentry}", ktLocalizationStrings[self.locale]._species , rpRace)
		elseif type(rpRace) == "number" then
			strCharacterSheet = strCharacterSheet.. string.format("{csentry}%s:{cscontents}  %s{/cscontents}{/csentry}", ktLocalizationStrings[self.locale]._species , karRaceToString[rpRace])
		end
	end
	
	if (rpGender ~= nil) then strCharacterSheet = strCharacterSheet..string.format("{csentry}%s:{cscontents}  %s{/cscontents}{/csentry}", ktLocalizationStrings[self.locale]._gender ,rpGender) end
	if (rpAge ~= nil) then strCharacterSheet = strCharacterSheet.. string.format("{csentry}%s:{cscontents}  %s{/cscontents}{/csentry}", ktLocalizationStrings[self.locale]._age ,  rpAge) end
	if (rpHeight ~= nil) then strCharacterSheet = strCharacterSheet..string.format("{csentry}%s:{cscontents}  %s{/cscontents}{/csentry}", ktLocalizationStrings[self.locale]._height ,  rpHeight) end
	if (rpWeight ~= nil) then strCharacterSheet = strCharacterSheet..string.format("{csentry}%s:{cscontents}  %s{/cscontents}{/csentry}", ktLocalizationStrings[self.locale]._build ,  rpWeight) end
	if (rpJob ~= nil) then strCharacterSheet = strCharacterSheet..string.format("{csentry}%s:{cscontents}  %s{/cscontents}{/csentry}", ktLocalizationStrings[self.locale]._occupation ,  rpJob) end
	if (rpShortDesc ~= nil) then strCharacterSheet = strCharacterSheet..string.format("{csentry}%s:{/csentry}{cscontents}%s{/cscontents}", ktLocalizationStrings[self.locale]._description ,  rpShortDesc) end
	
	strParsedSheet = GeminiRichText:ParseMarkup(strCharacterSheet, self.tStyles)
	
	return strParsedSheet

end

function PDA:DrawCharacterBio(unitName, unit)
	local  bPublicHistory, rpHistory, strParsedSheet
	bPublicHistory = RPCore:GetTrait(unitName, "publicBio") or false
	rpHistory = RPCore:GetTrait(unitName, "biography")
	Print(rpHistory)
	if bPublicHistory == true and rpHistory ~= nil then
		strParsedSheet = GeminiRichText:ParseMarkup(rpHistory, self.tStyles)
		return strParsedSheet
	else
		self:DrawCharacterProfile(unitName, unit)
	end

end

function PDA:OnProfileClick( wndHandler, wndControl, eMouseButton )
	local unitName = wndControl:GetParent():GetData()
	local strProfile = self:DrawCharacterProfile(unitName)
	self.wndCS:FindChild("wnd_CharSheet"):SetAML(strProfile)
	self.wndCS:FindChild("wnd_CharSheet"):SetData("profile")
end

function PDA:OnBioClick( wndHandler, wndControl, eMouseButton )
	local unitName = wndControl:GetParent():GetData()
	local strBio = self:DrawCharacterBio(unitName)
	if strBio and type(strBio) == "string" then
		self.wndCS:FindChild("wnd_CharSheet"):SetAML(strBio)
		self.wndCS:FindChild("wnd_CharSheet"):SetData("bio")
	end
end

function PDA:CreateCharacterSheet(wndHandler, wndControl)
	local tNameplate = wndControl:GetParent():GetData()
	local unit = tNameplate.unitOwner
	local unitName = tNameplate.unitName
	local bPublicBio = RPCore:GetTrait(unitName, "publicBio")
	self.wndCS:FindChild("btn_ShowBio"):Enable(bPublicBio)
	self.wndCS:SetData(unitName)
	self.wndCS:FindChild("wnd_CharSheet"):SetAML(self:DrawCharacterProfile(unitName, unit))
	self.wndCS:FindChild("btn_TogglePortrait"):FindChild("cstmwnd_Portrait"):SetCostume(unit)
	self.wndCS:FindChild("btn_TogglePortrait"):FindChild("cstmwnd_Portrait"):SetOpacity(0.6)
	self.wndCS:Show(true)
	self.wndCS:ToFront()
end

function PDA:UpdateCharacterSheet()
	local player = self.wndCS:GetData()
	local strContentType = self.wndCS:FindChild("wnd_CharSheet"):GetData()
	local bPublicBio = RPCore:GetTrait(player, "publicBio")
	local strBio = RPCore:GetTrait(player, "biography")
	local strURL = RPCore:GetTrait(player, "URL")
	
	self.wndCS:FindChild("btn_ShowBio"):Enable(bPublicBio and not (strBio == nil))
	self.wndCS:FindChild("btn_BioLink"):Enable(not (strURL == nil))
	
	if strURL ~= nil then
		self.wndCS:FindChild("btn_BioLink"):FindChild("wnd_DD"):FindChild("wnd_URL"):SetText(strURL)
	end
	
	if strContentType == "bio" then
		self.wndCS:FindChild("wnd_CharSheet"):SetAML(self:DrawCharacterBio(player))
	elseif strContentType == "profile" then
		self.wndCS:FindChild("wnd_CharSheet"):SetAML(self:DrawCharacterProfile(player))
	else
		self.wndCS:FindChild("wnd_CharSheet"):SetAML(self:DrawCharacterProfile(player))
	end
end

function PDA:OnRotateRight(wndHandler, wndControl)
	if wndHandler ~= wndControl then return end
	wndControl:GetParent():ToggleLeftSpin(true)
end

function PDA:OnRotateRightCancel(wndHandler, wndControl)
	if wndHandler ~= wndControl then return end
	wndControl:GetParent():ToggleLeftSpin(false)
end

function PDA:OnRotateLeft(wndHandler, wndControl)
	if wndHandler ~= wndControl then return end
	wndControl:GetParent():ToggleRightSpin(true)
end

function PDA:OnRotateLeftCancel(wndHandler, wndControl)
	if wndHandler ~= wndControl then return end
	wndControl:GetParent():ToggleRightSpin(false)
end

function PDA:OnChangeCamera(wndHandler, wndControl)
	if wndHandler ~= wndControl then return end
	local strCamera = wndControl:GetData()

	if strCamera == "Paperdoll" then
		wndControl:GetParent():SetCamera("Datachron")
		wndControl:SetData("Datachron")
		wndControl:ChangeArt("CRB_CharacterCreateSprites:btnCharS_ZoomPortrait")
	elseif strCamera == "Datachron" then
		wndControl:GetParent():SetCamera("Paperdoll")
		wndControl:SetData("Paperdoll")
		wndControl:ChangeArt("CRB_CharacterCreateSprites:btnCharS_ZoomModel")
	elseif strCamera == nil then
		wndControl:GetParent():SetCamera("Datachron")
		wndControl:SetData("Datachron")
		wndControl:ChangeArt("CRB_CharacterCreateSprites:btnCharS_ZoomPortrait")
	end

end

function PDA:OnToggleCharacter(wndHandler, wndControl, eMouseButton, bShow)
	if wndHandler ~= wndControl then return end
	local wndCostume = wndControl:FindChild("cstmwnd_Portrait")
	local wndCharacterSheet = wndControl:GetParent():FindChild("wnd_CharSheet")
	local nL, nT, nR, nB = wndCharacterSheet:GetAnchorOffsets()
	bShow = bShow or wndControl:GetData()
	wndCostume:Show(bShow)
	
	if wndCostume:IsShown() == true then
		wndCharacterSheet:SetAnchorOffsets(nL, nT, -240, nB)
		wndCharacterSheet:Show(true)
	elseif wndCostume:IsShown() == false then
		wndCharacterSheet:SetAnchorOffsets(nL, nT, -64, nB)
		wndCharacterSheet:Show(true)
	end
end

function PDA:OnToggleCharacterFull(wndHandler, wndControl)
	local bLargePortrait = wndControl:GetData()	
	local wndPortrait = self.wndCS:FindChild("cstmwnd_Portrait")
	local nL, nT, nR, nB = wndPortrait:GetAnchorOffsets()
	local nWidth = wndPortrait:GetWidth()
	
	if bLargePortrait == false or bLargePortrait == nil then
		wndPortrait:SetAnchorOffsets(-433, nT, nR, nB)
		self.wndCS:FindChild("wnd_CharSheet"):Show(false)
		wndControl:SetData(true)
		wndPortrait:SetOpacity(1)
	elseif bLargePortrait == true then
		wndPortrait:SetAnchorOffsets(-233, nT, nR, nB)
		self.wndCS:FindChild("wnd_CharSheet"):Show(true)
		wndControl:SetData(false)
		wndPortrait:SetOpacity(0.6)
	end
	-- -223 -- small
	-- -433 -- full
end

function PDA:OnURLShow(wndHandler, wndControl)
	if wndHandler ~= wndControl then return end
	local strURL = wndControl:FindChild("wnd_URL"):GetText()
	wndControl:FindChild("CopyToClipboard"):SetActionData(GameLib.CodeEnumConfirmButtonType.CopyToClipboard, strURL)
end

-----------------------------------------------------------------------------------------------
-- PDA Edit Form Functions
-----------------------------------------------------------------------------------------------
---- General Methods ----
function PDA:OnDDClick(wndHandler, wndControl)
	local wndDD = wndControl:FindChild("wnd_DD")
	wndDD:Show(not (wndDD:IsShown()))
end

function PDA:ToggleHelp(wndHandler, wndControl)
	local wnd = wndControl:FindChild("wnd")
	wnd:Show(not wnd:IsShown())
end

function PDA:TabShow(wndHandler, wndControl)
	local btnName = wndControl:GetName()
	if btnName == "btn_EditBackground" or btnName == "btn_LookupProfile" or btnName == "btn_EditProfile" then
		self.wndMain:FindChild("wnd_EditProfile"):Show(self.wndMain:FindChild("btn_EditProfile"):IsChecked())
		self.wndMain:FindChild("wnd_LookupProfile"):Show(self.wndMain:FindChild("btn_LookupProfile"):IsChecked())
		self.wndMain:FindChild("wnd_EditBackground"):Show(self.wndMain:FindChild("btn_EditBackground"):IsChecked())
	end
end

function PDA:OnClose(wndHandler, wndControl)
	wndControl:GetParent():Close() -- hide the window
end

function PDA:OnStatusShow(wndHandler, wndControl)
	if wndControl ~= wndHandler then return end
	if RPCore then
		local rpState = RPCore:GetLocalTrait("rpflag")
		if rpState == nil then rpState = 0 end
		for i = 1, 3 do
			local check = RPCore:HasBitFlag(rpState,i)
			wndControl:FindChild("input_b_RoleplayToggle" .. i):SetCheck(check)
		end
	end
end

function PDA:OnStatusCheck(wndHandler, wndControl)
	local rpState = 0
	local wndDD = wndControl:GetParent()
	for i = 1, 3 do 
		local wndButton = wndDD:FindChild("input_b_RoleplayToggle" .. i) 
		rpState = RPCore:SetBitFlag(rpState,i,wndButton:IsChecked())
	end 
	RPCore:SetLocalTrait("rpflag",rpState)
end

function PDA:OnPublicHistoryCheck(wndHandler, wndControl)
	RPCore:SetLocalTrait("publicBio", wndControl:IsChecked())
end

---- Edit Profile Methods ----

function PDA:OnEditShow(wndHandler, wndControl)
	if wndHandler ~= wndControl then return end
	local wndEditProfile = self.wndMain:FindChild("wnd_EditProfile")
	
	local rpFullname = RPCore:GetLocalTrait("fullname") or GameLib.GetPlayerUnit():GetName()
	local rpShortBlurb = RPCore:GetLocalTrait("shortdesc")
	local rpTitle = RPCore:GetLocalTrait("title")
	local rpHeight = RPCore:GetLocalTrait("height")
	local rpWeight = RPCore:GetLocalTrait("weight")
	local rpAge = RPCore:GetLocalTrait("age")
	local rpRace = karRaceToString[GameLib.GetPlayerUnit():GetRaceId()]
	local rpJob = RPCore:GetLocalTrait("job")
	local rpGender = RPCore:GetLocalTrait("gender") or karGenderToString[GameLib.GetPlayerUnit():GetGender()]
	local rpURL = RPCore:GetLocalTrait("URL")
	
	wndEditProfile:FindChild("input_s_Name"):SetText(rpFullname)
	wndEditProfile:FindChild("input_s_Name"):FindChild("label"):Show(false)
	
	if rpTitle and string.len(tostring(rpTitle)) > 1 then
		wndEditProfile:FindChild("input_s_Title"):SetText(rpTitle)
		wndEditProfile:FindChild("input_s_Title"):FindChild("label"):Show(false)
	end
	
	if rpShortBlurb and string.len(tostring(rpShortBlurb)) > 1 then
		wndEditProfile:FindChild("input_s_Description"):SetText(rpShortBlurb)
		wndEditProfile:FindChild("input_s_Description"):FindChild("label"):Show(false)
	end
	
	if rpJob and string.len(tostring(rpJob)) > 1 then
		wndEditProfile:FindChild("input_s_Job"):SetText(rpJob)
		wndEditProfile:FindChild("input_s_Job"):FindChild("label"):Show(false)
	end
	
	if rpRace and string.len(tostring(rpRace)) > 1 then
		wndEditProfile:FindChild("input_s_Race"):SetText(rpRace)
		wndEditProfile:FindChild("input_s_Race"):FindChild("label"):Show(false)
	end
	
	if rpGender and string.len(tostring(rpGender)) > 1 then
		wndEditProfile:FindChild("input_s_Gender"):SetText(rpGender)
		wndEditProfile:FindChild("input_s_Gender"):FindChild("label"):Show(false)
	end
	
	if rpAge and string.len(tostring(rpAge)) > 1 then
		wndEditProfile:FindChild("input_s_Age"):SetText(rpAge)
		wndEditProfile:FindChild("input_s_Age"):FindChild("label"):Show(false)
	end
	
	if rpHeight and string.len(tostring(rpHeight)) > 1 then
		wndEditProfile:FindChild("input_s_Height"):SetText(rpHeight)
		wndEditProfile:FindChild("input_s_Height"):FindChild("label"):Show(false)
	end
	
	if rpWeight and string.len(tostring(rpWeight)) > 1 then
		wndEditProfile:FindChild("input_s_Weight"):SetText(rpWeight)
		wndEditProfile:FindChild("input_s_Weight"):FindChild("label"):Show(false)
	end
	
	if rpGender and string.len(tostring(rpGender)) > 1 then
		wndEditProfile:FindChild("input_s_Gender"):SetText(rpGender)
		wndEditProfile:FindChild("input_s_Gender"):FindChild("label"):Show(false)
	end
	
	if rpURL and string.len(tostring(rpURL)) > 1 then
		wndEditProfile:FindChild("input_s_URL"):SetText(rpURL)
		wndEditProfile:FindChild("input_s_URL"):FindChild("label"):Show(false)
	end
	
end

function PDA:OnEditOK()
	local wndEditProfile = self.wndMain:FindChild("wnd_EditProfile")
		
	local strFullname = wndEditProfile:FindChild("input_s_Name"):GetText()
	local strCharTitle = wndEditProfile:FindChild("input_s_Title"):GetText()
	local strBlurb = wndEditProfile:FindChild("input_s_Description"):GetText()
	local strHeight = wndEditProfile:FindChild("input_s_Height"):GetText()
	local strWeight = wndEditProfile:FindChild("input_s_Weight"):GetText()
	local strAge = wndEditProfile:FindChild("input_s_Age"):GetText()
	local strJob = wndEditProfile:FindChild("input_s_Job"):GetText()
	local strGender = wndEditProfile:FindChild("input_s_Gender"):GetText()
	local strURL = wndEditProfile:FindChild("input_s_URL"):GetText()
	local nRace = GameLib.GetPlayerUnit():GetRaceId()
	local nSex = GameLib.GetPlayerUnit():GetGender()
	local nFaction = GameLib.GetPlayerUnit():GetFaction()
	
	RPCore:SetLocalTrait("fullname",strFullname)
	RPCore:SetLocalTrait("sex", nSex)
	RPCore:SetLocalTrait("race", nRace)
	RPCore:SetLocalTrait("faction", nFaction)
	
	if string.len(tostring(strCharTitle)) > 1 then RPCore:SetLocalTrait("title",strCharTitle) else RPCore:SetLocalTrait("title",nil) end
	if string.len(tostring(strBlurb)) > 1 then RPCore:SetLocalTrait("shortdesc", strBlurb) else RPCore:SetLocalTrait("shortdesc", nil) end
	if string.len(tostring(strHeight)) > 1 then RPCore:SetLocalTrait("height", strHeight) else RPCore:SetLocalTrait("height", nil) end
	if string.len(tostring(strWeight)) > 1 then RPCore:SetLocalTrait("weight", strWeight) else RPCore:SetLocalTrait("weight", nil) end
	if string.len(tostring(strAge)) > 1 then RPCore:SetLocalTrait("age", strAge) else RPCore:SetLocalTrait("age", nil) end
	if string.len(tostring(strJob)) > 1 then RPCore:SetLocalTrait("job", strJob) else RPCore:SetLocalTrait("job", nil) end
	if string.len(tostring(strGender)) > 1 then RPCore:SetLocalTrait("gender", strGender) else RPCore:SetLocalTrait("gender", nil) end
	if string.len(tostring(strURL)) > 1 then RPCore:SetLocalTrait("URL", strURL) else RPCore:SetLocalTrait("URL", nil) end
	
	self:OnEditShow() -- hide the window
end

function PDA:OnEditBoxChanged(wndHandler, wndControl)
	if wndHandler ~= wndControl then return end
	local bEmpty = not (string.len(wndControl:GetText()) >= 1)
	wndControl:FindChild("label"):Show(bEmpty)
end

function PDA:OnEditCancel()
	self:OnEditShow()
end

---- Profile Viewer Methods ----

function PDA:FillProfileList()
	local tCacheList = RPCore:GetCachedPlayerList()

	if #tCacheList > 1 then
		table.sort(tCacheList)
	end
	
	local wndGrid = self.wndMain:FindChild("wnd_LookupProfile:Grid")
	
	wndGrid:DeleteAll()
	
	for i,strPlayerName in pairs(tCacheList) do
		local strIcon
		local unit = GameLib.GetPlayerUnitByName(strPlayerName)
		local nRace, nSex, nFaction
		
		local strName = RPCore:GetTrait(strPlayerName, "fullname")
		
		if unit then
			nRace = unit:GetRaceId() or "Unknown"
			nSex = unit:GetGender() or "Unknown"
			nFaction = unit:GetFaction() or  Unit.CodeEnumFaction.ExilePlayer
		else
			nRace = RPCore:GetTrait(strPlayerName, "race") or "Unknown"
			nSex = RPCore:GetTrait(strPlayerName, "sex") or "Unknown"
			nFaction = RPCore:GetTrait(strPlayerName, "faction") or  Unit.CodeEnumFaction.ExilePlayer
		end
		
		if type(nRace) == "number" and type(nSex) == "number" then
			if nRace == GameLib.CodeEnumRace.Human then
				if nFaction == Unit.CodeEnumFaction.DominionPlayer then
					nSex = nSex + 2
				end
			end
			strIcon = ktRaceSprites[nRace][nSex]
		else
			strIcon = "CRB_Tradeskills:sprSchemIntroArt"
		end
		
		local iCurrRow = wndGrid:AddRow("")
		wndGrid:SetCellLuaData(iCurrRow, 1, strPlayerName)
		wndGrid:SetCellImage(iCurrRow, 1, strIcon)
		wndGrid:SetCellText(iCurrRow, 2, strName)
	end
	wndGrid:SetSortColumn(2)
end

function PDA:ShowCharacterSheet(wndControl, wndHandler, iRow, iCol)
	local strPlayerName = wndControl:GetCellData(iRow, 1)
	local unit
	
	self.wndCS:FindChild("wnd_CharSheet"):SetAML(self:DrawCharacterProfile(strPlayerName))
	self.wndCS:SetData(strPlayerName)
	
	unit = GameLib.GetPlayerUnitByName(strPlayerName)
	
	if unit then
		self.wndCS:FindChild("btn_TogglePortrait"):FindChild("cstmwnd_Portrait"):SetCostume(unit)
		self:OnToggleCharacter(self.wndCS:FindChild("btn_TogglePortrait"), self.wndCS:FindChild("btn_TogglePortrait"), 0, true)
		self.wndCS:FindChild("btn_TogglePortrait"):FindChild("cstmwnd_Portrait"):SetOpacity(0.6)
	else
		self.wndCS:FindChild("btn_TogglePortrait"):FindChild("cstmwnd_Portrait"):SetCostume(nil)
		self:OnToggleCharacter(self.wndCS:FindChild("btn_TogglePortrait"), self.wndCS:FindChild("btn_TogglePortrait"), 0, false)
		self.wndCS:FindChild("btn_TogglePortrait"):FindChild("cstmwnd_Portrait"):SetOpacity(0.6)
	end
	self.wndCS:SetData(strPlayerName)
	self.wndCS:Show(true)
	self.wndCS:ToFront()
	self.wndMain:Show(false)
end

---- Edit History ----

function PDA:OnEditHistoryShow(wndHandler, wndControl)
	local wndPublicBio = self.wndMain:FindChild("wnd_EditBackground:input_b_PublicHistory")
	local strBioText = RPCore:GetLocalTrait("biography") or ""
	local bPublicBio = RPCore:GetLocalTrait("publicBio") or false
	GeminiRichText:SetText(self.wndMarkupEditor, strBioText)
end

function PDA:OnEditHistoryOK(wndHandler, wndControl)
	local bioText = GeminiRichText:GetText(self.wndMarkupEditor)
	RPCore:SetLocalTrait("biography", bioText)
end

function PDA:OnEditHistoryCancel(wndHandler, wndControl)
	self:OnEditHistoryShow()
end

-----------------------------------------------------------------------------------------------
-- PDA Options Form Functions
-----------------------------------------------------------------------------------------------

function PDA:OnOptionsOK()
	-- RP State Colors
	local wndStateColors = self.wndOptions:FindChild("group_StateColors")
	for i = 0, 7 do
		local strColor = wndStateColors:FindChild("btn_Color_State"..i):GetData()
		self.tStateColors[i] = strColor
	end
	-- Nameplate Positioning
	local wndNameplatePosition = self.wndOptions:FindChild("group_NameplatePosition")
	self.tNamePlateOptions.nXoffset = wndNameplatePosition:FindChild("input_n_OffsetX"):GetValue()
	self.tNamePlateOptions.nYoffset = wndNameplatePosition:FindChild("input_n_OffsetY"):GetValue()
	local btnAnchor = wndNameplatePosition:FindChild("input_n_Anchor"):GetRadioSelButton("NameplateAnchor")
	self.tNamePlateOptions.nAnchor = tonumber(btnAnchor:GetName())
	-- Nameplate Visibility
	local wndNameplateVisibility = self.wndOptions:FindChild("group_NameplateVisibility")
	self.tNamePlateOptions.nNameplateDistance = tonumber(wndNameplateVisibility:FindChild("input_n_Distance"):GetValue())
	self.tNamePlateOptions.bShowMyNameplate = wndNameplateVisibility:FindChild("input_b_ShowPlayerNameplate"):IsChecked()
	self.tNamePlateOptions.bScaleNameplates = wndNameplateVisibility:FindChild("input_b_DistanceScaling"):IsChecked()
	self.tNamePlateOptions.bShowNames = wndNameplateVisibility:FindChild("input_b_ShowNames"):IsChecked()
	self.tNamePlateOptions.bShowTitles = wndNameplateVisibility:FindChild("input_b_ShowTitles"):IsChecked()
	-- Styles
	local tStyleTable = GeminiRichText:GetStyleTable(self.wndStyleEditor)
	for i,v in pairs(tStyleTable) do
		self.tStyles[i] = v
	end
	
	self.wndOptions:Close() -- hide the window
	self:UpdateMyNameplate()
	--Event_FireGenericEvent("GenericEvent_PerspectivePlates_RegisterOffsets", -15 + self.tNamePlateOptions.nXoffset, -15 + self.tNamePlateOptions.nYoffset, 15 + self.tNamePlateOptions.nXoffset, 15 + self.tNamePlateOptions.nYoffset)
end

function PDA:OnOptionsCancel()
	self.wndOptions:Show(false) -- hide the window
end

function PDA:OnShowOptions(wndHandler, wndControl)
	if wndControl ~= self.wndOptions then return end
	-- Styles
	GeminiRichText:SetStyleTable(self.wndStyleEditor, self.tStyles)
	
	-- Nameplate Visibility
	local wndNameplateVisibility = self.wndOptions:FindChild("group_NameplateVisibility")
	wndNameplateVisibility:FindChild("input_n_Distance"):SetValue(self.tNamePlateOptions.nNameplateDistance)
	wndNameplateVisibility:FindChild("input_b_ShowPlayerNameplate"):SetCheck(self.tNamePlateOptions.bShowMyNameplate)
	wndNameplateVisibility:FindChild("input_b_DistanceScaling"):SetCheck(self.tNamePlateOptions.bScaleNameplates)
	wndNameplateVisibility:FindChild("input_b_ShowNames"):SetCheck(self.tNamePlateOptions.bShowNames)
	wndNameplateVisibility:FindChild("input_b_ShowTitles"):SetCheck(self.tNamePlateOptions.bShowTitles)
	
	--Nameplate Positioning
	local wndNameplatePosition = self.wndOptions:FindChild("group_NameplatePosition")
	wndNameplatePosition:FindChild("input_n_OffsetX"):SetValue(self.tNamePlateOptions.nXoffset)
	wndNameplatePosition:FindChild("input_n_OffsetY"):SetValue(self.tNamePlateOptions.nYoffset)
	local wndAnchor = wndNameplatePosition:FindChild("input_n_Anchor")
	local btnAnchor = wndAnchor:FindChild(self.tNamePlateOptions.nAnchor)
	wndAnchor:SetRadioSelButton("NameplateAnchor", btnAnchor)
	
	-- RP State Colors
	local wndStateColors = self.wndOptions:FindChild("group_StateColors")
	for i = 0, 7 do
		wndStateColors:FindChild("btn_Color_State"..i):SetData(self.tStateColors[i])
		wndStateColors:FindChild("btn_Color_State"..i):FindChild("swatch"):SetBGColor(self.tStateColors[i])
	end
	
end

function PDA:ColorSelect(strColor, wndButton)
	wndButton:SetData(strColor)
	wndButton:FindChild("swatch"):SetBGColor(strColor)
end

function PDA:ColorButtonClick(wndHandler, wndControl)
	GeminiColor:ShowColorPicker(self, "ColorSelect", true, wndControl:GetData(), wndControl)
end

function PDA:ResetStyles(wndHandler, wndControl)

end

function PDA:ResetStateColors(wndHandler, wndControl)
	local wndOptions = wndControl:GetParent()
	for i = 0, 7 do
		local wndCurr = wndOptions:FindChild("btn_Color_State"..i..":swatch")
		local color = ktStateColors[i]
		wndCurr:SetData(color)
		wndCurr:SetBGColor(color)
		wndCurr:GetParent():SetData(color)
	end
end

-----------------------------------------------------------------------------------------------
-- PDA Instance
-----------------------------------------------------------------------------------------------
local PDAInst = PDA:new()
PDAInst:Init()