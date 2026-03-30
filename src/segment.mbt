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
/// Compatibility wrappers for segmentation APIs.
///
/// Implementations are hosted in the `linebreak` internal subpackage.
pub fn word_indices_whitespace(s : String) -> Array[(Int, Int)] {
  @linebreak.word_indices_whitespace(s)
}

///|
pub fn word_indices_uax29(s : String) -> Array[(Int, Int)] {
  @linebreak.word_indices_uax29(s)
}

///|
pub fn wrap_word_segments(s : String) -> Array[(Int, Int, Bool)] {
  @linebreak.wrap_word_segments(s)
}

///|
pub fn grapheme_indices_uax29(s : String) -> Array[(Int, Int)] {
  @linebreak.grapheme_indices_uax29(s)
}
