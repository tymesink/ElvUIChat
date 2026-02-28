local E, L, V, P, G = unpack(ElvUIChat)
local S = E:GetModule('Skins')
local LibStub = _G.LibStub

local _G = _G
local tinsert, xpcall, next, ipairs, pairs = tinsert, xpcall, next, ipairs, pairs
local unpack, assert, type, strfind = unpack, assert, type, strfind

local CreateFrame = CreateFrame
local hooksecurefunc = hooksecurefunc
local IsAddOnLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or _G.IsAddOnLoaded

S.allowBypass = {}
S.addonsToLoad = {}
S.nonAddonsToLoad = {}

S.Blizzard = {}
S.Blizzard.Regions = {
	'Left',
	'Middle',
	'Right',
	'Mid',
	'LeftDisabled',
	'MiddleDisabled',
	'RightDisabled',
	'TopLeft',
	'TopRight',
	'BottomLeft',
	'BottomRight',
	'TopMiddle',
	'MiddleLeft',
	'MiddleRight',
	'BottomMiddle',
	'MiddleMiddle',
	'TabSpacer',
	'TabSpacer1',
	'TabSpacer2',
	'_RightSeparator',
	'_LeftSeparator',
	'Cover',
	'Border',
	'Background',
	'TopTex',
	'TopLeftTex',
	'TopRightTex',
	'LeftTex',
	'BottomTex',
	'BottomLeftTex',
	'BottomRightTex',
	'RightTex',
	'MiddleTex',
	'Center'
}

-- Depends on the arrow texture to be up by default.
S.ArrowRotation = {
	up = 0,
	down = 3.14,
	left = 1.57,
	right = -1.57,
}

function S:SetBackdropBorderColor(frame, script)
	if frame.backdrop then frame = frame.backdrop end
	if frame.SetBackdropBorderColor then
		frame:SetBackdropBorderColor(unpack(script == 'OnEnter' and E.media.rgbvaluecolor or E.media.bordercolor))
	end
end

function S:SetModifiedBackdrop()
	if self:IsEnabled() then
		S:SetBackdropBorderColor(self, 'OnEnter')
	end
end

function S:SetOriginalBackdrop()
	if self:IsEnabled() then
		S:SetBackdropBorderColor(self, 'OnLeave')
	end
end

function S:SetDisabledBackdrop()
	if self:IsMouseOver() then
		S:SetBackdropBorderColor(self, 'OnDisable')
	end
end

-- DropDownMenu library support
function S:SkinLibDropDownMenu(prefix)
	if S[prefix..'_UIDropDownMenuSkinned'] then return end

	local key = (prefix == 'L4' or prefix == 'L3') and 'L' or prefix

	local bd = _G[key..'_DropDownList1Backdrop']
	local mbd = _G[key..'_DropDownList1MenuBackdrop']
	if bd and not bd.template then bd:SetTemplate('Transparent') end
	if mbd and not mbd.template then mbd:SetTemplate('Transparent') end

	S[prefix..'_UIDropDownMenuSkinned'] = true

	local lib = prefix == 'L4' and LibStub.libs['LibUIDropDownMenu-4.0']
	if (lib and lib.UIDropDownMenu_CreateFrames) or _G[key..'_UIDropDownMenu_CreateFrames'] then
		hooksecurefunc(lib or _G, (lib and '' or key..'_') .. 'UIDropDownMenu_CreateFrames', function()
			local lvls = _G[(key == 'Lib' and 'LIB' or key)..'_UIDROPDOWNMENU_MAXLEVELS']
			local ddbd = lvls and _G[key..'_DropDownList'..lvls..'Backdrop']
			local ddmbd = lvls and _G[key..'_DropDownList'..lvls..'MenuBackdrop']
			if ddbd and not ddbd.template then ddbd:SetTemplate('Transparent') end
			if ddmbd and not ddmbd.template then ddmbd:SetTemplate('Transparent') end
		end)
	end
end

