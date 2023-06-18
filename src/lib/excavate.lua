---@diagnostic disable-next-line: unknown-cast-variable
---@cast turtle turtle

local dig = require("lib.dig")
local util = require("lib.util")
-- This is used because it broadcasts our position when moving
local nav = require("lib.navigate")
local go = nav.go
local turn = nav.turn

-- TODO handle unbreakable blocks

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
	local ok = true
	local err
	for _ = 1, n, 1 do
		ok, err = tunnel.forward_push()
		if not ok then break end
	end
	return ok, err
end

-- Same as tunnel.forward but also dig upwards.
---@param n number
function tunnel.forward_two(n)
	local ok = true
	local err
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
	local ok = true
	local err
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
	turn()
	local ok, err = tunnel.forward(n)
	turn()
	return ok, err
end

---@param n number
function tunnel.up(n)
	local ok = true
	local err
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
	local ok = true
	local err
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
	local ok = true
	local err
	turtle.turnLeft()
	ok, err = tunnel.forward(n)
	turtle.turnRight()
	return ok, err
end

---@param n number
function tunnel.right(n)
	local ok = true
	local err
	turtle.turnRight()
	ok, err = tunnel.forward(n)
	turtle.turnLeft()
	return ok, err
end

---@param l number
---@param w number
---@param tunnel_fw fun(n: number)
local function dig_rectangle(l, w, tunnel_fw)
	local fuel_target = l * 2 * w * 2
	if turtle.getFuelLevel() < fuel_target then
		-- TODO determine fuel source somewhere
		util.refuel(fuel_target)
	end

	local rpos = 1
	for i = 1, w, 1 do
		tunnel_fw(l - 1)
		rpos = rpos * -1
		-- FIXME what happens when the chest is placed into an unloaded chunk?
		util.dump()
		-- Prepare for next column
		if i < w then
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
		go.back(l - 1)
		turtle.turnLeft()
	else
		turtle.turnRight()
	end
	go.forward(w - 1)
	turtle.turnRight()
	return true
end

---@param l number
---@param w number
---@param h number
local function dig_cuboid(l, w, h)
	-- TODO return to starting position after failure
	local fuel_target = h * 3
	if turtle.getFuelLevel() < fuel_target then
		-- TODO determine fuel source somewhere
		util.refuel(fuel_target)
	end
	local i = h
	while (i > 0) do
		if math.floor(i / 3) > 0 then
			tunnel.down(1)
			dig_rectangle(l, w, tunnel.forward_three)
			tunnel.down(1)
			i = i - 3
		elseif math.floor(i / 2) > 0 then
			tunnel.down(1)
			dig_rectangle(l, w, tunnel.forward_two)
			i = i - 2
		else
			dig_rectangle(l, w, tunnel.forward)
			i = i - 1
		end
		if (i > 0) then
			tunnel.down(1)
		end
	end
	for _ = 1, h - 1 do
		go.up()
	end
	util.dump()
	return true
end

---@param l number
---@param w number
local function dig_cuboid_bedrock(l, w)
	-- TODO return to starting position after failure
	local target_fuel = l * 2 * w * 2 + 10
	if turtle.getFuelLevel() < target_fuel then
		util.refuel(target_fuel)
	end

	local function scrape()
		local hpos = 0
		while true do
			local ok, _ = dig.down()
			if not ok then break end
			go.down()
			hpos = hpos + 1
		end
		go.up(hpos)
	end

	local rpos = 1
	for i = 1, w do
		for _ = 1, l - 1 do
			scrape()
			tunnel.forward_push()
		end
		scrape()
		util.dump(nil, nil, nil, "down")
		if i < w then
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
		go.back(l - 1)
		turtle.turnLeft()
	else
		turtle.turnRight()
	end
	go.forward(w - 1)
	turtle.turnRight()
	return true
end

return {
	dig_rectangle = dig_rectangle,
	dig_cuboid = dig_cuboid,
	dig_cuboid_bedrock = dig_cuboid_bedrock,
	tunnel = tunnel
}
