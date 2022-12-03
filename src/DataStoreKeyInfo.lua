local DataStoreKeyInfo = {}
DataStoreKeyInfo.__index = DataStoreKeyInfo

function DataStoreKeyInfo.new(createdTime, updatedTime)
	return setmetatable({
		CreatedTime = createdTime,
		UpdatedTime = updatedTime,
	}, DataStoreKeyInfo)
end

return DataStoreKeyInfo
