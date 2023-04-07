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

---@param dim dimensions
local function mine_cuboid(dim)
	logger.trace("determining available workers")
	local workers = worker.get_labels("miner")
	local segments = {}
	---@cast segments {worker: string, r_ypos: number}[] | number[][]
	local segment_h = dim.h / #workers
	---@cast segment_h number
	-- Track the relative y-position of workers
	local rem_h = dim.h - segment_h
	-- TODO bedrock scraping
	-- Setup first worker
	do
		logger.info("deploying worker 1")
		worker.deploy(workers[1])
		-- TODO more robust fuel handling
		-- Refuel
		local ftid = task.create(workers[1], "get_fuel")
		task.await(ftid)
		if task.get_data(ftid) < 1000 then
			task.await(task.create(workers[1], "refuel"))
		end
		-- Remaining height that could not be distributed evenly
		local first_segment_h = segment_h + dim.h % #workers
		segments[1] = {
			worker = workers[1],
			r_ypos = rem_h,
			task.create(workers[1], "tunnel", { direction = "down", distance = rem_h }),
			task.create(workers[1], "excavate", { l = dim.l, w = dim.w, h = first_segment_h })
		}
		rem_h = rem_h - first_segment_h
	end
	-- Setup remaining workers
	for i, w in ipairs(workers) do
		if i ~= 1 then
			logger.info("deploying worker " .. i)
			worker.deploy(workers[i])
			-- TODO more robust fuel handling
			local ftid = task.create(workers[i], "get_fuel")
			task.await(ftid)
			if task.get_data(ftid) < 1000 then
				task.await(task.create(workers[i], "refuel"))
			end
			table.insert(segments, i, {
				worker = w,
				r_ypos = rem_h,
				task.create(w, "navigate", { direction = "down", distance = rem_h }),
				task.create(w, "excavate", { l = dim.l, w = dim.w, h = segment_h })
			})
			rem_h = rem_h - segment_h
		end
	end
	-- Collect workers
	for i = #segments, 1, -1 do
		task.await(segments[i][2])
		task.await(task.create(segments[i].worker, "navigate", { direction = "up", distance = segments[i].r_ypos }))
		worker.collect(segments[i].worker)
	end
end

local function test_master()
	worker.create("dev-worker-1", "miner", 8001)
	worker.create("dev-worker-2", "miner", 8002)
	worker.create("dev-worker-3", "miner", 8003)
	local dim = {
		l = 3,
		w = 3,
		h = 9,
	}
	mine_cuboid(dim)
end

---@diagnostic disable-next-line: undefined-global
parallel.waitForAll(message.listen, gps.monitor, task.monitor, test_master)
