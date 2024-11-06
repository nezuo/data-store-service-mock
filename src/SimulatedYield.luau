--!strict

local SimulatedYield = {}
SimulatedYield.__index = SimulatedYield

export type SimulatedYield = typeof(setmetatable(
	{} :: {
		yielding: boolean,
		threads: { thread },
	},
	SimulatedYield
))

function SimulatedYield.new(): SimulatedYield
	return setmetatable({
		yielding = false,
		threads = {},
	}, SimulatedYield)
end

function SimulatedYield.yield(self: SimulatedYield)
	if not self.yielding then
		return
	end

	table.insert(self.threads, coroutine.running())

	coroutine.yield()
end

function SimulatedYield.startYield(self: SimulatedYield)
	self.yielding = true
end

function SimulatedYield.stopYield(self: SimulatedYield)
	self.yielding = false

	for _, thread in self.threads do
		task.spawn(thread)
	end

	table.clear(self.threads)
end

return SimulatedYield