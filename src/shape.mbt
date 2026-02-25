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
/// Minimal shaping port scaffold from `cosmic-text/src/shape.rs`.
///
/// This MVP produces 1 glyph per UTF-16 code unit and does not perform script runs,
/// harfbuzz shaping, BiDi, or font fallback.
pub(all) enum Shaping {
  Basic
  Advanced
}

///|
pub struct ShapeGlyph {
  start : Int
  end : Int
  x_advance : Float
  y_advance : Float
  x_offset : Float
  y_offset : Float
  font_id : Int
  font_weight : Int
  glyph_id : Int
  metadata : Int
  /// BiDi embedding level (LTR if divisible by 2).
  level : Int
  /// Optional Metrics override (font size / line height) for this glyph's span.
  metrics_opt : Metrics?
}

///|
pub fn ShapeGlyph::new(
  start : Int,
  end : Int,
  x_advance : Float,
  y_advance : Float,
  x_offset : Float,
  y_offset : Float,
  font_id : Int,
  glyph_id : Int,
  metadata : Int,
) -> ShapeGlyph {
  ShapeGlyph::{
    start,
    end,
    x_advance,
    y_advance,
    x_offset,
    y_offset,
    font_id,
    font_weight: 400,
    glyph_id,
    metadata,
    level: 0,
    metrics_opt: None,
  }
}

///|
pub struct ShapeLine {
  rtl : Bool
  glyphs : Array[ShapeGlyph]
}

///|
pub fn ShapeLine::new(rtl : Bool, glyphs : Array[ShapeGlyph]) -> ShapeLine {
  ShapeLine::{ rtl, glyphs }
}

///|
pub fn ShapeLine::empty() -> ShapeLine {
  ShapeLine::{ rtl: false, glyphs: [] }
}

///|
fn is_tab(code : Int) -> Bool {
  code == 9
}

///|
fn utf16_len_of_char(ch : Char) -> Int {
  // UTF-16: codepoints outside BMP take 2 code units.
  if ch.to_int() <= 0xFFFF {
    1
  } else {
    2
  }
}

///|
fn bidi_is_strong_rtl(b : @moon_swash.BidiClass) -> Bool {
  match b {
    R | AL | AN | RLE | RLO | RLI => true
    _ => false
  }
}

///|
fn bidi_is_strong_ltr(b : @moon_swash.BidiClass) -> Bool {
  match b {
    L | LRE | LRO | LRI => true
    _ => false
  }
}

///|
fn detect_base_rtl(text : String) -> Bool {
  // Heuristic: use the first strong directional character.
  for ch in text {
    let props = @moon_swash.CharInfo::from_char(ch).properties()
    let bidi = props.bidi_class()
    if bidi_is_strong_rtl(bidi) {
      return true
    }
    if bidi_is_strong_ltr(bidi) {
      return false
    }
  }
  false
}

///|
fn compute_bidi_levels(text : String, rtl : Bool) -> Array[Int] {
  let base = if rtl { 1 } else { 0 }
  let levels : Array[Int] = Array::makei(text.length(), _ => base)
  let strong_mask : Array[Bool] = Array::makei(text.length(), _ => false)
  let segments : Array[(Int, Int, Bool)] = []
  for p in text.iter2() {
    let idx = p.0
    let ch = p.1
    let props = @moon_swash.CharInfo::from_char(ch).properties()
    let bidi = props.bidi_class()
    let strong_rtl = bidi_is_strong_rtl(bidi)
    let strong_ltr = bidi_is_strong_ltr(bidi)
    let strong = strong_rtl || strong_ltr
    let lev = if strong_rtl {
      1
    } else if strong_ltr {
      if rtl {
        2
      } else {
        0
      }
    } else {
      base
    }
    let end = idx + ch.utf16_len()
    let mut i = idx
    while i < end && i < levels.length() {
      levels.set(i, lev)
      strong_mask.set(i, strong)
      i = i + 1
    }
    segments.push((idx, end, strong))
  }

  // Resolve neutral spans (e.g. spaces) toward surrounding strong runs.
  for seg in segments {
    let start = seg.0
    let end = seg.1
    if seg.2 {
      continue
    }
    let mut prev_level : Int? = None
    let mut j = start - 1
    while j >= 0 {
      if strong_mask[j] {
        prev_level = Some(levels[j])
        break
      }
      j = j - 1
    }
    let mut next_level : Int? = None
    let mut k = end
    while k < levels.length() {
      if strong_mask[k] {
        next_level = Some(levels[k])
        break
      }
      k = k + 1
    }
    let neutral_level = match (prev_level, next_level) {
      (Some(pl), Some(nl)) => if pl == nl { pl } else { base }
      (Some(pl), None) => pl
      (None, Some(nl)) => nl
      (None, None) => base
    }
    let mut i = start
    while i < end && i < levels.length() {
      levels.set(i, neutral_level)
      i = i + 1
    }
  }
  levels
}

