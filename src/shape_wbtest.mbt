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
fn sort_monospace_infos_for_test(
  infos : Array[(Int, Bool, Int, Int, Int)],
) -> Array[Int] {
  let n = infos.length()
  let used : Array[Bool] = Array::makei(n, _ => false)
  let ids : Array[Int] = []
  for _ in 0..<n {
    let mut best = -1
    for i in 0..<n {
      if used[i] {
        continue
      }
      if best < 0 || better_monospace_fallback_candidate(infos[i], infos[best]) {
        best = i
      }
    }
    if best >= 0 {
      used.set(best, true)
      ids.push(infos[best].0)
    }
  }
  ids
}

///|
fn token_for_test(ch : Char, offset : Int) -> @moon_swash.Token {
  @moon_swash.Token::Token(
    ch,
    offset.reinterpret_as_uint(),
    utf16_len_of_char(ch).reinterpret_as_uint(),
    @moon_swash.CharInfo::from_char(ch),
    0U,
  )
}

///|
test "monospace fallback primary-default rank has top priority" {
  let infos : Array[(Int, Bool, Int, Int, Int)] = [
    (10, false, 0, 0, 400),
    (11, true, 10, 999, 900),
    (12, false, 0, 0, 300),
  ]
  debug_inspect(sort_monospace_infos_for_test(infos), content="[11, 12, 10]")
}

///|
test "monospace fallback ranks weight diff before codepoint coverage" {
  let infos : Array[(Int, Bool, Int, Int, Int)] = [
    // better coverage but worse weight diff
    (10, false, 2, 0, 400),
    // worse coverage but exact weight
    (11, false, 0, 3, 400),
  ]
  debug_inspect(sort_monospace_infos_for_test(infos), content="[11, 10]")
}

///|
test "monospace fallback ranks lower non-matches when weight diff ties" {
  let infos : Array[(Int, Bool, Int, Int, Int)] = [
    (10, false, 1, 3, 400),
    (11, false, 1, 1, 400),
    (12, false, 1, 2, 400),
  ]
  debug_inspect(sort_monospace_infos_for_test(infos), content="[11, 12, 10]")
}

///|
test "collect_run_fallback_scripts keeps first-seen unique script order" {
  let tokens = [
    token_for_test('a', 0),
    token_for_test(' ', 1),
    token_for_test('\u{0628}', 2),
    token_for_test('\u{4F60}', 3),
    token_for_test('\u{0628}', 4),
    token_for_test('\u{3042}', 5),
  ]
  let scripts = collect_run_fallback_scripts(tokens)
  let ok = scripts.length() == 3 &&
    script_eq(scripts[0], @moon_swash.Script::Arabic) &&
    script_eq(scripts[1], @moon_swash.Script::Han) &&
    script_eq(scripts[2], @moon_swash.Script::Hiragana)
  inspect(ok, content="true")
}

///|
test "collect_run_fallback_scripts ignores latin/common/inherited/unknown" {
  let tokens = [
    token_for_test('a', 0),
    token_for_test('1', 1),
    token_for_test(' ', 2),
  ]
  inspect(collect_run_fallback_scripts(tokens).length(), content="0")
}

///|
test "shape_primary_script_seed keeps latin when explicitly latin" {
  let latin = shape_primary_script_seed(@moon_swash.Script::Latin)
  let common = shape_primary_script_seed(@moon_swash.Script::Common)
  let arabic = shape_primary_script_seed(@moon_swash.Script::Arabic)
  inspect(
    script_eq(latin.0, @moon_swash.Script::Latin) && !latin.1,
    content="true",
  )
  inspect(
    script_eq(common.0, @moon_swash.Script::Latin) && common.1,
    content="true",
  )
  inspect(
    script_eq(arabic.0, @moon_swash.Script::Arabic) && !arabic.1,
    content="true",
  )
}

///|
test "shape_levels_require_new_run splits on any level change" {
  inspect(shape_levels_require_new_run(0, 0), content="false")
  inspect(shape_levels_require_new_run(0, 2), content="true")
  inspect(shape_levels_require_new_run(1, 2), content="true")
}

///|
fn repeated_ascii_digit(n : Int) -> String {
  let sb = StringBuilder::new(size_hint=n)
  for _ in 0..<n {
    sb.write_char('1')
  }
  sb.to_string()
}

///|
test "BidiInfo keeps explicit paragraph base level when no strong chars" {
  debug_inspect(
    BidiInfo::new_with_para_level("12345", Some(0)).adjusted_levels(),
    content="[0, 0, 0, 0, 0]",
  )
  debug_inspect(
    BidiInfo::new_with_para_level("12345", Some(1)).adjusted_levels(),
    content="[2, 2, 2, 2, 2]",
  )
}

