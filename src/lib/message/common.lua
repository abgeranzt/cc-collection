---@diagnostic disable-next-line: unknown-cast-variable
---@cast os os

---@param modem modem
---@param listen_ch integer
---@param senders msg_senders
---@param logger logger
local function setup(modem, listen_ch, senders, logger)
	local lib = {}
	lib.label = os.getComputerLabel()

	-- NOTE: expand this
	lib.msg_types = {
		res = true,
	}

	-- NOTE: expand this
	lib.validators = {}

	---@param msg msg
	function lib.validate(msg)
		-- Drop the message if it is malformed or not intended for us.
		if type(msg) ~= "table"
			or not msg.rec
			or msg.rec ~= lib.label
			or not msg.snd
			or not lib.msg_types[msg.type]
			or not msg.payload
			or type(msg.payload) ~= "table"
		then
			logger.trace("dropped: malformed")
		elseif not senders[msg.snd] then
			logger.trace("dropped: invalid sender")
		elseif not lib.validators[msg.type] then
			logger.trace("dropped: no validator")
		else
			-- Choose validator based on message type.
			return lib.validators[msg.type](msg)
		end
		return false
	end

	-- NOTE: expand this
	lib.handlers = {}

	-- Handle modem messages. This includes the following:
	-- - decide whether to keep or drop messages
	-- - append it to the task queue if the message is a command
	-- - reply ("acknowledge") to messages
	function lib.listen()
		logger.info("listening on channel " .. listen_ch)
		modem.open(listen_ch)
		while true do
			local _e, _s, _c, _rc, msg, _d = os.pullEvent("modem_message")
			if lib.validate(msg) then
				---@cast msg msg
				logger.debug("valid message " .. msg.payload.id .. " type: '" .. msg.type .. "'")
				if not lib.handlers[msg.type] then
					logger.warn("no handler for message type '" .. msg.type .. "'")
				else
					lib.handlers[msg.type](msg)
				end
			else
				logger.trace("dropping invalid message")
			end
		end
	end

	---@param ch integer
	---@param rec_name string
	---@param msg_type msg_type
	---@param payload msg_payload
	function lib.send_msg(ch, rec_name, msg_type, payload)
		logger.debug("ch: " .. ch .. " rec_name: " .. rec_name)
		local msg = {
			rec = rec_name,
			snd = lib.label,
			type = msg_type,
			payload = payload
		}
		modem.transmit(ch, listen_ch, msg)
	end

	---@param ch integer
	---@param rec_name string
	---@param id number
	---@param status msg_status
	---@param body string | nil
	function lib.reply(ch, rec_name, id, status, body)
		local payload = {
			id = id,
			status = status,
			body = body
		}
		lib.send_msg(ch, rec_name, "res", payload)
	end

	return lib
end

return {
	setup = setup
}
