------------------------------------------------------------------------
-- Collection of functions that can be used in multiple places
------------------------------------------------------------------------
local E, L, V, P, G = unpack(ElvUIChat)
local LCS = E.Libs.LCS

local _G = _G
local wipe, max, next = wipe, max, next
local type, ipairs, pairs, unpack = type, ipairs, pairs, unpack
local strfind, strlen, tonumber, tostring = strfind, strlen, tonumber, tostring
local hooksecurefunc = hooksecurefunc

local CreateFrame = CreateFrame
local GetAddOnEnableState = GetAddOnEnableState
local GetBattlefieldArenaFaction = GetBattlefieldArenaFaction
local GetInstanceInfo = GetInstanceInfo
local GetNumGroupMembers = GetNumGroupMembers
local HideUIPanel = HideUIPanel
local InCombatLockdown = InCombatLockdown
local IsAddOnLoaded = IsAddOnLoaded
local IsInRaid = IsInRaid
local IsLevelAtEffectiveMaxLevel = IsLevelAtEffectiveMaxLevel
local IsRestrictedAccount = IsRestrictedAccount
local IsTrialAccount = IsTrialAccount
local IsVeteranTrialAccount = IsVeteranTrialAccount
local IsXPUserDisabled = IsXPUserDisabled
local RequestBattlefieldScoreData = RequestBattlefieldScoreData
local SetCVar = SetCVar
local UIParentLoadAddOn = UIParentLoadAddOn
local UnitFactionGroup = UnitFactionGroup
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitHasVehicleUI = UnitHasVehicleUI
local UnitInParty = UnitInParty
local UnitInRaid = UnitInRaid
local UnitIsUnit = UnitIsUnit
local GetSpecialization = (E.Classic or E.Wrath and LCS.GetSpecialization) or GetSpecialization
local GetSpecializationRole = (E.Classic or E.Wrath and LCS.GetSpecializationRole) or GetSpecializationRole
local C_PetBattles_IsInBattle = C_PetBattles and C_PetBattles.IsInBattle

local ERR_NOT_IN_COMBAT = ERR_NOT_IN_COMBAT
local FACTION_ALLIANCE = FACTION_ALLIANCE
local FACTION_HORDE = FACTION_HORDE
local PLAYER_FACTION_GROUP = PLAYER_FACTION_GROUP

local GameMenuButtonAddons = GameMenuButtonAddons
local GameMenuButtonLogout = GameMenuButtonLogout
local GameMenuFrame = GameMenuFrame
-- GLOBALS: ElvUIChatDB, ElvUF

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

do
	local essenceTextureID = 2975691
	function E:ScanTooltipTextures()
		local tt = E.ScanTooltip

		if not tt.gems then
			tt.gems = {}
		else
			wipe(tt.gems)
		end

		if not tt.essences then
			tt.essences = {}
		else
			for _, essences in pairs(tt.essences) do
				wipe(essences)
			end
		end

		local step = 1
		for i = 1, 10 do
			local tex = _G['ElvUI_ScanTooltipTexture'..i]
			local texture = tex and tex:IsShown() and tex:GetTexture()
			if texture then
				if texture == essenceTextureID then
					local selected = (tt.gems[i-1] ~= essenceTextureID and tt.gems[i-1]) or nil
					if not tt.essences[step] then tt.essences[step] = {} end

					tt.essences[step][1] = selected			--essence texture if selected or nil
					tt.essences[step][2] = tex:GetAtlas()	--atlas place 'tooltip-heartofazerothessence-major' or 'tooltip-heartofazerothessence-minor'
					tt.essences[step][3] = texture			--border texture placed by the atlas
					--`CollectEssenceInfo` will add 4 (hex quality color) and 5 (essence name)

					step = step + 1

					if selected then
						tt.gems[i-1] = nil
					end
				else
					tt.gems[i] = texture
				end
			end
		end

		return tt.gems, tt.essences
	end
end

function E:GetPlayerRole()
	local role = (E.Retail or E.Wrath) and UnitGroupRolesAssigned('player') or 'NONE'
	return (role == 'NONE' and E.myspec and GetSpecializationRole(E.myspec)) or role
end

function E:CheckRole()
	E.myspec = E.Retail and GetSpecialization()
	E.myrole = E:GetPlayerRole()
end

function E:Dump(object, inspect)
	if GetAddOnEnableState(E.myname, 'Blizzard_DebugTools') == 0 then
		E:Print('Blizzard_DebugTools is disabled.')
		return
	end

	local debugTools = IsAddOnLoaded('Blizzard_DebugTools')
	if not debugTools then UIParentLoadAddOn('Blizzard_DebugTools') end

	if inspect then
		local tableType = type(object)
		if tableType == 'table' then
			_G.DisplayTableInspectorWindow(object)
		else
			E:Print('Failed: ', tostring(object), ' is type: ', tableType,'. Requires table object.')
		end
	else
		_G.DevTools_Dump(object)
	end