function S:HandleButton(button, strip, isDecline, noStyle, createBackdrop, template, noGlossTex, overrideTex, frameLevel, regionsKill, regionsZero)
	assert(button, 'doesnt exist!')

	if button.isSkinned then return end

	if button.SetNormalTexture and not overrideTex then button:SetNormalTexture(E.ClearTexture) end
	if button.SetHighlightTexture then button:SetHighlightTexture(E.ClearTexture) end
	if button.SetPushedTexture then button:SetPushedTexture(E.ClearTexture) end
	if button.SetDisabledTexture then button:SetDisabledTexture(E.ClearTexture) end

	if strip then button:StripTextures() end

	S:HandleBlizzardRegions(button, nil, regionsKill, regionsZero)

	if button.Icon then
		local Texture = button.Icon:GetTexture()
		if Texture and (type(Texture) == 'string' and strfind(Texture, [[Interface\ChatFrame\ChatFrameExpandArrow]])) then
			button.Icon:SetTexture(E.Media.Textures.ArrowUp)
			button.Icon:SetRotation(S.ArrowRotation.right)
			button.Icon:SetVertexColor(1, 1, 1)
		end
	end

	if isDecline and button.Icon then
		button.Icon:SetTexture(E.Media.Textures.Close)
	end

	if not noStyle then
		if createBackdrop then
			button:CreateBackdrop(template, not noGlossTex, nil, nil, nil, nil, nil, true, frameLevel)
		else
			button:SetTemplate(template, not noGlossTex)
		end

		button:HookScript('OnEnter', S.SetModifiedBackdrop)
		button:HookScript('OnLeave', S.SetOriginalBackdrop)
		button:HookScript('OnDisable', S.SetDisabledBackdrop)
	end

	button.isSkinned = true
end

