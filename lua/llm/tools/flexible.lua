local parse = require("llm.common.io.parse")
local ui = require("llm.common.ui")
local conf = require("llm.config")
local LOG = require("llm.common.log")

local M = {}

function M.handler(name, F, state, _, prompt, opts)
  local options = {
    exit_on_move = false,
    enter_flexible_window = true,
    apply_visual_selection = true,
    timeout = 30,
    win_opts = {
      win_options = {
        spell = false,
        wrap = true,
        number = false,
        linebreak = false,
      },
      buf_options = {
        buftype = "nofile",
        filetype = "llm",
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

  if type(prompt) == "function" then
    prompt = (prompt():gsub(".", {
      ["'"] = "''",
    }))
  end

  local content = ""
  if options.apply_visual_selection then
    local mode = options.mode or vim.fn.mode()
    local lines = F.GetVisualSelectionRange(vim.api.nvim_get_current_buf(), mode, options)
    content = (F.GetVisualSelection(lines):gsub(".", {
      ["'"] = "''",
    }))
  end

  local flexible_box = nil

  if content == "" then
    state.app.session[name] = { { role = "user", content = prompt } }
  else
    state.app.session[name] = { { role = "system", content = prompt }, { role = "user", content = content } }
  end
  options.fetch_key = options.fetch_key and options.fetch_key or conf.configs.fetch_key
  options.messages = state.app.session[name]
  if options.exit_handler == nil then
    options.exit_handler = function(output)
      flexible_box = ui.FlexibleWindow(output, options.enter_flexible_window, options.win_opts)
      if flexible_box then
        flexible_box:mount()
      else
        LOG:ERROR("Your model's output is:", output)
        return
      end

      local default_actions = {
        accept = function()
          vim.api.nvim_command("normal! ggVGy")
        end,
        reject = function() end,
        close = function() end,
      }
      -- set keymaps and action
      for _, v in ipairs({ "accept", "reject", "close" }) do
        flexible_box:map(options[v].mapping.mode, options[v].mapping.keys, function()
          if options[v].action ~= nil then
            options[v]:action(options)
          else
            default_actions[v]()
          end
          flexible_box:unmount()
        end)
      end
    end
  end

  parse.GetOutput(options)

  F.VisMode2NorMode()
  if options.exit_on_move then
    vim.api.nvim_create_autocmd("CursorMoved", {
      group = vim.api.nvim_create_augroup("exit_on_move", { clear = true }),
      callback = function()
        if flexible_box ~= nil then
          flexible_box:unmount()
        end
      end,
    })
  end
end
return M
