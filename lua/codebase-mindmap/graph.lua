local M = {}

local SymbolKind = {
  [1] = "File",
  [2] = "Module",
  [3] = "Namespace",
  [4] = "Package",
  [5] = "Class",
  [6] = "Method",
  [7] = "Property",
  [8] = "Field",
  [9] = "Constructor",
  [10] = "Enum",
  [11] = "Interface",
  [12] = "Function",
  [13] = "Variable",
  [14] = "Constant",
  [15] = "String",
  [16] = "Number",
}

local function get_display_name(symbol)
  local name = symbol.name
  if not name or name == "" then
    return nil
  end
  if name == "default" or name == "_default" then
    return nil
  end
  if name:match("^<") then
    return nil
  end

  name = name:gsub("^_+", "")
  if #name > 35 then
    name = name:sub(1, 32) .. "..."
  end

  return name
end

local function is_builtin_or_stdlib(name)
  -- Python builtins
  local builtins = {
    "sub", "join", "split", "strip", "upper", "lower", "replace", "find",
    "append", "extend", "pop", "remove", "insert", "sort", "reverse",
    "keys", "values", "items", "get", "update", "clear",
    "read", "write", "close", "open", "readlines", "writelines",
    "encode", "decode", "format", "startswith", "endswith",
    "isdigit", "isalpha", "isupper", "islower",
    "len", "str", "int", "float", "bool", "list", "dict", "set",
    "print", "input", "range", "enumerate", "zip", "map", "filter",
    "hasattr", "getattr", "setattr", "isinstance", "issubclass",
    "super", "type", "callable", "dir", "vars", "id", "hash",
    "abs", "all", "any", "ascii", "bin", "chr", "ord", "hex", "oct",
    "min", "max", "sum", "round", "pow", "divmod",
    "sorted", "reversed", "next", "iter",
  }

  -- Framework/library specific (FastAPI, SQLAlchemy, Supabase, etc.)
  local framework_names = {
    "depends", "doc", "query", "default", "exception", "httperror",
    "httpexception", "runtimeerror", "typeerror", "valueerror",
    "table", "select", "execute", "eq", "neq", "lt", "gt", "lte", "gte",
    "order", "limit", "offset", "single", "maybe_single",
    "deprecated", "api_route", "request", "response",
    "sanitize_param", "primitive_value_to_str",
    "queryparams", "defaultplaceholder", "pre_select",
    "is_success", "apierror", "from_http_request_response",
    "get_list", "create_task", "add_api_route",
    "generate_default_error_message", "warning",
    "convert", "phrase",
  }

  -- Common internal/utility patterns (case-insensitive)
  local internal_patterns = {
    "^_",           -- Private methods
    "__init__",     -- Constructor
    "__str__",      -- String representation
    "__repr__",     -- Representation
    "__dict__",     -- Dictionary
    "__class__",    -- Class
    "^copy$",       -- Copy method
    "^from_$",      -- Constructor pattern
    "^to_",         -- Conversion methods
    "isenabledfor", -- Logging internals
    "^_log$",       -- Private logging
    "^_get_",       -- Private getters
    "^_set_",       -- Private setters
    "^_create_",    -- Private creators
    "^_build_",     -- Private builders
    "^_parse_",     -- Private parsers
    "^_validate_",  -- Private validators
    "^_sanitize_",  -- Private sanitizers
    "^_clean",      -- Private cleaners
    "^_format_",    -- Private formatters
    "encoding",     -- Property access
    "headers",      -- Property access
    "content",      -- Property access
    "text",         -- Property access
    "json",         -- Property access
    "status",       -- Property access
    "^add$",        -- Generic add
    "^send$",       -- Generic send
    "^flush$",      -- Generic flush
    "^warn$",       -- Generic warn
    "^error$",      -- Generic error
    "^info$",       -- Generic info
    "^or_$",        -- SQL OR
    "^and_$",       -- SQL AND
  }

  local lower_name = name:lower()
  
  -- Check exact matches for builtins
  for _, builtin in ipairs(builtins) do
    if lower_name == builtin then
      return true
    end
  end

  -- Check exact matches for framework names
  for _, framework in ipairs(framework_names) do
    if lower_name == framework then
      return true
    end
  end

  -- Check pattern matches
  for _, pattern in ipairs(internal_patterns) do
    if lower_name:match(pattern) then
      return true
    end
  end

  return false
