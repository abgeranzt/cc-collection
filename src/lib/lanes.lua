local function import()
	local nv = dofile("/ccc/lib/navigate.lua")
	local go = nv.go
	local turn = nv.turn
	local exc = dofile("/ccc/lib/excavate.lua")
	return go, turn, exc.dig, exc.tunnel
end
local go, turn, dig, tunnel = import()

-- Dig lane system with steps being the distance between each step.
local function dig_lanes(steps)
	local h = 0
	for _, s in ipairs(steps) do
		-- Increment for correct distance.
		s = s + 1
		tunnel.down(s)
		dig.forward()
		turtle.turnRight()
		tunnel.forward.one(1)
		turtle.turnLeft()
		dig.forward()
		turtle.turnRight()
		turtle.back()
		turtle.turnLeft()
		h = h + s
	end
	tunnel.forward.one(2)
	tunnel.up(h)
	turn()
	tunnel.forward.one(2)
	turtle.turnRight()
end

-- Export
local lanes = {dig_lanes = dig_lanes}
return lanes
