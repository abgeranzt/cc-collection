---@diagnostic disable-next-line: unknown-cast-variable
---@cast os os

local common = require("lib.gpslib.common")

---@param worker {get: fun(label: string)}
---@param logger logger
---@param dir gpslib_direction | nil
local function init(worker, logger, dir)
	-- TODO implement gps tracking for the master
	---@class lib_gpslib_master: lib_gpslib_common GPS operations for master computers
	local lib = common.init(function(_)
	end, logger, dir)

	function lib.monitor()
		while true do
			local _, msg = os.pullEvent("gps_update")
			---@cast msg msg
			local pos = msg.payload.body
			---@cast pos gpslib_position
			logger.trace("updating position for  '" .. msg.snd .. "'")
			worker.get(msg.snd).position = pos
		end
	end

	return lib
end

return {
	init = init
}
