local DataStoreKeyInfo = {}
DataStoreKeyInfo.__index = DataStoreKeyInfo

function DataStoreKeyInfo.new(createdTime, updatedTime)
	return setmetatable({
		CreatedTime = createdTime * 1000,
		UpdatedTime = updatedTime * 1000,
	}, DataStoreKeyInfo)
end

return DataStoreKeyInfo
