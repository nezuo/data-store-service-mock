local RunService = game:GetService("RunService")

local Constants = require(script.Parent.Constants)

local function wait(duration)
	if Constants.IS_UNIT_TEST_MODE then
		return 0
	end

	local remaining = duration

	while remaining > 0 do
		remaining = remaining - RunService.Heartbeat:Wait()
	end

	return duration - remaining
end

return wait
