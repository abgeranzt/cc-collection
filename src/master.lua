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
	worker.deploy("dev-worker-1")
	task.create("dev-worker-1", "navigate", {
		direction = "forward",
		distance = 2
	})
	local tid = task.create("dev-worker-1", "navigate", {
		direction = "back",
		distance = 2
	})
	task.await(tid)
	worker.collect("dev-worker-1")
end

---@diagnostic disable-next-line: undefined-global
parallel.waitForAll(message.listen, gps.monitor, task.monitor, test_master)
