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
/// Paragraph metadata for BiDi processing.
///
/// Indices are UTF-16 code-unit offsets in the source text.
pub struct ParagraphInfo {
  range_start : Int
  range_end : Int
  level : Int
}

///|
pub fn ParagraphInfo::range_start(self : ParagraphInfo) -> Int {
  self.range_start
}

///|
pub fn ParagraphInfo::range_end(self : ParagraphInfo) -> Int {
  self.range_end
}

///|
pub fn ParagraphInfo::level(self : ParagraphInfo) -> Int {
  self.level
}

///|
pub fn ParagraphInfo::is_rtl(self : ParagraphInfo) -> Bool {
  self.level % 2 != 0
}

///|
/// BiDi analysis result aligned with the reference flow:
/// paragraph split + class map + resolved levels.
///
/// `original_classes` and `levels` are indexed by UTF-16 code-unit offset.
pub struct BidiInfo {
  text : String
  original_classes : Array[@moon_swash.BidiClass]
  levels : Array[Int]
  paragraphs : Array[ParagraphInfo]

  fn new(text : String) -> BidiInfo
}

///|
fn bidi_utf16_len(ch : Char) -> Int {
  if ch.to_int() <= 0xFFFF {
    1
  } else {
    2
  }
}

///|
fn bidi_is_strong_rtl_class(b : @moon_swash.BidiClass) -> Bool {
  match b {
    R | AL | AN | RLE | RLO | RLI => true
    _ => false
  }
}

///|
fn bidi_is_strong_ltr_class(b : @moon_swash.BidiClass) -> Bool {
  match b {
    L | LRE | LRO | LRI => true
    _ => false
  }
}

///|
fn bidi_is_x9_ignored_class(b : @moon_swash.BidiClass) -> Bool {
  match b {
    RLE | LRE | RLO | LRO | PDF | BN => true
    _ => false
  }
}

///|
fn bidi_is_l1_ws_or_isolate_class(b : @moon_swash.BidiClass) -> Bool {
  match b {
    WS | FSI | LRI | RLI | PDI => true
    _ => false
  }
}

///|
fn bidi_is_segment_or_para_sep_class(b : @moon_swash.BidiClass) -> Bool {
  match b {
    B | S => true
    _ => false
  }
}

///|
fn bidi_push_repeated_class(
  classes : Array[@moon_swash.BidiClass],
  class : @moon_swash.BidiClass,
  n : Int,
) -> Unit {
  let mut i = 0
  while i < n {
    classes.push(class)
    i = i + 1
  }
}

///|
fn bidi_collect_classes_and_paragraphs(
  text : String,
  default_para_level : Int?,
) -> (Array[@moon_swash.BidiClass], Array[ParagraphInfo]) {
  let len = text.length()
  let classes : Array[@moon_swash.BidiClass] = []
  let paragraphs : Array[ParagraphInfo] = []

  let mut para_start = 0
  let mut para_first_strong_level : Int? = None

  for p in text.iter2() {
    let idx = p.0
    let ch = p.1
    let class = @moon_swash.CharInfo::from_char(ch).properties().bidi_class()
    let ch_len = bidi_utf16_len(ch)
    bidi_push_repeated_class(classes, class, ch_len)

    if para_first_strong_level is None {
      if bidi_is_strong_ltr_class(class) {
        para_first_strong_level = Some(0)
      } else if bidi_is_strong_rtl_class(class) {
        para_first_strong_level = Some(1)
      }
    }

    if class is B {
      let para_level = match default_para_level {
        Some(v) => v
        None => para_first_strong_level.unwrap_or(0)
      }
      paragraphs.push(ParagraphInfo::{
        range_start: para_start,
        range_end: idx + ch_len,
        level: para_level,
      })
      para_start = idx + ch_len
      para_first_strong_level = None
    }
  }

  if para_start < len {
    let para_level = match default_para_level {
      Some(v) => v
      None => para_first_strong_level.unwrap_or(0)
    }
    paragraphs.push(ParagraphInfo::{
      range_start: para_start,
      range_end: len,
      level: para_level,
    })
  }

  (classes, paragraphs)
}

