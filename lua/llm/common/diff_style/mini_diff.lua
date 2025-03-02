---Utilising the awesome:
---https://github.com/echasnovski/mini.diff

local ok, diff = pcall(require, "mini.diff")
if not ok then
  return vim.notify(string.format("Failed to load mini.diff: %s", diff), vim.log.levels.ERROR)
end

local api = vim.api

local current_source

---@class MiniDiff
---@field bufnr number The buffer number of the original buffer
---@field contents string[] The contents of the original buffer
---@field valid boolean Whether the diff is valid
local MiniDiff = { style = "MiniDiff" }

---@param args DiffArgs
---@return MiniDiff
function MiniDiff.new(args)
  local self = setmetatable({
    bufnr = args.bufnr,
    contents = args.contents,
  }, { __index = MiniDiff })

  MiniDiff.valid = true
  -- Capture the current source before we disable it
  if vim.b.minidiff_summary then
    current_source = vim.b.minidiff_summary["source_name"]
  end
  diff.disable(self.bufnr)

  -- Change the buffer source
  vim.b[self.bufnr].minidiff_config = {
    source = {
      name = "codecompanion",
      attach = function(bufnr)
        diff.set_ref_text(bufnr, self.contents)
        diff.toggle_overlay(self.bufnr)
      end,
      detach = function(bufnr)
        self:teardown()
      end,
    },
  }

  diff.enable(self.bufnr)

  return self
end

---Accept the diff
---@return nil
function MiniDiff:accept()
  vim.b[self.bufnr].minidiff_config = nil
  diff.disable(self.bufnr)
  MiniDiff.valid = false
end

---Reject the diff
---@return nil
function MiniDiff:reject()
  api.nvim_buf_set_lines(self.bufnr, 0, -1, true, self.contents)

  vim.b[self.bufnr].minidiff_config = nil
  diff.disable(self.bufnr)
  MiniDiff.valid = false
end

---Close down mini.diff
---@return nil
function MiniDiff:teardown()
  -- Revert the source
  if current_source then
    vim.b[self.bufnr].minidiff_config = diff.gen_source[current_source]()
    diff.enable(self.bufnr)
    current_source = nil
    MiniDiff.valid = false
  end
end

return MiniDiff
