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
test "Editor.action Indent aligns to next tab stop at after_whitespace" {
  let attrs = AttrsList::new(Attrs::new())
  let buffer = Buffer::new(Metrics::new(12.0F, 12.0F))
    .set_text("  foo", attrs, Advanced)
    .set_tab_width(4)
  let editor0 = Editor::new(buffer).set_cursor(Cursor::new(0, 3))
  let editor1 = editor0.action(Action::Indent)
  inspect(editor1.buffer().lines()[0].text(), content="    foo")
  inspect(editor1.cursor().index, content="5")
}

///|
test "Editor.action Unindent removes one tab stop chunk" {
  let attrs = AttrsList::new(Attrs::new())
  let buffer = Buffer::new(Metrics::new(12.0F, 12.0F))
    .set_text("      foo", attrs, Advanced) // 6 spaces
    .set_tab_width(4)
  let editor0 = Editor::new(buffer).set_cursor(Cursor::new(0, 6))
  let editor1 = editor0.action(Action::Unindent)
  inspect(editor1.buffer().lines()[0].text(), content="    foo")
  inspect(editor1.cursor().index, content="4")
}
