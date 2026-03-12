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
/// Port scaffold from `cosmic-text/src/buffer_line.rs`.
///
/// This implementation is intentionally minimal and test-driven:
/// - It focuses on cache invalidation and text/span mutations (append/split_off),
///   keeping API naming/semantics aligned with upstream.
fn string_concat(a : String, b : String) -> String {
  let sb = StringBuilder::new(size_hint=(a.length() + b.length()) * 2)
  sb.write_string(a)
  sb.write_string(b)
  sb.to_string()
}

///|
fn substring(s : String, start : Int, end : Int) -> String {
  let sb = StringBuilder::new(size_hint=(end - start) * 2)
  sb.write_view(s[:].view(start_offset=start, end_offset=end))
  sb.to_string()
}

///|
fn empty_layout_line() -> LayoutLine {
  LayoutLine::{
    start: 0,
    end: 0,
    w: 0.0F,
    max_ascent: 0.0F,
    max_descent: 0.0F,
    line_height_opt: None,
    glyphs: [],
    decorations: [],
  }
}

///|
fn max_layout_width(layout : Array[LayoutLine]) -> Float? {
  if layout.length() == 0 {
    return None
  }
  let mut max_w = layout[0].w
  for l in layout {
    if l.w > max_w {
      max_w = l.w
    }
  }
  Some(max_w)
}

