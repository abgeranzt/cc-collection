---@diagnostic disable-next-line: unknown-cast-variable
---@cast fs fs

---@diagnostic disable-next-line: unknown-cast-variable
---@cast http http

-- TODO optionally just install from file, useful for situations in which CC cannot connect to the internet

local packed_url = "https://github.com/marcel-engelke/atref/releases/download/master/packed"
local packed = "/packed"
local delim = "--------------------------------------------------"

fs.delete("/install.log")
---@param msg string
local function log(msg)
	print(msg)
	local log_file = fs.open("/install.log", "a")
	log_file.writeLine(msg)
	log_file.close()
end

---@param dest string
local function fetch(dest)
	log("fetching packed code from github")
	local res = http.get(packed_url)
	local code, _ = res.getResponseCode()
	if code ~= 200 then
		log("error: http status " .. code)
		---@diagnostic disable-next-line: undefined-global
		exit()
	end
	log("saving to '" .. dest .. "'")
	local file = fs.open(dest, "w")
	while true do
		local line = res.readLine()
		if not line then
			file.close()
			return
		end
		file.writeLine(line)
	end
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
			if line == delim then
				log("delim: " .. line)
				file.close()
				break
			end
			file.writeLine(line)
		end
	end
end

log("this script will download and install atref to /atref")
fetch(packed)
unpack(packed)
fs.delete(packed)
