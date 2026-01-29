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
test "LayoutGlyph::physical computes CacheKey subpixel bins" {
  let g = LayoutGlyph::new(0, 1, 10.0F, 7, 400, 42, 1.125F, 2.75F, 0.0F, 0)
  let p = g.physical((0.0F, 0.0F), 1.0F)
  inspect((p.x, p.y), content="(1, 2)")
  // 1.125 -> (1, One); 2.0 (truncated from 2.75) -> (2, Zero)
  inspect((p.cache_key.x_bin(), p.cache_key.y_bin()), content="(One, Zero)")
}
