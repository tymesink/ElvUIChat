local E, L, V, P, G = unpack(ElvUIChat)

local _G = _G
local strsub, type = strsub, type
local next, pcall, unpack = next, pcall, unpack
local hooksecurefunc = hooksecurefunc
local getmetatable = getmetatable
local tonumber = tonumber

local EnumerateFrames = EnumerateFrames
local CreateFrame = CreateFrame

local backdropr, backdropg, backdropb, backdropa = 0, 0, 0, 1
local borderr, borderg, borderb, bordera = 0, 0, 0, 1

local StripTexturesBlizzFrames = {
	'Inset',
	'inset',
	'InsetFrame',
	'LeftInset',
	'RightInset',
	'NineSlice',
	'BG',
	'Bg',
	'border',
	'Border',
	'Background',
	'BorderFrame',
	'bottomInset',
	'BottomInset',
	'bgLeft',
	'bgRight',
	'FilligreeOverlay',
	'PortraitOverlay',
	'ArtOverlayFrame',
	'Portrait',
	'portrait',
	'ScrollFrameBorder',
	'ScrollUpBorder',
	'ScrollDownBorder',
}

local SetTexCoords
do
	local left, right, top, bottom = unpack(E.TexCoords)

	SetTexCoords = function(frame)
		frame:SetTexCoord(left, right, top, bottom)
	end

end


local function WatchPixelSnap(frame, snap)
	if (frame and not frame:IsForbidden()) and frame.PixelSnapDisabled and snap then
		frame.PixelSnapDisabled = nil
	end
end

local function DisablePixelSnap(frame)
	if (frame and not frame:IsForbidden()) and not frame.PixelSnapDisabled then
		if frame.SetSnapToPixelGrid then
			frame:SetSnapToPixelGrid(false)
			frame:SetTexelSnappingBias(0)
		elseif frame.GetStatusBarTexture then
			local texture = frame:GetStatusBarTexture()
			if type(texture) == 'table' and texture.SetSnapToPixelGrid then
				texture:SetSnapToPixelGrid(false)
				texture:SetTexelSnappingBias(0)
			end
		end

		frame.PixelSnapDisabled = true
	end
end

local function BackdropFrameLevel(frame, level)
	frame:SetFrameLevel(level)

	if frame.oborder then frame.oborder:SetFrameLevel(level) end
	if frame.iborder then frame.iborder:SetFrameLevel(level) end
end

local function BackdropFrameLower(backdrop, parent)
	local level = parent:GetFrameLevel()
	local minus = level and (level - 1)
	if minus and (minus >= 0) then
		BackdropFrameLevel(backdrop, minus)
	else
		BackdropFrameLevel(backdrop, 0)
	end
end

local function GetTemplate(template)
	backdropa, bordera = 1, 1

	if template == 'ClassColor' then
		local color = E.myClassColor
		borderr, borderg, borderb = color.r, color.g, color.b
		backdropr, backdropg, backdropb = unpack(E.media.backdropcolor)
	elseif template == 'Transparent' then
		borderr, borderg, borderb = unpack(E.media.bordercolor)
		backdropr, backdropg, backdropb, backdropa = unpack(E.media.backdropfadecolor)
	else
		borderr, borderg, borderb = unpack(E.media.bordercolor)
		backdropr, backdropg, backdropb = unpack(E.media.backdropcolor)
	end
end


local function Size(frame, width, height, ...)
	local w = E:Scale(width)
	frame:SetSize(w, (height and E:Scale(height)) or w, ...)
end

local function Width(frame, width, ...)
	frame:SetWidth(E:Scale(width), ...)
end

local function Height(frame, height, ...)
	frame:SetHeight(E:Scale(height), ...)
end

local function OffsetFrameLevel(frame, offset, secondary)
	if not secondary then secondary = frame end

	local level = secondary:GetFrameLevel()
	frame:SetFrameLevel(level + (offset or 0))
end

