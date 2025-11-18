# engine/engine_render.nim
# Rendering helpers and the main render hook into the DSL.

import raylib
import engine_events
import engine_context
import ../dsl/dsl_runtime

# Simple helpers to keep casts tidy
template i32(x: int): int32 = int32(x)
template f32(x: SomeNumber): float32 = float32(x)

# ---------------------------------------------------------------------------
# Low-level wrappers (engine API)
# ---------------------------------------------------------------------------

proc clearScreen*(color: Color) =
  ## Clear the whole screen to a color.
  clearBackground(color)

proc drawTextBase*(txt: string; x, y, size: int; col: Color) =
  ## Draw text using engine ints, cast to raylib's int32 as needed.
  raylib.drawText(txt, i32(x), i32(y), i32(size), col)

proc drawRectBase*(x, y, w, h: int; col: Color) =
  ## Filled rectangle.
  drawRectangle(i32(x), i32(y), i32(w), i32(h), col)

proc drawRectLinesBase*(x, y, w, h: int; col: Color) =
  drawRectangleLines(i32(x), i32(y), i32(w), i32(h), col)

proc drawCircleBase*(cx, cy: int; radius: float; col: Color) =
  drawCircle(i32(cx), i32(cy), f32(radius), col)

# ---------------------------------------------------------------------------
# High-level per-frame render hook
# ---------------------------------------------------------------------------

proc render*() =
  ## Called once per frame by your main loop.
  ## Lets DSL scripts handle drawing via the "on:render" event.
  triggerEvent("on:render")
