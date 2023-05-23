local const = require("lib.const")
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
---@param current_pos gpslib_position
local function setup(logger, current_pos)
	local lib = {}

	lib.validators = {}
	---@param pos gpslib_position
	function lib.validators.gpslib_position(pos)
		if not pos then
			return false, "missing parameter 'pos'"
		end
		for _, v in pairs({ "x", "y", "z" }) do
			if not pos[v] then
				return false, "missing parameter 'pos." .. v .. "'"
			elseif type(pos[v]) ~= "number" then
				return false, "invalid parameter 'pos." .. v .. "'"
			end
			if not pos.dir then
				return false, "missing parameter 'pos.dir'"
			elseif not const.DIRECTIONS[pos.dir] then
				return false, "invalid parameter 'pos.dir'"
			end
		end
		return true, nil
	end

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

	---@param params {pos: gpslib_position}
	function lib.navigate_pos(params)
		local ok, err = lib.validators.gpslib_position(params.pos)
		if not ok then
			---@cast err string
			logger.error(err)
			return false, "navigate_pos command failed"
		end
		ok, err = go.coords(current_pos, params.pos)
		if not ok then
			---@cast err string
			logger.error(err)
			return false, "navigate_pos command failed"
		end
		return true, nil
	end

	---@return true, nil, number
	function lib.get_fuel()
		---@diagnostic disable-next-line: missing-return-value
		return true, nil, turtle.getFuelLevel()
	end

	---@param params { pos: gpslib_position }
	function lib.set_position(params)
		local ok, err = lib.validators.gpslib_position(params.pos)
		if not ok then
			---@cast err string
			logger.error(err)
			return false, "set_position command failed"
		end
		for k, v in pairs(params.pos) do
			current_pos[k] = v
		end
		return true, nil
	end

	return lib
end

return {
	directions = directions,
	setup = setup
}
