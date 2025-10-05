local utils = require("springboot-nvim.utils")

local M = {}

---For getting the appropriate command for running the project (maven or gradle)
---@param args string A string having additional run args
---@return string|nil RunCommand Either the build command or nil if not build file or project root is found
M.get_run_command = function(args)
  local project_root = utils.get_spring_boot_project_root()
  if not project_root then
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
    vim.notify(
      "No build file (pom.xml or build.gradle) found in the project root.",
      vim.log.levels.ERROR
    )
    return nil
  end
end

---Launches the spring boot project
---@param args string launch arguments, all in one string
M.boot_run = function(args)
  local project_root = utils.get_spring_boot_project_root()

  if not project_root then
    vim.notify("Could not find a build file", vim.log.levels.ERROR)
    return
  end

  vim.cmd("split | terminal")
  vim.cmd("resize 15")
  vim.cmd("norm G")
  local cd_cmd = ':call jobsend(b:terminal_job_id, "cd '
    .. project_root
    .. '\\n")'
  vim.cmd(cd_cmd)
  local run_cmd = M.get_run_command(args or "")
  vim.cmd(run_cmd)
  vim.cmd("wincmd k")
end

return M
