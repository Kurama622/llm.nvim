<!-- mtoc-start -->

* [Picker Style](#picker-style)
  * [Built-in](#built-in)
  * [snacks.nvim's picker](#snacksnvims-picker)
  * [fzf-lua's picker](#fzf-luas-picker)

<!-- mtoc-end -->
## Picker Style
### Built-in

```lua
FormulaRecognition = {
  handler = tools.images_handler,
  prompt = "Please convert the formula in the image to LaTeX syntax, and only return the syntax of the formula.",
  opts = {
    url = "http://localhost:11434/api/chat",
    model = "qwen2.5vl:3b",
    fetch_key = vim.env.LOCAL_LLM_KEY,
    api_type = "ollama",
    picker = {
      --[[ e.g.
           fd . ~/Pictures/ -e png -e jpeg | fzf --no-preview
           find ~/Pictures/ -type f | xargs -d '\n' ls -t | fzf --no-preview
           find ~/Pictures/ -name '*jpeg' -o -name '*png' | xargs -d '\n' ls -t | fzf --no-preview
      ]]
      cmd = "fd . ~/Pictures/ | xargs -d '\n' ls -t | fzf --no-preview",
      -- keymap
      mapping = {
        mode = "i",
        keys = "<C-f>",
      },
    },
    -- use_base64 = true,  -- for siliconflow api
    -- detail = "low", -- for siliconflow api
  },
},
```

### snacks.nvim's picker

```lua
FormulaRecognition = {
  handler = tools.images_handler,
  prompt = "Please convert the formula in the image to LaTeX syntax, and only return the syntax of the formula.",
  opts = {
    url = "http://localhost:11434/api/chat",
    model = "qwen2.5vl:3b",
    fetch_key = vim.env.LOCAL_LLM_KEY,
    api_type = "ollama",

    picker = {
      extern = function(callback)
        require("snacks").picker.files({
          cwd = "~",
          dirs = { "~/Pictures/" },
          -- see: https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#%EF%B8%8F-layouts
          layout = {
            layout = {
              box = "horizontal",
              width = 0.6,
              height = 0.6,
              {
                box = "vertical",
                border = "rounded",
                title = "Finder",
                { win = "input", height = 1, border = "bottom" },
                { win = "list", border = "none" },
              },
              { win = "preview", title = "{preview}", border = "rounded", width = 0.5 },
            },
          },
          actions = {
            confirm = function(picker, item)
              picker:close()
              local path = string.gsub(item._path, " ", "\\ ")
              callback(path)
            end,
          },
          on_close = function()
            callback()
          end,
        })
      end,
      -- keymap
      mapping = {
        mode = "i",
        keys = "<C-f>",
      },
    },
    -- use_base64 = true, -- for siliconflow api
    -- detail = "low",  -- for siliconflow api
  },
},
```

### fzf-lua's picker

```lua
FormulaRecognition = {
  handler = tools.images_handler,
  prompt = "Please convert the formula in the image to LaTeX syntax, and only return the syntax of the formula.",
  opts = {
    url = "http://localhost:11434/api/chat",
    model = "qwen2.5vl:3b",
    fetch_key = vim.env.LOCAL_LLM_KEY,
    api_type = "ollama",

    picker = {
      extern = function(callback)
        require("fzf-lua").files({
          cmd = "fd . ~/Pictures/ -e jpg -e jpeg -e png -e webp | xargs -d '\n' ls -t",
          winopts = {
            height = 0.7,
            width = 0.8,
          },
          actions = {
            default = function(selected)
              local path = string.gsub(selected[1], "^[^%w%p]+%s*", "") --  remove the icon if the file_icon is enable
              path = string.gsub(path, " ", "\\ ")
              callback(path)
            end,
          },
        })
      end,
      -- keymap
      mapping = {
        mode = "i",
        keys = "<C-f>",
      },
    },
    -- use_base64 = true, -- for siliconflow api
    -- detail = "low",  -- for siliconflow api
  },
},
```
