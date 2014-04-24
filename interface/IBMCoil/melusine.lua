local mod = IBMMod("Coil", "Melusine")

local phases = mod:phases(1)

phases[1]:addEventHandler("LOG_ENTRY", function(text)
	if text:find("readies Petrifaction") then
		IBMAlert("Petrifaction - Look away!")
	end
end)

mod:startOnLogEntry("Bioweapon Storage will be sealed off in")
