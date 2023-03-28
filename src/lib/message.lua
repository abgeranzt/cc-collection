--- @alias msg_type "res" | "cmd"
local message_types = {
	res = true,
	cmd = true
}

--- @alias status "ack" | "err" | "ok"
local status_types = {
	ack = true,
	err = true,
	ok = true
}

--- @param worker_ch number
--- @param master_name string
--- @param master_ch number
--- @param queue {push: fun(task: table)}
--- @param modem {open: fun(channel: number)}
--- @param logger logger
local function worker_setup(worker_ch, master_name, master_ch, queue, modem, logger)
	local message = {
	}

	--- @alias payload {id: number, body: {cmd: string, params: table | nil} | nil, status: status | nil}
	--- @alias msg {rec: string, snd: string, type: msg_type, payload: payload | nil }

	--- @param msg msg
	function message.validate(msg)
		-- Drop the message if it is malformed or not intended for us.
		if type(msg) ~= "table"
			or not msg.rec
			--- @diagnostic disable-next-line: undefined-field
			or msg.rec ~= os.computerLabel()
			or not msg.snd
			or msg.snd ~= master_name
			or not message_types[msg.type]
			or not msg.payload
			or type(msg.payload) ~= "table"
		then
			return false
		end
		-- Validate command
		if msg.type == "cmd" then
			if not msg.payload.body
				or type(msg.payload.body) ~= "table"
				or not msg.payload.body.cmd
				or type(msg.payload.body.cmd) ~= "string"
			then
				return false
			end
		end
		-- Validate response
		if msg.type == "res" then
			if not msg.payload.status
				or not status_types[msg.payload.status]
			then
				return false
			end
		end
		return true
	end

	--- @param msg msg
	function message._create_task(msg)
		local task = {
			reply_ch = master_ch,
			id = msg.payload.id,
			body = msg.payload.body,
		}
		queue.push(task)
	end

	-- Handle modem messages. This includes the following:
	-- - decide whether to keep or drop messages
	-- - append it to the task queue if the message is a command
	-- - reply ("acknowledge") to messages
	function message.listen()
		modem.open(worker_ch)
		while true do
			--- @diagnostic disable-next-line: undefined-field
			local _e, _s, _c, _rc, msg, _d = os.pullEvent("modem_message")
			if message.validate(msg) then
				--- @cast msg msg
				logger.debug("valid message " .. msg.payload.id .. " type: '" .. msg.type .. "'")
				if msg.type == "cmd" then
					logger.info("creating task " .. msg.payload.id)
					message._create_task(msg)
					message.reply(msg.payload.id, "ack")
				else
					logger.trace("dropping non-command message")
				end
			else
				logger.trace("dropping invalid message")
			end
		end
	end

	--- @param id number
	--- @param status status
	--- @param text string | nil
	function message.reply(id, status, text)
		local msg = {
			rec = master_name,
			--- @diagnostic disable-next-line: undefined-field
			snd = os.computerLabel(),
			type = "res",
			payload = {
				id = id,
				status = status,
				text = text,
			}
		}
		--- @diagnostic disable-next-line: undefined-field
		modem.transmit(master_ch, worker_ch, msg)
	end

	return message
end

return { worker_setup = worker_setup }
