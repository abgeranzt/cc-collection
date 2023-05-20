local go = require("lib.navigate").go
local util = require("lib.util")

local directions = {
	forward = true,
	back = true,
	up = true,
	down = true,
	left = true,
	right = true
}

---@param logger logger
local function setup(logger)
	local lib = {}

	---@param params {direction: cmd_direction, distance: number}
	function lib.navigate(params)
		-- validate params
		if not params.direction then
			local e = "missing parameter direction"
			---@cast e string
			return false, e
		end
		if not directions[params.direction]
			or type(params.direction) ~= "string"
		then
			local e = "invalid parameter direction '" .. params.direction .. "'"
			---@cast e string
			return false, e
		end
		if not params.distance then
			local e = "missing parameter distance"
			---@cast e string
			return false, e
		end
		if type(params.distance) ~= "number" then
			local e = "invalid parameter distance '" .. params.distance .. "'"
			---@cast e string
			return false, e
		end
		-- TODO have the master control the refuelling?
		local ok, err
		if turtle.getFuelLevel() < params.distance then
			ok, err = util.refuel(params.distance)
			if not ok then
				return false, err
			end
		end

		ok, err = go[params.direction](params.distance)
		if ok then
			return true
		else
			---@cast err string
			logger.error(err)
			return false, "navigate command failed"
		end
	end

	---@return true, nil, number
	function lib.get_fuel()
		---@diagnostic disable-next-line: missing-return-value
		return true, nil, turtle.getFuelLevel()
	end

	return lib
end

return {
	directions = directions,
	setup = setup
}
