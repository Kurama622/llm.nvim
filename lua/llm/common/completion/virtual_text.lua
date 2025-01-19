local state = require("llm.state")
local LOG = require("llm.common.log")

local virtual_text = {
  rendered = false,
  choice = nil,
  ns_id = vim.api.nvim_create_namespace("llm.virtualtext"),
  extmark_id = 1,
}

function virtual_text:clear()
  self.rendered = false
  vim.api.nvim_buf_del_extmark(0, self.ns_id, self.extmark_id)
end

function virtual_text:update_preview()
  self:clear()
  if state.completion.contents[self.choice] then
    self.display_lines = vim.split(state.completion.contents[self.choice], "\n", { plain = true })
    local extmark = {
      id = self.extmark_id,
      virt_text = { { self.display_lines[1], "Comment" } },
      virt_text_pos = "inline",
    }
    if #self.display_lines > 1 then
      extmark.virt_lines = {}
      for i = 2, #self.display_lines do
        extmark.virt_lines[i - 1] = { { self.display_lines[i], "Comment" } }
      end
    end
    self.cursor_col = vim.fn.col(".")
    self.cursor_line = vim.fn.line(".")
    vim.api.nvim_buf_set_extmark(0, self.ns_id, self.cursor_line - 1, self.cursor_col - 1, extmark)
  end
  self.rendered = true
end

function virtual_text:preview()
  if not self.choice then
    for i, v in pairs(state.completion.contents) do
      if v ~= "" then
        self.choice = i
        break
      end
    end
  end

  if not self.rendered then
    self:update_preview()
  end
end

function virtual_text:accept()
  self:clear()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line, col = cursor[1] - 1, cursor[2]
  vim.api.nvim_buf_set_text(0, line, col, line, col, self.display_lines)
  vim.api.nvim_command("doautocmd CompleteDone")
end

function virtual_text:next()
  if #state.completion.contents > 1 then
    self.choice = (self.choice + 1) % #state.completion.contents
    self:update_preview()
  end
end

function virtual_text:prev()
  if #state.completion.contents > 1 then
    self.choice = (self.choice - 1) % #state.completion.contents
    self:update_preview()
  end
end
return virtual_text
