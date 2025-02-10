## Code Completions

> [!NOTE]
> For Codeium code completion, you need to set up dependencies:
>
> `dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim", "Exafunction/codeium.nvim" }`,
<!-- mtoc-start -->

* [Settings](#settings)
  * [virtual text](#virtual-text)
  * [blink.cmp](#blinkcmp)
  * [nvim-cmp](#nvim-cmp)

<!-- mtoc-end -->

> [!NOTE]
> Your model needs to support FIM (Fill-in-Middle).
>
> In fact, you should also make the most of FIM as it has an advantage in completion, being able to fill in based on context rather than just continuing from the preceding text.

1. You can use `autocmd` to enable the completion feature of llm.nvim.

```lua
vim.api.nvim_create_autocmd({ "VimEnter" }, {
  callback = function()
    vim.api.nvim_command("LLMAppHandler Completion")
  end,
})
```

2. You can make the completion of llm.nvim take effect immediately by disabling lazy loading. (Completion AI tool requires setting `auto_trigger = true`)

```lua
{
  "Kurama622/llm.nvim",
  dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
  lazy = false,
  config = function()
    ...
  end,
}
```

## Settings

### virtual text

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
        toggle = {
          mode = "n",
          keys = "<leader>cp",
        },
      },
    },
  },
}
```

### blink.cmp

Completion AI tool requires setting `style = "blink.cmp"`

- blink.cmp config

```lua
{
    "saghen/blink.cmp",
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

### nvim-cmp

Completion AI tool requires setting `style = "nvim-cmp"`

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
