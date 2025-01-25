local ncmp = {}
local state = require("llm.state")
local LOG = require("llm.common.log")
local utils = require("llm.common.completion.utils")
local cmp = require("cmp")
local lsp = require("cmp.types.lsp")

function ncmp.get_trigger_characters()
  return { "@", ".", "(", "[", ":", " " }
end

function ncmp.get_keyword_pattern()
  -- NOTE: Don't trigger the completion by any keywords (use a pattern that
  -- is not likely to be triggered.). only trigger on the given characters.
  -- This is because candidates returned by LLMs are easily filtered out by
  -- cmp due to that LLM oftern returns candidates contains the full content
  -- in current line before the cursor.
  return "^$"
end

function ncmp:new()
  local source = setmetatable({}, { __index = ncmp })
  return source
end

function ncmp:complete(ctx, callback)
  -- we want to always invoke completion when invoked manually
  if not self.opts.auto_trigger and ctx.context.option.reason ~= "manual" then
    callback()
    return
  end

  local function _complete()
    LOG:TRACE("cmp complete")
    local context = utils.get_context(ctx.context, self.opts)

    if self.opts.fim then
      self.opts.prompt = context.lines_before
      self.opts.suffix = context.lines_after
    end
    self.opts.exit_handler = function(data)
      if not data then
        callback()
        return
      end

      local items = {}
      for _, result in ipairs(data) do
        table.insert(items, {
          label = result,
          documentation = {
            kind = cmp.lsp.MarkupKind.Markdown,
            value = "```" .. (vim.bo.ft or "") .. "\n" .. result .. "\n```",
          },
          insertTextMode = lsp.InsertTextMode.AdjustIndentation,
          cmp = {
            kind_hl_group = "CmpItemKindMinuet",
            kind_text = "llm",
          },
        })
      end
      callback({
        items = items,
      })
    end
    state.completion.backend.request(self.opts)
  end

  -- manual mode always complete immediately without debounce or throttle
  if ctx.context.option.reason == "manual" then
    _complete()
    return
  end

  _complete()
end

return ncmp
