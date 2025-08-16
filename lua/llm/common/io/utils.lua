local utils = {}
local conf = require("llm.config")
local state = require("llm.state")
local F = require("llm.common.api")

function utils.get_params_value(key, opts)
  local val = opts[key]

  -- opts already configured
  if not F.IsValid(opts.url) then
    if val == nil then
      val = conf.configs[key]
    end

    if conf.configs.url == nil and val == nil and F.IsValid(conf.configs.models) then
      val = conf.configs.models[1][key]
    end
  end

  return val
end

function utils.add_request_body_params(body, key, val, api_type)
  if api_type == "ollama" then
    if key == "temperature" or key == "top_p" then
      body.options[key] = val
    elseif key == "enable_thinking" then
      body.think = val
    else
      body[key] = val
    end
  else
    body[key] = val
  end
end

function utils.reset_io_status(opts)
  -- reset reason header
  state.reason_range.is_begin = false
  state.reason_range.is_end = false
  opts.args = state.args_template
end

function utils.gen_messages(ctx)
  local msg = { role = "assistant", content = ctx.assistant_output }
  if F.IsValid(ctx.reasoning_content) then
    msg["_llm_reasoning_content"] = ctx.reasoning_content
  end
  return msg
end

return utils
