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
fn find_alt_family_name(entry : FontEntry) -> String? {
  let strings = entry.font().localized_strings()
  let base = entry.family_name()
  for s in strings.iter() {
    let id = s.id()
    if id is @moon_swash.StringId::Family ||
      id is @moon_swash.StringId::TypographicFamily ||
      id is @moon_swash.StringId::WwsFamily {
      let v = s.to_string()
      if v != base {
        return Some(v)
      }
    }
  }
  None
}

///|
fn script_needs_stage_for_test(script : @moon_swash.Script) -> Bool {
  match script {
    @moon_swash.Script::Common
    | @moon_swash.Script::Inherited
    | @moon_swash.Script::Latin
    | @moon_swash.Script::Unknown => false
    _ => true
  }
}

///|
fn entry_supports_script_for_test(
  entry : FontEntry,
  script : @moon_swash.Script,
) -> Bool {
  let systems = entry.font().writing_systems()
  for ws in systems.iter() {
    match ws.script() {
      None => ()
      Some(s) => if s.to_opentype() == script.to_opentype() { return true }
    }
  }
  false
}

///|
fn script_in_array_for_test(
  scripts : Array[@moon_swash.Script],
  script : @moon_swash.Script,
) -> Bool {
  for s in scripts {
    if s.to_opentype() == script.to_opentype() {
      return true
    }
  }
  false
}

///|
fn first_discriminating_script_for_test(
  fs : FontSystem,
  ids : Array[Int],
) -> @moon_swash.Script? {
  let scripts : Array[@moon_swash.Script] = []
  for id in ids {
    match fs.get_font_entry(id) {
      None => ()
      Some(entry) => {
        let systems = entry.font().writing_systems()
        for ws in systems.iter() {
          match ws.script() {
            None => ()
            Some(s) =>
              if script_needs_stage_for_test(s) &&
                !script_in_array_for_test(scripts, s) {
                scripts.push(s)
              }
          }
        }
      }
    }
  }
  for script in scripts {
    let mut has_support = false
    let mut has_no_support = false
    for id in ids {
      match fs.get_font_entry(id) {
        None => ()
        Some(entry) =>
          if entry_supports_script_for_test(entry, script) {
            has_support = true
          } else {
            has_no_support = true
          }
      }
    }
    if has_support && has_no_support {
      return Some(script)
    }
  }
  None
}

