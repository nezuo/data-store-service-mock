local RunService = game:GetService("RunService")

local Budget = require(script.Budget)
local Constants = require(script.Constants)
local GlobalDataStore = require(script.GlobalDataStore)
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

function DataStoreServiceMock.new()
	return setmetatable({
		dataStores = {},
		errors = SimulatedErrors.new(),
		yield = SimulatedYield,
		budget = Budget.new(os.clock),
		clock = os.clock,
	}, DataStoreServiceMock)
end

function DataStoreServiceMock.manual()
	local now = 0

	local function clock()
		return now
	end

	local self = setmetatable({
		dataStores = {},
		errors = SimulatedErrors.new(),
		yield = SimulatedYield,
		budget = Budget.manual(clock),
	}, DataStoreServiceMock)

	self.clock = clock

	function self:setClock(seconds)
		now = seconds
	end

	return self
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
		self.dataStores[name][scope] = GlobalDataStore.new(self.budget, self.clock, self.errors)
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

return DataStoreServiceMock
