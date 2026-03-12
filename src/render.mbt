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
/// Helpers for rendering buffers and editors.
///
/// Ported from `cosmic-text/src/render.rs`.

///|
/// Custom renderer for buffers and editors.
pub(open) trait Renderer {
  /// Render a rectangle at x, y with size w, h and the provided `Color`.
  rectangle(Self, x : Int, y : Int, w : UInt, h : UInt, color : Color) -> Unit

  /// Render a `PhysicalGlyph` with the provided `Color`.
  ///
  /// For performance, consider using `SwashCache` directly.
  glyph(Self, physical_glyph : PhysicalGlyph, color : Color) -> Unit
}

///|
fn minf(a : Float, b : Float) -> Float {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn maxf(a : Float, b : Float) -> Float {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn render_int_from_float(v : Float) -> Int {
  v.to_double().to_int()
}

///|
fn render_uint_from_float(v : Float) -> UInt {
  if v <= 0.0F {
    0U
  } else {
    v.to_double().to_int().reinterpret_as_uint()
  }
}

///|
fn pick_decoration_color(
  span_color_opt : Color?,
  override_color_opt : Color?,
  default_color : Color,
) -> Color {
  match override_color_opt {
    Some(c) => c
    None =>
      match span_color_opt {
        Some(c) => c
        None => default_color
      }
  }
}

///|
fn deco_thickness(v : Float) -> Float {
  let t = if v < 1.0F { 1.0F } else { v }
  Float::from_double(t.to_double().ceil())
}

///|
fn[R : Renderer] draw_decoration_span(
  renderer : R,
  run : LayoutRun,
  span : DecorationSpan,
  default_color : Color,
) -> Unit {
  let glyph_count = run.glyphs.length()
  if glyph_count == 0 {
    return
  }
  let start = if span.glyph_start < 0 {
    0
  } else if span.glyph_start > glyph_count {
    glyph_count
  } else {
    span.glyph_start
  }
  let end = if span.glyph_end < start {
    start
  } else if span.glyph_end > glyph_count {
    glyph_count
  } else {
    span.glyph_end
  }
  if end <= start {
    return
  }

  let mut x_min = run.glyphs[start].x
  let mut x_max = run.glyphs[start].x + run.glyphs[start].w
  for i in start..<end {
    let g = run.glyphs[i]
    x_min = minf(x_min, g.x)
    x_max = maxf(x_max, g.x + g.w)
  }
  let width = x_max - x_min
  if width <= 0.0F {
    return
  }
  let w = render_uint_from_float(width)
  if w == 0U {
    return
  }
  let x_start = render_int_from_float(x_min)
  let deco = span.data
  let td = deco.text_decoration
  let font_size = span.font_size

  match td.underline {
    UnderlineStyle::None => ()
    UnderlineStyle::Single => {
      let color = pick_decoration_color(
        span.color_opt,
        td.underline_color_opt,
        default_color,
      )
      let thickness = deco_thickness(
        deco.underline_metrics.thickness * font_size,
      )
      let y = run.line_y - deco.underline_metrics.offset * font_size
      renderer.rectangle(
        x_start,
        render_int_from_float(y),
        w,
        render_uint_from_float(thickness),
        color,
      )
    }
    UnderlineStyle::Double => {
      let color = pick_decoration_color(
        span.color_opt,
        td.underline_color_opt,
        default_color,
      )
      let thickness = deco_thickness(
        deco.underline_metrics.thickness * font_size,
      )
      let gap = thickness
      let y = run.line_y - deco.underline_metrics.offset * font_size
      renderer.rectangle(
        x_start,
        render_int_from_float(y),
        w,
        render_uint_from_float(thickness),
        color,
      )
      renderer.rectangle(
        x_start,
        render_int_from_float(y + thickness + gap),
        w,
        render_uint_from_float(thickness),
        color,
      )
    }
  }

  if td.strikethrough {
    let color = pick_decoration_color(
      span.color_opt,
      td.strikethrough_color_opt,
      default_color,
    )
    let thickness = deco_thickness(
      deco.strikethrough_metrics.thickness * font_size,
    )
    let y = run.line_y - deco.strikethrough_metrics.offset * font_size
    renderer.rectangle(
      x_start,
      render_int_from_float(y),
      w,
      render_uint_from_float(thickness),
      color,
    )
  }

  if td.overline {
    let color = pick_decoration_color(
      span.color_opt,
      td.overline_color_opt,
      default_color,
    )
    let thickness = deco_thickness(deco.underline_metrics.thickness * font_size)
    let y = maxf(run.line_y - deco.ascent * font_size, run.line_top)
    renderer.rectangle(
      x_start,
      render_int_from_float(y),
      w,
      render_uint_from_float(thickness),
      color,
    )
  }
}

///|
/// Draw text decoration lines (underline, strikethrough, overline) for a layout run.
pub fn[R : Renderer] render_decoration(
  renderer : R,
  run : LayoutRun,
  default_color : Color,
) -> Unit {
  for span in run.decorations {
    draw_decoration_span(renderer, run, span, default_color)
  }
}

///|
/// Helper to migrate from the legacy callback-based renderer.
///
/// This matches upstream `LegacyRenderer`: rectangles are forwarded to the callback,
/// and glyphs are rasterized through `SwashCache::with_pixels`.
pub struct LegacyRenderer {
  font_system : FontSystem
  cache : SwashCache
  callback : (Int, Int, UInt, UInt, Color) -> Unit

  fn new(
    font_system : FontSystem,
    cache : SwashCache,
    callback : (Int, Int, UInt, UInt, Color) -> Unit,
  ) -> LegacyRenderer
}

///|
pub fn LegacyRenderer::new(
  font_system : FontSystem,
  cache : SwashCache,
  callback : (Int, Int, UInt, UInt, Color) -> Unit,
) -> LegacyRenderer {
  LegacyRenderer::{ font_system, cache, callback }
}

///|
pub impl Renderer for LegacyRenderer with rectangle(self, x, y, w, h, color) {
  (self.callback)(x, y, w, h, color)
}

///|
pub impl Renderer for LegacyRenderer with glyph(self, physical_glyph, color) {
  self.cache.with_pixels(self.font_system, physical_glyph.cache_key, color, fn(
    px,
    py,
    pixel_color,
  ) {
    (self.callback)(
      physical_glyph.x + px,
      physical_glyph.y + py,
      1U,
      1U,
      pixel_color,
    )
  })
}
