---@diagnostic disable-next-line: unknown-cast-variable
---@cast os os
---@diagnostic disable-next-line: unknown-cast-variable
---@cast turtle turtle

require("lib.ui").print_license()
sleep(1)
print(
	"This script will perform the setup for this worker. Enter the required information, follow the steps and you are good to go.\n"
)
sleep(1)

local function prompt_info()
	print("Worker name:")
	local label = io.read()
	print("Worker channel:")
	local worker_ch = io.read()
	print("Master name:")
	local master_name = io.read()
	print("Master channel:")
	local master_ch = io.read()

	return label, worker_ch, master_name, master_ch
end


local label, worker_ch, master_name, master_ch = prompt_info()

local function print_info()
	print("\nName: " .. label)
	print("Worker channel: " .. worker_ch)
	print("Master name: " .. master_name)
	print("Master channel: " .. master_ch .. "\n")
end

print_info()
while true do
	print("Is this correct? (y/n)")
	local s = io.read()
	if s == "y" or s == "Y" then
		break
	elseif s == "n" or s == "N" then
		label, worker_ch, master_name, master_ch = prompt_info()
		print_info()
	else
		print("Invalid input. Enter either 'y' or 'n'.")
	end
end

print("Saving configuration.")
os.setComputerLabel(label)


---@diagnostic disable-next-line: undefined-global
local f = fs.open("/startup.lua", "w")
---@cast f file_handle

f.writeLine("shell.run('/ccc/worker.lua',")
f.writeLine("\t'-mc', " .. master_ch .. ",")
f.writeLine("\t'-mn', '" .. master_name .. "',")
f.writeLine("\t'-wc', " .. worker_ch)
f.writeLine(")")
f.close()

print("Configuration saved")

---@param slot number
local function is_pickaxe(slot)
	return turtle.getItemCount(slot) > 0 and turtle.getItemDetail(slot).name == "minecraft:diamond_pickaxe"
end

local function has_pickaxe()
	local slot = turtle.getSelectedSlot()
	turtle.select(16)
	local hp = false
	turtle.equipRight()
	if is_pickaxe(16) then
		hp = true
	end
	turtle.equipRight()
	turtle.select(slot)
	return hp
end


local function is_modem(slot)
	return turtle.getItemCount(slot) > 0 and turtle.getItemDetail(slot).name == "computercraft:wireless_modem_advanced"
end

local function has_modem()
	local slot = turtle.getSelectedSlot()
	turtle.select(16)
	local hm = false
	turtle.select(16)
	turtle.equipLeft()
	if is_modem(16) then
		hm = true
	end
	turtle.equipLeft()
	turtle.select(slot)
	return hm
end

turtle.select(1)
if not has_pickaxe() then
	while true do
		print("Insert a diamond pickaxe into the first slot and press ENTER.")
		io.read()
		if is_pickaxe(1) then
			turtle.equipRight()
			break
		else
			print("No pickaxe provided.")
		end
	end
end

if not has_modem() then
	while true do
		print("Insert an ender modem into the first slot and press ENTER.")
		io.read()
		if is_modem(1) then
			turtle.equipLeft()
			break
		else
			print("No modem provided.")
		end
	end
end

print("Setup complete.")
