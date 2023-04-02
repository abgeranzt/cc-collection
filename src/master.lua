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

local function test_master()
	worker.create("dev-worker-1", "miner", 8001)
	worker.create("dev-worker-2", "miner", 8002)
	worker.deploy("dev-worker-1")
	local w1_t1 = task.create("dev-worker-1", "tunnel", {
		direction = "down",
		distance = 1
	})
	local w1_t2 = task.create("dev-worker-1", "excavate", {
		x = 3, y = 3, z = 2
	})
	local w1_t3 = task.create("dev-worker-1", "excavate_bedrock", {
		x = 3, y = 3
	})
	task.await(w1_t1)
	worker.deploy("dev-worker-2")
	local w2_t1 = task.create("dev-worker-2", "excavate", {
		x = 3, y = 3, z = 1
	})
	task.await(w2_t1)
	worker.collect("dev-worker-2")
	task.await(w1_t3)
	local w1_t4 = task.create("dev-worker-1", "navigate", {
		direction = "up",
		distance = 1
	})
	task.await(w1_t4)
	worker.collect("dev-worker-1")
end

---@diagnostic disable-next-line: undefined-global
parallel.waitForAll(message.listen, gps.monitor, task.monitor, test_master)
