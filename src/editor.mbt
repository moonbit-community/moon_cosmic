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
