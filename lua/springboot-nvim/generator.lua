---@type Utils
local utils = require("springboot-nvim.utils")
---@type Ui_Utils
local ui_utils = require("springboot-nvim.ui.ui_utils")
local api = vim.api

local windows
local bufs

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
  -- local file_path = vim.fn.fnamemodify(start_buf, ":p")
  -- -- Search the LAST occurrence of "/java/" in file_path
  -- local last_java_idx = nil
  -- local search_start = 1
  -- while true do
  --   local start_idx, end_idx = file_path:find("/java/", search_start)
  --   if not end_idx then
  --     break
  --   end
  --   last_java_idx = end_idx
  --   search_start = start_idx + 1
  -- end
  --
  -- if not last_java_idx then
  --   vim.notify("Could not find /java/ folder in path", vim.log.levels.ERROR)
  --   return
  -- end
  -- -- root_path will be like "/.../src/main/java"
  -- local root_path = file_path:sub(1, last_java_idx - 1)
  -- -- Make sure there is content in the class buffer
  -- local class_lines = api.nvim_buf_get_lines(bufs[4], 0, -1, false)
  -- local class_content = table.concat(class_lines)
  -- local package_lines = api.nvim_buf_get_lines(bufs[3], 0, -1, false)
  -- local base_package_path = table.concat(package_lines)
  -- local package_path = base_package_path:gsub("%.", "/")
  -- if package_path:sub(-1, -1) ~= "/" and package_path ~= "" then
  --   package_path = package_path .. "/"
  -- end
  --
  -- if class_content == "" then
  --   vim.notify("Cannot find name for the class", vim.log.levels.WARN)
  --   return
  -- end
  --
  -- -- Check the specified package directory to make sure it exists
  -- if vim.fn.isdirectory(root_path .. "/" .. package_path) == 1 then
  --   vim.notify("Package directory exists", vim.log.levels.INFO)
  -- else
  --   -- Make the package directory if it does not exist
  --   local command = "mkdir -p " .. root_path .. "/" .. package_path
  --   os.execute(command)
  -- end
  -- -- Generate the new java file and inject boiler plate
  -- -- Need to strip and trailing periods from the package
  -- if base_package_path:sub(-1, -1) == "." then
  --   base_package_path = string.sub(base_package_path, 1, -2)
  -- end
  -- local java_file_content =
  --   string.format(utils.class_boiler_plate, base_package_path, class_content)
  -- local java_file =
  --   io.open(root_path .. "/" .. package_path .. class_content .. ".java", "r")
  -- if java_file then
  --   vim.notify("Class already exists in package", vim.log.levels.INFO)
  --   java_file:close()
  -- else
  --   java_file =
  --     io.open(root_path .. "/" .. package_path .. class_content .. ".java", "w")
  --   if java_file then
  --     java_file:write(java_file_content)
  --     java_file:close()
  --
  --     -- local path = root_path .. "/" .. package_path .. class_content .. ".java"
  --     -- vim.cmd("edit " .. vim.fn.fnameescape(path))
  --   end
  -- end
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

---Creates the package ui, ui for managing packages???
---@param row integer
---@param col integer
---@param width integer
---@param height integer
---@param file_path string
---@return {package_bufn:integer, window_bufn:integer} buffnumbers
M.create_package_ui = function(row, col, width, height, file_path)
  local package_buf = api.nvim_create_buf(false, true)
  --api.nvim_buf_set_option(package_buf, 'bufhidden', 'wipe')
  vim.bo[package_buf].filetype = "springbootnvim"

  local opts = {
    style = "minimal",
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    zindex = 102,
  }
  local package = ui_utils.package_text(file_path)
  api.nvim_buf_set_lines(package_buf, 0, -1, false, { package })
  local package_win = api.nvim_open_win(package_buf, true, opts)

  table.insert(windows, package_win)
  table.insert(bufs, package_buf)
  return {
    package_bufnr = package_buf,
    window_bufnr = package_win,
  }
end

--TODO: Maybe i can use vim.ui to prevent a custom window as i don't know the reason for a custom window

---Creates a ui for something...
M.create_ui = function()
  -- Get the file from where the generate class was called from
  -- local start_buf = vim.fn.bufname(bufnr)
  -- local file_path = vim.fn.fnamemodify(start_buf, ":p")
  -- local project_root = utils.get_spring_boot_project_root()
  local main_class_dir = utils.find_main_application_class_directory()
  windows = {}
  bufs = {}
  -- Create buffer for popup
  local buf = api.nvim_create_buf(false, true)
  table.insert(bufs, buf)
  vim.bo[buf].bufhidden = "wipe"
  local border_buf = api.nvim_create_buf(false, true)
  table.insert(bufs, border_buf)
  --api.nvim_buf_set_option(border_buf, 'bufhidden', 'wipe')

  local width = 60
  local height = 8

  local row = math.floor((vim.fn.winheight(0) - height) / 2)
  local col = math.floor((vim.fn.winwidth(0) - width) / 2)

  local border_opts = {
    style = "minimal",
    relative = "editor",
    width = width + 2,
    height = height + 2,
    row = row - 1,
    col = col - 1,
    zindex = 99,
  }

  local opts = {
    style = "minimal",
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    zindex = 100,
  }

  local outline = ui_utils.draw_border(width, height)
  api.nvim_buf_set_lines(border_buf, 0, -1, false, outline)

  local border_win = api.nvim_open_win(border_buf, true, border_opts)
  table.insert(windows, border_win)
  local win = api.nvim_open_win(buf, true, opts)
  table.insert(windows, win)
  --api.nvim_command('au BufWipeout <buffer> exe "silent bdelete! "' ..border_buf)

  --api.nvim_win_set_option(win, 'cursorline', true)

  api.nvim_buf_set_lines(
    buf,
    0,
    -1,
    false,
    { ui_utils.center_text("Generate Class", width) }
  )
  -- local package_section = M.draw_package_section()
  -- api.nvim_buf_set_lines(buf, 1, -1, false, package_section)
  -- local class_section = M.draw_class_section()
  -- api.nvim_buf_set_lines(buf, 5, -1, false, class_section)
  api.nvim_buf_set_lines(
    buf,
    8,
    -1,
    false,
    { ui_utils.center_text("Confirm selections with <Enter>", width) }
  )
  if main_class_dir == nil then
    vim.notify(
      "Directory of the main class could not be found",
      vim.log.levels.ERROR
    )
    return
  end
  local package_area =
    M.create_package_ui(row + 2, col + 10, 48, 1, main_class_dir)
  api.nvim_set_current_win(package_area.window_bufnr)
  local first_line = vim.fn.getline(1, 1)
  local first_line_length = string.len(first_line[1])
  --api.nvim_feedkeys('a', 'n', true)
  api.nvim_win_set_cursor(package_area.window_bufnr, { 1, first_line_length })
end

return M
