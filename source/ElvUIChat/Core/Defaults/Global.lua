local E, L, V, P, G = unpack(ElvUIChat)

--Global Settings
G.general = {
	UIScale = 0.64,
	locale = E:GetLocale(),
	eyefinity = false,
	ultrawide = false,
	smallerWorldMap = true,
	allowDistributor = false,
	smallerWorldMapScale = 0.9,
	fadeMapWhenMoving = true,
	mapAlphaWhenMoving = 0.2,
	fadeMapDuration = 0.2,
	WorldMapCoordinates = {
		enable = true,
		position = 'BOTTOMLEFT',
		xOffset = 0,
		yOffset = 0
	},
	AceGUI = {
		width = 1024,
		height = 768
	},
	disableTutorialButtons = true,
	commandBarSetting = 'ENABLED_RESIZEPARENT'
}

G.classtimer = {}

G.chat = {
	classColorMentionExcludedNames = {}
}

G.bags = {
	ignoredItems = {}
}

G.datatexts = {
	customPanels = {},
	customCurrencies = {},
	settings = {
		Agility = { Label = '', NoLabel = false },
		Armor = { Label = '', NoLabel = false },
		Avoidance = { Label = '', NoLabel = false, decimalLength = 1 },
		Bags = { textFormat = 'USED_TOTAL', Label = '', NoLabel = false },
		CallToArms = { Label = '', NoLabel = false },
		Combat = { TimeFull = true, NoLabel = false },
		CombatIndicator = { OutOfCombat = '', InCombat = '', OutOfCombatColor = {r = 0, g = 0.8, b = 0}, InCombatColor = {r = 0.8, g = 0, b = 0} },
		Crit = { Label = '', NoLabel = false, decimalLength = 1 },
		Currencies = { goldFormat = 'BLIZZARD', goldCoins = true, displayedCurrency = 'BACKPACK', displayStyle = 'ICON', tooltipData = {}, idEnable = {}, headers = true, maxCurrency = false },
		Durability = { Label = '', NoLabel = false, percThreshold = 30 },
		DualSpecialization = { NoLabel = false },
		ElvUIChat = { Label = '' },
		Experience = { textFormat = 'CUR' },
		Friends = {
			Label = '', NoLabel = false,
			--status
			hideAFK = false,
			hideDND = false,
			--clients
			hideWoW = false,
			hideD3 = false,
			hideVIPR = false,
			hideWTCG = false, --Hearthstone
			hideHero = false, --Heros of the Storm
			hidePro = false, --Overwatch
			hideS1 = false,
			hideS2 = false,
			hideBSAp = false, --Mobile
			hideApp = false, --Launcher
		},
		Gold = { goldFormat = 'BLIZZARD', goldCoins = true },
		Guild = { Label = '', NoLabel = false },
		Haste = { Label = '', NoLabel = false, decimalLength = 1 },
		Hit = { Label = '', NoLabel = false, decimalLength = 1 },
		Intellect = { Label = '', NoLabel = false},
		['Item Level'] = { rarityColor = true },
		Location = { showZone = true, showSubZone = true, showContinent = false, color = 'REACTION', customColor = {r = 1, g = 1, b = 1} },
		Mastery = { Label = '', NoLabel = false, decimalLength = 1 },
		MovementSpeed = { Label = '', NoLabel = false, decimalLength = 1 },
		QuickJoin = { Label = '', NoLabel = false },
		Reputation = { textFormat = 'CUR' },
		['Talent/Loot Specialization'] = { displayStyle = 'BOTH', iconOnly = false },
		SpellPower = { school = 0 },
		Speed = { Label = '', NoLabel = false, decimalLength = 1 },
		Stamina = { Label = '', NoLabel = false },
		Strength = { Label = '', NoLabel = false },
		System = { NoLabel = false, ShowOthers = true, latency = 'WORLD' },
		Time = { time24 = _G.GetCurrentRegion() ~= 1, localTime = true, flashInvite = true },
		Versatility = { Label = '', NoLabel = false, decimalLength = 1 },
	},
	newPanelInfo = {
		growth = 'HORIZONTAL',
		width = 300,
		height = 22,
		frameStrata = 'LOW',
		numPoints = 3,
		frameLevel = 1,
		backdrop = true,
		panelTransparency = false,
		mouseover = false,
		border = true,
		textJustify = 'CENTER',
		visibility = '[petbattle] hide;show',
		tooltipAnchor = 'ANCHOR_TOPLEFT',
		tooltipXOffset = -17,
		tooltipYOffset = 4,
		fonts = {
			enable = false,
			font = 'PT Sans Narrow',
			fontSize = 12,
			fontOutline = 'OUTLINE',
		}
	},
}

G.nameplates = {}

G.unitframe = {
	aurafilters = {},
	aurawatch = {},
	raidDebuffIndicator = {
		instanceFilter = 'RaidDebuffs',
		otherFilter = 'CCDebuffs'
	},
	newCustomText = {
		text_format = '',
		size = 10,
		font = 'Homespun',
		fontOutline = 'MONOCHROMEOUTLINE',
		xOffset = 0,
		yOffset = 0,
		justifyH = 'CENTER',
		attachTextTo = 'Health'
	}
}

G.profileCopy = {
	--Specific values
	selected = 'Default',
	movers = {},
	--Modules
	actionbar = {
		general = false,
		bar1 = false,
		bar2 = false,
		bar3 = false,
		bar4 = false,
		bar5 = false,
		bar6 = false,
		barPet = false,
		stanceBar = false,
		microbar = false,
		extraActionButton = false,
		cooldown = false
	},
	auras = {
		general = false,
		buffs = false,
		debuffs = false,
		cooldown = false
	},
	bags = {
		general = false,
		split = false,
		vendorGrays = false,
		bagBar = false,
		cooldown = false
	},
	chat = {
		general = true
	},
	cooldown = {
		general = false,
		fonts = false
	},
	databars = {
		experience = false,
		reputation = false,
		honor = false,
		azerite = false
	},
	datatexts = {
		general = false,
		panels = false
	},
	general = {
		general = false,
		minimap = false,
		threat = false,
		totems = false,
		itemLevel = false,
		altPowerBar = false
	},
	nameplates = {
		general = false,
		cooldown = false,
		threat = false,
		units = {
			PLAYER = false,
			TARGET = false,
			FRIENDLY_PLAYER = false,
			ENEMY_PLAYER = false,
			FRIENDLY_NPC = false,
			ENEMY_NPC = false
		}
	},
	tooltip = {
		general = false,
		visibility = false,
		healthBar = false
	},
	unitframe = {
		general = false,
		cooldown = false,
		colors = {
			general = false,
			power = false,
			reaction = false,
			healPrediction = false,
			classResources = false,
			frameGlow = false,
			debuffHighlight = false
		},
		units = {
			player = false,
			target = false,
			targettarget = false,
			targettargettarget = false,
			focus = false,
			focustarget = false,
			pet = false,
			pettarget = false,
			boss = false,
			arena = false,
			party = false,
			raid1 = false,
			raid2 = false,
			raid3 = false,
			raidpet = false,
			tank = false,
			assist = false
		}
	}
}