///|
fn script_eq(a : @moon_swash.Script, b : @moon_swash.Script) -> Bool {
  a.to_opentype() == b.to_opentype()
}

///|
fn shape_script_needs_fallback_stage(script : @moon_swash.Script) -> Bool {
  match script {
    @moon_swash.Script::Common
    | @moon_swash.Script::Inherited
    | @moon_swash.Script::Latin
    | @moon_swash.Script::Unknown => false
    _ => true
  }
}

///|
fn shape_script_in_array(
  scripts : Array[@moon_swash.Script],
  script : @moon_swash.Script,
) -> Bool {
  for s in scripts {
    if script_eq(s, script) {
      return true
    }
  }
  false
}

///|
fn collect_run_fallback_scripts(
  run_tokens : Array[@moon_swash.Token],
) -> Array[@moon_swash.Script] {
  let scripts : Array[@moon_swash.Script] = []
  for tok in run_tokens {
    let script = @moon_swash.CharInfo::from_char(tok.ch()).properties().script()
    if shape_script_needs_fallback_stage(script) &&
      !shape_script_in_array(scripts, script) {
      scripts.push(script)
    }
  }
  scripts
}

///|
fn shape_primary_script_seed(
  script : @moon_swash.Script,
) -> (@moon_swash.Script, Bool) {
  match script {
    Common | Inherited | Unknown => (@moon_swash.Script::Latin, true)
    _ => (script, false)
  }
}

///|
fn shape_levels_require_new_run(prev_level : Int, new_level : Int) -> Bool {
  prev_level != new_level
}

///|
fn entry_supports_any_run_script(
  entry : FontEntry,
  scripts : Array[@moon_swash.Script],
) -> Bool {
  if scripts.length() == 0 {
    return false
  }
  let systems = entry.font().writing_systems()
  for ws in systems.iter() {
    match ws.script() {
      None => ()
      Some(s) => if shape_script_in_array(scripts, s) { return true }
    }
  }
  false
}

///|
fn source_start_index(source : @moon_swash.SourceRange) -> Int {
  source.start().reinterpret_as_int()
}

///|
fn source_end_index(source : @moon_swash.SourceRange) -> Int {
  source.end().reinterpret_as_int()
}

///|
fn attrs_for_position(
  attrs_list : AttrsList,
  pos : Int,
  text_len : Int,
) -> Attrs {
  if text_len <= 0 {
    attrs_list.defaults()
  } else {
    let i = if pos < 0 {
      0
    } else if pos >= text_len {
      text_len - 1
    } else {
      pos
    }
    attrs_list.get_span(i)
  }
}

///|
fn clamp_range_to_source(
  start0 : Int,
  end0 : Int,
  source_start : Int,
  source_end : Int,
) -> (Int, Int) {
  let start1 = if start0 < source_start {
    source_start
  } else if start0 > source_end {
    source_end
  } else {
    start0
  }
  let end1 = if end0 < start1 {
    start1
  } else if end0 > source_end {
    source_end
  } else {
    end0
  }
  (start1, end1)
}

///|
fn clamp_text_index(v : Int, text_len : Int) -> Int {
  if v < 0 {
    0
  } else if v > text_len {
    text_len
  } else {
    v
  }
}

