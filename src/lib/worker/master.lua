---@diagnostic disable-next-line: unknown-cast-variable
---@cast fs fs
---@diagnostic disable-next-line: unknown-cast-variable
---@cast turtle turtle

local const = require("lib.const")
local dig = require("lib.dig")
local util = require("lib.util")

-- Functionality related to managing a master's workers
---@param logger lib_logger
local function init(logger)
	---@class lib_worker_master Worker management
	---@field workers {[string]: worker}
	local lib = { workers = {} }

	---@param label string
	---@param worker_type worker_type
	---@param worker_ch number
	function lib.create(label, worker_type, worker_ch)
		logger.debug("creating worker '" .. label .. "'")
		lib.workers[label] = {
			label = label,
			type = worker_type,
			channel = worker_ch,
			deployed = false,
		}
	end

	function lib.load_from_file()
		logger.trace("loading workers from file")
		-- TODO error handling
		local f = fs.open("/workers", "r")
		---@cast f fs_filehandle
		while true do
			local s = f.readLine()
			if not s then
				break
			end
			local m = string.gmatch(s, "([^,]+)")
			local label = m()
			local worker_type = m()
			---@cast worker_type worker_type
			local worker_ch = tonumber(m())
			---@cast worker_ch number
			lib.create(label, worker_type, worker_ch)
		end
	end

	---@param label string
	function lib.get(label)
		return lib.workers[label]
	end

	---@param worker_type worker_type
	function lib.get_any_avail(worker_type)
		return lib.get_labels_avail(worker_type)[1]
	end

	-- Return a list of all workers (of a type)
	---@param worker_type worker_type | nil
	---@return string[]
	function lib.get_labels(worker_type)
		local workers = {}
		if worker_type then
			for _, w in pairs(lib.workers) do
				if w.type == worker_type then
					table.insert(workers, w.label)
				end
			end
		else
			for _, w in pairs(lib.workers) do
				table.insert(workers, w.label)
			end
		end
		return workers
	end

	-- Return a list of all available workers (of a type)
	---@param worker_type worker_type | nil
	---@return string[]
	function lib.get_labels_avail(worker_type)
		local workers = {}
		if worker_type then
			for _, w in pairs(lib.workers) do
				if w.type == worker_type and not w.deployed then
					table.insert(workers, w.label)
				end
			end
		else
			for _, w in pairs(lib.workers) do
				if not w.deployed then
					table.insert(workers, w.label)
				end
			end
		end
		return workers
	end

	local op = {
		place = { up = turtle.placeUp, down = turtle.placeDown },
		drop = { up = turtle.dropUp, down = turtle.dropDown },
		suck = { up = turtle.suckUp, down = turtle.suckDown },
		dig = { up = dig.up_safe, down = dig.down_safe }
	}

	---@param dir direction_ver | nil The direction in which to clear, nil for both
	local function clear_deployment_area(dir)
		logger.trace("clearing deployment area")
		turtle.select(const.SLOT_MASTER_FIRST_FREE)
		local err_def = "failed to clear deployment area"
		local ok, err
		if not dir or dir == "up" then
			ok, err = dig.up_safe()
			if not ok then
				logger.error(err)
				return false, err_def
			end
		end
		if not dir or dir == "down" then
			ok, err = dig.down_safe()
			if not ok then
				logger.error(err)
				return false, err_def
			end
		end
		if turtle.getItemCount(const.SLOT_MASTER_FIRST_FREE) > 0 then
			ok, err = util.dump(const.SLOT_DUMP, const.SLOT_MASTER_FIRST_FREE, 16, dir)
		end
		if not ok then
			logger.error(err)
			return false, err_def
		end
		return true
	end

	---@param dir direction_ver | nil The direction in which to place the worker inventory
	function lib.verify_workers(dir)
		-- TODO function that handles uses this function's return value and updates the worker list
		dir = dir or "down"
		logger.trace("clearing space for worker inventories")
		local ok, err = clear_deployment_area(dir)
		if not ok then
			logger.error(err)
			return false, err
		end

		local found = {}
		---@cast found { [string]: { [string]: boolean }}
		for wt, _ in pairs(const.WORKER_TYPES) do
			logger.info("verifying workers of type '" .. wt .. "'")
			local inv_slot = const.WORKER_TYPE_SLOTS[wt]
			local inv_dir
			logger.trace("placing worker inventory")
			inv_dir, err = util.place_inv(inv_slot, dir)
			if not inv_dir then
				logger.error(err)
				return false, err
			end

			found[wt] = {}
			for _, label in ipairs(lib.get_labels(wt)) do
				found[wt][label] = false
			end
			logger.trace("verifying worker list")
			local inv = peripheral.wrap(dir == "up" and "top" or "bottom")
			---@cast inv peripheral_inventory
			for slot = 1, inv.size() do
				local item = inv.getItemDetail(slot)
				if item then
					if lib.workers[item.displayName] then
						logger.trace("found worker '" .. item.displayName .. "'")
						found[wt][item.displayName] = true
					else
						logger.trace("item '" .. item.displayName .. "' is not a known worker")
					end
				else
					logger.trace("slot " .. slot .. " empty")
				end
			end
			logger.trace("breaking worker inventory")
			ok, err = util.break_inv(inv_slot, dir)
			if not ok then
				logger.error(err)
				return false, err
			end
		end

		local verified = util.table_copy_recursive(found)
		local complete = true
		for wt, _ in pairs(const.WORKER_TYPES) do
			for label, was_found in pairs(found[wt]) do
				if not was_found then
					logger.warn("worker '" .. label .. "' is missing")
					verified[wt][label] = nil
					complete = false
				end
			end
		end
		if not complete then
			logger.error("missing workers detected")
		end
		return complete, verified
	end

	---@param label string
	---@param dir direction_ver | nil
	function lib.deploy(label, dir)
		-- TODO ensure that enough fuel and dump chests are available
		-- TODO refactor this and get rid of the helper chests as in verify_workers
		local worker_type = lib.get(label).type
		dir = dir or "down"
		local helper_dir = dir == "down" and "up" or "down"

		local ok, err
		if worker_type == "loader" and not util.has_item(const.ITEM_MODEM, const.SLOT_MASTER_MODEMS) then
			err = "need at least one available " .. const.LABEL_MODEM
			logger.error(err)
			return false, err
		end

		-- Do this now because we do not want any mined items to clutter our inventory while deploying
		logger.trace("clearing space for helper chests")
		ok, err = clear_deployment_area()
		if not ok then
			logger.error(err)
			return false, err
		end

		logger.info("deploying worker '" .. label .. "' " .. dir .. "wards")
		turtle.select(const.SLOT_MASTER_FIRST_FREE)
		logger.trace("placing helper chests")
		ok, err = util.place_inv(const.SLOT_MASTER_HELPER, helper_dir)
		if not ok then
			err = "failed to place helper chest"
			logger.error(err)
			return false, err
		end
		logger.trace("placing worker chest")
		local chest_slot = lib.workers[label].type == "miner" and const.SLOT_MASTER_MINERS or const.SLOT_MASTER_LOADERS
		ok, err = util.place_inv(chest_slot, dir)
		if not ok then
			err = "failed to place worker chest"
			logger.error(err)
			return false, err
		end

		logger.trace("selecting worker")
		-- Search inventory for worker
		turtle.select(chest_slot)
		while true do
			op.suck[dir]()
			-- TODO handle missing worker
			if turtle.getItemDetail(chest_slot, true).displayName == label then
				logger.trace("worker found")
				turtle.transferTo(const.SLOT_MASTER_DEPLOY)
				break
			end
			op.drop[helper_dir]()
		end
		-- Return other workers
		while op.suck[helper_dir]() do
			op.drop[dir]()
		end
		util.break_inv(chest_slot, dir)

		logger.trace("deploying worker")
		turtle.select(const.SLOT_MASTER_DEPLOY)
		op.place[dir]()
		turtle.select(const.SLOT_DUMP)
		op.drop[dir](1)
		turtle.select(const.SLOT_FUEL)
		op.drop[dir](1)
		if worker_type == "loader" then
			turtle.select(const.SLOT_MASTER_MODEMS)
			op.drop[dir](1)
		end
		lib.workers[label].deployed = true

		logger.trace("removing helper chests")
		util.break_inv(const.SLOT_MASTER_HELPER, helper_dir)

		logger.trace("starting worker")
		local side = dir == "up" and "top" or "bottom"
		peripheral.call(side, "turnOn")
		-- Yield execution to allow the worker to start
		sleep(1)
		return true
	end

	-- Note: this assumes that the collected worker only contains the items we gave it on deployment
	---@param label string
	---@param dir direction_ver | nil
	function lib.collect(label, dir)
		dir = dir or "down"
		local chest_dir = dir == "down" and "up" or "down"
		local chest_slot = lib.workers[label].type == "miner" and const.SLOT_MASTER_MINERS or const.SLOT_MASTER_LOADERS

		local ok, err = clear_deployment_area(chest_dir)
		if not ok then
			logger.error(err)
			return false, err
		end

		logger.trace("placing worker chest")
		---@diagnostic disable-next-line: cast-local-type
		ok, err = util.place_inv(chest_slot, chest_dir)
		if not ok then
			err = "failed to place worker chest"
			logger.error(err)
			return false, err
		end
		-- Force the chests go into the right slots by inserting them into the first possible slot
		turtle.select(1)

		logger.trace("breaking worker")
		dig[dir]()
		lib.workers[label].deployed = false
		-- Since the worker is not guaranteed to go into the selected slot, we need to explicitly find it
		local worker_slot = util.find_item(const.ITEM_TURTLE)
		if not worker_slot then
			err = "worker not found in inventory after mining it"
			logger.error(err)
			return false, err
		end
		turtle.select(worker_slot)
		op.drop[chest_dir]()

		-- Handle extra items the worker was carrying
		while turtle.getItemCount(chest_slot) > 0 do
			ok, err = util.transfer_first_free(chest_slot, const.SLOT_MASTER_FIRST_FREE)
			logger.trace("dumping inventory")
			util.dump(const.SLOT_DUMP, const.SLOT_MASTER_FIRST_FREE, nil, dir)
			if ok then
				break
			end
		end
		logger.trace("collecting worker chest")
		turtle.select(chest_slot)
		op.dig[chest_dir]()
		return true
	end

	return lib
end

return {
	init = init
}
