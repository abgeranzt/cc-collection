-- Task queue
local queue = { fpos = 1, lpos = 1, len = 0 }

function queue.push(task)
	queue[queue.fpos] = task
	queue.fpos = queue.fpos + 1
	queue.len = queue.len + 1
end

function queue.pop()
	local task = queue[queue.lpos]
	queue[queue.lpos] = nil
	queue.lpos = queue.lpos + 1
	queue.len = queue.len - 1
	return task
end

---@cast queue queue
return { queue = queue }
