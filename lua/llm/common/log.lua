local LOG = {}

function LOG:setup(enable_trace, log_level)
  self.enable_trace = enable_trace
  self.log_level = log_level
  self.plugin_name = "llm.nvim"
end

function LOG:DEBUG(msg)
  if self.log_level <= 0 then
    vim.notify(msg, vim.log.levels.DEBUG, { title = self.plugin_name })
  end
end

function LOG:INFO(msg)
  if self.log_level <= 1 then
    vim.notify(msg, vim.log.levels.INFO, { title = self.plugin_name })
  end
end

function LOG:WARN(msg)
  if self.log_level <= 2 then
    vim.notify(msg, vim.log.levels.WARN, { title = self.plugin_name })
  end
end

function LOG:ERROR(msg)
  if self.log_level <= 3 then
    vim.notify(msg, vim.log.levels.ERROR, { title = self.plugin_name })
  end
end

function LOG:TRACE(msg)
  if self.enable_trace then
    vim.notify(msg, vim.log.levels.TRACE, { title = self.plugin_name })
  end
end

return LOG
