local cmp_buffer = { name = "cmp_buffer" }
local state = require("llm.state")
local cmp = require("cmp")
local lsp = require("cmp.types.lsp")
local F = require("llm.common.api")

function cmp_buffer:is_available()
  return vim.bo.filetype == "llm"
end
function cmp_buffer:get_trigger_characters()
  return { "/" }
end

function cmp_buffer:get_keyword_pattern()
  return [=[/\zs[^/\\:\*?<>'"`\|]*]=]
end

---Execute selected item
---@param item table The selected item from the completion menu
---@param callback function
---@return nil
function cmp_buffer:execute(item, callback)
  if item.cmp.kind_text == "llm.buffer" then
    item:picker(function(quote_buf_list)
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
        item.insertText = new_text
      end
      if F.IsValid(new_text) then
        item._textEdit.newText = new_text
        vim.api.nvim_buf_set_text(
          item.bufnr,
          item._textEdit.range.start.line,
          item._textEdit.range.start.character - 1,
          item._textEdit.range["end"].line,
          item._textEdit.range["end"].character,
          { item._textEdit.newText }
        )

        vim.api.nvim_feedkeys("A", "n", false)
      end
    end)
  end
  callback()
end

function cmp_buffer.new()
  return setmetatable({}, { __index = cmp_buffer })
end

function cmp_buffer:complete(ctx, callback)
  local items = require("llm.common.buffers")

  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local bufnr = vim.api.nvim_get_current_buf()
  vim.iter(items):map(function(item)
    item._textEdit = {
      newText = "buffer",
      range = {
        ["start"] = { line = row - 1, character = col },
        ["end"] = { line = row - 1, character = col + vim.api.nvim_strwidth(item.label) },
      },
    }
    item.documentation = {
      kind = cmp.lsp.MarkupKind.PlainText,
      value = item.detail,
    }
    item.bufnr = bufnr
    item.insertTextMode = lsp.InsertTextMode.AdjustIndentation
    item.insertText = item.label
    item.insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText
    item.cmp = {
      kind_hl_group = "CmpItemKind",
      kind_text = "llm.buffer",
    }

    return item
  end)

  callback({
    items = items,
    isIncomplete = false,
  })
end

return cmp_buffer
