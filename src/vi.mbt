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
/// Internal Vi-style editor layer on top of `moon_cosmic.Editor`.
pub(all) enum ViMode {
  Normal
  Insert
  Replace
  Visual
  VisualLine
  Search
}

///|
pub(all) enum ViOperator {
  Delete
  Change
  Yank
  ShiftLeft
  ShiftRight
}

///|
fn vi_motion_for_key(key : Char) -> Motion? {
  if key == 'h' {
    Some(Left)
  } else if key == 'j' {
    Some(Down)
  } else if key == 'k' {
    Some(Up)
  } else if key == 'l' {
    Some(Right)
  } else if key == 'w' {
    Some(NextWord)
  } else if key == 'b' {
    Some(PreviousWord)
  } else if key == 'B' {
    Some(PreviousWord)
  } else if key == 'e' {
    Some(RightWord)
  } else if key == 'E' {
    Some(RightWord)
  } else if key == 'W' {
    Some(NextWord)
  } else if key == '0' {
    Some(Home)
  } else if key == '^' {
    Some(SoftHome)
  } else if key == '$' {
    Some(End)
  } else {
    None
  }
}

///|
fn vi_with_visual_selection(editor : Editor, mode : ViMode) -> Editor {
  match mode {
    Visual => editor.set_selection(Selection::Normal(editor.cursor()))
    VisualLine => editor.set_selection(Selection::Line(editor.cursor()))
    _ => editor
  }
}

///|
fn vi_delete_current_line(editor : Editor) -> Editor {
  let cursor = editor.cursor()
  let line = cursor.line
  let lines = editor.buffer().lines()
  if line < 0 || line >= lines.length() {
    return editor
  }
  let end = lines[line].text().length()
  editor.delete_range(Cursor::new(line, 0), Cursor::new(line, end))
}

///|
fn vi_copy_current_line(editor : Editor) -> String? {
  let cursor = editor.cursor()
  let line = cursor.line
  let lines = editor.buffer().lines()
  if line < 0 || line >= lines.length() {
    return None
  }
  let line0 = lines[line]
  Some(line0.text() + line0.ending().as_str())
}

///|
fn vi_open_line_below(editor : Editor) -> Editor {
  let cursor = editor.cursor()
  let lines = editor.buffer().lines()
  if cursor.line < 0 || cursor.line >= lines.length() {
    return editor
  }
  let end = lines[cursor.line].text().length()
  let inserted = editor.insert_at(Cursor::new(cursor.line, end), "\n", None)
  inserted.0.set_cursor(inserted.1)
}

///|
fn vi_open_line_above(editor : Editor) -> Editor {
  let cursor = editor.cursor()
  let lines = editor.buffer().lines()
  if cursor.line < 0 || cursor.line >= lines.length() {
    return editor
  }
  let inserted = editor.insert_at(Cursor::new(cursor.line, 0), "\n", None)
  inserted.0.set_cursor(Cursor::new(cursor.line, 0))
}

///|
fn string_append_char(s : String, ch : Char) -> String {
  let sb = StringBuilder::new(size_hint=s.length() + ch.utf16_len())
  sb.write_string(s)
  sb.write_char(ch)
  sb.to_string()
}

///|
fn vi_digit_value(ch : Char) -> Int? {
  if ch == '0' {
    Some(0)
  } else if ch == '1' {
    Some(1)
  } else if ch == '2' {
    Some(2)
  } else if ch == '3' {
    Some(3)
  } else if ch == '4' {
    Some(4)
  } else if ch == '5' {
    Some(5)
  } else if ch == '6' {
    Some(6)
  } else if ch == '7' {
    Some(7)
  } else if ch == '8' {
    Some(8)
  } else if ch == '9' {
    Some(9)
  } else {
    None
  }
}

///|
fn vi_count_value(count_opt : Int?) -> Int {
  match count_opt {
    None => 1
    Some(v) => if v <= 0 { 1 } else { v }
  }
}

///|
fn vi_repeat_motion(editor : Editor, motion : Motion, count : Int) -> Editor {
  let mut out = editor
  let mut i = 0
  while i < count {
    out = out.action(Motion(motion))
    i = i + 1
  }
  out
}

///|
fn vi_repeat_put(
  editor : Editor,
  selection : Selection,
  data : String,
  after : Bool,
  count : Int,
) -> Editor {
  let mut out = editor
  let mut i = 0
  while i < count {
    out = vi_put_from_register(out, selection, data, after)
    i = i + 1
  }
  out
}

///|
fn vi_repeat_action(editor : Editor, action : Action, count : Int) -> Editor {
  let mut out = editor
  let mut i = 0
  while i < count {
    out = out.action(action)
    i = i + 1
  }
  out
}

///|
fn vi_apply_indent_lines(
  editor : Editor,
  count : Int,
  unindent : Bool,
) -> Editor {
  let cursor = editor.cursor()
  let lines = editor.buffer().lines()
  if cursor.line < 0 || cursor.line >= lines.length() {
    return editor
  }
  let count = if count <= 0 { 1 } else { count }
  let end_line = if cursor.line + count - 1 < lines.length() {
    cursor.line + count - 1
  } else {
    lines.length() - 1
  }
  let selected = editor.set_selection(Selection::Line(Cursor::new(end_line, 0)))
  let acted = if unindent {
    selected.action(Unindent)
  } else {
    selected.action(Indent)
  }
  acted.set_selection(Selection::None)
}

///|
fn vi_replace_one(editor : Editor, ch : Char) -> Editor {
  editor.action(Delete).action(Insert(ch)).action(Motion(Left))
}

