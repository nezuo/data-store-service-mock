--!strict
--!native

local function copyDeep<T>(value: T): T
	if typeof(value) ~= "table" then
		return value
	end

	local copy = {}

	for a, b in value do
		copy[a] = copyDeep(b)
	end

	return (copy :: any) :: T
end

return copyDeep
