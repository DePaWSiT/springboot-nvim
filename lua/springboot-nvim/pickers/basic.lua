---@type Table_Utils
local table_utils = require("springboot-nvim.table-utils")

---@class BasicPicker
local M = {}

local selection = {}

---loops the vim.ui.select to choose multiple dependencies
---@param items string[] An array-style table with values
---@param opts table Options to be passed to vim.ui.select
---@param done_flag PickerItem Text set for the 'done' marker (default "Done")
---@param callback fun(selection:PickerItem[]|nil) A callback method with the result
local function select_sync_loop(items, opts, done_flag, callback)
  vim.ui.select(items, opts, function(choice)
    if choice == nil then
      return
    end
    --break out of callback loop
    if choice == done_flag then
      callback(selection)
      return
    end
    --remove value from table and inserting it into local table
    local pick = table_utils.table_pop_value(items, choice)
    if pick then
      table.insert(selection, pick)
    end

    --loop the callback
    select_sync_loop(items, opts, done_flag, callback)
  end)
end

---Using a looped callback on vim.ui.select to choose dependencies
---@param springboot_data table An array-style table with values
---@param opts table|nil Options to be passed to vim.ui.select, don't use the format_item option as that one as set
---@param done_flag PickerItem|nil Text set for the 'done' marker (default "Done")
---@param callback fun(selection:PickerItem[]|nil) A callback method with the result
M.choose_spring_dependencies = function(
  springboot_data,
  opts,
  done_flag,
  callback
)
  --unpack data from request
  local items = {}
  for _, categories in pairs(springboot_data.dependencies.values) do
    for _, dependancies in pairs(categories.values) do
      table.insert(items, { id = dependancies.id, name = dependancies.name })
    end
  end

  opts = opts or {}
  table.insert(opts, {
    format_item = function(item)
      return item.name
    end,
  })

  --add done flag
  done_flag = done_flag or { value = "Done", name = "Done" }
  table.insert(items, done_flag)

  select_sync_loop(items, opts, done_flag, callback)
end

return M
