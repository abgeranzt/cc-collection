---@diagnostic disable-next-line: unknown-cast-variable
---@cast gps gps

local const = require("lib.const")
local exc = require("lib.excavate")
local go = require("lib.navigate").go
local util = require("lib.util")

---@param config lib_config
---@param task lib_task
---@param worker lib_worker_master
---@param logger lib_logger
local function init(config, task, worker, logger)
	---@class lib_routine_master Master routines for controlling workers
	local lib = {}

	---@param y number
	---@param h number
	local function touches_bedrock(y, h)
		return (y - h) <= const.HEIGHT_BEDROCK
	end

	-- Return the distance from the specified y-level to the first layer of bedrock
	---@param y number
	local function dist_to_bedrock(y)
		return y + math.abs(const.HEIGHT_BEDROCK) - 1
	end

	-- Determine the chunk corner required to mine in the specified direction
	---@param x integer
	---@param z integer
	---@param dir gpslib_direction
	local function get_chunk_corner(x, z, dir)
		local cx, cz
		if dir == "north" then
			cx = math.floor(x / 16) * 16
			cz = math.floor(z / 16 + 1) * 16 - 1
		elseif dir == "east" then
			cx = math.floor(x / 16) * 16
			cz = math.floor(z / 16) * 16
		elseif dir == "south" then
			cx = math.floor(x / 16 + 1) * 16 - 1
			cz = math.floor(z / 16) * 16
		else
			cx = math.floor(x / 16 + 1) * 16 - 1
			cz = math.floor(z / 16 + 1) * 16 - 1
		end
		return cx, cz
	end

	-- Distribute the layers to mine evenly
	---@param max_workers number
	---@param h number
	---@return number[]
	local function spread_segment_height(max_workers, h)
		-- Optimize worker amount for operation
		local used_workers = math.ceil(h / 3)
		used_workers = used_workers > max_workers and max_workers or used_workers

		local segments = {}
		for i = 1, used_workers do
			segments[i] = 0
		end

		-- Use increments of three to optimize fuel consumption and operation time
		while h > 0 do
			for i = 1, used_workers do
				if h >= 3 then
					segments[i] = segments[i] + 3
					h = h - 3
				else
					segments[i] = segments[i] + h
					h = 0
				end
			end
		end
		return segments
	end

	---@param pos gpslib_position Master position
	---@param dim dimensions
	---@param scrape_bedrock boolean | nil
	function lib.mine_cuboid(pos, dim, scrape_bedrock)
		logger.trace("determining available workers")
		local workers = worker.get_labels_avail("miner")
		local workers_n = #workers
		if workers_n < 1 then
			local err = "at least one configured miner is required"
			logger.error(err)
			return false, err
		end

		-- Adjust actual operation y-level
		local deploy_pos = util.coord_add(pos, 0, -1, 0)

		-- Trim operation area to bedrock
		if touches_bedrock(deploy_pos.y, dim.h) then
			logger.trace("operation will touch bedrock, trimming")
			-- We want to be two levels above bedrock to allow the scraper below to dump its items properly
			dim.h = dist_to_bedrock(deploy_pos.y) - 1
			scrape_bedrock = true
		end

		if workers_n == 1 then
			local w = worker.get_labels_avail("miner")[1]
			logger.info("deploying worker '" .. w .. "' for excavation")
			worker.deploy(w, "down")
			local w_pos = util.coord_add(pos, 0, -1, 0)
			task.create(w, "set_position", { pos = w_pos })
			task.create(w, "set_fuel_type", { fuel_type = config.fuel_type })
			-- TODO ? reduce the amount of fuel chests needed by calculating the fuel required for all tasks?
			task.await(task.create(w, "refuel", { target = const.TURTLE_MIN_FUEL }))
			logger.info("excavating segment 1")
			local tid = task.create(w, "excavate", { l = dim.l, w = dim.w, h = dim.h })
			task.await(tid)
			if not task.is_successful(tid) then
				logger.error("excavate task for main segment failed!")
			end
			if scrape_bedrock then
				tid = task.create(w, "tunnel_pos",
					{ pos = { x = w_pos.x, y = const.HEIGHT_BEDROCK + 2, z = w_pos.z, dir = w_pos.dir } })
				task.await(tid)
				if task.is_successful(tid) then
					logger.trace("excavating bedrock segment")
					tid = task.create(w, "excavate_bedrock", { l = dim.l, w = dim.w })
					task.await(tid)
					if not task.is_successful(tid) then
						logger.error("excavate task for bedrock segment failed!")
					end
				else
					logger.error("tunnel command before bedrock scraping failed!")
				end
			end
			tid = task.create(w, "tunnel_pos", { pos = w_pos })
			task.await(tid)
			if not task.is_successful(tid) then
				local err = "worker '" .. w .. "' failed to return"
				return false, err
			end
			worker.collect(w, "down")
			return true, nil
		end

		local segments = spread_segment_height(scrape_bedrock and workers_n - 1 or workers_n, dim.h)
		local segments_n = #segments
		if scrape_bedrock then
			logger.info("spreading area into " .. segments_n .. "+1 segments")
		else
			logger.info("spreading area into " .. segments_n .. " segments")
		end
		local first_w = worker.get_any_avail("miner")

		if scrape_bedrock then
			logger.info("deploying worker '" .. first_w .. "' for bedrock segment")
		else
			logger.info("deploying worker '" .. first_w .. "' for segment " .. #segments .. "/" .. segments_n)
		end
		worker.deploy(first_w, "down")
		task.create(first_w, "set_position", { pos = deploy_pos })
		task.create(first_w, "set_fuel_type", { fuel_type = config.fuel_type })
		-- TODO ? reduce the amount of fuel chests needed by calculating the fuel required for all tasks?
		task.await(task.create(first_w, "refuel", { target = const.TURTLE_MIN_FUEL }))
		local target_y = scrape_bedrock
			and const.HEIGHT_BEDROCK + 2
			or deploy_pos.y - dim.h + segments[#segments]
		local tid = task.create(first_w, "tunnel_pos",
			{ pos = { x = deploy_pos.x, y = target_y, z = deploy_pos.z, dir = deploy_pos.dir } })
		task.await(tid)
		if not task.is_successful(tid) then
			local err = "failed to create vertical tunnel"
			logger.error(err)
			task.await(task.create(first_w, "tunnel_pos", { pos = deploy_pos }))
			worker.collect(first_w, "down")
			return false, err
		end

		if scrape_bedrock then
			tid = task.create(first_w, "excavate_bedrock", { l = dim.l, w = dim.w })
			target_y = deploy_pos.y - dim.h
		else
			tid = task.create(first_w, "excavate", { l = dim.l, w = dim.w, h = segments[#segments] })
			dim.h = dim.h - segments[#segments]
			segments[#segments] = nil
		end

		local tasks = { { worker = first_w, tid = tid, segment = scrape_bedrock and "bedrock" or #segments + 1 } }
		---@cast tasks { worker: string, tid: integer, segment: integer | "bedrock"}[]

		while #segments > 0 do
			target_y = target_y + segments[#segments]
			local w = worker.get_any_avail("miner")
			logger.info("deploying worker '" .. w .. "' for segment " .. #segments .. "/" .. segments_n)
			worker.deploy(w, "down")
			task.create(w, "set_position", { pos = deploy_pos })
			-- TODO ? reduce the amount of fuel chests needed by calculating the fuel required for all tasks?
			task.await(task.create(w, "refuel", { target = const.TURTLE_MIN_FUEL }))
			task.await(
				task.create(w, "navigate_pos",
					{ pos = { x = deploy_pos.x, y = target_y, z = deploy_pos.z, dir = deploy_pos.dir } })
			)
			tid = task.create(w, "excavate", { l = dim.l, w = dim.w, h = segments[#segments] })
			dim.h = dim.h - segments[#segments]
			table.insert(tasks, { worker = w, tid = tid, segment = #segments })
			segments[#segments] = nil
		end

		while #tasks > 0 do
			tid = tasks[#tasks].tid
			local w = tasks[#tasks].worker
			task.await(tid)
			if not task.is_successful(tid) then
				logger.error("excavate tasks for segment " .. tasks[#tasks].segment .. " failed!")
			end
			task.await(task.create(w, "navigate_pos", { pos = deploy_pos }))
			logger.info("collecting worker '" .. w .. "'")
			worker.collect(w, "down")
			tasks[#tasks] = nil
		end
		return true, nil
	end

	---@param pos gpslib_position Initial master position
	---@param dim dimensions
	---@param dir direction_hoz
	---@param limit integer | nil Operation limit (-1 for infinite)
	function lib.auto_mine(pos, dim, dir, limit)
		logger.info("starting automining")
		limit = limit or -1
		for i = 1, limit do
			logger.info("starting mining operation " .. i .. "/" .. (limit > -1 and limit or "inf"))
			lib.mine_cuboid(pos, dim)
			if turtle.getFuelLevel() < dim.w then
				logger.trace("refuelling")
				util.refuel(dim.w)
			end
			logger.info("mining operation " .. i .. " complete")
			if i < limit then
				if dir == "forward" or dir == "back" then
					exc.tunnel[dir](dim.l)
				else
					exc.tunnel[dir](dim.w)
				end
				pos.x, pos.y, pos.z = gps.locate()
			end
		end
	end

	local chunk_shifts = {
		north = {
			x = 16,
			z = -16
		},
		east = {
			x = 16,
			z = 16
		},
		south = {
			x = -16,
			z = 16
		},
		west = {
			x = -16,
			z = -16
		}
	}

	---@param pos gpslib_position Initial master position
	---@param size integer Square chunks to mine
	function lib.deploy_loaders(pos, size)
		-- TODO error handling
		logger.info("deploying loaders for " .. size * size .. " chunks")

		local ok, err
		local n_chunks = size ^ 2
		local n_avail_loaders = #worker.get_labels_avail("loader")
		if n_avail_loaders < n_chunks then
			err = "not enough loaders available (has: " .. n_avail_loaders .. ", needs " .. n_chunks .. ")"
			return false, err
		end
		if not util.has_item(const.ITEM_MODEM, const.SLOT_MASTER_MODEMS, n_chunks) then
			err = "not enough " .. const.LABEL_MODEM .. " available (needs: " .. n_chunks .. ")"
			return false, err
		end

		local i = 1
		local chunks = {}
		for j = 1, size do
			chunks[j] = {}
			for k = 1, size do
				chunks[j][k] = {}
			end
		end
		---@cast chunks routine_chunk_grid
		-- Reverse order because we want to deploy loaders that are further away first
		for j = #chunks, 1, -1 do
			for k = #chunks, 1, -1 do
				local loader = worker.get_any_avail("loader")
				logger.info("deploying loader '" .. loader .. "' for chunk " .. i)
				i = i + 1
				ok, err = worker.deploy(loader, "up")
				if not ok then
					err = "failed to deploy loader '" .. loader .. "'"
					logger.error(err)
					return false, err
				end

				chunks[j][k].label = loader
				local loader_pos = util.coord_add(pos, 0, 1, 0)
				task.create(loader, "set_position", { pos = loader_pos })
				task.create(loader, "set_fuel_type", { fuel_type = config.fuel_type })

				local fuel_target = j * 16 * 2 + k * 16 * 2
				if fuel_target < const.TURTLE_MIN_FUEL then
					fuel_target = const.TURTLE_MIN_FUEL
				end
				task.await(task.create(loader, "refuel", { target = fuel_target }))

				local x = pos.x + (j - 1) * chunk_shifts[pos.dir].x
				local z = pos.z + (k - 1) * chunk_shifts[pos.dir].z

				local target_pos = {
					x = x,
					y = pos.y + 2,
					z = z,
					dir = pos.dir
				}
				local tid = task.create(loader, "tunnel_pos", { pos = target_pos })
				-- Yield to allow the worker to move
				sleep(3)
				chunks[j][k].tid = tid
			end
		end
		-- Await arrival
		for j = #chunks, 1, -1 do
			for k = #chunks[j], 1 - 1 do
				task.await(chunks[j][k].tid)
			end
		end
		return chunks
	end

	---@param pos gpslib_position
	---@param chunks routine_chunk_grid
	function lib.collect_loaders(pos, chunks)
		-- TODO error handling/propagation
		-- TODO deploy intermediate loader below
		logger.info("collecting loaders for " .. #chunks * #chunks .. " chunks")
		local i = 1
		for j = 1, #chunks do
			for k = 1, #chunks do
				local loader = chunks[j][k].label
				logger.info("collecting loader '" .. loader .. "' in chunk " .. i)
				i = i + 1
				local target_pos = util.coord_add(worker.workers[loader].position, 0, -1, 0)
				task.await(task.create(loader, "tunnel_pos", { pos = target_pos }))
				target_pos = util.coord_add(pos, 0, 1, 0)
				task.await(task.create(loader, "tunnel_pos", { pos = target_pos }))
				task.await(task.create(loader, "dump", {}))
				task.create(loader, "swap", {})
				-- Yield to allow the worker to swap
				sleep(1)
				local ok, err = worker.collect(loader, "up")
				if not ok then
					err = "failed to collect loader '" .. loader .. "'"
					logger.error(err)
					return false, err
				end
			end
		end
	end

	-- Mine a square of chunks.
	-- Navigate to the specified corner of the chunk and treat it as the bottom left corner of the square to mine.
	---@param pos gpslib_position Initial master position
	---@param size integer Square root of number of chunks (area is always a square)
	---@param dir gpslib_direction The direction to mine in (mine forward and right relative to this)
	---@param use_loaders boolean Whether to use loaders
	---@param limit integer | nil Operation limit (-1 for infinite)
	function lib.auto_mine_chunk(pos, size, dir, use_loaders, limit)
		-- TODO use worker.verify_workers and handle result, if missing, decide whether to continue with remaining workers
		if not use_loaders then
			logger.warn(
				"using auto chunk mining without chunk loaders may lead to unexpected behavior due to chunks being unloaded"
			)
		end
		limit = limit or -1
		local size_blocks = size * 16
		local n_miners = #worker.get_labels_avail("miner")
		if n_miners < 1 then
			local err = "not enough miners available (has: " .. n_miners .. ", needs at least 1)"
			logger.error(err)
			return false, err
		end
		if use_loaders then
			local n_loaders = #worker.get_labels_avail("loader")
			local n_chunks = size ^ 2
			if n_loaders < n_chunks then
				local err = "not enough loaders available (has: " ..
					n_loaders .. ", needs at least " .. n_chunks + 1 .. ")"
				logger.error(err)
				return false, err
			end
		end

		logger.info("starting chunk automining")
		local x, z = get_chunk_corner(pos.x, pos.z, dir)
		local target_pos = util.table_copy(pos)
		---@cast target_pos gpslib_position
		target_pos.x = x
		target_pos.z = z
		target_pos.dir = dir

		if not util.table_compare(pos, target_pos) then
			local target_fuel = math.abs(target_pos.x - pos.x) + math.abs(target_pos.z - pos.z)
			if turtle.getFuelLevel() < target_fuel then
				logger.info("refuelling")
				util.refuel(target_fuel + 1000)
			end
			logger.info("navigating to chunk edge")
			go.coords(pos, target_pos, exc.tunnel)
		end
		local ok, err = true, nil
		for op = 1, limit, 1 do
			if limit == -1 then
				logger.info("operation " .. op .. " (no limit set)")
			else
				logger.info("operation " .. op .. "/" .. limit)
			end
			local chunks
			if use_loaders then
				logger.trace("deploying loaders")
				chunks, err = lib.deploy_loaders(pos, size)
				if not chunks then
					return false, err
				end
				---@cast chunks routine_chunk_grid
			end
			logger.info("starting mining operation")
			-- TODO error handling
			lib.mine_cuboid(pos, { w = size_blocks, l = size_blocks, h = 1000 })
			if op ~= limit then
				logger.info("navigating to next position")
				local old_pos = util.table_copy(pos)
				ok, err = exc.tunnel.forward(size_blocks)
				-- Yield execution to allow pos to be updated
				sleep(1)
				if not ok then
					logger.error(err)
					logger.warn("navigation to next position failed")
					logger.warn("returning" ..
						(use_loaders and ", collecting loaders" or "") ..
						" and exiting")
					sleep(1)
					go.coords(pos, old_pos)
				end
			end
			if use_loaders then
				-- Yield execution to allow pos to be updated
				sleep(1)
				logger.info("collecting loaders")
				lib.collect_loaders(pos, chunks)
			end
			if not ok then
				return false, err
			end
		end
		logger.info("auto chunk mining complete")
		return true, nil
	end

	return lib
end

return {
	init = init
}
