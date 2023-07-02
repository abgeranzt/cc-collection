---@diagnostic disable-next-line: unknown-cast-variable
---@cast turtle turtle

local common = require("lib.command.common")
local exc = require("lib.excavate")


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

	return lib
end

return {
	init = init
}