///|
fn slice_text_utf16(text : String, start : Int, end : Int) -> String {
  let text_len = text.length()
  let s = clamp_text_index(start, text_len)
  let e = clamp_text_index(end, text_len)
  let to = if e < s { s } else { e }
  let sb = StringBuilder::new(size_hint=(to - s) * 2)
  sb.write_view(text[:].view(start_offset=s, end_offset=to))
  sb.to_string()
}

///|
fn attrs_list_for_utf16_range(
  attrs_list : AttrsList,
  start : Int,
  end : Int,
  text_len : Int,
) -> AttrsList {
  let s = clamp_text_index(start, text_len)
  let e0 = clamp_text_index(end, text_len)
  let e = if e0 < s { s } else { e0 }
  let (_, right) = attrs_list.split_off(s)
  let (mid, _) = right.split_off(e - s)
  mid
}

///|
fn build_cluster_starts(
  source : @moon_swash.SourceRange,
  components : ArrayView[@moon_swash.SourceRange],
  glyph_count : Int,
  rtl : Bool,
) -> Array[Int] {
  let starts : Array[Int] = []
  if glyph_count <= 0 {
    return starts
  }
  if components.length() == 0 {
    let source_start = source_start_index(source)
    for _ in 0..<glyph_count {
      starts.push(source_start)
    }
    return starts
  }

  let component_starts : Array[Int] = []
  for comp in components {
    component_starts.push(source_start_index(comp))
  }
  let m = component_starts.length()
  for i in 0..<glyph_count {
    let bucket = if glyph_count <= m {
      i * m / glyph_count
    } else if i < m {
      i
    } else {
      m - 1
    }
    let k = if rtl { m - 1 - bucket } else { bucket }
    starts.push(component_starts[k])
  }
  starts
}

///|
fn build_cluster_ends(
  starts : Array[Int],
  source_end : Int,
  rtl : Bool,
) -> Array[Int] {
  let n = starts.length()
  let ends : Array[Int] = []
  for _ in 0..<n {
    ends.push(source_end)
  }
  if n < 2 {
    return ends
  }
  if rtl {
    for i in 1..<n {
      let next_start = starts[i - 1]
      let next_end = ends[i - 1]
      if starts[i] == next_start {
        ends.set(i, next_end)
      } else {
        ends.set(i, next_start)
      }
    }
  } else {
    let mut i = n - 1
    while i > 0 {
      let next_start = starts[i]
      let next_end = ends[i]
      if starts[i - 1] == next_start {
        ends.set(i - 1, next_end)
      } else {
        ends.set(i - 1, next_start)
      }
      i = i - 1
    }
  }
  ends
}

///|
fn reverse_glyphs(glyphs : Array[ShapeGlyph]) -> Unit {
  if glyphs.length() < 2 {
    return
  }
  let mut i = 0
  let mut j = glyphs.length() - 1
  while i < j {
    let a = glyphs[i]
    let b = glyphs[j]
    glyphs.set(i, b)
    glyphs.set(j, a)
    i = i + 1
    j = j - 1
  }
}

///|
fn is_space_like_char(ch : Char) -> Bool {
  if ch == '\t' {
    return true
  }
  let cat = @moon_swash.CharInfo::from_char(ch).category()
  cat is SpaceSeparator || cat is LineSeparator || cat is ParagraphSeparator
}

///|
fn glyph_is_blank(text : String, glyph : ShapeGlyph) -> Bool {
  let start = clamp_text_index(glyph.start, text.length())
  let end0 = clamp_text_index(glyph.end, text.length())
  let end = if end0 < start { start } else { end0 }
  if end <= start {
    return false
  }
  let run = slice_text_utf16(text, start, end)
  let mut has_char = false
  for ch in run {
    has_char = true
    if !is_space_like_char(ch) {
      return false
    }
  }
  has_char
}

///|
priv struct RunGlyphChunk {
  blank : Bool
  glyphs : Array[ShapeGlyph]
}

