local LOG = require("llm.common.log")
local F = require("llm.common.api")
local utils = {}

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
  local res = {}
  for match in suggestion:gmatch(pattern) do
    for _, value in ipairs(vim.split(match, "\n")) do
      table.insert(res, value)
    end
  end
  if vim.tbl_isempty(res) then
    LOG:WARN("The code block format is incorrect, please manually copy the generated code.")
  else
    vim.fn.setreg("+", table.concat(res, "\n"))
  end
end

function utils.new_diff(diff, opts, context, suggestion)
  local pattern = string.format("%s%%w*\n(.-)\n%s", opts.start_str, opts.end_str)
  local res = {}
  for match in suggestion:gmatch(pattern) do
    for _, value in ipairs(vim.split(match, "\n")) do
      table.insert(res, value)
    end
  end
  if vim.tbl_isempty(res) then
    LOG:WARN("The code block format is incorrect, please manually copy the generated code.")
  else
    local contents = vim.api.nvim_buf_get_lines(context.bufnr, 0, -1, true)

    utils.overwrite_selection(context, res)
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
