local message_types = {
	res = true,
	cmd = true
}

--- @param ch number
--- @param master_name string
--- @param master_ch number
--- @param queue {push: fun(task: table)}
--- @param modem {open: fun(channel: number)}
local function worker_setup(ch, master_name, master_ch, queue, modem)
	local message = {
	}

	--- @param msg {rec: string, snd: string, type: string, payload: {id: number, body: {cmd: string, params: table | nil} | nil}}
	function message.validate(msg)
		-- Drop the message if it is malformed or not intended for us.
		if type(msg) ~= "table"
			or not msg.rec
			--- @diagnostic disable-next-line: undefined-field
			or msg.rec ~= os.computerLabel()
			or not msg.snd
			or msg.snd ~= master_name
			or not message_types[msg.type]
			or not msg.payload
			or type(msg.payload) ~= "table"
		then
			return false
		end
		-- Validate command
		if msg.payload.body then
			if type(msg.payload.body) ~= "table"
				or not msg.payload.body.cmd
				or type(msg.payload.body.cmd) ~= "string"
			then
				return false
			end
		end
		return true
	end

	--- @param msg {rec: string, snd: string, type: string, payload: {id: number, body: {cmd: string, params: table | nil} | nil}}
	function message.print(msg)
		print("info: [msg] " .. msg.type .. " " .. msg.payload.id)
	end

	--- @param msg {rec: string, snd: string, type: string, payload: {id: number, body: {cmd: string, params: table | nil}}}
	function message.create_task(msg)
		local task = {
			reply_ch = master_ch,
			id = msg.payload.id,
			body = msg.payload.body,
		}
		queue.push(task)
	end

	function message.listen()
		modem.open(ch)
		while true do
			--- @diagnostic disable-next-line: undefined-field
			local _e, _s, _c, _rc, msg, _d = os.pullEvent("modem_message")
			if message.validate(msg) then
				message.print(msg)
				if msg.type == "cmd" then
					message.create_task(msg)
				end
			end
		end
	end

	return message
end

return { worker_setup = worker_setup }
