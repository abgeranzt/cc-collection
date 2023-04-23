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
				---@diagnostic disable-next-line: undefined-global
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

---@cast go go
return { go = go, turn = turn }
