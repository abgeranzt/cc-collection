--- @param gps_ch number
--- @param worker_ch number
--- @param modem {transmit: fun(c: number, rc: number, s: string)}
local function worker_setup(gps_ch, worker_ch, modem)
	-- broadcast my position on the configured gps channel
	---@diagnostic disable-next-line: undefined-field
	local _worker_name = os.getComputerLabel()
	local function monitor()
		while true do
			--- @diagnostic disable-next-line: undefined-field
			_ = os.pullEvent("gps_update")
			local x, z, y = gps.locate()

			local msg = "[" .. _worker_name .. "] x" .. x .. " z" .. z .. " y" .. y
			modem.transmit(gps_ch, worker_ch, msg)
		end
	end
	return { monitor = monitor }
end

return {
	worker_setup = worker_setup
}
