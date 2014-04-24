local mod = IBMMod("Coil", "Nael deus Darnus")

local phases = mod:phases(4)

-- BEGIN PHASE 1

phases[1]:addEvent(19, "Stardust", {0.7, 0.0, 0.0, 0.3})
phases[1]:addEvent(28, "Ravensbeak", {0.7, 0.2, 0.6, 0.3})
phases[1]:addEvent(37, "Dive + Thermionic Beam", {0.8, 0.0, 0.2, 0.3})
phases[1]:addEvent(57, "Stardust", {0.6, 0.6, 0.0, 0.3})
phases[1]:schedule(08 + 60 - 5, function()
	IBMAlert("Lunar Dynamo Soon!")
end)
phases[1]:addEvent(08 + 60, "Lunar Dynamo + Stream", {0.6, 0.0, 0.6, 0.3})
phases[1]:addEvent(22 + 60, "Ravensbeak", {0.7, 0.2, 0.6, 0.3})

phases[1]:addEvent(34 + 60, "Stardust", {0.7, 0.0, 0.0, 0.3})
phases[1]:addEvent(46 + 60, "Double Meteor Stream", {0.7, 0.4, 0.7, 0.3})
phases[1]:addEvent(08 + 60 * 2, "Ravensbeak", {0.7, 0.2, 0.6, 0.3})
phases[1]:addEvent(15 + 60 * 2, "Stardust", {0.6, 0.6, 0.0, 0.3})
phases[1]:addEvent(28 + 60 * 2, "Dive + Thermionic Beam", {0.8, 0.0, 0.2, 0.3})

phases[1]:addEvent(49 + 60 * 2, "Stardust", {0.7, 0.0, 0.0, 0.3})
phases[1]:addEvent(57 + 60 * 2, "Ravensbeak", {0.7, 0.2, 0.6, 0.3})
phases[1]:schedule(03 + 60 * 3 - 5, function()
	IBMAlert("Lunar Dynamo Soon!")
end)
phases[1]:addEvent(03 + 60 * 3, "Lunar Dynamo + Stream", {0.6, 0.0, 0.6, 0.3})
phases[1]:addEvent(25 + 60 * 3, "Stardust", {0.6, 0.6, 0.0, 0.3})
phases[1]:addEvent(35 + 60 * 3, "Double Meteor Stream", {0.7, 0.4, 0.7, 0.3})
phases[1]:addEvent(55 + 60 * 3, "Ravensbeak", {0.7, 0.2, 0.6, 0.3})

phases[1]:addEvent(06 + 60 * 4, "Stardust", {0.7, 0.0, 0.0, 0.3})
phases[1]:addEvent(19 + 60 * 4, "Dive + Thermionic Beam", {0.8, 0.0, 0.2, 0.3})
phases[1]:addEvent(38 + 60 * 4, "Ravensbeak", {0.7, 0.2, 0.6, 0.3})
phases[1]:addEvent(44 + 60 * 4, "Stardust", {0.6, 0.6, 0.0, 0.3})
phases[1]:schedule(55 + 60 * 4 - 5, function()
	IBMAlert("Lunar Dynamo Soon!")
end)
phases[1]:addEvent(55 + 60 * 4, "Lunar Dynamo + Stream", {0.6, 0.0, 0.6, 0.3})

phases[1]:addEvent(16 + 60 * 5, "Stardust", {0.7, 0.0, 0.0, 0.3})
phases[1]:addEvent(24 + 60 * 5, "Ravensbeak", {0.7, 0.2, 0.6, 0.3})

phases[1]:addEvent(30 + 60 * 5, "Debris Burst (Death)", {0.7, 0.5, 0.0, 0.3})

phases[1]:addEventHandler("LOG_ENTRY", function(text)
	if text:find("Dalamud spawn") then
		mod:beginPhase(phases[2])
	elseif text:find("suffer the effect of Raven Blight") or text:find("suffers the effect of Raven Blight") then
		phases[1]:addTimer("Raven Blight", 12, {0.7, 0.2, 0.6, 0.3})
	end
end)

-- BEGIN PHASE 2 (DALAMUD SPAWNS)

phases[2]:addTimer("Stardust x 6", 62, {0.7, 0.0, 0.0, 0.3}, { isApproximate = true })
phases[2]:addTimer("Megaflare", 165, {0.7, 0.7, 0.0, 0.3}, { isApproximate = true })

phases[2]:addEventHandler("LOG_ENTRY", function(text)
	if text:find("Nael deus Darnus uses Megaflare") then
		mod:beginPhase(phases[3])
	end
end)

-- BEGIN PHASE 3 (GHOSTS)

