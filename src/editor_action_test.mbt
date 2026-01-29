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
test "Editor change tracking: insert and delete" {
  let attrs = AttrsList::new(Attrs::new())
  let buffer = Buffer::new(Metrics::new(12.0F, 14.0F)).set_text(
    "abc\ndef",
    attrs,
    Advanced,
  )
  let editor0 = Editor::new(buffer).start_change()

  // Insert
  let editor1 = editor0
    .set_cursor(Cursor::new(0, 1))
    .action(Action::Insert('X'))
  let (editor2, change_opt) = editor1.finish_change()
  ignore(editor2)
  match change_opt {
    None => abort("expected change")
    Some(change) => {
      inspect(change.items.length(), content="1")
      inspect(change.items[0].insert, content="true")
      inspect(change.items[0].text, content="X")
    }
  }

  // Delete across lines
  let editor3 = Editor::new(buffer)
    .start_change()
    .delete_range(Cursor::new(0, 2), Cursor::new(1, 1))
  let (_editor4, change_opt2) = editor3.finish_change()
  match change_opt2 {
    None => abort("expected change")
    Some(change) => {
      inspect(change.items.length(), content="1")
      inspect(change.items[0].insert, content="false")
      // Deleted text includes original line ending between lines.
      inspect(change.items[0].text, content="c\nd")
    }
  }
}

///|
test "Editor.action: backspace/delete/enter and motion" {
  let attrs = AttrsList::new(Attrs::new())
  let buffer = Buffer::new(Metrics::new(12.0F, 14.0F)).set_text(
    "ab\ncd",
    attrs,
    Advanced,
  )
  let editor0 = Editor::new(buffer).set_cursor(Cursor::new(0, 2))

  // Enter inserts newline.
  let editor1 = editor0.action(Action::Enter)
  inspect(editor1.buffer().lines().length(), content="3")
  inspect(editor1.buffer().lines()[0].text(), content="ab")

  // Backspace deletes previous code unit.
  let editor2 = Editor::new(buffer)
    .set_cursor(Cursor::new(0, 2))
    .action(Action::Backspace)
  inspect(editor2.buffer().lines()[0].text(), content="a")
  inspect(editor2.cursor().index, content="1")

  // Delete deletes forward.
  let editor3 = Editor::new(buffer)
    .set_cursor(Cursor::new(0, 1))
    .action(Action::Delete)
  inspect(editor3.buffer().lines()[0].text(), content="a")
  inspect(editor3.cursor().index, content="1")

  // Motion right then down.
  let editor4 = Editor::new(buffer)
    .set_cursor(Cursor::new(0, 0))
    .action(Action::Motion(Motion::Right))
    .action(Action::Motion(Motion::Down))
  inspect(editor4.cursor().line, content="1")
  inspect(editor4.cursor().index, content="1")
}

///|
test "Buffer.hit + Editor.action click/drag" {
  let attrs = AttrsList::new(Attrs::new())
  let buffer = Buffer::new(Metrics::new(12.0F, 12.0F))
    .set_text("abc", attrs, Advanced)
    .set_size(Some(1000.0F), None)
  match buffer.hit(1.0F, 0.0F) {
    None => abort("expected hit")
    Some(c) => inspect(c.index, content="0")
  }
  match buffer.hit(7.0F, 0.0F) {
    None => abort("expected hit")
    Some(c) => inspect(c.index, content="1")
  }
  let editor0 = Editor::new(buffer).set_cursor(Cursor::new(0, 0))
  let editor1 = editor0.action(Action::Click(7, 0))
  inspect(editor1.cursor().index, content="1")
  let editor2 = editor0.action(Action::Drag(7, 0))
  inspect(editor2.cursor().index, content="1")
  inspect(
    match editor2.selection {
      Normal(_) => true
      _ => false
    },
    content="true",
  )
}