do
	local function GetElement(frame, element, useParent)
		if useParent then frame = frame:GetParent() end

		local child = frame[element]
		if child then return child end

		local name = frame:GetName()
		if name then return _G[name..element] end
	end

	local function GetButton(frame, buttons)
		for _, data in ipairs(buttons) do
			if type(data) == 'string' then
				local found = GetElement(frame, data)
				if found then return found end
			else -- has useParent
				local found = GetElement(frame, data[1], data[2])
				if found then return found end
			end
		end
	end

	local function ThumbStatus(frame)
		if not frame.Thumb then
			return
		elseif not frame:IsEnabled() then
			frame.Thumb.backdrop:SetBackdropColor(0.3, 0.3, 0.3)
			return
		end

		local _, max = frame:GetMinMaxValues()
		if max == 0 then
			frame.Thumb.backdrop:SetBackdropColor(0.3, 0.3, 0.3)
		else
			frame.Thumb.backdrop:SetBackdropColor(unpack(E.media.rgbvaluecolor))
		end
	end

	local function ThumbWatcher(frame)
		hooksecurefunc(frame, 'Enable', ThumbStatus)
		hooksecurefunc(frame, 'Disable', ThumbStatus)
		hooksecurefunc(frame, 'SetEnabled', ThumbStatus)
		hooksecurefunc(frame, 'SetMinMaxValues', ThumbStatus)
		ThumbStatus(frame)
	end

	local upButtons = {'ScrollUpButton', 'UpButton', 'ScrollUp', {'scrollUp', true}, 'Back'}
	local downButtons = {'ScrollDownButton', 'DownButton', 'ScrollDown', {'scrollDown', true}, 'Forward'}
	local thumbButtons = {'ThumbTexture', 'thumbTexture', 'Thumb'}

	function S:HandleScrollBar(frame, thumbY, thumbX, template)
		assert(frame, 'doesnt exist!')

		if frame.backdrop then return end

		local upButton, downButton = GetButton(frame, upButtons), GetButton(frame, downButtons)
		local thumb = GetButton(frame, thumbButtons) or (frame.GetThumbTexture and frame:GetThumbTexture())

		frame:StripTextures()
		frame:CreateBackdrop(template or 'Transparent', nil, nil, nil, nil, nil, nil, nil, true)
		frame.backdrop:Point('TOPLEFT', upButton or frame, upButton and 'BOTTOMLEFT' or 'TOPLEFT', 0, 1)
		frame.backdrop:Point('BOTTOMRIGHT', downButton or frame, upButton and 'TOPRIGHT' or 'BOTTOMRIGHT', 0, -1)

		if frame.Background then frame.Background:Hide() end
		if frame.ScrollUpBorder then frame.ScrollUpBorder:Hide() end
		if frame.ScrollDownBorder then frame.ScrollDownBorder:Hide() end

		local frameLevel = frame:GetFrameLevel()
		if upButton then
			S:HandleNextPrevButton(upButton, 'up')
			upButton:SetFrameLevel(frameLevel + 2)
		end
		if downButton then
			S:HandleNextPrevButton(downButton, 'down')
			downButton:SetFrameLevel(frameLevel + 2)
		end
		if thumb and not thumb.backdrop then
			thumb:SetTexture()
			thumb:CreateBackdrop(nil, true, true, nil, nil, nil, nil, nil, frameLevel + 1)

			if not frame.Thumb then
				frame.Thumb = thumb
			end

			if thumb.backdrop then
				if not thumbX then thumbX = 0 end
				if not thumbY then thumbY = 0 end

				thumb.backdrop:Point('TOPLEFT', thumb, thumbX, -thumbY)
				thumb.backdrop:Point('BOTTOMRIGHT', thumb, -thumbX, thumbY)

				if frame.SetEnabled then
					ThumbWatcher(frame)
				else
					thumb.backdrop:SetBackdropColor(unpack(E.media.rgbvaluecolor))
				end
			end
		end
	end

	-- WoWTrimScrollBar
	local function ReskinScrollBarArrow(frame, direction)
		S:HandleNextPrevButton(frame, direction)

		if frame.Texture then
			frame.Texture:SetAlpha(0)

			if frame.Overlay then
				frame.Overlay:SetAlpha(0)
			end
		else
			frame:StripTextures()
		end
	end

	local function ThumbOnEnter(frame)
		local r, g, b = unpack(E.media.rgbvaluecolor)
		local thumb = frame.thumb or frame
		if thumb.backdrop then
			thumb.backdrop:SetBackdropColor(r, g, b, .75)
		end
	end

	local function ThumbOnLeave(frame)
		local r, g, b = unpack(E.media.rgbvaluecolor)
		local thumb = frame.thumb or frame

		if thumb.backdrop and not thumb.__isActive then
			thumb.backdrop:SetBackdropColor(r, g, b, .25)
		end
	end

	local function ThumbOnMouseDown(frame)
		local r, g, b = unpack(E.media.rgbvaluecolor)
		local thumb = frame.thumb or frame
		thumb.__isActive = true

		if thumb.backdrop then
			thumb.backdrop:SetBackdropColor(r, g, b, .75)
		end
	end

	local function ThumbOnMouseUp(frame)
		local r, g, b = unpack(E.media.rgbvaluecolor)
		local thumb = frame.thumb or frame
		thumb.__isActive = nil

		if thumb.backdrop then
			thumb.backdrop:SetBackdropColor(r, g, b, .25)
		end
	end

	function S:HandleTrimScrollBar(frame, small)
		assert(frame, 'does not exist.')

		frame:StripTextures()

		ReskinScrollBarArrow(frame.Back, 'up')
		ReskinScrollBarArrow(frame.Forward, 'down')

		if frame.Background then
			frame.Background:Hide()
		end

		local track = frame.Track
		if track then
			track:DisableDrawLayer('ARTWORK')
		end

		local thumb = frame:GetThumb()
		if thumb then
			thumb:DisableDrawLayer('BACKGROUND')
			thumb:CreateBackdrop('Transparent')
			thumb.backdrop:SetFrameLevel(thumb:GetFrameLevel()+1)

			local r, g, b = unpack(E.media.rgbvaluecolor)
			thumb.backdrop:SetBackdropColor(r, g, b, .25)

			if not small then
				thumb.backdrop:Point('TOPLEFT', 4, -1)
				thumb.backdrop:Point('BOTTOMRIGHT', -4, 1)
			end

			thumb:HookScript('OnEnter', ThumbOnEnter)
			thumb:HookScript('OnLeave', ThumbOnLeave)
			thumb:HookScript('OnMouseUp', ThumbOnMouseUp)
			thumb:HookScript('OnMouseDown', ThumbOnMouseDown)
		end
	end
