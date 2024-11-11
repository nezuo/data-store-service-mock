--!strict

local Budget = require(script.Parent.Budget)
local Constants = require(script.Parent.Constants)
local DataStoreKeyInfo = require(script.Parent.DataStoreKeyInfo)
local validateString = require(script.Parent.validateString)
local SimulatedErrors = require(script.Parent.SimulatedErrors)
local SimulatedYield = require(script.Parent.SimulatedYield)
local validateString = require(script.Parent.validateString)
local copyDeep = require(script.Parent.copyDeep)

local OrderedDataStore = {}
OrderedDataStore.__index = OrderedDataStore

export type OrderedDataStore = typeof(setmetatable({} :: {}, OrderedDataStore))

function OrderedDataStore.new(budget: Budget.Budget, errors: SimulatedErrors.SimulatedErrors, yield: SimulatedYield.SimulatedYield): OrderedDataStore
	return setmetatable({
		data = {},
		keyInfos = {},
		getCache = {},
		budget = budget,
		errors = errors,
		yield = yield,
	}, OrderedDataStore)
end

function OrderedDataStore:GetSortedAsync(ascending: boolean, pageSize: number, minValue: number?, maxValue: number?) end

return OrderedDataStore