local E, L, V, P, G = unpack(ElvUIChat)
local B = E:GetModule('Blizzard')

local _G = _G
function B:Initialize()
	B.Initialized = true

	-- ElvUIChat: Guard Edit Mode selection math (Retail-only)
	-- local EditModeSystemMixin = _G.EditModeSystemMixin
	-- if EditModeSystemMixin and EditModeSystemMixin.GetScaledSelectionSides and not B._patchedSelectionSides then
	-- 	local origGetScaledSelectionSides = EditModeSystemMixin.GetScaledSelectionSides
	-- 	function EditModeSystemMixin:GetScaledSelectionSides(...)
	-- 		local left, bottom, width, height, scale = origGetScaledSelectionSides(self, ...)
	-- 		if not left or not bottom or not width or not height then
	-- 			return left or 0, bottom or 0, width or 0, height or 0, scale or 1
	-- 		end

	-- 		return left, bottom, width, height, scale
	-- 	end

	-- 	B._patchedSelectionSides = true
	-- end
end
E:RegisterModule(B:GetName())
