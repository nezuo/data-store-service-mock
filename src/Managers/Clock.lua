local Constants = require(script.Parent.Parent.Constants)

local clock = 0

local Clock = {}

function Clock.get()
	if Constants.IS_UNIT_TEST_MODE then
		return clock
	else
		return os.clock()
	end
end

function Clock.set(value)
	clock = value
end

return Clock
