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
	argparse.add_arg("master_ch", "-mc", "number", true)

	local parsed_args, e = argparse.parse(args)
	if not parsed_args then
		print(e)
		---@diagnostic disable-next-line: undefined-global
		exit()
	end
	---@cast parsed_args table

	local log_ch = parsed_args.log_ch
	---@cast log_ch number
	local log_lvl = parsed_args.log_lvl
	---@cast log_lvl log_level
	local master_ch = parsed_args.master_ch
	---@cast master_ch number

	local logger = require("lib.logger").setup(log_ch, log_lvl, nil, modem)
	---@cast logger logger

	local worker = require("lib.worker").master_setup(logger)
	local message = require("lib.message").master_setup(master_ch, modem, worker, logger)
	local master_gps = require("lib.gps").master_setup(worker, logger)
	local task = require("lib.task").master_setup(message.send_task, worker, logger)
	local routine = require("lib.master.routine").setup(task, worker, logger)

	return logger, master_gps, message, routine, task, worker
end

local logger, master_gps, message, routine, task, worker = setup({ ... })


-- TODO get rid of this
local function test_master()
	-- worker.create("dev-worker-1", "miner", 8001)
	-- worker.create("dev-worker-2", "miner", 8002)
	worker.create("dev-worker-3", "miner", 8003)
	worker.create("dev-worker-4", "miner", 8004)
	local dim = {
		l = 3,
		w = 3,
		h = 6,
	}
	routine.auto_mine(dim, "left", 2)
end

---@diagnostic disable-next-line: undefined-global
parallel.waitForAll(message.listen, master_gps.monitor, task.monitor, test_master)
