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
fn is_ws_u16(c : UInt16) -> Bool {
  // MVP: space + tab for indentation logic.
  c == 32 || c == 9
}

///|
fn leading_whitespace(s : String) -> String {
  let len = s.length()
  let mut i = 0
  while i < len && is_ws_u16(s.code_unit_at(i)) {
    i = i + 1
  }
  slice_string(s, 0, i)
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
fn deleted_text(buffer : Buffer, start : Cursor, end : Cursor) -> String {
  let lines = buffer.lines()
  let start_line = start.line
  let end_line = end.line
  if start_line < 0 ||
    end_line < 0 ||
    start_line >= lines.length() ||
    end_line >= lines.length() {
    return ""
  }
  if start_line == end_line {
    let line = lines[start_line].text()
    let a = clamp(start.index, 0, line.length())
    let b = clamp(end.index, a, line.length())
    slice_string(line, a, b)
  } else {
    let sb = StringBuilder::new(size_hint=64)
    let first = lines[start_line]
    let first_text = first.text()
    let a = clamp(start.index, 0, first_text.length())
    sb.write_view(
      first_text[:].view(start_offset=a, end_offset=first_text.length()),
    )
    sb.write_string(first.ending().as_str())
    for i in (start_line + 1)..<end_line {
      let l = lines[i]
      sb.write_string(l.text())
      sb.write_string(l.ending().as_str())
    }
    let last = lines[end_line]
    let last_text = last.text()
    let b = clamp(end.index, 0, last_text.length())
    sb.write_view(last_text[:].view(start_offset=0, end_offset=b))
    sb.to_string()
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

///|
pub fn Editor::tab_width(self : Editor) -> Int {
  self.buffer.tab_width
}

///|
/// Set tab width in spaces. A value of 0 is ignored (matches upstream).
pub fn Editor::set_tab_width(self : Editor, tab_width : Int) -> Editor {
  if tab_width <= 0 {
    self
  } else {
    Editor::{ ..self, buffer: self.buffer.set_tab_width(tab_width) }
  }
}

///|
pub fn Editor::start_change(self : Editor) -> Editor {
  match self.change_opt {
    Some(_) => self
    None => Editor::{ ..self, change_opt: Some(Change::default()) }
  }
}

///|
pub fn Editor::finish_change(self : Editor) -> (Editor, Change?) {
  (Editor::{ ..self, change_opt: None }, self.change_opt)
}

///|
/// Insert `data` at the specified `cursor`, returning the updated editor and the new cursor.
///
/// NOTE: `attrs_list_opt` is applied to inserted text; when `None`, we use the previous character's attrs as defaults.
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

  // Determine attributes for inserted text (defaults + spans).
  let mut attrs_remaining = match attrs_list_opt {
    Some(al) => al
    None =>
      AttrsList::new(
        left.attrs_list().get_span(if idx > 0 { idx - 1 } else { 0 }),
      )
  }
  let parts = line_items_for_insert(data)
  // data.length() > 0 implies at least one part.
  let p0 = parts[0]
  let first_text = slice_string(data, p0.0, p0.1)
  let (first_attrs, rest_attrs) = attrs_remaining.split_off(first_text.length())
  attrs_remaining = rest_attrs
  let first = left.append(
    BufferLine::new(first_text, p0.2, first_attrs, Advanced),
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
      let (these_attrs, rest_attrs) = attrs_remaining.split_off(text.length())
      attrs_remaining = rest_attrs
      out.push(BufferLine::new(text, p.2, these_attrs, Advanced))
    }
    let plast = parts[parts.length() - 1]
    let last_text = slice_string(data, plast.0, plast.1)
    let (last_attrs, rest_attrs) = attrs_remaining.split_off(last_text.length())
    attrs_remaining = rest_attrs
    let last = BufferLine::new(last_text, plast.2, last_attrs, Advanced).append(
      after,
    )
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
        start,
        end,
        text: deleted_text(buffer0, start, end),
        insert: false,
      })
      editor = Editor::{ ..editor, change_opt: Some(Change::{ items, }) }
    }
  }
  editor
}

