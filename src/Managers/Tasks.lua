local Constants = require(script.Parent.Parent.Constants)
local Budget = require(script.Parent.Budget)

local lastBudgetUpdateAt = 0

local function getBudgetTasks(clock)
	local tasks = {}

	if clock - lastBudgetUpdateAt >= Constants.BUDGET_UPDATE_INTERVAL then
		local numberOfUpdates = math.floor((clock - lastBudgetUpdateAt) / Constants.BUDGET_UPDATE_INTERVAL)

		for update = 1, numberOfUpdates do
			local updateAt = lastBudgetUpdateAt + update * Constants.BUDGET_UPDATE_INTERVAL

			table.insert(tasks, {
				isBudgetUpdate = true, -- tODO: remove
				resumeAt = updateAt,
				resume = function()
					Budget.update()
				end,
			})
		end

		lastBudgetUpdateAt = lastBudgetUpdateAt + numberOfUpdates * Constants.BUDGET_UPDATE_INTERVAL
	end

	return tasks
end

local Tasks = {}

function Tasks.get(clock)
	return getBudgetTasks(clock)
end

return Tasks
