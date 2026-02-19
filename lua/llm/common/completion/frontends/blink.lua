-- referenced from minuet-ai.nvim: https://github.com/milanglacier/minuet-ai.nvim
local state = require("llm.state")
local LOG = require("llm.common.log")
local utils = require("llm.common.completion.utils")
local F = require("llm.common.api")

local blink = { name = "blink" }

function blink:clear() end

function blink:autocmd() end

function blink:keymap()
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

function blink.get_trigger_characters()
  return { "@", ".", "(", "[", ":", "{", " ", "/" }
end

function blink.new()
  local source = setmetatable({}, { __index = blink })
  source.is_in_throttle = nil
  source.debounce_timer = nil
  return source
end

function blink:execute(ctx, item, callback, default_implementation)
  if item.kind_name == "llm.cmds" then
    table.insert(
      state.enabled_cmds,
      F.table_filter(function(key, _)
        return key == "label" or key == "kind_name" or key == "callback"
      end, item)
    )
  elseif item.kind_name == "llm.buffer" then
    item.picker(function(quote_buf_list)
      vim.api.nvim_set_current_win(state.input.popup.winid)
      local new_text = ""
      for _, quote_buf in ipairs(quote_buf_list) do
        if F.IsValid(new_text) then
          new_text = new_text .. " buffer(" .. quote_buf .. ")"
        else
          new_text = "buffer(" .. quote_buf .. ")"
        end
      end

      if F.IsValid(new_text) then
        item.textEdit.newText = new_text
        vim.api.nvim_buf_set_text(
          ctx.bufnr,
          item.textEdit.range.start.line,
          item.textEdit.range.start.character - 1,
          item.textEdit.range["end"].line,
          item.textEdit.range["end"].character,
          { item.textEdit.newText }
        )

        vim.api.nvim_feedkeys("A", "n", false)
      else
        default_implementation()
        callback()
      end
    end)

    return
  elseif item.kind_name == "llm.file" then
    item.picker(function(quote_file_list)
      vim.api.nvim_set_current_win(state.input.popup.winid)
      local new_text = ""
      for _, quote_file in ipairs(quote_file_list) do
        if F.IsValid(new_text) then
          new_text = new_text .. " " .. quote_file
        else
          new_text = quote_file
        end
      end

      if F.IsValid(new_text) then
        item.textEdit.newText = new_text
        vim.api.nvim_buf_set_text(
          ctx.bufnr,
          item.textEdit.range.start.line,
          item.textEdit.range.start.character - 1,
          item.textEdit.range["end"].line,
          item.textEdit.range["end"].character,
          { item.textEdit.newText }
        )

        vim.api.nvim_feedkeys("A", "n", false)
      else
        default_implementation()
        callback()
      end
    end)

    return
  end

  default_implementation()
  callback()
end

function blink:get_completions(ctx, callback)
  local trigger_char = ctx.trigger.character
    or ctx.line:sub(ctx.bounds.start_col - 1, ctx.bounds.start_col - 1)

  if vim.bo.ft == "llm" then
    if trigger_char == "@" then
      local cmds = require("llm.common.cmds")
      callback({
        context = ctx,
        is_incomplete_forward = false,
        is_incomplete_backward = false,
        items = vim
          .iter(cmds)
          :map(function(item)
            return {
              label = item.label,
              documentation = {
                kind = "markdown",
                value = item.detail,
              },
              insertText = item.label,
              insertTextFormat = vim.lsp.protocol.CompletionItemKind.Text,
              kind = vim.lsp.protocol.CompletionItemKind.Text,
              kind_name = "llm.cmds",
              callback = item.callback,
            }
          end)
          :totable(),
      })
    elseif trigger_char == "/" then
      local buffers = require("llm.common.buffers")
      local files = require("llm.common.files")
      callback({
        context = ctx,
        is_incomplete_forward = false,
        is_incomplete_backward = false,
        items = vim
          .iter({ unpack(files), unpack(buffers) })
          :map(function(item)
            return {
              label = item.label,
              documentation = {
                kind = "markdown",
                value = item.detail,
              },
              insertText = item.label,
              insertTextFormat = vim.lsp.protocol.CompletionItemKind.Text,
              kind = vim.lsp.protocol.CompletionItemKind.Text,
              kind_name = item.kind_name,
              picker = function(complete)
                item:picker(complete)
              end,
              callback = item.callback,
            }
          end)
          :totable(),
      })
    end
  end

  if
    not state.completion.enable
    or not vim.tbl_contains(ctx.providers, "llm")
    or self.opts == nil
    or (not self.opts.auto_trigger and ctx.trigger.kind ~= "manual")
  then
    callback()
    return
  end

  local function _complete()
    local cond = self.opts.filetypes[vim.bo.ft] == nil
        and self.opts.default_filetype_enabled
      or self.opts.filetypes[vim.bo.ft]
    if not cond then
      return
    end

    if self.opts.throttle > 0 then
      self.is_in_throttle = true
      vim.defer_fn(function()
        self.is_in_throttle = nil
      end, self.opts.throttle)
    end
    LOG:TRACE("blink.cmp call _complete function.")
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
          filterText = result,
          documentation = {
            kind = "markdown",
            value = "```" .. (vim.bo.ft or "") .. "\n" .. result .. "\n```",
          },
          insertText = result,
          -- use PlainText to ensure proper indentation.
          insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
          -- TODO: use the provider name as kind name like nvim-cmp
          -- when blink supports non-lsp kind name.
          kind = vim.lsp.protocol.CompletionItemKind.Text,
          kind_name = "llm",
          kind_hl = "BlinkCmpItemKind",
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
  if self.opts.throttle > 0 and self.is_in_throttle then
    callback()
    return
  end

  if self.opts.debounce > 0 then
    if self.debounce_timer and not self.debounce_timer:is_closing() then
      self.debounce_timer:close()
    end
    self.debounce_timer = vim.defer_fn(_complete, self.opts.debounce)
  else
    _complete()
  end
end

return blink
