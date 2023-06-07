local util = require("lib.util")

---@diagnostic disable-next-line: unknown-cast-variable
---@cast fs fs
---@diagnostic disable-next-line: unknown-cast-variable
---@cast turtle turtle

local function init()
	---@class lib_setup_common Common computer setup functionality
	local lib = {}

	function lib.print_motd()
		print("This program is free software licensed under the GPLv3. See the source for copying conditions.")
		print("Author: Marcel Engelke")
		print("https://github.com/marcel-engelke/atref\n")
	end

	---@param c_type computer_type
	function lib.print_intro(c_type)
		print("This script will perform the setup for this " .. c_type .. ".\n" ..
			"Enter the required information, follow the steps and you are good to go.\n"
		)
	end

	lib.prompt = {}

	function lib.prompt.confirm_input()
		while true do
			print("Is this correct? (y/n)")
			local s = io.read()
			if s == "y" or s == "Y" then
				return true
			elseif s == "n" or s == "N" then
				return false
			else
				print("Invalid input. Enter either 'y' or 'n'.")
			end
		end
	end

	---@param prompt string
	---@param allowed {[string]: true} | nil
	---@return string
	function lib.prompt.value(prompt, allowed)
		while true do
			print(prompt)
			local val = io.read()
			if allowed and not allowed[val] then
				print("invalid input (value not allowed)")
			else
				return val
			end
		end
	end

	---@param prompt string
	---@param allowed {[string]: true} | nil
	---@return integer
	function lib.prompt.value_num(prompt, allowed)
		while true do
			local val = tonumber(lib.prompt.value(prompt, allowed))
			if not val then
				print("invalid input (expected number)")
			else
				return val
			end
		end
	end

	---@param c_type computer_type | nil
	function lib.prompt.computer_info(c_type)
		c_type = c_type or "computer"
		local label, listen_ch, master_name, master_ch
		while true do
			label = lib.prompt.value(c_type .. " name: ")
			listen_ch = lib.prompt.value_num("listen channel: ")
			master_name = lib.prompt.value("master name: ")
			master_ch = lib.prompt.value_num("master channel: ")
			print("\n" .. c_type .. " name: " .. label)
			print("listen channel: " .. listen_ch)
			print("master name: " .. master_name)
			print("master channel: " .. master_ch .. "\n")
			if lib.prompt.confirm_input() then
				break
			end
		end
		return {
			label = label,
			listen_ch = listen_ch,
			master_name = master_name,
			master_ch = master_ch
		}
	end

	---@param path string The file to execute at boot
	---@param args string[] Command line arguments provided to the file
	function lib.write_startup(path, args)
		local f = fs.open("/startup.lua", "w")
		f.write("shell.run('" .. path .. "'")
		for _, a in ipairs(args) do
			f.write(", '" .. a .. "'")
		end
		f.write(")")
		f.close()
	end

	---@param label string The item display name
	---@param name string The minecraft:item:identifier
	---@param side "left" | "right"
	---@param slot integer | nil
	function lib.equip_item(name, label, side, slot)
		slot = slot or 1
		local equip = side == "left" and turtle.equipLeft or turtle.equipRight
		while true do
			lib.prompt.value("Insert a " .. label .. " into slot " .. slot .. " and press enter.")
			if util.is_item(name, slot) then
				equip()
				break
			end
			print("No " .. label .. " in slot " .. slot .. " detected. Please try again.")
		end
	end

	return lib
end

return {
	init = init
}
