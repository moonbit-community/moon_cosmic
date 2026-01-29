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
/// Minimal `Buffer` port scaffold from `cosmic-text/src/buffer.rs`.
///
/// This MVP focuses on line splitting, cache invalidation and redraw semantics.
pub struct Buffer {
  lines : Array[BufferLine]
  metrics : Metrics
  width_opt : Float?
  height_opt : Float?
  scroll : Scroll
  redraw : Bool
  wrap : Wrap
  monospace_width : Float?
  tab_width : Int
  hinting : Hinting
}

///|
pub fn Buffer::new(metrics : Metrics) -> Buffer {
  Buffer::new_empty(metrics)
}

///|
/// Create an empty Buffer with the provided Metrics.
///
/// Panics (fails) if `metrics.line_height` is zero (aligned with upstream).
pub fn Buffer::new_empty(metrics : Metrics) -> Buffer {
  if metrics.line_height == 0.0F {
    abort("line height cannot be 0")
  }
  Buffer::{
    lines: [],
    metrics,
    width_opt: None,
    height_opt: None,
    scroll: Scroll::default(),
    redraw: false,
    wrap: Wrap::WordOrGlyph,
    monospace_width: None,
    tab_width: 8,
    hinting: Hinting::Disabled,
  }
}

///|
pub fn Buffer::metrics(self : Buffer) -> Metrics {
  self.metrics
}

///|
pub fn Buffer::lines(self : Buffer) -> Array[BufferLine] {
  self.lines
}

///|
pub fn Buffer::redraw(self : Buffer) -> Bool {
  self.redraw
}

///|
pub fn Buffer::set_redraw(self : Buffer, redraw : Bool) -> Buffer {
  if self.redraw == redraw {
    self
  } else {
    Buffer::{ ..self, redraw, }
  }
}

///|
pub fn Buffer::scroll(self : Buffer) -> Scroll {
  self.scroll
}

///|
pub fn Buffer::set_scroll(self : Buffer, scroll : Scroll) -> Buffer {
  if self.scroll.line == scroll.line &&
    self.scroll.vertical == scroll.vertical &&
    self.scroll.horizontal == scroll.horizontal {
    self
  } else {
    Buffer::{ ..self, scroll, redraw: true }
  }
}

///|
pub fn Buffer::wrap(self : Buffer) -> Wrap {
  self.wrap
}

///|
pub fn Buffer::hinting(self : Buffer) -> Hinting {
  self.hinting
}

///|
fn wrap_eq(a : Wrap, b : Wrap) -> Bool {
  match (a, b) {
    (None, None) => true
    (Glyph, Glyph) => true
    (Word, Word) => true
    (WordOrGlyph, WordOrGlyph) => true
    _ => false
  }
}

///|
fn hinting_eq(a : Hinting, b : Hinting) -> Bool {
  match (a, b) {
    (Disabled, Disabled) => true
    (Enabled, Enabled) => true
    _ => false
  }
}

///|
pub fn Buffer::set_wrap(self : Buffer, wrap : Wrap) -> Buffer {
  if wrap_eq(self.wrap, wrap) {
    self
  } else {
    Buffer::{ ..self, wrap, redraw: true }
  }
}

///|
pub fn Buffer::set_tab_width(self : Buffer, tab_width : Int) -> Buffer {
  if self.tab_width == tab_width {
    self
  } else {
    Buffer::{ ..self, tab_width, redraw: true }
  }
}

///|
pub fn Buffer::set_hinting(self : Buffer, hinting : Hinting) -> Buffer {
  if hinting_eq(self.hinting, hinting) {
    self
  } else {
    Buffer::{ ..self, hinting, redraw: true }
  }
}

///|
pub fn Buffer::set_monospace_width(
  self : Buffer,
  monospace_width : Float?,
) -> Buffer {
  if self.monospace_width is Some(w0) && monospace_width is Some(w1) && w0 == w1 {
    self
  } else if self.monospace_width is None && monospace_width is None {
    self
  } else {
    Buffer::{ ..self, monospace_width, redraw: true }
  }
}

///|
pub fn Buffer::set_metrics(self : Buffer, metrics : Metrics) -> Buffer {
  if metrics.line_height == 0.0F {
    abort("line height cannot be 0")
  }
  if self.metrics.font_size == metrics.font_size &&
    self.metrics.line_height == metrics.line_height {
    self
  } else {
    Buffer::{ ..self, metrics, redraw: true }
  }
}

