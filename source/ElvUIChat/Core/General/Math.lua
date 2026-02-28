local E, L, V, P, G = unpack(ElvUIChat)

local modf = math.modf
local select, type, format, strmatch = select, type, format, strmatch
local utf8sub, utf8len = string.utf8sub, string.utf8len

local C_Timer_After = C_Timer.After

-- Text Gradient by Simpy
function E:TextGradient(text, ...)
	local msg, total = '', utf8len(text)
	local idx, num = 0, select('#', ...) / 3

	for i = 1, total do
		local x = utf8sub(text, i, i)
		if strmatch(x, '%s') then
			msg = msg .. x
			idx = idx + 1
		else
			local segment, relperc = modf((idx/total)*num)
			local r1, g1, b1, r2, g2, b2 = select((segment*3)+1, ...)

			if not r2 then
				msg = msg .. E:RGBToHex(r1, g1, b1, nil, x..'|r')
			else
				msg = msg .. E:RGBToHex(r1+(r2-r1)*relperc, g1+(g2-g1)*relperc, b1+(b2-b1)*relperc, nil, x..'|r')
				idx = idx + 1
			end
		end
	end

	return msg
end

--RGB to Hex
function E:RGBToHex(r, g, b, header, ending)
	r = r <= 1 and r >= 0 and r or 1
	g = g <= 1 and g >= 0 and g or 1
	b = b <= 1 and b >= 0 and b or 1
	return format('%s%02x%02x%02x%s', header or '|cff', r*255, g*255, b*255, ending or '')
end

--From http://wow.gamepedia.com/UI_coordinates
function E:FramesOverlap(frameA, frameB)
	if not frameA or not frameB then return	end

	local sA, sB = frameA:GetEffectiveScale(), frameB:GetEffectiveScale()
	if not sA or not sB then return	end

	local frameALeft, frameARight, frameABottom, frameATop = frameA:GetLeft(), frameA:GetRight(), frameA:GetBottom(), frameA:GetTop()
	local frameBLeft, frameBRight, frameBBottom, frameBTop = frameB:GetLeft(), frameB:GetRight(), frameB:GetBottom(), frameB:GetTop()
	if not (frameALeft and frameARight and frameABottom and frameATop) then return end
	if not (frameBLeft and frameBRight and frameBBottom and frameBTop) then return end

	return ((frameALeft*sA) < (frameBRight*sB)) and ((frameBLeft*sB) < (frameARight*sA)) and ((frameABottom*sA) < (frameBTop*sB)) and ((frameBBottom*sB) < (frameATop*sA))
end

function E:GetScreenQuadrant(frame)
	local x, y = frame:GetCenter()
	if not (x and y) then
		return 'UNKNOWN', frame:GetName()
	end

	local point
	local width = E.screenWidth / 3
	local height = E.screenHeight / 3
	local dblWidth = width * 2
	local dblHeight = height * 2

	if x > width and x < dblWidth and y > dblHeight then
		point = 'TOP'
	elseif x < width and y > dblHeight then
		point = 'TOPLEFT'
	elseif x > dblWidth and y > dblHeight then
		point = 'TOPRIGHT'
	elseif x > width and x < dblWidth and y < height then
		point = 'BOTTOM'
	elseif x < width and y < height then
		point = 'BOTTOMLEFT'
	elseif x > dblWidth and y < height then
		point = 'BOTTOMRIGHT'
	elseif x < width and y > height and y < dblHeight then
		point = 'LEFT'
	elseif x > dblWidth and y < dblHeight and y > height then
		point = 'RIGHT'
	else
		point = 'CENTER'
	end

	return point
end

do
	local function CreateClosure(func, data)
		return function() func(unpack(data)) end
	end

	function E:Delay(delay, func, ...)
		if type(delay) ~= 'number' or type(func) ~= 'function' then return false end

		local args = {...}
		C_Timer_After(delay < 0.01 and 0.01 or delay, (#args <= 0 and func) or CreateClosure(func, args))

		return true
	end
end
