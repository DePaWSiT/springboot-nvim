---@type ConfigOptions
local config = require("springboot-nvim.config")
---@class Dev_Menu
local M = {}

---@type Spring_Menu_Definitions
local closing_menu_item = {
  name = "Close Menu",
  func = "cancelled",
}
---Base menu function
---@param definitions table<Spring_Menu_Definitions>
---@param opts table vim.ui.select options
local open_menu = function(definitions, opts)
  local menu = {}
  local actions = {}
  for i, action in ipairs(definitions) do
    table.insert(menu, string.format("%d. %s", i, action.name))
    actions[i] = action.func
  end

  vim.ui.select(menu, opts, function(_, idx)
    if idx == nil then
      return
    end
    local action = actions[idx]

    if action == "cancelled" then
      return
    elseif action then
      action()
    else
      vim.notify("Invalid option", vim.log.levels.WARN)
    end
  end)
end

local open_dev_menu = function()
  ---@type table<Spring_Menu_Definitions>
  local dev_action_definitions = {
    {
      name = "Open File",
      func = function()
        print("Opening file...")
      end,
    },
    {
      name = "Save File",
      func = function()
        print("Saving file...")
      end,
    },
    {
      name = "Close Editor",
      func = function()
        print("Closing editor...")
      end,
    },
    closing_menu_item,
  }

  open_menu(dev_action_definitions, { prompt = "Select an option: " })
end

M.open_spring_menu = function()
  ---@type table<Spring_Menu_Definitions>
  local spring_action_definitions = {}

  if config.dev_menu then
    table.insert(spring_action_definitions, {
      name = "Open dev menu",
      func = function()
        open_dev_menu()
      end,
    })
  end

  table.insert(spring_action_definitions, closing_menu_item)

  open_menu(spring_action_definitions, { prompt = "Select and option: " })
end

return M
