------------------------------------------------------------------------
-- Collection of functions that can be used in multiple places
------------------------------------------------------------------------
local E, L, V, P, G = unpack(ElvUIChat)

local _G = _G
local type, ipairs, pairs, unpack = type, ipairs, pairs, unpack
local strlen, tonumber = strlen, tonumber
local wipe = wipe
local hooksecurefunc = hooksecurefunc

local CreateFrame = CreateFrame
local HideUIPanel = HideUIPanel
local InCombatLockdown = InCombatLockdown
local IsInGroup = IsInGroup
local IsInRaid = IsInRaid
local UnitExists = UnitExists
local UnitGUID = UnitGUID
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local GetSpecialization = GetSpecialization
local GetSpecializationRole = GetSpecializationRole

local ERR_NOT_IN_COMBAT = ERR_NOT_IN_COMBAT

local GameMenuButtonAddons = GameMenuButtonAddons
local GameMenuFrame = GameMenuFrame
-- GLOBALS: ElvUIChatDB

function E:ClassColor(class, usePriestColor)
	if not class then return end

	local color = (_G.CUSTOM_CLASS_COLORS and _G.CUSTOM_CLASS_COLORS[class]) or _G.RAID_CLASS_COLORS[class]
	if type(color) ~= 'table' then return end

	if not color.colorStr then
		color.colorStr = E:RGBToHex(color.r, color.g, color.b, 'ff')
	elseif strlen(color.colorStr) == 6 then
		color.colorStr = 'ff'..color.colorStr
	end

	if usePriestColor and class == 'PRIEST' and tonumber(color.colorStr, 16) > tonumber(E.PriestColors.colorStr, 16) then
		return E.PriestColors
	else
		return color
	end
end

do -- other non-english locales require this
	E.UnlocalizedClasses = {}
	for k, v in pairs(_G.LOCALIZED_CLASS_NAMES_MALE) do E.UnlocalizedClasses[v] = k end
	for k, v in pairs(_G.LOCALIZED_CLASS_NAMES_FEMALE) do E.UnlocalizedClasses[v] = k end

	function E:UnlocalizedClassName(className)
		return (className and className ~= '') and E.UnlocalizedClasses[className]
	end
end

function E:GetPlayerRole()
	local role = UnitGroupRolesAssigned('player')
	return (role == 'NONE' and E.myspec and GetSpecializationRole(E.myspec)) or role
end

function E:CheckRole()
	E.myspec = GetSpecialization()
	E.myrole = E:GetPlayerRole()
end

E.GroupRoles = {}
E.GroupUnitsByRole = {}

function E:UpdateGroupRoles()
	wipe(E.GroupRoles)
	for k in pairs(E.GroupUnitsByRole) do
		wipe(E.GroupUnitsByRole[k])
	end

	E.IsInGroup = IsInGroup()
	if not E.IsInGroup then return end

	local inRaid = IsInRaid()
	local prefix = inRaid and 'raid' or 'party'
	local maxNum = inRaid and 40 or 4

	for i = 1, maxNum do
		local unit = prefix..i
		if UnitExists(unit) then
			local guid = UnitGUID(unit)
			local role = UnitGroupRolesAssigned(unit)
			if guid and role and role ~= 'NONE' then
				E.GroupRoles[guid] = role
				if not E.GroupUnitsByRole[role] then
					E.GroupUnitsByRole[role] = {}
				end
				E.GroupUnitsByRole[role][guid] = unit
			end
		end
	end
end

function E:PLAYER_ENTERING_WORLD(_, initLogin, isReload)
	E:CheckRole()
	E:UpdateGroupRoles()

	if initLogin or not ElvUIChatDB.DisabledAddOns then
		ElvUIChatDB.DisabledAddOns = {}
	end

	if initLogin or isReload then
		E:CheckIncompatible()
	end

	if not E.MediaUpdated then
		E:UpdateMedia()
		E.MediaUpdated = true
	end
end

function E:PLAYER_REGEN_ENABLED()
	if E.ShowOptions then
		E:ToggleOptions()
		E.ShowOptions = nil
	end
end

function E:PLAYER_REGEN_DISABLED()
	local err

	local ACD = E.Libs.AceConfigDialog
	if ACD and ACD.OpenFrames and ACD.OpenFrames.ElvUIChat then
		ACD:Close('ElvUIChat')
		err = true
	end

	if err then
		E:Print(ERR_NOT_IN_COMBAT)
	end
end

function E:PositionGameMenuButton()
	local logout = _G.GameMenuButtonLogout
	if not (logout and GameMenuFrame and GameMenuFrame.Header and GameMenuFrame.Header.Text) then return end

	GameMenuFrame.Header.Text:SetTextColor(unpack(E.media.rgbvaluecolor))
	GameMenuFrame:Height(GameMenuFrame:GetHeight() + logout:GetHeight() - 4)

	local button = GameMenuFrame[E.name]
	button:SetFormattedText('%s%s|r', E.media.hexvaluecolor, E.name)

	local _, relTo, _, _, offY = logout:GetPoint()
	if relTo ~= button then
		button:ClearAllPoints()
		button:Point('TOPLEFT', relTo, 'BOTTOMLEFT', 0, -1)
		logout:ClearAllPoints()
		logout:Point('TOPLEFT', button, 'BOTTOMLEFT', 0, offY)
	end
end

function E:ClickGameMenu()
	E:ToggleOptions()

	if not InCombatLockdown() then
		HideUIPanel(GameMenuFrame)
	end
end

function E:SetupGameMenu()
	local button = CreateFrame('Button', nil, GameMenuFrame, 'GameMenuButtonTemplate')
	button:SetScript('OnClick', E.ClickGameMenu)
	GameMenuFrame[E.name] = button

	local logout = _G.GameMenuButtonLogout
	if logout and not E:IsAddOnEnabled('ConsolePortUI_Menu') then
		button:Size(logout:GetWidth(), logout:GetHeight())
		button:Point('TOPLEFT', GameMenuButtonAddons, 'BOTTOMLEFT', 0, -1)
		hooksecurefunc('GameMenuFrame_UpdateVisibleButtons', E.PositionGameMenuButton)
	else
		button:Size(152, 22)
		button:Point('TOPLEFT', GameMenuButtonAddons or GameMenuFrame.Header, 'BOTTOMLEFT', 0, -1)
	end
end

function E:LoadAPI()
	E:RegisterEvent('PLAYER_ENTERING_WORLD')
	E:RegisterEvent('PLAYER_REGEN_ENABLED')
	E:RegisterEvent('PLAYER_REGEN_DISABLED')
	E:RegisterEvent('GROUP_ROSTER_UPDATE', 'UpdateGroupRoles')
	E:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED', 'CheckRole')
	E:SetupGameMenu()

	do -- setup cropIcon texCoords
		local opt = E.db.general.cropIcon
		local modifier = 0.04 * opt
		for i, v in ipairs(E.TexCoords) do
			if i % 2 == 0 then
				E.TexCoords[i] = v - modifier
			else
				E.TexCoords[i] = v + modifier
			end
		end
	end
end
