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
test "word_indices_whitespace basic" {
  let ranges = word_indices_whitespace("  hello\tworld\nmoon  ")
  inspect(ranges.length(), content="3")
  inspect(ranges[0], content="(2, 7)")
  inspect(ranges[1], content="(8, 13)")
  inspect(ranges[2], content="(14, 18)")
}

///|
test "wrap_word_segments basic ASCII" {
  inspect(
    wrap_word_segments("hello world"),
    content="[(0, 5, false), (5, 6, true), (6, 11, false)]",
  )
}

///|
test "wrap_word_segments uses UAX#14 opportunities (hyphen)" {
  // UAX#14 generally allows a break opportunity after '-'.
  inspect(wrap_word_segments("a-b"), content="[(0, 2, false), (2, 3, false)]")
}

///|
test "word_indices_uax29 basic ASCII" {
  inspect(word_indices_uax29("hello world"), content="[(0, 5), (6, 11)]")
}

///|
test "word_indices_uax29 ignores punctuation-only segments" {
  inspect(word_indices_uax29("a-b"), content="[(0, 1), (2, 3)]")
  inspect(word_indices_uax29("..."), content="[]")
}

///|
test "word_indices_uax29 follows unicode_word_indices-style alnum filtering" {
  inspect(word_indices_uax29("_"), content="[]")
  inspect(word_indices_uax29("a_b"), content="[(0, 3)]")
  inspect(word_indices_uax29("don't"), content="[(0, 5)]")
  inspect(word_indices_uax29("x!=y"), content="[(0, 1), (3, 4)]")
  inspect(word_indices_uax29("a\u{00A0}b"), content="[(0, 1), (2, 3)]")
}

///|
test "wrap_word_segments honors non-breaking space behavior" {
  inspect(wrap_word_segments("a\u{00A0}b"), content="[(0, 3, false)]")
}

///|
test "word_indices_uax29 matches unicode-segmentation for mixed punctuation and emoji cases" {
  inspect(word_indices_uax29("foo->bar"), content="[(0, 3), (5, 8)]")
  inspect(word_indices_uax29("a  b"), content="[(0, 1), (3, 4)]")
  inspect(word_indices_uax29("中 文"), content="[(0, 1), (2, 3)]")
  inspect(word_indices_uax29("👨‍👩‍👧 family"), content="[(9, 15)]")
}

///|
test "word_indices_uax29 follows unicode-segmentation thai boundary behavior" {
  inspect(
    word_indices_uax29("ไทยภาษา"),
    content="[(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7)]",
  )
}

///|
test "wrap_word_segments matches unicode-linebreak boundary samples" {
  inspect(wrap_word_segments("x!=y"), content="[(0, 4, false)]")
  inspect(wrap_word_segments("foo->bar"), content="[(0, 8, false)]")
  inspect(
    wrap_word_segments("中 文"),
    content="[(0, 1, false), (1, 2, true), (2, 3, false)]",
  )
  inspect(
    wrap_word_segments("👨‍👩‍👧 family"),
    content="[(0, 8, false), (8, 9, true), (9, 15, false)]",
  )
}

///|
test "segment behavior tracks additional unicode segmentation samples" {
  inspect(word_indices_uax29("--"), content="[]")
  inspect(word_indices_uax29("a--b"), content="[(0, 1), (3, 4)]")
  inspect(word_indices_uax29("123,456"), content="[(0, 7)]")
  inspect(word_indices_uax29("e-mail"), content="[(0, 1), (2, 6)]")
  inspect(word_indices_uax29("co_op"), content="[(0, 5)]")
  inspect(word_indices_uax29("a…b"), content="[(0, 1), (2, 3)]")
  inspect(word_indices_uax29("a\u{2009}b"), content="[(0, 1), (2, 3)]")
  inspect(word_indices_uax29("a\u{202F}b"), content="[(0, 3)]")
  inspect(word_indices_uax29("कक\u{94D}षा"), content="[(0, 5)]")

  inspect(wrap_word_segments("--"), content="[(0, 2, false)]")
  inspect(wrap_word_segments("a--b"), content="[(0, 3, false), (3, 4, false)]")
  inspect(wrap_word_segments("123,456"), content="[(0, 7, false)]")
  inspect(
    wrap_word_segments("e-mail"),
    content="[(0, 2, false), (2, 6, false)]",
  )
  inspect(wrap_word_segments("co_op"), content="[(0, 5, false)]")
  inspect(wrap_word_segments("a…b"), content="[(0, 2, false), (2, 3, false)]")
  inspect(
    wrap_word_segments("a\u{2009}b"),
    content="[(0, 1, false), (1, 2, true), (2, 3, false)]",
  )
  inspect(wrap_word_segments("a\u{202F}b"), content="[(0, 3, false)]")
  inspect(wrap_word_segments("कक\u{94D}षा"), content="[(0, 5, false)]")
}
