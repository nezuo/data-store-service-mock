local GlobalDataStore = require(script.Parent.Parent.GlobalDataStore)
local OrderedDataStore = require(script.Parent.Parent.OrderedDataStore)

local defaultDataStore = nil
local globalDataStores = {}
local orderedDataStores = {}

local function resetDataStore(dataStore)
	for key in pairs(dataStore._data) do
		dataStore._data[key] = nil
	end

	dataStore._getCache = {}
	dataStore._writeCooldowns = {}
	dataStore._writeLocks = {}
end

local DataStores = {}

function DataStores.reset()
	if defaultDataStore ~= nil then
		resetDataStore(defaultDataStore)
	end

	for _, dataStores in pairs(globalDataStores) do
		for _, dataStore in pairs(dataStores) do
			resetDataStore(dataStore)
		end
	end

	for _, dataStores in pairs(orderedDataStores) do
		for _, dataStore in pairs(dataStores) do
			resetDataStore(dataStore)
		end
	end
end

function DataStores.getDefaultDataStore()
	if defaultDataStore == nil then
		defaultDataStore = GlobalDataStore.global()
	end

	return defaultDataStore
end

function DataStores.getGlobalDataStore(name, scope)
	if globalDataStores[name] == nil then
		globalDataStores[name] = {}
	end

	if globalDataStores[name][scope] == nil then
		globalDataStores[name][scope] = GlobalDataStore.new(name, scope)
	end

	return globalDataStores[name][scope]
end

function DataStores.getOrderedDataStore(name, scope)
	if orderedDataStores[name] == nil then
		orderedDataStores[name] = {}
	end

	if orderedDataStores[name][scope] == nil then
		orderedDataStores[name][scope] = OrderedDataStore.new(name, scope)
	end

	return orderedDataStores[name][scope]
end

return DataStores