///|
pub fn Buffer::set_size(
  self : Buffer,
  width_opt : Float?,
  height_opt : Float?,
) -> Buffer {
  // MVP: any size change triggers redraw.
  if self.width_opt is Some(w0) &&
    width_opt is Some(w1) &&
    w0 == w1 &&
    self.height_opt is Some(h0) &&
    height_opt is Some(h1) &&
    h0 == h1 {
    self
  } else if self.width_opt is None &&
    width_opt is None &&
    self.height_opt is None &&
    height_opt is None {
    self
  } else {
    Buffer::{ ..self, width_opt, height_opt, redraw: true }
  }
}

///|
pub fn Buffer::size(self : Buffer) -> (Float?, Float?) {
  (self.width_opt, self.height_opt)
}

///|
fn slice_string(s : String, start : Int, end : Int) -> String {
  let sb = StringBuilder::new(size_hint=(end - start) * 2)
  sb.write_view(s[:].view(start_offset=start, end_offset=end))
  sb.to_string()
}

///|
/// Set full text of buffer (MVP).
///
/// NOTE: `attrs_list` is copied per line (upstream spans are per line).
pub fn Buffer::set_text(
  self : Buffer,
  text : String,
  attrs_list : AttrsList,
  shaping : Shaping,
) -> Buffer {
  let mut iter = LineIter::new(text)
  let new_lines : Array[BufferLine] = []
  while true {
    let (next_iter, item_opt) = iter.next()
    iter = next_iter
    if item_opt is Some(item) {
      let start = item.0
      let end = item.1
      let ending = item.2
      let line_text = slice_string(text, start, end)
      // MVP: attrs_list is shared; once we implement per-line ranges this will be adjusted.
      new_lines.push(BufferLine::new(line_text, ending, attrs_list, shaping))
    } else {
      break
    }
  }
  Buffer::{ ..self, lines: new_lines, redraw: true }
}

///|
/// Shape all lines using a provided FontSystem (best-effort).
///
/// This is a coarse-grained helper for clients that do not want to manage
/// per-line shaping manually yet.
pub fn Buffer::shape_all_with_font_system(
  self : Buffer,
  font_system : FontSystem,
) -> Buffer {
  let lines : Array[BufferLine] = []
  for line in self.lines {
    lines.push(line.shape_with_font_system(font_system, self.tab_width))
  }
  Buffer::{ ..self, lines, }
}

///|
/// Layout all lines using a provided FontSystem (best-effort).
pub fn Buffer::layout_all_with_font_system(
  self : Buffer,
  font_system : FontSystem,
) -> Buffer {
  let lines : Array[BufferLine] = []
  for line in self.lines {
    lines.push(
      line.layout_with_font_system(
        font_system,
        self.metrics.font_size,
        self.width_opt,
        self.wrap,
        self.monospace_width,
        self.tab_width,
        self.hinting,
      ),
    )
  }
  Buffer::{ ..self, lines, }
}

///|
/// Layout all lines using the built-in shaping (no font system).
pub fn Buffer::layout_all(self : Buffer) -> Buffer {
  let lines : Array[BufferLine] = []
  for line in self.lines {
    lines.push(
      line.layout(
        self.metrics.font_size,
        self.width_opt,
        self.wrap,
        self.monospace_width,
        self.tab_width,
        self.hinting,
      ),
    )
  }
  Buffer::{ ..self, lines, }
}

///|
/// A line of visible text for rendering (MVP subset).
pub struct LayoutRun {
  line_i : Int
  line_y : Float
  line_top : Float
  line_height : Float
  text : String
  rtl : Bool
  glyphs : Array[LayoutGlyph]
  line_w : Float
}

