local E, L, V, P, G = unpack(ElvUIChat)
local LO = E:GetModule('Layout')

local _G = _G

local BAR_HEIGHT = 22
local TOGGLE_WIDTH = 18

function LO:Initialize()
	LO.Initialized = true
end

function LO:ToggleChatTabPanels(rightOverride, leftOverride)
	if not _G.LeftChatTab then return end

	if leftOverride or not E.db.chat.panelTabBackdrop then
		_G.LeftChatTab:Hide()
	else
		_G.LeftChatTab:Show()
	end
end

local barHeight = BAR_HEIGHT + 1
local toggleWidth = TOGGLE_WIDTH + 1
function LO:RefreshChatMovers()
	local LeftChatPanel = _G.LeftChatPanel
	local LeftChatMover = _G.LeftChatMover
	-- TODO: movers stripped in chat-only build; decide if we reintroduce a mover stub
	if not (LeftChatPanel and LeftChatMover) then return end
	local Left = LeftChatPanel:GetPoint()
	local showLeftPanel = E.db.datatexts.panels.LeftChatDataPanel.enable
	
	if not showLeftPanel or E.db.chat.LeftChatDataPanelAnchor == 'ABOVE_CHAT' then
		LeftChatPanel:Point(Left, LeftChatMover, 0, 0)
	elseif showLeftPanel then
		LeftChatPanel:Point(Left, LeftChatMover, 0, barHeight)
	end

	-- mover sizes: same as in CH.PositionChats for panels but including the datatext bar height
	local panelWidth, panelHeight = E:Scale(E.db.chat.panelWidth), E:Scale(E.db.chat.panelHeight)
	LeftChatMover:SetSize(panelWidth, panelHeight + (showLeftPanel and barHeight or 0))
end

function LO:RepositionChatDataPanels()
	if not (_G.LeftChatTab and _G.LeftChatPanel and _G.LeftChatDataPanel and _G.LeftChatToggleButton) then return end

	local LeftChatTab = _G.LeftChatTab
	local LeftChatPanel = _G.LeftChatPanel
	local LeftChatDataPanel = _G.LeftChatDataPanel
	local LeftChatToggleButton = _G.LeftChatToggleButton

	if E.private.chat.enable then
		LeftChatTab:ClearAllPoints()
		LeftChatTab:Point('TOPLEFT', LeftChatPanel, 'TOPLEFT', 2, -2)
		LeftChatTab:Point('BOTTOMRIGHT', LeftChatPanel, 'TOPRIGHT', -2, -BAR_HEIGHT-2)
	end

	LeftChatDataPanel:ClearAllPoints()

	local SPACING = E.PixelMode and 1 or -1
	local sideButton = E.db.chat.hideChatToggles and 0 or toggleWidth
	if E.db.chat.LeftChatDataPanelAnchor == 'ABOVE_CHAT' then
		LeftChatDataPanel:Point('BOTTOMRIGHT', LeftChatPanel, 'TOPRIGHT', 0, -SPACING)
		LeftChatDataPanel:Point('TOPLEFT', LeftChatPanel, 'TOPLEFT', sideButton, barHeight)
		LeftChatToggleButton:Point('BOTTOMRIGHT', LeftChatDataPanel, 'BOTTOMLEFT', SPACING, 0)
		LeftChatToggleButton:Point('TOPLEFT', LeftChatDataPanel, 'TOPLEFT', -toggleWidth, 0)
	else
		LeftChatDataPanel:Point('TOPRIGHT', LeftChatPanel, 'BOTTOMRIGHT', 0, SPACING)
		LeftChatDataPanel:Point('BOTTOMLEFT', LeftChatPanel, 'BOTTOMLEFT', sideButton, -barHeight)
		LeftChatToggleButton:Point('TOPRIGHT', LeftChatDataPanel, 'TOPLEFT', SPACING, 0)
		LeftChatToggleButton:Point('BOTTOMLEFT', LeftChatDataPanel, 'BOTTOMLEFT', -toggleWidth, 0)
	end

	LO:RefreshChatMovers()
end

function LO:SetChatTabStyle()
	if not _G.LeftChatTab then return end

	local tabStyle = (E.db.chat.panelTabTransparency and 'Transparent') or nil
	local glossTex = (not tabStyle and true) or nil

	_G.LeftChatTab:SetTemplate(tabStyle, glossTex)
end

function LO:ToggleChatPanels()
	if not (_G.LeftChatPanel and _G.LeftChatDataPanel and _G.LeftChatToggleButton) then return end

	local showLeftPanel = E.db.datatexts.panels.LeftChatDataPanel.enable
	_G.LeftChatDataPanel:SetShown(showLeftPanel)

	local showToggles = not E.db.chat.hideChatToggles
	_G.LeftChatToggleButton:SetShown(showToggles and showLeftPanel)

	LO:RefreshChatMovers()

	local panelBackdrop = E.db.chat.panelBackdrop
	if panelBackdrop == 'SHOWBOTH' then
		_G.LeftChatPanel.backdrop:Show()
		LO:ToggleChatTabPanels()
	elseif panelBackdrop == 'HIDEBOTH' then
		_G.LeftChatPanel.backdrop:Hide()
		LO:ToggleChatTabPanels(true, true)
	elseif panelBackdrop == 'LEFT' then
		_G.LeftChatPanel.backdrop:Show()
		LO:ToggleChatTabPanels(true)
	else
		LO:ToggleChatTabPanels(nil, true)
	end
end

E:RegisterModule(LO:GetName())
