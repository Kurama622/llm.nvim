FormulaRecognition = {
  handler = tools.images_handler,
  prompt = "Please convert the formula in the image to LaTeX syntax, and only return the syntax of the formula.",
  opts = {
    url = "http://localhost:11434/api/chat",
    model = "qwen2.5vl:3b",
    fetch_key = vim.env.LOCAL_LLM_KEY,
    api_type = "ollama",
    picker = {
      -- built-in
      cmd = "fd . ~/Pictures/ | xargs -d '\n' ls -t | fzf --no-preview", 

      --[[ fzf-lua
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
      --]]

      --[[ snacks.nvim
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
      --]]
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
