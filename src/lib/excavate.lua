local util = require("util")

-- TODO handle unbreakable blocks

local pos = { x = 1, y = 1, z = 1 }
local dig = {}

function dig.forward()
	while turtle.detect() do
		if not turtle.dig() then
			return false
		end
	end
	return true
end

function dig.up()
	while turtle.detectUp() do
		if not turtle.digUp() then
			return false
		end
	end
	return true
end

local tunnel = { forward = {} }
-- Dig a single block and move forward.
function tunnel.forward.push()
	dig.forward()
	turtle.forward()
end

--- @param n number
function tunnel.forward.one(n)
	for _ = 1, n, 1 do
		tunnel.forward.push()
	end
end

-- Same as tunnel.forward.one but also dig upwards.
--- @param n number
function tunnel.forward.two(n)
	for _ = 1, n, 1 do
		tunnel.forward.push()
		dig.up()
	end
end

-- Same as tunnel.forward.one but also dig upwards and downwards.
--- @param n number
function tunnel.forward.three(n)
	for _ = 1, n, 1 do
		tunnel.forward.push()
		dig.up()
		turtle.digDown()
	end
end

--- @param n number
function tunnel.up(n)
	for _ = 1, n, 1 do
		dig.up()
		turtle.up()
	end
end

-- Dig n blocks and move downwards.
--- @param n number
function tunnel.down(n)
	for _ = 1, n, 1 do
		turtle.digDown()
		turtle.down()
	end
end

--- @param x number
--- @param y number
--- @param tunnel_fw fun(n: number)
local function dig_rectangle(x, y, tunnel_fw)
	local rpos = 1
	for i = 1, y, 1 do
		tunnel_fw(x - 1)
		pos.x = pos.x + (x - 1) * rpos
		rpos = rpos * -1
		util.dump()
		-- Prepare for next column
		if i < y then
			if rpos == -1 then
				turtle.turnRight()
				tunnel_fw(1)
				pos.y = pos.y + 1
				turtle.turnRight()
			else
				turtle.turnLeft()
				tunnel_fw(1)
				pos.y = pos.y + 1
				turtle.turnLeft()
			end
		end
	end
	if rpos == -1 then
		for i = 1, x - 1, 1 do
			turtle.back()
		end
		pos.x = 1
		rpos = rpos * -1
		turtle.turnLeft()
	else
		turtle.turnRight()
	end
	for i = 1, y - 1, 1 do
		turtle.forward()
	end
	pos.y = 1
	turtle.turnRight()
	return true
end

--- @param x number
--- @param y number
--- @param z number
local function dig_cuboid(x, y, z)
	local i = z
	while (i > 0) do
		if math.floor(i / 3) > 0 then
			tunnel.down(2)
			pos.z = pos.z + 2
			dig_rectangle(x, y, tunnel.forward.three)
			pos.z = pos.z + 1
			tunnel.down(1)
			i = i - 3
		elseif math.floor(i / 2) > 0 then
			tunnel.down(2)
			pos.z = pos.z + 2
			dig_rectangle(x, y, tunnel.forward.two)
			i = i - 2
		else
			tunnel.down(1)
			pos.z = pos.z + 1
			dig_rectangle(x, y, tunnel.forward.one)
			i = i - 1
		end
	end
	for _ = 1, z, 1 do
		turtle.up()
	end
	pos.z = 1
	dump()
	return true
end

return {
	dig = dig,
	dig_cuboid = dig_cuboid,
	dig_rectangle = dig_rectangle,
	tunnel = tunnel
}
