local Constants = require(script.Parent.Constants)
local DataStoreKeyInfo = require(script.Parent.DataStoreKeyInfo)
local validateString = require(script.Parent.validateString)

local function copyDeep(value)
	if typeof(value) ~= "table" then
		return value
	end

	local copy = {}

	for a, b in value do
		copy[a] = copyDeep(b)
	end

	return copy
end

local GlobalDataStore = {}
GlobalDataStore.__index = GlobalDataStore

function GlobalDataStore.new(budget, errors, yield)
	return setmetatable({
		data = {},
		keyInfos = {},
		getCache = {},
		budget = budget,
		errors = errors,
		yield = yield,
	}, GlobalDataStore)
end

function GlobalDataStore:write(key, data, userIds, metadata)
	local now = DateTime.now().UnixTimestampMillis

	local keyInfo = self.keyInfos[key]

	if keyInfo ~= nil then
		local version = tostring(tonumber(keyInfo.Version) + 1)

		self.keyInfos[key] = DataStoreKeyInfo.new(keyInfo.CreatedTime, now, version, userIds, metadata)
	else
		self.keyInfos[key] = DataStoreKeyInfo.new(now, now, "0", userIds, metadata)
	end

	-- Data is written after key info because DataStoreKeyInfo.new can throw an error.
	self.data[key] = copyDeep(data)
end

function GlobalDataStore:GetAsync(key: string, options: DataStoreGetOptions?)
	validateString("key", key, Constants.MAX_KEY_LENGTH)

	if (options == nil or options.UseCache) and self.getCache[key] ~= nil and os.clock() < self.getCache[key] then
		return copyDeep(self.data[key])
	end

	if self.errors ~= nil then
		self.errors:simulateError("GetAsync")
	end

	self.budget:yieldForBudget({ Enum.DataStoreRequestType.GetAsync })

	self.getCache[key] = os.clock() + Constants.GET_CACHE_DURATION

	local data = self.data[key]
	if data == nil then
		return nil, nil
	end

	local keyInfo = self.keyInfos[key]
	self.yield:yield()

	return copyDeep(data), keyInfo
end

function GlobalDataStore:UpdateAsync(key: string, transform)
	validateString("key", key, Constants.MAX_KEY_LENGTH)

	if typeof(transform) ~= "function" then
		error("`transform` must be a function")
	end

	if self.errors ~= nil then
		self.errors:simulateError("UpdateAsync")
	end

	local usingGetCache = self.getCache[key] ~= nil and os.clock() < self.getCache[key]

	local requestsTypes = if usingGetCache
		then { Enum.DataStoreRequestType.SetIncrementAsync }
		else { Enum.DataStoreRequestType.GetAsync, Enum.DataStoreRequestType.SetIncrementAsync }

	self.budget:yieldForBudget(requestsTypes)

	local oldValue = self.data[key]

	local toTransformerData = if oldValue ~= nil then copyDeep(oldValue) else nil
	local toTransformerKeyInfo = if oldValue == nil then nil else self.keyInfos[key]

	local ok, transformed, userIds, metadata = pcall(transform, toTransformerData, toTransformerKeyInfo)

	if not ok then
		task.spawn(error, transformed)
		return nil
	end

	if transformed == nil then
		return nil
	end

	-- TODO: Make sure transformed data is savable.

	self.yield:yield()

	self:write(key, transformed, userIds, metadata)

	self.getCache[key] = os.clock() + Constants.GET_CACHE_DURATION

	return copyDeep(transformed), self.keyInfos[key]
end

function GlobalDataStore:RemoveAsync(key: string)
	validateString("key", key, Constants.MAX_KEY_LENGTH)

	if self.errors ~= nil then
		self.errors:simulateError("RemoveAsync")
	end

	self.budget:yieldForBudget({ Enum.DataStoreRequestType.SetIncrementAsync })

	local oldValue = self.data[key]

	if oldValue == nil then
		return nil, nil
	end

	self.yield:yield()
	local keyInfo = self.keyInfos[key]

	self:write(key, nil, nil, nil)

	return copyDeep(oldValue), keyInfo
end

return GlobalDataStore