end

function S:HandleBlizzardRegions(frame, name, kill, zero)
	if not name then name = frame.GetName and frame:GetName() end
	for _, area in pairs(S.Blizzard.Regions) do
		local object = (name and _G[name..area]) or frame[area]
		if object then
			if kill then
				object:Kill()
			elseif zero then
				object:SetAlpha(0)
			else
				object:Hide()
			end
		end
	end
end

function S:HandleEditBox(frame, template)
	assert(frame, 'doesnt exist!')

	if frame.backdrop then return end

	frame:CreateBackdrop(template, nil, nil, nil, nil, nil, nil, nil, true)
	frame.backdrop:SetPoint('TOPLEFT', -2, 0)
	frame.backdrop:SetPoint('BOTTOMRIGHT')
	S:HandleBlizzardRegions(frame)

	local EditBoxName = frame:GetName()
	if EditBoxName and (strfind(EditBoxName, 'Silver') or strfind(EditBoxName, 'Copper')) then
		frame.backdrop:Point('BOTTOMRIGHT', -12, -2)
	end
end

function S:HandleDropDownBox(frame, width, pos, template)
	assert(frame, 'doesnt exist!')

	local frameName = frame.GetName and frame:GetName()
	local button = frame.Button or frameName and (_G[frameName..'Button'] or _G[frameName..'_Button'])
	local text = frameName and _G[frameName..'Text'] or frame.Text
	local icon = frame.Icon

	if not button then
		return
	end

	if not width then
		width = 155
	end

	frame:Width(width)
	frame:StripTextures()
	frame:CreateBackdrop(template)
	frame:SetFrameLevel(frame:GetFrameLevel() + 2)
	frame.backdrop:Point('TOPLEFT', 20, -2)
	frame.backdrop:Point('BOTTOMRIGHT', button, 'BOTTOMRIGHT', 2, -2)

	button:ClearAllPoints()

	if pos then
		button:Point('TOPRIGHT', frame.Right, -20, -21)
	else
		button:Point('RIGHT', frame, 'RIGHT', -10, 3)
	end

	button.SetPoint = E.noop
	S:HandleNextPrevButton(button, 'down')

	if text then
		text:ClearAllPoints()
		text:Point('RIGHT', button, 'LEFT', -2, 0)
	end

	if icon then
		icon:Point('LEFT', 23, 0)
	end
end

