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
/// Editor wrapper (ported from `cosmic-text/src/edit/editor.rs`).
///
/// This MoonBit port keeps the same high-level behavior but is implemented in a
/// functional style (methods return updated `Editor`).
fn order_cursors(a : Cursor, b : Cursor) -> (Cursor, Cursor) {
  if a.line < b.line {
    (a, b)
  } else if a.line > b.line {
    (b, a)
  } else if a.index <= b.index {
    (a, b)
  } else {
    (b, a)
  }
}

///|
fn clamp(v : Int, lo : Int, hi : Int) -> Int {
  if v < lo {
    lo
  } else if v > hi {
    hi
  } else {
    v
  }
}

///|
fn line_items_for_insert(data : String) -> Array[(Int, Int, LineEnding)] {
  let items : Array[(Int, Int, LineEnding)] = []
  let mut iter = LineIter::new(data)
  while true {
    let (next_iter, item_opt) = iter.next()
    iter = next_iter
    match item_opt {
      None => break
      Some(item) => items.push(item)
    }
  }
  // If the inserted data ends with a line ending, ensure a trailing empty line.
  if items.length() > 0 {
    let last = items[items.length() - 1]
    if last.2.as_str() != "" {
      let len = data.length()
      items.push((len, len, LineEnding::None))
    }
  }
  items
}

///|
pub struct Editor {
  buffer : Buffer
  cursor : Cursor
  cursor_x_opt : Int?
  selection : Selection
  cursor_moved : Bool
  auto_indent : Bool
  change_opt : Change?
}

///|
pub fn Editor::new(buffer : Buffer) -> Editor {
  Editor::{
    buffer,
    cursor: Cursor::new(0, 0),
    cursor_x_opt: None,
    selection: Selection::None,
    cursor_moved: false,
    auto_indent: false,
    change_opt: None,
  }
}

///|
pub fn Editor::buffer(self : Editor) -> Buffer {
  self.buffer
}

///|
pub fn Editor::cursor(self : Editor) -> Cursor {
  self.cursor
}

///|
pub fn Editor::set_cursor(self : Editor, cursor : Cursor) -> Editor {
  if self.cursor == cursor {
    self
  } else {
    Editor::{
      ..self,
      cursor,
      cursor_moved: true,
      buffer: self.buffer.set_redraw(true),
    }
  }
}

///|
pub fn Editor::selection(self : Editor) -> Selection {
  self.selection
}

///|
pub fn Editor::set_selection(self : Editor, selection : Selection) -> Editor {
  if self.selection == selection {
    self
  } else {
    Editor::{ ..self, selection, }
  }
}

///|
pub fn Editor::auto_indent(self : Editor) -> Bool {
  self.auto_indent
}

///|
pub fn Editor::set_auto_indent(self : Editor, auto_indent : Bool) -> Editor {
  if self.auto_indent == auto_indent {
    self
  } else {
    Editor::{ ..self, auto_indent, }
  }
}

///|
/// Get the bounds of the current selection (line/word selection is expanded).
pub fn Editor::selection_bounds(self : Editor) -> (Cursor, Cursor)? {
  let cursor = self.cursor
  let buffer = self.buffer
  match self.selection {
    Selection::None => None
    Selection::Normal(select) => Some(order_cursors(select, cursor))
    Selection::Line(select) => {
      let start_line = if select.line < cursor.line {
        select.line
      } else {
        cursor.line
      }
      let end_line = if select.line > cursor.line {
        select.line
      } else {
        cursor.line
      }
      let lines = buffer.lines()
      let end_index = lines[end_line].text().length()
      Some((Cursor::new(start_line, 0), Cursor::new(end_line, end_index)))
    }
    Selection::Word(select) => {
      let (start0, end0) = order_cursors(select, cursor)
      let mut start = start0
      let mut end = end0

      // Move start to beginning of word (whitespace-based MVP).
      {
        let line = buffer.lines()[start.line]
        let ranges = word_indices_whitespace(line.text())
        let mut found = 0
        let mut i = ranges.length() - 1
        while i >= 0 {
          let (ws, _we) = ranges[i]
          if ws < start.index {
            found = ws
            break
          }
          if i == 0 {
            break
          }
          i = i - 1
        }
        start = Cursor::new_with_affinity(start.line, found, start.affinity)
      }

      // Move end to end of word (whitespace-based MVP).
      {
        let line = buffer.lines()[end.line]
        let ranges = word_indices_whitespace(line.text())
        let mut found = line.text().length()
        for pair in ranges {
          let we = pair.1
          if we > end.index {
            found = we
            break
          }
        }
        end = Cursor::new_with_affinity(end.line, found, end.affinity)
      }
      Some((start, end))
    }
  }
}

