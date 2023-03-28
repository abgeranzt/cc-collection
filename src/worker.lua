local excavate = require("lib.excavate")
local queue = require("lib.queue").queue
local go = require("lib.navigate").go

local modem = peripheral.find("modem")
if not modem then
	print("No modem found, exiting!")
	exit()
end

-- TODO program parameters
-- local worker_name = "dev-worker1"
local worker_ch = 8000
local master_name = "dev-master1"
local master_ch = 8005
local logger = require("lib.logger").setup(9000, "debug", "/log", modem)
--- @cast logger logger

local message = require("lib.message").worker_setup(worker_ch, master_name, master_ch, queue, modem)

--- @alias command "excavate" | "navigate" | "exec"
local commands = {
}

--- @param params {x: number, y: number, z: number}
function commands.excavate(params)
	-- validate params
	for _, c in ipairs({ "x", "y", "z" }) do
		if not params[c] then
			local e = "missing parameter '" .. c .. "'"
			--- @cast e string
			return false, e
		elseif type(params[c]) ~= "number" then
			local e = "invalid parameter '" .. c .. "'"
			--- @cast e string
			return false, e
		end
	end
	local success, error = excavate.dig_cuboid(params.x, params.y, params.z)
	if success then
		return true
	else
		--- @cast error string
		logger.error(error)
		return false, "excavate command failed"
	end
end

--- @alias direction "forward" | "back" | "up" | "down" | "left" | "right"
local directions = {
	forward = true,
	back = true,
	up = true,
	down = true,
	left = true,
	right = true
}
--- @param params {direction: direction, distance: number}
function commands.navigate(params)
	-- TODO implement debugging via os events
	-- FIXME this does not work
	-- validate params
	if not params.direction then
		local e = "missing parameter direction"
		--- @cast e string
		return false, e
	end
	if not directions[params.direction]
		or type(params.direction) ~= "string"
	then
		local e = "invalid parameter direction '" .. params.direction .. "'"
		--- @cast e string
		return false, e
	end
	if not params.distance then
		local e = "missing parameter distance"
		--- @cast e string
		return false, e
	end
	if type(params.distance) ~= "number" then
		local e = "invalid parameter distance '" .. params.distance .. "'"
		--- @cast e string
		return false, e
	end

	local success, error = go[params.direction](params.distance)
	if success then
		return true
	else
		--- @cast error string
		logger.error(error)
		return false, "navigate command failed"
	end
end

local function work_queue()
	while true do
		if queue.len > 0 then
			local task = queue.pop()
			--- @alias task {reply_ch: number, id: number, body: {cmd: string, params: table}}
			--- @cast task task
			if commands[task.body.cmd] then
				local status, error = commands[task.body.cmd](task.body.params)
				if status then
					logger.info("command '" .. task.body.cmd .. "' successful")
					logger.info("task" .. task.id .. " completed")
					message.reply(task.id, "ok")
				else
					logger.error(error)
					message.reply(task.id, "err", error)
				end
			else
				local error = "invalid command '" .. task.body.cmd .. "'"
				logger.error(error)
				message.reply(task.id, "err", error)
			end
		else
			sleep(0.5)
		end
	end
end

-- TODO track worker position

local function main()
	parallel.waitForAll(message.listen, work_queue)
end

main()