do
	local check = [[Interface\Buttons\UI-CheckBox-Check]]
	local disabled = [[Interface\Buttons\UI-CheckBox-Check-Disabled]]

	local function checkNormalTexture(checkbox, texture) if texture ~= E.ClearTexture then checkbox:SetNormalTexture(E.ClearTexture) end end
	local function checkPushedTexture(checkbox, texture) if texture ~= E.ClearTexture then checkbox:SetPushedTexture(E.ClearTexture) end end
	local function checkHighlightTexture(checkbox, texture) if texture ~= E.ClearTexture then checkbox:SetHighlightTexture(E.ClearTexture) end end
	local function checkCheckedTexture(checkbox, texture)
		local melli = E.Media and E.Media.Textures and E.Media.Textures.Melli
			if texture == melli or texture == check then return end
			checkbox:SetCheckedTexture((E.private.skins.checkBoxSkin and melli) or check)
	end
	local function checkOnDisable(checkbox)
		if not checkbox.SetDisabledTexture then return end
		checkbox:SetDisabledTexture(checkbox:GetChecked() and (E.private.skins.checkBoxSkin and E.Media.Textures.Melli or disabled) or '')
	end

	function S:HandleCheckBox(frame, noBackdrop, noReplaceTextures, frameLevel, template)
		assert(frame, 'does not exist.')

		if frame.isSkinned then return end

		frame:StripTextures()

		if noBackdrop then
			frame:Size(16)
		else
			frame:CreateBackdrop(template, nil, nil, nil, nil, nil, nil, nil, frameLevel)
			frame.backdrop:SetInside(nil, 4, 4)
		end

		if not noReplaceTextures then
			if frame.SetCheckedTexture then
				if E.private.skins.checkBoxSkin then
					frame:SetCheckedTexture(E.Media.Textures.Melli)

					local checkedTexture = frame:GetCheckedTexture()
					checkedTexture:SetVertexColor(1, .82, 0, 0.8)
					checkedTexture:SetInside(frame.backdrop)
				else
					frame:SetCheckedTexture(check)

					if noBackdrop then
						frame:GetCheckedTexture():SetInside(nil, -4, -4)
					end
				end
			end

			if frame.SetDisabledTexture then
				if E.private.skins.checkBoxSkin then
					frame:SetDisabledTexture(E.Media.Textures.Melli)

					local disabledTexture = frame:GetDisabledTexture()
					disabledTexture:SetVertexColor(.6, .6, .6, .8)
					disabledTexture:SetInside(frame.backdrop)
				else
					frame:SetDisabledTexture(disabled)

					if noBackdrop then
						frame:GetDisabledTexture():SetInside(nil, -4, -4)
					end
				end
			end

			frame:HookScript('OnDisable', checkOnDisable)

			hooksecurefunc(frame, 'SetNormalTexture', checkNormalTexture)
			hooksecurefunc(frame, 'SetPushedTexture', checkPushedTexture)
			hooksecurefunc(frame, 'SetCheckedTexture', checkCheckedTexture)
			hooksecurefunc(frame, 'SetHighlightTexture', checkHighlightTexture)
		end

		frame.isSkinned = true
	end
end