///|
fn string_pop_last_char(s : String) -> String {
  if s.length() == 0 {
    return s
  }
  let mut last = 0
  for p in s.iter2() {
    last = p.0
  }
  let sb = StringBuilder::new(size_hint=last)
  sb.write_view(s[:].view(start_offset=0, end_offset=last))
  sb.to_string()
}

///|
fn find_substring_forward(text : String, pattern : String, start : Int) -> Int? {
  let plen = pattern.length()
  if plen == 0 || start < 0 || start > text.length() || plen > text.length() {
    return None
  }
  let end = text.length() - plen
  for i in start..<(end + 1) {
    let mut ok = true
    for j in 0..<plen {
      if text.code_unit_at(i + j) != pattern.code_unit_at(j) {
        ok = false
        break
      }
    }
    if ok {
      return Some(i)
    }
  }
  None
}

///|
fn find_substring_backward(
  text : String,
  pattern : String,
  end_exclusive : Int,
) -> Int? {
  let plen = pattern.length()
  if plen == 0 || plen > text.length() {
    return None
  }
  let end = if end_exclusive > text.length() {
    text.length()
  } else {
    end_exclusive
  }
  if end < plen {
    return None
  }
  let mut i = end - plen
  while true {
    let mut ok = true
    for j in 0..<plen {
      if text.code_unit_at(i + j) != pattern.code_unit_at(j) {
        ok = false
        break
      }
    }
    if ok {
      return Some(i)
    }
    if i == 0 {
      break
    }
    i = i - 1
  }
  None
}

///|
fn vi_search(editor : Editor, query : String, forwards : Bool) -> Editor {
  if query.length() == 0 {
    return editor
  }
  let cursor = editor.cursor()
  let lines = editor.buffer().lines()
  if lines.length() == 0 {
    return editor
  }
  if forwards {
    for line_i in cursor.line..<lines.length() {
      let text = lines[line_i].text()
      let start = if line_i == cursor.line { cursor.index + 1 } else { 0 }
      match find_substring_forward(text, query, start) {
        None => ()
        Some(index) =>
          return editor.set_cursor(
            Cursor::new_with_affinity(line_i, index, cursor.affinity),
          )
      }
    }
  } else {
    let mut line_i = cursor.line + 1
    while line_i > 0 {
      line_i = line_i - 1
      let text = lines[line_i].text()
      let end = if line_i == cursor.line { cursor.index } else { text.length() }
      match find_substring_backward(text, query, end) {
        None => ()
        Some(index) =>
          return editor.set_cursor(
            Cursor::new_with_affinity(line_i, index, cursor.affinity),
          )
      }
    }
  }
  editor
}

///|
fn vi_find_in_line(
  editor : Editor,
  target : Char,
  forwards : Bool,
  till : Bool,
) -> Editor {
  let cursor = editor.cursor()
  let lines = editor.buffer().lines()
  if cursor.line < 0 || cursor.line >= lines.length() {
    return editor
  }
  let text = lines[cursor.line].text()
  let target_len = target.utf16_len()
  if forwards {
    for p in text.iter2() {
      let idx = p.0
      let ch = p.1
      if idx > cursor.index && ch == target {
        let hit = if till { if idx > 0 { idx - 1 } else { idx } } else { idx }
        return editor.set_cursor(
          Cursor::new_with_affinity(cursor.line, hit, cursor.affinity),
        )
      }
    }
  } else {
    let mut found_opt : Int? = None
    for p in text.iter2() {
      let idx = p.0
      let ch = p.1
      if idx < cursor.index && ch == target {
        found_opt = Some(idx)
      }
    }
    match found_opt {
      None => ()
      Some(idx) => {
        let hit = if till { idx + target_len } else { idx }
        return editor.set_cursor(
          Cursor::new_with_affinity(cursor.line, hit, cursor.affinity),
        )
      }
    }
  }
  editor
}

///|
fn is_word_char(ch : Char) -> Bool {
  ch.is_ascii_alphabetic() || ch.is_numeric() || ch == '_'
}

///|
fn find_word_bounds(
  text : String,
  cursor_index : Int,
  with_delims : Bool,
) -> (Int, Int)? {
  if cursor_index < 0 || cursor_index >= text.length() {
    return None
  }
  for p in text.iter2() {
    let idx = p.0
    let ch = p.1
    let end = idx + ch.utf16_len()
    if cursor_index < idx || cursor_index >= end || !is_word_char(ch) {
      continue
    }

    let mut start = idx
    let mut stop = end

    let prevs : Array[(Int, Char)] = []
    for p0 in text.iter2() {
      if p0.0 >= idx {
        break
      }
      prevs.push(p0)
    }
    let mut i = prevs.length()
    while i > 0 {
      i = i - 1
      let p0 = prevs[i]
      if is_word_char(p0.1) {
        start = p0.0
      } else {
        break
      }
    }

    for p0 in text.iter2() {
      if p0.0 < end {
        continue
      }
      if is_word_char(p0.1) {
        stop = p0.0 + p0.1.utf16_len()
      } else {
        break
      }
    }

    if with_delims {
      let mut with_stop = stop
      let mut has_tail_space = false
      for p0 in text.iter2() {
        if p0.0 < stop {
          continue
        }
        if p0.1.is_whitespace() {
          has_tail_space = true
          with_stop = p0.0 + p0.1.utf16_len()
        } else {
          break
        }
      }

      let mut with_start = start
      if !has_tail_space {
        let prev_ws : Array[(Int, Char)] = []
        for p0 in text.iter2() {
          if p0.0 >= start {
            break
          }
          prev_ws.push(p0)
        }
        let mut j = prev_ws.length()
        while j > 0 {
          j = j - 1
          let p0 = prev_ws[j]
          if p0.1.is_whitespace() {
            with_start = p0.0
          } else {
            break
          }
        }
      }
      start = with_start
      stop = with_stop
    }

    return Some((start, stop))
  }
  None
}

