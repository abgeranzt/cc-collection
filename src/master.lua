local master_ch = 8000

--- @diagnostic disable-next-line: undefined-global
local modem = peripheral.find("modem")
if not modem then
	print("No modem found, exiting!")
	--- @diagnostic disable-next-line: undefined-global
	exit()
end

local workers = {}
--- @cast workers worker[]

--- @param label string
--- @param worker_ch number
function workers.create(label, worker_ch)
	workers[label] = {
		label = label,
		channel = worker_ch,
		deployed = false,
	}
end

local logger = require("lib.logger").setup(9000, "debug", "/log", modem)
-- local logger = require("lib.logger").setup(9000, "trace", "/log", modem)
--- @cast logger logger

local message = require("lib.message").master_setup(master_ch, modem, workers, logger)
local gps = require("lib.gps").master_setup(workers, logger)
local task = require("lib.task").master_setup(message.send_task, logger)

local function test_print_workers()
	while true do
		require("lib.debug").print_table(workers["dev-worker1"])
		--- @diagnostic disable-next-line: undefined-global
		sleep(3)
	end
end

workers.create("dev-worker1", 8001)

task.create(workers['dev-worker1'], "tunnel", { direction = "down", distance = 5 })
task.create(workers['dev-worker1'], "tunnel", { direction = "right", distance = 3 })
task.create(workers['dev-worker1'], "tunnel", { direction = "up", distance = 5 })
task.create(workers['dev-worker1'], "tunnel", { direction = "left", distance = 3 })

--- @diagnostic disable-next-line: undefined-global
parallel.waitForAll(message.listen, gps.monitor, task.monitor)
