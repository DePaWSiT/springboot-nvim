---@class Utils
local M = {}

M.class_boiler_plate = "package %s;\n\npublic class %s{\n\n}"
M.record_boiler_plate = "package %s;\n\npublic record %s(\n\n){}"
M.interface_boiler_plate = "package %s;\n\npublic interface %s{\n\n}"
M.enum_boiler_plate = "package %s;\n\npublic enum %s{\n\n}"
M.spring_languages = { "java", "kotlin", "groovy" }
M.spring_root_patterns = { "pom.xml", "build.gradle", "build.gradle.kts" }

---returns the project root for a spring project based on cwd
---@return string|nil root_dir The root directory for the spring boot project
M.get_spring_boot_project_root = function()
  for _, pattern in ipairs(M.spring_root_patterns) do
    local match = vim.fs.find(pattern, {
      path = vim.loop.cwd(),
      type = "file",
    })[1]
    if match then
      return vim.fs.dirname(match)
    end
  end
  vim.notify(
    "Root directory of spring project could not be found",
    vim.log.levels.WARN
  )
  return nil
end

---returns the directory where the file is located containing the @SpringBootApplication decorator (likely main)
---@return string|nil dir The directory where the @SpringBootApplication decoration is located in
M.find_main_application_class_directory = function()
  local main_class_pattern = "@SpringBootApplication"

  --requires ripgrep now
  local file = vim.fn.systemlist(
    string.format("rg --files-with-matches %s -1", main_class_pattern)
  )[1]
  local dir = file and vim.fn.fnamemodify(file, ":h") or nil
  if not dir then
    vim.notify(
      "Main application class not found in the project directory.",
      vim.log.levels.ERROR
    )
    return nil
  end
  return dir
end

return M
