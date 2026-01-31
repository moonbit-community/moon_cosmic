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
test "per-span metrics override affects glyph font_size, widths, and line_height" {
  let default_metrics = Metrics::new(10.0F, 12.0F)
  let big_metrics = Metrics::new(20.0F, 30.0F)
  let a0 = Attrs::new()
  let a1 = Attrs::new().metrics(big_metrics)
  let attrs_list = AttrsList::new(a0).add_span(1, 2, a1)
  let line0 = BufferLine::new(
    "ab",
    LineEnding::None,
    attrs_list,
    Shaping::Basic,
  )
  let line1 = line0.layout(
    default_metrics.font_size,
    None,
    Wrap::None,
    None,
    8,
    Hinting::Disabled,
  )
  let layout = if line1.layout_opt() is Some(v) { v } else { [] }
  inspect(layout.length(), content="1")
  inspect(layout[0].line_height_opt, content="Some(30)")
  let gs = layout[0].glyphs
  inspect(gs.length(), content="2")
  // First glyph uses default metrics, second uses override.
  inspect((gs[0].font_size, gs[1].font_size), content="(10, 20)")
  inspect((gs[0].w, gs[1].w), content="(10, 20)")
  inspect(
    (gs[0].line_height_opt, gs[1].line_height_opt),
    content="(None, Some(30))",
  )
}
