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
pub struct TestRenderer {
  rects : Array[(Int, Int, UInt, UInt, UInt)]
  glyph_pos : Array[(Int, Int)]
}

///|
pub impl Renderer for TestRenderer with rectangle(self, x, y, w, h, color) {
  self.rects.push((x, y, w, h, color.value))
}

///|
pub impl Renderer for TestRenderer with glyph(self, physical_glyph, _color) {
  self.glyph_pos.push((physical_glyph.x, physical_glyph.y))
}

///|
test "Editor.cursor_position + Editor.render (smoke)" {
  let attrs = AttrsList::new(Attrs::new())
  let buffer = Buffer::new(Metrics::new(12.0F, 12.0F))
    .set_text("abc", attrs, Advanced)
    .set_size(Some(1000.0F), None)
    .layout_all()
  let editor0 = Editor::new(buffer).set_cursor(Cursor::new(0, 2))
  match editor0.cursor_position() {
    None => abort("expected cursor position")
    Some((x, y)) => {
      inspect(x, content="24")
      inspect(y, content="0")
    }
  }
  let rects : Array[(Int, Int, UInt, UInt, UInt)] = []
  let glyph_pos : Array[(Int, Int)] = []
  let renderer = TestRenderer::{ rects, glyph_pos }
  editor0.render(
    renderer,
    Color::rgb(0, 0, 0),
    Color::rgb(255, 0, 0),
    Color::rgb(0, 0, 255),
    Color::rgb(0, 255, 0),
  )
  // cursor rectangle only
  inspect(rects.length(), content="1")

  // selection + cursor
  let rects2 : Array[(Int, Int, UInt, UInt, UInt)] = []
  let glyph_pos2 : Array[(Int, Int)] = []
  let renderer2 = TestRenderer::{ rects: rects2, glyph_pos: glyph_pos2 }
  let editor1 = editor0.set_selection(Selection::Normal(Cursor::new(0, 0)))
  editor1.render(
    renderer2,
    Color::rgb(0, 0, 0),
    Color::rgb(255, 0, 0),
    Color::rgb(0, 0, 255),
    Color::rgb(0, 255, 0),
  )
  inspect(rects2.length() >= 2, content="true")
}