///|
fn is_permutation_of_ids_for_test(lhs : Array[Int], rhs : Array[Int]) -> Bool {
  if lhs.length() != rhs.length() {
    return false
  }
  for id in lhs {
    let mut count = 0
    for rid in rhs {
      if rid == id {
        count = count + 1
      }
    }
    if count != 1 {
      return false
    }
  }
  true
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
test "FontSystem.font_matches cache is not externally mutable" {
  let a = mk_min_font_cmap4_single(b'\x00', b'\x41')
  let b = mk_min_font_cmap4_single(b'\x00', b'\x42')
  let fs = FontSystem::new().load_font_data(a).load_font_data(b)
  let attrs = Attrs::new()
  let first = fs.font_matches(attrs)
  first.set(0, 99)
  inspect(fs.font_matches(attrs), content="[0, 1]")
}

///|
test "FontSystem.font_matches generic-family ordering does not enforce explicit-family promotion" {
  let a = mk_min_font_cmap4_single(b'\x00', b'\x41')
  let b = mk_min_font_cmap4_single(b'\x00', b'\x42')
  let fs = FontSystem::new().load_font_data(a).load_font_data(b)
  let sans = Attrs::new().family(SansSerif)
  let serif = Attrs::new().family(Serif)
  let mono = Attrs::new().family(Monospace)
  inspect(fs.font_matches(sans), content="[0, 1]")
  inspect(fs.font_matches(serif), content="[0, 1]")
  inspect(fs.font_matches(mono), content="[0, 1]")
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

///|
test "FontSystem.count_supported_codepoints counts duplicates per run semantics" {
  let a = mk_min_font_cmap4_single(b'\x00', b'\x41')
  let b = mk_min_font_cmap4_single(b'\x00', b'\x42')
  let fs = FontSystem::new().load_font_data(a).load_font_data(b)
  let cps = [0x41U, 0x42U, 0x41U]
  inspect(fs.count_supported_codepoints(0, cps), content="2")
  inspect(fs.count_supported_codepoints(1, cps), content="1")
}

///|
test "FontSystem.select_family Name matches family aliases from name table" {
  let fs = FontSystem::new().load_font_data(test_font_inter_regular_ttf())
  match fs.get_font_entry(0) {
    None => inspect(true, content="false")
    Some(entry) =>
      match find_alt_family_name(entry) {
        None =>
          inspect(
            fs.select_family(Name(entry.family_name())),
            content="Some(0)",
          )
        Some(family_alias) =>
          inspect(fs.select_family(Name(family_alias)), content="Some(0)")
      }
  }
}

///|
test "FontSystem.font_matches_for_script promotes script-supporting fonts" {
  let min_font = mk_min_font_cmap4_single(b'\x00', b'\x41')
  let fs = FontSystem::new()
    .load_font_data(min_font)
    .load_font_data(test_font_inter_regular_ttf())
  let attrs = Attrs::new()
  let base = fs.font_matches(attrs)
  match first_discriminating_script_for_test(fs, base) {
    None => inspect(true, content="true")
    Some(script) => {
      let staged = fs.font_matches_for_script(attrs, script)
      let mut seen_unsupported = false
      let mut violated = false
      for id in staged {
        match fs.get_font_entry(id) {
          None => ()
          Some(entry) =>
            if entry_supports_script_for_test(entry, script) {
              if seen_unsupported {
                violated = true
              }
            } else {
              seen_unsupported = true
            }
        }
      }
      inspect(violated, content="false")
    }
  }
}

///|
test "FontSystem.font_matches_for_script keeps candidate set unchanged" {
  let min_font = mk_min_font_cmap4_single(b'\x00', b'\x41')
  let fs = FontSystem::new()
    .load_font_data(min_font)
    .load_font_data(test_font_inter_regular_ttf())
  let attrs = Attrs::new()
  let base = fs.font_matches(attrs)
  let s1 = fs.font_matches_for_script(attrs, @moon_swash.Script::Arabic)
  let s2 = fs.font_matches_for_script(attrs, @moon_swash.Script::Han)
  let s3 = fs.font_matches_for_script(attrs, @moon_swash.Script::Devanagari)
  inspect(is_permutation_of_ids_for_test(base, s1), content="true")
  inspect(is_permutation_of_ids_for_test(base, s2), content="true")
  inspect(is_permutation_of_ids_for_test(base, s3), content="true")
}

///|
test "FontSystem.font_matches_for_script remains stable across repeated cache hits" {
  let min_font = mk_min_font_cmap4_single(b'\x00', b'\x41')
  let fs = FontSystem::new()
    .load_font_data(min_font)
    .load_font_data(test_font_inter_regular_ttf())
  let attrs = Attrs::new()
  let scripts = [
    @moon_swash.Script::Arabic,
    @moon_swash.Script::Han,
    @moon_swash.Script::Hebrew,
    @moon_swash.Script::Thai,
    @moon_swash.Script::Devanagari,
  ]
  for i in 0..<2000 {
    fs.font_matches_for_script(attrs, scripts[i % scripts.length()]) |> ignore
  }
  inspect(fs.font_matches(attrs), content="[0, 1]")
}

///|
test "FontSystem.font_matches_for_script respects weight-zero gate for script/common promotion" {
  let min_font = mk_min_font_cmap4_single(b'\x00', b'\x41')
  let fs = FontSystem::new()
    .load_font_data(min_font)
    .load_font_data(test_font_inter_regular_ttf())
  let attrs = Attrs::new().weight(Weight::bold())
  let base = fs.font_matches(attrs)
  let arabic = fs.font_matches_for_script(attrs, @moon_swash.Script::Arabic)
  let han = fs.font_matches_for_script(attrs, @moon_swash.Script::Han)
  inspect(base == arabic, content="true")
  inspect(base == han, content="true")
}

///|
test "FontSystem.font_matches_for_scripts matches singleton script behavior" {
  let min_font = mk_min_font_cmap4_single(b'\x00', b'\x41')
  let fs = FontSystem::new()
    .load_font_data(min_font)
    .load_font_data(test_font_inter_regular_ttf())
  let attrs = Attrs::new()
  let script = @moon_swash.Script::Arabic
  inspect(
    fs.font_matches_for_scripts(attrs, [script]) ==
    fs.font_matches_for_script(attrs, script),
    content="true",
  )
}

///|
test "FontSystem.font_matches_for_scripts ignores latin/common/inherited/unknown" {
  let min_font = mk_min_font_cmap4_single(b'\x00', b'\x41')
  let fs = FontSystem::new()
    .load_font_data(min_font)
    .load_font_data(test_font_inter_regular_ttf())
  let attrs = Attrs::new()
  let base = fs.font_matches(attrs)
  let staged = fs.font_matches_for_scripts(attrs, [
    @moon_swash.Script::Latin,
    @moon_swash.Script::Common,
    @moon_swash.Script::Inherited,
    @moon_swash.Script::Unknown,
  ])
  inspect(staged == base, content="true")
}

///|
test "FontSystem.font_matches_for_scripts deduplicates repeated scripts" {
  let min_font = mk_min_font_cmap4_single(b'\x00', b'\x41')
  let fs = FontSystem::new()
    .load_font_data(min_font)
    .load_font_data(test_font_inter_regular_ttf())
  let attrs = Attrs::new()
  let repeated = fs.font_matches_for_scripts(attrs, [
    @moon_swash.Script::Arabic,
    @moon_swash.Script::Arabic,
    @moon_swash.Script::Han,
    @moon_swash.Script::Han,
  ])
  let unique = fs.font_matches_for_scripts(attrs, [
    @moon_swash.Script::Arabic,
    @moon_swash.Script::Han,
  ])
  inspect(repeated == unique, content="true")
}
