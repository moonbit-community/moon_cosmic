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
/// Shaping primitives ported from `cosmic-text/src/shape.rs`.
pub(all) enum Shaping {
  Basic
  Advanced
}

///|
const SHAPE_WEIGHT_AXIS_TAG : UInt = 0x77676874U // "wght"

///|
pub struct ShapeGlyph {
  start : Int
  end : Int
  x_advance : Float
  y_advance : Float
  x_offset : Float
  y_offset : Float
  /// Normalized ascent in em units.
  ascent : Float
  /// Normalized descent in em units.
  descent : Float
  font_id : Int
  font_weight : Int
  glyph_id : Int
  color_opt : Color?
  metadata : Int
  cache_key_flags : CacheKeyFlags
  text_decoration : TextDecoration
  underline_metrics : DecorationMetrics
  strikethrough_metrics : DecorationMetrics
  /// BiDi embedding level (LTR if divisible by 2).
  level : Int
  /// Optional Metrics override (font size / line height) for this glyph's span.
  metrics_opt : Metrics?

  fn new(
    start : Int,
    end : Int,
    x_advance : Float,
    y_advance : Float,
    x_offset : Float,
    y_offset : Float,
    font_id : Int,
    glyph_id : Int,
    metadata : Int,
  ) -> ShapeGlyph
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
    ascent: 0.0F,
    descent: 0.0F,
    font_id,
    font_weight: 400,
    glyph_id,
    color_opt: None,
    metadata,
    cache_key_flags: 0U,
    text_decoration: TextDecoration::new(),
    underline_metrics: DecorationMetrics::new(-0.125F, 1.0F / 14.0F),
    strikethrough_metrics: DecorationMetrics::new(0.3F, 1.0F / 14.0F),
    level: 0,
    metrics_opt: None,
  }
}

///|
pub fn ShapeGlyph::with_ascent_descent(
  self : ShapeGlyph,
  ascent : Float,
  descent : Float,
) -> ShapeGlyph {
  ShapeGlyph::{ ..self, ascent, descent }
}

///|
pub struct ShapeLine {
  text : String
  rtl : Bool
  glyphs : Array[ShapeGlyph]

  fn new(rtl : Bool, glyphs : Array[ShapeGlyph]) -> ShapeLine
}

///|
pub fn ShapeLine::new(rtl : Bool, glyphs : Array[ShapeGlyph]) -> ShapeLine {
  ShapeLine::{ text: "", rtl, glyphs }
}

