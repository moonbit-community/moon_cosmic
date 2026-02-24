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
fn mk_min_font_cmap4_single(cp_hi_byte : Byte, cp_lo_byte : Byte) -> Bytes {
  // Based on `moon_swash`'s internal cmap test font: a minimal TrueType font
  // with one "cmap" table containing a single format-4 subtable mapping
  // U+00XX -> glyph 3. We parameterize the codepoint bytes.
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
test "FontSystem.resolve_for_codepoint prefers a font that supports the codepoint" {
  // Font0 supports U+0041 ('A'); Font1 supports U+0042 ('B').
  let a = mk_min_font_cmap4_single(b'\x00', b'\x41')
  let b = mk_min_font_cmap4_single(b'\x00', b'\x42')
  let fs = FontSystem::new().load_font_data(a).load_font_data(b)
  let attrs = Attrs::new()
  inspect(fs.resolve_for_codepoint(attrs, 0x41U), content="Some(0)")
  inspect(fs.resolve_for_codepoint(attrs, 0x42U), content="Some(1)")

  // Missing in both fonts: fall back to the default resolution (first font).
  inspect(fs.resolve_for_codepoint(attrs, 0x43U), content="Some(0)")

  // Repeated resolution should be stable.
  inspect(fs.resolve_for_codepoint(attrs, 0x41U), content="Some(0)")
  inspect(fs.resolve_for_codepoint(attrs, 0x42U), content="Some(1)")
}

///|
test "FontSystem.select_family returns a generic-family fallback when fonts exist" {
  let a = mk_min_font_cmap4_single(b'\x00', b'\x41')
  let fs = FontSystem::new().load_font_data(a)
  inspect(fs.select_family(SansSerif), content="Some(0)")
  inspect(fs.select_family(Serif), content="Some(0)")
  inspect(fs.select_family(Name("missing")), content="None")
}

///|
test "FontSystem.font_matches is stable across cache hits" {
  let a = mk_min_font_cmap4_single(b'\x00', b'\x41')
  let b = mk_min_font_cmap4_single(b'\x00', b'\x42')
  let fs = FontSystem::new().load_font_data(a).load_font_data(b)
  let attrs = Attrs::new()
  inspect(fs.font_matches(attrs), content="[0, 1]")
  inspect(fs.font_matches(attrs), content="[0, 1]")
}

///|
test "FontSystem.resolve_for_codepoint remains stable across cache boundary clears" {
  let a = mk_min_font_cmap4_single(b'\x00', b'\x41')
  let b = mk_min_font_cmap4_single(b'\x00', b'\x42')
  let fs = FontSystem::new().load_font_data(a).load_font_data(b)
  let attrs = Attrs::new()
  for i in 0..<9000 {
    fs.resolve_for_codepoint(attrs, i.reinterpret_as_uint()) |> ignore
  }
  inspect(fs.resolve_for_codepoint(attrs, 0x41U), content="Some(0)")
  inspect(fs.resolve_for_codepoint(attrs, 0x42U), content="Some(1)")
}