///|
fn reorder_run_glyphs_for_bidi(
  text : String,
  run_glyphs : Array[ShapeGlyph],
  line_rtl : Bool,
  run_rtl : Bool,
) -> Array[ShapeGlyph] {
  if run_glyphs.length() < 2 {
    return run_glyphs
  }

  let chunks : Array[RunGlyphChunk] = []
  for glyph in run_glyphs {
    let blank = glyph_is_blank(text, glyph)
    if !blank && chunks.length() > 0 && !chunks[chunks.length() - 1].blank {
      chunks[chunks.length() - 1].glyphs.push(glyph)
    } else {
      chunks.push(RunGlyphChunk::{ blank, glyphs: [glyph] })
    }
  }

  // Swash emits RTL clusters in logical order while reference HarfBuzz stream
  // is visual. Adjust per-word glyph direction first, then apply word-order flip.
  let need_reverse_word_glyphs = if run_rtl { !line_rtl } else { line_rtl }
  if need_reverse_word_glyphs {
    for i in 0..<chunks.length() {
      reverse_glyphs(chunks[i].glyphs)
    }
  }
  if line_rtl != run_rtl {
    let mut i = 0
    let mut j = chunks.length() - 1
    while i < j {
      let a = chunks[i]
      let b = chunks[j]
      chunks.set(i, b)
      chunks.set(j, a)
      i = i + 1
      j = j - 1
    }
  }

  let out : Array[ShapeGlyph] = []
  for chunk in chunks {
    for glyph in chunk.glyphs {
      out.push(glyph)
    }
  }
  out
}

///|
fn missing_contains(missing : Array[Int], start : Int) -> Bool {
  for m in missing {
    if m == start {
      return true
    }
  }
  false
}

///|
fn remove_missing_range(missing : Array[Int], start : Int, end : Int) -> Unit {
  let keep : Array[Int] = []
  for m in missing {
    if m < start || m >= end {
      keep.push(m)
    }
  }
  missing.clear()
  for m in keep {
    missing.push(m)
  }
}

///|
fn replace_cluster_glyphs(
  run_glyphs : Array[ShapeGlyph],
  start : Int,
  end : Int,
  replacement : Array[ShapeGlyph],
) -> Array[ShapeGlyph] {
  let out : Array[ShapeGlyph] = []
  let mut inserted = false
  for g in run_glyphs {
    let in_range = g.start >= start && g.end <= end
    if in_range && !inserted {
      for rg in replacement {
        out.push(rg)
      }
      inserted = true
    }
    if !in_range {
      out.push(g)
    }
  }
  if !inserted {
    for rg in replacement {
      out.push(rg)
    }
  }
  out
}

///|
fn merge_fallback_glyphs(
  run_glyphs : Array[ShapeGlyph],
  missing : Array[Int],
  fallback_glyphs : Array[ShapeGlyph],
  fallback_missing : Array[Int],
) -> Array[ShapeGlyph] {
  let mut merged = run_glyphs
  let mut fb_i = 0
  while fb_i < fallback_glyphs.length() {
    let start = fallback_glyphs[fb_i].start
    let end = fallback_glyphs[fb_i].end
    if !missing_contains(missing, start) ||
      missing_contains(fallback_missing, start) {
      fb_i = fb_i + 1
      continue
    }

    let replacement : Array[ShapeGlyph] = []
    while fb_i < fallback_glyphs.length() {
      let g = fallback_glyphs[fb_i]
      if g.start >= start && g.end <= end {
        replacement.push(g)
        fb_i = fb_i + 1
      } else {
        break
      }
    }

    remove_missing_range(missing, start, end)
    merged = replace_cluster_glyphs(merged, start, end, replacement)
  }
  merged
}

///|
fn better_monospace_fallback_candidate(
  cand : (Int, Bool, Int, Int, Int),
  best : (Int, Bool, Int, Int, Int),
) -> Bool {
  let cand_id = cand.0
  let cand_is_primary_default = cand.1
  let cand_weight_diff = cand.2
  let cand_non_matches = cand.3
  let cand_weight = cand.4
  let best_id = best.0
  let best_is_primary_default = best.1
  let best_weight_diff = best.2
  let best_non_matches = best.3
  let best_weight = best.4
  if cand_is_primary_default != best_is_primary_default {
    return cand_is_primary_default
  }
  if cand_weight_diff != best_weight_diff {
    return cand_weight_diff < best_weight_diff
  }
  if cand_non_matches != best_non_matches {
    return cand_non_matches < best_non_matches
  }
  if cand_weight != best_weight {
    return cand_weight < best_weight
  }
  cand_id < best_id
}

