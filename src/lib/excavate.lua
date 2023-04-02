-- This is only useful for development
if not turtle then
	---@diagnostic disable-next-line: lowercase-global
	turtle = {}
	---@diagnostic disable-next-line: unknown-cast-variable
	---@cast turtle turtle
end

local util = require("lib.util")
-- This is used because it broadcasts our position when moving
local go = require("lib.navigate").go

-- TODO handle unbreakable blocks

local dig = {}

function dig.forward()
	local ok = true
	local err
	while turtle.detect() do
		ok, err = turtle.dig()
		if not ok then break end
	end
	return ok, err
end

function dig.up()
	local ok = true
	local err
	while turtle.detectUp() do
		ok, err = turtle.digUp()
		if not ok then break end
	end
	return ok, err
end

function dig.down()
	local ok = true
	local err
	while turtle.detectDown() do
		ok, err = turtle.digDown()
		if not ok then break end
	end
	return ok, err
end

local tunnel = {}
-- Dig a single block and move forward.
function tunnel.forward_push()
	local ok, err = dig.forward()
	if not ok then return false, err end
	ok, err = go.forward()
	return ok, err
end

---@param n number
function tunnel.forward(n)
	local ok, err
	for _ = 1, n, 1 do
		ok, err = tunnel.forward_push()
		if not ok then break end
	end
	return ok, err
end

-- Same as tunnel.forward but also dig upwards.
---@param n number
function tunnel.forward_two(n)
	local ok, err
	for _ = 1, n, 1 do
		ok, err = tunnel.forward_push()
		if not ok then break end
		ok, err = dig.up()
		if not ok then break end
	end
	return ok, err
end

-- Same as tunnel.forward but also dig upwards and downwards.
---@param n number
function tunnel.forward_three(n)
	local ok, err
	for _ = 1, n, 1 do
		ok, err = tunnel.forward_push()
		if not ok then break end
		ok, err = dig.up()
		if not ok then break end
		ok, err = dig.down()
		if not ok then break end
	end
	return ok, err
end

---@param n number
function tunnel.back(n)
	util.turn()
	local ok, err = tunnel.forward(n)
	util.turn()
	return ok, err
end

---@param n number
function tunnel.up(n)
	local ok, err
	for _ = 1, n, 1 do
		ok, err = dig.up()
		if not ok then break end
		ok, err = go.up()
		if not ok then break end
	end
	return ok, err
end

---@param n number
function tunnel.down(n)
	local ok, err
	for _ = 1, n, 1 do
		ok, err = dig.down()
		if not ok then break end
		ok, err = go.down()
		if not ok then break end
	end
	return ok, err
end

---@param n number
function tunnel.left(n)
	local ok, err
	turtle.turnLeft()
	ok, err = tunnel.forward(n)
	turtle.turnRight()
	return ok, err
end

---@param n number
function tunnel.right(n)
	local ok, err
	turtle.turnRight()
	ok, err = tunnel.forward(n)
	turtle.turnLeft()
	return ok, err
end

---@param x number
---@param y number
---@param tunnel_fw fun(n: number)
local function dig_rectangle(x, y, tunnel_fw)
	while turtle.getFuelLevel() < x * 2 or turtle.getFuelLevel() < 1000 do
		util.refuel()
	end

	local rpos = 1
	for i = 1, y, 1 do
		tunnel_fw(x - 1)
		rpos = rpos * -1
		util.dump()
		-- Prepare for next column
		if i < y then
			if rpos == -1 then
				turtle.turnRight()
				tunnel_fw(1)
				turtle.turnRight()
			else
				turtle.turnLeft()
				tunnel_fw(1)
				turtle.turnLeft()
			end
		end
	end
	if rpos == -1 then
		go.back(x - 1)
		turtle.turnLeft()
	else
		turtle.turnRight()
	end
	go.forward(y - 1)
	turtle.turnRight()
	return true
end

---@param x number
---@param y number
---@param z number
local function dig_cuboid(x, y, z)
	local i = z
	while (i > 0) do
		if math.floor(i / 3) > 0 then
			tunnel.down(1)
			dig_rectangle(x, y, tunnel.forward_three)
			tunnel.down(1)
			i = i - 3
		elseif math.floor(i / 2) > 0 then
			tunnel.down(1)
			dig_rectangle(x, y, tunnel.forward_two)
			i = i - 2
		else
			dig_rectangle(x, y, tunnel.forward)
			i = i - 1
		end
		if (i > 0) then
			tunnel.down(1)
		end
	end
	for _ = 1, z - 1 do
		go.up()
	end
	util.dump()
	return true
end

---@param x number
---@param y number
local function dig_cuboid_bedrock(x, y)
	do
		local fuel = turtle.getFuelLevel()
		while fuel < x * 6 + y * 2 or fuel < 1000 do
			util.refuel()
		end
	end

	local function scrape()
		local zpos = 0
		while true do
			local ok, _ = dig.down()
			if not ok then break end
			go.down()
			zpos = zpos + 1
		end
		go.up(zpos)
	end

	local rpos = 1
	for i = 1, y do
		for j = 1, x - 1 do
			scrape()
			tunnel.forward_push()
		end
		scrape()
		if i < y then
			if (rpos == 1) then
				turtle.turnRight()
				tunnel.forward_push()
				turtle.turnRight()
			else
				turtle.turnLeft()
				tunnel.forward_push()
				turtle.turnLeft()
			end
		end
		rpos = rpos * -1
	end
	if rpos == -1 then
		go.back(x - 1)
		turtle.turnLeft()
	else
		turtle.turnRight()
	end
	go.forward(y - 1)
	turtle.turnRight()
	return true
end

return {
	dig = dig,
	dig_rectangle = dig_rectangle,
	dig_cuboid = dig_cuboid,
	dig_cuboid_bedrock = dig_cuboid_bedrock,
	tunnel = tunnel
}
