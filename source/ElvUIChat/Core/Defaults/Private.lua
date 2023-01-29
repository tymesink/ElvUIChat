------------------------------------------------------------------------------------------------------
-- Locked Settings, These settings are stored for your character only regardless of profile options.
------------------------------------------------------------------------------------------------------
local E, L, V, P, G = unpack(ElvUIChat)

V.general = {
	loot = false,
	lootRoll = false,
	normTex = 'ElvUIChat Norm',
	glossTex = 'ElvUIChat Norm',
	dmgfont = 'Expressway',
	namefont = 'Expressway', -- (PT Sans) some dont render for mail room quest
	chatBubbles = 'backdrop',
	chatBubbleFont = 'PT Sans Narrow',
	chatBubbleFontSize = 12,
	chatBubbleFontOutline = 'NONE',
	chatBubbleName = false,
	nameplateFont = 'PT Sans Narrow',
	nameplateFontSize = 9,
	nameplateFontOutline = 'OUTLINE',
	nameplateLargeFont = 'PT Sans Narrow',
	nameplateLargeFontSize = 11,
	nameplateLargeFontOutline = 'OUTLINE',
	pixelPerfect = false,
	replaceNameFont = false,
	replaceCombatFont = false,
	replaceCombatText = false,
	replaceBubbleFont = false,
	replaceNameplateFont = false,
	replaceBlizzFonts = false,
	unifiedBlizzFonts = false,
	totemTracker = false,
	minimap = {
		enable = false,
		hideClassHallReport = false,
		hideCalendar = false,
		hideTracking = false,
	},
	classColorMentionsSpeech = false,
	raidUtility = false,
	voiceOverlay = false,
	worldMap = false,
}

V.bags = {
	enable = false,
	bagBar = false,
}

V.nameplates = {
	enable = false,
}

V.auras = {
	enable = false,
	disableBlizzard = false,
	buffsHeader = false,
	debuffsHeader = false,
	masque = {
		buffs = false,
		debuffs = false,
	}
}

V.chat = {
	enable = true,
}

V.skins = {
	ace3Enable = true,
	checkBoxSkin = true,
	parchmentRemoverEnable = false,
	blizzard = {
		enable = true,

		achievement = true,
		addonManager = true,
		adventureMap = true,
		alertframes = true,
		alliedRaces = true,
		animaDiversion = true,
		archaeology = true,
		arena = true,
		arenaRegistrar = true,
		artifact = true,
		auctionhouse = true,
		azerite = true,
		azeriteEssence = true,
		azeriteRespec = true,
		bags = true,
		barber = true,
		battlefield = true,
		bgmap = true,
		bgscore = true,
		binding = true,
		blizzardOptions = true,
		bmah = true, --black market
		calendar = true,
		channels = true,
		character = true,
		chromieTime = true,
		collections = true,
		communities = true,
		contribution = true,
		covenantPreview = true,
		covenantRenown = true,
		covenantSanctum = true,
		craft = true,
		deathRecap = true,
		debug = true,
		dressingroom = true,
		encounterjournal = true,
		eventLog = true,
		friends = true,
		garrison = true,
		gbank = true,
		gmChat = true,
		gossip = true,
		greeting = true,
		guide = true,
		guild = true,
		guildBank = true,
		guildcontrol = true,
		guildregistrar = true,
		help = true,
		inspect = true,
		islandQueue = true,
		islandsPartyPose = true,
		itemInteraction = true,
		itemUpgrade = true,
		lfg = true,
		lfguild = true,
		loot = true,
		losscontrol = true,
		macro = true,
		mail = true,
		merchant = true,
		mirrorTimers = true,
		misc = true,
		nonraid = true,
		objectiveTracker = true,
		obliterum = true,
		orderhall = true,
		perks = true,
		petbattleui = true,
		petition = true,
		playerChoice = true,
		pvp = true,
		quest = true,
		questChoice = true,
		raid = true,
		reforge = true,
		runeforge = true,
		scrapping = true,
		socket = true,
		soulbinds = true,
		spellbook = true,
		stable = true,
		subscriptionInterstitial = true,
		tabard = true,
		talent = true,
		talkinghead = true,
		taxi = true,
		timemanager = true,
		tooltip = true,
		torghastLevelPicker = true,
		trade = true,
		tradeskill = true,
		trainer = true,
		transmogrify = true,
		tutorials = true,
		voidstorage = true,
		weeklyRewards = true,
		worldmap = true,
		expansionLanding = true,
		majorFactions = true,
		genericTrait = true,
		editor = true,
	}
}

V.tooltip = {
	enable = false,
}

V.unitframe = {
	enable = false,
	disabledBlizzardFrames = {
		castbar = false,
		player = false,
		target = false,
		focus = false,
		boss = false,
		arena = false,
		party = false,
		raid = false,
	}
}

V.actionbar = {
	enable = false,
	hideCooldownBling = false,
	masque = {
		actionbars = false,
		petBar = false,
		stanceBar = false,
	}
}