end

function M.find_symbol_at_cursor(bufnr)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1] - 1
  local col = cursor[2]

  local params = {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    position = { line = line, character = col },
  }

  local clients = vim.lsp.get_active_clients({ bufnr = bufnr })

  for _, client in ipairs(clients) do
    if client.server_capabilities.documentSymbolProvider then
      local success, result = pcall(function()
        return client.request_sync("textDocument/documentSymbol", params, 5000, bufnr)
      end)

      if success and result and result.result then
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

        return find_enclosing(result.result, line, col)
      end
    end
  end

  return nil
end

function M.get_incoming_calls_recursive(client, item, depth, max_depth, visited, parent_info)
  if depth >= max_depth then
    return {}
  end

  visited = visited or {}
  local key = item.uri .. ":" .. item.range.start.line .. ":" .. item.range.start.character
  if visited[key] then
    return {}
  end
  visited[key] = true

  local result = client.request_sync("callHierarchy/incomingCalls", { item = item }, 5000)
  if not result or not result.result then
    return {}
  end

  local calls = {}
  for _, call in ipairs(result.result) do
    local call_info = {
      from = call.from,
      depth = depth,
      parent = parent_info,
    }
    table.insert(calls, call_info)

    if depth < max_depth - 1 then
      local nested = M.get_incoming_calls_recursive(client, call.from, depth + 1, max_depth, visited, call_info)
      for _, nested_call in ipairs(nested) do
        table.insert(calls, nested_call)
      end
    end
  end

  return calls
end

function M.get_outgoing_calls_recursive(client, item, depth, max_depth, visited, parent_info)
  if depth >= max_depth then
    return {}
  end

  visited = visited or {}
  local key = item.uri .. ":" .. item.range.start.line .. ":" .. item.range.start.character
  if visited[key] then
    return {}
  end
  visited[key] = true

  local result = client.request_sync("callHierarchy/outgoingCalls", { item = item }, 5000)
  if not result or not result.result then
    return {}
  end

  local calls = {}
  for _, call in ipairs(result.result) do
    local call_info = {
      to = call.to,
      depth = depth,
      parent = parent_info,
    }
    table.insert(calls, call_info)

    if depth < max_depth - 1 then
      local nested = M.get_outgoing_calls_recursive(client, call.to, depth + 1, max_depth, visited, call_info)
      for _, nested_call in ipairs(nested) do
        table.insert(calls, nested_call)
      end
    end
  end

  return calls
end

