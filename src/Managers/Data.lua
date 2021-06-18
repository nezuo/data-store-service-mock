local function getScope(data, name, scope)
	if data[name] == nil then
		data[name] = {}
	end

	if data[name][scope] == nil then
		data[name][scope] = {}
	end

	return data[name][scope]
end

local function create()
	local data = {}

	return {
		get = function(name, scope)
			return getScope(data, name, scope)
		end,

		set = function(name, scope, key, value)
			getScope(data, name, scope)[key] = value
		end,
	}
end

local function createDefault()
	local data = {}

	return {
		get = function()
			return data
		end,

		set = function(key, value)
			data[key] = value
		end,
	}
end

return {
	Default = createDefault(),
	Global = create(),
	Ordered = create(),
}
