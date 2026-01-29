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
test "layout_ascii: Wrap::Word splits on spaces" {
  let text = "hello world"
  let lines = layout_ascii(text, 10.0F, Some(60.0F), Wrap::Word)
  inspect(lines.length(), content="2")
  inspect(lines[0].start, content="0")
  inspect(lines[0].end, content="5")
  inspect(lines[0].w, content="50")
  inspect(lines[1].start, content="6")
  inspect(lines[1].end, content="11")
  inspect(lines[1].w, content="50")
}

///|
test "layout_ascii: Wrap::WordOrGlyph falls back for long words" {
  let text = "abcdefghij" // 10 glyphs
  let lines = layout_ascii(text, 10.0F, Some(30.0F), Wrap::WordOrGlyph)
  inspect(lines.length(), content="4")
  inspect(lines[0].start, content="0")
  inspect(lines[0].end, content="3")
  inspect(lines[1].start, content="3")
  inspect(lines[1].end, content="6")
  inspect(lines[2].start, content="6")
  inspect(lines[2].end, content="9")
  inspect(lines[3].start, content="9")
  inspect(lines[3].end, content="10")
}

///|
test "layout_from_shape: supports non-1:1 glyph coverage (ligature)" {
  let text = "fi"
  let shape = ShapeLine::new(false, [
    ShapeGlyph::new(0, 2, 2.0F, 0.0F, 0.0F, 0.0F, 0, 42, 0),
  ])
  let lines = layout_from_shape(text, shape, 10.0F, 10.0F, None, Wrap::None)
  inspect(lines.length(), content="1")
  inspect(lines[0].start, content="0")
  inspect(lines[0].end, content="2")
  inspect(lines[0].glyphs.length(), content="1")
  inspect(lines[0].w, content="20")
}

///|
test "layout_from_shape: Wrap::Word breaks using text word boundaries" {
  let text = "ab cd"
  let shape = ShapeLine::new(false, [
    // "ab" ligature
    ShapeGlyph::new(0, 2, 2.0F, 0.0F, 0.0F, 0.0F, 0, 1, 0),
    // space
    ShapeGlyph::new(2, 3, 1.0F, 0.0F, 0.0F, 0.0F, 0, 2, 0),
    // "cd" ligature
    ShapeGlyph::new(3, 5, 2.0F, 0.0F, 0.0F, 0.0F, 0, 3, 0),
  ])
  let lines = layout_from_shape(
    text,
    shape,
    10.0F,
    10.0F,
    Some(25.0F),
    Wrap::Word,
  )
  inspect(lines.length(), content="2")
  inspect(lines[0].start, content="0")
  inspect(lines[0].end, content="2")
  inspect(lines[1].start, content="3")
  inspect(lines[1].end, content="5")
}

///|
test "layout_from_shape: Wrap::WordOrGlyph falls back to glyph wrap inside a long word" {
  let text = "abcdef"
  let shape = ShapeLine::new(false, [
    ShapeGlyph::new(0, 2, 2.0F, 0.0F, 0.0F, 0.0F, 0, 1, 0),
    ShapeGlyph::new(2, 4, 2.0F, 0.0F, 0.0F, 0.0F, 0, 2, 0),
    ShapeGlyph::new(4, 6, 2.0F, 0.0F, 0.0F, 0.0F, 0, 3, 0),
  ])
  let lines = layout_from_shape(
    text,
    shape,
    10.0F,
    10.0F,
    Some(25.0F),
    Wrap::WordOrGlyph,
  )
  inspect(lines.length(), content="3")
  inspect((lines[0].start, lines[0].end), content="(0, 2)")
  inspect((lines[1].start, lines[1].end), content="(2, 4)")
  inspect((lines[2].start, lines[2].end), content="(4, 6)")
}
