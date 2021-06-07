local RunService = game:GetService("RunService")

local getClock = require(script.Parent.Parent.getClock).getClock
local Constants = require(script.Parent.Parent.Constants)

local budgetRequestQueues = {
	TEMPORARY = {},
}

local Budget = {}

function Budget.start()
	if not RunService:IsServer() then
		return
	end

	coroutine.wrap(function()
		while true do
			-- wait BUDGET_UPDATE_INTERVAL

			-- update budget

			for index, budgetRequestQueue in ipairs(budgetRequestQueues) do
				local newBudgetRequestQueue = {}

				for _, budgetRequest in ipairs(budgetRequestQueue) do
					if getClock() - budgetRequest.cooldownAt > Constants.WRITE_COOLDOWN then
						coroutine.resume(budgetRequest.thread)
					else
						table.insert(newBudgetRequestQueue, budgetRequest)
					end
				end

				budgetRequestQueues[index] = newBudgetRequestQueue
			end
		end
	end)()
end

function Budget.yieldForWriteCooldown(cooldownAt)
	-- TODO: return false if request queue is full!

	local budgetRequest = {
		cooldownAt = cooldownAt,
		resolved = false,
		thread = coroutine.running(),
	}

	local requestType = "TEMPORARY"

	table.insert(budgetRequestQueues[requestType], budgetRequest)

	if not budgetRequest.resolved then
		coroutine.yield()
	end

	return true
end

return Budget
