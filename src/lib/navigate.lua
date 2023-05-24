---@diagnostic disable-next-line: unknown-cast-variable
---@cast os os

-- TODO handle navigation errrors by returning to the original position

-- Navigate using relative coordinates.
-- Not equivalent to Minecraft coordinates
local go = {}
local MAX_TRIES = 5

for _, dir in ipairs({ "forward", "back", "up", "down" }) do
	---@param n number | nil
	go[dir] = function(n)
		n = n or 1
		local try = 1
		local ok, err
		while n > 0 do
			if try > MAX_TRIES then
				return false, err
			end

			ok, err = turtle[dir]()
			if ok then
				os.queueEvent("pos_update")
				n = n - 1
				try = 1
			else
				try = try + 1
				sleep(1)
			end
		end
		return true
	end
end

---@param n number | nil
function go.left(n)
	turtle.turnLeft()
	local ok, err = go.forward(n)
	if ok then
		turtle.turnRight()
		return true
	else
		turtle.turnRight()
		return false, err
	end
end

---@param n number | nil
function go.right(n)
	turtle.turnRight()
	local ok, err = go.forward(n)
	if ok then
		turtle.turnLeft()
		return true
	else
		turtle.turnLeft()
		return false, err
	end
end

local function turn()
	turtle.turnRight()
	turtle.turnRight()
	return true
end

---@param current_dir gpslib_direction
---@param target_dir gpslib_direction
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

---@param current_pos gpslib_position
---@param target_pos gpslib_position
---@param go_lib { up: fun(n), down: fun(n), forward: fun(n), back: fun(n) } | nil Interface implementing navigation functions
function go.coords(current_pos, target_pos, go_lib)
	if not go_lib then
		go_lib = go
	end
	local ok, err
	-- TODO current_pos.dir is updated manually, remove this behaviour once a wrapper for turtle.turnX has been written
	if current_pos.x ~= target_pos.x then
		if current_pos.dir == "north" then
			turtle.turnRight()
		elseif current_pos.dir == "south" then
			turtle.turnLeft()
		elseif current_pos.dir == "west" then
			turn()
		end
		current_pos.dir = "east"
		local dist = math.abs(current_pos.x - target_pos.x)
		if current_pos.x < target_pos.x then
			ok, err = go_lib.forward(dist)
		else
			ok, err = go_lib.back(dist)
		end
		if not ok then
			return false, err
		end
	end
	if current_pos.z ~= target_pos.z then
		if current_pos.dir == "north" then
			turn()
		elseif current_pos.dir == "east" then
			turtle.turnRight()
		elseif current_pos.dir == "west" then
			turtle.turnLeft()
		end
		current_pos.dir = "south"
		local dist = math.abs(current_pos.z - target_pos.z)
		if current_pos.z < target_pos.z then
			ok, err = go_lib.forward(dist)
		else
			ok, err = go_lib.back(dist)
		end
		if not ok then
			return false, err
		end
	end
	local dist = math.abs(current_pos.y - target_pos.y)
	if current_pos.y < target_pos.y then
		ok, err = go_lib.up(dist)
	else
		ok, err = go_lib.down(dist)
	end
	current_pos.dir = turn_dir(current_pos.dir, target_pos.dir)
	return ok and ok, nil or false, err
end

---@cast go go
return {
	go = go,
	turn = turn,
	turn_dir = turn_dir
}
