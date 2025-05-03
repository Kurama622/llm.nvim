local utils = {}
local conf = require("llm.config")
local state = require("llm.state")

function utils.get_params_value(key, opts)
  return opts[key] or conf.configs[key] or (conf.configs.models and conf.configs.models[1][key] or nil)
end

function utils.add_request_body_params(body, key, val)
  if val then
    body[key] = val
  end
end

function utils.reset_io_status()
  -- reset reason header
  state.reason_range.is_begin = false
  state.reason_range.is_end = false
end
return utils
