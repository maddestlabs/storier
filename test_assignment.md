# Test Assignment Fix

This file tests the DSL parser fix for simple assignments.

```nim on:render
x = 40
drawText("Hello from DSL!", x, 200, 24, "yellow")
```

The parser should now correctly handle:
1. Simple assignment: `x = 40`
2. Assignment with expressions: `x = 40 + 2`
3. Assignment after var declaration: `var y = 10` then `y = y + 1`
