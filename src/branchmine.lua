-- TODO documentation & refactoring
-- TODO verbose logs

local function dig_forward()
	while turtle.detect() do
		turtle.dig()
	end
end

local function place_torch()
	turtle.turnLeft()
	dig_forward()
	turtle.forward()
	if not turtle.detect() then
		turtle.place()
	end
	turtle.back()
	turtle.select(16)
	turtle.place()
	turtle.select(1)
	turtle.turnRight()
end

local function main(len)
	turtle.up()
	for i = 1, len, 1 do
		dig_forward()
		turtle.forward()
		turtle.digDown()
		-- Dig to sides
		if i % 2 == 0 then
			turtle.turnLeft()
			dig_forward()
			turtle.turnRight()
			turtle.turnRight()
			dig_forward()
			turtle.turnLeft()
			-- Place torch
		elseif (i % 5) - 3 == 0 then
			place_torch()
		end
		if turtle.getItemCount(14) > 0 then
			return_to_chest(i)
			dump_to_chest(2, 15)
			return_to_pos(len)
		end
	end
	return_to_chest(len)
	dump_to_chest(1, 16)
end

local function return_to_chest(len)
	turtle.down()
	turtle.turnLeft()
	turtle.turnLeft()
	for i = 1, len, 1 do
		if not turtle.detectDown() then
			turtle.select(1)
			turtle.placeDown()
		end
		turtle.forward()
	end
end

local function return_to_pos(len)
	turtle.turnLeft()
	turtle.turnLeft()
	turtle.up()
	for i = 1, len, 1 do
		turtle.forward()
	end
end

local function dump_to_chest(from, to)
	for i = from, to, 1 do
		turtle.select(i)
		turtle.drop()
	end
end

local len = ...
main(len)
