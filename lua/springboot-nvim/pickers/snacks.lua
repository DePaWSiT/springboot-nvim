---@type snacks.picker
local picker = require("snacks.picker")

---@class SnacksPicker
local M = {}

---Using snacks picker for dependecy selection
---@param springboot_data table
---@param callback fun(selection:string[]) A callback method with the result
M.choose_spring_dependencies = function(springboot_data, callback)
  local dependencies = {}
  for _, categories in pairs(springboot_data.dependencies.values) do
    for _, deps in pairs(categories.values) do
      table.insert(dependencies, { text = deps.name, value = deps.id })
    end
  end

  local selection = {}
  picker.pick({
    items = dependencies,
    prompt = "TAB to select, ENTER to submit",
    format = "text",
    confirm = function(ret_picker)
      local selected = ret_picker:selected()
      for _, item in pairs(selected) do
        table.insert(selection, item.value)
      end
      ret_picker:close()
      callback(selection)
    end,
  })
end

return M
