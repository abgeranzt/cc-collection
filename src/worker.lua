---@diagnostic disable-next-line: unknown-cast-variable
---@cast peripheral peripheral

---@param args table The arguments provided to the program
local function setup(args)
	local queue = require("lib.queue").queue
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
	argparse.add_arg("master_name", "-mn", "string", true)
	argparse.add_arg("worker_ch", "-wc", "number", true)
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
	local master_name = parsed_args.master_name
	---@cast master_name string
	local worker_ch = parsed_args.worker_ch
	---@cast worker_ch number

	local logger = require("lib.logger").setup(log_ch, log_lvl, nil, modem)
	---@cast logger logger
	local message = require("lib.message").worker_setup(worker_ch, master_name, master_ch, queue, modem, logger)
	local worker_gps = require("lib.gps").worker_setup(message.send_gps, logger)
	local command = require("lib.command.miner").setup(logger)

	return command, worker_gps, message, logger, queue
end

local command, worker_gps, message, logger, queue = setup({ ... })

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
					message.reply(task.id, "ok", out)
				else
					---@cast err string
					logger.error(err)
					message.reply(task.id, "err", err)
				end
			else
				local err = "invalid command '" .. task.body.cmd .. "'"
				logger.error(err)
				message.reply(task.id, "err", err)
			end
		else
			sleep(0.5)
		end
	end
end

local function main()
	logger.info("starting worker")
	---@diagnostic disable-next-line: undefined-global
	parallel.waitForAll(message.listen, work_queue, worker_gps.monitor)
end

main()
