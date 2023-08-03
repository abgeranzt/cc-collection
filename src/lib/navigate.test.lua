---@diagnostic disable: lowercase-global
local Testing = require("lib.testing.testing")

os = Testing.mockups.os
sleep = Testing.mockups.sleep
turtle = Testing.mockups.turtle

local navigate = require("lib.navigate")

Testing.test("go._go", function()
	-- forward
	Testing.set_return_many("turtle.forward", 5, true)
	local ok, err, trav = navigate.go._go("forward", 5)
	Testing.assert("_go returned true", { true }, { ok })
	Testing.assert("_go returned no error", {}, { err })
	Testing.assert("turtle.forward() has been called 5 times",
		{ 5 }, { Testing.get_call_amount("turtle.forward") }
	)
	Testing.assert("trav matches distance travelled", { 5 }, { trav })
	Testing.assert("pos_update event has been queued",
		{ 5 }, { Testing.get_call_amount("os.queueEvent") }
	)

	-- back
	Testing.reset_fns()
	Testing.set_return("turtle.back", true)
	ok, err, trav = navigate.go._go("back", 1)
	Testing.assert("_go returned true", { true }, { ok })
	Testing.assert("_go called turtle.back",
		{ 1 }, { Testing.get_call_amount("turtle.back") }
	)
	-- up
	Testing.reset_fns()
	Testing.set_return("turtle.up", true)
	ok, err, trav = navigate.go._go("up", 1)
	Testing.assert("_go returned true", { true }, { ok })
	Testing.assert("_go called turtle.up",
		{ 1 }, { Testing.get_call_amount("turtle.up") }
	)
	-- down
	Testing.reset_fns()
	Testing.set_return("turtle.down", true)
	ok, err, trav = navigate.go._go("down", 1)
	Testing.assert("_go returned true", { true }, { ok })
	Testing.assert("_go called turtle.down",
		{ 1 }, { Testing.get_call_amount("turtle.down") }
	)

	-- error while navigating
	Testing.reset_fns()
	Testing.set_return_many("turtle.forward", 3, true)
	Testing.set_default_return("turtle.forward", false, "test: path blocked")
	ok, err, trav = navigate.go._go("forward", 5)
	Testing.assert("_go returned false", { false }, { ok })
	Testing.assert("_go returned error message",
		{ "test: path blocked", }, { err }
	)
	Testing.assert("distance travelled matches", { 3 }, { trav })
	-- 3 successfull moves, 5 retries on failure
	Testing.assert("_go retried calling turtle.forward",
		{ 8 }, { Testing.get_call_amount("turtle.forward") })
end)

Testing.test("go._go_or_return", function()
	-- simple
	Testing.set_default_return("turtle.forward", true)
	navigate.go._go = Testing.fn("navigate.go._go")
	Testing.set_return("navigate.go._go", true, nil, 3)
	local ok, err, trav = navigate.go._go_or_return("forward", 3)
	Testing.assert("_go_or_return returned true", { true }, { ok })
	Testing.assert("_go_or_return returned no error", {}, { err })
	Testing.assert("_go was called correctly",
		{ "forward", 3 }, { Testing.get_last_call("navigate.go._go") }
	)
	Testing.assert("trav matches return value from _go", { 3 }, { trav })
	-- fail on initial move
	Testing.reset_fns()
	Testing.set_return("navigate.go._go", false, "test: path blocked", 3)
	Testing.set_return("navigate.go._go", true, nil, 3)
	ok, err, trav = navigate.go._go_or_return("forward", 5)
	Testing.assert("_go_or_return returned false", { false }, { ok })
	Testing.assert("_go_or_return returned error", { "test: path blocked" }, { err })
	Testing.assert("_go_or_return returned the distance travelled", { 3 }, { trav })
	-- fail on initial move, also fail on return move
	Testing.reset_fns()
	Testing.set_return("navigate.go._go", false, "test: path blocked", 5)
	Testing.set_return("navigate.go._go", false, "test: path blocked", 3)
	ok, err, trav = navigate.go._go_or_return("forward", 7)
	Testing.assert("_go_or_return returned false", { false }, { ok })
	Testing.assert("_go_or_return returned error", { "could not return after failed initial move" }, { err })
	Testing.assert("_go_or_return returned the distance travelled returning", { 3 }, { trav })
end)
-- reset overwritten lib import
navigate = require("lib.navigate")

