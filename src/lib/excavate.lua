local pos = {x = 1, y = 1, z = 1}

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

local go = {}
function go.forward(x)
	for i = 1, x, 1 do
		turtle.forward()
	end
end
function go.back(x)
	for i = 1, x, 1 do
		turtle.back()
	end
end
function go.up(z)
	for i = 1, z, 1 do
		turtle.up()
	end
end
function go.down(z)
	for i = 1, z, 1 do
		turtle.down()
	end
end

local function turn()
	turtle.turnRight()
	turtle.turnRight()
end

tunnel = {forward = {}}
-- Dig a single block and move forward
function tunnel.forward.push()
	dig.forward()
	turtle.forward()
end
-- Dig x blocks and move forward
function tunnel.forward.one(x)
	for i = 1, x, 1 do
		tunnel.forward.push()
	end
end
-- Same as tunnel.forward.one(x) but also dig upwards.
function tunnel.forward.two(x)
	for i = 1, x, 1 do
		tunnel.forward.push()
		dig.up()
	end
end
-- Same as tunnel.forward.one(x) but also dig upwards and downwards.
function tunnel.forward.three(x)
	for i = 1, x, 1 do
		tunnel.forward.push()
		dig.up()
		turtle.digDown()
	end
end
-- Dig x blocks and move downwards.
function tunnel.down(z)
	for i = 1, z, 1 do
		turtle.digDown()
		turtle.down()
	end
end

local function is_full()
	return turtle.getItemCount(14) > 0
end

local dump = {}
function dump.notify_master()
	msg = os.getComputerLabel() .. ":x:" .. "dumped"
	os.queueEvent("master_msg", msg)
end
-- TODO check if chest is full? emit event?
function dump.inv()
	turtle.back()
	turtle.turnRight()
	for i = 16, 1, -1 do
		turtle.select(i)
		turtle.drop(64)
	end
	dump.notify_master()
	turtle.turnLeft()
	turtle.forward()
end
-- return turtle to original position afterwards.
function dump.inv_return(rpos)
	if rpos == -1 then
		go.back(pos.x - 1)
		turtle.turnLeft()
	else
		turtle.turnRight()
	end
	go.forward(pos.y - 1)
	turtle.turnRight()
	go.up(pos.z - 1)
	dump.inv()
	go.down(pos.z - 1)
	turtle.turnRight()
	go.forward(pos.y - 1)
	if rpos == -1 then
		turtle.turnLeft()
		go.forward(pos.x - 1)
	else
		turtle.turnLeft()
	end
end

-- TODO handle unbreakable blocks
function dig_rectangle(x, y, z, tunnel_fw)
	local rpos = 1
	for i = 1, y, 1 do
		tunnel_fw(x - 1)
		pos.x = pos.x + (x - 1) * rpos
		rpos = rpos * -1
		if is_full() then
			dump.inv_return(rpos)
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

function dig_cuboid(x, y, z)
	local i = z
	while (i > 0) do
		if math.floor(i / 3) > 0 then
			tunnel.down(2)
			pos.z = pos.z + 2
			dig_rectangle(x, y, z, tunnel.forward.three)
			pos.z = pos.z + 1
			tunnel.down(1)
			i = i - 3
		elseif math.floor(i / 2) > 0 then
			tunnel.down(2)
			pos.z = pos.z + 2
			dig_rectangle(x, y, z, tunnel.forward.two)
			i = i - 2
		else
			tunnel.down(1)
			pos.z = pos.z + 1
			dig_rectangle(x, y, z, tunnel.forward.one)
			i = i - 1
		end
	end
	for i = 1, z, 1 do
		turtle.up()
	end
	pos.z = 1
	dump.inv()
	return true
end
