---@param t1 table
---@param t2 table
local function table_compare(t1, t2)
	for k, _ in pairs(t1) do
		if t1[k] ~= t2[k] then
			return false
		end
	end
	for k, _ in pairs(t2) do
		if not t1[k] then
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
		if not t1[k] then
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
	table_compare = table_compare,
	table_compare_recursive = table_compare_recursive,
	table_copy = table_copy,
	table_copy_recursive = table_copy_recursive,
	compare = compare
}
