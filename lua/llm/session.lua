local M = {}

local conf = require("llm.config")
local state = require("llm.state")
local streaming = require("llm.common.io.streaming")
local Popup = require("nui.popup")
local F = require("llm.common.api")
local LOG = require("llm.common.log")
local _layout = require("llm.common.layout")
local utils = require("llm.tools.utils")

local function hide_session()
  if state.layout.popup then
    state.layout.popup:hide()
    conf.session.status = 0
  else
    local success, _ = pcall(vim.api.nvim_win_close, state.llm.winid, true)
    if not success then
      LOG:WARN("Single window does not need to be hidden.")
    end
    if state.input.popup then
      state.input.popup:hide()
    end
  end
  conf.session.status = 0
end

local function new_session()
  LOG:WARN('[Unrecommended Behavior] Last time, the window was closed without using the "Session:Close" shortcut key.')
  conf.session.status = -1
end

local function show_session()
  if state.layout.popup then
    state.layout.popup:show()
    state.llm.winid = state.llm.popup.winid
    vim.api.nvim_set_option_value("spell", false, { win = state.llm.winid })
    vim.api.nvim_set_option_value("wrap", true, { win = state.llm.winid })
  else
    local win_options = {
      split = conf.configs.style,
    }
    state.llm.winid = vim.api.nvim_open_win(state.llm.bufnr, true, win_options)
    if state.input.popup then
      -- The relative winid needs to be adjusted when "relative = win",
      if state.input.popup.border.win_config.win then
        state.input.popup.border.win_config.win = state.llm.winid
      end
      state.input.popup:show()
    end
  end
  conf.session.status = 1
end

local function ToggleLLM()
  if conf.session.status == 1 then
    if vim.api.nvim_win_is_valid(state.llm.winid) then
      hide_session()
    else
      new_session()
    end
  elseif conf.session.status == 0 then
    show_session()
  end
end

function M.LLMSelectedTextHandler(description, builtin_called, opts)
  local lines = F.make_inline_context(opts, vim.api.nvim_get_current_buf(), "disposable_ask")
  local content = F.GetVisualSelection(lines)
  state.popwin = Popup(conf.configs.popwin_opts)
  state.popwin:mount()
  if builtin_called then
    if opts.prompt then
      state.session[state.popwin.winid] = {
        { role = "system", content = opts.prompt },
      }
    else
      state.session[state.popwin.winid] = {}
    end
    table.insert(state.session[state.popwin.winid], { role = "user", content = description .. "\n" .. content .. "\n" })
    F.update_prompt(state.popwin.winid)

    utils.set_keymapping(opts._.display.mapping.mode, opts._.display.mapping.keys, function()
      opts.action.display()
      if opts._.display.action ~= nil then
        opts._.display.action()
      end
    end, state.popwin.bufnr)
  else
    state.session[state.popwin.winid] = {
      { role = "system", content = description },
      { role = "user", content = content },
    }
  end

  vim.api.nvim_set_option_value("filetype", "llm", { buf = state.popwin.bufnr })
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = state.popwin.bufnr })
  vim.api.nvim_set_option_value("spell", false, { win = state.popwin.winid })
  vim.api.nvim_set_option_value("wrap", true, { win = state.popwin.winid })
  vim.api.nvim_set_option_value("linebreak", false, { win = state.popwin.winid })
  state.llm.worker = streaming.GetStreamingOutput({
    bufnr = state.popwin.bufnr,
    winid = state.popwin.winid,
    messages = state.session[state.popwin.winid],
    url = opts._.url,
    model = opts._.model,
    fetch_key = opts._.fetch_key,
    api_type = opts._.api_type,
    streaming_handler = opts._.streaming_handler,
  })

  for k, v in pairs(conf.configs.keys) do
    if k == "Session:Close" then
      F.SetFloatKeyMapping(state.popwin, v.mode, v.key, function()
        if state.llm.worker.job then
          state.llm.worker.job:shutdown()
          LOG:INFO("Suspend output...")
          vim.wait(200, function() end)
          state.llm.worker.job = nil
          vim.api.nvim_command("doautocmd BufEnter")
        end
        state.session[state.popwin.winid] = nil
        state.popwin:unmount()
      end, { noremap = true })
    elseif k == "Output:Cancel" then
      F.SetFloatKeyMapping(state.popwin, v.mode, v.key, F.CancelLLM, { noremap = true, silent = true })
    end
  end
end

