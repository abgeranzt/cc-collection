---@diagnostic disable-next-line: unknown-cast-variable
---@cast colors colors
---@diagnostic disable-next-line: unknown-cast-variable
---@cast os os
---@diagnostic disable-next-line: unknown-cast-variable
---@cast peripheral peripheral

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
monitor.setTextScale(0.5)
local x_size, y_size = monitor.getSize()
---@cast x_size number
---@cast y_size number

---@diagnostic disable-next-line: undefined-global
local log_file = fs.open("/server.log", "w")
---@cast log_file file_handle

-- TODO unused, get rid of it?
local level_colors = {
	fatal = colors.red,
	error = colors.red,
	warn = colors.orange,
	info = colors.white,
	debug = colors.lime,
	trace = colors.blue
}

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

-- TOOD own logger
local function log_server()
	while true do
		local _, event = os.pullEvent("log_message")
		---@cast event log_event
		log_file.writeLine(event.raw)
		print_msg(event)
	end
end

local message = require("lib.message").log_server_setup(9000, modem, "trace")

---@diagnostic disable-next-line: undefined-global
parallel.waitForAll(message.listen, log_server)
