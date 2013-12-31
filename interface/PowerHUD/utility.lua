math.randomseed(tonumber(tostring(os.time()):reverse():sub(1,6)))

PHUDUUID4 = function()
	local uuid = {[9] = "-", [14] = "-", [15] = "4", [19] = "-", [24] = "-"}
	local hex  = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"}
	for i = 1, 36 do
		if i == 20 then
			uuid[i] = hex[math.random(9, 12)]
		elseif uuid[i] == nil then
			uuid[i] = hex[math.random(16)]
		end
	end
	return table.concat(uuid)
end
