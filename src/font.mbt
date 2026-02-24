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
  font : @moon_swash.FontRef
  charmap_proxy : @moon_swash.CharmapProxy
  attributes : @moon_swash.Attributes
  is_monospace : Bool
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
pub struct FontSystem {
  locale : String
  fonts : Array[FontEntry]
  font_matches_cache : @hashmap.HashMap[FontMatchAttrs, Array[Int]]
  codepoint_support_cache : @hashmap.HashMap[FontCodepointKey, Bool]
}

///|
const FONT_MATCHES_CACHE_SIZE_LIMIT : Int = 256

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
        let metrics = f.metrics([])
        fonts.push(FontEntry::{
          id,
          family_name,
          font: f,
          charmap_proxy: @moon_swash.CharmapProxy::from_font(f),
          attributes: f.attributes(),
          is_monospace: metrics.is_monospace,
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
pub struct FontCodepointKey {
  font_id : Int
  codepoint : UInt
}

///|
pub impl Eq for FontCodepointKey with equal(self, other) {
  self.font_id == other.font_id && self.codepoint == other.codepoint
}

///|
pub impl Hash for FontCodepointKey with hash_combine(self, hasher) {
  hasher.combine_int(self.font_id)
  hasher.combine_uint(self.codepoint)
}

///|
pub struct FontMatchAttrs {
  family : Family
  weight : Weight
}

///|
pub impl Eq for FontMatchAttrs with equal(self, other) {
  self.family == other.family && self.weight == other.weight
}

///|
pub impl Hash for FontMatchAttrs with hash_combine(self, hasher) {
  self.family.hash_combine(hasher)
  self.weight.hash_combine(hasher)
}

///|
fn family_matches(entry : FontEntry, family : Family) -> Bool {
  match family {
    Name(name) => entry.family_name == name
    Monospace => entry.is_monospace
    _ => true
  }
}

///|
fn font_maps_codepoint(
  fs : FontSystem,
  entry : FontEntry,
  codepoint : UInt,
) -> Bool {
  let key = FontCodepointKey::{ font_id: entry.id, codepoint }
  match fs.codepoint_support_cache.get(key) {
    Some(ok) => ok
    None => {
      let cm = entry.charmap_proxy.materialize(entry.font)
      let ok = cm.map(codepoint) != 0
      fs.codepoint_support_cache.set(key, ok)
      ok
    }
  }
}

///|
fn entry_weight_diff(entry : FontEntry, req_weight : Weight) -> Int {
  let a = entry.attributes.weight().value.to_int()
  abs_int(a - req_weight.value)
}

///|
fn better_font_match(cand : (Int, Bool, Int), best : (Int, Bool, Int)) -> Bool {
  let cand_id = cand.0
  let cand_family = cand.1
  let cand_wdiff = cand.2
  let best_id = best.0
  let best_family = best.1
  let best_wdiff = best.2
  if cand_family != best_family {
    return cand_family
  }
  if cand_wdiff != best_wdiff {
    return cand_wdiff < best_wdiff
  }
  cand_id < best_id
}

///|
fn build_font_matches(fs : FontSystem, attrs : Attrs) -> Array[Int] {
  let family = attrs.family_value()
  let req_weight = attrs.weight_value()
  let candidates : Array[(Int, Bool, Int)] = []
  for e in fs.fonts {
    candidates.push(
      (e.id, family_matches(e, family), entry_weight_diff(e, req_weight)),
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
  ids
}

///|
fn get_font_matches(fs : FontSystem, attrs : Attrs) -> Array[Int] {
  if fs.font_matches_cache.length() >= FONT_MATCHES_CACHE_SIZE_LIMIT {
    fs.font_matches_cache.clear()
  }
  let key = FontMatchAttrs::{
    family: attrs.family_value(),
    weight: attrs.weight_value(),
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
