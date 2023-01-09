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

function GlobalDataStore.new(budget, clock, errors)
	return setmetatable({
		data = {},
		keyInfos = {},
		getCache = {},
		writeCooldowns = {},
		budget = budget,
		clock = clock,
		errors = errors,
	}, GlobalDataStore)
end

function GlobalDataStore:write(key, data)
	self.data[key] = copyDeep(data)

	if self.keyInfos[key] == nil then
		self.keyInfos[key] = DataStoreKeyInfo.new(self.clock(), self.clock())
	else
		self.keyInfos[key].UpdatedTime = self.clock()
	end
end

function GlobalDataStore:UpdateAsync(key, transform)
	validateString("key", key, Constants.MAX_KEY_LENGTH)

	if typeof(transform) ~= "function" then
		error("`transform` must be a function")
	end

	if self.errors ~= nil then
		self.errors:simulateError("UpdateAsync")
	end

	if self.writeCooldowns[key] ~= nil and self.clock() < self.writeCooldowns[key] then
		self.budget:yieldForBudgetAndWriteCooldown(
			key,
			self.writeCooldowns,
			{ Enum.DataStoreRequestType.SetIncrementAsync }
		)
	else
		local usingGetCache = self.getCache[key] ~= nil and self.clock() < self.getCache[key]

		local requestsTypes = if usingGetCache
			then { Enum.DataStoreRequestType.SetIncrementAsync }
			else { Enum.DataStoreRequestType.GetAsync, Enum.DataStoreRequestType.SetIncrementAsync }

		self.budget:yieldForBudget(requestsTypes)
	end

	local oldValue = self.data[key]

	local ok, transformed = pcall(transform, copyDeep(oldValue), self.keyInfos[key])

	if not ok then
		task.spawn(error, transformed)
		return nil
	end

	if transformed == nil then
		return nil
	end

	-- TODO: Make sure transformed data is savable.

	self:write(key, transformed)

	self.getCache[key] = self.clock() + Constants.GET_CACHE_DURATION
	self.writeCooldowns[key] = self.clock() + Constants.WRITE_COOLDOWN

	return copyDeep(transformed)
end

return GlobalDataStore
