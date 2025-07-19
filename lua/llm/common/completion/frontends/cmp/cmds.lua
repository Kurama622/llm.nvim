local cmp_cmds = { name = "cmp_cmds" }
local state = require("llm.state")
local LOG = require("llm.common.log")
local cmp = require("cmp")
local lsp = require("cmp.types.lsp")
local F = require("llm.common.api")

function cmp_cmds:is_available()
  return vim.bo.filetype == "llm"
end

function cmp_cmds:get_trigger_characters()
  return { "@" }
end

function cmp_cmds:get_keyword_pattern()
  return "^$"
end

---Execute selected item
---@param item table The selected item from the completion menu
---@param callback function
---@return nil
function cmp_cmds:execute(item, callback)
  if item.cmp.kind_text == "llm.cmds" then
    table.insert(
      state.enabled_cmds,
      F.table_filter(function(key, _)
        return key == "label" or key == "kind_name" or key == "callback"
      end, item)
    )
  end
  callback(item)
end

function cmp_cmds.new()
  return setmetatable({}, { __index = cmp_cmds })
end

function cmp_cmds:complete(ctx, callback)
  local items = require("llm.common.cmds")

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
      kind_text = "llm.cmds",
    }

    return item
  end)

  callback({
    items = items,
    isIncomplete = false,
  })
end

return cmp_cmds
