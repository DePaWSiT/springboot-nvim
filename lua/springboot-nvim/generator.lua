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

  --pretty nice that be default the folder name matches the language used, only 3 possible folders
  local language_path
  for _, name in ipairs(utils.spring_languages) do
    language_path = vim.fs.find(name, {
      path = path_to_main,
      type = "directory",
      limit = 1,
    })[1] or nil
  end
  if language_path == nil then
    vim.notify(
      "language folder after src could not be found",
      vim.log.levels.ERROR
    )
    return
  end

  --TODO: what to do when this returns an empty table? use project root? idk
  --TODO: add manual-override option for package-path where the user can manually insert a package path for where to place the file another vim.ui.input...
  local subdirs = utils.get_relative_subdirectories(language_path)

  --thought of making this without asking for package name but then where to place file???
  --ask for filename
  vim.ui.input({ prompt = "Enter filename.ext: " }, function(filename)
    if filename == nil or filename == "" then
      vim.notify("No filename was given", vim.log.levels.WARN)
      return
    end
    --ask package
    vim.ui.select(subdirs, {
      prompt = "Select location: ",
    }, function(package_path)
      --no package name given
      if package_path == nil then
        vim.notify("No location given", vim.log.levels.WARN)
        return
      end

      local package_name = string.gsub(package_path, "/", ".")

      --construct direct filepath with data provided
      local filepath = vim.fs.joinpath(language_path, package_path, filename)
      --for searching, windows doesn't really care if you use / or \ but to make it easier to have them all the same
      filepath = string.gsub(filepath, "\\", "/")

      local can_create = check_file_creation(filepath)
      if not can_create then
        vim.notify("File already exists", vim.log.levels.WARN)
        return
      end

      --pass relevant information back in callback form
      callback({
        filename = filename,
        package_name = package_name,
        filepath = filepath,
      })
      --no more searching required so break
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
