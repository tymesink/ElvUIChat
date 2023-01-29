--[[
	~AddOn Engine~
	To load the AddOn engine inside another addon add this to the top of your file:
		local E, L, V, P, G = unpack(ElvUIChat) --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
]]

local _G, next, strfind = _G, next, strfind
local gsub, tinsert, type = gsub, tinsert, type
local GetBuildInfo = GetBuildInfo
local GetLocale = GetLocale
local GetTime = GetTime
local CreateFrame = CreateFrame
local ReloadUI = ReloadUI
local UIDropDownMenu_SetAnchor = UIDropDownMenu_SetAnchor

-- GLOBALS: ElvUIChatCharacterDB, ElvUIChatPrivateDB, ElvUIChatDB

local AceAddon, AceAddonMinor = _G.LibStub('AceAddon-3.0')
local CallbackHandler = _G.LibStub('CallbackHandler-1.0')

local AddOnName, Engine = ...
local E = AceAddon:NewAddon(AddOnName, 'AceConsole-3.0', 'AceEvent-3.0', 'AceTimer-3.0', 'AceHook-3.0')
E.DF = {profile = {}, global = {}}; E.privateVars = {profile = {}} -- Defaults
E.Options = {type = 'group', args = {}, childGroups = 'ElvUI_HiddenTree'}
E.callbacks = E.callbacks or CallbackHandler:New(E)
E.wowpatch, E.wowbuild, E.wowdate, E.wowtoc = GetBuildInfo()
E.locale = GetLocale()

Engine[1] = E
Engine[2] = {}
Engine[3] = E.privateVars.profile
Engine[4] = E.DF.profile
Engine[5] = E.DF.global
_G.ElvUIChat = Engine

E.AFK = E:NewModule('AFK','AceEvent-3.0','AceTimer-3.0')
E.Blizzard = E:NewModule('Blizzard','AceEvent-3.0','AceHook-3.0')
E.Chat = E:NewModule('Chat','AceTimer-3.0','AceHook-3.0','AceEvent-3.0')
E.Layout = E:NewModule('Layout','AceEvent-3.0')
E.Skins = E:NewModule('Skins','AceTimer-3.0','AceHook-3.0','AceEvent-3.0')

E.InfoColor = '|cff1784d1' -- blue
E.InfoColor2 = '|cff9b9b9b' -- silver

-- Expansions
E.Retail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
E.Classic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
E.TBC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC -- not used
E.Wrath = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC

-- Item Qualitiy stuff, also used by MerathilisUI
E.QualityColors = CopyTable(_G.BAG_ITEM_QUALITY_COLORS)
E.QualityColors[-1] = {r = 0, g = 0, b = 0}
E.QualityColors[Enum.ItemQuality.Poor] = {r = .61, g = .61, b = .61}
E.QualityColors[Enum.ItemQuality.Common or Enum.ItemQuality.Standard] = {r = 0, g = 0, b = 0}

do -- this is different from E.locale because we need to convert for ace locale files
	local convert = {enGB = 'enUS', esES = 'esMX', itIT = 'enUS'}
	local gameLocale = convert[E.locale] or E.locale or 'enUS'

	function E:GetLocale()
		return gameLocale
	end
end

do
	E.Libs = {}
	E.LibsMinor = {}
	function E:AddLib(name, major, minor)
		if not name then return end

		-- in this case: `major` is the lib table and `minor` is the minor version
		if type(major) == 'table' and type(minor) == 'number' then
			E.Libs[name], E.LibsMinor[name] = major, minor
		else -- in this case: `major` is the lib name and `minor` is the silent switch
			E.Libs[name], E.LibsMinor[name] = _G.LibStub(major, minor)
		end
	end

	E:AddLib('AceAddon', AceAddon, AceAddonMinor)
	E:AddLib('AceDB', 'AceDB-3.0')
	E:AddLib('ACH', 'LibAceConfigHelper')
	E:AddLib('LSM', 'LibSharedMedia-3.0')
	E:AddLib('ACL', 'AceLocale-3.0-ElvUIChat')
	E:AddLib('SimpleSticky', 'LibSimpleSticky-1.0')

	-- libraries used for options
	E:AddLib('AceGUI', 'AceGUI-3.0')
	E:AddLib('AceConfig', 'AceConfig-3.0-ElvUIChat')
	E:AddLib('AceConfigDialog', 'AceConfigDialog-3.0-ElvUIChat')
	E:AddLib('AceConfigRegistry', 'AceConfigRegistry-3.0-ElvUIChat')
	E:AddLib('AceDBOptions', 'AceDBOptions-3.0')

	if E.Retail then
		E:AddLib('DualSpec', 'LibDualSpec-1.0')
	end
