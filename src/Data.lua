-- TODO: Are we keeping the reset API or doing something different?

local function create()
	local data = {}

	return {
		get = function(name, scope)
			if data[name] == nil then
				data[name] = {}
			end

			if data[name][scope] == nil then
				data[name][scope] = {}
			end

			return data[name][scope]
		end,

		reset = function()
			for key in pairs(data) do
				data[key] = nil
			end
		end,
	}
end

local function createDefault()
	local data = {}

	return {
		get = function()
			return data
		end,

		reset = function()
			for key in pairs(data) do
				data[key] = nil
			end
		end,
	}
end

return {
	Default = createDefault(),
	Global = create(),
	Ordered = create(),
}
