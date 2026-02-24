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
test "Buffer.set_text splits lines using LineIter endings" {
  let buf0 = Buffer::new(Metrics::new(12.0F, 14.0F))
  let attrs = AttrsList::new(Attrs::new())
  let buf1 = buf0.set_text("A\nB\r\nC", attrs, Advanced)
  let lines = buf1.lines()
  inspect(lines.length(), content="3")
  inspect(lines[0].text(), content="A")
  inspect(lines[0].ending().as_str(), content="\n")
  inspect(lines[1].text(), content="B")
  inspect(lines[1].ending().as_str(), content="\r\n")
  inspect(lines[2].text(), content="C")
  inspect(lines[2].ending().as_str(), content="")
}

///|
test "Buffer.set_text ensures a trailing LineEnding::None line (upstream behavior)" {
  let buf0 = Buffer::new(Metrics::new(12.0F, 14.0F))
  let attrs = AttrsList::new(Attrs::new())
  let buf1 = buf0.set_text("A\n", attrs, Advanced)
  let lines = buf1.lines()
  inspect(lines.length(), content="2")
  inspect(lines[0].text(), content="A")
  inspect(lines[0].ending().as_str(), content="\n")
  inspect(lines[1].text(), content="")
  inspect(lines[1].ending().as_str(), content="")
}

///|
test "Buffer.set_text empty text produces one empty LineEnding::None line" {
  let buf0 = Buffer::new(Metrics::new(12.0F, 14.0F))
  let attrs = AttrsList::new(Attrs::new())
  let buf1 = buf0.set_text("", attrs, Advanced)
  let lines = buf1.lines()
  inspect(lines.length(), content="1")
  inspect(lines[0].text(), content="")
  inspect(lines[0].ending().as_str(), content="")
}

///|
test "Buffer.set_rich_text builds per-line AttrsList spans and uses default line ending" {
  let bold = Attrs::new().weight(Weight::bold())
  let spans : Array[(String, Attrs)] = [
    ("a", bold),
    ("b\nc", Attrs::new()),
    ("d", bold),
  ]
  let buf = Buffer::new(Metrics::new(12.0F, 14.0F)).set_rich_text(
    spans,
    Attrs::new(),
    Advanced,
    Some(Align::Center),
  )
  let lines = buf.lines()
  inspect(lines.length(), content="2")
  inspect(lines[0].text(), content="ab")
  inspect(lines[1].text(), content="cd")
  // set_rich_text uses LineEnding::default() (LF) for all lines.
  inspect(lines[0].ending().as_str(), content="\n")
  inspect(lines[1].ending().as_str(), content="\n")

  // Alignment is applied to all lines.
  inspect(
    match lines[0].align() {
      Some(Center) => true
      _ => false
    },
    content="true",
  )

  // Attrs spans are relative to each line.
  inspect(lines[0].attrs_list().get_span(0) == bold, content="true")
  inspect(lines[0].attrs_list().get_span(1) == Attrs::new(), content="true")
  inspect(lines[1].attrs_list().get_span(0) == Attrs::new(), content="true")
  inspect(lines[1].attrs_list().get_span(1) == bold, content="true")
}

///|
test "Buffer.set_size marks redraw on change" {
  let buf0 = Buffer::new(Metrics::new(12.0F, 14.0F))
  let buf1 = buf0.set_size(Some(100.0F), None)
  inspect(buf1.redraw(), content="true")
}

///|
test "Buffer defaults align with upstream new_empty" {
  let buf0 = Buffer::new_empty(Metrics::new(12.0F, 14.0F))
  inspect(buf0.redraw(), content="false")
  inspect(
    match buf0.wrap() {
      WordOrGlyph => true
      _ => false
    },
    content="true",
  )
  inspect(buf0.tab_width, content="8")
  inspect(
    match buf0.hinting() {
      Disabled => true
      _ => false
    },
    content="true",
  )
  inspect(buf0.scroll().line, content="0")
}

///|
test "Buffer.layout_runs returns no runs before layout cache is built" {
  let attrs = AttrsList::new(Attrs::new())
  let buf = Buffer::new(Metrics::new(12.0F, 14.0F)).set_text(
    "A\nB",
    attrs,
    Advanced,
  )
  let mut runs = 0
  for _ in buf.layout_runs() {
    runs = runs + 1
  }
  inspect(runs, content="0")
}

///|
test "Buffer setters mark redraw when value changes" {
  let buf0 = Buffer::new_empty(Metrics::new(12.0F, 14.0F))
  let buf1 = buf0.set_wrap(Wrap::Glyph)
  inspect(buf1.redraw(), content="true")
  let buf2 = buf1.set_tab_width(2)
  inspect(buf2.redraw(), content="true")
  let buf3 = buf2.set_hinting(Hinting::Enabled)
  inspect(buf3.redraw(), content="true")
  let buf4 = buf3.set_monospace_width(Some(8.0F))
  inspect(buf4.redraw(), content="true")
  let buf5 = buf4.set_metrics(Metrics::new(13.0F, 15.0F))
  inspect(buf5.redraw(), content="true")
}

