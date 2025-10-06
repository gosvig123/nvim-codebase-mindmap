# UI Improvements Applied

## Visual Clarity Enhancements

### 1. **Extended Depth Support**
- Now handles all 12 levels for both callers and callees
- Previous: Only -3 to -1 and 1 to 3
- Current: -12 to -1 (callers) and 1 to 12 (callees)

### 2. **Better Spacing**
- Horizontal depth offset: 15 → 25 units (clearer separation)
- Vertical spacing: 5 → 4 units (more compact)
- Adjusted base positions for visual balance

### 3. **Depth Indicators**
- Added `↳` symbol for nested calls (depth > 0)
- Makes nesting level immediately visible
- Example:
  ```
  function_a →
    ↳ function_b →
      ↳ function_c →
  ```

### 4. **Improved Connectors**
- Shorter connector lines (mid_x calculation changed)
- Less visual clutter
- Clearer parent-child relationships

## How to Update

Run in Neovim:
```vim
:Lazy sync
```

Then restart Neovim and use:
- `<leader>mf` - Function call graph
- `<leader>mm` - File overview
