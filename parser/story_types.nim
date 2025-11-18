# parser/story_types.nim
# Shared Markdown + Story structure types for the Storie engine.

import std/[json, tables]

type
  # Kinds of content blocks in Markdown
  BlockKind* = enum
    HeadingBlock,
    TextBlock,
    CodeBlock,
    ListItemBlock

  # Inline markdown element (bold, italic, link...)
  MarkdownElement* = object
    text*: string
    bold*: bool
    italic*: bool
    isLink*: bool
    linkUrl*: string

  # A block inside a section (paragraph, heading, list item, code block)
  ContentBlock* = object
    kind*: BlockKind
    text*: string
    elements*: seq[MarkdownElement]
    level*: int
    code*: string
    language*: string
    metadata*: string

  # A section of the story (# Title, ## Subtitle)
  Section* = object
    id*: string
    title*: string
    level*: int
    blocks*: seq[ContentBlock]
    scripts*: Table[string, string]  # event → DSL code
    position*: JsonNode

  # Entire parsed story
  StoryContent* = object
    metadata*: JsonNode
    sections*: seq[Section]
    blocks*: seq[ContentBlock]  # extracted DSL code blocks
