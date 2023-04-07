-- TODO make this configurable
local master_ch = 8000

---@diagnostic disable-next-line: undefined-global
local modem = peripheral.find("modem")
if not modem then
	print("No modem found, exiting!")
	---@diagnostic disable-next-line: undefined-global
	exit()
end

local logger = require("lib.logger").setup(9000, "info", "/log", modem)
-- local logger = require("lib.logger").setup(9000, "trace", "/log", modem)
---@cast logger logger

local worker = require("lib.worker").master_setup(logger)
local message = require("lib.message").master_setup(master_ch, modem, worker, logger)
local gps = require("lib.gps").master_setup(worker, logger)
local task = require("lib.task").master_setup(message.send_task, worker, logger)

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

---@param dim dimensions
local function mine_cuboid(dim)
	logger.trace("determining available workers")
	local workers = worker.get_labels("miner")
	local segments = {}
	---@cast segments { worker: string, r_ypos: number }[] | number[][]
	local segment_h = spread_segment(#workers, dim.h)
	-- Track the relative y-position of workers
	local rem_h = dim.h - segment_h[1]

	-- TODO bedrock scraping
	for i, w in ipairs(workers) do
		logger.info("deploying worker '" .. workers[i] .. "' for segment " .. i)
		worker.deploy(workers[i])
		task.await(task.create(workers[i], "refuel", { target = 1000 }))
		table.insert(segments, i, {
			worker = w,
			r_ypos = rem_h,
			task.create(w, "tunnel", { direction = "down", distance = rem_h }),
			task.create(w, "excavate", { l = dim.l, w = dim.w, h = segment_h[i] })
		})
		rem_h = rem_h - segment_h[i]
		-- Wait for arrival to prevent collisions
		task.await(segments[i][1])
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
	-- worker.create("dev-worker-3", "miner", 8003)
	local dim = {
		l = 4,
		w = 4,
		h = 10,
	}
	mine_cuboid(dim)
end

---@diagnostic disable-next-line: undefined-global
parallel.waitForAll(message.listen, gps.monitor, task.monitor, test_master)
