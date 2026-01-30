# Milky2018/moon_cosmic

MoonBit port of Rust `cosmic-text` (text shaping, layout, and editor primitives), built on top of `Milky2018/moon_swash`.

This repo includes `./cosmic-text-reference` (the upstream Rust reference) and keeps behavior aligned via tests where feasible.

## Features

- **Font system (in-memory)**: load TTF/OTF/TTC bytes; resolve fonts by family + weight; per-codepoint fallback.
- **Shaping**: `Shaping::Advanced` uses `moon_swash/shape` to produce clustered glyphs and advances; tabs snap to stops.
- **Wrapping & layout**: `Wrap::{None,Glyph,Word,WordOrGlyph}`, `Align::{Left,Right,Center,Justified,End}`, hinting.
- **BiDi**: paragraph iteration + embedding levels and **visual reordering** of glyph runs.
- **Raster cache**: `CacheKey` + `SwashCache` backed by `moon_swash/scale` (variable `wght` axis support; fake-italic transform).
- **Editor primitives**: `Buffer`, `Editor`, cursor/selection, hit-testing, and motion actions.

## Install

Add dependency:

```bash
moon add Milky2018/moon_cosmic
```

## Quick Start (Layout)

```mbt
import Milky2018/moon_cosmic

fn main {
  // Provide font bytes from your host app (file I/O is app-specific).
  let font_bytes : Bytes = /* ... */

  let font_system = FontSystem::new().load_font_data(font_bytes)
  let metrics = Metrics::new(14.0F, 20.0F)

  let attrs = Attrs::new().family(Family::Name("Inter"))
  let attrs_list = AttrsList::new(attrs)

  let buffer = Buffer::new(metrics)
    .set_wrap(Wrap::WordOrGlyph)
    .set_text("Hello world", attrs_list, Shaping::Advanced)
    .set_size(Some(200.0F), None)
    .layout_all_with_font_system(font_system)

  for run in buffer.layout_runs() {
    // `run.glyphs`: Array[LayoutGlyph]
    // `run.line_w`: line width in pixels
    ignore(run)
  }
}
```

## Quick Start (Draw)

`Buffer::draw` renders via a callback (pixel-oriented for compatibility with the legacy renderer pattern).

```mbt
import Milky2018/moon_cosmic

fn draw_demo(font_bytes : Bytes) -> Unit {
  let font_system = FontSystem::new().load_font_data(font_bytes)
  let cache = SwashCache::new()

  let buffer = Buffer::new(Metrics::new(14.0F, 20.0F))
    .set_text("Hi!", AttrsList::new(Attrs::new()), Shaping::Advanced)
    .set_size(Some(200.0F), None)

  let (_buffer, _cache) = buffer.draw(
    font_system,
    cache,
    Color::rgb(0, 0, 0),
    fn(_x, _y, _w, _h, _color) { () },
  )
}
```

## Dev Workflow

Common commands:

```bash
moon check        # Lint/type-check
moon test         # Run tests
moon fmt          # Format
moon info         # Update .mbti
moon info && moon fmt
```

## Test Font Blob

Some parity tests require real font metrics. This repo embeds `Inter-Regular.ttf` into `src/test_fonts_test.mbt` (base64).

To regenerate it (if the reference font changes):

```bash
python3 scripts/gen_test_font_mbt.py
moon fmt
moon test
```

## License

Apache-2.0. Upstream `cosmic-text` is MIT OR Apache-2.0; see `./cosmic-text-reference` for details.
