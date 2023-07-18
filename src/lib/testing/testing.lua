local helpers = require("lib.helpers")
local queue = require("lib.queue")

---@class lib_testing
---@field mockups {[string]: {[string]: fun(...)}}
local testing = { mockups = dofile("mockups.lua") }

local functions = {}
---@cast functions { [string]: { queue: queue, default: table | nil} }

---@param name string
function testing.fn(name, ...)
	functions[name] = {
		queue = helpers.table_copy(queue),
		default = nil
	}

	local q = functions[name].queue
	local function fn(...)
		if q.len > 0 then
			return table.unpack(q.pop())
		end
		return functions[name].default
	end
	return fn
end

---@param name string
function testing.set_default_return(name, ...)
	functions[name].default = table.pack(...)
end

---@param name string
function testing.set_return(name, ...)
	functions[name].queue.push(table.pack(...))
end

---@param name string
---@param count integer
function testing.set_return_many(name, count, ...)
	for _ = 1, count do
		testing.set_return(name, ...)
	end
end

---@param expected any[]
---@param actual any[]
function testing.assert(expected, actual)
	local trace = debug.traceback(nil, 2)
	if #expected ~= #actual then
		print("ERROR: Expected " .. #expected .. " values, but got " .. #actual)
		print(trace)
		return false
	end

	if not helpers.compare(expected, actual) then
		print("ERROR: Expected:\n" .. helpers.table_to_str(expected) ..
			"\nFound:\n" .. helpers.table_to_str(actual)
		)
		print(trace)
		return false
	end
end

-- TODO testing.reset()
-- TODO test runtime
-- FIXME test this lib

return testing
