local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Clock = require(script.Parent.Parent.Managers.Clock)
local Constants = require(script.Parent.Parent.Constants)

local budgetRequestQueues = {}
local budgets = {}

local throttleQueueSize = Constants.THROTTLE_QUEUE_SIZE

local lastUpdateAt = Clock.get()

local function hasBudget(requestType)
	return budgets[requestType] > 0
end

local function hasBudgets(requestTypes)
	for _, requestType in ipairs(requestTypes) do
		if not hasBudget(requestType) then
			return false
		end
	end

	return true
end

local function updateUpdateAsyncBudget()
	budgets[Enum.DataStoreRequestType.UpdateAsync] =
		math.min(budgets[Enum.DataStoreRequestType.GetAsync], budgets[Enum.DataStoreRequestType.SetIncrementAsync])
end

local function stealBudget(requestTypes)
	for _, requestType in ipairs(requestTypes) do
		if budgets[requestType] ~= nil then
			budgets[requestType] = math.max(0, budgets[requestType] - 1)
		end
	end

	updateUpdateAsyncBudget()
end

local function isRequestOnCooldown(budgetRequest)
	if budgetRequest.cooldownAt == nil then
		return false
	end

	return Clock.get() - budgetRequest.cooldownAt >= Constants.WRITE_COOLDOWN
end

local function isOnWriteLock(budgetRequest)
	if budgetRequest.writeLocks == nil then
		return false
	end

	return budgetRequest.writeLocks[budgetRequest.key] == true
end

local function updateBudgetRequestQueues()
	for index, budgetRequestQueue in pairs(budgetRequestQueues) do
		local newBudgetRequestQueue = {}

		for _, budgetRequest in ipairs(budgetRequestQueue) do
			if
				not isRequestOnCooldown(budgetRequest)
				and not isOnWriteLock(budgetRequest)
				and hasBudgets(budgetRequest.requestTypes)
			then
				stealBudget(budgetRequest.requestTypes)

				coroutine.resume(budgetRequest.thread)
			else
				table.insert(newBudgetRequestQueue, budgetRequest)
			end
		end

		budgetRequestQueues[index] = newBudgetRequestQueue
	end
end

local function updateBudget(requestType, numberOfPlayers, deltaTime)
	local budget = Constants.BUDGETS[requestType]
	local rate = budget.ADDED_RATE + numberOfPlayers * budget.ADDED_PER_PLAYER_RATE

	budgets[requestType] = math.min(budgets[requestType] + rate * deltaTime, budget.MAXIMUM_BUDGET_FACTOR * rate)
end

local function updateBudgets()
	local numberOfPlayers = #Players:GetPlayers()
	local deltaTime = (Clock.get() - lastUpdateAt) / 60

	for requestType in pairs(Constants.BUDGETS) do
		updateBudget(requestType, numberOfPlayers, deltaTime)
	end

	updateUpdateAsyncBudget()
end

local Budget = {}

function Budget.setBudget(requestType)
	budgets[requestType] = 0

	if requestType == Enum.DataStoreRequestType.UpdateAsync then
		budgets[Enum.DataStoreRequestType.GetAsync] = 0
		budgets[Enum.DataStoreRequestType.SetIncrementAsync] = 0
	end
end

function Budget.getBudget(requestType)
	return math.floor(budgets[requestType] or 0)
end

function Budget.update()
	updateBudgets()
	updateBudgetRequestQueues()
end

function Budget.start()
	if not RunService:IsServer() then
		return
	end

	local updateAt = os.clock()

	local connection
	connection = RunService.Heartbeat:Connect(function()
		if Constants.IS_UNIT_TEST_MODE then
			connection:Disconnect()
		end

		if os.clock() >= updateAt then
			Budget.update()
			updateAt += Constants.BUDGET_UPDATE_INTERVAL
		end
	end)
end

function Budget.yieldForWriteCooldownAndBudget(key, cooldownAt, writeLocks, requestTypes)
	local mainRequestType = requestTypes[1]

	if #budgetRequestQueues[mainRequestType] >= throttleQueueSize then
		return false
	end

	local budgetRequest = {
		cooldownAt = cooldownAt,
		key = key,
		requestTypes = requestTypes,
		resolved = false,
		thread = coroutine.running(),
		writeLocks = writeLocks,
	}

	-- TODO: Trigger a warning when things are added to the queue.

	table.insert(budgetRequestQueues[mainRequestType], budgetRequest)

	if not budgetRequest.resolved then
		coroutine.yield()
	end

	return true
end

function Budget.yieldForBudget(requestTypes)
	local mainRequestType = requestTypes[1]

	if hasBudgets(requestTypes) then
		stealBudget(requestTypes)

		return true
	end

	if #budgetRequestQueues[mainRequestType] >= throttleQueueSize then
		return false
	end

	local budgetRequest = {
		requestTypes = requestTypes,
		resolved = false,
		thread = coroutine.running(),
	}

	-- TODO: Trigger a warning when things are added to the queue.

	table.insert(budgetRequestQueues[mainRequestType], budgetRequest)

	if not budgetRequest.resolved then
		coroutine.yield()
	end

	return true
end

function Budget.setThrottleQueueSize(size)
	throttleQueueSize = size
end

function Budget.reset()
	budgets = {
		[Enum.DataStoreRequestType.UpdateAsync] = math.min(
			Constants.BUDGETS[Enum.DataStoreRequestType.GetAsync].INITIAL_BUDGET,
			Constants.BUDGETS[Enum.DataStoreRequestType.SetIncrementAsync].INITIAL_BUDGET
		),
	}

	for requestType, budget in pairs(Constants.BUDGETS) do
		budgetRequestQueues[requestType] = {}
		budgets[requestType] = budget.INITIAL_BUDGET
	end
end

function Budget.resetThrottleQueueSize()
	throttleQueueSize = Constants.THROTTLE_QUEUE_SIZE
end

Budget.reset()
Budget.start()

return Budget
