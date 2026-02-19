-- referenced from minuet-ai.nvim: https://github.com/milanglacier/minuet-ai.nvim
local state = require("llm.state")
local LOG = require("llm.common.log")
local utils = require("llm.common.completion.utils")
local uv = vim.uv or vim.loop

local virtual_text = {
  name = "virtual_text",
  rendered = false,
  choice = nil,
  ns_id = vim.api.nvim_create_namespace("llm.virtualtext"),
  extmark_id = 1,
  timer = nil,
  is_on_throttle = false,
  timestamp = 0,
}

function virtual_text:start()
  if self.is_on_throttle then
    return
  end

  self:stop_timer()

  local bufnr = vim.api.nvim_get_current_buf()

  self.timer = vim.defer_fn(function()
    if self.is_on_throttle then
      return
    end

    utils.terminate_all_jobs()
    self.is_on_throttle = true
    vim.defer_fn(function()
      self.is_on_throttle = false
    end, self.opts.throttle)

    self:trigger(bufnr)
  end, self.opts.debounce)
end

function virtual_text:trigger(bufnr)
  if bufnr ~= vim.api.nvim_get_current_buf() or vim.fn.mode() ~= "i" then
    return
  end

  local timestamp = uv.now()
  self.timestamp = timestamp
  local context = utils.get_context(utils.make_cmp_context(), self.opts)
  local language = utils.add_language_comment()
  local tab = utils.add_tab_comment()
  if self.opts.fim then
    self.opts.prompt = language .. "\n" .. tab .. "\n" .. context.lines_before
    self.opts.suffix = context.lines_after
  end

  self:clear()
  self.opts.exit_handler = function()
    if timestamp ~= self.timestamp then
      return
    end
    self:preview()
  end

  if self.opts.prompt or self.opts.suffix then
    state.completion.backend.request(self.opts)
  end
end

function virtual_text:stop_timer()
  if self.timer and not self.timer:is_closing() then
    self.timer:stop()
    self.timer:close()
    self.timer = nil
  end
end
function virtual_text:clear()
  if self.rendered then
    self.rendered = false
    vim.api.nvim_buf_del_extmark(0, self.ns_id, self.extmark_id)
  end
end

function virtual_text:update_preview()
  self:clear()
  if state.completion.contents[self.choice] then
    self.display_lines = vim.split(
      state.completion.contents[self.choice],
      "\n",
      { plain = true }
    )
    local extmark = {
      id = self.extmark_id,
      virt_text = { { self.display_lines[1], "LLMCodeSuggestion" } },
      virt_text_pos = "inline",
    }
    if #self.display_lines > 1 then
      extmark.virt_lines = {}
      for i = 2, #self.display_lines do
        extmark.virt_lines[i - 1] =
          { { self.display_lines[i], "LLMCodeSuggestion" } }
      end
    end
    self.cursor_col = vim.fn.col(".")
    self.cursor_line = vim.fn.line(".")
    vim.api.nvim_buf_set_extmark(
      0,
      self.ns_id,
      self.cursor_line - 1,
      self.cursor_col - 1,
      extmark
    )
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
      vim.api.nvim_feedkeys(
        string.rep(down_key, #self.display_lines - 1),
        "n",
        false
      )
      vim.api.nvim_feedkeys(ctrl_o .. "$", "n", false)
    end
  end)()
  vim.api.nvim_command("doautocmd CompleteDone")
end

function virtual_text:next()
  if #state.completion.contents > 1 then
    self.choice = (self.choice + 1) % (#state.completion.contents + 1)
    self:update_preview()
  end
end

function virtual_text:prev()
  if #state.completion.contents > 1 then
    self.choice = (self.choice - 1) % (#state.completion.contents + 1)
    self:update_preview()
  end
end

function virtual_text:autocmd()
  if state.completion.set_autocmd then
    return
  end
  local virt_group =
    vim.api.nvim_create_augroup("virt_completions", { clear = true })

  vim.api.nvim_create_autocmd("InsertLeavePre", {
    group = virt_group,
    callback = function()
      local cond = self.opts.filetypes[vim.bo.ft] == nil
          and self.opts.default_filetype_enabled
        or self.opts.filetypes[vim.bo.ft]
      if not (state.completion.enable and cond) then
        return
      end
      utils.terminate_all_jobs()
      state.completion.contents = {}
      self:clear()
    end,
  })
  if self.opts.auto_trigger then
    vim.api.nvim_create_autocmd("InsertEnter", {
      group = virt_group,
      callback = function()
        local cond = self.opts.filetypes[vim.bo.ft] == nil
            and self.opts.default_filetype_enabled
          or self.opts.filetypes[vim.bo.ft]
        if not (state.completion.enable and cond) then
          return
        end
        state.completion.contents = {}
        self:start()
      end,
    })
    vim.api.nvim_create_autocmd("TextChangedI", {
      group = virt_group,
      callback = function()
        local cond = self.opts.filetypes[vim.bo.ft] == nil
            and self.opts.default_filetype_enabled
          or self.opts.filetypes[vim.bo.ft]
        if not (state.completion.enable and cond) then
          return
        end
        state.completion.contents = {}
        self:start()
      end,
    })
  end
  vim.api.nvim_create_autocmd("CompleteDone", {
    group = virt_group,
    callback = function()
      local cond = self.opts.filetypes[vim.bo.ft] == nil
          and self.opts.default_filetype_enabled
        or self.opts.filetypes[vim.bo.ft]
      if not (state.completion.enable and cond) then
        return
      end
      utils.terminate_all_jobs()
      self:clear()
    end,
  })
  state.completion.set_autocmd = true
end

function virtual_text:keymap()
  if state.completion.set_keymap then
    return
  end
  local callbacks = {
    accept = function()
      if not state.completion.enable then
        LOG:WARN("Please enable llm.nvim completion.")
        return
      end
      if self.rendered then
        self:accept()
      elseif not self.opts.auto_trigger then
        LOG:TRACE("Manual trigger completion.")
        self:start()
      end
    end,
    next = function()
      self:next()
    end,
    prev = function()
      self:prev()
    end,
    toggle = function()
      state.completion.enable = not state.completion.enable
      if state.completion.enable then
        LOG:INFO("Enable llm.nvim completion.")
      else
        LOG:INFO("Disable llm.nvim completion.")
      end
    end,
  }
  for name, km in pairs(self.opts.keymap.virtual_text) do
    vim.api.nvim_set_keymap(km.mode, km.keys, "", {
      callback = callbacks[name],
      noremap = true,
      silent = true,
    })
  end
  state.completion.set_keymap = true
end
return virtual_text
