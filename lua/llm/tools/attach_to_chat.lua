local LOG = require("llm.common.log")
local sess = require("llm.session")
local conf = require("llm.config")
local F = require("llm.common.api")
local diff = require("llm.common.diff_style")
local utils = require("llm.tools.utils")
local state = require("llm.state")
local M = {}

function M.handler(_, _, _, _, _, opts)
  local default_actions = {
    display = function()
      if diff.style == nil then
        diff = diff:update()
      end

      local display_opts = {}
      setmetatable(display_opts, {
        __index = state.summarize_suggestions,
      })
      utils.new_diff(diff, display_opts.pattern, display_opts.ctx, display_opts.assistant_output)
      F.CloseLLM()
    end,
    copy_suggestion_code = function()
      local display_opts = {}
      setmetatable(display_opts, {
        __index = state.summarize_suggestions,
      })
      utils.copy_suggestion_code(display_opts.pattern, display_opts.assistant_output)
      F.CloseLLM()
    end,
    accept = function()
      if diff and diff.valid then
        diff:accept()
      end
    end,
    reject = function()
      if diff and diff.valid then
        diff:reject()
      end
    end,
    close = function()
      if diff and diff.valid then
        diff:reject()
      end
    end,
  }
  local options = {
    is_codeblock = false,
    inline_assistant = false,
    language = "English",

    display = {
      mapping = {
        mode = "n",
        keys = { "d" },
      },
      action = nil,
    },
    copy_suggestion_code = {
      mapping = {
        mode = "n",
        keys = { "Y", "y" },
      },
      action = nil,
    },
    accept = {
      mapping = {
        mode = "n",
        keys = { "Y", "y" },
      },
      action = nil,
    },
    reject = {
      mapping = {
        mode = "n",
        keys = { "N", "n" },
      },
      action = nil,
    },
    close = {
      mapping = {
        mode = "n",
        keys = { "<esc>" },
      },
      action = nil,
    },
  }
  options = vim.tbl_deep_extend("force", options, opts or {})
  options.mode = vim.fn.mode()
  local bufnr = F.GetAttach(options)
  LOG:INFO("Attach successfully!")

  for _, k in ipairs({ "accept", "reject", "close" }) do
    utils.set_keymapping(options[k].mapping.mode, options[k].mapping.keys, function()
      default_actions[k]()
      if options[k].action ~= nil then
        options[k].action()
      end
      if k == "close" then
        for _, kk in ipairs({ "accept", "reject", "close" }) do
          utils.clear_keymapping(options[kk].mapping.mode, options[kk].mapping.keys, bufnr)
        end
      end
    end, bufnr)
  end

  sess.NewSession()

  local bufnr_list = F.GetChatUiBufnrList()
  for _, ui_bufnr in ipairs(bufnr_list) do
    for _, k in ipairs({ "display", "copy_suggestion_code" }) do
      utils.set_keymapping(options[k].mapping.mode, options[k].mapping.keys, function()
        default_actions[k]()
        if options[k].action ~= nil then
          options[k].action()
        end
      end, ui_bufnr)
    end
  end
end

return M
