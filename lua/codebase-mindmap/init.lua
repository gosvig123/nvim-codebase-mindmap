local M = {}

M.config = {
  max_depth = 3,
  show_kinds = { "Class", "Function", "Method", "Module" },
  layout = "tree",
  node_spacing = 3,
  level_spacing = 8,
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  
  vim.api.nvim_create_user_command("CodebaseMindmapFunction", function()
    require("codebase-mindmap.ui").show_function_graph()
  end, {})

  vim.api.nvim_create_user_command("CodebaseMindmapOverview", function()
    require("codebase-mindmap.ui").show_overview()
  end, {})

  vim.api.nvim_create_user_command("MindMap", function(args)
    if args.args == "file" then
      require("codebase-mindmap.ui").show_file_map()
    else
      require("codebase-mindmap.ui").show_workspace_map()
    end
  end, {
    nargs = "?",
    complete = function() return {"file", "workspace"} end
  })
end

return M
