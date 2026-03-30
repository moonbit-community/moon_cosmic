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
/// Subpackage for word/grapheme/linebreak segmentation.
fn is_ws(code : Int) -> Bool {
  code == 32 || code == 9 || code == 10 || code == 13
}

///|
pub fn word_indices_whitespace(s : String) -> Array[(Int, Int)] {
  let ranges : Array[(Int, Int)] = []
  let len = s.length()
  let mut i = 0
  while i < len {
    while i < len && is_ws(s.code_unit_at(i).to_int()) {
      i = i + 1
    }
    if i >= len {
      break
    }
    let start = i
    while i < len && !is_ws(s.code_unit_at(i).to_int()) {
      i = i + 1
    }
    ranges.push((start, i))
  }
  ranges
}

///|
pub fn word_indices_uax29(s : String) -> Array[(Int, Int)] {
  let chars = s.to_array()
  if chars.length() == 0 {
    return []
  }
  let analyze = @moon_swash.analyze(chars.iter())
  analyze.set_break_strength(@moon_swash.WordBreakStrength::Normal)
  let offs : Array[Int] = []
  let mut pos = 0
  for ch in chars {
    offs.push(pos)
    pos = pos + ch.utf16_len()
  }
  fn category_is_unicode_word_alnum(category : @moon_swash.Category) -> Bool {
    match category {
      @moon_swash.Category::CasedLetter
      | @moon_swash.Category::DecimalNumber
      | @moon_swash.Category::Letter
      | @moon_swash.Category::LetterNumber
      | @moon_swash.Category::LowercaseLetter
      | @moon_swash.Category::ModifierLetter
      | @moon_swash.Category::Number
      | @moon_swash.Category::OtherLetter
      | @moon_swash.Category::OtherNumber
      | @moon_swash.Category::TitlecaseLetter
      | @moon_swash.Category::UppercaseLetter => true
      _ => false
    }
  }
  fn segment_contains_word_like(
    chars : Array[Char],
    start_char_i : Int,
    end_char_i : Int,
  ) -> Bool {
    if end_char_i < start_char_i {
      return false
    }
    for i in start_char_i..<(end_char_i + 1) {
      let cat = @moon_swash.CharInfo::from_char(chars[i]).category()
      if category_is_unicode_word_alnum(cat) {
        return true
      }
    }
    false
  }
  let ranges : Array[(Int, Int)] = []
  let mut start_pos = 0
  let mut start_char_i = 0
  for i in 0..<chars.length() {
    match analyze.next() {
      None => break
      Some((_props, boundary)) =>
        match boundary {
          Word | Line | Mandatory => {
            let break_pos = offs[i]
            if break_pos > start_pos &&
              segment_contains_word_like(chars, start_char_i, i - 1) {
              ranges.push((start_pos, break_pos))
            }
            start_pos = break_pos
            start_char_i = i
          }
          None => ()
        }
    }
  }
  if pos > start_pos &&
    segment_contains_word_like(chars, start_char_i, chars.length() - 1) {
    ranges.push((start_pos, pos))
  }
  ranges
}

///|
pub(all) enum BreakOpportunity {
  Mandatory
  Allowed
  Prohibited
}

///|
pub fn is_ligature_guard_pair(left : Char, right : Char) -> Bool {
  (left == '|' && right == '>') ||
  (left == '!' && right == '=') ||
  (left == '-' && right == '>')
}

///|
/// Returns `(utf16_offset, break_opportunity)` pairs.
pub fn linebreaks(s : String) -> Array[(Int, BreakOpportunity)] {
  let chars = s.to_array()
  if chars.length() == 0 {
    return [(0, BreakOpportunity::Mandatory)]
  }
  let offs : Array[Int] = []
  let mut pos = 0
  for ch in chars {
    offs.push(pos)
    pos = pos + ch.utf16_len()
  }
  let analyze = @moon_swash.analyze(chars.iter())
  analyze.set_break_strength(@moon_swash.WordBreakStrength::Normal)
  let out : Array[(Int, BreakOpportunity)] = []
  for i in 0..<chars.length() {
    match analyze.next() {
      None => break
      Some((_props, boundary)) =>
        match boundary {
          Mandatory => out.push((offs[i], BreakOpportunity::Mandatory))
          Line =>
            if i > 0 && is_ligature_guard_pair(chars[i - 1], chars[i]) {
              ()
            } else {
              out.push((offs[i], BreakOpportunity::Allowed))
            }
          _ => ()
        }
    }
  }
  if out.length() == 0 || out[out.length() - 1].0 != s.length() {
    out.push((s.length(), BreakOpportunity::Mandatory))
  }
  out
}