///|
fn vi_select_word_text_object(
  editor : Editor,
  with_delims : Bool,
) -> (Editor, Bool) {
  let cursor = editor.cursor()
  let lines = editor.buffer().lines()
  if cursor.line < 0 || cursor.line >= lines.length() {
    return (editor, false)
  }
  let text = lines[cursor.line].text()
  match find_word_bounds(text, cursor.index, with_delims) {
    None => (editor, false)
    Some((start, end)) => {
      let start_cursor = Cursor::new_with_affinity(
        cursor.line,
        start,
        cursor.affinity,
      )
      let end_cursor = Cursor::new_with_affinity(
        cursor.line,
        end,
        cursor.affinity,
      )
      (
        editor
        .set_selection(Selection::Normal(start_cursor))
        .set_cursor(end_cursor),
        true,
      )
    }
  }
}

///|
fn vi_select_in(
  editor : Editor,
  start_c : Char,
  end_c : Char,
  with_delims : Bool,
) -> (Editor, Bool) {
  let cursor = editor.cursor()
  let lines = editor.buffer().lines()
  if cursor.line < 0 || cursor.line >= lines.length() {
    return (editor, false)
  }

  let mut end_line = cursor.line
  let mut end_index = cursor.index
  let mut starts = 0
  let mut ends = 0
  let mut found_end = false
  while !found_end {
    if end_line < 0 || end_line >= lines.length() {
      break
    }
    let text = lines[end_line].text()
    for p in text.iter2() {
      let i = p.0
      let c = p.1
      if i < end_index {
        continue
      }
      if c == end_c {
        ends = ends + 1
      } else if c == start_c {
        starts = starts + 1
      }
      if ends > starts {
        end_index = if with_delims { i + c.utf16_len() } else { i }
        found_end = true
        break
      }
    }
    if found_end {
      break
    }
    if end_line + 1 < lines.length() {
      end_line = end_line + 1
      end_index = 0
    } else {
      break
    }
  }
  if !found_end {
    return (editor, false)
  }

  let mut start_line = cursor.line
  let mut start_index = cursor.index
  let mut found_start = false
  while !found_start {
    if start_line < 0 || start_line >= lines.length() {
      break
    }
    let text = lines[start_line].text()
    let prevs : Array[(Int, Char)] = []
    for p in text.iter2() {
      if p.0 >= start_index {
        break
      }
      prevs.push(p)
    }
    let mut i = prevs.length()
    while i > 0 {
      i = i - 1
      let p = prevs[i]
      let c = p.1
      if c == start_c {
        starts = starts + 1
      } else if c == end_c {
        ends = ends + 1
      }
      if starts >= ends {
        start_index = if with_delims { p.0 } else { p.0 + c.utf16_len() }
        found_start = true
        break
      }
    }
    if found_start {
      break
    }
    if start_line > 0 {
      start_line = start_line - 1
      start_index = lines[start_line].text().length()
    } else {
      break
    }
  }
  if !found_start {
    return (editor, false)
  }

  let start_cursor = Cursor::new_with_affinity(
    start_line,
    start_index,
    cursor.affinity,
  )
  let end_cursor = Cursor::new_with_affinity(
    end_line,
    end_index,
    cursor.affinity,
  )
  (
    editor.set_selection(Selection::Normal(start_cursor)).set_cursor(end_cursor),
    true,
  )
}

///|
fn vi_select_text_object(
  editor : Editor,
  key : Char,
  with_delims : Bool,
) -> (Editor, Bool) {
  if key == 'w' || key == 'W' {
    return vi_select_word_text_object(editor, with_delims)
  }
  if key == '<' || key == '>' {
    return vi_select_in(editor, '<', '>', with_delims)
  }
  if key == '{' || key == '}' {
    return vi_select_in(editor, '{', '}', with_delims)
  }
  if key == '(' || key == ')' {
    return vi_select_in(editor, '(', ')', with_delims)
  }
  if key == '[' || key == ']' {
    return vi_select_in(editor, '[', ']', with_delims)
  }
  if key == '"' {
    return vi_select_in(editor, '"', '"', with_delims)
  }
  if key == '\'' {
    return vi_select_in(editor, '\'', '\'', with_delims)
  }
  if key == '`' {
    return vi_select_in(editor, '`', '`', with_delims)
  }
  (editor, false)
}

///|
fn vi_apply_text_object_operator(
  editor : Editor,
  op : ViOperator,
  key : Char,
  with_delims : Bool,
) -> (Editor, ViMode, (Selection, String)?, Bool) {
  let selected = vi_select_text_object(editor, key, with_delims)
  if !selected.1 {
    return (editor, Normal, None, false)
  }
  let selected_editor = selected.0
  let selection = selected_editor.selection()
  match op {
    Delete => {
      let captured : (Selection, String)? = match
        selected_editor.copy_selection() {
        None => None
        Some(data) => Some((selection, data))
      }
      let deleted = selected_editor.delete_selection()
      (deleted.0, Normal, captured, deleted.1)
    }
    Change => {
      let captured : (Selection, String)? = match
        selected_editor.copy_selection() {
        None => None
        Some(data) => Some((selection, data))
      }
      let deleted = selected_editor.delete_selection()
      (deleted.0, Insert, captured, deleted.1)
    }
    Yank => {
      let captured : (Selection, String)? = match
        selected_editor.copy_selection() {
        None => None
        Some(data) => Some((selection, data))
      }
      (selected_editor.set_selection(Selection::None), Normal, captured, true)
    }
    ShiftLeft =>
      (
        selected_editor.action(Unindent).set_selection(Selection::None),
        Normal,
        None,
        true,
      )
    ShiftRight =>
      (
        selected_editor.action(Indent).set_selection(Selection::None),
        Normal,
        None,
        true,
      )
  }
}

