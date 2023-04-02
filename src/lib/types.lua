-- This file does not do anything, it only exists to provide type definitions for the language server.

-- type defs for built-in APIs
---@alias turtle {detect: fun(), detectUp: fun(), detectDown: fun(), dig: fun(), digUp: fun(), digDown: fun(), turnLeft: fun(), turnRight: fun(), getFuelLevel: fun(), select: fun(s: number), getSelectedSlot: fun(), drop: fun(n: number | nil), dropUp: fun(n: number | nil), dropDown: fun(n: number | nil), place: fun(), placeUp: fun(), placeDown: fun(), suck: fun(), suckUp: fun(), suckDown: fun(), refuel: fun(), getItemCount: fun(s: number | nil)}
---@alias modem {open: fun(c: number), close: fun(c: number), transmit: fun(c: number, rc: number, msg: string | table)}

---@alias msg_body_cmd {cmd: string, params: table}
---@alias msg_body_gps {x: number, y: number, z: number}
---@alias msg_body_res string | nil
---@alias msg_body msg_body_cmd | msg_body_gps | msg_body_res
---@alias msg_status "err" | "ok"
---@alias msg_payload {id: number, body: msg_body | nil, status: msg_status | nil}
---@alias msg_type "cmd" | "res" | "gps"
---@alias msg {rec: string, snd: string, type: msg_type, payload: msg_payload | nil }

---@alias cmd_type "excavate" | "tunnel" | "navigate" | "dump" | "get_fuel" | "refuel"
---@alias cmd_direction "forward" | "back" | "up" | "down" | "left" | "right"

---@alias worker { label: string, type: worker_type, channel: number, deployed: boolean, position: gps_position | nil}
---@alias worker_task {reply_ch: number, id: number, body: {cmd: string, params: table}}
---@alias worker_type "miner" | "loader"

---@alias gps_position {x: number, y: number, z: number}
---@alias gps_event_data {label: string, position: gps_position}

---@alias file_handle {close: fun(), flush: fun(), write: fun(s: string), writeLine: fun(s: string), readLine: fun() }

---@alias logger {fatal: fun(s: string), error: fun(s: string), warn: fun(s: string), info: fun(s: string), debug: fun(s: string), trace: fun(s: string)}

---@alias task {worker: string, completed: boolean, status: msg_status, data: string | nil}

---@alias peripheral_inventory { size: fun(), list: fun(), getItemDetail: fun(s: number), getItemLimit: fun(s:number) }
