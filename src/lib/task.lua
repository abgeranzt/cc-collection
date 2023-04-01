---@param send_msg fun(target_ch: number, msg_target: string, payload: msg_payload)
---@param logger logger
---@param worker {get: fun(label: string): worker}
local function master_setup(send_msg, worker, logger)
	local _id = 1
	local _tasks = {}
	---@cast _tasks task[]

	---@param label string
	---@param command cmd_type
	---@param params table
	local function create(label, command, params)
		logger.info("creating '" .. command .. "' task for '" .. label .. "'")
		local payload = {
			id = _id,
			body = {
				cmd = command,
				params = params
			}
		}
		logger.trace("sending task to worker")
		send_msg(worker.get(label).channel, label, payload)
		local t = {
			completed = false,
			worker = label
		}
		_tasks[_id] = t
		_id = _id + 1
	end

	---@param id number
	local function get_status(id)
		return _tasks[id].status
	end

	---@param id number
	local function is_completed(id)
		return _tasks[id].completed
	end

	local function monitor()
		while true do
			---@diagnostic disable-next-line: undefined-field
			local _, id, status = os.pullEvent("task_update")
			---@cast id number
			---@cast status msg_status
			_tasks[id].completed = true
			_tasks[id].status = status
		end
	end

	return {
		create = create,
		get_status = get_status,
		is_completed = is_completed,
		monitor = monitor
	}
end

return {
	master_setup = master_setup
}