local function Point(obj, arg1, arg2, arg3, arg4, arg5, ...)
	if not arg2 then arg2 = obj:GetParent() end

	if type(arg2)=='number' then arg2 = E:Scale(arg2) end
	if type(arg3)=='number' then arg3 = E:Scale(arg3) end
	if type(arg4)=='number' then arg4 = E:Scale(arg4) end
	if type(arg5)=='number' then arg5 = E:Scale(arg5) end

	obj:SetPoint(arg1, arg2, arg3, arg4, arg5, ...)
end


function E:SetPointsRestricted(frame)
	if frame and not pcall(frame.GetPoint, frame) then
		return true
	end
end

local function SetOutside(obj, anchor, xOffset, yOffset, anchor2, noScale)
	if not anchor then anchor = obj:GetParent() end

	if not xOffset then xOffset = E.Border end
	if not yOffset then yOffset = E.Border end
	local x = (noScale and xOffset) or E:Scale(xOffset)
	local y = (noScale and yOffset) or E:Scale(yOffset)

	if E:SetPointsRestricted(obj) or obj:GetPoint() then
		obj:ClearAllPoints()
	end

	DisablePixelSnap(obj)
	obj:SetPoint('TOPLEFT', anchor, 'TOPLEFT', -x, y)
	obj:SetPoint('BOTTOMRIGHT', anchor2 or anchor, 'BOTTOMRIGHT', x, -y)
end

local function SetInside(obj, anchor, xOffset, yOffset, anchor2, noScale)
	if not anchor then anchor = obj:GetParent() end

	if not xOffset then xOffset = E.Border end
	if not yOffset then yOffset = E.Border end
	local x = (noScale and xOffset) or E:Scale(xOffset)
	local y = (noScale and yOffset) or E:Scale(yOffset)

	if E:SetPointsRestricted(obj) or obj:GetPoint() then
		obj:ClearAllPoints()
	end

	DisablePixelSnap(obj)
	obj:SetPoint('TOPLEFT', anchor, 'TOPLEFT', x, -y)
	obj:SetPoint('BOTTOMRIGHT', anchor2 or anchor, 'BOTTOMRIGHT', -x, y)
end

local function SetTemplate(frame, template, glossTex, ignoreUpdates, forcePixelMode, noScale)
	GetTemplate(template)

	frame.template = template or 'Default'
	frame.glossTex = glossTex
	frame.ignoreUpdates = ignoreUpdates
	frame.forcePixelMode = forcePixelMode

	if not frame.SetBackdrop then
		_G.Mixin(frame, _G.BackdropTemplateMixin)

		if frame.OnSizeChanged then
			frame:HookScript('OnSizeChanged', frame.OnBackdropSizeChanged)
		end
	end

	if template == 'NoBackdrop' then
		frame:SetBackdrop()
	else
		local edgeSize = E.twoPixelsPlease and 2 or 1

		frame:SetBackdrop({
			edgeFile = E.media.blankTex,
			bgFile = glossTex and (type(glossTex) == 'string' and glossTex or E.media.glossTex) or E.media.blankTex,
			edgeSize = noScale and edgeSize or E:Scale(edgeSize)
		})

		if frame.callbackBackdropColor then
			frame:callbackBackdropColor()
		else
			frame:SetBackdropColor(backdropr, backdropg, backdropb, frame.customBackdropAlpha or (template == 'Transparent' and backdropa) or 1)
		end

		local notPixelMode = not E.PixelMode
		if notPixelMode and not forcePixelMode then
			local backdrop = {
				edgeFile = E.media.blankTex,
				edgeSize = noScale and 1 or E:Scale(1)
			}

			local level = frame:GetFrameLevel()
			if not frame.iborder then
				local border = CreateFrame('Frame', nil, frame, 'BackdropTemplate')
				border:SetBackdrop(backdrop)
				border:SetBackdropBorderColor(0, 0, 0, 1)
				border:SetFrameLevel(level)
				border:SetInside(frame, 1, 1, nil, noScale)
				frame.iborder = border
			end

			if not frame.oborder then
				local border = CreateFrame('Frame', nil, frame, 'BackdropTemplate')
				border:SetBackdrop(backdrop)
				border:SetBackdropBorderColor(0, 0, 0, 1)
				border:SetFrameLevel(level)
				border:SetOutside(frame, 1, 1, nil, noScale)
				frame.oborder = border
			end
		end
	end

	if frame.forcedBorderColors then
		borderr, borderg, borderb, bordera = unpack(frame.forcedBorderColors)
	end

	frame:SetBackdropBorderColor(borderr, borderg, borderb, bordera)

	if not frame.ignoreUpdates then
		E.frames[frame] = true
	end
