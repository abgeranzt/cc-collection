---@diagnostic disable-next-line: unknown-cast-variable
---@cast fs fs
---@diagnostic disable-next-line: unknown-cast-variable
---@cast turtle turtle

local const = require("lib.const")
local dig = require("lib.dig")
local util = require("lib.util")

-- Functionality related to managing a master's workers
---@param logger logger
local function setup(logger)
	local lib = {}

	lib.workers = {}
	---@diagnostic disable-next-line: unknown-cast-variable
	---@cast lib.workers worker[]

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
			for _, w in pairs(workers) do
				table.insert(workers, w.label)
			end
		end
		return workers
	end

	---@param label string
	function lib.deploy(label)
		local ok, err
		logger.info("deploying worker '" .. label .. "'")

		logger.trace("placing helper chests")
		turtle.select(6)
		ok, err = dig.forward()
		-- TODO this is getting tedious, there has to be a more elgant way to propagate errors
		if not ok then
			return false, err
		end
		ok, err = dig.down_safe()
		if not ok then
			return false, err
		end
		if turtle.getItemCount(6) > 0 then
			ok, err = util.dump(1, 6, 16)
			if not ok then
				return false, err
			end
		end
		turtle.select(const.SLOT_HELPER)
		turtle.place()

		logger.trace("placing worker chest")
		local slot = lib.workers[label].type == "miner" and const.SLOT_MINERS or const.SLOT_LOADERS
		turtle.select(slot)
		turtle.placeDown()

		logger.trace("selecting worker")
		-- Search inventory for worker
		while true do
			turtle.suckDown()
			if turtle.getItemDetail(slot, true).displayName == label then
				logger.trace("worker found")
				turtle.transferTo(const.SLOT_DEPLOY)
				break
			end
			turtle.drop()
		end
		-- Return other workers
		while turtle.suck() do
			turtle.dropDown()
		end

		logger.trace("deploying worker")
		dig.down()
		turtle.select(const.SLOT_DEPLOY)
		turtle.placeDown()
		turtle.select(const.SLOT_DUMP)
		turtle.dropDown(1)
		turtle.select(const.SLOT_FUEL)
		turtle.dropDown(1)
		lib.workers[label].deployed = true

		logger.trace("removing helper chests")
		turtle.select(const.SLOT_HELPER)
		dig.forward()

		logger.trace("starting worker")
		peripheral.call("bottom", "turnOn")
		-- Yield execution to allow the worker to start
		sleep(1)
	end

	-- Note: this assumes that the collected worker only contains the items we gave it on deployment
	---@param label string
	function lib.collect(label)
		local slot = lib.workers[label].type == "miner" and const.SLOT_MINERS or const.SLOT_LOADERS
		turtle.select(slot)
		turtle.place()
		-- Force the chests go into the right slots by inserting them into the first possible slot
		-- TODO ensure that enough fuel and dump chests are available
		turtle.select(1)
		turtle.digDown()
		lib.workers[label].deployed = false
		turtle.select(slot)
		turtle.drop()
		turtle.dig()
	end

	return lib
end

return {
	setup = setup
}
