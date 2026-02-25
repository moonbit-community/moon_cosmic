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
test "BufferLine.set_text returns changed flag" {
  let defaults = Attrs::new()
  let attrs = AttrsList::new(defaults)
  let line0 = BufferLine::new("abc", Lf, attrs, Advanced)
  let (line1, changed1) = line0.set_text("abc", Lf, attrs)
  inspect(changed1, content="false")
  inspect(line1.text(), content="abc")
  let (line2, changed2) = line1.set_text("abcd", Lf, attrs)
  inspect(changed2, content="true")
  inspect(line2.text(), content="abcd")
}

///|
test "BufferLine.set_align returns changed only on value change" {
  let attrs = AttrsList::new(Attrs::new())
  let line0 = BufferLine::new("abc", Lf, attrs, Advanced)
  let (line1, changed1) = line0.set_align(None)
  inspect(changed1, content="false")
  let (line2, changed2) = line1.set_align(Some(Align::Center))
  inspect(changed2, content="true")
  let (line3, changed3) = line2.set_align(Some(Align::Center))
  inspect(changed3, content="false")
  let (line4, changed4) = line3.set_align(Some(Align::Left))
  inspect(changed4, content="true")
  inspect(
    match line4.align() {
      Some(Left) => true
      _ => false
    },
    content="true",
  )
}

///|
test "BufferLine.split_off follows upstream ending/align rules" {
  let attrs = AttrsList::new(Attrs::new())
  let line0 = BufferLine::new("hello", CrLf, attrs, Advanced)
  let (left, right) = line0.split_off(2)
  inspect(left.text(), content="he")
  inspect(left.ending().as_str(), content="")
  inspect(right.text(), content="llo")
  inspect(right.ending().as_str(), content="\r\n")
}

///|
test "BufferLine.set_ending invalidates shaping cache" {
  let attrs = AttrsList::new(Attrs::new())
  let line0 = BufferLine::new("abc", Lf, attrs, Advanced)
  let line1 = line0
    .shape(4)
    .layout(10.0F, Some(100.0F), Wrap::None, None, 4, Hinting::Disabled)
  inspect(
    match line1.shape_opt() {
      Some(_) => true
      _ => false
    },
    content="true",
  )
  let line2 = line1.set_ending(CrLf)
  inspect(
    match line2.shape_opt() {
      None => true
      _ => false
    },
    content="true",
  )
}

///|
test "BufferLine.append concatenates text and shifts spans" {
  let a0 = AttrsList::new(Attrs::new()).add_span(0, 1, Attrs::with_metadata(1))
  let b0 = AttrsList::new(Attrs::with_metadata(9)).add_span(
    0,
    1,
    Attrs::with_metadata(2),
  )
  let line0 = BufferLine::new("A", Lf, a0, Advanced)
  let line1 = BufferLine::new("B", None, b0, Advanced)
  let out = line0.append(line1)
  inspect(out.text(), content="AB")
  inspect(out.ending().as_str(), content="")
  // "B" comes from other defaults (metadata=9), and shifted span overrides at pos 1.
  inspect(out.attrs_list().get_span(1).metadata(), content="2")
}

///|
test "BufferLine.shape builds 1 glyph per code unit (tab uses tab_width cells)" {
  let attrs = AttrsList::new(Attrs::new())
  let line0 = BufferLine::new("a\tb", Lf, attrs, Advanced)
  let line1 = line0.shape(4)
  if line1.shape_opt() is Some(shape) {
    inspect(shape.glyphs.length(), content="3")
    inspect(shape.glyphs[0].x_advance, content="1")
    inspect(shape.glyphs[1].x_advance, content="4")
    inspect(shape.glyphs[2].x_advance, content="1")
  } else {
    fail("expected Some(shape)")
  }
}

///|
test "BufferLine.layout wraps words using whitespace segmentation (MVP)" {
  let attrs = AttrsList::new(Attrs::new())
  let line0 = BufferLine::new("hello world", Lf, attrs, Advanced)
  let line1 = line0.layout(
    10.0F,
    Some(60.0F),
    Wrap::Word,
    None,
    4,
    Hinting::Disabled,
  )
  if line1.layout_opt() is Some(layout) {
    inspect(layout.length(), content="2")
    inspect(layout[0].start, content="0")
    inspect(layout[0].end, content="5")
    inspect(layout[1].start, content="6")
    inspect(layout[1].end, content="11")
  } else {
    fail("expected Some(layout)")
  }
}

