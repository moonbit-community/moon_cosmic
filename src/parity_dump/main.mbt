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
struct ParityCase {
  id : String
  text : String
  wrap : @cosmic.Wrap
  width_opt : Float?
}

///|
fn bool01(v : Bool) -> String {
  if v {
    "1"
  } else {
    "0"
  }
}

///|
fn wrap_name(wrap : @cosmic.Wrap) -> String {
  match wrap {
    @cosmic.Wrap::None => "None"
    @cosmic.Wrap::Glyph => "Glyph"
    @cosmic.Wrap::Word => "Word"
    @cosmic.Wrap::WordOrGlyph => "WordOrGlyph"
  }
}

///|
fn width_name(width_opt : Float?) -> String {
  match width_opt {
    None => "none"
    Some(width) => width.to_string()
  }
}

///|
fn emit(tag : String, fields : Array[(String, String)]) -> Unit {
  let sb = StringBuilder::new()
  sb.write_string(tag)
  for field in fields {
    sb.write_string("\t")
    sb.write_string(field.0)
    sb.write_string("=")
    sb.write_string(field.1)
  }
  println(sb.to_string())
}

///|
fn font_index(font_ids : Array[Int], font_id : Int) -> Int {
  for i in 0..<font_ids.length() {
    if font_ids[i] == font_id {
      return i
    }
  }
  -1
}

///|
fn mk_cases() -> Array[ParityCase] {
  [
    ParityCase::{
      id: "ascii_sentence",
      text: "Move the mouse to see the circle follow your cursor.",
      wrap: @cosmic.Wrap::None,
      width_opt: None,
    },
    ParityCase::{
      id: "ascii_tabs",
      text: "A\tB\tC",
      wrap: @cosmic.Wrap::None,
      width_opt: None,
    },
    ParityCase::{
      id: "mix_hebrew",
      text: "Many computer programs fail to display bidirectional text correctly: שרה",
      wrap: @cosmic.Wrap::None,
      width_opt: None,
    },
    ParityCase::{
      id: "mix_arabic",
      text: "I like to render اللغة العربية in Rust!",
      wrap: @cosmic.Wrap::None,
      width_opt: None,
    },
    ParityCase::{
      id: "wrap_word_or_glyph",
      text: "Lorem ipsum dolor sit amet, qui minim labore adipisicing minim sint cillum sint consectetur cupidatat.",
      wrap: @cosmic.Wrap::WordOrGlyph,
      width_opt: Some(50.0),
    },
    ParityCase::{
      id: "wrap_word",
      text: "אב abc def",
      wrap: @cosmic.Wrap::Word,
      width_opt: Some(30.0),
    },
  ]
}

///|
fn build_font_system() -> (@cosmic.FontSystem, Array[Int]) {
  let font_paths = [
    "cosmic-text-reference/fonts/Inter-Regular.ttf", "cosmic-text-reference/fonts/NotoSans-Regular.ttf",
    "cosmic-text-reference/fonts/NotoSansHebrew.ttf", "cosmic-text-reference/fonts/NotoSansArabic.ttf",
  ]
  let mut fs = @cosmic.FontSystem::new()
  for font_path in font_paths {
    fs = fs.load_font_data(try! @fs.read_file_to_bytes(font_path))
  }
  let ids : Array[Int] = []
  for entry in fs.fonts() {
    ids.push(entry.id())
  }
  (fs, ids)
}

///|
fn dump_case(
  fs : @cosmic.FontSystem,
  font_ids : Array[Int],
  parity_case : ParityCase,
) -> Unit {
  let attrs_list = @cosmic.AttrsList::new(
    @cosmic.Attrs::new()
    .family(@cosmic.Family::Name("Inter"))
    .weight(@cosmic.Weight::normal()),
  )
  emit("CASE", [
    ("case", parity_case.id),
    ("wrap", wrap_name(parity_case.wrap)),
    ("width", width_name(parity_case.width_opt)),
  ])
  let shape = @cosmic.ShapeLine::build_with_font_system(
    @cosmic.ShapeLine::empty(),
    fs,
    parity_case.text,
    attrs_list,
    @cosmic.Shaping::Advanced,
    8,
  )
  emit("SHAPE", [
    ("case", parity_case.id),
    ("rtl", bool01(shape.rtl)),
    ("count", shape.glyphs.length().to_string()),
  ])
  for i in 0..<shape.glyphs.length() {
    let g = shape.glyphs[i]
    emit("SG", [
      ("case", parity_case.id),
      ("index", i.to_string()),
      ("start", g.start.to_string()),
      ("end", g.end.to_string()),
      ("font", font_index(font_ids, g.font_id).to_string()),
      ("glyph", g.glyph_id.to_string()),
      ("xa", g.x_advance.to_string()),
      ("ya", g.y_advance.to_string()),
      ("xo", g.x_offset.to_string()),
      ("yo", g.y_offset.to_string()),
      ("meta", g.metadata.to_string()),
    ])
  }
  let layout_lines = @cosmic.layout_from_shape(
    parity_case.text,
    shape,
    16.0,
    16.0,
    parity_case.width_opt,
    parity_case.wrap,
  )
  let cache = @cosmic.SwashCache::new()
  for line_i in 0..<layout_lines.length() {
    let line = layout_lines[line_i]
    emit("LL", [
      ("case", parity_case.id),
      ("line", line_i.to_string()),
      ("w", line.w.to_string()),
      ("count", line.glyphs.length().to_string()),
    ])
    for glyph_i in 0..<line.glyphs.length() {
      let glyph = line.glyphs[glyph_i]
      let physical = glyph.physical((0.0, 0.0), 1.0)
      let key = physical.cache_key
      let has_image = cache.get_image_uncached(fs, key) is Some(_)
      let ck_flags = (if key.has_fake_italic() { 1U } else { 0U }) |
        (if key.has_disable_hinting() { 2U } else { 0U }) |
        (if key.has_pixel_font() { 4U } else { 0U })
      emit("LG", [
        ("case", parity_case.id),
        ("line", line_i.to_string()),
        ("index", glyph_i.to_string()),
        ("start", glyph.start.to_string()),
        ("end", glyph.end.to_string()),
        ("font", font_index(font_ids, glyph.font_id).to_string()),
        ("glyph", glyph.glyph_id.to_string()),
        ("x", glyph.x.to_string()),
        ("y", glyph.y.to_string()),
        ("w", glyph.w.to_string()),
        ("level", glyph.level.to_string()),
        ("meta", glyph.metadata.to_string()),
        ("ck_font", font_index(font_ids, key.font_id).to_string()),
        ("ck_gid", key.glyph_id.to_string()),
        ("ck_size_bits", key.font_size_bits.to_string()),
        ("ck_x_bin", key.x_bin().as_float().to_string()),
        ("ck_y_bin", key.y_bin().as_float().to_string()),
        ("ck_weight", key.font_weight.to_string()),
        ("ck_flags", ck_flags.to_string()),
        ("img", bool01(has_image)),
      ])
    }
  }
}

///|
fn main {
  let (fs, font_ids) = build_font_system()
  for parity_case in mk_cases() {
    dump_case(fs, font_ids, parity_case)
  }
}
