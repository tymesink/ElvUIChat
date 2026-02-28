local ElvUIChat = select(2, ...)
ElvUIChat[2] = ElvUIChat[1].Libs.ACL:GetLocale('ElvUIChat', ElvUIChat[1]:GetLocale()) -- Locale doesn't exist yet, make it exist.
local E, L, V, P, G = unpack(ElvUIChat)

local _G = _G
local tonumber, pairs, ipairs, unpack, tostring = tonumber, pairs, ipairs, unpack, tostring
local strjoin, wipe, sort, tinsert, tremove, tContains = strjoin, wipe, sort, tinsert, tremove, tContains
local format, strfind, strrep, strlen, sub, gsub = format, strfind, strrep, strlen, strsub, gsub
local assert, type, pcall, xpcall, next, print = assert, type, pcall, xpcall, next, print
local rawget, rawset, setmetatable = rawget, rawset, setmetatable

local Mixin = Mixin
local ColorMixin = ColorMixin
local CreateFrame = CreateFrame
local GetBindingKey = GetBindingKey
local GetCurrentBindingSet = GetCurrentBindingSet
local GetNumGroupMembers = GetNumGroupMembers
local InCombatLockdown = InCombatLockdown
local IsInGroup = IsInGroup
local IsInGuild = IsInGuild
local IsInRaid = IsInRaid
local ReloadUI = ReloadUI
local SaveBindings = SaveBindings
local SetBinding = SetBinding
local UIParent = UIParent
local UnitFactionGroup = UnitFactionGroup

local GetSpecialization = C_SpecializationInfo.GetSpecialization or GetSpecialization
local PlayerGetTimerunningSeasonID = PlayerGetTimerunningSeasonID

local DisableAddOn = C_AddOns.DisableAddOn
local GetCVarBool = C_CVar.GetCVarBool

local LE_PARTY_CATEGORY_HOME = LE_PARTY_CATEGORY_HOME
local LE_PARTY_CATEGORY_INSTANCE = LE_PARTY_CATEGORY_INSTANCE
local C_ChatInfo_SendAddonMessage = C_ChatInfo.SendAddonMessage

-- GLOBALS: ElvUIChatCharacterDB

--Modules (ElvUIChat: Only load modules we have)
local AFK = E:GetModule('AFK')
local Chat = E:GetModule('Chat')
local Layout = E:GetModule('Layout')
local Skins = E:GetModule('Skins')
local LSM = E.Libs.LSM

--Constants
E.noop = function() end
E.title = format('%s%s|r', E.InfoColor, 'ElvUIChat')
E.version, E.versionString, E.versionDev, E.versionGit = E:ParseVersionString('ElvUIChat')
E.myfaction, E.myLocalizedFaction = UnitFactionGroup('player')
E.myLocalizedClass, E.myclass, E.myClassID = UnitClass('player')
E.myLocalizedRace, E.myrace, E.myRaceID = UnitRace('player')
E.mygender = UnitSex('player')
E.mylevel = UnitLevel('player')
E.myname = UnitName('player')
E.myrealm = GetRealmName()
E.mynameRealm = format('%s - %s', E.myname, E.myrealm) -- contains spaces/dashes in realm (for profile keys)
E.expansionLevel = GetExpansionLevel()
E.expansionLevelMax = GetMaxLevelForExpansionLevel(E.expansionLevel)
E.wowbuild = tonumber(E.wowbuild)
E.physicalWidth, E.physicalHeight = GetPhysicalScreenSize()
E.screenWidth, E.screenHeight = GetScreenWidth(), GetScreenHeight()
E.resolution = format('%dx%d', E.physicalWidth, E.physicalHeight)
E.perfect = 768 / E.physicalHeight
E.allowRoles = true -- Retail-only
E.NewSign = [[|TInterface\OptionsFrame\UI-OptionsFrame-NewFeatureIcon:14:14|t]]
E.NewSignNoWhatsNew = [[|TInterface\OptionsFrame\UI-OptionsFrame-NewFeatureIcon:14:14:0:0|t]]
E.TexturePath = [[Interface\AddOns\ElvUI\Media\Textures\]] -- for plugins?
E.ClearTexture = 0 -- used to clear: Set (Normal, Disabled, Checked, Pushed, Highlight) Texture
E.UserList = {}

-- ElvUIChat: We don't have oUF, skip these
-- E.oUF.Tags.Vars.E = E
-- E.oUF.Tags.Vars.L = L

--Tables
E.media = {}
E.media.bordercolor = {0, 0, 0, 1}  -- ElvUIChat: Initialize early for Toolkit.lua
E.media.backdropcolor = {0.1, 0.1, 0.1, 1}  -- ElvUIChat: Initialize early for Toolkit.lua
E.media.backdropfadecolor = {0.06, 0.06, 0.06, 0.8}  -- ElvUIChat: Initialize early for Toolkit.lua
E.media.unitframeBorderColor = {0, 0, 0, 1}  -- ElvUIChat: Initialize early for Toolkit.lua
E.media.rgbvaluecolor = {1, 1, 1}  -- ElvUIChat: Initialize early for Skins.lua
E.media.hexvaluecolor = 'FFFFFFFF'  -- ElvUIChat: Initialize early
E.media.normTex = E.ClearTexture -- TODO: replace with real texture after LSM fetch
E.media.glossTex = E.ClearTexture -- TODO: replace with real texture after LSM fetch
E.frames = {}
E.unitFrameElements = {}
E.statusBars = {}
-- ElvUIChat: These tables are now initialized in init.lua (early init before General files load)
-- E.RegisteredModules, E.RegisteredInitialModules, E.valueColorUpdateFuncs, E.TexCoords
E.texts = {}
E.snapBars = {}
E.FrameLocks = {}
E.VehicleLocks = {}
E.CreditsList = {}
E.ReverseTimer = {} -- Spells that we want to show the duration backwards (oUF_RaidDebuffs, ???)

-- ElvUIChat: Movers completely removed - chat doesn't need manual positioning

