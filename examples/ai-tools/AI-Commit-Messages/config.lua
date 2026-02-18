CommitMsg = {
  handler = "flexi_handler",
  prompt = function()
    -- Source: https://andrewian.dev/blog/ai-git-commits
    return string.format(
      [[You are an expert at following the Conventional Commit specification. Given the git diff listed below, please generate a commit message for me:

1. First line: conventional commit format (type: concise description) (remember to use semantic types like feat, fix, docs, style, refactor, perf, test, chore, etc.)
2. Optional bullet points if more context helps:
   - Keep the second line blank
   - Keep them short and direct
   - Focus on what changed
   - Always be terse
   - Don't overly explain
   - Drop any fluffy or formal language

Return ONLY the commit message - no introduction, no explanation, no quotes around it.

Examples:
feat: add user auth system

- Add JWT tokens for API auth
- Handle token refresh for long sessions

fix: resolve memory leak in worker pool

- Clean up idle connections
- Add timeout for stale workers

Simple change example:
fix: typo in README.md

Very important: Do not respond with any of the examples. Your message must be based off the diff that is about to be provided, with a little bit of styling informed by the recent commits you're about to see.

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

        local cmd = string.format('!git commit -m "%s"', table.concat(contents, '" -m "'))
        cmd = (cmd:gsub(".", {
          ["#"] = "\\#",
          ["%"] = "\\%",
        }))

        vim.api.nvim_command(cmd)
        -- just for lazygit
        vim.schedule(function()
          vim.api.nvim_command("LazyGit")
        end)
      end,
    },
  },
},
