---@diagnostic disable-next-line: unknown-cast-variable
---@cast os os
---@diagnostic disable-next-line: unknown-cast-variable
---@cast turtle turtle

local dig = require("lib.dig")

---@param slot integer
---@param dir util_inv_dir | nil
local function place_inv(slot, dir)
	local p_slot = turtle.getSelectedSlot()
	---@cast p_slot integer
	turtle.select(slot)

	local dig_fn = {
		up = dig.up_safe,
		down = dig.down_safe,
		forward = dig.forward_safe
	}
	local place_fn = {
		up = turtle.placeUp,
		down = turtle.placeDown,
		forward = turtle.place
	}

	if not dir then
	if not turtle.detect() then
			dir = "forward"
	elseif not turtle.detectUp() then
			dir = "up"
	else
			-- We do not want to default to down because that might mess with miners below
			dir = "forward"
		end
	end

	local ok, err = dig_fn[dir]()
		if not ok then
			return false, err
		end
	place_fn[dir]()

	turtle.select(p_slot)
	return dir
end

---@param slot integer
---@param dir util_inv_dir
local function break_inv(slot, dir)
	local p_slot = turtle.getSelectedSlot()
	---@cast p_slot integer
	turtle.select(slot)

	local dig_fn = {
		up = dig.up,
		down = dig.down,
		forward = dig.forward
	}

	local ok, err = dig_fn[dir]()

	turtle.select(p_slot)
	return ok, err
end

---@param d_slot integer | nil The slot with the dumping inv
---@param f_slot integer | nil The first slot to dump
---@param l_slot integer | nil The last slot to dump
---@param dir util_inv_dir | nil
local function dump(d_slot, f_slot, l_slot, dir)
	d_slot = d_slot or 1
	f_slot = f_slot or 3
	l_slot = l_slot or 16
	local p_slot = turtle.getSelectedSlot()
	---@cast p_slot integer
	turtle.select(d_slot)
	local err
	---@diagnostic disable-next-line: cast-local-type
	dir, err = place_inv(d_slot, dir)
	if not dir then
		return false, err
	end
	---@cast dir util_inv_dir

	local drop_fn = {
		forward = turtle.drop,
		up = turtle.dropUp,
		down = turtle.dropDown
	}

	local ok
	local s = f_slot
	while s <= l_slot do
		turtle.select(s)
		ok, err = drop_fn[dir]()
		if ok or err == "No items to drop" then
			s = s + 1
		else
			sleep(1)
		end
	end

	ok, err = break_inv(d_slot, dir)
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

	local inv_dir, err
	-- Trigger a dump if a block had to be mined before placing the inv
	while true do
		inv_dir, err = place_inv(s_slot)
		if not inv_dir then
			return false, err
		end
		if turtle.getItemCount(f_slot) > 0 then
			break_inv(s_slot, inv_dir)
			dump(d_slot, f_slot, l_slot)
		else
			break
		end
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


---@param name string The minecraft:item:identifier
---@param slot integer
local function is_item(name, slot)
	return turtle.getItemCount(slot) > 0 and
		turtle.getItemDetail(slot, true).name == name
end

---@param name string The minecraft:item:identifier
---@param side "left" | "right"
---@param s_slot integer | nil The slot used for swapping
local function has_item_equipped(name, side, s_slot)
	s_slot = s_slot or 16
	local equip = side == "left" and turtle.equipLeft or turtle.equipRight
	local slot = turtle.getSelectedSlot()
	local hi = false
	turtle.select(s_slot)
	equip()
	hi = is_item(name, s_slot)
	equip()
	turtle.select(slot)
	return hi
end

---@param t1 table
---@param t2 table
local function table_compare(t1, t2)
	for k, _ in pairs(t1) do
		if t1[k] ~= t2[k] then
			return false
		end
	end
	for k, _ in pairs(t2) do
		if not t1[k] then
			return false
		end
	end
	return true
end

---@param t table
local function table_copy(t)
	local new_t = {}
	for k, v in pairs(t) do
		new_t[k] = v
	end
	return new_t
end

return {
	dump = dump,
	refuel = refuel,
	get_label = get_label,
	is_item = is_item,
	has_item_equipped = has_item_equipped,
	table_compare = table_compare,
	table_copy = table_copy,
}
