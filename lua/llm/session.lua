local M = {}

local uin = require("llm.common.input")
local conf = require("llm.config")
local layout = require("llm.layout")
local streaming = require("llm.common.streaming")
local _popup = require("nui.popup")
local F = require("llm.common.func")

local function OpenLLM()
  F.SetRole(layout.llm.bufnr, layout.llm.winid, "llm")
  layout.llm.job = streaming.GetStreamingOutput(layout.llm.bufnr, layout.llm.winid, conf.session.messages)
end
local function GetVisualSelectionRange()
  local line_v = vim.fn.getpos("v")[2]
  local line_cur = vim.api.nvim_win_get_cursor(0)[1]
  if line_v > line_cur then
    return line_cur, line_v
  end
  return line_v, line_cur
end

local function GetVisualSelection()
  local vstart, vend = GetVisualSelectionRange()
  local lines = vim.fn.getline(vstart, vend)
  local seletion = table.concat(lines, "\n")
  return seletion
end

function M.LLMSelectedTextHandler(description)
  local content = description .. ":\n" .. GetVisualSelection()
  table.insert(conf.session.messages, { role = "user", content = content })

  layout.popwin = _popup(conf.configs.popwin_opts)

  layout.popwin:mount()
  vim.api.nvim_set_option_value("filetype", "markdown", { buf = layout.popwin.bufnr })
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = layout.popwin.bufnr })
  vim.api.nvim_set_option_value("spell", false, { win = layout.popwin.winid })
  vim.api.nvim_set_option_value("wrap", true, { win = layout.popwin.winid })
  layout.llm.job = streaming.GetStreamingOutput(layout.popwin.bufnr, layout.popwin.winid, conf.session.messages)

  for k, v in pairs(conf.configs.keys) do
    if k == "Session:Close" then
      layout.popwin:map(v.mode, v.key, function()
        layout.popwin:unmount()
        F.CancelLLM()
      end, { noremap = true })
    elseif k == "Output:Cancel" then
      layout.popwin:map(v.mode, v.key, F.CancelLLM, { noremap = true, silent = true })
    end
  end
end

function M.AddMessageToSession()
  local content = GetVisualSelection()
  F.SetRole(layout.llm.bufnr, layout.llm.winid, "user")
  table.insert(conf.session.messages, { role = "user", content = content })
  F.WriteContent(layout.llm.bufnr, layout.llm.winid, content)
end

function M.NewSession()
  if conf.session.status == -1 then
    local bufnr = vim.api.nvim_win_get_buf(0)
    local filename = vim.api.nvim_buf_get_name(bufnr)
    local winid = vim.api.nvim_get_current_win()

    local cmd_output = vim.fn.execute(":autocmd")

    local open_llm_autocmd_exists = string.match(cmd_output, "OpenLLM")
    if not open_llm_autocmd_exists then
      vim.api.nvim_create_autocmd("User", {
        pattern = "OpenLLM",
        callback = OpenLLM,
      })
    end

    if conf.configs.output_box_opts.style == "float" then
      local llm_popup = _popup(conf.configs.output_box_opts)
      layout.llm.popup = llm_popup

      llm_popup:mount()
      bufnr = llm_popup.bufnr
      winid = llm_popup.winid

      -- set autocmds
      local user_autocmd_lists = {
        close_llm = {
          exist = string.match(cmd_output, "CloseLLM"),
          pattern = "CloseLLM",
          callback = F.CloseLLM,
        },
        close_input = {
          exist = string.match(cmd_output, "CloseInput"),
          pattern = "CloseInput",
          callback = F.CloseInput,
        },
      }

      for _, v in pairs(user_autocmd_lists) do
        if not v.exist then
          vim.api.nvim_create_autocmd("User", {
            pattern = v.pattern,
            callback = v.callback,
          })
        end
      end

      -- set keymaps
      for k, v in pairs(conf.configs.keys) do
        if k == "Session:Close" then
          llm_popup:map(v.mode, v.key, function()
            F.CloseLLM()
            vim.api.nvim_exec_autocmds("User", { pattern = "CloseInput" })
            conf.session.status = -1
          end, { noremap = true })
        elseif k == "Session:Toggle" then
          llm_popup:map(v.mode, v.key, F.ToggleLLM, { noremap = true })
        end
      end
      uin.SetInput(bufnr, winid, conf.session.messages)
      conf.session.status = 1
    else
      if filename ~= "" or vim.bo.modifiable == false then
        bufnr = vim.api.nvim_create_buf(false, true)
        local win_options = {
          split = conf.configs.output_box_opts.style,
        }
        winid = vim.api.nvim_open_win(bufnr, true, win_options)
      end

      -- set keymaps
      for k, v in pairs(conf.configs.keys) do
        if k == "Output:Ask" then
          vim.keymap.set(v.mode, v.key, function()
            uin.SetInput(bufnr, winid, conf.session.messages)
          end, { buffer = bufnr, noremap = true, silent = true })
        elseif k == "Output:Cancel" then
          vim.keymap.set("n", "<C-c>", F.CancelLLM, { buffer = bufnr, noremap = true, silent = true })
        elseif k == "Output:Resend" then
          vim.keymap.set("n", "<C-r>", F.ResendLLM, { buffer = bufnr, noremap = true, silent = true })
        end
      end
    end

    filename = os.date("/tmp/%Y%m%d-%H%M%S") .. ".llm"
    vim.api.nvim_set_option_value("filetype", "markdown", { buf = bufnr })
    vim.api.nvim_set_option_value("buftype", "nofile", { buf = bufnr })
    vim.api.nvim_buf_set_name(bufnr, filename)
    vim.api.nvim_set_option_value("spell", false, { win = winid })
    vim.api.nvim_set_option_value("wrap", true, { win = winid })

    layout.llm.bufnr = bufnr
    layout.llm.winid = winid
  else
    F.ToggleLLM()
  end
end

return M
