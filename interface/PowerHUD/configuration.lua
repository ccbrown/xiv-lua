local textElementType = {
	initializeFunction = function(instance, parameters)
		instance.parameters = parameters
		
		instance.creationTime = SteadyTime()

		instance.window:setBackgroundColor(0.0, 0.0, 0.0, 0.0)

		if not instance.textView then
			instance.textView = TextView(instance.window)
		end

		instance.textView:setAnchor1(0.0, 0.0, 0.0, 0.0)
		instance.textView:setAnchor2(1.0, 1.0, 1.0, 1.0)
		instance.textView:setBackgroundColor(0.0, 0.0, 0.0, 0.0)
		instance.textView:setColor(1.0, 1.0, 1.0, 1.0)
		
		if parameters.horizontalAlignment then
			instance.textView:setHorizontalAlignment(parameters.horizontalAlignment)
		end
		
		instance.textView:show()
	end,
	updateEvents = {
		ANIMATION_FRAME = true
	},
	updateFunction = function(instance)
		instance.textView:setText(instance.element.textFunction(instance))
	end
}

local timerElementType = {
	initializeFunction = function(instance, parameters)
		instance.parameters = parameters
		
		instance.creationTime = SteadyTime()

		instance.window:setBackgroundColor(0.0, 0.0, 0.0, 0.3)

		if not instance.fillView then
			instance.fillView = View(instance.window)
		end
		
		instance.fillView:setAnchor1(0.0, 0.0, 0.0, 0.0)
		instance.fillView:setAnchor2(1.0, 1.0, 1.0, 1.0)
		
		if parameters.color then
			instance.fillView:setBackgroundColor(unpack(parameters.color))
		else
			instance.fillView:setBackgroundColor(0.0, 0.0, 0.5, 0.8)
		end

		instance.fillView:show()

		if not instance.labelTextView then
			instance.labelTextView = TextView(instance.window)
		end

		local padding = 6
		
		instance.labelTextView:setAnchor1(0.0, 0.0, 0.0, 0.0, padding, 0)
		instance.labelTextView:setAnchor2(1.0, 1.0, 1.0, 1.0, -padding, 0)
		instance.labelTextView:setBackgroundColor(0.0, 0.0, 0.0, 0.0)
		instance.labelTextView:setColor(1.0, 1.0, 1.0)
		instance.labelTextView:setText(parameters.label)
		instance.labelTextView:show()

		if not instance.timeTextView then
			instance.timeTextView = TextView(instance.window)
		end

		instance.timeTextView:setAnchor1(0.0, 0.0, 0.7, 0.0, padding, 0)
		instance.timeTextView:setAnchor2(1.0, 1.0, 1.0, 1.0, -padding, 0)
		instance.timeTextView:setBackgroundColor(0.0, 0.0, 0.0, 0.0)
		instance.timeTextView:setColor(1.0, 1.0, 1.0)
		instance.timeTextView:setHorizontalAlignment("right")
		instance.timeTextView:setText("")
		instance.timeTextView:show()
	end,
	updateEvents = {
		ANIMATION_FRAME = true
	},
	updateFunction = function(instance)
		instance.remainingTime = math.max(instance.parameters.duration - (SteadyTime() - instance.creationTime), 0.0)

		if instance.remainingTime <= 0.0 then
			return PHUDRecycleInstance(instance)
		end

		instance.fillView:setAnchor1(0.0, 0.0, 0.0, 0.0)
		instance.fillView:setAnchor2(1.0, 1.0, instance.remainingTime / instance.parameters.duration, 1.0)

		instance.timeTextView:setText(string.format("%.2f", instance.remainingTime))
	end
}

local elementTypes = {
	text = textElementType,
	timer = timerElementType
}

PHUDElementTypes = function()
	return elementTypes
end

local sharedTimersGroup = {
	screen = GameScreen,
	anchor1 = {0.0, 0.0, 0.65, 0.3},
	anchor2 = {1.0, 1.0, 0.85, 0.7},
	spacing = 4,
	sortFunction = function(a, b)
		return a.remainingTime < b.remainingTime
	end
}

local groups = {
	sharedTimers = sharedTimersGroup
}

PHUDGroups = function()
	return groups
end

local elements = {}

PHUDElements = function()
	return elements
end