///|
fn vi_register_get(
  registers : Array[(Char, Selection, String)],
  key : Char,
) -> (Selection, String)? {
  for entry in registers {
    if entry.0 == key {
      return Some((entry.1, entry.2))
    }
  }
  None
}

///|
fn vi_register_set(
  registers : Array[(Char, Selection, String)],
  key : Char,
  selection : Selection,
  data : String,
) -> Array[(Char, Selection, String)] {
  let out : Array[(Char, Selection, String)] = []
  let mut replaced = false
  for entry in registers {
    if entry.0 == key {
      out.push((key, selection, data))
      replaced = true
    } else {
      out.push(entry)
    }
  }
  if !replaced {
    out.push((key, selection, data))
  }
  out
}

///|
fn vi_target_register_key(key_opt : Char?) -> Char {
  match key_opt {
    None => '"'
    Some(key) => key
  }
}

///|
fn vi_put_from_register(
  editor : Editor,
  selection : Selection,
  data : String,
  after : Bool,
) -> Editor {
  match selection {
    Selection::Line(_) => {
      let cursor = editor.cursor()
      let line = if after { cursor.line + 1 } else { cursor.line }
      let inserted = editor.insert_at(Cursor::new(line, 0), data, None)
      inserted.0.set_cursor(inserted.1)
    }
    _ => {
      let editor = if after {
        let moved = editor.action(Motion(Right))
        if moved.cursor().line == editor.cursor().line {
          moved
        } else {
          editor
        }
      } else {
        editor
      }
      editor.insert_string(data, None)
    }
  }
}

///|
fn vi_capture_current_line(editor : Editor) -> (Selection, String)? {
  match vi_copy_current_line(editor) {
    None => None
    Some(data) => Some((Selection::Line(editor.cursor()), data))
  }
}

///|
fn vi_capture_lines(
  editor : Editor,
  start_line : Int,
  count : Int,
) -> (Selection, String)? {
  let lines = editor.buffer().lines()
  if start_line < 0 || start_line >= lines.length() {
    return None
  }
  let end_exclusive = if start_line + count < lines.length() {
    start_line + count
  } else {
    lines.length()
  }
  let sb = StringBuilder::new()
  let mut i = start_line
  while i < end_exclusive {
    let line = lines[i]
    sb.write_string(line.text())
    sb.write_string(line.ending().as_str())
    i = i + 1
  }
  let data = sb.to_string()
  if data == "" {
    None
  } else {
    Some((Selection::Line(editor.cursor()), data))
  }
}

///|
fn vi_delete_count_lines(
  editor : Editor,
  count : Int,
) -> (Editor, (Selection, String)?) {
  let cursor = editor.cursor()
  let lines = editor.buffer().lines()
  if cursor.line < 0 || cursor.line >= lines.length() {
    return (editor, None)
  }
  let count = if count <= 0 { 1 } else { count }
  let start_line = cursor.line
  let last_line = lines.length() - 1
  let end_line = if start_line + count - 1 < last_line {
    start_line + count - 1
  } else {
    last_line
  }
  let captured = vi_capture_lines(editor, start_line, count)
  let start = Cursor::new(start_line, 0)
  let end = if end_line < last_line {
    Cursor::new(end_line + 1, 0)
  } else {
    Cursor::new(end_line, lines[end_line].text().length())
  }
  let deleted = editor.delete_range(start, end)
  (deleted.set_cursor(Cursor::new(start_line, 0)), captured)
}

///|
fn vi_delete_to_line_end(editor : Editor) -> (Editor, (Selection, String)?) {
  let cursor = editor.cursor()
  let lines = editor.buffer().lines()
  if cursor.line < 0 || cursor.line >= lines.length() {
    return (editor, None)
  }
  let end_index = lines[cursor.line].text().length()
  if cursor.index >= end_index {
    return (editor, None)
  }
  let end = Cursor::new(cursor.line, end_index)
  let selected = editor.set_selection(Selection::Normal(cursor)).set_cursor(end)
  let captured : (Selection, String)? = match selected.copy_selection() {
    None => None
    Some(data) => Some((selected.selection(), data))
  }
  let deleted = selected.delete_selection()
  if deleted.1 {
    (deleted.0, captured)
  } else {
    (editor, None)
  }
}

///|
pub struct ViEditor {
  editor : Editor
  mode : ViMode
  pending_operator : ViOperator?
  passthrough : Bool
  history : Array[Change]
  history_index : Int
  save_pivot_opt : Int?
  changed : Bool
  search_opt : (String, Bool)?
  search_input_opt : String?
  search_input_forwards : Bool
  pending_find_opt : (Bool, Bool, Int)?
  last_find_opt : (Bool, Bool, Char)?
  pending_replace_char : Bool
  pending_text_object_opt : (ViOperator, Bool)?
  pending_g : Bool
  pending_count_opt : Int?
  pending_register_prefix : Bool
  active_register_opt : Char?
  registers : Array[(Char, Selection, String)]
  register_opt : String?
}

