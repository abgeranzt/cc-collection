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
		return y + const.HEIGHT_BEDROCK - 1
	end

	-- Round up to chunk border
	---@param p integer
	local function get_chunk_border(p)
		return (p / 16 + 1) * 16 - 1
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

		local _, y, _ = gps.locate()
		-- Adjust actual operation y-level
		y = y - 1
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
		local loaders = worker.get_labels("loader")
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
				require("lib.debug").print_table(target_pos)
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

	-- TODO chunk loaders
	---@param pos gpslib_position Initial master position
	---@param size integer Square chunks to mine
	---@param dir gpslib_direction
	---@param limit integer | nil Operation limit (-1 for infinite)
	---@param use_loaders boolean
	function lib.auto_mine_chunk(pos, size, dir, limit, use_loaders)
		logger.info("starting chunk automining")
		local target_x = get_chunk_border(pos.x)
		local target_z = get_chunk_border(pos.z)
		if pos.x ~= target_x or pos.z ~= target_z then
			logger.info("navigating to chunk edge")
			local target_pos = {
				x = target_x,
				y = pos.y,
				z = target_z,
				dir = "west"
			}
			go.coords(pos, target_pos, exc.tunnel)
		end
		if use_loaders then
			logger.info("deploying loaders")
		end
	end

	return lib
end

return {
	init = init
}
