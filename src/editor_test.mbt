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
test "Editor.selection_bounds: none/normal/line/word" {
  let attrs = AttrsList::new(Attrs::new())
  let buffer = Buffer::new(Metrics::new(12.0F, 14.0F)).set_text(
    "hello world\nfoo bar",
    attrs,
    Advanced,
  )

  // None
  let editor0 = Editor::new(buffer)
  inspect(
    match editor0.selection_bounds() {
      None => true
      _ => false
    },
    content="true",
  )

  // Normal
  let editor1 = editor0
    .set_cursor(Cursor::new(0, 2))
    .set_selection(Selection::Normal(Cursor::new(0, 5)))
  match editor1.selection_bounds() {
    None => abort("expected selection bounds")
    Some((start, end)) => {
      inspect(start.line, content="0")
      inspect(start.index, content="2")
      inspect(end.line, content="0")
      inspect(end.index, content="5")
    }
  }

  // Line selection expands to full lines.
  let editor2 = editor0
    .set_cursor(Cursor::new(1, 2))
    .set_selection(Selection::Line(Cursor::new(0, 0)))
  match editor2.selection_bounds() {
    None => abort("expected selection bounds")
    Some((start, end)) => {
      inspect(start.line, content="0")
      inspect(start.index, content="0")
      inspect(end.line, content="1")
      inspect(end.index, content="7")
    }
  }

  // Word selection expands to whole words (whitespace-based MVP).
  let editor3 = editor0
    .set_cursor(Cursor::new(0, 8))
    .set_selection(Selection::Word(Cursor::new(0, 1)))
  match editor3.selection_bounds() {
    None => abort("expected selection bounds")
    Some((start, end)) => {
      inspect(start.line, content="0")
      inspect(start.index, content="0")
      inspect(end.line, content="0")
      inspect(end.index, content="11")
    }
  }
}