end

local function CreateBackdrop(frame, template, glossTex, ignoreUpdates, forcePixelMode, noScale, allPoints, frameLevel)
	local parent = (frame.IsObjectType and frame:IsObjectType('Texture') and frame:GetParent()) or frame
	local backdrop = frame.backdrop or CreateFrame('Frame', nil, parent)
	if not frame.backdrop then frame.backdrop = backdrop end

	backdrop:SetTemplate(template, glossTex, ignoreUpdates, forcePixelMode, noScale)

	if allPoints then
		if allPoints == true then
			backdrop:SetAllPoints()
		else
			backdrop:SetAllPoints(allPoints)
		end
	else
		if forcePixelMode then
			backdrop:SetOutside(frame, E.twoPixelsPlease and 2 or 1, E.twoPixelsPlease and 2 or 1, nil, noScale)
		else
			backdrop:SetOutside(frame, E.Border, E.Border, nil, noScale)
		end
	end

	if frameLevel then
		if frameLevel == true then
			BackdropFrameLevel(backdrop, parent:GetFrameLevel())
		else
			BackdropFrameLevel(backdrop, frameLevel)
		end
	else
		BackdropFrameLower(backdrop, parent)
	end
end


local function Kill(object)
	if object.UnregisterAllEvents then
		object:UnregisterAllEvents()
		object:SetParent(E.HiddenFrame)
	else
		object.Show = object.Hide
	end

	object:Hide()
end

local STRIP_TEX = 'Texture'
local STRIP_FONT = 'FontString'
local function StripRegion(which, object, kill, zero)
	if kill then
		object:Kill()
	elseif zero then
		object:SetAlpha(0)
	elseif which == STRIP_TEX then
		object:SetTexture(E.ClearTexture)
		object:SetAtlas('')
	elseif which == STRIP_FONT then
		object:SetText('')
	end
end

local function StripType(which, object, kill, zero)
	if object:IsObjectType(which) then
		StripRegion(which, object, kill, zero)
	else
		if which == STRIP_TEX then
			local FrameName = object.GetName and object:GetName()
			for _, Blizzard in next, StripTexturesBlizzFrames do
				local BlizzFrame = object[Blizzard] or (FrameName and _G[FrameName..Blizzard])
				if BlizzFrame and BlizzFrame.StripTextures then
					BlizzFrame:StripTextures(kill, zero)
				end
			end
		end

		if object.GetNumRegions then
			for _, region in next, { object:GetRegions() } do
				if region and region.IsObjectType and region:IsObjectType(which) then
					StripRegion(which, region, kill, zero)
				end
			end
		end
	end
end

local function StripTextures(object, kill, zero)
	StripType(STRIP_TEX, object, kill, zero)
end

local function StripTexts(object, kill, zero)
	StripType(STRIP_FONT, object, kill, zero)
end

local function FontTemplate(fs, font, size, style, skip)
	if not skip then -- ignore updates from UpdateFontTemplates
		fs.font, fs.fontSize, fs.fontStyle = font, size, style
	end

	-- grab values from profile before conversion (fallbacks to sane defaults)
	if not style then style = E.db.general.fontStyle or P.general.fontStyle or '' end
	if not size then size = E.db.general.fontSize or P.general.fontSize or 12 end
	local resolvedFont = font or E.media.normFont or _G.STANDARD_TEXT_FONT
	if style == 'NONE' then style = '' end -- none isnt a real style

	local shadow = strsub(style, 0, 6) == 'SHADOW'
	if shadow then style = strsub(style, 7) end -- shadow isnt a real style

	fs:SetShadowColor(0, 0, 0, (shadow and (style == '' and 1 or 0.6)) or 0)
	fs:SetShadowOffset((shadow and 1) or 0, (shadow and -1) or 0)

	fs:SetFont(resolvedFont, size, style)
