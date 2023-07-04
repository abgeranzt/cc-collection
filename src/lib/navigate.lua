---@diagnostic disable-next-line: unknown-cast-variable
---@cast os os

-- TODO handle navigation errrors by returning to the original position

-- Navigate using relative coordinates.
-- Not equivalent to Minecraft coordinates
local go = {}
local MAX_TRIES = 5

local reverse = {
	forward = "back",
	back = "forward",
	up = "down",
	down = "up"
}

for _, dir in ipairs({ "forward", "back", "up", "down" }) do
	---@param n number | nil Distance
	---@return boolean success Success
	---@return string | nil error Error message
	---@return integer trav Distance travelled
	go[dir] = function(n)
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

	---@param n number | nil Distance
	---@return boolean success Success
	---@return string | nil error Error message
	---@return integer trav Distance travelled
	go[dir .. "or_return"] = function(n)
		local ok, err, trav = go[dir](n)
		if not ok then
			local trav_back
			ok, err, trav_back = go[reverse[dir]](trav)
			if not ok then
				return false, "could not return after failed initial move", trav_back
			end
			return false, err, trav
		end
		return true, nil, trav
	end
end

---@param n number | nil Distance
---@return boolean success Success
---@return string | nil error Error message
---@return integer trav Distance travelled
function go.left(n)
	turtle.turnLeft()
	local ok, err, trav = go.forward(n)
	if ok then
		turtle.turnRight()
		return true, nil, trav
	else
		turtle.turnRight()
		return false, err, trav
	end
end

function go.left_or_return(n)
	turtle.turnLeft()
	local ok, err, trav = go.forward(n)
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
	if not ok then
		local trav_back
		ok, err, trav_back = go.left(trav)
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
		local go_func_fw = go_lib.forward
		local go_func_bk = go_lib.back
		if current_pos.dir == "west" then
			go_func_fw = go_lib.back
			go_func_bk = go_lib.forward
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
		local go_func_fw = go_lib.forward
		local go_func_bk = go_lib.back
		if current_pos.dir == "north" then
			go_func_fw = go_lib.back
			go_func_bk = go_lib.forward
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
