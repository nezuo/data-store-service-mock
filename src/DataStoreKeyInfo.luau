--!strict

local DataStoreKeyInfo = {}
DataStoreKeyInfo.__index = DataStoreKeyInfo

export type UserIds = { number }
export type Metadata = { [any]: any }
export type DataStoreKeyInfo = typeof(setmetatable(
	{} :: {
		CreatedTime: number,
		UpdatedTime: number,
		Version: string,
		userIds: UserIds,
		metadata: Metadata,
	},
	DataStoreKeyInfo
))

function DataStoreKeyInfo.new(
	createdTime: number,
	updatedTime: number,
	version: string,
	userIds: UserIds?,
	metadata: Metadata?
): DataStoreKeyInfo
	local userIdsType = typeof(userIds)

	if userIdsType ~= "nil" and userIdsType ~= "table" then
		error(`expected userIds to be a table or nil, got {userIdsType}`)
	end

	if userIdsType == "table" then
		local expectedKey = 1
		for key, value in userIds :: UserIds do
			assert(typeof(value) == "number", "userId must be a number")

			if key ~= expectedKey then
				error(`expected userIds to be an array, got invalid key: {key}`)
			end

			expectedKey += 1
		end
	end

	return setmetatable({
		CreatedTime = createdTime,
		UpdatedTime = updatedTime,
		Version = version,
		userIds = if userIds ~= nil then table.clone(userIds) else {},
		metadata = if metadata ~= nil then table.clone(metadata) else {},
	}, DataStoreKeyInfo)
end

function DataStoreKeyInfo.GetUserIds(self: DataStoreKeyInfo): UserIds
	return table.clone(self.userIds)
end

function DataStoreKeyInfo:GetMetadata(): Metadata
	return table.clone(self.metadata)
end

return DataStoreKeyInfo