---@diagnostic disable-next-line: unknown-cast-variable
---@cast gps gps

local const = require("lib.const")
local exc = require("lib.excavate")
local go = require("lib.navigate").go
local util = require("lib.util")

---@param task task_lib
---@param worker lib_worker_master
---@param logger lib_logger
local function init(task, worker, logger)
	---@class lib_routine_master Master routines for controlling workers
	local lib = {}

	---@param y number
	---@param h number
	local function touches_bedrock(y, h)
		return (y - h) <= const.HEIGHT_BEDROCK
	end

	---@param y number
	local function trim_to_bedrock(y)
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

	-- TODO smarter speading: up to 3 per segment; avoid spreading on the first worker
	-- Distribute the layers to mine evenly
	---@param n_workers number
	---@param h number
	---@return number[]
	local function spread_seg_heigth(n_workers, h)
		local segments = {}
		local base = math.floor(h / n_workers)
		for i = 1, n_workers do
			segments[i] = base
		end
		for rem = h % n_workers, 1, -1 do
			segments[rem] = segments[rem] + 1
		end
		return segments
	end

	---@param pos gpslib_position Master position
	---@param dim dimensions
	function lib.mine_cuboid(pos, dim)
		-- FIXME some malformed messsages are received at this time - still valid?
		logger.trace("determining available workers")
		local workers = worker.get_labels("miner")

		-- Adjust actual operation y-level
		local y = pos.y - 1
		local segs = {}
		local scrape_br = false
		---@cast segs { worker: string, r_ypos: number }[] | number[][]
		if touches_bedrock(y, dim.h) then
			logger.trace("operation will touch bedrock, trimming")
			dim.h = trim_to_bedrock(y)
			scrape_br = true
		end
		logger.trace("spreading height on workers")
		local seg_hs = spread_seg_heigth(#workers, dim.h)
		-- Track the relative y-position of workers
		local rem_h = dim.h - seg_hs[1]

		for i, w in ipairs(workers) do
			logger.info("deploying worker '" .. workers[i] .. "' for segment " .. i)
			worker.deploy(workers[i])
			task.create(workers[i], "set_position", { pos = pos })
			-- TODO ? reduce the amount of fuel chests needed by calculating the fuel required for all tasks?
			task.await(task.create(workers[i], "refuel", { target = 1000 }))

			-- TODO scrape the bedrock using multiple workers?
			if i == 1 and scrape_br then
				logger.trace("splitting first segment to allow bedrock scraping")
				local seg_part_1 = trim_to_bedrock(y - rem_h)
				table.insert(segs, i, {
					worker = w,
					r_ypos = rem_h,
					task.create(w, "tunnel", { direction = "down", distance = rem_h }),
					task.create(w, "excavate", { l = dim.l, w = dim.w, h = seg_part_1 }),
					task.create(w, "tunnel", { direction = "down", distance = seg_part_1 }),
					task.create(w, "excavate_bedrock", { l = dim.l, w = dim.w }),
					task.create(w, "tunnel", { direction = "up", distance = seg_part_1 })
				})
			else
				table.insert(segs, i, {
					worker = w,
					r_ypos = rem_h,
					task.create(w, "tunnel", { direction = "down", distance = rem_h }),
					task.create(w, "excavate", { l = dim.l, w = dim.w, h = seg_hs[i] })
				})
			end
			rem_h = rem_h - seg_hs[i]
			-- Yield to allow the worker to move in order to prevent collision
			sleep(3)
		end
		--
		-- Collect workers
		for i = #segs, 1, -1 do
			local last_task = #(segs[i])
			task.await(segs[i][last_task])
			logger.info("recalling worker '" .. segs[i].worker .. "' of segment " .. i)
			task.await(task.create(segs[i].worker, "navigate", { direction = "up", distance = segs[i].r_ypos }))
			worker.collect(segs[i].worker)
		end
		-- TODO error handling
		return true
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
			-- TODO determine fuel type somewhere
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
		local loaders = worker.get_labels_avail("loader")
		local i = 1
		local chunks = {}
		for j = 1, size do
			chunks[j] = {}
			for k = 1, size do
				chunks[j][k] = {}
			end
		end
		-- Reverse order because we want to deploy loaders that are further away first
		for j = #chunks, 1, -1 do
			for k = #chunks, 1, -1 do
				local loader = loaders[i]
				logger.info("deploying loader '" .. loader .. "' for chunk " .. i)
				i = i + 1
				worker.deploy(loader, "loader", "up")
				chunks[j][k].label = loader
				task.create(loader, "set_position", {
					pos = {
						x = pos.x,
						y = pos.y + 1,
						z = pos.z,
						dir = pos.dir
					}
				})
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
				task.create(loader, "tunnel_pos", { pos = target_pos })
				local tid = task.create(loader, "update_position", {})
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
		---@cast chunks routine_chunk_grid
		return chunks
	end

	---@param pos gpslib_position
	---@param chunks routine_chunk_grid
	function lib.collect_loaders(pos, chunks)
		-- TODO error handling
		-- TODO deploy intermediate loader below
		logger.info("collecting loaders for " .. #chunks * #chunks .. " chunks")
		local i = 1
		for j = 1, #chunks do
			for k = 1, #chunks do
				local loader = chunks[j][k].label
				logger.info("collecting loader '" .. loader .. "' in chunk " .. i)
				i = i + 1
				task.await(task.create(loader, "tunnel_pos", {
					pos = {
						x = pos.x,
						z = pos.z,
						y = pos.y + 1,
						dir = pos.dir
					}
				}))
				task.create(loader, "swap", {})
				sleep(1)
				worker.collect(loader, "up")
			end
		end
	end

	---@param pos gpslib_position Initial master position
	---@param size integer Square root of number of chunks (area is always a square)
	---@param dir gpslib_direction
	---@param use_loaders boolean
	---@param limit integer | nil Operation limit (-1 for infinite)
	function lib.auto_mine_chunk(pos, size, dir, use_loaders, limit)
		limit = limit or -1
		local n_miners = #worker.get_labels("miner")
		if n_miners < 1 then
			local err = "not enough miners configured (has: " .. n_miners .. ", needs at least 1)"
			logger.error(err)
			return false, err
		end
		local n_loaders = #worker.get_labels("loader")
		local n_chunks = size ^ 2
		if n_loaders < n_chunks then
			local err = "not enough loaders configured (has: " ..
				n_loaders .. ", needs at least " .. n_chunks + 1 .. ")"
			logger.error(err)
			return false, err
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
		for op = 1, limit, 1 do
			-- TODO move after operation
			if limit == -1 then
				logger.info("operation " .. op .. " (no limit set)")
			else
				logger.info("operation " .. op .. "/" .. limit)
			end
			local chunks
			if use_loaders then
				logger.trace("deploying loaders")
				chunks = lib.deploy_loaders(pos, size)
			end
			logger.info("starting mining operation")
			lib.mine_cuboid(pos, { w = size * 16, l = size * 16, h = 1000 })
			if use_loaders then
				logger.info("collecting loaders")
				lib.collect_loaders(pos, chunks)
			end
		end
	end

	return lib
end

return {
	init = init
}
