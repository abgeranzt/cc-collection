---@param config lib_config
local function init(config)
	---@class lib_config
	---@field fuel_type util_fuel_type
	---@field listen_ch integer
	---@field log_ch integer
	---@field log_lvl log_level
	---@field master_ch integer
	---@field master_name string
	---@field slot_dump integer
	---@field slot_first_free integer
	---@field slot_fuel integer
	local lib = {}

	lib.fuel_type = config.fuel_type
	lib.listen_ch = config.listen_ch
	lib.log_ch = config.log_ch
	lib.log_lvl = config.log_lvl
	lib.master_ch = config.master_ch
	lib.master_name = config.master_name
	lib.slot_dump = config.slot_dump
	lib.slot_first_free = config.slot_first_free
	lib.slot_fuel = config.slot_fuel

	return lib
end

return {
	init = init
}
