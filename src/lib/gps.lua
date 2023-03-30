
--- @param send_gps fun(payload: { id: number, body:  msg_body_gps})
--- @param logger logger
local function worker_setup(send_gps, logger)
	local id = 1
	-- broadcast my position on the configured gps channel
	local function monitor()
		while true do
			--- @diagnostic disable-next-line: undefined-field
			local _ = os.pullEvent("gps_update")
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
	worker_setup = worker_setup
}
