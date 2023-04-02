local exc = require("lib.excavate")
local go = require("lib.navigate").go
local util = require("lib.util")

---@param logger logger
local function miner_setup(logger)
	---@param params {x: number, y: number, z: number}
	local function excavate(params)
		-- validate params
		for _, c in ipairs({ "x", "y", "z" }) do
			if not params[c] then
				local e = "missing parameter '" .. c .. "'"
				---@cast e string
				return false, e
			elseif type(params[c]) ~= "number" then
				local e = "invalid parameter '" .. c .. "'"
				---@cast e string
				return false, e
			end
		end
		local ok, err = exc.dig_cuboid(params.x, params.y, params.z)
		if ok then
			return true
		else
			---@cast err string
			logger.error(err)
			return false, "excavate command failed"
		end
	end

	---@param params {x: number, y: number}
	local function excavate_bedrock(params)
		-- validate params
		for _, c in ipairs({ "x", "y" }) do
			if not params[c] then
				local e = "missing parameter '" .. c .. "'"
				---@cast e string
				return false, e
			elseif type(params[c]) ~= "number" then
				local e = "invalid parameter '" .. c .. "'"
				---@cast e string
				return false, e
			end
		end
		local ok, err = exc.dig_cuboid_bedrock(params.x, params.y)
		if ok then
			return true
		else
			---@cast err string
			logger.error(err)
			return false, "excavate_bedrock command failed"
		end
	end

	local directions = {
		forward = true,
		back = true,
		up = true,
		down = true,
		left = true,
		right = true
	}

	---@param params {direction: cmd_direction, distance: number}
	local function tunnel(params)
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

		local ok, err = exc.tunnel[params.direction](params.distance)
		if ok then
			return true
		else
			---@cast err string
			logger.error(err)
			return false, "tunnel command failed"
		end
	end

	---@param params {direction: cmd_direction, distance: number}
	local function navigate(params)
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
		while turtle.getFuelLevel() < params.distance do
			util.refuel()
		end

		local ok, err = go[params.direction](params.distance)
		if ok then
			return true
		else
			---@cast err string
			logger.error(err)
			return false, "navigate command failed"
		end
	end

	---@return true, nil, number
	local function get_fuel()
		return true, nil, turtle.getFuelLevel()
	end

	local function refuel()
		local ok, err = util.refuel()
		if ok then
			return true
		else
			---@cast err string
			logger.error(err)
			return false, "refuel command false"
		end
	end

	local function dump()
		local ok, err = util.dump()
		if ok then
			return true
		else
			---@cast err string
			logger.error(err)
			return false, "dump command false"
		end
	end

	return {
		excavate = excavate,
		excavate_bedrock = excavate_bedrock,
		tunnel = tunnel,
		navigate = navigate,
		get_fuel = get_fuel,
		refuel = refuel,
		dump = dump
	}
end

return {
	miner_setup = miner_setup
}