///|
/// Insert `data` at the specified `cursor`, returning the updated editor and the new cursor.
///
/// NOTE: `attrs_list_opt` is currently treated as defaults-only (spans are ignored) in this MVP.
pub fn Editor::insert_at(
  self : Editor,
  cursor : Cursor,
  data : String,
  attrs_list_opt : AttrsList?,
) -> (Editor, Cursor) {
  if data.length() == 0 {
    return (self, cursor)
  }
  let mut cursor = cursor
  let mut buffer = self.buffer
  let lines0 = buffer.lines()

  // Ensure there are enough lines in the buffer to handle this cursor.
  let lines : Array[BufferLine] = []
  for l in lines0 {
    lines.push(l)
  }
  while cursor.line >= lines.length() {
    let mut last_ending = LineEnding::None
    if lines.length() > 0 {
      let last_i = lines.length() - 1
      let last_line0 = lines[last_i]
      last_ending = last_line0.ending()
      // Ensure a valid line ending is always set on interior lines.
      if last_ending.as_str() == "" {
        let last_line = last_line0.set_ending(LineEnding::default())
        lines[last_i] = last_line
        last_ending = last_line.ending()
      }
    }
    let defaults = match attrs_list_opt {
      Some(al) => al.defaults()
      None =>
        if lines.length() > 0 {
          lines[lines.length() - 1].attrs_list().defaults()
        } else {
          Attrs::new()
        }
    }
    lines.push(
      BufferLine::new("", last_ending, AttrsList::new(defaults), Advanced),
    )
  }

  // Clamp cursor index to the target line.
  let target0 = lines[cursor.line]
  let idx = clamp(cursor.index, 0, target0.text().length())
  cursor = Cursor::new_with_affinity(cursor.line, idx, cursor.affinity)
  let (left, after) = target0.split_off(idx)
  let after_len = after.text().length()

  // Determine defaults for inserted text.
  let inserted_defaults = match attrs_list_opt {
    Some(al) => al.defaults()
    None => left.attrs_list().get_span(if idx > 0 { idx - 1 } else { 0 })
  }
  let parts = line_items_for_insert(data)
  // data.length() > 0 implies at least one part.
  let p0 = parts[0]
  let first_text = slice_string(data, p0.0, p0.1)
  let first = left.append(
    BufferLine::new(
      first_text,
      p0.2,
      AttrsList::new(inserted_defaults),
      Advanced,
    ),
  )
  let out : Array[BufferLine] = []
  for i in 0..<cursor.line {
    out.push(lines[i])
  }
  let mut new_cursor = cursor
  if parts.length() == 1 {
    let merged = first.append(after)
    out.push(merged)
    for i in (cursor.line + 1)..<lines.length() {
      out.push(lines[i])
    }
    new_cursor = Cursor::new_with_affinity(
      cursor.line,
      merged.text().length() - after_len,
      cursor.affinity,
    )
  } else {
    out.push(first)
    // Middle lines (excluding the last part)
    for i in 1..<(parts.length() - 1) {
      let p = parts[i]
      let text = slice_string(data, p.0, p.1)
      out.push(
        BufferLine::new(text, p.2, AttrsList::new(inserted_defaults), Advanced),
      )
    }
    let plast = parts[parts.length() - 1]
    let last_text = slice_string(data, plast.0, plast.1)
    let last = BufferLine::new(
      last_text,
      plast.2,
      AttrsList::new(inserted_defaults),
      Advanced,
    ).append(after)
    out.push(last)
    for i in (cursor.line + 1)..<lines.length() {
      out.push(lines[i])
    }
    let new_line = cursor.line + (parts.length() - 1)
    new_cursor = Cursor::new_with_affinity(
      new_line,
      out[new_line].text().length() - after_len,
      cursor.affinity,
    )
  }
  buffer = Buffer::{ ..buffer, lines: out, redraw: true }
  let mut editor = Editor::{ ..self, buffer, }
  // Track change if enabled.
  match editor.change_opt {
    None => ()
    Some(change0) => {
      let items : Array[ChangeItem] = []
      for it in change0.items {
        items.push(it)
      }
      items.push(ChangeItem::{
        start: cursor,
        end: new_cursor,
        text: data,
        insert: true,
      })
      editor = Editor::{ ..editor, change_opt: Some(Change::{ items, }) }
    }
  }
  (editor, new_cursor)
}

///|
/// Delete text starting at `start` cursor and ending at `end` cursor.
pub fn Editor::delete_range(
  self : Editor,
  start : Cursor,
  end : Cursor,
) -> Editor {
  let (start, end) = order_cursors(start, end)
  if start.line == end.line && start.index == end.index {
    return self
  }
  let buffer0 = self.buffer
  let lines0 = buffer0.lines()
  if start.line < 0 || start.line >= lines0.length() {
    return self
  }
  let out : Array[BufferLine] = []
  for i in 0..<start.line {
    out.push(lines0[i])
  }
  if start.line == end.line {
    let line0 = lines0[start.line]
    let idx0 = clamp(start.index, 0, line0.text().length())
    let idx1 = clamp(end.index, idx0, line0.text().length())
    let (head, rest) = line0.split_off(idx0)
    let (_removed, after) = rest.split_off(idx1 - idx0)
    out.push(head.append(after))
    for i in (start.line + 1)..<lines0.length() {
      out.push(lines0[i])
    }
  } else {
    if end.line < 0 || end.line >= lines0.length() {
      return self
    }
    let start_line0 = lines0[start.line]
    let end_line0 = lines0[end.line]
    let idx0 = clamp(start.index, 0, start_line0.text().length())
    let idx1 = clamp(end.index, 0, end_line0.text().length())
    let (head, _tail) = start_line0.split_off(idx0)
    let (_removed, after) = end_line0.split_off(idx1)
    out.push(head.append(after))
    for i in (end.line + 1)..<lines0.length() {
      out.push(lines0[i])
    }
  }
  let buffer = Buffer::{ ..buffer0, lines: out, redraw: true }
  Editor::{ ..self, buffer, }
}
