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
pub struct DecorationTestRenderer {
  rects : Array[(Int, Int, UInt, UInt, UInt)]
  glyphs : Array[(Int, Int, UInt)]
}

///|
pub impl Renderer for DecorationTestRenderer with rectangle(
  self,
  x,
  y,
  w,
  h,
  color,
) {
  self.rects.push((x, y, w, h, color.value))
}

///|
pub impl Renderer for DecorationTestRenderer with glyph(
  self,
  physical_glyph,
  color,
) {
  self.glyphs.push((physical_glyph.x, physical_glyph.y, color.value))
}

///|
test "render_decoration draws underline rectangles" {
  let glyph = LayoutGlyph::new(0, 1, 10.0F, 0, 400, 1, 0.0F, 0.0F, 10.0F, 0)
  let td = TextDecoration::{
    ..TextDecoration::new(),
    underline: UnderlineStyle::Single,
  }
  let data = GlyphDecorationData::{
    text_decoration: td,
    underline_metrics: DecorationMetrics::new(-0.125F, 1.0F / 14.0F),
    strikethrough_metrics: DecorationMetrics::new(0.3F, 1.0F / 14.0F),
    ascent: 0.8F,
  }
  let deco = DecorationSpan::{
    glyph_start: 0,
    glyph_end: 1,
    data,
    color_opt: None,
    font_size: 10.0F,
  }
  let run = LayoutRun::{
    line_i: 0,
    line_y: 10.0F,
    line_top: 0.0F,
    line_height: 12.0F,
    text: "a",
    rtl: false,
    glyphs: [glyph],
    decorations: [deco],
    line_w: 10.0F,
  }
  let rects : Array[(Int, Int, UInt, UInt, UInt)] = []
  let glyphs : Array[(Int, Int, UInt)] = []
  let renderer = DecorationTestRenderer::{ rects, glyphs }
  render_decoration(renderer, run, Color::rgb(255, 0, 0))
  inspect(rects.length() > 0, content="true")
}
