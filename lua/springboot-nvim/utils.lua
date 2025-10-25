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

---Returns all relative paths of subdirectories below the given filepath
---@param filepath string Starting filepath
---@return string[] subdirectories All the subdirectories below the filepath
function M.get_relative_subdirectories(filepath)
  local subdirs = {}

  filepath = filepath:gsub("/$", "")

  local handle = vim.loop.fs_scandir(filepath)
  if not handle then
    return subdirs
  end

  while true do
    local name, type = vim.loop.fs_scandir_next(handle)
    if not name then
      break
    end
    if type == "directory" then
      table.insert(subdirs, name)

      local deeper = M.get_relative_subdirectories(filepath .. "/" .. name)
      for _, d in ipairs(deeper) do
        table.insert(subdirs, name .. "/" .. d)
      end
    end
  end
  return subdirs
end

---Makes a safe web request
---@param url string url for the web request
---@return vim.SystemCompleted|nil result a systemcompleted object with the result of the web request
M.safe_request = function(url)
  local status, request = pcall(function()
    return vim.system({ "curl", "-s", url }, { text = true }):wait()
  end)

  if not status then
    vim.notify(
      "Error making request to " .. url .. ": " .. request,
      vim.log.levels.ERROR
    )
    return nil
  end

  return request
end

---Decodes JSON data using a pcall and json_decode
---@param data string A JSON formatted string
---@return any decoded Returns the decoded JSON string, the type of the return depends on the JSON string that was decoded
M.safe_json_decode = function(data)
  local status, decoded = pcall(vim.fn.json_decode, data)

  if not status then
    vim.notify("Error decoding JSON: " .. decoded, vim.log.levels.ERROR)
    return nil
  end

  return decoded
end

return M
