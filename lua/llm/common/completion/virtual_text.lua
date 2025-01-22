local state = require("llm.state")
local LOG = require("llm.common.log")

local virtual_text = {
  rendered = false,
  choice = nil,
  ns_id = vim.api.nvim_create_namespace("llm.virtualtext"),
  extmark_id = 1,
}

function virtual_text:clear()
  if self.rendered then
    self.rendered = false
    vim.api.nvim_buf_del_extmark(0, self.ns_id, self.extmark_id)
  end
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
    self.rendered = true
  end
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
  local ctrl_o = vim.api.nvim_replace_termcodes("<C-o>", true, false, true)
  local down_key = vim.api.nvim_replace_termcodes("<down>", true, false, true)

  vim.schedule_wrap(function()
    vim.api.nvim_buf_set_text(0, line, col, line, col, self.display_lines)
    if #self.display_lines == 1 then
      -- move to eol. \15 is Ctrl-o
      vim.api.nvim_feedkeys(ctrl_o .. "$", "n", false)
    else
      -- move cursor to the end of inserted text
      vim.api.nvim_feedkeys(string.rep(down_key, #self.display_lines - 1), "n", false)
      vim.api.nvim_feedkeys(ctrl_o .. "$", "n", false)
    end
  end)()
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