///|
pub fn ShapeLine::empty() -> ShapeLine {
  ShapeLine::{ text: "", rtl: false, glyphs: [] }
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
fn absf(v : Float) -> Float {
  if v < 0.0F {
    0.0F - v
  } else {
    v
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
fn normalize_rtl_mark_clusters(
  glyphs : Array[ShapeGlyph],
  run_rtl : Bool,
) -> Unit {
  if !run_rtl || glyphs.length() < 2 {
    return
  }
  let mut i = 0
  while i < glyphs.length() {
    let start = glyphs[i].start
    let end = glyphs[i].end
    let mut j = i + 1
    while j < glyphs.length() &&
          glyphs[j].start == start &&
          glyphs[j].end == end {
      j = j + 1
    }
    if j - i > 1 {
      let mut base_adv = 0.0F
      let bases : Array[ShapeGlyph] = []
      let marks : Array[ShapeGlyph] = []
      for k in i..<j {
        let g = glyphs[k]
        if absf(g.x_advance) <= 0.000001F {
          marks.push(g)
        } else {
          bases.push(g)
          if g.x_advance > base_adv {
            base_adv = g.x_advance
          }
        }
      }
      if base_adv != 0.0F && marks.length() > 0 {
        // swash mark offsets in RTL clusters are relative to cluster end;
        // normalize to cluster start semantics used by reference shaping.
        for m in 0..<marks.length() {
          let g = marks[m]
          marks.set(m, ShapeGlyph::{ ..g, x_offset: g.x_offset + base_adv })
        }
        // Keep deterministic mark order for same-range cluster: larger x_offset first.
        let mut a = 0
        while a < marks.length() {
          let mut b = a + 1
          while b < marks.length() {
            if marks[b].x_offset > marks[a].x_offset {
              let ga = marks[a]
              let gb = marks[b]
              marks.set(a, gb)
              marks.set(b, ga)
            }
            b = b + 1
          }
          a = a + 1
        }
        let mut p = i
        for g in bases {
          glyphs.set(p, g)
          p = p + 1
        }
        for g in marks {
          glyphs.set(p, g)
          p = p + 1
        }
      }
    }
    i = j
  }
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
  normalize_rtl_mark_clusters(out, run_rtl)
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
fn shape_clamp_double(v : Double, lo : Double, hi : Double) -> Double {
  if v < lo {
    lo
  } else if v > hi {
    hi
  } else {
    v
  }
}

///|
fn shape_variation_settings_for_font(
  font : @moon_swash.FontRef,
  attrs : Attrs,
) -> Array[@moon_swash.VariationSetting] {
  let settings : Array[@moon_swash.VariationSetting] = []
  match font.variations().find_by_tag(SHAPE_WEIGHT_AXIS_TAG) {
    None => settings
    Some(axis) => {
      let w = attrs.weight_value().value().to_double()
      let value = shape_clamp_double(w, axis.min_value(), axis.max_value())
      settings.push(@moon_swash.Setting::new(SHAPE_WEIGHT_AXIS_TAG, value))
      settings
    }
  }
}

///|
fn hb_tag_from_swash_tag(tag : UInt) -> @common.Tag {
  @common.Tag::from_bytes(
    ((tag >> 24) & 0xFFU).to_byte(),
    ((tag >> 16) & 0xFFU).to_byte(),
    ((tag >> 8) & 0xFFU).to_byte(),
    (tag & 0xFFU).to_byte(),
  )
}

///|
fn hb_script_from_swash_script(script : @moon_swash.Script) -> @common.Script {
  @common.Script::from_iso15924_tag(hb_tag_from_swash_tag(script.to_opentype()))
}

///|
fn hb_direction_from_run_rtl(run_rtl : Bool) -> @common.Direction {
  if run_rtl {
    @common.direction_rtl
  } else {
    @common.direction_ltr
  }
}

///|
fn shape_harfbuzz_variations(
  font : @moon_swash.FontRef,
  attrs : Attrs,
) -> Array[@var.AxisCoord] {
  let axis_coords : Array[@var.AxisCoord] = []
  let settings = shape_variation_settings_for_font(font, attrs)
  for setting in settings {
    axis_coords.push(
      @var.AxisCoord::new(hb_tag_from_swash_tag(setting.tag), setting.value),
    )
  }
  axis_coords
}

///|
fn shape_run_with_harfbuzz(
  font_system : FontSystem,
  entry : FontEntry,
  attrs_list : AttrsList,
  levels : Array[Int],
  text_len : Int,
  line_rtl : Bool,
  run_rtl : Bool,
  script : @moon_swash.Script,
  run_tokens : Array[@moon_swash.Token],
  run_attrs : Attrs,
  font_id : Int,
  font_ascent : Float,
  font_descent : Float,
  underline_metrics : DecorationMetrics,
  strikethrough_metrics : DecorationMetrics,
) -> (Array[ShapeGlyph], Array[Int])? {
  if run_tokens.length() == 0 {
    return Some(([], []))
  }
  let mut source_start = run_tokens[0].offset().reinterpret_as_int()
  let mut source_end = source_start + run_tokens[0].len().reinterpret_as_int()
  for t in run_tokens {
    let s = t.offset().reinterpret_as_int()
    let e = s + t.len().reinterpret_as_int()
    if s < source_start {
      source_start = s
    }
    if e > source_end {
      source_end = e
    }
  }
  if source_end < source_start {
    source_end = source_start
  }
  let upem = entry.font.metrics([]).units_per_em.to_int()
  if upem <= 0 {
    return None
  }
  let hb_font = font_system.hb_font_for_entry(entry)
  hb_font.set_scale(upem, upem)
  let axis_coords = shape_harfbuzz_variations(entry.font, run_attrs)
  match hb_font.set_variations(axis_coords) {
    Err(_) => ()
    Ok(_) => ()
  }

  let hb_buffer = font_system.shape_hb_buffer()
  hb_buffer.clear()
  hb_buffer.set_direction(hb_direction_from_run_rtl(run_rtl))
  hb_buffer.set_script(hb_script_from_swash_script(script))
  hb_buffer.set_language(@common.Language::from_string("und"))
  for t in run_tokens {
    let ch = if t.ch() == '\t' { ' ' } else { t.ch() }
    hb_buffer.add_codepoint(
      ch.to_uint(),
      cluster=t.offset().reinterpret_as_int() - source_start,
    )
  }
  match @hb_shape.shape(hb_font, hb_buffer, shapers=["ot"]) {
    Err(_) => return None
    Ok(_) => ()
  }
  let infos = hb_buffer.infos()
  let positions = hb_buffer.positions()
  if infos.length() != positions.length() {
    return None
  }

  let upem_d = upem.to_double()
  let out : Array[ShapeGlyph] = []
  let missing : Array[Int] = []
  for i in 0..<infos.length() {
    let info = infos[i]
    let pos = positions[i]
    let start0 = source_start + info.cluster
    let start = if start0 < source_start {
      source_start
    } else if start0 > source_end {
      source_end
    } else {
      start0
    }
    let attrs = attrs_for_position(attrs_list, start, text_len)
    let lev = if levels.get(start) is Some(v) {
      v
    } else if line_rtl {
      1
    } else {
      0
    }
    if info.codepoint == 0U {
      missing.push(start)
    }
    let letter_spacing = attrs_letter_spacing(attrs)
    out.push(ShapeGlyph::{
      start,
      end: source_end,
      x_advance: Float::from_double(pos.x_advance.to_double() / upem_d) +
      letter_spacing,
      y_advance: Float::from_double(pos.y_advance.to_double() / upem_d),
      x_offset: Float::from_double(pos.x_offset.to_double() / upem_d),
      y_offset: Float::from_double(pos.y_offset.to_double() / upem_d),
      ascent: font_ascent,
      descent: font_descent,
      font_id,
      font_weight: attrs.weight_value().value(),
      glyph_id: info.codepoint.reinterpret_as_int(),
      color_opt: attrs.color_opt_value(),
      metadata: attrs.metadata(),
      cache_key_flags: attrs.cache_key_flags_value(),
      text_decoration: attrs.text_decoration_value(),
      underline_metrics,
      strikethrough_metrics,
      level: lev,
      metrics_opt: attrs.metrics_opt(),
    })
  }

  let use_rtl_end_adjust = if out.length() > 1 {
    out[0].start > out[out.length() - 1].start
  } else {
    run_rtl
  }
  if use_rtl_end_adjust {
    for i in 1..<out.length() {
      let next_start = out[i - 1].start
      let next_end = out[i - 1].end
      let g = out[i]
      out.set(i, ShapeGlyph::{
        ..g,
        end: if g.start == next_start {
          next_end
        } else {
          next_start
        },
      })
    }
  } else if out.length() > 1 {
    let mut i = out.length() - 1
    while i > 0 {
      let next_start = out[i].start
      let next_end = out[i].end
      let g = out[i - 1]
      out.set(i - 1, ShapeGlyph::{
        ..g,
        end: if g.start == next_start {
          next_end
        } else {
          next_start
        },
      })
      i = i - 1
    }
  }
  Some((out, missing))
}

///|
fn attrs_letter_spacing(attrs : Attrs) -> Float {
  match attrs.letter_spacing_opt() {
    None => 0.0F
    Some(v) => v
  }
}

///|
fn shape_run_missing_tokens(
  run_tokens : Array[@moon_swash.Token],
) -> Array[Int] {
  let missing : Array[Int] = []
  for t in run_tokens {
    let s = t.offset().reinterpret_as_int()
    if !missing_contains(missing, s) {
      missing.push(s)
    }
  }
  missing
}

///|
fn shape_run_with_font(
  font_system : FontSystem,
  attrs_list : AttrsList,
  levels : Array[Int],
  text_len : Int,
  line_rtl : Bool,
  run_rtl : Bool,
  script : @moon_swash.Script,
  run_tokens : Array[@moon_swash.Token],
  font_id : Int,
) -> (Array[ShapeGlyph], Array[Int]) {
  let entry = match font_system.get_font_entry(font_id) {
    None => return ([], shape_run_missing_tokens(run_tokens))
    Some(v) => v
  }
  let (font_ascent, font_descent, underline_metrics, strikethrough_metrics) = {
    let metrics = entry.font.metrics([])
    let upem = metrics.units_per_em.to_int()
    if upem <= 0 {
      (
        0.0F,
        0.0F,
        DecorationMetrics::new(-0.125F, 1.0F / 14.0F),
        DecorationMetrics::new(0.3F, 1.0F / 14.0F),
      )
    } else {
      let upem_d = upem.to_double()
      let scale = 1.0 / upem_d
      let stroke = if metrics.stroke_size == 0.0 {
        1.0 / 14.0
      } else {
        metrics.stroke_size / upem_d
      }
      (
        Float::from_double(metrics.ascent * scale),
        Float::from_double(metrics.descent * scale),
        DecorationMetrics::new(
          Float::from_double(metrics.underline_offset / upem_d),
          Float::from_double(stroke),
        ),
        DecorationMetrics::new(
          Float::from_double(metrics.strikeout_offset / upem_d),
          Float::from_double(stroke),
        ),
      )
    }
  }
  let run_attrs = if run_tokens.length() == 0 {
    attrs_list.defaults()
  } else {
    attrs_for_position(
      attrs_list,
      run_tokens[0].offset().reinterpret_as_int(),
      text_len,
    )
  }
  match
    shape_run_with_harfbuzz(
      font_system, entry, attrs_list, levels, text_len, line_rtl, run_rtl, script,
      run_tokens, run_attrs, font_id, font_ascent, font_descent, underline_metrics,
      strikethrough_metrics,
    ) {
    None => ([], shape_run_missing_tokens(run_tokens))
    Some(ret) => ret
  }
}

///|
/// Build a shaped line from text and attributes list.
pub fn ShapeLine::build(
  _self : ShapeLine,
  text : String,
  attrs_list : AttrsList,
  shaping : Shaping,
  tab_width : Int,
) -> ShapeLine {
  let bidi_info = if shaping is Advanced {
    BidiInfo::new(text)
  } else {
    BidiInfo::new_with_para_level(text, Some(0))
  }
  let rtl = bidi_info.rtl()
  let levels = bidi_info.adjusted_levels()
  let glyphs : Array[ShapeGlyph] = []
  let len = text.length()
  for i in 0..<len {
    let code = text.code_unit_at(i).to_int()
    let base_advance = if is_tab(code) {
      Float::from_double(tab_width.to_double())
    } else {
      1.0F
    }
    let attrs = attrs_list.get_span(i)
    let advance = base_advance + attrs_letter_spacing(attrs)
    glyphs.push(ShapeGlyph::{
      start: i,
      end: i + 1,
      x_advance: advance,
      y_advance: 0.0F,
      x_offset: 0.0F,
      y_offset: 0.0F,
      ascent: 0.0F,
      descent: 0.0F,
      font_id: 0,
      font_weight: attrs.weight_value().value(),
      glyph_id: code,
      color_opt: attrs.color_opt_value(),
      metadata: attrs.metadata(),
      cache_key_flags: attrs.cache_key_flags_value(),
      text_decoration: attrs.text_decoration_value(),
      underline_metrics: DecorationMetrics::new(-0.125F, 1.0F / 14.0F),
      strikethrough_metrics: DecorationMetrics::new(0.3F, 1.0F / 14.0F),
      level: if levels.get(i) is Some(v) {
        v
      } else {
        0
      },
      metrics_opt: attrs.metrics_opt(),
    })
  }
  ShapeLine::{ text, rtl, glyphs }
}

///|
/// Build a shaped line using a FontSystem (best-effort).
///
/// Advanced mode follows upstream `shape_run/shape_fallback` flow on top of
/// `moon_swash`: BiDi runs, per-run script/fallback selection, cluster-aware
/// glyph ranges, and run-cache reuse.
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
  let bidi_info = BidiInfo::new(text)
  let rtl = bidi_info.rtl()
  let levels = bidi_info.adjusted_levels()
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
  ShapeLine::{ text, rtl, glyphs }
}

///|
pub fn ShapeGlyph::width(self : ShapeGlyph, font_size : Float) -> Float {
  let glyph_font_size = match self.metrics_opt {
    None => font_size
    Some(m) => m.font_size
  }
  glyph_font_size * self.x_advance
}

///|
pub fn ShapeLine::width(self : ShapeLine, font_size : Float) -> Float {
  let mut width = 0.0F
  for glyph in self.glyphs {
    width = width + glyph.width(font_size)
  }
  width
}

///|
fn shape_line_source_text(line : ShapeLine) -> String {
  if line.text.length() > 0 {
    return line.text
  }
  let mut max_end = 0
  for g in line.glyphs {
    if g.end > max_end {
      max_end = g.end
    }
  }
  let sb = StringBuilder::new(size_hint=max_end)
  for _ in 0..<max_end {
    sb.write_char(' ')
  }
  sb.to_string()
}

///|
fn shape_hint_layout_line(line : LayoutLine) -> LayoutLine {
  if line.glyphs.length() == 0 {
    return line
  }
  let glyphs : Array[LayoutGlyph] = []
  let mut x = roundf(line.glyphs[0].x)
  let start_x = x
  for g in line.glyphs {
    let w = roundf(g.w)
    glyphs.push(LayoutGlyph::{ ..g, x, w })
    x = x + w
  }
  LayoutLine::{ ..line, w: x - start_x, glyphs }
}

///|
fn shape_max_layout_width(lines : Array[LayoutLine]) -> Float? {
  if lines.length() == 0 {
    return None
  }
  let mut max_w = lines[0].w
  for line in lines {
    if line.w > max_w {
      max_w = line.w
    }
  }
  Some(max_w)
}

///|
fn shape_postprocess_layout(
  text : String,
  lines0 : Array[LayoutLine],
  rtl : Bool,
  align_opt : Align?,
  width_opt : Float?,
  hinting : Hinting,
) -> Array[LayoutLine] {
  let mut lines = lines0
  let default_align = if rtl { Align::Right } else { Align::Left }
  let align = if align_opt is Some(a) { a } else { default_align }
  let line_width_opt = if width_opt is Some(width) {
    Some(width)
  } else {
    shape_max_layout_width(lines)
  }
  if line_width_opt is Some(width) {
    lines = apply_align_with_rtl(text, lines, width, align, rtl)
  }
  if hinting is Hinting::Enabled {
    let hinted : Array[LayoutLine] = []
    for line in lines {
      hinted.push(shape_hint_layout_line(line))
    }
    lines = hinted
  }
  lines
}

///|
pub fn ShapeLine::layout(
  self : ShapeLine,
  font_size : Float,
  width_opt : Float?,
  wrap : Wrap,
  ellipsize : Ellipsize,
  align : Align?,
  match_mono_width : Float?,
  hinting : Hinting,
) -> Array[LayoutLine] {
  let cell_w = if match_mono_width is Some(w) { w } else { font_size }
  let text = shape_line_source_text(self)
  let lines0 = layout_from_shape(text, self, font_size, cell_w, width_opt, wrap)
  let lines = apply_ellipsize(lines0, ellipsize, wrap, width_opt, font_size)
  shape_postprocess_layout(text, lines, self.rtl, align, width_opt, hinting)
}

///|
pub fn ShapeLine::layout_to_buffer(
  self : ShapeLine,
  font_size : Float,
  width_opt : Float?,
  wrap : Wrap,
  ellipsize : Ellipsize,
  align : Align?,
  layout_lines : Array[LayoutLine],
  match_mono_width : Float?,
  hinting : Hinting,
) -> Unit {
  layout_lines.clear()
  for
    line in self.layout(
      font_size, width_opt, wrap, ellipsize, align, match_mono_width, hinting,
    ) {
    layout_lines.push(line)
  }
}
