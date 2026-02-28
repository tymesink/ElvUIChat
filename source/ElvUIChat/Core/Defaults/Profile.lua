local E, L, V, P, G = unpack(ElvUIChat)

local CopyTable = CopyTable -- Our function doesn't exist yet.
local next = next

P.hideTutorial = true
P.dbConverted = nil -- use this to let DBConversions run once per profile

--Core
P.general = {
	messageRedirect = _G.DEFAULT_CHAT_FRAME:GetName(),
	smoothingAmount = 0.33,
	taintLog = false,
	stickyFrames = false,
	loginmessage = true,
	questXPPercent = false,
	numberPrefixStyle = 'ENGLISH',
	decimalLength = 1,
	fontSize = 12,
	font = 'PT Sans Narrow',
	fontStyle = 'OUTLINE',
	bordercolor = { r = 0, g = 0, b = 0 }, -- updated in E.Initialize
	backdropcolor = { r = 0.1, g = 0.1, b = 0.1 },
	backdropfadecolor = { r = .06, g = .06, b = .06, a = 0.8 },
	valuecolor = { r = 0.09, g = 0.52, b = 0.82 },
	cropIcon = 2
}

--Chat
P.chat = {
	url = true,
	panelSnapLeftID = nil, -- set by the snap code
	panelSnapping = true,
	shortChannels = true,
	hyperlinkHover = true,
	throttleInterval = 45,
	scrollDownInterval = 15,
	fade = true,
	inactivityTimer = 100,
	font = 'PT Sans Narrow',
	fontOutline = 'NONE',
	fontSize = 10,
	sticky = true,
	emotionIcons = true,
	keywordSound = 'None',
	noAlertInCombat = false,
	flashClientIcon = true,
	chatHistory = true,
	lfgIcons = true,
	maxLines = 100,
	channelAlerts = {
		GUILD = 'None',
		OFFICER = 'None',
		INSTANCE = 'None',
		PARTY = 'None',
		RAID = 'None',
		WHISPER = 'Whisper Alert',
	},
	showHistory = {
		WHISPER = true,
		GUILD = true,
		PARTY = true,
		RAID = true,
		INSTANCE = true,
		CHANNEL = true,
		SAY = true,
		YELL = true,
		EMOTE = true
	},
	historySize = 100,
	editboxHistorySize = 20,
	tabSelector = 'BOX',
	tabSelectedTextEnabled = true,
	tabSelectedTextColor = { r = 1, g = 1, b = 1 },
	tabSelectorColor = { r = .3, g = 1, b = .3 },
	timeStampFormat = 'NONE',
	timeStampLocalTime = false,
	keywords = 'ElvUIChat',
	panelWidth = 412,
	panelHeight = 180,
	panelBackdropNameLeft = '',
	panelBackdrop = 'LEFT',
	panelTabBackdrop = false,
	panelTabTransparency = false,
	editBoxPosition = 'BELOW_CHAT',
	fadeUndockedTabs = false,
	fadeTabsNoBackdrop = true,
	fadeChatToggles = true,
	hideChatToggles = false,
	hideCopyButton = false,
	useAltKey = false,
	classColorMentionsChat = true,
	enableCombatRepeat = true,
	numAllowedCombatRepeat = 5,
	useCustomTimeColor = true,
	customTimeColor = {r = 0.7, g = 0.7, b = 0.7},
	numScrollMessages = 3,
	autoClosePetBattleLog = true,
	socialQueueMessages = false,
	tabFont = 'PT Sans Narrow',
	tabFontSize = 12,
	tabFontOutline = 'NONE',
	copyChatLines = false,
	useBTagName = false,
	panelColor = {r = .06, g = .06, b = .06, a = 0.8},
	pinVoiceButtons = true,
	hideVoiceButtons = false,
	desaturateVoiceIcons = true,
	mouseoverVoicePanel = false,
	voicePanelAlpha = 0.25
}

