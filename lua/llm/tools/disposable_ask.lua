local LOG = require("llm.common.log")
local Popup = require("nui.popup")
local sess = require("llm.session")
local diff = require("llm.common.diff_style")
local utils = require("llm.tools.utils")
local state = require("llm.state")
local F = require("llm.common.api")
local M = {}

function M.handler(_, _, _, _, prompt, opts)
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
      state.popwin:unmount()
      F.ClearSummarizeSuggestions()
    end,
    copy_suggestion_code = function()
      local display_opts = {}
      setmetatable(display_opts, {
        __index = state.summarize_suggestions,
      })
      utils.copy_suggestion_code(display_opts.pattern, display_opts.assistant_output)
      state.popwin:unmount()
      F.ClearSummarizeSuggestions()
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

  if type(prompt) == "function" then
    prompt = prompt()
  end

  local options = {
    _name = "Ask",
    inline_assistant = false,
    enable_buffer_context = true,
    language = "English",
    timeout = 30,
    win_options = {
      winblend = 0,
      winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
    },
    border = {
      style = opts.style or "rounded",
      text = {
        top = opts.title or " Ask ",
        top_align = "center",
      },
    },
    position = opts.position or {
      row = 0,
      col = 0,
    },
    relative = opts.relative or "cursor",
    size = opts.size or {
      width = "50%",
      height = "5%",
    },
    enter = true,
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

  -- set diff keymapping
  local bufnr = vim.api.nvim_get_current_buf()
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

  local input_box = Popup(options)
  local mode = options.mode or vim.fn.mode()

  input_box:mount()

  vim.api.nvim_set_option_value("filetype", "llm", { buf = input_box.bufnr })
  vim.api.nvim_command("startinsert")
  input_box:map("n", "<cr>", function()
    local description = table.concat(vim.api.nvim_buf_get_lines(input_box.bufnr, 0, -1, true), "\n")
    input_box:unmount()
    local builtin_opts = {
      prompt = prompt,
      inline_assistant = options.inline_assistant,
      enable_buffer_context = options.enable_buffer_context,
      language = options.language,
      action = default_actions,
      _ = options,
      mode = mode,
    }
    sess.LLMSelectedTextHandler(description, true, builtin_opts)
  end)

  for _, f in pairs(options.hook) do
    f(input_box.bufnr, options)
  end

  input_box:map("n", "<esc>", function()
    input_box:unmount()
  end)
end

return M
