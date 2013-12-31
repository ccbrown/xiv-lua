local activeInstances = {}
local activeCounts = {}
local recycledInstances = {}

PHUDProcessEvent = function(event, ...)
	for instance, value in pairs(activeInstances) do
		if instance.type.updateEvents[event] then
			instance.window:show()
			instance.type.updateFunction(instance)
		end
	end

	for id, element in pairs(PHUDElements()) do
		elementType = PHUDElementTypes()[element.type]

		if not activeCounts[element] then
			activeCounts[element] = 0
		end

		if elementType and (not element.maxInstances or activeCounts[element] < element.maxInstances) and element.triggerEvents[event] then
			local parameters = element.triggerEvents[event](...)

			if parameters then
				local instance = table.remove(recycledInstances)
		
				local group = nil
				if element.group and PHUDGroups()[element.group] then
					group = PHUDGroups()[element.group]
					if not group.instances then
						PHUDUpdateGroup(group)
					end
				end
		
				if not instance then
					local parent = group and group.window or element.screen
					instance = { type = elementType, element = element, group = group, window = View(parent) }	
				end
		
				instance.window:setBackgroundColor(0.0, 0.0, 0.0, 0.0)
				instance.window:setClickable(false)
		
				elementType.initializeFunction(instance, type(parameters) == "table" and parameters or {})
				activeInstances[instance] = true
				activeCounts[element] = activeCounts[element] + 1

				elementType.updateFunction(instance)
				
				if activeInstances[instance] then
					if group then
						group.instances[instance] = true
						PHUDUpdateGroup(group)
					else
						instance.window:setAnchor1(unpack(element.anchor1))
						instance.window:setAnchor2(unpack(element.anchor2))
						instance.window:show()
					end
				end
			end
		end
	end	
end

PHUDRecycleInstance = function(instance)
	instance.window:hide()
	activeInstances[instance] = nil
	activeCounts[instance.element] = activeCounts[instance.element] - 1
	
	if instance.group then
		instance.group.instances[instance] = nil
		PHUDUpdateGroup(instance.group)
	end
	
	if not recycledInstances[instance.type] then
		recycledInstances[instance.type] = {}
	end
	
	table.insert(recycledInstances[instance.type], instance)
end

PHUDUpdateGroup = function(group)
	if not group.window then
		group.window = View(group.screen)
	end
	
	if not group.instances then
		group.instances = {}
	end
	
	group.window:setAnchor1(unpack(group.anchor1))
	group.window:setAnchor2(unpack(group.anchor2))
	group.window:setBackgroundColor(0.0, 0.0, 0.0, 0.0)
	group.window:setClickable(false)
	group.window:show()

	local display = {}
	
	for instance, value in pairs(group.instances) do
		table.insert(display, instance)
	end
	
	if group.sortFunction then
		table.sort(display, group.sortFunction)
	end
	
	local yOffset = 0

	for index, instance in ipairs(display) do
		instance.window:setAnchor1(0.0, 0.0, 0.0, 0.0, 0, yOffset)
		instance.window:setAnchor2(1.0, 1.0, 0.0, 0.0, instance.element.width, yOffset + instance.element.height)
		instance.window:show()

		yOffset = yOffset + instance.element.height + group.spacing
	end
end

PHUDUpdateGroups = function()
	for id, group in pairs(PHUDGroups()) do
		PHUDUpdateGroup(group)
	end
end

RegisterEventCallback(PHUDProcessEvent)
