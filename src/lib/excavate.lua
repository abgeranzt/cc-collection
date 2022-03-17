local dig = {
	forward = function()
		while turtle.detect() do
			if not turtle.dig() then
				return false
			end
		end
		return true
	end,
	up = function()
		while turtle.detectUp() do
			if not turtle.digUp() then
				return false
			end
		end
		return true
	end
}

local function turn()
	turtle.turnRight()
	turtle.turnRight()
end

local tunnel = {forward = {}}

function tunnel.back(x)
	for i = 1, x, 1 do
		if not turtle.back() then
			turn()
			dig.forward()
			turn()
			turtle.back()
		end
	end
end

function tunnel.down(z)
	for i = 1, z, 1 do
		turtle.digDown()
		turtle.down()
	end
end

-- Dig a single block and move forward
function tunnel.forward.push()
	if dig.forward() then
		turtle.forward()
		return true
	else
		return false
	end
end

-- Dig x blocks and move forward
function tunnel.forward.one(x)
	for i = 1, x, 1 do
		if not tunnel.forward.push() then
			tunnel.back(i)
			turtle.turnLeft()
			turtle.turnLeft()
			return false
		end
	end
	return true
end

-- Same as tunnel.forward.one(x) but also dig upwards.
function tunnel.forward.two(x)
	for i = 1, x, 1 do
		if not tunnel.forward.push() then
			tunnel.back(i)
			turtle.turnLeft()
			turtle.turnLeft()
			return false
		end
		dig.up()
	end
	return true
end

-- Same as tunnel.forward.one(x) but also dig upwards and downwards.
function tunnel.forward.three(x)
	for i = 1, x, 1 do
		if not tunnel.forward.push() then
			tunnel.back(i)
			turtle.turnLeft()
			turtle.turnLeft()
			return false
		end
		dig.up()
		turtle.digDown()
	end
	return true
end

local pos = {x = 1, y = 1, z = 1}

-- TODO handle unbreakable blocks
-- TODO empty into chest
function dig_rectangle(x, y, tunnel_fw)
	local rpos = 1
	for i = 1, y, 1 do
		if tunnel_fw(x - 1) then
			pos.x = pos.x + (x - 1) * rpos
			rpos = rpos * -1
		end
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
		turtle.turnLeft()
	else
		turtle.turnRight()
	end
	for i = 1, y - 1, 1 do
		turtle.forward()
	end
	turtle.turnRight()
	return true
end

function dig_cuboid(x, y, z)
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
	for i = 1, z, 1 do
		turtle.up()
	end
	return true
end
