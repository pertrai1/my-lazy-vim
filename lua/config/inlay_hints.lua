local M = {}

function M.valid_position(hint, lines)
  local position = hint and hint.position
  if type(position) ~= "table" then
    return false
  end

  local line = position.line
  local character = position.character
  if
    type(line) ~= "number"
    or line % 1 ~= 0
    or line < 0
    or type(character) ~= "number"
    or character % 1 ~= 0
    or character < 0
  then
    return false
  end

  local text = lines[line + 1]
  return text ~= nil and character <= #text
end

function M.filter_invalid_positions(result, lines)
  return vim.tbl_filter(function(hint)
    return M.valid_position(hint, lines)
  end, result)
end

return M
