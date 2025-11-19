# storie_raylib.nim
# Safe Raylib bindings exposed to the DSL runtime.
# Handles converting DSL Values → Raylib parameters.

import raylib
import std/[strutils, math]
import dsl_runtime
import ../engine/engine_render
import ../engine/engine_context

# ---------------------------------------------------------------------------
# Helpers to extract DSL Values into Nim/Raylib types
# ---------------------------------------------------------------------------

proc expectInt(v: Value; name="integer"): int =
  case v.kind
  of vkInt: v.i
  of vkFloat: int(v.f)
  else:
    quit "Expected " & name & ", got " & $v.kind

proc expectFloat(v: Value; name="number"): float =
  case v.kind
  of vkFloat: v.f
  of vkInt: float(v.i)
  else:
    quit "Expected " & name & ", got " & $v.kind

proc expectString(v: Value): string =
  case v.kind
  of vkString: v.s
  else:
    quit "Expected string, got " & $v.kind

proc expectBool(v: Value): bool =
  case v.kind
  of vkBool: v.b
  else:
    quit "Expected bool, got " & $v.kind

proc expectColor(v: Value): Color =
  ## Accepts:
  ##   {r:255, g:0, b:0, a:255}
  ##   "red"
  if v.kind == vkString:
    let c = v.s.toLowerAscii()
    case c
    of "white": return WHITE
    of "black": return BLACK
    of "red": return RED
    of "green": return GREEN
    of "blue": return BLUE
    of "yellow": return YELLOW
    of "orange": return ORANGE
    of "purple": return PURPLE
    of "pink": return PINK
    of "lightgray": return LIGHTGRAY
    of "gray": return GRAY
    of "darkgray": return DARKGRAY
    of "raywhite": return RAYWHITE
    of "lightblue": return Color(r: 173, g: 216, b: 230, a: 255)  # Raylib doesn't have LIGHTBLUE constant
    of "skyblue": return SKYBLUE
    of "lime": return LIME
    else:
      quit "Unknown color '" & v.s & "'"

  if v.kind == vkNil:
    quit "Expected color, got nil"

  # Struct-like value — assume a DSL JSON-like table
  quit "Color struct parsing not implemented yet"

proc expectKey(v: Value): KeyboardKey =
  ## Maps strings or ints to KeyboardKey.
  case v.kind
  of vkInt:
    return KeyboardKey(v.i)

  of vkString:
    let s = v.s.toLowerAscii()
    case s
    of "space": KeyboardKey.Space
    of "enter": KeyboardKey.Enter
    of "escape": KeyboardKey.Escape
    of "tab": KeyboardKey.Tab
    of "left": KeyboardKey.Left
    of "right": KeyboardKey.Right
    of "up": KeyboardKey.Up
    of "down": KeyboardKey.Down
    else:
      quit "Unknown key name: " & v.s

  else:
    quit "Expected key name or key code"

# ---------------------------------------------------------------------------
# Utility to wrap Raylib drawing into DSL visible native functions
# ---------------------------------------------------------------------------

# drawText(txt:string, x:int, y:int, size:int, color:Color)
proc dslDrawText*(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
  if args.len < 5:
    quit "drawText requires 5 arguments"
  let txt = expectString(args[0])
  let x   = expectInt(args[1])
  let y   = expectInt(args[2])
  let sz  = expectInt(args[3])
  let col = expectColor(args[4])

  drawTextBase(txt, x, y, sz, col)
  valNil()

# NEW ##########################################

# drawRect(x,y,w,h,color)
proc dslDrawRect*(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
  if args.len < 5:
    quit "drawRect requires 5 arguments"
  let x   = expectInt(args[0])
  let y   = expectInt(args[1])
  let w   = expectInt(args[2])
  let h   = expectInt(args[3])
  let col = expectColor(args[4])

  drawRectBase(x, y, w, h, col)
  valNil()

# drawRectLines(x,y,w,h,color)
proc dslDrawRectLines*(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
  if args.len < 5:
    quit "drawRectLines requires 5 arguments"
  let x   = expectInt(args[0])
  let y   = expectInt(args[1])
  let w   = expectInt(args[2])
  let h   = expectInt(args[3])
  let col = expectColor(args[4])

  drawRectLinesBase(x, y, w, h, col)
  valNil()

# drawCircle(x,y,radius,color)
proc dslDrawCircle*(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
  if args.len < 4:
    quit "drawCircle requires 4 arguments"

  let x      = expectInt(args[0])
  let y      = expectInt(args[1])
  let radius = expectFloat(args[2])
  let col    = expectColor(args[3])

  drawCircleBase(x, y, radius, col)
  valNil()

# clear(color)
proc dslClear*(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
  if args.len < 1:
    quit "clear requires 1 argument"
  let col = expectColor(args[0])
  clearScreen(col)
  valNil()

# isKeyDown(key)
proc dslIsKeyDown*(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
  if args.len < 1:
    quit "isKeyDown requires a key argument"
  let k = expectKey(args[0])
  valBool(isKeyDown(k))

# isKeyPressed(key)
proc dslIsKeyPressed*(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
  if args.len < 1:
    quit "isKeyPressed requires a key argument"
  let k = expectKey(args[0])
  valBool(isKeyPressed(k))

# ---------------------------------------------------------------------------
# Window & Engine values exposed to DSL
# ---------------------------------------------------------------------------

proc dslScreenWidth*(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
  valInt(int getScreenWidth())

proc dslScreenHeight*(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
  valInt(int getScreenHeight())

proc dslDeltaTime*(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
  valFloat(deltaTime)

# ---------------------------------------------------------------------------
# Registration
# ---------------------------------------------------------------------------

proc registerRaylibDSL*() =
  ## Bind all DSL-visible Raylib functions
  registerNative("drawText", dslDrawText)
  registerNative("drawRect", dslDrawRect)
  registerNative("drawRectLines", dslDrawRectLines)
  registerNative("drawCircle", dslDrawCircle)
  registerNative("clear", dslClear)

  registerNative("isKeyDown", dslIsKeyDown)
  registerNative("isKeyPressed", dslIsKeyPressed)

  registerNative("screenWidth", dslScreenWidth)
  registerNative("screenHeight", dslScreenHeight)
  registerNative("delta", dslDeltaTime)

  # Predefine common colors
  setGlobalString("WHITE", "white")
  setGlobalString("BLACK", "black")
  setGlobalString("RED", "red")
  setGlobalString("GREEN", "green")
  setGlobalString("BLUE", "blue")
  setGlobalString("YELLOW", "yellow")
