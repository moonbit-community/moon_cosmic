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
/// An iterator over paragraphs in input text.
///
/// Behavior follows `unicode-bidi` paragraph ranges:
/// paragraph separator characters (`BidiClass::B`) remain in the paragraph range
/// but are trimmed from the returned paragraph text.
pub struct BidiParagraphs {
  text : String
  ranges : Array[(Int, Int)]
  cursor : Int
  pos : Int
}

///|
fn bidi_paragraphs_is_ascii_fast_path(text : String) -> Bool {
  for ch in text {
    if ch.to_int() > 0x7F {
      return false
    }
    if ch.is_control() && ch != '\n' && ch != '\r' && ch != '\t' {
      return false
    }
  }
  true
}

///|
fn bidi_paragraphs_ascii_ranges(text : String) -> Array[(Int, Int)] {
  let ranges : Array[(Int, Int)] = []
  let len = text.length()
  let mut start = 0
  for p in text.iter2() {
    let i = p.0
    let ch = p.1
    if ch == '\n' {
      ranges.push((start, i))
      start = i + 1
    }
  }
  if start < len {
    ranges.push((start, len))
  }
  ranges
}

///|
fn bidi_paragraphs_ranges(text : String) -> Array[(Int, Int)] {
  if bidi_paragraphs_is_ascii_fast_path(text) {
    return bidi_paragraphs_ascii_ranges(text)
  }

  let ranges : Array[(Int, Int)] = []
  let info = BidiInfo::new(text)
  for para in info.paragraphs() {
    ranges.push((para.range_start(), para.range_end()))
  }
  ranges
}

///|
fn bidi_paragraphs_trim_trailing_b_separator(para : String) -> String {
  let mut last : (Int, Char)? = None
  for p in para.iter2() {
    last = Some((p.0, p.1))
  }
  match last {
    None => para
    Some((idx, ch)) => {
      let class = @moon_swash.CharInfo::from_char(ch).properties().bidi_class()
      if class is B {
        slice_string(para, 0, idx)
      } else {
        para
      }
    }
  }
}

///|
pub fn BidiParagraphs::new(text : String) -> BidiParagraphs {
  let ranges = bidi_paragraphs_ranges(text)
  let pos = if ranges.length() == 0 { text.length() } else { ranges[0].0 }
  BidiParagraphs::{ text, ranges, cursor: 0, pos }
}

///|
/// Returns (next, paragraph_text) if any.
pub fn BidiParagraphs::next(self : BidiParagraphs) -> (BidiParagraphs, String)? {
  if self.cursor >= self.ranges.length() {
    return None
  }
  let range = self.ranges[self.cursor]
  let para_raw = slice_string(self.text, range.0, range.1)
  let para = bidi_paragraphs_trim_trailing_b_separator(para_raw)
  let next_cursor = self.cursor + 1
  let next_pos = if next_cursor >= self.ranges.length() {
    self.text.length()
  } else {
    self.ranges[next_cursor].0
  }
  Some((BidiParagraphs::{ ..self, cursor: next_cursor, pos: next_pos }, para))
}

///|
pub fn BidiParagraphs::iter(self : BidiParagraphs) -> Iter[String] {
  let mut it = self
  Iter::new(fn() {
    match it.next() {
      None => None
      Some((next, para)) => {
        it = next
        Some(para)
      }
    }
  })
}
