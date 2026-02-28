--[[
	~AddOn Engine~
	To load the AddOn engine inside another addon add this to the top of your file:
		local E, L, V, P, G = unpack(ElvUIChat) --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
]]

local _G = _G
local strsplit, next, strfind, strmatch = strsplit, next, strfind, strmatch
local gsub, tinsert, type, wipe = gsub, tinsert, type, wipe
local tonumber, tostring = tonumber, tostring
local GetBuildInfo = GetBuildInfo
local GetLocale = GetLocale
local GetTime = GetTime
local CreateFrame = CreateFrame
local ReloadUI = ReloadUI
local UIParent = UIParent
local WorldFrame = WorldFrame
local UnitGUID = UnitGUID
local UIDropDownMenu_SetAnchor = UIDropDownMenu_SetAnchor

local GetAddOnMetadata = C_AddOns.GetAddOnMetadata
local C_AddOns_GetAddOnEnableState = C_AddOns.GetAddOnEnableState

local GetCVar = C_CVar.GetCVar
local SetCVar = C_CVar.SetCVar

-- GLOBALS: ElvUIChatCharacterDB, ElvUIChatPrivateDB, ElvUIChatDB

local AceAddon, AceAddonMinor = _G.LibStub('AceAddon-3.0')
local CallbackHandler = _G.LibStub('CallbackHandler-1.0')

local AddOnName, Engine = ...
local E = AceAddon:NewAddon(AddOnName, 'AceConsole-3.0', 'AceEvent-3.0', 'AceTimer-3.0', 'AceHook-3.0')
E.DF = {profile = {}, global = {}}; E.privateVars = {profile = {}} -- Defaults
E.Options = {type = 'group', args = {}, childGroups = 'tab'}
E.callbacks = E.callbacks or CallbackHandler:New(E)
E.wowpatch, E.wowbuild, E.wowdate, E.wowtoc = GetBuildInfo()
E.locale = GetLocale()

Engine[1] = E
Engine[2] = {}
Engine[3] = E.privateVars.profile
Engine[4] = E.DF.profile
Engine[5] = E.DF.global
_G.ElvUIChat = Engine

E.Chat = E:NewModule('Chat','AceTimer-3.0','AceHook-3.0','AceEvent-3.0')
E.Layout = E:NewModule('Layout','AceEvent-3.0')
E.Skins = E:NewModule('Skins','AceTimer-3.0','AceHook-3.0','AceEvent-3.0')

E.InfoColor = '|cff1784d1' -- blue
E.InfoColor2 = '|cff9b9b9b' -- silver
E.twoPixelsPlease = false -- changing this option is not supported! :P

do -- Retail Only (ElvUIChat)
	E.Retail = true
	E.Classic = false
	E.TBC = false
	E.Wrath = false
	E.Cata = false
	E.Mists = false
end

-- ElvUIChat: Initialize tables early so General files can use them
E.RegisteredModules = {}
E.RegisteredInitialModules = {}
E.TexCoords = {0, 1, 0, 1}
E.valueColorUpdateFuncs = setmetatable({}, {
	__newindex = function(_, key, value)
		if type(key) == 'function' then return end
		rawset(E.valueColorUpdateFuncs, key, value)
	end
})

-- ElvUIChat: Removed mover tables - movers not needed for chat-only addon

-- DONT USE: Deprecated
E.QualityColors = CopyTable(_G.BAG_ITEM_QUALITY_COLORS)
E.QualityColors[Enum.ItemQuality.Poor] = { r = .61, g = .61, b = .61, a = 1 }
E.QualityColors[Enum.ItemQuality.Common or Enum.ItemQuality.Standard] = { r = 0, g = 0, b = 0, a = 1 }
E.QualityColors[-1] = { r = 0, g = 0, b = 0, a = 1 }

do
	function E:AddonCompartmentFunc()
		E:ToggleOptions()
	end

	_G.ElvUIChat_AddonCompartmentFunc = E.AddonCompartmentFunc
end

do -- this is different from E.locale because we need to convert for ace locale files
	local convert = { enGB = 'enUS' }
	local gameLocale = convert[E.locale] or E.locale or 'enUS'

	function E:GetLocale()
		return gameLocale
	end
end

