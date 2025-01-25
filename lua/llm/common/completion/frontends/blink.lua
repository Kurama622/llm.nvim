local state = require("llm.state")
local LOG = require("llm.common.log")
local utils = require("llm.common.completion.utils")

local blink = {}

function blink:clear() end

function blink.get_trigger_characters()
  return { "@", ".", "(", "[", ":", "{" }
end

function blink.new()
  local source = setmetatable({}, { __index = blink })
  return source
end

function blink:get_completions(ctx, callback)
  if not self.opts.auto_trigger and ctx.trigger.kind ~= "manual" then
    callback()
    return
  end

  local function _complete()
    local context = utils.get_context(utils.make_cmp_context(ctx), self.opts)

    if self.opts.fim then
      self.opts.prompt = context.lines_before
      self.opts.suffix = context.lines_after
    end
    self.opts.exit_handler = function(data)
      data = vim.tbl_map(function(item)
        return utils.prepend_to_complete_word(item, context.lines_before)
      end, data)

      local items = {}
      for _, result in ipairs(data) do
        local line_entry = vim.split(result, "\n")
        local item_label
        for _, line in ipairs(line_entry) do
          line = utils.remove_spaces(line)
          if line and line ~= "" then
            item_label = line
            LOG:TRACE(item_label)
            break
          end
        end
        table.insert(items, {
          label = item_label,
          documentation = {
            kind = "markdown",
            value = "```" .. (vim.bo.ft or "") .. "\n" .. result .. "\n```",
          },
          insertText = result,
          -- TODO: use the provider name as kind name like nvim-cmp
          -- when blink supports non-lsp kind name.
          kind = vim.lsp.protocol.CompletionItemKind.Text,
        })
      end

      callback({
        is_incomplete_forward = false,
        is_incomplete_backward = false,
        items = items,
      })
    end
    state.completion.backend.request(self.opts)
  end

  if ctx.trigger.kind == "manual" then
    _complete()
    return
  end
  _complete()
end

return blink
