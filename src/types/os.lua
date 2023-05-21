---@alias os_pullEvent fun(name: string): string, ...
---@alias os_queueEvent fun(name: string, ...)
---@alias os_getComputerLabel fun(): string
---@alias os_setComputerLabel fun(label: string)

---@alias os { pullEvent: os_pullEvent, queueEvent: os_queueEvent, getComputerLabel: os_getComputerLabel, os_setComputerLabel: os_setComputerLabel}
