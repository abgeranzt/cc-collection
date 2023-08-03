---@diagnostic disable-next-line: unknown-cast-variable
---@cast os os

local util = require("lib.util")

-- TODO is returning trav actually required?

-- Navigate using relative coordinates.
-- Not equivalent to Minecraft coordinates
---@class lib_go
local go = {}
local MAX_TRIES = 5

local reverse = {
	forward = "back",
	back = "forward",
	up = "down",
	down = "up"
}

---@param dir direction_turtle Direction
---@param n number | nil Distance
---@return boolean success Success
---@return string | nil error Error message
---@return integer trav Distance travelled
function go._go(dir, n)
	n = n or 1
	local rem = n
	local try = 1
	local ok, err
	while rem > 0 do
		if try > MAX_TRIES then
			return false, err, n - rem
		end

		ok, err = turtle[dir]()
		if ok then
			os.queueEvent("pos_update")
			rem = rem - 1
			try = 1
		else
			try = try + 1
			sleep(1)
		end
	end
	return true, nil, n - rem
end

---@param dir direction_turtle Direction
---@param n number | nil Distance
---@return boolean success Success
---@return string | nil error Error message
---@return integer trav Distance travelled
function go._go_or_return(dir, n)
	local ok, err, trav = go._go(dir, n)
	if not ok then
		local trav_back
		ok, _, trav_back = go._go(reverse[dir], trav)
		if not ok then
			return false, "could not return after failed initial move", trav_back
		end
		return false, err, trav
	end
	return true, nil, trav
end

---@param n number | nil Distance
---@return boolean success Success
---@return string | nil error Error message
---@return integer trav Distance travelled
function go.forward(n)
	return go._go("forward", n)
end

---@param n number | nil Distance
---@return boolean success Success
---@return string | nil error Error message
---@return integer trav Distance travelled
function go.forward_or_return(n)
	return go._go_or_return("forward", n)
end

---@param n number | nil Distance
---@return boolean success Success
---@return string | nil error Error message
---@return integer trav Distance travelled
function go.back(n)
	return go._go("back", n)
end

---@param n number | nil Distance
---@return boolean success Success
---@return string | nil error Error message
---@return integer trav Distance travelled
function go.back_or_return(n)
	return go._go_or_return("back", n)
end

---@param n number | nil Distance
---@return boolean success Success
---@return string | nil error Error message
---@return integer trav Distance travelled
function go.up(n)
	return go._go("up", n)
end

---@param n number | nil Distance
---@return boolean success Success
---@return string | nil error Error message
---@return integer trav Distance travelled
function go.up_or_return(n)
	return go._go_or_return("up", n)
end

---@param n number | nil Distance
---@return boolean success Success
---@return string | nil error Error message
---@return integer trav Distance travelled
function go.down(n)
	return go._go("down", n)
end

---@param n number | nil Distance
---@return boolean success Success
---@return string | nil error Error message
---@return integer trav Distance travelled
function go.down_or_return(n)
	return go._go_or_return("down", n)
end

---@param n number | nil Distance
---@return boolean success Success
---@return string | nil error Error message
---@return integer trav Distance travelled
function go.left(n)
	turtle.turnLeft()
	local ok, err, trav = go.forward(n)
	turtle.turnRight()
	return ok, err, trav
end

---@param n number | nil Distance
---@return boolean success Success
---@return string | nil error Error message
---@return integer trav Distance travelled
function go.left_or_return(n)
	turtle.turnLeft()
	local ok, err, trav = go._go("forward", n)
	turtle.turnRight()
	if not ok then
		local trav_back
		ok, err, trav_back = go.right(trav)
		if not ok then
			return false, "could not return after failed initial move", trav_back
		end
		return false, err, trav
	end
	return true, nil, trav
end

---@param n number | nil Distance
---@return boolean success Success
---@return string | nil error Error message
---@return integer trav Distance travelled
function go.right(n)
	turtle.turnRight()
	local ok, err, trav = go.forward(n)
	turtle.turnLeft()
	return ok, err, trav
end

---@param n number | nil Distance
---@return boolean success Success
---@return string | nil error Error message
---@return integer trav Distance travelled
function go.right_or_return(n)
	turtle.turnRight()
	local ok, err, trav = go._go("forward", n)
	turtle.turnLeft()
	if not ok then
		local trav_back
		ok, err, trav_back = go._go("left", trav)
		if not ok then
			return false, "could not return after failed initial move", trav_back
		end
		return false, err, trav
	end
	return true, nil, trav
end

local function turn()
	turtle.turnRight()
	turtle.turnRight()
	return true
end