///|
pub fn Editor::copy_selection(self : Editor) -> String? {
  match self.selection_bounds() {
    None => None
    Some((start0, end0)) => {
      let lines = self.buffer.lines()
      let start = Cursor::new(
        start0.line,
        clamp(start0.index, 0, lines[start0.line].text().length()),
      )
      let end = Cursor::new(
        end0.line,
        clamp(end0.index, 0, lines[end0.line].text().length()),
      )
      if start.line == end.line {
        let text = lines[start.line].text()
        Some(slice_string(text, start.index, end.index))
      } else {
        let sb = StringBuilder::new(size_hint=64)
        // First line.
        {
          let text = lines[start.line].text()
          sb.write_view(
            text[:].view(start_offset=start.index, end_offset=text.length()),
          )
          sb.write_string("\n")
        }
        // Interior lines.
        for line_i in (start.line + 1)..<end.line {
          sb.write_string(lines[line_i].text())
          sb.write_string("\n")
        }
        // Last line.
        {
          let text = lines[end.line].text()
          sb.write_view(text[:].view(start_offset=0, end_offset=end.index))
        }
        Some(sb.to_string())
      }
    }
  }
}

///|
pub fn Editor::delete_selection(self : Editor) -> (Editor, Bool) {
  match self.selection_bounds() {
    None => (self, false)
    Some((start, end)) => {
      let editor = self
        .set_cursor(start)
        .set_selection(Selection::None)
        .delete_range(start, end)
      (editor, true)
    }
  }
}

///|
/// Insert string at current cursor, replacing selection if present.
pub fn Editor::insert_string(
  self : Editor,
  data : String,
  attrs_list_opt : AttrsList?,
) -> Editor {
  let (editor0, _deleted) = self.delete_selection()
  let cursor = editor0.cursor
  let (editor1, new_cursor) = editor0.insert_at(cursor, data, attrs_list_opt)
  editor1.set_cursor(new_cursor)
}

///|
pub fn Editor::apply_change(self : Editor, change : Change) -> (Editor, Bool) {
  // Cannot apply changes if there is a pending non-empty change.
  match self.change_opt {
    None => ()
    Some(pending) => if pending.items.length() > 0 { return (self, false) }
  }
  let mut editor = Editor::{ ..self, change_opt: None }
  let mut cursor = editor.cursor
  for item in change.items {
    if item.insert {
      let (e, c) = editor.insert_at(item.start, item.text, None)
      editor = e
      cursor = c
    } else {
      editor = editor.set_cursor(item.start)
      cursor = item.start
      editor = editor.delete_range(item.start, item.end)
    }
  }
  (editor.set_cursor(cursor), true)
}

///|
fn line_len(lines : Array[BufferLine], i : Int) -> Int {
  lines[i].text().length()
}

///|
fn cursor_motion(buffer : Buffer, cursor : Cursor, motion : Motion) -> Cursor {
  let lines = buffer.lines()
  if lines.length() == 0 {
    return cursor
  }
  let line_i = clamp(cursor.line, 0, lines.length() - 1)
  let line = lines[line_i].text()
  let idx = clamp(cursor.index, 0, line.length())
  let cur = Cursor::new_with_affinity(line_i, idx, cursor.affinity)
  match motion {
    LayoutCursor(_) => cur
    Previous | Left =>
      if cur.index > 0 {
        Cursor::new_with_affinity(cur.line, cur.index - 1, cur.affinity)
      } else if cur.line > 0 {
        let prev = cur.line - 1
        Cursor::new_with_affinity(prev, line_len(lines, prev), cur.affinity)
      } else {
        cur
      }
    Next | Right => {
      let len = line_len(lines, cur.line)
      if cur.index < len {
        Cursor::new_with_affinity(cur.line, cur.index + 1, cur.affinity)
      } else if cur.line + 1 < lines.length() {
        Cursor::new_with_affinity(cur.line + 1, 0, cur.affinity)
      } else {
        cur
      }
    }
    Up =>
      if cur.line > 0 {
        let prev = cur.line - 1
        Cursor::new_with_affinity(
          prev,
          clamp(cur.index, 0, line_len(lines, prev)),
          cur.affinity,
        )
      } else {
        cur
      }
    Down =>
      if cur.line + 1 < lines.length() {
        let next = cur.line + 1
        Cursor::new_with_affinity(
          next,
          clamp(cur.index, 0, line_len(lines, next)),
          cur.affinity,
        )
      } else {
        cur
      }
    Home => Cursor::new_with_affinity(cur.line, 0, cur.affinity)
    SoftHome => {
      let text = lines[cur.line].text()
      let mut after_ws = text.length()
      let mut i = 0
      while i < text.length() {
        if !is_ws_u16(text.code_unit_at(i)) {
          after_ws = i
          break
        }
        i = i + 1
      }
      let target = if cur.index == after_ws { 0 } else { after_ws }
      Cursor::new_with_affinity(cur.line, target, cur.affinity)
    }
    End =>
      Cursor::new_with_affinity(
        cur.line,
        line_len(lines, cur.line),
        cur.affinity,
      )
    BufferStart => Cursor::new_with_affinity(0, 0, cur.affinity)
    BufferEnd => {
      let last = lines.length() - 1
      Cursor::new_with_affinity(last, line_len(lines, last), cur.affinity)
    }
    Vertical(n) => {
      let tgt = clamp(cur.line + n, 0, lines.length() - 1)
      Cursor::new_with_affinity(
        tgt,
        clamp(cur.index, 0, line_len(lines, tgt)),
        cur.affinity,
      )
    }
    PageUp => cursor_motion(buffer, cur, Vertical(-10))
    PageDown => cursor_motion(buffer, cur, Vertical(10))
    GotoLine(n) => {
      let tgt = clamp(n, 0, lines.length() - 1)
      Cursor::new_with_affinity(
        tgt,
        clamp(cur.index, 0, line_len(lines, tgt)),
        cur.affinity,
      )
    }
    ParagraphStart => {
      let mut i = cur.line
      while i > 0 && lines[i - 1].text().length() > 0 {
        i = i - 1
      }
      Cursor::new_with_affinity(i, 0, cur.affinity)
    }
    ParagraphEnd => {
      let mut i = cur.line
      while i + 1 < lines.length() && lines[i + 1].text().length() > 0 {
        i = i + 1
      }
      Cursor::new_with_affinity(i, line_len(lines, i), cur.affinity)
    }
    PreviousWord | LeftWord => {
      let text = lines[cur.line].text()
      let ranges = word_indices_whitespace(text)
      let mut found = 0
      let mut i = ranges.length() - 1
      while i >= 0 {
        let (ws, _we) = ranges[i]
        if ws < cur.index {
          found = ws
          break
        }
        if i == 0 {
          break
        }
        i = i - 1
      }
      Cursor::new_with_affinity(cur.line, found, cur.affinity)
    }
    NextWord | RightWord => {
      let text = lines[cur.line].text()
      let ranges = word_indices_whitespace(text)
      let mut found = text.length()
      for p in ranges {
        let we = p.1
        if we > cur.index {
          found = we
          break
        }
      }
      Cursor::new_with_affinity(cur.line, found, cur.affinity)
    }
  }
}

