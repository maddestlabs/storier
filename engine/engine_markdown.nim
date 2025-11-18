# engine_markdown.nim
# Complete Markdown renderer with region support for Storie Engine.

import std/[strutils, math]
import raylib
import ../parser/story_types

# ------------------------------------------------------------------------------
# Markdown Rendering Region
# ------------------------------------------------------------------------------

# User-defined region for Markdown rendering.
# If width or height is 0, it auto-expands to window size.
var
  mdX*: int = 40
  mdY*: int = 40
  mdW*: int = 0   # 0 = full width
  mdH*: int = 0   # 0 = full height

proc setMarkdownRegion*(x, y, w, h: int) =
  mdX = x
  mdY = y
  mdW = w
  mdH = h

proc resetMarkdownRegion*() =
  mdX = 40
  mdY = 40
  mdW = 0
  mdH = 0

# ------------------------------------------------------------------------------
# User-overridable renderer hook
# ------------------------------------------------------------------------------

var markdownRenderer*: proc(content: StoryContent) = nil

# ------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------

template i32(x: int): int32 = int32(x)

proc measureTextWidth(txt: string; size: int): int =
  measureText(txt, int32(size))

proc drawTextLine(text: string; x, y, size: int; col: Color) =
  drawText(text, i32(x), i32(y), i32(size), col)

# ------------------------------------------------------------------------------
# Word wrapping
# ------------------------------------------------------------------------------

proc drawWrapped(text: string; x, y, size: int; col: Color; maxWidth: int): int =
  var curY = y
  var line = ""

  for word in text.splitWhitespace():
    let test = (if line.len == 0: word else: line & " " & word)
    if measureTextWidth(test, size) > maxWidth:
      drawTextLine(line, x, curY, size, col)
      curY += size + 4
      line = word
    else:
      line = test

  if line.len > 0:
    drawTextLine(line, x, curY, size, col)
    curY += size + 4

  return curY

# ------------------------------------------------------------------------------
# Inline markdown formatting
# ------------------------------------------------------------------------------

proc drawInlineElements(elems: seq[MarkdownElement]; x, y, size: int; col: Color): int =
  var curX = x
  var curY = y

  for e in elems:
    var c = col
    if e.bold:  c = YELLOW
    if e.italic: c = LIGHTGRAY
    if e.isLink: c = SKYBLUE

    drawTextLine(e.text, curX, curY, size, c)
    curX += measureTextWidth(e.text, size) + 4

  return curY + size + 4

# ------------------------------------------------------------------------------
# Code block rendering
# ------------------------------------------------------------------------------

proc drawCodeBlock(code: string; x, y: int): int =
  var cy = y
  drawTextLine("```nim", x, cy, 18, YELLOW)
  cy += 22

  for line in code.splitLines():
    drawTextLine(line, x + 20, cy, 18, LIGHTGRAY)
    cy += 22

  drawTextLine("```", x, cy, 18, YELLOW)
  cy += 30
  return cy

# ------------------------------------------------------------------------------
# Headings
# ------------------------------------------------------------------------------

proc drawHeading(text: string; x, y, level: int): int =
  let size = case level:
    of 1: 38
    of 2: 32
    of 3: 26
    of 4: 22
    of 5: 20
    else: 18

  drawTextLine(text, x, y, size, WHITE)
  return y + size + 12

# ------------------------------------------------------------------------------
# Lists
# ------------------------------------------------------------------------------

proc drawListItem(text: string; x, y: int; maxWidth: int): int =
  drawTextLine("•", x, y, 20, WHITE)
  return drawWrapped(text, x + 20, y, 20, RAYWHITE, maxWidth)

# ------------------------------------------------------------------------------
# Default Markdown Renderer
# ------------------------------------------------------------------------------

proc defaultMarkdownRenderer*(content: StoryContent) =
  # Determine actual layout region
  let regionX = mdX
  let regionY = mdY
  let regionW = if mdW == 0: getScreenWidth()  - (mdX * 2) else: mdW
  let regionH = if mdH == 0: getScreenHeight() - (mdY * 2) else: mdH

  var x = regionX
  var y = regionY

  for sec in content.sections:

    # Section heading
    if sec.title.len > 0:
      y = drawHeading(sec.title, x, y, sec.level)

    for b in sec.blocks:
      case b.kind
      of HeadingBlock:
        discard

      of TextBlock:
        if b.elements.len > 0:
          y = drawInlineElements(b.elements, x, y, 20, RAYWHITE)
        else:
          y = drawWrapped(b.text, x, y, 20, RAYWHITE, regionW)

      of CodeBlock:
        y = drawCodeBlock(b.code, x, y)

      of ListItemBlock:
        y = drawListItem(b.text, x, y, regionW)

      else:
        discard

      # Stop before drawing beyond region
      if y > regionY + regionH:
        return

# ------------------------------------------------------------------------------
# Public entry point
# ------------------------------------------------------------------------------

proc renderMarkdown*(content: StoryContent) =
  if markdownRenderer != nil:
    markdownRenderer(content)
  else:
    defaultMarkdownRenderer(content)
