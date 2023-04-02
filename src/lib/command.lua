local exc = require("lib.excavate")
local go = require("lib.navigate").go
local refuel = require("lib.util").refuel

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
			refuel()
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

	return {
		excavate = excavate,
		tunnel = tunnel,
		navigate = navigate
	}
end

return {
	miner_setup = miner_setup
}
