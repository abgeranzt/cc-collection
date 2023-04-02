local queue = require("lib.queue").queue

---@diagnostic disable-next-line: undefined-global
local modem = peripheral.find("modem")
if not modem then
	print("No modem found, exiting!")
	---@diagnostic disable-next-line: undefined-global
	exit()
end

-- TODO error handling + help
local worker_ch, master_name, master_ch = ...
worker_ch = tonumber(worker_ch)
---@cast worker_ch number
master_ch = tonumber(master_ch)
---@cast master_ch number

local logger = require("lib.logger").setup(9000, "debug", "/log", modem)
-- local logger = require("lib.logger").setup(9000, "trace", "/log", modem)
---@cast logger logger

local message = require("lib.message").worker_setup(worker_ch, master_name, master_ch, queue, modem, logger)
local gps = require("lib.gps").worker_setup(message.send_gps, logger)
local command = require("lib.command").miner_setup(logger)

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
			---@diagnostic disable-next-line: undefined-global
			sleep(0.5)
		end
	end
end

local function main()
	logger.debug("STARTING worker test")
	---@diagnostic disable-next-line: undefined-global
	parallel.waitForAll(message.listen, work_queue, gps.monitor)
end

main()
