COMMANDS = {
	kill = function(args) os.shutdown() end,
	run = function(args) return os.run({}, unpack(args)) end,
	qfuel = function(args) return turtle.getFuelLevel() end
}

function parse_msg(msg)
	-- syntax: cmd-arg1,argN
	-- syntax for run: run-FULLPATH,arg1,argN
	local f = string.gmatch(msg, "[^:]+")
	local cmd = f()
	local as = f()
	local args = {}
	if as then for v in string.gmatch(as, "[^,]+") do table.insert(args, v) end end
	return cmd, args
end

function exec_cmd(cmd, args)
	if not COMMANDS[cmd] then return "Invalid command '" .. cmd .. "'" end
	return COMMANDS[cmd](args)
end

function listen(modem, ch)
	modem.open(ch)
	local _e, _s, _c, rep_ch, msg, _d
	local cmd, args
	while true do
		_e, _s, _c, rep_ch, msg, _d = os.pullEvent("modem_message")
		cmd, args = parse_msg(msg)
		reply = exec_cmd(cmd, args)
		modem.transmit(rep_ch, 0, reply)
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