///|
test "BufferLine.layout: Align::Justified does not justify last visual line" {
  let attrs = AttrsList::new(Attrs::new())
  let line0 = BufferLine::new("a a a a a", Lf, attrs, Advanced)
  let (line0, _) = line0.set_align(Some(Align::Justified))
  let line1 = line0.layout(
    10.0F,
    Some(60.0F),
    Wrap::Word,
    None,
    4,
    Hinting::Disabled,
  )
  if line1.layout_opt() is Some(layout) {
    inspect(layout.length(), content="2")
    // First line: justified to full width.
    inspect(layout[0].w, content="60")
    // Last line: not justified.
    inspect(layout[1].w, content="30")
  } else {
    fail("expected Some(layout)")
  }
}

///|
test "BufferLine.layout: Hinting::Enabled rounds advances" {
  let attrs = AttrsList::new(Attrs::new())
  let line0 = BufferLine::new("ab", Lf, attrs, Advanced)
  let disabled = line0.layout(
    10.5F,
    None,
    Wrap::None,
    None,
    4,
    Hinting::Disabled,
  )
  let enabled = line0.layout(10.5F, None, Wrap::None, None, 4, Hinting::Enabled)
  if disabled.layout_opt() is Some(l0) && enabled.layout_opt() is Some(l1) {
    inspect(l0[0].w, content="21")
    inspect(l1[0].w, content="22")
  } else {
    fail("expected Some(layout)")
  }
}

///|
test "BufferLine.layout: Align::End follows paragraph direction in RTL lines" {
  let attrs = AttrsList::new(Attrs::new())
  let line0 = BufferLine::new("\u{05D0}\u{05D1}", Lf, attrs, Advanced)
  let (line1, _) = line0.set_align(Some(Align::End))
  let line2 = line1.layout(
    10.0F,
    Some(40.0F),
    Wrap::None,
    None,
    4,
    Hinting::Disabled,
  )
  if line2.shape_opt() is Some(shape) {
    inspect(shape.rtl, content="true")
  } else {
    fail("expected Some(shape)")
  }
  if line2.layout_opt() is Some(layout) {
    inspect(layout.length(), content="1")
    inspect(layout[0].w, content="20")
    // In RTL paragraphs, End means logical end (left edge).
    inspect(layout[0].glyphs[0].x, content="30")
  } else {
    fail("expected Some(layout)")
  }
}

///|
test "BufferLine.layout: whitespace-only word wrap keeps only final blank segment" {
  let attrs = AttrsList::new(Attrs::new())
  let line0 = BufferLine::new("   ", Lf, attrs, Advanced)
  let line1 = line0.layout(
    10.0F,
    Some(5.0F),
    Wrap::Word,
    None,
    4,
    Hinting::Disabled,
  )
  if line1.layout_opt() is Some(layout) {
    inspect(layout.length(), content="1")
    inspect(layout[0].w, content="10")
    inspect(layout[0].start, content="2")
    inspect(layout[0].end, content="3")
    inspect(layout[0].glyphs.length(), content="1")
  } else {
    fail("expected Some(layout)")
  }
}

///|
test "BufferLine.layout: whitespace-only word wrap keeps blanks when unbounded" {
  let attrs = AttrsList::new(Attrs::new())
  let line0 = BufferLine::new("   ", Lf, attrs, Advanced)
  let line1 = line0.layout(10.0F, None, Wrap::Word, None, 4, Hinting::Disabled)
  if line1.layout_opt() is Some(layout) {
    inspect(layout.length(), content="1")
    inspect(layout[0].w, content="30")
    inspect(layout[0].start, content="0")
    inspect(layout[0].end, content="3")
    inspect(layout[0].glyphs.length(), content="3")
  } else {
    fail("expected Some(layout)")
  }
}
