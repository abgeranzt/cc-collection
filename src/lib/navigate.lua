-- TODO handle navigation errrors by returning to the original position

-- Navigate using relative coordinates.
-- Not equivalent to Minecraft coordinates
local go = {}
local MAX_TRIES = 5

for _, dir in ipairs({ "forward", "back", "up", "down" }) do
	--- @param n number | nil
	go[dir] = function(n)
		local try = 1
		local success, error
		while n > 0 do
			if try > MAX_TRIES then
				return false, error
			end

			success, error = turtle[dir]()
			if success then
				---@diagnostic disable-next-line: undefined-field
				os.queue_event("gps_update")
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

--- @param n number | nil
function go.left(n)
	turtle.turnLeft()
	local success, error = go.forward(n)
	if success then
		turtle.turnRight()
		return true
	else
		turtle.turnRight()
		return false, error
	end
end

--- @param n number | nil
function go.right(n)
	turtle.turnRight()
	local success, error = go.forward(n)
	if success then
		turtle.turnLeft()
		return true
	else
		turtle.turnLeft()
		return false, error
	end
end

local function turn()
	turtle.turnRight()
	turtle.turnRight()
	return true
end

return { go = go, turn = turn }
