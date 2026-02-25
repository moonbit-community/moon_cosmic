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
test "ShapeRunCache: get updates age and trim evicts old entries" {
  fn mk_key() -> ShapeRunKey {
    ShapeRunKey::new("abc", AttrsList::new(Attrs::new()))
  }

  let cache = ShapeRunCache::new()
  cache.insert(mk_key(), [
    ShapeGlyph::new(0, 1, 1.0F, 0.0F, 0.0F, 0.0F, 0, 1, 0),
  ])

  // First trim: nothing is older than age 0.
  cache.trim(0UL)
  inspect(cache.peek(mk_key()) is Some(_), content="true")

  // Refresh the entry so it survives the next trim.
  inspect(cache.get(mk_key()) is Some(_), content="true")

  // After another trim with keep_ages=0, entry stays because get refreshed its age.
  cache.trim(0UL)
  inspect(cache.peek(mk_key()) is Some(_), content="true")

  // Now stop touching it; it should be evicted after the next trim.
  cache.trim(0UL)
  inspect(cache.peek(mk_key()) is Some(_), content="false")
}

///|
test "ShapeRunKey::new ignores spans equal to defaults" {
  let defaults = Attrs::new()
  let plain = AttrsList::new(defaults)
  let with_default_span = AttrsList::new(defaults).add_span(0, 2, defaults)
  let key_plain = ShapeRunKey::new("ab", plain)
  let key_with_default_span = ShapeRunKey::new("ab", with_default_span)
  inspect(key_plain == key_with_default_span, content="true")
}
