local E, L, V, P, G = unpack(ElvUIChat)
local ACD = E.Libs.AceConfigDialog

local min = min
local InCombatLockdown = InCombatLockdown
local ERR_NOT_IN_COMBAT = ERR_NOT_IN_COMBAT

-- Simple combat guard used by ToggleOptions.
function E:AlertCombat()
	if InCombatLockdown() then
		E:Print(ERR_NOT_IN_COMBAT)
		return true
	end
end

function E:Config_GetSize()
	return E.global.general.AceGUI.width, E.global.general.AceGUI.height
end

function E:Config_GetDefaultSize()
	local width, height = E:Config_GetSize()
	local maxWidth, maxHeight = E.UIParent:GetSize()
	width, height = min(maxWidth - 50, width), min(maxHeight - 50, height)
	return width, height
end

function E:Config_GetWindow()
	local ConfigOpen = ACD.OpenFrames and ACD.OpenFrames.ElvUIChat
	return ConfigOpen and ConfigOpen.frame
end

function E:Config_CloseWindow()
	ACD:Close('ElvUIChat')
end

function E:Config_OpenWindow()
	ACD:Open('ElvUIChat')
end

-- Midnight WoW changed GameTooltip:SetText/AddLine to require an explicit alpha
-- before the wrap boolean. Patch the AceConfigDialog tooltip instance so old
-- callers that pass (text, r, g, b, wrap) still work.
-- Midnight removed ColorPickerFrame:SetColorRGB() and ColorPickerFrame:Show() (old open API).
-- Ace3's AceGUIWidget-ColorPicker still uses the old pattern:
--   frame.func/opacityFunc/cancelFunc/hasOpacity/opacity set, then SetColorRGB + Show.
-- Shim SetColorRGB to store r,g,b and hook Show to call SetupColorPickerAndShow instead.
-- Also shim OpacitySliderFrame which the old Ace3 callbacks reference for alpha value.
function E:PatchColorPickerFrame()
	local CPF = _G.ColorPickerFrame
	if not CPF or CPF.__ecPatched then return end
	CPF.__ecPatched = true

	if not CPF.SetColorRGB then
		CPF.SetColorRGB = function(self, r, g, b)
			self._shimR, self._shimG, self._shimB = r, g, b
		end

		local origShow = CPF.Show
		CPF.Show = function(self, ...)
			if self._shimR ~= nil then
				local r, g, b = self._shimR, self._shimG, self._shimB
				self._shimR, self._shimG, self._shimB = nil, nil, nil
				self:SetupColorPickerAndShow({
					r = r, g = g, b = b,
					opacity = self.opacity or 0,
					hasOpacity = self.hasOpacity or false,
					swatchFunc = self.func,
					opacityFunc = self.opacityFunc,
					cancelFunc = self.cancelFunc,
				})
			else
				origShow(self, ...)
			end
		end
	end

	-- Old Ace3 callbacks use OpacitySliderFrame:GetValue() to get opacity (1-alpha).
	if not _G.OpacitySliderFrame then
		_G.OpacitySliderFrame = {
			GetValue = function()
				return CPF.hasOpacity and (1 - CPF:GetColorAlpha()) or 0
			end
		}
	end
end

function E:PatchAceTooltip()
	local tip = ACD and ACD.tooltip
	if not tip or tip.__ecPatched then return end
	tip.__ecPatched = true

	local origSetText = tip.SetText
	if origSetText then
		tip.SetText = function(self, text, r, g, b, alpha, wrap)
			if type(alpha) == 'boolean' then
				alpha, wrap = 1, alpha
			end
			return origSetText(self, text, r, g, b, alpha, wrap)
		end
	end

	local origAddLine = tip.AddLine
	if origAddLine then
		tip.AddLine = function(self, text, r, g, b, alpha, wrap)
			if type(alpha) == 'boolean' then
				alpha, wrap = 1, alpha
			end
			return origAddLine(self, text, r, g, b, alpha, wrap)
		end
	end
end

function E:ToggleOptions()
	if InCombatLockdown() then
		E:Print(ERR_NOT_IN_COMBAT)
		E.ShowOptions = true
		return
	end

	if E:Config_GetWindow() then
		ACD:Close('ElvUIChat')
		if E.ShowPopup then
			E:StaticPopup_Show('CONFIG_RL')
			E.ShowPopup = nil
		end
	else
		ACD:Open('ElvUIChat')
	end
end

