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
/// BiDi analysis result aligned with `unicode-bidi` / `cosmic-text` flow.
///
/// `original_classes` and `levels` are indexed by UTF-16 code-unit offset.
pub struct BidiInfo {
  text : String
  original_classes : Array[@moon_swash.BidiClass]
  levels : Array[Int]
  paragraphs : Array[ParagraphInfo]
}

///|
priv struct BidiParagraphFlags {
  is_pure_ltr : Bool
  has_isolate_controls : Bool
}

///|
priv struct BidiLevelRun {
  start : Int
  end : Int
}

///|
priv struct BidiIsolatingRunSequence {
  runs : Array[BidiLevelRun]
  sos : @moon_swash.BidiClass
  eos : @moon_swash.BidiClass
}

///|
priv struct BidiBracketPair {
  start : Int
  end : Int
  start_run : Int
  end_run : Int
}

///|
priv struct BidiTextMeta {
  char_len_at : Array[Int]
  char_at_start : Array[Char]
}

///|
priv enum BidiOverrideStatus {
  Neutral
  RTL
  LTR
  Isolate
}

///|
priv struct BidiExplicitStatus {
  level : Int
  status : BidiOverrideStatus
}

///|
const BIDI_MAX_EXPLICIT_LEVEL : Int = 125

///|
const BIDI_MAX_IMPLICIT_LEVEL : Int = 126

///|
fn bidi_utf16_len(ch : Char) -> Int {
  if ch.to_int() <= 0xFFFF {
    1
  } else {
    2
  }
}

///|
fn bidi_clamp_para_level(level : Int) -> Int {
  if level < 0 {
    0
  } else if level > BIDI_MAX_EXPLICIT_LEVEL {
    BIDI_MAX_EXPLICIT_LEVEL
  } else {
    level
  }
}

///|
fn bidi_level_is_rtl(level : Int) -> Bool {
  level % 2 != 0
}

///|
fn bidi_level_new_explicit_next_ltr(level : Int) -> Int? {
  let mut next = level + 1
  if next % 2 != 0 {
    next = next + 1
  }
  if next <= BIDI_MAX_EXPLICIT_LEVEL {
    Some(next)
  } else {
    None
  }
}

///|
fn bidi_level_new_explicit_next_rtl(level : Int) -> Int? {
  let mut next = level + 1
  if next % 2 == 0 {
    next = next + 1
  }
  if next <= BIDI_MAX_EXPLICIT_LEVEL {
    Some(next)
  } else {
    None
  }
}

///|
fn bidi_level_raise(level : Int, amount : Int, max_value : Int) -> Int? {
  let next = level + amount
  if next <= max_value {
    Some(next)
  } else {
    None
  }
}

///|
fn bidi_level_to_class(level : Int) -> @moon_swash.BidiClass {
  if bidi_level_is_rtl(level) {
    R
  } else {
    L
  }
}

///|
fn bidi_max_int(a : Int, b : Int) -> Int {
  if a >= b {
    a
  } else {
    b
  }
}

///|
fn bidi_is_rtl_embedding_control(class : @moon_swash.BidiClass) -> Bool {
  match class {
    RLE | RLO | RLI => true
    _ => false
  }
}

///|
fn bidi_is_removed_by_x9(class : @moon_swash.BidiClass) -> Bool {
  match class {
    RLE | LRE | RLO | LRO | PDF | BN => true
    _ => false
  }
}

///|
fn bidi_is_ni_class(class : @moon_swash.BidiClass) -> Bool {
  match class {
    B | S | WS | ON | FSI | LRI | RLI | PDI => true
    _ => false
  }
}

