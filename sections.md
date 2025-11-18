# Introduction

Welcome to the **multi-section demo**.

# About

This section appears after "Introduction".

### Features of this build:

- Markdown headings  
- Paragraphs  
- Lists  
- Code blocks  
- DSL-driven drawing

# DSL Interactions

```nim on:update
angle = angle + 0.05
```

```nim on:render
let cx = 400
let cy = 300
let r = int(50 + sin(angle) * 40)
drawText("Animated radius: " & $r, 40, 500, 22, "lightgreen")
drawCircle(cx, cy, r, "orange")
```
