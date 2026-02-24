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
/// Minimal font system wrapper for the MoonBit cosmic-text port.
///
/// Upstream `cosmic-text` uses `fontdb` for font discovery. In this MoonBit port
/// we start with an in-memory font list backed by `moon_swash`.
pub struct FontEntry {
  id : Int
  family_name : String
  postscript_name : String
  font : @moon_swash.FontRef
  charmap_proxy : @moon_swash.CharmapProxy
  attributes : @moon_swash.Attributes
  is_monospace : Bool
  not_emoji : Bool
}

///|
pub fn FontEntry::id(self : FontEntry) -> Int {
  self.id
}

///|
pub fn FontEntry::family_name(self : FontEntry) -> String {
  self.family_name
}

///|
pub fn FontEntry::postscript_name(self : FontEntry) -> String {
  self.postscript_name
}

///|
pub fn FontEntry::font(self : FontEntry) -> @moon_swash.FontRef {
  self.font
}

///|
pub fn FontEntry::charmap_proxy(self : FontEntry) -> @moon_swash.CharmapProxy {
  self.charmap_proxy
}

///|
pub fn FontEntry::attributes(self : FontEntry) -> @moon_swash.Attributes {
  self.attributes
}

///|
pub fn FontEntry::is_monospace(self : FontEntry) -> Bool {
  self.is_monospace
}

///|
pub fn FontEntry::not_emoji(self : FontEntry) -> Bool {
  self.not_emoji
}

///|
pub struct FontSystem {
  locale : String
  fonts : Array[FontEntry]
  font_matches_cache : @hashmap.HashMap[FontMatchAttrs, Array[Int]]
  codepoint_support_cache : @hashmap.HashMap[
    Int,
    FontCachedCodepointSupportInfo,
  ]
}

///|
const FONT_MATCHES_CACHE_SIZE_LIMIT : Int = 256

///|
const CODEPOINT_SUPPORTED_PER_FONT_LIMIT : Int = 512

///|
const CODEPOINT_NOT_SUPPORTED_PER_FONT_LIMIT : Int = 1024

///|
pub fn FontSystem::new() -> FontSystem {
  FontSystem::new_with_locale("en-US")
}

///|
pub fn FontSystem::new_with_locale(locale : String) -> FontSystem {
  FontSystem::{
    locale,
    fonts: [],
    font_matches_cache: @hashmap.HashMap::default(),
    codepoint_support_cache: @hashmap.HashMap::default(),
  }
}

///|
pub fn FontSystem::locale(self : FontSystem) -> String {
  self.locale
}

///|
pub fn FontSystem::fonts(self : FontSystem) -> Array[FontEntry] {
  self.fonts
}

///|
fn font_family_name(font : @moon_swash.FontRef, locale : String) -> String {
  let strings = font.localized_strings()
  match strings.find_by_id(@moon_swash.StringId::Family, Some(locale)) {
    Some(s) => s.to_string()
    None =>
      match strings.find_by_id(@moon_swash.StringId::Family, None) {
        Some(s) => s.to_string()
        None => ""
      }
  }
}

///|
fn font_postscript_name(font : @moon_swash.FontRef) -> String {
  let strings = font.localized_strings()
  match strings.find_by_id(@moon_swash.StringId::PostScript, None) {
    Some(s) => s.to_string()
    None => ""
  }
}

///|
fn string_contains_ascii(haystack : String, needle : String) -> Bool {
  let hlen = haystack.length()
  let nlen = needle.length()
  if nlen == 0 {
    return true
  }
  if nlen > hlen {
    return false
  }
  for i in 0..<(hlen - nlen + 1) {
    let mut ok = true
    for j in 0..<nlen {
      if haystack.code_unit_at(i + j) != needle.code_unit_at(j) {
        ok = false
        break
      }
    }
    if ok {
      return true
    }
  }
  false
}

///|
fn is_family_name_id(id : @moon_swash.StringId) -> Bool {
  match id {
    @moon_swash.StringId::Family
    | @moon_swash.StringId::TypographicFamily
    | @moon_swash.StringId::WwsFamily => true
    _ => false
  }
}

///|
fn entry_has_family_name(entry : FontEntry, family_name : String) -> Bool {
  if entry.family_name == family_name {
    return true
  }
  let strings = entry.font.localized_strings()
  for s in strings.iter() {
    if is_family_name_id(s.id()) && s.to_string() == family_name {
      return true
    }
  }
  false
}

///|
fn entry_in_forbidden_fallback(entry : FontEntry) -> Bool {
  // Reference uses platform-specific forbidden fallback lists.
  // We currently model the strictest practical case (`.LastResort`) to avoid
  // selecting it during generic fallback stages.
  entry_has_family_name(entry, ".LastResort")
}

