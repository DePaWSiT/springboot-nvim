local M = {}
---Don't know what this does
---@param file_path string A file path
---@return boolean contains whether there is package info
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

---find something .java
---@param file_path string the file path to search from
---@return string|nil package java package
M.get_java_package = function(file_path)
  local path_pattern = "src/(.-)%.java"
  local java_file_path = file_path:match(path_pattern)
  if not java_file_path then
    vim.notify(
      string.format("Could not find '%s' path pattern", path_pattern),
      vim.log.levels.ERROR
    )
    return nil
  end

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
end

---Checks and add packages
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

return M