///|
pub fn Buffer::layout_runs(self : Buffer) -> Iter[LayoutRun] {
  let runs : Array[LayoutRun] = []
  let line_height = self.metrics.line_height
  let mut y = 0.0F
  let n = self.lines.length()
  for i in 0..<n {
    let line = self.lines[i]
    let shape_opt = line.shape_opt()
    let rtl = if shape_opt is Some(s) { s.rtl } else { false }
    match line.layout_opt() {
      None => {
        runs.push(LayoutRun::{
          line_i: i,
          line_y: y,
          line_top: y,
          line_height,
          text: line.text(),
          rtl,
          glyphs: [],
          line_w: 0.0F,
        })
        y = y + line_height
      }
      Some(layout_lines) =>
        if layout_lines.length() == 0 {
          runs.push(LayoutRun::{
            line_i: i,
            line_y: y,
            line_top: y,
            line_height,
            text: line.text(),
            rtl,
            glyphs: [],
            line_w: 0.0F,
          })
          y = y + line_height
        } else {
          for l in layout_lines {
            runs.push(LayoutRun::{
              line_i: i,
              line_y: y,
              line_top: y,
              line_height,
              text: line.text(),
              rtl,
              glyphs: l.glyphs,
              line_w: l.w,
            })
            y = y + line_height
          }
        }
    }
  }
  runs.iter()
}

///|
/// Hit-testing: map a physical x/y position to a cursor (MVP).
pub fn Buffer::hit(self : Buffer, x : Float, y : Float) -> Cursor? {
  let buffer = self.layout_all()
  let mut last : Cursor? = None
  for run in buffer.layout_runs() {
    let line_cursor = if run.glyphs.length() == 0 {
      Cursor::new(run.line_i, 0)
    } else {
      Cursor::new(run.line_i, run.glyphs[run.glyphs.length() - 1].end)
    }
    last = Some(line_cursor)
    if y >= run.line_top && y < run.line_top + run.line_height {
      if run.glyphs.length() == 0 {
        return Some(Cursor::new(run.line_i, 0))
      }
      let glyphs = run.glyphs
      // Clamp to glyph span.
      if x <= glyphs[0].x {
        return Some(Cursor::new(run.line_i, glyphs[0].start))
      }
      let last_g = glyphs[glyphs.length() - 1]
      if x >= last_g.x + last_g.w {
        return Some(Cursor::new(run.line_i, last_g.end))
      }
      for g in glyphs {
        let mid = g.x + g.w / 2.0F
        if x < mid {
          return Some(Cursor::new(run.line_i, g.start))
        }
        if x < g.x + g.w {
          return Some(Cursor::new(run.line_i, g.end))
        }
      }
      return Some(line_cursor)
    }
  }
  last
}

