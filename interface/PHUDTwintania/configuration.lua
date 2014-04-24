local divebombs = 0
local profusions = 0
local lastScourgeEntry = 0
local lastLiquidHell = 0
local lastDreadknightEntry = 0

-- TODO: port to IBM

PHUDElements()[PHUDUUID4()] = {
	type = "timer",
	triggerEvents = {
		LOG_ENTRY = function(text)
			if text:find("scourge of Meracydia") then
				local now = SteadyTime()
				if now - lastScourgeEntry > 10 then
					-- fight's starting
					divebombs = 0
					profusions = 0
				end
				lastScourgeEntry = now
			end
			
			if text:find("Twintania readies Divebomb") then
				divebombs = divebombs + 1
				if divebombs < 6 then
					return {label = "Divebomb", duration = (divebombs == 3 and 49 or 7), color = {0.0, 0.4, 0.0, 0.6}}
				elseif divebombs == 6 then
					return {label = "Aetheric Profusion", duration = 70, color = {0.2, 0.2, 1.0, 0.6}}
				end
			elseif text:find("Twintania readies Death Sentence") then
				return {label = "Death Sentence CD", duration = 35, color = {0.7, 0.0, 0.3, 0.6}}
			elseif text:find("Twintania readies Twister") then
				PlaySound("interface/PowerHUD/aruba.wav")
				return {label = "Twister CD", duration = 20, color = {0.0, 0.4, 0.0, 0.6}}
			elseif text:find("dreadknight") then
				local now = SteadyTime()
				local trigger = now - lastDreadknightEntry > 10
				lastDreadknightEntry = now
				if trigger then
					return {label = "Dreadknight", duration = 35, color = {0.6, 0.0, 0.0, 0.6}}
				end
			elseif text:find("Twintania uses Liquid Hell") then
				local now = SteadyTime()
				local trigger = now - lastLiquidHell > 5
				lastLiquidHell = now
				if trigger then
					return {label = "Liquid Hell Barrage", duration = 17, color = {0.8, 0.3, 0.0, 0.6}}
				end
			end

			return nil
		end
	},
	group = "sharedTimers",
	width = 200,
	height = 30
}
