local get_label = require("lib.util").get_label

local log_levels = { "fatal", "error", "warn", "info", "debug", "trace" }

---@param log_ch number
---@param modem {transmit: fun(c: number, rc: number, s: string) | nil}
---@param log_level "fatal" | "error" | "warn" | "info" | "debug" | "trace"
local function logger_setup(log_ch, log_level, log_file, modem)
	local logger = {
		_label = get_label(),
		---@diagnostic disable-next-line: undefined-global
		_file = fs.open(log_file, "w")
		---@diagnostic disable-next-line: unknown-cast-variable
		---@cast _file file_handle
	}

	if modem then
		function logger._sendlog(msg)
			local log_msg = "[" .. logger._label .. "] - " .. msg
			modem.transmit(log_ch, 0, log_msg)
		end
	else
		function logger._sendlog(_)
		end
	end

	local skip = false
	for _, l in ipairs(log_levels) do
		if skip then
			---@diagnostic disable-next-line: assign-type-mismatch
			logger[l] = function(_)
			end
		else
			---@param msg string
			---@diagnostic disable-next-line: assign-type-mismatch
			logger[l] = function(msg)
				local log_msg = string.upper(l) .. ": " .. (msg or "")
				print(log_msg)
				logger._file.writeLine(log_msg)
				logger._sendlog(log_msg)
			end
		end
		if l == log_level then
			skip = true
		end
	end


	return logger
end

return { setup = logger_setup }
