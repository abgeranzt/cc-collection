---@diagnostic disable-next-line: unknown-cast-variable
---@cast colors colors
---@diagnostic disable-next-line: unknown-cast-variable
---@cast os os
---@diagnostic disable-next-line: unknown-cast-variable
---@cast peripheral peripheral

---@param args table The arguments provided to the program
local function setup(args)
	local modem = peripheral.find("modem")
	if not modem then
		print("No modem found, exiting!")
		---@diagnostic disable-next-line: undefined-global
		exit()
	end
	---@cast modem modem
	local monitor = peripheral.find("monitor")
	if not monitor then
		print("No monitor found, exiting!")
		---@diagnostic disable-next-line: undefined-global
		exit()
	end
	---@cast monitor monitor

	---@diagnostic disable-next-line: undefined-global
	local log_file = fs.open("/server.log", "w")
	---@cast log_file fs_filehandle

	local argparse = require("lib.argparse")
	argparse.add_arg("channel", "-c", "number", false, 9000)
	argparse.add_arg("level", "-l", "string", false, "info")
	argparse.add_arg("filter", "-f", "array", false)
	local parsed_args, e = argparse.parse(args)
	if not parsed_args then
		print(e)
		---@diagnostic disable-next-line: undefined-global
		exit()
	end
	---@cast parsed_args table

	local channel = parsed_args.channel
	---@cast channel integer
	local level = parsed_args.level
	---@cast level log_level
	local filter = parsed_args.filter
	---@cast filter string[]

	local message = require("lib.message").log_server_setup(channel, modem, level)

	return filter, log_file, message, monitor
end

local filter, log_file, message, monitor = setup({ ... })

monitor.clear()

monitor.setTextScale(0.5)
local x_size, y_size = monitor.getSize()
---@cast x_size number
---@cast y_size number


local level_colors_blit = {
	fatal = "e",
	error = "e",
	warn = "1",
	info = "0",
	debug = "5",
	trace = "b"
}

---@param snd string
---@param lvl string
---@param msg string
local function create_blit(snd, lvl, msg)
	snd = "[" .. snd .. "] - "
	local snd_color = string.rep("0", string.len(snd))

	local lc = tostring(level_colors_blit[lvl])
	local pad = string.len(lvl) == 4 and ":  " or ": "
	lvl = string.upper(lvl) .. pad
	local lvl_color = string.rep(lc, string.len(lvl) - 2) .. "00"

	local msg_color = string.rep("0", string.len(msg))

	local text = snd .. lvl .. msg
	local text_color = snd_color .. lvl_color .. msg_color
	local bg_color = string.rep("f", string.len(text))
	return text, text_color, bg_color
end

---@param event log_event
local function print_msg(event)
	local _x, y_pos = monitor.getCursorPos()
	if y_pos == y_size then
		monitor.scroll(1)
	end
	monitor.setCursorPos(1, y_pos)
	monitor.blit(create_blit(event.snd, event.lvl, event.msg))
	if y_pos < y_size then
		monitor.setCursorPos(1, y_pos + 1)
	end
end

-- TODO escape special characters in filter string
-- https://www.lua.org/pil/20.2.html
---@param event log_event
local function filter_msg(event)
	for _, f in ipairs(filter) do
		if string.find(event.raw, f) then
			return true
		end
	end
	return false
end

-- TODO own logger
local function log_server()
	if filter then
		while true do
			local _, event = os.pullEvent("log_message")
			---@cast event log_event
			if filter_msg(event) then
				log_file.writeLine(event.raw)
				print_msg(event)
			end
		end
	else
		while true do
			local _, event = os.pullEvent("log_message")
			---@cast event log_event
			log_file.writeLine(event.raw)
			print_msg(event)
		end
	end
end


---@diagnostic disable-next-line: undefined-global
parallel.waitForAll(message.listen, log_server)
