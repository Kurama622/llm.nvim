local LOG = require("llm.common.log")
local Popup = require("nui.popup")
local ui = require("llm.common.ui")
local conf = require("llm.config")
local Layout = require("nui.layout")
local M = {}

local function get_images_format(paths)
  local path_tbl = vim.split(paths, "\n")
  local res = {}
  for _, path in pairs(path_tbl) do
    local tbl = vim.split(path, "%.")
    table.insert(res, tbl[#tbl])
  end
  return res
end

function M.handler(name, F, state, streaming, prompt, opts)
  if prompt == nil then
    prompt = require("llm.tools.prompts").images
  elseif type(prompt) == "function" then
    prompt = prompt()
  end

  local options = {
    picker = {
      cmd = "fzf",
      height = nil,
      width = nil,
      row = nil,
      col = nil,
      relative = nil,
      border = nil,
      mapping = {
        mode = "i",
        keys = "<C-f>",
      },
    },
    _name = "Images",
    buftype = "nofile",
    spell = false,
    number = false,
    wrap = true,
    linebreak = false,
    component_width = "60%",
    component_height = "55%",
    timeout = 120,
    use_base64 = true,
    detail = "auto",
    query = {
      title = " Image Path ",
      hl = { link = "Define" },
    },
    input_box_opts = {
      enter = true,
      size = "15%",
      border = {
        style = "rounded",
        text = { top_align = "center" },
      },
      win_options = {
        winhighlight = "Normal:Normal,FloatBorder:FloatBorder,FloatTitle:LLMQuery",
      },
    },
    preview_box_opts = {
      focusable = true,
      size = "85%",
      border = {
        style = "rounded",
        text = { top = "", top_align = "center" },
      },
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

  options.input_box_opts.border = vim.tbl_deep_extend("keep", options.input_box_opts.border, {
    text = {
      top = options.query.title,
    },
  })
  options.input_box_opts.border.style = ui.seamless(options.input_box_opts.border.style, "top")

  options.preview_box_opts.border = vim.tbl_deep_extend("force", options.preview_box_opts.border, {
    style = ui.seamless(options.preview_box_opts.border.style, "bottom"),
  })

  vim.api.nvim_set_hl(0, "LLMQuery", options.query.hl)

  local input_box = Popup(F.table_filter(function(key)
    return key ~= "size"
  end, options.input_box_opts))

  local preview_box = Popup(F.table_filter(function(key)
    return key ~= "size"
  end, options.preview_box_opts))

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

  input_box:map(options.picker.mapping.mode, options.picker.mapping.keys, function()
    if options.picker.extern then
      options.picker.extern(function(item)
        if item then
          local start_pos = #vim.api.nvim_buf_get_lines(input_box.bufnr, 0, -1, true)
          vim.api.nvim_buf_set_lines(input_box.bufnr, start_pos - 1, -1, false, { item })
        end
        vim.api.nvim_set_current_win(input_box.winid)
      end)
    else
      F.Picker(options.picker.cmd, {
        width = options.picker.width,
        height = options.picker.height,
        row = options.picker.row,
        col = options.picker.col,
        relative = options.picker.relative,
        border = options.picker.border,
      }, function(item)
        if item then
          local start_pos = #vim.api.nvim_buf_get_lines(input_box.bufnr, 0, -1, true)
          vim.api.nvim_buf_set_lines(input_box.bufnr, start_pos - 1, -1, false, { item })
        end
      end)
    end
  end)

  input_box:map("n", "<enter>", function()
    -- clear preview_box content [optional]
    vim.api.nvim_buf_set_lines(preview_box.bufnr, 0, -1, false, {})

    local input_table = vim.api.nvim_buf_get_lines(input_box.bufnr, 0, -1, true)
    local input = table.concat(input_table, "\n")

    -- clear input_box content
    vim.api.nvim_buf_set_lines(input_box.bufnr, 0, -1, false, {})
    if input ~= "" then
      options.format = get_images_format(input)
      if options.use_base64 then
        state.app.session[name] = {
          { role = "user", content = prompt, images = F.base64_images_encode(input) },
        }
      else
        state.app.session[name] = {
          { role = "user", content = prompt, images = vim.split(input, "\n") },
        }
      end
      state.popwin_list[preview_box.winid] = preview_box
      options.bufnr = preview_box.bufnr
      options.winid = preview_box.winid
      options.messages = state.app.session[name]
      streaming(options)
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
        F.CancelLLM()
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
