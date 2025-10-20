---@class Table_Utils
local M = {}

---Whether an element is present in a given table
---@param tbl table<any> The table to look through
---@param element any The element to be searched for
---@return boolean present Whether the element is present in the table or not
M.contains = function(tbl, element)
  for _, value in pairs(tbl) do
    if value == element then
      return true
    end
  end
  return false
end

function M.list_to_string(tbl, is_err)
  local result = ""

  for i, value in ipairs(tbl) do
    if is_err then
      result = result .. "'" .. tostring(value) .. "'"
    else
      result = result .. tostring(value)
    end
    if i < #tbl then
      if is_err then
        result = result .. " or "
      else
        result = result .. "/"
      end
    end
  end
  return result
end

---Asks the user to pick one option from a table
---@generic T
---@param tbl T[] The table where the user can select from
---@param menu_text string The text displayed at the top
---@return any|nil value The selected value (same type as the table) or nil if out of bounds was selected
function M.table_to_inputlist(tbl, menu_text)
  if next(tbl) == nil then
    vim.notify("Table passed for inputlist is empty", vim.log.levels.ERROR)
    return
  end

  menu_text = menu_text or "Choose an option: "
  local menu = { menu_text }

  for i, option in ipairs(tbl) do
    table.insert(menu, string.format("%d. %s", i, option))
  end

  local choice = vim.fn.inputlist(menu)

  if choice >= 1 and choice <= #tbl then
    return tbl[choice]
  else
    return nil
  end
end

--- Removes the first matching value from a table (array-style)
function M.table_pop_value(tbl, item)
  for i, v in ipairs(tbl) do
    if v == item then
      table.remove(tbl, i)
      return v
    end
  end
  return nil -- not found
end
return M
