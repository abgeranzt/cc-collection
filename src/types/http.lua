---@alias http_res_read fun(count: integer | nil): number | string | nil
---@alias http_res_read_line fun(): string | nil
---@alias http_res_read_all fun(): string | nil
---@alias http_res_get_reponse_code fun(): integer, string
---@alias http_res_get_reponse_headers fun(): { [string]: string }

---@alias http_reponse { read: http_res_read, readLine: http_res_read_line, readAll: http_res_read_all, getResponseCode: http_res_get_reponse_code, getReponseHeaders: http_res_get_reponse_headers }
---@alias http_get fun(url: string, headers: { [string]: string } | nil, binary: boolean | nil): http_reponse

---@alias http { get: http_get }

---@diagnostic disable-next-line: lowercase-global
if not http then http = {} end
