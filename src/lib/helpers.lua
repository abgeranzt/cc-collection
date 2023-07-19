-- Split a string at every occurance of the delimiter provided.
-- Leading and trailng patterns are treated as if they were surrounded by an empty string.
-- See Lua stdlib string.find() for pattern documentation
---@param s string The string to split`
---@param pattern string The pattern use as a delimter
---@return string[]
local function string_split(s, pattern)
	local split = {}
	local i, j
	while true do
		i, j = string.find(s, pattern)
		if not i then
			break
		end
		table.insert(split, string.sub(s, 0, i - 1))
		s = string.sub(s, j + 1)
		if j == string.len(s) then
			break
		end
	end
	table.insert(split, s)
	return split
end

---@param t table
local function table_to_str(t)
	local s = "{"
	for k, v in pairs(t) do
		if type(v) == "table" then
			s = s .. table_to_str(v)
		else
			if type(v) == "boolean" then
				v = v and "true" or "false"
			end
			s = s .. k .. " = " .. v .. ", "
		end
	end
	return s .. "}"
end

---@param t1 table
---@param t2 table
local function table_compare(t1, t2)
	for k, _ in pairs(t1) do
		if t1[k] ~= t2[k] then
			return false
		end
	end
	for k, _ in pairs(t2) do
		if type(t1[k]) == "nil" then
			return false
		end
	end
	return true
end

---@param t1 table
---@param t2 table
local function table_compare_recursive(t1, t2)
	for k, _ in pairs(t1) do
		if type(t1[k]) ~= type(t2[k]) then
			return false
		elseif type(t1[k]) == "table" then
			if not table_compare_recursive(t1[k], t2[k]) then
				return false
			end
		else
			if t1[k] ~= t2[k] then
				return false
			end
		end
	end
	for k, _ in pairs(t2) do
		if type(t1[k]) == "nil" then
			return false
		end
	end
	return true
end

---@generic T: table
---@param t T
---@return T
local function table_copy(t)
	local new_t = {}
	for k, v in pairs(t) do
		new_t[k] = v
	end
	return new_t
end

---@generic T: table
---@param t T
---@return T
local function table_copy_recursive(t)
	local new_t = {}
	for k, v in pairs(t) do
		if type(v) == "table" then
			new_t[k] = table_copy_recursive(v)
		else
			new_t[k] = v
		end
	end
	return new_t
end

-- (Recursively) compare both values
---@param v1 any
---@param v2 any
local function compare(v1, v2)
	if type(v1) ~= type(v2) then
		return false
	else
		if type(v1) == "table" then
			return table_compare_recursive(v1, v2)
		end
		return v1 == v2
	end
end

return {
	string_split = string_split,
	table_to_str = table_to_str,
	table_compare = table_compare,
	table_compare_recursive = table_compare_recursive,
	table_copy = table_copy,
	table_copy_recursive = table_copy_recursive,
	compare = compare
}
