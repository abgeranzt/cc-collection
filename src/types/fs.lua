---@alias fs_fh_read fun(count: integer | nil): number | string | nil
---@alias fs_fh_read_line fun(): string | nil
---@alias fs_fh_read_all fun(): string | nil
---@alias fs_fh_write fun(text: string)
---@alias fs_fh_write_line fun(text: string)
---@alias fs_fh_flush fun() Save without closing the file
---@alias fs_fh_close fun()

---@alias fs_filehandle { read: fs_fh_read, readLine: fs_fh_read_line, readAll: fs_fh_read_all, write: fs_fh_write, writeLine: fs_fh_write_line, flush: fs_fh_flush, close: fs_fh_close }

---@alias fs_open_mode 'r' | 'w' | 'a' | 'rb' | 'wb' | 'ab'
---@alias fs_open fun(path: string, mode: fs_open_mode): fs_filehandle
---@alias fs_make_dir fun(path: string)
---@alias fs_delete fun(path: string)

---@alias fs { open: fs_open, makeDir: fs_make_dir, delete: fs_delete}

---@diagnostic disable-next-line: lowercase-global
if not fs then fs = {} end
