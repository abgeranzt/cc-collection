-- This file does not do anything, it only exists to provide type definitions for the language server.

--- @alias modem {open: fun(c: number), close: fun(c: number), transmit: fun(c: number, rc: number, msg: string | table)}

--- @alias msg_body_cmd {cmd: string, params: table}
--- @alias msg_body_gps {x: number, y: number, z: number}
--- @alias msg_body msg_body_cmd | msg_body_gps
--- @alias msg_status "err" | "ok"
--- @alias msg_payload {id: number, body: msg_body | nil, status: msg_status | nil}
--- @alias msg_type "cmd" | "res" | "gps"
--- @alias msg {rec: string, snd: string, type: msg_type, payload: msg_payload | nil }

--- @alias cmd_type "excavate" | "tunnel" | "navigate" | "dump"
--- @alias cmd_direction "forward" | "back" | "up" | "down" | "left" | "right"

--- @alias task {reply_ch: number, id: number, body: {cmd: string, params: table}}

--- @alias gps_position {x: number, y: number, z: number}
--- @alias gps_event_data {label: string, position: gps_position}

--- @alias file_handle {close: fun(), flush: fun(), write: fun(s: string), writeLine: fun(s: string) }

--- @alias logger {fatal: fun(s: string), error: fun(s: string), warn: fun(s: string), info: fun(s: string), debug: fun(s: string), trace: fun(s: string)}
