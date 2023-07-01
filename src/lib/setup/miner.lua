---@diagnostic disable-next-line: unknown-cast-variable
---@cast os os

local const = require("lib.const")
local util = require("lib.util")

local common = require("lib.setup.common")

local function init()
	---@class lib_setup_miner: lib_setup_common Miner setup
	local lib = common.init()

	function lib.setup()
		lib.print_motd()
		lib.print_intro("miner")

		local c_info = lib.prompt.computer_info("miner")

		os.setComputerLabel(c_info.label)
		lib.write_startup(const.PATH_MINER, {
			"-mc", tostring(c_info.master_ch),
			"-mn", c_info.master_name,
			"-c", tostring(c_info.listen_ch)
		})

		if not util.has_item_equipped(const.ITEM_PICKAXE, "right", 16) then
			lib.equip_item(const.ITEM_PICKAXE, const.LABEL_PICKAXE, "right")
		end
		if not util.has_item_equipped(const.ITEM_MODEM, "left", 16) then
			lib.equip_item(const.ITEM_MODEM, const.LABEL_MODEM, "left")
		end

		print("Setup complete")
	end

	return lib
end

return {
	init = init
}
