local LOG = require("llm.common.log")
local completion = {}

function completion.set_suggestion_hl()
  local hlgroup = "LLMCodeSuggestion"
  vim.api.nvim_set_hl(0, hlgroup, { link = "Comment", default = true })
end

function completion:init(opts)
  self.opts = opts
  self.backend = require("llm.common.completion.backends")(opts)
  self.set_suggestion_hl()
  if opts.api_type == "codeium" then
    if opts.style == "virtual_text" then
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
      pcall(vim.api.nvim_set_hl, 0, "CodeiumSuggestion", { link = "LLMCodeSuggestion", default = true })
    elseif opts.style == "nvim-cmp" then
      local codeium_opts = {
        enable_cmp_source = true,
      }
      require("codeium").setup(codeium_opts)

      for _, ft in pairs(require("cmp").core.sources) do
        if ft.name == "codeium" then
          ft.name = "llm"
        end
      end
    elseif opts.style == "blink.cmp" then
      local codeium_opts = {
        enable_cmp_source = false,
      }
      require("codeium").setup(codeium_opts)
      local has_blink, blink = pcall(require, "blink.cmp")
      if has_blink then
        local add_provider = blink.add_source_provider or blink.add_provider
        add_provider("llm", {
          name = "llm",
          module = "codeium.blink",
          enabled = true,
          score_offset = 10,
          async = true,
        })
      else
        LOG:INFO("Please ensure that blink.cmp has been correctly installed.")
      end
    end
    vim.api.nvim_set_keymap(opts.keymap.toggle.mode, opts.keymap.toggle.keys, "", {
      callback = function()
        vim.api.nvim_command("Codeium Toggle")
      end,
      desc = "Toggle Windsurf (codeium) Completion",
      noremap = true,
      silent = true,
    })
  else
    self.frontend = require("llm.common.completion.frontends")(opts)

    if opts.style == "virtual_text" then
      self.frontend:autocmd()
    end
    self.frontend:keymap()
  end
end

return completion
