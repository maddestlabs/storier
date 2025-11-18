# parser/markdown_parser.nim
# Markdown → StoryContent parser for the Storie Engine.

import std/[strutils, sequtils, json, tables]
import story_types

# ------------------------------------------------------------------------------
# Front matter parsing
# ------------------------------------------------------------------------------

proc parseFrontMatter(content: string): (JsonNode, string) =
  if not content.startsWith("---"):
    return (newJNull(), content)

  let parts = content.split("---", 3)
  if parts.len < 3:
    return (newJNull(), content)

  let fm = parts[1].strip()
  let remaining = parts[2]

  var root = newJObject()

  for line in fm.splitLines():
    let L = line.strip()
    if L.len == 0 or ':' notin L: continue

    let colon = L.find(':')
    let key = L[0..<colon].strip()
    let value = L[colon+1..^1].strip()

    if value == "true":
      root[key] = newJBool(true)
    elif value == "false":
      root[key] = newJBool(false)
    elif value.len > 1 and value[0] == '"' and value[^1] == '"':
      root[key] = newJString(value[1..^2])
    else:
      try:
        root[key] = newJInt(parseInt(value))
      except:
        try:
          root[key] = newJFloat(parseFloat(value))
        except:
          root[key] = newJString(value)

  return (root, remaining)

# ------------------------------------------------------------------------------
# Inline Markdown parsing (bold, italic, links)
# ------------------------------------------------------------------------------

proc parseMarkdownInline(text: string): seq[MarkdownElement] =
  result = @[]
  var i = 0
  var buf = ""
  var bold = false
  var italic = false

  template flush() =
    if buf.len > 0:
      result.add(MarkdownElement(
        text: buf,
        bold: bold,
        italic: italic,
        isLink: false,
        linkUrl: ""
      ))
      buf = ""

  while i < text.len:

    # Links: [text](url)
    if text[i] == '[':
      flush()
      var linkText = ""
      var linkUrl  = ""
      var j = i + 1

      while j < text.len and text[j] != ']':
        linkText.add(text[j])
        inc j

      if j < text.len and j+1 < text.len and text[j+1] == '(':
        j += 2
        while j < text.len and text[j] != ')':
          linkUrl.add(text[j])
          inc j

        if j < text.len:
          result.add(MarkdownElement(
            text: linkText,
            bold: bold,
            italic: italic,
            isLink: true,
            linkUrl: linkUrl
          ))
          i = j + 1
          continue

    # Bold **
    if i+1 < text.len and text[i] == '*' and text[i+1] == '*':
      flush()
      bold = not bold
      i += 2
      continue

    # Italic *
    if text[i] == '*':
      flush()
      italic = not italic
      i += 1
      continue

    # Regular character
    buf.add(text[i])
    inc i

  flush()

# ------------------------------------------------------------------------------
# Main Markdown parser (fully fixed)
# ------------------------------------------------------------------------------

proc parseMarkdown*(content: string): StoryContent =
  var story: StoryContent
  story.sections = @[]
  story.blocks   = @[]

  let (metadata, rawRemaining) = parseFrontMatter(content)
  story.metadata = metadata

  # Strip leading/trailing whitespace to avoid blank first line from triple-quotes
  let remaining = rawRemaining.strip()

  # ------------------------------------------------------------------
  # ALWAYS create section 1 before parsing lines
  # ------------------------------------------------------------------
  var currentSection: Section
  var sectionCount = 1
  var sectionStarted = true

  currentSection = Section(
    id: "section_1",
    title: "Untitled",
    level: 1,
    blocks: @[],
    scripts: initTable[string,string](),
    position: newJNull()
  )

  # Code block state
  var inCode = false
  var codeLang = ""
  var codeMeta = ""
  var codeContent = ""

  # ------------------------------------------------------------------
  # Line-by-line parsing
  # ------------------------------------------------------------------
  for line in remaining.splitLines():
    let L = line.strip()

    # --------------------------------------------------------------
    # Code block fences
    # --------------------------------------------------------------
    if L.startsWith("```"):
      if inCode:
        # Closing fence
        var b = ContentBlock(
          kind: CodeBlock,
          code: codeContent,
          language: codeLang,
          metadata: codeMeta
        )

        # DSL event block
        if codeLang == "nim" and codeMeta.startsWith("on:"):
          let ev = codeMeta[3..^1].strip()   # e.g. "render"
          story.blocks.add(b)
          currentSection.scripts[ev] = codeContent
        else:
          currentSection.blocks.add(b)

        # Reset state
        inCode = false
        codeLang = ""
        codeMeta = ""
        codeContent = ""
        continue

      else:
        # Opening fence
        inCode = true
        let inside = L[3..^1].strip()
        let parts = inside.split(' ', 2)

        codeLang = if parts.len >= 1: parts[0] else: ""
        codeMeta = if parts.len >= 2: parts[1] else: ""
        continue

    # Inside code block
    if inCode:
      if codeContent.len > 0: codeContent.add("\n")
      codeContent.add(line)
      continue

    # --------------------------------------------------------------
    # Headings
    # --------------------------------------------------------------
    if L.startsWith("#"):
      var level = 0
      var i = 0
      while i < L.len and L[i] == '#':
        inc level
        inc i

      let title = L[level..^1].strip()

      # If current section is the default "Untitled" and empty,
      # THEN DO NOT finalize it — just replace it.
      let isDefaultEmpty =
        currentSection.title == "Untitled" and
        currentSection.blocks.len == 0 and
        currentSection.scripts.len == 0

      if isDefaultEmpty:
        # Reuse section_1, just rename it
        currentSection.title = title
        currentSection.level = level
        currentSection.blocks.add(ContentBlock(
          kind: HeadingBlock,
          text: title,
          level: level
        ))
      else:
        # Finalize previous, start new section
        story.sections.add(currentSection)
        inc sectionCount

        currentSection = Section(
          id: "section_" & $sectionCount,
          title: title,
          level: level,
          blocks: @[
            ContentBlock(
              kind: HeadingBlock,
              text: title,
              level: level
            )
          ],
          scripts: initTable[string,string](),
          position: newJNull()
        )

      continue

    # --------------------------------------------------------------
    # List items: "- item"
    # --------------------------------------------------------------
    if L.startsWith("- "):
      currentSection.blocks.add(ContentBlock(
        kind: ListItemBlock,
        text: L[2..^1],
        elements: @[]
      ))
      continue

    # --------------------------------------------------------------
    # Paragraph / text
    # --------------------------------------------------------------
    if L.len > 0:
      let elems = parseMarkdownInline(line)
      currentSection.blocks.add(ContentBlock(
        kind: TextBlock,
        text: line,
        elements: elems
      ))

  # Add final section
  story.sections.add(currentSection)

  return story
