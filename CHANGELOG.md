# Changelog

All notable changes to nvim-codebase-mindmap are documented here.

## [Latest] - 2024-10-07

### 🚀 MAJOR: Non-Blocking Async Operations

**Fixed**: Editor no longer freezes when building call graphs

- Created fully async `graph_async.lua` module  
- Converted all LSP calls to use `client.request()` with callbacks
- Async `find_symbol_at_cursor` implementation in UI
- Editor remains fully responsive during graph building
- Shows progress notifications ("Finding symbol...", "Building call graph...")

**Impact**: Can type, move cursor, and use editor while graphs load ✅

### ⚡ Ultra-Compact Layout (40% More Visible)

**Box Sizes** (Smaller):
- Regular nodes: `name + 2, max 24` (was +4, max 30)
- Root node: `name + 3, max 28` (was +6, max 35)  
- Overview: `name + 2, max 22` (was +4, max 28)

**Spacing** (Tighter):
- Compact: `x_offset=24, root=40` (was 28/45)
- Tree: `x_offset=18, root=30` (was 20/35)
- Wide: `x_offset=45, root=60` (was 50/70)
- Padding: 1 space (was 2)

**Canvas**: `100x25 min` (was 120x30)

**Grid**: 8 columns, width 24 (was 6 columns, width 30)

**Result**: ~40% more functions visible on screen

### ✨ Better Selection Indicator

**Old**: `** text **` (caused truncation: `** ↳ too...`)  
**New**: `▶ text` (keeps full text: `▶create_progress_tracker`)

- Red arrow at left border
- Text never truncated by selection marker
- Same highlighting as connection arrows

### ⚙️ Performance Defaults

```lua
{
  max_depth = 1,      -- Instant results (was 2)
  lsp_timeout = 800,  -- Fast timeout (was 1000)
}
```

## [Previous] - 2024-10-06

### 📏 Spacing & Readability Improvements

#### Box Enhancements
- **Wider boxes**: Increased padding from +4 to +6 characters
- **Better text space**: Max width 35 → 40 characters (45 for root)
- **More padding**: 3 spaces from edge (was 1-2)
- **Smart truncation**: Long names show "..." elegantly
- **Cleaner selection**: `** name **` indicator (was `*** name ***`)

#### Layout Spacing
- **Vertical**: 5 units between nodes (was 4) - less cramped
- **Horizontal**: 45 units between levels (was 35) - clearer hierarchy
- **Root centering**: x=70 (was 60) - better balance
- **Tree separation**: More space between caller/callee trees
- **Canvas size**: 250x70 (was 200x60) - more room to breathe

#### Overview Grid
- **Column width**: 42 (was 35) - more spacious
- **Box padding**: Consistent with tree view
- **Better readability**: Less cramped grid layout

### 🎉 Major Layout Redesign

#### Tree-Based Organization
- **True hierarchical layout**: Children now positioned directly under their parents
- **Recursive tree algorithm**: Proper nesting calculation for all depth levels
- **Better space utilization**: Vertical and horizontal optimization

#### Visual Clarity Improvements
- **Section headers**: Added `◄ CALLERS` and `CALLEES ►` labels
- **Depth indicators**: `↳` symbol shows nesting level visually
- **Root centering**: Root node positioned between caller and callee trees
- **Clean naming**: Removed redundant arrows from caller names

#### Deep Nesting Support
- **12-level depth**: Full support for deeply nested call hierarchies
- **Unlimited nodes**: Removed artificial limits (was max 8 callers, 10 callees)
- **Parent tracking**: Proper parent-child relationship tracking
- **Smart filtering**: Enhanced filtering of built-in and framework functions

### 🔧 Technical Improvements

#### Layout Engine
- Implemented `count_subtree_size()` for tree measurement
- Added `layout_tree_recursive()` for hierarchical positioning
- Adaptive vertical spacing based on tree size
- Optimized horizontal offsets (35 units per level)

#### Rendering
- Increased canvas size: 200x60 (was 120x50)
- Better connector drawing with fixed mid-point calculation
- Section header rendering at top of display
- Improved priority system for overlapping elements

#### Graph Building
- Added parent information to call hierarchy
- Fixed nesting logic to connect to actual parents
- Removed depth-based indentation (using position instead)
- Better edge tracking for complex hierarchies

### 📚 Documentation
- Added `LAYOUT_GUIDE.md` - Visual guide to new layout
- Added `IMPROVEMENTS.md` - Technical improvement details
- Added `CHANGELOG.md` - This file
- Updated README with new features and examples

### 🐛 Bug Fixes
- Fixed command registration (CodebaseMindmapFunction, CodebaseMindmapOverview)
- Fixed parent-child edge connections for nested calls
- Fixed level grouping to support all 12 levels
- Fixed connector line overlap issues

### 🚀 Performance
- More efficient tree traversal
- Reduced vertical space usage
- Better screen real estate utilization
- Faster rendering with optimized canvas

## [Initial] - 2024-10-06

### Initial Release
- Basic call hierarchy visualization
- LSP integration
- File overview mode
- Navigation with hjkl/arrows
- Jump to definition
- Smart filtering of builtins

---

## Upgrade Instructions

To get the latest improvements:

```vim
:Lazy sync
```

Then restart Neovim and enjoy the improved visualization!
