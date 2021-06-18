local Data = require(script.Parent.Managers.Data)

local OrderedDataStore = {}
OrderedDataStore.__index = OrderedDataStore

function OrderedDataStore.new(name, scope)
	local self = setmetatable({}, OrderedDataStore)

	self._data = Data.Ordered.get(name, scope)

	return self
end

return OrderedDataStore
