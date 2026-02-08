local E, L, V, P, G = unpack(ElvUIChat)
-- Modules we don't have - make them nil-safe

local CH = E:GetModule('Chat')
local S = E:GetModule('Skins')

local _G = _G
local next = next
local unpack = unpack
local format = format
local strsub = strsub
local tinsert = tinsert

local ReloadUI = ReloadUI
local PlaySound = PlaySound
local CreateFrame = CreateFrame
local UIFrameFadeOut = UIFrameFadeOut
local ChangeChatColor = ChangeChatColor
local FCF_DockFrame = FCF_DockFrame
local FCF_SetWindowName = FCF_SetWindowName
local FCF_StopDragging = FCF_StopDragging
local FCF_UnDockFrame = FCF_UnDockFrame
local FCF_OpenNewWindow = FCF_OpenNewWindow
local FCF_ResetChatWindow = FCF_ResetChatWindow
local FCF_ResetChatWindows = FCF_ResetChatWindows
local FCF_SetChatWindowFontSize = FCF_SetChatWindowFontSize
local FCF_SavePositionAndDimensions = FCF_SavePositionAndDimensions
local SetChatColorNameByClass = SetChatColorNameByClass

local VoiceTranscriptionFrame_UpdateEditBox = VoiceTranscriptionFrame_UpdateEditBox
local VoiceTranscriptionFrame_UpdateVisibility = VoiceTranscriptionFrame_UpdateVisibility
local VoiceTranscriptionFrame_UpdateVoiceTab = VoiceTranscriptionFrame_UpdateVoiceTab

local CLASS, CONTINUE, PREVIOUS = CLASS, CONTINUE, PREVIOUS
local VOICE, LOOT, GENERAL, TRADE = VOICE, LOOT, GENERAL, TRADE
local GUILD_EVENT_LOG = GUILD_EVENT_LOG

-- GLOBALS: ElvUIInstallFrame

local CURRENT_PAGE = 0
local MAX_PAGE = 9

local PLAYER_NAME = format('%s-%s', E.myname, E:ShortenRealm(E.myrealm))
local ELV_TOONS = {
	['Elv-Spirestone']			= true,
	['Elvz-Spirestone']			= true,
	['Fleshlite-Spirestone']	= true,
	['Elvidan-Spirestone']		= true,
	['Elvilas-Spirestone']		= true,
	['Fraku-Spirestone']		= true,
	['Jarvix-Spirestone']		= true,
	['Watermelon-Spirestone']	= true,
	['Zinxbe-Spirestone']		= true,
	['Whorlock-Spirestone']		= true,
}

local function ToggleChatColorNamesByClassGroup(checked, group)
	local info = _G.ChatTypeGroup[group]
	if info then
		for _, value in next, info do
			SetChatColorNameByClass(strsub(value, 10), checked)
		end
	else
		SetChatColorNameByClass(group, checked)
	end
end

