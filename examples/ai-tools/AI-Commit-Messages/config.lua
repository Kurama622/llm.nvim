CommitMsg = {
  handler = tools.flexi_handler,
  prompt = function()
    return string.format(
      [[You are an expert at following the Conventional Commit specification. Given the git diff listed below, please generate a commit message for me:
1. Start with an action verb (e.g., feat, fix, refactor, chore, etc.), followed by a colon.
2. Briefly mention the file or module name that was changed.
3. Describe the specific changes made.

Examples:
- feat: update common/util.py, added test cases for util.py
- fix: resolve bug in user/auth.py related to login validation
- refactor: optimize database queries in models/query.py

Based on this format, generate appropriate commit messages. Respond with message only. DO NOT format the message in Markdown code blocks, DO NOT use backticks:

```diff
%s
```
]],
      vim.fn.system("git diff --no-ext-diff --staged")
    )
  end,

  opts = {
    enter_flexible_window = true,
    apply_visual_selection = false,
    win_opts = {
      relative = "editor",
      position = "50%",
    },
    accept = {
      mapping = {
        mode = "n",
        keys = "<cr>",
      },
      action = function()
        local contents = vim.api.nvim_buf_get_lines(0, 0, -1, true)
        vim.api.nvim_command(string.format('!git commit -m "%s"', table.concat(contents)))
      end,
    },
  },
},
