local h = require("lib.helpers")

-- Note: This file does not use the testing library because the latter depends on it.

local function test_string_split()
	local s = "a,b,c"
	local split = h.string_split(s, "%,")
	assert(3 == #split)
	assert("a" == split[1])
	assert("b" == split[2])
	assert("c" == split[3])

	s = "a;,b;,c"
	split = h.string_split(s, "%;%,")
	assert(3 == #split)
	assert("a" == split[1])
	assert("b" == split[2])
	assert("c" == split[3])

	s = ",abc"
	split = h.string_split(s, "%,")
	assert(2 == #split)
	assert("" == split[1])
	assert("abc" == split[2])

	s = "abc,"
	split = h.string_split(s, "%,")
	assert(2 == #split)
	assert("abc" == split[1])
	assert("" == split[2])

	s = ","
	split = h.string_split(s, "%,")
end

local function test_table_to_str()
	local t1 = { foo = "bar" }
	assert("{foo = bar, }" == h.table_to_str(t1))
	local t2 = { bar = t1 }
	assert("{bar = {foo = bar, }, }", h.table_to_str(t2))
end

local function test_table_compare()
	local t1 = { foo = "bar", bar = 1 }
	local t2 = { foo = "bar", bar = 1 }
	local t3 = { foo = "foo", bar = 1 }
	local t4 = {}
	local t5 = { 1, 2, 3 }
	local t6 = { 1, 2, 3 }
	local t7 = { 1, 2, 4 }
	local t8 = { 1, 2 }

	assert(h.table_compare(t1, t2))
	assert(not h.table_compare(t1, t3))
	assert(not h.table_compare(t1, t4))
	assert(not h.table_compare(t1, t5))
	assert(h.table_compare(t5, t6))
	assert(not h.table_compare(t5, t7))
	assert(not h.table_compare(t5, t8))
end

local function test_table_compare_recursive()
	local t1 = { foo = "bar", bar = 1 }
	local t2 = { foo = "bar", bar = 1 }
	local t3 = { foo = "foo", bar = 1 }
	local t4 = {}
	local t5 = { 1, 2, 3 }
	local t6 = { 1, 2, 3 }
	local t7 = { 1, 2, 4 }
	local t8 = { 1, 2 }

	assert(h.table_compare_recursive(t1, t2))
	assert(not h.table_compare_recursive(t1, t3))
	assert(not h.table_compare_recursive(t1, t4))
	assert(not h.table_compare_recursive(t1, t5))
	assert(h.table_compare_recursive(t5, t6))
	assert(not h.table_compare_recursive(t5, t7))
	assert(not h.table_compare_recursive(t5, t8))

	local t9 = { t1 = t1 }
	local t10 = { t1 = t1 }
	local t11 = { t1 = t3 }
	local t12 = { t1 = t9 }

	assert(h.table_compare_recursive(t9, t10))
	assert(not h.table_compare_recursive(t9, t11))
	assert(not h.table_compare_recursive(t9, t12))
end

local function test_table_copy()
	local foo = "bar"
	local bar = 1
	local t1 = {
		foo = "bar",
		bar = 1
	}
	local t2 = h.table_copy(t1)
	assert(t2.foo == foo)
	assert(t2.bar == bar)
	t1.foo = "foo"
	assert(t1.foo ~= t2.foo)
	assert(t2.foo == foo)
end

local function test_table_copy_recursive()
	local foo = "bar"
	local bar = 1
	local t1 = {
		foo = "bar",
		bar = 1
	}
	local t2 = h.table_copy_recursive(t1)
	assert(t2.foo == foo)
	assert(t2.bar == bar)
	t1.foo = "foo"
	assert(t1.foo ~= t2.foo)
	assert(t2.foo == foo)

	local t3 = {
		foo = t2
	}
	local t4 = h.table_copy_recursive(t3)
	assert(t3.foo.foo == t4.foo.foo)
	assert(t3.foo.bar == t4.foo.bar)
	t3.foo.bar = "foo"
	assert(t3.foo.foo ~= t4.foo.bar)
	assert(t4.foo.foo == foo)
end

local function test_compare()
	local foo = "foo"
	assert(h.compare("foo", foo))
	assert(not h.compare("bar", foo))
	local bar = 1
	assert(h.compare(1, bar))
	assert(not h.compare(2, bar))
	local t1 = { foo = "foo" }
	local t2 = { foo = "foo" }
	assert(h.compare(t1, t2))
	t2.foo = "bar"
	assert(not h.compare(t1, t2))
	local t3 = { foo = t1 }
	local t4 = { foo = t1 }
	assert(h.compare(t3, t4))
	t4.foo = t2
	assert(not h.compare(t3, t4))
end

test_string_split()
test_table_to_str()
test_table_compare()
test_table_compare_recursive()
test_table_copy()
test_table_copy_recursive()
test_compare()
