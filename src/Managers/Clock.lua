local Constants = require(script.Parent.Parent.Constants)

local clock = 0

local function get()
	return clock
end

local Clock = {
	get = Constants.IS_UNIT_TEST_MODE and get or os.clock,
}

function Clock.set(value)
	clock = value
end

return Clock
