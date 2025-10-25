---@class Table_Utils
local M = {}

---Whether an element is present in a given table
---@generic T
---@param tbl table<any, T> The table to look through
---@param element T The element to be searched for
---@return boolean present Whether the element is present in the table or not
M.contains = function(tbl, element)
  for _, value in pairs(tbl) do
    if value == element then
      return true
    end
  end
  return false
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