Testing.test("go.axis", function()
	local lib_go = {
		forward = Testing.fn("lib_go.forward"),
		back = Testing.fn("lib_go.back"),
		up = Testing.fn("lib_go.up"),
		down = Testing.fn("lib_go.down"),
	}
	-- y
	Testing.set_return("lib_go.up", true, nil, 10)
	local ok, err, trav = navigate.go.axis("y", "north", 0, 10, lib_go)
	Testing.assert("go.axis retured true", { true }, { ok })
	Testing.assert("go.axis returned no error", {}, { err })
	Testing.assert("go.axis called lib_go.up",
		{ 1 }, { Testing.get_call_amount("lib_go.up") }
	)
	Testing.assert("go.axis returned the distance travelled", { 10 }, { trav })
	Testing.reset_fns()
	Testing.set_return("lib_go.down", true, nil, 10)
	ok, err, trav = navigate.go.axis("y", "north", 0, -10, lib_go)
	Testing.assert("go.axis retured true", { true }, { ok })
	Testing.assert("go.axis returned no error", {}, { err })
	Testing.assert("go.axis called lib_go.down",
		{ 1 }, { Testing.get_call_amount("lib_go.down") }
	)
	Testing.assert("go.axis returned the distance travelled", { 10 }, { trav })
	-- x
	Testing.reset_fns()
	navigate.go.turn_dir = Testing.fn("navigate.go.turn_dir")
	Testing.set_return("navigate.go.turn_dir", "east")
	Testing.set_return("navigate.go.turn_dir", "north")
	Testing.set_return("lib_go.forward", true, nil, 10)
	ok, err, trav = navigate.go.axis("x", "north", 0, 10, lib_go)
	Testing.assert("go.axis retured true", { true }, { ok })
	Testing.assert("go.axis returned no error", {}, { err })
	Testing.assert("go.axis called lib_go.forward",
		{ 1 }, { Testing.get_call_amount("lib_go.forward") }
	)
	Testing.assert("go.axis returned the distance travelled", { 10 }, { trav })
	Testing.assert("go.turn_dir has been called two times",
		{ 2 }, { Testing.get_call_amount("navigate.go.turn_dir") }
	)
	Testing.assert("go.turn_dir has been called with the correct argument",
		{ "east", "north" }, { Testing.get_last_call("navigate.go.turn_dir") }
	)
	Testing.reset_fns()
	Testing.set_return("navigate.go.turn_dir", "east")
	Testing.set_return("navigate.go.turn_dir", "north")
	Testing.set_return("lib_go.back", true, nil, 10)
	ok, err, trav = navigate.go.axis("x", "north", 0, -10, lib_go)
	Testing.assert("go.axis retured true", { true }, { ok })
	Testing.assert("go.axis returned no error", {}, { err })
	Testing.assert("go.axis called lib_go.back",
		{ 1 }, { Testing.get_call_amount("lib_go.back") }
	)
	Testing.assert("go.axis returned the distance travelled", { 10 }, { trav })
	-- z
	Testing.reset_fns()
	navigate.go.turn_dir = Testing.fn("navigate.go.turn_dir")
	Testing.set_return("navigate.go.turn_dir", "south")
	Testing.set_return("navigate.go.turn_dir", "north")
	Testing.set_return("lib_go.forward", true, nil, 10)
	ok, err, trav = navigate.go.axis("z", "north", 0, 10, lib_go)
	Testing.assert("go.axis retured true", { true }, { ok })
	Testing.assert("go.axis returned no error", {}, { err })
	Testing.assert("go.axis called lib_go.forward",
		{ 1 }, { Testing.get_call_amount("lib_go.forward") }
	)
	Testing.assert("go.axis returned the distance travelled", { 10 }, { trav })
	Testing.assert("go.turn_dir has been called two times",
		{ 2 }, { Testing.get_call_amount("navigate.go.turn_dir") }
	)
	Testing.assert("go.turn_dir has been called with the correct argument",
		{ "south", "north" }, { Testing.get_last_call("navigate.go.turn_dir") }
	)
	Testing.reset_fns()
	Testing.set_return("navigate.go.turn_dir", "south")
	Testing.set_return("navigate.go.turn_dir", "north")
	Testing.set_return("lib_go.back", true, nil, 10)
	ok, err, trav = navigate.go.axis("z", "north", 0, -10, lib_go)
	Testing.assert("go.axis retured true", { true }, { ok })
	Testing.assert("go.axis returned no error", {}, { err })
	Testing.assert("go.axis called lib_go.back",
		{ 1 }, { Testing.get_call_amount("lib_go.back") }
	)
	Testing.assert("go.axis returned the distance travelled", { 10 }, { trav })
	-- failure
	Testing.reset_fns()
	Testing.set_return("lib_go.forward", false, "test: path blocked", 9)
	Testing.set_return("navigate.go.turn_dir", "south")
	Testing.set_return("navigate.go.turn_dir", "north")
	ok, err, trav = navigate.go.axis("z", "north", 0, 10, lib_go)
	Testing.assert("go.axis retured false", { false }, { ok })
	Testing.assert("go.axis returned the correct error",
		{ "test: path blocked" }, { err }
	)
	Testing.assert("go.axis returned the distance travelled", { 9 }, { trav })
end)
-- reset overwritten lib import
navigate = require("lib.navigate")

