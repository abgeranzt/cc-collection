---@diagnostic disable-next-line: unknown-cast-variable
---@cast peripheral peripheral
---@diagnostic disable-next-line: unknown-cast-variable
---@cast gps gps

local const = require("lib.const")

---@param args table The arguments provided to the program
local function init(args)
	local modem = peripheral.find("modem")
	if not modem then
		print("No modem found, exiting!")
		---@diagnostic disable-next-line: undefined-global
		exit()
	end
	---@cast modem modem
	modem.closeAll()

	local argparse = require("lib.argparse")
	argparse.add_arg("log_ch", "-lc", "number", false, 9000)
	argparse.add_arg("log_lvl", "-ll", "string", false, "info")
	argparse.add_arg("master_ch", "-mc", "number", false, 10000)
	argparse.add_arg("listen_ch", "-c", "number", true)
	-- TODO determine direction by myself and make this optinal
	argparse.add_arg("direction", "-d", "string", true, nil, const.DIRECTIONS)

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

	local logger = require("lib.logger").init(log_ch, log_lvl, nil, modem)
	---@cast logger logger

	local dir = parsed_args.direction
	---@cast dir gpslib_direction
	local pos = { dir = dir }
	pos.x, pos.y, pos.z = gps.locate()
	---@cast pos gpslib_position

	local queue = require("lib.queue").queue
	local worker = require("lib.worker.master").init(logger)
	local message = require("lib.message.master").init(modem, listen_ch, logger, {}, master_ch, queue)
	local gpslib = require("lib.gpslib.master").init(worker, logger)
	local task = require("lib.task").master_setup(message.send_cmd, worker, logger)
	local routine = require("lib.routine.master").init(task, worker, logger)

	return logger, gpslib, message, pos, routine, task, worker
end

local logger, gpslib, message, pos, routine, task, worker = init({ ... })


-- TODO get rid of this
local function test_master()
	worker.create("dev-worker-1", "miner", 8001)
	worker.create("dev-worker-2", "miner", 8002)
	-- worker.create("dev-worker-3", "miner", 8003)
	-- worker.create("dev-worker-4", "miner", 8004)

	worker.create("dev-loader-1", "loader", 7001)

	worker.deploy("dev-loader-1", "loader", "up")
	task.create("dev-loader-1", "set_position", { pos = pos })
	task.create("dev-loader-1", "refuel", { target = 1000 })
	local dim = {
		l = 3,
		w = 3,
		h = 12,
	}
	routine.mine_cuboid(pos, dim)
	-- note: swap will not return anything when modem has been unequipped
	-- TODO unequip_modem command? this would make this behavior more self-explanatory
	task.create("dev-loader-1", "swap")
	sleep(1)

	worker.collect("dev-loader-1", "up")
end

---@diagnostic disable-next-line: undefined-global
parallel.waitForAll(message.listen, gpslib.monitor, task.monitor, test_master)