end

local function StyleButton(button, noHover, noPushed, noChecked)
	if button.SetHighlightTexture and button.CreateTexture and not button.hover and not noHover then
		local highlightTex = (E.media and E.media.blankTex) or [[Interface\Buttons\WHITE8x8]]
		button:SetHighlightTexture(highlightTex)

		local hover = button:GetHighlightTexture()
		if hover then
			hover:SetInside()
			hover:SetBlendMode('ADD')
			hover:SetColorTexture(1, 1, 1, .3)
			button.hover = hover
		end
	end

	if button.SetPushedTexture and button.CreateTexture and not button.pushed and not noPushed then
		local pushedTex = (E.media and E.media.blankTex) or [[Interface\Buttons\WHITE8x8]]
		button:SetPushedTexture(pushedTex)

		local pushed = button:GetPushedTexture()
		pushed:SetInside()
		pushed:SetBlendMode('ADD')
		pushed:SetColorTexture(0.9, 0.8, 0.1, 0.3)
		button.pushed = pushed
	end

	if button.SetCheckedTexture and button.CreateTexture and not button.checked and not noChecked then
		button:SetCheckedTexture(E.media.blankTex)

		local checked = button:GetCheckedTexture()
		checked:SetInside()
		checked:SetBlendMode('ADD')
		checked:SetColorTexture(1, 1, 1, 0.3)
		button.checked = checked
	end
end


local API = {
	Kill = Kill,
	Size = Size,
	Point = Point,
	Width = Width,
	Height = Height,
	SetOutside = SetOutside,
	SetInside = SetInside,
	SetTemplate = SetTemplate,
	CreateBackdrop = CreateBackdrop,
	FontTemplate = FontTemplate,
	StripTextures = StripTextures,
	StripTexts = StripTexts,
	StyleButton = StyleButton,
	OffsetFrameLevel = OffsetFrameLevel,
	SetTexCoords = SetTexCoords,
}

local function AddAPI(object)
	local mk = getmetatable(object).__index
	for method, func in next, API do
		if not object[method] then
			mk[method] = func
		end
	end

	if not object.DisabledPixelSnap and (mk.SetSnapToPixelGrid or mk.SetStatusBarTexture or mk.SetColorTexture or mk.SetVertexColor or mk.CreateTexture or mk.SetTexCoord or mk.SetTexture) then
		if mk.SetSnapToPixelGrid then hooksecurefunc(mk, 'SetSnapToPixelGrid', WatchPixelSnap) end
		if mk.SetStatusBarTexture then hooksecurefunc(mk, 'SetStatusBarTexture', DisablePixelSnap) end
		if mk.SetColorTexture then hooksecurefunc(mk, 'SetColorTexture', DisablePixelSnap) end
		if mk.SetVertexColor then hooksecurefunc(mk, 'SetVertexColor', DisablePixelSnap) end
		if mk.CreateTexture then hooksecurefunc(mk, 'CreateTexture', DisablePixelSnap) end
		if mk.SetTexCoord then hooksecurefunc(mk, 'SetTexCoord', DisablePixelSnap) end
		if mk.SetTexture then hooksecurefunc(mk, 'SetTexture', DisablePixelSnap) end

		mk.DisabledPixelSnap = true
	end
end

local handled = { Frame = true }
local object = CreateFrame('Frame')
AddAPI(object)
AddAPI(object:CreateTexture())
AddAPI(object:CreateFontString())
AddAPI(object:CreateMaskTexture())

object = EnumerateFrames()
while object do
	local objType = object:GetObjectType()
	if not object:IsForbidden() and not handled[objType] then
		AddAPI(object)
		handled[objType] = true
	end

	object = EnumerateFrames(object)
end

AddAPI(_G.GameFontNormal) --Add API to `CreateFont` objects without actually creating one
AddAPI(CreateFrame('ScrollFrame')) --Hacky fix for issue on 7.1 PTR where scroll frames no longer seem to inherit the methods from the 'Frame' widget
