local nui_utils = require("nui.utils")
local LOG = require("llm.common.log")
local Tree = require("nui.tree")
local Popup = require("nui.popup")
local NuiLine = require("nui.line")

local function default_get_node_id(node)
  return node.id
end

local function default_prepare_node(node)
  if not node.text then
    error("missing node.text")
  end
  local texts = node.text

  if type(node.text) ~= "table" or node.text.content then
    texts = { node.text }
  end

  local lines = {}
  for _, text in ipairs(texts) do
    local line = NuiLine()
    line:append(text)
    table.insert(lines, line)
  end
  return lines
end

local dynamic_menu = {}

function dynamic_menu:init(options, configs)
  self.popup = Popup({
    enter = options.enter,
    focusable = options.focusable,
    zindex = options.zindex,
    border = options.border,
    win_options = options.win_options,
  })

  self.popup.tree = Tree({
    bufnr = self.popup.bufnr,
    nodes = {},

    get_node_id = configs.get_node_id or default_get_node_id,
    prepare_node = configs.prepare_node or default_prepare_node,
  })

  self.update = configs.update or function() end
  self.popup._.on_change = configs.on_change or function(item) end
  return self
end

function dynamic_menu:new(options, configs)
  local instance = setmetatable({}, { __index = self })
  return instance:init(options, configs)
end

return setmetatable(dynamic_menu, {
  __call = function(_, options, configs)
    return dynamic_menu:new(options, configs)
  end,
})
