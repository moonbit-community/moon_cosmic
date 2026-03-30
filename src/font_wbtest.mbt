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
fn wb_push_u16_be(out : Array[Byte], v : Int) -> Unit {
  let u = v.reinterpret_as_uint()
  let mask = 255 |> Int::reinterpret_as_uint
  out.push(((u >> 8) & mask).to_byte())
  out.push((u & mask).to_byte())
}

///|
fn wb_push_u32_be(out : Array[Byte], v : UInt) -> Unit {
  let mask = 255 |> Int::reinterpret_as_uint
  out.push(((v >> 24) & mask).to_byte())
  out.push(((v >> 16) & mask).to_byte())
  out.push(((v >> 8) & mask).to_byte())
  out.push((v & mask).to_byte())
}

///|
fn wb_set_u16_be(buf : Array[Byte], off : Int, v : Int) -> Unit {
  let u = v.reinterpret_as_uint()
  let mask = 255 |> Int::reinterpret_as_uint
  buf[off] = ((u >> 8) & mask).to_byte()
  buf[off + 1] = (u & mask).to_byte()
}

///|
fn wb_set_u32_be(buf : Array[Byte], off : Int, v : UInt) -> Unit {
  let mask = 255 |> Int::reinterpret_as_uint
  buf[off] = ((v >> 24) & mask).to_byte()
  buf[off + 1] = ((v >> 16) & mask).to_byte()
  buf[off + 2] = ((v >> 8) & mask).to_byte()
  buf[off + 3] = (v & mask).to_byte()
}

///|
fn wb_fixed_16_16(x : Int) -> UInt {
  x.reinterpret_as_uint() << 16
}

///|
fn wb_build_sfnt(tables : Array[(UInt, Bytes)]) -> Bytes {
  // Caller provides tags in ascending order for parser binary-search paths.
  let num_tables = tables.length()
  let header_len = 12 + num_tables * 16
  let out : Array[Byte] = []
  wb_push_u32_be(out, 0x00010000U)
  wb_push_u16_be(out, num_tables)
  wb_push_u16_be(out, 0)
  wb_push_u16_be(out, 0)
  wb_push_u16_be(out, 0)
  let mut offset = header_len
  for table in tables {
    let (tag, data) = table
    wb_push_u32_be(out, tag)
    wb_push_u32_be(out, 0U)
    wb_push_u32_be(out, offset.reinterpret_as_uint())
    wb_push_u32_be(out, data.length().reinterpret_as_uint())
    offset = offset + data.length()
  }
  for table in tables {
    let (_, data) = table
    for b in data.iter() {
      out.push(b)
    }
  }
  Bytes::from_array(out[:])
}

///|
fn wb_make_fvar_one_axis_wght() -> Bytes {
  // fvar header (16) + 1 axis record (20) + 1 instance record (10)
  let buf : Array[Byte] = Array::makei(46, _ => b'\x00')
  wb_set_u16_be(buf, 0, 1) // major version
  wb_set_u16_be(buf, 2, 0) // minor version
  wb_set_u16_be(buf, 4, 16) // axesOffset
  wb_set_u16_be(buf, 8, 1) // axisCount
  wb_set_u16_be(buf, 10, 20) // axisSize
  wb_set_u16_be(buf, 12, 1) // instanceCount
  wb_set_u16_be(buf, 14, 10) // instanceSize

  // Axis record
  wb_set_u32_be(buf, 16, 0x77676874U) // "wght"
  wb_set_u32_be(buf, 20, wb_fixed_16_16(100))
  wb_set_u32_be(buf, 24, wb_fixed_16_16(400))
  wb_set_u32_be(buf, 28, wb_fixed_16_16(900))
  wb_set_u16_be(buf, 32, 0)
  wb_set_u16_be(buf, 34, 256)

  // Instance record
  wb_set_u16_be(buf, 36, 300)
  wb_set_u16_be(buf, 38, 0)
  wb_set_u32_be(buf, 40, wb_fixed_16_16(650))
  wb_set_u16_be(buf, 44, 301)
  Bytes::from_array(buf[:])
}

