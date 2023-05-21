---@diagnostic disable-next-line: unknown-cast-variable
---@cast os os

local common = require("lib.gpslib.common")

---@param worker {get: fun(label: string)}
---@param logger logger
local function setup(worker, logger)
	-- TODO implement gps tracking for the master
	local lib = common.setup(function(_)
	end, logger)

	function lib.monitor()
		while true do
			local _, msg = os.pullEvent("gps_update")
			---@cast msg msg
			local pos = msg.payload.body
			---@cast pos gps_position
			-- TODO re-enable it when development is finished
			-- logger.trace("updating position for worker '" .. msg.snd .. "'")
			worker.get(msg.snd).position = pos
		end
	end

	return lib
end

return {
	setup = setup
}
