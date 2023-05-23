---@alias go_forward fun(n: number | nil): boolean, string | nil
---@alias go_back fun(n: number | nil): boolean, string | nil
---@alias go_up fun(n: number | nil): boolean, string | nil
---@alias go_down fun(n: number | nil): boolean, string | nil
---@alias go_left fun(n: number | nil): boolean, string | nil
---@alias go_right fun(n: number | nil): boolean, string | nil
---@alias go_coords fun(current_pos: gpslib_position, target_po: gpslib_position, go_lib: go_interface | nil): boolean, string | nil
---@alias go { forward: go_forward, back: go_back, up: go_up, down: go_down, left: go_left, right: go_right, coords: go_coords}

---@alias go_interface { forward: go_forward, back: go_back, up: go_up, down: go_down }