///|
/// Cursor motion based on current layout runs (MVP).
///
/// This uses visual lines from `layout_runs()` for vertical movement.
pub fn Buffer::cursor_motion(
  self : Buffer,
  cursor : Cursor,
  cursor_x_opt : Int?,
  motion : Motion,
) -> (Cursor, Int?)? {
  // Layout to get visual line runs.
  let buffer = self.layout_all()
  let runs : Array[LayoutRun] = []
  for r in buffer.layout_runs() {
    runs.push(r)
  }
  if runs.length() == 0 {
    return None
  }
  fn x_for_index(run : LayoutRun, index : Int) -> Float {
    let glyphs = run.glyphs
    if glyphs.length() == 0 {
      return 0.0F
    }
    let mut last_x = 0.0F
    let mut last_end = 0
    for g in glyphs {
      last_x = g.x + g.w
      last_end = g.end
      if index <= g.start {
        return g.x
      }
      if index > g.start && index < g.end {
        let span = g.end - g.start
        let off = index - g.start
        let t = Float::from_double(off.to_double() / span.to_double())
        return g.x + g.w * t
      }
      if index == g.end {
        return g.x + g.w
      }
    }
    if index >= last_end {
      last_x
    } else {
      0.0F
    }
  }

  fn index_for_x(run : LayoutRun, x : Float) -> Int {
    if run.glyphs.length() == 0 {
      return 0
    }
    let glyphs = run.glyphs
    if x <= glyphs[0].x {
      return glyphs[0].start
    }
    let last_g = glyphs[glyphs.length() - 1]
    if x >= last_g.x + last_g.w {
      return last_g.end
    }
    for g in glyphs {
      let mid = g.x + g.w / 2.0F
      if x < mid {
        return g.start
      }
      if x < g.x + g.w {
        return g.end
      }
    }
    last_g.end
  }

  fn int_from_float(v : Float) -> Int {
    v.to_double().to_int()
  }

  // Find current visual run.
  let mut cur_run_idx : Int? = None
  for i in 0..<runs.length() {
    let run = runs[i]
    if run.line_i != cursor.line {
      continue
    }
    if run.glyphs.length() == 0 {
      if cursor.index == 0 {
        cur_run_idx = Some(i)
        break
      }
    } else {
      let min_start = run.glyphs[0].start
      let mut max_end = run.glyphs[0].end
      for g in run.glyphs {
        if g.end > max_end {
          max_end = g.end
        }
      }
      if cursor.index >= min_start && cursor.index <= max_end {
        cur_run_idx = Some(i)
        break
      }
    }
  }
  if cur_run_idx is None {
    return None
  }
  let cur_idx = if cur_run_idx is Some(v) { v } else { 0 }
  let cur_run = runs[cur_idx]
  let cur_x = x_for_index(cur_run, cursor.index)
  let desired_x = match cursor_x_opt {
    None => cur_x
    Some(xi) => Float::from_double(xi.to_double())
  }

  // Vertical movement uses visual runs.
  let delta_opt : Int? = match motion {
    Up => Some(-1)
    Down => Some(1)
    Vertical(n) => Some(n)
    PageUp => Some(-10)
    PageDown => Some(10)
    _ => None
  }
  if delta_opt is Some(delta0) {
    let target = cur_idx + delta0
    if target < 0 || target >= runs.length() {
      return None
    }
    let run = runs[target]
    let new_index = index_for_x(run, desired_x)
    return Some(
      (
        Cursor::new_with_affinity(run.line_i, new_index, cursor.affinity),
        Some(int_from_float(desired_x)),
      ),
    )
  }

  // Fallback: text-index motion (same as Editor's MVP cursor_motion).
  let mut c = cursor
  match motion {
    Left | Previous =>
      if c.index > 0 {
        c = Cursor::new_with_affinity(c.line, c.index - 1, c.affinity)
      } else if c.line > 0 {
        let prev = c.line - 1
        let prev_len = buffer.lines()[prev].text().length()
        c = Cursor::new_with_affinity(prev, prev_len, c.affinity)
      }
    Right | Next => {
      let len = buffer.lines()[c.line].text().length()
      if c.index < len {
        c = Cursor::new_with_affinity(c.line, c.index + 1, c.affinity)
      } else if c.line + 1 < buffer.lines().length() {
        c = Cursor::new_with_affinity(c.line + 1, 0, c.affinity)
      }
    }
    Home => c = Cursor::new_with_affinity(c.line, 0, c.affinity)
    End =>
      c = Cursor::new_with_affinity(
        c.line,
        buffer.lines()[c.line].text().length(),
        c.affinity,
      )
    SoftHome => c = Cursor::new_with_affinity(c.line, 0, c.affinity)
    BufferStart => c = Cursor::new_with_affinity(0, 0, c.affinity)
    BufferEnd => {
      let last = buffer.lines().length() - 1
      c = Cursor::new_with_affinity(
        last,
        buffer.lines()[last].text().length(),
        c.affinity,
      )
    }
    _ => ()
  }
  Some((c, None))
}

///|
/// Draw the buffer using a `SwashCache`.
///
/// For compatibility with upstream's legacy renderer helper, the callback is
/// called per pixel (`w = 1`, `h = 1`).
pub fn Buffer::draw_with_font_system(
  self : Buffer,
  font_system : FontSystem,
  swash_cache : SwashCache,
  text_color : Color,
  f : (Int, Int, UInt, UInt, Color) -> Unit,
) -> (Buffer, SwashCache) {
  let buffer = self.layout_all_with_font_system(font_system)
  let mut y = 0.0F
  for line in buffer.lines {
    match line.layout_opt() {
      None => y = y + buffer.metrics.line_height
      Some(layout_lines) =>
        for layout_line in layout_lines {
          for glyph in layout_line.glyphs {
            let physical = glyph.physical((0.0F, y), 1.0F)
            swash_cache.with_pixels(
              font_system,
              physical.cache_key,
              text_color,
              fn(px, py, color) {
                f(physical.x + px, physical.y + py, 1U, 1U, color)
              },
            )
          }
          y = y + buffer.metrics.line_height
        }
    }
  }
  (buffer, swash_cache)
}

///|
/// Draw the buffer with a font system and swash cache.
///
/// This is a naming-aligned convenience wrapper (matches upstream's `Buffer::draw` intent).
pub fn Buffer::draw(
  self : Buffer,
  font_system : FontSystem,
  swash_cache : SwashCache,
  text_color : Color,
  f : (Int, Int, UInt, UInt, Color) -> Unit,
) -> (Buffer, SwashCache) {
  self.draw_with_font_system(font_system, swash_cache, text_color, f)
}
