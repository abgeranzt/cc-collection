local log_levels = { "fatal", "error", "warn", "info", "debug", "trace" }

--- @param log_ch number
--- @param modem {transmit: fun(c: number, cp: number, s: string) | nil}
--- @param log_level "fatal" | "error" | "warn" | "info" | "debug" | "trace"
local function logger_setup(log_ch, log_level, log_file, modem)
	local logger = {
		--- @alias file_handle {close: fun(), flush: fun(), write: fun(s: string), writeLine: fun(s: string) }
		_file = fs.open(log_file, "w")
		--- @diagnostic disable-next-line: unknown-cast-variable
		--- @cast _file file_handle
	}

	if modem then
		function logger._sendlog(msg)
			---@diagnostic disable-next-line: undefined-field
			local log_msg = "[" .. os.getComputerLabel() .. "] - " .. msg
			modem.transmit(log_ch, 0, log_msg)
		end
	end

	local skip = false
	for _, l in ipairs(log_levels) do
		if skip then
			logger[l] = function(_)
			end
		elseif modem then
			--- @param msg string
			logger[l] = function(msg)
				local log_msg = string.upper(l) .. ": " .. msg
				print(log_msg)
				logger._file.writeLine(log_msg)
				logger._sendlog(log_msg)
			end
		else
			--- @param msg string
			logger[l] = function(msg)
				local log_msg = string.upper(l) .. ": " .. msg
				print(log_msg)
				logger._file.writeLine(log_msg)
			end
		end
		if l == log_level then
			skip = true
		end
	end


	return logger
end

--- @alias logger {fatal: fun(s: string), error: fun(s: string), warn: fun(s: string), info: fun(s: string), debug: fun(s: string), trace: fun(s: string)}

return { setup = logger_setup }
