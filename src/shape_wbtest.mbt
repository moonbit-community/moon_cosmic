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
  @moon_swash.Token::new(
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
  inspect(sort_monospace_infos_for_test(infos), content="[11, 12, 10]")
}

///|
test "monospace fallback ranks weight diff before codepoint coverage" {
  let infos : Array[(Int, Bool, Int, Int, Int)] = [
    // better coverage but worse weight diff
    (10, false, 2, 0, 400),
    // worse coverage but exact weight
    (11, false, 0, 3, 400),
  ]
  inspect(sort_monospace_infos_for_test(infos), content="[11, 10]")
}

///|
test "monospace fallback ranks lower non-matches when weight diff ties" {
  let infos : Array[(Int, Bool, Int, Int, Int)] = [
    (10, false, 1, 3, 400),
    (11, false, 1, 1, 400),
    (12, false, 1, 2, 400),
  ]
  inspect(sort_monospace_infos_for_test(infos), content="[11, 12, 10]")
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
