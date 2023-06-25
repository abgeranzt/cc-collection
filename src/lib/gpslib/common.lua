---@diagnostic disable-next-line: unknown-cast-variable
---@cast os os

---@param send_gps fun(payload: { id: number, body:  msg_body_gps})
---@param logger lib_logger
---@param dir gpslib_direction | nil
local function init(send_gps, logger, dir)
	-- TODO wrapper for turtle.turnX to track direction
	---@class lib_gpslib_common Common GPS functionality
	---@field position gpslib_position
	local lib = {
		position = {
		}
	}

	if dir then
		lib.position.dir = dir
	end

	local pos = table.pack(gps.locate())
	lib.position.x = pos[1]
	lib.position.y = pos[2]
	lib.position.z = pos[3]
	---@diagnostic disable-next-line: cast-local-type
	pos = nil

	local id = 1
	-- broadcast my position on the configured gps channel
	function lib.work_updates()
		while true do
			local _ = os.pullEvent("pos_update")
			logger.trace("getting own coordinates")
			local x, y, z = gps.locate()
			if x then
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
			else
				logger.trace("no gps data received")
			end
		end
	end

	return lib
end

return {
	init = init
}
