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
  let selected = take_named_fallback_candidates(
    fs,
    Weight::normal(),
    [2, 99, 1, 0],
    [family_name],
  )
  let reordered : Array[Int] = []
  for id in selected.0 {
    reordered.push(id)
  }
  for id in selected.1 {
    reordered.push(id)
  }
  inspect(reordered, content="[2, 99, 1, 0]")
}

///|
test "take_named_fallback_candidates returns promoted and rest stages" {
  let min = mk_min_font_cmap4_single(b'\x00', b'\x41')
  let fs = FontSystem::new()
    .load_font_data(min)
    .load_font_data(min)
    .load_font_data(min)
  let family_name = match fs.get_font_entry(0) {
    Some(entry) => entry.family_name()
    None => ""
  }
  let selected = take_named_fallback_candidates(
    fs,
    Weight::normal(),
    [2, 99, 1, 0],
    [family_name],
  )
  inspect(selected.0, content="[2]")
  inspect(selected.1, content="[99, 1, 0]")
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
