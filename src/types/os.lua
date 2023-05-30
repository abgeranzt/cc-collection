---@alias os_pullEvent fun(name: string): string, ...
---@alias os_queueEvent fun(name: string, ...)
---@alias os_get_computer_label fun(): string
---@alias os_set_computer_label fun(label: string)

---@alias os { pullEvent: os_pullEvent, queueEvent: os_queueEvent, getComputerLabel: os_get_computer_label, setComputerLabel: os_set_computer_label}
