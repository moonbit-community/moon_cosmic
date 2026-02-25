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
test "platform fallback family tables match reference profiles" {
  inspect(
    common_fallback_family_names(Unix),
    content="[\"Noto Sans\", \"DejaVu Sans\", \"FreeSans\", \"Noto Sans Mono\", \"DejaVu Sans Mono\", \"FreeMono\", \"Noto Sans Symbols\", \"Noto Sans Symbols2\", \"Noto Color Emoji\"]",
  )
  inspect(
    common_fallback_family_names(MacOS),
    content="[\".SF NS\", \"Menlo\", \"Apple Color Emoji\", \"Geneva\", \"Arial Unicode MS\"]",
  )
  inspect(
    common_fallback_family_names(Windows),
    content="[\"Segoe UI\", \"Segoe UI Emoji\", \"Segoe UI Symbol\", \"Segoe UI Historic\"]",
  )
  inspect(common_fallback_family_names(Other), content="[]")
  inspect(forbidden_fallback_family_names(Unix), content="[]")
  inspect(forbidden_fallback_family_names(MacOS), content="[\".LastResort\"]")
  inspect(forbidden_fallback_family_names(Windows), content="[]")
  inspect(forbidden_fallback_family_names(Other), content="[]")
}

///|
test "script fallback family tables are profile-specific" {
  inspect(
    script_fallback_family_names(@moon_swash.Script::Arabic, "en-US", Unix),
    content="[\"Noto Sans Arabic\"]",
  )
  inspect(
    script_fallback_family_names(@moon_swash.Script::Arabic, "en-US", MacOS),
    content="[\"Geeza Pro\"]",
  )
  inspect(
    script_fallback_family_names(@moon_swash.Script::Arabic, "en-US", Windows),
    content="[]",
  )
  inspect(
    script_fallback_family_names(@moon_swash.Script::Han, "zh-TW", Unix),
    content="[\"Noto Sans CJK TC\"]",
  )
  inspect(
    script_fallback_family_names(@moon_swash.Script::Han, "zh-TW", MacOS),
    content="[\"PingFang TC\"]",
  )
  inspect(
    script_fallback_family_names(@moon_swash.Script::Han, "zh-TW", Windows),
    content="[\"Microsoft JhengHei UI\"]",
  )
  inspect(
    script_fallback_family_names(@moon_swash.Script::Han, "zh-TW", Other),
    content="[]",
  )
}

///|
test "default stage keeps only the primary zero-weight explicit-family candidate" {
  let data = mk_min_font_cmap4_single(b'\x00', b'\x41')
  let fs = FontSystem::new().load_font_data(data).load_font_data(data)
  let family = match fs.get_font_entry(0) {
    Some(entry) => Name(entry.family_name())
    None => Name("")
  }
  let (defaults, rest) = split_default_stage_candidates(
    fs,
    family,
    Weight::normal(),
    [0, 1],
  )
  inspect(defaults, content="[0]")
  inspect(rest, content="[1]")
}

///|
test "font_matches_for_scripts keeps full other-stage stream after default stage" {
  let data = mk_min_font_cmap4_single(b'\x00', b'\x41')
  let fs = FontSystem::new().load_font_data(data).load_font_data(data)
  let family = match fs.get_font_entry(0) {
    Some(entry) => Name(entry.family_name())
    None => Name("")
  }
  let attrs = Attrs::new().family(family)
  inspect(fs.font_matches_for_scripts(attrs, []), content="[0, 0, 1]")
}

///|
test "named fallback stage promotes only first match for each family" {
  let min = mk_min_font_cmap4_single(b'\x00', b'\x41')
  let fs = FontSystem::new()
    .load_font_data(min)
    .load_font_data(min)
    .load_font_data(min)
  let family_name = match fs.get_font_entry(2) {
    Some(entry) => entry.family_name()
    None => ""
  }
  let promoted : Array[Int] = []
  for _ in 0..<2 {
    match first_named_fallback_candidate(
      fs,
      Weight::normal(),
      [2, 99, 1, 0],
      family_name,
    ) {
      None => ()
      Some(id) => promoted.push(id)
    }
  }
  inspect(promoted, content="[2, 2]")
}

///|
test "first_named_fallback_candidate returns first valid weight-zero match" {
  let min = mk_min_font_cmap4_single(b'\x00', b'\x41')
  let fs = FontSystem::new()
    .load_font_data(min)
    .load_font_data(min)
    .load_font_data(min)
  let family_name = match fs.get_font_entry(0) {
    Some(entry) => entry.family_name()
    None => ""
  }
  let selected = first_named_fallback_candidate(
    fs,
    Weight::normal(),
    [2, 99, 1, 0],
    family_name,
  )
  inspect(selected, content="Some(2)")
}

///|
test "forbidden filtering applies to other-stage candidates only" {
  let min = mk_min_font_cmap4_single(b'\x00', b'\x41')
  let fs = FontSystem::new().load_font_data(min)
  let forbidden = match fs.get_font_entry(0) {
    Some(entry) => [entry.family_name()]
    None => []
  }
  inspect(
    filter_forbidden_from_other_stage(fs, forbidden, [0, 99]),
    content="[99]",
  )
}

///|
#cfg(not(target="native"))
test "non-native fallback profile defaults to Other" {
  let data = mk_min_font_cmap4_single(b'\x00', b'\x41')
  let fs = FontSystem::new().load_font_data(data)
  let is_other = match fallback_profile(fs) {
    Other => true
    _ => false
  }
  inspect(is_other, content="true")
}
