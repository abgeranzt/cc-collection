---@diagnostic disable-next-line: unknown-cast-variable
---@cast turtle turtle

local common = require("lib.command.common")
local exc = require("lib.excavate")
local go = require("lib.navigate").go
local util = require("lib.util")

local directions = common.directions

---@param config lib_config
---@param logger lib_logger
---@param pos gpslib_position
local function init(config, logger, pos)
	---@class lib_command_miner: lib_command_common Commands for mining turtles
	local lib = common.init(config, logger, pos)

	---@param params {l: number, w: number, h: number}
	function lib.excavate(params)
		-- validate params
		for _, c in ipairs({ "l", "w", "h" }) do
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
		local ok, err = exc.dig_cuboid(params.l, params.w, params.h, config.fuel_type)
		if ok then
			return true
		else
			---@cast err string
			logger.error(err)
			return false, "excavate command failed"
		end
	end

	---@param params {l: number, w: number}
	function lib.excavate_bedrock(params)
		-- validate params
		for _, c in ipairs({ "l", "w" }) do
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
		local ok, err = exc.dig_cuboid_bedrock(params.l, params.w, config.fuel_type)
		if ok then
			return true
		else
			---@cast err string
			logger.error(err)
			return false, "excavate_bedrock command failed"
		end
	end

	---@param params {direction: cmd_direction, distance: number}
	function lib.tunnel(params)
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

	---@param params {pos: gpslib_position}
	function lib.tunnel_pos(params)
		local ok, err = lib.validators.gpslib_position(params.pos)
		if not ok then
			---@cast err string
			logger.error(err)
			return false, "tunnel_pos command failed"
		end
		ok, err = go.coords(lib.current_pos, params.pos, exc.tunnel)
		if not ok then
			---@cast err string
			logger.error(err)
			return false, "tunnel_pos command failed"
		end
		return true, nil
	end

	function lib.dump()
		local ok, err = util.dump()
		if ok then
			return true
		else
			---@cast err string
			logger.error(err)
			return false, "dump command failed"
		end
	end

	---@param params { target: number }
	function lib.refuel(params)
		if turtle.getFuelLevel() < params.target then
			local ok, err = util.refuel(params.target, config.fuel_type)
			if not ok then
				---@cast err string
				logger.error(err)
				return false, "refuel command failed"
			end
		end
		return true
	end

	return lib
end

return {
	init = init
}
