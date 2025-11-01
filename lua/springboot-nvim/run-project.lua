---@type Utils
local utils = require("springboot-nvim.utils")

---@class RunProject
local M = {}

---@type string
local last_args = ""
---@type integer|nil
local terminal_id = nil

---For getting the appropriate command for running the project (maven or gradle)
---@param args string A string having additional run args
---@return string|nil RunCommand Either the build command or nil if not build file or project root is found
local function get_run_command(args)
  local project_root = utils.get_spring_boot_project_root()
  if project_root == nil then
    return nil
  end

  local maven_file = vim.fn.findfile("pom.xml", project_root)
  local gradle_file = vim.fn.findfile("build.gradle", project_root)
  local kts_gradle_file = vim.fn.findfile("build.gradle.kts", project_root)

  if maven_file ~= "" then
    return string.format(
      "cd %s && mvn spring-boot:run %s \\r\\n",
      project_root,
      args or ""
    )
  elseif gradle_file or kts_gradle_file ~= "" then
    return string.format(
      "cd %s && ./gradlew bootRun %s \\r\\n",
      project_root,
      args or ""
    )
  else
    vim.notify(
      "No build file (pom.xml or build.gradle) found in the project root.",
      vim.log.levels.ERROR
    )
    return nil
  end
end

local function terminal_is_active()
  if terminal_id == nil then
    return false
  end
  local buftype = vim.bo[terminal_id].buftype
  if buftype ~= "terminal" then
    return false
  end
  return true
end

---Launches the spring boot project
---@param args string launch arguments, all in one string
local function boot_run(args)
  local project_root = utils.get_spring_boot_project_root()

  if project_root == nil then
    vim.notify("Could not find a build file", vim.log.levels.ERROR)
    return
  end

  --check whether a terminal from earlier is still present
  local terminal_active = terminal_is_active()
  if not terminal_active then
    --TODO: terminal size in config?
    vim.cmd("botright split | terminal")
    vim.cmd("resize 15")
    vim.cmd("norm G")
    terminal_id = vim.api.nvim_get_current_buf()
  end
  --ensure terminal is in project root
  vim.fn.chansend(
    vim.bo[terminal_id].channel,
    "cd " .. project_root .. "\\r\\n"
  )
  last_args = args or ""
  local run_cmd = get_run_command(last_args)
  if run_cmd == nil then
    return
  end
  vim.fn.chansend(vim.bo[terminal_id].channel, run_cmd)
  --vim.cmd("wincmd k")
end

function M.start()
  vim.ui.input({ prompt = "Enter launch args or leave empty" }, function(args)
    if args == nil then
      vim.notify("Project start cancelled", vim.log.levels.WARN)
      return
    end
    boot_run(args)
  end)
end

function M.restart()
  local is_active = terminal_is_active()
  if not is_active then
    vim.notify(
      "terminal session is not found, starting a new one",
      vim.log.levels.INFO
    )
    boot_run(last_args)
    return
  end
  --clear terminal
  if vim.has("win32") == 1 then
    vim.fn.chansend(vim.bo[terminal_id].channel, "cls\\r\\n")
  else
    vim.fn.chansend(vim.bo[terminal_id].channel, "clear\\r\\n")
  end
  local run_cmd = get_run_command(last_args)
  if run_cmd == nil then
    return
  end
  vim.fn.chansend(vim.bo[terminal_id].channel, run_cmd)
end

function M.stop()
  local is_active = terminal_is_active()
  if not is_active then
    vim.notify(
      "cannot stop session as active session is not detected",
      vim.log.levels.INFO
    )
    return
  end
  vim.fn.chansend(vim.bo[terminal_id].channel, "\x03")
end

return M
