local E, L, V, P, G = unpack(ElvUIChat)

--Global Settings
G.general = {
	UIScale = 0.64,
	locale = E:GetLocale(),
	eyefinity = false,
	ultrawide = false,
	AceGUI = {
		width = 1024,
		height = 768
	},
}

G.chat = {
	classColorMentionExcludedNames = {}
}

G.datatexts = {
	customCurrencies = {},
	settings = {
		ElvUIChat = { Label = '' },
	},
}

G.profileCopy = {
	--Specific values
	selected = 'Default',
	movers = {},
	--Modules
	chat = {
		general = true
	},
	datatexts = {
		general = false,
		panels = false
	},
	general = {
		general = false,
	}
}
