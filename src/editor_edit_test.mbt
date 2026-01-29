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
test "Editor.insert_at inserts within a line" {
  let attrs = AttrsList::new(Attrs::new())
  let buffer = Buffer::new(Metrics::new(12.0F, 14.0F)).set_text(
    "hello world",
    attrs,
    Advanced,
  )
  let editor0 = Editor::new(buffer)
  let (editor1, cursor1) = editor0.insert_at(Cursor::new(0, 5), "X", None)
  inspect(editor1.buffer().lines()[0].text(), content="helloX world")
  inspect(cursor1.line, content="0")
  inspect(cursor1.index, content="6")
}

///|
test "Editor.insert_at inserts multi-line text (trailing newline creates empty line)" {
  let attrs = AttrsList::new(Attrs::new())
  let buffer = Buffer::new(Metrics::new(12.0F, 14.0F)).set_text(
    "abcDEF",
    attrs,
    Advanced,
  )
  let editor0 = Editor::new(buffer)
  let (editor1, cursor1) = editor0.insert_at(Cursor::new(0, 3), "1\n2\n", None)
  let lines = editor1.buffer().lines()
  inspect(lines.length(), content="3")
  inspect(lines[0].text(), content="abc1")
  inspect(lines[0].ending().as_str(), content="\n")
  inspect(lines[1].text(), content="2")
  inspect(lines[1].ending().as_str(), content="\n")
  inspect(lines[2].text(), content="DEF")
  inspect(lines[2].ending().as_str(), content="")
  inspect(cursor1.line, content="2")
  inspect(cursor1.index, content="0")
}

///|
test "Editor.delete_range deletes within and across lines" {
  let attrs = AttrsList::new(Attrs::new())
  let buffer0 = Buffer::new(Metrics::new(12.0F, 14.0F)).set_text(
    "helloX world",
    attrs,
    Advanced,
  )
  let editor0 = Editor::new(buffer0)
  let editor1 = editor0.delete_range(Cursor::new(0, 5), Cursor::new(0, 6))
  inspect(editor1.buffer().lines()[0].text(), content="hello world")
  let buffer1 = Buffer::new(Metrics::new(12.0F, 14.0F)).set_text(
    "abc\nDEF",
    attrs,
    Advanced,
  )
  let editor2 = Editor::new(buffer1)
  let editor3 = editor2.delete_range(Cursor::new(0, 1), Cursor::new(1, 2))
  let lines = editor3.buffer().lines()
  inspect(lines.length(), content="1")
  inspect(lines[0].text(), content="aF")
}
