-- This file does not do anything, it only exists to provide type definitions for the language server.

-- type defs for built-in APIs
---@alias colors { white: integer, orange: integer, magenta: integer, lightBlue: integer, yellow: integer, lime: integer, pink: integer, gray: integer, lightGray: integer, cyan: integer, purple: integer, blue: integer, brown: integer, green: integer, red: integer, black: integer }
---@diagnostic disable-next-line: lowercase-global
if not colors then colors = {} end
---@alias gps { locate: fun() }
---@diagnostic disable-next-line: lowercase-global
if not gps then gps = {} end
---@alias modem {open: fun(c: number), close: fun(c: number), transmit: fun(c: number, rc: number, msg: string | table)}
---@alias monitor { setTextScale: fun(n: number), getCursorPos: fun(), setCursorPos: fun(x: integer, y: integer), blit: fun(t: string, tc: string, bc: string), write: fun(t: string), setTextColor: fun(c: integer), setBackgroundColor: fun(c: integer), getSize: fun(), scroll: fun(y: integer) }
---@alias os { pullEvent: fun(n: string), queueEvent: fun(n: string, ...), getComputerLabel: fun(), setComputerLabel: fun(l: string) }
---@alias peripheral { call: fun(d: string, c: string), find: fun(n: string), wrap: fun(d: string) }
---@diagnostic disable-next-line: lowercase-global
if not peripheral then peripheral = {} end
---@alias turtle { detect: fun(), detectUp: fun(), detectDown: fun(), dig: fun(), digUp: fun(), digDown: fun(), turnLeft: fun(), turnRight: fun(), getFuelLevel: fun(), select: fun(s: number), getSelectedSlot: fun(), drop: fun(n: number | nil), dropUp: fun(n: number | nil), dropDown: fun(n: number | nil), place: fun(), placeUp: fun(), placeDown: fun(), suck: fun(), suckUp: fun(), suckDown: fun(), refuel: fun(), getItemCount: fun(s: number | nil), getItemDetail: fun(s: number, d: boolean | nil), inspect: fun(), inspectUp: fun(), inspectDown: fun(), equipLeft: fun(), equipRight: fun() }
---@diagnostic disable-next-line: lowercase-global
if not turtle then turtle = {} end
---@diagnostic disable-next-line: unknown-cast-variable
---@cast turtle turtle
if not sleep then
	---@diagnostic disable-next-line lowercase-global
	sleep = function(_)
	end
end

---@alias argparse_arg_type "string" | "number" | "boolean" | "array"
---@alias argparse_arg_default string | number | boolean | nil | string[]
---@alias argparse_arg {short: string, type: argparse_arg_type, required: boolean, default: argparse_arg_default}

---@alias msg_body_cmd {cmd: string, params: table}
---@alias msg_body_gps {x: number, y: number, z: number}
---@alias msg_body_res string | nil
---@alias msg_body msg_body_cmd | msg_body_gps | msg_body_res
---@alias msg_status "err" | "ok"
---@alias msg_payload {id: number, body: msg_body | nil, status: msg_status | nil}
---@alias msg_type "cmd" | "res" | "gps"
---@alias msg {rec: string, snd: string, type: msg_type, payload: msg_payload | nil }

---@alias cmd_type "excavate" | "excavate_bedrock" | "tunnel" | "navigate" | "dump" | "get_fuel" | "refuel"
---@alias cmd_direction "forward" | "back" | "up" | "down" | "left" | "right"

---@alias hoz_direction "forward" | "back" | "left" | "right"

---@alias worker { label: string, type: worker_type, channel: number, deployed: boolean, position: gps_position | nil}
---@alias worker_task {reply_ch: number, id: number, body: {cmd: string, params: table}}
---@alias worker_type "miner" | "loader"
--
---@alias worker_lib_get fun(label: string): worker
---@alias worker_lib_get_labels fun(worker_type: worker_type | nil): string[]
---@alias worker_lib { create: fun(l: string, wt: worker_type, wch: number), load_from_file: fun(), get: worker_lib_get, get_labels: worker_lib_get_labels, deploy: fun(l: string), collect: fun(l: string) }

---@alias gps_position {x: number, y: number, z: number}
---@alias gps_event_data {label: string, position: gps_position}

---@alias file_handle {close: fun(), flush: fun(), write: fun(s: string), writeLine: fun(s: string), readLine: fun() }

---@alias logger {fatal: fun(s: string), error: fun(s: string), warn: fun(s: string), info: fun(s: string), debug: fun(s: string), trace: fun(s: string)}
---@alias log_level "fatal" | "error" | "warn" | "info" | "debug" | "trace"
---@alias log_event {snd: string, lvl: log_level, msg: string, raw: string}

---@alias task {worker: string, completed: boolean, status: msg_status, data: string | nil}

---@alias task_lib_create fun(worker: string, command: cmd_type, params: table): number
---@alias task_lib { await: fun(id: number), create: task_lib_create, get_data: fun(id: number), get_status: fun(id: number), is_completed: fun(id: number), monitor: fun() }

---@alias peripheral_inventory { size: fun(), list: fun(), getItemDetail: fun(s: number), getItemLimit: fun(s:number) }

---@alias go {forward: fun(n: number | nil), back: fun(n: number | nil), up: fun(n: number | nil), down: fun(n: number | nil), left: fun(n: number | nil), right: fun(n: number | nil)}

---@alias dimensions {w: number, l: number, h: number}
