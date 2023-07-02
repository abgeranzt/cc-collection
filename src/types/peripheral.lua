---@alias peripheral_inventory_size fun(): integer
---@alias peripheral_inventory_list_entry { count: integer, name: string, nbt: string } | nil
---@alias peripheral_inventory_list fun(): peripheral_inventory_list_entry[]
---@alias peripheral_inventory_get_item_detail_entry { count: integer, displayName: string, maxCount: integer, name: string, nbt: string, tags: { [string]: boolean } } | nil
---@alias peripheral_inventory_get_item_detail fun(slot: integer):  peripheral_inventory_get_item_detail_entry
---@alias peripheral_inventory_get_item_limit fun(slot: integer): integer
---@alias peripheral_inventory_push_items fun(toName: string, fromSlot: integer, limit: integer | nil, toSlot: integer | nil): integer
---@alias peripheral_inventory_pull_items fun(fromName: string, fromSlot: integer, limit: integer | nil, toSlot: integer | nil): integer

---@alias peripheral_inventory { size: peripheral_inventory_size, list: peripheral_inventory_list, getItemDetail: peripheral_inventory_get_item_detail, getItemLimit: peripheral_inventory_get_item_limit, pushItems: peripheral_inventory_push_items, pullItems: peripheral_inventory_pull_items }