///|
fn bidi_is_isolate_initiator(class : @moon_swash.BidiClass) -> Bool {
  match class {
    RLI | LRI | FSI => true
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
fn bidi_set_repeated_class(
  classes : Array[@moon_swash.BidiClass],
  start : Int,
  n : Int,
  class : @moon_swash.BidiClass,
) -> Unit {
  let mut i = 0
  while i < n {
    let p = start + i
    if p >= 0 && p < classes.length() {
      classes.set(p, class)
    }
    i = i + 1
  }
}

///|
fn bidi_build_text_meta(text : String) -> BidiTextMeta {
  let len = text.length()
  let char_len_at : Array[Int] = Array::makei(len, _ => 0)
  let char_at_start : Array[Char] = Array::makei(len, _ => '\u{0000}')
  for p in text.iter2() {
    let idx = p.0
    let ch = p.1
    char_len_at.set(idx, bidi_utf16_len(ch))
    char_at_start.set(idx, ch)
  }
  BidiTextMeta::{ char_len_at, char_at_start }
}

///|
fn bidi_char_len_at(meta : BidiTextMeta, index : Int) -> Int {
  if index < 0 || index >= meta.char_len_at.length() {
    0
  } else {
    meta.char_len_at[index]
  }
}

///|
fn bidi_find_prev_non_removed_index(
  classes : Array[@moon_swash.BidiClass],
  from : Int,
  min_index : Int,
) -> Int? {
  let mut i = from - 1
  while i >= min_index {
    if !bidi_is_removed_by_x9(classes[i]) {
      return Some(i)
    }
    i = i - 1
  }
  None
}

///|
fn bidi_find_next_non_removed_index(
  classes : Array[@moon_swash.BidiClass],
  from : Int,
  max_index : Int,
) -> Int? {
  let mut i = from
  while i < max_index {
    if !bidi_is_removed_by_x9(classes[i]) {
      return Some(i)
    }
    i = i + 1
  }
  None
}

///|
fn bidi_compute_initial_info(
  text : String,
  default_para_level : Int?,
) -> (
  Array[@moon_swash.BidiClass],
  Array[ParagraphInfo],
  Array[BidiParagraphFlags],
) {
  let len = text.length()
  let original_classes : Array[@moon_swash.BidiClass] = []
  let paragraphs : Array[ParagraphInfo] = []
  let paragraph_flags : Array[BidiParagraphFlags] = []
  let isolate_stack : Array[Int] = []

  let mut para_start = 0
  let mut para_level = match default_para_level {
    Some(v) => Some(bidi_clamp_para_level(v))
    None => None
  }
  let mut is_pure_ltr = true
  let mut has_isolate_controls = false

  for p in text.iter2() {
    let i = p.0
    let ch = p.1
    let class = @moon_swash.CharInfo::from_char(ch).properties().bidi_class()
    let char_len = bidi_utf16_len(ch)

    bidi_push_repeated_class(original_classes, class, char_len)

    match class {
      B => {
        let para_end = i + char_len
        paragraphs.push(ParagraphInfo::{
          range_start: para_start,
          range_end: para_end,
          level: para_level.unwrap_or(0),
        })
        paragraph_flags.push(BidiParagraphFlags::{
          is_pure_ltr,
          has_isolate_controls,
        })

        para_start = para_end
        para_level = match default_para_level {
          Some(v) => Some(bidi_clamp_para_level(v))
          None => None
        }
        is_pure_ltr = true
        has_isolate_controls = false
        isolate_stack.clear()
      }
      L | R | AL => {
        if !(class is L) {
          is_pure_ltr = false
        }

        if isolate_stack.length() > 0 {
          let isolate_start = isolate_stack[isolate_stack.length() - 1]
          if original_classes[isolate_start] is FSI {
            bidi_set_repeated_class(
              original_classes,
              isolate_start,
              1,
              if class is L {
                LRI
              } else {
                RLI
              },
            )
          }
        } else if para_level is None {
          para_level = Some(if class is L { 0 } else { 1 })
        }
      }
      AN | LRE | RLE | LRO | RLO => is_pure_ltr = false
      RLI | LRI | FSI => {
        is_pure_ltr = false
        has_isolate_controls = true
        isolate_stack.push(i)
      }
      PDI =>
        if isolate_stack.length() > 0 {
          isolate_stack.truncate(isolate_stack.length() - 1)
        }
      _ => ()
    }
  }

  if para_start < len {
    paragraphs.push(ParagraphInfo::{
      range_start: para_start,
      range_end: len,
      level: para_level.unwrap_or(0),
    })
    paragraph_flags.push(BidiParagraphFlags::{
      is_pure_ltr,
      has_isolate_controls,
    })
  }

  (original_classes, paragraphs, paragraph_flags)
}

///|
fn bidi_explicit_compute_for_para(
  text : String,
  meta : BidiTextMeta,
  para : ParagraphInfo,
  original_classes : Array[@moon_swash.BidiClass],
  levels : Array[Int],
  processing_classes : Array[@moon_swash.BidiClass],
  runs : Array[BidiLevelRun],
) -> Unit {
  let stack : Array[BidiExplicitStatus] = [
    BidiExplicitStatus::{
      level: para.level,
      status: BidiOverrideStatus::Neutral,
    },
  ]

  let mut overflow_isolate_count = 0
  let mut overflow_embedding_count = 0
  let mut valid_isolate_count = 0

  let mut current_run_level = para.level
  let mut current_run_start = para.range_start
  let mut has_any_char = false

  for p in text.iter2() {
    let i = p.0
    if i < para.range_start {
      continue
    }
    if i >= para.range_end {
      break
    }

    let char_len = bidi_char_len_at(meta, i)
    if char_len <= 0 {
      continue
    }

    let class = original_classes[i]
    let last = stack[stack.length() - 1]

    match class {
      RLE | LRE | RLO | LRO | RLI | LRI | FSI => {
        levels.set(i, last.level)

        let is_isolate = bidi_is_isolate_initiator(class)
        if is_isolate {
          match last.status {
            RTL => processing_classes.set(i, R)
            LTR => processing_classes.set(i, L)
            _ => ()
          }
        }

        let new_level_opt = if bidi_is_rtl_embedding_control(class) {
          bidi_level_new_explicit_next_rtl(last.level)
        } else {
          bidi_level_new_explicit_next_ltr(last.level)
        }

        if new_level_opt is Some(new_level) &&
          overflow_isolate_count == 0 &&
          overflow_embedding_count == 0 {
          stack.push(BidiExplicitStatus::{
            level: new_level,
            status: match class {
              RLO => RTL
              LRO => LTR
              RLI | LRI | FSI => Isolate
              _ => Neutral
            },
          })

          if is_isolate {
            valid_isolate_count = valid_isolate_count + 1
          } else {
            levels.set(i, new_level)
          }
        } else if is_isolate {
          overflow_isolate_count = overflow_isolate_count + 1
        } else if overflow_isolate_count == 0 {
          overflow_embedding_count = overflow_embedding_count + 1
        }

        if !is_isolate {
          processing_classes.set(i, BN)
        }
      }
      PDI => {
        if overflow_isolate_count > 0 {
          overflow_isolate_count = overflow_isolate_count - 1
        } else if valid_isolate_count > 0 {
          overflow_embedding_count = 0
          let mut done = false
          while stack.length() > 0 && !done {
            let top = stack[stack.length() - 1]
            stack.truncate(stack.length() - 1)
            if top.status is Isolate {
              done = true
            }
          }
          valid_isolate_count = valid_isolate_count - 1
        }

        let now = stack[stack.length() - 1]
        levels.set(i, now.level)

        match now.status {
          RTL => processing_classes.set(i, R)
          LTR => processing_classes.set(i, L)
          _ => ()
        }
      }
      PDF => {
        if overflow_isolate_count > 0 {
          ()
        } else if overflow_embedding_count > 0 {
          overflow_embedding_count = overflow_embedding_count - 1
        } else if stack.length() >= 2 {
          let now = stack[stack.length() - 1]
          if !(now.status is Isolate) {
            stack.truncate(stack.length() - 1)
          }
        }

        let now = stack[stack.length() - 1]
        levels.set(i, now.level)
        processing_classes.set(i, BN)
      }
      B => ()
      _ => {
        levels.set(i, last.level)
        if !(class is BN) {
          match last.status {
            RTL => processing_classes.set(i, R)
            LTR => processing_classes.set(i, L)
            _ => ()
          }
        }
      }
    }

    let mut j = 1
    while j < char_len {
      let p = i + j
      if p < para.range_end {
        levels.set(p, levels[i])
        processing_classes.set(p, processing_classes[i])
      }
      j = j + 1
    }

    if !has_any_char {
      current_run_level = levels[i]
      has_any_char = true
    } else if !bidi_is_removed_by_x9(class) && levels[i] != current_run_level {
      runs.push(BidiLevelRun::{ start: current_run_start, end: i })
      current_run_level = levels[i]
      current_run_start = i
    }
  }

  if has_any_char && para.range_end > current_run_start {
    runs.push(BidiLevelRun::{ start: current_run_start, end: para.range_end })
  }
}

///|
fn bidi_run_first_non_removed_level(
  run : BidiLevelRun,
  classes : Array[@moon_swash.BidiClass],
  levels : Array[Int],
) -> Int {
  let mut i = run.start
  while i < run.end {
    if !bidi_is_removed_by_x9(classes[i]) {
      return levels[i]
    }
    i = i + 1
  }
  levels[run.start]
}

///|
fn bidi_run_last_non_removed_level(
  run : BidiLevelRun,
  classes : Array[@moon_swash.BidiClass],
  levels : Array[Int],
) -> Int {
  let mut i = run.end - 1
  while i >= run.start {
    if !bidi_is_removed_by_x9(classes[i]) {
      return levels[i]
    }
    i = i - 1
  }
  levels[run.end - 1]
}

///|
fn bidi_sequence_find_forward_from(
  sequence : BidiIsolatingRunSequence,
  pos : Int,
  level_run_index : Int,
  pred : (Int) -> Bool,
) -> Int? {
  let mut ri = level_run_index
  while ri < sequence.runs.length() {
    let run = sequence.runs[ri]
    let mut i = if ri == level_run_index { pos } else { run.start }
    if i < run.start {
      i = run.start
    }
    while i < run.end {
      if pred(i) {
        return Some(i)
      }
      i = i + 1
    }
    ri = ri + 1
  }
  None
}

///|
fn bidi_sequence_find_backward_from(
  sequence : BidiIsolatingRunSequence,
  pos : Int,
  level_run_index : Int,
  pred : (Int) -> Bool,
) -> Int? {
  let mut ri = level_run_index
  while ri >= 0 {
    let run = sequence.runs[ri]
    let mut i = if ri == level_run_index { pos - 1 } else { run.end - 1 }
    if i >= run.end {
      i = run.end - 1
    }
    while i >= run.start {
      if pred(i) {
        return Some(i)
      }
      i = i - 1
    }
    if ri == 0 {
      break
    }
    ri = ri - 1
  }
  None
}

///|
fn bidi_sequence_set_contiguous_bn_backward(
  sequence : BidiIsolatingRunSequence,
  pos : Int,
  level_run_index : Int,
  processing_classes : Array[@moon_swash.BidiClass],
  class_to_set : @moon_swash.BidiClass,
) -> Unit {
  let mut ri = level_run_index
  while ri >= 0 {
    let run = sequence.runs[ri]
    let mut i = if ri == level_run_index { pos - 1 } else { run.end - 1 }
    if i >= run.end {
      i = run.end - 1
    }
    while i >= run.start {
      if !(processing_classes[i] is BN) {
        return
      }
      processing_classes.set(i, class_to_set)
      i = i - 1
    }
    if ri == 0 {
      return
    }
    ri = ri - 1
  }
}

///|
fn bidi_sequence_set_contiguous_bn_forward(
  sequence : BidiIsolatingRunSequence,
  pos : Int,
  level_run_index : Int,
  processing_classes : Array[@moon_swash.BidiClass],
  class_to_set : @moon_swash.BidiClass,
) -> Unit {
  let mut ri = level_run_index
  while ri < sequence.runs.length() {
    let run = sequence.runs[ri]
    let mut i = if ri == level_run_index { pos } else { run.start }
    if i < run.start {
      i = run.start
    }
    while i < run.end {
      if !(processing_classes[i] is BN) {
        return
      }
      processing_classes.set(i, class_to_set)
      i = i + 1
    }
    ri = ri + 1
  }
}

///|
fn bidi_sequence_set_nsm_or_bn_forward(
  sequence : BidiIsolatingRunSequence,
  pos : Int,
  level_run_index : Int,
  original_classes : Array[@moon_swash.BidiClass],
  processing_classes : Array[@moon_swash.BidiClass],
  class_to_set : @moon_swash.BidiClass,
) -> Unit {
  let mut ri = level_run_index
  while ri < sequence.runs.length() {
    let run = sequence.runs[ri]
    let mut i = if ri == level_run_index { pos } else { run.start }
    if i < run.start {
      i = run.start
    }
    while i < run.end {
      if original_classes[i] is NSM || processing_classes[i] is BN {
        processing_classes.set(i, class_to_set)
      } else {
        return
      }
      i = i + 1
    }
    ri = ri + 1
  }
}

///|
fn bidi_prepare_isolating_run_sequences_for_para(
  para : ParagraphInfo,
  original_classes : Array[@moon_swash.BidiClass],
  levels : Array[Int],
  runs : Array[BidiLevelRun],
  has_isolate_controls : Bool,
  out_sequences : Array[BidiIsolatingRunSequence],
) -> Unit {
  if runs.length() == 0 {
    return
  }

  if !has_isolate_controls {
    let non_removed : Array[Int] = []
    let mut i = para.range_start
    while i < para.range_end {
      if !bidi_is_removed_by_x9(original_classes[i]) {
        non_removed.push(i)
      }
      i = i + 1
    }
    let mut pred_cursor = 0
    let mut succ_cursor = 0
    for run in runs {
      let seq_level = bidi_run_first_non_removed_level(
        run, original_classes, levels,
      )
      let end_level = bidi_run_last_non_removed_level(
        run, original_classes, levels,
      )
      while pred_cursor < non_removed.length() &&
            non_removed[pred_cursor] < run.start {
        pred_cursor = pred_cursor + 1
      }
      let pred_level = if pred_cursor == 0 {
        para.level
      } else {
        levels[non_removed[pred_cursor - 1]]
      }

      while succ_cursor < non_removed.length() &&
            non_removed[succ_cursor] < run.end {
        succ_cursor = succ_cursor + 1
      }
      let succ_level = if succ_cursor < non_removed.length() {
        levels[non_removed[succ_cursor]]
      } else {
        para.level
      }

      out_sequences.push(BidiIsolatingRunSequence::{
        runs: [run],
        sos: bidi_level_to_class(bidi_max_int(seq_level, pred_level)),
        eos: bidi_level_to_class(bidi_max_int(end_level, succ_level)),
      })
    }
    return
  }

  let sequence_stack : Array[Array[BidiLevelRun]] = [[]]
  let sequences : Array[Array[BidiLevelRun]] = []

  for run in runs {
    let start_class = original_classes[run.start]
    let mut end_class = start_class
    let mut i = run.end - 1
    while i >= run.start {
      let class = original_classes[i]
      if !bidi_is_removed_by_x9(class) {
        end_class = class
        break
      }
      i = i - 1
    }

    let mut seq : Array[BidiLevelRun] = []
    if start_class is PDI && sequence_stack.length() > 1 {
      let last_i = sequence_stack.length() - 1
      seq = sequence_stack[last_i]
      sequence_stack.truncate(last_i)
    }

    seq.push(run)

    if bidi_is_isolate_initiator(end_class) {
      sequence_stack.push(seq)
    } else {
      sequences.push(seq)
    }
  }

  let mut si = sequence_stack.length()
  while si > 0 {
    si = si - 1
    let seq = sequence_stack[si]
    if seq.length() != 0 {
      sequences.push(seq)
    }
  }

  for seq in sequences {
    let start_of_seq = seq[0].start
    let runs_len = seq.length()
    let end_of_seq = seq[runs_len - 1].end

    let result = BidiIsolatingRunSequence::{ runs: seq, sos: L, eos: L }

    let seq_level = match
      bidi_sequence_find_forward_from(result, start_of_seq, 0, fn(i) {
        !bidi_is_removed_by_x9(original_classes[i])
      }) {
      Some(idx) => levels[idx]
      None => levels[start_of_seq]
    }

    let end_level = match
      bidi_sequence_find_backward_from(result, end_of_seq, runs_len - 1, fn(i) {
        !bidi_is_removed_by_x9(original_classes[i])
      }) {
      Some(idx) => levels[idx]
      None => levels[end_of_seq - 1]
    }

    let pred_level = match
      bidi_find_prev_non_removed_index(
        original_classes,
        start_of_seq,
        para.range_start,
      ) {
      Some(idx) => levels[idx]
      None => para.level
    }

    let last_non_removed_class = match
      bidi_find_prev_non_removed_index(
        original_classes,
        end_of_seq,
        para.range_start,
      ) {
      Some(idx) => original_classes[idx]
      None => BN
    }

    let succ_level = if bidi_is_isolate_initiator(last_non_removed_class) {
      para.level
    } else {
      match
        bidi_find_next_non_removed_index(
          original_classes,
          end_of_seq,
          para.range_end,
        ) {
        Some(idx) => levels[idx]
        None => para.level
      }
    }

    out_sequences.push(BidiIsolatingRunSequence::{
      runs: result.runs,
      sos: bidi_level_to_class(bidi_max_int(seq_level, pred_level)),
      eos: bidi_level_to_class(bidi_max_int(end_level, succ_level)),
    })
  }
}

///|
fn bidi_resolve_weak_for_sequence(
  meta : BidiTextMeta,
  sequence : BidiIsolatingRunSequence,
  processing_classes : Array[@moon_swash.BidiClass],
) -> Unit {
  let mut prev_class_before_w4 = sequence.sos
  let mut prev_class_before_w5 = sequence.sos
  let mut prev_class_before_w1 = sequence.sos
  let mut last_strong_is_al = false

  let et_run_indices : Array[Int] = []
  let bn_run_indices : Array[Int] = []

  for run_index in 0..<sequence.runs.length() {
    let level_run = sequence.runs[run_index]
    let mut i = level_run.start
    while i < level_run.end {
      if processing_classes[i] is BN {
        bn_run_indices.push(i)
        i = i + 1
        continue
      }

      let mut w2_processing_class = processing_classes[i]

      if processing_classes[i] is NSM {
        processing_classes.set(
          i,
          match prev_class_before_w1 {
            RLI | LRI | FSI | PDI => ON
            _ => prev_class_before_w1
          },
        )
        w2_processing_class = processing_classes[i]
      }

      prev_class_before_w1 = processing_classes[i]

      match processing_classes[i] {
        EN => if last_strong_is_al { processing_classes.set(i, AN) }
        AL => processing_classes.set(i, R)
        _ => ()
      }

      match w2_processing_class {
        L | R => last_strong_is_al = false
        AL => last_strong_is_al = true
        _ => ()
      }

      let class_before_w456 = processing_classes[i]

      match processing_classes[i] {
        EN => {
          for j in et_run_indices {
            processing_classes.set(j, EN)
          }
          et_run_indices.clear()
        }
        ES | CS => {
          let char_len = bidi_char_len_at(meta, i)
          if char_len > 0 {
            let mut next_class = match
              bidi_sequence_find_forward_from(
                sequence,
                i + char_len,
                run_index,
                fn(j) { !bidi_is_removed_by_x9(processing_classes[j]) },
              ) {
              Some(idx) => processing_classes[idx]
              None => sequence.eos
            }

            if next_class is EN && last_strong_is_al {
              next_class = AN
            }

            let new_class : @moon_swash.BidiClass = if prev_class_before_w4
              is EN &&
              (processing_classes[i] is ES || processing_classes[i] is CS) &&
              next_class is EN {
              EN
            } else if prev_class_before_w4 is AN &&
              processing_classes[i] is CS &&
              next_class is AN {
              AN
            } else {
              ON
            }
            processing_classes.set(i, new_class)

            if new_class is ON {
              bidi_sequence_set_contiguous_bn_backward(
                sequence,
                i,
                run_index,
                processing_classes,
                ON,
              )
              bidi_sequence_set_contiguous_bn_forward(
                sequence,
                i + char_len,
                run_index,
                processing_classes,
                ON,
              )
            }
          } else if i > 0 {
            processing_classes.set(i, processing_classes[i - 1])
          }
        }
        ET =>
          if prev_class_before_w5 is EN {
            processing_classes.set(i, EN)
          } else {
            for j in bn_run_indices {
              et_run_indices.push(j)
            }
            et_run_indices.push(i)
          }
        _ => ()
      }

      bn_run_indices.clear()
      prev_class_before_w5 = processing_classes[i]

      if !(prev_class_before_w5 is ET) {
        for j in et_run_indices {
          processing_classes.set(j, ON)
        }
        et_run_indices.clear()
      }

      prev_class_before_w4 = class_before_w456
      i = i + 1
    }
  }

  for j in et_run_indices {
    processing_classes.set(j, ON)
  }
  et_run_indices.clear()

  let mut last_strong_is_l = sequence.sos is L
  for run in sequence.runs {
    let mut i = run.start
    while i < run.end {
      match processing_classes[i] {
        EN => if last_strong_is_l { processing_classes.set(i, L) }
        L => last_strong_is_l = true
        R | AL => last_strong_is_l = false
        _ => ()
      }
      i = i + 1
    }
  }
}

///|
fn bidi_sort_bracket_pairs_by_start(pairs : Array[BidiBracketPair]) -> Unit {
  let mut i = 1
  while i < pairs.length() {
    let key = pairs[i]
    let mut j = i - 1
    while pairs[j].start > key.start {
      pairs.set(j + 1, pairs[j])
      if j == 0 {
        break
      }
      j = j - 1
    }
    if pairs[j].start > key.start {
      pairs.set(j, key)
    } else {
      pairs.set(j + 1, key)
    }
    i = i + 1
  }
}

///|
fn bidi_identify_bracket_pairs(
  meta : BidiTextMeta,
  sequence : BidiIsolatingRunSequence,
  classes : Array[@moon_swash.BidiClass],
  out_pairs : Array[BidiBracketPair],
) -> Unit {
  let stack : Array[(Char, Int, Int)] = []
  for run_index in 0..<sequence.runs.length() {
    let level_run = sequence.runs[run_index]
    let mut i = level_run.start
    while i < level_run.end {
      if !(classes[i] is ON) || bidi_char_len_at(meta, i) <= 0 {
        i = i + 1
        continue
      }
      let ch = meta.char_at_start[i]
      match @moon_swash.Codepoint::bracket_type(ch) {
        Open(_) => {
          if stack.length() >= 63 {
            break
          }
          stack.push((ch, i, run_index))
        }
        Close(opening) =>
          if stack.length() == 0 {
            ()
          } else {
            let mut si = stack.length()
            let mut matched = false
            while si > 0 && !matched {
              si = si - 1
              let item = stack[si]
              if item.0 == opening {
                out_pairs.push(BidiBracketPair::{
                  start: item.1,
                  end: i,
                  start_run: item.2,
                  end_run: run_index,
                })
                stack.truncate(si)
                matched = true
              }
            }
          }
        None => ()
      }
      i = i + 1
    }
  }

  bidi_sort_bracket_pairs_by_start(out_pairs)
}

///|
fn bidi_resolve_neutral_run_class(
  prev_class : @moon_swash.BidiClass,
  next_class : @moon_swash.BidiClass,
  embedding_class : @moon_swash.BidiClass,
) -> @moon_swash.BidiClass {
  match (prev_class, next_class) {
    (L, L) => L
    (R, R)
    | (R, AN)
    | (R, EN)
    | (AN, R)
    | (AN, AN)
    | (AN, EN)
    | (EN, R)
    | (EN, AN)
    | (EN, EN) => R
    _ => embedding_class
  }
}

///|
fn bidi_resolve_neutral_for_sequence(
  meta : BidiTextMeta,
  sequence : BidiIsolatingRunSequence,
  levels : Array[Int],
  original_classes : Array[@moon_swash.BidiClass],
  processing_classes : Array[@moon_swash.BidiClass],
) -> Unit {
  let embedding_class = bidi_level_to_class(levels[sequence.runs[0].start])
  let opposite_embedding_class : @moon_swash.BidiClass = if embedding_class is L {
    R
  } else {
    L
  }

  let bracket_pairs : Array[BidiBracketPair] = []
  bidi_identify_bracket_pairs(meta, sequence, processing_classes, bracket_pairs)

  for pair in bracket_pairs {
    let mut found_embedding = false
    let mut found_opposite = false
    let mut class_to_set : @moon_swash.BidiClass? = None

    let start_char_len = {
      let l = bidi_char_len_at(meta, pair.start)
      if l > 0 {
        l
      } else {
        1
      }
    }
    let end_char_len = {
      let l = bidi_char_len_at(meta, pair.end)
      if l > 0 {
        l
      } else {
        1
      }
    }

    let enclosed_opt = bidi_sequence_find_forward_from(
      sequence,
      pair.start + start_char_len,
      pair.start_run,
      fn(idx) {
        if idx >= pair.end {
          false
        } else {
          let class = processing_classes[idx]
          if (embedding_class is L && class is L) ||
            (embedding_class is R && class is R) {
            found_embedding = true
          } else if (opposite_embedding_class is L && class is L) ||
            (opposite_embedding_class is R && class is R) {
            found_opposite = true
          } else if class is EN || class is AN {
            if embedding_class is L {
              found_opposite = true
            } else {
              found_embedding = true
            }
          }
          found_embedding
        }
      },
    )
    match enclosed_opt {
      Some(_) => ()
      None => ()
    }

    if found_embedding {
      class_to_set = Some(embedding_class)
    } else if found_opposite {
      let mut previous_strong = match
        bidi_sequence_find_backward_from(sequence, pair.start, pair.start_run, fn(
          idx,
        ) {
          let class = processing_classes[idx]
          class is L || class is R || class is EN || class is AN
        }) {
        Some(idx) => processing_classes[idx]
        None => sequence.sos
      }
      if previous_strong is EN || previous_strong is AN {
        previous_strong = R
      }
      class_to_set = Some(previous_strong)
    }

    if class_to_set is Some(cset) {
      let mut i = pair.start
      while i < pair.start + start_char_len {
        processing_classes.set(i, cset)
        i = i + 1
      }
      let mut j = pair.end
      while j < pair.end + end_char_len {
        processing_classes.set(j, cset)
        j = j + 1
      }

      bidi_sequence_set_contiguous_bn_backward(
        sequence,
        pair.start,
        pair.start_run,
        processing_classes,
        cset,
      )

      bidi_sequence_set_nsm_or_bn_forward(
        sequence,
        pair.start + start_char_len,
        pair.start_run,
        original_classes,
        processing_classes,
        cset,
      )
      bidi_sequence_set_nsm_or_bn_forward(
        sequence,
        pair.end + end_char_len,
        pair.end_run,
        original_classes,
        processing_classes,
        cset,
      )
    }
  }

  let mut prev_class = sequence.sos
  let ni_run : Array[Int] = []
  let runs = sequence.runs
  if runs.length() == 0 {
    return
  }
  let mut run_i = 0
  let mut i = runs[0].start
  while run_i < runs.length() {
    let run = runs[run_i]
    if i >= run.end {
      run_i = run_i + 1
      if run_i < runs.length() {
        i = runs[run_i].start
      }
      continue
    }

    let class_i = processing_classes[i]
    if bidi_is_ni_class(class_i) || class_i is BN {
      ni_run.push(i)
      let mut next_class = sequence.eos
      let mut found_next_strong = false
      let mut scan_run_i = run_i
      let mut scan_i = i + 1
      while scan_run_i < runs.length() {
        let scan_run = runs[scan_run_i]
        if scan_i < scan_run.start {
          scan_i = scan_run.start
        }
        while scan_i < scan_run.end {
          let cls = processing_classes[scan_i]
          if bidi_is_ni_class(cls) || cls is BN {
            ni_run.push(scan_i)
            scan_i = scan_i + 1
          } else {
            next_class = cls
            found_next_strong = true
            break
          }
        }
        if found_next_strong {
          break
        }
        scan_run_i = scan_run_i + 1
        if scan_run_i < runs.length() {
          scan_i = runs[scan_run_i].start
        }
      }

      let new_class = bidi_resolve_neutral_run_class(
        prev_class, next_class, embedding_class,
      )
      for j in ni_run {
        processing_classes.set(j, new_class)
      }
      ni_run.clear()
      prev_class = new_class

      if found_next_strong {
        run_i = scan_run_i
        i = scan_i
      } else {
        break
      }
    } else {
      prev_class = class_i
      i = i + 1
    }
  }
}

///|
fn bidi_resolve_levels_for_para(
  para : ParagraphInfo,
  processing_classes : Array[@moon_swash.BidiClass],
  levels : Array[Int],
) -> Int {
  let mut max_level = para.level
  let mut i = para.range_start
  while i < para.range_end {
    let mut level = levels[i]
    let is_rtl = bidi_level_is_rtl(level)

    match (is_rtl, processing_classes[i]) {
      (false, AN) | (false, EN) =>
        match bidi_level_raise(level, 2, BIDI_MAX_IMPLICIT_LEVEL) {
          Some(v) => level = v
          None => ()
        }
      (false, R) | (true, L) | (true, EN) | (true, AN) =>
        match bidi_level_raise(level, 1, BIDI_MAX_IMPLICIT_LEVEL) {
          Some(v) => level = v
          None => ()
        }
      _ => ()
    }

    levels.set(i, level)
    max_level = bidi_max_int(max_level, level)
    i = i + 1
  }

  max_level
}

///|
fn bidi_assign_levels_to_removed_chars_for_para(
  para : ParagraphInfo,
  classes : Array[@moon_swash.BidiClass],
  levels : Array[Int],
) -> Unit {
  let mut i = para.range_start
  while i < para.range_end {
    if bidi_is_removed_by_x9(classes[i]) {
      levels.set(
        i,
        if i > para.range_start {
          levels[i - 1]
        } else {
          para.level
        },
      )
    }
    i = i + 1
  }
}

///|
fn bidi_compute_info_for_para(
  text : String,
  meta : BidiTextMeta,
  para : ParagraphInfo,
  is_pure_ltr : Bool,
  has_isolate_controls : Bool,
  original_classes : Array[@moon_swash.BidiClass],
  processing_classes : Array[@moon_swash.BidiClass],
  levels : Array[Int],
) -> Unit {
  let mut i = para.range_start
  while i < para.range_end {
    levels.set(i, para.level)
    i = i + 1
  }

  if para.level == 0 && is_pure_ltr {
    return
  }

  let runs : Array[BidiLevelRun] = []
  bidi_explicit_compute_for_para(
    text, meta, para, original_classes, levels, processing_classes, runs,
  )

  let sequences : Array[BidiIsolatingRunSequence] = []
  bidi_prepare_isolating_run_sequences_for_para(
    para, original_classes, levels, runs, has_isolate_controls, sequences,
  )

  for sequence in sequences {
    bidi_resolve_weak_for_sequence(meta, sequence, processing_classes)
    bidi_resolve_neutral_for_sequence(
      meta, sequence, levels, original_classes, processing_classes,
    )
  }

  bidi_resolve_levels_for_para(para, processing_classes, levels) |> ignore
  bidi_assign_levels_to_removed_chars_for_para(para, original_classes, levels)
}

///|
/// Reference-aligned L1 whitespace reset step.
fn bidi_adjust_levels_l1_for_para(
  text : String,
  meta : BidiTextMeta,
  classes : Array[@moon_swash.BidiClass],
  para : ParagraphInfo,
  levels : Array[Int],
) -> Unit {
  if para.range_start >= para.range_end {
    return
  }

  let mut reset_from : Int? = Some(para.range_start)
  let mut reset_to : Int? = None
  let mut prev_level = para.level

  for p in text.iter2() {
    let i = p.0
    if i < para.range_start {
      continue
    }
    if i >= para.range_end {
      break
    }

    let char_len = bidi_char_len_at(meta, i)
    if char_len <= 0 {
      continue
    }

    let class = classes[i]
    match class {
      B | S => {
        reset_to = Some(i + char_len)
        if reset_from is None {
          reset_from = Some(i)
        }
      }
      WS | FSI | LRI | RLI | PDI =>
        if reset_from is None {
          reset_from = Some(i)
        }
      RLE | LRE | RLO | LRO | PDF | BN => {
        if reset_from is None {
          reset_from = Some(i)
        }
        let mut j = i
        while j < i + char_len && j < levels.length() {
          levels.set(j, prev_level)
          j = j + 1
        }
      }
      _ => reset_from = None
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

    prev_level = levels[i]
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
  let normalized_default = match default_para_level {
    Some(v) => Some(bidi_clamp_para_level(v))
    None => None
  }

  let (original_classes, paragraphs, paragraph_flags) = bidi_compute_initial_info(
    text, normalized_default,
  )

  let meta = bidi_build_text_meta(text)
  let levels : Array[Int] = Array::makei(text.length(), _ => 0)
  let processing_classes : Array[@moon_swash.BidiClass] = Array::makei(
    original_classes.length(),
    i => original_classes[i],
  )

  for i in 0..<paragraphs.length() {
    let para = paragraphs[i]
    let flags = paragraph_flags[i]
    bidi_compute_info_for_para(
      text,
      meta,
      para,
      flags.is_pure_ltr,
      flags.has_isolate_controls,
      original_classes,
      processing_classes,
      levels,
    )
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
  let meta = bidi_build_text_meta(self.text)
  for para in self.paragraphs {
    bidi_adjust_levels_l1_for_para(
      self.text,
      meta,
      self.original_classes,
      para,
      adjusted,
    )
  }
  adjusted
}
