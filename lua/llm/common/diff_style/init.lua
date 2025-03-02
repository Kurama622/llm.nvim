local conf = require("llm.config")

local diff = { style = nil }

---@return Diff|MiniDiff
function diff:update()
  local instance = nil
  if conf.configs.display.diff.provider == "default" then
    instance = require("llm.common.diff_style.default")
  elseif conf.configs.display.diff.provider == "mini_diff" then
    instance = require("llm.common.diff_style.mini_diff")
  end
  setmetatable(self, { __index = instance })
  return self
end

return diff
