local function all(tasks: { () -> () })
	local thread = coroutine.running()
	local tasksRemaining = #tasks
	local yielded = false

	for _, subTask in tasks do
		task.spawn(function()
			subTask()
			tasksRemaining -= 1

			if tasksRemaining == 0 and yielded then
				task.spawn(thread)
			end
		end)
	end

	if tasksRemaining > 0 then
		yielded = true
		coroutine.yield()
	end
end

local SimulatedYield = {}
SimulatedYield.__index = SimulatedYield

function SimulatedYield.new()
	return setmetatable({
		yielding = false,
		threads = {},
		yieldDuration = 0,
	}, SimulatedYield)
end

function SimulatedYield:setYieldDuration(duration: number)
	self.yieldDuration = duration
end

function SimulatedYield:yield()
	all({
		function()
			if self.yieldDuration > 0 then
				task.wait(self.yieldDuration)
			end
		end,
		function()
			if self.yielding then
				table.insert(self.threads, coroutine.running())

				coroutine.yield()
			end
		end,
	})
end

function SimulatedYield:startYield()
	self.yielding = true
end

function SimulatedYield:stopYield()
	self.yielding = false

	for _, thread in self.threads do
		task.spawn(thread)
	end

	table.clear(self.threads)
end

return SimulatedYield