///|
fn reorder_monospace_fallback_candidates(
  font_system : FontSystem,
  run_attrs : Attrs,
  run_scripts : Array[@moon_swash.Script],
  run_tokens : Array[@moon_swash.Token],
  ordered : Array[Int],
) -> Array[Int] {
  if !(run_attrs.family_value() is Monospace) {
    return ordered
  }
  let codepoints : Array[UInt] = []
  for t in run_tokens {
    codepoints.push(t.ch().to_int().reinterpret_as_uint())
  }
  if codepoints.length() == 0 || ordered.length() <= 1 {
    return ordered
  }

  let req_weight = run_attrs.weight_value()
  let mut primary_default_mono_id : Int? = None
  for id in ordered {
    match font_system.get_font_entry(id) {
      None => ()
      Some(entry) =>
        if entry.is_monospace() && entry_weight_diff(entry, req_weight) == 0 {
          primary_default_mono_id = Some(id)
          break
        }
    }
  }

  let mut has_script_specific_monospace = false
  for id in ordered {
    match font_system.get_font_entry(id) {
      None => ()
      Some(entry) =>
        if entry.is_monospace() &&
          entry_supports_any_run_script(entry, run_scripts) {
          has_script_specific_monospace = true
          break
        }
    }
  }

  let mono_candidates : Array[(Int, Bool, Int, Int, Int)] = []
  let non_mono_candidates : Array[Int] = []
  for id in ordered {
    match font_system.get_font_entry(id) {
      None => non_mono_candidates.push(id)
      Some(entry) => {
        let keep_as_mono = if !entry.is_monospace() {
          false
        } else if has_script_specific_monospace {
          match primary_default_mono_id {
            Some(pid) =>
              pid == id || entry_supports_any_run_script(entry, run_scripts)
            None => entry_supports_any_run_script(entry, run_scripts)
          }
        } else {
          true
        }
        if keep_as_mono {
          let supported = font_system.count_supported_codepoints(id, codepoints)
          let info = (
            id,
            match primary_default_mono_id {
              Some(pid) => pid == id
              None => false
            },
            entry_weight_diff(entry, req_weight),
            codepoints.length() - supported,
            entry_weight_raw(entry),
          )
          mono_candidates.push(info)
        } else {
          non_mono_candidates.push(id)
        }
      }
    }
  }

  let n = mono_candidates.length()
  let used : Array[Bool] = Array::makei(n, _ => false)
  let reordered_mono : Array[Int] = []
  for _ in 0..<n {
    let mut best = -1
    for i in 0..<n {
      if used[i] {
        continue
      }
      if best < 0 ||
        better_monospace_fallback_candidate(
          mono_candidates[i],
          mono_candidates[best],
        ) {
        best = i
      }
    }
    if best >= 0 {
      used.set(best, true)
      reordered_mono.push(mono_candidates[best].0)
    }
  }

  let reordered : Array[Int] = []
  for id in reordered_mono {
    reordered.push(id)
  }
  for id in non_mono_candidates {
    reordered.push(id)
  }
  reordered
}

