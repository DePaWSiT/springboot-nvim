local M = {}

local action_definitions = {
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
  {
    name = "Close Menu",
    func = "cancelled",
  },
}

local menu = { "Select an action:" }
local actions = {}

for i, action in ipairs(action_definitions) do
  table.insert(menu, string.format("%d. %s", i, action.name))
  actions[i] = action.func
end

M.open_dev_menu = function()
  local choice = vim.fn.inputlist(menu)

  local func = actions[choice]
  if func == "cancelled" then
    return
  elseif func then
    --TODO: How to handle parameters in function?
    func()
  else
    vim.notify("Invalid option", vim.log.levels.WARN)
  end
end

return M
