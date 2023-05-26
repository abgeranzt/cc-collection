---@alias modem_open fun(channel: integer)
---@alias modem_close fun(channel: integer)
---@alias modem_close_all fun()
---@alias modem_transmit fun(ch: integer, reply_ch: integer, payload: table | string | number)

---@alias modem { open: modem_open, close: modem_close, closeAll: modem_close_all, transmit: modem_transmit}
