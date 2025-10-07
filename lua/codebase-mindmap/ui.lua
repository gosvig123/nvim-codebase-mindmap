local graph_module = require("codebase-mindmap.graph")
local graph_async = require("codebase-mindmap.graph_async")
local layout = require("codebase-mindmap.layout")
local render = require("codebase-mindmap.render")

local M = {}
local state = {
  bufnr = nil,
  winnr = nil,
  graph = nil,
  positions = nil,
  current_layout = "compact",
  current_title = "",
  selected_node = nil,
  node_list = {},
  source_bufnr = nil,
  all_functions = {},
}

function M.show_file_map()
  local bufnr = vim.api.nvim_get_current_buf()
  state.source_bufnr = bufnr
  local filename = vim.fn.expand("%:t")

  if filename == "" then
    vim.notify("No file open", vim.log.levels.WARN)
    return
  end

  local clients = vim.lsp.get_active_clients({ bufnr = bufnr })
  if #clients == 0 then
    vim.notify("No LSP client attached. Start LSP first.", vim.log.levels.WARN)
    return
  end

  vim.notify("Finding symbol at cursor...", vim.log.levels.INFO)

  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1] - 1
  local col = cursor[2]

  local params = {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    position = { line = line, character = col },
  }

  for _, client in ipairs(clients) do
    if client.server_capabilities.documentSymbolProvider then
      client.request("textDocument/documentSymbol", params, function(err, result)
        if err or not result then
          vim.notify("No LSP symbols available", vim.log.levels.WARN)
          return
        end

        local function find_enclosing(symbols, target_line, target_col)
          for _, symbol in ipairs(symbols) do
            local range = symbol.range or symbol.location and symbol.location.range
            if range then
              local start_line = range.start.line
              local end_line = range["end"].line

              if target_line >= start_line and target_line <= end_line then
                if symbol.children and #symbol.children > 0 then
                  local child_result = find_enclosing(symbol.children, target_line, target_col)
                  if child_result then
                    return child_result
                  end
                end
                return symbol
              end
            end
          end
          return nil
        end

        local symbol = find_enclosing(result, line, col)

        if not symbol then
          vim.notify("No function/method found at cursor. Place cursor inside a function.", vim.log.levels.WARN)
          return
        end

        local symbol_name = symbol.name or "Unknown"

        vim.notify("Building call graph for " .. symbol_name .. "...", vim.log.levels.INFO)

        graph_async.build_function_call_graph_async(bufnr, symbol, function(graph)
          if not graph then
            vim.notify("Could not build call graph for " .. symbol_name, vim.log.levels.WARN)
            return
          end

          state.graph = graph
          state.current_title = "Function: " .. symbol_name
          state.selected_node = "root"

          local caller_count = 0
          local callee_count = 0

          for _, node in pairs(state.graph.nodes) do
            if node.level == -1 or node.level == -2 or node.level == -3 then
              caller_count = caller_count + 1
            end
            if node.level == 1 or node.level == 2 or node.level == 3 then
              callee_count = callee_count + 1
            end
          end

          if caller_count == 0 and callee_count == 0 then
            vim.notify(string.format("%s has no callers or callees in codebase", symbol_name), vim.log.levels.INFO)
          else
            vim.notify(
              string.format("%s: %d callers, %d callees", symbol_name, caller_count, callee_count),
              vim.log.levels.INFO
            )
          end

          M.render_with_layout(state.current_layout, state.current_title)
        end)
      end)
      
      return
    end
  end

  vim.notify("No LSP with documentSymbolProvider available", vim.log.levels.WARN)
end