///|
fn shape_run_with_font(
  font_system : FontSystem,
  attrs_list : AttrsList,
  levels : Array[Int],
  text_len : Int,
  line_rtl : Bool,
  run_rtl : Bool,
  cx : @shape.ShapeContext,
  script : @moon_swash.Script,
  run_tokens : Array[@moon_swash.Token],
  font_id : Int,
) -> (Array[ShapeGlyph], Array[Int]) {
  let font_opt = font_system.get_font(font_id)
  let font = match font_opt {
    None => {
      let missing : Array[Int] = []
      for t in run_tokens {
        missing.push(t.offset().reinterpret_as_int())
      }
      return ([], missing)
    }
    Some(f) => f
  }
  let cmap = @moon_swash.Charmap::from_font(font)
  let empty_features : Array[@moon_swash.Setting[UInt16]] = []
  let empty_variations : Array[@moon_swash.Setting[Double]] = []
  let shaper = cx
    .builder(font)
    .script(script)
    .direction(
      if run_rtl {
        @shape.Direction::RightToLeft
      } else {
        @shape.Direction::LeftToRight
      },
    )
    .language(None)
    .size(1.0)
    .features(empty_features.iter())
    .variations(empty_variations.iter())
    .build()

  let parser = @moon_swash.Parser::new(script, run_tokens.iter())
  let cluster = @moon_swash.CharCluster::new()
  while parser.next(cluster) {
    cluster.map(fn(ch) { cmap.map(ch.to_int().reinterpret_as_uint()) })
    |> ignore
    shaper.add_cluster(cluster)
  }

  let out : Array[ShapeGlyph] = []
  let missing : Array[Int] = []
  shaper.shape_with(fn(gc) {
    let source = gc.source()
    let source_start = source_start_index(source)
    let source_end = source_end_index(source)
    let shaped = gc.glyphs()
    let shaped_count = shaped.length()
    if shaped_count != 0 {
      let starts_fallback = build_cluster_starts(
        source,
        gc.components(),
        shaped_count,
        run_rtl,
      )
      let starts : Array[Int] = []
      // Reference alignment:
      // use per-glyph source marker first (analogous to HarfBuzz cluster index),
      // and fall back to component-based starts only when marker is out of range.
      for i in 0..<shaped_count {
        let data_start = shaped[i].data().reinterpret_as_int()
        if data_start >= source_start && data_start <= source_end {
          let fallback_start = starts_fallback[i]
          if data_start < fallback_start {
            starts.push(data_start)
          } else {
            starts.push(fallback_start)
          }
        } else {
          starts.push(starts_fallback[i])
        }
      }
      let ends = build_cluster_ends(starts, source_end, run_rtl)
      for i in 0..<shaped_count {
        let g = shaped[i]
        let (start, end) = clamp_range_to_source(
          starts[i],
          ends[i],
          source_start,
          source_end,
        )
        let attrs = attrs_for_position(attrs_list, start, text_len)
        let lev = if levels.get(start) is Some(v) {
          v
        } else if line_rtl {
          1
        } else {
          0
        }
        if g.id().to_int() == 0 {
          missing.push(start)
        }
        out.push(ShapeGlyph::{
          start,
          end,
          x_advance: Float::from_double(g.advance()),
          y_advance: 0.0F,
          x_offset: Float::from_double(g.x()),
          y_offset: Float::from_double(g.y()),
          font_id,
          font_weight: attrs.weight_value().value(),
          glyph_id: g.id().to_int(),
          metadata: attrs.metadata(),
          level: lev,
          metrics_opt: attrs.metrics_opt(),
        })
      }
    }
  })
  (out, missing)
}

///|
/// Build a shaped line from text and attributes list.
///
/// MVP notes:
/// - 1 code unit -> 1 glyph
/// - `glyph_id` is the code unit value
/// - `x_advance` is measured in "cells": 1.0 for normal chars, `tab_width` for tab.
pub fn ShapeLine::build(
  _self : ShapeLine,
  text : String,
  attrs_list : AttrsList,
  shaping : Shaping,
  tab_width : Int,
) -> ShapeLine {
  let rtl = shaping is Advanced && detect_base_rtl(text)
  let levels = compute_bidi_levels(text, rtl)
  let glyphs : Array[ShapeGlyph] = []
  let len = text.length()
  for i in 0..<len {
    let code = text.code_unit_at(i).to_int()
    let advance = if is_tab(code) {
      Float::from_double(tab_width.to_double())
    } else {
      1.0F
    }
    let attrs = attrs_list.get_span(i)
    glyphs.push(ShapeGlyph::{
      start: i,
      end: i + 1,
      x_advance: advance,
      y_advance: 0.0F,
      x_offset: 0.0F,
      y_offset: 0.0F,
      font_id: 0,
      font_weight: attrs.weight_value().value(),
      glyph_id: code,
      metadata: attrs.metadata(),
      level: if levels.get(i) is Some(v) {
        v
      } else {
        0
      },
      metrics_opt: attrs.metrics_opt(),
    })
  }
  ShapeLine::{ rtl, glyphs }
}

