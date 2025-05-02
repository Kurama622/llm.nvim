local utils = {}
local state = require("llm.state")
local F = require("llm.common.api")

function utils.add_think_mark(ctx)
  if not state.think_mark.created then
    ctx.assistant_output = ctx.assistant_output .. "\n> [!NOTE]\n>"
    F.WriteContent(ctx.bufnr, ctx.winid, "\n> [!NOTE]\n>")
    state.think_mark.created = true
  end
end

function utils.format_think(content)
  return string.gsub(content, ".", {
    ["\n"] = "\n> ",
  })
end

return utils
