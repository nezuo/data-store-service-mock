local RunService = game:GetService("RunService")

local Constants = require(script.Constants)
local GlobalDataStore = require(script.GlobalDataStore)
local OrderedDataStore = require(script.OrderedDataStore)
local getValidString = require(script.getValidString)

--<< clean this
local dataStoreRequestTypes = {}

for _, enum in ipairs(Enum.DataStoreRequestType:GetEnumItems()) do
	dataStoreRequestTypes[enum] = enum
end
--<<

local defaultDataStore = nil
local globalDataStores = {}
local orderedDataStores = {}

local function assertIsServer()
	if not RunService:IsServer() then
		error("DataStore can't be accessed from the client", 3)
	end
end

local function getValidName(name)
	name = getValidString(name)

	if #name == 0 then
		error("DataStore name can't be empty string", 3)
	elseif #name > Constants.MAX_NAME_LENGTH then
		error(string.format("DataStore name is too long (exceeds %d characters)", Constants.MAX_NAME_LENGTH), 3)
	end

	return name
end

local function getValidScope(scope)
	if scope == nil then
		return "global"
	end

	scope = getValidString(scope)

	if #scope == 0 then
		error("DataStore scope can't be empty string", 3)
	elseif #scope > Constants.MAX_SCOPE_LENGTH then
		error(string.format("DataStore scope is too long (exceeds %d characters)", Constants.MAX_SCOPE_LENGTH), 3)
	end

	return scope
end

local DataStoreServiceMock = {}

function DataStoreServiceMock:GetDataStore(name, scope)
	assertIsServer()

	name = getValidName(name)
	scope = getValidScope(scope)

	if globalDataStores[name] == nil then
		globalDataStores[name] = {}
	end

	if globalDataStores[name][scope] == nil then
		globalDataStores[name][scope] = GlobalDataStore.new(name, scope)
	end

	return globalDataStores[name][scope]
end

function DataStoreServiceMock:GetGlobalDataStore()
	assertIsServer()

	if defaultDataStore == nil then
		defaultDataStore = GlobalDataStore.global()
	end

	return defaultDataStore
end

function DataStoreServiceMock:GetOrderedDataStore(name, scope)
	assertIsServer()

	name = getValidName(name)
	scope = getValidScope(scope)

	if orderedDataStores[name] == nil then
		orderedDataStores[name] = {}
	end

	if orderedDataStores[name][scope] == nil then
		orderedDataStores[name][scope] = OrderedDataStore.new(name, scope)
	end

	return orderedDataStores[name][scope]
end

function DataStoreServiceMock:GetRequestBudgetForRequestType(requestType)
	if dataStoreRequestTypes[requestType] == nil then
		error("TODO")
	end

	-- return budget
end

return DataStoreServiceMock
