# Storier Engine Demo

Welcome to the **Storier Engine**, powered by:

- A Markdown parser
- A Nim-based DSL
- Raylib/Naylib rendering
- A flexible layout/region system

### DSL Rendered Text

```nim on:render
drawText("This text is drawn by DSL (render event)", 40, 260, 20, "lightblue")
```

### DSL Update Example

```nim on:update
pos = pos + 1
if pos > 800: pos = 0
```

```nim on:render
drawText("Moving text!", pos, 300, 24, "green")
``` 
