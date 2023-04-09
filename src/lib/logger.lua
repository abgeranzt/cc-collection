local log_levels = { "fatal", "error", "warn", "info", "debug", "trace" }

---@param log_ch number
---@param log_level "fatal" | "error" | "warn" | "info" | "debug" | "trace"
---@param log_file string | nil
---@param modem {transmit: fun(c: number, rc: number, s: string)} | nil
local function logger_setup(log_ch, log_level, log_file, modem)
	local logger = {}

	---@diagnostic disable-next-line: undefined-field
	local _label = os.getComputerLabel()

	local function write_log(_) end
	if log_file then
		---@diagnostic disable-next-line: undefined-global
		local _file = fs.open(log_file, "w")
		---@param msg string
		write_log = function(msg)
			_file.writeLine(msg)
		end
	end

	local function send_log(_) end
	if modem then
		send_log = function(msg)
			local log_msg = "[" .. _label .. "] - " .. msg
			modem.transmit(log_ch, 0, log_msg)
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
				write_log(log_msg)
				send_log(log_msg)
			end
		end
		if l == log_level then
			skip = true
		end
	end


	return logger
end

return { setup = logger_setup }
