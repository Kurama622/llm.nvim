local M = {}

local event = require("nui.utils.autocmd").event
local Popup = require("nui.popup")
local Layout = require("nui.layout")
local NuiText = require("nui.text")
local conf = require("llm.config")

function M.CompareAction(
  bufnr,
  start_str,
  end_str,
  mark_id,
  extmark,
  extmark_opts,
  space_text,
  start_line,
  end_line,
  codeln,
  offset,
  ostr,
  code_hl,
  separator_hl
)
  local pattern = string.format("%s(.-)%s", start_str, end_str)
  local res = ostr:match(pattern)
  if res == nil then
    print("The code block format is incorrect, please manually copy the generated code.")
    return codeln
  end

  -- set highlight
  vim.api.nvim_set_hl(0, "LLMSuggestCode", code_hl)
  vim.api.nvim_set_hl(0, "LLMSeparator", separator_hl)

  for _, v in ipairs({ "raw", "separator", "llm" }) do
    extmark[v] = vim.api.nvim_create_namespace(v)
    local text = v == "raw" and "<<<<<<< " .. v .. space_text
      or v == "separator" and "======= " .. space_text
      or ">>>>>>> " .. v .. space_text
    extmark_opts[v] = {
      virt_text = { { text, "LLMSeparator" } },
      virt_text_pos = "overlay",
    }
  end

  extmark["code"] = vim.api.nvim_create_namespace("code")
  extmark_opts["code"] = {}
  mark_id["code"] = {}

  if offset ~= 0 then
    -- create line to display raw separator virtual text
    F.InsertTextLine(bufnr, 0, "")
  end

  mark_id["raw"] = vim.api.nvim_buf_set_extmark(bufnr, extmark.raw, start_line - 2 + offset, 0, extmark_opts.raw)

  -- create line to display the separator virtual text
  F.InsertTextLine(bufnr, end_line + offset, "")
  mark_id["separator"] =
    vim.api.nvim_buf_set_extmark(bufnr, extmark.separator, end_line + offset, 0, extmark_opts.separator)

  for l in res:gmatch("[^\r\n]+") do
    -- create line to display the code suggested by the LLM
    F.InsertTextLine(bufnr, end_line + codeln + 1 + offset, "")
    extmark_opts.code[codeln] = { virt_text = { { l, "LLMSuggestCode" } }, virt_text_pos = "overlay" }
    mark_id.code[codeln] =
      vim.api.nvim_buf_set_extmark(bufnr, extmark.code, end_line + codeln + 1 + offset, 0, extmark_opts.code[codeln])
    codeln = codeln + 1
  end

  -- create line to display LLM separator virtual text
  F.InsertTextLine(bufnr, end_line + codeln + 1 + offset, "")
  mark_id["llm"] = vim.api.nvim_buf_set_extmark(bufnr, extmark.llm, end_line + codeln + 1 + offset, 0, extmark_opts.llm)
  return codeln
end

