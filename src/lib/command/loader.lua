local miner = require("lib.command.miner")

---@diagnostic disable-next-line: unknown-cast-variable
---@cast turtle turtle

---@param logger logger
---@param pos gpslib_position
---@param s_slot integer The slot to use for tool swapping
local function init(logger, pos, s_slot)
	-- XXX test this
	-- TODO test this
	local lib = miner.init(logger, pos)

	s_slot = s_slot or 3

	local function swap()
		local slot = turtle.getSelectedSlot()
		turtle.select(s_slot)
		local ok, err = turtle.equipRight()
		turtle.select(slot)
		if not ok then
			---@cast err string
			logger.error(err)
			return false, err
		end
		return true, nil
	end

	lib._tunnel = lib.tunnel
	---@param params {direction: cmd_direction, distance: number}
	---@diagnostic disable-next-line: duplicate-set-field
	function lib.tunnel(params)
		local stored_item = turtle.getItemDetail(s_slot, true).name
		if not stored_item then
			return false, "missing item in swap slot"
		end
		local had_pickaxe = false
		local ok, err
		---@cast stored_item string
		if stored_item == "minecraft:diamond_pickaxe" then
			had_pickaxe = true
			swap()
		end
		ok, err = lib._tunnel(params)
		if had_pickaxe and ok then
			ok, err = swap()
		end
		if not ok then
			---@cast err string
			logger.error(err)
			return false, "tunnel command (loader) failed"
		end
		return true, nil
	end

	lib._tunnel_pos = lib.tunnel_pos

	---@param params {pos: gpslib_position}
	---@diagnostic disable-next-line: duplicate-set-field
	function lib.tunnel_pos(params)
		local stored_item = turtle.getItemDetail(s_slot, true).name
		if not stored_item then
			return false, "missing item in swap slot"
		end
		local had_pickaxe = false
		local ok, err
		---@cast stored_item string
		if stored_item == "minecraft:diamond_pickaxe" then
			had_pickaxe = true
			swap()
		end
		ok, err = lib._tunnel_pos(params)
		if had_pickaxe and ok then
			ok, err = swap()
		end
		if not ok then
			---@cast err string
			logger.error(err)
			return false, "tunnel command (loader) failed"
		end
		return true, nil
	end

	return lib
end

return {
	init = init
}
