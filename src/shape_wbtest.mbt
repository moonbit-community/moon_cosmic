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