function E:ParseVersionString(addon)
	local version = GetAddOnMetadata(addon, 'Version')
	if strfind(version, 'project%-version') then
		return 15.03, '15.03-git', nil, true
	else
		local release, extra = strmatch(version, '^v?([%d.]+)(.*)')
		return tonumber(release), release..extra, extra ~= ''
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
	E:AddLib('Deflate', 'LibDeflate')
	
	-- libraries used for options
	E:AddLib('AceGUI', 'AceGUI-3.0')
	E:AddLib('AceConfig', 'AceConfig-3.0-ElvUIChat')
	E:AddLib('AceConfigDialog', 'AceConfigDialog-3.0-ElvUIChat')
	E:AddLib('AceConfigRegistry', 'AceConfigRegistry-3.0-ElvUIChat')
	E:AddLib('AceDBOptions', 'AceDBOptions-3.0')

	-- backwards compatible
	E.LSM = E.Libs.LSM
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

function E:SetCVar(cvar, value)
	local valstr = ((type(value) == 'boolean') and (value and '1' or '0')) or tostring(value)
	if GetCVar(cvar) ~= valstr then
		SetCVar(cvar, valstr)
	end
end

function E:GetAddOnEnableState(addon, character)
	return C_AddOns_GetAddOnEnableState(addon, character)
end

function E:IsAddOnEnabled(addon)
	return E:GetAddOnEnableState(addon, E.myguid) == 2
end

-- ElvUIChat: Add early helper functions so files can use them at load time
do
	local a1, a2 = '', '[%s%-]'
	function E:ShortenRealm(realm)
		if not realm then return '' end
		return gsub(realm, a2, a1)
	end
end

-- Provide minimal helpers used across modules
function E:GetMouseFocus()
	return _G.GetMouseFocus and _G.GetMouseFocus() or nil
end

function E:IsSecretValue(value)
	return false, value
end

function E:NotSecretValue(value)
	return value
end

function E:UpdateCustomClassColors()
	-- TODO: implement class color updates if needed in chat-only build
end

function E:Tutorials()
	-- TODO: tutorial flow is disabled in chat-only build
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
			-- Call loaded module logic would go here if needed
		else
			E.RegisteredModules[#E.RegisteredModules + 1] = { name = name, func = func }
		end
	end
end

function E:UpdateMedia()
	-- Placeholder - real implementation is in Core.lua
end

function E:InitializeInitialModules()
	-- Placeholder - real implementation is in Core.lua  
end

-- ElvUIChat: Add CopyTable early so OnInitialize can use it
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

	E.ScanTooltip = CreateFrame('GameTooltip', 'ElvUIChat_ScanTooltip', WorldFrame, 'GameTooltipTemplate')
	E.EasyMenu = CreateFrame('Frame', 'ElvUIChat_EasyMenu', UIParent, 'UIDropDownMenuTemplate')

	E.PixelMode = E.twoPixelsPlease or E.private.general.pixelPerfect -- keep this over `UIScale`
	E.Border = (E.PixelMode and not E.twoPixelsPlease) and 1 or 2
	E.Spacing = E.PixelMode and 0 or 1

	E.myClassColor = E:ClassColor(E.myclass, true)
	E.loadedtime = GetTime()

	local playerGUID = UnitGUID('player')
	local _, serverID = strsplit('-', playerGUID)
	E.serverID = tonumber(serverID)
	E.myguid = playerGUID

	-- ElvUIChat: These are called from E:Initialize() in Core.lua instead
	-- E:UIMult()
	-- E:UpdateMedia()
	-- E:InitializeInitialModules()
end

function E:SetEasyMenuAnchor(menu, frame)
	local point = E:GetScreenQuadrant(frame)
	local bottom = point and strfind(point, 'BOTTOM')
	local left = point and strfind(point, 'LEFT')

	local anchor1 = (bottom and left and 'BOTTOMLEFT') or (bottom and 'BOTTOMRIGHT') or (left and 'TOPLEFT') or 'TOPRIGHT'
	local anchor2 = (bottom and left and 'TOPLEFT') or (bottom and 'TOPRIGHT') or (left and 'BOTTOMLEFT') or 'BOTTOMRIGHT'

	UIDropDownMenu_SetAnchor(menu, 1, -1, anchor1, frame, anchor2)
end

function E:ResetProfile()
	E:StaggeredUpdateAll()
end

function E:OnProfileReset()
	E:ResetProfile()
end

function E:ResetPrivateProfile()
	ReloadUI()
end

function E:OnPrivateProfileReset()
	E:ResetPrivateProfile()
end