E.InversePoints = {
	BOTTOM = 'TOP',
	BOTTOMLEFT = 'TOPLEFT',
	BOTTOMRIGHT = 'TOPRIGHT',
	CENTER = 'CENTER',
	LEFT = 'RIGHT',
	RIGHT = 'LEFT',
	TOP = 'BOTTOM',
	TOPLEFT = 'BOTTOMLEFT',
	TOPRIGHT = 'BOTTOMRIGHT'
}

E.InverseAnchors = {
	BOTTOM = 'TOP',
	BOTTOMLEFT = 'TOPRIGHT',
	BOTTOMRIGHT = 'TOPLEFT',
	CENTER = 'CENTER',
	LEFT = 'RIGHT',
	RIGHT = 'LEFT',
	TOP = 'BOTTOM',
	TOPLEFT = 'BOTTOMRIGHT',
	TOPRIGHT = 'BOTTOMLEFT'
}

-- Workaround for people wanting to use white and it reverting to their class color.
E.PriestColors = { r = 0.99, g = 0.99, b = 0.99, colorStr = 'fffcfcfc' }

-- Socket Type info from 11.2.0 (63003): Interface\AddOns\Blizzard_ItemSocketing\Blizzard_ItemSocketingUI.lua
E.GemTypeInfo = {
	Yellow			= { r = 0.97, g = 0.82, b = 0.29, a = 1 },
	Red				= { r = 1.00, g = 0.47, b = 0.47, a = 1 },
	Blue			= { r = 0.47, g = 0.67, b = 1.00, a = 1 },
	Hydraulic		= { r = 1.00, g = 1.00, b = 1.00, a = 1 },
	Cogwheel		= { r = 1.00, g = 1.00, b = 1.00, a = 1 },
	Meta			= { r = 1.00, g = 1.00, b = 1.00, a = 1 },
	Prismatic		= { r = 1.00, g = 1.00, b = 1.00, a = 1 },
	PunchcardRed	= { r = 1.00, g = 0.47, b = 0.47, a = 1 },
	PunchcardYellow	= { r = 0.97, g = 0.82, b = 0.29, a = 1 },
	PunchcardBlue	= { r = 0.47, g = 0.67, b = 1.00, a = 1 },
	Domination		= { r = 0.24, g = 0.50, b = 0.70, a = 1 },
	Cypher			= { r = 1.00, g = 0.80, b = 0.00, a = 1 },
	Tinker			= { r = 1.00, g = 0.47, b = 0.47, a = 1 },
	Primordial		= { r = 1.00, g = 0.00, b = 1.00, a = 1 },
	Fragrance		= { r = 1.00, g = 1.00, b = 1.00, a = 1 },
	SingingThunder	= { r = 0.97, g = 0.82, b = 0.29, a = 1 },
	SingingSea		= { r = 0.47, g = 0.67, b = 1.00, a = 1 },
	SingingWind		= { r = 1.00, g = 0.47, b = 0.47, a = 1 },
	Fiber			= { r = 0.90, g = 0.80, b = 0.50, a = 1 },
}

E.Curves = { -- Midnight Color Curves (nil values created later)
	Duration = nil, -- duration object for SetTimeFromStart
	Float = {
		Alpha = nil, -- float for hiding at Zero
		Desaturation = nil, -- float curve for SetDesaturation
	},
	Color = {
		Default = nil, -- simple red, yellow, green curve for various places
		Dispel = nil, -- color curve for IsDispellableByMe; updated by ListUpdated in LibDispel
		Auras = { -- color curves created and updated by UpdateAuraCurves
			auras = false,	-- these all
			buffs = false,	-- stay false
			debuffs = false	-- on classics
		}
	}
}

