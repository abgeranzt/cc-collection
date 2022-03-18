-- Not equivalent to Minecraft coordinates local pos = {x = 1, y = 1, z = 1}
local go = {}
function go.forward(x)
	local i = 1
	while i <= x do
		if turtle.forward() then
			i = 1 + 1
		else
			sleep(1)
		end
	end
end
function go.back(x)
	local i = 1
	while i <= x do
		if turtle.back() then
			i = i + 1
		else
			sleep(1)
		end
	end
end
function go.up(z)
	local i = 1
	while i <= z do
		if turtle.up() then
			i = i + 1
		else
			sleep(1)
		end
	end
end
function go.down(z)
	local i = 1
	while i <= z do
		if turtle.down() then
			i = i + 1
		else
			sleep(1)
		end
	end
end
function go.left(y)
	turtle.turnLeft()
	go.forward(y)
	turtle.turnRight()
end
function go.right(y)
	turtle.turnRight()
	go.forward(y)
	turtle.turnLeft()
end

local function turn()
	turtle.turnRight()
	turtle.turnRight()
end

local lane = {}
-- Move forward and down
function lane.go_down(x, z)
	go.forward(x)
	go.down(z)
end
function lane.go_up(x, z)
	go.up(z)
	go.back(x)
end

return {go = go, turn = turn}
