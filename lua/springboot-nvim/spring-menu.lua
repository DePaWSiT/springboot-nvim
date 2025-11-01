---@type ConfigOptions
local config = require("springboot-nvim.config")
---@class Spring_Menu
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
    -- table.insert(menu, string.format("%d. %s", i, action.name))
    table.insert(menu, action.name)
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
      name = "Get project root",
      func = function()
        ---@type Utils
        local utils = require("springboot-nvim.utils")
        vim.notify(
          tostring(utils.get_spring_boot_project()),
          vim.log.levels.DEBUG
        )
      end,
    },
    {
      name = "Return",
      func = function()
        M.open_spring_menu()
      end,
    },
    closing_menu_item,
  }

  open_menu(dev_action_definitions, { prompt = "Select an option: " })
end

M.open_spring_menu = function()
  ---@type table<Spring_Menu_Definitions>
  local spring_action_definitions = {
    {
      name = "Create new project",
      func = function()
        ---@type Create_Springboot_Project
        local proj = require("springboot-nvim.create-springboot-project")
        proj.springboot_new_project()
      end,
    },
    {
      name = "Add Class",
      func = function()
        ---@type Generator
        local gen = require("springboot-nvim.generator")
        gen.generate_class()
      end,
    },
    {
      name = "Add Record",
      func = function()
        ---@type Generator
        local gen = require("springboot-nvim.generator")
        gen.generate_record()
      end,
    },
    {
      name = "Add Interface",
      func = function()
        ---@type Generator
        local gen = require("springboot-nvim.generator")
        gen.generate_interface()
      end,
    },
    {
      name = "Add Enum",
      func = function()
        ---@type Generator
        local gen = require("springboot-nvim.generator")
        gen.generate_enum()
      end,
    },
    {
      name = "Add Test Class",
      func = function()
        ---@type Generator
        local gen = require("springboot-nvim.generator")
        gen.generate_test_class()
      end,
    },
    {
      name = "Add Test Record",
      func = function()
        ---@type Generator
        local gen = require("springboot-nvim.generator")
        gen.generate_test_record()
      end,
    },
    {
      name = "Add Test Interface",
      func = function()
        ---@type Generator
        local gen = require("springboot-nvim.generator")
        gen.generate_test_interface()
      end,
    },
    {
      name = "Add Test Enum",
      func = function()
        ---@type Generator
        local gen = require("springboot-nvim.generator")
        gen.generate_test_enum()
      end,
    },
    {
      name = "Start",
      func = function()
        ---@type RunProject
        local run = require("springboot-nvim.run-project")
        run.start()
      end,
    },
    {
      name = "Restart",
      func = function()
        ---@type RunProject
        local run = require("springboot-nvim.run-project")
        run.restart()
      end,
    },
    {
      name = "Stop",
      func = function()
        ---@type RunProject
        local run = require("springboot-nvim.run-project")
        run.stop()
      end,
    },
  }

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