///|
pub fn ViEditor::new(editor : Editor) -> ViEditor {
  ViEditor::{
    editor,
    mode: Normal,
    pending_operator: None,
    passthrough: false,
    history: [],
    history_index: 0,
    save_pivot_opt: None,
    changed: false,
    search_opt: None,
    search_input_opt: None,
    search_input_forwards: true,
    pending_find_opt: None,
    last_find_opt: None,
    pending_replace_char: false,
    pending_text_object_opt: None,
    pending_g: false,
    pending_count_opt: None,
    pending_register_prefix: false,
    active_register_opt: None,
    registers: [],
    register_opt: None,
  }
}

///|
pub fn ViEditor::editor(self : ViEditor) -> Editor {
  self.editor
}

///|
pub fn ViEditor::mode(self : ViEditor) -> ViMode {
  self.mode
}

///|
pub fn ViEditor::changed(self : ViEditor) -> Bool {
  self.changed
}

///|
pub fn ViEditor::set_changed(self : ViEditor, changed : Bool) -> ViEditor {
  ViEditor::{ ..self, changed, }
}

///|
pub fn ViEditor::save_point(self : ViEditor) -> ViEditor {
  ViEditor::{ ..self, save_pivot_opt: Some(self.history_index), changed: false }
}

///|
pub fn ViEditor::set_passthrough(
  self : ViEditor,
  passthrough : Bool,
) -> ViEditor {
  ViEditor::{ ..self, passthrough, }
}

///|
pub fn ViEditor::set_editor(self : ViEditor, editor : Editor) -> ViEditor {
  ViEditor::{ ..self, editor, }
}

///|
pub fn ViEditor::escape(self : ViEditor) -> ViEditor {
  ViEditor::{
    ..self,
    editor: self.editor.set_selection(Selection::None),
    mode: Normal,
    pending_operator: None,
    search_input_opt: None,
    search_input_forwards: true,
    pending_find_opt: None,
    pending_replace_char: false,
    pending_text_object_opt: None,
    pending_g: false,
    pending_count_opt: None,
    pending_register_prefix: false,
    active_register_opt: None,
  }
}

///|
fn vi_eval_changed(history_index : Int, save_pivot_opt : Int?) -> Bool {
  match save_pivot_opt {
    Some(pivot) => history_index != pivot
    None => history_index != 0
  }
}

///|
fn ViEditor::push_change(self : ViEditor, change : Change) -> ViEditor {
  let history : Array[Change] = []
  for i in 0..<self.history_index {
    history.push(self.history[i])
  }
  history.push(change)
  let history_index = history.length()
  ViEditor::{
    ..self,
    history,
    history_index,
    changed: vi_eval_changed(history_index, self.save_pivot_opt),
  }
}

///|
fn ViEditor::set_register(
  self : ViEditor,
  selection : Selection,
  data : String,
) -> ViEditor {
  let target = vi_target_register_key(self.active_register_opt)
  let registers0 = vi_register_set(self.registers, '"', selection, data)
  let registers = if target == '"' {
    registers0
  } else {
    vi_register_set(registers0, target, selection, data)
  }
  ViEditor::{
    ..self,
    registers,
    register_opt: Some(data),
    active_register_opt: None,
    pending_register_prefix: false,
  }
}

///|
fn ViEditor::register_for_put(self : ViEditor) -> (Selection, String)? {
  let target = vi_target_register_key(self.active_register_opt)
  match vi_register_get(self.registers, target) {
    Some(value) => Some(value)
    None =>
      if target == '"' {
        match self.register_opt {
          None => None
          Some(data) => Some((Selection::None, data))
        }
      } else {
        None
      }
  }
}

///|
fn ViEditor::finalize_change(self : ViEditor) -> ViEditor {
  let finished = self.editor.finish_change()
  let editor = finished.0
  let with_editor = ViEditor::{ ..self, editor, }
  match finished.1 {
    None => with_editor
    Some(change) =>
      if change.items.length() == 0 {
        with_editor
      } else {
        with_editor.push_change(change)
      }
  }
}