function M.NewSession()
  if conf.session.status == -1 then
    local bufnr = vim.api.nvim_win_get_buf(0)
    local filename = vim.api.nvim_buf_get_name(bufnr)
    local winid = vim.api.nvim_get_current_win()

    -----------------------------------------------------
    ---                FLOAT STYLE
    -----------------------------------------------------
    if conf.configs.style == "float" then
      _layout.chat_ui()
      state.layout.popup:mount()
      vim.api.nvim_set_option_value("filetype", "llm", { buf = state.input.popup.bufnr })
      vim.api.nvim_set_current_win(state.input.popup.winid)
      vim.api.nvim_command("startinsert")
      bufnr = state.llm.popup.bufnr
      winid = state.llm.popup.winid

      -------------------------------------------------------------------------
      --- init current session
      -------------------------------------------------------------------------
      state.session.filename = "current"
      if not state.session[state.session.filename] then
        state.session[state.session.filename] = F.DeepCopy(conf.session.messages)
      end

      F.RefreshLLMText(state.session[state.session.filename])

      if conf.configs.save_session then
        local unmap_list = { "<Esc>", "<C-c>", "<CR>", "<Space>" }
        for _, v in ipairs(unmap_list) do
          state.history.popup:unmap("n", v)
        end
        state.history.popup = state.history.popup
      end

      -- set keymaps
      for k, v in pairs(conf.configs.keys) do
        if k == "Session:Close" then
          F.SetFloatKeyMapping(state.llm.popup, v.mode, v.key, function()
            F.CloseLLM()
          end, { noremap = true })
        elseif k == "Session:Toggle" then
          F.SetFloatKeyMapping(state.llm.popup, v.mode, v.key, ToggleLLM, { noremap = true })
        elseif k == "Focus:Input" then
          F.SetFloatKeyMapping(state.llm.popup, v.mode, v.key, function()
            vim.api.nvim_set_current_win(state.input.popup.winid)
            vim.api.nvim_command("startinsert")
          end, { noremap = true })
        end
      end

      for k, v in pairs(conf.configs.keys) do
        if k == "Input:Submit" then
          F.SetFloatKeyMapping(state.input.popup, v.mode, v.key, function()
            local input_table = vim.api.nvim_buf_get_lines(state.input.popup.bufnr, 0, -1, true)
            local input = table.concat(input_table, "\n")
            if state.input.attach_content then
              input = input .. "\n" .. state.input.attach_content
              F.ClearAttach()
            end
            if not conf.configs.save_session then
              state.session.filename = "current"
              if not state.session[state.session.filename] then
                state.session[state.session.filename] = F.DeepCopy(conf.session.messages)
              end
            end
            vim.api.nvim_buf_set_lines(state.input.popup.bufnr, 0, -1, false, {})
            F.update_prompt(state.session.filename)
            if input ~= "" then
              table.insert(state.session[state.session.filename], { role = "user", content = input })
              F.SetRole(bufnr, winid, "user")
              F.AppendChunkToBuffer(bufnr, winid, input)
              F.NewLine(bufnr, winid)
              vim.api.nvim_exec_autocmds("User", { pattern = "OpenLLM" })
            end
          end, { noremap = true })
        elseif k == "Input:Cancel" then
          F.SetFloatKeyMapping(state.input.popup, v.mode, v.key, F.CancelLLM, { noremap = true, silent = true })
        elseif k == "Input:Resend" then
          F.SetFloatKeyMapping(state.input.popup, v.mode, v.key, F.ResendLLM, { noremap = true, silent = true })
        elseif k == "Session:Close" then
          F.SetFloatKeyMapping(state.input.popup, v.mode, v.key, function()
            F.CloseLLM()
          end, { noremap = true })
        elseif k == "Session:Toggle" then
          F.SetFloatKeyMapping(state.input.popup, v.mode, v.key, ToggleLLM, { noremap = true })
        elseif conf.configs.save_session and k == "Input:HistoryNext" then
          F.SetFloatKeyMapping(state.input.popup, v.mode, v.key, function()
            F.MoveHistoryCursor(1)
          end, { noremap = true })
        elseif conf.configs.save_session and k == "Input:HistoryPrev" then
          F.SetFloatKeyMapping(state.input.popup, v.mode, v.key, function()
            F.MoveHistoryCursor(-1)
          end, { noremap = true })
        elseif k == "Focus:Output" then
          F.SetFloatKeyMapping(state.input.popup, v.mode, v.key, function()
            vim.api.nvim_set_current_win(state.llm.popup.winid)
            vim.api.nvim_command("stopinsert")
          end, { noremap = true })
        end
      end
      conf.session.status = 1
    else
      -----------------------------------------------------
      ---                 SPLIT STYLE
      -----------------------------------------------------
      if filename ~= "" or vim.bo.modifiable == false then
        bufnr = vim.api.nvim_create_buf(false, true)
        local win_options = {
          split = conf.configs.style,
        }
        winid = vim.api.nvim_open_win(bufnr, true, win_options)
      end

      -- set keymaps
      for k, v in pairs(conf.configs.keys) do
        if k == "Output:Ask" then
          F.SetSplitKeyMapping(v.mode, v.key, function()
            if state.input.popup then
              vim.api.nvim_set_current_win(state.input.popup.winid)
              vim.api.nvim_command("startinsert")
            else
              state.input.popup = Popup({
                relative = conf.configs.chat_ui_opts.input.split.relative or conf.configs.chat_ui_opts.relative,
                position = conf.configs.chat_ui_opts.input.split.position,
                enter = conf.configs.chat_ui_opts.input.split.enter,
                focusable = conf.configs.chat_ui_opts.input.split.focusable,
                zindex = conf.configs.chat_ui_opts.input.split.zindex,
                border = conf.configs.chat_ui_opts.input.split.border,
                win_options = conf.configs.chat_ui_opts.input.split.win_options,
                size = conf.configs.chat_ui_opts.input.split.size,
              })
              state.input.popup:mount()
              vim.api.nvim_set_option_value("filetype", "llm", { buf = state.input.popup.bufnr })
              vim.api.nvim_set_current_win(state.input.popup.winid)
              vim.api.nvim_command("startinsert")

              for name, d in pairs(conf.configs.keys) do
                if name == "Input:Submit" then
                  F.SetFloatKeyMapping(state.input.popup, d.mode, d.key, function()
                    local input_table = vim.api.nvim_buf_get_lines(state.input.popup.bufnr, 0, -1, true)
                    local input = table.concat(input_table, "\n")
                    if state.input.attach_content then
                      input = input .. "\n" .. state.input.attach_content
                      F.ClearAttach()
                    end
                    state.session.filename = state.session.filename or "current"
                    if not state.session[state.session.filename] then
                      state.session[state.session.filename] = F.DeepCopy(conf.session.messages)
                    end
                    state.input.popup:unmount()
                    state.input.popup = nil
                    F.update_prompt(state.session.filename)
                    if input ~= "" then
                      table.insert(state.session[state.session.filename], { role = "user", content = input })
                      F.SetRole(bufnr, winid, "user")
                      F.AppendChunkToBuffer(bufnr, winid, input)
                      F.NewLine(bufnr, winid)
                      vim.api.nvim_exec_autocmds("User", { pattern = "OpenLLM" })
                    end
                  end, { noremap = true })
                elseif name == "Session:Close" then
                  F.SetFloatKeyMapping(state.input.popup, d.mode, d.key, function()
                    F.CloseLLM()
                  end, { noremap = true })
                elseif name == "Session:Toggle" then
                  F.SetFloatKeyMapping(state.input.popup, d.mode, d.key, ToggleLLM, { noremap = true })
                end
              end
            end
          end, { buffer = bufnr, noremap = true, silent = true })
        elseif k == "Session:Toggle" then
          F.SetSplitKeyMapping(v.mode, v.key, ToggleLLM, { buffer = bufnr, noremap = true, silent = true })
        elseif k == "Session:Close" then
          F.SetSplitKeyMapping(v.mode, v.key, function()
            F.CloseLLM()
          end, { buffer = bufnr, noremap = true, silent = true })
        elseif k == "Session:History" then
          F.SetSplitKeyMapping(v.mode, v.key, function()
            _layout.menu_preview()
          end, { buffer = bufnr, noremap = true, silent = true })
        elseif k == "Output:Cancel" then
          F.SetSplitKeyMapping(v.mode, v.key, F.CancelLLM, { buffer = bufnr, noremap = true, silent = true })
        elseif k == "Output:Resend" then
          F.SetSplitKeyMapping(v.mode, v.key, F.ResendLLM, { buffer = bufnr, noremap = true, silent = true })
        end
      end

      conf.session.status = 1
    end

    filename = os.date("/tmp/%Y%m%d-%H%M%S") .. ".llm"
    vim.api.nvim_set_option_value("filetype", "llm", { buf = bufnr })
    vim.api.nvim_set_option_value("buftype", "nofile", { buf = bufnr })
    vim.api.nvim_buf_set_name(bufnr, filename)
    vim.api.nvim_set_option_value("spell", false, { win = winid })
    vim.api.nvim_set_option_value("wrap", true, { win = winid })
    vim.api.nvim_set_option_value("linebreak", false, { win = winid })

    state.llm.bufnr = bufnr
    state.llm.winid = winid
  else
    ToggleLLM()
  end
end

return M
