--!strict

local RunService = game:GetService("RunService")

local Budget = require(script.Budget)
local Constants = require(script.Constants)
local DataStore = require(script.DataStore)
local OrderedDataStore = require(script.OrderedDataStore)
local SimulatedErrors = require(script.SimulatedErrors)
local SimulatedYield = require(script.SimulatedYield)
local validateString = require(script.validateString)

local function assertServer()
	if not RunService:IsServer() then
		error("DataStore can't be accessed from the client")
	end
end

local DataStoreServiceMock = {}
DataStoreServiceMock.__index = DataStoreServiceMock

export type DataStoreServiceMock = typeof(setmetatable(
	{} :: {
		dataStores: { [string]: { [string]: DataStore.DataStore<any> } },
		orderedDataStores: { [string]: { [string]: OrderedDataStore.OrderedDataStore } },
		errors: SimulatedErrors.SimulatedErrors,
		yield: SimulatedYield.SimulatedYield,
		budget: Budget.Budget,
	},
	DataStoreServiceMock
))

function DataStoreServiceMock.new(): DataStoreServiceMock
	return setmetatable({
		dataStores = {},
		orderedDataStores = {},
		errors = SimulatedErrors.new(),
		yield = SimulatedYield.new(),
		budget = Budget.new(),
	}, DataStoreServiceMock)
end

function DataStoreServiceMock.manual(): DataStoreServiceMock
	return setmetatable({
		dataStores = {},
		orderedDataStores = {},
		errors = SimulatedErrors.new(),
		yield = SimulatedYield.new(),
		budget = Budget.manual(),
	}, DataStoreServiceMock)
end

function DataStoreServiceMock.GetGlobalDataStore<T>(self: DataStoreServiceMock): DataStore.DataStore<T>
	return DataStoreServiceMock.GetDataStore(self, "global")
end

function DataStoreServiceMock.GetDataStore<T>(
	self: DataStoreServiceMock,
	name: string,
	scope: string?
): DataStore.DataStore<T>
	assertServer()

	scope = if typeof(scope) ~= "string" then "global" else scope

	validateString("name", name, Constants.MAX_NAME_LENGTH)
	validateString("scope", scope :: string, Constants.MAX_SCOPE_LENGTH)

	if self.dataStores[name] == nil then
		self.dataStores[name] = {}
	end

	if self.dataStores[name][scope :: string] :: any == nil then
		self.dataStores[name][scope :: string] = DataStore.new(self.budget, self.errors, self.yield)
	end

	return self.dataStores[name][scope :: string]
end

function DataStoreServiceMock.GetOrderedDataStore(self: DataStoreServiceMock, name: string, scope: string?)
	assertServer()

	scope = if typeof(scope) ~= "string" then "global" else scope

	validateString("name", name, Constants.MAX_NAME_LENGTH)
	validateString("scope", scope :: string, Constants.MAX_SCOPE_LENGTH)

	if self.orderedDataStores[name] == nil then
		self.orderedDataStores[name] = {}
	end

	if self.orderedDataStores[name][scope :: string] :: any == nil then
		self.orderedDataStores[name][scope :: string] = OrderedDataStore.new(self.budget, self.errors, self.yield)
	end

	return self.orderedDataStores[name][scope :: string]
end

function DataStoreServiceMock.GetRequestBudgetForRequestType(
	self: DataStoreServiceMock,
	requestType: Enum.DataStoreRequestType
): number
	local budget = self.budget.budgets[requestType]

	if budget == nil then
		error("`requestType` must be an Enum.DataStoreRequestType")
	end

	return budget
end

return DataStoreServiceMock
