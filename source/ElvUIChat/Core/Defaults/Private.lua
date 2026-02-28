------------------------------------------------------------------------------------------------------
-- Locked Settings, These settings are stored for your character only regardless of profile options.
------------------------------------------------------------------------------------------------------
local E, L, V, P, G = unpack(ElvUIChat)

V.general = {
	normTex = 'ElvUIChat Norm',
	glossTex = 'ElvUIChat Norm',
	voiceOverlay = false,
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
		blizzardOptions = true, -- ChatConfig.lua (chat settings UI)
		tooltip = true,         -- Ace3.lua (tooltips)
	}
}
