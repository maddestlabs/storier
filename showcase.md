# Storier Engine — Feature Showcase

Welcome to **Storier**, a Markdown-first game / interactive story engine.

## 1. Basic Markdown Rendering

This paragraph demonstrates **line wrapping** and general Markdown layout.

## 2. DSL Rendering Example

```nim on:render
drawText("Hello from DSL!", 40, 200, 24, "yellow")
```

## 3. DSL Animation Example

```nim on:update
x = x + 1
if x > 800: x = 0
```

```nim on:render
drawText("I'm moving!", x, 260, 22, "lightgreen")
```

## 4. Custom Rendering Region

```nim on:render
setMarkdownRegion(60, 350, 680, 200)
```

Inside this region, Markdown content is drawn in a confined area.
