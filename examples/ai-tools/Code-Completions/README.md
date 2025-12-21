## Code Completions [dev]

> 本功能是应用户要求而开发的，本人并不使用该功能，所以该功能可能并不完善
> This feature is developed in response to user requests, and I do not use this feature myself, so it may not be perfect.

> [!NOTE]
> For Codeium(Windsurf) code completion, you need to set up dependencies:
>
> `dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim", "Exafunction/windsurf.nvim" }`,
<!-- mtoc-start -->

* [Settings](#settings)
  * [Toggle Completion](#toggle-completion)
  * [Completion style](#completion-style)
    * [virtual text](#virtual-text)
    * [blink.cmp](#blinkcmp)
    * [nvim-cmp](#nvim-cmp)
* [UI(Icon)](#uiicon)
  * [blink.cmp](#blinkcmp-1)
  * [nvim-cmp](#nvim-cmp-1)

<!-- mtoc-end -->

> [!NOTE]
> Your model needs to support FIM (Fill-in-Middle).
>
> In fact, you should also make the most of FIM as it has an advantage in completion, being able to fill in based on context rather than just continuing from the preceding text.
>
> **The url used by the code completion tool and the url used by the chat task are usually two different ones.**


## Settings

### Toggle Completion

```lua
Completion = {
  opts = {
    keymap = {
      toggle = {
        mode = "n",
        keys = "<leader>cp",
      },
    },
  },
}
```

### Completion style

#### virtual text

Completion AI tool requires setting `style = "virtual_text"`

Set key mapping for `virtual_text`
```lua
Completion = {
  opts = {
    keymap = {
      virtual_text = {
        accept = {
          mode = "i",
          keys = "<A-a>",
        },
        next = {
          mode = "i",
          keys = "<A-n>",
        },
        prev = {
          mode = "i",
          keys = "<A-p>",
        },
      },
    },
  },
}
```

#### blink.cmp

Completion AI tool requires setting `style = "blink.cmp"`

- blink.cmp config

```lua
{
    "saghen/blink.cmp",
    dependencies = { "Kurama622/llm.nvim" },
    opts = {
      completion = {
        trigger = {
          prefetch_on_insert = false,
          -- allow triggering by white space
          show_on_blocked_trigger_characters = {},
        },
      },

      keymap = {
        ["<C-y>"] = {
          function(cmp)
            cmp.show({ providers = { "llm" } })
          end,
        },
      },

      sources = {
        -- if you want to use auto-complete
        default = { "llm" },

        per_filetype = {
          -- optionally inherit from the `default` sources
          -- e.g. set completion for llm buffer
          -- llm = { inherit_defaults = true, "path" }, -- enable: "llm", "llm_cmds", "path"
          llm = { inherit_defaults = false },   -- enbale: "llm_cmds"
        },

        ---@note Windsurf does not require the following configuration
        providers = {
          llm = {
            name = "LLM",
            module = "llm.common.completion.frontends.blink",
            timeout_ms = 10000,
            score_offset = 100,
            async = true,
          },
        },

      },
    },
  }
```

#### nvim-cmp

Completion AI tool requires setting `style = "nvim-cmp"`

```lua
{
    "hrsh7th/nvim-cmp",
    version = false, -- last release is way too old
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "Kurama622/llm.nvim",
    },

    opts = function()
      -- Register nvim-cmp lsp capabilities
      vim.lsp.config("*", { capabilities = require("cmp_nvim_lsp").default_capabilities() })

      vim.api.nvim_set_hl(0, "CmpGhostText", { link = "Comment", default = true })
      local cmp = require("cmp")
      local defaults = require("cmp.config.default")()
      local auto_select = true
      return {
        auto_brackets = {}, -- configure any filetype to auto add brackets
        completion = {
          completeopt = "menu,menuone,noinsert" .. (auto_select and "" or ",noselect"),
        },
        preselect = auto_select and cmp.PreselectMode.Item or cmp.PreselectMode.None,
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
        }),
        sources = cmp.config.sources({
          { name = "lazydev" },
          { name = "nvim_lsp" },
          { name = "path" },
        }, {
          { name = "buffer" },
          { name = "llm", group_index = 1, priority = 100 },
        }),
        sorting = defaults.sorting,
        performance = {
          -- It is recommended to increase the timeout duration due to
          -- the typically slower response speed of LLMs compared to
          -- other completion sources. This is not needed when you only
          -- need manual completion.
          fetching_timeout = 10000,
        },
      }
    end,
  }
```

## UI(Icon)

### blink.cmp

- only add a icon for llm

```lua
      completion = {
        menu = {
          scrollbar = false,
          border = "rounded",
          winhighlight = "Normal:BlinkCmpMenu,FloatBorder:FloatBorder",

          draw = {
            components = {
              kind_icon = {
                ellipsis = false,
                text = function(ctx)
                  if ctx.item.kind_name == "llm" then
                    return " "
                  else
                    return ctx.kind_icon
                  end
                end,

                highlight = function(ctx)
                  if ctx.item.kind_name == "llm" then
                    return "BlinkCmpKindSnippet"
                  else
                    return ctx.kind_hl
                  end
                end,
              },
            },
          },
        },
        documentation = { window = { border = "rounded" } },
        trigger = {
          prefetch_on_insert = false,
          show_on_blocked_trigger_characters = {},
        },
      },
```

- use `mini.icons`

```lua
      completion = {
        menu = {
          scrollbar = false,
          border = "rounded",
          winhighlight = "Normal:BlinkCmpMenu,FloatBorder:FloatBorder",

          draw = {
            components = {
              kind_icon = {
                ellipsis = false,
                text = function(ctx)
                  local mini_icons = require("mini.icons")
                  local kind_name = ctx.item.kind_name or "lsp"

                  local success, kind_icon, _, _ = pcall(mini_icons.get, kind_name, ctx.kind)
                  if not success then
                    kind_icon = " "
                  end
                  return kind_icon
                end,

                -- Optionally, you may also use the highlights from mini.icons
                highlight = function(ctx)
                  local mini_icons = require("mini.icons")
                  local kind_name = ctx.item.kind_name or "lsp"

                  local success, _, hl, _ = pcall(mini_icons.get, kind_name, ctx.kind)
                  if not success then
                    hl = "BlinkCmpKindSnippet"
                  end
                  return hl
                end,
              },
            },
          },
        },
        documentation = { window = { border = "rounded" } },
        trigger = {
          prefetch_on_insert = false,
          show_on_blocked_trigger_characters = {},
        },
      },
```

### nvim-cmp

```lua
  {
    "hrsh7th/nvim-cmp",
    version = false, -- last release is way too old
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "Kurama622/llm.nvim",
    },

    opts = function()
      local cmp = require("cmp")
      local kind_icons = {
        Text = "",
        Method = "󰆧",
        Function = "󰊕",
        Constructor = "",
        Field = "󰇽",
        Variable = "󰂡",
        Class = "󰠱",
        Interface = "",
        Module = "",
        Property = "󰜢",
        Unit = "",
        Value = "󰎠",
        Enum = "",
        Keyword = "󰌋",
        Snippet = "",
        Color = "󰏘",
        File = "󰈙",
        Reference = "",
        Folder = "󰉋",
        EnumMember = "",
        Constant = "󰏿",
        Struct = "",
        Event = "",
        Operator = "󰆕",
        TypeParameter = "󰅲",
        llm = " ",
      }
      return {
        sources = cmp.config.sources({
          { name = "lazydev" },
          { name = "nvim_lsp" },
          { name = "path" },
        }, {
          { name = "buffer" },
          { name = "llm", group_index = 1, priority = 100 },
        }),
        formatting = {
          format = function(entry, vim_item)
            vim_item.kind = string.format("%s %s", kind_icons[vim_item.kind], vim_item.kind)

            vim_item.menu = ({
              buffer = "[Buffer]",
              nvim_lsp = "[LSP]",
              luasnip = "[LuaSnip]",
              nvim_lua = "[Lua]",
              latex_symbols = "[LaTeX]",
              llm = "[LLM]",
            })[entry.source.name]
            return vim_item
          end,
        },
        performance = {
          fetching_timeout = 10000,
        },
      }
    end,
  }
```

