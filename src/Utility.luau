--!strict
--!native

local DataStoreKeyInfo = require(script.Parent.DataStoreKeyInfo)

local Utility = {}

function Utility.copyDataStoreKeyInfo(keyInfo: DataStoreKeyInfo.DataStoreKeyInfo): DataStoreKeyInfo.DataStoreKeyInfo
	return DataStoreKeyInfo.new(
		keyInfo.CreatedTime,
		keyInfo.UpdatedTime,
		keyInfo.Version,
		keyInfo.userIds,
		keyInfo.metadata
	)
end

function Utility.copyDeep<T>(value: T): T
	if typeof(value) ~= "table" then
		return value
	end

	local copy = {}

	for a, b in value do
		copy[a] = Utility.copyDeep(b)
	end

	return (copy :: any) :: T
end

function Utility.validateString(name: string, value: string, maxLength: number)
	if #value == 0 then
		error(string.format("`%s` can't be empty string", name))
	elseif #value > maxLength then
		error(string.format("`%s` is too long (exceeds %d characters)", name, maxLength))
	end
end

return Utility
