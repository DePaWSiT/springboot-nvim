---@type ConfigOptions
local config = require("springboot-nvim.config")
---@class Autocmds
local M = {}

--TODO: Do something with the callback function (if it returns something)
local function incremental_compile()
  require("jdtls").compile(config.jdtls_compile, function(result)
    vim.notify(
      "jdtls compile result:\n" .. vim.inspect(result),
      vim.log.levels.DEBUG
    )
  end)
end

---Creates the autocommands related to this plugin
M.create_autocmds = function()
  local group =
    vim.api.nvim_create_augroup("JavaSpringAutoCommands", { clear = true })

  vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = "*.java",
    group = group,
    callback = function()
      incremental_compile()
    end,
  })
end

return M
