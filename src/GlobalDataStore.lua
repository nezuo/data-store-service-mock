local assertValidValue = require(script.Parent.assertValidValue)
local Budget = require(script.Parent.Managers.Budget)
local Constants = require(script.Parent.Constants)
local deepCopy = require(script.Parent.deepCopy)
local getClock = require(script.Parent.getClock).getClock
local getValidKey = require(script.Parent.getValidKey)
local Managers = require(script.Parent.Managers)
local simulateYield = require(script.Parent.simulateYield)

local function assertIsFunction(value)
	local valueType = typeof(value)

	if valueType ~= "function" then
		error("Unable to cast value to function") -- todo scope
	end
end

-- TODO: read cache

local GlobalDataStore = {}
GlobalDataStore.__index = GlobalDataStore

function GlobalDataStore.new(name, scope)
	local self = setmetatable({}, GlobalDataStore)

	self._data = Managers.Data.Global.get(name, scope)

	return self
end

function GlobalDataStore.global()
	local self = setmetatable({}, GlobalDataStore)

	self._data = Managers.Data.Default.get()

	return self
end

function GlobalDataStore:UpdateAsync(key, transform)
	key = getValidKey(key)
	assertIsFunction(transform)

	Managers.Errors.trySimulateErrorAndYield("UpdateAsync")

	-- TODO: wait for budget unless hit the limit

	if self._writeCooldown ~= nil and getClock() - self._writeCooldown < Constants.WRITE_COOLDOWN then
		Budget.yieldForWriteCooldown()
	end

	local currentValue = self._data[key]
	local value = transform(deepCopy(currentValue))

	if value == nil then
		simulateYield()

		return nil
	end

	assertValidValue(value)

	self._data[key] = deepCopy(value)

	-- tODO: write cache stuff and all that

	simulateYield()

	local finalValue = deepCopy(value)

	self._writeCooldown = getClock()

	return finalValue
end

return GlobalDataStore
