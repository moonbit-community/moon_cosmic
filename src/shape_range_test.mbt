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
    if i == 0 {
      b'\x00'
    } else if i == 1 {
      b'\x01'
    } else if i == 2 {
      b'\x00'
    } else if i == 3 {
      b'\x00'
    } else if i == 4 {
      b'\x00'
    } else if i == 5 {
      b'\x01'
    } else if i == 12 {
      b'c'
    } else if i == 13 {
      b'm'
    } else if i == 14 {
      b'a'
    } else if i == 15 {
      b'p'
    } else if i == 20 {
      b'\x00'
    } else if i == 21 {
      b'\x00'
    } else if i == 22 {
      b'\x00'
    } else if i == 23 {
      b'\x20'
    } else if i == 24 {
      b'\x00'
    } else if i == 25 {
      b'\x00'
    } else if i == 26 {
      b'\x00'
    } else if i == 27 {
      b'\x2C'
    } else if i == 32 {
      b'\x00'
    } else if i == 33 {
      b'\x00'
    } else if i == 34 {
      b'\x00'
    } else if i == 35 {
      b'\x01'
    } else if i == 36 {
      b'\x00'
    } else if i == 37 {
      b'\x03'
    } else if i == 38 {
      b'\x00'
    } else if i == 39 {
      b'\x01'
    } else if i == 40 {
      b'\x00'
    } else if i == 41 {
      b'\x00'
    } else if i == 42 {
      b'\x00'
    } else if i == 43 {
      b'\x0C'
    } else if i == 44 {
      b'\x00'
    } else if i == 45 {
      b'\x04'
    } else if i == 46 {
      b'\x00'
    } else if i == 47 {
      b'\x20'
    } else if i == 48 {
      b'\x00'
    } else if i == 49 {
      b'\x00'
    } else if i == 50 {
      b'\x00'
    } else if i == 51 {
      b'\x04'
    } else if i == 58 {
      cp_hi_byte
    } else if i == 59 {
      cp_lo_byte
    } else if i == 60 {
      b'\xFF'
    } else if i == 61 {
      b'\xFF'
    } else if i == 62 {
      b'\x00'
    } else if i == 63 {
      b'\x00'
    } else if i == 64 {
      cp_hi_byte
    } else if i == 65 {
      cp_lo_byte
    } else if i == 66 {
      b'\xFF'
    } else if i == 67 {
      b'\xFF'
    } else if i == 68 {
      b'\xFF'
    } else if i == 69 {
      b'\xC2'
    } else if i == 70 {
      b'\x00'
    } else if i == 71 {
      b'\x01'
    } else if i == 72 {
      b'\x00'
    } else if i == 73 {
      b'\x00'
    } else if i == 74 {
      b'\x00'
    } else if i == 75 {
      b'\x00'
    } else {
      b'\x00'
    }
  })
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
  inspect((font_at_a, font_at_b, font_at_c), content="(Some(0), Some(1), Some(2))")
}
