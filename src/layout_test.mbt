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

///|
test "layout_from_shape: stable wrap when feeding measured width back as limit" {
  fn shape_basic(text : String) -> ShapeLine {
    ShapeLine::build(
      ShapeLine::empty(),
      text,
      AttrsList::new(Attrs::new()),
      Shaping::Basic,
      8,
    )
  }

  fn max_w(lines : Array[LayoutLine]) -> Float {
    let mut m = 0.0F
    for l in lines {
      if l.w > m {
        m = l.w
      }
    }
    m
  }

  fn apply_align_opt(
    text : String,
    lines : Array[LayoutLine],
    width_opt : Float?,
    align_opt : Align?,
  ) -> Array[LayoutLine] {
    match (width_opt, align_opt) {
      (Some(w), Some(a)) => apply_align(text, lines, w, a)
      _ => lines
    }
  }

  fn check_wrap(
    text : String,
    wrap : Wrap,
    align_opt : Align?,
    start_width_opt : Float?,
  ) -> Bool {
    fn absf(v : Float) -> Float {
      if v < 0.0F {
        0.0F - v
      } else {
        v
      }
    }

    fn approx_eq(a : Float, b : Float, eps : Float) -> Bool {
      absf(a - b) <= eps
    }

    let font_size = 18.0F
    let cell_w = 18.0F
    let shape = shape_basic(text)
    let lines0 = apply_align_opt(
      text,
      layout_from_shape(text, shape, font_size, cell_w, start_width_opt, wrap),
      start_width_opt,
      align_opt,
    )
    let max0 = max_w(lines0)
    let new_limit = match start_width_opt {
      None => max0
      Some(sw) => if sw < max0 { sw } else { max0 }
    }
    let shape2 = shape_basic(text)
    let lines1 = apply_align_opt(
      text,
      layout_from_shape(text, shape2, font_size, cell_w, Some(new_limit), wrap),
      Some(new_limit),
      align_opt,
    )
    let max1 = max_w(lines1)
    if lines0.length() != lines1.length() {
      return false
    }
    if !approx_eq(max0, max1, 0.01F) {
      return false
    }
    // Compare line widths except the first line (matches upstream test intent).
    let mut i = 1
    while i < lines0.length() && i < lines1.length() {
      if !approx_eq(lines0[i].w, lines1[i].w, 0.01F) {
        return false
      }
      i = i + 1
    }
    true
  }

  let cases : Array[String] = [
    "(6)  SomewhatBoringDisplayTransform", "", " ", "  ", "   ", "       ", "hello world",
    "Lorem ipsum dolor sit amet, qui minim labore adipisicing minim sint cillum sint consectetur cupidatat.",
  ]
  for text in cases {
    for wrap in [Wrap::None, Wrap::Glyph, Wrap::Word, Wrap::WordOrGlyph] {
      for
        align_opt in [
          None,
          Some(Align::Left),
          Some(Align::Right),
          Some(Align::Center),
          Some(Align::End),
        ] {
        for
          start_width_opt in [
            None,
            Some(80.0F),
            Some(198.2132F),
            Some(20.0F),
            Some(4.0F),
            Some(300.0F),
          ] {
          fn wrap_str(w : Wrap) -> String {
            match w {
              None => "None"
              Glyph => "Glyph"
              Word => "Word"
              WordOrGlyph => "WordOrGlyph"
            }
          }

          fn align_str(a_opt : Align?) -> String {
            match a_opt {
              None => "None"
              Some(a) =>
                match a {
                  Left => "Left"
                  Right => "Right"
                  Center => "Center"
                  Justified => "Justified"
                  End => "End"
                }
            }
          }

          fn width_str(w : Float?) -> String {
            match w {
              None => "None"
              Some(v) => v.to_string()
            }
          }

          let ok0 = check_wrap(text, wrap, align_opt, start_width_opt)
          if !ok0 {
            inspect(
              "stable wrap failed (base): wrap=" +
              wrap_str(wrap) +
              " align=" +
              align_str(align_opt) +
              " start_width=" +
              width_str(start_width_opt) +
              " text=" +
              text,
              content="",
            )
          }
          let ok1 = check_wrap(
            text + "            ",
            wrap,
            align_opt,
            start_width_opt,
          )
          if !ok1 {
            inspect(
              "stable wrap failed (spaces): wrap=" +
              wrap_str(wrap) +
              " align=" +
              align_str(align_opt) +
              " start_width=" +
              width_str(start_width_opt) +
              " text=" +
              text,
              content="",
            )
          }
          let ok2 = check_wrap(text + "    ", wrap, align_opt, start_width_opt)
          if !ok2 {
            inspect(
              "stable wrap failed (spaces2): wrap=" +
              wrap_str(wrap) +
              " align=" +
              align_str(align_opt) +
              " start_width=" +
              width_str(start_width_opt) +
              " text=" +
              text,
              content="",
            )
          }
        }
      }
    }
  }
}
