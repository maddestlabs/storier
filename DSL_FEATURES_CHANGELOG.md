# DSL Language Features - Changelog

## New Features Added

This document describes the new language features added to the Storier DSL.

### 1. Boolean Literals

**Added**: Support for `true` and `false` boolean literals

**Usage**:
```nim
var isActive = true
var isDisabled = false
```

**Implementation**:
- Parser recognizes "true" and "false" identifiers and creates boolean expressions
- AST already had boolean support (ekBool, vkBool)
- Modified: `dsl/dsl_parser.nim` - parsePrefix() function

### 2. Logical Operators

**Added**: Support for `and`, `or`, and `not` logical operators

**Usage**:
```nim
# AND operator
if x > 5 and y < 10:
  drawText("Both conditions true", 10, 10, 20, "white")

# OR operator
if x < 0 or x > 100:
  drawText("Out of range", 10, 10, 20, "white")

# NOT operator
if not isGameOver:
  drawText("Game running", 10, 10, 20, "white")
```

**Operator Precedence**:
1. `not` (unary, highest)
2. `*`, `/`, `%`
3. `+`, `-`
4. `==`, `!=`, `<`, `<=`, `>`, `>=`
5. `and`
6. `or` (lowest)

**Implementation**:
- Parser recognizes "and" and "or" as infix operators when appearing as identifiers
- Parser recognizes "not" as prefix operator when appearing as identifier
- Runtime implements short-circuit evaluation for `and` and `or`
- Modified files:
  - `dsl/dsl_parser.nim` - parsePrefix() and parseExpr() functions
  - `dsl/dsl_runtime.nim` - evalExpr() function for ekBinOp case

**Short-Circuit Evaluation**:
- `and`: If left side is false, right side is NOT evaluated
- `or`: If left side is true, right side is NOT evaluated

### 3. For Loops

**Added**: Range-based for loops with Python-like syntax

**Syntax**:
```nim
for varName in range(start, end):
  # loop body
  # varName goes from start to end-1
```

**Usage Examples**:
```nim
# Draw 5 boxes
for i in range(0, 5):
  var xPos = 10 + i * 60
  drawRect(xPos, 100, 50, 30, "blue")

# Calculate sum
var sum = 0
for i in range(1, 11):
  sum = sum + i

# Nested conditionals in loop
for i in range(0, 10):
  if i % 2 == 0:
    drawCircle(i * 30, 100, 10.0, "green")
  else:
    drawCircle(i * 30, 100, 10.0, "red")
```

**Implementation**:
- Added `skFor` to StmtKind enum
- Added for loop fields to Stmt variant (forVar, forStart, forEnd, forBody)
- Added newFor() constructor
- Parser recognizes "for varName in range(start, end):" syntax
- Runtime evaluates start and end expressions, loops from start to end-1
- Loop variable is set in environment for each iteration
- Modified files:
  - `dsl/dsl_ast.nim` - Added skFor, for loop fields, newFor() constructor
  - `dsl/dsl_parser.nim` - Added parseFor() function, updated parseStmt()
  - `dsl/dsl_runtime.nim` - Added skFor case in execStmt()

**Range Semantics**:
- `range(start, end)` iterates from `start` to `end - 1` (like Python)
- Both start and end are evaluated as expressions
- Start and end values are converted to integers

### 4. Return Statement in Loops

**Behavior**: Return statements inside for loops properly propagate up

**Usage**:
```nim
proc findFirst():
  for i in range(0, 100):
    if i % 7 == 0 and i % 13 == 0:
      return i
  return -1
```

## Testing

A comprehensive test file has been created: `test_features.md`

This test file includes:
1. Boolean literal tests
2. Logical operator tests (and, or, not)
3. Conditional tests with boolean expressions
4. For loop tests (simple loops, calculations, nested conditionals)
5. Combined tests using multiple features together

## Breaking Changes

None. All changes are backward compatible.

## Files Modified

1. `dsl/dsl_ast.nim`
   - Added skFor to StmtKind enum
   - Added for loop fields to Stmt object
   - Added newFor() constructor

2. `dsl/dsl_parser.nim`
   - Modified parsePrefix() to handle "true", "false", "not"
   - Modified parseExpr() to handle "and", "or" as infix operators
   - Added parseFor() function
   - Modified parseStmt() to recognize "for" keyword

3. `dsl/dsl_runtime.nim`
   - Modified evalExpr() to handle "and", "or" with short-circuit evaluation
   - Added skFor case in execStmt() to execute for loops

4. New files created:
   - `test_features.md` - Comprehensive test suite for new features
   - `DSL_FEATURES_CHANGELOG.md` - This file

## Examples

### Complete Example: Bouncing Balls with Conditionals and Loops

```nim
# Initialize positions
var balls = 0

# Create 10 balls
for i in range(0, 10):
  var x = 50 + i * 70
  var y = 100
  var color = "blue"

  # Choose color based on position
  if i < 3:
    color = "red"
  elif i >= 3 and i < 7:
    color = "green"
  else:
    color = "blue"

  # Draw ball
  drawCircle(x, y, 20.0, color)

# Status text
var allBallsDrawn = true
if allBallsDrawn and not false:
  drawText("All balls drawn!", 10, 10, 20, "yellow")
```

## Future Enhancements

Potential future additions:
- While loops
- Break and continue statements
- Range with step: `range(start, end, step)`
- Single-argument range: `range(n)` equivalent to `range(0, n)`
- Collection iteration: `for item in collection:`
- Array/list data types

## Notes

- The tokenizer was not modified; keyword recognition happens in the parser
- This approach keeps the tokenizer simple and language-agnostic
- All new keywords ("true", "false", "and", "or", "not", "for", "in", "range") are recognized as tkIdent tokens and handled specially by the parser
