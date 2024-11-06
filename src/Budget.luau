--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Constants = require(script.Parent.Constants)

local function defaultBudget()
	local budgets = {}
	local queues = {}

	for requestType, options in Constants.REQUEST_BUDGETS do
		budgets[requestType] = options.INITIAL_BUDGET
		queues[requestType] = {}
	end

	budgets[Enum.DataStoreRequestType.UpdateAsync] =
		math.min(budgets[Enum.DataStoreRequestType.GetAsync], budgets[Enum.DataStoreRequestType.SetIncrementAsync])

	return {
		accumulatedSeconds = 0,
		budgets = budgets,
		queues = queues,
		maxThrottleQueueSize = Constants.MAX_THROTTLE_QUEUE_SIZE,
	}
end

local Budget = {}
Budget.__index = Budget

export type RequestTypes = { Enum.DataStoreRequestType }
export type Request = {
	requestTypes: RequestTypes,
	thread: thread,
}

export type Budget = typeof(setmetatable(
	defaultBudget() :: {
		accumulatedSeconds: number,
		budgets: { [Enum.DataStoreRequestType]: number },
		queues: { [Enum.DataStoreRequestType]: { Request } },
		maxThrottleQueueSize: number,
		manual: boolean,
	},
	Budget
))

function Budget.new()
	local self = setmetatable(defaultBudget(), Budget) :: Budget

	self.manual = false

	RunService.PostSimulation:Connect(function(deltaSeconds)
		self:tick(deltaSeconds)
	end)

	return self
end

function Budget.manual()
	local self = setmetatable(defaultBudget(), Budget) :: Budget

	self.manual = true

	return self
end

function Budget.setMaxThrottleQueueSize(self, size: number)
	self.maxThrottleQueueSize = size
end

function Budget.hasBudget(self, requestTypes: RequestTypes): boolean
	for _, requestType in requestTypes do
		if self.budgets[requestType] < 1 then
			return false
		end
	end

	return true
end

function Budget.consumeBudget(self: Budget, requestTypes: RequestTypes)
	for _, requestType in requestTypes do
		self.budgets[requestType] = math.max(self.budgets[requestType] - 1, 0)
	end

	self.budgets[Enum.DataStoreRequestType.UpdateAsync] = math.min(
		self.budgets[Enum.DataStoreRequestType.GetAsync],
		self.budgets[Enum.DataStoreRequestType.SetIncrementAsync]
	)
end

function Budget.updateBudgets(self: Budget)
	local playerCount = #Players:GetPlayers()

	for requestType, options in Constants.REQUEST_BUDGETS do
		local rate = options.RATE + playerCount * options.RATE_PER_PLAYER

		self.budgets[requestType] = math.min(
			self.budgets[requestType] + rate * Constants.BUDGET_UPDATE_INTERVAL,
			options.MAX_BUDGET_FACTOR * rate
		)
	end

	self.budgets[Enum.DataStoreRequestType.UpdateAsync] = math.min(
		self.budgets[Enum.DataStoreRequestType.GetAsync],
		self.budgets[Enum.DataStoreRequestType.SetIncrementAsync]
	)
end

function Budget.updateQueues(self: Budget)
	for index, queue in self.queues do
		local newQueue = {}

		for _, request in queue do
			if self:hasBudget(request.requestTypes) then
				self:consumeBudget(request.requestTypes)
				coroutine.resume(request.thread)
			else
				table.insert(newQueue, request)
			end
		end

		self.queues[index] = newQueue
	end
end

function Budget.update(self: Budget)
	self:updateBudgets()
	self:updateQueues()
end

function Budget.tick(self: Budget, deltaSeconds: number)
	self.accumulatedSeconds += deltaSeconds

	while self.accumulatedSeconds >= Constants.BUDGET_UPDATE_INTERVAL do
		self:update()
		self.accumulatedSeconds -= Constants.BUDGET_UPDATE_INTERVAL
	end
end

function Budget.yieldForBudget(self: Budget, requestTypes: RequestTypes)
	local mainRequestType = requestTypes[1]

	if self:hasBudget(requestTypes) then
		self:consumeBudget(requestTypes)
	elseif #self.queues[mainRequestType] >= self.maxThrottleQueueSize then
		error("Request was throttled due to lack of budget but the throttle queue was full")
	else
		warn("Request was throttled due to lack of budget")

		table.insert(self.queues[mainRequestType], {
			thread = coroutine.running(),
			requestTypes = requestTypes,
		})

		coroutine.yield()
	end
end

return Budget
