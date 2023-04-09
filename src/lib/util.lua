---@diagnostic disable-next-line: unknown-cast-variable
---@cast os os
---@diagnostic disable-next-line: unknown-cast-variable
---@cast turtle turtle

local function turn()
	turtle.turnRight()
	turtle.turnRight()
end

local function dump()
	local slot = turtle.getSelectedSlot()
	turtle.select(1)

	if not turtle.detect() then
		turtle.place()
		for s = 3, 16 do
			turtle.select(s)
			turtle.drop()
		end
		turtle.select(1)
		turtle.dig()
	elseif not turtle.detectUp() then
		turtle.placeUp()
		for s = 3, 16 do
			turtle.select(s)
			turtle.dropUp()
		end
		turtle.select(1)
		turtle.digUp()
	else
		turn()
		turtle.place()
		for s = 3, 16 do
			turtle.select(s)
			turtle.drop()
		end
		turtle.select(1)
		turtle.dig()
		turn()
	end

	turtle.select(slot)
	return true
end

-- TODO make this function more robust
local function refuel()
	if turtle.getItemCount(3) then
		dump()
	end

	local slot = turtle.getSelectedSlot()
	if not turtle.detect() then
		turtle.select(2)
		turtle.place()
		turtle.select(3)
		turtle.suck()
		turtle.refuel()
		turtle.select(2)
		turtle.dig()
		turtle.select(slot)
	elseif not turtle.detectUp() then
		turtle.select(2)
		turtle.placeUp()
		turtle.select(3)
		turtle.suckUp()
		turtle.refuel()
		turtle.select(2)
		turtle.digUp()
		turtle.select(slot)
	else
		turn()
		turtle.select(2)
		turtle.place()
		turtle.select(3)
		turtle.suck()
		turtle.refuel()
		turtle.select(2)
		turtle.dig()
		turtle.select(slot)
		turn()
	end
	return true
end

---@return string | nil
local function get_label()
	return os.getComputerLabel()
end

return {
	dump = dump,
	refuel = refuel,
	get_label = get_label
}
