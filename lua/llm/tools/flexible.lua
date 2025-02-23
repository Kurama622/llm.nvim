local parse = require("llm.common.io.parse")
local ui = require("llm.common.ui")
local conf = require("llm.config")
local LOG = require("llm.common.log")

local M = {}

function M.handler(name, F, state, _, prompt, opts)
  local options = {
    buftype = "nofile",
    spell = false,
    number = false,
    wrap = true,
    linebreak = false,
    exit_on_move = false,
    enter_flexible_window = true,
    apply_visual_selection = true,
    win_opts = {},
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
    content = (F.GetVisualSelection():gsub(".", {
      ["'"] = "''",
    }))
  end

  local flexible_box = nil

  if content == "" then
    state.app.session[name] = { { role = "user", content = prompt } }
  else
    state.app.session[name] = { { role = "system", content = prompt }, { role = "user", content = content } }
  end
  local fetch_key = options.fetch_key and options.fetch_key or conf.configs.fetch_key
  if options.exit_handler == nil then
    options.exit_handler = function(output)
      flexible_box = ui.FlexibleWindow(output, options.enter_flexible_window, options.win_opts)
      if flexible_box then
        flexible_box:mount()
      else
        LOG:ERROR(string.format([[Your model's output is "%s"]], output))
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
            options[v].action()
          else
            default_actions[v]()
          end
          flexible_box:unmount()
        end)
      end

      F.SetBoxOpts({ flexible_box }, {
        filetype = { "llm" },
        buftype = options.buftype,
        spell = options.spell,
        number = options.number,
        wrap = options.wrap,
        linebreak = options.linebreak,
      })
    end
  end

  parse.GetOutput(
    state.app.session[name],
    fetch_key,
    options.url,
    options.model,
    options.api_type,
    options.args,
    options.parse_handler,
    options.stdout_handler,
    options.stderr_handler,
    options.exit_handler
  )

  F.VisMode2NorMode()
  if options.exit_on_move then
    vim.api.nvim_create_autocmd("CursorMoved", {
      callback = function()
        if flexible_box ~= nil then
          flexible_box:unmount()
        end
      end,
    })
  end
end
return M