Testing.test("go.coords", function()
	navigate.go.axis = Testing.fn("navigate.go.axis", true)
	navigate.go.turn_dir = Testing.fn("navigate.go.turn_dir")
	Testing.set_return("navigate.go.axis", true, nil, 10)
	Testing.set_return("navigate.go.axis", true, nil, 0)
	Testing.set_return("navigate.go.axis", true, nil, 10)
	Testing.set_return("navigate.go.turn_dir", "south")
	local current_pos = {
		x = 0, y = 0, z = 0, dir = "north"
	}
	local target_pos = {
		x = -10, y = 0, z = 10, dir = "south"
	}
	local ok, err, trav, new_pos = navigate.go.coords(current_pos, target_pos, nil, "xyz")
	Testing.assert("go.coords returned true", { true }, { ok })
	Testing.assert("go.coords returned no error", {}, { err })
	Testing.assert("go.coords returned the total distance travelled", { 20 }, { trav })
	Testing.assert("go.coords returned the new position",
		{ x = -10, y = 0, z = 10, dir = "south" }, new_pos
	)
	Testing.assert("go.axis has been called three times",
		{ 3 }, { Testing.get_call_amount("navigate.go.axis") }
	)
	Testing.assert("go.axis has been called correctly",
		{ "x", "north", 0, -10 }, { Testing.get_nth_call("navigate.go.axis", 1) })
	Testing.assert("go.axis has been called correctly",
		{ "y", "north", 0, 0 }, { Testing.get_nth_call("navigate.go.axis", 2) })
	Testing.assert("go.axis has been called correctly",
		{ "z", "north", 0, 10 }, { Testing.get_last_call("navigate.go.axis") })

	-- different axis order: yzx
	Testing.reset_fns()
	Testing.set_return("navigate.go.axis", true, nil, 25)
	Testing.set_return("navigate.go.axis", true, nil, 10)
	Testing.set_return("navigate.go.axis", true, nil, 30)
	Testing.set_return("navigate.go.turn_dir", "south")
	current_pos = {
		x = 0, y = 0, z = 0, dir = "north"
	}
	target_pos = {
		x = 30, y = -25, z = 10, dir = "south"
	}
	ok, err, trav, new_pos = navigate.go.coords(current_pos, target_pos, nil, "yzx")
	Testing.assert("go.coords returned true", { true }, { ok })
	Testing.assert("go.coords returned no error", {}, { err })
	Testing.assert("go.coords returned the total distance travelled", { 65 }, { trav })
	Testing.assert("go.coords returned the new position",
		{ x = 30, y = -25, z = 10, dir = "south" }, new_pos
	)
	Testing.assert("go.axis has been called three times",
		{ 3 }, { Testing.get_call_amount("navigate.go.axis") }
	)
	Testing.assert("go.axis has been called correctly",
		{ "y", "north", 0, -25 }, { Testing.get_nth_call("navigate.go.axis", 1) })
	Testing.assert("go.axis has been called correctly",
		{ "z", "north", 0, 10 }, { Testing.get_nth_call("navigate.go.axis", 2) })
	Testing.assert("go.axis has been called correctly",
		{ "x", "north", 0, 30 }, { Testing.get_last_call("navigate.go.axis") })
	-- error while navigating
	Testing.reset_fns()
	Testing.set_return("navigate.go.axis", true, nil, 25)
	Testing.set_return("navigate.go.axis", false, "test: path blocked", 7)
	current_pos = {
		x = 0, y = 0, z = 0, dir = "north"
	}
	target_pos = {
		x = 30, y = -25, z = 10, dir = "south"
	}
	ok, err, trav, new_pos = navigate.go.coords(current_pos, target_pos, nil, "yzx")
	Testing.assert("go.coords returned false", { false }, { ok })
	Testing.assert("go.coords returned the correct error", { "test: path blocked" }, { err })
	Testing.assert("go.coords returned the total distance travelled", { 32 }, { trav })
	Testing.assert("go.coords returned the new position",
		{ x = 0, y = -25, z = 7, dir = "north" }, new_pos
	)
	Testing.assert("go.axis has been called two times",
		{ 2 }, { Testing.get_call_amount("navigate.go.axis") }
	)
	Testing.assert("go.axis has been called correctly",
		{ "y", "north", 0, -25 }, { Testing.get_nth_call("navigate.go.axis", 1) })
	Testing.assert("go.axis has been called correctly",
		{ "z", "north", 0, 10 }, { Testing.get_nth_call("navigate.go.axis", 2) })
	Testing.assert("current_pos.dir has not been changed", { "north" }, { current_pos.dir })
end)
-- reset overwritten lib import
navigate = require("lib.navigate")

