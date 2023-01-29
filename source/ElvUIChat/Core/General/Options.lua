local E, L, V, P, G = unpack(ElvUIChat)
local CH = E:GetModule('Chat')
local LO = E:GetModule('Layout')
local ACH = E.Libs.ACH
local C = { Blank = function() return '' end }
E.ConfigOptions = C

local _G = _G
local sort, strmatch, strsplit = sort, strmatch, strsplit
local format, gsub, ipairs, pairs = format, gsub, ipairs, pairs
local tconcat, tinsert, tremove = table.concat, tinsert, tremove

C.Values = {
	FontFlags = {
		NONE = 'None',
		OUTLINE = 'Outline',
		THICKOUTLINE = 'Thick',
		MONOCHROME = '|cffaaaaaaMono|r',
		MONOCHROMEOUTLINE = '|cffaaaaaaMono|r Outline',
		MONOCHROMETHICKOUTLINE = '|cffaaaaaaMono|r Thick',
	},
	FontSize = { min = 8, max = 64, step = 1 },
	Strata = { BACKGROUND = 'BACKGROUND', LOW = 'LOW', MEDIUM = 'MEDIUM', HIGH = 'HIGH', DIALOG = 'DIALOG', TOOLTIP = 'TOOLTIP' },
	GrowthDirection = {
		DOWN_RIGHT = format('%s and then %s', 'Down', 'Right'),
		DOWN_LEFT = format('%s and then %s', 'Down', 'Left'),
		UP_RIGHT = format('%s and then %s', 'Up', 'Right'),
		UP_LEFT = format('%s and then %s', 'Up', 'Left'),
		RIGHT_DOWN = format('%s and then %s', 'Right', 'Down'),
		RIGHT_UP = format('%s and then %s', 'Right', 'Up'),
		LEFT_DOWN = format('%s and then %s', 'Left', 'Down'),
		LEFT_UP = format('%s and then %s', 'Left', 'Up'),
	},
	AllPoints = { TOPLEFT = 'TOPLEFT', LEFT = 'LEFT', BOTTOMLEFT = 'BOTTOMLEFT', RIGHT = 'RIGHT', TOPRIGHT = 'TOPRIGHT', BOTTOMRIGHT = 'BOTTOMRIGHT', TOP = 'TOP', BOTTOM = 'BOTTOM', CENTER = 'CENTER' },
	Anchors = { TOPLEFT = 'TOPLEFT', LEFT = 'LEFT', BOTTOMLEFT = 'BOTTOMLEFT', RIGHT = 'RIGHT', TOPRIGHT = 'TOPRIGHT', BOTTOMRIGHT = 'BOTTOMRIGHT', TOP = 'TOP', BOTTOM = 'BOTTOM' },
	SmartAuraPositions = {
		DISABLED = 'Disable',
		BUFFS_ON_DEBUFFS = 'Buffs on Debuffs',
		DEBUFFS_ON_BUFFS = 'Debuffs on Buffs',
		FLUID_BUFFS_ON_DEBUFFS = 'Fluid Buffs on Debuffs',
		FLUID_DEBUFFS_ON_BUFFS = 'Fluid Debuffs on Buffs',
	},
	Roman = { 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X', 'XI', 'XII', 'XIII', 'XIV', 'XV', 'XVI', 'XVII', 'XVIII', 'XIX', 'XX' } -- 1 to 20
}

do
	C.StateSwitchGetText = function(_, TEXT)
		local friend, enemy = strmatch(TEXT, '^Friendly:([^,]*)'), strmatch(TEXT, '^Enemy:([^,]*)')
		local text, blockB, blockS, blockT = friend or enemy or TEXT
		local SF, localized = E.global.unitframe.specialFilters[text], L[text]
		if SF and localized and text:match('^block') then blockB, blockS, blockT = localized:match('^%[(.-)](%s?)(.+)') end
		local filterText = (blockB and format('|cFF999999%s|r%s%s', blockB, blockS, blockT)) or localized or text
		return (friend and format('|cFF33FF33%s|r %s', _G.FRIEND, filterText)) or (enemy and format('|cFFFF3333%s|r %s', _G.ENEMY, filterText)) or filterText
	end

	local function filterMatch(s,v)
		local m1, m2, m3, m4 = '^'..v..'$', '^'..v..',', ','..v..'$', ','..v..','
		return (strmatch(s, m1) and m1) or (strmatch(s, m2) and m2) or (strmatch(s, m3) and m3) or (strmatch(s, m4) and v..',')
	end

	C.SetFilterPriority = function(db, groupName, auraType, value, remove, movehere, friendState)
		if not auraType or not value then return end
		local filter = db[groupName] and db[groupName][auraType] and db[groupName][auraType].priority
		if not filter then return end
		local found = filterMatch(filter, E:EscapeString(value))
		if found and movehere then
			local tbl, sv, sm = {strsplit(',',filter)}
			for i in ipairs(tbl) do
				if tbl[i] == value then sv = i elseif tbl[i] == movehere then sm = i end
				if sv and sm then break end
			end
			tremove(tbl, sm)
			tinsert(tbl, sv, movehere)
			db[groupName][auraType].priority = tconcat(tbl,',')
		elseif found and friendState then
			local realValue = strmatch(value, '^Friendly:([^,]*)') or strmatch(value, '^Enemy:([^,]*)') or value
			local friend = filterMatch(filter, E:EscapeString('Friendly:'..realValue))
			local enemy = filterMatch(filter, E:EscapeString('Enemy:'..realValue))
			local default = filterMatch(filter, E:EscapeString(realValue))

			local state =
				(friend and (not enemy) and format('%s%s','Enemy:',realValue))					--[x] friend [ ] enemy: > enemy
			or	((not enemy and not friend) and format('%s%s','Friendly:',realValue))			--[ ] friend [ ] enemy: > friendly
			or	(enemy and (not friend) and default and format('%s%s','Friendly:',realValue))	--[ ] friend [x] enemy: (default exists) > friendly
			or	(enemy and (not friend) and strmatch(value, '^Enemy:') and realValue)			--[ ] friend [x] enemy: (no default) > realvalue
			or	(friend and enemy and realValue)												--[x] friend [x] enemy: > default

			if state then
				local stateFound = filterMatch(filter, E:EscapeString(state))
				if not stateFound then
					local tbl, sv = {strsplit(',',filter)}
					for i in ipairs(tbl) do
						if tbl[i] == value then
							sv = i
							break
						end
					end
					tinsert(tbl, sv, state)
					tremove(tbl, sv+1)
					db[groupName][auraType].priority = tconcat(tbl,',')
				end
			end
		elseif found and remove then
			db[groupName][auraType].priority = gsub(filter, found, '')
		elseif not found and not remove then
			db[groupName][auraType].priority = (filter == '' and value) or (filter..','..value)
		end
	end
end

-- --Function we can call on profile change to update GUI
function E:RefreshGUI()
	E.Libs.AceConfigRegistry:NotifyChange('ElvUIChat')
end

function E:LoadConfigOptions()
	E.Libs.AceConfig:RegisterOptionsTable('ElvUIChat', E.Options)
	E.Libs.AceConfigDialog:SetDefaultSize('ElvUIChat', E:Config_GetDefaultSize())
	E.Options.name = format('%s: |cff99ff33%.2f|r', 'Version', E.version)
	E:LoadConfigOptions_Core()
	E:LoadConfigOptions_Chat()
end

function E:LoadConfigOptions_Core()
	E.Options.args.info = ACH:Group('Information', nil, 4)
	E.Options.args.info.args.header = ACH:Description('|cffff8000ElvUI|r is a complete User Interface replacement addon for World of Warcraft.', 1, 'medium')
	E.Options.args.info.args.spacer = ACH:Spacer(2)

	local profileTypeItems = {
		profile = 'Profile',
		private = 'Private (Character Settings)',
		global = 'Global (Account Settings)',
	}
	local profileTypeListOrder = { 'profile', 'private', 'global' }

	--Create Profiles Table
	E.Options.args.profiles = ACH:Group('Profiles', nil, 4, 'tab')
	E.Options.args.profiles.args.desc = ACH:Description('This feature will allow you to transfer settings to other characters.', 0)
	E.Options.args.profiles.args.spacer = ACH:Spacer(6)

	E.Options.args.profiles.args.profile = E.Libs.AceDBOptions:GetOptionsTable(E.data)
	E.Options.args.profiles.args.private = E.Libs.AceDBOptions:GetOptionsTable(E.charSettings)

	E.Options.args.profiles.args.profile.name = 'Profile'
	E.Options.args.profiles.args.profile.order = 1
	E.Options.args.profiles.args.private.name = 'Private'
	E.Options.args.profiles.args.private.order = 2

	E.Libs.AceConfig:RegisterOptionsTable('ElvProfiles', E.Options.args.profiles.args.profile)

	if E.Retail or E.Wrath then
		E.Libs.DualSpec:EnhanceOptions(E.Options.args.profiles.args.profile, E.data)
	end

	E.Libs.AceConfig:RegisterOptionsTable('ElvPrivates', E.Options.args.profiles.args.private)

	E.Options.args.profiles.args.private.args.choose.confirm = function(info, value)
		if info[#info-1] == 'private' then
			return format('Choosing Settings %s. This will reload the UI.\n\n Are you sure?', value)
		else
			return false
		end
	end

	E.Options.args.profiles.args.private.args.copyfrom.confirm = function(info, value)
		return format('Copy settings from %s. This will overwrite %s profile.\n\n Are you sure?', value, info.handler:GetCurrentProfile())
	end
end

function E:LoadConfigOptions_Chat()
	local tabSelectorTable = {}
    local Chat = ACH:Group('Chat', nil, 2, 'tab', function(info) return E.db.chat[info[#info]] end, function(info, value) E.db.chat[info[#info]] = value end)
    E.Options.args.chat = Chat

    Chat.args.intro = ACH:Description('Adjust chat settings for ElvUIChat.', 1)
    Chat.args.enable = ACH:Toggle('Enable', nil, 2, nil, nil, nil, function() return E.private.chat.enable end, function(_, value) E.private.chat.enable = value E.ShowPopup = true end)

    local General = ACH:Group('General', nil, 3, nil, nil, nil, function() return not E.Chat.Initialized end)
    Chat.args.general = General

    General.args.url = ACH:Toggle('URL Links', 'Attempt to create URL links inside the chat.', 1)
    General.args.shortChannels = ACH:Toggle('Short Channels', 'Shorten the channel names in chat.', 2)
    General.args.hideChannels = ACH:Toggle('Hide Channels', 'Hide the channel names in chat.', 3)
    General.args.hyperlinkHover = ACH:Toggle('Hyperlink Hover', 'Display the hyperlink tooltip while hovering over a hyperlink.', 4, nil, nil, nil, nil, function(info, value) E.db.chat[info[#info]] = value CH:ToggleHyperlink(value) end)
    General.args.sticky = ACH:Toggle('Sticky Chat', 'When opening the Chat Editbox to type a message having this option set means it will retain the last channel you spoke in. If this option is turned off opening the Chat Editbox should always default to the SAY channel.', 5)
    General.args.emotionIcons = ACH:Toggle('Emotion Icons', 'Display emotion icons in chat.', 6)
    General.args.lfgIcons = ACH:Toggle('Role Icon', 'Display LFG Icons in group chat.', 7, nil, nil, nil, nil, function(info, value) E.db.chat.lfgIcons = value CH:CheckLFGRoles() end, nil, not E.Retail)
    General.args.useAltKey = ACH:Toggle('Use Alt Key', 'Require holding the Alt key down to move cursor or cycle through messages in the editbox.', 8, nil, nil, nil, nil, function(info, value) E.db.chat.useAltKey = value CH:UpdateSettings() end)
    General.args.autoClosePetBattleLog = ACH:Toggle('Auto-Close Pet Battle Log', nil, 9, nil, nil, nil, nil, nil, nil, not E.Retail)
    General.args.useBTagName = ACH:Toggle('Use Real ID BattleTag', 'Use BattleTag instead of Real ID names in chat. Chat History will always use BattleTag.', 10)
    General.args.socialQueueMessages = ACH:Toggle('Quick Join Messages', 'Show clickable Quick Join messages inside of the chat.', 11, nil, nil, nil, nil, nil, nil, not E.Retail)
    General.args.copyChatLines = ACH:Toggle('Copy Chat Lines', 'Adds an arrow infront of the chat lines to copy the entire line.', 12)
    General.args.hideCopyButton = ACH:Toggle('Hide Copy Button', nil, 13, nil, nil, nil, nil, function(info, value) E.db.chat.hideCopyButton = value CH:ToggleCopyChatButtons() end)
    General.args.spacer = ACH:Spacer(14, 'full')
    General.args.throttleInterval = ACH:Range('Spam Interval', 'Prevent the same messages from displaying in chat more than once within this set amount of seconds, set to zero to disable.', 20, { min = 0, max = 120, step = 1 }, nil, nil, function(info, value) E.db.chat[info[#info]] = value if value == 0 then CH:DisableChatThrottle() end end)
    General.args.scrollDownInterval = ACH:Range('Scroll Interval', 'Number of time in seconds to scroll down to the bottom of the chat window if you are not scrolled down completely.', 21, { min = 0, max = 120, step = 1 })
    General.args.numScrollMessages = ACH:Range('Scroll Messages', 'Number of messages you scroll for each step.', 22, { min = 1, max = 12, step = 1 })
    General.args.maxLines = ACH:Range('Max Lines', nil, 23, { min = 10, max = 5000, step = 1 }, nil, nil, function(info, value) E.db.chat[info[#info]] = value CH:SetupChat() end)
    General.args.editboxHistorySize = ACH:Range('Editbox History', nil, 24, { min = 5, max = 50, step = 1 })
    General.args.resetHistory = ACH:Execute('Reset Editbox History', nil, 25, function() CH:ResetEditboxHistory() end)
    General.args.editBoxPosition = ACH:Select('Chat EditBox Position', 'Position of the Chat EditBox, if datatexts are disabled this will be forced to be above chat.', 26, { BELOW_CHAT = 'Below Chat', ABOVE_CHAT = 'Above Chat', BELOW_CHAT_INSIDE = 'Below Chat (Inside)', ABOVE_CHAT_INSIDE = 'Above Chat (Inside)' }, nil, nil, nil, function(info, value) E.db.chat[info[#info]] = value CH:UpdateEditboxAnchors() end)

    General.args.tabSelection = ACH:Group('Tab Selector', nil, 30, nil, nil, function(info, value) E.db.chat[info[#info]] = value CH:UpdateChatTabColors() end)
    General.args.tabSelection.args.tabSelectedTextEnabled = ACH:Toggle('Colorize Selected Text', nil, 1)
    General.args.tabSelection.args.tabSelectedTextColor = ACH:Color('Selected Text Color', nil, 2, nil, nil, function(info) local t, d = E.db.chat[info[#info]], P.chat[info[#info]] return t.r, t.g, t.b, t.a, d.r, d.g, d.b end, function(info, r, g, b) local t = E.db.chat[info[#info]] t.r, t.g, t.b = r, g, b CH:UpdateChatTabColors() end, function() return not E.db.chat.tabSelectedTextEnabled end)
    General.args.tabSelection.args.tabSelector = ACH:Select('Selector Style', nil, 3, function() wipe(tabSelectorTable) tabSelectorTable['NONE'] = 'None' for key, value in pairs(CH.TabStyles) do if key ~= 'NONE' then local color = CH.db.tabSelectorColor local hexColor = E:RGBToHex(color.r, color.g, color.b) local selectedColor = E.media.hexvaluecolor if CH.db.tabSelectedTextEnabled then color = E.db.chat.tabSelectedTextColor selectedColor = E:RGBToHex(color.r, color.g, color.b) end tabSelectorTable[key] = format(value, hexColor, format('%sName|r', selectedColor), hexColor) end end return tabSelectorTable end)
    General.args.tabSelection.args.tabSelectorColor = ACH:Color('Selector Color', nil, 4, nil, nil, function(info) local t, d = E.db.chat[info[#info]], P.chat[info[#info]] return t.r, t.g, t.b, t.a, d.r, d.g, d.b end, function(info, r, g, b) local t = E.db.chat[info[#info]] t.r, t.g, t.b = r, g, b E:UpdateMedia() end, function() return E.db.chat.tabSelector == 'NONE' end)

    General.args.historyGroup = ACH:Group('History', nil, 65)
    General.args.historyGroup.args.chatHistory = ACH:Toggle('Enable', 'Log the main chat frames history. So when you reloadui or log in and out you see the history from your last session.', 1)
    General.args.historyGroup.args.resetHistory = ACH:Execute('Reset History', nil, 2, function() CH:ResetHistory() end)
    General.args.historyGroup.args.historySize = ACH:Range('History Size', nil, 3, { min = 10, max = 500, step = 1 }, nil, nil, nil, function() return not E.db.chat.chatHistory end)
    General.args.historyGroup.args.showHistory = ACH:MultiSelect('Display Types', nil, 4, { WHISPER = 'Whisper', GUILD = 'Guild', PARTY = 'Party', RAID = 'Raid', INSTANCE = 'Instance', CHANNEL = 'Channel', SAY = 'Say', YELL = 'Yell', EMOTE = 'Emote' }, nil, nil, function(info, key) return E.db.chat[info[#info]][key] end, function(info, key, value) E.db.chat[info[#info]][key] = value end, function() return not E.db.chat.chatHistory end)

    General.args.combatRepeat = ACH:Group('Combat Repeat', nil, 70)
    General.args.combatRepeat.args.enableCombatRepeat = ACH:Toggle('Enable', nil, 1)
    General.args.combatRepeat.args.numAllowedCombatRepeat = ACH:Range('Number Allowed', 'Number of repeat characters while in combat before the chat editbox is automatically closed.', 2, { min = 2, max = 10, step = 1 })

    General.args.fadingGroup = ACH:Group('Text Fade', nil, 75, nil, nil, function(info, value) E.db.chat[info[#info]] = value CH:UpdateFading() end, function() return not E.Chat.Initialized end)
    General.args.fadingGroup.args.fade = ACH:Toggle('Enable', 'Fade the chat text when there is no activity.', 1)
    General.args.fadingGroup.args.inactivityTimer = ACH:Range('Inactivity Timer', 'Controls how many seconds of inactivity has to pass before chat is faded.', 2, { min = 5, softMax = 120, step = 1 }, nil, nil, nil, function() return not CH.db.fade end)

    General.args.fontGroup = ACH:Group('Fonts', nil, 80, nil, nil, function(info, value) E.db.chat[info[#info]] = value CH:SetupChat() end, function() return not E.Chat.Initialized end)
    General.args.fontGroup.args.font = ACH:SharedMediaFont('Font', nil, 1)
    General.args.fontGroup.args.fontOutline = ACH:FontFlags('Font Outline', nil, 2)
    General.args.fontGroup.args.tabFont = ACH:SharedMediaFont('Tab Font', nil, 3)
    General.args.fontGroup.args.tabFontOutline = ACH:FontFlags('Tab Font Outline', nil, 5)
    General.args.fontGroup.args.tabFontSize = ACH:Range('Tab Font Size', nil, 3, C.Values.FontSize)

    General.args.alerts = ACH:Group('Alerts', nil, 85, nil, nil, nil, function() return not E.Chat.Initialized end)
    General.args.alerts.args.noAlertInCombat = ACH:Toggle('No Alert In Combat', nil, 1)
    General.args.alerts.args.flashClientIcon = ACH:Toggle('Flash Client Icon', nil, 2)

    General.args.alerts.args.keywordAlerts = ACH:Group('Keyword Alerts', nil, 5)
    General.args.alerts.args.keywordAlerts.inline = true
    General.args.alerts.args.keywordAlerts.args.keywordSound = ACH:SharedMediaSound('Keyword Alert', nil, 1, 'double')
    General.args.alerts.args.keywordAlerts.args.keywords = ACH:Input('Keywords', 'List of words to color in chat if found in a message. If you wish to add multiple words you must separate the word with a comma. To search for your current name you can use %MYNAME%.\n\nExample:\n%MYNAME%, ElvUIChat, RBGs, Tank', 2, 4, 'double', nil, function(info, value) E.db.chat[info[#info]] = value CH:UpdateChatKeywords() end)

    General.args.alerts.args.channelAlerts = ACH:Group('Channel Alerts', nil, 10, nil, function(info) return E.db.chat.channelAlerts[info[#info]] end, function(info, value) E.db.chat.channelAlerts[info[#info]] = value end)
    General.args.alerts.args.channelAlerts.inline = true
    General.args.alerts.args.channelAlerts.args.GUILD = ACH:SharedMediaSound('Guild', nil, nil, 'double')
    General.args.alerts.args.channelAlerts.args.OFFICER = ACH:SharedMediaSound('Officer', nil, nil, 'double')
    General.args.alerts.args.channelAlerts.args.INSTANCE = ACH:SharedMediaSound('Instance', nil, nil, 'double')
    General.args.alerts.args.channelAlerts.args.PARTY = ACH:SharedMediaSound('Party', nil, nil, 'double')
    General.args.alerts.args.channelAlerts.args.RAID = ACH:SharedMediaSound('Raid', nil, nil, 'double')
    General.args.alerts.args.channelAlerts.args.WHISPER = ACH:SharedMediaSound('Whisper', nil, nil, 'double')

    General.args.voicechatGroup = ACH:Group('Voice Chat', nil, 90)
    General.args.voicechatGroup.args.hideVoiceButtons = ACH:Toggle('Hide Voice Buttons', 'Completely hide the voice buttons.', 1, nil, nil, nil, nil, function(info, value) E.db.chat[info[#info]] = value E.ShowPopup = true end)
    General.args.voicechatGroup.args.pinVoiceButtons = ACH:Toggle('Pin Voice Buttons', 'This will pin the voice buttons to the chat\'s tab panel. Unchecking it will create a voice button panel with a mover.', 2, nil, nil, nil, nil, function(info, value) E.db.chat[info[#info]] = value E.ShowPopup = true end, function() return E.db.chat.hideVoiceButtons end)
    General.args.voicechatGroup.args.desaturateVoiceIcons = ACH:Toggle('Desaturate Voice Icons', nil, 3, nil, nil, nil, nil, function(info, value) E.db.chat[info[#info]] = value CH:UpdateVoiceChatIcons() end, function() return E.db.chat.hideVoiceButtons end)
    General.args.voicechatGroup.args.mouseoverVoicePanel = ACH:Toggle('Mouseover', nil, 4, nil, nil, nil, nil, function(info, value) E.db.chat[info[#info]] = value CH:ResetVoicePanelAlpha() end, function() return E.db.chat.hideVoiceButtons or E.db.chat.pinVoiceButtons end)
    General.args.voicechatGroup.args.voicePanelAlpha = ACH:Range('Alpha', 'Change the alpha level of the frame.', 5, { min = 0, max = 1, step = 0.01 }, nil, nil, function(info, value) E.db.chat[info[#info]] = value CH:ResetVoicePanelAlpha() end, function() return E.db.chat.hideVoiceButtons or E.db.chat.pinVoiceButtons or not E.db.chat.mouseoverVoicePanel end)

    General.args.timestampGroup = ACH:Group('Chat Timestamps', nil, 95)
    General.args.timestampGroup.args.timeStampLocalTime = ACH:Toggle('Local Time', 'If not set to true then the server time will be displayed instead.', 1)
    General.args.timestampGroup.args.timeStampFormat = ACH:Select('Chat Timestamps', 'Select the format of timestamps for chat messages.', 2, { ['NONE'] = 'None', ['%I:%M '] = '03:27', ['%I:%M:%S '] = '03:27:32', ['%I:%M %p '] = '03:27 PM', ['%I:%M:%S %p '] = '03:27:32 PM', ['%H:%M '] = '15:27', ['%H:%M:%S '] = '15:27:32' })
    General.args.timestampGroup.args.useCustomTimeColor = ACH:Toggle('Custom Timestamp Color', nil, 3, nil, nil, nil, nil, nil, nil, function() return E.db.chat.timeStampFormat == 'NONE' end)
    General.args.timestampGroup.args.customTimeColor = ACH:Color('', nil, 4, nil, nil, function(info) local t, d = E.db.chat[info[#info]], P.chat[info[#info]] return t.r, t.g, t.b, t.a, d.r, d.g, d.b end, function(info, r, g, b) local t = E.db.chat[info[#info]] t.r, t.g, t.b = r, g, b end, nil, function() return (E.db.chat.timeStampFormat == 'NONE' or not E.db.chat.useCustomTimeColor) end)

    General.args.classColorMentionGroup = ACH:Group('Class Color Mentions', nil, 100, nil, nil, nil, function() return not E.Chat.Initialized end)
    General.args.classColorMentionGroup.args.classColorMentionsChat = ACH:Toggle('Chat', 'Use class color for the names of players when they are mentioned.', 1, nil, nil, nil, function(info) return E.db.chat[info[#info]] end, function(info, value) E.db.chat[info[#info]] = value end, function() return E.private.general.chatBubbles == 'disabled' end)
    General.args.classColorMentionGroup.args.classColorMentionsSpeech = ACH:Toggle('Chat Bubbles', 'Use class color for the names of players when they are mentioned.', 2, nil, nil, nil, function(info) return E.private.general[info[#info]] end, function(info, value) E.private.general[info[#info]] = value E.ShowPopup = true end)
    General.args.classColorMentionGroup.args.classColorMentionExcludeName = ACH:Input('Exclude Name', 'Excluded names will not be class colored.', 3, nil, nil, C.Blank, function(_, value) if value == '' or gsub(value, '%s+', '') == '' then return end E.global.chat.classColorMentionExcludedNames[strlower(value)] = value end)
    General.args.classColorMentionGroup.args.classColorMentionExcludedNames = ACH:MultiSelect('Excluded Names', nil, 4, function(info) return E.global.chat[info[#info]] end, nil, nil, C.Blank, function(info, value) E.global.chat[info[#info]][value] = nil GameTooltip_Hide() end)

    local Panels = ACH:Group('Panels', nil, 85)
    Chat.args.panels = Panels

    Panels.args.fadeUndockedTabs = ACH:Toggle('Fade Undocked Tabs', 'Fades the text on chat tabs that are not docked at the left or right chat panel.', 1, nil, nil, nil, nil, function(info, value) E.db.chat[info[#info]] = value CH:UpdateChatTabs() end, nil, function() return not E.Chat.Initialized end)
    Panels.args.fadeTabsNoBackdrop = ACH:Toggle('Fade Tabs No Backdrop', 'Fades the text on chat tabs that are docked in a panel where the backdrop is disabled.', 2, nil, nil, nil, nil, function(info, value) E.db.chat[info[#info]] = value CH:UpdateChatTabs() end, nil, function() return not E.Chat.Initialized end)
    Panels.args.hideChatToggles = ACH:Toggle('Hide Chat Toggles', nil, 3, nil, nil, nil, nil, function(info, value) E.db.chat[info[#info]] = value CH:RefreshToggleButtons() LO:RepositionChatDataPanels() end)
    Panels.args.fadeChatToggles = ACH:Toggle('Fade Chat Toggles', 'Fades the buttons that toggle chat windows when that window has been toggled off.', 4, nil, nil, nil, nil, function(info, value) E.db.chat[info[#info]]= value CH:RefreshToggleButtons() end, function() return E.db.chat.hideChatToggles end)

    Panels.args.tabGroup = ACH:Group('Tab Panels', nil, 10, nil, nil, nil, nil, function() return not E.Chat.Initialized end)
    Panels.args.tabGroup.inline = true
    Panels.args.tabGroup.args.panelTabTransparency = ACH:Toggle('Tab Panel Transparency', nil, 1, nil, nil, 250, nil, function(info, value) E.db.chat[info[#info]] = value LO:SetChatTabStyle() end, function() return not E.db.chat.panelTabBackdrop end)
    Panels.args.tabGroup.args.panelTabBackdrop = ACH:Toggle('Tab Panel', 'Toggle the chat tab panel backdrop.', 2, nil, nil, nil, nil, function(info, value) E.db.chat[info[#info]] = value LO:ToggleChatPanels() if E.db.chat.pinVoiceButtons and not E.db.chat.hideVoiceButtons then CH:ReparentVoiceChatIcon() end end)

    Panels.args.panels = ACH:Group('Chat Panels', nil, 7)
    Panels.args.panels.inline = true
    Panels.args.panels.args.panelColor = ACH:Color('Backdrop Color', nil, 1, true, nil, function(info) local t, d = E.db.chat[info[#info]], P.chat[info[#info]] return t.r, t.g, t.b, t.a, d.r, d.g, d.b, d.a end, function(info, r, g, b, a) local t = E.db.chat[info[#info]] t.r, t.g, t.b, t.a = r, g, b, a CH:Panels_ColorUpdate() end)
    Panels.args.panels.args.panelHeight = ACH:Range(function() return E.db.chat.separateSizes and 'Left Panel Height' or 'Panel Height' end, function() return E.db.chat.separateSizes and 'Adjust the height of your left chat panel.' or nil end, 3, { min = 60, max = 1000, step = 1 }, nil, nil, function(info, value) E.db.chat[info[#info]] = value CH:PositionChats() end)
    Panels.args.panels.args.panelWidth = ACH:Range(function() return E.db.chat.separateSizes and 'Left Panel Width' or 'Panel Width' end, function() return E.db.chat.separateSizes and 'Adjust the width of your left chat panel.' or nil end, 4, { min = 50, max = 2000, step = 1 }, nil, nil, function(info, value) E.db.chat[info[#info]] = value CH:PositionChats() end)
    Panels.args.panels.args.panelSnapping = ACH:Toggle('Panel Snapping', 'When disabled, the Chat Background color has to be set via Blizzards Chat Tabs Background setting.', 6, nil, nil, nil, nil, function(info, value) E.db.chat[info[#info]] = value CH:PositionChats() end, nil, function() return not E.Chat.Initialized end)
end