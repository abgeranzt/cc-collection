-- TODO proper way to express/configure commands
function parse_msg(msg)
	-- TODO perf: make this global?
	local f = string.gmatch(msg, "[^-]+")
	local cmd = f()
	local arg_string = f()
	local args = {}
	for v in string.gmatch(arg_string, "[^,]+") do table.insert(args, v) end
	return cmd, args
end

function exec_cmd(cmd, args)
	if cmd == "run" then
		os.run({}, unpack(args))
	else
		if cmd == "kill" then os.shutdown() end
	end
end

function listen(modem, ch)
	modem.open(ch)
	local _e, _s, _c, rep_ch, msg, _d
	local cmd, args
	while true do
		_e, _s, _c, rep_ch, msg, _d = os.pullEvent("modem_message")
		cmd, args = parse_msg(msg)
		exec_cmd(cmd, args)
	end
end

function main(ch)
	local modem = peripheral.find("modem")
	if not (modem) then
		print("No wireless modem detected. Quitting!")
		return
	end
	listen(modem, ch)
end

local ch = ...
ch = tonumber(ch)
main(ch)
