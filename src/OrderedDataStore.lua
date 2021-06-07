local Managers = require(script.Parent.Managers)

local OrderedDataStore = {}
OrderedDataStore.__index = OrderedDataStore

function OrderedDataStore.new(name, scope)
	local self = setmetatable({}, OrderedDataStore)

	self._data = Managers.Data.Ordered.get(name, scope)

	return self
end

return OrderedDataStore
