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
	---@field workers worker[]
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
		suck = { up = turtle.suckUp, down = turtle.suckDown }
	}

	-- TODO function to check whether all registered workers of a type are actually present and available
	---@param label string
	---@param worker_type worker_type | nil
	---@param dir direction_ver | nil
	function lib.deploy(label, worker_type, dir)
		-- TODO we can assert the worker_type using the label, get rid of the parameter
		-- FIXME place worker chest in dir
		worker_type = worker_type or "miner"
		dir = dir or "down"

		local ok, err
		if worker_type == "loader" and not util.has_item(const.ITEM_MODEM, const.SLOT_MODEMS) then
			err = "need at least one available " .. const.LABEL_MODEM
			return false, err
		end

		logger.info("deploying worker '" .. label .. "'")
		logger.trace("placing helper chests")
		turtle.select(const.SLOT_FIRST_FREE)
		ok, err = dig.forward()
		-- TODO this is getting tedious, there has to be a more elgant way to propagate errors
		if not ok then
			return false, err
		end
		if dir == "up" then
			ok, err = dig.up_safe()
		else
			ok, err = dig.down_safe()
		end
		if not ok then
			return false, err
		end
		if turtle.getItemCount(const.SLOT_FIRST_FREE) > 0 then
			ok, err = util.dump(1, const.SLOT_FIRST_FREE, 16)
			if not ok then
				return false, err
			end
		end
		turtle.select(const.SLOT_HELPER)
		turtle.place()

		logger.trace("placing worker chest")
		local slot = lib.workers[label].type == "miner" and const.SLOT_MINERS or const.SLOT_LOADERS
		turtle.select(slot)
		op.place[dir]()

		logger.trace("selecting worker")
		-- Search inventory for worker
		while true do
			op.suck[dir]()
			if turtle.getItemDetail(slot, true).displayName == label then
				logger.trace("worker found")
				turtle.transferTo(const.SLOT_DEPLOY)
				break
			end
			turtle.drop()
		end
		-- Return other workers
		while turtle.suck() do
			op.drop[dir]()
		end
		dig[dir]()

		logger.trace("deploying worker")
		turtle.select(const.SLOT_DEPLOY)
		op.place[dir]()
		if worker_type == "loader" then
			turtle.select(const.SLOT_MODEMS)
		else
			turtle.select(const.SLOT_DUMP)
		end
		op.drop[dir](1)
		turtle.select(const.SLOT_FUEL)
		op.drop[dir](1)
		lib.workers[label].deployed = true

		logger.trace("removing helper chests")
		turtle.select(const.SLOT_HELPER)
		dig.forward()

		logger.trace("starting worker")
		if dir == "up" then
			peripheral.call("top", "turnOn")
		else
			peripheral.call("bottom", "turnOn")
		end
		-- Yield execution to allow the worker to start
		sleep(1)
	end

	-- Note: this assumes that the collected worker only contains the items we gave it on deployment
	---@param label string
	---@param dir direction_ver | nil
	function lib.collect(label, dir)
		dir = dir or "down"
		local slot = lib.workers[label].type == "miner" and const.SLOT_MINERS or const.SLOT_LOADERS
		turtle.select(slot)
		turtle.place()
		-- Force the chests go into the right slots by inserting them into the first possible slot
		-- TODO ensure that enough fuel and dump chests are available
		turtle.select(1)
		dig[dir]()
		lib.workers[label].deployed = false
		turtle.select(slot)
		turtle.drop()
		turtle.dig()
	end

	return lib
end

return {
	init = init
}
