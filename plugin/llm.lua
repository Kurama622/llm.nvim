local state = require("llm.state")
local conf = require("llm.config")
local app = require("llm.app")
local F = require("llm.common.api")

local highlight = {
  LlmBlueNormal = { fg = "#65bcff", bg = "NONE", default = true },
  LlmBlueLight = { fg = "#b0e2ff", bg = "NONE", default = true },
  LlmRedNormal = { fg = "#ff7eb9", bg = "NONE", default = true },
  LlmRedLight = { fg = "#fca7ea", bg = "NONE", default = true },
  LlmGreenNormal = { fg = "#4fd6be", bg = "NONE", default = true },
  LlmGreenLight = { fg = "#b8db87", bg = "NONE", default = true },
  LlmYellowNormal = { fg = "#ff966c", bg = "NONE", default = true },
  LlmYellowLight = { fg = "#f9e2af", bg = "NONE", default = true },
  LlmGrayNormal = { fg = "#828bb8", bg = "NONE", default = true },
  LlmGrayLight = { fg = "#9c9c9c", bg = "NONE", default = true },
  LlmPurpleNormal = { fg = "#c099ff", bg = "NONE", default = true },
  LlmPurpleLight = { fg = "#ee82ee", bg = "NONE", default = true },
  LlmWhiteNormal = { fg = "#c8d3f5", bg = "NONE", default = true },
  LlmCmds = { fg = "#2aa198", bg = "NONE", default = true },
  LlmBuffers = { fg = "#2aa198", bg = "NONE", default = true, reverse = true },
}

local llm_augroup = vim.api.nvim_create_augroup("llm_augroup", { clear = true })

for k, v in pairs(highlight) do
  vim.api.nvim_set_hl(0, k, v)
end

local function OpenLLM()
  local streaming = require("llm.common.io.streaming")
  F.SetRole(state.llm.popup.bufnr, state.llm.popup.winid, "assistant")
  streaming.GetStreamingOutput({
    bufnr = state.llm.popup.bufnr,
    winid = state.llm.popup.winid,
    messages = state.session[state.session.filename],
    fetch_key = conf.configs.fetch_key,
    args = conf.configs.args,
    streaming_handler = conf.configs.streaming_handler,
  })
end

vim.api.nvim_create_user_command("LLMSessionToggle", function()
  require("llm.session").NewSession()
end, {})

-- only for in visual mode
vim.api.nvim_create_user_command("LLMSelectedTextHandler", function(args)
  require("llm.session").LLMSelectedTextHandler(args.fargs[1], false, { mode = "v" })
end, { nargs = 1, range = true })

vim.api.nvim_create_user_command("LLMAppHandler", function(args)
  local arg_opts = {}
  if args.count ~= -1 then
    arg_opts.mode = "v"
  end
  app.LLMAppHandler(args.fargs[1], arg_opts)
end, {
  nargs = 1,
  range = true,
  complete = function(arg_lead)
    return vim.tbl_filter(function(item)
      return item:find("^" .. vim.pesc(arg_lead))
    end, vim.tbl_keys(conf.configs.app_handler))
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

vim.api.nvim_create_autocmd("VimLeave", {
  group = vim.api.nvim_create_augroup("llm_exit", { clear = true }),
  callback = function()
    if state.layout.popup ~= nil or state.llm.popup ~= nil then
      F.SaveSession()
    end
  end,
})

vim.api.nvim_create_autocmd("VimResized", {
  group = vim.api.nvim_create_augroup("llm_refresh_layout", { clear = true }),
  callback = function()
    if state.layout.popup ~= nil then
      state.layout.popup:update({
        relative = conf.configs.chat_ui_opts.relative,
        position = conf.configs.chat_ui_opts.position,
        size = conf.configs.chat_ui_opts.size,
      })
    end
    -- Update text, truncating display based on window width
    for _, comp in ipairs({ state.history, state.models }) do
      if comp.popup ~= nil and comp.popup.winid then
        comp.update()
      end
    end
  end,
})

-- Setup syntax highlighting for all llm buffer
local group = "llm.syntax"
vim.api.nvim_create_augroup(group, { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  pattern = "llm",
  group = group,
  callback = vim.schedule_wrap(function(args)
    if vim.bo.ft ~= "llm" then
      return
    end

    local cmds = require("llm.common.cmds")
    local bufnr = args.buf
    for _, item in ipairs(cmds) do
      vim.api.nvim_buf_call(bufnr, function()
        vim.cmd.syntax('match LlmCmds "@' .. item.label .. '"')
      end)
    end
    vim.cmd.syntax('match LlmBuffers "buffer(\\d\\+)"')
  end),
})

-- Setup completion for blink.cmp and cmp
local has_cmp, cmp = pcall(require, "cmp")
local has_blink, blink = pcall(require, "blink.cmp")
if has_blink then
  local name = "LLM_METHODS"
  local source = "llm_methods"
  pcall(function()
    local add_provider = blink.add_source_provider or blink.add_provider
    add_provider(source, {
      name = name,
      module = "llm.common.completion.frontends.blink",
      enabled = true,
      score_offset = 10,
    })
  end)
  pcall(function()
    blink.add_filetype_source("llm", source)
  end)
elseif has_cmp then
  for _, name in ipairs({ "cmd", "buffer", "file" }) do
    cmp.register_source("llm_" .. name, require("llm.common.completion.frontends.cmp." .. name).new())
  end
  cmp.setup.filetype("llm", {
    enabled = true,
    sources = vim.list_extend({
      { name = "llm_cmd", group_index = 1 },
      { name = "llm_buffer", group_index = 1 },
      { name = "llm_file", group_index = 1 },
    }, cmp.get_config().sources),
  })
end
vim.treesitter.language.register("markdown", "llm")
