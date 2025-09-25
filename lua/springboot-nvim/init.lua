--this is the only thing actually doing something in the init???
require("create_springboot_project")
local utils = require("springboot-nvim.utils")
local jdtls = require("jdtls")

local M = {}

M.incremental_compile = function()
  jdtls.compile("incremental")
end

M.get_run_command = function(args)
  local project_root = utils.get_spring_boot_project_root()
  if not project_root then
    return "Unknown"
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
    print("No build file (pom.xml or build.gradle) found in the project root.")
    return "Unknown"
  end
end

M.boot_run = function(args)
  local project_root = utils.get_spring_boot_project_root()

  if project_root then
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
  else
    print("Not in a Spring Boot project")
  end
end

M.contains_package_info = function(file_path)
  local file = io.open(file_path, "r")
  if not file then
    return false
  end
  local current_position = file:seek()
  local file_size = file:seek("end")
  file:seek("set", current_position)
  file:close()

  return file_size > 0
end

M.get_java_package = function(file_path)
  local java_file_path = file_path:match("src/(.-)%.java")
  if java_file_path then
    local package_path = java_file_path:gsub("/", ".")

    local t = {}
    for str in string.gmatch(package_path, "([^.]+)") do
      table.insert(t, str)
    end

    local package = ""

    for i = 3, #t - 1 do
      package = package .. "." .. t[i]
    end

    return string.sub(package, 2, -1)
  else
    return nil
  end
end

M.check_and_add_package = function()
  local file_path = vim.fn.expand("%:p")
  if not M.contains_package_info(file_path) then
    local package_location = M.get_java_package(file_path)
    local package_text = "package " .. package_location .. ";"
    local buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { package_text, "", "" })
    vim.api.nvim_win_set_cursor(0, { 3, 0 })
  end
end
-- key mapping

-- auto commands
M.setup = function()
  vim.api.nvim_exec2(
    [[
    augroup JavaAutoCommands
    autocmd!
    autocmd BufWritePost *.java lua require('springboot-nvim').incremental_compile()
    augroup END
]],
    { output = false }
  )

  vim.api.nvim_exec2(
    [[
    augroup JavaPackageDetails
    autocmd!
    autocmd BufReadPost *.java lua require('springboot-nvim').fill_package_details()
    augroup END
]],
    { output = false }
  )

  vim.api.nvim_exec2(
    [[
  	augroup ClosePluginBuffers
  	autocmd!
  	autocmd FileType springbootnvim autocmd QuitPre * lua require('springboot-nvim').close_ui()
  	augroup END
]],
    { output = false }
  )
end

return M
