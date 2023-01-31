local ElvUIChat = select(2, ...)
ElvUIChat[2] = ElvUIChat[1].Libs.ACL:GetLocale('ElvUIChat', ElvUIChat[1]:GetLocale()) -- Locale doesn't exist yet, make it exist.
local E, L, V, P, G = unpack(ElvUIChat)
local LCS = E.Libs.LCS

local _G = _G
local tonumber, pairs, ipairs, error, unpack, select, tostring = tonumber, pairs, ipairs, error, unpack, select, tostring
local strsplit, strjoin, wipe, sort, tinsert, tremove, tContains = strsplit, strjoin, wipe, sort, tinsert, tremove, tContains
local format, find, strrep, strlen, sub, gsub = format, strfind, strrep, strlen, strsub, gsub
local assert, type, pcall, xpcall, next, print = assert, type, pcall, xpcall, next, print
local rawget, rawset, setmetatable = rawget, rawset, setmetatable

local CreateFrame = CreateFrame
local GetSpellInfo = GetSpellInfo
local GetCVarBool = GetCVarBool
local GetNumGroupMembers = GetNumGroupMembers
local InCombatLockdown = InCombatLockdown
local GetAddOnEnableState = GetAddOnEnableState
local UnitFactionGroup = UnitFactionGroup
local DisableAddOn = DisableAddOn
local IsInGroup = IsInGroup
local IsInGuild = IsInGuild
local IsInRaid = IsInRaid
local ReloadUI = ReloadUI
local UnitGUID = UnitGUID
local GetBindingKey = GetBindingKey
local SetBinding = SetBinding
local SaveBindings = SaveBindings
local GetCurrentBindingSet = GetCurrentBindingSet
local GetSpecialization = (E.Classic or E.Wrath and LCS.GetSpecialization) or GetSpecialization

local ERR_NOT_IN_COMBAT = ERR_NOT_IN_COMBAT
local LE_PARTY_CATEGORY_HOME = LE_PARTY_CATEGORY_HOME
local LE_PARTY_CATEGORY_INSTANCE = LE_PARTY_CATEGORY_INSTANCE
local C_ChatInfo_SendAddonMessage = C_ChatInfo.SendAddonMessage
-- GLOBALS: ElvUIChatCharacterDB

--Modules
local Blizzard = E:GetModule('Blizzard')
local Chat = E:GetModule('Chat')
local Layout = E:GetModule('Layout')
local LSM = E.Libs.LSM

--Constants
E.noop = function() end
E.title = format('%s%s|r', E.InfoColor, 'ElvUIChat')
E.version = tonumber(GetAddOnMetadata('ElvUIChat', 'Version'))
E.toc = tonumber(GetAddOnMetadata('ElvUIChat', 'X-Interface'))
E.myfaction, E.myLocalizedFaction = UnitFactionGroup('player')
E.mylevel = UnitLevel('player')
E.myLocalizedClass, E.myclass, E.myClassID = UnitClass('player')
E.myLocalizedRace, E.myrace, E.myRaceID = UnitRace('player')
E.myname = UnitName('player')
E.myrealm = GetRealmName()
E.mynameRealm = format('%s - %s', E.myname, E.myrealm) -- contains spaces/dashes in realm (for profile keys)
E.myspec = E.Retail and GetSpecialization()
E.wowbuild = tonumber(E.wowbuild)
E.physicalWidth, E.physicalHeight = GetPhysicalScreenSize()
E.screenWidth, E.screenHeight = GetScreenWidth(), GetScreenHeight()
E.resolution = format('%dx%d', E.physicalWidth, E.physicalHeight)
E.perfect = 768 / E.physicalHeight
E.NewSign = [[|TInterface\OptionsFrame\UI-OptionsFrame-NewFeatureIcon:14:14|t]]
E.TexturePath = [[Interface\AddOns\ElvUIChat\Media\Textures\]] -- for plugins?
E.ClearTexture = not E.Classic and 0 or '' -- used to clear: Set (Normal, Disabled, Checked, Pushed, Highlight) Texture
E.UserList = {}

