# CLAUDE.md - Storier Engine Documentation for AI Assistants

> **Last Updated:** 2025-11-18
> **Project:** Storier - Markdown-based Story/Game Engine
> **Language:** Nim
> **License:** MIT (Maddest Labs, 2025)

## Table of Contents

1. [Project Overview](#project-overview)
2. [Codebase Structure](#codebase-structure)
3. [Architecture](#architecture)
4. [Development Workflows](#development-workflows)
5. [Key Conventions](#key-conventions)
6. [DSL Language Reference](#dsl-language-reference)
7. [Extending the Engine](#extending-the-engine)
8. [Common Tasks](#common-tasks)
9. [Debugging Guide](#debugging-guide)

---

## Project Overview

**Storier** is a Raylib-based story/game engine that combines three powerful technologies:

- **Markdown**: For writing narrative content with familiar syntax
- **Nim DSL**: A custom indentation-based scripting language for interactivity
- **Raylib**: Hardware-accelerated 2D graphics rendering

### Key Features

- Parse markdown files into structured story content
- Embed interactive scripts in markdown code blocks
- Event-driven architecture (`on:render`, `on:update`, etc.)
- Full Raylib bindings accessible from DSL
- Word-wrapped markdown rendering with inline formatting
- Global persistent state across frames
- No external config files - pure Nim compilation

### Primary Use Cases

1. Interactive fiction with graphics
2. Visual novels with custom rendering
3. Educational stories with animations
4. Experimental narrative games

---

## Codebase Structure

```
storier/
├── storier.nim                 # Main entry point (107 lines)
├── storier                     # Compiled binary (ELF 64-bit)
│
├── parser/                     # Markdown parsing layer
│   ├── story_types.nim         # Data structures (StoryContent, Section, ContentBlock)
│   └── markdown_parser.nim     # Markdown → AST converter
│
├── dsl/                        # Custom scripting language
│   ├── dsl_tokenizer.nim       # Lexical analysis (indent-aware)
│   ├── dsl_ast.nim             # Abstract syntax tree definitions
│   ├── dsl_parser.nim          # Recursive descent + Pratt parser
│   ├── dsl_runtime.nim         # Execution engine with dynamic typing
│   ├── storie_raylib.nim       # Primary DSL ↔ Raylib bridge
│   ├── dsl_raylib_bindings.nim # Manual Raylib function bindings
│   └── dsl_raylib_autoreg.nim  # Macro-based auto-registration
│
├── engine/                     # Rendering and coordination
│   ├── engine_context.nim      # Frame timing (dt, frameCount)
│   ├── engine_events.nim       # Event system façade
│   ├── engine_render.nim       # Low-level Raylib wrappers
│   └── engine_markdown.nim     # Markdown rendering with word-wrap
│
└── *.md                        # Example story files
    ├── index.md                # Default story loaded by engine
    ├── minimal.md              # Minimal example
    ├── animation.md            # Animation example
    ├── sections.md             # Section example
    └── showcase.md             # Feature showcase
```

### File Size Context

- **Total LOC**: ~3,000-4,000 lines (estimated)
- **Largest modules**: markdown_parser.nim, dsl_runtime.nim, engine_markdown.nim
- **Smallest modules**: engine_events.nim (façade pattern)
- **Binary size**: ~3.4 MB (includes Raylib)

---

## Architecture

### Data Flow Overview

```
┌─────────────────────────────────────────────────────────────┐
│  Input: index.md (or fallback markdown)                     │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│  PARSER LAYER                                               │
│  ┌───────────────────┐     ┌──────────────────────┐        │
│  │ markdown_parser   │────▶│ StoryContent         │        │
│  │ - Parse blocks    │     │ - sections[]         │        │
│  │ - Inline format   │     │ - blocks[] (DSL)     │        │
│  │ - Extract DSL     │     │ - metadata (YAML)    │        │
│  └───────────────────┘     └──────────────────────┘        │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│  DSL LAYER                                                  │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌─────────┐ │
│  │Tokenizer │──▶│  Parser  │──▶│ Runtime  │──▶│ Events  │ │
│  │- Indent  │   │- AST     │   │- Values  │   │ Table   │ │
│  │- Tokens  │   │- Pratt   │   │- Env     │   │         │ │
│  └──────────┘   └──────────┘   └──────────┘   └─────────┘ │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│  ENGINE LAYER                                               │
│  ┌──────────────┐   ┌──────────────┐   ┌────────────────┐  │
│  │ Context      │   │ Markdown     │   │ Render         │  │
│  │ - dt         │   │ Renderer     │   │ - Events       │  │
│  │ - frame      │   │ - Word wrap  │   │ - Raylib calls │  │
│  └──────────────┘   └──────────────┘   └────────────────┘  │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│  RAYLIB (Graphics Output)                                   │
│  - Window management                                        │
│  - Drawing primitives                                       │
│  - Input handling                                           │
└─────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

#### Parser Layer (`parser/`)

**Purpose**: Convert markdown text into structured, typed data

**Key Types**:
```nim
# story_types.nim
type
  BlockKind* = enum
    HeadingBlock, TextBlock, CodeBlock, ListItemBlock

  MarkdownElement* = object
    text*: string
    bold*, italic*: bool
    isLink*: bool
    linkUrl*: string

  ContentBlock* = object
    kind*: BlockKind
    text*: string
    elements*: seq[MarkdownElement]  # Inline formatting
    level*: int                      # Heading level (1-5)
    code*: string                    # Code block content
    language*: string                # "nim", etc.
    metadata*: string                # "on:render", "on:update"

  Section* = object
    id*: string                      # "section_1", "section_2"
    title*: string
    level*: int
    blocks*: seq[ContentBlock]
    scripts*: Table[string, string]  # event → code
    position*: JsonNode

  StoryContent* = object
    metadata*: JsonNode              # YAML front matter
    sections*: seq[Section]          # Hierarchical sections
    blocks*: seq[ContentBlock]       # All DSL blocks (fast lookup)
```

**Parsing Flow** (markdown_parser.nim):
1. Extract YAML front matter (between `---` delimiters)
2. Split body into lines
3. State machine per line:
   - Track code block state (`inCode`, `codeLanguage`, `codeMetadata`)
   - Detect headings (`#` → `#####`) → create new sections
   - Accumulate text blocks with inline parsing
   - Detect list items (`- `)
4. For code blocks with `language="nim"` and `metadata="on:*"`:
   - Add to `StoryContent.blocks[]` for DSL registration

**Inline Parsing**:
- `**text**` → bold
- `*text*` → italic
- `[text](url)` → link
- Escape sequences supported

#### DSL Layer (`dsl/`)

**Purpose**: Provide a lightweight scripting language for interactivity

**Sub-components**:

1. **dsl_tokenizer.nim**: Lexical Analysis
   - Indent/dedent tracking (Python-style blocks)
   - Token types: `tkInt`, `tkFloat`, `tkString`, `tkIdent`, `tkOp`, `tkLParen`, `tkRParen`, `tkComma`, `tkColon`, `tkNewline`, `tkIndent`, `tkDedent`, `tkEOF`
   - String literals: `"..."` or `'...'`
   - Comments: `#` to end of line
   - Operators: `+`, `-`, `*`, `/`, `%`, `==`, `!=`, `<`, `<=`, `>`, `>=`, `and`, `or`

2. **dsl_ast.nim**: Syntax Tree Definitions
   ```nim
   type
     ExprKind* = enum
       ekInt, ekFloat, ekString, ekBool,
       ekIdent, ekBinOp, ekUnaryOp, ekCall

     Expr* = ref object
       case kind*: ExprKind
       of ekInt: intVal*: int
       of ekFloat: floatVal*: float
       of ekString: strVal*: string
       of ekBool: boolVal*: bool
       of ekIdent: ident*: string
       of ekBinOp:
         op*: string
         left*, right*: Expr
       of ekUnaryOp:
         unaryOp*: string
         unaryExpr*: Expr
       of ekCall:
         funcName*: string
         args*: seq[Expr]

     StmtKind* = enum
       skExpr, skVar, skLet, skAssign,
       skIf, skProc, skReturn, skBlock

     Stmt* = ref object
       # Variant type for each statement kind
       # skVar: varName, varValue
       # skIf: ifBranch, elifBranches, elseStmts
       # skProc: procName, params, body
       # etc.

     Program* = object
       stmts*: seq[Stmt]
   ```

3. **dsl_parser.nim**: Syntax Analysis
   - **Algorithm**: Recursive descent + Pratt parser (for operator precedence)
   - **Operator Precedence** (lowest to highest):
     1. `or`
     2. `and`
     3. `==`, `!=`, `<`, `<=`, `>`, `>=`
     4. `+`, `-`
     5. `*`, `/`, `%`
   - **Statement Parsing**:
     - `var name = expr`
     - `let name = expr`
     - `name = expr` (assignment)
     - `if cond: block elif cond: block else: block`
     - `proc name(p:type, ...): body`
     - `return expr`
   - **Indentation Handling**: Uses `tkIndent`/`tkDedent` for block structure

4. **dsl_runtime.nim**: Execution Engine
   ```nim
   type
     ValueKind* = enum
       vkNil, vkInt, vkFloat, vkBool, vkString, vkFunction

     Value* = ref object
       case kind*: ValueKind
       of vkInt: i*: int
       of vkFloat: f*: float
       of vkBool: b*: bool
       of vkString: s*: string
       of vkFunction: fnVal*: FunctionVal

     FunctionVal* = ref object
       isNative*: bool
       native*: NativeFunc         # Nim callback
       params*: seq[string]        # Parameter names
       stmts*: seq[Stmt]           # User-defined body

     Env* = object
       vars*: Table[string, Value]
       parent*: ref Env            # Lexical scoping

   var runtimeEnv*: ref Env        # Global environment
   var events*: Table[string, Program]  # Event registry
   ```

   **Key Functions**:
   - `proc registerEvent*(name: string; prog: Program)` - Store event handler
   - `proc triggerEvent*(name: string)` - Execute event handler
   - `proc execProgram*(prog: Program; env: ref Env)` - Run statements
   - `proc evalExpr*(e: Expr; env: ref Env): Value` - Evaluate expression
   - `proc registerNative*(name: string; fn: NativeFunc)` - Bind Nim function

5. **storie_raylib.nim**: Primary Raylib Bridge
   - Registers common drawing functions as DSL natives
   - Color parsing (string → Raylib Color)
   - Key mapping (string → KeyboardKey enum)

   **Available DSL Functions**:
   ```nim
   drawText(text:str, x:int, y:int, size:int, color:str)
   drawRect(x:int, y:int, w:int, h:int, color:str)
   drawRectLines(x:int, y:int, w:int, h:int, color:str)
   drawCircle(x:int, y:int, radius:float, color:str)
   clear(color:str)
   isKeyDown(key:str) -> bool
   isKeyPressed(key:str) -> bool
   screenWidth() -> int
   screenHeight() -> int
   delta() -> float
   ```

   **Colors**: "white", "black", "red", "green", "blue", "yellow", "orange", "purple", "pink", "lightgray", "gray", "darkgray", "raywhite", "lightblue", "skyblue", "lime"

   **Keys**: "space", "enter", "escape", "tab", "left", "right", "up", "down", "a"-"z", "0"-"9"

6. **dsl_raylib_bindings.nim**: Manual bindings (lower-level)
7. **dsl_raylib_autoreg.nim**: Macro-based auto-registration
   - Uses Nim macros to introspect Raylib functions
   - Automatically generates DSL wrappers
   - Example:
     ```nim
     autoRegisterRaylib(DrawText, DrawRectangle, ClearBackground)
     ```

#### Engine Layer (`engine/`)

**Purpose**: Coordinate rendering, timing, and events

1. **engine_context.nim**: Frame Timing
   ```nim
   var
     lastTime*: float      # Previous frame timestamp
     deltaTime*: float     # Frame delta in seconds
     frameCount*: int      # Total frames rendered

   proc updateGlobals*() =
     # Updates dt, frameCount
     # Syncs to DSL globals: dt, screenWidth, screenHeight, frame
   ```

2. **engine_events.nim**: Event System Façade
   - Thin wrapper over dsl_runtime.registerEvent/triggerEvent
   - Minimal implementation

3. **engine_render.nim**: Low-Level Raylib Wrappers
   ```nim
   proc clearScreen*(color: Color)
   proc drawTextBase*(txt: string; x, y, size: int; col: Color)
   proc drawRectBase*(x, y, w, h: int; col: Color)
   proc drawRectLinesBase*(x, y, w, h: int; col: Color)
   proc drawCircleBase*(cx, cy: int; radius: float; col: Color)
   proc render*()  # Triggers "on:render" event
   ```

4. **engine_markdown.nim**: Markdown Rendering
   - **Region Support**:
     ```nim
     var mdX*, mdY*: int = 40      # Start position
     var mdW*, mdH*: int = 0       # 0 = full screen
     proc setMarkdownRegion*(x, y, w, h: int)
     ```
   - **Block Rendering**:
     - Headings: Scaled font size (H1=38px, H2=32px, ..., H5=18px)
     - Text: Word-wrapped paragraphs with inline formatting
     - Code blocks: Indented, yellow backticks, light gray text
     - Lists: Bullet points with word wrap
   - **Inline Formatting**:
     - Bold → YELLOW
     - Italic → LIGHTGRAY
     - Links → SKYBLUE
   - **Word Wrap Algorithm**:
     ```
     For each word in text:
       Measure "currentLine word"
       If width > maxWidth:
         Draw currentLine
         Start new line with word
       Else:
         Append word to currentLine
     ```
   - **Custom Renderer Hook**:
     ```nim
     var markdownRenderer*: proc(content: StoryContent) = nil
     proc renderMarkdown*(content: StoryContent) =
       if markdownRenderer != nil:
         markdownRenderer(content)
       else:
         defaultRenderer(content)
     ```

### Main Entry Point (`storier.nim`)

**Execution Flow**:
```nim
proc main() =
  # 1. Initialize Raylib window
  initWindow(800, 600, "Storie Engine")
  setTargetFPS(60)

  # 2. Initialize engine subsystems
  initContext()           # Frame timing
  initRuntime()           # DSL runtime environment
  registerRaylibDSL()     # Bind Raylib functions to DSL

  # 3. Load story content
  loadStoryRuntime()      # Parse index.md → register DSL events

  # 4. Main loop
  runMainLoop()           # Render until window closed

  # 5. Cleanup
  closeWindow()

proc loadStoryRuntime() =
  # Load index.md or fallback markdown
  let markdown = if fileExists("index.md"):
    readFile("index.md")
  else:
    fallbackMarkdown

  # Parse markdown into StoryContent
  currentStory = parseMarkdown(markdown)

  # Register DSL event handlers
  for codeBlock in currentStory.blocks:
    if codeBlock.language == "nim" and codeBlock.metadata.startsWith("on:"):
      let tokens = tokenizeDsl(codeBlock.code)
      let program = parseDsl(tokens)
      registerEvent(codeBlock.metadata, program)

proc runMainLoop() =
  while not windowShouldClose():
    updateGlobals()       # Update dt, frame, etc.

    beginDrawing()
    clearBackground(Black)

    # Render markdown content
    renderMarkdown(currentStory)

    # Optional: Trigger render event for DSL scripts
    # triggerEvent("on:render")

    endDrawing()
```

---

## Development Workflows

### Building the Project

**Standard Compilation**:
```bash
nim c storier.nim
```

**Optimized Release Build**:
```bash
nim c -d:release storier.nim
```

**With Debugging**:
```bash
nim c --debugger:native storier.nim
```

**Dependencies**:
- Nim compiler (1.6+ recommended)
- Raylib (via Naylib wrapper) - typically installed via Nimble
- No external build configuration files required

### Running the Engine

```bash
# Run compiled binary
./storier

# Or compile and run in one step
nim c -r storier.nim
```

**Story File Loading**:
- Default: Loads `index.md` from current working directory
- Fallback: If `index.md` not found, uses embedded fallback markdown
- To use different story: Replace `index.md` or modify `loadMarkdown()` in storier.nim:37-44

### Typical Development Cycle

1. **Modify Story Content**:
   - Edit `index.md` or create new `.md` file
   - Add markdown content (headings, text, lists)
   - Embed DSL scripts in code blocks:
     ```markdown
     ```nim on:render
     drawText("Hello", 100, 100, 20, "white")
     ```
     ```

2. **Test Changes**:
   - No recompilation needed for markdown changes
   - Just restart `./storier`
   - DSL errors appear in console output

3. **Modify Engine Code**:
   - Edit `.nim` files in `parser/`, `dsl/`, or `engine/`
   - Recompile: `nim c storier.nim`
   - Test in engine

4. **Add New DSL Functions**:
   - See [Extending the Engine](#extending-the-engine) section

### Git Workflow

**Current Branch**: `claude/claude-md-mi585wo6nwwkjqsh-014MVbHuLNo3tfoWAy4KcVUa`

**Important**:
- Always develop on designated feature branch
- Branch must start with `claude/` and end with matching session ID
- Push failures (403) indicate branch name mismatch

**Standard Git Commands**:
```bash
# Check status
git status

# Commit changes
git add <files>
git commit -m "Description"

# Push to remote
git push -u origin <branch-name>

# If push fails with network error, retry with exponential backoff:
# Try 1: immediate
# Try 2: wait 2s
# Try 3: wait 4s
# Try 4: wait 8s
# Try 5: wait 16s
```

---

## Key Conventions

### Code Style

**Nim Style Guide**:
- Use `camelCase` for variables and functions
- Use `PascalCase` for types
- Public exports marked with `*` suffix
- Indentation: 2 spaces (standard Nim)
- Line length: No strict limit, ~100 chars preferred

**Module Naming**:
- Prefix with layer: `dsl_*`, `engine_*`, `markdown_*`
- Descriptive names: `dsl_tokenizer`, `engine_render`

**Comments**:
- Use `#` for line comments
- Add separator comments for major sections:
  ```nim
  # ------------------------------------------------------------------------------
  # Section Title
  # ------------------------------------------------------------------------------
  ```

### File Organization

**Import Order** (see storier.nim:1-20):
1. Nim standard library
2. Parser layer imports
3. DSL layer imports
4. Engine layer imports
5. External libraries (raylib)
6. Bindings

**Exports**:
- Mark public APIs with `*`: `proc foo*() = ...`
- Keep internal helpers private: `proc helperFunc() = ...`

### Naming Conventions

**Variables**:
- Global state: `currentStory`, `runtimeEnv`, `events`
- Frame timing: `deltaTime`, `frameCount`, `lastTime`
- Markdown region: `mdX`, `mdY`, `mdW`, `mdH`

**Functions**:
- Imperative verbs: `loadMarkdown()`, `parseMarkdown()`, `registerEvent()`
- DSL bindings: Prefix with `dsl`: `dslDrawText()`, `dslIsKeyDown()`
- Engine functions: Descriptive: `updateGlobals()`, `renderMarkdown()`

**Types**:
- Suffix with kind: `BlockKind`, `ExprKind`, `StmtKind`, `ValueKind`
- Descriptive: `StoryContent`, `MarkdownElement`, `ContentBlock`

### Error Handling

**Current Approach**:
- Runtime errors: Echo to console, may crash
- Parse errors: Echo to console, may crash
- Missing files: Fallback to embedded content

**DSL Error Messages**:
```nim
echo "Error: Unknown function: ", funcName
echo "Type error: Expected int, got ", value.kind
```

**Recommended Pattern**:
- Check preconditions
- Echo descriptive error
- Return nil/default value or raise exception

### DSL Event Conventions

**Event Naming**:
- Prefix with `on:`: `on:render`, `on:update`, `on:click`
- Use lowercase: `on:keypress` not `on:KeyPress`
- Descriptive: `on:mousedown` not `on:md`

**Event Registration** (in markdown):
```markdown
```nim on:render
# Code executed every frame during rendering
drawText("Hello", 100, 100, 20, "white")
```
```

**Event Triggering** (in engine code):
```nim
triggerEvent("on:render")
```

### Testing Conventions

**No Formal Test Suite**: Currently manual testing only

**Recommended Testing Approach**:
1. Create test story files: `test_*.md`
2. Run engine with test file
3. Verify visual output and console logs
4. Check for crashes or error messages

**Example Test Story**:
```markdown
# Test: Drawing Functions

```nim on:render
drawText("Text Test", 10, 10, 20, "white")
drawRect(10, 40, 100, 50, "red")
drawCircle(200, 100, 30.0, "blue")
```
```

---

## DSL Language Reference

### Syntax Overview

**Indentation-Based Blocks** (like Python):
```nim
if x > 5:
  drawText("Big", 10, 10, 20, "white")
  drawRect(10, 40, 100, 50, "red")
else:
  drawText("Small", 10, 10, 20, "gray")
```

**Comments**:
```nim
# This is a comment
var x = 10  # Inline comment
```

### Data Types

**Primitive Types**:
```nim
var i = 42              # Integer
var f = 3.14            # Float
var s = "Hello"         # String
var b = true            # Boolean (true/false)
var n = nil             # Nil
```

**Type Coercion**:
- `int` ↔ `float`: Automatic in arithmetic
- `any` → `bool`: `nil`/`false` = false, others = true
- `any` → `string`: Automatic in `drawText()`

### Variables

**Mutable Variables**:
```nim
var counter = 0
counter = counter + 1
```

**Constants**:
```nim
let maxSpeed = 100
# maxSpeed = 200  # Error: cannot reassign
```

**Global Variables** (persist across frames):
```nim
# In on:update
var pos = 0  # Only creates on first frame
pos = pos + 1

# In on:render
drawCircle(pos, 100, 10.0, "red")  # Uses updated pos
```

### Operators

**Arithmetic**:
```nim
a + b    # Addition
a - b    # Subtraction
a * b    # Multiplication
a / b    # Division
a % b    # Modulo
```

**Comparison**:
```nim
a == b   # Equal
a != b   # Not equal
a < b    # Less than
a <= b   # Less than or equal
a > b    # Greater than
a >= b   # Greater than or equal
```

**Logical**:
```nim
a and b  # Logical AND
a or b   # Logical OR
not a    # Logical NOT (unary)
```

**Precedence** (highest to lowest):
1. `*`, `/`, `%`
2. `+`, `-`
3. `==`, `!=`, `<`, `<=`, `>`, `>=`
4. `and`
5. `or`

### Control Flow

**If Statements**:
```nim
if condition:
  statement1
  statement2
elif otherCondition:
  statement3
else:
  statement4
```

**Nested Conditions**:
```nim
if x > 0:
  if y > 0:
    drawText("Quadrant 1", 10, 10, 20, "white")
  else:
    drawText("Quadrant 4", 10, 10, 20, "white")
else:
  drawText("Left side", 10, 10, 20, "white")
```

### Functions

**User-Defined Functions**:
```nim
proc double(n:int):
  return n * 2

var result = double(5)  # result = 10
```

**Multiple Parameters**:
```nim
proc add(a:int, b:int):
  return a + b

var sum = add(3, 7)
```

**No Return Value**:
```nim
proc greet():
  drawText("Hello!", 10, 10, 20, "white")

greet()
```

**Native Functions** (built-in, provided by engine):
- See [Built-in Functions](#built-in-functions) section

### Built-in Functions

**Drawing Functions**:
```nim
drawText(text:str, x:int, y:int, size:int, color:str)
# Example: drawText("Hello", 100, 50, 24, "white")

drawRect(x:int, y:int, width:int, height:int, color:str)
# Example: drawRect(10, 10, 100, 50, "red")

drawRectLines(x:int, y:int, width:int, height:int, color:str)
# Example: drawRectLines(10, 10, 100, 50, "blue")

drawCircle(x:int, y:int, radius:float, color:str)
# Example: drawCircle(200, 200, 50.0, "yellow")

clear(color:str)
# Example: clear("black")
```

**Input Functions**:
```nim
isKeyDown(key:str) -> bool
# Example: if isKeyDown("space"): drawText("Space held", 10, 10, 20, "white")

isKeyPressed(key:str) -> bool
# Example: if isKeyPressed("enter"): drawText("Enter pressed", 10, 10, 20, "white")
```

**System Functions**:
```nim
screenWidth() -> int
# Returns window width in pixels

screenHeight() -> int
# Returns window height in pixels

delta() -> float
# Returns frame delta time in seconds (same as global dt)
```

**Global Variables** (automatically set by engine):
```nim
dt           # Frame delta time (float)
screenWidth  # Window width (int)
screenHeight # Window height (int)
frame        # Frame number (int)
```

### Color Reference

**Named Colors**:
- `"white"`, `"black"`
- `"red"`, `"green"`, `"blue"`
- `"yellow"`, `"orange"`, `"purple"`, `"pink"`
- `"lightgray"`, `"gray"`, `"darkgray"`
- `"raywhite"`, `"lightblue"`, `"skyblue"`, `"lime"`

### Key Reference

**Special Keys**:
- `"space"`, `"enter"`, `"escape"`, `"tab"`
- `"left"`, `"right"`, `"up"`, `"down"`

**Alphanumeric**:
- `"a"` through `"z"`
- `"0"` through `"9"`

### Complete Example

```nim
# Animation example with input
var ballX = 100
var ballY = 100
var speedX = 2
var speedY = 2

# Move ball
ballX = ballX + speedX
ballY = ballY + speedY

# Bounce on edges
if ballX < 0 or ballX > screenWidth:
  speedX = speedX * -1

if ballY < 0 or ballY > screenHeight:
  speedY = speedY * -1

# User control
if isKeyDown("left"):
  ballX = ballX - 5

if isKeyDown("right"):
  ballX = ballX + 5

# Draw
clear("black")
drawCircle(ballX, ballY, 20.0, "red")
drawText("Use arrow keys", 10, 10, 20, "white")
```

---

## Extending the Engine

### Adding New DSL Functions

**Step 1**: Implement native function in `dsl/storie_raylib.nim`:

```nim
proc dslMyFunction(env: ref Env; args: seq[Value]): Value =
  # Validate argument count
  if args.len != 2:
    echo "Error: myFunction expects 2 arguments"
    return valNil()

  # Extract arguments with type checking
  if args[0].kind != vkInt:
    echo "Error: Argument 1 must be int"
    return valNil()

  if args[1].kind != vkString:
    echo "Error: Argument 2 must be string"
    return valNil()

  let num = args[0].i
  let text = args[1].s

  # Implement functionality
  echo "My function called with: ", num, ", ", text

  # Return value
  return valInt(num * 2)
```

**Step 2**: Register in `registerRaylibDSL()`:

```nim
proc registerRaylibDSL*() =
  # ... existing registrations ...
  registerNative("myFunction", dslMyFunction)
```

**Step 3**: Use in DSL:

```markdown
```nim on:render
var result = myFunction(42, "Hello")
drawText(result, 10, 10, 20, "white")
```
```

### Adding New Event Types

**Step 1**: Define event trigger in appropriate engine module:

```nim
# In engine/engine_events.nim or engine/engine_render.nim
proc handleMouseClick*() =
  triggerEvent("on:click")
```

**Step 2**: Call in main loop:

```nim
# In storier.nim runMainLoop()
while not windowShouldClose():
  updateGlobals()

  # Check for mouse click
  if isMouseButtonPressed(0):
    handleMouseClick()

  beginDrawing()
  # ... existing rendering ...
  endDrawing()
```

**Step 3**: Use in story markdown:

```markdown
```nim on:click
drawText("Clicked!", 100, 100, 30, "red")
```
```

### Adding New Markdown Block Types

**Step 1**: Add to `BlockKind` enum in `parser/story_types.nim`:

```nim
type
  BlockKind* = enum
    HeadingBlock
    TextBlock
    CodeBlock
    ListItemBlock
    ImageBlock      # New block type
```

**Step 2**: Update `ContentBlock` type:

```nim
type
  ContentBlock* = object
    kind*: BlockKind
    # ... existing fields ...
    imagePath*: string        # New field for images
    imageAlt*: string
```

**Step 3**: Add parsing logic in `parser/markdown_parser.nim`:

```nim
# In parseMarkdown() line-by-line loop
if line.startsWith("!["):
  # Parse ![alt](path) syntax
  let altStart = line.find("[") + 1
  let altEnd = line.find("]")
  let pathStart = line.find("(") + 1
  let pathEnd = line.find(")")

  let imageBlock = ContentBlock(
    kind: ImageBlock,
    imageAlt: line[altStart..<altEnd],
    imagePath: line[pathStart..<pathEnd]
  )
  currentSection.blocks.add(imageBlock)
```

**Step 4**: Add rendering in `engine/engine_markdown.nim`:

```nim
# In renderMarkdown() block rendering section
of ImageBlock:
  # Load and draw image using Raylib
  let texture = loadTexture(blk.imagePath)
  drawTexture(texture, posX, posY, White)
  posY += texture.height + 4
```

### Custom Markdown Renderer

**Example: Split-Screen Layout**

```nim
# In your custom module or storier.nim
proc splitScreenRenderer(content: StoryContent) =
  # Left panel: Markdown
  setMarkdownRegion(0, 0, 400, 600)
  defaultMarkdownRenderer(content)

  # Right panel: Custom DSL rendering area
  drawRectLines(400, 0, 400, 600, White)
  triggerEvent("on:render")

# Set as active renderer
markdownRenderer = splitScreenRenderer
```

### Macro-Based Raylib Auto-Binding

**To add bulk Raylib functions**:

```nim
# In dsl/dsl_raylib_autoreg.nim
autoRegisterRaylib(
  DrawLine,
  DrawTriangle,
  DrawPoly,
  MeasureText,
  LoadTexture,
  DrawTexture
)
```

**Requirements**:
- Function parameters must be supported types: `int`, `float32`, `bool`, `string`, `Color`
- Return types: `void`, `int`, `float32`, `bool`, `string`
- Complex types require manual bindings

---

## Common Tasks

### Task 1: Create a New Story

**Steps**:
1. Create new markdown file: `my_story.md`
2. Add content:
   ```markdown
   # My Interactive Story

   This is a paragraph with **bold** and *italic* text.

   ## Chapter 1

   The adventure begins here.

   ```nim on:render
   drawText("Custom rendering", 10, 250, 22, "yellow")
   ```
   ```

3. Either:
   - Rename to `index.md` (default)
   - OR modify `storier.nim:38` to load your file:
     ```nim
     let path = getCurrentDir() / "my_story.md"
     ```
4. Run: `./storier`

### Task 2: Add Interactive Animation

**Example: Bouncing Ball**

```markdown
# Bouncing Ball Demo

Watch the ball bounce!

```nim on:update
var ballX = 400
var ballY = 0
var ballVY = 0
var ballVY = ballVY + 0.5  # Gravity

ballY = ballY + ballVY

if ballY > 500:
  ballY = 500
  ballVY = ballVY * -0.8  # Bounce with damping

ballX = ballX
```

```nim on:render
drawCircle(ballX, ballY, 20.0, "red")
```
```

### Task 3: Handle Keyboard Input

**Example: Arrow Key Movement**

```markdown
```nim on:update
var playerX = 400
var playerY = 300

if isKeyDown("left"):
  playerX = playerX - 3

if isKeyDown("right"):
  playerX = playerX + 3

if isKeyDown("up"):
  playerY = playerY - 3

if isKeyDown("down"):
  playerY = playerY + 3
```

```nim on:render
drawCircle(playerX, playerY, 15.0, "blue")
drawText("Use arrow keys to move", 10, 10, 20, "white")
```
```

### Task 4: Debug DSL Code

**Approach**:
1. Add debug output in DSL:
   ```nim
   var x = 100
   # No print() function available, use drawText for debugging
   drawText("Debug: x = ", 10, 10, 16, "yellow")
   ```

2. Check console for runtime errors:
   ```
   Error: Unknown function: myFunc
   Type error: Expected int, got string
   ```

3. Verify event registration:
   - Check console on startup for:
     ```
     DSL EVENT: on:render
     <code printed here>
     ```

4. Test in isolation:
   - Create minimal test story with only problematic code
   - Remove complexity until error disappears
   - Gradually add back to find issue

### Task 5: Add New Raylib Drawing Function

**Example: Draw Line**

```nim
# In dsl/storie_raylib.nim

proc dslDrawLine(env: ref Env; args: seq[Value]): Value =
  if args.len != 5:
    echo "drawLine requires 5 arguments: x1, y1, x2, y2, color"
    return valNil()

  if args[0].kind != vkInt or args[1].kind != vkInt or
     args[2].kind != vkInt or args[3].kind != vkInt:
    echo "First 4 arguments must be integers"
    return valNil()

  if args[4].kind != vkString:
    echo "Last argument must be color string"
    return valNil()

  let x1 = args[0].i
  let y1 = args[1].i
  let x2 = args[2].i
  let y2 = args[3].i
  let colorStr = args[4].s

  let col = parseColor(colorStr)
  drawLine(x1.int32, y1.int32, x2.int32, y2.int32, col)

  return valNil()

# In registerRaylibDSL():
proc registerRaylibDSL*() =
  # ... existing ...
  registerNative("drawLine", dslDrawLine)
```

**Usage**:
```nim
drawLine(10, 10, 100, 100, "red")
```

### Task 6: Modify Markdown Rendering Style

**Example: Change Heading Colors**

```nim
# In engine/engine_markdown.nim

# Find heading rendering section (around line 80-100)
of HeadingBlock:
  let hSize = case blk.level
    of 1: 38
    of 2: 32
    of 3: 28
    of 4: 22
    else: 18

  # Change this line:
  # drawTextBase(blk.text, posX, posY, hSize, White)

  # To custom colors:
  let hColor = case blk.level
    of 1: Yellow      # H1 = yellow
    of 2: SkyBlue     # H2 = sky blue
    else: White       # H3+ = white

  drawTextBase(blk.text, posX, posY, hSize, hColor)
```

### Task 7: Parse Custom Metadata

**Example: Section-Level DSL Scripts**

Currently, scripts are global. To add per-section scripts:

```nim
# In parser/markdown_parser.nim
# After creating a new section:

proc parseMarkdown*(text: string): StoryContent =
  # ... existing code ...

  # After detecting heading and creating section:
  if line.startsWith("#"):
    currentSection = Section(
      id: fmt"section_{sectionId}",
      title: title,
      level: level,
      blocks: @[],
      scripts: initTable[string, string](),  # Initialize
      position: newJNull()
    )

  # When encountering code block in this section:
  if codeBlock.language == "nim" and codeBlock.metadata.startsWith("on:"):
    currentSection.scripts[codeBlock.metadata] = codeBlock.code
```

**Usage** (trigger section-specific events):
```nim
# In engine code
proc renderSection(section: Section) =
  for event, code in section.scripts:
    if event == "on:sectionRender":
      # Parse and execute section-specific code
      let tokens = tokenizeDsl(code)
      let prog = parseDsl(tokens)
      execProgram(prog, runtimeEnv)
```

---

## Debugging Guide

### Common Issues

#### 1. "index.md not found"

**Cause**: Running `./storier` from wrong directory

**Solution**:
```bash
cd /path/to/storier
./storier
```

Or create `index.md` in current directory.

#### 2. DSL Code Not Executing

**Symptoms**: Code block visible in markdown but no effect

**Debug Steps**:
1. Check code block syntax:
   ```markdown
   ```nim on:render
   drawText("Test", 10, 10, 20, "white")
   ```
   ```
   - Must be triple backticks
   - Language must be `nim`
   - Metadata must start with `on:`

2. Check console for errors:
   - Tokenizer errors: Invalid syntax
   - Parser errors: Malformed statements
   - Runtime errors: Unknown function, type mismatch

3. Verify event is triggered:
   - `on:render` triggers every frame automatically
   - `on:update` must be called manually (not in default loop)
   - Custom events require explicit `triggerEvent()` calls

#### 3. "Unknown function" Error

**Cause**: Function not registered or misspelled

**Check**:
- Function name matches registered name exactly (case-sensitive)
- Function registered in `registerRaylibDSL()` in dsl/storie_raylib.nim
- No typos: `drawText` not `drawtext`

#### 4. Type Mismatch Errors

**Cause**: Passing wrong type to function

**Example**:
```nim
drawText("Hello", "100", 10, 20, "white")  # Error: "100" is string, not int
```

**Solution**:
```nim
drawText("Hello", 100, 10, 20, "white")    # Correct: 100 is int
```

#### 5. Indentation Errors

**Cause**: Inconsistent indentation in DSL code

**Bad**:
```nim
if x > 5:
  drawText("Big", 10, 10, 20, "white")
    drawRect(10, 40, 100, 50, "red")  # Extra indent
```

**Good**:
```nim
if x > 5:
  drawText("Big", 10, 10, 20, "white")
  drawRect(10, 40, 100, 50, "red")
```

#### 6. Variable Scope Issues

**Symptom**: Variable resets every frame

**Cause**: Using `let` instead of `var`, or re-declaring with `var`

**Bad**:
```nim
# on:update
var counter = 0      # Re-declared every frame
counter = counter + 1
```

**Good**:
```nim
# on:update (first frame)
var counter = 0      # Declared once, persists

# on:update (subsequent frames)
counter = counter + 1  # Just reassign
```

**Best Practice**: Use initialization check:
```nim
var counter = 0  # Only creates if doesn't exist
counter = counter + 1
```

#### 7. Compilation Errors

**Common Nim Errors**:
- `undeclared identifier`: Import missing or typo
- `type mismatch`: Check function signatures
- `cannot open file`: Module not found

**Solution**:
```bash
# Check imports
nim check storier.nim

# Verbose compilation
nim c --hints:on --warnings:on storier.nim
```

### Debugging Techniques

#### Console Output

**Add debug output in Nim code**:
```nim
echo "Debug: currentStory.sections.len = ", currentStory.sections.len
echo "Debug: DSL block code = ", codeBlock.code
```

**Check runtime state**:
```nim
# In dsl_runtime.nim
echo "Executing event: ", eventName
echo "Current env vars: ", env.vars
```

#### Visual Debugging

**In DSL code**:
```nim
# Show variable values on screen
drawText("x = ", 10, 10, 16, "yellow")
drawText(x, 50, 10, 16, "yellow")

# Show bounding boxes
drawRectLines(x, y, w, h, "red")

# Show frame count
drawText(frame, 10, 30, 16, "white")
```

#### Minimal Reproduction

**Steps**:
1. Copy problematic code to new minimal story:
   ```markdown
   # Debug

   ```nim on:render
   var x = 100
   drawCircle(x, 100, 20.0, "red")
   ```
   ```

2. Run and verify error persists
3. Simplify until error disappears
4. Identify minimal failing case

#### Source Code Inspection

**Key places to add debug output**:
- `parser/markdown_parser.nim:parseMarkdown()` - Check parsing
- `dsl/dsl_tokenizer.nim:tokenizeDsl()` - Check tokens
- `dsl/dsl_parser.nim:parseDsl()` - Check AST
- `dsl/dsl_runtime.nim:execStmt()` - Check execution
- `dsl/storie_raylib.nim:dslDrawText()` - Check function calls

### Performance Debugging

**Frame Rate Issues**:
```nim
# In engine/engine_context.nim
proc updateGlobals*() =
  let currentTime = getTime()
  deltaTime = currentTime - lastTime
  lastTime = currentTime
  frameCount += 1

  # Add FPS counter
  if frameCount mod 60 == 0:
    echo "FPS: ", 1.0 / deltaTime
```

**Profiling**:
```bash
# Compile with profiling
nim c --profiler:on --stackTrace:on storier.nim

# Run and generate profile
./storier
# Profile written to profile_results.txt
```

---

## AI Assistant Guidelines

### When Asked to Modify Code

1. **Always read files first**: Use Read tool before Edit/Write
2. **Understand context**: Read related modules to understand dependencies
3. **Follow conventions**: Match existing code style and naming
4. **Test changes**: Verify compilation after modifications
5. **Explain changes**: Describe what was changed and why

### When Asked to Debug

1. **Gather information**:
   - Read error messages carefully
   - Check relevant source files
   - Understand data flow

2. **Identify root cause**:
   - Trace execution path
   - Check type mismatches
   - Verify function signatures

3. **Propose solution**:
   - Suggest minimal fix
   - Explain why it works
   - Mention potential side effects

### When Asked to Add Features

1. **Clarify requirements**:
   - What should the feature do?
   - Where should it integrate?
   - Any performance concerns?

2. **Plan implementation**:
   - Which modules to modify?
   - New types/functions needed?
   - Breaking changes?

3. **Implement incrementally**:
   - Start with data structures
   - Add parsing/processing
   - Add rendering/execution
   - Test each step

4. **Document**:
   - Update this CLAUDE.md
   - Add code comments
   - Provide usage examples

### When Asked About Architecture

1. **Refer to this document**: Use diagrams and explanations above
2. **Provide file references**: Include line numbers (e.g., storier.nim:37-44)
3. **Explain relationships**: How components interact
4. **Give examples**: Show real code from the project

### Code Quality Checklist

Before completing any code task:

- [ ] Code compiles without errors
- [ ] Follows Nim style guide (camelCase, 2-space indent)
- [ ] Functions have clear names and purposes
- [ ] Type safety maintained (proper Value kinds)
- [ ] Error messages are descriptive
- [ ] No obvious performance issues
- [ ] Existing functionality not broken
- [ ] Changes documented in code comments

### Common Pitfalls to Avoid

1. **Don't break DSL runtime**: Changes to Value/Env types affect entire system
2. **Don't ignore indentation**: DSL parser is indent-sensitive
3. **Don't modify parser without updating types**: Keep story_types.nim in sync
4. **Don't add Raylib calls without DSL bindings**: Users need DSL access
5. **Don't assume file exists**: Check with `fileExists()` before `readFile()`

---

## Appendix

### File Reference Quick Links

- **Main Entry**: storier.nim:1-107
- **Markdown Parsing**: parser/markdown_parser.nim
- **Markdown Types**: parser/story_types.nim
- **DSL Tokenizer**: dsl/dsl_tokenizer.nim
- **DSL Parser**: dsl/dsl_parser.nim
- **DSL Runtime**: dsl/dsl_runtime.nim
- **DSL Raylib Bindings**: dsl/storie_raylib.nim
- **Engine Timing**: engine/engine_context.nim
- **Markdown Rendering**: engine/engine_markdown.nim
- **Raylib Wrappers**: engine/engine_render.nim

### External Resources

- **Nim Language**: https://nim-lang.org/docs/manual.html
- **Raylib**: https://www.raylib.com/
- **Naylib (Nim Raylib)**: https://github.com/planetis-m/naylib

### Version History

- **v0.1** (2025-11-18): Initial documentation created from codebase analysis

---

**End of CLAUDE.md**
