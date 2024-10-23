local M = {}

local uin = require("llm.common.input")
local conf = require("llm.config")
local state = require("llm.state")
local streaming = require("llm.common.streaming")
local _popup = require("nui.popup")
local Menu = require("nui.menu")
local F = require("llm.common.func")

local function OpenLLM()
  F.SetRole(state.llm.bufnr, state.llm.winid, "assistant")
  state.llm.worker = streaming.GetStreamingOutput(
    state.llm.bufnr,
    state.llm.winid,
    state.session[state.session.filename],
    conf.configs.fetch_key
  )
end

function M.LLMSelectedTextHandler(description)
  local content = description .. ":\n" .. F.GetVisualSelection()
  state.popwin = _popup(conf.configs.popwin_opts)
  state.popwin:mount()
  state.session[state.popwin.winid] = {}
  table.insert(state.session[state.popwin.winid], { role = "user", content = content })

  vim.api.nvim_set_option_value("filetype", "markdown", { buf = state.popwin.bufnr })
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = state.popwin.bufnr })
  vim.api.nvim_set_option_value("spell", false, { win = state.popwin.winid })
  vim.api.nvim_set_option_value("wrap", true, { win = state.popwin.winid })
  vim.api.nvim_set_option_value("linebreak", false, { win = state.popwin.winid })
  state.llm.worker = streaming.GetStreamingOutput(
    state.popwin.bufnr,
    state.popwin.winid,
    state.session[state.popwin.winid],
    conf.configs.fetch_key
  )

  for k, v in pairs(conf.configs.keys) do
    if k == "Session:Close" then
      F.WinMapping(state.popwin, v.mode, v.key, function()
        if state.llm.worker.job then
          state.llm.worker.job:shutdown()
          print("Suspend output...")
          vim.wait(200, function() end)
          state.llm.worker.job = nil
        end
        state.popwin:unmount()
      end, { noremap = true })
    elseif k == "Output:Cancel" then
      F.WinMapping(state.popwin, v.mode, v.key, F.CancelLLM, { noremap = true, silent = true })
    end
  end
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
      state.llm.popup = llm_popup

      llm_popup:mount()
      bufnr = llm_popup.bufnr
      winid = llm_popup.winid

      if conf.configs.save_session then
        local history_popup = Menu(conf.configs.history_box_opts, {
          lines = (function()
            local items = F.ListFilesInPath()
            state.history.list = { Menu.item("current") }
            for _, item in ipairs(items) do
              table.insert(state.history.list, Menu.item(item))
            end
            return state.history.list
          end)(),
          max_width = 20,
          keymap = {
            focus_next = { "j", "<Down>", "<Tab>" },
            focus_prev = { "k", "<Up>", "<S-Tab>" },
            submit = { "<CR>", "<Space>" },
          },
          on_change = function(item)
            if item.text == "current" then
              state.session.filename = item.text
              if not state.session[item.text] then
                state.session[item.text] = F.DeepCopy(conf.session.messages)
              end
              F.RefreshLLMText(state.session[item.text])
            else
              local sess_file = string.format("%s/%s", conf.configs.history_path, item.text)
              state.session.filename = item.text
              if not state.session[item.text] then
                local file = io.open(sess_file, "r")
                local messages = vim.fn.json_decode(file:read())
                state.session[item.text] = messages
                file:close()
              end
              F.RefreshLLMText(state.session[item.text])
            end
          end,
          on_submit = function(item)
            print("Menu Submitted: ", item.text)
          end,
        })

        history_popup:mount()
        local unmap_list = { "<Esc>", "<C-c>", "<CR>", "<Space>" }
        for _, v in ipairs(unmap_list) do
          history_popup:unmap("n", v)
        end
        state.history.popup = history_popup
      end

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
        close_history = {
          exist = string.match(cmd_output, "CloseHistory"),
          pattern = "CloseHistory",
          callback = F.CloseHistory,
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
          F.WinMapping(llm_popup, v.mode, v.key, function()
            F.CloseLLM()
            vim.api.nvim_exec_autocmds("User", { pattern = "CloseInput" })
            vim.api.nvim_exec_autocmds("User", { pattern = "CloseHistory" })
            conf.session.status = -1
          end, { noremap = true })
        elseif k == "Session:Toggle" then
          F.WinMapping(llm_popup, v.mode, v.key, F.ToggleLLM, { noremap = true })
        end
      end
      uin.SetInput(bufnr, winid)
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
            uin.SetInput(bufnr, winid)
          end, { buffer = bufnr, noremap = true, silent = true })
        elseif k == "Output:Cancel" then
          vim.keymap.set(v.mode, v.key, F.CancelLLM, { buffer = bufnr, noremap = true, silent = true })
        elseif k == "Output:Resend" then
          vim.keymap.set(v.mode, v.key, F.ResendLLM, { buffer = bufnr, noremap = true, silent = true })
        end
      end
    end

    filename = os.date("/tmp/%Y%m%d-%H%M%S") .. ".llm"
    vim.api.nvim_set_option_value("filetype", "markdown", { buf = bufnr })
    vim.api.nvim_set_option_value("buftype", "nofile", { buf = bufnr })
    vim.api.nvim_buf_set_name(bufnr, filename)
    vim.api.nvim_set_option_value("spell", false, { win = winid })
    vim.api.nvim_set_option_value("wrap", true, { win = winid })
    vim.api.nvim_set_option_value("linebreak", false, { win = winid })

    state.llm.bufnr = bufnr
    state.llm.winid = winid
  else
    F.ToggleLLM()
  end
end

return M
