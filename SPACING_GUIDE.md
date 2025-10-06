# Spacing & Layout Guide

## Box Dimensions

### Before
```
┌────────────────┐
│function_name   │  ← Cramped: +4 padding, max 35 width
└────────────────┘
```

### After
```
╭──────────────────────╮
│   function_name      │  ← Spacious: +6 padding, max 40 width
╰──────────────────────╯
```

## Spacing Parameters

### Vertical Spacing
- **Previous**: 4 units between nodes
- **Current**: 5 units between nodes
- **Benefit**: Less cramped, easier to read

### Horizontal Spacing
- **Previous**: 35 units between depth levels
- **Current**: 45 units between depth levels
- **Benefit**: Clearer visual hierarchy

### Root Position
- **Previous**: x = 60
- **Current**: x = 70
- **Benefit**: Better centering between caller/callee trees

### Caller/Callee Offsets
- **Callers**: -10 from root (was -5)
- **Callees**: +50 from root (was +40)
- **Benefit**: More breathing room around root

## Box Padding

### Text Padding
```
Before:  ╭─┬─────────────┐
         │ │text         │  ← 1-2 spaces
         ╰─┴─────────────┘

After:   ╭───┬─────────────┐
         │   │  text       │  ← 3 spaces
         ╰───┴─────────────┘
```

### Width Calculation
- **Normal boxes**: `min(name_length + 6, 40)`
- **Root box**: `min(name_length + 8, 45)`
- **Overview boxes**: `min(name_length + 6, 38)`

### Text Truncation
Long names are intelligently truncated:
```
╭──────────────────────╮
│   very_long_functi...│  ← Smart truncation with ...
╰──────────────────────╯
```

## Selected Node Indicator

### Before
```
╭─────────────────────────╮
│*** function_name ***    │  ← Cluttered
╰─────────────────────────╯
```

### After
```
╭─────────────────────────╮
│   ** function_name **   │  ← Cleaner, better spacing
╰─────────────────────────╯
```

## Canvas Size

### Previous
- Width: 200 characters
- Height: 60 lines

### Current
- Width: 250 characters
- Height: 70 lines

**Benefit**: Accommodates wider boxes and more breathing room

## Overview Grid

### Previous
- 4 columns
- 35 width per column
- Cramped layout

### Current
- 4 columns  
- 42 width per column
- Spacious layout

## Summary

| Parameter | Before | After | Change |
|-----------|--------|-------|--------|
| Box width padding | +4 | +6 | +50% |
| Max box width | 35 | 40 | +14% |
| Vertical spacing | 4 | 5 | +25% |
| Horizontal offset | 35 | 45 | +29% |
| Text padding | 1-2 | 3 | +50-200% |
| Canvas width | 200 | 250 | +25% |
| Canvas height | 60 | 70 | +17% |

**Result**: More readable, less cramped, better visual hierarchy!
