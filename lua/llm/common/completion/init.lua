local completion = {}

function completion:init(opts)
  self.opts = opts
  self.backend = require("llm.common.completion.backends")(opts)
  self.frontend = require("llm.common.completion.frontends")(opts)

  if opts.api_type == "codeium" and opts.style == "virtual_text" then
    local codeium_opts = {
      enable_cmp_source = false,
      virtual_text = {
        enabled = true,
        filetypes = opts.filetypes,
        default_filetype_enabled = opts.default_filetype_enabled,
        key_bindings = {
          accept = opts.keymap.virtual_text.accept.keys,
          next = opts.keymap.virtual_text.next.keys,
          prev = opts.keymap.virtual_text.prev.keys,
        },
      },
    }
    require("codeium").setup(codeium_opts)
  elseif opts.style == "virtual_text" then
    self.frontend:autocmd()
    self.frontend:keymap()
  end
end

return completion
