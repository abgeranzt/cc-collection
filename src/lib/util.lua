---@diagnostic disable-next-line: unknown-cast-variable
---@cast os os

local dig = require("lib.dig").dig


local function place_inv(slot)
	local p_slot = turtle.getSelectedSlot()
	---@cast p_slot integer
	turtle.select(slot)
	local inv_dir

	if not turtle.detect() then
		turtle.place()
		inv_dir = "forward"
	elseif not turtle.detectUp() then
		turtle.placeUp()
		inv_dir = "up"
	else
		local ok, err = dig.forward_safe()
		if not ok then
			return false, err
		end
		turtle.place()
		inv_dir = "forward"
	end
	---@cast inv_dir util_inv_dir

	turtle.select(p_slot)
	return inv_dir
end

---@param slot integer
---@param dir util_inv_dir
local function break_inv(slot, dir)
	local p_slot = turtle.getSelectedSlot()
	---@cast p_slot integer
	turtle.select(slot)

	local ok, err
	if dir == "forward" then
		ok, err = turtle.dig()
	else
		ok, err = turtle.digUp()
	end

	turtle.select(p_slot)
	return ok, err
end

---@param d_slot integer | nil The slot with the dumping inv
---@param f_slot integer | nil The first slot to dump
---@param l_slot integer | nil The last slot to dump
local function dump(d_slot, f_slot, l_slot)
	d_slot = d_slot or 1
	f_slot = f_slot or 3
	l_slot = l_slot or 16
	local p_slot = turtle.getSelectedSlot()
	---@cast p_slot integer
	turtle.select(d_slot)
	local inv_dir, err = place_inv(d_slot)
	if not inv_dir then
		return false, err
	end

	local drop_fn
	if inv_dir == "forward" then
		drop_fn = turtle.drop
	else
		drop_fn = turtle.dropUp
	end

	local ok
	local s = f_slot
	while s <= l_slot do
		turtle.select(s)
		ok, err = drop_fn()
		if ok or err == "No items to drop" then
			s = s + 1
		else
			sleep(1)
		end
	end

	ok, err = break_inv(d_slot, inv_dir)
	turtle.select(p_slot)

	return ok, err
end

---@param target integer
---@param f_type util_fuel_type | nil
---@param s_slot integer | nil The fuel source slot
---@param d_slot integer | nil The slot with the dumping inv
---@param f_slot integer | nil The first slot for temp fuel storage
---@param l_slot integer | nil The last slot for temp fuel storage
local function refuel(target, f_type, s_slot, d_slot, f_slot, l_slot)
	f_type = f_type or "consumable"
	s_slot = s_slot or 2
	d_slot = d_slot or 1
	f_slot = f_slot or 3
	l_slot = s_slot or 16

	if f_type == "container" then
		for i = f_slot, l_slot do
			if turtle.getItemCount(i) then
				dump(d_slot, f_slot, l_slot)
				break
			end
		end
	end

	local inv_dir, err = place_inv(s_slot)
	if not inv_dir then
		return false, err
	end

	local suck_fn
	if inv_dir == "forward" then
		suck_fn = turtle.suck
	else
		suck_fn = turtle.suckUp
	end

	local p_slot = turtle.getSelectedSlot()
	---@cast p_slot integer

	local ok
	if f_type == "container" then
		local slot = s_slot
		while turtle.getFuelLevel() < target do
			if slot > l_slot then
				break_inv(s_slot, inv_dir)
				dump(d_slot)
				inv_dir, err = place_inv(s_slot)
				if not inv_dir then
					return false, err
				end
				slot = f_slot
			end

			turtle.select(slot)
			while true do
				ok, _ = suck_fn(1)
				if ok then
					break
				end
			end
			ok, err = turtle.refuel(1)
			if not ok then
				break_inv(s_slot, inv_dir)
				return false, err
			end
			slot = slot + 1
		end
	else
		while turtle.getFuelLevel() < target do
			turtle.select(f_slot)
			ok, err = suck_fn(1)
			if ok then
				ok, err = turtle.refuel(1)
				if not ok then
					break_inv(s_slot, inv_dir)
					return false, err
				end
			else
				sleep(1)
			end
		end
	end

	ok, err = break_inv(s_slot, inv_dir)
	turtle.select(p_slot)
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
