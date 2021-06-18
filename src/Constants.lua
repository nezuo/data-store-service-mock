return {
	IS_UNIT_TEST_MODE = true,

	YIELD_TIME_MIN = 0.2,
	YIELD_TIME_MAX = 0.5,

	MAX_NAME_LENGTH = 50, -- The maximum number of characters allowed in a DataStore's name.
	MAX_SCOPE_LENGTH = 50, -- The maximum number of characters allowed in a DataStore's scope.
	MAX_KEY_LENGTH = 50, -- The maximum number of characters allowed in a DataStore key.
	MAX_DATA_LENGTH = 4194301, -- The maximum number of characters allowed in a JSON encoded version of the data.

	WRITE_COOLDOWN = 6, -- The amount of time in seconds between writes on one key in a particular DataStore.
	GET_COOLDOWN = 5, -- The amount of time in seconds........ TODO

	THROTTLE_QUEUE_SIZE = 30, -- The amount of requests that can be throttled at once before requests will error.

	BUDGET_UPDATE_INTERVAL = 1, -- The interval in seconds at which budgets are updated.

	BUDGETS = {
		[Enum.DataStoreRequestType.GetAsync] = {
			INITIAL_BUDGET = 100,
			ADDED_RATE = 60,
			ADDED_PER_PLAYER_RATE = 10,
			MAXIMUM_BUDGET_FACTOR = 3,
		},

		[Enum.DataStoreRequestType.SetIncrementAsync] = {
			INITIAL_BUDGET = 100,
			ADDED_RATE = 60,
			ADDED_PER_PLAYER_RATE = 10,
			MAXIMUM_BUDGET_FACTOR = 3,
		},

		[Enum.DataStoreRequestType.SetIncrementSortedAsync] = {
			INITIAL_BUDGET = 50,
			ADDED_RATE = 30,
			ADDED_PER_PLAYER_RATE = 5,
			MAXIMUM_BUDGET_FACTOR = 3,
		},

		[Enum.DataStoreRequestType.OnUpdate] = {
			INITIAL_BUDGET = 30,
			ADDED_RATE = 30,
			ADDED_PER_PLAYER_RATE = 5,
			MAXIMUM_BUDGET_FACTOR = 1,
		},

		[Enum.DataStoreRequestType.GetSortedAsync] = {
			INITIAL_BUDGET = 10,
			ADDED_RATE = 5,
			ADDED_PER_PLAYER_RATE = 2,
			MAXIMUM_BUDGET_FACTOR = 3,
		},
	},
}
