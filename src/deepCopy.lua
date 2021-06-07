local function deepCopy(copiedValue)
	if typeof(copiedValue) == "table" then
		local copy = {}

		for key, value in pairs(copiedValue) do
			copy[key] = deepCopy(value)
		end

		return copy
	else
		return copiedValue
	end
end

return deepCopy
