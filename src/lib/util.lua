local function turn()
	turtle.turnRight()
	turtle.turnRight()
end

local function dump()
	local slot = turtle.getSelectedSlot()
	turtle.select(1)

	if not turtle.detectUp() then
		turtle.placeUp()
		for s = 3, 16 do
			turtle.select(s)
			turtle.dropUp()
		end
		turtle.select(1)
		turtle.digUp()
	elseif not turtle.detect() then
		turtle.place()
		for s = 3, 16 do
			turtle.select(s)
			turtle.drop()
		end
		turtle.select(1)
		turtle.dig()
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
end

local function refuel()
	if turtle.getItemCount(3) then
		dump()
	end

	local slot = turtle.getSelectedSlot()
	if not turtle.detectUp() then
		turtle.select(2)
		turtle.placeUp()
		turtle.select(3)
		turtle.suckUp()
		turtle.refuel()
		turtle.select(2)
		turtle.digUp()
		turtle.select(slot)
	elseif not turtle.detect() then
		turtle.select(2)
		turtle.place()
		turtle.select(3)
		turtle.suck()
		turtle.refuel()
		turtle.select(2)
		turtle.dig()
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
end

return {
	dump = dump,
	refuel = refuel
}
