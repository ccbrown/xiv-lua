local recycledTimers = {}

IBMTimerStart = function(t, duration)
	t.startTime = SteadyTime()
	t.duration = duration
end

IBMTimerSetColor = function(t, r, g, b, a)
	t.fillView:setBackgroundColor(r, g, b, a)
end

IBMTimerSetIsApproximate = function(t, isApproximate)
	t.isApproximate = isApproximate
end

IBMTimerRecycle = function(t)
	t.window:hide()
	table.insert(recycledTimers, t)
end

IBMTimerUpdate = function(t)
	t.remainingTime = math.max(t.duration - (SteadyTime() - t.startTime), 0.0)

	t.fillView:setAnchor1(0.0, 0.0, 0.0, 0.0)
	t.fillView:setAnchor2(1.0, 1.0, t.remainingTime / t.duration, 1.0)

	if t.isApproximate then
		t.timeTextView:setText(string.format("~%.2f", t.remainingTime))
	else
		t.timeTextView:setText(string.format("%.2f", t.remainingTime))
	end

	t.window:show()
end

IBMTimer = function(label)
	local t = table.remove(recycledTimers)
	
	if not t then
		t = {}

		t.window = View(GameScreen)
		t.window:setBackgroundColor(0.0, 0.0, 0.0, 0.0)
		
		t.backgroundView = View(t.window)
		t.backgroundView:setAnchor1(0.0, 0.0, 0.0, 0.0)
		t.backgroundView:setAnchor2(1.0, 1.0, 1.0, 1.0)
		t.backgroundView:setBackgroundColor(0.0, 0.0, 0.0, 0.6)
		t.backgroundView:show()

		t.fillView = View(t.window)
		t.fillView:setAnchor1(0.0, 0.0, 0.0, 0.0)
		t.fillView:setAnchor2(1.0, 1.0, 1.0, 1.0)
		t.fillView:setBackgroundColor(0.0, 0.0, 0.0, 0.8)
		t.fillView:show()

		local padding = 6

		t.labelTextView = TextView(t.window)
		t.labelTextView:setAnchor1(0.0, 0.0, 0.0, 0.0, padding, 0)
		t.labelTextView:setAnchor2(1.0, 1.0, 1.0, 1.0, -padding, 0)
		t.labelTextView:setBackgroundColor(0.0, 0.0, 0.0, 0.0)
		t.labelTextView:setColor(1.0, 1.0, 1.0)
		t.labelTextView:setText("")
		t.labelTextView:show()

		t.timeTextView = TextView(t.window)
		t.timeTextView:setAnchor1(0.0, 0.0, 0.7, 0.0, padding, 0)
		t.timeTextView:setAnchor2(1.0, 1.0, 1.0, 1.0, -padding, 0)
		t.timeTextView:setBackgroundColor(0.0, 0.0, 0.0, 0.0)
		t.timeTextView:setColor(1.0, 1.0, 1.0)
		t.timeTextView:setHorizontalAlignment("right")
		t.timeTextView:setText("")
		t.timeTextView:show()
	end
	
	t.window:hide()
	t.start = IBMTimerStart
	t.setColor = IBMTimerSetColor
	t.setIsApproximate = IBMTimerSetIsApproximate
	t.recycle = IBMTimerRecycle
	t.update = IBMTimerUpdate
	t.labelTextView:setText(label)
	t.remainingTime = 0

	return t
end