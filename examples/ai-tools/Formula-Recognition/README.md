- builtin
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
      cmd = "find ~/Pictures/ -type f | fzf",
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

- snacks
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
