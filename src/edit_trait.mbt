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
/// Shared editable surface for `Editor`/`SyntaxEditor`/`ViEditor`.
pub(open) trait Edit {
  fn editor(Self) -> Editor
  fn set_editor(Self, Editor) -> Self
  fn cursor(Self) -> Cursor
  fn set_cursor(Self, Cursor) -> Self
  fn selection(Self) -> Selection
  fn set_selection(Self, Selection) -> Self
  fn auto_indent(Self) -> Bool
  fn set_auto_indent(Self, Bool) -> Self
  fn tab_width(Self) -> Int
  fn set_tab_width(Self, Int) -> Self
  fn start_change(Self) -> Self
  fn finish_change(Self) -> (Self, Change?)
  fn copy_selection(Self) -> String?
  fn delete_selection(Self) -> (Self, Bool)
  fn delete_range(Self, Cursor, Cursor) -> Self
  fn insert_string(Self, String, AttrsList?) -> Self
  fn apply_change(Self, Change) -> (Self, Bool)
  fn cursor_position(Self) -> (Int, Int)?
  fn action(Self, Action) -> Self
}

///|
pub impl Edit for Editor with fn editor(self) {
  self
}

///|
pub impl Edit for Editor with fn set_editor(_self, editor) {
  editor
}

///|
pub impl Edit for Editor with fn cursor(self) {
  self.cursor()
}

///|
pub impl Edit for Editor with fn set_cursor(self, cursor) {
  self.set_cursor(cursor)
}

///|
pub impl Edit for Editor with fn selection(self) {
  self.selection()
}

///|
pub impl Edit for Editor with fn set_selection(self, selection) {
  self.set_selection(selection)
}

///|
pub impl Edit for Editor with fn auto_indent(self) {
  self.auto_indent()
}

///|
pub impl Edit for Editor with fn set_auto_indent(self, auto_indent) {
  self.set_auto_indent(auto_indent)
}

///|
pub impl Edit for Editor with fn tab_width(self) {
  self.tab_width()
}

///|
pub impl Edit for Editor with fn set_tab_width(self, tab_width) {
  self.set_tab_width(tab_width)
}

///|
pub impl Edit for Editor with fn start_change(self) {
  self.start_change()
}

///|
pub impl Edit for Editor with fn finish_change(self) {
  self.finish_change()
}

///|
pub impl Edit for Editor with fn copy_selection(self) {
  self.copy_selection()
}

///|
pub impl Edit for Editor with fn delete_selection(self) {
  self.delete_selection()
}

///|
pub impl Edit for Editor with fn delete_range(self, start, end) {
  self.delete_range(start, end)
}

///|
pub impl Edit for Editor with fn insert_string(self, data, attrs_list_opt) {
  self.insert_string(data, attrs_list_opt)
}

///|
pub impl Edit for Editor with fn apply_change(self, change) {
  self.apply_change(change)
}

///|
pub impl Edit for Editor with fn cursor_position(self) {
  self.cursor_position()
}

///|
pub impl Edit for Editor with fn action(self, action) {
  self.action(action)
}

///|
pub impl Edit for SyntaxEditor with fn editor(self) {
  self.editor()
}

///|
pub impl Edit for SyntaxEditor with fn set_editor(self, editor) {
  self.set_editor(editor)
}

///|
pub impl Edit for SyntaxEditor with fn cursor(self) {
  self.cursor()
}

///|
pub impl Edit for SyntaxEditor with fn set_cursor(self, cursor) {
  self.set_cursor(cursor)
}

///|
pub impl Edit for SyntaxEditor with fn selection(self) {
  self.selection()
}

///|
pub impl Edit for SyntaxEditor with fn set_selection(self, selection) {
  self.set_selection(selection)
}

///|
pub impl Edit for SyntaxEditor with fn auto_indent(self) {
  self.auto_indent()
}

///|
pub impl Edit for SyntaxEditor with fn set_auto_indent(self, auto_indent) {
  self.set_auto_indent(auto_indent)
}

///|
pub impl Edit for SyntaxEditor with fn tab_width(self) {
  self.tab_width()
}

