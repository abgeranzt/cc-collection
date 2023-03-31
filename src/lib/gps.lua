--- @param workers {[string]: {position: gps_position}}
local function master_setup(workers, logger)
	local function monitor()
		while true do
			--- @diagnostic disable-next-line: undefined-field
			local _, msg = os.pullEvent("gps_update")
			--- @cast msg msg
			local pos = msg.payload.body
			--- @diagnostic disable-next-line: cast-type-mismatch
			--- @cast pos gps_position
			logger.debug("updating position for worker '" .. msg.snd .. "'")
			workers[msg.snd].position = pos
		end
	end
	return {
		monitor = monitor
	}
end

--- @param send_gps fun(payload: { id: number, body:  msg_body_gps})
--- @param logger logger
local function worker_setup(send_gps, logger)
	local id = 1
	-- broadcast my position on the configured gps channel
	local function monitor()
		while true do
			--- @diagnostic disable-next-line: undefined-field
			local _ = os.pullEvent("gps_update")
			--- @diagnostic disable-next-line: undefined-global
			local x, z, y = gps.locate()
			local payload = {
				id = id,
				body = {
					x = x,
					y = y,
					z = z
				}
			}
			logger.trace("sending gps update")
			send_gps(payload)
			id = id + 1
		end
	end
	return {
		monitor = monitor
	}
end


return {
	master_setup = master_setup,
	worker_setup = worker_setup
}
