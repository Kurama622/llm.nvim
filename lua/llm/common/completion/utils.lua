-- This file uses code from minuet-ai.nvim
-- Source: https://github.com/milanglacier/minuet-ai.nvim
-- License: GNU General Public License v3.0
-- Copyright (c) minuet-ai.nvim contributors
local state = require("llm.state")
local LOG = require("llm.common.log")
local uv = vim.uv or vim.loop
local utils = {}

function utils.clear_completion() end

---@param job Job
function utils.remove_job(job)
  for i, j in ipairs(state.completion.jobs) do
    if j.pid == job.pid then
      table.remove(state.completion.jobs, i)
      break
    end
  end
end

---@param pid number
local function terminate_job(pid)
  if not uv.kill(pid, 15) then -- SIGTERM
    return false
  end

  return true
end

function utils.terminate_all_jobs()
  for _, job in ipairs(state.completion.jobs) do
    terminate_job(job.pid)
  end
  state.completion.jobs = {}
end

function utils.add_language_comment()
  if vim.bo.ft == nil or vim.bo.ft == "" then
    return ""
  end

  if vim.bo.commentstring == nil or vim.bo.commentstring == "" then
    return "# language: " .. vim.bo.ft
  end

  -- escape % in comment string
  local commentstring = vim.bo.commentstring:gsub("^%% ", "%%%% "):gsub("%%$", "%%%%")

  return string.format(commentstring, string.format("language: %s", vim.bo.ft))
end

function utils.add_tab_comment()
  if vim.bo.ft == nil or vim.bo.ft == "" then
    return ""
  end

  local tab_comment

  if vim.bo.expandtab and vim.bo.softtabstop > 0 then
    tab_comment = "indentation: use " .. vim.bo.softtabstop .. " spaces for a tab"

    if vim.bo.commentstring == nil or vim.bo.commentstring == "" then
      return "# " .. tab_comment
    end

    local commentstring = vim.bo.commentstring:gsub("^%% ", "%%%% "):gsub("%%$", "%%%%")

    return string.format(commentstring, tab_comment)
  end

  if not vim.bo.expandtab then
    tab_comment = "indentation: use \t for a tab"
    if vim.bo.commentstring == nil or vim.bo.commentstring == "" then
      return "# " .. tab_comment
    end

    local commentstring = vim.bo.commentstring:gsub("^%% ", "%%%% "):gsub("%%$", "%%%%")

    return string.format(commentstring, tab_comment)
  end

  return ""
end
-- Copied from blink.cmp.Context. Because we might use nvim-cmp instead of
-- blink-cmp, so blink might not be installed, so we create another class here
-- and use it instead.

--- @class blinkCmpContext
--- @field line string
--- @field cursor number[]

---@param blink_context blinkCmpContext?
function utils.make_cmp_context(blink_context)
  local self = {}
  local cursor
  if blink_context then
    cursor = blink_context.cursor
    self.cursor_line = blink_context.line
  else
    cursor = vim.api.nvim_win_get_cursor(0)
    self.cursor_line = vim.api.nvim_get_current_line()
  end

  self.cursor = {}
  self.cursor.row = cursor[1]
  self.cursor.col = cursor[2] + 1
  self.cursor.line = self.cursor.row - 1
  -- self.cursor.character = require('cmp.utils.misc').to_utfindex(self.cursor_line, self.cursor.col)
  self.cursor_before_line = string.sub(self.cursor_line, 1, self.cursor.col - 1)
  self.cursor_after_line = string.sub(self.cursor_line, self.cursor.col)
  return self
end

function utils.get_context(cmp_context, opts)
  local cursor = cmp_context.cursor
  local lines_before_list = vim.api.nvim_buf_get_lines(0, 0, cursor.line, false)
  local lines_after_list = vim.api.nvim_buf_get_lines(0, cursor.line + 1, -1, false)

  local lines_before = table.concat(lines_before_list, "\n")
  local lines_after = table.concat(lines_after_list, "\n")

  lines_before = lines_before .. "\n" .. cmp_context.cursor_before_line
  lines_after = cmp_context.cursor_after_line .. "\n" .. lines_after

  local n_chars_before = vim.fn.strchars(lines_before)
  local n_chars_after = vim.fn.strchars(lines_after)

  if n_chars_before + n_chars_after > opts.context_window then
    -- use some heuristic to decide the context length of before cursor and after cursor
    if n_chars_before < opts.context_window * opts.context_ratio then
      -- If the context length before cursor does not exceed the maximum
      -- size, we include the full content before the cursor.
      lines_after = vim.fn.strcharpart(lines_after, 0, opts.context_window - n_chars_before)
    elseif n_chars_after < opts.context_window * (1 - opts.context_ratio) then
      -- if the context length after cursor does not exceed the maximum
      -- size, we include the full content after the cursor.
      lines_before = vim.fn.strcharpart(lines_before, n_chars_before + n_chars_after - opts.context_window)
    else
      -- at the middle of the file, use the context_ratio to determine the allocation
      lines_after = vim.fn.strcharpart(lines_after, 0, math.floor(opts.context_window * (1 - opts.context_ratio)))

      lines_before =
        vim.fn.strcharpart(lines_before, n_chars_before - math.floor(opts.context_window * opts.context_ratio))
    end
  end
  return {
    lines_before = lines_before,
    lines_after = lines_after,
  }
end

--- Remove the trailing and leading spaces for each string in the table
---@param item string
function utils.remove_spaces(item)
  if item:find("%S") then -- only include entries that contains non-whitespace
    -- replace the trailing spaces
    item = item:gsub("%s+$", "")
    -- replace the leading spaces
    item = item:gsub("^%s+", "")
  end

  return item
end

--- If the last word of b is not a substring of the first word of a,
--- And it there are no trailing spaces for b and no leading spaces for a,
--- prepend the last word of b to a.
---@param a string?
---@param b string?
---@return string?
function utils.prepend_to_complete_word(a, b)
  if not a or not b then
    return a
  end

  local last_word_b = b:match("[%w_-]+$")
  local first_word_a = a:match("^[%s%w_-]+")

  if last_word_b and first_word_a and not (first_word_a:sub(1, vim.fn.strdisplaywidth(last_word_b)) == last_word_b) then
    a = last_word_b .. a
  end

  return a
end

return utils
