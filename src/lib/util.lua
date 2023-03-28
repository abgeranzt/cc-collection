local turn = require("navigate").turn

local function dump()
	turn()
	local slot = turtle.getSelectedSlot()
	turtle.select(1)
	turtle.place()
	for s = 3, 16 do
		turtle.select(s)
		turtle.drop()
	end
	turtle.select(1)
	turtle.dig()
	turtle.select(slot)
	turn()
end

local function refuel()
	if turtle.getItemCount(3) then
		dump()
	end

	turn()
	local slot = turtle.getSelectedSlot()
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

return {
	dump = dump,
	refuel = refuel
}
