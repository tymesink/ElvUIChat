local E, L, V, P, G = unpack(ElvUIChat)
local B = E:GetModule('Blizzard')

local _G = _G
local UnitXP = UnitXP
local UnitXPMax = UnitXPMax
local GetRewardXP = GetRewardXP
local GetQuestLogRewardXP = GetQuestLogRewardXP
local C_QuestLog_ShouldShowQuestRewards = C_QuestLog.ShouldShowQuestRewards
local C_QuestLog_GetSelectedQuest = C_QuestLog.GetSelectedQuest

--This changes the growth direction of the toast frame depending on position of the mover
local function PostMove(mover)
	local x, y = mover:GetCenter()
	local top = E.UIParent:GetTop()
	local right = E.UIParent:GetRight()

	local point
	if y > (top*0.5) then
		point = (x > (right*0.5)) and 'TOPRIGHT' or 'TOPLEFT'
	else
		point = (x > (right*0.5)) and 'BOTTOMRIGHT' or 'BOTTOMLEFT'
	end
	mover.anchorPoint = point

	mover.parent:ClearAllPoints()
	mover.parent:Point(point, mover)
end

function B:RepositionFrame(frame, _, anchor)
	if anchor ~= frame.mover then
		frame:ClearAllPoints()
		frame:Point(frame.mover.anchorPoint or 'TOPLEFT', frame.mover, frame.mover.anchorPoint or 'TOPLEFT')
	end
end

function B:QuestXPPercent()
	if not E.db.general.questXPPercent then return end

	local unitXP, unitXPMax = UnitXP('player'), UnitXPMax('player')
	if _G.QuestInfoFrame.questLog then
		local selectedQuest = C_QuestLog_GetSelectedQuest()
		if C_QuestLog_ShouldShowQuestRewards(selectedQuest) then
			local xp = GetQuestLogRewardXP()
			if xp and xp > 0 then
				local text = _G.MapQuestInfoRewardsFrame.XPFrame.Name:GetText()
				if text then _G.MapQuestInfoRewardsFrame.XPFrame.Name:SetFormattedText('%s (|cff4beb2c+%.2f%%|r)', text, (((unitXP + xp) / unitXPMax) - (unitXP / unitXPMax))*100) end
			end
		end
	else
		local xp = GetRewardXP()
		if xp and xp > 0 then
			local text = _G.QuestInfoXPFrame.ValueText:GetText()
			if text then _G.QuestInfoXPFrame.ValueText:SetFormattedText('%s (|cff4beb2c+%.2f%%|r)', text, (((unitXP + xp) / unitXPMax) - (unitXP / unitXPMax))*100) end
		end
	end
end

function B:Initialize()
	B.Initialized = true

	B:HandleWidgets()

	if E.Retail then
		--Add (+X%) to quest rewards experience text
		B:SecureHook('QuestInfo_Display', 'QuestXPPercent')
	end
	
	-- Battle.Net Frame
	_G.BNToastFrame:Point('TOPRIGHT', _G.MMHolder or _G.Minimap, 'BOTTOMRIGHT', 0, -10)
	E:CreateMover(_G.BNToastFrame, 'BNETMover', L["BNet Frame"], nil, nil, PostMove)
	_G.BNToastFrame.mover:Size(_G.BNToastFrame:GetSize())
	B:SecureHook(_G.BNToastFrame, 'SetPoint', 'RepositionFrame')
end
E:RegisterModule(B:GetName())
