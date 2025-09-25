local lspconfig = require("lspconfig")

local M = {}

M.class_boiler_plate = "package %s;\n\npublic class %s{\n\n}"
M.record_boiler_plate = "package %s;\n\npublic record %s(\n\n){}"
M.interface_boiler_plate = "package %s;\n\npublic interface %s{\n\n}"
M.enum_boiler_plate = "package %s;\n\npublic enum %s{\n\n}"

---converts a value to an integer
---@param val any value to be converted
---@return integer|nil
M.toint = function(val)
  local n = tonumber(val)
  return n and math.floor(n) or nil
end

---returns the project root for a spring project based on cwd
---@return string|nil
M.get_spring_boot_project_root = function()
  local root_pattern = { "pom.xml", "build.gradle", "build.gradle.kts", ".git" }

  local root_dir =
    lspconfig.util.root_pattern(unpack(root_pattern))(vim.loop.cwd())
  if not root_dir then
    vim.notify(
      "Root directory of spring project could not be found",
      vim.log.levels.WARN
    )
    return nil
  end
  return root_dir
end

---returns the directory where the file is located containing the @SpringBootApplication decorator (likely main)
---@return string|nil
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

M.is_nvim_tree_available = function()
  local has_nvim_tree_module = pcall(require, "nvim-tree")
  return has_nvim_tree_module
end

M.java_path = function(full_path)
  local pattern = "(.-)/java"
  return full_path:match(pattern) .. "/java"
end

M.generate_java_file = function(buf, type, package_buf, class_buf)
  local package_buf_int = M.totint(package_buf)
  local class_buf_int = M.totint(class_buf)
  if not package_buf_int or class_buf_int then
    vim.notify("Could not get buffer for package or class", vim.log.levels.WARN)
    return
  end
  local package_input =
    vim.api.nvim_buf_get_lines(package_buf_int, 0, -1, false)
  local package_text = table.concat(package_input)
  local class_input = vim.api.nvim_buf_get_lines(class_buf_int, 0, -1, false)
  local class_text = table.concat(class_input)
  if class_text ~= "" then
    local dir = M.java_path(vim.api.nvim_buf_get_name(buf))
    -- Make sure the directory for the new file ends in a /
    local package_path = package_text:gsub("%.", "/")
    if package_path:sub(-1, -1) ~= "/" and package_path ~= "" then
      package_path = package_path .. "/"
    end

    -- Create a new package if one does not exist
    if vim.fn.isdirectory(dir .. "/" .. package_path) ~= 1 then
      local command = "mkdir -p " .. dir .. "/" .. package_path
      os.execute(command)
    end

    -- Strip trailing . for package import statement
    local package_import = package_text
    if package_text:sub(-1, -1) == "." then
      package_import = string.sub(package_import, 1, -2)
    end

    -- Generate file content
    local java_file_content
    if type == "class" then
      java_file_content =
        string.format(M.class_boiler_plate, package_import, class_text)
    end
    if type == "record" then
      java_file_content =
        string.format(M.record_boiler_plate, package_import, class_text)
    end
    if type == "interface" then
      java_file_content =
        string.format(M.interface_boiler_plate, package_import, class_text)
    end
    if type == "enum" then
      java_file_content =
        string.format(M.enum_boiler_plate, package_import, class_text)
    end
    local java_file =
      io.open(dir .. "/" .. package_path .. class_text .. ".java", "r")

    if java_file then
      print("Java file already exists")
      java_file:close()
      return
    else
      java_file =
        io.open(dir .. "/" .. package_path .. class_text .. ".java", "w")
      if java_file then
        java_file:write(java_file_content)
        java_file:close()
      else
        print("an issue occured generating java file")
      end
    end
    vim.cmd("q!")
    vim.cmd("edit " .. dir .. "/" .. package_path .. class_text .. ".java")
  else
    print("Please specify a class name to continue")
  end
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