///|
fn ViEditor::feed_char_inner(self : ViEditor, key : Char) -> ViEditor {
  match self.search_input_opt {
    None => ()
    Some(query) =>
      if key == '\n' {
        let forwards = self.search_input_forwards
        let editor = vi_search(self.editor, query, forwards)
        return ViEditor::{
          ..self,
          editor,
          mode: Normal,
          search_opt: Some((query, forwards)),
          search_input_opt: None,
          search_input_forwards: true,
        }
      } else if key == '\u{08}' || key == '\u{7F}' {
        return ViEditor::{
          ..self,
          search_input_opt: Some(string_pop_last_char(query)),
        }
      } else {
        return ViEditor::{
          ..self,
          mode: Search,
          search_input_opt: Some(string_append_char(query, key)),
        }
      }
  }

  match self.pending_find_opt {
    None => ()
    Some((forwards, till, find_count)) => {
      let mut editor = self.editor
      let mut i = 0
      while i < find_count {
        editor = vi_find_in_line(editor, key, forwards, till)
        i = i + 1
      }
      return ViEditor::{
        ..self,
        editor,
        pending_find_opt: None,
        last_find_opt: Some((forwards, till, key)),
      }
    }
  }

  if self.pending_replace_char {
    return ViEditor::{
      ..self,
      editor: vi_replace_one(self.editor, key),
      pending_replace_char: false,
      mode: Normal,
      pending_count_opt: None,
    }
  }

  match self.pending_text_object_opt {
    None => ()
    Some((op, with_delims)) => {
      let applied = vi_apply_text_object_operator(
        self.editor,
        op,
        key,
        with_delims,
      )
      let with_state = ViEditor::{
        ..self,
        editor: applied.0,
        mode: applied.1,
        pending_operator: None,
        pending_text_object_opt: None,
      }
      match applied.2 {
        None => return with_state
        Some(captured) => return with_state.set_register(captured.0, captured.1)
      }
    }
  }

  if self.pending_register_prefix {
    return ViEditor::{
      ..self,
      pending_register_prefix: false,
      active_register_opt: Some(key),
    }
  }

  if self.pending_g {
    if key == 'g' {
      let editor = match self.pending_count_opt {
        None => self.editor.action(Motion(BufferStart))
        Some(count) =>
          self.editor.action(
            Motion(GotoLine(if count <= 0 { 0 } else { count - 1 })),
          )
      }
      return ViEditor::{
        ..self,
        editor,
        pending_g: false,
        pending_count_opt: None,
      }
    }
    if key == 'e' || key == 'E' {
      return ViEditor::{
        ..self,
        editor: self.editor
        .action(Motion(PreviousWord))
        .action(Motion(RightWord)),
        pending_g: false,
        pending_count_opt: None,
      }
    }
    if key == 'n' || key == 'N' {
      match self.search_opt {
        None =>
          return ViEditor::{ ..self, pending_g: false, pending_count_opt: None }
        Some((query, forwards0)) => {
          let forwards = if key == 'n' { forwards0 } else { !forwards0 }
          let searched = vi_search(self.editor, query, forwards)
          let cursor = searched.cursor()
          let end = Cursor::new(cursor.line, cursor.index + query.length())
          return ViEditor::{
            ..self,
            editor: searched
            .set_selection(Selection::Normal(cursor))
            .set_cursor(end),
            pending_g: false,
            pending_count_opt: None,
          }
        }
      }
    }
    return ViEditor::{ ..self, pending_g: false }.feed_char_inner(key)
  }

  if self.passthrough {
    if key == '\n' {
      return ViEditor::{ ..self, editor: self.editor.action(Enter) }
    }
    return ViEditor::{ ..self, editor: self.editor.action(Insert(key)) }
  }
  match self.mode {
    Insert =>
      if key == '\n' {
        ViEditor::{ ..self, editor: self.editor.action(Enter) }
      } else {
        ViEditor::{ ..self, editor: self.editor.action(Insert(key)) }
      }
    Replace =>
      if key == '\n' {
        ViEditor::{ ..self, editor: self.editor.action(Enter) }
      } else {
        ViEditor::{
          ..self,
          editor: self.editor.action(Delete).action(Insert(key)),
        }
      }
    Visual | VisualLine => {
      if key == 'v' && self.mode is Visual {
        return self.escape()
      }
      if key == 'V' && self.mode is VisualLine {
        return self.escape()
      }
      match vi_motion_for_key(key) {
        None => self
        Some(motion) =>
          ViEditor::{ ..self, editor: self.editor.action(Motion(motion)) }
      }
    }
    Search => self
    Normal => {
      match vi_digit_value(key) {
        None => ()
        Some(digit) =>
          if key != '0' || self.pending_count_opt is Some(_) {
            let base = match self.pending_count_opt {
              None => 0
              Some(v) => v
            }
            return ViEditor::{
              ..self,
              pending_count_opt: Some(base * 10 + digit),
            }
          }
      }
      let count = vi_count_value(self.pending_count_opt)
      match self.pending_operator {
        Some(Delete) =>
          if key == 'i' {
            ViEditor::{
              ..self,
              pending_operator: None,
              pending_text_object_opt: Some((Delete, false)),
            }
          } else if key == 'a' {
            ViEditor::{
              ..self,
              pending_operator: None,
              pending_text_object_opt: Some((Delete, true)),
            }
          } else if key == 'd' {
            let deleted = vi_delete_count_lines(self.editor, count)
            let with_editor = ViEditor::{
              ..self,
              editor: deleted.0,
              pending_operator: None,
              pending_count_opt: None,
            }
            match deleted.1 {
              None => with_editor
              Some(captured) => with_editor.set_register(captured.0, captured.1)
            }
          } else {
            let after_op = ViEditor::{
              ..self,
              pending_operator: None,
              pending_count_opt: None,
            }
            match vi_motion_for_key(key) {
              None => after_op
              Some(motion) =>
                ViEditor::{
                  ..after_op,
                  editor: vi_repeat_motion(after_op.editor, motion, count).action(
                    Delete,
                  ),
                }
            }
          }
        Some(Change) =>
          if key == 'i' {
            ViEditor::{
              ..self,
              pending_operator: None,
              pending_text_object_opt: Some((Change, false)),
            }
          } else if key == 'a' {
            ViEditor::{
              ..self,
              pending_operator: None,
              pending_text_object_opt: Some((Change, true)),
            }
          } else if key == 'c' {
            let deleted = vi_delete_count_lines(self.editor, count)
            let with_editor = ViEditor::{
              ..self,
              editor: deleted.0,
              mode: Insert,
              pending_operator: None,
              pending_count_opt: None,
            }
            match deleted.1 {
              None => with_editor
              Some(captured) => with_editor.set_register(captured.0, captured.1)
            }
          } else {
            let after_op = ViEditor::{
              ..self,
              pending_operator: None,
              pending_count_opt: None,
            }
            match vi_motion_for_key(key) {
              None => after_op
              Some(motion) =>
                ViEditor::{
                  ..after_op,
                  editor: vi_repeat_motion(after_op.editor, motion, count).action(
                    Delete,
                  ),
                  mode: Insert,
                }
            }
          }
        Some(Yank) =>
          if key == 'i' {
            ViEditor::{
              ..self,
              pending_operator: None,
              pending_text_object_opt: Some((Yank, false)),
            }
          } else if key == 'a' {
            ViEditor::{
              ..self,
              pending_operator: None,
              pending_text_object_opt: Some((Yank, true)),
            }
          } else if key == 'y' {
            let with_state = ViEditor::{
              ..self,
              pending_operator: None,
              pending_count_opt: None,
            }
            match
              vi_capture_lines(self.editor, self.editor.cursor().line, count) {
              None => with_state
              Some(captured) => with_state.set_register(captured.0, captured.1)
            }
          } else {
            ViEditor::{
              ..self,
              pending_operator: None,
              pending_count_opt: None,
            }
          }
        Some(ShiftLeft) =>
          if key == '<' {
            ViEditor::{
              ..self,
              editor: vi_apply_indent_lines(self.editor, count, true),
              pending_operator: None,
              pending_count_opt: None,
            }
          } else {
            ViEditor::{
              ..self,
              pending_operator: None,
              pending_count_opt: None,
            }
          }
        Some(ShiftRight) =>
          if key == '>' {
            ViEditor::{
              ..self,
              editor: vi_apply_indent_lines(self.editor, count, false),
              pending_operator: None,
              pending_count_opt: None,
            }
          } else {
            ViEditor::{
              ..self,
              pending_operator: None,
              pending_count_opt: None,
            }
          }
        None =>
          if key == 'i' {
            ViEditor::{ ..self, mode: Insert, pending_count_opt: None }
          } else if key == 'I' {
            ViEditor::{
              ..self,
              editor: self.editor.action(Motion(Home)),
              mode: Insert,
              pending_count_opt: None,
            }
          } else if key == 'a' {
            ViEditor::{
              ..self,
              editor: self.editor.action(Motion(Right)),
              mode: Insert,
              pending_count_opt: None,
            }
          } else if key == 'A' {
            ViEditor::{
              ..self,
              editor: self.editor.action(Motion(End)),
              mode: Insert,
              pending_count_opt: None,
            }
          } else if key == 'v' {
            let mode = Visual
            ViEditor::{
              ..self,
              mode,
              editor: vi_with_visual_selection(self.editor, mode),
              pending_count_opt: None,
            }
          } else if key == 'V' {
            let mode = VisualLine
            ViEditor::{
              ..self,
              mode,
              editor: vi_with_visual_selection(self.editor, mode),
              pending_count_opt: None,
            }
          } else if key == 'x' {
            ViEditor::{
              ..self,
              editor: vi_repeat_action(self.editor, Delete, count),
              pending_count_opt: None,
            }
          } else if key == 'X' {
            ViEditor::{
              ..self,
              editor: vi_repeat_action(self.editor, Backspace, count),
              pending_count_opt: None,
            }
          } else if key == 's' {
            ViEditor::{
              ..self,
              editor: vi_repeat_action(self.editor, Delete, count),
              mode: Insert,
              pending_count_opt: None,
            }
          } else if key == 'r' {
            ViEditor::{
              ..self,
              pending_replace_char: true,
              pending_count_opt: None,
            }
          } else if key == 'R' {
            ViEditor::{ ..self, mode: Replace, pending_count_opt: None }
          } else if key == 'o' {
            ViEditor::{
              ..self,
              editor: vi_open_line_below(self.editor),
              mode: Insert,
              pending_count_opt: None,
            }
          } else if key == 'O' {
            ViEditor::{
              ..self,
              editor: vi_open_line_above(self.editor),
              mode: Insert,
              pending_count_opt: None,
            }
          } else if key == 'D' {
            let deleted = vi_delete_to_line_end(self.editor)
            let with_editor = ViEditor::{
              ..self,
              editor: deleted.0,
              pending_count_opt: None,
            }
            match deleted.1 {
              None => with_editor
              Some(captured) => with_editor.set_register(captured.0, captured.1)
            }
          } else if key == 'C' {
            let deleted = vi_delete_to_line_end(self.editor)
            let with_editor = ViEditor::{
              ..self,
              editor: deleted.0,
              mode: Insert,
              pending_count_opt: None,
            }
            match deleted.1 {
              None => with_editor
              Some(captured) => with_editor.set_register(captured.0, captured.1)
            }
          } else if key == 'S' {
            let with_editor = ViEditor::{
              ..self,
              editor: vi_delete_current_line(self.editor),
              mode: Insert,
              pending_count_opt: None,
            }
            match vi_capture_current_line(self.editor) {
              None => with_editor
              Some(captured) => with_editor.set_register(captured.0, captured.1)
            }
          } else if key == 'Y' {
            match
              vi_capture_lines(self.editor, self.editor.cursor().line, count) {
              None => ViEditor::{ ..self, pending_count_opt: None }
              Some(captured) =>
                ViEditor::{ ..self, pending_count_opt: None }.set_register(
                  captured.0,
                  captured.1,
                )
            }
          } else if key == 'g' {
            ViEditor::{ ..self, pending_g: true }
          } else if key == 'G' {
            let editor = match self.pending_count_opt {
              None => self.editor.action(Motion(BufferEnd))
              Some(n) =>
                self.editor.action(
                  Motion(GotoLine(if n <= 0 { 0 } else { n - 1 })),
                )
            }
            ViEditor::{ ..self, editor, pending_count_opt: None }
          } else if key == '"' {
            ViEditor::{ ..self, pending_register_prefix: true }
          } else if key == '/' {
            ViEditor::{
              ..self,
              mode: Search,
              search_input_opt: Some(""),
              search_input_forwards: true,
              pending_count_opt: None,
            }
          } else if key == '?' {
            ViEditor::{
              ..self,
              mode: Search,
              search_input_opt: Some(""),
              search_input_forwards: false,
              pending_count_opt: None,
            }
          } else if key == 'n' {
            match self.search_opt {
              None => self
              Some((query, forwards)) =>
                ViEditor::{
                  ..self,
                  editor: vi_search(self.editor, query, forwards),
                  pending_count_opt: None,
                }
            }
          } else if key == 'N' {
            match self.search_opt {
              None => self
              Some((query, forwards)) =>
                ViEditor::{
                  ..self,
                  editor: vi_search(self.editor, query, !forwards),
                  pending_count_opt: None,
                }
            }
          } else if key == 'f' {
            ViEditor::{
              ..self,
              pending_find_opt: Some((true, false, count)),
              pending_count_opt: None,
            }
          } else if key == 'F' {
            ViEditor::{
              ..self,
              pending_find_opt: Some((false, false, count)),
              pending_count_opt: None,
            }
          } else if key == 't' {
            ViEditor::{
              ..self,
              pending_find_opt: Some((true, true, count)),
              pending_count_opt: None,
            }
          } else if key == 'T' {
            ViEditor::{
              ..self,
              pending_find_opt: Some((false, true, count)),
              pending_count_opt: None,
            }
          } else if key == ';' {
            match self.last_find_opt {
              None => ViEditor::{ ..self, pending_count_opt: None }
              Some(last) =>
                ViEditor::{
                  ..self,
                  editor: vi_find_in_line(self.editor, last.2, last.0, last.1),
                  pending_count_opt: None,
                }
            }
          } else if key == ',' {
            match self.last_find_opt {
              None => ViEditor::{ ..self, pending_count_opt: None }
              Some(last) =>
                ViEditor::{
                  ..self,
                  editor: vi_find_in_line(self.editor, last.2, !last.0, last.1),
                  pending_count_opt: None,
                }
            }
          } else if key == '-' {
            ViEditor::{
              ..self,
              editor: self.editor.action(Motion(Up)).action(Motion(SoftHome)),
              pending_count_opt: None,
            }
          } else if key == '+' {
            ViEditor::{
              ..self,
              editor: self.editor.action(Motion(Down)).action(Motion(SoftHome)),
              pending_count_opt: None,
            }
          } else if key == '<' {
            ViEditor::{ ..self, pending_operator: Some(ShiftLeft) }
          } else if key == '>' {
            ViEditor::{ ..self, pending_operator: Some(ShiftRight) }
          } else if key == 'p' {
            match self.register_for_put() {
              None => self
              Some(register) =>
                ViEditor::{
                  ..self,
                  editor: vi_repeat_put(
                    self.editor,
                    register.0,
                    register.1,
                    true,
                    count,
                  ),
                  active_register_opt: None,
                  pending_count_opt: None,
                }
            }
          } else if key == 'P' {
            match self.register_for_put() {
              None => self
              Some(register) =>
                ViEditor::{
                  ..self,
                  editor: vi_repeat_put(
                    self.editor,
                    register.0,
                    register.1,
                    false,
                    count,
                  ),
                  active_register_opt: None,
                  pending_count_opt: None,
                }
            }
          } else if key == 'd' {
            ViEditor::{ ..self, pending_operator: Some(Delete) }
          } else if key == 'c' {
            ViEditor::{ ..self, pending_operator: Some(Change) }
          } else if key == 'y' {
            ViEditor::{ ..self, pending_operator: Some(Yank) }
          } else if key == 'u' {
            self.undo()
          } else if key == '\u{12}' {
            self.redo()
          } else {
            match vi_motion_for_key(key) {
              None => ViEditor::{ ..self, pending_count_opt: None }
              Some(motion) =>
                ViEditor::{
                  ..self,
                  editor: vi_repeat_motion(self.editor, motion, count),
                  pending_count_opt: None,
                }
            }
          }
      }
    }
  }
}

