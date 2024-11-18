local RunService = game:GetService("RunService")

local Budget = require(script.Budget)
local Constants = require(script.Constants)
local DataStore = require(script.DataStore)
local SimulatedErrors = require(script.SimulatedErrors)
local SimulatedYield = require(script.SimulatedYield)
local validateString = require(script.validateString)

type SimulatedErrors = {
	addSimulatedErrors: (self: SimulatedErrors, amount: number) -> (),
}

type SimulatedYield = {
	startYield: (self: SimulatedYield) -> (),
	stopYield: (self: SimulatedYield) -> (),
}

type Budget = {
	setMaxThrottleQueueSize: (self: Budget, size: number) -> (),
	update: (self: Budget) -> (),
}

export type DataStore = {
	write: (self: DataStore, key: string, data: any, userIds: { number }?, metadata: { [any]: any }?) -> (),
	GetAsync: (self: DataStore, key: string, options: DataStoreGetOptions?) -> (unknown, DataStoreKeyInfo?),
	UpdateAsync: (
		self: DataStore,
		key: string,
		transform: (unknown, DataStoreKeyInfo?) -> (unknown, { number }?, { [any]: any }?)
	) -> (unknown, DataStoreKeyInfo?),
	RemoveAsync: (self: DataStore, key: string) -> (unknown, DataStoreKeyInfo?),
}

export type DataStoreServiceMock = {
	errors: SimulatedErrors,
	yield: SimulatedYield,
	budget: Budget,
	GetDataStore: (self: DataStoreServiceMock, name: string, scope: string?) -> DataStore,
	GetRequestBudgetForRequestType: (self: DataStoreServiceMock, requestType: Enum.DataStoreRequestType) -> number,
}

local function assertServer()
	if not RunService:IsServer() then
		error("DataStore can't be accessed from the client")
	end
end

local DataStoreServiceMock = {}
DataStoreServiceMock.__index = DataStoreServiceMock

function DataStoreServiceMock.new()
	return setmetatable({
		dataStores = {},
		errors = SimulatedErrors.new(),
		yield = SimulatedYield.new(),
		budget = Budget.new(),
	}, DataStoreServiceMock)
end

function DataStoreServiceMock.manual()
	return setmetatable({
		dataStores = {},
		errors = SimulatedErrors.new(),
		yield = SimulatedYield.new(),
		budget = Budget.manual(),
	}, DataStoreServiceMock)
end

function DataStoreServiceMock:GetDataStore(name, scope)
	assertServer()

	scope = scope or "global"

	validateString("name", name, Constants.MAX_NAME_LENGTH)
	validateString("scope", scope, Constants.MAX_SCOPE_LENGTH)

	if self.dataStores[name] == nil then
		self.dataStores[name] = {}
	end

	if self.dataStores[name][scope] == nil then
		self.dataStores[name][scope] = DataStore.new(self.budget, self.errors, self.yield)
	end

	return self.dataStores[name][scope]
end

function DataStoreServiceMock:GetRequestBudgetForRequestType(requestType)
	local budget = self.budget.budgets[requestType]

	if budget == nil then
		error("`requestType` must be an Enum.DataStoreRequestType")
	end

	return budget
end

return (DataStoreServiceMock :: any) :: { new: () -> DataStoreServiceMock, manual: () -> DataStoreServiceMock }