function M.action_handler(name, F, state, streaming, prompt, opts)
  if prompt == nil then
    prompt = [[Optimize the code, correct syntax errors, make the code more concise, and enhance reusability.

Provide optimization ideas and the complete code after optimization. Mark the output code block with # BEGINCODE and # ENDCODE.

The indentation of the optimized code should remain consistent with the original code. Here is an example:

The original code is:
<space><space><space><space>def func(a, b)
<space><space><space><space><space><space><space><space>return a + b

Optimization ideas:
1. The function name `func` is not clear. Based on the context, it is determined that this function is meant to implement the functionality of adding two numbers, so the function name is changed to `add`.
2. There is a syntax issue in the function definition; it should end with a colon. It should be `def add(a, b):`.

Since the original code is indented by N spaces, the optimized code is also indented by N spaces.

The optimized code is:

```<language>
# BEGINCODE
<space><space><space><space>def add(a, b):
<space><space><space><space><space><space><space><space>return a + b
# ENDCODE
```

Please optimize this code according to the format, and respond in Chinese.]]
  end

  local options = {
    func = M.CompareAction,
    code_hl = { fg = "#6aa84f", bg = "NONE" },
    separator_hl = { fg = "#6aa84f", bg = "#333333" },
    border = "solid",
    win_options = { winblend = 0, winhighlight = "Normal:Normal" },
    buftype = "nofile",
    spell = false,
    number = true,
    wrap = true,
    linebreak = false,
  }

  options = vim.tbl_deep_extend("force", options, opts or {})
  local fetch_key = options.fetch_key and options.fetch_key or conf.configs.fetch_key

  local start_line, end_line = F.GetVisualSelectionRange()
  local bufnr = vim.api.nvim_get_current_buf()
  local source_content = F.GetVisualSelection()

  local preview_box = Popup({ enter = true, border = options.border, win_options = options.win_options })

  local layout = F.CreateLayout(
    "30%",
    "98%",
    Layout.Box({ Layout.Box(preview_box, { size = "100%" }) }, { dir = "row" }),
    { position = { row = "50%", col = "100%" } }
  )

  layout:mount()

  local mark_id = {}
  local extmark = {}
  local extmark_opts = {}
  local space_text = string.rep(" ", vim.o.columns - 7)
  local start_str = "# BEGINCODE"
  local end_str = "# ENDCODE"
  local codeln = 0
  local offset = start_line == 1 and 1 or 0

  F.SetBoxOpts({ preview_box }, {
    filetype = { "markdown" },
    buftype = options.buftype,
    spell = options.spell,
    number = options.number,
    wrap = options.wrap,
    linebreak = options.linebreak,
  })

  state.app["session"][name] = {}
  table.insert(state.app.session[name], { role = "user", content = prompt .. "\n" .. source_content })

  state.popwin = preview_box
  local worker = streaming(
    preview_box.bufnr,
    preview_box.winid,
    state.app.session[name],
    fetch_key,
    options.url,
    options.model,
    options.api_type,
    nil, -- curl args
    nil, -- streaming handler
    nil, -- stdout handler
    nil, -- stderr handler
    function(ostr) -- exit handler
      codeln = options.func(
        bufnr,
        start_str,
        end_str,
        mark_id,
        extmark,
        extmark_opts,
        space_text,
        start_line,
        end_line,
        codeln,
        offset,
        ostr,
        options.code_hl,
        options.separator_hl
      )
    end
  )

  preview_box:map("n", "<C-c>", function()
    if worker.job then
      worker.job:shutdown()
      worker.job = nil
    end
  end)

  preview_box:map("n", { "<esc>", "N", "n" }, function()
    if worker.job then
      worker.job:shutdown()
      print("Suspend output...")
      vim.wait(200, function() end)
      worker.job = nil
    end
    if codeln ~= 0 then
      vim.api.nvim_buf_del_extmark(bufnr, extmark.raw, mark_id.raw)
      vim.api.nvim_buf_del_extmark(bufnr, extmark.separator, mark_id.separator)
      vim.api.nvim_buf_del_extmark(bufnr, extmark.llm, mark_id.llm)
      for i = 0, codeln - 1 do
        vim.api.nvim_buf_del_extmark(bufnr, extmark.code, mark_id.code[i])
      end

      -- remove the line created to display the code suggested by LLM.
      F.RemoveTextLines(bufnr, end_line + offset, end_line + codeln + 2 + offset)
      if offset ~= 0 then
        -- remove the line created to display the raw separator.
        F.RemoveTextLines(bufnr, 0, 1)
      end
    end
    layout:unmount()
  end)

  preview_box:map("n", { "Y", "y" }, function()
    if codeln ~= 0 then
      vim.api.nvim_buf_del_extmark(bufnr, extmark.raw, mark_id.raw)
      vim.api.nvim_buf_del_extmark(bufnr, extmark.separator, mark_id.separator)
      vim.api.nvim_buf_del_extmark(bufnr, extmark.llm, mark_id.llm)

      -- remove the line created to display the LLM separator.
      F.RemoveTextLines(bufnr, end_line + codeln + 1 + offset, end_line + codeln + 2 + offset)
      -- remove raw code
      F.RemoveTextLines(bufnr, start_line - 1, end_line + 1 + offset)

      for i = 0, codeln - 1 do
        vim.api.nvim_buf_del_extmark(bufnr, extmark.code, mark_id.code[i])
      end

      for i = 0, codeln - 1 do
        -- Write the code suggested by the LLM.
        F.ReplaceTextLine(bufnr, start_line - 1 + i, extmark_opts.code[i].virt_text[1][1])
      end
    end
    layout:unmount()
  end)
