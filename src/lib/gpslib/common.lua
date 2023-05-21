---@diagnostic disable-next-line: unknown-cast-variable
---@cast os os

---@param send_gps fun(payload: { id: number, body:  msg_body_gps})
---@param logger logger
local function setup(send_gps, logger)
	local lib = {}

	local id = 1
	-- broadcast my position on the configured gps channel
	function lib.work_updates()
		while true do
			local _ = os.pullEvent("pos_update")
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

	return lib
end

return {
	setup = setup
}
