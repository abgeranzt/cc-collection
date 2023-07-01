---@diagnostic disable-next-line: unknown-cast-variable
---@cast os os

---@param send_cmd fun(ch: number, rec_name: string, payload: msg_payload)
---@param logger lib_logger
---@param worker lib_worker_master
local function init(send_cmd, worker, logger)
	---@class lib_task
	local lib = {}

	local _id = 1
	local _tasks = {}
	---@cast _tasks task[]

	---@param label string
	---@param command cmd_type
	---@param params table | nil
	function lib.create(label, command, params)
		logger.info("creating '" .. command .. "' task (id: " .. _id .. ") for '" .. label .. "'")
		local payload = {
			id = _id,
			body = {
				cmd = command,
				params = params
			}
		}
		logger.trace("sending task to worker")
		send_cmd(worker.get(label).channel, label, payload)
		local t = {
			completed = false,
			worker = label
		}
		_tasks[_id] = t
		_id = _id + 1
		return payload.id
	end

	---@param id number
	function lib.get_status(id)
		return _tasks[id].status
	end

	---@param id number
	function lib.get_data(id)
		return _tasks[id].data
	end

	---@param id number
	function lib.is_completed(id)
		return _tasks[id].completed
	end

	---@param id number
	function lib.is_successful(id)
		return _tasks[id].status == "ok" and true or false
	end

	---@param id number
	function lib.await(id)
		while not lib.is_completed(id) do
			sleep(1)
		end
	end

	function lib.monitor()
		while true do
			local _, id, status, data = os.pullEvent("task_update")
			---@cast id number
			---@cast status msg_status
			---@cast data string | nil
			_tasks[id].completed = true
			_tasks[id].status = status
			_tasks[id].data = data
		end
	end

	return lib
end

return {
	init = init
}
