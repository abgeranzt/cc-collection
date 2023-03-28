local get_label = require("lib.util").get_label

--- @alias msg_type "cmd" | "res" | "gps"
local message_types = {
	cmd = true,
	res = true,
	gps = true,
}

--- @alias status "err" | "ok"
local status_types = {
	err = true,
	ok = true
}

--- @alias modem {open: fun(channel: number), transmit: fun(c: number, rc: number, msg: string | table)}
--- @alias msg_body {cmd: string | nil, params: table | nil, x: number | nil, z: number | nil, y: number | nil}
--- @alias msg_payload {id: number, body: msg_body | nil, status: status | nil}
--- @alias msg {rec: string, snd: string, type: msg_type, payload: msg_payload | nil }

--- @param worker_ch number
--- @param master_name string
--- @param master_ch number
--- @param queue {push: fun(task: table)}
--- @param modem modem
--- @param logger logger
local function worker_setup(worker_ch, master_name, master_ch, queue, modem, logger)
	local message = {
		_label = get_label()
	}

	--- @param msg msg
	function message._validate(msg)
		-- Drop the message if it is malformed or not intended for us.
		if type(msg) ~= "table"
			or not msg.rec
			or msg.rec ~= message._label
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
			--- @diagnostic disable-next-line: undefined-field, unused-local
			local _e, _s, _c, _rc, msg, _d = os.pullEvent("modem_message")
			if message._validate(msg) then
				--- @cast msg msg
				logger.debug("valid message " .. msg.payload.id .. " type: '" .. msg.type .. "'")
				if msg.type == "cmd" then
					logger.info("creating task " .. msg.payload.id)
					message._create_task(msg)
				else
					logger.trace("dropping non-command message")
				end
			else
				logger.trace("dropping invalid message")
			end
		end
	end

	--- @param type msg_type
	--- @param payload msg_payload
	function message._send(type, payload)
		local msg = {
			rec = master_name,
			snd = message._label,
			type = type,
			payload = payload
		}
		modem.transmit(master_ch, worker_ch, msg)
	end

	--- @param payload msg_payload
	function message.send_gps(payload)
		message._send("gps", payload)
	end

	--- @param id number
	--- @param status status
	--- @param text string | nil
	function message.reply(id, status, text)
		local payload = {
			id = id,
			status = status,
			text = text
		}
		message._send("res", payload)
	end

	return message
end

return { worker_setup = worker_setup }