do
	local background = [[Interface\Minimap\UI-Minimap-Background]]

	local function buttonNormalTexture(frame, texture) if texture ~= E.ClearTexture then frame:SetNormalTexture(E.ClearTexture) end end
	local function buttonPushedTexture(frame, texture) if texture ~= E.ClearTexture then frame:SetPushedTexture(E.ClearTexture) end end
	local function buttonDisabledTexture(frame, texture) if texture ~= E.ClearTexture then frame:SetDisabledTexture(E.ClearTexture) end end
	local function buttonHighlightTexture(frame, texture) if texture ~= E.ClearTexture then frame:SetHighlightTexture(E.ClearTexture) end end

	function S:HandleRadioButton(Button)
		if Button.isSkinned then return end

		local InsideMask = Button:CreateMaskTexture()
		InsideMask:SetTexture(background, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
		InsideMask:Size(10, 10)
		InsideMask:Point('CENTER')
		Button.InsideMask = InsideMask

		local OutsideMask = Button:CreateMaskTexture()
		OutsideMask:SetTexture(background, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
		OutsideMask:Size(13, 13)
		OutsideMask:Point('CENTER')
		Button.OutsideMask = OutsideMask

		Button:SetCheckedTexture(E.media.normTex)
		Button:SetNormalTexture(E.media.normTex)
		Button:SetHighlightTexture(E.media.normTex)
		Button:SetDisabledTexture(E.media.normTex)

		local Check = Button:GetCheckedTexture()
		Check:SetVertexColor(unpack(E.media.rgbvaluecolor))
		Check:SetTexCoord(0, 1, 0, 1)
		Check:SetInside()
		Check:AddMaskTexture(InsideMask)

		local Highlight = Button:GetHighlightTexture()
		Highlight:SetTexCoord(0, 1, 0, 1)
		Highlight:SetVertexColor(1, 1, 1)
		Highlight:AddMaskTexture(InsideMask)

		local Normal = Button:GetNormalTexture()
		Normal:SetOutside()
		Normal:SetTexCoord(0, 1, 0, 1)
		Normal:SetVertexColor(unpack(E.media.bordercolor))
		Normal:AddMaskTexture(OutsideMask)

		local Disabled = Button:GetDisabledTexture()
		Disabled:SetVertexColor(.3, .3, .3)
		Disabled:AddMaskTexture(OutsideMask)

		hooksecurefunc(Button, 'SetNormalTexture', buttonNormalTexture)
		hooksecurefunc(Button, 'SetPushedTexture', buttonPushedTexture)
		hooksecurefunc(Button, 'SetDisabledTexture', buttonDisabledTexture)
		hooksecurefunc(Button, 'SetHighlightTexture', buttonHighlightTexture)

		Button.isSkinned = true
	end
end

do
	local closeOnEnter = function(btn) if btn.Texture then btn.Texture:SetVertexColor(unpack(E.media.rgbvaluecolor)) end end
	local closeOnLeave = function(btn) if btn.Texture then btn.Texture:SetVertexColor(1, 1, 1) end end

	function S:HandleCloseButton(f, point, x, y)
		assert(f, 'doenst exist!')

		f:StripTextures()

		if not f.Texture then
			f.Texture = f:CreateTexture(nil, 'OVERLAY')
			f.Texture:Point('CENTER')
			f.Texture:SetTexture(E.Media.Textures.Close)
			f.Texture:Size(12, 12)
			f:HookScript('OnEnter', closeOnEnter)
			f:HookScript('OnLeave', closeOnLeave)
			f:SetHitRectInsets(6, 6, 7, 7)
		end

		if point then
			f:Point('TOPRIGHT', point, 'TOPRIGHT', x or 2, y or 2)
		end
	end

	function S:HandleNextPrevButton(btn, arrowDir, color, noBackdrop, stripTexts, frameLevel)
		if btn.isSkinned then return end

		if not arrowDir then
			arrowDir = 'down'

			local name = btn:GetDebugName()
			local ButtonName = name and name:lower()
			if ButtonName then
				if strfind(ButtonName, 'left') or strfind(ButtonName, 'prev') or strfind(ButtonName, 'decrement') or strfind(ButtonName, 'backward') or strfind(ButtonName, 'back') then
					arrowDir = 'left'
				elseif strfind(ButtonName, 'right') or strfind(ButtonName, 'next') or strfind(ButtonName, 'increment') or strfind(ButtonName, 'forward') then
					arrowDir = 'right'
				elseif strfind(ButtonName, 'scrollup') or strfind(ButtonName, 'upbutton') or strfind(ButtonName, 'top') or strfind(ButtonName, 'asc') or strfind(ButtonName, 'home') or strfind(ButtonName, 'maximize') then
					arrowDir = 'up'
				end
			end
		end

		btn:StripTextures()

		if btn.Texture then
			btn.Texture:SetAlpha(0)
		end

		if not noBackdrop then
			S:HandleButton(btn, nil, nil, true, nil, nil, nil, nil, frameLevel)
		end

		if stripTexts then
			btn:StripTexts()
		end

		btn:SetNormalTexture(E.Media.Textures.ArrowUp)
		btn:SetPushedTexture(E.Media.Textures.ArrowUp)
		btn:SetDisabledTexture(E.Media.Textures.ArrowUp)

		local Normal, Disabled, Pushed = btn:GetNormalTexture(), btn:GetDisabledTexture(), btn:GetPushedTexture()

		if noBackdrop then
			btn:Size(20, 20)
			Disabled:SetVertexColor(.5, .5, .5)
			btn.Texture = Normal

			if not color then
				btn:HookScript('OnEnter', closeOnEnter)
				btn:HookScript('OnLeave', closeOnLeave)
			end
		else
			btn:Size(18, 18)
			Disabled:SetVertexColor(.3, .3, .3)
		end

		Normal:SetInside()
		Pushed:SetInside()
		Disabled:SetInside()

		Normal:SetTexCoord(0, 1, 0, 1)
		Pushed:SetTexCoord(0, 1, 0, 1)
		Disabled:SetTexCoord(0, 1, 0, 1)

		local rotation = S.ArrowRotation[arrowDir]
		if rotation then
			Normal:SetRotation(rotation)
			Pushed:SetRotation(rotation)
			Disabled:SetRotation(rotation)
		end

		if color then
			Normal:SetVertexColor(color.r, color.g, color.b)
		else
			Normal:SetVertexColor(1, 1, 1)
		end

		btn.isSkinned = true
	end
end

function S:HandleSliderFrame(frame, template, frameLevel)
	assert(frame, 'doesnt exist!')

	local orientation = frame:GetOrientation()
	local SIZE = 12

	if frame.SetBackdrop then
		frame:SetBackdrop()
	end

	frame:StripTextures()
	frame:SetThumbTexture(E.Media.Textures.Melli)

	if not frame.backdrop then
		frame:CreateBackdrop(template, nil, nil, nil, nil, nil, nil, true, frameLevel)
	end

	local thumb = frame:GetThumbTexture()
	thumb:SetVertexColor(1, .82, 0, 0.8)
	thumb:Size(SIZE-2,SIZE-2)

	if orientation == 'VERTICAL' then
		frame:Width(SIZE)
	else
		frame:Height(SIZE)

		for _, region in next, { frame:GetRegions() } do
			if region:IsObjectType('FontString') then
				local point, anchor, anchorPoint, x, y = region:GetPoint()
				if strfind(anchorPoint, 'BOTTOM') then
					region:Point(point, anchor, anchorPoint, x, y - 4)
				end
			end
		end
	end
end

function S:ADDON_LOADED(_, addonName)
	if not self.allowBypass[addonName] and not E.initialized then
		return
	end

	local object = self.addonsToLoad[addonName]
	if object then
		S:CallLoadedAddon(addonName, object)
	end
end

-- nonAddonsToLoad:
--- this is used for loading skins when our skin init function executes.
--- please add a given name, non-given-name is specific for elvui core addon.
function S:AddCallback(name, func, position) -- arg1: name is 'given name'
	local load = (type(name) == 'function' and name) or (not func and S[name])
	S:RegisterSkin('ElvUIChat', load or func, nil, nil, position)
end

local function errorhandler(err)
	return _G.geterrorhandler()(err)
end

function S:RegisterSkin(addonName, func, forceLoad, bypass, position)
	if bypass then
		self.allowBypass[addonName] = true
	end

	if forceLoad then
		xpcall(func, errorhandler)
		self.addonsToLoad[addonName] = nil
	elseif addonName == 'ElvUIChat' then
		if position then
			tinsert(self.nonAddonsToLoad, position, func)
		else
			tinsert(self.nonAddonsToLoad, func)
		end
	else
		local addon = self.addonsToLoad[addonName]
		if not addon then
			self.addonsToLoad[addonName] = {}
			addon = self.addonsToLoad[addonName]
		end

		if position then
			tinsert(addon, position, func)
		else
			tinsert(addon, func)
		end
	end
end

function S:CallLoadedAddon(addonName, object)
	for _, func in next, object do
		xpcall(func, errorhandler)
	end

	self.addonsToLoad[addonName] = nil
end

function S:Initialize()
	self.Initialized = true
	self.db = E.private.skins

	for index, func in next, self.nonAddonsToLoad do
		xpcall(func, errorhandler)
		self.nonAddonsToLoad[index] = nil
	end

	for addonName, object in pairs(self.addonsToLoad) do
		local isLoaded, isFinished = IsAddOnLoaded(addonName)
		if isLoaded and isFinished then
			S:CallLoadedAddon(addonName, object)
		end
	end

	-- Early Skin Handling (populated before ElvUIChat is loaded from the Ace3 file)
	if E.private.skins.ace3Enable and S.EarlyAceWidgets then
		for _, n in next, S.EarlyAceWidgets do
			if n.SetLayout then
				S:Ace3_RegisterAsContainer(n)
			else
				S:Ace3_RegisterAsWidget(n)
			end
		end
		for _, n in next, S.EarlyAceTooltips do
			S:Ace3_SkinTooltip(LibStub(n, true))
		end
	end
	if S.EarlyDropdowns then
		for _, n in next, S.EarlyDropdowns do
			S:SkinLibDropDownMenu(n)
		end
	end
end

-- Keep this outside, it's used for skinning addons before ElvUIChat load
S:RegisterEvent('ADDON_LOADED')

E:RegisterModule(S:GetName())
