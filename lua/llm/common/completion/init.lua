local completion = {}

function completion:init(opts)
  self.opts = opts
  self.backend = require("llm.common.completion.backends")(opts)
  self.frontend = require("llm.common.completion.frontends")(opts)
  if opts.style == "virtual_text" then
    self.frontend:autocmd()
    self.frontend:keymap()
  end
end

return completion
