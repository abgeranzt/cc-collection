local master_ch = 8000

local modem = peripheral.find("modem")
if not modem then
	print("No modem found, exiting!")
	exit()
end

local workers = {}

--- @param label string
function workers.create(label)
	workers[label] = {
		deployed = false,
		position = {
			x = nil,
			y = nil,
			z = nil
		}
	}
end

workers.create("dev-worker1")

local logger = require("lib.logger").setup(9000, "debug", "/log", modem)
-- local logger = require("lib.logger").setup(9000, "trace", "/log", modem)
--- @cast logger logger

local message = require("lib.message").master_setup(master_ch, modem, workers, logger)
local gps = require("lib.gps").master_setup(workers, logger)

parallel.waitForAll(message.listen, gps.monitor)