///|
/// Build a shaped line using a FontSystem (best-effort).
///
/// Current behavior is still "Basic shaping" (1 UTF-16 code unit -> 1 glyph),
/// but uses `moon_swash` charmap + glyph metrics so advances are font-derived.
pub fn ShapeLine::build_with_font_system(
  _self : ShapeLine,
  font_system : FontSystem,
  text : String,
  attrs_list : AttrsList,
  shaping : Shaping,
  tab_width : Int,
) -> ShapeLine {
  if shaping is Basic {
    return ShapeLine::build(
      ShapeLine::empty(),
      text,
      attrs_list,
      shaping,
      tab_width,
    )
  }
  let default_font_id_opt = font_system.resolve(attrs_list.defaults())
  let default_font_id = match default_font_id_opt {
    None =>
      return ShapeLine::build(
        ShapeLine::empty(),
        text,
        attrs_list,
        shaping,
        tab_width,
      )
    Some(id) => id
  }
  if font_system.get_font(default_font_id) is None {
    return ShapeLine::build(
      ShapeLine::empty(),
      text,
      attrs_list,
      shaping,
      tab_width,
    )
  }

  // Use swash's shaping engine for clusters/ligatures/marks. We intentionally use
  // size=1.0 so the returned advances/offsets are in "em" units (like upstream),
  // which are later multiplied by `font_size` during layout.
  let rtl = detect_base_rtl(text)
  let levels = compute_bidi_levels(text, rtl)
  let cx = @shape.ShapeContext::new()
  let runs : Array[
    (
      @moon_swash.Script,
      Array[@moon_swash.Script],
      Bool,
      Array[@moon_swash.Token],
    ),
  ] = []
  let mut off = 0U
  let mut cur_primary_script = @moon_swash.Script::Latin
  let mut cur_primary_pending = true
  let mut cur_level = if rtl { 1 } else { 0 }
  let mut cur_rtl = rtl
  let mut cur_scripts : Array[@moon_swash.Script] = []
  let mut cur_tokens : Array[@moon_swash.Token] = []
  for ch0 in text {
    let script0 = @moon_swash.CharInfo::from_char(ch0).properties().script()
    let len_u = utf16_len_of_char(ch0).reinterpret_as_uint()
    let i = off.reinterpret_as_int()
    let level_i = if levels.get(i) is Some(v) { v } else if rtl { 1 } else { 0 }
    let run_rtl = level_i % 2 != 0
    // Tabs are shaped as spaces (upstream behavior).
    let ch = if ch0 == '\t' { ' ' } else { ch0 }
    let info = @moon_swash.CharInfo::from_char(ch)
    let tok = @moon_swash.Token::new(ch, off, len_u, info, off)
    let primary = shape_primary_script_seed(script0)
    if cur_tokens.length() == 0 {
      cur_primary_script = primary.0
      cur_primary_pending = primary.1
      cur_level = level_i
      cur_rtl = run_rtl
      cur_scripts = []
    } else if shape_levels_require_new_run(cur_level, level_i) {
      runs.push((cur_primary_script, cur_scripts, cur_rtl, cur_tokens))
      cur_tokens = []
      cur_primary_script = primary.0
      cur_primary_pending = primary.1
      cur_level = level_i
      cur_rtl = run_rtl
      cur_scripts = []
    } else if cur_primary_pending &&
      !(script0 is Common || script0 is Inherited || script0 is Unknown) {
      cur_primary_script = script0
      cur_primary_pending = false
    }
    if shape_script_needs_fallback_stage(script0) &&
      !shape_script_in_array(cur_scripts, script0) {
      cur_scripts.push(script0)
    }
    cur_tokens.push(tok)
    off = off + len_u
  }
  let glyphs : Array[ShapeGlyph] = []
  if cur_tokens.length() != 0 {
    runs.push((cur_primary_script, cur_scripts, cur_rtl, cur_tokens))
  }
  for run in runs {
    let script = run.0
    let run_scripts = if run.1.length() == 0 {
      collect_run_fallback_scripts(run.3)
    } else {
      run.1
    }
    let run_rtl = run.2
    let run_tokens = run.3
    let run_start = if run_tokens.length() == 0 {
      0
    } else {
      run_tokens[0].offset().reinterpret_as_int()
    }
    let run_end = if run_tokens.length() == 0 {
      run_start
    } else {
      let last = run_tokens[run_tokens.length() - 1]
      (last.offset() + last.len()).reinterpret_as_int()
    }
    let cache_key = ShapeRunKey::new(
      slice_text_utf16(text, run_start, run_end),
      attrs_list_for_utf16_range(attrs_list, run_start, run_end, text.length()),
    )
    if font_system.shape_run_cache.get(cache_key) is Some(cache_glyphs) {
      for g in cache_glyphs {
        glyphs.push(ShapeGlyph::{
          ..g,
          start: g.start + run_start,
          end: g.end + run_start,
        })
      }
      continue
    }

    let run_attrs = attrs_for_position(attrs_list, run_start, text.length())
    let run_font_id = match font_system.resolve(run_attrs) {
      None => default_font_id
      Some(id) => id
    }
    let (default_glyphs, default_missing) = shape_run_with_font(
      font_system,
      attrs_list,
      levels,
      text.length(),
      rtl,
      run_rtl,
      cx,
      script,
      run_tokens,
      run_font_id,
    )
    let mut run_glyphs = default_glyphs
    let missing = default_missing
    if missing.length() > 0 {
      let ordered0 = font_system.font_matches_for_scripts(
        run_attrs, run_scripts,
      )
      let ordered = reorder_monospace_fallback_candidates(
        font_system, run_attrs, run_scripts, run_tokens, ordered0,
      )
      for alt_font_id in ordered {
        if alt_font_id == run_font_id {
          continue
        }
        let (fb_glyphs, fb_missing) = shape_run_with_font(
          font_system,
          attrs_list,
          levels,
          text.length(),
          rtl,
          run_rtl,
          cx,
          script,
          run_tokens,
          alt_font_id,
        )
        run_glyphs = merge_fallback_glyphs(
          run_glyphs, missing, fb_glyphs, fb_missing,
        )
        if missing.length() == 0 {
          break
        }
      }
    }
    run_glyphs = reorder_run_glyphs_for_bidi(text, run_glyphs, rtl, run_rtl)
    let cached_run_glyphs : Array[ShapeGlyph] = []
    for g in run_glyphs {
      glyphs.push(g)
      cached_run_glyphs.push(ShapeGlyph::{
        ..g,
        start: g.start - run_start,
        end: g.end - run_start,
      })
    }
    font_system.shape_run_cache.insert(cache_key, cached_run_glyphs)
  }

  // If shaping produces no glyphs, fall back to the simple shaper to keep layout stable.
  if glyphs.length() == 0 {
    return ShapeLine::build(
      ShapeLine::empty(),
      text,
      attrs_list,
      shaping,
      tab_width,
    )
  }

  // Apply tab stops using each tab glyph's own advance as the tab unit.
  let mut x = 0.0
  for i in 0..<glyphs.length() {
    let g0 = glyphs[i]
    let is_tab_glyph = g0.end - g0.start == 1 &&
      g0.start >= 0 &&
      g0.start < text.length() &&
      is_tab(text.code_unit_at(g0.start).to_int())
    if is_tab_glyph {
      let step = g0.x_advance.to_double() * tab_width.to_double()
      if step != 0.0 {
        let next = ((x / step).floor() + 1.0) * step
        let adv = next - x
        let g1 = ShapeGlyph::{ ..g0, x_advance: Float::from_double(adv) }
        glyphs.set(i, g1)
        x = next
      } else {
        x = x + g0.x_advance.to_double()
      }
    } else {
      x = x + g0.x_advance.to_double()
    }
  }
  ShapeLine::{ rtl, glyphs }
}
