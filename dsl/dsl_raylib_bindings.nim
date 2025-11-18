# dsl_raylib_bindings.nim
# Native DSL bindings for Raylib drawing operations.

import std/[strutils, tables]
import raylib
import dsl_runtime
import engine_render


# ------------------------------------------------------------------------------
# Color map (string → Raylib Color)
# Add any colors you like.
# ------------------------------------------------------------------------------

let colorMap*: Table[string, Color] = {
  "white": WHITE,
  "black": BLACK,
  "red": RED,
  "green": GREEN,
  "blue": BLUE,
  "yellow": YELLOW,
  "purple": PURPLE,
  "pink": PINK,
  "orange": ORANGE,
  "gray": GRAY,
  "lightgray": LIGHTGRAY,
  "darkgray": DARKGRAY
}.toTable()


proc getColor*(v: Value): Color =
  ## Convert a DSL Value to a Raylib Color.
  if v.kind == vkString:
    let key = v.s.toLowerAscii()
    if key in colorMap:
      return colorMap[key]
    else:
      quit "Unknown color: " & v.s
  else:
    quit "Expected color string, got: " & $v


# ------------------------------------------------------------------------------
# Argument helpers
# ------------------------------------------------------------------------------

proc expectInt(args: seq[Value]; index: int): int =
  if index >= args.len:
    quit "Missing integer argument at index " & $index
  case args[index].kind
  of vkInt: args[index].i
  of vkFloat: int(args[index].f)
  else: quit "Expected integer, got: " & $args[index]

proc expectFloat(args: seq[Value]; index: int): float =
  if index >= args.len:
    quit "Missing float argument at index " & $index
  case args[index].kind
  of vkFloat: args[index].f
  of vkInt: float(args[index].i)
  else: quit "Expected float, got: " & $args[index]

proc expectString(args: seq[Value]; index: int): string =
  if index >= args.len:
    quit "Missing string argument at index " & $index
  if args[index].kind == vkString:
    return args[index].s
  quit "Expected string, got: " & $args[index]


# ------------------------------------------------------------------------------
# DrawText binding: drawText(text, x, y, fontSize, color)
# ------------------------------------------------------------------------------

proc dslDrawText(env: ref Env; args: seq[Value]): Value =
  if args.len < 5:
    quit "drawText expects 5 args: text, x, y, size, color"

  let txt = expectString(args, 0)
  let x   = expectInt(args, 1)
  let y   = expectInt(args, 2)
  let size = expectInt(args, 3)
  let col = getColor(args[4])

  drawTextBase(txt, x, y, size, col)
  return valNil()


# ------------------------------------------------------------------------------
# DrawRect binding: drawRect(x, y, w, h, color)
# ------------------------------------------------------------------------------

proc dslDrawRect(env: ref Env; args: seq[Value]): Value =
  if args.len < 5:
    quit "drawRect expects 5 args: x, y, w, h, color"

  let x = expectInt(args, 0)
  let y = expectInt(args, 1)
  let w = expectInt(args, 2)
  let h = expectInt(args, 3)
  let col = getColor(args[4])

  drawRectBase(x, y, w, h, col)
  return valNil()


# ------------------------------------------------------------------------------
# DrawCircle binding: drawCircle(cx, cy, radius, color)
# ------------------------------------------------------------------------------

proc dslDrawCircle(env: ref Env; args: seq[Value]): Value =
  if args.len < 4:
    quit "drawCircle expects 4 args: cx, cy, radius, color"

  let cx = expectInt(args, 0)
  let cy = expectInt(args, 1)
  let r  = expectInt(args, 2)
  let col = getColor(args[3])

  drawCircleBase(cx, cy, r, col)
  return valNil()


# ------------------------------------------------------------------------------
# Initialization: Register all native functions into DSL runtime
# ------------------------------------------------------------------------------

proc initRaylibBindings*() =
  ## Call this after initRuntime().
  registerNative("drawText", dslDrawText)
  registerNative("drawRect", dslDrawRect)
  registerNative("drawCircle", dslDrawCircle)
