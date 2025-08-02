-- referenced from minuet-ai.nvim: https://github.com/milanglacier/minuet-ai.nvim
local ncmp = { name = "cmp" }
local state = require("llm.state")
local LOG = require("llm.common.log")
local utils = require("llm.common.completion.utils")
local cmp = require("cmp")
local lsp = require("cmp.types.lsp")

function ncmp.get_trigger_characters()
  return { "@", ".", "(", "[", ":", "{", " " }
end

function ncmp:is_available()
  return self.opts.filetypes[vim.bo.filetype] ~= false
end

function ncmp:new()
  function ncmp.get_keyword_pattern()
    -- NOTE: Don't trigger the completion by any keywords (use a pattern that
    -- is not likely to be triggered.). only trigger on the given characters.
    -- This is because candidates returned by LLMs are easily filtered out by
    -- cmp due to that LLM oftern returns candidates contains the full content
    -- in current line before the cursor.
    if self.opts.only_trigger_by_keywords then
      return "^$"
    end
  end

  local source = setmetatable({}, { __index = self })
  source.is_in_throttle = nil
  source.debounce_timer = nil
  return source
end

function ncmp:keymap()
  if state.completion.set_keymap then
    return
  end
  local callbacks = {
    toggle = function()
      state.completion.enable = not state.completion.enable
      if state.completion.enable then
        LOG:INFO("Enable llm.nvim completion.")
      else
        LOG:INFO("Disable llm.nvim completion.")
      end
    end,
  }
  for name, km in pairs(self.opts.keymap) do
    -- "virtual_text" is not needed
    if name ~= "virtual_text" then
      vim.api.nvim_set_keymap(km.mode, km.keys, "", {
        callback = callbacks[name],
        noremap = true,
        silent = true,
      })
    end
  end
  state.completion.set_keymap = true
end

function ncmp:complete(ctx, callback)
  -- we want to always invoke completion when invoked manually
  if (not state.completion.enable) or (not self.opts.auto_trigger and ctx.context.option.reason ~= "manual") then
    callback()
    return
  end

  local function _complete()
    if self.opts.throttle > 0 then
      self.is_in_throttle = true
      vim.defer_fn(function()
        self.is_in_throttle = nil
      end, self.opts.throttle)
    end

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
        local line_entry = vim.split(result, "\n")
        local item_label = nil
        for _, line in ipairs(line_entry) do
          line = utils.remove_spaces(line)
          if line and line ~= "" then
            item_label = line
            break
          end
        end
        if not item_label then
          return
        end
        table.insert(items, {
          label = item_label,
          documentation = {
            kind = cmp.lsp.MarkupKind.Markdown,
            value = "```" .. (vim.bo.ft or "") .. "\n" .. result .. "\n```",
          },
          insertTextMode = lsp.InsertTextMode.AdjustIndentation,
          insertText = result,
          -- use PlainText to ensure proper indentation.
          insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
          cmp = {
            kind_hl_group = "CmpItemKind",
            kind_text = "llm",
          },
        })
      end
      if not vim.tbl_isempty(items) then
        callback({
          items = items,
        })
      end
    end
    state.completion.backend.request(self.opts)
  end

  -- manual mode always complete immediately without debounce or throttle
  if ctx.context.option.reason == "manual" then
    _complete()
    return
  end

  if self.opts.throttle > 0 and self.is_in_throttle then
    callback()
    return
  end

  if self.opts.debounce > 0 then
    if self.debounce_timer and not self.debounce_timer:is_closing() then
      self.debounce_timer:stop()
      self.debounce_timer:close()
    end
    self.debounce_timer = vim.defer_fn(_complete, self.opts.debounce)
  else
    _complete()
  end
end

return ncmp