///|
/// Load font data (TTF/OTF/TTC bytes) into the system.
///
/// If the bytes do not parse as a font/collection, this is a no-op.
pub fn FontSystem::load_font_data(
  self : FontSystem,
  data : Bytes,
) -> FontSystem {
  match @moon_swash.FontDataRef::new(data) {
    None => self
    Some(data_ref) => {
      let locale = self.locale
      let fonts = self.fonts
      for f in data_ref.fonts() {
        let id = fonts.length()
        let family_name = font_family_name(f, locale)
        let postscript_name = font_postscript_name(f)
        let not_emoji = !string_contains_ascii(postscript_name, "Emoji")
        let metrics = f.metrics([])
        fonts.push(FontEntry::{
          id,
          family_name,
          postscript_name,
          font: f,
          charmap_proxy: @moon_swash.CharmapProxy::from_font(f),
          attributes: f.attributes(),
          is_monospace: metrics.is_monospace && not_emoji,
          not_emoji,
        })
      }
      // New fonts change candidate ordering; clear match cache.
      self.font_matches_cache.clear()
      FontSystem::{ ..self, fonts, }
    }
  }
}

///|
/// Find a font ID that matches the family selector (best-effort).
pub fn FontSystem::select_family(self : FontSystem, family : Family) -> Int? {
  select_family_with_weight(self, family, Weight::normal())
}

///|
fn abs_int(v : Int) -> Int {
  if v < 0 {
    0 - v
  } else {
    v
  }
}

///|
struct FontCachedCodepointSupportInfo {
  supported : Array[UInt]
  not_supported : Array[UInt]
  mut charmap_opt : @moon_swash.Charmap?
}

///|
fn FontCachedCodepointSupportInfo::new() -> FontCachedCodepointSupportInfo {
  FontCachedCodepointSupportInfo::{
    supported: [],
    not_supported: [],
    charmap_opt: None,
  }
}

///|
pub struct FontMatchAttrs {
  family : Family
  weight : Weight
  stretch : @moon_swash.Stretch
  style : @moon_swash.Style
}

///|
pub impl Eq for FontMatchAttrs with equal(self, other) {
  self.family == other.family &&
  self.weight == other.weight &&
  self.stretch == other.stretch &&
  self.style == other.style
}

///|
pub impl Hash for FontMatchAttrs with hash_combine(self, hasher) {
  self.family.hash_combine(hasher)
  self.weight.hash_combine(hasher)
  hasher.combine_int(self.stretch.raw().to_int())
  hasher.combine_string(self.style.to_string())
}

///|
fn family_matches(entry : FontEntry, family : Family) -> Bool {
  match family {
    Name(name) => entry_has_family_name(entry, name)
    Monospace => entry.is_monospace
    _ => true
  }
}

///|
fn move_forbidden_candidates_to_end(
  fs : FontSystem,
  family : Family,
  ids : Array[Int],
) -> Array[Int] {
  let head : Array[Int] = []
  let tail : Array[Int] = []
  for id in ids {
    if id < 0 || id >= fs.fonts.length() {
      continue
    }
    let entry = fs.fonts[id]
    // Keep explicitly requested family candidates in front.
    if entry_in_forbidden_fallback(entry) && !family_matches(entry, family) {
      tail.push(id)
    } else {
      head.push(id)
    }
  }
  for id in tail {
    head.push(id)
  }
  head
}

///|
fn font_maps_codepoint(
  fs : FontSystem,
  entry : FontEntry,
  codepoint : UInt,
) -> Bool {
  match fs.codepoint_support_cache.get(entry.id) {
    Some(info) => {
      let ok = cached_codepoint_has_support(info, entry, codepoint)
      fs.codepoint_support_cache.set(entry.id, info)
      ok
    }
    None => {
      let info = FontCachedCodepointSupportInfo::new()
      let ok = cached_codepoint_has_support(info, entry, codepoint)
      fs.codepoint_support_cache.set(entry.id, info)
      ok
    }
  }
}

///|
fn sorted_search_uint(arr : Array[UInt], value : UInt) -> (Bool, Int) {
  let mut low = 0
  let mut high = arr.length()
  while low < high {
    let mid = low + (high - low) / 2
    let cur = arr[mid]
    if cur == value {
      return (true, mid)
    }
    if cur < value {
      low = mid + 1
    } else {
      high = mid
    }
  }
  (false, low)
}

