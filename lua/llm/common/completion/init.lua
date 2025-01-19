local LOG = require("llm.common.log")
local utils = require("llm.common.completion.utils")

local completion = {}

function completion:init(opts)
  self.opts = opts
  if self.opts.api_type == "ollama" then
    self.provider = require("llm.common.completion.backends.ollama")
  end
  LOG:TRACE("provider:" .. self.provider.name)

  self.opts.frontend = require("llm.common.completion.virtual_text")
  local completion_group = vim.api.nvim_create_augroup("completion", { clear = true })
  vim.api.nvim_create_autocmd("InsertEnter", {
    group = completion_group,
    callback = function()
      self:start()
    end,
  })
  vim.api.nvim_create_autocmd("TextChangedI", {
    group = completion_group,
    callback = function()
      self:start()
    end,
  })
  vim.api.nvim_create_autocmd("CompleteDone", {
    group = completion_group,
    callback = utils.terminate_all_jobs,
  })

  self:keymap()
end

function completion:keymap()
  local callbacks = {
    accept = function()
      self.opts.frontend:accept()
    end,
    next = function()
      self.opts.frontend:next()
    end,
    prev = function()
      self.opts.frontend:prev()
    end,
  }
  for name, km in pairs(self.opts.keymap.virtual_text) do
    vim.api.nvim_set_keymap(km.mode, km.keys, "", {
      callback = callbacks[name],
    })
  end
end

function completion:start()
  local context = utils.get_context(utils.make_cmp_context(), self.opts)
  local language = utils.add_language_comment()
  local tab = utils.add_tab_comment()
  self.opts.timeout = tostring(self.opts.timeout)
  if self.opts.fim then
    self.opts.prompt = language .. "\n" .. tab .. "\n" .. context.lines_before
    self.opts.suffix = context.lines_after
  end

  self.opts.frontend:clear()
  self.opts.exit_handler = function()
    self.opts.frontend:preview()
  end

  -- LOG:TRACE("start: " .. self.provider.name)
  LOG:TRACE("prompt:" .. self.opts.prompt)
  -- LOG:TRACE("suffix:" .. self.opts.suffix)
  if self.opts.prompt or self.opts.suffix then
    self.provider.request(self.opts)
  end
end
return completion
