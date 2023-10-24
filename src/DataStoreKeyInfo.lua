local DataStoreKeyInfo = {}
DataStoreKeyInfo.__index = DataStoreKeyInfo

function DataStoreKeyInfo.new(createdTime, updatedTime, version, userIds, metadata)
	return setmetatable({
		CreatedTime = createdTime * 1000,
		UpdatedTime = updatedTime * 1000,
		Version = version,
		userIds = userIds or {},
		metadata = metadata or {},
	}, DataStoreKeyInfo)
end

function DataStoreKeyInfo:GetUserIds()
	return self.userIds
end

function DataStoreKeyInfo:GetMetadata()
	return self.metadata
end

return DataStoreKeyInfo
