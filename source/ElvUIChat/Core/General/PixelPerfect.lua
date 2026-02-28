local E, L, V, P, G = unpack(ElvUIChat)

local _G = _G
local UIParent = UIParent
local GetScreenWidth = GetScreenWidth
local GetScreenHeight = GetScreenHeight
local InCombatLockdown = InCombatLockdown

function E:RefreshGlobalFX() -- using RefreshModelScene will taint
	_G.GlobalFXDialogModelScene:Hide()
	_G.GlobalFXDialogModelScene:Show()

	_G.GlobalFXMediumModelScene:Hide()
	_G.GlobalFXMediumModelScene:Show()

	_G.GlobalFXBackgroundModelScene:Hide()
	_G.GlobalFXBackgroundModelScene:Show()
end

function E:UIScale()
	if InCombatLockdown() then
		E:RegisterEventForObject('PLAYER_REGEN_ENABLED', E.UIScale, E.UIScale)
	else -- E.Initialize
		UIParent:SetScale(E.global.general.UIScale)

		E.screenWidth, E.screenHeight = GetScreenWidth(), GetScreenHeight()
		E.UIParent:SetSize(E.screenWidth, E.screenHeight)
		E.UIParent.origHeight = E.UIParent:GetHeight()

		-- ElvUIChat: Always refresh global FX (Retail-only)
		E:RefreshGlobalFX()

		if E:IsEventRegisteredForObject('PLAYER_REGEN_ENABLED', E.UIScale) then
			E:UnregisterEventForObject('PLAYER_REGEN_ENABLED', E.UIScale, E.UIScale)
		end
	end
end
