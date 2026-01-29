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
/// Rendering helpers for Editor (ported from `cosmic-text/src/edit/editor.rs`).
///
/// This is an MVP: selection/cursor rendering is based on current `layout_runs()`
/// and uses code-unit indices (not grapheme clusters).
fn int_from_float(v : Float) -> Int {
  v.to_double().to_int()
}

///|
fn uint_from_int(v : Int) -> UInt {
  if v <= 0 {
    0U
  } else {
    v.reinterpret_as_uint()
  }
}

///|
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
      // LTR cursor at glyph end.
      return g.x + g.w
    }
  }
  if index >= last_end {
    last_x
  } else {
    0.0F
  }
}

///|
fn cursor_position_in_run(cursor : Cursor, run : LayoutRun) -> (Int, Int)? {
  if cursor.line != run.line_i {
    return None
  }
  if run.glyphs.length() == 0 {
    return Some((0, int_from_float(run.line_top)))
  }
  // Prefer the run whose glyph span contains the index.
  let min_start = run.glyphs[0].start
  let mut max_end = run.glyphs[0].end
  for g in run.glyphs {
    if g.end > max_end {
      max_end = g.end
    }
  }
  if cursor.index < min_start || cursor.index > max_end {
    return None
  }
  let x = x_for_index(run, cursor.index)
  Some((int_from_float(x), int_from_float(run.line_top)))
}

///|
/// Get X and Y position of the top-left corner of the cursor (MVP).
pub fn Editor::cursor_position(self : Editor) -> (Int, Int)? {
  let buffer = self.buffer.layout_all()
  let mut fallback : (Int, Int)? = None
  for run in buffer.layout_runs() {
    if run.line_i == self.cursor.line {
      // Keep last run on this line as a fallback (for wrapped lines).
      fallback = Some(
        (int_from_float(run.line_w), int_from_float(run.line_top)),
      )
    }
    match cursor_position_in_run(self.cursor, run) {
      None => ()
      Some(pos) => return Some(pos)
    }
  }
  fallback
}

///|
/// Render editor contents with selection and cursor highlights.
pub fn[R : Renderer] Editor::render(
  self : Editor,
  renderer : R,
  text_color : Color,
  cursor_color : Color,
  selection_color : Color,
  selected_text_color : Color,
) -> Unit {
  let selection_bounds = self.selection_bounds()
  let buffer = self.buffer.layout_all()
  let width_opt = buffer.size().0
  for run in buffer.layout_runs() {
    // Highlight selection (MVP: per-layout-run x range).
    match selection_bounds {
      None => ()
      Some((start, end)) =>
        if run.line_i >= start.line && run.line_i <= end.line {
          let text_len = run.text.length()
          let start_idx = if run.line_i == start.line { start.index } else { 0 }
          let end_idx = if run.line_i == end.line {
            end.index
          } else {
            text_len
          }
          let mut x0 = x_for_index(run, start_idx)
          let mut x1 = x_for_index(run, end_idx)
          if run.line_i != start.line {
            x0 = 0.0F
          }
          if run.line_i != end.line {
            x1 = if width_opt is Some(w) { w } else { run.line_w }
          }
          let min_x = if x0 < x1 { x0 } else { x1 }
          let max_x = if x0 > x1 { x0 } else { x1 }
          renderer.rectangle(
            int_from_float(min_x),
            int_from_float(run.line_top),
            uint_from_int(int_from_float(max_x - min_x)),
            uint_from_int(int_from_float(run.line_height)),
            selection_color,
          )
        }
    }

    // Draw cursor.
    match cursor_position_in_run(self.cursor, run) {
      None => ()
      Some((x, y)) =>
        renderer.rectangle(
          x,
          y,
          1U,
          uint_from_int(int_from_float(run.line_height)),
          cursor_color,
        )
    }

    // Draw glyphs.
    for g in run.glyphs {
      let physical = g.physical((0.0F, run.line_y), 1.0F)
      let mut glyph_color = match g.color_opt {
        None => text_color
        Some(c) => c
      }
      if text_color != selected_text_color {
        match selection_bounds {
          None => ()
          Some((start, end)) =>
            if run.line_i >= start.line &&
              run.line_i <= end.line &&
              (start.line != run.line_i || g.end > start.index) &&
              (end.line != run.line_i || g.start < end.index) {
              glyph_color = selected_text_color
            }
        }
      }
      renderer.glyph(physical, glyph_color)
    }
  }
}
