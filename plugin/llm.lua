local state = require("llm.state")
local conf = require("llm.config")
local streaming = require("llm.common.streaming")
local F = require("llm.common.func")

local highlight = {
  LLMBlueNormal = { fg = "#65bcff", bg = "NONE" },
  LLMBlueLight = { fg = "#B0E2FF", bg = "NONE" },
  LlmRedNormal = { fg = "#ff7eb9", bg = "NONE" },
  LlmRedLight = { fg = "#fca7ea", bg = "NONE" },
  LlmGreenNormal = { fg = "#4fd6be", bg = "NONE" },
  LlmGreenLight = { fg = "#b8db87", bg = "NONE" },
  LlmYellowNormal = { fg = "#ff966c", bg = "NONE" },
  LlmYellowLight = { fg = "#f9e2af", bg = "NONE" },
  LlmGrayNormal = { fg = "#828bb8", bg = "NONE" },
  LlmGrayLight = { fg = "#9c9c9c", bg = "NONE" },
}

for k, v in pairs(highlight) do
  vim.api.nvim_set_hl(0, k, v)
end

local function OpenLLM()
  F.SetRole(state.llm.bufnr, state.llm.winid, "assistant")
  state.llm.worker = streaming.GetStreamingOutput(
    state.llm.bufnr,
    state.llm.winid,
    state.session[state.session.filename],
    conf.configs.fetch_key,
    nil,
    nil,
    nil,
    conf.configs.args,
    conf.configs.streaming_handler
  )
end

vim.api.nvim_create_user_command("LLMSessionToggle", function()
  require("llm.session").NewSession()
end, {})

vim.api.nvim_create_user_command("LLMSelectedTextHandler", function(args)
  require("llm.session").LLMSelectedTextHandler(args.fargs[1])
end, { nargs = 1 })

vim.api.nvim_create_user_command("LLMAppHandler", function(args)
  require("llm.app").LLMAppHandler(args.fargs[1])
end, { nargs = 1 })

vim.api.nvim_create_autocmd("User", {
  pattern = "OpenLLM",
  callback = OpenLLM,
})

vim.api.nvim_create_autocmd("VimResized", {
  group = vim.api.nvim_create_augroup("refresh_layout", { clear = true }),
  callback = function()
    if state.layout.popup ~= nil then
      state.layout.popup:update({
        relative = conf.configs.chat_ui_opts.relative,
        position = conf.configs.chat_ui_opts.position,
        size = conf.configs.chat_ui_opts.size,
      })
    end
  end,
})
