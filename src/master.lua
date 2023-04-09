-- TODO make this configurable
local master_ch = 8000

---@diagnostic disable-next-line: undefined-global
local modem = peripheral.find("modem")
if not modem then
	print("No modem found, exiting!")
	---@diagnostic disable-next-line: undefined-global
	exit()
end

local logger = require("lib.logger").setup(9000, "info", nil, modem)
-- local logger = require("lib.logger").setup(9000, "trace", "/log", modem)
---@cast logger logger

local worker = require("lib.worker").master_setup(logger)
local message = require("lib.message").master_setup(master_ch, modem, worker, logger)
local master_gps = require("lib.gps").master_setup(worker, logger)
local task = require("lib.task").master_setup(message.send_task, worker, logger)

-- TODO smarter speading: up to 3 per segment; avoid spreading on the first worker
-- Distribute the layers to mine evenly
---@param n_workers number
---@param h number
---@return number[]
local function spread_segment(n_workers, h)
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

---@param y number
---@param h number
local function touches_bedrock(y, h)
	return (y - 1 - h) <= -60
end

---@param y number
---@param h number
local function to_bedrock(y, h)
	local new_h = h
	-- TODO there is probably a more elegant solution in form of an equation for this, but it works
	while y - new_h <= -60 do
		new_h = new_h - 1
	end
	return new_h
end

---@param dim dimensions
local function mine_cuboid(dim)
	logger.trace("determining available workers")
	local workers = worker.get_labels("miner")
	---@diagnostic disable-next-line: undefined-global
	local _, y, _ = gps.locate()
	local segments = {}
	---@cast segments { worker: string, r_ypos: number }[] | number[][]
	dim.h = to_bedrock(y, dim.h)
	local segment_h = spread_segment(#workers, dim.h)
	-- Track the relative y-position of workers
	local rem_h = dim.h - segment_h[1]

	-- TODO scrape the bedrock using multiple workers?
	for i, w in ipairs(workers) do
		logger.info("deploying worker '" .. workers[i] .. "' for segment " .. i)
		worker.deploy(workers[i])
		task.await(task.create(workers[i], "refuel", { target = 1000 }))

		if i == 1 and touches_bedrock(y, dim.h) then
			local s1 = to_bedrock(y - rem_h, segment_h[1])
			table.insert(segments, i, {
				worker = w,
				r_ypos = rem_h,
				task.create(w, "tunnel", { direction = "down", distance = rem_h }),
				task.create(w, "excavate", { l = dim.l, w = dim.w, h = s1 }),
				task.create(w, "tunnel", { direction = "down", distance = s1 - 1 }),
				task.create(w, "excavate_bedrock", { l = dim.l, w = dim.w }),
				task.create(w, "tunnel", { direction = "up", distance = s1 - 1 })
			})
		else
			table.insert(segments, i, {
				worker = w,
				r_ypos = rem_h,
				task.create(w, "tunnel", { direction = "down", distance = rem_h }),
				task.create(w, "excavate", { l = dim.l, w = dim.w, h = segment_h[i] })
			})
		end
		rem_h = rem_h - segment_h[i]
		-- Yield to allow the worker to move in order to prevent collision
		---@diagnostic disable-next-line: undefined-global
		sleep(3)
	end

	-- Collect workers
	for i = #segments, 1, -1 do
		task.await(segments[i][2])
		logger.info("recalling worker '" .. segments[i].worker .. "' of segment " .. i)
		task.await(task.create(segments[i].worker, "navigate", { direction = "up", distance = segments[i].r_ypos }))
		worker.collect(segments[i].worker)
	end
end

local function test_master()
	worker.create("dev-worker-1", "miner", 8001)
	worker.create("dev-worker-2", "miner", 8002)
	worker.create("dev-worker-3", "miner", 8003)
	local dim = {
		l = 9,
		w = 3,
		h = 20,
	}
	mine_cuboid(dim)
end

---@diagnostic disable-next-line: undefined-global
parallel.waitForAll(message.listen, master_gps.monitor, task.monitor, test_master)
