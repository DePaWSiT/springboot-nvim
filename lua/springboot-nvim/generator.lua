---@type Utils
local utils = require("springboot-nvim.utils")

---@class Generator
local M = {}

---Checks whether file already exists (and thus whether a new file can be created)
---@param path string Path to file
---@return boolean result Whether file already exists
local function check_file_creation(path)
  if vim.loop.fs_stat(path) then
    return true
  else
    return false
  end
end

---write helper for writing stuff
---@param path string path to file
---@param contents string stuff to be written
local function generator_write(path, contents)
  local file = io.open(path, "w")
  if not file then
    vim.notify("File failed to open", vim.log.levels.WARN)
    return
  end
  file.write(file, contents)
  file.close(file)
end

---Base method for generator a java file
---@param is_testing boolean Whether the file is to be placed in the test section or the main
---@param callback fun(info: {filename:string, package_name:string, path:string })
local function generator_base(is_testing, callback)
  local root = utils.get_spring_boot_project_root()
  if root == nil then
    vim.notify("Root could not be found", vim.log.levels.ERROR)
    return
  end

  is_testing = is_testing or false

  --path to main or test depending on the situation
  local path_to_main
  if is_testing then
    path_to_main = vim.fs.joinpath(root, "src", "test")
  else
    path_to_main = vim.fs.joinpath(root, "src", "main")
  end

  --thought of making this without asking for package name but then where to place file???
  --ask for filename
  vim.ui.input({ prompt = "Enter filename: " }, function(filename)
    if filename == nil or filename == "" then
      vim.notify("No filename was given", vim.log.levels.WARN)
      return
    end
    --ask for package name
    vim.ui.input({
      prompt = "Enter package name: ",
    }, function(package_name)
      --no package name given
      if package_name == nil or package_name == "" then
        vim.notify("No package name was given", vim.log.levels.WARN)
        return
      end

      --look for java, kotlin or groovy folder
      for _, name in ipairs(utils.spring_languages) do
        local match = vim.fs.find(name, {
          path = path_to_main,
          type = "directory",
          limit = 1,
        })[1]
        --pretty nice that be default the folder name matches the language used, only 3 possible folders
        if match then
          --given all the data is correct, construct path
          local path = vim.fs.joinpath(
            match,
            string.gsub(package_name, "%.", "/"),
            filename
          )
          --for searching, windows doesn't really care if you use / or \ but to make it easier to have them all the same
          path = string.gsub(path, "\\", "/")

          local can_create = check_file_creation(path)
          if not can_create then
            vim.notify("File already exists", vim.log.levels.WARN)
            return
          end

          --pass relevant information back in callback form
          callback({
            filename = filename,
            package_name = package_name,
            path = path,
          })
          --no more searching required so break
          break
        end
      end
    end)
  end)
end

---Generates a new java class
M.generate_class = function()
  generator_base(false, function(info)
    local write_content =
      string.format(utils.class_boiler_plate, info.package_name, info.filename)
    generator_write(info.path, write_content)
  end)
end

---Generate a new record
M.generate_record = function()
  generator_base(false, function(info)
    local write_content =
      string.format(utils.record_boiler_plate, info.package_name, info.filename)
    generator_write(info.path, write_content)
  end)
end

---Generate a new interface
M.generate_interface = function()
  generator_base(false, function(info)
    local write_content = string.format(
      utils.interface_boiler_plate,
      info.package_name,
      info.filename
    )
    generator_write(info.path, write_content)
  end)
end

---Generate a new enum
M.generate_enum = function()
  generator_base(false, function(info)
    local write_content =
      string.format(utils.enum_boiler_plate, info.package_name, info.filename)
    generator_write(info.path, write_content)
  end)
end

return M
