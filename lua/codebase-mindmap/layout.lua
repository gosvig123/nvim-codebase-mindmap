local M = {}

function M.compact_layout(graph)
  local positions = {}

  if graph.root.name == "All Functions" then
    return M.overview_layout(graph)
  end

  local level_groups = {}

  for node_id, node in pairs(graph.nodes) do
    local level = node.level
    level_groups[level] = level_groups[level] or {}
    table.insert(level_groups[level], {
      id = node_id,
      depth = node.depth or 0,
    })
  end

  for level, nodes_at_level in pairs(level_groups) do
    table.sort(nodes_at_level, function(a, b)
      return a.depth < b.depth
    end)
  end

  local y_spacing = 5
  local x_caller_base = 5
  local x_root = 50
  local x_callee_base = 95
  local x_depth_offset = 15

  local root_node = graph.nodes["root"]
  if root_node then
    local root_y = 10

    positions["root"] = {
      x = x_root,
      y = root_y,
      width = math.min(#root_node.name + 4, 35),
      height = 3,
    }
  end

  local callers_by_level = {}
  for level = -3, -1 do
    if level_groups[level] then
      callers_by_level[level] = level_groups[level]
    end
  end

  local current_y = 3
  for level = -3, -1 do
    if callers_by_level[level] then
      for _, node_info in ipairs(callers_by_level[level]) do
        local node = graph.nodes[node_info.id]
        local depth = node.depth or 0
        local x = x_caller_base + (depth * x_depth_offset)

        positions[node_info.id] = {
          x = x,
          y = current_y,
          width = math.min(#node.name + 4, 35),
          height = 3,
        }

        current_y = current_y + y_spacing
      end
    end
  end

  local callees_by_level = {}
  for level = 1, 3 do
    if level_groups[level] then
      callees_by_level[level] = level_groups[level]
    end
  end

  current_y = 3
  for level = 1, 3 do
    if callees_by_level[level] then
      for _, node_info in ipairs(callees_by_level[level]) do
        local node = graph.nodes[node_info.id]
        local depth = node.depth or 0
        local x = x_callee_base + (depth * x_depth_offset)

        positions[node_info.id] = {
          x = x,
          y = current_y,
          width = math.min(#node.name + 4, 35),
          height = 3,
        }

        current_y = current_y + y_spacing
      end
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