--Tables
E.media = {}
E.frames = {}
E.statusBars = {}
E.texts = {}
E.snapBars = {}
E.RegisteredModules = {}
E.RegisteredInitialModules = {}
E.valueColorUpdateFuncs = {}
E.TexCoords = {0, 1, 0, 1}
E.FrameLocks = {}
E.VehicleLocks = {}
E.CreditsList = {}
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
--Workaround for people wanting to use white and it reverting to their class color.
E.PriestColors = { r = 0.99, g = 0.99, b = 0.99, colorStr = 'fffcfcfc' }

--This frame everything in ElvUIChat should be anchored to for Eyefinity support.
E.UIParent = CreateFrame('Frame', 'ElvUIParent', _G.UIParent)
E.UIParent:SetFrameLevel(_G.UIParent:GetFrameLevel())
E.UIParent:SetSize(E.screenWidth, E.screenHeight)
E.UIParent:SetPoint('BOTTOM')
E.UIParent.origHeight = E.UIParent:GetHeight()
E.snapBars[#E.snapBars + 1] = E.UIParent

E.HiddenFrame = CreateFrame('Frame', nil, _G.UIParent)
E.HiddenFrame:SetPoint('BOTTOM')
E.HiddenFrame:SetSize(1,1)
E.HiddenFrame:Hide()

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

--
-- TODO: REVIEW LoadCommands
--
function E:LoadCommands()
	self:RegisterChatCommand('ec', 'ToggleOptions')
end

--
-- TODO: REVIEW UpdateBlizzardFonts
--
local chatFontHeights = {6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20}
function E:UpdateBlizzardFonts()
	_G.CHAT_FONT_HEIGHTS = chatFontHeights
end

function E:Print(...)
	(E.db and _G[E.db.general.messageRedirect] or _G.DEFAULT_CHAT_FRAME):AddMessage(strjoin('', E.media.hexvaluecolor or '|cff00b3ff', 'ElvUIChat:|r ', ...)) -- I put DEFAULT_CHAT_FRAME as a fail safe.
end

function E:GrabColorPickerValues(r, g, b)
	-- we must block the execution path to `ColorCallback` in `AceGUIWidget-ColorPicker-ElvUIChat`
	-- in order to prevent an infinite loop from `OnValueChanged` when passing into `E.UpdateMedia` which eventually leads here again.
	_G.ColorPickerFrame.noColorCallback = true

	-- grab old values
	local oldR, oldG, oldB = _G.ColorPickerFrame:GetColorRGB()

	-- set and define the new values
	_G.ColorPickerFrame:SetColorRGB(r, g, b)
	r, g, b = _G.ColorPickerFrame:GetColorRGB()

	-- swap back to the old values
	if oldR then _G.ColorPickerFrame:SetColorRGB(oldR, oldG, oldB) end

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
		local color = E:ClassColor(E.myclass, true)
		if color then
			db.r, db.g, db.b = color.r, color.g, color.b
		end
	end

	return db
end

function E:SetColorTable(t, data)
	if not data.r or not data.g or not data.b then
		error('SetColorTable: Could not unpack color values.')
	end

	if t and (type(t) == 'table') then
		local r, g, b, a = E:UpdateColorTable(data)

		t.r, t.g, t.b, t.a = r, g, b, a
		t[1], t[2], t[3], t[4] = r, g, b, a
	else
		t = E:GetColorTable(data)
	end

	return t
end

function E:VerifyColorTable(data)
	if data.r > 1 or data.r < 0 then data.r = 1 end
	if data.g > 1 or data.g < 0 then data.g = 1 end
	if data.b > 1 or data.b < 0 then data.b = 1 end
	if data.a and (data.a > 1 or data.a < 0) then data.a = 1 end
end

function E:UpdateColorTable(data)
	if not data.r or not data.g or not data.b then
		error('UpdateColorTable: Could not unpack color values.')
	end

	E:VerifyColorTable(data)

	return data.r, data.g, data.b, data.a
end

function E:GetColorTable(data)
	if not data.r or not data.g or not data.b then
		error('GetColorTable: Could not unpack color values.')
	end

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

	if mediaType then -- callback from SharedMedia: LSM.Register
		if mediaType == 'font' then
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

	if E.private.chat.enable then
		-- Chat Tab Selector Color
		E:UpdateClassColor(E.db.chat.tabSelectorColor)
		E:UpdateClassColor(E.db.chat.tabSelectedTextColor)

		-- Chat Panel Background Texture
		local LeftChatPanel, RightChatPanel = _G.LeftChatPanel, _G.RightChatPanel
		if LeftChatPanel and LeftChatPanel.tex and RightChatPanel and RightChatPanel.tex then
			LeftChatPanel.tex:SetTexture(E.db.chat.panelBackdropNameLeft)
			RightChatPanel.tex:SetTexture(E.db.chat.panelBackdropNameRight)

			local a = E.db.general.backdropfadecolor.a or 0.5
			LeftChatPanel.tex:SetAlpha(a)
			RightChatPanel.tex:SetAlpha(a)
		end
	end

	E:ValueFuncCall()
	E:UpdateBlizzardFonts()
end

function E:GeneralMedia_ApplyToAll()
	local font = E.db.general.font
	local fontSize = E.db.general.fontSize
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
end

function E:UpdateBackdropColors()
	local r, g, b = unpack(E.media.backdropcolor)
	local r2, g2, b2, a2 = unpack(E.media.backdropfadecolor)

	for frame in pairs(E.frames) do
		if frame and frame.template and not frame:IsForbidden() then
			if not frame.ignoreUpdates then
				if frame.callbackBackdropColor then
					frame:callbackBackdropColor()
				elseif frame.template == 'Default' then
					frame:SetBackdropColor(r, g, b)
				elseif frame.template == 'Transparent' then
					frame:SetBackdropColor(r2, g2, b2, frame.customBackdropAlpha or a2)
				end
			end
		else
			E.frames[frame] = nil
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
		DisableAddOn(popup.addon)
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

function E:IsAddOnEnabled(addon)
	return GetAddOnEnableState(E.myname, addon) == 2
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
	local ADDONS = {
		Chat = {
			info = {
				enabled = function() return E.private.chat.enable end,
				accept = function() E.private.chat.enable = false; ReloadUI() end,
				name = 'ElvUIChat Chat'
			},
			'Prat-3.0',
			'Chatter',
			'Glass'
		},
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

function E:CopyTable(current, default)
	if type(current) ~= 'table' then
		current = {}
	end

	if type(default) == 'table' then
		for option, value in pairs(default) do
			current[option] = (type(value) == 'table' and E:CopyTable(current[option], value)) or value
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
		local default, genTable, genOption = checkTable[option]
		if keyed then genTable = generatedKeys[option] else genOption = generatedKeys end

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

local function keySort(a, b)
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
	local function recurse(tbl, level, ret)
		local tkeys = {}
		for i in pairs(tbl) do tinsert(tkeys, i) end
		sort(tkeys, keySort)

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
				ret = recurse(v, level + 1, ret)
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
		if inTable then ret = recurse(inTable, 1, ret) end
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
		-- filters = 'E.global',
		-- styleFilters = 'E.global'
	}

	local function buildLineStructure(str) -- str is profileText
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
	local function recurse(tbl, ret, profileText)
		local tkeys = {}
		for i in pairs(tbl) do tinsert(tkeys, i) end
		sort(tkeys, keySort)

		local lineStructure = buildLineStructure(profileText)
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
				ret = recurse(v, ret, profileText)
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
			ret = recurse(inTable, ret, profileText)
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
			local pos = find(str, delim, start, true) -- plain find
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
	local function SendRecieve(_, event, prefix, message, _, sender)
		if event == 'CHAT_MSG_ADDON' then
			if sender == PLAYER_NAME then return end
			if prefix == 'ELVUI_VERSIONCHK' then
				local ver, msg, inCombat = E.version, tonumber(message), InCombatLockdown()

				E.UserList[E:StripMyRealm(sender)] = msg

				if msg and (msg > ver) and not E.recievedOutOfDateMessage then -- you're outdated D:
					E:Print(L["ElvUIChat is out of date. You can download the newest version from www.tukui.org. Get premium membership and have ElvUIChat automatically updated with the Tukui Client!"])

					if msg and ((msg - ver) >= 0.05) and not inCombat then
						E.PopupDialogs.ELVUI_UPDATE_AVAILABLE.text = L["ElvUIChat is five or more revisions out of date. You can download the newest version from www.tukui.org. Get premium membership and have ElvUIChat automatically updated with the Tukui Client!"]..format('|n|nSender %s : Version %s', sender, msg)

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
	f:RegisterEvent('CHAT_MSG_ADDON')
	f:RegisterEvent('GROUP_ROSTER_UPDATE')
	f:RegisterEvent('PLAYER_ENTERING_WORLD')
	f:SetScript('OnEvent', SendRecieve)
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

function E:UpdateDB()
	E.private = E.charSettings.profile
	E.global = E.data.global
	E.db = E.data.profile
	Chat.db = E.db.chat
	--Not part of staggered update
end

function E:UpdateMoverPositions()
	--The mover is positioned before it is resized, which causes issues for unitframes
	--Allow movers to be 'pushed' outside the screen, when they are resized they should be back in the screen area.
	--We set movers to be clamped again at the bottom of this function.
	E:SetMoversClampedToScreen(false)
	E:SetMoversPositions()

	--Not part of staggered update
end

function E:UpdateMediaItems(skipCallback)
	E:UpdateMedia()
	E:UpdateFrameTemplates()
	E:UpdateStatusBars()

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


function E:UpdateMisc(skipCallback)
	--AFK:Toggle()

	if not skipCallback then
		E.callbacks:Fire('StaggeredUpdate')
	end
end

function E:UpdateEnd()

	if E.RefreshGUI then
		E:RefreshGUI()
	end

	E:SetMoversClampedToScreen(true) -- Go back to using clamp after resizing has taken place.

	if E.staggerUpdateRunning then
		--We're doing a staggered update, but plugins expect the old UpdateAll to be called
		--So call it, but skip updates inside it
		E:UpdateAll(false)
	elseif not E.private.install_complete then
		E:Install()
	end

	--Done updating, let code now
	E.staggerUpdateRunning = false
end

do
	local staggerDelay = 0.02
	local staggerTable = {}
	local function CallStaggeredUpdate()
		local nextUpdate, nextDelay = staggerTable[1]
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
			tinsert(staggerTable, 'UpdateLayout')
			
			if Chat.Initialized then
				tinsert(staggerTable, 'UpdateChat')
			end
			
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

function E:ResetAllUI()
	E:ResetMovers()

	if E.db.lowresolutionset then
		E:SetupResolution(true)
	end

	if E.db.layoutSet then
		E:SetupLayout(E.db.layoutSet, true)
	end
end

function E:ResetUI(...)
	if InCombatLockdown() then E:Print(ERR_NOT_IN_COMBAT) return end

	if ... == '' or ... == ' ' or ... == nil then
		E:StaticPopup_Show('RESETUI_CHECK')
		return
	end

	E:ResetMovers(...)
end

do
	local function errorhandler(err)
		return _G.geterrorhandler()(err)
	end

	function E:CallLoadFunc(func, ...)
		xpcall(func, errorhandler, ...)
	end
end

function E:CallLoadedModule(obj, silent, object, index)
	local name, func
	if type(obj) == 'table' then name, func = unpack(obj) else name = obj end
	local module = name and E:GetModule(name, silent)

	if not module then return end
	if func and type(func) == 'string' then
		E:CallLoadFunc(module[func], module)
	elseif func and type(func) == 'function' then
		E:CallLoadFunc(func, module)
	elseif module.Initialize then
		E:CallLoadFunc(module.Initialize, module)
	end

	if object and index then object[index] = nil end
end

function E:RegisterInitialModule(name, func)
	E.RegisteredInitialModules[#E.RegisteredInitialModules + 1] = (func and {name, func}) or name
end

function E:RegisterModule(name, func)
	if E.initialized then
		E:CallLoadedModule((func and {name, func}) or name)
	else
		E.RegisteredModules[#E.RegisteredModules + 1] = (func and {name, func}) or name
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

function E:DBConversions()
	-- release converts, only one call per version
	if E.db.dbConverted ~= E.version then
		E.db.dbConverted = E.version
	end

	-- development converts

	-- always convert
	if not ElvUIChatCharacterDB.ConvertKeybindings then
		E:ConvertActionBarKeybinds()
		ElvUIChatCharacterDB.ConvertKeybindings = true
	end
end

function E:ConvertActionBarKeybinds()
	for oldcmd, newcmd in pairs({ ELVUIBAR6BUTTON = 'ELVUIBAR2BUTTON', EXTRABAR7BUTTON = 'ELVUIBAR7BUTTON', EXTRABAR8BUTTON = 'ELVUIBAR8BUTTON', EXTRABAR9BUTTON = 'ELVUIBAR9BUTTON', EXTRABAR10BUTTON = 'ELVUIBAR10BUTTON' }) do
		for i = 1, 12 do
			local oldkey, newkey = format('%s%d', oldcmd, i), format('%s%d', newcmd, i)
			for _, key in next, { GetBindingKey(oldkey) } do
				SetBinding(key, newkey)
			end
		end
	end

	local cur = GetCurrentBindingSet()
	if cur and cur > 0 then
		SaveBindings(cur)
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

function E:Initialize()
	wipe(E.db)
	wipe(E.global)
	wipe(E.private)

	local playerGUID = UnitGUID('player')
	local _, serverID = strsplit('-', playerGUID)
	E.serverID = tonumber(serverID)
	E.myguid = playerGUID

	E.data = E.Libs.AceDB:New('ElvUIChatDB', E.DF, true)
	E.data.RegisterCallback(E, 'OnProfileChanged', 'StaggeredUpdateAll')
	E.data.RegisterCallback(E, 'OnProfileCopied', 'StaggeredUpdateAll')
	E.data.RegisterCallback(E, 'OnProfileReset', 'OnProfileReset')
	E.charSettings = E.Libs.AceDB:New('ElvUIChatPrivateDB', E.privateVars)
	E.charSettings.RegisterCallback(E, 'OnProfileChanged', ReloadUI)
	E.charSettings.RegisterCallback(E, 'OnProfileCopied', ReloadUI)
	E.charSettings.RegisterCallback(E, 'OnProfileReset', 'OnPrivateProfileReset')
	E.private = E.charSettings.profile
	E.global = E.data.global
	E.db = E.data.profile

	-- default the non thing pixel border color to 191919, otherwise its 000000
	if not E.PixelMode then P.general.bordercolor = { r = 0.1, g = 0.1, b = 0.1 } end

	E:DBConversions()
	E:UIScale()
	E:BuildPrefixValues()
	E:LoadAPI()
	E:LoadCommands()
	E:InitializeModules()
	E:LoadMovers()
	E:UpdateMedia()
	E:Contruct_StaticPopups()
	
	if E.Retail or E.Wrath then
		E.Libs.DualSpec:EnhanceDatabase(E.data, 'ElvUIChat')
	end

	E:LoadConfigOptions()
	
	E.initialized = true

	if E.db.general.smoothingAmount and (E.db.general.smoothingAmount ~= 0.33) then
		E:SetSmoothingAmount(E.db.general.smoothingAmount)
	end

	if not E.private.install_complete then
		E:Install()
	end

	if E.db.general.loginmessage then
		local msg = format(L["LOGIN_MSG"], E.version)
		if Chat.Initialized then msg = select(2, Chat:FindURL('CHAT_MSG_DUMMY', msg)) end
		print(msg)
	end
end
