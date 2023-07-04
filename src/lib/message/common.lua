---@diagnostic disable-next-line: unknown-cast-variable
---@cast os os

local const = require("lib.const")

---@param modem modem
---@param listen_ch integer
---@param logger lib_logger
local function init(modem, listen_ch, logger)
	---@class lib_message_common Common communication functionality
	local lib = {}
	lib.label = os.getComputerLabel()

	-- NOTE: expand this
	lib.msg_types = {}

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
	-- - validate the message
	-- - call the configured handler for the message type
	function lib.listen()
		logger.info("listening on channel " .. listen_ch)
		modem.open(listen_ch)
		while true do
			local _e, _s, _c, reply_ch, msg, _d = os.pullEvent("modem_message")
			-- Ignore gps replies, they are handled by the built-in gps library.
			if reply_ch == const.CH_GPS then
				logger.trace("ignoring gps message")
			elseif lib.validate(msg) then
				---@cast msg msg
				logger.trace("valid message")
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
	init = init
}
