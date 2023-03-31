local get_label = require("lib.util").get_label

local message_types = {
	cmd = true,
	res = true,
	gps = true,
}

local status_types = {
	err = true,
	ok = true
}


--- @param master_ch number
--- @param modem modem
--- @param workers {[string]: true}
--- @param logger logger
local function master_setup(master_ch, modem, workers, logger)
	-- TODO refactor this to only return public functions (see gps/task)
	local message = {
		_id = 1,
		_label = get_label()
	}

	--- @param msg msg
	function message._validate(msg)
		-- Drop the message if it is malformed or not intended for us.
		if type(msg) ~= "table"
			or not msg.rec
			or msg.rec ~= message._label
			or not msg.snd
			or not workers[msg.snd]
			or not message_types[msg.type]
			or not msg.payload
			or type(msg.payload) ~= "table"
			or not msg.payload.id
			or type(msg.payload.id) ~= "number"
		then
			logger.trace("dropped: malformed")
			return false
		end
		-- Validate response
		if msg.type == "res" then
			if not msg.payload.status
				or not status_types[msg.payload.status]
			then
				logger.trace("dropped: malformed res")
				return false
			end
			return true
			-- Validate gps update
		elseif msg.type == "gps" then
			if not msg.payload.body
				or type(msg.payload.body) ~= "table"
			then
				logger.trace("dropped: malformed gps")
				return false
			end
			for _, c in ipairs({ "x", "y", "z" }) do
				if not msg.payload.body[c]
					or type(msg.payload.body[c]) ~= "number"
				then
					logger.trace("dropped: malformed gps (coordinates)")
					return false
				end
			end
			return true
		end
	end

	function message.listen()
		modem.open(master_ch)
		while true do
			--- @diagnostic disable-next-line: undefined-field, unused-local
			local _e, _s, _c, _rc, msg, _d = os.pullEvent("modem_message")
			--- @cast msg msg
			if message._validate(msg) then
				logger.debug("valid message " .. msg.payload.id .. " type: '" .. msg.type .. "'")
				if msg.type == "gps" then
					--- @diagnostic disable-next-line: undefined-field
					os.queueEvent("gps_update", msg)
				elseif msg.type == "res" then
					--- @diagnostic disable-next-line: undefined-field
					os.queueEvent("task_update", msg.payload.id, msg.payload.status)
				end
			else
				logger.trace("dropping invalid message")
			end
		end
	end

	--- @param target_ch number
	--- @param msg_target string
	--- @param msg_type msg_type
	--- @param payload msg_payload
	function message._send(target_ch, msg_target, msg_type, payload)
		local msg = {
			snd = message._label,
			rec = msg_target,
			type = msg_type,
			payload = payload
		}
		logger.debug("sending '" .. msg_type .. "' message " .. msg.payload.id .. " to '" .. msg_target .. "'")
		modem.transmit(target_ch, master_ch, msg)
	end

	--- @param msg_target string
	--- @param payload msg_payload
	function message.send_task(target_ch, msg_target, payload)
		message._send(target_ch, msg_target, "cmd", payload)
	end

	return message
end


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
			logger.trace("dropped: malformed")
			return false
		end
		-- Validate command
		if msg.type == "cmd" then
			if not msg.payload.body
				or type(msg.payload.body) ~= "table"
				or not msg.payload.body.cmd
				or type(msg.payload.body.cmd) ~= "string"
			then
				logger.trace("dropped: malformed cmd")
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
	--- @param status msg_status
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


return {
	master_setup = master_setup,
	worker_setup = worker_setup
}
