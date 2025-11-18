# dsl_raylib_autoreg.nim
# Macro-based batch auto-registration of selected Naylib/Raylib procs
# into the Mini-Nim DSL runtime.

import std/[strutils, tables]
import macros
import raylib
import dsl_runtime
import engine_render   # optional: if you want to wrap your own helpers too


# ------------------------------------------------------------------------------
# Helpers for mapping DSL Value → Nim types
# ------------------------------------------------------------------------------

proc argToInt(args: seq[Value]; i: int): int =
  if i >= args.len:
    quit "Missing integer argument at index " & $i
  case args[i].kind
  of vkInt: args[i].i
  of vkFloat: int(args[i].f)
  else: quit "Expected integer, got: " & $args[i]

proc argToFloat(args: seq[Value]; i: int): float32 =
  if i >= args.len:
    quit "Missing float argument at index " & $i
  case args[i].kind
  of vkFloat: args[i].f.float32
  of vkInt: float32(args[i].i)
  else: quit "Expected float, got: " & $args[i]

proc argToBool(args: seq[Value]; i: int): bool =
  if i >= args.len:
    quit "Missing bool argument at index " & $i
  case args[i].kind
  of vkBool: args[i].b
  of vkInt: args[i].i != 0
  of vkFloat: args[i].f != 0.0
  of vkString: args[i].s.len > 0
  of vkNil: false
  of vkFunction: true

proc argToString(args: seq[Value]; i: int): string =
  if i >= args.len:
    quit "Missing string argument at index " & $i
  if args[i].kind == vkString:
    args[i].s
  else:
    $args[i]


# Color map & conversion from DSL Value (string → Color)
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

proc argToColor(args: seq[Value]; i: int): Color =
  if i >= args.len:
    quit "Missing color argument at index " & $i
  if args[i].kind == vkString:
    let key = args[i].s.toLowerAscii()
    if key in colorMap:
      colorMap[key]
    else:
      quit "Unknown color: " & args[i].s
  else:
    quit "Expected color string, got: " & $args[i]


# ------------------------------------------------------------------------------
# Macro utilities: build conversion expressions based on param types
# ------------------------------------------------------------------------------

proc typeNameStr(n: NimNode): string =
  ## Returns a simple string representation for a type node.
  ## E.g., "int", "cint", "float32", "Color", "cstring"
  result = n.repr.strip()

proc makeArgExpr(paramType: NimNode; index: int): NimNode =
  ## Build an expression that converts args[index] to the desired param type.
  let tname = typeNameStr(paramType)

  if tname in ["int", "cint", "int32"]:
    result = quote do: argToInt(args, `index`).int32
  elif tname in ["float", "cfloat", "float32", "float64"]:
    result = quote do: argToFloat(args, `index`)
  elif tname in ["string"]:
    result = quote do: argToString(args, `index`)
  elif tname in ["cstring"]:
    result = quote do: argToString(args, `index`).cstring
  elif tname.endsWith("Color") or tname == "Color":
    result = quote do: argToColor(args, `index`)
  elif tname == "bool":
    result = quote do: argToBool(args, `index`)
  else:
    # Unsupported param type for now
    error("Auto-binding: unsupported param type: " & tname, paramType)


proc isVoidReturn(retType: NimNode): bool =
  ## Detect void / no-return procs.
  # heuristic: empty node or "void"
  if retType.kind == nnkEmpty:
    true
  else:
    let r = retType.repr.strip()
    r == "void" or r == "nil" or r == ""


# ------------------------------------------------------------------------------
# Macro: autoRegisterRaylib
# ------------------------------------------------------------------------------

