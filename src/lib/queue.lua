-- Simple queue implementation.
---@class Queue lib_queue
local Queue = {}

function Queue.create()
	local queue = { fpos = 1, lpos = 1, len = 0 }

	function queue.push(item)
		queue[queue.fpos] = item
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

	return queue
end

-- FIXME this is deprected, refactor the code it is used in
local queue = { fpos = 1, lpos = 1, len = 0 }

function queue.push(item)
	queue[queue.fpos] = item
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
return { Queue = Queue, queue = queue }
