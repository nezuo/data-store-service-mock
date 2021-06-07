local function getValidString(str)
	if typeof(str) == "number" then
		if str ~= str then
			return "NAN"
		elseif str >= math.huge then
			return "INF"
		elseif str <= -math.huge then
			return "-INF"
		end
	end

	return tostring(str)
end

return getValidString