-- Chat-only: no custom parent needed; use the native UIParent while keeping the reference for callers.
E.UIParent = UIParent
_G.ElvUIParent = UIParent
E.snapBars[#E.snapBars + 1] = E.UIParent

E.HiddenFrame = CreateFrame('Frame', nil, UIParent)
E.HiddenFrame:SetPoint('BOTTOM')
E.HiddenFrame:SetSize(1,1)
E.HiddenFrame:Hide()
E.DEFAULT_FILTER = {}

do
	local a1,a2 = '','[%s%-]'
	function E:ShortenRealm(realm)
		return gsub(realm, a2, a1)
	end

	local a3 = format('%%-%s', E:ShortenRealm(E.myrealm))
	function E:StripMyRealm(name)
		return gsub(name, a3, a1)
	end
end

function E:Print(...)
	local frame = E.db and _G[E.db.general.messageRedirect] or _G.DEFAULT_CHAT_FRAME
	local msg = strjoin('', E.media.hexvaluecolor or '|cff00b3ff', 'ElvUI:|r ', ...)
	frame:AddMessage(msg)
end

function E:GrabColorPickerValues(r, g, b)
	-- we must block the execution path to `ColorCallback` in `AceGUIWidget-ColorPicker-ElvUI`
	-- in order to prevent an infinite loop from `OnValueChanged` when passing into `E.UpdateMedia` which eventually leads here again.
	_G.ColorPickerFrame.noColorCallback = true

	-- grab old values
	local oldR, oldG, oldB = _G.ColorPickerFrame:GetColorRGB()

	-- set and define the new values (ElvUIChat: Retail-only, always use Content.ColorPicker)
	_G.ColorPickerFrame.Content.ColorPicker:SetColorRGB(r or 1, g or 1, b or 1)

	r, g, b = _G.ColorPickerFrame:GetColorRGB()

	-- swap back to the old values
	if oldR then
		_G.ColorPickerFrame.Content.ColorPicker:SetColorRGB(oldR, oldG, oldB)
	end

	-- free it up..
	_G.ColorPickerFrame.noColorCallback = nil

	return r, g, b
end

--Basically check if another class border is being used on a class that doesn't match. And then return true if a match is found.
function E:CheckClassColor(r, g, b)
	r, g, b = E:GrabColorPickerValues(r, g, b)

	for class in pairs(_G.RAID_CLASS_COLORS) do
		if class ~= E.myclass then
			local color = E:ClassColor(class, true)
			local red, green, blue = E:GrabColorPickerValues(color.r, color.g, color.b)
			if red == r and green == g and blue == b then
				return true
			end
		end
	end
end

function E:UpdateClassColor(db)
	if E:CheckClassColor(db.r, db.g, db.b) then
		local color = E.myClassColor
		if color then
			db.r, db.g, db.b = color.r, color.g, color.b
		end
	end

	return db
end

function E:SetColorTable(t, data)
	if t and (type(t) == 'table') then
		local r, g, b, a = E:UpdateColorTable(data)

		t.r, t.g, t.b, t.a = r, g, b, a
		t[1], t[2], t[3], t[4] = r, g, b, a
	else
		t = E:GetColorTable(data)
	end

	if not t.GetRGB then
		Mixin(t, ColorMixin)
	end

	return t
end

function E:VerifyColorTable(data)
	-- we just need to verify all the values exist or assume they are meant to be one
	if not data.r or (data.r > 1 or data.r < 0) then data.r = 1 end
	if not data.g or (data.g > 1 or data.g < 0) then data.g = 1 end
	if not data.b or (data.b > 1 or data.b < 0) then data.b = 1 end
	if not data.a or (data.a > 1 or data.a < 0) then data.a = 1 end
end

function E:NewColorTable(r, g, b, a)
	-- this function doesnt update the color to a mixin (unlike SetColorTable)
	-- that makes it safe to use it for creating new colors for the db
	-- dont upgrade the table to a mixin here

	local data = { r = r, g = g, b = b, a = a }

	E:VerifyColorTable(data)

	return data
end

function E:UpdateColorTable(data)
	E:VerifyColorTable(data)

	return data.r, data.g, data.b, data.a
end

function E:GetColorTable(data)
	E:VerifyColorTable(data)

	local r, g, b, a = data.r, data.g, data.b, data.a
	return { r, g, b, a, r = r, g = g, b = b, a = a }
end

function E:UpdateMedia(mediaType)
	if not E.db.general or not E.private.general then return end

	E.media.normFont = LSM:Fetch('font', E.db.general.font)
	E.media.combatFont = LSM:Fetch('font', E.private.general.dmgfont)
	E.media.blankTex = LSM:Fetch('background', 'ElvUIChat Blank')
	E.media.normTex = LSM:Fetch('statusbar', E.private.general.normTex)
	E.media.glossTex = LSM:Fetch('statusbar', E.private.general.glossTex)

	local fallbackTex = (E.Media and E.Media.Textures and E.Media.Textures.NormTex) or E.ClearTexture
	if not E.media.normTex then E.media.normTex = fallbackTex end
	if not E.media.glossTex then E.media.glossTex = fallbackTex end

	if mediaType then -- callback from SharedMedia: LSM.Register
		-- TODO: UpdateBlizzardFonts may be missing in chat-only builds; confirm future inclusion
		if mediaType == 'font' and E.UpdateBlizzardFonts then
			E:UpdateBlizzardFonts()
		end

		return
	end

	-- Colors
	E.media.bordercolor = E:SetColorTable(E.media.bordercolor, E:UpdateClassColor(E.db.general.bordercolor))
	E.media.backdropcolor = E:SetColorTable(E.media.backdropcolor, E:UpdateClassColor(E.db.general.backdropcolor))
	E.media.backdropfadecolor = E:SetColorTable(E.media.backdropfadecolor, E:UpdateClassColor(E.db.general.backdropfadecolor))

	-- Custom Glow Color
	E.media.customGlowColor = E:SetColorTable(E.media.customGlowColor, E:UpdateClassColor(E.db.general.customGlow.color))

	local value = E:UpdateClassColor(E.db.general.valuecolor)
	E.media.rgbvaluecolor = E:SetColorTable(E.media.rgbvaluecolor, value)
	E.media.hexvaluecolor = E:RGBToHex(value.r, value.g, value.b)

	-- TODO: cooldown settings can be nil in slimmed chat builds; decide if we should enforce presence
	if E.db.cooldown and E.db.cooldown.enable then
		for key in next, P.cooldown do
			local db = type(key) == 'table' and E.db.cooldown[key]
			if db then
				E:UpdateClassColor(db.colors.text)
				E:UpdateClassColor(db.colors.edge)
				E:UpdateClassColor(db.colors.edgeCharge)
				E:UpdateClassColor(db.colors.swipe)
				E:UpdateClassColor(db.colors.swipeCharge)
				E:UpdateClassColor(db.colors.swipeLOC)
			end
		end
	end

	if E.private.chat.enable then
		-- Chat Tab Selector Color
		E:UpdateClassColor(E.db.chat.tabSelectorColor)
		E:UpdateClassColor(E.db.chat.tabSelectedTextColor)

		-- Chat Panel Background Texture
		local LeftChatPanel = _G.LeftChatPanel
		if LeftChatPanel and LeftChatPanel.tex then
			LeftChatPanel.tex:SetTexture(E.db.chat.panelBackdropNameLeft)

			local a = E.db.general.backdropfadecolor.a or 0.5
			LeftChatPanel.tex:SetAlpha(a)
		end
	end

	E:ValueFuncCall()
	-- TODO: UpdateBlizzardFonts optional in this subset; revisit guard once font pipeline is finalized
	if E.UpdateBlizzardFonts then
		E:UpdateBlizzardFonts()
	end
end

function E:GeneralMedia_ApplyToAll()
	local font = E.db.general.font
	local fontSize = E.db.general.fontSize


	-- Only chat module exists
	E.db.chat.font = font
	E.db.chat.fontSize = fontSize
	E.db.chat.tabFont = font
	E.db.chat.tabFontSize = fontSize

	E:StaggeredUpdateAll()
end

function E:ValueFuncCall()
	local hex, r, g, b = E.media.hexvaluecolor, unpack(E.media.rgbvaluecolor)
	for obj, func in pairs(E.valueColorUpdateFuncs) do
		func(obj, hex, r, g, b)
	end
end

function E:UpdateFrameTemplates()
	for frame in pairs(E.frames) do
		if frame and frame.template and not frame:IsForbidden() then
			if not (frame.ignoreUpdates or frame.ignoreFrameTemplates) then
				frame:SetTemplate(frame.template, frame.glossTex, nil, frame.forcePixelMode)
			end
		else
			E.frames[frame] = nil
		end
	end

	for frame in pairs(E.unitFrameElements) do
		if frame and frame.template and not frame:IsForbidden() then
			if not (frame.ignoreUpdates or frame.ignoreFrameTemplates) then
				frame:SetTemplate(frame.template, frame.glossTex, nil, frame.forcePixelMode, frame.isUnitFrameElement)
			end
		else
			E.unitFrameElements[frame] = nil
		end
	end
end

function E:UpdateBorderColors()
	local r, g, b = unpack(E.media.bordercolor)
	for frame in pairs(E.frames) do
		if frame and frame.template and not frame:IsForbidden() then
			if not (frame.ignoreUpdates or frame.forcedBorderColors) and (frame.template == 'Default' or frame.template == 'Transparent') then
				frame:SetBackdropBorderColor(r, g, b)
			end
		else
			E.frames[frame] = nil
		end
	end

	local r2, g2, b2 = unpack(E.media.unitframeBorderColor)
	for frame in pairs(E.unitFrameElements) do
		if frame and frame.template and not frame:IsForbidden() then
			if not (frame.ignoreUpdates or frame.forcedBorderColors) and (frame.template == 'Default' or frame.template == 'Transparent') then
				frame:SetBackdropBorderColor(r2, g2, b2)
			end
		else
			E.unitFrameElements[frame] = nil
		end
	end
end

function E:UpdateBackdropColors()
	local r, g, b, a = unpack(E.media.backdropcolor)
	local r2, g2, b2, a2 = unpack(E.media.backdropfadecolor)

	for frame in pairs(E.frames) do
		if frame and frame.template and not frame:IsForbidden() then
			if not frame.ignoreUpdates then
				if frame.callbackBackdropColor then
					frame:callbackBackdropColor()
				elseif frame.template == 'Default' then
					frame:SetBackdropColor(r, g, b, frame.customBackdropAlpha or a)
				elseif frame.template == 'Transparent' then
					frame:SetBackdropColor(r2, g2, b2, frame.customBackdropAlpha or a2)
				end
			end
		else
			E.frames[frame] = nil
		end
	end

	for frame in pairs(E.unitFrameElements) do
		if frame and frame.template and not frame:IsForbidden() then
			if not frame.ignoreUpdates then
				if frame.callbackBackdropColor then
					frame:callbackBackdropColor()
				elseif frame.template == 'Default' then
					frame:SetBackdropColor(r, g, b, frame.customBackdropAlpha or a)
				elseif frame.template == 'Transparent' then
					frame:SetBackdropColor(r2, g2, b2, frame.customBackdropAlpha or a2)
				end
			end
		else
			E.unitFrameElements[frame] = nil
		end
	end
end

function E:UpdateFontTemplates()
	for text in pairs(E.texts) do
		if text then
			text:FontTemplate(text.font, text.fontSize, text.fontStyle, true)
		else
			E.texts[text] = nil
		end
	end
end

function E:RegisterStatusBar(statusBar)
	E.statusBars[statusBar] = true
end

function E:UnregisterStatusBar(statusBar)
	E.statusBars[statusBar] = nil
end

function E:UpdateStatusBars()
	for statusBar in pairs(E.statusBars) do
		if statusBar and statusBar:IsObjectType('StatusBar') then
			statusBar:SetStatusBarTexture(E.media.normTex)
		elseif statusBar and statusBar:IsObjectType('Texture') then
			statusBar:SetTexture(E.media.normTex)
		end
	end
end

do
	local cancel = function(popup)
		DisableAddOn(popup.addon, E.myguid)
		ReloadUI()
	end

	function E:IncompatibleAddOn(addon, module, info)
		local popup = E.PopupDialogs.INCOMPATIBLE_ADDON
		popup.button2 = info.name or module
		popup.button1 = addon
		popup.module = module
		popup.addon = addon
		popup.accept = info.accept
		popup.cancel = info.cancel or cancel

		E:StaticPopup_Show('INCOMPATIBLE_ADDON', popup.button1, popup.button2)
	end
end

function E:IsIncompatible(module, addons)
	for _, addon in ipairs(addons) do
		local incompatible
		if addon == 'Leatrix_Plus' then
			local db = _G.LeaPlusDB
			incompatible = db and db.MinimapMod == 'On'
		else
			incompatible = E:IsAddOnEnabled(addon)
		end

		if incompatible then
			E:IncompatibleAddOn(addon, module, addons.info)
			return true
		end
	end
end

do
	-- ElvUIChat: Only check for Chat module conflicts
	local ADDONS = {
		Chat = {
			info = {
				enabled = function() return E.private.chat.enable end,
				accept = function() E.private.chat.enable = false; ReloadUI() end,
				name = 'ElvUI Chat'
			},
			'Prat-3.0',
			'Chatter',
			'Chattynator',
			'Glass'
		}
	}

	E.INCOMPATIBLE_ADDONS = ADDONS -- let addons have the ability to alter this list to trigger our popup if they want
	function E:AddIncompatible(module, addonName)
		if ADDONS[module] then
			tinsert(ADDONS[module], addonName)
		else
			print(module, 'is not in the incompatibility list.')
		end
	end

	function E:CheckIncompatible()
		if E.global.ignoreIncompatible then return end

		for module, addons in pairs(ADDONS) do
			if addons[1] and addons.info.enabled() and E:IsIncompatible(module, addons) then
				break
			end
		end
	end
end

function E:CopyTable(current, default, merge)
	if type(current) ~= 'table' then
		current = {}
	end

	if type(default) == 'table' then
		for option, value in pairs(default) do
			local isTable = type(value) == 'table'
			if not merge or (isTable or current[option] == nil) then
				current[option] = (isTable and E:CopyTable(current[option], value, merge)) or value
			end
		end
	end

	return current
end

function E:RemoveEmptySubTables(tbl)
	if type(tbl) ~= 'table' then
		E:Print('Bad argument #1 to \'RemoveEmptySubTables\' (table expected)')
		return
	end

	for k, v in pairs(tbl) do
		if type(v) == 'table' then
			if next(v) == nil then
				tbl[k] = nil
			else
				E:RemoveEmptySubTables(v)
			end
		end
	end
end

--Compare 2 tables and remove duplicate key/value pairs
--param cleanTable : table you want cleaned
--param checkTable : table you want to check against.
--param generatedKeys : table defined in `Distributor.lua` to allow user generated tables to be exported (customTexts, customCurrencies, etc).
--return : a copy of cleanTable with duplicate key/value pairs removed
function E:RemoveTableDuplicates(cleanTable, checkTable, generatedKeys)
	if type(cleanTable) ~= 'table' then
		E:Print('Bad argument #1 to \'RemoveTableDuplicates\' (table expected)')
		return
	end
	if type(checkTable) ~= 'table' then
		E:Print('Bad argument #2 to \'RemoveTableDuplicates\' (table expected)')
		return
	end

	local rtdCleaned = {}
	local keyed = type(generatedKeys) == 'table'
	for option, value in pairs(cleanTable) do
		local default = checkTable[option]
		local genTable, genOption
		if keyed then
			genTable = generatedKeys[option]
		else
			genOption = generatedKeys
		end

		-- we only want to add settings which are existing in the default table, unless it's allowed by generatedKeys
		if default ~= nil or (genTable or genOption ~= nil) then
			if type(value) == 'table' and type(default) == 'table' then
				if genOption ~= nil then
					rtdCleaned[option] = E:RemoveTableDuplicates(value, default, genOption)
				else
					rtdCleaned[option] = E:RemoveTableDuplicates(value, default, genTable or nil)
				end
			elseif cleanTable[option] ~= default then
				-- add unique data to our clean table
				rtdCleaned[option] = value
			end
		end
	end

	--Clean out empty sub-tables
	E:RemoveEmptySubTables(rtdCleaned)

	return rtdCleaned
end

--Compare 2 tables and remove blacklisted key/value pairs
--param cleanTable : table you want cleaned
--param blacklistTable : table you want to check against.
--return : a copy of cleanTable with blacklisted key/value pairs removed
function E:FilterTableFromBlacklist(cleanTable, blacklistTable)
	if type(cleanTable) ~= 'table' then
		E:Print('Bad argument #1 to \'FilterTableFromBlacklist\' (table expected)')
		return
	end
	if type(blacklistTable) ~= 'table' then
		E:Print('Bad argument #2 to \'FilterTableFromBlacklist\' (table expected)')
		return
	end

	local tfbCleaned = {}
	for option, value in pairs(cleanTable) do
		if type(value) == 'table' and blacklistTable[option] and type(blacklistTable[option]) == 'table' then
			tfbCleaned[option] = E:FilterTableFromBlacklist(value, blacklistTable[option])
		else
			-- Filter out blacklisted keys
			if blacklistTable[option] ~= true then
				tfbCleaned[option] = value
			end
		end
	end

	--Clean out empty sub-tables
	E:RemoveEmptySubTables(tfbCleaned)

	return tfbCleaned
end

local function KeySort(a, b)
	local A, B = type(a), type(b)

	if A == B then
		if A == 'number' or A == 'string' then
			return a < b
		elseif A == 'boolean' then
			return (a and 1 or 0) > (b and 1 or 0)
		end
	end

	return A < B
end

do	--The code in this function is from WeakAuras, credit goes to Mirrored and the WeakAuras Team
	--Code slightly modified by Simpy, sorting from @sighol
	local function Recurse(tbl, level, ret)
		local tkeys = {}
		for i in pairs(tbl) do tinsert(tkeys, i) end
		sort(tkeys, KeySort)

		for _, i in ipairs(tkeys) do
			local v = tbl[i]

			ret = ret..strrep('    ', level)..'['
			if type(i) == 'string' then ret = ret..'"'..i..'"' else ret = ret..i end
			ret = ret..'] = '

			if type(v) == 'number' then
				ret = ret..v..',\n'
			elseif type(v) == 'string' then
				ret = ret..'"'..v:gsub('\\', '\\\\'):gsub('\n', '\\n'):gsub('"', '\\"'):gsub('\124', '\124\124')..'",\n'
			elseif type(v) == 'boolean' then
				if v then ret = ret..'true,\n' else ret = ret..'false,\n' end
			elseif type(v) == 'table' then
				ret = ret..'{\n'
				ret = Recurse(v, level + 1, ret)
				ret = ret..strrep('    ', level)..'},\n'
			else
				ret = ret..'"'..tostring(v)..'",\n'
			end
		end

		return ret
	end

	function E:TableToLuaString(inTable)
		if type(inTable) ~= 'table' then
			E:Print('Invalid argument #1 to E:TableToLuaString (table expected)')
			return
		end

		local ret = '{\n'
		if inTable then ret = Recurse(inTable, 1, ret) end
		ret = ret..'}'

		return ret
	end
end

do	--The code in this function is from WeakAuras, credit goes to Mirrored and the WeakAuras Team
	--Code slightly modified by Simpy, sorting from @sighol
	local lineStructureTable, profileFormat = {}, {
		profile = 'E.db',
		private = 'E.private',
		global = 'E.global',
		filters = 'E.global'
	}

	local function BuildLineStructure(str) -- str is profileText
		for _, v in ipairs(lineStructureTable) do
			if type(v) == 'string' then
				str = str..'["'..v..'"]'
			else
				str = str..'['..v..']'
			end
		end

		return str
	end

	local sameLine
	local function Recurse(tbl, ret, profileText)
		local tkeys = {}
		for i in pairs(tbl) do tinsert(tkeys, i) end
		sort(tkeys, KeySort)

		local lineStructure = BuildLineStructure(profileText)
		for _, k in ipairs(tkeys) do
			local v = tbl[k]

			if not sameLine then
				ret = ret..lineStructure
			end

			ret = ret..'['

			if type(k) == 'string' then
				ret = ret..'"'..k..'"'
			else
				ret = ret..k
			end

			if type(v) == 'table' then
				tinsert(lineStructureTable, k)
				sameLine = true
				ret = ret..']'
				ret = Recurse(v, ret, profileText)
			else
				sameLine = false
				ret = ret..'] = '

				if type(v) == 'number' then
					ret = ret..v..'\n'
				elseif type(v) == 'string' then
					ret = ret..'"'..v:gsub('\\', '\\\\'):gsub('\n', '\\n'):gsub('"', '\\"'):gsub('\124', '\124\124')..'"\n'
				elseif type(v) == 'boolean' then
					if v then
						ret = ret..'true\n'
					else
						ret = ret..'false\n'
					end
				else
					ret = ret..'"'..tostring(v)..'"\n'
				end
			end
		end

		tremove(lineStructureTable)

		return ret
	end

	function E:ProfileTableToPluginFormat(inTable, profileType)
		local profileText = profileFormat[profileType]
		if not profileText then return end

		wipe(lineStructureTable)

		local ret = ''
		if inTable and profileType then
			sameLine = false
			ret = Recurse(inTable, ret, profileText)
		end

		return ret
	end
end

do	--Split string by multi-character delimiter (the strsplit / string.split function provided by WoW doesn't allow multi-character delimiter)
	local splitTable = {}
	function E:SplitString(str, delim)
		assert(type (delim) == 'string' and strlen(delim) > 0, 'bad delimiter')

		local start = 1
		wipe(splitTable) -- results table

		-- find each instance of a string followed by the delimiter
		while true do
			local pos = strfind(str, delim, start, true) -- plain find
			if not pos then break end

			tinsert(splitTable, sub(str, start, pos - 1))
			start = pos + strlen(delim)
		end -- while

		-- insert final one (after last delimiter)
		tinsert(splitTable, sub(str, start))

		return unpack(splitTable)
	end
end

do
	local SendMessageWaiting -- only allow 1 delay at a time regardless of eventing
	function E:SendMessage()
		if IsInRaid() then
			C_ChatInfo_SendAddonMessage('ELVUI_VERSIONCHK', E.version, (not IsInRaid(LE_PARTY_CATEGORY_HOME) and IsInRaid(LE_PARTY_CATEGORY_INSTANCE)) and 'INSTANCE_CHAT' or 'RAID')
		elseif IsInGroup() then
			C_ChatInfo_SendAddonMessage('ELVUI_VERSIONCHK', E.version, (not IsInGroup(LE_PARTY_CATEGORY_HOME) and IsInGroup(LE_PARTY_CATEGORY_INSTANCE)) and 'INSTANCE_CHAT' or 'PARTY')
		elseif IsInGuild() then
			C_ChatInfo_SendAddonMessage('ELVUI_VERSIONCHK', E.version, 'GUILD')
		end

		SendMessageWaiting = nil
	end

	local SendRecieveGroupSize = 0
	local PLAYER_NAME = format('%s-%s', E.myname, E:ShortenRealm(E.myrealm))
	local function SendRecieve(_, event, prefix, message, _, senderOne, senderTwo)
		if event == 'CHAT_MSG_ADDON' then
			local sender = strfind(senderOne, '-') and senderOne or senderTwo
			if sender == PLAYER_NAME then
				return
			elseif prefix == 'ELVUI_VERSIONCHK' then
				local ver, msg, inCombat = E.version, tonumber(message), InCombatLockdown()

				E.UserList[E:StripMyRealm(sender)] = msg

				if msg and (msg > ver) and not E.recievedOutOfDateMessage then -- you're outdated D:
					E:Print(L["ElvUI is out of date. You can download the newest version from tukui.org."])

					if msg and ((msg - ver) >= 0.05) and not inCombat then
						E.PopupDialogs.ELVUI_UPDATE_AVAILABLE.text = L["ElvUI is five or more revisions out of date. You can download the newest version from tukui.org."]..format('\n\nSender %s : Version %s', sender, msg)

						E:StaticPopup_Show('ELVUI_UPDATE_AVAILABLE')
					end

					E.recievedOutOfDateMessage = true
				end
			end
		elseif event == 'GROUP_ROSTER_UPDATE' then
			local num = GetNumGroupMembers()
			if num ~= SendRecieveGroupSize then
				if num > 1 and num > SendRecieveGroupSize then
					if not SendMessageWaiting then
						SendMessageWaiting = E:Delay(10, E.SendMessage)
					end
				end
				SendRecieveGroupSize = num
			end
		elseif event == 'PLAYER_ENTERING_WORLD' then
			if not SendMessageWaiting then
				SendMessageWaiting = E:Delay(10, E.SendMessage)
			end
		end
	end

	_G.C_ChatInfo.RegisterAddonMessagePrefix('ELVUI_VERSIONCHK')

	local f = CreateFrame('Frame')
	f:SetScript('OnEvent', SendRecieve)
	f:RegisterEvent('CHAT_MSG_ADDON')
	f:RegisterEvent('GROUP_ROSTER_UPDATE')
	f:RegisterEvent('PLAYER_ENTERING_WORLD')
end

function E:UpdateStart(skipCallback, skipUpdateDB)
	if not skipUpdateDB then
		E:UpdateDB()
	end

	E:UpdateMoverPositions()
	E:UpdateMediaItems()

	if not skipCallback then
		E.callbacks:Fire('StaggeredUpdate')
	end
end

do -- BFA Convert, deprecated..
	local function ConvertAurawatch(spell)
		if spell.sizeOverride then spell.sizeOverride = nil end
		if spell.size then spell.size = nil end

		if not spell.sizeOffset then
			spell.sizeOffset = 0
		end

		if spell.styleOverride then
			spell.style = spell.styleOverride
			spell.styleOverride = nil
		elseif not spell.style then
			spell.style = 'coloredIcon'
		end
	end

	local ttModSwap
	do -- tooltip convert
		local swap = {ALL = 'HIDE', NONE = 'SHOW'}
		ttModSwap = function(val) return swap[val] end
	end

end

-- ElvUIChat: Simplified SetupDB for chat-only modules
function E:SetupDB()
	-- Chat module uses E.db.chat
	if E.Chat then
		E.Chat.db = E.db.chat
	end
	
	-- Skins module uses E.private.skins (not E.db)
	if E.Skins then
		E.Skins.db = E.private.skins
	end
	
end

function E:UpdateDB()
	E.private = E.charSettings.profile
	E.global = E.data.global
	E.db = E.data.profile

	E:SetupDB()

	-- ElvUIChat: Removed unitframe border color defaults - we don't have UnitFrames module
end

function E:UpdateMoverPositions()
	-- ElvUIChat: Stub - movers removed, chat doesn't need manual positioning
end



function E:UpdateMediaItems(skipCallback)
	E:UpdateMedia()
	if E.UpdateCustomClassColors then
		E:UpdateCustomClassColors()
	end
	E:UpdateFrameTemplates()

	if not skipCallback then
		E.callbacks:Fire('StaggeredUpdate')
	end
end

function E:UpdateLayout(skipCallback)
	Layout:ToggleChatPanels()
	
	if not skipCallback then
		E.callbacks:Fire('StaggeredUpdate')
	end
end


function E:UpdateChat(skipCallback)
	Chat:SetupChat()
	Chat:UpdateEditboxAnchors()

	if not skipCallback then
		E.callbacks:Fire('StaggeredUpdate')
	end
end

function E:UpdateEnd()
	if E.RefreshGUI then
		E:RefreshGUI()
	end

	-- ElvUIChat: Removed mover clamping - movers not needed for chat-only addon

	if E.staggerUpdateRunning then
		--We're doing a staggered update, but plugins expect the old UpdateAll to be called
		--So call it, but skip updates inside it
		E:UpdateAll(false)
	elseif not E.private.install_complete then
		-- ElvUIChat: Simple install - just mark as complete, chat works with defaults
		E.private.install_complete = E.version
	end

	--Done updating, let code now
	E.staggerUpdateRunning = false
end

do
	local staggerDelay = 0.02
	local staggerTable = {}
	local function CallStaggeredUpdate()
		local nextUpdate = staggerTable[1]
		local nextDelay
		if nextUpdate then
			tremove(staggerTable, 1)

			if nextUpdate == 'UpdateNamePlates' or nextUpdate == 'UpdateBags' then
				nextDelay = 0.05
			end

			E:Delay(nextDelay or staggerDelay, E[nextUpdate])
		end
	end
	E:RegisterCallback('StaggeredUpdate', CallStaggeredUpdate)

	function E:StaggeredUpdateAll(event)
		if not E.initialized then
			E:Delay(1, E.StaggeredUpdateAll, E, event)
			return
		end

		if (not event or event == 'OnProfileChanged' or event == 'OnProfileCopied') and not E.staggerUpdateRunning then

			tinsert(staggerTable, 'UpdateMisc')
			tinsert(staggerTable, 'UpdateEnd')
			--Stagger updates
			E.staggerUpdateRunning = true
			E:UpdateStart()
		else
			--Fire away
			E:UpdateAll(true)
		end
	end
end

function E:UpdateAll(doUpdates)
	if doUpdates then
		E:UpdateStart(true)

		E:UpdateLayout()
		if Chat.Initialized then
			E:UpdateChat()
		end
		E:UpdateMisc()
		E:UpdateEnd()
	end
end

do
	E.ObjectEventTable, E.ObjectEventFrame = {}, CreateFrame('Frame')
	local eventFrame, eventTable = E.ObjectEventFrame, E.ObjectEventTable

	eventFrame:SetScript('OnEvent', function(_, event, ...)
		local objs = eventTable[event]
		if objs then
			for object, funcs in pairs(objs) do
				for _, func in ipairs(funcs) do
					func(object, event, ...)
				end
			end
		end
	end)

	function E:HasFunctionForObject(event, object, func)
		if not (event and object and func) then
			E:Print('Error. Usage: HasFunctionForObject(event, object, func)')
			return
		end

		local objs = eventTable[event]
		local funcs = objs and objs[object]
		return funcs and tContains(funcs, func)
	end

	function E:IsEventRegisteredForObject(event, object)
		if not (event and object) then
			E:Print('Error. Usage: IsEventRegisteredForObject(event, object)')
			return
		end

		local objs = eventTable[event]
		local funcs = objs and objs[object]
		return funcs ~= nil, funcs
	end

	--- Registers specified event and adds specified func to be called for the specified object.
	-- Unless all parameters are supplied it will not register.
	-- If the specified object has already been registered for the specified event
	-- then it will just add the specified func to a table of functions that should be called.
	-- When a registered event is triggered, then the registered function is called with
	-- the object as first parameter, then event, and then all the parameters for the event itself.
	-- @param event The event you want to register.
	-- @param object The object you want to register the event for.
	-- @param func The function you want executed for this object.
	function E:RegisterEventForObject(event, object, func)
		if not (event and object and func) then
			E:Print('Error. Usage: RegisterEventForObject(event, object, func)')
			return
		end

		local objs = eventTable[event]
		if not objs then
			objs = {}
			eventTable[event] = objs
			pcall(eventFrame.RegisterEvent, eventFrame, event)
		end

		local funcs = objs[object]
		if not funcs then
			objs[object] = {func}
		elseif not tContains(funcs, func) then
			tinsert(funcs, func)
		end
	end

	--- Unregisters specified function for the specified object on the specified event.
	-- Unless all parameters are supplied it will not unregister.
	-- @param event The event you want to unregister an object from.
	-- @param object The object you want to unregister a func from.
	-- @param func The function you want unregistered for the object.
	function E:UnregisterEventForObject(event, object, func)
		if not (event and object and func) then
			E:Print('Error. Usage: UnregisterEventForObject(event, object, func)')
			return
		end

		local objs = eventTable[event]
		local funcs = objs and objs[object]
		if funcs then
			for index, fnc in ipairs(funcs) do
				if func == fnc then
					tremove(funcs, index)
					break
				end
			end

			if #funcs == 0 then
				objs[object] = nil
			end

			if not next(funcs) then
				eventFrame:UnregisterEvent(event)
				eventTable[event] = nil
			end
		end
	end

	function E:UnregisterAllEventsForObject(object, func)
		if not (object and func) then
			E:Print('Error. Usage: UnregisterAllEventsForObject(object, func)')
			return
		end

		for event in pairs(eventTable) do
			if E:IsEventRegisteredForObject(event, object) then
				E:UnregisterEventForObject(event, object, func)
			end
		end
	end
end


do
	local function Errorhandler(err)
		local handler = _G.geterrorhandler()
		if handler then
			return handler(err)
		end
	end

	function E:CallLoadFunc(func, ...)
		xpcall(func, Errorhandler, ...)
	end
end

function E:CallLoadedModule(obj, silent, object, index)
	local name, func = obj.name, obj.func

	local module = name and E:GetModule(name, silent)
	if not module then return end

	if func and type(func) == 'string' then
		E:CallLoadFunc(module[func], module)
	elseif func and type(func) == 'function' then
		E:CallLoadFunc(func, module)
	elseif module.Initialize then
		E:CallLoadFunc(module.Initialize, module)
	end

	if object and index then
		object[index] = nil
	end
end

function E:RegisterInitialModule(name, func)
	E.RegisteredInitialModules[#E.RegisteredInitialModules + 1] = { name = name, func = func }
end

do
	local loaded = {}
	function E:RegisterModule(name, func)
		if E.initialized then
			loaded.name = name
			loaded.func = func

			E:CallLoadedModule(loaded)
		else
			E.RegisteredModules[#E.RegisteredModules + 1] = { name = name, func = func }
		end
	end
end

function E:InitializeInitialModules()
	for index, object in ipairs(E.RegisteredInitialModules) do
		E:CallLoadedModule(object, true, E.RegisteredInitialModules, index)
	end
end

function E:InitializeModules()
	for index, object in ipairs(E.RegisteredModules) do
		E:CallLoadedModule(object, true, E.RegisteredModules, index)
	end
end


do
	-- Shamelessly taken from AceDB-3.0 and stripped down by Simpy
	function E:CopyDefaults(dest, src)
		for k, v in pairs(src) do
			if type(v) == 'table' then
				if not rawget(dest, k) then rawset(dest, k, {}) end
				if type(dest[k]) == 'table' then E:CopyDefaults(dest[k], v) end
			elseif rawget(dest, k) == nil then
				rawset(dest, k, v)
			end
		end

		return dest
	end

	function E:RemoveDefaults(db, defaults)
		setmetatable(db, nil)

		for k, v in pairs(defaults) do
			if type(v) == 'table' and type(db[k]) == 'table' then
				E:RemoveDefaults(db[k], v)
				if next(db[k]) == nil then db[k] = nil end
			elseif db[k] == defaults[k] then
				db[k] = nil
			end
		end

		return db
	end
end

function E:LoadCommands()
	E:RegisterChatCommand('elvuichat', 'ToggleOptions')
	E:RegisterChatCommand('ec', 'ToggleOptions')
end

function E:Initialize()
	wipe(E.db)
	wipe(E.global)
	wipe(E.private)

	E.myspec = GetSpecialization()
	E.TimerunningID = PlayerGetTimerunningSeasonID and PlayerGetTimerunningSeasonID()

	-- ElvUIChat: Use our namespaced database names
	E.data = E.Libs.AceDB:New('ElvUIChatDB', E.DF, true)
	E.data.RegisterCallback(E, 'OnProfileChanged', 'StaggeredUpdateAll')
	E.data.RegisterCallback(E, 'OnProfileCopied', 'StaggeredUpdateAll')
	E.data.RegisterCallback(E, 'OnProfileReset', 'OnProfileReset')

	E.charSettings = E.Libs.AceDB:New('ElvUIChatPrivateDB', E.privateVars)
	E.charSettings.RegisterCallback(E, 'OnProfileChanged', ReloadUI)
	E.charSettings.RegisterCallback(E, 'OnProfileCopied', ReloadUI)
	E.charSettings.RegisterCallback(E, 'OnProfileReset', 'OnPrivateProfileReset')

	E:UpdateDB()
	E:UIScale()
	E:LoadStaticPopups()

	E:LoadAPI()
	E:LoadCommands()
	E:UpdateMedia()
	E:InitializeModules()

	if E.UpdateCustomClassColors then
		E:UpdateCustomClassColors()
	end

	E.initialized = true

	E:LoadConfigOptions()

	-- ElvUIChat: Retail-only, always call Tutorials
	if E.Tutorials then
		E:Tutorials()
	end

	if E.db.general.tagUpdateRate and (E.db.general.tagUpdateRate ~= P.general.tagUpdateRate) then
		E:TagUpdateRate(E.db.general.tagUpdateRate)
	end

	if E.db.general.smoothingAmount and (E.db.general.smoothingAmount ~= P.general.smoothingAmount) then
		E:SetSmoothingAmount(E.db.general.smoothingAmount)
	end

	if not E.private.install_complete then
		-- ElvUIChat: Simple install - just mark as complete, chat works with defaults
		E.private.install_complete = E.version
	end

	-- TODO: skip UPDATE_REQUEST popup in chat-only build
	E.updateRequestTriggered = false

	if GetCVarBool('taintLog') then
		E:StaticPopup_Show('TAINT_LOG')
	elseif GetCVarBool('scriptProfile') then
		E:StaticPopup_Show('SCRIPT_PROFILE')
	end

	if E.db.general.loginmessage then
		local msg, _ = format(L["LOGIN_MSG"], E.versionString)

		if Chat.Initialized then -- setup the link
			_, msg = Chat:FindURL('CHAT_MSG_DUMMY', msg)
		end

		print(msg)
		print(L["LOGIN_MSG_HELP"])
	end
end
