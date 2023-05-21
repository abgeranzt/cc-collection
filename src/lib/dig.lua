local dig = {}

function dig.forward()
	local ok = true
	local err
	while turtle.detect() do
		ok, err = turtle.dig()
		if not ok then break end
	end
	return ok, err
end

function dig.up()
	local ok = true
	local err
	while turtle.detectUp() do
		ok, err = turtle.digUp()
		if not ok then break end
	end
	return ok, err
end

-- TODO configrable blacklist of blocks?
-- Prevent the mining of computers or turtles
---@param retries integer | nil
function dig.forward_safe(retries)
	retries = retries or 5
	while turtle.detect() do
		local ok, err
		for _ = 1, retries do
			local _, b = turtle.inspect()
			---@cast b {name: string}
			if string.find(b.name, "computercraft:turtle")
				or string.find(b.name, "computercraft:computer")
			then
				sleep(1)
			else
				ok, err = turtle.dig()
				break
			end
		end
		if not ok then
			return false, (err and err or "failed to safely break block")
		end
	end
	return true
end

---@param retries integer | nil
function dig.up_safe(retries)
	retries = retries or 5
	while turtle.detectUp() do
		local ok, err
		for _ = 1, retries - 1 do
			local _, b = turtle.inspectUp()
			---@cast b {name: string}
			if string.find(b.name, "computercraft:turtle")
				or string.find(b.name, "computercraft:computer")
			then
				sleep(1)
			else
				ok, err = turtle.digUp()
				break
			end
		end
		if not ok then
			return false, (err and err or "failed to safely break block")
		end
	end
	return true
end

function dig.down()
	local ok = true
	local err
	while turtle.detectDown() do
		ok, err = turtle.digDown()
		if not ok then break end
	end
	return ok, err
end

return dig
