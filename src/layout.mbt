// Copyright 2025 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
/// Minimal layout scaffolding ported from `cosmic-text/src/layout.rs`.
///
/// NOTE: This is an MVP focused on wrap/layout tests; shaping/font fallback will be added later.

///|
/// Metrics hinting strategy
pub(all) enum Hinting {
  Disabled
  Enabled
}

///|
/// Wrapping mode
pub(all) enum Wrap {
  None
  Glyph
  Word
  WordOrGlyph
}

///|
/// Align or justify
pub(all) enum Align {
  Left
  Right
  Center
  Justified
  End
}

///|
/// A laid out glyph (MVP subset)
pub struct LayoutGlyph {
  start : Int
  end : Int
  font_size : Float
  font_id : Int
  font_weight : Int
  glyph_id : Int
  x : Float
  y : Float
  w : Float
  /// BiDi embedding level (LTR if divisible by 2).
  level : Int
  line_height_opt : Float?
  x_offset : Float
  y_offset : Float
  color_opt : Color?
  metadata : Int
  cache_key_flags : CacheKeyFlags
}

///|
/// Convenience constructor (fills optional fields with defaults).
pub fn LayoutGlyph::new(
  start : Int,
  end : Int,
  font_size : Float,
  font_id : Int,
  font_weight : Int,
  glyph_id : Int,
  x : Float,
  y : Float,
  w : Float,
  metadata : Int,
) -> LayoutGlyph {
  LayoutGlyph::{
    start,
    end,
    font_size,
    font_id,
    font_weight,
    glyph_id,
    x,
    y,
    w,
    level: 0,
    line_height_opt: None,
    x_offset: 0.0F,
    y_offset: 0.0F,
    color_opt: None,
    metadata,
    cache_key_flags: 0U,
  }
}

///|
/// A line of laid out glyphs (MVP subset)
pub struct LayoutLine {
  start : Int
  end : Int
  w : Float
  max_ascent : Float
  max_descent : Float
  line_height_opt : Float?
  glyphs : Array[LayoutGlyph]
}

///|
/// A laid out glyph in physical/pixel coordinates, ready for rasterization.
pub struct PhysicalGlyph {
  cache_key : CacheKey
  x : Int
  y : Int
}

///|
pub fn LayoutGlyph::physical(
  self : LayoutGlyph,
  offset : (Float, Float),
  scale : Float,
) -> PhysicalGlyph {
  let x_off = self.font_size * self.x_offset
  let y_off = self.font_size * self.y_offset
  let pos_x = (self.x + x_off) * scale + offset.0
  // Hinting in Y axis (match upstream idea): truncate to integral.
  let pos_y = truncf((self.y - y_off) * scale + offset.1)
  let (cache_key, x, y) = CacheKey::new(
    self.font_id,
    self.glyph_id,
    self.font_size * scale,
    (pos_x, pos_y),
    self.font_weight,
    self.cache_key_flags,
  )
  PhysicalGlyph::{ cache_key, x, y }
}

///|
fn float_from_int(v : Int) -> Float {
  Float::from_double(v.to_double())
}

///|
fn glyph_layout_width(
  glyph : ShapeGlyph,
  default_font_size : Float,
  cell_w : Float,
) -> Float {
  let glyph_font_size = match glyph.metrics_opt {
    Option::None => default_font_size
    Option::Some(m) => m.font_size
  }
  let mut w = glyph.x_advance * glyph_font_size
  if cell_w != default_font_size && default_font_size != 0.0F {
    let match_em_width = cell_w / default_font_size
    if match_em_width != 0.0F {
      // Keep behavior close to upstream `layout_to_buffer`: snap per-glyph advance.
      w = roundf(w / match_em_width) * match_em_width
    }
  }
  w
}

///|
fn max_int(a : Int, b : Int) -> Int {
  if a > b {
    a
  } else {
    b
  }
}

///|

///|
fn prefix_range_w(prefix : Array[Float], start : Int, end : Int) -> Float {
  let s = if start < 0 { 0 } else { start }
  let e = if end < s { s } else { end }
  let a = if prefix.get(s) is Some(v) { v } else { 0.0F }
  let b = if prefix.get(e) is Some(v) { v } else { a }
  b - a
}

///|
priv struct GlyphWrapSegment {
  glyph_start : Int
  glyph_end : Int
  blank : Bool
}