end

function E:AddNonPetBattleFrames()
	if InCombatLockdown() then
		E:UnregisterEventForObject('PLAYER_REGEN_DISABLED', E.AddNonPetBattleFrames, E.AddNonPetBattleFrames)
		return
	elseif E:IsEventRegisteredForObject('PLAYER_REGEN_DISABLED', E.AddNonPetBattleFrames) then
		E:UnregisterEventForObject('PLAYER_REGEN_DISABLED', E.AddNonPetBattleFrames, E.AddNonPetBattleFrames)
	end

	for object, data in pairs(E.FrameLocks) do
		local parent, strata
		if type(data) == 'table' then
			parent, strata = data.parent, data.strata
		elseif data == true then
			parent = _G.UIParent
		end

		local obj = _G[object] or object
		obj:SetParent(parent)
		if strata then
			obj:SetFrameStrata(strata)
		end
	end
end

function E:RemoveNonPetBattleFrames()
	if InCombatLockdown() then
		E:RegisterEventForObject('PLAYER_REGEN_DISABLED', E.RemoveNonPetBattleFrames, E.RemoveNonPetBattleFrames)
		return
	elseif E:IsEventRegisteredForObject('PLAYER_REGEN_DISABLED', E.RemoveNonPetBattleFrames) then
		E:UnregisterEventForObject('PLAYER_REGEN_DISABLED', E.RemoveNonPetBattleFrames, E.RemoveNonPetBattleFrames)
	end

	for object in pairs(E.FrameLocks) do
		local obj = _G[object] or object
		obj:SetParent(E.HiddenFrame)
	end
end

function E:RegisterPetBattleHideFrames(object, originalParent, originalStrata)
	if not object or not originalParent then
		E:Print('Error. Usage: RegisterPetBattleHideFrames(object, originalParent, originalStrata)')
		return
	end

	object = _G[object] or object

	--If already doing pokemon
	if E.Retail and C_PetBattles_IsInBattle() then
		object:SetParent(E.HiddenFrame)
	end

	E.FrameLocks[object] = {
		parent = originalParent,
		strata = originalStrata or nil,
	}
end

function E:UnregisterPetBattleHideFrames(object)
	if not object then
		E:Print('Error. Usage: UnregisterPetBattleHideFrames(object)')
		return
	end

	object = _G[object] or object

	--Check if object was registered to begin with
	if not E.FrameLocks[object] then return end

	--Change parent of object back to original parent
	local originalParent = E.FrameLocks[object].parent
	if originalParent then
		object:SetParent(originalParent)
	end

	--Change strata of object back to original
	local originalStrata = E.FrameLocks[object].strata
	if originalStrata then
		object:SetFrameStrata(originalStrata)
	end

	--Remove object from table
	E.FrameLocks[object] = nil
end

function E:RegisterObjectForVehicleLock(object, originalParent)
	if not object or not originalParent then
		E:Print('Error. Usage: RegisterObjectForVehicleLock(object, originalParent)')
		return
	end

	object = _G[object] or object
	--Entering/Exiting vehicles will often happen in combat.
	--For this reason we cannot allow protected objects.
	if object.IsProtected and object:IsProtected() then
		E:Print('Error. Object is protected and cannot be changed in combat.')
		return
	end

	--Check if we are already in a vehicles
	if (E.Retail or E.Wrath) and UnitHasVehicleUI('player') then
		object:SetParent(E.HiddenFrame)
	end

	--Add object to table
	E.VehicleLocks[object] = originalParent
end

function E:UnregisterObjectForVehicleLock(object)
	if not object then
		E:Print('Error. Usage: UnregisterObjectForVehicleLock(object)')
		return
	end

	object = _G[object] or object
	--Check if object was registered to begin with
	if not E.VehicleLocks[object] then
		return
	end

	--Change parent of object back to original parent
	local originalParent = E.VehicleLocks[object]
	if originalParent then
		object:SetParent(originalParent)
	end

	--Remove object from table
	E.VehicleLocks[object] = nil
end

function E:EnterVehicleHideFrames(_, unit)
	if unit ~= 'player' then return end
	for object in pairs(E.VehicleLocks) do
		object:SetParent(E.HiddenFrame)
	end
end

function E:ExitVehicleShowFrames(_, unit)
	if unit ~= 'player' then return end
	for object, originalParent in pairs(E.VehicleLocks) do
		object:SetParent(originalParent)
	end
end

function E:RequestBGInfo()
	RequestBattlefieldScoreData()
end

