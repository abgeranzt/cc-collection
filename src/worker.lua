local excavate = require("lib.excavate")
local queue = require("lib.queue").queue

local modem = peripheral.find("modem")
if not modem then
	print("No modem found, exiting!")
	exit()
end

-- TODO configure channel
-- local worker_name = "dev-worker1"
local worker_ch = 8000
local master_name = "dev-master1"
local master_ch = 8005

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
		end
	end
	return excavate.dig_cuboid(params.x, params.y, params.z) or false, "excavate command failed"
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
					message.reply(task.id, "ok")
				else
					message.reply(task.id, "err", error)
				end
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
