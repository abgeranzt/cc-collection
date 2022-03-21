local function import()
	local nv = dofile("/ccc/lib/navigate.lua")
	return nv.go, nv.turn
end
-- TODO unused turn?
local go, turn = import()

local function pull()
	local s = true
	while s do
		s = turtle.suck(64)
	end
end

-- Empty turtle inv into inventory below
local function push()
	while true do
		local dump_failed = false
		for i = 16, 1, -1 do
			if turtle.getItemCount(i) > 0 then
				turtle.select(i)
				if not turtle.dropDown(64) then
					dump_failed = true
				end
			end
		end
		if not dump_failed then
			break
		end
		msg = os.getComputerLabel() .. ":e:" .. "main inventory full"
		os.queueEvent("master_msg", msg)
	end
end

local function fetch(z)
	go.forward()
	go.down(z + 2)
	go.back()
	turtle.turnRight()
	pull()
	turtle.turnLeft()
	go.back()
	go.up(z + 2)
	go.forward()
	push()
	return true
end

-- Export
local haul = {fetch = fetch}
return haul
