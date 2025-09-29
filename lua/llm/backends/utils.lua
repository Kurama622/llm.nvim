local LOG = require("llm.common.log")
local utils = {}
local state = require("llm.state")
local F = require("llm.common.api")

function utils.mark_reason_begin(ctx, append_line_break)
  if not state.reason_range.is_begin then
    ctx.reasoning_content = ctx.reasoning_content .. "\n> [!NOTE] reason\n"
    F.WriteContent(ctx.bufnr, ctx.winid, "\n> [!NOTE] reason\n")
    if append_line_break then
      ctx.reasoning_content = ctx.reasoning_content .. "\n"
      F.WriteContent(ctx.bufnr, ctx.winid, "\n")
    end
    state.reason_range.is_begin = true
  end
end

function utils.mark_reason_end(ctx, append_line_break)
  if state.reason_range.is_begin and not state.reason_range.is_end then
    ctx.reasoning_content = ctx.reasoning_content .. "\n> [!NOTE] reason\n"
    F.WriteContent(ctx.bufnr, ctx.winid, "\n> [!NOTE] reason\n")
    if append_line_break then
      ctx.reasoning_content = ctx.reasoning_content .. "\n"
      F.WriteContent(ctx.bufnr, ctx.winid, "\n")
    end
    state.reason_range.is_end = true
  end
end

-- TODO: useless
function utils.format_reason(content)
  return string.gsub(content, ".", {
    ["\n"] = "\n> ",
  })
end

local function trim(str)
  return str:match("^%s*(.-)%s*$")
end

local function remove_braces(str)
  return str:sub(2, #str - 1)
end

local function remove_quote(str)
  local i, j = 1, #str
  while str:sub(i, i) ~= '"' and i < #str do
    i = i + 1
  end

  str = str:sub(1, i - 1) .. str:sub(i + 1)
  while str:sub(j, j) ~= '"' and j > 1 do
    j = j - 1
  end
  return str:sub(1, j - 1) .. str:sub(j + 1)
end

local function serialization(val)
  local left_space = 1
  while val:sub(left_space, left_space) == " " do
    left_space = left_space + 1
  end

  local right_space = #val
  while val:sub(right_space, right_space) == " " do
    right_space = right_space - 1
  end

  return val:sub(1, left_space - 1) .. vim.json.encode(val:sub(left_space, right_space)) .. val:sub(right_space + 1)
end

local function get_item_value(s)
  local cnt = 0
  local len = #s
  local j = len

  if s:sub(j, j) ~= '"' then
    return "", s
  end

  while cnt < 2 do
    local c = s:sub(j, j)
    if c == '"' then
      cnt = cnt + 1
    end
    if j < 1 then
      return "", s
    end
    j = j - 1
  end

  while s:sub(j, j) ~= '"' and j > 0 do
    j = j - 1
  end

  return serialization(remove_quote(s:sub(1, j))), s:sub(j + 1)
end

function utils.format_json_str(str)
  str = remove_braces(trim(str))
  local list = {}
  for token in string.gmatch(str, "([^:]+)") do
    table.insert(list, token)
  end

  local res = "{"
  local num = #list
  local remainer = ""
  for i = 1, num do
    if i == 1 then
      res = res .. list[i] .. ":"
    elseif i == num then
      local s = remove_quote(remainer .. list[i])
      res = res .. serialization(s)
      remainer = ""
    else
      local value, key = get_item_value(remainer .. list[i])
      remainer = ""
      if value ~= "" then
        res = res .. value .. key .. ":"
      else
        remainer = remainer .. key .. ":"
      end
    end
  end
  res = res .. "}"

  return F.pcall(vim.json.decode, res, "{}")
end

function utils.decode_escaped_string(s)
  if not F.IsValid(s) then
    return nil
  end
  return (
    s:gsub("\\(.)", function(c)
      if c == "n" then
        return "\n"
      elseif c == "r" then
        return "\r"
      elseif c == "t" then
        return "\t"
      elseif c == "\\" then
        return "\\"
      else
        return c
      end
    end)
  )
end
return utils