///|
fn justify_line(text : String, line : LayoutLine, width : Float) -> LayoutLine {
  let extra = width - line.w
  if extra <= 0.0F {
    return line
  }
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

///|
fn justify_lines_except_last(
  text : String,
  layout : Array[LayoutLine],
  width : Float,
) -> Array[LayoutLine] {
  let out : Array[LayoutLine] = []
  let n = layout.length()
  for i in 0..<n {
    if i == n - 1 {
      out.push(layout[i])
    } else {
      out.push(justify_line(text, layout[i], width))
    }
  }
  out
}

///|
fn hint_line(l : LayoutLine) -> LayoutLine {
  if l.glyphs.length() == 0 {
    return l
  }
  let glyphs : Array[LayoutGlyph] = []
  let mut x = roundf(l.glyphs[0].x)
  let start_x = x
  for g in l.glyphs {
    let w = roundf(g.w)
    glyphs.push(LayoutGlyph::{ ..g, x, w })
    x = x + w
  }
  LayoutLine::{ ..l, w: x - start_x, glyphs }
}

///|
fn nonneg(v : Float) -> Float {
  if v < 0.0F {
    0.0F
  } else {
    v
  }
}

///|
fn bl_maxf(a : Float, b : Float) -> Float {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn layout_line_height_for_ellipsize(
  line : LayoutLine,
  font_size : Float,
) -> Float {
  if line.line_height_opt is Some(h) {
    h
  } else {
    font_size
  }
}

///|
fn ellipsis_width(line : LayoutLine, font_size : Float) -> Float {
  if line.glyphs.length() == 0 {
    return font_size
  }
  let g = line.glyphs[0]
  let w = if g.w > 0.0F { g.w } else { g.font_size }
  if w > 0.0F {
    w
  } else {
    font_size
  }
}

///|
fn ellipsis_glyph(
  line : LayoutLine,
  font_size : Float,
  x : Float,
  w : Float,
) -> LayoutGlyph {
  if line.glyphs.length() > 0 {
    let base = line.glyphs[0]
    LayoutGlyph::{ ..base, start: line.end, end: line.end, x, w }
  } else {
    LayoutGlyph::{
      ..LayoutGlyph::new(
        line.start,
        line.end,
        font_size,
        0,
        400,
        0,
        x,
        0.0F,
        w,
        0,
      ),
      line_height_opt: line.line_height_opt,
    }
  }
}

///|
fn take_prefix_indices(
  glyphs : Array[LayoutGlyph],
  max_w : Float,
) -> Array[Int] {
  let out : Array[Int] = []
  let mut w = 0.0F
  for p in glyphs.iter2() {
    let i = p.0
    let g = p.1
    if w + g.w > max_w {
      break
    }
    out.push(i)
    w = w + g.w
  }
  out
}

///|
fn take_suffix_indices(
  glyphs : Array[LayoutGlyph],
  max_w : Float,
) -> Array[Int] {
  let rev : Array[Int] = []
  let mut w = 0.0F
  let mut i = glyphs.length()
  while i > 0 {
    let g = glyphs[i - 1]
    if w + g.w > max_w {
      break
    }
    rev.push(i - 1)
    w = w + g.w
    i = i - 1
  }
  let out : Array[Int] = []
  let mut j = rev.length()
  while j > 0 {
    out.push(rev[j - 1])
    j = j - 1
  }
  out
}

///|
fn glyphs_from_indices(
  glyphs : Array[LayoutGlyph],
  indices : Array[Int],
) -> Array[LayoutGlyph] {
  let out : Array[LayoutGlyph] = []
  for idx in indices {
    if glyphs.get(idx) is Some(g) {
      out.push(g)
    }
  }
  out
}

///|
fn reposition_glyphs(
  glyphs : Array[LayoutGlyph],
  start_x : Float,
) -> (Array[LayoutGlyph], Float) {
  let out : Array[LayoutGlyph] = []
  let mut x = start_x
  for g in glyphs {
    out.push(LayoutGlyph::{ ..g, x, })
    x = x + g.w
  }
  (out, x - start_x)
}

///|
fn project_decorations(
  decorations : Array[DecorationSpan],
  source_indices : Array[Int],
) -> Array[DecorationSpan] {
  let out : Array[DecorationSpan] = []
  for decoration in decorations {
    let mut run_start = -1
    let mut i = 0
    while i < source_indices.length() {
      let source_i = source_indices[i]
      let in_span = source_i >= decoration.glyph_start &&
        source_i < decoration.glyph_end
      if in_span {
        if run_start < 0 {
          run_start = i
        }
      } else if run_start >= 0 {
        out.push(DecorationSpan::{
          ..decoration,
          glyph_start: run_start,
          glyph_end: i,
        })
        run_start = -1
      }
      i = i + 1
    }
    if run_start >= 0 {
      out.push(DecorationSpan::{
        ..decoration,
        glyph_start: run_start,
        glyph_end: source_indices.length(),
      })
    }
  }
  out
}

///|
fn ellipsize_line(
  line : LayoutLine,
  font_size : Float,
  width_limit : Float,
  mode : Ellipsize,
) -> LayoutLine {
  let max_w = nonneg(width_limit)
  let e_w = bl_maxf(1.0F, ellipsis_width(line, font_size))
  let text_w = nonneg(max_w - e_w)
  let glyphs = line.glyphs
  let out_glyphs : Array[LayoutGlyph] = []
  let source_indices : Array[Int] = []

  match mode {
    End(_) => {
      let prefix_indices = take_prefix_indices(glyphs, text_w)
      let prefix = glyphs_from_indices(glyphs, prefix_indices)
      let (placed_prefix, prefix_w) = reposition_glyphs(prefix, 0.0F)
      for g in placed_prefix {
        out_glyphs.push(g)
      }
      for idx in prefix_indices {
        source_indices.push(idx)
      }
      out_glyphs.push(ellipsis_glyph(line, font_size, prefix_w, e_w))
      source_indices.push(-1)
    }
    Start(_) => {
      let suffix_indices = take_suffix_indices(glyphs, text_w)
      let suffix = glyphs_from_indices(glyphs, suffix_indices)
      out_glyphs.push(ellipsis_glyph(line, font_size, 0.0F, e_w))
      source_indices.push(-1)
      let (placed_suffix, _) = reposition_glyphs(suffix, e_w)
      for g in placed_suffix {
        out_glyphs.push(g)
      }
      for idx in suffix_indices {
        source_indices.push(idx)
      }
    }
    Middle(_) => {
      let left_budget = text_w / 2.0F
      let prefix_indices = take_prefix_indices(glyphs, left_budget)
      let prefix = glyphs_from_indices(glyphs, prefix_indices)
      let mut prefix_w = 0.0F
      for g in prefix {
        prefix_w = prefix_w + g.w
      }
      let suffix_indices = take_suffix_indices(
        glyphs,
        nonneg(text_w - prefix_w),
      )
      let suffix = glyphs_from_indices(glyphs, suffix_indices)
      let (placed_prefix, prefix_w2) = reposition_glyphs(prefix, 0.0F)
      for g in placed_prefix {
        out_glyphs.push(g)
      }
      for idx in prefix_indices {
        source_indices.push(idx)
      }
      out_glyphs.push(ellipsis_glyph(line, font_size, prefix_w2, e_w))
      source_indices.push(-1)
      let (placed_suffix, _) = reposition_glyphs(suffix, prefix_w2 + e_w)
      for g in placed_suffix {
        out_glyphs.push(g)
      }
      for idx in suffix_indices {
        source_indices.push(idx)
      }
    }
    None => return line
  }

  let mut out_w = 0.0F
  for g in out_glyphs {
    out_w = out_w + g.w
  }
  let decorations = project_decorations(line.decorations, source_indices)
  let mut out_start = line.start
  let mut out_end = line.end
  let mut seen_real_glyph = false
  for source_i in source_indices {
    if source_i >= 0 && glyphs.get(source_i) is Some(source_glyph) {
      if !seen_real_glyph {
        out_start = source_glyph.start
        seen_real_glyph = true
      }
      out_end = source_glyph.end
    }
  }
  if !seen_real_glyph {
    out_start = line.end
    out_end = line.end
  }
  LayoutLine::{
    ..line,
    start: out_start,
    end: out_end,
    w: out_w,
    glyphs: out_glyphs,
    decorations,
  }
}

///|
fn apply_ellipsize(
  layout : Array[LayoutLine],
  ellipsize : Ellipsize,
  wrap : Wrap,
  width_opt : Float?,
  font_size : Float,
) -> Array[LayoutLine] {
  if layout.length() == 0 || ellipsize is None {
    return layout
  }

  let keep_lines = match ellipsize {
    None => layout.length()
    Start(limit) | Middle(limit) | End(limit) =>
      match (wrap, limit) {
        (Wrap::None, _) => 1
        (_, Lines(lines)) => if lines <= 0 { 1 } else { lines }
        (_, Height(height_limit)) => {
          let mut acc = 0.0F
          let mut kept = 0
          for line in layout {
            let h = layout_line_height_for_ellipsize(line, font_size)
            if acc + h > height_limit {
              break
            }
            acc = acc + h
            kept = kept + 1
          }
          if kept <= 0 {
            1
          } else {
            kept
          }
        }
      }
  }

  let keep = if keep_lines > layout.length() {
    layout.length()
  } else {
    keep_lines
  }
  let target_i = if keep <= 0 { 0 } else { keep - 1 }
  let target = layout[target_i]
  let max_w = if width_opt is Some(w) { w } else { target.w }
  let needs_trim = keep < layout.length() || target.w > max_w
  if !needs_trim {
    return layout
  }

  let out : Array[LayoutLine] = []
  for i in 0..<keep {
    if i == target_i {
      out.push(ellipsize_line(layout[i], font_size, max_w, ellipsize))
    } else {
      out.push(layout[i])
    }
  }
  out
}

///|
fn apply_layout_postprocess(
  text : String,
  layout0 : Array[LayoutLine],
  rtl : Bool,
  align_opt : Align?,
  width_opt : Float?,
  hinting : Hinting,
) -> Array[LayoutLine] {
  let mut layout = if layout0.length() == 0 {
    [empty_layout_line()]
  } else {
    layout0
  }
  let default_align = if rtl { Align::Right } else { Align::Left }
  let align = if align_opt is Some(a) { a } else { default_align }
  let line_width_opt = if width_opt is Some(width) {
    Some(width)
  } else {
    max_layout_width(layout)
  }
  if line_width_opt is Some(width) {
    match align {
      Justified => layout = justify_lines_except_last(text, layout, width)
      _ => layout = apply_align_with_rtl(text, layout, width, align, rtl)
    }
  }
  if hinting is Hinting::Enabled {
    let out : Array[LayoutLine] = []
    for l in layout {
      out.push(hint_line(l))
    }
    layout = out
  }
  layout
}

///|
fn align_eq(a : Align, b : Align) -> Bool {
  match (a, b) {
    (Left, Left) => true
    (Right, Right) => true
    (Center, Center) => true
    (Justified, Justified) => true
    (End, End) => true
    _ => false
  }
}

///|
fn align_opt_eq(a : Align?, b : Align?) -> Bool {
  match (a, b) {
    (None, None) => true
    (Some(a1), Some(b1)) => align_eq(a1, b1)
    _ => false
  }
}

///|
pub struct BufferLine {
  text : String
  ending : LineEnding
  attrs_list : AttrsList
  align : Align?
  shape_opt : Cached[ShapeLine]
  layout_opt : Cached[Array[LayoutLine]]
  shaping : Shaping
  metadata : Int?

  fn new(
    text : String,
    ending : LineEnding,
    attrs_list : AttrsList,
    shaping : Shaping,
  ) -> BufferLine
}

///|
pub fn BufferLine::new(
  text : String,
  ending : LineEnding,
  attrs_list : AttrsList,
  shaping : Shaping,
) -> BufferLine {
  BufferLine::{
    text,
    ending,
    attrs_list,
    align: None,
    shape_opt: Empty,
    layout_opt: Empty,
    shaping,
    metadata: None,
  }
}

///|
pub fn BufferLine::text(self : BufferLine) -> String {
  self.text
}

///|
pub fn BufferLine::into_text(self : BufferLine) -> String {
  self.text
}

///|
pub fn BufferLine::ending(self : BufferLine) -> LineEnding {
  self.ending
}

///|
pub fn BufferLine::set_ending(
  self : BufferLine,
  ending : LineEnding,
) -> BufferLine {
  if ending.as_str() == self.ending.as_str() {
    self
  } else {
    BufferLine::{ ..self, ending, }.reset_shaping()
  }
}

///|
pub fn BufferLine::attrs_list(self : BufferLine) -> AttrsList {
  self.attrs_list
}

///|
pub fn BufferLine::set_attrs_list(
  self : BufferLine,
  attrs_list : AttrsList,
) -> (BufferLine, Bool) {
  if attrs_list == self.attrs_list {
    (self, false)
  } else {
    (BufferLine::{ ..self, attrs_list, }.reset_shaping(), true)
  }
}

///|
pub fn BufferLine::align(self : BufferLine) -> Align? {
  self.align
}

///|
pub fn BufferLine::reset(self : BufferLine) -> BufferLine {
  BufferLine::{ ..self, metadata: None }.reset_shaping()
}

///|
pub fn BufferLine::reset_shaping(self : BufferLine) -> BufferLine {
  let shape_opt = self.shape_opt.set_unused()
  BufferLine::{ ..self, shape_opt, }.reset_layout()
}

///|
pub fn BufferLine::reset_layout(self : BufferLine) -> BufferLine {
  let layout_opt = self.layout_opt.set_unused()
  BufferLine::{ ..self, layout_opt, }
}

///|
pub fn BufferLine::shape_opt(self : BufferLine) -> ShapeLine? {
  self.shape_opt.get()
}

///|
pub fn BufferLine::shape(self : BufferLine, tab_width : Int) -> BufferLine {
  if self.shape_opt.is_unused() {
    let (shape_opt, reused_opt) = self.shape_opt.take_unused()
    let reused = if reused_opt is Some(v) { v } else { ShapeLine::empty() }
    let built = reused.build(
      self.text,
      self.attrs_list,
      self.shaping,
      tab_width,
    )
    let shape_opt = shape_opt.set_used(built)
    BufferLine::{ ..self, shape_opt, }.reset_layout()
  } else {
    self
  }
}

///|
/// Shape using a provided FontSystem (best-effort).
///
/// This is an incremental step towards upstream `cosmic-text`:
/// we keep the same cache behavior, but build glyph advances from the font.
pub fn BufferLine::shape_with_font_system(
  self : BufferLine,
  font_system : FontSystem,
  tab_width : Int,
) -> BufferLine {
  if self.shape_opt.is_unused() {
    let (shape_opt, reused_opt) = self.shape_opt.take_unused()
    let reused = if reused_opt is Some(v) { v } else { ShapeLine::empty() }
    let built = reused.build_with_font_system(
      font_system,
      self.text,
      self.attrs_list,
      self.shaping,
      tab_width,
    )
    let shape_opt = shape_opt.set_used(built)
    BufferLine::{ ..self, shape_opt, }.reset_layout()
  } else {
    self
  }
}

///|
pub fn BufferLine::layout_opt(self : BufferLine) -> Array[LayoutLine]? {
  self.layout_opt.get()
}

///|
pub fn BufferLine::layout(
  self : BufferLine,
  font_size : Float,
  width_opt : Float?,
  wrap : Wrap,
  ellipsize : Ellipsize,
  match_mono_width : Float?,
  tab_width : Int,
  hinting : Hinting,
) -> BufferLine {
  if self.layout_opt.is_unused() {
    let line = self.shape(tab_width)
    let shape_opt = line.shape_opt()
    if shape_opt is Some(shape) {
      let cell_w = if match_mono_width is Some(w) { w } else { font_size }
      let layout = layout_from_shape(
        line.text,
        shape,
        font_size,
        cell_w,
        width_opt,
        wrap,
      )
      let layout = apply_ellipsize(
        layout, ellipsize, wrap, width_opt, font_size,
      )
      let layout = apply_layout_postprocess(
        line.text,
        layout,
        shape.rtl,
        line.align,
        width_opt,
        hinting,
      )
      let (layout_opt, _) = line.layout_opt.take_unused()
      let layout_opt = layout_opt.set_used(layout)
      BufferLine::{ ..line, layout_opt, }
    } else {
      line
    }
  } else {
    self
  }
}

///|
/// Layout using a provided FontSystem (best-effort).
pub fn BufferLine::layout_with_font_system(
  self : BufferLine,
  font_system : FontSystem,
  font_size : Float,
  width_opt : Float?,
  wrap : Wrap,
  ellipsize : Ellipsize,
  match_mono_width : Float?,
  tab_width : Int,
  hinting : Hinting,
) -> BufferLine {
  if self.layout_opt.is_unused() {
    let line = self.shape_with_font_system(font_system, tab_width)
    let shape_opt = line.shape_opt()
    if shape_opt is Some(shape) {
      let cell_w = if match_mono_width is Some(w) { w } else { font_size }
      let layout = layout_from_shape(
        line.text,
        shape,
        font_size,
        cell_w,
        width_opt,
        wrap,
      )
      let layout = apply_ellipsize(
        layout, ellipsize, wrap, width_opt, font_size,
      )
      let layout = apply_layout_postprocess(
        line.text,
        layout,
        shape.rtl,
        line.align,
        width_opt,
        hinting,
      )
      let (layout_opt, _) = line.layout_opt.take_unused()
      let layout_opt = layout_opt.set_used(layout)
      BufferLine::{ ..line, layout_opt, }
    } else {
      line
    }
  } else {
    // Match existing API: if layout is cached, no work.
    // `hinting` is currently unused (MVP), but kept for API compatibility.
    ignore(hinting)
    self
  }
}

///|
pub fn BufferLine::set_text(
  self : BufferLine,
  text : String,
  ending : LineEnding,
  attrs_list : AttrsList,
) -> (BufferLine, Bool) {
  if text != self.text ||
    ending.as_str() != self.ending.as_str() ||
    !attrs_list.eq(self.attrs_list) {
    let updated = BufferLine::{ ..self, text, ending, attrs_list }.reset()
    (updated, true)
  } else {
    (self, false)
  }
}

///|
pub fn BufferLine::set_align(
  self : BufferLine,
  align : Align?,
) -> (BufferLine, Bool) {
  if align_opt_eq(align, self.align) {
    (self, false)
  } else {
    (BufferLine::{ ..self, align, }.reset_layout(), true)
  }
}

///|
pub fn BufferLine::layout_runs(
  self : BufferLine,
  height_opt : Float?,
  line_height : Float,
) -> Iter[LayoutRun] {
  let runs : Array[LayoutRun] = []
  let shape = match self.shape_opt() {
    None => return runs.iter()
    Some(v) => v
  }
  let layout = match self.layout_opt() {
    None => return runs.iter()
    Some(v) => v
  }
  let mut line_top_acc = 0.0F
  for l in layout {
    let this_line_height = if l.line_height_opt is Some(h) {
      h
    } else {
      line_height
    }
    let line_top = line_top_acc
    let glyph_height = l.max_ascent + l.max_descent
    let centering_offset = (this_line_height - glyph_height) / 2.0F
    let line_y = line_top + centering_offset + l.max_ascent
    if height_opt is Some(h) && line_y - l.max_ascent > h {
      return runs.iter()
    }
    line_top_acc = line_top_acc + this_line_height
    if line_y + l.max_descent < 0.0F {
      continue
    }
    runs.push(LayoutRun::{
      line_i: 0,
      line_y,
      line_top,
      line_height: this_line_height,
      text: self.text,
      rtl: shape.rtl,
      glyphs: l.glyphs,
      decorations: l.decorations,
      line_w: l.w,
    })
  }
  runs.iter()
}

///|
pub fn BufferLine::metadata(self : BufferLine) -> Int? {
  self.metadata
}

///|
pub fn BufferLine::set_metadata(
  self : BufferLine,
  metadata : Int,
) -> BufferLine {
  BufferLine::{ ..self, metadata: Some(metadata) }
}

///|
/// Append `other` to `self` (consumes both, returns updated line).
pub fn BufferLine::append(self : BufferLine, other : BufferLine) -> BufferLine {
  let len = self.text.length()
  let other_text = other.text
  let other_len = other_text.length()
  let mut attrs_list = self.attrs_list
  if other.attrs_list.defaults() != attrs_list.defaults() {
    attrs_list = attrs_list.add_span(
      len,
      len + other_len,
      other.attrs_list.defaults(),
    )
  }
  for span in other.attrs_list.spans_iter() {
    attrs_list = attrs_list.add_span(
      span.start + len,
      span.end + len,
      span.attrs,
    )
  }
  BufferLine::{
    ..self,
    text: string_concat(self.text, other_text),
    ending: other.ending,
    attrs_list,
  }.reset()
}

///|
/// Split off new line at index. Returns (left, right).
pub fn BufferLine::split_off(
  self : BufferLine,
  index : Int,
) -> (BufferLine, BufferLine) {
  let index = if index < 0 { 0 } else { index }
  let end = self.text.length()
  let idx = if index > end { end } else { index }
  let left_text = substring(self.text, 0, idx)
  let right_text = substring(self.text, idx, end)
  let (left_attrs, right_attrs) = self.attrs_list.split_off(idx)
  let left = BufferLine::{
    ..self,
    text: left_text,
    ending: None,
    attrs_list: left_attrs,
  }.reset()
  let mut right = BufferLine::new(
    right_text,
    self.ending,
    right_attrs,
    self.shaping,
  )
  right = BufferLine::{ ..right, align: self.align }
  (left, right)
}
