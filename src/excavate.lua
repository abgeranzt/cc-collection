-- excavate.lua - dig in a cuboid shape

-- TODO document usage
-- TODO dunmp to chest on finish/drop-off
-- TODO return to chest - use navigation w/ grid-system
function dig_cuboid(x, y, z)
	local i = z
	while (i > 0) do
		if math.floor(i / 3) > 0 then
			tunnel_down(2)
			turtle.digDown()
			dig_rectangle(x, y, true, true)
			tunnel_down(1)
			i = i - 3
		elseif math.floor(i / 2) > 0 then
			tunnel_down(2)
			dig_rectangle(x, y, true, false)
			i = i - 2
		else
			tunnel_down(1)
			dig_rectangle(x, y, false, false)
			i = i - 1
		end
	end
	for i = 1, z, 1 do
		turtle.up()
	end
end

function dig_rectangle(x, y, up, down)
	local pos = 1
	local tunnel_forward = fn_tunnel_forward(up, down)
	for i = 1, y, 1 do
		tunnel_forward(x - 1)
		pos = pos * -1
		-- Prepare for next column
		if i < y then
			if pos == -1 then
				turtle.turnRight()
				tunnel_forward(1)
				turtle.turnRight()
			else
				turtle.turnLeft()
				tunnel_forward(1)
				turtle.turnLeft()
			end
		end
	end
	if pos == -1 then
		for i = 1, x - 1, 1 do
			turtle.back()
		end
		turtle.turnLeft()
	else
		turtle.turnRight()
	end
	for i = 1, y - 1, 1 do
		turtle.forward()
	end
	turtle.turnRight()
end

function dig_forward()
	while turtle.detect() do
		turtle.dig()
	end
end

function fn_tunnel_forward(up, down)
	digUp = function() end
	if up then
		digUp = function()
		turtle.digUp()
		end
	end
	digDown = function() end
	if down then
		digDown = function()
			turtle.digDown()
		end
	end
	return function(x)
		for i = 1, x, 1 do
			dig_forward()
			turtle.forward()
			digUp()
			digDown()
		end
	end
end

-- TODO legacy: get rid of this function
--[[
function tunnel_forward(x, up, down)
	up = up or false
	down = down or false
	for i = 1, x, 1 do
		dig_forward()
		turtle.forward()
		if up then
			turtle.digUp()
		end
		if down then
			turtle.digDown()
		end
	end
end
]]--

function tunnel_down(y)
	for i = 1, y, 1 do
		turtle.digDown()
		turtle.down()
	end
end

function main(x, y, z)
	x = x or 0
	y = y or 0
	z = z or 0

	dig_cuboid(x, y, z)
end

-- Coordinate labels not related to Minecraft coordinates
local x, y, z = ...
x = tonumber(x)
y = tonumber(y)
z = tonumber(z)
main(x, y, z)
