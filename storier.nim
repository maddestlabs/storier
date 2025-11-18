import std/[os, strformat]

# Markdown → AST
import parser/markdown_parser
import parser/story_types

# DSL tokenizer/parser/runtime
import dsl/dsl_tokenizer
import dsl/dsl_parser
import dsl/dsl_runtime

# Engine layers
import engine/engine_context
import engine/engine_events
import engine/engine_render
import engine/engine_markdown

# Raylib & DSL bindings
import raylib
import dsl/storie_raylib

# ------------------------------------------------------------------------------
# Fallback Markdown
# ------------------------------------------------------------------------------
const fallbackMarkdown = """# Welcome to Storier!
This is text.
"""

# ------------------------------------------------------------------------------
# Global Story Content
# ------------------------------------------------------------------------------
var currentStory*: StoryContent

# ------------------------------------------------------------------------------
# Load /index.md or fallback text
# ------------------------------------------------------------------------------
proc loadMarkdown(): string =
  let path = getCurrentDir() / "index.md"
  if fileExists(path):
    return readFile(path)
  else:
    echo fmt"index.md not found at: {path}"
    echo "Using fallback story."
    return fallbackMarkdown

# ------------------------------------------------------------------------------
# Parse Markdown → DSL blocks → register events
# ------------------------------------------------------------------------------
proc loadStoryRuntime() =
  currentStory = parseMarkdown(loadMarkdown())

  echo "SECTIONS: ", currentStory.sections.len
  echo "DSL BLOCKS: ", currentStory.blocks.len

  for sec in currentStory.sections:
    echo "SECTION: ", sec.title
    echo "  blocks: ", sec.blocks.len

  for smts in currentStory.blocks:
    echo "DSL EVENT: ", smts.metadata
    echo smts.code

  # existing DSL registration
  for smts in currentStory.blocks:
    let toks = tokenizeDsl(smts.code)
    let prog = parseDsl(toks)
    registerEvent(smts.metadata, prog)


# ------------------------------------------------------------------------------
# Main loop
# ------------------------------------------------------------------------------
proc runMainLoop() =
  while not windowShouldClose():
    updateGlobals()

    beginDrawing()
    clearBackground(Black)

    # 1. Render Markdown story content
    renderMarkdown(currentStory)

    # 2. Render DSL scripts (user-defined)
    # triggerEvent("render")

    # 3. Debug text to confirm Raylib is alive
    # drawText("Hello", 20, 20, 20, White)

    endDrawing()

# ------------------------------------------------------------------------------
# Entry point
# ------------------------------------------------------------------------------
proc main() =
  initWindow(800, 600, "Storie Engine")
  setTargetFPS(60)

  initContext()
  initRuntime()
  registerRaylibDSL()       # DSL Raylib functions available here

  loadStoryRuntime()        # load index.md or fallbackMarkdown
  runMainLoop()             # enter main loop

  closeWindow()

main()
