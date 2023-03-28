--- @param send_gps fun(payload: { id: number, body:  { x: number, z: number, y: number }})
local function worker_setup(send_gps)
	local id = 1
	-- broadcast my position on the configured gps channel
	local function monitor()
		while true do
			--- @diagnostic disable-next-line: undefined-field
			_ = os.pullEvent("gps_update")
			local x, z, y = gps.locate()
			local payload = {
				id = id,
				body = {
					x = x,
					z = z,
					y = y
				}
			}
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