///|
pub impl Edit for SyntaxEditor with fn set_tab_width(self, tab_width) {
  self.set_tab_width(tab_width)
}

///|
pub impl Edit for SyntaxEditor with fn start_change(self) {
  self.start_change()
}

///|
pub impl Edit for SyntaxEditor with fn finish_change(self) {
  self.finish_change()
}

///|
pub impl Edit for SyntaxEditor with fn copy_selection(self) {
  self.copy_selection()
}

///|
pub impl Edit for SyntaxEditor with fn delete_selection(self) {
  self.delete_selection()
}

///|
pub impl Edit for SyntaxEditor with fn delete_range(self, start, end) {
  self.delete_range(start, end)
}

///|
pub impl Edit for SyntaxEditor with fn insert_string(self, data, attrs_list_opt) {
  self.insert_string(data, attrs_list_opt)
}

///|
pub impl Edit for SyntaxEditor with fn apply_change(self, change) {
  self.apply_change(change)
}

///|
pub impl Edit for SyntaxEditor with fn cursor_position(self) {
  self.cursor_position()
}

///|
pub impl Edit for SyntaxEditor with fn action(self, action) {
  self.action(action)
}

///|
pub impl Edit for ViEditor with fn editor(self) {
  self.editor()
}

///|
pub impl Edit for ViEditor with fn set_editor(self, editor) {
  self.set_editor(editor)
}

///|
pub impl Edit for ViEditor with fn cursor(self) {
  self.editor().cursor()
}

///|
pub impl Edit for ViEditor with fn set_cursor(self, cursor) {
  self.set_editor(self.editor().set_cursor(cursor))
}

///|
pub impl Edit for ViEditor with fn selection(self) {
  self.editor().selection()
}

///|
pub impl Edit for ViEditor with fn set_selection(self, selection) {
  self.set_editor(self.editor().set_selection(selection))
}

///|
pub impl Edit for ViEditor with fn auto_indent(self) {
  self.editor().auto_indent()
}

///|
pub impl Edit for ViEditor with fn set_auto_indent(self, auto_indent) {
  self.set_editor(self.editor().set_auto_indent(auto_indent))
}

///|
pub impl Edit for ViEditor with fn tab_width(self) {
  self.editor().tab_width()
}

///|
pub impl Edit for ViEditor with fn set_tab_width(self, tab_width) {
  self.set_editor(self.editor().set_tab_width(tab_width))
}

///|
pub impl Edit for ViEditor with fn start_change(self) {
  self.set_editor(self.editor().start_change())
}

///|
pub impl Edit for ViEditor with fn finish_change(self) {
  let finished = self.editor().finish_change()
  (self.set_editor(finished.0), finished.1)
}

///|
pub impl Edit for ViEditor with fn copy_selection(self) {
  self.editor().copy_selection()
}

///|
pub impl Edit for ViEditor with fn delete_selection(self) {
  let deleted = self.editor().delete_selection()
  (self.set_editor(deleted.0), deleted.1)
}

///|
pub impl Edit for ViEditor with fn delete_range(self, start, end) {
  self.set_editor(self.editor().delete_range(start, end))
}

///|
pub impl Edit for ViEditor with fn insert_string(self, data, attrs_list_opt) {
  self.set_editor(self.editor().insert_string(data, attrs_list_opt))
}

///|
pub impl Edit for ViEditor with fn apply_change(self, change) {
  let applied = self.editor().apply_change(change)
  (self.set_editor(applied.0), applied.1)
}

///|
pub impl Edit for ViEditor with fn cursor_position(self) {
  self.editor().cursor_position()
}

///|
pub impl Edit for ViEditor with fn action(self, action) {
  self.set_editor(self.editor().action(action))
}

///|
pub extend Editor with Edit::{set_editor, editor}

///|
pub extend ViEditor with Edit::{
  start_change,
  copy_selection,
  finish_change,
  action,
  set_auto_indent,
  tab_width,
  selection,
  apply_change,
  cursor,
  set_cursor,
  insert_string,
  set_selection,
  set_tab_width,
  cursor_position,
  auto_indent,
  delete_selection,
  delete_range,
}
