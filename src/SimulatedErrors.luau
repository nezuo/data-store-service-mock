--!strict

local SimulatedErrors = {}
SimulatedErrors.__index = SimulatedErrors

export type SimulatedErrors = typeof(setmetatable(
	{} :: {
		errorsToSimulate: number,
	},
	SimulatedErrors
))

function SimulatedErrors.new(): SimulatedErrors
	return setmetatable({
		errorsToSimulate = 0,
	}, SimulatedErrors)
end

function SimulatedErrors.addSimulatedErrors(self: SimulatedErrors, amount: number)
	assert(typeof(amount) == "number", "`amount` must be a number")

	self.errorsToSimulate += amount
end

function SimulatedErrors.simulateError(self: SimulatedErrors, method: string)
	if self.errorsToSimulate > 0 then
		self.errorsToSimulate -= 1

		error(string.format("`%s` rejected with error (simulated error)", method))
	end
end

return SimulatedErrors