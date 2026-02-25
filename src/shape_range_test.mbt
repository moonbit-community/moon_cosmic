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
fn mk_min_font_cmap4_single_for_shape_range(
  cp_hi_byte : Byte,
  cp_lo_byte : Byte,
) -> Bytes {
  Bytes::makei(76, i => {
    match i {
      0 => b'\x00'
      1 => b'\x01'
      2 => b'\x00'
      3 => b'\x00'
      4 => b'\x00'
      5 => b'\x01'
      12 => b'c'
      13 => b'm'
      14 => b'a'
      15 => b'p'
      20 => b'\x00'
      21 => b'\x00'
      22 => b'\x00'
      23 => b'\x20'
      24 => b'\x00'
      25 => b'\x00'
      26 => b'\x00'
      27 => b'\x2C'
      32 => b'\x00'
      33 => b'\x00'
      34 => b'\x00'
      35 => b'\x01'
      36 => b'\x00'
      37 => b'\x03'
      38 => b'\x00'
      39 => b'\x01'
      40 => b'\x00'
      41 => b'\x00'
      42 => b'\x00'
      43 => b'\x0C'
      44 => b'\x00'
      45 => b'\x04'
      46 => b'\x00'
      47 => b'\x20'
      48 => b'\x00'
      49 => b'\x00'
      50 => b'\x00'
      51 => b'\x04'
      58 => cp_hi_byte
      59 => cp_lo_byte
      60 => b'\xFF'
      61 => b'\xFF'
      62 => b'\x00'
      63 => b'\x00'
      64 => cp_hi_byte
      65 => cp_lo_byte
      66 => b'\xFF'
      67 => b'\xFF'
      68 => b'\xFF'
      69 => b'\xC2'
      70 => b'\x00'
      71 => b'\x01'
      72 => b'\x00'
      73 => b'\x00'
      74 => b'\x00'
      75 => b'\x00'
      _ => b'\x00'
    }
  })
}

///|
fn source_range_has_non_ws(text : String, start : Int, end : Int) -> Bool {
  let s = if start < 0 {
    0
  } else if start > text.length() {
    text.length()
  } else {
    start
  }
  let e = if end < s {
    s
  } else if end > text.length() {
    text.length()
  } else {
    end
  }
  let mut i = s
  while i < e {
    let cu = text.code_unit_at(i).to_int()
    if cu != 32 && cu != 9 {
      return true
    }
    i = i + 1
  }
  false
}

///|
test "ShapeLine.build_with_font_system keeps space glyphs on whitespace source ranges" {
  let text = "Move the mouse to see the circle follow your cursor."
  let font_system = FontSystem::new().load_font_data(
    test_font_inter_regular_ttf(),
  )
  let shape = ShapeLine::build_with_font_system(
    ShapeLine::empty(),
    font_system,
    text,
    AttrsList::new(Attrs::new()),
    Shaping::Advanced,
    8,
  )
  let space_gid = match font_system.get_font(0) {
    None => 0
    Some(font) => @moon_swash.Charmap::from_font(font).map(32U).to_int()
  }
  let mut bad = 0
  for glyph in shape.glyphs {
    if glyph.glyph_id != space_gid {
      continue
    }
    let mut i = glyph.start
    let mut has_non_ws = false
    while i < glyph.end && i < text.length() {
      let cu = text.code_unit_at(i).to_int()
      if cu != 32 && cu != 9 {
        has_non_ws = true
        break
      }
      i = i + 1
    }
    if has_non_ws {
      bad = bad + 1
    }
  }
  inspect(bad, content="0")
}

///|
test "ShapeLine.build_with_font_system keeps visible ASCII renderable on physical cache path" {
  let text = "Move the mouse to see the circle follow your cursor."
  let font_system = FontSystem::new().load_font_data(
    test_font_inter_regular_ttf(),
  )
  let shape = ShapeLine::build_with_font_system(
    ShapeLine::empty(),
    font_system,
    text,
    AttrsList::new(Attrs::new()),
    Shaping::Advanced,
    8,
  )
  let lines = layout_from_shape(text, shape, 18.0F, 18.0F, None, Wrap::None)
  let cache = SwashCache::new()
  let mut bad = 0
  for line in lines {
    for glyph in line.glyphs {
      if !source_range_has_non_ws(text, glyph.start, glyph.end) {
        continue
      }
      let physical = glyph.physical((0.0F, 0.0F), 1.0F)
      if cache.get_image_uncached(font_system, physical.cache_key) is None {
        bad = bad + 1
      }
    }
  }
  inspect(bad, content="0")
}

///|
test "ShapeLine.build_with_font_system emits non-inverted in-bounds source ranges" {
  let text = "office affine \u{05D0}\u{05D1}\u{05D2} test"
  let font_system = FontSystem::new().load_font_data(
    test_font_inter_regular_ttf(),
  )
  let shape = ShapeLine::build_with_font_system(
    ShapeLine::empty(),
    font_system,
    text,
    AttrsList::new(Attrs::new()),
    Shaping::Advanced,
    8,
  )
  let mut ok = true
  for glyph in shape.glyphs {
    if glyph.start < 0 || glyph.end < glyph.start || glyph.end > text.length() {
      ok = false
    }
  }
  inspect(ok, content="true")
}

///|
test "ShapeLine.build_with_font_system assigns metadata by glyph start attrs" {
  let text = "abc"
  let attrs = AttrsList::new(Attrs::with_metadata(7)).add_span(
    1,
    2,
    Attrs::with_metadata(42),
  )
  let font_system = FontSystem::new().load_font_data(
    test_font_inter_regular_ttf(),
  )
  let shape = ShapeLine::build_with_font_system(
    ShapeLine::empty(),
    font_system,
    text,
    attrs,
    Shaping::Advanced,
    8,
  )
  let mut ok = true
  let mut saw_mid = false
  for glyph in shape.glyphs {
    if glyph.start == 1 {
      saw_mid = true
      if glyph.metadata != 42 {
        ok = false
      }
    } else if glyph.start >= 0 && glyph.start < text.length() {
      if glyph.metadata != 7 {
        ok = false
      }
    }
  }
  inspect((saw_mid, ok), content="(true, true)")
}

///|
test "ShapeLine.build_with_font_system replaces missing clusters incrementally" {
  let fs = FontSystem::new()
    .load_font_data(mk_min_font_cmap4_single_for_shape_range(b'\x00', b'\x41')) // A
    .load_font_data(mk_min_font_cmap4_single_for_shape_range(b'\x00', b'\x42')) // B
    .load_font_data(mk_min_font_cmap4_single_for_shape_range(b'\x00', b'\x43')) // C
  let shape = ShapeLine::build_with_font_system(
    ShapeLine::empty(),
    fs,
    "ABC",
    AttrsList::new(Attrs::new()),
    Shaping::Advanced,
    8,
  )
  let mut font_at_a : Int? = None
  let mut font_at_b : Int? = None
  let mut font_at_c : Int? = None
  for g in shape.glyphs {
    if g.start == 0 {
      font_at_a = Some(g.font_id)
    } else if g.start == 1 {
      font_at_b = Some(g.font_id)
    } else if g.start == 2 {
      font_at_c = Some(g.font_id)
    }
  }
  inspect(
    (font_at_a, font_at_b, font_at_c),
    content="(Some(0), Some(1), Some(2))",
  )
}
