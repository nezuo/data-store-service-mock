local Constants = require(script.Parent.Constants)
local DataStoreKeyInfo = require(script.Parent.DataStoreKeyInfo)
local validateString = require(script.Parent.validateString)

local OrderedDataStore = {}
OrderedDataStore.__index = OrderedDataStore

function OrderedDataStore.new(budget, errors, yield)
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