local targetName = null
local lastSearch = 0

local window = View(GameScreen)
window:setBackgroundColor(0.0, 0.0, 0.0, 0.0)
window:setAnchor1(0.0, 0.0, 0.0, 0.0, 20.0, 20.0)
window:setAnchor2(1.0, 1.0, 0.0, 0.0, 400.0, 40.0)
window:hide()

local textView = TextView(window)
textView:setBackgroundColor(0.0, 0.0, 0.0, 0.5)
textView:setColor(1.0, 1.0, 1.0)
textView:setAnchor1(0.0, 0.0, 0.0, 0.0)
textView:setAnchor2(1.0, 1.0, 1.0, 1.0)
textView:show()

local eventHandler = function(event, arg1)
	if event == "LOG_ENTRY" and arg1:sub(9, 12) == "0038" then
		local target = arg1:match("!track (%a+ %a+)")
		if target then
			targetName = target
			window:show()
		elseif arg1:find("!track") then
			targetName = null
			window:hide()
		else
			return
		end
	end
	
	if not targetName then
		return
	end

	local now = SteadyTime()
	
	if now - lastSearch > 0.5 then
		if SearchEntities(targetName) > 0 then
			local x, y, z = UnitPosition("player")
			local tx, ty, tz = UnitPosition("search")
			textView:setText(string.format(" %s located at %.1f, %.1f, %.1f (%+.1f, %+.1f, %+.1f).", targetName, tx, ty, tz, tx - x, ty - y, tz - z))
		else
			textView:setText(" "..targetName.." not found.")
		end
	end
end

RegisterEventCallback(eventHandler)