end

function M.side_by_side_handler(name, F, state, streaming, prompt, opts)
  local ft = vim.bo.filetype
  if prompt == nil then
    prompt = [[优化代码, 修改语法错误, 让代码更简洁, 增强可复用性，
            你要像copliot那样，直接给出代码内容, 不要使用代码块或其他标签包裹!

            下面是一个例子，假设我们需要优化下面这段代码:
            void test() {
             return 0
            }

            输出格式应该为：
            int test() {
              return 0;
            }

            请按照格式，帮我优化这段代码：]]
  end

  local source_content = F.GetVisualSelection()

  local options = {
    left = {
      title = " Source ",
    },
    right = {
      title = " Preview ",
    },
    buftype = "nofile",
    spell = false,
    number = true,
    wrap = true,
    linebreak = false,
  }

  options = vim.tbl_deep_extend("force", options, opts or {})
  local fetch_key = options.fetch_key and options.fetch_key or conf.configs.fetch_key

  local source_box = F.CreatePopup(options.left.title, false)
  local preview_box = F.CreatePopup(options.right.title, true, { enter = true })

  local layout = F.CreateLayout(
    "80%",
    "55%",
    Layout.Box({
      Layout.Box(source_box, { size = "50%" }),
      Layout.Box(preview_box, { size = "50%" }),
    }, { dir = "row" })
  )

  layout:mount()

  F.SetBoxOpts({ source_box, preview_box }, {
    filetype = { ft, ft },
    buftype = options.buftype,
    spell = options.spell,
    number = options.number,
    wrap = options.wrap,
    linebreak = options.linebreak,
  })

  state.popwin = source_box
  F.WriteContent(source_box.bufnr, source_box.winid, source_content)

  state.app["session"][name] = {}
  table.insert(state.app.session[name], { role = "user", content = prompt .. "\n" .. source_content })

  state.popwin = preview_box
  local worker = streaming(
    preview_box.bufnr,
    preview_box.winid,
    state.app.session[name],
    fetch_key,
    options.url,
    options.model,
    options.api_type
  )

  preview_box:map("n", "<C-c>", function()
    if worker.job then
      worker.job:shutdown()
      worker.job = nil
    end
  end)

  preview_box:map("n", { "<esc>", "N", "n" }, function()
    if worker.job then
      worker.job:shutdown()
      print("Suspend output...")
      vim.wait(200, function() end)
      worker.job = nil
    end
    layout:unmount()
  end)

  preview_box:map("n", { "Y", "y" }, function()
    vim.api.nvim_command("normal! ggVGky")
    layout:unmount()
  end)
end

