local LOG = require("llm.common.log")
local state = require("llm.state")
local utils = require("llm.common.completion.utils")

local completion = {}

function completion:init(opts)
  self.opts = opts
  if self.opts.api_type == "ollama" then
    self.provider = require("llm.common.completion.backends.ollama")
  end
  LOG:TRACE("llm.nvim completion provider: " .. self.provider.name)

  self.opts.frontend = require("llm.common.completion.virtual_text")
  self:autocmd()
  self:keymap()
end

function completion:autocmd()
  if state.completion.set_autocmd then
    return
  end
  local completion_group = vim.api.nvim_create_augroup("completion", { clear = true })

  vim.api.nvim_create_autocmd("InsertLeavePre", {
    group = completion_group,
    callback = function()
      if not state.completion.enable then
        return
      end
      utils.terminate_all_jobs()
      self.opts.frontend:clear()
    end,
  })
  if self.opts.auto_trigger then
    vim.api.nvim_create_autocmd("InsertEnter", {
      group = completion_group,
      callback = function()
        if not state.completion.enable then
          return
        end
        self:start()
      end,
    })
    vim.api.nvim_create_autocmd("TextChangedI", {
      group = completion_group,
      callback = function()
        if not state.completion.enable then
          return
        end
        self:start()
      end,
    })
  end
  vim.api.nvim_create_autocmd("CompleteDone", {
    group = completion_group,
    callback = function()
      if not state.completion.enable then
        return
      end
      utils.terminate_all_jobs()
      self.opts.frontend:clear()
    end,
  })
  state.completion.set_autocmd = true
end

function completion:keymap()
  if state.completion.set_keymap then
    return
  end
  local callbacks = {
    accept = function()
      if not state.completion.enable then
        LOG:WARN("Please enable llm.nvim completion.")
        return
      end
      if self.opts.frontend.rendered then
        self.opts.frontend:accept()
      elseif not self.opts.auto_trigger then
        LOG:TRACE("Manual trigger completion.")
        self:start()
      end
    end,
    next = function()
      self.opts.frontend:next()
    end,
    prev = function()
      self.opts.frontend:prev()
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
    })
  end
  state.completion.set_keymap = true
end

function completion:start()
  if self.opts.ignore_filetypes_dict[vim.bo.ft] then
    return
  end
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

  if self.opts.prompt or self.opts.suffix then
    self.provider.request(self.opts)
  end
end
return completion
