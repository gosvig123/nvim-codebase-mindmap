local M = {}

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
  local builtins = {
    "sub", "join", "split", "strip", "upper", "lower", "replace", "find",
    "append", "extend", "pop", "remove", "insert", "sort", "reverse",
    "keys", "values", "items", "get", "update", "clear",
    "read", "write", "close", "open", "readlines", "writelines",
    "encode", "decode", "format", "startswith", "endswith",
    "isdigit", "isalpha", "isupper", "islower",
    "len", "str", "int", "float", "bool", "list", "dict", "set",
    "print", "input", "range", "enumerate", "zip", "map", "filter",
  }

  local lower_name = name:lower()
  
  for _, builtin in ipairs(builtins) do
    if lower_name == builtin then
      return true
    end
  end

  return lower_name:match("^_") or lower_name:match("__init__") or lower_name:match("__str__")
end

local SymbolKind = {
  [12] = "Function",
  [6] = "Method",
  [5] = "Class",
}

function M.build_function_call_graph_async(bufnr, symbol, callback)
  if not symbol then
    callback(nil)
    return
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
    callback({ nodes = nodes, edges = edges, root = root })
    return
  end

  local params = {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    position = { line = range.start.line, character = range.start.character },
  }

  local clients = vim.lsp.get_active_clients({ bufnr = bufnr })
  
  for _, client in ipairs(clients) do
    if client.server_capabilities.callHierarchyProvider then
      client.request("textDocument/prepareCallHierarchy", params, function(err, result)
        if err or not result or #result == 0 then
          callback({ nodes = nodes, edges = edges, root = root })
          return
        end

        local item = result[1]
        local max_depth = require("codebase-mindmap").config.max_depth or 2
        local results_ready = { incoming = false, outgoing = false }
        local incoming_calls = {}
        local outgoing_calls = {}

        local function try_complete()
          if results_ready.incoming and results_ready.outgoing then
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

            callback({ nodes = nodes, edges = edges, root = root })
          end
        end

          local function get_calls_async(call_type, item_param, depth, visited, parent_info, result_callback)
          if depth >= max_depth then
            result_callback({})
            return
          end

          visited = visited or {}
          local key = item_param.uri .. ":" .. item_param.range.start.line .. ":" .. item_param.range.start.character
          if visited[key] then
            result_callback({})
            return
          end
          visited[key] = true

          local method = call_type == "incoming" and "callHierarchy/incomingCalls" or "callHierarchy/outgoingCalls"

          client.request(method, { item = item_param }, function(call_err, call_result)
            if call_err or not call_result or #call_result == 0 then
              result_callback({})
              return
            end

            local calls = {}
            local pending = #call_result

            for _, call in ipairs(call_result) do
              local target = call_type == "incoming" and call.from or call.to
              local call_info = {
                [call_type == "incoming" and "from" or "to"] = target,
                depth = depth,
                parent = parent_info,
              }
              table.insert(calls, call_info)

              if depth < max_depth - 1 then
                get_calls_async(call_type, target, depth + 1, visited, call_info, function(nested)
                  for _, nested_call in ipairs(nested) do
                    table.insert(calls, nested_call)
                  end
                  pending = pending - 1
                  if pending == 0 then
                    result_callback(calls)
                  end
                end)
              else
                pending = pending - 1
                if pending == 0 then
                  result_callback(calls)
                end
              end
            end
          end)
        end

        get_calls_async("incoming", item, 0, {}, nil, function(results)
          incoming_calls = results
          results_ready.incoming = true
          try_complete()
        end)

        get_calls_async("outgoing", item, 0, {}, nil, function(results)
          outgoing_calls = results
          results_ready.outgoing = true
          try_complete()
        end)
      end)
      
      return
    end
  end

  callback({ nodes = nodes, edges = edges, root = root })
end

return M
