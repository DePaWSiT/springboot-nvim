--this is the only thing actually doing something in the init???
require("springboot-nvim.create-springboot-project")
local package_manager = require("springboot-nvim.package")
local springboot_nvim_ui = require("springboot-nvim.ui.springboot_nvim_ui")
local jdtls = require("jdtls")

local M = {
  options = {
    dev_menu = false,
  },
}

--TODO: Make this a config option (full or incremental)
--TODO: Do something with the callback function (if it returns something)
local function incremental_compile()
  jdtls.compile("incremental")
end

-- auto commands
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
    package_manager.check_and_add_package()
  end,
})

vim.api.nvim_create_autocmd("QuitPre", {
  group = group,
  callback = function()
    if vim.bo.filetype == "springbootnvim" then
      springboot_nvim_ui.close_ui()
    end
  end,
})

M.setup = function(opts)
  M.options = vim.tbl_deep_extend("force", M.options, opts)
  if M.options.dev_menu then
    vim.notify("Dev menu enabled", vim.log.levels.INFO)

    local snacks_present, _ = pcall(require, "snacks")
    if not snacks_present then
      vim.notify(
        "Dev menu disabled as snacks is not present",
        vim.log.levels.WARN
      )
    else
      local dev = require("springboot-nvim.pickers.snacks")
      vim.api.nvim_create_user_command("SpringDevMenu", function()
        dev.choose_spring_dependencies(function(chosen_values)
          if chosen_values == 0 then
          --TODO: If no dependencies are selected, use default (config)
          else
            vim.notify(
              "Selected dependencies:\n- "
                .. table.concat(chosen_values, "\n- "),
              vim.log.levels.INFO
            )
          end
        end)
      end, {})
    end
  end
end

return M
