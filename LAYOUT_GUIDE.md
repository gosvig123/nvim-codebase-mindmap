# Layout Improvements Guide

## New Tree-Based Layout

### Before (Flat List Layout)
```
function1 →        
function2 →        
  function3 →      ╔═══════════╗        function_a
    function4 →    ║   ROOT    ║        function_b  
      function5 →  ╚═══════════╝          function_c
                                            function_d
```
❌ Problems:
- Hard to see which function calls which
- Overlapping lines
- No clear parent-child relationship
- Wastes vertical space

### After (Tree Layout)
```
◄ CALLERS                                                    CALLEES ►

╭─────────────╮                                         ╭─────────────╮
│ function1   │────┐                              ┌────▶│ function_a  │
╰─────────────╯    │                              │     ╰─────────────╯
                   │                              │           │
  ╭─────────────╮  │      ╔═══════════╗          │           └──▶╭─────────────╮
  │↳ function2  │──┴─────▶║   ROOT    ║●─────────┤                │↳ sub_func_a │
  ╰─────────────╯         ╚═══════════╝          │                ╰─────────────╯
                                                  │     
                                                  └────▶╭─────────────╮
                                                        │ function_b  │
                                                        ╰─────────────╯
```
✅ Improvements:
- Clear tree structure
- Children under parents
- Section headers (CALLERS ◄ / ► CALLEES)
- Better space utilization
- Visual depth indicators (↳)

## Key Features

### 1. **Tree Structure**
- Children positioned directly under parents
- Recursive layout calculation
- Proper nesting up to 12 levels

### 2. **Space Optimization**
- Horizontal offset: 35 units per depth level
- Vertical spacing: 4 units between nodes
- Adaptive canvas size: 200x60

### 3. **Visual Clarity**
- **Headers**: Show CALLERS on left, CALLEES on right
- **Depth indicators**: `↳` symbol for nested functions
- **Root node**: Double border box, centered
- **Connectors**: Clear parent→child arrows

### 4. **Smart Positioning**
- Root centered between trees
- Callers flow left with negative offset
- Callees flow right with positive offset
- No overlap between branches

## Usage

After syncing (`<leader>mf` on a function):
1. **Left side**: Shows who calls this function (callers)
2. **Center**: The selected function (root)
3. **Right side**: Shows what this function calls (callees)

Navigate with:
- `hjkl` or arrow keys
- `<CR>` to jump to function
- `q` to close
