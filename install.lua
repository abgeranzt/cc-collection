---@diagnostic disable-next-line: unknown-cast-variable
---@cast fs fs
-- TODO fetch packed file from release page
local packed = "/packed"
local DELIM = "--------------------------------------------------"

fs.delete("/install.log")
---@param msg string
local function log(msg)
	print(msg)
	local log_file = fs.open("/install.log", "a")
	log_file.writeLine(msg)
	log_file.close()
end

---@param packed_path string
local function unpack(packed_path)
	local packed_file = fs.open(packed_path, 'r')
	packed_file.readLine()
	packed_file.readLine()

	while true do
		local path = packed_file.readLine()
		---@cast path string
		log("creating directory '" .. path .. "'")
		fs.makeDir(path)
		local file_name = packed_file.readLine()
		---@cast file_name string
		file_name = path .. "/" .. file_name
		log("installing file '" .. file_name .. "'")
		local file = fs.open(file_name, 'w')
		packed_file.readLine()

		while true do
			local line = packed_file.readLine()
			if not line then
				file.close()
				return
			end
			if line == DELIM then
				log("delim: " .. line)
				file.close()
				break
			end
			file.writeLine(line)
		end
	end
end

unpack(packed)