///|
test "BidiInfo stays responsive on long neutral-heavy numeric input" {
  let text = repeated_ascii_digit(100000)
  let levels = BidiInfo::new_with_para_level(text, Some(0)).adjusted_levels()
  let ok = levels.length() == text.length() &&
    levels[0] == 0 &&
    levels[levels.length() - 1] == 0
  inspect(ok, content="true")
}

///|
test "BidiInfo auto paragraph direction follows first strong character" {
  inspect(BidiInfo::new("א 1 A").rtl(), content="true")
  inspect(BidiInfo::new("A 1 א").rtl(), content="false")
}

///|
test "BidiInfo resolves neutrals between opposite strong levels to paragraph base" {
  let levels = BidiInfo::new("א 1 A").adjusted_levels()
  debug_inspect(levels, content="[1, 1, 2, 1, 2]")
}

///|
test "BidiInfo uses single-sided strong level for trailing neutrals" {
  let levels = BidiInfo::new_with_para_level("A 12", Some(1)).adjusted_levels()
  let ok = levels.length() == 4 &&
    levels[0] == 2 &&
    levels[1] == 2 &&
    levels[2] == 2 &&
    levels[3] == 2
  inspect(ok, content="true")
}

///|
test "BidiInfo retains explicit formatting controls during adjusted level pass" {
  debug_inspect(
    BidiInfo::new("\u{202B}12\u{202C}").adjusted_levels(),
    content="[0, 2, 2, 0]",
  )
  debug_inspect(
    BidiInfo::new_with_para_level("\u{202B}12\u{202C}", Some(1)).adjusted_levels(),
    content="[1, 4, 4, 1]",
  )
}

///|
test "BidiInfo resolves FSI to direction of first strong in isolate scope" {
  debug_inspect(
    BidiInfo::new("a\u{2068}א\u{2069}1").adjusted_levels(),
    content="[0, 0, 1, 0, 0]",
  )
  debug_inspect(
    BidiInfo::new("a\u{2068}A\u{2069}1").adjusted_levels(),
    content="[0, 0, 2, 0, 0]",
  )
}

///|
test "BidiInfo applies bracket-pair neutral resolution in RTL context" {
  debug_inspect(
    BidiInfo::new("(א A)").adjusted_levels(),
    content="[1, 1, 1, 2, 1]",
  )
}

///|
test "shape run cache is cleared when fonts are loaded" {
  let fs = FontSystem::new().load_font_data(
    mk_min_font_cmap4_single(b'\x00', b'\x41'),
  )
  let attrs = AttrsList::new(Attrs::new())
  ShapeLine::build_with_font_system(
    ShapeLine::empty(),
    fs,
    "B",
    attrs,
    Shaping::Advanced,
    8,
  )
  |> ignore
  inspect(
    fs.shape_run_cache.peek(ShapeRunKey::new("B", attrs)) is Some(_),
    content="true",
  )
  fs.load_font_data(mk_min_font_cmap4_single(b'\x00', b'\x42')) |> ignore
  inspect(
    fs.shape_run_cache.peek(ShapeRunKey::new("B", attrs)) is Some(_),
    content="false",
  )
}

///|
test "shape variation settings clamp weight to variable axis range" {
  let fs = FontSystem::new().load_font_data(
    mk_min_variable_font_cmap4_single(b'\x00', b'\x41'),
  )
  let font = fs.get_font(0).unwrap()
  let attrs_hi = Attrs::new().weight(Weight::new(950))
  let attrs_lo = Attrs::new().weight(Weight::new(50))
  let vars_hi = shape_variation_settings_for_font(font, attrs_hi)
  let vars_lo = shape_variation_settings_for_font(font, attrs_lo)
  inspect(vars_hi.length(), content="1")
  inspect(vars_lo.length(), content="1")
  let axis = font.variations().find_by_tag(0x77676874U).unwrap()
  let coords_hi = font.variations().normalized_coords(vars_hi.iter()).to_array()
  let coords_lo = font.variations().normalized_coords(vars_lo.iter()).to_array()
  inspect(coords_hi[0] == axis.normalize(900.0), content="true")
  inspect(coords_lo[0] == axis.normalize(100.0), content="true")
}

///|
test "shape variation settings are empty for non-variable fonts" {
  let fs = FontSystem::new().load_font_data(
    mk_min_font_cmap4_single(b'\x00', b'\x41'),
  )
  let font = fs.get_font(0).unwrap()
  let attrs = Attrs::new().weight(Weight::bold())
  inspect(shape_variation_settings_for_font(font, attrs).length(), content="0")
}
