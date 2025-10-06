local M = {}

local function count_subtree_size(graph, node_id)
  local node = graph.nodes[node_id]
  if not node or not node.children or #node.children == 0 then
    return 1
  end
  
  local size = 1
  for _, child_id in ipairs(node.children) do
    size = size + count_subtree_size(graph, child_id)
  end
  return size
end

local function layout_tree_recursive(graph, node_id, positions, x, y, x_offset, y_spacing, is_caller)
  local node = graph.nodes[node_id]
  if not node then return y end
  
  positions[node_id] = {
    x = x,
    y = y,
    width = math.min(#node.name + 4, 35),
    height = 3,
  }
  
  local current_y = y
  
  if node.children and #node.children > 0 then
    current_y = current_y + y_spacing
    
    for _, child_id in ipairs(node.children) do
      current_y = layout_tree_recursive(
        graph, 
        child_id, 
        positions, 
        x + x_offset, 
        current_y, 
        x_offset, 
        y_spacing,
        is_caller
      )
    end
  end
  
  return math.max(y + y_spacing, current_y)
end

function M.compact_layout(graph)
  local positions = {}

  if graph.root.name == "All Functions" then
    return M.overview_layout(graph)
  end

  local y_spacing = 4
  local x_offset = 35
  local x_root = 60
  
  local root_node = graph.nodes["root"]
  if not root_node then
    return positions
  end
  
  local caller_count = 0
  local callee_count = 0
  
  for node_id, node in pairs(graph.nodes) do
    if node.kind == "Caller" and node.depth == 0 then
      caller_count = caller_count + 1
    elseif node.kind == "Callee" and node.depth == 0 then
      callee_count = callee_count + 1
    end
  end
  
  local total_callers_height = caller_count * y_spacing
  local total_callees_height = callee_count * y_spacing
  local max_height = math.max(total_callers_height, total_callees_height)
  
  local root_y = math.max(3, math.floor(max_height / 2))
  
  positions["root"] = {
    x = x_root,
    y = root_y,
    width = math.min(#root_node.name + 4, 35),
    height = 3,
  }
  
  local caller_y = 2
  for node_id, node in pairs(graph.nodes) do
    if node.kind == "Caller" and node.depth == 0 then
      caller_y = layout_tree_recursive(
        graph,
        node_id,
        positions,
        x_root - x_offset - 5,
        caller_y,
        -x_offset,
        y_spacing,
        true
      )
    end
  end
  
  local callee_y = 2
  for node_id, node in pairs(graph.nodes) do
    if node.kind == "Callee" and node.depth == 0 then
      callee_y = layout_tree_recursive(
        graph,
        node_id,
        positions,
        x_root + 40,
        callee_y,
        x_offset,
        y_spacing,
        false
      )
    end
  end

  return positions
end

function M.overview_layout(graph)
  local positions = {}

  local functions = {}
  for node_id, node in pairs(graph.nodes) do
    if node.level == 1 then
      table.insert(functions, node_id)
    end
  end

  table.sort(functions, function(a, b)
    return graph.nodes[a].name < graph.nodes[b].name
  end)

  local cols = 4
  local col_width = 35
  local row_height = 5
  local x_start = 5
  local y_start = 3

  for i, func_id in ipairs(functions) do
    local col = (i - 1) % cols
    local row = math.floor((i - 1) / cols)

    local node = graph.nodes[func_id]

    positions[func_id] = {
      x = x_start + (col * col_width),
      y = y_start + (row * row_height),
      width = math.min(#node.name + 4, 32),
      height = 3,
    }
  end

  return positions
end

function M.tree_layout(graph)
  return M.compact_layout(graph)
end

function M.wide_layout(graph)
  local positions = M.compact_layout(graph)

  if graph.root.name ~= "All Functions" then
    for _, pos in pairs(positions) do
      pos.x = math.floor(pos.x * 1.3)
    end
  end

  return positions
end

function M.radial_layout(graph)
  return M.compact_layout(graph)
end

return M
