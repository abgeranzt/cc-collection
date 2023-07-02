---@diagnostic disable-next-line: unknown-cast-variable
---@cast peripheral peripheral
---@diagnostic disable-next-line: unknown-cast-variable
---@cast turtle turtle

local const = require("lib.const")
local util = require("lib.util")

---@param args table The arguments provided to the program
local function init(args)
	local queue = require("lib.queue").queue

	if not util.has_item(const.ITEM_MODEM, const.SLOT_LOADER_SWAP) then
		print("No modem found, exiting!")
		---@diagnostic disable-next-line: undefined-global
		exit()
	end
	turtle.select(const.SLOT_LOADER_SWAP)
	turtle.equipRight()
	local modem = peripheral.find("modem")
	---@cast modem modem
	modem.closeAll()

	local argparse = require("lib.argparse")
	argparse.add_arg("fuel_type", "-f", "enum", false, "consumable", const.FUEL_TYPES)
	argparse.add_arg("listen_ch", "-c", "number", true)
	argparse.add_arg("log_ch", "-lc", "number", false, 9000)
	argparse.add_arg("log_lvl", "-ll", "string", false, "info")
	argparse.add_arg("master_ch", "-mc", "number", true)
	argparse.add_arg("master_name", "-mn", "string", true)

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
		slot_dump = const.SLOT_DUMP,
		slot_first_free = const.SLOT_LOADER_FIRST_FREE,
		slot_fuel = const.SLOT_FUEL
	})

	local logger = require("lib.logger").init(config.log_ch, config.log_lvl, nil, modem)

	local masters = {}
	masters[config.master_name] = true
	local message = require("lib.message.controllable").init(
		modem, config.listen_ch, logger, masters, config.master_ch, queue
	)
	local gpslib = require("lib.gpslib.common").init(message.send_gps, logger)
	local command = require("lib.command.loader").init(config, logger, gpslib.position, modem, config.listen_ch)

	return config, command, gpslib, message, logger, queue
end

local config, command, gpslib, message, logger, queue = init({ ... })

local function work_queue()
	while true do
		if queue.len > 0 then
			local task = queue.pop()
			---@cast task worker_task
			logger.info("executing task " .. task.id)
			if command[task.body.cmd] then
				local status, err, out = command[task.body.cmd](task.body.params)
				if status then
					logger.info("command '" .. task.body.cmd .. "' successful")
					logger.info("task " .. task.id .. " complete")
					message.reply(config.master_ch, config.master_name, task.id, "ok", out)
				else
					---@cast err string
					logger.error(err)
					message.reply(config.master_ch, config.master_name, task.id, "err", err)
				end
			else
				local err = "invalid command '" .. task.body.cmd .. "'"
				logger.error(err)
				message.reply(config.master_ch, config.master_name, task.id, "err", err)
			end
		else
			sleep(0.5)
		end
	end
end

local function main()
	logger.info("starting loader")
	---@diagnostic disable-next-line: undefined-global
	parallel.waitForAll(message.listen, work_queue, gpslib.work_updates)
end

main()
