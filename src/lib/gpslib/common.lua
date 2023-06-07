---@diagnostic disable-next-line: unknown-cast-variable
---@cast os os

---@param send_gps fun(payload: { id: number, body:  msg_body_gps})
---@param logger logger
local function init(send_gps, logger)
	-- TODO wrapper for turtle.turnX to track direction
	---@class lib_gpslib_common Common GPS functionality
	local lib = {}

	local pos = {}
	lib.position = pos

	local id = 1
	-- broadcast my position on the configured gps channel
	function lib.work_updates()
		while true do
			local _ = os.pullEvent("pos_update")
			logger.trace("getting own coordinates")
			local x, y, z = gps.locate()
			lib.position.x = x
			lib.position.y = y
			lib.position.z = z
			local payload = {
				id = id,
				body = {
					x = x,
					y = y,
					z = z,
					dir = lib.position.dir
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
	init = init
}
