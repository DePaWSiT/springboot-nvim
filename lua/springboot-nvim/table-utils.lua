local M = {}

M.contains = function(tbl, element)
  for _, value in pairs(tbl) do
    if value == element then
      return true
    end
  end
  return false
end

M.list_to_string = function(tbl, is_err)
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

return M
