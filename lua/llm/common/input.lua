local M = {}

local _popup = require("nui.popup")
local conf = require("llm.config")
local state = require("llm.state")
local F = require("llm.common.func")

function M.SetInput(bufnr, winid)
  local input_popup = _popup(conf.configs.input_box_opts)
  state.input.popup = input_popup

  -- set keymaps
  for k, v in pairs(conf.configs.keys) do
    if k == "Input:Submit" then
      F.WinMapping(input_popup, v.mode, v.key, function()
        local input_table = vim.api.nvim_buf_get_lines(input_popup.bufnr, 0, -1, true)
        local input = table.concat(input_table, "\n")
        if conf.configs.style ~= "float" then
          state.session.filename = "current"
          if not state.session[state.session.filename] then
            state.session[state.session.filename] = F.DeepCopy(conf.session.messages)
          end
          input_popup:unmount()
        else
          if not conf.configs.save_session then
            state.session.filename = "current"
            if not state.session[state.session.filename] then
              state.session[state.session.filename] = F.DeepCopy(conf.session.messages)
            end
          end
          vim.api.nvim_buf_set_lines(input_popup.bufnr, 0, -1, false, {})
        end
        if input ~= "" then
          table.insert(state.session[state.session.filename], { role = "user", content = input })
          F.SetRole(bufnr, winid, "user")
          F.AppendChunkToBuffer(bufnr, winid, input)
          F.NewLine(bufnr, winid)
          vim.api.nvim_exec_autocmds("User", { pattern = "OpenLLM" })
        end
      end, { noremap = true })
    elseif k == "Input:Cancel" and conf.configs.style == "float" then
      F.WinMapping(input_popup, v.mode, v.key, F.CancelLLM, { noremap = true, silent = true })
    elseif k == "Input:Resend" and conf.configs.style == "float" then
      F.WinMapping(input_popup, v.mode, v.key, F.ResendLLM, { noremap = true, silent = true })
    elseif k == "Session:Close" then
      F.WinMapping(input_popup, v.mode, v.key, function()
        input_popup:unmount()
        if conf.configs.style == "float" then
          vim.api.nvim_exec_autocmds("User", { pattern = "CloseLLM" })
          vim.api.nvim_exec_autocmds("User", { pattern = "CloseHistory" })
        end
        conf.session.status = -1
        vim.api.nvim_command("doautocmd BufEnter")
      end, { noremap = true })
    elseif k == "Session:Toggle" and conf.configs.style == "float" then
      F.WinMapping(input_popup, v.mode, v.key, F.ToggleLLM, { noremap = true })
    elseif conf.configs.save_session and k == "Input:HistoryNext" and conf.configs.style == "float" then
      F.WinMapping(input_popup, v.mode, v.key, function()
        F.MoveHistoryCursor(1)
      end, { noremap = true })
    elseif conf.configs.save_session and k == "Input:HistoryPrev" and conf.configs.style == "float" then
      F.WinMapping(input_popup, v.mode, v.key, function()
        F.MoveHistoryCursor(-1)
      end, { noremap = true })
    end
  end

  input_popup:mount()
  vim.api.nvim_command("startinsert")
end

return M
