--!strict

local Budget = require(script.Parent.Budget)
local Constants = require(script.Parent.Constants)
local DataStoreKeyInfo = require(script.Parent.DataStoreKeyInfo)
local SimulatedErrors = require(script.Parent.SimulatedErrors)
local SimulatedYield = require(script.Parent.SimulatedYield)
local Utility = require(script.Parent.Utility)

local DataStore = {}
DataStore.__index = DataStore

export type Transform<T> = (
	T | nil,
	DataStoreKeyInfo.DataStoreKeyInfo | nil
) -> (T, DataStoreKeyInfo.UserIds?, DataStoreKeyInfo.Metadata?)

export type DataStore<T> = typeof(setmetatable(
	{} :: {
		data: T,
		keyInfos: { [string]: DataStoreKeyInfo.DataStoreKeyInfo },
		getCache: { [string]: number },
		budget: Budget.Budget,
		errors: SimulatedErrors.SimulatedErrors,
		yield: SimulatedYield.SimulatedYield,
	},
	DataStore
))

function DataStore.new<T>(
	budget: Budget.Budget,
	errors: SimulatedErrors.SimulatedErrors,
	yield: SimulatedYield.SimulatedYield
): DataStore<T>
	return setmetatable({
		data = ({} :: any) :: T,
		keyInfos = {},
		getCache = {},
		budget = budget,
		errors = errors,
		yield = yield,
	}, DataStore)
end

function DataStore.write<T>(
	self: DataStore<T>,
	key: string,
	data: T?,
	userIds: DataStoreKeyInfo.UserIds?,
	metadata: DataStoreKeyInfo.Metadata?
)
	local now = DateTime.now().UnixTimestampMillis

	local keyInfo = self.keyInfos[key]

	if keyInfo :: any ~= nil then
		local version = tostring(tonumber(keyInfo.Version) :: number + 1)

		self.keyInfos[key] = DataStoreKeyInfo.new(keyInfo.CreatedTime, now, version, userIds, metadata)
	else
		self.keyInfos[key] = DataStoreKeyInfo.new(now, now, "0", userIds, metadata)
	end

	-- Data is written after key info because DataStoreKeyInfo.new can throw an error.
	(self.data :: any)[key] = Utility.copyDeep(data)
end

function DataStore.GetAsync<T>(
	self: DataStore<T>,
	key: string,
	options: DataStoreGetOptions?
): (T?, DataStoreKeyInfo.DataStoreKeyInfo?)
	Utility.validateString("key", key, Constants.MAX_KEY_LENGTH)

	if (options == nil or options.UseCache) and self.getCache[key] ~= nil and os.clock() < self.getCache[key] then
		local data = (self.data :: any)[key]
		local keyInfo = self.keyInfos[key]

		if data == nil then
			return nil, nil
		end

		return Utility.copyDeep(data), Utility.copyDataStoreKeyInfo(keyInfo)
	end

	if self.errors :: any ~= nil then
		self.errors:simulateError("GetAsync")
	end

	self.budget:yieldForBudget({ Enum.DataStoreRequestType.GetAsync })

	self.getCache[key] = os.clock() + Constants.GET_CACHE_DURATION

	self.yield:yield()

	local data = (self.data :: any)[key]
	local keyInfo = self.keyInfos[key]

	if data == nil then
		return nil, nil
	end

	return Utility.copyDeep(data), Utility.copyDataStoreKeyInfo(keyInfo)
end

function DataStore.UpdateAsync<T>(
	self: DataStore<T>,
	key: string,
	transform: Transform<T>
): (T?, DataStoreKeyInfo.DataStoreKeyInfo?)
	Utility.validateString("key", key, Constants.MAX_KEY_LENGTH)

	if typeof(transform) ~= "function" then
		error("`transform` must be a function")
	end

	if self.errors :: any ~= nil then
		self.errors:simulateError("UpdateAsync")
	end

	local usingGetCache = self.getCache[key] ~= nil and os.clock() < self.getCache[key]

	local requestsTypes = if usingGetCache
		then { Enum.DataStoreRequestType.SetIncrementAsync }
		else { Enum.DataStoreRequestType.GetAsync, Enum.DataStoreRequestType.SetIncrementAsync }

	self.budget:yieldForBudget(requestsTypes)
	self.yield:yield()

	local oldValue = Utility.copyDeep((self.data :: any)[key])
	local oldKeyInfo = if oldValue ~= nil then Utility.copyDataStoreKeyInfo(self.keyInfos[key]) else nil

	local ok, transformed, userIds, metadata = pcall(transform, oldValue, oldKeyInfo)

	if not ok then
		task.spawn(error, transformed)
		return nil
	end

	if transformed == nil then
		return nil
	end

	-- TODO: Make sure transformed data is savable.

	self:write(key, transformed, userIds, metadata)

	self.getCache[key] = os.clock() + Constants.GET_CACHE_DURATION

	return Utility.copyDeep(transformed), Utility.copyDataStoreKeyInfo(self.keyInfos[key])
end

function DataStore.RemoveAsync<T>(self: DataStore<T>, key: string): (T?, DataStoreKeyInfo.DataStoreKeyInfo?)
	Utility.validateString("key", key, Constants.MAX_KEY_LENGTH)

	if self.errors :: any ~= nil then
		self.errors:simulateError("RemoveAsync")
	end

	self.budget:yieldForBudget({ Enum.DataStoreRequestType.SetIncrementAsync })
	self.yield:yield()

	local oldValue = (self.data :: any)[key]
	local keyInfo = self.keyInfos[key]

	if oldValue == nil then
		return nil, nil
	end

	self:write(key)

	return Utility.copyDeep(oldValue), Utility.copyDataStoreKeyInfo(keyInfo)
end

return DataStore