phases[3]:addEvent(31, "Ghost of Meracydia", {0.7, 0.4, 0.0, 0.3})
phases[3]:addEvent(40, "Deadly Drive", {0.7, 0.0, 0.0, 0.3})
phases[3]:addEvent(31 + 60, "Ghost of Meracydia", {0.7, 0.4, 0.0, 0.3})
phases[3]:addEvent(40 + 60, "Deadly Drive", {0.7, 0.0, 0.0, 0.3})
phases[3]:addEvent(31 + 60 * 2, "Ghost of Meracydia", {0.7, 0.4, 0.0, 0.3})
phases[3]:addEvent(40 + 60 * 2, "Deadly Drive", {0.7, 0.0, 0.0, 0.3})

phases[3]:addEvent(10, "Heavensfall", {0.7, 0.7, 0.0, 0.3})

local addCoilCoilFallNova = function(t)
	phases[3]:addEvent(t +  0, "Binding Coil", {0.7, 0.2, 0.6, 0.3})
	phases[3]:addEvent(t + 23, "Binding Coil", {0.7, 0.2, 0.6, 0.3})
	phases[3]:addEvent(t + 24, "Heavensfall", {0.7, 0.7, 0.0, 0.3})
	phases[3]:addEvent(t + 35, "Super Nova", {0.2, 0.2, 0.2, 0.3})
end

addCoilCoilFallNova(37)
addCoilCoilFallNova(37 + 55)
addCoilCoilFallNova(37 + 55 * 2)
addCoilCoilFallNova(37 + 55 * 3)

phases[3]:addEventHandler("LOG_ENTRY", function(text)
	if text:find("Nael deus Darnus readies Heavensfall") then
		IBMAlert("Heavensfall casting!")
	elseif text:find("You suffer the effect of Garrote Twist") then
		IBMAlert("Garrote Twist on YOU!")
	elseif text:find("Nael deus Darnus readies Bahamut's Favor") then
		mod:beginPhase(phases[4])
	end
end)

-- BEGIN PHASE 4 (BAHAMUT'S FAVOR)

local addFavorRotation = function(i)
	local start = 97 * i

	phases[4]:addEvent(start + 19 + 12 * 0, "Fireball (1)", {0.8, 0.4, 0.2, 0.3})
	phases[4]:addEvent(start + 19 + 12 * 1, "Fireball (2)", {0.8, 0.4, 0.2, 0.3})
	phases[4]:addEvent(start + 19 + 12 * 2, "Fireball (3)", {0.8, 0.4, 0.2, 0.3})
	phases[4]:addEvent(start + 19 + 12 * 3, "Fireball (4)", {0.8, 0.4, 0.2, 0.3})

	phases[4]:schedule(start + 16, function()
		IBMAlert("Lunar Dynamo Soon!")
	end)
	phases[4]:addEvent(start + 19, "Dive + Lunar Dynamo", {0.6, 0.0, 0.6, 0.3}, { isApproximate = true })
	phases[4]:addEvent(start + 41, "Chariot + Novas + Beam", {0.8, 0.0, 0.2, 0.3}, { isApproximate = true })
	phases[4]:addEvent(start + 64, "Cauterize", {0.2, 0.2, 0.8, 0.3}, { isApproximate = true })
	if i % 2 == 0 then
		phases[4]:addEvent(start + 69, "Meteor Stream", {0.7, 0.4, 0.7, 0.3}, { isApproximate = true })
	else
		phases[4]:addEvent(start + 68, "Iron Chariot", {0.7, 0.7, 0.0, 0.3}, { isApproximate = true })
		phases[4]:schedule(start + 70, function()
			IBMAlert("Lunar Dynamo Soon!")
		end)
		phases[4]:addEvent(start + 75, "Dive + Lunar Dynamo", {0.6, 0.0, 0.6, 0.3}, { isApproximate = true })
	end
	phases[4]:addEvent(start + 70, "Cauterize", {0.2, 0.2, 0.8, 0.3}, { isApproximate = true })
	phases[4]:addEvent(start + 97, "Bahamut's Favor", {0.7, 0.7, 0.0, 0.3}, { isApproximate = true })
end

addFavorRotation(0)
addFavorRotation(1)
addFavorRotation(2)
addFavorRotation(3)

phases[4]:addEventHandler("LOG_ENTRY", function(text)
	if text:find("You suffer the effect of Thunderstruck") then
		IBMAlert("Thunderstruck on YOU!")
		phases[4]:addTimer("Thunderstruck on YOU", 5, {0.7, 0.1, 0.4, 0.3})
	elseif text:find("suffers the effect of Thunderstruck") then
		phases[4]:addTimer("Thunderstruck on "..text:match("(%a+) %a+ suffers"), 5, {0.7, 0.1, 0.4, 0.3})
	end
end)

mod:startOnLogEntry("Nael deus Darnus")
