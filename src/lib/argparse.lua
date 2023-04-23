local conf_args = {}
---@cast conf_args argparse_arg[]

---@param name string
---@param short string The argument in usage (e.g. -a)
---@param arg_type argparse_arg_type
---@param required boolean | nil
---@param default argparse_arg_default
local function add_arg(name, short, arg_type, required, default)
	if arg_type == "boolean" and required then
		return false, "boolean argument '" .. name "' cannot be required"
	elseif required and default then
		return false, "required argument '" .. name "' cannot have a default"
	end
	conf_args[name] = {
		short = short,
		type = arg_type,
		required = required or false,
		default = default
	}
	return true, nil
end

---@param prov_args table The arguments provided to the program
local function parse(prov_args)
	if not prov_args then
		return false, "no arguments provided"
	end
	local args = {}
	for name, arg in pairs(conf_args) do
		local a_pos = nil
		local v_pos = nil
		for p, a in ipairs(prov_args) do
			if a == arg.short then
				a_pos = p
				-- Assume that argument values never start with minus sign "-"
				-- TODO This will lead to problems if using negative values is required at some point. Improve this!
				-- Using a plus sign "+" may be better.
				if type(prov_args[p + 1]) == "string" and prov_args[p + 1][1] ~= "-" then
					v_pos = p + 1
				end
			end
		end
		if arg.required and not a_pos then
			return false, "argument '" .. name .. "' is missing"
		elseif arg.required and not v_pos then
			return false, "missing value for argument '" .. name .. "'"
		elseif arg.type == "boolean" then
			args[name] = a_pos and true or false
		elseif arg.type == "number" then
			if not v_pos then
				args[name] = arg.default
			elseif type(tonumber(prov_args[v_pos])) ~= "number" then
				return false, "invalid value for numeric argument '" .. name .. "'"
			else
				args[name] = tonumber(prov_args[v_pos])
			end
		elseif arg.type == "array" then
			if not v_pos then
				args[name] = arg.default
			end
			args[name] = {}
			for e in string.gmatch(prov_args[v_pos], "[^,]+") do
				table.insert(args[name], e)
			end
		else
			args[name] = v_pos and prov_args[v_pos] or arg.default
		end
	end
	return args, nil
end

return {
	add_arg = add_arg,
	parse = parse
}
