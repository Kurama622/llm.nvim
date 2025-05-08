local state = require("llm.state")
local conf = require("llm.config")
local streaming = require("llm.common.io.streaming")
local app = require("llm.app")
local F = require("llm.common.api")

local highlight = {
  LlmBlueNormal = { fg = "#65bcff", bg = "NONE" },
  LlmBlueLight = { fg = "#b0e2ff", bg = "NONE" },
  LlmRedNormal = { fg = "#ff7eb9", bg = "NONE" },
  LlmRedLight = { fg = "#fca7ea", bg = "NONE" },
  LlmGreenNormal = { fg = "#4fd6be", bg = "NONE" },
  LlmGreenLight = { fg = "#b8db87", bg = "NONE" },
  LlmYellowNormal = { fg = "#ff966c", bg = "NONE" },
  LlmYellowLight = { fg = "#f9e2af", bg = "NONE" },
  LlmGrayNormal = { fg = "#828bb8", bg = "NONE" },
  LlmGrayLight = { fg = "#9c9c9c", bg = "NONE" },
  LlmPurpleNormal = { fg = "#c099ff", bg = "NONE" },
  LlmPurpleLight = { fg = "#ee82ee", bg = "NONE" },
  LlmWhiteNormal = { fg = "#c8d3f5", bg = "NONE" },
}

local llm_augroup = vim.api.nvim_create_augroup("llm_augroup", { clear = true })

for k, v in pairs(highlight) do
  vim.api.nvim_set_hl(0, k, v)
end

local function OpenLLM()
  F.SetRole(state.llm.bufnr, state.llm.winid, "assistant")
  state.llm.worker = streaming.GetStreamingOutput({
    bufnr = state.llm.bufnr,
    winid = state.llm.winid,
    messages = state.session[state.session.filename],
    fetch_key = conf.configs.fetch_key,
    args = conf.configs.args,
    streaming_handler = conf.configs.streaming_handler,
  })
end

vim.api.nvim_create_user_command("LLMSessionToggle", function()
  require("llm.session").NewSession()
end, {})

vim.api.nvim_create_user_command("LLMSelectedTextHandler", function(args)
  require("llm.session").LLMSelectedTextHandler(args.fargs[1], false, { mode = "v" })
end, { nargs = 1, range = true })

vim.api.nvim_create_user_command("LLMAppHandler", function(args)
  app.LLMAppHandler(args.fargs[1])
end, {
  nargs = 1,
  range = true,
  complete = function()
    return vim.tbl_keys(conf.configs.app_handler)
  end,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "AutoTrigger",
  group = llm_augroup,
  callback = app.auto_trigger,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "OpenLLM",
  group = llm_augroup,
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

vim.treesitter.language.register("markdown", "llm")
