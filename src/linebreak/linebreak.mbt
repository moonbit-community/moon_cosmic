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
/// Compatibility wrapper that forwards to `unicode_linebreak`.
pub fn word_indices_whitespace(s : String) -> Array[(Int, Int)] {
  @unicode_linebreak.word_indices_whitespace(s)
}

///|
pub fn word_indices_uax29(s : String) -> Array[(Int, Int)] {
  @unicode_linebreak.word_indices_uax29(s)
}

///|
pub(all) enum BreakOpportunity {
  Mandatory
  Allowed
  Prohibited
}

///|
fn map_break_opportunity(
  op : @unicode_linebreak.BreakOpportunity,
) -> BreakOpportunity {
  match op {
    @unicode_linebreak.BreakOpportunity::Mandatory => Mandatory
    @unicode_linebreak.BreakOpportunity::Allowed => Allowed
    @unicode_linebreak.BreakOpportunity::Prohibited => Prohibited
  }
}

///|
pub fn is_ligature_guard_pair(left : Char, right : Char) -> Bool {
  @unicode_linebreak.is_ligature_guard_pair(left, right)
}

///|
pub fn linebreaks(s : String) -> Array[(Int, BreakOpportunity)] {
  let out : Array[(Int, BreakOpportunity)] = []
  for br in @unicode_linebreak.linebreaks(s) {
    let offset = br.0
    let op = br.1
    out.push((offset, map_break_opportunity(op)))
  }
  out
}

///|
pub fn wrap_word_segments(s : String) -> Array[(Int, Int, Bool)] {
  @unicode_linebreak.wrap_word_segments(s)
}

///|
pub fn grapheme_indices_uax29(s : String) -> Array[(Int, Int)] {
  @unicode_linebreak.grapheme_indices_uax29(s)
}
