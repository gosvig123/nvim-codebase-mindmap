# Changelog

All notable changes to nvim-codebase-mindmap are documented here.

## [Latest] - 2024-10-06

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
