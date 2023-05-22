---@diagnostic disable-next-line: unknown-cast-variable
---@cast os os

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

return {
	log_server_setup = log_server_setup,
}