macro autoRegisterRaylib*(procs: varargs[typed]): untyped =
  ## Usage:
  ##
  ##   autoRegisterRaylib(
  ##     DrawText,
  ##     DrawRectangle,
  ##     ClearBackground,
  ##     DrawCircle,
  ##     IsKeyDown
  ##   )
  ##
  ## For each proc symbol given:
  ## - introspects its parameter list
  ## - generates a NativeFunc wrapper
  ## - calls registerNative("<name>", wrapper)
  ##
  ## Constraints:
  ## - only supports params of types:
  ##     int/cint/int32, float32/float64, string/cstring, bool, Color
  ## - return values:
  ##     void/Color/bool/int/float/string are supported (others: error)

  result = newStmtList()

  for p in procs:
    if p.kind != nnkSym:
      error("autoRegisterRaylib expects procedure symbols", p)

    let sym = p
    let procName = $sym
    let procType = sym.getTypeInst()

    # Expect proc type: ProcTy(formalParams, ...)
    if procType.kind != nnkProcTy:
      error("Symbol " & procName & " is not a proc", p)

    let formalParams = procType[0]
    # formalParams structure:
    #   [0] = return type
    #   [1..] = nnkIdentDefs for each param

    if formalParams.len == 0:
      error("Proc " & procName & " has invalid formal params", p)

    let retType = formalParams[0]

    var paramDefs: seq[NimNode] = @[]
    for i in 1 ..< formalParams.len:
      paramDefs.add(formalParams[i])

    let wrapperName = ident("dsl_" & procName & "_wrapper")
    let dslNameLit = newLit(procName)  # DSL name same as Nim name (case-sensitive)

    # Build argument list for underlying call
    var argExprs: seq[NimNode] = @[]
    var argIndex = 0

    for defNode in paramDefs:
      # defNode is nnkIdentDefs(ident1, ident2?, typeNode, default?)
      # type is usually at position len(defNode)-2
      let typeNode = defNode[defNode.len - 2]
      argExprs.add(makeArgExpr(typeNode, argIndex))
      inc argIndex

    # Build call expression: sym(argExprs...)
    var callNode = newCall(sym)
    for a in argExprs:
      callNode.add(a)

    # Build wrapper body depending on return type
    var body: NimNode
    let retName = retType.repr.strip()

    if isVoidReturn(retType):
      body = quote do:
        discard `callNode`
        result = valNil()
    else:
      # Support some primitive return types
      if retName in ["int", "int32", "cint"]:
        body = quote do:
          let r = `callNode`
          result = valInt(int(r))
      elif retName in ["float", "float32", 'float64', "cfloat"]:
        body = quote do:
          let r = `callNode`
          result = valFloat(float(r))
      elif retName == "bool":
        body = quote do:
          let r = `callNode`
          result = valBool(r)
      elif retName in ["string"]:
        body = quote do:
          let r = `callNode`
          result = valString(r)
      elif retName == "cstring":
        body = quote do:
          let r = `callNode`
          result = valString($r)
      elif retName.endsWith("Color") or retName == "Color":
        # Not super useful directly to DSL yet; wrap as string
        body = quote do:
          let r = `callNode`
          # Just return a string marker for now; could later wrap a richer type
          result = valString("Color(...)")
      else:
        error("Auto-binding: unsupported return type for " & procName & ": " & retName,
              retType)

    # Define wrapper proc
    let wrapperProc = quote do:
      proc `wrapperName`(env: ref Env; args: seq[Value]): Value {.gcsafe.} =
        `body`

    # Define registration call
    let regStmt = quote do:
      registerNative(`dslNameLit`, `wrapperName`)

    result.add(wrapperProc)
    result.add(regStmt)


# ------------------------------------------------------------------------------
# Convenience initialize proc
# ------------------------------------------------------------------------------

proc initRaylibAutoBindings*() =
  ## Call this somewhere during startup to bulk-register the chosen Raylib procs.
  ## You may tweak the list as needed.
  ##
  ## NOTE: all names here must be in scope via `import raylib`/`import naylib`.
  ##
  autoRegisterRaylib(
    DrawText,
    DrawRectangle,
    ClearBackground,
    DrawCircle,
    DrawRectangleLines,
    DrawLine,
    IsKeyDown,
    IsKeyUp,
    IsKeyPressed,
    IsKeyReleased
  )
