local mod = IBMMod("Coil", "The Avatar")

local phases = mod:phases(1)

phases[1]:addTimer("Enrage", 11 * 60, {0.7, 0.0, 0.0, 0.3})

local towerTimer1 = nil
local towerTimer2 = nil
local towerTimer3 = nil

local towerSets = 0

local addTowerSet = function(towers, isThree)
	phases[1]:schedule(towerSets * 80, function()
		phases[1]:addTimer("Towers - " .. towers, 15, {0.0, 0.7, 0.0, 0.3})
	end)
	if isThree then
		phases[1]:schedule(15 + towerSets * 80, function()
			towerTimer1 = phases[1]:addTimer("Tower Effect", 60, {0.0, 0.7, 0.0, 0.3})
			towerTimer2 = phases[1]:addTimer("Tower Effect", 60, {0.0, 0.7, 0.0, 0.3})
			towerTimer3 = phases[1]:addTimer("Tower Effect", 60, {0.0, 0.7, 0.0, 0.3})
		end)
	else
		phases[1]:schedule(15 + towerSets * 80, function()
			towerTimer1 = phases[1]:addTimer("Tower Effect", 60, {0.0, 0.7, 0.0, 0.3})
			towerTimer2 = phases[1]:addTimer("Tower Effect", 60, {0.0, 0.7, 0.0, 0.3})
			towerTimer3 = nil
		end)
	end
	towerSets = towerSets + 1
end

addTowerSet("Dread / Damage", false)
addTowerSet("Mines / Damage", false)
addTowerSet("Dread / Damage", false)
addTowerSet("Mines / Damage", false)
addTowerSet("Dread / Mines", false)
addTowerSet("Mines / 2 x Damage", true)
-- TODO: detect tower effect activation so we can accurately predict these
--addTowerSet("Dread / Mines / Damage", true)
--addTowerSet("Mines / 2 x Damage", true)

phases[1]:addEventHandler("LOG_ENTRY", function(text)
	if text:find("suffer the effect of Languishing") or text:find("suffers the effect of Languishing") then
		if towerTimer1 and towerTimer1.instance and towerTimer1.instance.duration == 60 then
			towerTimer1.instance.duration = towerTimer1.instance.duration - 15
		elseif towerTimer2 and towerTimer2.instance then
			towerTimer2.instance.duration = towerTimer2.instance.duration - 15
		end
	elseif text:find("The Avatar readies Brainjack") then
		IBMAlert("Brainjack casting!")
		phases[1]:addTimer("Brainjack Over", 13, {0.9, 0.45, 0.0, 0.3})
	elseif text:find("The Avatar readies Allagan Field") then
		IBMAlert("Allagan Field casting!")
		phases[1]:addTimer("Allagan Field Over", 33, {0.7, 0.8, 0.0, 0.3})
	elseif text:find("The Avatar uses Diffusion Ray") then
		phases[1]:addTimer("Diffusion Ray", 14.6, {0.45, 0.45, 0.9, 0.3})
	end
end)

mod:startOnLogEntry("The central bow will be sealed off in")
