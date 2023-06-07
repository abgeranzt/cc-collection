---@diagnostic disable-next-line: unknown-cast-variable
---@cast os os

local const = require("lib.const")
local util = require("lib.util")

local common = require("lib.setup.common")

local function init()
	---@class lib_setup_loader: lib_setup_common Loader setup
	local lib = common.init()

	function lib.setup()
		lib.print_motd()
		lib.print_intro("loader")

		local c_info = lib.prompt.computer_info("loader")

		os.setComputerLabel(c_info.label)
		lib.write_startup(const.PATH_LOADER, {
			"-mc", tostring(c_info.master_ch),
			"-mn", c_info.master_name,
			"-c", tostring(c_info.listen_ch)
		})

		if not util.has_item_equipped(const.ITEM_PICKAXE, "right", 16) then
			lib.equip_item(const.ITEM_PICKAXE, const.LABEL_PICKAXE, "right")
		end
		if not util.has_item_equipped(const.ITEM_CHUNK_CONTROLLER, "left", 16) then
			lib.equip_item(const.ITEM_CHUNK_CONTROLLER, const.LABEL_CHUNK_CONTROLLER, "left")
		end

		print("Setup complete")
	end

	return lib
end

return {
	init = init
}