function M.show_workspace_map()
  local bufnr = vim.api.nvim_get_current_buf()
  state.source_bufnr = bufnr

  local symbols = graph_module.get_document_symbols(bufnr)

  if #symbols == 0 then
    vim.notify("No symbols found. Ensure LSP is running.", vim.log.levels.WARN)
    return
  end

  state.all_functions = graph_module.extract_all_functions(symbols)

  if #state.all_functions == 0 then
    vim.notify("No functions found in file", vim.log.levels.WARN)
    return
  end

  state.graph = graph_module.build_overview_graph(state.all_functions)
  state.current_title = "File Overview: " .. vim.fn.expand("%:t")
  state.selected_node = state.all_functions[1] and state.all_functions[1].id or nil

  M.render_with_layout(state.current_layout, state.current_title)

  vim.notify(
    string.format("Found %d functions. Press / to search, <CR> to explore", #state.all_functions),
    vim.log.levels.INFO
  )
end

function M.search_function()
  if not state.all_functions or #state.all_functions == 0 then
    vim.notify("No functions to search. Use <leader>mm first.", vim.log.levels.WARN)
    return
  end

  vim.ui.input({ prompt = "Search function: " }, function(input)
    if not input or input == "" then
      return
    end

    local matches = {}
    local lower_input = input:lower()

    for _, func in ipairs(state.all_functions) do
      if func.name:lower():find(lower_input, 1, true) then
        table.insert(matches, func)
      end
    end

    if #matches == 0 then
      vim.notify("No matches found for: " .. input, vim.log.levels.WARN)
      return
    end

    if #matches == 1 then
      state.selected_node = matches[1].id
      M.refresh_display()
      vim.notify("Found: " .. matches[1].name, vim.log.levels.INFO)
    else
      local choices = {}
      for i, func in ipairs(matches) do
        table.insert(choices, string.format("%d. %s", i, func.name))
      end

      vim.ui.select(choices, {
        prompt = string.format("Found %d matches:", #matches),
      }, function(_, idx)
        if idx then
          state.selected_node = matches[idx].id
          M.refresh_display()
          vim.notify("Selected: " .. matches[idx].name, vim.log.levels.INFO)
        end
      end)
    end
  end)
end

function M.explore_selected()
  if not state.selected_node then
    vim.notify("No function selected", vim.log.levels.WARN)
    return
  end

  local node = state.graph.nodes[state.selected_node]
  if not node or not node.symbol then
    vim.notify("Cannot explore this node", vim.log.levels.WARN)
    return
  end

  if state.winnr and vim.api.nvim_win_is_valid(state.winnr) then
    vim.api.nvim_win_close(state.winnr, true)
  end

  vim.notify("Exploring " .. node.name .. "...", vim.log.levels.INFO)

  graph_async.build_function_call_graph_async(state.source_bufnr, node.symbol, function(graph)
    if not graph then
      vim.notify("Could not build call graph", vim.log.levels.WARN)
      return
    end

    state.graph = graph
    state.current_title = "Function: " .. node.name
    state.selected_node = "root"

    M.render_with_layout(state.current_layout, state.current_title)
  end)
end

function M.render_with_layout(layout_type, title)
  if not state.graph then
    vim.notify("No graph data available", vim.log.levels.WARN)
    return
  end

  if layout_type == "compact" then
    state.positions = layout.compact_layout(state.graph)
  elseif layout_type == "tree" then
    state.positions = layout.tree_layout(state.graph)
  elseif layout_type == "wide" then
    state.positions = layout.wide_layout(state.graph)
  else
    state.positions = layout.compact_layout(state.graph)
  end

  state.node_list = {}
  for node_id, pos in pairs(state.positions) do
    table.insert(state.node_list, {
      id = node_id,
      x = pos.x,
      y = pos.y,
      width = pos.width,
      height = pos.height,
    })
  end

  table.sort(state.node_list, function(a, b)
    if math.abs(a.y - b.y) < 3 then
      return a.x < b.x
    end
    return a.y < b.y
  end)

  local lines = render.render(state.graph, state.positions, state.selected_node)

  M.display(lines, title .. " [" .. layout_type .. "]")
end

function M.cycle_layout()
  if not state.graph then
    vim.notify("No graph loaded", vim.log.levels.WARN)
    return
  end

  local layouts = { "compact", "tree", "wide" }
  local current_idx = 1

  for i, l in ipairs(layouts) do
    if l == state.current_layout then
      current_idx = i
      break
    end
  end

  local next_idx = (current_idx % #layouts) + 1
  state.current_layout = layouts[next_idx]

  if state.winnr and vim.api.nvim_win_is_valid(state.winnr) then
    vim.api.nvim_win_close(state.winnr, true)
  end

  M.render_with_layout(state.current_layout, state.current_title)

  vim.notify("Layout: " .. state.current_layout, vim.log.levels.INFO)
end

function M.navigate(direction)
  if not state.selected_node or #state.node_list == 0 then
    return
  end

  local current_idx = 1
  for i, node in ipairs(state.node_list) do
    if node.id == state.selected_node then
      current_idx = i
      break
    end
  end

  local current_node = state.node_list[current_idx]
  local new_idx = current_idx

  if direction == "down" then
    for i = current_idx + 1, #state.node_list do
      if state.node_list[i].y > current_node.y + 2 then
        new_idx = i
        break
      end
    end
  elseif direction == "up" then
    for i = current_idx - 1, 1, -1 do
      if state.node_list[i].y < current_node.y - 2 then
        new_idx = i
        break
      end
    end
  elseif direction == "right" then
    local candidates = {}
    for i, node in ipairs(state.node_list) do
      if node.x > current_node.x + 10 then
        local dist = math.abs(node.y - current_node.y)
        table.insert(candidates, { idx = i, dist = dist })
      end
    end

    if #candidates > 0 then
      table.sort(candidates, function(a, b)
        return a.dist < b.dist
      end)
      new_idx = candidates[1].idx
    end
  elseif direction == "left" then
    local candidates = {}
    for i, node in ipairs(state.node_list) do
      if node.x < current_node.x - 10 then
        local dist = math.abs(node.y - current_node.y)
        table.insert(candidates, { idx = i, dist = dist })
      end
    end

    if #candidates > 0 then
      table.sort(candidates, function(a, b)
        return a.dist < b.dist
      end)
      new_idx = candidates[1].idx
    end
  end

  if new_idx ~= current_idx then
    state.selected_node = state.node_list[new_idx].id
    M.refresh_display()

    local node = state.graph.nodes[state.selected_node]
    if node then
      vim.notify("Selected: " .. node.name, vim.log.levels.INFO)
    end
  end
end

function M.refresh_display()
  if not state.graph or not state.winnr or not vim.api.nvim_win_is_valid(state.winnr) then
    return
  end

  local lines = render.render(state.graph, state.positions, state.selected_node)

  vim.bo[state.bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(state.bufnr, 0, -1, false, lines)
  vim.bo[state.bufnr].modifiable = false

  local node = state.graph.nodes[state.selected_node]
  if node then
    local pos = state.positions[state.selected_node]
    if pos then
      pcall(vim.api.nvim_win_set_cursor, state.winnr, { pos.y + 1, pos.x + 1 })

      vim.api.nvim_set_option_value("cursorline", true, { win = state.winnr })
      vim.api.nvim_set_option_value("cursorcolumn", false, { win = state.winnr })
    end
  end
end

function M.jump_to_selected()
  if not state.selected_node then
    return
  end

  local node = state.graph.nodes[state.selected_node]
  if not node then
    vim.notify("Node not found", vim.log.levels.WARN)
    return
  end

  if state.current_title:match("^File Overview") and node.symbol then
    M.explore_selected()
    return
  end

  if state.winnr and vim.api.nvim_win_is_valid(state.winnr) then
    vim.api.nvim_win_close(state.winnr, true)
  end

  vim.schedule(function()
    if node.uri then
      local filename = vim.uri_to_fname(node.uri)
      vim.cmd("edit " .. vim.fn.fnameescape(filename))
    end

    if node.location then
      local range = node.location.range or node.location.selectionRange
      if range and range.start then
        local line = range.start.line + 1
        local col = range.start.character or 0

        pcall(vim.api.nvim_win_set_cursor, 0, { line, col })
        vim.cmd("normal! zz")
      end
    end
  end)
end

function M.display(lines, title)
  state.bufnr = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_set_lines(state.bufnr, 0, -1, false, lines)
  vim.bo[state.bufnr].modifiable = false
  vim.bo[state.bufnr].buftype = "nofile"
  vim.bo[state.bufnr].filetype = "mindmap"

  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.9)

  state.winnr = vim.api.nvim_open_win(state.bufnr, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor(vim.o.columns * 0.05),
    row = math.floor(vim.o.lines * 0.05),
    style = "minimal",
    border = "rounded",
    title = title or "Call Graph",
    title_pos = "center",
  })

  M.setup_keymaps()
  M.setup_highlights()

  vim.api.nvim_set_option_value("cursorline", true, { win = state.winnr })
  vim.api.nvim_set_option_value("cursorlineopt", "line", { win = state.winnr })

  if state.selected_node then
    local pos = state.positions[state.selected_node]
    if pos then
      pcall(vim.api.nvim_win_set_cursor, state.winnr, { pos.y + 1, pos.x + 1 })
    end
  end
end

function M.setup_keymaps()
  local opts = { buffer = state.bufnr, silent = true }

  vim.keymap.set("n", "<CR>", function()
    M.jump_to_selected()
  end, opts)

  vim.keymap.set("n", "q", function()
    if state.winnr and vim.api.nvim_win_is_valid(state.winnr) then
      vim.api.nvim_win_close(state.winnr, true)
    end
  end, opts)

  vim.keymap.set("n", "h", function()
    M.navigate("left")
  end, opts)

  vim.keymap.set("n", "j", function()
    M.navigate("down")
  end, opts)

  vim.keymap.set("n", "k", function()
    M.navigate("up")
  end, opts)

  vim.keymap.set("n", "l", function()
    M.navigate("right")
  end, opts)

  vim.keymap.set("n", "<Left>", function()
    M.navigate("left")
  end, opts)

  vim.keymap.set("n", "<Down>", function()
    M.navigate("down")
  end, opts)

  vim.keymap.set("n", "<Up>", function()
    M.navigate("up")
  end, opts)

  vim.keymap.set("n", "<Right>", function()
    M.navigate("right")
  end, opts)

  vim.keymap.set("n", "/", function()
    M.search_function()
  end, opts)

  vim.keymap.set("n", "e", function()
    M.explore_selected()
  end, opts)

  vim.keymap.set("n", "L", function()
    M.cycle_layout()
  end, opts)

  vim.keymap.set("n", "r", function()
    if state.winnr and vim.api.nvim_win_is_valid(state.winnr) then
      vim.api.nvim_win_close(state.winnr, true)
    end
    M.show_file_map()
  end, opts)

  vim.keymap.set("n", "?", function()
    local node = state.graph.nodes[state.selected_node]
    local node_name = node and node.name or "none"

    local is_overview = state.current_title:match("^File Overview")

    local help_text = {
      "Interactive Call Graph Navigator",
      "",
      "Navigation:",
      "  hjkl or ←↓↑→  - Navigate",
      "  <CR>          - " .. (is_overview and "Explore function" or "Jump to function"),
      "",
      "Actions:",
      "  /       - Search function" .. (is_overview and "" or " (overview mode only)"),
      "  e       - Explore (show call graph)" .. (is_overview and "" or " (overview mode only)"),
      "  q       - Close",
      "  r       - Back to cursor function",
      "  L       - Cycle layout",
      "  ?       - This help",
      "",
      "Selected: " .. node_name,
    }
    vim.notify(table.concat(help_text, "\n"), vim.log.levels.INFO)
  end, opts)
end

function M.setup_highlights()
  vim.api.nvim_set_option_value("syntax", "on", { buf = state.bufnr })

  vim.api.nvim_buf_call(state.bufnr, function()
    vim.cmd([[
      syntax match MindMapBox /[┌┐└┘─│╔╗╚╝═║╭╮╰╯]/
      syntax match MindMapArrow /[●▶▼→>]/
      syntax match MindMapLine /[─│┐└┌┘]/
      syntax match MindMapText /[a-zA-Z0-9_\.]/
      
      highlight default MindMapBox guifg=#61AFEF ctermfg=75
      highlight default MindMapArrow guifg=#E06C75 gui=bold ctermfg=204
      highlight default MindMapLine guifg=#56B6C2 ctermfg=73
      highlight default MindMapText guifg=#ABB2BF ctermfg=249
    ]])
  end)
end

return M