///|
pub fn wrap_word_segments(s : String) -> Array[(Int, Int, Bool)] {
  let chars = s.to_array()
  if chars.length() == 0 {
    return []
  }

  let offs : Array[Int] = []
  let lens : Array[Int] = []
  let mut pos = 0
  for ch in chars {
    offs.push(pos)
    let len = ch.utf16_len()
    lens.push(len)
    pos = pos + len
  }
  fn emit_segment(
    out : Array[(Int, Int, Bool)],
    chars : Array[Char],
    offs : Array[Int],
    lens : Array[Int],
    start_char_i : Int,
    end_char_i : Int,
    start_word : Int,
    end_pos : Int,
  ) -> Unit {
    if end_pos <= start_word || end_char_i < start_char_i {
      return
    }
    let mut start_lb = end_pos
    let mut ws_start_i : Int? = None
    let mut k = end_char_i
    while k >= start_char_i {
      if chars[k].is_whitespace() {
        start_lb = offs[k]
        ws_start_i = Some(k)
      } else {
        break
      }
      if k == 0 {
        break
      }
      k = k - 1
    }

    if start_word < start_lb {
      out.push((start_word, start_lb, false))
    }
    match ws_start_i {
      None => ()
      Some(i0) =>
        for i in i0..<(end_char_i + 1) {
          out.push((offs[i], offs[i] + lens[i], true))
        }
    }
  }

  let analyze = @moon_swash.analyze(chars.iter())
  analyze.set_break_strength(@moon_swash.WordBreakStrength::Normal)
  let out : Array[(Int, Int, Bool)] = []
  let mut start_char_i = 0
  let mut start_word = 0
  for i in 0..<chars.length() {
    match analyze.next() {
      None => break
      Some((_props, boundary)) =>
        match boundary {
          Line | Mandatory => {
            if boundary is Line &&
              i > 0 &&
              is_ligature_guard_pair(chars[i - 1], chars[i]) {
              continue
            }
            let end_pos = offs[i]
            emit_segment(
              out,
              chars,
              offs,
              lens,
              start_char_i,
              i - 1,
              start_word,
              end_pos,
            )
            start_char_i = i
            start_word = end_pos
          }
          _ => ()
        }
    }
  }

  emit_segment(
    out,
    chars,
    offs,
    lens,
    start_char_i,
    chars.length() - 1,
    start_word,
    s.length(),
  )
  out
}

///|
pub fn grapheme_indices_uax29(s : String) -> Array[(Int, Int)] {
  let chars = s.to_array()
  if chars.length() == 0 {
    return []
  }
  let offs : Array[Int] = []
  let lens : Array[Int] = []
  let breaks : Array[@moon_swash.ClusterBreak] = []
  let pict : Array[Bool] = []
  let mut pos = 0
  for ch in chars {
    offs.push(pos)
    let len = ch.utf16_len()
    lens.push(len)
    let info = @moon_swash.CharInfo::from_char(ch)
    breaks.push(info.cluster_break())
    pict.push(info.properties().is_extended_pictographic())
    pos = pos + len
  }
  fn is_control(b : @moon_swash.ClusterBreak) -> Bool {
    match b {
      CN | CR | LF => true
      _ => false
    }
  }

  fn is_hangul_l(b : @moon_swash.ClusterBreak) -> Bool {
    match b {
      L => true
      _ => false
    }
  }

  fn is_hangul_v(b : @moon_swash.ClusterBreak) -> Bool {
    match b {
      V | LV => true
      _ => false
    }
  }

  fn is_hangul_t(b : @moon_swash.ClusterBreak) -> Bool {
    match b {
      T | LVT => true
      _ => false
    }
  }

  fn should_break(
    i : Int,
    breaks : Array[@moon_swash.ClusterBreak],
    pict : Array[Bool],
  ) -> Bool {
    let prev = breaks[i - 1]
    let cur = breaks[i]

    // GB3
    if prev is CR && cur is LF {
      return false
    }
    // GB4/GB5
    if is_control(prev) || is_control(cur) {
      return true
    }
    // GB6
    if is_hangul_l(prev) {
      match cur {
        L | V | LV | LVT => return false
        _ => ()
      }
    }
    // GB7
    if is_hangul_v(prev) {
      match cur {
        V | T => return false
        _ => ()
      }
    }
    // GB8
    if is_hangul_t(prev) {
      if cur is T {
        return false
      }
    }

    // GB9/9a/9b
    match cur {
      EX | ZWJ | SM => return false
      _ => ()
    }
    if prev is PP {
      return false
    }

    // GB11 (simplified): Extended_Pictographic Extend* ZWJ x Extended_Pictographic
    if cur is @moon_swash.ClusterBreak::XX && pict[i] && prev is ZWJ {
      let mut k = i - 2
      while k >= 0 && breaks[k] is EX {
        k = k - 1
      }
      if k >= 0 && pict[k] {
        return false
      }
    }

    // GB12/13: RI pairs
    if prev is RI && cur is RI {
      let mut count = 0
      let mut k = i - 1
      while k >= 0 && breaks[k] is RI {
        count = count + 1
        if k == 0 {
          break
        }
        k = k - 1
      }
      if count % 2 == 1 {
        return false
      }
    }
    true
  }

  let ranges : Array[(Int, Int)] = []
  let mut start = 0
  for i in 1..<chars.length() {
    if should_break(i, breaks, pict) {
      ranges.push((start, offs[i]))
      start = offs[i]
    }
  }
  ranges.push((start, offs[offs.length() - 1] + lens[lens.length() - 1]))
  ranges
}