///|
fn layout_is_space_like_char(ch : Char) -> Bool {
  if ch == '\t' {
    return true
  }
  let cat = @moon_swash.CharInfo::from_char(ch).category()
  cat is SpaceSeparator || cat is LineSeparator || cat is ParagraphSeparator
}

///|
fn layout_glyph_is_blank(text : String, glyph : ShapeGlyph) -> Bool {
  let start = if glyph.start < 0 {
    0
  } else if glyph.start > text.length() {
    text.length()
  } else {
    glyph.start
  }
  let end0 = if glyph.end < 0 {
    0
  } else if glyph.end > text.length() {
    text.length()
  } else {
    glyph.end
  }
  let end = if end0 < start { start } else { end0 }
  if end <= start {
    return false
  }
  let run = try! text[start:end]
  let mut has_char = false
  for ch in run {
    has_char = true
    if !layout_is_space_like_char(ch) {
      return false
    }
  }
  has_char
}

///|
fn build_glyph_wrap_segments(
  text : String,
  shape : ShapeLine,
) -> Array[GlyphWrapSegment] {
  let segs : Array[GlyphWrapSegment] = []
  let n = shape.glyphs.length()
  let mut i = 0
  while i < n {
    let blank = layout_glyph_is_blank(text, shape.glyphs[i])
    if blank {
      segs.push(GlyphWrapSegment::{ glyph_start: i, glyph_end: i + 1, blank })
      i = i + 1
      continue
    }
    let start = i
    i = i + 1
    while i < n && !layout_glyph_is_blank(text, shape.glyphs[i]) {
      i = i + 1
    }
    segs.push(GlyphWrapSegment::{ glyph_start: start, glyph_end: i, blank })
  }
  segs
}

///|
fn reorder_shape_glyphs_for_word_wrap(
  text : String,
  shape : ShapeLine,
) -> ShapeLine {
  let n = shape.glyphs.length()
  if n < 2 {
    return shape
  }
  let ordered : Array[ShapeGlyph] = []
  let mut span_start = 0
  while span_start < n {
    let level = shape.glyphs[span_start].level
    let span_rtl = level % 2 != 0
    let mut span_end = span_start + 1
    while span_end < n && shape.glyphs[span_end].level == level {
      span_end = span_end + 1
    }

    let words : Array[GlyphWrapSegment] = []
    let mut i = span_start
    while i < span_end {
      let blank = layout_glyph_is_blank(text, shape.glyphs[i])
      if blank {
        words.push(GlyphWrapSegment::{ glyph_start: i, glyph_end: i + 1, blank })
        i = i + 1
      } else {
        let wstart = i
        i = i + 1
        while i < span_end && !layout_glyph_is_blank(text, shape.glyphs[i]) {
          i = i + 1
        }
        words.push(GlyphWrapSegment::{
          glyph_start: wstart,
          glyph_end: i,
          blank: false,
        })
      }
    }

    if shape.rtl != span_rtl {
      let mut w = words.length() - 1
      while true {
        let seg = words[w]
        for gi in seg.glyph_start..<seg.glyph_end {
          ordered.push(shape.glyphs[gi])
        }
        if w == 0 {
          break
        }
        w = w - 1
      }
    } else {
      for seg in words {
        for gi in seg.glyph_start..<seg.glyph_end {
          ordered.push(shape.glyphs[gi])
        }
      }
    }
    span_start = span_end
  }
  ShapeLine::{ ..shape, glyphs: ordered }
}

