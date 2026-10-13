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
test "Affinity helpers" {
  inspect(@moon_cosmic.Affinity::Before.before(), content="true")
  inspect(@moon_cosmic.Affinity::Before.after(), content="false")
  inspect(@moon_cosmic.Affinity::After.before(), content="false")
  inspect(@moon_cosmic.Affinity::After.after(), content="true")
  inspect(
    match @moon_cosmic.Affinity::from_before(true) {
      Before => true
      _ => false
    },
    content="true",
  )
  inspect(
    match @moon_cosmic.Affinity::from_after(true) {
      After => true
      _ => false
    },
    content="true",
  )
}

///|
test "Cursor constructors" {
  let c0 = @moon_cosmic.Cursor::new(1, 2)
  inspect(c0.line, content="1")
  inspect(c0.index, content="2")
  inspect(
    match c0.affinity {
      Before => true
      _ => false
    },
    content="true",
  )
  let c1 = @moon_cosmic.Cursor::new_with_affinity(3, 4, After)
  inspect(
    match c1.affinity {
      After => true
      _ => false
    },
    content="true",
  )
}

///|
test "Scroll default/new" {
  let s0 = @moon_cosmic.Scroll::default()
  inspect(s0.line, content="0")
  inspect(s0.vertical, content="0")
  inspect(s0.horizontal, content="0")
  let s1 = @moon_cosmic.Scroll::new(2, 3.0F, 4.0F)
  inspect(s1.line, content="2")
  inspect(s1.vertical, content="3")
  inspect(s1.horizontal, content="4")
}
