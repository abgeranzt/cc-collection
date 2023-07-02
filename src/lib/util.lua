---@diagnostic disable-next-line: unknown-cast-variable
---@cast os os
---@diagnostic disable-next-line: unknown-cast-variable
---@cast turtle turtle

local const = require("lib.const")
local dig = require("lib.dig")

---@param slot integer
---@param dir util_inv_dir | nil
local function place_inv(slot, dir)
	local p_slot = turtle.getSelectedSlot()
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

local op = {
	drop = {
		forward = turtle.drop,
		up = turtle.dropUp,
		down = turtle.dropDown,
	},
	suck = {
		forward = turtle.suck,
		up = turtle.suckUp,
		down = turtle.suckDown,
	}
}

---@param d_slot integer | nil The slot with the dumping inv
---@param f_slot integer | nil The first slot to dump
---@param l_slot integer | nil The last slot to dump
---@param chest_dir util_inv_dir | nil The direction to place the dumping inv in
local function dump(d_slot, f_slot, l_slot, chest_dir)
	d_slot = d_slot or const.SLOT_DUMP
	f_slot = f_slot or 3
	l_slot = l_slot or 16
	local p_slot = turtle.getSelectedSlot()
	turtle.select(d_slot)
	local ok, err
	---@diagnostic disable-next-line: cast-local-type
	chest_dir, err = place_inv(d_slot, chest_dir)
	if not chest_dir then
		return false, err
	end
	---@cast chest_dir util_inv_dir

	local slot = f_slot
	while slot <= l_slot do
		turtle.select(slot)
		ok, err = op.drop[chest_dir]()
		if ok or err == "No items to drop" then
			slot = slot + 1
		else
			sleep(1)
		end
	end

	ok, err = break_inv(d_slot, chest_dir)
	turtle.select(p_slot)

	return ok, err
end

---@param target integer The fuel target
---@param fuel_type util_fuel_type | nil The used fuel type
---@param s_slot integer | nil The fuel source slot
---@param d_slot integer | nil The slot with the dumping inv
---@param f_slot integer | nil The first slot for temp fuel storage
---@param l_slot integer | nil The last slot for temp fuel storage
---@param chest_dir util_inv_dir | nil The direction to place the fuel chest in
local function refuel(target, fuel_type, s_slot, d_slot, f_slot, l_slot, chest_dir)
	fuel_type = fuel_type or "consumable"
	s_slot = s_slot or 2
	d_slot = d_slot or 1
	f_slot = f_slot or 3
	l_slot = l_slot or 16

	local function dump_containers()
		-- FIXME this seems to ignore the first slot to dump
		for i = f_slot, l_slot do
			if turtle.getItemCount(i) then
				local ok, err = dump(d_slot, f_slot, l_slot, chest_dir)
				if not ok then
					return false, err
				end
				break
			end
		end
		return true, nil
	end

	local ok, err
	if fuel_type == "container" then
		ok, err = dump_containers()
		if not ok then
			return false, err
		end
	end

	-- Trigger a dump if a block had to be mined before placing the inv
	while true do
		---@diagnostic disable-next-line: cast-local-type
		chest_dir, err = place_inv(s_slot, chest_dir)
		if not chest_dir then
			return false, err
		end
		if turtle.getItemCount(f_slot) > 0 then
			break_inv(s_slot, chest_dir)
			ok, err = dump(d_slot, f_slot, l_slot, chest_dir)
			if not ok then
				return false, err
			end
		else
			break
		end
	end
	---@cast chest_dir util_inv_dir

	local p_slot = turtle.getSelectedSlot()

	-- TODO thorough testing for container fuel sources
	if fuel_type == "container" then
		local fuel_slot = f_slot
		while turtle.getFuelLevel() < target do
			if fuel_slot > l_slot then
				break_inv(s_slot, chest_dir)
				ok, err = dump(d_slot, f_slot, l_slot, chest_dir)
				if not ok then
					return false, err
				end
				---@diagnostic disable-next-line: cast-local-type
				chest_dir, err = place_inv(s_slot)
				if not chest_dir then
					return false, err
				end
				fuel_slot = f_slot
			end

			turtle.select(fuel_slot)
			while true do
				ok, _ = op.suck[chest_dir](1)
				if ok then
					break
				end
				sleep(0.5)
			end
			ok, err = turtle.refuel(1)
			if not ok then
				break_inv(s_slot, chest_dir)
				return false, err
			end
			fuel_slot = fuel_slot + 1
		end
	else
		while turtle.getFuelLevel() < target do
			turtle.select(f_slot)
			ok, err = op.suck[chest_dir](1)
			if ok then
				ok, err = turtle.refuel(1)
				if not ok then
					break_inv(s_slot, chest_dir)
					return false, err
				end
			else
				sleep(1)
			end
		end
	end

	ok, err = break_inv(s_slot, chest_dir)
	if not ok then
		return false, err
	end
	-- Dump empty containers
	if fuel_type == "container" then
		ok, err = dump_containers()
	end
	if not ok then
		return false, err
	end
	turtle.select(p_slot)
	return true
end

---@param s_slot integer The slot to move from
---@param f_slot integer nil The first slot to try to move to
---@param l_slot integer | nil The last slot to try to move to
local function transfer_first_free(s_slot, f_slot, l_slot)
	l_slot = l_slot or 16
	local p_slot = turtle.getSelectedSlot()
	turtle.select(s_slot)
	local moved = false
	for slot = f_slot, l_slot do
		if turtle.transferTo(slot) then
			moved = true
			break
		end
	end
	turtle.select(p_slot)
	return moved
end

---@return string | nil
local function get_label()
	return os.getComputerLabel()
end

---@param name string The minecraft:item:identifier
---@param slot integer The turtle slot
---@param min integer | nil Optional mininum amount
local function has_item(name, slot, min)
	if not min then min = 1 end
	return turtle.getItemCount(slot) >= min and
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
	hi = has_item(name, s_slot)
	equip()
	turtle.select(slot)
	return hi
end

---@param name string The minecraft:item:identifier
---@param f_slot integer | nil The first slot to look in
---@param l_slot integer | nil The last slot to look in
local function find_item(name, f_slot, l_slot)
	f_slot = f_slot or 1
	l_slot = l_slot or 16
	for slot = f_slot, l_slot do
		if turtle.getItemCount(slot) > 0 and turtle.getItemDetail(slot, true).name == name then
			return slot
		end
	end
	return false
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

---@param pos gpslib_position
---@param x integer
---@param y integer
---@param z integer
---@return gpslib_position
local function coord_add(pos, x, y, z)
	return {
		x = pos.x + x,
		y = pos.y + y,
		z = pos.z + z,
		dir = pos.dir
	}
end

return {
	place_inv = place_inv,
	break_inv = break_inv,
	dump = dump,
	refuel = refuel,
	transfer_first_free = transfer_first_free,
	get_label = get_label,
	has_item = has_item,
	has_item_equipped = has_item_equipped,
	find_item = find_item,
	table_compare = table_compare,
	table_copy = table_copy,
	coord_add = coord_add
}