///|
fn build_layout_line_from_shape(
  shape : ShapeLine,
  glyph_start : Int,
  glyph_end : Int,
  default_font_size : Float,
  cell_w : Float,
) -> LayoutLine {
  let glyphs : Array[LayoutGlyph] = []
  // Compute the source text span for this visual line from glyph coverage.
  let mut text_start = shape.glyphs[glyph_start].start
  let mut text_end = shape.glyphs[glyph_start].end
  for i in glyph_start..<glyph_end {
    let g = shape.glyphs[i]
    if g.start < text_start {
      text_start = g.start
    }
    if g.end > text_end {
      text_end = g.end
    }
  }
  let mut x = 0.0F
  let mut max_line_height : Float? = Option::None
  for i in glyph_start..<glyph_end {
    let g = shape.glyphs[i]
    let glyph_font_size = match g.metrics_opt {
      Option::None => default_font_size
      Option::Some(m) => m.font_size
    }
    let w = glyph_layout_width(g, default_font_size, cell_w)
    let glyph_line_height_opt = match g.metrics_opt {
      Option::None => Option::None
      Option::Some(m) => Option::Some(m.line_height)
    }
    match (max_line_height, glyph_line_height_opt) {
      (Option::None, Option::Some(h)) => max_line_height = Option::Some(h)
      (Option::Some(a), Option::Some(b)) =>
        if b > a {
          max_line_height = Option::Some(b)
        }
      _ => ()
    }
    glyphs.push(LayoutGlyph::{
      start: g.start,
      end: g.end,
      font_size: glyph_font_size,
      font_id: g.font_id,
      font_weight: g.font_weight,
      glyph_id: g.glyph_id,
      x,
      y: 0.0F,
      w,
      level: g.level,
      line_height_opt: glyph_line_height_opt,
      x_offset: g.x_offset,
      y_offset: g.y_offset,
      color_opt: None,
      metadata: g.metadata,
      cache_key_flags: 0U,
    })
    x = x + w
  }
  LayoutLine::{
    start: text_start,
    end: text_end,
    w: x,
    max_ascent: 0.0F,
    max_descent: 0.0F,
    line_height_opt: max_line_height,
    glyphs,
  }
}

///|
fn push_layout_line_from_shape(
  lines : Array[LayoutLine],
  shape : ShapeLine,
  glyph_start : Int,
  glyph_end : Int,
  font_size : Float,
  cell_w : Float,
) -> Unit {
  if glyph_end <= glyph_start {
    return
  }
  lines.push(
    build_layout_line_from_shape(
      shape, glyph_start, glyph_end, font_size, cell_w,
    ),
  )
}

///|
fn push_line(
  lines : Array[LayoutLine],
  text_start : Int,
  text_end : Int,
  glyph_w : Float,
) -> Unit {
  let len = text_end - text_start
  let w = glyph_w * float_from_int(len)
  // MVP: 1 glyph per code unit, with x computed from glyph width.
  let glyphs : Array[LayoutGlyph] = []
  for i in 0..<len {
    glyphs.push(LayoutGlyph::{
      start: text_start + i,
      end: text_start + i + 1,
      font_size: glyph_w,
      font_id: 0,
      font_weight: 400,
      glyph_id: 0,
      x: glyph_w * float_from_int(i),
      y: 0.0F,
      w: glyph_w,
      level: 0,
      line_height_opt: None,
      x_offset: 0.0F,
      y_offset: 0.0F,
      color_opt: None,
      metadata: 0,
      cache_key_flags: 0U,
    })
  }
  lines.push(LayoutLine::{
    start: text_start,
    end: text_end,
    w,
    max_ascent: 0.0F,
    max_descent: 0.0F,
    line_height_opt: None,
    glyphs,
  })
}

///|
fn push_line_glyph_chunks(
  lines : Array[LayoutLine],
  text_start : Int,
  text_end : Int,
  glyph_w : Float,
  max_w : Float,
) -> Unit {
  let max_glyphs_f = (max_w / glyph_w).to_double()
  let max_glyphs = max_int(1, max_glyphs_f.to_int())
  let mut i = text_start
  while i < text_end {
    let next = if i + max_glyphs > text_end { text_end } else { i + max_glyphs }
    push_line(lines, i, next, glyph_w)
    i = next
  }
}