function E:PLAYER_ENTERING_WORLD(_, initLogin, isReload)
	E:CheckRole()

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

	-- Blizzard will set this value to int(60/CVar cameraDistanceMax)+1 at logout if it is manually set higher than that
	if not E.Retail and E.db.general.lockCameraDistanceMax then
		SetCVar('cameraDistanceMaxZoomFactor', E.db.general.cameraDistanceMax)
	end

	local _, instanceType = GetInstanceInfo()
	if instanceType == 'pvp' then
		E.BGTimer = E:ScheduleRepeatingTimer('RequestBGInfo', 5)
		E:RequestBGInfo()
	elseif E.BGTimer then
		E:CancelTimer(E.BGTimer)
		E.BGTimer = nil
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

	--if IsAddOnLoaded('ElvUI_Options') then
		local ACD = E.Libs.AceConfigDialog
		if ACD and ACD.OpenFrames and ACD.OpenFrames.ElvUIChat then
			ACD:Close('ElvUIChat')
			err = true
		end
	--end

	if E.CreatedMovers then
		for name in pairs(E.CreatedMovers) do
			local mover = _G[name]
			if mover and mover:IsShown() then
				mover:Hide()
				err = true
			end
		end
	end

	if err then
		E:Print(ERR_NOT_IN_COMBAT)
	end
end

function E:XPIsUserDisabled()
	return E.Retail and IsXPUserDisabled()
end

function E:XPIsTrialMax()
	return E.Retail and (IsRestrictedAccount() or IsTrialAccount() or IsVeteranTrialAccount()) and (E.myLevel == 20)
end

function E:XPIsLevelMax()
	return IsLevelAtEffectiveMaxLevel(E.mylevel) or E:XPIsUserDisabled() or E:XPIsTrialMax()
end

function E:GetGroupUnit(unit)
	if UnitIsUnit(unit, 'player') then return end
	if strfind(unit, 'party') or strfind(unit, 'raid') then
		return unit
	end

	-- returns the unit as raid# or party# when grouped
	if UnitInParty(unit) or UnitInRaid(unit) then
		local isInRaid = IsInRaid()
		for i = 1, GetNumGroupMembers() do
			local groupUnit = (isInRaid and 'raid' or 'party')..i
			if UnitIsUnit(unit, groupUnit) then
				return groupUnit
			end
		end
	end
end

function E:PositionGameMenuButton()
	if E.Retail then
		GameMenuFrame.Header.Text:SetTextColor(unpack(E.media.rgbvaluecolor))
	end
	GameMenuFrame:Height(GameMenuFrame:GetHeight() + GameMenuButtonLogout:GetHeight() - 4)

	local button = GameMenuFrame[E.name]
	button:SetFormattedText('%s%s|r', E.media.hexvaluecolor, E.name)

	local _, relTo, _, _, offY = GameMenuButtonLogout:GetPoint()
	if relTo ~= button then
		button:ClearAllPoints()
		button:Point('TOPLEFT', relTo, 'BOTTOMLEFT', 0, -1)
		GameMenuButtonLogout:ClearAllPoints()
		GameMenuButtonLogout:Point('TOPLEFT', button, 'BOTTOMLEFT', 0, offY)
	end
end

function E:NEUTRAL_FACTION_SELECT_RESULT()
	E.myfaction, E.myLocalizedFaction = UnitFactionGroup('player')
end

function E:PLAYER_LEVEL_UP(_, level)
	E.mylevel = level
end

function E:ClickGameMenu()
	E:ToggleOptions() -- we already prevent it from opening in combat

	if not InCombatLockdown() then
		HideUIPanel(GameMenuFrame)
	end
end

function E:SetupGameMenu()
	local button = CreateFrame('Button', nil, GameMenuFrame, 'GameMenuButtonTemplate')
	button:SetScript('OnClick', E.ClickGameMenu)
	GameMenuFrame[E.name] = button

	if not E:IsAddOnEnabled('ConsolePortUI_Menu') then
		button:Size(GameMenuButtonLogout:GetWidth(), GameMenuButtonLogout:GetHeight())
		button:Point('TOPLEFT', GameMenuButtonAddons, 'BOTTOMLEFT', 0, -1)
		hooksecurefunc('GameMenuFrame_UpdateVisibleButtons', E.PositionGameMenuButton)
	end
end

function E:LoadAPI()
	E:RegisterEvent('PLAYER_LEVEL_UP')
	E:RegisterEvent('PLAYER_ENTERING_WORLD')
	E:RegisterEvent('PLAYER_REGEN_ENABLED')
	E:RegisterEvent('PLAYER_REGEN_DISABLED')
	E:SetupGameMenu()

	if E.Retail then
		E:RegisterEvent('NEUTRAL_FACTION_SELECT_RESULT')
		E:RegisterEvent('PET_BATTLE_CLOSE', 'AddNonPetBattleFrames')
		E:RegisterEvent('PET_BATTLE_OPENING_START', 'RemoveNonPetBattleFrames')
		E:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED', 'CheckRole')
	end

	if E.Retail or E.Wrath then
		E:RegisterEvent('UNIT_ENTERED_VEHICLE', 'EnterVehicleHideFrames')
		E:RegisterEvent('UNIT_EXITED_VEHICLE', 'ExitVehicleShowFrames')
	else
		E:RegisterEvent('CHARACTER_POINTS_CHANGED', 'CheckRole')
	end

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