function M.qa_handler(name, F, state, streaming, prompt, opts)
  if prompt == nil then
    prompt = [[请帮我把这段话翻译成英语, 直接给出翻译结果: ]]
  end

  local options = {
    query = {
      title = " 󰊿 Trans ",
      hl = { link = "CurSearch" },
    },
    buftype = "nofile",
    spell = false,
    number = false,
    wrap = true,
    linebreak = false,
  }

  options = vim.tbl_deep_extend("force", options, opts or {})
  local fetch_key = options.fetch_key and options.fetch_key or conf.configs.fetch_key
  vim.api.nvim_set_hl(0, "LLMQuery", options.query.hl)

  -- print(options.query.hl.fg)

  local input_box = Popup({
    enter = true,
    border = {
      style = "solid",
      text = {
        top = NuiText(options.query.title, "LLMQuery"),
        top_align = "center",
      },
    },
  })

  local separator = Popup({
    border = { style = "none" },
    enter = false,
    focusable = false,
    win_options = { winblend = 0, winhighlight = "Normal:Normal" },
  })

  local preview_box = Popup({
    focusable = true,
    border = { style = "solid", text = { top = "", top_align = "center" } },
  })

  local layout = F.CreateLayout(
    "60%",
    "55%",
    Layout.Box({
      Layout.Box(input_box, { size = "15%" }),
      Layout.Box(separator, { size = "5%" }),
      Layout.Box(preview_box, { size = "80%" }),
    }, { dir = "col" })
  )

  layout:mount()
  vim.api.nvim_command("startinsert")

  F.SetBoxOpts({ preview_box }, {
    filetype = { "markdown", "markdown" },
    buftype = options.buftype,
    spell = options.spell,
    number = options.number,
    wrap = options.wrap,
    linebreak = options.linebreak,
  })

  local worker = { job = nil }

  state.app["session"][name] = {}
  input_box:map("n", "<enter>", function()
    -- clear preview_box content [optional]
    vim.api.nvim_buf_set_lines(preview_box.bufnr, 0, -1, false, {})

    local input_table = vim.api.nvim_buf_get_lines(input_box.bufnr, 0, -1, true)
    local input = table.concat(input_table, "\n")

    -- clear input_box content
    vim.api.nvim_buf_set_lines(input_box.bufnr, 0, -1, false, {})
    if input ~= "" then
      table.insert(state.app.session[name], { role = "user", content = prompt .. "\n" .. input })
      state.popwin = preview_box
      worker = streaming(
        preview_box.bufnr,
        preview_box.winid,
        state.app.session[name],
        fetch_key,
        options.url,
        options.model,
        options.api_type
      )
    end
  end)

  input_box:map("n", { "J", "K" }, function()
    vim.api.nvim_set_current_win(preview_box.winid)
  end)
  preview_box:map("n", { "J", "K" }, function()
    vim.api.nvim_set_current_win(input_box.winid)
  end)

  for _, v in ipairs({ input_box, preview_box }) do
    v:map("n", { "<esc>", "N", "n" }, function()
      if worker.job then
        worker.job:shutdown()
        print("Suspend output...")
        vim.wait(200, function() end)
        worker.job = nil
      end
      layout:unmount()
    end)

    v:map("n", { "Y", "y" }, function()
      vim.api.nvim_set_current_win(preview_box.winid)
      vim.api.nvim_command("normal! ggVGky")
      layout:unmount()
    end)
  end
end

function M.curl_request_handler(url, args)
  for _, v in ipairs(args) do
    url = url .. " " .. v
  end
  local cmd = string.format("curl -s %s ", url)
  local pipe = io.popen(cmd)
  local res = nil
  if pipe ~= nil then
    res = vim.json.decode(pipe:read())
    pipe:close()
  end
  return res
end

function M.flexi_handler(name, F, state, _, prompt, opts)
  local content = prompt .. ":\n" .. F.GetVisualSelection()
  local options = {
    buftype = "nofile",
    spell = false,
    number = false,
    wrap = true,
    linebreak = false,
    exit_on_move = false,
    enter_flexible_window = true,
  }

  options = vim.tbl_deep_extend("force", options, opts or {})
  state.app.session[name] = {}
  table.insert(state.app.session[name], { role = "user", content = content })
  local fetch_key = options.fetch_key and options.fetch_key or conf.configs.fetch_key

  local flexible_box = nil
  F.GetUrlOutput(
    state.app.session[name],
    fetch_key,
    opts.url,
    opts.model,
    opts.api_type,
    nil,
    nil,
    nil,
    nil,
    function(output)
      flexible_box = F.FlexibleWindow(output, options.enter_flexible_window)
      flexible_box:mount()
      flexible_box:map("n", { "<esc>", "N", "n" }, function()
        flexible_box:unmount()
      end)

      F.SetBoxOpts({ flexible_box }, {
        filetype = { "markdown", "markdown" },
        buftype = options.buftype,
        spell = options.spell,
        number = options.number,
        wrap = options.wrap,
        linebreak = options.linebreak,
      })
    end
  )
  local esc = vim.api.nvim_replace_termcodes("<esc>", true, false, true)
  vim.api.nvim_feedkeys(esc, "x", false)
  if options.exit_on_move then
    vim.api.nvim_create_autocmd("CursorMoved", {
      callback = function()
        if flexible_box ~= nil then
          flexible_box:unmount()
        end
      end,
    })
  end
end

return M
