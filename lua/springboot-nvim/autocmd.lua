---@class Autocmds
local M = {}

--TODO: Do something with the callback function (if it returns something)
local function incremental_compile()
  local options = require("springboot-nvim.init").options
  require("jdtls").compile(options.jdtls_compile, function(result)
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

  vim.api.nvim_create_autocmd("BufReadPost", {
    pattern = "*.java",
    group = group,
    callback = function()
      require("springboot-nvim.package").check_and_add_package()
    end,
  })

  vim.api.nvim_create_autocmd("QuitPre", {
    group = group,
    callback = function()
      if vim.bo.filetype == "springbootnvim" then
        require("springboot-nvim.ui.springboot_nvim_ui").close_ui()
      end
    end,
  })
end

return M
