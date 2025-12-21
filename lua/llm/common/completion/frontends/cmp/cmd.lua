local cmp_cmd = { name = "cmp_cmd" }
local state = require("llm.state")
local LOG = require("llm.common.log")
local cmp = require("cmp")
local lsp = require("cmp.types.lsp")
local F = require("llm.common.api")

function cmp_cmd:is_available()
  return vim.bo.filetype == "llm"
end

function cmp_cmd:get_trigger_characters()
  return { "@" }
end

function cmp_cmd:get_keyword_pattern()
  return "^$"
end

---Execute selected item
---@param item table The selected item from the completion menu
---@param callback function
---@return nil
function cmp_cmd:execute(item, callback)
  if item.cmp.kind_text == "llm.cmd" then
    table.insert(
      state.enabled_cmds,
      F.table_filter(function(key, _)
        return key == "label" or key == "kind_name" or key == "callback"
      end, item)
    )
  end
  callback(item)
end

function cmp_cmd.new()
  return setmetatable({}, { __index = cmp_cmd })
end

function cmp_cmd:complete(ctx, callback)
  local items = require("llm.common.cmd")

  vim.iter(items):map(function(item)
    item.documentation = {
      kind = cmp.lsp.MarkupKind.PlainText,
      value = item.detail,
    }
    item.insertTextMode = lsp.InsertTextMode.AdjustIndentation
    item.insertText = item.label
    item.insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText
    item.cmp = {
      kind_hl_group = "CmpItemKind",
      kind_text = "llm.cmd",
    }

    return item
  end)

  callback({
    items = items,
    isIncomplete = false,
  })
end

return cmp_cmd