---@param current_dir gpslib_direction Current direction
---@param target_dir gpslib_direction Target direction
---@return gpslib_direction new_dir Same as target_dir
function go.turn_dir(current_dir, target_dir)
	local function nothing()
	end
	local select_action = {
		north = {
			north = nothing,
			east = turtle.turnRight,
			south = turn,
			west = turtle.turnLeft,
		},
		east = {
			north = turtle.turnLeft,
			east = nothing,
			south = turtle.turnRight,
			west = turn,
		},
		south = {
			north = turn,
			east = turtle.turnLeft,
			south = nothing,
			west = turtle.turnRight,
		},
		west = {
			north = turtle.turnRight,
			east = turn,
			south = turtle.turnLeft,
			west = nothing
		}
	}
	select_action[current_dir][target_dir]()
	return target_dir
end

-- Attempt to navigate along the specified axis
-- The lib_go parameter accepts any interface that implements basic turtle movement.
-- This allows overriding the behavior while moving, which is useful for tasks
-- such as mining blocks or interacting with the environment.
-- The order in which the axis are traversed can be set by the axis_order parameter
---@param axis lib_go_axis The axis to move on
---@param current_dir gpslib_direction The current direction
---@param current_point integer The current point on the axis
---@param target_point integer The target point on the axis
---@param lib_go lib_go | nil Interface implementing basic navigation functions
---@return boolean success Success
---@return string | nil error Error message
---@return integer trav Distance travelled
function go.axis(axis, current_dir, current_point, target_point, lib_go)
	lib_go = lib_go and lib_go or go
	if current_point == target_point then
		return true, nil, 0
	end
	local distance = math.abs(current_point - target_point)
	if axis == "y" then
		if target_point > current_point then
			return lib_go.up(distance)
		else
			return lib_go.down(distance)
		end
	elseif axis == "x" then
		go.turn_dir(current_dir, "east")
		local ok, err, trav
		if target_point > current_point then
			ok, err, trav = lib_go.forward(distance)
		else
			ok, err, trav = lib_go.back(distance)
		end
		go.turn_dir("east", current_dir)
		return ok, err, trav
	end
	-- z
	go.turn_dir(current_dir, "south")
	local ok, err, trav
	if target_point > current_point then
		ok, err, trav = lib_go.forward(distance)
	else
		ok, err, trav = lib_go.back(distance)
	end
	go.turn_dir("south", current_dir)
	return ok, err, trav
end

-- Attempt to navigate the target position.
-- The lib_go parameter accepts any interface that implements basic turtle movement.
-- This allows overriding the behavior while moving, which is useful for tasks
-- such as mining blocks or interacting with the environment.
-- The order in which the axis are traversed can be set by the axis_order parameter
---@param current_pos gpslib_position The current position
---@param target_pos gpslib_position The target position
---@param lib_go lib_go | nil Interface implementing basic navigation functions
---@param axis_order lib_go_axis_order | nil The order in which to travel along the axes
---@return boolean success Success
---@return string | nil error Error message
---@return integer trav Distance travelled
---@return gpslib_position new_pos The new position
function go.coords(current_pos, target_pos, lib_go, axis_order)
	axis_order = axis_order and axis_order or "xyz"
	local ok, err, trav
	local trav_all = 0
	local new_pos = util.table_copy(current_pos)
	for i = 1, 3 do
		local axis = string.sub(axis_order, i, i)
		---@cast axis lib_go_axis
		ok, err, trav = go.axis(axis, current_pos.dir, current_pos[axis], target_pos[axis], lib_go)
		trav_all = trav_all + trav
		local delta = current_pos[axis] < target_pos[axis] and trav or trav * -1
		new_pos[axis] = new_pos[axis] + delta
		if not ok then
			return false, err, trav_all, new_pos
		end
	end
	new_pos.dir = go.turn_dir(current_pos.dir, target_pos.dir)
	return true, nil, trav_all, new_pos
end

-- Attempt to navigate the target position and return on the same path after encountering an obstacle.
-- The lib_go parameter accepts any interface that implements basic turtle movement.
-- This allows overriding the behavior while moving, which is useful for tasks
-- such as mining blocks or interacting with the environment.
-- The order in which the axis are traversed can be set by the axis_order parameter
---@param current_pos gpslib_position The current position
---@param target_pos gpslib_position The target position
---@param lib_go lib_go | nil Interface implementing basic navigation functions
---@param axis_order lib_go_axis_order | nil The order in which to travel along the axes
---@return boolean success Success
---@return string | nil error Error message
---@return integer trav Distance travelled
---@return gpslib_position new_pos The new position
function go.coords_or_return(current_pos, target_pos, lib_go, axis_order)
	axis_order = axis_order or "xyz"
	local ok, err, trav, new_pos = go.coords(current_pos, target_pos, lib_go, axis_order)
	if ok then
		return true, nil, trav, new_pos
	end
	local trav_back
	ok, _, trav_back, new_pos = go.coords(new_pos, current_pos, lib_go, string.reverse(axis_order))
	if not ok then
		return false, "could not return after failed initial move", trav_back, new_pos
	end
	return false, err, trav, new_pos
end

return {
	go = go,
	-- TODO move turn to go.turn
	turn = turn,
}
