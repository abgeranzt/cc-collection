---@param task task_lib
---@param worker worker_lib
---@param logger logger
---@param gps gps
local function master_setup(task, worker, gps, logger)
	---@param y number
	---@param h number
	local function touches_bedrock(y, h)
		return (y - h) <= -60
	end

	-- TODO unneeded, remove?
	---@param y number
	local function dist_bedrock(y)
		return y + 60
	end

	---@param y number
	local function trim_to_bedrock(y)
		return y + 59
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

	---@param dim dimensions
	local function mine_cuboid(dim)
		-- FIXME some malformed messsages are received at this time
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
		-- DEBUG
		for _, h in ipairs(seg_hs) do
			logger.debug("SEG: " .. tostring(h))
		end
		-- Track the relative y-position of workers
		local rem_h = dim.h - seg_hs[1]

		for i, w in ipairs(workers) do
			logger.info("deploying worker '" .. workers[i] .. "' for segment " .. i)
			worker.deploy(workers[i])
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
			---@diagnostic disable-next-line: undefined-global
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

	return {
		mine_cuboid = mine_cuboid
	}
end

return {
	master_setup = master_setup
}