end

do
	local a,b,c = '','([%(%)%.%%%+%-%*%?%[%^%$])','%%%1'
	function E:EscapeString(s) return gsub(s,b,c) end

	local d = {'|[TA].-|[ta]','|c[fF][fF]%x%x%x%x%x%x','|r','^%s+','%s+$'}
	function E:StripString(s, ignoreTextures)
		for i = ignoreTextures and 2 or 1, #d do s = gsub(s,d[i],a) end
		return s
	end
end

function E:OnEnable()
	E:Initialize()
end

function E:OnInitialize()
	if not ElvUIChatCharacterDB then
		ElvUIChatCharacterDB = {}
	end

	E.db = E:CopyTable({}, E.DF.profile)
	E.global = E:CopyTable({}, E.DF.global)
	E.private = E:CopyTable({}, E.privateVars.profile)

	if ElvUIChatDB then
		if ElvUIChatDB.global then
			E:CopyTable(E.global, ElvUIChatDB.global)
		end

		local key = ElvUIChatDB.profileKeys and ElvUIChatDB.profileKeys[E.mynameRealm]
		if key and ElvUIChatDB.profiles and ElvUIChatDB.profiles[key] then
			E:CopyTable(E.db, ElvUIChatDB.profiles[key])
		end
	end

	if ElvUIChatPrivateDB then
		local key = ElvUIChatPrivateDB.profileKeys and ElvUIChatPrivateDB.profileKeys[E.mynameRealm]
		if key and ElvUIChatPrivateDB.profiles and ElvUIChatPrivateDB.profiles[key] then
			E:CopyTable(E.private, ElvUIChatPrivateDB.profiles[key])
		end
	end

	E.ScanTooltip = CreateFrame('GameTooltip', 'ElvUI_ScanTooltip', _G.UIParent, 'GameTooltipTemplate')
	E.EasyMenu = CreateFrame('Frame', 'ElvUI_EasyMenu', _G.UIParent, 'UIDropDownMenuTemplate')

	E.PixelMode = E.twoPixelsPlease or E.private.general.pixelPerfect -- keep this over `UIScale`
	E.Border = (E.PixelMode and not E.twoPixelsPlease) and 1 or 2
	E.Spacing = E.PixelMode and 0 or 1
	E.loadedtime = GetTime()

	E:UIMult()
	E:UpdateMedia()
	E:InitializeInitialModules()
end

function E:SetEasyMenuAnchor(menu, frame)
	local point = E:GetScreenQuadrant(frame)
	local bottom = point and strfind(point, 'BOTTOM')
	local left = point and strfind(point, 'LEFT')

	local anchor1 = (bottom and left and 'BOTTOMLEFT') or (bottom and 'BOTTOMRIGHT') or (left and 'TOPLEFT') or 'TOPRIGHT'
	local anchor2 = (bottom and left and 'TOPLEFT') or (bottom and 'TOPRIGHT') or (left and 'BOTTOMLEFT') or 'BOTTOMRIGHT'

	UIDropDownMenu_SetAnchor(menu, 0, 0, anchor1, frame, anchor2)
end

function E:ResetProfile()
	E:StaggeredUpdateAll()
end

function E:OnProfileReset()
	E:StaticPopup_Show('RESET_PROFILE_PROMPT')
end

function E:ResetPrivateProfile()
	ReloadUI()
end

function E:OnPrivateProfileReset()
	E:StaticPopup_Show('RESET_PRIVATE_PROFILE_PROMPT')
end
