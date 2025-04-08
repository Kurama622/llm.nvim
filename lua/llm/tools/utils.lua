local LOG = require("llm.common.log")
local F = require("llm.common.api")
local utils = {}

function utils.parse_suggestion(suggestion, pattern)
  local res = {}
  local linenr = 0
  local pos = 1
  local range_tbl = {}
  while true do
    local s, e, c = string.find(suggestion, pattern, pos)
    if not s then
      break
    end

    table.insert(res, c)
    linenr = linenr + vim.tbl_count(vim.split(string.sub(suggestion, pos, s - 2), "\n"))
    local start_nr = linenr
    linenr = linenr + vim.tbl_count(vim.split(string.sub(suggestion, s, e), "\n"))
    local end_nr = linenr
    table.insert(range_tbl, { start_nr, end_nr })
    pos = e + 2
  end
  return res, range_tbl
end

function utils.get_hunk_idx(range_tbl)
  local cursor_linenr = vim.api.nvim_win_get_cursor(0)[1]
  local idx = 0
  for n, range in ipairs(range_tbl) do
    idx = n
    if cursor_linenr > range[1] and cursor_linenr < range[2] + 1 then
      break
    end
  end
  return idx
end

function utils.set_keymapping(mode, keymaps, callback, bufnr)
  for _, key in pairs(keymaps) do
    vim.api.nvim_buf_set_keymap(bufnr, mode, key, "", { callback = callback })
  end
end

function utils.clear_keymapping(mode, keymaps, bufnr)
  for _, key in pairs(keymaps) do
    vim.keymap.del(mode, key, { buffer = bufnr })
  end
end

function utils.overwrite_selection(context, contents)
  if context.start_col > 0 then
    context.start_col = context.start_col - 1
  end

  vim.api.nvim_buf_set_text(
    context.bufnr,
    context.start_line - 1,
    context.start_col,
    context.end_line - 1,
    context.end_col,
    contents
  )
  vim.api.nvim_win_set_cursor(context.winnr, { context.start_line, context.start_col })
end

function utils.copy_suggestion_code(opts, suggestion)
  local pattern = string.format("%s%%w*\n(.-)\n%s", opts.start_str, opts.end_str)
  local res, range_tbl = utils.parse_suggestion(suggestion, pattern)
  if vim.tbl_isempty(res) then
    LOG:WARN("The code block format is incorrect, please manually copy the generated code.")
  else
    local idx = utils.get_hunk_idx(range_tbl)
    vim.fn.setreg("+", res[idx])
  end
end

function utils.new_diff(diff, opts, context, suggestion)
  local pattern = string.format("%s%%w*\n(.-)\n%s", opts.start_str, opts.end_str)
  local res, range_tbl = utils.parse_suggestion(suggestion, pattern)
  if vim.tbl_isempty(res) then
    LOG:WARN("The code block format is incorrect, please manually copy the generated code.")
  else
    local contents = vim.api.nvim_buf_get_lines(context.bufnr, 0, -1, true)
    local idx = utils.get_hunk_idx(range_tbl)

    utils.overwrite_selection(context, vim.split(res[idx], "\n"))
    setmetatable(diff, {
      __index = diff.new({
        bufnr = context.bufnr,
        cursor_pos = context.cursor_pos,
        filetype = context.filetype,
        contents = contents,
        winnr = context.winnr,
      }),
    })
  end
end

function utils.single_turn_dialogue(preview_box, streaming, options, context, diff)
  if preview_box then
    F.AppendChunkToBuffer(preview_box.bufnr, preview_box.winid, "-----\n")
  end
  options.bufnr = preview_box.bufnr
  options.winid = preview_box.winid
  options.exit_handler = function(ostr)
    utils.new_diff(diff, options, context, ostr)
  end
  return streaming(options)
end
return utils
