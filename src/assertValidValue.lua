local HttpService = game:GetService("HttpService")

local Constants = require(script.Parent.Constants)

-- todo: SCOPES

local function makeInvalidTypeError(valueType)
	return string.format(
		"104: Cannot store %s in data store. Data stores can only accept valid UTF-8 characters.",
		valueType
	)
end

local function makeExceedsLimitError()
	return "105: Serialized value exceeds 4MB limit."
end

local function assertValidStringValue(value)
	if #value > Constants.MAX_DATA_LENGTH then
		error(makeExceedsLimitError())
	elseif utf8.len(value) == nil then
		error(makeInvalidTypeError("string"))
	end
end

local function getTableType(value)
	local key = next(value)

	if typeof(key) == "number" then
		return "Array"
	else
		return "Dictionary"
	end
end

local function isNumberValid(tableType, value)
	if tableType == "Dictionary" then
		return false, "cannot store mixed tables"
	end

	if value % 1 == 0 then
		return false, "cannot store tables with non-integer indices"
	end

	if value == math.huge or value == -math.huge then
		return false, "cannot store tables with (-)infinity indices"
	end

	return true
end

local function isValueValid(value, valueType)
	if valueType == "userdata" or valueType == "function" or valueType == "thread" then
		return false, string.format("cannot store '%s' of type %s", tostring(value), valueType)
	end

	if valueType == "string" and utf8.len(value) == nil then
		return false, "cannot store strings that are invalid UTF-8"
	end

	return true
end

local function isValidTable(tbl, visited, path)
	visited[tbl] = true

	local tableType = getTableType(tbl)

	local lastIndex = 0
	for key, value in pairs(tbl) do
		table.insert(path, tostring(key))

		local keyType = typeof(key)

		if keyType == "number" then
			local isValidNumber, invalidNumberReason = isNumberValid(key)

			if not isValidNumber then
				return false, path, invalidNumberReason
			end
		end

		if tableType == "Dictionary" and keyType ~= "string" then
			return false, path, string.format("dictionaries cannot have keys of type %s", keyType)
		end

		if tableType == "Array" and keyType ~= "number" then
			return false, path, "cannot store mixed tables"
		end

		if utf8.len(key) == nil then
			return false, path, "dictionary has key that is invalid UTF-8"
		end

		if tableType == "Array" then
			if lastIndex ~= key - 1 then
				return false, path, "array has non-sequential indices"
			end

			lastIndex = key
		end

		local valueType = typeof(value)

		local isValidValue, invalidValueReason = isValueValid(value)

		if not isValidValue then
			return isValidValue, path, invalidValueReason
		end

		if valueType == "table" then
			if visited[value] then
				return false, path
			end

			local isValid, invalidPath, reason = isValidTable(value, visited, path)

			if not isValid then
				return isValidTable, invalidPath, reason
			end
		end

		table.remove(tbl)
	end

	return true, nil, nil
end

local function assertValidTableValue(value)
	local isValid, invalidPath, reason = isValidTable(value, {}, { "root" })

	if not isValid then
		error(string.format("Table value has invalid entry at <%s>: %s", table.concat(invalidPath, "."), reason))
	end

	local ok, content = pcall(function()
		return HttpService:JSONEncode(value)
	end)

	if not ok then
		error("Could not encode table to JSON.")
	elseif #content > Constants.MAX_DATA_LENGTH then
		error(makeExceedsLimitError())
	end
end

-- TODO: This really needs to be tested!
local function assertValidValue(value)
	local valueType = typeof(value)

	if valueType == "function" or valueType == "userdata" or valueType == "thread" then
		error(makeInvalidTypeError(valueType))
	end

	if valueType == "string" then
		assertValidStringValue(value)
	elseif valueType == "table" then
		assertValidTableValue(value)
	end
end

return assertValidValue
