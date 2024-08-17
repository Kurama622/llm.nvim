local M = {}

local _popup = require("nui.popup")
local conf = require("llm.config")
local layout = require("llm.layout")
local F = require("llm.common.func")

function M.SetInput(bufnr, winid, messages)
  local input_popup = _popup(conf.configs.input_box_opts)
  layout.input.popup = input_popup

  -- set keymaps
  for k, v in pairs(conf.configs.keys) do
    if k == "Input:Submit" then
      input_popup:map(v.mode, v.key, function()
        local input_table = vim.api.nvim_buf_get_lines(input_popup.bufnr, 0, -1, true)
        local input = table.concat(input_table, "\n")
        if conf.configs.output_box_opts.style ~= "float" then
          input_popup:unmount()
        else
          vim.api.nvim_buf_set_lines(input_popup.bufnr, 0, -1, false, {})
        end
        if input ~= "" then
          table.insert(messages, { role = "user", content = input })
          F.SetRole(bufnr, winid, "User")
          F.AppendChunkToBuffer(bufnr, winid, input)
          F.NewLine(bufnr, winid)
          vim.api.nvim_exec_autocmds("User", { pattern = "OpenLLM" })
        end
      end, { noremap = true })
    elseif k == "Input:Cancel" and conf.configs.output_box_opts.style == "float" then
      input_popup:map(v.mode, v.key, F.CancelLLM, { noremap = true, silent = true })
    elseif k == "Input:Resend" and conf.configs.output_box_opts.style == "float" then
      input_popup:map(v.mode, v.key, F.ResendLLM, { noremap = true, silent = true })
    elseif k == "Session:Close" then
      input_popup:map(v.mode, v.key, function()
        input_popup:unmount()
        if conf.configs.output_box_opts.style == "float" then
          vim.api.nvim_exec_autocmds("User", { pattern = "CloseLLM" })
        end
        conf.session.status = -1
      end, { noremap = true })
    elseif k == "Session:Toggle" and conf.configs.output_box_opts.style == "float" then
      input_popup:map(v.mode, v.key, F.ToggleLLM, { noremap = true })
    end
  end

  input_popup:mount()
  vim.api.nvim_command("startinsert")
end

return M
