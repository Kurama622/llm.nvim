local M = {}

local conf = require("llm.config")
local LOG = require("llm.common.log")
local F = require("llm.common.api")
local streaming = require("llm.common.io.streaming").GetStreamingOutput

local state = require("llm.state")

function M.LLMAppHandler(name, arg_opts)
  if conf.configs.app_handler[name] ~= nil then
    local tool = {
      handler = nil,
      prompt = nil,
      --- @type nil | table
      opts = {
        hook = {},
        mode = arg_opts.mode,
      },
    }

    table.insert(tool.opts.hook, function(bufnr, opts)
      local _table = conf.configs.keys["Session:Models"]
      local _modes = type(_table.mode) == "string" and { _table.mode } or _table.mode
      local _keys = type(_table.key) == "string" and { _table.key } or _table.key
      for i = 1, #_modes do
        for j = 1, #_keys do
          vim.api.nvim_buf_set_keymap(bufnr, _modes[i], _keys[j], "", {
            callback = function()
              F.ModelsPreview(opts, name)
            end,
          })
        end
      end
    end)

    tool = vim.tbl_deep_extend("force", tool, conf.configs.app_handler[name] or {})

    -- Restore the last selected model parameters
    -- The tool has configured its own model.
    if state.models[name] and state.models[name].selected then
      for _, key in pairs(state.model_params) do
        tool.opts[key] = state.models[name].selected[key]
      end

      -- The tool did not specify its own model; instead, it uses the Chat model.
    elseif tool.opts.url == nil and state.models.Chat and state.models.Chat.selected then
      for _, key in pairs(state.model_params) do
        tool.opts[key] = state.models.Chat.selected[key]
      end
    end

    if tool.opts.models then
      F.ModelsPreview(tool.opts, name, function(choice, idx)
        if not choice then
          return
        end
        F.ResetModel(tool.opts, tool.opts, idx)
        -- Each call requires selecting a model, so there is no need to record the selected model information.

        tool.handler(name, F, state, streaming, tool.prompt, tool.opts)
      end)
    else
      tool.handler(name, F, state, streaming, tool.prompt, tool.opts)
    end
  end
end

function M.auto_trigger()
  for name in pairs(conf.configs.app_handler) do
    if conf.configs.app_handler[name].opts and conf.configs.app_handler[name].opts.auto_trigger ~= nil then
      M.LLMAppHandler(name, {})
    end
  end
end
return M
