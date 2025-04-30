local LOG = {}

function LOG:setup(enable_trace, log_level)
  self.enable_trace = enable_trace
  self.log_level = log_level
  self.plugin_name = "llm.nvim"
end

local function format_string(...)
  local args = { ... }
  local n = select("#", ...)

  for i = 1, n do
    local v = args[i]
    if type(v) == "table" then
      args[i] = vim.inspect(v)
    elseif type(v) == "string" then
      args[i] = v
    elseif type(v) == "function" then
      args[i] = "<" .. tostring(v) .. ">"
    else
      args[i] = tostring(v)
    end
  end
  return table.concat(args, " ")
end

function LOG:DEBUG(...)
  if self.log_level <= 0 then
    vim.notify(format_string(...), vim.log.levels.DEBUG, { title = self.plugin_name })
  end
end

function LOG:INFO(...)
  if self.log_level <= 1 then
    vim.notify(format_string(...), vim.log.levels.INFO, { title = self.plugin_name })
  end
end

function LOG:WARN(...)
  if self.log_level <= 2 then
    vim.notify(format_string(...), vim.log.levels.WARN, { title = self.plugin_name })
  end
end

function LOG:ERROR(...)
  if self.log_level <= 3 then
    vim.notify(format_string(...), vim.log.levels.ERROR, { title = self.plugin_name })
  end
end

function LOG:TRACE(...)
  if self.enable_trace then
    vim.notify(format_string(...), vim.log.levels.TRACE, { title = self.plugin_name })
  end
end

return LOG
