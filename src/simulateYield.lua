local Constants = require(script.Parent.Constants)

local random = Random.new()

local function simulateYield()
	if Constants.YIELD_TIME_MAX > 0 then
		-- wait for random:NextNumber(Constants.YIELD_TIME_MIN, Constants.YIELD_TIME_MAX)
	end
end

return simulateYield
