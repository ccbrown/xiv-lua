PHUDElements()[PHUDUUID4()] = {
	type = "text",
	triggerEvents = {
		ANIMATION_FRAME = function()
			return { horizontalAlignment = "center" }
		end
	},
	textFunction = function(instance)
		local chp, mhp, cmp, mmp, ctp = UnitVitals("target")
		return mhp > 0 and string.format("%d / %d (%.2f%%)", chp, mhp, chp / mhp * 100) or ""
	end,
	maxInstances = 1,
	screen = GameScreen,
	anchor1 = {0.0, 0.0, 0.5, 0.0, -100, 50},
	anchor2 = {1.0, 1.0, 0.5, 0.0, 100, 70}
}

PHUDElements()[PHUDUUID4()] = {
	type = "text",
	triggerEvents = {
		ANIMATION_FRAME = function()
			return true
		end
	},
	textFunction = function(instance)
		local chp, mhp, cmp, mmp, ctp = UnitVitals("focus")
		return mhp > 0 and string.format("%d / %d (%.2f%%)", chp, mhp, chp / mhp * 100) or ""
	end,
	maxInstances = 1,
	screen = GameScreen,
	anchor1 = {0.0, 0.0, 0.0, 0.0, 570, 180},
	anchor2 = {1.0, 1.0, 0.0, 0.0, 770, 200}
}
