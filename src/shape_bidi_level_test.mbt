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
test "ShapeLine.build assigns heuristic bidi levels (LTR base)" {
  let text = "abc \u{05D0}\u{05D1}"
  let shape = ShapeLine::build(
    ShapeLine::empty(),
    text,
    AttrsList::new(Attrs::new()),
    Shaping::Advanced,
    8,
  )
  // "abc " => base LTR (0); Hebrew letters => RTL (1)
  inspect(shape.rtl, content="false")
  inspect(shape.glyphs.length(), content="6")
  inspect(shape.glyphs[0].level, content="0")
  inspect(shape.glyphs[3].level, content="0") // space
  inspect(shape.glyphs[4].level, content="1")
  inspect(shape.glyphs[5].level, content="1")
}

///|
test "ShapeLine.build assigns heuristic bidi levels (RTL base)" {
  let text = "\u{05D0}\u{05D1} abc"
  let shape = ShapeLine::build(
    ShapeLine::empty(),
    text,
    AttrsList::new(Attrs::new()),
    Shaping::Advanced,
    8,
  )
  // Hebrew => base RTL (1); Latin letters are embedded LTR (2)
  inspect(shape.rtl, content="true")
  inspect(shape.glyphs.length(), content="6")
  inspect(shape.glyphs[0].level, content="1")
  inspect(shape.glyphs[2].level, content="1") // space
  inspect(shape.glyphs[3].level, content="2")
  inspect(shape.glyphs[5].level, content="2")
}
