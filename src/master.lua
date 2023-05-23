---@diagnostic disable-next-line: unknown-cast-variable
---@cast peripheral peripheral
---@diagnostic disable-next-line: unknown-cast-variable
---@cast gps gps

---@param args table The arguments provided to the program
local function setup(args)
	local modem = peripheral.find("modem")
	if not modem then
		print("No modem found, exiting!")
		---@diagnostic disable-next-line: undefined-global
		exit()
	end
	---@cast modem modem

	local argparse = require("lib.argparse")
	argparse.add_arg("log_ch", "-lc", "number", false, 9000)
	argparse.add_arg("log_lvl", "-ll", "string", false, "info")
	argparse.add_arg("master_ch", "-mc", "number", false, 10000)
	argparse.add_arg("listen_ch", "-c", "number", true)

	local parsed_args, e = argparse.parse(args)
	if not parsed_args then
		print(e)
		---@diagnostic disable-next-line: undefined-global
		exit()
	end
	---@cast parsed_args table

	local log_ch = parsed_args.log_ch
	---@cast log_ch integer
	local log_lvl = parsed_args.log_lvl
	---@cast log_lvl log_level
	local listen_ch = parsed_args.listen_ch
	---@cast listen_ch integer
	local master_ch = parsed_args.master_ch
	---@cast master_ch integer

	local logger = require("lib.logger").setup(log_ch, log_lvl, nil, modem)
	---@cast logger logger

	local queue = require("lib.queue").queue
	local worker = require("lib.worker.master").setup(logger)
	local message = require("lib.message.master").setup(modem, listen_ch, logger, {}, master_ch, queue)
	local gpslib = require("lib.gpslib.master").setup(worker, logger)
	local task = require("lib.task").master_setup(message.send_cmd, worker, logger)
	local routine = require("lib.routine").setup(task, worker, logger)

	return logger, gpslib, message, routine, task, worker
end

local logger, gpslib, message, routine, task, worker = setup({ ... })


-- TODO get rid of this
local function test_master()
	-- worker.create("dev-worker-1", "miner", 8001)
	-- worker.create("dev-worker-2", "miner", 8002)
	-- worker.create("dev-worker-3", "miner", 8003)
	worker.create("dev-worker-4", "miner", 8004)
	worker.deploy("dev-worker-4")
	local x, y, z = gps.locate()
	local tid = task.create("dev-worker-4", "set_position", { pos = { x = x, y = y - 1, z = z, dir = "west" } })
	tid = task.create("dev-worker-4", "navigate_pos", { pos = { x = -50, y = y - 1, z = -4, dir = "south" } })
	tid = task.create("dev-worker-4", "navigate_pos", { pos = { x = -48, y = -22, z = -7, dir = "north" } })
	tid = task.create("dev-worker-4", "navigate_pos", { pos = { x = -46, y = y - 1, z = -3, dir = "east" } })
	task.await(tid)
	worker.collect("dev-worker-4")

	-- local dim = {
	-- l = 3,
	-- w = 3,
	-- h = 6,
	-- }
	-- routine.auto_mine(dim, "left", 1)
end

---@diagnostic disable-next-line: undefined-global
parallel.waitForAll(message.listen, gpslib.monitor, task.monitor, test_master)
