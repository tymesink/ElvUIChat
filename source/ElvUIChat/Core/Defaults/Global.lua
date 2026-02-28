local E, L, V, P, G = unpack(ElvUIChat)

--Global Settings
G.general = {
	locale = E:GetLocale(),
	ignoreIncompatible = false,
	AceGUI = {
		width = 1024,
		height = 768
	},
}

G.chat = {
	classColorMentionExcludedNames = {}
}

