local alert = {}

IBMAlert = function(text)
	if not alert.window then
		alert.window = View(GameScreen)
		alert.window:setAnchor1(0.0, 0.0, 0.0, 0.25, 0.0, -100.0)
		alert.window:setAnchor2(1.0, 1.0, 1.0, 0.25, 0.0,  100.0)
		alert.window:setBackgroundColor(0.0, 0.0, 0.0, 0.5)

		alert.shadowViews = {}

		for x = -1, 1, 2 do
			for y = -1, 1, 2 do
				local shadowView = TextView(alert.window)
				shadowView:setAnchor1(0.0, 0.0, 0.0, 0.0, x * 3.0, y * 3.0)
				shadowView:setAnchor2(1.0, 1.0, 1.0, 1.0, x * 3.0, y * 3.0)
				shadowView:setColor(0.0, 0.0, 0.0, 1.0)
				shadowView:setBackgroundColor(0.0, 0.0, 0.0, 0.0)
				shadowView:setHorizontalAlignment("center")
				shadowView:setFont("Arial", 30)
				shadowView:show()
				table.insert(alert.shadowViews, shadowView)
			end
		end

		alert.textView = TextView(alert.window)
		alert.textView:setAnchor1(0.0, 0.0, 0.0, 0.0)
		alert.textView:setAnchor2(1.0, 1.0, 1.0, 1.0)
		alert.textView:setColor(1.0, 0.5, 0.0, 1.0)
		alert.textView:setBackgroundColor(0.0, 0.0, 0.0, 0.0)
		alert.textView:setHorizontalAlignment("center")
		alert.textView:setFont("Arial", 30)
		alert.textView:show()
	end
	
	alert.proxy = {}
	alert.proxy.time = SteadyTime()
	alert.proxy.text = text

	PlaySound("interface/IchibanBossMods/sounds/se.10.wav")
	IBMAlertUpdate()

	return alert.proxy
end

IBMAlertUpdate = function()
	if alert.window then
		if alert.proxy then
			local elapsed = SteadyTime() - alert.proxy.time
			if elapsed > 5 then
				alert.proxy = nil
				alert.window:hide()
			else
				if alert.text ~= alert.proxy.text then
					alert.text = alert.proxy.text
					alert.textView:setText(alert.text)
					for i, v in ipairs(alert.shadowViews) do
						v:setText(alert.text)
					end
				end
				alert.window:setOpacity(math.min(1.0, 1.0 - (elapsed - 4.0) / 1.0))
				alert.window:show()
			end
		else
			alert.window:hide()
		end
	end
end
