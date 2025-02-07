local LOG = require("llm.common.log")
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

    vim.api.nvim_set_keymap(opts.keymap.virtual_text.toggle.mode, opts.keymap.virtual_text.toggle.keys, "", {
      callback = function()
        local codeium_virt_opts = require("codeium.config").options.virtual_text
        LOG:INFO("Enable codeium completion: " .. tostring(codeium_virt_opts.manual))
        codeium_virt_opts.manual = not codeium_virt_opts.manual
      end,
      noremap = true,
      silent = true,
    })
  elseif opts.style == "virtual_text" then
    self.frontend:autocmd()
    self.frontend:keymap()
  end
end

return completion
