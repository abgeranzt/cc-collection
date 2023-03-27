-- TODO handle navigation errors

-- Navigate using relative coordinates.
-- Not equivalent to Minecraft coordinates
local go = {}

--- @param n number | nil
function go.forward(n)
	n = n or 1
	for _ = 1, n, 0 do
		if turtle.forward() then
			_ = _ + 1
		else
			sleep(1)
		end
	end
end

--- @param n number | nil
function go.back(n)
	n = n or 1
	for _ = 1, n, 0 do
		if turtle.back() then
			_ = _ + 1
		else
			sleep(1)
		end
	end
end

--- @param n number | nil
function go.up(n)
	n = n or 1
	for _ = 1, n, 0 do
		if turtle.up() then
			_ = _ + 1
		else
			sleep(1)
		end
	end
end

--- @param n number | nil
function go.down(n)
	n = n or 1
	for _ = 1, n, 0 do
		if turtle.down() then
			_ = _ + 1
		else
			sleep(1)
		end
	end
end

--- @param n number | nil
function go.left(n)
	turtle.turnLeft()
	go.forward(n)
	turtle.turnRight()
end

--- @param n number | nil
function go.right(n)
	turtle.turnRight()
	go.forward(n)
	turtle.turnLeft()
end

local function turn()
	turtle.turnRight()
	turtle.turnRight()
end

-- Export
return { go = go, turn = turn }
