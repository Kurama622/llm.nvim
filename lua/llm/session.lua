local M = {}

local conf = require("llm.config")
local state = require("llm.state")
local Popup = require("nui.popup")
local F = require("llm.common.api")
local LOG = require("llm.common.log")

local function hide_session()
  if state.layout.popup then
    state.layout.popup:hide()
  else
    for _, comp in ipairs({ state.llm, state.input }) do
      if comp.popup then
        comp.popup:hide()
      end
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

    -- The cursor moves to the location of the model.
    local model_idx = nil
    if F.IsValid(state.models.Chat.selected) then
      model_idx = state.models.Chat.selected._model_idx
    end
    F.RepositionPopupCursor(state.models.popup, model_idx)
  else
    if state.llm.popup then
      state.llm.popup:show()
    end
    if state.input.popup then
      -- The relative winid needs to be adjusted when "relative = win",
      if state.input.popup.border.win_config.win then
        state.input.popup.border.win_config.win = state.llm.popup.winid
      end
      -- manual_hidden: Input popup is hidden separately.
      if not state.input.popup.manual_hidden then
        state.input.popup:show()
      end
    end
  end
  conf.session.status = 1
end

local function ToggleLLM()
  if conf.session.status == 1 then
    if vim.api.nvim_win_is_valid(state.llm.popup.winid) then
      hide_session()
    else
      new_session()
    end
  elseif conf.session.status == 0 then
    show_session()
  end
end