Testing.test("navigate.go.coords_or_return", function()
	navigate.go.coords = Testing.fn("navigate.go.coords", true)
	local current_pos = {
		x = 0, y = 0, z = 0, dir = "north"
	}
	local target_pos = {
		x = 30, y = -25, z = 10, dir = "south"
	}
	Testing.set_return("navigate.go.coords", true, nil, 65, target_pos)
	local ok, err, trav, new_pos = navigate.go.coords_or_return(current_pos, target_pos, nil, "xyz")
	Testing.assert("go.coords_or_return returned true", { true }, { ok })
	Testing.assert("go.coords_or_return returned no error", {}, { err })
	Testing.assert("go.coords_or_return returned the total distance travelled", { 65 }, { trav })
	Testing.assert("go.coords_or_return returned the new position",
		{ x = 30, y = -25, z = 10, dir = "south" }, new_pos
	)
	Testing.assert("go.coords has been called correctly",
		{ current_pos, target_pos, nil, "xyz" }, { Testing.get_last_call("navigate.go.coords") }
	)
	-- fail on initial move
	Testing.reset_fns()
	Testing.set_return("navigate.go.coords", false, "test: path blocked", 32, { x = 30, y = -2, z = 0 })
	Testing.set_return("navigate.go.coords", true, nil, 32, current_pos)
	current_pos = {
		x = 0, y = 0, z = 0, dir = "north"
	}
	target_pos = {
		x = 30, y = -25, z = 10, dir = "south"
	}
	ok, err, trav, new_pos = navigate.go.coords_or_return(current_pos, target_pos, nil, "xyz")
	Testing.assert("go.coords_or_return returned false", { false }, { ok })
	Testing.assert("go.coords_or_return returned the correct error", { "test: path blocked" }, { err })
	Testing.assert("go.coords_or_return returned the total distance travelled", { 32 }, { trav })
	Testing.assert("go.coords_or_return returned the new position",
		current_pos, new_pos
	)
	Testing.assert("go.coords has been called correctly",
		{ current_pos, target_pos, nil, "xyz" }, { Testing.get_nth_call("navigate.go.coords", 1) }
	)
	Testing.assert("go.coords has been called correctly when returning",
		{ { x = 30, y = -2, z = 0 }, current_pos, nil, "zyx" }, { Testing.get_last_call("navigate.go.coords") }
	)
	-- fail on initial move, also fail on return move
	Testing.reset_fns()
	Testing.set_return("navigate.go.coords", false, "test: path blocked", 32, { x = 30, y = -2, z = 0 })
	Testing.set_return("navigate.go.coords", false, "test: path blocked", 5, { x = 27, y = 0, z = 0 })
	current_pos = {
		x = 0, y = 0, z = 0, dir = "north"
	}
	target_pos = {
		x = 30, y = -25, z = 10, dir = "south"
	}
	ok, err, trav, new_pos = navigate.go.coords_or_return(current_pos, target_pos, nil, "xyz")
	Testing.assert("go.coords_or_return returned false", { false }, { ok })
	Testing.assert("go.coords_or_return returned the correct error",
		{ "could not return after failed initial move" }, { err }
	)
	Testing.assert("go.coords_or_return returned the total distance while returning", { 5 }, { trav })
	Testing.assert("go.coords_or_return returned the new position",
		{ x = 27, y = 0, z = 0 }, new_pos
	)
	Testing.assert("go.coords has been called correctly",
		{ current_pos, target_pos, nil, "xyz" }, { Testing.get_nth_call("navigate.go.coords", 1) }
	)
	Testing.assert("go.coords has been called correctly when returning",
		{ { x = 30, y = -2, z = 0 }, current_pos, nil, "zyx" }, { Testing.get_last_call("navigate.go.coords") }
	)
end)
-- reset overwritten lib import
navigate = require("lib.navigate")
