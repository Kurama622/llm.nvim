local LOG = require("llm.common.log")
local F = require("llm.common.api")
local utils = {}

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

function utils.single_turn_dialogue(
  preview_box,
  state,
  name,
  streaming,
  fetch_key,
  options,
  start_str,
  end_str,
  context,
  diff
)
  if preview_box then
    F.AppendChunkToBuffer(preview_box.bufnr, preview_box.winid, "-----\n")
  end

  return streaming(
    preview_box.bufnr,
    preview_box.winid,
    state.app.session[name],
    fetch_key,
    options.url,
    options.model,
    options.api_type,
    options.args,
    options.streaming_handler,
    options.stdout_handler,
    options.stderr_handler,
    function(ostr)
      local pattern = string.format("%s%%w*\n(.-)\n%s", start_str, end_str)
      local res = {}
      for match in ostr:gmatch(pattern) do
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
  )
end
return utils