function M.LLMSelectedTextHandler(description, builtin_called, opts)
  opts = opts or {}
  opts.diagnostic = opts.diagnostic or conf.configs.diagnostic
  local bufnr = vim.api.nvim_get_current_buf()
  opts.lsp = opts.lsp or conf.configs.lsp
  local lines, start_line, end_line, start_col, end_col = F.MakeInlineContext(opts, bufnr, "disposable_ask")
  if F.IsValid(opts.lsp) then
    opts.lsp.bufnr = bufnr
    opts.lsp.start_line, opts.lsp.end_line = start_line, end_line
  end
  state.input.attach_content = F.GetVisualSelection(lines)

  if builtin_called then
    conf.configs.popwin_opts.border.text.top = conf.configs.popwin_opts.border.text.top_builtin
  else
    conf.configs.popwin_opts.border.text.top = conf.configs.popwin_opts.border.text.top_user
  end

  local popwin = Popup(conf.configs.popwin_opts)
  popwin:mount()

  state.popwin_list[popwin.winid] = popwin
  state.popwin_list[popwin.winid].row, state.popwin_list[popwin.winid].col = unpack(vim.api.nvim_win_get_position(0))
  local update_cursor_pos = {
    left = function(winid, v)
      state.popwin_list[winid].col = state.popwin_list[winid].col - v.distance
    end,
    right = function(winid, v)
      state.popwin_list[winid].col = state.popwin_list[winid].col + v.distance
    end,
    up = function(winid, v)
      state.popwin_list[winid].row = state.popwin_list[winid].row - v.distance
    end,
    down = function(winid, v)
      state.popwin_list[winid].row = state.popwin_list[winid].row + v.distance
    end,
  }

  if F.IsValid(opts.diagnostic) then
    state.input.attach_content = state.input.attach_content
      .. "\n"
      .. F.GetRangeDiagnostics(bufnr, start_line, end_line, start_col, end_col, opts)
  end

  state.input.request_with_lsp = F.lsp_wrap(opts)

  local streaming = require("llm.common.io.streaming")
  local utils = require("llm.tools.utils")
  if builtin_called then
    if opts.prompt then
      state.session[popwin.winid] = {
        { role = "system", content = opts.prompt },
      }
    else
      state.session[popwin.winid] = {}
    end
    table.insert(
      state.session[popwin.winid],
      { role = "user", content = description .. "\n" .. state.input.attach_content .. "\n" }
    )

    F.UpdatePrompt(popwin.winid)

    for _, k in ipairs({ "display", "copy_suggestion_code" }) do
      utils.set_keymapping(opts._[k].mapping.mode, opts._[k].mapping.keys, function()
        opts.action[k]()
        if k == "display" then
          if vim.api.nvim_get_option_value("buftype", { buf = bufnr }) ~= "nofile" then
            for _, op in ipairs({ "accept", "reject", "close" }) do
              utils.set_keymapping(opts._[op].mapping.mode, opts._[op].mapping.keys, function()
                opts.action[op]()
                if opts._[op].action ~= nil then
                  opts._[op].action()
                end
                for _, reset_op in ipairs({ "accept", "reject", "close" }) do
                  utils.clear_keymapping(opts._[reset_op].mapping.mode, opts._[reset_op].mapping.keys, bufnr)
                end
              end, bufnr)
            end
          end
        end
        if opts._[k].action ~= nil then
          opts._[k].action()
        end
      end, popwin.bufnr)
    end

    local params = {
      _name = opts._._name,
      bufnr = popwin.bufnr,
      winid = popwin.winid,
      messages = state.session[popwin.winid],
    }

    for _, key in pairs(state.model_params) do
      params[key] = opts._[key]
    end

    if state.input.request_with_lsp ~= nil then
      state.input.request_with_lsp(function()
        if F.IsValid(state.input.lsp_ctx.content) then
          table.insert(state.session[popwin.winid], state.input.lsp_ctx)
        end
        streaming.GetStreamingOutput(params)
        F.ClearAttach()
      end)
    else
      streaming.GetStreamingOutput(params)
    end
  else
    state.session[popwin.winid] = {
      { role = "system", content = description },
      { role = "user", content = state.input.attach_content },
    }
    streaming.GetStreamingOutput({
      bufnr = popwin.bufnr,
      winid = popwin.winid,
      messages = state.session[popwin.winid],
    })
  end

  for k, v in pairs(conf.configs.popwin_opts.move) do
    F.SetFloatKeyMapping(popwin, v.mode, v.keys, function()
      local winid = vim.api.nvim_get_current_win()

      update_cursor_pos[k](winid, v)

      local win_conf = vim.api.nvim_win_get_config(winid)
      state.popwin_list[winid]:update_layout({
        relative = "editor",
        position = {
          row = state.popwin_list[winid].row,
          col = state.popwin_list[winid].col,
        },
        size = {
          height = win_conf.height,
          width = win_conf.width,
        },
      })
    end)
  end
  for k, v in pairs(conf.configs.keys) do
    if k == "Session:Close" then
      F.SetFloatKeyMapping(popwin, v.mode, v.key, function()
        F.CancelLLM()
        vim.api.nvim_command("doautocmd BufEnter")
        local winid = vim.api.nvim_get_current_win()
        state.popwin_list[winid]:unmount()
        state.popwin_list[winid] = nil
        state.session[winid] = nil
      end, { noremap = true })
    elseif k == "Output:Cancel" then
      F.SetFloatKeyMapping(popwin, v.mode, v.key, F.CancelLLM, { noremap = true, silent = true })
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
      local _layout = require("llm.common.layout")
      _layout.chat_ui()
      _layout:mount()
      vim.api.nvim_set_current_win(state.input.popup.winid)
      vim.api.nvim_command("startinsert")
      bufnr = state.llm.popup.bufnr
      winid = state.llm.popup.winid

      -------------------------------------------------------------------------
      --- init current session
      -------------------------------------------------------------------------
      state.session.filename = "current"
      if not state.session[state.session.filename] then
        state.session[state.session.filename] = vim.deepcopy(conf.session.messages)
      end

      F.RefreshLLMText(state.session[state.session.filename])

      -- set keymaps
      for k, v in pairs(conf.configs.keys) do
        if k == "Session:Close" then
          F.SetFloatKeyMapping(state.llm.popup, v.mode, v.key, function()
            F.CloseLLM()
          end, { noremap = true })
        elseif k == "Session:Hide" then
          F.SetFloatKeyMapping(state.llm.popup, v.mode, v.key, ToggleLLM, { noremap = true })
        elseif k == "Session:Toggle" or k == "Session:Open" then
          F.SetFloatKeyMapping(state.llm.popup, v.mode, v.key, ToggleLLM, { noremap = true })
        elseif k == "Session:New" then
          F.SetFloatKeyMapping(state.llm.popup, v.mode, v.key, function()
            F.SaveSession()
            _layout:update_history()
            vim.api.nvim_buf_set_lines(state.llm.popup.bufnr, 0, -1, false, {})
            vim.api.nvim_set_current_win(state.input.popup.winid)
            vim.api.nvim_feedkeys("A", "n", false)
          end, { noremap = true, silent = true })
        elseif k == "Focus:Input" then
          F.SetFloatKeyMapping(state.llm.popup, v.mode, v.key, function()
            vim.api.nvim_set_current_win(state.input.popup.winid)
            vim.api.nvim_feedkeys("A", "n", false)
          end, { noremap = true })
        elseif k == "PageUp" then
          F.SetFloatKeyMapping(state.input.popup, v.mode, v.key, function()
            F.ScrollWindow(state.llm.popup.winid, "page-up")
          end, { noremap = true })
        elseif k == "PageDown" then
          F.SetFloatKeyMapping(state.input.popup, v.mode, v.key, function()
            F.ScrollWindow(state.llm.popup.winid, "page-down")
          end, { noremap = true })
        elseif k == "HalfPageUp" then
          F.SetFloatKeyMapping(state.input.popup, v.mode, v.key, function()
            F.ScrollWindow(state.llm.popup.winid, "half-page-up")
          end, { noremap = true })
        elseif k == "HalfPageDown" then
          F.SetFloatKeyMapping(state.input.popup, v.mode, v.key, function()
            F.ScrollWindow(state.llm.popup.winid, "half-page-down")
          end, { noremap = true })
        elseif k == "JumpToTop" then
          F.SetFloatKeyMapping(state.input.popup, v.mode, v.key, function()
            F.ScrollWindow(state.llm.popup.winid, "top")
          end, { noremap = true })
        elseif k == "JumpToBottom" then
          F.SetFloatKeyMapping(state.input.popup, v.mode, v.key, function()
            F.ScrollWindow(state.llm.popup.winid, "bottom")
          end, { noremap = true })
        end
      end

      for k, v in pairs(conf.configs.keys) do
        if k == "Input:Submit" then
          F.SetFloatKeyMapping(state.input.popup, v.mode, v.key, function()
            local input_table = vim.api.nvim_buf_get_lines(state.input.popup.bufnr, 0, -1, true)
            local input = table.concat(input_table, "\n") .. "\n" .. state.input.attach_content

            if not conf.configs.save_session then
              state.session.filename = "current"
              if not state.session[state.session.filename] then
                state.session[state.session.filename] = vim.deepcopy(conf.session.messages)
              end
            end
            vim.api.nvim_buf_set_lines(state.input.popup.bufnr, 0, -1, false, {})
            F.UpdatePrompt(state.session.filename)
            if input ~= "" then
              table.insert(state.session.changed, state.session.filename)
              table.insert(state.session[state.session.filename], { role = "user", content = input })
              F.SetRole(bufnr, winid, "user")
              F.AppendChunkToBuffer(bufnr, winid, input)
              F.NewLine(bufnr, winid)
              if state.input.request_with_lsp ~= nil then
                state.input.request_with_lsp(function()
                  if F.IsValid(state.input.lsp_ctx.content) then
                    table.insert(state.session[state.session.filename], state.input.lsp_ctx)
                    F.SetRole(bufnr, winid, "user")

                    local symbols_location_info = ""
                    for fname, symbol_location in pairs(state.input.lsp_ctx.symbols_location_list) do
                      for _, sym in pairs(symbol_location) do
                        symbols_location_info = symbols_location_info
                          .. "\n- "
                          .. fname
                          .. "#L"
                          .. sym.start_row
                          .. "-"
                          .. sym.end_row
                          .. " | "
                          .. sym.name
                      end
                    end
                    F.AppendChunkToBuffer(
                      bufnr,
                      winid,
                      require("llm.tools.prompts").lsp .. "\n" .. symbols_location_info .. "\n"
                    )
                    F.NewLine(bufnr, winid)
                  end
                  vim.api.nvim_exec_autocmds("User", { pattern = "OpenLLM" })
                  F.ClearAttach()
                end)
              else
                vim.api.nvim_exec_autocmds("User", { pattern = "OpenLLM" })
              end
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
        elseif k == "Session:Toggle" or k == "Session:Open" then
          F.SetFloatKeyMapping(state.input.popup, v.mode, v.key, ToggleLLM, { noremap = true })
        elseif k == "Session:New" then
          F.SetFloatKeyMapping(state.input.popup, v.mode, v.key, function()
            F.SaveSession()
            _layout:update_history()
            vim.api.nvim_buf_set_lines(state.llm.popup.bufnr, 0, -1, false, {})
            vim.api.nvim_feedkeys("A", "n", false)
          end, { noremap = true, silent = true })
        elseif k == "Session:Hide" then
          F.SetFloatKeyMapping(state.input.popup, v.mode, v.key, ToggleLLM, { noremap = true })
        elseif conf.configs.save_session and k == "Input:HistoryNext" then
          F.SetFloatKeyMapping(state.input.popup, v.mode, v.key, function()
            F.MoveHistoryCursor(1)
          end, { noremap = true })
        elseif conf.configs.save_session and k == "Input:HistoryPrev" then
          F.SetFloatKeyMapping(state.input.popup, v.mode, v.key, function()
            F.MoveHistoryCursor(-1)
          end, { noremap = true })
        elseif conf.configs.save_session and k == "Input:ModelsNext" then
          F.SetFloatKeyMapping(state.input.popup, v.mode, v.key, function()
            F.MoveModelsCursor(1)
          end, { noremap = true })
        elseif conf.configs.save_session and k == "Input:ModelsPrev" then
          F.SetFloatKeyMapping(state.input.popup, v.mode, v.key, function()
            F.MoveModelsCursor(-1)
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
      local Split = require("nui.split")
      if filename ~= "" or vim.bo.modifiable == false then
        state.llm.popup = Split({
          relative = "editor",
          position = conf.configs.style,
          size = conf.configs.chat_ui_opts.output.split.size,
          enter = true,
          win_options = conf.configs.chat_ui_opts.output.split.win_options,
          buf_options = conf.configs.chat_ui_opts.output.split.buf_options,
        })
        state.llm.popup:mount()
        winid = state.llm.popup.winid
        bufnr = state.llm.popup.bufnr
      else
        state.llm.popup = {
          winid = winid,
          bufnr = bufnr,
          unmount = function()
            vim.api.nvim_win_close(winid, true)
          end,
          hide = function() end,
          show = function() end,
        }
      end

      -- set keymaps
      for k, v in pairs(conf.configs.keys) do
        if k == "Output:Ask" then
          F.SetSplitKeyMapping(v.mode, v.key, function()
            if state.input.popup then
              if state.input.popup.manual_hidden then
                state.input.popup:show()
                state.input.popup.manual_hidden = nil
                vim.api.nvim_feedkeys("A", "n", false)
              else
                vim.api.nvim_set_current_win(state.input.popup.winid)
                vim.api.nvim_feedkeys("A", "n", false)
              end
            else
              state.input.popup = Popup({
                relative = conf.configs.chat_ui_opts.input.split.relative or conf.configs.chat_ui_opts.relative,
                position = conf.configs.chat_ui_opts.input.split.position,
                enter = conf.configs.chat_ui_opts.input.split.enter,
                focusable = conf.configs.chat_ui_opts.input.split.focusable,
                zindex = conf.configs.chat_ui_opts.input.split.zindex,
                border = conf.configs.chat_ui_opts.input.split.border,
                win_options = conf.configs.chat_ui_opts.input.split.win_options,
                buf_options = conf.configs.chat_ui_opts.input.split.buf_options,
                size = conf.configs.chat_ui_opts.input.split.size,
              })
              state.input.popup:mount()
              vim.api.nvim_set_current_win(state.input.popup.winid)
              vim.api.nvim_command("startinsert")

              for name, d in pairs(conf.configs.keys) do
                if name == "Input:Submit" then
                  F.SetFloatKeyMapping(state.input.popup, d.mode, d.key, function()
                    local input_table = vim.api.nvim_buf_get_lines(state.input.popup.bufnr, 0, -1, true)
                    local input = table.concat(input_table, "\n") .. "\n" .. state.input.attach_content
                    state.session.filename = state.session.filename or "current"
                    if not state.session[state.session.filename] then
                      state.session[state.session.filename] = vim.deepcopy(conf.session.messages)
                    end
                    state.input.popup:unmount()
                    state.input.popup = nil
                    F.UpdatePrompt(state.session.filename)
                    if input ~= "" then
                      table.insert(state.session.changed, state.session.filename)
                      table.insert(state.session[state.session.filename], { role = "user", content = input })
                      F.SetRole(bufnr, winid, "user")
                      F.AppendChunkToBuffer(bufnr, winid, input)
                      F.NewLine(bufnr, winid)
                      if state.input.request_with_lsp ~= nil then
                        state.input.request_with_lsp(function()
                          if F.IsValid(state.input.lsp_ctx.content) then
                            table.insert(state.session[state.session.filename], state.input.lsp_ctx)
                            F.SetRole(bufnr, winid, "user")

                            local symbols_location_info = ""
                            for fname, symbol_location in pairs(state.input.lsp_ctx.symbols_location_list) do
                              for _, sym in pairs(symbol_location) do
                                symbols_location_info = symbols_location_info
                                  .. "\n- "
                                  .. fname
                                  .. "#L"
                                  .. sym.start_row
                                  .. "-"
                                  .. sym.end_row
                                  .. " | "
                                  .. sym.name
                              end
                            end
                            F.AppendChunkToBuffer(
                              bufnr,
                              winid,
                              require("llm.tools.prompts").lsp .. "\n" .. symbols_location_info .. "\n"
                            )
                            F.NewLine(bufnr, winid)
                          end
                          vim.api.nvim_exec_autocmds("User", { pattern = "OpenLLM" })
                          F.ClearAttach()
                        end)
                      else
                        vim.api.nvim_exec_autocmds("User", { pattern = "OpenLLM" })
                      end
                    end
                    vim.api.nvim_set_current_win(state.llm.popup.winid)
                  end, { noremap = true })
                elseif name == "Session:Hide" then
                  F.SetFloatKeyMapping(state.input.popup, d.mode, d.key, function()
                    state.input.popup:hide()
                    state.input.popup.manual_hidden = true
                  end, { noremap = true })
                elseif name == "Session:Close" then
                  F.SetFloatKeyMapping(state.input.popup, d.mode, d.key, function()
                    F.CloseLLM()
                  end, { noremap = true })
                elseif name == "Session:Toggle" or k == "Session:Open" then
                  F.SetFloatKeyMapping(state.input.popup, d.mode, d.key, ToggleLLM, { noremap = true })
                end
              end
            end
          end, { buffer = bufnr, noremap = true, silent = true })
        elseif k == "Session:Toggle" or k == "Session:Open" then
          F.SetSplitKeyMapping(v.mode, v.key, ToggleLLM, { buffer = bufnr, noremap = true, silent = true })
        elseif k == "Session:Close" then
          F.SetSplitKeyMapping(v.mode, v.key, function()
            F.CloseLLM()
          end, { buffer = bufnr, noremap = true, silent = true })
        elseif k == "Session:Hide" then
          F.SetSplitKeyMapping(v.mode, v.key, ToggleLLM, { buffer = bufnr, noremap = true, silent = true })
        elseif k == "Session:New" then
          F.SetSplitKeyMapping(v.mode, v.key, function()
            F.SaveSession()
            vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
          end, { buffer = bufnr, noremap = true, silent = true })
        elseif k == "Session:History" then
          F.SetSplitKeyMapping(v.mode, v.key, function()
            F.HistoryPreview()
          end, { buffer = bufnr, noremap = true, silent = true })
        elseif k == "Session:Models" then
          if conf.configs.models then
            F.SetSplitKeyMapping(v.mode, v.key, function()
              F.ModelsPreview()
            end, { buffer = bufnr, noremap = true, silent = true })
          end
        elseif k == "Output:Cancel" then
          F.SetSplitKeyMapping(v.mode, v.key, F.CancelLLM, { buffer = bufnr, noremap = true, silent = true })
        elseif k == "Output:Resend" then
          F.SetSplitKeyMapping(v.mode, v.key, F.ResendLLM, { buffer = bufnr, noremap = true, silent = true })
        end
      end

      conf.session.status = 1
    end

    vim.api.nvim_set_option_value("buftype", "nofile", { buf = bufnr })
    vim.api.nvim_buf_set_name(bufnr, "[llm-session]")
  else
    ToggleLLM()
  end

  -- copy suggestion code
  local bufnr_list = { state.llm.popup.bufnr }
  if state.input.popup then
    table.insert(bufnr_list, state.input.popup.bufnr)
  end
  local utils = require("llm.tools.utils")
  for _, bufnr in ipairs(bufnr_list) do
    for _, key in ipairs({ "y", "Y" }) do
      vim.api.nvim_buf_set_keymap(bufnr, "n", key, "", {
        callback = function()
          utils.copy_suggestion_code({
            start_str = "```",
            end_str = "```",
          }, table.concat(vim.api.nvim_buf_get_lines(state.llm.popup.bufnr, 0, -1, false), "\n"))
          LOG:INFO("Copy successful!")
        end,
      })
    end
  end
end

return M
