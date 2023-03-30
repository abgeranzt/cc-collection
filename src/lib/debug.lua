local function print_table(t, indent)
	indent = indent or ""
	for k, v in pairs(t) do
		if type(v) == "table" then
			print(indent .. "'" .. k .. "':")
			print_table(v, (indent .. "  "))
		else
			print(indent .. "'" .. k .. "': '" .. v .. "'")
		end
	end
end

return {
	print_table = print_table
}
