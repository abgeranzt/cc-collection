---@diagnostic disable-next-line: unknown-cast-variable
---@cast os os

-- TODO handle navigation errrors by returning to the original position

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

---@param dir cmd_direction Direction
---@param n number | nil Distance
---@return boolean success Success
---@return string | nil error Error message
---@return integer trav Distance travelled
local function _go(dir, n)
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

---@param dir cmd_direction Direction
---@param n number | nil Distance
---@return boolean success Success
---@return string | nil error Error message
---@return integer trav Distance travelled
local function _go_or_return(dir, n)
	local ok, err, trav = _go(dir, n)
	if not ok then
		local trav_back
		ok, err, trav_back = _go(reverse[dir], trav)
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
	return _go("forward", n)
end

---@param n number | nil Distance
---@return boolean success Success
---@return string | nil error Error message
---@return integer trav Distance travelled
function go.forward_or_return(n)
	return _go_or_return("forward", n)
end

---@param n number | nil Distance
---@return boolean success Success
---@return string | nil error Error message
---@return integer trav Distance travelled
function go.back(n)
	return _go("back", n)
end

---@param n number | nil Distance
---@return boolean success Success
---@return string | nil error Error message
---@return integer trav Distance travelled
function go.back_or_return(n)
	return _go_or_return("back", n)
end

---@param n number | nil Distance
---@return boolean success Success
---@return string | nil error Error message
---@return integer trav Distance travelled
function go.up(n)
	return _go("up", n)
end

---@param n number | nil Distance
---@return boolean success Success
---@return string | nil error Error message
---@return integer trav Distance travelled
function go.up_or_return(n)
	return _go_or_return("up", n)
end

---@param n number | nil Distance
---@return boolean success Success
---@return string | nil error Error message
---@return integer trav Distance travelled
function go.down(n)
	return _go("down", n)
end

---@param n number | nil Distance
---@return boolean success Success
---@return string | nil error Error message
---@return integer trav Distance travelled
function go.down_or_return(n)
	return _go_or_return("down", n)
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
	local ok, err, trav = _go("forward", n)
	turtle.turnRight()
	if not ok then
		local trav_back
		ok, err, trav_back = _go("right", trav)
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
	local ok, err, trav = _go("forward", n)
	turtle.turnLeft()
	if not ok then
		local trav_back
		ok, err, trav_back = _go("left", trav)
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
local function turn_dir(current_dir, target_dir)
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

-- Attempt to navigate the target position.
-- The lib_go parameter accepts any interface that implements basic turtle movement.
-- This allows overriding the behavior while moving, which is useful for tasks
-- such as mining blocks or interacting with the environment.
---@param current_pos gpslib_position
---@param target_pos gpslib_position
---@param lib_go lib_go | nil Interface implementing basic navigation functions
function go.coords(current_pos, target_pos, lib_go)
	if not lib_go then
		lib_go = go
	end
	local ok, err
	-- TODO current_pos.dir is updated manually, remove this behaviour once a wrapper for turtle.turnX has been written
	if current_pos.x ~= target_pos.x then
		local go_func_fw = lib_go.forward
		local go_func_bk = lib_go.back
		if current_pos.dir == "west" then
			go_func_fw = lib_go.back
			go_func_bk = lib_go.forward
		else
			if current_pos.dir == "north" then
				turtle.turnRight()
			elseif current_pos.dir == "south" then
				turtle.turnLeft()
			end
			current_pos.dir = "east"
		end
		local dist = math.abs(current_pos.x - target_pos.x)
		if current_pos.x < target_pos.x then
			ok, err = go_func_fw(dist)
		else
			ok, err = go_func_bk(dist)
		end
		if not ok then
			return false, err
		end
	end
	if current_pos.z ~= target_pos.z then
		local go_func_fw = lib_go.forward
		local go_func_bk = lib_go.back
		if current_pos.dir == "north" then
			go_func_fw = lib_go.back
			go_func_bk = lib_go.forward
		else
			if current_pos.dir == "east" then
				turtle.turnRight()
			elseif current_pos.dir == "west" then
				turtle.turnLeft()
			end
			current_pos.dir = "south"
		end
		local dist = math.abs(current_pos.z - target_pos.z)
		if current_pos.z < target_pos.z then
			ok, err = go_func_fw(dist)
		else
			ok, err = go_func_bk(dist)
		end
		if not ok then
			return false, err
		end
	end
	local dist = math.abs(current_pos.y - target_pos.y)
	if current_pos.y < target_pos.y then
		ok, err = lib_go.up(dist)
	else
		ok, err = lib_go.down(dist)
	end
	current_pos.dir = turn_dir(current_pos.dir, target_pos.dir)
	return ok and ok, nil or false, err
end

return {
	go = go,
	turn = turn,
	turn_dir = turn_dir
}