///|
/// ASCII-only layout for wrap tests.
///
/// Semantics:
/// - Treat each code unit as one glyph.
/// - `glyph_w` is a monospace advance in pixels.
pub fn layout_ascii(
  text : String,
  glyph_w : Float,
  width_opt : Float?,
  wrap : Wrap,
) -> Array[LayoutLine] {
  let len = text.length()
  let lines : Array[LayoutLine] = []
  if len == 0 {
    return lines
  }
  match wrap {
    None => {
      push_line(lines, 0, len, glyph_w)
      return lines
    }
    Glyph => {
      let max_w = if width_opt is Some(w) { w } else { 0.0F }
      push_line_glyph_chunks(lines, 0, len, glyph_w, max_w)
      return lines
    }
    _ => ()
  }
  if width_opt is None {
    push_line(lines, 0, len, glyph_w)
    return lines
  }
  let max_w = if width_opt is Some(w) { w } else { 0.0F }
  let fallback_to_glyph = match wrap {
    WordOrGlyph => true
    _ => false
  }

  // Word/WordOrGlyph: linebreak-based segments with explicit blank tokens.
  let segs = wrap_word_segments(text)
  let mut i = 0
  while i < segs.length() {
    // Skip leading blank segments.
    while i < segs.length() && segs[i].2 {
      i = i + 1
    }
    if i >= segs.length() {
      break
    }
    let line_start_i = i
    let start_pos = segs[line_start_i].0
    let mut cur_end_pos = start_pos
    let mut last_non_blank_end_pos = start_pos
    let mut emitted = false
    while i < segs.length() {
      let seg = segs[i]
      let blank = seg.2
      let word_w = glyph_w * float_from_int(seg.1 - seg.0)
      let cur_w = glyph_w * float_from_int(cur_end_pos - start_pos)
      let would_w = glyph_w * float_from_int(seg.1 - start_pos)
      let fits = would_w <= max_w || (blank && cur_w <= max_w)
      if fits {
        cur_end_pos = seg.1
        if !blank {
          last_non_blank_end_pos = seg.1
        }
        i = i + 1
        continue
      }

      // Doesn't fit.
      if cur_end_pos == start_pos {
        // Segment doesn't fit on an empty line.
        if fallback_to_glyph && !blank && word_w > max_w {
          push_line_glyph_chunks(lines, seg.0, seg.1, glyph_w, max_w)
          i = i + 1
          emitted = true
          break
        } else {
          // Place it anyway (may overflow), then start new line.
          push_line(lines, seg.0, seg.1, glyph_w)
          i = i + 1
          emitted = true
          break
        }
      }

      // Emit current line without trailing blanks (blank tokens are explicit).
      if last_non_blank_end_pos > start_pos {
        push_line(lines, start_pos, last_non_blank_end_pos, glyph_w)
      }
      emitted = true
      // Start a new line at the current segment (don't consume it).
      break
    }

    // End-of-input: emit remaining line (trim trailing blanks).
    if i >= segs.length() && !emitted && last_non_blank_end_pos > start_pos {
      push_line(lines, start_pos, last_non_blank_end_pos, glyph_w)
    }
  }
  lines
}

///|
fn finalize_layout_lines(
  lines : Array[LayoutLine],
  rtl : Bool,
  width_opt : Float?,
) -> Array[LayoutLine] {
  if !rtl || lines.length() == 0 {
    return lines
  }
  let line_width = match width_opt {
    Some(w) => w
    None => {
      let mut max_w = 0.0F
      for line in lines {
        if line.w > max_w {
          max_w = line.w
        }
      }
      max_w
    }
  }
  let out : Array[LayoutLine] = []
  for line in lines {
    let glyphs : Array[LayoutGlyph] = []
    for glyph in line.glyphs {
      glyphs.push(LayoutGlyph::{ ..glyph, x: line_width - (glyph.x + glyph.w) })
    }
    out.push(LayoutLine::{ ..line, glyphs, })
  }
  out
}

