---@diagnostic disable-next-line: unknown-cast-variable
---@cast os os

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

local log_levels = {
	trace = 1,
	debug = 2,
	info = 3,
	warn = 4,
	error = 5,
	fatal = 6
}

-- TODO error handling for this?
---@param log_ch number
---@param modem modem
---@param log_level log_level
local function log_server_setup(log_ch, modem, log_level)
	local log_level_num = log_levels[log_level]

	---@param msg string
	---@return log_event
	local function _parse(msg)
		local snd = string.match(msg, "%[.+%]%s%-%s")
		local msg_raw = msg
		snd = string.sub(snd, 2, string.len(snd) - 4)
		msg = string.gsub(msg, "%[.+%]%s%-%s", "", 1)
		local lvl = string.match(msg, "%a+: ")
		lvl = string.lower(string.sub(lvl, 1, string.len(lvl) - 2))
		msg = string.gsub(msg, "%a+: ", "", 1)
		return {
			snd = snd,
			lvl = lvl,
			msg = msg,
			raw = msg_raw
		}
	end


	local function listen()
		modem.open(log_ch)
		while true do
			local _e, _s, _c, _rc, msg, _d = os.pullEvent("modem_message")
			local event = _parse(msg)
			if log_levels[event.lvl] >= log_level_num then
				os.queueEvent("log_message", _parse(msg))
			end
		end
	end

	return {
		listen = listen
	}
end

---@param master_ch number
---@param modem modem
---@param worker {get: fun(label: string)}
---@param logger logger
local function master_setup(master_ch, modem, worker, logger)
	local _label = get_label()

	---@param msg msg
	local function _validate(msg)
		-- Drop the message if it is malformed or not intended for us.
		if type(msg) ~= "table"
			or not msg.rec
			or msg.rec ~= _label
			or not msg.snd
			or not worker.get(msg.snd)
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

	local function listen()
		logger.info("listening on channel " .. master_ch)
		modem.open(master_ch)
		while true do
			local _e, _s, _c, _rc, msg, _d = os.pullEvent("modem_message")
			---@cast msg msg
			if _validate(msg) then
				-- TODO re-enable it when development is finished
				-- logger.debug("valid message " .. msg.payload.id .. " type: '" .. msg.type .. "'")
				if msg.type == "gps" then
					os.queueEvent("gps_update", msg)
				elseif msg.type == "res" then
					os.queueEvent("task_update", msg.payload.id, msg.payload.status, msg.payload.body)
				end
			else
				logger.trace("dropping invalid message")
			end
		end
	end

	---@param target_ch number
	---@param msg_target string
	---@param msg_type msg_type
	---@param payload msg_payload
	local function _send(target_ch, msg_target, msg_type, payload)
		local msg = {
			snd = _label,
			rec = msg_target,
			type = msg_type,
			payload = payload
		}
		logger.debug("sending '" .. msg_type .. "' message " .. msg.payload.id .. " to '" .. msg_target .. "'")
		modem.transmit(target_ch, master_ch, msg)
	end

	---@param msg_target string
	---@param payload msg_payload
	local function send_task(target_ch, msg_target, payload)
		_send(target_ch, msg_target, "cmd", payload)
	end

	return {
		listen = listen,
		send_task = send_task
	}
end



return {
	log_server_setup = log_server_setup,
	master_setup = master_setup,
}
