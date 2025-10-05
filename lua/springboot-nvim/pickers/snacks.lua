local utils = require("springboot-nvim.utils")
local snacks = require("snacks")

local M = {}

--TODO: Use API to get list
--TODO: Call this method from the project creation pipeline
--TODO: Get data on the dependencies from the
---@param on_confirm function(table<string>):void Function to be used for asking the user for dependencies when creating spring boot project
M.choose_spring_dependencies = function(on_confirm)
  local dependencies = {}
  local request = utils.safe_request("https://start.spring.io/metadata/client")
  local data = utils.safe_json_decode(request.stdout)
  for _, categories in pairs(data.dependencies.values) do
    for _, deps in pairs(categories.values) do
      table.insert(dependencies, { text = deps.name, value = deps.id })
    end
  end

  snacks.picker.pick({
    items = dependencies,
    prompt = "TAB to select items, ENTER to submit",
    format = "text",
    confirm = function(picker)
      local selected = picker:selected()
      local values = {}
      for _, item in pairs(selected) do
        table.insert(values, item.value)
      end
      on_confirm(values)
      picker:close()
    end,
  })
end

return M