///|
fn cached_codepoint_has_support(
  info : FontCachedCodepointSupportInfo,
  entry : FontEntry,
  codepoint : UInt,
) -> Bool {
  let (supported_hit, supported_insert_pos) = sorted_search_uint(
    info.supported,
    codepoint,
  )
  if supported_hit {
    return true
  }
  let (not_supported_hit, not_supported_insert_pos) = sorted_search_uint(
    info.not_supported,
    codepoint,
  )
  if not_supported_hit {
    return false
  }

  let cm = match info.charmap_opt {
    Some(cached) => cached
    None => {
      let built = entry.charmap_proxy.materialize(entry.font)
      info.charmap_opt = Some(built)
      built
    }
  }
  let ok = cm.map(codepoint) != 0
  if ok {
    if supported_insert_pos != CODEPOINT_SUPPORTED_PER_FONT_LIMIT {
      info.supported.insert(supported_insert_pos, codepoint)
      info.supported.truncate(CODEPOINT_SUPPORTED_PER_FONT_LIMIT)
    }
  } else if not_supported_insert_pos != CODEPOINT_NOT_SUPPORTED_PER_FONT_LIMIT {
    info.not_supported.insert(not_supported_insert_pos, codepoint)
    info.not_supported.truncate(CODEPOINT_NOT_SUPPORTED_PER_FONT_LIMIT)
  }
  ok
}

///|
fn entry_weight_diff(entry : FontEntry, req_weight : Weight) -> Int {
  let a = entry.attributes.weight().value.to_int()
  abs_int(a - req_weight.value)
}

///|
fn entry_weight_raw(entry : FontEntry) -> Int {
  entry.attributes.weight().value.to_int()
}

///|
fn entry_stretch_raw(entry : FontEntry) -> Int {
  entry.attributes.stretch().raw().to_int()
}

///|
fn entry_stretch_diff(
  entry : FontEntry,
  req_stretch : @moon_swash.Stretch,
) -> Int {
  abs_int(entry_stretch_raw(entry) - req_stretch.raw().to_int())
}

///|
fn style_bucket(style : @moon_swash.Style) -> Int {
  match style {
    @moon_swash.Style::Normal => 0
    @moon_swash.Style::Italic => 1
    @moon_swash.Style::Oblique(_) => 2
  }
}

///|
fn style_diff(lhs : @moon_swash.Style, rhs : @moon_swash.Style) -> Int {
  let a = style_bucket(lhs)
  let b = style_bucket(rhs)
  if a == b {
    0
  } else if (a == 1 && b == 2) || (a == 2 && b == 1) {
    1
  } else {
    2
  }
}

///|
fn entry_style_diff(entry : FontEntry, req_style : @moon_swash.Style) -> Int {
  style_diff(entry.attributes.style(), req_style)
}

///|
fn better_font_match(
  cand : (Int, Bool, Int, Int, Int, Int, Int),
  best : (Int, Bool, Int, Int, Int, Int, Int),
) -> Bool {
  let cand_id = cand.0
  let cand_not_emoji = cand.1
  let cand_wdiff = cand.2
  let cand_stretch_diff = cand.3
  let cand_style_diff = cand.4
  let cand_weight = cand.5
  let cand_stretch = cand.6
  let best_id = best.0
  let best_not_emoji = best.1
  let best_wdiff = best.2
  let best_stretch_diff = best.3
  let best_style_diff = best.4
  let best_weight = best.5
  let best_stretch = best.6
  if cand_not_emoji != best_not_emoji {
    // Keep the same ordering semantics as reference `FontMatchKey` derived Ord.
    return !cand_not_emoji
  }
  if cand_wdiff != best_wdiff {
    return cand_wdiff < best_wdiff
  }
  if cand_stretch_diff != best_stretch_diff {
    return cand_stretch_diff < best_stretch_diff
  }
  if cand_style_diff != best_style_diff {
    return cand_style_diff < best_style_diff
  }
  if cand_weight != best_weight {
    return cand_weight < best_weight
  }
  if cand_stretch != best_stretch {
    return cand_stretch < best_stretch
  }
  cand_id < best_id
}

