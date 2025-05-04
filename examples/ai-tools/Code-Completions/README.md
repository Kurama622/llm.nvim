## Code Completions

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
          prefetch_on_insert = false
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

        ---@note Windsurf does not require the following configuration
        providers = {
          llm = {
            name = "llm",
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
  dependencies = { "Kurama622/llm.nvim" },
  optional = true,
  opts = function(_, opts)
    -- if you wish to use autocomplete
    table.insert(opts.sources, 1, {
      name = "llm",
      group_index = 1,
      priority = 100,
    })

    opts.performance = {
      -- It is recommended to increase the timeout duration due to
      -- the typically slower response speed of LLMs compared to
      -- other completion sources. This is not needed when you only
      -- need manual completion.
      fetching_timeout = 5000,
    }
  end,
},

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
    optional = true,
    opts = function(_, opts)
      -- if you wish to use autocomplete
      table.insert(opts.sources, 1, {
        name = "llm",
        group_index = 1,
        priority = 100,
      })

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
      opts.formatting = {
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
      }
      opts.performance = {
        fetching_timeout = 10000,
      }
    end,
  }
```