///|
fn adjust_selection_index(
  sel : Selection,
  line_i : Int,
  delta : Int,
) -> Selection {
  fn clamp_nonneg(v : Int) -> Int {
    if v < 0 {
      0
    } else {
      v
    }
  }

  match sel {
    None => None
    Normal(c) =>
      if c.line == line_i {
        Normal(
          Cursor::new_with_affinity(
            c.line,
            clamp_nonneg(c.index + delta),
            c.affinity,
          ),
        )
      } else {
        sel
      }
    Line(c) =>
      if c.line == line_i {
        Line(
          Cursor::new_with_affinity(
            c.line,
            clamp_nonneg(c.index + delta),
            c.affinity,
          ),
        )
      } else {
        sel
      }
    Word(c) =>
      if c.line == line_i {
        Word(
          Cursor::new_with_affinity(
            c.line,
            clamp_nonneg(c.index + delta),
            c.affinity,
          ),
        )
      } else {
        sel
      }
  }
}

///|
/// Perform an action on the editor (MVP: cursor motion is text-index based, no hit-testing yet).
pub fn Editor::action(self : Editor, action : Action) -> Editor {
  let old_cursor = self.cursor
  let mut editor = self
  match action {
    Motion(motion) => {
      let new_cursor = cursor_motion(editor.buffer, editor.cursor, motion)
      editor = editor.set_cursor(new_cursor)
    }
    Escape => {
      match editor.selection {
        Selection::None => ()
        _ =>
          editor = Editor::{ ..editor, buffer: editor.buffer.set_redraw(true) }
      }
      editor = editor.set_selection(Selection::None)
    }
    Insert(ch) =>
      if ch.is_control() && ch != '\t' && ch != '\n' {
        ()
      } else if ch == '\n' {
        editor = editor.action(Enter)
      } else {
        editor = editor.insert_string(ch.to_string(), None)
      }
    Enter =>
      if editor.auto_indent {
        let line = editor.buffer.lines()[editor.cursor.line].text()
        editor = editor.insert_string("\n" + leading_whitespace(line), None)
      } else {
        editor = editor.insert_string("\n", None)
      }
    Backspace => {
      let (e0, deleted) = editor.delete_selection()
      editor = e0
      if !deleted {
        let end = editor.cursor
        let mut start = end
        if end.index > 0 {
          start = Cursor::new_with_affinity(
            end.line,
            end.index - 1,
            end.affinity,
          )
        } else if end.line > 0 {
          let prev = end.line - 1
          start = Cursor::new_with_affinity(
            prev,
            editor.buffer.lines()[prev].text().length(),
            end.affinity,
          )
        }
        if start != end {
          editor = editor.set_cursor(start).delete_range(start, end)
        }
      }
    }
    Delete => {
      let (e0, deleted) = editor.delete_selection()
      editor = e0
      if !deleted {
        let start = editor.cursor
        let mut end = start
        let line = editor.buffer.lines()[start.line].text()
        if start.index < line.length() {
          end = Cursor::new_with_affinity(
            start.line,
            start.index + 1,
            start.affinity,
          )
        } else if start.line + 1 < editor.buffer.lines().length() {
          end = Cursor::new_with_affinity(start.line + 1, 0, start.affinity)
        }
        if start != end {
          editor = editor.delete_range(start, end).set_cursor(start)
        }
      }
    }
    Indent => {
      let tab_width = editor.tab_width()
      let indent = String::make(tab_width, ' ')
      let (start, end) = match editor.selection_bounds() {
        Some(some) => some
        None => (editor.cursor, editor.cursor)
      }
      let indent_len = indent.length()
      for line_i in start.line..<=end.line {
        let (e, _c) = editor.insert_at(Cursor::new(line_i, 0), indent, None)
        editor = e
        if old_cursor.line == line_i {
          editor = editor.set_cursor(
            Cursor::new_with_affinity(
              old_cursor.line,
              old_cursor.index + indent_len,
              old_cursor.affinity,
            ),
          )
        }
        editor = Editor::{
          ..editor,
          selection: adjust_selection_index(
            editor.selection,
            line_i,
            indent_len,
          ),
        }
      }
    }
    Unindent => {
      let tab_width = editor.tab_width()
      let (start, end) = match editor.selection_bounds() {
        Some(some) => some
        None => (editor.cursor, editor.cursor)
      }
      for line_i in start.line..<=end.line {
        let text = editor.buffer.lines()[line_i].text()
        let mut n = 0
        while n < text.length() && n < tab_width && text.code_unit_at(n) == 32 {
          n = n + 1
        }
        if n > 0 {
          editor = editor.delete_range(
            Cursor::new(line_i, 0),
            Cursor::new(line_i, n),
          )
          if old_cursor.line == line_i {
            let new_idx = if old_cursor.index - n < 0 {
              0
            } else {
              old_cursor.index - n
            }
            editor = editor.set_cursor(
              Cursor::new_with_affinity(
                old_cursor.line,
                new_idx,
                old_cursor.affinity,
              ),
            )
          }
          editor = Editor::{
            ..editor,
            selection: adjust_selection_index(editor.selection, line_i, -n),
          }
        }
      }
    }
    Click(x, y) => {
      editor = editor.set_selection(Selection::None)
      match
        editor.buffer.hit(
          Float::from_double(x.to_double()),
          Float::from_double(y.to_double()),
        ) {
        None => ()
        Some(new_cursor) => editor = editor.set_cursor(new_cursor)
      }
    }
    DoubleClick(x, y) => {
      editor = editor.action(Click(x, y))
      editor = editor.set_selection(Selection::Word(editor.cursor))
      editor = Editor::{ ..editor, buffer: editor.buffer.set_redraw(true) }
    }
    TripleClick(x, y) => {
      editor = editor.action(Click(x, y))
      editor = editor.set_selection(Selection::Line(editor.cursor))
      editor = Editor::{ ..editor, buffer: editor.buffer.set_redraw(true) }
    }
    Drag(x, y) => {
      match editor.selection {
        Selection::None => {
          editor = editor.set_selection(Selection::Normal(editor.cursor))
          editor = Editor::{ ..editor, buffer: editor.buffer.set_redraw(true) }
        }
        _ => ()
      }
      match
        editor.buffer.hit(
          Float::from_double(x.to_double()),
          Float::from_double(y.to_double()),
        ) {
        None => ()
        Some(new_cursor) => editor = editor.set_cursor(new_cursor)
      }
    }
    Scroll(pixels) => {
      let scroll0 = editor.buffer.scroll()
      let scroll = Scroll::{ ..scroll0, vertical: scroll0.vertical + pixels }
      editor = Editor::{ ..editor, buffer: editor.buffer.set_scroll(scroll) }
    }
  }
  if old_cursor != editor.cursor {
    editor = Editor::{
      ..editor,
      cursor_moved: true,
      buffer: editor.buffer.set_redraw(true),
    }
  }
  editor
}
