local timerListPosition = {340, -200}

IBMModPhaseAddTimer = function(p, ...)
	local v = {
		label = select(1, ...),
		duration = select(2, ...),
		instance = nil
	}
	
	if select('#', ...) >= 3 then
		v.color = select(3, ...)
	else
		v.color = {0.0, 0.0, 0.5, 0.8}
	end
	
	if select('#', ...) >= 4 then
		local params = select(4, ...)
		if params then
			v.isApproximate = params.isApproximate
		end
	end

	if p.isActive then
		local t = IBMTimer(v.label)
		t:setColor(v.color[1], v.color[2], v.color[3], v.color[4])
		t:setIsApproximate(v.isApproximate)
		t:start(v.duration)
		p.activeTimers[t] = true
		v.instance = t
		table.insert(p.mod.activeTimers, t)
	else
		table.insert(p.staticTimers, v)
	end

	return v
end

IBMModPhaseAddEventHandler = function(p, e, h)
	p.eventHandlers[e] = h
end

IBMModPhaseSchedule = function(p, ...)
	local sf = {
		delay = select(1, ...),
		func = select(2, ...),
		instance = nil
	}
	
	if p.isActive then
		local i = {
			invocationTime = SteadyTime() + sf.delay, 
			func = sf.func
		}
		sf.instance = i
		table.insert(p.scheduledFunctions, i)
	else
		table.insert(p.staticFunctions, sf)
	end
	
	return sf
end

IBMModPhaseAddEvent = function(p, t, name, color, params)
	p:schedule(math.max(0, t - 30), function()
		p:addTimer(name, t - math.max(0, t - 30), color, params)
	end)
end

IBMModPhases = function(m, count)
	local phases = {}
	for i = 1, count do
		local phase = {
			mod = m,
			staticTimers = {},
			addTimer = IBMModPhaseAddTimer,
			staticFunctions = {},
			schedule = IBMModPhaseSchedule,
			activeTimers = {},
			addEvent = IBMModPhaseAddEvent,
			addEventHandler = IBMModPhaseAddEventHandler,
			eventHandlers = {},
			isActive = false
		}
		table.insert(phases, phase)
	end
	m.phases = phases
	m.startingPhase = phases[1]
	return phases
end

IBMModSetStartingPhase = function(m, phase)
	m.startingPhase = phase
end

IBMModStartOnLogEntry = function(m, entry)
	m.startLogEntry = entry
end

IBMModShouldActivateOnLogEntry = function(m, text)
	return (m.startLogEntry and text:find(m.startLogEntry)) or (m.sealName and text:find("The "..m.sealName.." will be sealed off"))
end

IBMModEndPhase = function(m)
	if not m.currentPhase then
		return
	end

	local p = m.currentPhase
	
	local i = 0
	while i <= #m.activeTimers do
		local t = m.activeTimers[i]
		if p.activeTimers[t] then
			table.remove(m.activeTimers, i)
			t:recycle()
		else
			i = i + 1
		end
	end

	p.activeTimers = {}
	p.scheduledFunctions = {}
	p.isActive = false
end

IBMModBeginPhase = function(m, p)
	m:endPhase()
	m.currentPhase = p
	m.currentPhase.isActive = true
	
	for i, v in ipairs(p.staticTimers) do
		local t = IBMTimer(v.label)
		t:setColor(v.color[1], v.color[2], v.color[3], v.color[4])
		t:setIsApproximate(v.isApproximate)
		t:start(v.duration)
		p.activeTimers[t] = true
		v.instance = t
		table.insert(m.activeTimers, t)
	end
	
	p.scheduledFunctions = {}
	for i, v in ipairs(p.staticFunctions) do
		local i = {
			invocationTime = SteadyTime() + v.delay, 
			func = v.func
		}
		v.instance = i
		table.insert(p.scheduledFunctions, i)
	end
end

local mods = {}

IBMMod = function(groupName, name)
	local m = {
		groupName = groupName,
		name = name,
		phases = IBMModPhases,
		setStartingPhase = IBMModSetStartingPhase,
		startOnLogEntry = IBMModStartOnLogEntry,
		beginPhase = IBMModBeginPhase,
		endPhase = IBMModEndPhase,
		shouldActivateOnLogEntry = IBMModShouldActivateOnLogEntry,
		activeTimers = {}
	}
	table.insert(mods, m)
	return m
end

local activeMod = nil
local lastModDeactivation = 0

IBMActivateMod = function(m)
	IBMDeactivateMod()
	print("activating "..m.name)
	activeMod = m
	m:beginPhase(m.startingPhase)
end

IBMDeactivateMod = function()
	if not activeMod then
		return
	end

	local m = activeMod
	print("deactivating "..m.name)
	m:endPhase()
	for i, t in ipairs(m.activeTimers) do
		t:recycle()
	end
	m.activeTimers = {}
	activeMod = nil
	lastModDeactivation = SteadyTime()
end

IBMProcessEvent = function(event, arg1)
	IBMAlertUpdate()

	local now = SteadyTime()
	local newlyActivated = false
	
	if not activeMod then
		if now - lastModDeactivation > 4.0 and event == "LOG_ENTRY" then
			for i, m in ipairs(mods) do
				if m:shouldActivateOnLogEntry(arg1) then
					IBMActivateMod(m)
					newlyActivated = true
					break
				end
			end
		end
		if not activeMod then
			return
		end
	end
	
	local m = activeMod
	local p = m.currentPhase
	
	if event == "LOG_ENTRY" then
		if arg1:find("no longer sealed") then
			IBMDeactivateMod()
			return
		end
	elseif event == "LEFT_COMBAT" then
		IBMDeactivateMod()
		return
	end

	local handler = p.eventHandlers[event]
	
	if handler ~= nil then
		handler(arg1)
	end
	
	local i = 1
	while i <= #p.scheduledFunctions do
		if now >= p.scheduledFunctions[i].invocationTime then
			p.scheduledFunctions[i].func()
			table.remove(p.scheduledFunctions, i)
		else
			i = i + 1
		end
	end

	local i = 1
	while i <= #m.activeTimers do
		local t = m.activeTimers[i]
		t:update()
		if now >= t.startTime + t.duration then
			t:recycle()
			table.remove(m.activeTimers, i)
			p.activeTimers[t] = nil
		else
			i = i + 1
		end
	end

	local sorted = {}
	
	for i, v in pairs(m.activeTimers) do
		table.insert(sorted, {i, v})
	end
	
	table.sort(sorted, function(a, b)
		if math.abs(a[2].remainingTime - b[2].remainingTime) < 0.1 then
			return a[1] < b[1]
		end
		return a[2].remainingTime < b[2].remainingTime
	end)
	
	local y = timerListPosition[2]
	for i, v in ipairs(sorted) do
		v[2].window:setAnchor1(0.0, 0.0, 0.5, 0.5, -100 + timerListPosition[1], -15 + y)
		v[2].window:setAnchor2(1.0, 1.0, 0.5, 0.5, 100 + timerListPosition[1], 15 + y)
		y = y + 34
	end
end

RegisterEventCallback(IBMProcessEvent)