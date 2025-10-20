---@type Autocmds
local autocmds = require("springboot-nvim.autocmd")
---@type ConfigOptions
local config = require("springboot-nvim.config")
---@type Spring_Menu
local spring_menu = require("springboot-nvim.spring-menu")

---@class Init
local M = {}

---Helper for creating the user commands
local function create_usercommands()
  vim.api.nvim_create_user_command("Spring", spring_menu.open_spring_menu, {})
end

---Helper for setting a picker function
local set_picker = function()
  if config.picker == "default" then
    local snacks_picker_present, _ = pcall(require, "snacks.picker")
    if snacks_picker_present then
      config.picker = "snacks"
    else
      config.picker = "vim"
    end
  end
end

---Helper to enable the dev menu
local enable_dev_menu = function()
  vim.notify("Dev menu enabled", vim.log.levels.INFO)

  vim.api.nvim_create_user_command("SpringDevMenu", function()
    require("springboot-nvim.dev-menu").open_dev_menu()
  end, {})
end

---First function to be run
---@param opts ConfigOptions user provided configuration options
M.setup = function(opts)
  config = vim.tbl_deep_extend("force", config, opts)
  autocmds.create_autocmds()
  create_usercommands()
  set_picker()

  if config.dev_menu then
    enable_dev_menu()
  end
end

return M
