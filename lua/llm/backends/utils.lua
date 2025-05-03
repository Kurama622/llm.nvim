local utils = {}
local state = require("llm.state")
local F = require("llm.common.api")

function utils.mark_reason_begin(ctx)
  if not state.reason_range.is_begin then
    ctx.reasoning_content = ctx.reasoning_content .. "\n> [!NOTE] reason\n"
    F.WriteContent(ctx.bufnr, ctx.winid, "\n> [!NOTE] reason\n")
    state.reason_range.is_begin = true
  end
end

function utils.mark_reason_end(ctx)
  if state.reason_range.is_begin and not state.reason_range.is_end then
    ctx.reasoning_content = ctx.reasoning_content .. "\n> [!NOTE] reason\n"
    F.WriteContent(ctx.bufnr, ctx.winid, "\n> [!NOTE] reason\n")
    state.reason_range.is_end = true
  end
end

-- TODO: useless
function utils.format_reason(content)
  return string.gsub(content, ".", {
    ["\n"] = "\n> ",
  })
end

return utils
