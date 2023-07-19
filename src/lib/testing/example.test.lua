local Testing = require("lib.testing.testing")

local function do_something(n)
	local m = n * 2
	return m ^ n
end

local function create_vargs(n)
	local t = {}
	for i = 1, n do
		t[i] = i
	end
	return table.unpack(t)
end

Testing.test("passing test", function()
	Testing.assert("this always succeeds", { "foo", 1 }, { "foo", 1 })
	Testing.assert("both true", { true }, { true })
	Testing.assert("both empty", {}, {})
end)

Testing.test("failing test", function()
	Testing.assert("this always fails", { true }, { false })
	Testing.assert("missing val", { true }, {})
end)

Testing.test("function call with runtime error", function()
	assert(true == true)
	do_something("foo")
end)

Testing.test("function with multiple return values", function()
	-- Simulate a function that returns many values
	-- Note: table.pack creates n field with number of values in packed table
	local expected = { 1, 2, 3, 4, n = 4 }
	local actual = table.pack(create_vargs(4))
	Testing.assert("complex assertion", expected, actual)
end)