///|
test "Buffer.hit respects RTL line direction (clamps + half-glyph)" {
  let attrs = AttrsList::new(Attrs::new())
  let s = "\u{05D0}\u{05D1}\u{05D2}"
  let buffer = Buffer::new(Metrics::new(12.0F, 12.0F))
    .set_text(s, attrs, Advanced)
    .set_size(Some(1000.0F), None)
    .layout_all()
  match buffer.hit(-1.0F, 0.0F) {
    None => abort("expected hit")
    Some(c) => {
      inspect(c.index, content="3")
      inspect(
        match c.affinity {
          Before => true
          _ => false
        },
        content="true",
      )
    }
  }
  match buffer.hit(10000.0F, 0.0F) {
    None => abort("expected hit")
    Some(c) => {
      inspect(c.index, content="0")
      inspect(
        match c.affinity {
          After => true
          _ => false
        },
        content="true",
      )
    }
  }
}

///|
test "Editor.action Backspace/Delete are grapheme-aware (combining mark)" {
  let attrs = AttrsList::new(Attrs::new())
  // "e" + COMBINING ACUTE ACCENT (U+0301) => one grapheme cluster, two UTF-16 code units.
  let s = "e\u{0301}"
  let buffer = Buffer::new(Metrics::new(12.0F, 12.0F)).set_text(
    s,
    attrs,
    Advanced,
  )
  let editor0 = Editor::new(buffer).set_cursor(Cursor::new(0, 2))
  let editor1 = editor0.action(Action::Backspace)
  inspect(editor1.buffer().lines()[0].text(), content="")
  let editor2 = Editor::new(buffer).set_cursor(Cursor::new(0, 0))
  let editor3 = editor2.action(Action::Delete)
  inspect(editor3.buffer().lines()[0].text(), content="")
}

///|
test "Buffer.cursor_motion Previous/Next are grapheme-aware (combining mark)" {
  let attrs = AttrsList::new(Attrs::new())
  // "e" + COMBINING ACUTE ACCENT (U+0301) => one grapheme cluster, two UTF-16 code units.
  let s = "e\u{0301}"
  let buffer = Buffer::new(Metrics::new(12.0F, 12.0F))
    .set_text(s, attrs, Advanced)
    .set_size(Some(1000.0F), None)
  match buffer.cursor_motion(Cursor::new(0, 2), None, Motion::Previous) {
    None => abort("expected motion")
    Some((c, _x)) => {
      inspect(c.index, content="0")
      inspect(
        match c.affinity {
          After => true
          _ => false
        },
        content="true",
      )
    }
  }
  match buffer.cursor_motion(Cursor::new(0, 0), None, Motion::Next) {
    None => abort("expected motion")
    Some((c, _x)) => {
      inspect(c.index, content="2")
      inspect(
        match c.affinity {
          Before => true
          _ => false
        },
        content="true",
      )
    }
  }
}

///|
test "Buffer.cursor_motion SoftHome jumps to first non-whitespace" {
  let attrs = AttrsList::new(Attrs::new())
  let buffer = Buffer::new(Metrics::new(12.0F, 12.0F))
    .set_text("  foo", attrs, Advanced)
    .set_size(Some(1000.0F), None)
  match buffer.cursor_motion(Cursor::new(0, 0), None, Motion::SoftHome) {
    None => abort("expected motion")
    Some((c, _x)) => inspect(c.index, content="2")
  }
  match buffer.cursor_motion(Cursor::new(0, 2), None, Motion::SoftHome) {
    None => abort("expected motion")
    Some((c, _x)) => inspect(c.index, content="2")
  }
}

///|
test "Buffer.cursor_motion SoftHome on all-whitespace line returns 0" {
  let attrs = AttrsList::new(Attrs::new())
  let buffer = Buffer::new(Metrics::new(12.0F, 12.0F))
    .set_text("   ", attrs, Advanced)
    .set_size(Some(1000.0F), None)
  match buffer.cursor_motion(Cursor::new(0, 1), None, Motion::SoftHome) {
    None => abort("expected motion")
    Some((c, _x)) => inspect(c.index, content="0")
  }
}

