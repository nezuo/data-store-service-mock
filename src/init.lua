local RunService = game:GetService("RunService")

local Constants = require(script.Constants)
local getValidString = require(script.getValidString)
local Managers = require(script.Managers)

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

	return Managers.DataStores.getGlobalDataStore(name, scope)
end

function DataStoreServiceMock:GetGlobalDataStore()
	assertIsServer()

	return Managers.DataStores.getDefaultDataStore()
end

function DataStoreServiceMock:GetOrderedDataStore(name, scope)
	assertIsServer()

	name = getValidName(name)
	scope = getValidScope(scope)

	return Managers.getOrderedDataStore(name, scope)
end

function DataStoreServiceMock:GetRequestBudgetForRequestType(requestType)
	-- todo: assert(is a DataStoreRequestType)

	return Managers.Budget.getBudget(requestType)
end

return DataStoreServiceMock