function E:SetupChat(noDisplayMsg)
	local chats = _G.CHAT_FRAMES
	FCF_ResetChatWindows()

	-- force initialize the tts chat (it doesn't get shown unless you use it)
	local voiceChat = _G[chats[3]]
	FCF_ResetChatWindow(voiceChat, VOICE)
	FCF_DockFrame(voiceChat, 3)

	local rightChat = FCF_OpenNewWindow(LOOT)
	FCF_UnDockFrame(rightChat)

	for id, name in next, chats do
		local frame = _G[name]

		if E.private.chat.enable then
			CH:FCFTab_UpdateColors(CH:GetTab(frame))
		end

		if id == 1 then
			frame:ClearAllPoints()
			frame:Point('BOTTOMLEFT', _G.LeftChatToggleButton, 'TOPLEFT', 1, 3)
		elseif id == 2 then
			FCF_SetWindowName(frame, GUILD_EVENT_LOG)
		elseif id == 3 then
			VoiceTranscriptionFrame_UpdateVisibility(frame)
			VoiceTranscriptionFrame_UpdateVoiceTab(frame)
			VoiceTranscriptionFrame_UpdateEditBox(frame)
		elseif id == 4 then
			frame:ClearAllPoints()
			frame:Point('BOTTOMLEFT', _G.RightChatDataPanel, 'TOPLEFT', 1, 3)
			FCF_SetWindowName(frame, LOOT..' / '..TRADE)
		end

		FCF_SetChatWindowFontSize(nil, frame, 12)
		FCF_SavePositionAndDimensions(frame)
		FCF_StopDragging(frame)
	end

	-- keys taken from `ChatTypeGroup` but doesnt add: 'OPENING', 'TRADESKILLS', 'PET_INFO', 'COMBAT_MISC_INFO', 'COMMUNITIES_CHANNEL', 'PET_BATTLE_COMBAT_LOG', 'PET_BATTLE_INFO', 'TARGETICONS'
	local chatGroup = { 'SYSTEM', 'CHANNEL', 'SAY', 'EMOTE', 'YELL', 'WHISPER', 'PARTY', 'PARTY_LEADER', 'RAID', 'RAID_LEADER', 'RAID_WARNING', 'INSTANCE_CHAT', 'INSTANCE_CHAT_LEADER', 'GUILD', 'OFFICER', 'MONSTER_SAY', 'MONSTER_YELL', 'MONSTER_EMOTE', 'MONSTER_WHISPER', 'MONSTER_BOSS_EMOTE', 'MONSTER_BOSS_WHISPER', 'ERRORS', 'AFK', 'DND', 'IGNORED', 'BG_HORDE', 'BG_ALLIANCE', 'BG_NEUTRAL', 'ACHIEVEMENT', 'GUILD_ACHIEVEMENT', 'BN_WHISPER', 'BN_INLINE_TOAST_ALERT' }
	local ChatFrame1_RemoveAllMessageGroups = _G.ChatFrame1.RemoveAllMessageGroups or _G.ChatFrame_RemoveAllMessageGroups
	local ChatFrame1_AddMessageGroup = _G.ChatFrame1.AddMessageGroup or _G.ChatFrame_AddMessageGroup

	ChatFrame1_RemoveAllMessageGroups(_G.ChatFrame1)
	for _, v in next, chatGroup do
		ChatFrame1_AddMessageGroup(_G.ChatFrame1, v)
	end

	-- keys taken from `ChatTypeGroup` which weren't added above to ChatFrame1 but keeping CHANNEL
	chatGroup = { 'PING', 'CHANNEL', 'COMBAT_XP_GAIN', 'COMBAT_HONOR_GAIN', 'COMBAT_FACTION_CHANGE', 'SKILL', 'LOOT', 'CURRENCY', 'MONEY' }
	local RightChat_RemoveAllMessageGroups = rightChat.RemoveAllMessageGroups or _G.ChatFrame_RemoveAllMessageGroups
	local RightChat_AddMessageGroup = rightChat.AddMessageGroup or _G.ChatFrame_AddMessageGroup

	RightChat_RemoveAllMessageGroups(rightChat)
	for _, v in next, chatGroup do
		RightChat_AddMessageGroup(rightChat, v)
	end

	local ChatFrame1_AddChannel = _G.ChatFrame1.AddChannel or _G.ChatFrame_AddChannel
	local ChatFrame1_RemoveChannel = _G.ChatFrame1.RemoveChannel or _G.ChatFrame_RemoveChannel
	local RightChat_AddChannel = rightChat.AddChannel or _G.ChatFrame_AddChannel

	ChatFrame1_AddChannel(_G.ChatFrame1, GENERAL)
	ChatFrame1_RemoveChannel(_G.ChatFrame1, TRADE)
	RightChat_AddChannel(rightChat, TRADE)

	-- set the chat groups names in class color to enabled for all chat groups which players names appear
	chatGroup = { 'SAY', 'EMOTE', 'YELL', 'WHISPER', 'PARTY', 'PARTY_LEADER', 'RAID', 'RAID_LEADER', 'RAID_WARNING', 'INSTANCE_CHAT', 'INSTANCE_CHAT_LEADER', 'GUILD', 'OFFICER', 'ACHIEVEMENT', 'GUILD_ACHIEVEMENT', 'COMMUNITIES_CHANNEL' }
	for i = 1, _G.MAX_WOW_CHAT_CHANNELS do
		tinsert(chatGroup, 'CHANNEL'..i)
	end
	for _, v in next, chatGroup do
		ToggleChatColorNamesByClassGroup(true, v)
	end

	-- Adjust Chat Colors
	ChangeChatColor('CHANNEL1', 0.76, 0.90, 0.91) -- General
	ChangeChatColor('CHANNEL2', 0.91, 0.62, 0.47) -- Trade
	ChangeChatColor('CHANNEL3', 0.91, 0.89, 0.47) -- Local Defense

	if E.private.chat.enable then
		CH:PositionChats()
	end

	-- TODO: right toggle may not exist without a right panel; remove guard if right side returns
	if E.db.RightChatPanelFaded and _G.RightChatToggleButton then
		_G.RightChatToggleButton:Click()
	end

	if E.db.LeftChatPanelFaded then
		_G.LeftChatToggleButton:Click()
	end

	if ELV_TOONS[PLAYER_NAME] then
		E:SetCVar('scriptErrors', 1)
	end

	if _G.InstallStepComplete and not noDisplayMsg then
		_G.InstallStepComplete.message = L["Chat Set"]
		_G.InstallStepComplete:Show()
	end
end

function E:SetupCVars(noDisplayMsg)
	E:SetCVar('statusTextDisplay', 'BOTH')
	E:SetCVar('showTutorials', 0)
	E:SetCVar('fstack_preferParentKeys', 0) -- Add back the frame names via fstack!


	if E.private.chat.enable then
		E:SetCVar('chatMouseScroll', 1)
		E:SetCVar('chatStyle', 'classic')
		E:SetCVar('whisperMode', 'inline')
		E:SetCVar('wholeChatWindowClickable', 0)
	end

	if _G.InstallStepComplete and not noDisplayMsg then
		_G.InstallStepComplete.message = L["CVars Set"]
		_G.InstallStepComplete:Show()
	end
end

function E:LayoutNormal()
	--Chat
	E.db.chat.fontSize = 10
	E.db.chat.separateSizes = false
	E.db.chat.panelHeight = 236
	E.db.chat.panelWidth = 472
	E.db.chat.tabFontSize = 12
	E.db.chat.copyChatLines = true
end

function E:SetupLayout(layout, noDataReset, noDisplayMsg)
	if not noDataReset then
		E.data:ResetProfile(nil, true) -- noChildren, noCallbacks
		E.db.layoutSet = layout
		E:LayoutNormal()
	end

	E:StaggeredUpdateAll()

	if _G.InstallStepComplete and not noDisplayMsg then
		_G.InstallStepComplete.message = L["Layout Set"]
		_G.InstallStepComplete:Show()
	end
end



function E:SetupComplete(reload)
	E.private.install_complete = E.version

	if reload then
		ReloadUI()
	end
end

function E:SetupReset()
	_G.InstallNextButton:Disable()
	_G.InstallPrevButton:Disable()
	_G.InstallOption1Button:Hide()
	_G.InstallOption1Button:SetScript('OnClick', nil)
	_G.InstallOption1Button:SetText('')
	_G.InstallOption2Button:Hide()
	_G.InstallOption2Button:SetScript('OnClick', nil)
	_G.InstallOption2Button:SetText('')
	_G.InstallOption3Button:Hide()
	_G.InstallOption3Button:SetScript('OnClick', nil)
	_G.InstallOption3Button:SetText('')
	_G.InstallOption4Button:Hide()
	_G.InstallOption4Button:SetScript('OnClick', nil)
	_G.InstallOption4Button:SetText('')
	_G.InstallSlider:Hide()
	_G.InstallSlider.Min:SetText('')
	_G.InstallSlider.Max:SetText('')
	_G.InstallSlider.Cur:SetText('')
	_G.InstallSlider:SetScript('OnValueChanged', nil)
	_G.InstallSlider:SetScript('OnMouseUp', nil)

	E.InstallFrame.SubTitle:SetText('')
	E.InstallFrame.Desc1:SetText('')
	E.InstallFrame.Desc2:SetText('')
	E.InstallFrame.Desc3:SetText('')
	E.InstallFrame:Size(550, 400)
end

function E:SetPage(num)
	CURRENT_PAGE = num

	E:SetupReset()

	_G.InstallStatus.anim.progress:SetChange(num)
	_G.InstallStatus.anim.progress:Play()
	_G.InstallStatus.text:SetText(CURRENT_PAGE..' / '..MAX_PAGE)

	_G.InstallNextButton:SetEnabled(CURRENT_PAGE ~= MAX_PAGE)
	_G.InstallPrevButton:SetEnabled(num ~= 1)

	local f = E.InstallFrame
	local InstallOption1Button = _G.InstallOption1Button
	local InstallOption2Button = _G.InstallOption2Button
	local InstallOption3Button = _G.InstallOption3Button
	local InstallOption4Button = _G.InstallOption4Button
	local InstallSlider = _G.InstallSlider

	local r, g, b = E:ColorGradient(CURRENT_PAGE / MAX_PAGE, 1, 0, 0, 1, 1, 0, 0, 1, 0)
	f.Status:SetStatusBarColor(r, g, b)

	f.Desc1:FontTemplate(nil, 16)
	f.Desc2:FontTemplate(nil, 16)
	f.Desc3:FontTemplate(nil, 16)

	if num == 1 then
		f.SubTitle:SetFormattedText(L["Welcome to ElvUI version %s!"], E.versionString)
		f.Desc1:SetText(L["This install process will help you learn some of the features in ElvUI has to offer and also prepare your user interface for usage."])
		f.Desc2:SetText(L["The in-game configuration menu can be accessed by typing the /ec command. Press the button below if you wish to skip the installation process."])
		f.Desc3:SetText(L["Please press the continue button to go onto the next step."])
	elseif num == 2 then
		f.SubTitle:SetText(L["CVars"])
		f.Desc1:SetText(L["This part of the installation process sets up your World of Warcraft default options it is recommended you should do this step for everything to behave properly."])
		f.Desc2:SetText(L["Please click the button below to setup your CVars."])
		f.Desc3:SetText(L["Importance: |cffFF3333High|r"])
		f.Desc3:FontTemplate(nil, 18)

		InstallOption1Button:Show()
		InstallOption1Button:SetScript('OnClick', function() E:SetupCVars() end)
		InstallOption1Button:SetText(L["Setup CVars"])
	elseif num == 3 then
		f.SubTitle:SetText(L["Chat"])
		f.Desc1:SetText(L["This part of the installation process sets up your chat windows names, positions and colors."])
		f.Desc2:SetText(L["The chat windows function the same as Blizzard standard chat windows, you can right click the tabs and drag them around, rename, etc. Please click the button below to setup your chat windows."])
		f.Desc3:SetText(L["Importance: |cffD3CF00Medium|r"])
		f.Desc2:FontTemplate(nil, 14)
		f.Desc3:FontTemplate(nil, 18)

		InstallOption1Button:Show()
		InstallOption1Button:SetScript('OnClick', function() E:SetupChat() end)
		InstallOption1Button:SetText(L["Setup Chat"])
	elseif num == 4 then
		f.SubTitle:SetText(L["Profile Settings Setup"])
		f.Desc1:SetText(L["Please click the button below to setup your Profile Settings."])
		f.Desc2:SetText(L["New Profile will create a fresh profile for this character."] .. '\n' .. L["Shared Profile will select the default profile."])

		InstallOption1Button:SetText(L["Shared Profile"])
		InstallOption1Button:Show()
		InstallOption1Button:SetScript('OnClick', function()
			E.data:SetProfile('Default')
			E:NextPage()
		end)

		InstallOption2Button:SetText(L["New Profile"])
		InstallOption2Button:Show()
		InstallOption2Button:SetScript('OnClick', function()
			E.data:SetProfile(E.mynameRealm)
			E:NextPage()
		end)
	elseif num == 5 then
		
	elseif num == 6 then
	
	elseif num == 7 then

	elseif num == 8 then

	elseif num == 9 then
		f.SubTitle:SetText(L["Installation Complete"])
		f.Desc1:SetText(L["You are now finished with the installation process. If you are in need of technical support please join our Discord."])
		f.Desc2:SetText(L["Please click the button below so you can setup variables and ReloadUI."])

		InstallOption2Button:Show()
		
		InstallOption2Button:SetScript('OnClick', function() E:SetupComplete(true) end)
		InstallOption2Button:SetText(L["Finished"])
		E:SetupLayout('foo')
		E.InstallFrame:Size(550, 350)
	end
end

function E:NextPage()
	if CURRENT_PAGE ~= MAX_PAGE then
		CURRENT_PAGE = CURRENT_PAGE + 1

		E:SetPage(CURRENT_PAGE)
	end
end

function E:PreviousPage()
	if CURRENT_PAGE ~= 1 then
		CURRENT_PAGE = CURRENT_PAGE - 1

		E:SetPage(CURRENT_PAGE)
	end
end

--Install UI
function E:Install()
	if not _G.InstallStepComplete then
		local imsg = CreateFrame('Frame', 'InstallStepComplete', E.UIParent)
		imsg:Size(418, 72)
		imsg:Point('TOP', 0, -190)
		imsg:Hide()
		imsg:SetScript('OnShow', function(f)
			if f.message then
				PlaySound(888)
				f.text:SetText(f.message)
				UIFrameFadeOut(f, 3.5, 1, 0)
				E:Delay(4, f.Hide, f)
				f.message = nil
			else
				f:Hide()
			end
		end)

		imsg.firstShow = false

		imsg.bg = imsg:CreateTexture(nil, 'BACKGROUND')
		imsg.bg:SetTexture([[Interface\LevelUp\LevelUpTex]])
		imsg.bg:Point('BOTTOM')
		imsg.bg:Size(326, 103)
		imsg.bg:SetTexCoord(0.00195313, 0.63867188, 0.03710938, 0.23828125)
		imsg.bg:SetVertexColor(1, 1, 1, 0.6)

		imsg.lineTop = imsg:CreateTexture(nil, 'BACKGROUND')
		imsg.lineTop:SetDrawLayer('BACKGROUND', 2)
		imsg.lineTop:SetTexture([[Interface\LevelUp\LevelUpTex]])
		imsg.lineTop:Point('TOP')
		imsg.lineTop:Size(418, 7)
		imsg.lineTop:SetTexCoord(0.00195313, 0.81835938, 0.01953125, 0.03320313)

		imsg.lineBottom = imsg:CreateTexture(nil, 'BACKGROUND')
		imsg.lineBottom:SetDrawLayer('BACKGROUND', 2)
		imsg.lineBottom:SetTexture([[Interface\LevelUp\LevelUpTex]])
		imsg.lineBottom:Point('BOTTOM')
		imsg.lineBottom:Size(418, 7)
		imsg.lineBottom:SetTexCoord(0.00195313, 0.81835938, 0.01953125, 0.03320313)

		imsg.text = imsg:CreateFontString(nil, 'ARTWORK', 'GameFont_Gigantic')
		imsg.text:Point('BOTTOM', 0, 12)
		imsg.text:SetTextColor(1, 0.82, 0)
		imsg.text:SetJustifyH('CENTER')
	end

	--Create Frame
	if not E.InstallFrame then
		local f = CreateFrame('Button', 'ElvUIInstallFrame', E.UIParent)
		f.SetPage = E.SetPage

		f:Size(550, 400)
		f:SetTemplate('Transparent')
		f:Point('CENTER')
		f:SetFrameStrata('TOOLTIP')

		f:SetMovable(true)
		f:EnableMouse(true)
		f:RegisterForDrag('LeftButton')
		f:SetScript('OnDragStart', function(frame) frame:StartMoving() frame:SetUserPlaced(false) end)
		f:SetScript('OnDragStop', function(frame) frame:StopMovingOrSizing() end)

		f.Title = f:CreateFontString(nil, 'OVERLAY')
		f.Title:FontTemplate(nil, 20)
		f.Title:Point('TOP', 0, -5)
		f.Title:SetText(L["ElvUI Installation"])

		f.Next = CreateFrame('Button', 'InstallNextButton', f, 'UIPanelButtonTemplate')
		f.Next:Size(110, 25)
		f.Next:Point('BOTTOMRIGHT', -5, 5)
		f.Next:SetText(CONTINUE)
		f.Next:Disable()
		f.Next:SetScript('OnClick', E.NextPage)
		S:HandleButton(f.Next, true)

		f.Prev = CreateFrame('Button', 'InstallPrevButton', f, 'UIPanelButtonTemplate')
		f.Prev:Size(110, 25)
		f.Prev:Point('BOTTOMLEFT', 5, 5)
		f.Prev:SetText(PREVIOUS)
		f.Prev:Disable()
		f.Prev:SetScript('OnClick', E.PreviousPage)
		S:HandleButton(f.Prev, true)

		f.Status = CreateFrame('StatusBar', 'InstallStatus', f)
		f.Status:OffsetFrameLevel(2)
		f.Status:CreateBackdrop()
		f.Status:SetStatusBarTexture(E.media.normTex)
		E:RegisterStatusBar(f.Status)
		f.Status:SetStatusBarColor(1, 0, 0)
		f.Status:SetMinMaxValues(0, MAX_PAGE)
		f.Status:Point('TOPLEFT', f.Prev, 'TOPRIGHT', 6, -2)
		f.Status:Point('BOTTOMRIGHT', f.Next, 'BOTTOMLEFT', -6, 2)

		-- Setup StatusBar Animation
		f.Status.anim = _G.CreateAnimationGroup(f.Status)
		f.Status.anim.progress = f.Status.anim:CreateAnimation('Progress')
		f.Status.anim.progress:SetEasing('Out')
		f.Status.anim.progress:SetDuration(0.3)

		f.Status.text = f.Status:CreateFontString(nil, 'OVERLAY')
		f.Status.text:FontTemplate(nil, 14, 'OUTLINE')
		f.Status.text:Point('CENTER')
		f.Status.text:SetText(CURRENT_PAGE..' / '..MAX_PAGE)

		f.Slider = CreateFrame('Slider', 'InstallSlider', f)
		f.Slider:SetOrientation('HORIZONTAL')
		f.Slider:Height(15)
		f.Slider:Width(400)
		f.Slider:SetHitRectInsets(0, 0, -10, 0)
		f.Slider:Point('CENTER', 0, 45)
		S:HandleSliderFrame(f.Slider)
		f.Slider:Hide()

		f.Slider.Min = f.Slider:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightSmall')
		f.Slider.Min:Point('RIGHT', f.Slider, 'LEFT', -3, 0)
		f.Slider.Max = f.Slider:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightSmall')
		f.Slider.Max:Point('LEFT', f.Slider, 'RIGHT', 3, 0)
		f.Slider.Cur = f.Slider:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightSmall')
		f.Slider.Cur:Point('BOTTOM', f.Slider, 'TOP', 0, 10)
		f.Slider.Cur:FontTemplate(nil, 22)

		f.Option1 = CreateFrame('Button', 'InstallOption1Button', f, 'UIPanelButtonTemplate')
		f.Option1:Size(160, 30)
		f.Option1:Point('BOTTOM', 0, 45)
		f.Option1:SetText('')
		f.Option1:Hide()
		S:HandleButton(f.Option1, true)

		f.Option2 = CreateFrame('Button', 'InstallOption2Button', f, 'UIPanelButtonTemplate')
		f.Option2:Size(110, 30)
		f.Option2:Point('BOTTOMLEFT', f, 'BOTTOM', 4, 45)
		f.Option2:SetText('')
		f.Option2:Hide()
		f.Option2:SetScript('OnShow', function() f.Option1:Width(110); f.Option1:ClearAllPoints(); f.Option1:Point('BOTTOMRIGHT', f, 'BOTTOM', -4, 45) end)
		f.Option2:SetScript('OnHide', function() f.Option1:Width(160); f.Option1:ClearAllPoints(); f.Option1:Point('BOTTOM', 0, 45) end)
		S:HandleButton(f.Option2, true)

		f.Option3 = CreateFrame('Button', 'InstallOption3Button', f, 'UIPanelButtonTemplate')
		f.Option3:Size(100, 30)
		f.Option3:Point('LEFT', f.Option2, 'RIGHT', 4, 0)
		f.Option3:SetText('')
		f.Option3:Hide()
		f.Option3:SetScript('OnShow', function() f.Option1:Width(100); f.Option1:ClearAllPoints(); f.Option1:Point('RIGHT', f.Option2, 'LEFT', -4, 0); f.Option2:Width(100); f.Option2:ClearAllPoints(); f.Option2:Point('BOTTOM', f, 'BOTTOM', 0, 45) end)
		f.Option3:SetScript('OnHide', function() f.Option1:Width(160); f.Option1:ClearAllPoints(); f.Option1:Point('BOTTOM', 0, 45); f.Option2:Width(110); f.Option2:ClearAllPoints(); f.Option2:Point('BOTTOMLEFT', f, 'BOTTOM', 4, 45) end)
		S:HandleButton(f.Option3, true)

		f.Option4 = CreateFrame('Button', 'InstallOption4Button', f, 'UIPanelButtonTemplate')
		f.Option4:Size(100, 30)
		f.Option4:Point('LEFT', f.Option3, 'RIGHT', 4, 0)
		f.Option4:SetText('')
		f.Option4:Hide()
		f.Option4:SetScript('OnShow', function()
			f.Option1:Width(100)
			f.Option2:Width(100)
			f.Option1:ClearAllPoints()
			f.Option1:Point('RIGHT', f.Option2, 'LEFT', -4, 0)
			f.Option2:ClearAllPoints()
			f.Option2:Point('BOTTOMRIGHT', f, 'BOTTOM', -4, 45)
		end)
		f.Option4:SetScript('OnHide', function() f.Option1:Width(160); f.Option1:ClearAllPoints(); f.Option1:Point('BOTTOM', 0, 45); f.Option2:Width(110); f.Option2:ClearAllPoints(); f.Option2:Point('BOTTOMLEFT', f, 'BOTTOM', 4, 45) end)
		S:HandleButton(f.Option4, true)

		f.SubTitle = f:CreateFontString(nil, 'OVERLAY')
		f.SubTitle:FontTemplate(nil, 20)
		f.SubTitle:Point('TOP', 0, -40)
		f.SubTitle:SetTextColor(unpack(E.media.rgbvaluecolor))

		f.Desc1 = f:CreateFontString(nil, 'OVERLAY')
		f.Desc1:FontTemplate(nil, 16)
		f.Desc1:Point('TOPLEFT', 20, -75)
		f.Desc1:Width(f:GetWidth() - 40)

		f.Desc2 = f:CreateFontString(nil, 'OVERLAY')
		f.Desc2:FontTemplate(nil, 16)
		f.Desc2:Point('TOPLEFT', 20, -125)
		f.Desc2:Width(f:GetWidth() - 40)

		f.Desc3 = f:CreateFontString(nil, 'OVERLAY')
		f.Desc3:FontTemplate(nil, 16)
		f.Desc3:Point('TOPLEFT', 20, -175)
		f.Desc3:Width(f:GetWidth() - 40)

		local close = CreateFrame('Button', 'InstallCloseButton', f, 'UIPanelCloseButton')
		close:Point('TOPRIGHT', f, 'TOPRIGHT')
		close:SetScript('OnClick', function()
			E:SetupComplete()
			f:Hide()
		end)
		S:HandleCloseButton(close)

		local logo = f:CreateTexture('InstallTutorialImage', 'OVERLAY')
		logo:Size(256, 128)
		logo:SetTexture(E.Media.Textures.LogoTop)
		logo:Point('BOTTOM', 0, 70)
		f.tutorialImage = logo

		local logo2 = f:CreateTexture('InstallTutorialImage2', 'OVERLAY')
		logo2:Size(256, 128)
		logo2:SetTexture(E.Media.Textures.LogoBottom)
		logo2:Point('BOTTOM', 0, 70)
		f.tutorialImage2 = logo2

		E.InstallFrame = f
	end

	E.InstallFrame.tutorialImage:SetVertexColor(unpack(E.media.rgbvaluecolor))
	E.InstallFrame:Show()
	E:NextPage()
end