function M.build_function_call_graph(bufnr, symbol)
  if not symbol then
    return nil
  end

  local nodes = {}
  local edges = {}

  local function_name = get_display_name(symbol) or "Unknown"
  local kind = SymbolKind[symbol.kind] or "Unknown"

  local root = {
    id = "root",
    name = function_name,
    kind = kind,
    children = {},
    level = 0,
    location = symbol.location or symbol.selectionRange,
  }
  nodes[root.id] = root

  local range = symbol.location and symbol.location.range or symbol.selectionRange
  if not range then
    return { nodes = nodes, edges = edges, root = root }
  end

  local params = {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    position = { line = range.start.line, character = range.start.character },
  }

  local clients = vim.lsp.get_active_clients({ bufnr = bufnr })
  local incoming_calls = {}
  local outgoing_calls = {}

  for _, client in ipairs(clients) do
    if client.server_capabilities.callHierarchyProvider then
      local prepare_result = client.request_sync("textDocument/prepareCallHierarchy", params, 5000, bufnr)

      if prepare_result and prepare_result.result and #prepare_result.result > 0 then
        local item = prepare_result.result[1]

        -- Support up to 12 levels of nesting
        incoming_calls = M.get_incoming_calls_recursive(client, item, 0, 12, {})
        outgoing_calls = M.get_outgoing_calls_recursive(client, item, 0, 12, {})
      end
      break
    end
  end

  local id_counter = 0
  local caller_map = {}

  for _, call in ipairs(incoming_calls) do
    local caller_name = call.from.name

    if not is_builtin_or_stdlib(caller_name) then
      id_counter = id_counter + 1
      local caller_id = "caller_" .. id_counter

      if #caller_name > 28 then
        caller_name = caller_name:sub(1, 25) .. "..."
      end

      local level = -(call.depth + 1)
      local depth_indicator = call.depth > 0 and "↳ " or ""

      nodes[caller_id] = {
        id = caller_id,
        name = depth_indicator .. caller_name,
        kind = "Caller",
        children = {},
        level = level,
        depth = call.depth,
        location = call.from,
        uri = call.from.uri,
      }

      caller_map[call] = caller_id

      if call.depth == 0 then
        table.insert(edges, { from = caller_id, to = root.id })
      elseif call.parent and caller_map[call.parent] then
        local parent_id = caller_map[call.parent]
        table.insert(edges, { from = caller_id, to = parent_id })
      end
    end
  end

  local callee_map = {}

  for _, call in ipairs(outgoing_calls) do
    local callee_name = call.to.name

    if not is_builtin_or_stdlib(callee_name) then
      id_counter = id_counter + 1
      local callee_id = "callee_" .. id_counter

      if #callee_name > 28 then
        callee_name = callee_name:sub(1, 25) .. "..."
      end

      local level = call.depth + 1
      local depth_indicator = call.depth > 0 and "↳ " or ""

      nodes[callee_id] = {
        id = callee_id,
        name = depth_indicator .. callee_name,
        kind = "Callee",
        children = {},
        level = level,
        depth = call.depth,
        location = call.to,
        uri = call.to.uri,
      }

      callee_map[call] = callee_id

      if call.depth == 0 then
        table.insert(root.children, callee_id)
        table.insert(edges, { from = root.id, to = callee_id })
      elseif call.parent and callee_map[call.parent] then
        local parent_id = callee_map[call.parent]
        table.insert(nodes[parent_id].children, callee_id)
        table.insert(edges, { from = parent_id, to = callee_id })
      end
    end
  end

  return { nodes = nodes, edges = edges, root = root }
end

function M.extract_all_functions(symbols)
  local functions = {}
  local id_counter = 0

  local function extract_recursive(syms)
    for _, symbol in ipairs(syms) do
      local kind_name = SymbolKind[symbol.kind]

      if kind_name == "Function" or kind_name == "Method" or kind_name == "Class" or kind_name == "Interface" then
        local display_name = get_display_name(symbol)

        if display_name and not is_builtin_or_stdlib(display_name) then
          id_counter = id_counter + 1
          table.insert(functions, {
            id = "func_" .. id_counter,
            name = display_name,
            kind = kind_name,
            symbol = symbol,
            location = symbol.location or symbol.selectionRange,
          })
        end
      end

      if symbol.children and #symbol.children > 0 then
        extract_recursive(symbol.children)
      end
    end
  end

  extract_recursive(symbols)

  return functions
end

function M.build_overview_graph(functions)
  local nodes = {}
  local edges = {}

  local root = {
    id = "root",
    name = "All Functions",
    kind = "Root",
    children = {},
    level = 0,
  }
  nodes[root.id] = root

  for i, func in ipairs(functions) do
    nodes[func.id] = {
      id = func.id,
      name = func.name,
      kind = func.kind,
      symbol = func.symbol,
      location = func.location,
      children = {},
      level = 1,
    }

    table.insert(root.children, func.id)
    table.insert(edges, { from = root.id, to = func.id })
  end

  return { nodes = nodes, edges = edges, root = root }
end

function M.get_document_symbols(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local params = { textDocument = vim.lsp.util.make_text_document_params(bufnr) }
  local clients = vim.lsp.get_active_clients({ bufnr = bufnr })

  for _, client in ipairs(clients) do
    if client.server_capabilities.documentSymbolProvider then
      local success, result = pcall(function()
        return client.request_sync("textDocument/documentSymbol", params, 10000, bufnr)
      end)

      if success and result and result.result then
        return result.result
      end
    end
  end

  return {}
end

function M.build_document_graph(symbols, filename)
  return { nodes = {}, edges = {}, root = { id = "root", children = {} } }
end

function M.get_symbols()
  return {}
end

function M.build_graph(symbols, root_name)
  return { nodes = {}, edges = {}, root = { id = "root", children = {} } }
end

return M