///|
fn wb_make_cmap4_single(cp_hi_byte : Byte, cp_lo_byte : Byte) -> Bytes {
  // Table bytes only (same payload as mk_min_font_cmap4_single's cmap table).
  Bytes::makei(44, i => {
    match i {
      0 => b'\x00'
      1 => b'\x00'
      2 => b'\x00'
      3 => b'\x01'
      4 => b'\x00'
      5 => b'\x03'
      6 => b'\x00'
      7 => b'\x01'
      8 => b'\x00'
      9 => b'\x00'
      10 => b'\x00'
      11 => b'\x0C'
      12 => b'\x00'
      13 => b'\x04'
      14 => b'\x00'
      15 => b'\x20'
      16 => b'\x00'
      17 => b'\x00'
      18 => b'\x00'
      19 => b'\x04'
      26 => cp_hi_byte
      27 => cp_lo_byte
      28 => b'\xFF'
      29 => b'\xFF'
      30 => b'\x00'
      31 => b'\x00'
      32 => cp_hi_byte
      33 => cp_lo_byte
      34 => b'\xFF'
      35 => b'\xFF'
      36 => b'\xFF'
      37 => b'\xC2'
      38 => b'\x00'
      39 => b'\x01'
      40 => b'\x00'
      41 => b'\x00'
      42 => b'\x00'
      43 => b'\x00'
      _ => b'\x00'
    }
  })
}

///|
fn mk_min_variable_font_cmap4_single(
  cp_hi_byte : Byte,
  cp_lo_byte : Byte,
) -> Bytes {
  wb_build_sfnt([
    (0x636D6170U, wb_make_cmap4_single(cp_hi_byte, cp_lo_byte)), // "cmap"
    (0x66766172U, wb_make_fvar_one_axis_wght()), // "fvar"
  ])
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
  inspect(
    script_fallback_family_names(@moon_swash.Script::TaiLe, "en-US", Unix),
    content="[\"Noto Sans Tai Le\"]",
  )
  inspect(
    script_fallback_family_names(@moon_swash.Script::TaiTham, "en-US", Unix),
    content="[\"Noto Sans Tai Tham\"]",
  )
  inspect(
    script_fallback_family_names(@moon_swash.Script::TaiViet, "en-US", Unix),
    content="[\"Noto Sans Tai Viet\"]",
  )
  inspect(
    script_fallback_family_names(
      @moon_swash.Script::CanadianAboriginal,
      "en-US",
      MacOS,
    ),
    content="[\"Euphemia UCAS\"]",
  )
  inspect(
    script_fallback_family_names(
      @moon_swash.Script::CanadianAboriginal,
      "en-US",
      Windows,
    ),
    content="[\"Gadugi\"]",
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
test "default stage allows explicit-family variable-weight candidate" {
  let data = mk_min_variable_font_cmap4_single(b'\x00', b'\x41')
  let fs = FontSystem::new().load_font_data(data)
  let family = match fs.get_font_entry(0) {
    Some(entry) => Name(entry.family_name())
    None => Name("")
  }
  let (defaults, rest) = split_default_stage_candidates(
    fs,
    family,
    Weight::bold(),
    [0],
  )
  inspect(defaults, content="[0]")
  inspect(rest, content="[]")
}

///|
test "named fallback candidate accepts variable-weight match" {
  let data = mk_min_variable_font_cmap4_single(b'\x00', b'\x41')
  let fs = FontSystem::new().load_font_data(data)
  let family_name = match fs.get_font_entry(0) {
    Some(entry) => entry.family_name()
    None => ""
  }
  inspect(
    first_named_fallback_candidate(fs, Weight::bold(), [0], family_name),
    content="Some(0)",
  )
}

///|
test "named fallback candidate rejects variable-weight outside axis range" {
  let data = mk_min_variable_font_cmap4_single(b'\x00', b'\x41')
  let fs = FontSystem::new().load_font_data(data)
  let family_name = match fs.get_font_entry(0) {
    Some(entry) => entry.family_name()
    None => ""
  }
  inspect(
    first_named_fallback_candidate(fs, Weight::new(950), [0], family_name),
    content="None",
  )
}

///|
test "named fallback candidate still rejects non-variable non-zero weight diff" {
  let data = mk_min_font_cmap4_single(b'\x00', b'\x41')
  let fs = FontSystem::new().load_font_data(data)
  let family_name = match fs.get_font_entry(0) {
    Some(entry) => entry.family_name()
    None => ""
  }
  inspect(
    first_named_fallback_candidate(fs, Weight::bold(), [0], family_name),
    content="None",
  )
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
    match
      first_named_fallback_candidate(
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
test "font match ordering keeps id tie-break ahead of variable-weight flag" {
  let var_data = mk_min_variable_font_cmap4_single(b'\x00', b'\x41')
  let static_data = mk_min_font_cmap4_single(b'\x00', b'\x41')
  let fs = FontSystem::new()
    .load_font_data(var_data)
    .load_font_data(static_data)
  let attrs = Attrs::new().weight(Weight::bold())
  inspect(fs.font_matches(attrs), content="[0, 1]")
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