///|
/// Layout from ShapeLine (MVP).
///
/// `cell_w` is the pixel width per "advance cell" (ShapeGlyph.x_advance is in cells).
pub fn layout_from_shape(
  text : String,
  shape : ShapeLine,
  font_size : Float,
  cell_w : Float,
  width_opt : Float?,
  wrap : Wrap,
) -> Array[LayoutLine] {
  let lines : Array[LayoutLine] = []
  if text.length() == 0 {
    return finalize_layout_lines(lines, shape.rtl, width_opt)
  }
  let shape_for_wrap = match wrap {
    Word | WordOrGlyph => reorder_shape_glyphs_for_word_wrap(text, shape)
    _ => shape
  }
  let glyph_len = shape_for_wrap.glyphs.length()
  if glyph_len == 0 {
    return finalize_layout_lines(lines, shape_for_wrap.rtl, width_opt)
  }
  match wrap {
    None => {
      push_layout_line_from_shape(
        lines, shape_for_wrap, 0, glyph_len, font_size, cell_w,
      )
      return finalize_layout_lines(lines, shape_for_wrap.rtl, width_opt)
    }
    _ => ()
  }
  match (width_opt, wrap) {
    // No width constraint:
    // - Glyph wrap: no wrapping required, keep full glyph span (includes spaces).
    // - Word/WordOrGlyph: no wrapping required, keep full glyph span (matches upstream behavior).
    (None, Glyph) => {
      push_layout_line_from_shape(
        lines, shape_for_wrap, 0, glyph_len, font_size, cell_w,
      )
      return finalize_layout_lines(lines, shape_for_wrap.rtl, width_opt)
    }
    (None, Word) | (None, WordOrGlyph) => {
      push_layout_line_from_shape(
        lines, shape_for_wrap, 0, glyph_len, font_size, cell_w,
      )
      return finalize_layout_lines(lines, shape_for_wrap.rtl, width_opt)
    }
    _ => ()
  }
  let max_w = if width_opt is Some(w) { w } else { 0.0F }
  match wrap {
    Glyph => {
      let mut start = 0
      let mut w = 0.0F
      for i in 0..<glyph_len {
        let adv_w = glyph_layout_width(
          shape_for_wrap.glyphs[i],
          font_size,
          cell_w,
        )
        if w + adv_w > max_w && i > start {
          push_layout_line_from_shape(
            lines, shape_for_wrap, start, i, font_size, cell_w,
          )
          start = i
          w = 0.0F
        }
        w = w + adv_w
      }
      push_layout_line_from_shape(
        lines, shape_for_wrap, start, glyph_len, font_size, cell_w,
      )
      return finalize_layout_lines(lines, shape_for_wrap.rtl, width_opt)
    }
    _ => ()
  }
  let fallback_to_glyph = match wrap {
    WordOrGlyph => true
    _ => false
  }

  // Prefix sums of pixel advances for quick range width queries.
  let prefix : Array[Float] = []
  let mut acc = 0.0F
  prefix.push(acc)
  for i in 0..<glyph_len {
    acc = acc + glyph_layout_width(shape_for_wrap.glyphs[i], font_size, cell_w)
    prefix.push(acc)
  }

  // Word/WordOrGlyph on shaped glyph stream: split by blank/non-blank glyph chunks.
  let segs = build_glyph_wrap_segments(text, shape_for_wrap)
  if segs.length() == 0 {
    return finalize_layout_lines(lines, shape_for_wrap.rtl, width_opt)
  }
  let mut i = 0
  while i < segs.length() {
    if wrap is WordOrGlyph {
      while i < segs.length() && segs[i].blank {
        i = i + 1
      }
    }
    if i >= segs.length() {
      break
    }
    let line_start_i = i
    let mut line_start_g = segs[line_start_i].glyph_start
    let mut cur_end_g = line_start_g
    let mut before_last_blank_end_g = line_start_g
    let mut emitted = false
    // Track last "fitting" glyph end and the end position before the most recent
    // blank segment, mirroring upstream `width_before_last_blank` behavior.
    while i < segs.length() {
      let seg = segs[i]
      let blank = seg.blank
      let would_end_g = seg.glyph_end
      let would_w = prefix_range_w(prefix, line_start_g, would_end_g)
      let cur_w = prefix_range_w(prefix, line_start_g, cur_end_g)
      let fits = would_w <= max_w || (blank && cur_w <= max_w)
      if fits {
        if blank {
          before_last_blank_end_g = cur_end_g
        }
        cur_end_g = would_end_g
        i = i + 1
        continue
      }

      // Doesn't fit.
      if i == line_start_i {
        // Segment doesn't fit on an empty line.
        let word_start_g = seg.glyph_start
        let word_end_g = seg.glyph_end
        if fallback_to_glyph &&
          !blank &&
          prefix_range_w(prefix, word_start_g, word_end_g) > max_w {
          // Match reference behavior: commit wrapped chunks except the final one.
          // Keep the final chunk as the current in-progress line so trailing blanks
          // can still attach before the next wrap decision.
          let mut chunk_start = word_start_g
          let mut chunk_w = 0.0F
          for gi in word_start_g..<word_end_g {
            let glyph_w = glyph_layout_width(
              shape_for_wrap.glyphs[gi],
              font_size,
              cell_w,
            )
            if chunk_w + glyph_w > max_w && gi > chunk_start {
              push_layout_line_from_shape(
                lines, shape_for_wrap, chunk_start, gi, font_size, cell_w,
              )
              chunk_start = gi
              chunk_w = 0.0F
            }
            chunk_w = chunk_w + glyph_w
          }
          line_start_g = chunk_start
          cur_end_g = word_end_g
          before_last_blank_end_g = cur_end_g
          i = i + 1
          continue
        } else {
          // Place the word anyway (may overflow).
          push_layout_line_from_shape(
            lines, shape_for_wrap, word_start_g, word_end_g, font_size, cell_w,
          )
          i = i + 1
          emitted = true
        }
        break
      }

      // Reference parity on word-wrap: if a non-blank segment overflows right
      // after a blank separator, keep it on the same line and allow overflow.
      // This matches span-transition behavior in upstream layout.
      if wrap is Word && !blank && i > line_start_i && segs[i - 1].blank {
        cur_end_g = would_end_g
        i = i + 1
        continue
      }

      // Emit current line, possibly trimming trailing blanks when wrapping.
      let emit_end = if i > line_start_i && segs[i - 1].blank {
        if wrap is WordOrGlyph &&
          !blank &&
          prefix_range_w(prefix, seg.glyph_start, seg.glyph_end) > max_w {
          cur_end_g
        } else {
          before_last_blank_end_g
        }
      } else {
        cur_end_g
      }
      if emit_end > line_start_g {
        push_layout_line_from_shape(
          lines, shape_for_wrap, line_start_g, emit_end, font_size, cell_w,
        )
      }
      // When a blank segment triggers wrap, consume it so the next line does not
      // start with that overflowing blank (matches upstream word-wrap behavior).
      if blank {
        i = i + 1
      }
      emitted = true
      // Start a new line at the current segment (do not consume it).
      break
    }

    // End-of-input: keep trailing blanks that fit in the last visual line.
    if i >= segs.length() && !emitted && cur_end_g > line_start_g {
      push_layout_line_from_shape(
        lines, shape_for_wrap, line_start_g, cur_end_g, font_size, cell_w,
      )
    }
  }
  finalize_layout_lines(lines, shape_for_wrap.rtl, width_opt)
}