///|
test "Buffer.cursor_motion Home/End operate on visual line when wrapped" {
  let attrs = AttrsList::new(Attrs::new())
  let text = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  let buffer = Buffer::new(Metrics::new(12.0F, 12.0F))
    .set_text(text, attrs, Advanced)
    .set_size(Some(40.0F), None)
    .layout_all()
  let runs : Array[LayoutRun] = []
  for r in buffer.layout_runs() {
    runs.push(r)
  }
  if runs.length() < 2 {
    abort("expected wrapped runs")
  }
  let run1 = runs[1]
  if run1.glyphs.length() == 0 {
    abort("expected glyphs")
  }
  let home_expected = run1.glyphs[0].start
  let end_expected = run1.glyphs[run1.glyphs.length() - 1].end
  let mid_idx = run1.glyphs[0].end
  match buffer.cursor_motion(Cursor::new(0, mid_idx), None, Motion::Home) {
    None => abort("expected motion")
    Some((c, _x)) => {
      inspect(c.index == home_expected, content="true")
      inspect(
        match c.affinity {
          After => true
          _ => false
        },
        content="true",
      )
    }
  }
  match buffer.cursor_motion(Cursor::new(0, home_expected), None, Motion::End) {
    None => abort("expected motion")
    Some((c, _x)) => {
      inspect(c.index == end_expected, content="true")
      inspect(
        match c.affinity {
          Before => true
          _ => false
        },
        content="true",
      )
    }
  }
}

///|
test "Buffer.cursor_motion PreviousWord/NextWord cross lines" {
  let attrs = AttrsList::new(Attrs::new())
  let buffer = Buffer::new(Metrics::new(12.0F, 12.0F))
    .set_text("foo\nbar", attrs, Advanced)
    .set_size(Some(1000.0F), None)
  match buffer.cursor_motion(Cursor::new(1, 0), None, Motion::PreviousWord) {
    None => abort("expected motion")
    Some((c, _x)) => {
      inspect(c.line, content="0")
      inspect(c.index, content="3")
    }
  }
  match buffer.cursor_motion(Cursor::new(0, 3), None, Motion::NextWord) {
    None => abort("expected motion")
    Some((c, _x)) => {
      inspect(c.line, content="1")
      inspect(c.index, content="0")
    }
  }
}

///|
test "Buffer.cursor_motion ParagraphStart/ParagraphEnd" {
  let attrs = AttrsList::new(Attrs::new())
  let buffer = Buffer::new(Metrics::new(12.0F, 12.0F))
    .set_text("foo", attrs, Advanced)
    .set_size(Some(1000.0F), None)
  match buffer.cursor_motion(Cursor::new(0, 2), None, Motion::ParagraphStart) {
    None => abort("expected motion")
    Some((c, _x)) => inspect(c.index, content="0")
  }
  match buffer.cursor_motion(Cursor::new(0, 1), None, Motion::ParagraphEnd) {
    None => abort("expected motion")
    Some((c, _x)) => inspect(c.index, content="3")
  }
}

///|
test "Buffer.cursor_motion GotoLine uses LayoutCursor mapping" {
  let attrs = AttrsList::new(Attrs::new())
  let buffer = Buffer::new(Metrics::new(12.0F, 12.0F))
    .set_text("abc\ndefg\nhi", attrs, Advanced)
    .set_size(Some(1000.0F), None)
  match buffer.cursor_motion(Cursor::new(0, 2), None, Motion::GotoLine(1)) {
    None => abort("expected motion")
    Some((c, _x)) => {
      inspect(c.line, content="1")
      inspect(c.index, content="2")
    }
  }
  match buffer.cursor_motion(Cursor::new(0, 0), None, Motion::GotoLine(99)) {
    None => ()
    Some((_c, _x)) => abort("expected None for out-of-range")
  }
}

///|
test "Buffer.cursor_motion Left/Right respect base RTL lines" {
  let attrs = AttrsList::new(Attrs::new())
  let s = "\u{05D0}\u{05D1}\u{05D2}"
  let buffer = Buffer::new(Metrics::new(12.0F, 12.0F))
    .set_text(s, attrs, Advanced)
    .set_size(Some(1000.0F), None)
  match buffer.cursor_motion(Cursor::new(0, 0), None, Motion::Left) {
    None => abort("expected motion")
    Some((c, _x)) => {
      inspect(c.index, content="1")
      inspect(
        match c.affinity {
          Before => true
          _ => false
        },
        content="true",
      )
    }
  }
  match buffer.cursor_motion(Cursor::new(0, 1), None, Motion::Right) {
    None => abort("expected motion")
    Some((c, _x)) => {
      inspect(c.index, content="0")
      inspect(
        match c.affinity {
          After => true
          _ => false
        },
        content="true",
      )
    }
  }
}
