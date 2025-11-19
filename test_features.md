# DSL Feature Test Suite

This story tests the new DSL features: boolean literals, logical operators, and for loops.

## Boolean Literals and Logical Operators

```nim on:render
# Test 1: Boolean literals
var isTrue = true
var isFalse = false

# Test 2: Logical AND operator
var test1 = true and true
var test2 = true and false
var test3 = false and true
var test4 = false and false

# Test 3: Logical OR operator
var test5 = true or true
var test6 = true or false
var test7 = false or true
var test8 = false or false

# Test 4: NOT operator
var test9 = not true
var test10 = not false

# Display results
drawText("Boolean Literals Test", 10, 10, 20, "yellow")
drawText("isTrue should be true", 10, 40, 16, "white")
drawText("isFalse should be false", 10, 60, 16, "white")

drawText("Logical Operators Test", 10, 100, 20, "yellow")
drawText("AND: T&T=T, T&F=F, F&T=F, F&F=F", 10, 130, 16, "white")
drawText("OR: T|T=T, T|F=T, F|T=T, F|F=F", 10, 150, 16, "white")
drawText("NOT: !T=F, !F=T", 10, 170, 16, "white")
```

## Conditionals with Boolean Expressions

```nim on:render
# Test conditional with boolean variables
var x = 10
var y = 20

if x < y and x > 5:
  drawText("Condition test 1: PASS (x < y AND x > 5)", 10, 210, 16, "green")
else:
  drawText("Condition test 1: FAIL", 10, 210, 16, "red")

if x > y or y == 20:
  drawText("Condition test 2: PASS (x > y OR y == 20)", 10, 230, 16, "green")
else:
  drawText("Condition test 2: FAIL", 10, 230, 16, "red")

if not (x > y):
  drawText("Condition test 3: PASS (NOT x > y)", 10, 250, 16, "green")
else:
  drawText("Condition test 3: FAIL", 10, 250, 16, "red")
```

## For Loop Tests

```nim on:render
# Test 1: Simple for loop (draw boxes)
var yPos = 290
drawText("For Loop Test 1: Drawing boxes", 10, yPos, 16, "yellow")

for i in range(0, 5):
  var xPos = 10 + i * 60
  drawRect(xPos, yPos + 30, 50, 30, "blue")

# Test 2: For loop with calculations
drawText("For Loop Test 2: Calculations", 10, 360, 16, "yellow")

var sum = 0
for i in range(1, 6):
  sum = sum + i

drawText("Sum of 1 to 5 should be 15", 10, 390, 16, "white")
# Note: sum variable contains 15

# Test 3: Nested conditionals in loop
drawText("For Loop Test 3: Conditional in loop", 10, 430, 16, "yellow")

for i in range(0, 10):
  if i % 2 == 0:
    var xPos = 10 + i * 30
    drawCircle(xPos, 480, 10.0, "green")
  else:
    var xPos = 10 + i * 30
    drawCircle(xPos, 480, 10.0, "red")
```

## Combined Test: Animation with Conditionals and Loops

```nim on:render
# Draw a grid using nested... wait, we don't have nested loops yet!
# Let's do a single loop with conditional colors

var baseY = 520
drawText("Combined Test: Loop + Conditionals", 10, baseY, 16, "yellow")

for i in range(0, 8):
  var xPos = 10 + i * 40
  var color = "blue"

  if i < 3:
    color = "red"
  elif i >= 3 and i < 6:
    color = "green"
  else:
    color = "blue"

  drawRect(xPos, baseY + 30, 35, 35, color)
```

---

**All tests should display correctly with proper colors and positions.**