///|
fn build_font_matches(fs : FontSystem, attrs : Attrs) -> Array[Int] {
  let family = attrs.family_value()
  let req_weight = attrs.weight_value()
  let req_stretch = attrs.stretch_value()
  let req_style = attrs.style_value()
  let candidates : Array[(Int, Bool, Int, Int, Int, Int, Int)] = []
  for e in fs.fonts {
    candidates.push(
      (
        e.id,
        e.not_emoji,
        entry_weight_diff(e, req_weight),
        entry_stretch_diff(e, req_stretch),
        entry_style_diff(e, req_style),
        entry_weight_raw(e),
        entry_stretch_raw(e),
      ),
    )
  }
  let n = candidates.length()
  let used : Array[Bool] = Array::makei(n, _ => false)
  let ids : Array[Int] = []
  for _ in 0..<n {
    let mut best_i = -1
    for i in 0..<n {
      if used[i] {
        continue
      }
      if best_i < 0 || better_font_match(candidates[i], candidates[best_i]) {
        best_i = i
      }
    }
    if best_i >= 0 {
      used.set(best_i, true)
      ids.push(candidates[best_i].0)
    }
  }

  // Keep candidate ordering close to upstream:
  // sort globally by match score, then move query best family match to front.
  let mut preferred : (Int, Bool, Int, Int, Int, Int, Int)? = None
  for e in fs.fonts {
    if !family_matches(e, family) {
      continue
    }
    let cand = (
      e.id,
      e.not_emoji,
      entry_weight_diff(e, req_weight),
      entry_stretch_diff(e, req_stretch),
      entry_style_diff(e, req_style),
      entry_weight_raw(e),
      entry_stretch_raw(e),
    )
    match preferred {
      None => preferred = Some(cand)
      Some(best) => if better_font_match(cand, best) { preferred = Some(cand) }
    }
  }

  match preferred {
    None => move_forbidden_candidates_to_end(fs, family, ids)
    Some(best) => {
      let pid = best.0
      if ids.length() == 0 || ids[0] == pid {
        return move_forbidden_candidates_to_end(fs, family, ids)
      }
      let reordered : Array[Int] = [pid]
      for id in ids {
        if id != pid {
          reordered.push(id)
        }
      }
      move_forbidden_candidates_to_end(fs, family, reordered)
    }
  }
}

///|
fn get_font_matches(fs : FontSystem, attrs : Attrs) -> Array[Int] {
  if fs.font_matches_cache.length() >= FONT_MATCHES_CACHE_SIZE_LIMIT {
    fs.font_matches_cache.clear()
  }
  let key = FontMatchAttrs::{
    family: attrs.family_value(),
    weight: attrs.weight_value(),
    stretch: attrs.stretch_value(),
    style: attrs.style_value(),
  }
  match fs.font_matches_cache.get(key) {
    Some(ids) => ids
    None => {
      let ids = build_font_matches(fs, attrs)
      fs.font_matches_cache.set(key, ids)
      ids
    }
  }
}

///|
/// Get ordered font match candidates for attrs (cached).
pub fn FontSystem::font_matches(self : FontSystem, attrs : Attrs) -> Array[Int] {
  get_font_matches(self, attrs)
}

///|
fn select_family_with_weight(
  fs : FontSystem,
  family : Family,
  req_weight : Weight,
) -> Int? {
  let attrs = Attrs::new().family(family).weight(req_weight)
  let ids = get_font_matches(fs, attrs)
  for id in ids {
    if id >= 0 && id < fs.fonts.length() && family_matches(fs.fonts[id], family) {
      return Some(id)
    }
  }
  None
}

///|
/// Resolve a font ID for a specific codepoint (best-effort).
///
/// This prefers the requested family (when present) and then minimizes weight
/// difference, falling back to any loaded font that supports the codepoint.
pub fn FontSystem::resolve_for_codepoint(
  self : FontSystem,
  attrs : Attrs,
  codepoint : UInt,
) -> Int? {
  let matches = get_font_matches(self, attrs)
  for id in matches {
    if id < 0 || id >= self.fonts.length() {
      continue
    }
    let e = self.fonts[id]
    if font_maps_codepoint(self, e, codepoint) {
      return Some(id)
    }
  }
  self.resolve(attrs)
}

///|
/// Resolve a font ID for the given attrs (best-effort).
pub fn FontSystem::resolve(self : FontSystem, attrs : Attrs) -> Int? {
  let matches = get_font_matches(self, attrs)
  if matches.length() > 0 {
    Some(matches[0])
  } else if self.fonts.length() > 0 {
    Some(0)
  } else {
    None
  }
}

///|
pub fn FontSystem::get_font(
  self : FontSystem,
  font_id : Int,
) -> @moon_swash.FontRef? {
  if font_id < 0 || font_id >= self.fonts.length() {
    return None
  }
  Some(self.fonts[font_id].font)
}

///|
/// Get the full FontEntry for a font_id (useful for downstream rasterization with TTC collections).
pub fn FontSystem::get_font_entry(
  self : FontSystem,
  font_id : Int,
) -> FontEntry? {
  if font_id < 0 || font_id >= self.fonts.length() {
    return None
  }
  Some(self.fonts[font_id])
}
