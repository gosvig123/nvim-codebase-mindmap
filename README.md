# 🧠 nvim-codebase-mindmap

An interactive call graph visualization plugin for Neovim that helps you understand function relationships using LSP call hierarchy.

## ✨ Features

- 🔍 **Interactive Call Graph** - Visualize function callers and callees with multi-level depth
- 📊 **File Overview Mode** - Browse all functions in a file as a searchable grid
- 🎯 **Smart Filtering** - Automatically filters out built-in and framework functions
- ⌨️ **Intuitive Navigation** - hjkl/arrow keys for seamless movement
- 🚀 **Jump to Code** - Navigate directly to function definitions
- 🎨 **ASCII Art Rendering** - Clean, terminal-friendly visualization
- 🔧 **LSP Integration** - Works with any LSP server supporting call hierarchy (basedpyright, tsserver, rust-analyzer, etc.)

## 📦 Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "yourusername/nvim-codebase-mindmap",
  dependencies = { "neovim/nvim-lspconfig" },
  config = function()
    require("codebase-mindmap").setup()
  end,
  keys = {
    { "<leader>mf", "<cmd>CodebaseMindmapFunction<cr>", desc = "Show function call graph" },
    { "<leader>mm", "<cmd>CodebaseMindmapOverview<cr>", desc = "Show file overview" },
  },
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "yourusername/nvim-codebase-mindmap",
  requires = { "neovim/nvim-lspconfig" },
  config = function()
    require("codebase-mindmap").setup()
  end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'yourusername/nvim-codebase-mindmap'
Plug 'neovim/nvim-lspconfig'
```

## 🚀 Usage

### Commands

- `:CodebaseMindmapFunction` - Show call graph for function under cursor
- `:CodebaseMindmapOverview` - Show all functions in current file

### Keybindings (in mindmap buffer)

| Key | Action |
|-----|--------|
| `hjkl` / `←↓↑→` | Navigate between functions |
| `<CR>` | Jump to function definition / Explore function |
| `/` | Search (in overview mode) |
| `L` | Cycle layout |
| `q` | Close mindmap |

### Function View (`<leader>mf`)

Shows the function under cursor with:
- **Left side**: Callers (who calls this function)
- **Right side**: Callees (what this function calls)
- **Multi-level depth**: Shows nested call relationships

```
    ╭─────────────────╮
    │ handle_request  │──┐
    ╰─────────────────╯  │
                         │
    ╔═══════════════╗    │
    ║ process_data  ║●───┼──┐
    ╚═══════════════╝    │  │
                         │  │
    ╭──────────────╮     │  │
    │ validate_user│←────┘  │
    ╰──────────────╯        │
                            │
    ╭────────────╮          │
    │ save_to_db │←─────────┘
    ╰────────────╯
```

### Overview Mode (`<leader>mm`)

Displays all functions in the current file as a 4-column grid:

```
┌─────────────────────────────────────────────┐
│  func1       func2       func3       func4  │
│  func5       func6       func7       func8  │
│  func9       func10      func11      func12 │
└─────────────────────────────────────────────┘
```

Press `/` to search, `<CR>` to explore a function's call graph.

## ⚙️ Configuration

```lua
require("codebase-mindmap").setup({
  -- Default keybindings
  mappings = {
    function_view = "<leader>mf",
    overview = "<leader>mm",
  },
  
  -- Filter settings (configured in graph.lua)
  max_callers = 8,   -- Maximum callers to show
  max_callees = 10,  -- Maximum callees to show
  max_depth = 2,     -- Maximum call hierarchy depth
})
```

## 🎯 Supported LSP Servers

Any LSP server with call hierarchy support:

- ✅ **Python**: basedpyright, pyright, pylsp
- ✅ **TypeScript/JavaScript**: tsserver, denols
- ✅ **Rust**: rust-analyzer
- ✅ **Go**: gopls
- ✅ **C/C++**: clangd
- ✅ **Java**: jdtls
- ✅ **And more...**

## 🔧 Requirements

- Neovim >= 0.8.0
- An LSP server with call hierarchy support
- `nvim-lspconfig` (optional but recommended)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

MIT License - see [LICENSE](LICENSE) for details

## 🙏 Acknowledgments

- Inspired by the need for better code navigation in large codebases
- Built with ❤️ using Neovim's LSP capabilities

## 🐛 Known Issues

- Very large call hierarchies may take time to load
- Some LSP servers have limited call hierarchy support

## 🗺️ Roadmap

- [ ] Color coding by symbol type
- [ ] Export call graphs to file
- [ ] Cross-file call hierarchy (workspace-wide)
- [ ] Custom filtering rules
- [ ] Graph search/filtering
- [ ] Integration with telescope.nvim
- [ ] Configurable max depth and limits via setup()

---

**Star ⭐ this repo if you find it helpful!**