///|
pub fn ViEditor::feed_char(self : ViEditor, key : Char) -> ViEditor {
  if key == '\u{1B}' {
    return self.escape()
  }
  let started = ViEditor::{ ..self, editor: self.editor.start_change() }
  started.feed_char_inner(key).finalize_change()
}

///|
pub fn ViEditor::undo(self : ViEditor) -> ViEditor {
  if self.history_index == 0 {
    return self
  }
  let change = self.history[self.history_index - 1].reverse()
  let applied = self.editor.apply_change(change)
  if !applied.1 {
    return self
  }
  let history_index = self.history_index - 1
  ViEditor::{
    ..self,
    editor: applied.0,
    history_index,
    changed: vi_eval_changed(history_index, self.save_pivot_opt),
    mode: Normal,
    pending_operator: None,
    pending_text_object_opt: None,
    pending_g: false,
    pending_count_opt: None,
    pending_register_prefix: false,
    active_register_opt: None,
    pending_replace_char: false,
  }
}

///|
pub fn ViEditor::redo(self : ViEditor) -> ViEditor {
  if self.history_index >= self.history.length() {
    return self
  }
  let change = self.history[self.history_index]
  let applied = self.editor.apply_change(change)
  if !applied.1 {
    return self
  }
  let history_index = self.history_index + 1
  ViEditor::{
    ..self,
    editor: applied.0,
    history_index,
    changed: vi_eval_changed(history_index, self.save_pivot_opt),
    mode: Normal,
    pending_operator: None,
    pending_text_object_opt: None,
    pending_g: false,
    pending_count_opt: None,
    pending_register_prefix: false,
    active_register_opt: None,
    pending_replace_char: false,
  }
}

///|
pub fn ViEditor::feed_string(self : ViEditor, keys : String) -> ViEditor {
  let mut out = self
  for key in keys {
    out = out.feed_char(key)
  }
  out
}