///|
test "Buffer.set_wrap invalidates cached layout and relayout reflects new wrap mode" {
  let attrs = AttrsList::new(Attrs::new())
  let mut buf = Buffer::new(Metrics::new(12.0F, 14.0F))
  buf = buf
    .set_text("a a a a a a", attrs, Advanced)
    .set_size(Some(24.0F), None)
    .set_wrap(Wrap::None)
    .layout_all()

  let mut runs_none = 0
  for _ in buf.layout_runs() {
    runs_none = runs_none + 1
  }

  let buf2 = buf.set_wrap(Wrap::WordOrGlyph).layout_all()
  let mut runs_wrap = 0
  for _ in buf2.layout_runs() {
    runs_wrap = runs_wrap + 1
  }
  inspect(runs_none == 1, content="true")
  inspect(runs_wrap > runs_none, content="true")
}

///|
test "Buffer.set_size clamps negative width/height to zero" {
  let buf = Buffer::new(Metrics::new(12.0F, 14.0F)).set_size(
    Some(-5.0F),
    Some(-10.0F),
  )
  inspect(
    match buf.size().0 {
      Some(v) => v == 0.0F
      None => false
    },
    content="true",
  )
  inspect(
    match buf.size().1 {
      Some(v) => v == 0.0F
      None => false
    },
    content="true",
  )
}

///|
test "Buffer.layout_runs follows scroll line and viewport height" {
  let attrs = AttrsList::new(Attrs::new())
  let mut buf = Buffer::new(Metrics::new(12.0F, 14.0F))
  buf = buf
    .set_text("A\nB\nC", attrs, Advanced)
    .set_size(Some(200.0F), Some(14.0F))
    .layout_all()

  let vis0 : Array[Int] = []
  for run in buf.layout_runs() {
    vis0.push(run.line_i)
  }
  inspect(vis0, content="[0]")

  let buf1 = buf.set_scroll(Scroll::new(1, 0.0F, 0.0F)).layout_all()
  let vis1 : Array[Int] = []
  for run in buf1.layout_runs() {
    vis1.push(run.line_i)
  }
  inspect(vis1, content="[1]")
}

///|
test "wrap_word_fallback: layout_runs never overflow width (MVP)" {
  let metrics = Metrics::new(14.0F, 20.0F)
  let mut buffer = Buffer::new(metrics)
  buffer = buffer.set_wrap(Wrap::WordOrGlyph)
  buffer = buffer.set_text(
    "Lorem ipsum dolor sit amet, qui minim labore adipisicing minim sint cillum sint consectetur cupidatat.",
    AttrsList::new(Attrs::new()),
    Advanced,
  )
  buffer = buffer.set_size(Some(50.0F), Some(1000.0F))
  buffer = buffer.layout_all()
  let mut measured = 0.0F
  for run in buffer.layout_runs() {
    if run.line_w > measured {
      measured = run.line_w
    }
  }
  let w = if buffer.size().0 is Some(v) { v } else { 0.0F }
  inspect(measured <= w, content="true")
}

///|
/// Reference: `cosmic-text-reference/tests/wrap_stability.rs` (wrap_extra_line).
///
/// This requires real font metrics (Inter-Regular.ttf). We embed the font bytes for parity.
test "wrap_extra_line: matches upstream empty/overflow line counts" {
  let metrics = Metrics::new(14.0F, 20.0F)
  let mut buffer = Buffer::new(metrics)
  buffer = buffer.set_wrap(Wrap::Word)
  buffer = buffer.set_text(
    "Lorem ipsum dolor sit amet, qui minim labore adipisicing\n\nweeewoooo minim sint cillum sint consectetur cupidatat.",
    AttrsList::new(Attrs::new().family(Name("Inter"))),
    Advanced,
  )
  buffer = buffer.set_size(Some(50.0F), Some(1000.0F))
  let font_system = FontSystem::new().load_font_data(
    test_font_inter_regular_ttf(),
  )
  buffer = buffer.layout_all_with_font_system(font_system)
  let mut empty_lines = 0
  let mut overflow_lines = 0
  for run in buffer.layout_runs() {
    if run.line_w == 0.0F {
      empty_lines = empty_lines + 1
    }
    if run.line_w > 50.0F {
      overflow_lines = overflow_lines + 1
    }
  }
  inspect(empty_lines, content="1")
  inspect(overflow_lines, content="4")
}

///|
test "Buffer.draw is a naming-aligned wrapper (smoke)" {
  let metrics = Metrics::new(12.0F, 14.0F)
  let attrs = AttrsList::new(Attrs::new())
  let buffer0 = Buffer::new(metrics)
    .set_text("A", attrs, Advanced)
    .set_size(Some(100.0F), None)
  let font_system = FontSystem::new()
  let cache = SwashCache::new()
  let (buffer1, _cache) = buffer0.draw(
    font_system,
    cache,
    Color::rgb(0, 0, 0),
    fn(_, _, _, _, _) { () },
  )
  let has_layout = if buffer1.lines()[0].layout_opt() is Some(_) {
    true
  } else {
    false
  }
  inspect(has_layout, content="true")
}
