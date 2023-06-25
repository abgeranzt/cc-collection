local common = require("lib.message.common")

---@param modem modem
---@param listen_ch integer
---@param logger lib_logger
---@param masters {[string]: true}
---@param queue queue
local function init(modem, listen_ch, logger, masters, master_ch, queue)
	---@class lib_message_controllable: lib_message_common Communication functionality for controllable computers
	local lib = common.init(modem, listen_ch, logger)

	lib.msg_types.cmd = true
	lib.msg_types.gps = true

	---@param msg msg
	function lib.validators.cmd(msg)
		if not msg.payload.body
			or type(msg.payload.body) ~= "table"
			or not msg.payload.body.cmd
			or type(msg.payload.body.cmd) ~= "string"
		then
			logger.trace("dropped: malformed cmd")
		elseif not masters[msg.snd] then
			logger.trace("dropped: invalid cmd sender")
		else
			return true
		end
		return false
	end

	---@param msg msg
	function lib.handlers.cmd(msg)
		queue.push({
			reply_ch = msg.snd,
			id = msg.payload.id,
			body = msg.payload.body
		})
	end

	---@param payload msg_payload
	function lib.send_gps(payload)
		for m, _ in pairs(masters) do
			lib.send_msg(master_ch, m, "gps", payload)
		end
	end

	return lib
end

return {
	init = init
}
