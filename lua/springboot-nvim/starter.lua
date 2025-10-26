---@type Utils
local utils = require("springboot-nvim.utils")
local M = {}

local function get_run_command(args)
  local project_root = utils.get_spring_boot_project_root()
  if project_root == nil then
    vim.notify("Could not find project root", vim.log.levels.ERROR)
    return nil
  end

  local maven_file = vim.fn.findfile("pom.xml", project_root)
  local gradle_file = vim.fn.findfile("build.gradle", project_root)
  local kts_gradle_file = vim.fn.findfile("build.gradle.kts", project_root)

  if maven_file ~= "" then
    return string.format(
      ':call jobsend(b:terminal_job_id, "cd %s && mvn spring-boot:run %s \\n")',
      project_root,
      args or ""
    )
  elseif gradle_file or kts_gradle_file ~= "" then
    return string.format(
      ':call jobsend(b:terminal_job_id, "cd %s && ./gradlew bootRun %s \\n")',
      project_root,
      args or ""
    )
  else
    vim.notify("Could not determine project type {Gradle or Maven}")
    return nil
  end
end

local function boot_run(args)
  local project_root = utils.get_spring_boot_project_root()
  if project_root == nil then
    vim.notify("Could not find project root", vim.log.levels.ERROR)
    return
  end

  if project_root then
    vim.cmd("split | terminal")
    vim.cmd("resize 15")
    vim.cmd("norm G")
    local cd_cmd = ':call jobsend(b:terminal_job_id, "cd '
      .. project_root
      .. '\\n")'
    vim.cmd(cd_cmd)
    local run_cmd = get_run_command(args or "")
    vim.cmd(run_cmd)
    vim.cmd("wincmd k")
  else
    vim.notify("Not in a spring boot project", vim.log.levels.ERROR)
    return
  end
end

return M
