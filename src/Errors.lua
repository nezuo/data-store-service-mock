local simulateYield = require(script.Parent.simulateYield)

local errorChance = 0
local errorCounter = 0
local random = Random.new()

local function getError(methodName)
	return string.format("%s rejected with error (simulated error)", methodName)
end

local Errors = {}

function Errors.setErrorChance(chance)
	errorChance = chance
end

function Errors.setErrorCounter(count)
	errorCounter = count
end

function Errors.trySimulateErrorAndYield(methodName)
	if errorCounter > 0 then
		errorCounter -= 1

		simulateYield()
		error(getError(methodName)) -- todo scope
	end

	if errorChance > 0 and random:NextNumber() < errorChance then
		simulateYield()
		error(getError(methodName)) -- todo scope
	end
end

return Errors
