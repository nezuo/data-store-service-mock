local Constants = require(script.Parent.Constants)
local getValidString = require(script.Parent.getValidString)

local function getValidKey(key)
	key = getValidString(key)

	if #key == 0 then
		error("101: Key name can't be empty.", 3) -- todo scope
	elseif #key > Constants.MAX_NAME_LENGTH then
		error(string.format("102: Key name exceeds the %d limit.", Constants.MAX_NAME_LENGTH), 3) -- todo scope
	end

	return key
end

return getValidKey
