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
/// Cache for shaped runs (ported from `cosmic-text/src/shape_run_cache.rs`).

///|
/// Key for caching shape runs.
pub struct ShapeRunKey {
  text : String
  default_attrs : Attrs
  attrs_spans : Array[(Int, Int, Attrs)]
}

///|
pub fn ShapeRunKey::new(text : String, attrs_list : AttrsList) -> ShapeRunKey {
  let default_attrs = attrs_list.defaults()
  let spans : Array[(Int, Int, Attrs)] = []
  for s in attrs_list.spans_iter() {
    if s.attrs != default_attrs {
      spans.push((s.start, s.end, s.attrs))
    }
  }
  ShapeRunKey::{ text, default_attrs, attrs_spans: spans }
}

///|
pub impl Eq for ShapeRunKey with equal(self, other) {
  if self.text != other.text ||
    self.default_attrs != other.default_attrs ||
    self.attrs_spans.length() != other.attrs_spans.length() {
    return false
  }
  for i in 0..<self.attrs_spans.length() {
    if self.attrs_spans[i].0 != other.attrs_spans[i].0 ||
      self.attrs_spans[i].1 != other.attrs_spans[i].1 ||
      self.attrs_spans[i].2 != other.attrs_spans[i].2 {
      return false
    }
  }
  true
}

///|
pub impl Hash for ShapeRunKey with hash_combine(self, hasher) {
  hasher.combine_string(self.text)
  self.default_attrs.hash_combine(hasher)
  hasher.combine_int(self.attrs_spans.length())
  for s in self.attrs_spans {
    hasher.combine_int(s.0)
    hasher.combine_int(s.1)
    s.2.hash_combine(hasher)
  }
}

///|
/// A helper structure for caching shape runs.
pub struct ShapeRunCache {
  mut age : UInt64
  cache : @hashmap.HashMap[ShapeRunKey, (UInt64, Array[ShapeGlyph])]
}

///|
pub fn ShapeRunCache::new() -> ShapeRunCache {
  ShapeRunCache::{ age: 0UL, cache: @hashmap.HashMap::default() }
}

///|
/// Get a cache item, updating age if found.
pub fn ShapeRunCache::get(
  self : ShapeRunCache,
  key : ShapeRunKey,
) -> Array[ShapeGlyph]? {
  match self.cache.get(key) {
    None => None
    Some((_, glyphs)) => {
      self.cache.set(key, (self.age, glyphs))
      Some(glyphs)
    }
  }
}

///|
/// Peek a cache item without updating its age.
pub fn ShapeRunCache::peek(
  self : ShapeRunCache,
  key : ShapeRunKey,
) -> Array[ShapeGlyph]? {
  match self.cache.get(key) {
    None => None
    Some((_, glyphs)) => Some(glyphs)
  }
}

///|
/// Insert a cache item with current age.
pub fn ShapeRunCache::insert(
  self : ShapeRunCache,
  key : ShapeRunKey,
  glyphs : Array[ShapeGlyph],
) -> Unit {
  self.cache.set(key, (self.age, glyphs))
}

///|
/// Clear all cached runs.
pub fn ShapeRunCache::clear(self : ShapeRunCache) -> Unit {
  self.cache.clear()
}

///|
/// Remove anything in the cache with an age older than `keep_ages`.
pub fn ShapeRunCache::trim(self : ShapeRunCache, keep_ages : UInt64) -> Unit {
  let entries = self.cache.to_array()
  for e in entries {
    let (k, v) = e
    let age = v.0
    if age + keep_ages < self.age {
      self.cache.remove(k)
    }
  }
  self.age = self.age + 1UL
}

///|
pub impl Show for ShapeRunCache with output(_self, logger) {
  logger.write_string("ShapeRunCache { .. }")
}
