local LOG = require("llm.common.log")
local Popup = require("nui.popup")
local ui = require("llm.common.ui")
local conf = require("llm.config")
local NuiText = require("nui.text")
local Layout = require("nui.layout")
local M = {}

function M.handler(name, F, state, streaming, prompt, opts)
  if prompt == nil then
    prompt = require("llm.tools.prompts").qa
  elseif type(prompt) == "function" then
    prompt = prompt()
  end

  local options = {
    buftype = "nofile",
    spell = false,
    number = false,
    wrap = true,
    linebreak = false,
    component_width = "60%",
    component_height = "55%",
    query = {
      title = " 󰊿 Trans ",
      hl = { link = "Define" },
    },
    input_box_opts = {
      size = "15%",
      win_options = {
        winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
      },
    },
    preview_box_opts = {
      size = "85%",
      win_options = {
        winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
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
  options.fetch_key = options.fetch_key and options.fetch_key or conf.configs.fetch_key
  vim.api.nvim_set_hl(0, "LLMQuery", options.query.hl)

  local input_box = Popup({
    enter = true,
    border = {
      style = ui.seamless("rounded", "top"),
      text = {
        top = NuiText(options.query.title, "LLMQuery"),
        top_align = "center",
      },
    },
    win_options = options.input_box_opts.win_options,
  })

  local preview_box = Popup({
    focusable = true,
    border = {
      style = ui.seamless("rounded", "bottom"),
      text = { top = "", top_align = "center" },
    },
    win_options = options.preview_box_opts.win_options,
  })

  local layout = F.CreateLayout(
    options.component_width,
    options.component_height,
    Layout.Box({
      Layout.Box(input_box, { size = options.input_box_opts.size }),
      Layout.Box(preview_box, { size = options.preview_box_opts.size, { grow = 1 } }),
    }, { dir = "col" })
  )

  layout:mount()

  F.SetBoxOpts({ input_box, preview_box }, {
    filetype = { "llm", "llm" },
    buftype = options.buftype,
    spell = options.spell,
    number = options.number,
    wrap = options.wrap,
    linebreak = options.linebreak,
  })

  local worker = { job = nil }

  input_box:map("n", "<enter>", function()
    -- clear preview_box content [optional]
    vim.api.nvim_buf_set_lines(preview_box.bufnr, 0, -1, false, {})

    local input_table = vim.api.nvim_buf_get_lines(input_box.bufnr, 0, -1, true)
    local input = table.concat(input_table, "\n")

    -- clear input_box content
    vim.api.nvim_buf_set_lines(input_box.bufnr, 0, -1, false, {})
    if input ~= "" then
      state.app.session[name] = {
        { role = "system", content = prompt },
        { role = "user", content = input },
      }
      state.popwin = preview_box
      options.bufnr = preview_box.bufnr
      options.winid = preview_box.winid
      options.messages = state.app.session[name]
      worker = streaming(options)
    end
  end)

  input_box:map("n", { "J", "K" }, function()
    vim.api.nvim_set_current_win(preview_box.winid)
  end)
  preview_box:map("n", { "J", "K" }, function()
    vim.api.nvim_set_current_win(input_box.winid)
  end)

  local default_actions = {
    accept = function()
      vim.api.nvim_set_current_win(preview_box.winid)
      vim.api.nvim_command("normal! ggVGkky")
    end,
    reject = function() end,
    close = function() end,
  }

  for _, v in ipairs({ input_box, preview_box }) do
    for _, k in ipairs({ "accept", "reject", "close" }) do
      v:map(options[k].mapping.mode, options[k].mapping.keys, function()
        if worker.job then
          worker.job:shutdown()
          LOG:INFO("Suspend output...")
          vim.wait(200, function() end)
          worker.job = nil
        end
        if options[k].action ~= nil then
          options[k].action()
        else
          default_actions[k]()
        end
        layout:unmount()
      end)
    end
  end

  for _, f in pairs(options.hook) do
    f(input_box.bufnr, options)
  end

  -- Fix the vim.ui.select callback function not entering insert mode
  vim.defer_fn(function()
    vim.api.nvim_command("startinsert")
  end, 50)
end
return M