///|
fn apply_align_to_line(
  text : String,
  line : LayoutLine,
  width : Float,
  align : Align,
  rtl : Bool,
) -> LayoutLine {
  let extra = width - line.w
  if extra <= 0.0F {
    return line
  }
  match align {
    Left => line
    Center => {
      let dx = extra / 2.0F
      let glyphs : Array[LayoutGlyph] = []
      for g in line.glyphs {
        glyphs.push(LayoutGlyph::{ ..g, x: g.x + dx })
      }
      LayoutLine::{ ..line, glyphs, }
    }
    Right => {
      let dx = extra
      let glyphs : Array[LayoutGlyph] = []
      for g in line.glyphs {
        glyphs.push(LayoutGlyph::{ ..g, x: g.x + dx })
      }
      LayoutLine::{ ..line, glyphs, }
    }
    End =>
      if rtl {
        line
      } else {
        let dx = extra
        let glyphs : Array[LayoutGlyph] = []
        for g in line.glyphs {
          glyphs.push(LayoutGlyph::{ ..g, x: g.x + dx })
        }
        LayoutLine::{ ..line, glyphs, }
      }
    Justified => {
      // MVP: distribute extra width across ASCII spaces in this line.
      let mut space_count = 0
      for i in line.start..<line.end {
        if i >= 0 && i < text.length() && text.code_unit_at(i) == 32 {
          space_count = space_count + 1
        }
      }
      if space_count == 0 {
        return line
      }
      let add = extra / Float::from_double(space_count.to_double())
      let glyphs : Array[LayoutGlyph] = []
      let mut dx = 0.0F
      for g in line.glyphs {
        let mut w = g.w
        // Space glyph is identified by [start,end) covering a single code unit space.
        if g.end - g.start == 1 &&
          g.start >= 0 &&
          g.start < text.length() &&
          text.code_unit_at(g.start) == 32 {
          w = w + add
          glyphs.push(LayoutGlyph::{ ..g, x: g.x + dx, w })
          dx = dx + add
        } else {
          glyphs.push(LayoutGlyph::{ ..g, x: g.x + dx, w })
        }
      }
      LayoutLine::{ ..line, w: line.w + extra, glyphs }
    }
  }
}

///|
/// Apply Align to precomputed layout lines (requires a finite width).
pub fn apply_align_with_rtl(
  text : String,
  lines : Array[LayoutLine],
  width : Float,
  align : Align,
  rtl : Bool,
) -> Array[LayoutLine] {
  let out : Array[LayoutLine] = []
  for line in lines {
    out.push(apply_align_to_line(text, line, width, align, rtl))
  }
  out
}

///|
/// Apply Align to precomputed layout lines assuming LTR paragraph direction.
pub fn apply_align(
  text : String,
  lines : Array[LayoutLine],
  width : Float,
  align : Align,
) -> Array[LayoutLine] {
  apply_align_with_rtl(text, lines, width, align, false)
}
