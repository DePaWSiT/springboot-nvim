local utils = require("springboot-nvim.utils")
local api = vim.api
local start_buf

local windows
local bufs

local M = {}

M.generate_class = function()
  local file_path = vim.fn.fnamemodify(start_buf, ":p")
  -- Search the LAST occurrence of "/java/" in file_path
  local last_java_idx = nil
  local search_start = 1
  while true do
    local start_idx, end_idx = file_path:find("/java/", search_start)
    if not end_idx then
      break
    end
    last_java_idx = end_idx
    search_start = start_idx + 1
  end

  if not last_java_idx then
    -- Error to the console and abort
    vim.notify("Could not find /java/ folder in path", vim.log.levels.ERROR)
    return
  end
  -- root_path will be like "/.../src/main/java"
  local root_path = file_path:sub(1, last_java_idx - 1)
  -- Make sure there is content in the class buffer
  local class_lines = api.nvim_buf_get_lines(bufs[4], 0, -1, false)
  local class_content = table.concat(class_lines)
  local package_lines = api.nvim_buf_get_lines(bufs[3], 0, -1, false)
  local base_package_path = table.concat(package_lines)
  local package_path = base_package_path:gsub("%.", "/")
  if package_path:sub(-1, -1) ~= "/" and package_path ~= "" then
    package_path = package_path .. "/"
  end

  if class_content == "" then
    vim.notify("Cannot find name for the class", vim.log.levels.WARN)
    return
  end

  -- Check the specified package directory to make sure it exists
  if vim.fn.isdirectory(root_path .. "/" .. package_path) == 1 then
    vim.notify("Package directory exists", vim.log.levels.INFO)
  else
    -- Make the package directory if it does not exist
    local command = "mkdir -p " .. root_path .. "/" .. package_path
    os.execute(command)
  end
  -- Generate the new java file and inject boiler plate
  -- Need to strip and trailing periods from the package
  if base_package_path:sub(-1, -1) == "." then
    base_package_path = string.sub(base_package_path, 1, -2)
  end
  local java_file_content =
    string.format(utils.class_boiler_plate, base_package_path, class_content)
  local java_file =
    io.open(root_path .. "/" .. package_path .. class_content .. ".java", "r")
  if java_file then
    vim.notify("Class already exists in package", vim.log.levels.INFO)
    java_file:close()
  else
    java_file =
      io.open(root_path .. "/" .. package_path .. class_content .. ".java", "w")
    if java_file then
      java_file:write(java_file_content)
      java_file:close()
      M.close_generate_class()
      local path = root_path .. "/" .. package_path .. class_content .. ".java"
      vim.cmd("edit " .. vim.fn.fnameescape(path))
    end
  end
end

---@class bufReturn
---@field package_bufnr integer
---@field window_bufnr integer

---Creates the package ui, ui for managing packages???
---@param row integer
---@param col integer
---@param width integer
---@param height integer
---@param file_path any
---@return bufReturn table: {package_bufnr : integer, window_bufnr : integer}
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
  local package = M.package_text(file_path)
  api.nvim_buf_set_lines(package_buf, 0, -1, false, { package })
  local package_win = api.nvim_open_win(package_buf, true, opts)

  table.insert(windows, package_win)
  table.insert(bufs, package_buf)
  return {
    package_bufnr = package_buf,
    window_bufnr = package_win,
  }
end

---Creates a ui for something...
---@param bufnr string|integer The name or the number of the buffer
M.create_ui = function(bufnr)
  -- Get the file from where the generate class was called from
  start_buf = vim.fn.bufname(bufnr)
  local file_path = vim.fn.fnamemodify(start_buf, ":p")
  local project_root = M.get_spring_boot_project_root(file_path)
  local main_class_dir = M.find_main_application_class_directory(project_root)
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

  local outline = M.draw_border(width, height)
  api.nvim_buf_set_lines(border_buf, 0, -1, false, outline)

  local border_win = api.nvim_open_win(border_buf, true, border_opts)
  table.insert(windows, border_win)
  local win = api.nvim_open_win(buf, true, opts)
  table.insert(windows, win)
  --api.nvim_command('au BufWipeout <buffer> exe "silent bdelete! "' ..border_buf)

  --api.nvim_win_set_option(win, 'cursorline', true)

  api.nvim_buf_set_lines(buf, 0, -1, false, { M.center_text("Generate Class") })
  local package_section = M.draw_package_section()
  api.nvim_buf_set_lines(buf, 1, -1, false, package_section)
  local class_section = M.draw_class_section()
  api.nvim_buf_set_lines(buf, 5, -1, false, class_section)
  api.nvim_buf_set_lines(
    buf,
    8,
    -1,
    false,
    { M.center_text("Confirm selections with <Enter>") }
  )
  local package_area =
    M.create_package_ui(row + 2, col + 10, 48, 1, main_class_dir)
  api.nvim_set_current_win(package_area.window_bufnr)
  local first_line = vim.fn.getline(1, 1)
  local first_line_length = string.len(first_line[1])
  --api.nvim_feedkeys('a', 'n', true)
  api.nvim_win_set_cursor(package_area.window_bufnr, { 1, first_line_length })
end

return M