///|
fn bidi_resolve_para_levels(
  classes : Array[@moon_swash.BidiClass],
  levels : Array[Int],
  para : ParagraphInfo,
) -> Unit {
  let start = para.range_start
  let end = para.range_end
  if start >= end {
    return
  }
  let base = para.level
  let para_len = end - start
  let strong_mask : Array[Bool] = Array::makei(para_len, _ => false)

  let mut i = start
  while i < end {
    let class = classes[i]
    let strong_rtl = bidi_is_strong_rtl_class(class)
    let strong_ltr = bidi_is_strong_ltr_class(class)
    let strong = strong_rtl || strong_ltr
    let lev = if strong_rtl {
      1
    } else if strong_ltr {
      if base % 2 != 0 {
        2
      } else {
        0
      }
    } else {
      base
    }
    levels.set(i, lev)
    strong_mask.set(i - start, strong)
    i = i + 1
  }

  let prev_strong_before : Array[Int] = Array::makei(para_len + 1, _ => -1)
  let mut prev_idx = -1
  for off in 0..<para_len {
    if strong_mask[off] {
      prev_idx = start + off
    }
    prev_strong_before.set(off + 1, prev_idx)
  }

  let next_strong_after : Array[Int] = Array::makei(para_len + 1, _ => -1)
  let mut next_idx = -1
  let mut off = para_len - 1
  while off >= 0 {
    if strong_mask[off] {
      next_idx = start + off
    }
    next_strong_after.set(off, next_idx)
    off = off - 1
  }

  let mut run_start = start
  while run_start < end {
    if strong_mask[run_start - start] {
      run_start = run_start + 1
      continue
    }
    let mut run_end = run_start + 1
    while run_end < end && !strong_mask[run_end - start] {
      run_end = run_end + 1
    }

    let rel_start = run_start - start
    let rel_end = run_end - start
    let prev_level = if prev_strong_before[rel_start] >= 0 {
      Some(levels[prev_strong_before[rel_start]])
    } else {
      None
    }
    let next_level = if next_strong_after[rel_end] >= 0 {
      Some(levels[next_strong_after[rel_end]])
    } else {
      None
    }
    let neutral_level = match (prev_level, next_level) {
      (Some(pl), Some(nl)) => if pl == nl { pl } else { base }
      (Some(pl), None) => pl
      (None, Some(nl)) => nl
      (None, None) => base
    }
    let mut j = run_start
    while j < run_end {
      levels.set(j, neutral_level)
      j = j + 1
    }
    run_start = run_end
  }
}

///|
/// Reference-aligned L1 whitespace reset step (same role as `adjust_levels`
/// in `cosmic-text/src/shape.rs`).
fn bidi_adjust_levels_l1_for_para(
  text : String,
  classes : Array[@moon_swash.BidiClass],
  para : ParagraphInfo,
  levels : Array[Int],
) -> Unit {
  if para.range_start >= para.range_end {
    return
  }
  let mut reset_from : Int? = Some(para.range_start)
  let mut reset_to : Int? = None

  for p in text.iter2() {
    let idx = p.0
    let ch = p.1
    if idx < para.range_start || idx >= para.range_end {
      continue
    }
    let class = classes[idx]
    let next = idx + bidi_utf16_len(ch)
    if bidi_is_x9_ignored_class(class) {
      ()
    } else if bidi_is_segment_or_para_sep_class(class) {
      reset_to = Some(next)
      if reset_from is None {
        reset_from = Some(idx)
      }
    } else if bidi_is_l1_ws_or_isolate_class(class) {
      if reset_from is None {
        reset_from = Some(idx)
      }
    } else {
      reset_from = None
    }

    match (reset_from, reset_to) {
      (Some(from), Some(to)) => {
        let mut j = from
        while j < to && j < levels.length() {
          levels.set(j, para.level)
          j = j + 1
        }
        reset_from = None
        reset_to = None
      }
      _ => ()
    }
  }

  if reset_from is Some(from) {
    let mut j = from
    while j < para.range_end && j < levels.length() {
      levels.set(j, para.level)
      j = j + 1
    }
  }
}

///|
pub fn BidiInfo::new(text : String) -> BidiInfo {
  BidiInfo::new_with_para_level(text, None)
}

///|
pub fn BidiInfo::new_with_para_level(
  text : String,
  default_para_level : Int?,
) -> BidiInfo {
  let (original_classes, paragraphs) = bidi_collect_classes_and_paragraphs(
    text, default_para_level,
  )
  let levels : Array[Int] = Array::makei(text.length(), _ => 0)
  for para in paragraphs {
    bidi_resolve_para_levels(original_classes, levels, para)
  }
  BidiInfo::{ text, original_classes, levels, paragraphs }
}

///|
pub fn BidiInfo::text(self : BidiInfo) -> String {
  self.text
}

///|
pub fn BidiInfo::paragraphs(self : BidiInfo) -> Array[ParagraphInfo] {
  self.paragraphs
}

///|
pub fn BidiInfo::levels(self : BidiInfo) -> Array[Int] {
  self.levels
}

///|
pub fn BidiInfo::rtl(self : BidiInfo) -> Bool {
  if self.paragraphs.length() == 0 {
    false
  } else {
    self.paragraphs[0].is_rtl()
  }
}

///|
pub fn BidiInfo::adjusted_levels(self : BidiInfo) -> Array[Int] {
  let adjusted : Array[Int] = Array::makei(self.levels.length(), i => {
    self.levels[i]
  })
  for para in self.paragraphs {
    bidi_adjust_levels_l1_for_para(
      self.text,
      self.original_classes,
      para,
      adjusted,
    )
  }
  adjusted
}
