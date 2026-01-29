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
/// Paragraph iterator for bidi-aware text processing.
///
/// Upstream `cosmic-text` uses `unicode-bidi` to find paragraph boundaries.
/// For now (wasm-gc friendly), we approximate this by iterating `LineIter`
/// and returning each line without the trailing line ending.
pub struct BidiParagraphs {
  text : String
  iter : LineIter
}

///|
pub fn BidiParagraphs::new(text : String) -> BidiParagraphs {
  BidiParagraphs::{ text, iter: LineIter::new(text) }
}

///|
/// Returns (next, paragraph_text) if any.
pub fn BidiParagraphs::next(self : BidiParagraphs) -> (BidiParagraphs, String)? {
  let (next_iter, item_opt) = self.iter.next()
  match item_opt {
    None => None
    Some(item) => {
      let start = item.0
      let end = item.1
      let para = slice_string(self.text, start, end)
      Some((BidiParagraphs::{ ..self, iter: next_iter }, para))
    }
  }
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
