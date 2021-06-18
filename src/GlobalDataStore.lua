local assertValidValue = require(script.Parent.assertValidValue)
local Budget = require(script.Parent.Managers.Budget)
local Clock = require(script.Parent.Managers.Clock)
local Constants = require(script.Parent.Constants)
local Data = require(script.Parent.Managers.Data)
local deepCopy = require(script.Parent.deepCopy)
local Errors = require(script.Parent.Managers.Errors)
local getValidKey = require(script.Parent.getValidKey)
local simulateYield = require(script.Parent.simulateYield)

local function assertIsFunction(value)
	local valueType = typeof(value)

	if valueType ~= "function" then
		error("Unable to cast value to function") -- todo scope
	end
end

local function hasWriteCooldown(writeCooldown)
	return writeCooldown ~= nil and Clock.get() - writeCooldown < Constants.WRITE_COOLDOWN
end

local function hasGetCache(getCache)
	return getCache ~= nil and Clock.get() - getCache < Constants.GET_COOLDOWN
end

local GlobalDataStore = {}
GlobalDataStore.__index = GlobalDataStore

function GlobalDataStore.new(name, scope)
	local self = setmetatable({}, GlobalDataStore)

	self._data = Data.Global.get(name, scope)
	self._getCache = {}
	self._writeCooldowns = {}
	self._writeLocks = {}

	return self
end

function GlobalDataStore.global()
	local self = setmetatable({}, GlobalDataStore)

	self._data = Data.Default.get()
	self._getCache = {}
	self._writeCooldowns = {}
	self._writeLocks = {}

	return self
end

function GlobalDataStore:UpdateAsync(key, transform)
	key = getValidKey(key)
	assertIsFunction(transform)

	Errors.trySimulateErrorAndYield("UpdateAsync")

	local success
	if self._writeLocks[key] == true or hasWriteCooldown(self._writeCooldowns[key]) then
		success = Budget.yieldForWriteCooldownAndBudget(key, self._writeCooldowns[key], self._writeLocks, {
			Enum.DataStoreRequestType.SetIncrementAsync,
		})
	else
		self._writeLocks[key] = true

		local requestTypes = {}

		if not hasGetCache(self._getCache[key]) then
			table.insert(requestTypes, Enum.DataStoreRequestType.GetAsync)
		end

		table.insert(requestTypes, Enum.DataStoreRequestType.SetIncrementAsync)

		success = Budget.yieldForBudget(requestTypes)

		self._writeLocks[key] = nil
	end

	if not success then
		error("Request rejected with error (request was throttled, but throttle queue was full")
	end

	local currentValue = self._data[key]
	local value = transform(deepCopy(currentValue))

	if value == nil then
		simulateYield()

		return nil
	end

	assertValidValue(value)

	self._writeLocks[key] = true
	self._data[key] = deepCopy(value)

	simulateYield()

	local finalValue = deepCopy(value)

	self._writeLocks[key] = nil
	self._writeCooldowns[key] = Clock.get()
	self._getCache[key] = Clock.get()

	return finalValue
end

return GlobalDataStore
