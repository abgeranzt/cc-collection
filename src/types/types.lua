-- This file does not do anything, it only exists to provide type definitions for the language server.

-- type defs for built-in APIs
---@alias colors { white: integer, orange: integer, magenta: integer, lightBlue: integer, yellow: integer, lime: integer, pink: integer, gray: integer, lightGray: integer, cyan: integer, purple: integer, blue: integer, brown: integer, green: integer, red: integer, black: integer }
---@diagnostic disable-next-line: lowercase-global
if not colors then colors = {} end
---@alias gps { locate: fun() }
---@diagnostic disable-next-line: lowercase-global
if not gps then gps = {} end
---@alias monitor { setTextScale: fun(n: number), getCursorPos: fun(), setCursorPos: fun(x: integer, y: integer), blit: fun(t: string, tc: string, bc: string), write: fun(t: string), setTextColor: fun(c: integer), setBackgroundColor: fun(c: integer), getSize: fun(), scroll: fun(y: integer), clear: fun() }
---@alias peripheral { call: fun(d: string, c: string), find: fun(n: string), wrap: fun(d: string) }
---@diagnostic disable-next-line: lowercase-global
if not peripheral then peripheral = {} end
---@diagnostic disable-next-line: unknown-cast-variable
---@cast turtle turtle
if not sleep then
	---@diagnostic disable-next-line lowercase-global
	sleep = function(_)
	end
end

---@alias argparse_arg_type "string" | "number" | "boolean" | "array" | "enum"
---@alias argparse_arg_default string | number | boolean | nil | string[]
---@alias argparse_arg {short: string, type: argparse_arg_type, required: boolean, default: argparse_arg_default, allowed: {[string]: true} | nil}

---@alias msg_body_cmd {cmd: string, params: table}
---@alias msg_body_gps gpslib_position
---@alias msg_body_res string | nil
---@alias msg_body msg_body_cmd | msg_body_gps | msg_body_res
---@alias msg_status "err" | "ok"
---@alias msg_payload {id: number, body: msg_body | nil, status: msg_status | nil}
---@alias msg_type "cmd" | "res" | "gps"
---@alias msg_senders { [string]: true }
---@alias msg {rec: string, snd: string, type: msg_type, payload: msg_payload | nil }

---@alias cmd_type "excavate" | "excavate_bedrock" | "tunnel" | "tunnel_pos" | "navigate" | "navigate_pos" | "dump" | "get_fuel" | "refuel" | "set_position" | "swap" | "update_position"
---@alias cmd_direction "forward" | "back" | "up" | "down" | "left" | "right"

---@alias direction_hoz "forward" | "back" | "left" | "right"
---@alias direction_ver "up" | "down"

---@alias computer_type worker_type | "master" | "server" | "computer"

---@alias worker { label: string, type: worker_type, channel: number, deployed: boolean, position: gpslib_position}
---@alias worker_task {reply_ch: number, id: number, body: {cmd: string, params: table}}
---@alias worker_type "miner" | "loader"
--
---@alias worker_lib_get fun(label: string): worker
---@alias worker_lib_get_labels fun(worker_type: worker_type | nil): string[]
---@alias worker_lib { create: fun(l: string, wt: worker_type, wch: number), load_from_file: fun(), get: worker_lib_get, get_labels: worker_lib_get_labels, deploy: fun(l: string), collect: fun(l: string) }

---@alias gps_event_data {label: string, position: gpslib_position}
---@alias gpslib_direction "north" | "east" | "south" | "west"
---@alias gpslib_position {x: integer, y: integer, z: integer, dir: gpslib_direction}


---@alias logger {fatal: fun(s: string), error: fun(s: string), warn: fun(s: string), info: fun(s: string), debug: fun(s: string), trace: fun(s: string)}
---@alias log_level "fatal" | "error" | "warn" | "info" | "debug" | "trace"
---@alias log_event {snd: string, lvl: log_level, msg: string, raw: string}

---@alias task {worker: string, completed: boolean, status: msg_status, data: string | nil}

---@alias task_lib_create fun(worker: string, command: cmd_type, params: table): number
---@alias task_lib { await: fun(id: number), create: task_lib_create, get_data: fun(id: number), get_status: fun(id: number), is_completed: fun(id: number), monitor: fun() }

---@alias peripheral_inventory { size: fun(), list: fun(), getItemDetail: fun(s: number), getItemLimit: fun(s:number) }

---@alias dimensions {w: number, l: number, h: number}

---@alias util_inv_dir "forward" | "up" | "down"
---@alias util_fuel_type "consumable" | "container"

---@alias queue { fpos: integer, lpos: integer, len: integer, push: fun(task: table), pop: fun(): table}

---@alias routine_chunk_grid {[integer]: {[integer]: {label: string, tid: integer}}}
