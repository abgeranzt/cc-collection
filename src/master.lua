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
	-- TODO determine direction by myself using compass or moving the turtle and make this optinal
	argparse.add_arg("direction", "-d", "string", true, nil, const.DIRECTIONS)
	argparse.add_arg("fuel_type", "-f", "enum", false, "consumable", const.FUEL_TYPES)
	argparse.add_arg("listen_ch", "-c", "number", true)
	argparse.add_arg("log_ch", "-lc", "number", false, 9000)
	argparse.add_arg("log_lvl", "-ll", "string", false, "info")
	argparse.add_arg("master_ch", "-mc", "number", false, 10000)
	argparse.add_arg("master_name", "-mn", "string", false, "")

	local parsed_args, e = argparse.parse(args)
	if not parsed_args then
		print(e)
		---@diagnostic disable-next-line: undefined-global
		exit()
	end
	---@cast parsed_args table

	local config = require("lib.config").init({
		fuel_type = parsed_args.fuel_type,
		listen_ch = parsed_args.listen_ch,
		log_ch = parsed_args.log_ch,
		log_lvl = parsed_args.log_lvl,
		master_ch = parsed_args.master_ch,
		master_name = parsed_args.master_name,
	})

	local logger = require("lib.logger").init(config.log_ch, config.log_lvl, nil, modem)
	local queue = require("lib.queue").queue
	local worker = require("lib.worker.master").init(logger)
	local message = require("lib.message.master").init(modem, config.listen_ch, logger, {}, config.master_ch, queue)
	local task = require("lib.task").init(message.send_cmd, worker, logger)
	local routine = require("lib.routine.master").init(config, task, worker, logger)

	local dir = parsed_args.direction
	---@cast dir gpslib_direction
	local gpslib = require("lib.gpslib.master").init(worker, logger, dir)

	return config, logger, gpslib, message, routine, task, worker
end

local config, logger, gpslib, message, routine, task, worker = init({ ... })


-- TODO get rid of this
local function test_master()
	worker.create("dev-worker-1", "miner", 8001)
	worker.create("dev-worker-2", "miner", 8002)
	worker.create("dev-worker-3", "miner", 8003)
	worker.create("dev-worker-4", "miner", 8004)
	worker.create("dev-worker-5", "miner", 8005)
	worker.create("dev-worker-6", "miner", 8006)

	worker.create("dev-loader-1", "loader", 7001)
	worker.create("dev-loader-2", "loader", 7002)
	worker.create("dev-loader-3", "loader", 7003)
	worker.create("dev-loader-4", "loader", 7004)

	local ok, err = routine.auto_mine_chunk(gpslib.position, 1, "north", true, 1)
	if ok then
		print("success")
	else
		print(err)
	end
	exit()
end

---@diagnostic disable-next-line: undefined-global
parallel.waitForAll(message.listen, gpslib.monitor, gpslib.work_updates, task.monitor, test_master)
