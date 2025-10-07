local M = {}

function M.create_canvas(width, height)
  local canvas = {}
  canvas.data = {}
  canvas.priority = {}

  for y = 1, height do
    canvas.data[y] = {}
    canvas.priority[y] = {}
    for x = 1, width do
      canvas.data[y][x] = " "
      canvas.priority[y][x] = 0
    end
  end

  return canvas
end

function M.set_char(canvas, x, y, char, priority)
  priority = priority or 1

  if y < 1 or y > #canvas.data or x < 1 or x > #canvas.data[1] then
    return
  end

  if canvas.priority[y][x] <= priority then
    canvas.data[y][x] = char
    canvas.priority[y][x] = priority
  end
end

function M.draw_arrow(canvas, x1, y1, x2, y2)
  if y1 == y2 then
    for x = x1, x2 - 1 do
      if x == x1 then
        M.set_char(canvas, x, y1, "●", 2)
      else
        M.set_char(canvas, x, y1, "─", 1)
      end
    end
    M.set_char(canvas, x2, y2, "▶", 2)
  else
    local mid_x = x1 + 3

    for x = x1, mid_x do
      if x == x1 then
        M.set_char(canvas, x, y1, "●", 2)
      else
        M.set_char(canvas, x, y1, "─", 1)
      end
    end

    local start_y = math.min(y1, y2)
    local end_y = math.max(y1, y2)

    for y = start_y, end_y do
      if y == y1 and y1 < y2 then
        M.set_char(canvas, mid_x, y, "┐", 2)
      elseif y == y1 and y1 > y2 then
        M.set_char(canvas, mid_x, y, "┘", 2)
      elseif y == y2 and y2 > y1 then
        M.set_char(canvas, mid_x, y, "└", 2)
      elseif y == y2 and y2 < y1 then
        M.set_char(canvas, mid_x, y, "┌", 2)
      else
        M.set_char(canvas, mid_x, y, "│", 1)
      end
    end

    for x = mid_x + 1, x2 - 1 do
      M.set_char(canvas, x, y2, "─", 1)
    end
    M.set_char(canvas, x2, y2, "▶", 2)
  end
end

function M.draw_box(canvas, x, y, width, height, text, style, is_selected)
  style = style or "single"

  local borders = {
    single = { tl = "┌", tr = "┐", bl = "└", br = "┘", h = "─", v = "│" },
    double = { tl = "╔", tr = "╗", bl = "╚", br = "╝", h = "═", v = "║" },
    rounded = { tl = "╭", tr = "╮", bl = "╰", br = "╯", h = "─", v = "│" },
  }

  local b = borders[style]
  local priority = is_selected and 6 or 5

  if y >= 1 and y <= #canvas.data then
    if x >= 1 and x <= #canvas.data[1] then
      M.set_char(canvas, x, y, b.tl, priority)
    end
    if x + width - 1 <= #canvas.data[1] then
      M.set_char(canvas, x + width - 1, y, b.tr, priority)
    end
  end

  if y + height - 1 >= 1 and y + height - 1 <= #canvas.data then
    if x >= 1 and x <= #canvas.data[1] then
      M.set_char(canvas, x, y + height - 1, b.bl, priority)
    end
    if x + width - 1 <= #canvas.data[1] then
      M.set_char(canvas, x + width - 1, y + height - 1, b.br, priority)
    end
  end

  for i = 1, width - 2 do
    if x + i >= 1 and x + i <= #canvas.data[1] then
      if y >= 1 and y <= #canvas.data then
        M.set_char(canvas, x + i, y, b.h, priority)
      end
      if y + height - 1 >= 1 and y + height - 1 <= #canvas.data then
        M.set_char(canvas, x + i, y + height - 1, b.h, priority)
      end
    end
  end

  for i = 1, height - 2 do
    if y + i >= 1 and y + i <= #canvas.data then
      if x >= 1 and x <= #canvas.data[1] then
        M.set_char(canvas, x, y + i, b.v, priority)
      end
      if x + width - 1 >= 1 and x + width - 1 <= #canvas.data[1] then
        M.set_char(canvas, x + width - 1, y + i, b.v, priority)
      end
    end
  end

  local text_y = y + math.floor(height / 2)
  local padding = 3
  local text_x = x + padding
  
  local available_width = width - (padding * 2)
  local display_text = text
  
  if #text > available_width then
    display_text = text:sub(1, available_width - 3) .. "..."
  end

  if text_y >= 1 and text_y <= #canvas.data then
    for i = 1, #display_text do
      if text_x + i - 1 >= 1 and text_x + i - 1 <= #canvas.data[1] then
        M.set_char(canvas, text_x + i - 1, text_y, display_text:sub(i, i), priority + 1)
      end
    end
  end
end

function M.render(graph, positions, selected_node)
  local max_x = 0
  local max_y = 0

  for _, pos in pairs(positions) do
    max_x = math.max(max_x, pos.x + pos.width + 5)
    max_y = math.max(max_y, pos.y + pos.height + 2)
  end

  max_x = math.max(max_x, 100)
  max_y = math.max(max_y, 35)

  local canvas = M.create_canvas(max_x, max_y)

  local has_callers = false
  local has_callees = false
  for node_id, node in pairs(graph.nodes) do
    if node.kind == "Caller" then has_callers = true end
    if node.kind == "Callee" then has_callees = true end
  end

  if has_callers then
    local header = "◄ CALLERS"
    for i = 1, #header do
      M.set_char(canvas, 15 + i - 1, 1, header:sub(i, i), 10)
    end
  end

  if has_callees then
    local header = "CALLEES ►"
    for i = 1, #header do
      M.set_char(canvas, 130 + i - 1, 1, header:sub(i, i), 10)
    end
  end

  for _, edge in ipairs(graph.edges) do
    local from_pos = positions[edge.from]
    local to_pos = positions[edge.to]

    if from_pos and to_pos then
      local from_node = graph.nodes[edge.from]
      local to_node = graph.nodes[edge.to]
      
      local x1, y1, x2, y2
      
      if from_node and from_node.kind == "Caller" then
        x1 = from_pos.x + from_pos.width
        y1 = from_pos.y + 1
        x2 = to_pos.x - 1
        y2 = to_pos.y + 1
      else
        x1 = from_pos.x + from_pos.width
        y1 = from_pos.y + 1
        x2 = to_pos.x - 1
        y2 = to_pos.y + 1
      end

      M.draw_arrow(canvas, x1, y1, x2, y2)
    end
  end

  for node_id, pos in pairs(positions) do
    local node = graph.nodes[node_id]
    if node then
      local style = node.level == 0 and "double" or "rounded"
      local is_selected = (node_id == selected_node)
      M.draw_box(canvas, pos.x, pos.y, pos.width, pos.height, node.name, style, is_selected)
    end
  end

  local lines = {}
  for _, row in ipairs(canvas.data) do
    table.insert(lines, table.concat(row))
  end

  return lines
end

return M
