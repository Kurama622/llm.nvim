local utils = {}
local conf = require("llm.config")
local state = require("llm.state")

function utils.get_params_value(key, opts)
  local val = opts[key]

  if val == nil then
    val = conf.configs[key]
  end

  if val == nil and not vim.tbl_isempty(conf.configs.models) then
    val = conf.configs.models[1][key]
  end

  return val
end

function utils.add_request_body_params(body, key, val)
  body[key] = val
end

function utils.reset_io_status()
  -- reset reason header
  state.reason_range.is_begin = false
  state.reason_range.is_end = false
end
return utils
