# engine/engine_context.nim
# Engine-wide timing & context, plus syncing globals to the DSL runtime.

import raylib
import ../dsl/dsl_runtime

var
  lastTime*: float = 0
  deltaTime*: float = 0
  frameCount*: int = 0

proc initContext*() =
  ## Initialize engine timing & DSL runtime globals.
  lastTime = getTime().float
  deltaTime = 0
  frameCount = 0

  # Initialize DSL runtime (safe if called once at startup)
  initRuntime()

  # Seed globals visible from DSL scripts
  setGlobalFloat("dt", 0)
  setGlobalInt("screenWidth", int getScreenWidth())
  setGlobalInt("screenHeight", int getScreenHeight())
  setGlobalInt("frame", 0)

proc updateGlobals*() =
  ## Call once per frame to update dt/frame and sync them to DSL runtime.
  let now = getTime().float
  deltaTime = now - lastTime
  lastTime = now
  inc frameCount

  setGlobalFloat("dt", deltaTime)
  setGlobalInt("screenWidth", int getScreenWidth())
  setGlobalInt("screenHeight", int getScreenHeight())
  setGlobalInt("frame", frameCount)

# Convenience getters if engine code wants them directly
proc getDelta*(): float = deltaTime
proc getFrameCount*(): int = frameCount
