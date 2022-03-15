COMMANDS = {
	kill = function(args) os.shutdown() end,
	run = function(args) return os.run({}, unpack(args)) end,
	qfuel = function(args) return turtle.getFuelLevel() end
}

local queue = {fpos = 1, lpos = 1, len = 0}

-- TODO efficient and ordered queue implementation
function queue.push(task)
	queue[queue.fpos] = task
	queue.fpos = queue.fpos + 1
	queue.len = queue.len + 1
end

function queue.pop()
	task = queue[queue.lpos]
	queue[queue.lpos] = nil
	queue.lpos = queue.lpos + 1
	queue.len = queue.len - 1
	return task
end

modem = peripheral.find("modem")
ch = ...
ch = tonumber(ch)

function parse_message(msg, reply_ch)
	local task = {reply_ch = reply_ch}
	-- syntax: cmd-arg1,argN
	-- syntax for run: run-FULLPATH,arg1,argN
	local f = string.gmatch(msg, "[^:]+")
	task.job_id = f()
	task.cmd = f()
	task.args = {}
	local args = f()
	if args and #args > 0 then
		for a in string.gmatch(args, "[^,]+") do table.insert(task.args, a) end
	end
	return task
end

function listen()
	modem.open(ch)
	local _e, _s, _c, rep_ch, msg, _d
	local task
	while true do
		os.startTimer(1)
		_e, _s, _c, reply_ch, msg, _d = os.pullEvent("modem_message")
		task = parse_message(msg, reply_ch)
		queue.push(task)
		modem.transmit(reply_ch, ch, task.job_id .. ":ack")
	end
end

function exec_task(task)
	local reply = {err = true}
	if not task.cmd then
		reply.msg = "No command provided"
	elseif not COMMANDS[task.cmd] then
		reply.msg = "Invalid command '" .. task.cmd .. "'"
	else
		reply.msg = COMMANDS[task.cmd](task.args)
		reply.err = false
	end
	return reply
end

function work_queue()
	local reply, status, task
	while true do
		if queue.len > 0 then
			task = queue.pop()
			reply = exec_task(task)
			status = reply.err and "err" or "ok"
			-- TODO more info in reply?
			modem.transmit(task.reply_ch, 0,
				task.job_id .. ":" .. status .. ":" .. tostring(reply.msg))
		else
			sleep(0.1)
		end
	end
end

function main()
	if not modem then
		print("No wireless modem detected. Quitting")
		return
	end
	if not ch then
		print("No channel specified. Quiting")
		return

	end
	parallel.waitForAll(listen, work_queue)
end

main()
